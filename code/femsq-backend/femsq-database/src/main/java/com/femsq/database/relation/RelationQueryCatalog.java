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
