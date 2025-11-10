package com.femsq.database.connection;

import static org.junit.jupiter.api.Assertions.*;

import com.femsq.database.auth.AuthenticationProvider;
import com.femsq.database.auth.CredentialsAuthenticationProvider;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.config.DatabaseConfigurationService.DatabaseConfigurationProperties;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class ConnectionFactoryTest {

    private RecordingJdbcConnector connector;
    private DatabaseConfigurationService configurationService;
    private ConnectionFactory connectionFactory;

    @BeforeEach
    void setUp() {
        connector = new RecordingJdbcConnector();
        configurationService = new StubConfigurationService();
        connectionFactory = new ConnectionFactory(connector, configurationService);
    }

    @AfterEach
    void tearDown() {
        connectionFactory.close();
    }

    @Test
    void buildJdbcUrlProducesExpectedFormat() {
        DatabaseConfigurationProperties config = new DatabaseConfigurationProperties("db.local", 1433, "femsq", "alex", "secret", "credentials");
        String url = connectionFactory.buildJdbcUrl(config);
        assertEquals("jdbc:sqlserver://db.local:1433;encrypt=false;trustServerCertificate=true", url);
    }

    @Test
    void createConnectionDelegatesToConnectorWithProperties() {
        AuthenticationProvider provider = new CredentialsAuthenticationProvider();
        DatabaseConfigurationProperties config = new DatabaseConfigurationProperties("db.local", 1433, "femsq", "alex", "secret", "credentials");

        Connection connection = connectionFactory.createConnection(config, provider);
        assertNull(connection, "Тестовый коннектор возвращает null");
        assertEquals("jdbc:sqlserver://db.local:1433;encrypt=false;trustServerCertificate=true", connector.capturedUrl);
        assertEquals("alex", connector.capturedProperties.getProperty("user"));
        assertEquals("secret", connector.capturedProperties.getProperty("password"));
        assertEquals("femsq", connector.capturedProperties.getProperty("databaseName"));
    }

    @Test
    void createConnectionWrapsSqlException() {
        connector.shouldThrow = true;
        AuthenticationProvider provider = new CredentialsAuthenticationProvider();
        DatabaseConfigurationProperties config = new DatabaseConfigurationProperties("db.local", 1433, "femsq", "alex", "secret", "credentials");

        assertThrows(ConnectionFactoryException.class, () -> connectionFactory.createConnection(config, provider));
    }

    @Test
    void closeDelegatesToConnector() {
        connectionFactory.close();
        assertTrue(connector.closed, "Должен вызываться close() у коннектора");
    }

    @Test
    void createConnectionUsesFactoryDefaults() {
        Connection connection = connectionFactory.createConnection();
        assertNull(connection, "Тестовый коннектор возвращает null");
        assertEquals("jdbc:sqlserver://stub.local:1433;encrypt=false;trustServerCertificate=true", connector.capturedUrl);
        assertEquals("alex", connector.capturedProperties.getProperty("user"));
        assertEquals("secret", connector.capturedProperties.getProperty("password"));
    }

    private static class RecordingJdbcConnector implements JdbcConnector {
        String capturedUrl;
        Properties capturedProperties;
        boolean shouldThrow;
        boolean closed;

        @Override
        public Connection connect(String url, Properties properties) throws SQLException {
            this.capturedUrl = url;
            this.capturedProperties = properties;
            if (shouldThrow) {
                throw new SQLException("test");
            }
            return null;
        }

        @Override
        public void close() {
            closed = true;
        }
    }

    private static class StubConfigurationService extends DatabaseConfigurationService {
        StubConfigurationService() {
            super(null, null);
        }

        @Override
        public DatabaseConfigurationProperties loadConfig() {
            return new DatabaseConfigurationProperties("stub.local", 1433, "femsq", "alex", "secret", "credentials");
        }
    }
}
