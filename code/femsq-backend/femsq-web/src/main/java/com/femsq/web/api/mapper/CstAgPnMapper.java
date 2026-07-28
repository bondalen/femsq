package com.femsq.web.api.mapper;

import com.femsq.database.model.CstAgPn;
import com.femsq.web.api.dto.CstAgPnCodeDto;
import com.femsq.web.api.dto.CstAgPnCreateRequest;
import com.femsq.web.api.dto.CstAgPnDto;
import com.femsq.web.api.dto.CstAgPnUpdateRequest;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/**
 * Маппер {@link CstAgPn}.
 */
@Component
public class CstAgPnMapper {

    public CstAgPnDto toDto(CstAgPn point) {
        Objects.requireNonNull(point, "point");
        return new CstAgPnDto(point.cstapKey(), point.cstapCsta(), point.cstapIpgPnN(), point.cstapOidOld());
    }

    public List<CstAgPnDto> toDto(List<CstAgPn> points) {
        Objects.requireNonNull(points, "points");
        return points.stream().map(this::toDto).collect(Collectors.toList());
    }

    /**
     * Преобразует строку списка кодов САК в DTO.
     */
    public CstAgPnCodeDto toCodeDto(com.femsq.database.model.CstAgPnCode code) {
        Objects.requireNonNull(code, "code");
        return new CstAgPnCodeDto(
                code.cstapKey(),
                code.cstapIpgPnN(),
                code.cstapCsta(),
                code.cstaCst(),
                code.cstName()
        );
    }

    /**
     * Преобразует список кодов САК в DTO.
     */
    public List<CstAgPnCodeDto> toCodeDto(List<com.femsq.database.model.CstAgPnCode> codes) {
        Objects.requireNonNull(codes, "codes");
        return codes.stream().map(this::toCodeDto).collect(Collectors.toList());
    }

    public CstAgPn toDomain(CstAgPnCreateRequest request) {
        Objects.requireNonNull(request, "request");
        return new CstAgPn(null, request.cstapCsta(), request.cstapIpgPnN(), request.cstapOidOld());
    }

    public CstAgPn toDomain(int cstapKey, CstAgPnUpdateRequest request) {
        Objects.requireNonNull(request, "request");
        return new CstAgPn(cstapKey, request.cstapCsta(), request.cstapIpgPnN(), request.cstapOidOld());
    }
}
