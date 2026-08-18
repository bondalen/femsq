/**
 * Apollo: relationNode / relationExpand (не экран СУДЗ).
 */
import { gql } from '@apollo/client/core';

import { apolloClient } from '@/plugins/apollo';
import { RequestError } from './http';

/** Поле строки. */
export interface RelationApiField {
  name: string;
  value: string | null;
}

/** Строка expand/get. */
export interface RelationApiRow {
  key: number;
  fields: RelationApiField[];
}

function wrapApolloError(error: unknown, operation: string): RequestError {
  const message = error instanceof Error ? error.message : `Ошибка GraphQL операции ${operation}`;
  return new RequestError(message, {
    status: 0,
    statusText: 'GraphQL',
    url: '/graphql',
    body: { operation }
  });
}

const RELATION_ROW_FIELDS = `
  key
  fields { name value }
`;

const RELATION_NODE = gql`
  query RelationNode($table: String!, $id: Int!) {
    relationNode(table: $table, id: $id) {
      ${RELATION_ROW_FIELDS}
    }
  }
`;

const RELATION_EXPAND = gql`
  query RelationExpand($edge: String!, $fromId: Int!) {
    relationExpand(edge: $edge, fromId: $fromId) {
      ${RELATION_ROW_FIELDS}
    }
  }
`;

/**
 * Строка таблицы каталога.
 *
 * @param table имя JSON
 * @param id PK
 * @return строка или null
 */
export async function fetchRelationNode(table: string, id: number): Promise<RelationApiRow | null> {
  try {
    const result = await apolloClient.query<{ relationNode: RelationApiRow | null }>({
      query: RELATION_NODE,
      variables: { table, id },
      fetchPolicy: 'network-only'
    });
    return result.data?.relationNode ?? null;
  } catch (error) {
    throw wrapApolloError(error, 'RelationNode');
  }
}

/**
 * Раскрытие ребра каталога.
 *
 * @param edge имя JSON
 * @param fromId PK from
 * @return строки to
 */
export async function fetchRelationExpand(edge: string, fromId: number): Promise<RelationApiRow[]> {
  try {
    const result = await apolloClient.query<{ relationExpand: RelationApiRow[] }>({
      query: RELATION_EXPAND,
      variables: { edge, fromId },
      fetchPolicy: 'network-only'
    });
    return result.data?.relationExpand ?? [];
  } catch (error) {
    throw wrapApolloError(error, 'RelationExpand');
  }
}
