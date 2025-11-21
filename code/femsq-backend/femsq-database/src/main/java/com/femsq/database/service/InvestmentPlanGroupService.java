package com.femsq.database.service;

import com.femsq.database.model.InvestmentPlanGroup;
import java.util.List;

/** Сервис для справочника групп планов инвестиционных программ. */
public interface InvestmentPlanGroupService {

    List<InvestmentPlanGroup> getAll();
}
