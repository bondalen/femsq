package com.femsq.database.auth;

import com.femsq.database.config.DatabaseConfigurationService.DatabaseConfigurationProperties;
import java.util.Locale;
import java.util.Objects;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

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
                        KerberosConfiguration.configureKerberosSSO();
                        kerberosConfigured = true;
                    }
                }
            }
            
            properties.setProperty("authenticationScheme", "JavaKerberos");
            
            // Для JavaKerberos ОБЯЗАТЕЛЬНО указать имя пользователя
            String currentUser = System.getProperty("user.name");
            if (currentUser != null && !currentUser.isEmpty()) {
                properties.setProperty("user", currentUser);
                log.log(Level.INFO, "Using JavaKerberos for integrated authentication on {0} as user: {1}", 
                        new Object[]{osName, currentUser});
                log.log(Level.INFO, "Authentication will use Kerberos ticket from system cache");
            } else {
                log.log(Level.WARNING, "Cannot determine current user name for Kerberos authentication on {0}", osName);
            }
        }
        
        return properties;
    }

    @Override
    public String getName() {
        return "windows-integrated";
    }
}
