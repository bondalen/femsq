package com.femsq.database.model.sudz;

/**
 * Строка TwoLoad пакета платежей: номер СФ из Excel уже связан с более чем одним
 * {@code cnInv} в домене. Apply воронки намеренно закрыт (S69); разбор — КСДСФ.
 * Live-выборка по {@code CnInvPmtUplTbl}.
 *
 * @param cnInv номер СФ (NullИлиПусто)
 * @param cntrPrtNum БУиРГ из строк пакета (MAX)
 * @param cntrPrtName имя контрагента (MAX)
 * @param ciCount число различных {@code ciKey}
 */
public record SudzPmtUplTwoLoad(
        String cnInv,
        Integer cntrPrtNum,
        String cntrPrtName,
        int ciCount
) {

    /**
     * @param cnInv СФ
     * @param cntrPrtNum БУиРГ
     * @param cntrPrtName имя
     * @param ciCount число ci
     */
    public SudzPmtUplTwoLoad {
        cnInv = blankToNull(cnInv);
        cntrPrtName = blankToNull(cntrPrtName);
        if (ciCount < 2) {
            throw new IllegalArgumentException("ciCount TwoLoad должен быть ≥2: " + ciCount);
        }
    }

    private static String blankToNull(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }
}
