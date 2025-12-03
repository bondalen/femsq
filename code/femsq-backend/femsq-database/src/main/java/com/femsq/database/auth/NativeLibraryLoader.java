package com.femsq.database.auth;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Locale;
import java.util.Objects;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Утилита для загрузки нативных библиотек из JAR-файла.
 *
 * <p>Поддерживает автоматическую загрузку библиотеки mssql-jdbc_auth для Windows Authentication
 * на Windows-системах. Библиотека извлекается из JAR во временную директорию, загружается через
 * {@link System#load(String)} и тем самым становится доступной для драйвера до того, как тот
 * попытается вызвать {@code System.loadLibrary}.
 *
 * <p>На Linux и других Unix-системах библиотека не требуется, так как используется JavaKerberos.
 */
public final class NativeLibraryLoader {

    private static final Logger log = Logger.getLogger(NativeLibraryLoader.class.getName());
    private static final String DRIVER_POM_PROPERTIES =
            "META-INF/maven/com.microsoft.sqlserver/mssql-jdbc/pom.properties";

    private static final Object loadLock = new Object();
    private static volatile boolean libraryLoaded = false;

    private NativeLibraryLoader() {
    }

    /**
     * Загружает нативную библиотеку для Windows Authentication, если это необходимо.
     * Всегда создаёт папку native-libs рядом с JAR для последующего использования.
     *
     * <p>Метод безопасен для многократного вызова - библиотека загружается только один раз.
     *
     * @return {@code true} если библиотека успешно загружена или не требуется,
     *         {@code false} если произошла ошибка загрузки
     */
    public static boolean ensureSqlServerAuthLibrary() {
        synchronized (loadLock) {
            if (libraryLoaded) {
                return true;
            }

            // НЕ создаём папку native-libs программно
            // Пользователь будет копировать её вручную при необходимости
            // Это позволяет избежать проблем с определением правильной директории

            String osName = System.getProperty("os.name", "").toLowerCase(Locale.ROOT);
            if (!osName.contains("windows")) {
                log.log(Level.FINE, "Native library not required on {0}, using JavaKerberos", osName);
                libraryLoaded = true; // Не требуется, но считаем успешным
                return true;
            }

            try {
                loadWindowsAuthLibrary();
                libraryLoaded = true;
                log.log(Level.INFO, "Successfully loaded mssql-jdbc_auth library for Windows Authentication");
                return true;
            } catch (Exception exception) {
                log.log(Level.WARNING, "Failed to load mssql-jdbc_auth library, will use JavaKerberos instead", exception);
                // Не блокируем работу - попробуем использовать JavaKerberos
                return false;
            }
        }
    }

    private static void loadWindowsAuthLibrary() throws IOException {
        String archFolder = detectWindowsArch();
        String driverVersion = detectDriverVersion();
        String libraryFileName = String.format("mssql-jdbc_auth-%s.%s.dll", driverVersion, archFolder);

        // Определяем директорию native-libs рядом с тонким JAR (не в lib/)
        // Ищем тонкий JAR в текущей директории
        Path libraryDir = resolveNativeLibsDirectory();
        
        // Проверяем, существует ли директория (должна быть создана вручную)
        if (!Files.exists(libraryDir) || !Files.isDirectory(libraryDir)) {
            throw new IOException("Native library directory not found: " + libraryDir + 
                ". Please copy native-libs directory manually.");
        }
        
        // Ищем библиотеку в native-libs (должна быть скопирована вручную)
        // Пробуем разные варианты имён
        Path libraryPath = null;
        String[] possibleNames = {
            libraryFileName,  // mssql-jdbc_auth-12.8.1.x64.dll
            "mssql-jdbc_auth.dll",  // короткое имя
            "sqljdbc_auth.dll"  // старое имя
        };
        
        for (String name : possibleNames) {
            Path candidate = libraryDir.resolve(name);
            if (Files.exists(candidate)) {
                libraryPath = candidate;
                log.log(Level.INFO, "Found native library: {0}", candidate);
                break;
            }
        }
        
        if (libraryPath == null || !Files.exists(libraryPath)) {
            throw new IOException("Native library not found in " + libraryDir + 
                ". Expected one of: " + String.join(", ", possibleNames) +
                ". Please copy native-libs directory manually.");
        }

        // Права доступа уже должны быть установлены при копировании папки вручную
        // На Windows права доступа не требуются

        // КРИТИЧНО: Добавляем путь к библиотеке в java.library.path ДО загрузки
        // Это нужно для того, чтобы драйвер мог найти DLL через System.loadLibrary()
        String currentLibraryPath = System.getProperty("java.library.path", "");
        String newLibraryPath = libraryDir.toAbsolutePath().toString();
        if (!currentLibraryPath.contains(newLibraryPath)) {
            String updatedLibraryPath = currentLibraryPath.isEmpty()
                    ? newLibraryPath
                    : currentLibraryPath + java.io.File.pathSeparator + newLibraryPath;
            System.setProperty("java.library.path", updatedLibraryPath);
            log.log(Level.INFO, "Added library directory to java.library.path: {0}", newLibraryPath);
            
            // На Windows также нужно обновить системную переменную окружения PATH
            // для текущего процесса (через reflection, так как System.loadLibrary использует её)
            try {
                java.lang.reflect.Field sysPathsField = ClassLoader.class.getDeclaredField("sys_paths");
                sysPathsField.setAccessible(true);
                sysPathsField.set(null, null); // Сбрасываем кэш путей, чтобы перечитать java.library.path
            } catch (Exception reflectionException) {
                log.log(Level.FINE, "Could not reset sys_paths cache (non-critical)", reflectionException);
            }
        }

        // Библиотека уже должна быть в native-libs (скопирована вручную)
        // Не создаём копии - используем то, что есть
        
        // Загружаем библиотеку явно через System.load() с полным путём
        // Это гарантирует, что библиотека будет загружена в JVM ДО того, как драйвер попытается её найти
        // Используем путь с полным именем, так как это оригинальная DLL из ресурсов
        System.load(libraryPath.toAbsolutePath().toString());
        log.log(Level.INFO, "Pre-loaded native library via System.load() from: {0}", libraryPath);
        
        // Логируем информацию для диагностики
        log.log(Level.INFO, "Library directory: {0}", libraryDir);
        log.log(Level.INFO, "Current java.library.path: {0}", System.getProperty("java.library.path"));
        log.log(Level.INFO, "Driver will use native NTLM authentication");
    }

    private static String detectWindowsArch() {
        String arch = System.getProperty("os.arch", "").toLowerCase(Locale.ROOT);
        return arch.contains("64") ? "x64" : "x86";
    }

    /**
     * Определяет директорию для native-libs рядом с тонким JAR.
     * Ищет тонкий JAR (femsq-web-*-thin.jar) в текущей директории.
     */
    private static Path resolveNativeLibsDirectory() {
        // Сначала пытаемся найти тонкий JAR в текущей директории
        Path currentDir = Paths.get(System.getProperty("user.dir", "."));
        
        try {
            // Ищем файлы, соответствующие паттерну тонкого JAR
            java.io.File dir = currentDir.toFile();
            if (dir.exists() && dir.isDirectory()) {
                java.io.File[] files = dir.listFiles((d, name) -> 
                    name.startsWith("femsq-web-") && name.contains("-thin.jar"));
                
                if (files != null && files.length > 0) {
                    // Найден тонкий JAR - используем его директорию
                    Path thinJarDir = files[0].getParentFile().toPath();
                    Path nativeLibsDir = thinJarDir.resolve("native-libs");
                    log.log(Level.INFO, "Found thin JAR: {0}, using native-libs directory: {1}", 
                        new Object[]{files[0].getName(), nativeLibsDir});
                    return nativeLibsDir;
                }
            }
        } catch (Exception e) {
            log.log(Level.WARNING, "Failed to find thin JAR in current directory, using fallback", e);
        }
        
        // Fallback: используем текущую директорию
        Path nativeLibsDir = currentDir.resolve("native-libs");
        log.log(Level.INFO, "Using fallback native-libs directory: {0}", nativeLibsDir);
        return nativeLibsDir;
    }

    private static String detectDriverVersion() throws IOException {
        try (InputStream is = NativeLibraryLoader.class.getClassLoader().getResourceAsStream(DRIVER_POM_PROPERTIES)) {
            if (is == null) {
                throw new IOException("Unable to locate " + DRIVER_POM_PROPERTIES + " inside classpath");
            }
            Properties properties = new Properties();
            properties.load(is);
            String rawVersion = Objects.requireNonNull(properties.getProperty("version"),
                    "mssql-jdbc version is not specified in pom.properties");
            int idx = rawVersion.indexOf(".jre");
            return idx > 0 ? rawVersion.substring(0, idx) : rawVersion;
        }
    }

    /**
     * Проверяет, загружена ли библиотека.
     */
    public static boolean isLibraryLoaded() {
        return libraryLoaded;
    }
}
