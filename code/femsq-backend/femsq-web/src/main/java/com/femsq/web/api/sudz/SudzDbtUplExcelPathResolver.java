package com.femsq.web.api.sudz;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Путь Excel из {@code cidufPath}: в БД хранится как в Проводнике пользователя;
 * JVM (WSL) может видеть другой путь. Резолвер не меняет значение в БД.
 */
public final class SudzDbtUplExcelPathResolver {

    /** {@code D:\foo} или {@code D:/foo}. */
    private static final Pattern WINDOWS_DRIVE = Pattern.compile("^([A-Za-z]):[/\\\\](.*)$");

    /**
     * Шар nb-win из {@code project-docs.json} {@code excel_share}:
     * Windows {@code D:\wire-guard-share-nb-win} ↔ bind {@code /mnt/nb-win-share}.
     */
    private static final String WSL_DRIVE_SHARE = "/mnt/d/wire-guard-share-nb-win";
    private static final String WSL_SHARE_BIND = "/mnt/nb-win-share";

    private SudzDbtUplExcelPathResolver() {
    }

    /**
     * Снимает кавычки «Копировать как путь» и пробелы.
     *
     * @param raw значение из UI / БД
     * @return очищенная строка; пустая, если {@code raw} null/blank
     */
    public static String normalizeStored(String raw) {
        if (raw == null) {
            return "";
        }
        String trimmed = raw.trim();
        if (trimmed.length() >= 2) {
            char first = trimmed.charAt(0);
            char last = trimmed.charAt(trimmed.length() - 1);
            if ((first == '"' && last == '"') || (first == '\'' && last == '\'')) {
                trimmed = trimmed.substring(1, trimmed.length() - 1).trim();
            }
        }
        return trimmed;
    }

    /**
     * Кандидаты для открытия файла: как в БД, затем перевод Windows-диска в {@code /mnt/{буква}/},
     * затем bind-шара nb-win.
     *
     * @param cidufPath путь из БД
     * @return уникальные пути в порядке проверки
     */
    public static List<Path> candidates(String cidufPath) {
        String stored = normalizeStored(cidufPath);
        Set<String> keys = new LinkedHashSet<>();
        List<Path> out = new ArrayList<>();
        if (stored.isEmpty()) {
            return List.of();
        }
        addCandidate(out, keys, stored);
        String wsl = toWslMount(stored);
        if (wsl != null) {
            addCandidate(out, keys, wsl);
            String bind = toNbWinShareBind(wsl);
            if (bind != null) {
                addCandidate(out, keys, bind);
            }
        }
        return List.copyOf(out);
    }

    /**
     * Первый существующий обычный файл среди кандидатов.
     *
     * @param cidufPath путь из БД
     * @return readable path или empty
     */
    public static Optional<Path> resolveExisting(String cidufPath) {
        for (Path candidate : candidates(cidufPath)) {
            if (Files.isRegularFile(candidate)) {
                return Optional.of(candidate.toAbsolutePath().normalize());
            }
        }
        return Optional.empty();
    }

    /**
     * Перевод {@code D:\a\b.xlsx} → {@code /mnt/d/a/b.xlsx}.
     *
     * @param stored нормализованный путь из БД
     * @return POSIX или {@code null}, если не диск Windows
     */
    static String toWslMount(String stored) {
        String unified = stored.replace('\\', '/');
        Matcher matcher = WINDOWS_DRIVE.matcher(unified);
        if (!matcher.matches()) {
            return null;
        }
        String letter = matcher.group(1).toLowerCase(Locale.ROOT);
        String rest = matcher.group(2);
        if (rest.isEmpty()) {
            return "/mnt/" + letter;
        }
        return "/mnt/" + letter + "/" + rest;
    }

    private static String toNbWinShareBind(String wslMount) {
        String lower = wslMount.toLowerCase(Locale.ROOT);
        String prefix = WSL_DRIVE_SHARE;
        if (!lower.startsWith(prefix)) {
            return null;
        }
        String suffix = wslMount.substring(prefix.length());
        return WSL_SHARE_BIND + suffix;
    }

    private static void addCandidate(List<Path> out, Set<String> keys, String raw) {
        Path path = Path.of(raw);
        String key = path.toString();
        if (keys.add(key)) {
            out.add(path);
        }
    }
}
