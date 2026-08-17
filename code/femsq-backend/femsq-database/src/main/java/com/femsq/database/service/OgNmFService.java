package com.femsq.database.service;

import com.femsq.database.model.OgNmF;
import java.util.List;

/**
 * Сервис вариантов наименований ({@code ags.ogNmF}).
 */
public interface OgNmFService {

    /**
     * @param ogKey организация
     * @return варианты имён
     */
    List<OgNmF> listByOrg(int ogKey);

    /**
     * @param row без onfKey
     * @return созданная
     */
    OgNmF create(OgNmF row);

    /**
     * @param row с onfKey
     * @return обновлённая
     */
    OgNmF update(OgNmF row);

    /**
     * @param onfKey PK
     * @return true если удалено
     */
    boolean delete(int onfKey);
}
