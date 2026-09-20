# 26-0920 — разведение ключей pm + H6 (A/B/C + C')

**Дата:** 2026-09-20 · **JAR:** см. сборку после C'

## Что сделано

| Шаг | Содержание |
|-----|------------|
| **A** | `01_REMAP_QI_PM_KEYS.sql`: QI apply → pm_upl **47–51**; g_p@902; File/Tbl; IDENTITY sudz |
| **B** | H6 читает только пакеты из `g_p` (после A — без старых 3–8) |
| **C** | H6: путь `invDbtCia` ∪ путь `dvDocBase`=`invNum` |
| Rebuild | `02_REBUILD…` → **1215** @902; остаток FAIL **9469** |
| **C'** | `03_REBUILD_DbtUplCstAg_902_cia_link.sql` + код: |
| | **B'** `idcCia`→`cnInvAccnt`→smpl (не `idcCia` как ciasKey) |
| | **A** `dvDocBase` = invNum **или** link при `LEN>=8` |
| Rebuild C' | **1580** строк @902 |

## Сверка vs Access `26-0505`

| Метрика | H7 canon | После A/B/C | После C' |
|---------|----------|-------------|----------|
| FAIL (unaccounted) | **729** | **1** | **0** ✅ |
| matchedClean | 1150 | 1878 | **1879** |
| `0620CR000043` | `051-2000860` | `051-2005183` | `051-2005183` |
| `49786` / 9469 | — | `051-2004956` ❌ | **`051-2005850`** ✅ |

Корень FAIL 9469: `idcCia=16284` уже верный cia→smpl **68548** (`49786`); H6 джойнил `idcCia` к `pm.ciaCnInvAccntSmpl` и попадал в чужой smpl **16284** (`90123`/606022).

Артефакты: `…/artifacts/h7_s80_qiv_qi_vs_access_fixC_26-0920-1348.*`
