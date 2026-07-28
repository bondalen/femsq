package com.femsq.web.api.dto;

import java.util.UUID;

/**
 * DTO агента на стройке {@code ags.cstAg}.
 */
public record CstAgDto(
        Integer cstaKey,
        Integer cstaAg,
        Integer cstaCst,
        UUID cstaOidOld,
        Integer cstaInvestor,
        String agentLabel
) {
}
