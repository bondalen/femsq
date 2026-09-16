package com.femsq.database.service;

import com.femsq.database.model.CnContractCreate;
import com.femsq.database.model.CnContractCreated;
import com.femsq.database.model.CnNumTypeLookup;
import java.time.LocalDate;
import java.util.List;
import java.util.OptionalInt;

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

    /**
     * Полный клон ключа воронки (номер + дата исполнителя + сторона).
     *
     * @param cnnNum номер
     * @param csoCnDate дата; {@code null} = без даты
     * @param csosOrgId PK {@code org_id}
     * @return существующий {@code cn_key}, если клон есть
     */
    OptionalInt findCnKeyByPerformerIdentity(String cnnNum, LocalDate csoCnDate, int csosOrgId);

    /**
     * Удаляет договор без связей cnInv (стороны и номера — каскадом).
     *
     * @param cnKey PK {@code ags.cn}
     * @return {@code true}, если cn удалён
     */
    boolean deleteByCnKey(int cnKey);
}
