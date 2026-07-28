package com.femsq.database.model;

import java.time.LocalDate;

/**
 * Строка списка Access {@code ralpRaCst} (отчёты аренды стройки).
 *
 * @param cstKey         стройка
 * @param ogaNm          подпись агента ({@code ogAgCs})
 * @param cstapIpgPnN    код САК
 * @param ralprKey       PK отчёта аренды
 * @param ralprNum       номер
 * @param ralprDate      дата
 * @param ralprCstAgPn   САК ({@code cstAgPn.cstapKey})
 * @param ralprOgSender  отправитель ({@code og.ogKey} или {@code ogNmF.onfKey})
 * @param ogNm           имя отправителя
 * @param auCnt          число строк {@code ralpRaAu}
 * @param hasReturned    есть ли Au с текстом возврата или статусом 3
 */
public record RalpRaCstListEntry(
        Integer cstKey,
        String ogaNm,
        String cstapIpgPnN,
        int ralprKey,
        String ralprNum,
        LocalDate ralprDate,
        Integer ralprCstAgPn,
        Integer ralprOgSender,
        String ogNm,
        int auCnt,
        boolean hasReturned
) {
}
