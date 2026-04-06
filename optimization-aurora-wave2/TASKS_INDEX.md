# Реестр задач — волна 2 (TASK-011+)

**Легенда статусов:** `не начато` | `в работе` | `сделано` | `частично` | `отменено`

Обновляй статус при старте и завершении. После завершения — ссылка на дату и TASK-ID в `JOURNAL.md`.

| ID | Кратко | Статус | ТЗ |
|----|--------|--------|-----|
| TASK-011 | SLIPPER: агрессивнее движок (FPS, физика, Y-sort, лимиты clamp) | сделано — [2026-04-06](JOURNAL.md) | [tasks/TASK-011-slipper-engine-aggressive-wave2.md](tasks/TASK-011-slipper-engine-aggressive-wave2.md) |
| TASK-012 | SLIPPER: троттлинг записи сохранения на диск (интервал, срочный flush) | сделано — [2026-04-06](JOURNAL.md) | [tasks/TASK-012-slipper-save-disk-throttle.md](tasks/TASK-012-slipper-save-disk-throttle.md) |
| TASK-013 | SLIPPER: сцена и декор — меньше активного мира (cull, слои, радиусы) | сделано — [2026-04-06](JOURNAL.md) | [tasks/TASK-013-slipper-scene-partial-activation.md](tasks/TASK-013-slipper-scene-partial-activation.md) |
| TASK-014 | SLIPPER: реже игровые циклы и вспомогательные системы (`_process` / таймеры) | сделано — [2026-04-06](JOURNAL.md) | [tasks/TASK-014-slipper-process-systems-throttle.md](tasks/TASK-014-slipper-process-systems-throttle.md) |
| TASK-015 | SLIPPER: бюджет врагов/снарядов/логики боя на дистанции | сделано — [2026-04-06](JOURNAL.md) | [tasks/TASK-015-slipper-combat-distant-budget.md](tasks/TASK-015-slipper-combat-distant-budget.md) |
| TASK-016 | SLIPPER: HUD, всплывающий урон, UI без лишних обновлений | сделано — [2026-04-06](JOURNAL.md) | [tasks/TASK-016-slipper-hud-floating-combat-ui.md](tasks/TASK-016-slipper-hud-floating-combat-ui.md) |
| TASK-017 | SLIPPER: отключение тяжёлых визуальных эффектов в сценах (не импорт) | сделано — [2026-04-06](JOURNAL.md) | [tasks/TASK-017-slipper-visual-effects-in-scenes.md](tasks/TASK-017-slipper-visual-effects-in-scenes.md) |
| TASK-018 | SLIPPER: навигация и вспомогательные подсистемы (реже обновления) | сделано — [2026-04-06](JOURNAL.md) | [tasks/TASK-018-slipper-navigation-subsystems.md](tasks/TASK-018-slipper-navigation-subsystems.md) |
| TASK-019 | Приёмка волны 2 и синхронизация чек-листа | сделано — [2026-04-06](JOURNAL.md) | [tasks/TASK-019-wave2-acceptance-and-docs-sync.md](tasks/TASK-019-wave2-acceptance-and-docs-sync.md) |
| TASK-020 | SLIPPER: деревья/кусты (миграция тайлов) — статичный первый кадр | сделано — [2026-04-06](JOURNAL.md) | [tasks/TASK-020-slipper-trees-boosh-static-first-frame.md](tasks/TASK-020-slipper-trees-boosh-static-first-frame.md) |

## Рекомендуемый порядок

1. **TASK-011** задаёт числовой потолок движка для SLIPPER — удобно первым или согласовать с **TASK-014**.
2. **TASK-012** можно параллельно с **TASK-013**–**018** (разные подсистемы); внимание к гонкам при выходе из игры.
3. **TASK-019** — после того, как ключевые задачи доведены до `сделано` или осознанно `частично`.
