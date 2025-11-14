package com.femsq.web.api.dto;

import java.util.List;

/**
 * DTO для ответа с пагинацией.
 *
 * @param <T> тип элементов в списке
 */
public record PageResponse<T>(
        List<T> content,
        int totalElements,
        int totalPages,
        int page,
        int size
) {
    /**
     * Создает объект пагинации из списка и параметров.
     */
    public static <T> PageResponse<T> of(List<T> content, int page, int size, int totalElements) {
        int totalPages = size > 0 ? (int) Math.ceil((double) totalElements / size) : 0;
        return new PageResponse<>(content, totalElements, totalPages, page, size);
    }
}


