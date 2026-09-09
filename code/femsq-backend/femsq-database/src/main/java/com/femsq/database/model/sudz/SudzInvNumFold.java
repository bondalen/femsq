package com.femsq.database.model.sudz;

/**
 * Свёртка омоглифов номера СФ: латинская {@code A56} и кириллическая {@code А56}
 * должны находить одну запись ({@code inNumNull} в БД бывает в обеих раскладках).
 */
public final class SudzInvNumFold {

    /**
     * Пары «кириллица → латиница» для букв, неотличимых в номерах дел/СФ.
     */
    private static final char[][] CYR_TO_LATIN = {
        {'А', 'A'}, {'а', 'A'},
        {'В', 'B'},
        {'Е', 'E'}, {'е', 'E'},
        {'К', 'K'},
        {'М', 'M'},
        {'Н', 'H'},
        {'О', 'O'}, {'о', 'O'},
        {'Р', 'P'}, {'р', 'P'},
        {'С', 'C'}, {'с', 'C'},
        {'Т', 'T'},
        {'Х', 'X'}, {'х', 'X'}
    };

    private SudzInvNumFold() {
    }

    /**
     * Сворачивает омоглифы в строке фильтра или значения.
     *
     * @param raw исходная строка
     * @return свёрнутая строка; {@code null} как есть
     */
    public static String fold(String raw) {
        if (raw == null) {
            return null;
        }
        String out = raw;
        for (char[] pair : CYR_TO_LATIN) {
            out = out.replace(pair[0], pair[1]);
        }
        return out;
    }

    /**
     * SQL-выражение {@code REPLACE(...)} над колонкой, совместимое с MSSQL 2012.
     *
     * @param columnExpr выражение колонки ({@code inv.inNumNull})
     * @return вложенные REPLACE
     */
    public static String sqlFoldExpr(String columnExpr) {
        String sql = columnExpr;
        for (char[] pair : CYR_TO_LATIN) {
            sql = "REPLACE(" + sql + ", N'" + pair[0] + "', N'" + pair[1] + "')";
        }
        return sql;
    }
}
