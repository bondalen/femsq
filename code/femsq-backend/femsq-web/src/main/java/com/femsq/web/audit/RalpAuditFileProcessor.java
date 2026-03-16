package com.femsq.web.audit;

import java.time.Instant;
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

    @Override
    public boolean supports(Integer type) {
        return Objects.equals(type, TYPE_RALP);
    }

    @Override
    public void process(AuditExecutionContext context, AuditFile file) {
        log.info(() -> "[AuditExecution] Ralp processor stub for file " + file.getPath()
                + ", type=" + file.getType());
        AuditLogEntry entry = new AuditLogEntry(
                Instant.now(),
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "FILE_RALP_STUB",
                "<P>Обработан файл (заглушка RALP): " + file.getPath() + "</P>",
                null
        );
        context.appendEntry(entry);
    }
}
