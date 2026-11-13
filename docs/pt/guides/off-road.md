---
title: Off Road
description: Quando pedir o Off Road, o que ele muda nas rodadas do intent e da spec, e onde termina.
---

# Off Road

Esta página responde quando pedir o Off Road, o que ele muda, onde termina e o que continua exatamente como no Highway.

O Off Road não é uma via nem uma classe de pedido. É o acesso consultado ao Highway: a mesma track, as mesmas etapas, os mesmos artefatos, com mais das decisões iniciais trazidas para você.

## Quando pedir

No Highway o agente faz só perguntas bloqueadoras; outras perguntas podem ser resolvidas no intent ou ficar em `Open questions`, e perguntas adiáveis viram tarefas delimitadas na spec (veja [Perguntas e delegação](questions-and-delegation.md)). Peça o Off Road quando o pedido ainda depende de decisões que você quer tomar: um layout sobre o qual você tem opinião, nomes, a ordem do trabalho, qual de duas abordagens razoáveis seguir.

Peça com palavras simples, no início ou em qualquer ponto do intent ou da spec:

```text
/ot-intent Redesenhe a página de preços. Vá de Off Road, quero opinar nas escolhas.
```

```text
Mude para Off Road no resto desta spec.
```

## O que muda

Enquanto o Off Road está ligado, cada rodada de perguntas do intent e da spec também traz as escolhas que o agente resolveria sozinho. Nada mais muda na rodada:

- No máximo quatro perguntas por rodada.
- Cada pergunta nomeia a decisão que destrava e oferece opções, com a recomendação do agente primeiro.
- Você pode responder qualquer pergunta com "decida você"; o agente registra a decisão delegada e a lista no resumo para veto.
- A etapa de intent continua com uma rodada; a etapa de spec continua usando quantas rodadas forem necessárias para resolver as perguntas bloqueadoras.

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
