package com.femsq.database.model.sudz;

/**
 * Строка вкладки «стройки новые» (Access {@code CnInvPmtUplTbl_CstNew}).
 * Источник — {@code cipuCacNot}: уникальный {@code cacOrNull} пакета без пары в {@code ags.cstAgPn}.
 * {@code sh} = правые 6 символов; {@code ipCode} — такой же суффикс {@code cstapIpgPnN}, если он уже есть.
 * {@code pirIDnew} / {@code pirName} остаются пустыми: таблицы {@code tblPIR} в FishEye нет.
 *
 * @param cacOrNull нормализованный САК (11 символов)
 * @param sh правые 6 символов {@code cacOrNull}
 * @param ipCode совпавший суффикс {@code ags.cstAgPn.cstapIpgPnN} или null
 * @param pirIDnew ключ PIR или null
 * @param pirName имя PIR или null
 */
public record SudzPmtUplCstNew(
        String cacOrNull,
        String sh,
        String ipCode,
        String pirIDnew,
        String pirName
) {

    /**
     * @param cacOrNull САК
     * @param sh суффикс
     * @param ipCode код ИП или null
     * @param pirIDnew PIR или null
     * @param pirName имя PIR или null
     */
    public SudzPmtUplCstNew {
        if (cacOrNull == null || cacOrNull.isBlank()) {
            throw new IllegalArgumentException("cacOrNull обязателен");
        }
        cacOrNull = cacOrNull.trim();
        sh = sh == null ? "" : sh.trim();
        ipCode = blankToNull(ipCode);
        pirIDnew = blankToNull(pirIDnew);
        pirName = blankToNull(pirName);
    }

    private static String blankToNull(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }
}
