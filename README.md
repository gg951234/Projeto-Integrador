# Hero Maze 🎮📚
Um jogo 2D de labirinto (top-down), educativo, feito em Godot 4.6.
O jogador explora labirintos, derrota inimigos, coleta moedas e enfrenta um chefe em cada fase — enquanto aprende, na prática, conceitos de lógica e ciência da computação (teoria de grafos e condicionais).
É um projeto que une entretenimento + conteúdo escolar.

**🎯 Tema: 8 fases, 8 matérias**
Cada fase tem cenário e chefe temático ligado a uma disciplina:

Fase	Matéria	Chefe
1	Geografia	Golem
2	Física	ByBy
3	Matemática	Cartagon
4	História	Anubis
5	Biologia	Corona
6	Filosofia	Ares
7	Ed. Física	Kobe
8	Ed. Física	Risadinha


**🕹️ Como se joga (loop principal)**
O jogador anda pelo labirinto desviando das paredes.

Derrota todos os inimigos da fase (ataque corpo a corpo com espada) e coleta moedas.

Ao derrotar o último inimigo:

O portão do chefe se abre.

Surge uma linha de setas (grafo do menor caminho) apontando até a sala do chefe.

Seguir o caminho dourado (menor caminho) rende +5 moedas bônus.

Setas azuis mostram rotas alternativas mais longas.

Chegando na sala do chefe, vence o boss e desbloqueia a próxima fase.

📘 Diferencial educativo
Teoria de grafos (fases 1–4):  
O labirinto vira um grafo (células = vértices, corredores = arestas).
Um algoritmo A* encontra o menor caminho — explicado em popup e demonstrado pelas setas.

Condicionais (fases 5–8):  
Popups ensinam como os jogos "tomam decisões" (se/então), usando exemplos práticos do próprio jogo (paredes, combate, portão secreto).

Quiz e dados por matéria complementam o conteúdo.

⚙️ Sistemas e recursos
Contas de jogador (Firebase): cadastro/login por e-mail, login persistente e modo offline com sincronização automática.

Ranking online (Firestore): placar por fase com pontuação e tempo.

Economia + Loja: moedas coletadas compram e equipam skins do personagem.

Progressão salva localmente e na nuvem (mesclagem do melhor de cada).

Suporte mobile (Android/iOS): HUD adaptado.

# 📌 Em uma frase
Um labirinto educativo em 8 fases temáticas de matérias escolares, onde você luta, coleta e segue o "menor caminho" até o chefe — aprendendo grafos e lógica de programação enquanto joga, com ranking online, contas e loja de skins.


____________________________________________________

# Como instalar e rodar o jogo?

1. Instalar o Godot 4.6

Baixe em godotengine.org/download a versão Godot 4.6 – Standard (não precisa da versão .NET/C#, o jogo é todo em GDScript).
É um .exe portátil: não precisa instalar, só extrair e abrir.

2. Baixar o projeto do GitHub

Escolha uma das opções:

Opção A — com Git (recomendado):

git clone https://github.com/gg951234/Projeto-Integrador.git
Opção B — sem Git (ZIP):

Abra https://github.com/gg951234/Projeto-Integrador
Botão verde Code → Download ZIP
Extraia a pasta em algum lugar.

**3. Pegar as chaves com o grupo (Ou na documentação/txt)**

As chaves são necessárias para login, ranking e save na nuvem (o jogo em si roda sem elas, mas essas partes ficam offline).
Chave de API da Web (Web API Key) → vira FIREBASE_API_KEY
ID do projeto (Project ID) → vira FIREBASE_PROJECT_ID

**4. Criar o arquivo .env**

Na raiz do projeto (a pasta que tem o project.godot):

Copie o modelo .env.example para um novo arquivo chamado .env:
PowerShell: Copy-Item .env.example .env
Ou manualmente: duplique .env.example e renomeie para .env.
Abra o .env e preencha com as suas chaves:
FIREBASE_API_KEY=sua_chave_de_api_da_web
FIREBASE_PROJECT_ID=seu_id_do_projeto
Salve. (O .env é ignorado pelo Git de propósito — suas chaves nunca vão para o repositório.)

**5. Abrir e rodar no Godot**

Abra o Godot 4.6.
Clique em Import → navegue até a pasta do projeto → selecione o project.godot → Import & Edit.
Na primeira vez, o Godot reimporta os assets (aguarde alguns segundos).
Pressione F5 (▶️ Executar Projeto) — o jogo abre no menu principal.
Observações importantes
Sem as chaves / sem internet: o jogo (labirinto, fases, chefes) roda normal em modo offline; só login, ranking e sincronização na nuvem ficam indisponíveis até configurar o .env.
Regras do Firestore: para o ranking/save funcionarem, o Firestore precisa permitir leitura/escrita para usuários autenticados (coleções usuarios/{uid} e ranking_fase_XX). Se der erro de permissão, ajuste as Regras do Firestore.
Assets externos: a pasta assets/images/Cute_Fantasy_Free/ está no .gitignore (pack de arte licenciado). Se notar alguma textura faltando após o clone, é por isso — basta adicionar o pack nessa pasta.
