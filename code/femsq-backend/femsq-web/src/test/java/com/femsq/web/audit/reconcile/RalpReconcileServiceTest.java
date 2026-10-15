package com.femsq.web.audit.reconcile;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
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

    @Test
    void partitionForInClause_splitsAboveSqlServerLimit() {
        List<Integer> keys = new ArrayList<>();
        for (int i = 1; i <= 2292; i++) {
            keys.add(i);
        }
        List<List<Integer>> chunks =
                RalpReconcileService.partitionForInClause(keys, RalpReconcileService.BULK_IN_CHUNK);
        assertEquals(5, chunks.size());
        assertEquals(500, chunks.get(0).size());
        assertEquals(500, chunks.get(1).size());
        assertEquals(500, chunks.get(2).size());
        assertEquals(500, chunks.get(3).size());
        assertEquals(292, chunks.get(4).size());
        int total = chunks.stream().mapToInt(List::size).sum();
        assertEquals(2292, total);
        for (List<Integer> chunk : chunks) {
            assertTrue(chunk.size() < 2100);
        }
    }

    @Test
    void partitionForInClause_empty() {
        assertEquals(List.of(), RalpReconcileService.partitionForInClause(List.of(), 500));
    }
}
