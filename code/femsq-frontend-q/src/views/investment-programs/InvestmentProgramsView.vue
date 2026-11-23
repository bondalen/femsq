<template>
  <QPage class="investment-programs-view q-pa-md" data-test="investment-programs-view">
    <div class="row items-center q-gutter-md q-mb-md">
      <div>
        <div class="text-h5">Инвестпрограммы</div>
        <div class="text-caption text-grey-7">
          Leaves: шапка ИП · пункты как корни дерева · Structure; Планы/Лимиты — позже (1.3)
        </div>
      </div>
      <QSpace />
      <QBtn
        flat
        round
        icon="refresh"
        :loading="store.loadingPrograms || store.loadingPoints"
        :disable="store.mutating"
        aria-label="Обновить"
        data-test="investment-programs-refresh"
        @click="onRefresh"
      />
    </div>

    <QBanner v-if="store.error" class="bg-negative text-white q-mb-md" rounded>
      {{ store.error }}
    </QBanner>

    <div class="row q-col-gutter-md">
      <!-- Список ИП -->
      <div class="col-12 col-md-3">
        <div class="row q-gutter-sm q-mb-sm items-end">
          <QInput
            v-model.number="yearFilterModel"
            dense
            type="number"
            label="Год"
            clearable
            class="col"
            data-test="investment-programs-year"
            @keyup.enter="onRefresh"
          />
          <QInput
            v-model="store.nameFilter"
            dense
            label="Имя"
            clearable
            class="col"
            data-test="investment-programs-name"
            @keyup.enter="onRefresh"
          />
        </div>
        <div class="row items-center q-mb-sm">
          <div class="text-subtitle2">ИП</div>
          <QSpace />
          <QBtn
            flat
            dense
            no-caps
            icon="add"
            label="Создать"
            :disable="store.mutating"
            data-test="investment-programs-create"
            @click="openCreateProgram"
          />
        </div>
        <QList bordered class="rounded-borders programs-list" data-test="investment-programs-list">
          <QItem
            v-for="p in store.programs"
            :key="p.ipgKey"
            clickable
            :active="p.ipgKey === store.selectedIpgKey"
            @click="onSelectProgram(p.ipgKey)"
          >
            <QItemSection>
              <QItemLabel>{{ p.year ?? '?' }} №{{ p.ipgNum }} · {{ p.ipgNm }}</QItemLabel>
              <QItemLabel caption>
                {{ p.ogName || `og=${p.ipgOg}` }} · {{ p.stNetName || `stNet=${p.ipgStRlSh}` }}
              </QItemLabel>
            </QItemSection>
          </QItem>
          <QItem v-if="!store.loadingPrograms && store.programs.length === 0">
            <QItemSection class="text-grey-7">Нет ИП</QItemSection>
          </QItem>
        </QList>
      </div>

      <!-- Шапка + дерево + detail -->
      <div class="col-12 col-md-9">
        <template v-if="store.selectedProgram">
          <div class="text-subtitle1 q-mb-sm">Шапка ИП {{ store.selectedProgram.ipgKey }}</div>
          <div class="row q-col-gutter-sm q-mb-md">
            <div class="col-12 col-sm-4">
              <QInput v-model="headerForm.ipgNm" dense label="Наименование" :disable="store.mutating" />
            </div>
            <div class="col-6 col-sm-2">
              <QInput
                v-model.number="headerForm.ipgNum"
                dense
                type="number"
                label="№"
                :disable="store.mutating"
              />
            </div>
            <div class="col-6 col-sm-2">
              <QInput
                v-model.number="headerForm.ipgYy"
                dense
                type="number"
                label="yKey (год)"
                :hint="store.selectedProgram.year ? `год ${store.selectedProgram.year}` : undefined"
                :disable="store.mutating"
              />
            </div>
            <div class="col-6 col-sm-2">
              <QInput v-model="headerForm.ipgStr" dense type="date" label="Начало" :disable="store.mutating" />
            </div>
            <div class="col-6 col-sm-2">
              <QInput
                v-model="headerForm.ipgEnd"
                dense
                type="date"
                label="Окончание"
                clearable
                :disable="store.mutating"
              />
            </div>
            <div class="col-12 col-sm-6">
              <QSelect
                v-model="headerForm.ipgStRlSh"
                dense
                emit-value
                map-options
                :options="stNetOptions"
                label="Структура (stNet)"
                :disable="store.mutating"
              />
            </div>
            <div class="col-12 col-sm-6 row items-center q-gutter-sm">
              <QBtn
                color="primary"
                unelevated
                no-caps
                label="Сохранить шапку"
                :loading="store.mutating"
                data-test="investment-programs-save-header"
                @click="onSaveHeader"
              />
            </div>
          </div>

          <div class="row q-col-gutter-md">
            <div class="col-12 col-lg-6">
              <div class="row items-center q-mb-sm">
                <div class="text-subtitle2">Пункты (дерево)</div>
                <QSpace />
                <QBtn
                  flat
                  dense
                  no-caps
                  icon="add"
                  label="Пункт"
                  :disable="store.mutating"
                  data-test="investment-programs-add-point"
                  @click="openCreatePoint"
                />
              </div>
              <QInput
                v-model="store.pointFilter"
                dense
                clearable
                class="q-mb-sm"
                label="Фильтр пунктов"
                data-test="investment-programs-point-filter"
              />
              <div v-if="store.loadingPoints" class="text-grey-7 q-pa-sm">Загрузка пунктов…</div>
              <FemsqTree
                v-else
                class="leaves-tree"
                :nodes="store.treeNodes"
                node-key="key"
                children-key="children"
                leaf-key="leaf"
                expand-on-click
                fill
                v-model:selected-key="selectedKeyModel"
                v-model:expanded-keys="expandedKeys"
                @toggle="onTreeToggle"
                data-test="investment-programs-tree"
              >
                <template #header="{ node }">
                  <span>{{ node.label }}</span>
                  <span v-if="node.kind === 'pn'" class="text-caption text-grey-6 q-ml-sm">
                    ipgp={{ node.ipgpKey }}
                  </span>
                </template>
                <template #empty>Нет пунктов</template>
              </FemsqTree>
            </div>

            <div class="col-12 col-lg-6">
              <div class="text-subtitle2 q-mb-sm">Деталь</div>
              <template v-if="store.selectedPoint">
                <div class="text-caption text-grey-7 q-mb-sm">
                  Пункт ipgpKey={{ store.selectedPoint.ipgpKey }} ·
                  {{ store.selectedPoint.ipgpShName || `sh=${store.selectedPoint.ipgpSh}` }}
                </div>
                <div class="row q-col-gutter-sm">
                  <div class="col-4">
                    <QInput
                      v-model.number="pointForm.ipgpNum"
                      dense
                      type="number"
                      label="№"
                      clearable
                      :disable="store.mutating"
                    />
                  </div>
                  <div class="col-8">
                    <QInput
                      v-model.number="pointForm.ipgpCstAgPn"
                      dense
                      type="number"
                      label="cstAgPn (ключ САК)"
                      :hint="store.selectedPoint.cstAgPnCode || undefined"
                      :disable="store.mutating"
                    />
                  </div>
                  <div class="col-6">
                    <QSelect
                      v-model="pointForm.ipgpSh"
                      dense
                      emit-value
                      map-options
                      :options="shOptions"
                      label="Схема реализации"
                      :disable="store.mutating"
                    />
                  </div>
                  <div class="col-6">
                    <QInput
                      v-model="pointForm.ipgpTskCms"
                      dense
                      label="Комментарий / мощность"
                      :disable="store.mutating"
                    />
                  </div>
                  <div class="col-4">
                    <QInput
                      v-model.number="pointForm.ipgpSmTtl"
                      dense
                      type="number"
                      label="Итого"
                      :disable="store.mutating"
                    />
                  </div>
                  <div class="col-4">
                    <QInput
                      v-model.number="pointForm.ipgpSmWrk"
                      dense
                      type="number"
                      label="СМР"
                      :disable="store.mutating"
                    />
                  </div>
                  <div class="col-4">
                    <QInput
                      v-model.number="pointForm.ipgpSmEqu"
                      dense
                      type="number"
                      label="Оборуд."
                      :disable="store.mutating"
                    />
                  </div>
                </div>
                <div class="row q-gutter-sm q-mt-md">
                  <QBtn
                    color="primary"
                    unelevated
                    no-caps
                    label="Сохранить пункт"
                    :loading="store.mutating"
                    data-test="investment-programs-save-point"
                    @click="onSavePoint"
                  />
                  <QBtn
                    flat
                    no-caps
                    color="negative"
                    label="Удалить"
                    :disable="store.mutating"
                    data-test="investment-programs-delete-point"
                    @click="onDeletePoint"
                  />
                </div>

                <div class="q-mt-lg">
                  <div class="text-subtitle2 q-mb-sm">Привязка к структуре (stiKey)</div>
                  <div class="row q-gutter-sm items-end">
                    <QInput
                      v-model.number="bindStiKey"
                      dense
                      type="number"
                      label="stiKey"
                      class="col"
                      :disable="store.mutating"
                      data-test="investment-programs-sti-key"
                    />
                    <QBtn
                      unelevated
                      no-caps
                      color="primary"
                      label="Добавить"
                      :disable="!bindStiKey || store.mutating"
                      data-test="investment-programs-add-st"
                      @click="onAddBind"
                    />
                  </div>
                  <QList dense bordered class="q-mt-sm rounded-borders">
                    <QItem
                      v-for="b in structureRows"
                      :key="b.ipgspKey"
                    >
                      <QItemSection>
                        <QItemLabel>{{ b.stName || 'узел' }}</QItemLabel>
                        <QItemLabel caption>stiKey={{ b.ipgspSt }} · ipgsp={{ b.ipgspKey }}</QItemLabel>
                      </QItemSection>
                      <QItemSection side>
                        <QBtn
                          flat
                          dense
                          round
                          icon="delete"
                          color="negative"
                          :disable="store.mutating"
                          @click="onRemoveBind(b.ipgspKey)"
                        />
                      </QItemSection>
                    </QItem>
                    <QItem v-if="structureRows.length === 0">
                      <QItemSection class="text-grey-7">Нет привязок</QItemSection>
                    </QItem>
                  </QList>
                </div>
              </template>
              <div v-else class="text-grey-7">Выберите пункт в дереве</div>
            </div>
          </div>
        </template>
        <div v-else class="text-grey-7">Выберите инвестпрограмму слева</div>
      </div>
    </div>

    <!-- Диалог создания ИП -->
    <QDialog v-model="createProgramOpen" persistent>
      <QCard style="min-width: 420px">
        <QCardSection class="text-h6">Новая ИП</QCardSection>
        <QCardSection class="row q-col-gutter-sm">
          <div class="col-12">
            <QInput v-model="createProgramForm.ipgNm" dense label="Наименование" autofocus />
          </div>
          <div class="col-6">
            <QInput v-model.number="createProgramForm.ipgOg" dense type="number" label="ogKey" />
          </div>
          <div class="col-6">
            <QInput v-model.number="createProgramForm.ipgYy" dense type="number" label="yKey (ags.yyyy)" />
          </div>
          <div class="col-6">
            <QInput v-model.number="createProgramForm.ipgNum" dense type="number" label="№" />
          </div>
          <div class="col-6">
            <QSelect
              v-model="createProgramForm.ipgStRlSh"
              dense
              emit-value
              map-options
              :options="stNetOptions"
              label="stNet"
            />
          </div>
          <div class="col-6">
            <QInput v-model="createProgramForm.ipgStr" dense type="date" label="Начало" />
          </div>
          <div class="col-6">
            <QInput v-model="createProgramForm.ipgEnd" dense type="date" label="Окончание" clearable />
          </div>
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat no-caps label="Отмена" v-close-popup :disable="store.mutating" />
          <QBtn color="primary" unelevated no-caps label="Создать" :loading="store.mutating" @click="submitCreateProgram" />
        </QCardActions>
      </QCard>
    </QDialog>

    <!-- Диалог создания пункта -->
    <QDialog v-model="createPointOpen" persistent>
      <QCard style="min-width: 400px">
        <QCardSection class="text-h6">Новый пункт</QCardSection>
        <QCardSection class="row q-col-gutter-sm">
          <div class="col-6">
            <QInput v-model.number="createPointForm.ipgpCstAgPn" dense type="number" label="cstAgPn" autofocus />
          </div>
          <div class="col-6">
            <QSelect
              v-model="createPointForm.ipgpSh"
              dense
              emit-value
              map-options
              :options="shOptions"
              label="Схема"
            />
          </div>
          <div class="col-6">
            <QInput v-model.number="createPointForm.ipgpNum" dense type="number" label="№" clearable />
          </div>
          <div class="col-12">
            <QInput v-model="createPointForm.ipgpTskCms" dense label="Комментарий" />
          </div>
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat no-caps label="Отмена" v-close-popup :disable="store.mutating" />
          <QBtn color="primary" unelevated no-caps label="Создать" :loading="store.mutating" @click="submitCreatePoint" />
        </QCardActions>
      </QCard>
    </QDialog>
  </QPage>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue';
import {
  QBanner,
  QBtn,
  QCard,
  QCardActions,
  QCardSection,
  QDialog,
  QInput,
  QItem,
  QItemLabel,
  QItemSection,
  QList,
  QPage,
  QSelect,
  QSpace,
  useQuasar
} from 'quasar';
import { FemsqTree } from 'fequlib';

import { getStIpgNetworks } from '@/api/st-ipg-structure-api';
import { useIpgLeavesStore } from '@/stores/ipg-leaves';

const store = useIpgLeavesStore();
const $q = useQuasar();

const expandedKeys = ref<string[]>([]);
const bindStiKey = ref<number | null>(null);
const createProgramOpen = ref(false);
const createPointOpen = ref(false);
const stNetOptions = ref<{ label: string; value: number }[]>([]);

const headerForm = reactive({
  ipgNm: '',
  ipgNum: 1,
  ipgYy: 0,
  ipgStr: '',
  ipgEnd: '' as string,
  ipgStRlSh: 0,
  ipgRepl: null as number | null,
  ipgYyYear: null as number | null
});

const pointForm = reactive({
  ipgpNum: null as number | null,
  ipgpCstAgPn: 0,
  ipgpSh: 1,
  ipgpTskCms: '',
  ipgpSmTtl: null as number | null,
  ipgpSmWrk: null as number | null,
  ipgpSmEqu: null as number | null
});

const createProgramForm = reactive({
  ipgNm: '',
  ipgOg: 7,
  ipgYy: 0,
  ipgNum: 1,
  ipgStr: new Date().toISOString().slice(0, 10),
  ipgEnd: '' as string,
  ipgStRlSh: 0
});

const createPointForm = reactive({
  ipgpCstAgPn: 0,
  ipgpSh: 1,
  ipgpNum: null as number | null,
  ipgpTskCms: ''
});

const yearFilterModel = computed({
  get: () => store.yearFilter,
  set: (v: number | null | string) => {
    if (v === '' || v == null) {
      store.yearFilter = null;
      return;
    }
    store.yearFilter = Number(v);
  }
});

const selectedKeyModel = computed({
  get: () => store.selectedTreeKey,
  set: (value: string | number | null) => {
    store.selectTreeNode(value == null ? null : String(value));
  }
});

const shOptions = computed(() =>
  store.schemes.map((s) => ({ label: `${s.ipgsKey} · ${s.ipgsNm}`, value: s.ipgsKey }))
);

const structureRows = computed(() => {
  const key = store.selectedIpgpKey;
  if (key == null) {
    return [];
  }
  return store.structureByPn[key] ? [...store.structureByPn[key]] : [];
});

function syncHeaderForm(): void {
  const p = store.selectedProgram;
  if (!p) {
    return;
  }
  headerForm.ipgNm = p.ipgNm;
  headerForm.ipgNum = p.ipgNum;
  headerForm.ipgYy = p.ipgYy;
  headerForm.ipgStr = (p.ipgStr || '').slice(0, 10);
  headerForm.ipgEnd = p.ipgEnd ? p.ipgEnd.slice(0, 10) : '';
  headerForm.ipgStRlSh = p.ipgStRlSh;
  headerForm.ipgRepl = p.ipgRepl;
  headerForm.ipgYyYear = p.ipgYyYear;
}

function syncPointForm(): void {
  const p = store.selectedPoint;
  if (!p) {
    return;
  }
  pointForm.ipgpNum = p.ipgpNum;
  pointForm.ipgpCstAgPn = p.ipgpCstAgPn;
  pointForm.ipgpSh = p.ipgpSh;
  pointForm.ipgpTskCms = p.ipgpTskCms ?? '';
  pointForm.ipgpSmTtl = p.ipgpSmTtl;
  pointForm.ipgpSmWrk = p.ipgpSmWrk;
  pointForm.ipgpSmEqu = p.ipgpSmEqu;
}

watch(
  () => store.selectedProgram,
  () => syncHeaderForm(),
  { immediate: true }
);

watch(
  () => store.selectedPoint,
  () => syncPointForm()
);

async function loadStNets(): Promise<void> {
  try {
    const nets = await getStIpgNetworks();
    stNetOptions.value = nets.map((n) => ({
      label: `${n.stNetKey} · ${n.name}`,
      value: n.stNetKey
    }));
    if (!createProgramForm.ipgStRlSh && nets.length > 0) {
      createProgramForm.ipgStRlSh = nets[0].stNetKey;
    }
  } catch (err) {
    console.warn('[investment-programs] stNet lookup', err);
  }
}

async function onRefresh(): Promise<void> {
  await store.fetchPrograms(store.selectedIpgKey);
}

async function onSelectProgram(ipgKey: number): Promise<void> {
  await store.selectProgram(ipgKey);
  expandedKeys.value = [];
}

async function onTreeToggle(
  _node: { key: string; ipgpKey?: number; kind?: string },
  key: string | number,
  expanded: boolean
): Promise<void> {
  if (!expanded) {
    return;
  }
  const keyStr = String(key);
  const folder = /^folder:(\d+):struct$/.exec(keyStr);
  const pn = /^pn:(\d+)$/.exec(keyStr);
  const ipgpKey = folder ? Number(folder[1]) : pn ? Number(pn[1]) : null;
  if (ipgpKey != null) {
    await store.ensureStructure(ipgpKey);
  }
}

function openCreateProgram(): void {
  createProgramForm.ipgNm = '';
  createProgramForm.ipgNum = 1;
  if (store.selectedProgram) {
    createProgramForm.ipgOg = store.selectedProgram.ipgOg;
    createProgramForm.ipgYy = store.selectedProgram.ipgYy;
    createProgramForm.ipgStRlSh = store.selectedProgram.ipgStRlSh;
  }
  createProgramOpen.value = true;
}

function openCreatePoint(): void {
  createPointForm.ipgpCstAgPn = 0;
  createPointForm.ipgpNum = null;
  createPointForm.ipgpTskCms = '';
  createPointForm.ipgpSh = store.schemes[0]?.ipgsKey ?? 1;
  createPointOpen.value = true;
}

async function submitCreateProgram(): Promise<void> {
  if (!createProgramForm.ipgNm.trim() || !createProgramForm.ipgOg || !createProgramForm.ipgYy) {
    $q.notify({ type: 'warning', message: 'Заполните наименование, ogKey и yKey' });
    return;
  }
  try {
    await store.createProgram({
      ipgOg: Number(createProgramForm.ipgOg),
      ipgNm: createProgramForm.ipgNm.trim(),
      ipgYy: Number(createProgramForm.ipgYy),
      ipgNum: Number(createProgramForm.ipgNum),
      ipgStr: createProgramForm.ipgStr,
      ipgEnd: createProgramForm.ipgEnd || null,
      ipgStRlSh: Number(createProgramForm.ipgStRlSh)
    });
    createProgramOpen.value = false;
    $q.notify({ type: 'positive', message: 'ИП создана' });
  } catch (err) {
    $q.notify({ type: 'negative', message: err instanceof Error ? err.message : String(err) });
  }
}

async function submitCreatePoint(): Promise<void> {
  if (store.selectedIpgKey == null || !createPointForm.ipgpCstAgPn) {
    $q.notify({ type: 'warning', message: 'Нужны ИП и cstAgPn' });
    return;
  }
  try {
    await store.createPoint({
      ipgpIpg: store.selectedIpgKey,
      ipgpCstAgPn: Number(createPointForm.ipgpCstAgPn),
      ipgpSh: Number(createPointForm.ipgpSh),
      ipgpNum: createPointForm.ipgpNum,
      ipgpTskCms: createPointForm.ipgpTskCms || null
    });
    createPointOpen.value = false;
    $q.notify({ type: 'positive', message: 'Пункт создан' });
  } catch (err) {
    $q.notify({ type: 'negative', message: err instanceof Error ? err.message : String(err) });
  }
}

async function onSaveHeader(): Promise<void> {
  if (store.selectedIpgKey == null) {
    return;
  }
  try {
    await store.saveProgram(store.selectedIpgKey, {
      ipgNm: headerForm.ipgNm.trim(),
      ipgYy: Number(headerForm.ipgYy),
      ipgNum: Number(headerForm.ipgNum),
      ipgStr: headerForm.ipgStr,
      ipgEnd: headerForm.ipgEnd || null,
      ipgRepl: headerForm.ipgRepl,
      ipgStRlSh: Number(headerForm.ipgStRlSh),
      ipgYyYear: headerForm.ipgYyYear
    });
    $q.notify({ type: 'positive', message: 'Шапка сохранена' });
  } catch (err) {
    $q.notify({ type: 'negative', message: err instanceof Error ? err.message : String(err) });
  }
}

async function onSavePoint(): Promise<void> {
  if (store.selectedIpgpKey == null) {
    return;
  }
  try {
    await store.savePoint(store.selectedIpgpKey, {
      ipgpNum: pointForm.ipgpNum,
      ipgpCstAgPn: Number(pointForm.ipgpCstAgPn),
      ipgpSh: Number(pointForm.ipgpSh),
      ipgpTskCms: pointForm.ipgpTskCms || null,
      ipgpSmTtl: pointForm.ipgpSmTtl,
      ipgpSmWrk: pointForm.ipgpSmWrk,
      ipgpSmEqu: pointForm.ipgpSmEqu
    });
    $q.notify({ type: 'positive', message: 'Пункт сохранён' });
  } catch (err) {
    $q.notify({ type: 'negative', message: err instanceof Error ? err.message : String(err) });
  }
}

function onDeletePoint(): void {
  if (store.selectedIpgpKey == null) {
    return;
  }
  const id = store.selectedIpgpKey;
  $q.dialog({
    title: 'Удалить пункт?',
    message: 'Запрещено при UtPl/Lim. Привязки Structure будут удалены.',
    cancel: true,
    persistent: true
  }).onOk(async () => {
    try {
      await store.removePoint(id);
      $q.notify({ type: 'positive', message: 'Пункт удалён' });
    } catch (err) {
      $q.notify({ type: 'negative', message: err instanceof Error ? err.message : String(err) });
    }
  });
}

async function onAddBind(): Promise<void> {
  if (store.selectedIpgpKey == null || !bindStiKey.value) {
    return;
  }
  try {
    await store.addStructureBind(store.selectedIpgpKey, Number(bindStiKey.value));
    bindStiKey.value = null;
    $q.notify({ type: 'positive', message: 'Привязка добавлена' });
  } catch (err) {
    $q.notify({ type: 'negative', message: err instanceof Error ? err.message : String(err) });
  }
}

async function onRemoveBind(ipgspKey: number): Promise<void> {
  if (store.selectedIpgpKey == null) {
    return;
  }
  try {
    await store.removeStructureBind(ipgspKey, store.selectedIpgpKey);
    $q.notify({ type: 'positive', message: 'Привязка удалена' });
  } catch (err) {
    $q.notify({ type: 'negative', message: err instanceof Error ? err.message : String(err) });
  }
}

onMounted(async () => {
  await Promise.all([store.loadSchemes(), loadStNets()]);
  await store.fetchPrograms();
});
</script>

<style scoped>
.programs-list {
  max-height: 70vh;
  overflow: auto;
}
.leaves-tree {
  min-height: 360px;
  max-height: 70vh;
  border: 1px solid rgba(0, 0, 0, 0.12);
  border-radius: 4px;
  padding: 8px;
}
</style>
