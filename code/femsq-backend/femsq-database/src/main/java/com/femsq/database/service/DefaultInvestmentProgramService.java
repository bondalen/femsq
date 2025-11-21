package com.femsq.database.service;

import com.femsq.database.dao.InvestmentProgramDao;
import com.femsq.database.model.InvestmentProgram;
import java.util.List;
import java.util.Objects;

/** Реализация {@link InvestmentProgramService}. */
public class DefaultInvestmentProgramService implements InvestmentProgramService {

    private final InvestmentProgramDao investmentProgramDao;

    public DefaultInvestmentProgramService(InvestmentProgramDao investmentProgramDao) {
        this.investmentProgramDao = Objects.requireNonNull(investmentProgramDao, "investmentProgramDao");
    }

    @Override
    public List<InvestmentProgram> getAll() {
        return investmentProgramDao.findAllWithDisplayName();
    }
}
