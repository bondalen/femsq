/**
 * API клиент для работы с файлами ревизий через GraphQL.
 */

import { gql } from '@apollo/client/core';

import { apolloClient } from '@/plugins/apollo';
import { RequestError } from './http';
import type { RaFDto, RaFCreateRequest, RaFUpdateRequest } from '@/types/files';

const GET_FILES = gql`
  query GetFiles {
    files {
      afKey
      afName
      afDir
      afType
      afExecute
      afSource
      afCreated
      afUpdated
      raOrgSender
      afNum
    }
  }
`;

const GET_FILE = gql`
  query GetFile($id: Int!) {
    file(id: $id) {
      afKey
      afName
      afDir
      afType
      afExecute
      afSource
      afCreated
      afUpdated
      raOrgSender
      afNum
    }
  }
`;

const GET_FILES_BY_DIRECTORY = gql`
  query GetFilesByDirectory($dirId: Int!) {
    filesByDirectory(dirId: $dirId) {
      afKey
      afName
      afDir
      afType
      afExecute
      afSource
      afCreated
      afUpdated
      raOrgSender
      afNum
    }
  }
`;

const CREATE_FILE = gql`
  mutation CreateFile($input: FileCreateInput!) {
    createFile(input: $input) {
      afKey
      afName
      afDir
      afType
      afExecute
      afSource
      afCreated
      afUpdated
      raOrgSender
      afNum
    }
  }
`;

const UPDATE_FILE = gql`
  mutation UpdateFile($id: Int!, $input: FileUpdateInput!) {
    updateFile(id: $id, input: $input) {
      afKey
      afName
      afDir
      afType
      afExecute
      afSource
      afCreated
      afUpdated
      raOrgSender
      afNum
    }
  }
`;

const DELETE_FILE = gql`
  mutation DeleteFile($id: Int!) {
    deleteFile(id: $id)
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
 * Получить все файлы.
 */
export async function getAllFiles(): Promise<RaFDto[]> {
  try {
    const result = await apolloClient.query<{ files: RaFDto[] }>({
      query: GET_FILES,
      fetchPolicy: 'network-only'
    });
    return result.data.files;
  } catch (error) {
    throw wrapApolloError(error, 'GetFiles');
  }
}

/**
 * Получить файл по ID.
 */
export async function getFileById(id: number): Promise<RaFDto> {
  try {
    const result = await apolloClient.query<{ file: RaFDto | null }>({
      query: GET_FILE,
      variables: { id },
      fetchPolicy: 'network-only'
    });
    if (!result.data.file) {
      throw new RequestError('Файл не найден', {
        status: 404,
        statusText: 'Not Found',
        url: '/graphql',
        body: { id }
      });
    }
    return result.data.file;
  } catch (error) {
    if (error instanceof RequestError) {
      throw error;
    }
    throw wrapApolloError(error, 'GetFile');
  }
}

/**
 * Получить файлы по директории.
 */
export async function getFilesByDirId(dirId: number): Promise<RaFDto[]> {
  try {
    const result = await apolloClient.query<{ filesByDirectory: RaFDto[] }>({
      query: GET_FILES_BY_DIRECTORY,
      variables: { dirId },
      fetchPolicy: 'network-only'
    });
    return result.data.filesByDirectory;
  } catch (error) {
    throw wrapApolloError(error, 'GetFilesByDirectory');
  }
}

/**
 * Создать файл.
 */
export async function createFile(data: RaFCreateRequest): Promise<RaFDto> {
  try {
    const result = await apolloClient.mutate<{ createFile: RaFDto }>({
      mutation: CREATE_FILE,
      variables: { input: data }
    });
    if (!result.data?.createFile) {
      throw new Error('Mutation CreateFile returned no data');
    }
    return result.data.createFile;
  } catch (error) {
    throw wrapApolloError(error, 'CreateFile');
  }
}

/**
 * Обновить файл.
 */
export async function updateFile(id: number, data: RaFUpdateRequest): Promise<RaFDto> {
  try {
    const result = await apolloClient.mutate<{ updateFile: RaFDto }>({
      mutation: UPDATE_FILE,
      variables: { id, input: data }
    });
    if (!result.data?.updateFile) {
      throw new Error('Mutation UpdateFile returned no data');
    }
    return result.data.updateFile;
  } catch (error) {
    throw wrapApolloError(error, 'UpdateFile');
  }
}

/**
 * Удалить файл.
 */
export async function deleteFile(id: number): Promise<void> {
  try {
    await apolloClient.mutate<{ deleteFile: boolean }>({
      mutation: DELETE_FILE,
      variables: { id }
    });
  } catch (error) {
    throw wrapApolloError(error, 'DeleteFile');
  }
}
