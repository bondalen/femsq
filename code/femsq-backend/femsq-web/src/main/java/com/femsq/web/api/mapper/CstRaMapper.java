package com.femsq.web.api.mapper;

import com.femsq.database.model.CstAgPnSiteLookup;
import com.femsq.database.model.CstRaListEntry;
import com.femsq.database.model.RaPeriodLookup;
import com.femsq.database.model.RaReport;
import com.femsq.database.model.RaSumm;
import com.femsq.web.api.dto.CstAgPnSiteLookupDto;
import com.femsq.web.api.dto.CstRaListEntryDto;
import com.femsq.web.api.dto.RaPeriodLookupDto;
import com.femsq.web.api.dto.RaReportCreateRequest;
import com.femsq.web.api.dto.RaReportDto;
import com.femsq.web.api.dto.RaReportUpdateRequest;
import com.femsq.web.api.dto.RaSummCreateRequest;
import com.femsq.web.api.dto.RaSummDto;
import com.femsq.web.api.dto.RaSummUpdateRequest;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/**
 * Маппер отчётов стройки ({@code fnRRcList} / {@code ra} / {@code ra_summ}).
 */
@Component
public class CstRaMapper {

    public CstRaListEntryDto toListDto(CstRaListEntry entry) {
        Objects.requireNonNull(entry, "entry");
        return new CstRaListEntryDto(
                entry.yyyy(),
                entry.mNum(),
                entry.p(),
                entry.cstaKey(),
                entry.cstaAg(),
                entry.cstaCst(),
                entry.ogaNm(),
                entry.cstapKey(),
                entry.cstapIpgPnN(),
                entry.raKey(),
                entry.raNum(),
                entry.raDate(),
                entry.raType(),
                entry.raChKey(),
                entry.raChNum(),
                entry.raChDate(),
                entry.raOrgSender(),
                entry.ogNm(),
                toDouble(entry.rasTotal()),
                toDouble(entry.rasWork()),
                toDouble(entry.rasEquip()),
                toDouble(entry.rasOthers()),
                entry.raArrived(),
                entry.raArrivedDate(),
                entry.raReturned(),
                entry.raReturnedDate(),
                entry.raSent(),
                entry.raSentDate()
        );
    }

    public List<CstRaListEntryDto> toListDto(List<CstRaListEntry> entries) {
        return entries.stream().map(this::toListDto).collect(Collectors.toList());
    }

    public RaReportDto toDto(RaReport report) {
        Objects.requireNonNull(report, "report");
        return new RaReportDto(
                report.raKey(),
                report.raNum(),
                report.raDate(),
                report.raCac(),
                report.raType(),
                report.raWorkType(),
                report.raPeriod(),
                report.raArrived(),
                report.raArrivedDate(),
                report.raReturned(),
                report.raReturnedDate(),
                report.raSent(),
                report.raSentDate(),
                report.raNoteT(),
                toOffsetDateTime(report.raCreated()),
                report.raOrgSender(),
                report.raNote()
        );
    }

    public RaReport toDomain(RaReportCreateRequest request) {
        Objects.requireNonNull(request, "request");
        return new RaReport(
                null,
                request.raNum(),
                request.raDate(),
                request.raCac(),
                request.raType(),
                request.raWorkType(),
                request.raPeriod(),
                request.raArrived(),
                request.raArrivedDate(),
                request.raReturned(),
                request.raReturnedDate(),
                request.raSent(),
                request.raSentDate(),
                request.raNoteT(),
                null,
                request.raOrgSender(),
                request.raNote()
        );
    }

    public RaReport toDomain(int raKey, RaReportUpdateRequest request) {
        Objects.requireNonNull(request, "request");
        return new RaReport(
                raKey,
                request.raNum(),
                request.raDate(),
                request.raCac(),
                request.raType(),
                request.raWorkType(),
                request.raPeriod(),
                request.raArrived(),
                request.raArrivedDate(),
                request.raReturned(),
                request.raReturnedDate(),
                request.raSent(),
                request.raSentDate(),
                request.raNoteT(),
                null,
                request.raOrgSender(),
                request.raNote()
        );
    }

    public RaSummDto toDto(RaSumm summ) {
        Objects.requireNonNull(summ, "summ");
        return new RaSummDto(
                summ.rasKey(),
                summ.rasRa(),
                toDouble(summ.rasTotal()),
                toDouble(summ.rasWork()),
                toDouble(summ.rasEquip()),
                toDouble(summ.rasOthers()),
                toOffsetDateTime(summ.rasDate())
        );
    }

    public List<RaSummDto> toSummDto(List<RaSumm> summs) {
        return summs.stream().map(this::toDto).collect(Collectors.toList());
    }

    public RaSumm toDomain(RaSummCreateRequest request) {
        Objects.requireNonNull(request, "request");
        return new RaSumm(
                null,
                request.rasRa(),
                toBigDecimal(request.rasTotal()),
                toBigDecimal(request.rasWork()),
                toBigDecimal(request.rasEquip()),
                toBigDecimal(request.rasOthers()),
                toLocalDateTime(request.rasDate())
        );
    }

    public RaSumm toDomain(int rasKey, RaSummUpdateRequest request) {
        Objects.requireNonNull(request, "request");
        return new RaSumm(
                rasKey,
                request.rasRa(),
                toBigDecimal(request.rasTotal()),
                toBigDecimal(request.rasWork()),
                toBigDecimal(request.rasEquip()),
                toBigDecimal(request.rasOthers()),
                toLocalDateTime(request.rasDate())
        );
    }

    public RaPeriodLookupDto toDto(RaPeriodLookup lookup) {
        return new RaPeriodLookupDto(lookup.key(), lookup.p());
    }

    public List<RaPeriodLookupDto> toPeriodDto(List<RaPeriodLookup> lookups) {
        return lookups.stream().map(this::toDto).collect(Collectors.toList());
    }

    public CstAgPnSiteLookupDto toDto(CstAgPnSiteLookup lookup) {
        return new CstAgPnSiteLookupDto(
                lookup.cstapKey(),
                lookup.cstapIpgPnN(),
                lookup.cstaKey(),
                lookup.agentLabel()
        );
    }

    public List<CstAgPnSiteLookupDto> toSiteLookupDto(List<CstAgPnSiteLookup> lookups) {
        return lookups.stream().map(this::toDto).collect(Collectors.toList());
    }

    private static Double toDouble(BigDecimal value) {
        return value == null ? null : value.doubleValue();
    }

    private static BigDecimal toBigDecimal(Double value) {
        return value == null ? null : BigDecimal.valueOf(value);
    }

    /**
     * GraphQL {@code DateTime} (ExtendedScalars) сериализует {@link OffsetDateTime}.
     */
    private static OffsetDateTime toOffsetDateTime(LocalDateTime dateTime) {
        if (dateTime == null) {
            return null;
        }
        return dateTime.atZone(ZoneId.systemDefault()).toOffsetDateTime();
    }

    private static LocalDateTime toLocalDateTime(OffsetDateTime dateTime) {
        if (dateTime == null) {
            return null;
        }
        return dateTime.atZoneSameInstant(ZoneId.systemDefault()).toLocalDateTime();
    }
}
