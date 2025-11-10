package com.femsq.database.auth;

import com.femsq.database.config.DatabaseConfigurationService.DatabaseConfigurationProperties;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;

/**
 * Factory responsible for creating {@link AuthenticationProvider} based on configuration.
 */
public class AuthenticationProviderFactory {

    private final Map<String, AuthenticationProvider> providers;

    public AuthenticationProviderFactory(Map<String, AuthenticationProvider> providers) {
        if (!providers.containsKey("credentials")) {
            throw new IllegalArgumentException("Factory must contain credentials provider");
        }
        this.providers = Map.copyOf(providers);
    }

    public static AuthenticationProviderFactory withDefaults() {
        return new AuthenticationProviderFactory(Map.of(
                "credentials", new CredentialsAuthenticationProvider(),
                "windows-integrated", new WindowsIntegratedAuthenticationProvider(),
                "kerberos", new KerberosAuthenticationProvider()));
    }

    public AuthenticationProvider create(DatabaseConfigurationProperties configuration) {
        Objects.requireNonNull(configuration, "configuration");
        String authMode = normalize(configuration.authMode());
        AuthenticationProvider provider = providers.get(authMode);
        if (provider == null) {
            throw new IllegalArgumentException("Неизвестный режим аутентификации: " + configuration.authMode());
        }
        return provider;
    }

    private String normalize(String authMode) {
        if (authMode == null || authMode.isBlank()) {
            return "credentials";
        }
        return authMode.trim().toLowerCase(Locale.ROOT);
    }
}
