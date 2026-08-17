package com.femsq.database.service;

import com.femsq.database.dao.OgNmFDao;
import com.femsq.database.model.OgNmF;
import java.util.List;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Реализация {@link OgNmFService}.
 */
public class DefaultOgNmFService implements OgNmFService {

    private static final Logger log = Logger.getLogger(DefaultOgNmFService.class.getName());

    private final OgNmFDao ogNmFDao;
    private final OgService ogService;

    /**
     * @param ogNmFDao DAO
     * @param ogService проверка существования og
     */
    public DefaultOgNmFService(OgNmFDao ogNmFDao, OgService ogService) {
        this.ogNmFDao = Objects.requireNonNull(ogNmFDao, "ogNmFDao");
        this.ogService = Objects.requireNonNull(ogService, "ogService");
    }

    @Override
    public List<OgNmF> listByOrg(int ogKey) {
        requireOrg(ogKey);
        return ogNmFDao.findByOrg(ogKey);
    }

    @Override
    public OgNmF create(OgNmF row) {
        Objects.requireNonNull(row, "row");
        requireOrg(row.onfOg());
        requireName(row.onfName());
        log.log(Level.INFO, "create ogNmF onfOg={0} name={1}", new Object[]{row.onfOg(), row.onfName()});
        return ogNmFDao.create(normalize(row));
    }

    @Override
    public OgNmF update(OgNmF row) {
        Objects.requireNonNull(row, "row");
        if (row.onfKey() == null) {
            throw new IllegalArgumentException("onfKey обязателен для обновления");
        }
        requireOrg(row.onfOg());
        requireName(row.onfName());
        return ogNmFDao.update(normalize(row));
    }

    @Override
    public boolean delete(int onfKey) {
        if (onfKey <= 0) {
            throw new IllegalArgumentException("onfKey должен быть положительным: " + onfKey);
        }
        return ogNmFDao.deleteById(onfKey);
    }

    private void requireOrg(int ogKey) {
        if (ogKey <= 0) {
            throw new IllegalArgumentException("onfOg должен быть положительным: " + ogKey);
        }
        if (ogService.getById(ogKey).isEmpty()) {
            throw new IllegalArgumentException("Организация не найдена: ogKey=" + ogKey);
        }
    }

    private static void requireName(String name) {
        if (name == null || name.isBlank()) {
            throw new IllegalArgumentException("onfName (организация) обязателен");
        }
    }

    private static OgNmF normalize(OgNmF row) {
        String name = row.onfName() == null ? null : row.onfName().trim();
        String ext = row.onfNameExt() == null || row.onfNameExt().isBlank()
                ? null
                : row.onfNameExt().trim();
        return new OgNmF(row.onfKey(), row.onfOg(), name, ext, row.onfStart(), row.onfEnd());
    }
}
