package com.femsq.database.auth;

import com.femsq.database.config.DatabaseConfigurationService.DatabaseConfigurationProperties;
import java.util.Properties;

/**
 * Authentication provider responsible for preparing JDBC properties for a MS SQL Server connection.
 * <p>
 * Concrete implementations build the set of properties required for the specific authentication
 * mechanism (integrated security, trusted connection, username/password etc.).
 * </p>
 */
public interface AuthenticationProvider {

    /**
     * Builds JDBC connection properties suitable for the configured authentication strategy.
     *
     * @param configuration валидированная конфигурация подключения к базе данных
     * @return {@link Properties} объект, который будет передан коннектору JDBC
     */
    Properties buildProperties(DatabaseConfigurationProperties configuration);

    /**
     * @return человекочитаемое имя стратегии аутентификации
     */
    String getName();
}
