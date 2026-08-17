package com.femsq.web.api.sudz;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/**
 * Кандидаты пути Excel: Проводник {@code D:\…} → WSL {@code /mnt/d/…}.
 */
class SudzDbtUplExcelPathResolverTest {

    @Test
    void stripsCopyAsPathQuotes() {
        assertEquals(
                "D:\\wire-guard-share-nb-win\\a.xlsx",
                SudzDbtUplExcelPathResolver.normalizeStored("  \"D:\\wire-guard-share-nb-win\\a.xlsx\"  ")
        );
    }

    @Test
    void windowsDriveBecomesWslMount() {
        String stored = "D:\\wire-guard-share-nb-win\\femsq\\excel\\a.xlsx";
        assertEquals(
                "/mnt/d/wire-guard-share-nb-win/femsq/excel/a.xlsx",
                SudzDbtUplExcelPathResolver.toWslMount(stored)
        );
        assertEquals(
                "/mnt/d/wire-guard-share-nb-win/femsq/excel/a.xlsx",
                SudzDbtUplExcelPathResolver.toWslMount("D:/wire-guard-share-nb-win/femsq/excel/a.xlsx")
        );
        List<Path> candidates = SudzDbtUplExcelPathResolver.candidates(stored);
        assertTrue(candidates.stream().anyMatch(p ->
                p.toString().equals("/mnt/d/wire-guard-share-nb-win/femsq/excel/a.xlsx")));
        assertTrue(candidates.stream().anyMatch(p ->
                p.toString().equals("/mnt/nb-win-share/femsq/excel/a.xlsx")));
    }

    @Test
    void posixPathStaysAsIs() {
        List<Path> candidates = SudzDbtUplExcelPathResolver.candidates(
                "/mnt/d/wire-guard-share-nb-win/femsq/excel/a.xlsx");
        assertEquals(1, candidates.size());
        assertEquals("/mnt/d/wire-guard-share-nb-win/femsq/excel/a.xlsx", candidates.get(0).toString());
    }

    @Test
    void resolveExistingFindsFile(@TempDir Path temp) throws Exception {
        Path file = temp.resolve("debit.xlsx");
        Files.writeString(file, "xlsx", StandardCharsets.UTF_8);
        assertEquals(
                file.toAbsolutePath().normalize(),
                SudzDbtUplExcelPathResolver.resolveExisting(file.toString()).orElseThrow()
        );
    }

    @Test
    void emptyPathHasNoCandidates() {
        assertTrue(SudzDbtUplExcelPathResolver.candidates("  ").isEmpty());
        assertTrue(SudzDbtUplExcelPathResolver.resolveExisting(null).isEmpty());
    }
}
