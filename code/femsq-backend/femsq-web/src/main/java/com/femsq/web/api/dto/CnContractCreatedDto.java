package com.femsq.web.api.dto;

/**
 * Результат {@code createCnContract}. Ключи стороны null без исполнителя.
 */
public record CnContractCreatedDto(
        Integer cnKey,
        Integer cnnKey,
        Integer cnSKey,
        Integer csosKey,
        Integer cnSOrgKey
) {
}
