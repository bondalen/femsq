package com.femsq.database.dao;

import com.femsq.database.model.CnS;
import java.util.List;
import java.util.Optional;

/**
 * DAO {@code ags.cn_s}.
 */
public interface CnSDao {

    /**
     * @param cnSKey PK
     * @return сторона или empty
     */
    Optional<CnS> findById(int cnSKey);

    /**
     * Стороны договора.
     *
     * @param cnKey {@code cn_key}
     * @return список по типу
     */
    List<CnS> findByCnKey(int cnKey);

    /**
     * @param side без PK
     * @return с PK
     */
    CnS create(CnS side);

    /**
     * @param side с PK
     * @return актуальная
     */
    CnS update(CnS side);

    /**
     * @param cnSKey PK
     * @return true если удалена
     */
    boolean deleteById(int cnSKey);
}
