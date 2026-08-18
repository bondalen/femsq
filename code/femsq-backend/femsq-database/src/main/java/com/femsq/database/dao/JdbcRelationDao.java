package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.relation.RelationCard;
import com.femsq.database.model.relation.RelationEdge;
import com.femsq.database.model.relation.RelationField;
import com.femsq.database.model.relation.RelationRow;
import com.femsq.database.model.relation.RelationTable;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.sql.Date;

/**
 * JDBC-чтение whitelist-таблиц и рёбер.
 */
public class JdbcRelationDao implements RelationDao {

    private static final Logger log = Logger.getLogger(JdbcRelationDao.class.getName());

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    /**
     * @param connectionFactory подключение
     * @param configurationService схема {@code ags}
     */
    public JdbcRelationDao(
            ConnectionFactory connectionFactory,
            DatabaseConfigurationService configurationService
    ) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
        this.configurationService = Objects.requireNonNull(configurationService, "configurationService");
    }

    @Override
    public Optional<RelationRow> findNode(RelationTable table, int id) {
        Objects.requireNonNull(table, "table");
        String sql = "SELECT " + selectList(table) + " FROM " + qualify(table) + " WHERE "
                + bracket(table.pk()) + " = ?";
        log.log(Level.FINE, "relationNode {0} id={1}", new Object[] {table.name(), id});
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, id);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }
                return Optional.of(mapRow(rs, table.pk()));
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "relationNode failed", exception);
            throw new DaoException("Не удалось прочитать " + table.name() + " id=" + id, exception);
        }
    }

    @Override
    public List<RelationRow> expand(RelationEdge edge, int fromId) {
        Objects.requireNonNull(edge, "edge");
        String sql = expandSql(edge);
        log.log(Level.FINE, "relationExpand {0} fromId={1}", new Object[] {edge.name(), fromId});
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, fromId);
            try (ResultSet rs = statement.executeQuery()) {
                List<RelationRow> rows = new ArrayList<>();
                while (rs.next()) {
                    rows.add(mapRow(rs, edge.to().pk()));
                }
                return List.copyOf(rows);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "relationExpand failed", exception);
            throw new DaoException("Не удалось раскрыть ребро " + edge.name() + " fromId=" + fromId, exception);
        }
    }

    private String expandSql(RelationEdge edge) {
        RelationTable to = edge.to();
        RelationTable from = edge.from();
        String toSelect = selectList(to, "t");
        if (edge.card() == RelationCard.ONE_TO_MANY) {
            if (edge.toJoin() == null || edge.toJoin().isBlank()) {
                throw new IllegalArgumentException("У 1:N ребра " + edge.name() + " нет toJoin");
            }
            return "SELECT " + toSelect + " FROM " + qualify(to) + " t WHERE t." + bracket(edge.toJoin()) + " = ?";
        }
        if (edge.fromJoin() == null || edge.fromJoin().isBlank()) {
            throw new IllegalArgumentException("У N:1 ребра " + edge.name() + " нет fromJoin");
        }
        return "SELECT " + toSelect + " FROM " + qualify(to) + " t INNER JOIN " + qualify(from)
                + " f ON f." + bracket(edge.fromJoin()) + " = t." + bracket(to.pk())
                + " WHERE f." + bracket(from.pk()) + " = ?";
    }

    private String selectList(RelationTable table) {
        return selectList(table, null);
    }

    private String selectList(RelationTable table, String alias) {
        String prefix = alias == null || alias.isBlank() ? "" : alias + ".";
        List<String> parts = new ArrayList<>();
        for (String column : table.columns()) {
            parts.add(prefix + bracket(column));
        }
        return String.join(", ", parts);
    }

    private String qualify(RelationTable table) {
        String configured = agsSchema();
        String schema = table.schema();
        if ("ags".equals(schema) && configured != null && !configured.isBlank()) {
            schema = configured;
        }
        return schema + "." + bracket(table.table());
    }

    private String agsSchema() {
        try {
            String schema = configurationService.loadConfig().schema();
            if (schema == null || schema.trim().isEmpty()) {
                return "ags";
            }
            return schema.trim();
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            log.log(Level.WARNING, "Нет конфигурации БД, схема ags", exception);
            return "ags";
        }
    }

    private static String bracket(String identifier) {
        return "[" + identifier + "]";
    }

    private static RelationRow mapRow(ResultSet rs, String pk) throws SQLException {
        int key = rs.getInt(pk);
        ResultSetMetaData meta = rs.getMetaData();
        List<RelationField> fields = new ArrayList<>();
        for (int i = 1; i <= meta.getColumnCount(); i++) {
            String name = meta.getColumnLabel(i);
            fields.add(new RelationField(name, stringify(rs.getObject(i))));
        }
        return new RelationRow(key, List.copyOf(fields));
    }

    private static String stringify(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Timestamp timestamp) {
            return timestamp.toInstant().toString();
        }
        if (value instanceof Date date) {
            return date.toLocalDate().format(DateTimeFormatter.ISO_LOCAL_DATE);
        }
        if (value instanceof BigDecimal decimal) {
            return decimal.stripTrailingZeros().toPlainString();
        }
        return String.valueOf(value);
    }
}
