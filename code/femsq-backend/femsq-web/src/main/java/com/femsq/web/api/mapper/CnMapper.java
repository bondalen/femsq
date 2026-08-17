package com.femsq.web.api.mapper;

import com.femsq.database.model.Cn;
import com.femsq.database.model.CnNum;
import com.femsq.web.api.dto.CnDto;
import com.femsq.web.api.dto.CnNumDto;
import com.femsq.web.api.dto.CnUpdateRequest;
import java.util.List;
import org.springframework.stereotype.Component;

/**
 * Маппер договоров / номеров → GraphQL DTO.
 */
@Component
public class CnMapper {

    public CnNumDto toDto(CnNum entity) {
        return new CnNumDto(
                entity.cnnKey(),
                entity.cnnNum(),
                entity.cnnCn(),
                entity.cnnType(),
                entity.cnnTypeName(),
                entity.cnnNote()
        );
    }

    public List<CnNumDto> toCnNumDto(List<CnNum> entities) {
        return entities.stream().map(this::toDto).toList();
    }

    public CnDto toDto(Cn entity) {
        return new CnDto(
                entity.cnKey(),
                entity.cnNumber(),
                entity.cnDate(),
                entity.cnNote(),
                entity.cnMark()
        );
    }

    /**
     * Собирает доменную модель для UPDATE (номер computed — не трогаем).
     */
    public Cn toDomain(int cnKey, CnUpdateRequest request) {
        return new Cn(
                cnKey,
                null,
                request.cnDate(),
                request.cnNote(),
                request.cnMark()
        );
    }
}
