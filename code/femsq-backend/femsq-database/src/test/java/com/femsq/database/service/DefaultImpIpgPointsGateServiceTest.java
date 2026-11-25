package com.femsq.database.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.dao.ImpIpgLoadDao;
import com.femsq.database.dao.IpgLeavesDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.ImpIpgLoad;
import com.femsq.database.model.ImpIpgPointsGateResult;
import com.femsq.database.model.ImpIpgReconcileResult;
import com.femsq.database.model.ImpIpgReconcileRow;
import com.femsq.database.model.ImpIpgReconcileStatus;
import com.femsq.database.model.ImpIpgRow;
import com.femsq.database.model.ImpIpgStagingDraft;
import com.femsq.database.model.IpgFull;
import com.femsq.database.model.IpgPn;
import com.femsq.database.model.IpgPnBulkDraft;
import com.femsq.database.model.IpgSh;
import com.femsq.database.model.IpgStPn;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Unit-тесты gate загрузки пунктов (§3.2.1).
 */
class DefaultImpIpgPointsGateServiceTest {

    private StubLoadDao loadDao;
    private StubIpgDao ipgDao;
    private StubReconcile reconcile;
    private ImpIpgPointsGateService service;

    @BeforeEach
    void setUp() {
        loadDao = new StubLoadDao();
        ipgDao = new StubIpgDao();
        reconcile = new StubReconcile();
        service = new DefaultImpIpgPointsGateService(loadDao, ipgDao, reconcile);
    }

    @Test
    void evaluateReadyWhenPtsfClosedAndStNetSet() {
        loadDao.load = sampleLoad(8, 27);
        ipgDao.ipg = sampleIpg(27, 5);
        reconcile.result = new ImpIpgReconcileResult(8, 5, 2, 0, List.of(
                closedRow(1),
                closedRow(2)));

        ImpIpgPointsGateResult result = service.evaluate(8);

        assertTrue(result.ready());
        assertEquals(27, result.ipgKey());
        assertEquals(5, result.stNetKey());
        assertEquals(2, result.sectionCount());
        assertEquals(0, result.openCount());
        assertTrue(result.errors().isEmpty());
        assertEquals(5, reconcile.lastStNetKey);
        assertFalse(reconcile.lastPersist);
    }

    @Test
    void evaluateFailsWhenOpenRows() {
        loadDao.load = sampleLoad(8, 27);
        ipgDao.ipg = sampleIpg(27, 5);
        reconcile.result = new ImpIpgReconcileResult(8, 5, 1, 1, List.of(
                closedRow(1),
                openRow(99)));

        ImpIpgPointsGateResult result = service.evaluate(8);

        assertFalse(result.ready());
        assertEquals(1, result.openCount());
        assertEquals(List.of(99), result.openRowIds());
        assertFalse(result.errors().isEmpty());
    }

    @Test
    void evaluateFailsWhenIpgMissing() {
        loadDao.load = sampleLoad(8, 27);
        ipgDao.ipg = null;

        ImpIpgPointsGateResult result = service.evaluate(8);

        assertFalse(result.ready());
        assertTrue(result.errors().stream().anyMatch(e -> e.contains("ipg не найдена")));
    }

    @Test
    void evaluateFailsWhenNoSections() {
        loadDao.load = sampleLoad(8, 27);
        ipgDao.ipg = sampleIpg(27, 5);
        reconcile.result = new ImpIpgReconcileResult(8, 5, 0, 0, List.of());

        ImpIpgPointsGateResult result = service.evaluate(8);

        assertFalse(result.ready());
        assertTrue(result.errors().stream().anyMatch(e -> e.contains("нет разделов")));
    }

    @Test
    void assertReadyThrowsWhenNotReady() {
        loadDao.load = sampleLoad(8, 27);
        ipgDao.ipg = sampleIpg(27, 5);
        reconcile.result = new ImpIpgReconcileResult(8, 5, 0, 1, List.of(openRow(5)));

        DaoException ex = assertThrows(DaoException.class, () -> service.assertReady(8));
        assertTrue(ex.getMessage().contains("Gate пунктов"));
    }

    @Test
    void evaluateFailsWhenLoadMissing() {
        loadDao.load = null;
        ImpIpgPointsGateResult result = service.evaluate(404);
        assertFalse(result.ready());
        assertTrue(result.errors().stream().anyMatch(e -> e.contains("не найдена")));
    }

    private static ImpIpgLoad sampleLoad(int key, int ipg) {
        return new ImpIpgLoad(key, ipg, "sql_0", "/tmp/x.xlsx", null, LocalDateTime.now());
    }

    private static IpgFull sampleIpg(int key, int stNet) {
        return new IpgFull(
                key, 7, "og", "Утверждённая", 28, 2026, (short) 1,
                LocalDate.of(2026, 11, 24), null, null, stNet, "net", null);
    }

    private static ImpIpgReconcileRow closedRow(int id) {
        return new ImpIpgReconcileRow(
                id, id, "S", id, ImpIpgReconcileStatus.MATCHED, List.of(id), true, true, true);
    }

    private static ImpIpgReconcileRow openRow(int id) {
        return new ImpIpgReconcileRow(
                id, id, "open", null, ImpIpgReconcileStatus.UNMATCHED, List.of(), false, false, false);
    }

    private static final class StubLoadDao implements ImpIpgLoadDao {
        private ImpIpgLoad load;

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
            return List.of();
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

    private static final class StubIpgDao implements IpgLeavesDao {
        private IpgFull ipg;

        @Override
        public Optional<IpgFull> findIpgByKey(int ipgKey) {
            return Optional.ofNullable(ipg);
        }

        @Override
        public List<IpgFull> findIpgs(Integer year, Integer ogKey, String nameContains) {
            return List.of();
        }

        @Override
        public IpgFull createIpg(
                int ipgOg, String ipgNm, int ipgYy, short ipgNum, LocalDate ipgStr,
                LocalDate ipgEnd, Integer ipgRepl, int ipgStRlSh, Integer ipgYyYear) {
            throw new UnsupportedOperationException();
        }

        @Override
        public IpgFull updateIpg(
                int ipgKey, String ipgNm, int ipgYy, short ipgNum, LocalDate ipgStr,
                LocalDate ipgEnd, Integer ipgRepl, int ipgStRlSh, Integer ipgYyYear) {
            throw new UnsupportedOperationException();
        }

        @Override
        public Optional<IpgPn> findPnByKey(int ipgpKey) {
            return Optional.empty();
        }

        @Override
        public List<IpgPn> findPnsByIpg(int ipgKey) {
            return List.of();
        }

        @Override
        public IpgPn createPn(
                int ipgpIpg, Integer ipgpNum, int ipgpCstAgPn, int ipgpSh,
                BigDecimal ipgpSmTtl, BigDecimal ipgpSmWrk, BigDecimal ipgpSmEqu,
                BigDecimal ipgpSmOth, BigDecimal ipgpSmAgFee, BigDecimal ipgpCostAdjust,
                BigDecimal ipgpSmReserv, String ipgpTskCms) {
            throw new UnsupportedOperationException();
        }

        @Override
        public List<Integer> bulkCreatePnsWithSt(int ipgKey, List<IpgPnBulkDraft> drafts) {
            throw new UnsupportedOperationException();
        }

        @Override
        public int createPnWithSt(int ipgKey, IpgPnBulkDraft draft) {
            throw new UnsupportedOperationException();
        }

        @Override
        public IpgPn updatePn(
                int ipgpKey, Integer ipgpNum, int ipgpCstAgPn, int ipgpSh,
                BigDecimal ipgpSmTtl, BigDecimal ipgpSmWrk, BigDecimal ipgpSmEqu,
                BigDecimal ipgpSmOth, BigDecimal ipgpSmAgFee, BigDecimal ipgpCostAdjust,
                BigDecimal ipgpSmReserv, String ipgpTskCms) {
            throw new UnsupportedOperationException();
        }

        @Override
        public void deletePn(int ipgpKey) {
            throw new UnsupportedOperationException();
        }

        @Override
        public List<IpgStPn> findStPnByPn(int ipgpKey) {
            return List.of();
        }

        @Override
        public IpgStPn addStPn(int ipgpKey, int stiKey) {
            throw new UnsupportedOperationException();
        }

        @Override
        public void removeStPn(int ipgspKey) {
            throw new UnsupportedOperationException();
        }

        @Override
        public List<IpgStPn> setStPn(int ipgpKey, List<Integer> stiKeys) {
            return List.of();
        }

        @Override
        public List<IpgSh> findAllSh() {
            return List.of();
        }
    }

    private static final class StubReconcile implements ImpIpgReconcileService {
        private ImpIpgReconcileResult result =
                new ImpIpgReconcileResult(0, 0, 0, 0, List.of());
        private Integer lastStNetKey;
        private Boolean lastPersist;

        @Override
        public ImpIpgReconcileResult reconcile(int loadKey, int stNetKey, boolean persistMatches) {
            lastStNetKey = stNetKey;
            lastPersist = persistMatches;
            return result;
        }
    }
}
