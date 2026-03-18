/**
 * API клиент для работы с типами ревизий.
 */

import { gql } from '@apollo/client/core';

import { apolloClient } from '@/plugins/apollo';
import { RequestError } from './http';
import type { RaAtDto } from '@/types/audits';

export type ApiError = RequestError;

const GET_AUDIT_TYPES = gql`
  query GetAuditTypes {
    auditTypes {
      atKey
      atName
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

/**
 * Получает список всех типов ревизий.
 */
export async function getAuditTypes(): Promise<RaAtDto[]> {
  try {
    const result = await apolloClient.query<{ auditTypes: RaAtDto[] }>({
      query: GET_AUDIT_TYPES,
      fetchPolicy: 'network-only'
    });
    return result.data.auditTypes;
  } catch (error) {
    throw wrapApolloError(error, 'GetAuditTypes');
  }
}