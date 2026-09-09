package com.femsq.database.model.sudz;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

/**
 * Омоглифы номера СФ.
 */
class SudzInvNumFoldTest {

    @Test
    void cyrillicAFoldsToLatin() {
        assertEquals("A56-69288", SudzInvNumFold.fold("А56-69288"));
    }

    @Test
    void latinAUnchanged() {
        assertEquals("A56-69288", SudzInvNumFold.fold("A56-69288"));
    }

    @Test
    void nullPassthrough() {
        assertNull(SudzInvNumFold.fold(null));
    }

    @Test
    void sqlExprNestsReplace() {
        String sql = SudzInvNumFold.sqlFoldExpr("inv.inNumNull");
        assertTrue(sql.startsWith("REPLACE("));
        assertTrue(sql.contains("inv.inNumNull"));
        assertTrue(sql.contains("N'А'"));
    }
}
