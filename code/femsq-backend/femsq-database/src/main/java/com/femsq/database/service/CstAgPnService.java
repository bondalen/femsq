package com.femsq.database.service;

import com.femsq.database.model.CstAgPn;
import com.femsq.database.model.CstAgPnCode;
import com.femsq.database.model.CstAgPnSiteLookup;
import java.util.List;
import java.util.Optional;

/**
 * Сервис САК {@code ags.cstAgPn}.
 */
public interface CstAgPnService {

    List<CstAgPn> getForCstAg(int cstaKey);

    Optional<CstAgPn> getById(int cstapKey);

    /**
     * Список САК для формы поиска по коду.
     */
    List<CstAgPnCode> getCodes(String codeFilter);

    /**
     * Lookup САК стройки для combo {@code ra_cac}.
     */
    List<CstAgPnSiteLookup> getSiteLookups(int cstKey);

    CstAgPn create(CstAgPn point);

    CstAgPn update(CstAgPn point);

    boolean delete(int cstapKey);
}
