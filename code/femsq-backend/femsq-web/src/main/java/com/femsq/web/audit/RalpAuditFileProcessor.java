package com.femsq.web.audit;

import com.femsq.web.audit.reconcile.AuditReconcileCoordinator;
import com.femsq.web.audit.staging.AuditStagingService;
import com.femsq.web.audit.stage2.RalpFkAnomalyFormatter;
import com.femsq.web.audit.stage2.RalpStage2Service;
import java.util.Objects;
import java.util.logging.Logger;
import org.springframework.stereotype.Service;

/**
 * Обработчик файлов type=3 (аренда земли, RALP): Stage 1 → Stage 2 → reconcile.
 */
@Service
public class RalpAuditFileProcessor implements AuditFileProcessor {

    private static final Logger log = Logger.getLogger(RalpAuditFileProcessor.class.getName());

    private static final int TYPE_RALP = 3;

    private final AuditStagingService auditStagingService;
    private final RalpStage2Service ralpStage2Service;
    private final AuditReconcileCoordinator reconcileCoordinator;

    public RalpAuditFileProcessor(AuditStagingService auditStagingService,
                                  RalpStage2Service ralpStage2Service,
                                  AuditReconcileCoordinator reconcileCoordinator) {
        this.auditStagingService = Objects.requireNonNull(auditStagingService, "auditStagingService");
        this.ralpStage2Service = Objects.requireNonNull(ralpStage2Service, "ralpStage2Service");
        this.reconcileCoordinator = Objects.requireNonNull(reconcileCoordinator, "reconcileCoordinator");
    }

    @Override
    public boolean supports(Integer type) {
        return Objects.equals(type, TYPE_RALP);
    }

    @Override
    public void process(AuditExecutionContext context, AuditFile file) {
        int inserted = 0;
        if (Integer.valueOf(1).equals(file.getSource())) {
            inserted = auditStagingService.loadToStaging(context, file);
        }
        int insertedFinal = inserted;
        log.info(() -> "[AuditExecution] Ralp processor Stage1, file=" + file.getPath()
                + ", type=" + file.getType() + ", inserted=" + insertedFinal);
        context.append(
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "FILE_RALP_STAGE1",
                "<P>Этап 1 (RALP) завершён: " + file.getPath() + ", вставлено строк = " + inserted + "</P>",
                null
        );

        Long executionKey = context.getExecutionKey();
        if (executionKey == null) {
            context.append(
                    AuditLogLevel.WARNING,
                    AuditLogScope.FILE,
                    "FILE_RALP_STAGE2_SKIPPED",
                    "<P>Этап 2 (RALP) пропущен: отсутствует ключ выполнения</P>",
                    null
            );
            return;
        }

        RalpStage2Service.ResolutionResult resolutionResult = ralpStage2Service.resolveForExecution(executionKey);
        context.append(
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "FILE_RALP_STAGE2A2B",
                RalpFkAnomalyFormatter.formatStage2SummaryHtml(
                        resolutionResult.resolvedCstAgPn(),
                        resolutionResult.resolvedOgSender(),
                        resolutionResult.resolvedSmSender(),
                        resolutionResult.computedStatus(),
                        resolutionResult.stagingRows(),
                        resolutionResult.unresolvedRows(),
                        resolutionResult.unresolvedCst(),
                        resolutionResult.unresolvedOg(),
                        resolutionResult.unresolvedDate()
                ),
                null
        );

        // §9.3.8.4: детализация A1–A4 — в дереве сверки (одна точка истины); здесь только агрегат Stage 2.

        reconcileCoordinator.run(context, file);
    }
}
