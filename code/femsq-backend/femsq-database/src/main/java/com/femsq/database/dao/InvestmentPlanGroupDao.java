package com.femsq.database.dao;

import com.femsq.database.model.InvestmentPlanGroup;
import java.util.List;

/** DAO для справочника групп планов ({@code ags.ipgUtPlGr}). */
public interface InvestmentPlanGroupDao {

    /** Возвращает все группы планов с отформатированными названиями. */
    List<InvestmentPlanGroup> findAllWithDisplayName();
}
