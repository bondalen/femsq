package com.femsq.web.api.rest;

import java.time.Instant;

/**
 * Стандартная структура ответа об ошибке REST API.
 *
 * @param timestamp время возникновения ошибки
 * @param status    HTTP-статус
 * @param error     текстовое описание статуса
 * @param message   сообщение об ошибке
 * @param path      запрошенный путь
 */
public record ApiError(
        Instant timestamp,
        int status,
        String error,
        String message,
        String path
) {
}
