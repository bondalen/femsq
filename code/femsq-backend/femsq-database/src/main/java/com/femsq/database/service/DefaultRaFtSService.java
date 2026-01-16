package com.femsq.database.service;

import com.femsq.database.dao.RaFtSDao;
import com.femsq.database.dao.RaFtStDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaFtS;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Реализация {@link RaFtSService}, обеспечивающая базовую бизнес-валидацию.
 */
public class DefaultRaFtSService implements RaFtSService {

    private static final Logger log = Logger.getLogger(DefaultRaFtSService.class.getName());

    private final RaFtSDao raFtSDao;
    private final RaFtStDao raFtStDao;

    public DefaultRaFtSService(RaFtSDao raFtSDao, RaFtStDao raFtStDao) {
        this.raFtSDao = Objects.requireNonNull(raFtSDao, "raFtSDao");
        this.raFtStDao = Objects.requireNonNull(raFtStDao, "raFtStDao");
    }

    @Override
    public List<RaFtS> getAll() {
        return raFtSDao.findAll();
    }

    @Override
    public Optional<RaFtS> getById(int ftSKey) {
        return raFtSDao.findById(ftSKey);
    }

    @Override
    public List<RaFtS> getByFileType(int fileType) {
        return raFtSDao.findByFileType(fileType);
    }

    @Override
    public List<RaFtS> getBySheetType(int sheetType) {
        return raFtSDao.findBySheetType(sheetType);
    }

    @Override
    public RaFtS create(RaFtS raFtS) {
        validateNewFileSource(raFtS);
        try {
            return raFtSDao.create(raFtS);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to create file source type={0}, num={1}", new Object[]{raFtS.ftSType(), raFtS.ftSNum()});
            throw exception;
        }
    }

    @Override
    public RaFtS update(RaFtS raFtS) {
        validateExistingFileSource(raFtS);
        try {
            return raFtSDao.update(raFtS);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to update file source {0}", raFtS.ftSKey());
            throw exception;
        }
    }

    @Override
    public boolean delete(int ftSKey) {
        try {
            return raFtSDao.deleteById(ftSKey);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to delete file source {0}", ftSKey);
            throw exception;
        }
    }

    private void validateNewFileSource(RaFtS raFtS) {
        Objects.requireNonNull(raFtS, "raFtS");
        if (raFtS.ftSKey() != null) {
            throw new IllegalArgumentException("Новый источник не должен содержать идентификатор");
        }
        validateCommonFields(raFtS);
        
        // Проверка существования типа источника
        if (raFtStDao.findById(raFtS.ftSSheetType()).isEmpty()) {
            throw new IllegalArgumentException("Тип источника с идентификатором " + raFtS.ftSSheetType() + " не найден");
        }
    }

    private void validateExistingFileSource(RaFtS raFtS) {
        Objects.requireNonNull(raFtS, "raFtS");
        if (raFtS.ftSKey() == null) {
            throw new IllegalArgumentException("Для обновления источника требуется идентификатор");
        }
        validateCommonFields(raFtS);
        
        // Проверка существования типа источника
        if (raFtStDao.findById(raFtS.ftSSheetType()).isEmpty()) {
            throw new IllegalArgumentException("Тип источника с идентификатором " + raFtS.ftSSheetType() + " не найден");
        }
    }

    private void validateCommonFields(RaFtS raFtS) {
        if (raFtS.ftSType() == null) {
            throw new IllegalArgumentException("Тип файла обязателен");
        }
        if (raFtS.ftSType() < 1 || raFtS.ftSType() > 6) {
            throw new IllegalArgumentException("Тип файла должен быть в диапазоне от 1 до 6");
        }
        if (raFtS.ftSNum() == null) {
            throw new IllegalArgumentException("Номер источника обязателен");
        }
        if (raFtS.ftSSheetType() == null) {
            throw new IllegalArgumentException("Тип источника обязателен");
        }
    }
}
