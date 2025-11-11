package com.femsq.database.dao;

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
    private static final String TABLE_NAME = "ags_test.og";

    private final ConnectionFactory connectionFactory;

    public JdbcOgDao(ConnectionFactory connectionFactory) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
    }

    @Override
    public Optional<Og> findById(int ogKey) {
        String sql = "SELECT ogKey, ogNm, ogNmOf, ogNmFl, ogTxt, ogINN, ogKPP, ogOGRN, ogOKPO, ogOE, ogRgTaxType "
                + "FROM " + TABLE_NAME + " WHERE ogKey = ?";
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
                + TABLE_NAME + " ORDER BY ogKey";
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
    public Og create(Og organization) {
        Objects.requireNonNull(organization, "organization");
        String sql = "INSERT INTO " + TABLE_NAME + " (ogNm, ogNmOf, ogNmFl, ogTxt, ogINN, ogKPP, ogOGRN, ogOKPO, ogOE, ogRgTaxType) "
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
        String sql = "UPDATE " + TABLE_NAME
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
        String sql = "DELETE FROM " + TABLE_NAME + " WHERE ogKey = ?";
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
