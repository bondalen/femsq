package com.femsq.database.dao;

import com.femsq.database.model.CnSOrg;
import java.util.List;
import java.util.Optional;

/**
 * DAO {@code ags.cn_s_org}.
 */
public interface CnSOrgDao {

    /**
     * @param cnSOrgKey PK
     * @return org или empty
     */
    Optional<CnSOrg> findById(int cnSOrgKey);

    /**
     * @param csosKey {@code csoCn_s_org_smpl}
     * @return строки с датами
     */
    List<CnSOrg> findByCsosKey(int csosKey);

    /**
     * Все org-строки договора (для сборки дерева).
     *
     * @param cnKey {@code cn_key}
     * @return список
     */
    List<CnSOrg> findByCnKey(int cnKey);

    /**
     * @param org без PK
     * @return с PK
     */
    CnSOrg create(CnSOrg org);

    /**
     * @param org с PK
     * @return актуальная
     */
    CnSOrg update(CnSOrg org);

    /**
     * @param cnSOrgKey PK
     * @return true если удалена
     */
    boolean deleteById(int cnSOrgKey);

    /**
     * Удаляет все org по smpl.
     *
     * @param csosKey {@code csoCn_s_org_smpl}
     * @return число удалённых
     */
    int deleteByCsosKey(int csosKey);
}
