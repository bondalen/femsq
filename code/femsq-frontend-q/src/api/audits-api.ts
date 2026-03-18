/**
 * API клиент для работы с ревизиями.
 */

import { gql } from '@apollo/client/core';

import { apolloClient } from '@/plugins/apollo';
import { RequestError } from './http';
import type { RaACreateRequest, RaADto, RaAUpdateRequest } from '@/types/audits';

export type ApiError = RequestError;

function wrapApolloError(error: unknown, operation: string): RequestError {
  const message = error instanceof Error ? error.message : `Ошибка GraphQL операции ${operation}`;
  return new RequestError(message, {
    status: 0,
    statusText: 'GraphQL',
    url: '/graphql',
    body: { operation }
  });
}

const GET_AUDITS = gql`
  query GetAudits {
    audits {
      adtKey
      adtName
      adtDate
      adtResults
      adtDir
      adtType
      adtAddRA
      adtCreated
      adtUpdated
      adtStatus
    }
  }
`;

const GET_AUDIT = gql`
  query GetAudit($id: Int!) {
    audit(id: $id) {
      adtKey
      adtName
      adtDate
      adtResults
      adtDir
      adtType
      adtAddRA
      adtCreated
      adtUpdated
      adtStatus
    }
  }
`;

const CREATE_AUDIT = gql`
  mutation CreateAudit($input: AuditCreateInput!) {
    createAudit(input: $input) {
      adtKey
      adtName
      adtDate
      adtResults
      adtDir
      adtType
      adtAddRA
      adtCreated
      adtUpdated
      adtStatus
    }
  }
`;

const UPDATE_AUDIT = gql`
  mutation UpdateAudit($id: Int!, $input: AuditUpdateInput!) {
    updateAudit(id: $id, input: $input) {
      adtKey
      adtName
      adtDate
      adtResults
      adtDir
      adtType
      adtAddRA
      adtCreated
      adtUpdated
      adtStatus
    }
  }
`;

const DELETE_AUDIT = gql`
  mutation DeleteAudit($id: Int!) {
    deleteAudit(id: $id)
  }
`;

const EXECUTE_AUDIT = gql`
  mutation ExecuteAudit($id: Int!) {
    executeAudit(id: $id) {
      started
      alreadyRunning
      message
    }
  }
`;

/**
 * Получает список всех ревизий.
 */
export async function getAudits(): Promise<RaADto[]> {
  try {
    const result = await apolloClient.query<{ audits: RaADto[] }>({
      query: GET_AUDITS,
      fetchPolicy: 'network-only'
    });
    return result.data.audits;
  } catch (error) {
    throw wrapApolloError(error, 'GetAudits');
  }
}

/**
 * Получает ревизию по идентификатору.
 */
export async function getAuditById(id: number): Promise<RaADto> {
  try {
    const result = await apolloClient.query<{ audit: RaADto | null }>({
      query: GET_AUDIT,
      variables: { id },
      fetchPolicy: 'network-only'
    });
    if (!result.data.audit) {
      throw new RequestError('Ревизия не найдена', {
        status: 404,
        statusText: 'Not Found',
        url: '/graphql',
        body: { id }
      });
    }
    return result.data.audit;
  } catch (error) {
    if (error instanceof RequestError) {
      throw error;
    }
    throw wrapApolloError(error, 'GetAudit');
  }
}

/**
 * Создает новую ревизию.
 */
export async function createAudit(request: RaACreateRequest): Promise<RaADto> {
  try {
    const result = await apolloClient.mutate<{ createAudit: RaADto }>({
      mutation: CREATE_AUDIT,
      variables: { input: request }
    });
    if (!result.data?.createAudit) {
      throw new Error('Mutation CreateAudit returned no data');
    }
    return result.data.createAudit;
  } catch (error) {
    throw wrapApolloError(error, 'CreateAudit');
  }
}

/**
 * Обновляет существующую ревизию.
 */
export async function updateAudit(id: number, request: RaAUpdateRequest): Promise<RaADto> {
  try {
    const result = await apolloClient.mutate<{ updateAudit: RaADto }>({
      mutation: UPDATE_AUDIT,
      variables: { id, input: request }
    });
    if (!result.data?.updateAudit) {
      throw new Error('Mutation UpdateAudit returned no data');
    }
    return result.data.updateAudit;
  } catch (error) {
    throw wrapApolloError(error, 'UpdateAudit');
  }
}

/**
 * Удаляет ревизию.
 */
export async function deleteAudit(id: number): Promise<void> {
  try {
    await apolloClient.mutate<{ deleteAudit: boolean }>({
      mutation: DELETE_AUDIT,
      variables: { id }
    });
  } catch (error) {
    throw wrapApolloError(error, 'DeleteAudit');
  }
}

/**
 * Запускает выполнение ревизии (асинхронно, без ожидания результата).
 */
export interface AuditExecutionResult {
  started: boolean;
  alreadyRunning: boolean;
  message?: string | null;
}

export async function executeAudit(id: number): Promise<AuditExecutionResult> {
  try {
    const result = await apolloClient.mutate<{ executeAudit: AuditExecutionResult }>({
      mutation: EXECUTE_AUDIT,
      variables: { id }
    });
    if (!result.data?.executeAudit) {
      throw new Error('Mutation ExecuteAudit returned no data');
    }
    return result.data.executeAudit;
  } catch (error) {
    throw wrapApolloError(error, 'ExecuteAudit');
  }
}