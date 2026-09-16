package com.femsq.database.model.sudz;

import java.util.List;
import java.util.Objects;

/**
 * Итог шага {@code invDbtLoad}: apply-счётчики, очередь и снимок dry-лога.
 *
 * @param insertedInvDbt число INSERT в {@code sudz.invDbt}
 * @param insertedBridges число INSERT в {@code sudz.invDbtDbtVar}
 * @param insertedValues число INSERT в {@code sudz.DbtValue}
 * @param queuedCount число строк очереди {@code CnInvUplInvDbtDouble} после apply
 * @param calmCreatePending Calm Create без слота (будет / был кандидат на INSERT {@code invDbt})
 * @param calmF1Pending Calm F1 (мост/Value на существующий слот)
 * @param silentHoleResolved 4FK+{@code idvvKey}, слотов 0, не в calm и не в очереди
 */
public record SudzDbtUplInvDbtLoadApplyResult(
        int insertedInvDbt,
        int insertedBridges,
        int insertedValues,
        int queuedCount,
        List<SudzDbtUplInvDbtLoadCalmRow> calmCreatePending,
        List<SudzDbtUplInvDbtLoadCalmRow> calmF1Pending,
        List<SudzDbtUplInvDbtLoadCalmRow> silentHoleResolved
) {
    /**
     * Нормализует списки снимка (null → empty, defensive copy).
     */
    public SudzDbtUplInvDbtLoadApplyResult {
        calmCreatePending = List.copyOf(
                Objects.requireNonNullElse(calmCreatePending, List.of()));
        calmF1Pending = List.copyOf(
                Objects.requireNonNullElse(calmF1Pending, List.of()));
        silentHoleResolved = List.copyOf(
                Objects.requireNonNullElse(silentHoleResolved, List.of()));
    }

    /**
     * Компактный итог без строк снимка (только счётчики).
     *
     * @param insertedInvDbt INSERT invDbt
     * @param insertedBridges INSERT мостов
     * @param insertedValues INSERT DbtValue
     * @param queuedCount размер очереди
     * @return результат с пустыми списками
     */
    public static SudzDbtUplInvDbtLoadApplyResult countsOnly(
            int insertedInvDbt,
            int insertedBridges,
            int insertedValues,
            int queuedCount
    ) {
        return new SudzDbtUplInvDbtLoadApplyResult(
                insertedInvDbt, insertedBridges, insertedValues, queuedCount,
                List.of(), List.of(), List.of());
    }
}
