/**
 * API клиент для работы со справочником типов файлов (ra_ft) через GraphQL.
 */

import { gql } from '@apollo/client/core';

import { apolloClient } from '@/plugins/apollo';
import { RequestError } from './http';
import type { RaFtDto } from '@/types/files';

const GET_FILE_TYPES = gql`
  query GetFileTypes {
    fileTypes {
      ftKey
      ftName
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
 * Получить все типы файлов.
 */
export async function getAllFileTypes(): Promise<RaFtDto[]> {
  try {
    const result = await apolloClient.query<{ fileTypes: RaFtDto[] }>({
      query: GET_FILE_TYPES,
      fetchPolicy: 'network-only'
    });
    return result.data.fileTypes;
  } catch (error) {
    throw wrapApolloError(error, 'GetFileTypes');
  }
}

/**
 * Получить тип файла по ID.
 */
export async function getFileTypeById(id: number): Promise<RaFtDto> {
  try {
    const result = await apolloClient.query<{ fileTypes: RaFtDto[] }>({
      query: GET_FILE_TYPES,
      fetchPolicy: 'network-only'
    });
    const found = result.data.fileTypes.find((ft) => ft.ftKey === id) ?? null;
    if (!found) {
      throw new RequestError('Тип файла не найден', {
        status: 404,
        statusText: 'Not Found',
        url: '/graphql',
        body: { id }
      });
    }
    return found;
  } catch (error) {
    if (error instanceof RequestError) {
      throw error;
    }
    throw wrapApolloError(error, 'GetFileTypeById');
  }
}
