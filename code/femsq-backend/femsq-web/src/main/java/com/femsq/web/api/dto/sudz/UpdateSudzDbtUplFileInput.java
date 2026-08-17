package com.femsq.web.api.dto.sudz;

/**
 * GraphQL input upsert шапки лаунчера ({@code CnInvDbtUplFile}).
 *
 * @param uplKey ключ выгрузки
 * @param path путь/имя файла; null — не менять (при insert — пустая строка)
 * @param flLoad флаг «Обновлять»; null — не менять (при insert — false)
 * @param flTbl флаг «обнов. по исх?»; null — не менять (при insert — false)
 */
public record UpdateSudzDbtUplFileInput(
        int uplKey,
        String path,
        Boolean flLoad,
        Boolean flTbl
) {
}
