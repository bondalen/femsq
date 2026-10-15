package com.femsq.web.api.rest;

import com.femsq.database.config.DatabaseConfigurationService.MissingConfigurationException;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.sudz.SudzD644Row;
import com.femsq.database.model.sudz.SudzRsltDebt;
import com.femsq.database.model.sudz.SudzSvodResult;
import com.femsq.database.service.SudzService;
import com.femsq.web.api.sudz.SudzD644ExcelExporter;
import com.femsq.web.api.sudz.SudzRsltExcelExporter;
import com.femsq.web.api.sudz.SudzRsltReturnImporter;
import com.femsq.web.api.sudz.SudzRsltReturnParse;
import com.femsq.web.api.sudz.SudzRsltReturnProgress;
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

    private static final DateTimeFormatter FILE_STAMP =
            DateTimeFormatter.ofPattern("yyyy-MM-dd_HHmmss");

    private final SudzService sudzService;

    /**
     * @param sudzService доменный сервис СУДЗ
     */
    public SudzExportRestController(SudzService sudzService) {
        this.sudzService = sudzService;
    }

    /**
     * Rslt (сбор): Excel со срезами до {@code asOfUpl} и пустыми колонками {@code *_new}.
     * Протокол прогона пишет экран через {@code replaceSudzYearProgress}.
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
            String stamp = LocalDateTime.now().format(FILE_STAMP);
            String fileName = "ags_Yr_DbtChangesRslt_" + yr + "_" + asOfUpl + "_" + stamp + ".xlsx";
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
     * Протокол прогона пишет экран через {@code replaceSudzYearProgress}, этот ответ лог не меняет.
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
            String stamp = LocalDateTime.now().format(FILE_STAMP);
            String fileName = "ags_Yr_DbtChangesRslt_" + yr + "_" + asOfUpl + "_povtor_" + stamp + ".xlsx";
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
     * Итоговый документ D644 (построчно, {@code yr_CmmGr}).
     *
     * @param yr ключ год-варианта
     * @param currUpl текущий срез
     * @return файл xlsx
     */
    @GetMapping(value = "/d644.xlsx", produces = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    public ResponseEntity<byte[]> exportD644(
            @RequestParam int yr,
            @RequestParam int currUpl
    ) {
        try {
            List<SudzD644Row> rows = sudzService.getD644(yr, currUpl);
            byte[] body = SudzD644ExcelExporter.exportD644(rows);
            String stamp = LocalDateTime.now().format(FILE_STAMP);
            String fileName = "ags_Yr_DbtChangesRsltD644_" + yr + "_" + currUpl + "_" + stamp + ".xlsx";
            log.log(Level.INFO, "D644 Excel yr={0}, currUpl={1}, rows={2}, bytes={3}",
                    new Object[]{yr, currUpl, rows.size(), body.length});
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
            log.log(Level.WARNING, "D644 Excel DAO error: {0}", exception.getMessage());
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        } catch (IOException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Ошибка генерации Excel", exception);
        }
    }

    /**
     * Годовой свод по субсчетам Д644.
     * Протокол прогона пишет экран через {@code replaceSudzYearProgress}.
     *
     * @param yr ключ год-варианта
     * @param currUpl текущий срез
     * @return файл xlsx
     */
    @GetMapping(value = "/d644-svod.xlsx", produces = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    public ResponseEntity<byte[]> exportD644Svod(
            @RequestParam int yr,
            @RequestParam int currUpl
    ) {
        try {
            SudzSvodResult svod = sudzService.getD644Svod(yr, currUpl);
            byte[] body = SudzD644ExcelExporter.exportSvod(svod);
            String stamp = LocalDateTime.now().format(FILE_STAMP);
            String fileName = "ags_Yr_DbtChangesD644Svod_" + yr + "_" + currUpl + "_" + stamp + ".xlsx";
            int accounts = svod.accounts() != null ? svod.accounts().size() : 0;
            log.log(Level.INFO, "D644Svod Excel yr={0}, currUpl={1}, accounts={2}, bytes={3}",
                    new Object[]{yr, currUpl, accounts, body.length});
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
            log.log(Level.WARNING, "D644Svod Excel DAO error: {0}", exception.getMessage());
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
        String fileName = file.getOriginalFilename() != null ? file.getOriginalFilename() : "return.xlsx";
        SudzRsltReturnParse parse = null;
        try {
            parse = SudzRsltReturnImporter.parse(file.getInputStream());
            if (parse.rows().isEmpty()) {
                String reason = "В файле нет строк с заполненными *_new";
                rememberReturnProgress(yr, SudzRsltReturnProgress.failure(
                        fileName, yr, parse, reason, LocalDateTime.now()));
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, reason);
            }
            var imported = sudzService.importRsltReturn(yr, parse.rows());
            rememberReturnProgress(yr, SudzRsltReturnProgress.success(
                    fileName, yr, parse, imported, LocalDateTime.now()));
            log.log(Level.INFO,
                    "Rslt return import yr={0}, imported={1}, extreme={2}, walkBack={3}, acc={4}, file={5}",
                    new Object[]{yr, imported.importedDebts(), imported.boundExtreme(),
                            imported.boundWalkBack(), imported.boundAcc(), fileName});
            return Map.of(
                    "yr", yr,
                    "imported", imported.importedDebts(),
                    "boundExtreme", imported.boundExtreme(),
                    "boundWalkBack", imported.boundWalkBack(),
                    "boundAcc", imported.boundAcc(),
                    "parsed", parse.sourceRows(),
                    "fileName", fileName
            );
        } catch (ResponseStatusException exception) {
            throw exception;
        } catch (IllegalArgumentException exception) {
            rememberReturnProgress(yr, SudzRsltReturnProgress.failure(
                    fileName, yr, parse, exception.getMessage(), LocalDateTime.now()));
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
        } catch (MissingConfigurationException exception) {
            rememberReturnProgress(yr, SudzRsltReturnProgress.failure(
                    fileName, yr, parse, exception.getMessage(), LocalDateTime.now()));
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, exception.getMessage(), exception);
        } catch (DaoException exception) {
            rememberReturnProgress(yr, SudzRsltReturnProgress.failure(
                    fileName, yr, parse, exception.getMessage(), LocalDateTime.now()));
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        } catch (IOException exception) {
            rememberReturnProgress(yr, SudzRsltReturnProgress.failure(
                    fileName, yr, null, "Не удалось прочитать Excel", LocalDateTime.now()));
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Не удалось прочитать Excel", exception);
        }
    }

    /**
     * Пишет протокол прогона в {@code yr_Progress}. Сбой записи лога не скрывает результат импорта.
     *
     * @param yr ключ года
     * @param protocol текст протокола
     */
    private void rememberReturnProgress(int yr, String protocol) {
        try {
            sudzService.replaceYearProgress(yr, protocol);
        } catch (RuntimeException progressError) {
            log.log(Level.WARNING, "Не удалось записать протокол yr_Progress: {0}", progressError.getMessage());
        }
    }
}
