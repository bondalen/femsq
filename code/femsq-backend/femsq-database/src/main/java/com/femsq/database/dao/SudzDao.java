package com.femsq.database.dao;

import com.femsq.database.model.sudz.SudzCmmGrLookup;
import com.femsq.database.model.sudz.SudzCnInvUplDbtP1;
import com.femsq.database.model.sudz.SudzCnInvUplInvDbtDouble;
import com.femsq.database.model.sudz.SudzInvDbtDoubleAdvice;
import com.femsq.database.model.sudz.SudzInvDbtSlot;
import com.femsq.database.model.sudz.SudzInvDbtSlotTimeline;
import com.femsq.database.model.sudz.SudzInvDbtVarCandidates;
import com.femsq.database.model.sudz.SudzCnInvUplSfDouble;
import com.femsq.database.model.sudz.SudzD644Row;
import com.femsq.database.model.sudz.SudzDbtUplAccSmplNotApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplAccSmplNotLoadResult;
import com.femsq.database.model.sudz.SudzDbtUplAccSmplNotRow;
import com.femsq.database.model.sudz.SudzDbtUplAccSmplVarInvPhaseResult;
import com.femsq.database.model.sudz.SudzDbtUplDbtValueLoadApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplDbtValueLoadPhaseResult;
import com.femsq.database.model.sudz.SudzDbtUplDbtValueLoadSnapshot;
import com.femsq.database.model.sudz.SudzDbtUplInvDbtDbtEnsureApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplInvDbtDbtEnsureSnapshot;
import com.femsq.database.model.sudz.SudzDbtUplInvDbtLoadApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplInvDbtVarAmbiguousRow;
import com.femsq.database.model.sudz.SudzDbtUplInvDbtVarEnsureApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplInvDbtVarEnsureRow;
import com.femsq.database.model.sudz.SudzDbtUplInvDbtVarEnsureSnapshot;
import com.femsq.database.model.sudz.SudzDbtUplCnCtptExistInvApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplCnCtptExistInvResult;
import com.femsq.database.model.sudz.SudzDbtUplCnExistCtptNotLoad;
import com.femsq.database.model.sudz.SudzDbtUplCnNotLoad;
import com.femsq.database.model.sudz.SudzDbtUplCnNotLoadApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplFile;
import com.femsq.database.model.sudz.SudzDbtUplFileSh;
import com.femsq.database.model.sudz.SudzDbtUplFunnelQueueClearResult;
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
import com.femsq.database.model.sudz.SudzSfDoubleAdvice;
import com.femsq.database.model.sudz.SudzSfDoubleHints;
import com.femsq.database.model.sudz.SudzSfDoubleSumMatches;
import com.femsq.database.model.sudz.SudzSvodResult;
import com.femsq.database.model.sudz.SudzUplLookup;
import com.femsq.database.model.sudz.SudzYear;
import com.femsq.database.model.sudz.SudzYearDetail;
import com.femsq.database.model.sudz.SudzYearUpl;
import com.femsq.database.model.sudz.SudzYyyyLookup;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * Доступ к витринам и CRUD портфеля года СУДЗ.
 * Схема на DEV — {@code sudz}, на prod — {@code ags}; не из {@code database.properties#schema}.
 */
public interface SudzDao {

    /**
     * Список год-вариантов с lookup-подписями.
     *
     * @return годы по возрастанию {@code yr_key}
     */
    List<SudzYear> findYears();

    /**
     * Год-вариант по ключу (с lookup).
     *
     * @param yrKey ключ {@code yr}
     * @return год или empty
     */
    Optional<SudzYear> findYear(int yrKey);

    /**
     * Карточка года: шапка + выгрузки + pm-связи.
     *
     * @param yrKey ключ года
     * @return деталь или empty
     */
    Optional<SudzYearDetail> findYearDetail(int yrKey);

    /**
     * Lookup выгрузок ДЗ.
     *
     * @return список по {@code upl_key}
     */
    List<SudzUplLookup> findUplLookups();

    /**
     * Lookup групп комментариев.
     *
     * @return список по {@code cnicgKey}
     */
    List<SudzCmmGrLookup> findCmmGrLookups();

    /**
     * Lookup календарных лет из {@code ags.yyyy}.
     *
     * @return список по {@code yKey}
     */
    List<SudzYyyyLookup> findYyyyLookups();

    /**
     * Lookup выгрузок платежей.
     *
     * @return список по {@code cn_inv_pm_key}
     */
    List<SudzPmUplLookup> findPmUplLookups();

    /**
     * Создаёт год-вариант. Либо {@code baseUplKey}, либо inline-поля новой выгрузки.
     * При создании всегда добавляет базовую выгрузку в {@code yr_upl_p}.
     * Колонку {@code yr_Progress} не заполняет.
     *
     * @param variant описание варианта
     * @param baseUplKey существующая базовая выгрузка (или null при inline)
     * @param inlineUplName имя новой выгрузки (или null)
     * @param inlineUplDate дата новой выгрузки
     * @param inlineUplStatusOnDate дата состояния новой выгрузки
     * @param yKey ключ {@code ags.yyyy}
     * @param cmmGrKey группа комментариев (nullable)
     * @return ключ созданного года
     */
    int createYear(
            String variant,
            Integer baseUplKey,
            String inlineUplName,
            LocalDate inlineUplDate,
            LocalDate inlineUplStatusOnDate,
            int yKey,
            Integer cmmGrKey
    );

    /**
     * Обновляет поля года без изменения {@code yr_Progress}.
     *
     * @param yrKey ключ года
     * @param variant описание
     * @param baseUplKey базовая выгрузка
     * @param yKey ключ {@code ags.yyyy}
     * @param cmmGrKey группа комментариев (nullable)
     * @param cmmGrNewKey группа новых (nullable)
     */
    void updateYear(
            int yrKey,
            String variant,
            int baseUplKey,
            int yKey,
            Integer cmmGrKey,
            Integer cmmGrNewKey
    );

    /**
     * Создаёт группу комментариев {@code cnInvCmmGr}.
     *
     * @param name имя группы
     * @param date дата группы
     * @return новый {@code cnicgKey}
     */
    int createCmmGr(String name, LocalDate date);

    /**
     * Импортирует строки возврата Rslt ({@code *_new}) в {@code yr_CmmGr_New}.
     *
     * @param yrKey год
     * @param rows строки с dbtKey и новыми полями
     * @return число обработанных долгов
     */
    int importRsltReturn(int yrKey, List<SudzRsltReturnRow> rows);

    /**
     * Дописывает строку в начало {@code yr_Progress} (лог формирования документов).
     * Хранит не более ~100 строк; более старые отбрасываются.
     *
     * @param yrKey ключ года
     * @param line одна строка лога (без обязательного перевода строки в конце)
     * @return полный текст {@code yr_Progress} после записи
     */
    String appendYearProgress(int yrKey, String line);

    /**
     * Удаляет год: сначала {@code yr_upl_p}, затем {@code yr}.
     *
     * @param yrKey ключ года
     */
    void deleteYear(int yrKey);

    /**
     * Создаёт выгрузку ДЗ (PK — {@code MAX(upl_key)+1}, не IDENTITY).
     *
     * @param name имя
     * @param uplDate дата выгрузки
     * @param statusOnDate дата состояния
     * @return ключ выгрузки
     */
    int createUpl(String name, LocalDate uplDate, LocalDate statusOnDate);

    /**
     * Добавляет выгрузку в год ({@code yr_upl_p}).
     *
     * @param yrKey ключ года
     * @param uplKey ключ выгрузки
     * @return созданная строка с lookup
     */
    SudzYearUpl addYearUpl(int yrKey, int uplKey);

    /**
     * Удаляет строку {@code yr_upl_p}.
     *
     * @param yrUplPKey ключ строки
     */
    void removeYearUpl(int yrUplPKey);

    /**
     * Создаёт выгрузку платежей.
     *
     * @param name имя
     * @param date дата
     * @return ключ
     */
    int createPmUpl(String name, LocalDate date);

    /**
     * Связывает выгрузку ДЗ с выгрузкой платежей ({@code cn_inv_dbt_upl_g_p}).
     *
     * @param dbtUplKey ключ выгрузки ДЗ
     * @param pmKey ключ выгрузки платежей
     * @return созданная связь
     */
    SudzPmLink addPmLink(int dbtUplKey, int pmKey);

    /**
     * Удаляет связь {@code cn_inv_dbt_upl_g_p}.
     *
     * @param gPKey ключ связи ({@code [key]})
     */
    void removePmLink(int gPKey);

    /**
     * Портфель года в структуре Rslt (зерно {@code dbtKey}, срезы по дате выгрузки).
     *
     * @param yrKey ключ года
     * @param asOfUpl опционально: только срезы с {@code upl_date} ≤ даты этой выгрузки (Rslt сбор)
     * @return долги с периодами
     */
    List<SudzRsltDebt> findYrDbtChanges(int yrKey, Integer asOfUpl);

    /**
     * Итоговый документ D644.
     *
     * @param yrKey ключ года
     * @param currUpl текущая выгрузка
     * @return строки D644
     */
    List<SudzD644Row> findD644(int yrKey, int currUpl);

    /**
     * Годовой свод по счетам ГК.
     *
     * @param yrKey ключ года
     * @param currUpl текущая выгрузка
     * @return счета и итог
     */
    SudzSvodResult findD644Svod(int yrKey, int currUpl);

    /**
     * Сохраняет куратора, мероприятия и код стройки в группу {@code yr.yr_CmmGr}.
     *
     * @param yrKey ключ года
     * @param dbtKey ключ долга
     * @param curator куратор (type=8); blank → удалить
     * @param mery мероприятия (type=1); blank → удалить
     * @param cstCode код {@code cstAgPn.cstapIpgPnN}; blank → удалить привязку type=2
     * @return актуальные значения после записи
     */
    SudzDebtCollection saveDebtCollection(
            int yrKey,
            int dbtKey,
            String curator,
            String mery,
            String cstCode
    );

    /**
     * Лаунчер загрузки свода для выгрузки: File + FileSh + InvDouble.
     *
     * @param uplKey ключ {@code cn_inv_dbt_upl}
     * @return карточка или empty, если upl не найден
     */
    Optional<SudzDbtUplLauncher> findDbtUplLauncher(int uplKey);

    /**
     * Upsert шапки {@code CnInvDbtUplFile} по {@code cidufUpload}.
     *
     * @param uplKey ключ выгрузки
     * @param path путь/имя; null — оставить / при insert пустая строка
     * @param flLoad флаг; null — оставить / при insert false
     * @param flTbl флаг; null — оставить / при insert false
     * @return актуальная шапка
     */
    SudzDbtUplFile upsertDbtUplFile(int uplKey, String path, Boolean flLoad, Boolean flTbl);

    /**
     * Создаёт лист {@code CnInvDbtUplFileSh} (File создаётся при отсутствии).
     *
     * @param uplKey ключ выгрузки
     * @param sheet имя листа Excel
     * @param accountNum номер счёта ГК ({@code ags.accnt.account_num})
     * @param test флаг «проверять?»
     * @return созданный лист
     */
    SudzDbtUplFileSh createDbtUplFileSh(int uplKey, String sheet, int accountNum, boolean test);

    /**
     * Обновляет лист {@code CnInvDbtUplFileSh}.
     *
     * @param cidufsKey ключ листа
     * @param sheet имя; null — не менять
     * @param accountNum номер счёта; null — не менять
     * @param test флаг; null — не менять
     * @return обновлённый лист
     */
    SudzDbtUplFileSh updateDbtUplFileSh(int cidufsKey, String sheet, Integer accountNum, Boolean test);

    /**
     * Удаляет лист {@code CnInvDbtUplFileSh}.
     *
     * @param cidufsKey ключ листа
     * @return true, если строка удалена
     */
    boolean deleteDbtUplFileSh(int cidufsKey);

    /**
     * Добавляет 6 стандартных листов общего свода (если ещё нет ни одного).
     *
     * @param uplKey ключ выгрузки
     * @return актуальный список листов File
     */
    List<SudzDbtUplFileSh> seedDbtUplStandardSheets(int uplKey);

    /**
     * Записывает HTML-лог хода в шапку File (создаёт File при отсутствии).
     *
     * @param uplKey ключ выгрузки
     * @param progressHtml полный HTML лога
     * @return актуальная шапка
     */
    SudzDbtUplFile setDbtUplFileProgress(int uplKey, String progressHtml);

    /**
     * Заменяет буфер {@code CnInvDbtUplTbl} для выгрузки (DELETE по unload + INSERT).
     *
     * @param unloadKey {@code upl_key} / {@code cidutUnloadKey}
     * @param rows строки из Excel
     * @return число вставленных строк
     */
    int replaceDbtUplTbl(int unloadKey, List<SudzDbtUplTblRow> rows);

    /**
     * Число строк буфера Tbl для выгрузки.
     *
     * @param unloadKey {@code upl_key}
     * @return COUNT(*)
     */
    int countDbtUplTbl(int unloadKey);

    /**
     * Организации свода без кода БУиРГ в {@code ags.org_id} (type=1).
     * Совпадение ИНН (type=2) даёт {@code existingOgNm}; несколько type=2 — несколько строк (как Access).
     *
     * @param unloadKey {@code upl_key} / {@code cidutUnloadKey}
     * @return строки для лога {@code orgNotInBuirg}
     */
    List<SudzDbtUplOrgNotInBuirg> findDbtUplOrgNotInBuirg(int unloadKey);

    /**
     * Договоры свода без пары в БД (цепочка Access {@code ciduCnNotLoad}).
     * Нормализация {@code *Null} — как вычисляемые поля Access (не столбцы Tbl).
     *
     * @param unloadKey {@code upl_key} / {@code cidutUnloadKey}
     * @return строки для лога {@code CnNotLoad}
     */
    List<SudzDbtUplCnNotLoad> findDbtUplCnNotLoad(int unloadKey);

    /**
     * Договоры свода: номер есть в БД, но нет пары номер+дата+исполнитель
     * ({@code ciduCnExistCtptNot} / {@code HAVING Count &gt; 0}).
     *
     * @param unloadKey {@code upl_key} / {@code cidutUnloadKey}
     * @return строки для лога {@code CnExistCtptNotLoad}
     */
    List<SudzDbtUplCnExistCtptNotLoad> findDbtUplCnExistCtptNotLoad(int unloadKey);

    /**
     * INSERT договоров шага {@code CnNotLoad} (только строки с {@code countCnName = 1}).
     * Одна транзакция; все новые {@code cn} получают один {@code cnMark}.
     *
     * @param rows строки лога (порядок = индекс 1..n)
     * @param cnMark метка отката
     * @param note текст примечания
     * @return итог apply
     */
    SudzDbtUplCnNotLoadApplyResult applyDbtUplCnNotLoad(
            List<SudzDbtUplCnNotLoad> rows,
            int cnMark,
            String note
    );

    /**
     * Откат apply {@code CnNotLoad} по {@code ags.cn.cnMark}.
     * Порядок: {@code cn_s_org} → {@code cn_s_org_smpl} → {@code cn_s} → {@code cnNum} → {@code cn}.
     *
     * @param cnMark метка
     * @return число удалённых строк {@code ags.cn}
     */
    int rollbackCnNotLoadByMark(int cnMark);

    /**
     * Очистка очереди двоящих СФ ({@code CnInvDbtUplFileInvDouble}) — prelude Access
     * перед {@code CnCtptExistInvNotLoad}.
     *
     * @return число удалённых строк
     */
    int clearDbtUplInvDouble();

    /**
     * Сброс очередей воронки (КСДСФ, КСДД, P1, FileInvDouble, TblCnInv) для выгрузки.
     *
     * @param unloadKey {@code upl_key}
     * @param fileKey ключ File или null
     * @return счётчики DELETE
     */
    SudzDbtUplFunnelQueueClearResult clearDbtUplFunnelQueues(int unloadKey, Integer fileKey);

    /**
     * Пересобирает буфер {@code CnInvDbtUplTblCnInv} (новые СФ для существующих договоров)
     * и возвращает данные для лога. При {@code fileKey != null} наполняет InvDouble
     * для СФ с ненулевым {@code inNumCount} (как {@code CnInvConcat}).
     *
     * @param unloadKey {@code upl_key}
     * @param fileKey ключ File для InvDouble; null — не писать очередь
     * @return буфер + договоры
     */
    SudzDbtUplCnCtptExistInvResult rebuildDbtUplCnCtptExistInvNot(int unloadKey, Integer fileKey);

    /**
     * INSERT {@code inv} → {@code invNum} → {@code cnInv} по буферу TblCnInv
     * только для строк без {@code inNumCount} (очередь SfDouble — вручную, S68).
     *
     * @param unloadKey ключ (для лога; буфер уже собран)
     * @return число внесённых СФ
     */
    SudzDbtUplCnCtptExistInvApplyResult applyDbtUplCnCtptExistInvNotLoad(int unloadKey);

    /**
     * Diff шага {@code CnCtptInvExistAccSmplNotLoad}: СФ есть, нет
     * {@code ags.cnInvAccntSmpl} на ({@code ciKey}, {@code account_key}, БУиРГ).
     * Эталон: {@code ciduCnCtptInvAccSmplNot} ← All ← ExistInvAll.
     *
     * @param unloadKey {@code cidutUnloadKey}
     * @return строки для лога
     */
    List<SudzDbtUplAccSmplNotRow> findDbtUplCnCtptInvExistAccSmplNot(int unloadKey);

    /**
     * INSERT в {@code ags.cnInvAccntSmpl} по diff AccSmpl
     * ({@code ciduCnCtptInvAccSmplNotIns}).
     *
     * @param unloadKey {@code cidutUnloadKey}
     * @return число внесённых пар СФ+СГК
     */
    SudzDbtUplAccSmplNotApplyResult applyDbtUplCnCtptInvExistAccSmplNotLoad(int unloadKey);

    /**
     * Diff + apply AccSmpl за одно JDBC-соединение (один {@code fillSudzEiaTemp}).
     * Предпочтительно при {@code flLoad=true}, чтобы не строить {@code #sudzEia} дважды.
     *
     * @param unloadKey {@code cidutUnloadKey}
     * @return строки лога и итог INSERT
     */
    SudzDbtUplAccSmplNotLoadResult findAndApplyDbtUplCnCtptInvExistAccSmplNotLoad(int unloadKey);

    /**
     * Diff шага {@code invDbtVarEnsure}: missing + ambiguous одним проходом CTE.
     *
     * @param unloadKey {@code cidutUnloadKey}
     * @return снимок для лога
     */
    SudzDbtUplInvDbtVarEnsureSnapshot findDbtUplInvDbtVarEnsureSnapshot(int unloadKey);

    /**
     * Diff шага {@code invDbtVarEnsure}: однозначная четвёрка FK, нет {@code invDbtVar}.
     *
     * @param unloadKey {@code cidutUnloadKey}
     * @return строки для лога
     */
    List<SudzDbtUplInvDbtVarEnsureRow> findDbtUplInvDbtVarEnsureMissing(int unloadKey);

    /**
     * Контексты {@code invDbtVarEnsure}, где {@code cnNum}/{@code invNum} не уникальны.
     *
     * @param unloadKey {@code cidutUnloadKey}
     * @return строки для лога
     */
    List<SudzDbtUplInvDbtVarAmbiguousRow> findDbtUplInvDbtVarEnsureAmbiguous(int unloadKey);

    /**
     * INSERT {@code sudz.invDbtVar} для однозначных отсутствующих контекстов.
     *
     * @param unloadKey {@code cidutUnloadKey}
     * @return число внесённых вариантов
     */
    SudzDbtUplInvDbtVarEnsureApplyResult applyDbtUplInvDbtVarEnsure(int unloadKey);

    /**
     * Пересборка очереди {@code CnInvUplInvDbtDouble} для выгрузки.
     *
     * @param unloadKey {@code upl_key}
     * @param fileKey {@code cidufKey} (может быть null)
     * @return число строк очереди после rebuild
     */
    int rebuildInvDbtDoubleQueue(int unloadKey, Integer fileKey);

    /**
     * Auto INSERT {@code sudz.invDbt} / {@code invDbtDbtVar} / {@code DbtValue} для однозначных iKey (B1b).
     *
     * @param unloadKey {@code upl_key}
     * @return счётчики apply (+ queuedCount после очистки очереди)
     */
    SudzDbtUplInvDbtLoadApplyResult applyDbtUplInvDbtLoadUnambiguous(int unloadKey);

    /**
     * Rebuild очереди InvDouble + apply однозначных (одно JDBC-соединение, temp-наборы).
     *
     * @param unloadKey {@code upl_key}
     * @param fileKey {@code cidufKey} (может быть null)
     * @param flLoad выполнять apply
     * @return счётчики apply или только queuedCount при {@code flLoad=false}
     */
    SudzDbtUplInvDbtLoadApplyResult runInvDbtLoadPhase(int unloadKey, Integer fileKey, boolean flLoad);

    /**
     * AccSmpl apply + invDbtVarEnsure apply + invDbtLoad phase в одном JDBC-соединении.
     *
     * @param unloadKey {@code upl_key}
     * @param fileKey {@code cidufKey} (может быть null)
     * @param flLoad выполнять apply-шаги
     * @return счётчики трёх подшагов
     */
    SudzDbtUplAccSmplVarInvPhaseResult runAccSmplVarInvDbtPhase(
            int unloadKey, Integer fileKey, boolean flLoad);

    /**
     * Снимок шага {@code invDbtDbtEnsure} (C1): слоты с Value на upl без {@code invDbtDbt}.
     *
     * @param unloadKey {@code upl_key}
     * @return missing / f1 / new / ambiguous
     */
    SudzDbtUplInvDbtDbtEnsureSnapshot findDbtUplInvDbtDbtEnsureSnapshot(int unloadKey);

    /**
     * Auto {@code Dbt} + {@code invDbtDbt} для слотов upl без моста (C1 / D7).
     *
     * @param unloadKey {@code upl_key}
     * @return счётчики apply
     */
    SudzDbtUplInvDbtDbtEnsureApplyResult applyDbtUplInvDbtDbtEnsure(int unloadKey);

    /**
     * Базовая выгрузка года ({@code yr.cn_inv_dbt_upl}) для upl в контексте портфеля.
     *
     * @param unloadKey текущая {@code upl_key}
     * @param yrKey контекст года ({@code yr.yr_key})
     * @return base upl или empty, если upl не входит в {@code yr_upl_p} года
     */
    Optional<Integer> findBaseUplForCurr(int unloadKey, int yrKey);

    /**
     * Года-портфели, в которых upl входит в {@code yr_upl_p}.
     *
     * @param uplKey {@code upl_key}
     * @return {@code yr_key} по возрастанию
     */
    List<Integer> findYearKeysForUpl(int uplKey);

    /**
     * Снимок шага {@code dbtValueLoad} (C2).
     *
     * @param unloadKey {@code upl_key}
     * @param yrKey контекст года
     * @return skip / tail / disappeared / P1
     */
    SudzDbtUplDbtValueLoadSnapshot findDbtUplDbtValueLoadSnapshot(int unloadKey, int yrKey);

    /**
     * Пересборка очереди {@code CnInvUplDbtP1} (исчезновение base→curr + sum-match).
     *
     * @param unloadKey {@code upl_key}
     * @param fileKey {@code cidufKey} (может быть null)
     * @param yrKey контекст года
     * @return число строк после rebuild
     */
    int rebuildDbtP1Queue(int unloadKey, Integer fileKey, int yrKey);

    /**
     * Apply tail {@code DbtValue} (C2).
     *
     * @param unloadKey {@code upl_key}
     * @param yrKey контекст года
     * @return счётчики tail
     */
    SudzDbtUplDbtValueLoadApplyResult applyDbtUplDbtValueLoadTail(int unloadKey, int yrKey);

    /**
     * Rebuild P1 + tail apply + снимок в одном JDBC-проходе (без повторных CTE).
     *
     * @param unloadKey {@code upl_key}
     * @param fileKey {@code cidufKey} (может быть null)
     * @param yrKey контекст года
     * @param flLoad выполнять tail apply
     * @return снимок и счётчики apply
     */
    SudzDbtUplDbtValueLoadPhaseResult runDbtValueLoadPhase(
            int unloadKey, Integer fileKey, int yrKey, boolean flLoad);

    /**
     * Очередь P1-кандидатов по выгрузке.
     *
     * @param unloadKey {@code upl_key}
     * @return строки {@code CnInvUplDbtP1}
     */
    List<SudzCnInvUplDbtP1> findDbtP1ByUnload(int unloadKey);

    /**
     * Очередь разбора двоящих задолженностей по выгрузке.
     *
     * @param unloadKey {@code upl_key}
     * @return строки {@code CnInvUplInvDbtDouble}
     */
    List<SudzCnInvUplInvDbtDouble> findInvDbtDoublesByUnload(int unloadKey);

    /**
     * Excel-кандидат для строки очереди двоящих долгов.
     *
     * @param ciudKey ключ {@code CnInvUplInvDbtDouble}
     * @return карточка Tbl
     */
    Optional<SudzSfDoubleExcelCandidate> findInvDbtDoubleExcelCandidate(int ciudKey);

    /**
     * Слоты {@code invDbt} по СФ.
     *
     * @param iKey {@code ags.inv.iKey}
     * @return слоты
     */
    List<SudzInvDbtSlot> findInvDbtSlotsByInv(int iKey);

    /**
     * Create нового слота + мост + {@code DbtValue} из очереди (A2).
     *
     * @param ciudKey ключ очереди
     * @return обновлённая строка
     */
    SudzCnInvUplInvDbtDouble createInvDbtFromDouble(int ciudKey);

    /**
     * Link к существующему слоту + мост + {@code DbtValue} (A2).
     *
     * @param ciudKey ключ очереди
     * @param idKey {@code invDbt.idKey}
     * @return обновлённая строка
     */
    SudzCnInvUplInvDbtDouble linkInvDbtDouble(int ciudKey, int idKey);

    /**
     * Кандидаты FK для create {@code invDbtVar} по строке очереди двоящих.
     *
     * @param ciudKey ключ {@code CnInvUplInvDbtDouble}
     * @return стороны / cnNum / invNum / account
     */
    SudzInvDbtVarCandidates findInvDbtVarCandidates(int ciudKey);

    /**
     * Советник КСДД (сегм. 22c).
     *
     * @param ciudKey ключ очереди
     * @param epsilon допуск суммы
     * @return рекомендация оператору
     */
    SudzInvDbtDoubleAdvice findInvDbtDoubleAdvice(int ciudKey, BigDecimal epsilon);

    /**
     * Временной ряд одного слота invDbt (вкладка «Динамика»).
     *
     * @param iKey СФ
     * @param idKey слот
     * @param ciudKey очередь (якорь Excel)
     * @return точки DbtValue
     */
    SudzInvDbtSlotTimeline findInvDbtSlotTimeline(int iKey, int idKey, int ciudKey);

    /**
     * INSERT (или reuse UNIQUE) {@code invDbtVar} и запись {@code ciudIdvvKey} в очередь.
     *
     * @param ciudKey ключ очереди
     * @param idvvCnNum выбранный {@code cnnKey}
     * @param idvvInvNum выбранный {@code inKey}
     * @param idvvAccnt счёт ГК
     * @param idvvCnSOrg сторона исполнителя
     * @return обновлённая строка очереди
     */
    SudzCnInvUplInvDbtDouble ensureInvDbtVarForDouble(
            int ciudKey,
            int idvvCnNum,
            int idvvInvNum,
            int idvvAccnt,
            int idvvCnSOrg
    );

    /**
     * Очередь КСДСФ по выгрузке долгов.
     *
     * @param unloadKey {@code upl_key}
     * @return строки {@code CnInvUplSfDouble}
     */
    List<SudzCnInvUplSfDouble> findSfDoublesByUnload(int unloadKey);

    /**
     * Excel-кандидат (строка Tbl) для строки очереди.
     *
     * @param ciusKey ключ очереди
     * @return карточка или empty
     */
    Optional<SudzSfDoubleExcelCandidate> findSfDoubleExcelCandidate(int ciusKey);

    /**
     * Доменные СФ с тем же номером.
     *
     * @param invNum номер СФ
     * @return совпадения (inv + cnInv)
     */
    List<SudzSfDoubleDomainMatch> findSfDoubleDomainMatches(String invNum);

    /**
     * Кандидаты вкладки «Суммы»: {@code cn_inv_dbt} и {@code DbtValue} по сумме ±ε.
     *
     * @param debt сумма Excel ({@code cidutDebt})
     * @param epsilon допуск (рубли), обычно {@code 0.01}
     * @return списки совпадений (лимит TOP 200 на каждую сторону)
     */
    SudzSfDoubleSumMatches findSfDoubleSumMatches(BigDecimal debt, BigDecimal epsilon);

    /**
     * Подсказки КСДСФ: исполнитель Excel среди СФ по номеру и сумм (old/new).
     *
     * @param ciusKey ключ очереди
     * @param epsilon допуск суммы (для зон сумм)
     * @return три секции с ключами выбора строк
     */
    SudzSfDoubleHints findSfDoubleHints(int ciusKey, BigDecimal epsilon);

    /**
     * Советник КСДСФ: рекомендация link / create / manual для оператора.
     *
     * @param ciusKey ключ очереди
     * @param epsilon допуск суммы (для подсказок по суммам)
     * @return блок {@code [советник]}
     */
    SudzSfDoubleAdvice findSfDoubleAdvice(int ciusKey, BigDecimal epsilon);

    /**
     * Создать новый СФ по строке очереди (Access {@code btnInvAdd} / {@code btnInvCreate}).
     *
     * @param ciusKey ключ очереди со статусом open
     * @return обновлённая строка
     */
    SudzCnInvUplSfDouble createSfFromDouble(int ciusKey);

    /**
     * Привязать строку очереди к существующему договору через {@code ags.cnInv}.
     *
     * @param ciusKey ключ очереди со статусом open
     * @param invKey ключ существующего {@code ags.inv}
     * @param cnKey ключ существующего {@code ags.cn}
     * @return обновлённая строка
     */
    SudzCnInvUplSfDouble linkSfDoubleToCn(int ciusKey, int invKey, int cnKey);
}
