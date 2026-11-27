# Первый промпт — чат «C4b / _2606 cost-net correctness»

Скопировать в **новый** чат Cursor целиком.

---

## Промпт

```text
Работаем по плану:
docs/development/notes/chats/chat-plan/chat-plan-26-1127-c4-2606-costnet-correctness.md
Задача 0096 · трек C4 (ранний gate) · стенд FishEye_prod_noM6.
Дефект: P-2026-11-27-002.

### Цель
В стеке _2606 развести IPG-net и cost-net:
  @stNetIpg  ← ipgCh.ipgcStNetIpg (отбор строек по разделам ИПГ)
  @stCostNet ← сетка затрат (stnType=2); default = боевая «Стандартная» (сейчас stnKey=3)

Сейчас mastering передаёт ipgcStNetIpg и в cost-rollup → fnStDownAll(2,212)=0,
а fnStDownAll(3,212)=72. Repro: fnStCostUtPlPMn(7226, 212, 2, mn)=0,
с net=3 = Σ частей. Прямая строка на stcKey маскирует баг.

### Решения владельца (не пересматривать без явной просьбы)
- H1+H2: развести параметры; default cost-net = stnType=2; явный @stCostNet для capability
- UtPl / помесячные планы: только пункты stcKey; выбора сетки при вводе нет
- Multi-net: обязателен тест временной 2-й сети (T1–T6) + полное удаление артефактов
- Не продуктовый rollout второй сети; не раздувать план скоростью/20.6 без явного статуса в §5
- C2 O2 на паузе до DoD этого плана

### Начни с
§0: зафиксировать дефект в note (если ещё нет деталей), аудит всех мест,
где @stNet / @stCostNet кормится из ipgcStNetIpg; затем §1 патч H1+H2
(код + MSSQL2012) на FishEye_prod_noM6.

Не начинать C2 §4.0 UI и не оставлять тестовую 2-ю сеть после приёмки.
```
