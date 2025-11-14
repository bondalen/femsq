package com.femsq.database.dao;

import static org.junit.jupiter.api.Assertions.*;

import com.femsq.database.auth.AuthenticationProviderFactory;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.config.DatabaseConfigurationService.DatabaseConfigurationProperties;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.connection.HikariJdbcConnector;
import com.femsq.database.model.Og;
import com.femsq.database.model.OgAg;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.UUID;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Assumptions;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

/**
 * Интеграционные тесты для проверки работы {@link JdbcOgAgDao} с разными схемами базы данных.
 */
class JdbcOgAgDaoSchemaTest {

    private static ConnectionFactory connectionFactory;
    private static AuthenticationProviderFactory providerFactory;
    private static DatabaseConfigurationProperties baseConfiguration;

    @BeforeAll
    static void setUp() {
        Assumptions.assumeTrue(DaoIntegrationTestSupport.isDatabaseConfigured(),
                "FEMSQ_DB_PASSWORD must be set to run DAO schema tests");
        baseConfiguration = DaoIntegrationTestSupport.configurationFromEnv();
        providerFactory = AuthenticationProviderFactory.withDefaults();
    }

    @AfterAll
    static void tearDown() {
        if (connectionFactory != null) {
            connectionFactory.close();
        }
    }

    /**
     * Проверяет, что DAO корректно работает с дефолтной схемой из конфигурации.
     */
    @Test
    void daoUsesSchemaFromConfiguration() {
        DatabaseConfigurationService configService = new StubConfigurationService(baseConfiguration);
        connectionFactory = new ConnectionFactory(
                new HikariJdbcConnector(),
                configService,
                providerFactory
        );
        JdbcOgAgDao dao = new JdbcOgAgDao(connectionFactory, configService);

        // Проверяем, что можем получить данные из схемы
        var agents = dao.findAll();
        assertNotNull(agents, "Список агентских организаций не должен быть null");
    }

    /**
     * Проверяет, что при изменении схемы в конфигурации DAO использует новую схему.
     */
    @Test
    void daoSwitchesSchemaWhenConfigurationChanges() throws SQLException {
        String testSchema = "ags_test_schema_test_ag";
        
        // Создаем тестовую схему и таблицы
        createTestSchema(testSchema);
        
        try {
            // Конфигурация с тестовой схемой
            DatabaseConfigurationProperties testConfig = new DatabaseConfigurationProperties(
                    baseConfiguration.host(),
                    baseConfiguration.port(),
                    baseConfiguration.database(),
                    testSchema,
                    baseConfiguration.username(),
                    baseConfiguration.password(),
                    baseConfiguration.authMode()
            );
            
            DatabaseConfigurationService configService = new StubConfigurationService(testConfig);
            connectionFactory = new ConnectionFactory(
                    new HikariJdbcConnector(),
                    configService,
                    providerFactory
            );
            JdbcOgDao ogDao = new JdbcOgDao(connectionFactory, configService);
            JdbcOgAgDao dao = new JdbcOgAgDao(connectionFactory, configService);

            // Создаем тестовую организацию в тестовой схеме
            Og testOrg = new Og(
                    null,
                    "Тестовая организация для агентов",
                    "ООО «Тестовая организация для агентов»",
                    null,
                    "Организация для тестирования работы с разными схемами",
                    null,
                    null,
                    null,
                    null,
                    null,
                    "og"
            );

            Og createdOrg = ogDao.create(testOrg);
            assertNotNull(createdOrg.ogKey(), "Организация должна быть создана в схеме " + testSchema);
            
            // Создаем тестовую агентскую организацию
            OgAg testAgent = new OgAg(
                    null,
                    "TEST001",
                    createdOrg.ogKey(),
                    UUID.randomUUID()
            );

            OgAg created = dao.create(testAgent);
            assertNotNull(created.ogAgKey(), "Агентская организация должна быть создана в схеме " + testSchema);
            
            // Проверяем, что можем найти созданную агентскую организацию
            var found = dao.findById(created.ogAgKey());
            assertTrue(found.isPresent(), "Агентская организация должна быть найдена в схеме " + testSchema);
            assertEquals("TEST001", found.get().code());
            
            // Проверяем поиск по организации
            var agentsByOrg = dao.findByOrganization(createdOrg.ogKey());
            assertFalse(agentsByOrg.isEmpty(), "Должны быть найдены агенты для организации");
            assertTrue(agentsByOrg.stream().anyMatch(ag -> ag.ogAgKey().equals(created.ogAgKey())));
        } finally {
            // Очищаем тестовую схему
            dropTestSchema(testSchema);
        }
    }

    /**
     * Создает тестовую схему и таблицы для тестирования.
     */
    private void createTestSchema(String schemaName) throws SQLException {
        DatabaseConfigurationService tempConfigService = new StubConfigurationService(baseConfiguration);
        ConnectionFactory tempFactory = new ConnectionFactory(
                new HikariJdbcConnector(),
                tempConfigService,
                providerFactory
        );
        try {
            try (Connection connection = tempFactory.createConnection();
                 Statement statement = connection.createStatement()) {
                // Создаем схему, если её нет
                statement.execute("IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = '" + schemaName + "') " +
                        "EXEC('CREATE SCHEMA " + schemaName + "')");
                
                // Создаем таблицу og в тестовой схеме
                String createOgTableSql = String.format("""
                    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'%s.og') AND type in (N'U'))
                    CREATE TABLE %s.og (
                        ogKey INT IDENTITY(1,1) PRIMARY KEY,
                        ogNm NVARCHAR(255) NOT NULL,
                        ogNmOf NVARCHAR(500),
                        ogNmFl NVARCHAR(1000),
                        ogTxt NVARCHAR(MAX),
                        ogINN FLOAT,
                        ogKPP FLOAT,
                        ogOGRN FLOAT,
                        ogOKPO FLOAT,
                        ogOE INT,
                        ogRgTaxType NVARCHAR(10) NOT NULL
                    )
                    """, schemaName, schemaName);
                statement.execute(createOgTableSql);
                
                // Создаем таблицу ogAg в тестовой схеме
                String createOgAgTableSql = String.format("""
                    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'%s.ogAg') AND type in (N'U'))
                    CREATE TABLE %s.ogAg (
                        ogaKey INT IDENTITY(1,1) PRIMARY KEY,
                        ogaCode NVARCHAR(255) NOT NULL,
                        ogaOg INT NOT NULL,
                        ogaOidOld UNIQUEIDENTIFIER,
                        FOREIGN KEY (ogaOg) REFERENCES %s.og(ogKey) ON DELETE CASCADE
                    )
                    """, schemaName, schemaName, schemaName);
                statement.execute(createOgAgTableSql);
            }
        } finally {
            tempFactory.close();
        }
    }

    /**
     * Удаляет тестовую схему после тестирования.
     */
    private void dropTestSchema(String schemaName) {
        DatabaseConfigurationService tempConfigService = new StubConfigurationService(baseConfiguration);
        ConnectionFactory tempFactory = new ConnectionFactory(
                new HikariJdbcConnector(),
                tempConfigService,
                providerFactory
        );
        try {
            try (Connection connection = tempFactory.createConnection();
                 Statement statement = connection.createStatement()) {
                statement.execute("DROP SCHEMA IF EXISTS " + schemaName);
            }
        } catch (SQLException exception) {
            // Игнорируем ошибки при удалении тестовой схемы
        } finally {
            tempFactory.close();
        }
    }

    /**
     * Заглушка сервиса конфигурации для тестов.
     */
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


