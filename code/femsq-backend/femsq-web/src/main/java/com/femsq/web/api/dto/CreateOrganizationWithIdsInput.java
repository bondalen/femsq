package com.femsq.web.api.dto;

/**
 * Создание организации + опциональные идентификаторы БУиРГ/ИНН(+КПП) в {@code org_id}.
 *
 * @param ogName краткое имя
 * @param ogOfficialName официальное имя
 * @param ogFullName полное имя
 * @param ogDescription описание
 * @param registrationTaxType og|sd|ie
 * @param buirg код БУиРГ (type=1), optional
 * @param itn ИНН (type=2), optional
 * @param itnExt КПП в org_id_value_t_ext, optional
 */
public record CreateOrganizationWithIdsInput(
        String ogName,
        String ogOfficialName,
        String ogFullName,
        String ogDescription,
        String registrationTaxType,
        Integer buirg,
        String itn,
        String itnExt
) {
}
