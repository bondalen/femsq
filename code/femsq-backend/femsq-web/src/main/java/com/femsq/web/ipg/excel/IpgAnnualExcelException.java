package com.femsq.web.ipg.excel;

/**
 * Ошибка разбора Excel годовой ИП.
 */
public class IpgAnnualExcelException extends RuntimeException {

    public IpgAnnualExcelException(String message) {
        super(message);
    }

    public IpgAnnualExcelException(String message, Throwable cause) {
        super(message, cause);
    }
}
