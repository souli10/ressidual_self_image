class_name MinigameBase
extends Control

## Base class for all hacking minigames.
## Emitted when the player wins/loses. Terminal listens to these.

signal minigame_won
signal minigame_lost

## How hard this instance is (0.0 = easy, 1.0 = hardest).
## Set by the terminal based on GameManager.faith_percent.
var difficulty: float = 0.0


func start_minigame(diff: float) -> void:
	difficulty = diff
	visible = true
	_begin()


## Override in subclasses to kick off gameplay.
func _begin() -> void:
	pass
