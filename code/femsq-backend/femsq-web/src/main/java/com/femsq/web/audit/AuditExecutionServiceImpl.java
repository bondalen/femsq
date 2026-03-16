package com.femsq.web.audit;

import com.femsq.database.model.RaA;
import com.femsq.database.model.RaF;
import com.femsq.database.service.RaAService;
import com.femsq.database.service.RaFService;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.logging.Logger;
import org.springframework.stereotype.Service;

/**
 * Базовая (пока минимальная) реализация сервиса-оркестратора выполнения ревизий.
 *
 * На данном этапе метод {@link #executeAudit(long)} только:
 * - проверяет существование ревизии;
 * - инициализирует контекст и шапку лога;
 * - сохраняет обновлённое поле adt_results и временную метку в базе.
 * Детальная логика по обработке файлов и Excel будет добавляться поэтапно.
 */
@Service
public class AuditExecutionServiceImpl implements AuditExecutionService {

    private static final Logger log = Logger.getLogger(AuditExecutionServiceImpl.class.getName());

    private final RaAService raAService;
    private final RaFService raFService;
    private final List<AuditFileProcessor> fileProcessors;

    public AuditExecutionServiceImpl(RaAService raAService,
                                     RaFService raFService,
                                     List<AuditFileProcessor> fileProcessors) {
        this.raAService = raAService;
        this.raFService = raFService;
        this.fileProcessors = fileProcessors;
    }

    @Override
    public void executeAudit(long auditId) {
        // Шаг 1: загрузка ревизии или ошибка  (реакция на ошибку — в REST-контроллере)
        RaA audit = raAService.getById(auditId)
                .orElseThrow(() -> new IllegalArgumentException("Ревизия с id=" + auditId + " не найдена"));

        log.info(() -> "[AuditExecution] Starting audit execution for auditId=" + auditId);

        // Шаг 2: инициализация контекста и шапки лога
        AuditExecutionContext context = new AuditExecutionContext(auditId);
        context.setDirectoryId(audit.adtDir() != null ? audit.adtDir().longValue() : null);
        context.setStartedAt(Instant.now());
        context.setLastUpdatedAt(context.getStartedAt());

        String headerHtml = "<P>Запуск ревизии <b>" + escape(audit.adtName()) + "</b> (ID=" + auditId + ")</P>";
        AuditLogEntry headerEntry = new AuditLogEntry(
                context.getStartedAt(),
                AuditLogLevel.INFO,
                AuditLogScope.AUDIT,
                "AUDIT_START",
                headerHtml,
                null
        );
        context.appendEntry(headerEntry);

        // Шаг 3: цикл по файлам ревизии и делегирование обработчикам (пока без Excel-логики)
        Integer dirId = audit.adtDir();
        if (dirId == null) {
            log.warning("[AuditExecution] Audit has no directory, skipping file processing. auditId=" + auditId);
            saveProgress(audit, context);
            return;
        }

        List<RaF> files = raFService.getByDirId(dirId);
        log.info(() -> "[AuditExecution] Files to process for auditId=" + auditId + " (dir=" + dirId + "): " + files.size());

        for (RaF raF : files) {
            // Учитываем только файлы, помеченные к выполнению
            if (!Boolean.TRUE.equals(raF.afExecute())) {
                continue;
            }

            AuditFile auditFile = new AuditFile(
                    raF.afKey() != null ? raF.afKey() : -1L,
                    raF.afName(), // пока используем только имя файла; путь будет уточнён позже
                    raF.afType(),
                    raF.afSource() != null && raF.afSource() ? 1 : 0
            );

            AuditFileProcessor processor = fileProcessors.stream()
                    .filter(p -> p.supports(raF.afType()))
                    .findFirst()
                    .orElse(null);

            if (processor == null) {
                AuditLogEntry entry = new AuditLogEntry(
                        Instant.now(),
                        AuditLogLevel.WARNING,
                        AuditLogScope.FILE,
                        "FILE_PROCESSOR_NOT_FOUND",
                        "<P>Нет обработчика для файла типа " + raF.afType() + ": " + raF.afName() + "</P>",
                        null
                );
                context.appendEntry(entry);
                continue;
            }

            processor.process(context, auditFile);

            // Завершение обработки файла
            AuditLogEntry fileEnd = new AuditLogEntry(
                    Instant.now(),
                    AuditLogLevel.INFO,
                    AuditLogScope.FILE,
                    "FILE_PROCESS_FINISH",
                    "<P>Обработка файла завершена: " + raF.afName() + "</P>",
                    null
            );
            context.appendEntry(fileEnd);

            // Инкрементальное обновление лога и временной метки после каждого файла
            saveProgress(audit, context);
        }

        // Шаг 4: финальное сохранение обновлённого adt_results (контрольная фиксация)
        saveProgress(audit, context);

        log.info(() -> "[AuditExecution] Audit execution log saved for auditId=" + auditId);
    }

    /**
     * Сохраняет текущее состояние лога и временные метки в записи ревизии.
     * Используется как для инкрементальных обновлений, так и для финального сохранения.
     */
    private void saveProgress(RaA audit, AuditExecutionContext context) {
        String newResults = context.buildHtmlLog();
        RaA updated = new RaA(
                audit.adtKey(),
                audit.adtName(),
                toLocalDateTime(context.getStartedAt()),
                newResults,
                audit.adtDir(),
                audit.adtType(),
                audit.adtAddRA(),
                audit.adtCreated(),
                LocalDateTime.now()
        );
        raAService.update(updated);
    }

    private static String escape(String value) {
        return value == null ? "" : value.replace("<", "&lt;").replace(">", "&gt;");
    }

    private static LocalDateTime toLocalDateTime(Instant instant) {
        if (instant == null) {
            return null;
        }
        return LocalDateTime.ofInstant(instant, ZoneId.systemDefault());
    }
}
