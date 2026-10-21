package com.femsq.web.api.dto;

import java.util.List;

/**
 * GraphQL-страница master-списка номеров договоров.
 *
 * @param items строки страницы
 * @param totalCount всего строк под фильтром
 * @param page номер страницы с 1
 * @param rowsPerPage размер страницы
 */
public record CnNumPageDto(
        List<CnNumDto> items,
        int totalCount,
        int page,
        int rowsPerPage
) {
}
