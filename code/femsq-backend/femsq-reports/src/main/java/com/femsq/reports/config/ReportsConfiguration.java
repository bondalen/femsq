package com.femsq.reports.config;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.web.client.RestTemplate;

/**
 * Конфигурация модуля отчётов.
 * 
 * <p>Включает автоматическую загрузку свойств из {@link ReportsProperties}
 * через {@link EnableConfigurationProperties}.
 * 
 * <p>Включает поддержку @Scheduled методов через {@link EnableScheduling}.
 * 
 * <p>Эта конфигурация автоматически активируется при наличии модуля
 * в classpath и позволяет использовать {@code @Autowired ReportsProperties}
 * в других компонентах.
 * 
 * @author Александр
 * @version 1.0.0
 * @since 2025-11-21
 */
@Configuration
@EnableConfigurationProperties(ReportsProperties.class)
@EnableScheduling
public class ReportsConfiguration {

    /**
     * Создаёт bean RestTemplate для загрузки данных из внешних API.
     * 
     * @return настроенный RestTemplate
     */
    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
}
