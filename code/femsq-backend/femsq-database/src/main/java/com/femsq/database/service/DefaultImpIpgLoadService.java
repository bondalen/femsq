package com.femsq.database.service;

import com.femsq.database.dao.ImpIpgLoadDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.ImpIpgLoad;
import com.femsq.database.model.ImpIpgRow;
import com.femsq.database.model.ImpIpgStagingDraft;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Logger;

/**
 * Реализация {@link ImpIpgLoadService}.
 */
public class DefaultImpIpgLoadService implements ImpIpgLoadService {

    private static final Logger log = Logger.getLogger(DefaultImpIpgLoadService.class.getName());

    private final ImpIpgLoadDao dao;

    public DefaultImpIpgLoadService(ImpIpgLoadDao dao) {
        this.dao = Objects.requireNonNull(dao, "dao");
    }

    @Override
    public Optional<ImpIpgLoad> getLoad(int iilKey) {
        return dao.findLoadByKey(iilKey);
    }

    @Override
    public List<ImpIpgLoad> listLoadsByIpg(int ipgKey) {
        return dao.findLoadsByIpg(ipgKey);
    }

    @Override
    public ImpIpgLoad createLoad(int ipgKey, String name, String filePath, String note) {
        requireName(name);
        log.info(() -> "createLoad ipg=" + ipgKey + " name=" + name);
        return dao.insertLoad(ipgKey, name.trim(), blankToNull(filePath), blankToNull(note));
    }

    @Override
    public ImpIpgLoad updateLoad(int iilKey, String name, String filePath, String note) {
        requireName(name);
        return dao.updateLoad(iilKey, name.trim(), blankToNull(filePath), blankToNull(note));
    }

    @Override
    public boolean deleteLoad(int iilKey) {
        log.info(() -> "deleteLoad iilKey=" + iilKey);
        return dao.deleteLoad(iilKey);
    }

    @Override
    public Optional<ImpIpgRow> getRow(int iiKey) {
        return dao.findRowByKey(iiKey);
    }

    @Override
    public List<ImpIpgRow> listRows(int iilKey) {
        return dao.findRowsByLoad(iilKey);
    }

    @Override
    public List<ImpIpgRow> listStructureRows(int iilKey) {
        return dao.findStructureRowsByLoad(iilKey);
    }

    @Override
    public ImpIpgRow createRow(
            int loadKey,
            int rowNo,
            String rowKind,
            String text,
            Integer parentKey,
            Integer stiKey,
            String ctx) {
        return dao.insertRow(loadKey, rowNo, rowKind, blankToNull(text), parentKey, stiKey, blankToNull(ctx));
    }

    @Override
    public ImpIpgRow updateRow(
            int iiKey,
            Integer rowNo,
            String rowKind,
            String text,
            Integer parentKey,
            Integer stiKey,
            boolean clearStiKey,
            String ctx) {
        ImpIpgRow current = dao.findRowByKey(iiKey)
                .orElseThrow(() -> new DaoException("impIpg не найден: " + iiKey));
        Integer resolvedSti = clearStiKey ? null : (stiKey != null ? stiKey : current.iiStiKey());
        return dao.updateRow(
                iiKey,
                rowNo != null ? rowNo : current.iiRowNo(),
                rowKind != null ? rowKind : current.iiRowKind(),
                text != null ? text : current.iiText(),
                parentKey != null ? parentKey : current.iiParent(),
                resolvedSti,
                ctx != null ? ctx : current.iiCtx());
    }

    @Override
    public boolean deleteRow(int iiKey) {
        return dao.deleteRow(iiKey);
    }

    @Override
    public int clearRows(int iilKey) {
        log.info(() -> "clearRows load=" + iilKey);
        return dao.deleteRowsByLoad(iilKey);
    }

    @Override
    public int replaceStaging(int iilKey, List<ImpIpgStagingDraft> drafts) {
        Objects.requireNonNull(drafts, "drafts");
        log.info(() -> "replaceStaging load=" + iilKey + " drafts=" + drafts.size());
        return dao.replaceRows(iilKey, drafts);
    }

    private static void requireName(String name) {
        if (name == null || name.isBlank()) {
            throw new DaoException("Наименование сессии загрузки обязательно");
        }
    }

    private static String blankToNull(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }
}
