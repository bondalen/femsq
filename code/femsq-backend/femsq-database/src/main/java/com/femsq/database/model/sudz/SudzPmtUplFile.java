package com.femsq.database.model.sudz;

/**
 * Шапка лаунчера загрузки платежей ({@code CnInvPmtUplFile}).
 *
 * @param cipufKey ключ файла
 * @param cipufUpload ключ пакета ({@code cn_inv_pm_key})
 * @param cipufPath путь / имя файла
 * @param cipufFlLoad флаг «Обновлять» (писать в БД)
 * @param cipufFlTbl флаг «обнов. по исх?» (Excel → staging)
 * @param cipufLoadingProgress HTML-лог хода (как у dbt; в Access — RTF)
 * @param cipufSheet имя листа Excel (у pmt нет FileSh)
 */
public record SudzPmtUplFile(
        int cipufKey,
        int cipufUpload,
        String cipufPath,
        boolean cipufFlLoad,
        boolean cipufFlTbl,
        String cipufLoadingProgress,
        String cipufSheet
) {
}
