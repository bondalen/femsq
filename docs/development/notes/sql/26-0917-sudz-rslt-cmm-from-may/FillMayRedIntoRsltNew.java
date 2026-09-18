import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.ss.usermodel.DateUtil;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

/**
 * Копирует Rslt сбор и кладёт MAY красные (col 36/37/38) в *_new (cur_new / mery_new / cstAgPn_new).
 * Сопоставление как у FillMailGreen: QIV Overd&gt;0, ключ acc|normInv|ttlQIV, спецпары A45/86740/732.
 */
public class FillMayRedIntoRsltNew {
    static final int MAIL_CUR_NEW = 50;
    static final int MAIL_MERY_NEW = 51;
    static final int MAIL_CST_NEW = 52;

    static String nz(String s) {
        if (s == null) {
            return null;
        }
        s = s.replace('\u00A0', ' ').trim();
        return s.isEmpty() ? null : s;
    }

    static String str(Cell c) {
        if (c == null) {
            return null;
        }
        return switch (c.getCellType()) {
            case STRING -> nz(c.getStringCellValue());
            case NUMERIC -> {
                if (DateUtil.isCellDateFormatted(c)) {
                    yield c.getLocalDateTimeCellValue().toLocalDate().toString();
                }
                double d = c.getNumericCellValue();
                if (Math.rint(d) == d && Math.abs(d) < 1e15) {
                    yield Long.toString((long) d);
                }
                yield String.format(Locale.ROOT, "%.2f", d);
            }
            case FORMULA -> {
                try {
                    yield nz(c.getStringCellValue());
                } catch (Exception e) {
                    try {
                        yield String.format(Locale.ROOT, "%.2f", c.getNumericCellValue());
                    } catch (Exception e2) {
                        yield null;
                    }
                }
            }
            default -> null;
        };
    }

    static Double num(Cell c) {
        if (c == null) {
            return null;
        }
        return switch (c.getCellType()) {
            case NUMERIC -> c.getNumericCellValue();
            case FORMULA -> {
                try {
                    yield c.getNumericCellValue();
                } catch (Exception e) {
                    yield null;
                }
            }
            default -> null;
        };
    }

    static boolean overd(Double o) {
        return o != null && o > 1e-9;
    }

    static String nrm(String s) {
        return s == null ? "" : s.replace('\u00A0', ' ').trim().replaceAll("\\s+", " ");
    }

    static String normInv(String inv) {
        if (inv == null) {
            return "";
        }
        String s = inv.replace('\u00A0', ' ').trim();
        s = s.replaceAll("\\s*\\(номеров:\\s*\\d+\\)\\s*", "");
        s = s.replaceAll("\\s+от\\s+\\d{1,2}[./]\\d{1,2}[./]\\d{2,4}\\s*$", "");
        String u = s.trim().toUpperCase(Locale.ROOT);
        if (u.contains("10000086740") || u.equals("86740")) {
            return "86740";
        }
        if (u.startsWith("732")) {
            String f = u.split(",")[0].trim();
            if (f.equals("732") || f.startsWith("732 ")) {
                return "732";
            }
        }
        if (u.contains("А45-19974") || u.contains("A45-19974")) {
            return "А45-19974/2024";
        }
        return u;
    }

    static String soft(String acc, String inv, String ttl) {
        String ni = normInv(inv);
        String a = acc == null ? "" : acc.trim();
        if (ni.equals("А45-19974/2024")) {
            return a + "|" + ni + "|*";
        }
        return a + "|" + ni + "|" + (ttl == null ? "" : ttl);
    }

    static String first(String... v) {
        for (String x : v) {
            if (x != null) {
                return x;
            }
        }
        return null;
    }

    static void writeText(Row row, int col, String value) {
        if (value == null) {
            return;
        }
        Cell cell = row.getCell(col);
        if (cell == null) {
            cell = row.createCell(col, CellType.STRING);
        }
        cell.setCellValue(value);
    }

    static class MaySrc {
        int row;
        String soft;
        String cur;
        String mery;
        String cst;

        boolean anyRed() {
            return cur != null || mery != null || cst != null;
        }
    }

    public static void main(String[] args) throws Exception {
        Path mayPath = Path.of(args[0]);
        Path mailPath = Path.of(args[1]);
        Path outPath = Path.of(args[2]);
        Files.copy(mailPath, outPath, StandardCopyOption.REPLACE_EXISTING);

        Map<String, List<MaySrc>> mayBy = new HashMap<>();
        int mayQiv = 0;
        int mayWithRed = 0;
        try (FileInputStream in = new FileInputStream(mayPath.toFile());
                XSSFWorkbook mayWb = new XSSFWorkbook(in)) {
            Sheet may = mayWb.getSheetAt(0);
            for (int r = 3; r <= may.getLastRowNum(); r++) {
                Row row = may.getRow(r);
                if (row == null || !overd(num(row.getCell(11)))) {
                    continue;
                }
                mayQiv++;
                MaySrc x = new MaySrc();
                x.row = r + 1;
                String acc = str(row.getCell(1));
                String inv = first(str(row.getCell(2)), str(row.getCell(19)));
                x.soft = soft(acc, inv, str(row.getCell(10)));
                x.cur = str(row.getCell(36));
                x.mery = str(row.getCell(37));
                x.cst = str(row.getCell(38));
                if (x.anyRed()) {
                    mayWithRed++;
                }
                mayBy.computeIfAbsent(x.soft, k -> new ArrayList<>()).add(x);
            }
        }

        int mailQiv = 0;
        int paired = 0;
        int unpaired = 0;
        int wrote = 0;
        int curN = 0;
        int meryN = 0;
        int cstN = 0;
        try (FileInputStream in = new FileInputStream(outPath.toFile());
                XSSFWorkbook mailWb = new XSSFWorkbook(in)) {
            Sheet mail = mailWb.getSheetAt(0);
            for (int r = 3; r <= mail.getLastRowNum(); r++) {
                Row row = mail.getRow(r);
                if (row == null || !overd(num(row.getCell(11)))) {
                    continue;
                }
                mailQiv++;
                String acc = str(row.getCell(1));
                String inv = first(str(row.getCell(2)), str(row.getCell(16)), str(row.getCell(31)));
                String key = soft(acc, inv, str(row.getCell(10)));
                List<MaySrc> hits = mayBy.getOrDefault(key, List.of());
                if (hits.isEmpty()) {
                    unpaired++;
                    continue;
                }
                paired++;
                MaySrc s = hits.get(0);
                for (MaySrc h : hits) {
                    if (h.anyRed()) {
                        s = h;
                        break;
                    }
                }
                if (!s.anyRed()) {
                    continue;
                }
                if (s.cur != null) {
                    writeText(row, MAIL_CUR_NEW, s.cur);
                    curN++;
                }
                if (s.mery != null) {
                    writeText(row, MAIL_MERY_NEW, s.mery);
                    meryN++;
                }
                if (s.cst != null) {
                    writeText(row, MAIL_CST_NEW, s.cst);
                    cstN++;
                }
                wrote++;
            }
            try (FileOutputStream out = new FileOutputStream(outPath.toFile())) {
                mailWb.write(out);
            }
        }
        System.out.println("out=" + outPath);
        System.out.println("MAY QIV-overd=" + mayQiv + " withRed=" + mayWithRed);
        System.out.println("MAIL QIV-overd=" + mailQiv + " paired=" + paired + " unpaired=" + unpaired);
        System.out.println("wroteRows=" + wrote + " cur_new=" + curN + " mery_new=" + meryN + " cstAgPn_new=" + cstN);
    }
}
