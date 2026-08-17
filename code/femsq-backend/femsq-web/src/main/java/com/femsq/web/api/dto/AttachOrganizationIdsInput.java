package com.femsq.web.api.dto;

/**
 * Привязка БУиРГ и/или ИНН(+КПП) к существующей организации.
 *
 * @param ogKey ключ og
 * @param buirg код БУиРГ, optional
 * @param itn ИНН, optional
 * @param itnExt КПП в org_id_value_t_ext, optional
 */
public record AttachOrganizationIdsInput(
        int ogKey,
        Integer buirg,
        String itn,
        String itnExt
) {
}
