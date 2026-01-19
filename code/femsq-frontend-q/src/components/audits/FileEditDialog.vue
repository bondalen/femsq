<template>
  <q-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" persistent>
    <q-card style="min-width: 500px; max-width: 600px">
      <q-card-section class="row items-center bg-primary text-white">
        <q-icon name="edit_document" size="sm" class="q-mr-sm" />
        <div class="text-h6">{{ isEdit ? 'Редактирование файла' : 'Добавление файла' }}</div>
        <q-space />
        <q-btn icon="close" flat round dense @click="handleCancel" />
      </q-card-section>

      <q-card-section class="q-pt-md">
        <q-form ref="formRef" @submit.prevent="handleSubmit" greedy>
          <!-- Имя файла -->
          <q-input
            v-model="form.afName"
            label="Имя файла *"
            outlined
            dense
            :rules="[
              (val) => (val && val.length > 0) || 'Поле обязательно для заполнения',
              (val) => (val && val.length <= 500) || 'Максимальная длина 500 символов'
            ]"
            class="q-mb-md"
          />

          <!-- Тип файла -->
          <q-select
            v-model="form.afType"
            :options="fileTypesOptions"
            label="Тип файла *"
            outlined
            dense
            emit-value
            map-options
            :rules="[(val) => val !== null && val !== undefined || 'Поле обязательно для заполнения']"
            class="q-mb-md"
          />

          <!-- Отправитель -->
          <q-select
            v-model="form.raOrgSender"
            :options="organizationsOptions"
            :loading="lookupsStore.loadingOrganizations"
            label="Отправитель"
            outlined
            dense
            emit-value
            map-options
            clearable
            class="q-mb-md"
          >
            <template v-if="organizationsOptions.length === 0 && !lookupsStore.loadingOrganizations" v-slot:no-option>
              <q-item>
                <q-item-section class="text-grey">
                  Организации не найдены
                </q-item-section>
              </q-item>
            </template>
          </q-select>

          <div class="row q-col-gutter-md q-mb-md">
            <!-- Номер по порядку -->
            <div class="col-12 col-sm-6">
              <q-input
                v-model.number="form.afNum"
                label="Номер по порядку"
                type="number"
                outlined
                dense
              />
            </div>

            <!-- Чекбоксы -->
            <div class="col-12 col-sm-6">
              <q-checkbox
                v-model="form.afExecute"
                label="Подлежит рассмотрению"
                dense
              />
              <q-checkbox
                v-model="form.afSource"
                label="Брать данные из Excel"
                dense
              />
            </div>
          </div>
        </q-form>
      </q-card-section>

      <q-card-actions align="right" class="q-pa-md">
        <q-btn
          label="Отмена"
          color="grey-7"
          flat
          @click="handleCancel"
        />
        <q-btn
          :label="isEdit ? 'Сохранить' : 'Создать'"
          color="primary"
          unelevated
          @click="handleSubmit"
          :loading="loading"
        />
      </q-card-actions>
    </q-card>
  </q-dialog>
</template>

<script setup lang="ts">
import { ref, watch, computed } from 'vue';
import type { RaFDto, RaFCreateRequest, RaFUpdateRequest } from '@/types/files';
import { useLookupsStore } from '@/stores/lookups';

interface Props {
  modelValue: boolean;
  file?: RaFDto | null;
  dirId: number;
}

interface Emits {
  (e: 'update:modelValue', value: boolean): void;
  (e: 'save', data: RaFCreateRequest | RaFUpdateRequest): void;
  (e: 'cancel'): void;
}

const props = defineProps<Props>();
const emit = defineEmits<Emits>();

const lookupsStore = useLookupsStore();

// Refs
const formRef = ref<any>(null);
const loading = ref(false);

// Form state
const form = ref<{
  afName: string;
  afType: number | null;
  raOrgSender: number | null;
  afNum: number | null;
  afExecute: boolean;
  afSource: boolean;
}>({
  afName: '',
  afType: null,
  raOrgSender: null,
  afNum: null,
  afExecute: false,
  afSource: false
});

// Computed
const isEdit = computed(() => !!props.file);

const fileTypesOptions = computed(() => lookupsStore.fileTypesOptions);
const organizationsOptions = computed(() => lookupsStore.organizationsOptions);

// Watchers
watch(
  () => props.modelValue,
  (isOpen) => {
    if (isOpen) {
      loadLookups();
      if (props.file) {
        // Режим редактирования
        form.value = {
          afName: props.file.afName,
          afType: props.file.afType,
          raOrgSender: props.file.raOrgSender ?? null,
          afNum: props.file.afNum ?? null,
          afExecute: props.file.afExecute,
          afSource: props.file.afSource ?? false
        };
      } else {
        // Режим создания
        resetForm();
      }
    }
  }
);

// Methods
async function loadLookups() {
  // Используем force = true для гарантии загрузки свежих данных при открытии диалога
  await lookupsStore.loadAllLookups(true);
}

function resetForm() {
  form.value = {
    afName: '',
    afType: null,
    raOrgSender: null,
    afNum: null,
    afExecute: false,
    afSource: false
  };
  formRef.value?.resetValidation();
}

async function handleSubmit() {
  const isValid = await formRef.value?.validate();
  if (!isValid) return;

  const data = {
    afName: form.value.afName,
    afDir: props.dirId,
    afType: form.value.afType!,
    afExecute: form.value.afExecute,
    afSource: form.value.afSource,
    raOrgSender: form.value.raOrgSender ?? undefined,
    afNum: form.value.afNum ?? undefined
  };

  emit('save', data);
}

function handleCancel() {
  emit('cancel');
  emit('update:modelValue', false);
}
</script>
