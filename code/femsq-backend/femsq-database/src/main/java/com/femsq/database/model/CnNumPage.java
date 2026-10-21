package com.femsq.database.model;

import java.util.List;

/**
 * Страница master-списка {@code ags.cnNum} (page с 1).
 *
 * @param items строки страницы
 * @param totalCount всего строк под фильтром
 * @param page номер страницы с 1
 * @param rowsPerPage размер страницы
 */
public record CnNumPage(
        List<CnNum> items,
        int totalCount,
        int page,
        int rowsPerPage
) {
}
