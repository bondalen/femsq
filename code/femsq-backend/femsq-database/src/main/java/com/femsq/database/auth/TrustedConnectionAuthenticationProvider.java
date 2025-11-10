package com.femsq.database.auth;

import com.femsq.database.config.DatabaseConfigurationService.DatabaseConfigurationProperties;
import java.util.Objects;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Authentication provider that uses trusted connection (Kerberos/SSO) settings.
 */
public class TrustedConnectionAuthenticationProvider implements AuthenticationProvider {

    private static final Logger log = Logger.getLogger(TrustedConnectionAuthenticationProvider.class.getName());

    @Override
    public Properties buildProperties(DatabaseConfigurationProperties configuration) {
        Objects.requireNonNull(configuration, "configuration");
        Properties properties = new Properties();
        properties.setProperty("authenticationScheme", "JavaKerberos");
        properties.setProperty("integratedSecurity", "true");
        log.log(Level.FINE, "Prepared trusted connection authentication properties");
        return properties;
    }

    @Override
    public String getName() {
        return "trusted-connection";
    }
}
