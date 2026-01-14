package com.femsq.web.api.mapper;

import com.femsq.database.model.RaA;
import com.femsq.web.api.dto.RaACreateRequest;
import com.femsq.web.api.dto.RaADto;
import com.femsq.web.api.dto.RaAUpdateRequest;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/**
 * Маппер между доменной моделью {@link RaA} и DTO-объектами API.
 */
@Component
public class RaAMapper {

    /**
     * Преобразует доменную модель в DTO.
     *
     * @param raA доменная сущность
     * @return DTO-представление
     */
    public RaADto toDto(RaA raA) {
        Objects.requireNonNull(raA, "raA");
        return new RaADto(
                raA.adtKey(),
                raA.adtName(),
                raA.adtDate(),
                raA.adtResults(),
                raA.adtDir(),
                raA.adtType(),
                raA.adtAddRA(),
                raA.adtCreated(),
                raA.adtUpdated()
        );
    }

    /**
     * Преобразует список доменных моделей в список DTO.
     *
     * @param raAs список доменных сущностей
     * @return список DTO
     */
    public List<RaADto> toDto(List<RaA> raAs) {
        Objects.requireNonNull(raAs, "raAs");
        return raAs.stream().map(this::toDto).collect(Collectors.toList());
    }

    /**
     * Формирует доменную модель для создания ревизии.
     *
     * @param request входной запрос
     * @return доменная сущность без идентификатора
     */
    public RaA toDomain(RaACreateRequest request) {
        Objects.requireNonNull(request, "request");
        return new RaA(
                null,
                request.adtName(),
                request.adtDate(),
                request.adtResults(),
                request.adtDir(),
                request.adtType(),
                request.adtAddRA(),
                null,
                null
        );
    }

    /**
     * Формирует доменную модель для обновления ревизии.
     *
     * @param adtKey  идентификатор ревизии
     * @param request входной запрос
     * @return доменная сущность с идентификатором
     */
    public RaA toDomain(long adtKey, RaAUpdateRequest request) {
        Objects.requireNonNull(request, "request");
        return new RaA(
                adtKey,
                request.adtName(),
                request.adtDate(),
                request.adtResults(),
                request.adtDir(),
                request.adtType(),
                request.adtAddRA(),
                null,
                null
        );
    }
}