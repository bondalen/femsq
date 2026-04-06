package com.femsq.web.audit;

import com.femsq.database.model.RaA;
import com.femsq.database.model.RaF;
import com.femsq.database.service.RaAService;
import com.femsq.database.service.RaDirService;
import com.femsq.database.service.RaExecutionService;
import com.femsq.database.service.RaFService;
import com.femsq.web.audit.runtime.AuditExecutionRegistry;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.logging.Level;
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
    private static final long LOG_FLUSH_INTERVAL_MS = 1000L;
    private static final DateTimeFormatter HUMAN_TS_FORMAT = DateTimeFormatter.ofPattern("dd.MM.yyyy HH:mm:ss z");

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
        // Шаг 1: загрузка ревизии (вне основного try — при сбое ревизия уже RUNNING в реестре)
        final RaA audit;
        try {
            audit = raAService.getById(auditId)
                    .orElseThrow(() -> new IllegalArgumentException("Ревизия с id=" + auditId + " не найдена"));
        } catch (Throwable ex) {
            auditExecutionRegistry.markFailed(auditId, throwableMessage(ex));
            log.log(Level.SEVERE, "[AuditExecution] Failed to load audit auditId=" + auditId, ex);
            return;
        }

        log.info(() -> "[AuditExecution] Starting audit execution for auditId=" + auditId);

        // Шаг 2–4: контекст, файлы, финал (все ошибки и Error → markFailed, иначе RUNNING «зависает»)
        AuditExecutionContext errContext = null;
        String auditSpanId = null;
        try {
            final AuditExecutionContext context = new AuditExecutionContext(auditId);
            errContext = context;
            raExecutionService.getLatestByAuditId((int) auditId)
                    .ifPresent(exec -> context.setExecutionKey(exec.execKey() != null ? exec.execKey().longValue() : null));
            Integer dirId = audit.adtDir();
            context.setDirectoryId(dirId != null ? dirId.longValue() : null);
            final boolean[] dirLookupFound = {false};
            final boolean[] dirLookupMissing = {false};
            if (dirId != null) {
                raDirService.getById(dirId).ifPresentOrElse(
                        dir -> {
                            context.setDirectoryPath(dir.dir());
                            dirLookupFound[0] = true;
                        },
                        () -> {
                            dirLookupMissing[0] = true;
                            log.warning("[AuditExecution] Directory not found for adtDir=" + audit.adtDir() + ", auditId=" + auditId);
                        }
                );
            }
            context.setStartedAt(Instant.now());
            context.setLastUpdatedAt(context.getStartedAt());
            context.setAuditType(audit.adtType());
            context.setAddRa(audit.adtAddRA());
            ThrottledProgressFlusher progressFlusher = new ThrottledProgressFlusher(
                    LOG_FLUSH_INTERVAL_MS,
                    () -> saveProgress(audit, context)
            );
            context.setOnEntryAppended(ctx -> progressFlusher.tryFlush());

            String resolvedDir = context.getDirectoryPath() == null || context.getDirectoryPath().isBlank()
                    ? "(не задана)"
                    : normalizeCrossPlatformPath(context.getDirectoryPath().trim());
            auditSpanId = context.beginSpan(
                    AuditLogLevel.INFO,
                    AuditLogScope.AUDIT,
                    "AUDIT_START",
                    "<P>Начало ревизии <b>" + escape(audit.adtName()) + "</b> (ID=" + auditId + ")</P>"
                            + "<P>Проводим по директории - " + escape(resolvedDir) + "</P>"
                            + "<P><b>" + formatInstantHuman(context.getStartedAt()) + "</b> - Время начала проведения ревизии.</P>",
                    withPresentationMeta(Map.of(
                            "auditId", String.valueOf(auditId),
                            "auditName", audit.adtName() == null ? "" : audit.adtName(),
                            "auditDir", resolvedDir,
                            "startedAt", String.valueOf(context.getStartedAt())
                    ), "START", "RED", "BOLD")
            );
            if (dirLookupMissing[0]) {
                context.append(
                        AuditLogLevel.WARNING,
                        AuditLogScope.AUDIT,
                        "DIR_LOOKUP_NOT_FOUND",
                        "<P>Не обнаружена <font color=\"red\">директория</font> для ревизии (dirId=" + dirId + ")</P>",
                        withPresentationMeta(Map.of("auditId", String.valueOf(auditId), "dirId", String.valueOf(dirId)),
                                "ERROR", "RED", "BOLD")
                );
            } else if (dirLookupFound[0]) {
                context.append(
                        AuditLogLevel.INFO,
                        AuditLogScope.AUDIT,
                        "DIR_LOOKUP_FOUND",
                        "<P>Имя директории <b><font color=\"green\">" + escape(resolvedDir)
                                + "</font></b> для ревизии обнаружено</P>",
                        withPresentationMeta(Map.of("auditId", String.valueOf(auditId), "dirName", resolvedDir),
                                "INFO", "GREEN", "BOLD")
                );
            }

            // Шаг 3: цикл по файлам ревизии и делегирование обработчикам (пока без Excel-логики)
            dirId = audit.adtDir();
            if (dirId == null) {
                log.warning("[AuditExecution] Audit has no directory, skipping file processing. auditId=" + auditId);
                context.append(AuditLogLevel.WARNING, AuditLogScope.AUDIT, "DIR_ID_EMPTY",
                        "<P>Директория ревизии не задана — обработка файлов пропущена</P>",
                        withPresentationMeta(Map.of("auditId", String.valueOf(auditId)), "WARNING", "RED", "NORMAL"));
                appendAuditEnd(context, auditSpanId, "COMPLETED");
                saveProgress(audit, context);
                auditExecutionRegistry.markCompleted(auditId);
                return;
            }

            List<RaF> files = raFService.getByDirId(dirId);
            log.info("[AuditExecution] Files to process for auditId=" + auditId + " (dir=" + dirId + "): " + files.size());
            if (files.isEmpty()) {
                context.append(
                        AuditLogLevel.WARNING,
                        AuditLogScope.AUDIT,
                        "FILES_EMPTY",
                        "<P>Не обнаружены файлы для рассмотрения</P>",
                        withPresentationMeta(Map.of("auditId", String.valueOf(auditId)), "WARNING", "RED", "NORMAL")
                );
            }

            boolean dirMissing = verifyDirectoryExistsInFileSystem(context);
            if (dirMissing) {
                appendAuditEnd(context, auditSpanId, "COMPLETED");
                saveProgress(audit, context);
                auditExecutionRegistry.markCompleted(auditId);
                return;
            }

            for (RaF raF : files) {
                // Учитываем только файлы, помеченные к выполнению
                if (!Boolean.TRUE.equals(raF.afExecute())) {
                    Instant skippedStartedAt = Instant.now();
                    String skippedFileSpan = context.beginSpan(
                            AuditLogLevel.INFO,
                            AuditLogScope.FILE,
                            "FILE_START",
                            "<P>Файл: " + escape(raF.afName()) + " — начало обработки</P>",
                            withPresentationMeta(Map.of(
                                    "auditId", String.valueOf(auditId),
                                    "filePath", String.valueOf(raF.afName()),
                                    "fileType", String.valueOf(raF.afType())
                            ), "START", "GREEN", "BOLD")
                    );
                    context.append(AuditLogLevel.INFO, AuditLogScope.FILE, "FILE_SKIPPED_BY_USER",
                            "<P>Файл пропущен (по настройке): " + escape(raF.afName()) + "</P>",
                            withPresentationMeta(Map.of(
                                    "auditId", String.valueOf(auditId),
                                    "filePath", String.valueOf(raF.afName())
                            ), "INFO", "GREEN", "NORMAL"));
                    context.endSpan(
                            skippedFileSpan,
                            AuditLogLevel.INFO,
                            AuditLogScope.FILE,
                            "FILE_END",
                            "<P>Файл: " + escape(raF.afName()) + " — завершено (пропущен), duration="
                                    + formatDuration(skippedStartedAt, Instant.now()) + "</P>",
                            withPresentationMeta(Map.of(
                                    "auditId", String.valueOf(auditId),
                                    "filePath", String.valueOf(raF.afName()),
                                    "durationHuman", formatDuration(skippedStartedAt, Instant.now())
                            ), "END", "GREEN", "NORMAL")
                    );
                    continue;
                }

                Integer fileType = raF.afType();
                if (Objects.equals(fileType, 1) || Objects.equals(fileType, 4)) {
                    String message = "<P>af_type=" + fileType
                            + " устарел — файл " + escape(raF.afName()) + " пропущен</P>";
                    log.warning("[AuditExecution] Skipped obsolete file type af_type=" + fileType + ", file=" + raF.afName());
                    context.append(AuditLogLevel.WARNING, AuditLogScope.FILE, "FILE_TYPE_OBSOLETE_SKIPPED", message, null);
                    continue;
                }

                String resolvedPath = resolveFilePath(context, raF);
                if (resolvedPath == null || resolvedPath.isBlank()) {
                    String message = "<P>Путь к файлу не определён — файл пропущен: "
                            + escape(raF.afName()) + "</P>";
                    log.warning("[AuditExecution] File path is empty, skipping file=" + raF.afName());
                    context.append(AuditLogLevel.WARNING, AuditLogScope.FILE, "FILE_PATH_EMPTY", message, null);
                    continue;
                }

                Instant fileStartedAt = Instant.now();
                String fileSpanId = context.beginSpan(
                        AuditLogLevel.INFO,
                        AuditLogScope.FILE,
                        "FILE_START",
                        "<P>Файл: " + escape(raF.afName()) + " (type=" + fileType + ") — начало обработки</P>",
                        withPresentationMeta(Map.of(
                                "auditId", String.valueOf(auditId),
                                "filePath", resolvedPath,
                                "fileType", String.valueOf(fileType)
                        ), "START", "GREEN", "BOLD")
                );

                Path filePath = Path.of(resolvedPath);
                if (!Files.exists(filePath)) {
                    context.append(AuditLogLevel.WARNING, AuditLogScope.FILE, "FILE_FS_MISSING",
                            "<P>" + formatInstantHuman(Instant.now()) + " - Файл с именем <b><font color=\"red\">"
                                    + escape(resolvedPath) + "</font></b> в файловой системе не обнаружен</P>",
                            withPresentationMeta(Map.of("auditId", String.valueOf(auditId), "filePath", resolvedPath),
                                    "ERROR", "RED", "BOLD"));
                    context.endSpan(fileSpanId, AuditLogLevel.INFO, AuditLogScope.FILE, "FILE_END",
                            "<P>Файл: " + escape(raF.afName()) + " — завершено (не найден), duration="
                                    + formatDuration(fileStartedAt, Instant.now()) + "</P>",
                            withPresentationMeta(Map.of(
                                    "auditId", String.valueOf(auditId),
                                    "filePath", resolvedPath,
                                    "durationHuman", formatDuration(fileStartedAt, Instant.now())
                            ), "END", "GREEN", "NORMAL"));
                    saveProgress(audit, context);
                    continue;
                } else {
                    context.append(AuditLogLevel.INFO, AuditLogScope.FILE, "FILE_FS_FOUND",
                            "<P>" + formatInstantHuman(Instant.now()) + " - Файл с именем <b>"
                                    + escape(resolvedPath) + "</b> в файловой системе обнаружен</P>",
                            withPresentationMeta(Map.of("auditId", String.valueOf(auditId), "filePath", resolvedPath),
                                    "INFO", "GREEN", "NORMAL"));
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
                    context.append(
                            AuditLogLevel.WARNING,
                            AuditLogScope.FILE,
                            "FILE_PROCESSOR_NOT_FOUND",
                            "<P>Нет обработчика для файла типа " + raF.afType() + ": " + raF.afName() + "</P>",
                            withPresentationMeta(Map.of(
                                    "auditId", String.valueOf(auditId),
                                    "filePath", resolvedPath,
                                    "fileType", String.valueOf(raF.afType())
                            ), "WARNING", "RED", "NORMAL")
                    );
                    context.endSpan(fileSpanId, AuditLogLevel.INFO, AuditLogScope.FILE, "FILE_END",
                            "<P>Файл: " + escape(raF.afName()) + " — завершено (нет обработчика), duration="
                                    + formatDuration(fileStartedAt, Instant.now()) + "</P>",
                            withPresentationMeta(Map.of(
                                    "auditId", String.valueOf(auditId),
                                    "filePath", resolvedPath,
                                    "durationHuman", formatDuration(fileStartedAt, Instant.now())
                            ), "END", "GREEN", "NORMAL"));
                    continue;
                }

                context.inSpan(fileSpanId, () -> processor.process(context, auditFile));

                // Завершение обработки файла
                context.endSpan(fileSpanId, AuditLogLevel.INFO, AuditLogScope.FILE, "FILE_END",
                        "<P>Файл: " + escape(raF.afName()) + " — завершено за " + formatDuration(fileStartedAt, Instant.now()) + "</P>",
                        withPresentationMeta(Map.of(
                                "auditId", String.valueOf(auditId),
                                "filePath", resolvedPath,
                                "durationHuman", formatDuration(fileStartedAt, Instant.now())
                        ), "END", "GREEN", "NORMAL"));

                // Инкрементальное обновление лога и временной метки после каждого файла
                saveProgress(audit, context);
            }

            // Шаг 4: финальное сохранение обновлённого adt_results (контрольная фиксация)
            appendAuditEnd(context, auditSpanId, "COMPLETED");
            saveProgress(audit, context);

            auditExecutionRegistry.markCompleted(auditId);
            log.info(() -> "[AuditExecution] Audit execution log saved for auditId=" + auditId);
        } catch (Throwable ex) {
            auditExecutionRegistry.markFailed(auditId, throwableMessage(ex));
            log.log(Level.SEVERE, "[AuditExecution] Error during audit execution for auditId=" + auditId, ex);
            if (errContext != null) {
                try {
                    errContext.append(
                            AuditLogLevel.ERROR,
                            AuditLogScope.AUDIT,
                            "AUDIT_ERROR",
                            "<P><b>Ошибка выполнения ревизии.</b> Подробности см. в журнале сервера.</P>",
                            withPresentationMeta(Map.of("auditId", String.valueOf(auditId)), "ERROR", "RED", "BOLD")
                    );
                    if (auditSpanId != null) {
                        appendAuditEnd(errContext, auditSpanId, "FAILED");
                    }
                    saveProgress(audit, errContext);
                } catch (Exception persistEx) {
                    log.log(Level.WARNING,
                            "[AuditExecution] Failed to persist audit error log for auditId=" + auditId,
                            persistEx);
                }
            }
        }
    }

    /**
     * Краткое сообщение для {@link AuditExecutionRegistry#markFailed(long, String)} (БД / UI).
     */
    private static String throwableMessage(Throwable ex) {
        String m = ex.getMessage();
        return (m != null && !m.isBlank()) ? m : ex.getClass().getName();
    }

    private static final class ThrottledProgressFlusher {
        private final long intervalMs;
        private final Runnable flushAction;
        private long lastFlushAtMs;

        private ThrottledProgressFlusher(long intervalMs, Runnable flushAction) {
            this.intervalMs = intervalMs;
            this.flushAction = flushAction;
            this.lastFlushAtMs = 0L;
        }

        private synchronized void tryFlush() {
            long now = System.currentTimeMillis();
            if (now - lastFlushAtMs < intervalMs) {
                return;
            }
            flushAction.run();
            lastFlushAtMs = now;
        }
    }

    private boolean verifyDirectoryExistsInFileSystem(AuditExecutionContext context) {
        String dir = context.getDirectoryPath();
        if (dir == null || dir.isBlank()) {
            return false;
        }
        String normalizedDir = normalizeCrossPlatformPath(dir.trim());
        Path path = Path.of(normalizedDir);
        if (Files.isDirectory(path)) {
            context.append(
                    AuditLogLevel.INFO,
                    AuditLogScope.AUDIT,
                    "DIR_FS_EXISTS",
                    "<P>Директория с именем <b><font color=\"green\">" + escape(normalizedDir)
                            + "</font></b> в файловой системе обнаружена</P>",
                    withPresentationMeta(Map.of("dirPath", normalizedDir), "SUCCESS", "GREEN", "BOLD")
            );
            return false;
        }
        context.append(
                AuditLogLevel.WARNING,
                AuditLogScope.AUDIT,
                "DIR_FS_MISSING",
                "<P>Директория с именем <b><font color=\"red\">" + escape(normalizedDir)
                        + "</font></b> в файловой системе не обнаружена</P>",
                withPresentationMeta(Map.of("dirPath", normalizedDir), "ERROR", "RED", "BOLD")
        );
        return true;
    }

    private void appendAuditEnd(AuditExecutionContext context, String auditSpanId, String status) {
        Instant start = context.getStartedAt();
        Instant end = Instant.now();
        boolean failed = "FAILED".equalsIgnoreCase(status);
        String endColor = failed ? "#f85149" : "#0055AA";
        long totalSeconds = start != null && end != null
                ? Math.max(0L, Duration.between(start, end).getSeconds())
                : 0L;
        String durationRu = formatAuditDurationRussian(start, end);
        context.endSpan(auditSpanId, AuditLogLevel.INFO, AuditLogScope.AUDIT, "AUDIT_END",
                "<P>В " + formatInstantHuman(end) + " - <b><font color=\"" + endColor + "\">ревизия завершена</font></b>. С "
                        + formatInstantHuman(start)
                        + " в течении " + durationRu + ", (всего " + totalSeconds + " сек.).</P>",
                withPresentationMeta(Map.of(
                        "finishedAt", formatInstantHuman(end),
                        "startedAt", formatInstantHuman(start),
                        "durationHuman", durationRu,
                        "durationTotalSec", String.valueOf(totalSeconds),
                        "status", status
                ), "END", failed ? "RED" : "BLUE", "BOLD"));
    }

    /**
     * Длительность ревизии для текста {@code AUDIT_END} в стиле VBA (SCR-002-D): «N мин. M сек.».
     */
    private static String formatAuditDurationRussian(Instant start, Instant end) {
        if (start == null || end == null) {
            return "-";
        }
        long seconds = Duration.between(start, end).getSeconds();
        if (seconds < 0) {
            seconds = 0;
        }
        long minutes = seconds / 60;
        long remSeconds = seconds % 60;
        return minutes + " мин. " + remSeconds + " сек.";
    }

    private String formatDuration(Instant start, Instant end) {
        if (start == null || end == null) {
            return "-";
        }
        long seconds = Duration.between(start, end).toSeconds();
        if (seconds < 0) {
            seconds = 0;
        }
        long minutes = seconds / 60;
        long remSeconds = seconds % 60;
        return minutes + "m " + remSeconds + "s";
    }

    private String formatInstantHuman(Instant instant) {
        if (instant == null) {
            return "-";
        }
        ZonedDateTime zonedDateTime = instant.atZone(ZoneId.systemDefault());
        return HUMAN_TS_FORMAT.format(zonedDateTime);
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

        String dir = normalizeCrossPlatformPath(directoryPath.trim());
        String separator = dir.contains("\\") ? "\\" : "/";
        String cleanedDir = dir.endsWith("\\") || dir.endsWith("/") ? dir.substring(0, dir.length() - 1) : dir;
        String cleanedFile = normalized.startsWith("\\") || normalized.startsWith("/") ? normalized.substring(1) : normalized;
        return cleanedDir + separator + cleanedFile;
    }

    private String normalizeCrossPlatformPath(String path) {
        if (path == null || path.isBlank()) {
            return path;
        }
        String trimmed = path.trim();
        // Some directory values may come in escaped UNC-like format with doubled backslashes.
        String canonical = trimmed.replace("\\\\", "\\");
        String lowerCanonical = canonical.toLowerCase();
        String wslPrefix = "\\wsl.localhost\\ubuntu\\";
        if (lowerCanonical.startsWith(wslPrefix)) {
            String suffix = canonical.substring(wslPrefix.length()).replace("\\", "/");
            return "/" + suffix;
        }
        return trimmed;
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
