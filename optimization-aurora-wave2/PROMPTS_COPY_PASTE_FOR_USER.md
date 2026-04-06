# Готовые промпты для чата (волна 2, TASK-011…019)

Скопируй **один** блок целиком для нужной задачи и вставь в начало сессии с агентом **без правок**.

Имей под рукой:

- `optimization-aurora-wave2/CONTEXT_FOR_AGENTS.md`
- файл ТЗ из блока (например `optimization-aurora-wave2/tasks/TASK-011-slipper-engine-aggressive-wave2.md`)

Первая волна (TASK-001…010): каталог `optimization-aurora/`.

---

## Общий контекст (опционально, перед любой задачей волны 2)

```
Ты работаешь над второй волной оптимизации Honor of Aurora (Godot 4.4) для ОС Аврора.

Обязательно:
1) Прочитай optimization-aurora-wave2/CONTEXT_FOR_AGENTS.md
2) Все оптимизации волны 2 только в режиме «На тапке» (PerformancePreset.Mode.SLIPPER / PerformancePreset.is_slipper_mode(SaveManager))
3) Не оптимизируй портирование и экспорт — только код и поведение игры в honor-of-aurora/
4) Журнал: optimization-aurora-wave2/JOURNAL.md, реестр: optimization-aurora-wave2/TASKS_INDEX.md
```

---

## TASK-011 — движок SLIPPER: FPS, физика, Y-sort, clamp

```
Ты помогаешь с оптимизацией игры Honor of Aurora (Godot 4.4) для ОС Аврора на слабом железе.

Обязательно:
1) Прочитай optimization-aurora-wave2/CONTEXT_FOR_AGENTS.md
2) Выполни только задачу TASK-011 по ТЗ: optimization-aurora-wave2/tasks/TASK-011-slipper-engine-aggressive-wave2.md
3) Работай в каталоге honor-of-aurora/
4) По завершении добавь запись в optimization-aurora-wave2/JOURNAL.md (формат см. заголовок журнала) и обнови статус в optimization-aurora-wave2/TASKS_INDEX.md

Не выходи за рамки ТЗ TASK-011. Остальное — в журнал как рекомендация, без реализации без согласования.
```

---

## TASK-012 — троттлинг сохранений на диск в SLIPPER

```
Ты помогаешь с оптимизацией игры Honor of Aurora (Godot 4.4) для ОС Аврора на слабом железе.

Обязательно:
1) Прочитай optimization-aurora-wave2/CONTEXT_FOR_AGENTS.md
2) Выполни только задачу TASK-012 по ТЗ: optimization-aurora-wave2/tasks/TASK-012-slipper-save-disk-throttle.md
3) Работай в каталоге honor-of-aurora/
4) По завершении добавь запись в optimization-aurora-wave2/JOURNAL.md и обнови статус в optimization-aurora-wave2/TASKS_INDEX.md

Не выходи за рамки ТЗ TASK-012.
```

---

## TASK-013 — частичная активация сцены и декор

```
Ты помогаешь с оптимизацией игры Honor of Aurora (Godot 4.4) для ОС Аврора на слабом железе.

Обязательно:
1) Прочитай optimization-aurora-wave2/CONTEXT_FOR_AGENTS.md
2) Выполни только задачу TASK-013 по ТЗ: optimization-aurora-wave2/tasks/TASK-013-slipper-scene-partial-activation.md
3) Работай в каталоге honor-of-aurora/
4) По завершении добавь запись в optimization-aurora-wave2/JOURNAL.md и обнови статус в optimization-aurora-wave2/TASKS_INDEX.md

Не выходи за рамки ТЗ TASK-013.
```

---

## TASK-014 — реже `_process` и вспомогательные системы

```
Ты помогаешь с оптимизацией игры Honor of Aurora (Godot 4.4) для ОС Аврора на слабом железе.

Обязательно:
1) Прочитай optimization-aurora-wave2/CONTEXT_FOR_AGENTS.md
2) Выполни только задачу TASK-014 по ТЗ: optimization-aurora-wave2/tasks/TASK-014-slipper-process-systems-throttle.md
3) Работай в каталоге honor-of-aurora/
4) По завершении добавь запись в optimization-aurora-wave2/JOURNAL.md и обнови статус в optimization-aurora-wave2/TASKS_INDEX.md

Не выходи за рамки ТЗ TASK-014.
```

---

## TASK-015 — бюджет логики на дистанции (бой)

```
Ты помогаешь с оптимизацией игры Honor of Aurora (Godot 4.4) для ОС Аврора на слабом железе.

Обязательно:
1) Прочитай optimization-aurora-wave2/CONTEXT_FOR_AGENTS.md
2) Выполни только задачу TASK-015 по ТЗ: optimization-aurora-wave2/tasks/TASK-015-slipper-combat-distant-budget.md
3) Работай в каталоге honor-of-aurora/
4) По завершении добавь запись в optimization-aurora-wave2/JOURNAL.md и обнови статус в optimization-aurora-wave2/TASKS_INDEX.md

Не выходи за рамки ТЗ TASK-015.
```

---

## TASK-016 — HUD и всплывающий урон

```
Ты помогаешь с оптимизацией игры Honor of Aurora (Godot 4.4) для ОС Аврора на слабом железе.

Обязательно:
1) Прочитай optimization-aurora-wave2/CONTEXT_FOR_AGENTS.md
2) Выполни только задачу TASK-016 по ТЗ: optimization-aurora-wave2/tasks/TASK-016-slipper-hud-floating-combat-ui.md
3) Работай в каталоге honor-of-aurora/
4) По завершении добавь запись в optimization-aurora-wave2/JOURNAL.md и обнови статус в optimization-aurora-wave2/TASKS_INDEX.md

Не выходи за рамки ТЗ TASK-016.
```

---

## TASK-017 — визуальные эффекты в сценах (не импорт)

```
Ты помогаешь с оптимизацией игры Honor of Aurora (Godot 4.4) для ОС Аврора на слабом железе.

Обязательно:
1) Прочитай optimization-aurora-wave2/CONTEXT_FOR_AGENTS.md
2) Выполни только задачу TASK-017 по ТЗ: optimization-aurora-wave2/tasks/TASK-017-slipper-visual-effects-in-scenes.md
3) Работай в каталоге honor-of-aurora/
4) По завершении добавь запись в optimization-aurora-wave2/JOURNAL.md и обнови статус в optimization-aurora-wave2/TASKS_INDEX.md

Не выходи за рамки ТЗ TASK-017.
```

---

## TASK-018 — навигация и вспомогательные подсистемы

```
Ты помогаешь с оптимизацией игры Honor of Aurora (Godot 4.4) для ОС Аврора на слабом железе.

Обязательно:
1) Прочитай optimization-aurora-wave2/CONTEXT_FOR_AGENTS.md
2) Выполни только задачу TASK-018 по ТЗ: optimization-aurora-wave2/tasks/TASK-018-slipper-navigation-subsystems.md
3) Работай в каталоге honor-of-aurora/
4) По завершении добавь запись в optimization-aurora-wave2/JOURNAL.md и обнови статус в optimization-aurora-wave2/TASKS_INDEX.md

Не выходи за рамки ТЗ TASK-018.
```

---

## TASK-019 — приёмка волны 2 и синхронизация документов

```
Ты помогаешь с оптимизацией игры Honor of Aurora (Godot 4.4) для ОС Аврора на слабом железе.

Обязательно:
1) Прочитай optimization-aurora-wave2/CONTEXT_FOR_AGENTS.md
2) Выполни только задачу TASK-019 по ТЗ: optimization-aurora-wave2/tasks/TASK-019-wave2-acceptance-and-docs-sync.md
3) Работай в optimization-aurora-wave2/ и при необходимости в optimization-aurora/ (минимальные правки ссылок)
4) По завершении добавь запись в optimization-aurora-wave2/JOURNAL.md и обнови статус в optimization-aurora-wave2/TASKS_INDEX.md

Не выходи за рамки ТЗ TASK-019.
```
