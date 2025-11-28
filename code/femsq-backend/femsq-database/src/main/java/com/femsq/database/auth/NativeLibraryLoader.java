package com.femsq.database.auth;

import com.femsq.database.util.JarPathResolver;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.attribute.PosixFilePermission;
import java.util.EnumSet;
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
    private static final String AUTH_RESOURCE_ROOT = "/com/microsoft/sqlserver/jdbc/auth/";
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

            // Всегда создаём папку native-libs рядом с JAR, даже на Linux
            // Это нужно для того, чтобы папка была доступна для извлечения из fat JAR
            try {
                Path libraryDir = resolveLibraryDirectory();
                log.log(Level.INFO, "Created native-libs directory: {0}", libraryDir);
            } catch (Exception e) {
                log.log(Level.WARNING, "Failed to create native-libs directory", e);
            }

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
        String resourcePath = AUTH_RESOURCE_ROOT + archFolder + "/" + libraryFileName;

        // Используем каталог рядом с JAR или временный каталог
        Path libraryDir = resolveLibraryDirectory();
        Path libraryPath = libraryDir.resolve(libraryFileName);

        try (InputStream inputStream = NativeLibraryLoader.class.getResourceAsStream(resourcePath)) {
            if (inputStream == null) {
                throw new IOException("Native library " + resourcePath + " not found inside JAR. "
                        + "Ensure mssql-jdbc_auth resources are packaged.");
            }
            try (FileOutputStream outputStream = new FileOutputStream(libraryPath.toFile())) {
                byte[] buffer = new byte[8192];
                int bytesRead;
                while ((bytesRead = inputStream.read(buffer)) != -1) {
                    outputStream.write(buffer, 0, bytesRead);
                }
            }
        }

        try {
            Files.setPosixFilePermissions(libraryPath, EnumSet.of(
                    PosixFilePermission.OWNER_READ,
                    PosixFilePermission.OWNER_WRITE,
                    PosixFilePermission.OWNER_EXECUTE,
                    PosixFilePermission.GROUP_READ,
                    PosixFilePermission.GROUP_EXECUTE,
                    PosixFilePermission.OTHERS_READ,
                    PosixFilePermission.OTHERS_EXECUTE
            ));
        } catch (UnsupportedOperationException ignored) {
            // На Windows это не поддерживается, игнорируем
        }

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

        // Создаём копии DLL с разными именами для максимальной совместимости
        // Драйвер может искать библиотеку под разными именами в зависимости от версии и контекста
        
        // Базовое имя, которое драйвер использует для поиска: "mssql-jdbc_auth-VERSION.ARCH"
        String baseLibraryName = String.format("mssql-jdbc_auth-%s.%s", driverVersion, archFolder);
        
        // Создаём все возможные варианты имён:
        // 1. Полное имя с версией и архитектурой: mssql-jdbc_auth-12.8.1.x64.dll (уже создано выше)
        // 2. Базовое имя драйвера с расширением: mssql-jdbc_auth-12.8.1.x64.dll (копия для надёжности)
        // 3. Короткое имя: mssql-jdbc_auth.dll
        // 4. Старое имя (обратная совместимость): sqljdbc_auth.dll
        
        Path driverNamePath = libraryDir.resolve(baseLibraryName + ".dll");
        Path shortNamePath = libraryDir.resolve("mssql-jdbc_auth.dll");
        Path legacyNamePath = libraryDir.resolve("sqljdbc_auth.dll");
        
        // Создаём копию с базовым именем драйвера (если это не тот же файл)
        if (!driverNamePath.equals(libraryPath)) {
            try {
                Files.copy(libraryPath, driverNamePath, java.nio.file.StandardCopyOption.REPLACE_EXISTING);
                log.log(Level.INFO, "Created driver name library copy: {0}", driverNamePath.getFileName());
            } catch (IOException copyException) {
                log.log(Level.WARNING, "Failed to create driver name copy (may affect compatibility)", copyException);
            }
        }
        
        // Создаём копию с коротким именем
        try {
            Files.copy(libraryPath, shortNamePath, java.nio.file.StandardCopyOption.REPLACE_EXISTING);
            log.log(Level.INFO, "Created short name library copy: {0}", shortNamePath.getFileName());
        } catch (IOException copyException) {
            log.log(Level.WARNING, "Failed to create short name copy (may affect compatibility)", copyException);
        }
        
        // Создаём копию со старым именем
        try {
            Files.copy(libraryPath, legacyNamePath, java.nio.file.StandardCopyOption.REPLACE_EXISTING);
            log.log(Level.INFO, "Created legacy name library copy: {0}", legacyNamePath.getFileName());
        } catch (IOException copyException) {
            log.log(Level.WARNING, "Failed to create legacy name copy (may affect compatibility)", copyException);
        }
        
        // Загружаем библиотеку явно через System.load() с полным путём
        // Это гарантирует, что библиотека будет загружена в JVM ДО того, как драйвер попытается её найти
        // Используем путь с полным именем, так как это оригинальная DLL из ресурсов
        System.load(libraryPath.toAbsolutePath().toString());
        log.log(Level.INFO, "Pre-loaded native library via System.load() from: {0}", libraryPath);
        
        // Логируем информацию для диагностики
        log.log(Level.INFO, "Library directory: {0}", libraryDir);
        log.log(Level.INFO, "Created {0} library file variants for maximum compatibility", 
                driverNamePath.equals(libraryPath) ? 3 : 4);
        log.log(Level.INFO, "Current java.library.path: {0}", System.getProperty("java.library.path"));
        log.log(Level.INFO, "Driver will use native NTLM authentication through: {0}", baseLibraryName);
    }

    /**
     * Определяет каталог для размещения нативных библиотек.
     * Приоритет: каталог рядом с основным JAR > временный каталог.
     * 
     * <p>Для тонкого JAR определяет директорию основного JAR (не вложенного из lib/).
     * Использует текущую рабочую директорию, так как JAR обычно запускается из своей директории.
     */
    private static Path resolveLibraryDirectory() throws IOException {
        try {
            Path jarDir = null;
            
            // Способ 1: Пробуем определить через основной класс приложения
            // Это должно указать на тонкий JAR, а не на вложенный JAR из lib/
            try {
                Class<?> mainClass = Class.forName("com.femsq.web.FemsqWebApplication");
                Path candidateDir = JarPathResolver.resolveJarDirectory(mainClass);
                
                // Проверяем, что это не вложенный JAR из lib/
                // Если путь содержит "lib", это может быть вложенный JAR
                String candidatePath = candidateDir.toString().replace('\\', '/');
                if (!candidatePath.contains("/lib/") && !candidatePath.endsWith("/lib")) {
                    jarDir = candidateDir;
                }
            } catch (ClassNotFoundException e) {
                // Основной класс недоступен, пробуем другой способ
            }
            
            // Способ 2: Если не удалось определить через основной класс,
            // пробуем найти тонкий JAR в java.class.path
            if (jarDir == null) {
                String classPath = System.getProperty("java.class.path", "");
                String pathSeparator = System.getProperty("path.separator", ":");
                String[] paths = classPath.split(pathSeparator);
                
                for (String path : paths) {
                    if (path.endsWith("-thin.jar") || (path.contains("femsq-web") && path.endsWith(".jar"))) {
                        Path candidateJar = Paths.get(path);
                        if (Files.exists(candidateJar)) {
                            Path candidateDir = candidateJar.getParent();
                            if (candidateDir != null) {
                                // Проверяем, что это не lib/
                                String candidatePath = candidateDir.toString().replace('\\', '/');
                                if (!candidatePath.endsWith("/lib")) {
                                    jarDir = candidateDir;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
            
            // Способ 3: Используем текущую рабочую директорию
            // (предполагаем, что JAR запущен из своей директории)
            if (jarDir == null) {
                jarDir = Paths.get(System.getProperty("user.dir", "."));
                log.log(Level.INFO, "Using current working directory: {0}", jarDir);
            }
            
            Path libDir = jarDir.resolve("native-libs");
            Files.createDirectories(libDir);
            log.log(Level.INFO, "Using library directory next to JAR: {0}", libDir);
            return libDir;
            
        } catch (Exception exception) {
            log.log(Level.WARNING, "Could not determine JAR directory, using temp directory", exception);
            // Fallback: используем временный каталог
            Path tempDir = Files.createTempDirectory("femsq-native-libs");
            tempDir.toFile().deleteOnExit();
            log.log(Level.WARNING, "Using temporary library directory: {0}", tempDir);
            return tempDir;
        }
    }

    private static String detectWindowsArch() {
        String arch = System.getProperty("os.arch", "").toLowerCase(Locale.ROOT);
        return arch.contains("64") ? "x64" : "x86";
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
