package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.Og;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC-реализация {@link OgDao} на основе {@link ConnectionFactory}.
 */
public class JdbcOgDao implements OgDao {

    private static final Logger log = Logger.getLogger(JdbcOgDao.class.getName());
    private static final String TABLE_BASE_NAME = "og";

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcOgDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
        this.configurationService = Objects.requireNonNull(configurationService, "configurationService");
    }

    /**
     * Возвращает полное имя таблицы с учетом текущей схемы из конфигурации.
     *
     * @return полное имя таблицы в формате "schema.table"
     */
    private String getTableName() {
        try {
            String schema = configurationService.loadConfig().schema();
            return schema + "." + TABLE_BASE_NAME;
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            log.log(Level.WARNING, "Configuration not found, using default schema", exception);
            return "ags_test." + TABLE_BASE_NAME;
        }
    }

    @Override
    public Optional<Og> findById(int ogKey) {
        String sql = "SELECT ogKey, ogNm, ogNmOf, ogNmFl, ogTxt, ogINN, ogKPP, ogOGRN, ogOKPO, ogOE, ogRgTaxType "
                + "FROM " + getTableName() + " WHERE ogKey = ?";
        log.log(Level.FINE, "Executing findById for ogKey={0}", ogKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ogKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return Optional.of(mapOg(resultSet));
                }
                return Optional.empty();
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findById", exception);
            throw new DaoException("Не удалось получить организацию c идентификатором " + ogKey, exception);
        }
    }

    @Override
    public List<Og> findAll() {
        String sql = "SELECT ogKey, ogNm, ogNmOf, ogNmFl, ogTxt, ogINN, ogKPP, ogOGRN, ogOKPO, ogOE, ogRgTaxType FROM "
                + getTableName() + " ORDER BY ogKey";
        log.fine("Executing findAll for og");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            List<Og> result = new ArrayList<>();
            while (resultSet.next()) {
                result.add(mapOg(resultSet));
            }
            return List.copyOf(result);
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findAll", exception);
            throw new DaoException("Не удалось получить список организаций", exception);
        }
    }

    @Override
    public List<Og> findAll(int page, int size, String sortField, String sortDirection) {
        // Валидация и нормализация параметров
        String safeSortField = validateSortField(sortField);
        String safeSortDirection = "desc".equalsIgnoreCase(sortDirection) ? "DESC" : "ASC";
        int offset = page * size;

        // SQL Server требует OFFSET, даже если он равен 0
        // Используем синтаксис совместимый с SQL Server 2012+
        String sql = "SELECT ogKey, ogNm, ogNmOf, ogNmFl, ogTxt, ogINN, ogKPP, ogOGRN, ogOKPO, ogOE, ogRgTaxType FROM "
                + getTableName() + " ORDER BY " + safeSortField + " " + safeSortDirection
                + " OFFSET " + offset + " ROWS FETCH NEXT " + size + " ROWS ONLY";
        log.fine(() -> String.format("Executing findAll with pagination: page=%d, size=%d, sort=%s %s, offset=%d", 
                page, size, safeSortField, safeSortDirection, offset));
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            List<Og> result = new ArrayList<>();
            while (resultSet.next()) {
                result.add(mapOg(resultSet));
            }
            return List.copyOf(result);
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findAll with pagination", exception);
            log.log(Level.SEVERE, "SQL: " + sql, exception);
            throw new DaoException("Не удалось получить список организаций с пагинацией: " + exception.getMessage(), exception);
        }
    }

    @Override
    public long count() {
        String sql = "SELECT COUNT(*) FROM " + getTableName();
        log.fine("Executing count for og");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            if (resultSet.next()) {
                return resultSet.getLong(1);
            }
            return 0L;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute count", exception);
            throw new DaoException("Не удалось подсчитать количество организаций", exception);
        }
    }

    /**
     * Валидирует и нормализует имя поля для сортировки.
     * Разрешает только безопасные имена полей для предотвращения SQL-инъекций.
     */
    private String validateSortField(String sortField) {
        if (sortField == null || sortField.trim().isEmpty()) {
            return "ogKey";
        }
        String normalized = sortField.trim();
        // Разрешаем только известные поля
        switch (normalized.toLowerCase()) {
            case "ogkey":
            case "ognm":
            case "ognmof":
            case "ognmfl":
            case "oginn":
            case "ogkpp":
            case "ogogrn":
            case "ogokpo":
            case "ogoe":
            case "ogrgtaxtype":
                return normalized;
            default:
                log.warning(() -> "Invalid sort field: " + normalized + ", using default: ogKey");
                return "ogKey";
        }
    }

    @Override
    public Og create(Og organization) {
        Objects.requireNonNull(organization, "organization");
        String sql = "INSERT INTO " + getTableName() + " (ogNm, ogNmOf, ogNmFl, ogTxt, ogINN, ogKPP, ogOGRN, ogOKPO, ogOE, ogRgTaxType) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        log.log(Level.INFO, "Creating organization {0}", organization.ogName());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            bindOrganization(statement, organization);
            statement.executeUpdate();
            try (ResultSet generatedKeys = statement.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    int generatedId = generatedKeys.getInt(1);
                    return organizationWithId(organization, generatedId);
                }
                throw new DaoException("Не удалось получить идентификатор созданной организации");
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute create", exception);
            throw new DaoException("Не удалось создать организацию", exception);
        }
    }

    @Override
    public Og update(Og organization) {
        Objects.requireNonNull(organization, "organization");
        if (organization.ogKey() == null) {
            throw new DaoException("Для обновления организации необходим идентификатор");
        }
        String sql = "UPDATE " + getTableName()
                + " SET ogNm = ?, ogNmOf = ?, ogNmFl = ?, ogTxt = ?, ogINN = ?, ogKPP = ?, ogOGRN = ?, ogOKPO = ?, ogOE = ?, ogRgTaxType = ?"
                + " WHERE ogKey = ?";
        log.log(Level.INFO, "Updating organization {0}", organization.ogKey());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            bindOrganization(statement, organization);
            statement.setInt(11, organization.ogKey());
            int updated = statement.executeUpdate();
            if (updated == 0) {
                throw new DaoException("Организация с идентификатором " + organization.ogKey() + " не найдена");
            }
            return organization;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute update", exception);
            throw new DaoException("Не удалось обновить организацию", exception);
        }
    }

    @Override
    public boolean deleteById(int ogKey) {
        String sql = "DELETE FROM " + getTableName() + " WHERE ogKey = ?";
        log.log(Level.INFO, "Deleting organization {0}", ogKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ogKey);
            int deleted = statement.executeUpdate();
            return deleted > 0;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute delete", exception);
            throw new DaoException("Не удалось удалить организацию " + ogKey, exception);
        }
    }

    private void bindOrganization(PreparedStatement statement, Og organization) throws SQLException {
        statement.setNString(1, organization.ogName());
        statement.setNString(2, organization.ogOfficialName());
        statement.setNString(3, organization.ogFullName());
        statement.setNString(4, organization.ogDescription());
        setNullable(statement, 5, organization.inn(), Types.DOUBLE);
        setNullable(statement, 6, organization.kpp(), Types.DOUBLE);
        setNullable(statement, 7, organization.ogrn(), Types.DOUBLE);
        setNullable(statement, 8, organization.okpo(), Types.DOUBLE);
        setNullable(statement, 9, organization.oe(), Types.INTEGER);
        statement.setString(10, organization.registrationTaxType());
    }

    private void setNullable(PreparedStatement statement, int index, Object value, int sqlType) throws SQLException {
        if (value == null) {
            statement.setNull(index, sqlType);
        } else {
            statement.setObject(index, value, sqlType);
        }
    }

    private Og mapOg(ResultSet resultSet) throws SQLException {
        return new Og(
                resultSet.getInt("ogKey"),
                resultSet.getNString("ogNm"),
                resultSet.getNString("ogNmOf"),
                resultSet.getNString("ogNmFl"),
                resultSet.getNString("ogTxt"),
                resultSet.getObject("ogINN", Double.class),
                resultSet.getObject("ogKPP", Double.class),
                resultSet.getObject("ogOGRN", Double.class),
                resultSet.getObject("ogOKPO", Double.class),
                resultSet.getObject("ogOE", Integer.class),
                resultSet.getString("ogRgTaxType")
        );
    }

    private Og organizationWithId(Og organization, int generatedId) {
        return new Og(
                generatedId,
                organization.ogName(),
                organization.ogOfficialName(),
                organization.ogFullName(),
                organization.ogDescription(),
                organization.inn(),
                organization.kpp(),
                organization.ogrn(),
                organization.okpo(),
                organization.oe(),
                organization.registrationTaxType()
        );
    }
}
