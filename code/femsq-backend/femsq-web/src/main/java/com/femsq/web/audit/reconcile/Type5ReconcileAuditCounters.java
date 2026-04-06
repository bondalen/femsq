package com.femsq.web.audit.reconcile;

/**
 * Структурированные счётчики reconcile для {@code af_type=5} (события
 * {@code RECONCILE_TYPE5_MATCH_STATS} и {@code RECONCILE_TYPE5_APPLY_STATS}).
 *
 * <p>Значения копируются в meta журнала аудита без парсинга строки {@code diagnostics}.</p>
 */
public record Type5ReconcileAuditCounters(MatchStats match, ApplyStats apply) {

    /**
     * Категории read-model матчинга RA/RC (до или независимо от записи в домен).
     *
     * @param rcInvalid    строки RC, не попавшие в валидный матч (parse/missing base и т.п., без ambiguous)
     * @param rcAmbiguous  неоднозначный base RA или несколько {@code rac_key} на ключ
     */
    public record MatchStats(
            int raNew,
            int raChanged,
            int raUnchanged,
            int raInvalid,
            int raAmbiguous,
            int rcNew,
            int rcChanged,
            int rcUnchanged,
            int rcInvalid,
            int rcAmbiguous
    ) {
    }

    /**
     * Эффекты apply или оценка dry-run (те же поля, что и при реальном apply).
     *
     * @param sumInserted суммарно вставленные версии сумм: RA ({@code ra_summ}) + RC ({@code ra_change_summ})
     */
    public record ApplyStats(
            int raInserted,
            int raUpdated,
            int raUnchanged,
            int raDeleted,
            int rcInserted,
            int rcUpdated,
            int rcUnchanged,
            int rcDeleted,
            int sumInserted
    ) {
    }
}
