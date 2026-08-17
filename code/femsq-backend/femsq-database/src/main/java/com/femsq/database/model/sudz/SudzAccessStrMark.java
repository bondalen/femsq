package com.femsq.database.model.sudz;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Objects;

/**
 * Метка Access {@code strMark(Now())} → {@code CLng}: месяц + день(2) + час(2) + минута(2).
 * Пример: 14.08 21:05 → {@code 8142105}.
 */
public final class SudzAccessStrMark {

    private SudzAccessStrMark() {
    }

    /**
     * @param dateTime момент (системная зона)
     * @return числовая метка для {@code ags.cn.cnMark}
     */
    public static int from(LocalDateTime dateTime) {
        Objects.requireNonNull(dateTime, "dateTime");
        int month = dateTime.getMonthValue();
        int day = dateTime.getDayOfMonth();
        int hour = dateTime.getHour();
        int minute = dateTime.getMinute();
        String raw = month
                + pad2(day)
                + pad2(hour)
                + pad2(minute);
        return Integer.parseInt(raw);
    }

    /**
     * Текущее системное время JVM.
     *
     * @return метка
     */
    public static int now() {
        return from(LocalDateTime.now(ZoneId.systemDefault()));
    }

    private static String pad2(int value) {
        return value < 10 ? "0" + value : String.valueOf(value);
    }
}
