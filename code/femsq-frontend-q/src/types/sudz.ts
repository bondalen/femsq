/**
 * Типы GraphQL API СУДЗ.
 */

export interface SudzYear {
  yrKey: number;
  yrVariant: string | null;
  baseUpl: number | null;
  yyyy: number | null;
  cmmGr: number | null;
  cmmGrNew?: number | null;
  baseUplName?: string | null;
  baseUplDate?: string | null;
  cmmGrName?: string | null;
  cmmGrDate?: string | null;
  cmmGrNewName?: string | null;
  cmmGrNewDate?: string | null;
  yyyyValue?: number | null;
  progress?: string | null;
}

export interface SudzUplLookup {
  uplKey: number;
  uplName: string | null;
  uplDate: string | null;
  uplStatusOnDate: string | null;
}

export interface SudzCmmGrLookup {
  cmmGrKey: number;
  name: string | null;
  date: string | null;
}

export interface SudzYyyyLookup {
  yKey: number;
  yyyy: number;
}

export interface SudzPmUplLookup {
  pmKey: number;
  name: string | null;
  date: string | null;
}

export interface SudzPmLink {
  gPKey: number;
  dbtUpl: number;
  pmKey: number;
  pmName: string | null;
  pmDate: string | null;
  dbtUplName: string | null;
  dbtUplDate: string | null;
}

export interface SudzYearUpl {
  yrUplPKey: number;
  yrKey: number;
  uplKey: number;
  uplName: string | null;
  uplDate: string | null;
  uplStatusOnDate: string | null;
  pmLinks: SudzPmLink[];
}

export interface SudzYearDetail {
  year: SudzYear;
  upls: SudzYearUpl[];
}

export interface CreateSudzYearInput {
  variant: string;
  yKey: number;
  cmmGrKey?: number | null;
  baseUplKey?: number | null;
  newUplName?: string | null;
  newUplDate?: string | null;
  newUplStatusOnDate?: string | null;
}

export interface UpdateSudzYearInput {
  yrKey: number;
  variant: string;
  baseUplKey: number;
  yKey: number;
  cmmGrKey?: number | null;
  cmmGrNewKey?: number | null;
}

export interface CreateSudzCmmGrInput {
  name: string;
  date: string;
}

/** Результат REST-импорта возврата Rslt. */
export interface SudzRsltReturnImportResult {
  yr: number;
  imported: number;
  parsed: number;
  fileName: string;
}

export interface CreateSudzUplInput {
  name: string;
  uplDate?: string | null;
  statusOnDate: string;
}

/** Шапка лаунчера CnInvDbtUplFile. */
export interface SudzDbtUplFile {
  cidufKey: number;
  cidufUpload: number;
  cidufPath: string;
  cidufFlLoad: boolean;
  cidufFlTbl: boolean;
  cidufLoadingProgress: string | null;
}

/** Лист CnInvDbtUplFileSh. */
export interface SudzDbtUplFileSh {
  cidufsKey: number;
  cidufsFile: number;
  cidufsSheet: string;
  cidufsAccount: number;
  accountNum: number | null;
  cidufsTest: boolean;
}

export interface CreateSudzDbtUplFileShInput {
  uplKey: number;
  sheet: string;
  accountNum: number;
  test: boolean;
}

export interface UpdateSudzDbtUplFileShInput {
  cidufsKey: number;
  sheet?: string | null;
  accountNum?: number | null;
  test?: boolean | null;
}

/** Очередь InvDouble (legacy). */
export interface SudzDbtUplInvDouble {
  cidufiKey: number;
  cidufiCiduf: number | null;
  cidufiCnNnn: number | null;
  cidufiCnNum: string | null;
  cidufiCnKey: number | null;
  cidufiInvNnn: number | null;
  cidufiInvNum: string | null;
  cidufiInvNumCount: string | null;
}

/** Общая очередь КСДСФ. */
export interface SudzCnInvUplSfDouble {
  ciusKey: number;
  ciusCidut: number | null;
  ciusCiput: number | null;
  ciusDbtFile: number | null;
  ciusPmtFile: number | null;
  ciusUnloadKey: number | null;
  ciusDbtTblCnInvRow: number | null;
  ciusPmtTblCnInvRow: number | null;
  ciusCnKey: number | null;
  ciusCnNum: string | null;
  ciusInvNum: string | null;
  ciusInvNumCount: number | null;
  ciusStatus: string;
  ciusStatusAt: string | null;
  ciusCreatedInvKey: number | null;
}

/** Очередь двоящих задолженностей СФ (CnInvUplInvDbtDouble). */
export interface SudzCnInvUplInvDbtDouble {
  ciudKey: number;
  ciudCidut: number;
  ciudDbtFile: number | null;
  ciudUnloadKey: number;
  ciudIKey: number | null;
  ciudCnNum: string | null;
  ciudInvNum: string | null;
  ciudDebt: number | null;
  ciudIdvvKey: number | null;
  ciudReason: string | null;
  /** Текстовый канал сообщений ([queue.build] …). */
  ciudReasonDetail: string | null;
  ciudStatus: string;
  ciudStatusAt: string | null;
  ciudCreatedIdKey: number | null;
}

/** Очередь кандидатов P1 multi-Dbt (CnInvUplDbtP1). */
export interface SudzCnInvUplDbtP1 {
  cip1Key: number;
  cip1UnloadKey: number;
  cip1BaseUpl: number;
  cip1DbtFile: number | null;
  cip1DbtKey: number;
  cip1BaseSlotKey: number;
  cip1BaseIKey: number | null;
  cip1BaseCnNum: string | null;
  cip1BaseInvNum: string | null;
  cip1MatchSum: number;
  cip1SumKind: string;
  cip1CandCidut: number | null;
  cip1CandIKey: number | null;
  cip1CandCnNum: string | null;
  cip1CandInvNum: string | null;
  cip1CandDebt: number | null;
  cip1Reason: string;
  cip1ReasonDetail: string | null;
  cip1Status: string;
  cip1StatusAt: string | null;
  cip1LinkedSlotKey: number | null;
}

/** Кандидаты create invDbtVar на экране двоящих. */
export interface SudzInvDbtVarSideCandidate {
  cnKey: number;
  cnSOrgKey: number;
  csoCnDate: string | null;
}

export interface SudzInvDbtVarCnNumCandidate {
  cnnKey: number;
  cnKey: number;
  cnnNumNull: string | null;
}

export interface SudzInvDbtVarInvNumCandidate {
  inKey: number;
  inInv: number;
  inNumNull: string | null;
}

export interface SudzInvDbtVarCandidates {
  ciudKey: number;
  iKey: number | null;
  accountKey: number | null;
  sides: SudzInvDbtVarSideCandidate[];
  cnNums: SudzInvDbtVarCnNumCandidate[];
  invNums: SudzInvDbtVarInvNumCandidate[];
}

/** Режим Merge канонов или долей на upl (S77.3). */
export type SudzDbtMergeMode = 'CANONS' | 'SHARES_ON_UPL';

/** Одна доля Split. */
export interface SplitSudzDbtPartInput {
  ttl: number;
  overd?: number | null;
  varKey?: number | null;
  note?: string | null;
  dateStart?: string | null;
  dateMaturity?: string | null;
  docBase?: string | null;
  ciudKey?: number | null;
}

/** Вход Split канона на доли одной upl. */
export interface SplitSudzDbtInput {
  dbtKey: number;
  sourceSlotKey: number;
  uplKey: number;
  parts: SplitSudzDbtPartInput[];
}

/** Созданная доля Split. */
export interface SudzDbtSplitPartResult {
  slotKey: number;
  varKey: number;
  valueKey: number;
  ttl: number;
}

/** Результат Split. */
export interface SudzDbtSplitResult {
  dbtKey: number;
  sourceSlotKey: number;
  uplKey: number;
  removedSourceValue: boolean;
  parts: SudzDbtSplitPartResult[];
}

/** Вход Merge. */
export interface MergeSudzDbtInput {
  mode: SudzDbtMergeMode;
  survivorDbtKey: number;
  slotKeys: number[];
  survivorSlotKey?: number | null;
  uplKey?: number | null;
}

/** Результат Merge. */
export interface SudzDbtMergeResult {
  survivorDbtKey: number;
  mode: SudzDbtMergeMode;
  updatedBridges: number;
  removedShareValues: number;
  restoredValueKey: number | null;
}

/** Excel-кандидат КСДСФ. */
export interface SudzSfDoubleExcelCandidate {
  cidutKey: number;
  findDbtNum: number | null;
  cidutAccount: number | null;
  /** Номер счёта ГК (ags.accnt.account_num), как в дереве слотов. */
  cidutAccntNum: number | null;
  cidutCntrPrtNum: number | null;
  cidutCntrPrtName: string | null;
  cidutCntrPrtITN: string | null;
  cidutCnName: string | null;
  cidutCnDate: string | null;
  cidutCnInv: string | null;
  cidutCnInvName: string | null;
  cidutFormtnDate: string | null;
  cidutMatrtyDate: string | null;
  cidutDebt: number | null;
  cidutDebtOverdue: number | null;
  cidutDoc: string | null;
  cidutLink: string | null;
  cidutSheet: number | null;
  cidutSheetNum: number | null;
  cidutUnloadKey: number | null;
}

/** Доменный СФ с совпадающим номером. */
export interface SudzSfDoubleDomainMatch {
  invKey: number;
  invNum: string | null;
  invNumKey: number | null;
  invEntered: string | null;
  ciKey: number | null;
  cnKey: number | null;
  cnNum: string | null;
}

/** Совпадение суммы в старой структуре (cn_inv_dbt). */
export interface SudzSfDoubleOldSumMatch {
  cidKey: number;
  number: number | null;
  dbtTtl: number | null;
  dbtOverd: number | null;
  debtType: string | null;
  uplKey: number | null;
  ciaKey: number | null;
  /** Имя карточки cnInvAccnt (сегм. 20 / M4). */
  ciaName: string | null;
}

/** Совпадение суммы в новой структуре (DbtValue, M2). */
export interface SudzSfDoubleNewSumMatch {
  dvKey: number;
  dvTtl: number | null;
  dvOverd: number | null;
  dvUpl: number | null;
  dvInvDbt: number | null;
  dbtKey: number | null;
}

/** Пара списков совпадений по сумме для вкладки «Суммы». */
export interface SudzSfDoubleSumMatches {
  oldMatches: SudzSfDoubleOldSumMatch[];
  newMatches: SudzSfDoubleNewSumMatch[];
}

/** Ключ подсказки для выбора строки на экране КСДСФ. */
export interface SudzSfDoubleHintItem {
  zone: string;
  pickKey: string;
  pickValue: number;
  invKey: number | null;
  cnKey: number | null;
  cnNum: string | null;
  matchBy: string;
  label: string | null;
}

/** Секция подсказки (yes/no/unknown/na). */
export interface SudzSfDoubleHintSection {
  status: string;
  message: string;
  totalCount: number;
  items: SudzSfDoubleHintItem[];
}

/** Три зоны подсказок по исполнителю Excel. */
export interface SudzSfDoubleHints {
  sfByNum: SudzSfDoubleHintSection;
  sumsOld: SudzSfDoubleHintSection;
  sumsNew: SudzSfDoubleHintSection;
}

/** Советник КСДСФ ([советник] в «Сообщения»). */
export interface SudzSfDoubleAdvice {
  messageText: string;
  confidence: string | null;
  action: string | null;
  recommendInvKey: number | null;
  recommendCnKey: number | null;
}

/** Советник КСДД ([advisor] в «Сообщения»). */
export interface SudzInvDbtDoubleAdvice {
  messageText: string;
  confidence: string | null;
  action: string | null;
  recommendIdKey: number | null;
  recommendVarKey: number | null;
  recommendDbtKey: number | null;
  recommendUplKey: number | null;
  splitParts: SplitSudzDbtPartInput[] | null;
}

/** Точка ряда DbtValue по слоту. */
export interface SudzInvDbtTimelinePoint {
  uplKey: number | null;
  statusDate: string | null;
  ttl: number | null;
  overdue: number | null;
  source: string | null;
  varKey: number | null;
}

/** Временной ряд одного слота invDbt. */
export interface SudzInvDbtSlotTimeline {
  idKey: number;
  idNum: number;
  ciaName: string | null;
  varKey: number | null;
  accnt: number | null;
  excelAnchor: number | null;
  excelStatusDate: string | null;
  points: SudzInvDbtTimelinePoint[];
}

/** Карточка лаунчера экрана C. */
export interface SudzDbtUplLauncher {
  upl: SudzUplLookup;
  file: SudzDbtUplFile | null;
  sheets: SudzDbtUplFileSh[];
  invDoubles: SudzDbtUplInvDouble[];
  sfDoubles: SudzCnInvUplSfDouble[];
  invDbtDoubles: SudzCnInvUplInvDbtDouble[];
  dbtP1: SudzCnInvUplDbtP1[];
}

export interface UpdateSudzDbtUplFileInput {
  uplKey: number;
  path?: string | null;
  flLoad?: boolean | null;
  flTbl?: boolean | null;
}

export interface RunSudzDbtUplFunnelInput {
  uplKey: number;
  /** Контекст портфеля года (yr.yr_key) для diff base→curr. */
  yrKey: number;
  steps: string[];
  flLoad: boolean;
}

/** Ручная привязка строки КСДСФ к существующему inv/cn. */
export interface LinkSudzSfDoubleInput {
  ciusKey: number;
  invKey: number;
  cnKey: number;
}

export interface SudzDbtUplFunnelResult {
  launcher: SudzDbtUplLauncher;
  ranSteps: string[];
  stub: boolean;
}

export interface CreateSudzPmUplInput {
  name?: string | null;
  date: string;
}

export interface SudzRsltPeriod {
  uplKey: number;
  uplDate: string | null;
  asOf: string | null;
  invNumEnum: string | null;
  idNum: number | null;
  cnNumEnum: string | null;
  csoCnDate: string | null;
  orgIdValueL: number | null;
  itn: string | null;
  ctptOrg: string | null;
  maturity: string | null;
  ttl: number | null;
  overd: number | null;
  cstAgPnCode: string | null;
  cstAgPnName: string | null;
  agOrg: string | null;
  pogasheno: number | null;
}

export interface SudzRsltDebt {
  dbtKey: number;
  accountNum: string | null;
  curator: string | null;
  mery: string | null;
  cstCode: string | null;
  cstName: string | null;
  curatorNew?: string | null;
  meryNew?: string | null;
  cstCodeNew?: string | null;
  periods: SudzRsltPeriod[];
}

export interface SudzD644Row {
  dbtKey: number;
  accountNum: number | null;
  agent: string | null;
  orgId: number | null;
  itn: string | null;
  counterpart: string | null;
  contract: string | null;
  contractDate: string | null;
  invoice: string | null;
  dateStart: string | null;
  maturityBase: string | null;
  ttlBase: number | null;
  overdBase: number | null;
  maturityCurr: string | null;
  overdCurr: number | null;
  repaid: number | null;
  cstCode: string | null;
  cstName: string | null;
  comment644: string | null;
  baseUplDate: string | null;
  currUplDate: string | null;
  baseUpl: number | null;
  currUpl: number | null;
}

export interface SudzSvodAccount {
  accountNum: number;
  accountName: string | null;
  overdBase: number | null;
  repaid: number | null;
  overdCurr: number | null;
  repaidPct: number | null;
}

export interface SudzSvodTotal {
  overdBase: number | null;
  repaid: number | null;
  overdCurr: number | null;
  repaidPct: number | null;
}

export interface SudzSvodResult {
  accounts: SudzSvodAccount[];
  total: SudzSvodTotal | null;
}

export interface SudzDebtCollectionInput {
  yr: number;
  dbtKey: number;
  curator?: string | null;
  mery?: string | null;
  cstCode?: string | null;
}

export interface SudzDebtCollectionResult {
  dbtKey: number;
  curator: string | null;
  mery: string | null;
  cstCode: string | null;
  cstName: string | null;
  cmmGr: number;
}

/** Строка списка долгов Rslt. */
export interface SudzPortfolioRow {
  dbtKey: number;
  accountNum: string | null;
  counterpart: string | null;
  baseOverd: number | null;
  invoice: string | null;
  cstCode: string | null;
  curator: string | null;
  mery: string | null;
  cstName: string | null;
  debt: SudzRsltDebt;
}
