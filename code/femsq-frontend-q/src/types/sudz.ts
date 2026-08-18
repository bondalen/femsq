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
  cidufsTest: boolean;
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

/** Excel-кандидат КСДСФ. */
export interface SudzSfDoubleExcelCandidate {
  cidutKey: number;
  findDbtNum: number | null;
  cidutAccount: number | null;
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

/** {@code ags.cn_inv_dbt} в дереве КСДСФ. */
export interface SudzSfDoubleCnInvDbt {
  cnInvDbtKey: number;
  dateStart: string | null;
  dateMaturity: string | null;
  debtType: string | null;
  dbtTtl: number | null;
  dbtOverd: number | null;
  docBase: string | null;
  link: string | null;
  uplKey: number | null;
  number: number | null;
  mark: number | null;
  cidTimeOfEntry: string | null;
}

/** {@code ags.cnInvAccnt}. */
export interface SudzSfDoubleCnInvAccnt {
  ciaKey: number;
  ciaCnSOrg: number | null;
  ciaName: string | null;
  ciaNote: string | null;
  ciaCnInvAccntSmpl: number;
  ciaTimeOfEntry: string | null;
  debts: SudzSfDoubleCnInvDbt[];
}

/** {@code ags.cnInvAccntSmpl}. */
export interface SudzSfDoubleAccntSmpl {
  ciasKey: number;
  ciasCnInv: number;
  ciasAccnt: number | null;
  accountNum: number | null;
  ciasCnSOrgSmpl: number | null;
  ciasNote: string | null;
  ciasTimeOfEntry: string | null;
  accounts: SudzSfDoubleCnInvAccnt[];
}

/** {@code sudz.DbtValue}. */
export interface SudzSfDoubleDbtValue {
  dvKey: number;
  dvUpl: number | null;
  dvTtl: number | null;
  dvOverd: number | null;
  dvDateStart: string | null;
  dvDateMaturity: string | null;
  dvDocBase: string | null;
}

/** {@code sudz.Dbt}. */
export interface SudzSfDoubleDbt {
  dbtKey: number;
  dbtNote: string | null;
  values: SudzSfDoubleDbtValue[];
}

/** {@code sudz.invDbtDbt}. */
export interface SudzSfDoubleInvDbtDbt {
  iddKey: number;
  iddInv: number | null;
  iddDbt: number | null;
  iddInvDbt: number | null;
  iddTimeOfEntry: string | null;
  dbt: SudzSfDoubleDbt | null;
}

/** {@code sudz.invDbt}. */
export interface SudzSfDoubleInvDbt {
  idKey: number;
  idInv: number;
  idNum: number | null;
  idNote: string | null;
  idTimeOfEntry: string | null;
  links: SudzSfDoubleInvDbtDbt[];
}

/** СГК + новая ДЗ для дерева КСДСФ. */
export interface SudzSfDoubleTreeDebt {
  smpls: SudzSfDoubleAccntSmpl[];
  invDbts: SudzSfDoubleInvDbt[];
}

/** Карточка лаунчера экрана C. */
export interface SudzDbtUplLauncher {
  upl: SudzUplLookup;
  file: SudzDbtUplFile | null;
  sheets: SudzDbtUplFileSh[];
  invDoubles: SudzDbtUplInvDouble[];
  sfDoubles: SudzCnInvUplSfDouble[];
}

export interface UpdateSudzDbtUplFileInput {
  uplKey: number;
  path?: string | null;
  flLoad?: boolean | null;
  flTbl?: boolean | null;
}

export interface RunSudzDbtUplFunnelInput {
  uplKey: number;
  steps: string[];
  flLoad: boolean;
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
