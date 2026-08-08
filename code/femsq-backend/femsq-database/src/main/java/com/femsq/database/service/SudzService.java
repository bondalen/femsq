package com.femsq.database.service;

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
    SudzYearDetail updateYear(int yrKey, String variant, int baseUplKey, int yKey, Integer cmmGrKey);

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
}
