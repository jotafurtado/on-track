---
title: Off Road
description: Quando pedir o Off Road, o que ele muda nas rodadas do intent e da spec, e onde termina.
---

# Off Road

Esta página responde quando pedir o Off Road, o que ele muda, onde termina e o que continua exatamente como no Highway.

O Highway é a estrada pavimentada: o pedido é claro, o terreno é conhecido e o agente segue com poucas paradas. O Off Road é a estrada sem pavimento: o terreno ainda não foi mapeado, então você vai mais devagar e para mais vezes para olhar o caminho.

O Off Road não é uma via nem uma classe de pedido. É o acesso consultado ao Highway: a mesma track, as mesmas etapas, os mesmos artefatos, com mais das decisões iniciais trazidas para você.

## Quando pedir

A maior parte do trabalho anda no Highway ou na via Express. Peça o Off Road quando o pedido leva a um terreno que você ainda não conhece, ou quando você quer tomar as escolhas de design:

| Pedido | Rota |
|---|---|
| Crie uma API REST neste projeto Laravel. | Highway: a stack é conhecida e o pedido diz o que construir. |
| Crie uma API com Rust como motor. Nunca usamos Rust aqui. | Off Road: bibliotecas, estrutura e trade-offs ainda estão em aberto. |

Peça com palavras simples, no início ou em qualquer ponto do intent ou da spec:

```text
/ot-intent Crie a API de cobrança com Rust como motor. Vá de Off Road, é terreno novo para nós.
```

```text
Mude para Off Road no resto desta spec.
```

O agente também pode sugerir o Off Road no Highway: quando o seu pedido está vago demais para o intent, ou quando sobram perguntas bloqueadoras depois da terceira rodada da spec. Ele só sugere; a rota muda quando você pede.

## O que muda

Enquanto o Off Road está ligado:

- Cada rodada também traz as escolhas de design que o agente resolveria sozinho, além das perguntas bloqueadoras.
- As rodadas não têm número fixo, no intent nem na spec. O agente faz quantas os pontos em aberto pedirem, uma por tema, e para quando não sobra nenhum.
- Antes de cada rodada, o agente levanta as opções consolidadas para aquele tema (bibliotecas, abordagens) e as apresenta com os trade-offs e a recomendação dele.
- Quando o terreno pede estudo que vai além da track, o agente sugere uma research.

O que continua igual em toda rodada: no máximo quatro perguntas, um tema, cada uma nomeando a decisão que destrava com a recomendação primeiro, e "decida você" para delegar. Pontos já resolvidos continuam sem ser perguntados. Veja [Perguntas e delegação](questions-and-delegation.md).

## Onde termina

O Off Road vale do momento em que você o pede até a spec daquela track ser aprovada, isto é, até o seu verde depois do resumo da spec. Da spec aprovada em diante, a track segue no Highway.

## O que não muda

| Não muda | Como funciona |
|---|---|
| Implement | O mesmo procedimento de qualquer track: grupos, `Validate`, aceitação, gate. |
| Revisão | A mesma regra em toda track: todo achado `[blocking]` e todo `[important]` dentro do escopo é corrigido, e todo achado é registrado em `assets/review.md`. |
| Artefatos | Os mesmos arquivos: `intent.md`, `spec.md`, `tasks.md`, `assets/`, e os mesmos artefatos de apoio. |
| Sinais | As mesmas três paradas com verde, amarelo e vermelho. |
| Limiares | Os mesmos critérios para assessments e ADRs. Veja [Limiares](../reference/thresholds.md). |

## Uma spec reaberta

Se uma mudança material devolve uma spec aprovada a `draft`, o Off Road não volta sozinho. Peça de novo se quiser as perguntas extras na spec revisada.

## Uma sessão nova

O Off Road não é gravado em nenhum arquivo: nenhum campo de frontmatter nem artefato o registra. Em uma sessão nova, enquanto a spec ainda não foi aprovada, peça o Off Road de novo se quiser. Isso vale também quando você retoma por um handoff que cita o seu pedido anterior: a citação não liga o Off Road.

## Off Road ou research antes

O Off Road cobre o terreno desconhecido de um pedido que você já tem. Se a ideia ainda está se formando, comece antes do intent com uma research ou uma sessão de grilling (veja [Quando a ideia ainda não está clara](questions-and-delegation.md#quando-a-ideia-ainda-nao-esta-clara)).
