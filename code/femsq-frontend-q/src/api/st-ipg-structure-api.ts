/**
 * GraphQL API структуры ИПГ (C2 §2.4.1 / §2.5.1).
 *
 * Операции из `og-schema.graphqls`: схемы stNet type=1, дерево fnSt, CRUD узлов/рёбер.
 */

import { gql } from '@apollo/client/core';

import { apolloClient } from '@/plugins/apollo';
import { RequestError } from './http';

/** Схема структуры ИПГ (`ags.stNet`, stnType=1). */
export interface StIpgNetworkDto {
  stNetKey: number;
  stNetType: number;
  name: string;
  rootKey: number;
}

/** Плоская строка обхода `ags.fnSt`. */
export interface StIpgTreeNodeDto {
  childKey: number;
  parentKey: number | null;
  stpnNum: number | null;
  pnLevel: number | null;
  stNum: string | null;
  name: string | null;
  stRelKey: number | null;
  stNetPnKey: number | null;
}

/** Alias-имя узла (`ags.stIpgNm`). */
export interface StIpgNmDto {
  stinKey: number;
  stiKey: number;
  name: string;
}

const ST_IPG_NETWORK_FIELDS = `
  stNetKey
  stNetType
  name
  rootKey
`;

const ST_IPG_TREE_FIELDS = `
  childKey
  parentKey
  stpnNum
  pnLevel
  stNum
  name
  stRelKey
  stNetPnKey
`;

const GET_ST_IPG_NETWORKS = gql`
  query GetStIpgNetworks {
    stIpgNetworks {
      ${ST_IPG_NETWORK_FIELDS}
    }
  }
`;

const GET_ST_IPG_NETWORK_TREE = gql`
  query GetStIpgNetworkTree($stNetKey: Int!, $rootKey: Int) {
    stIpgNetworkTree(stNetKey: $stNetKey, rootKey: $rootKey) {
      ${ST_IPG_TREE_FIELDS}
    }
  }
`;

const CREATE_ST_IPG_NETWORK = gql`
  mutation CreateStIpgNetwork($name: String!, $rootKey: Int!) {
    createStIpgNetwork(name: $name, rootKey: $rootKey) {
      ${ST_IPG_NETWORK_FIELDS}
    }
  }
`;

const RENAME_ST_IPG_NETWORK = gql`
  mutation RenameStIpgNetwork($id: Int!, $name: String!) {
    renameStIpgNetwork(id: $id, name: $name) {
      ${ST_IPG_NETWORK_FIELDS}
    }
  }
`;

const CLONE_ST_IPG_NETWORK = gql`
  mutation CloneStIpgNetwork($sourceId: Int!, $newName: String!) {
    cloneStIpgNetwork(sourceId: $sourceId, newName: $newName) {
      ${ST_IPG_NETWORK_FIELDS}
    }
  }
`;

const CREATE_ST_IPG_CHILD_NODE = gql`
  mutation CreateStIpgChildNode(
    $stNetKey: Int!
    $parentKey: Int!
    $name: String!
    $stpnNum: Int
  ) {
    createStIpgChildNode(
      stNetKey: $stNetKey
      parentKey: $parentKey
      name: $name
      stpnNum: $stpnNum
    ) {
      ${ST_IPG_TREE_FIELDS}
    }
  }
`;

const RENAME_ST_IPG_NODE = gql`
  mutation RenameStIpgNode($stiKey: Int!, $name: String!) {
    renameStIpgNode(stiKey: $stiKey, name: $name)
  }
`;

const GET_ST_IPG_NODE_NAMES = gql`
  query GetStIpgNodeNames($stiKey: Int!) {
    stIpgNodeNames(stiKey: $stiKey) {
      stinKey
      stiKey
      name
    }
  }
`;

const ADD_ST_IPG_NODE_NAME = gql`
  mutation AddStIpgNodeName($stiKey: Int!, $name: String!) {
    addStIpgNodeName(stiKey: $stiKey, name: $name) {
      stinKey
      stiKey
      name
    }
  }
`;

const ATTACH_ST_IPG_EDGE = gql`
  mutation AttachStIpgEdge(
    $stNetKey: Int!
    $parentKey: Int!
    $childKey: Int!
    $stpnNum: Int
  ) {
    attachStIpgEdge(
      stNetKey: $stNetKey
      parentKey: $parentKey
      childKey: $childKey
      stpnNum: $stpnNum
    )
  }
`;

const MOVE_ST_IPG_EDGE = gql`
  mutation MoveStIpgEdge(
    $stNetKey: Int!
    $childKey: Int!
    $fromParentKey: Int!
    $toParentKey: Int!
    $stpnNum: Int
  ) {
    moveStIpgEdge(
      stNetKey: $stNetKey
      childKey: $childKey
      fromParentKey: $fromParentKey
      toParentKey: $toParentKey
      stpnNum: $stpnNum
    )
  }
`;

const DETACH_ST_IPG_EDGE = gql`
  mutation DetachStIpgEdge($stNetKey: Int!, $parentKey: Int!, $childKey: Int!) {
    detachStIpgEdge(stNetKey: $stNetKey, parentKey: $parentKey, childKey: $childKey)
  }
`;

const DELETE_ST_IPG_NODE = gql`
  mutation DeleteStIpgNode($stNetKey: Int!, $stiKey: Int!) {
    deleteStIpgNode(stNetKey: $stNetKey, stiKey: $stiKey)
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

/** Список схем ИПГ. */
export async function getStIpgNetworks(): Promise<StIpgNetworkDto[]> {
  try {
    const result = await apolloClient.query<{ stIpgNetworks: StIpgNetworkDto[] }>({
      query: GET_ST_IPG_NETWORKS,
      fetchPolicy: 'network-only'
    });
    return result.data.stIpgNetworks ?? [];
  } catch (error) {
    throw wrapApolloError(error, 'GetStIpgNetworks');
  }
}

/**
 * Дерево схемы через fnSt.
 *
 * @param stNetKey ключ схемы
 * @param rootKey корень обхода; null → stnRoot на сервере
 */
export async function getStIpgNetworkTree(
  stNetKey: number,
  rootKey?: number | null
): Promise<StIpgTreeNodeDto[]> {
  try {
    const result = await apolloClient.query<{ stIpgNetworkTree: StIpgTreeNodeDto[] }>({
      query: GET_ST_IPG_NETWORK_TREE,
      variables: { stNetKey, rootKey: rootKey ?? null },
      fetchPolicy: 'network-only'
    });
    return result.data.stIpgNetworkTree ?? [];
  } catch (error) {
    throw wrapApolloError(error, 'GetStIpgNetworkTree');
  }
}

/** Создать схему type=1. */
export async function createStIpgNetwork(name: string, rootKey: number): Promise<StIpgNetworkDto> {
  try {
    const result = await apolloClient.mutate<{ createStIpgNetwork: StIpgNetworkDto }>({
      mutation: CREATE_ST_IPG_NETWORK,
      variables: { name, rootKey }
    });
    const created = result.data?.createStIpgNetwork;
    if (!created) {
      throw new Error('createStIpgNetwork: пустой ответ');
    }
    return created;
  } catch (error) {
    throw wrapApolloError(error, 'CreateStIpgNetwork');
  }
}

/** Переименовать схему. */
export async function renameStIpgNetwork(id: number, name: string): Promise<StIpgNetworkDto> {
  try {
    const result = await apolloClient.mutate<{ renameStIpgNetwork: StIpgNetworkDto }>({
      mutation: RENAME_ST_IPG_NETWORK,
      variables: { id, name }
    });
    const updated = result.data?.renameStIpgNetwork;
    if (!updated) {
      throw new Error('renameStIpgNetwork: пустой ответ');
    }
    return updated;
  } catch (error) {
    throw wrapApolloError(error, 'RenameStIpgNetwork');
  }
}

/** Клон схемы (shared-узлы). */
export async function cloneStIpgNetwork(
  sourceId: number,
  newName: string
): Promise<StIpgNetworkDto> {
  try {
    const result = await apolloClient.mutate<{ cloneStIpgNetwork: StIpgNetworkDto }>({
      mutation: CLONE_ST_IPG_NETWORK,
      variables: { sourceId, newName }
    });
    const cloned = result.data?.cloneStIpgNetwork;
    if (!cloned) {
      throw new Error('cloneStIpgNetwork: пустой ответ');
    }
    return cloned;
  } catch (error) {
    throw wrapApolloError(error, 'CloneStIpgNetwork');
  }
}

/** Создать дочерний узел в схеме. */
export async function createStIpgChildNode(input: {
  stNetKey: number;
  parentKey: number;
  name: string;
  stpnNum?: number | null;
}): Promise<StIpgTreeNodeDto> {
  try {
    const result = await apolloClient.mutate<{ createStIpgChildNode: StIpgTreeNodeDto }>({
      mutation: CREATE_ST_IPG_CHILD_NODE,
      variables: {
        stNetKey: input.stNetKey,
        parentKey: input.parentKey,
        name: input.name,
        stpnNum: input.stpnNum ?? null
      }
    });
    const created = result.data?.createStIpgChildNode;
    if (!created) {
      throw new Error('createStIpgChildNode: пустой ответ');
    }
    return created;
  } catch (error) {
    throw wrapApolloError(error, 'CreateStIpgChildNode');
  }
}

/** Переименовать узел (первичное stIpgNm). */
export async function renameStIpgNode(stiKey: number, name: string): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ renameStIpgNode: boolean }>({
      mutation: RENAME_ST_IPG_NODE,
      variables: { stiKey, name }
    });
    return Boolean(result.data?.renameStIpgNode);
  } catch (error) {
    throw wrapApolloError(error, 'RenameStIpgNode');
  }
}

/** Список имён/aliases узла. */
export async function getStIpgNodeNames(stiKey: number): Promise<StIpgNmDto[]> {
  try {
    const result = await apolloClient.query<{ stIpgNodeNames: StIpgNmDto[] }>({
      query: GET_ST_IPG_NODE_NAMES,
      variables: { stiKey },
      fetchPolicy: 'network-only'
    });
    return result.data.stIpgNodeNames ?? [];
  } catch (error) {
    throw wrapApolloError(error, 'GetStIpgNodeNames');
  }
}

/** Добавить alias-имя узла. */
export async function addStIpgNodeName(stiKey: number, name: string): Promise<StIpgNmDto> {
  try {
    const result = await apolloClient.mutate<{ addStIpgNodeName: StIpgNmDto }>({
      mutation: ADD_ST_IPG_NODE_NAME,
      variables: { stiKey, name }
    });
    const created = result.data?.addStIpgNodeName;
    if (!created) {
      throw new Error('addStIpgNodeName: пустой ответ');
    }
    return created;
  } catch (error) {
    throw wrapApolloError(error, 'AddStIpgNodeName');
  }
}

/** Привязать существующий узел под parent в схеме. */
export async function attachStIpgEdge(input: {
  stNetKey: number;
  parentKey: number;
  childKey: number;
  stpnNum?: number | null;
}): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ attachStIpgEdge: boolean }>({
      mutation: ATTACH_ST_IPG_EDGE,
      variables: {
        stNetKey: input.stNetKey,
        parentKey: input.parentKey,
        childKey: input.childKey,
        stpnNum: input.stpnNum ?? null
      }
    });
    return Boolean(result.data?.attachStIpgEdge);
  } catch (error) {
    throw wrapApolloError(error, 'AttachStIpgEdge');
  }
}

/** Перенести ребёнка в схеме (смена родителя). */
export async function moveStIpgEdge(input: {
  stNetKey: number;
  childKey: number;
  fromParentKey: number;
  toParentKey: number;
  stpnNum?: number | null;
}): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ moveStIpgEdge: boolean }>({
      mutation: MOVE_ST_IPG_EDGE,
      variables: {
        stNetKey: input.stNetKey,
        childKey: input.childKey,
        fromParentKey: input.fromParentKey,
        toParentKey: input.toParentKey,
        stpnNum: input.stpnNum ?? null
      }
    });
    return Boolean(result.data?.moveStIpgEdge);
  } catch (error) {
    throw wrapApolloError(error, 'MoveStIpgEdge');
  }
}

/** Отсоединить ребро от схемы. */
export async function detachStIpgEdge(
  stNetKey: number,
  parentKey: number,
  childKey: number
): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ detachStIpgEdge: boolean }>({
      mutation: DETACH_ST_IPG_EDGE,
      variables: { stNetKey, parentKey, childKey }
    });
    return Boolean(result.data?.detachStIpgEdge);
  } catch (error) {
    throw wrapApolloError(error, 'DetachStIpgEdge');
  }
}

/** Удалить узел (строгая политика на сервере). */
export async function deleteStIpgNode(stNetKey: number, stiKey: number): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ deleteStIpgNode: boolean }>({
      mutation: DELETE_ST_IPG_NODE,
      variables: { stNetKey, stiKey }
    });
    return Boolean(result.data?.deleteStIpgNode);
  } catch (error) {
    throw wrapApolloError(error, 'DeleteStIpgNode');
  }
}
