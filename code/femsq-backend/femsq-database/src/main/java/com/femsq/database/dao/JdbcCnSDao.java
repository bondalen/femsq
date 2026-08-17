package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.CnS;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC-реализация {@link CnSDao}.
 */
public class JdbcCnSDao implements CnSDao {

    private static final Logger log = Logger.getLogger(JdbcCnSDao.class.getName());

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcCnSDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
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
            log.log(Level.WARNING, "Configuration missing for cn_s, fallback ags.", exception);
            return "ags.";
        }
    }

    private String tableName() {
        return schemaPrefix() + "cn_s";
    }

    private String typeTable() {
        return schemaPrefix() + "cn_s_type";
    }

    private String selectSql() {
        return "SELECT s.cn_s_key, s.cn_key, s.cn_s_type, t.cn_s_t_name AS cn_s_type_name "
                + "FROM " + tableName() + " s "
                + "LEFT JOIN " + typeTable() + " t ON t.cn_s_t_key = s.cn_s_type";
    }

    @Override
    public Optional<CnS> findById(int cnSKey) {
        String sql = selectSql() + " WHERE s.cn_s_key = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, cnSKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return Optional.of(mapRow(rs));
                }
                return Optional.empty();
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось получить cn_s_key=" + cnSKey, exception);
        }
    }

    @Override
    public List<CnS> findByCnKey(int cnKey) {
        String sql = selectSql() + " WHERE s.cn_key = ? ORDER BY s.cn_s_type, s.cn_s_key";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, cnKey);
            try (ResultSet rs = statement.executeQuery()) {
                List<CnS> rows = new ArrayList<>();
                while (rs.next()) {
                    rows.add(mapRow(rs));
                }
                return List.copyOf(rows);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось получить стороны договора cn_key=" + cnKey, exception);
        }
    }

    @Override
    public CnS create(CnS side) {
        Objects.requireNonNull(side, "side");
        String sql = "INSERT INTO " + tableName() + " (cn_key, cn_s_type) VALUES (?, ?)";
        log.log(Level.INFO, "Creating cn_s cn_key={0} type={1}", new Object[]{side.cnKey(), side.cnSType()});
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setInt(1, side.cnKey());
            statement.setInt(2, side.cnSType());
            statement.executeUpdate();
            try (ResultSet keys = statement.getGeneratedKeys()) {
                if (!keys.next()) {
                    throw new DaoException("Не удалось получить cn_s_key");
                }
                return findById(keys.getInt(1))
                        .orElseThrow(() -> new DaoException("Не удалось прочитать созданную cn_s"));
            }
        } catch (SQLException exception) {
            throw new DaoException("Не удалось создать сторону договора", exception);
        }
    }

    @Override
    public CnS update(CnS side) {
        Objects.requireNonNull(side, "side");
        if (side.cnSKey() == null) {
            throw new DaoException("Для обновления cn_s нужен идентификатор");
        }
        String sql = "UPDATE " + tableName() + " SET cn_key = ?, cn_s_type = ? WHERE cn_s_key = ?";
        log.log(Level.INFO, "Updating cn_s {0}", side.cnSKey());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, side.cnKey());
            statement.setInt(2, side.cnSType());
            statement.setInt(3, side.cnSKey());
            if (statement.executeUpdate() == 0) {
                throw new DaoException("cn_s_key=" + side.cnSKey() + " не найден");
            }
            return findById(side.cnSKey())
                    .orElseThrow(() -> new DaoException("Не удалось прочитать обновлённую cn_s"));
        } catch (SQLException exception) {
            throw new DaoException("Не удалось обновить сторону договора", exception);
        }
    }

    @Override
    public boolean deleteById(int cnSKey) {
        String sql = "DELETE FROM " + tableName() + " WHERE cn_s_key = ?";
        log.log(Level.INFO, "Deleting cn_s {0}", cnSKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, cnSKey);
            return statement.executeUpdate() > 0;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось удалить cn_s_key=" + cnSKey, exception);
        }
    }

    private static CnS mapRow(ResultSet rs) throws SQLException {
        return new CnS(
                rs.getInt("cn_s_key"),
                rs.getInt("cn_key"),
                rs.getInt("cn_s_type"),
                rs.getNString("cn_s_type_name")
        );
    }
}
