# Предложение: Объединение Backend и Frontend в единый JAR

## Текущее состояние

### Документация проекта
Согласно `docs/project/project-docs.json`:
- **Архитектура:** `"type": "full-stack"`
- **Frontend serving:** `"serving": "Spring Boot Static Resources"`
- **Deployment:** `"deployment": "Spring Boot Fat JAR"`
- **Frontend URL:** `"frontend": "http://localhost:8080 (встроенный в JAR)"`
- **Описание сборки:** `"Сборка единого JAR-файла с встроенным frontend"`

### Текущая реализация
- ❌ Frontend собирается отдельно через `npm run build` в `code/femsq-frontend-q/dist/`
- ❌ Backend собирается отдельно через `mvn package` в `code/femsq-backend/femsq-web/target/`
- ❌ Нет автоматизации объединения в единый артефакт
- ❌ Нет конфигурации Spring Boot для обслуживания статических ресурсов
- ❌ Нет конфигурации для SPA routing (Vue Router)

## Предлагаемое решение

### Вариант 1: Maven + frontend-maven-plugin (РекОМЕНДУЕТСЯ)

**Преимущества:**
- Автоматическая сборка frontend при сборке backend
- Интеграция в Maven lifecycle
- Единая команда сборки: `mvn clean package`
- Стандартный подход для Spring Boot + Vue.js

**Реализация:**

1. **Добавить frontend-maven-plugin в `femsq-web/pom.xml`:**
```xml
<plugin>
    <groupId>com.github.eirslett</groupId>
    <artifactId>frontend-maven-plugin</artifactId>
    <version>1.15.0</version>
    <configuration>
        <workingDirectory>../../femsq-frontend-q</workingDirectory>
        <installDirectory>${project.build.directory}/frontend</installDirectory>
    </configuration>
    <executions>
        <execution>
            <id>install node and npm</id>
            <goals>
                <goal>install-node-and-npm</goal>
            </goals>
            <configuration>
                <nodeVersion>v20.10.0</nodeVersion>
                <npmVersion>10.2.4</npmVersion>
            </configuration>
        </execution>
        <execution>
            <id>npm install</id>
            <goals>
                <goal>npm</goal>
            </goals>
            <configuration>
                <arguments>install</arguments>
            </configuration>
        </execution>
        <execution>
            <id>npm run build</id>
            <goals>
                <goal>npm</goal>
            </goals>
            <configuration>
                <arguments>run build</arguments>
            </configuration>
        </execution>
    </executions>
</plugin>
```

2. **Добавить maven-resources-plugin для копирования dist в static:**
```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-resources-plugin</artifactId>
    <version>3.3.1</version>
    <executions>
        <execution>
            <id>copy-frontend</id>
            <phase>process-resources</phase>
            <goals>
                <goal>copy-resources</goal>
            </goals>
            <configuration>
                <outputDirectory>${project.build.outputDirectory}/static</outputDirectory>
                <resources>
                    <resource>
                        <directory>../../femsq-frontend-q/dist</directory>
                        <filtering>false</filtering>
                    </resource>
                </resources>
            </configuration>
        </execution>
    </executions>
</plugin>
```

3. **Создать конфигурацию Spring Boot для статических ресурсов:**
```java
@Configuration
public class WebMvcConfig implements WebMvcConfigurer {
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/**")
                .addResourceLocations("classpath:/static/")
                .resourceChain(false);
    }

    @Override
    public void addViewControllers(ViewControllerRegistry registry) {
        registry.addViewController("/").setViewName("forward:/index.html");
    }
}
```

4. **Создать контроллер для SPA routing:**
```java
@Controller
public class SpaController {
    @RequestMapping(value = {
        "/organizations",
        "/connection",
        "/{path:[^\\.]*}"
    })
    public String forward() {
        return "forward:/index.html";
    }
}
```

### Вариант 2: Отдельный скрипт сборки

**Преимущества:**
- Простота реализации
- Не требует изменений в Maven

**Недостатки:**
- Две команды вместо одной
- Менее интегрировано

**Реализация:**

Создать скрипт `scripts/build-full-stack.sh`:
```bash
#!/bin/bash
set -e

echo "Building frontend..."
cd code/femsq-frontend-q
npm install
npm run build

echo "Copying frontend to backend resources..."
mkdir -p ../femsq-backend/femsq-web/src/main/resources/static
cp -r dist/* ../femsq-backend/femsq-web/src/main/resources/static/

echo "Building backend..."
cd ../femsq-backend
mvn clean package -DskipTests

echo "Full-stack JAR created: femsq-web/target/femsq-web-0.1.0-SNAPSHOT.jar"
```

### Вариант 3: Docker-based сборка

**Преимущества:**
- Изоляция окружений
- Воспроизводимость

**Недостатки:**
- Требует Docker
- Более сложная настройка

## Рекомендация

**Рекомендуется Вариант 1** (Maven + frontend-maven-plugin), так как:
1. Соответствует требованиям документации ("Сборка единого JAR-файла")
2. Автоматизирует весь процесс
3. Интегрируется в существующий Maven workflow
4. Стандартный подход для Spring Boot приложений

## План реализации

### Этап 1: Настройка Maven (1-2 часа)
1. Добавить `frontend-maven-plugin` в `femsq-web/pom.xml`
2. Добавить `maven-resources-plugin` для копирования dist
3. Настроить пути относительно корня проекта

### Этап 2: Конфигурация Spring Boot (30 минут)
1. Создать `WebMvcConfig` для статических ресурсов
2. Создать `SpaController` для SPA routing
3. Настроить порядок обработки запросов (API → Static → SPA)

### Этап 3: Тестирование (1 час)
1. Собрать единый JAR: `mvn clean package`
2. Запустить: `java -jar femsq-web-0.1.0-SNAPSHOT.jar`
3. Проверить:
   - Frontend доступен на `http://localhost:8080/`
   - API доступен на `http://localhost:8080/api/v1/...`
   - Vue Router работает (переходы между страницами)

### Этап 4: Обновление документации (30 минут)
1. Обновить `deployment-guide.md` с инструкциями по сборке full-stack
2. Обновить `project-docs.json` с подтверждением реализации

## Дополнительные соображения

### API Base URL
При встраивании frontend в JAR, API base URL должен быть относительным.

**Текущая реализация:**
В `code/femsq-frontend-q/src/api/http.ts` используется:
```typescript
const RAW_BASE_URL = (import.meta.env.VITE_API_BASE_URL as string | undefined) ?? 'http://localhost:8080';
```

**Решение:**
1. Для production сборки установить `VITE_API_BASE_URL=/api/v1` или пустую строку
2. Обновить `vite.config.ts` для использования относительных путей при production build:
```typescript
export default defineConfig({
  // ... existing config
  build: {
    rollupOptions: {
      output: {
        // Ensure relative paths for assets
      }
    }
  },
  base: process.env.NODE_ENV === 'production' ? '/' : '/'
});
```

3. Обновить `http.ts` для поддержки относительных путей:
```typescript
const RAW_BASE_URL = (import.meta.env.VITE_API_BASE_URL as string | undefined) ?? 
  (import.meta.env.PROD ? '' : 'http://localhost:8080');
```

### Production vs Development
- **Development:** Frontend на Vite dev server (port 5175), Backend на Spring Boot (port 8080)
- **Production:** Все в одном JAR, один порт (8080)

### CORS
При объединении в один JAR CORS не нужен, но текущая конфигурация не помешает.

## Оценка времени

- **Настройка Maven:** 1-2 часа
- **Конфигурация Spring Boot:** 30 минут
- **Тестирование:** 1 час
- **Документация:** 30 минут
- **Итого:** ~3-4 часа

## Следующие шаги

1. Реализовать Вариант 1 (Maven + frontend-maven-plugin)
2. Протестировать сборку и запуск
3. Обновить `deployment-guide.md`
4. Обновить `project-docs.json` с подтверждением реализации

