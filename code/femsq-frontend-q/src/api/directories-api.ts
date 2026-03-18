/**
 * API клиент для работы с директориями ревизий
 */

import { gql } from '@apollo/client/core';

import { apolloClient } from '@/plugins/apollo';
import { RequestError } from './http';
import type { RaDirDto } from '@/types/audits';
import type { DirectoryDto } from '@/types/files';

function wrapApolloError(error: unknown, operation: string): RequestError {
  const message = error instanceof Error ? error.message : `Ошибка GraphQL операции ${operation}`;
  return new RequestError(message, {
    status: 0,
    statusText: 'GraphQL',
    url: '/graphql',
    body: { operation }
  });
}

const GET_DIRECTORIES = gql`
  query GetDirectories {
    directories {
      key
      dirName
      dir
      dirCreated
      dirUpdated
    }
  }
`;

const GET_DIRECTORY_BY_ID = gql`
  query GetDirectoryById($id: Int!) {
    directories {
      key
      dirName
      dir
      dirCreated
      dirUpdated
    }
  }
`;

const GET_DIRECTORY_BY_AUDIT_ID = gql`
  query GetDirectoryByAuditId($id: Int!) {
    audit(id: $id) {
      adtKey
      directory {
        key
        dirName
        dir
        dirCreated
        dirUpdated
      }
    }
  }
`;

/**
 * Получить все директории (возвращает RaDirDto - соответствует backend API)
 */
export async function getDirectories(): Promise<RaDirDto[]> {
  try {
    const result = await apolloClient.query<{ directories: RaDirDto[] }>({
      query: GET_DIRECTORIES,
      fetchPolicy: 'network-only'
    });
    return result.data.directories;
  } catch (error) {
    throw wrapApolloError(error, 'GetDirectories');
  }
}

/**
 * Получить все директории (алиас для совместимости)
 * @deprecated Используйте getDirectories() который возвращает RaDirDto
 */
export async function getAllDirectories(): Promise<DirectoryDto[]> {
  const raDirs = await getDirectories();
  // Адаптер: преобразуем RaDirDto в DirectoryDto для совместимости
  return raDirs.map((dir) => ({
    key: dir.key,
    dirName: dir.dirName,
    dir: dir.dir,
    created: dir.dirCreated || null,
    updated: dir.dirUpdated || null
  }));
}

/**
 * Получить директорию по ID
 */
export async function getDirectoryById(id: number): Promise<RaDirDto> {
  try {
    // В схеме нет отдельного query directory(id), поэтому фильтруем по справочнику.
    const result = await apolloClient.query<{ directories: RaDirDto[] }>({
      query: GET_DIRECTORIES,
      fetchPolicy: 'network-only'
    });
    const found = result.data.directories.find((d) => d.key === id) ?? null;
    if (!found) {
      throw new RequestError('Директория не найдена', {
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
    throw wrapApolloError(error, 'GetDirectoryById');
  }
}

/**
 * Получить директорию для ревизии (связь 1:1)
 */
export async function getDirectoryByAuditId(auditId: number): Promise<RaDirDto> {
  try {
    const result = await apolloClient.query<{ audit: { directory: RaDirDto | null } | null }>({
      query: GET_DIRECTORY_BY_AUDIT_ID,
      variables: { id: auditId },
      fetchPolicy: 'network-only'
    });
    const directory = result.data.audit?.directory ?? null;
    if (!directory) {
      throw new RequestError('Директория ревизии не найдена', {
        status: 404,
        statusText: 'Not Found',
        url: '/graphql',
        body: { auditId }
      });
    }
    return directory;
  } catch (error) {
    if (error instanceof RequestError) {
      throw error;
    }
    throw wrapApolloError(error, 'GetDirectoryByAuditId');
  }
}
