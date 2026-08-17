/**
 * Типы экрана «Договоры» (cnNum + cn + стороны).
 */

export interface CnNumDto {
  cnnKey: number;
  cnnNum: string | null;
  cnnCn: number;
  cnnType: number | null;
  cnnTypeName: string | null;
  cnnNote: string | null;
}

export interface CnDto {
  cnKey: number;
  cnNumber: string | null;
  cnDate: string | null;
  cnNote: string | null;
  cnMark: number | null;
}

export interface CnSOrgDto {
  cnSOrgKey: number;
  csoCnSOrgSmpl: number;
  dateBeg: string | null;
  dateEnd: string | null;
  csoAsbuId: string | null;
  csoCnDate: string | null;
  csoTimeOfEntry: string | null;
}

export interface CnSOrgSmplDto {
  csosKey: number;
  csosCnS: number;
  csosOrgId: number;
  orgLabel: string | null;
  csosTimeOfEntry: string | null;
  orgs: CnSOrgDto[];
}

export interface CnSideDto {
  cnSKey: number;
  cnKey: number;
  cnSType: number;
  cnSTypeName: string | null;
  smpls: CnSOrgSmplDto[];
}

export interface CnSOrgIdLookupDto {
  orgIdKey: number;
  buirg: number | null;
  label: string;
}

export interface CnSideCreateRequest {
  cnKey: number;
  cnSType: number;
}

export interface CnSideUpdateRequest {
  cnKey: number;
  cnSType: number;
}

export interface CnSOrgSmplCreateRequest {
  csosCnS: number;
  csosOrgId: number;
}

export interface CnSOrgSmplUpdateRequest {
  csosCnS: number;
  csosOrgId: number;
}

export interface CnSOrgCreateRequest {
  csoCnSOrgSmpl: number;
  dateBeg?: string | null;
  dateEnd?: string | null;
  csoAsbuId?: string | null;
  csoCnDate?: string | null;
}

export interface CnSOrgUpdateRequest {
  csoCnSOrgSmpl: number;
  dateBeg?: string | null;
  dateEnd?: string | null;
  csoAsbuId?: string | null;
  csoCnDate?: string | null;
}

export interface CnNumTypeLookupDto {
  cnntKey: number;
  cnntName: string | null;
}

export interface CnContractCreateRequest {
  cnnNum?: string | null;
  /** Дата из свода → csoCnDate; cn_date при создании не заполняется. */
  csoCnDate?: string | null;
  cnnType: number;
  csosOrgId?: number | null;
  note?: string | null;
}

export interface CnUpdateRequest {
  cnDate?: string | null;
  cnNote?: string | null;
  cnMark?: number | null;
}

export interface CnContractCreatedDto {
  cnKey: number;
  cnnKey: number;
  cnSKey: number | null;
  csosKey: number | null;
  cnSOrgKey: number | null;
}
