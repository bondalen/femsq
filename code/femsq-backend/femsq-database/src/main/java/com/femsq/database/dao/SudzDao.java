package com.femsq.database.dao;

import com.femsq.database.model.sudz.SudzCmmGrLookup;
import com.femsq.database.model.sudz.SudzD644Row;
import com.femsq.database.model.sudz.SudzDebtCollection;
import com.femsq.database.model.sudz.SudzPmLink;
import com.femsq.database.model.sudz.SudzPmUplLookup;
import com.femsq.database.model.sudz.SudzRsltDebt;
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
     */
    void updateYear(int yrKey, String variant, int baseUplKey, int yKey, Integer cmmGrKey);

    /**
     * Дописывает строку в {@code yr_Progress} (лог формирования документов).
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
}
