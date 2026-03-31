package com.femsq.web.audit.reconcile;

import com.femsq.web.audit.AuditExecutionContext;
import com.femsq.web.audit.AuditFile;
import com.femsq.web.audit.AuditLogEntry;
import com.femsq.web.audit.AuditLogLevel;
import com.femsq.web.audit.AuditLogScope;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.stereotype.Service;

/**
 * Координатор reconcile с единым форматом логирования шагов.
 *
 * <p>При {@code addRa=false} reconcile всё равно вызывается с {@link ReconcileContext#addRa()} {@code false},
 * чтобы сервисы (например type=5) могли выполнить read-model и dry-run без записи в доменные таблицы.</p>
 */
@Service
public class AuditReconcileCoordinator {

    private final List<AuditReconcileService> reconcileServices;

    public AuditReconcileCoordinator(List<AuditReconcileService> reconcileServices) {
        this.reconcileServices = Objects.requireNonNull(reconcileServices, "reconcileServices");
    }

    public ReconcileResult run(AuditExecutionContext context, AuditFile file) {
        Long executionKey = context.getExecutionKey();
        if (executionKey == null) {
            ReconcileResult skipped = ReconcileResult.skipped("executionKey is null");
            appendResult(context, file, skipped);
            return skipped;
        }
        if (file.getType() == null) {
            ReconcileResult skipped = ReconcileResult.skipped("fileType is null");
            appendResult(context, file, skipped);
            return skipped;
        }

        AuditReconcileService service = reconcileServices.stream()
                .filter(candidate -> candidate.supports(file.getType()))
                .findFirst()
                .orElse(null);

        if (service == null) {
            ReconcileResult skipped = ReconcileResult.skipped("reconcile service not found for fileType=" + file.getType());
            appendResult(context, file, skipped);
            return skipped;
        }

        Instant reconcileStartedAt = Instant.now();
        String reconcileSpanId = context.beginSpan(
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "RECONCILE_START",
                "<P>Reconcile start: type=" + file.getType() + ", execKey=" + executionKey + "</P>",
                null
        );

        boolean addRa = Boolean.TRUE.equals(context.getAddRa());
        ReconcileResult result = context.inSpan(reconcileSpanId, () -> service.reconcile(new ReconcileContext(
                executionKey,
                context.getAuditId(),
                addRa,
                file.getType()
        )));
        appendResult(context, file, result, reconcileSpanId, reconcileStartedAt);
        return result;
    }

    private void appendResult(AuditExecutionContext context,
                              AuditFile file,
                              ReconcileResult result,
                              String reconcileSpanId,
                              Instant reconcileStartedAt) {
        String code = result.applied() ? "RECONCILE_DONE" : "RECONCILE_SKIPPED";
        AuditLogLevel level = result.applied() ? AuditLogLevel.INFO : AuditLogLevel.WARNING;
        String duration = formatDuration(reconcileStartedAt, Instant.now());
        String countersSummary = summarizeCounters(result.message());
        String summaryLine = "<P><b>Reconcile</b>: type=" + file.getType()
                + ", applied=" + result.applied()
                + ", affectedRows=" + result.affectedRows()
                + ", duration=" + duration
                + "</P>";
        String countersLine = countersSummary.isBlank()
                ? "<P>details: " + escape(result.message()) + "</P>"
                : "<P>counters: " + escape(countersSummary) + "</P>";
        context.endSpan(reconcileSpanId, level, AuditLogScope.FILE, code,
                summaryLine + countersLine,
                null);
    }

    private void appendResult(AuditExecutionContext context, AuditFile file, ReconcileResult result) {
        // legacy path for early-exit cases (no reconcile span)
        String code = result.applied() ? "RECONCILE_DONE" : "RECONCILE_SKIPPED";
        AuditLogLevel level = result.applied() ? AuditLogLevel.INFO : AuditLogLevel.WARNING;
        String countersSummary = summarizeCounters(result.message());
        String summaryLine = "<P><b>Reconcile</b>: type=" + file.getType()
                + ", applied=" + result.applied()
                + ", affectedRows=" + result.affectedRows()
                + "</P>";
        String countersLine = countersSummary.isBlank()
                ? "<P>details: " + escape(result.message()) + "</P>"
                : "<P>counters: " + escape(countersSummary) + "</P>";
        context.append(level, AuditLogScope.FILE, code,
                summaryLine + countersLine,
                null);
    }

    private String summarizeCounters(String message) {
        if (message == null || message.isBlank()) {
            return "";
        }
        int idx = message.indexOf("; ");
        String tail = idx >= 0 ? message.substring(idx + 2) : message;
        Map<String, String> kv = parseKeyValues(tail);
        if (kv.isEmpty()) {
            return "";
        }

        // Keep this short (1 line): most important counters first.
        Set<String> preferred = Set.of(
                "dryRun", "applyRequested", "applyBlocked",
                "inserted", "updated", "unchanged", "errors",
                "rcRowsConsidered", "rcParseInvalid", "rcMissingBaseRa",
                "rcCategoryNEW", "rcCategoryCHANGED", "rcCategoryUNCHANGED",
                "rcApplyDeltaNew", "rcApplyDeltaChanged",
                "marker_raStepAlreadyDone", "marker_rcStepAlreadyDone",
                "deleteEnabled", "raDeletePlanned", "raDeleteApplied", "rcDeletePlanned", "rcDeleteApplied"
        );

        List<String> parts = new ArrayList<>();
        for (Map.Entry<String, String> e : kv.entrySet()) {
            if (preferred.contains(e.getKey())) {
                parts.add(e.getKey() + "=" + e.getValue());
            }
            if (parts.size() >= 18) {
                break;
            }
        }
        return String.join(", ", parts);
    }

    private Map<String, String> parseKeyValues(String text) {
        Map<String, String> result = new LinkedHashMap<>();
        Pattern p = Pattern.compile("([A-Za-z0-9_]+)=([^,]+)");
        Matcher m = p.matcher(text);
        while (m.find()) {
            String key = m.group(1);
            String value = m.group(2).trim();
            result.putIfAbsent(key, value);
        }
        return result;
    }

    private String escape(String value) {
        return value == null ? "" : value.replace("<", "&lt;").replace(">", "&gt;");
    }

    private String formatDuration(Instant start, Instant end) {
        if (start == null || end == null) {
            return "-";
        }
        long seconds = ChronoUnit.SECONDS.between(start, end);
        if (seconds < 0) {
            seconds = 0;
        }
        long minutes = seconds / 60;
        long remSeconds = seconds % 60;
        return minutes + "m " + remSeconds + "s";
    }
}
