package com.femsq.web.api.mapper;

import com.femsq.database.model.OgAgCs;
import com.femsq.web.api.dto.OgAgCsLookupDto;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/**
 * Маппер lookup {@link OgAgCs}.
 */
@Component
public class OgAgCsMapper {

    public OgAgCsLookupDto toDto(OgAgCs item) {
        Objects.requireNonNull(item, "item");
        return new OgAgCsLookupDto(item.ogaKey(), item.ogaNm());
    }

    public List<OgAgCsLookupDto> toDto(List<OgAgCs> items) {
        Objects.requireNonNull(items, "items");
        return items.stream().map(this::toDto).collect(Collectors.toList());
    }
}
