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
