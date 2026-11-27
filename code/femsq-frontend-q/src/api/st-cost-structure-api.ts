/**
 * GraphQL API структуры затрат (C2 O2 §4.0.1 / §4.0.2).
 *
 * Операции `stCost*` из `og-schema.graphqls`: схемы stNet type=2, дерево fnSt, CRUD.
 */

import { gql } from '@apollo/client/core';

import { apolloClient } from '@/plugins/apollo';
import { RequestError } from './http';
import type { StIpgNetworkDto, StIpgTreeNodeDto } from './st-ipg-structure-api';

/** Схема структуры затрат (`ags.stNet`, stnType=2) — те же поля, что у ИПГ. */
export type StCostNetworkDto = StIpgNetworkDto;

/** Плоская строка обхода `ags.fnSt` для cost-net. */
export type StCostTreeNodeDto = StIpgTreeNodeDto;

/** Alias-имя узла (`ags.stCostNm`). */
export interface StCostNmDto {
  stcnKey: number;
  stcKey: number;
  name: string;
}

const ST_COST_NETWORK_FIELDS = `
  stNetKey
  stNetType
  name
  rootKey
`;

const ST_COST_TREE_FIELDS = `
  childKey
  parentKey
  stpnNum
  pnLevel
  stNum
  name
  stRelKey
  stNetPnKey
`;

const GET_ST_COST_NETWORKS = gql`
  query GetStCostNetworks {
    stCostNetworks {
      ${ST_COST_NETWORK_FIELDS}
    }
  }
`;

const GET_ST_COST_NETWORK_TREE = gql`
  query GetStCostNetworkTree($stNetKey: Int!, $rootKey: Int) {
    stCostNetworkTree(stNetKey: $stNetKey, rootKey: $rootKey) {
      ${ST_COST_TREE_FIELDS}
    }
  }
`;

const CREATE_ST_COST_NETWORK = gql`
  mutation CreateStCostNetwork($name: String!, $rootKey: Int!) {
    createStCostNetwork(name: $name, rootKey: $rootKey) {
      ${ST_COST_NETWORK_FIELDS}
    }
  }
`;

const RENAME_ST_COST_NETWORK = gql`
  mutation RenameStCostNetwork($id: Int!, $name: String!) {
    renameStCostNetwork(id: $id, name: $name) {
      ${ST_COST_NETWORK_FIELDS}
    }
  }
`;

const CLONE_ST_COST_NETWORK = gql`
  mutation CloneStCostNetwork($sourceId: Int!, $newName: String!) {
    cloneStCostNetwork(sourceId: $sourceId, newName: $newName) {
      ${ST_COST_NETWORK_FIELDS}
    }
  }
`;

const CREATE_ST_COST_CHILD_NODE = gql`
  mutation CreateStCostChildNode(
    $stNetKey: Int!
    $parentKey: Int!
    $name: String!
    $stpnNum: Int
  ) {
    createStCostChildNode(
      stNetKey: $stNetKey
      parentKey: $parentKey
      name: $name
      stpnNum: $stpnNum
    ) {
      ${ST_COST_TREE_FIELDS}
    }
  }
`;

const RENAME_ST_COST_NODE = gql`
  mutation RenameStCostNode($stcKey: Int!, $name: String!) {
    renameStCostNode(stcKey: $stcKey, name: $name)
  }
`;

const GET_ST_COST_NODE_NAMES = gql`
  query GetStCostNodeNames($stcKey: Int!) {
    stCostNodeNames(stcKey: $stcKey) {
      stcnKey
      stcKey
      name
    }
  }
`;

const ADD_ST_COST_NODE_NAME = gql`
  mutation AddStCostNodeName($stcKey: Int!, $name: String!) {
    addStCostNodeName(stcKey: $stcKey, name: $name) {
      stcnKey
      stcKey
      name
    }
  }
`;

const ATTACH_ST_COST_EDGE = gql`
  mutation AttachStCostEdge(
    $stNetKey: Int!
    $parentKey: Int!
    $childKey: Int!
    $stpnNum: Int
  ) {
    attachStCostEdge(
      stNetKey: $stNetKey
      parentKey: $parentKey
      childKey: $childKey
      stpnNum: $stpnNum
    )
  }
`;

const MOVE_ST_COST_EDGE = gql`
  mutation MoveStCostEdge(
    $stNetKey: Int!
    $childKey: Int!
    $fromParentKey: Int!
    $toParentKey: Int!
    $stpnNum: Int
  ) {
    moveStCostEdge(
      stNetKey: $stNetKey
      childKey: $childKey
      fromParentKey: $fromParentKey
      toParentKey: $toParentKey
      stpnNum: $stpnNum
    )
  }
`;

const DETACH_ST_COST_EDGE = gql`
  mutation DetachStCostEdge($stNetKey: Int!, $parentKey: Int!, $childKey: Int!) {
    detachStCostEdge(stNetKey: $stNetKey, parentKey: $parentKey, childKey: $childKey)
  }
`;

const DELETE_ST_COST_NODE = gql`
  mutation DeleteStCostNode($stNetKey: Int!, $stcKey: Int!) {
    deleteStCostNode(stNetKey: $stNetKey, stcKey: $stcKey)
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

/** Список схем затрат. */
export async function getStCostNetworks(): Promise<StCostNetworkDto[]> {
  try {
    const result = await apolloClient.query<{ stCostNetworks: StCostNetworkDto[] }>({
      query: GET_ST_COST_NETWORKS,
      fetchPolicy: 'network-only'
    });
    return result.data.stCostNetworks ?? [];
  } catch (error) {
    throw wrapApolloError(error, 'GetStCostNetworks');
  }
}

/**
 * Дерево схемы затрат через fnSt.
 *
 * @param stNetKey ключ схемы
 * @param rootKey корень обхода; null → stnRoot на сервере
 */
export async function getStCostNetworkTree(
  stNetKey: number,
  rootKey?: number | null
): Promise<StCostTreeNodeDto[]> {
  try {
    const result = await apolloClient.query<{ stCostNetworkTree: StCostTreeNodeDto[] }>({
      query: GET_ST_COST_NETWORK_TREE,
      variables: { stNetKey, rootKey: rootKey ?? null },
      fetchPolicy: 'network-only'
    });
    return result.data.stCostNetworkTree ?? [];
  } catch (error) {
    throw wrapApolloError(error, 'GetStCostNetworkTree');
  }
}

/** Создать схему type=2. */
export async function createStCostNetwork(name: string, rootKey: number): Promise<StCostNetworkDto> {
  try {
    const result = await apolloClient.mutate<{ createStCostNetwork: StCostNetworkDto }>({
      mutation: CREATE_ST_COST_NETWORK,
      variables: { name, rootKey }
    });
    const created = result.data?.createStCostNetwork;
    if (!created) {
      throw new Error('createStCostNetwork: пустой ответ');
    }
    return created;
  } catch (error) {
    throw wrapApolloError(error, 'CreateStCostNetwork');
  }
}

/** Переименовать схему. */
export async function renameStCostNetwork(id: number, name: string): Promise<StCostNetworkDto> {
  try {
    const result = await apolloClient.mutate<{ renameStCostNetwork: StCostNetworkDto }>({
      mutation: RENAME_ST_COST_NETWORK,
      variables: { id, name }
    });
    const updated = result.data?.renameStCostNetwork;
    if (!updated) {
      throw new Error('renameStCostNetwork: пустой ответ');
    }
    return updated;
  } catch (error) {
    throw wrapApolloError(error, 'RenameStCostNetwork');
  }
}

/** Клон схемы (shared-узлы). */
export async function cloneStCostNetwork(
  sourceId: number,
  newName: string
): Promise<StCostNetworkDto> {
  try {
    const result = await apolloClient.mutate<{ cloneStCostNetwork: StCostNetworkDto }>({
      mutation: CLONE_ST_COST_NETWORK,
      variables: { sourceId, newName }
    });
    const cloned = result.data?.cloneStCostNetwork;
    if (!cloned) {
      throw new Error('cloneStCostNetwork: пустой ответ');
    }
    return cloned;
  } catch (error) {
    throw wrapApolloError(error, 'CloneStCostNetwork');
  }
}

/** Создать дочерний узел в схеме. */
export async function createStCostChildNode(input: {
  stNetKey: number;
  parentKey: number;
  name: string;
  stpnNum?: number | null;
}): Promise<StCostTreeNodeDto> {
  try {
    const result = await apolloClient.mutate<{ createStCostChildNode: StCostTreeNodeDto }>({
      mutation: CREATE_ST_COST_CHILD_NODE,
      variables: {
        stNetKey: input.stNetKey,
        parentKey: input.parentKey,
        name: input.name,
        stpnNum: input.stpnNum ?? null
      }
    });
    const created = result.data?.createStCostChildNode;
    if (!created) {
      throw new Error('createStCostChildNode: пустой ответ');
    }
    return created;
  } catch (error) {
    throw wrapApolloError(error, 'CreateStCostChildNode');
  }
}

/** Переименовать узел (первичное stCostNm). */
export async function renameStCostNode(stcKey: number, name: string): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ renameStCostNode: boolean }>({
      mutation: RENAME_ST_COST_NODE,
      variables: { stcKey, name }
    });
    return Boolean(result.data?.renameStCostNode);
  } catch (error) {
    throw wrapApolloError(error, 'RenameStCostNode');
  }
}

/** Список имён/aliases узла. */
export async function getStCostNodeNames(stcKey: number): Promise<StCostNmDto[]> {
  try {
    const result = await apolloClient.query<{ stCostNodeNames: StCostNmDto[] }>({
      query: GET_ST_COST_NODE_NAMES,
      variables: { stcKey },
      fetchPolicy: 'network-only'
    });
    return result.data.stCostNodeNames ?? [];
  } catch (error) {
    throw wrapApolloError(error, 'GetStCostNodeNames');
  }
}

/** Добавить alias-имя узла. */
export async function addStCostNodeName(stcKey: number, name: string): Promise<StCostNmDto> {
  try {
    const result = await apolloClient.mutate<{ addStCostNodeName: StCostNmDto }>({
      mutation: ADD_ST_COST_NODE_NAME,
      variables: { stcKey, name }
    });
    const created = result.data?.addStCostNodeName;
    if (!created) {
      throw new Error('addStCostNodeName: пустой ответ');
    }
    return created;
  } catch (error) {
    throw wrapApolloError(error, 'AddStCostNodeName');
  }
}

/** Привязать существующий узел под parent в схеме. */
export async function attachStCostEdge(input: {
  stNetKey: number;
  parentKey: number;
  childKey: number;
  stpnNum?: number | null;
}): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ attachStCostEdge: boolean }>({
      mutation: ATTACH_ST_COST_EDGE,
      variables: {
        stNetKey: input.stNetKey,
        parentKey: input.parentKey,
        childKey: input.childKey,
        stpnNum: input.stpnNum ?? null
      }
    });
    return Boolean(result.data?.attachStCostEdge);
  } catch (error) {
    throw wrapApolloError(error, 'AttachStCostEdge');
  }
}

/** Перенести ребёнка в схеме (смена родителя). */
export async function moveStCostEdge(input: {
  stNetKey: number;
  childKey: number;
  fromParentKey: number;
  toParentKey: number;
  stpnNum?: number | null;
}): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ moveStCostEdge: boolean }>({
      mutation: MOVE_ST_COST_EDGE,
      variables: {
        stNetKey: input.stNetKey,
        childKey: input.childKey,
        fromParentKey: input.fromParentKey,
        toParentKey: input.toParentKey,
        stpnNum: input.stpnNum ?? null
      }
    });
    return Boolean(result.data?.moveStCostEdge);
  } catch (error) {
    throw wrapApolloError(error, 'MoveStCostEdge');
  }
}

/** Отсоединить ребро от схемы. */
export async function detachStCostEdge(
  stNetKey: number,
  parentKey: number,
  childKey: number
): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ detachStCostEdge: boolean }>({
      mutation: DETACH_ST_COST_EDGE,
      variables: { stNetKey, parentKey, childKey }
    });
    return Boolean(result.data?.detachStCostEdge);
  } catch (error) {
    throw wrapApolloError(error, 'DetachStCostEdge');
  }
}

/** Удалить узел (строгая политика на сервере). */
export async function deleteStCostNode(stNetKey: number, stcKey: number): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ deleteStCostNode: boolean }>({
      mutation: DELETE_ST_COST_NODE,
      variables: { stNetKey, stcKey }
    });
    return Boolean(result.data?.deleteStCostNode);
  } catch (error) {
    throw wrapApolloError(error, 'DeleteStCostNode');
  }
}
