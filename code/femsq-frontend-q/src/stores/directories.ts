/**
 * Pinia store для управления директориями (ra_dir)
 */

import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { DirectoryDto } from '@/types/files'
import * as directoriesApi from '@/api/directories-api'

export const useDirectoriesStore = defineStore('directories', () => {
  // State
  const directories = ref<DirectoryDto[]>([])
  const currentDirectory = ref<DirectoryDto | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  // Getters
  const directoryById = computed(() => (id: number) => {
    return directories.value.find(dir => dir.key === id)
  })

  const directoriesOptions = computed(() => {
    return directories.value.map(dir => ({
      value: dir.key,
      label: dir.dirName
    }))
  })

  // Actions
  async function loadAll() {
    loading.value = true
    error.value = null
    
    try {
      const data = await directoriesApi.getAllDirectories()
      directories.value = data
      return data
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Ошибка загрузки директорий'
      console.error('Failed to load directories:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  async function loadById(id: number) {
    loading.value = true
    error.value = null
    
    try {
      const data = await directoriesApi.getDirectoryById(id)
      
      // Обновляем или добавляем в список
      const index = directories.value.findIndex(d => d.key === id)
      if (index >= 0) {
        directories.value[index] = data
      } else {
        directories.value.push(data)
      }
      
      return data
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Ошибка загрузки директории'
      console.error('Failed to load directory:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  async function loadByAuditId(auditId: number) {
    loading.value = true
    error.value = null
    
    try {
      const data = await directoriesApi.getDirectoryByAuditId(auditId)
      currentDirectory.value = data
      
      // Также добавляем в общий список
      const index = directories.value.findIndex(d => d.key === data.key)
      if (index >= 0) {
        directories.value[index] = data
      } else {
        directories.value.push(data)
      }
      
      return data
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Ошибка загрузки директории ревизии'
      console.error('Failed to load directory by audit:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  function setCurrentDirectory(directory: DirectoryDto | null) {
    currentDirectory.value = directory
  }

  function clearDirectories() {
    directories.value = []
    currentDirectory.value = null
    error.value = null
  }

  return {
    // State
    directories,
    currentDirectory,
    loading,
    error,
    
    // Getters
    directoryById,
    directoriesOptions,
    
    // Actions
    loadAll,
    loadById,
    loadByAuditId,
    setCurrentDirectory,
    clearDirectories
  }
})
