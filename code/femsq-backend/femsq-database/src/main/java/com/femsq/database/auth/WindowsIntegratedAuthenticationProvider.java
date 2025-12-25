package com.femsq.database.auth;

import com.femsq.database.config.DatabaseConfigurationService.DatabaseConfigurationProperties;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.Principal;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.security.auth.Subject;
import javax.security.auth.kerberos.KerberosPrincipal;
import javax.security.auth.login.LoginContext;

/**
 * Authentication provider for Windows integrated security.
 * 
 * <p><b>Кросс-платформенный подход (2025-11-19):</b>
 * <ul>
 *   <li><b>На Windows:</b> Использует Windows SSPI (автоматический выбор Kerberos/NTLM)</li>
 *   <li><b>На Linux:</b> Использует JavaKerberos с JAAS конфигурацией</li>
 * </ul>
 * 
 * <p><b>Преимущества Windows SSPI:</b>
 * <ul>
 *   <li>Не требует native DLL и её зависимостей (Visual C++ Runtime)</li>
 *   <li>Работает "из коробки" на машинах в домене Windows</li>
 *   <li>Драйвер автоматически выбирает лучший метод (Kerberos если доступен, иначе NTLM)</li>
 *   <li>Не требует установки дополнительного ПО на клиентской машине</li>
 *   <li>Самый надёжный метод для Windows в корпоративной среде</li>
 * </ul>
 * 
 * <p><b>Требования:</b>
 * <ul>
 *   <li>Компьютер присоединен к домену Windows/Linux с Kerberos</li>
 *   <li>Пользователь аутентифицирован в домене</li>
 *   <li>SQL Server настроен для Windows Authentication</li>
 * </ul>
 * 
 * <p>Если Windows Authentication недоступна, используйте режим "credentials" 
 * с явным указанием имени пользователя и пароля.
 */
public class WindowsIntegratedAuthenticationProvider implements AuthenticationProvider {

    private static final Logger log = Logger.getLogger(WindowsIntegratedAuthenticationProvider.class.getName());
    private static volatile boolean kerberosConfigured = false;

    @Override
    public Properties buildProperties(DatabaseConfigurationProperties configuration) {
        Objects.requireNonNull(configuration, "configuration");
        Properties properties = new Properties();
        
        String osName = System.getProperty("os.name", "").toLowerCase(Locale.ROOT);
        boolean isWindows = osName.contains("windows");
        
        if (isWindows) {
            // WINDOWS: Используем Windows SSPI (Kerberos/NTLM auto-select)
            // Драйвер автоматически выберет лучший метод аутентификации
            properties.setProperty("integratedSecurity", "true");
            
            log.log(Level.INFO, "Using Windows SSPI for integrated authentication (Kerberos/NTLM auto-select)");
            log.log(Level.INFO, "Authentication will use current Windows user credentials automatically");
            
        } else {
            // LINUX/UNIX: Используем JavaKerberos с JAAS
            // Настраиваем JAAS конфигурацию один раз
            if (!kerberosConfigured) {
                synchronized (WindowsIntegratedAuthenticationProvider.class) {
                    if (!kerberosConfigured) {
                        // Передаем realm из конфигурации (может быть null)
                        String realm = configuration.realm();
                        KerberosConfiguration.configureKerberosSSO(realm, osName);
                        kerberosConfigured = true;
                    }
                }
            }
            
            // Как в DBeaver: используем оба флага одновременно!
            properties.setProperty("integratedSecurity", "true");
            properties.setProperty("authenticationScheme", "JavaKerberos");
            properties.setProperty("jaasConfigurationName", "SQLJDBCDriver");
            
            // АВТОМАТИЧЕСКОЕ определение Kerberos principal (SSO!)
            log.log(Level.INFO, "Auto-detecting Kerberos principal for SSO...");
            String principal = detectKerberosPrincipal();
            
            if (principal != null && !principal.isEmpty()) {
                properties.setProperty("user", principal);
                log.log(Level.INFO, "✅ Auto-detected Kerberos principal: {0}", principal);
                log.log(Level.INFO, "Using JavaKerberos SSO on {0} with principal: {1}", new Object[]{osName, principal});
            } else {
                log.log(Level.WARNING, "⚠️ Could not auto-detect Kerberos principal!");
                log.log(Level.WARNING, "Make sure you are logged in to the domain and have a valid Kerberos ticket");
                log.log(Level.WARNING, "Connection may fail without valid credentials");
            }
            
            log.log(Level.INFO, "Authentication will use Kerberos ticket from system cache");
        }
        
        return properties;
    }

    @Override
    public String getName() {
        return "windows-integrated";
    }
    
    /**
     * Автоматическое определение Kerberos principal из ticket cache.
     * 
     * <p>Стратегия определения (в порядке приоритета):
     * <ol>
     *   <li>Извлечение из Kerberos ticket cache через JAAS LoginContext</li>
     *   <li>Fallback: system user + realm из /etc/krb5.conf</li>
     *   <li>Fallback: переменная окружения KRB5PRINCIPAL</li>
     * </ol>
     * 
     * @return Kerberos principal в формате "user@REALM" или null если не удалось определить
     */
    private static String detectKerberosPrincipal() {
        // Стратегия 1: Извлечь из ticket cache через JAAS
        try {
            log.log(Level.INFO, "Attempting to extract principal from Kerberos ticket cache via JAAS...");
            Subject subject = new Subject();
            LoginContext loginContext = new LoginContext("SQLJDBCDriver", subject);
            loginContext.login();
            
            // Извлекаем KerberosPrincipal из Subject
            for (Principal principal : subject.getPrincipals()) {
                if (principal instanceof KerberosPrincipal) {
                    String principalName = principal.getName();
                    log.log(Level.INFO, "✅ Successfully extracted principal from ticket cache: {0}", principalName);
                    return principalName;
                }
            }
            
            log.log(Level.INFO, "No KerberosPrincipal found in Subject, trying fallback methods...");
        } catch (Exception e) {
            log.log(Level.INFO, "Could not extract principal via JAAS (ticket may not exist yet): {0}", e.getMessage());
        }
        
        // Стратегия 2: Fallback - system user + realm из krb5.conf
        try {
            log.log(Level.INFO, "Attempting fallback: system user + realm from krb5.conf...");
            String systemUser = System.getProperty("user.name");
            String realm = extractRealmFromKrb5Conf();
            
            if (systemUser != null && !systemUser.isEmpty() && realm != null && !realm.isEmpty()) {
                String principal = systemUser + "@" + realm;
                log.log(Level.INFO, "✅ Constructed principal from system user + krb5.conf: {0}", principal);
                return principal;
            } else {
                log.log(Level.INFO, "Cannot construct principal: systemUser={0}, realm={1}", 
                    new Object[]{systemUser, realm});
            }
        } catch (Exception e) {
            log.log(Level.WARNING, "Fallback method failed: {0}", e.getMessage());
        }
        
        // Стратегия 3: Переменная окружения KRB5PRINCIPAL
        try {
            String envPrincipal = System.getenv("KRB5PRINCIPAL");
            if (envPrincipal != null && !envPrincipal.isEmpty()) {
                log.log(Level.INFO, "✅ Found principal in KRB5PRINCIPAL env var: {0}", envPrincipal);
                return envPrincipal;
            }
        } catch (Exception e) {
            log.log(Level.WARNING, "Could not read KRB5PRINCIPAL env var: {0}", e.getMessage());
        }
        
        log.log(Level.WARNING, "All strategies failed to detect Kerberos principal");
        return null;
    }
    
    /**
     * Извлечение default_realm из /etc/krb5.conf.
     * 
     * @return Realm в верхнем регистре или null если не найден
     */
    private static String extractRealmFromKrb5Conf() {
        Path krb5ConfPath = Paths.get("/etc/krb5.conf");
        
        if (!Files.exists(krb5ConfPath)) {
            log.log(Level.INFO, "krb5.conf not found at /etc/krb5.conf");
            return null;
        }
        
        try {
            List<String> lines = Files.readAllLines(krb5ConfPath);
            boolean inLibdefaults = false;
            
            for (String line : lines) {
                String trimmed = line.trim();
                
                // Начало секции [libdefaults]
                if (trimmed.equals("[libdefaults]")) {
                    inLibdefaults = true;
                    continue;
                }
                
                // Конец секции [libdefaults] (начало другой секции)
                if (inLibdefaults && trimmed.startsWith("[")) {
                    inLibdefaults = false;
                    continue;
                }
                
                // Поиск default_realm в секции [libdefaults]
                if (inLibdefaults && trimmed.startsWith("default_realm")) {
                    String[] parts = trimmed.split("=", 2);
                    if (parts.length == 2) {
                        String realm = parts[1].trim().toUpperCase(Locale.ROOT);
                        log.log(Level.INFO, "Found default_realm in krb5.conf: {0}", realm);
                        return realm;
                    }
                }
            }
            
            log.log(Level.INFO, "default_realm not found in krb5.conf");
        } catch (Exception e) {
            log.log(Level.WARNING, "Error reading krb5.conf: {0}", e.getMessage());
        }
        
        return null;
    }
}
