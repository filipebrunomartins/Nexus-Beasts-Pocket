# GUIA COMPLETO: Criando seu próprio TCG no estilo Pokémon TCG Pocket

## Projeto de exemplo: **NEXUS BEASTS Pocket**

Este documento tem dois objetivos:

1. **Documentar todas as regras e mecânicas do Pokémon TCG Pocket** (o jogo de referência), para que você entenda exatamente como ele funciona.
2. **Fornecer um passo a passo completo de criação de um novo jogo** com as mesmas regras, mas com um universo, tipos e monstros 100% originais — incluindo um jogo de exemplo pronto ("Nexus Beasts Pocket") com 50+ monstros originais (mínimo 5 de cada um dos 10 tipos) e um conjunto completo de cartas de suporte.

> **Nota legal importante:** mecânicas e regras de jogo não são protegidas por direitos autorais, mas nomes, personagens, artes, textos de cartas e a marca "Pokémon" são propriedade da The Pokémon Company/Nintendo. Para criar um jogo próprio com segurança, você deve criar **nomes, criaturas, artes e textos totalmente originais** — que é exatamente o que este guia faz.

---

# PARTE 1 — COMO FUNCIONA O POKÉMON TCG POCKET (JOGO DE REFERÊNCIA)

Esta seção resume as mecânicas reais do jogo, verificadas em fontes atualizadas, para servir de base fiel ao seu clone.

## 1.1 Estrutura geral

| Elemento | Regra no TCG Pocket |
|---|---|
| Tamanho do baralho | **20 cartas** (apenas Monstros e Treinadores; **não existem cartas de Energia**) |
| Cópias por carta | Máximo **2 cartas com o mesmo nome** por baralho |
| Mão inicial | **5 cartas** (o jogo garante ao menos 1 monstro Básico na mão inicial) |
| Limite de mão | **10 cartas** (com 10+ cartas, você não compra no início do turno) |
| Banco | Até **3 monstros** no Banco (+1 Ativo = máx. 4 em jogo) |
| Condição de vitória | Marcar **3 pontos**: nocaute de monstro comum = **1 ponto**; nocaute de monstro **EX** = **2 pontos**. Também vence quem deixa o oponente sem monstros em jogo. |
| Fim do baralho | Ficar sem cartas para comprar **não** causa derrota — o jogo continua |
| Limite de tempo | ~20 minutos por jogador; empate no turno 30 se ninguém venceu |

## 1.2 A Zona de Energia (a grande inovação do Pocket)

- Não há cartas de Energia no baralho. Em vez disso, cada jogador tem uma **Zona de Energia** que **gera 1 Energia automaticamente por turno**.
- O jogador pode ver qual será a **próxima** Energia gerada (planejamento).
- Se o baralho estiver configurado com **mais de um tipo** de Energia, o tipo gerado a cada turno é **aleatório** entre os tipos escolhidos.
- **A Energia anexada não é gasta ao atacar** — uma vez carregado, o monstro pode repetir o ataque todo turno. Energia só é descartada ao **recuar** (paga o custo de recuo) ou por efeitos de cartas.
- **O jogador que começa não recebe Energia no seu primeiro turno** (compensação por jogar primeiro).
- Efeitos de aceleração de Energia (habilidades, ataques, apoiadores) pegam Energia extra **da Zona de Energia**, não da mão.

## 1.3 Preparação da partida

1. Cada jogador embaralha seu baralho de 20 cartas e compra **5 cartas**.
2. Cara ou coroa decide quem começa.
3. Cada jogador coloca **1 monstro Básico** virado para baixo como **Ativo** e até **3 Básicos** no **Banco**.
4. As cartas são reveladas e a partida começa.

## 1.4 Estrutura do turno

Em ordem (as ações 2–6 são livres, exceto onde indicado):

1. **Comprar** 1 carta (obrigatório; pulado se a mão tiver 10 cartas).
2. **Ações livres**, em qualquer ordem e quantidade permitida:
   - Colocar monstros **Básicos** no Banco (quantos couberem);
   - **Evoluir** monstros (1 evolução por monstro por turno; não pode evoluir um monstro que entrou em jogo neste turno, nem no 1º turno de cada jogador);
   - Anexar a **Energia** da Zona de Energia a **1 monstro** (Ativo ou do Banco) — só **1 por turno**;
   - Jogar **1 carta de Apoiador** por turno;
   - Jogar **quantas cartas de Item** quiser;
   - Anexar **Ferramentas** (1 por monstro, sem limite por turno);
   - Usar **Habilidades** dos monstros (conforme o texto de cada uma);
   - **Recuar** o Ativo (1 vez por turno): descarta Energia igual ao custo de recuo e troca por um monstro do Banco.
3. **Atacar** com o monstro Ativo (opcional; **encerra o turno**). O jogador que começa **não pode receber Energia** no 1º turno, mas pode atacar se tiver um ataque de custo zero ou suprido por habilidade.

## 1.5 Combate e dano

- O ataque exige que o monstro tenha **Energia anexada igual ou superior ao custo** impresso. Custos **Incolores (⭐)** podem ser pagos com qualquer tipo.
- **Fraqueza:** se o atacante for do tipo da fraqueza do defensor, o ataque com dano causa **+20 de dano**. **Não existe Resistência** no Pocket.
- Dano é registrado no monstro; se o dano acumulado ≥ PS, o monstro é **nocauteado**: vai para o descarte com tudo que estava anexado, e o oponente marca 1 ponto (2 se for EX).
- Ao perder o Ativo, o jogador **promove** um monstro do Banco. Se não tiver nenhum, perde a partida.
- Monstros no Banco **não** sofrem Fraqueza (efeitos que atingem o Banco causam o dano indicado, sem modificadores).

## 1.6 Condições Especiais (status)

Aplicáveis apenas ao monstro **Ativo**. São curadas quando o monstro **vai para o Banco**, **evolui** ou por **efeito de carta**.

| Condição | Efeito |
|---|---|
| **Envenenado** | Sofre **10 de dano** entre os turnos (checkup). Persiste até ser curado. |
| **Queimado** | Sofre **20 de dano** entre os turnos; depois joga uma moeda — **cara** cura a queimadura. |
| **Adormecido** | Não pode atacar nem recuar. Entre os turnos, joga moeda — **cara** acorda. |
| **Paralisado** | Não pode atacar nem recuar durante o próximo turno do dono; cura automática ao final dele. |
| **Confuso** | Ao declarar ataque, joga moeda — **coroa** = o ataque falha. |

Envenenado/Queimado podem coexistir com Adormecido/Paralisado/Confuso (estes três se substituem entre si).

## 1.7 Tipos de carta

### Monstros
- **Básico** — entra direto em jogo.
- **Estágio 1 / Estágio 2** — evoluem a partir do estágio anterior.
- **EX** — versões mais fortes (Básicas ou evoluídas). **Regra EX:** ao ser nocauteado, concede **2 pontos** ao oponente. Um EX evoluído não evolui para a versão comum seguinte, e vice-versa. Como o nome do EX é diferente ("Nome ex"), você pode ter 2 cópias da versão comum **e** 2 da versão EX no mesmo baralho.

### Treinadores
- **Apoiador** — efeito forte; **1 por turno**; vai para o descarte após o uso. (Diferente do TCG físico, pode ser jogado já no 1º turno.)
- **Item** — efeito imediato; **sem limite por turno**; descartado após o uso.
- **Ferramenta** — fica **anexada** a um monstro (1 Ferramenta por monstro).
- **Item Fóssil** — carta especial que entra em jogo **como se fosse um monstro Básico** (com PS próprio, não dá ponto ao ser destruída em alguns casos, e certos monstros evoluem dela). Não pode começar a partida em jogo.

## 1.8 Tipos elementais do Pocket

10 tipos: **Planta, Fogo, Água, Elétrico, Psíquico, Lutador, Sombrio, Metal, Dragão e Incolor**. Só existem 8 tipos de Energia — **Dragão e Incolor não têm Energia própria**: ataques de Dragão pedem combinações de outras energias, e Incolor aceita qualquer uma.

---

# PARTE 2 — PASSO A PASSO: CRIANDO SEU PRÓPRIO JOGO

Agora vem a parte criativa. Siga estas 10 etapas para transformar o sistema acima em um jogo original.

## Etapa 1 — Defina a identidade do universo
- Escolha um **tema** que substitua "monstrinhos de bolso": bestas cósmicas, espíritos elementais, robôs bio-mecânicos, criaturas de sonhos etc.
- Dê um **nome ao jogo** e ao "treinador" (aqui: **Nexus Beasts Pocket**, e os jogadores são **Invocadores**).
- Renomeie os conceitos-chave para fugir da marca original:

| Conceito original | Nome no seu jogo (exemplo) |
|---|---|
| Pokémon | **Beast (Besta)** |
| Treinador (categoria de carta) | **Aliado** |
| Apoiador | **Mentor** |
| Pokémon Ativo | **Besta da Linha de Frente** |
| Banco | **Reserva** |
| Zona de Energia | **Núcleo de Mana** |
| Pontos | **Selos de Vitória** |
| Carta EX | **Carta ÔMEGA (Ω)** |

## Etapa 2 — Recrie a tabela de tipos
Crie 10 tipos originais espelhando a estrutura (8 com energia própria + 2 especiais) e monte um **ciclo de fraquezas** fechado, para que todo tipo tenha predador e presa:

| Tipo original | Tipo novo | Símbolo | Fraco contra |
|---|---|---|---|
| Planta | **Flora** | 🌿 | Brasa |
| Fogo | **Brasa** | 🔥 | Maré |
| Água | **Maré** | 💧 | Faísca |
| Elétrico | **Faísca** | ⚡ | Rocha |
| Psíquico | **Mente** | 🔮 | Sombra |
| Lutador | **Rocha** | 🪨 | Mente |
| Sombrio | **Sombra** | 🌑 | Rocha |
| Metal | **Aço** | ⚙️ | Brasa |
| Dragão | **Mito** | 🐉 | — (sem fraqueza; sem energia própria) |
| Incolor | **Neutro** | ⭐ | Rocha (ou variável) |

## Etapa 3 — Copie o esqueleto de regras
Adote integralmente a Parte 1 trocando os nomes: baralho de 20, 2 cópias, 3 Selos de Vitória, Reserva de 3, Núcleo de Mana com 1 mana/turno, fraqueza +20, sem resistência, mão máxima de 10, sem derrota por fim de baralho, Ω vale 2 selos. **Não mude nada na primeira versão** — primeiro clone, depois inove.

## Etapa 4 — Defina a matemática de balanceamento
Use estas fórmulas de referência (extraídas do padrão do jogo original):

**PS (Pontos de Saúde):**
- Básico frágil: 30–60 | Básico sólido: 70–100 | Estágio 1: 80–120 | Estágio 2: 120–160 | Básico Ω: 100–140 | Estágio superior Ω: 150–190

**Dano por Energia (regra de ouro ≈ 25–30 de dano por energia de custo):**
- 1 energia → 10–30 de dano
- 2 energias → 30–60
- 3 energias → 60–100
- 4 energias → 100–150 (geralmente com desvantagem: descartar energia, dano em si mesmo, cara-ou-coroa)

**Modificadores de custo:** efeitos positivos (status, dano na Reserva, cura, compra) "custam" ~10–20 de dano; efeitos negativos (auto-dano, descartar energia) "pagam" +10–30 de dano extra.

**Custo de recuo:** 0 (velozes) a 3 (tanques). Quanto maior o PS, maior tende a ser o recuo.

## Etapa 5 — Desenhe a anatomia da carta
Todo monstro precisa exibir: Estágio (e de quem evolui) • Nome • PS • Tipo • Ilustração • Habilidade (opcional) • Ataques (custo, nome, dano, efeito) • Fraqueza • Custo de recuo • Raridade (♦1–♦4, ★). Aliados exibem: categoria (Mentor/Item/Ferramenta/Fóssil), nome, texto do efeito e a regra da categoria.

## Etapa 6 — Crie o bestiário (Parte 3 deste documento)
Mínimo viável de um set inicial: **5+ monstros por tipo**, com pelo menos **1 linha evolutiva completa** (Básico→Est.1→Est.2) por tipo, 1 carta Ω por tipo e o restante de básicos/linhas curtas.

## Etapa 7 — Crie as cartas de Aliado (Parte 4)
Um set funcional precisa de: 2 cartas de compra, 1 busca de monstro, 2 curas, 1 troca/controle de posição, 1 redução de recuo, 2 aceleradores de mana condicionados a tipo, 2–3 Ferramentas e 1–2 Fósseis.

## Etapa 8 — Monte baralhos-teste (Parte 5)
Monte 2 baralhos de 20 cartas de tipos diferentes e jogue-os entre si dezenas de vezes.

## Etapa 9 — Playtest e ajuste
Checklist de saúde do jogo:
- As partidas duram 8–15 minutos e 10–25 turnos?
- Quem começa vence ~50% das vezes? (Se ganhar demais, reforce a regra "sem mana no 1º turno".)
- Alguma carta aparece em 100% dos baralhos vencedores? → enfraqueça (nerf).
- Alguma carta nunca é usada? → fortaleça (buff) ou redesenhe.
- Um jogador que está perdendo consegue virar o jogo? Deve ser possível, mas não trivial.

## Etapa 10 — Produza o protótipo
- **Físico:** imprima as cartas em papel (9 por folha A4), use protetores de carta (sleeves) com uma carta comum atrás para dar rigidez; use dado/moeda e marcadores de dano de 10/50.
- **Digital:** comece com Tabletop Simulator/Playingcards.io para testes; para um app real, uma stack simples é Godot ou Unity + servidor autoritativo (Node/Go) com matchmaking. Toda a lógica de regras deve rodar no servidor para evitar trapaças.

---

# PARTE 3 — BESTIÁRIO DO SET INICIAL "DESPERTAR DO NEXUS" (50+ monstros originais)

Legenda dos custos de ataque: 🌿 Flora · 🔥 Brasa · 💧 Maré · ⚡ Faísca · 🔮 Mente · 🪨 Rocha · 🌑 Sombra · ⚙️ Aço · ⭐ qualquer energia. "Recuo" = nº de energias descartadas para recuar. Fraquezas seguem o ciclo da Etapa 2.

## 3.1 Tipo FLORA 🌿 (fraqueza: Brasa 🔥)

| Carta | Estágio | PS | Habilidade | Ataques | Recuo |
|---|---|---|---|---|---|
| **Brotinelo** | Básico | 60 | — | 🌿 Chicote de Broto — 20 | 1 |
| **Folhagor** | Est. 1 (de Brotinelo) | 90 | — | 🌿🌿 Lâmina Foliar — 40 | 1 |
| **Selvarok** | Est. 2 (de Folhagor) | 150 | **Fotossíntese:** 1x por turno, cure 20 de dano deste monstro. | 🌿🌿🌿⭐ Fúria da Selva — 100 | 3 |
| **Cogumim** | Básico | 70 | — | 🌿 Esporo Sonolento — 10; o defensor fica **Adormecido**. | 1 |
| **Espinhel** | Básico | 80 | **Casca de Espinhos:** se este monstro estiver na Linha de Frente e sofrer dano de ataque, o atacante sofre 20. | 🌿🌿 Agulhada — 30 | 2 |
| **Selvarok Ω** | Básico Ω | 140 | — | 🌿🌿 Raízes Vorazes — 40; cure 20 deste monstro. / 🌿🌿🌿🌿 Colapso Verde — 130; este monstro sofre 30. | 3 |

## 3.2 Tipo BRASA 🔥 (fraqueza: Maré 💧)

| Carta | Estágio | PS | Habilidade | Ataques | Recuo |
|---|---|---|---|---|---|
| **Fagulho** | Básico | 60 | — | 🔥 Faísca Quente — 20 | 1 |
| **Pirandra** | Est. 1 (de Fagulho) | 90 | — | 🔥🔥⭐ Bafo Ardente — 60; joga moeda: cara = defensor **Queimado**. | 2 |
| **Vulkragon** | Est. 2 (de Pirandra) | 160 | — | 🔥🔥🔥🔥 Erupção Total — 140; descarte 2 energias 🔥 deste monstro. | 3 |
| **Cinzelim** | Básico | 50 | — | 🔥 Cinza Irritante — 10; o defensor fica **Queimado**. | 1 |
| **Lavaboi** | Básico | 100 | — | 🔥🔥🔥 Investida Magmática — 60 | 3 |
| **Vulkragon Ω** | Básico Ω | 140 | **Coração de Magma:** 1x por turno, pegue 1 energia 🔥 do Núcleo de Mana e anexe a este monstro. | 🔥🔥🔥 Tempestade de Fogo — 90 | 2 |

## 3.3 Tipo MARÉ 💧 (fraqueza: Faísca ⚡)

| Carta | Estágio | PS | Habilidade | Ataques | Recuo |
|---|---|---|---|---|---|
| **Gotari** | Básico | 60 | — | 💧 Jato d'Água — 20 | 1 |
| **Ondaluz** | Est. 1 (de Gotari) | 90 | — | 💧💧 Pulso de Maré — 50 | 1 |
| **Abissarion** | Est. 2 (de Ondaluz) | 150 | **Correnteza:** ao jogar esta carta da mão para evoluir, você pode trocar o monstro da Linha de Frente do oponente por um da Reserva dele. | 💧💧💧 Vórtice Abissal — 90 | 2 |
| **Concharrico** | Básico | 80 | **Concha Rígida:** este monstro sofre −10 de dano de ataques. | 💧💧 Estilhaço de Concha — 30 | 2 |
| **Peixelor** | Básico | 60 | — | 💧⭐ Cardume Veloz — 20+; joga 2 moedas: +20 por cara. | 1 |
| **Abissarion Ω** | Básico Ω | 150 | — | 💧💧 Prisão de Bolhas — 40; o defensor não pode recuar no próximo turno. / 💧💧💧⭐ Tsunami — 120 | 3 |

## 3.4 Tipo FAÍSCA ⚡ (fraqueza: Rocha 🪨)

| Carta | Estágio | PS | Habilidade | Ataques | Recuo |
|---|---|---|---|---|---|
| **Voltim** | Básico | 60 | — | ⚡ Choquinho — 20 | 1 |
| **Raiotem** | Est. 1 (de Voltim) | 90 | — | ⚡⚡ Descarga — 40; joga moeda: cara = defensor **Paralisado**. | 1 |
| **Tempestrix** | Est. 2 (de Raiotem) | 140 | **Sobrecarga:** os ataques deste monstro custam ⭐1 a menos se você tiver 3 monstros na Reserva. | ⚡⚡⚡ Relâmpago Cadente — 90 | 1 |
| **Zumbizz** | Básico | 50 | — | ⚡ Zumbido Estático — 10; devolva 1 energia do defensor para o Núcleo de Mana do oponente (joga moeda: só com cara). | 0 |
| **Magnetauro** | Básico | 90 | — | ⚡⚡⭐ Chifre Eletrizado — 50 | 2 |
| **Tempestrix Ω** | Básico Ω | 130 | — | ⚡ Ricochete — 30 / ⚡⚡⚡ Circuito Máximo — 60 em um monstro do oponente à sua escolha (Reserva incluída). | 1 |

## 3.5 Tipo MENTE 🔮 (fraqueza: Sombra 🌑)

| Carta | Estágio | PS | Habilidade | Ataques | Recuo |
|---|---|---|---|---|---|
| **Sonim** | Básico | 60 | — | 🔮 Toque Psíquico — 20 | 1 |
| **Oraculix** | Est. 1 (de Sonim) | 80 | **Premonição:** 1x por turno, olhe a carta do topo do seu baralho. | 🔮🔮 Onda Mental — 40 | 1 |
| **Astrallume** | Est. 2 (de Oraculix) | 140 | — | 🔮🔮⭐ Explosão Astral — 60+; +20 por energia 🔮 extra anexada além do custo. | 2 |
| **Hipnolho** | Básico | 70 | — | 🔮 Olhar Hipnótico — o defensor fica **Adormecido** (sem dano). / 🔮🔮 Pesadelo — 30; +30 se o defensor estiver Adormecido. | 1 |
| **Levitoad** | Básico | 60 | **Levitação:** custo de recuo 0 se este monstro tiver energia 🔮 anexada. | 🔮⭐ Salto Etéreo — 30 | 1 |
| **Astrallume Ω** | Básico Ω | 140 | **Elo Cósmico:** 1x por turno, mova 1 energia 🔮 entre seus monstros. | 🔮🔮🔮 Colapso Estelar — 100 | 2 |

## 3.6 Tipo ROCHA 🪨 (fraqueza: Mente 🔮)

| Carta | Estágio | PS | Habilidade | Ataques | Recuo |
|---|---|---|---|---|---|
| **Pedrik** | Básico | 70 | — | 🪨 Soco de Pedra — 20 | 1 |
| **Granitor** | Est. 1 (de Pedrik) | 100 | — | 🪨🪨⭐ Avalanche — 60 | 3 |
| **Titanólito** | Est. 2 (de Granitor) | 170 | **Pele de Montanha:** este monstro sofre −20 de dano de ataques. | 🪨🪨🪨⭐ Terremoto — 110; cause 10 a cada monstro da SUA Reserva. | 4 |
| **Garrancho** | Básico | 60 | — | 🪨 Golpe Duplo — 10x; joga 2 moedas: 10 por cara. / 🪨🪨 Quebra-Guarda — 40 | 1 |
| **Escavurso** | Básico | 90 | — | 🪨🪨 Garra Subterrânea — 40; este ataque ignora efeitos que reduzem dano no defensor. | 2 |
| **Titanólito Ω** | Básico Ω | 160 | — | 🪨🪨 Muralha Viva — 30; este monstro sofre −30 de dano de ataques no próximo turno. / 🪨🪨🪨🪨 Punho Sísmico — 140 | 4 |

## 3.7 Tipo SOMBRA 🌑 (fraqueza: Rocha 🪨)

| Carta | Estágio | PS | Habilidade | Ataques | Recuo |
|---|---|---|---|---|---|
| **Noctim** | Básico | 60 | — | 🌑 Arranhão Sombrio — 20 | 1 |
| **Umbrarat** | Est. 1 (de Noctim) | 90 | — | 🌑🌑 Presas Venenosas — 40; o defensor fica **Envenenado**. | 1 |
| **Reinoturno** | Est. 2 (de Umbrarat) | 140 | **Manto da Noite:** se o defensor estiver Envenenado, os ataques deste monstro causam +30. | 🌑🌑⭐ Lâmina do Eclipse — 70 | 2 |
| **Espectrolho** | Básico | 50 | **Intangível:** joga moeda quando este monstro for atacado; cara = previne todo o dano. (1x por turno do oponente.) | 🌑🌑 Sussurro Maldito — 30 | 1 |
| **Corvomau** | Básico | 70 | — | 🌑 Bico Ladrão — 20; se este ataque nocautear o defensor, compre 2 cartas. | 1 |
| **Reinoturno Ω** | Básico Ω | 140 | — | 🌑🌑 Toxina Profunda — 30; o defensor fica **Envenenado** (sofre 20 em vez de 10 entre turnos). / 🌑🌑🌑 Julgamento Noturno — 90 | 2 |

## 3.8 Tipo AÇO ⚙️ (fraqueza: Brasa 🔥)

| Carta | Estágio | PS | Habilidade | Ataques | Recuo |
|---|---|---|---|---|---|
| **Parafusim** | Básico | 70 | — | ⚙️ Engrenada — 20 | 2 |
| **Blindobô** | Est. 1 (de Parafusim) | 110 | — | ⚙️⚙️⭐ Prensa Hidráulica — 60 | 3 |
| **Fortalezaur** | Est. 2 (de Blindobô) | 160 | **Liga Reforçada:** este monstro não pode ficar Envenenado nem Queimado. | ⚙️⚙️⚙️⭐ Canhão Pesado — 120; este monstro não pode atacar no seu próximo turno. | 4 |
| **Latinha** | Básico | 60 | — | ⚙️ Reciclar — cure 20 deste monstro. / ⚙️⚙️ Batida Metálica — 30 | 1 |
| **Gyrodrone** | Básico | 70 | **Voo Estável:** custo de recuo 0. | ⚙️⚙️ Hélice Cortante — 40 | 0 |
| **Fortalezaur Ω** | Básico Ω | 150 | **Escudo Automático:** este monstro sofre −10 de dano de ataques. | ⚙️⚙️⚙️ Míssil Guiado — 50 em um monstro do oponente à sua escolha. | 3 |

## 3.9 Tipo MITO 🐉 (sem fraqueza; sem energia própria — custos mistos)

| Carta | Estágio | PS | Habilidade | Ataques | Recuo |
|---|---|---|---|---|---|
| **Ovolisco** | Básico | 60 | — | ⭐ Cabeçada — 20 | 1 |
| **Dracolim** | Est. 1 (de Ovolisco) | 100 | — | 🔥💧 Sopro Primordial — 50 | 2 |
| **Aetherion** | Est. 2 (de Dracolim) | 160 | — | 🔥🔥💧💧 Fúria do Nexus — 150 | 3 |
| **Wyrmito** | Básico | 70 | — | ⚡🌑 Mordida Ancestral — 40 | 1 |
| **Serpelume** | Básico | 90 | — | 💧🔮 Espiral Mística — 40; cure 20 deste monstro. | 2 |
| **Aetherion Ω** | Básico Ω | 150 | **Presença Mítica:** os ataques deste monstro não são afetados por habilidades do defensor. | 🔮🌑⭐ Ruptura Dimensional — 100 | 3 |

## 3.10 Tipo NEUTRO ⭐ (fraqueza: Rocha 🪨; aceita qualquer energia)

| Carta | Estágio | PS | Habilidade | Ataques | Recuo |
|---|---|---|---|---|---|
| **Fofurelho** | Básico | 60 | — | ⭐ Plaquinha — 10; joga moeda: cara = o defensor não pode atacar no próximo turno. | 1 |
| **Saltarelho** | Est. 1 (de Fofurelho) | 90 | — | ⭐⭐ Pulo Duplo — 30+; joga moeda: cara = +30. | 1 |
| **Rugidonte** | Básico | 100 | — | ⭐⭐⭐ Atropelo — 60 | 3 |
| **Plumazul** | Básico | 60 | **Vento de Cauda:** 1x por turno, se este monstro estiver na Reserva, você pode reduzir em 1 o custo de recuo da sua Linha de Frente neste turno. | ⭐ Bicada — 20 | 1 |
| **Melodina** | Básico | 70 | — | ⭐ Canção Calmante — cure 30 de um dos seus monstros. / ⭐⭐ Grito Agudo — 30 | 1 |
| **Rugidonte Ω** | Básico Ω | 140 | — | ⭐⭐ Investida — 40 / ⭐⭐⭐⭐ Fúria Selvagem — 80+; +40 se você tiver menos Selos de Vitória que o oponente. | 3 |

**Total: 60 cartas de monstro (6 por tipo × 10 tipos, incluindo 1 Ω por tipo).**

---

# PARTE 4 — CARTAS DE ALIADO (SUPORTE) DO SET INICIAL

Todas com nomes e textos originais, cobrindo as funções essenciais de um set jogável.

## 4.1 Mentores (equivalentes a Apoiadores — máx. 1 por turno)

| Carta | Efeito |
|---|---|
| **Professora Íris** | Descarte sua mão e compre 3 cartas. |
| **Recruta Bruno** | Compre 2 cartas. |
| **Curandeira Maya** | Cure 50 de dano de um dos seus monstros. |
| **Capitão Vento** | Troque a Besta da Linha de Frente do oponente por uma da Reserva dele (o oponente escolhe qual entra). |
| **Ferreiro Odan** | Escolha 1 dos seus monstros de Aço ⚙️: ele sofre −20 de dano de ataques até o fim do próximo turno do oponente. |
| **Maré-Mestra Suri** | Joga uma moeda: se cara, pegue 2 energias 💧 do Núcleo de Mana e anexe a 1 monstro de Maré da sua Reserva. |
| **Rastreadora Kova** | Procure no seu baralho 1 monstro Básico aleatório e coloque-o na sua mão. Embaralhe o baralho. |
| **Chamado do Nexus** | Só pode ser usada se você tiver 2+ Selos de Vitória a menos que o oponente. Compre 3 cartas. |

## 4.2 Itens (sem limite por turno)

| Carta | Efeito |
|---|---|
| **Poção do Vale** | Cure 20 de dano de um dos seus monstros. |
| **Antídoto Universal** | Remova todas as Condições Especiais da sua Besta da Linha de Frente. |
| **Botas de Salto** | Neste turno, o custo de recuo da sua Linha de Frente é reduzido em 1. |
| **Cápsula de Captura** | Joga uma moeda: se cara, procure no baralho 1 monstro Básico aleatório e coloque na mão. |
| **Sino do Recuo** | Troque sua Besta da Linha de Frente por uma da sua Reserva (sem pagar custo de recuo). |
| **Lente de Batalha** | Olhe as 3 cartas do topo do seu baralho e devolva-as em qualquer ordem. |

## 4.3 Ferramentas (anexáveis — 1 por monstro)

| Carta | Efeito |
|---|---|
| **Amuleto Vital** | O monstro com esta carta recebe +20 PS. |
| **Garra Afiada** | Os ataques do monstro com esta carta causam +10 de dano à Besta da Linha de Frente do oponente. |
| **Manto Espinhoso** | Se o monstro com esta carta estiver na Linha de Frente e sofrer dano de ataque, o atacante sofre 10. |

## 4.4 Itens-Relíquia (equivalentes aos Fósseis)

| Carta | Efeito |
|---|---|
| **Relíquia de Âmbar** | Jogue como se fosse uma Besta Básica de 40 PS, tipo Neutro, sem ataques e sem custo de recuo (pode ser descartada da Linha de Frente a qualquer momento no seu turno). Se for nocauteada, o oponente NÃO marca Selo. O monstro **Ambarion** (set futuro) evolui desta carta. |
| **Relíquia de Gelo** | Mesmas regras da Relíquia de Âmbar. O monstro **Glacivor** (set futuro) evolui desta carta. |

**Total do set "Despertar do Nexus": 60 monstros + 19 Aliados = 79 cartas.**

---

# PARTE 5 — BARALHOS INICIAIS DE EXEMPLO (20 cartas cada)

## Baralho "Fúria Vulcânica" (mono-Brasa 🔥)
- 2× Fagulho, 2× Pirandra, 2× Vulkragon
- 2× Cinzelim, 2× Lavaboi, 1× Vulkragon Ω
- 2× Professora Íris, 2× Recruta Bruno, 1× Curandeira Maya
- 2× Poção do Vale, 1× Sino do Recuo, 1× Amuleto Vital
**Plano de jogo:** segurar o início com Lavaboi/Cinzelim (queimadura) enquanto carrega Vulkragon Ω na Reserva com a habilidade Coração de Magma; fechar o jogo com Erupção Total.

## Baralho "Maré Constante" (mono-Maré 💧)
- 2× Gotari, 2× Ondaluz, 2× Abissarion
- 2× Concharrico, 2× Peixelor, 1× Abissarion Ω
- 2× Professora Íris, 2× Maré-Mestra Suri, 1× Capitão Vento
- 2× Poção do Vale, 1× Botas de Salto, 1× Garra Afiada
**Plano de jogo:** Concharrico tanka cedo; Suri acelera mana; Abissarion chega puxando alvos frágeis da Reserva inimiga com Correnteza.

---

# PARTE 6 — CHECKLIST FINAL DE PRODUÇÃO

## 6.1 Modelo de texto de carta (template)
```
[ESTÁGIO]  (Evolui de: ______)          [RARIDADE ♦/★]
NOME DA BESTA                     PS [___]  TIPO [ícone]
---------------------------------------------------------
HABILIDADE: Nome — texto do efeito (se houver)
---------------------------------------------------------
[custo] NOME DO ATAQUE ................. [dano]
        texto do efeito (se houver)
---------------------------------------------------------
Fraqueza: [tipo +20]        Recuo: [0-4 ⭐]
```

## 6.2 Roteiro de playtest (repita a cada mudança)
1. Jogue 10 partidas entre os 2 baralhos iniciais, anote vencedor, nº de turnos e quem começou.
2. Marque cartas "mortas" (nunca jogadas) e cartas "obrigatórias" (sempre decisivas).
3. Ajuste UMA variável por vez (PS, dano ou custo) em passos de 10 PS / 10 dano / 1 energia.
4. Repita até: duração média 8–15 min, taxa de vitória de quem começa entre 45–55%, e nenhum tipo com mais de 60% de vitórias contra todos os outros.

## 6.3 Regras de ouro do design (aprendidas com o jogo original)
- **Simplicidade primeiro:** 20 cartas, 3 selos e mana automática existem para partidas de 10 minutos. Toda carta nova deve caber nesse ritmo.
- **A mana automática é o coração do jogo:** ela remove a frustração de "não comprar energia" — nunca crie cartas que destruam completamente a mana do oponente.
- **Ω é risco/recompensa:** mais forte, porém entrega 2 selos. Mantenha essa tensão.
- **Todo tipo precisa de identidade:** Flora cura, Brasa descarta mana por dano alto, Maré manipula posições, Faísca é veloz e atinge a Reserva, Mente escala dano e prevê o baralho, Rocha tanka, Sombra envenena, Aço reduz dano, Mito tem custos mistos sem fraqueza, Neutro é flexível.
- **Coloque moedas onde houver poder demais:** o cara-ou-coroa é a válvula de segurança do balanceamento.

## 6.4 Expansões futuras (roadmap sugerido)
1. **Set 2:** +40 cartas, introduz as evoluções das Relíquias (Ambarion, Glacivor) e Ferramentas por tipo.
2. **Set 3:** monstros Ω evoluídos (Estágio 2 Ω) com 170–190 PS.
3. **Set 4:** mecânica nova exclusiva sua (ex.: "Fúria" — bônus quando o monstro está com metade dos PS), para o jogo ganhar identidade própria além do clone.

---

*Documento criado como guia de design. Todos os nomes de monstros, cartas e o universo "Nexus Beasts" são originais e livres para você usar e modificar no seu projeto.*
