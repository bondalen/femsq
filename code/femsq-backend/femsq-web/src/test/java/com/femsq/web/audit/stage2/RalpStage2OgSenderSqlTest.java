package com.femsq.web.audit.stage2;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

/**
 * Unit: Stage 2 RALP пишет отправителя как VBA — {@code onfOg} ({@code og.ogKey}), не {@code onfKey}.
 *
 * <p>0054.7.3 / RCA prod dry-run 2026-08-04.</p>
 */
class RalpStage2OgSenderSqlTest {

    @Test
    void sqlOgSender_setsOnfOg_notOnfKey() {
        String sql = RalpStage2Service.SQL_OG_SENDER;
        assertTrue(sql.contains("SET stg.ralprtOgSender = og.onfOg"), sql);
        assertTrue(sql.contains("AND og.onfOg IS NOT NULL"), sql);
        assertFalse(sql.contains("= og.onfKey"), sql);
    }

    @Test
    void sqlSenderSm_setsOnfOg_notOnfKey() {
        String sql = RalpStage2Service.SQL_SENDER_SM;
        assertTrue(sql.contains("SET sm.ralprsSender = og.onfOg"), sql);
        assertTrue(sql.contains("AND og.onfOg IS NOT NULL"), sql);
        assertFalse(sql.contains("= og.onfKey"), sql);
    }
}
