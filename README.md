<div align="center">

<img src="images/Logo/Logo.png" alt="Честь Авроры" width="420"/>

# Честь Авроры

### *Honor of Aurora*

**2D RPG на Godot** · острова · бой · база · моральный выбор · плотный лор

[![Godot](https://img.shields.io/badge/Godot-4.4-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org/)
[![GL Compatibility](https://img.shields.io/badge/renderer-GL%20Compatibility-5a6c7d)](https://docs.godotengine.org/en/stable/tutorials/rendering/rendering_method.html)
[![Android APK](https://img.shields.io/badge/Android-APK-3ddc84?logo=android&logoColor=white)](#быстрый-старт)
[![Aurora OS](https://img.shields.io/badge/Aurora%20OS-RPM-0078d7)](#быстрый-старт)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

</div>

---

## О проекте

**Честь Архипелага Аврора** — сюжетная 2D RPG на **Godot 4.4** про экспедицию на острова, где приказ Короны постепенно превращается в личный моральный выбор.

В игре есть бои в реальном времени, база с развитием, караваны, ресурсы, спутники, письма, сюжетные предметы и диалоги. Отдельный акцент — лор: мир не подаётся одной справкой, а собирается через реплики, записки, хронологию, предметы, реакцию NPC и последствия решений.

Готовые сборки лежат в корне репозитория:

- `Honor of Aurora.apk` — Android.
- `ru.marsel.honorofaurora-1.0.0-1.armv7hl.rpm` — ОС «Аврора».

Исходники Godot-проекта находятся в [`honor-of-aurora/`](honor-of-aurora/) (`project.godot`).

---

## Быстрый старт

### Android

1. Скачайте файл `Honor of Aurora.apk`.
2. Перенесите APK на Android-устройство.
3. Разрешите установку из выбранного источника, если система попросит.
4. Установите и запустите игру.

### ОС «Аврора»

1. Скачайте файл `ru.marsel.honorofaurora-1.0.0-1.armv7hl.rpm`.
2. Установите RPM штатным способом для устройства/SDK ОС «Аврора».
3. Запустите приложение после установки.

### Запуск из исходников

Движок нужен только для разработки или самостоятельной сборки.

1. Установите [Godot 4.4](https://godotengine.org/download).
2. Откройте `honor-of-aurora/project.godot`.
3. Запустите главную сцену проекта.

---

## Геймплей

- Исследование островов с видом сверху.
- Бой в реальном времени: меч, щит, позиционирование, враги разного уровня.
- Союзники в отряде: лучники, копейщики, рабочие и сюжетные спутники.
- База экспедиции: найм, улучшения зданий, церковь, стрельбище, казармы, шахта и караван Короны.
- Экономика ресурсов: золото, мясо, дерево и Сердцевина.
- Система Короны: приказы, сроки, титулы, немилость и одобрение.
- Сложности: лёгкая, нормальная и сложная, с разным давлением на бой, отдых, экономику и приказы.
- Сенсорное управление: экранный джойстик, кнопки атаки, щита, привала и приказов отряду.

---

## Лор и сюжет

Лор — одна из центральных частей игры, а не декоративная справка.

В основе истории:

- Корона отправляет рыцаря на Аврору за Сердцевиной, потому что материковые маяки гаснут.
- Орден Тихой Зари связан старым контрактом и скрывает правду о стражах.
- Стражи островов оказываются не просто врагами, а живыми печатями.
- Под архипелагом спит Заря — древняя сила, о последствиях пробуждения которой спорят даже старые тексты.
- Сердцевина под базой — лишь верхняя жила, пригодная для лагеря и малых отгрузок; глубокие жилы закрыты стражами.

Текстовая часть включает:

- основные сюжетные диалоги;
- личные линии целителя, Мирона и Брана;
- письма с материка;
- записки из сундуков;
- предметы кодекса;
- хронологию событий;
- внутримировые объяснения механик: караван, титулы, немилость, Сердцевина.

Канон и история нарративных решений зафиксированы в [`CHANGELOG_LORE.md`](CHANGELOG_LORE.md).

---

## Галерея

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
<img src="screen_shots/5.jpg" alt="" width="100%"/><br/><sub>Караван и развитие.</sub>
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
| Рендеринг | `gl_compatibility`, 2D pixel snap, мобильные настройки качества |
| Платформы | Android APK, ОС «Аврора» RPM, запуск из Godot |
| Аудио | OGG и WAV; атрибуция источников в [`honor-of-aurora/audio/LICENSE_SOURCES.txt`](honor-of-aurora/audio/LICENSE_SOURCES.txt) |
| Лицензия | MIT |

---

## Структура репозитория

```text
Double_win/
├── honor-of-aurora/                         # Godot-проект: сцены, скрипты, ресурсы
├── images/                                  # материалы для README и презентаций
├── screen_shots/                            # скриншоты игры
├── CHANGELOG_LORE.md                        # канон и нарративные решения
├── Honor of Aurora.apk                      # Android-сборка
├── ru.marsel.honorofaurora-1.0.0-1.armv7hl.rpm  # сборка для ОС «Аврора»
├── LICENSE
└── README.md
```

---

## Лицензия

Проект распространяется по лицензии **MIT** — см. [`LICENSE`](LICENSE).

---

<div align="center">

*Остров за островом — приказ за приказом.*

</div>
