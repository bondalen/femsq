package com.femsq.web.audit.reconcile;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.web.audit.reconcile.AgFee2306ReconcileService.ActHeader;
import com.femsq.web.audit.reconcile.AgFee2306ReconcileService.ActKey;
import com.femsq.web.audit.reconcile.AgFee2306ReconcileService.AttrSnapshot;
import com.femsq.web.audit.reconcile.AgFee2306ReconcileService.DomainAttrs;
import com.femsq.web.audit.reconcile.AgFee2306ReconcileService.PnMatchKey;
import com.femsq.web.audit.reconcile.AgFee2306ReconcileService.StgLine;
import com.femsq.web.audit.reconcile.AgFee2306ReconcileService.StgPn;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/**
 * Unit-тесты type=6: заголовки (Фаза C) и пункты (Фаза D).
 */
class AgFee2306ReconcileServiceTest {

    @Test
    void buildHeaders_groupsBySenderNameDate() {
        StgLine a1 = line(1, "А-1", LocalDate.of(2025, 3, 1), "in-1", null, null, null);
        StgLine a2 = line(1, "А-1", LocalDate.of(2025, 3, 1), "in-1", null, null, null);
        StgLine b = line(1, "А-2", LocalDate.of(2025, 3, 2), "in-2", null, null, null);

        Map<ActKey, ActHeader> headers = AgFee2306ReconcileService.buildHeaders(List.of(a1, a2, b));
        assertEquals(2, headers.size());
        ActHeader h1 = headers.get(new ActKey(1, "А-1", LocalDate.of(2025, 3, 1)));
        assertNotNull(h1);
        assertFalse(h1.ambiguousAttrs());
        assertEquals("in-1", h1.attrs().arrivedNum());
    }

    @Test
    void buildHeaders_marksAmbiguousWhenAttrsDiffer() {
        StgLine a1 = line(1, "А-1", LocalDate.of(2025, 3, 1), "in-1", null, null, null);
        StgLine a2 = line(1, "А-1", LocalDate.of(2025, 3, 1), "in-2", null, null, null);

        Map<ActKey, ActHeader> headers = AgFee2306ReconcileService.buildHeaders(List.of(a1, a2));
        ActHeader h = headers.get(new ActKey(1, "А-1", LocalDate.of(2025, 3, 1)));
        assertTrue(h.ambiguousAttrs());
        assertNull(h.attrs());
        assertEquals(2, h.attrVariants());
    }

    @Test
    void buildHeaders_skipsInvalidLines() {
        StgLine bad = new StgLine();
        bad.oafName = "X";
        bad.oafDate = LocalDate.of(2025, 1, 1);
        Map<ActKey, ActHeader> headers = AgFee2306ReconcileService.buildHeaders(List.of(bad));
        assertTrue(headers.isEmpty());
    }

    @Test
    void resolveYear_modalWins() {
        StgLine y25a = line(1, "A", LocalDate.of(2025, 1, 1), null, null, null, null);
        StgLine y25b = line(1, "B", LocalDate.of(2025, 2, 1), null, null, null, null);
        StgLine y24 = line(1, "C", LocalDate.of(2024, 1, 1), null, null, null, null);
        Map<ActKey, ActHeader> headers = AgFee2306ReconcileService.buildHeaders(List.of(y25a, y25b, y24));
        assertEquals(2025, AgFee2306ReconcileService.resolveYear(headers));
    }

    @Test
    void attrsEqual_comparesBusinessFieldsAndYearMonth() {
        AttrSnapshot excel = new AttrSnapshot(
                "1", LocalDate.of(2025, 1, 10),
                "2", LocalDate.of(2025, 1, 11),
                null, null, null,
                "C", "U"
        );
        DomainAttrs dbOk = new DomainAttrs(excel, 5, 1);
        assertTrue(AgFee2306ReconcileService.attrsEqual(dbOk, excel, 5, 1));

        DomainAttrs dbWrongMonth = new DomainAttrs(excel, 5, 2);
        assertFalse(AgFee2306ReconcileService.attrsEqual(dbWrongMonth, excel, 5, 1));

        AttrSnapshot excel2 = new AttrSnapshot(
                "1", LocalDate.of(2025, 1, 10),
                "CHANGED", LocalDate.of(2025, 1, 11),
                null, null, null,
                "C", "U"
        );
        assertFalse(AgFee2306ReconcileService.attrsEqual(dbOk, excel2, 5, 1));
    }

    @Test
    void buildStagingPns_groupsByActAndCst() {
        StgLine a = line(1, "А-1", LocalDate.of(2026, 1, 31), null, 10, "051-1", new BigDecimal("100.00"));
        StgLine b = line(1, "А-1", LocalDate.of(2026, 1, 31), null, 10, "051-1", new BigDecimal("100.0"));
        StgLine c = line(1, "А-1", LocalDate.of(2026, 1, 31), null, 11, "051-2", new BigDecimal("50"));

        Map<PnMatchKey, StgPn> pns = AgFee2306ReconcileService.buildStagingPns(List.of(a, b, c), 2026);
        assertEquals(2, pns.size());
        StgPn p1 = pns.get(new PnMatchKey(new ActKey(1, "А-1", LocalDate.of(2026, 1, 31)), 10));
        assertFalse(p1.ambiguousTtl());
        assertEquals(0, p1.ttl().compareTo(new BigDecimal("100")));
    }

    @Test
    void buildStagingPns_marksAmbiguousTtl() {
        StgLine a = line(1, "А-1", LocalDate.of(2026, 1, 31), null, 10, "051-1", new BigDecimal("100"));
        StgLine b = line(1, "А-1", LocalDate.of(2026, 1, 31), null, 10, "051-1", new BigDecimal("200"));

        Map<PnMatchKey, StgPn> pns = AgFee2306ReconcileService.buildStagingPns(List.of(a, b), 2026);
        StgPn p = pns.values().iterator().next();
        assertTrue(p.ambiguousTtl());
        assertNull(p.ttl());
    }

    @Test
    void buildStagingPns_skipsOtherYearAndNoCst() {
        StgLine otherYear = line(1, "А-1", LocalDate.of(2025, 1, 1), null, 10, "x", BigDecimal.ONE);
        StgLine noCst = line(1, "А-2", LocalDate.of(2026, 1, 1), null, null, "y", BigDecimal.TEN);
        Map<PnMatchKey, StgPn> pns = AgFee2306ReconcileService.buildStagingPns(List.of(otherYear, noCst), 2026);
        assertTrue(pns.isEmpty());
    }

    @Test
    void totalsEqual_and_sumStaging() {
        assertTrue(AgFee2306ReconcileService.totalsEqual(new BigDecimal("1.0"), new BigDecimal("1.00")));
        assertFalse(AgFee2306ReconcileService.totalsEqual(BigDecimal.ONE, BigDecimal.TEN));

        StgLine a = line(1, "А-1", LocalDate.of(2026, 1, 31), null, 10, "a", new BigDecimal("100"));
        StgLine b = line(1, "А-1", LocalDate.of(2026, 1, 31), null, 11, "b", new BigDecimal("50.5"));
        Map<PnMatchKey, StgPn> pns = AgFee2306ReconcileService.buildStagingPns(List.of(a, b), 2026);
        assertEquals(0, AgFee2306ReconcileService.sumStagingTotals(pns).compareTo(new BigDecimal("150.5")));
    }

    private static StgLine line(
            int sender,
            String name,
            LocalDate date,
            String arrivedNum,
            Integer cstKey,
            String cstCode,
            BigDecimal ttl
    ) {
        StgLine line = new StgLine();
        line.senderKey = sender;
        line.oafName = name;
        line.oafDate = date;
        line.arrivedNum = arrivedNum;
        line.cstAgPnKey = cstKey;
        line.cstCode = cstCode;
        line.ttl = ttl;
        return line;
    }
}
