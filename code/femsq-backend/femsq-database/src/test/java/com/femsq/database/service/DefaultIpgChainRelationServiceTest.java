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

class DefaultIpgChainRelationServiceTest {

    private StubIpgChainRelationDao stubDao;
    private IpgChainRelationService service;

    @BeforeEach
    void setUp() {
        stubDao = new StubIpgChainRelationDao();
        service = new DefaultIpgChainRelationService(stubDao, new StubIpgChainDao());
    }

    @Test
    void getByChainDelegatesToDao() {
        List<IpgChainRelation> relations = List.of(
                sampleRelation(1, 10, 100),
                sampleRelation(2, 10, 101)
        );
        stubDao.nextFindByChain = relations;

        List<IpgChainRelation> result = service.getByChain(10);

        assertEquals(2, result.size());
        assertEquals(10, stubDao.lastFindByChain);
    }

    @Test
    void getByChainsDelegatesToDao() {
        List<IpgChainRelation> relations = List.of(sampleRelation(1, 10, 100));
        stubDao.nextFindByChains = relations;

        List<IpgChainRelation> result = service.getByChains(List.of(10, 20));

        assertEquals(1, result.size());
        assertTrue(stubDao.lastFindByChains.contains(10));
        assertTrue(stubDao.lastFindByChains.contains(20));
    }

    @Test
    void getAllDelegatesToDao() {
        List<IpgChainRelation> relations = List.of(sampleRelation(1, 10, 100));
        stubDao.nextFindAll = relations;

        List<IpgChainRelation> result = service.getAll();

        assertEquals(1, result.size());
        assertTrue(stubDao.findAllCalled);
    }

    private IpgChainRelation sampleRelation(Integer key, Integer chainKey, Integer ipgKey) {
        return new IpgChainRelation(key, chainKey, ipgKey, null);
    }

    private static final class StubIpgChainRelationDao implements IpgChainRelationDao {
        private List<IpgChainRelation> nextFindByChain = List.of();
        private List<IpgChainRelation> nextFindByChains = List.of();
        private List<IpgChainRelation> nextFindAll = List.of();
        private Integer lastFindByChain;
        private Collection<Integer> lastFindByChains;
        private boolean findAllCalled;

        @Override
        public java.util.Optional<IpgChainRelation> findById(int relationKey) {
            return java.util.Optional.empty();
        }

        @Override
        public List<IpgChainRelation> findByChain(int chainKey) {
            lastFindByChain = chainKey;
            return nextFindByChain;
        }

        @Override
        public List<IpgChainRelation> findByChains(Collection<Integer> chainKeys) {
            lastFindByChains = chainKeys;
            return nextFindByChains;
        }

        @Override
        public List<IpgChainRelation> findAll() {
            findAllCalled = true;
            return nextFindAll;
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

    private static final class StubIpgChainDao implements IpgChainDao {
        @Override
        public Optional<IpgChain> findById(int chainKey) {
            return Optional.of(new IpgChain(chainKey, "stub", null, null, null));
        }

        @Override
        public List<IpgChain> findAll() {
            return List.of();
        }

        @Override
        public List<IpgChain> findAll(
                int page, int size, String sortField, String sortDirection, String nameFilter, Integer yearFilter) {
            return List.of();
        }

        @Override
        public long count(String nameFilter, Integer yearFilter) {
            return 0;
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
            return false;
        }
    }
}
