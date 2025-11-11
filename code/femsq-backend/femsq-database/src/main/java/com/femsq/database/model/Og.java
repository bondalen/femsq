package com.femsq.database.model;

import java.util.Objects;

/**
 * Представляет сущность организации (таблица {@code ags_test.og}) для DAO-слоя.
 *
 * @param ogKey        идентификатор организации (PRIMARY KEY)
 * @param ogName       краткое наименование
 * @param ogOfficialName официальное юридическое наименование
 * @param ogFullName   полное наименование (может отсутствовать)
 * @param ogDescription текстовое описание
 * @param inn          идентификационный номер налогоплательщика
 * @param kpp          код причины постановки на учет
 * @param ogrn         основной государственный регистрационный номер
 * @param okpo         код ОКПО
 * @param oe           код отрасли экономики
 * @param registrationTaxType признак налогового учета ({@code og}, {@code sd}, {@code ie})
 */
public record Og(
        Integer ogKey,
        String ogName,
        String ogOfficialName,
        String ogFullName,
        String ogDescription,
        Double inn,
        Double kpp,
        Double ogrn,
        Double okpo,
        Integer oe,
        String registrationTaxType
) {

    public Og {
        Objects.requireNonNull(ogName, "ogName");
        Objects.requireNonNull(ogOfficialName, "ogOfficialName");
        Objects.requireNonNull(registrationTaxType, "registrationTaxType");
    }
}
