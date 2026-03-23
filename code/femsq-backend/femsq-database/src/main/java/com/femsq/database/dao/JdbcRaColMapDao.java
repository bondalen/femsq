package com.femsq.database.dao;

import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaColMap;
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
 * JDBC-реализация {@link RaColMapDao}.
 */
public class JdbcRaColMapDao implements RaColMapDao {

    private static final Logger log = Logger.getLogger(JdbcRaColMapDao.class.getName());
    private static final String TABLE_NAME = "ags.ra_col_map";

    private final ConnectionFactory connectionFactory;

    public JdbcRaColMapDao(ConnectionFactory connectionFactory) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
    }

    @Override
    public List<RaColMap> findBySheetConfKey(int sheetConfKey) {
        String sql = "SELECT rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, "
                + "rcm_xl_hdr_pri, rcm_xl_match, rcm_required "
                + "FROM " + TABLE_NAME + " WHERE rcm_rsc_key = ? ORDER BY rcm_tbl_col_ord, rcm_xl_hdr_pri, rcm_key";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, sheetConfKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                List<RaColMap> result = new ArrayList<>();
                while (resultSet.next()) {
                    result.add(new RaColMap(
                            resultSet.getInt("rcm_key"),
                            resultSet.getInt("rcm_rsc_key"),
                            resultSet.getNString("rcm_tbl_col"),
                            resultSet.getInt("rcm_tbl_col_ord"),
                            resultSet.getNString("rcm_xl_hdr"),
                            resultSet.getInt("rcm_xl_hdr_pri"),
                            resultSet.getString("rcm_xl_match"),
                            resultSet.getBoolean("rcm_required")
                    ));
                }
                return List.copyOf(result);
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to read ra_col_map", exception);
            throw new DaoException("Не удалось загрузить маппинг колонок для конфигурации " + sheetConfKey, exception);
        }
    }
}
