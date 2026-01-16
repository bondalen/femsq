<template>
  <v-container fluid class="pa-4">
    <v-row>
      <v-col cols="12">
        <h1 class="text-h4 mb-4">Ревизии отчётов агента</h1>
      </v-col>
    </v-row>
    
    <v-row>
      <v-col cols="12">
        <v-card>
          <v-tabs v-model="currentTab" bg-color="primary">
            <v-tab value="files">
              <v-icon icon="mdi-file-multiple" class="mr-2" />
              Файлы для проверки
            </v-tab>
            <v-tab value="results" disabled>
              <v-icon icon="mdi-chart-box-outline" class="mr-2" />
              Результаты
            </v-tab>
            <v-tab value="land-review" disabled>
              <v-icon icon="mdi-map-marker" class="mr-2" />
              Земля, рассмотрения
            </v-tab>
            <v-tab value="land-reports" disabled>
              <v-icon icon="mdi-file-chart" class="mr-2" />
              Земля, отчёты
            </v-tab>
            <v-tab value="land-rent" disabled>
              <v-icon icon="mdi-currency-rub" class="mr-2" />
              Земля, итог
            </v-tab>
          </v-tabs>
          
          <v-card-text>
            <v-window v-model="currentTab">
              <v-window-item value="files">
                <AuditFilesTab :audit-id="1" />
              </v-window-item>
              
              <v-window-item value="results">
                <v-alert type="info">Вкладка "Результаты" в разработке</v-alert>
              </v-window-item>
              
              <v-window-item value="land-review">
                <v-alert type="info">Вкладка "Земля, рассмотрения" в разработке</v-alert>
              </v-window-item>
              
              <v-window-item value="land-reports">
                <v-alert type="info">Вкладка "Земля, отчёты" в разработке</v-alert>
              </v-window-item>
              
              <v-window-item value="land-rent">
                <v-alert type="info">Вкладка "Земля, итог" в разработке</v-alert>
              </v-window-item>
            </v-window>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import AuditFilesTab from '@/components/audits/AuditFilesTab.vue'

const currentTab = ref('files')
</script>
