package com.femsq.database.auth;

import static org.junit.jupiter.api.Assertions.*;

import com.femsq.database.config.DatabaseConfigurationService.DatabaseConfigurationProperties;
import java.util.Properties;
import org.junit.jupiter.api.Test;

class AuthenticationProvidersTest {

    private static final DatabaseConfigurationProperties BASE_CONFIG =
            new DatabaseConfigurationProperties("db.local", 1433, "femsq", "alex", "secret");

    @Test
    void credentialsProviderAddsUserAndPassword() {
        AuthenticationProvider provider = new CredentialsAuthenticationProvider();
        Properties properties = provider.buildProperties(BASE_CONFIG);
        assertEquals("alex", properties.getProperty("user"));
        assertEquals("secret", properties.getProperty("password"));
    }

    @Test
    void credentialsProviderRejectsMissingUsername() {
        AuthenticationProvider provider = new CredentialsAuthenticationProvider();
        DatabaseConfigurationProperties invalid = new DatabaseConfigurationProperties("db.local", 1433, "femsq", null, "secret");
        assertThrows(IllegalArgumentException.class, () -> provider.buildProperties(invalid));
    }

    @Test
    void integratedSecurityProviderSetsFlag() {
        AuthenticationProvider provider = new IntegratedSecurityAuthenticationProvider();
        Properties properties = provider.buildProperties(BASE_CONFIG);
        assertEquals("true", properties.getProperty("integratedSecurity"));
    }

    @Test
    void trustedConnectionProviderSetsKerberos() {
        AuthenticationProvider provider = new TrustedConnectionAuthenticationProvider();
        Properties properties = provider.buildProperties(BASE_CONFIG);
        assertEquals("true", properties.getProperty("integratedSecurity"));
        assertEquals("JavaKerberos", properties.getProperty("authenticationScheme"));
    }
}
