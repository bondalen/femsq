package com.femsq.web.audit.reconcile;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.web.audit.AuditExecutionContext;
import com.femsq.web.audit.stage2.RalpFkAnomalyRow;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * Unit-тесты дерева сверки type=3 (§9.3.8.4 + A5-span).
 */
class RalpReconcileTreeLoggerTest {

    private static RalpReconcileTreeLogger.TreeModel model(
            int stagingTotal,
            int newReports,
            int newAu,
            int changed,
            Type5ReconcileTreeLogger.ListedBlock newLines,
            Type5ReconcileTreeLogger.ListedBlock changedLines,
            Type5ReconcileTreeLogger.ListedBlock emptyArrived,
            Type5ReconcileErrorGrouper.ErrorTree errors,
            List<String> orphans,
            boolean apply
    ) {
        return new RalpReconcileTreeLogger.TreeModel(
                stagingTotal,
                newReports,
                newAu,
                changed,
                newLines == null ? Type5ReconcileTreeLogger.ListedBlock.empty() : newLines,
                changedLines == null ? Type5ReconcileTreeLogger.ListedBlock.empty() : changedLines,
                emptyArrived == null ? Type5ReconcileTreeLogger.ListedBlock.empty() : emptyArrived,
                errors == null ? Type5ReconcileErrorGrouper.ErrorTree.empty() : errors,
                orphans == null ? List.of() : orphans,
                apply
        );
    }

    @Test
    void appendScaffold_writesSingleTrunkWithEmptyMessages() {
        AuditExecutionContext context = new AuditExecutionContext(42L);
        RalpReconcileTreeLogger.appendScaffold(
                context, 42L, 100L, model(10, 0, 0, 0, null, null, null, null, List.of(), false));
        String html = context.buildHtmlLog();

        assertTrue(html.contains("Всего строк:"), html);
        assertTrue(html.contains("<b>Отчёты аренды</b>"), html);
        assertFalse(html.contains("<b>ОА</b>"), html);
        assertTrue(html.contains("Не найдены отчёты/рассмотрения отсутствующие в БД."), html);
        assertTrue(html.contains("Не найдены рассмотрения имеющие несоответствия в данных."), html);
        assertFalse(html.contains("Без рассмотрения"), html);
        assertTrue(html.contains("<details"), html);
    }

    @Test
    void appendScaffold_listsNewAndChangedUnderReadySpan_dryRun() {
        AuditExecutionContext context = new AuditExecutionContext(7L);
        RalpReconcileTreeLogger.TreeModel m = model(
                3, 1, 1, 1,
                new Type5ReconcileTreeLogger.ListedBlock(
                        List.of("<P>1. 10. 0126/1 от 01.03.2026.</P>", "<P>1. —. Рассмотрение к ОА № 0126/1.</P>"),
                        0),
                new Type5ReconcileTreeLogger.ListedBlock(
                        List.of("<P>1. 20. Рассмотрение ОА № 0126/2: поля отличаются.</P>"),
                        0),
                null, null, List.of(), false);

        RalpReconcileTreeLogger.appendScaffold(context, 7L, 8L, m);
        String html = context.buildHtmlLog();

        assertTrue(html.contains("Найдено отсутствующих в БД: 2"), html);
        assertTrue(html.contains("готово к внесению"), html);
        assertTrue(html.contains("0126/1"), html);
    }

    @Test
    void appendScaffold_applyModeUsesVnesenoTitle() {
        AuditExecutionContext context = new AuditExecutionContext(9L);
        RalpReconcileTreeLogger.appendScaffold(
                context, 9L, 10L,
                model(1, 1, 0, 0,
                        new Type5ReconcileTreeLogger.ListedBlock(List.of("<P>1. NEW</P>"), 0),
                        null, null, null, List.of(), true));
        String html = context.buildHtmlLog();

        assertTrue(html.contains("<b>внесено</b>"), html);
        assertFalse(html.contains("готово к внесению"), html);
    }

    @Test
    void appendScaffold_groupsEmptyArrivedUnderCollapsibleSpan() {
        AuditExecutionContext context = new AuditExecutionContext(5L);
        String line = RalpReconcileAnomalyFormatter.formatEmptyArrivedHtml(
                415, "465/310326", LocalDate.of(2026, 3, 31));
        RalpReconcileTreeLogger.appendScaffold(
                context, 5L, 6L,
                model(2, 0, 0, 0, null, null,
                        new Type5ReconcileTreeLogger.ListedBlock(List.of(line), 1),
                        null, List.of(), false));
        String html = context.buildHtmlLog();

        assertTrue(html.contains("Без рассмотрения (пустое «Поступило»)"), html);
        assertTrue(html.contains(">2<") || html.contains(">2</font>"), html);
        assertTrue(html.contains("415"), html);
        assertTrue(html.contains("465/310326"), html);
        assertTrue(html.contains("и ещё 1"), html);
        assertFalse(html.contains("рассмотрение не обрабатывается"), html);
        assertTrue(html.contains("<details"), html);
    }

    @Test
    void appendScaffold_groupsStage2ErrorsAndOrphans() {
        AuditExecutionContext context = new AuditExecutionContext(11L);
        List<Type5ReconcileErrorGrouper.ErrorHit> hits = RalpReconcileErrorMapper.toErrorHits(List.of(
                new RalpFkAnomalyRow(1L, 91, "0126/a", LocalDate.of(2026, 1, 31),
                        "026-3005711", "Газпром инвест", null, null, 10),
                new RalpFkAnomalyRow(2L, 151, "0126/b", LocalDate.of(2026, 2, 1),
                        "026-3005711", "X", null, null, 11),
                new RalpFkAnomalyRow(3L, 243, "0126/c", LocalDate.of(2026, 2, 2),
                        "026-1000001", "Газпром инвест", "филиал", 5, null),
                new RalpFkAnomalyRow(4L, 283, "0126/d", null,
                        "026-1000001", "Y", null, 5, 12)
        ));
        Type5ReconcileErrorGrouper.ErrorTree errors =
                Type5ReconcileErrorGrouper.group(hits, Type5ReconcileTreeLineFormatter.SUMMARY_LINE_LIMIT);

        RalpReconcileTreeLogger.appendScaffold(
                context, 11L, 12L,
                model(4, 0, 0, 0, null, null, null, errors, List.of("ORPHAN-1", "ORPHAN-2"), false));
        String html = context.buildHtmlLog();

        assertTrue(html.contains("Не участвуют в сверке / ошибки"), html);
        assertTrue(html.contains("026-3005711"), html);
        assertTrue(html.contains("Лишние отчёты в БД"), html);
        assertTrue(html.contains("ORPHAN-1"), html);
    }

    @Test
    void errorMapper_prefersCstapOverSenderAndDate() {
        List<Type5ReconcileErrorGrouper.ErrorHit> hits = RalpReconcileErrorMapper.toErrorHits(List.of(
                new RalpFkAnomalyRow(1L, 1, "n", null, "026-1", "s", "b", null, null)
        ));
        assertEquals(1, hits.size());
        assertEquals(Type5ReconcileErrorGrouper.PRIMARY_MISSING_CSTAP, hits.get(0).primaryReason());
        assertEquals("026-1", hits.get(0).groupValue());
        assertEquals("A1_A2_CST", hits.get(0).reasonCode());
    }

    @Test
    void errorMapper_mapsSenderAndDateGaps() {
        List<Type5ReconcileErrorGrouper.ErrorHit> hits = RalpReconcileErrorMapper.toErrorHits(List.of(
                new RalpFkAnomalyRow(2L, 2, "n2", LocalDate.of(2026, 3, 1),
                        "026-2", "Org", "Branch", 1, null),
                new RalpFkAnomalyRow(3L, 3, "n3", null, "026-3", "Org", null, 1, 2)
        ));
        assertEquals(2, hits.size());
        assertEquals(Type5ReconcileErrorGrouper.PRIMARY_MISSING_SENDER, hits.get(0).primaryReason());
        assertEquals("Org / Branch", hits.get(0).groupValue());
        assertEquals(Type5ReconcileErrorGrouper.PRIMARY_OTHER, hits.get(1).primaryReason());
        assertEquals("A3_DATE", hits.get(1).reasonCode());
    }
}
