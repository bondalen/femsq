package com.femsq.database.service;

import static org.junit.jupiter.api.Assertions.*;

import com.femsq.database.dao.OgDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.Og;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class DefaultOgServiceTest {

    private StubOgDao stubDao;
    private OgService service;

    @BeforeEach
    void setUp() {
        stubDao = new StubOgDao();
        service = new DefaultOgService(stubDao);
    }

    @Test
    void createDelegatesToDao() {
        Og newOrganization = sampleOrganization(null, "ООО Тест", "Общество", "og");
        stubDao.nextCreated = sampleOrganization(1, "ООО Тест", "Общество", "og");

        Og created = service.create(newOrganization);

        assertEquals(1, created.ogKey());
        assertEquals(newOrganization.ogName(), stubDao.lastCreated.ogName());
    }

    @Test
    void createFailsWhenIdPresent() {
        Og withId = sampleOrganization(10, "ООО", "Общество", "og");

        assertThrows(IllegalArgumentException.class, () -> service.create(withId));
    }

    @Test
    void createFailsOnBlankFields() {
        Og invalid = sampleOrganization(null, " ", " ", " ");

        assertThrows(IllegalArgumentException.class, () -> service.create(invalid));
    }

    @Test
    void updateRequiresId() {
        Og invalid = sampleOrganization(null, "ООО", "Общество", "og");

        assertThrows(IllegalArgumentException.class, () -> service.update(invalid));
    }

    @Test
    void updateDelegatesToDao() {
        Og updated = sampleOrganization(5, "ООО", "Общество", "og");
        stubDao.nextUpdated = updated;

        Og result = service.update(updated);

        assertSame(updated, result);
        assertEquals(5, stubDao.lastUpdated.ogKey());
    }

    @Test
    void deleteReturnsDaoResult() {
        stubDao.deleteResult = true;

        assertTrue(service.delete(7));
        assertEquals(7, stubDao.lastDeletedId);
    }

    private Og sampleOrganization(Integer id, String name, String official, String taxType) {
        return new Og(
                id,
                name,
                official,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                taxType
        );
    }

    private static final class StubOgDao implements OgDao {

        private Og nextCreated;
        private Og nextUpdated;
        private Og lastCreated;
        private Og lastUpdated;
        private Integer lastDeletedId;
        private boolean deleteResult;
        private final List<Og> all = new ArrayList<>();
        private final Map<Integer, Og> byId = new java.util.HashMap<>();

        @Override
        public Optional<Og> findById(int ogKey) {
            return Optional.ofNullable(byId.get(ogKey));
        }

        @Override
        public List<Og> findAll() {
            return List.copyOf(all);
        }

        @Override
        public List<Og> findAll(int page, int size, String sortField, String sortDirection) {
            int offset = page * size;
            return all.stream()
                    .skip(offset)
                    .limit(size)
                    .toList();
        }

        @Override
        public long count() {
            return all.size();
        }

        @Override
        public Og create(Og organization) {
            lastCreated = organization;
            if (nextCreated != null) {
                byId.put(nextCreated.ogKey(), nextCreated);
                all.add(nextCreated);
                return nextCreated;
            }
            throw new DaoException("Stub result not configured");
        }

        @Override
        public Og update(Og organization) {
            lastUpdated = organization;
            if (nextUpdated != null) {
                byId.put(nextUpdated.ogKey(), nextUpdated);
                return nextUpdated;
            }
            throw new DaoException("Stub result not configured");
        }

        @Override
        public boolean deleteById(int ogKey) {
            lastDeletedId = ogKey;
            return deleteResult;
        }
    }
}
