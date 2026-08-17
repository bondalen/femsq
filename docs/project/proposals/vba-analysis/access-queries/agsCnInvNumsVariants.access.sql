/*
 * Объект MS Access: сохранённый запрос agsCnInvNumsVariants
 *
 * Назначение: все варианты номеров СФ, связанных с договором через
 * cnInv → inv → invNum, сторона исполнитель (cn_s_type=2).
 * Для ciduCnExistInvNot достаточно join по cn_key + inNumNull → ciKey.
 *
 * Диалект: Microsoft Access SQL (Jet/ACE). Не исполнять как есть на SQL Server.
 *
 * Источник: снято из Access (чат 2026-08-15).
 *
 * lastUpdated: 2026-08-15
 */

SELECT
    ags_invNum.inKey,
    ags_invNum.inNum,
    ags_invNum.inNumNull,
    ags_inv.iKey,
    ags_inv.iDate,
    ags_inv.iDateNull,
    ags_cnInv.ciKey,
    ags_cn.cn_key,
    ags_cnNum.cnnNum,
    ags_cnNum.cnnNumNull,
    ags_cn_s.cn_s_type,
    ags_cn_s_org_smpl.csosKey,
    ags_cn_s_org.cn_s_org_key,
    ags_cn_s_org.csoAsbuID,
    ags_cn_s_org.csoCnDate,
    ags_cn_s_org.csoCnDateNull,
    ags_org_id.org_id_key,
    ags_org_id.org_id_value_l,
    ags_og.ogNm
FROM ((((((ags_cn
    INNER JOIN ((ags_inv
        INNER JOIN ags_invNum ON ags_inv.iKey = ags_invNum.inInv)
        INNER JOIN ags_cnInv ON ags_inv.iKey = ags_cnInv.ciInv)
        ON ags_cn.cn_key = ags_cnInv.ciCn)
    INNER JOIN ags_cnNum ON ags_cn.cn_key = ags_cnNum.cnnCn)
    INNER JOIN ags_cn_s ON ags_cn.cn_key = ags_cn_s.cn_key)
    INNER JOIN ags_cn_s_org_smpl ON ags_cn_s.cn_s_key = ags_cn_s_org_smpl.csosCn_s)
    INNER JOIN ags_cn_s_org ON ags_cn_s_org_smpl.csosKey = ags_cn_s_org.csoCn_s_org_smpl)
    INNER JOIN ags_org_id ON ags_cn_s_org_smpl.csosOrgId = ags_org_id.org_id_key)
    INNER JOIN ags_og ON ags_org_id.org = ags_og.ogKey
WHERE (((ags_cn_s.cn_s_type) = 2));
