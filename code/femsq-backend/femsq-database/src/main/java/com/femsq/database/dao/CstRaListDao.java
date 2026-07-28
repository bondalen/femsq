package com.femsq.database.dao;

import com.femsq.database.model.CstRaListEntry;
import java.util.List;

/**
 * DAO перечня отчётов стройки через {@code ags.fnRRcList}.
 */
public interface CstRaListDao {

    /**
     * Возвращает отчёты и изменения для стройки, упорядоченные по году/месяцу/номеру.
     *
     * @param cstKey идентификатор стройки ({@code cstaCst})
     */
    List<CstRaListEntry> findByCst(int cstKey);
}
