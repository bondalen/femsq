/**
 * TypeScript типы для системы ревизий.
 */

export interface RaAtDto {
  atKey: number;
  atName: string;
  atCreated?: string | null;
  atUpdated?: string | null;
}

export interface RaDirDto {
  key: number;
  dirName: string;
  dir: string;
  dirCreated?: string | null;
  dirUpdated?: string | null;
}

export type AuditRunStatus = 'IDLE' | 'RUNNING' | 'COMPLETED' | 'FAILED';

export type StagingLogLevel = 'VERBOSE' | 'SUMMARY' | 'MINIMAL';

export interface RaADto {
  adtKey: number;
  adtName: string;
  adtDate?: string | null;
  adtResults?: string | null;
  adtDir: number;
  adtType: number;
  adtAddRA: boolean;
  adtStagingLogLevel?: StagingLogLevel | null;
  adtCreated?: string | null;
  adtUpdated?: string | null;
  adtStatus?: AuditRunStatus | null;
}

export interface RaACreateRequest {
  adtName: string;
  adtDate?: string | null;
  adtResults?: string | null;
  adtDir: number;
  adtType: number;
  adtAddRA: boolean;
  adtStagingLogLevel?: StagingLogLevel | null;
}

export interface RaAUpdateRequest {
  adtName: string;
  adtDate?: string | null;
  adtResults?: string | null;
  adtDir: number;
  adtType: number;
  adtAddRA: boolean;
  adtStagingLogLevel?: StagingLogLevel | null;
}