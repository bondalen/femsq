package com.femsq.database.dao;

import static org.junit.jupiter.api.Assertions.*;

import com.femsq.database.auth.AuthenticationProviderFactory;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.config.DatabaseConfigurationService.DatabaseConfigurationProperties;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.connection.HikariJdbcConnector;
import com.femsq.database.model.Og;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Assumptions;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

/**
 * Интеграционные тесты для проверки работы {@link JdbcOgDao} с разными схемами базы данных.
 */
class JdbcOgDaoSchemaTest {

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
        // Используем схему из переменной окружения или дефолтную "ags_test"
        String expectedSchema = baseConfiguration.schema();
        DatabaseConfigurationService configService = new StubConfigurationService(baseConfiguration);
        connectionFactory = new ConnectionFactory(
                new HikariJdbcConnector(),
                configService,
                providerFactory
        );
        JdbcOgDao dao = new JdbcOgDao(connectionFactory, configService);

        // Проверяем, что можем получить данные из схемы
        var organizations = dao.findAll();
        assertNotNull(organizations, "Список организаций не должен быть null");
        assertFalse(organizations.isEmpty(), "Должны быть организации в схеме " + expectedSchema);
    }

    /**
     * Проверяет, что при изменении схемы в конфигурации DAO использует новую схему.
     * <p>
     * Тест создает временную схему и проверяет, что DAO корректно работает с ней.
     * </p>
     */
    @Test
    void daoSwitchesSchemaWhenConfigurationChanges() throws SQLException {
        String testSchema = "ags_test_schema_test";
        
        // Создаем тестовую схему и таблицу
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
            JdbcOgDao dao = new JdbcOgDao(connectionFactory, configService);

            // Создаем тестовую организацию в тестовой схеме
            Og testOrg = new Og(
                    null,
                    "Тестовая организация для схемы",
                    "ООО «Тестовая организация для схемы»",
                    null,
                    "Организация для тестирования работы с разными схемами",
                    null,
                    null,
                    null,
                    null,
                    null,
                    "og"
            );

            Og created = dao.create(testOrg);
            assertNotNull(created.ogKey(), "Организация должна быть создана в схеме " + testSchema);
            
            // Проверяем, что можем найти созданную организацию
            var found = dao.findById(created.ogKey());
            assertTrue(found.isPresent(), "Организация должна быть найдена в схеме " + testSchema);
            assertEquals("Тестовая организация для схемы", found.get().ogName());
        } finally {
            // Очищаем тестовую схему
            dropTestSchema(testSchema);
        }
    }

    /**
     * Проверяет, что при отсутствии схемы в конфигурации используется дефолтная схема "ags_test".
     */
    @Test
    void daoUsesDefaultSchemaWhenSchemaNotConfigured() {
        // Конфигурация без явно указанной схемы (null)
        DatabaseConfigurationProperties configWithoutSchema = new DatabaseConfigurationProperties(
                baseConfiguration.host(),
                baseConfiguration.port(),
                baseConfiguration.database(),
                null, // Схема не указана
                baseConfiguration.username(),
                baseConfiguration.password(),
                baseConfiguration.authMode()
        );
        
        DatabaseConfigurationService configService = new StubConfigurationService(configWithoutSchema);
        connectionFactory = new ConnectionFactory(
                new HikariJdbcConnector(),
                configService,
                providerFactory
        );
        JdbcOgDao dao = new JdbcOgDao(connectionFactory, configService);

        // Проверяем, что метод getTableName() использует дефолтную схему
        // Это проверяется косвенно через выполнение запроса
        // Если схема не найдена, должен использоваться fallback "ags_test"
        assertDoesNotThrow(() -> {
            var organizations = dao.findAll();
            assertNotNull(organizations);
        }, "DAO должен работать с дефолтной схемой при отсутствии конфигурации");
    }

    /**
     * Создает тестовую схему и таблицу для тестирования.
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
                String createTableSql = String.format("""
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
                statement.execute(createTableSql);
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


