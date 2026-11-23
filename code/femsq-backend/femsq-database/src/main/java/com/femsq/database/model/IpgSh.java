package com.femsq.database.model;

import java.util.Objects;

/**
 * Схема реализации пункта ИП ({@code ags.ipgSh}).
 */
public record IpgSh(int ipgsKey, String ipgsNm) {
    public IpgSh {
        Objects.requireNonNull(ipgsNm, "ipgsNm");
    }
}
