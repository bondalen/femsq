package com.femsq.database.service;

import com.femsq.database.model.CnS;
import java.util.List;
import java.util.Optional;

/**
 * Сервис сторон договора {@code cn_s}.
 */
public interface CnSService {

    /**
     * @param cnKey договор
     * @return стороны
     */
    List<CnS> getForCn(int cnKey);

    /**
     * @param cnSKey PK
     * @return сторона
     */
    Optional<CnS> getById(int cnSKey);

    /**
     * @param side без PK
     * @return созданная
     */
    CnS create(CnS side);

    /**
     * @param side с PK
     * @return обновлённая
     */
    CnS update(CnS side);

    /**
     * Каскадно удаляет org → smpl → сторону.
     *
     * @param cnSKey PK
     * @return true если удалена
     */
    boolean delete(int cnSKey);
}
