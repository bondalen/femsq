package com.femsq.database.model.sudz;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * Сборка дерева {@code cst → cstAg → cstAgPn} по хвосту из 6 символов.
 */
class SudzPmtUplCstMatchTest {

    @Test
    void rejectsSuffixOtherThanSixCharacters() {
        assertThrows(IllegalArgumentException.class, () -> SudzPmtUplCstMatch.requireCodeSuffix("67"));
        assertThrows(IllegalArgumentException.class, () -> SudzPmtUplCstMatch.requireCodeSuffix(null));
        assertEquals("006707", SudzPmtUplCstMatch.requireCodeSuffix(" 006707 "));
    }

    @Test
    void groupsAgentsAndMarksOnlyMatchingCodes() {
        List<SudzPmtUplCstMatch> tree = SudzPmtUplCstMatch.assemble(List.of(
                new SudzPmtUplCstMatch.Flat(10, "Север", 1, "Газпром", "051", 100, "051-2006707"),
                new SudzPmtUplCstMatch.Flat(10, "Север", 1, "Газпром", "051", 101, "051-1999999"),
                new SudzPmtUplCstMatch.Flat(10, "Север", 2, "  ", null, null, null),
                new SudzPmtUplCstMatch.Flat(20, "Юг", 3, "Инвест", "014", 200, "014-2006707")
        ), "006707");

        assertEquals(2, tree.size());
        SudzPmtUplCstMatch north = tree.get(0);
        assertEquals(10, north.cstKey());
        assertEquals(2, north.agents().size());
        assertEquals("Газпром", north.agents().get(0).agentLabel());
        assertEquals("051", north.agents().get(0).ogaCode());
        assertEquals(2, north.agents().get(0).points().size());
        assertTrue(north.agents().get(0).points().get(0).sameSuffix());
        assertFalse(north.agents().get(0).points().get(1).sameSuffix());
        assertNull(north.agents().get(1).agentLabel());
        assertTrue(north.agents().get(1).points().isEmpty());
        assertTrue(tree.get(1).agents().get(0).points().get(0).sameSuffix());
    }
}
