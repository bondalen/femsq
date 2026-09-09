package com.femsq.web.api.dto.sudz;

/**
 * Вход upsert {@code cnInvCmm} на {@code DbtValue} (S78.6).
 *
 * @param valueKey {@code dvKey}
 * @param cmmGrKey {@code cnicGroup}
 * @param cnicType 1 мероприятия, 8 куратор
 * @param text текст (пустой не удаляет строку)
 */
public record UpsertSudzDbtCanonCommentInput(
        int valueKey,
        int cmmGrKey,
        int cnicType,
        String text
) {
}
