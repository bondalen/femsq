package com.femsq.web.audit.excel;

import java.io.FileInputStream;
import java.util.function.Function;
import org.apache.poi.openxml4j.util.ZipSecureFile;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.springframework.stereotype.Component;

/**
 * Компонент открытия Excel-книг (XLSX/XLS) через Apache POI.
 * Гарантирует закрытие книги после использования.
 */
@Component
public class AuditExcelReader {

    /**
     * Открывает книгу Excel по пути {@code path}, передаёт её в {@code consumer} и возвращает результат.
     * Книга закрывается независимо от результата.
     *
     * @throws AuditExcelException при ошибке открытия файла
     */
    public <T> T withWorkbook(String path, Function<Workbook, T> consumer) {
        double previousRatio = ZipSecureFile.getMinInflateRatio();
        ZipSecureFile.setMinInflateRatio(0.0);
        try (var is = new FileInputStream(path);
             Workbook workbook = WorkbookFactory.create(is)) {
            return consumer.apply(workbook);
        } catch (AuditExcelException e) {
            throw e;
        } catch (java.io.FileNotFoundException e) {
            throw new AuditExcelException("Excel file not found: " + path, e);
        } catch (Exception e) {
            throw new AuditExcelException("Failed to open Excel file: " + path + " — " + e.getMessage(), e);
        } finally {
            ZipSecureFile.setMinInflateRatio(previousRatio);
        }
    }
}
