package com.femsq.database.auth;

import com.femsq.database.config.DatabaseConfigurationService.DatabaseConfigurationProperties;
import java.util.Objects;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Authentication provider for Kerberos-based trusted connections.
 */
public class KerberosAuthenticationProvider implements AuthenticationProvider {

    private static final Logger log = Logger.getLogger(KerberosAuthenticationProvider.class.getName());

    @Override
    public Properties buildProperties(DatabaseConfigurationProperties configuration) {
        Objects.requireNonNull(configuration, "configuration");
        Properties properties = new Properties();
        properties.setProperty("integratedSecurity", "true");
        properties.setProperty("authenticationScheme", "JavaKerberos");
        log.log(Level.FINE, "Prepared kerberos authentication properties");
        return properties;
    }

    @Override
    public String getName() {
        return "kerberos";
    }
}
