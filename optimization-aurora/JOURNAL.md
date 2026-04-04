# Журнал оптимизации (ОС Аврора / режим «На тапке»)

**Назначение:** единая хронология работ по оптимизации. После выполнения задачи исполнитель добавляет **одну новую запись** в конец файла (append-only по смыслу; старые записи не переписывать).

## Как писать запись (обязательный формат)

Скопируй шаблон, заполни все поля:

```
### YYYY-MM-DD — TASK-XXX — <краткий заголовок>
**Исполнитель / сессия:** <опционально: кратко, кто внёс запись>
**Статус задачи:** выполнено | частично | заблокировано (причина)

**Сделано:**
- …

**Изменённые файлы (пути от корня репозитория):**
- …

**Проверка:** <как проверялось: запуск редактора, сцена, устройство — или «не запускалось»>

**Заметки / риски для следующих задач:**
- …
```

---

## Записи

### 2026-04-05 — TASK-001 — Режим «На тапке»: enum SLIPPER, SaveManager, настройки
**Исполнитель / сессия:** —
**Статус задачи:** выполнено

**Сделано:**
- В `PerformancePreset.Mode` добавлен `SLIPPER = 4` (совместимость старых сохранений: 0–3 без смены смысла); `clamp_mode` расширен до 0..4.
- В `apply_from_save_manager` отдельная ветка `Mode.SLIPPER` (временно те же числа, что у MINIMAL, для TASK-002).
- В `Save_manager.gd` комментарий о миграции `performance_mode` 0..3 и новом значении 4.
- В `settings_overlay`: пункт «На тапке», маппинг индексов списка на enum, описание режима (1–2 предложения).

**Изменённые файлы (пути от корня репозитория):**
- `honor-of-aurora/autoload/performance_preset.gd`
- `honor-of-aurora/autoload/Save_manager.gd`
- `honor-of-aurora/ui/menu/settings_overlay.gd`

**Проверка:** статический разбор кода и согласованность enum/UI; редактор Godot не запускался в этой сессии.

**Заметки / риски для следующих задач:**
- **TASK-002:** задать отдельные `max_fps` / физику / Y-sort для `SLIPPER` в `performance_preset.gd`.
- **Рекомендация (вне TASK-001):** при появлении других мест с жёстким перечислением режимов — проверить их на `Mode.SLIPPER`.

### 2026-04-05 — TASK-002 — Движок «На тапке»: FPS, физика, VSync, Y-sort
**Исполнитель / сессия:** —
**Статус задачи:** выполнено

**Сделано:**
- Для `PerformancePreset.Mode.SLIPPER`: `Engine.max_fps` 30 (через `max_fps_val`), `physics_ticks_per_second` 30, `YSortManager.refresh_every_frames` 8 (агрессивнее, чем MINIMAL с 4), VSync `DisplayServer.VSYNC_ENABLED`.
- Подсказка в настройках для «На тапке» приведена к тем же числам.
- Проверено: `GameManager` после смены сцены вызывает `SaveManager.apply_window_and_engine_settings()` → `PerformancePreset.apply_from_save_manager`; отдельных расхождений не найдено, правки в `GameManager.gd` не требовались.

**Изменённые файлы (пути от корня репозитория):**
- `honor-of-aurora/autoload/performance_preset.gd`
- `honor-of-aurora/ui/menu/settings_overlay.gd`

**Проверка:** статический разбор кода и поиск вызовов; редактор Godot не запускался.

**Заметки / риски для следующих задач:**
- **Рекомендация:** на целевом устройстве или сцене с большим числом `y_sortable` проверить артефакты порядка отрисовки при интервале Y-sort 8 кадров; при проблемах вернуть 4 только для SLIPPER или оставить 8 и ослабить в другом месте.
- **Рекомендация:** VSync оставлен включённым; отключение или `MAILBOX` — только после замеров на Авроре (вне объёма TASK-002).

### 2026-04-05 — TASK-003 — Погода: оверлей дождя отключён в режиме «На тапке»
**Исполнитель / сессия:** —
**Статус задачи:** выполнено

**Сделано:**
- В `PerformancePreset` добавлена централизованная проверка `is_slipper_mode(sm: Node)` через `SaveManager.performance_mode` и `Mode.SLIPPER`.
- В `RainSystem`: метод `should_show_rain_overlay()` — дождь визуально только если погодный цикл активен и режим не SLIPPER; `get_monster_kill_reward_multiplier()` и `is_rain_weather_active()` без изменений (x2 лута при дожде сохраняется).
- `sync_rain_overlay_for_scene` и `base_island_rain.refresh_rain_state` опираются на `should_show_rain_overlay()` — на «На тапке» узел с `CPUParticles2D` не создаётся / скрывается, меньше нагрузки, чем при «Минимальный» с тем же дождём.
- По поиску `GPUParticles2D` / `CPUParticles2D` в `honor-of-aurora/` частицы погоды встречаются только в `environment/weather/base_island_rain.*`; других эффектов этого типа в проекте не найдено.

**Изменённые файлы (пути от корня репозитория):**
- `honor-of-aurora/autoload/performance_preset.gd`
- `honor-of-aurora/autoload/rain_system.gd`
- `honor-of-aurora/environment/weather/base_island_rain.gd`

**Проверка:** статический разбор и согласованность с `enemy_base` (награда по `get_monster_kill_reward_multiplier()`); редактор Godot не запускался.

**Заметки / риски для следующих задач:**
- **Рекомендация:** при смене пресета в настройках без смены сцены оверлей дождя обновится при следующем `GameManager` → `sync_rain_overlay_for_scene`; при необходимости мгновенного отклика можно вызвать синхронизацию из обработчика смены `performance_mode` (вне объёма TASK-003).

### 2026-04-05 — TASK-004 — Импорт текстур: VRAM, лимит размера (Terrain + Resources)
**Исполнитель / сессия:** —
**Статус задачи:** выполнено

**Сделано:**
- Выбраны **две категории** без массового трогания всего проекта: (1) **`Asets/Environment/Terrain/`** — тайлы земли/воды/пены/камней/моста; (2) **`Asets/Environment/Resources/`** — шахты, деревья, овцы, спрайты ресурсов на карте. Не затронуты `images/Logo/`, `icons/`, `Asets/Environment/UI/` (читаемость UI/иконок).
- Для всех **26** файлов `*.png.import`: `compress/mode=2` (VRAM Compressed), согласовано с `project.godot` → `textures/vram_compression/import_etc2_astc=true` (GL Compatibility / мобильные GPU).
- **`process/size_limit=2048`** — ограничение максимальной стороны для телефонного viewport (1280×720 и слабее), без лишнего разрешения в VRAM.
- **Mipmaps выключены** (`mipmaps/generate=false`) для обеих категорий: пиксель-арт и тайловые атласы — иначе риск размытия стиля (по ТЗ — «с осторожностью»); выигрыш — в сжатии и лимите размера.

**Изменённые файлы (пути от корня репозитория):**
- `honor-of-aurora/Asets/Environment/Terrain/Bridge/Bridge_All.png.import`
- `honor-of-aurora/Asets/Environment/Terrain/Ground/Shadows.png.import`
- `honor-of-aurora/Asets/Environment/Terrain/Ground/Tilemap_Elevation.png.import`
- `honor-of-aurora/Asets/Environment/Terrain/Ground/Tilemap_Flat.png.import`
- `honor-of-aurora/Asets/Environment/Terrain/Water/Water.png.import`
- `honor-of-aurora/Asets/Environment/Terrain/Water/Foam/Foam.png.import`
- `honor-of-aurora/Asets/Environment/Terrain/Water/Rocks/Rocks_01.png.import` … `Rocks_04.png.import`
- `honor-of-aurora/Asets/Environment/Resources/Gold Mine/GoldMine_Active.png.import` … `GoldMine_Destroyed.png.import`, `GoldMine_Inactive.png.import`
- `honor-of-aurora/Asets/Environment/Resources/Resources/*.png.import` (G_/M_/W_ Idle/Spawn, с вариантами NoShadow)
- `honor-of-aurora/Asets/Environment/Resources/Sheep/HappySheep_*.png.import`
- `honor-of-aurora/Asets/Environment/Resources/Trees/Tree.png.import`

**Проверка:** правки формата `.import` сверены с текущей схемой Godot 4; исполняемый Godot в PATH на локальной машине не найден — **открытие сцены и меню в редакторе не выполнялось**; после `git pull` рекомендуется открыть проект в Godot 4.4, дождаться реимпорта и проверить остров/меню на отсутствие битых/розовых текстур.

**Заметки / риски для следующих задач:**
- **Рекомендация:** при появлении крупных некропельных спрайтов с сильным масштабом вдали — точечно включить `mipmaps/generate=true` только для них (не для тайлмапов).
- **Рекомендация:** для новых импортов можно рассмотреть `[importer_defaults]` в `project.godot` — только после согласования, чтобы не затронуть логотип и мелкий UI по умолчанию.
- **Рекомендация:** следующая волна — другие тяжёлые папки (`Asets/...` вне Terrain/Resources, при необходимости — выборочно `Environment/UI` баннеры), отдельной задачей.

### 2026-04-05 — TASK-005 — Масштаб рендера «На тапке» (viewport stretch ~75%)
**Исполнитель / сессия:** —
**Статус задачи:** выполнено

**Сделано:**
- Использован механизм Godot 4.4: для `PerformancePreset.Mode.SLIPPER` корневое окно переводится в `Window.CONTENT_SCALE_MODE_VIEWPORT` с `content_scale_factor = 4/3` — внутренний буфер ~960×540 при базе 1280×720 (~56% пикселей от полного кадра), затем апскейл на размер окна; логические координаты и hit-test остаются в базовом размере (как в документации «viewport stretch»).
- Для остальных пресетов восстановлено поведение как в `project.godot`: `CONTENT_SCALE_MODE_CANVAS_ITEMS` и `content_scale_factor = 1.0` (без регрессии для существующего пути UI через `ui_scale_percent` и группу `hud`).
- Константа `PerformancePreset.SLIPPER_RENDER_STRETCH_SCALE`; подсказка в настройках для «На тапке» дополнена фразой про внутренний рендер.

**Изменённые файлы (пути от корня репозитория):**
- `honor-of-aurora/autoload/performance_preset.gd`
- `honor-of-aurora/autoload/Save_manager.gd`
- `honor-of-aurora/ui/menu/settings_overlay.gd`

**Проверка:** согласованность с документацией Godot 4.4 (stretch scale при viewport mode); редактор Godot в этой сессии не запускался.

**Заметки / риски для следующих задач:**
- **Рекомендация:** на устройстве ОС Аврора проверить отсутствие артефактов/чёрных полос при `aspect=expand` и читаемость шрифтов; при слишком мягкой картинке можно снизить factor до 1.25 или точечно поднять эффективный `ui_scale_percent` только в SLIPPER (отдельное согласование).
- **Рекомендация:** если понадобится ещё сильнее грузить GPU — рассмотреть `SLIPPER_RENDER_STRETCH_SCALE = 2.0` (половина разрешения по сторонам) после проверки UI.

### 2026-04-05 — TASK-006 — Звук «На тапке»: бюджет SFX, throttle шагов
**Исполнитель / сессия:** —
**Статус задачи:** выполнено

**Сделано:**
- Проанализирован `SoundManager`: все несущие SFX — пул из `AudioStreamPlayer` (не 2D), размер 8; при переполнении раньше всегда перезаписывался канал 0. Отдельных `AudioStreamPlayer2D` в проекте не найдено.
- Для `PerformancePreset.is_slipper_mode(SaveManager)`: для «второстепенных» SFX (`allow_drop`) одновременно используются не более **4** голосов из пула; при занятости новый звук **отбрасывается** (не крадёт канал у UI/диалогов/критичных боевых сигналов).
- К `allow_drop` отнесены: взмахи атак, попадания по врагам, шаги, подбор золота, лечение (много событий в бою). Без `allow_drop` остаются UI, Dialogue, музыка, получение урона игроком, смерть, щит, уровень-ап, меню.
- В SLIPPER для шагов добавлен **throttle** минимум ~0.14 с между `play_footstep()` — меньше вызовов без полной потери обратной связи.
- `apply_user_volume_settings` / шины `volume_*` не менялись.

**Изменённые файлы (пути от корня репозитория):**
- `honor-of-aurora/autoload/SoundManager.gd`

**Проверка:** статический разбор и поиск `AudioStreamPlayer`/`AudioStreamPlayer2D`; редактор Godot не запускался.

**Заметки / риски для следующих задач:**
- **Рекомендация:** при смене пресета без перезагрузки сцены полифония SLIPPER применяется сразу (чтение `SaveManager` на каждый вызов). Если появятся локальные `AudioStreamPlayer` вне `SoundManager` — вынести в общий пул или дублировать политику (вне объёма TASK-006).
- **Рекомендация:** на устройстве с замером профайлера подтвердить снижение нагрузки в стресс-бою; при слишком «пустом» звуке в SLIPPER можно поднять `_SLIPPER_SFX_VOICES` до 5–6 без трогания громкостей.

### 2026-04-05 — TASK-007 — GDScript: меньше аллокаций в горячих путях (character_unit, дождь, овцы)
**Исполнитель / сессия:** —
**Статус задачи:** выполнено

**Сделано:**
- **Профайлер (ожидание vs факт):** в сессии редактор Godot не запускался — нет выгрузки Functions/Memory. По коду отмечены типичные горячие пути: `_physics_process` у юнитов с `get_nodes_in_group`, `_process` у оверлея дождя при активной погоде, базовые проверки овец/рабочих.
- **`character_unit.gd` — до:** на каждый юнит с включённым soft separation вызывались **два** `get_nodes_in_group("character_unit")` подряд (босс + отряд). **После:** один вызов после `get_node_count_in_group`, общий `Array` передаётся в `_apply_boss_radius_separation` и в цикл отталкивания — **вдвое меньше** аллокаций массива группы на юнит за тик физики (логика и силы без изменений).
- **`base_island_rain.gd` — до:** при отсутствии камеры у viewport каждый кадр `_process` обходил группу `player`. **После:** кэш `Camera2D` с узла игрока, сброс при появлении viewport-камеры или смене валидной камеры — реже обход группы (оверлей дождя только без режима «На тапке», см. TASK-003).
- **`sheep_resource.gd` — до:** при проверке анимации рабочего `String(an)` на каждую итерацию рядом с овцой. **После:** `StringName.begins_with("interact")` без лишней конвертации в `String`.

**Изменённые файлы (пути от корня репозитория):**
- `honor-of-aurora/characters/character_unit.gd`
- `honor-of-aurora/environment/weather/base_island_rain.gd`
- `honor-of-aurora/objects/world/sheep_resource.gd`

**Проверка:** статический разбор и линтер по изменённым `.gd`; встроенный Profiler Godot в этой сессии не запускался.

**Заметки / риски для следующих задач:**
- **Рекомендация:** на целевой сборке открыть Profiler (Script Time / Memory) в бою и на базе с овцами — подтвердить снижение для `_apply_soft_separation_to_velocity` и при необходимости искать следующий слой (например единый кэш списка `character_unit` раз на тик, если узлов много).
- **Рекомендация:** `mine_off_visual.gd` и другие `_process` с `get_nodes_in_group("ally_pawn")` каждый кадр на базе — кандидаты на реже обновление или кэш в отдельной задаче (вне объёма TASK-007).

### 2026-04-05 — TASK-008 — Сцены: отсечение дальнего декора в SLIPPER (остров 1)
**Исполнитель / сессия:** —
**Статус задачи:** выполнено

**Сделано:**
- **Тестовая сцена:** `Game/Game_level_1.tscn` (остров 1) — крупная локация с множеством слоёв `tile_layer_trees_y_sort_migrate` (деревья + декор).
- **Механизм:** после миграции тайлов в спрайты слой добавляется в группу `slipper_cull_decor_layer`. На острове 1 узел `SlipperDecorDistanceCull` (`slipper_decor_distance_cull.gd`) при `PerformancePreset.is_slipper_mode(SaveManager)` раз в 4 кадра сравнивает расстояние от игрока (или камеры) до центра содержимого слоя; за пределами радиуса (~2400 px, export) слой скрывается, `process_mode` отключается, дочерние `Sprite2D`/`AnimatedSprite2D` убираются из `y_sortable` (и анимированные — из `wind_decor_sprite`), чтобы **YSortManager** не обходил сотни декоративных спрайтов. При выходе из SLIPPER или при возврате в радиус — восстановление видимости и групп.
- **Профилирование:** в этой сессии редактор Godot не запускался; ожидаемый эффект — меньше узлов в группе `y_sortable` при удалении камеры/игрока от кучи декора и меньше работы в `YSortManager._process` (см. замеры Profiler на устройстве).

**Изменённые файлы (пути от корня репозитория):**
- `honor-of-aurora/world/decor/slipper_decor_distance_cull.gd`
- `honor-of-aurora/world/decor/slipper_decor_distance_cull.gd.uid`
- `honor-of-aurora/world/decor/tile_layer_trees_y_sort_migrate.gd`
- `honor-of-aurora/Game/Game_level_1.tscn`

**Проверка:** статический разбор и линтер по новым/изменённым `.gd`; сцена в редакторе не открывалась.

**Заметки / риски для следующих задач:**
- **Рекомендация:** для других тяжёлых островов (`Game_level_2`, база и т.д.) при необходимости добавить такой же узел-потомок `island` с тем же скриптом (группа уже заполняется из миграции слоёв).
- **Рекомендация:** на Авроре в Profiler сравнить число объектов в `y_sortable` и время `YSortManager` до/после при уходе героя в «пустую» зону карты; при «мелькании» декора на границе радиуса — гистерезис или больший радиус (отдельная настройка).

### 2026-04-05 — TASK-009 — UI: HUD и тач-слой, реже обновление в SLIPPER
**Исполнитель / сессия:** —
**Статус задачи:** выполнено

**Сделано:**
- **Инвентаризация HUD (верхняя полоса и связанные инстансы):** полоса HP (`texture_progress_bar.gd`) и счётчики ресурсов (`resource_counter.gd`) обновляются по сигналам (`health_changed`, `gold_changed` и т.д.), не в `_process` каждый кадр. Броня (`HUD._refresh_armor_hud`) — по `Events.location_changed` и `Events.armor_durability_changed`. Единственный постоянный `_process` в дереве `canvas_layer.tscn` среди UI критичного HUD — **`MobileTouchControls`**: каждый кадр вызывался `_refresh_visibility()` (видимость тач-оверлея, кнопки rally/rest на острове).
- **«На тапке»:** для `MobileTouchControls` введён throttle **раз в 3 кадра** для `_refresh_visibility` в `_process` (диапазон 2–5 по ТЗ). Чтобы не отставала смена локации и настройки тач-зон после ресайза: добавлены немедленные вызовы `_refresh_visibility` по `Events.location_changed` и в конце `apply_user_touch_settings()` (после масштабирования зон).
- **Шейдеры/тени на TopHudBar:** в сценах верхней полосы (`gold.tscn`, `ore_counter.tscn` и т.д.) иконки без `ShaderMaterial`; отдельного отключения шейдеров для SLIPPER не потребовалось. Тени Label/темы на этих узлах в сценах не заданы.

**Изменённые файлы (пути от корня репозитория):**
- `honor-of-aurora/ui/mobile_touch_controls/mobile_touch_controls.gd`

**Проверка:** статический разбор и линтер по изменённому `.gd`; редактор Godot не запускался.

**Заметки / риски для следующих задач:**
- **Рекомендация (вне TASK-009):** `VirtualJoystick` / `moba_action_button` используют `queue_redraw` при вводе — при профилировании на Авроре при необходимости ограничить частоту перерисовки только при активном касании.
- **Рекомендация:** объединять/упрощать `CanvasLayer` в корне HUD без отдельного согласования не делалось (в ТЗ — снижение перерисовок, не перестройка иерархии слоёв).

### 2026-04-05 — TASK-010 — Чек-лист приёмки и критерии перед релизом на Аврору
**Исполнитель / сессия:** —
**Статус задачи:** выполнено

**Сделано:**
- Проверены `JOURNAL.md` и `TASKS_INDEX.md`: задачи TASK-001…TASK-009 в журнале со статусом **выполнено**; задач со статусом «отменено» нет.
- Добавлен единый документ с чек-листом в markdown-таблице: `optimization-aurora/ACCEPTANCE_AURORA.md` (первый запуск/миграция, все пресеты включая «На тапке», дождь логика+визуал, бой с толпой/FPS, меню и HUD, звук, выход и повторный вход; колонка Pass/Fail).
- Зафиксированы **известные ограничения** (Y-sort раз в 8 кадров, дождь без оверлея на «На тапке», viewport stretch, отсечение декора, throttle тач-HUD).
- Ссылка на чек-лист добавлена в таблицу «Как пользоваться» в `optimization-aurora/README.md` (дублирования отдельного раздела с полным текстом чек-листа нет).

**Изменённые файлы (пути от корня репозитория):**
- `optimization-aurora/ACCEPTANCE_AURORA.md` (новый)
- `optimization-aurora/README.md`
- `optimization-aurora/TASKS_INDEX.md`

**Проверка:** сверка по `JOURNAL.md` и `TASKS_INDEX.md` статическим чтением; игровой клиент и редактор Godot в этой сессии не запускались.

**Заметки / риски для следующих задач:**
- **Рекомендация:** после изменений кода режима «На тапке» обновлять `ACCEPTANCE_AURORA.md` и строки с ожидаемыми результатами в таблице.
