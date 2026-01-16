package com.femsq.web.api.mapper;

import com.femsq.database.model.RaFtSn;
import com.femsq.web.api.dto.RaFtSnDto;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/**
 * Маппер между доменной моделью {@link RaFtSn} и DTO-объектами API.
 */
@Component
public class RaFtSnMapper {

    /**
     * Преобразует доменную модель в DTO.
     *
     * @param raFtSn доменная сущность
     * @return DTO-представление
     */
    public RaFtSnDto toDto(RaFtSn raFtSn) {
        Objects.requireNonNull(raFtSn, "raFtSn");
        return new RaFtSnDto(
                raFtSn.ftsnKey(),
                raFtSn.ftsnFtS(),
                raFtSn.ftsnName(),
                raFtSn.ftsnCreated(),
                raFtSn.ftsnUpdated()
        );
    }

    /**
     * Преобразует список доменных моделей в список DTO.
     *
     * @param raFtSns список доменных сущностей
     * @return список DTO
     */
    public List<RaFtSnDto> toDto(List<RaFtSn> raFtSns) {
        Objects.requireNonNull(raFtSns, "raFtSns");
        return raFtSns.stream().map(this::toDto).collect(Collectors.toList());
    }
}
