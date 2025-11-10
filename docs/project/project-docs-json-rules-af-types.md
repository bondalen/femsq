# Правила описания типов артефактов модулей

**Версия:** 1.0.0  
**Дата создания:** 2025-01-27  
**Последнее обновление:** 2025-11-10  
**Статус:** Активный  
**Применимость:** Универсальный справочник для любых проектов

---

## Назначение

Этот документ определяет стандартизированную систему типов артефактов для описания структуры модулей в файле `project-docs.json`. Система применима к проектам на различных технологических стеках.

---

## Три базовые сущности

### 1. Module (Модуль)
**Определение:** Независимая единица сборки с собственной конфигурацией

**Физическое представление:**
- 📁 Директория с файлами сборки
- Содержит: конфигурацию сборки, исходный код, ресурсы

**Примеры:**
- Maven/Gradle модуль (`pom.xml`, `build.gradle`)
- NPM пакет (`package.json`)
- Python пакет (`setup.py`, `pyproject.toml`)

**Атрибут `artifact_type`:** `"directory"`

---

### 2. Component (Компонент)
**Определение:** Логическая группировка связанных классов/файлов

**Физическое представление:**
- 📁 Директория с исходными файлами
- Не имеет собственной конфигурации сборки

**Примеры:**
- Java package (`com.example.service`)
- Vue/React директория компонентов (`src/components/auth/`)
- Python module (папка с `__init__.py`)

**Атрибут `artifact_type`:** `"directory"`

---

### 3. Class (Класс)
**Определение:** Единица кода (класс, компонент, модуль)

**Физическое представление:**
- 📄 Файл с кодом
- Может содержать вложенные классы (nested)

**Примеры:**
- Java class/interface/enum (`.java`)
- Vue component (`.vue`)
- TypeScript class/interface (`.ts`)

**Атрибут `artifact_type`:** `"file"` или `"nested"`

---

## Обязательные атрибуты

### Для всех артефактов:

```json
{
  "id": "Уникальный идентификатор",
  "number": "Структурный номер (01.01.01)",
  "name": "Имя артефакта",
  "description": "Описание назначения",
  "status": "planned | in_progress | completed | deprecated",
  "artifact": {
    "location": "Логическое расположение (package/namespace)",
    "file_path": "Физический путь в файловой системе",
    "type": "Конкретный тип артефакта (см. справочник ниже)",
    "artifact_type": "directory | file | nested"
  }
}
```

---

## Справочник типов артефактов

### Backend: Java/Spring

#### Module types:
- `maven-module` - корневой Maven проект
- `maven-submodule` - Maven субмодуль
- `gradle-module` - Gradle модуль
- `spring-boot-app` - Spring Boot приложение

#### Component types:
- `java-package` - Java пакет

#### Class types:
- `java-class` - Java класс
- `java-interface` - Java интерфейс
- `java-enum` - Java перечисление
- `java-record` - Java record (Java 14+)
- `java-annotation` - Java аннотация
- `nested-class` - Вложенный класс

**Пример Module:**
```json
{
  "module": {
    "displayName": "Backend Module. № 01",
    "attributes": {
      "id": "backend",
      "number": "01",
      "name": "Backend Module",
      "description": "Основной backend модуль приложения",
      "status": "planned",
      "artifact": {
        "location": "project-backend/",
        "file_path": "project-backend/",
        "type": "maven-module",
        "artifact_type": "directory",
        "build_file": "pom.xml"
      }
    }
  }
}
```

**Пример Component:**
```json
{
  "component": {
    "displayName": "Configuration Package. № 01.01.01",
    "attributes": {
      "id": "config",
      "number": "01.01.01",
      "name": "Configuration Package",
      "description": "Пакет для управления конфигурацией",
      "status": "planned",
      "artifact": {
        "location": "com.example.database.config",
        "file_path": "src/main/java/com/example/database/config/",
        "type": "java-package",
        "artifact_type": "directory"
      }
    }
  }
}
```

**Пример Class:**
```json
{
  "class": {
    "displayName": "DatabaseConfigService. № 01.01.01.01",
    "attributes": {
      "id": "DatabaseConfigService",
      "number": "01.01.01.01",
      "name": "DatabaseConfigService",
      "description": "Сервис для работы с конфигурацией БД",
      "status": "planned",
      "artifact": {
        "location": "com.example.database.config.DatabaseConfigService",
        "file_path": "src/main/java/com/example/database/config/DatabaseConfigService.java",
        "type": "java-class",
        "artifact_type": "file"
      },
      "responsibilities": [
        "Управление конфигурацией",
        "Интеграция с UI"
      ],
      "dependsOn": ["ConfigFileManager"]
    }
  }
}
```

**Пример Nested Class:**
```json
{
  "class": {
    "displayName": "ConfigValidator. № 01.01.01.01.01",
    "attributes": {
      "id": "ConfigValidator",
      "number": "01.01.01.01.01",
      "name": "ConfigValidator",
      "description": "Вложенный класс для валидации",
      "status": "planned",
      "artifact": {
        "location": "com.example.database.config.DatabaseConfigService.ConfigValidator",
        "file_path": "src/main/java/com/example/database/config/DatabaseConfigService.java",
        "type": "nested-class",
        "artifact_type": "nested",
        "parent_class": "DatabaseConfigService"
      }
    }
  }
}
```

---

### Frontend: Vue.js

#### Module types:
- `npm-package` - NPM пакет
- `vue-module` - Vue.js модуль/приложение

#### Component types:
- `vue-components` - Директория Vue компонентов
- `vue-composables` - Директория composables
- `vue-stores` - Директория store (Pinia/Vuex)

#### Class types:
- `vue-component` - Vue компонент (`.vue`)
- `typescript-class` - TypeScript класс
- `typescript-interface` - TypeScript интерфейс
- `typescript-type` - TypeScript type alias

**Пример Module (Frontend):**
```json
{
  "module": {
    "displayName": "Frontend Module. № 02",
    "attributes": {
      "id": "frontend",
      "number": "02",
      "name": "Frontend Module",
      "description": "Frontend модуль на Vue.js",
      "status": "planned",
      "artifact": {
        "location": "project-frontend/",
        "file_path": "project-frontend/",
        "type": "vue-module",
        "artifact_type": "directory",
        "build_file": "package.json"
      }
    }
  }
}
```

---

## Таблица соответствия

| Артефакт | artifact_type | Физическое | location | file_path |
|----------|---------------|------------|----------|-----------|
| Module | directory | Папка с build файлом | code/femsq-backend/ | code/femsq-backend/ |
| Component | directory | Папка с исходниками | com.femsq.database.config | src/main/java/com/femsq/database/config/ |
| Class | file | Файл с кодом | com.femsq.database.config.DatabaseConfigService | src/.../DatabaseConfigService.java |
| Nested Class | nested | Класс внутри файла | com.femsq...ConfigValidator | src/.../DatabaseConfigService.java |

---

## Группировка атрибутов в `artifact`

Для улучшения читаемости и возможности сворачивания в IDE, все физические атрибуты артефактов группируются в объект `artifact`:

**Преимущества:**
- ✅ Четкая группировка физических атрибутов
- ✅ Легко сворачивать в IDE
- ✅ Логическое разделение: метаданные vs физическое представление
- ✅ Можно добавлять новые атрибуты без загромождения

---

## История версий

| Версия | Дата | Изменения |
|--------|------|-----------|
| 1.0.0 | 2025-01-27 | Первая версия: Java/Spring, Vue.js. Группировка в artifact |

---

**Файл создан:** 2025-01-27  
**Автор:** Александр  
**Применимость:** Универсальный справочник для любых проектов
