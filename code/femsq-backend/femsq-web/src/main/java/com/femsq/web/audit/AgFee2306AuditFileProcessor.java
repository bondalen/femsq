package com.femsq.web.audit;

import com.femsq.web.audit.reconcile.AuditReconcileCoordinator;
import com.femsq.web.audit.stage2.AgFeeAgentAnomaly;
import com.femsq.web.audit.stage2.AgFeeCstAnomaly;
import com.femsq.web.audit.stage2.AgFeeFkAnomalyFormatter;
import com.femsq.web.audit.stage2.AgFeeStage2Service;
import com.femsq.web.audit.staging.AuditStagingService;
import java.util.List;
import java.util.Objects;
import java.util.logging.Logger;
import org.springframework.stereotype.Service;

/**
 * Процессор файла типа 6: Stage 1 (Excel → {@code ags.ra_stg_agfee}) + Stage 2a (FK агент/стройка).
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
        context.append(
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "FILE_AGFEE_2306_STAGE1",
                "<P>Этап 1 (AgFee2306) завершён: " + file.getPath() + ", вставлено строк: " + inserted + "</P>",
                null
        );

        if (!Integer.valueOf(1).equals(context.getAuditType())) {
            context.append(
                    AuditLogLevel.INFO,
                    AuditLogScope.FILE,
                    "FILE_AGFEE_2306_STAGE2_SKIPPED_BY_AUDIT_TYPE",
                    "<P>Этап 2 (AgFee2306) пропущен: guard ctx.auditType == 1 не выполнен</P>",
                    null
            );
            return;
        }

        Long executionKey = context.getExecutionKey();
        if (executionKey == null) {
            context.append(
                    AuditLogLevel.WARNING,
                    AuditLogScope.FILE,
                    "FILE_AGFEE_2306_STAGE2_SKIPPED",
                    "<P>Этап 2 (AgFee2306) пропущен: executionKey отсутствует</P>",
                    null
            );
            return;
        }

        AgFeeStage2Service.ResolutionResult resolved = agFeeStage2Service.resolveForExecution(executionKey);
        context.append(
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "FILE_AGFEE_2306_STAGE2A",
                "<P>Этап 2a (AgFee2306): агент=" + resolved.resolvedAgents()
                        + ", стройка=" + resolved.resolvedCst()
                        + "; с ключом агента=" + resolved.rowsWithSenderKey()
                        + "/" + resolved.stagingRows()
                        + ", с ключом стройки=" + resolved.rowsWithCstKey()
                        + "/" + resolved.stagingRows()
                        + "</P>",
                null
        );

        appendAgentSpan(context, resolved.agentAnomalies());
        appendCstSpan(context, resolved.cstAnomalies());

        reconcileCoordinator.run(context, file);
    }

    /**
     * Свёртываемый блок Stage 2a: отправители (AgentNo / OK).
     */
    private static void appendAgentSpan(AuditExecutionContext context, List<AgFeeAgentAnomaly> anomalies) {
        List<AgFeeAgentAnomaly> list = anomalies == null ? List.of() : anomalies;
        boolean ok = list.isEmpty();
        AuditLogLevel level = ok ? AuditLogLevel.INFO : AuditLogLevel.WARNING;
        String spanId = context.beginSpan(
                level,
                AuditLogScope.SHEET,
                "FILE_AGFEE_2306_AGENT_START",
                AgFeeFkAnomalyFormatter.formatAgentTitleHtml(list),
                null
        );
        try {
            context.inSpan(spanId, () -> {
                String body = AgFeeFkAnomalyFormatter.formatAgentBodyHtml(list);
                if (body != null) {
                    context.append(level, AuditLogScope.SHEET, "FILE_AGFEE_2306_AGENT_NO", body, null);
                }
            });
        } finally {
            context.endSpan(
                    spanId,
                    AuditLogLevel.INFO,
                    AuditLogScope.SHEET,
                    "FILE_AGFEE_2306_AGENT_END",
                    "<P>Отправители — конец</P>",
                    null
            );
        }
    }

    /**
     * Свёртываемый блок Stage 2a: стройки (CstNo / OK).
     */
    private static void appendCstSpan(AuditExecutionContext context, List<AgFeeCstAnomaly> anomalies) {
        List<AgFeeCstAnomaly> list = anomalies == null ? List.of() : anomalies;
        boolean ok = list.isEmpty();
        AuditLogLevel level = ok ? AuditLogLevel.INFO : AuditLogLevel.WARNING;
        String spanId = context.beginSpan(
                level,
                AuditLogScope.SHEET,
                "FILE_AGFEE_2306_CST_START",
                AgFeeFkAnomalyFormatter.formatCstTitleHtml(list),
                null
        );
        try {
            context.inSpan(spanId, () -> {
                String body = AgFeeFkAnomalyFormatter.formatCstBodyHtml(list);
                if (body != null) {
                    context.append(level, AuditLogScope.SHEET, "FILE_AGFEE_2306_CST_NO", body, null);
                }
            });
        } finally {
            context.endSpan(
                    spanId,
                    AuditLogLevel.INFO,
                    AuditLogScope.SHEET,
                    "FILE_AGFEE_2306_CST_END",
                    "<P>Стройки — конец</P>",
                    null
            );
        }
    }
}
