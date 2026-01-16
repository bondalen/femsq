/**
 * Pinia store для управления справочниками (lookups)
 * Типы файлов, организации и другие справочные данные
 */

import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { RaFtDto, OrganizationLookupDto } from '@/types/files'
import * as fileTypesApi from '@/api/file-types-api'
import * as organizationsApi from '@/api/organizations-api'

export const useLookupsStore = defineStore('lookups', () => {
  // State
  const fileTypes = ref<RaFtDto[]>([])
  const organizations = ref<OrganizationLookupDto[]>([])
  const loadingFileTypes = ref(false)
  const loadingOrganizations = ref(false)
  const fileTypesLoaded = ref(false)
  const organizationsLoaded = ref(false)

  // Getters
  const fileTypeById = computed(() => (id: number) => {
    return fileTypes.value.find(ft => ft.ftKey === id)
  })

  const fileTypeNameById = computed(() => (id: number) => {
    const fileType = fileTypes.value.find(ft => ft.ftKey === id)
    return fileType?.ftName ?? `Тип ${id}`
  })

  const organizationById = computed(() => (id: number) => {
    return organizations.value.find(org => org.ogKey === id)
  })

  const organizationNameById = computed(() => (id: number | null) => {
    if (id === null) return 'Не указан'
    const organization = organizations.value.find(org => org.ogKey === id)
    return organization?.ogNm ?? `Организация ${id}`
  })

  const fileTypesOptions = computed(() => {
    return fileTypes.value.map(ft => ({
      value: ft.ftKey,
      label: ft.ftName
    }))
  })

  const organizationsOptions = computed(() => {
    return organizations.value.map(org => ({
      value: org.ogKey,
      label: org.ogNm
    }))
  })

  // Actions
  async function loadFileTypes(force = false) {
    if (fileTypesLoaded.value && !force) {
      return fileTypes.value
    }

    loadingFileTypes.value = true
    
    try {
      const data = await fileTypesApi.getAllFileTypes()
      fileTypes.value = data
      fileTypesLoaded.value = true
      return data
    } catch (err) {
      console.error('Failed to load file types:', err)
      throw err
    } finally {
      loadingFileTypes.value = false
    }
  }

  async function loadOrganizations(force = false) {
    if (organizationsLoaded.value && !force) {
      return organizations.value
    }

    loadingOrganizations.value = true
    
    try {
      const data = await organizationsApi.getOrganizationsLookup()
      organizations.value = data
      organizationsLoaded.value = true
      return data
    } catch (err) {
      console.error('Failed to load organizations:', err)
      throw err
    } finally {
      loadingOrganizations.value = false
    }
  }

  async function loadAllLookups(force = false) {
    await Promise.all([
      loadFileTypes(force),
      loadOrganizations(force)
    ])
  }

  function clearFileTypes() {
    fileTypes.value = []
    fileTypesLoaded.value = false
  }

  function clearOrganizations() {
    organizations.value = []
    organizationsLoaded.value = false
  }

  function clearAll() {
    clearFileTypes()
    clearOrganizations()
  }

  return {
    // State
    fileTypes,
    organizations,
    loadingFileTypes,
    loadingOrganizations,
    fileTypesLoaded,
    organizationsLoaded,
    
    // Getters
    fileTypeById,
    fileTypeNameById,
    organizationById,
    organizationNameById,
    fileTypesOptions,
    organizationsOptions,
    
    // Actions
    loadFileTypes,
    loadOrganizations,
    loadAllLookups,
    clearFileTypes,
    clearOrganizations,
    clearAll
  }
})
