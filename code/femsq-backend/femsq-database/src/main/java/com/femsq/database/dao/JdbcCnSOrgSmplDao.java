package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.CnSOrgIdLookup;
import com.femsq.database.model.CnSOrgSmpl;
import com.femsq.database.model.OrgId;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC-реализация {@link CnSOrgSmplDao}.
 */
public class JdbcCnSOrgSmplDao implements CnSOrgSmplDao {

    private static final Logger log = Logger.getLogger(JdbcCnSOrgSmplDao.class.getName());

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcCnSOrgSmplDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
        this.configurationService = Objects.requireNonNull(configurationService, "configurationService");
    }

    private String schemaPrefix() {
        try {
            String schema = configurationService.loadConfig().schema();
            if (schema == null || schema.isBlank()) {
                return "ags.";
            }
            return schema.trim() + ".";
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            log.log(Level.WARNING, "Configuration missing for cn_s_org_smpl, fallback ags.", exception);
            return "ags.";
        }
    }

    private String tableName() {
        return schemaPrefix() + "cn_s_org_smpl";
    }

    private String selectWithLabel() {
        return "SELECT m.csosKey, m.csosCn_s, m.csosOrgId, m.csosTimeOfEntry, "
                + "CAST(i.org_id_value_l AS nvarchar(32)) + N' ' + ISNULL(o.ogNm, N'') AS orgLabel "
                + "FROM " + tableName() + " m "
                + "LEFT JOIN " + schemaPrefix() + "org_id i ON i.org_id_key = m.csosOrgId "
                + "LEFT JOIN " + schemaPrefix() + "og o ON o.ogKey = i.org";
    }

    @Override
    public Optional<CnSOrgSmpl> findById(int csosKey) {
        String sql = selectWithLabel() + " WHERE m.csosKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, csosKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return Optional.of(mapRow(rs));
                }
                return Optional.empty();
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось получить csosKey=" + csosKey, exception);
        }
    }

    @Override
    public List<CnSOrgSmpl> findByCnSKey(int cnSKey) {
        String sql = selectWithLabel() + " WHERE m.csosCn_s = ? ORDER BY m.csosKey";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, cnSKey);
            try (ResultSet rs = statement.executeQuery()) {
                List<CnSOrgSmpl> rows = new ArrayList<>();
                while (rs.next()) {
                    rows.add(mapRow(rs));
                }
                return List.copyOf(rows);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось получить smpl для cn_s_key=" + cnSKey, exception);
        }
    }

    @Override
    public List<CnSOrgSmpl> findByCnKey(int cnKey) {
        String sql = selectWithLabel()
                + " INNER JOIN " + schemaPrefix() + "cn_s s ON s.cn_s_key = m.csosCn_s "
                + "WHERE s.cn_key = ? ORDER BY s.cn_s_type, m.csosKey";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, cnKey);
            try (ResultSet rs = statement.executeQuery()) {
                List<CnSOrgSmpl> rows = new ArrayList<>();
                while (rs.next()) {
                    rows.add(mapRow(rs));
                }
                return List.copyOf(rows);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось получить smpl для cn_key=" + cnKey, exception);
        }
    }

    @Override
    public List<CnSOrgIdLookup> findOrgIdLookups() {
        String sql = "SELECT i.org_id_key, i.org_id_value_l, "
                + "CAST(i.org_id_value_l AS nvarchar(32)) + N' ' + ISNULL(o.ogNm, N'') AS label "
                + "FROM " + schemaPrefix() + "org_id i "
                + "LEFT JOIN " + schemaPrefix() + "og o ON o.ogKey = i.org "
                + "WHERE i.org_id_type = " + OrgId.TYPE_BUIRG + " "
                + "ORDER BY i.org_id_value_l, o.ogNm";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet rs = statement.executeQuery()) {
            List<CnSOrgIdLookup> rows = new ArrayList<>();
            while (rs.next()) {
                rows.add(new CnSOrgIdLookup(
                        rs.getInt("org_id_key"),
                        (Integer) rs.getObject("org_id_value_l"),
                        rs.getNString("label")
                ));
            }
            return List.copyOf(rows);
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось загрузить lookup org_id для сторон договора", exception);
        }
    }

    @Override
    public CnSOrgSmpl create(CnSOrgSmpl smpl) {
        Objects.requireNonNull(smpl, "smpl");
        String sql = "INSERT INTO " + tableName() + " (csosCn_s, csosOrgId, csosTimeOfEntry) VALUES (?, ?, ?)";
        log.log(Level.INFO, "Creating cn_s_org_smpl cn_s={0} orgId={1}",
                new Object[]{smpl.csosCnS(), smpl.csosOrgId()});
        LocalDateTime entry = smpl.csosTimeOfEntry() != null ? smpl.csosTimeOfEntry() : LocalDateTime.now();
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setInt(1, smpl.csosCnS());
            statement.setInt(2, smpl.csosOrgId());
            statement.setTimestamp(3, Timestamp.valueOf(entry));
            statement.executeUpdate();
            try (ResultSet keys = statement.getGeneratedKeys()) {
                if (!keys.next()) {
                    throw new DaoException("Не удалось получить csosKey");
                }
                return findById(keys.getInt(1))
                        .orElseThrow(() -> new DaoException("Не удалось прочитать созданный smpl"));
            }
        } catch (SQLException exception) {
            throw new DaoException("Не удалось создать cn_s_org_smpl", exception);
        }
    }

    @Override
    public CnSOrgSmpl update(CnSOrgSmpl smpl) {
        Objects.requireNonNull(smpl, "smpl");
        if (smpl.csosKey() == null) {
            throw new DaoException("Для обновления smpl нужен идентификатор");
        }
        String sql = "UPDATE " + tableName() + " SET csosCn_s = ?, csosOrgId = ? WHERE csosKey = ?";
        log.log(Level.INFO, "Updating cn_s_org_smpl {0}", smpl.csosKey());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, smpl.csosCnS());
            statement.setInt(2, smpl.csosOrgId());
            statement.setInt(3, smpl.csosKey());
            if (statement.executeUpdate() == 0) {
                throw new DaoException("csosKey=" + smpl.csosKey() + " не найден");
            }
            return findById(smpl.csosKey())
                    .orElseThrow(() -> new DaoException("Не удалось прочитать обновлённый smpl"));
        } catch (SQLException exception) {
            throw new DaoException("Не удалось обновить cn_s_org_smpl", exception);
        }
    }

    @Override
    public boolean deleteById(int csosKey) {
        String sql = "DELETE FROM " + tableName() + " WHERE csosKey = ?";
        log.log(Level.INFO, "Deleting cn_s_org_smpl {0}", csosKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, csosKey);
            return statement.executeUpdate() > 0;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось удалить csosKey=" + csosKey, exception);
        }
    }

    private static CnSOrgSmpl mapRow(ResultSet rs) throws SQLException {
        Timestamp ts = rs.getTimestamp("csosTimeOfEntry");
        return new CnSOrgSmpl(
                rs.getInt("csosKey"),
                rs.getInt("csosCn_s"),
                rs.getInt("csosOrgId"),
                rs.getNString("orgLabel"),
                ts != null ? ts.toLocalDateTime() : null
        );
    }
}
