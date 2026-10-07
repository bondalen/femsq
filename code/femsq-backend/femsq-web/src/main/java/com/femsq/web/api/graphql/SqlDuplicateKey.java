package com.femsq.web.api.graphql;

import java.sql.SQLException;

/**
 * Распознаёт нарушение уникального ключа SQL Server в цепочке {@link Throwable}.
 */
public final class SqlDuplicateKey {

    private static final int UNIQUE_INDEX = 2601;
    private static final int UNIQUE_CONSTRAINT = 2627;

    private SqlDuplicateKey() {
    }

    /**
     * @param error исключение DAO или обёртка над ним
     * @return {@code true}, если причина — ошибка 2601 или 2627
     */
    public static boolean matches(Throwable error) {
        Throwable current = error;
        while (current != null) {
            if (current instanceof SQLException sql) {
                int code = sql.getErrorCode();
                if (code == UNIQUE_INDEX || code == UNIQUE_CONSTRAINT) {
                    return true;
                }
            }
            current = current.getCause();
        }
        return false;
    }
}
