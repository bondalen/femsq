package com.femsq.web.ipg.excel;

import com.femsq.database.model.ImpIpgStagingDraft;
import java.io.IOException;
import java.io.InputStream;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.apache.poi.openxml4j.util.ZipSecureFile;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.ss.usermodel.DataFormatter;
import org.apache.poi.ss.usermodel.FormulaEvaluator;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.springframework.stereotype.Component;

/**
 * Парсер основного листа приложения годовой ИП → черновики {@code ags.impIpg} (C2 §3.1.6.2).
 * Лист {@code sql} не используется; разделы = {@code S}, стройки = {@code L}.
 */
@Component
public class IpgAnnualExcelParser {

    private static final Pattern CST_AG_PN = Pattern.compile(
            "^(?:\\d{3}|[A-Za-zА-Яа-яЁё][\\wА-Яа-яЁё]*)-\\d{7}$",
            Pattern.UNICODE_CHARACTER_CLASS);
    private static final Pattern SECTION_NUM = Pattern.compile("^(\\d+(?:\\.\\d+)*)\\.?\\s+(.*)$");
    private static final Pattern PLAIN_NUM = Pattern.compile("^\\d+$");
    private static final Pattern SKIP_SHEET = Pattern.compile(
            "(?i)sql|контроль|group|лист\\s*\\d|расч");
    private static final Pattern PREFER_SHEET = Pattern.compile("(?i)приложен|план\\s*кс|приложение");

    private final DataFormatter formatter = new DataFormatter(Locale.ROOT);

    /**
     * Разбор файла Excel по пути.
     *
     * @param filePath путь к .xlsx
     * @return результат с листом и черновиками
     */
    public ParseOutcome parse(Path filePath) {
        Objects.requireNonNull(filePath, "filePath");
        if (!Files.isRegularFile(filePath)) {
            throw new IpgAnnualExcelException("Файл Excel не найден: " + filePath);
        }
        double previousRatio = ZipSecureFile.getMinInflateRatio();
        ZipSecureFile.setMinInflateRatio(0.0);
        try (InputStream inputStream = Files.newInputStream(filePath);
             Workbook workbook = WorkbookFactory.create(inputStream)) {
            return parseWorkbook(workbook);
        } catch (IpgAnnualExcelException exception) {
            throw exception;
        } catch (IOException exception) {
            throw new IpgAnnualExcelException("Не удалось прочитать Excel: " + filePath, exception);
        } catch (Exception exception) {
            throw new IpgAnnualExcelException(
                    "Ошибка разбора Excel: " + filePath + " — " + exception.getMessage(), exception);
        } finally {
            ZipSecureFile.setMinInflateRatio(previousRatio);
        }
    }

    /**
     * Разбор уже открытой книги (для тестов).
     */
    ParseOutcome parseWorkbook(Workbook workbook) {
        Sheet sheet = selectSheet(workbook);
        List<String[]> rows = readSheetRows(sheet);
        List<ImpIpgStagingDraft> drafts = parseRows(sheet.getSheetName(), rows);
        int sections = 0;
        int leaves = 0;
        for (ImpIpgStagingDraft draft : drafts) {
            if ("S".equals(draft.rowKind())) {
                sections++;
            } else if ("L".equals(draft.rowKind())) {
                leaves++;
            }
        }
        if (sections == 0) {
            throw new IpgAnnualExcelException(
                    "На листе «" + sheet.getSheetName() + "» не найдено разделов (ПТСФ)");
        }
        return new ParseOutcome(sheet.getSheetName(), drafts, sections, leaves);
    }

    /**
     * Разбор плоских строк A..H (для unit-тестов без POI-файла).
     */
    List<ImpIpgStagingDraft> parseRows(String sheetName, List<String[]> rows) {
        List<ImpIpgStagingDraft> out = new ArrayList<>();
        Deque<StackFrame> stack = new ArrayDeque<>();
        boolean started = false;

        for (int i = 0; i < rows.size(); i++) {
            String[] cols = rows.get(i);
            int excelRow = i + 1;
            String a = clean(cell(cols, 0));
            String b = clean(cell(cols, 1));
            String c = clean(cell(cols, 2));
            String d = clean(cell(cols, 3));
            String e = clean(cell(cols, 4));
            String f = clean(cell(cols, 5));
            String g = clean(cell(cols, 6));
            String h = clean(cell(cols, 7));

            if (!started) {
                if (isHeader(a, b, c)) {
                    started = true;
                }
                continue;
            }
            if (a.isEmpty() && b.isEmpty() && c.isEmpty()) {
                continue;
            }

            if (isLeaf(a, b)) {
                Integer parentIdx = stack.isEmpty() ? null : stack.peekLast().index();
                List<String> path = pathTitles(stack, out);
                String ctx = buildLeafCtx(sheetName, excelRow, path, b, a.isEmpty() ? null : a, c, d, e, f, g, h);
                out.add(new ImpIpgStagingDraft(excelRow, "L", c.isEmpty() ? b : c, parentIdx, ctx));
                continue;
            }

            String secText = resolveSectionText(a, b, c);
            if (secText == null) {
                continue;
            }
            SectionParts parts = splitSection(secText);
            if (parts.title().isEmpty()) {
                continue;
            }
            boolean numbered = parts.depth() > 0;
            int depth = resolveSectionDepth(parts, stack);
            while (!stack.isEmpty() && stack.peekLast().depth() >= depth) {
                stack.removeLast();
            }
            Integer parentIdx = stack.isEmpty() ? null : stack.peekLast().index();
            List<String> path = pathTitles(stack, out);
            path.add(parts.title());
            int index = out.size();
            String ctx = buildSectionCtx(sheetName, excelRow, path, parts.secNum(), parts.title(), d, e, f, g, h);
            out.add(new ImpIpgStagingDraft(excelRow, "S", secText, parentIdx, ctx));
            stack.addLast(new StackFrame(depth, index, numbered || depth == 0 && isTopLevelUnnumberedTitle(parts.title())));
        }
        return List.copyOf(out);
    }

    /**
     * Глубина узла для стека родителей.
     * <p>
     * Ненумерованные заголовки раньше всегда давали {@code depth=0} и {@code stack.clear()} —
     * из‑за этого вложенные «АСУ ТП»/«КИИ» становились корнем и ломали path у следующих
     * «2.7. Метрология»… (баг пилота §3.1.7.2). Теперь:
     * <ul>
     *   <li>нумерованные — по числу сегментов {@code 1.2.3};</li>
     *   <li>ненумерованный «корневой» блок ({@code План …}) или пустой стек — depth 0;</li>
     *   <li>прочий ненумерованный: ребёнок нумерованного верха ({@code depth+1}) либо
     *       сиблинг другого ненумерованного (тот же depth → while снимает соседа).</li>
     * </ul>
     */
    private static int resolveSectionDepth(SectionParts parts, Deque<StackFrame> stack) {
        if (parts.depth() > 0) {
            return parts.depth();
        }
        if (stack.isEmpty() || isTopLevelUnnumberedTitle(parts.title())) {
            return 0;
        }
        StackFrame top = stack.peekLast();
        if (top.structural()) {
            return top.depth() + 1;
        }
        return top.depth();
    }

    /**
     * Крупные блоки приложения без номера (не вложенные подпункты вроде «КИИ»).
     */
    private static boolean isTopLevelUnnumberedTitle(String title) {
        if (title == null || title.isBlank()) {
            return false;
        }
        String low = title.trim().toLowerCase(Locale.ROOT);
        return low.startsWith("план ")
                || low.startsWith("приложение")
                || low.equals("вся инвестпрограмма");
    }

    private Sheet selectSheet(Workbook workbook) {
        Sheet preferred = null;
        Sheet fallback = null;
        for (int i = 0; i < workbook.getNumberOfSheets(); i++) {
            Sheet sheet = workbook.getSheetAt(i);
            String name = sheet.getSheetName() == null ? "" : sheet.getSheetName();
            if (SKIP_SHEET.matcher(name).find()) {
                continue;
            }
            if (preferred == null && PREFER_SHEET.matcher(name).find()) {
                preferred = sheet;
            }
            if (fallback == null) {
                fallback = sheet;
            }
        }
        Sheet chosen = preferred != null ? preferred : fallback;
        if (chosen == null) {
            throw new IpgAnnualExcelException("В книге нет подходящего листа приложения");
        }
        return chosen;
    }

    private List<String[]> readSheetRows(Sheet sheet) {
        Workbook workbook = sheet.getWorkbook();
        FormulaEvaluator evaluator = workbook.getCreationHelper().createFormulaEvaluator();
        List<String[]> rows = new ArrayList<>();
        int last = sheet.getLastRowNum();
        for (int r = 0; r <= last; r++) {
            Row row = sheet.getRow(r);
            String[] cols = new String[8];
            for (int c = 0; c < 8; c++) {
                cols[c] = row == null ? "" : formatCell(row.getCell(c), evaluator);
            }
            rows.add(cols);
        }
        return rows;
    }

    private String formatCell(Cell cell, FormulaEvaluator evaluator) {
        if (cell == null) {
            return "";
        }
        CellType type = cell.getCellType();
        if (type == CellType.FORMULA) {
            type = cell.getCachedFormulaResultType();
        }
        if (type == CellType.NUMERIC) {
            double value = cell.getNumericCellValue();
            if (value == Math.rint(value) && Math.abs(value) < 1_000_000_000d) {
                return Long.toString((long) value);
            }
            return BigDecimal.valueOf(value).stripTrailingZeros().toPlainString();
        }
        return formatter.formatCellValue(cell, evaluator);
    }

    private static boolean isHeader(String a, String b, String c) {
        String al = a.toLowerCase(Locale.ROOT);
        String bl = b.toLowerCase(Locale.ROOT);
        String cl = c.toLowerCase(Locale.ROOT);
        return (al.equals("№") || al.equals("n") || al.equals("#") || al.equals("num") || al.equals("nnn"))
                && (bl.contains("код") || cl.contains("наимен") || bl.equalsIgnoreCase("cstAgPn"));
    }

    private static boolean isLeaf(String a, String b) {
        if (!CST_AG_PN.matcher(b).matches()) {
            return false;
        }
        return a.isEmpty() || PLAIN_NUM.matcher(a).matches();
    }

    private static String resolveSectionText(String a, String b, String c) {
        if (!a.isEmpty() && !PLAIN_NUM.matcher(a).matches() && !CST_AG_PN.matcher(a).matches()
                && (b.isEmpty() || !CST_AG_PN.matcher(b).matches())) {
            if (isSkippedSection(a)) {
                return null;
            }
            return a;
        }
        if (a.isEmpty() && !b.isEmpty() && !CST_AG_PN.matcher(b).matches()
                && (c.isEmpty() || (!CST_AG_PN.matcher(c).matches() && !PLAIN_NUM.matcher(c).matches()))) {
            if (isSkippedSection(b)) {
                return null;
            }
            return b;
        }
        return null;
    }

    private static boolean isSkippedSection(String text) {
        String low = text.toLowerCase(Locale.ROOT);
        return low.equals("всего ип")
                || low.startsWith("в том числе")
                || low.startsWith("лимиты")
                || low.contains("проект плана")
                || low.contains("проект уточнения")
                || low.startsWith("млн ");
    }

    private static SectionParts splitSection(String text) {
        Matcher matcher = SECTION_NUM.matcher(text);
        if (matcher.matches()) {
            String num = matcher.group(1);
            String title = clean(matcher.group(2));
            int depth = num.isEmpty() ? 0 : num.split("\\.").length;
            return new SectionParts(num, title, depth);
        }
        return new SectionParts(null, text, 0);
    }

    private static List<String> pathTitles(Deque<StackFrame> stack, List<ImpIpgStagingDraft> out) {
        List<String> path = new ArrayList<>();
        for (StackFrame frame : stack) {
            ImpIpgStagingDraft draft = out.get(frame.index());
            path.add(splitSection(draft.text()).title());
        }
        return path;
    }

    private static String buildSectionCtx(
            String sheet,
            int excelRow,
            List<String> path,
            String secNum,
            String title,
            String ttl,
            String work,
            String equip,
            String others,
            String commissioning) {
        StringBuilder json = new StringBuilder(256);
        json.append('{');
        appendString(json, "sheet", sheet, false);
        appendInt(json, "excelRow", excelRow, true);
        appendStringArray(json, "path", path, true);
        appendString(json, "title", title, true);
        if (secNum != null) {
            appendString(json, "secNum", secNum, true);
        }
        appendOptionalNumber(json, "ttl", ttl);
        appendOptionalNumber(json, "work", work);
        appendOptionalNumber(json, "equip", equip);
        appendOptionalNumber(json, "others", others);
        if (!commissioning.isEmpty()) {
            appendString(json, "commissioning", commissioning, true);
        }
        json.append('}');
        return json.toString();
    }

    private static String buildLeafCtx(
            String sheet,
            int excelRow,
            List<String> path,
            String cstAgPn,
            String nnn,
            String name,
            String ttl,
            String work,
            String equip,
            String others,
            String commissioning) {
        StringBuilder json = new StringBuilder(256);
        json.append('{');
        appendString(json, "sheet", sheet, false);
        appendInt(json, "excelRow", excelRow, true);
        appendStringArray(json, "path", path, true);
        appendString(json, "cstAgPn", cstAgPn, true);
        if (nnn != null) {
            appendString(json, "nnn", nnn, true);
        }
        if (!name.isEmpty()) {
            appendString(json, "name", name, true);
        }
        appendOptionalNumber(json, "ttl", ttl);
        appendOptionalNumber(json, "work", work);
        appendOptionalNumber(json, "equip", equip);
        appendOptionalNumber(json, "others", others);
        if (!commissioning.isEmpty()) {
            appendString(json, "commissioning", commissioning, true);
        }
        json.append('}');
        return json.toString();
    }

    private static void appendOptionalNumber(StringBuilder json, String key, String raw) {
        if (raw == null || raw.isBlank()) {
            return;
        }
        String normalized = raw.replace(',', '.').replace(" ", "").replace("\u00a0", "");
        try {
            new BigDecimal(normalized);
            json.append(',').append('"').append(key).append('"').append(':').append(normalized);
        } catch (NumberFormatException ignored) {
            appendString(json, key, raw, true);
        }
    }

    private static void appendString(StringBuilder json, String key, String value, boolean comma) {
        if (comma) {
            json.append(',');
        }
        json.append('"').append(key).append('"').append(':');
        json.append('"').append(escapeJson(value)).append('"');
    }

    private static void appendInt(StringBuilder json, String key, int value, boolean comma) {
        if (comma) {
            json.append(',');
        }
        json.append('"').append(key).append('"').append(':').append(value);
    }

    private static void appendStringArray(StringBuilder json, String key, List<String> values, boolean comma) {
        if (comma) {
            json.append(',');
        }
        json.append('"').append(key).append('"').append(':').append('[');
        for (int i = 0; i < values.size(); i++) {
            if (i > 0) {
                json.append(',');
            }
            json.append('"').append(escapeJson(values.get(i))).append('"');
        }
        json.append(']');
    }

    private static String escapeJson(String value) {
        if (value == null) {
            return "";
        }
        StringBuilder out = new StringBuilder(value.length() + 8);
        for (int i = 0; i < value.length(); i++) {
            char ch = value.charAt(i);
            switch (ch) {
                case '\\' -> out.append("\\\\");
                case '"' -> out.append("\\\"");
                case '\n' -> out.append("\\n");
                case '\r' -> out.append("\\r");
                case '\t' -> out.append("\\t");
                default -> {
                    if (ch < 0x20) {
                        out.append(String.format("\\u%04x", (int) ch));
                    } else {
                        out.append(ch);
                    }
                }
            }
        }
        return out.toString();
    }

    private static String cell(String[] cols, int index) {
        return index < cols.length && cols[index] != null ? cols[index] : "";
    }

    private static String clean(String value) {
        if (value == null || value.isEmpty()) {
            return "";
        }
        String normalized = value
                .replace('\u00a0', ' ')
                .replace('\u202f', ' ')
                .replace('\n', ' ')
                .replace('\r', ' ');
        return normalized.trim().replaceAll(" +", " ");
    }

    /**
     * Исход парсера.
     */
    public record ParseOutcome(
            String sheetName,
            List<ImpIpgStagingDraft> drafts,
            int sectionCount,
            int leafCount) {
    }

    /**
     * @param structural нумерованный или корневой «План …» — точка вложения для ненумерованных детей
     */
    private record StackFrame(int depth, int index, boolean structural) {
    }

    private record SectionParts(String secNum, String title, int depth) {
    }
}
