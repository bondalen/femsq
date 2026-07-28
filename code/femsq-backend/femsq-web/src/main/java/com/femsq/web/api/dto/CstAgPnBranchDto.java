package com.femsq.web.api.dto;

import java.time.LocalDate;

/**
 * DTO филиала САК {@code ags.cstAgPnBranch}.
 */
public record CstAgPnBranchDto(
        Integer cstapbKey,
        Integer cstapbCstAgPn,
        Integer cstapbBranch,
        LocalDate cstapbStart,
        LocalDate cstapbEnd,
        String branchName
) {
}
