package com.femsq.web.ipg.excel;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.ipglog.ImpIpgLoadLogContext;
import com.femsq.database.model.ImpIpgLoadMonf;
import com.femsq.database.model.ImpIpgMonfParseResult;
import com.femsq.database.model.ImpIpgMonfParseRow;
import com.femsq.database.service.ImpIpgLoadMonfService;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.springframework.stereotype.Service;

/**
 * Оркестрация parse skeleton Monf → staging в ответе + {@code iilmResults} (C2 §6.5).
 */
@Service
public class ImpIpgLoadMonfParseService {

    private static final Logger log = Logger.getLogger(ImpIpgLoadMonfParseService.class.getName());
    private static final int SAMPLE_ROWS = 12;

    private final ImpIpgLoadMonfService monfService;
    private final IpgMonfExcelParser parser;
    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public ImpIpgLoadMonfParseService(
            ImpIpgLoadMonfService monfService,
            IpgMonfExcelParser parser,
            ConnectionFactory connectionFactory,
            DatabaseConfigurationService configurationService) {
        this.monfService = Objects.requireNonNull(monfService, "monfService");
        this.parser = Objects.requireNonNull(parser, "parser");
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
        this.configurationService = Objects.requireNonNull(configurationService, "configurationService");
    }

    /**
     * Разбирает Excel Monf; пишет HTML в {@code iilmResults}; staging только в ответе (без apply).
     *
     * @param monfKey  ключ строки Monf
     * @param filePath путь или null → {@code iilmFilePath}
     */
    public ImpIpgMonfParseResult parse(int monfKey, String filePath) {
        ImpIpgLoadMonf monf = monfService.get(monfKey)
                .orElseThrow(() -> new DaoException("impIpgLoadMonf не найден: " + monfKey));
        String resolvedPath = (filePath != null && !filePath.isBlank())
                ? filePath.trim()
                : monf.iilmFilePath();
        StringBuilder html = new StringBuilder();
        html.append("<div class=\"monf-parse\">");
        html.append("<p><b>LdM / Monf parse</b> · monf=").append(monfKey).append("</p>");
        try {
            if (resolvedPath == null || resolvedPath.isBlank()) {
                throw new IpgMonfExcelException("Не задан путь к Excel (filePath / iilmFilePath)");
            }
            Path path = Path.of(resolvedPath);
            html.append("<p>Файл: <code>")
                    .append(ImpIpgLoadLogContext.esc(resolvedPath))
                    .append("</code></p>");
            if (!Files.isRegularFile(path)) {
                throw new IpgMonfExcelException("Файл не найден: " + resolvedPath);
            }
            String limColumn = monf.iilmLimColumn();
            if (limColumn == null || limColumn.isBlank()) {
                limColumn = "лимит";
            }
            int sumFirst = monf.iilmSumFirst() != null ? monf.iilmSumFirst() : 1;
            boolean quarter = monf.iilmQuarter();
            html.append("<p>Лист: ")
                    .append(ImpIpgLoadLogContext.esc(nullToDash(monf.iilmSheet())))
                    .append(" · limColumn=«")
                    .append(ImpIpgLoadLogContext.esc(limColumn))
                    .append("» · quarter=")
                    .append(quarter)
                    .append(" · sumFirst=")
                    .append(sumFirst)
                    .append("</p>");

            Set<String> costNames = loadCostItsNames();
            html.append("<p>Справочник направлений затрат (отсев): ")
                    .append(costNames.size())
                    .append(" имён</p>");

            log.info(() -> "parseMonf monf=" + monfKey + " path=" + path);
            IpgMonfExcelParser.ParseOutcome outcome = parser.parse(
                    path,
                    monf.iilmSheet(),
                    limColumn,
                    quarter,
                    sumFirst,
                    costNames);

            html.append("<p class=\"ok\">Лист «")
                    .append(ImpIpgLoadLogContext.esc(outcome.sheetName()))
                    .append("» · код col=")
                    .append(outcome.codeColumn1Based())
                    .append(" · lim col=")
                    .append(outcome.limColumn1Based())
                    .append("</p>");
            html.append("<p>Маска кода: hits=")
                    .append(outcome.codeHits())
                    .append(" · loaded=")
                    .append(outcome.loadedCount())
                    .append(" · skipped=")
                    .append(outcome.skippedCount())
                    .append("</p>");
            appendSampleTable(html, outcome.rows());

            if (filePath != null && !filePath.isBlank()
                    && (monf.iilmFilePath() == null || !resolvedPath.equals(monf.iilmFilePath()))) {
                monfService.update(
                        monfKey,
                        monf.iilmUtPl(),
                        monf.iilmNm(),
                        resolvedPath,
                        monf.iilmSheet(),
                        monf.iilmLimColumn(),
                        monf.iilmQuarter(),
                        monf.iilmSumFirst(),
                        monf.iilmNote());
            }

            String logHtml = html.append("</div>").toString();
            monfService.updateResults(monfKey, logHtml);
            return new ImpIpgMonfParseResult(
                    monfKey,
                    outcome.sheetName(),
                    resolvedPath,
                    outcome.codeColumn1Based(),
                    outcome.limColumn1Based(),
                    quarter,
                    sumFirst,
                    outcome.codeHits(),
                    outcome.loadedCount(),
                    outcome.skippedCount(),
                    outcome.rows(),
                    logHtml);
        } catch (RuntimeException ex) {
            html.append("<p class=\"err\">")
                    .append(ImpIpgLoadLogContext.esc(String.valueOf(ex.getMessage())))
                    .append("</p></div>");
            try {
                monfService.updateResults(monfKey, html.toString());
            } catch (RuntimeException persistEx) {
                log.log(Level.WARNING, "Не удалось сохранить iilmResults monf=" + monfKey, persistEx);
            }
            throw ex;
        }
    }

    private void appendSampleTable(StringBuilder html, List<ImpIpgMonfParseRow> rows) {
        html.append("<table border=\"1\" cellpadding=\"2\" cellspacing=\"0\">");
        html.append("<tr><th>#</th><th>row</th><th>код</th><th>имя</th><th>limYear</th><th>M01</th></tr>");
        int shown = Math.min(rows.size(), SAMPLE_ROWS);
        for (int i = 0; i < shown; i++) {
            ImpIpgMonfParseRow row = rows.get(i);
            BigDecimal m01 = row.months().isEmpty() ? null : row.months().get(0);
            html.append("<tr><td>").append(i + 1).append("</td><td>")
                    .append(row.rowNo()).append("</td><td>")
                    .append(ImpIpgLoadLogContext.esc(row.cstCode())).append("</td><td>")
                    .append(ImpIpgLoadLogContext.esc(nullToDash(row.name()))).append("</td><td>")
                    .append(row.limYear() != null ? row.limYear().toPlainString() : "—")
                    .append("</td><td>")
                    .append(m01 != null ? m01.toPlainString() : "—")
                    .append("</td></tr>");
        }
        if (rows.size() > SAMPLE_ROWS) {
            html.append("<tr><td colspan=\"6\">… ещё ")
                    .append(rows.size() - SAMPLE_ROWS)
                    .append(" строк</td></tr>");
        }
        html.append("</table>");
    }

    private Set<String> loadCostItsNames() {
        String schema;
        try {
            schema = configurationService.loadConfig().schema();
            if (schema == null || schema.isBlank()) {
                schema = "ags";
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            log.log(Level.WARNING, "schema missing for costIts", exception);
            schema = "ags";
        }
        String sql = "SELECT iciName FROM " + schema.trim() + ".ipgCostItsNmAll";
        Set<String> names = new HashSet<>();
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            while (resultSet.next()) {
                String name = resultSet.getString(1);
                if (name != null && !name.isBlank()) {
                    names.add(name.trim());
                }
            }
        } catch (SQLException exception) {
            log.log(Level.WARNING, "Не удалось загрузить ipgCostItsNmAll — отсев имён пропущен", exception);
        }
        return Set.copyOf(names);
    }

    private static String nullToDash(String value) {
        return value == null || value.isBlank() ? "—" : value;
    }
}
