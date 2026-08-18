package com.femsq.database.relation;

import com.femsq.database.model.relation.RelationCard;
import com.femsq.database.model.relation.RelationEdge;
import com.femsq.database.model.relation.RelationTable;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Whitelist таблиц и рёбер для GraphQL relation*. Срез 1: три ребра КСДСФ.
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

    private static final Map<String, RelationTable> TABLES = Map.of(
            INV_NUM.name(), INV_NUM,
            INV.name(), INV,
            CN_INV.name(), CN_INV,
            CN.name(), CN
    );

    private static final Map<String, RelationEdge> EDGES;

    static {
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
