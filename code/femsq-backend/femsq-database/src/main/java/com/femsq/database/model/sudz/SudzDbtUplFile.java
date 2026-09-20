package com.femsq.database.model.sudz;

/**
 * Шапка лаунчера загрузки свода ({@code CnInvDbtUplFile}).
 *
 * @param cidufKey ключ файла
 * @param cidufUpload ключ выгрузки ({@code upl_key})
 * @param cidufPath путь / имя файла
 * @param cidufFlLoad флаг «Обновлять» (писать в БД)
 * @param cidufFlTbl флаг «обнов. по исх?» (Excel → staging)
 * @param cidufLoadingProgress HTML-лог хода воронки (в Access — RTF)
 * @param cidufOpsProgress HTML-журнал операций шапки (H6 и др.; не затирает ход воронки)
 */
public record SudzDbtUplFile(
        int cidufKey,
        int cidufUpload,
        String cidufPath,
        boolean cidufFlLoad,
        boolean cidufFlTbl,
        String cidufLoadingProgress,
        String cidufOpsProgress
) {
}
