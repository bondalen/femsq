package com.femsq.web.api.dto;

/**
 * DTO представление типа файла {@code ags.ra_ft} для REST API.
 * Используется как lookup в UI (выпадающие списки).
 *
 * @param ftKey   идентификатор типа файла
 * @param ftName  название типа файла
 */
public record RaFtDto(
        Integer ftKey,
        String ftName
) {
}
