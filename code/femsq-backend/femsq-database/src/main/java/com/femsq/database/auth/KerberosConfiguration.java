package com.femsq.database.auth;

import javax.security.auth.login.AppConfigurationEntry;
import javax.security.auth.login.Configuration;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JAAS конфигурация для Kerberos Single Sign-On.
 * 
 * <p><b>Используется только на Linux/Unix.</b> На Windows используется встроенный SSPI.
 * 
 * <p>Настраивает Kerberos для использования текущих системных credentials
 * без необходимости ввода пароля. Работает на машинах присоединенных к домену.
 * 
 * <p><b>Конфигурация для Linux (готова к использованию):</b>
 * <ul>
 *   <li><b>useTicketCache=true</b> - использовать системный Kerberos ticket cache</li>
 *   <li><b>doNotPrompt=true</b> - не запрашивать пароль</li>
 *   <li><b>principal=user@DOMAIN</b> - явно указывается из переменных окружения (если доступно)</li>
 *   <li><b>refreshKrb5Config=true</b> - перечитывать krb5.conf при необходимости</li>
 * </ul>
 * 
 * <p><b>Отладка:</b> Установите system property <code>sun.security.krb5.debug=true</code>
 * для подробного логирования Kerberos аутентификации.
 */
public class KerberosConfiguration extends Configuration {
    
    private static final Logger log = Logger.getLogger(KerberosConfiguration.class.getName());
    private static final String KRB5_LOGIN_MODULE = "com.sun.security.auth.module.Krb5LoginModule";
    private static volatile KerberosConfiguration instance;
    private static volatile boolean configured = false;

    /**
     * Активирует Kerberos SSO конфигурацию для Windows с native SSPI.
     * 
     * <p>Использует Windows native GSS-API через JNI для доступа к Kerberos tickets
     * из Windows LSA (Local Security Authority) без необходимости в mssql-jdbc_auth.dll.
     * 
     * <p>Метод безопасен для многократного вызова.
     * 
     * @param realm Kerberos realm (например, ADM.GAZPROM.RU)
     */
    public static void configureKerberosSSO(String realm) {
        if (configured) {
            return;
        }
        
        synchronized (KerberosConfiguration.class) {
            if (!configured) {
                try {
                    // КРИТИЧНО: Использовать Windows native SSPI через JNI
                    // Это позволяет Java читать Kerberos tickets из Windows LSA
                    System.setProperty("sun.security.jgss.native", "true");
                    log.log(Level.INFO, "Set sun.security.jgss.native=true for Windows SSPI integration");
                    
                    // Разрешить использовать системные credentials
                    System.setProperty("javax.security.auth.useSubjectCredsOnly", "false");
                    log.log(Level.INFO, "Set javax.security.auth.useSubjectCredsOnly=false");
                    
                    // Устанавливаем realm если предоставлен
                    if (realm != null && !realm.isEmpty()) {
                        System.setProperty("java.security.krb5.realm", realm);
                        log.log(Level.INFO, "Set java.security.krb5.realm={0}", realm);
                    }
                    
                    instance = new KerberosConfiguration();
                    Configuration.setConfiguration(instance);
                    configured = true;
                    log.log(Level.INFO, "Configured Kerberos SSO with Windows native SSPI");
                } catch (Exception e) {
                    log.log(Level.WARNING, "Failed to configure Kerberos SSO", e);
                }
            }
        }
    }
    
    /**
     * Активирует Kerberos SSO без явного realm.
     * Realm будет определён автоматически из системы.
     */
    public static void configureKerberosSSO() {
        configureKerberosSSO(null);
    }

    @Override
    public AppConfigurationEntry[] getAppConfigurationEntry(String name) {
        // Конфигурация для SQL Server JDBC Driver (используется на Linux/Unix)
        Map<String, Object> options = new HashMap<>();
        
        // Использовать системный Kerberos ticket cache (не запрашивать пароль)
        options.put("useTicketCache", "true");
        options.put("doNotPrompt", "true");
        options.put("refreshKrb5Config", "true");
        
        // Попытка получить explicit principal для Linux
        // Формат: username@DOMAIN.COM (DOMAIN должен быть в верхнем регистре)
        String userName = System.getProperty("user.name");
        String domain = System.getenv("USERDNSDOMAIN"); // Windows
        if (domain == null) {
            // Linux: попробовать получить из других переменных
            domain = System.getenv("KRB5REALM");
        }
        
        if (userName != null && domain != null && !userName.isEmpty() && !domain.isEmpty()) {
            String principal = userName + "@" + domain.toUpperCase(Locale.ROOT);
            options.put("principal", principal);
            log.log(Level.INFO, "Using explicit Kerberos principal: {0}", principal);
        } else {
            log.log(Level.INFO, "Principal not specified explicitly, will use ticket cache default");
            if (userName != null) {
                log.log(Level.FINE, "User: {0}, Domain: {1}", new Object[]{userName, domain});
            }
        }
        
        // Отладка Kerberos (контролируется через system property)
        // Запуск с: -Dsun.security.krb5.debug=true
        String debugProp = System.getProperty("sun.security.krb5.debug");
        if ("true".equalsIgnoreCase(debugProp)) {
            options.put("debug", "true");
            log.log(Level.INFO, "Kerberos debug mode enabled");
        }
        
        AppConfigurationEntry entry = new AppConfigurationEntry(
                KRB5_LOGIN_MODULE,
                AppConfigurationEntry.LoginModuleControlFlag.REQUIRED,
                options
        );
        
        return new AppConfigurationEntry[] { entry };
    }
}
