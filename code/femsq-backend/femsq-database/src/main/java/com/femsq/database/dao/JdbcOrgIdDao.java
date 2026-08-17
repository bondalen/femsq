package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.OrgId;
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
 * JDBC-реализация {@link OrgIdDao}.
 */
public class JdbcOrgIdDao implements OrgIdDao {

    private static final Logger log = Logger.getLogger(JdbcOrgIdDao.class.getName());
    private static final String TABLE_BASE = "org_id";

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    /**
     * @param connectionFactory фабрика подключений
     * @param configurationService схема БД
     */
    public JdbcOrgIdDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
        this.configurationService = Objects.requireNonNull(configurationService, "configurationService");
    }

    private String tableName() {
        try {
            String schema = configurationService.loadConfig().schema();
            if (schema == null || schema.isBlank()) {
                return "ags." + TABLE_BASE;
            }
            return schema.trim() + "." + TABLE_BASE;
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            log.log(Level.WARNING, "Configuration missing for org_id, fallback ags_test", exception);
            return "ags_test." + TABLE_BASE;
        }
    }

    @Override
    public List<OrgId> findByOrg(int orgKey) {
        String sql = "SELECT org_id_key, org, org_id_type, org_id_value_l, org_id_value_t, org_id_value_t_ext "
                + "FROM " + tableName() + " WHERE org = ? ORDER BY org_id_type, org_id_key";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, orgKey);
            try (ResultSet rs = statement.executeQuery()) {
                List<OrgId> rows = new ArrayList<>();
                while (rs.next()) {
                    rows.add(map(rs));
                }
                return List.copyOf(rows);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось прочитать org_id для org=" + orgKey, exception);
        }
    }

    @Override
    public Optional<OrgId> findBuirg(int buirg) {
        String sql = "SELECT org_id_key, org, org_id_type, org_id_value_l, org_id_value_t, org_id_value_t_ext "
                + "FROM " + tableName()
                + " WHERE org_id_type = " + OrgId.TYPE_BUIRG + " AND org_id_value_l = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, buirg);
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return Optional.of(map(rs));
                }
                return Optional.empty();
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось найти БУиРГ " + buirg, exception);
        }
    }

    @Override
    public boolean existsItnForOrg(int orgKey, String itn, String itnExt) {
        String sql = "SELECT 1 FROM " + tableName()
                + " WHERE org = ? AND org_id_type = " + OrgId.TYPE_ITN
                + " AND org_id_value_t = ?"
                + " AND (("
                + "   (? IS NULL OR LTRIM(RTRIM(?)) = N'') AND (org_id_value_t_ext IS NULL OR LTRIM(RTRIM(org_id_value_t_ext)) = N'')"
                + " ) OR (org_id_value_t_ext = ?))";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, orgKey);
            statement.setNString(2, itn);
            statement.setNString(3, itnExt);
            statement.setNString(4, itnExt);
            statement.setNString(5, itnExt);
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next();
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось проверить ИНН/КПП org=" + orgKey, exception);
        }
    }

    @Override
    public OrgId create(OrgId orgId) {
        Objects.requireNonNull(orgId, "orgId");
        if (orgId.orgIdKey() != null) {
            throw new IllegalArgumentException("Новый org_id не должен содержать ключ");
        }
        String sql = "INSERT INTO " + tableName()
                + " (org, org_id_type, org_id_value_l, org_id_value_t, org_id_value_t_ext)"
                + " VALUES (?, ?, ?, ?, ?)";
        log.log(Level.INFO, "Creating org_id org={0} type={1}",
                new Object[]{orgId.org(), orgId.orgIdType()});
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            bindValues(statement, orgId);
            statement.executeUpdate();
            try (ResultSet keys = statement.getGeneratedKeys()) {
                if (!keys.next()) {
                    throw new DaoException("Не удалось получить org_id_key");
                }
                return new OrgId(
                        keys.getInt(1),
                        orgId.org(),
                        orgId.orgIdType(),
                        orgId.orgIdValueL(),
                        orgId.orgIdValueT(),
                        orgId.orgIdValueTExt()
                );
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось создать org_id для org=" + orgId.org(), exception);
        }
    }

    @Override
    public OrgId update(OrgId orgId) {
        Objects.requireNonNull(orgId, "orgId");
        if (orgId.orgIdKey() == null) {
            throw new IllegalArgumentException("Для обновления org_id нужен ключ");
        }
        String sql = "UPDATE " + tableName()
                + " SET org = ?, org_id_type = ?, org_id_value_l = ?, org_id_value_t = ?, org_id_value_t_ext = ?"
                + " WHERE org_id_key = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            bindValues(statement, orgId);
            statement.setInt(6, orgId.orgIdKey());
            if (statement.executeUpdate() == 0) {
                throw new DaoException("org_id не найден: " + orgId.orgIdKey());
            }
            return orgId;
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось обновить org_id " + orgId.orgIdKey(), exception);
        }
    }

    private static void bindValues(PreparedStatement statement, OrgId orgId) throws SQLException {
        statement.setInt(1, orgId.org());
        statement.setInt(2, orgId.orgIdType());
        if (orgId.orgIdValueL() == null) {
            statement.setNull(3, Types.INTEGER);
        } else {
            statement.setInt(3, orgId.orgIdValueL());
        }
        statement.setNString(4, orgId.orgIdValueT());
        statement.setNString(5, orgId.orgIdValueTExt());
    }

    private static OrgId map(ResultSet rs) throws SQLException {
        Integer valueL = (Integer) rs.getObject("org_id_value_l");
        return new OrgId(
                rs.getInt("org_id_key"),
                rs.getInt("org"),
                rs.getInt("org_id_type"),
                valueL,
                rs.getNString("org_id_value_t"),
                rs.getNString("org_id_value_t_ext")
        );
    }
}
