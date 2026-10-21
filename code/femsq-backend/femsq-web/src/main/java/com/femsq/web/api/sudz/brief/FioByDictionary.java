package com.femsq.web.api.sudz.brief;

import java.util.Collection;
import java.util.HashSet;
import java.util.Locale;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Порт VBA {@code FioByDictionary}: ФИО → «Фамилия И.О.» по словарю имён/отчеств.
 * В продукте тексты «Отказ:/Ошибка:» в ячейку не пишутся — вызывающий оставляет исходный C.
 * Дополнительно к ровно трём словам: повтор ФИО в ячейке отбрасывается, префикс ИП/КФХ сохраняется,
 * «Фамилия Имя» без отчества даёт «Фамилия И.».
 */
public final class FioByDictionary {

    private static final Locale RU = Locale.forLanguageTag("ru");
    private static final Pattern CYRILLIC_WORD = Pattern.compile("[А-ЯЁа-яё-]+");
    /**
     * Уже готовые инициалы и повтор той же фамилии (часто обрезанный хвост).
     */
    private static final Pattern LEADING_INITIALS_REPEAT = Pattern.compile(
            "^([А-ЯЁа-яё-]+)\\s+([А-ЯЁа-яё])\\.\\s*([А-ЯЁа-яё])\\.\\s+\\1(?:\\s.*)?$",
            Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE);

    /** Исходный текст оставлен: не ровно 3 слова и нет вложенного ФИО. */
    public enum SkipReason {
        /** Преобразовано. */
        NONE,
        /** Пустой вход. */
        EMPTY,
        /** Число токенов не даёт ФИО из словаря. */
        WORD_COUNT,
        /** Три слова, но имя/отчество не в словаре. */
        DICT
    }

    /**
     * Результат одного вызова.
     *
     * @param text текст для ячейки C (инициалы или исходный)
     * @param transformed true, если применены инициалы
     * @param skip причина пропуска
     */
    public record Result(String text, boolean transformed, SkipReason skip) {
    }

    private final Set<String> words;

    /**
     * @param dictionaryWords слова из {@code ags.v_fioDictWord}
     * @throws IllegalArgumentException если словарь пуст
     */
    public FioByDictionary(Collection<String> dictionaryWords) {
        Set<String> collected = new HashSet<>();
        if (dictionaryWords != null) {
            for (String raw : dictionaryWords) {
                if (raw == null) {
                    continue;
                }
                String t = raw.trim();
                if (!t.isEmpty()) {
                    collected.add(t.toLowerCase(RU));
                }
            }
        }
        if (collected.isEmpty()) {
            throw new IllegalArgumentException("Ошибка: Словарь пуст");
        }
        this.words = Set.copyOf(collected);
    }

    /**
     * Преобразует контрагента по правилам §6.6 / VBA fio и правилам повтора / ИП / двух слов.
     *
     * @param txt исходный текст колонки C
     * @return результат (без строк «Отказ:»)
     */
    public Result apply(String txt) {
        if (txt == null) {
            return new Result("", false, SkipReason.EMPTY);
        }
        String clean = txt.trim();
        if (clean.isEmpty()) {
            return new Result(clean, false, SkipReason.EMPTY);
        }
        String[] parts = clean.split("\\s+");
        if (parts.length == 3 && inDict(parts[1]) && inDict(parts[2]) && isSurname(parts[0])) {
            return new Result(initials(parts[0], parts[1], parts[2]), true, SkipReason.NONE);
        }
        Matcher leading = LEADING_INITIALS_REPEAT.matcher(clean);
        if (leading.matches()) {
            String text = leading.group(1) + " "
                    + Character.toUpperCase(leading.group(2).charAt(0)) + "."
                    + Character.toUpperCase(leading.group(3).charAt(0)) + ".";
            return new Result(text, true, SkipReason.NONE);
        }
        String embedded = embeddedFio(parts);
        if (embedded != null) {
            return new Result(embedded, true, SkipReason.NONE);
        }
        if (parts.length == 2 && isSurname(parts[0]) && inDict(parts[1])) {
            return new Result(oneInitial(parts[0], parts[1]), true, SkipReason.NONE);
        }
        if (parts.length != 3) {
            return new Result(clean, false, SkipReason.WORD_COUNT);
        }
        return new Result(clean, false, SkipReason.DICT);
    }

    /**
     * Первое «фамилия + имя + отчество» в токенах: в конце строки (префикс ИП/КФХ сохраняется)
     * или с повтором той же фамилии сразу после (хвост отбрасывается).
     *
     * @param parts токены ячейки
     * @return текст с инициалами или null
     */
    private String embeddedFio(String[] parts) {
        for (int i = 0; i <= parts.length - 3; i++) {
            if (!isSurname(parts[i])) {
                continue;
            }
            if (!inDictLoose(parts[i + 1]) || !inDictLoose(parts[i + 2])) {
                continue;
            }
            boolean atEnd = i + 3 == parts.length;
            boolean repeatedSurname = i + 3 < parts.length && repeatedSurname(parts[i], parts[i + 3]);
            if (!atEnd && !repeatedSurname) {
                continue;
            }
            String fio = initials(parts[i], parts[i + 1], parts[i + 2]);
            if (i == 0) {
                return fio;
            }
            StringBuilder prefix = new StringBuilder();
            for (int p = 0; p < i; p++) {
                if (p > 0) {
                    prefix.append(' ');
                }
                prefix.append(parts[p]);
            }
            return prefix + " " + fio;
        }
        return null;
    }

    private boolean inDict(String token) {
        return words.contains(token.toLowerCase(RU));
    }

    /**
     * Точное слово или родительный падеж словарного имени/отчества («Иванович» → «Ивановича», «Анатолий» → «Анатолия»).
     *
     * @param token токен ячейки
     * @return true, если слово узнаётся словарём
     */
    private boolean inDictLoose(String token) {
        if (inDict(token)) {
            return true;
        }
        String t = token.toLowerCase(RU);
        if (t.length() < 5) {
            return false;
        }
        for (String word : words) {
            if (word.length() < 4) {
                continue;
            }
            if (t.startsWith(word)) {
                String rest = t.substring(word.length());
                if (rest.equals("а") || rest.equals("я") || rest.equals("у") || rest.equals("ю")) {
                    return true;
                }
            }
            if (word.endsWith("й") && t.equals(word.substring(0, word.length() - 1) + "я")) {
                return true;
            }
        }
        return false;
    }

    private static boolean isSurname(String token) {
        if (!CYRILLIC_WORD.matcher(token).matches()) {
            return false;
        }
        String upper = token.toUpperCase(RU);
        return !upper.equals("ИП")
                && !upper.equals("ООО")
                && !upper.equals("ОАО")
                && !upper.equals("ПАО")
                && !upper.equals("ЗАО")
                && !upper.equals("АО")
                && !upper.equals("КФХ")
                && !upper.equals("ГЛАВА")
                && !upper.equals("ХОЗЯЙСТВО")
                && !upper.equals("КРЕСТЬЯНСКОЕ");
    }

    /**
     * Повтор фамилии: то же слово или обрезка («Николаева» / «Николаев»).
     *
     * @param surname фамилия первого ФИО
     * @param next следующий токен
     * @return true, если это та же фамилия
     */
    private static boolean repeatedSurname(String surname, String next) {
        if (surname.equalsIgnoreCase(next)) {
            return true;
        }
        String left = surname.toLowerCase(RU);
        String right = next.toLowerCase(RU);
        String shorter = left.length() <= right.length() ? left : right;
        String longer = left.length() <= right.length() ? right : left;
        return shorter.length() >= 5 && longer.startsWith(shorter);
    }

    private static String initials(String surname, String name, String patronymic) {
        return surname + " " + initialLetter(name) + "." + initialLetter(patronymic) + ".";
    }

    private static String oneInitial(String surname, String name) {
        return surname + " " + initialLetter(name) + ".";
    }

    private static char initialLetter(String word) {
        return Character.toUpperCase(word.charAt(0));
    }
}
