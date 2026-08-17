package com.femsq.web.api.mapper;

import com.femsq.database.model.CnS;
import com.femsq.database.model.CnSOrg;
import com.femsq.database.model.CnSOrgIdLookup;
import com.femsq.database.model.CnSOrgSmpl;
import com.femsq.web.api.dto.CnSOrgCreateRequest;
import com.femsq.web.api.dto.CnSOrgDto;
import com.femsq.web.api.dto.CnSOrgIdLookupDto;
import com.femsq.web.api.dto.CnSOrgSmplCreateRequest;
import com.femsq.web.api.dto.CnSOrgSmplDto;
import com.femsq.web.api.dto.CnSOrgSmplUpdateRequest;
import com.femsq.web.api.dto.CnSOrgUpdateRequest;
import com.femsq.web.api.dto.CnSideCreateRequest;
import com.femsq.web.api.dto.CnSideDto;
import com.femsq.web.api.dto.CnSideUpdateRequest;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/**
 * Маппер сторон договора и вложенного дерева.
 */
@Component
public class CnPartyMapper {

    private static final DateTimeFormatter TS = DateTimeFormatter.ISO_LOCAL_DATE_TIME;

    /**
     * Собирает дерево сторона → smpl → org.
     */
    public List<CnSideDto> toTree(
            List<CnS> sides,
            List<CnSOrgSmpl> smpls,
            List<CnSOrg> orgs
    ) {
        Map<Integer, List<CnSOrg>> orgsBySmpl = orgs.stream()
                .collect(Collectors.groupingBy(CnSOrg::csoCnSOrgSmpl));
        Map<Integer, List<CnSOrgSmpl>> smplsBySide = smpls.stream()
                .collect(Collectors.groupingBy(CnSOrgSmpl::csosCnS));

        List<CnSideDto> result = new ArrayList<>();
        for (CnS side : sides) {
            List<CnSOrgSmplDto> smplDtos = new ArrayList<>();
            for (CnSOrgSmpl smpl : smplsBySide.getOrDefault(side.cnSKey(), List.of())) {
                List<CnSOrgDto> orgDtos = orgsBySmpl.getOrDefault(smpl.csosKey(), List.of()).stream()
                        .map(this::toOrgDto)
                        .toList();
                smplDtos.add(toSmplDto(smpl, orgDtos));
            }
            result.add(new CnSideDto(
                    side.cnSKey(),
                    side.cnKey(),
                    side.cnSType(),
                    side.cnSTypeName(),
                    smplDtos
            ));
        }
        return List.copyOf(result);
    }

    public CnSideDto toSideDto(CnS side, List<CnSOrgSmplDto> smpls) {
        return new CnSideDto(side.cnSKey(), side.cnKey(), side.cnSType(), side.cnSTypeName(), smpls);
    }

    public CnSOrgSmplDto toSmplDto(CnSOrgSmpl smpl, List<CnSOrgDto> orgs) {
        return new CnSOrgSmplDto(
                smpl.csosKey(),
                smpl.csosCnS(),
                smpl.csosOrgId(),
                smpl.orgLabel(),
                formatTs(smpl.csosTimeOfEntry()),
                orgs
        );
    }

    public CnSOrgDto toOrgDto(CnSOrg org) {
        return new CnSOrgDto(
                org.cnSOrgKey(),
                org.csoCnSOrgSmpl(),
                org.dateBeg(),
                org.dateEnd(),
                org.csoAsbuId(),
                org.csoCnDate(),
                formatTs(org.csoTimeOfEntry())
        );
    }

    public List<CnSOrgIdLookupDto> toLookupDto(List<CnSOrgIdLookup> rows) {
        return rows.stream()
                .map(row -> new CnSOrgIdLookupDto(row.orgIdKey(), row.buirg(), row.label()))
                .toList();
    }

    public CnS toDomain(CnSideCreateRequest request) {
        Objects.requireNonNull(request, "request");
        return new CnS(null, request.cnKey(), request.cnSType(), null);
    }

    public CnS toDomain(int cnSKey, CnSideUpdateRequest request) {
        Objects.requireNonNull(request, "request");
        return new CnS(cnSKey, request.cnKey(), request.cnSType(), null);
    }

    public CnSOrgSmpl toDomain(CnSOrgSmplCreateRequest request) {
        Objects.requireNonNull(request, "request");
        return new CnSOrgSmpl(null, request.csosCnS(), request.csosOrgId(), null, null);
    }

    public CnSOrgSmpl toDomain(int csosKey, CnSOrgSmplUpdateRequest request) {
        Objects.requireNonNull(request, "request");
        return new CnSOrgSmpl(csosKey, request.csosCnS(), request.csosOrgId(), null, null);
    }

    public CnSOrg toDomain(CnSOrgCreateRequest request) {
        Objects.requireNonNull(request, "request");
        return new CnSOrg(
                null,
                request.csoCnSOrgSmpl(),
                request.dateBeg(),
                request.dateEnd(),
                request.csoAsbuId(),
                request.csoCnDate(),
                null
        );
    }

    public CnSOrg toDomain(int cnSOrgKey, CnSOrgUpdateRequest request) {
        Objects.requireNonNull(request, "request");
        return new CnSOrg(
                cnSOrgKey,
                request.csoCnSOrgSmpl(),
                request.dateBeg(),
                request.dateEnd(),
                request.csoAsbuId(),
                request.csoCnDate(),
                null
        );
    }

    private static String formatTs(LocalDateTime value) {
        return value == null ? null : TS.format(value);
    }
}
