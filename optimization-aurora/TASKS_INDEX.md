# Реестр задач оптимизации

**Легенда статусов:** `не начато` | `в работе` | `сделано` | `отменено`

Обновляй статус при старте и завершении задачи. После завершения — ссылка на запись в `JOURNAL.md` (дата и TASK-ID).

| ID | Кратко | Статус | ТЗ |
|----|--------|--------|-----|
| TASK-001 | Режим «На тапке»: enum, SaveManager, меню настроек | сделано | [tasks/TASK-001-slipper-mode-core.md](tasks/TASK-001-slipper-mode-core.md) — журнал 2026-04-05 |
| TASK-002 | Движок под «На тапке»: FPS, физика, VSync, Y-sort | сделано | [tasks/TASK-002-engine-tuning-slipper.md](tasks/TASK-002-engine-tuning-slipper.md) — журнал 2026-04-05 |
| TASK-003 | Погода и частицы: дождь и тяжёлые эффекты | сделано | [tasks/TASK-003-weather-particles-slipper.md](tasks/TASK-003-weather-particles-slipper.md) — журнал 2026-04-05 |
| TASK-004 | Импорт текстур: сжатие, mipmaps, лимиты размера | сделано | [tasks/TASK-004-texture-import-aurora.md](tasks/TASK-004-texture-import-aurora.md) — журнал 2026-04-05 |
| TASK-005 | Масштаб рендера / viewport / UI под слабое железо | сделано | [tasks/TASK-005-render-scale-slipper.md](tasks/TASK-005-render-scale-slipper.md) — журнал 2026-04-05 |
| TASK-006 | Звук: бюджет полифонии и упрощения Audio | сделано | [tasks/TASK-006-audio-budget-slipper.md](tasks/TASK-006-audio-budget-slipper.md) — журнал 2026-04-05 |
| TASK-007 | Профилирование и снижение аллокаций в GDScript | сделано | [tasks/TASK-007-profiling-gdscript-hotspots.md](tasks/TASK-007-profiling-gdscript-hotspots.md) — журнал 2026-04-05 |
| TASK-008 | Сцены: отсечение дальних объектов, упрощение декора | сделано | [tasks/TASK-008-scene-visibility-culling.md](tasks/TASK-008-scene-visibility-culling.md) — журнал 2026-04-05 |
| TASK-009 | CanvasLayer / HUD: лишние перерисовки и порядок слоёв | сделано | [tasks/TASK-009-ui-canvas-hud-slipper.md](tasks/TASK-009-ui-canvas-hud-slipper.md) — журнал 2026-04-05 |
| TASK-010 | Критерии приёмки и чек-лист перед релизом на Аврору | сделано | [tasks/TASK-010-acceptance-checklist-aurora.md](tasks/TASK-010-acceptance-checklist-aurora.md) — журнал 2026-04-05; [ACCEPTANCE_AURORA.md](ACCEPTANCE_AURORA.md) |

## Зависимости (рекомендуемый порядок)

1. **TASK-001** → **TASK-002** (сначала стабильный enum и UI, потом числа в пресете).
2. **TASK-003**–**TASK-009** можно распределять параллельно разным веткам или исполнителям после **TASK-001**, но каждый должен проверять `PerformancePreset` / `SaveManager.performance_mode` на наличие режима «На тапке».
3. **TASK-010** — последним или итеративно после каждой крупной волны.
