package com.femsq.web.audit;

import java.time.Instant;
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

    @Override
    public boolean supports(Integer type) {
        return Objects.equals(type, TYPE_ALL_AGENTS);
    }

    @Override
    public void process(AuditExecutionContext context, AuditFile file) {
        log.info(() -> "[AuditExecution] AllAgents processor stub for file " + file.getPath()
                + ", type=" + file.getType());
        AuditLogEntry entry = new AuditLogEntry(
                Instant.now(),
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "FILE_ALL_AGENTS_STUB",
                "<P>Обработан файл (заглушка AllAgents): " + file.getPath() + "</P>",
                null
        );
        context.appendEntry(entry);
    }
}
