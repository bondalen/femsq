package com.femsq.web.audit.staging;

import java.util.Locale;
import java.util.Objects;
import java.util.Set;
import java.util.logging.Logger;
import java.util.regex.Pattern;
import java.util.regex.PatternSyntaxException;

/**
 * Классификация строки type=5 до INSERT: пустая vs отсев по признаку vs whitelist.
 * <p>
 * Пустые строки (пустой «Признак» и пустой «№ ОА») не считаются {@code UNKNOWN_SIGN}.
 * «ОА Аренда» отсекается только по признаку (отдельный агрегат в логе).
 * Нижняя граница диапазона (§9.3.7.2) — последняя строка, значимая для данных.
 * </p>
 */
public final class Type5SignFilterClassifier {

    private static final Logger log = Logger.getLogger(Type5SignFilterClassifier.class.getName());

    /** Нормализованное значение признака аренды. */
    public static final String ARENADA_SIGN_NORMALIZED = "оа аренда";

    /** Подпись в SUMMARY/топ для агрегата аренды. */
    public static final String ARENADA_SIGN_LABEL = "ОА Аренда";

    /** Подпись для непустой строки без читаемого признака. */
    public static final String UNKNOWN_SIGN_LABEL = "UNKNOWN_SIGN";

    /** Regex по умолчанию для маркера кода стройки в «№ ОА». */
    public static final String DEFAULT_RA_NUM_REGEX = "\\d{7}";

    private Type5SignFilterClassifier() {
    }

    /**
     * Результат классификации строки по признаку и номеру ОА.
     *
     * @param kind  исход решения
     * @param label подпись для счётчика фильтра ({@code null} для EMPTY/ACCEPTED)
     */
    public record Decision(Kind kind, String label) {
        /**
         * Создаёт решение классификации.
         */
        public Decision {
            Objects.requireNonNull(kind, "kind");
        }
    }

    /**
     * Исход классификации строки type=5 перед загрузкой в staging.
     */
    public enum Kind {
        /** Нет признака и нет № ОА — резерв/пустая строка. */
        EMPTY,
        /** Признак из whitelist — кандидат на INSERT. */
        ACCEPTED,
        /** Признак «ОА Аренда» — исключить (агрегат). */
        FILTERED_ARENDA,
        /** Прочий непустой/не whitelist признак. */
        FILTERED_OTHER
    }

    /**
     * Классифицирует строку по сырому признаку и № ОА.
     *
     * @param signRaw      значение колонки «Признак» ({@code rainSign})
     * @param raNumRaw     значение колонки «№ ОА» ({@code rainRaNum})
     * @param allowedSigns нормализованный whitelist (lowercase); не {@code null}
     * @return решение для счётчиков и ветвления цикла Stage 1
     */
    public static Decision classify(String signRaw, String raNumRaw, Set<String> allowedSigns) {
        Objects.requireNonNull(allowedSigns, "allowedSigns");
        String normalizedSign = normalizeSign(signRaw);
        String raNum = normalizeRaNum(raNumRaw);
        if (normalizedSign.isEmpty() && raNum.isEmpty()) {
            return new Decision(Kind.EMPTY, null);
        }
        if (allowedSigns.contains(normalizedSign)) {
            return new Decision(Kind.ACCEPTED, null);
        }
        if (ARENADA_SIGN_NORMALIZED.equals(normalizedSign)) {
            return new Decision(Kind.FILTERED_ARENDA, ARENADA_SIGN_LABEL);
        }
        String label = (signRaw == null || signRaw.trim().isEmpty())
                ? UNKNOWN_SIGN_LABEL
                : signRaw.trim();
        return new Decision(Kind.FILTERED_OTHER, label);
    }

    /**
     * Строка значима для нижней границы диапазона type=5:
     * whitelist, «ОА Аренда» или «№ ОА» содержит {@code raNumPattern}.
     *
     * @param signRaw      признак
     * @param raNumRaw     номер ОА
     * @param allowedSigns whitelist
     * @param raNumPattern скомпилированный regex (например {@code \d{7}})
     * @return {@code true}, если строка должна входить в обрабатываемый диапазон
     */
    public static boolean isSignificantForDataRange(
            String signRaw,
            String raNumRaw,
            Set<String> allowedSigns,
            Pattern raNumPattern
    ) {
        Objects.requireNonNull(allowedSigns, "allowedSigns");
        Objects.requireNonNull(raNumPattern, "raNumPattern");
        String normalizedSign = normalizeSign(signRaw);
        if (allowedSigns.contains(normalizedSign)) {
            return true;
        }
        if (ARENADA_SIGN_NORMALIZED.equals(normalizedSign)) {
            return true;
        }
        String raNum = normalizeRaNum(raNumRaw);
        return !raNum.isEmpty() && raNumPattern.matcher(raNum).find();
    }

    /**
     * Прочий отсев ({@link Kind#FILTERED_OTHER}) без маркера {@code raNumPattern} в «№ ОА» —
     * кандидат на поштучный WARN (§9.3.7.3).
     *
     * @param decision     результат {@link #classify}
     * @param raNumRaw     сырой № ОА
     * @param raNumPattern regex маркера (например {@code \d{7}})
     * @return {@code true}, если нужна детальная строка OTHER
     */
    public static boolean isOtherWithoutRaNumMarker(
            Decision decision,
            String raNumRaw,
            Pattern raNumPattern
    ) {
        if (decision == null || decision.kind() != Kind.FILTERED_OTHER) {
            return false;
        }
        Objects.requireNonNull(raNumPattern, "raNumPattern");
        String raNum = normalizeRaNum(raNumRaw);
        return raNum.isEmpty() || !raNumPattern.matcher(raNum).find();
    }

    /**
     * Компилирует regex для «№ ОА»; при ошибке — {@link #DEFAULT_RA_NUM_REGEX}.
     *
     * @param regex значение из настроек (может быть {@code null}/blank)
     * @return скомпилированный pattern
     */
    public static Pattern compileRaNumPattern(String regex) {
        String effective = (regex == null || regex.isBlank()) ? DEFAULT_RA_NUM_REGEX : regex.trim();
        try {
            return Pattern.compile(effective);
        } catch (PatternSyntaxException ex) {
            log.warning(() -> "[Type5SignFilter] invalid ra-num-regex '" + effective
                    + "', fallback to " + DEFAULT_RA_NUM_REGEX + ": " + ex.getMessage());
            return Pattern.compile(DEFAULT_RA_NUM_REGEX);
        }
    }

    /**
     * Нормализует признак для сравнения с whitelist (trim + lower case).
     *
     * @param value сырое значение из Excel
     * @return нормализованная строка или пустая
     */
    public static String normalizeSign(String value) {
        if (value == null) {
            return "";
        }
        return value.trim().toLowerCase(Locale.ROOT);
    }

    /**
     * Нормализует «№ ОА»: удаляет все пробельные символы (в т.ч. переводы строк в ячейке).
     *
     * @param value сырое значение из Excel
     * @return компактная строка или пустая
     */
    public static String normalizeRaNum(String value) {
        if (value == null) {
            return "";
        }
        return value.replaceAll("\\s+", "").trim();
    }
}
