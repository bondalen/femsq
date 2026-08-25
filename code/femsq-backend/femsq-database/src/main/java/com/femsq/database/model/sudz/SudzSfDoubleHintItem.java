package com.femsq.database.model.sudz;

/**
 * Совпадение подсказки КСДСФ: ключ для выбора строки в таблице экрана.
 *
 * @param zone {@code sf} | {@code sumsOld} | {@code sumsNew}
 * @param pickKey имя поля выбора ({@code inKey}, {@code cidKey}, {@code dvKey})
 * @param pickValue значение ключа
 * @param invKey {@code ags.inv.iKey} (для зоны sf)
 * @param cnKey договор
 * @param cnNum номер договора
 * @param matchBy {@code BUIRG} | {@code ITN} | {@code BOTH}
 * @param label краткая подпись кнопки
 */
public record SudzSfDoubleHintItem(
        String zone,
        String pickKey,
        int pickValue,
        Integer invKey,
        Integer cnKey,
        String cnNum,
        String matchBy,
        String label
) {
}
