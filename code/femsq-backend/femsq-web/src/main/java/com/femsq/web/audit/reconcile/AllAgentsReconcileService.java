package com.femsq.web.audit.reconcile;

import com.femsq.database.connection.ConnectionFactory;
import com.femsq.web.audit.AuditExecutionContext;
import com.femsq.web.audit.AuditLogLevel;
import com.femsq.web.audit.AuditLogScope;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.LocalDate;
import java.util.HashSet;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.logging.Logger;
import org.springframework.stereotype.Service;

/**
 * Reconcile для type=5 (AllAgents): ветка RA (ОА / ОА прочие), ветка изменений RC (ОА изм) — read-model по {@code ra_ImpNewQuRa} / {@code ra_ImpNewQuRc}.
 */
@Service
public class AllAgentsReconcileService extends AbstractTransactionalReconcileService {

    private static final Logger log = Logger.getLogger(AllAgentsReconcileService.class.getName());
    private static final int TYPE_ALL_AGENTS = 5;
    // 1.5.1: идемпотентность apply через marker-таблицу на exec_key + step_code
    private static final String MARKER_TABLE = "ags.ra_reconcile_marker";
    private static final String STEP_APPLY_RA = "TYPE5_APPLY_RA";
    private static final String STEP_APPLY_RC = "TYPE5_APPLY_RC";
    private static final String STEP_DELETE_RA = "TYPE5_DELETE_RA";
    private static final String STEP_DELETE_RC = "TYPE5_DELETE_RC";
    private static final String SIMULATE_FAILURE_STEP_PROP = "femsq.reconcile.type5.simulateFailureStep";

    /** В БД колонки {@code ra_change}/{@code ra_chSmLt} используют кириллическую «с» (U+0441), не латинскую «c». */
    private static final String RC_COL_RA_FK = "[ra\u0441_ra]";
    private static final String RC_COL_NUM = "[ra\u0441_num]";
    private static final String RC_COL_DATE = "[ra\u0441_date]";
    private static final String RACS_FK_RAC = "[ra\u0441s_ra\u0441]";
    private static final String RACS_TOTAL = "[ra\u0441s_total]";
    private static final String RACS_WORK = "[ra\u0441s_work]";
    private static final String RACS_EQUIP = "[ra\u0441s_equip]";
    private static final String RACS_OTHERS = "[ra\u0441s_others]";
    private static final String RACS_DATE = "[ra\u0441s_date]";
    private static final boolean ENABLE_DELETES = Boolean.parseBoolean(
            System.getProperty("femsq.reconcile.type5.enableDeletes", "false"));
    /** Цвет акцента для summary RA/RC (SCR-002-A/B/C, Crimson). */
    private static final String HTML_CRIMSON_SUMMARY = "#DC143C";
    /** SCR-002-B: несовпадение поля — «старое» в БД. */
    private static final String HTML_CRIMSON_FIELD = "#DC143C";
    /** SCR-002-B: ожидаемое значение из источника. */
    private static final String HTML_PERU_EXPECTED = "#CD853F";
    /** SCR-002-B: значение после обновления. */
    private static final String HTML_SEA_GREEN = "#2E8B57";

    public AllAgentsReconcileService(ConnectionFactory connectionFactory) {
        super(connectionFactory);
    }

    @Override
    public boolean supports(int fileType) {
        return fileType == TYPE_ALL_AGENTS;
    }

    @Override
    protected ReconcileResult reconcileInTransaction(Connection connection, ReconcileContext context) throws SQLException {
        List<StagingRaRow> stagingRowsData = loadStagingRows(connection, context.executionKey());
        LookupCaches lookupCaches = loadLookupCaches(connection);
        LookupResolutionResult lookupResult = resolveLookupKeys(stagingRowsData, lookupCaches);
        LookupResolutionStats lookupStats = lookupResult.stats();
        CanonicalKeyStats canonicalKeyStats = buildCanonicalKeyStats(stagingRowsData, lookupResult.byRowKey());
        RaReadModelResult readModelResult = buildRaReadModel(connection, stagingRowsData, lookupResult.byRowKey(), context);
        RaReadModelStats readModelStats = readModelResult.stats();
        // RC read-model строим позже:
        // - в dry-run можно строить сразу
        // - в apply: после того, как RA применён (чтобы RC видел созданные base RA по (ra_period, ra_num))
        RcChangeReadModelResult rcReadModelResult = new RcChangeReadModelResult(
                new RcChangeReadModelStats(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                List.of(),
                List.of()
        );
        RcChangeReadModelStats rcReadStats = rcReadModelResult.stats();
        MissingLookupDiagnostics missingDiagnostics = buildMissingLookupDiagnostics(stagingRowsData, lookupResult.byRowKey());
        int stagingRows = stagingRowsData.size();
        int validationErrors = validateRequiredFields(stagingRowsData);
        int unsupportedSign = countUnsupportedSign(stagingRowsData);
        int inserted = 0;
        int updated = 0;
        int unchanged = readModelStats.categoryUnchanged();
        int sumInserted = 0;
        int sumUnchangedSkipped = 0;
        int skipped = Math.max(stagingRows - validationErrors - unsupportedSign - canonicalKeyStats.invalidKeyRows(), 0);
        int errors = validationErrors;
        boolean applyRequested = context.addRa();
        // VBA semantics for type=5: row-level reject, not global apply blocker.
        boolean applyBlocked = false;
        boolean dryRun = !applyRequested;
        appendType5ModeAndRaRowsAuditLog(context, readModelStats.considered(), applyRequested);
        int rcChangesInserted = 0;
        int rcSumsInserted = 0;
        int rcChangesUpdated = 0;
        int rcSumsInsertedChanged = 0;
        int rcSumsUnchangedSkipped = 0;
        int rcNewPlanned = 0;
        int rcChangedPlanned = 0;
        RaDeletePlan raDeletePlan = planRaDeletes(connection, stagingRowsData, lookupResult.byRowKey());
        appendRaExcessItemsAudit(context, raDeletePlan);
        // rcDeletePlan зависит от domainRcByKey, который для apply нужно грузить после RA apply.
        RcDeletePlan rcDeletePlan = new RcDeletePlan(List.of(), 0);
        int raDeleted = 0;
        int rcDeleted = 0;
        boolean raStepAlreadyDone = false;
        boolean rcStepAlreadyDone = false;
        boolean raDeleteAlreadyDone = false;
        boolean rcDeleteAlreadyDone = false;
        if (dryRun) {
            Map<PeriodRaNumKey, List<Long>> raByPeriodAndNum = loadRaKeysByPeriodAndRaNum(connection);
            Map<RcChangeMatchKey, List<DomainRcChangeRow>> domainRcByKey = loadDomainRcChangeRows(connection);
            rcReadModelResult = buildRcChangeReadModel(
                    stagingRowsData,
                    lookupResult.byRowKey(),
                    lookupCaches,
                    raByPeriodAndNum,
                    domainRcByKey
            );
            rcReadStats = rcReadModelResult.stats();
            appendRcRowsSummaryAuditLog(context, rcReadStats.rcRowsConsidered());
            rcNewPlanned = rcReadModelResult.newRows().size();
            rcChangedPlanned = rcReadModelResult.changedRows().size();
            rcDeletePlan = planRcDeletes(
                    stagingRowsData,
                    lookupResult.byRowKey(),
                    lookupCaches,
                    raByPeriodAndNum,
                    domainRcByKey
            );
            DryRunStats dryRunStats = estimateDryRunStats(connection, readModelResult);
            inserted = dryRunStats.inserted();
            updated = dryRunStats.updated();
            sumInserted = dryRunStats.sumInserted();
            sumUnchangedSkipped = dryRunStats.sumUnchangedSkipped();
        } else if (!applyBlocked) {
            // 1.5.1: идемпотентность apply через marker-таблицу на exec_key + step_code.
            ensureMarkerTableExists(connection);
            long execKey = context.executionKey();
            raStepAlreadyDone = markerStepExists(connection, execKey, TYPE_ALL_AGENTS, STEP_APPLY_RA);
            rcStepAlreadyDone = markerStepExists(connection, execKey, TYPE_ALL_AGENTS, STEP_APPLY_RC);
            if (ENABLE_DELETES) {
                raDeleteAlreadyDone = markerStepExists(connection, execKey, TYPE_ALL_AGENTS, STEP_DELETE_RA);
                rcDeleteAlreadyDone = markerStepExists(connection, execKey, TYPE_ALL_AGENTS, STEP_DELETE_RC);
            }

            if (!raStepAlreadyDone) {
                InsertNewRaResult insertResult = insertNewRaRows(connection, context, readModelResult.newRows());
                inserted = insertResult.insertedCount();
                updated = updateChangedRaRows(connection, context, readModelResult.changedRows());
                SumEvolutionStats sumStats = evolveRaSums(
                        connection,
                        context,
                        readModelResult.newRows(),
                        insertResult.insertedRows(),
                        readModelResult.changedRows()
                );
                sumInserted = sumStats.inserted();
                sumUnchangedSkipped = sumStats.unchangedSkipped();
                markMarkerDone(connection, execKey, TYPE_ALL_AGENTS, STEP_APPLY_RA, null);
                maybeSimulateFailure(STEP_APPLY_RA);
            }

            // После apply RA обновляем кэши, которые нужны для RC сопоставления/удалений.
            Map<PeriodRaNumKey, List<Long>> raByPeriodAndNum = loadRaKeysByPeriodAndRaNum(connection);
            Map<RcChangeMatchKey, List<DomainRcChangeRow>> domainRcByKey = loadDomainRcChangeRows(connection);
            rcReadModelResult = buildRcChangeReadModel(
                    stagingRowsData,
                    lookupResult.byRowKey(),
                    lookupCaches,
                    raByPeriodAndNum,
                    domainRcByKey
            );
            rcReadStats = rcReadModelResult.stats();
            appendRcRowsSummaryAuditLog(context, rcReadStats.rcRowsConsidered());
            rcNewPlanned = rcReadModelResult.newRows().size();
            rcChangedPlanned = rcReadModelResult.changedRows().size();
            rcDeletePlan = planRcDeletes(
                    stagingRowsData,
                    lookupResult.byRowKey(),
                    lookupCaches,
                    raByPeriodAndNum,
                    domainRcByKey
            );

            if (!rcStepAlreadyDone) {
                // 1.3.2: создание записей ветки RC только для NEW-строк (когда rac_key отсутствует).
                RcChangeApplyStats rcApplyStats = insertNewRcChanges(connection, rcReadModelResult.newRows());
                rcChangesInserted = rcApplyStats.rcChangesInserted();
                rcSumsInserted = rcApplyStats.rcSumsInserted();

                // 1.3.3: обновление существующих записей ветки RC для CHANGED-строк.
                RcChangeUpdateStats rcUpdateStats = updateChangedRcChanges(connection, rcReadModelResult.changedRows());
                rcChangesUpdated = rcUpdateStats.rcChangesUpdated();
                rcSumsInsertedChanged = rcUpdateStats.rcSumsInserted();
                rcSumsUnchangedSkipped = rcUpdateStats.rcSumsUnchangedSkipped();
                markMarkerDone(connection, execKey, TYPE_ALL_AGENTS, STEP_APPLY_RC, null);
                maybeSimulateFailure(STEP_APPLY_RC);
            }

            if (ENABLE_DELETES) {
                if (!raDeleteAlreadyDone) {
                    raDeleted = applyRaDeletes(connection, raDeletePlan.raKeysToDelete());
                    markMarkerDone(connection, execKey, TYPE_ALL_AGENTS, STEP_DELETE_RA, null);
                }
                if (!rcDeleteAlreadyDone) {
                    rcDeleted = applyRcDeletes(connection, rcDeletePlan.racKeysToDelete());
                    markMarkerDone(connection, execKey, TYPE_ALL_AGENTS, STEP_DELETE_RC, null);
                }
            }
        }

        String counters = formatCounters(
                stagingRows,
                inserted,
                updated,
                unchanged,
                skipped,
                unsupportedSign,
                errors,
                canonicalKeyStats,
                lookupStats,
                readModelStats,
                rcReadStats,
                applyRequested,
                applyBlocked,
                dryRun,
                sumInserted,
                sumUnchangedSkipped
        );
        counters = counters + ", rcChangesInserted=" + rcChangesInserted + ", rcSumsInserted=" + rcSumsInserted;
        counters = counters + ", rcChangesUpdated=" + rcChangesUpdated
                + ", rcSumsInsertedChanged=" + rcSumsInsertedChanged
                + ", rcSumsUnchangedSkipped=" + rcSumsUnchangedSkipped;
        counters = counters + ", rcApplyPlannedNew=" + rcNewPlanned
                + ", rcApplyPlannedChanged=" + rcChangedPlanned;
        counters = counters + ", rcApplyDeltaNew=" + (rcStepAlreadyDone ? 0 : (rcNewPlanned - rcChangesInserted))
                + ", rcApplyDeltaChanged=" + (rcStepAlreadyDone ? 0 : (rcChangedPlanned - rcChangesUpdated));
        counters = counters + ", marker_raStepAlreadyDone=" + raStepAlreadyDone
                + ", marker_rcStepAlreadyDone=" + rcStepAlreadyDone
                + ", marker_raDeleteAlreadyDone=" + raDeleteAlreadyDone
                + ", marker_rcDeleteAlreadyDone=" + rcDeleteAlreadyDone;
        counters = counters + ", deleteEnabled=" + ENABLE_DELETES
                + ", raDeletePlanned=" + raDeletePlan.planned()
                + ", raDeleteApplied=" + raDeleted
                + ", raDeleteSkippedAmbiguous=" + raDeletePlan.skippedAmbiguous()
                + ", rcDeletePlanned=" + rcDeletePlan.planned()
                + ", rcDeleteApplied=" + rcDeleted
                + ", rcDeleteSkippedAmbiguous=" + rcDeletePlan.skippedAmbiguous();
        String missingDetails = formatMissingDetails(missingDiagnostics);
        String blockingReason = "";
        String diagnostics = counters + blockingReason + ", " + missingDetails;
        log.info("[Reconcile][type=5] execKey=" + context.executionKey() + ", " + counters);
        Type5ReconcileAuditCounters type5AuditCounters = buildType5ReconcileAuditCounters(
                readModelStats,
                rcReadStats,
                inserted,
                updated,
                unchanged,
                raDeleted,
                rcChangesInserted,
                rcChangesUpdated,
                rcDeleted,
                sumInserted,
                rcSumsInserted,
                rcSumsInsertedChanged
        );
        if (applyRequested && !applyBlocked) {
            return ReconcileResult.applied(inserted + updated, "type=5 apply-partial; " + diagnostics, type5AuditCounters);
        }
        return ReconcileResult.skipped("type=5 apply-skipped; " + diagnostics, type5AuditCounters);
    }

    private List<StagingRaRow> loadStagingRows(Connection connection, long executionKey) throws SQLException {
        String sql = """
                SELECT
                    rain_key,
                    rainRaNum,
                    rainRaDate,
                    rainCstAgPnStr,
                    rainSender,
                    rainSign,
                    rainTtl,
                    rainWork,
                    rainEquip,
                    rainOthers,
                    rainArrivedNum,
                    rainArrivedDate,
                    rainArrivedDateFact,
                    rainReturnedNum,
                    rainReturnedDate,
                    rainReturnedReason,
                    rainSendNum,
                    rainSendDate
                FROM ags.ra_stg_ra
                WHERE rain_exec_key = ?
                ORDER BY rain_key
                """;
        List<StagingRaRow> rows = new ArrayList<>();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, executionKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    rows.add(new StagingRaRow(
                            resultSet.getLong("rain_key"),
                            resultSet.getString("rainRaNum"),
                            resultSet.getDate("rainRaDate") != null ? resultSet.getDate("rainRaDate").toLocalDate() : null,
                            resultSet.getString("rainCstAgPnStr"),
                            resultSet.getString("rainSender"),
                            resultSet.getString("rainSign"),
                            resultSet.getBigDecimal("rainTtl"),
                            resultSet.getBigDecimal("rainWork"),
                            resultSet.getBigDecimal("rainEquip"),
                            resultSet.getBigDecimal("rainOthers"),
                            resultSet.getString("rainArrivedNum"),
                            toLocalDate(resultSet, "rainArrivedDate"),
                            toLocalDate(resultSet, "rainArrivedDateFact"),
                            resultSet.getString("rainReturnedNum"),
                            toLocalDate(resultSet, "rainReturnedDate"),
                            resultSet.getString("rainReturnedReason"),
                            resultSet.getString("rainSendNum"),
                            toLocalDate(resultSet, "rainSendDate")
                    ));
                }
                return rows;
            }
        }
    }

    private LocalDate toLocalDate(ResultSet resultSet, String column) throws SQLException {
        return resultSet.getDate(column) != null ? resultSet.getDate(column).toLocalDate() : null;
    }

    private CanonicalKeyStats buildCanonicalKeyStats(List<StagingRaRow> rows, Map<Long, ResolvedLookupKeys> byRowKey) {
        int valid = 0;
        int invalid = 0;
        for (StagingRaRow row : rows) {
            if (toCanonicalMatchKey(row, byRowKey.get(row.key())) == null) {
                invalid++;
            } else {
                valid++;
            }
        }
        return new CanonicalKeyStats(valid, invalid);
    }

    /**
     * 1.1.2 Lookup-resolving для staging-строк:
     * - periodKey: rainRaDate -> ags_ra_period.rap_datePeriod
     * - cstapKey : rainCstAgPnStr -> ags.cstAgPn.cstapIpgPnN
     * - ogKey    : rainSender -> ags.ogNmF_allVariantsNoRepeat.ogNm255
     */
    private LookupResolutionResult resolveLookupKeys(List<StagingRaRow> rows, LookupCaches caches) {
        int resolvedAll = 0;
        int missingPeriod = 0;
        int missingCst = 0;
        int missingOg = 0;
        Map<Long, ResolvedLookupKeys> byRowKey = new HashMap<>();
        for (StagingRaRow row : rows) {
            Integer periodKey = resolvePeriodKey(row.raDate(), caches.periodByDate());
            Integer cstapKey = resolveTextKey(row.cstAgPnStr(), caches.cstapByCode());
            Integer ogKey = resolveOgKey(row.sender(), caches.ogByName());
            byRowKey.put(row.key(), new ResolvedLookupKeys(periodKey, cstapKey, ogKey));
            if (periodKey == null) {
                missingPeriod++;
            }
            if (cstapKey == null) {
                missingCst++;
            }
            if (ogKey == null) {
                missingOg++;
            }
            if (periodKey != null && cstapKey != null && ogKey != null) {
                resolvedAll++;
            }
        }
        return new LookupResolutionResult(
                new LookupResolutionStats(
                        resolvedAll,
                        missingPeriod,
                        missingCst,
                        missingOg,
                        caches.periodAmbiguous(),
                        caches.cstapAmbiguous(),
                        caches.ogAmbiguous()
                ),
                byRowKey
        );
    }

    private LookupCaches loadLookupCaches(Connection connection) throws SQLException {
        LookupCacheLoadResult periodResult = loadPeriodLookup(connection);
        LookupCacheLoadResult cstResult = loadTextLookup(connection, """
                SELECT cstapKey, cstapIpgPnN
                FROM ags.cstAgPn
                """);
        LookupCacheLoadResult ogResult = loadTextLookup(connection, """
                SELECT ogKey, ogNm255
                FROM ags.ogNmF_allVariantsNoRepeat
                """);
        Map<LocalDate, Integer> periodByDate = new HashMap<>();
        for (Map.Entry<String, Integer> entry : periodResult.values().entrySet()) {
            periodByDate.put(LocalDate.parse(entry.getKey()), entry.getValue());
        }
        return new LookupCaches(
                periodByDate,
                cstResult.values(),
                ogResult.values(),
                periodResult.ambiguousCount(),
                cstResult.ambiguousCount(),
                ogResult.ambiguousCount()
        );
    }

    private LookupCacheLoadResult loadPeriodLookup(Connection connection) throws SQLException {
        String sql = """
                SELECT [key], rap_datePeriod
                FROM ags.ra_period
                """;
        Map<String, Integer> values = new HashMap<>();
        int ambiguous = 0;
        try (PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            while (resultSet.next()) {
                int key = resultSet.getInt(1);
                LocalDate periodDate = resultSet.getDate(2) != null ? resultSet.getDate(2).toLocalDate() : null;
                if (periodDate == null) {
                    continue;
                }
                String normalized = periodDate.toString();
                Integer existing = values.putIfAbsent(normalized, key);
                if (existing != null && existing != key) {
                    ambiguous++;
                }
            }
        }
        return new LookupCacheLoadResult(values, ambiguous);
    }

    private LookupCacheLoadResult loadTextLookup(Connection connection, String sql) throws SQLException {
        Map<String, Integer> values = new HashMap<>();
        int ambiguous = 0;
        try (PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            while (resultSet.next()) {
                int key = resultSet.getInt(1);
                String normalized = trimToNull(resultSet.getString(2));
                if (normalized == null) {
                    continue;
                }
                Integer existing = values.putIfAbsent(normalized, key);
                if (existing != null && existing != key) {
                    ambiguous++;
                }
            }
        }
        return new LookupCacheLoadResult(values, ambiguous);
    }

    private Integer resolvePeriodKey(LocalDate raDate, Map<LocalDate, Integer> periodByDate) {
        return periodByDate.get(periodDateOfDate(raDate));
    }

    private Integer resolveTextKey(String raw, Map<String, Integer> byNormalizedText) {
        String normalized = trimToNull(raw);
        if (normalized == null) {
            return null;
        }
        return byNormalizedText.get(normalized);
    }

    private Integer resolveOgKey(String rawSender, Map<String, Integer> bySenderVariant) {
        String normalized = trimToNull(rawSender);
        if (normalized == null) {
            return null;
        }
        // Access query ra_ImpNewQu resolves sender via ogNm variants; summary rows must not map.
        if ("Итог".equalsIgnoreCase(normalized)) {
            return null;
        }
        return bySenderVariant.get(normalized);
    }

    private RaReadModelResult buildRaReadModel(
            Connection connection,
            List<StagingRaRow> rows,
            Map<Long, ResolvedLookupKeys> byRowKey,
            ReconcileContext context
    ) throws SQLException {
        Map<CanonicalMatchKey, List<DomainRaRow>> domainByKey = loadDomainRaRows(connection);
        List<NewRaRow> newRows = new ArrayList<>();
        List<ChangedRaRow> changedRows = new ArrayList<>();
        int considered = 0;
        int filteredSign = 0;
        int invalid = 0;
        int matchedSingle = 0;
        int matchedAmbiguous = 0;
        int missing = 0;
        int unchanged = 0;
        int changed = 0;
        int categoryNew = 0;
        int categoryChanged = 0;
        int categoryUnchanged = 0;
        int categoryAmbiguous = 0;
        int categoryInvalid = 0;
        /** Нет канонического ключа (raNum/lookup): ошибка качества данных для RA-apply. */
        int rejectedInvalidCanonical = 0;
        /** Знак не ОА/ОА прочие при валидном ключе: ошибка качества; не путать с FILTERED_TO_RC (ОА изм). */
        int rejectedDisallowedSign = 0;
        for (StagingRaRow row : rows) {
            String sign = trimToNull(row.sign());
            if ("ОА изм".equals(sign)) {
                filteredSign++;
                continue;
            }
            considered++;
            CanonicalMatchKey canonical = toCanonicalMatchKey(row, byRowKey.get(row.key()));
            if (canonical == null) {
                invalid++;
                categoryInvalid++;
                rejectedInvalidCanonical++;
                appendRaValidationFail(context, row, "INVALID_CANONICAL_KEY", describeMissingCanonicalParts(row, byRowKey.get(row.key())));
                continue;
            }
            if (!isAllowedRaSign(sign)) {
                invalid++;
                categoryInvalid++;
                rejectedDisallowedSign++;
                appendRaValidationFail(context, row, "DISALLOWED_SIGN", "Знак «" + escapeHtml(trimToNull(sign)) + "» не допускается для ветки RA (ожидаются ОА / ОА прочие).");
                continue;
            }
            List<DomainRaRow> candidates = domainByKey.get(canonical);
            if (candidates == null || candidates.isEmpty()) {
                missing++;
                categoryNew++;
                newRows.add(new NewRaRow(row, byRowKey.get(row.key())));
                continue;
            }
            if (candidates.size() > 1) {
                matchedAmbiguous++;
                categoryAmbiguous++;
                appendRaValidationFail(context, row, "AMBIGUOUS_MATCH",
                        "Найдено " + candidates.size() + " записей ags.ra по ключу (отправитель, стройка, период, номер).");
                continue;
            }
            matchedSingle++;
            DomainRaRow domain = candidates.get(0);
            if (isSameAsSource(domain, row, byRowKey.get(row.key()))) {
                unchanged++;
                categoryUnchanged++;
            } else {
                changed++;
                categoryChanged++;
                changedRows.add(new ChangedRaRow(domain.raKey(), domain, row));
            }
        }
        int rowsEligible = categoryNew + categoryChanged;
        int rejectedAmbiguous = categoryAmbiguous;
        int rejectedFilteredToRc = filteredSign;
        int rowsRejected =
                rejectedFilteredToRc + rejectedInvalidCanonical + rejectedDisallowedSign + rejectedAmbiguous;
        return new RaReadModelResult(
                new RaReadModelStats(
                        considered,
                        filteredSign,
                        invalid,
                        matchedSingle,
                        matchedAmbiguous,
                        missing,
                        unchanged,
                        changed,
                        categoryNew,
                        categoryChanged,
                        categoryUnchanged,
                        categoryAmbiguous,
                        categoryInvalid,
                        rowsEligible,
                        rowsRejected,
                        rejectedFilteredToRc,
                        rejectedInvalidCanonical,
                        rejectedDisallowedSign,
                        rejectedAmbiguous
                ),
                newRows,
                changedRows
        );
    }

    private InsertNewRaResult insertNewRaRows(Connection connection, ReconcileContext context, List<NewRaRow> newRows)
            throws SQLException {
        if (newRows.isEmpty()) {
            return new InsertNewRaResult(0, List.of());
        }
        // 1.5.2: защититься от дублей на уровне SQL при insert-ветке RA.
        // read-model для NEW-строк ищет ags.ra по (ra_period, ra_num), поэтому guard делаем по этим ключам.
        String sql = """
                INSERT INTO ags.ra (
                    ra_num, ra_date, ra_cac, ra_type, ra_work_type, ra_period,
                    ra_arrived, ra_arrived_date, ra_arrived_dateFact,
                    ra_returned, ra_returned_date, ra_returnedReason,
                    ra_sent, ra_sent_date,
                    ra_note_t, ra_created, ra_org_sender, ra_note
                )
                OUTPUT INSERTED.ra_key
                SELECT
                    ?, ?, ?, ?, NULL, ?,
                    ?, ?, ?,
                    ?, ?, ?,
                    ?, ?,
                    NULL, ?, ?,
                    NULL
                WHERE NOT EXISTS (
                    SELECT 1 FROM ags.ra r
                    WHERE r.ra_period = ? AND r.ra_num = ?
                )
                """;

        String selectExistingRaKeySql = """
                SELECT TOP 1 ra_key
                FROM ags.ra
                WHERE ra_period = ? AND ra_num = ?
                ORDER BY ra_key DESC
                """;
        int inserted = 0;
        List<InsertedRaRow> insertedRows = new ArrayList<>();
        try (PreparedStatement statement = connection.prepareStatement(sql);
             PreparedStatement selectExistingRaKey = connection.prepareStatement(selectExistingRaKeySql)) {
            Timestamp now = new Timestamp(System.currentTimeMillis());
            for (NewRaRow row : newRows) {
                ResolvedLookupKeys keys = row.lookupKeys();
                StagingRaRow source = row.stagingRow();
                String raNum = trimToNull(source.raNum());
                Integer raPeriod = keys.periodKey();
                String raType = mapToDomainRaType(source.sign());

                // SELECT part
                statement.setString(1, raNum);
                statement.setObject(2, source.raDate());
                statement.setInt(3, keys.cstapKey());
                statement.setString(4, raType);
                statement.setInt(5, raPeriod);
                statement.setString(6, trimToNull(source.arrivedNum()));
                statement.setObject(7, source.arrivedDate());
                statement.setObject(8, source.arrivedDateFact());
                statement.setString(9, trimToNull(source.returnedNum()));
                statement.setObject(10, source.returnedDate());
                statement.setString(11, trimToNull(source.returnedReason()));
                statement.setString(12, trimToNull(source.sendNum()));
                statement.setObject(13, source.sendDate());
                statement.setTimestamp(14, now);
                statement.setInt(15, keys.ogKey());

                // WHERE NOT EXISTS part
                statement.setInt(16, raPeriod);
                statement.setString(17, raNum);
                try (ResultSet resultSet = statement.executeQuery()) {
                    if (resultSet.next()) {
                        inserted++;
                        long raKey = resultSet.getLong(1);
                        insertedRows.add(new InsertedRaRow(raKey, source));
                        appendRaNewCreatedAudit(context, source, keys, raKey, true);
                    } else {
                        // Уже существует (SQL-idempotency). Разрешим ra_key, чтобы всё равно корректно эволюционировать суммы.
                        selectExistingRaKey.setInt(1, raPeriod);
                        selectExistingRaKey.setString(2, raNum);
                        try (ResultSet rs = selectExistingRaKey.executeQuery()) {
                            if (rs.next()) {
                                long raKey = rs.getLong(1);
                                insertedRows.add(new InsertedRaRow(raKey, source));
                                appendRaNewCreatedAudit(context, source, keys, raKey, false);
                            }
                        }
                    }
                }
            }
        }
        return new InsertNewRaResult(inserted, insertedRows);
    }

    private int updateChangedRaRows(Connection connection, ReconcileContext context, List<ChangedRaRow> changedRows)
            throws SQLException {
        if (changedRows.isEmpty()) {
            return 0;
        }
        String sql = """
                UPDATE ags.ra
                SET
                    ra_type = ?,
                    ra_date = ?,
                    ra_arrived = ?,
                    ra_arrived_date = ?,
                    ra_arrived_dateFact = ?,
                    ra_returned = ?,
                    ra_returned_date = ?,
                    ra_returnedReason = ?,
                    ra_sent = ?,
                    ra_sent_date = ?
                WHERE ra_key = ?
                """;
        int updated = 0;
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            for (ChangedRaRow row : changedRows) {
                StagingRaRow source = row.stagingRow();
                DomainRaRow domainBefore = row.domainBefore();
                statement.setString(1, mapToDomainRaType(source.sign()));
                statement.setObject(2, source.raDate());
                statement.setString(3, trimToNull(source.arrivedNum()));
                statement.setObject(4, source.arrivedDate());
                statement.setObject(5, source.arrivedDateFact());
                statement.setString(6, trimToNull(source.returnedNum()));
                statement.setObject(7, source.returnedDate());
                statement.setString(8, trimToNull(source.returnedReason()));
                statement.setString(9, trimToNull(source.sendNum()));
                statement.setObject(10, source.sendDate());
                statement.setLong(11, row.raKey());
                int n = statement.executeUpdate();
                updated += n;
                if (n > 0) {
                    appendRaFieldMismatchAndUpdatedAudit(context, domainBefore, source, row.raKey());
                }
            }
        }
        return updated;
    }

    private SumEvolutionStats evolveRaSums(
            Connection connection,
            ReconcileContext context,
            List<NewRaRow> newRaRows,
            List<InsertedRaRow> insertedRows,
            List<ChangedRaRow> changedRows
    ) throws SQLException {
        int inserted = 0;
        int unchangedSkipped = 0;
        String selectLatestSql = """
                SELECT TOP 1 ras_total, ras_work, ras_equip, ras_others
                FROM ags.ra_summ
                WHERE ras_ra = ?
                ORDER BY ras_date DESC, ras_key DESC
                """;
        String insertSql = """
                INSERT INTO ags.ra_summ (ras_ra, ras_total, ras_work, ras_equip, ras_others, ras_date)
                VALUES (?, ?, ?, ?, ?, ?)
                """;
        try (PreparedStatement selectLatest = connection.prepareStatement(selectLatestSql);
             PreparedStatement insertStatement = connection.prepareStatement(insertSql)) {
            Timestamp now = new Timestamp(System.currentTimeMillis());
            for (int i = 0; i < insertedRows.size(); i++) {
                InsertedRaRow row = insertedRows.get(i);
                NewRaRow newRa = newRaRows.get(i);
                RaSummUpsertOutcome outcome = upsertRaSummForRowWithOutcome(
                        selectLatest, insertStatement, now, row.raKey(), row.stagingRow());
                if (outcome.versionInserted()) {
                    inserted++;
                    appendRaNewSumsAudit(context, newRa.stagingRow(), row.raKey(), outcome);
                } else {
                    unchangedSkipped++;
                }
            }
            for (ChangedRaRow row : changedRows) {
                RaSummUpsertOutcome outcome = upsertRaSummForRowWithOutcome(
                        selectLatest, insertStatement, now, row.raKey(), row.stagingRow());
                if (outcome.versionInserted()) {
                    inserted++;
                    appendRaSumMismatchAudit(context, row.stagingRow(), row.raKey(), outcome);
                } else {
                    unchangedSkipped++;
                }
            }
        }
        return new SumEvolutionStats(inserted, unchangedSkipped);
    }

    private DryRunStats estimateDryRunStats(
            Connection connection,
            RaReadModelResult readModelResult
    ) throws SQLException {
        int plannedInserted = readModelResult.newRows().size();
        int plannedUpdated = readModelResult.changedRows().size();
        int plannedSumInserted = plannedInserted;
        int plannedSumUnchangedSkipped = 0;
        for (ChangedRaRow row : readModelResult.changedRows()) {
            if (hasSameLatestSum(connection, row.raKey(), row.stagingRow())) {
                plannedSumUnchangedSkipped++;
            } else {
                plannedSumInserted++;
            }
        }
        return new DryRunStats(
                plannedInserted,
                plannedUpdated,
                plannedSumInserted,
                plannedSumUnchangedSkipped
        );
    }

    private RaSummUpsertOutcome upsertRaSummForRowWithOutcome(
            PreparedStatement selectLatest,
            PreparedStatement insertStatement,
            Timestamp now,
            long raKey,
            StagingRaRow source
    ) throws SQLException {
        selectLatest.setLong(1, raKey);
        BigDecimal dbTotal = null;
        BigDecimal dbWork = null;
        BigDecimal dbEquip = null;
        BigDecimal dbOthers = null;
        boolean hasLatest = false;
        try (ResultSet resultSet = selectLatest.executeQuery()) {
            if (resultSet.next()) {
                hasLatest = true;
                dbTotal = resultSet.getBigDecimal("ras_total");
                dbWork = resultSet.getBigDecimal("ras_work");
                dbEquip = resultSet.getBigDecimal("ras_equip");
                dbOthers = resultSet.getBigDecimal("ras_others");
            }
        }
        if (hasLatest
                && sameAmount(dbTotal, source.ttl())
                && sameAmount(dbWork, source.work())
                && sameAmount(dbEquip, source.equip())
                && sameAmount(dbOthers, source.others())) {
            return new RaSummUpsertOutcome(false, true, dbTotal, dbWork, dbEquip, dbOthers);
        }
        insertStatement.setLong(1, raKey);
        setNullableMoney(insertStatement, 2, source.ttl());
        setNullableMoney(insertStatement, 3, source.work());
        setNullableMoney(insertStatement, 4, source.equip());
        setNullableMoney(insertStatement, 5, source.others());
        insertStatement.setTimestamp(6, now);
        insertStatement.executeUpdate();
        return new RaSummUpsertOutcome(true, hasLatest, dbTotal, dbWork, dbEquip, dbOthers);
    }

    private boolean hasSameLatestSum(Connection connection, long raKey, StagingRaRow source) throws SQLException {
        String sql = """
                SELECT TOP 1 ras_total, ras_work, ras_equip, ras_others
                FROM ags.ra_summ
                WHERE ras_ra = ?
                ORDER BY ras_date DESC, ras_key DESC
                """;
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, raKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (!resultSet.next()) {
                    return false;
                }
                BigDecimal dbTotal = resultSet.getBigDecimal("ras_total");
                BigDecimal dbWork = resultSet.getBigDecimal("ras_work");
                BigDecimal dbEquip = resultSet.getBigDecimal("ras_equip");
                BigDecimal dbOthers = resultSet.getBigDecimal("ras_others");
                return sameAmount(dbTotal, source.ttl())
                        && sameAmount(dbWork, source.work())
                        && sameAmount(dbEquip, source.equip())
                        && sameAmount(dbOthers, source.others());
            }
        }
    }

    private void setNullableMoney(PreparedStatement statement, int index, BigDecimal value) throws SQLException {
        if (value == null) {
            statement.setNull(index, Types.DECIMAL);
            return;
        }
        statement.setBigDecimal(index, value);
    }

    private Map<CanonicalMatchKey, List<DomainRaRow>> loadDomainRaRows(Connection connection) throws SQLException {
        String sql = """
                SELECT
                    r.ra_key,
                    r.ra_org_sender,
                    r.ra_cac,
                    r.ra_period,
                    r.ra_num,
                    r.ra_type,
                    r.ra_date,
                    r.ra_arrived,
                    r.ra_arrived_date,
                    r.ra_arrived_dateFact,
                    r.ra_returned,
                    r.ra_returned_date,
                    r.ra_returnedReason,
                    r.ra_sent,
                    r.ra_sent_date,
                    s.ras_total,
                    s.ras_work,
                    s.ras_equip,
                    s.ras_others
                FROM ags.ra AS r
                LEFT JOIN ags.raSmLt AS s ON s.ras_ra = r.ra_key
                """;
        Map<CanonicalMatchKey, List<DomainRaRow>> byKey = new HashMap<>();
        try (PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            while (resultSet.next()) {
                CanonicalMatchKey key = new CanonicalMatchKey(
                        resultSet.getInt("ra_org_sender"),
                        resultSet.getInt("ra_cac"),
                        resultSet.getInt("ra_period"),
                        trimToNull(resultSet.getString("ra_num"))
                );
                DomainRaRow row = new DomainRaRow(
                        resultSet.getLong("ra_key"),
                        trimToNull(resultSet.getString("ra_type")),
                        toLocalDate(resultSet, "ra_date"),
                        trimToNull(resultSet.getString("ra_arrived")),
                        toLocalDate(resultSet, "ra_arrived_date"),
                        toLocalDate(resultSet, "ra_arrived_dateFact"),
                        trimToNull(resultSet.getString("ra_returned")),
                        toLocalDate(resultSet, "ra_returned_date"),
                        trimToNull(resultSet.getString("ra_returnedReason")),
                        trimToNull(resultSet.getString("ra_sent")),
                        toLocalDate(resultSet, "ra_sent_date"),
                        resultSet.getBigDecimal("ras_total"),
                        resultSet.getBigDecimal("ras_work"),
                        resultSet.getBigDecimal("ras_equip"),
                        resultSet.getBigDecimal("ras_others")
                );
                byKey.computeIfAbsent(key, ignored -> new ArrayList<>()).add(row);
            }
        }
        return byKey;
    }

    private boolean isSameAsSource(DomainRaRow domain, StagingRaRow source, ResolvedLookupKeys keys) {
        if (keys == null || keys.ogKey() == null) {
            return false;
        }
        if (!equalsNullable(domain.raType(), trimToNull(source.sign()))) {
            return false;
        }
        if (!equalsNullable(domain.raDate(), source.raDate())) {
            return false;
        }
        if (!equalsNullable(domain.arrived(), trimToNull(source.arrivedNum()))) {
            return false;
        }
        if (!equalsNullable(domain.arrivedDate(), source.arrivedDate())) {
            return false;
        }
        if (!equalsNullable(domain.arrivedDateFact(), source.arrivedDateFact())) {
            return false;
        }
        if (!equalsNullable(domain.returned(), trimToNull(source.returnedNum()))) {
            return false;
        }
        if (!equalsNullable(domain.returnedDate(), source.returnedDate())) {
            return false;
        }
        if (!equalsNullable(domain.returnedReason(), trimToNull(source.returnedReason()))) {
            return false;
        }
        if (!equalsNullable(domain.sent(), trimToNull(source.sendNum()))) {
            return false;
        }
        if (!equalsNullable(domain.sentDate(), source.sendDate())) {
            return false;
        }
        if (!sameAmount(domain.total(), source.ttl())) {
            return false;
        }
        if (!sameAmount(domain.work(), source.work())) {
            return false;
        }
        if (!sameAmount(domain.equip(), source.equip())) {
            return false;
        }
        return sameAmount(domain.others(), source.others());
    }

    private boolean sameAmount(BigDecimal left, BigDecimal right) {
        BigDecimal nLeft = left == null ? BigDecimal.ZERO : left;
        BigDecimal nRight = right == null ? BigDecimal.ZERO : right;
        return nLeft.compareTo(nRight) == 0;
    }

    private <T> boolean equalsNullable(T left, T right) {
        return Objects.equals(left, right);
    }

    /**
     * 1.1.1 Канонический ключ матчинга для type=5:
     * (ra_org_sender, ra_cac, ra_period, ra_num)
     * где:
     * - ra_org_sender <= ogKey (resolved sender key)
     * - ra_cac        <= cstapKey (resolved construction key)
     * - ra_period     <= periodKey (resolved period key)
     * - ra_num        <= trimToNull(rainRaNum)
     */
    private CanonicalMatchKey toCanonicalMatchKey(StagingRaRow row, ResolvedLookupKeys resolvedLookupKeys) {
        if (resolvedLookupKeys == null) {
            return null;
        }
        String raNum = trimToNull(row.raNum());
        Integer senderKey = resolvedLookupKeys.ogKey();
        Integer cacKey = resolvedLookupKeys.cstapKey();
        Integer periodKey = resolvedLookupKeys.periodKey();
        if (senderKey == null || cacKey == null || periodKey == null || raNum == null) {
            return null;
        }
        return new CanonicalMatchKey(senderKey, cacKey, periodKey, raNum);
    }

    private int validateRequiredFields(List<StagingRaRow> rows) {
        int errors = 0;
        for (StagingRaRow row : rows) {
            if (trimToNull(row.raNum()) == null) {
                errors++;
            }
        }
        return errors;
    }

    private int countUnsupportedSign(List<StagingRaRow> rows) {
        int unsupported = 0;
        for (StagingRaRow row : rows) {
            String sign = trimToNull(row.sign());
            if (sign == null) {
                continue;
            }
            if (!"ОА".equals(sign) && !"ОА прочие".equals(sign) && !"ОА изм".equals(sign)) {
                unsupported++;
            }
        }
        return unsupported;
    }

    private LocalDate periodDateOfDate(LocalDate date) {
        if (date == null) {
            return null;
        }
        if (date.getDayOfMonth() < 16) {
            return date.withDayOfMonth(15);
        }
        return date.withDayOfMonth(date.lengthOfMonth());
    }

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private boolean isAllowedRaSign(String sign) {
        return "ОА".equals(sign) || "ОА прочие".equals(sign);
    }

    private static String mapToDomainRaType(String sign) {
        if ("ОА прочие".equals(sign)) {
            return "ОА, прочие";
        }
        return sign;
    }

    /**
     * 1.3.1 Read-model для ветки изменений (аналог {@code ra_ImpNewQuRc}): парсинг {@code rainRaNum}, поиск {@code ags.ra}
     * по {@code (ra_period, ra_num)}, сопоставление с {@code ags.ra_change} по {@code (ra_period, raс_ra, raс_num)} и сверка полей со staging.
     */
    private Map<PeriodRaNumKey, List<Long>> loadRaKeysByPeriodAndRaNum(Connection connection) throws SQLException {
        String sql = """
                SELECT r.ra_key, r.ra_period, r.ra_num
                FROM ags.ra r
                """;
        Map<PeriodRaNumKey, List<Long>> byKey = new HashMap<>();
        try (PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            while (resultSet.next()) {
                String raNum = trimToNull(resultSet.getString("ra_num"));
                if (raNum == null) {
                    continue;
                }
                PeriodRaNumKey key = new PeriodRaNumKey(resultSet.getInt("ra_period"), raNum);
                long raKey = resultSet.getLong("ra_key");
                byKey.computeIfAbsent(key, ignored -> new ArrayList<>()).add(raKey);
            }
        }
        return byKey;
    }

    private Map<RcChangeMatchKey, List<DomainRcChangeRow>> loadDomainRcChangeRows(Connection connection) throws SQLException {
        String sql = "SELECT c.rac_key, c." + RC_COL_RA_FK + " AS rac_ra_fk, c." + RC_COL_NUM + " AS rac_change_num, c.ra_period, "
                + "c." + RC_COL_DATE + " AS rac_rc_date, c.ra_org_sender, c.ra_arrived, c.ra_arrived_date, c.ra_arrived_dateFact, "
                + "c.ra_returned, c.ra_returned_date, c.ra_returnedReason, c.ra_sent, c.ra_sent_date, "
                + "s." + RACS_TOTAL + " AS racs_total, s." + RACS_WORK + " AS racs_work, s." + RACS_EQUIP + " AS racs_equip, s."
                + RACS_OTHERS + " AS racs_others "
                + "FROM ags.ra_change c "
                + "LEFT JOIN ags.ra_chSmLt s ON c.rac_key = s." + RACS_FK_RAC;
        Map<RcChangeMatchKey, List<DomainRcChangeRow>> byKey = new HashMap<>();
        try (PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            while (resultSet.next()) {
                String changeNum = normalizeRcChangeNumKey(resultSet.getString("rac_change_num"));
                RcChangeMatchKey key = new RcChangeMatchKey(
                        resultSet.getInt("ra_period"),
                        resultSet.getLong("rac_ra_fk"),
                        changeNum
                );
                DomainRcChangeRow row = new DomainRcChangeRow(
                        resultSet.getLong("rac_key"),
                        resultSet.getLong("rac_ra_fk"),
                        changeNum,
                        resultSet.getInt("ra_period"),
                        toLocalDate(resultSet, "rac_rc_date"),
                        resultSet.getInt("ra_org_sender"),
                        trimToNull(resultSet.getString("ra_arrived")),
                        toLocalDate(resultSet, "ra_arrived_date"),
                        toLocalDate(resultSet, "ra_arrived_dateFact"),
                        trimToNull(resultSet.getString("ra_returned")),
                        toLocalDate(resultSet, "ra_returned_date"),
                        trimToNull(resultSet.getString("ra_returnedReason")),
                        trimToNull(resultSet.getString("ra_sent")),
                        toLocalDate(resultSet, "ra_sent_date"),
                        resultSet.getBigDecimal("racs_total"),
                        resultSet.getBigDecimal("racs_work"),
                        resultSet.getBigDecimal("racs_equip"),
                        resultSet.getBigDecimal("racs_others")
                );
                byKey.computeIfAbsent(key, ignored -> new ArrayList<>()).add(row);
            }
        }
        return byKey;
    }

    private static String normalizeRcChangeNumKey(String raw) {
        String t = raw == null ? "" : raw.trim();
        if (t.isEmpty()) {
            return "";
        }
        // Канонизируем числовые значения, чтобы "01" и "1" считались одним изменением.
        if (t.matches("\\d{1,9}")) {
            try {
                return String.valueOf(Long.parseLong(t));
            } catch (NumberFormatException ignored) {
                // fall through
            }
        }
        return t;
    }

    private RcChangeReadModelResult buildRcChangeReadModel(
            List<StagingRaRow> rows,
            Map<Long, ResolvedLookupKeys> byRowKey,
            LookupCaches lookupCaches,
            Map<PeriodRaNumKey, List<Long>> raByPeriodAndNum,
            Map<RcChangeMatchKey, List<DomainRcChangeRow>> domainRcByKey
    ) {
        int considered = 0;
        int parseInvalid = 0;
        int missingRcPeriod = 0;
        int missingReportPeriod = 0;
        int missingLookupForCompare = 0;
        int missingBaseRa = 0;
        int ambiguousBaseRa = 0;
        int ambiguousRac = 0;
        int categoryNew = 0;
        int categoryUnchanged = 0;
        int categoryChanged = 0;
        List<RcNewApplyRow> newRows = new ArrayList<>();
        List<RcChangedApplyRow> changedRows = new ArrayList<>();
        Map<LocalDate, Integer> periodByDate = lookupCaches.periodByDate();
        for (StagingRaRow row : rows) {
            if (!"ОА изм".equals(trimToNull(row.sign()))) {
                continue;
            }
            considered++;
            Optional<RcStagingLineParser.ParsedRcLine> parsedOpt = RcStagingLineParser.parse(row.raNum());
            if (parsedOpt.isEmpty()) {
                parseInvalid++;
                continue;
            }
            RcStagingLineParser.ParsedRcLine parsed = parsedOpt.get();
            Integer rcPeriod = resolvePeriodKey(row.raDate(), periodByDate);
            if (rcPeriod == null) {
                missingRcPeriod++;
                continue;
            }
            Integer reportPeriodKey = resolvePeriodKey(parsed.reportDate(), periodByDate);
            if (reportPeriodKey == null) {
                missingReportPeriod++;
                continue;
            }
            String reportNum = trimToNull(parsed.reportNumber());
            if (reportNum == null) {
                missingBaseRa++;
                continue;
            }
            PeriodRaNumKey raLookup = new PeriodRaNumKey(reportPeriodKey, reportNum);
            List<Long> raKeys = raByPeriodAndNum.getOrDefault(raLookup, List.of());
            if (raKeys.isEmpty()) {
                missingBaseRa++;
                continue;
            }
            if (raKeys.size() > 1) {
                ambiguousBaseRa++;
                continue;
            }
            long raKey = raKeys.get(0);
            ResolvedLookupKeys keys = byRowKey.get(row.key());
            if (keys == null || keys.ogKey() == null) {
                missingLookupForCompare++;
                continue;
            }
            String changeNumKey = normalizeRcChangeNumKey(String.valueOf(parsed.changeNumber()));
            RcChangeMatchKey rcKey = new RcChangeMatchKey(rcPeriod, raKey, changeNumKey);
            List<DomainRcChangeRow> racList = domainRcByKey.getOrDefault(rcKey, List.of());
            if (racList.isEmpty()) {
                categoryNew++;
                newRows.add(new RcNewApplyRow(
                        raKey,
                        rcPeriod,
                        changeNumKey,
                        row.raDate(),
                        keys.ogKey(),
                        trimToNull(row.arrivedNum()),
                        row.arrivedDate(),
                        row.arrivedDateFact(),
                        trimToNull(row.returnedNum()),
                        row.returnedDate(),
                        trimToNull(row.returnedReason()),
                        trimToNull(row.sendNum()),
                        row.sendDate(),
                        row.ttl(),
                        row.work(),
                        row.equip(),
                        row.others()
                ));
                continue;
            }
            if (racList.size() > 1) {
                ambiguousRac++;
                continue;
            }
            DomainRcChangeRow domain = racList.get(0);
            if (isRcRowMatchingStaging(domain, row, keys)) {
                categoryUnchanged++;
            } else {
                categoryChanged++;
                changedRows.add(new RcChangedApplyRow(
                        domain.racKey(),
                        raKey,
                        rcPeriod,
                        changeNumKey,
                        row.raDate(),
                        keys.ogKey(),
                        trimToNull(row.arrivedNum()),
                        row.arrivedDate(),
                        row.arrivedDateFact(),
                        trimToNull(row.returnedNum()),
                        row.returnedDate(),
                        trimToNull(row.returnedReason()),
                        trimToNull(row.sendNum()),
                        row.sendDate(),
                        row.ttl(),
                        row.work(),
                        row.equip(),
                        row.others()
                ));
            }
        }
        RcChangeReadModelStats stats = new RcChangeReadModelStats(
                considered,
                parseInvalid,
                missingRcPeriod,
                missingReportPeriod,
                missingLookupForCompare,
                missingBaseRa,
                ambiguousBaseRa,
                ambiguousRac,
                categoryNew,
                categoryUnchanged,
                categoryChanged
        );
        return new RcChangeReadModelResult(stats, newRows, changedRows);
    }

    /**
     * 1.3.2 Создание `ags.ra_change` + одной версии сумм в `ags.ra_change_summ` для NEW-строк RC.
     * <p>
     * {@code ags.ra_chSmLt} является {@code VIEW}, поэтому запись всегда делается в базовую таблицу истории
     * {@code ags.ra_change_summ}.
     * </p>
     */
    private RcChangeApplyStats insertNewRcChanges(Connection connection, List<RcNewApplyRow> newRows)
            throws SQLException {
        if (newRows == null || newRows.isEmpty()) {
            return new RcChangeApplyStats(0, 0);
        }

        String insertRcSql = """
                INSERT INTO ags.ra_change (
                    ra_period, %s, %s, %s,
                    ra_arrived, ra_arrived_date, ra_arrived_dateFact,
                    ra_returned, ra_returned_date, ra_returnedReason,
                    ra_sent, ra_sent_date,
                    ra_note_t, ra_created, ra_org_sender, ra_note
                )
                OUTPUT INSERTED.rac_key
                SELECT
                    ?, ?, ?, ?,
                    ?, ?, ?,
                    ?, ?, ?,
                    ?, ?,
                    NULL, ?, ?,
                    NULL
                WHERE NOT EXISTS (
                    SELECT 1 FROM ags.ra_change c
                    WHERE c.ra_period = ?
                      AND c.%s = ?
                      AND c.%s = ?
                )
                """.formatted(RC_COL_RA_FK, RC_COL_NUM, RC_COL_DATE, RC_COL_RA_FK, RC_COL_NUM);

        String selectRacKeySql = """
                SELECT TOP 1 rac_key
                FROM ags.ra_change
                WHERE ra_period = ?
                  AND %s = ?
                  AND %s = ?
                ORDER BY rac_key DESC
                """.formatted(RC_COL_RA_FK, RC_COL_NUM);

        Timestamp now = new Timestamp(System.currentTimeMillis());
        int rcChangesInserted = 0;
        int rcSumsInserted = 0;
        int rcSumsSkipped = 0;

        try (PreparedStatement insertRc = connection.prepareStatement(insertRcSql);
             PreparedStatement selectRacKey = connection.prepareStatement(selectRacKeySql)) {
            for (RcNewApplyRow row : newRows) {
                int idx = 1;
                insertRc.setInt(idx++, row.raPeriod());
                insertRc.setLong(idx++, row.raFk());
                insertRc.setString(idx++, row.changeNum());
                insertRc.setObject(idx++, row.rcDate());

                insertRc.setString(idx++, row.arrived());
                insertRc.setObject(idx++, row.arrivedDate());
                insertRc.setObject(idx++, row.arrivedDateFact());

                insertRc.setString(idx++, row.returned());
                insertRc.setObject(idx++, row.returnedDate());
                insertRc.setString(idx++, row.returnedReason());

                insertRc.setString(idx++, row.sent());
                insertRc.setObject(idx++, row.sentDate());

                // ra_created, ra_org_sender.
                insertRc.setTimestamp(idx++, now);
                insertRc.setInt(idx++, row.raOrgSender());

                // WHERE NOT EXISTS keys.
                insertRc.setInt(idx++, row.raPeriod());
                insertRc.setLong(idx++, row.raFk());
                insertRc.setString(idx++, row.changeNum());

                try (ResultSet rs = insertRc.executeQuery()) {
                    Long racKey;
                    if (rs.next()) {
                        racKey = rs.getLong(1);
                        rcChangesInserted++;
                    } else {
                        // Already exists (idempotency). Resolve rac_key and still apply sum evolution (1.3.4).
                        selectRacKey.setInt(1, row.raPeriod());
                        selectRacKey.setLong(2, row.raFk());
                        selectRacKey.setString(3, row.changeNum());
                        try (ResultSet rsk = selectRacKey.executeQuery()) {
                            racKey = rsk.next() ? rsk.getLong(1) : null;
                        }
                    }
                    if (racKey == null) {
                        continue;
                    }

                    boolean inserted = evolveRcSums(connection, racKey, row.total(), row.work(), row.equip(), row.others(), now);
                    if (inserted) {
                        rcSumsInserted++;
                    } else {
                        rcSumsSkipped++;
                    }
                }
            }
        }

        return new RcChangeApplyStats(rcChangesInserted, rcSumsInserted);
    }

    /**
     * 1.3.3 Обновление существующих строк `ags.ra_change` + эволюция сумм в `ags.ra_change_summ` только при отличии от latest.
     */
    private RcChangeUpdateStats updateChangedRcChanges(Connection connection, List<RcChangedApplyRow> changedRows)
            throws SQLException {
        if (changedRows == null || changedRows.isEmpty()) {
            return new RcChangeUpdateStats(0, 0, 0);
        }

        String updateSql = """
                UPDATE ags.ra_change
                SET
                    %s = ?,
                    ra_org_sender = ?,
                    ra_arrived = ?,
                    ra_arrived_date = ?,
                    ra_arrived_dateFact = ?,
                    ra_returned = ?,
                    ra_returned_date = ?,
                    ra_returnedReason = ?,
                    ra_sent = ?,
                    ra_sent_date = ?
                WHERE rac_key = ?
                """.formatted(RC_COL_DATE);

        int updated = 0;
        int sumsInserted = 0;
        int sumsUnchangedSkipped = 0;
        Timestamp now = new Timestamp(System.currentTimeMillis());

        try (PreparedStatement updateStmt = connection.prepareStatement(updateSql);
             PreparedStatement ignored = connection.prepareStatement("SELECT 1")) {
            for (RcChangedApplyRow row : changedRows) {
                int idx = 1;
                updateStmt.setObject(idx++, row.rcDate());
                updateStmt.setInt(idx++, row.raOrgSender());
                updateStmt.setString(idx++, row.arrived());
                updateStmt.setObject(idx++, row.arrivedDate());
                updateStmt.setObject(idx++, row.arrivedDateFact());
                updateStmt.setString(idx++, row.returned());
                updateStmt.setObject(idx++, row.returnedDate());
                updateStmt.setString(idx++, row.returnedReason());
                updateStmt.setString(idx++, row.sent());
                updateStmt.setObject(idx++, row.sentDate());
                updateStmt.setLong(idx++, row.racKey());
                updated += updateStmt.executeUpdate();

                boolean inserted = evolveRcSums(connection, row.racKey(), row.total(), row.work(), row.equip(), row.others(), now);
                if (inserted) {
                    sumsInserted++;
                } else {
                    sumsUnchangedSkipped++;
                }
            }
        }

        return new RcChangeUpdateStats(updated, sumsInserted, sumsUnchangedSkipped);
    }

    /**
     * 1.3.4 Эволюция сумм RC: вставить новую версию в {@code ags.ra_change_summ} только если отличается от latest.
     * Latest читается через {@code ags.ra_chSmLt} (это VIEW).
     */
    private boolean evolveRcSums(
            Connection connection,
            long racKey,
            BigDecimal total,
            BigDecimal work,
            BigDecimal equip,
            BigDecimal others,
            Timestamp now
    ) throws SQLException {
        String selectLatestSumSql = """
                SELECT %s AS total, %s AS work, %s AS equip, %s AS others
                FROM ags.ra_chSmLt
                WHERE %s = ?
                """.formatted(RACS_TOTAL, RACS_WORK, RACS_EQUIP, RACS_OTHERS, RACS_FK_RAC);
        String insertSumSql = """
                INSERT INTO ags.ra_change_summ (
                    %s, %s, %s, %s, %s, %s
                ) VALUES (?, ?, ?, ?, ?, ?)
                """.formatted(RACS_FK_RAC, RACS_TOTAL, RACS_WORK, RACS_EQUIP, RACS_OTHERS, RACS_DATE);

        BigDecimal dbTotal = null;
        BigDecimal dbWork = null;
        BigDecimal dbEquip = null;
        BigDecimal dbOthers = null;
        boolean hasLatest = false;
        try (PreparedStatement selectLatest = connection.prepareStatement(selectLatestSumSql)) {
            selectLatest.setLong(1, racKey);
            try (ResultSet rs = selectLatest.executeQuery()) {
                if (rs.next()) {
                    hasLatest = true;
                    dbTotal = rs.getBigDecimal("total");
                    dbWork = rs.getBigDecimal("work");
                    dbEquip = rs.getBigDecimal("equip");
                    dbOthers = rs.getBigDecimal("others");
                }
            }
        }
        if (hasLatest
                && sameAmount(dbTotal, total)
                && sameAmount(dbWork, work)
                && sameAmount(dbEquip, equip)
                && sameAmount(dbOthers, others)) {
            return false;
        }
        try (PreparedStatement insertSum = connection.prepareStatement(insertSumSql)) {
            insertSum.setLong(1, racKey);
            setNullableMoney(insertSum, 2, total);
            setNullableMoney(insertSum, 3, work);
            setNullableMoney(insertSum, 4, equip);
            setNullableMoney(insertSum, 5, others);
            insertSum.setTimestamp(6, now);
            insertSum.executeUpdate();
            return true;
        }
    }

    /**
     * 1.4.1 Планирование delete-ветки RA: доменные строки, которые есть в БД, но отсутствуют в текущем источнике (staging) для exec_key.
     * <p>Delete применяется только при {@code addRa=true} и включённом флаге {@link #ENABLE_DELETES}.</p>
     */
    private RaDeletePlan planRaDeletes(
            Connection connection,
            List<StagingRaRow> rows,
            Map<Long, ResolvedLookupKeys> byRowKey
    ) throws SQLException {
        // Source set: только кондиционные строки RA-ветки (ОА/ОА прочие) с валидным canonical key.
        Set<CanonicalMatchKey> sourceKeys = new HashSet<>();
        Set<Integer> sourcePeriods = new HashSet<>();
        for (StagingRaRow row : rows) {
            String sign = trimToNull(row.sign());
            if (!isAllowedRaSign(sign)) {
                continue;
            }
            CanonicalMatchKey key = toCanonicalMatchKey(row, byRowKey.get(row.key()));
            if (key == null) {
                continue;
            }
            sourceKeys.add(key);
            sourcePeriods.add(key.raPeriod());
        }

        // Domain set, grouped by canonical key.
        Map<CanonicalMatchKey, List<DomainRaRow>> domainByKey = loadDomainRaRows(connection);

        List<RaExcessPlanned> excessItems = new ArrayList<>();
        int skippedAmbiguous = 0;
        for (Map.Entry<CanonicalMatchKey, List<DomainRaRow>> entry : domainByKey.entrySet()) {
            CanonicalMatchKey key = entry.getKey();
            if (!sourcePeriods.contains(key.raPeriod())) {
                continue; // out of current exec_key scope
            }
            if (sourceKeys.contains(key)) {
                continue; // present in source
            }
            List<DomainRaRow> candidates = entry.getValue();
            if (candidates.size() != 1) {
                skippedAmbiguous++;
                continue;
            }
            Integer period = key.raPeriod();
            if (period == null) {
                continue;
            }
            excessItems.add(new RaExcessPlanned(candidates.get(0).raKey(), period, key.raNum()));
        }

        return new RaDeletePlan(excessItems, skippedAmbiguous);
    }

    /**
     * 1.4.2 Планирование delete-ветки RC: доменные изменения, которые есть в БД, но отсутствуют в текущем источнике (staging) для exec_key.
     */
    private RcDeletePlan planRcDeletes(
            List<StagingRaRow> rows,
            Map<Long, ResolvedLookupKeys> byRowKey,
            LookupCaches lookupCaches,
            Map<PeriodRaNumKey, List<Long>> raByPeriodAndNum,
            Map<RcChangeMatchKey, List<DomainRcChangeRow>> domainRcByKey
    ) {
        Set<RcChangeMatchKey> sourceKeys = new HashSet<>();
        Set<Integer> rcPeriodsInSource = new HashSet<>();
        Map<LocalDate, Integer> periodByDate = lookupCaches.periodByDate();
        for (StagingRaRow row : rows) {
            if (!"ОА изм".equals(trimToNull(row.sign()))) {
                continue;
            }
            Optional<RcStagingLineParser.ParsedRcLine> parsedOpt = RcStagingLineParser.parse(row.raNum());
            if (parsedOpt.isEmpty()) {
                continue;
            }
            RcStagingLineParser.ParsedRcLine parsed = parsedOpt.get();
            Integer rcPeriod = resolvePeriodKey(row.raDate(), periodByDate);
            if (rcPeriod == null) {
                continue;
            }
            Integer reportPeriodKey = resolvePeriodKey(parsed.reportDate(), periodByDate);
            if (reportPeriodKey == null) {
                continue;
            }
            String reportNum = trimToNull(parsed.reportNumber());
            if (reportNum == null) {
                continue;
            }
            PeriodRaNumKey raLookup = new PeriodRaNumKey(reportPeriodKey, reportNum);
            List<Long> raKeys = raByPeriodAndNum.getOrDefault(raLookup, List.of());
            if (raKeys.size() != 1) {
                continue;
            }
            long raKey = raKeys.get(0);
            String changeNumKey = normalizeRcChangeNumKey(String.valueOf(parsed.changeNumber()));
            sourceKeys.add(new RcChangeMatchKey(rcPeriod, raKey, changeNumKey));
            rcPeriodsInSource.add(rcPeriod);
        }

        List<Long> racKeysToDelete = new ArrayList<>();
        int skippedAmbiguous = 0;
        for (Map.Entry<RcChangeMatchKey, List<DomainRcChangeRow>> entry : domainRcByKey.entrySet()) {
            RcChangeMatchKey key = entry.getKey();
            if (!rcPeriodsInSource.contains(key.rcPeriod())) {
                continue;
            }
            if (sourceKeys.contains(key)) {
                continue;
            }
            List<DomainRcChangeRow> candidates = entry.getValue();
            if (candidates.size() != 1) {
                skippedAmbiguous++;
                continue;
            }
            racKeysToDelete.add(candidates.get(0).racKey());
        }

        return new RcDeletePlan(racKeysToDelete, skippedAmbiguous);
    }

    private int applyRcDeletes(Connection connection, List<Long> racKeys) throws SQLException {
        if (racKeys == null || racKeys.isEmpty()) {
            return 0;
        }
        int deleted = 0;
        String delSums = "DELETE FROM ags.ra_change_summ WHERE " + RACS_FK_RAC + " = ?";
        String delRc = "DELETE FROM ags.ra_change WHERE rac_key = ?";
        try (PreparedStatement psSums = connection.prepareStatement(delSums);
             PreparedStatement psRc = connection.prepareStatement(delRc)) {
            for (Long racKey : racKeys) {
                psSums.setLong(1, racKey);
                psSums.executeUpdate();
                psRc.setLong(1, racKey);
                deleted += psRc.executeUpdate();
            }
        }
        return deleted;
    }

    private int applyRaDeletes(Connection connection, List<Long> raKeys) throws SQLException {
        if (raKeys == null || raKeys.isEmpty()) {
            return 0;
        }
        int deleted = 0;
        String delRcSumsByRa = "DELETE s FROM ags.ra_change_summ s INNER JOIN ags.ra_change c ON s."
                + RACS_FK_RAC + " = c.rac_key WHERE c." + RC_COL_RA_FK + " = ?";
        String delRcByRa = "DELETE FROM ags.ra_change WHERE " + RC_COL_RA_FK + " = ?";
        String delRaSums = "DELETE FROM ags.ra_summ WHERE ras_ra = ?";
        String delRa = "DELETE FROM ags.ra WHERE ra_key = ?";
        try (PreparedStatement psRcSums = connection.prepareStatement(delRcSumsByRa);
             PreparedStatement psRc = connection.prepareStatement(delRcByRa);
             PreparedStatement psRaSums = connection.prepareStatement(delRaSums);
             PreparedStatement psRa = connection.prepareStatement(delRa)) {
            for (Long raKey : raKeys) {
                psRcSums.setLong(1, raKey);
                psRcSums.executeUpdate();
                psRc.setLong(1, raKey);
                psRc.executeUpdate();
                psRaSums.setLong(1, raKey);
                psRaSums.executeUpdate();
                psRa.setLong(1, raKey);
                deleted += psRa.executeUpdate();
            }
        }
        return deleted;
    }

    private void ensureMarkerTableExists(Connection connection) throws SQLException {
        String sql = """
                IF OBJECT_ID(N'%s', N'U') IS NULL
                BEGIN
                    CREATE TABLE %s (
                        rm_key BIGINT IDENTITY(1,1) PRIMARY KEY,
                        exec_key BIGINT NOT NULL,
                        file_type INT NOT NULL,
                        step_code NVARCHAR(64) NOT NULL,
                        created_at DATETIME2 NOT NULL CONSTRAINT DF_ra_reconcile_marker_created_at DEFAULT SYSUTCDATETIME(),
                        details NVARCHAR(4000) NULL
                    );
                    CREATE UNIQUE INDEX UX_ra_reconcile_marker_exec_step
                        ON %s(exec_key, file_type, step_code);
                    CREATE INDEX IX_ra_reconcile_marker_created_at
                        ON %s(created_at);
                END
                """.formatted(MARKER_TABLE, MARKER_TABLE, MARKER_TABLE, MARKER_TABLE);
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.execute();
        }
    }

    private void maybeSimulateFailure(String stepCode) throws SQLException {
        String configured = System.getProperty(SIMULATE_FAILURE_STEP_PROP, "");
        if (configured == null || configured.isBlank()) {
            return;
        }
        if (configured.equals(stepCode)) {
            throw new SQLException("Simulated failure for " + stepCode + " (prop " + SIMULATE_FAILURE_STEP_PROP + ")");
        }
    }

    private boolean markerStepExists(Connection connection, long execKey, int fileType, String stepCode) throws SQLException {
        String sql = "SELECT 1 FROM " + MARKER_TABLE + " WHERE exec_key = ? AND file_type = ? AND step_code = ?";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setLong(1, execKey);
            ps.setInt(2, fileType);
            ps.setString(3, stepCode);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private void markMarkerDone(Connection connection, long execKey, int fileType, String stepCode, String details) throws SQLException {
        String sql = """
                MERGE %s AS t
                USING (SELECT ? AS exec_key, ? AS file_type, ? AS step_code, ? AS details) s
                    ON t.exec_key = s.exec_key AND t.file_type = s.file_type AND t.step_code = s.step_code
                WHEN NOT MATCHED THEN
                    INSERT (exec_key, file_type, step_code, details)
                    VALUES (s.exec_key, s.file_type, s.step_code, s.details);
                """.formatted(MARKER_TABLE);

        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setLong(1, execKey);
            ps.setInt(2, fileType);
            ps.setString(3, stepCode);
            if (details == null) {
                ps.setNull(4, Types.VARCHAR);
            } else {
                ps.setString(4, details);
            }
            ps.execute();
        }
    }

    /**
     * Кандидаты на удаление RA: ключ + идентификаторы для row-level аудита {@code RA_EXCESS_ITEM}.
     */
    private record RaExcessPlanned(long raKey, int raPeriod, String raNum) {
    }

    private record RaDeletePlan(List<RaExcessPlanned> excessItems, int skippedAmbiguous) {
        List<Long> raKeysToDelete() {
            if (excessItems == null || excessItems.isEmpty()) {
                return List.of();
            }
            return excessItems.stream().map(RaExcessPlanned::raKey).toList();
        }

        int planned() {
            return excessItems == null ? 0 : excessItems.size();
        }
    }

    private record RcDeletePlan(List<Long> racKeysToDelete, int skippedAmbiguous) {
        int planned() {
            return racKeysToDelete == null ? 0 : racKeysToDelete.size();
        }
    }

    /**
     * Сверка полей изменения с листом (как {@code rs*} в {@code ra_ImpNewQuRc}), включая суммы из {@code ra_chSmLt}.
     */
    private boolean isRcRowMatchingStaging(DomainRcChangeRow domain, StagingRaRow source, ResolvedLookupKeys keys) {
        if (!Objects.equals(domain.raOrgSender(), keys.ogKey())) {
            return false;
        }
        if (!equalsNullable(domain.rcDate(), source.raDate())) {
            return false;
        }
        if (!equalsNullable(domain.arrived(), trimToNull(source.arrivedNum()))) {
            return false;
        }
        if (!equalsNullable(domain.arrivedDate(), source.arrivedDate())) {
            return false;
        }
        if (!equalsNullable(domain.arrivedDateFact(), source.arrivedDateFact())) {
            return false;
        }
        if (!equalsNullable(domain.returned(), trimToNull(source.returnedNum()))) {
            return false;
        }
        if (!equalsNullable(domain.returnedDate(), source.returnedDate())) {
            return false;
        }
        if (!equalsNullable(domain.returnedReason(), trimToNull(source.returnedReason()))) {
            return false;
        }
        if (!equalsNullable(domain.sent(), trimToNull(source.sendNum()))) {
            return false;
        }
        if (!equalsNullable(domain.sentDate(), source.sendDate())) {
            return false;
        }
        if (!sameAmount(domain.total(), source.ttl())) {
            return false;
        }
        if (!sameAmount(domain.work(), source.work())) {
            return false;
        }
        if (!sameAmount(domain.equip(), source.equip())) {
            return false;
        }
        return sameAmount(domain.others(), source.others());
    }

    /**
     * Явные MSG для журнала аудита: режим reconcile и сводка по строкам RA перед обработкой RA (1.8.11.3.1, 4.5).
     */
    private void appendType5ModeAndRaRowsAuditLog(ReconcileContext context, int raRowsConsidered, boolean addRa) {
        AuditExecutionContext audit = context.auditExecutionContext();
        if (audit == null) {
            return;
        }
        String modeToken = addRa ? "APPLY" : "DIAGNOSTIC";
        String modeHtml = addRa
                ? "<P>Режим: <b>применение</b> (addRa=true)</P>"
                : "<P>Режим: <b>диагностика</b> (addRa=false)</P>";
        audit.append(
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "RECONCILE_TYPE5_MODE",
                modeHtml,
                withPresentationMeta(
                        Map.of(
                                "auditId", String.valueOf(context.auditId()),
                                "execKey", String.valueOf(context.executionKey()),
                                "fileType", String.valueOf(context.fileType()),
                                "addRa", String.valueOf(addRa),
                                "mode", modeToken
                        ),
                        "INFO",
                        "BLUE",
                        "NORMAL"
                )
        );
        audit.append(
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "RA_ROWS_SUMMARY",
                "<P>Всего строк отчётов: <b><font color=\"" + HTML_CRIMSON_SUMMARY + "\">"
                        + raRowsConsidered + "</font></b></P>",
                withPresentationMeta(
                        Map.of(
                                "auditId", String.valueOf(context.auditId()),
                                "execKey", String.valueOf(context.executionKey()),
                                "fileType", String.valueOf(context.fileType()),
                                "raRowsCount", String.valueOf(raRowsConsidered)
                        ),
                        "INFO",
                        "CRIMSON",
                        "BOLD"
                )
        );
    }

    /**
     * Сводка по строкам изменений перед блоком RC (1.8.11.3.2).
     */
    private void appendRcRowsSummaryAuditLog(ReconcileContext context, int rcRowsConsidered) {
        AuditExecutionContext audit = context.auditExecutionContext();
        if (audit == null) {
            return;
        }
        audit.append(
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "RC_ROWS_SUMMARY",
                "<P>Всего строк изменений: <b><font color=\"" + HTML_CRIMSON_SUMMARY + "\">"
                        + rcRowsConsidered + "</font></b></P>",
                withPresentationMeta(
                        Map.of(
                                "auditId", String.valueOf(context.auditId()),
                                "execKey", String.valueOf(context.executionKey()),
                                "fileType", String.valueOf(context.fileType()),
                                "rcRowsCount", String.valueOf(rcRowsConsidered)
                        ),
                        "INFO",
                        "CRIMSON",
                        "BOLD"
                )
        );
    }

    /**
     * Row-level события аудита для ветки RA (1.8.11.5.1–5.7): NEW / validation / CHANGED поля и суммы / excess.
     * Все вызовы no-op при {@code context.auditExecutionContext() == null}.
     */
    /* ---- Row-level RA audit (1.8.11.5.1–5.7) ---- */

    private static String escapeHtml(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
    }

    private static String describeMissingCanonicalParts(StagingRaRow row, ResolvedLookupKeys keys) {
        List<String> parts = new ArrayList<>();
        if (trimToNullStatic(row.raNum()) == null) {
            parts.add("нет ra_num");
        }
        if (keys == null) {
            parts.add("lookup не разрешён");
        } else {
            if (keys.ogKey() == null) {
                parts.add("нет отправителя (og)");
            }
            if (keys.cstapKey() == null) {
                parts.add("нет стройки (cac)");
            }
            if (keys.periodKey() == null) {
                parts.add("нет периода отчёта");
            }
        }
        return parts.isEmpty() ? "неизвестная причина" : String.join("; ", parts);
    }

    private static String trimToNullStatic(String value) {
        if (value == null) {
            return null;
        }
        String t = value.trim();
        return t.isEmpty() ? null : t;
    }

    private static String formatAuditDate(LocalDate d) {
        return d == null ? "—" : d.toString();
    }

    private static String formatAuditMoney(BigDecimal v) {
        if (v == null) {
            return "—";
        }
        return v.stripTrailingZeros().toPlainString();
    }

    private static String formatAuditString(String s) {
        return s == null ? "—" : escapeHtml(s);
    }

    private void appendRaValidationFail(ReconcileContext context, StagingRaRow row, String reasonCode, String detailText) {
        AuditExecutionContext audit = context.auditExecutionContext();
        if (audit == null) {
            return;
        }
        String safeDetail = escapeHtml(detailText);
        String html = "<P>RA: отказ валидации (staging key=<b>" + row.key() + "</b>, ra_num=<b>"
                + formatAuditString(trimToNull(row.raNum())) + "</b>): <b>" + escapeHtml(reasonCode) + "</b>. "
                + safeDetail + "</P>";
        Map<String, String> meta = new HashMap<>();
        meta.put("auditId", String.valueOf(context.auditId()));
        meta.put("execKey", String.valueOf(context.executionKey()));
        meta.put("fileType", String.valueOf(context.fileType()));
        meta.put("rowIndex", String.valueOf(row.key()));
        meta.put("raNum", trimToNull(row.raNum()) == null ? "" : trimToNull(row.raNum()));
        meta.put("reason", reasonCode);
        meta.put("detail", detailText);
        audit.append(
                AuditLogLevel.WARNING,
                AuditLogScope.FILE,
                "RA_VALIDATION_FAIL",
                html,
                withPresentationMeta(meta, "WARNING", "CRIMSON", "NORMAL")
        );
    }

    private void appendRaNewCreatedAudit(
            ReconcileContext context,
            StagingRaRow source,
            ResolvedLookupKeys keys,
            long raKey,
            boolean insertedNewRow
    ) {
        AuditExecutionContext audit = context.auditExecutionContext();
        if (audit == null) {
            return;
        }
        String mode = insertedNewRow ? "Создана новая запись ags.ra" : "Запись ags.ra уже существовала (идемпотентность)";
        String html = "<P>" + mode + ": <b>ra_key=" + raKey + "</b>, staging key=" + source.key()
                + ", ra_num=<b>" + formatAuditString(trimToNull(source.raNum())) + "</b>, период="
                + (keys.periodKey() != null ? keys.periodKey() : "—")
                + ", cac=" + (keys.cstapKey() != null ? keys.cstapKey() : "—")
                + ", og=" + (keys.ogKey() != null ? keys.ogKey() : "—") + ".</P>";
        Map<String, String> meta = new HashMap<>();
        meta.put("auditId", String.valueOf(context.auditId()));
        meta.put("execKey", String.valueOf(context.executionKey()));
        meta.put("fileType", String.valueOf(context.fileType()));
        meta.put("rowIndex", String.valueOf(source.key()));
        meta.put("raKey", String.valueOf(raKey));
        meta.put("raNum", trimToNull(source.raNum()) == null ? "" : trimToNull(source.raNum()));
        meta.put("period", keys.periodKey() != null ? String.valueOf(keys.periodKey()) : "");
        meta.put("cstap", keys.cstapKey() != null ? String.valueOf(keys.cstapKey()) : "");
        meta.put("insertedNewRow", String.valueOf(insertedNewRow));
        audit.append(
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "RA_NEW_CREATED",
                html,
                withPresentationMeta(meta, "INFO", "BLUE", "NORMAL")
        );
    }

    private void appendRaNewSumsAudit(
            ReconcileContext context,
            StagingRaRow source,
            long raKey,
            RaSummUpsertOutcome outcome
    ) {
        AuditExecutionContext audit = context.auditExecutionContext();
        if (audit == null) {
            return;
        }
        String sumsLine = "итого=" + formatAuditMoney(source.ttl()) + ", работы=" + formatAuditMoney(source.work())
                + ", оборуд.=" + formatAuditMoney(source.equip()) + ", прочие=" + formatAuditMoney(source.others());
        String html;
        if (outcome.versionInserted()) {
            html = "<P>RA суммы: добавлена новая версия в ags.ra_summ для <b>ra_key=" + raKey + "</b> (staging key="
                    + source.key() + "): " + sumsLine + ".</P>";
        } else {
            html = "<P>RA суммы: совпадают с последней версией ags.ra_summ для <b>ra_key=" + raKey
                    + "</b> (staging key=" + source.key() + "), вставка пропущена: " + sumsLine + ".</P>";
        }
        Map<String, String> meta = new HashMap<>();
        meta.put("auditId", String.valueOf(context.auditId()));
        meta.put("execKey", String.valueOf(context.executionKey()));
        meta.put("fileType", String.valueOf(context.fileType()));
        meta.put("rowIndex", String.valueOf(source.key()));
        meta.put("raKey", String.valueOf(raKey));
        meta.put("ttl", formatAuditMoney(source.ttl()));
        meta.put("work", formatAuditMoney(source.work()));
        meta.put("equip", formatAuditMoney(source.equip()));
        meta.put("others", formatAuditMoney(source.others()));
        meta.put("versionInserted", String.valueOf(outcome.versionInserted()));
        audit.append(
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "RA_NEW_SUMS",
                html,
                withPresentationMeta(meta, "INFO", "BLUE", "NORMAL")
        );
    }

    private void appendRaFieldMismatchAndUpdatedAudit(ReconcileContext context, DomainRaRow d, StagingRaRow s, long raKey) {
        AuditExecutionContext audit = context.auditExecutionContext();
        if (audit == null) {
            return;
        }
        String html = buildRaFieldMismatchUpdatedParagraphHtml(raKey, d, s);
        if (html.isEmpty()) {
            return;
        }
        Map<String, String> base = new HashMap<>();
        base.put("auditId", String.valueOf(context.auditId()));
        base.put("execKey", String.valueOf(context.executionKey()));
        base.put("fileType", String.valueOf(context.fileType()));
        base.put("rowIndex", String.valueOf(s.key()));
        base.put("raKey", String.valueOf(raKey));
        base.put("fieldsTouched", listRaFieldNamesChanged(d, s));
        base.put("pairedEventKey", "RA_FIELD_UPDATED");
        audit.append(
                AuditLogLevel.WARNING,
                AuditLogScope.FILE,
                "RA_FIELD_MISMATCH",
                html,
                withPresentationMeta(new HashMap<>(base), "WARNING", "CRIMSON", "NORMAL")
        );
        Map<String, String> updatedMeta = new HashMap<>(base);
        updatedMeta.put("pairedEventKey", "RA_FIELD_MISMATCH");
        updatedMeta.put("detailInEvent", "RA_FIELD_MISMATCH");
        /* Одна визуальная <P> в RA_FIELD_MISMATCH; отдельная запись для учёта eventKey 5.5 (мета + пустой HTML). */
        audit.append(
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "RA_FIELD_UPDATED",
                "",
                withPresentationMeta(updatedMeta, "INFO", "SEA_GREEN", "NORMAL")
        );
    }

    private static String listRaFieldNamesChanged(DomainRaRow d, StagingRaRow s) {
        List<String> names = new ArrayList<>();
        if (!Objects.equals(d.raType(), mapToDomainRaType(trimToNullStatic(s.sign())))) {
            names.add("ra_type");
        }
        if (!Objects.equals(d.raDate(), s.raDate())) {
            names.add("ra_date");
        }
        if (!Objects.equals(d.arrived(), trimToNullStatic(s.arrivedNum()))) {
            names.add("ra_arrived");
        }
        if (!Objects.equals(d.arrivedDate(), s.arrivedDate())) {
            names.add("ra_arrived_date");
        }
        if (!Objects.equals(d.arrivedDateFact(), s.arrivedDateFact())) {
            names.add("ra_arrived_dateFact");
        }
        if (!Objects.equals(d.returned(), trimToNullStatic(s.returnedNum()))) {
            names.add("ra_returned");
        }
        if (!Objects.equals(d.returnedDate(), s.returnedDate())) {
            names.add("ra_returned_date");
        }
        if (!Objects.equals(d.returnedReason(), trimToNullStatic(s.returnedReason()))) {
            names.add("ra_returnedReason");
        }
        if (!Objects.equals(d.sent(), trimToNullStatic(s.sendNum()))) {
            names.add("ra_sent");
        }
        if (!Objects.equals(d.sentDate(), s.sendDate())) {
            names.add("ra_sent_date");
        }
        return String.join(",", names);
    }

    private static String buildRaFieldMismatchUpdatedParagraphHtml(long raKey, DomainRaRow d, StagingRaRow s) {
        List<String> segments = new ArrayList<>();
        addRaFieldTripleIfDiff(
                segments, "ra_type", d.raType(), mapToDomainRaType(trimToNullStatic(s.sign())));
        addRaFieldTripleIfDiff(segments, "ra_date", formatAuditDate(d.raDate()), formatAuditDate(s.raDate()));
        addRaFieldTripleIfDiff(segments, "ra_arrived", d.arrived(), trimToNullStatic(s.arrivedNum()));
        addRaFieldTripleIfDiff(segments, "ra_arrived_date", formatAuditDate(d.arrivedDate()), formatAuditDate(s.arrivedDate()));
        addRaFieldTripleIfDiff(
                segments, "ra_arrived_dateFact", formatAuditDate(d.arrivedDateFact()), formatAuditDate(s.arrivedDateFact()));
        addRaFieldTripleIfDiff(segments, "ra_returned", d.returned(), trimToNullStatic(s.returnedNum()));
        addRaFieldTripleIfDiff(segments, "ra_returned_date", formatAuditDate(d.returnedDate()), formatAuditDate(s.returnedDate()));
        addRaFieldTripleIfDiff(segments, "ra_returnedReason", d.returnedReason(), trimToNullStatic(s.returnedReason()));
        addRaFieldTripleIfDiff(segments, "ra_sent", d.sent(), trimToNullStatic(s.sendNum()));
        addRaFieldTripleIfDiff(segments, "ra_sent_date", formatAuditDate(d.sentDate()), formatAuditDate(s.sendDate()));
        if (segments.isEmpty()) {
            return "";
        }
        return "<P><b>ra_key=" + raKey + "</b> (staging key=" + s.key() + "): "
                + String.join(" ", segments) + "</P>";
    }

    private static void addRaFieldTripleIfDiff(List<String> segments, String label, String oldRaw, String newRaw) {
        String oldNorm = oldRaw == null || "—".equals(oldRaw) ? null : oldRaw;
        String newNorm = newRaw == null || "—".equals(newRaw) ? null : newRaw;
        if (Objects.equals(oldNorm, newNorm)) {
            return;
        }
        String oldDisp = oldRaw == null ? "—" : escapeHtml(oldRaw);
        String newDisp = newRaw == null ? "—" : escapeHtml(newRaw);
        segments.add(
                "<b>" + escapeHtml(label) + "</b>: БД <font color=\"" + HTML_CRIMSON_FIELD + "\">" + oldDisp
                        + "</font> ожид. <font color=\"" + HTML_PERU_EXPECTED + "\">" + newDisp
                        + "</font> → <font color=\"" + HTML_SEA_GREEN + "\">" + newDisp + "</font>");
    }

    private void appendRaSumMismatchAudit(
            ReconcileContext context,
            StagingRaRow source,
            long raKey,
            RaSummUpsertOutcome outcome
    ) {
        AuditExecutionContext audit = context.auditExecutionContext();
        if (audit == null) {
            return;
        }
        String html = "<P><b>ra_key=" + raKey + "</b> (staging key=" + source.key()
                + "): расхождение сумм — добавлена новая версия в ags.ra_summ. "
                + buildSumComponentDiffHtml("итого", outcome.oldTotal(), source.ttl())
                + " " + buildSumComponentDiffHtml("работы", outcome.oldWork(), source.work())
                + " " + buildSumComponentDiffHtml("оборуд.", outcome.oldEquip(), source.equip())
                + " " + buildSumComponentDiffHtml("прочие", outcome.oldOthers(), source.others())
                + "</P>";
        Map<String, String> meta = new HashMap<>();
        meta.put("auditId", String.valueOf(context.auditId()));
        meta.put("execKey", String.valueOf(context.executionKey()));
        meta.put("fileType", String.valueOf(context.fileType()));
        meta.put("rowIndex", String.valueOf(source.key()));
        meta.put("raKey", String.valueOf(raKey));
        meta.put("ttlOld", formatAuditMoney(outcome.oldTotal()));
        meta.put("ttlNew", formatAuditMoney(source.ttl()));
        meta.put("workOld", formatAuditMoney(outcome.oldWork()));
        meta.put("workNew", formatAuditMoney(source.work()));
        meta.put("equipOld", formatAuditMoney(outcome.oldEquip()));
        meta.put("equipNew", formatAuditMoney(source.equip()));
        meta.put("othersOld", formatAuditMoney(outcome.oldOthers()));
        meta.put("othersNew", formatAuditMoney(source.others()));
        audit.append(
                AuditLogLevel.WARNING,
                AuditLogScope.FILE,
                "RA_SUM_MISMATCH",
                html,
                withPresentationMeta(meta, "WARNING", "CRIMSON", "NORMAL")
        );
    }

    private static String buildSumComponentDiffHtml(String label, BigDecimal oldV, BigDecimal newV) {
        return "<b>" + escapeHtml(label) + "</b>: БД <font color=\"" + HTML_CRIMSON_FIELD + "\">"
                + formatAuditMoney(oldV) + "</font> → источник <font color=\"" + HTML_PERU_EXPECTED + "\">"
                + formatAuditMoney(newV) + "</font> <font color=\"" + HTML_SEA_GREEN + "\">(применено)</font>";
    }

    private void appendRaExcessItemsAudit(ReconcileContext context, RaDeletePlan plan) {
        AuditExecutionContext audit = context.auditExecutionContext();
        if (audit == null || plan.excessItems() == null || plan.excessItems().isEmpty()) {
            return;
        }
        for (RaExcessPlanned item : plan.excessItems()) {
            String raName = "RA № " + formatAuditString(item.raNum()) + ", период " + item.raPeriod();
            String html = "<P>Лишняя запись в домене (кандидат на удаление): <b>" + raName + "</b>, <b>ra_key="
                    + item.raKey() + "</b>.</P>";
            Map<String, String> meta = new HashMap<>();
            meta.put("auditId", String.valueOf(context.auditId()));
            meta.put("execKey", String.valueOf(context.executionKey()));
            meta.put("fileType", String.valueOf(context.fileType()));
            meta.put("rowIndex", "");
            meta.put("raKey", String.valueOf(item.raKey()));
            meta.put("raNum", item.raNum() == null ? "" : item.raNum());
            meta.put("raPeriod", String.valueOf(item.raPeriod()));
            meta.put("raName", "RA № " + (item.raNum() == null ? "" : item.raNum()) + ", период " + item.raPeriod());
            audit.append(
                    AuditLogLevel.WARNING,
                    AuditLogScope.FILE,
                    "RA_EXCESS_ITEM",
                    html,
                    withPresentationMeta(meta, "WARNING", "CRIMSON", "NORMAL")
            );
        }
    }

    private static Map<String, String> withPresentationMeta(
            Map<String, String> meta,
            String messageType,
            String colorHint,
            String emphasis
    ) {
        Map<String, String> enriched = new HashMap<>();
        if (meta != null) {
            enriched.putAll(meta);
        }
        enriched.put("messageType", messageType);
        enriched.put("colorHint", colorHint);
        enriched.put("emphasis", emphasis);
        return enriched;
    }

    /**
     * Собирает структурированные счётчики для {@link ReconcileResult#type5AuditCounters()} (meta в журнале аудита).
     */
    private static Type5ReconcileAuditCounters buildType5ReconcileAuditCounters(
            RaReadModelStats readModelStats,
            RcChangeReadModelStats rcReadStats,
            int raInserted,
            int raUpdated,
            int raUnchanged,
            int raDeleted,
            int rcInserted,
            int rcUpdated,
            int rcDeleted,
            int raSumInserted,
            int rcSumsInserted,
            int rcSumsInsertedChanged
    ) {
        int rcInvalid = rcReadStats.rcParseInvalid()
                + rcReadStats.rcMissingRcPeriod()
                + rcReadStats.rcMissingReportPeriod()
                + rcReadStats.rcMissingLookupForCompare()
                + rcReadStats.rcMissingBaseRa();
        int rcAmbiguous = rcReadStats.rcAmbiguousBaseRa() + rcReadStats.rcAmbiguousRac();
        Type5ReconcileAuditCounters.MatchStats match = new Type5ReconcileAuditCounters.MatchStats(
                readModelStats.categoryNew(),
                readModelStats.categoryChanged(),
                readModelStats.categoryUnchanged(),
                readModelStats.categoryInvalid(),
                readModelStats.categoryAmbiguous(),
                rcReadStats.rcCategoryNew(),
                rcReadStats.rcCategoryChanged(),
                rcReadStats.rcCategoryUnchanged(),
                rcInvalid,
                rcAmbiguous
        );
        int sumTotal = raSumInserted + rcSumsInserted + rcSumsInsertedChanged;
        Type5ReconcileAuditCounters.ApplyStats apply = new Type5ReconcileAuditCounters.ApplyStats(
                raInserted,
                raUpdated,
                raUnchanged,
                raDeleted,
                rcInserted,
                rcUpdated,
                rcReadStats.rcCategoryUnchanged(),
                rcDeleted,
                sumTotal
        );
        return new Type5ReconcileAuditCounters(match, apply);
    }

    private String formatCounters(
            int stagingRows,
            int inserted,
            int updated,
            int unchanged,
            int skipped,
            int unsupportedSign,
            int errors,
            CanonicalKeyStats canonicalKeyStats,
            LookupResolutionStats lookupStats,
            RaReadModelStats readModelStats,
            RcChangeReadModelStats rcReadStats,
            boolean applyRequested,
            boolean applyBlocked,
            boolean dryRun,
            int sumInserted,
            int sumUnchangedSkipped
    ) {
        return "stagingRows=" + stagingRows
                + ", inserted=" + inserted
                + ", updated=" + updated
                + ", unchanged=" + unchanged
                + ", skipped=" + skipped
                + ", skippedUnsupportedSign=" + unsupportedSign
                + ", canonicalKeyValid=" + canonicalKeyStats.validKeyRows()
                + ", canonicalKeyInvalid=" + canonicalKeyStats.invalidKeyRows()
                + ", lookupResolvedAll=" + lookupStats.resolvedAll()
                + ", lookupMissingPeriod=" + lookupStats.missingPeriod()
                + ", lookupMissingCstap=" + lookupStats.missingCstap()
                + ", lookupMissingOg=" + lookupStats.missingOg()
                + ", lookupAmbiguous(period/cstap/og)=" + lookupStats.ambiguousPeriod()
                + "/" + lookupStats.ambiguousCstap()
                + "/" + lookupStats.ambiguousOg()
                + ", matchRowsConsidered=" + readModelStats.considered()
                + ", matchFilteredSign=" + readModelStats.filteredSign()
                + ", matchInvalid=" + readModelStats.invalid()
                + ", matchMissing=" + readModelStats.missing()
                + ", matchAmbiguous=" + readModelStats.ambiguous()
                + ", matchSingle=" + readModelStats.matchedSingle()
                + ", matchUnchanged=" + readModelStats.unchanged()
                + ", matchChanged=" + readModelStats.changed()
                + ", matchCategoryNEW=" + readModelStats.categoryNew()
                + ", matchCategoryCHANGED=" + readModelStats.categoryChanged()
                + ", matchCategoryUNCHANGED=" + readModelStats.categoryUnchanged()
                + ", matchCategoryAMBIGUOUS=" + readModelStats.categoryAmbiguous()
                + ", matchCategoryINVALID=" + readModelStats.categoryInvalid()
                + ", rowsEligible=" + readModelStats.rowsEligible()
                + ", rowsRejected=" + readModelStats.rowsRejected()
                + ", rejectedByReason(filteredToRc)=" + readModelStats.rejectedFilteredToRc()
                + ", rejectedByReason(invalidCanonical)=" + readModelStats.rejectedInvalidCanonical()
                + ", rejectedByReason(disallowedSign)=" + readModelStats.rejectedDisallowedSign()
                + ", rejectedByReason(ambiguous)=" + readModelStats.rejectedAmbiguous()
                + ", rcRowsConsidered=" + rcReadStats.rcRowsConsidered()
                + ", rcParseInvalid=" + rcReadStats.rcParseInvalid()
                + ", rcMissingRcPeriod=" + rcReadStats.rcMissingRcPeriod()
                + ", rcMissingReportPeriod=" + rcReadStats.rcMissingReportPeriod()
                + ", rcMissingLookupForCompare=" + rcReadStats.rcMissingLookupForCompare()
                + ", rcMissingBaseRa=" + rcReadStats.rcMissingBaseRa()
                + ", rcAmbiguousBaseRa=" + rcReadStats.rcAmbiguousBaseRa()
                + ", rcAmbiguousRac=" + rcReadStats.rcAmbiguousRac()
                + ", rcCategoryNEW=" + rcReadStats.rcCategoryNew()
                + ", rcCategoryUNCHANGED=" + rcReadStats.rcCategoryUnchanged()
                + ", rcCategoryCHANGED=" + rcReadStats.rcCategoryChanged()
                + ", applyRequested=" + applyRequested
                + ", applyBlocked=" + applyBlocked
                + ", dryRun=" + dryRun
                + ", summInserted=" + sumInserted
                + ", summUnchangedSkipped=" + sumUnchangedSkipped
                + ", errors=" + errors;
    }

    private MissingLookupDiagnostics buildMissingLookupDiagnostics(
            List<StagingRaRow> rows,
            Map<Long, ResolvedLookupKeys> byRowKey
    ) {
        Map<String, Integer> missingSenders = new HashMap<>();
        Map<String, Integer> missingCst = new HashMap<>();
        Map<String, Integer> missingPeriod = new HashMap<>();
        for (StagingRaRow row : rows) {
            ResolvedLookupKeys keys = byRowKey.get(row.key());
            if (keys == null) {
                continue;
            }
            if (keys.ogKey() == null) {
                addCount(missingSenders, trimToNull(row.sender()));
            }
            if (keys.cstapKey() == null) {
                addCount(missingCst, trimToNull(row.cstAgPnStr()));
            }
            if (keys.periodKey() == null) {
                addCount(missingPeriod, row.raDate() != null ? row.raDate().toString() : null);
            }
        }
        return new MissingLookupDiagnostics(
                topN(missingSenders, 12),
                topN(missingCst, 12),
                topN(missingPeriod, 12)
        );
    }

    private void addCount(Map<String, Integer> counts, String raw) {
        String key = raw == null ? "(null)" : raw;
        counts.put(key, counts.getOrDefault(key, 0) + 1);
    }

    private Map<String, Integer> topN(Map<String, Integer> source, int limit) {
        Map<String, Integer> result = new LinkedHashMap<>();
        source.entrySet().stream()
                .sorted(Comparator.<Map.Entry<String, Integer>>comparingInt(Map.Entry::getValue).reversed()
                        .thenComparing(Map.Entry::getKey))
                .limit(limit)
                .forEach(entry -> result.put(entry.getKey(), entry.getValue()));
        return result;
    }

    private String formatMissingDetails(MissingLookupDiagnostics diagnostics) {
        return "Нет отправителя: " + formatNameCounts(diagnostics.missingSenders())
                + "; Нет стройки: " + formatNameCounts(diagnostics.missingCstCodes())
                + "; Нет периода: " + formatNameCounts(diagnostics.missingRaDates());
    }

    private String formatNameCounts(Map<String, Integer> counts) {
        if (counts.isEmpty()) {
            return "0";
        }
        StringBuilder builder = new StringBuilder("[");
        boolean first = true;
        for (Map.Entry<String, Integer> entry : counts.entrySet()) {
            if (!first) {
                builder.append("; ");
            }
            builder.append(entry.getKey()).append(" x").append(entry.getValue());
            first = false;
        }
        builder.append("]");
        return builder.toString();
    }

    /**
     * Минимальный срез staging-строки для начального reconcile-каркаса.
     */
    private record StagingRaRow(
            long key,
            String raNum,
            LocalDate raDate,
            String cstAgPnStr,
            String sender,
            String sign,
            BigDecimal ttl,
            BigDecimal work,
            BigDecimal equip,
            BigDecimal others,
            String arrivedNum,
            LocalDate arrivedDate,
            LocalDate arrivedDateFact,
            String returnedNum,
            LocalDate returnedDate,
            String returnedReason,
            String sendNum,
            LocalDate sendDate
    ) {
    }

    private record CanonicalMatchKey(
            Integer raOrgSender,
            Integer raCac,
            Integer raPeriod,
            String raNum
    ) {
    }

    private record CanonicalKeyStats(int validKeyRows, int invalidKeyRows) {
    }

    private record LookupCacheLoadResult(Map<String, Integer> values, int ambiguousCount) {
    }

    private record LookupCaches(
            Map<LocalDate, Integer> periodByDate,
            Map<String, Integer> cstapByCode,
            Map<String, Integer> ogByName,
            int periodAmbiguous,
            int cstapAmbiguous,
            int ogAmbiguous
    ) {
    }

    private record LookupResolutionStats(
            int resolvedAll,
            int missingPeriod,
            int missingCstap,
            int missingOg,
            int ambiguousPeriod,
            int ambiguousCstap,
            int ambiguousOg
    ) {
    }

    private record LookupResolutionResult(
            LookupResolutionStats stats,
            Map<Long, ResolvedLookupKeys> byRowKey
    ) {
    }

    private record ResolvedLookupKeys(
            Integer periodKey,
            Integer cstapKey,
            Integer ogKey
    ) {
    }

    private record DomainRaRow(
            long raKey,
            String raType,
            LocalDate raDate,
            String arrived,
            LocalDate arrivedDate,
            LocalDate arrivedDateFact,
            String returned,
            LocalDate returnedDate,
            String returnedReason,
            String sent,
            LocalDate sentDate,
            BigDecimal total,
            BigDecimal work,
            BigDecimal equip,
            BigDecimal others
    ) {
    }

    /** Ключ поиска {@code ags.ra} для ветки RC: только период отчёта и {@code ra_num} (как в {@code ra_ImpNewQuRc}). */
    private record PeriodRaNumKey(int raPeriod, String raNum) {
    }

    /** Ключ строки {@code ags.ra_change}: период изменения, родительский {@code ra_key}, номер изменения. */
    private record RcChangeMatchKey(int rcPeriod, long raKey, String changeNum) {
    }

    /**
     * Строка {@code ags.ra_change} с последними суммами из {@code ags.ra_chSmLt} (как в {@code ra_ImpNewQuRc}).
     */
    private record DomainRcChangeRow(
            long racKey,
            long raFk,
            String changeNum,
            int raPeriod,
            LocalDate rcDate,
            int raOrgSender,
            String arrived,
            LocalDate arrivedDate,
            LocalDate arrivedDateFact,
            String returned,
            LocalDate returnedDate,
            String returnedReason,
            String sent,
            LocalDate sentDate,
            BigDecimal total,
            BigDecimal work,
            BigDecimal equip,
            BigDecimal others
    ) {
    }

    /** Статистика read-model ветки изменений (1.3.1), без записи в БД. */
    private record RcChangeReadModelStats(
            int rcRowsConsidered,
            int rcParseInvalid,
            int rcMissingRcPeriod,
            int rcMissingReportPeriod,
            int rcMissingLookupForCompare,
            int rcMissingBaseRa,
            int rcAmbiguousBaseRa,
            int rcAmbiguousRac,
            int rcCategoryNew,
            int rcCategoryUnchanged,
            int rcCategoryChanged
    ) {
    }

    /** Результат построения RC read-model: статистика + список NEW-строк для apply (1.3.2). */
    private record RcChangeReadModelResult(
            RcChangeReadModelStats stats,
            List<RcNewApplyRow> newRows,
            List<RcChangedApplyRow> changedRows
    ) {
    }

    /** Модель строки RC, которая относится к категории NEW и будет создана в {@code ags.ra_change}. */
    private record RcNewApplyRow(
            long raFk,
            int raPeriod,
            String changeNum,
            LocalDate rcDate,
            int raOrgSender,
            String arrived,
            LocalDate arrivedDate,
            LocalDate arrivedDateFact,
            String returned,
            LocalDate returnedDate,
            String returnedReason,
            String sent,
            LocalDate sentDate,
            BigDecimal total,
            BigDecimal work,
            BigDecimal equip,
            BigDecimal others
    ) {
    }

    /** Модель строки RC, которая относится к категории CHANGED и будет обновлена в {@code ags.ra_change}. */
    private record RcChangedApplyRow(
            long racKey,
            long raFk,
            int raPeriod,
            String changeNum,
            LocalDate rcDate,
            int raOrgSender,
            String arrived,
            LocalDate arrivedDate,
            LocalDate arrivedDateFact,
            String returned,
            LocalDate returnedDate,
            String returnedReason,
            String sent,
            LocalDate sentDate,
            BigDecimal total,
            BigDecimal work,
            BigDecimal equip,
            BigDecimal others
    ) {
    }

    /** Счётчики apply-операций для RC (1.3.2). */
    private record RcChangeApplyStats(
            int rcChangesInserted,
            int rcSumsInserted
    ) {
    }

    /** Счётчики apply-операций для RC update (1.3.3). */
    private record RcChangeUpdateStats(
            int rcChangesUpdated,
            int rcSumsInserted,
            int rcSumsUnchangedSkipped
    ) {
    }

    /**
     * Статистика read-model матчинга RA и eligibility для partial apply (1.1.8–1.1.9).
     * {@code rejectedFilteredToRc} — строки «ОА изм» (ветка RC), не ошибка качества RA.
     * Остальные {@code rejectedByReason*} — отказы RA-apply по данным/неоднозначности.
     */
    private record RaReadModelStats(
            int considered,
            int filteredSign,
            int invalid,
            int matchedSingle,
            int ambiguous,
            int missing,
            int unchanged,
            int changed,
            int categoryNew,
            int categoryChanged,
            int categoryUnchanged,
            int categoryAmbiguous,
            int categoryInvalid,
            int rowsEligible,
            int rowsRejected,
            int rejectedFilteredToRc,
            int rejectedInvalidCanonical,
            int rejectedDisallowedSign,
            int rejectedAmbiguous
    ) {
    }

    private record RaReadModelResult(
            RaReadModelStats stats,
            List<NewRaRow> newRows,
            List<ChangedRaRow> changedRows
    ) {
    }

    private record NewRaRow(
            StagingRaRow stagingRow,
            ResolvedLookupKeys lookupKeys
    ) {
    }

    private record ChangedRaRow(
            long raKey,
            DomainRaRow domainBefore,
            StagingRaRow stagingRow
    ) {
    }

    private record InsertedRaRow(
            long raKey,
            StagingRaRow stagingRow
    ) {
    }

    private record InsertNewRaResult(
            int insertedCount,
            List<InsertedRaRow> insertedRows
    ) {
    }

    private record SumEvolutionStats(
            int inserted,
            int unchangedSkipped
    ) {
    }

    /**
     * Результат попытки вставить новую версию строки в {@code ags.ra_summ} (для аудита 5.2 и 5.6).
     */
    private record RaSummUpsertOutcome(
            boolean versionInserted,
            boolean hadLatestVersion,
            BigDecimal oldTotal,
            BigDecimal oldWork,
            BigDecimal oldEquip,
            BigDecimal oldOthers
    ) {
    }

    private record DryRunStats(
            int inserted,
            int updated,
            int sumInserted,
            int sumUnchangedSkipped
    ) {
    }

    private record MissingLookupDiagnostics(
            Map<String, Integer> missingSenders,
            Map<String, Integer> missingCstCodes,
            Map<String, Integer> missingRaDates
    ) {
    }
}
