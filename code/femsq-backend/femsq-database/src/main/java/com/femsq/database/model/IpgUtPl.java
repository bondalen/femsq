package com.femsq.database.model;

import java.time.LocalDate;

/**
 * План агента на ИП ({@code ags.ipgUtPl}).
 *
 * @param iuplKey PK
 * @param iuplNm  наименование
 * @param iuplDate дата
 * @param iuplAg  агент ({@code ogAg.ogaKey})
 * @param iuplIpg ИП ({@code ipg.ipgKey})
 */
public record IpgUtPl(
        int iuplKey,
        String iuplNm,
        LocalDate iuplDate,
        int iuplAg,
        int iuplIpg
) {
}
