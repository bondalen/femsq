package com.femsq.web.api.dto.sudz;

/**
 * Вход link слота для очереди двоящих долгов.
 *
 * @param ciudKey ключ очереди
 * @param idKey {@code invDbt.idKey}
 */
public record LinkSudzInvDbtDoubleInput(int ciudKey, int idKey) {
}
