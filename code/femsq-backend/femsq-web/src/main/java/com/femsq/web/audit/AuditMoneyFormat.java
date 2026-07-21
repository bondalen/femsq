package com.femsq.web.audit;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.util.Locale;

/**
 * Единый формат денежных сумм в логе ревизии: {@code 5 558 976 847,24}
 * (пробел — разделитель разрядов, запятая — десятичный, 2 знака).
 */
public final class AuditMoneyFormat {

    private static final DecimalFormat FORMAT;

    static {
        DecimalFormatSymbols symbols = new DecimalFormatSymbols(Locale.ROOT);
        symbols.setGroupingSeparator(' ');
        symbols.setDecimalSeparator(',');
        FORMAT = new DecimalFormat("#,##0.00", symbols);
        FORMAT.setGroupingUsed(true);
        FORMAT.setRoundingMode(RoundingMode.HALF_UP);
        FORMAT.setMinimumFractionDigits(2);
        FORMAT.setMaximumFractionDigits(2);
    }

    private AuditMoneyFormat() {
    }

    /**
     * Форматирует сумму для отображения в {@code adt_results}.
     *
     * @param value сумма или {@code null}
     * @return строка вида {@code 1 234,56} либо {@code 0,00} для null
     */
    public static String format(BigDecimal value) {
        BigDecimal v = value == null ? BigDecimal.ZERO : value;
        synchronized (FORMAT) {
            return FORMAT.format(v);
        }
    }
}
