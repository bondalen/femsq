package com.femsq.web.audit.runtime;

import com.femsq.database.model.RaExecution;
import com.femsq.database.service.RaExecutionService;
import java.util.List;
import java.util.logging.Logger;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Периодически проверяет {@code ags.ra_execution} на записи {@code RUNNING}, не сменившие статус дольше порога.
 *
 * <p>Не изменяет данные: только пишет предупреждение в лог для эксплуатации (метрики можно навесить на этот же запрос).</p>
 */
@Component
@ConditionalOnProperty(name = "audit.execution.stale-watchdog-enabled", havingValue = "true", matchIfMissing = true)
public class AuditExecutionStalenessWatchdog {

    private static final Logger log = Logger.getLogger(AuditExecutionStalenessWatchdog.class.getName());

    private final RaExecutionService raExecutionService;
    private final int staleAfterMinutes;

    public AuditExecutionStalenessWatchdog(
            RaExecutionService raExecutionService,
            @Value("${audit.execution.stale-warning-after-minutes:45}") int staleAfterMinutes) {
        this.raExecutionService = raExecutionService;
        this.staleAfterMinutes = staleAfterMinutes;
    }

    /**
     * По умолчанию раз в 10 минут (cron можно переопределить).
     */
    @Scheduled(cron = "${audit.execution.stale-check-cron:0 */10 * * * *}")
    public void logStaleRunningExecutions() {
        if (staleAfterMinutes <= 0) {
            return;
        }
        try {
            List<RaExecution> stale = raExecutionService.listRunningOlderThanMinutes(staleAfterMinutes);
            for (RaExecution row : stale) {
                log.warning(() -> "[AuditExecutionStale] RUNNING longer than " + staleAfterMinutes + "m: exec_key="
                        + row.execKey() + ", auditId=" + row.execAdtKey() + ", started=" + row.execStarted());
            }
        } catch (Exception ex) {
            log.warning("[AuditExecutionStale] check failed: " + ex.getMessage());
        }
    }
}
