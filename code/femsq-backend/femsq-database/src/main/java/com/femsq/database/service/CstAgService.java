package com.femsq.database.service;

import com.femsq.database.model.CstAg;
import java.util.List;
import java.util.Optional;

/**
 * Сервис агентов на стройках {@code ags.cstAg}.
 */
public interface CstAgService {

    List<CstAg> getForCst(int cstKey);

    Optional<CstAg> getById(int cstaKey);

    CstAg create(CstAg agent);

    CstAg update(CstAg agent);

    boolean delete(int cstaKey);
}
