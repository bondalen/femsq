package com.femsq.web.audit;

import com.femsq.web.audit.staging.AuditStagingService;
import com.femsq.web.audit.stage2.CnPrDocStage2Service;
import com.femsq.web.audit.reconcile.AuditReconcileCoordinator;
import java.time.Instant;
import java.util.Objects;
import java.util.logging.Logger;
import org.springframework.stereotype.Service;

/**
 * Процессор файла типа 2: Stage 1 (Excel -> ags.ra_stg_cn_prdoc).
 */
@Service
public class CnPrDocAuditFileProcessor implements AuditFileProcessor {

    private static final Logger log = Logger.getLogger(CnPrDocAuditFileProcessor.class.getName());
    private static final int TYPE_CN_PRDOC = 2;
    private final AuditStagingService auditStagingService;
    private final CnPrDocStage2Service cnPrDocStage2Service;
    private final AuditReconcileCoordinator reconcileCoordinator;

    public CnPrDocAuditFileProcessor(AuditStagingService auditStagingService,
                                     CnPrDocStage2Service cnPrDocStage2Service,
                                     AuditReconcileCoordinator reconcileCoordinator) {
        this.auditStagingService = Objects.requireNonNull(auditStagingService, "auditStagingService");
        this.cnPrDocStage2Service = Objects.requireNonNull(cnPrDocStage2Service, "cnPrDocStage2Service");
        this.reconcileCoordinator = Objects.requireNonNull(reconcileCoordinator, "reconcileCoordinator");
    }

    @Override
    public boolean supports(Integer type) {
        return Objects.equals(type, TYPE_CN_PRDOC);
    }

    @Override
    public void process(AuditExecutionContext context, AuditFile file) {
        int inserted = 0;
        if (Integer.valueOf(1).equals(file.getSource())) {
            inserted = auditStagingService.loadToStaging(context, file);
        }
        int insertedFinal = inserted;
        log.info(() -> "[AuditExecution] CnPrDoc processor Stage1, file=" + file.getPath()
                + ", type=" + file.getType() + ", inserted=" + insertedFinal);
        context.appendEntry(new AuditLogEntry(
                Instant.now(),
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "FILE_CN_PRDOC_STAGE1",
                "<P>Stage 1 (CnPrDoc) завершён: " + file.getPath() + ", вставлено строк: " + inserted + "</P>",
                null
        ));

        Long executionKey = context.getExecutionKey();
        if (executionKey == null) {
            context.appendEntry(new AuditLogEntry(
                    Instant.now(),
                    AuditLogLevel.WARNING,
                    AuditLogScope.FILE,
                    "FILE_CN_PRDOC_STAGE2_SKIPPED",
                    "<P>Stage 2 (CnPrDoc) пропущен: executionKey отсутствует</P>",
                    null
            ));
            return;
        }

        CnPrDocStage2Service.ResolutionResult resolutionResult = cnPrDocStage2Service.resolveForExecution(executionKey);
        context.appendEntry(new AuditLogEntry(
                Instant.now(),
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "FILE_CN_PRDOC_STAGE2A",
                "<P>Stage 2a (CnPrDoc) выполнен: cnpdTpOrdKey=" + resolutionResult.resolvedTpOrd()
                        + ", pdpCstAgPnKey=" + resolutionResult.resolvedCstAgPn() + "</P>",
                null
        ));

        reconcileCoordinator.run(context, file);
    }
}
