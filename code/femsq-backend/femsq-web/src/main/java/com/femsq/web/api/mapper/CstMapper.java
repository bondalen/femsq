package com.femsq.web.api.mapper;

import com.femsq.database.model.Cst;
import com.femsq.web.api.dto.CstCreateRequest;
import com.femsq.web.api.dto.CstDto;
import com.femsq.web.api.dto.CstUpdateRequest;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/**
 * Маппер стройки {@link Cst}.
 */
@Component
public class CstMapper {

    public CstDto toDto(Cst site) {
        Objects.requireNonNull(site, "site");
        return new CstDto(site.cstKey(), site.cstName(), site.cstBusSgm(), site.cstOidOld(), site.cstMark());
    }

    public List<CstDto> toDto(List<Cst> sites) {
        Objects.requireNonNull(sites, "sites");
        return sites.stream().map(this::toDto).collect(Collectors.toList());
    }

    public Cst toDomain(CstCreateRequest request) {
        Objects.requireNonNull(request, "request");
        return new Cst(null, request.cstName(), request.cstBusSgm(), request.cstOidOld(), request.cstMark());
    }

    public Cst toDomain(int cstKey, CstUpdateRequest request) {
        Objects.requireNonNull(request, "request");
        return new Cst(cstKey, request.cstName(), request.cstBusSgm(), request.cstOidOld(), request.cstMark());
    }
}
