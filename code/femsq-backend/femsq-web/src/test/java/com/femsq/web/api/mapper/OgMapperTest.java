package com.femsq.web.api.mapper;

import com.femsq.database.model.Og;
import com.femsq.web.api.dto.OgCreateRequest;
import com.femsq.web.api.dto.OgUpdateRequest;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

/**
 * Тесты для {@link OgMapper}.
 */
class OgMapperTest {

    private final OgMapper mapper = new OgMapper();

    @Test
    void toDtoCopiesAllFields() {
        Og og = new Og(1, "short", "official", "full", "description",
                1234567890d, 1234567890d, 1234567890d, 1234567890d, 10, "OG");

        var dto = mapper.toDto(og);

        assertEquals(og.ogKey(), dto.ogKey());
        assertEquals(og.ogName(), dto.ogName());
        assertEquals(og.ogOfficialName(), dto.ogOfficialName());
        assertEquals(og.ogFullName(), dto.ogFullName());
        assertEquals(og.ogDescription(), dto.ogDescription());
        assertEquals(og.inn(), dto.inn());
        assertEquals(og.kpp(), dto.kpp());
        assertEquals(og.ogrn(), dto.ogrn());
        assertEquals(og.okpo(), dto.okpo());
        assertEquals(og.oe(), dto.oe());
        assertEquals("OG", dto.registrationTaxType());
    }

    @Test
    void toDomainCreateNormalizesTaxType() {
        var request = new OgCreateRequest("short", "official", null, null,
                null, null, null, null, null, " OG ");

        Og og = mapper.toDomain(request);

        assertNull(og.ogKey());
        assertEquals("short", og.ogName());
        assertEquals("official", og.ogOfficialName());
        assertEquals("og", og.registrationTaxType());
    }

    @Test
    void toDomainUpdatePreservesIdentifier() {
        var request = new OgUpdateRequest("short", "official", "full", "descr",
                1d, 2d, 3d, 4d, 5, "SD");

        Og og = mapper.toDomain(42, request);

        assertEquals(42, og.ogKey());
        assertEquals("sd", og.registrationTaxType());
    }
}
