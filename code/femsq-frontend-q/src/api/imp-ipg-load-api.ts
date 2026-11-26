/**
 * GraphQL API: сессии загрузки годовой ИП / парсер / сверка ПТСФ (C2 §3.1.6).
 */

import { gql } from '@apollo/client/core';

import { apolloClient } from '@/plugins/apollo';
import { RequestError } from './http';

export interface ImpIpgLoadDto {
  id: number;
  ipgKey: number;
  name: string;
  filePath?: string | null;
  note?: string | null;
  created?: string | null;
  /** Накопительный HTML-лог «Ход загрузки» (iilResults). */
  logHtml?: string | null;
}

export interface ImpIpgParseResultDto {
  loadKey: number;
  sheetName: string;
  filePath: string;
  sectionCount: number;
  leafCount: number;
  totalRows: number;
  /** Накопительный HTML-лог «Ход загрузки». */
  logHtml?: string | null;
}

export interface ImpIpgReconcileRowDto {
  rowId: number;
  rowNo: number;
  text?: string | null;
  stiKey?: number | null;
  status: string;
  candidateStiKeys: number[];
  pathMatched: boolean;
  nameInPool: boolean;
  closed: boolean;
}

export interface ImpIpgReconcileResultDto {
  loadKey: number;
  stNetKey: number;
  matched: number;
  open: number;
  rows: ImpIpgReconcileRowDto[];
  /** Накопительный HTML-лог «Ход загрузки». */
  logHtml?: string | null;
}

export interface ImpIpgRowDto {
  id: number;
  loadKey: number;
  rowNo: number;
  rowKind: string;
  text?: string | null;
  parentKey?: number | null;
  stiKey?: number | null;
  ctx?: string | null;
}

/** Итог bulk apply пунктов (§3.2.4 / §3.2.5). */
export interface ImpIpgPointsApplyResultDto {
  loadKey: number;
  ipgKey: number;
  previousIpgKey?: number | null;
  dryRun: boolean;
  leafCount: number;
  appliedCount: number;
  skippedAlreadyCount: number;
  ready: boolean;
  errors: string[];
  problemRowIds: number[];
  createdPnKeys: number[];
  /** Накопительный HTML-лог «Ход загрузки» (dry-run — без записи в сессию). */
  logHtml?: string | null;
}

const IMP_IPG_LOADS = gql`
  query ImpIpgLoads($ipgKey: Int!) {
    impIpgLoads(ipgKey: $ipgKey) {
      id
      ipgKey
      name
      filePath
      note
      created
      logHtml
    }
  }
`;

const CREATE_IMP_IPG_LOAD = gql`
  mutation CreateImpIpgLoad($input: CreateImpIpgLoadInput!) {
    createImpIpgLoad(input: $input) {
      id
      ipgKey
      name
      filePath
      note
      created
      logHtml
    }
  }
`;

const PARSE_IMP_IPG_LOAD = gql`
  mutation ParseImpIpgLoad($id: Int!, $filePath: String) {
    parseImpIpgLoad(id: $id, filePath: $filePath) {
      loadKey
      sheetName
      filePath
      sectionCount
      leafCount
      totalRows
      logHtml
    }
  }
`;

const RECONCILE_IMP_IPG_STRUCTURE = gql`
  mutation ReconcileImpIpgStructure(
    $loadKey: Int!
    $stNetKey: Int!
    $persistMatches: Boolean
  ) {
    reconcileImpIpgStructure(
      loadKey: $loadKey
      stNetKey: $stNetKey
      persistMatches: $persistMatches
    ) {
      loadKey
      stNetKey
      matched
      open
      rows {
        rowId
        rowNo
        text
        stiKey
        status
        candidateStiKeys
        pathMatched
        nameInPool
        closed
      }
      logHtml
    }
  }
`;

const MAP_IMP_IPG_ROW_STI = gql`
  mutation MapImpIpgRowSti($id: Int!, $stiKey: Int, $clearStiKey: Boolean) {
    mapImpIpgRowSti(id: $id, stiKey: $stiKey, clearStiKey: $clearStiKey) {
      id
      loadKey
      rowNo
      rowKind
      text
      parentKey
      stiKey
      ctx
    }
  }
`;

const APPLY_IMP_IPG_POINTS = gql`
  mutation ApplyImpIpgPoints($loadKey: Int!, $previousIpgKey: Int, $dryRun: Boolean) {
    applyImpIpgPoints(loadKey: $loadKey, previousIpgKey: $previousIpgKey, dryRun: $dryRun) {
      loadKey
      ipgKey
      previousIpgKey
      dryRun
      leafCount
      appliedCount
      skippedAlreadyCount
      ready
      errors
      problemRowIds
      createdPnKeys
      logHtml
    }
  }
`;

function wrapApolloError(error: unknown, operation: string): RequestError {
  const message = error instanceof Error ? error.message : `Ошибка GraphQL операции ${operation}`;
  return new RequestError(message, {
    status: 0,
    statusText: 'GraphQL',
    url: '/graphql',
    body: { operation }
  });
}

/** Сессии загрузки под ИП. */
export async function getImpIpgLoads(ipgKey: number): Promise<ImpIpgLoadDto[]> {
  try {
    const result = await apolloClient.query<{ impIpgLoads: ImpIpgLoadDto[] }>({
      query: IMP_IPG_LOADS,
      variables: { ipgKey },
      fetchPolicy: 'network-only'
    });
    return result.data.impIpgLoads ?? [];
  } catch (error) {
    throw wrapApolloError(error, 'ImpIpgLoads');
  }
}

/** Создать сессию загрузки. */
export async function createImpIpgLoad(input: {
  ipgKey: number;
  name: string;
  filePath?: string | null;
  note?: string | null;
}): Promise<ImpIpgLoadDto> {
  try {
    const result = await apolloClient.mutate<{ createImpIpgLoad: ImpIpgLoadDto }>({
      mutation: CREATE_IMP_IPG_LOAD,
      variables: { input }
    });
    if (!result.data?.createImpIpgLoad) {
      throw new Error('createImpIpgLoad: пустой ответ');
    }
    return result.data.createImpIpgLoad;
  } catch (error) {
    throw wrapApolloError(error, 'CreateImpIpgLoad');
  }
}

/** Разобрать Excel в staging. */
export async function parseImpIpgLoad(
  id: number,
  filePath?: string | null
): Promise<ImpIpgParseResultDto> {
  try {
    const result = await apolloClient.mutate<{ parseImpIpgLoad: ImpIpgParseResultDto }>({
      mutation: PARSE_IMP_IPG_LOAD,
      variables: { id, filePath: filePath ?? null }
    });
    if (!result.data?.parseImpIpgLoad) {
      throw new Error('parseImpIpgLoad: пустой ответ');
    }
    return result.data.parseImpIpgLoad;
  } catch (error) {
    throw wrapApolloError(error, 'ParseImpIpgLoad');
  }
}

/** Сверка ПТСФ со схемой. */
export async function reconcileImpIpgStructure(
  loadKey: number,
  stNetKey: number,
  persistMatches = true
): Promise<ImpIpgReconcileResultDto> {
  try {
    const result = await apolloClient.mutate<{
      reconcileImpIpgStructure: ImpIpgReconcileResultDto;
    }>({
      mutation: RECONCILE_IMP_IPG_STRUCTURE,
      variables: { loadKey, stNetKey, persistMatches }
    });
    if (!result.data?.reconcileImpIpgStructure) {
      throw new Error('reconcileImpIpgStructure: пустой ответ');
    }
    return result.data.reconcileImpIpgStructure;
  } catch (error) {
    throw wrapApolloError(error, 'ReconcileImpIpgStructure');
  }
}

/** Ручной map stiKey. */
export async function mapImpIpgRowSti(
  id: number,
  stiKey: number | null,
  clearStiKey = false
): Promise<ImpIpgRowDto> {
  try {
    const result = await apolloClient.mutate<{ mapImpIpgRowSti: ImpIpgRowDto }>({
      mutation: MAP_IMP_IPG_ROW_STI,
      variables: { id, stiKey, clearStiKey }
    });
    if (!result.data?.mapImpIpgRowSti) {
      throw new Error('mapImpIpgRowSti: пустой ответ');
    }
    return result.data.mapImpIpgRowSti;
  } catch (error) {
    throw wrapApolloError(error, 'MapImpIpgRowSti');
  }
}

/**
 * Bulk apply листьев staging → ipgPn+ipgStPn (§3.2.4).
 *
 * @param dryRun true — только валидация и счётчики
 */
export async function applyImpIpgPoints(
  loadKey: number,
  previousIpgKey: number | null = null,
  dryRun = false
): Promise<ImpIpgPointsApplyResultDto> {
  try {
    const result = await apolloClient.mutate<{
      applyImpIpgPoints: ImpIpgPointsApplyResultDto;
    }>({
      mutation: APPLY_IMP_IPG_POINTS,
      variables: {
        loadKey,
        previousIpgKey,
        dryRun
      }
    });
    if (!result.data?.applyImpIpgPoints) {
      throw new Error('applyImpIpgPoints: пустой ответ');
    }
    return result.data.applyImpIpgPoints;
  } catch (error) {
    throw wrapApolloError(error, 'ApplyImpIpgPoints');
  }
}
