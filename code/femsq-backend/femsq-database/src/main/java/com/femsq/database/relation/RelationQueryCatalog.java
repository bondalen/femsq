package com.femsq.database.relation;

import com.femsq.database.model.relation.RelationQueryDefinition;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Whitelist именованных SELECT для {@code relationQuery}. SQL не уходит с клиента.
 */
public final class RelationQueryCatalog {

    /**
     * Контекст invDbtVar по слоту invDbt: человекочитаемая строка + FK для сверки.
     * Параметр {@code ?} = {@code invDbt.idKey}.
     */
    public static final String SUDZ_INV_DBT_VAR_CONTEXT_BY_SLOT = "sudz.invDbtVar.contextBySlot";

    /**
     * Точки {@code DbtValue} пары слот+var по мосту {@code invDbtDbtVar}.
     * Параметр {@code ?} = {@code invDbtDbtVar.iddvKey}.
     */
    public static final String SUDZ_DBT_VALUE_BY_SLOT_VAR_BRIDGE = "sudz.DbtValue.bySlotVarBridge";

    private static final Map<String, RelationQueryDefinition> QUERIES;

    static {
        Map<String, RelationQueryDefinition> queries = new LinkedHashMap<>();
        queries.put(
                SUDZ_INV_DBT_VAR_CONTEXT_BY_SLOT,
                new RelationQueryDefinition(
                        SUDZ_INV_DBT_VAR_CONTEXT_BY_SLOT,
                        """
                        SELECT TOP (50)
                          b.iddvKey,
                          v.idvvKey,
                          b.iddvInvDbt AS slotIdKey,
                          CAST(acc.account_num AS nvarchar(32)) AS accntNum,
                          cnn.cnnNumNull AS cnNumLabel,
                          invn.inNumNull AS invNumLabel,
                          og.ogNm AS orgName,
                          og.ogINN AS orgInn,
                          v.idvvCn_s_org AS cnSOrgKey,
                          CONVERT(varchar(10), o.csoCnDate, 23) AS cnSOrgDate,
                          v.idvvCnNum,
                          v.idvvInvNum,
                          v.idvvAccnt,
                          (
                            CAST(v.idvvKey AS nvarchar(20))
                            + N' · счёт ' + CAST(acc.account_num AS nvarchar(32))
                            + N' · дог. ' + ISNULL(cnn.cnnNumNull, N'—')
                            + N' · СФ ' + ISNULL(invn.inNumNull, N'—')
                            + N' · ' + ISNULL(og.ogNm, N'—')
                            + CASE WHEN og.ogINN IS NOT NULL AND LTRIM(RTRIM(CAST(og.ogINN AS nvarchar(64)))) <> N''
                                   THEN N' (ИНН ' + CAST(og.ogINN AS nvarchar(64)) + N')'
                                   ELSE N'' END
                            + N' · сторона '
                            + ISNULL(CONVERT(varchar(10), o.csoCnDate, 23), N'—')
                          ) AS summaryLine
                        FROM sudz.invDbtDbtVar AS b
                        INNER JOIN sudz.invDbtVar AS v ON v.idvvKey = b.iddvInvDbtVar
                        INNER JOIN ags.accnt AS acc ON acc.account_key = v.idvvAccnt
                        INNER JOIN ags.cnNum AS cnn ON cnn.cnnKey = v.idvvCnNum
                        INNER JOIN ags.invNum AS invn ON invn.inKey = v.idvvInvNum
                        INNER JOIN ags.cn_s_org AS o ON o.cn_s_org_key = v.idvvCn_s_org
                        INNER JOIN ags.cn_s_org_smpl AS m ON m.csosKey = o.csoCn_s_org_smpl
                        INNER JOIN ags.org_id AS i ON i.org_id_key = m.csosOrgId
                        INNER JOIN ags.og AS og ON og.ogKey = i.org
                        WHERE b.iddvInvDbt = ?
                        ORDER BY b.iddvKey
                        """,
                        "iddvKey"
                )
        );
        queries.put(
                SUDZ_DBT_VALUE_BY_SLOT_VAR_BRIDGE,
                new RelationQueryDefinition(
                        SUDZ_DBT_VALUE_BY_SLOT_VAR_BRIDGE,
                        """
                        SELECT TOP (100)
                          dv.dvKey,
                          dv.dvInvDbt,
                          dv.dvInvDbtVar,
                          dv.dvUpl,
                          dv.dvTtl,
                          dv.dvOverd,
                          dv.dvDateStart,
                          dv.dvDateMaturity,
                          u.upl_name AS uplName,
                          CONVERT(varchar(10), u.upl_date, 23) AS uplDate,
                          CONVERT(varchar(10), u.uplStatusOnDate, 23) AS uplStatusOnDate
                        FROM sudz.DbtValue AS dv
                        INNER JOIN sudz.invDbtDbtVar AS b
                          ON b.iddvInvDbt = dv.dvInvDbt
                         AND b.iddvInvDbtVar = dv.dvInvDbtVar
                        LEFT JOIN sudz.cn_inv_dbt_upl AS u ON u.upl_key = dv.dvUpl
                        WHERE b.iddvKey = ?
                          AND (dv.dvUpl IS NULL OR dv.dvUpl < 801 OR dv.dvUpl >= 910)
                          AND (
                            u.uplStatusOnDate IS NULL
                            OR NOT EXISTS (
                              SELECT 1
                              FROM sudz.DbtValue AS dv2
                              INNER JOIN sudz.cn_inv_dbt_upl AS u2 ON u2.upl_key = dv2.dvUpl
                              WHERE dv2.dvInvDbt = dv.dvInvDbt
                                AND dv2.dvInvDbtVar = dv.dvInvDbtVar
                                AND (dv2.dvUpl < 801 OR dv2.dvUpl >= 910)
                                AND u2.uplStatusOnDate = u.uplStatusOnDate
                                AND dv2.dvUpl > dv.dvUpl
                            )
                          )
                        ORDER BY u.uplStatusOnDate, dv.dvUpl, dv.dvKey
                        """,
                        "dvKey",
                        100
                )
        );
        QUERIES = Map.copyOf(queries);
    }

    private RelationQueryCatalog() {
    }

    /**
     * Запрос по id.
     *
     * @param id идентификатор JSON
     * @return определение
     */
    public static RelationQueryDefinition require(String id) {
        RelationQueryDefinition definition = QUERIES.get(id);
        if (definition == null) {
            throw new IllegalArgumentException("Неизвестный relationQuery: " + id);
        }
        return definition;
    }
}
