package com.femsq.web.config;

import com.femsq.database.config.ConfigurationFileManager;
import com.femsq.database.config.ConfigurationValidator;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.dao.JdbcOgAgDao;
import com.femsq.database.dao.JdbcOgDao;
import com.femsq.database.dao.OgAgDao;
import com.femsq.database.dao.OgDao;
import com.femsq.database.service.DefaultOgAgService;
import com.femsq.database.service.DefaultOgService;
import com.femsq.database.service.OgAgService;
import com.femsq.database.service.OgService;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Конфигурация бинов, связывающая инфраструктурный модуль {@code femsq-database}
 * со Spring-контекстом Web API.
 */
@Configuration
public class DatabaseModuleConfiguration {

    /**
     * Создает менеджер файлов конфигурации.
     *
     * @return экземпляр {@link ConfigurationFileManager}
     */
    @Bean
    public ConfigurationFileManager configurationFileManager() {
        return new ConfigurationFileManager();
    }

    /**
     * Создает валидатор параметров подключения к базе данных.
     *
     * @return экземпляр {@link ConfigurationValidator}
     */
    @Bean
    public ConfigurationValidator configurationValidator() {
        return new ConfigurationValidator();
    }

    /**
     * Создает сервис работы с конфигурацией подключения.
     *
     * @param fileManager менеджер конфигурационного файла
     * @param validator   валидатор параметров
     * @return сервис конфигурации
     */
    @Bean
    public DatabaseConfigurationService databaseConfigurationService(
            ConfigurationFileManager fileManager,
            ConfigurationValidator validator) {
        return new DatabaseConfigurationService(fileManager, validator);
    }

    /**
     * Создает фабрику JDBC-подключений. Bean закрывается при остановке контекста.
     *
     * @param configurationService сервис конфигурации базы данных
     * @return фабрика подключений
     */
    @Bean(destroyMethod = "close")
    public ConnectionFactory connectionFactory(DatabaseConfigurationService configurationService) {
        return new ConnectionFactory(configurationService);
    }

    /**
     * Регистрирует DAO для таблицы {@code ags_test.og}.
     *
     * @param connectionFactory фабрика подключений
     * @return реализация {@link OgDao}
     */
    @Bean
    public OgDao ogDao(ConnectionFactory connectionFactory) {
        return new JdbcOgDao(connectionFactory);
    }

    /**
     * Регистрирует DAO для таблицы {@code ags_test.ogAg}.
     *
     * @param connectionFactory фабрика подключений
     * @return реализация {@link OgAgDao}
     */
    @Bean
    public OgAgDao ogAgDao(ConnectionFactory connectionFactory) {
        return new JdbcOgAgDao(connectionFactory);
    }

    /**
     * Создает сервисный слой организаций.
     *
     * @param ogDao DAO организаций
     * @return сервис организаций
     */
    @Bean
    public OgService ogService(OgDao ogDao) {
        return new DefaultOgService(ogDao);
    }

    /**
     * Создает сервисный слой агентских организаций.
     *
     * @param ogAgDao DAO агентских организаций
     * @param ogDao   DAO базовых организаций для проверок
     * @return сервис агентских организаций
     */
    @Bean
    public OgAgService ogAgService(OgAgDao ogAgDao, OgDao ogDao) {
        return new DefaultOgAgService(ogAgDao, ogDao);
    }
}
