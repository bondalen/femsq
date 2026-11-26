package com.femsq.database.dao;

import com.femsq.database.model.ImpIpgLoad;
import com.femsq.database.model.ImpIpgRow;
import com.femsq.database.model.ImpIpgStagingDraft;
import java.util.List;
import java.util.Optional;

/**
 * Доступ к {@code ags.impIpgLoad} / {@code ags.impIpg} (C2 §3.1.6.1).
 */
public interface ImpIpgLoadDao {

    Optional<ImpIpgLoad> findLoadByKey(int iilKey);

    List<ImpIpgLoad> findLoadsByIpg(int ipgKey);

    ImpIpgLoad insertLoad(int ipgKey, String name, String filePath, String note);

    ImpIpgLoad updateLoad(int iilKey, String name, String filePath, String note);

    /**
     * Сохраняет накопительный HTML-лог сессии в {@code iilResults} (C2 §3.5.4).
     *
     * @param iilKey ключ сессии
     * @param html   полный HTML лога (или null — очистить)
     */
    void updateLoadResults(int iilKey, String html);

    /**
     * Удаляет сессию и все строки {@code impIpg} этой сессии.
     */
    boolean deleteLoad(int iilKey);

    Optional<ImpIpgRow> findRowByKey(int iiKey);

    List<ImpIpgRow> findRowsByLoad(int iilKey);

    /** Только разделы ({@code iiRowKind='S'}) — ПТСФ. */
    List<ImpIpgRow> findStructureRowsByLoad(int iilKey);

    ImpIpgRow insertRow(
            int loadKey,
            int rowNo,
            String rowKind,
            String text,
            Integer parentKey,
            Integer stiKey,
            String ctx);

    ImpIpgRow updateRow(
            int iiKey,
            Integer rowNo,
            String rowKind,
            String text,
            Integer parentKey,
            Integer stiKey,
            String ctx);

    boolean deleteRow(int iiKey);

    /** Удаляет все строки staging сессии (перед повторным парсом). */
    int deleteRowsByLoad(int iilKey);

    /**
     * Атомарно очищает staging сессии и вставляет черновики.
     * {@code parentIndex} в черновиках резолвится в {@code iiParent} по порядку вставки.
     *
     * @return число вставленных строк
     */
    int replaceRows(int iilKey, List<ImpIpgStagingDraft> drafts);
}
