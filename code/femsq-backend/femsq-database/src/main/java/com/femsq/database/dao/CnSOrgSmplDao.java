package com.femsq.database.dao;

import com.femsq.database.model.CnSOrgIdLookup;
import com.femsq.database.model.CnSOrgSmpl;
import java.util.List;
import java.util.Optional;

/**
 * DAO {@code ags.cn_s_org_smpl}.
 */
public interface CnSOrgSmplDao {

    /**
     * @param csosKey PK
     * @return smpl или empty
     */
    Optional<CnSOrgSmpl> findById(int csosKey);

    /**
     * @param cnSKey {@code csosCn_s}
     * @return smpl стороны
     */
    List<CnSOrgSmpl> findByCnSKey(int cnSKey);

    /**
     * Все smpl договора (для сборки дерева).
     *
     * @param cnKey {@code cn_key}
     * @return список
     */
    List<CnSOrgSmpl> findByCnKey(int cnKey);

    /**
     * Lookup БУиРГ ({@code org_id_type=1}) для выбора организации.
     *
     * @return список
     */
    List<CnSOrgIdLookup> findOrgIdLookups();

    /**
     * @param smpl без PK
     * @return с PK
     */
    CnSOrgSmpl create(CnSOrgSmpl smpl);

    /**
     * @param smpl с PK
     * @return актуальная
     */
    CnSOrgSmpl update(CnSOrgSmpl smpl);

    /**
     * @param csosKey PK
     * @return true если удалена
     */
    boolean deleteById(int csosKey);
}
