import { fileURLToPath, URL } from 'node:url';

import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import { quasar, transformAssetUrls } from '@quasar/vite-plugin';

// eslint-disable-next-line import/no-default-export
export default defineConfig({
  plugins: [
    vue({
      template: { transformAssetUrls }
    }),
    quasar({
      sassVariables: 'src/styles/quasar-variables.scss'
    })
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  },
  // Настройки для production build
  base: '/', // Относительные пути для встраивания в Spring Boot JAR
  build: {
    outDir: 'dist', // Директория для production build
    emptyOutDir: true, // Очищать директорию перед сборкой
    // Настройки для корректных путей к assets
    rollupOptions: {
      output: {
        // Имена файлов с хешами для кэширования
        assetFileNames: 'assets/[name]-[hash][extname]',
        chunkFileNames: 'assets/[name]-[hash].js',
        entryFileNames: 'assets/[name]-[hash].js'
      }
    }
  },
  server: {
    port: 5175,
    open: false,
    proxy: {
      // Прокси для API запросов в development режиме
      // Все запросы к /api/* перенаправляются на backend (http://localhost:8080)
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
        secure: false,
        // Сохраняем оригинальный путь запроса
        rewrite: (path) => path
      }
    }
  },
  preview: {
    port: 4175
  }
});
