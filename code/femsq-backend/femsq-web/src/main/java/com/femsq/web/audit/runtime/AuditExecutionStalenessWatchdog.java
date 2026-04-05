package com.femsq.web.audit.runtime;

import com.femsq.database.model.RaExecution;
import com.femsq.database.service.RaExecutionService;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.Gauge;
import io.micrometer.core.instrument.MeterRegistry;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.logging.Logger;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Периодически проверяет {@code ags.ra_execution} на записи {@code RUNNING}, не сменившие статус дольше порога.
 *
 * <p>Не изменяет данные: предупреждение в лог и (при наличии Actuator) метрики Micrometer.</p>
 */
@Component
@ConditionalOnProperty(name = "audit.execution.stale-watchdog-enabled", havingValue = "true", matchIfMissing = true)
public class AuditExecutionStalenessWatchdog {

    private static final Logger log = Logger.getLogger(AuditExecutionStalenessWatchdog.class.getName());

    private final RaExecutionService raExecutionService;
    private final int staleAfterMinutes;
    private final AtomicInteger staleRunningGauge = new AtomicInteger(0);
    private final Counter staleRowsDetectedTotal;
    private final Counter checkFailureTotal;

    public AuditExecutionStalenessWatchdog(
            RaExecutionService raExecutionService,
            @Value("${audit.execution.stale-warning-after-minutes:45}") int staleAfterMinutes,
            ObjectProvider<MeterRegistry> meterRegistryProvider) {
        this.raExecutionService = raExecutionService;
        this.staleAfterMinutes = staleAfterMinutes;
        MeterRegistry registry = meterRegistryProvider.getIfAvailable();
        if (registry != null) {
            Gauge.builder("audit.execution.stale.running", staleRunningGauge, AtomicInteger::get)
                    .description("Число строк ags.ra_execution в RUNNING дольше порога stale-warning-after-minutes")
                    .register(registry);
            this.staleRowsDetectedTotal = Counter.builder("audit.execution.stale.rows.detected")
                    .description("Накопленное число «зависших» строк, зафиксированных watchdog (по одному тику на строку)")
                    .register(registry);
            this.checkFailureTotal = Counter.builder("audit.execution.stale.check.failure")
                    .description("Ошибки выполнения проверки watchdog")
                    .register(registry);
        } else {
            this.staleRowsDetectedTotal = null;
            this.checkFailureTotal = null;
        }
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
            staleRunningGauge.set(stale.size());
            if (staleRowsDetectedTotal != null && !stale.isEmpty()) {
                staleRowsDetectedTotal.increment(stale.size());
            }
            for (RaExecution row : stale) {
                log.warning(() -> "[AuditExecutionStale] RUNNING longer than " + staleAfterMinutes + "m: exec_key="
                        + row.execKey() + ", auditId=" + row.execAdtKey() + ", started=" + row.execStarted());
            }
        } catch (Exception ex) {
            staleRunningGauge.set(0);
            if (checkFailureTotal != null) {
                checkFailureTotal.increment();
            }
            log.warning("[AuditExecutionStale] check failed: " + ex.getMessage());
        }
    }
}
