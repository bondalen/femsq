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
import com.femsq.database.dao.CnContractDao;
import com.femsq.database.dao.CnDao;
import com.femsq.database.dao.CnNumDao;
import com.femsq.database.dao.CnSDao;
import com.femsq.database.dao.CnSOrgDao;
import com.femsq.database.dao.CnSOrgSmplDao;
import com.femsq.database.dao.CstAgDao;
import com.femsq.database.dao.CstAgPnBranchDao;
import com.femsq.database.dao.CstAgPnDao;
import com.femsq.database.dao.CstDao;
import com.femsq.database.dao.CstRaListDao;
import com.femsq.database.dao.JdbcCnContractDao;
import com.femsq.database.dao.JdbcCnDao;
import com.femsq.database.dao.JdbcCnNumDao;
import com.femsq.database.dao.JdbcCnSDao;
import com.femsq.database.dao.JdbcCnSOrgDao;
import com.femsq.database.dao.JdbcCnSOrgSmplDao;
import com.femsq.database.dao.JdbcCstAgDao;
import com.femsq.database.dao.JdbcCstAgPnBranchDao;
import com.femsq.database.dao.JdbcCstAgPnDao;
import com.femsq.database.dao.JdbcCstDao;
import com.femsq.database.dao.JdbcCstRaListDao;
import com.femsq.database.dao.JdbcOgAgCsDao;
import com.femsq.database.dao.JdbcRaPeriodDao;
import com.femsq.database.dao.JdbcRaReportDao;
import com.femsq.database.dao.JdbcRaSummDao;
import com.femsq.database.dao.JdbcRalpRaAuDao;
import com.femsq.database.dao.JdbcRalpRaCstListDao;
import com.femsq.database.dao.JdbcRalpRaDao;
import com.femsq.database.dao.RaPeriodDao;
import com.femsq.database.dao.RaReportDao;
import com.femsq.database.dao.RaSummDao;
import com.femsq.database.dao.RalpRaAuDao;
import com.femsq.database.dao.RalpRaCstListDao;
import com.femsq.database.dao.RalpRaDao;
import com.femsq.database.dao.JdbcOgAgDao;
import com.femsq.database.dao.JdbcOgDao;
import com.femsq.database.dao.JdbcOgNmFDao;
import com.femsq.database.dao.JdbcOrgIdDao;
import com.femsq.database.dao.OgAgCsDao;
import com.femsq.database.dao.JdbcRaADao;
import com.femsq.database.dao.JdbcRaAtDao;
import com.femsq.database.dao.JdbcRaDirDao;
import com.femsq.database.dao.JdbcRaExecutionDao;
import com.femsq.database.dao.JdbcRaFDao;
import com.femsq.database.dao.JdbcRaFtDao;
import com.femsq.database.dao.JdbcRaFtSDao;
import com.femsq.database.dao.JdbcRaFtSnDao;
import com.femsq.database.dao.JdbcRaFtStDao;
import com.femsq.database.dao.JdbcRaColMapDao;
import com.femsq.database.dao.JdbcRaSheetConfDao;
import com.femsq.database.dao.JdbcStNetworkDao;
import com.femsq.database.dao.OgAgDao;
import com.femsq.database.dao.OgDao;
import com.femsq.database.dao.OgNmFDao;
import com.femsq.database.dao.OrgIdDao;
import com.femsq.database.dao.RaADao;
import com.femsq.database.dao.RaAtDao;
import com.femsq.database.dao.RaDirDao;
import com.femsq.database.dao.RaExecutionDao;
import com.femsq.database.dao.RaFDao;
import com.femsq.database.dao.RaFtDao;
import com.femsq.database.dao.RaFtSDao;
import com.femsq.database.dao.RaFtSnDao;
import com.femsq.database.dao.RaFtStDao;
import com.femsq.database.dao.RaColMapDao;
import com.femsq.database.dao.RaSheetConfDao;
import com.femsq.database.dao.StNetworkDao;
import com.femsq.database.dao.RelationDao;
import com.femsq.database.dao.SudzDao;
import com.femsq.database.dao.JdbcRelationDao;
import com.femsq.database.dao.JdbcSudzDao;
import com.femsq.database.service.DefaultIpgChainRelationService;
import com.femsq.database.service.DefaultIpgChainService;
import com.femsq.database.service.DefaultInvestmentPlanGroupService;
import com.femsq.database.service.DefaultInvestmentProgramService;
import com.femsq.database.service.CnContractService;
import com.femsq.database.service.CnNumService;
import com.femsq.database.service.CnSOrgService;
import com.femsq.database.service.CnSOrgSmplService;
import com.femsq.database.service.CnSService;
import com.femsq.database.service.CnService;
import com.femsq.database.service.CstAgPnBranchService;
import com.femsq.database.service.CstAgPnService;
import com.femsq.database.service.CstAgService;
import com.femsq.database.service.CstRaListService;
import com.femsq.database.service.CstService;
import com.femsq.database.service.DefaultCnContractService;
import com.femsq.database.service.DefaultCnNumService;
import com.femsq.database.service.DefaultCnSOrgService;
import com.femsq.database.service.DefaultCnSOrgSmplService;
import com.femsq.database.service.DefaultCnSService;
import com.femsq.database.service.DefaultCnService;
import com.femsq.database.service.DefaultCstAgPnBranchService;
import com.femsq.database.service.DefaultCstAgPnService;
import com.femsq.database.service.DefaultCstAgService;
import com.femsq.database.service.DefaultCstRaListService;
import com.femsq.database.service.DefaultCstService;
import com.femsq.database.service.DefaultOgAgCsService;
import com.femsq.database.service.DefaultOgAgService;
import com.femsq.database.service.DefaultOgNmFService;
import com.femsq.database.service.DefaultOgService;
import com.femsq.database.service.DefaultOrgIdService;
import com.femsq.database.service.DefaultRaPeriodService;
import com.femsq.database.service.DefaultRaReportService;
import com.femsq.database.service.DefaultRaSummService;
import com.femsq.database.service.DefaultRalpRaAuService;
import com.femsq.database.service.DefaultRalpRaAuStatusService;
import com.femsq.database.service.DefaultRalpRaCstListService;
import com.femsq.database.service.DefaultRalpRaService;
import com.femsq.database.service.OgAgCsService;
import com.femsq.database.service.OgAgService;
import com.femsq.database.service.OgNmFService;
import com.femsq.database.service.OgService;
import com.femsq.database.service.OrgIdService;
import com.femsq.database.service.RaPeriodService;
import com.femsq.database.service.RaReportService;
import com.femsq.database.service.RaSummService;
import com.femsq.database.service.RalpRaAuService;
import com.femsq.database.service.RalpRaAuStatusService;
import com.femsq.database.service.RalpRaCstListService;
import com.femsq.database.service.RalpRaService;
import com.femsq.database.service.DefaultRaAService;
import com.femsq.database.service.DefaultRaAtService;
import com.femsq.database.service.DefaultRaDirService;
import com.femsq.database.service.DefaultRaExecutionService;
import com.femsq.database.service.DefaultRaFService;
import com.femsq.database.service.DefaultRaFtService;
import com.femsq.database.service.DefaultRelationService;
import com.femsq.database.service.DefaultSudzService;
import com.femsq.database.service.RelationService;
import com.femsq.database.service.SudzService;
import com.femsq.database.service.DefaultRaFtSService;
import com.femsq.database.service.DefaultRaFtSnService;
import com.femsq.database.service.DefaultRaFtStService;
import com.femsq.database.service.DefaultRaColMapService;
import com.femsq.database.service.DefaultRaSheetConfService;
import com.femsq.database.service.DefaultStNetworkService;
import com.femsq.database.service.IpgChainRelationService;
import com.femsq.database.service.IpgChainService;
import com.femsq.database.service.InvestmentPlanGroupService;
import com.femsq.database.service.InvestmentProgramService;
import com.femsq.database.service.RaAService;
import com.femsq.database.service.RaAtService;
import com.femsq.database.service.RaDirService;
import com.femsq.database.service.RaExecutionService;
import com.femsq.database.service.RaFService;
import com.femsq.database.service.RaFtService;
import com.femsq.database.service.RaFtSService;
import com.femsq.database.service.RaFtSnService;
import com.femsq.database.service.RaFtStService;
import com.femsq.database.service.RaColMapService;
import com.femsq.database.service.RaSheetConfService;
import com.femsq.database.service.StNetworkService;
import org.springframework.beans.factory.annotation.Value;
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
     * DAO {@code org_id} (БУиРГ / ИНН).
     *
     * @param connectionFactory фабрика
     * @param configurationService схема
     * @return DAO
     */
    @Bean
    public OrgIdDao orgIdDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        return new JdbcOrgIdDao(connectionFactory, configurationService);
    }

    /**
     * DAO {@code ogNmF} (варианты наименований).
     *
     * @param connectionFactory фабрика
     * @param configurationService схема
     * @return DAO
     */
    @Bean
    public OgNmFDao ogNmFDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        return new JdbcOgNmFDao(connectionFactory, configurationService);
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
     * Сервис идентификаторов организаций ({@code org_id}).
     *
     * @param orgIdDao DAO
     * @param ogService карточки og
     * @return сервис
     */
    @Bean
    public OrgIdService orgIdService(OrgIdDao orgIdDao, OgService ogService) {
        return new DefaultOrgIdService(orgIdDao, ogService);
    }

    /**
     * Сервис вариантов наименований ({@code ogNmF}).
     *
     * @param ogNmFDao DAO
     * @param ogService карточки og
     * @return сервис
     */
    @Bean
    public OgNmFService ogNmFService(OgNmFDao ogNmFDao, OgService ogService) {
        return new DefaultOgNmFService(ogNmFDao, ogService);
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

    /**
     * DAO строек {@code cst}.
     */
    @Bean
    public CstDao cstDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        return new JdbcCstDao(connectionFactory, configurationService);
    }

    /**
     * DAO номеров договоров {@code cnNum}.
     */
    @Bean
    public CnNumDao cnNumDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        return new JdbcCnNumDao(connectionFactory, configurationService);
    }

    /**
     * DAO договоров {@code cn}.
     */
    @Bean
    public CnDao cnDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        return new JdbcCnDao(connectionFactory, configurationService);
    }

    @Bean
    public CnNumService cnNumService(CnNumDao cnNumDao) {
        return new DefaultCnNumService(cnNumDao);
    }

    @Bean
    public CnService cnService(CnDao cnDao) {
        return new DefaultCnService(cnDao);
    }

    /**
     * DAO составного создания договора с исполнителем.
     */
    @Bean
    public CnContractDao cnContractDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        return new JdbcCnContractDao(connectionFactory, configurationService);
    }

    @Bean
    public CnContractService cnContractService(CnContractDao cnContractDao) {
        return new DefaultCnContractService(cnContractDao);
    }

    /**
     * DAO сторон договора {@code cn_s}.
     */
    @Bean
    public CnSDao cnSDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        return new JdbcCnSDao(connectionFactory, configurationService);
    }

    /**
     * DAO {@code cn_s_org_smpl}.
     */
    @Bean
    public CnSOrgSmplDao cnSOrgSmplDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        return new JdbcCnSOrgSmplDao(connectionFactory, configurationService);
    }

    /**
     * DAO {@code cn_s_org}.
     */
    @Bean
    public CnSOrgDao cnSOrgDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        return new JdbcCnSOrgDao(connectionFactory, configurationService);
    }

    @Bean
    public CnSService cnSService(CnSDao cnSDao, CnSOrgSmplDao cnSOrgSmplDao, CnSOrgDao cnSOrgDao, CnDao cnDao) {
        return new DefaultCnSService(cnSDao, cnSOrgSmplDao, cnSOrgDao, cnDao);
    }

    @Bean
    public CnSOrgSmplService cnSOrgSmplService(CnSOrgSmplDao cnSOrgSmplDao, CnSOrgDao cnSOrgDao, CnSDao cnSDao) {
        return new DefaultCnSOrgSmplService(cnSOrgSmplDao, cnSOrgDao, cnSDao);
    }

    @Bean
    public CnSOrgService cnSOrgService(CnSOrgDao cnSOrgDao, CnSOrgSmplDao cnSOrgSmplDao) {
        return new DefaultCnSOrgService(cnSOrgDao, cnSOrgSmplDao);
    }

    /**
     * DAO агентов на стройках {@code cstAg}.
     */
    @Bean
    public CstAgDao cstAgDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        return new JdbcCstAgDao(connectionFactory, configurationService);
    }

    /**
     * DAO САК {@code cstAgPn}.
     */
    @Bean
    public CstAgPnDao cstAgPnDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        return new JdbcCstAgPnDao(connectionFactory, configurationService);
    }

    /**
     * DAO филиалов САК {@code cstAgPnBranch}.
     */
    @Bean
    public CstAgPnBranchDao cstAgPnBranchDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        return new JdbcCstAgPnBranchDao(connectionFactory, configurationService);
    }

    /**
     * DAO lookup агентов {@code ogAgCs}.
     */
    @Bean
    public OgAgCsDao ogAgCsDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        return new JdbcOgAgCsDao(connectionFactory, configurationService);
    }

    @Bean
    public CstService cstService(CstDao cstDao) {
        return new DefaultCstService(cstDao);
    }

    @Bean
    public CstAgService cstAgService(CstAgDao cstAgDao, CstDao cstDao) {
        return new DefaultCstAgService(cstAgDao, cstDao);
    }

    @Bean
    public CstAgPnService cstAgPnService(CstAgPnDao cstAgPnDao, CstAgDao cstAgDao) {
        return new DefaultCstAgPnService(cstAgPnDao, cstAgDao);
    }

    @Bean
    public CstAgPnBranchService cstAgPnBranchService(CstAgPnBranchDao cstAgPnBranchDao, CstAgPnDao cstAgPnDao, OgDao ogDao) {
        return new DefaultCstAgPnBranchService(cstAgPnBranchDao, cstAgPnDao, ogDao);
    }

    @Bean
    public OgAgCsService ogAgCsService(OgAgCsDao ogAgCsDao) {
        return new DefaultOgAgCsService(ogAgCsDao);
    }

    /**
     * DAO перечня отчётов стройки ({@code fnRRcList}).
     */
    @Bean
    public CstRaListDao cstRaListDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        return new JdbcCstRaListDao(connectionFactory, configurationService);
    }

    @Bean
    public RaReportDao raReportDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        return new JdbcRaReportDao(connectionFactory, configurationService);
    }

    @Bean
    public RaSummDao raSummDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        return new JdbcRaSummDao(connectionFactory, configurationService);
    }

    @Bean
    public RaPeriodDao raPeriodDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        return new JdbcRaPeriodDao(connectionFactory, configurationService);
    }

    @Bean
    public CstRaListService cstRaListService(CstRaListDao cstRaListDao) {
        return new DefaultCstRaListService(cstRaListDao);
    }

    @Bean
    public RaReportService raReportService(RaReportDao raReportDao, RaSummDao raSummDao, CstAgPnDao cstAgPnDao) {
        return new DefaultRaReportService(raReportDao, raSummDao, cstAgPnDao);
    }

    @Bean
    public RaSummService raSummService(RaSummDao raSummDao, RaReportDao raReportDao) {
        return new DefaultRaSummService(raSummDao, raReportDao);
    }

    @Bean
    public RaPeriodService raPeriodService(RaPeriodDao raPeriodDao) {
        return new DefaultRaPeriodService(raPeriodDao);
    }

    /**
     * DAO списка отчётов аренды (Access {@code ralpRaCst}).
     */
    @Bean
    public RalpRaCstListDao ralpRaCstListDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        return new JdbcRalpRaCstListDao(connectionFactory, configurationService);
    }

    @Bean
    public RalpRaDao ralpRaDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        return new JdbcRalpRaDao(connectionFactory, configurationService);
    }

    @Bean
    public RalpRaAuDao ralpRaAuDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        return new JdbcRalpRaAuDao(connectionFactory, configurationService);
    }

    @Bean
    public RalpRaCstListService ralpRaCstListService(RalpRaCstListDao ralpRaCstListDao) {
        return new DefaultRalpRaCstListService(ralpRaCstListDao);
    }

    @Bean
    public RalpRaService ralpRaService(RalpRaDao ralpRaDao, CstAgPnDao cstAgPnDao) {
        return new DefaultRalpRaService(ralpRaDao, cstAgPnDao);
    }

    @Bean
    public RalpRaAuService ralpRaAuService(RalpRaAuDao ralpRaAuDao, RalpRaDao ralpRaDao) {
        return new DefaultRalpRaAuService(ralpRaAuDao, ralpRaDao);
    }

    @Bean
    public RalpRaAuStatusService ralpRaAuStatusService() {
        return new DefaultRalpRaAuStatusService();
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

    @Bean
    public RaFDao raFDao(ConnectionFactory connectionFactory) {
        return new JdbcRaFDao(connectionFactory);
    }

    @Bean
    public RaExecutionDao raExecutionDao(ConnectionFactory connectionFactory) {
        return new JdbcRaExecutionDao(connectionFactory);
    }

    @Bean
    public RaSheetConfDao raSheetConfDao(ConnectionFactory connectionFactory) {
        return new JdbcRaSheetConfDao(connectionFactory);
    }

    @Bean
    public RaColMapDao raColMapDao(ConnectionFactory connectionFactory) {
        return new JdbcRaColMapDao(connectionFactory);
    }

    @Bean
    public RaFtStDao raFtStDao(ConnectionFactory connectionFactory) {
        return new JdbcRaFtStDao(connectionFactory);
    }

    @Bean
    public RaFtSDao raFtSDao(ConnectionFactory connectionFactory) {
        return new JdbcRaFtSDao(connectionFactory);
    }

    @Bean
    public RaFtSnDao raFtSnDao(ConnectionFactory connectionFactory) {
        return new JdbcRaFtSnDao(connectionFactory);
    }

    @Bean
    public RaFtDao raFtDao(ConnectionFactory connectionFactory) {
        return new JdbcRaFtDao(connectionFactory);
    }

    @Bean
    public RaFService raFService(RaFDao raFDao) {
        return new DefaultRaFService(raFDao);
    }

    @Bean
    public RaExecutionService raExecutionService(RaExecutionDao raExecutionDao) {
        return new DefaultRaExecutionService(raExecutionDao);
    }

    @Bean
    public RaSheetConfService raSheetConfService(RaSheetConfDao raSheetConfDao) {
        return new DefaultRaSheetConfService(raSheetConfDao);
    }

    @Bean
    public RaColMapService raColMapService(RaColMapDao raColMapDao) {
        return new DefaultRaColMapService(raColMapDao);
    }

    @Bean
    public RaFtStService raFtStService(RaFtStDao raFtStDao) {
        return new DefaultRaFtStService(raFtStDao);
    }

    @Bean
    public RaFtSService raFtSService(RaFtSDao raFtSDao, RaFtStDao raFtStDao) {
        return new DefaultRaFtSService(raFtSDao, raFtStDao);
    }

    @Bean
    public RaFtSnService raFtSnService(RaFtSnDao raFtSnDao, RaFtSDao raFtSDao) {
        return new DefaultRaFtSnService(raFtSnDao, raFtSDao);
    }

    @Bean
    public RaFtService raFtService(RaFtDao raFtDao) {
        return new DefaultRaFtService(raFtDao);
    }

    @Bean
    public SudzDao sudzDao(
            ConnectionFactory connectionFactory,
            @Value("${femsq.sudz.schema:sudz}") String sudzSchema
    ) {
        return new JdbcSudzDao(connectionFactory, sudzSchema);
    }

    @Bean
    public SudzService sudzService(SudzDao sudzDao) {
        return new DefaultSudzService(sudzDao);
    }

    /**
     * DAO обхода связей (whitelist рёбер).
     *
     * @param connectionFactory подключение
     * @param configurationService схема ags
     * @return DAO
     */
    @Bean
    public RelationDao relationDao(
            ConnectionFactory connectionFactory,
            DatabaseConfigurationService configurationService
    ) {
        return new JdbcRelationDao(connectionFactory, configurationService);
    }

    /**
     * Сервис обхода связей.
     *
     * @param relationDao DAO
     * @return сервис
     */
    @Bean
    public RelationService relationService(RelationDao relationDao) {
        return new DefaultRelationService(relationDao);
    }
}
