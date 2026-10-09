package com.femsq.database.model.sudz;

/**
 * Алиас номера СФ ({@code ags.invNum}) для decision-TreeList.
 *
 * @param inKey ключ {@code invNum.inKey}
 * @param inNum текст номера
 * @param primary совпадает с {@code inv.iNum} (или единственный)
 * @param hitExcel совпал с номером Excel кейса
 */
public record SudzSfDecisionInvNum(
        int inKey,
        String inNum,
        boolean primary,
        boolean hitExcel
) {
}
