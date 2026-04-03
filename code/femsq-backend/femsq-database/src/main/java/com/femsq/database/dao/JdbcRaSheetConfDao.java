package com.femsq.database.dao;

import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaSheetConf;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC-реализация {@link RaSheetConfDao}.
 */
public class JdbcRaSheetConfDao implements RaSheetConfDao {

    private static final Logger log = Logger.getLogger(JdbcRaSheetConfDao.class.getName());
    private static final String TABLE_NAME = "ags.ra_sheet_conf";

    private final ConnectionFactory connectionFactory;

    public JdbcRaSheetConfDao(ConnectionFactory connectionFactory) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
    }

    @Override
    public List<RaSheetConf> findByFileType(int fileType) {
        String sql = "SELECT rsc_key, rsc_ft_key, rsc_sheet, rsc_stg_tbl, rsc_anchor, rsc_anchor_match, rsc_row_pattern, rsc_sign_whitelist "
                + "FROM " + TABLE_NAME + " WHERE rsc_ft_key = ? ORDER BY rsc_key";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, fileType);
            try (ResultSet resultSet = statement.executeQuery()) {
                List<RaSheetConf> result = new ArrayList<>();
                while (resultSet.next()) {
                    result.add(new RaSheetConf(
                            resultSet.getInt("rsc_key"),
                            resultSet.getInt("rsc_ft_key"),
                            resultSet.getNString("rsc_sheet"),
                            resultSet.getNString("rsc_stg_tbl"),
                            resultSet.getNString("rsc_anchor"),
                            resultSet.getString("rsc_anchor_match"),
                            resultSet.getNString("rsc_row_pattern"),
                            resultSet.getNString("rsc_sign_whitelist")
                    ));
                }
                return List.copyOf(result);
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to read ra_sheet_conf", exception);
            throw new DaoException("Не удалось загрузить конфигурацию листов для типа файла " + fileType, exception);
        }
    }
}
