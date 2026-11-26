# План: R-MONEY-AGG — квант денег и оси агрегации при вводе

**Дата создания:** 2026-11-26  
**Последнее обновление:** 2026-11-26  
**Версия плана:** 0.1.4  
**Статус плана:** ✅ completed — §1–5+7 ✅; §6 → обязательство O2 (C2)  



**Задача:** **0095**  
**Трек:** C2 / данные (сквозное: ImpIpg, leaves, RA, UtPl O2)  
**ADR:** [012-money-agg-axes.md](../../../../project/decisions/012-money-agg-axes.md)  
**Спин-офф:** [fn2-stcost-fact-rs](./chat-plan-26-1126-fn2-stcost-fact-rs.md) (диагностика lim δ≈0.01 @3555)

---

## 0. Зачем

Excel несёт субкопеечные доли и арифметические ошибки по осям (`Ttl≠части`, `212≠195+172+187`). БД — квант копейки (млн:`decimal(23,8)`; ₽:`money`). Без round+AggCheck срезы stCost и RS lim/факт расходятся.

---

## 1. Решения (зафиксированы 2026-11-26)

См. ADR 012: классы **Q / A / A-hard / S**; D1, D2', D2'', D3, D6, D7.

---

## 2. Дерево работ

```text
├─ 0. ADR 012 + ссылки (.cursorrules, roadmap)                 ✅
├─ 1. FemsqMoney / AggAxis + unit-тесты                        ✅
├─ 2. ImpIpg: parser scale 8 + apply AggCheck/Fix + seed lim   ✅
├─ 3. GraphQL leaves — тот же util                             ✅
├─ 4. One-shot данные стенда (Q/A; отчёт A-hard)               ✅
│     Q25+A4 fixed; HARD13 @ipg21 skipped; 07k1 DECIMAL_EXACT
├─ 5. RA: AuditExcelCellReader + reconcile ra_summ             ✅
│     roundRub; AggAxis на ra_summ / ra_change_summ / ra_change_au / JdbcRaSummDao
├─ 6. UtPl O2 — Round(8) + оси с первого дня                   ☐ (с O2)
└─ 7. Gate 07k1 @507 после repair                              ✅
```

---

## 3. Критерий закрытия

1. ADR 012 принят; util используется всеми путями ввода млн/₽ с осями.  
2. ImpIpg + leaves: Q/A авто; A-hard block; lim seeded из согласованных Sm*.  
3. На стенде после repair: 07k1 lim δ=0 (нет класса 3555).  
4. RA: round+rebalance до INSERT; фактDoc не размножает рассинхрон.  
5. Задача **0095** → completed (§6 остаётся обязательством O2).

---

## 4. Журнал правок

| Дата | Версия | Что |
|------|--------|-----|
| 2026-11-26 | 0.1.0 | Создан после согласия D2'/D2''/D7; ADR 012 |
| 2026-11-26 | 0.1.1 | FemsqMoney/AggAxis; ImpIpg+leaves+seed lim; parser scale 8 |
| 2026-11-26 | 0.1.2 | One-shot Sm/lim: Q25+A4; 07k1 EXACT; HARD13 @ipg21 в бэклог |
| 2026-11-26 | 0.1.3 | RA: roundRub + AggAxis на reconcile/DAO; BLOCK skip INSERT |
| 2026-11-26 | 0.1.4 | План/0095 закрыты; UtPl Round(8)+AggAxis — с первого дня O2 |
