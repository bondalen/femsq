package com.femsq.database.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.dao.OrgIdDao;
import com.femsq.database.model.Og;
import com.femsq.database.model.OrgId;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Валидация привязки БУиРГ/ИНН без JDBC.
 */
class DefaultOrgIdServiceTest {

    private FakeOrgIdDao orgIdDao;
    private FakeOgService ogService;
    private DefaultOrgIdService service;

    @BeforeEach
    void setUp() {
        orgIdDao = new FakeOrgIdDao();
        ogService = new FakeOgService();
        service = new DefaultOrgIdService(orgIdDao, ogService);
    }

    @Test
    void createOrganizationWithIdsWritesItnOnlyToOrgId() {
        Og created = service.createOrganizationWithIds(sampleOg(null), 777, "7707083893", "770701001");
        assertEquals(1, created.ogKey());
        assertEquals(null, created.inn());
        assertEquals(2, orgIdDao.rows.size());
        assertEquals(OrgId.TYPE_BUIRG, orgIdDao.rows.get(0).orgIdType());
        assertEquals(777, orgIdDao.rows.get(0).orgIdValueL());
        assertEquals(OrgId.TYPE_ITN, orgIdDao.rows.get(1).orgIdType());
        assertEquals("7707083893", orgIdDao.rows.get(1).orgIdValueT());
        assertEquals("770701001", orgIdDao.rows.get(1).orgIdValueTExt());
    }

    @Test
    void attachRequiresAtLeastOneId() {
        ogService.store.put(10, sampleOg(10));
        assertThrows(IllegalArgumentException.class, () -> service.attachIds(10, null, "  ", null));
    }

    @Test
    void attachBuirgRejectsForeignOwner() {
        ogService.store.put(10, sampleOg(10));
        orgIdDao.rows.add(new OrgId(1, 99, OrgId.TYPE_BUIRG, 12345, null, null));
        IllegalArgumentException ex = assertThrows(
                IllegalArgumentException.class,
                () -> service.attachIds(10, 12345, null, null)
        );
        assertTrue(ex.getMessage().contains("уже привязан"));
    }

    @Test
    void attachItnUpgradesEmptyKppOnExistingRow() {
        ogService.store.put(10, sampleOg(10));
        orgIdDao.rows.add(new OrgId(5, 10, OrgId.TYPE_ITN, null, "6901067107", null));
        List<OrgId> result = service.attachIds(10, null, "6901067107", "366302001");
        assertEquals(1, result.size());
        assertEquals(5, result.get(0).orgIdKey());
        assertEquals("366302001", result.get(0).orgIdValueTExt());
        assertEquals(1, orgIdDao.rows.size());
    }

    private static Og sampleOg(Integer key) {
        return new Og(key, "Тест", "Тест Оф", null, null, null, null, null, null, null, "og");
    }

    private static final class FakeOrgIdDao implements OrgIdDao {
        private final List<OrgId> rows = new ArrayList<>();
        private final AtomicInteger seq = new AtomicInteger(1);

        @Override
        public List<OrgId> findByOrg(int orgKey) {
            return rows.stream().filter(r -> r.org() == orgKey).toList();
        }

        @Override
        public Optional<OrgId> findBuirg(int buirg) {
            return rows.stream()
                    .filter(r -> r.orgIdType() == OrgId.TYPE_BUIRG && buirg == r.orgIdValueL())
                    .findFirst();
        }

        @Override
        public boolean existsItnForOrg(int orgKey, String itn, String itnExt) {
            return rows.stream().anyMatch(r ->
                    r.org() == orgKey
                            && r.orgIdType() == OrgId.TYPE_ITN
                            && itn.equals(r.orgIdValueT())
                            && java.util.Objects.equals(itnExt, r.orgIdValueTExt()));
        }

        @Override
        public OrgId create(OrgId orgId) {
            OrgId saved = new OrgId(
                    seq.getAndIncrement(),
                    orgId.org(),
                    orgId.orgIdType(),
                    orgId.orgIdValueL(),
                    orgId.orgIdValueT(),
                    orgId.orgIdValueTExt()
            );
            rows.add(saved);
            return saved;
        }

        @Override
        public OrgId update(OrgId orgId) {
            for (int i = 0; i < rows.size(); i++) {
                if (rows.get(i).orgIdKey().equals(orgId.orgIdKey())) {
                    rows.set(i, orgId);
                    return orgId;
                }
            }
            throw new IllegalStateException("not found");
        }
    }

    private static final class FakeOgService implements OgService {
        final java.util.Map<Integer, Og> store = new java.util.HashMap<>();
        private final AtomicInteger seq = new AtomicInteger(1);

        @Override
        public List<Og> getAll() {
            return List.copyOf(store.values());
        }

        @Override
        public List<Og> getAll(int page, int size, String sortField, String sortDirection, String nameFilter) {
            return getAll();
        }

        @Override
        public long count(String nameFilter) {
            return store.size();
        }

        @Override
        public Optional<Og> getById(int ogKey) {
            return Optional.ofNullable(store.get(ogKey));
        }

        @Override
        public Og create(Og organization) {
            int key = seq.getAndIncrement();
            Og saved = new Og(
                    key,
                    organization.ogName(),
                    organization.ogOfficialName(),
                    organization.ogFullName(),
                    organization.ogDescription(),
                    organization.inn(),
                    organization.kpp(),
                    organization.ogrn(),
                    organization.okpo(),
                    organization.oe(),
                    organization.registrationTaxType()
            );
            store.put(key, saved);
            return saved;
        }

        @Override
        public Og update(Og organization) {
            store.put(organization.ogKey(), organization);
            return organization;
        }

        @Override
        public boolean delete(int ogKey) {
            return store.remove(ogKey) != null;
        }
    }
}
