package com.femsq.database.service;

import com.femsq.database.model.CstAgPnBranch;
import java.util.List;
import java.util.Optional;

/**
 * Сервис филиалов САК {@code ags.cstAgPnBranch}.
 */
public interface CstAgPnBranchService {

    List<CstAgPnBranch> getForCstAgPn(int cstapKey);

    Optional<CstAgPnBranch> getById(int cstapbKey);

    CstAgPnBranch create(CstAgPnBranch branch);

    CstAgPnBranch update(CstAgPnBranch branch);

    boolean delete(int cstapbKey);
}
