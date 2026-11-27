/**
 * GraphQL API: помесячные Excel агентов (impIpgLoadMonf), C2 §6.4.
 */

import { gql } from '@apollo/client/core';

import { apolloClient } from '@/plugins/apollo';
import { RequestError } from './http';

/** Строка Monf. */
export interface ImpIpgLoadMonfDto {
  id: number;
  loadKey: number;
  utPlKey?: number | null;
  name: string;
  filePath?: string | null;
  sheet?: string | null;
  limColumn?: string | null;
  quarter: boolean;
  sumFirst?: number | null;
  note?: string | null;
  created?: string | null;
  logHtml?: string | null;
}

/** Ввод создания. */
export interface CreateImpIpgLoadMonfInput {
  loadKey: number;
  utPlKey?: number | null;
  name: string;
  filePath?: string | null;
  sheet?: string | null;
  limColumn?: string | null;
  quarter?: boolean | null;
  sumFirst?: number | null;
  note?: string | null;
}

/** Ввод обновления. */
export interface UpdateImpIpgLoadMonfInput {
  utPlKey?: number | null;
  name: string;
  filePath?: string | null;
  sheet?: string | null;
  limColumn?: string | null;
  quarter?: boolean | null;
  sumFirst?: number | null;
  note?: string | null;
}

/** Строка staging parse (§6.5). */
export interface ImpIpgMonfParseRowDto {
  rowNo: number;
  cstCode: string;
  name?: string | null;
  limYear?: number | null;
  quarters?: (number | null)[] | null;
  months?: (number | null)[] | null;
  skipped: boolean;
  skipReason?: string | null;
}

/** Итог parse Monf. */
export interface ImpIpgMonfParseResultDto {
  monfKey: number;
  sheetName: string;
  filePath: string;
  codeColumn: number;
  limColumn: number;
  quarter: boolean;
  sumFirst: number;
  codeHits: number;
  loadedCount: number;
  skippedCount: number;
  rows: ImpIpgMonfParseRowDto[];
  logHtml?: string | null;
}

/** Итог apply Monf (§6.6). */
export interface ImpIpgMonfApplyResultDto {
  monfKey: number;
  utPlKey: number;
  ipgKey: number;
  dryRun: boolean;
  parsedCount: number;
  appliedCount: number;
  unmatchedCount: number;
  ambiguousCount: number;
  errorCount: number;
  problems: string[];
  logHtml?: string | null;
}

const MONF_FIELDS = `
  id
  loadKey
  utPlKey
  name
  filePath
  sheet
  limColumn
  quarter
  sumFirst
  note
  created
  logHtml
`;

const IMP_IPG_LOAD_MONFS = gql`
  query ImpIpgLoadMonfs($ipgKey: Int!) {
    impIpgLoadMonfs(ipgKey: $ipgKey) {
      ${MONF_FIELDS}
    }
  }
`;

const IMP_IPG_LOAD_MONFS_BY_LOAD = gql`
  query ImpIpgLoadMonfsByLoad($loadKey: Int!) {
    impIpgLoadMonfsByLoad(loadKey: $loadKey) {
      ${MONF_FIELDS}
    }
  }
`;

const CREATE_IMP_IPG_LOAD_MONF = gql`
  mutation CreateImpIpgLoadMonf($input: CreateImpIpgLoadMonfInput!) {
    createImpIpgLoadMonf(input: $input) {
      ${MONF_FIELDS}
    }
  }
`;

const UPDATE_IMP_IPG_LOAD_MONF = gql`
  mutation UpdateImpIpgLoadMonf($id: Int!, $input: UpdateImpIpgLoadMonfInput!) {
    updateImpIpgLoadMonf(id: $id, input: $input) {
      ${MONF_FIELDS}
    }
  }
`;

const DELETE_IMP_IPG_LOAD_MONF = gql`
  mutation DeleteImpIpgLoadMonf($id: Int!) {
    deleteImpIpgLoadMonf(id: $id)
  }
`;

const PARSE_IMP_IPG_LOAD_MONF = gql`
  mutation ParseImpIpgLoadMonf($id: Int!, $filePath: String) {
    parseImpIpgLoadMonf(id: $id, filePath: $filePath) {
      monfKey
      sheetName
      filePath
      codeColumn
      limColumn
      quarter
      sumFirst
      codeHits
      loadedCount
      skippedCount
      logHtml
      rows {
        rowNo
        cstCode
        name
        limYear
        skipped
        skipReason
      }
    }
  }
`;

const APPLY_IMP_IPG_LOAD_MONF = gql`
  mutation ApplyImpIpgLoadMonf($id: Int!, $dryRun: Boolean) {
    applyImpIpgLoadMonf(id: $id, dryRun: $dryRun) {
      monfKey
      utPlKey
      ipgKey
      dryRun
      parsedCount
      appliedCount
      unmatchedCount
      ambiguousCount
      errorCount
      problems
      logHtml
    }
  }
`;

/**
 * Оборачивает ошибку Apollo в {@link RequestError}.
 */
function wrapApolloError(error: unknown, operation: string): RequestError {
  const message = error instanceof Error ? error.message : `Ошибка GraphQL операции ${operation}`;
  return new RequestError(message, {
    status: 0,
    statusText: 'GraphQL',
    url: '/graphql',
    body: { operation }
  });
}

/**
 * Список Monf текущей ИП.
 */
export async function fetchImpIpgLoadMonfs(ipgKey: number): Promise<ImpIpgLoadMonfDto[]> {
  try {
    const { data } = await apolloClient.query({
      query: IMP_IPG_LOAD_MONFS,
      variables: { ipgKey },
      fetchPolicy: 'network-only'
    });
    return (data?.impIpgLoadMonfs ?? []) as ImpIpgLoadMonfDto[];
  } catch (error) {
    throw wrapApolloError(error, 'impIpgLoadMonfs');
  }
}

/**
 * Monf одной сессии load.
 */
export async function fetchImpIpgLoadMonfsByLoad(
  loadKey: number
): Promise<ImpIpgLoadMonfDto[]> {
  try {
    const { data } = await apolloClient.query({
      query: IMP_IPG_LOAD_MONFS_BY_LOAD,
      variables: { loadKey },
      fetchPolicy: 'network-only'
    });
    return (data?.impIpgLoadMonfsByLoad ?? []) as ImpIpgLoadMonfDto[];
  } catch (error) {
    throw wrapApolloError(error, 'impIpgLoadMonfsByLoad');
  }
}

/**
 * Создать строку Monf.
 */
export async function createImpIpgLoadMonf(
  input: CreateImpIpgLoadMonfInput
): Promise<ImpIpgLoadMonfDto> {
  try {
    const { data } = await apolloClient.mutate({
      mutation: CREATE_IMP_IPG_LOAD_MONF,
      variables: { input }
    });
    return data.createImpIpgLoadMonf as ImpIpgLoadMonfDto;
  } catch (error) {
    throw wrapApolloError(error, 'createImpIpgLoadMonf');
  }
}

/**
 * Обновить строку Monf.
 */
export async function updateImpIpgLoadMonf(
  id: number,
  input: UpdateImpIpgLoadMonfInput
): Promise<ImpIpgLoadMonfDto> {
  try {
    const { data } = await apolloClient.mutate({
      mutation: UPDATE_IMP_IPG_LOAD_MONF,
      variables: { id, input }
    });
    return data.updateImpIpgLoadMonf as ImpIpgLoadMonfDto;
  } catch (error) {
    throw wrapApolloError(error, 'updateImpIpgLoadMonf');
  }
}

/**
 * Удалить строку Monf.
 */
export async function deleteImpIpgLoadMonf(id: number): Promise<boolean> {
  try {
    const { data } = await apolloClient.mutate({
      mutation: DELETE_IMP_IPG_LOAD_MONF,
      variables: { id }
    });
    return Boolean(data?.deleteImpIpgLoadMonf);
  } catch (error) {
    throw wrapApolloError(error, 'deleteImpIpgLoadMonf');
  }
}

/**
 * Parse skeleton Monf (§6.5): якоря → staging в ответе + logHtml.
 */
export async function parseImpIpgLoadMonf(
  id: number,
  filePath?: string | null
): Promise<ImpIpgMonfParseResultDto> {
  try {
    const { data } = await apolloClient.mutate({
      mutation: PARSE_IMP_IPG_LOAD_MONF,
      variables: { id, filePath: filePath || null }
    });
    return data.parseImpIpgLoadMonf as ImpIpgMonfParseResultDto;
  } catch (error) {
    throw wrapApolloError(error, 'parseImpIpgLoadMonf');
  }
}

/**
 * Apply Monf → UtPlP / LmMn@212 (§6.6).
 */
export async function applyImpIpgLoadMonf(
  id: number,
  dryRun?: boolean | null
): Promise<ImpIpgMonfApplyResultDto> {
  try {
    const { data } = await apolloClient.mutate({
      mutation: APPLY_IMP_IPG_LOAD_MONF,
      variables: { id, dryRun: dryRun ?? false }
    });
    return data.applyImpIpgLoadMonf as ImpIpgMonfApplyResultDto;
  } catch (error) {
    throw wrapApolloError(error, 'applyImpIpgLoadMonf');
  }
}
