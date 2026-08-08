package com.femsq.web.api.rest;

import com.femsq.database.config.DatabaseConfigurationService.MissingConfigurationException;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.sudz.SudzRsltDebt;
import com.femsq.database.model.sudz.SudzRsltReturnRow;
import com.femsq.database.service.SudzService;
import com.femsq.web.api.sudz.SudzRsltExcelExporter;
import com.femsq.web.api.sudz.SudzRsltReturnImporter;
import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

/**
 * REST-выгрузка бинарных документов СУДЗ (Excel). Осознанное исключение из GraphQL-only.
 */
@RestController
@RequestMapping("/api/v1/sudz")
public class SudzExportRestController {

    private static final Logger log = Logger.getLogger(SudzExportRestController.class.getName());

    private final SudzService sudzService;

    /**
     * @param sudzService доменный сервис СУДЗ
     */
    public SudzExportRestController(SudzService sudzService) {
        this.sudzService = sudzService;
    }

    /**
     * Rslt (сбор): Excel со срезами до {@code asOfUpl} и пустыми колонками {@code *_new}.
     *
     * @param yr ключ год-варианта
     * @param asOfUpl выгрузка «срезы до …» (обязательна)
     * @return файл xlsx
     */
    @GetMapping(value = "/rslt-sborn.xlsx", produces = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    public ResponseEntity<byte[]> exportRsltSborn(
            @RequestParam int yr,
            @RequestParam int asOfUpl
    ) {
        try {
            List<SudzRsltDebt> debts = sudzService.getYrDbtChanges(yr, asOfUpl);
            byte[] body = SudzRsltExcelExporter.exportRsltSborn(debts);
            // Дата-время в имени: повторное «Сформировать» не перезаписывает тот же файл (FSA).
            String stamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd_HHmmss"));
            String fileName = "ags_Yr_DbtChangesRslt_" + yr + "_" + asOfUpl + "_" + stamp + ".xlsx";
            String line = String.format(
                    "[%s] Rslt сбор · Excel | yr=%d | asOfUpl=%d | долгов=%d | файл=%s | ok",
                    LocalDateTime.now().withNano(0),
                    yr,
                    asOfUpl,
                    debts.size(),
                    fileName
            );
            try {
                sudzService.appendYearProgress(yr, line);
            } catch (RuntimeException progressError) {
                log.log(Level.WARNING, "Не удалось дописать yr_Progress: {0}", progressError.getMessage());
            }
            log.log(Level.INFO, "Rslt сбор Excel yr={0}, asOfUpl={1}, rows={2}, bytes={3}",
                    new Object[]{yr, asOfUpl, debts.size(), body.length});
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + fileName + "\"")
                    .contentType(MediaType.parseMediaType(
                            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                    .body(body);
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
        } catch (MissingConfigurationException exception) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, exception.getMessage(), exception);
        } catch (DaoException exception) {
            log.log(Level.WARNING, "Rslt Excel DAO error: {0}", exception.getMessage());
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        } catch (IOException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Ошибка генерации Excel", exception);
        }
    }

    /**
     * Rslt (повтор): «старые» из {@code yr_CmmGr}, колонки {@code *_new} из {@code yr_CmmGr_New}.
     *
     * @param yr ключ год-варианта
     * @param asOfUpl выгрузка «срезы до …»
     * @return файл xlsx
     */
    @GetMapping(value = "/rslt-povtor.xlsx", produces = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    public ResponseEntity<byte[]> exportRsltPovtor(
            @RequestParam int yr,
            @RequestParam int asOfUpl
    ) {
        try {
            List<SudzRsltDebt> debts = sudzService.getYrDbtChanges(yr, asOfUpl);
            byte[] body = SudzRsltExcelExporter.exportRsltPovtor(debts);
            String stamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd_HHmmss"));
            String fileName = "ags_Yr_DbtChangesRslt_" + yr + "_" + asOfUpl + "_povtor_" + stamp + ".xlsx";
            String line = String.format(
                    "[%s] Rslt повтор · Excel | yr=%d | asOfUpl=%d | долгов=%d | файл=%s | ok",
                    LocalDateTime.now().withNano(0),
                    yr,
                    asOfUpl,
                    debts.size(),
                    fileName
            );
            try {
                sudzService.appendYearProgress(yr, line);
            } catch (RuntimeException progressError) {
                log.log(Level.WARNING, "Не удалось дописать yr_Progress: {0}", progressError.getMessage());
            }
            log.log(Level.INFO, "Rslt повтор Excel yr={0}, asOfUpl={1}, rows={2}, bytes={3}",
                    new Object[]{yr, asOfUpl, debts.size(), body.length});
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + fileName + "\"")
                    .contentType(MediaType.parseMediaType(
                            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                    .body(body);
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
        } catch (MissingConfigurationException exception) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, exception.getMessage(), exception);
        } catch (DaoException exception) {
            log.log(Level.WARNING, "Rslt повтор Excel DAO error: {0}", exception.getMessage());
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        } catch (IOException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Ошибка генерации Excel", exception);
        }
    }

    /**
     * Импорт возврата Rslt: колонки {@code *_new} → {@code yr_CmmGr_New}.
     *
     * @param yr ключ года
     * @param file xlsx
     * @return краткий JSON-результат
     */
    @PostMapping(value = "/rslt-return", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public Map<String, Object> importRsltReturn(
            @RequestParam int yr,
            @RequestParam("file") MultipartFile file
    ) {
        if (file == null || file.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Файл возврата пуст");
        }
        try {
            List<SudzRsltReturnRow> rows = SudzRsltReturnImporter.parse(file.getInputStream());
            if (rows.isEmpty()) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "В файле нет строк с заполненными *_new"
                );
            }
            int imported = sudzService.importRsltReturn(yr, rows);
            String fileName = file.getOriginalFilename() != null ? file.getOriginalFilename() : "return.xlsx";
            String line = String.format(
                    "[%s] Rslt повтор · Загрузить | yr=%d | долгов=%d | файл=%s | ok",
                    LocalDateTime.now().withNano(0),
                    yr,
                    imported,
                    fileName
            );
            try {
                sudzService.appendYearProgress(yr, line);
            } catch (RuntimeException progressError) {
                log.log(Level.WARNING, "Не удалось дописать yr_Progress: {0}", progressError.getMessage());
            }
            log.log(Level.INFO, "Rslt return import yr={0}, imported={1}, file={2}",
                    new Object[]{yr, imported, fileName});
            return Map.of(
                    "yr", yr,
                    "imported", imported,
                    "parsed", rows.size(),
                    "fileName", fileName
            );
        } catch (ResponseStatusException exception) {
            throw exception;
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
        } catch (MissingConfigurationException exception) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, exception.getMessage(), exception);
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        } catch (IOException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Не удалось прочитать Excel", exception);
        }
    }
}
