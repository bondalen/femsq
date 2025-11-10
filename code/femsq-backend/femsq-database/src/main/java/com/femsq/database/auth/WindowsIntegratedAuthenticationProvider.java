package com.femsq.database.auth;

import com.femsq.database.config.DatabaseConfigurationService.DatabaseConfigurationProperties;
import java.util.Objects;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Authentication provider for Windows integrated security.
 */
public class WindowsIntegratedAuthenticationProvider implements AuthenticationProvider {

    private static final Logger log = Logger.getLogger(WindowsIntegratedAuthenticationProvider.class.getName());

    @Override
    public Properties buildProperties(DatabaseConfigurationProperties configuration) {
        Objects.requireNonNull(configuration, "configuration");
        Properties properties = new Properties();
        properties.setProperty("integratedSecurity", "true");
        log.log(Level.FINE, "Prepared windows integrated authentication properties");
        return properties;
    }

    @Override
    public String getName() {
        return "windows-integrated";
    }
}
