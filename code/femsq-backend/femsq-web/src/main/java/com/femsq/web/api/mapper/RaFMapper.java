package com.femsq.web.api.mapper;

import com.femsq.database.model.RaF;
import com.femsq.web.api.dto.RaFCreateRequest;
import com.femsq.web.api.dto.RaFDto;
import com.femsq.web.api.dto.RaFUpdateRequest;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/**
 * Маппер между доменной моделью {@link RaF} и DTO-объектами API.
 */
@Component
public class RaFMapper {

    /**
     * Преобразует доменную модель в DTO.
     *
     * @param raF доменная сущность
     * @return DTO-представление
     */
    public RaFDto toDto(RaF raF) {
        Objects.requireNonNull(raF, "raF");
        return new RaFDto(
                raF.afKey(),
                raF.afName(),
                raF.afDir(),
                raF.afType(),
                raF.afExecute(),
                raF.afSource(),
                raF.afCreated(),
                raF.afUpdated(),
                raF.raOrgSender(),
                raF.afNum()
        );
    }

    /**
     * Преобразует список доменных моделей в список DTO.
     *
     * @param raFs список доменных сущностей
     * @return список DTO
     */
    public List<RaFDto> toDto(List<RaF> raFs) {
        Objects.requireNonNull(raFs, "raFs");
        return raFs.stream().map(this::toDto).collect(Collectors.toList());
    }

    /**
     * Формирует доменную модель для создания файла.
     *
     * @param request входной запрос
     * @return доменная сущность без идентификатора
     */
    public RaF toDomain(RaFCreateRequest request) {
        Objects.requireNonNull(request, "request");
        return new RaF(
                null,
                request.afName(),
                request.afDir(),
                request.afType(),
                request.afExecute(),
                request.afSource(),
                null,
                null,
                request.raOrgSender(),
                request.afNum()
        );
    }

    /**
     * Формирует доменную модель для обновления файла.
     *
     * @param afKey  идентификатор файла
     * @param request входной запрос
     * @return доменная сущность с идентификатором
     */
    public RaF toDomain(long afKey, RaFUpdateRequest request) {
        Objects.requireNonNull(request, "request");
        return new RaF(
                afKey,
                request.afName(),
                request.afDir(),
                request.afType(),
                request.afExecute(),
                request.afSource(),
                null,
                null,
                request.raOrgSender(),
                request.afNum()
        );
    }
}
