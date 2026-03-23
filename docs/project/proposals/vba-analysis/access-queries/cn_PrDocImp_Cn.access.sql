/*
 * Объект MS Access: сохранённый запрос cn_PrDocImp_Cn
 *
 * Назначение: по уникальным комбинациям (номер договора из импорта, кредитор, supplierOrgId)
 * из cn_PrDocImp подтягивает данные договора с сервера (ags_cn / ags_cn_s / ags_cn_s_org_smpl / ags_cnNum)
 * для стороны cn_s_type = 2; учитывает число совпадений csosKey (cn_s_org_keyCount).
 *
 * Диалект: Microsoft Access SQL (Jet/ACE). Не исполнять как есть на SQL Server.
 *
 * Источник текста: cn_PrDocImp_Cn.txt (снято из Access).
 *
 * lastUpdated: 2026-03-21
 */

SELECT
    bbb.cnpdCnNum,
    bbb.textOfCreditor,
    bbb.supplierOrgId,
    bbb.cn_s_org_keyCount,
    aaa.cn_date,
    aaa.cn_key,
    aaa.cn_s_key,
    aaa.csosKey
FROM (
    SELECT
        x.cnpdCnNum,
        x.textOfCreditor,
        x.supplierOrgId,
        x.cn_s_org_keyCount
    FROM (
        SELECT
            z.cnpdCnNum,
            z.textOfCreditor,
            z.supplierOrgId,
            Count(y.csosKey) AS cn_s_org_keyCount
        FROM (
            SELECT
                cn_PrDocImp.cnpdCnNumNull AS cnpdCnNum,
                cn_PrDocImp.textOfCreditor,
                cn_PrDocImp.supplierOrgId
            FROM cn_PrDocImp
            GROUP BY
                cn_PrDocImp.cnpdCnNumNull,
                cn_PrDocImp.textOfCreditor,
                cn_PrDocImp.supplierOrgId
            ORDER BY cn_PrDocImp.cnpdCnNumNull
        ) AS z
            LEFT JOIN (
                SELECT
                    ags_cnNum.cnnNum AS cn_number,
                    cn.cn_date,
                    cn.cn_key,
                    cnS.cn_s_key,
                    cnSorS.csosKey,
                    cnSorS.csosOrgId AS org_id
                FROM (
                    (
                        ags_cn AS cn
                        INNER JOIN ags_cn_s AS cnS
                            ON cn.cn_key = cnS.cn_key
                    )
                    INNER JOIN ags_cn_s_org_smpl AS cnSorS
                        ON cnS.cn_s_key = cnSorS.csosCn_s
                )
                    INNER JOIN ags_cnNum
                        ON cn.cn_key = ags_cnNum.cnnCn
                WHERE (((cnS.cn_s_type) = 2))
            ) AS y
                ON (z.supplierOrgId = y.org_id)
                AND (z.cnpdCnNum = y.cn_number)
        GROUP BY
            z.cnpdCnNum,
            z.textOfCreditor,
            z.supplierOrgId
    ) AS x
) AS bbb
    LEFT JOIN (
        SELECT
            ags_cnNum.cnnNum AS cn_number,
            cn.cn_date,
            cn.cn_key,
            cnS.cn_s_key,
            cnSorS.csosKey,
            cnSorS.csosOrgId AS org_id
        FROM (
            (
                ags_cn AS cn
                INNER JOIN ags_cn_s AS cnS
                    ON cn.cn_key = cnS.cn_key
            )
            INNER JOIN ags_cn_s_org_smpl AS cnSorS
                ON cnS.cn_s_key = cnSorS.csosCn_s
        )
            INNER JOIN ags_cnNum
                ON cn.cn_key = ags_cnNum.cnnCn
        WHERE (((cnS.cn_s_type) = 2))
    ) AS aaa
        ON (bbb.cnpdCnNum = aaa.cn_number)
        AND (bbb.supplierOrgId = aaa.org_id);
