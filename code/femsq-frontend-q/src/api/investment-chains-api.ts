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

