package com.femsq.web.audit.excel;

/**
 * Исключение, сигнализирующее об ошибке при чтении Excel-файла или staging-загрузке.
 */
public class AuditExcelException extends RuntimeException {

    public AuditExcelException(String message) {
        super(message);
    }

    public AuditExcelException(String message, Throwable cause) {
        super(message, cause);
    }
}
