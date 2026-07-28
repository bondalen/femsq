package com.femsq.web.api.dto;

import java.time.LocalDate;

/**
 * DTO строки {@code ags.fnRRcList} для вкладки «отчёты».
 */
public record CstRaListEntryDto(
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
        Double rasTotal,
        Double rasWork,
        Double rasEquip,
        Double rasOthers,
        String raArrived,
        LocalDate raArrivedDate,
        String raReturned,
        LocalDate raReturnedDate,
        String raSent,
        LocalDate raSentDate
) {
}
