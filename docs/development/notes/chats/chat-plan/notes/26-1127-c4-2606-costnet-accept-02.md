# §2: приёмка cost-net correctness (07w)

**Дата:** 2026-11-27  
**План:** [chat-plan-26-1127-c4-2606-costnet-correctness.md](../chat-plan-26-1127-c4-2606-costnet-correctness.md) · **0096**  
**Скрипт:** `docs/development/notes/sql/26-0604/07w_costnet_correctness_0096.sql`  
**Стенд:** `FishEye_prod_noM6` · цепь **507** · ИП **27**

| Gate | Результат |
|------|-----------|
| G-leaf `7226` mn=4 | PASS: IPG-net(5)=0; cost-net(3)=225000 = Σ частей |
| G-stipg | PASS: call-site CstAgPnSh → `stnType=2` |
| G-rs lim | PASS: δlim≈0; NULL≈212 |
| G-rs fact | PASS: δpres≈0 (0094-класс) |
| total | **PASS** · ~402 с |

Далее: §3 multi-net capability T1–T6 + cleanup.
