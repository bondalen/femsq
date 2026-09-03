package com.femsq.database.model;

/**
 * Добавление второго (и далее) номера к существующему договору.
 *
 * @param cnKey FK {@code ags.cn}
 * @param cnnNum текст номера (null → NULL в БД)
 * @param cnnType FK {@code cnNumType}, NOT NULL
 * @param note примечание cnNum
 */
public record CnNumCreate(
        int cnKey,
        String cnnNum,
        int cnnType,
        String note
) {
}
