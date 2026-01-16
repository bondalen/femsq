<template>
  <v-dialog
    :model-value="modelValue"
    @update:model-value="$emit('update:modelValue', $event)"
    max-width="600"
    persistent
  >
    <v-card>
      <v-card-title class="d-flex align-center bg-primary">
        <v-icon icon="mdi-file-document-edit-outline" class="mr-2" />
        {{ isEdit ? 'Редактирование файла' : 'Добавление файла' }}
      </v-card-title>
      
      <v-card-text class="pt-4">
        <v-form ref="formRef" v-model="valid" @submit.prevent="handleSubmit">
          <v-text-field
            v-model="form.afName"
            label="Имя файла *"
            :rules="[rules.required, rules.maxLength(500)]"
            variant="outlined"
            density="comfortable"
            counter="500"
            hint="Полное имя файла с расширением"
            persistent-hint
          />
          
          <v-select
            v-model="form.afType"
            :items="fileTypesOptions"
            label="Тип файла *"
            :rules="[rules.required]"
            variant="outlined"
            density="comfortable"
            item-title="label"
            item-value="value"
            :loading="loadingLookups"
          />
          
          <v-select
            v-model="form.raOrgSender"
            :items="organizationsOptions"
            label="Отправитель"
            variant="outlined"
            density="comfortable"
            item-title="label"
            item-value="value"
            :loading="loadingLookups"
            clearable
            hint="Организация-отправитель (необязательно)"
            persistent-hint
          />
          
          <v-row>
            <v-col cols="12" md="6">
              <v-text-field
                v-model.number="form.afNum"
                label="Номер по порядку"
                type="number"
                variant="outlined"
                density="comfortable"
                hint="Для сортировки файлов"
                persistent-hint
              />
            </v-col>
            
            <v-col cols="12" md="6">
              <v-checkbox
                v-model="form.afExecute"
                label="Подлежит рассмотрению"
                density="comfortable"
                hide-details
              />
              
              <v-checkbox
                v-model="form.afSource"
                label="Брать данные из Excel"
                density="comfortable"
                hide-details
              />
            </v-col>
          </v-row>
        </v-form>
      </v-card-text>
      
      <v-divider />
      
      <v-card-actions>
        <v-spacer />
        <v-btn
          variant="text"
          @click="handleCancel"
          :disabled="saving"
        >
          Отмена
        </v-btn>
        <v-btn
          color="primary"
          variant="flat"
          @click="handleSubmit"
          :loading="saving"
          :disabled="!valid"
        >
          {{ isEdit ? 'Сохранить' : 'Создать' }}
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, watch, computed } from 'vue'
import type { RaFDto, RaFCreateRequest, RaFUpdateRequest } from '@/types/files'
import { useLookupsStore } from '@/stores/lookups'

interface Props {
  modelValue: boolean
  file?: RaFDto | null
  dirId: number
}

interface Emits {
  (e: 'update:modelValue', value: boolean): void
  (e: 'save', data: RaFCreateRequest | RaFUpdateRequest): void
  (e: 'cancel'): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

const lookupsStore = useLookupsStore()

// Form state
const formRef = ref<any>(null)
const valid = ref(false)
const saving = ref(false)

const form = ref<{
  afName: string
  afType: number | null
  afExecute: boolean
  afSource: boolean | null
  raOrgSender: number | null
  afNum: number | null
}>({
  afName: '',
  afType: null,
  afExecute: true,
  afSource: false,
  raOrgSender: null,
  afNum: null
})

// Computed
const isEdit = computed(() => !!props.file)

const fileTypesOptions = computed(() => lookupsStore.fileTypesOptions)
const organizationsOptions = computed(() => lookupsStore.organizationsOptions)

const loadingLookups = computed(() => 
  lookupsStore.loadingFileTypes || lookupsStore.loadingOrganizations
)

// Validation rules
const rules = {
  required: (v: any) => !!v || 'Обязательное поле',
  maxLength: (max: number) => (v: string) => 
    !v || v.length <= max || `Максимум ${max} символов`
}

// Watchers
watch(() => props.modelValue, (isOpen) => {
  if (isOpen) {
    loadLookups()
    resetForm()
    if (props.file) {
      loadFileData(props.file)
    }
  }
})

// Methods
async function loadLookups() {
  await lookupsStore.loadAllLookups()
}

function resetForm() {
  form.value = {
    afName: '',
    afType: null,
    afExecute: true,
    afSource: false,
    raOrgSender: null,
    afNum: null
  }
  formRef.value?.resetValidation()
}

function loadFileData(file: RaFDto) {
  form.value = {
    afName: file.afName,
    afType: file.afType,
    afExecute: file.afExecute,
    afSource: file.afSource,
    raOrgSender: file.raOrgSender,
    afNum: file.afNum
  }
}

async function handleSubmit() {
  const { valid: isValid } = await formRef.value.validate()
  if (!isValid) return
  
  saving.value = true
  
  try {
    const data: RaFCreateRequest | RaFUpdateRequest = {
      afName: form.value.afName,
      afDir: props.dirId,
      afType: form.value.afType!,
      afExecute: form.value.afExecute,
      afSource: form.value.afSource,
      raOrgSender: form.value.raOrgSender,
      afNum: form.value.afNum
    }
    
    emit('save', data)
  } finally {
    saving.value = false
  }
}

function handleCancel() {
  emit('cancel')
  emit('update:modelValue', false)
}
</script>
