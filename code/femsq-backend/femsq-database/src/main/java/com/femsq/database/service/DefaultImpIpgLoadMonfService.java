package com.femsq.database.service;

import com.femsq.database.dao.ImpIpgLoadDao;
import com.femsq.database.dao.ImpIpgLoadMonfDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.ImpIpgLoadMonf;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Logger;

/**
 * Реализация {@link ImpIpgLoadMonfService}.
 */
public class DefaultImpIpgLoadMonfService implements ImpIpgLoadMonfService {

    private static final Logger log = Logger.getLogger(DefaultImpIpgLoadMonfService.class.getName());

    private final ImpIpgLoadMonfDao monfDao;
    private final ImpIpgLoadDao loadDao;

    public DefaultImpIpgLoadMonfService(ImpIpgLoadMonfDao monfDao, ImpIpgLoadDao loadDao) {
        this.monfDao = Objects.requireNonNull(monfDao, "monfDao");
        this.loadDao = Objects.requireNonNull(loadDao, "loadDao");
    }

    @Override
    public List<ImpIpgLoadMonf> listByLoad(int loadKey) {
        return monfDao.findByLoad(loadKey);
    }

    @Override
    public List<ImpIpgLoadMonf> listByIpg(int ipgKey) {
        return monfDao.findByIpg(ipgKey);
    }

    @Override
    public Optional<ImpIpgLoadMonf> get(int iilmKey) {
        return monfDao.findByKey(iilmKey);
    }

    @Override
    public ImpIpgLoadMonf create(
            int loadKey,
            Integer utPlKey,
            String name,
            String filePath,
            String sheet,
            String limColumn,
            boolean quarter,
            Integer sumFirst,
            String note) {
        requireName(name);
        if (loadDao.findLoadByKey(loadKey).isEmpty()) {
            throw new DaoException("Сессия impIpgLoad не найдена: " + loadKey);
        }
        log.info(() -> "createMonf load=" + loadKey + " name=" + name);
        return monfDao.insert(
                loadKey,
                utPlKey,
                name.trim(),
                blankToNull(filePath),
                blankToNull(sheet),
                blankToNull(limColumn),
                quarter,
                sumFirst,
                blankToNull(note));
    }

    @Override
    public ImpIpgLoadMonf update(
            int iilmKey,
            Integer utPlKey,
            String name,
            String filePath,
            String sheet,
            String limColumn,
            boolean quarter,
            Integer sumFirst,
            String note) {
        requireName(name);
        return monfDao.update(
                iilmKey,
                utPlKey,
                name.trim(),
                blankToNull(filePath),
                blankToNull(sheet),
                blankToNull(limColumn),
                quarter,
                sumFirst,
                blankToNull(note));
    }

    @Override
    public boolean delete(int iilmKey) {
        log.info(() -> "deleteMonf iilmKey=" + iilmKey);
        return monfDao.delete(iilmKey);
    }

    @Override
    public void updateResults(int iilmKey, String html) {
        monfDao.updateResults(iilmKey, html);
    }

    private static void requireName(String name) {
        if (name == null || name.isBlank()) {
            throw new DaoException("Наименование строки Monf обязательно");
        }
    }

    private static String blankToNull(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }
}
