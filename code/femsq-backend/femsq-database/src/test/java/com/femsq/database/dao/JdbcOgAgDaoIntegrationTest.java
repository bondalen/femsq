package com.femsq.database.dao;

import static org.junit.jupiter.api.Assertions.*;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.Og;
import com.femsq.database.model.OgAg;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Assumptions;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class JdbcOgAgDaoIntegrationTest {

    private static ConnectionFactory connectionFactory;
    private static DatabaseConfigurationService configurationService;
    private static JdbcOgDao ogDao;
    private static JdbcOgAgDao dao;

    @BeforeAll
    static void setUp() {
        Assumptions.assumeTrue(DaoIntegrationTestSupport.isDatabaseConfigured(),
                "FEMSQ_DB_PASSWORD must be set to run DAO integration tests");
        var configuration = DaoIntegrationTestSupport.configurationFromEnv();
        connectionFactory = DaoIntegrationTestSupport.createConnectionFactory(configuration);
        configurationService = DaoIntegrationTestSupport.createConfigurationService(configuration);
        ogDao = new JdbcOgDao(connectionFactory, configurationService);
        dao = new JdbcOgAgDao(connectionFactory, configurationService);
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
    }

    @Test
    void findByOrganizationReturnsSeedAgents() {
        Og organization = ogDao.findById(1).orElseThrow();

        List<OgAg> agents = dao.findByOrganization(organization.ogKey());

        assertEquals(1, agents.size(), "Каждая организация из seed-скрипта должна иметь одного агента");
        assertEquals(organization.ogKey(), agents.getFirst().organizationKey());
    }

    @Test
    void createInsertsNewAgentForOrganization() {
        Og organization = ogDao.findById(2).orElseThrow();
        OgAg newAgent = new OgAg(null, "900", organization.ogKey(), UUID.randomUUID());

        OgAg created = dao.create(newAgent);

        assertNotNull(created.ogAgKey());
        assertEquals("900", created.code());
        assertEquals(organization.ogKey(), created.organizationKey());
        assertTrue(dao.findById(created.ogAgKey()).isPresent());
    }

    @Test
    void updateModifiesAgentCode() {
        Og organization = ogDao.findById(3).orElseThrow();
        OgAg existing = dao.findByOrganization(organization.ogKey()).getFirst();
        OgAg updated = new OgAg(existing.ogAgKey(), "777", organization.ogKey(), existing.legacyOid());

        OgAg saved = dao.update(updated);

        assertEquals("777", saved.code());
        assertEquals("777", dao.findById(existing.ogAgKey()).orElseThrow().code());
    }

    @Test
    void deleteByIdRemovesAgent() {
        Og organization = ogDao.findById(1).orElseThrow();
        OgAg created = dao.create(new OgAg(null, "901", organization.ogKey(), null));

        boolean deleted = dao.deleteById(created.ogAgKey());

        assertTrue(deleted);
        assertTrue(dao.findById(created.ogAgKey()).isEmpty());
    }

    @Test
    void createFailsForMissingOrganization() {
        OgAg invalid = new OgAg(null, "905", 9999, null);

        assertThrows(DaoException.class, () -> dao.create(invalid));
    }

    @Test
    void updateMissingAgentThrowsDaoException() {
        Og organization = ogDao.findById(1).orElseThrow();
        OgAg missing = new OgAg(9999, "990", organization.ogKey(), null);

        assertThrows(DaoException.class, () -> dao.update(missing));
    }

    @Test
    void deleteOrganizationCascadeRemovesAgents() {
        Og organization = ogDao.create(new Og(
                null,
                "Организация для проверки каскада",
                "Общество с ограниченной ответственностью «Организация для проверки каскада»",
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                "og"
        ));
        OgAg agent = dao.create(new OgAg(null, "950", organization.ogKey(), null));

        boolean deleted = ogDao.deleteById(organization.ogKey());

        assertTrue(deleted, "Организация должна удалиться");
        assertTrue(dao.findById(agent.ogAgKey()).isEmpty(), "Агент должен удалиться каскадно");
    }
}
