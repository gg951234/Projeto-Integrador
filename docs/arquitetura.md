# 🏗️ Arquitetura do Projeto — Herói Maze
> Projeto Integrador 1 | UTFPR Campus Santa Helena | BCC 2026/01
> Engine: Godot 4.6.2 | GDScript | Renderer: Compatibility

---

## 📐 Padrão Arquitetural

O projeto adota uma arquitetura híbrida com 4 padrões complementares:

| Padrão | Onde se aplica |
|---|---|
| **Manager Pattern (Autoload/Singleton)** | Sistemas globais: GameManager, SaveManager, AudioManager, SettingsManager, UserManager, EconomyManager, RankingManager |
| **Scene-Based MVC** | Cada tela é uma cena independente com seu controller. Managers = Model, Cenas/UI = View |
| **Data-Driven** | Fases e perguntas educativas carregadas de JSONs externos (`data/levels/`, `data/questions/`) |
| **Component-Based** | Player e Enemy são `CharacterBody2D` com scripts separados. Blocos usam herança de `BlockCommand` |

---

## 🗂️ Estrutura de Pastas

```
res://
├── scenes/
│   ├── main/
│   │   └── Main.tscn                  # Cena raiz do jogo, ponto de entrada
│   ├── screens/
│   │   ├── StartScreen.tscn           # Tela inicial com botão Start
│   │   ├── LoginScreen.tscn           # Login do jogador (nome + senha)
│   │   ├── RegisterScreen.tscn        # Cadastro de novo jogador
│   │   ├── PhaseSelectScreen.tscn     # Seleção de fases desbloqueadas
│   │   ├── ShopScreen.tscn            # Loja de skins, temas e poderes
│   │   ├── SettingsScreen.tscn        # Configurações: som, brilho, idioma
│   │   ├── RankingScreen.tscn         # Ranking top 10 entre jogadores
│   │   └── ResultScreen.tscn          # Resultado ao fim de uma fase
│   ├── levels/
│   │   ├── Level01_Geografia.tscn     # Fase 1 — Geografia: Vegetação
│   │   ├── Level02_Fisica.tscn        # Fase 2 — Física: Fenômenos Ópticos
│   │   ├── Level03_Matematica.tscn    # Fase 3 — Matemática: Operações Básicas
│   │   ├── Level04_Historia.tscn      # Fase 4 — História: Egito Antigo
│   │   ├── Level05_Biologia.tscn      # Fase 5 — Biologia: Genética
│   │   ├── Level06_Filosofia.tscn     # Fase 6 — Filosofia: Deuses Gregos
│   │   ├── Level07_EducacaoFisica.tscn# Fase 7 — Educação Física: Basquete
│   │   ├── Level08_Artes.tscn         # Fase 8 — Artes: Pintura
│   │   ├── Level09_Quimica.tscn       # Fase 9 — Química: Fusão e Fissão
│   │   └── Level10_Portugues.tscn     # Fase 10 — Português: Literatura
│   ├── player/
│   │   └── Player.tscn                # Personagem principal com AnimatedSprite2D
│   ├── enemies/
│   │   └── Enemy.tscn                 # Inimigo base (pode ser herdado)
│   ├── objects/
│   │   ├── Coin.tscn                  # Moeda coletável do cenário
│   │   ├── Portal.tscn                # Portal de saída da fase
│   │   ├── Door.tscn                  # Porta bloqueada (abre com desafio)
│   │   └── Collectible.tscn           # Item coletável genérico
│   └── blocks/
│       ├── BlockCommand.tscn          # Bloco base de programação
│       ├── BlockMove.tscn             # Bloco: mover personagem
│       ├── BlockTurn.tscn             # Bloco: girar direção
│       └── BlockRepeat.tscn           # Bloco: repetir comandos
│
├── scripts/
│   ├── autoload/                      # Singletons — carregados automaticamente pelo Godot
│   │   ├── GameManager.gd             # [✅ CRIADO] Estado global: fase atual, moedas, progresso
│   │   ├── SaveManager.gd             # [✅ CRIADO] Leitura e escrita de user://save.json
│   │   ├── AudioManager.gd            # [✅ CRIADO] Controle de música e SFX
│   │   ├── SettingsManager.gd         # [✅ CRIADO] Volume, brilho, idioma — persiste em settings.json
│   │   ├── UserManager.gd             # [🔲 CRIAR] Registro, login e logout de jogadores
│   │   ├── EconomyManager.gd          # [🔲 CRIAR] Ganho e gasto de moedas internas
│   │   └── RankingManager.gd          # [🔲 CRIAR] Ranking via SQLite GDExtension
│   ├── player/
│   │   └── PlayerController.gd        # [✅ CRIADO] Movimentação 4 direções + move_and_slide()
│   ├── enemies/
│   │   └── EnemyController.gd         # [✅ CRIADO] Patrulha simples, inverte em is_on_wall()
│   ├── levels/
│   │   ├── LevelManager.gd            # [✅ CRIADO] Array com paths das 10 fases, carregar_fase()
│   │   ├── TimerManager.gd            # [✅ CRIADO] Timer de 5 min, sinal tempo_esgotado
│   │   └── CollisionHandler.gd        # [🔲 CRIAR] Lógica central de colisões do nível
│   ├── education/
│   │   ├── ChallengeManager.gd        # [✅ CRIADO] Carrega JSON da matéria, valida respostas
│   │   ├── Question.gd                # [🔲 CRIAR] Modelo de dados de uma pergunta
│   │   └── AnswerValidator.gd         # [🔲 CRIAR] Valida resposta do jogador
│   ├── blocks/
│   │   ├── BlockCommand.gd            # [✅ CRIADO] Classe base com enum TipoComando
│   │   ├── BlockProgrammingManager.gd # [🔲 CRIAR] Gerencia fila de blocos e execução
│   │   └── CommandInterpreter.gd      # [🔲 CRIAR] Interpreta e executa sequência de blocos
│   └── ui/
│       ├── MenuController.gd          # [🔲 CRIAR] Lógica do menu principal e navegação
│       ├── ShopController.gd          # [🔲 CRIAR] Listagem, compra e aplicação de itens
│       ├── SettingsController.gd      # [🔲 CRIAR] Lógica da tela de configurações
│       └── RankingController.gd       # [🔲 CRIAR] Busca e exibe top 10 do SQLite
│
├── assets/
│   ├── sprites/
│   │   ├── player/                    # Spritesheet do personagem (idle, walk, hit)
│   │   ├── enemies/                   # Sprites dos inimigos
│   │   ├── objects/                   # Sprites de moedas, portais, portas
│   │   ├── items/                     # Skins e itens da loja
│   │   └── tilesets/                  # Tilesets de cada fase (10 temas)
│   ├── audio/
│   │   ├── music/                     # Trilhas: menu, fase_01..fase_10, resultado
│   │   └── sfx/                       # Sons: passo, moeda, acerto, erro, portal, dano
│   ├── fonts/                         # Fontes pixel art utilizadas na UI
│   └── ui/
│       ├── buttons/                   # Sprites de botões (normal, hover, pressed)
│       ├── icons/                     # Ícones: moeda, vida, tempo, config, ranking
│       └── backgrounds/               # Backgrounds de cada tela
│
├── data/
│   ├── levels/
│   │   ├── level_01.json              # Metadados da Fase 1 (matéria, tema, dificuldade)
│   │   ├── level_02.json              # Metadados da Fase 2
│   │   ├── ...                        # (repetir até level_10.json)
│   │   └── level_10.json              # Metadados da Fase 10
│   ├── questions/
│   │   ├── geografia.json             # [✅ COM CONTEÚDO] Perguntas de Geografia
│   │   ├── fisica.json                # [✅ COM CONTEÚDO] Perguntas de Física
│   │   ├── matematica.json            # [✅ COM CONTEÚDO] Perguntas de Matemática
│   │   ├── historia.json              # [🔲 PLACEHOLDER] Perguntas de História
│   │   ├── biologia.json              # [🔲 PLACEHOLDER] Perguntas de Biologia
│   │   ├── filosofia.json             # [🔲 PLACEHOLDER] Perguntas de Filosofia
│   │   ├── educacao_fisica.json       # [🔲 PLACEHOLDER] Perguntas de Educação Física
│   │   ├── artes.json                 # [🔲 PLACEHOLDER] Perguntas de Artes
│   │   ├── quimica.json               # [🔲 PLACEHOLDER] Perguntas de Química
│   │   └── portugues.json             # [🔲 PLACEHOLDER] Perguntas de Português
│   ├── shop_items.json                # Catálogo de itens da loja (nome, preço, tipo)
│   └── settings_default.json          # Configurações padrão (volume, brilho, idioma)
│
└── docs/
    └── arquitetura.md                 # Este arquivo — visão geral da arquitetura
```

---

## ⚙️ Autoloads registrados no Godot

Configure em **Project → Project Settings → Autoload**:

| Nome | Caminho | Descrição |
|---|---|---|
| GameManager | `res://scripts/autoload/GameManager.gd` | Estado global do jogo |
| SaveManager | `res://scripts/autoload/SaveManager.gd` | Persistência local JSON |
| AudioManager | `res://scripts/autoload/AudioManager.gd` | Música e efeitos sonoros |
| SettingsManager | `res://scripts/autoload/SettingsManager.gd` | Configurações do usuário |
| UserManager | `res://scripts/autoload/UserManager.gd` | Autenticação de jogadores |
| EconomyManager | `res://scripts/autoload/EconomyManager.gd` | Sistema de moedas |
| RankingManager | `res://scripts/autoload/RankingManager.gd` | Ranking via SQLite |

---

## 🎮 Input Map

Configure em **Project → Project Settings → Input Map**:

| Ação | Tecla Principal | Tecla Alternativa |
|---|---|---|
| mover_cima | `W` | Seta ↑ |
| mover_baixo | `S` | Seta ↓ |
| mover_esquerda | `A` | Seta ← |
| mover_direita | `D` | Seta → |
| interagir | `E` | — |
| pausar | `Esc` | — |

> No mobile, as ações serão mapeadas para um joystick virtual na tela.

---

## 💾 Persistência de Dados

| Dado | Arquivo | Formato |
|---|---|---|
| Progresso do jogador | `user://save.json` | JSON |
| Configurações | `user://settings.json` | JSON |
| Ranking | `user://ranking.db` | SQLite (GDExtension) |

---

## 🔗 Convenções de Nomenclatura

| Tipo | Convenção | Exemplo |
|---|---|---|
| Cenas | PascalCase + `.tscn` | `PlayerController.tscn` |
| Scripts | PascalCase + `.gd` | `GameManager.gd` |
| Funções | snake_case | `carregar_fase()` |
| Variáveis | snake_case | `fase_atual` |
| Constantes | UPPER_SNAKE | `VELOCIDADE = 100.0` |
| Arquivos JSON | snake_case | `shop_items.json` |
| Assets/Sprites | snake_case | `player_idle.png` |

---

## 📋 Legenda de Status

| Ícone | Significado |
|---|---|
| ✅ CRIADO | Script/cena já implementado |
| 🔲 CRIAR | Pendente de implementação |
| 🔲 PLACEHOLDER | JSON existe mas sem conteúdo real |
