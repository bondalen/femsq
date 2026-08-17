package com.femsq.database.model.sudz;

/**
 * Результат INSERT одной строки {@code CnNotLoad} (при {@code countCnName = 1}).
 *
 * @param cnKey {@code ags.cn.cn_key}
 * @param cnnKey {@code ags.cnNum.cnnKey}
 * @param cnSKey {@code ags.cn_s.cn_s_key}
 * @param csosKey {@code ags.cn_s_org_smpl.csosKey}
 * @param cnSOrgKey {@code ags.cn_s_org.cn_s_org_key}
 */
public record SudzDbtUplCnNotLoadInserted(
        int cnKey,
        int cnnKey,
        int cnSKey,
        int csosKey,
        int cnSOrgKey
) {
}
