/**
 * Apollo API клиент СУДЗ (read/write).
 */

import { gql } from '@apollo/client/core';

import { apolloClient } from '@/plugins/apollo';
import { RequestError } from './http';
import type {
  CreateSudzCmmGrInput,
  CreateSudzPmUplInput,
  CreateSudzDbtUplFileShInput,
  CreateSudzUplInput,
  CreateSudzYearInput,
  LinkSudzSfDoubleInput,
  SudzCmmGrLookup,
  SudzCnInvUplSfDouble,
  SudzCnInvUplInvDbtDouble,
  SudzInvDbtDoubleAdvice,
  SudzInvDbtSlotTimeline,
  SudzInvDbtVarCandidates,
  SudzD644Row,
  SudzDbtUplFile,
  SudzDbtUplLauncher,
  SudzDebtCollectionInput,
  SudzDebtCollectionResult,
  SudzPmLink,
  SudzPmUplLookup,
  SudzRsltDebt,
  SudzRsltReturnImportResult,
  SudzSfDoubleDomainMatch,
  SudzSfDoubleExcelCandidate,
  SudzSfDoubleHints,
  SudzSfDoubleAdvice,
  SudzSfDoubleSumMatches,
  SudzSvodResult,
  SudzUplLookup,
  SudzYear,
  SudzYearDetail,
  SudzYearUpl,
  SudzYyyyLookup,
  UpdateSudzDbtUplFileInput,
  UpdateSudzDbtUplFileShInput,
  SudzDbtUplFileSh,
  RunSudzDbtUplFunnelInput,
  SudzDbtUplFunnelResult,
  UpdateSudzYearInput
} from '@/types/sudz';

function wrapApolloError(error: unknown, operation: string): RequestError {
  const message = error instanceof Error ? error.message : `Ошибка GraphQL операции ${operation}`;
  return new RequestError(message, {
    status: 0,
    statusText: 'GraphQL',
    url: '/graphql',
    body: { operation }
  });
}

const YEAR_FIELDS = `
  yrKey
  yrVariant
  baseUpl
  yyyy
  cmmGr
  cmmGrNew
  baseUplName
  baseUplDate
  cmmGrName
  cmmGrDate
  cmmGrNewName
  cmmGrNewDate
  yyyyValue
  progress
`;

const YEAR_DETAIL_FIELDS = `
  year { ${YEAR_FIELDS} }
  upls {
    yrUplPKey
    yrKey
    uplKey
    uplName
    uplDate
    uplStatusOnDate
    pmLinks {
      gPKey
      dbtUpl
      pmKey
      pmName
      pmDate
      dbtUplName
      dbtUplDate
    }
  }
`;

const SUDZ_YEARS = gql`
  query SudzYears {
    sudzYears {
      ${YEAR_FIELDS}
    }
  }
`;

const SUDZ_YEAR = gql`
  query SudzYear($yrKey: Int!) {
    sudzYear(yrKey: $yrKey) {
      ${YEAR_DETAIL_FIELDS}
    }
  }
`;

const SUDZ_UPL_LOOKUPS = gql`
  query SudzUplLookups {
    sudzUplLookups {
      uplKey
      uplName
      uplDate
      uplStatusOnDate
    }
  }
`;

const DBT_UPL_FILE_FIELDS = `
  cidufKey
  cidufUpload
  cidufPath
  cidufFlLoad
  cidufFlTbl
  cidufLoadingProgress
`;

/** Поля File без HTML-лога (ответ mutation воронки — лог подгружается отдельно). */
const DBT_UPL_FILE_FIELDS_SLIM = `
  cidufKey
  cidufUpload
  cidufPath
  cidufFlLoad
  cidufFlTbl
`;

const SF_DOUBLE_FIELDS = `
  ciusKey
  ciusCidut
  ciusCiput
  ciusDbtFile
  ciusPmtFile
  ciusUnloadKey
  ciusDbtTblCnInvRow
  ciusPmtTblCnInvRow
  ciusCnKey
  ciusCnNum
  ciusInvNum
  ciusInvNumCount
  ciusStatus
  ciusStatusAt
  ciusCreatedInvKey
`;

const INV_DBT_DOUBLE_FIELDS = `
  ciudKey
  ciudCidut
  ciudDbtFile
  ciudUnloadKey
  ciudIKey
  ciudCnNum
  ciudInvNum
  ciudDebt
  ciudIdvvKey
  ciudReason
  ciudReasonDetail
  ciudStatus
  ciudStatusAt
  ciudCreatedIdKey
`;

const DBT_P1_FIELDS = `
  cip1Key
  cip1UnloadKey
  cip1BaseUpl
  cip1DbtFile
  cip1DbtKey
  cip1BaseSlotKey
  cip1BaseIKey
  cip1BaseCnNum
  cip1BaseInvNum
  cip1MatchSum
  cip1SumKind
  cip1CandCidut
  cip1CandIKey
  cip1CandCnNum
  cip1CandInvNum
  cip1CandDebt
  cip1Reason
  cip1ReasonDetail
  cip1Status
  cip1StatusAt
  cip1LinkedSlotKey
`;

const SUDZ_DBT_UPL_LAUNCHER = gql`
  query SudzDbtUplLauncher($uplKey: Int!) {
    sudzDbtUplLauncher(uplKey: $uplKey) {
      upl {
        uplKey
        uplName
        uplDate
        uplStatusOnDate
      }
      file {
        ${DBT_UPL_FILE_FIELDS}
      }
      sheets {
        cidufsKey
        cidufsFile
        cidufsSheet
        cidufsAccount
        accountNum
        cidufsTest
      }
      invDoubles {
        cidufiKey
        cidufiCiduf
        cidufiCnNnn
        cidufiCnNum
        cidufiCnKey
        cidufiInvNnn
        cidufiInvNum
        cidufiInvNumCount
      }
      sfDoubles {
        ${SF_DOUBLE_FIELDS}
      }
      invDbtDoubles {
        ${INV_DBT_DOUBLE_FIELDS}
      }
      dbtP1 {
        ${DBT_P1_FIELDS}
      }
    }
  }
`;

const UPDATE_DBT_UPL_FILE = gql`
  mutation UpdateSudzDbtUplFile($input: UpdateSudzDbtUplFileInput!) {
    updateSudzDbtUplFile(input: $input) {
      ${DBT_UPL_FILE_FIELDS}
    }
  }
`;

const CREATE_DBT_UPL_FILE_SH = gql`
  mutation CreateSudzDbtUplFileSh($input: CreateSudzDbtUplFileShInput!) {
    createSudzDbtUplFileSh(input: $input) {
      cidufsKey cidufsFile cidufsSheet cidufsAccount accountNum cidufsTest
    }
  }
`;

const UPDATE_DBT_UPL_FILE_SH = gql`
  mutation UpdateSudzDbtUplFileSh($input: UpdateSudzDbtUplFileShInput!) {
    updateSudzDbtUplFileSh(input: $input) {
      cidufsKey cidufsFile cidufsSheet cidufsAccount accountNum cidufsTest
    }
  }
`;

const DELETE_DBT_UPL_FILE_SH = gql`
  mutation DeleteSudzDbtUplFileSh($cidufsKey: Int!) {
    deleteSudzDbtUplFileSh(cidufsKey: $cidufsKey)
  }
`;

const SEED_DBT_UPL_STANDARD_SHEETS = gql`
  mutation SeedSudzDbtUplStandardSheets($uplKey: Int!) {
    seedSudzDbtUplStandardSheets(uplKey: $uplKey) {
      cidufsKey cidufsFile cidufsSheet cidufsAccount accountNum cidufsTest
    }
  }
`;

const SUDZ_YEAR_KEYS_FOR_UPL = gql`
  query SudzYearKeysForUpl($uplKey: Int!) {
    sudzYearKeysForUpl(uplKey: $uplKey)
  }
`;

const RUN_DBT_UPL_FUNNEL = gql`
  mutation RunSudzDbtUplFunnel($input: RunSudzDbtUplFunnelInput!) {
    runSudzDbtUplFunnel(input: $input) {
      stub
      ranSteps
      launcher {
        upl {
          uplKey
          uplName
          uplDate
          uplStatusOnDate
        }
        file {
          ${DBT_UPL_FILE_FIELDS_SLIM}
        }
        sheets {
          cidufsKey
          cidufsFile
          cidufsSheet
          cidufsAccount
          accountNum
          cidufsTest
        }
        invDoubles {
          cidufiKey
          cidufiCiduf
          cidufiCnNnn
          cidufiCnNum
          cidufiCnKey
          cidufiInvNnn
          cidufiInvNum
          cidufiInvNumCount
        }
        sfDoubles {
          ${SF_DOUBLE_FIELDS}
        }
        invDbtDoubles {
          ${INV_DBT_DOUBLE_FIELDS}
        }
        dbtP1 {
          ${DBT_P1_FIELDS}
        }
      }
    }
  }
`;

const SUDZ_SF_DOUBLE_EXCEL = gql`
  query SudzSfDoubleExcelCandidate($ciusKey: Int!) {
    sudzSfDoubleExcelCandidate(ciusKey: $ciusKey) {
      cidutKey
      findDbtNum
      cidutAccount
      cidutAccntNum
      cidutCntrPrtNum
      cidutCntrPrtName
      cidutCntrPrtITN
      cidutCnName
      cidutCnDate
      cidutCnInv
      cidutCnInvName
      cidutFormtnDate
      cidutMatrtyDate
      cidutDebt
      cidutDebtOverdue
      cidutDoc
      cidutLink
      cidutSheet
      cidutSheetNum
      cidutUnloadKey
    }
  }
`;

const SUDZ_INV_DBT_DOUBLE_EXCEL = gql`
  query SudzInvDbtDoubleExcelCandidate($ciudKey: Int!) {
    sudzInvDbtDoubleExcelCandidate(ciudKey: $ciudKey) {
      cidutKey
      findDbtNum
      cidutAccount
      cidutAccntNum
      cidutCntrPrtNum
      cidutCntrPrtName
      cidutCntrPrtITN
      cidutCnName
      cidutCnDate
      cidutCnInv
      cidutCnInvName
      cidutFormtnDate
      cidutMatrtyDate
      cidutDebt
      cidutDebtOverdue
      cidutDoc
      cidutLink
      cidutSheet
      cidutSheetNum
      cidutUnloadKey
    }
  }
`;

const SUDZ_INV_DBT_SLOTS = gql`
  query SudzInvDbtSlots($iKey: Int!) {
    sudzInvDbtSlots(iKey: $iKey) {
      idKey
      idInv
      idNum
      idNote
    }
  }
`;

const SUDZ_INV_DBT_DOUBLE_ADVICE = gql`
  query SudzInvDbtDoubleAdvice($ciudKey: Int!, $epsilon: Float) {
    sudzInvDbtDoubleAdvice(ciudKey: $ciudKey, epsilon: $epsilon) {
      messageText
      confidence
      action
      recommendIdKey
      recommendVarKey
    }
  }
`;

const SUDZ_INV_DBT_SLOT_TIMELINE = gql`
  query SudzInvDbtSlotTimeline($iKey: Int!, $idKey: Int!, $ciudKey: Int!) {
    sudzInvDbtSlotTimeline(iKey: $iKey, idKey: $idKey, ciudKey: $ciudKey) {
      idKey
      idNum
      ciaName
      varKey
      accnt
      excelAnchor
      excelStatusDate
      points {
        uplKey
        statusDate
        ttl
        overdue
        source
        varKey
      }
    }
  }
`;

const CREATE_INV_DBT_FROM_DOUBLE = gql`
  mutation CreateSudzInvDbtFromDouble($ciudKey: Int!) {
    createSudzInvDbtFromDouble(ciudKey: $ciudKey) {
      ${INV_DBT_DOUBLE_FIELDS}
    }
  }
`;

const LINK_INV_DBT_DOUBLE = gql`
  mutation LinkSudzInvDbtDouble($input: LinkSudzInvDbtDoubleInput!) {
    linkSudzInvDbtDouble(input: $input) {
      ${INV_DBT_DOUBLE_FIELDS}
    }
  }
`;

const SUDZ_INV_DBT_VAR_CANDIDATES = gql`
  query SudzInvDbtVarCandidates($ciudKey: Int!) {
    sudzInvDbtVarCandidates(ciudKey: $ciudKey) {
      ciudKey
      iKey
      accountKey
      sides {
        cnKey
        cnSOrgKey
        csoCnDate
      }
      cnNums {
        cnnKey
        cnKey
        cnnNumNull
      }
      invNums {
        inKey
        inInv
        inNumNull
      }
    }
  }
`;

const ENSURE_INV_DBT_VAR_FOR_DOUBLE = gql`
  mutation EnsureSudzInvDbtVarForDouble($input: EnsureSudzInvDbtVarForDoubleInput!) {
    ensureSudzInvDbtVarForDouble(input: $input) {
      ${INV_DBT_DOUBLE_FIELDS}
    }
  }
`;

const SUDZ_SF_DOUBLE_DOMAIN = gql`
  query SudzSfDoubleDomainMatches($invNum: String!) {
    sudzSfDoubleDomainMatches(invNum: $invNum) {
      invKey
      invNum
      invNumKey
      invEntered
      ciKey
      cnKey
      cnNum
    }
  }
`;

const SUDZ_SF_DOUBLE_SUM_MATCHES = gql`
  query SudzSfDoubleSumMatches($debt: Float!, $epsilon: Float) {
    sudzSfDoubleSumMatches(debt: $debt, epsilon: $epsilon) {
      oldMatches {
        cidKey
        number
        dbtTtl
        dbtOverd
        debtType
        uplKey
        ciaKey
        ciaName
      }
      newMatches {
        dvKey
        dvTtl
        dvOverd
        dvUpl
        dvInvDbt
        dbtKey
      }
    }
  }
`;

const SUDZ_SF_DOUBLE_HINTS = gql`
  query SudzSfDoubleHints($ciusKey: Int!, $epsilon: Float) {
    sudzSfDoubleHints(ciusKey: $ciusKey, epsilon: $epsilon) {
      sfByNum {
        status
        message
        totalCount
        items {
          zone
          pickKey
          pickValue
          invKey
          cnKey
          cnNum
          matchBy
          label
        }
      }
      sumsOld {
        status
        message
        totalCount
        items {
          zone
          pickKey
          pickValue
          invKey
          cnKey
          cnNum
          matchBy
          label
        }
      }
      sumsNew {
        status
        message
        totalCount
        items {
          zone
          pickKey
          pickValue
          invKey
          cnKey
          cnNum
          matchBy
          label
        }
      }
    }
  }
`;

const SUDZ_SF_DOUBLE_ADVICE = gql`
  query SudzSfDoubleAdvice($ciusKey: Int!, $epsilon: Float) {
    sudzSfDoubleAdvice(ciusKey: $ciusKey, epsilon: $epsilon) {
      messageText
      confidence
      action
      recommendInvKey
      recommendCnKey
    }
  }
`;

const CREATE_SF_FROM_DOUBLE = gql`
  mutation CreateSudzSfFromDouble($ciusKey: Int!) {
    createSudzSfFromDouble(ciusKey: $ciusKey) {
      ${SF_DOUBLE_FIELDS}
    }
  }
`;

const LINK_SF_DOUBLE_TO_CN = gql`
  mutation LinkSudzSfDoubleToCn($input: LinkSudzSfDoubleInput!) {
    linkSudzSfDoubleToCn(input: $input) {
      ${SF_DOUBLE_FIELDS}
    }
  }
`;

const SUDZ_CMM_GR_LOOKUPS = gql`
  query SudzCmmGrLookups {
    sudzCmmGrLookups {
      cmmGrKey
      name
      date
    }
  }
`;

const SUDZ_YYYY_LOOKUPS = gql`
  query SudzYyyyLookups {
    sudzYyyyLookups {
      yKey
      yyyy
    }
  }
`;

const SUDZ_PM_LOOKUPS = gql`
  query SudzPmUplLookups {
    sudzPmUplLookups {
      pmKey
      name
      date
    }
  }
`;

const CREATE_YEAR = gql`
  mutation CreateSudzYear($input: CreateSudzYearInput!) {
    createSudzYear(input: $input) { ${YEAR_DETAIL_FIELDS} }
  }
`;

const UPDATE_YEAR = gql`
  mutation UpdateSudzYear($input: UpdateSudzYearInput!) {
    updateSudzYear(input: $input) { ${YEAR_DETAIL_FIELDS} }
  }
`;

const DELETE_YEAR = gql`
  mutation DeleteSudzYear($yrKey: Int!) {
    deleteSudzYear(yrKey: $yrKey)
  }
`;

const CREATE_CMM_GR = gql`
  mutation CreateSudzCmmGr($input: CreateSudzCmmGrInput!) {
    createSudzCmmGr(input: $input) {
      cmmGrKey
      name
      date
    }
  }
`;

const CREATE_UPL = gql`
  mutation CreateSudzUpl($input: CreateSudzUplInput!) {
    createSudzUpl(input: $input) {
      uplKey
      uplName
      uplDate
      uplStatusOnDate
    }
  }
`;

const ADD_YEAR_UPL = gql`
  mutation AddSudzYearUpl($yrKey: Int!, $uplKey: Int!) {
    addSudzYearUpl(yrKey: $yrKey, uplKey: $uplKey) {
      yrUplPKey
      yrKey
      uplKey
      uplName
      uplDate
      uplStatusOnDate
      pmLinks { gPKey }
    }
  }
`;

const REMOVE_YEAR_UPL = gql`
  mutation RemoveSudzYearUpl($yrUplPKey: Int!) {
    removeSudzYearUpl(yrUplPKey: $yrUplPKey)
  }
`;

const CREATE_PM = gql`
  mutation CreateSudzPmUpl($input: CreateSudzPmUplInput!) {
    createSudzPmUpl(input: $input) {
      pmKey
      name
      date
    }
  }
`;

const ADD_PM_LINK = gql`
  mutation AddSudzPmLink($dbtUplKey: Int!, $pmKey: Int!) {
    addSudzPmLink(dbtUplKey: $dbtUplKey, pmKey: $pmKey) {
      gPKey
      dbtUpl
      pmKey
      pmName
      pmDate
      dbtUplName
      dbtUplDate
    }
  }
`;

const REMOVE_PM_LINK = gql`
  mutation RemoveSudzPmLink($gPKey: Int!) {
    removeSudzPmLink(gPKey: $gPKey)
  }
`;

const SUDZ_YR_DBT_CHANGES = gql`
  query SudzYrDbtChanges($yr: Int!, $asOfUpl: Int) {
    sudzYrDbtChanges(yr: $yr, asOfUpl: $asOfUpl) {
      dbtKey
      accountNum
      curator
      mery
      cstCode
      cstName
      curatorNew
      meryNew
      cstCodeNew
      periods {
        uplKey
        uplDate
        asOf
        invNumEnum
        idNum
        cnNumEnum
        csoCnDate
        orgIdValueL
        itn
        ctptOrg
        maturity
        ttl
        overd
        cstAgPnCode
        cstAgPnName
        agOrg
        pogasheno
      }
    }
  }
`;

const SUDZ_D644 = gql`
  query SudzD644($yr: Int!, $currUpl: Int!) {
    sudzD644(yr: $yr, currUpl: $currUpl) {
      dbtKey
      accountNum
      agent
      orgId
      itn
      counterpart
      contract
      contractDate
      invoice
      dateStart
      maturityBase
      ttlBase
      overdBase
      maturityCurr
      overdCurr
      repaid
      cstCode
      cstName
      comment644
      baseUplDate
      currUplDate
      baseUpl
      currUpl
    }
  }
`;

const SUDZ_D644_SVOD = gql`
  query SudzD644Svod($yr: Int!, $currUpl: Int!) {
    sudzD644Svod(yr: $yr, currUpl: $currUpl) {
      accounts {
        accountNum
        accountName
        overdBase
        repaid
        overdCurr
        repaidPct
      }
      total {
        overdBase
        repaid
        overdCurr
        repaidPct
      }
    }
  }
`;

const UPDATE_SUDZ_DEBT_COLLECTION = gql`
  mutation UpdateSudzDebtCollection($input: SudzDebtCollectionInput!) {
    updateSudzDebtCollection(input: $input) {
      dbtKey
      curator
      mery
      cstCode
      cstName
      cmmGr
    }
  }
`;

/** Список год-вариантов. */
export async function getSudzYears(): Promise<SudzYear[]> {
  try {
    const result = await apolloClient.query<{ sudzYears: SudzYear[] }>({
      query: SUDZ_YEARS,
      fetchPolicy: 'network-only'
    });
    return result.data.sudzYears;
  } catch (error) {
    throw wrapApolloError(error, 'SudzYears');
  }
}

/** Карточка года. */
export async function getSudzYear(yrKey: number): Promise<SudzYearDetail> {
  try {
    const result = await apolloClient.query<{ sudzYear: SudzYearDetail }>({
      query: SUDZ_YEAR,
      variables: { yrKey },
      fetchPolicy: 'network-only'
    });
    return result.data.sudzYear;
  } catch (error) {
    throw wrapApolloError(error, 'SudzYear');
  }
}

export async function getSudzUplLookups(): Promise<SudzUplLookup[]> {
  try {
    const result = await apolloClient.query<{ sudzUplLookups: SudzUplLookup[] }>({
      query: SUDZ_UPL_LOOKUPS,
      fetchPolicy: 'network-only'
    });
    return result.data.sudzUplLookups;
  } catch (error) {
    throw wrapApolloError(error, 'SudzUplLookups');
  }
}

/**
 * Лаунчер загрузки свода для выбранной выгрузки.
 */
export async function getSudzDbtUplLauncher(uplKey: number): Promise<SudzDbtUplLauncher> {
  try {
    const result = await apolloClient.query<{ sudzDbtUplLauncher: SudzDbtUplLauncher }>({
      query: SUDZ_DBT_UPL_LAUNCHER,
      variables: { uplKey },
      fetchPolicy: 'network-only'
    });
    const data = result.data?.sudzDbtUplLauncher;
    if (!data) throw new Error('Пустой ответ sudzDbtUplLauncher');
    return { ...data, sfDoubles: data.sfDoubles ?? [], invDbtDoubles: data.invDbtDoubles ?? [], dbtP1: data.dbtP1 ?? [] };
  } catch (error) {
    throw wrapApolloError(error, 'SudzDbtUplLauncher');
  }
}

/**
 * Excel-кандидат КСДСФ.
 */
export async function getSudzSfDoubleExcelCandidate(
  ciusKey: number
): Promise<SudzSfDoubleExcelCandidate | null> {
  try {
    const result = await apolloClient.query<{
      sudzSfDoubleExcelCandidate: SudzSfDoubleExcelCandidate | null;
    }>({
      query: SUDZ_SF_DOUBLE_EXCEL,
      variables: { ciusKey },
      fetchPolicy: 'network-only'
    });
    return result.data?.sudzSfDoubleExcelCandidate ?? null;
  } catch (error) {
    throw wrapApolloError(error, 'SudzSfDoubleExcelCandidate');
  }
}

/**
 * Доменные СФ с совпадающим номером.
 */
export async function getSudzSfDoubleDomainMatches(
  invNum: string
): Promise<SudzSfDoubleDomainMatch[]> {
  try {
    const result = await apolloClient.query<{
      sudzSfDoubleDomainMatches: SudzSfDoubleDomainMatch[];
    }>({
      query: SUDZ_SF_DOUBLE_DOMAIN,
      variables: { invNum },
      fetchPolicy: 'network-only'
    });
    return result.data?.sudzSfDoubleDomainMatches ?? [];
  } catch (error) {
    throw wrapApolloError(error, 'SudzSfDoubleDomainMatches');
  }
}

/**
 * Кандидаты вкладки «Суммы» по сумме Excel ±ε.
 */
export async function getSudzSfDoubleSumMatches(
  debt: number,
  epsilon: number = 0.01
): Promise<SudzSfDoubleSumMatches> {
  try {
    const result = await apolloClient.query<{
      sudzSfDoubleSumMatches: SudzSfDoubleSumMatches;
    }>({
      query: SUDZ_SF_DOUBLE_SUM_MATCHES,
      variables: { debt, epsilon },
      fetchPolicy: 'network-only'
    });
    const data = result.data?.sudzSfDoubleSumMatches;
    if (!data) {
      return { oldMatches: [], newMatches: [] };
    }
    return {
      oldMatches: data.oldMatches ?? [],
      newMatches: data.newMatches ?? []
    };
  } catch (error) {
    throw wrapApolloError(error, 'SudzSfDoubleSumMatches');
  }
}

/**
 * Подсказки КСДСФ: исполнитель Excel среди СФ по номеру и сумм.
 */
export async function getSudzSfDoubleHints(
  ciusKey: number,
  epsilon: number = 0.01
): Promise<SudzSfDoubleHints> {
  try {
    const result = await apolloClient.query<{
      sudzSfDoubleHints: SudzSfDoubleHints;
    }>({
      query: SUDZ_SF_DOUBLE_HINTS,
      variables: { ciusKey, epsilon },
      fetchPolicy: 'network-only'
    });
    const data = result.data?.sudzSfDoubleHints;
    if (!data) {
      const empty = { status: 'na', message: 'Нет данных подсказки.', totalCount: 0, items: [] };
      return { sfByNum: empty, sumsOld: empty, sumsNew: empty };
    }
    return data;
  } catch (error) {
    throw wrapApolloError(error, 'SudzSfDoubleHints');
  }
}

/** Советник КСДСФ для панели «Сообщения». */
export async function getSudzSfDoubleAdvice(
  ciusKey: number,
  epsilon: number = 0.01
): Promise<SudzSfDoubleAdvice> {
  try {
    const result = await apolloClient.query<{
      sudzSfDoubleAdvice: SudzSfDoubleAdvice;
    }>({
      query: SUDZ_SF_DOUBLE_ADVICE,
      variables: { ciusKey, epsilon },
      fetchPolicy: 'network-only'
    });
    const data = result.data?.sudzSfDoubleAdvice;
    if (!data) {
      return {
        messageText: '[советник]\nнет данных',
        confidence: 'none',
        action: 'manual',
        recommendInvKey: null,
        recommendCnKey: null
      };
    }
    return data;
  } catch (error) {
    throw wrapApolloError(error, 'SudzSfDoubleAdvice');
  }
}

/**
 * Создать СФ из строки очереди КСДСФ.
 */
export async function createSudzSfFromDouble(ciusKey: number): Promise<SudzCnInvUplSfDouble> {
  try {
    const result = await apolloClient.mutate<{ createSudzSfFromDouble: SudzCnInvUplSfDouble }>({
      mutation: CREATE_SF_FROM_DOUBLE,
      variables: { ciusKey }
    });
    const data = result.data?.createSudzSfFromDouble;
    if (!data) throw new Error('Пустой ответ createSudzSfFromDouble');
    return data;
  } catch (error) {
    throw wrapApolloError(error, 'CreateSudzSfFromDouble');
  }
}

/** Excel-кандидат очереди двоящих долгов. */
export async function getSudzInvDbtDoubleExcelCandidate(
  ciudKey: number
): Promise<SudzSfDoubleExcelCandidate | null> {
  try {
    const result = await apolloClient.query<{
      sudzInvDbtDoubleExcelCandidate: SudzSfDoubleExcelCandidate | null;
    }>({
      query: SUDZ_INV_DBT_DOUBLE_EXCEL,
      variables: { ciudKey },
      fetchPolicy: 'network-only'
    });
    return result.data?.sudzInvDbtDoubleExcelCandidate ?? null;
  } catch (error) {
    throw wrapApolloError(error, 'SudzInvDbtDoubleExcelCandidate');
  }
}

/** Слоты invDbt по СФ. */
export async function getSudzInvDbtSlots(
  iKey: number
): Promise<{ idKey: number; idInv: number; idNum: number; idNote: string | null }[]> {
  try {
    const result = await apolloClient.query<{
      sudzInvDbtSlots: { idKey: number; idInv: number; idNum: number; idNote: string | null }[];
    }>({
      query: SUDZ_INV_DBT_SLOTS,
      variables: { iKey },
      fetchPolicy: 'network-only'
    });
    return result.data?.sudzInvDbtSlots ?? [];
  } catch (error) {
    throw wrapApolloError(error, 'SudzInvDbtSlots');
  }
}

/** Советник КСДД для панели «Сообщения». */
export async function getSudzInvDbtDoubleAdvice(
  ciudKey: number,
  epsilon: number = 0.01
): Promise<SudzInvDbtDoubleAdvice> {
  try {
    const result = await apolloClient.query<{
      sudzInvDbtDoubleAdvice: SudzInvDbtDoubleAdvice;
    }>({
      query: SUDZ_INV_DBT_DOUBLE_ADVICE,
      variables: { ciudKey, epsilon },
      fetchPolicy: 'network-only'
    });
    const data = result.data?.sudzInvDbtDoubleAdvice;
    if (!data) {
      return {
        messageText: '[advisor]\nнет данных',
        confidence: 'none',
        action: 'manual',
        recommendIdKey: null,
        recommendVarKey: null
      };
    }
    return data;
  } catch (error) {
    throw wrapApolloError(error, 'SudzInvDbtDoubleAdvice');
  }
}

/** Временной ряд DbtValue выбранного слота. */
export async function getSudzInvDbtSlotTimeline(
  iKey: number,
  idKey: number,
  ciudKey: number
): Promise<SudzInvDbtSlotTimeline> {
  try {
    const result = await apolloClient.query<{
      sudzInvDbtSlotTimeline: SudzInvDbtSlotTimeline;
    }>({
      query: SUDZ_INV_DBT_SLOT_TIMELINE,
      variables: { iKey, idKey, ciudKey },
      fetchPolicy: 'network-only'
    });
    const data = result.data?.sudzInvDbtSlotTimeline;
    if (!data) {
      throw new Error('Пустой ответ sudzInvDbtSlotTimeline');
    }
    return data;
  } catch (error) {
    throw wrapApolloError(error, 'SudzInvDbtSlotTimeline');
  }
}

/** Create слота + DbtValue из очереди двоящих. */
export async function createSudzInvDbtFromDouble(
  ciudKey: number
): Promise<SudzCnInvUplInvDbtDouble> {
  try {
    const result = await apolloClient.mutate<{
      createSudzInvDbtFromDouble: SudzCnInvUplInvDbtDouble;
    }>({
      mutation: CREATE_INV_DBT_FROM_DOUBLE,
      variables: { ciudKey }
    });
    const data = result.data?.createSudzInvDbtFromDouble;
    if (!data) throw new Error('Пустой ответ createSudzInvDbtFromDouble');
    return data;
  } catch (error) {
    throw wrapApolloError(error, 'CreateSudzInvDbtFromDouble');
  }
}

/** Link слота + DbtValue. */
export async function linkSudzInvDbtDouble(
  ciudKey: number,
  idKey: number
): Promise<SudzCnInvUplInvDbtDouble> {
  try {
    const result = await apolloClient.mutate<{
      linkSudzInvDbtDouble: SudzCnInvUplInvDbtDouble;
    }>({
      mutation: LINK_INV_DBT_DOUBLE,
      variables: { input: { ciudKey, idKey } }
    });
    const data = result.data?.linkSudzInvDbtDouble;
    if (!data) throw new Error('Пустой ответ linkSudzInvDbtDouble');
    return data;
  } catch (error) {
    throw wrapApolloError(error, 'LinkSudzInvDbtDouble');
  }
}

/** Кандидаты FK для create invDbtVar. */
export async function getSudzInvDbtVarCandidates(
  ciudKey: number
): Promise<SudzInvDbtVarCandidates> {
  try {
    const result = await apolloClient.query<{
      sudzInvDbtVarCandidates: SudzInvDbtVarCandidates;
    }>({
      query: SUDZ_INV_DBT_VAR_CANDIDATES,
      variables: { ciudKey },
      fetchPolicy: 'network-only'
    });
    const data = result.data?.sudzInvDbtVarCandidates;
    if (!data) throw new Error('Пустой ответ sudzInvDbtVarCandidates');
    return {
      ...data,
      sides: data.sides ?? [],
      cnNums: data.cnNums ?? [],
      invNums: data.invNums ?? []
    };
  } catch (error) {
    throw wrapApolloError(error, 'SudzInvDbtVarCandidates');
  }
}

/** Create/reuse invDbtVar и ciudIdvvKey. */
export async function ensureSudzInvDbtVarForDouble(input: {
  ciudKey: number;
  idvvCnNum: number;
  idvvInvNum: number;
  idvvAccnt: number;
  idvvCnSOrg: number;
}): Promise<SudzCnInvUplInvDbtDouble> {
  try {
    const result = await apolloClient.mutate<{
      ensureSudzInvDbtVarForDouble: SudzCnInvUplInvDbtDouble;
    }>({
      mutation: ENSURE_INV_DBT_VAR_FOR_DOUBLE,
      variables: { input }
    });
    const data = result.data?.ensureSudzInvDbtVarForDouble;
    if (!data) throw new Error('Пустой ответ ensureSudzInvDbtVarForDouble');
    return data;
  } catch (error) {
    throw wrapApolloError(error, 'EnsureSudzInvDbtVarForDouble');
  }
}

/**
 * Привязать строку КСДСФ к существующему договору через ags.cnInv.
 */
export async function linkSudzSfDoubleToCn(
  input: LinkSudzSfDoubleInput
): Promise<SudzCnInvUplSfDouble> {
  try {
    const result = await apolloClient.mutate<{ linkSudzSfDoubleToCn: SudzCnInvUplSfDouble }>({
      mutation: LINK_SF_DOUBLE_TO_CN,
      variables: { input }
    });
    const data = result.data?.linkSudzSfDoubleToCn;
    if (!data) throw new Error('Пустой ответ linkSudzSfDoubleToCn');
    return data;
  } catch (error) {
    throw wrapApolloError(error, 'LinkSudzSfDoubleToCn');
  }
}

/**
 * Upsert шапки CnInvDbtUplFile.
 */
export async function updateSudzDbtUplFile(
  input: UpdateSudzDbtUplFileInput
): Promise<SudzDbtUplFile> {
  try {
    const result = await apolloClient.mutate<{ updateSudzDbtUplFile: SudzDbtUplFile }>({
      mutation: UPDATE_DBT_UPL_FILE,
      variables: { input }
    });
    const data = result.data?.updateSudzDbtUplFile;
    if (!data) throw new Error('Пустой ответ updateSudzDbtUplFile');
    return data;
  } catch (error) {
    throw wrapApolloError(error, 'UpdateSudzDbtUplFile');
  }
}

/**
 * Создаёт лист CnInvDbtUplFileSh.
 */
export async function createSudzDbtUplFileSh(
  input: CreateSudzDbtUplFileShInput
): Promise<SudzDbtUplFileSh> {
  try {
    const result = await apolloClient.mutate<{ createSudzDbtUplFileSh: SudzDbtUplFileSh }>({
      mutation: CREATE_DBT_UPL_FILE_SH,
      variables: { input }
    });
    const data = result.data?.createSudzDbtUplFileSh;
    if (!data) throw new Error('Пустой ответ createSudzDbtUplFileSh');
    return data;
  } catch (error) {
    throw wrapApolloError(error, 'CreateSudzDbtUplFileSh');
  }
}

/**
 * Обновляет лист CnInvDbtUplFileSh.
 */
export async function updateSudzDbtUplFileSh(
  input: UpdateSudzDbtUplFileShInput
): Promise<SudzDbtUplFileSh> {
  try {
    const result = await apolloClient.mutate<{ updateSudzDbtUplFileSh: SudzDbtUplFileSh }>({
      mutation: UPDATE_DBT_UPL_FILE_SH,
      variables: { input }
    });
    const data = result.data?.updateSudzDbtUplFileSh;
    if (!data) throw new Error('Пустой ответ updateSudzDbtUplFileSh');
    return data;
  } catch (error) {
    throw wrapApolloError(error, 'UpdateSudzDbtUplFileSh');
  }
}

/**
 * Удаляет лист CnInvDbtUplFileSh.
 */
export async function deleteSudzDbtUplFileSh(cidufsKey: number): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ deleteSudzDbtUplFileSh: boolean }>({
      mutation: DELETE_DBT_UPL_FILE_SH,
      variables: { cidufsKey }
    });
    return result.data?.deleteSudzDbtUplFileSh ?? false;
  } catch (error) {
    throw wrapApolloError(error, 'DeleteSudzDbtUplFileSh');
  }
}

/**
 * 6 стандартных листов общего свода (если список пуст).
 */
export async function seedSudzDbtUplStandardSheets(uplKey: number): Promise<SudzDbtUplFileSh[]> {
  try {
    const result = await apolloClient.mutate<{ seedSudzDbtUplStandardSheets: SudzDbtUplFileSh[] }>({
      mutation: SEED_DBT_UPL_STANDARD_SHEETS,
      variables: { uplKey }
    });
    return result.data?.seedSudzDbtUplStandardSheets ?? [];
  } catch (error) {
    throw wrapApolloError(error, 'SeedSudzDbtUplStandardSheets');
  }
}

/**
 * Года-портфели, содержащие upl (контекст воронки C2).
 */
export async function getSudzYearKeysForUpl(uplKey: number): Promise<number[]> {
  try {
    const result = await apolloClient.query<{ sudzYearKeysForUpl: number[] }>({
      query: SUDZ_YEAR_KEYS_FOR_UPL,
      variables: { uplKey },
      fetchPolicy: 'network-only'
    });
    return result.data.sudzYearKeysForUpl ?? [];
  } catch (error) {
    throw wrapApolloError(error, 'SudzYearKeysForUpl');
  }
}

/**
 * Stub/реальный прогон воронки (S61f).
 */
export async function runSudzDbtUplFunnel(
  input: RunSudzDbtUplFunnelInput
): Promise<SudzDbtUplFunnelResult> {
  try {
    const result = await apolloClient.mutate<{ runSudzDbtUplFunnel: SudzDbtUplFunnelResult }>({
      mutation: RUN_DBT_UPL_FUNNEL,
      variables: { input }
    });
    const data = result.data?.runSudzDbtUplFunnel;
    if (!data) throw new Error('Пустой ответ runSudzDbtUplFunnel');
    return {
      ...data,
      launcher: {
        ...data.launcher,
        sfDoubles: data.launcher.sfDoubles ?? [],
        invDbtDoubles: data.launcher.invDbtDoubles ?? [],
        dbtP1: data.launcher.dbtP1 ?? []
      }
    };
  } catch (error) {
    throw wrapApolloError(error, 'RunSudzDbtUplFunnel');
  }
}

export async function getSudzCmmGrLookups(): Promise<SudzCmmGrLookup[]> {
  try {
    const result = await apolloClient.query<{ sudzCmmGrLookups: SudzCmmGrLookup[] }>({
      query: SUDZ_CMM_GR_LOOKUPS,
      fetchPolicy: 'network-only'
    });
    return result.data.sudzCmmGrLookups;
  } catch (error) {
    throw wrapApolloError(error, 'SudzCmmGrLookups');
  }
}

export async function getSudzYyyyLookups(): Promise<SudzYyyyLookup[]> {
  try {
    const result = await apolloClient.query<{ sudzYyyyLookups: SudzYyyyLookup[] }>({
      query: SUDZ_YYYY_LOOKUPS,
      fetchPolicy: 'network-only'
    });
    return result.data.sudzYyyyLookups;
  } catch (error) {
    throw wrapApolloError(error, 'SudzYyyyLookups');
  }
}

export async function getSudzPmUplLookups(): Promise<SudzPmUplLookup[]> {
  try {
    const result = await apolloClient.query<{ sudzPmUplLookups: SudzPmUplLookup[] }>({
      query: SUDZ_PM_LOOKUPS,
      fetchPolicy: 'network-only'
    });
    return result.data.sudzPmUplLookups;
  } catch (error) {
    throw wrapApolloError(error, 'SudzPmUplLookups');
  }
}

export async function createSudzYear(input: CreateSudzYearInput): Promise<SudzYearDetail> {
  try {
    const result = await apolloClient.mutate<{ createSudzYear: SudzYearDetail }>({
      mutation: CREATE_YEAR,
      variables: { input }
    });
    const data = result.data?.createSudzYear;
    if (!data) throw new Error('Пустой ответ createSudzYear');
    return data;
  } catch (error) {
    throw wrapApolloError(error, 'CreateSudzYear');
  }
}

export async function updateSudzYear(input: UpdateSudzYearInput): Promise<SudzYearDetail> {
  try {
    const result = await apolloClient.mutate<{ updateSudzYear: SudzYearDetail }>({
      mutation: UPDATE_YEAR,
      variables: { input }
    });
    const data = result.data?.updateSudzYear;
    if (!data) throw new Error('Пустой ответ updateSudzYear');
    return data;
  } catch (error) {
    throw wrapApolloError(error, 'UpdateSudzYear');
  }
}

export async function deleteSudzYear(yrKey: number): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ deleteSudzYear: boolean }>({
      mutation: DELETE_YEAR,
      variables: { yrKey }
    });
    return Boolean(result.data?.deleteSudzYear);
  } catch (error) {
    throw wrapApolloError(error, 'DeleteSudzYear');
  }
}

export async function createSudzCmmGr(input: CreateSudzCmmGrInput): Promise<SudzCmmGrLookup> {
  try {
    const result = await apolloClient.mutate<{ createSudzCmmGr: SudzCmmGrLookup }>({
      mutation: CREATE_CMM_GR,
      variables: { input }
    });
    const data = result.data?.createSudzCmmGr;
    if (!data) throw new Error('Пустой ответ createSudzCmmGr');
    return data;
  } catch (error) {
    throw wrapApolloError(error, 'CreateSudzCmmGr');
  }
}

export async function createSudzUpl(input: CreateSudzUplInput): Promise<SudzUplLookup> {
  try {
    const result = await apolloClient.mutate<{ createSudzUpl: SudzUplLookup }>({
      mutation: CREATE_UPL,
      variables: { input }
    });
    const data = result.data?.createSudzUpl;
    if (!data) throw new Error('Пустой ответ createSudzUpl');
    return data;
  } catch (error) {
    throw wrapApolloError(error, 'CreateSudzUpl');
  }
}

export async function addSudzYearUpl(yrKey: number, uplKey: number): Promise<SudzYearUpl> {
  try {
    const result = await apolloClient.mutate<{ addSudzYearUpl: SudzYearUpl }>({
      mutation: ADD_YEAR_UPL,
      variables: { yrKey, uplKey }
    });
    const data = result.data?.addSudzYearUpl;
    if (!data) throw new Error('Пустой ответ addSudzYearUpl');
    return data;
  } catch (error) {
    throw wrapApolloError(error, 'AddSudzYearUpl');
  }
}

export async function removeSudzYearUpl(yrUplPKey: number): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ removeSudzYearUpl: boolean }>({
      mutation: REMOVE_YEAR_UPL,
      variables: { yrUplPKey }
    });
    return Boolean(result.data?.removeSudzYearUpl);
  } catch (error) {
    throw wrapApolloError(error, 'RemoveSudzYearUpl');
  }
}

export async function createSudzPmUpl(input: CreateSudzPmUplInput): Promise<SudzPmUplLookup> {
  try {
    const result = await apolloClient.mutate<{ createSudzPmUpl: SudzPmUplLookup }>({
      mutation: CREATE_PM,
      variables: { input }
    });
    const data = result.data?.createSudzPmUpl;
    if (!data) throw new Error('Пустой ответ createSudzPmUpl');
    return data;
  } catch (error) {
    throw wrapApolloError(error, 'CreateSudzPmUpl');
  }
}

export async function addSudzPmLink(dbtUplKey: number, pmKey: number): Promise<SudzPmLink> {
  try {
    const result = await apolloClient.mutate<{ addSudzPmLink: SudzPmLink }>({
      mutation: ADD_PM_LINK,
      variables: { dbtUplKey, pmKey }
    });
    const data = result.data?.addSudzPmLink;
    if (!data) throw new Error('Пустой ответ addSudzPmLink');
    return data;
  } catch (error) {
    throw wrapApolloError(error, 'AddSudzPmLink');
  }
}

export async function removeSudzPmLink(gPKey: number): Promise<boolean> {
  try {
    const result = await apolloClient.mutate<{ removeSudzPmLink: boolean }>({
      mutation: REMOVE_PM_LINK,
      variables: { gPKey }
    });
    return Boolean(result.data?.removeSudzPmLink);
  } catch (error) {
    throw wrapApolloError(error, 'RemoveSudzPmLink');
  }
}

export async function getSudzYrDbtChanges(yr: number, asOfUpl?: number | null): Promise<SudzRsltDebt[]> {
  try {
    const result = await apolloClient.query<{ sudzYrDbtChanges: SudzRsltDebt[] }>({
      query: SUDZ_YR_DBT_CHANGES,
      variables: { yr, asOfUpl: asOfUpl ?? null },
      fetchPolicy: 'network-only'
    });
    return result.data.sudzYrDbtChanges;
  } catch (error) {
    throw wrapApolloError(error, 'SudzYrDbtChanges');
  }
}

/**
 * Скачивание Excel Rslt (сбор или повтор). Осознанный REST Blob.
 */
export async function downloadSudzRsltExcel(
  yr: number,
  asOfUpl: number,
  kind: 'sborn' | 'povtor' = 'sborn'
): Promise<{ blob: Blob; fileName: string }> {
  const path = kind === 'povtor' ? 'rslt-povtor.xlsx' : 'rslt-sborn.xlsx';
  const url = `/api/v1/sudz/${path}?yr=${encodeURIComponent(String(yr))}&asOfUpl=${encodeURIComponent(String(asOfUpl))}`;
  const response = await fetch(url);
  if (!response.ok) {
    const text = await response.text();
    throw new RequestError(text || `Ошибка выгрузки Rslt (${response.status})`, {
      status: response.status,
      statusText: response.statusText,
      url: response.url,
      body: text
    });
  }
  const blob = await response.blob();
  const fromHeader = parseContentDispositionFileName(response.headers.get('Content-Disposition'));
  const stamp = (() => {
    const d = new Date();
    const p = (n: number) => String(n).padStart(2, '0');
    return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}_${p(d.getHours())}${p(d.getMinutes())}${p(d.getSeconds())}`;
  })();
  const mid = kind === 'povtor' ? '_povtor_' : '_';
  const timed = `ags_Yr_DbtChangesRslt_${yr}_${asOfUpl}${mid}${stamp}.xlsx`;
  const fileName =
    fromHeader && (/_\d{4}-\d{2}-\d{2}_\d{6}\.xlsx$/i.test(fromHeader) || /_povtor_\d{4}-\d{2}-\d{2}_\d{6}\.xlsx$/i.test(fromHeader))
      ? fromHeader
      : timed;
  return { blob, fileName };
}

/** @deprecated используйте {@link downloadSudzRsltExcel} */
export async function downloadSudzRsltSbornExcel(
  yr: number,
  asOfUpl: number
): Promise<{ blob: Blob; fileName: string }> {
  return downloadSudzRsltExcel(yr, asOfUpl, 'sborn');
}

/**
 * Скачивание Excel D644 (построчный итоговый документ).
 */
export async function downloadSudzD644Excel(
  yr: number,
  currUpl: number
): Promise<{ blob: Blob; fileName: string }> {
  const url = `/api/v1/sudz/d644.xlsx?yr=${encodeURIComponent(String(yr))}&currUpl=${encodeURIComponent(String(currUpl))}`;
  return downloadSudzExcelBlob(url, `ags_Yr_DbtChangesRsltD644_${yr}_${currUpl}`);
}

/**
 * Скачивание Excel годового свода по субсчетам Д644.
 */
export async function downloadSudzD644SvodExcel(
  yr: number,
  currUpl: number
): Promise<{ blob: Blob; fileName: string }> {
  const url = `/api/v1/sudz/d644-svod.xlsx?yr=${encodeURIComponent(String(yr))}&currUpl=${encodeURIComponent(String(currUpl))}`;
  return downloadSudzExcelBlob(url, `ags_Yr_DbtChangesD644Svod_${yr}_${currUpl}`);
}

/**
 * Общая загрузка Blob Excel СУДЗ по URL.
 */
async function downloadSudzExcelBlob(
  url: string,
  namePrefix: string
): Promise<{ blob: Blob; fileName: string }> {
  const response = await fetch(url);
  if (!response.ok) {
    const text = await response.text();
    throw new RequestError(text || `Ошибка выгрузки Excel (${response.status})`, {
      status: response.status,
      statusText: response.statusText,
      url: response.url,
      body: text
    });
  }
  const blob = await response.blob();
  const fromHeader = parseContentDispositionFileName(response.headers.get('Content-Disposition'));
  const stamp = (() => {
    const d = new Date();
    const p = (n: number) => String(n).padStart(2, '0');
    return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}_${p(d.getHours())}${p(d.getMinutes())}${p(d.getSeconds())}`;
  })();
  const timed = `${namePrefix}_${stamp}.xlsx`;
  const fileName =
    fromHeader && /_\d{4}-\d{2}-\d{2}_\d{6}\.xlsx$/i.test(fromHeader) ? fromHeader : timed;
  return { blob, fileName };
}

/**
 * Импорт Excel возврата Rslt → {@code yr_CmmGr_New}. Осознанный REST multipart.
 */
export async function uploadSudzRsltReturn(
  yr: number,
  file: File
): Promise<SudzRsltReturnImportResult> {
  const form = new FormData();
  form.append('file', file);
  const url = `/api/v1/sudz/rslt-return?yr=${encodeURIComponent(String(yr))}`;
  const response = await fetch(url, { method: 'POST', body: form });
  if (!response.ok) {
    const text = await response.text();
    throw new RequestError(text || `Ошибка импорта возврата (${response.status})`, {
      status: response.status,
      statusText: response.statusText,
      url: response.url,
      body: text
    });
  }
  return (await response.json()) as SudzRsltReturnImportResult;
}

/**
 * Извлекает filename из Content-Disposition.
 */
function parseContentDispositionFileName(header: string | null): string | null {
  if (!header) {
    return null;
  }
  const utf = /filename\*=UTF-8''([^;]+)/i.exec(header);
  if (utf?.[1]) {
    try {
      return decodeURIComponent(utf[1].trim());
    } catch {
      return utf[1].trim();
    }
  }
  const plain = /filename="([^"]+)"/i.exec(header) ?? /filename=([^;]+)/i.exec(header);
  return plain?.[1]?.trim() ?? null;
}

const APPEND_PROGRESS = gql`
  mutation AppendSudzYearProgress($yrKey: Int!, $line: String!) {
    appendSudzYearProgress(yrKey: $yrKey, line: $line)
  }
`;

/**
 * Дописывает строку в yr_Progress.
 */
export async function appendSudzYearProgress(yrKey: number, line: string): Promise<string> {
  try {
    const result = await apolloClient.mutate<{ appendSudzYearProgress: string }>({
      mutation: APPEND_PROGRESS,
      variables: { yrKey, line }
    });
    return result.data?.appendSudzYearProgress ?? '';
  } catch (error) {
    throw wrapApolloError(error, 'AppendSudzYearProgress');
  }
}

export async function getSudzD644(yr: number, currUpl: number): Promise<SudzD644Row[]> {
  try {
    const result = await apolloClient.query<{ sudzD644: SudzD644Row[] }>({
      query: SUDZ_D644,
      variables: { yr, currUpl },
      fetchPolicy: 'network-only'
    });
    return result.data.sudzD644;
  } catch (error) {
    throw wrapApolloError(error, 'SudzD644');
  }
}

export async function getSudzD644Svod(yr: number, currUpl: number): Promise<SudzSvodResult> {
  try {
    const result = await apolloClient.query<{ sudzD644Svod: SudzSvodResult }>({
      query: SUDZ_D644_SVOD,
      variables: { yr, currUpl },
      fetchPolicy: 'network-only'
    });
    return result.data.sudzD644Svod;
  } catch (error) {
    throw wrapApolloError(error, 'SudzD644Svod');
  }
}

export async function updateSudzDebtCollection(
  input: SudzDebtCollectionInput
): Promise<SudzDebtCollectionResult> {
  try {
    const result = await apolloClient.mutate<{ updateSudzDebtCollection: SudzDebtCollectionResult }>({
      mutation: UPDATE_SUDZ_DEBT_COLLECTION,
      variables: { input }
    });
    const data = result.data?.updateSudzDebtCollection;
    if (!data) throw new Error('Пустой ответ updateSudzDebtCollection');
    return data;
  } catch (error) {
    throw wrapApolloError(error, 'UpdateSudzDebtCollection');
  }
}
