package com.femsq.web.api.sudz;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.model.sudz.SudzPmtUplLogOnlyResult;
import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * Сжатый лог H2: сводка N + первые K.
 */
class SudzPmtUplCompressedLogTest {

    @Test
    void appendEmptyWritesOliveMessage() {
        SudzDbtUplProgressLog progress = new SudzDbtUplProgressLog();
        SudzPmtUplCompressedLog.append(
                progress,
                "<font color=\"Olive\"><b>пусто</b></font>.",
                "Найдено",
                SudzPmtUplLogOnlyResult.empty());
        String html = progress.toHtml();
        assertTrue(html.contains("пусто"));
        assertFalse(html.contains("первые"));
    }

    @Test
    void appendSamplesTruncatesWithEllipsis() {
        SudzDbtUplProgressLog progress = new SudzDbtUplProgressLog();
        List<String> samples = List.of("a", "b", "c");
        SudzPmtUplCompressedLog.append(
                progress,
                "empty",
                "Найдено",
                new SudzPmtUplLogOnlyResult(10, samples));
        String html = progress.toHtml();
        assertTrue(html.contains("<b>10</b>"));
        assertTrue(html.contains("1."));
        assertTrue(html.contains("ещё 7"));
    }
}
