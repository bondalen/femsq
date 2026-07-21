package com.femsq.web.audit.reconcile;

import com.femsq.web.audit.AuditExecutionContext;
import com.femsq.web.audit.AuditLogLevel;
import com.femsq.web.audit.AuditLogScope;
import com.femsq.web.audit.AuditMoneyFormat;
import com.femsq.web.audit.staging.StagingLogLevel;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Дерево сверки type=6 (AgFee): Акт → Пункты + диагностические секции и годовая сумма.
 *
 * <p>Стилистика как type=3/5: Crimson / DarkGreen / Chocolate / CadetBlue.
 * В режиме SUMMARY узлы «без изменений» сворачиваются в одну строку-сводку.
 */
public final class Type6ReconcileTreeLogger {

    static final String HTML_CRIMSON = "#DC143C";
    static final String HTML_DARK_GREEN = "#006400";
    static final String HTML_CHOCOLATE = "#D2691E";
    static final String HTML_CADET = "#5F9EA0";

    private Type6ReconcileTreeLogger() {
    }

    /** Статус узла Акт. */
    public enum ActStatus {
        NEW, ATTR_CHANGED, UNCHANGED, MISSING_IN_SOURCE, ATTR_AMBIGUOUS
    }

    /** Статус узла Пункт. */
    public enum PnStatus {
        NEW, SUM_CHANGED, UNCHANGED, MISSING_IN_SOURCE, AMBIGUOUS_TTL, PENDING_PARENT
    }

    /**
     * Пункт под актом.
     *
     * @param label  подпись (код стройки / cstap)
     * @param status статус
     * @param detail доп. текст (например БД/ист суммы)
     */
    public record PnNode(String label, PnStatus status, String detail) {
    }

    /**
     * Акт с дочерними пунктами.
     *
     * @param label  № + дата + агент
     * @param status статус заголовка
     * @param points пункты
     */
    public record ActNode(String label, ActStatus status, List<PnNode> points) {
    }

    /**
     * Модель дерева и счётчиков.
     *
     * @param year            @yearAct
     * @param stagingLines    строк staging
     * @param acts            акты (NEW/ATTR/UNCHANGED + их пункты)
     * @param missingActs     акты только в БД
     * @param actsNew         счётчик
     * @param actsUpdated     счётчик
     * @param actsUnchanged   счётчик
     * @param actsMissing     счётчик
     * @param linesNew        счётчик
     * @param linesUpdated    счётчик
     * @param linesUnchanged  счётчик
     * @param linesMissing    счётчик
     * @param actAttrWarnings тексты ActAttr
     * @param sourceSum       сумма источника
     * @param dbSum           сумма БД
     * @param applyRequested  addRa
     */
    public record TreeModel(
            int year,
            int stagingLines,
            List<ActNode> acts,
            List<ActNode> missingActs,
            int actsNew,
            int actsUpdated,
            int actsUnchanged,
            int actsMissing,
            int linesNew,
            int linesUpdated,
            int linesUnchanged,
            int linesMissing,
            List<String> actAttrWarnings,
            BigDecimal sourceSum,
            BigDecimal dbSum,
            boolean applyRequested
    ) {
    }

    /**
     * Пишет дерево в текущий span сверки.
     */
    public static void appendScaffold(
            AuditExecutionContext audit,
            long auditId,
            long execKey,
            TreeModel model
    ) {
        if (audit == null || model == null) {
            return;
        }
        StagingLogLevel level = audit.getStagingLogLevel();
        if (level == null) {
            level = StagingLogLevel.SUMMARY;
        }
        boolean verbose = level == StagingLogLevel.VERBOSE;

        Map<String, String> base = baseMeta(auditId, execKey);
        base.put("year", String.valueOf(model.year()));
        base.put("applyRequested", String.valueOf(model.applyRequested()));

        appendPlain(audit, "RECONCILE_TYPE6_STAGING_TOTAL",
                "<P>" + formatSummaryParagraph(model) + "</P>",
                withMeta(base, Map.of("stagingLines", String.valueOf(model.stagingLines())),
                        "INFO", "CRIMSON", "BOLD"));

        if (model.actAttrWarnings() != null && !model.actAttrWarnings().isEmpty()) {
            appendPlain(audit, "RECONCILE_TYPE6_ACT_ATTR",
                    "<P><font color=\"" + HTML_CRIMSON
                            + "\">Разночтения атрибутов Актов в источнике:</font> "
                            + escape(String.join("; ", limit(model.actAttrWarnings(), 20)))
                            + "</P>",
                    withMeta(base, Map.of("count", String.valueOf(model.actAttrWarnings().size())),
                            "WARNING", "CRIMSON", "NORMAL"));
        }

        String trunkId = audit.beginSpan(
                AuditLogLevel.INFO,
                AuditLogScope.SHEET,
                "RECONCILE_TYPE6_ACTS_START",
                "<P><b>Акты агентского вознаграждения</b>"
                        + (model.acts().isEmpty() ? ""
                        : ": <font color=\"" + HTML_CRIMSON + "\">" + model.acts().size() + "</font>")
                        + "</P>",
                withMeta(base, Map.of("branch", "acts"), "START", "BLUE", "BOLD")
        );
        try {
            audit.inSpan(trunkId, () -> appendActs(audit, base, model, verbose));
        } finally {
            audit.endSpan(trunkId, AuditLogLevel.INFO, AuditLogScope.SHEET,
                    "RECONCILE_TYPE6_ACTS_END",
                    "<P>Акты — конец</P>",
                    withMeta(base, Map.of("branch", "acts"), "END", "BLUE", "NORMAL"));
        }

        if (model.missingActs() != null && !model.missingActs().isEmpty()) {
            appendPlain(audit, "RECONCILE_TYPE6_ACT_MISSING",
                    "<P><font color=\"" + HTML_CRIMSON + "\">Акты отсутствующие в источнике ("
                            + model.missingActs().size() + ")"
                            + (model.applyRequested() ? ", удалены" : ", только просмотр")
                            + ":</font> "
                            + escape(String.join("; ", limit(
                                    model.missingActs().stream().map(ActNode::label).toList(), 30)))
                            + "</P>",
                    withMeta(base, Map.of("count", String.valueOf(model.missingActs().size())),
                            "WARNING", "CRIMSON", "NORMAL"));
        }

        BigDecimal src = model.sourceSum() == null ? BigDecimal.ZERO : model.sourceSum();
        BigDecimal db = model.dbSum() == null ? BigDecimal.ZERO : model.dbSum();
        BigDecimal diff = src.subtract(db);
        appendPlain(audit, "RECONCILE_TYPE6_YEAR_SUM",
                "<P><b>Сумма Актов за год</b>. Итого, источник: <b><font color=\""
                        + HTML_DARK_GREEN + "\">" + escape(AuditMoneyFormat.format(src))
                        + "</font></b>; Итого, БД: <b><font color=\""
                        + HTML_CHOCOLATE + "\">" + escape(AuditMoneyFormat.format(db))
                        + "</font></b>; Разница: <font color=\""
                        + HTML_CRIMSON + "\">" + escape(AuditMoneyFormat.format(diff))
                        + "</font>;</P>",
                withMeta(base, Map.of(
                        "sourceSum", src.toPlainString(),
                        "dbSum", db.toPlainString(),
                        "diff", diff.toPlainString()), "INFO", "CHOCOLATE", "BOLD"));
    }

    /**
     * Человекочитаемый абзац сводки сверки type=6 (для дерева и «подробности»).
     */
    public static String formatSummaryParagraph(TreeModel model) {
        if (model == null) {
            return "";
        }
        return "Сверка актов агентского вознаграждения за <b>" + model.year() + "</b>: "
                + "строк файла <b><font color=\"" + HTML_CRIMSON + "\">" + model.stagingLines()
                + "</font></b>; "
                + "актов — новые " + model.actsNew()
                + ", изменены атрибуты " + model.actsUpdated()
                + ", без изменений " + model.actsUnchanged()
                + ", нет в источнике " + model.actsMissing()
                + "; пунктов — новые " + model.linesNew()
                + ", изменена сумма " + model.linesUpdated()
                + ", без изменений " + model.linesUnchanged()
                + ", нет в источнике " + model.linesMissing()
                + "; обновление БД: " + (model.applyRequested() ? "да" : "нет");
    }

    /** Русская подпись статуса акта. */
    static String actStatusLabel(ActStatus status) {
        if (status == null) {
            return "";
        }
        return switch (status) {
            case NEW -> "новый";
            case ATTR_CHANGED -> "изменены атрибуты";
            case UNCHANGED -> "без изменений";
            case MISSING_IN_SOURCE -> "нет в источнике";
            case ATTR_AMBIGUOUS -> "разночтения атрибутов";
        };
    }

    /** Русская подпись статуса пункта. */
    static String pnStatusLabel(PnStatus status) {
        if (status == null) {
            return "";
        }
        return switch (status) {
            case NEW -> "новый";
            case SUM_CHANGED -> "изменена сумма";
            case UNCHANGED -> "без изменений";
            case MISSING_IN_SOURCE -> "нет в источнике";
            case AMBIGUOUS_TTL -> "неоднозначная сумма";
            case PENDING_PARENT -> "ожидает акт";
        };
    }

    private static void appendActs(
            AuditExecutionContext audit,
            Map<String, String> base,
            TreeModel model,
            boolean verbose
    ) {
        List<ActNode> acts = model.acts() == null ? List.of() : model.acts();
        if (acts.isEmpty()) {
            appendPlain(audit, "RECONCILE_TYPE6_ACTS_EMPTY",
                    "<P>Нет актов для отображения в дереве (за год в источнике).</P>",
                    withMeta(base, Map.of(), "INFO", "BLUE", "NORMAL"));
            return;
        }

        if (!verbose && model.actsUnchanged() > 0) {
            appendPlain(audit, "RECONCILE_TYPE6_UNCH_SUMMARY",
                    "<P><font color=\"" + HTML_CADET + "\">Без изменений: "
                            + model.actsUnchanged() + " акт(ов), "
                            + model.linesUnchanged() + " пункт(ов)"
                            + " (полный список — в режиме VERBOSE).</font></P>",
                    withMeta(base, Map.of(
                            "actsUnchanged", String.valueOf(model.actsUnchanged()),
                            "linesUnchanged", String.valueOf(model.linesUnchanged())),
                            "INFO", "CADETBLUE", "NORMAL"));
        }

        int shown = 0;
        int limit = verbose ? 200 : 40;
        int skippedUnchanged = 0;
        for (ActNode act : acts) {
            boolean actInteresting = act.status() != ActStatus.UNCHANGED
                    || hasInterestingPoints(act);
            if (!verbose && !actInteresting) {
                skippedUnchanged++;
                continue;
            }
            if (shown >= limit) {
                appendPlain(audit, "RECONCILE_TYPE6_ACT_MORE",
                        "<P>… ещё актов с изменениями: "
                                + Math.max(0, countInteresting(acts, verbose) - limit)
                                + "</P>",
                        withMeta(base, Map.of(), "INFO", "BLUE", "NORMAL"));
                break;
            }
            shown++;
            String statusColor = statusColor(act.status());
            String actSpan = audit.beginSpan(
                    AuditLogLevel.INFO,
                    AuditLogScope.SHEET,
                    "RECONCILE_TYPE6_ACT_START",
                    "<P><b>" + shown + ".</b> <font color=\"" + HTML_CADET + "\">"
                            + escape(act.label()) + "</font> — <font color=\""
                            + statusColor + "\">" + actStatusLabel(act.status()) + "</font></P>",
                    withMeta(base, Map.of(
                            "actStatus", act.status().name(),
                            "points", String.valueOf(act.points() == null ? 0 : act.points().size())),
                            "INFO", "CADETBLUE", "NORMAL")
            );
            try {
                audit.inSpan(actSpan, () -> appendPoints(audit, base, act, verbose));
            } finally {
                audit.endSpan(actSpan, AuditLogLevel.INFO, AuditLogScope.SHEET,
                        "RECONCILE_TYPE6_ACT_END",
                        "<P></P>",
                        withMeta(base, Map.of(), "END", "BLUE", "NORMAL"));
            }
        }
        if (!verbose && skippedUnchanged > 0 && shown == 0) {
            appendPlain(audit, "RECONCILE_TYPE6_ACTS_ALL_UNCH",
                    "<P>Все отображаемые акты без изменений относительно БД.</P>",
                    withMeta(base, Map.of(), "INFO", "BLUE", "NORMAL"));
        }
    }

    private static boolean hasInterestingPoints(ActNode act) {
        if (act.points() == null) {
            return false;
        }
        for (PnNode pn : act.points()) {
            if (pn.status() != PnStatus.UNCHANGED) {
                return true;
            }
        }
        return false;
    }

    private static int countInteresting(List<ActNode> acts, boolean verbose) {
        if (verbose) {
            return acts.size();
        }
        int n = 0;
        for (ActNode act : acts) {
            if (act.status() != ActStatus.UNCHANGED || hasInterestingPoints(act)) {
                n++;
            }
        }
        return n;
    }

    private static void appendPoints(
            AuditExecutionContext audit,
            Map<String, String> base,
            ActNode act,
            boolean verbose
    ) {
        List<PnNode> points = act.points() == null ? List.of() : act.points();
        if (points.isEmpty()) {
            appendPlain(audit, "RECONCILE_TYPE6_PN_EMPTY",
                    "<P><font color=\"" + HTML_CHOCOLATE + "\">(пунктов нет)</font></P>",
                    withMeta(base, Map.of(), "INFO", "CHOCOLATE", "NORMAL"));
            return;
        }
        int unchangedHidden = 0;
        int i = 0;
        int shown = 0;
        for (PnNode pn : points) {
            i++;
            if (!verbose && pn.status() == PnStatus.UNCHANGED) {
                unchangedHidden++;
                continue;
            }
            shown++;
            if (shown > 60) {
                appendPlain(audit, "RECONCILE_TYPE6_PN_MORE",
                        "<P>… ещё пунктов: " + (points.size() - i + 1) + "</P>",
                        withMeta(base, Map.of(), "INFO", "BLUE", "NORMAL"));
                break;
            }
            String detail = (pn.detail() == null || pn.detail().isBlank())
                    ? ""
                    : " — " + escape(pn.detail());
            appendPlain(audit, "RECONCILE_TYPE6_PN",
                    "<P><font color=\"" + HTML_CHOCOLATE + "\">" + shown + ".</font> "
                            + escape(pn.label()) + " — <font color=\""
                            + pnStatusColor(pn.status()) + "\">" + pnStatusLabel(pn.status())
                            + "</font>" + detail + "</P>",
                    withMeta(base, Map.of("pnStatus", pn.status().name()),
                            "INFO", "CHOCOLATE", "NORMAL"));
        }
        if (!verbose && unchangedHidden > 0 && shown > 0) {
            appendPlain(audit, "RECONCILE_TYPE6_PN_UNCH_HIDDEN",
                    "<P><font color=\"" + HTML_CADET + "\">… и ещё "
                            + unchangedHidden + " пункт(ов) без изменений</font></P>",
                    withMeta(base, Map.of("unchangedHidden", String.valueOf(unchangedHidden)),
                            "INFO", "CADETBLUE", "NORMAL"));
        }
    }

    private static String statusColor(ActStatus s) {
        return switch (s) {
            case NEW -> HTML_DARK_GREEN;
            case ATTR_CHANGED -> HTML_CHOCOLATE;
            case MISSING_IN_SOURCE, ATTR_AMBIGUOUS -> HTML_CRIMSON;
            case UNCHANGED -> HTML_CADET;
        };
    }

    private static String pnStatusColor(PnStatus s) {
        return switch (s) {
            case NEW, PENDING_PARENT -> HTML_DARK_GREEN;
            case SUM_CHANGED -> HTML_CHOCOLATE;
            case MISSING_IN_SOURCE, AMBIGUOUS_TTL -> HTML_CRIMSON;
            case UNCHANGED -> HTML_CADET;
        };
    }

    private static void appendPlain(
            AuditExecutionContext audit,
            String code,
            String html,
            Map<String, String> meta
    ) {
        audit.append(AuditLogLevel.INFO, AuditLogScope.SUMMARY, code, html, meta);
    }

    private static Map<String, String> baseMeta(long auditId, long execKey) {
        Map<String, String> m = new LinkedHashMap<>();
        m.put("auditId", String.valueOf(auditId));
        m.put("executionKey", String.valueOf(execKey));
        m.put("fileType", "6");
        return m;
    }

    private static Map<String, String> withMeta(
            Map<String, String> base,
            Map<String, String> extra,
            String messageType,
            String colorHint,
            String emphasis
    ) {
        Map<String, String> m = new HashMap<>(base);
        m.putAll(extra);
        m.put("messageType", messageType);
        m.put("colorHint", colorHint);
        m.put("emphasis", emphasis);
        return m;
    }

    private static List<String> limit(List<String> items, int max) {
        if (items.size() <= max) {
            return items;
        }
        List<String> out = new ArrayList<>(items.subList(0, max));
        out.add("… ещё " + (items.size() - max));
        return out;
    }

    private static String escape(String raw) {
        if (raw == null) {
            return "";
        }
        return raw.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
    }
}
