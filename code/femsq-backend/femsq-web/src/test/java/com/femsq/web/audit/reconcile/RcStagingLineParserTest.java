package com.femsq.web.audit.reconcile;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

/**
 * Юнит-тесты {@link RcStagingLineParser} на строках, выгруженных из реальной БД (ОА изм, годы отчёта 2025–2026).
 */
class RcStagingLineParserTest {

    @ParameterizedTest(name = "{0}")
    @MethodSource("expectedSuccessCases")
    void parse_matchesProductionSamples(
            String label,
            String rainRaNum,
            int expectedChange,
            String expectedReportFragment,
            LocalDate expectedEarliestDate
    ) {
        var parsed = RcStagingLineParser.parse(rainRaNum);
        assertTrue(parsed.isPresent(), () -> "expected parse: " + label);
        assertEquals(expectedChange, parsed.get().changeNumber(), label);
        assertEquals(expectedReportFragment, parsed.get().reportNumber(), label);
        assertEquals(expectedEarliestDate, parsed.get().reportDate(), label);
    }

    static Stream<Arguments> expectedSuccessCases() {
        return Stream.of(
                Arguments.of(
                        "dot date typical",
                        "Изм. 1 в ТМ25-2005400-14 от 31.05.2025",
                        1,
                        "ТМ25-2005400-14",
                        LocalDate.of(2025, 5, 31)),
                Arguments.of(
                        "russian month genitive",
                        "Изм 1 к ОА № НП25-2001040-18 от 31 мая 2025 г.",
                        1,
                        "НП25-2001040-18",
                        LocalDate.of(2025, 5, 31)),
                Arguments.of(
                        "Изменение № 1 prefix",
                        "Изменение № 1 в ИР25-2000714-38 от 31.12.2025",
                        1,
                        "ИР25-2000714-38",
                        LocalDate.of(2025, 12, 31)),
                Arguments.of(
                        "2026 sample",
                        "Изм 1 в СЗ26-2002573-5 от 31.01.2026",
                        1,
                        "СЗ26-2002573-5",
                        LocalDate.of(2026, 1, 31)),
                Arguments.of(
                        "slash in report num",
                        "Изм 2 в СЗ25-2001311-23/2 от 31.12.2025",
                        2,
                        "СЗ25-2001311-23/2",
                        LocalDate.of(2025, 12, 31)),
                Arguments.of(
                        "all caps ИЗМ (ревизия 13 / exec 28)",
                        "ИЗМ 1 в ГР25-2003297-9 от 31.05.2025",
                        1,
                        "ГР25-2003297-9",
                        LocalDate.of(2025, 5, 31)));
    }

    @ParameterizedTest
    @MethodSource("expectedFailureCases")
    void parse_failsWithoutDateInLine(String rainRaNum) {
        assertFalse(RcStagingLineParser.parse(rainRaNum).isPresent());
    }

    static Stream<String> expectedFailureCases() {
        return Stream.of(
                /* 13 строк в БД за 2025–2026 без подстроки « от » — нет даты для RcStringRaDate */
                "Изм 1 в СЗ25-2004018-25");
    }

    /**
     * Регрессия по выборке уникальных {@code rainRaNum} из прод-запроса (см. {@code rc-parser/README.md}).
     */
    @Test
    void parse_allLinesInResourceFile_succeedOrDocumented() throws Exception {
        List<String> lines = readResourceLines("rc-parser/oizm_distinct_rainRaNum_2025-2026.txt");
        int ok = 0;
        int fail = 0;
        List<String> failures = new ArrayList<>();
        for (String line : lines) {
            if (line.isEmpty() || line.startsWith("#")) {
                continue;
            }
            if (RcStagingLineParser.parse(line).isPresent()) {
                ok++;
            } else {
                fail++;
                if (failures.size() < 25) {
                    failures.add(line);
                }
            }
        }
        assertTrue(ok > 0, "no successful parses from resource file");
        /* Доля без даты в тексте ожидаемо даёт неуспех; держим порог мягко — при деградации парсера тест упадёт. */
        final int okFinal = ok;
        final int failFinal = fail;
        double failRate = failFinal * 100.0 / (okFinal + failFinal);
        assertTrue(failRate <= 25.0, () -> String.format(
                "unexpected parse failure rate %.2f%% (ok=%d fail=%d). Samples: %s",
                failRate, okFinal, failFinal, failures));
    }

    private static List<String> readResourceLines(String classpath) throws Exception {
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(
                Objects.requireNonNull(
                        RcStagingLineParserTest.class.getClassLoader().getResourceAsStream(classpath),
                        "missing classpath resource: " + classpath),
                StandardCharsets.UTF_8))) {
            return reader.lines().toList();
        }
    }
}
