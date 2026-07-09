package com.femsq.web.audit.staging;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class StagingLogLevelTest {

    @Test
    void resolve_nullDbValue_returnsApplicationDefault() {
        assertEquals(StagingLogLevel.SUMMARY, StagingLogLevel.resolve(null, StagingLogLevel.SUMMARY));
    }

    @Test
    void resolve_validDbValue_returnsLevel() {
        assertEquals(StagingLogLevel.VERBOSE, StagingLogLevel.resolve("verbose", StagingLogLevel.SUMMARY));
    }

    @Test
    void resolve_invalidDbValue_returnsApplicationDefault() {
        assertEquals(StagingLogLevel.MINIMAL, StagingLogLevel.resolve("UNKNOWN", StagingLogLevel.MINIMAL));
    }

    @Test
    void verbose_usesSingleRowInsert() {
        assertEquals(true, StagingLogLevel.VERBOSE.logEachStagingRow());
        assertEquals(false, StagingLogLevel.SUMMARY.logEachStagingRow());
    }
}
