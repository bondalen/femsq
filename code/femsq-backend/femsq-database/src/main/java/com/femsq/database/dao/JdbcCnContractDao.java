package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.CnContractCreate;
import com.femsq.database.model.CnContractCreated;
import com.femsq.database.model.CnNumTypeLookup;
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
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC: создание договора с исполнителем одной транзакцией.
 */
public class JdbcCnContractDao implements CnContractDao {

    private static final Logger log = Logger.getLogger(JdbcCnContractDao.class.getName());

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcCnContractDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
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
            log.log(Level.WARNING, "Configuration missing for cn contract create, fallback ags.", exception);
            return "ags.";
        }
    }

    @Override
    public CnContractCreated createWithPerformer(CnContractCreate input) {
        Objects.requireNonNull(input, "input");
        if (input.cnnType() <= 0) {
            throw new IllegalArgumentException("Тип номера обязателен (cnNum.cnnType NOT NULL)");
        }
        String numRaw = input.cnnNum() == null ? "" : input.cnnNum().trim();
        String numOrNull = numRaw.isEmpty() ? null : numRaw;
        Integer orgId = input.csosOrgId();
        if (orgId != null && orgId <= 0) {
            orgId = null;
        }

        String prefix = schemaPrefix();
        Timestamp now = Timestamp.valueOf(LocalDateTime.now());
        String note = input.note();
        // Как Access CnNotLoad: дата из свода → только csoCnDate; cn_date при создании всегда NULL.
        LocalDate csoCnDate = input.csoCnDate();

        log.log(Level.INFO, "Creating cn (+party?) num={0} type={1} orgId={2} csoCnDate={3}",
                new Object[]{numOrNull, input.cnnType(), orgId, csoCnDate});

        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                int cnKey;
                String insertCn = "INSERT INTO " + prefix + "cn (cn_date, cn_note, cnTimeOfEntry) VALUES (?, ?, ?)";
                try (PreparedStatement statement = connection.prepareStatement(insertCn, Statement.RETURN_GENERATED_KEYS)) {
                    statement.setNull(1, Types.DATE);
                    if (note == null || note.isBlank()) {
                        statement.setNull(2, Types.NVARCHAR);
                    } else {
                        statement.setNString(2, note.trim());
                    }
                    statement.setTimestamp(3, now);
                    statement.executeUpdate();
                    cnKey = readGeneratedKey(statement, "Не удалось получить cn_key");
                }

                int cnnKey;
                String insertNum = "INSERT INTO " + prefix + "cnNum (cnnNum, cnnCn, cnnType, cnnNote, cnnTimeOfEntry) "
                        + "VALUES (?, ?, ?, ?, ?)";
                try (PreparedStatement statement = connection.prepareStatement(insertNum, Statement.RETURN_GENERATED_KEYS)) {
                    if (numOrNull == null) {
                        statement.setNull(1, Types.NVARCHAR);
                    } else {
                        statement.setNString(1, numOrNull);
                    }
                    statement.setInt(2, cnKey);
                    statement.setInt(3, input.cnnType());
                    if (note == null || note.isBlank()) {
                        statement.setNull(4, Types.NVARCHAR);
                    } else {
                        statement.setNString(4, note.trim());
                    }
                    statement.setTimestamp(5, now);
                    statement.executeUpdate();
                    cnnKey = readGeneratedKey(statement, "Не удалось получить cnnKey");
                }

                Integer cnSKey = null;
                Integer csosKey = null;
                Integer cnSOrgKey = null;

                if (orgId != null) {
                    try (PreparedStatement statement = connection.prepareStatement(
                            "INSERT INTO " + prefix + "cn_s (cn_key, cn_s_type) VALUES (?, 2)",
                            Statement.RETURN_GENERATED_KEYS)) {
                        statement.setInt(1, cnKey);
                        statement.executeUpdate();
                        cnSKey = readGeneratedKey(statement, "Не удалось получить cn_s_key");
                    }

                    try (PreparedStatement statement = connection.prepareStatement(
                            "INSERT INTO " + prefix + "cn_s_org_smpl (csosCn_s, csosOrgId, csosTimeOfEntry) VALUES (?, ?, ?)",
                            Statement.RETURN_GENERATED_KEYS)) {
                        statement.setInt(1, cnSKey);
                        statement.setInt(2, orgId);
                        statement.setTimestamp(3, now);
                        statement.executeUpdate();
                        csosKey = readGeneratedKey(statement, "Не удалось получить csosKey");
                    }

                    if (csoCnDate != null) {
                        try (PreparedStatement statement = connection.prepareStatement(
                                "INSERT INTO " + prefix + "cn_s_org (csoCn_s_org_smpl, csoTimeOfEntry, csoCnDate) VALUES (?, ?, ?)",
                                Statement.RETURN_GENERATED_KEYS)) {
                            statement.setInt(1, csosKey);
                            statement.setTimestamp(2, now);
                            statement.setDate(3, Date.valueOf(csoCnDate));
                            statement.executeUpdate();
                            cnSOrgKey = readGeneratedKey(statement, "Не удалось получить cn_s_org_key");
                        }
                    } else {
                        try (PreparedStatement statement = connection.prepareStatement(
                                "INSERT INTO " + prefix + "cn_s_org (csoCn_s_org_smpl, csoTimeOfEntry) VALUES (?, ?)",
                                Statement.RETURN_GENERATED_KEYS)) {
                            statement.setInt(1, csosKey);
                            statement.setTimestamp(2, now);
                            statement.executeUpdate();
                            cnSOrgKey = readGeneratedKey(statement, "Не удалось получить cn_s_org_key");
                        }
                    }
                }

                connection.commit();
                return new CnContractCreated(cnKey, cnnKey, cnSKey, csosKey, cnSOrgKey);
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось создать договор", exception);
        }
    }

    @Override
    public List<CnNumTypeLookup> findNumTypes() {
        String sql = "SELECT cnntKey, cnntName FROM " + schemaPrefix() + "cnNumType ORDER BY cnntKey";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet rs = statement.executeQuery()) {
            List<CnNumTypeLookup> rows = new ArrayList<>();
            while (rs.next()) {
                rows.add(new CnNumTypeLookup(rs.getInt("cnntKey"), rs.getNString("cnntName")));
            }
            return List.copyOf(rows);
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось прочитать cnNumType", exception);
        }
    }

    @Override
    public int countByCnnNum(String cnnNum) {
        String raw = cnnNum == null ? "" : cnnNum.trim();
        String sql;
        if (raw.isEmpty()) {
            sql = "SELECT COUNT(*) FROM " + schemaPrefix() + "cnNum "
                    + "WHERE cnnNum IS NULL OR LTRIM(RTRIM(cnnNum)) = N''";
        } else {
            sql = "SELECT COUNT(*) FROM " + schemaPrefix() + "cnNum WHERE LTRIM(RTRIM(cnnNum)) = ?";
        }
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            if (!raw.isEmpty()) {
                statement.setNString(1, raw);
            }
            try (ResultSet rs = statement.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось посчитать совпадения cnnNum", exception);
        }
    }

    private static int readGeneratedKey(PreparedStatement statement, String errorMessage) throws SQLException {
        try (ResultSet keys = statement.getGeneratedKeys()) {
            if (keys.next()) {
                return keys.getInt(1);
            }
        }
        throw new DaoException(errorMessage);
    }
}
