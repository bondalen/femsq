package com.femsq.database.service;

import com.femsq.database.dao.RaFDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaF;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Реализация {@link RaFService}, обеспечивающая базовую бизнес-валидацию.
 */
public class DefaultRaFService implements RaFService {

    private static final Logger log = Logger.getLogger(DefaultRaFService.class.getName());

    private final RaFDao raFDao;

    public DefaultRaFService(RaFDao raFDao) {
        this.raFDao = Objects.requireNonNull(raFDao, "raFDao");
    }

    @Override
    public List<RaF> getAll() {
        return raFDao.findAll();
    }

    @Override
    public Optional<RaF> getById(long afKey) {
        return raFDao.findById(afKey);
    }

    @Override
    public List<RaF> getByAuditId(long adtKey) {
        return raFDao.findByAuditId(adtKey);
    }

    @Override
    public List<RaF> getByDirId(int dirKey) {
        return raFDao.findByDirId(dirKey);
    }

    @Override
    public List<RaF> getByFileType(int fileType) {
        return raFDao.findByFileType(fileType);
    }

    @Override
    public RaF create(RaF raF) {
        validateNewFile(raF);
        try {
            return raFDao.create(raF);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to create file {0}", raF.afName());
            throw exception;
        }
    }

    @Override
    public RaF update(RaF raF) {
        validateExistingFile(raF);
        try {
            return raFDao.update(raF);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to update file {0}", raF.afKey());
            throw exception;
        }
    }

    @Override
    public boolean delete(long afKey) {
        try {
            return raFDao.deleteById(afKey);
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to delete file {0}", afKey);
            throw exception;
        }
    }

    private void validateNewFile(RaF raF) {
        Objects.requireNonNull(raF, "raF");
        if (raF.afKey() != null) {
            throw new IllegalArgumentException("Новый файл не должен содержать идентификатор");
        }
        validateCommonFields(raF);
        
        // Проверка уникальности имени файла в рамках директории
        List<RaF> existingFiles = raFDao.findByDirId(raF.afDir());
        boolean duplicateName = existingFiles.stream()
                .anyMatch(f -> f.afName().equalsIgnoreCase(raF.afName()));
        if (duplicateName) {
            throw new IllegalArgumentException("Файл с именем '" + raF.afName() + "' уже существует для директории " + raF.afDir());
        }
    }

    private void validateExistingFile(RaF raF) {
        Objects.requireNonNull(raF, "raF");
        if (raF.afKey() == null) {
            throw new IllegalArgumentException("Для обновления файла требуется идентификатор");
        }
        validateCommonFields(raF);
        
        // Проверка уникальности имени файла в рамках директории (исключая текущий файл)
        List<RaF> existingFiles = raFDao.findByDirId(raF.afDir());
        boolean duplicateName = existingFiles.stream()
                .filter(f -> !f.afKey().equals(raF.afKey()))
                .anyMatch(f -> f.afName().equalsIgnoreCase(raF.afName()));
        if (duplicateName) {
            throw new IllegalArgumentException("Файл с именем '" + raF.afName() + "' уже существует для директории " + raF.afDir());
        }
    }

    private void validateCommonFields(RaF raF) {
        if (isBlank(raF.afName())) {
            throw new IllegalArgumentException("Имя файла обязательно");
        }
        if (raF.afDir() == null) {
            throw new IllegalArgumentException("Директория обязательна");
        }
        if (raF.afType() == null) {
            throw new IllegalArgumentException("Тип файла обязателен");
        }
        if (raF.afType() < 1 || raF.afType() > 6) {
            throw new IllegalArgumentException("Тип файла должен быть в диапазоне от 1 до 6");
        }
        if (raF.afExecute() == null) {
            throw new IllegalArgumentException("Флаг afExecute обязателен");
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
