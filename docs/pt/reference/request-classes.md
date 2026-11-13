---
title: Classes de pedido
description: As cinco classes em que um pedido pode cair, o que cada uma registra, os critérios do Express e como funcionam pedido composto, escolha explícita e escalada.
---

# Classes de pedido

Esta página responde como o agente decide o que um pedido vira. Todo pedido é classificado antes de o agente alocar número de track, track ou qualquer artefato. A classe decide a via por onde o trabalho segue e o que ele deixa em `on-track/`, se deixar algo.

## As cinco classes

| Classe | O que é | O que registra |
|---|---|---|
| Operacional | Rodar, compilar, instalar, inspecionar ou relatar sem editar arquivo versionado do repositório alvo | Nada. Nem track, nem artefato, e nunca uma nota dentro de uma track, inclusive em `assets/` |
| Express | Edição em que os cinco critérios do Express valem | Uma crumb local até o commit. Sem track, sem outro arquivo em `on-track/`, sem regenerar o índice |
| Highway | Qualquer outra edição, e toda edição com critério do Express incerto. É o padrão | O ciclo completo: `intent.md`, `spec.md`, `tasks.md` e `assets/` em `on-track/tracks/NNN-slug/` |
| Só pesquisa | Investigar um fato externo, sem mudança de estado desejada no sistema | `on-track/research/<slug>.md` e o índice, por `ot-research`. Sem track |
| Só avaliação | Avaliar ou auditar o que existe, sem mudança de estado desejada no sistema | `on-track/assessments/<YYYY-MM-DD>-<slug>.md` e o índice, por `ot-assess`. Sem track |

Off Road não é uma classe nem uma terceira via. É o acesso consultado ao Highway: o mesmo ciclo, com mais perguntas ao usuário durante o intent e a spec. Veja [Off Road](../guides/off-road.md).

Um pedido que só pede um handoff vai para `ot-handoff`, que grava o handoff e regenera o índice sem track. Veja [Comandos](commands.md).

## Critérios do Express

Um pedido segue pela via Express só quando os cinco critérios valem:

1. O pedido diz o que construir, sem pergunta aberta que o mudaria.
2. No máximo três arquivos mudam.
3. Nada disto muda: contrato público (API, flags de CLI, schema, formato de arquivo consumido por terceiros), dado persistido ou migration, controle de segurança (autenticação, autorização, segredos, permissões) ou dependência (adicionada, atualizada ou removida).
4. Reverter só o diff desfaz a mudança, sem backfill de dados e sem efeito externo.
5. Um comando existente ou uma verificação observável confirma o resultado.

Se algum critério for incerto, o pedido segue pelo Highway.

## O que a via Express faz

1. O agente diz em uma frase que a mudança segue pela via Express.
2. Implementa a mudança.
3. Roda a verificação.
4. Grava uma crumb, tenha a verificação passado ou não.
5. Relata a mudança e o resultado.

O relato encerra o trabalho. Não há sinal nem parada no fim da via Express. Fora a crumb, o agente não cria track nem arquivo em `on-track/` e não regenera o índice. A única exceção de artefato é uma decisão que passa no limiar de ADR: o agente grava só essa ADR e regenera o índice. Veja [Limiares](thresholds.md).

O formato da crumb está em [Artefatos](artifacts.md#crumb). Como desfazer uma mudança Express e como as crumbs alimentam o commit está em [Mudanças Express](../guides/express-changes.md) e [Commits](../guides/committing.md).

## Pedidos compostos

Um pedido que pede várias coisas é separado em partes antes de qualquer alocação. Cada parte é classificada sozinha e segue a própria via. Uma mensagem pode gerar ao mesmo tempo uma ação operacional, uma mudança Express e uma track no Highway.

Quando um pedido chega a `ot-intent` sem que o usuário tenha nomeado a skill, as partes operacionais e Express não criam track. A skill para depois dessas partes, a menos que restem partes do Highway.

Quando um pedido é vago ou ambíguo demais para classificar, o agente pergunta em uma rodada de no máximo quatro perguntas, pela ferramenta de perguntas do host quando ela existe.

## Escolha explícita

A escolha explícita do usuário vence nos dois sentidos:

| O usuário | Efeito |
|---|---|
| Nomeia `ot-intent`, ou pede uma track ou um intent | A edição segue pelo Highway, mesmo que se qualificasse para o Express |
| Pede para fazer direto, ou sem track | A edição segue pela via Express |
| Pede Off Road | A track do Highway roda com a consulta do Off Road desde esse momento até a aprovação da spec |

## Escalada do Express para o Highway

Se um critério do Express deixar de valer durante o trabalho, o agente para antes da edição que o quebraria, diz qual critério caiu e inicia o Highway com `ot-intent`.

## Roteamento dentro do `ot-intent`

Se um pedido que chega ao `ot-intent` é só investigativo ("pesquise", "investigue") ou avaliativo ("avalie", "audite") e não descreve mudança de estado desejada, a skill o encaminha para `ot-research` ou `ot-assess` como chamada direta. Não cria pasta de track nem `intent.md`.
