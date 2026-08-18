package com.femsq.web.api.graphql;

import com.femsq.database.config.DatabaseConfigurationService.MissingConfigurationException;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.sudz.SudzCmmGrLookup;
import com.femsq.database.model.sudz.SudzCnInvUplSfDouble;
import com.femsq.database.model.sudz.SudzD644Row;
import com.femsq.database.model.sudz.SudzDbtUplFile;
import com.femsq.database.model.sudz.SudzDbtUplFunnelResult;
import com.femsq.database.model.sudz.SudzDbtUplLauncher;
import com.femsq.database.model.sudz.SudzDebtCollection;
import com.femsq.database.model.sudz.SudzPmLink;
import com.femsq.database.model.sudz.SudzPmUplLookup;
import com.femsq.database.model.sudz.SudzRsltDebt;
import com.femsq.database.model.sudz.SudzSfDoubleDomainMatch;
import com.femsq.database.model.sudz.SudzSfDoubleExcelCandidate;
import com.femsq.database.model.sudz.SudzSfDoubleTreeDebt;
import com.femsq.database.model.sudz.SudzSvodResult;
import com.femsq.database.model.sudz.SudzUplLookup;
import com.femsq.database.model.sudz.SudzYear;
import com.femsq.database.model.sudz.SudzYearDetail;
import com.femsq.database.model.sudz.SudzYearUpl;
import com.femsq.database.model.sudz.SudzYyyyLookup;
import com.femsq.database.service.SudzService;
import com.femsq.web.api.dto.sudz.CreateSudzCmmGrInput;
import com.femsq.web.api.dto.sudz.CreateSudzPmUplInput;
import com.femsq.web.api.dto.sudz.CreateSudzUplInput;
import com.femsq.web.api.dto.sudz.CreateSudzYearInput;
import com.femsq.web.api.dto.sudz.RunSudzDbtUplFunnelInput;
import com.femsq.web.api.dto.sudz.SudzDebtCollectionInput;
import com.femsq.web.api.dto.sudz.UpdateSudzDbtUplFileInput;
import com.femsq.web.api.dto.sudz.UpdateSudzYearInput;
import com.femsq.web.api.sudz.SudzDbtUplFunnelRunner;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.web.server.ResponseStatusException;

/**
 * GraphQL-контроллер витрин СУДЗ и CRUD портфеля года.
 */
@Controller
public class SudzGraphqlController {

    private static final Logger log = Logger.getLogger(SudzGraphqlController.class.getName());

    private final SudzService sudzService;
    private final SudzDbtUplFunnelRunner dbtUplFunnelRunner;

    /**
     * @param sudzService сервис СУДЗ
     * @param dbtUplFunnelRunner оркестратор воронки excelToTbl+…
     */
    public SudzGraphqlController(
            SudzService sudzService,
            SudzDbtUplFunnelRunner dbtUplFunnelRunner
    ) {
        this.sudzService = sudzService;
        this.dbtUplFunnelRunner = dbtUplFunnelRunner;
    }

    /**
     * Список год-вариантов.
     *
     * @return годы
     */
    @QueryMapping
    public List<SudzYear> sudzYears() {
        try {
            return sudzService.listYears();
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    /**
     * Карточка года.
     *
     * @param yrKey ключ года
     * @return деталь
     */
    @QueryMapping
    public SudzYearDetail sudzYear(@Argument int yrKey) {
        try {
            return sudzService.getYearDetail(yrKey);
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    /**
     * Lookup выгрузок ДЗ.
     *
     * @return список
     */
    @QueryMapping
    public List<SudzUplLookup> sudzUplLookups() {
        try {
            return sudzService.listUplLookups();
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    /**
     * Lookup групп комментариев.
     *
     * @return список
     */
    @QueryMapping
    public List<SudzCmmGrLookup> sudzCmmGrLookups() {
        try {
            return sudzService.listCmmGrLookups();
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    /**
     * Lookup календарных лет.
     *
     * @return список
     */
    @QueryMapping
    public List<SudzYyyyLookup> sudzYyyyLookups() {
        try {
            return sudzService.listYyyyLookups();
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    /**
     * Lookup выгрузок платежей.
     *
     * @return список
     */
    @QueryMapping
    public List<SudzPmUplLookup> sudzPmUplLookups() {
        try {
            return sudzService.listPmUplLookups();
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    /**
     * Портфель года (Rslt).
     *
     * @param yr ключ год-варианта
     * @param asOfUpl опционально: срезы до выгрузки включительно
     * @return долги
     */
    @QueryMapping
    public List<SudzRsltDebt> sudzYrDbtChanges(@Argument int yr, @Argument Integer asOfUpl) {
        try {
            return sudzService.getYrDbtChanges(yr, asOfUpl);
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    /**
     * Документ D644.
     *
     * @param yr ключ года
     * @param currUpl текущая выгрузка
     * @return строки
     */
    @QueryMapping
    public List<SudzD644Row> sudzD644(@Argument int yr, @Argument int currUpl) {
        try {
            return sudzService.getD644(yr, currUpl);
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            log.log(Level.WARNING, "D644 failed: {0}", exception.getMessage());
            throw badRequestFromDao(exception);
        }
    }

    /**
     * Годовой свод.
     *
     * @param yr ключ года
     * @param currUpl текущая выгрузка
     * @return свод
     */
    @QueryMapping
    public SudzSvodResult sudzD644Svod(@Argument int yr, @Argument int currUpl) {
        try {
            return sudzService.getD644Svod(yr, currUpl);
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            log.log(Level.WARNING, "D644Svod failed: {0}", exception.getMessage());
            throw badRequestFromDao(exception);
        }
    }

    /**
     * Создание год-варианта.
     *
     * @param input поля
     * @return карточка
     */
    @MutationMapping
    public SudzYearDetail createSudzYear(@Argument CreateSudzYearInput input) {
        try {
            return sudzService.createYear(
                    input.variant(),
                    input.baseUplKey(),
                    input.newUplName(),
                    input.newUplDate(),
                    input.newUplStatusOnDate(),
                    input.yKey(),
                    input.cmmGrKey()
            );
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    /**
     * Обновление год-варианта.
     *
     * @param input поля
     * @return карточка
     */
    @MutationMapping
    public SudzYearDetail updateSudzYear(@Argument UpdateSudzYearInput input) {
        try {
            return sudzService.updateYear(
                    input.yrKey(),
                    input.variant(),
                    input.baseUplKey(),
                    input.yKey(),
                    input.cmmGrKey(),
                    input.cmmGrNewKey()
            );
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    /**
     * Удаление год-варианта.
     *
     * @param yrKey ключ
     * @return true
     */
    @MutationMapping
    public boolean deleteSudzYear(@Argument int yrKey) {
        try {
            return sudzService.deleteYear(yrKey);
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    /**
     * Создание выгрузки ДЗ.
     *
     * @param input поля
     * @return выгрузка
     */
    @MutationMapping
    public SudzUplLookup createSudzUpl(@Argument CreateSudzUplInput input) {
        try {
            return sudzService.createUpl(input.name(), input.uplDate(), input.statusOnDate());
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    /**
     * Добавление выгрузки в год.
     *
     * @param yrKey ключ года
     * @param uplKey ключ выгрузки
     * @return строка yr_upl_p
     */
    @MutationMapping
    public SudzYearUpl addSudzYearUpl(@Argument int yrKey, @Argument int uplKey) {
        try {
            return sudzService.addYearUpl(yrKey, uplKey);
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    /**
     * Удаление выгрузки из года.
     *
     * @param yrUplPKey ключ
     * @return true
     */
    @MutationMapping
    public boolean removeSudzYearUpl(@Argument int yrUplPKey) {
        try {
            return sudzService.removeYearUpl(yrUplPKey);
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    /**
     * Создание выгрузки платежей.
     *
     * @param input поля
     * @return выгрузка
     */
    @MutationMapping
    public SudzPmUplLookup createSudzPmUpl(@Argument CreateSudzPmUplInput input) {
        try {
            return sudzService.createPmUpl(input.name(), input.date());
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    /**
     * Связь ДЗ-выгрузки с платежами.
     *
     * @param dbtUplKey ключ ДЗ
     * @param pmKey ключ платежей
     * @return связь
     */
    @MutationMapping
    public SudzPmLink addSudzPmLink(@Argument int dbtUplKey, @Argument int pmKey) {
        try {
            return sudzService.addPmLink(dbtUplKey, pmKey);
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    /**
     * Удаление связи платежей.
     *
     * @param gPKey ключ
     * @return true
     */
    @MutationMapping
    public boolean removeSudzPmLink(@Argument int gPKey) {
        try {
            return sudzService.removePmLink(gPKey);
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    /**
     * Сохранение сбора (куратор / мероприятия / код стройки).
     *
     * @param input поля сбора
     * @return актуальные значения
     */
    @MutationMapping
    public SudzDebtCollection updateSudzDebtCollection(@Argument SudzDebtCollectionInput input) {
        try {
            return sudzService.updateDebtCollection(
                    input.yr(),
                    input.dbtKey(),
                    input.curator(),
                    input.mery(),
                    input.cstCode()
            );
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    /**
     * Дописывает строку в {@code yr_Progress}.
     *
     * @param yrKey ключ года
     * @param line текст события
     * @return полный лог
     */
    @MutationMapping
    public String appendSudzYearProgress(@Argument int yrKey, @Argument String line) {
        try {
            return sudzService.appendYearProgress(yrKey, line);
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    /**
     * Создаёт группу комментариев (для привязки к {@code yr_CmmGr_New}).
     *
     * @param input имя и дата
     * @return lookup
     */
    @MutationMapping
    public SudzCmmGrLookup createSudzCmmGr(@Argument CreateSudzCmmGrInput input) {
        try {
            return sudzService.createCmmGr(input.name(), input.date());
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    /**
     * Лаунчер загрузки свода для выбранной выгрузки.
     *
     * @param uplKey ключ выгрузки
     * @return карточка лаунчера
     */
    @QueryMapping
    public SudzDbtUplLauncher sudzDbtUplLauncher(@Argument int uplKey) {
        try {
            return sudzService.getDbtUplLauncher(uplKey);
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    /**
     * Excel-кандидат КСДСФ.
     *
     * @param ciusKey ключ очереди
     * @return карточка или null
     */
    @QueryMapping
    public SudzSfDoubleExcelCandidate sudzSfDoubleExcelCandidate(@Argument int ciusKey) {
        try {
            return sudzService.findSfDoubleExcelCandidate(ciusKey).orElse(null);
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    /**
     * Доменные СФ с совпадающим номером.
     *
     * @param invNum номер СФ
     * @return список
     */
    @QueryMapping
    public List<SudzSfDoubleDomainMatch> sudzSfDoubleDomainMatches(@Argument String invNum) {
        try {
            return sudzService.findSfDoubleDomainMatches(invNum);
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    /**
     * СГК простой и новая ДЗ для дерева КСДСФ.
     *
     * @param invKey {@code inv.iKey}
     * @return вложенные карточки
     */
    @QueryMapping
    public SudzSfDoubleTreeDebt sudzSfDoubleTreeDebt(@Argument int invKey) {
        try {
            return sudzService.findSfDoubleTreeDebt(invKey);
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    /**
     * Создать СФ из очереди КСДСФ.
     *
     * @param ciusKey ключ open
     * @return обновлённая строка
     */
    @MutationMapping
    public SudzCnInvUplSfDouble createSudzSfFromDouble(@Argument int ciusKey) {
        try {
            return sudzService.createSfFromDouble(ciusKey);
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    /**
     * Upsert шапки лаунчера {@code CnInvDbtUplFile}.
     *
     * @param input поля
     * @return актуальная шапка
     */
    @MutationMapping
    public SudzDbtUplFile updateSudzDbtUplFile(@Argument UpdateSudzDbtUplFileInput input) {
        try {
            return sudzService.updateDbtUplFile(input.uplKey(), input.path(), input.flLoad(), input.flTbl());
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    /**
     * Stub-прогон воронки загрузки свода (панель шагов S61f).
     *
     * @param input uplKey, steps, flLoad
     * @return результат с логом
     */
    @MutationMapping
    public SudzDbtUplFunnelResult runSudzDbtUplFunnel(@Argument RunSudzDbtUplFunnelInput input) {
        try {
            return dbtUplFunnelRunner.run(input.uplKey(), input.steps(), input.flLoad());
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    /**
     * Откат договоров, созданных шагом CnNotLoad с данным {@code cnMark}.
     *
     * @param cnMark метка из лога воронки
     * @return число удалённых строк {@code ags.cn}
     */
    @MutationMapping
    public int rollbackSudzCnNotLoad(@Argument int cnMark) {
        try {
            return sudzService.rollbackCnNotLoadByMark(cnMark);
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    private ResponseStatusException badRequest(IllegalArgumentException exception) {
        return new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
    }

    private ResponseStatusException badRequestFromDao(DaoException exception) {
        String message = exception.getMessage();
        Throwable cause = exception.getCause();
        if (cause != null && cause.getMessage() != null && !cause.getMessage().isBlank()) {
            message = cause.getMessage();
        }
        return new ResponseStatusException(HttpStatus.BAD_REQUEST, message, exception);
    }

    private ResponseStatusException unavailable(MissingConfigurationException exception) {
        return new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, exception.getMessage(), exception);
    }

    private ResponseStatusException internal(DaoException exception) {
        return new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
    }
}
