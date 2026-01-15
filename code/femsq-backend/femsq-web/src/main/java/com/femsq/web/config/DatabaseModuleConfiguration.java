package com.femsq.web.config;

import com.femsq.database.auth.AuthenticationProviderFactory;
import com.femsq.database.config.ConfigurationFileManager;
import com.femsq.database.config.ConfigurationValidator;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.connection.ConnectionManager;
import com.femsq.database.dao.IpgChainDao;
import com.femsq.database.dao.IpgChainRelationDao;
import com.femsq.database.dao.InvestmentPlanGroupDao;
import com.femsq.database.dao.InvestmentProgramDao;
import com.femsq.database.dao.JdbcIpgChainDao;
import com.femsq.database.dao.JdbcIpgChainRelationDao;
import com.femsq.database.dao.JdbcInvestmentPlanGroupDao;
import com.femsq.database.dao.JdbcInvestmentProgramDao;
import com.femsq.database.dao.JdbcOgAgDao;
import com.femsq.database.dao.JdbcOgDao;
import com.femsq.database.dao.JdbcRaADao;
import com.femsq.database.dao.JdbcRaAtDao;
import com.femsq.database.dao.JdbcRaDirDao;
import com.femsq.database.dao.JdbcStNetworkDao;
import com.femsq.database.dao.OgAgDao;
import com.femsq.database.dao.OgDao;
import com.femsq.database.dao.RaADao;
import com.femsq.database.dao.RaAtDao;
import com.femsq.database.dao.RaDirDao;
import com.femsq.database.dao.StNetworkDao;
import com.femsq.database.service.DefaultIpgChainRelationService;
import com.femsq.database.service.DefaultIpgChainService;
import com.femsq.database.service.DefaultInvestmentPlanGroupService;
import com.femsq.database.service.DefaultInvestmentProgramService;
import com.femsq.database.service.DefaultOgAgService;
import com.femsq.database.service.DefaultOgService;
import com.femsq.database.service.DefaultRaAService;
import com.femsq.database.service.DefaultRaAtService;
import com.femsq.database.service.DefaultRaDirService;
import com.femsq.database.service.DefaultStNetworkService;
import com.femsq.database.service.IpgChainRelationService;
import com.femsq.database.service.IpgChainService;
import com.femsq.database.service.InvestmentPlanGroupService;
import com.femsq.database.service.InvestmentProgramService;
import com.femsq.database.service.OgAgService;
import com.femsq.database.service.OgService;
import com.femsq.database.service.RaAService;
import com.femsq.database.service.RaAtService;
import com.femsq.database.service.RaDirService;
import com.femsq.database.service.StNetworkService;
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
     * Создает фабрику провайдеров аутентификации.
     *
     * @return фабрика провайдеров аутентификации
     */
    @Bean
    public AuthenticationProviderFactory authenticationProviderFactory() {
        return AuthenticationProviderFactory.withDefaults();
    }

    /**
     * Создает фабрику JDBC-подключений. Bean закрывается при остановке контекста.
     *
     * @param configurationService сервис конфигурации базы данных
     * @param providerFactory       фабрика провайдеров аутентификации
     * @return фабрика подключений
     */
    @Bean(destroyMethod = "close")
    public ConnectionFactory connectionFactory(
            DatabaseConfigurationService configurationService,
            AuthenticationProviderFactory providerFactory) {
        return new ConnectionFactory(configurationService, providerFactory);
    }

    /**
     * Создает менеджер подключений для динамического переподключения.
     *
     * @param connectionFactory       фабрика подключений
     * @param configurationService    сервис конфигурации
     * @param configurationValidator  валидатор конфигурации
     * @param providerFactory         фабрика провайдеров аутентификации
     * @return менеджер подключений
     */
    @Bean
    public ConnectionManager connectionManager(
            ConnectionFactory connectionFactory,
            DatabaseConfigurationService configurationService,
            ConfigurationValidator configurationValidator,
            AuthenticationProviderFactory providerFactory) {
        return new ConnectionManager(
                connectionFactory,
                configurationService,
                configurationValidator,
                providerFactory);
    }

    /**
     * Регистрирует DAO для таблицы {@code og} (схема определяется из конфигурации).
     *
     * @param connectionFactory       фабрика подключений
     * @param configurationService    сервис конфигурации для получения схемы
     * @return реализация {@link OgDao}
     */
    @Bean
    public OgDao ogDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        return new JdbcOgDao(connectionFactory, configurationService);
    }

    /**
     * Регистрирует DAO для таблицы {@code ogAg} (схема определяется из конфигурации).
     *
     * @param connectionFactory       фабрика подключений
     * @param configurationService    сервис конфигурации для получения схемы
     * @return реализация {@link OgAgDao}
     */
    @Bean
    public OgAgDao ogAgDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        return new JdbcOgAgDao(connectionFactory, configurationService);
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

    @Bean
    public IpgChainDao ipgChainDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        return new JdbcIpgChainDao(connectionFactory, configurationService);
    }

    @Bean
    public IpgChainRelationDao ipgChainRelationDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        return new JdbcIpgChainRelationDao(connectionFactory, configurationService);
    }

    @Bean
    public StNetworkDao stNetworkDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        return new JdbcStNetworkDao(connectionFactory, configurationService);
    }

    @Bean
    public InvestmentProgramDao investmentProgramDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        return new JdbcInvestmentProgramDao(connectionFactory, configurationService);
    }

    @Bean
    public InvestmentPlanGroupDao investmentPlanGroupDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        return new JdbcInvestmentPlanGroupDao(connectionFactory, configurationService);
    }

    @Bean
    public IpgChainService ipgChainService(IpgChainDao ipgChainDao) {
        return new DefaultIpgChainService(ipgChainDao);
    }

    @Bean
    public IpgChainRelationService ipgChainRelationService(IpgChainRelationDao ipgChainRelationDao) {
        return new DefaultIpgChainRelationService(ipgChainRelationDao);
    }

    @Bean
    public StNetworkService stNetworkService(StNetworkDao stNetworkDao) {
        return new DefaultStNetworkService(stNetworkDao);
    }

    @Bean
    public InvestmentProgramService investmentProgramService(InvestmentProgramDao investmentProgramDao) {
        return new DefaultInvestmentProgramService(investmentProgramDao);
    }

    @Bean
    public InvestmentPlanGroupService investmentPlanGroupService(InvestmentPlanGroupDao investmentPlanGroupDao) {
        return new DefaultInvestmentPlanGroupService(investmentPlanGroupDao);
    }

    @Bean
    public RaAtDao raAtDao(ConnectionFactory connectionFactory) {
        return new JdbcRaAtDao(connectionFactory);
    }

    @Bean
    public RaDirDao raDirDao(ConnectionFactory connectionFactory) {
        return new JdbcRaDirDao(connectionFactory);
    }

    @Bean
    public RaADao raADao(ConnectionFactory connectionFactory) {
        return new JdbcRaADao(connectionFactory);
    }

    @Bean
    public RaAtService raAtService(RaAtDao raAtDao) {
        return new DefaultRaAtService(raAtDao);
    }

    @Bean
    public RaDirService raDirService(RaDirDao raDirDao) {
        return new DefaultRaDirService(raDirDao);
    }

    @Bean
    public RaAService raAService(RaADao raADao) {
        return new DefaultRaAService(raADao);
    }
}
