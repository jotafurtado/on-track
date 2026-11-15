---
title: Perguntas e delegação
description: O que o agente pergunta, como funciona uma rodada de perguntas no Highway e no Off Road e como delegar uma decisão com "decida você".
---

# Perguntas e delegação

Esta página responde o que o agente pergunta durante o intent e a spec, qual é o formato de uma rodada de perguntas, quantas rodadas cada rota tem e o que acontece quando você responde "decida você".

## O que nunca é perguntado

O agente pergunta só o que ainda está em aberto. Antes de perguntar, ele verifica se o ponto já está resolvido por uma destas fontes:

- o seu pedido,
- o contexto que ele já tem: o `AGENTS.md` e os arquivos lidos na sessão,
- uma ferramenta de consulta que o seu projeto indica para isso, como um grafo de código ou um servidor de memória,
- uma leitura pontual: um manifesto, o `.env.example`, `on-track/decisions/`.

Se o seu `AGENTS.md` já diz onde o sistema é hospedado, você não vai ser perguntado sobre onde ele vai ser hospedado. O fato resolvido entra no artefato com a fonte: no intent, em `Assumed state` > `Verified by the agent`.

Para se poupar de perguntas, escreva os fatos estáveis do projeto (stack, hospedagem, convenções) no `AGENTS.md` ou num documento que ele aponte.

## Perguntas bloqueadoras

Uma pergunta é bloqueadora quando a resposta muda um destes:

- escopo,
- segurança,
- persistência,
- integração externa,
- arquitetura,
- aceitação.

Perguntas bloqueadoras são feitas tanto no Highway quanto no [Off Road](off-road.md). As rotas diferem só no que perguntam além delas.

## As perguntas servem ao seu pedido

Cada pergunta esclarece o que você pediu ou propõe um caminho para chegar lá. O agente não abre frentes novas que você não pediu.

Uma decisão já registrada, num ADR ou numa escolha documentada, fica como está. Uma escolha que só está em uso, sem razão registrada, pode receber uma sugestão quando existe opção claramente melhor que serve ao seu pedido, como uma biblioteca mais consolidada que se encaixa no projeto. A sugestão ocupa uma das vagas da rodada e vem com a recomendação do agente.

## A rodada

Uma rodada tem no máximo quatro perguntas, feitas pela ferramenta de perguntas do host quando ela existe, todas sobre um tema: modelo de dados numa rodada, bibliotecas na seguinte, infraestrutura depois. Cada pergunta:

- nomeia a decisão que destrava,
- oferece opções,
- coloca a recomendação do agente primeiro.

```text
Armazenamento dos cadastros (destrava: persistência dos envios do formulário)
  1. Enviar ao provedor de newsletter atual (recomendado)
  2. Gravar em uma nova tabela do banco
  3. Mandar por e-mail para a caixa da equipe
```

Sinais não são perguntas. A parada no fim de cada etapa é lida como texto simples, nunca pela ferramenta de perguntas (veja [Sinais do Highway](highway-signals.md)).

## Quantas rodadas

| Rota | Intent | Spec |
|---|---|---|
| Highway | Uma rodada, só perguntas bloqueadoras | Até três rodadas, só perguntas bloqueadoras |
| Off Road | Quantas forem necessárias, bloqueadoras e escolhas de design | Quantas forem necessárias, bloqueadoras e escolhas de design |

No Highway:

- No intent, uma pergunta bloqueadora além do limite vai para `Open questions`, para a spec resolver. Qualquer outra pergunta o agente resolve sozinho ou deixa ali.
- Na spec, se sobrarem perguntas bloqueadoras depois da terceira rodada, o agente para, lista as que faltam e sugere o Off Road. O resumo e `. para implementar` ficam retidos até cada uma ser respondida ou delegada.
- Se o seu pedido está vago demais para o intent e as fontes acima não o resolvem, o agente sugere o Off Road e segue no Highway, a menos que você aceite a sugestão.

## Perguntas em aberto na spec

A spec lê as `Open questions` do intent e classifica cada uma:

| Tipo | O que acontece |
|---|---|
| Bloqueadora | Resolvida antes do resumo, dentro dos limites de rodada acima. |
| Adiável | A resposta não bloqueia a arquitetura geral nem o escopo. Vira uma tarefa delimitada cujo `Validate` nomeia a resposta ou o artefato esperado, em um grupo que os grupos dependentes listam em `(depends: ...)`. |

Cada entrada em `Open questions` é uma pergunta de verdade: termina com ponto de interrogação e nomeia a decisão que destrava, com um responsável quando houver. Sem delegação, o agente não inventa resposta para nenhum dos dois tipos.

## "Decida você"

Você pode responder qualquer pergunta com "decida você". Isso é uma delegação: o agente decide, registra a decisão e a mostra para você vetar.

| Etapa | Onde a decisão delegada é registrada |
|---|---|
| Intent | `intent.md`, em `Constraints` > `Proposed by the agent`, marcada `(delegated)` |
| Spec | `spec.md`, em `Constraints`, marcada `(delegated)` |

```markdown
### Proposed by the agent
- Signup submissions go to the existing newsletter provider. (delegated)
```

## Vetar uma decisão delegada

As decisões delegadas aparecem no resumo da etapa, antes da localização da track e da linha de próximo passo. Para vetar uma, responda com a mudança que você quer em vez de `.`: qualquer resposta assim é um sinal amarelo, então o agente revisa o intent ou a spec e mostra o resumo de novo. No resumo do intent, as outras restrições que o agente propôs por conta própria são listadas do mesmo jeito, para o mesmo veto. Uma restrição proposta pelo agente só é permitida quando omiti-la traz risco de perda de dados, problema de segurança ou quebra do resultado pedido. Ela deve nomear esse risco e não pode ampliar o resultado.

## Quando a ideia ainda não está clara

O intent começa quando você sabe o que quer construir. Se a ideia ainda está se formando, trabalhe nela antes do intent:

- Peça uma research (`/ot-research`) sobre o tema, leia e depois abra o intent.
- Ou faça antes uma sessão de grilling. A skill [`grill-me`](https://github.com/mattpocock/skills/tree/main/skills/productivity/grill-me), de Matt Pocock, é uma opção; ela não faz parte deste pacote.

Se o agente percebe que responder ao seu pedido exigiria explorar alternativas ao próprio pedido, ele avisa e sugere uma research.
