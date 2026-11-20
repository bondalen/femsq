package com.femsq.web.api.dto;

/**
 * DTO ответа со статусом подключения к БД.
 *
 * @param connected      флаг успешного подключения
 * @param schema         имя текущей схемы (database.properties)
 * @param database       имя базы данных
 * @param message        информационное сообщение
 * @param error          сообщение об ошибке (если есть)
 * @param sudzAvailable  доступен ли слой СУДЗ ({@code femsq.sudz.schema}.yr); {@code null} если не проверялось
 */
public record ConnectionStatusResponse(
        boolean connected,
        String schema,
        String database,
        String message,
        String error,
        Boolean sudzAvailable
) {
    /**
     * Совместимый конструктор без флага СУДЗ (флаг = {@code null}).
     */
    public ConnectionStatusResponse(
            boolean connected,
            String schema,
            String database,
            String message,
            String error) {
        this(connected, schema, database, message, error, null);
    }
}
