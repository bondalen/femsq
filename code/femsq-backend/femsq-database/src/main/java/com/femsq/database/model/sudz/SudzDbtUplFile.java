package com.femsq.database.model.sudz;

/**
 * Шапка лаунчера загрузки свода ({@code CnInvDbtUplFile}).
 *
 * @param cidufKey ключ файла
 * @param cidufUpload ключ выгрузки ({@code upl_key})
 * @param cidufPath путь / имя файла
 * @param cidufFlLoad флаг «Обновлять» (писать в БД)
 * @param cidufFlTbl флаг «обнов. по исх?» (Excel → staging)
 * @param cidufLoadingProgress HTML-лог хода (в Access — RTF)
 */
public record SudzDbtUplFile(
        int cidufKey,
        int cidufUpload,
        String cidufPath,
        boolean cidufFlLoad,
        boolean cidufFlTbl,
        String cidufLoadingProgress
) {
}
