package com.femsq.database.service;

import com.femsq.database.dao.OrgIdDao;
import com.femsq.database.model.Og;
import com.femsq.database.model.OrgId;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Реализация {@link OrgIdService}.
 */
public class DefaultOrgIdService implements OrgIdService {

    private static final Logger log = Logger.getLogger(DefaultOrgIdService.class.getName());

    private final OrgIdDao orgIdDao;
    private final OgService ogService;

    /**
     * @param orgIdDao DAO org_id
     * @param ogService сервис og
     */
    public DefaultOrgIdService(OrgIdDao orgIdDao, OgService ogService) {
        this.orgIdDao = Objects.requireNonNull(orgIdDao, "orgIdDao");
        this.ogService = Objects.requireNonNull(ogService, "ogService");
    }

    @Override
    public List<OrgId> listByOrg(int orgKey) {
        if (orgKey <= 0) {
            throw new IllegalArgumentException("orgKey должен быть положительным: " + orgKey);
        }
        return orgIdDao.findByOrg(orgKey);
    }

    @Override
    public Og createOrganizationWithIds(Og organization, Integer buirg, String itn, String itnExt) {
        Objects.requireNonNull(organization, "organization");
        Og withoutInn = new Og(
                null,
                organization.ogName(),
                organization.ogOfficialName(),
                organization.ogFullName(),
                organization.ogDescription(),
                null,
                organization.kpp(),
                organization.ogrn(),
                organization.okpo(),
                organization.oe(),
                organization.registrationTaxType()
        );
        Og created = ogService.create(withoutInn);
        log.log(Level.INFO, "Created ogKey={0}, attaching ids buirg={1} itn={2} ext={3}",
                new Object[]{created.ogKey(), buirg, itn, itnExt});
        attachIdsInternal(created.ogKey(), buirg, itn, itnExt, false);
        return created;
    }

    @Override
    public List<OrgId> attachIds(int orgKey, Integer buirg, String itn, String itnExt) {
        if (orgKey <= 0) {
            throw new IllegalArgumentException("orgKey должен быть положительным: " + orgKey);
        }
        if (ogService.getById(orgKey).isEmpty()) {
            throw new IllegalArgumentException("Организация не найдена: ogKey=" + orgKey);
        }
        return attachIdsInternal(orgKey, buirg, itn, itnExt, true);
    }

    @Override
    public OrgId update(OrgId orgId) {
        Objects.requireNonNull(orgId, "orgId");
        if (orgId.orgIdKey() == null) {
            throw new IllegalArgumentException("org_id_key обязателен");
        }
        if (ogService.getById(orgId.org()).isEmpty()) {
            throw new IllegalArgumentException("Организация не найдена: ogKey=" + orgId.org());
        }
        if (orgId.orgIdType() == OrgId.TYPE_BUIRG) {
            if (orgId.orgIdValueL() == null || orgId.orgIdValueL() <= 0) {
                throw new IllegalArgumentException("Для БУиРГ нужен положительный цифровой ключ");
            }
            Optional<OrgId> existing = orgIdDao.findBuirg(orgId.orgIdValueL());
            if (existing.isPresent() && !existing.get().orgIdKey().equals(orgId.orgIdKey())) {
                throw new IllegalArgumentException(
                        "Код БУиРГ " + orgId.orgIdValueL() + " уже привязан к ogKey=" + existing.get().org()
                );
            }
        }
        return orgIdDao.update(new OrgId(
                orgId.orgIdKey(),
                orgId.org(),
                orgId.orgIdType(),
                orgId.orgIdValueL(),
                normalizeText(orgId.orgIdValueT()),
                normalizeText(orgId.orgIdValueTExt())
        ));
    }

    private List<OrgId> attachIdsInternal(
            int orgKey,
            Integer buirg,
            String itn,
            String itnExt,
            boolean requireAtLeastOne
    ) {
        String normalizedItn = normalizeText(itn);
        String normalizedExt = normalizeText(itnExt);
        boolean hasBuirg = buirg != null;
        boolean hasItn = normalizedItn != null;
        if (requireAtLeastOne && !hasBuirg && !hasItn) {
            throw new IllegalArgumentException("Укажите код БУиРГ и/или ИНН");
        }
        if (hasBuirg && buirg <= 0) {
            throw new IllegalArgumentException("Код БУиРГ должен быть положительным: " + buirg);
        }
        List<OrgId> result = new ArrayList<>();
        if (hasBuirg) {
            result.add(attachBuirg(orgKey, buirg));
        }
        if (hasItn) {
            result.add(attachItn(orgKey, normalizedItn, normalizedExt));
        }
        return List.copyOf(result);
    }

    private OrgId attachBuirg(int orgKey, int buirg) {
        Optional<OrgId> existing = orgIdDao.findBuirg(buirg);
        if (existing.isPresent()) {
            OrgId row = existing.get();
            if (row.org() == orgKey) {
                return row;
            }
            throw new IllegalArgumentException(
                    "Код БУиРГ " + buirg + " уже привязан к организации ogKey=" + row.org()
            );
        }
        return orgIdDao.create(new OrgId(null, orgKey, OrgId.TYPE_BUIRG, buirg, null, null));
    }

    private OrgId attachItn(int orgKey, String itn, String itnExt) {
        if (orgIdDao.existsItnForOrg(orgKey, itn, itnExt)) {
            return orgIdDao.findByOrg(orgKey).stream()
                    .filter(r -> r.orgIdType() == OrgId.TYPE_ITN && itn.equals(r.orgIdValueT()))
                    .filter(r -> Objects.equals(normalizeText(r.orgIdValueTExt()), itnExt))
                    .findFirst()
                    .orElseThrow(() -> new IllegalStateException("ИНН/КПП найдены, но строка не прочитана"));
        }
        // Дописать КПП к уже существующему ИНН без расширения (типичный случай головной организации).
        if (itnExt != null) {
            Optional<OrgId> withoutExt = orgIdDao.findByOrg(orgKey).stream()
                    .filter(r -> r.orgIdType() == OrgId.TYPE_ITN && itn.equals(r.orgIdValueT()))
                    .filter(r -> normalizeText(r.orgIdValueTExt()) == null)
                    .findFirst();
            if (withoutExt.isPresent()) {
                OrgId row = withoutExt.get();
                log.log(Level.INFO, "Upgrading org_id_key={0} with KPP for org={1}",
                        new Object[]{row.orgIdKey(), orgKey});
                return orgIdDao.update(new OrgId(
                        row.orgIdKey(),
                        row.org(),
                        row.orgIdType(),
                        row.orgIdValueL(),
                        itn,
                        itnExt
                ));
            }
        }
        return orgIdDao.create(new OrgId(null, orgKey, OrgId.TYPE_ITN, null, itn, itnExt));
    }

    private static String normalizeText(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
