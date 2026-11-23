package com.femsq.database.model;

/**
 * Привязка пункта ИП к узлу структуры ({@code ags.ipgStPn}).
 */
public record IpgStPn(
        int ipgspKey,
        int ipgspPn,
        int ipgspSt,
        String stName
) {
}
