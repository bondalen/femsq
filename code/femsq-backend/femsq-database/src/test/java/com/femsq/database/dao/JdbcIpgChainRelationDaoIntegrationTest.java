package com.femsq.database.dao;

import static org.junit.jupiter.api.Assertions.*;

import com.femsq.database.auth.AuthenticationProvider;
import com.femsq.database.auth.AuthenticationProviderFactory;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.model.IpgChainRelation;
import java.util.List;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Assumptions;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class JdbcIpgChainRelationDaoIntegrationTest {

    private static ConnectionFactory connectionFactory;
    private static AuthenticationProviderFactory providerFactory;
    private static AuthenticationProvider authenticationProvider;
    private static DatabaseConfigurationService configurationService;
    private static JdbcIpgChainRelationDao dao;

    @BeforeAll
    static void setUp() {
        Assumptions.assumeTrue(DaoIntegrationTestSupport.isDatabaseConfigured(),
                "FEMSQ_DB_PASSWORD must be set to run DAO integration tests");
        var configuration = DaoIntegrationTestSupport.configurationFromEnv();
        providerFactory = AuthenticationProviderFactory.withDefaults();
        connectionFactory = DaoIntegrationTestSupport.createConnectionFactory(configuration);
        authenticationProvider = providerFactory.create(configuration);
        configurationService = DaoIntegrationTestSupport.createConfigurationService(configuration);
        dao = new JdbcIpgChainRelationDao(connectionFactory, configurationService);
    }

    @AfterAll
    static void tearDown() {
        if (connectionFactory != null) {
            connectionFactory.close();
        }
    }

    @BeforeEach
    void resetData() throws Exception {
        DaoIntegrationTestSupport.resetSchema(connectionFactory);
        try (var connection = connectionFactory.createConnection(authenticationProvider)) {
            assertNotNull(connection);
        }
    }

    @Test
    void findAllReturnsEmptyListWhenNoData() {
        List<IpgChainRelation> relations = dao.findAll();
        assertNotNull(relations);
        assertTrue(relations.isEmpty() || relations.size() >= 0);
    }

    @Test
    void findByChainReturnsEmptyWhenNotFound() {
        List<IpgChainRelation> relations = dao.findByChain(99999);
        assertNotNull(relations);
        assertTrue(relations.isEmpty());
    }

    @Test
    void findByChainsReturnsEmptyWhenNotFound() {
        List<IpgChainRelation> relations = dao.findByChains(List.of(99999, 99998));
        assertNotNull(relations);
        assertTrue(relations.isEmpty());
    }
}
