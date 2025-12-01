# Обновление JasperReports до версии 7.0.3

**Дата:** 2025-11-27  
**Автор:** Александр  
**Версия:** 1.0

## Причина обновления

Jaspersoft Studio 7.0.3 создаёт отчёты с атрибутами, не поддерживаемыми в JasperReports 6.21.0:
- `forPrompting` в параметрах
- `uuid` в корневом элементе (удалён ранее)
- Другие атрибуты новой версии

Обновление до 7.0.3 устраняет необходимость постоянного исправления отчётов.

## Выполненные изменения

### 1. Обновление зависимостей (`femsq-reports/pom.xml`)

- **Версия:** `6.21.0` → `7.0.3`
- **Добавлена зависимость:** `jasperreports-pdf` (PDF экспортер вынесен в отдельный модуль)

```xml
<properties>
    <jasperreports.version>7.0.3</jasperreports.version>
</properties>

<dependencies>
    <!-- JasperReports Core -->
    <dependency>
        <groupId>net.sf.jasperreports</groupId>
        <artifactId>jasperreports</artifactId>
        <version>${jasperreports.version}</version>
    </dependency>
    
    <!-- JasperReports PDF Export (отдельный модуль в 7.0.3) -->
    <dependency>
        <groupId>net.sf.jasperreports</groupId>
        <artifactId>jasperreports-pdf</artifactId>
        <version>${jasperreports.version}</version>
    </dependency>
    
    <!-- Остальные зависимости остались без изменений -->
</dependencies>
```

### 2. Обновление импортов (`ReportGenerationService.java`)

**Изменения в API экспортеров:**

- **PDF экспортер:** перемещён в отдельный пакет
  - Старый: `net.sf.jasperreports.engine.export.JRPdfExporter`
  - Новый: `net.sf.jasperreports.pdf.JRPdfExporter`
  - Конфигурация: `net.sf.jasperreports.pdf.SimplePdfExporterConfiguration`

- **Excel и HTML экспортеры:** остались в прежних пакетах
  - Excel: `net.sf.jasperreports.engine.export.ooxml.JRXlsxExporter`
  - HTML: `net.sf.jasperreports.engine.export.HtmlExporter`

### 3. Обновление документации

- `docs/project/project-docs.json`: версия обновлена до `7.0.3`

## Совместимость

✅ **Spring Boot 3.4.5:** полностью совместимо  
✅ **Java 21:** полностью совместимо  
✅ **Jakarta EE:** поддерживается (Spring Boot 3.x использует Jakarta)

## Важные замечания

### Существующие отчёты

Отчёты, созданные в Jaspersoft Studio 7.0.3, теперь работают без исправлений:
- ✅ Атрибут `forPrompting` поддерживается
- ✅ Все новые атрибуты версии 7.0.3 поддерживаются

### Отчёты версии 6.x

Если у вас есть старые отчёты (созданные в версии 6.x), рекомендуется:
1. Открыть их в Jaspersoft Studio 7.0.3
2. Выполнить: `Правый клик > JasperReports > Обновить файлы JasperReports`
3. Сохранить обновлённые файлы

**Примечание:** Все текущие отчёты уже созданы в Studio 7.0.3, поэтому дополнительных действий не требуется.

## Тестирование

После обновления необходимо протестировать:
- ✅ Компиляция проекта: **УСПЕШНО**
- ⏳ Генерация PDF отчётов
- ⏳ Генерация Excel отчётов
- ⏳ Генерация HTML отчётов
- ⏳ Работа всех встроенных отчётов

## Следующие шаги

1. **Собрать fat JAR** и протестировать генерацию отчётов
2. **Проверить все встроенные отчёты:**
   - `contractor-card`
   - `objects-list`
   - `contractor-with-objects`
   - `my-new-report`
3. **Убедиться, что отчёты открываются без ошибок**

## Ссылки

- [JasperReports 7.0.3 Release Notes](https://community.jaspersoft.com/documentation)
- [Migration Guide 6.x → 7.x](https://community.jaspersoft.com/forums/topic/69820-what-changes-were-made-from-version-6206-to-version-703-of-jaspersoft-studio/)



