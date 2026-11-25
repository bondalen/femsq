package com.femsq.database.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.dao.CstAgPnDao;
import com.femsq.database.dao.ImpIpgLoadDao;
import com.femsq.database.dao.IpgLeavesDao;
import com.femsq.database.model.CstAgPn;
import com.femsq.database.model.ImpIpgLoad;
import com.femsq.database.model.ImpIpgPointsApplyResult;
import com.femsq.database.model.ImpIpgPointsGateResult;
import com.femsq.database.model.ImpIpgRow;
import com.femsq.database.model.ImpIpgShResolveLeaf;
import com.femsq.database.model.ImpIpgShResolveResult;
import com.femsq.database.model.ImpIpgShResolveSource;
import com.femsq.database.model.ImpIpgStagingDraft;
import com.femsq.database.model.ImpIpgStiInheritLeaf;
import com.femsq.database.model.ImpIpgStiInheritResult;
import com.femsq.database.model.IpgFull;
import com.femsq.database.model.IpgPn;
import com.femsq.database.model.IpgPnBulkDraft;
import com.femsq.database.model.IpgSh;
import com.femsq.database.model.IpgStPn;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Unit-тесты apply пунктов (§3.2.7 partial / идемпотентность).
 */
class DefaultImpIpgPointsApplyServiceTest {

    private StubLoadDao loadDao;
    private StubIpgDao ipgDao;
    private StubCstAgPnDao cstDao;
    private StubGate gate;
    private StubSti sti;
    private StubSh sh;
    private ImpIpgPointsApplyService service;

    @BeforeEach
    void setUp() {
        loadDao = new StubLoadDao();
        ipgDao = new StubIpgDao();
        cstDao = new StubCstAgPnDao();
        gate = new StubGate();
        sti = new StubSti();
        sh = new StubSh();
        service = new DefaultImpIpgPointsApplyService(loadDao, ipgDao, cstDao, gate, sti, sh);
    }

    @Test
    void dryRunReadyWithoutInsert() {
        prepareHappyPath();

        ImpIpgPointsApplyResult result = service.apply(8, null, true);

        assertTrue(result.ready());
        assertTrue(result.dryRun());
        assertEquals(1, result.appliedCount());
        assertEquals(0, result.skippedAlreadyCount());
        assertTrue(result.createdPnKeys().isEmpty());
        assertTrue(ipgDao.created.isEmpty());
    }

    @Test
    void commitWritesOneLeaf() {
        prepareHappyPath();

        ImpIpgPointsApplyResult result = service.apply(8, null, false);

        assertTrue(result.ready());
        assertFalse(result.dryRun());
        assertEquals(1, result.appliedCount());
        assertEquals(List.of(501), result.createdPnKeys());
        assertEquals(1, ipgDao.created.size());
        IpgPnBulkDraft draft = ipgDao.created.get(0);
        assertEquals(1001, draft.cstAgPnKey());
        assertEquals(4, draft.ipgpSh());
        assertEquals(55, draft.stiKey());
        assertEquals(1, draft.ipgpNum());
        assertEquals(new BigDecimal("10.5"), draft.ipgpSmTtl());
    }

    @Test
    void idempotentSkipWhenAlreadyExists() {
        prepareHappyPath();
        ipgDao.existingPns = List.of(pn(1, 27, 1001, "051-1", 4));

        ImpIpgPointsApplyResult result = service.apply(8, null, false);

        assertTrue(result.ready());
        assertEquals(0, result.appliedCount());
        assertEquals(1, result.skippedAlreadyCount());
        assertTrue(ipgDao.created.isEmpty());
        assertTrue(result.errors().isEmpty());
    }

    @Test
    void partialAppliesReadyAndLogsMissingCstAgPn() {
        prepareTwoLeaves();
        cstDao.byCode.remove("051-2");

        ImpIpgPointsApplyResult result = service.apply(8, null, false);

        assertFalse(result.ready());
        assertEquals(1, result.appliedCount());
        assertEquals(1, result.problemRowIds().size());
        assertTrue(result.errors().stream()
                .anyMatch(e -> e.contains(DefaultImpIpgPointsApplyService.ERR_CSTAGPN_MISSING)
                        && e.contains("051-2")));
        assertEquals(1, ipgDao.created.size());
        assertEquals(1001, ipgDao.created.get(0).cstAgPnKey());
    }

    @Test
    void softGateOpenDoesNotAbort() {
        prepareHappyPath();
        gate.openCount = 2;

        ImpIpgPointsApplyResult result = service.apply(8, null, false);

        assertTrue(result.ready());
        assertEquals(1, result.appliedCount());
    }

    @Test
    void hardFailWhenIpgStRlShMissing() {
        prepareHappyPath();
        ipgDao.stRlSh = 0;

        ImpIpgPointsApplyResult result = service.apply(8, null, true);

        assertFalse(result.ready());
        assertTrue(result.errors().get(0).contains("ipgStRlSh"));
        assertTrue(ipgDao.created.isEmpty());
    }

    @Test
    void extractHelpersFromCtx() {
        String ctx = "{\"nnn\":\"12\",\"ttl\":16423.18,\"work\":1,\"equip\":2,\"others\":3,"
                + "\"commissioning\":\"Q1\",\"cstAgPn\":\"051-1\"}";
        assertEquals(12, DefaultImpIpgPointsApplyService.extractNnn(ctx));
        assertEquals(new BigDecimal("16423.18"), DefaultImpIpgPointsApplyService.extractDecimal(ctx, "ttl"));
        assertEquals("Q1", DefaultImpIpgPointsApplyService.extractCommissioning(ctx));
    }

    private void prepareHappyPath() {
        loadDao.load = sampleLoad(8, 27);
        String ctx = "{\"cstAgPn\":\"051-1\",\"nnn\":\"1\",\"ttl\":10.5,\"work\":4,\"equip\":3,\"others\":3.5}";
        loadDao.rows = List.of(
                new ImpIpgRow(1, 8, 1, "S", "sec", null, 55, "{}"),
                new ImpIpgRow(10, 8, 2, "L", "leaf", 1, null, ctx));
        cstDao.byCode.put("051-1", new CstAgPn(1001, 200, "051-1", null));
        sti.result = new ImpIpgStiInheritResult(
                8, 27, 1, 1, 0, true, List.of(), List.of(),
                List.of(new ImpIpgStiInheritLeaf(10, 2, "leaf", 1, 55, null)));
        sh.result = new ImpIpgShResolveResult(
                8, 27, null, 1, 1, 0, 0, 1, 0, true, List.of(), List.of(),
                List.of(new ImpIpgShResolveLeaf(
                        10, 2, "leaf", "051-1", 4, ImpIpgShResolveSource.DEFAULT_4, null)));
        ipgDao.nextKey = 501;
    }

    private void prepareTwoLeaves() {
        loadDao.load = sampleLoad(8, 27);
        String ctx1 = "{\"cstAgPn\":\"051-1\",\"nnn\":\"1\",\"ttl\":10}";
        String ctx2 = "{\"cstAgPn\":\"051-2\",\"nnn\":\"2\",\"ttl\":20}";
        loadDao.rows = List.of(
                new ImpIpgRow(1, 8, 1, "S", "sec", null, 55, "{}"),
                new ImpIpgRow(10, 8, 2, "L", "leaf1", 1, null, ctx1),
                new ImpIpgRow(11, 8, 3, "L", "leaf2", 1, null, ctx2));
        cstDao.byCode.put("051-1", new CstAgPn(1001, 200, "051-1", null));
        cstDao.byCode.put("051-2", new CstAgPn(1002, 200, "051-2", null));
        sti.result = new ImpIpgStiInheritResult(
                8, 27, 2, 2, 0, true, List.of(), List.of(),
                List.of(
                        new ImpIpgStiInheritLeaf(10, 2, "leaf1", 1, 55, null),
                        new ImpIpgStiInheritLeaf(11, 3, "leaf2", 1, 55, null)));
        sh.result = new ImpIpgShResolveResult(
                8, 27, null, 2, 2, 0, 0, 2, 0, true, List.of(), List.of(),
                List.of(
                        new ImpIpgShResolveLeaf(
                                10, 2, "leaf1", "051-1", 4, ImpIpgShResolveSource.DEFAULT_4, null),
                        new ImpIpgShResolveLeaf(
                                11, 3, "leaf2", "051-2", 4, ImpIpgShResolveSource.DEFAULT_4, null)));
        ipgDao.nextKey = 501;
    }

    private static ImpIpgLoad sampleLoad(int key, int ipg) {
        return new ImpIpgLoad(key, ipg, "load", null, null, LocalDateTime.of(2026, 11, 25, 10, 0));
    }

    private static IpgPn pn(int key, int ipg, int cstKey, String code, int sh) {
        return new IpgPn(key, ipg, 1, cstKey, code, "cst", "og",
                BigDecimal.ONE, BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO,
                null, null, null, null, sh, "Не определена");
    }

    private static final class StubGate implements ImpIpgPointsGateService {
        int openCount;

        @Override
        public ImpIpgPointsGateResult evaluate(int loadKey) {
            return new ImpIpgPointsGateResult(
                    loadKey, 27, 5, 1, openCount, openCount == 0, List.of(), List.of());
        }

        @Override
        public ImpIpgPointsGateResult assertReady(int loadKey) {
            return evaluate(loadKey);
        }
    }

    private static final class StubSti implements ImpIpgStiInheritService {
        ImpIpgStiInheritResult result;

        @Override
        public ImpIpgStiInheritResult evaluate(int loadKey) {
            return result;
        }

        @Override
        public ImpIpgStiInheritResult assertReady(int loadKey) {
            return result;
        }
    }

    private static final class StubSh implements ImpIpgShResolveService {
        ImpIpgShResolveResult result;

        @Override
        public ImpIpgShResolveResult evaluate(int loadKey, Integer previousIpgKey) {
            return result;
        }

        @Override
        public ImpIpgShResolveResult assertReady(int loadKey, Integer previousIpgKey) {
            return result;
        }
    }

    private static final class StubCstAgPnDao implements CstAgPnDao {
        final Map<String, CstAgPn> byCode = new HashMap<>();

        @Override
        public Optional<CstAgPn> findById(int cstapKey) {
            return Optional.empty();
        }

        @Override
        public Optional<CstAgPn> findByCodeExact(String code) {
            return Optional.ofNullable(byCode.get(code));
        }

        @Override
        public List<CstAgPn> findByCstAg(int cstaKey) {
            return List.of();
        }

        @Override
        public List<com.femsq.database.model.CstAgPnCode> findCodes(String codeFilter) {
            return List.of();
        }

        @Override
        public List<com.femsq.database.model.CstAgPnSiteLookup> findSiteLookups(int cstKey) {
            return List.of();
        }

        @Override
        public CstAgPn create(CstAgPn point) {
            throw new UnsupportedOperationException();
        }

        @Override
        public CstAgPn update(CstAgPn point) {
            throw new UnsupportedOperationException();
        }

        @Override
        public boolean deleteById(int cstapKey) {
            return false;
        }
    }

    private static final class StubLoadDao implements ImpIpgLoadDao {
        ImpIpgLoad load;
        List<ImpIpgRow> rows = List.of();

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

    private static final class StubIpgDao implements IpgLeavesDao {
        List<IpgPn> existingPns = List.of();
        final List<IpgPnBulkDraft> created = new ArrayList<>();
        int nextKey = 1;
        int stRlSh = 5;

        @Override
        public Optional<IpgFull> findIpgByKey(int ipgKey) {
            return Optional.of(new IpgFull(
                    ipgKey, 1, "og", "ipg", 2026, 2026, (short) 1,
                    LocalDate.of(2026, 1, 1), null, null, stRlSh, "st", 2026));
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
            return existingPns;
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
            List<Integer> keys = new ArrayList<>();
            for (IpgPnBulkDraft draft : drafts) {
                keys.add(createPnWithSt(ipgKey, draft));
            }
            return keys;
        }

        @Override
        public int createPnWithSt(int ipgKey, IpgPnBulkDraft draft) {
            created.add(draft);
            return nextKey++;
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
}
