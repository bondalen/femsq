package com.femsq.database.auth;

import static org.junit.jupiter.api.Assertions.*;

import com.femsq.database.config.DatabaseConfigurationService.DatabaseConfigurationProperties;
import java.util.Properties;
import org.junit.jupiter.api.Test;

class AuthenticationProvidersTest {

    private static final DatabaseConfigurationProperties BASE_CONFIG =
            new DatabaseConfigurationProperties("db.local", 1433, "femsq", null, "alex", "secret", "credentials");

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
        DatabaseConfigurationProperties invalid = new DatabaseConfigurationProperties("db.local", 1433, "femsq", null, null, "secret", "credentials");
        assertThrows(IllegalArgumentException.class, () -> provider.buildProperties(invalid));
    }

    @Test
    void windowsIntegratedProviderSetsFlag() {
        AuthenticationProvider provider = new WindowsIntegratedAuthenticationProvider();
        DatabaseConfigurationProperties config = new DatabaseConfigurationProperties("db.local", 1433, "femsq", null, null, null, "windows-integrated");
        Properties properties = provider.buildProperties(config);
        assertEquals("true", properties.getProperty("integratedSecurity"));
        // На Windows может использоваться либо NTLM (без authenticationScheme), либо JavaKerberos
        // На Linux всегда используется JavaKerberos
        // Проверяем, что хотя бы один из вариантов установлен
        String authScheme = properties.getProperty("authenticationScheme");
        if (authScheme != null) {
            assertEquals("JavaKerberos", authScheme);
        }
        // Если authenticationScheme отсутствует, значит используется NTLM через нативную DLL (только на Windows)
    }

    @Test
    void kerberosProviderSetsScheme() {
        AuthenticationProvider provider = new KerberosAuthenticationProvider();
        DatabaseConfigurationProperties config = new DatabaseConfigurationProperties("db.local", 1433, "femsq", null, null, null, "kerberos");
        Properties properties = provider.buildProperties(config);
        assertEquals("true", properties.getProperty("integratedSecurity"));
        assertEquals("JavaKerberos", properties.getProperty("authenticationScheme"));
    }

    @Test
    void factorySelectsProviderByAuthMode() {
        AuthenticationProviderFactory factory = AuthenticationProviderFactory.withDefaults();
        DatabaseConfigurationProperties kerberosConfig = new DatabaseConfigurationProperties("db.local", 1433, "femsq", null, null, null, "kerberos");
        AuthenticationProvider provider = factory.create(kerberosConfig);
        assertEquals("kerberos", provider.getName());
    }

    @Test
    void factoryThrowsOnUnknownMode() {
        AuthenticationProviderFactory factory = AuthenticationProviderFactory.withDefaults();
        DatabaseConfigurationProperties config = new DatabaseConfigurationProperties("db.local", 1433, "femsq", null, null, null, "unsupported");
        assertThrows(IllegalArgumentException.class, () -> factory.create(config));
    }
}
