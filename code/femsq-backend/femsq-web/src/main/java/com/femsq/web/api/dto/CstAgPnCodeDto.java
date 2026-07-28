package com.femsq.web.api.dto;

/**
 * DTO строки списка САК для формы поиска по коду.
 */
public record CstAgPnCodeDto(
        Integer cstapKey,
        String cstapIpgPnN,
        Integer cstapCsta,
        Integer cstaCst,
        String cstName
) {
}
