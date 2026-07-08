package com.femsq.web.audit.excel;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Objects;
import java.util.function.Function;
import org.apache.poi.EncryptedDocumentException;
import org.apache.poi.openxml4j.util.ZipSecureFile;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.springframework.stereotype.Component;

/**
 * Единая точка входа для безопасного открытия Excel-книги в audit-конвейере.
 * Поддерживает Zip bomb mitigation, зашифрованные файлы (legacy-пароль) и гарантированное закрытие ресурсов.
 */
@Component
public class AuditExcelReader {

    /** Пароль по умолчанию для legacy audit Excel (VBA-конвенция). */
    private static final String DEFAULT_EXCEL_PASSWORD = "303";

    /**
     * Открывает workbook по строковому пути.
     *
     * @param path     путь к файлу Excel
     * @param consumer функция обработки workbook
     * @param <T>      тип результата
     * @return результат consumer
     * @throws AuditExcelException при ошибке открытия файла
     */
    public <T> T withWorkbook(String path, Function<Workbook, T> consumer) {
        Objects.requireNonNull(path, "path");
        return withWorkbook(Path.of(path), consumer);
    }

    /**
     * Открывает workbook по пути, выполняет callback и гарантированно закрывает ресурсы.
     *
     * @param filePath путь к файлу Excel
     * @param consumer функция обработки workbook
     * @param <T>      тип результата
     * @return результат consumer
     * @throws AuditExcelException при ошибке открытия файла
     */
    public <T> T withWorkbook(Path filePath, Function<Workbook, T> consumer) {
        Objects.requireNonNull(filePath, "filePath");
        Objects.requireNonNull(consumer, "consumer");
        if (!Files.exists(filePath)) {
            throw new AuditExcelException("Excel file not found: " + filePath);
        }
        double previousRatio = ZipSecureFile.getMinInflateRatio();
        ZipSecureFile.setMinInflateRatio(0.0);
        try {
            try {
                return withWorkbookUsingPassword(filePath, consumer, null);
            } catch (EncryptedDocumentException encryptedWithoutPassword) {
                return withWorkbookUsingPassword(filePath, consumer, DEFAULT_EXCEL_PASSWORD);
            }
        } catch (AuditExcelException exception) {
            throw exception;
        } catch (IOException exception) {
            throw new AuditExcelException("Failed to read Excel file: " + filePath, exception);
        } catch (Exception exception) {
            throw new AuditExcelException("Failed to open Excel file: " + filePath + " — " + exception.getMessage(), exception);
        } finally {
            ZipSecureFile.setMinInflateRatio(previousRatio);
        }
    }

    private <T> T withWorkbookUsingPassword(Path filePath, Function<Workbook, T> consumer, String password)
            throws IOException {
        try (InputStream inputStream = Files.newInputStream(filePath);
             Workbook workbook = WorkbookFactory.create(inputStream, password)) {
            return consumer.apply(workbook);
        } catch (EncryptedDocumentException exception) {
            if (password != null) {
                throw new AuditExcelException("Failed to read encrypted Excel file: " + filePath, exception);
            }
            throw exception;
        }
    }
}
