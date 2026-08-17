package com.femsq.database.model;

import java.time.LocalDate;

/**
 * Параметры ручного создания договора (экран «Договоры»).
 * Обязателен только {@code cnnType} ({@code cnNum.cnnType} NOT NULL).
 * Номер/дата/исполнитель — по наличию; без исполнителя создаются только {@code cn}+{@code cnNum}.
 * Дата из свода пишется в {@code csoCnDate}; {@code cn.cn_date} при создании всегда NULL (как Access).
 *
 * @param cnnNum номер (null/пусто → NULL в БД; такие уже есть)
 * @param csoCnDate дата для org-слота исполнителя (null = отсутствует)
 * @param cnnType тип номера (обязателен, обычно 1 = БУиРГ)
 * @param csosOrgId {@code org_id_key} исполнителя или null
 * @param note примечание
 */
public record CnContractCreate(
        String cnnNum,
        LocalDate csoCnDate,
        int cnnType,
        Integer csosOrgId,
        String note
) {
}
