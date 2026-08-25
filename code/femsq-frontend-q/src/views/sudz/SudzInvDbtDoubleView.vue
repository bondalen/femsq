<template>
  <QPage class="q-pa-none" data-test="sudz-inv-dbt-double-view">
    <div class="absolute-full q-pa-md column no-wrap">
      <div class="row items-center q-mb-sm q-gutter-sm shrink-0">
        <QBtn
          color="primary"
          unelevated
          dense
          no-caps
          icon="arrow_back"
          label="К загрузке свода"
          data-test="sudz-inv-dbt-double-back"
          @click="goBack"
        />
        <div class="text-h6 col">Разбор двоящих задолженностей СФ</div>
      </div>
      <div class="text-body2 text-grey-7">
        Каркас экрана (S66e). Полный разбор очереди
        <code>CnInvUplInvDbtDouble</code> — в следующих срезах; сейчас очередь
        пересобирается шагом воронки <code>invDbtLoad</code>.
      </div>
    </div>
  </QPage>
</template>

<script setup lang="ts">
import { QBtn, QPage } from 'quasar';
import { useConnectionStore } from '@/stores/connection';

const connection = useConnectionStore();

/**
 * Возврат на лаунчер загрузки свода.
 */
function goBack(): void {
  connection.navigate('sudz-dbt-upl');
}
</script>
