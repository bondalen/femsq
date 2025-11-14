package com.femsq.web.api.dto;

/**
 * DTO ответа со статусом подключения к БД.
 *
 * @param connected флаг успешного подключения
 * @param schema    имя текущей схемы
 * @param database  имя базы данных
 * @param message   информационное сообщение
 * @param error     сообщение об ошибке (если есть)
 */
public record ConnectionStatusResponse(
        boolean connected,
        String schema,
        String database,
        String message,
        String error
) {
}


