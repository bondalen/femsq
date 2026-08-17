package com.femsq.database.model;

import java.util.Objects;

/**
 * Номер договора ({@code ags.cnNum}) с отображаемым типом.
 *
 * @param cnnKey      PK
 * @param cnnNum      текст номера (может быть null)
 * @param cnnCn       FK → {@code cn.cn_key}
 * @param cnnType     FK → {@code cnNumType}
 * @param cnnTypeName имя типа (lookup), например «БУиРГ»
 * @param cnnNote     примечание
 */
public record CnNum(
        Integer cnnKey,
        String cnnNum,
        Integer cnnCn,
        Integer cnnType,
        String cnnTypeName,
        String cnnNote
) {

    public CnNum {
        Objects.requireNonNull(cnnKey, "cnnKey");
        Objects.requireNonNull(cnnCn, "cnnCn");
    }
}
