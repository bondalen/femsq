package com.femsq.database.service;

import com.femsq.database.model.ImpIpgLoad;
import com.femsq.database.model.ImpIpgRow;
import com.femsq.database.model.ImpIpgStagingDraft;
import java.util.List;
import java.util.Optional;

/**
 * Сервис сессий загрузки ИП / staging ({@code impIpgLoad}, {@code impIpg}).
 */
public interface ImpIpgLoadService {

    Optional<ImpIpgLoad> getLoad(int iilKey);

    List<ImpIpgLoad> listLoadsByIpg(int ipgKey);

    ImpIpgLoad createLoad(int ipgKey, String name, String filePath, String note);

    ImpIpgLoad updateLoad(int iilKey, String name, String filePath, String note);

    boolean deleteLoad(int iilKey);

    Optional<ImpIpgRow> getRow(int iiKey);

    List<ImpIpgRow> listRows(int iilKey);

    List<ImpIpgRow> listStructureRows(int iilKey);

    ImpIpgRow createRow(
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
            boolean clearStiKey,
            String ctx);

    boolean deleteRow(int iiKey);

    int clearRows(int iilKey);

    /**
     * Заменяет тело staging сессии результатами парсера Excel.
     *
     * @return число записанных строк
     */
    int replaceStaging(int iilKey, List<ImpIpgStagingDraft> drafts);
}
