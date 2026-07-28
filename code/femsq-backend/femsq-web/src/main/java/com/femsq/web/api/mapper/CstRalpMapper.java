package com.femsq.web.api.mapper;

import com.femsq.database.model.RalpRa;
import com.femsq.database.model.RalpRaAu;
import com.femsq.database.model.RalpRaAuStatusLookup;
import com.femsq.database.model.RalpRaCstListEntry;
import com.femsq.web.api.dto.RalpRaAuCreateRequest;
import com.femsq.web.api.dto.RalpRaAuDto;
import com.femsq.web.api.dto.RalpRaAuStatusLookupDto;
import com.femsq.web.api.dto.RalpRaAuUpdateRequest;
import com.femsq.web.api.dto.RalpRaCreateRequest;
import com.femsq.web.api.dto.RalpRaCstListEntryDto;
import com.femsq.web.api.dto.RalpRaDto;
import com.femsq.web.api.dto.RalpRaUpdateRequest;
import java.math.BigDecimal;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/**
 * Маппер вкладки «отчёты, аренда» ({@code ralpRaCst} / {@code ralpRa} / {@code ralpRaAu}).
 */
@Component
public class CstRalpMapper {

    public RalpRaCstListEntryDto toListDto(RalpRaCstListEntry entry) {
        Objects.requireNonNull(entry, "entry");
        return new RalpRaCstListEntryDto(
                entry.cstKey(),
                entry.ogaNm(),
                entry.cstapIpgPnN(),
                entry.ralprKey(),
                entry.ralprNum(),
                entry.ralprDate(),
                entry.ralprCstAgPn(),
                entry.ralprOgSender(),
                entry.ogNm(),
                entry.auCnt(),
                entry.hasReturned()
        );
    }

    public List<RalpRaCstListEntryDto> toListDto(List<RalpRaCstListEntry> entries) {
        return entries.stream().map(this::toListDto).collect(Collectors.toList());
    }

    public RalpRaDto toDto(RalpRa report) {
        Objects.requireNonNull(report, "report");
        return new RalpRaDto(
                report.ralprKey(),
                report.ralprNum(),
                report.ralprDate(),
                report.ralprCstAgPn(),
                report.ralprOgSender(),
                report.ogNm(),
                report.ralprY(),
                report.ralprM()
        );
    }

    public RalpRa toDomain(RalpRaCreateRequest request) {
        Objects.requireNonNull(request, "request");
        return new RalpRa(
                null,
                request.ralprNum(),
                request.ralprDate(),
                request.ralprCstAgPn(),
                request.ralprOgSender(),
                null,
                null,
                null
        );
    }

    public RalpRa toDomain(int ralprKey, RalpRaUpdateRequest request) {
        Objects.requireNonNull(request, "request");
        return new RalpRa(
                ralprKey,
                request.ralprNum(),
                request.ralprDate(),
                request.ralprCstAgPn(),
                request.ralprOgSender(),
                null,
                null,
                null
        );
    }

    public RalpRaAuDto toDto(RalpRaAu row) {
        Objects.requireNonNull(row, "row");
        return new RalpRaAuDto(
                row.ralpraKey(),
                row.ralpraRa(),
                toDouble(row.ralpraCostAndVat()),
                row.ralpraArrived(),
                row.ralpraArrivedDate(),
                row.ralpraReturned(),
                row.ralpraReturnedDate(),
                row.ralpraSent(),
                row.ralpraSentDate(),
                row.ralpraNote(),
                row.ralpraStatus()
        );
    }

    public List<RalpRaAuDto> toAuDto(List<RalpRaAu> rows) {
        return rows.stream().map(this::toDto).collect(Collectors.toList());
    }

    public RalpRaAu toDomain(RalpRaAuCreateRequest request) {
        Objects.requireNonNull(request, "request");
        return new RalpRaAu(
                null,
                request.ralpraRa(),
                toBigDecimal(request.ralpraCostAndVat()),
                request.ralpraArrived(),
                request.ralpraArrivedDate(),
                request.ralpraReturned(),
                request.ralpraReturnedDate(),
                request.ralpraSent(),
                request.ralpraSentDate(),
                request.ralpraNote(),
                request.ralpraStatus()
        );
    }

    public RalpRaAu toDomain(int ralpraKey, RalpRaAuUpdateRequest request) {
        Objects.requireNonNull(request, "request");
        return new RalpRaAu(
                ralpraKey,
                request.ralpraRa(),
                toBigDecimal(request.ralpraCostAndVat()),
                request.ralpraArrived(),
                request.ralpraArrivedDate(),
                request.ralpraReturned(),
                request.ralpraReturnedDate(),
                request.ralpraSent(),
                request.ralpraSentDate(),
                request.ralpraNote(),
                request.ralpraStatus()
        );
    }

    public RalpRaAuStatusLookupDto toDto(RalpRaAuStatusLookup lookup) {
        Objects.requireNonNull(lookup, "lookup");
        return new RalpRaAuStatusLookupDto(lookup.code(), lookup.label());
    }

    public List<RalpRaAuStatusLookupDto> toStatusDto(List<RalpRaAuStatusLookup> lookups) {
        return lookups.stream().map(this::toDto).collect(Collectors.toList());
    }

    private static Double toDouble(BigDecimal value) {
        return value == null ? null : value.doubleValue();
    }

    private static BigDecimal toBigDecimal(Double value) {
        return value == null ? null : BigDecimal.valueOf(value);
    }
}
