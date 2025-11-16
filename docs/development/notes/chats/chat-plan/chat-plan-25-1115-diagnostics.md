# Диагностика проблемы с интеграционными тестами femsq-web

**Дата:** 2025-11-15  
**Выполнено:** Диагностика (02.1)

## Результаты диагностики

### 02.1.1 Структура пакетов и расположение классов

**Проверено:**
- ✅ Главный класс: `com.femsq.web.FemsqWebApplication` находится в `src/main/java/com/femsq/web/`
- ✅ Интеграционные тесты находятся в `src/test/java/com/femsq/web/api/rest/`
- ✅ Пакет тестов: `com.femsq.web.api.rest`
- ✅ Пакет главного класса: `com.femsq.web`
- ✅ `scanBasePackages = {"com.femsq"}` должен покрывать оба пакета

**Структура:**
```
com.femsq.web
  ├── FemsqWebApplication.java (главный класс)
  ├── api/
  │   └── rest/
  │       ├── ApiOrganizationsSuccessIT.java
  │       ├── ApiMissingConfigurationIT.java
  │       └── ConnectionControllerReconnectionIT.java
  └── config/
      ├── CorsConfig.java
      ├── DatabaseModuleConfiguration.java
      ├── GraphQlConfig.java
      ├── SpaController.java
      └── WebMvcConfig.java
```

**Вывод:** Структура пакетов корректна, главный класс должен быть доступен из тестов.

### 02.1.2 Зависимости Spring Boot Test в pom.xml

**Проверено:**
- ✅ `spring-boot-starter-test` версии `3.4.5` присутствует в зависимостях
- ✅ Scope: `test`
- ✅ Версия берется из `${spring.boot.version}` = `3.4.5`

**Конфигурация:**
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <version>${spring.boot.version}</version>
    <scope>test</scope>
</dependency>
```

**Вывод:** Зависимости Spring Boot Test настроены корректно.

### 02.1.3 Конфигурация Maven Failsafe Plugin

**Проверено:**
- ✅ `maven-failsafe-plugin` версии `3.2.5` настроен
- ✅ Профиль `integration` активируется через `-Pintegration`
- ✅ Включены паттерны: `**/*IT.java`, `**/*ITCase.java`, `**/*IntegrationTest.java`
- ✅ Goals: `integration-test`, `verify`

**Конфигурация:**
```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-failsafe-plugin</artifactId>
    <version>3.2.5</version>
    <configuration>
        <argLine>-Dnet.bytebuddy.experimental=true</argLine>
        <includes>
            <include>**/*IT.java</include>
            <include>**/*ITCase.java</include>
            <include>**/*IntegrationTest.java</include>
        </includes>
    </configuration>
    <executions>
        <execution>
            <goals>
                <goal>integration-test</goal>
                <goal>verify</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

**Вывод:** Конфигурация Maven Failsafe Plugin корректна.

### 02.1.4 Детальная информация об ошибке

**Ошибка:**
```
java.lang.IllegalStateException: Failed to find merged annotation for 
@org.springframework.test.context.BootstrapWith(org.springframework.boot.test.context.SpringBootTestContextBootstrapper.class)
```

**Stack trace:**
```
at org.springframework.util.Assert.state(Assert.java:101)
at org.springframework.test.context.TestContextAnnotationUtils$AnnotationDescriptor.<init>(TestContextAnnotationUtils.java:527)
at org.springframework.test.context.TestContextAnnotationUtils.findAnnotationDescriptor(TestContextAnnotationUtils.java:266)
at org.springframework.test.context.TestContextAnnotationUtils.findAnnotationDescriptor(TestContextAnnotationUtils.java:228)
at org.springframework.test.context.BootstrapUtils.resolveExplicitTestContextBootstrapper(BootstrapUtils.java:175)
at org.springframework.test.context.BootstrapUtils.resolveTestContextBootstrapper(BootstrapUtils.java:150)
at org.springframework.test.context.BootstrapUtils.resolveTestContextBootstrapper(BootstrapUtils.java:126)
at org.springframework.test.context.TestContextManager.<init>(TestContextManager.java:126)
at org.springframework.test.context.junit.jupiter.SpringExtension.getTestContextManager(SpringExtension.java:362)
at org.springframework.test.context.junit.jupiter.SpringExtension.postProcessTestInstance(SpringExtension.java:157)
```

**Затронутые тесты:**
1. `ApiOrganizationsSuccessIT` - ошибка при инициализации
2. `ApiMissingConfigurationIT` - ошибка при инициализации
3. `ConnectionControllerReconnectionIT` - ошибка при инициализации

**Конфигурация тестов:**
Все три теста используют:
```java
@SpringBootTest(classes = FemsqWebApplication.class, webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
```

**Анализ ошибки:**
- Spring Boot не может найти merged annotation для `@BootstrapWith`
- Это происходит на этапе инициализации тестового контекста
- Проблема возникает до попытки загрузить `FemsqWebApplication`
- Это указывает на проблему с classpath или версией Spring Boot

## Выводы

### Корневая причина
Проблема связана с тем, что Spring Boot Test Framework не может правильно обработать аннотацию `@SpringBootTest` при запуске через Maven Failsafe Plugin. Это может быть связано с:

1. **Проблема с classpath:** Класс `FemsqWebApplication` может не быть доступен в classpath тестов при запуске через Failsafe Plugin
2. **Проблема с версией Spring Boot 3.4.5:** Возможны изменения в механизме обработки аннотаций
3. **Проблема с порядком загрузки классов:** Spring Boot не может найти merged annotation до загрузки главного класса

### Рекомендации

**Приоритет 1: Проверить classpath**
- Убедиться, что `FemsqWebApplication` компилируется и доступен в classpath тестов
- Проверить, что Maven правильно включает main классы в test classpath

**Приоритет 2: Использовать @TestConfiguration**
- Создать явную тестовую конфигурацию
- Это обойдет проблему с автоматическим обнаружением

**Приоритет 3: Проверить совместимость версий**
- Проверить известные проблемы Spring Boot 3.4.5 с интеграционными тестами
- Рассмотреть возможность временного отката до 3.3.5 для проверки

## Следующие шаги

1. ✅ Диагностика завершена
2. ⏳ Выбрать вариант решения (02.2)
3. ⏳ Реализовать выбранное решение (02.3)

