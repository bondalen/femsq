package com.femsq.database.dao;

import com.femsq.database.model.CnContractCreate;
import com.femsq.database.model.CnContractCreated;
import com.femsq.database.model.CnNumTypeLookup;
import java.time.LocalDate;
import java.util.List;
import java.util.OptionalInt;

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

    /**
     * Ищет договор с тем же ключом воронки: {@code cnnNumNull} + дата исполнителя
     * ({@code NULL} ≡ 1900-01-01) + {@code org_id_value_l} выбранного {@code org_id}.
     * Без исполнителя идентичность неполная — возвращает empty.
     *
     * @param cnnNum номер (пусто → {@code NullИлиПусто})
     * @param csoCnDate дата стороны; {@code null} как в своде без даты
     * @param csosOrgId PK {@code ags.org_id}
     * @return {@code cn_key} существующего клона, если есть
     */
    OptionalInt findCnKeyByPerformerIdentity(String cnnNum, LocalDate csoCnDate, int csosOrgId);

    /**
     * Удаляет договор и дочерние cn_s/cnNum, если нет связей cnInv.
     *
     * @param cnKey PK {@code ags.cn}
     * @return {@code true}, если строка cn удалена
     */
    boolean deleteByCnKey(int cnKey);
}
