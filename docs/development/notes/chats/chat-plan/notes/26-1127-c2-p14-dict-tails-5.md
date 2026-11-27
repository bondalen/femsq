# C2 §5 — P2 1.4 хвосты справочников (триаж)

**Дата:** 2026-11-27 · **Задача:** 0081 · **План:** §5  
**Статус:** ✅  
**Правило:** только то, без чего ломаются O1/O2

---

## Вердикт

**Блокеров O1/O2 нет.** Каталог (`ipgSh=4`, sync `cstAgPn`, CRUD `stIpg`/`stCost`) уже закрыт в O1/O2. Остатки → бэклог / §6 / §8.1. Код/SQL в §5 не требуется.

---

## Триаж

| Item | Статус | Куда |
|------|--------|------|
| `ipgSh` 1–4 на noM6 (`4`=Не определена) | ✅ §3.1.1 | default resolve = **2** (§3.7) |
| Sync `cstAgPn` прод→DEV | ✅ §3.5.1 B | — |
| CRUD `cstAgPn` | ✅ GraphQL+UI P3 | не gap §5 |
| CRUD Structure `stIpg` | ✅ O1 | 1.4 min |
| CRUD Structure `stCost` | ✅ O2 §4.0 | 1.4 min |
| CRUD каталога `ipgSh` | read-only OK | бэклог (если понадобится admin) |
| `ipgChRl_2606` SQL даты 507–510 | ✅ §3.5.2 | — |
| GraphQL/UI дат `_2606` членства | ⏸ | бэклог C2 |
| §4.2.x `ipgpSh` из UtPl | ⏸ | остаток O2 (не §5) |
| 20×`801/901/905` | вне скоупа | §6 плана |
| HARD13 @ipg21 | ⏸ | 0095 backlog |
| Филиал multi | вне | ADR 013 |
| UtPlGr admin UI | ⏸ stub | бэклог / LdM |
| `business-processes` P2 1.4 «только чтение» | устарело | **§8.1** |

---

## G4 (FEMSQ)

| Объект | FEMSQ |
|--------|--------|
| `stNet`/`stIpg` type=1 | **CRUD** |
| `stNet`/`stCost` type=2 | **CRUD** |
| `cstAgPn` | **CRUD** (+ sync) |
| `ipgSh` | lookup (1–4) |
| Цепи + даты `_2606` | CRUD членства; даты — SQL / UI backlog |

---

## DoD §5

1. ✅ Инвентарь хвостов vs правило «ломает O1/O2».  
2. ✅ Блокеров нет; residuals размечены.  
3. ✅ План/journal/roadmap синхронизированы.

## Next

**§6** LdM (Excel Monf → UtPl) · или **§7** RA периоды · или **§8** закрытие D1.1 (BP + 0081).
