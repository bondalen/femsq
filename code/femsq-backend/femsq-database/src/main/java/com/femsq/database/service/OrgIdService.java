package com.femsq.database.service;

import com.femsq.database.model.Og;
import com.femsq.database.model.OrgId;
import java.util.List;
import java.util.Objects;

/**
 * Сервис идентификаторов организаций ({@code ags.org_id}) и создания og+ids.
 */
public interface OrgIdService {

    /**
     * Список идентификаторов организации.
     *
     * @param orgKey ogKey
     * @return type 1/2
     */
    List<OrgId> listByOrg(int orgKey);

    /**
     * Создаёт {@code og} (без записи ИНН в {@code og.ogINN}) и при необходимости
     * строки {@code org_id} type=1 (БУиРГ) и/или type=2 (ИНН[+КПП]).
     *
     * @param organization карточка без ogKey; inn игнорируется
     * @param buirg код БУиРГ или null
     * @param itn ИНН или null/blank
     * @param itnExt КПП в {@code org_id_value_t_ext} или null
     * @return созданная организация
     */
    Og createOrganizationWithIds(Og organization, Integer buirg, String itn, String itnExt);

    /**
     * Привязывает БУиРГ и/или ИНН(+КПП) к существующей организации.
     *
     * @param orgKey ogKey
     * @param buirg код БУиРГ или null
     * @param itn ИНН или null/blank
     * @param itnExt КПП или null
     * @return созданные/существующие записи
     */
    List<OrgId> attachIds(int orgKey, Integer buirg, String itn, String itnExt);

    /**
     * Обновляет строку {@code org_id} (например КПП в расширении).
     *
     * @param orgId с ключом
     * @return актуальная
     */
    OrgId update(OrgId orgId);
}
