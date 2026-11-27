package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.IpgUtPl;
import com.femsq.database.model.IpgUtPlP;
import com.femsq.database.model.IpgUtPlPnLmMnCell;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC-реализация {@link IpgUtPlDao} (C2 O2 §4.2).
 */
public class JdbcIpgUtPlDao implements IpgUtPlDao {

    private static final Logger log = Logger.getLogger(JdbcIpgUtPlDao.class.getName());

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcIpgUtPlDao(
            ConnectionFactory connectionFactory,
            DatabaseConfigurationService configurationService) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
        this.configurationService = Objects.requireNonNull(
                configurationService, "configurationService");
    }

    private String schema() {
        try {
            String value = configurationService.loadConfig().schema();
            if (value == null || value.isBlank()) {
                return "ags";
            }
            return value.trim();
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            log.log(Level.WARNING, "Schema missing, default ags", exception);
            return "ags";
        }
    }

    private String q(String table) {
        return schema() + "." + table;
    }

    @Override
    public List<IpgUtPl> findUtPlByIpg(int ipgKey) {
        String sql = "SELECT iuplKey, iuplNm, iuplDate, iuplAg, iuplIpg FROM " + q("ipgUtPl")
                + " WHERE iuplIpg = ? ORDER BY iuplNm, iuplKey";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ipgKey);
            try (ResultSet rs = statement.executeQuery()) {
                List<IpgUtPl> result = new ArrayList<>();
                while (rs.next()) {
                    result.add(mapUtPl(rs));
                }
                return List.copyOf(result);
            }
        } catch (SQLException | DatabaseConfigurationService.MissingConfigurationException exception) {
            throw new DaoException("Не удалось прочитать ipgUtPl по ipg=" + ipgKey, exception);
        }
    }

    @Override
    public Optional<IpgUtPl> findUtPlByKey(int iuplKey) {
        String sql = "SELECT iuplKey, iuplNm, iuplDate, iuplAg, iuplIpg FROM " + q("ipgUtPl")
                + " WHERE iuplKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, iuplKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }
                return Optional.of(mapUtPl(rs));
            }
        } catch (SQLException | DatabaseConfigurationService.MissingConfigurationException exception) {
            throw new DaoException("Не удалось прочитать ipgUtPl key=" + iuplKey, exception);
        }
    }

    @Override
    public IpgUtPl createUtPl(int ipgKey, int agKey, String name, LocalDate date) {
        String sql = "INSERT INTO " + q("ipgUtPl")
                + " (iuplNm, iuplDate, iuplAg, iuplIpg) VALUES (?, ?, ?, ?)";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(
                     sql, Statement.RETURN_GENERATED_KEYS)) {
            if (name == null || name.isBlank()) {
                statement.setNull(1, Types.NVARCHAR);
            } else {
                statement.setNString(1, name.trim());
            }
            if (date == null) {
                statement.setNull(2, Types.DATE);
            } else {
                statement.setDate(2, Date.valueOf(date));
            }
            statement.setInt(3, agKey);
            statement.setInt(4, ipgKey);
            statement.executeUpdate();
            int key = readGeneratedKey(statement, "ipgUtPl");
            log.info(() -> "createUtPl key=" + key + " ipg=" + ipgKey + " ag=" + agKey);
            return findUtPlByKey(key).orElseThrow(
                    () -> new DaoException("ipgUtPl не найден после insert key=" + key));
        } catch (SQLException | DatabaseConfigurationService.MissingConfigurationException exception) {
            throw new DaoException("Не удалось создать ipgUtPl", exception);
        }
    }

    @Override
    public List<IpgUtPlP> findUtPlPByPlan(int plKey) {
        String sql = "SELECT iuplpKey, iuplpPl, iuplpIpgPn, iuplpLim, iuplpSubAg FROM "
                + q("ipgUtPlP") + " WHERE iuplpPl = ? ORDER BY iuplpIpgPn, iuplpKey";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, plKey);
            try (ResultSet rs = statement.executeQuery()) {
                List<IpgUtPlP> result = new ArrayList<>();
                while (rs.next()) {
                    result.add(mapUtPlP(rs));
                }
                return List.copyOf(result);
            }
        } catch (SQLException | DatabaseConfigurationService.MissingConfigurationException exception) {
            throw new DaoException("Не удалось прочитать ipgUtPlP pl=" + plKey, exception);
        }
    }

    @Override
    public Optional<IpgUtPlP> findUtPlP(int plKey, int ipgpKey) {
        String sql = "SELECT iuplpKey, iuplpPl, iuplpIpgPn, iuplpLim, iuplpSubAg FROM "
                + q("ipgUtPlP")
                + " WHERE iuplpPl = ? AND iuplpIpgPn = ? AND iuplpSubAg IS NULL";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, plKey);
            statement.setInt(2, ipgpKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }
                return Optional.of(mapUtPlP(rs));
            }
        } catch (SQLException | DatabaseConfigurationService.MissingConfigurationException exception) {
            throw new DaoException(
                    "Не удалось найти ipgUtPlP pl=" + plKey + " pn=" + ipgpKey, exception);
        }
    }

    @Override
    public IpgUtPlP createUtPlP(int plKey, int ipgpKey) {
        String sql = "INSERT INTO " + q("ipgUtPlP")
                + " (iuplpPl, iuplpIpgPn) VALUES (?, ?)";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(
                     sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setInt(1, plKey);
            statement.setInt(2, ipgpKey);
            statement.executeUpdate();
            int key = readGeneratedKey(statement, "ipgUtPlP");
            log.info(() -> "createUtPlP key=" + key + " pl=" + plKey + " pn=" + ipgpKey);
            return findUtPlPByKey(connection, key).orElseThrow(
                    () -> new DaoException("ipgUtPlP не найден после insert key=" + key));
        } catch (SQLException | DatabaseConfigurationService.MissingConfigurationException exception) {
            throw new DaoException("Не удалось создать ipgUtPlP", exception);
        }
    }

    private Optional<IpgUtPlP> findUtPlPByKey(Connection connection, int key) throws SQLException {
        String sql = "SELECT iuplpKey, iuplpPl, iuplpIpgPn, iuplpLim, iuplpSubAg FROM "
                + q("ipgUtPlP") + " WHERE iuplpKey = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, key);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }
                return Optional.of(mapUtPlP(rs));
            }
        }
    }

    @Override
    public List<IpgUtPlPnLmMnCell> findLmMnByPlPn(int plPnKey) {
        String sql = "SELECT iuplpmKey, iuplpmPlPn, iuplpmStCost, iuplpmMn, iuplpmLim FROM "
                + q("ipgUtPlPnLmMn")
                + " WHERE iuplpmPlPn = ? ORDER BY iuplpmMn, iuplpmStCost";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, plPnKey);
            try (ResultSet rs = statement.executeQuery()) {
                List<IpgUtPlPnLmMnCell> result = new ArrayList<>();
                while (rs.next()) {
                    result.add(new IpgUtPlPnLmMnCell(
                            rs.getInt("iuplpmKey"),
                            rs.getInt("iuplpmPlPn"),
                            rs.getInt("iuplpmStCost"),
                            rs.getInt("iuplpmMn"),
                            rs.getBigDecimal("iuplpmLim")));
                }
                return List.copyOf(result);
            }
        } catch (SQLException | DatabaseConfigurationService.MissingConfigurationException exception) {
            throw new DaoException("Не удалось прочитать LmMn plPn=" + plPnKey, exception);
        }
    }

    @Override
    public void upsertLmMnCell(int plPnKey, int stCost, int month, BigDecimal lim) {
        boolean delete = lim == null || lim.compareTo(BigDecimal.ZERO) == 0;
        try (Connection connection = connectionFactory.createConnection()) {
            if (delete) {
                String del = "DELETE FROM " + q("ipgUtPlPnLmMn")
                        + " WHERE iuplpmPlPn = ? AND iuplpmStCost = ? AND iuplpmMn = ?";
                try (PreparedStatement statement = connection.prepareStatement(del)) {
                    statement.setInt(1, plPnKey);
                    statement.setInt(2, stCost);
                    statement.setInt(3, month);
                    statement.executeUpdate();
                }
                return;
            }
            String upd = "UPDATE " + q("ipgUtPlPnLmMn")
                    + " SET iuplpmLim = ? WHERE iuplpmPlPn = ? AND iuplpmStCost = ? AND iuplpmMn = ?";
            try (PreparedStatement statement = connection.prepareStatement(upd)) {
                statement.setBigDecimal(1, lim);
                statement.setInt(2, plPnKey);
                statement.setInt(3, stCost);
                statement.setInt(4, month);
                int updated = statement.executeUpdate();
                if (updated > 0) {
                    return;
                }
            }
            String ins = "INSERT INTO " + q("ipgUtPlPnLmMn")
                    + " (iuplpmPlPn, iuplpmStCost, iuplpmMn, iuplpmLim) VALUES (?, ?, ?, ?)";
            try (PreparedStatement statement = connection.prepareStatement(ins)) {
                statement.setInt(1, plPnKey);
                statement.setInt(2, stCost);
                statement.setInt(3, month);
                statement.setBigDecimal(4, lim);
                statement.executeUpdate();
            }
        } catch (SQLException | DatabaseConfigurationService.MissingConfigurationException exception) {
            throw new DaoException(
                    "Не удалось upsert LmMn plPn=" + plPnKey + " st=" + stCost + " m=" + month,
                    exception);
        }
    }

    @Override
    public void syncWideMonthsAndLim(
            int plPnKey,
            BigDecimal[] months212,
            BigDecimal limYear,
            BigDecimal[] quarters) {
        if (months212 == null || months212.length != 12) {
            throw new IllegalArgumentException("months212 must be length 12");
        }
        if (quarters == null || quarters.length != 4) {
            throw new IllegalArgumentException("quarters must be length 4");
        }
        String sql = "UPDATE " + q("ipgUtPlP") + " SET "
                + "iuplpLim=?, "
                + "iuplpQ1=?, iuplpM01=?, iuplpM02=?, iuplpM03=?, "
                + "iuplpQ2=?, iuplpM04=?, iuplpM05=?, iuplpM06=?, "
                + "iuplpQ3=?, iuplpM07=?, iuplpM08=?, iuplpM09=?, "
                + "iuplpQ4=?, iuplpM10=?, iuplpM11=?, iuplpM12=? "
                + "WHERE iuplpKey=?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            int i = 1;
            setDecimal(statement, i++, limYear);
            setDecimal(statement, i++, quarters[0]);
            setDecimal(statement, i++, months212[0]);
            setDecimal(statement, i++, months212[1]);
            setDecimal(statement, i++, months212[2]);
            setDecimal(statement, i++, quarters[1]);
            setDecimal(statement, i++, months212[3]);
            setDecimal(statement, i++, months212[4]);
            setDecimal(statement, i++, months212[5]);
            setDecimal(statement, i++, quarters[2]);
            setDecimal(statement, i++, months212[6]);
            setDecimal(statement, i++, months212[7]);
            setDecimal(statement, i++, months212[8]);
            setDecimal(statement, i++, quarters[3]);
            setDecimal(statement, i++, months212[9]);
            setDecimal(statement, i++, months212[10]);
            setDecimal(statement, i++, months212[11]);
            statement.setInt(i, plPnKey);
            statement.executeUpdate();
        } catch (SQLException | DatabaseConfigurationService.MissingConfigurationException exception) {
            throw new DaoException("Не удалось sync wide M*/Lim plPn=" + plPnKey, exception);
        }
    }

    private static IpgUtPl mapUtPl(ResultSet rs) throws SQLException {
        Date date = rs.getDate("iuplDate");
        return new IpgUtPl(
                rs.getInt("iuplKey"),
                rs.getNString("iuplNm"),
                date == null ? null : date.toLocalDate(),
                rs.getInt("iuplAg"),
                rs.getInt("iuplIpg"));
    }

    private static IpgUtPlP mapUtPlP(ResultSet rs) throws SQLException {
        int sub = rs.getInt("iuplpSubAg");
        Integer subAg = rs.wasNull() ? null : sub;
        return new IpgUtPlP(
                rs.getInt("iuplpKey"),
                rs.getInt("iuplpPl"),
                rs.getInt("iuplpIpgPn"),
                rs.getBigDecimal("iuplpLim"),
                subAg);
    }

    private static void setDecimal(PreparedStatement statement, int index, BigDecimal value)
            throws SQLException {
        if (value == null) {
            statement.setNull(index, Types.DECIMAL);
        } else {
            statement.setBigDecimal(index, value);
        }
    }

    private int readGeneratedKey(PreparedStatement statement, String label) throws SQLException {
        try (ResultSet keys = statement.getGeneratedKeys()) {
            if (!keys.next()) {
                throw new DaoException("Не получен IDENTITY для " + label);
            }
            return keys.getInt(1);
        }
    }
}
