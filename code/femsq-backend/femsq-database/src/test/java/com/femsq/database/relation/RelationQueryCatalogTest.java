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
        assertTrue(def.sql().contains("cnSOrgDate"));
        assertTrue(def.sql().contains("csoCnDate"));
    }

    @Test
    void dbtValueBySlotVarBridgeIsRegistered() {
        var def = RelationQueryCatalog.require(RelationQueryCatalog.SUDZ_DBT_VALUE_BY_SLOT_VAR_BRIDGE);
        assertEquals("dvKey", def.keyColumn());
        assertEquals(100, def.maxRows());
        assertTrue(def.sql().contains("uplStatusOnDate"));
        assertTrue(def.sql().contains("sudz.cn_inv_dbt_upl"));
        assertTrue(def.sql().contains("910"));
        assertTrue(def.sql().contains("iddvKey"));
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
