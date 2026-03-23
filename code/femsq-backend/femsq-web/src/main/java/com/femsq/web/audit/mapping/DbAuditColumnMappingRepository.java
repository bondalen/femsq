package com.femsq.web.audit.mapping;

import com.femsq.database.model.RaColMap;
import com.femsq.database.model.RaSheetConf;
import com.femsq.database.service.RaColMapService;
import com.femsq.database.service.RaSheetConfService;
import java.util.List;
import java.util.Objects;
import org.springframework.stereotype.Repository;

/**
 * Реализация {@link AuditColumnMappingRepository} через SQL Server-таблицы конфигурации.
 */
@Repository
public class DbAuditColumnMappingRepository implements AuditColumnMappingRepository {

    private final RaSheetConfService raSheetConfService;
    private final RaColMapService raColMapService;

    public DbAuditColumnMappingRepository(RaSheetConfService raSheetConfService, RaColMapService raColMapService) {
        this.raSheetConfService = Objects.requireNonNull(raSheetConfService, "raSheetConfService");
        this.raColMapService = Objects.requireNonNull(raColMapService, "raColMapService");
    }

    @Override
    public List<RaSheetConf> getSheetConfigs(int fileType) {
        return raSheetConfService.getByFileType(fileType);
    }

    @Override
    public List<RaColMap> getColumnMappings(int sheetConfKey) {
        return raColMapService.getBySheetConfKey(sheetConfKey);
    }
}
