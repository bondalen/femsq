package com.femsq.web.api.mapper;

import com.femsq.database.model.RaDir;
import com.femsq.web.api.dto.RaDirDto;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/**
 * Маппер между доменной моделью {@link RaDir} и DTO-объектами API.
 */
@Component
public class RaDirMapper {

    /**
     * Преобразует доменную модель в DTO.
     *
     * @param raDir доменная сущность
     * @return DTO-представление
     */
    public RaDirDto toDto(RaDir raDir) {
        Objects.requireNonNull(raDir, "raDir");
        return new RaDirDto(
                raDir.key(),
                raDir.dirName(),
                raDir.dir(),
                raDir.dirCreated(),
                raDir.dirUpdated()
        );
    }

    /**
     * Преобразует список доменных моделей в список DTO.
     *
     * @param raDirs список доменных сущностей
     * @return список DTO
     */
    public List<RaDirDto> toDto(List<RaDir> raDirs) {
        Objects.requireNonNull(raDirs, "raDirs");
        return raDirs.stream().map(this::toDto).collect(Collectors.toList());
    }
}