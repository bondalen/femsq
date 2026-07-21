package com.femsq.web.audit.stage2;

import java.util.List;

/**
 * Аномалия резолюции стройки (эквивалент {@code ags.ogAgFeePnTestCstNo}).
 *
 * <p>Одна запись = один код стройки; Excel-строки — все упоминания в текущем {@code exec_key}.
 *
 * @param cstCode    код стройки из Excel ({@code oafptPnCstAgPn})
 * @param excelRows  номера строк листа Excel (1-based), может быть пустым если {@code oafptRow} ещё нет
 * @param rowCount   число staging-строк с этим кодом
 */
public record AgFeeCstAnomaly(String cstCode, List<Integer> excelRows, int rowCount) {

    /**
     * Компактный конструктор с защитой от null в списке строк.
     */
    public AgFeeCstAnomaly {
        excelRows = excelRows == null ? List.of() : List.copyOf(excelRows);
    }
}
