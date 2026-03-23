package com.femsq.web.audit;

import com.femsq.web.audit.staging.AuditStagingService;
import com.femsq.web.audit.stage2.AgFeeStage2Service;
import com.femsq.web.audit.reconcile.AuditReconcileCoordinator;
import java.time.Instant;
import java.util.Objects;
import java.util.logging.Logger;
import org.springframework.stereotype.Service;

/**
 * Процессор файла типа 6: Stage 1 (Excel -> ags.ra_stg_agfee).
 */
@Service
public class AgFee2306AuditFileProcessor implements AuditFileProcessor {

    private static final Logger log = Logger.getLogger(AgFee2306AuditFileProcessor.class.getName());
    private static final int TYPE_AGFEE_2306 = 6;
    private final AuditStagingService auditStagingService;
    private final AgFeeStage2Service agFeeStage2Service;
    private final AuditReconcileCoordinator reconcileCoordinator;

    public AgFee2306AuditFileProcessor(AuditStagingService auditStagingService,
                                       AgFeeStage2Service agFeeStage2Service,
                                       AuditReconcileCoordinator reconcileCoordinator) {
        this.auditStagingService = Objects.requireNonNull(auditStagingService, "auditStagingService");
        this.agFeeStage2Service = Objects.requireNonNull(agFeeStage2Service, "agFeeStage2Service");
        this.reconcileCoordinator = Objects.requireNonNull(reconcileCoordinator, "reconcileCoordinator");
    }

    @Override
    public boolean supports(Integer type) {
        return Objects.equals(type, TYPE_AGFEE_2306);
    }

    @Override
    public void process(AuditExecutionContext context, AuditFile file) {
        int inserted = 0;
        if (Integer.valueOf(1).equals(file.getSource())) {
            inserted = auditStagingService.loadToStaging(context, file);
        }
        int insertedFinal = inserted;
        log.info(() -> "[AuditExecution] AgFee2306 processor Stage1, file=" + file.getPath()
                + ", type=" + file.getType() + ", inserted=" + insertedFinal);
        context.appendEntry(new AuditLogEntry(
                Instant.now(),
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "FILE_AGFEE_2306_STAGE1",
                "<P>Stage 1 (AgFee2306) завершён: " + file.getPath() + ", вставлено строк: " + inserted + "</P>",
                null
        ));

        if (!Integer.valueOf(1).equals(context.getAuditType())) {
            context.appendEntry(new AuditLogEntry(
                    Instant.now(),
                    AuditLogLevel.INFO,
                    AuditLogScope.FILE,
                    "FILE_AGFEE_2306_STAGE2_SKIPPED_BY_AUDIT_TYPE",
                    "<P>Stage 2 (AgFee2306) пропущен: guard ctx.auditType == 1 не выполнен</P>",
                    null
            ));
            return;
        }

        Long executionKey = context.getExecutionKey();
        if (executionKey == null) {
            context.appendEntry(new AuditLogEntry(
                    Instant.now(),
                    AuditLogLevel.WARNING,
                    AuditLogScope.FILE,
                    "FILE_AGFEE_2306_STAGE2_SKIPPED",
                    "<P>Stage 2 (AgFee2306) пропущен: executionKey отсутствует</P>",
                    null
            ));
            return;
        }

        int resolved = agFeeStage2Service.resolveForExecution(executionKey);
        context.appendEntry(new AuditLogEntry(
                Instant.now(),
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "FILE_AGFEE_2306_STAGE2A",
                "<P>Stage 2a (AgFee2306) выполнен: oafptOgKey=" + resolved + "</P>",
                null
        ));

        reconcileCoordinator.run(context, file);
    }
}
