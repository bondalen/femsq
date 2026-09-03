package com.femsq.database.service;

import com.femsq.database.model.CnNum;
import com.femsq.database.model.CnNumCreate;
import java.util.List;

/**
 * Сервис номеров договоров {@code ags.cnNum}.
 */
public interface CnNumService {

    List<CnNum> getAll();

    List<CnNum> getByCnKey(int cnKey);

    /**
     * Добавляет номер к существующему договору.
     */
    CnNum create(CnNumCreate input);
}
