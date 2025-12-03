package com.femsq.web;

import com.femsq.database.auth.NativeLibraryLoader;
import com.femsq.web.startup.LibraryCompatibilityChecker;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * Точка входа Spring Boot-приложения FEMSQ Web API.
 */
@SpringBootApplication(scanBasePackages = {"com.femsq"})
public class FemsqWebApplication {
    
    private static final Logger log = LoggerFactory.getLogger(FemsqWebApplication.class);

    /**
     * Запускает Spring Boot-контекст для REST и GraphQL API.
     *
     * @param args аргументы командной строки
     */
    public static void main(String[] args) {
        // Настраиваем classpath для компилятора JasperReports (для работы в Spring Boot fat JAR)
        configureJasperReportsCompiler();
        
        // Загружаем native библиотеку для Windows Authentication ДО инициализации Spring
        NativeLibraryLoader.ensureSqlServerAuthLibrary();
        
        // Проверяем совместимость библиотек для thin JAR
        if (isThinJar()) {
            Path libDir = resolveLibDirectory();
            Path reportDir = resolveReportDirectory();
            
            if (libDir != null && libDir.toFile().exists()) {
                log.info("Thin JAR detected. Validating external libraries in: {}", libDir);
                LibraryCompatibilityChecker.ValidationResult result = 
                    LibraryCompatibilityChecker.verify(libDir, reportDir);
                
                // Блокируем запуск при любых ошибках (отсутствие библиотек или несовпадение версий)
                if (!result.isValid()) {
                    log.error("Critical library validation errors:");
                    result.getErrors().forEach(log::error);
                    log.error("Application startup aborted due to critical library validation errors.");
                    if (reportDir != null) {
                        log.error("See library version report for details in: {}", reportDir);
                    }
                    System.exit(1);
                }
                
                // Всегда показываем предупреждения
                if (result.hasWarnings()) {
                    log.warn("Library validation warnings:");
                    result.getWarnings().forEach(log::warn);
                }
            } else {
                log.warn("lib/ directory not found at: {}. Skipping library validation.", libDir);
            }
        }
        
        SpringApplication.run(FemsqWebApplication.class, args);
    }
    
    /**
     * Определяет, запущен ли thin JAR.
     */
    private static boolean isThinJar() {
        String jarPath = FemsqWebApplication.class.getProtectionDomain()
            .getCodeSource()
            .getLocation()
            .getPath();
        return jarPath != null && jarPath.contains("-thin.jar");
    }
    
    /**
     * Определяет путь к директории lib/.
     */
    private static Path resolveLibDirectory() {
        try {
            // Пытаемся определить путь к JAR
            java.net.URL location = FemsqWebApplication.class.getProtectionDomain()
                .getCodeSource()
                .getLocation();
            
            if (location != null) {
                String jarPath = location.getPath();
                
                if (jarPath != null) {
                    // Обрабатываем префикс nested: (используется Spring Boot Loader при java -cp)
                    if (jarPath.startsWith("nested:")) {
                        // Для nested: используем user.dir как базовую директорию
                        String userDir = System.getProperty("user.dir");
                        if (userDir != null) {
                            Path libDir = Paths.get(userDir).resolve("lib");
                            log.debug("Using user.dir for lib directory: {}", libDir);
                            return libDir;
                        }
                    }
                    
                    // Убираем префикс file: и декодируем URL
                    if (jarPath.startsWith("file:")) {
                        jarPath = jarPath.substring(5);
                    }
                    if (jarPath.contains("!")) {
                        jarPath = jarPath.substring(0, jarPath.indexOf("!"));
                    }
                    
                    // Декодируем URL-encoded символы
                    try {
                        jarPath = java.net.URLDecoder.decode(jarPath, "UTF-8");
                    } catch (java.io.UnsupportedEncodingException e) {
                        // Игнорируем, используем как есть
                    }
                    
                    Path jarFile = Paths.get(jarPath);
                    if (jarFile.toFile().exists()) {
                        Path libDir = jarFile.getParent().resolve("lib");
                        return libDir;
                    }
                }
            }
        } catch (Exception e) {
            log.debug("Failed to resolve lib directory: {}", e.getMessage());
        }
        
        // Fallback: используем user.dir (рабочая директория)
        String userDir = System.getProperty("user.dir");
        if (userDir != null) {
            Path libDir = Paths.get(userDir).resolve("lib");
            log.debug("Using user.dir fallback for lib directory: {}", libDir);
            return libDir;
        }
        
        // Последний fallback: относительный путь
        return Paths.get("lib");
    }
    
    /**
     * Определяет путь к директории для сохранения отчётов (рядом с тонким JAR).
     */
    private static Path resolveReportDirectory() {
        try {
            // Пытаемся определить путь к JAR
            java.net.URL location = FemsqWebApplication.class.getProtectionDomain()
                .getCodeSource()
                .getLocation();
            
            if (location != null) {
                String jarPath = location.getPath();
                
                if (jarPath != null) {
                    // Обрабатываем префикс nested: (используется Spring Boot Loader при java -cp)
                    if (jarPath.startsWith("nested:")) {
                        // Для nested: используем user.dir как базовую директорию
                        String userDir = System.getProperty("user.dir");
                        if (userDir != null) {
                            log.debug("Using user.dir for report directory: {}", userDir);
                            return Paths.get(userDir);
                        }
                    }
                    
                    // Убираем префикс file: и декодируем URL
                    if (jarPath.startsWith("file:")) {
                        jarPath = jarPath.substring(5);
                    }
                    if (jarPath.contains("!")) {
                        jarPath = jarPath.substring(0, jarPath.indexOf("!"));
                    }
                    
                    // Декодируем URL-encoded символы
                    try {
                        jarPath = java.net.URLDecoder.decode(jarPath, "UTF-8");
                    } catch (java.io.UnsupportedEncodingException e) {
                        // Игнорируем, используем как есть
                    }
                    
                    Path jarFile = Paths.get(jarPath);
                    if (jarFile.toFile().exists()) {
                        // Отчёты сохраняем в той же директории, где находится тонкий JAR
                        return jarFile.getParent();
                    }
                }
            }
        } catch (Exception e) {
            log.debug("Failed to resolve report directory: {}", e.getMessage());
        }
        
        // Fallback: используем user.dir (рабочая директория)
        String userDir = System.getProperty("user.dir");
        if (userDir != null) {
            log.debug("Using user.dir fallback for report directory: {}", userDir);
            return Paths.get(userDir);
        }
        
        // Последний fallback: текущая директория
        return Paths.get(".");
    }
    
    /**
     * Настраивает компилятор JasperReports для работы в Spring Boot nested JAR.
     * Использует встроенный компилятор, который работает через reflection и не требует внешнего Java компилятора.
     */
    private static void configureJasperReportsCompiler() {
        try {
            // Используем встроенный компилятор JREvaluatorCompiler, который компилирует выражения
            // через reflection и не требует внешнего Java компилятора с classpath
            System.setProperty("jasperreports.compiler", "net.sf.jasperreports.compilers.JREvaluatorCompiler");
            
            // Для Spring Boot nested JAR компилятор должен использовать текущий classloader
            // Это позволяет находить классы через reflection без указания classpath
            System.setProperty("jasperreports.compiler.use.current.classloader", "true");
            
            log.info("Configured JasperReports compiler (JREvaluatorCompiler) for Spring Boot nested JAR");
        } catch (Exception e) {
            log.warn("Failed to configure JasperReports compiler, compilation may fail: {}", e.getMessage());
        }
    }
}
