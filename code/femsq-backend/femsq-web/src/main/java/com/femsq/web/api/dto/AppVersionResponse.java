package com.femsq.web.api.dto;

/**
 * DTO версии приложения для UI.
 *
 * @param version строка версии сборки, например {@code 0.1.0.234-SNAPSHOT}
 */
public record AppVersionResponse(String version) {
}
