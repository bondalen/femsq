package com.femsq.web.audit;

import com.femsq.database.model.RaA;
import com.femsq.database.model.RaF;
import com.femsq.database.service.RaAService;
import com.femsq.database.service.RaDirService;
import com.femsq.database.service.RaExecutionService;
import com.femsq.database.service.RaFService;
import com.femsq.web.audit.runtime.AuditExecutionRegistry;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Objects;
import java.util.logging.Logger;
import org.springframework.scheduling.annotation.Async;
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
    private final RaDirService raDirService;
    private final RaExecutionService raExecutionService;
    private final RaFService raFService;
    private final List<AuditFileProcessor> fileProcessors;
    private final AuditExecutionRegistry auditExecutionRegistry;

    public AuditExecutionServiceImpl(RaAService raAService,
                                     RaDirService raDirService,
                                     RaExecutionService raExecutionService,
                                     RaFService raFService,
                                     List<AuditFileProcessor> fileProcessors,
                                     AuditExecutionRegistry auditExecutionRegistry) {
        this.raAService = raAService;
        this.raDirService = raDirService;
        this.raExecutionService = raExecutionService;
        this.raFService = raFService;
        this.fileProcessors = fileProcessors;
        this.auditExecutionRegistry = auditExecutionRegistry;
    }

    @Async
    @Override
    public void executeAudit(long auditId) {
        // Шаг 1: загрузка ревизии или ошибка  (реакция на ошибку — в REST-контроллере)
        RaA audit = raAService.getById(auditId)
                .orElseThrow(() -> new IllegalArgumentException("Ревизия с id=" + auditId + " не найдена"));

        log.info(() -> "[AuditExecution] Starting audit execution for auditId=" + auditId);

        // Шаг 2: инициализация контекста и шапки лога
        AuditExecutionContext context = new AuditExecutionContext(auditId);
        raExecutionService.getLatestByAuditId((int) auditId)
                .ifPresent(exec -> context.setExecutionKey(exec.execKey() != null ? exec.execKey().longValue() : null));
        Integer dirId = audit.adtDir();
        context.setDirectoryId(dirId != null ? dirId.longValue() : null);
        if (dirId != null) {
            raDirService.getById(dirId).ifPresentOrElse(
                    dir -> context.setDirectoryPath(dir.dir()),
                    () -> log.warning("[AuditExecution] Directory not found for adtDir=" + audit.adtDir() + ", auditId=" + auditId)
            );
        }
        context.setStartedAt(Instant.now());
        context.setLastUpdatedAt(context.getStartedAt());
        context.setAuditType(audit.adtType());
        context.setAddRa(audit.adtAddRA());

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

        try {
            // Шаг 3: цикл по файлам ревизии и делегирование обработчикам (пока без Excel-логики)
            dirId = audit.adtDir();
            if (dirId == null) {
                log.warning("[AuditExecution] Audit has no directory, skipping file processing. auditId=" + auditId);
                saveProgress(audit, context);
                auditExecutionRegistry.markCompleted(auditId);
                return;
            }

            List<RaF> files = raFService.getByDirId(dirId);
            log.info("[AuditExecution] Files to process for auditId=" + auditId + " (dir=" + dirId + "): " + files.size());

            for (RaF raF : files) {
                // Учитываем только файлы, помеченные к выполнению
                if (!Boolean.TRUE.equals(raF.afExecute())) {
                    continue;
                }

                Integer fileType = raF.afType();
                if (Objects.equals(fileType, 1) || Objects.equals(fileType, 4)) {
                    String message = "<P>WARN: af_type=" + fileType
                            + " устарел — файл " + escape(raF.afName()) + " пропущен</P>";
                    log.warning("[AuditExecution] Skipped obsolete file type af_type=" + fileType + ", file=" + raF.afName());
                    context.appendEntry(new AuditLogEntry(
                            Instant.now(),
                            AuditLogLevel.WARNING,
                            AuditLogScope.FILE,
                            "FILE_TYPE_OBSOLETE_SKIPPED",
                            message,
                            null
                    ));
                    continue;
                }

                String resolvedPath = resolveFilePath(context, raF);
                if (resolvedPath == null || resolvedPath.isBlank()) {
                    String message = "<P>WARN: Путь к файлу не определён — файл пропущен: "
                            + escape(raF.afName()) + "</P>";
                    log.warning("[AuditExecution] File path is empty, skipping file=" + raF.afName());
                    context.appendEntry(new AuditLogEntry(
                            Instant.now(),
                            AuditLogLevel.WARNING,
                            AuditLogScope.FILE,
                            "FILE_PATH_EMPTY",
                            message,
                            null
                    ));
                    continue;
                }

                AuditFile auditFile = new AuditFile(
                        raF.afKey() != null ? raF.afKey() : -1L,
                        resolvedPath,
                        fileType,
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

            auditExecutionRegistry.markCompleted(auditId);
            log.info(() -> "[AuditExecution] Audit execution log saved for auditId=" + auditId);
        } catch (Exception ex) {
            auditExecutionRegistry.markFailed(auditId, ex.getMessage());
            log.severe("[AuditExecution] Error during audit execution for auditId=" + auditId + ": " + ex.getMessage());
            AuditLogEntry errorEntry = new AuditLogEntry(
                    Instant.now(),
                    AuditLogLevel.ERROR,
                    AuditLogScope.AUDIT,
                    "AUDIT_ERROR",
                    "<P><b>Ошибка выполнения ревизии.</b> Подробности см. в журнале сервера.</P>",
                    null
            );
            context.appendEntry(errorEntry);
            saveProgress(audit, context);
        }
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

    private String resolveFilePath(AuditExecutionContext context, RaF file) {
        String fileName = file.afName();
        if (fileName == null || fileName.isBlank()) {
            return fileName;
        }

        String normalized = fileName.trim();
        if (isAbsoluteOrUncPath(normalized)) {
            return normalized;
        }

        String directoryPath = context.getDirectoryPath();
        if (directoryPath == null || directoryPath.isBlank()) {
            return normalized;
        }

        String dir = directoryPath.trim();
        String separator = dir.contains("\\") ? "\\" : "/";
        String cleanedDir = dir.endsWith("\\") || dir.endsWith("/") ? dir.substring(0, dir.length() - 1) : dir;
        String cleanedFile = normalized.startsWith("\\") || normalized.startsWith("/") ? normalized.substring(1) : normalized;
        return cleanedDir + separator + cleanedFile;
    }

    private boolean isAbsoluteOrUncPath(String path) {
        return path.startsWith("\\\\")
                || path.startsWith("/")
                || (path.length() >= 3
                && Character.isLetter(path.charAt(0))
                && path.charAt(1) == ':'
                && (path.charAt(2) == '\\' || path.charAt(2) == '/'));
    }

    private static LocalDateTime toLocalDateTime(Instant instant) {
        if (instant == null) {
            return null;
        }
        return LocalDateTime.ofInstant(instant, ZoneId.systemDefault());
    }
}
