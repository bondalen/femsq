package com.femsq.database.service;

import com.femsq.database.dao.SudzDao;
import com.femsq.database.model.sudz.SudzCmmGrLookup;
import com.femsq.database.model.sudz.SudzCnInvUplSfDouble;
import com.femsq.database.model.sudz.SudzD644Row;
import com.femsq.database.model.sudz.SudzAccessStrMark;
import com.femsq.database.model.sudz.SudzDbtUplCnCtptExistInvApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplCnCtptExistInvResult;
import com.femsq.database.model.sudz.SudzDbtUplCnExistCtptNotLoad;
import com.femsq.database.model.sudz.SudzDbtUplCnNotLoad;
import com.femsq.database.model.sudz.SudzDbtUplCnNotLoadApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplFile;
import com.femsq.database.model.sudz.SudzDbtUplFunnelResult;
import com.femsq.database.model.sudz.SudzDbtUplFunnelSteps;
import com.femsq.database.model.sudz.SudzDbtUplLauncher;
import com.femsq.database.model.sudz.SudzDbtUplOrgNotInBuirg;
import com.femsq.database.model.sudz.SudzDbtUplTblRow;
import com.femsq.database.model.sudz.SudzDebtCollection;
import com.femsq.database.model.sudz.SudzPmLink;
import com.femsq.database.model.sudz.SudzPmUplLookup;
import com.femsq.database.model.sudz.SudzRsltDebt;
import com.femsq.database.model.sudz.SudzRsltReturnRow;
import com.femsq.database.model.sudz.SudzSfDoubleDomainMatch;
import com.femsq.database.model.sudz.SudzSfDoubleExcelCandidate;
import com.femsq.database.model.sudz.SudzSvodResult;
import com.femsq.database.model.sudz.SudzUplLookup;
import com.femsq.database.model.sudz.SudzYear;
import com.femsq.database.model.sudz.SudzYearDetail;
import com.femsq.database.model.sudz.SudzYearUpl;
import com.femsq.database.model.sudz.SudzYyyyLookup;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Реализация {@link SudzService}.
 */
public class DefaultSudzService implements SudzService {

    private static final Logger log = Logger.getLogger(DefaultSudzService.class.getName());

    private final SudzDao sudzDao;

    /**
     * @param sudzDao DAO СУДЗ
     */
    public DefaultSudzService(SudzDao sudzDao) {
        this.sudzDao = Objects.requireNonNull(sudzDao, "sudzDao");
    }

    @Override
    public List<SudzYear> listYears() {
        return sudzDao.findYears();
    }

    @Override
    public SudzYearDetail getYearDetail(int yrKey) {
        return sudzDao.findYearDetail(yrKey)
                .orElseThrow(() -> new IllegalArgumentException("Год-вариант СУДЗ не найден: yr=" + yrKey));
    }

    @Override
    public List<SudzUplLookup> listUplLookups() {
        return sudzDao.findUplLookups();
    }

    @Override
    public List<SudzCmmGrLookup> listCmmGrLookups() {
        return sudzDao.findCmmGrLookups();
    }

    @Override
    public List<SudzYyyyLookup> listYyyyLookups() {
        return sudzDao.findYyyyLookups();
    }

    @Override
    public List<SudzPmUplLookup> listPmUplLookups() {
        return sudzDao.findPmUplLookups();
    }

    @Override
    public SudzYearDetail createYear(
            String variant,
            Integer baseUplKey,
            String inlineUplName,
            LocalDate inlineUplDate,
            LocalDate inlineUplStatusOnDate,
            int yKey,
            Integer cmmGrKey
    ) {
        String variantNorm = requireNonBlank(variant, "variant");
        if (yKey <= 0) {
            throw new IllegalArgumentException("yKey должен быть положительным: " + yKey);
        }
        boolean hasBase = baseUplKey != null && baseUplKey > 0;
        boolean hasInline = inlineUplName != null && !inlineUplName.isBlank();
        if (hasBase == hasInline) {
            throw new IllegalArgumentException(
                    "Нужно указать либо baseUplKey, либо поля новой выгрузки (newUpl*), но не оба и не ни одного");
        }
        if (hasInline) {
            if (inlineUplStatusOnDate == null) {
                throw new IllegalArgumentException("newUplStatusOnDate обязателен при создании выгрузки");
            }
        } else if (baseUplKey == null || baseUplKey <= 0) {
            throw new IllegalArgumentException("baseUplKey должен быть положительным");
        }
        if (cmmGrKey != null && cmmGrKey <= 0) {
            throw new IllegalArgumentException("cmmGrKey должен быть положительным или null: " + cmmGrKey);
        }

        log.log(Level.INFO, "createYear variant={0}, yKey={1}", new Object[]{variantNorm, yKey});
        int yrKey = sudzDao.createYear(
                variantNorm,
                hasBase ? baseUplKey : null,
                hasInline ? inlineUplName.trim() : null,
                inlineUplDate,
                inlineUplStatusOnDate,
                yKey,
                cmmGrKey
        );
        return getYearDetail(yrKey);
    }

    @Override
    public SudzYearDetail updateYear(
            int yrKey,
            String variant,
            int baseUplKey,
            int yKey,
            Integer cmmGrKey,
            Integer cmmGrNewKey
    ) {
        requireYear(yrKey);
        String variantNorm = requireNonBlank(variant, "variant");
        if (baseUplKey <= 0) {
            throw new IllegalArgumentException("baseUplKey должен быть положительным: " + baseUplKey);
        }
        if (yKey <= 0) {
            throw new IllegalArgumentException("yKey должен быть положительным: " + yKey);
        }
        if (cmmGrKey != null && cmmGrKey <= 0) {
            throw new IllegalArgumentException("cmmGrKey должен быть положительным или null: " + cmmGrKey);
        }
        if (cmmGrNewKey != null && cmmGrNewKey <= 0) {
            throw new IllegalArgumentException("cmmGrNewKey должен быть положительным или null: " + cmmGrNewKey);
        }
        log.log(Level.INFO, "updateYear yr={0}", yrKey);
        sudzDao.updateYear(yrKey, variantNorm, baseUplKey, yKey, cmmGrKey, cmmGrNewKey);
        return getYearDetail(yrKey);
    }

    @Override
    public SudzCmmGrLookup createCmmGr(String name, java.time.LocalDate date) {
        String nameNorm = requireNonBlank(name, "name");
        if (date == null) {
            throw new IllegalArgumentException("Дата группы комментариев обязательна");
        }
        int key = sudzDao.createCmmGr(nameNorm, date);
        return new SudzCmmGrLookup(key, nameNorm, date);
    }

    @Override
    public int importRsltReturn(int yrKey, java.util.List<SudzRsltReturnRow> rows) {
        requireYear(yrKey);
        if (rows == null || rows.isEmpty()) {
            throw new IllegalArgumentException("Нет строк для импорта возврата Rslt");
        }
        log.log(Level.INFO, "importRsltReturn yr={0}, rows={1}", new Object[]{yrKey, rows.size()});
        return sudzDao.importRsltReturn(yrKey, rows);
    }

    @Override
    public String appendYearProgress(int yrKey, String line) {
        requireYear(yrKey);
        String text = line == null ? "" : line.trim();
        if (text.isEmpty()) {
            throw new IllegalArgumentException("Строка лога progress не должна быть пустой");
        }
        log.log(Level.INFO, "appendYearProgress yr={0}", yrKey);
        return sudzDao.appendYearProgress(yrKey, text);
    }

    @Override
    public boolean deleteYear(int yrKey) {
        requireYear(yrKey);
        log.log(Level.INFO, "deleteYear yr={0}", yrKey);
        sudzDao.deleteYear(yrKey);
        return true;
    }

    @Override
    public SudzUplLookup createUpl(String name, LocalDate uplDate, LocalDate statusOnDate) {
        String nameNorm = requireNonBlank(name, "name");
        if (statusOnDate == null) {
            throw new IllegalArgumentException("statusOnDate обязателен");
        }
        int uplKey = sudzDao.createUpl(nameNorm, uplDate, statusOnDate);
        return sudzDao.findUplLookups().stream()
                .filter(u -> u.uplKey() == uplKey)
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("Созданная выгрузка не найдена: uplKey=" + uplKey));
    }

    @Override
    public SudzYearUpl addYearUpl(int yrKey, int uplKey) {
        requireYear(yrKey);
        if (uplKey <= 0) {
            throw new IllegalArgumentException("uplKey должен быть положительным: " + uplKey);
        }
        return sudzDao.addYearUpl(yrKey, uplKey);
    }

    @Override
    public boolean removeYearUpl(int yrUplPKey) {
        if (yrUplPKey <= 0) {
            throw new IllegalArgumentException("yrUplPKey должен быть положительным: " + yrUplPKey);
        }
        sudzDao.removeYearUpl(yrUplPKey);
        return true;
    }

    @Override
    public SudzPmUplLookup createPmUpl(String name, LocalDate date) {
        if (date == null) {
            throw new IllegalArgumentException("date обязателен");
        }
        String nameNorm = name == null ? null : name.trim();
        if (nameNorm != null && nameNorm.isEmpty()) {
            nameNorm = null;
        }
        int pmKey = sudzDao.createPmUpl(nameNorm, date);
        return sudzDao.findPmUplLookups().stream()
                .filter(p -> p.pmKey() == pmKey)
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("Созданная pm-выгрузка не найдена: pmKey=" + pmKey));
    }

    @Override
    public SudzPmLink addPmLink(int dbtUplKey, int pmKey) {
        if (dbtUplKey <= 0) {
            throw new IllegalArgumentException("dbtUplKey должен быть положительным: " + dbtUplKey);
        }
        if (pmKey <= 0) {
            throw new IllegalArgumentException("pmKey должен быть положительным: " + pmKey);
        }
        return sudzDao.addPmLink(dbtUplKey, pmKey);
    }

    @Override
    public boolean removePmLink(int gPKey) {
        if (gPKey <= 0) {
            throw new IllegalArgumentException("gPKey должен быть положительным: " + gPKey);
        }
        sudzDao.removePmLink(gPKey);
        return true;
    }

    @Override
    public List<SudzRsltDebt> getYrDbtChanges(int yrKey, Integer asOfUpl) {
        requireYear(yrKey);
        if (asOfUpl != null && asOfUpl <= 0) {
            throw new IllegalArgumentException("asOfUpl должен быть положительным: " + asOfUpl);
        }
        log.log(Level.FINE, "getYrDbtChanges yr={0}, asOfUpl={1}", new Object[]{yrKey, asOfUpl});
        return sudzDao.findYrDbtChanges(yrKey, asOfUpl);
    }

    @Override
    public List<SudzD644Row> getD644(int yrKey, int currUpl) {
        requireYear(yrKey);
        if (currUpl <= 0) {
            throw new IllegalArgumentException("currUpl должен быть положительным: " + currUpl);
        }
        log.log(Level.FINE, "getD644 yr={0}, currUpl={1}", new Object[]{yrKey, currUpl});
        return sudzDao.findD644(yrKey, currUpl);
    }

    @Override
    public SudzSvodResult getD644Svod(int yrKey, int currUpl) {
        requireYear(yrKey);
        if (currUpl <= 0) {
            throw new IllegalArgumentException("currUpl должен быть положительным: " + currUpl);
        }
        log.log(Level.FINE, "getD644Svod yr={0}, currUpl={1}", new Object[]{yrKey, currUpl});
        return sudzDao.findD644Svod(yrKey, currUpl);
    }

    @Override
    public SudzDebtCollection updateDebtCollection(
            int yrKey,
            int dbtKey,
            String curator,
            String mery,
            String cstCode
    ) {
        requireYear(yrKey);
        if (dbtKey <= 0) {
            throw new IllegalArgumentException("dbtKey должен быть положительным: " + dbtKey);
        }
        log.log(Level.INFO, "updateDebtCollection yr={0}, dbtKey={1}", new Object[]{yrKey, dbtKey});
        return sudzDao.saveDebtCollection(yrKey, dbtKey, curator, mery, cstCode);
    }

    @Override
    public SudzDbtUplLauncher getDbtUplLauncher(int uplKey) {
        if (uplKey <= 0) {
            throw new IllegalArgumentException("uplKey должен быть положительным: " + uplKey);
        }
        return sudzDao.findDbtUplLauncher(uplKey)
                .orElseThrow(() -> new IllegalArgumentException("Выгрузка ДЗ не найдена: uplKey=" + uplKey));
    }

    @Override
    public SudzDbtUplFile updateDbtUplFile(int uplKey, String path, Boolean flLoad, Boolean flTbl) {
        if (uplKey <= 0) {
            throw new IllegalArgumentException("uplKey должен быть положительным: " + uplKey);
        }
        log.log(Level.INFO, "updateDbtUplFile uplKey={0}", uplKey);
        return sudzDao.upsertDbtUplFile(uplKey, path, flLoad, flTbl);
    }

    @Override
    public SudzDbtUplFunnelResult runDbtUplFunnelStub(int uplKey, List<String> steps, boolean flLoad) {
        if (uplKey <= 0) {
            throw new IllegalArgumentException("uplKey должен быть положительным: " + uplKey);
        }
        List<String> ordered = new ArrayList<>();
        for (String stepId : steps) {
            if (stepId != null && !SudzDbtUplFunnelSteps.EXCEL_TO_TBL.equals(stepId)) {
                ordered.add(stepId);
            }
        }
        ordered = List.copyOf(ordered);
        SudzDbtUplFunnelSteps.requirePrefixOfEnabled(ordered);
        log.log(Level.INFO, "runDbtUplFunnelStub uplKey={0}, steps={1}, flLoad={2}",
                new Object[]{uplKey, ordered, flLoad});

        StringBuilder stub = new StringBuilder();
        stub.append("<p><b><font color=\"DarkGoldenrod\">STUB</font></b> воронка upl_key=")
                .append(uplKey)
                .append(", flLoad=")
                .append(flLoad ? "true" : "false")
                .append(", шагов=")
                .append(ordered.size())
                .append(". Доменные таблицы не изменялись.</p>");
        for (String stepId : ordered) {
            String title = SudzDbtUplFunnelSteps.ALL.stream()
                    .filter(s -> s.id().equals(stepId))
                    .map(SudzDbtUplFunnelSteps.StepDef::titleRu)
                    .findFirst()
                    .orElse(stepId);
            stub.append("<p><font color=\"CadetBlue\">STUB</font> <b>")
                    .append(escapeHtml(stepId))
                    .append("</b> — ")
                    .append(escapeHtml(title))
                    .append(": шаг принят оркестратором, реализация позже.</p>");
        }
        stub.append("<p><font color=\"blue\">STUB завершён</font></p>");

        sudzDao.setDbtUplFileProgress(uplKey, stub.toString());
        SudzDbtUplLauncher after = getDbtUplLauncher(uplKey);
        return new SudzDbtUplFunnelResult(after, ordered, true);
    }

    @Override
    public SudzDbtUplFile setDbtUplFileProgress(int uplKey, String progressHtml) {
        if (uplKey <= 0) {
            throw new IllegalArgumentException("uplKey должен быть положительным: " + uplKey);
        }
        return sudzDao.setDbtUplFileProgress(uplKey, progressHtml);
    }

    @Override
    public int replaceDbtUplTbl(int unloadKey, List<SudzDbtUplTblRow> rows) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        Objects.requireNonNull(rows, "rows");
        log.log(Level.INFO, "replaceDbtUplTbl unloadKey={0}, rows={1}",
                new Object[]{unloadKey, rows.size()});
        return sudzDao.replaceDbtUplTbl(unloadKey, rows);
    }

    @Override
    public int countDbtUplTbl(int unloadKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        return sudzDao.countDbtUplTbl(unloadKey);
    }

    @Override
    public List<SudzDbtUplOrgNotInBuirg> listDbtUplOrgNotInBuirg(int unloadKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        return sudzDao.findDbtUplOrgNotInBuirg(unloadKey);
    }

    @Override
    public List<SudzDbtUplCnNotLoad> listDbtUplCnNotLoad(int unloadKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        return sudzDao.findDbtUplCnNotLoad(unloadKey);
    }

    @Override
    public List<SudzDbtUplCnExistCtptNotLoad> listDbtUplCnExistCtptNotLoad(int unloadKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        return sudzDao.findDbtUplCnExistCtptNotLoad(unloadKey);
    }

    @Override
    public SudzDbtUplCnNotLoadApplyResult applyDbtUplCnNotLoad(List<SudzDbtUplCnNotLoad> rows) {
        Objects.requireNonNull(rows, "rows");
        int cnMark = SudzAccessStrMark.now();
        String note = "Добавлено " + LocalDateTime.now();
        return sudzDao.applyDbtUplCnNotLoad(rows, cnMark, note);
    }

    @Override
    public int rollbackCnNotLoadByMark(int cnMark) {
        if (cnMark <= 0) {
            throw new IllegalArgumentException("cnMark должен быть положительным: " + cnMark);
        }
        return sudzDao.rollbackCnNotLoadByMark(cnMark);
    }

    @Override
    public int clearDbtUplInvDouble() {
        return sudzDao.clearDbtUplInvDouble();
    }

    @Override
    public SudzDbtUplCnCtptExistInvResult rebuildDbtUplCnCtptExistInvNot(int unloadKey, Integer fileKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        return sudzDao.rebuildDbtUplCnCtptExistInvNot(unloadKey, fileKey);
    }

    @Override
    public SudzDbtUplCnCtptExistInvApplyResult applyDbtUplCnCtptExistInvNotLoad(int unloadKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        return sudzDao.applyDbtUplCnCtptExistInvNotLoad(unloadKey);
    }

    @Override
    public List<SudzCnInvUplSfDouble> findSfDoublesByUnload(int unloadKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        return sudzDao.findSfDoublesByUnload(unloadKey);
    }

    @Override
    public Optional<SudzSfDoubleExcelCandidate> findSfDoubleExcelCandidate(int ciusKey) {
        if (ciusKey <= 0) {
            throw new IllegalArgumentException("ciusKey должен быть положительным: " + ciusKey);
        }
        return sudzDao.findSfDoubleExcelCandidate(ciusKey);
    }

    @Override
    public List<SudzSfDoubleDomainMatch> findSfDoubleDomainMatches(String invNum) {
        return sudzDao.findSfDoubleDomainMatches(invNum);
    }

    @Override
    public SudzCnInvUplSfDouble createSfFromDouble(int ciusKey) {
        if (ciusKey <= 0) {
            throw new IllegalArgumentException("ciusKey должен быть положительным: " + ciusKey);
        }
        return sudzDao.createSfFromDouble(ciusKey);
    }

    @Override
    public SudzCnInvUplSfDouble linkSfDoubleToCn(int ciusKey, int invKey, int cnKey) {
        if (ciusKey <= 0) {
            throw new IllegalArgumentException("ciusKey должен быть положительным: " + ciusKey);
        }
        if (invKey <= 0) {
            throw new IllegalArgumentException("invKey должен быть положительным: " + invKey);
        }
        if (cnKey <= 0) {
            throw new IllegalArgumentException("cnKey должен быть положительным: " + cnKey);
        }
        return sudzDao.linkSfDoubleToCn(ciusKey, invKey, cnKey);
    }

    private static String escapeHtml(String value) {
        if (value == null) {
            return "";
        }
        return value
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }

    private void requireYear(int yrKey) {
        if (sudzDao.findYear(yrKey).isEmpty()) {
            throw new IllegalArgumentException("Год-вариант СУДЗ не найден: yr=" + yrKey);
        }
    }

    private static String requireNonBlank(String value, String field) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(field + " обязателен");
        }
        return value.trim();
    }
}
