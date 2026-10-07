package com.femsq.web.api.graphql;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.exception.DaoException;
import java.sql.SQLException;
import org.junit.jupiter.api.Test;

/**
 * Проверка распознавания уникального ключа SQL Server.
 */
class SqlDuplicateKeyTest {

    @Test
    void matchesUniqueIndexInsideDaoException() {
        SQLException sql = new SQLException("duplicate key", "23000", 2601);
        assertTrue(SqlDuplicateKey.matches(new DaoException("Не удалось создать САК", sql)));
    }

    @Test
    void ignoresOtherSqlErrors() {
        SQLException sql = new SQLException("timeout", "HYT00", 0);
        assertFalse(SqlDuplicateKey.matches(new DaoException("Не удалось создать САК", sql)));
    }
}
