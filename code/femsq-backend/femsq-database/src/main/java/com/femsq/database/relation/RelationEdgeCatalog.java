package com.femsq.database.relation;

import com.femsq.database.model.relation.RelationCard;
import com.femsq.database.model.relation.RelationEdge;
import com.femsq.database.model.relation.RelationTable;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Whitelist таблиц и рёбер для GraphQL relation*. Полный каталог КСДСФ / Договоров (v1).
 */
public final class RelationEdgeCatalog {

    private static final RelationTable INV_NUM = table(
            "invNum",
            "ags",
            "invNum",
            "inKey",
            List.of("inKey", "inNum", "inInv", "inNumNull", "inNote", "inTimeOfEntry")
    );
    private static final RelationTable INV = table(
            "inv",
            "ags",
            "inv",
            "iKey",
            List.of("iKey", "iNum", "iDate", "iNote", "iTimeOfEntry", "iDateNull", "iName")
    );
    private static final RelationTable CN_INV = table(
            "cnInv",
            "ags",
            "cnInv",
            "ciKey",
            List.of("ciKey", "ciCn", "ciInv", "ciNote", "ciMark", "ciTimeOfEntry")
    );
    private static final RelationTable CN = table(
            "cn",
            "ags",
            "cn",
            "cn_key",
            List.of("cn_key", "cn_number", "cn_date", "cn_note", "cnMark", "cnTimeOfEntry", "cnName")
    );
    private static final RelationTable CN_NUM = table(
            "cnNum",
            "ags",
            "cnNum",
            "cnnKey",
            List.of("cnnKey", "cnnNum", "cnnCn", "cnnType", "cnnNote", "cnnTimeOfEntry", "cnnNumNull")
    );
    private static final RelationTable CN_S = table(
            "cn_s",
            "ags",
            "cn_s",
            "cn_s_key",
            List.of("cn_s_key", "cn_key", "cn_s_type")
    );
    private static final RelationTable SMPL = table(
            "smpl",
            "ags",
            "cn_s_org_smpl",
            "csosKey",
            List.of("csosKey", "csosCn_s", "csosOrgId", "csosTimeOfEntry")
    );
    private static final RelationTable ORG = table(
            "org",
            "ags",
            "cn_s_org",
            "cn_s_org_key",
            List.of(
                    "cn_s_org_key",
                    "date_beg",
                    "date_end",
                    "csoAsbuID",
                    "csoCnDate",
                    "csoCn_s_org_smpl",
                    "csoCnDateNull",
                    "csoTimeOfEntry"
            )
    );
    private static final RelationTable ORG_ID = table(
            "orgId",
            "ags",
            "org_id",
            "org_id_key",
            List.of(
                    "org_id_key",
                    "org",
                    "org_id_type",
                    "org_id_value_l",
                    "org_id_value_t",
                    "org_id_value_t_ext"
            )
    );
    private static final RelationTable OG = table(
            "og",
            "ags",
            "og",
            "ogKey",
            List.of(
                    "ogKey",
                    "ogNm",
                    "ogNmOf",
                    "ogNmFl",
                    "ogTxt",
                    "ogINN",
                    "ogKPP",
                    "ogOGRN",
                    "ogOKPO",
                    "ogOE",
                    "ogRgTaxType"
            )
    );
    private static final RelationTable CIAS = table(
            "cias",
            "ags",
            "cnInvAccntSmpl",
            "ciasKey",
            List.of("ciasKey", "ciasCnInv", "ciasAccnt", "ciasCn_s_org_smpl", "ciasNote", "ciasTimeOfEntry")
    );
    private static final RelationTable CIA = table(
            "cia",
            "ags",
            "cnInvAccnt",
            "ciaKey",
            List.of("ciaKey", "ciaCn_s_org", "ciaName", "ciaNote", "ciaCnInvAccntSmpl", "ciaTimeOfEntry", "ciaNameNull")
    );
    private static final RelationTable CID = table(
            "cid",
            "ags",
            "cn_inv_dbt",
            "cn_inv_dbt_key",
            List.of(
                    "cn_inv_dbt_key",
                    "cn_inv_date_start",
                    "cn_inv_date_maturity",
                    "debt_type",
                    "dbt_ttl",
                    "dbt_overd",
                    "doc_base",
                    "link",
                    "cn_inv_dbt_upl",
                    "number",
                    "mark",
                    "cidCnInvAccntCtpt",
                    "cidTimeOfEntry"
            )
    );
    private static final RelationTable UPL = table(
            "upl",
            "ags",
            "cn_inv_dbt_upl",
            "upl_key",
            List.of("upl_key", "uplNmCs", "upl_date", "upl_name", "uplStatusOnDate")
    );
    private static final RelationTable INV_DBT = table(
            "invDbt",
            "sudz",
            "invDbt",
            "idKey",
            List.of("idKey", "idInv", "idNum", "idNote", "idTimeOfEntry")
    );
    private static final RelationTable IDD = table(
            "idd",
            "sudz",
            "invDbtDbt",
            "iddKey",
            List.of("iddKey", "iddInv", "iddDbt", "iddInvDbt", "iddTimeOfEntry")
    );
    private static final RelationTable DBT = table(
            "dbt",
            "sudz",
            "Dbt",
            "dbtKey",
            List.of("dbtKey", "dbtNote", "dbtTimeOfEntry")
    );
    private static final RelationTable DV = table(
            "dv",
            "sudz",
            "DbtValue",
            "dvKey",
            List.of(
                    "dvKey",
                    "dvDbt",
                    "dvInvDbtVar",
                    "dvUpl",
                    "dvTtl",
                    "dvOverd",
                    "dvDateStart",
                    "dvDateMaturity",
                    "dvDocBase",
                    "dvTimeOfEntry"
            )
    );

    private static final Map<String, RelationTable> TABLES;

    private static final Map<String, RelationEdge> EDGES;

    static {
        Map<String, RelationTable> tables = new LinkedHashMap<>();
        tables.put(INV_NUM.name(), INV_NUM);
        tables.put(INV.name(), INV);
        tables.put(CN_INV.name(), CN_INV);
        tables.put(CN.name(), CN);
        tables.put(CN_NUM.name(), CN_NUM);
        tables.put(CN_S.name(), CN_S);
        tables.put(SMPL.name(), SMPL);
        tables.put(ORG.name(), ORG);
        tables.put(ORG_ID.name(), ORG_ID);
        tables.put(OG.name(), OG);
        tables.put(CIAS.name(), CIAS);
        tables.put(CIA.name(), CIA);
        tables.put(CID.name(), CID);
        tables.put(UPL.name(), UPL);
        tables.put(INV_DBT.name(), INV_DBT);
        tables.put(IDD.name(), IDD);
        tables.put(DBT.name(), DBT);
        tables.put(DV.name(), DV);
        TABLES = Map.copyOf(tables);

        Map<String, RelationEdge> edges = new LinkedHashMap<>();
        edges.put(
                "invNum.inv",
                new RelationEdge("invNum.inv", INV_NUM, INV, "inInv", null, RelationCard.MANY_TO_ONE)
        );
        edges.put(
                "inv.cnInv",
                new RelationEdge("inv.cnInv", INV, CN_INV, null, "ciInv", RelationCard.ONE_TO_MANY)
        );
        edges.put(
                "cnInv.cn",
                new RelationEdge("cnInv.cn", CN_INV, CN, "ciCn", null, RelationCard.MANY_TO_ONE)
        );
        edges.put(
                "cn.cnNum",
                new RelationEdge("cn.cnNum", CN, CN_NUM, null, "cnnCn", RelationCard.ONE_TO_MANY)
        );
        edges.put(
                "cn.cn_s",
                new RelationEdge("cn.cn_s", CN, CN_S, null, "cn_key", RelationCard.ONE_TO_MANY)
        );
        edges.put(
                "cn_s.smpl",
                new RelationEdge("cn_s.smpl", CN_S, SMPL, null, "csosCn_s", RelationCard.ONE_TO_MANY)
        );
        edges.put(
                "smpl.org",
                new RelationEdge("smpl.org", SMPL, ORG, null, "csoCn_s_org_smpl", RelationCard.ONE_TO_MANY)
        );
        edges.put(
                "smpl.orgId",
                new RelationEdge("smpl.orgId", SMPL, ORG_ID, "csosOrgId", null, RelationCard.MANY_TO_ONE)
        );
        edges.put(
                "orgId.og",
                new RelationEdge("orgId.og", ORG_ID, OG, "org", null, RelationCard.MANY_TO_ONE)
        );
        edges.put(
                "og.orgId",
                new RelationEdge("og.orgId", OG, ORG_ID, null, "org", RelationCard.ONE_TO_MANY)
        );
        edges.put(
                "cnInv.cias",
                new RelationEdge("cnInv.cias", CN_INV, CIAS, null, "ciasCnInv", RelationCard.ONE_TO_MANY)
        );
        edges.put(
                "cias.cia",
                new RelationEdge("cias.cia", CIAS, CIA, null, "ciaCnInvAccntSmpl", RelationCard.ONE_TO_MANY)
        );
        edges.put(
                "cia.cid",
                new RelationEdge("cia.cid", CIA, CID, null, "cidCnInvAccntCtpt", RelationCard.ONE_TO_MANY)
        );
        edges.put(
                "cid.upl",
                new RelationEdge("cid.upl", CID, UPL, "cn_inv_dbt_upl", null, RelationCard.MANY_TO_ONE)
        );
        edges.put(
                "inv.invDbt",
                new RelationEdge("inv.invDbt", INV, INV_DBT, null, "idInv", RelationCard.ONE_TO_MANY)
        );
        edges.put(
                "invDbt.idd",
                new RelationEdge("invDbt.idd", INV_DBT, IDD, null, "iddInvDbt", RelationCard.ONE_TO_MANY)
        );
        edges.put(
                "idd.dbt",
                new RelationEdge("idd.dbt", IDD, DBT, "iddDbt", null, RelationCard.MANY_TO_ONE)
        );
        edges.put(
                "dbt.dv",
                new RelationEdge("dbt.dv", DBT, DV, null, "dvDbt", RelationCard.ONE_TO_MANY)
        );
        EDGES = Map.copyOf(edges);
    }

    private RelationEdgeCatalog() {
    }

    /**
     * Таблица по имени JSON.
     *
     * @param name {@code invNum}
     * @return таблица
     */
    public static RelationTable requireTable(String name) {
        RelationTable table = TABLES.get(name);
        if (table == null) {
            throw new IllegalArgumentException("Неизвестная таблица relationNode: " + name);
        }
        return table;
    }

    /**
     * Ребро по имени JSON.
     *
     * @param name {@code invNum.inv}
     * @return ребро
     */
    public static RelationEdge requireEdge(String name) {
        RelationEdge edge = EDGES.get(name);
        if (edge == null) {
            throw new IllegalArgumentException("Неизвестное ребро relationExpand: " + name);
        }
        return edge;
    }

    private static RelationTable table(String name, String schema, String table, String pk, List<String> columns) {
        return new RelationTable(name, schema, table, pk, List.copyOf(columns));
    }
}
