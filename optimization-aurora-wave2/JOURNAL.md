# Журнал оптимизации — волна 2 (ОС Аврора / режим «На тапке»)

**Назначение:** хронология работ по задачам **TASK-011 и выше**. Только **`optimization-aurora-wave2/JOURNAL.md`** — не добавлять сюда записи по TASK-001…010 (они в `optimization-aurora/JOURNAL.md`).

**Правило:** append-only по смыслу — новые записи **в конец**; старые не переписывать.

## Как писать запись (обязательный формат)

Скопируй шаблон, заполни все поля:

```
### YYYY-MM-DD — TASK-XXX — <краткий заголовок>
**Исполнитель / сессия:** <опционально>
**Статус задачи:** выполнено | частично | заблокировано (причина)

**Сделано:**
- …

**Изменённые файлы (пути от корня репозитория):**
- …

**Проверка:** <редактор, сцена, устройство — или «не запускалось»>

**Заметки / риски для следующих задач:**
- …
```

---

## Записи

### 2026-04-06 — TASK-011 — SLIPPER: агрессивнее движок (20 FPS, Y-sort ×16)
**Статус задачи:** выполнено

**Сделано:**
- Режим «На тапке» (`Mode.SLIPPER`): **20 FPS** (`Engine.max_fps`), **`physics_ticks_per_second` = 30** (без снижения ниже 30 — осознанно для снарядов), **Y-sort раз в 16 кадров** (`YSortManager.refresh_every_frames`).
- Нижняя граница **20** для `Engine.max_fps` применяется **только** в ветке SLIPPER; остальные пресеты по-прежнему clamp **30–240**.
- Расширен `@export_range` у `YSortManager.refresh_every_frames` до **1–16**; `PerformancePreset` clamp согласован с константой `YSORT_REFRESH_FRAMES_MAX`.
- Подсказка в настройках обновлена под новые числа.

**Изменённые файлы (пути от корня репозитория):**
- `honor-of-aurora/autoload/performance_preset.gd`
- `honor-of-aurora/autoload/YSortManager.gd`
- `honor-of-aurora/ui/menu/settings_overlay.gd`

**Проверка:** не запускалось (изменения по ТЗ; линтер по отредактированным файлам — без замечаний)

**Заметки / риски для следующих задач:**
- Рекомендуется ручная проверка боёвки и ввода на устройстве при 20 FPS и редком Y-sort; при артефактах слоёв — откат интервала Y-sort или FPS только после согласования.

### 2026-04-06 — TASK-012 — SLIPPER: троттлинг записи сохранения на диск
**Статус задачи:** выполнено

**Сделано:**
- В `Save_manager.gd` для режима «На тапке» введён минимальный интервал **3 с** между **«мягкими»** успешными записями на диск (`SLIPPER_SAVE_MIN_INTERVAL_SEC`); вне SLIPPER поведение как раньше — без троттлинга.
- `save_game(force: bool = false)`: `force=false` — мягкий путь (троттлинг в SLIPPER); `force=true` или `save_game_immediate()` — немедленная запись; `NOTIFICATION_WM_CLOSE_REQUEST` вызывает `save_game(true)` перед закрытием окна.
- Отложенный flush (`request_save_game_deferred` → `_flush_deferred_save_game`) идёт по **мягкому** пути; при отложении из-за троттлинга намерение сохраняется: флаг + `SceneTree.create_timer`, догоняющая запись в `_finish_slipper_soft_save_after_throttle` (в т.ч. если пресет сменили до таймера — запись не теряется).
- «Мягкими» оставлены только кодекс UI (`save_game(false)`) и deferred HP/уровень; остальные вызовы по коду помечены `SaveManager.save_game(true)` (ресурсы, сюжет, локации, покупки, миграции, смерть и т.д.).
- В debug-сборке считается `_slipper_debug_throttled_soft_saves` при пропуске мягкой записи (для замеров).

**Изменённые файлы (пути от корня репозитория):**
- `honor-of-aurora/autoload/Save_manager.gd`
- `honor-of-aurora/autoload/GameManager.gd`
- `honor-of-aurora/autoload/CrownSystem.gd`
- `honor-of-aurora/autoload/DifficultyConfig.gd`
- `honor-of-aurora/autoload/PostFinaleWorld.gd`
- `honor-of-aurora/autoload/StoryState.gd`
- `honor-of-aurora/autoload/rain_system.gd`
- `honor-of-aurora/ui/menu/settings_overlay.gd`
- `honor-of-aurora/ui/casle_minu/main/castle_main_menu.gd`
- `honor-of-aurora/ally/youth_worker/youth_worker_companion.gd`
- `honor-of-aurora/objects/world/chest/world_chest.gd`
- `honor-of-aurora/objects/buildings/building_template.gd`
- `honor-of-aurora/world/encounters/encounter_zone.gd`

**Проверка:** не запускалось (логика по ТЗ; линтер по `Save_manager.gd` — без замечаний)

**Заметки / риски для следующих задач:**
- На мобильных/встраиваемых без `NOTIFICATION_WM_CLOSE_REQUEST` полагаться на явные `save_game(true)` в геймплее и на догон при троттлинге; при необходимости — отдельный хук паузы/фона.
- Интервал 3 с для мягких событий: при жалобах на потерю прогресса при резком выходе — уменьшить только для SLIPPER или расширить список критичных `force`.

### 2026-04-06 — TASK-013 — SLIPPER: ужесточение distance-cull декора и узел на всех островах/базе
**Статус задачи:** выполнено

**Сделано:**
- В `slipper_decor_distance_cull.gd` для режима «На тапке» применены множители **TASK-013**: радиус отсечения **×0.75** к экспорту (по умолчанию ~1800 px вместо 2400), интервал полного прохода **×2** к `update_every_frames`, верхняя граница **16** кадров (согласовано с потолком Y-sort волны 2).
- Порядок в `_process`: сначала проверка SLIPPER и немедленное `_restore_all_under_island()` при выходе из режима (без задержки из-за троттлинга кадров).
- `@export_range` для `update_every_frames` расширен до **1–16**.
- Узел `SlipperDecorDistanceCull` добавлен в сцены **`Game_base_islad.tscn`**, **`Game_level_2.tscn` … `Game_level_5.tscn`** (раньше был только в `Game_level_1.tscn`), чтобы отсечение работало на базе и остальных островах с тем же паттерном `island` + `tile_layer_trees_y_sort_migrate`.

**Изменённые файлы (пути от корня репозитория):**
- `honor-of-aurora/world/decor/slipper_decor_distance_cull.gd`
- `honor-of-aurora/Game/Game_base_islad.tscn`
- `honor-of-aurora/Game/Game_level_2.tscn`
- `honor-of-aurora/Game/Game_level_3.tscn`
- `honor-of-aurora/Game/Game_level_4.tscn`
- `honor-of-aurora/Game/Game_level_5.tscn`

**Проверка:** не запускалось (изменения по ТЗ; линтер по `slipper_decor_distance_cull.gd` — без замечаний)

**Заметки / риски для следующих задач:**
- Глазами в SLIPPER: пройти базу и острова 1–5 — декор у игрока должен быть на месте; переключить пресет на «Минимальный» — весь декор снова виден.
- При «обрезании» дальнего декора на краю радиуса — подкрутить только множитель `_SLIPPER_CULL_RADIUS_MULT` или экспорт `cull_radius_pixels` в сцене.

### 2026-04-06 — TASK-014 — SLIPPER: реже вспомогательные `_process` (троттлинг на базе)
**Статус задачи:** выполнено

**Сделано:**
- Аудит `func _process` / `_physics_process` в `honor-of-aurora/`: критичный путь (бой, отдых с интерполяцией HP, ралли, дождь вне SLIPPER, магнит осколков и т.д.) не трогался.
- В режиме «На тапке» для слоя **«шахта выключена»** на базе (`mine_off_visual.gd`): полный обход `ally_pawn` и проверки назначения на руду выполняются **раз в 3 кадра** (`Engine.get_process_frames() % 3`), только обновление видимости декоративного тайл-слоя.

**Изменённые файлы (пути от корня репозитория):**
- `honor-of-aurora/world/islads/base/mine_off_visual.gd`

**Проверка:** не запускалось (изменения по ТЗ; линтер по отредактированному файлу — без замечаний)

**Заметки / риски для следующих задач:**
- При заметной задержке переключения иконки «шахта выключена» при назначении/снятии рудника — уменьшить **N** (сейчас 3) только в SLIPPER.

### 2026-04-06 — TASK-015 — SLIPPER: бюджет логики на дистанции (враги, снаряды)
**Статус задачи:** выполнено

**Сделано:**
- Добавлен `SlipperCombatBudget` (`slipper_combat_budget.gd`): константы порогов и проверка только при `PerformancePreset.is_slipper_mode(SaveManager)`.
- **Враги (`enemy_base.gd`):** если герой дальше **2000 px** и нет консервативной близости к герою (`attack_radius + 420 px`, overlap `AttackArea` при `monitoring`), тяжёлый AI (выбор цели по таймеру, навигация/лучи, soft-separation, анимация, anti-stuck) выполняется **раз в 4 физкадра**; в «лёгких» кадрах преследование — упрощённый вектор к цели без навигации. Состояния ATTACK/HIT/DEATH/LEASH/RECOVER и группа **BOSS** — без троттлинга (полный кадр).
- **Снаряды:** для стрелы лучника, гарпуна, кости гнолла, шаров шамана при расстоянии до героя **> 1600 px** каждый второй кадр `_process` только накапливает `delta`, затем движение за один шаг с суммой — **средняя скорость и коллизии по пути сохраняются** (без изменения урона).

**Изменённые файлы (пути от корня репозитория):**
- `honor-of-aurora/autoload/slipper_combat_budget.gd`
- `honor-of-aurora/enemies/enemy_base.gd`
- `honor-of-aurora/ally/archer/Arrow/arrow.gd`
- `honor-of-aurora/enemies/harpoon fish/harpoon_projectile.gd`
- `honor-of-aurora/enemies/gnoll/gnoll_bone.gd`
- `honor-of-aurora/enemies/shaman/shaman_lightning_ball.gd`

**Проверка:** не запускалось (логика по ТЗ; линтер по отредактированным файлам — без замечаний)

**Заметки / риски для следующих задач:**
- Дальние враги в SLIPPER могут чуть грубее обходить препятствия в «лёгких» кадрах; при артефактах — уменьшить `FAR_HEAVY_AI_INTERVAL_FRAMES` или увеличить `NEAR_FULL_AI_DISTANCE_PX` только в SLIPPER.
- Другие снаряды с собственным `_process` (если появятся) — по тому же паттерну накопления delta.

### 2026-04-06 — TASK-016 — SLIPPER: HUD и всплывающий урон без лишних обновлений
**Статус задачи:** выполнено

**Сделано:**
- В `GameplayFacade.spawn_damage_number`: при `PerformancePreset.is_slipper_mode(SaveManager)` лимит **14** одновременных всплывающих чисел урона на слое `DamageNumbersCanvasLayer`; при превышении новый визуал не создаётся — **урон по геймплею не меняется**.
- В `HUD.gd`: для SLIPPER обновление блока **процента брони** (второстепенно относительно HP) **дебаунсится** таймером **0,12 с** при сигнале `armor_durability_changed`; смена локации по-прежнему сразу вызывает `_refresh_armor_hud` (останов таймера + мгновенное обновление). Масштаб UI / `apply_user_ui_scale` не трогались.

**Изменённые файлы (пути от корня репозитория):**
- `honor-of-aurora/autoload/GameplayFacade.gd`
- `honor-of-aurora/ui/HUD/HUD.gd`

**Проверка:** не запускалось (логика по ТЗ; линтер по отредактированным файлам — без замечаний)

**Заметки / риски для следующих задач:**
- При жалобах на «пропадающие» цифры урона в SLIPPER — поднять `SLIPPER_MAX_DAMAGE_NUMBER_VISUALS` или снизить только там; при отстающем проценте брони в бою — уменьшить интервал дебаунса или убрать для брони.

### 2026-04-06 — TASK-017 — SLIPPER: тяжёлые визуальные эффекты в сценах (частицы, шейдеры UI)
**Статус задачи:** выполнено

**Сделано:**
- **Аудит:** по `honor-of-aurora/` в `.tscn` найдены только `CPUParticles2D` в `environment/weather/base_island_rain.tscn` (дождь); `GPUParticles2D` в сценах нет. Дождь уже скрыт в SLIPPER через `RainSystem.should_show_rain_overlay()`.
- **Синхронизация дождя при смене пресета:** в `Save_manager.apply_window_and_engine_settings` добавлен вызов `RainSystem.sync_rain_overlay_for_scene` для текущей сцены — при выходе из «На тапке» оверлей дождя снова появляется без перезагрузки сцены (если погода «дождь» по счётчику телепортов).
- **ShaderMaterial `ore_icon_gold`:** в SLIPPER снимается с иконок руды в меню стрельбища и монастыря (`slipper_ore_icon_shader_toggle.gd`, группа `slipper_visual_material_toggle` + вызов из `apply_window_and_engine_settings`); в панели добычи сундука (`chest_loot_panel.gd`) чип руды без шейдера в SLIPPER. Обратная связь боя/урона не трогалась.

**Изменённые файлы (пути от корня репозитория):**
- `honor-of-aurora/autoload/Save_manager.gd`
- `honor-of-aurora/autoload/rain_system.gd`
- `honor-of-aurora/ui/casle_minu/slipper_ore_icon_shader_toggle.gd` (новый)
- `honor-of-aurora/ui/casle_minu/archery/archery_menu.tscn`
- `honor-of-aurora/ui/casle_minu/monastery/monastery_menu.tscn`
- `honor-of-aurora/ui/chest/chest_loot_panel.gd`

**Проверка:** не запускалось (логика по ТЗ; линтер по новым/изменённым скриптам — без замечаний)

**Заметки / риски для следующих задач:**
- При появлении новых `*Particles2D` в сценах — по тому же паттерну: только SLIPPER + восстановление при смене пресета; критичный визуал боя не отключать без проверки.

### 2026-04-06 — TASK-018 — SLIPPER: навигация (NavigationAgent2D) — пороги и реже target_position
**Статус задачи:** выполнено

**Сделано:**
- В `SlipperCombatBudget` (TASK-018): для SLIPPER у врагов шире `path_desired_distance` / `target_desired_distance` (22/28 → 30/40 px), у пешек с `NavigationAgent2D` — 16/28 → 22/38; вне SLIPPER восстановление прежних значений.
- **Враги (`enemy_base.gd`):** пресет агента синхронизируется каждый кадр при активном агенте; в погоне `target_position` на цель обновляется **раз в 2 физкадра**, если герой дальше порогов TASK-015 (иначе каждый кадр: близкий бой / консервативная дистанция атаки / overlap `AttackArea`). Боссы без навигации — без изменений.
- **Рабочие (`pawn_base.gd`):** при `base_move_use_navigation_agent_path` то же троттлирование `target_position` к `_gather_target` по дистанции до игрока; пресет дистанций агента в `_physics_process`. Геометрия навигации и телепорты не трогались.

**Изменённые файлы (пути от корня репозитория):**
- `honor-of-aurora/autoload/slipper_combat_budget.gd`
- `honor-of-aurora/enemies/enemy_base.gd`
- `honor-of-aurora/ally/pawn/scripts/pawn_base.gd`

**Проверка:** не запускалось (логика по ТЗ; линтер по отредактированным файлам — без замечаний)

**Заметки / риски для следующих задач:**
- Затронутые типы: все наследники `enemy_base` с `use_navigation` и не-BOSS; пешки базы/островов с экспортом `base_move_use_navigation_agent_path` (по умолчанию выкл.).
- Если дальние враги в SLIPPER «отстают» от движущейся цели — уменьшить `NAV_TARGET_REFRESH_FAR_INTERVAL_FRAMES` до 1 или чаще обновлять только `target_position` без изменения TASK-015.

### 2026-04-06 — TASK-019 — Приёмка волны 2 и синхронизация документов
**Статус задачи:** выполнено

**Сделано:**
- **`ACCEPTANCE_WAVE2_AURORA.md`:** добавлена сводка **реальных** параметров SLIPPER по `JOURNAL.md` (движок TASK-011, сохранения TASK-012, декор TASK-013, шахта TASK-014, бой TASK-015, HUD TASK-016, визуал TASK-017, навигация TASK-018); расширен ручной чек-лист с однозначными ожиданиями и ссылками на ТЗ; убраны плейсхолдеры в духе «см. журнал» без конкретики.
- **`README.md`:** строка о дате последней синхронизации приёмки волны 2 (**2026-04-06**) и ссылка на чек-лист.
- **`optimization-aurora/ACCEPTANCE_AURORA.md`:** минимальная синхронизация — явная ссылка на актуальную приёмку волны 2; исправлены неверные номера задач волны 2 (Y-sort → **TASK-011**, числа урона → **14** / **TASK-016**, декор → **TASK-013**, текстуры импорта → **TASK-004**); **viewport stretch** приведён к коду (**4/3**, ~960×540 при 1280×720); таблица тач — **TASK-009** + уточнение про `queue_redraw`.

**Изменённые файлы (пути от корня репозитория):**
- `optimization-aurora-wave2/ACCEPTANCE_WAVE2_AURORA.md`
- `optimization-aurora-wave2/README.md`
- `optimization-aurora-wave2/TASKS_INDEX.md`
- `optimization-aurora/ACCEPTANCE_AURORA.md`

**Проверка:** сверка чисел с `JOURNAL.md` (волна 2) и с `honor-of-aurora/autoload/performance_preset.gd` для stretch; игру не запускалось.

**Заметки / риски для следующих задач:**
- При смене констант в коде — обновлять **оба** чек-листа (`ACCEPTANCE_WAVE2_AURORA.md` и при необходимости корневой `ACCEPTANCE_AURORA.md`) и журнал.
