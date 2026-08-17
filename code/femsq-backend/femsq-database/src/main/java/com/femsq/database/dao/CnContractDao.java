package com.femsq.database.dao;

import com.femsq.database.model.CnContractCreate;
import com.femsq.database.model.CnContractCreated;
import com.femsq.database.model.CnNumTypeLookup;
import java.util.List;

/**
 * DAO составного создания договора + lookup типов номера.
 */
public interface CnContractDao {

    /**
     * Создаёт {@code cn} → {@code cnNum} → {@code cn_s}(исполнитель) → smpl → org в одной транзакции.
     *
     * @param input параметры
     * @return ключи созданных строк
     */
    CnContractCreated createWithPerformer(CnContractCreate input);

    /**
     * Справочник {@code cnNumType}.
     *
     * @return типы номера
     */
    List<CnNumTypeLookup> findNumTypes();

    /**
     * Сколько уже есть номеров с тем же текстом (для предупреждения о коллизии).
     *
     * @param cnnNum номер
     * @return число совпадений
     */
    int countByCnnNum(String cnnNum);
}
