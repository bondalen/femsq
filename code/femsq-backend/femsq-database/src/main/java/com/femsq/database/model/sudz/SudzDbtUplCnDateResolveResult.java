package com.femsq.database.model.sudz;

/**
 * Итог резолва пустых {@code cidutCnDate} (компактный свод / C.10.6).
 *
 * @param nullDateRows строк Tbl с пустой датой до резолва
 * @param fromValue обновлено датой стороны Value@prior
 * @param fromTbl обновлено датой Tbl@prior
 * @param fromUniqueSide обновлено единственной датированной стороной без prior
 * @param alreadyNullSide пар, где null-сторона уже есть (Tbl без изменения)
 * @param createdNullSides создано сторон с пустой датой (только flLoad)
 * @param unresolved пар без однозначного резолва
 */
public record SudzDbtUplCnDateResolveResult(
        int nullDateRows,
        int fromValue,
        int fromTbl,
        int fromUniqueSide,
        int alreadyNullSide,
        int createdNullSides,
        int unresolved
) {
}
