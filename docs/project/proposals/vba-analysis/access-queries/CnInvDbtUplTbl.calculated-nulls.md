/*
 * Access CnInvDbtUplTbl — вычисляемые поля *Null (не пишутся при импорте).
 * В sudz.CnInvDbtUplTbl одноимённые столбцы физические и пустые; Java/T-SQL
 * шагов воронки повторяет выражения ниже (S61l CnNotLoad и далее).
 *
 * cidutCnDateNull:
 *   IIf(IsNull([cidutCnDate]); #01.01.1900#; [cidutCnDate])
 *
 * cidutCnNameNull:
 *   IIf(IsNull([cidutCnName]); "NullИлиПусто";
 *       IIf([cidutCnName]=""; "NullИлиПусто"; Trim([cidutCnName])))
 *
 * cidutCnInvNull:
 *   IIf(IsNull([cidutCnInv]); "NullИлиПусто";
 *       IIf([cidutCnInv]=""; "NullИлиПусто"; Trim([cidutCnInv])))
 *
 * cidutCnInvNameNull:
 *   IIf(IsNull([cidutCnInvName]); "NullИлиПусто";
 *       IIf([cidutCnInvName]=""; "NullИлиПусто"; [cidutCnInvName]))
 *
 * Снято: 2026-08-14 (скрин конструктора Access).
 * lastUpdated: 2026-08-14
 */
