package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzDbtUplAccSmplNotApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplCnCtptExistInvApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplCnNotLoadApplyResult;
import com.femsq.database.model.sudz.SudzPmtUplAgNotLoadApplyResult;
import com.femsq.database.model.sudz.SudzPmtUplDocNotApplyResult;
import com.femsq.database.model.sudz.SudzPmtUplFile;
import com.femsq.database.model.sudz.SudzPmtUplFunnelResult;
import com.femsq.database.model.sudz.SudzPmtUplFunnelSteps;
import com.femsq.database.model.sudz.SudzPmtUplInsPmNotApplyResult;
import com.femsq.database.model.sudz.SudzPmtUplInsPmNotResult;
import com.femsq.database.model.sudz.SudzPmtUplInvNotResult;
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
 * Оркестратор воронки загрузки платежей (0074/0076): Excel→Tbl по {@code cipufFlTbl},
 * log-only {@code cipu*} (H2), apply шаги 3/5/7/9/10/12 (H3), stub прочих apply.
 * <p>
 * Лог — сжатый: блокеры, сводки N + первые K; без построчного Excel.
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
            log.log(Level.INFO, "pmt funnel start {0} pmKey={1}",
                    new Object[]{SudzPmtUplFunnelSteps.EXCEL_TO_TBL, pmKey});
            long stepT0 = System.currentTimeMillis();
            runExcelToTbl(pmKey, progress);
            long ms = System.currentTimeMillis() - stepT0;
            progress.line("excelToTbl: <b>" + ms + "</b> мс");
            log.log(Level.INFO, "pmt funnel step {0} ms={1}",
                    new Object[]{SudzPmtUplFunnelSteps.EXCEL_TO_TBL, ms});
        }

        if (!ordered.isEmpty()) {
            int tblCount = sudzService.countPmtUplTbl(pmKey);
            progress.line("Буфер Tbl: <font color=\"DarkCyan\">" + tblCount + "</font> строк"
                    + " (unloadKey=" + pmKey + ").");
            if (tblCount == 0) {
                progress.line("<font color=\"Salmon\">буфер пуст</font> — сначала «обнов. по исх?»"
                        + " (Excel→Tbl) либо выберите пакет с уже загруженным Tbl.");
            }
            for (String stepId : ordered) {
                ran.add(stepId);
                String title = SudzPmtUplFunnelSteps.ALL.stream()
                        .filter(s -> s.id().equals(stepId))
                        .map(SudzPmtUplFunnelSteps.StepDef::titleRu)
                        .findFirst()
                        .orElse(stepId);
                // Как свод: блоки развёрнуты — оператор сразу видит N / образцы (H2/H3).
                progress.open("<b>" + SudzDbtUplProgressLog.escape(stepId) + "</b> — "
                        + SudzDbtUplProgressLog.escape(title), true);
                log.log(Level.INFO, "pmt funnel start {0} pmKey={1} flLoad={2}",
                        new Object[]{stepId, pmKey, flLoad});
                long stepT0 = System.currentTimeMillis();
                if (SudzPmtUplFunnelSteps.isLogOnly(stepId)) {
                    runLogOnlyStep(pmKey, stepId, progress);
                    long ms = System.currentTimeMillis() - stepT0;
                    progress.line("шаг: <b>" + ms + "</b> мс · flLoad=" + (flLoad ? 1 : 0)
                            + " (запись домена не выполняется).");
                    log.log(Level.INFO, "pmt funnel log-only {0} pmKey={1} ms={2}",
                            new Object[]{stepId, pmKey, ms});
                } else if ("cipuCn_CtptCnNotLoad".equals(stepId)) {
                    runCnNotLoadStep(pmKey, flLoad, progress);
                    long ms = System.currentTimeMillis() - stepT0;
                    progress.line("шаг: <b>" + ms + "</b> мс · flLoad=" + (flLoad ? 1 : 0) + ".");
                    log.log(Level.INFO, "pmt funnel CnNotLoad pmKey={0} flLoad={1} ms={2}",
                            new Object[]{pmKey, flLoad, ms});
                } else if ("cipuCn_AgNotLoad".equals(stepId)) {
                    runAgNotLoadStep(pmKey, flLoad, progress);
                    long ms = System.currentTimeMillis() - stepT0;
                    progress.line("шаг: <b>" + ms + "</b> мс · flLoad=" + (flLoad ? 1 : 0) + ".");
                    log.log(Level.INFO, "pmt funnel AgNotLoad pmKey={0} flLoad={1} ms={2}",
                            new Object[]{pmKey, flLoad, ms});
                } else if ("cipuCn_CtptCnOneInvNotLoad".equals(stepId)) {
                    runInvNotLoadStep(pmKey, flLoad, progress);
                    long ms = System.currentTimeMillis() - stepT0;
                    progress.line("шаг: <b>" + ms + "</b> мс · flLoad=" + (flLoad ? 1 : 0) + ".");
                    log.log(Level.INFO, "pmt funnel InvNotLoad pmKey={0} flLoad={1} ms={2}",
                            new Object[]{pmKey, flLoad, ms});
                } else if ("cipuCn_CtptCnOneInvOneAcNotLoad".equals(stepId)) {
                    runAcNotLoadStep(pmKey, flLoad, progress);
                    long ms = System.currentTimeMillis() - stepT0;
                    progress.line("шаг: <b>" + ms + "</b> мс · flLoad=" + (flLoad ? 1 : 0) + ".");
                    log.log(Level.INFO, "pmt funnel AcNotLoad pmKey={0} flLoad={1} ms={2}",
                            new Object[]{pmKey, flLoad, ms});
                } else if ("cipuDocNotLoad".equals(stepId)) {
                    runDocNotLoadStep(pmKey, flLoad, progress);
                    long ms = System.currentTimeMillis() - stepT0;
                    progress.line("шаг: <b>" + ms + "</b> мс · flLoad=" + (flLoad ? 1 : 0) + ".");
                    log.log(Level.INFO, "pmt funnel DocNotLoad pmKey={0} flLoad={1} ms={2}",
                            new Object[]{pmKey, flLoad, ms});
                } else if ("cipuInsPmNotLoad".equals(stepId)) {
                    runInsPmNotLoadStep(pmKey, flLoad, progress);
                    long ms = System.currentTimeMillis() - stepT0;
                    progress.line("шаг: <b>" + ms + "</b> мс · flLoad=" + (flLoad ? 1 : 0) + ".");
                    log.log(Level.INFO, "pmt funnel InsPmNotLoad pmKey={0} flLoad={1} ms={2}",
                            new Object[]{pmKey, flLoad, ms});
                } else {
                    anyStub = true;
                    progress.line("<font color=\"CadetBlue\">stub</font>: apply-шаг — H3"
                            + " (0076). flLoad=" + (flLoad ? 1 : 0)
                            + " — запись в домен не выполняется.");
                }
                progress.close();
            }
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
     * Log-only шаг H2: сводка N + первые K, без записи домена.
     *
     * @param pmKey пакет
     * @param stepId id шага
     * @param progress лог
     */
    private void runLogOnlyStep(int pmKey, String stepId, SudzDbtUplProgressLog progress) {
        var result = sudzService.findPmtUplLogOnly(
                stepId, pmKey, SudzPmtUplFunnelSteps.LOG_ONLY_SAMPLE_LIMIT);
        switch (stepId) {
            case "cipuCtpt_All_OIdNot" -> SudzPmtUplCompressedLog.append(
                    progress,
                    "<font color=\"Olive\"><b>новые контрагенты/агенты по БУиРГ отсутствуют</b></font>.",
                    "Без org_id type=1:",
                    result);
            case "cipuCacNot" -> SudzPmtUplCompressedLog.append(
                    progress,
                    "<font color=\"Olive\"><b>новые САК/стройки отсутствуют</b></font>.",
                    "САК без пары в cstAgPn:",
                    result);
            case "cipuCn_CtptCnTwo" -> SudzPmtUplCompressedLog.append(
                    progress,
                    "<font color=\"Olive\"><b>двойных пар договор+исполнитель нет</b></font>.",
                    "Пар с cn×&gt;1:",
                    result);
            case "cipuCn_AgTwo" -> SudzPmtUplCompressedLog.append(
                    progress,
                    "<font color=\"Olive\"><b>двойных агентов на договоре нет</b></font>.",
                    "Договоров с ag×&gt;1:",
                    result);
            case "cipuCn_CtptCnOneInvTwoLoad" -> SudzPmtUplCompressedLog.append(
                    progress,
                    "<font color=\"Olive\"><b>двойных СФ в БД нет</b></font>.",
                    "СФ с ci×&gt;1:",
                    result);
            case "cipuCn_CtptCnOneInvOneAcDcNot" -> SudzPmtUplCompressedLog.append(
                    progress,
                    "<font color=\"Olive\"><b>все коды ПД найдены в cn_inv_doc</b></font>"
                            + " (срез H2 без полного AcDc-буфера).",
                    "Кодов ПД без cn_inv_doc:",
                    result);
            case "cipuInsPmExt" -> {
                SudzPmtUplCompressedLog.append(
                        progress,
                        "<font color=\"Olive\"><b>платежей этого upl в cn_inv_pm ещё нет</b></font>.",
                        "Уже в cn_inv_pm для upl:",
                        result);
                progress.line("<font color=\"gray\">полный построчный MainTest (cipuInsPmExtFalse)"
                        + " — после буфера ExtPm / H3</font>.");
            }
            default -> progress.line("<font color=\"Salmon\">неизвестный log-only шаг</font>: "
                    + SudzDbtUplProgressLog.escape(stepId));
        }
        log.log(Level.INFO, "pmt log-only {0} pmKey={1} total={2}",
                new Object[]{stepId, pmKey, result.total()});
    }

    /**
     * H3 шаг 3: find всегда; apply при {@code flLoad} (countCn=0 + org_id).
     *
     * @param pmKey пакет
     * @param flLoad писать ли в домен
     * @param progress лог
     */
    private void runCnNotLoadStep(int pmKey, boolean flLoad, SudzDbtUplProgressLog progress) {
        var rows = sudzService.listPmtUplCnNotLoad(pmKey);
        SudzDbtUplCnNotLoadApplyResult applyResult = null;
        if (flLoad) {
            applyResult = sudzService.applyPmtUplCnNotLoad(rows);
            log.log(Level.INFO, "pmt CnNotLoad apply pmKey={0} inserted={1} cnMark={2}",
                    new Object[]{pmKey, applyResult.insertedCount(), applyResult.cnMark()});
        }
        SudzPmtUplCnNotLoadLog.append(progress, rows, applyResult);
    }

    /**
     * H3 шаг 5: find всегда; apply при {@code flLoad} (org_id агента → smpl type=1).
     *
     * @param pmKey пакет
     * @param flLoad писать ли в домен
     * @param progress лог
     */
    private void runAgNotLoadStep(int pmKey, boolean flLoad, SudzDbtUplProgressLog progress) {
        var rows = sudzService.listPmtUplAgNotLoad(pmKey);
        SudzPmtUplAgNotLoadApplyResult applyResult = null;
        if (flLoad) {
            applyResult = sudzService.applyPmtUplAgNotLoad(rows);
            log.log(Level.INFO, "pmt AgNotLoad apply pmKey={0} inserted={1}",
                    new Object[]{pmKey, applyResult.insertedCount()});
        }
        SudzPmtUplAgNotLoadLog.append(progress, rows, applyResult);
    }

    /**
     * H3 шаг 7: rebuild TblCnInv всегда; apply inv/invNum/cnInv при {@code flLoad}.
     *
     * @param pmKey пакет
     * @param flLoad писать ли в домен
     * @param progress лог
     */
    private void runInvNotLoadStep(int pmKey, boolean flLoad, SudzDbtUplProgressLog progress) {
        SudzPmtUplInvNotResult prepared = sudzService.rebuildPmtUplInvNot(pmKey);
        SudzDbtUplCnCtptExistInvApplyResult applyResult = null;
        SudzPmtUplInvNotLoadLog.append(progress, prepared, null);
        if (flLoad && prepared.invoiceRowCount() > 0) {
            applyResult = sudzService.applyPmtUplInvNotLoad(pmKey);
            progress.line("Внесено счетов-фактур (строк) в БД: <b><font color=\"DarkGreen\">"
                    + applyResult.insertedCount() + "</font></b>");
            prepared = sudzService.rebuildPmtUplInvNot(pmKey);
            SudzPmtUplInvNotLoadLog.append(progress, prepared, null);
            log.log(Level.INFO, "pmt InvNotLoad apply pmKey={0} inserted={1} left={2}",
                    new Object[]{pmKey, applyResult.insertedCount(), prepared.invoiceRowCount()});
        }
    }

    /**
     * H3 шаг 9: find всегда; apply {@code cnInvAccntSmpl} при {@code flLoad}.
     *
     * @param pmKey пакет
     * @param flLoad писать ли в домен
     * @param progress лог
     */
    private void runAcNotLoadStep(int pmKey, boolean flLoad, SudzDbtUplProgressLog progress) {
        var rows = sudzService.listPmtUplAcNotLoad(pmKey);
        SudzDbtUplAccSmplNotApplyResult applyResult = null;
        SudzPmtUplAcNotLoadLog.append(progress, rows, null);
        if (flLoad && !rows.isEmpty()) {
            applyResult = sudzService.applyPmtUplAcNotLoad(pmKey);
            progress.line("Внесено пар СФ+СГК (строк) в БД: <b><font color=\"DarkGreen\">"
                    + applyResult.insertedCount() + "</font></b>.");
            rows = sudzService.listPmtUplAcNotLoad(pmKey);
            SudzPmtUplAcNotLoadLog.append(progress, rows, null);
            log.log(Level.INFO, "pmt AcNotLoad apply pmKey={0} inserted={1} left={2}",
                    new Object[]{pmKey, applyResult.insertedCount(), rows.size()});
        }
    }

    /**
     * H3 шаг 10: find коды ПД без {@code cn_inv_doc}; apply INSERT при {@code flLoad}.
     *
     * @param pmKey пакет
     * @param flLoad писать ли в домен
     * @param progress лог
     */
    private void runDocNotLoadStep(int pmKey, boolean flLoad, SudzDbtUplProgressLog progress) {
        var codes = sudzService.listPmtUplDocNotLoad(pmKey);
        SudzPmtUplDocNotApplyResult applyResult = null;
        SudzPmtUplDocNotLoadLog.append(progress, codes, null);
        if (flLoad && !codes.isEmpty()) {
            applyResult = sudzService.applyPmtUplDocNotLoad(pmKey);
            progress.line("Внесено документов (строк) в БД: <b><font color=\"DarkGreen\">"
                    + applyResult.insertedCount() + "</font></b>.");
            codes = sudzService.listPmtUplDocNotLoad(pmKey);
            SudzPmtUplDocNotLoadLog.append(progress, codes, null);
            log.log(Level.INFO, "pmt DocNotLoad apply pmKey={0} inserted={1} left={2}",
                    new Object[]{pmKey, applyResult.insertedCount(), codes.size()});
        }
    }

    /**
     * H3 шаг 12: find готовые платежи без {@code cn_inv_pm}; apply INSERT при {@code flLoad}.
     *
     * @param pmKey пакет
     * @param flLoad писать ли в домен
     * @param progress лог
     */
    private void runInsPmNotLoadStep(int pmKey, boolean flLoad, SudzDbtUplProgressLog progress) {
        SudzPmtUplInsPmNotResult find = sudzService.listPmtUplInsPmNotLoad(pmKey);
        SudzPmtUplInsPmNotApplyResult applyResult = null;
        SudzPmtUplInsPmNotLoadLog.append(progress, find, null);
        if (flLoad && find.readyCount() > 0) {
            applyResult = sudzService.applyPmtUplInsPmNotLoad(pmKey);
            progress.line("Внесено платежи в количестве: <font color=\"DarkGreen\"><b>"
                    + applyResult.insertedCount() + "</b></font> записей.");
            find = sudzService.listPmtUplInsPmNotLoad(pmKey);
            SudzPmtUplInsPmNotLoadLog.append(progress, find, null);
            log.log(Level.INFO, "pmt InsPmNotLoad apply pmKey={0} inserted={1} left={2}",
                    new Object[]{pmKey, applyResult.insertedCount(), find.readyCount()});
        }
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
