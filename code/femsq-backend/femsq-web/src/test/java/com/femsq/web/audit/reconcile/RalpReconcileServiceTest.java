package com.femsq.web.audit.reconcile;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.time.LocalDate;
import org.junit.jupiter.api.Test;

class RalpReconcileServiceTest {

    @Test
    void computeCloseDate_usesDayBeforeNewArrived() {
        LocalDate oldArrived = LocalDate.of(2026, 3, 10);
        LocalDate newArrived = LocalDate.of(2026, 3, 15);
        assertEquals(LocalDate.of(2026, 3, 14),
                RalpReconcileService.computeCloseDate(oldArrived, null, newArrived));
    }

    @Test
    void computeCloseDate_notBeforeOldArrived() {
        LocalDate oldArrived = LocalDate.of(2026, 3, 20);
        LocalDate newArrived = LocalDate.of(2026, 3, 15);
        assertEquals(oldArrived,
                RalpReconcileService.computeCloseDate(oldArrived, null, newArrived));
    }

    @Test
    void computeCloseDate_considersOldSentDate() {
        LocalDate oldArrived = LocalDate.of(2026, 3, 5);
        LocalDate oldSent = LocalDate.of(2026, 3, 12);
        LocalDate newArrived = LocalDate.of(2026, 3, 15);
        assertEquals(LocalDate.of(2026, 3, 14),
                RalpReconcileService.computeCloseDate(oldArrived, oldSent, newArrived));
    }

    @Test
    void syntheticReturned_formatsRussianPrefix() {
        assertEquals("автозакрытие от 09.07.2026",
                RalpReconcileService.syntheticReturned(LocalDate.of(2026, 7, 9)));
    }

    @Test
    void parseDate_extractsFirstDdMmYyyy() {
        assertEquals(LocalDate.of(2021, 5, 20),
                RalpReconcileService.parseDate("ИЛ-02/99-4345 от 20.05.2021"));
    }
}
