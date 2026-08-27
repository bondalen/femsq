package com.femsq.web.api.dto;

import java.util.List;

/**
 * GraphQL-страница связей {@code cnInv} по договору.
 */
public record CnInvPageDto(
        List<CnInvDto> items,
        int totalCount,
        int page,
        int rowsPerPage
) {
}
