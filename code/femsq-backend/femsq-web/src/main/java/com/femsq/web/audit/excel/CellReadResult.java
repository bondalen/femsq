package com.femsq.web.audit.excel;

/**
 * Результат типизированного чтения ячейки Excel: значение, исходный текст и ошибка формата (если есть).
 *
 * @param <T> целевой тип значения
 * @param value        распознанное значение или {@code null}
 * @param rawText      строковое представление ячейки до преобразования
 * @param parseError   сообщение об ошибке парсинга; {@code null} — успех
 * @param expectedType человекочитаемый ожидаемый тип для лога ревизии
 */
public record CellReadResult<T>(T value, String rawText, String parseError, String expectedType) {

    /**
     * Возвращает {@code true}, если ячейка прочитана без ошибки формата.
     */
    public boolean ok() {
        return parseError == null;
    }

    /**
     * Успешное чтение.
     */
    public static <T> CellReadResult<T> success(T value, String rawText) {
        return new CellReadResult<>(value, rawText, null, null);
    }

    /**
     * Ошибка формата: значение не распознано.
     */
    public static <T> CellReadResult<T> failure(String rawText, String parseError, String expectedType) {
        return new CellReadResult<>(null, rawText, parseError, expectedType);
    }
}
