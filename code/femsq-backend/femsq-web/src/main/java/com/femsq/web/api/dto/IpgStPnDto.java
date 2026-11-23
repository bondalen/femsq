package com.femsq.web.api.dto;

/**
 * DTO привязки пункта к узлу структуры.
 */
public record IpgStPnDto(
        Integer ipgspKey,
        Integer ipgspPn,
        Integer ipgspSt,
        String stName
) {
}
