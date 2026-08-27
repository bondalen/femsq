package com.femsq.database.model;

import java.util.List;

/**
 * Страница связей {@code cnInv} по договору (page с 1).
 */
public record CnInvPage(
        List<CnInvListItem> items,
        int totalCount,
        int page,
        int rowsPerPage
) {
}
