# PlantUML Диаграммы FEMSQ

**Дата создания:** 2025-01-27  
**Версия:** 1.0.0

## Список диаграмм

### 1. database-module-classes.puml
**Диаграмма классов модуля Database**
- Показывает все классы модуля database
- Пакеты: config, connection, auth, model
- Интерфейсы и реализации провайдеров аутентификации

### 2. components.puml
**Диаграмма компонентов FEMSQ**
- Backend (Spring Boot) и Frontend (Vue.js)
- Взаимодействие с MS SQL Server
- Файлы конфигурации

### 3. first-run-sequence.puml
**Последовательность первого запуска**
- Шаги от запуска JAR до настройки подключения
- Взаимодействие пользователя с системой
- API вызовы и сохранение конфигурации

### 4. package-structure.puml
**Структура пакетов Java**
- Иерархия пакетов com.femsq.*
- Классы в каждом пакете
- Организация кода

---

## Как использовать

### Просмотр в VS Code/Cursor
1. Установите расширение PlantUML
2. Откройте .puml файл
3. Нажмите Alt+D для предпросмотра

### Генерация изображений
```bash
# Установка PlantUML (если не установлен)
sudo apt install plantuml

# Генерация PNG
plantuml database-module-classes.puml

# Генерация SVG
plantuml -tsvg database-module-classes.puml
```

### Онлайн просмотр
Скопируйте содержимое .puml файла на:
- https://www.plantuml.com/plantuml/uml/

---

## Обновление диаграмм

При изменении архитектуры **обязательно** обновляйте диаграммы:
1. Редактируйте .puml файл
2. Проверьте корректность синтаксиса
3. Обновите дату в project-docs.json

**Версия PlantUML:** Используется стандартный синтаксис PlantUML