/**
 * Store экрана «Договоры» (master cnNum + detail cn + дерево сторон).
 */

import { computed, ref } from 'vue';
import { defineStore } from 'pinia';

import {
  createCnContract,
  createCnSide,
  createCnSOrg,
  createCnSOrgSmpl,
  deleteCnSide,
  deleteCnSOrg,
  deleteCnSOrgSmpl,
  fetchCn,
  fetchCnNums,
  fetchCnNumsByCn,
  fetchCnNumDuplicateCount,
  fetchCnNumTypes,
  fetchCnSides,
  fetchCnSOrgIdLookups,
  updateCn,
  updateCnSide,
  updateCnSOrg,
  updateCnSOrgSmpl
} from '@/api/contracts-api';
import { RequestError } from '@/api/http';
import type {
  CnContractCreateRequest,
  CnContractCreatedDto,
  CnDto,
  CnNumDto,
  CnNumTypeLookupDto,
  CnSideCreateRequest,
  CnSideDto,
  CnSideUpdateRequest,
  CnSOrgCreateRequest,
  CnSOrgIdLookupDto,
  CnSOrgSmplCreateRequest,
  CnSOrgSmplUpdateRequest,
  CnSOrgUpdateRequest,
  CnUpdateRequest
} from '@/types/contracts';

const ROLE_CATALOG: { cnSType: number; cnSTypeName: string }[] = [
  { cnSType: 1, cnSTypeName: 'заказчик' },
  { cnSType: 2, cnSTypeName: 'исполнитель' }
];

export const useContractsStore = defineStore('contracts', () => {
  const cnNums = ref<CnNumDto[]>([]);
  const selectedCnnKey = ref<number | null>(null);
  const selectedCn = ref<CnDto | null>(null);
  const cnNumsForCn = ref<CnNumDto[]>([]);
  const sides = ref<CnSideDto[]>([]);
  const orgIdLookups = ref<CnSOrgIdLookupDto[]>([]);
  const numTypes = ref<CnNumTypeLookupDto[]>([]);
  const expandedSides = ref<Set<number>>(new Set());
  const expandedSmpls = ref<Set<number>>(new Set());
  const loadingList = ref(false);
  const loadingDetail = ref(false);
  const loadingSides = ref(false);
  const saving = ref(false);
  const error = ref<string | null>(null);

  const selectedCnNum = computed(
    () => cnNums.value.find((row) => row.cnnKey === selectedCnnKey.value) ?? null
  );

  /**
   * Роли заказчик/исполнитель всегда на экране; отсутствующие — «виртуальные».
   */
  const displaySides = computed(() => {
    const cnKey = selectedCn.value?.cnKey ?? null;
    return ROLE_CATALOG.map((role) => {
      const existing = sides.value.find((side) => side.cnSType === role.cnSType);
      if (existing) {
        return { ...existing, virtual: false as const };
      }
      return {
        cnSKey: null as number | null,
        cnKey: cnKey ?? 0,
        cnSType: role.cnSType,
        cnSTypeName: role.cnSTypeName,
        smpls: [] as CnSideDto['smpls'],
        virtual: true as const
      };
    });
  });

  /**
   * Загружает master-список номеров.
   */
  async function loadCnNums(): Promise<void> {
    loadingList.value = true;
    error.value = null;
    try {
      cnNums.value = await fetchCnNums();
      if (selectedCnnKey.value != null) {
        const stillThere = cnNums.value.some((row) => row.cnnKey === selectedCnnKey.value);
        if (!stillThere) {
          selectedCnnKey.value = null;
          selectedCn.value = null;
          cnNumsForCn.value = [];
          sides.value = [];
        }
      }
      if (selectedCnnKey.value == null && cnNums.value.length > 0) {
        await selectCnNum(cnNums.value[0].cnnKey);
      }
    } catch (err) {
      error.value = err instanceof RequestError ? err.message : 'Ошибка загрузки номеров';
      cnNums.value = [];
    } finally {
      loadingList.value = false;
    }
  }

  /**
   * Выбор номера в master → загрузка договора, номеров и сторон.
   */
  async function selectCnNum(cnnKey: number): Promise<void> {
    selectedCnnKey.value = cnnKey;
    const row = cnNums.value.find((item) => item.cnnKey === cnnKey);
    if (!row) {
      selectedCn.value = null;
      cnNumsForCn.value = [];
      sides.value = [];
      return;
    }
    loadingDetail.value = true;
    error.value = null;
    try {
      const [cn, nums] = await Promise.all([fetchCn(row.cnnCn), fetchCnNumsByCn(row.cnnCn)]);
      selectedCn.value = cn;
      cnNumsForCn.value = nums;
      await loadSides(row.cnnCn);
    } catch (err) {
      error.value = err instanceof RequestError ? err.message : 'Ошибка загрузки договора';
      selectedCn.value = null;
      cnNumsForCn.value = [];
      sides.value = [];
    } finally {
      loadingDetail.value = false;
    }
  }

  /**
   * Загружает дерево сторон для договора.
   */
  async function loadSides(cnKey: number): Promise<void> {
    loadingSides.value = true;
    try {
      sides.value = await fetchCnSides(cnKey);
      expandedSides.value = new Set(sides.value.map((side) => side.cnSKey));
      expandedSmpls.value = new Set(
        sides.value.flatMap((side) => side.smpls.map((smpl) => smpl.csosKey))
      );
    } catch (err) {
      error.value = err instanceof RequestError ? err.message : 'Ошибка загрузки сторон';
      sides.value = [];
    } finally {
      loadingSides.value = false;
    }
  }

  /**
   * Lookup org_id (лениво, один раз).
   */
  async function ensureOrgIdLookups(): Promise<void> {
    if (orgIdLookups.value.length > 0) {
      return;
    }
    orgIdLookups.value = await fetchCnSOrgIdLookups();
  }

  /**
   * Справочник типов номера (лениво).
   */
  async function ensureNumTypes(): Promise<void> {
    if (numTypes.value.length > 0) {
      return;
    }
    numTypes.value = await fetchCnNumTypes();
  }

  /**
   * Число коллизий номера (решение — за оператором, не блокируем).
   */
  async function duplicateCount(cnnNum: string): Promise<number> {
    return fetchCnNumDuplicateCount(cnnNum);
  }

  /**
   * Создаёт новый договор с исполнителем и выбирает его в master.
   */
  async function createContract(input: CnContractCreateRequest): Promise<CnContractCreatedDto> {
    saving.value = true;
    error.value = null;
    try {
      const created = await createCnContract(input);
      await loadCnNums();
      await selectCnNum(created.cnnKey);
      return created;
    } catch (err) {
      error.value = err instanceof RequestError ? err.message : 'Ошибка создания договора';
      throw err;
    } finally {
      saving.value = false;
    }
  }

  /**
   * Обновляет карточку cn ({@code cn_date} и пр.) и обновляет selectedCn.
   */
  async function saveCn(input: CnUpdateRequest): Promise<void> {
    const cnKey = selectedCn.value?.cnKey;
    if (cnKey == null) {
      throw new Error('Договор не выбран');
    }
    saving.value = true;
    error.value = null;
    try {
      selectedCn.value = await updateCn(cnKey, input);
    } catch (err) {
      error.value = err instanceof RequestError ? err.message : 'Ошибка сохранения договора';
      throw err;
    } finally {
      saving.value = false;
    }
  }

  function isSideExpanded(cnSKey: number): boolean {
    return expandedSides.value.has(cnSKey);
  }

  function toggleSide(cnSKey: number): void {
    const next = new Set(expandedSides.value);
    if (next.has(cnSKey)) {
      next.delete(cnSKey);
    } else {
      next.add(cnSKey);
    }
    expandedSides.value = next;
  }

  function isSmplExpanded(csosKey: number): boolean {
    return expandedSmpls.value.has(csosKey);
  }

  function toggleSmpl(csosKey: number): void {
    const next = new Set(expandedSmpls.value);
    if (next.has(csosKey)) {
      next.delete(csosKey);
    } else {
      next.add(csosKey);
    }
    expandedSmpls.value = next;
  }

  async function reloadCurrentSides(): Promise<void> {
    const cnKey = selectedCn.value?.cnKey;
    if (cnKey != null) {
      await loadSides(cnKey);
    }
  }

  async function saveSide(input: CnSideCreateRequest, id?: number): Promise<void> {
    saving.value = true;
    error.value = null;
    try {
      if (id == null) {
        await createCnSide(input);
      } else {
        const update: CnSideUpdateRequest = input;
        await updateCnSide(id, update);
      }
      await reloadCurrentSides();
    } catch (err) {
      error.value = err instanceof RequestError ? err.message : 'Ошибка сохранения стороны';
      throw err;
    } finally {
      saving.value = false;
    }
  }

  async function removeSide(id: number): Promise<void> {
    saving.value = true;
    error.value = null;
    try {
      await deleteCnSide(id);
      await reloadCurrentSides();
    } catch (err) {
      error.value = err instanceof RequestError ? err.message : 'Ошибка удаления стороны';
      throw err;
    } finally {
      saving.value = false;
    }
  }

  async function saveSmpl(input: CnSOrgSmplCreateRequest, id?: number): Promise<void> {
    saving.value = true;
    error.value = null;
    try {
      if (id == null) {
        await createCnSOrgSmpl(input);
      } else {
        const update: CnSOrgSmplUpdateRequest = input;
        await updateCnSOrgSmpl(id, update);
      }
      await reloadCurrentSides();
    } catch (err) {
      error.value = err instanceof RequestError ? err.message : 'Ошибка сохранения smpl';
      throw err;
    } finally {
      saving.value = false;
    }
  }

  async function removeSmpl(id: number): Promise<void> {
    saving.value = true;
    error.value = null;
    try {
      await deleteCnSOrgSmpl(id);
      await reloadCurrentSides();
    } catch (err) {
      error.value = err instanceof RequestError ? err.message : 'Ошибка удаления smpl';
      throw err;
    } finally {
      saving.value = false;
    }
  }

  async function saveOrg(input: CnSOrgCreateRequest, id?: number): Promise<void> {
    saving.value = true;
    error.value = null;
    try {
      if (id == null) {
        await createCnSOrg(input);
      } else {
        const update: CnSOrgUpdateRequest = {
          csoCnSOrgSmpl: input.csoCnSOrgSmpl,
          dateBeg: input.dateBeg,
          dateEnd: input.dateEnd,
          csoAsbuId: input.csoAsbuId,
          csoCnDate: input.csoCnDate
        };
        await updateCnSOrg(id, update);
      }
      await reloadCurrentSides();
    } catch (err) {
      error.value = err instanceof RequestError ? err.message : 'Ошибка сохранения org';
      throw err;
    } finally {
      saving.value = false;
    }
  }

  async function removeOrg(id: number): Promise<void> {
    saving.value = true;
    error.value = null;
    try {
      await deleteCnSOrg(id);
      await reloadCurrentSides();
    } catch (err) {
      error.value = err instanceof RequestError ? err.message : 'Ошибка удаления org';
      throw err;
    } finally {
      saving.value = false;
    }
  }

  return {
    cnNums,
    selectedCnnKey,
    selectedCnNum,
    selectedCn,
    cnNumsForCn,
    sides,
    displaySides,
    orgIdLookups,
    numTypes,
    loadingList,
    loadingDetail,
    loadingSides,
    saving,
    error,
    loadCnNums,
    selectCnNum,
    loadSides,
    ensureOrgIdLookups,
    ensureNumTypes,
    duplicateCount,
    createContract,
    saveCn,
    isSideExpanded,
    toggleSide,
    isSmplExpanded,
    toggleSmpl,
    saveSide,
    removeSide,
    saveSmpl,
    removeSmpl,
    saveOrg,
    removeOrg
  };
});
