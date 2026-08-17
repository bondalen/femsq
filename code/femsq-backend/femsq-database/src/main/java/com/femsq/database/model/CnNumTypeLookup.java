package com.femsq.database.model;

/**
 * Lookup типа номера договора {@code cnNumType}.
 *
 * @param cnntKey PK
 * @param cnntName название (напр. «БУиРГ»)
 */
public record CnNumTypeLookup(
        int cnntKey,
        String cnntName
) {
}
