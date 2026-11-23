/**
 * API клиент для работы с цепочками инвестиционных программ (investment chains).
 *
 * Использует GraphQL-схему `og-schema.graphqls`:
 * - query `investmentChains(name, year)` — список цепочек;
 * - query `investmentChainRelations(chainId)` — связи цепочки с программами и группами планов.
 */

import { gql } from '@apollo/client/core';

import { apolloClient } from '@/plugins/apollo';
import { RequestError } from './http';

export interface IpgChainDto {
  chainKey: number;
  name: string;
  stNetKey?: number | null;
  stNetName?: string | null;
  latestIpgKey?: number | null;
  year?: number | null;
}

export interface IpgChainRelationDto {
  relationKey: number;
  chainKey: number;
  investmentProgramKey: number;
  investmentProgramName?: string | null;
  planGroupKey?: number | null;
  planGroupName?: string | null;
}

const GET_INVESTMENT_CHAINS = gql`
  query GetInvestmentChains($name: String, $year: Int) {
    investmentChains(name: $name, year: $year) {
      chainKey
      name
      stNetKey
      stNetName
      latestIpgKey
      year
    }
  }
`;

const GET_INVESTMENT_CHAIN_RELATIONS = gql`
  query GetInvestmentChainRelations($chainId: Int!) {
    investmentChainRelations(chainId: $chainId) {
      relationKey
      chainKey
      investmentProgramKey
      investmentProgramName
      planGroupKey
      planGroupName
    }
  }
`;

const CREATE_INVESTMENT_CHAIN = gql`
  mutation CreateInvestmentChain($input: CreateInvestmentChainInput!) {
    createInvestmentChain(input: $input) {
      chainKey
      name
      stNetKey
      stNetName
      latestIpgKey
      year
    }
  }
`;

const UPDATE_INVESTMENT_CHAIN = gql`
  mutation UpdateInvestmentChain($id: Int!, $input: UpdateInvestmentChainInput!) {
    updateInvestmentChain(id: $id, input: $input) {
      chainKey
      name
      stNetKey
      stNetName
      latestIpgKey
      year
    }
  }
`;

const DELETE_INVESTMENT_CHAIN = gql`
  mutation DeleteInvestmentChain($id: Int!) {
    deleteInvestmentChain(id: $id)
  }
`;

const ADD_IPG_TO_CHAIN = gql`
  mutation AddIpgToChain($input: AddIpgToChainInput!) {
    addIpgToChain(input: $input) {
      relationKey
      chainKey
      investmentProgramKey
      investmentProgramName
      planGroupKey
      planGroupName
    }
  }
`;

const UPDATE_CHAIN_RELATION = gql`
  mutation UpdateChainRelation($id: Int!, $input: UpdateChainRelationInput!) {
    updateChainRelation(id: $id, input: $input) {
      relationKey
      chainKey
      investmentProgramKey
      investmentProgramName
      planGroupKey
      planGroupName
    }
  }
`;

const REMOVE_IPG_FROM_CHAIN = gql`
  mutation RemoveIpgFromChain($id: Int!) {
    removeIpgFromChain(id: $id)
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

export interface InvestmentChainsQuery {
  page: number;
  size: number;
  sort: string;
  name?: string;
  year?: number | null;
}

export interface InvestmentChainsPage {
  content: IpgChainDto[];
  totalElements: number;
  totalPages: number;
  page: number;
  size: number;
}

/**
 * Получить страницу цепочек инвестиционных программ.
 *
 * Backend GraphQL возвращает полный список по фильтрам `name`/`year`,
 * поэтому пагинация и сортировка выполняются на клиенте.
 */
export async function getInvestmentChainsPage(
  query: InvestmentChainsQuery
): Promise<InvestmentChainsPage> {
  const variables: { name?: string; year?: number } = {};
  if (query.name && query.name.trim().length > 0) {
    variables.name = query.name.trim();
  }
  if (typeof query.year === 'number') {
    variables.year = query.year;
  }

  try {
    const result = await apolloClient.query<{ investmentChains: IpgChainDto[] }>({
      query: GET_INVESTMENT_CHAINS,
      variables,
      fetchPolicy: 'network-only'
    });

    const all = result.data.investmentChains ?? [];

    const sorted = (() => {
      const [field, directionRaw] = query.sort.split(',');
      const direction = directionRaw === 'desc' ? -1 : 1;

      if (field === 'name') {
        return [...all].sort((a, b) => (a.name ?? '').localeCompare(b.name ?? '') * direction);
      }
      if (field === 'chainKey') {
        return [...all].sort((a, b) => ((a.chainKey ?? 0) - (b.chainKey ?? 0)) * direction);
      }

      return all;
    })();

    const size = query.size > 0 ? query.size : sorted.length || 1;
    const totalElements = sorted.length;
    const totalPages = totalElements === 0 ? 0 : Math.ceil(totalElements / size);

    const maxPageIndex = Math.max(totalPages - 1, 0);
    const page = Math.min(Math.max(query.page, 0), maxPageIndex);

    const start = page * size;
    const end = start + size;
    const pageContent = sorted.slice(start, end);

    return {
      content: pageContent,
      totalElements,
      totalPages,
      page,
      size
    };
  } catch (error) {
    throw wrapApolloError(error, 'GetInvestmentChains');
  }
}

/**
 * Получить связи для указанной цепочки.
 */
export async function getInvestmentChainRelations(
  chainId: number
): Promise<IpgChainRelationDto[]> {
  try {
    const result = await apolloClient.query<{ investmentChainRelations: IpgChainRelationDto[] }>({
      query: GET_INVESTMENT_CHAIN_RELATIONS,
      variables: { chainId },
      fetchPolicy: 'network-only'
    });

    return result.data.investmentChainRelations ?? [];
  } catch (error) {
    throw wrapApolloError(error, 'GetInvestmentChainRelations');
  }
}

/** Создать цепочку (только имя; stNet/late/year — computed). */
export async function createInvestmentChain(name: string): Promise<IpgChainDto> {
  try {
    const result = await apolloClient.mutate<{ createInvestmentChain: IpgChainDto }>({
      mutation: CREATE_INVESTMENT_CHAIN,
      variables: { input: { name } }
    });
    const created = result.data?.createInvestmentChain;
    if (!created) {
      throw new Error('createInvestmentChain: пустой ответ');
    }
    return created;
  } catch (error) {
    throw wrapApolloError(error, 'CreateInvestmentChain');
  }
}

/** Переименовать цепочку. */
export async function updateInvestmentChain(id: number, name: string): Promise<IpgChainDto> {
  try {
    const result = await apolloClient.mutate<{ updateInvestmentChain: IpgChainDto }>({
      mutation: UPDATE_INVESTMENT_CHAIN,
      variables: { id, input: { name } }
    });
    const updated = result.data?.updateInvestmentChain;
    if (!updated) {
      throw new Error('updateInvestmentChain: пустой ответ');
    }
    return updated;
  } catch (error) {
    throw wrapApolloError(error, 'UpdateInvestmentChain');
  }
}

/** Удалить цепочку (cascade ipgChRl). */
export async function deleteInvestmentChain(id: number): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ deleteInvestmentChain: boolean }>({
      mutation: DELETE_INVESTMENT_CHAIN,
      variables: { id }
    });
    return Boolean(result.data?.deleteInvestmentChain);
  } catch (error) {
    throw wrapApolloError(error, 'DeleteInvestmentChain');
  }
}

/** Добавить ИП в цепь. */
export async function addIpgToChain(input: {
  chainKey: number;
  investmentProgramKey: number;
  planGroupKey?: number | null;
}): Promise<IpgChainRelationDto> {
  try {
    const result = await apolloClient.mutate<{ addIpgToChain: IpgChainRelationDto }>({
      mutation: ADD_IPG_TO_CHAIN,
      variables: {
        input: {
          chainKey: input.chainKey,
          investmentProgramKey: input.investmentProgramKey,
          planGroupKey: input.planGroupKey ?? null
        }
      }
    });
    const created = result.data?.addIpgToChain;
    if (!created) {
      throw new Error('addIpgToChain: пустой ответ');
    }
    return created;
  } catch (error) {
    throw wrapApolloError(error, 'AddIpgToChain');
  }
}

/** Обновить связь (ИП / группа планов). */
export async function updateChainRelation(
  id: number,
  input: { investmentProgramKey: number; planGroupKey?: number | null }
): Promise<IpgChainRelationDto> {
  try {
    const result = await apolloClient.mutate<{ updateChainRelation: IpgChainRelationDto }>({
      mutation: UPDATE_CHAIN_RELATION,
      variables: {
        id,
        input: {
          investmentProgramKey: input.investmentProgramKey,
          planGroupKey: input.planGroupKey ?? null
        }
      }
    });
    const updated = result.data?.updateChainRelation;
    if (!updated) {
      throw new Error('updateChainRelation: пустой ответ');
    }
    return updated;
  } catch (error) {
    throw wrapApolloError(error, 'UpdateChainRelation');
  }
}

/** Убрать ИП из цепи. */
export async function removeIpgFromChain(id: number): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ removeIpgFromChain: boolean }>({
      mutation: REMOVE_IPG_FROM_CHAIN,
      variables: { id }
    });
    return Boolean(result.data?.removeIpgFromChain);
  } catch (error) {
    throw wrapApolloError(error, 'RemoveIpgFromChain');
  }
}

