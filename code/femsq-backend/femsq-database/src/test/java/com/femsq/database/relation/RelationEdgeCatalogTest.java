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
        assertEquals("ciInv", RelationEdgeCatalog.requireEdge("cnInv.inv").fromJoin());
        assertEquals(RelationCard.MANY_TO_ONE, RelationEdgeCatalog.requireEdge("cnInv.inv").card());
        assertEquals(RelationCard.ONE_TO_MANY, RelationEdgeCatalog.requireEdge("cn.cnInv").card());
        assertEquals("upl", RelationEdgeCatalog.requireEdge("cid.upl").to().name());
        assertEquals("invDbt", RelationEdgeCatalog.requireEdge("inv.invDbt").to().name());
        assertEquals("dv", RelationEdgeCatalog.requireEdge("invDbt.dv").to().name());
        assertEquals("invDbt", RelationEdgeCatalog.requireEdge("dv.invDbt").to().name());
        assertEquals("cia", RelationEdgeCatalog.requireEdge("cid.cia").to().name());
        assertEquals("cias", RelationEdgeCatalog.requireEdge("cia.cias").to().name());
        assertEquals("cnInv", RelationEdgeCatalog.requireEdge("cias.cnInv").to().name());
        assertEquals("invNum", RelationEdgeCatalog.requireEdge("inv.invNum").to().name());
        assertEquals("idd", RelationEdgeCatalog.requireEdge("dbt.idd").to().name());
        assertEquals("invDbt", RelationEdgeCatalog.requireEdge("idd.invDbt").to().name());
        assertEquals("inv", RelationEdgeCatalog.requireEdge("invDbt.inv").to().name());
        assertEquals("idvv", RelationEdgeCatalog.requireEdge("iddv.idvv").to().name());
        assertEquals("iddv", RelationEdgeCatalog.requireEdge("invDbt.iddv").to().name());
        assertEquals("og", RelationEdgeCatalog.requireEdge("orgId.og").to().name());
        assertEquals("csosOrgId", RelationEdgeCatalog.requireEdge("smpl.orgId").fromJoin());
    }

    @Test
    void unknownEdgeFails() {
        IllegalArgumentException error = assertThrows(
                IllegalArgumentException.class,
                () -> RelationEdgeCatalog.requireEdge("no.such.edge")
        );
        assertEquals("Неизвестное ребро relationExpand: no.such.edge", error.getMessage());
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
