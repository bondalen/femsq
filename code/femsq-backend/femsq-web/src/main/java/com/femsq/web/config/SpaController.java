package com.femsq.web.config;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

/**
 * Контроллер для SPA routing (Vue Router).
 * 
 * <p>Перехватывает все запросы, которые не являются:
 * <ul>
 *   <li>API-запросами (/api/**)</li>
 *   <li>GraphQL-запросами (/graphql)</li>
 *   <li>Статическими файлами (файлы с расширениями)</li>
 * </ul>
 * 
 * <p>И перенаправляет их на index.html для обработки Vue Router на клиенте.
 */
@Controller
public class SpaController {

  /**
   * Обрабатывает все SPA-маршруты, перенаправляя их на index.html.
   * 
   * <p>Паттерн {@code /{path:[^\\.]*}} соответствует всем путям, которые:
   * <ul>
   *   <li>Не содержат точку (.) - исключает файлы с расширениями</li>
   * </ul>
   * 
   * <p>Важно: в Spring Boot контроллеры с более специфичными путями имеют приоритет.
   * Поэтому API-запросы (/api/**) и GraphQL-запросы (/graphql) будут обработаны
   * соответствующими контроллерами до того, как этот контроллер сможет их перехватить.
   * 
   * <p>Примеры маршрутов, которые будут обработаны:
   * <ul>
   *   <li>/organizations</li>
   *   <li>/connection</li>
   *   <li>/organizations/123</li>
   * </ul>
   * 
   * <p>Примеры маршрутов, которые НЕ будут обработаны (обрабатываются другими контроллерами):
   * <ul>
   *   <li>/api/v1/organizations - API-запрос (обрабатывается OgRestController)</li>
   *   <li>/graphql - GraphQL-запрос (обрабатывается GraphQL контроллером)</li>
   *   <li>/assets/index.js - статический файл (обрабатывается ResourceHandler)</li>
   * </ul>
   * 
   * @return имя представления для forward на index.html
   */
  @RequestMapping(value = {
      "/organizations",
      "/connection",
      "/{path:[^\\.]*}"  // Все пути без точки (исключает файлы с расширениями)
  })
  public String spaRoutes() {
    // Перенаправляем на index.html для обработки Vue Router
    return "forward:/index.html";
  }
}
