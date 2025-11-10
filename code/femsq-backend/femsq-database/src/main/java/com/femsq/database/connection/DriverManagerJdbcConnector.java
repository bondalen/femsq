package com.femsq.database.connection;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

/**
 * Standard implementation that delegates to {@link DriverManager}.
 */
public class DriverManagerJdbcConnector implements JdbcConnector {

    @Override
    public Connection connect(String url, Properties properties) throws SQLException {
        return DriverManager.getConnection(url, properties);
    }
}
