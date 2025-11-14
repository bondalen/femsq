package com.femsq.database.connection;

import static org.junit.jupiter.api.Assertions.*;

import com.femsq.database.auth.AuthenticationProvider;
import com.femsq.database.auth.AuthenticationProviderFactory;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.config.DatabaseConfigurationService.DatabaseConfigurationProperties;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Locale;
import org.junit.jupiter.api.Assumptions;
import org.junit.jupiter.api.Test;

class ConnectionFactoryIntegrationTest {

    @Test
    void connectsToRealDatabaseAndFindsTestSchema() throws SQLException {
        String password = System.getenv("FEMSQ_DB_PASSWORD");
        Assumptions.assumeTrue(password != null && !password.isBlank(),
                "FEMSQ_DB_PASSWORD must be set to run integration test");

        String host = envOr("FEMSQ_DB_HOST", "localhost");
        int port = Integer.parseInt(envOr("FEMSQ_DB_PORT", "1433"));
        String database = envOr("FEMSQ_DB_NAME", "FishEye");
        String schema = envOr("FEMSQ_DB_SCHEMA", "ags_test");
        String authMode = envOr("FEMSQ_DB_AUTH_MODE", "credentials").toLowerCase(Locale.ROOT);
        String username = "credentials".equals(authMode) ? envOr("FEMSQ_DB_USER", "sa") : null;

        DatabaseConfigurationProperties configuration = new DatabaseConfigurationProperties(
                host,
                port,
                database,
                schema,
                username,
                "credentials".equals(authMode) ? password : null,
                authMode
        );

        AuthenticationProviderFactory providerFactory = AuthenticationProviderFactory.withDefaults();
        AuthenticationProvider provider = providerFactory.create(configuration);

        try (ConnectionFactory factory = new ConnectionFactory(new HikariJdbcConnector(),
                new StubConfigurationService(configuration), providerFactory)) {
            try (Connection connection = factory.createConnection(configuration, provider)) {
                assertNotNull(connection);
                assertTrue(connection.isValid(5), "Connection should be valid within 5 seconds");
                assertSchemaExists(connection, "ags_test");
            }
        }
    }

    private void assertSchemaExists(Connection connection, String schema) throws SQLException {
        try (var statement = connection.createStatement();
             var resultSet = statement.executeQuery(
                     "SELECT name FROM sys.schemas WHERE name = '" + schema + "'")) {
            assertTrue(resultSet.next(), () -> "Schema " + schema + " must exist in target database");
        }
    }

    private static String envOr(String key, String fallback) {
        String value = System.getenv(key);
        return value == null || value.isBlank() ? fallback : value;
    }

    private static class StubConfigurationService extends DatabaseConfigurationService {
        private final DatabaseConfigurationProperties configuration;

        StubConfigurationService(DatabaseConfigurationProperties configuration) {
            super(null, null);
            this.configuration = configuration;
        }

        @Override
        public DatabaseConfigurationProperties loadConfig() {
            return configuration;
        }
    }
}
