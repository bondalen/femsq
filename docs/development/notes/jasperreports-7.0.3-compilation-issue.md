# Проблема компиляции отчётов JasperReports 7.0.3 в Spring Boot Fat JAR

**Дата:** 2025-11-28  
**Версия:** 1.0  
**Статус:** Требует решения

## Проблема

При запуске приложения в Spring Boot fat JAR отчёты JasperReports не компилируются с ошибкой:

```
error: cannot find symbol
  symbol: class JREvaluator
  symbol: class JRFillField
  symbol: class JRFillParameter
  package net.sf.jasperreports.engine does not exist
```

## Причина

Компилятор JasperReports использует Java компилятор (`javac`) для компиляции выражений в JRXML файлах. В Spring Boot fat JAR классы находятся в `BOOT-INF/classes/` и `BOOT-INF/lib/`, и компилятор не может найти классы JasperReports в classpath.

## Попытки решения

### 1. Настройка classpath через системные свойства
- Установка `jasperreports.compiler.classpath`
- Проблема: для nested JAR путь содержит `!BOOT-INF/lib/...`, что не является валидным путём к файлу

### 2. Использование JREvaluatorCompiler
- Установка `jasperreports.compiler=net.sf.jasperreports.compilers.JREvaluatorCompiler`
- Проблема: всё равно использует Java компилятор для компиляции выражений

### 3. Использование текущего classloader
- Установка `jasperreports.compiler.use.current.classloader=true`
- Проблема: не решает проблему с компилятором

## Возможные решения

### Вариант 1: Предкомпиляция отчётов
Компилировать отчёты на этапе сборки и включать `.jasper` файлы в JAR:

```xml
<plugin>
    <groupId>org.codehaus.mojo</groupId>
    <artifactId>exec-maven-plugin</artifactId>
    <executions>
        <execution>
            <phase>process-resources</phase>
            <goals>
                <goal>java</goal>
            </goals>
            <configuration>
                <mainClass>com.femsq.reports.build.PrecompileReports</mainClass>
            </configuration>
        </execution>
    </executions>
</plugin>
```

**Преимущества:**
- Отчёты компилируются на этапе сборки с полным classpath
- Не требуется компиляция в runtime

**Недостатки:**
- Нужно перекомпилировать при изменении отчётов
- Увеличивает время сборки

### Вариант 2: Использование Groovy компилятора
Если доступен Groovy, использовать Groovy компилятор:

```java
System.setProperty("jasperreports.compiler", "net.sf.jasperreports.compilers.JRGroovyCompiler");
```

**Преимущества:**
- Groovy компилятор может работать с текущим classloader

**Недостатки:**
- Требует зависимости Groovy
- Может быть медленнее

### Вариант 3: Извлечение JAR во временную директорию
Извлечь `jasperreports-7.0.3.jar` из nested JAR во временную директорию и указать путь:

```java
// Извлечь JAR из nested JAR
Path tempJar = extractNestedJar("jasperreports-7.0.3.jar");
System.setProperty("jasperreports.compiler.classpath", tempJar.toString());
```

**Преимущества:**
- Решает проблему с nested JAR

**Недостатки:**
- Требует дополнительного кода
- Временные файлы

### Вариант 4: Использование JavaScript компилятора
Использовать JavaScript компилятор (если доступен):

```java
System.setProperty("jasperreports.compiler", "net.sf.jasperreports.compilers.JRJavaScriptCompiler");
```

**Преимущества:**
- Не требует Java компилятора

**Недостатки:**
- Требует JavaScript движка
- Может быть медленнее

## Текущий статус

- ✅ Fat JAR собран (49 МБ)
- ✅ Thin JAR извлечён (1.6 МБ)
- ✅ DLL библиотеки включены
- ❌ Компиляция отчётов не работает (4 из 4 отчётов не компилируются)

## Рекомендация

Использовать **Вариант 1 (Предкомпиляция отчётов)** - это наиболее надёжное решение, которое:
- Работает в любой среде
- Не требует дополнительных зависимостей
- Гарантирует компиляцию на этапе сборки

## Следующие шаги

1. Создать класс `PrecompileReports` для компиляции отчётов на этапе сборки
2. Настроить Maven plugin для запуска предкомпиляции
3. Включить `.jasper` файлы в JAR вместо `.jrxml`
4. Обновить `ReportGenerationService` для использования предкомпилированных отчётов

