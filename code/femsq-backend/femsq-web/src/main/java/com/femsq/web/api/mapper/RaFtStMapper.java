package com.femsq.web.api.mapper;

import com.femsq.database.model.RaFtSt;
import com.femsq.web.api.dto.RaFtStDto;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/**
 * Маппер между доменной моделью {@link RaFtSt} и DTO-объектами API.
 */
@Component
public class RaFtStMapper {

    /**
     * Преобразует доменную модель в DTO.
     *
     * @param raFtSt доменная сущность
     * @return DTO-представление
     */
    public RaFtStDto toDto(RaFtSt raFtSt) {
        Objects.requireNonNull(raFtSt, "raFtSt");
        return new RaFtStDto(
                raFtSt.stKey(),
                raFtSt.stName(),
                raFtSt.stCreated(),
                raFtSt.stUpdated()
        );
    }

    /**
     * Преобразует список доменных моделей в список DTO.
     *
     * @param raFtSts список доменных сущностей
     * @return список DTO
     */
    public List<RaFtStDto> toDto(List<RaFtSt> raFtSts) {
        Objects.requireNonNull(raFtSts, "raFtSts");
        return raFtSts.stream().map(this::toDto).collect(Collectors.toList());
    }
}
