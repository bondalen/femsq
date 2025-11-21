package com.femsq.database.dao;

import static org.junit.jupiter.api.Assertions.*;

import com.femsq.database.auth.AuthenticationProvider;
import com.femsq.database.auth.AuthenticationProviderFactory;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.model.InvestmentProgram;
import java.util.List;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Assumptions;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class JdbcInvestmentProgramDaoIntegrationTest {

    private static ConnectionFactory connectionFactory;
    private static AuthenticationProviderFactory providerFactory;
    private static AuthenticationProvider authenticationProvider;
    private static DatabaseConfigurationService configurationService;
    private static JdbcInvestmentProgramDao dao;

    @BeforeAll
    static void setUp() {
        Assumptions.assumeTrue(DaoIntegrationTestSupport.isDatabaseConfigured(),
                "FEMSQ_DB_PASSWORD must be set to run DAO integration tests");
        var configuration = DaoIntegrationTestSupport.configurationFromEnv();
        providerFactory = AuthenticationProviderFactory.withDefaults();
        connectionFactory = DaoIntegrationTestSupport.createConnectionFactory(configuration);
        authenticationProvider = providerFactory.create(configuration);
        configurationService = DaoIntegrationTestSupport.createConfigurationService(configuration);
        dao = new JdbcInvestmentProgramDao(connectionFactory, configurationService);
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
    void findAllWithDisplayNameReturnsPrograms() {
        List<InvestmentProgram> programs = dao.findAllWithDisplayName();
        assertNotNull(programs);
        assertTrue(programs.size() >= 0);
        if (!programs.isEmpty()) {
            InvestmentProgram first = programs.get(0);
            assertNotNull(first.ipgKey());
            assertNotNull(first.displayName());
            assertFalse(first.displayName().isEmpty());
        }
    }
}
