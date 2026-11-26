package com.femsq.database.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.dao.ImpIpgLoadDao;
import com.femsq.database.dao.IpgLeavesDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.ImpIpgLoad;
import com.femsq.database.model.ImpIpgRow;
import com.femsq.database.model.ImpIpgShResolveResult;
import com.femsq.database.model.ImpIpgShResolveSource;
import com.femsq.database.model.ImpIpgStagingDraft;
import com.femsq.database.model.IpgFull;
import com.femsq.database.model.IpgPn;
import com.femsq.database.model.IpgPnBulkDraft;
import com.femsq.database.model.IpgSh;
import com.femsq.database.model.IpgStPn;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Unit-тесты резолва ipgpSh (§3.2.3 / notes O1 §5.2).
 */
class DefaultImpIpgShResolveServiceTest {

    private StubLoadDao loadDao;
    private StubIpgDao ipgDao;
    private ImpIpgShResolveService service;

    @BeforeEach
    void setUp() {
        loadDao = new StubLoadDao();
        ipgDao = new StubIpgDao();
        ipgDao.schemes = List.of(
                new IpgSh(1, "Инвестиционная"),
                new IpgSh(2, "Агентская"),
                new IpgSh(3, "Иная схема"),
                new IpgSh(4, "Не определена"));
        service = new DefaultImpIpgShResolveService(loadDao, ipgDao);
    }

    @Test
    void singleOccurrenceTakesPrevWhenExactlyOneScheme() {
        loadDao.load = sampleLoad(8, 27);
        loadDao.rows = List.of(leaf(1, 10, "051-1"));
        ipgDao.prevPns = List.of(pn(100, 17, "051-1", 2));

        ImpIpgShResolveResult result = service.evaluate(8, 17);

        assertTrue(result.ready());
        assertEquals(1, result.fromPrevCount());
        assertEquals(2, result.resolvedLeaves().get(0).resolvedSh());
        assertEquals(ImpIpgShResolveSource.FROM_PREV, result.resolvedLeaves().get(0).source());
    }

    @Test
    void singleOccurrenceDefaultsTo2WhenPrevAmbiguousOrEmpty() {
        loadDao.load = sampleLoad(8, 27);
        loadDao.rows = List.of(leaf(1, 10, "051-1"));
        ipgDao.prevPns = List.of(pn(100, 17, "051-1", 1), pn(101, 17, "051-1", 2));

        ImpIpgShResolveResult ambiguous = service.evaluate(8, 17);
        assertEquals(2, ambiguous.resolvedLeaves().get(0).resolvedSh());
        assertEquals(ImpIpgShResolveSource.DEFAULT_4, ambiguous.resolvedLeaves().get(0).source());

        ImpIpgShResolveResult noPrev = service.evaluate(8, null);
        assertEquals(2, noPrev.resolvedLeaves().get(0).resolvedSh());
        assertEquals(1, noPrev.default4Count());
    }

    @Test
    void multiOccurrenceUsesPrevThenFreePool() {
        loadDao.load = sampleLoad(8, 27);
        loadDao.rows = List.of(
                leaf(1, 10, "051-1"),
                leaf(2, 11, "051-1"));
        ipgDao.prevPns = List.of(pn(100, 17, "051-1", 2));

        ImpIpgShResolveResult result = service.evaluate(8, 17);

        assertTrue(result.ready());
        assertEquals(2, result.resolvedCount());
        assertEquals(2, result.resolvedLeaves().get(0).resolvedSh());
        assertEquals(ImpIpgShResolveSource.FROM_PREV, result.resolvedLeaves().get(0).source());
        assertEquals(1, result.resolvedLeaves().get(1).resolvedSh());
        assertEquals(ImpIpgShResolveSource.FREE_POOL, result.resolvedLeaves().get(1).source());
    }

    @Test
    void multiOccurrenceErrorsWhenNotEnoughSchemes() {
        loadDao.load = sampleLoad(8, 27);
        // 5 вхождений, в справочнике только 4 схемы
        loadDao.rows = List.of(
                leaf(1, 10, "X"),
                leaf(2, 11, "X"),
                leaf(3, 12, "X"),
                leaf(4, 13, "X"),
                leaf(5, 14, "X"));

        ImpIpgShResolveResult result = service.evaluate(8, null);

        assertFalse(result.ready());
        assertEquals(5, result.errorCount());
        assertTrue(result.problemLeaves().stream()
                .allMatch(p -> DefaultImpIpgShResolveService.ERR_NO_SCHEMES.equals(p.errorReason())));
    }

    @Test
    void missingCstAgPnIsError() {
        loadDao.load = sampleLoad(8, 27);
        loadDao.rows = List.of(new ImpIpgRow(1, 8, 10, "L", "leaf", null, null, "{\"nnn\":\"1\"}"));

        ImpIpgShResolveResult result = service.evaluate(8, null);

        assertFalse(result.ready());
        assertEquals(DefaultImpIpgShResolveService.ERR_MISSING_CODE,
                result.problemLeaves().get(0).errorReason());
    }

    @Test
    void extractCstAgPnFromCtx() {
        assertEquals("051-2000860",
                DefaultImpIpgShResolveService.extractCstAgPn(
                        "{\"cstAgPn\":\"051-2000860\",\"ttl\":1}"));
        assertEquals(null, DefaultImpIpgShResolveService.extractCstAgPn("{}"));
    }

    @Test
    void assertReadyThrowsWhenErrors() {
        loadDao.load = sampleLoad(8, 27);
        loadDao.rows = List.of(new ImpIpgRow(1, 8, 10, "L", "leaf", null, null, "{}"));

        DaoException ex = assertThrows(DaoException.class, () -> service.assertReady(8, null));
        assertTrue(ex.getMessage().contains("ipgpSh"));
    }

    @Test
    void evaluateFailsWhenLoadMissing() {
        loadDao.load = null;
        ImpIpgShResolveResult result = service.evaluate(404, null);
        assertFalse(result.ready());
        assertTrue(result.errors().stream().anyMatch(e -> e.contains("не найдена")));
    }

    private static ImpIpgLoad sampleLoad(int key, int ipg) {
        return new ImpIpgLoad(key, ipg, "sql_0", "/tmp/x.xlsx", null, LocalDateTime.now());
    }

    private static ImpIpgRow leaf(int key, int rowNo, String code) {
        return new ImpIpgRow(
                key, 8, rowNo, "L", "leaf-" + key, null, null,
                "{\"cstAgPn\":\"" + code + "\"}");
    }

    private static IpgPn pn(int key, int ipg, String code, int sh) {
        return new IpgPn(
                key, ipg, 1, 10, code, "cst", "og",
                BigDecimal.ONE, null, null, null, null, null, null, null,
                sh, "sh-" + sh);
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
        public void updateLoadResults(int iilKey, String html) {
            // лог не проверяется в этом тесте
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
        private List<IpgPn> prevPns = List.of();
        private List<IpgSh> schemes = List.of();

        @Override
        public Optional<IpgFull> findIpgByKey(int ipgKey) {
            return Optional.empty();
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
            return prevPns;
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
            return schemes;
        }
    }
}
