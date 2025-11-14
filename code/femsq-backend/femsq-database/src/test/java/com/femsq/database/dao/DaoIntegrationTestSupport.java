package com.femsq.database.dao;

import com.femsq.database.auth.AuthenticationProviderFactory;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.connection.HikariJdbcConnector;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.config.DatabaseConfigurationService.DatabaseConfigurationProperties;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.List;
import java.util.Locale;

final class DaoIntegrationTestSupport {

    private static final Path SEED_SCRIPT = Path.of("..", "..", "config", "sql", "ags_test_seed.sql");

    private DaoIntegrationTestSupport() {
    }

    static boolean isDatabaseConfigured() {
        String password = System.getenv("FEMSQ_DB_PASSWORD");
        return password != null && !password.isBlank();
    }

    static DatabaseConfigurationProperties configurationFromEnv() {
        String host = envOr("FEMSQ_DB_HOST", "localhost");
        int port = Integer.parseInt(envOr("FEMSQ_DB_PORT", "1433"));
        String database = envOr("FEMSQ_DB_NAME", "FishEye");
        String schema = envOr("FEMSQ_DB_SCHEMA", "ags_test");
        String authMode = envOr("FEMSQ_DB_AUTH_MODE", "credentials").toLowerCase(Locale.ROOT);
        String username = "credentials".equals(authMode) ? envOr("FEMSQ_DB_USER", "sa") : null;
        String password = "credentials".equals(authMode) ? System.getenv("FEMSQ_DB_PASSWORD") : null;
        return new DatabaseConfigurationProperties(host, port, database, schema, username, password, authMode);
    }

    static ConnectionFactory createConnectionFactory(DatabaseConfigurationProperties configuration) {
        AuthenticationProviderFactory providerFactory = AuthenticationProviderFactory.withDefaults();
        return new ConnectionFactory(new HikariJdbcConnector(), new StubConfigurationService(configuration), providerFactory);
    }

    static DatabaseConfigurationService createConfigurationService(DatabaseConfigurationProperties configuration) {
        return new StubConfigurationService(configuration);
    }

    static void resetSchema(ConnectionFactory factory) throws IOException, SQLException {
        List<String> lines = Files.readAllLines(SEED_SCRIPT);
        try (Connection connection = factory.createConnection()) {
            executeScript(connection, lines);
        }
    }

    private static void executeScript(Connection connection, List<String> lines) throws SQLException {
        StringBuilder statementBuilder = new StringBuilder();
        try (Statement statement = connection.createStatement()) {
            for (String line : lines) {
                if (line.trim().equalsIgnoreCase("GO")) {
                    runStatement(statement, statementBuilder);
                } else {
                    statementBuilder.append(line).append(System.lineSeparator());
                }
            }
            runStatement(statement, statementBuilder);
        }
    }

    private static void runStatement(Statement statement, StringBuilder statementBuilder) throws SQLException {
        String sql = statementBuilder.toString().trim();
        if (!sql.isEmpty()) {
            statement.execute(sql);
        }
        statementBuilder.setLength(0);
    }

    private static String envOr(String key, String fallback) {
        String value = System.getenv(key);
        return value == null || value.isBlank() ? fallback : value;
    }

    private static final class StubConfigurationService extends DatabaseConfigurationService {
        private final DatabaseConfigurationProperties configuration;

        private StubConfigurationService(DatabaseConfigurationProperties configuration) {
            super(null, null);
            this.configuration = configuration;
        }

        @Override
        public DatabaseConfigurationProperties loadConfig() {
            return configuration;
        }
    }
}
