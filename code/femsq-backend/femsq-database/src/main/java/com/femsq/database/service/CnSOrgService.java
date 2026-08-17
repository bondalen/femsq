package com.femsq.database.service;

import com.femsq.database.model.CnSOrg;
import java.util.List;
import java.util.Optional;

/**
 * Сервис {@code cn_s_org}.
 */
public interface CnSOrgService {

    /**
     * @param csosKey smpl
     * @return org-строки
     */
    List<CnSOrg> getForSmpl(int csosKey);

    /**
     * @param cnKey договор
     * @return все org договора
     */
    List<CnSOrg> getForCn(int cnKey);

    /**
     * @param cnSOrgKey PK
     * @return org
     */
    Optional<CnSOrg> getById(int cnSOrgKey);

    /**
     * @param org без PK
     * @return созданная
     */
    CnSOrg create(CnSOrg org);

    /**
     * @param org с PK
     * @return обновлённая
     */
    CnSOrg update(CnSOrg org);

    /**
     * @param cnSOrgKey PK
     * @return true если удалена
     */
    boolean delete(int cnSOrgKey);
}
