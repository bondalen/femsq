package com.femsq.web.api.mapper;

import com.femsq.database.model.RaFtS;
import com.femsq.web.api.dto.RaFtSDto;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/**
 * Маппер между доменной моделью {@link RaFtS} и DTO-объектами API.
 */
@Component
public class RaFtSMapper {

    /**
     * Преобразует доменную модель в DTO.
     *
     * @param raFtS доменная сущность
     * @return DTO-представление
     */
    public RaFtSDto toDto(RaFtS raFtS) {
        Objects.requireNonNull(raFtS, "raFtS");
        return new RaFtSDto(
                raFtS.ftSKey(),
                raFtS.ftSType(),
                raFtS.ftSNum(),
                raFtS.ftSSheetType(),
                raFtS.ftSCreated(),
                raFtS.ftSUpdated(),
                raFtS.ftSPeriod()
        );
    }

    /**
     * Преобразует список доменных моделей в список DTO.
     *
     * @param raFtSs список доменных сущностей
     * @return список DTO
     */
    public List<RaFtSDto> toDto(List<RaFtS> raFtSs) {
        Objects.requireNonNull(raFtSs, "raFtSs");
        return raFtSs.stream().map(this::toDto).collect(Collectors.toList());
    }
}
