/**
 * Типы GraphQL для иерархии строек (cst / cstAg / cstAgPn / cstAgPnBranch).
 */

export interface ConstructionSiteDto {
  cstKey: number;
  cstName: string;
  cstBusSgm?: string | null;
  cstOidOld?: string | null;
  cstMark?: number | null;
}

export interface CstCreateRequest {
  cstName: string;
  cstBusSgm?: string | null;
  cstOidOld?: string | null;
  cstMark?: number | null;
}

export interface CstUpdateRequest {
  cstName: string;
  cstBusSgm?: string | null;
  cstOidOld?: string | null;
  cstMark?: number | null;
}

export interface CstAgentDto {
  cstaKey: number;
  cstaAg: number;
  cstaCst: number;
  cstaOidOld?: string | null;
  cstaInvestor?: number | null;
  agentLabel?: string | null;
}

export interface CstAgCreateRequest {
  cstaAg: number;
  cstaCst: number;
  cstaOidOld?: string | null;
  cstaInvestor?: number | null;
}

export interface CstAgUpdateRequest {
  cstaAg: number;
  cstaCst: number;
  cstaOidOld?: string | null;
  cstaInvestor?: number | null;
}

export interface CstAgPointDto {
  cstapKey: number;
  cstapCsta: number;
  cstapIpgPnN: string;
  cstapOidOld?: string | null;
}

export interface CstAgPnCreateRequest {
  cstapCsta: number;
  cstapIpgPnN: string;
  cstapOidOld?: string | null;
}

export interface CstAgPnUpdateRequest {
  cstapCsta: number;
  cstapIpgPnN: string;
  cstapOidOld?: string | null;
}

export interface CstAgPnBranchDto {
  cstapbKey: number;
  cstapbCstAgPn: number;
  cstapbBranch: number;
  cstapbStart?: string | null;
  cstapbEnd?: string | null;
  branchName?: string | null;
}

export interface CstAgPnBranchCreateRequest {
  cstapbCstAgPn: number;
  cstapbBranch: number;
  cstapbStart?: string | null;
  cstapbEnd?: string | null;
}

export interface CstAgPnBranchUpdateRequest {
  cstapbCstAgPn: number;
  cstapbBranch: number;
  cstapbStart?: string | null;
  cstapbEnd?: string | null;
}

/** Строка списка САК для формы поиска по коду. */
export interface CstAgPnCodeDto {
  cstapKey: number;
  cstapIpgPnN: string;
  cstapCsta: number;
  cstaCst: number;
  cstName?: string | null;
}

export interface OgAgCsLookupDto {
  ogaKey: number;
  ogaNm: string;
}

/** Строка списка отчётов (ags.fnRRcList). */
export interface CstRaListEntryDto {
  yyyy?: number | null;
  mNum?: number | null;
  p?: string | null;
  cstaKey?: number | null;
  cstaAg?: number | null;
  cstaCst?: number | null;
  ogaNm?: string | null;
  cstapKey?: number | null;
  cstapIpgPnN?: string | null;
  raKey: number;
  raNum?: string | null;
  raDate?: string | null;
  raType?: string | null;
  raChKey?: number | null;
  raChNum?: string | null;
  raChDate?: string | null;
  raOrgSender?: number | null;
  ogNm?: string | null;
  rasTotal?: number | null;
  rasWork?: number | null;
  rasEquip?: number | null;
  rasOthers?: number | null;
  raArrived?: string | null;
  raArrivedDate?: string | null;
  raReturned?: string | null;
  raReturnedDate?: string | null;
  raSent?: string | null;
  raSentDate?: string | null;
}

export interface RaReportDto {
  raKey: number;
  raNum: string;
  raDate?: string | null;
  raCac: number;
  raType: string;
  raWorkType?: string | null;
  raPeriod: number;
  raArrived?: string | null;
  raArrivedDate?: string | null;
  raReturned?: string | null;
  raReturnedDate?: string | null;
  raSent?: string | null;
  raSentDate?: string | null;
  raNoteT?: string | null;
  raCreated?: string | null;
  raOrgSender: number;
  raNote?: string | null;
}

export interface RaReportCreateRequest {
  raNum: string;
  raDate?: string | null;
  raCac: number;
  raType: string;
  raWorkType?: string | null;
  raPeriod: number;
  raArrived?: string | null;
  raArrivedDate?: string | null;
  raReturned?: string | null;
  raReturnedDate?: string | null;
  raSent?: string | null;
  raSentDate?: string | null;
  raNoteT?: string | null;
  raOrgSender: number;
  raNote?: string | null;
}

export type RaReportUpdateRequest = RaReportCreateRequest;

export interface RaSummDto {
  rasKey: number;
  rasRa: number;
  rasTotal?: number | null;
  rasWork?: number | null;
  rasEquip?: number | null;
  rasOthers?: number | null;
  rasDate?: string | null;
}

export interface RaSummCreateRequest {
  rasRa: number;
  rasTotal?: number | null;
  rasWork?: number | null;
  rasEquip?: number | null;
  rasOthers?: number | null;
  rasDate?: string | null;
}

export type RaSummUpdateRequest = RaSummCreateRequest;

export interface RaPeriodLookupDto {
  key: number;
  p: string;
}

export interface CstAgPnSiteLookupDto {
  cstapKey: number;
  cstapIpgPnN: string;
  cstaKey: number;
  agentLabel?: string | null;
}

/** Строка списка Access ralpRaCst. */
export interface RalpRaCstListEntryDto {
  cstKey?: number | null;
  ogaNm?: string | null;
  cstapIpgPnN?: string | null;
  ralprKey: number;
  ralprNum?: string | null;
  ralprDate?: string | null;
  ralprCstAgPn?: number | null;
  ralprOgSender?: number | null;
  ogNm?: string | null;
  auCnt: number;
  hasReturned: boolean;
}

export interface RalpRaDto {
  ralprKey: number;
  ralprNum: string;
  ralprDate: string;
  ralprCstAgPn: number;
  ralprOgSender: number;
  ogNm?: string | null;
  ralprY?: number | null;
  ralprM?: number | null;
}

export interface RalpRaCreateRequest {
  ralprNum: string;
  ralprDate: string;
  ralprCstAgPn: number;
  ralprOgSender: number;
}

export type RalpRaUpdateRequest = RalpRaCreateRequest;

export interface RalpRaAuDto {
  ralpraKey: number;
  ralpraRa: number;
  ralpraCostAndVat?: number | null;
  ralpraArrived?: string | null;
  ralpraArrivedDate?: string | null;
  ralpraReturned?: string | null;
  ralpraReturnedDate?: string | null;
  ralpraSent?: string | null;
  ralpraSentDate?: string | null;
  ralpraNote?: string | null;
  ralpraStatus: number;
}

export interface RalpRaAuCreateRequest {
  ralpraRa: number;
  ralpraCostAndVat?: number | null;
  ralpraArrived?: string | null;
  ralpraArrivedDate?: string | null;
  ralpraReturned?: string | null;
  ralpraReturnedDate?: string | null;
  ralpraSent?: string | null;
  ralpraSentDate?: string | null;
  ralpraNote?: string | null;
  ralpraStatus: number;
}

export type RalpRaAuUpdateRequest = RalpRaAuCreateRequest;

export interface RalpRaAuStatusLookupDto {
  code: number;
  label: string;
}
