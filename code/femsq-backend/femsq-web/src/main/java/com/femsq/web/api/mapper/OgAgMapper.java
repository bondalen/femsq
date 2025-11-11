package com.femsq.web.api.mapper;

import com.femsq.database.model.OgAg;
import com.femsq.web.api.dto.OgAgCreateRequest;
import com.femsq.web.api.dto.OgAgDto;
import com.femsq.web.api.dto.OgAgUpdateRequest;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/**
 * Маппер между сущностью {@link OgAg} и DTO-объектами API.
 */
@Component
public class OgAgMapper {

    /**
     * Преобразует доменную модель в DTO.
     */
    public OgAgDto toDto(OgAg agent) {
        Objects.requireNonNull(agent, "agent");
        return new OgAgDto(agent.ogAgKey(), agent.code(), agent.organizationKey(), agent.legacyOid());
    }

    /**
     * Преобразует список доменных моделей в список DTO.
     */
    public List<OgAgDto> toDto(List<OgAg> agents) {
        Objects.requireNonNull(agents, "agents");
        return agents.stream().map(this::toDto).collect(Collectors.toList());
    }

    /**
     * Формирует доменную модель для создания агентской организации.
     */
    public OgAg toDomain(OgAgCreateRequest request) {
        Objects.requireNonNull(request, "request");
        return new OgAg(null, request.code(), request.organizationKey(), request.legacyOid());
    }

    /**
     * Формирует доменную модель для обновления агентской организации.
     */
    public OgAg toDomain(int ogAgKey, OgAgUpdateRequest request) {
        Objects.requireNonNull(request, "request");
        return new OgAg(ogAgKey, request.code(), request.organizationKey(), request.legacyOid());
    }
}
