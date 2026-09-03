package com.femsq.database.dao;

import com.femsq.database.model.CnNum;
import com.femsq.database.model.CnNumCreate;
import java.util.List;

/**
 * DAO номеров договоров {@code ags.cnNum}.
 */
public interface CnNumDao {

    /**
     * Все номера с именем типа, сортировка по {@code cnnNum}.
     */
    List<CnNum> findAll();

    /**
     * Номера, привязанные к договору.
     */
    List<CnNum> findByCnKey(int cnKey);

    /**
     * Добавляет номер к существующему договору.
     *
     * @param input cnKey, cnnNum, cnnType
     * @return созданная строка cnNum
     */
    CnNum create(CnNumCreate input);
}
