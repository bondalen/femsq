/**
 * GraphQL API Leaves (C2 §2.4.2 / §2.5.2): полная ipg, пункты, ipgStPn, ipgSh.
 */

import { gql } from '@apollo/client/core';

import { apolloClient } from '@/plugins/apollo';
import { RequestError } from './http';

/** Полная карточка ИП. */
export interface IpgFullDto {
  ipgKey: number;
  ipgOg: number;
  ogName: string | null;
  ipgNm: string;
  ipgYy: number;
  year: number | null;
  ipgNum: number;
  ipgStr: string;
  ipgEnd: string | null;
  ipgRepl: number | null;
  ipgStRlSh: number;
  stNetName: string | null;
  ipgYyYear: number | null;
}

/** Пункт ИП (+ код / стройка / агент из САК). */
export interface IpgPnDto {
  ipgpKey: number;
  ipgpIpg: number;
  ipgpNum: number | null;
  ipgpCstAgPn: number;
  cstAgPnCode: string | null;
  cstAgPnCstName: string | null;
  cstAgPnOgName: string | null;
  ipgpSmTtl: number | null;
  ipgpSmWrk: number | null;
  ipgpSmEqu: number | null;
  ipgpSmOth: number | null;
  ipgpSmAgFee: number | null;
  ipgpCostAdjust: number | null;
  ipgpSmReserv: number | null;
  ipgpTskCms: string | null;
  ipgpSh: number;
  ipgpShName: string | null;
}

/** Привязка пункта к stiKey. */
export interface IpgStPnDto {
  ipgspKey: number;
  ipgspPn: number;
  ipgspSt: number;
  stName: string | null;
}

/** Схема реализации. */
export interface IpgShDto {
  ipgsKey: number;
  ipgsNm: string;
}

export interface CreateIpgInput {
  ipgOg: number;
  ipgNm: string;
  ipgYy: number;
  ipgNum: number;
  ipgStr: string;
  ipgEnd?: string | null;
  ipgRepl?: number | null;
  ipgStRlSh: number;
  ipgYyYear?: number | null;
}

export interface UpdateIpgInput {
  ipgNm: string;
  ipgYy: number;
  ipgNum: number;
  ipgStr: string;
  ipgEnd?: string | null;
  ipgRepl?: number | null;
  ipgStRlSh: number;
  ipgYyYear?: number | null;
}

export interface CreateIpgPnInput {
  ipgpIpg: number;
  ipgpNum?: number | null;
  ipgpCstAgPn: number;
  ipgpSh: number;
  ipgpSmTtl?: number | null;
  ipgpSmWrk?: number | null;
  ipgpSmEqu?: number | null;
  ipgpSmOth?: number | null;
  ipgpSmAgFee?: number | null;
  ipgpCostAdjust?: number | null;
  ipgpSmReserv?: number | null;
  ipgpTskCms?: string | null;
}

export type UpdateIpgPnInput = Omit<CreateIpgPnInput, 'ipgpIpg'>;

const IPG_FULL_FIELDS = `
  ipgKey
  ipgOg
  ogName
  ipgNm
  ipgYy
  year
  ipgNum
  ipgStr
  ipgEnd
  ipgRepl
  ipgStRlSh
  stNetName
  ipgYyYear
`;

const IPG_PN_FIELDS = `
  ipgpKey
  ipgpIpg
  ipgpNum
  ipgpCstAgPn
  cstAgPnCode
  cstAgPnCstName
  cstAgPnOgName
  ipgpSmTtl
  ipgpSmWrk
  ipgpSmEqu
  ipgpSmOth
  ipgpSmAgFee
  ipgpCostAdjust
  ipgpSmReserv
  ipgpTskCms
  ipgpSh
  ipgpShName
`;

const IPG_ST_PN_FIELDS = `
  ipgspKey
  ipgspPn
  ipgspSt
  stName
`;

const GET_INVESTMENT_PROGRAMS_FULL = gql`
  query GetInvestmentProgramsFull($year: Int, $ogKey: Int, $name: String) {
    investmentProgramsFull(year: $year, ogKey: $ogKey, name: $name) {
      ${IPG_FULL_FIELDS}
    }
  }
`;

const GET_INVESTMENT_PROGRAM_FULL = gql`
  query GetInvestmentProgramFull($id: Int!) {
    investmentProgramFull(id: $id) {
      ${IPG_FULL_FIELDS}
    }
  }
`;

const GET_INVESTMENT_PROGRAM_POINTS = gql`
  query GetInvestmentProgramPoints($ipgKey: Int!) {
    investmentProgramPoints(ipgKey: $ipgKey) {
      ${IPG_PN_FIELDS}
    }
  }
`;

const GET_IPG_PN_STRUCTURE = gql`
  query GetIpgPnStructure($ipgpKey: Int!) {
    ipgPnStructure(ipgpKey: $ipgpKey) {
      ${IPG_ST_PN_FIELDS}
    }
  }
`;

const GET_IPG_SCHEMES = gql`
  query GetIpgSchemes {
    ipgSchemes {
      ipgsKey
      ipgsNm
    }
  }
`;

const CREATE_INVESTMENT_PROGRAM = gql`
  mutation CreateInvestmentProgram($input: CreateIpgInput!) {
    createInvestmentProgram(input: $input) {
      ${IPG_FULL_FIELDS}
    }
  }
`;

const UPDATE_INVESTMENT_PROGRAM = gql`
  mutation UpdateInvestmentProgram($id: Int!, $input: UpdateIpgInput!) {
    updateInvestmentProgram(id: $id, input: $input) {
      ${IPG_FULL_FIELDS}
    }
  }
`;

const CREATE_IPG_PN = gql`
  mutation CreateIpgPn($input: CreateIpgPnInput!) {
    createIpgPn(input: $input) {
      ${IPG_PN_FIELDS}
    }
  }
`;

const UPDATE_IPG_PN = gql`
  mutation UpdateIpgPn($id: Int!, $input: UpdateIpgPnInput!) {
    updateIpgPn(id: $id, input: $input) {
      ${IPG_PN_FIELDS}
    }
  }
`;

const DELETE_IPG_PN = gql`
  mutation DeleteIpgPn($id: Int!) {
    deleteIpgPn(id: $id)
  }
`;

const ADD_IPG_PN_STRUCTURE = gql`
  mutation AddIpgPnStructure($ipgpKey: Int!, $stiKey: Int!) {
    addIpgPnStructure(ipgpKey: $ipgpKey, stiKey: $stiKey) {
      ${IPG_ST_PN_FIELDS}
    }
  }
`;

const REMOVE_IPG_PN_STRUCTURE = gql`
  mutation RemoveIpgPnStructure($ipgspKey: Int!) {
    removeIpgPnStructure(ipgspKey: $ipgspKey)
  }
`;

const SET_IPG_PN_STRUCTURE = gql`
  mutation SetIpgPnStructure($ipgpKey: Int!, $stiKeys: [Int!]!) {
    setIpgPnStructure(ipgpKey: $ipgpKey, stiKeys: $stiKeys) {
      ${IPG_ST_PN_FIELDS}
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

/** Список полных ИП. */
export async function getInvestmentProgramsFull(filter?: {
  year?: number | null;
  ogKey?: number | null;
  name?: string | null;
}): Promise<IpgFullDto[]> {
  try {
    const result = await apolloClient.query<{ investmentProgramsFull: IpgFullDto[] }>({
      query: GET_INVESTMENT_PROGRAMS_FULL,
      variables: {
        year: filter?.year ?? null,
        ogKey: filter?.ogKey ?? null,
        name: filter?.name ?? null
      },
      fetchPolicy: 'network-only'
    });
    return result.data.investmentProgramsFull ?? [];
  } catch (error) {
    throw wrapApolloError(error, 'GetInvestmentProgramsFull');
  }
}

/** Одна ИП. */
export async function getInvestmentProgramFull(id: number): Promise<IpgFullDto | null> {
  try {
    const result = await apolloClient.query<{ investmentProgramFull: IpgFullDto | null }>({
      query: GET_INVESTMENT_PROGRAM_FULL,
      variables: { id },
      fetchPolicy: 'network-only'
    });
    return result.data.investmentProgramFull ?? null;
  } catch (error) {
    throw wrapApolloError(error, 'GetInvestmentProgramFull');
  }
}

/** Пункты ИП. */
export async function getInvestmentProgramPoints(ipgKey: number): Promise<IpgPnDto[]> {
  try {
    const result = await apolloClient.query<{ investmentProgramPoints: IpgPnDto[] }>({
      query: GET_INVESTMENT_PROGRAM_POINTS,
      variables: { ipgKey },
      fetchPolicy: 'network-only'
    });
    return result.data.investmentProgramPoints ?? [];
  } catch (error) {
    throw wrapApolloError(error, 'GetInvestmentProgramPoints');
  }
}

/** Привязки пункта к структуре. */
export async function getIpgPnStructure(ipgpKey: number): Promise<IpgStPnDto[]> {
  try {
    const result = await apolloClient.query<{ ipgPnStructure: IpgStPnDto[] }>({
      query: GET_IPG_PN_STRUCTURE,
      variables: { ipgpKey },
      fetchPolicy: 'network-only'
    });
    return result.data.ipgPnStructure ?? [];
  } catch (error) {
    throw wrapApolloError(error, 'GetIpgPnStructure');
  }
}

/** Справочник ipgSh. */
export async function getIpgSchemes(): Promise<IpgShDto[]> {
  try {
    const result = await apolloClient.query<{ ipgSchemes: IpgShDto[] }>({
      query: GET_IPG_SCHEMES,
      fetchPolicy: 'network-only'
    });
    return result.data.ipgSchemes ?? [];
  } catch (error) {
    throw wrapApolloError(error, 'GetIpgSchemes');
  }
}

/** Создать ИП. */
export async function createInvestmentProgram(input: CreateIpgInput): Promise<IpgFullDto> {
  try {
    const result = await apolloClient.mutate<{ createInvestmentProgram: IpgFullDto }>({
      mutation: CREATE_INVESTMENT_PROGRAM,
      variables: { input }
    });
    const created = result.data?.createInvestmentProgram;
    if (!created) {
      throw new Error('createInvestmentProgram: пустой ответ');
    }
    return created;
  } catch (error) {
    throw wrapApolloError(error, 'CreateInvestmentProgram');
  }
}

/** Обновить ИП. */
export async function updateInvestmentProgram(id: number, input: UpdateIpgInput): Promise<IpgFullDto> {
  try {
    const result = await apolloClient.mutate<{ updateInvestmentProgram: IpgFullDto }>({
      mutation: UPDATE_INVESTMENT_PROGRAM,
      variables: { id, input }
    });
    const updated = result.data?.updateInvestmentProgram;
    if (!updated) {
      throw new Error('updateInvestmentProgram: пустой ответ');
    }
    return updated;
  } catch (error) {
    throw wrapApolloError(error, 'UpdateInvestmentProgram');
  }
}

/** Создать пункт. */
export async function createIpgPn(input: CreateIpgPnInput): Promise<IpgPnDto> {
  try {
    const result = await apolloClient.mutate<{ createIpgPn: IpgPnDto }>({
      mutation: CREATE_IPG_PN,
      variables: { input }
    });
    const created = result.data?.createIpgPn;
    if (!created) {
      throw new Error('createIpgPn: пустой ответ');
    }
    return created;
  } catch (error) {
    throw wrapApolloError(error, 'CreateIpgPn');
  }
}

/** Обновить пункт. */
export async function updateIpgPn(id: number, input: UpdateIpgPnInput): Promise<IpgPnDto> {
  try {
    const result = await apolloClient.mutate<{ updateIpgPn: IpgPnDto }>({
      mutation: UPDATE_IPG_PN,
      variables: { id, input }
    });
    const updated = result.data?.updateIpgPn;
    if (!updated) {
      throw new Error('updateIpgPn: пустой ответ');
    }
    return updated;
  } catch (error) {
    throw wrapApolloError(error, 'UpdateIpgPn');
  }
}

/** Удалить пункт. */
export async function deleteIpgPn(id: number): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ deleteIpgPn: boolean }>({
      mutation: DELETE_IPG_PN,
      variables: { id }
    });
    return Boolean(result.data?.deleteIpgPn);
  } catch (error) {
    throw wrapApolloError(error, 'DeleteIpgPn');
  }
}

/** Добавить привязку stiKey. */
export async function addIpgPnStructure(ipgpKey: number, stiKey: number): Promise<IpgStPnDto> {
  try {
    const result = await apolloClient.mutate<{ addIpgPnStructure: IpgStPnDto }>({
      mutation: ADD_IPG_PN_STRUCTURE,
      variables: { ipgpKey, stiKey }
    });
    const created = result.data?.addIpgPnStructure;
    if (!created) {
      throw new Error('addIpgPnStructure: пустой ответ');
    }
    return created;
  } catch (error) {
    throw wrapApolloError(error, 'AddIpgPnStructure');
  }
}

/** Удалить привязку. */
export async function removeIpgPnStructure(ipgspKey: number): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ removeIpgPnStructure: boolean }>({
      mutation: REMOVE_IPG_PN_STRUCTURE,
      variables: { ipgspKey }
    });
    return Boolean(result.data?.removeIpgPnStructure);
  } catch (error) {
    throw wrapApolloError(error, 'RemoveIpgPnStructure');
  }
}

/** Заменить набор привязок. */
export async function setIpgPnStructure(
  ipgpKey: number,
  stiKeys: number[]
): Promise<IpgStPnDto[]> {
  try {
    const result = await apolloClient.mutate<{ setIpgPnStructure: IpgStPnDto[] }>({
      mutation: SET_IPG_PN_STRUCTURE,
      variables: { ipgpKey, stiKeys }
    });
    return result.data?.setIpgPnStructure ?? [];
  } catch (error) {
    throw wrapApolloError(error, 'SetIpgPnStructure');
  }
}
