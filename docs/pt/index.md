---
title: On Track Method
description: Um ciclo de desenvolvimento de software leve, conduzido por agentes, que mantém o registro proporcional ao tamanho de cada pedido.
---

# On Track Method

Esta página responde o que é o On Track Method, quem decide o quê e por qual caminho um pedido segue. O restante da documentação está nos links ao final.

O On Track Method é um ciclo de desenvolvimento de software leve para agentes de código. Ele funciona como um conjunto de skills e um bloco gerenciado no `AGENTS.md` do repositório, e guarda seus registros como arquivos Markdown simples em `on-track/`. O registro acompanha o tamanho do pedido: o que não precisa de track não ganha track.

## Quem decide o quê

| Papel | Responsabilidades |
|---|---|
| Você | Define o rumo, responde às perguntas bloqueadoras e dá o sinal em cada parada do Highway. |
| O agente | Classifica o pedido, investiga, documenta o intent, planeja a spec e as tarefas, implementa, valida, revisa e relata. |

O método nunca faz commit, push ou deploy sozinho. O commit fica com você ou com quem o preparar (veja [Commit](guides/committing.md)).

## Três caminhos para um pedido

Antes de alocar qualquer coisa, o agente separa um pedido composto em partes e classifica cada parte. Trabalho operacional (rodar, compilar, inspecionar, relatar) acontece sem nenhum artefato. Um pedido só de pesquisa ou só de avaliação gera esse artefato e nenhuma track. As edições seguem um destes caminhos:

![O On Track Method encaminha pedidos por Express, Highway ou Off Road. Express implementa, verifica, registra um crumb e relata sem sinais. Highway segue por intent, spec, implementação, revisão e ship com sinais humanos. Off Road acrescenta consulta durante intent e spec, e se une ao Highway após a aprovação da spec.](../images/pt/lanes.png)

`●` marca uma parada em que o agente espera o seu sinal: verde (`.`), amarelo (qualquer instrução) ou vermelho (`x`).

- **Express**: uma edição pequena e reversível que cumpre cinco critérios. O agente implementa, roda uma verificação, escreve uma nota local chamada crumb e relata. Não há track nem parada. Veja [Mudanças Express](guides/express-changes.md).
- **Highway**: toda outra edição, e o padrão. O agente escreve um intent, depois uma spec e as tarefas, então implementa e oferece o ship, parando para o seu sinal depois de cada etapa. Veja [Sua primeira track](getting-started/first-track.md) e [Sinais do Highway](guides/highway-signals.md).
- **Off Road**: não é uma via separada. É o acesso consultado ao Highway: a pedido, as rodadas de perguntas do intent e da spec também trazem as escolhas que o agente resolveria sozinho. Termina quando a spec é aprovada. Veja [Off Road](guides/off-road.md).

## Para onde ir

| Seção | O que contém |
|---|---|
| Primeiros passos | [Instalação](getting-started/installation.md), [Sua primeira track](getting-started/first-track.md), [Migração do nome anterior](getting-started/migrating.md) |
| Guias | [Mudanças Express](guides/express-changes.md), [Sinais do Highway](guides/highway-signals.md), [Off Road](guides/off-road.md), [Perguntas e delegação](guides/questions-and-delegation.md), [Artefatos de apoio](guides/supporting-artifacts.md), [Commit](guides/committing.md) |
| Referência | [Classes de pedido](reference/request-classes.md), [Ciclo](reference/cycle.md), [Sinais](reference/signals.md), [Artefatos](reference/artifacts.md), [Limiares](reference/thresholds.md), [Comandos](reference/commands.md), [Validação](reference/validation.md), [Regras para agentes](reference/agent-rules.md) |
| Conceitos | [Por que On Track](concepts/why-on-track.md), [Escolhas de design](concepts/design-choices.md) |
