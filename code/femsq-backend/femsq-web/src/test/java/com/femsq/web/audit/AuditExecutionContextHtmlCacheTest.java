package com.femsq.web.audit;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;

import com.femsq.web.audit.staging.StagingLogLevel;
import org.junit.jupiter.api.Test;

class AuditExecutionContextHtmlCacheTest {

    @Test
    void buildHtmlLog_reusesCacheUntilNewEntry() {
        AuditExecutionContext context = new AuditExecutionContext(1L);
        context.append(AuditLogLevel.INFO, AuditLogScope.AUDIT, "A", "<P>one</P>", null);
        String first = context.buildHtmlLog();
        String second = context.buildHtmlLog();
        assertSame(first, second);

        context.append(AuditLogLevel.INFO, AuditLogScope.AUDIT, "B", "<P>two</P>", null);
        String third = context.buildHtmlLog();
        assertEquals(2, context.getEntries().size());
        org.junit.jupiter.api.Assertions.assertNotSame(first, third);
    }

    @Test
    void progressFlushInterval_summaryIsTenSeconds() {
        assertEquals(10_000L, StagingLogLevel.SUMMARY.progressFlushIntervalMs());
        assertEquals(1_000L, StagingLogLevel.VERBOSE.progressFlushIntervalMs());
        assertEquals(30_000L, StagingLogLevel.MINIMAL.progressFlushIntervalMs());
    }
}
