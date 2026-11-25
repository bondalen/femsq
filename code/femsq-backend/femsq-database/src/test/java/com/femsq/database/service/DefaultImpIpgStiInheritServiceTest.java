package com.femsq.database.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.dao.ImpIpgLoadDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.ImpIpgLoad;
import com.femsq.database.model.ImpIpgRow;
import com.femsq.database.model.ImpIpgStagingDraft;
import com.femsq.database.model.ImpIpgStiInheritResult;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Unit-тесты наследования sti L←S (§3.2.2).
 */
class DefaultImpIpgStiInheritServiceTest {

    private StubLoadDao loadDao;
    private ImpIpgStiInheritService service;

    @BeforeEach
    void setUp() {
        loadDao = new StubLoadDao();
        service = new DefaultImpIpgStiInheritService(loadDao);
    }

    @Test
    void evaluateReadyWhenAllLeavesInheritFromSection() {
        loadDao.load = sampleLoad(8, 27);
        loadDao.rows = List.of(
                section(1, 10, null),
                leaf(2, 11, 1),
                leaf(3, 12, 1));

        ImpIpgStiInheritResult result = service.evaluate(8);

        assertTrue(result.ready());
        assertEquals(2, result.leafCount());
        assertEquals(2, result.readyCount());
        assertEquals(0, result.holeCount());
        assertTrue(result.holes().isEmpty());
        assertEquals(10, result.readyLeaves().get(0).resolvedStiKey());
        assertEquals(10, result.readyLeaves().get(1).resolvedStiKey());
    }

    @Test
    void evaluateReportsHoleWhenParentStiMissing() {
        loadDao.load = sampleLoad(8, 27);
        loadDao.rows = List.of(
                section(1, null, null),
                leaf(2, 11, 1));

        ImpIpgStiInheritResult result = service.evaluate(8);

        assertFalse(result.ready());
        assertEquals(1, result.holeCount());
        assertEquals(DefaultImpIpgStiInheritService.HOLE_PARENT_STI_MISSING,
                result.holes().get(0).holeReason());
    }

    @Test
    void evaluateReportsHoleWhenNoParent() {
        loadDao.load = sampleLoad(8, 27);
        loadDao.rows = List.of(leaf(2, 11, null));

        ImpIpgStiInheritResult result = service.evaluate(8);

        assertFalse(result.ready());
        assertEquals(DefaultImpIpgStiInheritService.HOLE_NO_PARENT,
                result.holes().get(0).holeReason());
    }

    @Test
    void evaluateReportsHoleWhenParentMissing() {
        loadDao.load = sampleLoad(8, 27);
        loadDao.rows = List.of(leaf(2, 11, 999));

        ImpIpgStiInheritResult result = service.evaluate(8);

        assertEquals(DefaultImpIpgStiInheritService.HOLE_PARENT_MISSING,
                result.holes().get(0).holeReason());
    }

    @Test
    void evaluateReportsHoleWhenParentNotSection() {
        loadDao.load = sampleLoad(8, 27);
        loadDao.rows = List.of(
                leaf(1, 10, null),
                leaf(2, 11, 1));

        ImpIpgStiInheritResult result = service.evaluate(8);

        assertTrue(result.holes().stream()
                .anyMatch(h -> h.rowId() == 2
                        && DefaultImpIpgStiInheritService.HOLE_PARENT_NOT_SECTION.equals(h.holeReason())));
    }

    @Test
    void evaluateFailsWhenNoLeaves() {
        loadDao.load = sampleLoad(8, 27);
        loadDao.rows = List.of(section(1, 10, null));

        ImpIpgStiInheritResult result = service.evaluate(8);

        assertFalse(result.ready());
        assertTrue(result.errors().stream().anyMatch(e -> e.contains("нет листьев")));
    }

    @Test
    void evaluateFailsWhenLoadMissing() {
        loadDao.load = null;
        ImpIpgStiInheritResult result = service.evaluate(404);
        assertFalse(result.ready());
        assertTrue(result.errors().stream().anyMatch(e -> e.contains("не найдена")));
    }

    @Test
    void assertReadyThrowsWhenHoles() {
        loadDao.load = sampleLoad(8, 27);
        loadDao.rows = List.of(leaf(2, 11, null));

        DaoException ex = assertThrows(DaoException.class, () -> service.assertReady(8));
        assertTrue(ex.getMessage().contains("Наследование sti"));
    }

    @Test
    void leafOwnStiKeyIgnoredUsesParentOnly() {
        loadDao.load = sampleLoad(8, 27);
        // L с «своим» iiStiKey — всё равно берём sti родителя S
        loadDao.rows = List.of(
                section(1, 42, null),
                new ImpIpgRow(2, 8, 11, "L", "leaf", 1, 999, "{}"));

        ImpIpgStiInheritResult result = service.evaluate(8);

        assertTrue(result.ready());
        assertEquals(42, result.readyLeaves().get(0).resolvedStiKey());
    }

    private static ImpIpgLoad sampleLoad(int key, int ipg) {
        return new ImpIpgLoad(key, ipg, "sql_0", "/tmp/x.xlsx", null, LocalDateTime.now());
    }

    private static ImpIpgRow section(int key, Integer sti, Integer parent) {
        return new ImpIpgRow(key, 8, key, "S", "sec-" + key, parent, sti, null);
    }

    private static ImpIpgRow leaf(int key, int rowNo, Integer parent) {
        return new ImpIpgRow(key, 8, rowNo, "L", "leaf-" + key, parent, null, "{}");
    }

    private static final class StubLoadDao implements ImpIpgLoadDao {
        private ImpIpgLoad load;
        private List<ImpIpgRow> rows = new ArrayList<>();

        @Override
        public Optional<ImpIpgLoad> findLoadByKey(int iilKey) {
            return Optional.ofNullable(load);
        }

        @Override
        public List<ImpIpgLoad> findLoadsByIpg(int ipgKey) {
            return List.of();
        }

        @Override
        public ImpIpgLoad insertLoad(int ipgKey, String name, String filePath, String note) {
            throw new UnsupportedOperationException();
        }

        @Override
        public ImpIpgLoad updateLoad(int iilKey, String name, String filePath, String note) {
            throw new UnsupportedOperationException();
        }

        @Override
        public boolean deleteLoad(int iilKey) {
            return false;
        }

        @Override
        public Optional<ImpIpgRow> findRowByKey(int iiKey) {
            return Optional.empty();
        }

        @Override
        public List<ImpIpgRow> findRowsByLoad(int iilKey) {
            return rows;
        }

        @Override
        public List<ImpIpgRow> findStructureRowsByLoad(int iilKey) {
            return List.of();
        }

        @Override
        public ImpIpgRow insertRow(
                int loadKey, int rowNo, String rowKind, String text,
                Integer parentKey, Integer stiKey, String ctx) {
            throw new UnsupportedOperationException();
        }

        @Override
        public ImpIpgRow updateRow(
                int iiKey, Integer rowNo, String rowKind, String text,
                Integer parentKey, Integer stiKey, String ctx) {
            throw new UnsupportedOperationException();
        }

        @Override
        public boolean deleteRow(int iiKey) {
            return false;
        }

        @Override
        public int deleteRowsByLoad(int iilKey) {
            return 0;
        }

        @Override
        public int replaceRows(int iilKey, List<ImpIpgStagingDraft> drafts) {
            return 0;
        }
    }
}
