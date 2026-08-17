package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzDbtUplCnCtptExistInvApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplCnNotLoadApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplFile;
import com.femsq.database.model.sudz.SudzDbtUplFunnelResult;
import com.femsq.database.model.sudz.SudzDbtUplFunnelSteps;
import com.femsq.database.model.sudz.SudzDbtUplLauncher;
import com.femsq.database.model.sudz.SudzDbtUplTblRow;
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
 * Оркестратор воронки загрузки свода: {@code excelToTbl} … {@code CnCtptExistInvNotLoad};
 * прочие шаги панели — stub. Очистка InvDouble — prelude внутри шага СФ.
 * Лог шагов — хронология сверху вниз, каждый шаг в сворачиваемом блоке.
 */
@Service
public class SudzDbtUplFunnelRunner {

    private static final Logger log = Logger.getLogger(SudzDbtUplFunnelRunner.class.getName());

    private final SudzService sudzService;
    private final SudzDbtUplExcelToTblImporter importer;

    /**
     * @param sudzService домен
     * @param importer парсер
     */
    public SudzDbtUplFunnelRunner(
            SudzService sudzService,
            SudzDbtUplExcelToTblImporter importer
    ) {
        this.sudzService = Objects.requireNonNull(sudzService, "sudzService");
        this.importer = Objects.requireNonNull(importer, "importer");
    }

    /**
     * Прогон: Excel→Tbl по {@code cidufFlTbl}, затем префикс панели. Лог прогона
     * <em>заменяет</em> предыдущий {@code cidufLoadingProgress}.
     *
     * @param uplKey ключ выгрузки
     * @param steps префикс stepId панели (без excelToTbl)
     * @param flLoad флаг записи (для будущих apply; сейчас в логе)
     * @return результат
     */
    public SudzDbtUplFunnelResult run(int uplKey, List<String> steps, boolean flLoad) {
        if (uplKey <= 0) {
            throw new IllegalArgumentException("uplKey должен быть положительным: " + uplKey);
        }
        List<String> ordered = new ArrayList<>();
        for (String stepId : steps) {
            if (stepId != null && !SudzDbtUplFunnelSteps.EXCEL_TO_TBL.equals(stepId)) {
                ordered.add(stepId);
            }
        }
        ordered = List.copyOf(ordered);
        SudzDbtUplFunnelSteps.requirePrefixOfEnabled(ordered);

        SudzDbtUplLauncher before = sudzService.getDbtUplLauncher(uplKey);
        SudzDbtUplFile file = before.file();
        boolean flTbl = file != null && file.cidufFlTbl();
        if (!flTbl && ordered.isEmpty()) {
            throw new IllegalArgumentException(
                    "Включите «обнов. по исх?» или отметьте хотя бы один шаг воронки");
        }
        log.log(Level.INFO, "runDbtUplFunnel uplKey={0}, steps={1}, flLoad={2}, flTbl={3}",
                new Object[]{uplKey, ordered, flLoad, flTbl});

        SudzDbtUplProgressLog progress = new SudzDbtUplProgressLog();
        progress.line("<b><font color=\"DarkGoldenrod\">Воронка</font></b> upl_key="
                + uplKey + ", flLoad=" + flLoad + ", flTbl=" + flTbl
                + ", шагов панели=" + ordered.size()
                + ". " + SudzDbtUplProgressLog.now());

        List<String> ran = new ArrayList<>();
        boolean anyStub = false;
        if (flTbl) {
            ran.add(SudzDbtUplFunnelSteps.EXCEL_TO_TBL);
            progress.open("<b>" + SudzDbtUplFunnelSteps.EXCEL_TO_TBL + "</b> — "
                    + "Обновлять промежуточную таблицу по данным источника", true);
            runExcelToTbl(uplKey, progress);
            progress.close();
        }
        for (String stepId : ordered) {
            ran.add(stepId);
            String title = SudzDbtUplFunnelSteps.ALL.stream()
                    .filter(s -> s.id().equals(stepId))
                    .map(SudzDbtUplFunnelSteps.StepDef::titleRu)
                    .findFirst()
                    .orElse(stepId);
            progress.open("<b>" + SudzDbtUplProgressLog.escape(stepId) + "</b> — "
                    + SudzDbtUplProgressLog.escape(title), true);
            if (SudzDbtUplFunnelSteps.ORG_NOT_IN_BUIRG.equals(stepId)) {
                runOrgNotInBuirg(uplKey, progress);
            } else if (SudzDbtUplFunnelSteps.CN_NOT_LOAD.equals(stepId)) {
                runCnNotLoad(uplKey, progress, flLoad);
            } else if (SudzDbtUplFunnelSteps.CN_EXIST_CTPT_NOT_LOAD.equals(stepId)) {
                runCnExistCtptNotLoad(uplKey, progress);
            } else if (SudzDbtUplFunnelSteps.CN_CTPT_EXIST_INV_NOT_LOAD.equals(stepId)) {
                runCnCtptExistInvNotLoad(uplKey, progress, flLoad);
            } else {
                anyStub = true;
                progress.line("<font color=\"CadetBlue\">STUB</font>: шаг принят оркестратором,"
                        + " реализация позже.");
            }
            progress.close();
        }
        progress.line("<font color=\"blue\">Воронка завершена</font> — " + SudzDbtUplProgressLog.now());

        sudzService.setDbtUplFileProgress(uplKey, progress.toHtml());
        SudzDbtUplLauncher after = sudzService.getDbtUplLauncher(uplKey);
        return new SudzDbtUplFunnelResult(after, List.copyOf(ran), anyStub);
    }

    /**
     * excelToTbl: путь из {@code cidufPath}, открытие файла процессом Java.
     *
     * @param uplKey ключ выгрузки
     * @param progress лог шага
     */
    private void runExcelToTbl(int uplKey, SudzDbtUplProgressLog progress) {
        SudzDbtUplLauncher launcher = sudzService.getDbtUplLauncher(uplKey);
        SudzDbtUplFile file = launcher.file();
        if (file == null) {
            progress.line("<font color=\"red\">нет записи File</font>.");
            return;
        }
        String stored = SudzDbtUplExcelPathResolver.normalizeStored(file.cidufPath());
        if (stored.isEmpty()) {
            progress.line("<font color=\"red\">в БД нет пути к Excel</font>"
                    + " (cidufPath пуст). Вставьте путь как в Проводнике и сохраните поле.");
            return;
        }
        progress.line("Путь в БД: <font color=\"green\">"
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
            progress.line("Чтение: <font color=\"DarkBlue\">"
                    + SudzDbtUplProgressLog.escape(path.toString()) + "</font>");
        }
        if (launcher.sheets() == null || launcher.sheets().isEmpty()) {
            progress.line("В БД <font color=\"Salmon\">записи листов загрузки отсутствуют</font>");
            return;
        }
        try {
            byte[] bytes = Files.readAllBytes(path);
            String fileName = Optional.ofNullable(path.getFileName())
                    .map(Path::toString)
                    .orElse(stored);
            List<SudzDbtUplTblRow> rows = importer.parse(
                    bytes,
                    fileName,
                    launcher.sheets(),
                    uplKey,
                    progress
            );
            int written = sudzService.replaceDbtUplTbl(uplKey, rows);
            progress.line("<font color=\"green\"><b>записано в Tbl:</b></font> " + written + " строк.");
            log.log(Level.INFO, "excelToTbl uplKey={0} wrote={1} path={2}",
                    new Object[]{uplKey, written, path});
        } catch (IOException exception) {
            progress.line("<font color=\"red\">ошибка чтения Excel</font> — "
                    + SudzDbtUplProgressLog.escape(exception.getMessage()));
            log.log(Level.WARNING, "excelToTbl parse failed uplKey=" + uplKey, exception);
        }
    }

    /**
     * orgNotInBuirg: уникальные организации Tbl без {@code ags.org_id} type=1.
     * Только лог; {@code cidufFlLoad} не влияет (как Access).
     *
     * @param uplKey ключ выгрузки
     * @param progress лог шага
     */
    private void runOrgNotInBuirg(int uplKey, SudzDbtUplProgressLog progress) {
        int tblCount = sudzService.countDbtUplTbl(uplKey);
        progress.line("Буфер Tbl: <font color=\"DarkCyan\">" + tblCount + "</font> строк"
                + " (unloadKey=" + uplKey + ").");
        if (tblCount == 0) {
            progress.line("<font color=\"Salmon\">буфер пуст</font> — сначала включите"
                    + " «обнов. по исх?» либо загрузите Excel в Tbl.");
        }
        var rows = sudzService.listDbtUplOrgNotInBuirg(uplKey);
        SudzDbtUplOrgNotInBuirgLog.append(progress, rows);
        log.log(Level.INFO, "orgNotInBuirg uplKey={0} tbl={1} missingBuirgRows={2}",
                new Object[]{uplKey, tblCount, rows.size()});
    }

    /**
     * CnNotLoad: договоры без пары в БД (номер + дата + исполнитель).
     * Только лог; {@code cidufFlLoad} в этом срезе не влияет (apply — позже).
     *
     * @param uplKey ключ выгрузки
     * @param progress лог шага
     */
    private void runCnNotLoad(int uplKey, SudzDbtUplProgressLog progress, boolean flLoad) {
        int tblCount = sudzService.countDbtUplTbl(uplKey);
        progress.line("Буфер Tbl: <font color=\"DarkCyan\">" + tblCount + "</font> строк"
                + " (unloadKey=" + uplKey + ").");
        if (tblCount == 0) {
            progress.line("<font color=\"Salmon\">буфер пуст</font> — сначала включите"
                    + " «обнов. по исх?» либо загрузите Excel в Tbl.");
        }
        var rows = sudzService.listDbtUplCnNotLoad(uplKey);
        SudzDbtUplCnNotLoadApplyResult applyResult = null;
        if (flLoad) {
            applyResult = sudzService.applyDbtUplCnNotLoad(rows);
            log.log(Level.INFO, "CnNotLoad apply uplKey={0} cnMark={1} inserted={2}",
                    new Object[]{uplKey, applyResult.cnMark(), applyResult.insertedCount()});
        }
        SudzDbtUplCnNotLoadLog.append(progress, rows, applyResult);
        log.log(Level.INFO, "CnNotLoad uplKey={0} tbl={1} missingCnRows={2} flLoad={3}",
                new Object[]{uplKey, tblCount, rows.size(), flLoad});
    }

    /**
     * CnExistCtptNotLoad: номер договора есть в БД, исполнитель из свода не совпадает.
     * Только лог; {@code cidufFlLoad} не влияет (как Access — apply не реализован).
     *
     * @param uplKey ключ выгрузки
     * @param progress лог шага
     */
    private void runCnExistCtptNotLoad(int uplKey, SudzDbtUplProgressLog progress) {
        int tblCount = sudzService.countDbtUplTbl(uplKey);
        progress.line("Буфер Tbl: <font color=\"DarkCyan\">" + tblCount + "</font> строк"
                + " (unloadKey=" + uplKey + ").");
        if (tblCount == 0) {
            progress.line("<font color=\"Salmon\">буфер пуст</font> — сначала включите"
                    + " «обнов. по исх?» либо загрузите Excel в Tbl.");
        }
        var rows = sudzService.listDbtUplCnExistCtptNotLoad(uplKey);
        SudzDbtUplCnExistCtptNotLoadLog.append(progress, rows);
        log.log(Level.INFO, "CnExistCtptNotLoad uplKey={0} tbl={1} mismatchRows={2}",
                new Object[]{uplKey, tblCount, rows.size()});
    }

    /**
     * CnCtptExistInvNotLoad: prelude clear InvDouble + буфер новых СФ + лог;
     * apply inv/invNum/cnInv при {@code flLoad}.
     *
     * @param uplKey ключ выгрузки
     * @param progress лог шага
     * @param flLoad писать ли в домен
     */
    private void runCnCtptExistInvNotLoad(int uplKey, SudzDbtUplProgressLog progress, boolean flLoad) {
        int tblCount = sudzService.countDbtUplTbl(uplKey);
        progress.line("Буфер Tbl: <font color=\"DarkCyan\">" + tblCount + "</font> строк"
                + " (unloadKey=" + uplKey + ").");
        if (tblCount == 0) {
            progress.line("<font color=\"Salmon\">буфер пуст</font> — сначала включите"
                    + " «обнов. по исх?» либо загрузите Excel в Tbl.");
        }
        int cleared = sudzService.clearDbtUplInvDouble();
        progress.line("Очистка CnInvDbtUplFileInvDouble: удалено"
                + " <font color=\"DarkCyan\">" + cleared + "</font>"
                + "; очередь SfDouble пересоберётся при rebuild.");

        Integer fileKey = null;
        SudzDbtUplLauncher launcher = sudzService.getDbtUplLauncher(uplKey);
        if (launcher.file() != null) {
            fileKey = launcher.file().cidufKey();
        }

        var prepared = sudzService.rebuildDbtUplCnCtptExistInvNot(uplKey, fileKey);
        SudzDbtUplCnCtptExistInvNotLoadLog.append(progress, prepared, null);

        SudzDbtUplCnCtptExistInvApplyResult applyResult = null;
        if (flLoad && prepared.invoiceRowCount() > 0) {
            applyResult = sudzService.applyDbtUplCnCtptExistInvNotLoad(uplKey);
            progress.line("Внесено счетов-фактур (строк) в БД: <b><font color=\"DarkGreen\">"
                    + applyResult.insertedCount() + "</font></b>");
            // Access: повторный показ после apply (хвост должен опустеть)
            prepared = sudzService.rebuildDbtUplCnCtptExistInvNot(uplKey, null);
            SudzDbtUplCnCtptExistInvNotLoadLog.append(progress, prepared, null);
        }
        log.log(Level.INFO,
                "CnCtptExistInvNotLoad uplKey={0} tbl={1} invRows={2} contracts={3} flLoad={4} applied={5}",
                new Object[]{
                        uplKey,
                        tblCount,
                        prepared.invoiceRowCount(),
                        prepared.contracts().size(),
                        flLoad,
                        applyResult == null ? 0 : applyResult.insertedCount()
                });
    }
}
