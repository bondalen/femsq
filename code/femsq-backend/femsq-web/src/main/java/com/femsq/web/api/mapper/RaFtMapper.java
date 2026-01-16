package com.femsq.web.api.mapper;

import com.femsq.database.model.RaFt;
import com.femsq.web.api.dto.RaFtDto;
import org.springframework.stereotype.Component;
import java.util.List;
import java.util.Objects;

/**
 * Маппер для преобразования между {@link RaFt} и {@link RaFtDto}.
 */
@Component
public class RaFtMapper {

    /**
     * Преобразует доменную модель в DTO.
     *
     * @param raFt доменная модель
     * @return DTO
     */
    public RaFtDto toDto(RaFt raFt) {
        Objects.requireNonNull(raFt, "raFt");
        return new RaFtDto(
                raFt.ftKey(),
                raFt.ftName()
        );
    }

    /**
     * Преобразует список доменных моделей в список DTO.
     *
     * @param raFts список доменных моделей
     * @return список DTO
     */
    public List<RaFtDto> toDto(List<RaFt> raFts) {
        Objects.requireNonNull(raFts, "raFts");
        return raFts.stream().map(this::toDto).toList();
    }
}
