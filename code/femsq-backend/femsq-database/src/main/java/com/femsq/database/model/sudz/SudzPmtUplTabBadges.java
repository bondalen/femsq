package com.femsq.database.model.sudz;

/**
 * Счётчики вкладок экрана D для выбранного пакета (0077 / 1.1.3).
 * Грид КСДСФ и вкладка Sum_t этим типом не наполняются — только числа.
 *
 * @param cstNew строк очереди {@code cipuCacNot}
 * @param invNot хвост {@code cipuCn_CtptCnOneInvNot}: СФ без {@code cnInv} на единственном договоре
 * @param twoLoad строк шага {@code cipuCn_CtptCnOneInvTwoLoad} (СФ с ci×&gt;1)
 * @param sfOpen открытых строк {@code CnInvUplSfDouble}, привязанных к строкам Tbl этого пакета
 */
public record SudzPmtUplTabBadges(int cstNew, int invNot, int twoLoad, int sfOpen) {

    /**
     * @param cstNew стройки новые
     * @param invNot хвост InvNot
     * @param twoLoad TwoLoad
     * @param sfOpen open КСДСФ
     */
    public SudzPmtUplTabBadges {
        if (cstNew < 0 || invNot < 0 || twoLoad < 0 || sfOpen < 0) {
            throw new IllegalArgumentException("счётчики вкладок не могут быть отрицательными");
        }
    }
}
