package com.femsq.web.api.dto;

/**
 * DTO схемы структуры {@code stNet}.
 */
public record StNetworkFullDto(
        Integer stNetKey,
        Integer stNetType,
        String name,
        Integer rootKey
) {
}
