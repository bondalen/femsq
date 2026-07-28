/**
 * Apollo API для строек и вкладки «агенты».
 */

import { gql } from '@apollo/client/core';

import { apolloClient } from '@/plugins/apollo';
import { RequestError } from './http';
import type {
  ConstructionSiteDto,
  CstAgCreateRequest,
  CstAgPnBranchCreateRequest,
  CstAgPnBranchDto,
  CstAgPnBranchUpdateRequest,
  CstAgPnCreateRequest,
  CstAgPointDto,
  CstAgPnCodeDto,
  CstAgPnSiteLookupDto,
  CstAgPnUpdateRequest,
  CstAgUpdateRequest,
  CstAgentDto,
  CstCreateRequest,
  CstRaListEntryDto,
  CstUpdateRequest,
  OgAgCsLookupDto,
  RaPeriodLookupDto,
  RaReportCreateRequest,
  RaReportDto,
  RaReportUpdateRequest,
  RaSummCreateRequest,
  RaSummDto,
  RaSummUpdateRequest,
  RalpRaAuCreateRequest,
  RalpRaAuDto,
  RalpRaAuStatusLookupDto,
  RalpRaAuUpdateRequest,
  RalpRaCreateRequest,
  RalpRaCstListEntryDto,
  RalpRaDto,
  RalpRaUpdateRequest
} from '@/types/construction-sites';

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

const SITE_FIELDS = `
  cstKey
  cstName
  cstBusSgm
  cstOidOld
  cstMark
`;

const AGENT_FIELDS = `
  cstaKey
  cstaAg
  cstaCst
  cstaOidOld
  cstaInvestor
  agentLabel
`;

const POINT_FIELDS = `
  cstapKey
  cstapCsta
  cstapIpgPnN
  cstapOidOld
`;

const BRANCH_FIELDS = `
  cstapbKey
  cstapbCstAgPn
  cstapbBranch
  cstapbStart
  cstapbEnd
  branchName
`;

const GET_CONSTRUCTION_SITES = gql`
  query GetConstructionSites {
    constructionSites {
      ${SITE_FIELDS}
    }
  }
`;

const CREATE_CONSTRUCTION_SITE = gql`
  mutation CreateConstructionSite($input: CstCreateRequest!) {
    createConstructionSite(input: $input) {
      ${SITE_FIELDS}
    }
  }
`;

const UPDATE_CONSTRUCTION_SITE = gql`
  mutation UpdateConstructionSite($id: Int!, $input: CstUpdateRequest!) {
    updateConstructionSite(id: $id, input: $input) {
      ${SITE_FIELDS}
    }
  }
`;

const DELETE_CONSTRUCTION_SITE = gql`
  mutation DeleteConstructionSite($id: Int!) {
    deleteConstructionSite(id: $id)
  }
`;

const GET_CST_AGENTS = gql`
  query GetCstAgents($cstKey: Int!) {
    cstAgents(cstKey: $cstKey) {
      ${AGENT_FIELDS}
    }
  }
`;

const CREATE_CST_AGENT = gql`
  mutation CreateCstAgent($input: CstAgCreateRequest!) {
    createCstAgent(input: $input) {
      ${AGENT_FIELDS}
    }
  }
`;

const UPDATE_CST_AGENT = gql`
  mutation UpdateCstAgent($id: Int!, $input: CstAgUpdateRequest!) {
    updateCstAgent(id: $id, input: $input) {
      ${AGENT_FIELDS}
    }
  }
`;

const DELETE_CST_AGENT = gql`
  mutation DeleteCstAgent($id: Int!) {
    deleteCstAgent(id: $id)
  }
`;

const GET_CST_AG_POINTS = gql`
  query GetCstAgPoints($cstaKey: Int!) {
    cstAgPoints(cstaKey: $cstaKey) {
      ${POINT_FIELDS}
    }
  }
`;

const CREATE_CST_AG_POINT = gql`
  mutation CreateCstAgPoint($input: CstAgPnCreateRequest!) {
    createCstAgPoint(input: $input) {
      ${POINT_FIELDS}
    }
  }
`;

const UPDATE_CST_AG_POINT = gql`
  mutation UpdateCstAgPoint($id: Int!, $input: CstAgPnUpdateRequest!) {
    updateCstAgPoint(id: $id, input: $input) {
      ${POINT_FIELDS}
    }
  }
`;

const DELETE_CST_AG_POINT = gql`
  mutation DeleteCstAgPoint($id: Int!) {
    deleteCstAgPoint(id: $id)
  }
`;

const GET_CST_AG_PN_BRANCHES = gql`
  query GetCstAgPnBranches($cstapKey: Int!) {
    cstAgPnBranches(cstapKey: $cstapKey) {
      ${BRANCH_FIELDS}
    }
  }
`;

const CREATE_CST_AG_PN_BRANCH = gql`
  mutation CreateCstAgPnBranch($input: CstAgPnBranchCreateRequest!) {
    createCstAgPnBranch(input: $input) {
      ${BRANCH_FIELDS}
    }
  }
`;

const UPDATE_CST_AG_PN_BRANCH = gql`
  mutation UpdateCstAgPnBranch($id: Int!, $input: CstAgPnBranchUpdateRequest!) {
    updateCstAgPnBranch(id: $id, input: $input) {
      ${BRANCH_FIELDS}
    }
  }
`;

const DELETE_CST_AG_PN_BRANCH = gql`
  mutation DeleteCstAgPnBranch($id: Int!) {
    deleteCstAgPnBranch(id: $id)
  }
`;

const GET_OG_AG_CS_LOOKUPS = gql`
  query GetOgAgCsLookups {
    ogAgCsLookups {
      ogaKey
      ogaNm
    }
  }
`;

const GET_CONSTRUCTION_SITE = gql`
  query GetConstructionSite($id: Int!) {
    constructionSite(id: $id) {
      ${SITE_FIELDS}
    }
  }
`;

const GET_CST_AG_PN_CODES = gql`
  query GetCstAgPnCodes($codeFilter: String) {
    cstAgPnCodes(codeFilter: $codeFilter) {
      cstapKey
      cstapIpgPnN
      cstapCsta
      cstaCst
      cstName
    }
  }
`;

/** Список строек. */
export async function getConstructionSites(): Promise<ConstructionSiteDto[]> {
  try {
    const result = await apolloClient.query<{ constructionSites: ConstructionSiteDto[] }>({
      query: GET_CONSTRUCTION_SITES,
      fetchPolicy: 'network-only'
    });
    return result.data.constructionSites;
  } catch (error) {
    throw wrapApolloError(error, 'GetConstructionSites');
  }
}

/** Создать стройку. */
export async function createConstructionSite(input: CstCreateRequest): Promise<ConstructionSiteDto> {
  try {
    const result = await apolloClient.mutate<{ createConstructionSite: ConstructionSiteDto }>({
      mutation: CREATE_CONSTRUCTION_SITE,
      variables: { input }
    });
    if (!result.data?.createConstructionSite) {
      throw new Error('Пустой ответ createConstructionSite');
    }
    return result.data.createConstructionSite;
  } catch (error) {
    throw wrapApolloError(error, 'CreateConstructionSite');
  }
}

/** Обновить стройку. */
export async function updateConstructionSite(id: number, input: CstUpdateRequest): Promise<ConstructionSiteDto> {
  try {
    const result = await apolloClient.mutate<{ updateConstructionSite: ConstructionSiteDto }>({
      mutation: UPDATE_CONSTRUCTION_SITE,
      variables: { id, input }
    });
    if (!result.data?.updateConstructionSite) {
      throw new Error('Пустой ответ updateConstructionSite');
    }
    return result.data.updateConstructionSite;
  } catch (error) {
    throw wrapApolloError(error, 'UpdateConstructionSite');
  }
}

/** Удалить стройку. */
export async function deleteConstructionSite(id: number): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ deleteConstructionSite: boolean }>({
      mutation: DELETE_CONSTRUCTION_SITE,
      variables: { id }
    });
    return Boolean(result.data?.deleteConstructionSite);
  } catch (error) {
    throw wrapApolloError(error, 'DeleteConstructionSite');
  }
}

/** Агенты стройки. */
export async function getCstAgents(cstKey: number): Promise<CstAgentDto[]> {
  try {
    const result = await apolloClient.query<{ cstAgents: CstAgentDto[] }>({
      query: GET_CST_AGENTS,
      variables: { cstKey },
      fetchPolicy: 'network-only'
    });
    return result.data.cstAgents;
  } catch (error) {
    throw wrapApolloError(error, 'GetCstAgents');
  }
}

/** Создать агента на стройке. */
export async function createCstAgent(input: CstAgCreateRequest): Promise<CstAgentDto> {
  try {
    const result = await apolloClient.mutate<{ createCstAgent: CstAgentDto }>({
      mutation: CREATE_CST_AGENT,
      variables: { input }
    });
    if (!result.data?.createCstAgent) {
      throw new Error('Пустой ответ createCstAgent');
    }
    return result.data.createCstAgent;
  } catch (error) {
    throw wrapApolloError(error, 'CreateCstAgent');
  }
}

/** Обновить агента на стройке. */
export async function updateCstAgent(id: number, input: CstAgUpdateRequest): Promise<CstAgentDto> {
  try {
    const result = await apolloClient.mutate<{ updateCstAgent: CstAgentDto }>({
      mutation: UPDATE_CST_AGENT,
      variables: { id, input }
    });
    if (!result.data?.updateCstAgent) {
      throw new Error('Пустой ответ updateCstAgent');
    }
    return result.data.updateCstAgent;
  } catch (error) {
    throw wrapApolloError(error, 'UpdateCstAgent');
  }
}

/** Удалить агента на стройке. */
export async function deleteCstAgent(id: number): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ deleteCstAgent: boolean }>({
      mutation: DELETE_CST_AGENT,
      variables: { id }
    });
    return Boolean(result.data?.deleteCstAgent);
  } catch (error) {
    throw wrapApolloError(error, 'DeleteCstAgent');
  }
}

/** САК агента. */
export async function getCstAgPoints(cstaKey: number): Promise<CstAgPointDto[]> {
  try {
    const result = await apolloClient.query<{ cstAgPoints: CstAgPointDto[] }>({
      query: GET_CST_AG_POINTS,
      variables: { cstaKey },
      fetchPolicy: 'network-only'
    });
    return result.data.cstAgPoints;
  } catch (error) {
    throw wrapApolloError(error, 'GetCstAgPoints');
  }
}

/** Создать САК. */
export async function createCstAgPoint(input: CstAgPnCreateRequest): Promise<CstAgPointDto> {
  try {
    const result = await apolloClient.mutate<{ createCstAgPoint: CstAgPointDto }>({
      mutation: CREATE_CST_AG_POINT,
      variables: { input }
    });
    if (!result.data?.createCstAgPoint) {
      throw new Error('Пустой ответ createCstAgPoint');
    }
    return result.data.createCstAgPoint;
  } catch (error) {
    throw wrapApolloError(error, 'CreateCstAgPoint');
  }
}

/** Обновить САК. */
export async function updateCstAgPoint(id: number, input: CstAgPnUpdateRequest): Promise<CstAgPointDto> {
  try {
    const result = await apolloClient.mutate<{ updateCstAgPoint: CstAgPointDto }>({
      mutation: UPDATE_CST_AG_POINT,
      variables: { id, input }
    });
    if (!result.data?.updateCstAgPoint) {
      throw new Error('Пустой ответ updateCstAgPoint');
    }
    return result.data.updateCstAgPoint;
  } catch (error) {
    throw wrapApolloError(error, 'UpdateCstAgPoint');
  }
}

/** Удалить САК. */
export async function deleteCstAgPoint(id: number): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ deleteCstAgPoint: boolean }>({
      mutation: DELETE_CST_AG_POINT,
      variables: { id }
    });
    return Boolean(result.data?.deleteCstAgPoint);
  } catch (error) {
    throw wrapApolloError(error, 'DeleteCstAgPoint');
  }
}

/** Филиалы САК. */
export async function getCstAgPnBranches(cstapKey: number): Promise<CstAgPnBranchDto[]> {
  try {
    const result = await apolloClient.query<{ cstAgPnBranches: CstAgPnBranchDto[] }>({
      query: GET_CST_AG_PN_BRANCHES,
      variables: { cstapKey },
      fetchPolicy: 'network-only'
    });
    return result.data.cstAgPnBranches;
  } catch (error) {
    throw wrapApolloError(error, 'GetCstAgPnBranches');
  }
}

/** Создать филиал САК. */
export async function createCstAgPnBranch(input: CstAgPnBranchCreateRequest): Promise<CstAgPnBranchDto> {
  try {
    const result = await apolloClient.mutate<{ createCstAgPnBranch: CstAgPnBranchDto }>({
      mutation: CREATE_CST_AG_PN_BRANCH,
      variables: { input }
    });
    if (!result.data?.createCstAgPnBranch) {
      throw new Error('Пустой ответ createCstAgPnBranch');
    }
    return result.data.createCstAgPnBranch;
  } catch (error) {
    throw wrapApolloError(error, 'CreateCstAgPnBranch');
  }
}

/** Обновить филиал САК. */
export async function updateCstAgPnBranch(
  id: number,
  input: CstAgPnBranchUpdateRequest
): Promise<CstAgPnBranchDto> {
  try {
    const result = await apolloClient.mutate<{ updateCstAgPnBranch: CstAgPnBranchDto }>({
      mutation: UPDATE_CST_AG_PN_BRANCH,
      variables: { id, input }
    });
    if (!result.data?.updateCstAgPnBranch) {
      throw new Error('Пустой ответ updateCstAgPnBranch');
    }
    return result.data.updateCstAgPnBranch;
  } catch (error) {
    throw wrapApolloError(error, 'UpdateCstAgPnBranch');
  }
}

/** Удалить филиал САК. */
export async function deleteCstAgPnBranch(id: number): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ deleteCstAgPnBranch: boolean }>({
      mutation: DELETE_CST_AG_PN_BRANCH,
      variables: { id }
    });
    return Boolean(result.data?.deleteCstAgPnBranch);
  } catch (error) {
    throw wrapApolloError(error, 'DeleteCstAgPnBranch');
  }
}

/** Lookup агентов для combo. */
export async function getOgAgCsLookups(): Promise<OgAgCsLookupDto[]> {
  try {
    const result = await apolloClient.query<{ ogAgCsLookups: OgAgCsLookupDto[] }>({
      query: GET_OG_AG_CS_LOOKUPS,
      fetchPolicy: 'network-only'
    });
    return result.data.ogAgCsLookups;
  } catch (error) {
    throw wrapApolloError(error, 'GetOgAgCsLookups');
  }
}

/** Одна стройка по ключу. */
export async function getConstructionSite(id: number): Promise<ConstructionSiteDto | null> {
  try {
    const result = await apolloClient.query<{ constructionSite: ConstructionSiteDto | null }>({
      query: GET_CONSTRUCTION_SITE,
      variables: { id },
      fetchPolicy: 'network-only'
    });
    return result.data.constructionSite ?? null;
  } catch (error) {
    throw wrapApolloError(error, 'GetConstructionSite');
  }
}

/** Список САК для формы поиска по коду. */
export async function getCstAgPnCodes(codeFilter?: string | null): Promise<CstAgPnCodeDto[]> {
  try {
    const result = await apolloClient.query<{ cstAgPnCodes: CstAgPnCodeDto[] }>({
      query: GET_CST_AG_PN_CODES,
      variables: { codeFilter: codeFilter?.trim() || null },
      fetchPolicy: 'network-only'
    });
    return result.data.cstAgPnCodes;
  } catch (error) {
    throw wrapApolloError(error, 'GetCstAgPnCodes');
  }
}

const RA_LIST_FIELDS = `
  yyyy
  mNum
  p
  cstaKey
  cstaAg
  cstaCst
  ogaNm
  cstapKey
  cstapIpgPnN
  raKey
  raNum
  raDate
  raType
  raChKey
  raChNum
  raChDate
  raOrgSender
  ogNm
  rasTotal
  rasWork
  rasEquip
  rasOthers
  raArrived
  raArrivedDate
  raReturned
  raReturnedDate
  raSent
  raSentDate
`;

const RA_REPORT_FIELDS = `
  raKey
  raNum
  raDate
  raCac
  raType
  raWorkType
  raPeriod
  raArrived
  raArrivedDate
  raReturned
  raReturnedDate
  raSent
  raSentDate
  raNoteT
  raCreated
  raOrgSender
  raNote
`;

const RA_SUMM_FIELDS = `
  rasKey
  rasRa
  rasTotal
  rasWork
  rasEquip
  rasOthers
  rasDate
`;

const GET_CST_RA_LIST = gql`
  query GetCstRaList($cstKey: Int!) {
    cstRaList(cstKey: $cstKey) {
      ${RA_LIST_FIELDS}
    }
  }
`;

const GET_CONSTRUCTION_SITE_REPORT = gql`
  query GetConstructionSiteReport($id: Int!) {
    constructionSiteReport(id: $id) {
      ${RA_REPORT_FIELDS}
    }
  }
`;

const GET_RA_SUMS = gql`
  query GetRaSums($raKey: Int!) {
    raSums(raKey: $raKey) {
      ${RA_SUMM_FIELDS}
    }
  }
`;

const GET_RA_PERIOD_LOOKUPS = gql`
  query GetRaPeriodLookups {
    raPeriodLookups {
      key
      p
    }
  }
`;

const GET_CST_AG_PN_LOOKUPS_FOR_SITE = gql`
  query GetCstAgPnLookupsForSite($cstKey: Int!) {
    cstAgPnLookupsForSite(cstKey: $cstKey) {
      cstapKey
      cstapIpgPnN
      cstaKey
      agentLabel
    }
  }
`;

const CREATE_RA_REPORT = gql`
  mutation CreateRaReport($input: RaReportCreateRequest!) {
    createRaReport(input: $input) {
      ${RA_REPORT_FIELDS}
    }
  }
`;

const UPDATE_RA_REPORT = gql`
  mutation UpdateRaReport($id: Int!, $input: RaReportUpdateRequest!) {
    updateRaReport(id: $id, input: $input) {
      ${RA_REPORT_FIELDS}
    }
  }
`;

const DELETE_RA_REPORT = gql`
  mutation DeleteRaReport($id: Int!) {
    deleteRaReport(id: $id)
  }
`;

const CREATE_RA_SUMM = gql`
  mutation CreateRaSumm($input: RaSummCreateRequest!) {
    createRaSumm(input: $input) {
      ${RA_SUMM_FIELDS}
    }
  }
`;

const UPDATE_RA_SUMM = gql`
  mutation UpdateRaSumm($id: Int!, $input: RaSummUpdateRequest!) {
    updateRaSumm(id: $id, input: $input) {
      ${RA_SUMM_FIELDS}
    }
  }
`;

const DELETE_RA_SUMM = gql`
  mutation DeleteRaSumm($id: Int!) {
    deleteRaSumm(id: $id)
  }
`;

const RALP_LIST_FIELDS = `
  cstKey
  ogaNm
  cstapIpgPnN
  ralprKey
  ralprNum
  ralprDate
  ralprCstAgPn
  ralprOgSender
  ogNm
  auCnt
  hasReturned
`;

const RALP_RA_FIELDS = `
  ralprKey
  ralprNum
  ralprDate
  ralprCstAgPn
  ralprOgSender
  ogNm
  ralprY
  ralprM
`;

const RALP_AU_FIELDS = `
  ralpraKey
  ralpraRa
  ralpraCostAndVat
  ralpraArrived
  ralpraArrivedDate
  ralpraReturned
  ralpraReturnedDate
  ralpraSent
  ralpraSentDate
  ralpraNote
  ralpraStatus
`;

const GET_CST_RALP_RA_LIST = gql`
  query GetCstRalpRaList($cstKey: Int!) {
    cstRalpRaList(cstKey: $cstKey) {
      ${RALP_LIST_FIELDS}
    }
  }
`;

const GET_RALP_RA = gql`
  query GetRalpRa($id: Int!) {
    ralpRa(id: $id) {
      ${RALP_RA_FIELDS}
    }
  }
`;

const GET_RALP_RA_AUS = gql`
  query GetRalpRaAus($ralprKey: Int!) {
    ralpRaAus(ralprKey: $ralprKey) {
      ${RALP_AU_FIELDS}
    }
  }
`;

const GET_RALP_RA_AU_STATUS_LOOKUPS = gql`
  query GetRalpRaAuStatusLookups {
    ralpRaAuStatusLookups {
      code
      label
    }
  }
`;

const CREATE_RALP_RA = gql`
  mutation CreateRalpRa($input: RalpRaCreateRequest!) {
    createRalpRa(input: $input) {
      ${RALP_RA_FIELDS}
    }
  }
`;

const UPDATE_RALP_RA = gql`
  mutation UpdateRalpRa($id: Int!, $input: RalpRaUpdateRequest!) {
    updateRalpRa(id: $id, input: $input) {
      ${RALP_RA_FIELDS}
    }
  }
`;

const DELETE_RALP_RA = gql`
  mutation DeleteRalpRa($id: Int!) {
    deleteRalpRa(id: $id)
  }
`;

const CREATE_RALP_RA_AU = gql`
  mutation CreateRalpRaAu($input: RalpRaAuCreateRequest!) {
    createRalpRaAu(input: $input) {
      ${RALP_AU_FIELDS}
    }
  }
`;

const UPDATE_RALP_RA_AU = gql`
  mutation UpdateRalpRaAu($id: Int!, $input: RalpRaAuUpdateRequest!) {
    updateRalpRaAu(id: $id, input: $input) {
      ${RALP_AU_FIELDS}
    }
  }
`;

const DELETE_RALP_RA_AU = gql`
  mutation DeleteRalpRaAu($id: Int!) {
    deleteRalpRaAu(id: $id)
  }
`;

/** Перечень отчётов стройки (fnRRcList). */
export async function getCstRaList(cstKey: number): Promise<CstRaListEntryDto[]> {
  try {
    const result = await apolloClient.query<{ cstRaList: CstRaListEntryDto[] }>({
      query: GET_CST_RA_LIST,
      variables: { cstKey },
      fetchPolicy: 'network-only'
    });
    return result.data.cstRaList;
  } catch (error) {
    throw wrapApolloError(error, 'GetCstRaList');
  }
}

/** Карточка отчёта ags.ra. */
export async function getConstructionSiteReport(id: number): Promise<RaReportDto | null> {
  try {
    const result = await apolloClient.query<{ constructionSiteReport: RaReportDto | null }>({
      query: GET_CONSTRUCTION_SITE_REPORT,
      variables: { id },
      fetchPolicy: 'network-only'
    });
    return result.data.constructionSiteReport ?? null;
  } catch (error) {
    throw wrapApolloError(error, 'GetConstructionSiteReport');
  }
}

/** Версии сумм отчёта. */
export async function getRaSums(raKey: number): Promise<RaSummDto[]> {
  try {
    const result = await apolloClient.query<{ raSums: RaSummDto[] }>({
      query: GET_RA_SUMS,
      variables: { raKey },
      fetchPolicy: 'network-only'
    });
    return result.data.raSums;
  } catch (error) {
    throw wrapApolloError(error, 'GetRaSums');
  }
}

/** Lookup периодов. */
export async function getRaPeriodLookups(): Promise<RaPeriodLookupDto[]> {
  try {
    const result = await apolloClient.query<{ raPeriodLookups: RaPeriodLookupDto[] }>({
      query: GET_RA_PERIOD_LOOKUPS,
      fetchPolicy: 'network-only'
    });
    return result.data.raPeriodLookups;
  } catch (error) {
    throw wrapApolloError(error, 'GetRaPeriodLookups');
  }
}

/** Lookup САК стройки для ra_cac. */
export async function getCstAgPnLookupsForSite(cstKey: number): Promise<CstAgPnSiteLookupDto[]> {
  try {
    const result = await apolloClient.query<{ cstAgPnLookupsForSite: CstAgPnSiteLookupDto[] }>({
      query: GET_CST_AG_PN_LOOKUPS_FOR_SITE,
      variables: { cstKey },
      fetchPolicy: 'network-only'
    });
    return result.data.cstAgPnLookupsForSite;
  } catch (error) {
    throw wrapApolloError(error, 'GetCstAgPnLookupsForSite');
  }
}

export async function createRaReport(input: RaReportCreateRequest): Promise<RaReportDto> {
  try {
    const result = await apolloClient.mutate<{ createRaReport: RaReportDto }>({
      mutation: CREATE_RA_REPORT,
      variables: { input }
    });
    if (!result.data?.createRaReport) {
      throw new Error('Пустой ответ createRaReport');
    }
    return result.data.createRaReport;
  } catch (error) {
    throw wrapApolloError(error, 'CreateRaReport');
  }
}

export async function updateRaReport(id: number, input: RaReportUpdateRequest): Promise<RaReportDto> {
  try {
    const result = await apolloClient.mutate<{ updateRaReport: RaReportDto }>({
      mutation: UPDATE_RA_REPORT,
      variables: { id, input }
    });
    if (!result.data?.updateRaReport) {
      throw new Error('Пустой ответ updateRaReport');
    }
    return result.data.updateRaReport;
  } catch (error) {
    throw wrapApolloError(error, 'UpdateRaReport');
  }
}

export async function deleteRaReport(id: number): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ deleteRaReport: boolean }>({
      mutation: DELETE_RA_REPORT,
      variables: { id }
    });
    return Boolean(result.data?.deleteRaReport);
  } catch (error) {
    throw wrapApolloError(error, 'DeleteRaReport');
  }
}

export async function createRaSumm(input: RaSummCreateRequest): Promise<RaSummDto> {
  try {
    const result = await apolloClient.mutate<{ createRaSumm: RaSummDto }>({
      mutation: CREATE_RA_SUMM,
      variables: { input }
    });
    if (!result.data?.createRaSumm) {
      throw new Error('Пустой ответ createRaSumm');
    }
    return result.data.createRaSumm;
  } catch (error) {
    throw wrapApolloError(error, 'CreateRaSumm');
  }
}

export async function updateRaSumm(id: number, input: RaSummUpdateRequest): Promise<RaSummDto> {
  try {
    const result = await apolloClient.mutate<{ updateRaSumm: RaSummDto }>({
      mutation: UPDATE_RA_SUMM,
      variables: { id, input }
    });
    if (!result.data?.updateRaSumm) {
      throw new Error('Пустой ответ updateRaSumm');
    }
    return result.data.updateRaSumm;
  } catch (error) {
    throw wrapApolloError(error, 'UpdateRaSumm');
  }
}

export async function deleteRaSumm(id: number): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ deleteRaSumm: boolean }>({
      mutation: DELETE_RA_SUMM,
      variables: { id }
    });
    return Boolean(result.data?.deleteRaSumm);
  } catch (error) {
    throw wrapApolloError(error, 'DeleteRaSumm');
  }
}

/** Перечень отчётов аренды стройки (Access ralpRaCst). */
export async function getCstRalpRaList(cstKey: number): Promise<RalpRaCstListEntryDto[]> {
  try {
    const result = await apolloClient.query<{ cstRalpRaList: RalpRaCstListEntryDto[] }>({
      query: GET_CST_RALP_RA_LIST,
      variables: { cstKey },
      fetchPolicy: 'network-only'
    });
    return result.data.cstRalpRaList;
  } catch (error) {
    throw wrapApolloError(error, 'GetCstRalpRaList');
  }
}

export async function getRalpRa(id: number): Promise<RalpRaDto | null> {
  try {
    const result = await apolloClient.query<{ ralpRa: RalpRaDto | null }>({
      query: GET_RALP_RA,
      variables: { id },
      fetchPolicy: 'network-only'
    });
    return result.data.ralpRa;
  } catch (error) {
    throw wrapApolloError(error, 'GetRalpRa');
  }
}

export async function getRalpRaAus(ralprKey: number): Promise<RalpRaAuDto[]> {
  try {
    const result = await apolloClient.query<{ ralpRaAus: RalpRaAuDto[] }>({
      query: GET_RALP_RA_AUS,
      variables: { ralprKey },
      fetchPolicy: 'network-only'
    });
    return result.data.ralpRaAus;
  } catch (error) {
    throw wrapApolloError(error, 'GetRalpRaAus');
  }
}

export async function getRalpRaAuStatusLookups(): Promise<RalpRaAuStatusLookupDto[]> {
  try {
    const result = await apolloClient.query<{ ralpRaAuStatusLookups: RalpRaAuStatusLookupDto[] }>({
      query: GET_RALP_RA_AU_STATUS_LOOKUPS,
      fetchPolicy: 'network-only'
    });
    return result.data.ralpRaAuStatusLookups;
  } catch (error) {
    throw wrapApolloError(error, 'GetRalpRaAuStatusLookups');
  }
}

export async function createRalpRa(input: RalpRaCreateRequest): Promise<RalpRaDto> {
  try {
    const result = await apolloClient.mutate<{ createRalpRa: RalpRaDto }>({
      mutation: CREATE_RALP_RA,
      variables: { input }
    });
    if (!result.data?.createRalpRa) {
      throw new Error('Пустой ответ createRalpRa');
    }
    return result.data.createRalpRa;
  } catch (error) {
    throw wrapApolloError(error, 'CreateRalpRa');
  }
}

export async function updateRalpRa(id: number, input: RalpRaUpdateRequest): Promise<RalpRaDto> {
  try {
    const result = await apolloClient.mutate<{ updateRalpRa: RalpRaDto }>({
      mutation: UPDATE_RALP_RA,
      variables: { id, input }
    });
    if (!result.data?.updateRalpRa) {
      throw new Error('Пустой ответ updateRalpRa');
    }
    return result.data.updateRalpRa;
  } catch (error) {
    throw wrapApolloError(error, 'UpdateRalpRa');
  }
}

export async function deleteRalpRa(id: number): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ deleteRalpRa: boolean }>({
      mutation: DELETE_RALP_RA,
      variables: { id }
    });
    return Boolean(result.data?.deleteRalpRa);
  } catch (error) {
    throw wrapApolloError(error, 'DeleteRalpRa');
  }
}

export async function createRalpRaAu(input: RalpRaAuCreateRequest): Promise<RalpRaAuDto> {
  try {
    const result = await apolloClient.mutate<{ createRalpRaAu: RalpRaAuDto }>({
      mutation: CREATE_RALP_RA_AU,
      variables: { input }
    });
    if (!result.data?.createRalpRaAu) {
      throw new Error('Пустой ответ createRalpRaAu');
    }
    return result.data.createRalpRaAu;
  } catch (error) {
    throw wrapApolloError(error, 'CreateRalpRaAu');
  }
}

export async function updateRalpRaAu(id: number, input: RalpRaAuUpdateRequest): Promise<RalpRaAuDto> {
  try {
    const result = await apolloClient.mutate<{ updateRalpRaAu: RalpRaAuDto }>({
      mutation: UPDATE_RALP_RA_AU,
      variables: { id, input }
    });
    if (!result.data?.updateRalpRaAu) {
      throw new Error('Пустой ответ updateRalpRaAu');
    }
    return result.data.updateRalpRaAu;
  } catch (error) {
    throw wrapApolloError(error, 'UpdateRalpRaAu');
  }
}

export async function deleteRalpRaAu(id: number): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ deleteRalpRaAu: boolean }>({
      mutation: DELETE_RALP_RA_AU,
      variables: { id }
    });
    return Boolean(result.data?.deleteRalpRaAu);
  } catch (error) {
    throw wrapApolloError(error, 'DeleteRalpRaAu');
  }
}
