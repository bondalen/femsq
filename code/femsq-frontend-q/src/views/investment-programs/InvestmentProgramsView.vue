<template>
  <QPage class="investment-programs-view q-pa-none" data-test="investment-programs-view">
    <div class="absolute-full q-px-md q-pt-sm q-pb-sm column no-wrap investment-programs-inner">
      <div class="row items-center q-gutter-sm q-mb-xs shrink-0 no-wrap">
        <div class="text-subtitle1 text-weight-medium ellipsis">Инвестпрограммы</div>
        <QInput
          v-model.number="yearFilterModel"
          dense
          outlined
          type="number"
          label="Год"
          clearable
          class="investment-programs-filter-year"
          data-test="investment-programs-year"
          @keyup.enter="onRefresh"
        />
        <QInput
          v-model="store.nameFilter"
          dense
          outlined
          label="Имя"
          clearable
          class="investment-programs-filter-name"
          data-test="investment-programs-name"
          @keyup.enter="onRefresh"
        />
        <QSpace />
        <QBtn
          flat
          dense
          round
          icon="refresh"
          :loading="store.loadingPrograms || store.loadingPoints"
          :disable="store.mutating"
          aria-label="Обновить"
          data-test="investment-programs-refresh"
          @click="onRefresh"
        />
      </div>

      <QBanner v-if="store.error" class="bg-negative text-white q-mb-xs shrink-0" rounded>
        {{ store.error }}
      </QBanner>

      <FemsqCardStrip
        class="q-mb-xs shrink-0"
        :items="store.programs"
        item-key="ipgKey"
        :selected-key="store.selectedIpgKey"
        :loading="store.loadingPrograms"
        :disabled="store.mutating"
        dense
        test-id-prefix="investment-programs-card"
        data-test="investment-programs-strip"
        @update:selected-key="onSelectNetworkKey"
      >
        <template #item="{ item }">
          <div class="text-weight-medium">
            {{ item.year ?? '?' }} №{{ item.ipgNum }} · {{ item.ipgNm }}
          </div>
          <div class="text-caption investment-programs-muted">
            {{ item.ogName || `og=${item.ipgOg}` }} · {{ item.stNetName || `stNet=${item.ipgStRlSh}` }}
          </div>
        </template>
        <template #empty>Нет ИП — измените фильтр или создайте</template>
        <template #trailing>
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
        </template>
      </FemsqCardStrip>

      <template v-if="store.selectedProgram">
        <QTabs
          v-model="mainTab"
          dense
          class="text-primary shrink-0"
          data-test="investment-programs-tabs"
        >
          <QTab name="general" label="Общее" data-test="investment-programs-tab-general" />
          <QTab name="points" label="Пункты" data-test="investment-programs-tab-points" />
          <QTab
            name="load-points"
            label="Загрузка пунктов"
            data-test="investment-programs-tab-load-points"
          />
          <QTab
            name="plan-groups"
            label="Группы планов"
            data-test="investment-programs-tab-plan-groups"
          />
          <QTab name="plans" label="Планы" data-test="investment-programs-tab-plans" />
          <QTab
            name="load-utpl"
            label="Загрузка ут. планов"
            data-test="investment-programs-tab-load-utpl"
          />
        </QTabs>

        <QTabPanels v-model="mainTab" animated class="bg-transparent col investment-programs-panels">
          <!-- Общее: шапка ИП -->
          <QTabPanel name="general" class="q-pa-none column fill-pane">
            <div class="text-subtitle2 q-mb-sm">
              Шапка ИП {{ store.selectedProgram.ipgKey }}
            </div>
            <div class="row q-col-gutter-sm">
              <div class="col-12 col-sm-4">
                <QInput
                  v-model="headerForm.ipgNm"
                  dense
                  outlined
                  label="Наименование"
                  :disable="store.mutating"
                />
              </div>
              <div class="col-6 col-sm-2">
                <QInput
                  v-model.number="headerForm.ipgNum"
                  dense
                  outlined
                  type="number"
                  label="№"
                  :disable="store.mutating"
                />
              </div>
              <div class="col-6 col-sm-2">
                <QInput
                  v-model.number="headerForm.ipgYy"
                  dense
                  outlined
                  type="number"
                  label="yKey (год)"
                  :hint="store.selectedProgram.year ? `год ${store.selectedProgram.year}` : undefined"
                  :disable="store.mutating"
                />
              </div>
              <div class="col-6 col-sm-2">
                <QInput
                  v-model="headerForm.ipgStr"
                  dense
                  outlined
                  type="date"
                  label="Начало"
                  :disable="store.mutating"
                />
              </div>
              <div class="col-6 col-sm-2">
                <QInput
                  v-model="headerForm.ipgEnd"
                  dense
                  outlined
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
                  outlined
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
          </QTabPanel>

          <!-- Пункты: FemsqTreeList + контекстная панель (§3.2.8.4) -->
          <QTabPanel name="points" class="q-pa-none column fill-pane" data-test="investment-programs-points-panel">
            <div v-if="store.loadingPoints" class="text-grey-7 q-pa-sm col">Загрузка пунктов…</div>
            <FemsqTreeList
              v-else
              class="leaves-tree col"
              title="Пункты"
              :nodes="store.treeNodes"
              node-key="key"
              children-key="children"
              leaf-key="leaf"
              header-level="pn"
              :column-sets="leavesColumnSets"
              expand-on-click
              fill
              filter-mode="roots"
              v-model:filter="pointFilterModel"
              v-model:column-filters="pointColumnFilters"
              v-model:filters-visible="pointFiltersVisible"
              v-model:selected-key="selectedKeyModel"
              v-model:expanded-keys="expandedKeys"
              @toggle="onTreeToggle"
              data-test="investment-programs-tree"
            >
              <template #actions>
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
              </template>
              <template #empty>Нет пунктов</template>
            </FemsqTreeList>

            <div
              v-if="showPointContext"
              class="investment-programs-context q-mt-xs shrink-0"
              data-test="investment-programs-point-context"
            >
              <div class="row items-center q-mb-xs">
                <div class="text-subtitle2">
                  Пункт ipgpKey={{ store.selectedPoint?.ipgpKey }}
                </div>
                <QSpace />
                <QBtn
                  color="primary"
                  unelevated
                  dense
                  no-caps
                  label="Сохранить"
                  :loading="store.mutating"
                  data-test="investment-programs-save-point"
                  @click="onSavePoint"
                />
                <QBtn
                  flat
                  dense
                  no-caps
                  color="negative"
                  label="Удалить"
                  :disable="store.mutating"
                  data-test="investment-programs-delete-point"
                  @click="onDeletePoint"
                />
                <QBtn
                  flat
                  dense
                  round
                  icon="close"
                  aria-label="Снять выбор"
                  data-test="investment-programs-context-close"
                  @click="clearTreeSelection"
                />
              </div>
              <!-- Как Access ipgMin: код / стройка / агент — раздельно; суммы полного набора -->
              <div class="row q-col-gutter-sm">
                <div class="col-3 col-sm-1">
                  <QInput
                    v-model.number="pointForm.ipgpNum"
                    dense
                    outlined
                    type="number"
                    label="№"
                    clearable
                    :disable="store.mutating"
                  />
                </div>
                <div class="col-9 col-sm-2">
                  <QInput
                    :model-value="store.selectedPoint?.cstAgPnCode || ''"
                    dense
                    outlined
                    readonly
                    label="Код"
                    data-test="investment-programs-cst-code"
                  />
                </div>
                <div class="col-12 col-sm-5">
                  <QInput
                    :model-value="store.selectedPoint?.cstAgPnCstName || ''"
                    dense
                    outlined
                    readonly
                    label="Наименование стройки"
                    data-test="investment-programs-cst-name"
                  />
                </div>
                <div class="col-12 col-sm-4">
                  <QInput
                    :model-value="store.selectedPoint?.cstAgPnOgName || ''"
                    dense
                    outlined
                    readonly
                    label="Агент"
                    data-test="investment-programs-cst-agent"
                  />
                </div>
                <div class="col-6 col-sm-2">
                  <QInput
                    v-model.number="pointForm.ipgpCstAgPn"
                    dense
                    outlined
                    type="number"
                    label="cstAgPn (ключ)"
                    :disable="store.mutating"
                  />
                </div>
                <div class="col-6 col-sm-3">
                  <QSelect
                    v-model="pointForm.ipgpSh"
                    dense
                    outlined
                    emit-value
                    map-options
                    :options="shOptions"
                    label="Схема (ipgpSh)"
                    :disable="store.mutating"
                  />
                </div>
                <div class="col-12 col-sm-7">
                  <QInput
                    v-model="pointForm.ipgpTskCms"
                    dense
                    outlined
                    label="Комментарий / мощность (ipgpTskCms)"
                    :disable="store.mutating"
                  />
                </div>
                <div class="col-4 col-sm-2">
                  <QInput
                    v-model.number="pointForm.ipgpSmTtl"
                    dense
                    outlined
                    type="number"
                    label="Итого"
                    :disable="store.mutating"
                  />
                </div>
                <div class="col-4 col-sm-2">
                  <QInput
                    v-model.number="pointForm.ipgpSmWrk"
                    dense
                    outlined
                    type="number"
                    label="СМР"
                    :disable="store.mutating"
                  />
                </div>
                <div class="col-4 col-sm-2">
                  <QInput
                    v-model.number="pointForm.ipgpSmEqu"
                    dense
                    outlined
                    type="number"
                    label="Оборуд."
                    :disable="store.mutating"
                  />
                </div>
                <div class="col-4 col-sm-2">
                  <QInput
                    v-model.number="pointForm.ipgpSmOth"
                    dense
                    outlined
                    type="number"
                    label="Прочее"
                    :disable="store.mutating"
                  />
                </div>
                <div class="col-4 col-sm-2">
                  <QInput
                    v-model.number="pointForm.ipgpSmAgFee"
                    dense
                    outlined
                    type="number"
                    label="Аг.вознагр."
                    :disable="store.mutating"
                  />
                </div>
                <div class="col-4 col-sm-2">
                  <QInput
                    v-model.number="pointForm.ipgpCostAdjust"
                    dense
                    outlined
                    type="number"
                    label="Корр.стоим."
                    :disable="store.mutating"
                  />
                </div>
                <div class="col-4 col-sm-2">
                  <QInput
                    v-model.number="pointForm.ipgpSmReserv"
                    dense
                    outlined
                    type="number"
                    label="Резерв"
                    :disable="store.mutating"
                  />
                </div>
              </div>
              <div class="row q-col-gutter-sm items-end q-mt-xs">
                <div class="col-12 col-md-6">
                  <div class="text-caption investment-programs-muted q-mb-xs">
                    Привязка к структуре (ipgStPn → stiKey)
                  </div>
                  <div class="row q-gutter-sm items-end">
                    <QInput
                      v-model.number="bindStiKey"
                      dense
                      outlined
                      type="number"
                      label="stiKey"
                      class="col"
                      :disable="store.mutating"
                      data-test="investment-programs-sti-key"
                    />
                    <QBtn
                      unelevated
                      dense
                      no-caps
                      color="primary"
                      label="Добавить"
                      :disable="!bindStiKey || store.mutating"
                      data-test="investment-programs-add-st"
                      @click="onAddBind"
                    />
                  </div>
                </div>
                <div class="col-12 col-md-6">
                  <QList dense bordered class="rounded-borders investment-programs-bind-list">
                    <QItem v-for="b in structureRows" :key="b.ipgspKey">
                      <QItemSection>
                        <QItemLabel>{{ b.stName || 'узел' }}</QItemLabel>
                        <QItemLabel caption>sti={{ b.ipgspSt }} · ipgsp={{ b.ipgspKey }}</QItemLabel>
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
                      <QItemSection class="investment-programs-muted">Нет привязок</QItemSection>
                    </QItem>
                  </QList>
                </div>
              </div>
            </div>

            <div
              v-else-if="selectedBind"
              class="investment-programs-context q-mt-xs shrink-0"
              data-test="investment-programs-bind-context"
            >
              <div class="row items-center">
                <div class="text-subtitle2">
                  Привязка sti={{ selectedBind.stiKey }} · {{ selectedBind.label }}
                </div>
                <QSpace />
                <QBtn
                  flat
                  dense
                  no-caps
                  color="negative"
                  label="Удалить привязку"
                  :disable="store.mutating || selectedBind.ipgspKey == null"
                  data-test="investment-programs-remove-st"
                  @click="selectedBind.ipgspKey != null && onRemoveBind(selectedBind.ipgspKey)"
                />
                <QBtn
                  flat
                  dense
                  round
                  icon="close"
                  aria-label="Снять выбор"
                  @click="clearTreeSelection"
                />
              </div>
            </div>
          </QTabPanel>

          <!-- Загрузка пунктов: apply из staging (§3.2.8.3); детали ошибок — только в «Ход загрузки» (§3.5.6) -->
          <QTabPanel
            name="load-points"
            class="q-pa-md column fill-pane no-wrap"
            data-test="investment-programs-load-points-panel"
          >
            <div class="text-subtitle2 shrink-0">Загрузка пунктов</div>
            <div class="investment-programs-muted text-caption q-mb-sm shrink-0">
              Разбор Excel и сверка ПТСФ — на экране «Структура ИПГ». Здесь — apply листьев staging → пункты
              ИП <strong>{{ store.selectedProgram.ipgKey }}</strong>
              · {{ store.selectedProgram.ipgNm }}.
            </div>
            <!-- Фикс. toolbar: одна строка, без hint-прыжка (§3.5.6 A) -->
            <div
              class="row items-center q-col-gutter-sm no-wrap shrink-0 q-mb-xs investment-programs-load-toolbar"
              data-test="investment-programs-load-toolbar"
            >
              <div class="col">
                <QSelect
                  v-model="loadModel"
                  dense
                  outlined
                  emit-value
                  map-options
                  clearable
                  label="Сессия load"
                  :options="loadSelectOptions"
                  :loading="store.loadingLoads"
                  data-test="investment-programs-load"
                />
              </div>
              <div class="col-auto investment-programs-prev-ipg">
                <QInput
                  v-model="previousIpgModel"
                  dense
                  outlined
                  type="number"
                  clearable
                  label="prev ИП (ipgpSh)"
                  data-test="investment-programs-previous-ipg"
                >
                  <QTooltip>Пусто → схема 4 (неопределённая). Иначе ipgpSh из prev ИП.</QTooltip>
                </QInput>
              </div>
              <div class="col-auto row no-wrap q-gutter-xs items-center">
                <QBtn
                  outline
                  color="secondary"
                  no-caps
                  label="Проверить"
                  :loading="store.applyingPoints"
                  :disable="!canApplyPoints || store.mutating"
                  data-test="investment-programs-apply-points-dry"
                  @click="onApplyPointsDryRun"
                />
                <QBtn
                  unelevated
                  color="secondary"
                  no-caps
                  label="Загрузить пункты"
                  :loading="store.applyingPoints"
                  :disable="!canApplyPoints || store.mutating"
                  data-test="investment-programs-apply-points"
                  @click="onApplyPoints"
                />
              </div>
            </div>
            <div
              class="text-caption investment-programs-muted ellipsis shrink-0 investment-programs-load-meta"
              data-test="investment-programs-load-meta"
            >
              <template v-if="store.selectedLoad">
                load={{ store.selectedLoad.id }}
                · файл {{ store.selectedLoad.filePath || '—' }}
                · {{ store.selectedLoad.name }}
              </template>
              <template v-else>Выберите сессию load</template>
            </div>
            <div
              class="text-caption shrink-0 ellipsis investment-programs-apply-summary"
              :class="applyLogToneClass"
              data-test="investment-programs-apply-summary"
            >
              <template v-if="store.applyResult">
                Пункты ({{ store.applyResult.dryRun ? 'проверка' : 'запись' }}):
                листьев {{ store.applyResult.leafCount }}
                · применено {{ store.applyResult.appliedCount }}
                · уже было {{ store.applyResult.skippedAlreadyCount ?? 0 }}
                · ошибок {{ store.applyResult.errors.length }}
                · ready={{ store.applyResult.ready }}
              </template>
              <template v-else>&nbsp;</template>
            </div>
            <div
              class="col column no-wrap q-mt-xs investment-programs-load-log-wrap"
              data-test="investment-programs-load-log"
            >
              <div class="text-subtitle2 q-mb-xs shrink-0">Ход загрузки</div>
              <div class="col scroll investment-programs-load-log">
                <div class="audit-log-surface">
                  <div
                    v-if="store.loadLogHtml"
                    class="audit-log-html"
                    v-html="store.loadLogHtml"
                  />
                  <div v-else class="audit-log-empty text-body2">
                    Журнал загрузки появится после «Проверить» / «Загрузить» (и разбора на Structure).
                  </div>
                </div>
              </div>
            </div>
          </QTabPanel>

          <QTabPanel name="plan-groups" class="q-pa-md">
            <div class="text-subtitle2 q-mb-sm">Группы планов</div>
            <div class="investment-programs-muted">{{ STUB_O2 }}</div>
          </QTabPanel>

          <QTabPanel name="plans" class="q-pa-md column q-gutter-sm" data-test="investment-programs-plans-panel">
            <div class="row items-center q-gutter-sm">
              <div class="text-subtitle2">Планы (UtPl @ stCost)</div>
              <QSpace />
              <QBadge
                v-if="utPlStore.grid"
                :color="utPlStore.grid.gAggOk ? 'positive' : 'negative'"
                :label="utPlStore.grid.gAggOk ? 'G-agg OK' : 'G-agg FAIL'"
              />
              <QBtn
                dense
                flat
                no-caps
                icon="refresh"
                label="Обновить"
                :loading="utPlStore.loading"
                data-test="investment-programs-plans-refresh"
                @click="onRefreshUtPl"
              />
              <QBtn
                dense
                unelevated
                color="primary"
                no-caps
                label="Новый план"
                data-test="investment-programs-plans-create"
                @click="createUtPlOpen = true"
              />
            </div>
            <div class="row q-col-gutter-sm">
              <div class="col-5">
                <QSelect
                  :model-value="utPlStore.selectedPlKey"
                  dense
                  outlined
                  emit-value
                  map-options
                  clearable
                  :options="utPlPlanOptions"
                  label="План агента (iuplIpg=текущая)"
                  data-test="investment-programs-plans-select"
                  @update:model-value="onSelectUtPl"
                />
              </div>
              <div class="col-7">
                <QSelect
                  :model-value="utPlStore.selectedIpgpKey"
                  dense
                  outlined
                  emit-value
                  map-options
                  clearable
                  :options="utPlPointOptions"
                  label="Пункт ИП"
                  data-test="investment-programs-plans-point"
                  @update:model-value="onSelectUtPlPoint"
                />
              </div>
            </div>
            <div v-if="utPlStore.error" class="text-negative text-body2">{{ utPlStore.error }}</div>
            <div
              v-if="utPlStore.grid"
              class="text-caption text-grey-7"
            >
              UtPlP={{ utPlStore.grid.plPnKey }} · limYear(212)={{ utPlStore.grid.limYear ?? '—' }}
            </div>
            <div v-if="utPlStore.grid" class="col scroll">
              <table class="utpl-lmmn-table" data-test="investment-programs-plans-grid">
                <thead>
                  <tr>
                    <th>М</th>
                    <th>212</th>
                    <th>195</th>
                    <th>172</th>
                    <th>187</th>
                    <th>agg</th>
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="row in utPlEditRows" :key="row.month">
                    <td>{{ row.month }}</td>
                    <td>
                      <QInput
                        v-model.number="row.lim212"
                        dense
                        outlined
                        type="number"
                        step="any"
                        input-class="text-right"
                      />
                    </td>
                    <td>
                      <QInput
                        v-model.number="row.lim195"
                        dense
                        outlined
                        type="number"
                        step="any"
                        input-class="text-right"
                      />
                    </td>
                    <td>
                      <QInput
                        v-model.number="row.lim172"
                        dense
                        outlined
                        type="number"
                        step="any"
                        input-class="text-right"
                      />
                    </td>
                    <td>
                      <QInput
                        v-model.number="row.lim187"
                        dense
                        outlined
                        type="number"
                        step="any"
                        input-class="text-right"
                      />
                    </td>
                    <td class="text-caption">{{ row.aggCode }}</td>
                    <td>
                      <QBtn
                        dense
                        flat
                        no-caps
                        color="primary"
                        label="Сохранить"
                        :loading="utPlStore.mutating"
                        :data-test="`investment-programs-plans-save-m${row.month}`"
                        @click="onSaveUtPlMonth(row)"
                      />
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
            <div v-else class="investment-programs-muted">
              Выберите план агента и пункт — откроется грид месяц × stCost.
            </div>
          </QTabPanel>

          <QTabPanel
            name="load-utpl"
            class="q-pa-md column q-gutter-sm"
            data-test="investment-programs-load-utpl-panel"
          >
            <div class="row items-center q-gutter-sm">
              <div class="text-subtitle2">Загрузка уточнённых планов (LdM / Monf)</div>
              <QSpace />
              <QBtn
                dense
                flat
                no-caps
                icon="refresh"
                label="Обновить"
                :loading="monfStore.loading"
                data-test="investment-programs-monf-refresh"
                @click="onRefreshMonf"
              />
              <QBtn
                dense
                unelevated
                color="primary"
                no-caps
                label="Новая строка"
                :disable="store.selectedLoadKey == null"
                data-test="investment-programs-monf-create"
                @click="openCreateMonf"
              />
            </div>
            <div class="investment-programs-muted text-caption">
              LdM Monf: «Разобрать» (§6.5) → «Применить» (§6.6, UtPlP + LmMn@212). Нужны сессия load и
              план UtPl.
            </div>
            <div class="row q-col-gutter-sm">
              <div class="col-5">
                <QSelect
                  v-model="monfLoadFilterModel"
                  dense
                  outlined
                  emit-value
                  map-options
                  clearable
                  label="Сессия load"
                  :options="loadSelectOptions"
                  :loading="store.loadingLoads"
                  data-test="investment-programs-monf-load"
                />
              </div>
              <div class="col-7">
                <QSelect
                  :model-value="monfStore.selectedId"
                  dense
                  outlined
                  emit-value
                  map-options
                  clearable
                  label="Строка Monf"
                  :options="monfRowOptions"
                  :loading="monfStore.loading"
                  data-test="investment-programs-monf-select"
                  @update:model-value="onSelectMonf"
                />
              </div>
            </div>
            <div v-if="monfStore.error" class="text-negative text-body2">{{ monfStore.error }}</div>
            <div v-if="monfStore.selected" class="row q-col-gutter-sm">
              <div class="col-6">
                <QInput v-model="monfForm.name" dense outlined label="Наименование" />
              </div>
              <div class="col-6">
                <QSelect
                  v-model="monfForm.utPlKey"
                  dense
                  outlined
                  emit-value
                  map-options
                  clearable
                  label="План UtPl"
                  :options="utPlPlanOptions"
                />
              </div>
              <div class="col-12">
                <QInput v-model="monfForm.filePath" dense outlined label="Путь Excel" />
              </div>
              <div class="col-4">
                <QInput v-model="monfForm.sheet" dense outlined label="Лист" />
              </div>
              <div class="col-4">
                <QInput v-model="monfForm.limColumn" dense outlined label="Якорь колонки лимита" />
              </div>
              <div class="col-2">
                <QInput
                  v-model.number="monfForm.sumFirst"
                  dense
                  outlined
                  type="number"
                  label="SumFirst"
                />
              </div>
              <div class="col-2 flex items-center">
                <QBtn
                  dense
                  outline
                  no-caps
                  :color="monfForm.quarter ? 'primary' : 'grey'"
                  :label="monfForm.quarter ? 'Q+M (16)' : '12 M'"
                  data-test="investment-programs-monf-quarter"
                  @click="monfForm.quarter = !monfForm.quarter"
                />
              </div>
              <div class="col-12">
                <QInput v-model="monfForm.note" dense outlined type="textarea" autogrow label="Заметка" />
              </div>
              <div class="col-12 row q-gutter-sm items-center">
                <QBtn
                  unelevated
                  color="primary"
                  no-caps
                  label="Сохранить"
                  :loading="monfStore.mutating"
                  data-test="investment-programs-monf-save"
                  @click="onSaveMonf"
                />
                <QBtn
                  unelevated
                  color="secondary"
                  no-caps
                  label="Разобрать"
                  :loading="monfStore.parsing"
                  :disable="!monfForm.filePath || monfStore.applying"
                  data-test="investment-programs-monf-parse"
                  @click="onParseMonf"
                />
                <QBtn
                  outline
                  color="secondary"
                  no-caps
                  label="Проверить"
                  :loading="monfStore.applying"
                  :disable="monfForm.utPlKey == null || monfStore.parsing"
                  data-test="investment-programs-monf-apply-dry"
                  @click="onApplyMonfDry"
                />
                <QBtn
                  unelevated
                  color="secondary"
                  no-caps
                  label="Применить"
                  :loading="monfStore.applying"
                  :disable="monfForm.utPlKey == null || monfStore.parsing"
                  data-test="investment-programs-monf-apply"
                  @click="onApplyMonf"
                />
                <QBtn
                  outline
                  color="negative"
                  no-caps
                  label="Удалить"
                  :loading="monfStore.mutating"
                  data-test="investment-programs-monf-delete"
                  @click="onDeleteMonf"
                />
                <div
                  v-if="monfStore.parseResult"
                  class="text-caption text-grey-7"
                  data-test="investment-programs-monf-parse-summary"
                >
                  hits={{ monfStore.parseResult.codeHits }} · loaded={{ monfStore.parseResult.loadedCount }}
                  · skipped={{ monfStore.parseResult.skippedCount }} · лист
                  «{{ monfStore.parseResult.sheetName }}»
                </div>
                <div
                  v-if="monfStore.applyResult"
                  class="text-caption"
                  :class="monfStore.applyResult.errorCount ? 'text-negative' : 'text-grey-7'"
                  data-test="investment-programs-monf-apply-summary"
                >
                  apply{{ monfStore.applyResult.dryRun ? ' (dry)' : '' }}:
                  {{ monfStore.applyResult.appliedCount }}/{{ monfStore.applyResult.parsedCount }}
                  · unmatched={{ monfStore.applyResult.unmatchedCount }}
                  · ambig={{ monfStore.applyResult.ambiguousCount }}
                  · err={{ monfStore.applyResult.errorCount }}
                </div>
              </div>
              <div
                class="col-12"
                v-if="
                  monfStore.selected.logHtml ||
                  monfStore.applyResult?.logHtml ||
                  monfStore.parseResult?.logHtml
                "
              >
                <div class="text-subtitle2 q-mb-xs">Ход (logHtml)</div>
                <div class="audit-log-surface">
                  <div
                    class="audit-log-html"
                    v-html="
                      monfStore.applyResult?.logHtml ||
                      monfStore.parseResult?.logHtml ||
                      monfStore.selected.logHtml
                    "
                  />
                </div>
              </div>
            </div>
            <div v-else class="investment-programs-muted">
              Выберите или создайте строку Monf (нужна сессия load).
            </div>
            <div v-if="monfStore.filteredRows.length" class="text-caption text-grey-7">
              Строк: {{ monfStore.filteredRows.length }}
              <template v-if="monfStore.filterLoadKey != null">
                · load={{ monfStore.filterLoadKey }}
              </template>
            </div>
          </QTabPanel>
        </QTabPanels>
      </template>
      <div v-else class="investment-programs-muted q-mt-md">Выберите инвестпрограмму в полосе карточек</div>
    </div>

    <QDialog v-model="createProgramOpen" persistent>
      <QCard style="min-width: 420px">
        <QCardSection class="text-h6">Новая ИП</QCardSection>
        <QCardSection class="row q-col-gutter-sm">
          <div class="col-12">
            <QInput v-model="createProgramForm.ipgNm" dense outlined label="Наименование" autofocus />
          </div>
          <div class="col-6">
            <QInput v-model.number="createProgramForm.ipgOg" dense outlined type="number" label="ogKey" />
          </div>
          <div class="col-6">
            <QInput
              v-model.number="createProgramForm.ipgYy"
              dense
              outlined
              type="number"
              label="yKey (ags.yyyy)"
            />
          </div>
          <div class="col-6">
            <QInput v-model.number="createProgramForm.ipgNum" dense outlined type="number" label="№" />
          </div>
          <div class="col-6">
            <QSelect
              v-model="createProgramForm.ipgStRlSh"
              dense
              outlined
              emit-value
              map-options
              :options="stNetOptions"
              label="stNet"
            />
          </div>
          <div class="col-6">
            <QInput v-model="createProgramForm.ipgStr" dense outlined type="date" label="Начало" />
          </div>
          <div class="col-6">
            <QInput
              v-model="createProgramForm.ipgEnd"
              dense
              outlined
              type="date"
              label="Окончание"
              clearable
            />
          </div>
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat no-caps label="Отмена" v-close-popup :disable="store.mutating" />
          <QBtn
            color="primary"
            unelevated
            no-caps
            label="Создать"
            :loading="store.mutating"
            @click="submitCreateProgram"
          />
        </QCardActions>
      </QCard>
    </QDialog>

    <QDialog v-model="createPointOpen" persistent>
      <QCard style="min-width: 400px">
        <QCardSection class="text-h6">Новый пункт</QCardSection>
        <QCardSection class="row q-col-gutter-sm">
          <div class="col-6">
            <QInput
              v-model.number="createPointForm.ipgpCstAgPn"
              dense
              outlined
              type="number"
              label="cstAgPn"
              autofocus
            />
          </div>
          <div class="col-6">
            <QSelect
              v-model="createPointForm.ipgpSh"
              dense
              outlined
              emit-value
              map-options
              :options="shOptions"
              label="Схема"
            />
          </div>
          <div class="col-6">
            <QInput
              v-model.number="createPointForm.ipgpNum"
              dense
              outlined
              type="number"
              label="№"
              clearable
            />
          </div>
          <div class="col-12">
            <QInput v-model="createPointForm.ipgpTskCms" dense outlined label="Комментарий" />
          </div>
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat no-caps label="Отмена" v-close-popup :disable="store.mutating" />
          <QBtn
            color="primary"
            unelevated
            no-caps
            label="Создать"
            :loading="store.mutating"
            @click="submitCreatePoint"
          />
        </QCardActions>
      </QCard>
    </QDialog>

    <QDialog v-model="createUtPlOpen" persistent>
      <QCard style="min-width: 360px">
        <QCardSection class="text-h6">Новый план агента</QCardSection>
        <QCardSection class="row q-col-gutter-sm">
          <div class="col-6">
            <QInput
              v-model.number="createUtPlForm.agKey"
              dense
              outlined
              type="number"
              label="agKey (ogAg)"
              autofocus
            />
          </div>
          <div class="col-12">
            <QInput v-model="createUtPlForm.name" dense outlined label="Наименование" />
          </div>
        </QCardSection>
        <QCardActions align="right">
          <QBtn flat no-caps label="Отмена" v-close-popup :disable="utPlStore.mutating" />
          <QBtn
            color="primary"
            unelevated
            no-caps
            label="Создать"
            :loading="utPlStore.mutating"
            data-test="investment-programs-plans-create-submit"
            @click="submitCreateUtPl"
          />
        </QCardActions>
      </QCard>
    </QDialog>
  </QPage>
</template>

<script setup lang="ts">
/**
 * Экран Leaves (§2.5.2 / §3.2.8): полоса ИП + вкладки; Пункты — FemsqTreeList.
 */
import { computed, onMounted, reactive, ref, watch } from 'vue';
import {
  QBadge,
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
  QTab,
  QTabPanel,
  QTabPanels,
  QTabs,
  QTooltip,
  useQuasar
} from 'quasar';
import {
  FemsqCardStrip,
  FemsqTreeList,
  type FemsqTreeListColumnSet
} from 'fequlib';

import { getStIpgNetworks } from '@/api/st-ipg-structure-api';
import {
  useIpgLeavesStore,
  type LeavesTreeNode
} from '@/stores/ipg-leaves';
import { useImpIpgLoadMonfStore } from '@/stores/imp-ipg-load-monf';
import { useIpgUtPlStore } from '@/stores/ipg-utpl';

const STUB_O2 = 'Заглушка до O2 (блок 4): группы планов (UtPlGr) — вторичный экран.';

const store = useIpgLeavesStore();
const utPlStore = useIpgUtPlStore();
const monfStore = useImpIpgLoadMonfStore();
const $q = useQuasar();
const createUtPlOpen = ref(false);
const monfForm = reactive({
  name: '',
  filePath: '',
  sheet: '',
  limColumn: '',
  quarter: true,
  sumFirst: null as number | null,
  utPlKey: null as number | null,
  note: ''
});
const createUtPlForm = reactive({
  agKey: 1,
  name: ''
});
/** Локальные редактируемые строки грида (не мутировать store напрямую). */
const utPlEditRows = ref<
  {
    month: number;
    lim212: number | null;
    lim195: number | null;
    lim172: number | null;
    lim187: number | null;
    aggCode: string;
  }[]
>([]);

/** Вкладка master: general | points | load-points | stubs. */
const mainTab = ref<'general' | 'points' | 'load-points' | 'plan-groups' | 'plans' | 'load-utpl'>(
  'points'
);
const expandedKeys = ref<string[]>([]);
/** §3.2.9.3: фильтр в FemsqTreeList (не host QInput). */
const pointFilterModel = ref('');
const pointColumnFilters = ref<Record<string, string>>({});
const pointFiltersVisible = ref(false);
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
  ipgpSmEqu: null as number | null,
  ipgpSmOth: null as number | null,
  ipgpSmAgFee: null as number | null,
  ipgpCostAdjust: null as number | null,
  ipgpSmReserv: null as number | null
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

const loadSelectOptions = computed(() =>
  store.loads.map((item) => ({
    label: `${item.id}: ${item.name}`,
    value: item.id
  }))
);

const loadModel = computed({
  get: () => store.selectedLoadKey,
  set: (value: number | null) => {
    store.selectLoad(value);
  }
});

const previousIpgModel = computed({
  get: () => store.previousIpgKeyForApply,
  set: (value: number | string | null) => {
    if (value === null || value === '' || Number.isNaN(Number(value))) {
      store.previousIpgKeyForApply = null;
      return;
    }
    store.previousIpgKeyForApply = Number(value);
  }
});

const canApplyPoints = computed(() => store.selectedLoadKey != null);

/** Тон итога apply: полный OK / частичный / полный провал. */
const applyLogToneClass = computed(() => {
  const result = store.applyResult;
  if (result == null) {
    return '';
  }
  if (result.ready) {
    return 'text-positive';
  }
  if (result.appliedCount > 0 || (result.skippedAlreadyCount ?? 0) > 0) {
    return 'text-warning';
  }
  return 'text-negative';
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

function formatSum(value: unknown): string {
  if (value == null || value === '') {
    return '—';
  }
  const n = Number(value);
  return Number.isFinite(n) ? String(n) : String(value);
}

/** columnSets: корни pn + папки-оси + привязки / stub (§3.2.8.4). */
const leavesColumnSets: FemsqTreeListColumnSet<LeavesTreeNode>[] = [
  {
    level: 'pn',
    columns: [
      { name: 'label', label: 'САК', field: 'label' },
      // §3.2.8.5: узкие data-колонки (~САК); ellipsis + session-resize
      { name: 'cstName', label: 'Стройка', field: 'cstName', width: '110px' },
      { name: 'ogName', label: 'Агент', field: 'ogName', width: '110px' },
      { name: 'num', label: '№', field: 'num', width: '56px', align: 'right' },
      { name: 'sh', label: 'Схема', field: 'shName', width: '120px' },
      {
        name: 'ttl',
        label: 'Итого',
        field: 'smTtl',
        width: '96px',
        align: 'right',
        format: formatSum,
        filterable: false
      },
      {
        name: 'wrk',
        label: 'СМР',
        field: 'smWrk',
        width: '96px',
        align: 'right',
        format: formatSum,
        filterable: false
      },
      {
        name: 'equ',
        label: 'Оборуд.',
        field: 'smEqu',
        width: '88px',
        align: 'right',
        format: formatSum,
        filterable: false
      },
      {
        name: 'oth',
        label: 'Прочее',
        field: 'smOth',
        width: '88px',
        align: 'right',
        format: formatSum,
        filterable: false
      },
      {
        name: 'agFee',
        label: 'Аг.возн.',
        field: 'smAgFee',
        width: '88px',
        align: 'right',
        format: formatSum,
        filterable: false
      },
      {
        name: 'adj',
        label: 'Корр.',
        field: 'costAdjust',
        width: '80px',
        align: 'right',
        format: formatSum,
        filterable: false
      },
      {
        name: 'reserv',
        label: 'Резерв',
        field: 'smReserv',
        width: '80px',
        align: 'right',
        format: formatSum,
        filterable: false
      },
      { name: 'cms', label: 'Мощность', field: 'note', width: '140px' }
    ]
  },
  {
    level: 'axis',
    columns: [{ name: 'label', label: 'Ось', field: 'label' }]
  },
  {
    level: 'bind',
    columns: [
      { name: 'label', label: 'Раздел', field: 'label' },
      { name: 'sti', label: 'sti', field: 'stiKey', width: '72px', align: 'right' }
    ]
  },
  {
    level: 'stub',
    columns: [{ name: 'label', label: '…', field: 'label' }]
  }
];

/** Контекст пункта: выбран pn или папка/дети с ipgpKey (не голый bind). */
const showPointContext = computed(() => {
  const key = store.selectedTreeKey;
  if (key == null || store.selectedPoint == null) {
    return false;
  }
  if (key.startsWith('st:')) {
    return false;
  }
  return true;
});

const selectedBind = computed(() => {
  const key = store.selectedTreeKey;
  if (key == null || !key.startsWith('st:')) {
    return null;
  }
  const node = findTreeNode(store.treeNodes, key);
  return node?.domainKind === 'stBind' ? node : null;
});

function findTreeNode(nodes: LeavesTreeNode[], key: string): LeavesTreeNode | null {
  for (const node of nodes) {
    if (node.key === key) {
      return node;
    }
    if (node.children?.length) {
      const found = findTreeNode(node.children, key);
      if (found) {
        return found;
      }
    }
  }
  return null;
}

function clearTreeSelection(): void {
  store.selectTreeNode(null);
}

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
  pointForm.ipgpSmOth = p.ipgpSmOth;
  pointForm.ipgpSmAgFee = p.ipgpSmAgFee;
  pointForm.ipgpCostAdjust = p.ipgpCostAdjust;
  pointForm.ipgpSmReserv = p.ipgpSmReserv;
}

const utPlPlanOptions = computed(() =>
  utPlStore.plans.map((p) => ({
    label: `${p.iuplKey} · ${p.iuplNm || '—'} · ag=${p.iuplAg}`,
    value: p.iuplKey
  }))
);

const utPlPointOptions = computed(() =>
  store.points.map((p) => ({
    label: `${p.ipgpKey} · №${p.ipgpNum ?? '—'} · ${p.cstAgPnCode || p.cstAgPnCstName || '—'}`,
    value: p.ipgpKey
  }))
);

function syncUtPlEditRows(): void {
  const months = utPlStore.grid?.months ?? [];
  utPlEditRows.value = months.map((m) => ({
    month: m.month,
    lim212: m.lim212,
    lim195: m.lim195,
    lim172: m.lim172,
    lim187: m.lim187,
    aggCode: m.aggCode
  }));
}

async function onRefreshUtPl(): Promise<void> {
  if (store.selectedIpgKey == null) {
    return;
  }
  await utPlStore.loadPlans(store.selectedIpgKey);
  if (utPlStore.selectedPlKey != null && utPlStore.selectedIpgpKey != null) {
    await utPlStore.loadGrid();
  }
}

async function onSelectUtPl(plKey: number | null): Promise<void> {
  utPlStore.selectPlan(plKey);
  if (plKey != null && utPlStore.selectedIpgpKey != null) {
    await utPlStore.loadGrid();
  }
}

async function onSelectUtPlPoint(ipgpKey: number | null): Promise<void> {
  await utPlStore.selectPoint(ipgpKey);
}

async function onSaveUtPlMonth(row: {
  month: number;
  lim212: number | null;
  lim195: number | null;
  lim172: number | null;
  lim187: number | null;
  aggCode: string;
}): Promise<void> {
  const ok = await utPlStore.saveMonth({
    plPnKey: utPlStore.grid?.plPnKey ?? 0,
    month: row.month,
    lim212: row.lim212,
    lim195: row.lim195,
    lim172: row.lim172,
    lim187: row.lim187,
    aggCode: row.aggCode
  });
  if (ok) {
    $q.notify({ type: 'positive', message: `Месяц ${row.month} сохранён` });
  } else if (utPlStore.error) {
    $q.notify({ type: 'negative', message: utPlStore.error });
  }
}

async function submitCreateUtPl(): Promise<void> {
  if (store.selectedIpgKey == null || !createUtPlForm.agKey) {
    $q.notify({ type: 'warning', message: 'Нужны ИП и agKey' });
    return;
  }
  const created = await utPlStore.createPlan({
    ipgKey: store.selectedIpgKey,
    agKey: Number(createUtPlForm.agKey),
    name: createUtPlForm.name.trim() || null
  });
  if (created) {
    createUtPlOpen.value = false;
    createUtPlForm.name = '';
    $q.notify({ type: 'positive', message: `План ${created.iuplKey} создан` });
  } else if (utPlStore.error) {
    $q.notify({ type: 'negative', message: utPlStore.error });
  }
}

const monfLoadFilterModel = computed({
  get: () => monfStore.filterLoadKey,
  set: (value: number | null) => {
    monfStore.setLoadFilter(value);
    if (value != null) {
      store.selectLoad(value);
    }
  }
});

const monfRowOptions = computed(() =>
  monfStore.filteredRows.map((r) => ({
    label: `${r.id}: ${r.name}${r.filePath ? ' · ' + r.filePath : ''}`,
    value: r.id
  }))
);

function syncMonfForm(): void {
  const row = monfStore.selected;
  if (row == null) {
    monfForm.name = '';
    monfForm.filePath = '';
    monfForm.sheet = '';
    monfForm.limColumn = '';
    monfForm.quarter = true;
    monfForm.sumFirst = null;
    monfForm.utPlKey = null;
    monfForm.note = '';
    return;
  }
  monfForm.name = row.name ?? '';
  monfForm.filePath = row.filePath ?? '';
  monfForm.sheet = row.sheet ?? '';
  monfForm.limColumn = row.limColumn ?? '';
  monfForm.quarter = row.quarter !== false;
  monfForm.sumFirst = row.sumFirst ?? null;
  monfForm.utPlKey = row.utPlKey ?? null;
  monfForm.note = row.note ?? '';
}

async function onRefreshMonf(): Promise<void> {
  if (store.selectedIpgKey == null) {
    return;
  }
  if (store.loads.length === 0) {
    await store.fetchLoads(store.selectedIpgKey);
  }
  await monfStore.loadForIpg(store.selectedIpgKey);
  syncMonfForm();
}

function onSelectMonf(id: number | null): void {
  monfStore.select(id);
  syncMonfForm();
}

async function openCreateMonf(): Promise<void> {
  const loadKey = monfStore.filterLoadKey ?? store.selectedLoadKey;
  if (loadKey == null) {
    $q.notify({ type: 'warning', message: 'Выберите сессию load' });
    return;
  }
  try {
    const created = await monfStore.create({
      loadKey,
      name: `Monf ${new Date().toISOString().slice(0, 16)}`,
      quarter: true,
      limColumn: 'лимит'
    });
    syncMonfForm();
    $q.notify({ type: 'positive', message: `Monf ${created.id} создан` });
  } catch {
    $q.notify({ type: 'negative', message: monfStore.error || 'Ошибка создания Monf' });
  }
}

async function onSaveMonf(): Promise<void> {
  if (monfStore.selectedId == null) {
    return;
  }
  if (!monfForm.name.trim()) {
    $q.notify({ type: 'warning', message: 'Наименование обязательно' });
    return;
  }
  try {
    await monfStore.update(monfStore.selectedId, {
      name: monfForm.name.trim(),
      filePath: monfForm.filePath || null,
      sheet: monfForm.sheet || null,
      limColumn: monfForm.limColumn || null,
      quarter: monfForm.quarter,
      sumFirst: monfForm.sumFirst,
      utPlKey: monfForm.utPlKey,
      note: monfForm.note || null
    });
    syncMonfForm();
    $q.notify({ type: 'positive', message: 'Monf сохранён' });
  } catch {
    $q.notify({ type: 'negative', message: monfStore.error || 'Ошибка сохранения Monf' });
  }
}

async function onDeleteMonf(): Promise<void> {
  if (monfStore.selectedId == null) {
    return;
  }
  try {
    const id = monfStore.selectedId;
    await monfStore.remove(id);
    syncMonfForm();
    $q.notify({ type: 'positive', message: `Monf ${id} удалён` });
  } catch {
    $q.notify({ type: 'negative', message: monfStore.error || 'Ошибка удаления Monf' });
  }
}

/**
 * §6.5: parse skeleton — якоря → staging + HTML-лог.
 */
async function onParseMonf(): Promise<void> {
  if (monfStore.selectedId == null) {
    return;
  }
  if (!monfForm.filePath.trim()) {
    $q.notify({ type: 'warning', message: 'Укажите путь Excel' });
    return;
  }
  try {
    await saveMonfForm();
    const result = await monfStore.parse(monfForm.filePath);
    syncMonfForm();
    if (result) {
      $q.notify({
        type: 'positive',
        message: `Разбор: loaded=${result.loadedCount}, skipped=${result.skippedCount}`
      });
    }
  } catch {
    $q.notify({ type: 'negative', message: monfStore.error || 'Ошибка разбора Monf' });
  }
}

async function saveMonfForm(): Promise<void> {
  if (monfStore.selectedId == null) {
    return;
  }
  await monfStore.update(monfStore.selectedId, {
    name: monfForm.name.trim() || 'Monf',
    filePath: monfForm.filePath || null,
    sheet: monfForm.sheet || null,
    limColumn: monfForm.limColumn || null,
    quarter: monfForm.quarter,
    sumFirst: monfForm.sumFirst,
    utPlKey: monfForm.utPlKey,
    note: monfForm.note || null
  });
}

/**
 * §6.6 dryRun: сверка матчей код+SmTtl без записи.
 */
async function onApplyMonfDry(): Promise<void> {
  await runApplyMonf(true);
}

/**
 * §6.6: запись UtPlP / LmMn@212.
 */
async function onApplyMonf(): Promise<void> {
  await runApplyMonf(false);
}

async function runApplyMonf(dryRun: boolean): Promise<void> {
  if (monfStore.selectedId == null) {
    return;
  }
  if (monfForm.utPlKey == null) {
    $q.notify({ type: 'warning', message: 'Выберите план UtPl' });
    return;
  }
  try {
    await saveMonfForm();
    const result = await monfStore.apply(dryRun);
    syncMonfForm();
    if (result) {
      $q.notify({
        type: result.errorCount > 0 ? 'warning' : 'positive',
        message: `${dryRun ? 'Проверка' : 'Применение'}: ${result.appliedCount}/${result.parsedCount}, unmatched=${result.unmatchedCount}`
      });
    }
  } catch {
    $q.notify({ type: 'negative', message: monfStore.error || 'Ошибка apply Monf' });
  }
}

watch(
  () => store.selectedProgram,
  async (program) => {
    syncHeaderForm();
    utPlStore.reset();
    monfStore.reset();
    syncMonfForm();
    if (program != null) {
      await utPlStore.loadPlans(program.ipgKey);
      if (store.selectedIpgpKey != null) {
        await utPlStore.selectPoint(store.selectedIpgpKey);
      }
      if (mainTab.value === 'load-utpl') {
        await monfStore.loadForIpg(program.ipgKey);
      }
    }
  },
  { immediate: true }
);

watch(
  () => utPlStore.grid,
  () => syncUtPlEditRows()
);

watch(mainTab, async (tab) => {
  if (tab === 'plans' && store.selectedIpgKey != null && utPlStore.plans.length === 0) {
    await utPlStore.loadPlans(store.selectedIpgKey);
  }
  if (tab === 'load-utpl' && store.selectedIpgKey != null) {
    if (store.loads.length === 0) {
      await store.fetchLoads(store.selectedIpgKey);
    }
    await monfStore.loadForIpg(store.selectedIpgKey);
    if (store.selectedLoadKey != null && monfStore.filterLoadKey == null) {
      monfStore.setLoadFilter(store.selectedLoadKey);
    }
  }
});

watch(
  () => store.selectedPoint,
  () => syncPointForm(),
  { immediate: true }
);

watch(
  () => store.selectedIpgpKey,
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

/**
 * §3.2.8.3: dryRun без записи — «Проверить».
 */
async function onApplyPointsDryRun(): Promise<void> {
  try {
    const preview = await store.applySelectedPoints(true);
    notifyApplyResult(preview);
  } catch (err) {
    $q.notify({
      type: 'negative',
      message: err instanceof Error ? err.message : String(err)
    });
  }
}

/**
 * §3.2.8.3: commit partial; лог на панели.
 */
async function onApplyPoints(): Promise<void> {
  try {
    const committed = await store.applySelectedPoints(false);
    notifyApplyResult(committed);
  } catch (err) {
    $q.notify({
      type: 'negative',
      message: err instanceof Error ? err.message : String(err)
    });
  }
}

/**
 * Notify по итогу apply: partial — warning, полный успех — positive.
 */
function notifyApplyResult(result: {
  dryRun: boolean;
  appliedCount: number;
  skippedAlreadyCount?: number;
  errors: string[];
  ready: boolean;
}): void {
  const skipped = result.skippedAlreadyCount ?? 0;
  const mode = result.dryRun ? 'Проверка' : 'Загрузка';
  const summary =
    `${mode}: применено ${result.appliedCount}, уже было ${skipped}, ошибок ${result.errors.length}`;
  if (result.ready) {
    $q.notify({ type: 'positive', message: summary });
    return;
  }
  if (result.appliedCount > 0 || skipped > 0) {
    $q.notify({
      type: 'warning',
      message: `${summary} — см. лог`,
      timeout: 8000
    });
    return;
  }
  $q.notify({
    type: 'negative',
    message: result.errors[0] ?? summary,
    timeout: 8000
  });
}

/**
 * Выбор ИП из CardStrip (ключ = ipgKey).
 */
async function onSelectNetworkKey(key: string | number | null): Promise<void> {
  if (key == null || key === '') {
    return;
  }
  const ipgKey = Number(key);
  if (Number.isNaN(ipgKey)) {
    return;
  }
  await onSelectProgram(ipgKey);
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
      ipgpSmEqu: pointForm.ipgpSmEqu,
      ipgpSmOth: pointForm.ipgpSmOth,
      ipgpSmAgFee: pointForm.ipgpSmAgFee,
      ipgpCostAdjust: pointForm.ipgpCostAdjust,
      ipgpSmReserv: pointForm.ipgpSmReserv
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
.investment-programs-inner {
  min-height: 0;
}

.investment-programs-filter-year {
  width: 5.5rem;
  max-width: 5.5rem;
  flex: 0 0 auto;
}

.investment-programs-filter-name {
  width: 12rem;
  max-width: 12rem;
  flex: 0 0 auto;
}

.fill-pane {
  height: 100%;
  min-height: 0;
  overflow: hidden;
}

.investment-programs-panels {
  min-height: 0;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.investment-programs-panels :deep(.q-panel-parent),
.investment-programs-panels :deep(.q-tab-panel) {
  flex: 1 1 auto;
  min-height: 0;
  height: 100%;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.investment-programs-muted {
  color: var(--femsq-text-muted, rgba(0, 0, 0, 0.54));
}

.utpl-lmmn-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.85rem;
}

.utpl-lmmn-table th,
.utpl-lmmn-table td {
  padding: 0.25rem 0.35rem;
  border-bottom: 1px solid rgba(0, 0, 0, 0.08);
  vertical-align: middle;
}

.utpl-lmmn-table th {
  text-align: left;
  font-weight: 600;
}

.leaves-tree {
  min-height: 200px;
  border: 1px solid var(--femsq-border, rgba(0, 0, 0, 0.12));
  border-radius: 4px;
  overflow: hidden;
}

.investment-programs-context {
  max-height: 42%;
  overflow: auto;
  border: 1px solid var(--femsq-border);
  border-radius: 4px;
  padding: 8px 10px;
  background: var(--femsq-bg-elevated);
  color: var(--femsq-text);
}

.investment-programs-context :deep(.q-field__native),
.investment-programs-context :deep(.q-field__label),
.investment-programs-context :deep(.q-field__marginal),
.investment-programs-context :deep(.q-placeholder) {
  color: var(--femsq-text);
}

.investment-programs-context :deep(.q-field--outlined .q-field__control) {
  background: var(--femsq-field-filled-bg, var(--femsq-bg-surface));
}

.investment-programs-context :deep(.q-field--outlined .q-field__control::before) {
  border-color: var(--femsq-border);
}

.investment-programs-context :deep(.q-item) {
  color: var(--femsq-text);
}

.investment-programs-bind-list {
  max-height: 7rem;
  overflow: auto;
  background: var(--femsq-bg-surface);
  border-color: var(--femsq-border) !important;
}

.investment-programs-load-toolbar {
  min-height: 40px;
}

.investment-programs-prev-ipg {
  flex: 0 0 9rem;
  width: 9rem;
  max-width: 9rem;
}

.investment-programs-load-meta,
.investment-programs-apply-summary {
  min-height: 1.25rem;
  line-height: 1.25rem;
}

.investment-programs-load-log-wrap {
  min-height: 0;
}

.investment-programs-load-log {
  min-height: 0;
  overflow: auto;
  border: 1px solid var(--femsq-border, rgba(0, 0, 0, 0.12));
  border-radius: 4px;
  padding: 4px;
}
</style>
