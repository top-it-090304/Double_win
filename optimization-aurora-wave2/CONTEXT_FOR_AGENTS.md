# Контекст для агента: волна 2 оптимизации (режим «На тапке»)

## 1. Репозиторий и движок

- Корень репозитория: `Double_win`. Игра: **`honor-of-aurora/`** (Godot **4.4**, рендер **GL Compatibility**).
- Целевая платформа: ОС **Аврора**, очень слабое железо.

## 2. Связь с первой волной

- Задачи **TASK-001…010** и журнал первой волны: **`optimization-aurora/`** (не переписывать старые записи).
- Задачи **TASK-011 и выше** — **только** в этой папке: `optimization-aurora-wave2/`.
- После работы по задаче волны 2: **одна** новая запись в **`optimization-aurora-wave2/JOURNAL.md`**, статус в **`optimization-aurora-wave2/TASKS_INDEX.md`**.

## 3. Режим «На тапке» — единственный переключатель оптимизаций волны 2

- В коде режим задаётся через **`SaveManager.performance_mode`** и **`PerformancePreset.Mode.SLIPPER`**.
- **Обязательно:** любая оптимизация волны 2 активна **только если** `PerformancePreset.is_slipper_mode(SaveManager)` возвращает `true`.
- **Запрещено:** ослаблять геймплей, графику или частоту симуляции **глобально** для всех пресетов «ради Авроры». Исключение — рефактор с сохранением старого поведения для MINIMAL/MEDIUM/MAXIMUM и новой веткой только для SLIPPER.

## 4. Что НЕ входит в объём волны 2 (критично)

- **Не** менять скрипты/настройки **экспорта**, CI, шаблоны сборки под Аврору, если они лежат вне игрового рантайма.
- **Не** заниматься «оптимизацией портирования» как процесса; **не** массово переключать импорт текстур в `.png.import` **как основную задачу**, если это не следует напрямую из ТЗ конкретной задачи (в волне 2 приоритет — логика игры, частоты, отсечение в сценах).
- **Не** менять лор, диалоги и баланс чисел (урон, цены) без явного указания в задаче.
- Любое снижение `physics_ticks_per_second` ниже уже согласованного для SLIPPER — **только** с комментарием о риске для боёвки и проверкой геймплея.

## 5. Уже существующие точки оптимизации (прочитать перед дублированием)

| Компонент | Путь / заметка |
|-----------|------------------|
| Пресеты FPS, физика, VSync, Y-sort | `honor-of-aurora/autoload/performance_preset.gd` — `apply_from_save_manager`, ветка `Mode.SLIPPER` |
| Окно, viewport stretch в SLIPPER | `honor-of-aurora/autoload/Save_manager.gd` — `apply_window_and_engine_settings`, `PerformancePreset.should_apply_slipper_viewport_stretch` |
| Y-sort менеджер | `honor-of-aurora/autoload/YSortManager.gd` — `refresh_every_frames` (сейчас `@export_range(1, 8, 1)`) |
| Дождь: визуал выкл. в SLIPPER | `honor-of-aurora/autoload/rain_system.gd` |
| Декор: отсечение по дистанции | `honor-of-aurora/world/decor/slipper_decor_distance_cull.gd`, группа `slipper_cull_decor_layer` |
| Звук: лимит голосов, шаги | `honor-of-aurora/autoload/SoundManager.gd` |
| Тач: реже обновления | `honor-of-aurora/ui/mobile_touch_controls/mobile_touch_controls.gd` |
| Отложенное сохранение | `honor-of-aurora/autoload/Save_manager.gd` — `request_save_game_deferred`, `_flush_deferred_save_game` |

## 6. Критерий успеха волны 2

На устройстве или в редакторе: игрок выбирает **«На тапке»** → измеримо **меньше** нагрузка CPU/GPU/диска по сравнению с тем же прохождением на **«Минимальный»**, без поломки сохранений, без софтлоков, с приемлемой играбельностью. Конкретные проверки — в **`ACCEPTANCE_WAVE2_AURORA.md`**.

## 7. Обязательные действия после выполнения задачи (MUST)

1. Добавить запись в конец **`optimization-aurora-wave2/JOURNAL.md`** по шаблону из заголовка файла.
2. Обновить **`optimization-aurora-wave2/TASKS_INDEX.md`**.
3. Если задача не завершена — явно указать остаток и риски в журнале и пользователю.
