package com.femsq.database.model;

import java.util.Objects;

/**
 * Строка списка САК для формы поиска по коду (Access {@code cstAgPn}).
 *
 * @param cstapKey    ключ САК
 * @param cstapIpgPnN код пункта ИП / САК
 * @param cstapCsta   ключ агента на стройке
 * @param cstaCst     ключ стройки
 * @param cstName     наименование стройки (для контекста)
 */
public record CstAgPnCode(
        Integer cstapKey,
        String cstapIpgPnN,
        Integer cstapCsta,
        Integer cstaCst,
        String cstName
) {

    public CstAgPnCode {
        Objects.requireNonNull(cstapKey, "cstapKey");
        Objects.requireNonNull(cstapIpgPnN, "cstapIpgPnN");
        Objects.requireNonNull(cstapCsta, "cstapCsta");
        Objects.requireNonNull(cstaCst, "cstaCst");
    }
}
