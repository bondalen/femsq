package com.femsq.database.dao;

import com.femsq.database.model.OrgId;
import java.util.List;
import java.util.Optional;

/**
 * Доступ к {@code ags.org_id} (коды БУиРГ / ИНН организаций).
 */
public interface OrgIdDao {

    /**
     * Идентификаторы организации.
     *
     * @param orgKey {@code og.ogKey}
     * @return список (type 1/2)
     */
    List<OrgId> findByOrg(int orgKey);

    /**
     * Поиск type=1 по коду БУиРГ.
     *
     * @param buirg {@code org_id_value_l}
     * @return запись или empty
     */
    Optional<OrgId> findBuirg(int buirg);

    /**
     * Есть ли у организации ИНН с тем же расширением (КПП).
     *
     * @param orgKey ogKey
     * @param itn ИНН
     * @param itnExt КПП / расширение (nullable)
     * @return true если есть
     */
    boolean existsItnForOrg(int orgKey, String itn, String itnExt);

    /**
     * Вставка идентификатора ({@code org_id_key} IDENTITY).
     *
     * @param orgId без ключа
     * @return с ключом
     */
    OrgId create(OrgId orgId);

    /**
     * Обновление значений идентификатора (в т.ч. КПП в {@code org_id_value_t_ext}).
     *
     * @param orgId с ключом
     * @return актуальная
     */
    OrgId update(OrgId orgId);
}
