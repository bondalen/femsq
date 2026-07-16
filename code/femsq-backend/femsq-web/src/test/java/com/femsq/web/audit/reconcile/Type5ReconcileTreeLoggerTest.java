package com.femsq.web.audit.reconcile;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.web.audit.AuditExecutionContext;
import com.femsq.web.audit.staging.StagingLogLevel;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * Unit-тесты дерева сверки type=5 (§9.3.8.1–9.3.8.2).
 */
class Type5ReconcileTreeLoggerTest {

    @Test
    void appendScaffold_writesNestedOaBranchesAndEmptyMessages() {
        AuditExecutionContext context = new AuditExecutionContext(42L);
        Type5ReconcileTreeLogger.TreeCounts counts = new Type5ReconcileTreeLogger.TreeCounts(
                10,
                Type5ReconcileTreeLogger.BranchDetail.ofCounts(
                        new Type5ReconcileTreeLogger.BranchCounts(5, 2, 1)),
                Type5ReconcileTreeLogger.BranchDetail.ofCounts(
                        Type5ReconcileTreeLogger.BranchCounts.empty()),
                Type5ReconcileTreeLogger.BranchDetail.ofCounts(
                        new Type5ReconcileTreeLogger.BranchCounts(3, 0, 0)),
                Type5ReconcileTreeLogger.BranchDetail.ofCounts(
                        Type5ReconcileTreeLogger.BranchCounts.empty()),
                Type5ReconcileTreeLogger.BranchDetail.ofCounts(
                        Type5ReconcileTreeLogger.BranchCounts.empty())
        );

        Type5ReconcileTreeLogger.appendScaffold(context, 42L, 100L, counts);
        String html = context.buildHtmlLog();

        assertTrue(html.contains("Всего строк:"), html);
        assertTrue(html.contains("<b>ОА</b>"), html);
        assertTrue(html.contains("Собственно ОА"), html);
        assertTrue(html.contains("Изменения к ОА"), html);
        assertTrue(html.contains("ОА прочие"), html);
        assertTrue(html.contains("Найдено отчётов отсутствующих в БД: 2"), html);
        assertTrue(html.contains("Не найдены изменения отсутствующие в БД."), html);
        assertFalse(html.contains("Изменения без определённой базы"), html);
        assertTrue(html.contains("<details"), html);
        assertTrue(html.contains("badge-start"), html);
    }

    @Test
    void appendScaffold_includesOrphanBranchWhenUnresolved() {
        AuditExecutionContext context = new AuditExecutionContext(1L);
        Type5ReconcileTreeLogger.TreeCounts counts = new Type5ReconcileTreeLogger.TreeCounts(
                2,
                Type5ReconcileTreeLogger.BranchDetail.ofCounts(Type5ReconcileTreeLogger.BranchCounts.empty()),
                Type5ReconcileTreeLogger.BranchDetail.ofCounts(Type5ReconcileTreeLogger.BranchCounts.empty()),
                Type5ReconcileTreeLogger.BranchDetail.ofCounts(Type5ReconcileTreeLogger.BranchCounts.empty()),
                Type5ReconcileTreeLogger.BranchDetail.ofCounts(Type5ReconcileTreeLogger.BranchCounts.empty()),
                Type5ReconcileTreeLogger.BranchDetail.ofCounts(
                        new Type5ReconcileTreeLogger.BranchCounts(4, 0, 0))
        );

        Type5ReconcileTreeLogger.appendScaffold(context, 1L, 2L, counts);
        String html = context.buildHtmlLog();

        assertTrue(html.contains("Изменения без определённой базы"), html);
        assertTrue(html.contains("Строк без NEW/CHANGED"), html);
        assertTrue(html.contains(">4<"), html);
    }

    @Test
    void appendScaffold_listsNewLinesUnderReadySpan_dryRun() {
        AuditExecutionContext context = new AuditExecutionContext(7L);
        List<String> lines = List.of(
                Type5ReconcileTreeLineFormatter.formatRaNewLine(
                        1, 100, "ИР26-1", LocalDate.of(2026, 3, 1),
                        new BigDecimal("10"), BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO)
        );
        Type5ReconcileTreeLogger.BranchDetail oaRa = new Type5ReconcileTreeLogger.BranchDetail(
                new Type5ReconcileTreeLogger.BranchCounts(1, 1, 0),
                new Type5ReconcileTreeLogger.ListedBlock(lines, 0),
                Type5ReconcileTreeLogger.ListedBlock.empty(),
                Type5ReconcileErrorGrouper.ErrorTree.empty()
        );
        Type5ReconcileTreeLogger.TreeCounts counts = new Type5ReconcileTreeLogger.TreeCounts(
                1,
                oaRa,
                Type5ReconcileTreeLogger.BranchDetail.ofCounts(Type5ReconcileTreeLogger.BranchCounts.empty()),
                Type5ReconcileTreeLogger.BranchDetail.ofCounts(Type5ReconcileTreeLogger.BranchCounts.empty()),
                Type5ReconcileTreeLogger.BranchDetail.ofCounts(Type5ReconcileTreeLogger.BranchCounts.empty()),
                Type5ReconcileTreeLogger.BranchDetail.ofCounts(Type5ReconcileTreeLogger.BranchCounts.empty())
        );

        Type5ReconcileTreeLogger.appendScaffold(context, 7L, 8L, counts, false);
        String html = context.buildHtmlLog();

        assertTrue(html.contains("готово к внесению"), html);
        assertFalse(html.contains("<b>внесено</b>"), html);
        assertTrue(html.contains("ИР26-1"), html);
        assertTrue(html.contains("01.03.2026"), html);
    }

    @Test
    void appendScaffold_applyModeUsesVnesenoTitle() {
        AuditExecutionContext context = new AuditExecutionContext(9L);
        Type5ReconcileTreeLogger.BranchDetail oaRa = new Type5ReconcileTreeLogger.BranchDetail(
                new Type5ReconcileTreeLogger.BranchCounts(1, 1, 0),
                new Type5ReconcileTreeLogger.ListedBlock(List.of("<P>1. 10. X.</P>"), 0),
                Type5ReconcileTreeLogger.ListedBlock.empty(),
                Type5ReconcileErrorGrouper.ErrorTree.empty()
        );
        Type5ReconcileTreeLogger.TreeCounts counts = new Type5ReconcileTreeLogger.TreeCounts(
                1,
                oaRa,
                Type5ReconcileTreeLogger.BranchDetail.ofCounts(Type5ReconcileTreeLogger.BranchCounts.empty()),
                Type5ReconcileTreeLogger.BranchDetail.ofCounts(Type5ReconcileTreeLogger.BranchCounts.empty()),
                Type5ReconcileTreeLogger.BranchDetail.ofCounts(Type5ReconcileTreeLogger.BranchCounts.empty()),
                Type5ReconcileTreeLogger.BranchDetail.ofCounts(Type5ReconcileTreeLogger.BranchCounts.empty())
        );

        Type5ReconcileTreeLogger.appendScaffold(context, 9L, 10L, counts, true);
        String html = context.buildHtmlLog();

        assertTrue(html.contains("<b>внесено</b>"), html);
        assertFalse(html.contains("готово к внесению"), html);
    }

    @Test
    void limitLines_summaryShowsOverflow() {
        List<String> all = new ArrayList<>();
        for (int i = 1; i <= 45; i++) {
            all.add("<P>" + i + "</P>");
        }
        Type5ReconcileTreeLogger.ListedBlock block =
                Type5ReconcileTreeLineFormatter.limitLines(all, Type5ReconcileTreeLineFormatter.SUMMARY_LINE_LIMIT);
        assertEquals(40, block.lineHtmls().size());
        assertEquals(5, block.suppressed());

        assertEquals(0, Type5ReconcileTreeLineFormatter.detailLimit(StagingLogLevel.MINIMAL));
        assertEquals(Integer.MAX_VALUE, Type5ReconcileTreeLineFormatter.detailLimit(StagingLogLevel.VERBOSE));
        assertEquals(40, Type5ReconcileTreeLineFormatter.detailLimit(StagingLogLevel.SUMMARY));
    }

    @Test
    void formatRaChangedLine_includesAccessStyleDiff() {
        List<Type5ReconcileTreeLineFormatter.FieldDiff> diffs = List.of(
                new Type5ReconcileTreeLineFormatter.FieldDiff("Письмо направления", "", "472")
        );
        String html = Type5ReconcileTreeLineFormatter.formatRaChangedLine(1, 2538, "ГПИ26-1", diffs);
        assertTrue(html.contains("2538"), html);
        assertTrue(html.contains("Письмо направления"), html);
        assertTrue(html.contains("источник: 472"), html);
        assertTrue(html.contains("Обновлено, БД: 472"), html);
    }

    @Test
    void appendScaffold_groupsErrorsByPrimaryReason() {
        AuditExecutionContext context = new AuditExecutionContext(11L);
        List<Type5ReconcileErrorGrouper.ErrorHit> hits = List.of(
                Type5ReconcileErrorGrouper.ErrorHit.of(
                        "ОА", 28, Type5ReconcileErrorGrouper.PRIMARY_MISSING_CSTAP,
                        "026-2001234", "INVALID_CANONICAL_KEY", "стройка не найдена"),
                Type5ReconcileErrorGrouper.ErrorHit.of(
                        "ОА", 132, Type5ReconcileErrorGrouper.PRIMARY_MISSING_CSTAP,
                        "026-2001234", "INVALID_CANONICAL_KEY", "стройка не найдена"),
                Type5ReconcileErrorGrouper.ErrorHit.of(
                        "ОА", 2456, Type5ReconcileErrorGrouper.PRIMARY_MISSING_SENDER,
                        "Газпром инвест", "INVALID_CANONICAL_KEY", "отправитель не найден"),
                Type5ReconcileErrorGrouper.ErrorHit.of(
                        "ОА", 789, Type5ReconcileErrorGrouper.PRIMARY_OTHER,
                        null, "DISALLOWED_SIGN", "знак недопустим")
        );
        Type5ReconcileErrorGrouper.ErrorTree errors =
                Type5ReconcileErrorGrouper.group(hits, Type5ReconcileTreeLineFormatter.SUMMARY_LINE_LIMIT);
        Type5ReconcileTreeLogger.BranchDetail oaRa = new Type5ReconcileTreeLogger.BranchDetail(
                new Type5ReconcileTreeLogger.BranchCounts(4, 0, 0),
                Type5ReconcileTreeLogger.ListedBlock.empty(),
                Type5ReconcileTreeLogger.ListedBlock.empty(),
                errors
        );
        Type5ReconcileTreeLogger.TreeCounts counts = new Type5ReconcileTreeLogger.TreeCounts(
                4,
                oaRa,
                Type5ReconcileTreeLogger.BranchDetail.ofCounts(Type5ReconcileTreeLogger.BranchCounts.empty()),
                Type5ReconcileTreeLogger.BranchDetail.ofCounts(Type5ReconcileTreeLogger.BranchCounts.empty()),
                Type5ReconcileTreeLogger.BranchDetail.ofCounts(Type5ReconcileTreeLogger.BranchCounts.empty()),
                Type5ReconcileTreeLogger.BranchDetail.ofCounts(Type5ReconcileTreeLogger.BranchCounts.empty())
        );

        Type5ReconcileTreeLogger.appendScaffold(context, 11L, 12L, counts, false);
        String html = context.buildHtmlLog();

        assertTrue(html.contains("Не участвуют в сверке / ошибки"), html);
        assertTrue(html.contains("отсутствуют стройки"), html);
        assertTrue(html.contains("026-2001234"), html);
        assertTrue(html.contains("28") && html.contains("132"), html);
        assertTrue(html.contains("отсутствует отправитель"), html);
        assertTrue(html.contains("Газпром инвест"), html);
        assertTrue(html.contains("иные ошибки"), html);
        assertTrue(html.contains("789"), html);
    }

    @Test
    void primaryForCanonicalGaps_prefersCstapOverSender() {
        assertEquals(
                Type5ReconcileErrorGrouper.PRIMARY_MISSING_CSTAP,
                Type5ReconcileErrorGrouper.primaryForCanonicalGaps(true, true, false, false));
        assertEquals(
                Type5ReconcileErrorGrouper.PRIMARY_MISSING_SENDER,
                Type5ReconcileErrorGrouper.primaryForCanonicalGaps(false, true, false, false));
        assertEquals(
                Type5ReconcileErrorGrouper.PRIMARY_OTHER,
                Type5ReconcileErrorGrouper.primaryForCanonicalGaps(false, false, true, false));
    }
}
