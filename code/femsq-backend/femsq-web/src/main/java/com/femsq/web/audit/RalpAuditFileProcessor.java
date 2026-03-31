package com.femsq.web.audit;

import com.femsq.web.audit.staging.AuditStagingService;
import com.femsq.web.audit.stage2.RalpStage2Service;
import com.femsq.web.audit.reconcile.AuditReconcileCoordinator;
import java.util.Objects;
import java.util.logging.Logger;
import org.springframework.stereotype.Service;

/**
 * Заглушка обработчика файлов типа "ralp" (RAAudit_ralp и связанные сценарии).
 *
 * Пока только логирует факт обработки файла; реальная логика будет добавлена
 * на последующих этапах переноса из VBA.
 */
@Service
public class RalpAuditFileProcessor implements AuditFileProcessor {

    private static final Logger log = Logger.getLogger(RalpAuditFileProcessor.class.getName());

    // TODO: согласовать реальные значения af_type для сценария RAAudit_ralp.
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
                "<P>Stage 1 (RALP) завершён: " + file.getPath() + ", вставлено строк: " + inserted + "</P>",
                null
        );

        Long executionKey = context.getExecutionKey();
        if (executionKey == null) {
            context.append(
                    AuditLogLevel.WARNING,
                    AuditLogScope.FILE,
                    "FILE_RALP_STAGE2_SKIPPED",
                    "<P>Stage 2 (RALP) пропущен: executionKey отсутствует</P>",
                    null
            );
            return;
        }

        RalpStage2Service.ResolutionResult resolutionResult = ralpStage2Service.resolveForExecution(executionKey);
        context.append(
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "FILE_RALP_STAGE2A2B",
                "<P>Stage 2 (RALP) выполнен: ralprtCstAgPn=" + resolutionResult.resolvedCstAgPn()
                        + ", ralprtOgSender=" + resolutionResult.resolvedOgSender()
                        + ", ralprsSender=" + resolutionResult.resolvedSmSender()
                        + ", ralprtStatus=" + resolutionResult.computedStatus() + "</P>",
                null
        );

        reconcileCoordinator.run(context, file);
    }
}
