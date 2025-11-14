package com.femsq.web.api.dto;

/**
 * DTO ответа с текущей конфигурацией подключения к БД (без пароля).
 *
 * @param host     хост MS SQL Server
 * @param port     порт подключения
 * @param database имя базы данных
 * @param schema   имя схемы
 * @param username имя пользователя
 * @param authMode режим аутентификации
 */
public record ConnectionConfigResponse(
        String host,
        Integer port,
        String database,
        String schema,
        String username,
        String authMode
) {
}


