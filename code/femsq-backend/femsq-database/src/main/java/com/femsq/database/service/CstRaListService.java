package com.femsq.database.service;

import com.femsq.database.model.CstRaListEntry;
import java.util.List;

/**
 * Сервис перечня отчётов стройки ({@code ags.fnRRcList}).
 */
public interface CstRaListService {

    /**
     * Перечень отчётов и изменений для стройки.
     */
    List<CstRaListEntry> getForCst(int cstKey);
}
