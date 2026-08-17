package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.CnSOrg;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC-реализация {@link CnSOrgDao}.
 */
public class JdbcCnSOrgDao implements CnSOrgDao {

    private static final Logger log = Logger.getLogger(JdbcCnSOrgDao.class.getName());

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcCnSOrgDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
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
            log.log(Level.WARNING, "Configuration missing for cn_s_org, fallback ags.", exception);
            return "ags.";
        }
    }

    private String tableName() {
        return schemaPrefix() + "cn_s_org";
    }

    private String selectSql() {
        return "SELECT cn_s_org_key, csoCn_s_org_smpl, date_beg, date_end, csoAsbuID, csoCnDate, csoTimeOfEntry "
                + "FROM " + tableName();
    }

    @Override
    public Optional<CnSOrg> findById(int cnSOrgKey) {
        String sql = selectSql() + " WHERE cn_s_org_key = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, cnSOrgKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return Optional.of(mapRow(rs));
                }
                return Optional.empty();
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось получить cn_s_org_key=" + cnSOrgKey, exception);
        }
    }

    @Override
    public List<CnSOrg> findByCsosKey(int csosKey) {
        String sql = selectSql() + " WHERE csoCn_s_org_smpl = ? ORDER BY cn_s_org_key";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, csosKey);
            try (ResultSet rs = statement.executeQuery()) {
                List<CnSOrg> rows = new ArrayList<>();
                while (rs.next()) {
                    rows.add(mapRow(rs));
                }
                return List.copyOf(rows);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось получить cn_s_org для csosKey=" + csosKey, exception);
        }
    }

    @Override
    public List<CnSOrg> findByCnKey(int cnKey) {
        String sql = "SELECT o.cn_s_org_key, o.csoCn_s_org_smpl, o.date_beg, o.date_end, o.csoAsbuID, o.csoCnDate, o.csoTimeOfEntry "
                + "FROM " + tableName() + " o "
                + "INNER JOIN " + schemaPrefix() + "cn_s_org_smpl m ON m.csosKey = o.csoCn_s_org_smpl "
                + "INNER JOIN " + schemaPrefix() + "cn_s s ON s.cn_s_key = m.csosCn_s "
                + "WHERE s.cn_key = ? ORDER BY s.cn_s_type, m.csosKey, o.cn_s_org_key";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, cnKey);
            try (ResultSet rs = statement.executeQuery()) {
                List<CnSOrg> rows = new ArrayList<>();
                while (rs.next()) {
                    rows.add(mapRow(rs));
                }
                return List.copyOf(rows);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось получить cn_s_org для cn_key=" + cnKey, exception);
        }
    }

    @Override
    public CnSOrg create(CnSOrg org) {
        Objects.requireNonNull(org, "org");
        String sql = "INSERT INTO " + tableName()
                + " (csoCn_s_org_smpl, date_beg, date_end, csoAsbuID, csoCnDate, csoTimeOfEntry) "
                + "VALUES (?, ?, ?, ?, ?, ?)";
        log.log(Level.INFO, "Creating cn_s_org smpl={0}", org.csoCnSOrgSmpl());
        LocalDateTime entry = org.csoTimeOfEntry() != null ? org.csoTimeOfEntry() : LocalDateTime.now();
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setInt(1, org.csoCnSOrgSmpl());
            setDate(statement, 2, org.dateBeg());
            setDate(statement, 3, org.dateEnd());
            if (org.csoAsbuId() == null) {
                statement.setNull(4, Types.NVARCHAR);
            } else {
                statement.setNString(4, org.csoAsbuId());
            }
            setDate(statement, 5, org.csoCnDate());
            statement.setTimestamp(6, Timestamp.valueOf(entry));
            statement.executeUpdate();
            try (ResultSet keys = statement.getGeneratedKeys()) {
                if (!keys.next()) {
                    throw new DaoException("Не удалось получить cn_s_org_key");
                }
                return findById(keys.getInt(1))
                        .orElseThrow(() -> new DaoException("Не удалось прочитать созданный cn_s_org"));
            }
        } catch (SQLException exception) {
            throw new DaoException("Не удалось создать cn_s_org", exception);
        }
    }

    @Override
    public CnSOrg update(CnSOrg org) {
        Objects.requireNonNull(org, "org");
        if (org.cnSOrgKey() == null) {
            throw new DaoException("Для обновления cn_s_org нужен идентификатор");
        }
        String sql = "UPDATE " + tableName()
                + " SET csoCn_s_org_smpl = ?, date_beg = ?, date_end = ?, csoAsbuID = ?, csoCnDate = ? "
                + "WHERE cn_s_org_key = ?";
        log.log(Level.INFO, "Updating cn_s_org {0}", org.cnSOrgKey());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, org.csoCnSOrgSmpl());
            setDate(statement, 2, org.dateBeg());
            setDate(statement, 3, org.dateEnd());
            if (org.csoAsbuId() == null) {
                statement.setNull(4, Types.NVARCHAR);
            } else {
                statement.setNString(4, org.csoAsbuId());
            }
            setDate(statement, 5, org.csoCnDate());
            statement.setInt(6, org.cnSOrgKey());
            if (statement.executeUpdate() == 0) {
                throw new DaoException("cn_s_org_key=" + org.cnSOrgKey() + " не найден");
            }
            return findById(org.cnSOrgKey())
                    .orElseThrow(() -> new DaoException("Не удалось прочитать обновлённый cn_s_org"));
        } catch (SQLException exception) {
            throw new DaoException("Не удалось обновить cn_s_org", exception);
        }
    }

    @Override
    public boolean deleteById(int cnSOrgKey) {
        String sql = "DELETE FROM " + tableName() + " WHERE cn_s_org_key = ?";
        log.log(Level.INFO, "Deleting cn_s_org {0}", cnSOrgKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, cnSOrgKey);
            return statement.executeUpdate() > 0;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось удалить cn_s_org_key=" + cnSOrgKey, exception);
        }
    }

    @Override
    public int deleteByCsosKey(int csosKey) {
        String sql = "DELETE FROM " + tableName() + " WHERE csoCn_s_org_smpl = ?";
        log.log(Level.INFO, "Deleting cn_s_org by smpl {0}", csosKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, csosKey);
            return statement.executeUpdate();
        } catch (SQLException exception) {
            throw new DaoException("Не удалось удалить cn_s_org для csosKey=" + csosKey, exception);
        }
    }

    private static void setDate(PreparedStatement statement, int index, LocalDate value) throws SQLException {
        if (value == null) {
            statement.setNull(index, Types.DATE);
        } else {
            statement.setDate(index, Date.valueOf(value));
        }
    }

    private static CnSOrg mapRow(ResultSet rs) throws SQLException {
        Date beg = rs.getDate("date_beg");
        Date end = rs.getDate("date_end");
        Date cnDate = rs.getDate("csoCnDate");
        Timestamp ts = rs.getTimestamp("csoTimeOfEntry");
        return new CnSOrg(
                rs.getInt("cn_s_org_key"),
                rs.getInt("csoCn_s_org_smpl"),
                beg != null ? beg.toLocalDate() : null,
                end != null ? end.toLocalDate() : null,
                rs.getNString("csoAsbuID"),
                cnDate != null ? cnDate.toLocalDate() : null,
                ts != null ? ts.toLocalDateTime() : null
        );
    }
}
