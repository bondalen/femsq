package com.femsq.web.api.dto.sudz;

/**
 * Вход create/reuse {@code invDbtVar} для строки очереди двоящих.
 *
 * @param ciudKey ключ очереди
 * @param idvvCnNum {@code cnnKey}
 * @param idvvInvNum {@code inKey}
 * @param idvvAccnt счёт ГК
 * @param idvvCnSOrg {@code cn_s_org_key}
 */
public record EnsureSudzInvDbtVarForDoubleInput(
        int ciudKey,
        int idvvCnNum,
        int idvvInvNum,
        int idvvAccnt,
        int idvvCnSOrg
) {
}
