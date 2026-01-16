/**
 * Pinia store для управления файлами ревизий (ra_f)
 */

import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { RaFDto, RaFCreateRequest, RaFUpdateRequest } from '@/types/files'
import * as filesApi from '@/api/files-api'

export const useFilesStore = defineStore('files', () => {
  // State
  const files = ref<RaFDto[]>([])
  const currentDirId = ref<number | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  // Getters
  const filesByDirId = computed(() => (dirId: number) => {
    return files.value.filter(file => file.afDir === dirId)
  })

  const fileById = computed(() => (id: number) => {
    return files.value.find(file => file.afKey === id)
  })

  const filesByType = computed(() => (typeId: number) => {
    return files.value.filter(file => file.afType === typeId)
  })

  const sortedFiles = computed(() => {
    return [...files.value].sort((a, b) => {
      // Сортировка по af_num, затем по af_key
      if (a.afNum !== null && b.afNum !== null) {
        return a.afNum - b.afNum
      }
      if (a.afNum !== null) return -1
      if (b.afNum !== null) return 1
      return a.afKey - b.afKey
    })
  })

  // Actions
  async function loadByDirId(dirId: number) {
    loading.value = true
    error.value = null
    currentDirId.value = dirId
    
    try {
      const data = await filesApi.getFilesByDirId(dirId)
      files.value = data
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Ошибка загрузки файлов'
      console.error('Failed to load files:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  async function loadAll() {
    loading.value = true
    error.value = null
    
    try {
      const data = await filesApi.getAllFiles()
      files.value = data
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Ошибка загрузки файлов'
      console.error('Failed to load all files:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  async function loadById(id: number) {
    loading.value = true
    error.value = null
    
    try {
      const data = await filesApi.getFileById(id)
      // Обновляем или добавляем файл в список
      const index = files.value.findIndex(f => f.afKey === id)
      if (index >= 0) {
        files.value[index] = data
      } else {
        files.value.push(data)
      }
      return data
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Ошибка загрузки файла'
      console.error('Failed to load file:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  async function create(request: RaFCreateRequest) {
    loading.value = true
    error.value = null
    
    try {
      const created = await filesApi.createFile(request)
      files.value.push(created)
      return created
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Ошибка создания файла'
      console.error('Failed to create file:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  async function update(id: number, request: RaFUpdateRequest) {
    loading.value = true
    error.value = null
    
    try {
      const updated = await filesApi.updateFile(id, request)
      const index = files.value.findIndex(f => f.afKey === id)
      if (index >= 0) {
        files.value[index] = updated
      }
      return updated
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Ошибка обновления файла'
      console.error('Failed to update file:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  async function deleteFile(id: number) {
    loading.value = true
    error.value = null
    
    try {
      await filesApi.deleteFile(id)
      const index = files.value.findIndex(f => f.afKey === id)
      if (index >= 0) {
        files.value.splice(index, 1)
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Ошибка удаления файла'
      console.error('Failed to delete file:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  function clearFiles() {
    files.value = []
    currentDirId.value = null
    error.value = null
  }

  return {
    // State
    files,
    currentDirId,
    loading,
    error,
    
    // Getters
    filesByDirId,
    fileById,
    filesByType,
    sortedFiles,
    
    // Actions
    loadByDirId,
    loadAll,
    loadById,
    create,
    update,
    deleteFile,
    clearFiles
  }
})
