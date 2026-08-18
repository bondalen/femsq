package com.femsq.database.service;

import com.femsq.database.model.sudz.SudzCmmGrLookup;
import com.femsq.database.model.sudz.SudzCnInvUplSfDouble;
import com.femsq.database.model.sudz.SudzD644Row;
import com.femsq.database.model.sudz.SudzDbtUplCnCtptExistInvApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplCnCtptExistInvResult;
import com.femsq.database.model.sudz.SudzDbtUplCnExistCtptNotLoad;
import com.femsq.database.model.sudz.SudzDbtUplCnNotLoad;
import com.femsq.database.model.sudz.SudzDbtUplCnNotLoadApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplFile;
import com.femsq.database.model.sudz.SudzDbtUplFunnelResult;
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
import com.femsq.database.model.sudz.SudzSfDoubleTreeDebt;
import com.femsq.database.model.sudz.SudzSvodResult;
import com.femsq.database.model.sudz.SudzUplLookup;
import com.femsq.database.model.sudz.SudzYear;
import com.femsq.database.model.sudz.SudzYearDetail;
import com.femsq.database.model.sudz.SudzYearUpl;
import com.femsq.database.model.sudz.SudzYyyyLookup;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * Сервис чтения/записи витрин СУДЗ и CRUD портфеля года.
 */
public interface SudzService {

    /**
     * Список год-вариантов с lookup.
     *
     * @return годы
     */
    List<SudzYear> listYears();

    /**
     * Карточка года с выгрузками.
     *
     * @param yrKey ключ года
     * @return деталь
     * @throws IllegalArgumentException если год не найден
     */
    SudzYearDetail getYearDetail(int yrKey);

    /**
     * Lookup выгрузок ДЗ.
     *
     * @return список
     */
    List<SudzUplLookup> listUplLookups();

    /**
     * Lookup групп комментариев.
     *
     * @return список
     */
    List<SudzCmmGrLookup> listCmmGrLookups();

    /**
     * Lookup календарных лет.
     *
     * @return список
     */
    List<SudzYyyyLookup> listYyyyLookups();

    /**
     * Lookup выгрузок платежей.
     *
     * @return список
     */
    List<SudzPmUplLookup> listPmUplLookups();

    /**
     * Создаёт год-вариант.
     *
     * @param variant описание
     * @param baseUplKey существующая база (или null)
     * @param inlineUplName имя новой выгрузки (или null)
     * @param inlineUplDate дата новой выгрузки
     * @param inlineUplStatusOnDate дата состояния
     * @param yKey ключ ags.yyyy
     * @param cmmGrKey группа (nullable)
     * @return карточка созданного года
     */
    SudzYearDetail createYear(
            String variant,
            Integer baseUplKey,
            String inlineUplName,
            LocalDate inlineUplDate,
            LocalDate inlineUplStatusOnDate,
            int yKey,
            Integer cmmGrKey
    );

    /**
     * Обновляет год без изменения progress.
     *
     * @param yrKey ключ
     * @param variant описание
     * @param baseUplKey база
     * @param yKey ключ года
     * @param cmmGrKey группа (nullable)
     * @return актуальная карточка
     */
    SudzYearDetail updateYear(
            int yrKey,
            String variant,
            int baseUplKey,
            int yKey,
            Integer cmmGrKey,
            Integer cmmGrNewKey
    );

    /**
     * Создаёт группу комментариев.
     *
     * @param name имя
     * @param date дата
     * @return lookup новой группы
     */
    SudzCmmGrLookup createCmmGr(String name, java.time.LocalDate date);

    /**
     * Импорт возврата Rslt в {@code yr_CmmGr_New}.
     *
     * @param yrKey год
     * @param rows строки *_new
     * @return число долгов
     */
    int importRsltReturn(int yrKey, java.util.List<SudzRsltReturnRow> rows);

    /**
     * Дописывает строку в лог {@code yr_Progress}.
     *
     * @param yrKey ключ года
     * @param line текст события
     * @return полный текст лога после записи
     */
    String appendYearProgress(int yrKey, String line);

    /**
     * Удаляет год.
     *
     * @param yrKey ключ
     * @return true при успехе
     */
    boolean deleteYear(int yrKey);

    /**
     * Создаёт выгрузку ДЗ.
     *
     * @param name имя
     * @param uplDate дата
     * @param statusOnDate дата состояния
     * @return созданная выгрузка
     */
    SudzUplLookup createUpl(String name, LocalDate uplDate, LocalDate statusOnDate);

    /**
     * Добавляет выгрузку в год.
     *
     * @param yrKey ключ года
     * @param uplKey ключ выгрузки
     * @return строка yr_upl_p
     */
    SudzYearUpl addYearUpl(int yrKey, int uplKey);

    /**
     * Удаляет выгрузку из года.
     *
     * @param yrUplPKey ключ yr_upl_p
     * @return true
     */
    boolean removeYearUpl(int yrUplPKey);

    /**
     * Создаёт выгрузку платежей.
     *
     * @param name имя
     * @param date дата
     * @return созданная выгрузка
     */
    SudzPmUplLookup createPmUpl(String name, LocalDate date);

    /**
     * Связывает выгрузку ДЗ с платежами.
     *
     * @param dbtUplKey ключ ДЗ
     * @param pmKey ключ платежей
     * @return связь
     */
    SudzPmLink addPmLink(int dbtUplKey, int pmKey);

    /**
     * Удаляет связь платежей.
     *
     * @param gPKey ключ g_p
     * @return true
     */
    boolean removePmLink(int gPKey);

    /**
     * Портфель года (структура Rslt).
     *
     * @param yrKey ключ года
     * @param asOfUpl опционально: срезы до выбранной выгрузки включительно
     * @return долги со срезами
     * @throws IllegalArgumentException если год не найден
     */
    List<SudzRsltDebt> getYrDbtChanges(int yrKey, Integer asOfUpl);

    /**
     * Итоговый документ D644.
     *
     * @param yrKey ключ года
     * @param currUpl текущая выгрузка
     * @return строки D644
     * @throws IllegalArgumentException если год не найден
     */
    List<SudzD644Row> getD644(int yrKey, int currUpl);

    /**
     * Годовой свод по счетам ГК.
     *
     * @param yrKey ключ года
     * @param currUpl текущая выгрузка
     * @return свод
     * @throws IllegalArgumentException если год не найден
     */
    SudzSvodResult getD644Svod(int yrKey, int currUpl);

    /**
     * Сохраняет сбор по долгу в {@code yr_CmmGr}.
     *
     * @param yrKey ключ года
     * @param dbtKey ключ долга
     * @param curator куратор
     * @param mery мероприятия
     * @param cstCode код стройки
     * @return актуальные значения
     * @throws IllegalArgumentException при неверных аргументах / неизвестном коде стройки
     */
    SudzDebtCollection updateDebtCollection(
            int yrKey,
            int dbtKey,
            String curator,
            String mery,
            String cstCode
    );

    /**
     * Лаунчер загрузки свода (File / FileSh / InvDouble) для выгрузки.
     *
     * @param uplKey ключ выгрузки
     * @return карточка
     * @throws IllegalArgumentException если выгрузка не найдена
     */
    SudzDbtUplLauncher getDbtUplLauncher(int uplKey);

    /**
     * Upsert шапки лаунчера по выгрузке.
     *
     * @param uplKey ключ выгрузки
     * @param path путь/имя (nullable)
     * @param flLoad флаг (nullable)
     * @param flTbl флаг (nullable)
     * @return актуальная шапка
     */
    SudzDbtUplFile updateDbtUplFile(int uplKey, String path, Boolean flLoad, Boolean flTbl);

    /**
     * Stub-прогон воронки (S61f): пишет лог по отмеченным шагам, домен не меняет.
     *
     * @param uplKey ключ выгрузки
     * @param steps префикс цепочки stepId
     * @param flLoad флаг записи (только отражается в логе stub)
     * @return результат с launcher
     */
    SudzDbtUplFunnelResult runDbtUplFunnelStub(int uplKey, List<String> steps, boolean flLoad);

    /**
     * Записывает HTML-лог хода в File.
     *
     * @param uplKey ключ выгрузки
     * @param progressHtml полный HTML
     * @return шапка File
     */
    SudzDbtUplFile setDbtUplFileProgress(int uplKey, String progressHtml);

    /**
     * Заменяет буфер {@code CnInvDbtUplTbl} для выгрузки.
     *
     * @param unloadKey upl_key
     * @param rows строки
     * @return число вставленных
     */
    int replaceDbtUplTbl(int unloadKey, List<SudzDbtUplTblRow> rows);

    /**
     * Число строк буфера {@code CnInvDbtUplTbl}.
     *
     * @param unloadKey {@code upl_key}
     * @return COUNT(*)
     */
    int countDbtUplTbl(int unloadKey);

    /**
     * Организации свода без кода БУиРГ ({@code ags.org_id} type=1).
     * Не пишет в домен; {@code cidufFlLoad} не влияет.
     *
     * @param unloadKey {@code upl_key}
     * @return строки лога (несколько type=2 на один ИНН — несколько строк, как Access)
     */
    List<SudzDbtUplOrgNotInBuirg> listDbtUplOrgNotInBuirg(int unloadKey);

    /**
     * Договоры свода без пары в БД ({@code CnNotLoad} / {@code ciduCnNotLoad}).
     *
     * @param unloadKey {@code upl_key}
     * @return строки для лога
     */
    List<SudzDbtUplCnNotLoad> listDbtUplCnNotLoad(int unloadKey);

    /**
     * Договоры свода с существующим номером, но без пары исполнителя
     * ({@code CnExistCtptNotLoad} / {@code ciduCnExistCtptNot}). Только лог.
     *
     * @param unloadKey {@code upl_key}
     * @return строки для лога
     */
    List<SudzDbtUplCnExistCtptNotLoad> listDbtUplCnExistCtptNotLoad(int unloadKey);

    /**
     * Apply {@code CnNotLoad}: INSERT при {@code countCnName = 1}, общий {@code cnMark}.
     *
     * @param rows строки лога
     * @return итог (метка для отката)
     */
    SudzDbtUplCnNotLoadApplyResult applyDbtUplCnNotLoad(List<SudzDbtUplCnNotLoad> rows);

    /**
     * Откат apply {@code CnNotLoad} по {@code cnMark}.
     *
     * @param cnMark метка
     * @return число удалённых {@code ags.cn}
     */
    int rollbackCnNotLoadByMark(int cnMark);

    /**
     * Prelude: очистка {@code CnInvDbtUplFileInvDouble}.
     *
     * @return число удалённых строк
     */
    int clearDbtUplInvDouble();

    /**
     * Пересборка буфера новых СФ + данные лога (+ InvDouble при fileKey).
     *
     * @param unloadKey {@code upl_key}
     * @param fileKey ключ File или null
     * @return буфер и договоры
     */
    SudzDbtUplCnCtptExistInvResult rebuildDbtUplCnCtptExistInvNot(int unloadKey, Integer fileKey);

    /**
     * Apply: INSERT inv / invNum / cnInv по буферу (без строк очереди SfDouble).
     *
     * @param unloadKey {@code upl_key}
     * @return итог
     */
    SudzDbtUplCnCtptExistInvApplyResult applyDbtUplCnCtptExistInvNotLoad(int unloadKey);

    /**
     * Очередь КСДСФ по выгрузке долгов.
     *
     * @param unloadKey {@code upl_key}
     * @return строки
     */
    List<SudzCnInvUplSfDouble> findSfDoublesByUnload(int unloadKey);

    /**
     * Excel-кандидат для строки очереди.
     *
     * @param ciusKey ключ
     * @return карточка
     */
    Optional<SudzSfDoubleExcelCandidate> findSfDoubleExcelCandidate(int ciusKey);

    /**
     * Доменные СФ с совпадающим номером.
     *
     * @param invNum номер
     * @return совпадения
     */
    List<SudzSfDoubleDomainMatch> findSfDoubleDomainMatches(String invNum);

    /**
     * СГК простой и новая ДЗ для дерева КСДСФ.
     *
     * @param invKey {@code inv.iKey}
     * @return вложенные карточки
     */
    SudzSfDoubleTreeDebt findSfDoubleTreeDebt(int invKey);

    /**
     * Создать новый СФ из строки очереди КСДСФ.
     *
     * @param ciusKey ключ open
     * @return обновлённая строка
     */
    SudzCnInvUplSfDouble createSfFromDouble(int ciusKey);
}
