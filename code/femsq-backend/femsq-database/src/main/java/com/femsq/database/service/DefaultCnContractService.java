package com.femsq.database.service;

import com.femsq.database.dao.CnContractDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.CnContractCreate;
import com.femsq.database.model.CnContractCreated;
import com.femsq.database.model.CnNumTypeLookup;
import java.util.List;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Реализация {@link CnContractService}.
 */
public class DefaultCnContractService implements CnContractService {

    private static final Logger log = Logger.getLogger(DefaultCnContractService.class.getName());

    private final CnContractDao cnContractDao;

    public DefaultCnContractService(CnContractDao cnContractDao) {
        this.cnContractDao = Objects.requireNonNull(cnContractDao, "cnContractDao");
    }

    @Override
    public CnContractCreated createWithPerformer(CnContractCreate input) {
        Objects.requireNonNull(input, "input");
        try {
            CnContractCreated created = cnContractDao.createWithPerformer(input);
            log.log(Level.INFO, "Created contract cn={0} cnn={1}",
                    new Object[]{created.cnKey(), created.cnnKey()});
            return created;
        } catch (DaoException exception) {
            log.log(Level.SEVERE, "Failed to create contract with performer", exception);
            throw exception;
        }
    }

    @Override
    public List<CnNumTypeLookup> getNumTypes() {
        return cnContractDao.findNumTypes();
    }

    @Override
    public int countByCnnNum(String cnnNum) {
        return cnContractDao.countByCnnNum(cnnNum == null ? "" : cnnNum);
    }
}
