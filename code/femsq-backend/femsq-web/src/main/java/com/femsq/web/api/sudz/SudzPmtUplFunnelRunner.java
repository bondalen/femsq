package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzPmtUplFile;
import com.femsq.database.model.sudz.SudzPmtUplFunnelResult;
import com.femsq.database.model.sudz.SudzPmtUplFunnelSteps;
import com.femsq.database.model.sudz.SudzPmtUplLauncher;
import com.femsq.database.model.sudz.SudzPmtUplTblRow;
import com.femsq.database.service.SudzService;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;

/**
 * Оркестратор воронки загрузки платежей (0074): Excel→Tbl по {@code cipufFlTbl},
 * затем префикс {@code cipu*} (stub без apply).
 * <p>
 * Лог — сжатый: блокеры, сводки шагов; без построчного Excel и без STUB на каждый cipu*.
 * </p>
 */
@Service
public class SudzPmtUplFunnelRunner {

    private static final Logger log = Logger.getLogger(SudzPmtUplFunnelRunner.class.getName());

    private final SudzService sudzService;
    private final SudzPmtUplExcelToTblImporter importer;

    /**
     * @param sudzService домен
     * @param importer парсер Excel→Tbl
     */
    public SudzPmtUplFunnelRunner(
            SudzService sudzService,
            SudzPmtUplExcelToTblImporter importer
    ) {
        this.sudzService = Objects.requireNonNull(sudzService, "sudzService");
        this.importer = Objects.requireNonNull(importer, "importer");
    }

    /**
     * Прогон: Excel→Tbl при {@code cipufFlTbl}, затем префикс панели.
     * Лог прогона заменяет {@code cipufLoadingProgress}.
     *
     * @param pmKey ключ пакета
     * @param steps префикс stepId (без excelToTbl)
     * @param flLoad флаг «Обновлять» (в логе; apply — позже)
     * @return результат
     */
    public SudzPmtUplFunnelResult run(int pmKey, List<String> steps, boolean flLoad) {
        if (pmKey <= 0) {
            throw new IllegalArgumentException("pmKey должен быть положительным: " + pmKey);
        }
        List<String> ordered = new ArrayList<>();
        if (steps != null) {
            for (String stepId : steps) {
                if (stepId != null && !SudzPmtUplFunnelSteps.EXCEL_TO_TBL.equals(stepId)) {
                    ordered.add(stepId);
                }
            }
        }
        ordered = List.copyOf(ordered);
        SudzPmtUplFunnelSteps.requirePrefixOfEnabled(ordered);

        SudzPmtUplLauncher before = sudzService.getPmtUplLauncher(pmKey);
        SudzPmtUplFile file = before.file();
        boolean flTbl = file != null && file.cipufFlTbl();
        if (!flTbl && ordered.isEmpty()) {
            throw new IllegalArgumentException(
                    "Включите «обнов. по исх?» или отметьте хотя бы один шаг воронки");
        }
        log.log(Level.INFO, "runPmtUplFunnel pmKey={0}, steps={1}, flLoad={2}, flTbl={3}",
                new Object[]{pmKey, ordered, flLoad, flTbl});

        SudzDbtUplProgressLog progress = new SudzDbtUplProgressLog();
        progress.line("<b><font color=\"DarkGoldenrod\">Воронка платежей</font></b>"
                + " pm_key=" + pmKey
                + " · flTbl=" + (flTbl ? 1 : 0)
                + " · flLoad=" + (flLoad ? 1 : 0)
                + " · " + SudzDbtUplProgressLog.now());

        List<String> ran = new ArrayList<>();
        boolean anyStub = false;
        long funnelT0 = System.currentTimeMillis();

        if (flTbl) {
            ran.add(SudzPmtUplFunnelSteps.EXCEL_TO_TBL);
            long stepT0 = System.currentTimeMillis();
            runExcelToTbl(pmKey, progress);
            long ms = System.currentTimeMillis() - stepT0;
            progress.line("excelToTbl: <b>" + ms + "</b> мс");
            log.log(Level.INFO, "pmt funnel step {0} ms={1}",
                    new Object[]{SudzPmtUplFunnelSteps.EXCEL_TO_TBL, ms});
        }

        if (!ordered.isEmpty()) {
            ran.addAll(ordered);
            anyStub = true;
            progress.line("<font color=\"CadetBlue\">cipu*</font>: stub ("
                    + ordered.size() + " шагов префикса), apply нет · flLoad="
                    + (flLoad ? 1 : 0)
                    + ". Реализация шагов — позже; списки решений — во вкладках.");
        }

        long funnelMs = System.currentTimeMillis() - funnelT0;
        progress.line("<font color=\"blue\">Воронка OK</font> — "
                + SudzDbtUplProgressLog.now()
                + " (всего <b>" + funnelMs + "</b> мс)");
        log.log(Level.INFO, "runPmtUplFunnel done pmKey={0} totalMs={1} steps={2}",
                new Object[]{pmKey, funnelMs, ran});

        sudzService.setPmtUplFileProgress(pmKey, progress.toHtml());
        SudzPmtUplLauncher after = sudzService.getPmtUplLauncher(pmKey);
        return new SudzPmtUplFunnelResult(after, List.copyOf(ran), anyStub);
    }

    /**
     * excelToTbl: путь из {@code cipufPath}, лист {@code cipufSheet}.
     *
     * @param pmKey ключ пакета
     * @param progress лог шага
     */
    private void runExcelToTbl(int pmKey, SudzDbtUplProgressLog progress) {
        SudzPmtUplLauncher launcher = sudzService.getPmtUplLauncher(pmKey);
        SudzPmtUplFile file = launcher.file();
        if (file == null) {
            progress.line("<font color=\"red\">нет записи File</font>.");
            return;
        }
        String stored = SudzDbtUplExcelPathResolver.normalizeStored(file.cipufPath());
        if (stored.isEmpty()) {
            progress.line("<font color=\"red\">в БД нет пути к Excel</font>"
                    + " (cipufPath пуст). Вставьте путь как в Проводнике и сохраните поле.");
            return;
        }
        progress.line("путь: <font color=\"green\">"
                + SudzDbtUplProgressLog.escape(stored) + "</font>");
        Optional<Path> readable = SudzDbtUplExcelPathResolver.resolveExisting(stored);
        if (readable.isEmpty()) {
            String tried = SudzDbtUplExcelPathResolver.candidates(stored).stream()
                    .map(Path::toString)
                    .collect(Collectors.joining("; "));
            progress.line("<font color=\"red\">файл не найден</font> для процесса Java."
                    + " Пробовали: " + SudzDbtUplProgressLog.escape(tried)
                    + ". Проверьте путь в Проводнике и доступность диска для WSL.");
            return;
        }
        Path path = readable.get();
        if (!path.toString().equals(stored)) {
            progress.line("чтение: <font color=\"DarkBlue\">"
                    + SudzDbtUplProgressLog.escape(path.toString()) + "</font>");
        }
        String sheetLabel = file.cipufSheet() == null || file.cipufSheet().isBlank()
                ? "«?»"
                : SudzDbtUplProgressLog.escape(file.cipufSheet().trim());
        try {
            byte[] bytes = Files.readAllBytes(path);
            String fileName = Optional.ofNullable(path.getFileName())
                    .map(Path::toString)
                    .orElse(stored);
            List<SudzPmtUplTblRow> rows = importer.parse(
                    bytes,
                    fileName,
                    file.cipufSheet(),
                    pmKey,
                    progress
            );
            int written = sudzService.replacePmtUplTbl(pmKey, rows);
            progress.line("<b>excelToTbl</b>: "
                    + SudzDbtUplProgressLog.escape(fileName)
                    + " → " + sheetLabel
                    + " → Tbl <b>" + written + "</b> стр.");
            log.log(Level.INFO, "pmt excelToTbl pmKey={0} wrote={1} path={2}",
                    new Object[]{pmKey, written, path});
        } catch (IOException exception) {
            progress.line("<font color=\"red\">ошибка чтения Excel</font> — "
                    + SudzDbtUplProgressLog.escape(exception.getMessage()));
            log.log(Level.WARNING, "pmt excelToTbl parse failed pmKey=" + pmKey, exception);
        }
    }
}
