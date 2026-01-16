<template>
  <q-page padding>
    <div class="q-pa-md">
      <!-- Заголовок -->
      <div class="row q-mb-md">
        <div class="col">
          <h1 class="text-h4 q-mb-sm">Ревизии отчётов агента</h1>
          <p class="text-grey-7">Управление файлами для проверки и результатами ревизий</p>
        </div>
      </div>

      <!-- Карточка с вкладками -->
      <div class="row">
        <div class="col">
          <q-card flat bordered>
            <q-tabs
              v-model="currentTab"
              class="bg-primary text-white"
              active-color="white"
              indicator-color="white"
              align="left"
            >
              <q-tab name="files" icon="folder_open" label="Файлы для проверки" />
              <q-tab name="results" icon="assignment_turned_in" label="Результаты" disable />
              <q-tab name="land" icon="landscape" label="Земля" disable />
              <q-tab name="buildings" icon="business" label="Здания" disable />
              <q-tab name="facilities" icon="factory" label="Сооружения" disable />
              <q-tab name="movable" icon="category" label="Движимое имущество" disable />
            </q-tabs>

            <q-separator />

            <q-tab-panels v-model="currentTab" animated>
              <!-- Вкладка: Файлы для проверки -->
              <q-tab-panel name="files">
                <!-- TODO: В будущем загружать текущую ревизию из роутера или store -->
                <AuditFilesTab :audit-id="2" />
              </q-tab-panel>

              <!-- Вкладка: Результаты -->
              <q-tab-panel name="results">
                <q-banner class="bg-blue-1 text-blue-9">
                  <template v-slot:avatar>
                    <q-icon name="info" color="blue" />
                  </template>
                  <div class="text-h6 q-mb-sm">Результаты ревизии</div>
                  <div>
                    Эта вкладка будет содержать результаты проверки файлов и сводную информацию
                    по ревизии.
                  </div>
                </q-banner>
              </q-tab-panel>

              <!-- Вкладка: Земля -->
              <q-tab-panel name="land">
                <q-banner class="bg-blue-1 text-blue-9">
                  <template v-slot:avatar>
                    <q-icon name="info" color="blue" />
                  </template>
                  <div class="text-h6 q-mb-sm">Земельные участки</div>
                  <div>
                    Эта вкладка будет содержать информацию о земельных участках, выявленных в
                    процессе ревизии.
                  </div>
                </q-banner>
              </q-tab-panel>

              <!-- Вкладка: Здания -->
              <q-tab-panel name="buildings">
                <q-banner class="bg-blue-1 text-blue-9">
                  <template v-slot:avatar>
                    <q-icon name="info" color="blue" />
                  </template>
                  <div class="text-h6 q-mb-sm">Здания</div>
                  <div>
                    Эта вкладка будет содержать информацию о зданиях, выявленных в процессе
                    ревизии.
                  </div>
                </q-banner>
              </q-tab-panel>

              <!-- Вкладка: Сооружения -->
              <q-tab-panel name="facilities">
                <q-banner class="bg-blue-1 text-blue-9">
                  <template v-slot:avatar>
                    <q-icon name="info" color="blue" />
                  </template>
                  <div class="text-h6 q-mb-sm">Сооружения</div>
                  <div>
                    Эта вкладка будет содержать информацию о сооружениях, выявленных в процессе
                    ревизии.
                  </div>
                </q-banner>
              </q-tab-panel>

              <!-- Вкладка: Движимое имущество -->
              <q-tab-panel name="movable">
                <q-banner class="bg-blue-1 text-blue-9">
                  <template v-slot:avatar>
                    <q-icon name="info" color="blue" />
                  </template>
                  <div class="text-h6 q-mb-sm">Движимое имущество</div>
                  <div>
                    Эта вкладка будет содержать информацию о движимом имуществе, выявленном в
                    процессе ревизии.
                  </div>
                </q-banner>
              </q-tab-panel>
            </q-tab-panels>
          </q-card>
        </div>
      </div>
    </div>
  </q-page>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import AuditFilesTab from '@/components/audits/AuditFilesTab.vue';

const currentTab = ref('files');
</script>

<style scoped>
.text-h4 {
  font-size: 2rem;
  font-weight: 400;
  line-height: 1.2;
}
</style>
