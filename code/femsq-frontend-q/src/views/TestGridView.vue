<template>
  <q-page padding class="test-grid-view">
    <h4>Тест Quasar Grid для Master-Detail</h4>
    
    <!-- ВАРИАНТ 1: col-md-3 / col-md-9 (25% / 75%) -->
    <h5>Вариант 1: col-md-3 / col-md-9</h5>
    <div class="row q-col-gutter-md" style="height: 400px; border: 2px solid red;">
      <div class="col-12 col-md-3" style="background: lightblue; border: 1px solid blue;">
        <q-card>
          <q-card-section>
            <strong>ЛЕВАЯ ПАНЕЛЬ</strong><br>
            (25% на десктопе >= 1024px)
          </q-card-section>
        </q-card>
      </div>
      
      <div class="col-12 col-md-9" style="background: lightgreen; border: 1px solid green;">
        <q-card>
          <q-card-section>
            <strong>ПРАВАЯ ПАНЕЛЬ</strong><br>
            (75% на десктопе >= 1024px)
          </q-card-section>
        </q-card>
      </div>
    </div>
    
    <q-separator class="q-my-md" />
    
    <!-- ВАРИАНТ 2: col-sm-3 / col-sm-9 (работает >= 600px) -->
    <h5>Вариант 2: col-sm-3 / col-sm-9</h5>
    <div class="row q-col-gutter-md" style="height: 400px; border: 2px solid orange;">
      <div class="col-12 col-sm-3" style="background: lightblue; border: 1px solid blue;">
        <q-card>
          <q-card-section>
            <strong>ЛЕВАЯ ПАНЕЛЬ</strong><br>
            (25% при ширине >= 600px)
          </q-card-section>
        </q-card>
      </div>
      
      <div class="col-12 col-sm-9" style="background: lightgreen; border: 1px solid green;">
        <q-card>
          <q-card-section>
            <strong>ПРАВАЯ ПАНЕЛЬ</strong><br>
            (75% при ширине >= 600px)
          </q-card-section>
        </q-card>
      </div>
    </div>
    
    <q-separator class="q-my-md" />
    
    <!-- ВАРИАНТ 3: col-md-2 / col-md-10 (16.67% / 83.33%) -->
    <h5>Вариант 3: col-md-2 / col-md-10</h5>
    <div class="row q-col-gutter-md" style="height: 400px; border: 2px solid purple;">
      <div class="col-12 col-md-2" style="background: lightblue; border: 1px solid blue;">
        <q-card>
          <q-card-section>
            <strong>ЛЕВАЯ ПАНЕЛЬ</strong><br>
            (16.67% на десктопе >= 1024px)
          </q-card-section>
        </q-card>
      </div>
      
      <div class="col-12 col-md-10" style="background: lightgreen; border: 1px solid green;">
        <q-card>
          <q-card-section>
            <strong>ПРАВАЯ ПАНЕЛЬ</strong><br>
            (83.33% на десктопе >= 1024px)
          </q-card-section>
        </q-card>
      </div>
    </div>
    
    <q-separator class="q-my-md" />
    
    <!-- ВАРИАНТ 4: Кастомный CSS (как в 2a137c8) -->
    <h5>Вариант 4: col-12 + Кастомный CSS (как в 2a137c8)</h5>
    <div class="row q-col-gutter-md test-custom-grid" style="height: 400px; border: 2px solid green;">
      <div class="col-12 custom-left-panel" style="background: lightblue; border: 1px solid blue;">
        <q-card>
          <q-card-section>
            <strong>ЛЕВАЯ ПАНЕЛЬ</strong><br>
            (13.33% при >= 768px через CSS)
          </q-card-section>
        </q-card>
      </div>
      
      <div class="col-12 custom-right-panel" style="background: lightgreen; border: 1px solid green;">
        <q-card>
          <q-card-section>
            <strong>ПРАВАЯ ПАНЕЛЬ</strong><br>
            (86.67% при >= 768px через CSS)
          </q-card-section>
        </q-card>
      </div>
    </div>
    
    <q-separator class="q-my-md" />
    
    <!-- Информация об экране -->
    <q-card>
      <q-card-section>
        <h6>Информация об экране:</h6>
        <p><strong>Ширина окна:</strong> {{ windowWidth }}px</p>
        <p><strong>Breakpoint:</strong> {{ $q.screen.name }}</p>
        <p><strong>Quasar Screen:</strong></p>
        <ul>
          <li>xs (< 600px): {{ $q.screen.xs }}</li>
          <li>sm (600px - 1023px): {{ $q.screen.sm }}</li>
          <li>md (1024px - 1439px): {{ $q.screen.md }}</li>
          <li>lg (1440px - 1919px): {{ $q.screen.lg }}</li>
          <li>xl (>= 1920px): {{ $q.screen.xl }}</li>
        </ul>
      </q-card-section>
    </q-card>
    
    <q-separator class="q-my-md" />
    
    <q-card>
      <q-card-section>
        <h6>Рекомендации:</h6>
        <ul>
          <li v-if="windowWidth < 600">
            <q-badge color="warning">Окно слишком узкое (< 600px)</q-badge><br>
            Все варианты покажут панели друг под другом
          </li>
          <li v-else-if="windowWidth < 768">
            <q-badge color="info">Ширина: 600-767px</q-badge><br>
            Работают: Вариант 2 (col-sm), Вариант 4 НЕ работает (нужно >= 768px)
          </li>
          <li v-else-if="windowWidth < 1024">
            <q-badge color="primary">Ширина: 768-1023px</q-badge><br>
            Работают: Вариант 2 (col-sm), Вариант 4 (custom CSS)<br>
            НЕ работают: Вариант 1, 3 (col-md нужно >= 1024px)
          </li>
          <li v-else>
            <q-badge color="positive">Ширина: >= 1024px</q-badge><br>
            Работают все варианты!
          </li>
        </ul>
      </q-card-section>
    </q-card>
  </q-page>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue';
import { useQuasar } from 'quasar';

const $q = useQuasar();
const windowWidth = ref(window.innerWidth);

function updateWidth() {
  windowWidth.value = window.innerWidth;
}

onMounted(() => {
  window.addEventListener('resize', updateWidth);
});

onUnmounted(() => {
  window.removeEventListener('resize', updateWidth);
});
</script>

<style scoped>
.test-grid-view {
  max-width: 1800px;
  margin: 0 auto;
}

/* Вариант 4: Кастомный CSS как в 2a137c8 */
.test-custom-grid .custom-left-panel,
.test-custom-grid .custom-right-panel {
  flex: 0 0 100%;
  max-width: 100%;
}

@media (min-width: 768px) {
  .test-custom-grid .custom-left-panel {
    flex: 0 0 13.33%;
    max-width: 13.33%;
  }
  
  .test-custom-grid .custom-right-panel {
    flex: 0 0 86.67%;
    max-width: 86.67%;
  }
}
</style>
