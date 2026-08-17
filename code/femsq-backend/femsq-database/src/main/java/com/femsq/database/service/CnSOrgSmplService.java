package com.femsq.database.service;

import com.femsq.database.model.CnSOrgIdLookup;
import com.femsq.database.model.CnSOrgSmpl;
import java.util.List;
import java.util.Optional;

/**
 * Сервис {@code cn_s_org_smpl}.
 */
public interface CnSOrgSmplService {

    /**
     * @param cnSKey сторона
     * @return smpl
     */
    List<CnSOrgSmpl> getForCnS(int cnSKey);

    /**
     * @param cnKey договор
     * @return все smpl договора
     */
    List<CnSOrgSmpl> getForCn(int cnKey);

    /**
     * @param csosKey PK
     * @return smpl
     */
    Optional<CnSOrgSmpl> getById(int csosKey);

    /**
     * Lookup БУиРГ для выбора {@code csosOrgId}.
     *
     * @return список
     */
    List<CnSOrgIdLookup> getOrgIdLookups();

    /**
     * @param smpl без PK
     * @return созданная
     */
    CnSOrgSmpl create(CnSOrgSmpl smpl);

    /**
     * @param smpl с PK
     * @return обновлённая
     */
    CnSOrgSmpl update(CnSOrgSmpl smpl);

    /**
     * Каскадно удаляет org → smpl.
     *
     * @param csosKey PK
     * @return true если удалена
     */
    boolean delete(int csosKey);
}
