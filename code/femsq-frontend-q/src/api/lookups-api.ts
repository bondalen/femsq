/**
 * GraphQL API клиент для lookup-справочников:
 * - investmentPrograms
 * - investmentPlanGroups
 * - stNetworks
 *
 * Использует схему `og-schema.graphqls` (см. Query в backend).
 */

import { gql } from '@apollo/client/core';

import { apolloClient } from '@/plugins/apollo';
import { RequestError } from './http';

export interface InvestmentProgramLookupDto {
  ipgKey: number;
  name: string;
}

export interface InvestmentPlanGroupLookupDto {
  planGroupKey: number;
  name: string;
}

export interface StNetworkDto {
  stNetKey: number;
  name: string;
}

const GET_INVESTMENT_PROGRAMS = gql`
  query GetInvestmentPrograms {
    investmentPrograms {
      ipgKey
      name
    }
  }
`;

const GET_PLAN_GROUPS = gql`
  query GetInvestmentPlanGroups {
    investmentPlanGroups {
      planGroupKey
      name
    }
  }
`;

const GET_ST_NETWORKS = gql`
  query GetStNetworks {
    stNetworks {
      stNetKey
      name
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

export async function getInvestmentProgramsLookup(): Promise<InvestmentProgramLookupDto[]> {
  try {
    const result = await apolloClient.query<{
      investmentPrograms: InvestmentProgramLookupDto[];
    }>({
      query: GET_INVESTMENT_PROGRAMS,
      fetchPolicy: 'network-only'
    });
    return result.data.investmentPrograms ?? [];
  } catch (error) {
    throw wrapApolloError(error, 'GetInvestmentPrograms');
  }
}

export async function getPlanGroupsLookup(): Promise<InvestmentPlanGroupLookupDto[]> {
  try {
    const result = await apolloClient.query<{
      investmentPlanGroups: InvestmentPlanGroupLookupDto[];
    }>({
      query: GET_PLAN_GROUPS,
      fetchPolicy: 'network-only'
    });
    return result.data.investmentPlanGroups ?? [];
  } catch (error) {
    throw wrapApolloError(error, 'GetInvestmentPlanGroups');
  }
}

export async function getStNetworksLookup(): Promise<StNetworkDto[]> {
  try {
    const result = await apolloClient.query<{ stNetworks: StNetworkDto[] }>({
      query: GET_ST_NETWORKS,
      fetchPolicy: 'network-only'
    });
    return result.data.stNetworks ?? [];
  } catch (error) {
    throw wrapApolloError(error, 'GetStNetworks');
  }
}

