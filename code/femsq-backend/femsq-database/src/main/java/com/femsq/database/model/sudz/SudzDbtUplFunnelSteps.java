package com.femsq.database.model.sudz;

import java.util.List;

/**
 * Канонический реестр шагов воронки загрузки свода (S61f).
 * Порядок фиксирован; {@code CnCtptInvAccExistDbl} отключён как в Access с 03.02.2023.
 */
public final class SudzDbtUplFunnelSteps {

    private SudzDbtUplFunnelSteps() {
    }

    /** Описание шага. */
    public record StepDef(String id, String titleRu, boolean enabled) {
    }

    /**
     * Id шага Excel→Tbl. Не в панели чекбоксов: им управляет {@code cidufFlTbl}
     * («обнов. по исх?»), как в Access.
     */
    public static final String EXCEL_TO_TBL = "excelToTbl";

    /**
     * Инлайн-блок Access ≈140–207: лог организаций без кода БУиРГ (без записи в домен).
     */
    public static final String ORG_NOT_IN_BUIRG = "orgNotInBuirg";

    /**
     * Access {@code CnNotLoad}: отсутствующие договоры с исполнителями (лог + apply).
     */
    public static final String CN_NOT_LOAD = "CnNotLoad";

    /**
     * Access {@code CnExistCtptNotLoad}: номер есть, исполнитель не совпадает (только лог).
     */
    public static final String CN_EXIST_CTPT_NOT_LOAD = "CnExistCtptNotLoad";

    /**
     * Access {@code CnCtptExistInvNotLoad}: новые СФ для существующих договоров.
     * Перед шагом внутри оркестратора — очистка {@code CnInvDbtUplFileInvDouble}
     * (в Access отдельный вызов перед Sub; в UI не отдельный чекбокс — S65e).
     */
    public static final String CN_CTPT_EXIST_INV_NOT_LOAD = "CnCtptExistInvNotLoad";

    /**
     * Полный упорядоченный реестр шагов <em>панели</em> (без Excel→Tbl).
     * titleRu — из комментариев VBA перед шагом ({@code Form_CnInvDbtUpl_gt_File_f}).
     * Очистка InvDouble не в панели: prelude к {@link #CN_CTPT_EXIST_INV_NOT_LOAD}.
     */
    public static final List<StepDef> ALL = List.of(
            new StepDef(ORG_NOT_IN_BUIRG,
                    "Отображаем отсутствующих контрагентов", true),
            new StepDef(CN_NOT_LOAD,
                    "Отображаем отсутствующие в БД договоры с исполнителями либо добавляем их", true),
            new StepDef(CN_EXIST_CTPT_NOT_LOAD,
                    "Отображаем договора, имеющиеся в БД, в которых отсутствует обнаруженный в БД исполнитель",
                    true),
            new StepDef(CN_CTPT_EXIST_INV_NOT_LOAD,
                    "Отображаем новые счета-фактуры для существующих договоров", true),
            new StepDef("CnCtptInvExistAccSmplNotLoad",
                    "Отображаем счета-фактуры не имеющие Задолженностей простых в БД либо добавляем их",
                    true),
            new StepDef("invDbtDouble",
                    "Проверяем имеющиеся в БД задолженности, которые более чем одна у счёта-фактуры",
                    true),
            new StepDef("CnCtptInvExistAccNotLoad",
                    "Отображаем счета-фактуры не имеющие Задолженностей в БД либо добавляем их", true),
            new StepDef("ciduTblCnCtptInvAccNameCountOneNot",
                    "Отображаем повторяющиеся Задолженности (с именами) имеющиеся в источнике", true),
            new StepDef("CnCtptInvAccExistDbl",
                    "Отображаем Задолженности имеющие более одной задолженности в выгрузке (отключён)",
                    false),
            new StepDef("CnCtptInvAccExistDbtNotLoad",
                    "Отображаем Задолженности не имеющие задолженности в БД либо добавляем их туда",
                    true),
            new StepDef("CnCtptInvAccDbtExist",
                    "Отображаем пары СФ+СГК имеющие задолженности в БД", true)
    );

    /**
     * Упорядоченные id включённых в продукт шагов (без disabled).
     *
     * @return список id
     */
    public static List<String> enabledIds() {
        return ALL.stream().filter(StepDef::enabled).map(StepDef::id).toList();
    }

    /**
     * Проверяет, что {@code requested} — префикс цепочки среди enabled-шагов
     * (в том же порядке, без пропусков и disabled).
     *
     * @param requested запрошенные id
     * @throws IllegalArgumentException при нарушении
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
        for (String id : requested) {
            ALL.stream()
                    .filter(s -> s.id().equals(id) && !s.enabled())
                    .findFirst()
                    .ifPresent(s -> {
                        throw new IllegalArgumentException("Шаг отключён: " + id);
                    });
        }
    }
}
