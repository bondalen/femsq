package com.femsq.database.model.sudz;

import java.util.List;
import java.util.Set;

/**
 * Реестр шагов воронки загрузки платежей (1.1.1.2 / 0074).
 * Порядок = префикс цепочки; Excel→Tbl управляется {@code cipufFlTbl}.
 */
public final class SudzPmtUplFunnelSteps {

    private SudzPmtUplFunnelSteps() {
    }

    /** Описание шага панели. */
    public record StepDef(String id, String titleRu, boolean enabled) {
    }

    /** Id Excel→Tbl (не в чекбоксах; флаг «обнов. по исх?»). */
    public static final String EXCEL_TO_TBL = "excelToTbl";

    /**
     * Log-only шаги §2.9 (H2): без записи домена; сводка N + первые K.
     * Apply-шаги (3, 5, 7, 9, 10, 12) — H3.
     */
    public static final Set<String> LOG_ONLY_IDS = Set.of(
            "cipuCtpt_All_OIdNot",
            "cipuCacNot",
            "cipuCn_CtptCnTwo",
            "cipuCn_AgTwo",
            "cipuCn_CtptCnOneInvTwoLoad",
            "cipuCn_CtptCnOneInvOneAcDcNot",
            "cipuInsPmExt"
    );

    /** Сколько образцов строк писать в сжатый лог (H2). */
    public static final int LOG_ONLY_SAMPLE_LIMIT = 15;

    public static final List<StepDef> ALL = List.of(
            new StepDef("cipuCtpt_All_OIdNot",
                    "Отображаем отсутствующих контрагентов по выгрузке платежей", true),
            new StepDef("cipuCacNot",
                    "Отображаем отсутствующие стройки", true),
            new StepDef("cipuCn_CtptCnNotLoad",
                    "Отображаем отсутствующие договоры (по выгрузке платежей) либо добавляем их", true),
            new StepDef("cipuCn_CtptCnTwo",
                    "Отображаем пары договор+исполнитель более одного раза", true),
            new StepDef("cipuCn_AgNotLoad",
                    "Отображаем договора, не имеющие агента в БД, либо добавляем их", true),
            new StepDef("cipuCn_AgTwo",
                    "Отображаем агента более одного раза", true),
            new StepDef("cipuCn_CtptCnOneInvNotLoad",
                    "Отображаем новые счета-фактуры для существующих договоров либо добавляем их", true),
            new StepDef("cipuCn_CtptCnOneInvTwoLoad",
                    "Отображаем счета-фактуры, уже более чем однократно в БД (только показ; apply закрыт S69)", true),
            new StepDef("cipuCn_CtptCnOneInvOneAcNotLoad",
                    "Отображаем СФ без пары СФ+счёт ГК либо добавляем их", true),
            new StepDef("cipuDocNotLoad",
                    "Отображаем отсутствующие платёжные документы либо добавляем их", true),
            new StepDef("cipuCn_CtptCnOneInvOneAcDcNot",
                    "Отображаем СФ без платёжного документа", true),
            new StepDef("cipuInsPmNotLoad",
                    "Отображаем платежи, готовые к внесению в БД, либо вносим их", true),
            new StepDef("cipuInsPmExt",
                    "Отображаем платежи, уже в БД (построчный diff)", true)
    );

    /**
     * @param stepId id шага панели
     * @return true если шаг только логирует (H2)
     */
    public static boolean isLogOnly(String stepId) {
        return stepId != null && LOG_ONLY_IDS.contains(stepId);
    }

    /**
     * @return id включённых шагов панели
     */
    public static List<String> enabledIds() {
        return ALL.stream().filter(StepDef::enabled).map(StepDef::id).toList();
    }

    /**
     * Проверяет префикс цепочки среди enabled-шагов.
     *
     * @param requested запрошенные id
     */
    public static void requirePrefixOfEnabled(List<String> requested) {
        if (requested == null) {
            throw new IllegalArgumentException("Список шагов не задан");
        }
        if (requested.isEmpty()) {
            return;
        }
        List<String> chain = enabledIds();
        if (requested.size() > chain.size()) {
            throw new IllegalArgumentException("Слишком много шагов: " + requested.size());
        }
        for (int i = 0; i < requested.size(); i++) {
            String id = requested.get(i);
            if (id == null || id.isBlank()) {
                throw new IllegalArgumentException("Пустой stepId на позиции " + i);
            }
            if (!chain.get(i).equals(id)) {
                throw new IllegalArgumentException(
                        "Шаги должны быть префиксом цепочки; на позиции " + i
                                + " ожидался «" + chain.get(i) + "», получен «" + id + "»"
                );
            }
        }
    }
}
