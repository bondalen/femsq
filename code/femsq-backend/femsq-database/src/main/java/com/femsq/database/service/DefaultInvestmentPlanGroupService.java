package com.femsq.database.service;

import com.femsq.database.dao.InvestmentPlanGroupDao;
import com.femsq.database.model.InvestmentPlanGroup;
import java.util.List;
import java.util.Objects;

/** Реализация {@link InvestmentPlanGroupService}. */
public class DefaultInvestmentPlanGroupService implements InvestmentPlanGroupService {

    private final InvestmentPlanGroupDao planGroupDao;

    public DefaultInvestmentPlanGroupService(InvestmentPlanGroupDao planGroupDao) {
        this.planGroupDao = Objects.requireNonNull(planGroupDao, "planGroupDao");
    }

    @Override
    public List<InvestmentPlanGroup> getAll() {
        return planGroupDao.findAllWithDisplayName();
    }
}
