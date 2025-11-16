package com.femsq.web.config;

import org.springframework.boot.SpringBootConfiguration;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.context.annotation.ComponentScan;

/**
 * Тестовая конфигурация для интеграционных тестов модуля femsq-web.
 * 
 * <p>Используется для явного указания главного класса приложения при запуске
 * интеграционных тестов через Maven Failsafe Plugin. Решает проблему с
 * автоматическим обнаружением {@code @SpringBootConfiguration} в Spring Boot 3.4.5.
 * 
 * <p>Эта конфигурация дублирует настройки из {@code FemsqWebApplication},
 * но может быть использована в {@code @SpringBootTest(classes=...)}.
 * 
 * <p>Использование:
 * <pre>{@code
 * @SpringBootTest(classes = IntegrationTestConfiguration.class, webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
 * class MyIntegrationTest {
 *     // ...
 * }
 * }</pre>
 */
@SpringBootConfiguration
@EnableAutoConfiguration
@ComponentScan(basePackages = "com.femsq")
public class IntegrationTestConfiguration {
    // Конфигурация дублирует настройки из FemsqWebApplication
    // для использования в интеграционных тестах
}

