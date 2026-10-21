package com.femsq.web.api.sudz.brief;

import com.femsq.database.service.SudzService;
import com.femsq.web.api.sudz.SudzDbtUplExcelPathResolver;
import java.io.IOException;
import java.nio.file.Path;
import java.time.LocalDate;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.springframework.stereotype.Service;

/**
 * Оркестратор краткого отчёта по входящему своду (**1.1.1.0.3.2**).
 */
@Service
public class SudzBriefReportService {

    private static final Logger log = Logger.getLogger(SudzBriefReportService.class.getName());

    private final SudzService sudzService;
    private final SudzBriefReportBuilder builder = new SudzBriefReportBuilder();

    /**
     * @param sudzService доступ к словарю FIO
     */
    public SudzBriefReportService(SudzService sudzService) {
        this.sudzService = sudzService;
    }

    /**
     * Резолвит путь свода, читает словарь, пишет {@code …_краткий_отчёт.xlsx} рядом.
     *
     * @param svodPath путь как в Проводнике / POSIX
     * @param asOf дата отчёта (L6)
     * @return результат прогона
     */
    public SudzBriefReportResult prepare(String svodPath, LocalDate asOf) {
        Path resolved = SudzDbtUplExcelPathResolver.resolveExisting(svodPath)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Файл свода не найден: " + svodPath));
        List<String> words = sudzService.listFioDictWords();
        if (words.isEmpty()) {
            throw new IllegalStateException("Ошибка: Словарь пуст");
        }
        FioByDictionary fio = new FioByDictionary(words);
        try {
            SudzBriefReportResult result = builder.build(resolved, asOf, fio);
            log.log(Level.INFO, "prepareSudzBriefReport out={0} H={1}",
                    new Object[]{result.outputPath(), result.totalDebtH()});
            return result;
        } catch (IOException exception) {
            throw new IllegalStateException(
                    "Не удалось собрать краткий отчёт: " + exception.getMessage(), exception);
        }
    }
}
