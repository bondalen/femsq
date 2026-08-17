package com.femsq.web.api.dto;

import java.util.List;

/**
 * Сторона договора с вложенным деревом smpl → org.
 */
public record CnSideDto(
        Integer cnSKey,
        Integer cnKey,
        Integer cnSType,
        String cnSTypeName,
        List<CnSOrgSmplDto> smpls
) {
}
