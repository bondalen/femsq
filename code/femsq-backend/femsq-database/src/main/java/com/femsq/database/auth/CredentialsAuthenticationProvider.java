package com.femsq.database.auth;

import com.femsq.database.config.DatabaseConfigurationService.DatabaseConfigurationProperties;
import java.util.Objects;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Authentication provider that uses explicit username/password credentials.
 */
public class CredentialsAuthenticationProvider implements AuthenticationProvider {

    private static final Logger log = Logger.getLogger(CredentialsAuthenticationProvider.class.getName());

    @Override
    public Properties buildProperties(DatabaseConfigurationProperties configuration) {
        Objects.requireNonNull(configuration, "configuration");

        Properties properties = new Properties();
        if (configuration.username() == null || configuration.username().isBlank()) {
            throw new IllegalArgumentException("Для credentials аутентификации требуется username");
        }
        if (configuration.password() == null) {
            throw new IllegalArgumentException("Для credentials аутентификации требуется password");
        }
        properties.setProperty("user", configuration.username());
        properties.setProperty("password", configuration.password());
        log.log(Level.FINE, "Prepared credentials authentication properties for user {0}", configuration.username());
        return properties;
    }

    @Override
    public String getName() {
        return "credentials";
    }
}
