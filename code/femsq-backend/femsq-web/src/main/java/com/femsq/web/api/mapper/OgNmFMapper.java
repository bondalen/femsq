package com.femsq.web.api.mapper;

import com.femsq.database.model.OgNmF;
import com.femsq.web.api.dto.OgNmFDto;
import java.util.List;
import java.util.Objects;
import org.springframework.stereotype.Component;

/**
 * Маппер {@link OgNmF}.
 */
@Component
public class OgNmFMapper {

    /**
     * @param row домен
     * @return DTO
     */
    public OgNmFDto toDto(OgNmF row) {
        Objects.requireNonNull(row, "row");
        return new OgNmFDto(
                row.onfKey(),
                row.onfOg(),
                row.onfName(),
                row.onfNameExt(),
                row.onfStart(),
                row.onfEnd()
        );
    }

    /**
     * @param rows домен
     * @return DTO
     */
    public List<OgNmFDto> toDto(List<OgNmF> rows) {
        Objects.requireNonNull(rows, "rows");
        return rows.stream().map(this::toDto).toList();
    }
}
