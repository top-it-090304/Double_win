extends Node

enum LOCATION {BASE, LVL1, LVL2, LVL3, LVL4, LVL5, MENU}

signal location_changed(location: LOCATION)
signal gold_changed(gold: int)
