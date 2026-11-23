package com.femsq.database.service;

import static org.junit.jupiter.api.Assertions.*;

import com.femsq.database.dao.IpgChainDao;
import com.femsq.database.dao.IpgChainRelationDao;
import com.femsq.database.model.IpgChain;
import com.femsq.database.model.IpgChainRelation;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class DefaultIpgChainServiceTest {

    private StubIpgChainDao stubDao;
    private IpgChainService service;

    @BeforeEach
    void setUp() {
        stubDao = new StubIpgChainDao();
        service = new DefaultIpgChainService(stubDao, new StubIpgChainRelationDao());
    }

    @Test
    void getByIdDelegatesToDao() {
        IpgChain chain = sampleChain(1, "Test Chain", 2024);
        stubDao.nextFound = Optional.of(chain);

        Optional<IpgChain> result = service.getById(1);

        assertTrue(result.isPresent());
        assertEquals(1, result.get().chainKey());
        assertEquals(1, stubDao.lastFindById);
    }

    @Test
    void getAllDelegatesToDao() {
        List<IpgChain> chains = List.of(sampleChain(1, "Chain 1", 2024), sampleChain(2, "Chain 2", 2023));
        stubDao.nextFindAll = chains;

        List<IpgChain> result = service.getAll();

        assertEquals(2, result.size());
        assertTrue(stubDao.findAllCalled);
    }

    @Test
    void getAllWithFiltersDelegatesToDao() {
        List<IpgChain> chains = List.of(sampleChain(1, "Test", 2024));
        stubDao.nextFindAllFiltered = chains;

        List<IpgChain> result = service.getAll(0, 10, "ipgcKey", "asc", "test", 2024);

        assertEquals(1, result.size());
        assertEquals(0, stubDao.lastPage);
        assertEquals(10, stubDao.lastSize);
        assertEquals("test", stubDao.lastNameFilter);
        assertEquals(2024, stubDao.lastYearFilter);
    }

    @Test
    void countDelegatesToDao() {
        stubDao.nextCount = 5L;

        long result = service.count("test", 2024);

        assertEquals(5L, result);
        assertEquals("test", stubDao.lastCountNameFilter);
        assertEquals(2024, stubDao.lastCountYearFilter);
    }

    private IpgChain sampleChain(Integer key, String name, Integer year) {
        return new IpgChain(key, name, null, null, year);
    }

    private static final class StubIpgChainDao implements IpgChainDao {
        private Optional<IpgChain> nextFound = Optional.empty();
        private List<IpgChain> nextFindAll = List.of();
        private List<IpgChain> nextFindAllFiltered = List.of();
        private long nextCount = 0L;
        private Integer lastFindById;
        private boolean findAllCalled;
        private int lastPage;
        private int lastSize;
        private String lastNameFilter;
        private Integer lastYearFilter;
        private String lastCountNameFilter;
        private Integer lastCountYearFilter;

        @Override
        public Optional<IpgChain> findById(int chainKey) {
            lastFindById = chainKey;
            return nextFound;
        }

        @Override
        public List<IpgChain> findAll() {
            findAllCalled = true;
            return nextFindAll;
        }

        @Override
        public List<IpgChain> findAll(int page, int size, String sortField, String sortDirection, String nameFilter, Integer yearFilter) {
            lastPage = page;
            lastSize = size;
            lastNameFilter = nameFilter;
            lastYearFilter = yearFilter;
            return nextFindAllFiltered;
        }

        @Override
        public long count(String nameFilter, Integer yearFilter) {
            lastCountNameFilter = nameFilter;
            lastCountYearFilter = yearFilter;
            return nextCount;
        }

        @Override
        public IpgChain insert(String name) {
            throw new UnsupportedOperationException();
        }

        @Override
        public IpgChain update(int chainKey, String name) {
            throw new UnsupportedOperationException();
        }

        @Override
        public boolean delete(int chainKey) {
            throw new UnsupportedOperationException();
        }
    }

    private static final class StubIpgChainRelationDao implements IpgChainRelationDao {
        @Override
        public Optional<IpgChainRelation> findById(int relationKey) {
            return Optional.empty();
        }

        @Override
        public List<IpgChainRelation> findByChain(int chainKey) {
            return List.of();
        }

        @Override
        public List<IpgChainRelation> findByChains(Collection<Integer> chainKeys) {
            return List.of();
        }

        @Override
        public List<IpgChainRelation> findAll() {
            return List.of();
        }

        @Override
        public Optional<IpgChainRelation> findByChainAndIpg(int chainKey, int investmentProgramKey) {
            return Optional.empty();
        }

        @Override
        public IpgChainRelation insert(int chainKey, int investmentProgramKey, Integer planGroupKey) {
            throw new UnsupportedOperationException();
        }

        @Override
        public IpgChainRelation update(int relationKey, int investmentProgramKey, Integer planGroupKey) {
            throw new UnsupportedOperationException();
        }

        @Override
        public boolean delete(int relationKey) {
            return false;
        }

        @Override
        public int deleteByChain(int chainKey) {
            return 0;
        }
    }
}
