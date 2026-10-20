package com.femsq.database.model.sudz;

/**
 * Одно отличие книги (уже загруженный Tbl) и {@code cn_inv_pm}. Запись не выполняет.
 *
 * @param docCode «№ докум.»
 * @param sheet номер листа
 * @param due срок оплаты, усечённый до секунды
 * @param field «стройка» или «строка»
 * @param bookValue значение в книге
 * @param dbValue значение в базе
 */
public record SudzPmtUplExtGap(
        String docCode,
        Integer sheet,
        String due,
        String field,
        String bookValue,
        String dbValue
) {
}
