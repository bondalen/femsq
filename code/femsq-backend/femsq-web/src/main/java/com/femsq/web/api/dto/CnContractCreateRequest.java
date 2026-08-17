package com.femsq.web.api.dto;

import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

/**
 * Создание договора: обязателен только тип номера; остальное — по наличию.
 * {@code csoCnDate} — дата из свода в {@code cn_s_org}; {@code cn_date} не заполняется.
 */
public record CnContractCreateRequest(
        String cnnNum,
        LocalDate csoCnDate,
        @NotNull Integer cnnType,
        Integer csosOrgId,
        String note
) {
}
