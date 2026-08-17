package com.femsq.database.dao;

import com.femsq.database.model.OgNmF;
import java.util.List;

/**
 * Доступ к {@code ags.ogNmF}.
 */
public interface OgNmFDao {

    /**
     * Варианты имён организации.
     *
     * @param ogKey {@code onfOg}
     * @return строки
     */
    List<OgNmF> findByOrg(int ogKey);

    /**
     * Вставка (IDENTITY {@code onfKey}).
     *
     * @param row без ключа
     * @return с ключом
     */
    OgNmF create(OgNmF row);

    /**
     * Обновление имени/филиала/дат.
     *
     * @param row с ключом
     * @return актуальная
     */
    OgNmF update(OgNmF row);

    /**
     * Удаление строки.
     *
     * @param onfKey PK
     * @return true если удалено
     */
    boolean deleteById(int onfKey);
}
