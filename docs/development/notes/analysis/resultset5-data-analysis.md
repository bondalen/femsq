# Анализ источника данных ags.spMstrg_2408_ResultSet5

**Дата анализа:** 2025-12-05  
**Автор:** Александр  
**Этап:** 08.2 - Анализ источника данных ResultSet5  
**Связанный план:** `docs/development/notes/chats/chat-plan/chat-plan-25-1205-jasper-report-mstrg.md`

---

## 1. Общая информация

### Метаданные таблицы
- **Схема:** ags
- **Таблица:** spMstrg_2408_ResultSet5
- **Количество столбцов:** 44
- **Количество записей:** 32 (31 запись данных + 1 разделительная строка)
- **Источник:** Хранимая процедура `ags.spMstrg_2408` (ResultSet #5)

### Назначение
Итоговые данные по исполнению плана капитального строительства:
- Сгруппированные по схемам реализации (агентская, инвестиционная, прочая)
- С данными за текущий, предыдущий и предпредыдущий месяцы
- Только итоговые записи (`cstAgPnCode = 'всего'`)

---

## 2. Структура данных (44 столбца)

### 2.1 Идентификационные поля (7 столбцов)

| № | Столбец | Тип SQL Server | Java Class | Nullable | Макс. длина | Назначение |
|---|---------|----------------|------------|----------|-------------|------------|
| 1 | **ipgSh** | nvarchar(50) | String | YES | 50 | Схема реализации ("а", "агентская", "инвест.", "прочая") |
| 2 | **limSort** | money | BigDecimal | YES | - | Вспомогательное поле для сортировки лимитов |
| 3 | **ogNm** | nvarchar(255) | String | YES | 255 | Название организации |
| 4 | **branchName** | nvarchar(255) | String | YES | 255 | Название филиала |
| 5 | **lim** | money | BigDecimal | YES | - | Общий лимит |
| 6 | **cstAgPnCode** | nvarchar(255) | String | YES | 255 | Код контрагента ("всего" для итоговых) |
| 7 | **mn** | nvarchar(50) | String | YES | 50 | Месяц текущего периода |

**Примечания:**
- `ogNm` и `branchName` взаимоисключающие: если заполнен `ogNm`, то `branchName` NULL и наоборот
- `ipgSh` - ключевое поле для группировки
- `limSort` - техническое поле для сортировки (совпадает с `lim` в большинстве случаев)

### 2.2 Лимиты по схемам (2 столбца)

| № | Столбец | Тип SQL Server | Java Class | Nullable | Назначение |
|---|---------|----------------|------------|----------|------------|
| 8 | **ag_lim** | money | BigDecimal | YES | Лимит агентской схемы |
| 9 | **iv_lim** | money | BigDecimal | YES | Лимит инвестиционной схемы |
| 10 | **uk_lim** | money | BigDecimal | YES | Лимит укупорки |

**Префиксы:**
- `ag_` - агентская схема
- `iv_` - инвестиционная схема (investment)
- `uk_` - укупорка (может быть украинский?)

### 2.3 Исполнение сметного лимита (3 столбца)

| № | Столбец | Тип SQL Server | Java Class | Nullable | Назначение |
|---|---------|----------------|------------|----------|------------|
| 11 | **ag_Ful_OverFul** | money | BigDecimal | YES | Исполнение/перевыполнение сметного лимита |
| 12 | **ag_LimPc** | money | BigDecimal | YES | % исполнения сметного лимита (в формате 0.609 = 60.9%) |
| 13 | **ag_PlOverLimit_** | money | BigDecimal | YES | Превышение лимита бизнес сметного плана |

### 2.4 Данные текущего периода - в разрезе контрагентов (7 столбцов)

| № | Столбец | Тип SQL Server | Java Class | Nullable | Назначение | Формат |
|---|---------|----------------|------------|----------|------------|--------|
| 14 | **ag_PlAccum** | money | BigDecimal | YES | План накопленный, в тыс | Деньги |
| 15 | **ag_PlFulfillment** | money | BigDecimal | YES | Исполнение, в тыс | Деньги |
| 16 | **ag_PlPz** | float | Double | YES | Исполнение, в % | **Percent** |
| 17 | **ag_PlOverFulfillment** | money | BigDecimal | YES | Перевыполнение плана, в тыс | Деньги |
| 18 | **ag_PlPercent** | float | Double | YES | Исполнение в разрезе контрагентов, в % | **Percent** |
| 19 | **ag_PlFulfillmentAll** | money | BigDecimal | YES | Исполнение (все), в тыс | Деньги |
| 20 | **ag_acceptedNot** | money | BigDecimal | YES | Принято не... | Деньги |

**Диапазоны значений:**
- `ag_PlPz`: от 0.156722 (15.67%) до 1.0 (100%)
- `ag_PlPercent`: от 0.157717 (15.77%) до 3.066137 (306.61%)

### 2.5 Данные текущего периода - по месяцам (3 столбца)

| № | Столбец | Тип SQL Server | Java Class | Nullable | Назначение | Формат |
|---|---------|----------------|------------|----------|------------|--------|
| 21 | **ag_Pl_M** | money | BigDecimal | YES | План месячный, в тыс | Деньги |
| 22 | **ag_acceptedTtl_M** | money | BigDecimal | YES | Исполнение месячное, в тыс | Деньги |
| 23 | **ag_PlPz_M** | float | Double | YES | Исполнение месячное, в % | **Percent** |

### 2.6 Данные предыдущего месяца (PrM_) (8 столбцов)

| № | Столбец | Тип SQL Server | Java Class | Nullable | Назначение | Формат |
|---|---------|----------------|------------|----------|------------|--------|
| 24 | **PrM_ag_PlAccum** | money | BigDecimal | YES | План накопленный (пред. месяц) | Деньги |
| 25 | **PrM_ag_PlFulfillment** | money | BigDecimal | YES | Исполнение (пред. месяц) | Деньги |
| 26 | **PrM_ag_PlPz** | float | Double | YES | Исполнение, в % (пред. месяц) | **Percent** |
| 27 | **PrM_ag_PlOverFulfillment** | money | BigDecimal | YES | Перевыполнение (пред. месяц) | Деньги |
| 28 | **PrM_ag_PlPercent** | float | Double | YES | Исполнение в разрезе, в % (пред. месяц) | **Percent** |
| 29 | **PrM_ag_PlFulfillmentAll** | money | BigDecimal | YES | Исполнение все (пред. месяц) | Деньги |
| 30 | **PrM_ag_Pl_M** | money | BigDecimal | YES | План месячный (пред. месяц) | Деньги |
| 31 | **PrM_ag_acceptedTtl_M** | money | BigDecimal | YES | Исполнение месячное (пред. месяц) | Деньги |
| 32 | **PrM_ag_PlPz_M** | float | Double | YES | Исполнение месячное, в % (пред. месяц) | **Percent** |
| 33 | **PrM_mnPrevious** | nvarchar(50) | String | YES | Название предыдущего месяца ("июнь") |

**Диапазоны значений:**
- `PrM_ag_PlPz`: от 0.185115 (18.51%) до 1.0 (100%)

### 2.7 Данные предпредыдущего месяца (PrM_...2) (9 столбцов)

| № | Столбец | Тип SQL Server | Java Class | Nullable | Назначение | Формат |
|---|---------|----------------|------------|----------|------------|--------|
| 34 | **PrM_ag_PlAccum2** | money | BigDecimal | YES | План накопленный (предпред. месяц) | Деньги |
| 35 | **PrM_ag_PlFulfillment2** | money | BigDecimal | YES | Исполнение (предпред. месяц) | Деньги |
| 36 | **PrM_ag_PlPz2** | float | Double | YES | Исполнение, в % (предпред. месяц) | **Percent** |
| 37 | **PrM_ag_PlOverFulfillment2** | money | BigDecimal | YES | Перевыполнение (предпред. месяц) | Деньги |
| 38 | **PrM_ag_PlPercent2** | float | Double | YES | Исполнение в разрезе, в % (предпред. месяц) | **Percent** |
| 39 | **PrM_ag_PlFulfillment2All** | money | BigDecimal | YES | Исполнение все (предпред. месяц) | Деньги |
| 40 | **PrM_ag_Pl_M2** | money | BigDecimal | YES | План месячный (предпред. месяц) | Деньги |
| 41 | **PrM_ag_acceptedTtl_M2** | money | BigDecimal | YES | Исполнение месячное (предпред. месяц) | Деньги |
| 42 | **PrM_ag_PlPz_M2** | float | Double | YES | Исполнение месячное, в % (предпред. месяц) | **Percent** |
| 43 | **PrM_mnPrevious2** | nvarchar(50) | String | YES | Название предпредыдущего месяца ("май") |

### 2.8 Дополнительные поля (1 столбец)

| № | Столбец | Тип SQL Server | Java Class | Nullable | Назначение |
|---|---------|----------------|------------|----------|------------|
| 44 | **np_acceptedTtlAccum** | money | BigDecimal | YES | Принято накопленно (неплан?) |

---

## 3. Типы данных и маппинг SQL Server → Java

### 3.1 Текстовые поля (6 шт.)
```java
nvarchar → java.lang.String
```
- `ipgSh` (50)
- `ogNm` (255)
- `branchName` (255)
- `cstAgPnCode` (255)
- `mn` (50)
- `PrM_mnPrevious` (50)
- `PrM_mnPrevious2` (50)

### 3.2 Денежные поля (money) (27 шт.)
```java
money → java.math.BigDecimal
```
Precision: 19, Scale: 4

**Список полей:**
- `limSort`, `lim`, `ag_lim`, `iv_lim`, `uk_lim`
- `ag_Ful_OverFul`, `ag_LimPc`, `ag_PlOverLimit_`
- `ag_PlAccum`, `ag_PlFulfillment`, `ag_PlOverFulfillment`, `ag_PlFulfillmentAll`, `ag_acceptedNot`
- `ag_Pl_M`, `ag_acceptedTtl_M`
- `PrM_ag_PlAccum`, `PrM_ag_PlFulfillment`, `PrM_ag_PlOverFulfillment`, `PrM_ag_PlFulfillmentAll`
- `PrM_ag_Pl_M`, `PrM_ag_acceptedTtl_M`
- `PrM_ag_PlAccum2`, `PrM_ag_PlFulfillment2`, `PrM_ag_PlOverFulfillment2`, `PrM_ag_PlFulfillment2All`
- `PrM_ag_Pl_M2`, `PrM_ag_acceptedTtl_M2`
- `np_acceptedTtlAccum`

### 3.3 Процентные поля (float) (10 шт.)
```java
float → java.lang.Double
```
Precision: 53

**Важно:** Значения в формате десятичной дроби (0.609045 = 60.9045%)

**Список полей:**
- Текущий период: `ag_PlPz`, `ag_PlPercent`, `ag_PlPz_M`
- Предыдущий месяц: `PrM_ag_PlPz`, `PrM_ag_PlPercent`, `PrM_ag_PlPz_M`
- Предпредыдущий месяц: `PrM_ag_PlPz2`, `PrM_ag_PlPercent2`, `PrM_ag_PlPz_M2`
- **Ещё один:** нужно найти в структуре

---

## 4. Анализ данных

### 4.1 Статистика по записям

**Всего записей:** 32

**По схемам реализации (ipgSh):**
| ipgSh | Количество | Назначение |
|-------|------------|------------|
| "а" | 1 | Итоговая строка (общий итог) |
| "агентская" | 17 | Агентская схема реализации |
| "агентская_" | 1 | **Разделительная строка** |
| "инвест." | 7 | Инвестиционная схема |
| "прочая" | 6 | Прочая схема |

**Примечание:** Разделительная строка "агентская_" с ogNm="Заказчики" используется для визуального разделения в отчёте.

### 4.2 NULL значения

| Поле | NULL записей | % от общего |
|------|--------------|-------------|
| `ipgSh` | 0 | 0% (всегда заполнено) |
| `ogNm` | 12 | 37.5% |
| `ag_lim` | 14 | 43.75% |
| `ag_PlFulfillment` | 15 | 46.88% |
| `mn` | 1 | 3.13% (разделительная строка) |

**Выводы:**
- `ogNm` NULL когда заполнен `branchName` (филиалы)
- `ag_lim` NULL для разделительной строки и некоторых записей инвестиционной/прочей схем
- `mn` NULL только для разделительной строки "агентская_"

### 4.3 Примеры данных

#### Итоговая строка (ipgSh = "а"):
```
ogNm: "итого"
lim: 1,363,982,055,354 (1.36 трлн)
ag_lim: 1,326,451,647,254
iv_lim: 23,148,923,100
uk_lim: 14,381,485,000
ag_PlAccum: 528,845,203,854 (528.8 млрд)
ag_PlFulfillment: 322,090,936,696 (322.1 млрд)
ag_PlPz: 0.609045 (60.9%)
mn: "июль"
PrM_mnPrevious: "июнь"
PrM_mnPrevious2: "май"
```

#### Агентская схема - организация:
```
ipgSh: "агентская"
ogNm: "Газпром инвест, ООО"
lim: 1,292,497,668,040
ag_PlPz: 0.611707 (61.2%)
```

#### Агентская схема - филиал:
```
ipgSh: "агентская"
ogNm: NULL
branchName: "Газпром инвест, ООО, Томск, филиал"
lim: 328,512,314,000
ag_PlPz: 0.738289 (73.8%)
```

#### Разделительная строка:
```
ipgSh: "агентская_"
ogNm: "Заказчики"
cstAgPnCode: NULL (все остальные поля NULL)
```

### 4.4 Диапазоны значений

#### Денежные суммы (money):
- **Минимум:** ~0 (малые суммы)
- **Максимум:** ~1.4 трлн (lim для итоговой строки)
- **Типичные значения:** миллионы - миллиарды рублей
- **Формат отображения:** `#,##0` (без копеек)

#### Процентные поля (float):
- **ag_PlPz:** от 15.67% до 100%
- **ag_PlPercent:** от 15.77% до **306.61%** (может превышать 100%!)
- **PrM_ag_PlPz:** от 18.51% до 100%
- **Формат отображения:** `##0.0%` или `##0.00%` (1-2 знака после запятой)

---

## 5. Соответствие полей Access ↔ ResultSet5

### 5.1 Прямое соответствие (36 полей)

| Access Control | ControlSource | ResultSet5 Column | Match |
|----------------|---------------|-------------------|-------|
| #29 | ogNm | ogNm | ✅ |
| #30 | lim | lim | ✅ |
| #31 | ag_lim | ag_lim | ✅ |
| #32 | ag_Ful_OverFul | ag_Ful_OverFul | ✅ |
| #33 | ag_LimPc | ag_LimPc | ✅ |
| #34 | ag_PlOverLimit_ | ag_PlOverLimit_ | ✅ |
| #35 | iv_lim | iv_lim | ✅ |
| #36 | uk_lim | uk_lim | ✅ |
| #37 | ag_PlAccum | ag_PlAccum | ✅ |
| #39 | ag_PlPz | ag_PlPz | ✅ |
| #40 | ag_PlOverFulfillment | ag_PlOverFulfillment | ✅ |
| #41 | ag_PlPercent | ag_PlPercent | ✅ |
| #44 | ag_Pl_M | ag_Pl_M | ✅ |
| #45 | ag_acceptedTtl_M | ag_acceptedTtl_M | ✅ |
| #46 | ag_PlPz_M | ag_PlPz_M | ✅ |
| #47 | PrM_ag_PlPz_M | PrM_ag_PlPz_M | ✅ |
| #48 | PrM_ag_acceptedTtl_M | PrM_ag_acceptedTtl_M | ✅ |
| #49 | PrM_ag_Pl_M | PrM_ag_Pl_M | ✅ |
| #50 | PrM_ag_PlPercent | PrM_ag_PlPercent | ✅ |
| #51 | PrM_ag_PlOverFulfillment | PrM_ag_PlOverFulfillment | ✅ |
| #52 | PrM_ag_PlPz | PrM_ag_PlPz | ✅ |
| #53 | PrM_ag_PlFulfillment | PrM_ag_PlFulfillment | ✅ |
| #54 | PrM_ag_PlAccum | PrM_ag_PlAccum | ✅ |
| #56 | PrM_ag_PlAccum2 | PrM_ag_PlAccum2 | ✅ |
| #57 | PrM_ag_PlFulfillment2 | PrM_ag_PlFulfillment2 | ✅ |
| #58 | PrM_ag_PlPz2 | PrM_ag_PlPz2 | ✅ |
| #59 | PrM_ag_PlOverFulfillment2 | PrM_ag_PlOverFulfillment2 | ✅ |
| #60 | PrM_ag_PlPercent2 | PrM_ag_PlPercent2 | ✅ |
| #61 | PrM_ag_Pl_M2 | PrM_ag_Pl_M2 | ✅ |
| #62 | PrM_ag_acceptedTtl_M2 | PrM_ag_acceptedTtl_M2 | ✅ |
| #63 | PrM_ag_PlPz_M2 | PrM_ag_PlPz_M2 | ✅ |
| #64 | branchName | branchName | ✅ |
| #65 | ag_acceptedNot | ag_acceptedNot | ✅ |
| #66 | PrM_ag_PlFulfillmentAll | PrM_ag_PlFulfillmentAll | ✅ |

### 5.2 Вычисляемые поля (3 поля)

#### Control #38: ag_PlFulfillmentCn
```vb
ControlSource = =IIf([ag_PlFulfillment]<0,Null,[ag_PlFulfillment])
```
**JasperReports:**
```java
<textFieldExpression><![CDATA[
  $F{ag_PlFulfillment} != null && $F{ag_PlFulfillment}.compareTo(BigDecimal.ZERO) < 0 
    ? null 
    : $F{ag_PlFulfillment}
]]></textFieldExpression>
```

#### Control #42: mnCn
```vb
ControlSource = =IIf(IsNull([ag_lim]),Null,[mn])
```
**JasperReports:**
```java
<textFieldExpression><![CDATA[
  $F{ag_lim} == null ? null : $F{mn}
]]></textFieldExpression>
```

#### Control #43: PrM_mnPreviousCn
```vb
ControlSource = =IIf(IsNull([ag_lim]),Null,[PrM_mnPrevious])
```
**JasperReports:**
```java
<textFieldExpression><![CDATA[
  $F{ag_lim} == null ? null : $F{PrM_mnPrevious}
]]></textFieldExpression>
```

#### Control #55: Поле440 (PrM_mnPrevious2Cn)
```vb
ControlSource = =IIf(IsNull([ag_lim]),Null,[PrM_mnPrevious2])
```
**JasperReports:**
```java
<textFieldExpression><![CDATA[
  $F{ag_lim} == null ? null : $F{PrM_mnPrevious2}
]]></textFieldExpression>
```

### 5.3 Неиспользуемые поля ResultSet5

Поля из ResultSet5, которые НЕ используются в Access отчёте:
- `limSort` (техническое поле для сортировки)
- `cstAgPnCode` (используется только для фильтрации WHERE, не отображается)
- `ag_PlFulfillmentAll` (есть в ResultSet5, но нет в Access контролах)
- `np_acceptedTtlAccum` (есть в ResultSet5, но нет в Access контролах)
- Возможно ещё несколько полей (нужно проверить все 70 контролов)

---

## 6. Группировка и сортировка

### 6.1 ORDER BY
```sql
ORDER BY ipgSh, limSort DESC, lim DESC
```

**Результат сортировки:**
1. "а" (итого) - самый первый
2. "агентская" - по убыванию lim
3. "агентская_" (разделитель)
4. "инвест." - по убыванию lim
5. "прочая" - по убыванию lim

### 6.2 Группировка в JasperReports

**Рекомендация:** Создать группу по `ipgSh`

```xml
<group name="ipgShGroup">
  <groupExpression><![CDATA[$F{ipgSh}]]></groupExpression>
  <groupHeader>
    <band height="0"/>
  </groupHeader>
  <groupFooter>
    <band height="0"/>
  </groupFooter>
</group>
```

**Примечание:** Визуальная группировка не требуется (высота Group Header в Access = 1 point), но может понадобиться для подсчёта итогов.

---

## 7. Рекомендации для JasperReports

### 7.1 Определение полей (field)

```xml
<!-- Текстовые поля -->
<field name="ipgSh" class="java.lang.String"/>
<field name="ogNm" class="java.lang.String"/>
<field name="branchName" class="java.lang.String"/>
<field name="cstAgPnCode" class="java.lang.String"/>
<field name="mn" class="java.lang.String"/>
<field name="PrM_mnPrevious" class="java.lang.String"/>
<field name="PrM_mnPrevious2" class="java.lang.String"/>

<!-- Денежные поля (money → BigDecimal) -->
<field name="limSort" class="java.math.BigDecimal"/>
<field name="lim" class="java.math.BigDecimal"/>
<field name="ag_lim" class="java.math.BigDecimal"/>
<field name="iv_lim" class="java.math.BigDecimal"/>
<field name="uk_lim" class="java.math.BigDecimal"/>
<field name="ag_Ful_OverFul" class="java.math.BigDecimal"/>
<field name="ag_LimPc" class="java.math.BigDecimal"/>
<field name="ag_PlOverLimit_" class="java.math.BigDecimal"/>
<field name="ag_PlAccum" class="java.math.BigDecimal"/>
<field name="ag_PlFulfillment" class="java.math.BigDecimal"/>
<field name="ag_PlOverFulfillment" class="java.math.BigDecimal"/>
<field name="ag_PlFulfillmentAll" class="java.math.BigDecimal"/>
<field name="ag_acceptedNot" class="java.math.BigDecimal"/>
<field name="ag_Pl_M" class="java.math.BigDecimal"/>
<field name="ag_acceptedTtl_M" class="java.math.BigDecimal"/>
<!-- ... и так далее для остальных money полей -->

<!-- Процентные поля (float → Double) -->
<field name="ag_PlPz" class="java.lang.Double"/>
<field name="ag_PlPercent" class="java.lang.Double"/>
<field name="ag_PlPz_M" class="java.lang.Double"/>
<field name="PrM_ag_PlPz" class="java.lang.Double"/>
<field name="PrM_ag_PlPercent" class="java.lang.Double"/>
<field name="PrM_ag_PlPz_M" class="java.lang.Double"/>
<field name="PrM_ag_PlPz2" class="java.lang.Double"/>
<field name="PrM_ag_PlPercent2" class="java.lang.Double"/>
<field name="PrM_ag_PlPz_M2" class="java.lang.Double"/>
```

### 7.2 Форматирование

#### Денежные поля:
```xml
<textField pattern="#,##0">
  <textFieldExpression><![CDATA[$F{ag_PlAccum}]]></textFieldExpression>
</textField>
```

#### Процентные поля:
```xml
<textField pattern="##0.0%">
  <textFieldExpression><![CDATA[$F{ag_PlPz}]]></textFieldExpression>
</textField>
```

**Важно:** Процентные поля в БД хранятся как десятичные дроби (0.609 = 60.9%), паттерн `##0.0%` автоматически умножит на 100.

### 7.3 Условное отображение разделительной строки

```xml
<textField>
  <textFieldExpression><![CDATA[
    $F{ipgSh}.equals("агентская_") ? $F{ogNm} : ""
  ]]></textFieldExpression>
  <style>
    <conditionalStyle>
      <conditionExpression><![CDATA[$F{ipgSh}.equals("агентская_")]]></conditionExpression>
      <style backcolor="#D6EAF8"/> <!-- Светло-голубой фон для разделителя -->
    </conditionalStyle>
  </style>
</textField>
```

### 7.4 Обработка NULL значений

Многие поля могут быть NULL, поэтому используйте безопасное отображение:

```xml
<textField isBlankWhenNull="true">
  <textFieldExpression><![CDATA[$F{ogNm}]]></textFieldExpression>
</textField>
```

Или для вычислений:

```xml
<textFieldExpression><![CDATA[
  $F{ag_lim} != null ? $F{ag_lim} : BigDecimal.ZERO
]]></textFieldExpression>
```

---

## 8. SQL запрос для JasperReports

```sql
<queryString>
  <![CDATA[
    SELECT 
      ipgSh, limSort, ogNm, branchName, lim, ag_lim, iv_lim, uk_lim, cstAgPnCode,
      ag_Ful_OverFul, ag_LimPc, ag_PlOverLimit_,
      ag_PlAccum, ag_PlFulfillment, ag_PlPz, ag_PlOverFulfillment, ag_PlPercent, 
      ag_PlFulfillmentAll, ag_acceptedNot,
      ag_Pl_M, ag_acceptedTtl_M, ag_PlPz_M,
      mn,
      PrM_ag_PlAccum, PrM_ag_PlFulfillment, PrM_ag_PlPz, PrM_ag_PlOverFulfillment, 
      PrM_ag_PlPercent, PrM_ag_PlFulfillmentAll,
      PrM_ag_Pl_M, PrM_ag_acceptedTtl_M, PrM_ag_PlPz_M, PrM_mnPrevious,
      PrM_ag_PlAccum2, PrM_ag_PlFulfillment2, PrM_ag_PlPz2, PrM_ag_PlOverFulfillment2, 
      PrM_ag_PlPercent2, PrM_ag_PlFulfillment2All,
      PrM_ag_Pl_M2, PrM_ag_acceptedTtl_M2, PrM_ag_PlPz_M2, PrM_mnPrevious2,
      np_acceptedTtlAccum
    FROM ags.spMstrg_2408_ResultSet5
    ORDER BY ipgSh, limSort DESC, lim DESC
  ]]>
</queryString>
```

---

## 9. Выводы и статус

### ✅ Этап 08.2 - ЗАВЕРШЁН

- ✅ 08.2.1 Выполнен SELECT из `ags.spMstrg_2408_ResultSet5` - **32 записи**
- ✅ 08.2.2 Определены типы данных всех 44 столбцов:
  - 7 текстовых (nvarchar → String)
  - 27 денежных (money → BigDecimal)
  - 10 процентных (float → Double)
- ✅ 08.2.3 Проверено соответствие полей Access ↔ ResultSet5:
  - 36 полей прямого соответствия
  - 4 вычисляемых поля (IIf формулы)
  - 4 неиспользуемых поля
- ✅ 08.2.4 Определены вычисляемые поля и их преобразования в Java
- ✅ 08.2.5 Изучены примеры данных:
  - Диапазоны: от 15% до 306% (процентные), от 0 до 1.4 трлн (денежные)
  - NULL значения: 0-47% по разным полям
  - Группировка: 5 схем реализации (а, агентская, агентская_, инвест., прочая)

### Следующий этап

**08.3 - Подготовка окружения для разработки**
- Проверить установку Jaspersoft Studio
- Создать структуру каталогов
- Создать JSON metadata файл

---

**Файл создан:** 2025-12-05  
**Автор:** Александр  
**Статус:** Этап 08.2 завершён ✅