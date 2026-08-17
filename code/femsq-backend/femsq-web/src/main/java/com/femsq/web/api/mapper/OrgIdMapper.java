package com.femsq.web.api.mapper;

import com.femsq.database.model.OrgId;
import com.femsq.web.api.dto.OrgIdDto;
import java.util.List;
import java.util.Objects;
import org.springframework.stereotype.Component;

/**
 * Маппер {@link OrgId} ↔ {@link OrgIdDto}.
 */
@Component
public class OrgIdMapper {

    /**
     * @param orgId домен
     * @return DTO
     */
    public OrgIdDto toDto(OrgId orgId) {
        Objects.requireNonNull(orgId, "orgId");
        return new OrgIdDto(
                orgId.orgIdKey(),
                orgId.org(),
                orgId.orgIdType(),
                orgId.orgIdValueL(),
                orgId.orgIdValueT(),
                orgId.orgIdValueTExt()
        );
    }

    /**
     * @param rows домен
     * @return DTO
     */
    public List<OrgIdDto> toDto(List<OrgId> rows) {
        Objects.requireNonNull(rows, "rows");
        return rows.stream().map(this::toDto).toList();
    }
}
