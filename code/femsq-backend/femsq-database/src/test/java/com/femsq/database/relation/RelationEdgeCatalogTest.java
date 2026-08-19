package com.femsq.database.relation;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.femsq.database.model.relation.RelationCard;
import org.junit.jupiter.api.Test;

class RelationEdgeCatalogTest {

    @Test
    void ksdsfEdgesAreRegistered() {
        assertEquals("inv", RelationEdgeCatalog.requireEdge("invNum.inv").to().name());
        assertEquals(RelationCard.ONE_TO_MANY, RelationEdgeCatalog.requireEdge("inv.cnInv").card());
        assertEquals("cn_key", RelationEdgeCatalog.requireEdge("cnInv.cn").to().pk());
        assertEquals(RelationCard.ONE_TO_MANY, RelationEdgeCatalog.requireEdge("cn.cnInv").card());
        assertEquals("upl", RelationEdgeCatalog.requireEdge("cid.upl").to().name());
        assertEquals("invDbt", RelationEdgeCatalog.requireEdge("inv.invDbt").to().name());
        assertEquals("dv", RelationEdgeCatalog.requireEdge("dbt.dv").to().name());
        assertEquals("og", RelationEdgeCatalog.requireEdge("orgId.og").to().name());
        assertEquals("csosOrgId", RelationEdgeCatalog.requireEdge("smpl.orgId").fromJoin());
    }

    @Test
    void unknownEdgeFails() {
        IllegalArgumentException error = assertThrows(
                IllegalArgumentException.class,
                () -> RelationEdgeCatalog.requireEdge("inv.invNum")
        );
        assertEquals("Неизвестное ребро relationExpand: inv.invNum", error.getMessage());
    }

    @Test
    void unknownTableFails() {
        IllegalArgumentException error = assertThrows(
                IllegalArgumentException.class,
                () -> RelationEdgeCatalog.requireTable("accnt")
        );
        assertEquals("Неизвестная таблица relationNode: accnt", error.getMessage());
    }
}
