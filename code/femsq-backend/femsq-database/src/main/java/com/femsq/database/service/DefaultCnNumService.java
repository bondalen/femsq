package com.femsq.database.service;

import com.femsq.database.dao.CnNumDao;
import com.femsq.database.model.CnNum;
import com.femsq.database.model.CnNumColumnFilters;
import com.femsq.database.model.CnNumCreate;
import com.femsq.database.model.CnNumPage;
import java.util.List;
import java.util.Objects;
import java.util.logging.Logger;

/**
 * Реализация {@link CnNumService}.
 */
public class DefaultCnNumService implements CnNumService {

    private static final Logger log = Logger.getLogger(DefaultCnNumService.class.getName());

    private final CnNumDao cnNumDao;

    public DefaultCnNumService(CnNumDao cnNumDao) {
        this.cnNumDao = Objects.requireNonNull(cnNumDao, "cnNumDao");
    }

    @Override
    public List<CnNum> getAll() {
        log.fine("CnNumService.getAll");
        return cnNumDao.findAll();
    }

    @Override
    public CnNumPage page(
            int page,
            int rowsPerPage,
            String filter,
            CnNumColumnFilters columnFilters,
            String sortBy,
            boolean descending
    ) {
        log.fine(() -> "CnNumService.page page=" + page + " rows=" + rowsPerPage);
        return cnNumDao.findPage(page, rowsPerPage, filter, columnFilters, sortBy, descending);
    }

    @Override
    public List<CnNum> getByCnKey(int cnKey) {
        log.fine(() -> "CnNumService.getByCnKey cnKey=" + cnKey);
        return cnNumDao.findByCnKey(cnKey);
    }

    @Override
    public CnNum create(CnNumCreate input) {
        log.info(() -> "CnNumService.create cnKey=" + input.cnKey());
        return cnNumDao.create(input);
    }
}
