package com.femsq.database.service;

import com.femsq.database.model.RaSumm;
import java.util.List;
import java.util.Optional;

/**
 * Сервис сумм отчёта {@code ags.ra_summ}.
 */
public interface RaSummService {

    Optional<RaSumm> getById(int rasKey);

    List<RaSumm> getForRa(int raKey);

    RaSumm create(RaSumm summ);

    RaSumm update(RaSumm summ);

    boolean delete(int rasKey);
}
