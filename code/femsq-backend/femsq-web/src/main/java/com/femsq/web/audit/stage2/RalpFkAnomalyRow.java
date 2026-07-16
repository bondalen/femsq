package com.femsq.web.audit.stage2;

import java.time.LocalDate;

/**
 * Строка staging RALP с незаполненным FK/датой после Stage 2 (аномалии A1–A4).
 *
 * @param stagingKey     {@code ralprt_key}
 * @param excelRow       {@code ralprtRow} (1-based), может быть {@code null} на старых прогонах
 * @param reportNum      номер отчёта
 * @param reportDate     дата отчёта
 * @param cstCodeStr     код стройки из Excel
 * @param ogSenderStr    отправитель из Excel
 * @param ogBranchStr    филиал из Excel
 * @param cstAgPn        FK стройки (NULL = не разрешён)
 * @param ogSender       FK отправителя (NULL = не разрешён)
 */
public record RalpFkAnomalyRow(
        long stagingKey,
        Integer excelRow,
        String reportNum,
        LocalDate reportDate,
        String cstCodeStr,
        String ogSenderStr,
        String ogBranchStr,
        Integer cstAgPn,
        Integer ogSender
) {
    /**
     * @return {@code true}, если строка попадает под критерий invalid reconcile
     */
    public boolean isUnresolved() {
        return cstAgPn == null || ogSender == null || reportDate == null;
    }
}
