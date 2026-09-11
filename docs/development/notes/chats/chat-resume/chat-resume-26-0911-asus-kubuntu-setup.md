# Резюме: донастройка FEMSQ на asus-kubuntu (Kubuntu 24.04)

**Дата:** 2026-09-11  
**Статус:** ✅ завершено (этапы 0–6)  
**Чат журнала:** `chat-2026-09-11-001` — Донастройка asus-kubuntu (active, medium)  
**План:** [chat-plan-26-0911-asus-kubuntu-setup.md](../chat-plan/chat-plan-26-0911-asus-kubuntu-setup.md)  
**Дока remote:** [remote-development-nb-win.md](../../../remote-development-nb-win.md)

## Итог

Машина `asus-kubuntu` — полноценная remote-станция FEMSQ (профиль как `alex-fedora`): WireGuard → Docker SQL на nb-win (`10.7.0.3`). Сборка `0.1.0.270-SNAPSHOT` и health к FishEye подтверждены.

## Сделано

| Этап | Результат |
|------|-----------|
| 0 Аудит | Hostname не был в реестре; VPN/SMB/SQL уже OK |
| 1 Реестр | `asus-kubuntu` в `project-docs.json` + `environments.json`; `setup-cursor-mcp.sh` |
| 2 Toolchain | Temurin 21 / Maven 3.9.11 / Node 20.19.5 в `~/.local` (без sudo) |
| 3 Конфиг | `~/.femsq/database.properties`; MCP remote; SQL smoke + DBHub green |
| 4 feQuLib | Клон `/home/alex/projects/java/spring/vue/feQuLib`; `check-fequlib.sh` OK |
| 5 Дока | `remote-development-nb-win.md` (Fedora + Kubuntu) + это резюме |
| 6 Приёмка | JAR `0.1.0.270`; `/api/v1/connection/status` → 200, `FishEye`/`ags` |
| Секреты | `~/.config/secrets/{github,femsq-db}.env` (600) |

## Приёмка сборки (заметки)

Первый `build-thin-jar` упал на Vite: `echarts/core` из `FemsqChart` (feQuLib). Исправлено:

- зависимости `echarts` / `vue-echarts` в `femsq-frontend-q`
- `npm install` в feQuLib
- `dedupe: ['echarts', 'vue-echarts']` в `vite.config.ts`

Версия увеличена один раз: `0.1.0.269` → `0.1.0.270`. Thin-скрипт после фейла не перезапускался целиком; fat JAR собран и проверен.

## Ключевые пути

- FEMSQ: `/home/alex/projects/java/spring/vue/femsq`
- feQuLib: `/home/alex/projects/java/spring/vue/feQuLib`
- JAR: `code/femsq-backend/femsq-web/target/femsq-web-0.1.0.270-SNAPSHOT.jar`
- DB: `10.7.0.3:1433` / `FishEye` / schema `ags`
- Excel share: `/mnt/nb-win-share/femsq/excel`

## Опционально позже

- apt/`curl`/sqlcmd (системный toolchain)
- Ротация GitHub-токена
- RAM 16+ GiB (сейчас ~8 GiB тесно)
