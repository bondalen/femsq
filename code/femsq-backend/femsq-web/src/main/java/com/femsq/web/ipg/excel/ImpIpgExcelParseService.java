package com.femsq.web.ipg.excel;

import com.femsq.database.exception.DaoException;
import com.femsq.database.model.ImpIpgLoad;
import com.femsq.database.model.ImpIpgParseResult;
import com.femsq.database.service.ImpIpgLoadService;
import java.nio.file.Path;
import java.util.Objects;
import java.util.logging.Logger;
import org.springframework.stereotype.Service;

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
     * @param loadKey  ключ {@code impIpgLoad}
     * @param filePath путь к файлу; null/blank → взять из сессии
     * @return итог разбора
     */
    public ImpIpgParseResult parseLoad(int loadKey, String filePath) {
        ImpIpgLoad load = loadService.getLoad(loadKey)
                .orElseThrow(() -> new DaoException("impIpgLoad не найден: " + loadKey));
        String resolvedPath = (filePath != null && !filePath.isBlank())
                ? filePath.trim()
                : load.iilFilePath();
        if (resolvedPath == null || resolvedPath.isBlank()) {
            throw new IpgAnnualExcelException(
                    "Не задан путь к Excel (аргумент filePath или iilFilePath сессии " + loadKey + ")");
        }
        Path path = Path.of(resolvedPath);
        log.info(() -> "parseLoad load=" + loadKey + " path=" + path);
        IpgAnnualExcelParser.ParseOutcome outcome = parser.parse(path);
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
        return new ImpIpgParseResult(
                loadKey,
                outcome.sheetName(),
                resolvedPath,
                outcome.sectionCount(),
                outcome.leafCount(),
                written);
    }
}
