package com.femsq.database.model.sudz;

import java.util.List;

/**
 * Кандидаты FK для create {@code invDbtVar} по строке очереди двоящих.
 *
 * @param ciudKey ключ очереди
 * @param iKey СФ
 * @param accountKey счёт ГК из Excel ({@code cidutAccount})
 * @param sides стороны ExistList
 * @param cnNums варианты {@code cnNum} type=1 по договорам сторон
 * @param invNums варианты {@code invNum} по СФ+номеру
 */
public record SudzInvDbtVarCandidates(
        int ciudKey,
        Integer iKey,
        Integer accountKey,
        List<SudzInvDbtVarSideCandidate> sides,
        List<SudzInvDbtVarCnNumCandidate> cnNums,
        List<SudzInvDbtVarInvNumCandidate> invNums
) {
}
