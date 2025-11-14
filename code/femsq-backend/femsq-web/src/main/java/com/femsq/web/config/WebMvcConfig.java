package com.femsq.web.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Конфигурация Spring MVC для обслуживания статических ресурсов и SPA routing.
 * 
 * <p>Настраивает:
 * <ul>
 *   <li>Обслуживание статических ресурсов из classpath:/static/</li>
 *   <li>Перенаправление корневого пути на index.html для SPA</li>
 * </ul>
 */
@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

  /**
   * Настраивает обработчики статических ресурсов.
   * 
   * <p>Ресурсы из classpath:/static/ будут доступны:
   * <ul>
   *   <li>По пути /static/** (явный путь к статическим ресурсам)</li>
   *   <li>Напрямую по корневому пути для файлов, которые существуют в static/ 
   *       (например, /index.html, /assets/...)</li>
   * </ul>
   * 
   * <p>Важно: обработчики ресурсов имеют более низкий приоритет, чем контроллеры,
   * поэтому API-запросы (/api/**) не будут перехвачены.
   * 
   * @param registry реестр обработчиков ресурсов
   */
  @Override
  public void addResourceHandlers(ResourceHandlerRegistry registry) {
    // Обслуживание статических ресурсов из classpath:/static/ по явному пути
    registry
        .addResourceHandler("/static/**")
        .addResourceLocations("classpath:/static/")
        .resourceChain(false); // Отключаем кэширование для production (можно включить для оптимизации)
    
    // Обслуживание статических ресурсов напрямую из корня
    // Spring Boot автоматически проверит существование файла перед обслуживанием
    // Это позволяет обслуживать /index.html, /assets/... напрямую
    // 
    // Важно: обработчики ресурсов имеют более низкий приоритет, чем контроллеры,
    // поэтому API-запросы (/api/**) не будут перехвачены этим обработчиком
    registry
        .addResourceHandler("/**")
        .addResourceLocations("classpath:/static/")
        .resourceChain(false);
  }

  /**
   * Настраивает перенаправления для SPA.
   * 
   * <p>Корневой путь "/" перенаправляется на "/index.html",
   * что позволяет Vue Router обрабатывать маршрутизацию на клиенте.
   * 
   * @param registry реестр контроллеров представлений
   */
  @Override
  public void addViewControllers(ViewControllerRegistry registry) {
    // Перенаправление корневого пути на index.html для SPA
    registry.addViewController("/").setViewName("forward:/index.html");
  }
}
