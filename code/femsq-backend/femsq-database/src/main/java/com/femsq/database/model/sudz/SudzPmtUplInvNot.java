package com.femsq.database.model.sudz;

/**
 * Строка хвоста InvNot пакета платежей: ровно один договор, нет {@code cnInv},
 * номер уже встречается в {@code invNum} (ручной разбор / КСДСФ).
 * Live-выборка по {@code CnInvPmtUplTbl}, не чтение буфера {@code TblCnInv}.
 *
 * @param cntrPrtNum БУиРГ
 * @param cntrPrtName имя контрагента
 * @param cnName номер договора (NullИлиПусто)
 * @param cnKey ключ договора
 * @param cnInv номер СФ (NullИлиПусто)
 * @param invNumCount число различных inv с этим номером в {@code invNum}
 */
public record SudzPmtUplInvNot(
        Integer cntrPrtNum,
        String cntrPrtName,
        String cnName,
        int cnKey,
        String cnInv,
        Integer invNumCount
) {

    /**
     * @param cntrPrtNum БУиРГ
     * @param cntrPrtName имя
     * @param cnName договор
     * @param cnKey ключ
     * @param cnInv СФ
     * @param invNumCount счётчик номеров
     */
    public SudzPmtUplInvNot {
        cntrPrtName = blankToNull(cntrPrtName);
        cnName = blankToNull(cnName);
        cnInv = blankToNull(cnInv);
        if (cnKey <= 0) {
            throw new IllegalArgumentException("cnKey должен быть положительным: " + cnKey);
        }
    }

    private static String blankToNull(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }
}
