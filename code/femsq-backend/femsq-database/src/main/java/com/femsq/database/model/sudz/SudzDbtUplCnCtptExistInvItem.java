package com.femsq.database.model.sudz;

/**
 * Один номер СФ в буфере {@code CnInvDbtUplTblCnInv} (для лога / InvDouble).
 *
 * @param cnInv номер СФ ({@code NullИлиПусто} = пустой)
 * @param inNumCount сколько inv уже с этим {@code inNumNull} в БД; null = номера ещё нет
 */
public record SudzDbtUplCnCtptExistInvItem(
        String cnInv,
        Integer inNumCount
) {
}
