package com.femsq.database.util;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Утилита для определения пути к JAR-файлу, из которого запущено приложение.
 * <p>
 * Поддерживает различные форматы URL, включая:
 * <ul>
 *   <li>Обычный JAR: {@code file:/path/to/jar}</li>
 *   <li>JAR внутри JAR (Spring Boot): {@code jar:file:/path/to/jar!/BOOT-INF/lib/nested.jar}</li>
 *   <li>Nested JAR (Spring Boot Loader): {@code nested:/path/to/jar!/BOOT-INF/lib/nested.jar}</li>
 * </ul>
 */
public final class JarPathResolver {

    private static final Logger log = Logger.getLogger(JarPathResolver.class.getName());

    private JarPathResolver() {
    }

    /**
     * Определяет каталог, в котором находится JAR-файл приложения.
     *
     * @param clazz класс для определения location (обычно класс из основного модуля)
     * @return каталог, содержащий JAR-файл
     * @throws IOException если не удалось определить путь к JAR
     */
    public static Path resolveJarDirectory(Class<?> clazz) throws IOException {
        String locationStr = clazz.getProtectionDomain()
                .getCodeSource()
                .getLocation()
                .toString();

        log.log(Level.INFO, "Raw location string: {0}", locationStr);

        // Убираем префиксы jar:, nested:, file: и извлекаем путь к JAR
        String jarPathStr = normalizeLocationString(locationStr);
        log.log(Level.INFO, "Normalized JAR path: {0}", jarPathStr);

        Path jarPath = Paths.get(jarPathStr);
        
        if (!Files.exists(jarPath)) {
            throw new IOException("JAR file not found: " + jarPath);
        }

        Path jarDir = jarPath.getParent();
        if (jarDir == null) {
            throw new IOException("Cannot determine parent directory for JAR: " + jarPath);
        }

        log.log(Level.INFO, "Resolved JAR directory: {0} (from JAR: {1})", 
                new Object[]{jarDir, jarPath.getFileName()});
        return jarDir;
    }

    /**
     * Нормализует строку location, убирая все протоколы и извлекая реальный путь к JAR.
     */
    private static String normalizeLocationString(String locationStr) {
        String result = locationStr;
        
        // 1. Убираем jar: префикс если есть
        if (result.startsWith("jar:")) {
            result = result.substring(4);
        }
        
        // 2. Убираем nested: префикс если есть
        if (result.startsWith("nested:")) {
            result = result.substring(7);
        }
        
        // 3. Убираем file: префикс если есть
        if (result.startsWith("file:")) {
            result = result.substring(5);
        }
        
        // 4. На Windows убираем лишний / в начале (например, /D:/ -> D:/)
        if (result.startsWith("/") && result.length() > 2 && result.charAt(2) == ':') {
            result = result.substring(1);
        }
        
        // 5. Убираем всё после .jar (включая !/BOOT-INF и прочее)
        // Пример: D:/path/to/app.jar/!BOOT-INF/classes/!/ -> D:/path/to/app.jar
        // Пример: D:/app.jar!/BOOT-INF/lib/nested.jar -> D:/app.jar
        int jarExtIndex = result.toLowerCase().indexOf(".jar");
        if (jarExtIndex > 0) {
            int endIndex = jarExtIndex + 4; // ".jar".length()
            // Проверяем, есть ли что-то после .jar
            if (endIndex < result.length()) {
                char nextChar = result.charAt(endIndex);
                // Если после .jar идет !, / или \, обрезаем всё после .jar
                if (nextChar == '!' || nextChar == '/' || nextChar == '\\') {
                    result = result.substring(0, endIndex);
                }
            }
        }
        
        // 6. Убираем завершающий / если есть (кроме корневого /)
        while (result.length() > 1 && (result.endsWith("/") || result.endsWith("\\"))) {
            result = result.substring(0, result.length() - 1);
        }
        
        // 7. Нормализуем слэши для Windows
        if (System.getProperty("os.name", "").toLowerCase().contains("windows")) {
            result = result.replace('/', '\\');
        }
        
        return result;
    }
}
