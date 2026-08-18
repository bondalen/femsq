package com.femsq.database.model.sudz;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;

/**
 * Контекст дерева КСДСФ: СГК простой ({@code cnInvAccntSmpl}…) и новая ДЗ ({@code invDbt}…).
 *
 * @param smpls карточки СГК по связям {@code cnInv} выбранного СФ
 * @param invDbts строки {@code sudz.invDbt} выбранного СФ
 */
public record SudzSfDoubleTreeDebt(
        List<AccntSmpl> smpls,
        List<InvDbt> invDbts
) {

    /**
     * {@code ags.cnInvAccntSmpl}.
     *
     * @param ciasKey ключ
     * @param ciasCnInv {@code cnInv.ciKey}
     * @param ciasAccnt ключ счёта ГК
     * @param accountNum номер счёта ГК
     * @param ciasCnSOrgSmpl smpl стороны
     * @param ciasNote заметка
     * @param ciasTimeOfEntry ввод
     * @param accounts карточки {@code cnInvAccnt}
     */
    public record AccntSmpl(
            int ciasKey,
            int ciasCnInv,
            Integer ciasAccnt,
            Integer accountNum,
            Integer ciasCnSOrgSmpl,
            String ciasNote,
            OffsetDateTime ciasTimeOfEntry,
            List<CnInvAccnt> accounts
    ) {
    }

    /**
     * {@code ags.cnInvAccnt}.
     *
     * @param ciaKey ключ
     * @param ciaCnSOrg {@code cn_s_org}
     * @param ciaName имя (костыль)
     * @param ciaNote заметка
     * @param ciaCnInvAccntSmpl родительский smpl
     * @param ciaTimeOfEntry ввод
     * @param debts срезы {@code cn_inv_dbt}
     */
    public record CnInvAccnt(
            int ciaKey,
            Integer ciaCnSOrg,
            String ciaName,
            String ciaNote,
            int ciaCnInvAccntSmpl,
            OffsetDateTime ciaTimeOfEntry,
            List<CnInvDbt> debts
    ) {
    }

    /**
     * Срез старой структуры {@code ags.cn_inv_dbt}.
     *
     * @param cnInvDbtKey ключ
     * @param dateStart дата образования
     * @param dateMaturity срок
     * @param debtType тип
     * @param dbtTtl сумма
     * @param dbtOverd просрочка
     * @param docBase основание
     * @param link ссылка
     * @param uplKey выгрузка
     * @param number номер в своде
     * @param mark метка
     * @param cidTimeOfEntry ввод
     */
    public record CnInvDbt(
            int cnInvDbtKey,
            LocalDate dateStart,
            LocalDate dateMaturity,
            String debtType,
            Double dbtTtl,
            Double dbtOverd,
            String docBase,
            String link,
            Integer uplKey,
            Integer number,
            Integer mark,
            OffsetDateTime cidTimeOfEntry
    ) {
    }

    /**
     * {@code sudz.invDbt}.
     *
     * @param idKey ключ
     * @param idInv СФ
     * @param idNum номер в выгрузке
     * @param idNote заметка
     * @param idTimeOfEntry ввод
     * @param links связки {@code invDbtDbt}
     */
    public record InvDbt(
            int idKey,
            int idInv,
            Integer idNum,
            String idNote,
            OffsetDateTime idTimeOfEntry,
            List<InvDbtDbt> links
    ) {
    }

    /**
     * {@code sudz.invDbtDbt}.
     *
     * @param iddKey ключ
     * @param iddInv СФ
     * @param iddDbt {@code Dbt}
     * @param iddInvDbt родительский {@code invDbt}
     * @param iddTimeOfEntry ввод
     * @param dbt карточка {@code Dbt}
     */
    public record InvDbtDbt(
            int iddKey,
            Integer iddInv,
            Integer iddDbt,
            Integer iddInvDbt,
            OffsetDateTime iddTimeOfEntry,
            Dbt dbt
    ) {
    }

    /**
     * {@code sudz.Dbt} + срезы {@code DbtValue}.
     *
     * @param dbtKey ключ
     * @param dbtNote заметка
     * @param values величины
     */
    public record Dbt(
            int dbtKey,
            String dbtNote,
            List<DbtValue> values
    ) {
    }

    /**
     * {@code sudz.DbtValue}.
     *
     * @param dvKey ключ
     * @param dvUpl выгрузка
     * @param dvTtl сумма
     * @param dvOverd просрочка
     * @param dvDateStart дата образования
     * @param dvDateMaturity срок
     * @param dvDocBase основание
     */
    public record DbtValue(
            int dvKey,
            Integer dvUpl,
            Double dvTtl,
            Double dvOverd,
            LocalDate dvDateStart,
            LocalDate dvDateMaturity,
            String dvDocBase
    ) {
    }
}
