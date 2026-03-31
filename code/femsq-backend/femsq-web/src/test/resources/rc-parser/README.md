# rc-parser — фикстуры для `RcStagingLineParser`

## `oizm_distinct_rainRaNum_2025-2026.txt`

Уникальные значения `rainRaNum` для строк со знаком «ОА изм», у которых `rainRaDate` относится к **2025 или 2026** году (календарный год даты строки отчёта).

Источник: выборка из `ags.ra_stg_ra` (DBHub / SQL Server), 2026-03-24. **70** уникальных шаблонов; на снимке БД при прогоне `RcStagingLineParserIntegrationIT`: ~**86%** успешных разборов, ~**14%** без даты в тексте (например строка без подстроки «от …») или иные отличия от VBA.

Юнит-тест `RcStagingLineParserTest#parse_allLinesInResourceFile_succeedOrDocumented` проверяет, что доля неуспеха по этому файлу не превышает **25%** (регрессия парсера).

### Обновление выборки

```sql
SELECT DISTINCT rainRaNum
FROM ags.ra_stg_ra
WHERE LTRIM(RTRIM(ISNULL(rainSign, ''))) = N'ОА изм'
  AND rainRaDate IS NOT NULL
  AND YEAR(rainRaDate) IN (2025, 2026)
ORDER BY rainRaNum;
```

Сохранить результат в этот файл (UTF-8), по одной строке на значение, комментарии с `#`.

### Интеграционный прогон по живой БД

См. `RcStagingLineParserIntegrationIT`: `mvn test -pl femsq-web -Dtest=RcStagingLineParserIntegrationIT -Dfemsq.integration.rcParser=true`
