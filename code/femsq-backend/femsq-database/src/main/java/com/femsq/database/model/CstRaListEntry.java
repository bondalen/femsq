package com.femsq.database.model;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Objects;

/**
 * Строка перечня отчётов/изменений стройки ({@code ags.fnRRcList(@cstKey)}).
 *
 * @param yyyy            год периода
 * @param mNum            номер месяца
 * @param p               подпись периода
 * @param cstaKey         ключ агента на стройке
 * @param cstaAg          ключ агента {@code ogAgCs}
 * @param cstaCst         ключ стройки
 * @param ogaNm           имя агента
 * @param cstapKey        ключ САК
 * @param cstapIpgPnN     код САК
 * @param raKey           ключ базового отчёта {@code ags.ra}
 * @param raNum           номер отчёта
 * @param raDate          дата отчёта
 * @param raType          тип отчёта
 * @param raChKey         ключ изменения ({@code null} — базовый отчёт)
 * @param raChNum         номер изменения
 * @param raChDate        дата изменения
 * @param raOrgSender     ключ отправителя
 * @param ogNm            имя отправителя
 * @param rasTotal        сумма всего (latest)
 * @param rasWork         СМР
 * @param rasEquip        оборудование
 * @param rasOthers       прочее
 * @param raArrived       поступил (номер)
 * @param raArrivedDate   дата поступления
 * @param raReturned      возвращён
 * @param raReturnedDate  дата возврата
 * @param raSent          направлен
 * @param raSentDate      дата направления
 */
public record CstRaListEntry(
        Integer yyyy,
        Integer mNum,
        String p,
        Integer cstaKey,
        Integer cstaAg,
        Integer cstaCst,
        String ogaNm,
        Integer cstapKey,
        String cstapIpgPnN,
        Integer raKey,
        String raNum,
        LocalDate raDate,
        String raType,
        Integer raChKey,
        String raChNum,
        LocalDate raChDate,
        Integer raOrgSender,
        String ogNm,
        BigDecimal rasTotal,
        BigDecimal rasWork,
        BigDecimal rasEquip,
        BigDecimal rasOthers,
        String raArrived,
        LocalDate raArrivedDate,
        String raReturned,
        LocalDate raReturnedDate,
        String raSent,
        LocalDate raSentDate
) {

    public CstRaListEntry {
        Objects.requireNonNull(raKey, "raKey");
    }

    /**
     * @return {@code true}, если строка — базовый отчёт (не изменение)
     */
    public boolean isBaseReport() {
        return raChKey == null;
    }
}
