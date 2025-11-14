package com.femsq.web.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

/**
 * Конфигурация CORS для разрешения запросов с frontend.
 */
@Configuration
public class CorsConfig {

  @Bean
  public CorsFilter corsFilter() {
    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    CorsConfiguration config = new CorsConfiguration();
    
    // Разрешаем запросы с localhost:5175 (Vite dev server) и других портов
    config.addAllowedOriginPattern("http://localhost:*");
    config.addAllowedOriginPattern("http://127.0.0.1:*");
    
    // Разрешаем все методы HTTP
    config.addAllowedMethod("*");
    
    // Разрешаем все заголовки
    config.addAllowedHeader("*");
    
    // Разрешаем отправку credentials (cookies, authorization headers)
    config.setAllowCredentials(true);
    
    // Применяем конфигурацию ко всем путям
    source.registerCorsConfiguration("/**", config);
    
    return new CorsFilter(source);
  }
}
