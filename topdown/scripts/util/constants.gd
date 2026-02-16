class_name Constants

## Tile and grid
const TILE_SIZE := 32

## Player
const PLAYER_SPEED := 200.0
const HACK_RANGE := 150.0  # Max distance to right-click hack an object

## Cooldown (seconds) — scales down as faith increases
const DEFAULT_COOLDOWN := 5.0
const MIN_COOLDOWN := 1.0

## Faith
const FAITH_PER_LEVEL := 20.0  # +20 % per completed level

## Commands
const CMD_UNLOCK := "unlock"
const CMD_DELETE := "delete"
const CMD_PING := "ping"
const CMD_STOP := "stop"
