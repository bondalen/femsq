package com.femsq.web.api.dto;

import java.time.LocalDate;

/**
 * Правка карточки {@code cn}: {@code cn_date} / примечание / метка.
 * Не затрагивает {@code csoCnDate} сторон.
 */
public record CnUpdateRequest(
        LocalDate cnDate,
        String cnNote,
        Integer cnMark
) {
}
