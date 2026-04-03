package com.femsq.web.audit;

import com.femsq.web.audit.staging.AuditStagingService;
import com.femsq.web.audit.reconcile.AuditReconcileCoordinator;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;
import java.util.logging.Logger;
import org.springframework.stereotype.Service;

/**
 * Заглушка обработчика файлов сценария "все агенты" (аналог ra_aAllAgents).
 */
@Service
public class AllAgentsAuditFileProcessor implements AuditFileProcessor {

    private static final Logger log = Logger.getLogger(AllAgentsAuditFileProcessor.class.getName());

    // TODO: согласовать реальные значения af_type для сценария AllAgents.
    private static final int TYPE_ALL_AGENTS = 5;
    private final AuditStagingService auditStagingService;
    private final AuditReconcileCoordinator reconcileCoordinator;

    public AllAgentsAuditFileProcessor(AuditStagingService auditStagingService,
                                       AuditReconcileCoordinator reconcileCoordinator) {
        this.auditStagingService = Objects.requireNonNull(auditStagingService, "auditStagingService");
        this.reconcileCoordinator = Objects.requireNonNull(reconcileCoordinator, "reconcileCoordinator");
    }

    @Override
    public boolean supports(Integer type) {
        return Objects.equals(type, TYPE_ALL_AGENTS);
    }

    @Override
    public void process(AuditExecutionContext context, AuditFile file) {
        int inserted = 0;
        if (Integer.valueOf(1).equals(file.getSource())) {
            inserted = auditStagingService.loadToStaging(context, file);
        }
        int insertedFinal = inserted;
        log.info(() -> "[AuditExecution] AllAgents processor Stage1, file=" + file.getPath()
                + ", type=" + file.getType() + ", inserted=" + insertedFinal);
        context.append(
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "FILE_ALL_AGENTS_STAGE1",
                "<P>Stage 1 (AllAgents) завершён: " + file.getPath() + ", вставлено строк: " + inserted + "</P>",
                withPresentationMeta(
                        Map.of(
                                "auditId", String.valueOf(context.getAuditId()),
                                "filePath", String.valueOf(file.getPath()),
                                "fileType", String.valueOf(file.getType()),
                                "insertedRows", String.valueOf(inserted)
                        ),
                        "INFO",
                        "BLUE",
                        "NORMAL"
                )
        );

        // Stage 2 для type=5 по архитектуре: no-op, данные уже готовы к reconcile.
        context.append(
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "FILE_ALL_AGENTS_STAGE2_NOOP",
                "<P>Stage 2 (AllAgents): no-op, дополнительные FK/derived вычисления не требуются</P>",
                withPresentationMeta(
                        Map.of(
                                "auditId", String.valueOf(context.getAuditId()),
                                "filePath", String.valueOf(file.getPath()),
                                "fileType", String.valueOf(file.getType()),
                                "reason", "NO_OP"
                        ),
                        "INFO",
                        "SILVER",
                        "NORMAL"
                )
        );

        reconcileCoordinator.run(context, file);
    }

    private Map<String, String> withPresentationMeta(Map<String, String> meta,
                                                      String messageType,
                                                      String colorHint,
                                                      String emphasis) {
        Map<String, String> enriched = new HashMap<>();
        if (meta != null) {
            enriched.putAll(meta);
        }
        enriched.put("messageType", messageType);
        enriched.put("colorHint", colorHint);
        enriched.put("emphasis", emphasis);
        return enriched;
    }
}
