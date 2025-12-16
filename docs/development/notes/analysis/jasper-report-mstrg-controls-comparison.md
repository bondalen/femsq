# Сравнительный анализ контролов Access отчёта и элементов JRXML

**Дата анализа:** 2025-12-05  
**Автор:** Александр  
**Исходный файл структуры:** `/home/alex/Загрузки/mstrgAg_23_Branch_q2m_2408_25_structure_9.txt`  
**Текущий JRXML:** `code/femsq-backend/femsq-reports/src/main/resources/reports/embedded/mstrgAg_23_Branch_q2m_2408_25.jrxml`  
**Связанный план:** `docs/development/notes/chats/chat-plan/chat-plan-25-1205-jasper-report-mstrg.md`  
**Этап выполнения:** 08.5.4 - Тестирование базового шаблона

---

## 1. Общая статистика

### Access отчёт (исходный)
- **Всего контролов:** 70
- **Label (100):** 24 контрола
- **TextBox (109):** 42 контрола
- **Unknown_101 (101):** 2 контрола (линии разделители)
- **Unknown_127 (127):** 1 контрол
- **Rectangle (102):** 1 контрол (Report Footer)

### JRXML шаблон (текущий)
- **Всего элементов:** ~15 элементов
  - **staticText:** 12 элементов (заголовки)
  - **textField:** 12 элементов (поля данных)
  - **rectangle:** 2 элемента (линии разделители)
  - **textField (pageFooter):** 2 элемента (номер страницы, дата)

---

## 2. Детальное сравнение по секциям

### 2.1 Report Header (Заголовок отчёта)

#### Access: Control #1
- **Тип:** Label (100)
- **Секция:** Report Header
- **Координаты:** x=0, y=0, width=1156pt, height=43pt
- **Текст:** "Исполнение плана капитального строительства по отдельным программам и подразделениям в соответствии с утверждённым финансированием при исполнении на 2025 год, утверждённого постановлением 03.09.2025 (по состоянию на 17.09.2025)"
- **Шрифт:** Times New Roman, 8pt, Bold
- **Цвет:** ForeColor=#7F7F7F (серый)

#### JRXML: Title band
- **Тип:** staticText
- **Координаты:** x=0, y=0, width=1156pt, height=43pt ✅
- **Текст:** ✅ Соответствует
- **Шрифт:** Times New Roman, 8pt, Bold ✅
- **Цвет:** ❌ Не указан (должен быть #7F7F7F)

**Статус:** ✅ Реализован (требуется добавить цвет)

---

### 2.2 Page Header (Верхний колонтитул)

#### Access: Controls #2-#27 (26 контролов)

**Контролы, которые должны быть в Page Header:**

1. **Control #3** - Линия разделитель (Unknown_101)
   - x=0, y=0, width=1153pt, height=1pt
   - BackColor=#FDEADA
   - ✅ Реализован как rectangle

2. **Control #4** - "Филиал" (Label)
   - x=0, y=0, width=99pt, height=43pt
   - ✅ Реализован как staticText

3. **Control #5** - "Номер филиала (без ИСО)" (Label)
   - x=99, y=0, width=80pt, height=43pt
   - ✅ Реализован как staticText

4. **Control #6** - "Лимит" (Label)
   - x=178, y=0, width=85pt, height=13pt
   - ✅ Реализован как staticText

5. **Control #19** - "на 2024 г. программ" (Label)
   - x=178, y=13, width=85pt, height=19pt
   - ✅ Реализован как staticText (но высота изменена на 10pt)

6. **Control #18** - "ИНВЕСТИЦИОННАЯ" (Label)
   - x=178, y=32, width=85pt, height=11pt
   - ForeColor=#2F3699 (синий)
   - ✅ Реализован как staticText (но y=23 вместо 32)

7. **Control #17** - "ИТОГО" (Label)
   - x=178, y=43, width=85pt, height=11pt
   - ForeColor=#C0504D (красный)
   - ✅ Реализован как staticText (но y=33 вместо 43)

8. **Control #7** - "Исполнение сметного лимита" (Label)
   - x=263, y=0, width=77pt, height=32pt
   - ✅ Реализован как staticText

9. **Control #8** - "% Исполнения сметного лимита" (Label)
   - x=340, y=0, width=46pt, height=43pt
   - ✅ Реализован как staticText

10. **Control #9** - "Превышен лимит бизнес сметного плана" (Label)
    - x=386, y=0, width=74pt, height=32pt
    - ✅ Реализован как staticText

11. **Control #10** - "Месяц" (Label)
    - x=460, y=13, width=52pt, height=30pt
    - ✅ Реализован как staticText

12. **Control #11** - " в разрезе видов контрагентов финансирования" (Label)
    - x=512, y=13, width=436pt, height=10pt
    - BackColor=#FDEADA
    - ✅ Реализован как staticText

**Контролы, которые НЕ реализованы в JRXML:**

13. **Control #2** - "на накопленное" (Label)
    - x=263, y=43, width=77pt, height=11pt
    - Visible=False
    - ❌ Не реализован (скрыт в Access)

14. **Control #12** - "Исполнение, в тыс" (Label)
    - x=599, y=23, width=80pt, height=31pt
    - ❌ НЕ реализован

15. **Control #13** - "Исполнение, в %" (Label)
    - x=680, y=23, width=49pt, height=31pt
    - ❌ НЕ реализован

16. **Control #14** - "Исполнение сверх плана, в тыс" (Label)
    - x=728, y=23, width=71pt, height=31pt
    - ❌ НЕ реализован

17. **Control #15** - "Исполнение сверх плана, в %" (Label)
    - x=880, y=23, width=69pt, height=31pt
    - ❌ НЕ реализован

18. **Control #16** - "Инвестиционная программа капитального строительства по видам контрагентов финансирования на текущий и предыдущий месяц (инвестиционная программа и в разрезе контрагентов)" (Label)
    - x=460, y=0, width=700pt, height=13pt
    - BackColor=#FCD5B5
    - ❌ НЕ реализован

19. **Control #20** - "План, в тыс" (Label)
    - x=512, y=23, width=87pt, height=31pt
    - ❌ НЕ реализован

20. **Control #21** - " в тыс рублей по месяцам" (Label)
    - x=949, y=13, width=211pt, height=10pt
    - BackColor=#F3F0F6
    - ❌ НЕ реализован

21. **Control #22** - "План, в тыс" (Label)
    - x=949, y=23, width=77pt, height=31pt
    - ❌ НЕ реализован

22. **Control #23** - "Исполнение, в тыс" (Label)
    - x=1026, y=23, width=85pt, height=31pt
    - ❌ НЕ реализован

23. **Control #24** - "Исполнение, в %" (Label)
    - x=1111, y=23, width=49pt, height=31pt
    - ❌ НЕ реализован

24. **Control #25** - "Исполнение сверх плана, в тыс" (Label)
    - x=800, y=23, width=80pt, height=31pt
    - ❌ НЕ реализован

25. **Control #26** - Unknown_127 (пустой элемент)
    - x=263, y=32, width=77pt, height=11pt
    - ❌ НЕ реализован (пустой элемент)

26. **Control #27** - "для инвестиционной программы" (Label)
    - x=386, y=32, width=74pt, height=22pt
    - ForeColor=#FF0000 (красный)
    - ❌ НЕ реализован

**Статус Page Header:** ⚠️ Реализовано 12 из 26 контролов (46%)

---

### 2.3 Detail (Строки данных)

#### Access: Controls #28-#70 (43 контрола)

**Контролы, которые реализованы в JRXML:**

1. **Control #28** - Линия разделитель (Unknown_101)
   - x=0, y=0, width=1153pt, height=1pt
   - BackColor=#C6D9F1
   - ✅ Реализован как rectangle

2. **Control #29** - ogNm (TextBox)
   - x=0, y=0, width=99pt, height=9pt
   - ✅ Реализован как textField (но y=1 вместо 0)

3. **Control #30** - lim (TextBox)
   - x=99, y=0, width=80pt, height=27pt
   - ✅ Реализован как textField (но y=1 вместо 0)

4. **Control #31** - ag_lim (TextBox)
   - x=178, y=0, width=85pt, height=9pt
   - ✅ Реализован как textField (но y=1 вместо 0)

5. **Control #35** - iv_lim (TextBox)
   - x=178, y=9, width=85pt, height=9pt
   - ForeColor=#2F3699 (синий)
   - ✅ Реализован как textField (но y=10 вместо 9)

6. **Control #36** - uk_lim (TextBox)
   - x=178, y=18, width=85pt, height=9pt
   - ForeColor=#C0504D (красный)
   - ✅ Реализован как textField (но y=19 вместо 18)

7. **Control #32** - ag_Ful_OverFul (TextBox)
   - x=263, y=0, width=77pt, height=18pt
   - ✅ Реализован как textField (но y=1 вместо 0)

8. **Control #33** - ag_LimPc (TextBox)
   - x=340, y=0, width=46pt, height=27pt
   - Format=Percent
   - ✅ Реализован как textField (но y=1 вместо 0)

9. **Control #34** - ag_PlOverLimit_ (TextBox)
   - x=386, y=0, width=74pt, height=18pt
   - ✅ Реализован как textField (но y=1 вместо 0)

10. **Control #42** - mnCn (TextBox, вычисляемое)
    - x=460, y=0, width=52pt, height=9pt
    - ControlSource=IIf(IsNull([ag_lim]),Null,[mn])
    - ✅ Реализован как textField (но y=14 вместо 0, выражение реализовано)

11. **Control #37** - ag_PlAccum (TextBox)
    - x=512, y=0, width=87pt, height=9pt
    - ✅ Реализован как textField (но y=14 вместо 0)

12. **Control #38** - ag_PlFulfillmentCn (TextBox, вычисляемое)
    - x=599, y=0, width=80pt, height=9pt
    - ControlSource=IIf([ag_PlFulfillment]<0,Null,[ag_PlFulfillment])
    - ✅ Реализован как textField (но y=14 вместо 0, выражение реализовано)

13. **Control #39** - ag_PlPz (TextBox)
    - x=680, y=0, width=49pt, height=9pt
    - Format=Percent
    - ✅ Реализован как textField (но y=14 вместо 0, height=27 вместо 9)

**Контролы, которые НЕ реализованы в JRXML:**

14. **Control #40** - ag_PlOverFulfillment (TextBox)
    - x=728, y=0, width=71pt, height=9pt
    - ❌ НЕ реализован

15. **Control #41** - ag_PlPercent (TextBox)
    - x=880, y=0, width=69pt, height=9pt
    - Format=Percent
    - ❌ НЕ реализован

16. **Control #43** - PrM_mnPreviousCn (TextBox, вычисляемое)
    - x=460, y=9, width=52pt, height=9pt
    - ControlSource=IIf(IsNull([ag_lim]),Null,[PrM_mnPrevious])
    - ForeColor=#E46C0A (оранжевый)
    - ❌ НЕ реализован

17. **Control #44** - ag_Pl_M (TextBox)
    - x=949, y=0, width=77pt, height=9pt
    - ❌ НЕ реализован

18. **Control #45** - ag_acceptedTtl_M (TextBox)
    - x=1026, y=0, width=85pt, height=9pt
    - ❌ НЕ реализован

19. **Control #46** - ag_PlPz_M (TextBox)
    - x=1111, y=0, width=49pt, height=9pt
    - Format=Percent
    - ❌ НЕ реализован

20. **Control #47** - PrM_ag_PlPz_M (TextBox)
    - x=1111, y=9, width=49pt, height=9pt
    - Format=Percent
    - ForeColor=#E46C0A (оранжевый)
    - ❌ НЕ реализован

21. **Control #48** - PrM_ag_acceptedTtl_M (TextBox)
    - x=1026, y=9, width=85pt, height=9pt
    - ForeColor=#E46C0A (оранжевый)
    - ❌ НЕ реализован

22. **Control #49** - PrM_ag_Pl_M (TextBox)
    - x=949, y=9, width=77pt, height=9pt
    - ForeColor=#E46C0A (оранжевый)
    - ❌ НЕ реализован

23. **Control #50** - PrM_ag_PlPercent (TextBox)
    - x=880, y=9, width=69pt, height=9pt
    - Format=Percent
    - ForeColor=#E46C0A (оранжевый)
    - ❌ НЕ реализован

24. **Control #51** - PrM_ag_PlOverFulfillment (TextBox)
    - x=728, y=9, width=71pt, height=9pt
    - ForeColor=#E46C0A (оранжевый)
    - ❌ НЕ реализован

25. **Control #52** - PrM_ag_PlPz (TextBox)
    - x=680, y=9, width=49pt, height=9pt
    - Format=Percent
    - ForeColor=#E46C0A (оранжевый)
    - ❌ НЕ реализован

26. **Control #53** - PrM_ag_PlFulfillment (TextBox)
    - x=599, y=9, width=80pt, height=9pt
    - ForeColor=#E46C0A (оранжевый)
    - ❌ НЕ реализован

27. **Control #54** - PrM_ag_PlAccum (TextBox)
    - x=512, y=9, width=87pt, height=9pt
    - ForeColor=#E46C0A (оранжевый)
    - ❌ НЕ реализован

28. **Control #55** - PrM_mnPrevious2Cn (TextBox, вычисляемое)
    - x=460, y=18, width=52pt, height=9pt
    - ControlSource=IIf(IsNull([ag_lim]),Null,[PrM_mnPrevious2])
    - ForeColor=#4F6228 (зелёный)
    - ❌ НЕ реализован

29. **Control #56** - PrM_ag_PlAccum2 (TextBox)
    - x=512, y=18, width=87pt, height=9pt
    - ForeColor=#4F6228 (зелёный)
    - ❌ НЕ реализован

30. **Control #57** - PrM_ag_PlFulfillment2 (TextBox)
    - x=599, y=18, width=80pt, height=9pt
    - ForeColor=#4F6228 (зелёный)
    - ❌ НЕ реализован

31. **Control #58** - PrM_ag_PlPz2 (TextBox)
    - x=680, y=18, width=49pt, height=9pt
    - Format=Percent
    - ForeColor=#4F6228 (зелёный)
    - ❌ НЕ реализован

32. **Control #59** - PrM_ag_PlOverFulfillment2 (TextBox)
    - x=728, y=18, width=71pt, height=9pt
    - ForeColor=#4F6228 (зелёный)
    - ❌ НЕ реализован

33. **Control #60** - PrM_ag_PlPercent2 (TextBox)
    - x=880, y=18, width=69pt, height=9pt
    - Format=Percent
    - ForeColor=#4F6228 (зелёный)
    - ❌ НЕ реализован

34. **Control #61** - PrM_ag_PlFulfillment2All (TextBox)
    - x=800, y=18, width=80pt, height=9pt
    - ForeColor=#4F6228 (зелёный)
    - ❌ НЕ реализован

35. **Control #62** - PrM_ag_Pl_M2 (TextBox)
    - x=949, y=18, width=77pt, height=9pt
    - ForeColor=#4F6228 (зелёный)
    - ❌ НЕ реализован

36. **Control #63** - PrM_ag_acceptedTtl_M2 (TextBox)
    - x=1026, y=18, width=85pt, height=9pt
    - ForeColor=#4F6228 (зелёный)
    - ❌ НЕ реализован

37. **Control #64** - PrM_ag_PlPz_M2 (TextBox)
    - x=1111, y=18, width=49pt, height=9pt
    - Format=Percent
    - ForeColor=#4F6228 (зелёный)
    - ❌ НЕ реализован

38. **Control #65** - ag_PlFulfillmentAll (TextBox)
    - x=800, y=0, width=80pt, height=9pt
    - ❌ НЕ реализован

39. **Control #66** - ag_acceptedNot (TextBox)
    - x=800, y=9, width=80pt, height=9pt
    - ❌ НЕ реализован

40. **Control #67** - PrM_ag_PlFulfillmentAll (TextBox)
    - x=800, y=9, width=80pt, height=9pt
    - ForeColor=#E46C0A (оранжевый)
    - ❌ НЕ реализован

41. **Control #64** - branchName (TextBox)
    - x=0, y=9, width=99pt, height=18pt
    - ForeColor=#E46C0A (оранжевый)
    - ❌ НЕ реализован

42. **Control #65** - ag_acceptedNot (TextBox)
    - x=263, y=18, width=77pt, height=9pt
    - ForeColor=#C0504D (красный)
    - Visible=False
    - ❌ НЕ реализован (скрыт в Access)

43. **Control #66** - PrM_ag_PlFulfillmentAll (TextBox)
    - x=800, y=9, width=80pt, height=9pt
    - ForeColor=#E46C0A (оранжевый)
    - ❌ НЕ реализован

44. **Control #67** - ag_PlFulfillmentAll (TextBox)
    - x=800, y=0, width=80pt, height=9pt
    - ❌ НЕ реализован

45. **Control #68** - PrM_ag_PlFulfillment2All (TextBox)
    - x=800, y=18, width=80pt, height=9pt
    - ForeColor=#4F6228 (зелёный)
    - ❌ НЕ реализован

46. **Control #69** - np_acceptedTtlAccum (TextBox)
    - x=386, y=18, width=74pt, height=9pt
    - ForeColor=#FF0000 (красный)
    - ❌ НЕ реализован

47. **Control #70** - Rectangle (Report Footer)
    - x=0, y=0, width=1160pt, height=0pt
    - BorderStyle=Solid, BorderWidth=2, BorderColor=#BFBFBF
    - ❌ НЕ реализован (Report Footer не реализован)

**Статус Detail:** ⚠️ Реализовано 13 из 42 контролов данных (31%) + 1 линия разделитель

---

### 2.4 Report Footer (Итоговая секция)

#### Access: Control #70
- **Тип:** Rectangle (102)
- **Секция:** Report Footer
- **Координаты:** x=0, y=0, width=1160pt, height=0pt
- **BorderStyle:** Solid, BorderWidth=2, BorderColor=#BFBFBF

#### JRXML: Report Footer
- ❌ НЕ реализован

**Статус Report Footer:** ❌ Не реализован

### 2.5 Page Footer (Нижний колонтитул)

#### Access: (нет контролов в экспорте, но обычно содержит номер страницы)

#### JRXML: Page Footer
- **textField:** Номер страницы (x=0, y=0)
- **textField:** Дата генерации (x=863, y=0)

**Статус Page Footer:** ✅ Реализован базовый функционал

---

## 3. Итоговая статистика

### Реализовано
- **Report Header:** 1/1 (100%) ⚠️ Требуется добавить цвет
- **Page Header:** 12/26 (46%) ⚠️ Много пропущенных заголовков
- **Detail:** 13/43 (30%) ⚠️ Большинство полей не реализовано
- **Page Footer:** 2/2 (100%) ✅

### Общий процент реализации
- **Всего контролов:** 70
- **Реализовано:** ~28 контролов (40%)
- **Не реализовано:** ~42 контрола (60%)

### Детализация по типам
- **Label (24):** Реализовано 12 (50%)
- **TextBox (42):** Реализовано 13 (31%)
- **Unknown_101 (2):** Реализовано 2 (100%) ✅
- **Unknown_127 (1):** Реализовано 0 (0%)
- **Rectangle (1):** Реализовано 0 (0%)

---

## 4. Критические пропуски

### 4.1 Заголовки столбцов (Page Header)
Отсутствуют заголовки для:
- Исполнение, в тыс
- Исполнение, в %
- Исполнение сверх плана, в тыс
- Исполнение сверх плана, в %
- План, в тыс (несколько колонок)
- В тыс рублей по месяцам
- Для инвестиционной программы

### 4.2 Поля данных (Detail)
Отсутствуют поля:
- **Текущий период:**
  - ag_PlOverFulfillment
  - ag_PlPercent
  - ag_PlFulfillmentAll
  - ag_acceptedNot
  - ag_Pl_M
  - ag_acceptedTtl_M
  - ag_PlPz_M

- **Предыдущий месяц (PrM_):**
  - PrM_mnPreviousCn
  - PrM_ag_PlAccum
  - PrM_ag_PlFulfillment
  - PrM_ag_PlPz
  - PrM_ag_PlOverFulfillment
  - PrM_ag_PlPercent
  - PrM_ag_PlFulfillmentAll
  - PrM_ag_Pl_M
  - PrM_ag_acceptedTtl_M
  - PrM_ag_PlPz_M

- **Предпредыдущий месяц (PrM_...2):**
  - PrM_mnPrevious2Cn
  - PrM_ag_PlAccum2
  - PrM_ag_PlFulfillment2
  - PrM_ag_PlPz2
  - PrM_ag_PlOverFulfillment2
  - PrM_ag_PlPercent2
  - PrM_ag_PlFulfillment2All
  - PrM_ag_Pl_M2
  - PrM_ag_acceptedTtl_M2
  - PrM_ag_PlPz_M2

- **Дополнительные поля:**
  - branchName (y=9, оранжевый цвет)
  - ag_acceptedNot (y=18, красный цвет, Visible=False)
  - ag_PlFulfillmentAll (y=0)
  - PrM_ag_PlFulfillmentAll (y=9, оранжевый)
  - PrM_ag_PlFulfillment2All (y=18, зелёный)
  - np_acceptedTtlAccum (y=18, красный цвет)

---

## 5. Рекомендации

### 5.1 Приоритет 1 (Критично)
1. Добавить все недостающие заголовки столбцов в Page Header
2. Добавить все поля данных текущего периода в Detail
3. Добавить поля данных предыдущего месяца (PrM_) с правильными цветами (#E46C0A)
4. Добавить поля данных предпредыдущего месяца (PrM_...2) с правильными цветами (#4F6228)

### 5.2 Приоритет 2 (Важно)
1. Исправить координаты элементов (y-смещения)
2. Добавить правильные цвета текста для всех элементов
3. Реализовать вычисляемые поля (IIf выражения)
4. Добавить правильные форматы (Percent для процентных полей)

### 5.3 Приоритет 3 (Желательно)
1. Добавить условное форматирование (если требуется)
2. Оптимизировать высоту Detail band для размещения всех элементов
3. Проверить соответствие всех координат исходному отчёту

---

## 6. VBA код и условное форматирование

### 6.1 VBA код из Access отчёта

В Access отчёте присутствует VBA код для условного форматирования секции Detail:

```vba
Private Sub Деталь_Format(Cancel As Integer, FormatCount As Integer)
    On Error Resume Next
    
    Select Case Me!ogNm
        Case "Итого"
            Деталь.BackColor = 14020607
            Деталь.AlternateBackColor = 14020607
        Case "Подпрограмма"
            Деталь.BackColor = 14020607
            Деталь.AlternateBackColor = 14020607
        Case Else
            Деталь.BackColor = vbWhite
            Деталь.AlternateBackColor = RGB(242, 242, 242)
    End Select
End Sub
```

**Назначение:** Изменение цвета фона Detail band в зависимости от значения `ogNm`:
- Если `ogNm = "Итого"` или `"Подпрограмма"` → BackColor = 14020607 (RGB: R=214, G=214, B=214) - светло-серый
- Иначе → BackColor = белый, AlternateBackColor = RGB(242, 242, 242) - очень светло-серый

**Реализация в JasperReports:** Требуется использовать условные стили или выражения для `backcolor` в `reportElement`.

**Статус:** ❌ Не реализовано

---

## 7. Следующие шаги

1. **Этап 08.6** - Детальная настройка layout и форматирования
   - Добавить все недостающие заголовки
   - Добавить все недостающие поля данных
   - Настроить цвета и форматирование

2. **Этап 08.7** - Реализация вычисляемых полей
   - Реализовать все IIf выражения
   - Проверить корректность преобразования в Java выражения

3. **Этап 08.8** - Финальная проверка и тестирование
   - Сравнить визуально с исходным отчётом
   - Проверить все данные
   - Исправить найденные несоответствия

---

**Вывод:** Текущий JRXML шаблон содержит только базовую структуру отчёта. Реализовано примерно 40% контролов из исходного Access отчёта. Требуется значительная доработка для достижения полного соответствия.
