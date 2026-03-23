package com.femsq.database.service;

import com.femsq.database.dao.RaSheetConfDao;
import com.femsq.database.model.RaSheetConf;
import java.util.List;
import java.util.Objects;

/**
 * Реализация {@link RaSheetConfService}.
 */
public class DefaultRaSheetConfService implements RaSheetConfService {

    private final RaSheetConfDao raSheetConfDao;

    public DefaultRaSheetConfService(RaSheetConfDao raSheetConfDao) {
        this.raSheetConfDao = Objects.requireNonNull(raSheetConfDao, "raSheetConfDao");
    }

    @Override
    public List<RaSheetConf> getByFileType(int fileType) {
        return raSheetConfDao.findByFileType(fileType);
    }
}
