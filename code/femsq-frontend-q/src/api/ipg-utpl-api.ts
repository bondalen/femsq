/**
 * GraphQL API планов UtPl / LmMn (C2 O2 §4.2).
 *
 * Операции `ipgUtPl*` / `upsertIpgUtPlPnLmMnMonth` из `og-schema.graphqls`.
 */

import { gql } from '@apollo/client/core';

import { apolloClient } from '@/plugins/apollo';
import { RequestError } from './http';

/** План агента на ИП. */
export interface IpgUtPlDto {
  iuplKey: number;
  iuplNm: string | null;
  iuplDate: string | null;
  iuplAg: number;
  iuplIpg: number;
}

/** Заголовок UtPlP. */
export interface IpgUtPlPDto {
  iuplpKey: number;
  iuplpPl: number;
  iuplpIpgPn: number;
  iuplpLim: number | null;
  iuplpSubAg: number | null;
}

/** Ось C месяца. */
export interface IpgUtPlPnLmMnMonthDto {
  plPnKey: number;
  month: number;
  lim212: number | null;
  lim195: number | null;
  lim172: number | null;
  lim187: number | null;
  aggCode: string;
}

/** Грид LmMn. */
export interface IpgUtPlPnLmMnGridDto {
  plPnKey: number;
  limYear: number | null;
  months: IpgUtPlPnLmMnMonthDto[];
  gAggOk: boolean;
}

const UTPL_FIELDS = `
  iuplKey
  iuplNm
  iuplDate
  iuplAg
  iuplIpg
`;

const GRID_FIELDS = `
  plPnKey
  limYear
  gAggOk
  months {
    plPnKey
    month
    lim212
    lim195
    lim172
    lim187
    aggCode
  }
`;

const IPG_UT_PL_BY_IPG = gql`
  query IpgUtPlByIpg($ipgKey: Int!) {
    ipgUtPlByIpg(ipgKey: $ipgKey) {
      ${UTPL_FIELDS}
    }
  }
`;

const IPG_UT_PL_PN_LM_MN_GRID = gql`
  query IpgUtPlPnLmMnGrid($plKey: Int!, $ipgpKey: Int!) {
    ipgUtPlPnLmMnGrid(plKey: $plKey, ipgpKey: $ipgpKey) {
      ${GRID_FIELDS}
    }
  }
`;

const CREATE_IPG_UT_PL = gql`
  mutation CreateIpgUtPl($input: CreateIpgUtPlInput!) {
    createIpgUtPl(input: $input) {
      ${UTPL_FIELDS}
    }
  }
`;

const UPSERT_IPG_UT_PL_PN_LM_MN_MONTH = gql`
  mutation UpsertIpgUtPlPnLmMnMonth($input: UpsertIpgUtPlPnLmMnMonthInput!) {
    upsertIpgUtPlPnLmMnMonth(input: $input) {
      ${GRID_FIELDS}
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
 * Планы агента текущей ИП (`iuplIpg`).
 */
export async function fetchIpgUtPlByIpg(ipgKey: number): Promise<IpgUtPlDto[]> {
  try {
    const { data } = await apolloClient.query({
      query: IPG_UT_PL_BY_IPG,
      variables: { ipgKey },
      fetchPolicy: 'network-only'
    });
    return (data?.ipgUtPlByIpg ?? []) as IpgUtPlDto[];
  } catch (error) {
    throw wrapApolloError(error, 'ipgUtPlByIpg');
  }
}

/**
 * Грид месяц×stCost для плана+пункта.
 */
export async function fetchIpgUtPlPnLmMnGrid(
  plKey: number,
  ipgpKey: number
): Promise<IpgUtPlPnLmMnGridDto> {
  try {
    const { data } = await apolloClient.query({
      query: IPG_UT_PL_PN_LM_MN_GRID,
      variables: { plKey, ipgpKey },
      fetchPolicy: 'network-only'
    });
    return data.ipgUtPlPnLmMnGrid as IpgUtPlPnLmMnGridDto;
  } catch (error) {
    throw wrapApolloError(error, 'ipgUtPlPnLmMnGrid');
  }
}

/**
 * Создать план агента на ИП.
 */
export async function createIpgUtPl(input: {
  ipgKey: number;
  agKey: number;
  name?: string | null;
  date?: string | null;
}): Promise<IpgUtPlDto> {
  try {
    const { data } = await apolloClient.mutate({
      mutation: CREATE_IPG_UT_PL,
      variables: { input }
    });
    return data.createIpgUtPl as IpgUtPlDto;
  } catch (error) {
    throw wrapApolloError(error, 'createIpgUtPl');
  }
}

/**
 * Upsert оси C месяца (DoD A+B+G-agg на backend).
 */
export async function upsertIpgUtPlPnLmMnMonth(input: {
  plKey: number;
  ipgpKey: number;
  month: number;
  lim212?: number | null;
  lim195?: number | null;
  lim172?: number | null;
  lim187?: number | null;
}): Promise<IpgUtPlPnLmMnGridDto> {
  try {
    const { data } = await apolloClient.mutate({
      mutation: UPSERT_IPG_UT_PL_PN_LM_MN_MONTH,
      variables: { input }
    });
    return data.upsertIpgUtPlPnLmMnMonth as IpgUtPlPnLmMnGridDto;
  } catch (error) {
    throw wrapApolloError(error, 'upsertIpgUtPlPnLmMnMonth');
  }
}
