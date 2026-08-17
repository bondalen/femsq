package com.femsq.database.model.sudz;

/**
 * Строка общей очереди СФ с совпадающими номерами ({@code sudz.CnInvUplSfDouble}).
 *
 * @param ciusKey ключ
 * @param ciusCidut FK строка Excel долгов (XOR с ciput)
 * @param ciusCiput FK строка Excel платежей
 * @param ciusDbtFile ключ File долгов
 * @param ciusPmtFile ключ File платежей
 * @param ciusUnloadKey upl / pm key
 * @param ciusDbtTblCnInvRow строка буфера TblCnInv долгов
 * @param ciusPmtTblCnInvRow строка буфера TblCnInv платежей
 * @param ciusCnKey договор из match
 * @param ciusCnNum номер договора
 * @param ciusInvNum номер СФ
 * @param ciusInvNumCount сколько inv в ags с этим номером
 * @param ciusStatus open|created|deferred
 * @param ciusStatusAt время смены статуса
 * @param ciusCreatedInvKey iKey после create
 */
public record SudzCnInvUplSfDouble(
        int ciusKey,
        Integer ciusCidut,
        Integer ciusCiput,
        Integer ciusDbtFile,
        Integer ciusPmtFile,
        Integer ciusUnloadKey,
        Integer ciusDbtTblCnInvRow,
        Integer ciusPmtTblCnInvRow,
        Integer ciusCnKey,
        String ciusCnNum,
        String ciusInvNum,
        Integer ciusInvNumCount,
        String ciusStatus,
        java.time.LocalDateTime ciusStatusAt,
        Integer ciusCreatedInvKey
) {
}
