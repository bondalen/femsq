package com.femsq.web.api.mapper;

import com.femsq.database.model.Og;
import com.femsq.web.api.dto.OgCreateRequest;
import com.femsq.web.api.dto.OgDto;
import com.femsq.web.api.dto.OgUpdateRequest;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/**
 * Маппер между доменной моделью {@link Og} и DTO-объектами API.
 */
@Component
public class OgMapper {

    /**
     * Преобразует доменную модель в DTO.
     *
     * @param og доменная сущность
     * @return DTO-представление
     */
    public OgDto toDto(Og og) {
        Objects.requireNonNull(og, "og");
        return new OgDto(
                og.ogKey(),
                og.ogName(),
                og.ogOfficialName(),
                og.ogFullName(),
                og.ogDescription(),
                og.inn(),
                og.kpp(),
                og.ogrn(),
                og.okpo(),
                og.oe(),
                og.registrationTaxType()
        );
    }

    /**
     * Преобразует список доменных моделей в список DTO.
     *
     * @param organizations список доменных сущностей
     * @return список DTO
     */
    public List<OgDto> toDto(List<Og> organizations) {
        Objects.requireNonNull(organizations, "organizations");
        return organizations.stream().map(this::toDto).collect(Collectors.toList());
    }

    /**
     * Формирует доменную модель для создания организации.
     *
     * @param request входной запрос
     * @return доменная сущность без идентификатора
     */
    public Og toDomain(OgCreateRequest request) {
        Objects.requireNonNull(request, "request");
        return new Og(
                null,
                request.ogName(),
                request.ogOfficialName(),
                request.ogFullName(),
                request.ogDescription(),
                request.inn(),
                request.kpp(),
                request.ogrn(),
                request.okpo(),
                request.oe(),
                normalizeTaxType(request.registrationTaxType())
        );
    }

    /**
     * Формирует доменную модель для обновления организации.
     *
     * @param ogKey   идентификатор организации
     * @param request входной запрос
     * @return доменная сущность с идентификатором
     */
    public Og toDomain(int ogKey, OgUpdateRequest request) {
        Objects.requireNonNull(request, "request");
        return new Og(
                ogKey,
                request.ogName(),
                request.ogOfficialName(),
                request.ogFullName(),
                request.ogDescription(),
                request.inn(),
                request.kpp(),
                request.ogrn(),
                request.okpo(),
                request.oe(),
                normalizeTaxType(request.registrationTaxType())
        );
    }

    private String normalizeTaxType(String registrationTaxType) {
        return registrationTaxType == null ? null : registrationTaxType.trim().toLowerCase();
    }
}
