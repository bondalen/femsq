# Runbook §3.5.1 B — sync cstAgPn noM6

**Стенд:** `FishEye_prod_noM6` · **НЕ на прод**  
**Источник:** отПрод `femsq_cstagpn_full_diff_20261126`  
**Порядок (после подготовки скриптов):**

| # | Скрипт | План |
|---|--------|------|
| 1 | `00b_SNAPSHOT_remap_keys_DEV_ONLY.sql` | 3.5.1.0 |
| 2 | `03_REMAP_7_codes_DEV_ONLY.sql` | 3.5.1.1 |
| 3 | `04_UPDATE_displaced_keys_DEV_ONLY.sql` | 3.5.1.2 |
| 4 | ~~`05_UPDATE_3804_…`~~ **SKIP** | 3.5.1.3 ✅ — на прод опечатка `1002605` исправлена на `051-1002605`; DEV не трогаем |
| 5 | `02_IMPORT_noM6_DEV_ONLY.sql` | 3.5.1.4 (~72 cstAgPn) |
| 6 | `06_VERIFY_sync_DEV_ONLY.sql` | 3.5.1.5 (ожидание 3804 = `051-1002605`) |
| 7 | `ImpIpgPointsApplySmokeMain 9\|10\|11 none commit` | 3.5.1.6 |

**Remap:** без DELETE DEV_key — temp `__REMAP_<key>`, INSERT prod_key, FK→prod, затем 04 UPDATE на старых ключах.

**Откат:** из `ags._bak_cstagpn_B_20261126_*` (ручной; отдельный rollback-скрипт не генерировался).
