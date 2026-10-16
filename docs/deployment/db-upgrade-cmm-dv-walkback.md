# Порядок работ: миграция комментариев Acc → `*Dv` (walk-back)

**Файл:** `docs/deployment/db-upgrade-cmm-dv-walkback.md`  
**Дата создания:** 2026-10-16  
**lastUpdated:** 2026-10-16  
**Автор:** Александр  
**Статус:** пакет готов; на продуктив `SPB-05-NV-SQL1` не применялся

**Скрипты:** [`26-1016-cmm-dv-prod/MSSQL2012`](../development/notes/sql/26-1016-cmm-dv-prod/MSSQL2012/README.md)  
**Правила SQL:** [`sql-server-deployment-rules.md`](sql-server-deployment-rules.md)  
**План:** [chat-plan-26-1012](../development/notes/chats/chat-plan/chat-plan-26-1012-qii-cmm-d644.md) узел 4.3  
**Окно cutover:** [db-upgrade-sudz-invdbt-cutover.md](db-upgrade-sudz-invdbt-cutover.md) §1.3.1 (шаг D5a) · [чеклист дня](db-upgrade-sudz-invdbt-cutover-deploy-day-checklist.md)  
**Реестр прода:** `docs/project/project-docs.json` → `development.environments.machines.prod-fisheye`

---

## 1. Что делает пакет

Для каждой строки `sudz.cnInvCmm` / `sudz.cnInvCmmCst` (тип 2) с пустым `*Dv`, чья группа указана в `sudz.yr.yr_CmmGr` или `yr_CmmGr_New`, ищет доли `DbtValue` с крайней upl этого года назад к базе и сажает текст на найденные доли.

Группа, на которую год не смотрит, не меняется. На DEV 2026-10-16 это группы **903, 904, 905, 906** и остаток **907** (указатели уже на **1909**).

## 2. Чего пакет не делает

- Не добавляет колонки `*Dv` и не трогает схему `ags`. На копии FishEye у `ags.cnInvCmm` колонки `cnicDv` нет: `00` останавливается, если целиться не в `sudz`.
- Не удаляет группу 907.
- Не выбирает upl «вообще последнюю в базе», если у группы нет года.

DDL `*Dv` на прод — отдельное окно (черновики `26-0908-sudz-split-merge-dev/02` и `05` написаны для DEV `sudz` и на прод сами по себе не переносятся). Пока ворота `00` не печатают `gate OK`, скрипт `02` не запускать.

## 3. День применения

1. Бэкап базы.
2. `00_VERIFY_before.sql` — `package_compat = OK for MSSQL2012 package` и `gate OK`.
3. `01_DRYCHECK_cmm_Dv_walkback.sql` — сверить `would_bind` / `stay_no_year` с ожиданием окна. На DEV репетиция 2026-10-16: у всех ещё пустых групп `would_bind = 0`.
4. `02_MIGRATE_cmm_Dv_walkback.sql` в одном окне (внутри есть `BEGIN/COMMIT`).
5. `03_VERIFY_after.sql` — у связанных групп `null_dv` только там, где в году нет Value.
6. Если шаг 4 повредил данные — восстановить бэкап. `04_ROLLBACK.sql` только сообщает об этом и сам строки не чистит.

Клиенты Access, которые пишут в `ags.cnInvCmm` без `*Dv`, этим пакетом не переводятся.
