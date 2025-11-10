package com.femsq.database.connection;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;

/**
 * Abstraction over JDBC connection creation. Allows to plug different implementations (e.g. for tests).
 */
public interface JdbcConnector {

    /**
     * Opens a JDBC connection using the provided URL and properties.
     *
     * @param url      JDBC URL
     * @param properties дополнительные свойства подключения
     * @return установленное соединение
     * @throws SQLException при ошибке соединения
     */
    Connection connect(String url, Properties properties) throws SQLException;
}
