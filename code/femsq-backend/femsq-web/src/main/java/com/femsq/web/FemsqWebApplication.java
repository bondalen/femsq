package com.femsq.web;

import com.femsq.database.auth.NativeLibraryLoader;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Точка входа Spring Boot-приложения FEMSQ Web API.
 */
@SpringBootApplication(scanBasePackages = {"com.femsq"})
public class FemsqWebApplication {

    /**
     * Запускает Spring Boot-контекст для REST и GraphQL API.
     *
     * @param args аргументы командной строки
     */
    public static void main(String[] args) {
        // Загружаем native библиотеку для Windows Authentication ДО инициализации Spring
        NativeLibraryLoader.ensureSqlServerAuthLibrary();
        
        SpringApplication.run(FemsqWebApplication.class, args);
    }
}
