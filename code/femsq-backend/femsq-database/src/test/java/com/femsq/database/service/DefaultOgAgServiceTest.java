package com.femsq.database.service;

import static org.junit.jupiter.api.Assertions.*;

import com.femsq.database.dao.OgAgDao;
import com.femsq.database.dao.OgDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.Og;
import com.femsq.database.model.OgAg;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class DefaultOgAgServiceTest {

    private StubOgDao ogDao;
    private StubOgAgDao ogAgDao;
    private OgAgService service;

    @BeforeEach
    void setUp() {
        ogDao = new StubOgDao();
        ogAgDao = new StubOgAgDao();
        service = new DefaultOgAgService(ogAgDao, ogDao);
    }

    @Test
    void createDelegatesWhenOrganizationExists() {
        ogDao.byId.put(1, sampleOrganization(1));
        OgAg newAgent = sampleAgent(null, 1, "100");
        ogAgDao.nextCreated = sampleAgent(10, 1, "100");

        OgAg created = service.create(newAgent);

        assertEquals(10, created.ogAgKey());
        assertEquals("100", ogAgDao.lastCreated.code());
    }

    @Test
    void createFailsWhenOrganizationMissing() {
        OgAg newAgent = sampleAgent(null, 99, "100");

        assertThrows(IllegalArgumentException.class, () -> service.create(newAgent));
    }

    @Test
    void updateRequiresExistingId() {
        OgAg agent = sampleAgent(null, 1, "200");

        assertThrows(IllegalArgumentException.class, () -> service.update(agent));
    }

    @Test
    void updateDelegatesWhenOrganizationExists() {
        ogDao.byId.put(1, sampleOrganization(1));
        OgAg agent = sampleAgent(5, 1, "200");
        ogAgDao.nextUpdated = agent;

        OgAg result = service.update(agent);

        assertSame(agent, result);
        assertEquals(5, ogAgDao.lastUpdated.ogAgKey());
    }

    @Test
    void deleteDelegates() {
        ogAgDao.deleteResult = true;

        assertTrue(service.delete(7));
        assertEquals(7, ogAgDao.lastDeletedId);
    }

    private Og sampleOrganization(int id) {
        return new Og(
                id,
                "Организация",
                "Организация",
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                "og"
        );
    }

    private OgAg sampleAgent(Integer id, int organizationId, String code) {
        return new OgAg(id, code, organizationId, null);
    }

    private static final class StubOgDao implements OgDao {

        private final Map<Integer, Og> byId = new java.util.HashMap<>();

        @Override
        public Optional<Og> findById(int ogKey) {
            return Optional.ofNullable(byId.get(ogKey));
        }

        @Override
        public List<Og> findAll() {
            return new ArrayList<>(byId.values());
        }

        @Override
        public List<Og> findAll(int page, int size, String sortField, String sortDirection) {
            int offset = page * size;
            return byId.values().stream()
                    .skip(offset)
                    .limit(size)
                    .toList();
        }

        @Override
        public long count() {
            return byId.size();
        }

        @Override
        public Og create(Og organization) {
            throw new UnsupportedOperationException();
        }

        @Override
        public Og update(Og organization) {
            throw new UnsupportedOperationException();
        }

        @Override
        public boolean deleteById(int ogKey) {
            throw new UnsupportedOperationException();
        }
    }

    private static final class StubOgAgDao implements OgAgDao {

        private OgAg nextCreated;
        private OgAg nextUpdated;
        private OgAg lastCreated;
        private OgAg lastUpdated;
        private Integer lastDeletedId;
        private boolean deleteResult;
        private final Map<Integer, OgAg> byId = new java.util.HashMap<>();

        @Override
        public Optional<OgAg> findById(int ogAgKey) {
            return Optional.ofNullable(byId.get(ogAgKey));
        }

        @Override
        public List<OgAg> findByOrganization(int organizationKey) {
            return byId.values().stream()
                    .filter(agent -> agent.organizationKey() == organizationKey)
                    .toList();
        }

        @Override
        public List<OgAg> findAll() {
            return List.copyOf(byId.values());
        }

        @Override
        public OgAg create(OgAg agent) {
            lastCreated = agent;
            if (nextCreated != null) {
                byId.put(nextCreated.ogAgKey(), nextCreated);
                return nextCreated;
            }
            throw new DaoException("Stub result not configured");
        }

        @Override
        public OgAg update(OgAg agent) {
            lastUpdated = agent;
            if (nextUpdated != null) {
                byId.put(nextUpdated.ogAgKey(), nextUpdated);
                return nextUpdated;
            }
            throw new DaoException("Stub result not configured");
        }

        @Override
        public boolean deleteById(int ogAgKey) {
            lastDeletedId = ogAgKey;
            return deleteResult;
        }
    }
}
