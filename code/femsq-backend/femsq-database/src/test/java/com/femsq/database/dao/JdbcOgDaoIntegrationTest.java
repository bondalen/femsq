package com.femsq.database.dao;

import static org.junit.jupiter.api.Assertions.*;

import com.femsq.database.auth.AuthenticationProvider;
import com.femsq.database.auth.AuthenticationProviderFactory;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.Og;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Assumptions;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class JdbcOgDaoIntegrationTest {

    private static ConnectionFactory connectionFactory;
    private static AuthenticationProviderFactory providerFactory;
    private static AuthenticationProvider authenticationProvider;
    private static JdbcOgDao dao;

    @BeforeAll
    static void setUp() {
        Assumptions.assumeTrue(DaoIntegrationTestSupport.isDatabaseConfigured(),
                "FEMSQ_DB_PASSWORD must be set to run DAO integration tests");
        var configuration = DaoIntegrationTestSupport.configurationFromEnv();
        providerFactory = AuthenticationProviderFactory.withDefaults();
        connectionFactory = DaoIntegrationTestSupport.createConnectionFactory(configuration);
        authenticationProvider = providerFactory.create(configuration);
        dao = new JdbcOgDao(connectionFactory);
    }

    @AfterAll
    static void tearDown() {
        if (connectionFactory != null) {
            connectionFactory.close();
        }
    }

    @BeforeEach
    void resetData() throws IOException, SQLException {
        DaoIntegrationTestSupport.resetSchema(connectionFactory);
        try (var connection = connectionFactory.createConnection(authenticationProvider)) {
            assertNotNull(connection);
        }
    }

    @Test
    void findAllReturnsSeedData() {
        List<Og> organizations = dao.findAll();

        assertEquals(3, organizations.size(), "Seed script must create three organizations");
        assertTrue(organizations.stream().anyMatch(og -> "Рога, ООО".equals(og.ogName())));
        assertTrue(organizations.stream().anyMatch(og -> "Рога и копыта, АО".equals(og.ogName())));
        assertTrue(organizations.stream().anyMatch(og -> "Копыта и хвосты, ИП".equals(og.ogName())));
    }

    @Test
    void createInsertsNewOrganization() {
        Og newOrganization = new Og(
                null,
                "Тестовая организация",
                "Общество с ограниченной ответственностью «Тестовая организация»",
                null,
                "Организация создана интеграционным тестом",
                1234567890d,
                null,
                null,
                null,
                null,
                "og"
        );

        Og created = dao.create(newOrganization);

        assertNotNull(created.ogKey(), "Созданная организация должна иметь идентификатор");
        assertEquals("Тестовая организация", created.ogName());
        assertTrue(dao.findById(created.ogKey()).isPresent(), "Организация должна быть доступна по идентификатору");
    }

    @Test
    void updateChangesOrganizationDescription() {
        Og existing = dao.findById(1).orElseThrow();
        Og updated = new Og(
                existing.ogKey(),
                existing.ogName(),
                existing.ogOfficialName(),
                existing.ogFullName(),
                "Обновленное описание",
                existing.inn(),
                existing.kpp(),
                existing.ogrn(),
                existing.okpo(),
                existing.oe(),
                existing.registrationTaxType()
        );

        Og saved = dao.update(updated);

        assertEquals("Обновленное описание", saved.ogDescription());
        assertEquals("Обновленное описание", dao.findById(existing.ogKey()).orElseThrow().ogDescription());
    }

    @Test
    void deleteByIdRemovesOrganization() {
        Og created = dao.create(new Og(
                null,
                "Удаляемая организация",
                "Общество с ограниченной ответственностью «Удаляемая организация»",
                null,
                "На удаление",
                null,
                null,
                null,
                null,
                null,
                "og"
        ));

        boolean deleted = dao.deleteById(created.ogKey());

        assertTrue(deleted, "Метод должен возвращать true при успешном удалении");
        assertTrue(dao.findById(created.ogKey()).isEmpty());
    }

    @Test
    void createFailsWhenTaxTypeInvalid() {
        Og invalid = new Og(
                null,
                "Организация с некорректным налоговым режимом",
                "Организация с некорректным налоговым режимом",
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                "xx"
        );

        assertThrows(DaoException.class, () -> dao.create(invalid));
    }

    @Test
    void deleteOrganizationCascadeRemovesAgents() {
        JdbcOgAgDao agentDao = new JdbcOgAgDao(connectionFactory);
        assertFalse(agentDao.findByOrganization(1).isEmpty(), "Предполагается, что у og=1 есть агент");

        boolean deleted = dao.deleteById(1);

        assertTrue(deleted);
        assertTrue(agentDao.findByOrganization(1).isEmpty(), "Агентские записи должны удаляться каскадно");
    }

    @Test
    void updateNonExistingThrowsDaoException() {
        Og missing = new Og(
                9999,
                "Несуществующая организация",
                "Общество с ограниченной ответственностью «Несуществующая организация»",
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                "og"
        );

        assertThrows(DaoException.class, () -> dao.update(missing));
    }
}
