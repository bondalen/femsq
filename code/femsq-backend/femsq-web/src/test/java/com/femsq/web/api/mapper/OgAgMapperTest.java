package com.femsq.web.api.mapper;

import com.femsq.database.model.OgAg;
import com.femsq.web.api.dto.OgAgCreateRequest;
import com.femsq.web.api.dto.OgAgUpdateRequest;
import java.util.UUID;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

/**
 * Тесты для {@link OgAgMapper}.
 */
class OgAgMapperTest {

    private final OgAgMapper mapper = new OgAgMapper();

    @Test
    void toDtoCopiesFields() {
        UUID legacy = UUID.randomUUID();
        OgAg ogAg = new OgAg(7, "AG-1", 3, legacy);

        var dto = mapper.toDto(ogAg);

        assertEquals(ogAg.ogAgKey(), dto.ogAgKey());
        assertEquals("AG-1", dto.code());
        assertEquals(3, dto.organizationKey());
        assertEquals(legacy, dto.legacyOid());
    }

    @Test
    void toDomainCreateSetsNullId() {
        UUID legacy = UUID.randomUUID();
        var request = new OgAgCreateRequest("AG-2", 11, legacy);

        OgAg ogAg = mapper.toDomain(request);

        assertNull(ogAg.ogAgKey());
        assertEquals("AG-2", ogAg.code());
        assertEquals(11, ogAg.organizationKey());
        assertEquals(legacy, ogAg.legacyOid());
    }

    @Test
    void toDomainUpdateSetsIdentifier() {
        var request = new OgAgUpdateRequest("AG-3", 15, null);

        OgAg ogAg = mapper.toDomain(21, request);

        assertEquals(21, ogAg.ogAgKey());
        assertEquals("AG-3", ogAg.code());
        assertEquals(15, ogAg.organizationKey());
        assertNull(ogAg.legacyOid());
    }
}
