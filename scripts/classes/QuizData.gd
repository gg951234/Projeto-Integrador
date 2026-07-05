extends Node

var questions = {
	"Level1": [
		{
			"question": "Qual bioma brasileiro é conhecido pela grande biodiversidade e pela Floresta Amazônica?",
			"options": [
				"Caatinga",
				"Cerrado",
				"Amazônia",
				"Pantanal"
			],
			"correct": "Amazônia"
		},
		{
			"question": "Qual bioma brasileiro apresenta clima semiárido e vegetação adaptada à seca?",
			"options": [
				"Mata Atlântica",
				"Caatinga",
				"Pampa",
				"Cerrado"
			],
			"correct": "Caatinga"
		},
		{
			"question": "O Pantanal é famoso por qual característica?",
			"options": [
				"Deserto",
				"Inundações periódicas",
				"Montanhas altas",
				"Clima polar"
			],
			"correct": "Inundações periódicas"
		},
		{
			"question": "Qual bioma brasileiro é mais devastado pela urbanização e agricultura?",
			"options": [
				"Mata Atlântica",
				"Cerrado",
				"Pampa",
				"Caatinga"
			],
			"correct": "Mata Atlântica"
		},
		{
			"question": "O Cerrado é conhecido por qual tipo de vegetação?",
			"options": [
				"Floresta densa",
				"Campos com árvores retorcidas",
				"Manguezais",
				"Vegetação rasteira"
			],
			"correct": "Campos com árvores retorcidas"
		},
		{
			"question": "Qual ação humana mais ameaça os biomas brasileiros?",
			"options": [
				"Preservação ambiental",
				"Desmatamento",
				"Reflorestamento",
				"Educação ambiental"
			],
			"correct": "Desmatamento"
		}
	],
	"Level2": [
		{
			"question": "Qual combustível é derivado do petróleo?",
			"options": [
				"Etanol",
				"Carvão",
				"Gasolina",
				"Madeira"
			],
			"correct": "Gasolina"
		},
		{
			"question": "Qual máquina usa vapor para funcionar?",
			"options": [
				"Motor elétrico",
				"Motor a combustão",
				"Máquina a vapor",
				"Turbina eólica"
			],
			"correct": "Máquina a vapor"
		},
		{
			"question": "O etanol no Brasil é produzido principalmente a partir de qual planta?",
			"options": [
				"Milho",
				"Soja",
				"Cana-de-açúcar",
				"Trigo"
			],
			"correct": "Cana-de-açúcar"
		},
		{
			"question": "Qual impacto ambiental está associado ao uso de combustíveis fósseis?",
			"options": [
				"Aquecimento global",
				"Aumento da biodiversidade",
				"Reflorestamento",
				"Purificação da água"
			],
			"correct": "Aquecimento global"
		},
		{
			"question": "Qual destes é um combustível renovável?",
			"options": [
				"Carvão mineral",
				"Etanol",
				"Petróleo",
				"Gás natural"
			],
			"correct": "Etanol"
		},
		{
			"question": "Qual máquina revolucionou o transporte no século XIX?",
			"options": [
				"Carro elétrico",
				"Locomotiva a vapor",
				"Avião",
				"Navio a vela"
			],
			"correct": "Locomotiva a vapor"
		}
	],
	"Level3": [
		{
			"question": "Qual é o valor de x em 2x + 3 = 7?",
			"options": [
				"1",
				"2",
				"3",
				"4"
			],
			"correct": "2"
		},
		{
			"question": "No plano cartesiano, o ponto (0,0) é chamado de:",
			"options": [
				"Origem",
				"Eixo X",
				"Eixo Y",
				"Centro da reta"
			],
			"correct": "Origem"
		},
		{
			"question": "Qual é a incógnita na equação 5x = 20?",
			"options": [
				"5",
				"20",
				"x",
				"Nenhuma"
			],
			"correct": "x"
		},
		{
			"question": "Se uma sequência é 2, 4, 6, 8, qual é o próximo número?",
			"options": [
				"9",
				"10",
				"11",
				"12"
			],
			"correct": "10"
		},
		{
			"question": "Qual é a solução de x - 5 = 12?",
			"options": [
				"7",
				"12",
				"17",
				"20"
			],
			"correct": "17"
		},
		{
			"question": "Se y é diretamente proporcional a x, o que acontece quando x aumenta?",
			"options": [
				"y diminui",
				"y aumenta",
				"y não muda",
				"y vira zero"
			],
			"correct": "y aumenta"
		}
	],
	"Level4": [
		{
			"question": "Qual rio foi essencial para o Egito Antigo?",
			"options": [
				"Tigre",
				"Eufrates",
				"Nilo",
				"Amazonas"
			],
			"correct": "Nilo"
		},
		{
			"question": "Quem eram os governantes do Egito Antigo?",
			"options": [
				"Imperadores",
				"Reis",
				"Faraós",
				"Presidentes"
			],
			"correct": "Faraós"
		},
		{
			"question": "As pirâmides do Egito eram usadas principalmente como:",
			"options": [
				"Templos",
				"Túmulos",
				"Casas",
				"Escolas"
			],
			"correct": "Túmulos"
		},
		{
			"question": "Qual era a escrita usada pelos egípcios?",
			"options": [
				"Cuneiforme",
				"Hieróglifos",
				"Latim",
				"Grego"
			],
			"correct": "Hieróglifos"
		},
		{
			"question": "Qual prática estava ligada à preservação dos corpos no Egito?",
			"options": [
				"Mumificação",
				"Incinerar",
				"Congelar",
				"Enterrar"
			],
			"correct": "Mumificação"
		},
		{
			"question": "Qual deus egípcio era associado ao sol?",
			"options": [
				"Rá",
				"Osíris",
				"Anúbis",
				"Ísis"
			],
			"correct": "Rá"
		}
	],
	"Level5": [
		{
			"question": "Qual é a menor unidade da vida?",
			"options": [
				"Átomo",
				"Molécula",
				"Célula",
				"Tecido"
			],
			"correct": "Célula"
		},
		{
			"question": "Qual organela é responsável pela produção de energia na célula?",
			"options": [
				"Núcleo",
				"Mitocôndria",
				"Ribossomo",
				"Lisossomo"
			],
			"correct": "Mitocôndria"
		},
		{
			"question": "Qual molécula carrega as informações genéticas?",
			"options": [
				"Proteína",
				"DNA",
				"Lipídio",
				"RNA"
			],
			"correct": "DNA"
		},
		{
			"question": "Qual organela controla as atividades da célula?",
			"options": [
				"Núcleo",
				"Mitocôndria",
				"Citoplasma",
				"Membrana"
			],
			"correct": "Núcleo"
		},
		{
			"question": "Células procariontes não possuem:",
			"options": [
				"Núcleo definido",
				"Membrana plasmática",
				"DNA",
				"Citoplasma"
			],
			"correct": "Núcleo definido"
		},
		{
			"question": "Qual organela é responsável pela síntese de proteínas?",
			"options": [
				"Mitocôndria",
				"Ribossomo",
				"Lisossomo",
				"Vacúolo"
			],
			"correct": "Ribossomo"
		}
	],
	"Level6": [
		{
			"question": "Qual deus grego era considerado o rei dos deuses?",
			"options": [
				"Zeus",
				"Poseidon",
				"Apolo",
				"Hermes"
			],
			"correct": "Zeus"
		},
		{
			"question": "Qual era o principal templo dedicado a Atena em Atenas?",
			"options": [
				"Coliseu",
				"Partenon",
				"Panteão",
				"Ágora"
			],
			"correct": "Partenon"
		},
		{
			"question": "Qual filósofo grego foi mestre de Alexandre, o Grande?",
			"options": [
				"Sócrates",
				"Platão",
				"Aristóteles",
				"Epicuro"
			],
			"correct": "Aristóteles"
		},
		{
			"question": "Qual era o deus grego do submundo?",
			"options": [
				"Zeus",
				"Hades",
				"Ares",
				"Apolo"
			],
			"correct": "Hades"
		},
		{
			"question": "Qual cidade grega era famosa por seus guerreiros?",
			"options": [
				"Esparta",
				"Atenas",
				"Roma",
				"Delos"
			],
			"correct": "Esparta"
		},
		{
			"question": "Qual poeta grego escreveu a Ilíada e a Odisseia?",
			"options": [
				"Homero",
				"Virgílio",
				"Platão",
				"Sófocles"
			],
			"correct": "Homero"
		}
	],
	"Level7": [
		{
			"question": "Quantos jogadores cada equipe tem em quadra no basquete?",
			"options": [
				"4",
				"5",
				"6",
				"7"
			],
			"correct": "5"
		},
		{
			"question": "Qual é o objetivo principal do jogo de basquete?",
			"options": [
				"Fazer gols",
				"Marcar pontos com cestas",
				"Defender o campo",
				"Correr mais rápido"
			],
			"correct": "Marcar pontos com cestas"
		},
		{
			"question": "Qual é o nome do movimento de quicar a bola enquanto se desloca?",
			"options": [
				"Passe",
				"Arremesso",
				"Drible",
				"Bloqueio"
			],
			"correct": "Drible"
		},
		{
			"question": "Qual é a altura oficial da cesta de basquete?",
			"options": [
				"2,50 m",
				"3,05 m",
				"3,50 m",
				"4,00 m"
			],
			"correct": "3,05 m"
		},
		{
			"question": "Qual é o nome do passe feito com as duas mãos no peito?",
			"options": [
				"Passe picado",
				"Passe de peito",
				"Passe por cima",
				"Passe lateral"
			],
			"correct": "Passe de peito"
		},
		{
			"question": "Qual é a linha que delimita a área de três pontos?",
			"options": [
				"Linha de fundo",
				"Linha lateral",
				"Linha de três pontos",
				"Linha de lance livre"
			],
			"correct": "Linha de três pontos"
		}
	],
	"Level8": [
		{
			"question": "Qual elemento dos quadrinhos mostra o que os personagens falam?",
			"options": [
				"Balões de fala",
				"Onomatopeias",
				"Quadros",
				"Cenário"
			],
			"correct": "Balões de fala"
		},
		{
			"question": "Qual palavra imita sons em HQs, como 'BUM' ou 'POW'?",
			"options": [
				"Legenda",
				"Onomatopeia",
				"Balão",
				"Narrativa"
			],
			"correct": "Onomatopeia"
		},
		{
			"question": "Qual é a sequência que organiza a história em quadrinhos?",
			"options": [
				"Cenas soltas",
				"Quadros em ordem",
				"Balões",
				"Personagens"
			],
			"correct": "Quadros em ordem"
		},
		{
			"question": "Qual é o nome do espaço onde a história acontece?",
			"options": [
				"Cenário",
				"Balão",
				"Quadro",
				"Narrador"
			],
			"correct": "Cenário"
		},
		{
			"question": "Qual tipo de balão mostra o pensamento do personagem?",
			"options": [
				"Balão de fala",
				"Balão de pensamento",
				"Balão de grito",
				"Balão narrativo"
			],
			"correct": "Balão de pensamento"
		},
		{
			"question": "Qual é a principal função das HQs?",
			"options": [
				"Ensinar matemática",
				"Comunicar por imagens e textos",
				"Mostrar apenas desenhos",
				"Substituir livros"
			],
			"correct": "Comunicar por imagens e textos"
		}
]
}
