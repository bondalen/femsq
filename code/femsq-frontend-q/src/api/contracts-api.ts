/**
 * Apollo API экрана «Договоры» (cnNum/cn + CRUD сторон).
 */

import { gql } from '@apollo/client/core';

import { apolloClient } from '@/plugins/apollo';
import { RequestError } from './http';
import type {
  CnContractCreateRequest,
  CnContractCreatedDto,
  CnDto,
  CnInvCreateRequest,
  CnInvDto,
  CnInvUpdateRequest,
  CnNumDto,
  CnNumTypeLookupDto,
  CnSideCreateRequest,
  CnSideDto,
  CnSideUpdateRequest,
  CnSOrgCreateRequest,
  CnSOrgDto,
  CnSOrgIdLookupDto,
  CnSOrgSmplCreateRequest,
  CnSOrgSmplDto,
  CnSOrgSmplUpdateRequest,
  CnSOrgUpdateRequest,
  CnUpdateRequest
} from '@/types/contracts';

const CN_NUMS_QUERY = gql`
  query CnNums {
    cnNums {
      cnnKey
      cnnNum
      cnnCn
      cnnType
      cnnTypeName
      cnnNote
    }
  }
`;

const CN_QUERY = gql`
  query Cn($cnKey: Int!) {
    cn(cnKey: $cnKey) {
      cnKey
      cnNumber
      cnDate
      cnNote
      cnMark
    }
  }
`;

const CN_NUMS_BY_CN_QUERY = gql`
  query CnNumsByCn($cnKey: Int!) {
    cnNumsByCn(cnKey: $cnKey) {
      cnnKey
      cnnNum
      cnnCn
      cnnType
      cnnTypeName
      cnnNote
    }
  }
`;

const CN_SIDES_QUERY = gql`
  query CnSides($cnKey: Int!) {
    cnSides(cnKey: $cnKey) {
      cnSKey
      cnKey
      cnSType
      cnSTypeName
      smpls {
        csosKey
        csosCnS
        csosOrgId
        orgLabel
        csosTimeOfEntry
        orgs {
          cnSOrgKey
          csoCnSOrgSmpl
          dateBeg
          dateEnd
          csoAsbuId
          csoCnDate
          csoTimeOfEntry
        }
      }
    }
  }
`;

const CN_S_ORG_ID_LOOKUPS_QUERY = gql`
  query CnSOrgIdLookups {
    cnSOrgIdLookups {
      orgIdKey
      buirg
      label
    }
  }
`;

const CN_NUM_TYPES_QUERY = gql`
  query CnNumTypes {
    cnNumTypes {
      cnntKey
      cnntName
    }
  }
`;

const CN_NUM_DUPLICATE_COUNT_QUERY = gql`
  query CnNumDuplicateCount($cnnNum: String!) {
    cnNumDuplicateCount(cnnNum: $cnnNum)
  }
`;

const CREATE_CN_CONTRACT = gql`
  mutation CreateCnContract($input: CnContractCreateRequest!) {
    createCnContract(input: $input) {
      cnKey
      cnnKey
      cnSKey
      csosKey
      cnSOrgKey
    }
  }
`;

const UPDATE_CN = gql`
  mutation UpdateCn($id: Int!, $input: CnUpdateRequest!) {
    updateCn(id: $id, input: $input) {
      cnKey
      cnNumber
      cnDate
      cnNote
      cnMark
    }
  }
`;

const CREATE_CN_INV = gql`
  mutation CreateCnInv($input: CnInvCreateRequest!) {
    createCnInv(input: $input) {
      ciKey
      ciInv
      ciCn
      ciTimeOfEntry
    }
  }
`;

const UPDATE_CN_INV = gql`
  mutation UpdateCnInv($id: Int!, $input: CnInvUpdateRequest!) {
    updateCnInv(id: $id, input: $input) {
      ciKey
      ciInv
      ciCn
      ciTimeOfEntry
    }
  }
`;

const DELETE_CN_INV = gql`
  mutation DeleteCnInv($id: Int!) {
    deleteCnInv(id: $id)
  }
`;

const CREATE_CN_SIDE = gql`
  mutation CreateCnSide($input: CnSideCreateRequest!) {
    createCnSide(input: $input) {
      cnSKey
      cnKey
      cnSType
      cnSTypeName
      smpls {
        csosKey
      }
    }
  }
`;

const UPDATE_CN_SIDE = gql`
  mutation UpdateCnSide($id: Int!, $input: CnSideUpdateRequest!) {
    updateCnSide(id: $id, input: $input) {
      cnSKey
      cnKey
      cnSType
      cnSTypeName
      smpls {
        csosKey
      }
    }
  }
`;

const DELETE_CN_SIDE = gql`
  mutation DeleteCnSide($id: Int!) {
    deleteCnSide(id: $id)
  }
`;

const CREATE_CN_S_ORG_SMPL = gql`
  mutation CreateCnSOrgSmpl($input: CnSOrgSmplCreateRequest!) {
    createCnSOrgSmpl(input: $input) {
      csosKey
      csosCnS
      csosOrgId
      orgLabel
      csosTimeOfEntry
      orgs {
        cnSOrgKey
      }
    }
  }
`;

const UPDATE_CN_S_ORG_SMPL = gql`
  mutation UpdateCnSOrgSmpl($id: Int!, $input: CnSOrgSmplUpdateRequest!) {
    updateCnSOrgSmpl(id: $id, input: $input) {
      csosKey
      csosCnS
      csosOrgId
      orgLabel
      csosTimeOfEntry
      orgs {
        cnSOrgKey
      }
    }
  }
`;

const DELETE_CN_S_ORG_SMPL = gql`
  mutation DeleteCnSOrgSmpl($id: Int!) {
    deleteCnSOrgSmpl(id: $id)
  }
`;

const CREATE_CN_S_ORG = gql`
  mutation CreateCnSOrg($input: CnSOrgCreateRequest!) {
    createCnSOrg(input: $input) {
      cnSOrgKey
      csoCnSOrgSmpl
      dateBeg
      dateEnd
      csoAsbuId
      csoCnDate
      csoTimeOfEntry
    }
  }
`;

const UPDATE_CN_S_ORG = gql`
  mutation UpdateCnSOrg($id: Int!, $input: CnSOrgUpdateRequest!) {
    updateCnSOrg(id: $id, input: $input) {
      cnSOrgKey
      csoCnSOrgSmpl
      dateBeg
      dateEnd
      csoAsbuId
      csoCnDate
      csoTimeOfEntry
    }
  }
`;

const DELETE_CN_S_ORG = gql`
  mutation DeleteCnSOrg($id: Int!) {
    deleteCnSOrg(id: $id)
  }
`;

function toRequestError(error: unknown, fallback: string): RequestError {
  if (error instanceof RequestError) {
    return error;
  }
  const message = error instanceof Error ? error.message : fallback;
  return new RequestError(message, {
    status: 0,
    statusText: 'GraphQL',
    url: '/graphql'
  });
}

function emptyResponseError(operation: string): RequestError {
  return new RequestError(`Пустой ответ ${operation}`, {
    status: 0,
    statusText: 'GraphQL',
    url: '/graphql',
    body: { operation }
  });
}

/**
 * Загружает полный список номеров договоров.
 */
export async function fetchCnNums(): Promise<CnNumDto[]> {
  try {
    const result = await apolloClient.query<{ cnNums: CnNumDto[] }>({
      query: CN_NUMS_QUERY,
      fetchPolicy: 'network-only'
    });
    return result.data.cnNums ?? [];
  } catch (error) {
    throw toRequestError(error, 'Не удалось загрузить номера договоров');
  }
}

/**
 * Карточка договора по ключу.
 */
export async function fetchCn(cnKey: number): Promise<CnDto | null> {
  try {
    const result = await apolloClient.query<{ cn: CnDto | null }>({
      query: CN_QUERY,
      variables: { cnKey },
      fetchPolicy: 'network-only'
    });
    return result.data.cn ?? null;
  } catch (error) {
    throw toRequestError(error, 'Не удалось загрузить договор');
  }
}

/**
 * Номера, привязанные к договору.
 */
export async function fetchCnNumsByCn(cnKey: number): Promise<CnNumDto[]> {
  try {
    const result = await apolloClient.query<{ cnNumsByCn: CnNumDto[] }>({
      query: CN_NUMS_BY_CN_QUERY,
      variables: { cnKey },
      fetchPolicy: 'network-only'
    });
    return result.data.cnNumsByCn ?? [];
  } catch (error) {
    throw toRequestError(error, 'Не удалось загрузить номера договора');
  }
}

/**
 * Дерево сторон договора.
 */
export async function fetchCnSides(cnKey: number): Promise<CnSideDto[]> {
  try {
    const result = await apolloClient.query<{ cnSides: CnSideDto[] }>({
      query: CN_SIDES_QUERY,
      variables: { cnKey },
      fetchPolicy: 'network-only'
    });
    return result.data.cnSides ?? [];
  } catch (error) {
    throw toRequestError(error, 'Не удалось загрузить стороны договора');
  }
}

/**
 * Lookup БУиРГ для выбора организации стороны.
 */
export async function fetchCnSOrgIdLookups(): Promise<CnSOrgIdLookupDto[]> {
  try {
    const result = await apolloClient.query<{ cnSOrgIdLookups: CnSOrgIdLookupDto[] }>({
      query: CN_S_ORG_ID_LOOKUPS_QUERY,
      fetchPolicy: 'network-only'
    });
    return result.data.cnSOrgIdLookups ?? [];
  } catch (error) {
    throw toRequestError(error, 'Не удалось загрузить организации (org_id)');
  }
}

/**
 * Справочник типов номера договора.
 */
export async function fetchCnNumTypes(): Promise<CnNumTypeLookupDto[]> {
  try {
    const result = await apolloClient.query<{ cnNumTypes: CnNumTypeLookupDto[] }>({
      query: CN_NUM_TYPES_QUERY,
      fetchPolicy: 'network-only'
    });
    return result.data.cnNumTypes ?? [];
  } catch (error) {
    throw toRequestError(error, 'Не удалось загрузить типы номера');
  }
}

/**
 * Число уже существующих номеров с тем же текстом.
 */
export async function fetchCnNumDuplicateCount(cnnNum: string): Promise<number> {
  try {
    const result = await apolloClient.query<{ cnNumDuplicateCount: number }>({
      query: CN_NUM_DUPLICATE_COUNT_QUERY,
      variables: { cnnNum },
      fetchPolicy: 'network-only'
    });
    return result.data.cnNumDuplicateCount ?? 0;
  } catch (error) {
    throw toRequestError(error, 'Не удалось проверить коллизию номера');
  }
}

/**
 * Создаёт новый договор с исполнителем (вариант 1).
 */
export async function createCnContract(input: CnContractCreateRequest): Promise<CnContractCreatedDto> {
  try {
    const result = await apolloClient.mutate<{ createCnContract: CnContractCreatedDto }>({
      mutation: CREATE_CN_CONTRACT,
      variables: { input }
    });
    if (!result.data?.createCnContract) {
      throw emptyResponseError('createCnContract');
    }
    return result.data.createCnContract;
  } catch (error) {
    throw toRequestError(error, 'Не удалось создать договор');
  }
}

/**
 * Обновляет карточку cn (cn_date / note / mark).
 */
export async function updateCn(id: number, input: CnUpdateRequest): Promise<CnDto> {
  try {
    const result = await apolloClient.mutate<{ updateCn: CnDto }>({
      mutation: UPDATE_CN,
      variables: { id, input }
    });
    if (!result.data?.updateCn) {
      throw emptyResponseError('updateCn');
    }
    return result.data.updateCn;
  } catch (error) {
    throw toRequestError(error, 'Не удалось обновить договор');
  }
}

/**
 * Создаёт связь существующих договора и СФ.
 */
export async function createCnInv(input: CnInvCreateRequest): Promise<CnInvDto> {
  try {
    const result = await apolloClient.mutate<{ createCnInv: CnInvDto }>({
      mutation: CREATE_CN_INV,
      variables: { input }
    });
    if (!result.data?.createCnInv) {
      throw emptyResponseError('createCnInv');
    }
    return result.data.createCnInv;
  } catch (error) {
    throw toRequestError(error, 'Не удалось создать связь cnInv');
  }
}

/**
 * Обновляет связь договора и СФ по ciKey.
 */
export async function updateCnInv(id: number, input: CnInvUpdateRequest): Promise<CnInvDto> {
  try {
    const result = await apolloClient.mutate<{ updateCnInv: CnInvDto }>({
      mutation: UPDATE_CN_INV,
      variables: { id, input }
    });
    if (!result.data?.updateCnInv) {
      throw emptyResponseError('updateCnInv');
    }
    return result.data.updateCnInv;
  } catch (error) {
    throw toRequestError(error, 'Не удалось обновить связь cnInv');
  }
}

/**
 * Удаляет связь cnInv по ciKey.
 */
export async function deleteCnInv(id: number): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ deleteCnInv: boolean }>({
      mutation: DELETE_CN_INV,
      variables: { id }
    });
    return result.data?.deleteCnInv ?? false;
  } catch (error) {
    throw toRequestError(error, 'Не удалось удалить связь cnInv');
  }
}

/**
 * Создаёт сторону договора.
 */
export async function createCnSide(input: CnSideCreateRequest): Promise<CnSideDto> {
  try {
    const result = await apolloClient.mutate<{ createCnSide: CnSideDto }>({
      mutation: CREATE_CN_SIDE,
      variables: { input }
    });
    if (!result.data?.createCnSide) {
      throw emptyResponseError('createCnSide');
    }
    return result.data.createCnSide;
  } catch (error) {
    throw toRequestError(error, 'Не удалось создать сторону');
  }
}

/**
 * Обновляет сторону договора.
 */
export async function updateCnSide(id: number, input: CnSideUpdateRequest): Promise<CnSideDto> {
  try {
    const result = await apolloClient.mutate<{ updateCnSide: CnSideDto }>({
      mutation: UPDATE_CN_SIDE,
      variables: { id, input }
    });
    if (!result.data?.updateCnSide) {
      throw emptyResponseError('updateCnSide');
    }
    return result.data.updateCnSide;
  } catch (error) {
    throw toRequestError(error, 'Не удалось обновить сторону');
  }
}

/**
 * Удаляет сторону (каскадно smpl/org).
 */
export async function deleteCnSide(id: number): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ deleteCnSide: boolean }>({
      mutation: DELETE_CN_SIDE,
      variables: { id }
    });
    return result.data?.deleteCnSide ?? false;
  } catch (error) {
    throw toRequestError(error, 'Не удалось удалить сторону');
  }
}

/**
 * Создаёт smpl.
 */
export async function createCnSOrgSmpl(input: CnSOrgSmplCreateRequest): Promise<CnSOrgSmplDto> {
  try {
    const result = await apolloClient.mutate<{ createCnSOrgSmpl: CnSOrgSmplDto }>({
      mutation: CREATE_CN_S_ORG_SMPL,
      variables: { input }
    });
    if (!result.data?.createCnSOrgSmpl) {
      throw emptyResponseError('createCnSOrgSmpl');
    }
    return result.data.createCnSOrgSmpl;
  } catch (error) {
    throw toRequestError(error, 'Не удалось создать организацию стороны (smpl)');
  }
}

/**
 * Обновляет smpl.
 */
export async function updateCnSOrgSmpl(id: number, input: CnSOrgSmplUpdateRequest): Promise<CnSOrgSmplDto> {
  try {
    const result = await apolloClient.mutate<{ updateCnSOrgSmpl: CnSOrgSmplDto }>({
      mutation: UPDATE_CN_S_ORG_SMPL,
      variables: { id, input }
    });
    if (!result.data?.updateCnSOrgSmpl) {
      throw emptyResponseError('updateCnSOrgSmpl');
    }
    return result.data.updateCnSOrgSmpl;
  } catch (error) {
    throw toRequestError(error, 'Не удалось обновить организацию стороны (smpl)');
  }
}

/**
 * Удаляет smpl (каскадно org).
 */
export async function deleteCnSOrgSmpl(id: number): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ deleteCnSOrgSmpl: boolean }>({
      mutation: DELETE_CN_S_ORG_SMPL,
      variables: { id }
    });
    return result.data?.deleteCnSOrgSmpl ?? false;
  } catch (error) {
    throw toRequestError(error, 'Не удалось удалить организацию стороны (smpl)');
  }
}

/**
 * Создаёт cn_s_org.
 */
export async function createCnSOrg(input: CnSOrgCreateRequest): Promise<CnSOrgDto> {
  try {
    const result = await apolloClient.mutate<{ createCnSOrg: CnSOrgDto }>({
      mutation: CREATE_CN_S_ORG,
      variables: { input }
    });
    if (!result.data?.createCnSOrg) {
      throw emptyResponseError('createCnSOrg');
    }
    return result.data.createCnSOrg;
  } catch (error) {
    throw toRequestError(error, 'Не удалось создать запись org с датами');
  }
}

/**
 * Обновляет cn_s_org.
 */
export async function updateCnSOrg(id: number, input: CnSOrgUpdateRequest): Promise<CnSOrgDto> {
  try {
    const result = await apolloClient.mutate<{ updateCnSOrg: CnSOrgDto }>({
      mutation: UPDATE_CN_S_ORG,
      variables: { id, input }
    });
    if (!result.data?.updateCnSOrg) {
      throw emptyResponseError('updateCnSOrg');
    }
    return result.data.updateCnSOrg;
  } catch (error) {
    throw toRequestError(error, 'Не удалось обновить запись org с датами');
  }
}

/**
 * Удаляет cn_s_org.
 */
export async function deleteCnSOrg(id: number): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ deleteCnSOrg: boolean }>({
      mutation: DELETE_CN_S_ORG,
      variables: { id }
    });
    return result.data?.deleteCnSOrg ?? false;
  } catch (error) {
    throw toRequestError(error, 'Не удалось удалить запись org с датами');
  }
}
