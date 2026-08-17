package com.femsq.database.service;

import com.femsq.database.model.CnContractCreate;
import com.femsq.database.model.CnContractCreated;
import com.femsq.database.model.CnNumTypeLookup;
import java.util.List;

/**
 * Ручное создание договора с исполнителем (экран «Договоры»).
 */
public interface CnContractService {

    /**
     * @param input параметры
     * @return ключи
     */
    CnContractCreated createWithPerformer(CnContractCreate input);

    /**
     * @return типы номера
     */
    List<CnNumTypeLookup> getNumTypes();

    /**
     * Число уже существующих номеров с тем же текстом (коллизия — на решение оператора).
     *
     * @param cnnNum номер
     * @return count
     */
    int countByCnnNum(String cnnNum);
}
