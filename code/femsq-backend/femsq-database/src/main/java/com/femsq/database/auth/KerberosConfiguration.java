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
 * <p><b>Платформо-зависимая настройка:</b>
 * <ul>
 *   <li><b>Windows:</b> Использует native SSPI через JNI (sun.security.jgss.native=true)</li>
 *   <li><b>Linux/Unix:</b> Использует JAAS конфигурацию из файла (указанного в -Djava.security.auth.login.config)</li>
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
     * Активирует Kerberos SSO конфигурацию с учётом операционной системы.
     * 
     * <p><b>Windows:</b> Использует native GSS-API через JNI для доступа к Kerberos tickets
     * из Windows LSA (Local Security Authority).
     * 
     * <p><b>Linux/Unix:</b> Полагается на JAAS конфигурацию из файла, указанного в JVM параметре
     * -Djava.security.auth.login.config=/path/to/jaas.conf
     * 
     * <p>Метод безопасен для многократного вызова.
     * 
     * @param realm Kerberos realm (например, ADM.GAZPROM.RU)
     * @param osName Имя операционной системы из System.getProperty("os.name")
     */
    public static void configureKerberosSSO(String realm, String osName) {
        if (configured) {
            return;
        }
        
        synchronized (KerberosConfiguration.class) {
            if (!configured) {
                try {
                    // Логируем все критические параметры
                    log.log(Level.INFO, "=== Kerberos Configuration ===");
                    log.log(Level.INFO, "Operating System: {0}", osName);
                    log.log(Level.INFO, "Kerberos Realm: {0}", realm != null ? realm : "<not specified>");
                    log.log(Level.INFO, "JAAS config file: {0}", System.getProperty("java.security.auth.login.config"));
                    log.log(Level.INFO, "Kerberos config: {0}", System.getProperty("java.security.krb5.conf"));
                    log.log(Level.INFO, "KRB5CCNAME env: {0}", System.getenv("KRB5CCNAME"));
                    log.log(Level.INFO, "Current user: {0}", System.getProperty("user.name"));
                    
                    if (osName != null && osName.toLowerCase().startsWith("windows")) {
                        // ============================================
                        // WINDOWS: Использовать native SSPI через JNI
                        // ============================================
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
                        
                        log.log(Level.INFO, "Configured Kerberos SSO for WINDOWS with native SSPI");
                    } else {
                        // ============================================
                        // LINUX/UNIX: Использовать JAAS из файла
                        // ============================================
                        // НЕ устанавливаем sun.security.jgss.native=true!
                        // Полагаемся на JAAS конфигурацию из файла, указанного в:
                        // -Djava.security.auth.login.config=/path/to/jaas-femsq.conf
                        
                        // Разрешить использовать системные credentials
                        System.setProperty("javax.security.auth.useSubjectCredsOnly", "false");
                        log.log(Level.INFO, "Set javax.security.auth.useSubjectCredsOnly=false");
                        
                        // Устанавливаем realm если предоставлен
                        if (realm != null && !realm.isEmpty()) {
                            System.setProperty("java.security.krb5.realm", realm);
                            log.log(Level.INFO, "Set java.security.krb5.realm={0}", realm);
                        }
                        
                        // Включаем debug если указано
                        if ("true".equalsIgnoreCase(System.getProperty("sun.security.krb5.debug"))) {
                            System.setProperty("sun.security.jgss.debug", "true");
                            log.log(Level.INFO, "Kerberos debug mode enabled (sun.security.krb5.debug=true)");
                        }
                        
                        log.log(Level.INFO, "Configured Kerberos SSO for LINUX/UNIX with JAAS configuration from file");
                    }
                    
                    log.log(Level.INFO, "==============================");
                    
                    instance = new KerberosConfiguration();
                    Configuration.setConfiguration(instance);
                    configured = true;
                    
                } catch (Exception e) {
                    log.log(Level.WARNING, "Failed to configure Kerberos SSO", e);
                }
            }
        }
    }
    
    /**
     * Активирует Kerberos SSO без явного realm.
     * Realm будет определён автоматически из системы.
     * 
     * @param osName Имя операционной системы
     */
    public static void configureKerberosSSO(String osName) {
        configureKerberosSSO(null, osName);
    }

    @Override
    public AppConfigurationEntry[] getAppConfigurationEntry(String name) {
        // Конфигурация для SQL Server JDBC Driver
        // Эта конфигурация используется только если драйвер читает JAAS из кода
        // На Linux драйвер обычно читает из файла (-Djava.security.auth.login.config)
        Map<String, Object> options = new HashMap<>();
        
        // Использовать системный Kerberos ticket cache (не запрашивать пароль)
        options.put("useTicketCache", "true");
        options.put("doNotPrompt", "true");
        options.put("refreshKrb5Config", "true");
        
        // Попытка получить explicit principal для Linux
        // Формат: username@DOMAIN.COM (DOMAIN должен быть в верхнем регистре)
        String userName = System.getProperty("user.name");
        String configuredRealm = System.getProperty("java.security.krb5.realm"); // Realm из конфигурации
        
        if (userName != null && configuredRealm != null && !userName.isEmpty() && !configuredRealm.isEmpty()) {
            String principal = userName + "@" + configuredRealm.toUpperCase(Locale.ROOT);
            options.put("principal", principal);
            log.log(Level.INFO, "Using explicit Kerberos principal in JAAS: {0}", principal);
        } else {
            log.log(Level.INFO, "Principal not specified explicitly in JAAS, will use ticket cache default");
            if (userName != null) {
                log.log(Level.FINE, "User: {0}, Configured Realm: {1}", new Object[]{userName, configuredRealm});
            }
        }
        
        // Отладка Kerberos (контролируется через system property)
        // Запуск с: -Dsun.security.krb5.debug=true
        String debugProp = System.getProperty("sun.security.krb5.debug");
        if ("true".equalsIgnoreCase(debugProp)) {
            options.put("debug", "true");
            log.log(Level.INFO, "Kerberos debug mode enabled in JAAS options");
        }
        
        AppConfigurationEntry entry = new AppConfigurationEntry(
                KRB5_LOGIN_MODULE,
                AppConfigurationEntry.LoginModuleControlFlag.REQUIRED,
                options
        );
        
        return new AppConfigurationEntry[] { entry };
    }
}
