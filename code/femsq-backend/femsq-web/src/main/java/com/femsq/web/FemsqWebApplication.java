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
            String loaderPath = System.getProperty("loader.path");
            if (loaderPath != null && loaderPath.contains("lib")) {
                Path libDir = resolveLibDirectory();
                if (libDir != null && libDir.toFile().exists()) {
                    LibraryCompatibilityChecker.ValidationResult result = 
                        LibraryCompatibilityChecker.verify(libDir);
                    
                    if (!result.isValid()) {
                        log.error("Library validation failed. Errors:");
                        result.getErrors().forEach(log::error);
                        log.error("Application startup aborted due to library validation errors.");
                        System.exit(1);
                    }
                    
                    if (result.hasWarnings()) {
                        log.warn("Library validation warnings:");
                        result.getWarnings().forEach(log::warn);
                    }
                } else {
                    log.warn("lib/ directory not found. Skipping library validation.");
                }
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
            String jarPath = FemsqWebApplication.class.getProtectionDomain()
                .getCodeSource()
                .getLocation()
                .getPath();
            
            if (jarPath != null) {
                // Убираем префикс file: и декодируем URL
                if (jarPath.startsWith("file:")) {
                    jarPath = jarPath.substring(5);
                }
                if (jarPath.contains("!")) {
                    jarPath = jarPath.substring(0, jarPath.indexOf("!"));
                }
                
                Path jarFile = Paths.get(jarPath);
                Path libDir = jarFile.getParent().resolve("lib");
                return libDir;
            }
        } catch (Exception e) {
            log.debug("Failed to resolve lib directory: {}", e.getMessage());
        }
        
        // Fallback: используем текущую директорию
        return Paths.get("lib");
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
