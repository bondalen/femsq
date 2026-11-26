package com.femsq.database.ipglog;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

/**
 * Тесты сборки HTML лога загрузки ИП (§3.5.4).
 */
class ImpIpgLoadLogContextTest {

    @Test
    void buildsNestedDetailsWithAuditLogClasses() {
        ImpIpgLoadLogContext ctx = new ImpIpgLoadLogContext(8);
        String root = ctx.beginSpan(ImpIpgLoadLogLevel.INFO, ImpIpgLoadLogScope.LOAD,
                ImpIpgLoadLogCodes.IPG_LOAD_START, "Загрузка");
        String apply = ctx.beginSpan(ImpIpgLoadLogLevel.INFO, ImpIpgLoadLogScope.APPLY,
                ImpIpgLoadLogCodes.APPLY_START, "Применение");
        ctx.append(ImpIpgLoadLogLevel.ERROR, ImpIpgLoadLogScope.APPLY,
                ImpIpgLoadLogCodes.APPLY_ROW_ERR, "ошибка");
        ctx.endSpan(apply, ImpIpgLoadLogLevel.WARNING, ImpIpgLoadLogScope.APPLY,
                ImpIpgLoadLogCodes.APPLY_END, "конец");
        ctx.endSpan(root, ImpIpgLoadLogLevel.WARNING, ImpIpgLoadLogScope.LOAD,
                ImpIpgLoadLogCodes.IPG_LOAD_END, "итог");

        String html = ctx.buildHtmlLog();

        assertTrue(html.startsWith("<div class=\"femsq-auditlog\">"));
        assertTrue(html.contains("<details open"));
        assertTrue(html.contains("lvl-error"));
        assertTrue(html.contains("badge-start"));
        assertTrue(ctx.hasErrors());
        assertEquals(2, html.split("<details", -1).length - 1);
    }

    @Test
    void cumulativeMergeKeepsPreviousBody() {
        ImpIpgLoadLogContext first = new ImpIpgLoadLogContext(1);
        first.append(ImpIpgLoadLogLevel.INFO, ImpIpgLoadLogScope.LOAD, "X", "первая операция");
        String html1 = first.buildHtmlLog();

        ImpIpgLoadLogContext second = new ImpIpgLoadLogContext(1);
        second.append(ImpIpgLoadLogLevel.SUCCESS, ImpIpgLoadLogScope.LOAD, "Y", "вторая операция");
        String merged = second.buildHtmlLog(html1);

        assertTrue(merged.contains("первая операция"));
        assertTrue(merged.contains("вторая операция"));
        assertEquals(1, merged.split("<style>", -1).length - 1);
        assertEquals(1, merged.split("class=\"femsq-auditlog\"", -1).length - 1);
    }

    @Test
    void unknownPreviousHtmlIsIgnored() {
        ImpIpgLoadLogContext ctx = new ImpIpgLoadLogContext(1);
        ctx.append(ImpIpgLoadLogLevel.INFO, ImpIpgLoadLogScope.LOAD, "X", "новое");

        String html = ctx.buildHtmlLog("<p>legacy</p>");

        assertFalse(html.contains("legacy"));
        assertTrue(html.contains("новое"));
    }

    @Test
    void escapesHtmlSpecialChars() {
        assertEquals("a &lt;b&gt; &amp; c", ImpIpgLoadLogContext.esc("a <b> & c"));
    }
}
