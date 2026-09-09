package com.femsq.database.model.sudz;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Карточка канона Dbt со слотами (S78) и комментариями на {@code DbtValue} (S78.6).
 *
 * @param dbtKey ключ канона
 * @param slots слоты с мостом на канон
 * @param cmmYears год-варианты, в которые входят upl карточки
 */
public record SudzDbtCanonDetail(
        int dbtKey,
        List<SudzDbtCanonSlot> slots,
        List<SudzDbtCanonCmmYear> cmmYears
) {
    /**
     * Слот канона.
     *
     * @param slotKey {@code invDbt.idKey}
     * @param iKey СФ
     * @param idNum номер слота в СФ
     * @param varKey {@code invDbtVar}, если мост var есть
     * @param cnNum номер договора
     * @param invNum номер СФ
     * @param orgBuirg БУиРГ
     * @param csoDate дата стороны
     * @param accountKey ключ счёта
     * @param accountNum номер счёта
     * @param values Value по upl (новые сверху)
     */
    public record SudzDbtCanonSlot(
            int slotKey,
            int iKey,
            int idNum,
            Integer varKey,
            String cnNum,
            String invNum,
            Integer orgBuirg,
            LocalDate csoDate,
            Integer accountKey,
            Integer accountNum,
            List<SudzDbtCanonValue> values
    ) {
    }

    /**
     * Value на слоте.
     *
     * @param valueKey ключ
     * @param uplKey выгрузка
     * @param ttl сумма
     * @param overd просрочка
     * @param uplName имя выгрузки
     * @param uplDate дата выгрузки
     * @param uplStatusOnDate дата статуса среза
     * @param comments тексты {@code cnInvCmm} на этой Value (типы 1 и 8)
     */
    public record SudzDbtCanonValue(
            int valueKey,
            int uplKey,
            BigDecimal ttl,
            BigDecimal overd,
            String uplName,
            LocalDate uplDate,
            LocalDate uplStatusOnDate,
            List<SudzDbtCanonComment> comments
    ) {
    }

    /**
     * Комментарий на {@code DbtValue}.
     *
     * @param cmmKey {@code cnicKey}
     * @param valueKey {@code cnicDv}
     * @param cmmGrKey {@code cnicGroup}
     * @param cmmGrName имя группы
     * @param groupKind {@code official} / {@code new} / {@code other}
     * @param cnicType 1 мероприятия, 8 куратор
     * @param text текст
     */
    public record SudzDbtCanonComment(
            int cmmKey,
            int valueKey,
            int cmmGrKey,
            String cmmGrName,
            String groupKind,
            int cnicType,
            String text
    ) {
    }

    /**
     * Год-вариант с группами комментариев, пересекающий upl карточки.
     *
     * @param yrKey ключ года
     * @param yrVariant название
     * @param cmmGr {@code yr_CmmGr}
     * @param cmmGrName имя официальной группы
     * @param cmmGrNew {@code yr_CmmGr_New}
     * @param cmmGrNewName имя рабочей группы
     * @param uplKeys выгрузки года, которые есть на карточке
     */
    public record SudzDbtCanonCmmYear(
            int yrKey,
            String yrVariant,
            Integer cmmGr,
            String cmmGrName,
            Integer cmmGrNew,
            String cmmGrNewName,
            List<Integer> uplKeys
    ) {
    }
}
