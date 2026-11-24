package com.femsq.web.ipg.excel;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.model.ImpIpgStagingDraft;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIf;

/**
 * Unit-тесты парсера годовой ИП (§3.1.6.2).
 */
class IpgAnnualExcelParserTest {

    private final IpgAnnualExcelParser parser = new IpgAnnualExcelParser();

    @Test
    void parseRows_buildsSectionTreeAndLeaves() {
        List<String[]> rows = new ArrayList<>();
        rows.add(new String[] {"", "", "", "", "", "", "", ""});
        rows.add(new String[] {"№", "Код", "Наименование", "Всего", "СМР", "Оборудование", "Прочие", ""});
        rows.add(new String[] {"", "План капитального строительства", "", "100", "", "", "", ""});
        rows.add(new String[] {"", "1. Приоритетные проекты", "", "90", "", "", "", ""});
        rows.add(new String[] {"", "1.1. Проекты развития", "", "80", "", "", "", ""});
        rows.add(new String[] {"", "1.1.1. Обустройство Чаяндинского м/р", "", "50", "", "", "", ""});
        rows.add(new String[] {"1", "051-2000860", "Обустройство Чаяндинского НГКМ", "10", "7", "2", "1", "скв."});
        rows.add(new String[] {"2", "023-3000860", "Бурение", "5", "5", "", "", ""});
        rows.add(new String[] {"", "1.1.2. Ковыкта", "", "30", "", "", "", ""});
        rows.add(new String[] {"3", "051-2000714", "Обустройство Ковыктинского", "30", "20", "5", "5", ""});

        List<ImpIpgStagingDraft> drafts = parser.parseRows("Приложение № 1", rows);
        long sections = drafts.stream().filter(d -> "S".equals(d.rowKind())).count();
        long leaves = drafts.stream().filter(d -> "L".equals(d.rowKind())).count();
        assertEquals(5, sections);
        assertEquals(3, leaves);

        ImpIpgStagingDraft root = drafts.get(0);
        assertEquals("S", root.rowKind());
        assertEquals(null, root.parentIndex());
        assertTrue(root.ctx().contains("\"title\":\"План капитального строительства\""));

        ImpIpgStagingDraft leaf = drafts.get(4);
        assertEquals("L", leaf.rowKind());
        assertEquals(Integer.valueOf(3), leaf.parentIndex());
        assertTrue(leaf.ctx().contains("\"cstAgPn\":\"051-2000860\""));
        assertTrue(leaf.ctx().contains("\"path\":["));
        assertFalse(leaf.ctx().contains("\\u0000"));
    }

    @Test
    void parseRows_sectionInColumnA_sqlIiiStyle() {
        List<String[]> rows = new ArrayList<>();
        rows.add(new String[] {"№", "Код", "Наименование", "", "", "", "", ""});
        rows.add(new String[] {"План капитального строительства", "", "", "", "", "", "", ""});
        rows.add(new String[] {"1. Приоритетные проекты", "", "", "", "", "", "", ""});
        rows.add(new String[] {"1", "051-2000860", "Обустройство", "1", "", "", "", ""});
        rows.add(new String[] {"334", "СИНЕРГИЯ-2005291", "Офисы", "2", "", "", "", ""});

        List<ImpIpgStagingDraft> drafts = parser.parseRows("Приложение № 1", rows);
        assertEquals(2, drafts.stream().filter(d -> "S".equals(d.rowKind())).count());
        assertEquals(2, drafts.stream().filter(d -> "L".equals(d.rowKind())).count());
        assertTrue(drafts.get(3).ctx().contains("СИНЕРГИЯ-2005291"));
    }

    /**
     * Ненумерованные «АСУ ТП»/«КИИ» не должны сбрасывать стек: иначе «2.7. Метрология»
     * получает path {@code [КИИ, Метрология]} вместо пути под программой.
     */
    @Test
    void parseRows_unnumberedNestedDoesNotResetStack() {
        List<String[]> rows = new ArrayList<>();
        rows.add(new String[] {"№", "Код", "Наименование", "", "", "", "", ""});
        rows.add(new String[] {"", "План капитального строительства", "", "", "", "", "", ""});
        rows.add(new String[] {"", "2. Проекты комплексных программ", "", "", "", "", "", ""});
        rows.add(new String[] {"", "2.6. АСУ ТП", "", "", "", "", "", ""});
        rows.add(new String[] {"", "АСУ ТП", "", "", "", "", "", ""});
        rows.add(new String[] {"1", "051-2000001", "Лист под АСУ", "1", "", "", "", ""});
        rows.add(new String[] {"", "КИИ", "", "", "", "", "", ""});
        rows.add(new String[] {"2", "051-2000002", "Лист под КИИ", "1", "", "", "", ""});
        rows.add(new String[] {"", "2.7. Метрология", "", "", "", "", "", ""});
        rows.add(new String[] {"3", "051-2000003", "Лист метрология", "1", "", "", "", ""});
        rows.add(new String[] {"", "План долгосрочных финансовых вложений", "", "", "", "", "", ""});
        rows.add(new String[] {"", "Приоритетные проекты плана долгосрочных финансовых вложений", "", "", "", "", "", ""});

        List<ImpIpgStagingDraft> drafts = parser.parseRows("приложение 2", rows);
        ImpIpgStagingDraft asuPlain = drafts.stream()
                .filter(d -> "S".equals(d.rowKind()) && "АСУ ТП".equals(d.text()))
                .findFirst()
                .orElseThrow();
        ImpIpgStagingDraft kii = drafts.stream()
                .filter(d -> "S".equals(d.rowKind()) && "КИИ".equals(d.text()))
                .findFirst()
                .orElseThrow();
        ImpIpgStagingDraft metro = drafts.stream()
                .filter(d -> "S".equals(d.rowKind()) && d.text().startsWith("2.7."))
                .findFirst()
                .orElseThrow();
        ImpIpgStagingDraft dfv = drafts.stream()
                .filter(d -> "S".equals(d.rowKind()) && d.text().startsWith("План долгосрочных"))
                .findFirst()
                .orElseThrow();
        ImpIpgStagingDraft dfvPrio = drafts.stream()
                .filter(d -> "S".equals(d.rowKind()) && d.text().startsWith("Приоритетные проекты плана"))
                .findFirst()
                .orElseThrow();

        assertEquals(Integer.valueOf(2), asuPlain.parentIndex()); // under 2.6
        assertEquals(Integer.valueOf(2), kii.parentIndex()); // sibling under 2.6
        assertEquals(Integer.valueOf(1), metro.parentIndex()); // under «2. Проекты…», not КИИ
        assertTrue(metro.ctx().contains("\"path\":[\"План капитального строительства\",\"Проекты комплексных программ\",\"Метрология\"]"));
        assertFalse(metro.ctx().contains("КИИ"));
        assertEquals(null, dfv.parentIndex());
        assertEquals(Integer.valueOf(drafts.indexOf(dfv)), dfvPrio.parentIndex());
    }

    @Test
    @EnabledIf("sampleSql0Exists")
    void parse_sql0_sampleFile() {
        Path path = Path.of("/mnt/nb-win-share/femsq/excel/2026-1120/ipg-sql-load/sql_0.xlsx");
        IpgAnnualExcelParser.ParseOutcome outcome = parser.parse(path);
        assertEquals(39, outcome.sectionCount());
        assertEquals(398, outcome.leafCount());
        assertTrue(outcome.sheetName().toLowerCase().contains("приложен"));
    }

    @Test
    @EnabledIf("sampleSqlIiiExists")
    void parse_sqlIii_sampleFile_withFormulaRowNumbers() {
        Path path = Path.of("/mnt/nb-win-share/femsq/excel/2026-1120/ipg-sql-load/sql_iii.xlsx");
        IpgAnnualExcelParser.ParseOutcome outcome = parser.parse(path);
        assertEquals(54, outcome.sectionCount());
        assertEquals(663, outcome.leafCount());
    }

    static boolean sampleSql0Exists() {
        return Files.isRegularFile(Path.of("/mnt/nb-win-share/femsq/excel/2026-1120/ipg-sql-load/sql_0.xlsx"));
    }

    static boolean sampleSqlIiiExists() {
        return Files.isRegularFile(Path.of("/mnt/nb-win-share/femsq/excel/2026-1120/ipg-sql-load/sql_iii.xlsx"));
    }
}
