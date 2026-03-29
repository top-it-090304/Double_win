<div align="center">

<img src="images/Logo/Logo.jpg" alt="Честь Архипелага Аврора" width="420"/>

# Честь Архипелага Аврора

### *Honor of Aurora*

**2D RPG на Godot** · острова · бой · база и сюжет

[![Godot](https://img.shields.io/badge/Godot-4.4-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org/)
[![GL Compatibility](https://img.shields.io/badge/renderer-GL%20Compatibility-5a6c7d)](https://docs.godotengine.org/en/stable/tutorials/rendering/rendering_method.html)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

</div>

---

## О проекте

**Честь Архипелага Аврора** — 2D‑игра на **Godot 4.4**: острова, бои от третьего лица сверху, база и сюжет. Сборка рассчитана в том числе на **ОС «Аврора»** и сенсор.

Код и сцены — в [`honor-of-aurora/`](honor-of-aurora/) (`project.godot`).

---

## Геймплей

- Ходите по локациям, бьётесь в реальном времени (**меч и щит**); на поле бывают **союзники**.
- **Диалоги** с NPC; сюжет идёт вперёд через сцену и текст.
- **База:** экран с разделами вроде найма, улучшений и каравана; на нём же **отношения с Короной** и учёт **ресурсов** (то, что видно в HUD).
- У союзника можно открыть **меню приказов** (через HUD).
- **Сохранения** и **сложность**; в настройках — картинка и управление (в т.ч. под сенсор); при необходимости на экране — **джойстик и кнопки** удара/щита.

Лор и зафиксированные правила мира — в [`CHANGELOG_LORE.md`](CHANGELOG_LORE.md).

---

## Галерея

*Демонстрация геймплея.*

<table>
<tr>
<td align="center" valign="top" width="33%">
<img src="screen_shots/1.jpg" alt="" width="100%"/><br/><sub>Меню игры.</sub>
</td>
<td align="center" valign="top" width="33%">
<img src="screen_shots/2.jpg" alt="" width="100%"/><br/><sub>Настройки.</sub>
</td>
<td align="center" valign="top" width="33%">
<img src="screen_shots/3.jpg" alt="" width="100%"/><br/><sub>Диалог.</sub>
</td>
</tr>
<tr>
<td align="center" valign="top">
<img src="screen_shots/4.jpg" alt="" width="100%"/><br/><sub>База.</sub>
</td>
<td align="center" valign="top">
<img src="screen_shots/5.jpg" alt="" width="100%"/><br/><sub>База.</sub>
</td>
<td align="center" valign="top">
<img src="screen_shots/6.jpg" alt="" width="100%"/><br/><sub>Найм.</sub>
</td>
</tr>
<tr>
<td align="center" valign="top" colspan="3">
<br/>
<img src="screen_shots/7.jpg" alt="" width="66%"/><br/><sub>Бой.</sub>
</td>
</tr>
</table>

---

## Технологии

| Компонент | Версия / детали |
|-----------|-----------------|
| Движок | **Godot 4.4** (`config/features`: `4.4`, **GL Compatibility**) |
| Язык | **GDScript** |
| Рендеринг | `gl_compatibility`, пиксельное привязывание 2D, при необходимости сжатие текстур под мобильные GPU |
| Аудио | OGG и др. (см. [`honor-of-aurora/audio/LICENSE_SOURCES.txt`](honor-of-aurora/audio/LICENSE_SOURCES.txt) при необходимости атрибуции) |
| Репозиторий | Git |

---

## Быстрый старт

1. Установите [**Godot 4.4**](https://godotengine.org/download) (или совместимую 4.x с тем же проектом).
2. Клонируйте репозиторий или скачайте архив.
3. В Godot: **Import** → укажите файл  
   `honor-of-aurora/project.godot`  
   либо откройте папку `honor-of-aurora` как проект.
4. Запустите сцену с **Main Scene**, заданной в проекте (меню **Project → Project Settings → Application → Run**).

> **Совет:** для целевой сборки под Аврору ориентируйтесь на экспорт с **GL Compatibility** и проверку ввода на сенсоре — в `project.godot` уже включена эмуляция мыши с касаний для стандартного UI.

---

## Структура репозитория (кратко)

```
Double_win/
├── honor-of-aurora/     # проект Godot (сцены, скрипты, ресурсы)
├── images/              # материалы вне движка, в т.ч. логотип для README
├── screen_shots/        # скриншоты для README и портфолио
├── story_icon_candidates/
├── CHANGELOG_LORE.md    # канон и нарративные решения
├── LICENSE              # MIT
└── README.md
```

---

## Лицензия

Проект распространяется по лицензии **MIT** — см. файл [`LICENSE`](LICENSE).

---

<div align="center">

*Остров за островом — приказ за приказом.*

</div>
