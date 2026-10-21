package com.femsq.web.api.sudz.brief;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * Порт VBA FioByDictionary: инициалы и пропуски.
 */
class FioByDictionaryTest {

    private final FioByDictionary fio = new FioByDictionary(List.of("Иван", "Иванович", "Мария", "Петровна"));

    @Test
    void transformsThreeWordsInDict() {
        FioByDictionary.Result r = fio.apply("Иванов Иван Иванович");
        assertTrue(r.transformed());
        assertEquals("Иванов И.И.", r.text());
        assertEquals(FioByDictionary.SkipReason.NONE, r.skip());
    }

    @Test
    void skipsWrongWordCount() {
        FioByDictionary.Result r = fio.apply("ООО Ромашка");
        assertFalse(r.transformed());
        assertEquals("ООО Ромашка", r.text());
        assertEquals(FioByDictionary.SkipReason.WORD_COUNT, r.skip());
    }

    @Test
    void skipsThreeWordsNotInDict() {
        FioByDictionary.Result r = fio.apply("Сидоров Пётр Сидорович");
        assertFalse(r.transformed());
        assertEquals("Сидоров Пётр Сидорович", r.text());
        assertEquals(FioByDictionary.SkipReason.DICT, r.skip());
    }

    @Test
    void emptyDictionaryRejected() {
        assertThrows(IllegalArgumentException.class, () -> new FioByDictionary(List.of()));
    }

    @Test
    void dropsRepeatedFioTail() {
        FioByDictionary dict = new FioByDictionary(List.of(
                "Сергей", "Николаевич", "Петр", "Викторович", "Нина", "Николаевна", "Людмила", "Павловна"));
        assertEquals("Лукин С.Н.", dict.apply("Лукин Сергей Николаевич Лукин Серге").text());
        assertEquals("Орлов П.В.", dict.apply("Орлов Петр Викторович Орлов Петр Ви").text());
        assertEquals("Дрягина Н.Н.", dict.apply("Дрягина Нина Николаевна Дрягина Нин").text());
        assertEquals("Николаева Л.П.", dict.apply("Николаева Людмила Павловна Николаев").text());
    }

    @Test
    void dropsTailAfterReadyInitials() {
        FioByDictionary dict = new FioByDictionary(List.of("Людмила", "Петр", "Михайлович"));
        assertEquals("Нальгиева Л.М.", dict.apply("Нальгиева Л.М. Нальгиева Людмила Му").text());
        assertEquals("МАГИН П.М.", dict.apply("МАГИН П.М. МАГИН ПЕТР МИХАЙЛОВИЧ ПЕ").text());
        assertEquals("Кадушкин А.А.", dict.apply("Кадушкин А.А. Кадушкин Александр Ал").text());
    }

    @Test
    void keepsOrgPrefixAndAbbreviatesPerson() {
        FioByDictionary dict = new FioByDictionary(List.of(
                "Владимир", "Николаевич", "Александрович", "Анатолий", "Иванович", "Александр"));
        assertEquals("ИП ВОЛКОВ В.Н.", dict.apply("ИП ВОЛКОВ ВЛАДИМИР НИКОЛАЕВИЧ").text());
        assertEquals(
                "ИП ГЛАВА К(Ф)Х ОБЪЕДКОВ В.А.",
                dict.apply("ИП ГЛАВА К(Ф)Х ОБЪЕДКОВ ВЛАДИМИР АЛЕКСАНДРОВИЧ").text());
        assertEquals(
                "КФХ КУЗЬМЕНКО А.И.",
                dict.apply("КФХ КУЗЬМЕНКО АНАТОЛИЯ ИВАНОВИЧА").text());
        assertEquals(
                "КРЕСТЬЯНСКОЕ ХОЗЯЙСТВО МАШНИНА А.А.",
                dict.apply("КРЕСТЬЯНСКОЕ ХОЗЯЙСТВО МАШНИНА АЛЕКСАНДРА АЛЕКСАНДРОВИЧА").text());
    }

    @Test
    void abbreviatesSurnameAndGivenName() {
        FioByDictionary dict = new FioByDictionary(List.of("Татьяна", "Норталап"));
        assertEquals("Кубышева Т.", dict.apply("Кубышева Татьяна").text());
        assertEquals("Куаткалиев Н.", dict.apply("Куаткалиев Норталап").text());
    }

    @Test
    void leavesLegalEntity() {
        assertEquals("ООО Ромашка", fio.apply("ООО Ромашка").text());
        assertEquals("АДМИНИСТРАЦИЯ НАДЫМСКОГО РАЙОНА", fio.apply("АДМИНИСТРАЦИЯ НАДЫМСКОГО РАЙОНА").text());
    }
}
