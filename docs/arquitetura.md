# Arquitetura - Heroi Maze

## Autoloads
- GameManager: estado global
- SaveManager: save em user://save.json
- AudioManager: musica e SFX
- SettingsManager: volume, brilho, idioma

## Decisoes tecnicas
- Save local via JSON em user://
- SQLite via plugin para ranking local
- Resolucao base: 480x270 stretch canvas_items
