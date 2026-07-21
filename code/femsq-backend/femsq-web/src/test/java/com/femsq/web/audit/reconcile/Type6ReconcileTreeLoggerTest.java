package com.femsq.web.audit.reconcile;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.web.audit.AuditExecutionContext;
import com.femsq.web.audit.reconcile.Type6ReconcileTreeLogger.ActNode;
import com.femsq.web.audit.reconcile.Type6ReconcileTreeLogger.ActStatus;
import com.femsq.web.audit.reconcile.Type6ReconcileTreeLogger.PnNode;
import com.femsq.web.audit.reconcile.Type6ReconcileTreeLogger.PnStatus;
import com.femsq.web.audit.reconcile.Type6ReconcileTreeLogger.TreeModel;
import com.femsq.web.audit.staging.StagingLogLevel;
import java.math.BigDecimal;
import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * Unit-тесты дерева сверки type=6 (Фаза E / задача 0056).
 */
class Type6ReconcileTreeLoggerTest {

    @Test
    void appendScaffold_writesActPointTreeAndYearSum() {
        AuditExecutionContext ctx = new AuditExecutionContext(14L);
        ctx.setStagingLogLevel(StagingLogLevel.VERBOSE);
        TreeModel model = new TreeModel(
                2026,
                666,
                List.of(new ActNode(
                        "1РЧС от 2026-01-31 (cstaAg=1)",
                        ActStatus.NEW,
                        List.of(
                                new PnNode("051-1", PnStatus.PENDING_PARENT, null),
                                new PnNode("051-2", PnStatus.NEW, null)
                        ))),
                List.of(),
                31, 0, 0, 0,
                521, 0, 0, 0,
                List.of(),
                new BigDecimal("100.50"),
                BigDecimal.ZERO,
                false
        );

        Type6ReconcileTreeLogger.appendScaffold(ctx, 14L, 1198L, model);
        String html = ctx.buildHtmlLog();

        assertTrue(html.contains("Сверка актов агентского вознаграждения"), html);
        assertTrue(html.contains("год"), html);
        assertTrue(html.contains("Акты агентского вознаграждения"), html);
        assertTrue(html.contains("1РЧС"), html);
        assertTrue(html.contains("новый") || html.contains("ожидает акт"), html);
        assertFalse(html.contains("NEW/ATTR/UNCH"), html);
        assertFalse(html.contains(">СОБЫТИЕ<") || html.contains("badge-info\">СОБЫТИЕ"), html);
        // свёртываемый акт: код *_START → badge-start (+/−)
        assertTrue(html.contains("badge-start") || html.contains("RECONCILE_TYPE6_ACT"), html);
        assertTrue(html.contains("Сумма Актов за год"), html);
        assertTrue(html.contains("100,50"), html);
        assertTrue(html.contains("<details"), html);
    }

    @Test
    void appendScaffold_summaryHidesUnchangedNodes() {
        AuditExecutionContext ctx = new AuditExecutionContext(14L);
        ctx.setStagingLogLevel(StagingLogLevel.SUMMARY);
        TreeModel model = new TreeModel(
                2026,
                666,
                List.of(
                        new ActNode("A от 2026-01-01 (cstaAg=1)", ActStatus.UNCHANGED,
                                List.of(new PnNode("051-1", PnStatus.UNCHANGED, null))),
                        new ActNode("B от 2026-02-01 (cstaAg=1)", ActStatus.NEW,
                                List.of(new PnNode("051-2", PnStatus.NEW, null)))
                ),
                List.of(),
                1, 0, 1, 0,
                1, 0, 1, 0,
                List.of(),
                BigDecimal.ONE,
                BigDecimal.ONE,
                false
        );
        Type6ReconcileTreeLogger.appendScaffold(ctx, 14L, 1L, model);
        String html = ctx.buildHtmlLog();
        assertTrue(html.contains("Без изменений: 1 акт"), html);
        assertTrue(html.contains("B от 2026-02-01"), html);
        assertFalse(html.contains("A от 2026-01-01"), html);
        assertFalse(html.contains("UNCHANGED"), html);
        assertTrue(html.contains("новый"), html);
    }

    @Test
    void appendScaffold_writesActAttrAndMissing() {
        AuditExecutionContext ctx = new AuditExecutionContext(1L);
        TreeModel model = new TreeModel(
                2026, 10,
                List.of(),
                List.of(new ActNode("X от 2026-02-01 (cstaAg=2)", ActStatus.MISSING_IN_SOURCE, List.of())),
                0, 0, 0, 1,
                0, 0, 0, 0,
                List.of("А-1 (variants=2)"),
                BigDecimal.ZERO, BigDecimal.TEN,
                true
        );
        Type6ReconcileTreeLogger.appendScaffold(ctx, 1L, 2L, model);
        String html = ctx.buildHtmlLog();
        assertTrue(html.contains("Разночтения атрибутов"), html);
        assertTrue(html.contains("отсутствующие в источнике"), html);
        assertTrue(html.contains("удалены"), html);
    }
}
