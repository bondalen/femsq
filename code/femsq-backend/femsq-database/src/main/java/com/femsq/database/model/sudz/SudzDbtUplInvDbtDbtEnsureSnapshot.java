package com.femsq.database.model.sudz;

/**
 * Снимок шага {@code invDbtDbtEnsure} (C1): слоты с {@code DbtValue} на upl без моста {@code invDbtDbt}.
 *
 * @param missingBridge всего слотов без моста на upl
 * @param f1Ready готовы к reuse по F1 (уникальный {@code dbtKey})
 * @param newReady готовы к INSERT нового {@code Dbt} (нет sibling-моста)
 * @param ambiguous sibling есть, F1 не однозначен — только лог
 */
public record SudzDbtUplInvDbtDbtEnsureSnapshot(
        int missingBridge,
        int f1Ready,
        int newReady,
        int ambiguous
) {
}
