extends Node

enum LOCATION {BASE, LVL1, LVL2, LVL3, LVL4, LVL5, MENU}

## Последняя известная локация (для условий диалогов). Обновляется при смене сцены.
var current_location: LOCATION = LOCATION.BASE

signal location_changed(location: LOCATION)
signal gold_changed(gold: int)
