package com.femsq.web.api.mapper;

import com.femsq.database.model.RaAt;
import com.femsq.web.api.dto.RaAtDto;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/**
 * Маппер между доменной моделью {@link RaAt} и DTO-объектами API.
 */
@Component
public class RaAtMapper {

    /**
     * Преобразует доменную модель в DTO.
     *
     * @param raAt доменная сущность
     * @return DTO-представление
     */
    public RaAtDto toDto(RaAt raAt) {
        Objects.requireNonNull(raAt, "raAt");
        return new RaAtDto(
                raAt.atKey(),
                raAt.atName(),
                raAt.atCreated(),
                raAt.atUpdated()
        );
    }

    /**
     * Преобразует список доменных моделей в список DTO.
     *
     * @param raAts список доменных сущностей
     * @return список DTO
     */
    public List<RaAtDto> toDto(List<RaAt> raAts) {
        Objects.requireNonNull(raAts, "raAts");
        return raAts.stream().map(this::toDto).collect(Collectors.toList());
    }
}