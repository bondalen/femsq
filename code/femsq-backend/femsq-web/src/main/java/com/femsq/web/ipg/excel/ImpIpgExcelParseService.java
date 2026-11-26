package com.femsq.web.ipg.excel;

import com.femsq.database.exception.DaoException;
import com.femsq.database.ipglog.ImpIpgLoadLogContext;
import com.femsq.database.ipglog.ImpIpgLoadLogScope;
import com.femsq.database.ipglog.ImpIpgLoadLogSupport;
import com.femsq.database.model.ImpIpgLoad;
import com.femsq.database.model.ImpIpgParseResult;
import com.femsq.database.service.ImpIpgLoadService;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.Objects;
import java.util.logging.Logger;
import org.springframework.stereotype.Service;

import static com.femsq.database.ipglog.ImpIpgLoadLogCodes.*;
import static com.femsq.database.ipglog.ImpIpgLoadLogLevel.*;

/**
 * Оркестрация парсинга Excel годовой ИП в staging {@code impIpg} (C2 §3.1.6.2).
 */
@Service
public class ImpIpgExcelParseService {

    private static final Logger log = Logger.getLogger(ImpIpgExcelParseService.class.getName());

    private final ImpIpgLoadService loadService;
    private final IpgAnnualExcelParser parser;

    public ImpIpgExcelParseService(ImpIpgLoadService loadService, IpgAnnualExcelParser parser) {
        this.loadService = Objects.requireNonNull(loadService, "loadService");
        this.parser = Objects.requireNonNull(parser, "parser");
    }

    /**
     * Читает Excel (путь из аргумента или {@code iilFilePath}), заменяет staging сессии.
     *
     * <p>Ведёт накопительный лог «Ход загрузки» (C2 §3.5.4): LOAD → FILE → WORKBOOK → PARSE;
     * лог сохраняется в {@code iilResults} в том числе при ошибке (исключение пробрасывается).
     *
     * @param loadKey  ключ {@code impIpgLoad}
     * @param filePath путь к файлу; null/blank → взять из сессии
     * @return итог разбора (с накопительным {@code logHtml})
     */
    public ImpIpgParseResult parseLoad(int loadKey, String filePath) {
        ImpIpgLoad load = loadService.getLoad(loadKey)
                .orElseThrow(() -> new DaoException("impIpgLoad не найден: " + loadKey));
        ImpIpgLoadLogContext logCtx = new ImpIpgLoadLogContext(loadKey);
        String previousHtml = load.iilResults();
        String loadSpan = logCtx.beginSpan(INFO, ImpIpgLoadLogScope.LOAD, IPG_LOAD_START,
                "<b>Загрузка ИП</b>: разбор Excel, сессия " + loadKey);
        try {
            return doParse(load, loadKey, filePath, logCtx, loadSpan, previousHtml);
        } catch (RuntimeException ex) {
            logCtx.append(ERROR, ImpIpgLoadLogScope.PARSE, IPG_LOAD_ERROR,
                    ImpIpgLoadLogContext.esc(String.valueOf(ex.getMessage())));
            logCtx.endSpan(loadSpan, ERROR, ImpIpgLoadLogScope.LOAD, IPG_LOAD_ERROR, "Разбор прерван");
            ImpIpgLoadLogSupport.finishAndPersist(
                    logCtx, previousHtml, true, loadService::updateLoadResults, loadKey, log);
            throw ex;
        }
    }

    private ImpIpgParseResult doParse(
            ImpIpgLoad load,
            int loadKey,
            String filePath,
            ImpIpgLoadLogContext logCtx,
            String loadSpan,
            String previousHtml) {
        String resolvedPath = (filePath != null && !filePath.isBlank())
                ? filePath.trim()
                : load.iilFilePath();
        if (resolvedPath == null || resolvedPath.isBlank()) {
            logCtx.append(ERROR, ImpIpgLoadLogScope.FILE, FILE_MISSING, "Путь к Excel не задан");
            throw new IpgAnnualExcelException(
                    "Не задан путь к Excel (аргумент filePath или iilFilePath сессии " + loadKey + ")");
        }
        Path path = Path.of(resolvedPath);
        String fileSpan = logCtx.beginSpan(INFO, ImpIpgLoadLogScope.FILE, FILE_RESOLVE_OK,
                "Файл: <code>" + ImpIpgLoadLogContext.esc(resolvedPath) + "</code>",
                Map.of("path", resolvedPath));
        if (!Files.isRegularFile(path)) {
            logCtx.endSpan(fileSpan, ERROR, ImpIpgLoadLogScope.FILE, FILE_MISSING, "Файл не найден");
        } else {
            logCtx.endSpan(fileSpan, SUCCESS, ImpIpgLoadLogScope.FILE, FILE_RESOLVE_OK, "Файл найден");
        }
        log.info(() -> "parseLoad load=" + loadKey + " path=" + path);

        String bookSpan = logCtx.beginSpan(INFO, ImpIpgLoadLogScope.PARSE, WORKBOOK_OPEN,
                "Открытие книги Excel");
        IpgAnnualExcelParser.ParseOutcome outcome;
        try {
            logCtx.append(INFO, ImpIpgLoadLogScope.PARSE, PARSE_START, "Разбор листа приложения");
            outcome = parser.parse(path);
        } finally {
            logCtx.endSpan(bookSpan, INFO, ImpIpgLoadLogScope.PARSE, WORKBOOK_CLOSE, "Книга закрыта");
        }
        logCtx.append(SUCCESS, ImpIpgLoadLogScope.PARSE, PARSE_SHEET,
                "Лист: «" + ImpIpgLoadLogContext.esc(outcome.sheetName()) + "»",
                Map.of("sheet", String.valueOf(outcome.sheetName())));
        logCtx.append(INFO, ImpIpgLoadLogScope.PARSE, PARSE_STATS,
                "разделов " + outcome.sectionCount() + ", листьев " + outcome.leafCount());

        if (filePath != null && !filePath.isBlank()
                && (load.iilFilePath() == null || !resolvedPath.equals(load.iilFilePath()))) {
            loadService.updateLoad(loadKey, load.iilNm(), resolvedPath, load.iilNote());
        }
        int written = loadService.replaceStaging(loadKey, outcome.drafts());
        log.info(() -> "parseLoad done load=" + loadKey
                + " sheet=" + outcome.sheetName()
                + " S=" + outcome.sectionCount()
                + " L=" + outcome.leafCount()
                + " written=" + written);
        logCtx.append(SUCCESS, ImpIpgLoadLogScope.PARSE, PARSE_STAGING_WRITTEN,
                "В staging записано строк: " + written, Map.of("written", String.valueOf(written)));
        logCtx.append(SUMMARY, ImpIpgLoadLogScope.SUMMARY, PARSE_END,
                "разделов " + outcome.sectionCount() + ", листьев " + outcome.leafCount()
                        + ", строк staging " + written);
        logCtx.endSpan(loadSpan, SUCCESS, ImpIpgLoadLogScope.LOAD, IPG_LOAD_END, "Разбор завершён");
        String html = ImpIpgLoadLogSupport.finishAndPersist(
                logCtx, previousHtml, true, loadService::updateLoadResults, loadKey, log);
        return new ImpIpgParseResult(
                loadKey,
                outcome.sheetName(),
                resolvedPath,
                outcome.sectionCount(),
                outcome.leafCount(),
                written,
                html);
    }
}
