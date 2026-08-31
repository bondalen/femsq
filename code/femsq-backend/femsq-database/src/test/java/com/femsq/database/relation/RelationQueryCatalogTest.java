package com.femsq.database.relation;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class RelationQueryCatalogTest {

    @Test
    void invDbtVarContextBySlotIsRegistered() {
        var def = RelationQueryCatalog.require(RelationQueryCatalog.SUDZ_INV_DBT_VAR_CONTEXT_BY_SLOT);
        assertEquals("iddvKey", def.keyColumn());
        assertTrue(def.sql().contains("summaryLine"));
        assertTrue(def.sql().contains("invDbtDbtVar"));
    }

    @Test
    void unknownQueryFails() {
        IllegalArgumentException error = assertThrows(
                IllegalArgumentException.class,
                () -> RelationQueryCatalog.require("no.such.query")
        );
        assertEquals("Неизвестный relationQuery: no.such.query", error.getMessage());
    }
}
