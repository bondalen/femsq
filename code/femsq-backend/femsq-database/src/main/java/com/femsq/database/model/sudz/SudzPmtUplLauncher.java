package com.femsq.database.model.sudz;

/**
 * Карточка лаунчера загрузки платежей для выбранного пакета.
 *
 * @param upl реестр {@code cn_inv_pm_upl}
 * @param file шапка {@code CnInvPmtUplFile} (после ensure всегда есть)
 */
public record SudzPmtUplLauncher(
        SudzPmUplLookup upl,
        SudzPmtUplFile file
) {
}
