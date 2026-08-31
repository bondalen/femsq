package com.femsq.database.model.sudz;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

/**
 * Строка очереди кандидатов P1 (multi-Dbt, путь 2): исчезновение {@code Dbt}
 * base yr → curr + sum-match ({@code sudz.CnInvUplDbtP1}).
 *
 * @param cip1Key ключ
 * @param cip1UnloadKey текущая выгрузка
 * @param cip1BaseUpl базовая выгрузка года ({@code yr.cn_inv_dbt_upl})
 * @param cip1DbtFile ключ File долгов
 * @param cip1DbtKey исчезнувший канон {@code Dbt}
 * @param cip1BaseSlotKey слот {@code invDbt} на base
 * @param cip1BaseIKey {@code ags.inv.iKey} base
 * @param cip1BaseCnNum номер договора base
 * @param cip1BaseInvNum номер СФ base
 * @param cip1MatchSum сумма для sum-match
 * @param cip1SumKind {@code ttl} | {@code overd}
 * @param cip1CandCidut кандидат Tbl (null — нет совпадения)
 * @param cip1CandIKey {@code iKey} кандидата
 * @param cip1CandCnNum номер договора кандидата
 * @param cip1CandInvNum номер СФ кандидата
 * @param cip1CandDebt сумма кандидата
 * @param cip1Reason {@code single} | {@code multi} | {@code none}
 * @param cip1ReasonDetail текст ({@code [queue.build]} …)
 * @param cip1Status {@code open} | {@code linked} | {@code deferred}
 * @param cip1StatusAt время смены статуса
 * @param cip1LinkedSlotKey {@code invDbt.idKey} после link
 */
public record SudzCnInvUplDbtP1(
        int cip1Key,
        int cip1UnloadKey,
        int cip1BaseUpl,
        Integer cip1DbtFile,
        int cip1DbtKey,
        int cip1BaseSlotKey,
        Integer cip1BaseIKey,
        String cip1BaseCnNum,
        String cip1BaseInvNum,
        BigDecimal cip1MatchSum,
        String cip1SumKind,
        Integer cip1CandCidut,
        Integer cip1CandIKey,
        String cip1CandCnNum,
        String cip1CandInvNum,
        BigDecimal cip1CandDebt,
        String cip1Reason,
        String cip1ReasonDetail,
        String cip1Status,
        OffsetDateTime cip1StatusAt,
        Integer cip1LinkedSlotKey
) {
}
