package com.femsq.database.relation;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.femsq.database.model.relation.RelationCard;
import org.junit.jupiter.api.Test;

class RelationEdgeCatalogTest {

    @Test
    void slice1EdgesAreRegistered() {
        assertEquals("inv", RelationEdgeCatalog.requireEdge("invNum.inv").to().name());
        assertEquals(RelationCard.ONE_TO_MANY, RelationEdgeCatalog.requireEdge("inv.cnInv").card());
        assertEquals("cn_key", RelationEdgeCatalog.requireEdge("cnInv.cn").to().pk());
    }

    @Test
    void unknownEdgeFails() {
        IllegalArgumentException error = assertThrows(
                IllegalArgumentException.class,
                () -> RelationEdgeCatalog.requireEdge("inv.invDbt")
        );
        assertEquals("Неизвестное ребро relationExpand: inv.invDbt", error.getMessage());
    }

    @Test
    void unknownTableFails() {
        IllegalArgumentException error = assertThrows(
                IllegalArgumentException.class,
                () -> RelationEdgeCatalog.requireTable("invDbt")
        );
        assertEquals("Неизвестная таблица relationNode: invDbt", error.getMessage());
    }
}
