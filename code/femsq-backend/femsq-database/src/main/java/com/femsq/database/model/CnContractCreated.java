package com.femsq.database.model;

/**
 * Результат создания договора.
 * Ключи стороны null, если исполнитель не задан.
 *
 * @param cnKey     {@code cn.cn_key}
 * @param cnnKey    {@code cnNum.cnnKey}
 * @param cnSKey    {@code cn_s.cn_s_key} или null
 * @param csosKey   {@code cn_s_org_smpl.csosKey} или null
 * @param cnSOrgKey {@code cn_s_org.cn_s_org_key} или null
 */
public record CnContractCreated(
        int cnKey,
        int cnnKey,
        Integer cnSKey,
        Integer csosKey,
        Integer cnSOrgKey
) {
}
