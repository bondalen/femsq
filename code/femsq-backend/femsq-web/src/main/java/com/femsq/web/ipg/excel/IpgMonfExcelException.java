package com.femsq.web.ipg.excel;

/**
 * Ошибка разбора помесячного Excel (C2 §6.5).
 */
public class IpgMonfExcelException extends RuntimeException {

    public IpgMonfExcelException(String message) {
        super(message);
    }

    public IpgMonfExcelException(String message, Throwable cause) {
        super(message, cause);
    }
}
