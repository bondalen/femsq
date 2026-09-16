package com.femsq.web.api.dto.sudz;

/**
 * GraphQL input upsert шапки лаунчера платежей ({@code CnInvPmtUplFile}).
 *
 * @param pmKey ключ пакета платежей
 * @param path путь/имя файла; null — не менять (при insert — пустая строка)
 * @param sheet имя листа; null — не менять (при insert — null)
 * @param flLoad флаг «Обновлять»; null — не менять (при insert — false)
 * @param flTbl флаг «обнов. по исх?»; null — не менять (при insert — false)
 */
public record UpdateSudzPmUplFileInput(
        int pmKey,
        String path,
        String sheet,
        Boolean flLoad,
        Boolean flTbl
) {
}
