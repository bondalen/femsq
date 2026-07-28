package com.femsq.database.service;

import com.femsq.database.model.RaReport;
import java.util.Optional;

/**
 * Сервис отчётов {@code ags.ra}.
 */
public interface RaReportService {

    Optional<RaReport> getById(int raKey);

    RaReport create(RaReport report);

    RaReport update(RaReport report);

    boolean delete(int raKey);
}
