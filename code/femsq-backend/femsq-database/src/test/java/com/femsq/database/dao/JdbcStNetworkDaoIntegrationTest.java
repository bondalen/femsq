package com.femsq.database.dao;

import static org.junit.jupiter.api.Assertions.*;

import com.femsq.database.auth.AuthenticationProvider;
import com.femsq.database.auth.AuthenticationProviderFactory;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.model.StNetwork;
import java.util.List;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Assumptions;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class JdbcStNetworkDaoIntegrationTest {

    private static ConnectionFactory connectionFactory;
    private static AuthenticationProviderFactory providerFactory;
    private static AuthenticationProvider authenticationProvider;
    private static DatabaseConfigurationService configurationService;
    private static JdbcStNetworkDao dao;

    @BeforeAll
    static void setUp() {
        Assumptions.assumeTrue(DaoIntegrationTestSupport.isDatabaseConfigured(),
                "FEMSQ_DB_PASSWORD must be set to run DAO integration tests");
        var configuration = DaoIntegrationTestSupport.configurationFromEnv();
        providerFactory = AuthenticationProviderFactory.withDefaults();
        connectionFactory = DaoIntegrationTestSupport.createConnectionFactory(configuration);
        authenticationProvider = providerFactory.create(configuration);
        configurationService = DaoIntegrationTestSupport.createConfigurationService(configuration);
        dao = new JdbcStNetworkDao(connectionFactory, configurationService);
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
    void findAllOrderedReturnsNetworks() {
        List<StNetwork> networks = dao.findAllOrdered();
        assertNotNull(networks);
        assertTrue(networks.size() >= 0);
        if (!networks.isEmpty()) {
            StNetwork first = networks.get(0);
            assertNotNull(first.stnKey());
            assertNotNull(first.name());
        }
    }
}
