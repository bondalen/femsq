# §3: multi-net capability T1–T6

**Дата:** 2026-11-27  
**План:** [chat-plan-26-1127-c4-2606-costnet-correctness.md](../chat-plan-26-1127-c4-2606-costnet-correctness.md) · **0096**  
**Скрипт:** `docs/development/notes/sql/26-0604/07x_costnet_multinet_capability_0096.sql`  
**Стенд:** `FishEye_prod_noM6`

| T | Проверка | Результат |
|---|----------|-----------|
| T1 | temp `stnType=2` (214→212, 212→148, 212→187) | PASS · stnKey=8 (удалён) |
| T2 | носитель 7226 mn=4 без прямой 212 | PASS |
| T3 | combat(3) → 225000 | PASS |
| T4 | temp → 450000 (отличие от combat) | PASS |
| T4b | default lookup = «Стандартная» при 2 сетях | PASS |
| T5 | IPG DAG 82→82 · contracts 962→962 | PASS |
| T6 | cleanup · type2 1→1 · orphan=0 | PASS |

**Итог:** `=== 07x PASS ===`
