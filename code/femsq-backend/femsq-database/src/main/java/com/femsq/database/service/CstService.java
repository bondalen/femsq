package com.femsq.database.service;

import com.femsq.database.model.Cst;
import java.util.List;
import java.util.Optional;

/**
 * Сервис строек {@code ags.cst}.
 */
public interface CstService {

    List<Cst> getAll();

    Optional<Cst> getById(int cstKey);

    Cst create(Cst site);

    Cst update(Cst site);

    boolean delete(int cstKey);
}
