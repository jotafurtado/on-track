---
title: Escolhas de desenho
description: As escolhas por trás do On Track Method e o que foi pesado contra cada uma.
---

# Escolhas de desenho

Esta página responde por que o método fez algumas escolhas que podem surpreender, e o que foi pesado contra cada uma. As regras estão nas páginas de Referência citadas em cada seção.

## Sinais em texto

Em cada parada do Highway, o usuário responde em texto: `.` para verde, `x` para vermelho, qualquer outra coisa para amarelo. Fora dos dois tokens, vale o significado da mensagem, em qualquer idioma, e não uma lista fechada de palavras.

Pesado contra: responder pela ferramenta de perguntas do host, como um diálogo com botões. O diálogo pode cobrir o resumo que o usuário precisa ler para decidir, e digitar `.` é mais rápido do que qualquer clique. A ferramenta de perguntas fica reservada para perguntas de fato.

Os tokens são símbolos porque símbolo não tem idioma. As linhas de próximo passo que os anunciam (`. para continuar com a spec`, `. para implementar`, `. para ship (marca a track como concluida)`) ficam como o pacote as escreve.

Veja [Sinais](../reference/signals.md).

## Sem parada no fim do Express

A via Express se anuncia, implementa, verifica, grava uma crumb e relata. O relato encerra o trabalho; não há sinal.

Pesado contra: um sinal de saída como o do Highway. Numa mudança Express, essa parada só anunciaria que a mudança pode ser desfeita, e o usuário já pode pedir isso a qualquer momento. Desfazer é um pedido comum, que também apaga a crumb.

Veja [Mudanças Express](../guides/express-changes.md).

## O método nunca faz commit

Nenhuma skill e nenhuma via faz commit. O commit é do mantenedor, ou da ferramenta que o mantenedor usa para prepará-lo.

Pesado contra: fazer commit no fim de cada mudança. Em vez disso, o método deixa o que o commit precisa: no Highway, intent, spec e tasks explicam a mudança; na via Express, a crumb registra o pedido, a causa, os arquivos e a verificação.

Veja [Commits](../guides/committing.md).

## Off Road é acesso, não via

O Off Road é o acesso consultado ao Highway. Ele muda uma coisa só: enquanto vale, a rodada do intent ou da spec também leva as escolhas que o agente resolveria sozinho, dentro do mesmo teto de quatro perguntas. Termina quando a spec é aprovada.

Pesado contra: uma terceira via com fluxo próprio. O Off Road não tem artefatos, sinais nem limiares próprios; usa os do Highway. Por isso pode ser ligado no meio de um intent ou de uma spec, e por isso implement e revisão são os mesmos em toda track. Uma spec devolvida a `draft` não o religa, a menos que o usuário peça de novo, e nenhum arquivo o registra, então uma sessão nova precisa do pedido de novo enquanto a spec não for aprovada.

Veja [Off Road](../guides/off-road.md).

## Uma regra de revisão

A revisão do implement corrige todo achado `[blocking]` e todo `[important]` cuja correção cabe nos arquivos da spec, e deixa o resto aberto. A regra é a mesma em toda track. Todo achado é registrado com o destino que teve em `assets/review.md`, e o resumo do ship nomeia cada `[important]` aberto.

Pesado contra: deixar a revisão se comportar de outro jeito conforme a track foi planejada, por exemplo depois de um Off Road. Uma regra única torna o resultado previsível, e o registro o torna visível. O usuário que quer um achado aberto corrigido responde amarelo na parada de ship.

Veja [Validação](../reference/validation.md#revisao-do-implement).

## Sem compatibilidade com o nome antigo

O método foi renomeado. A árvore, o bloco gerenciado, os comandos e os scripts mudaram de nome, e não há migração automática: `ot-init` recusa o projeto que ainda tem a árvore ou o bloco gerenciado antigos, não muda nada e imprime os passos manuais.

Pesado contra: migrar automaticamente. A recusa não grava nada, e o agente não renomeia nem apaga nada sem o usuário pedir, então mover os arquivos do usuário fica com o usuário.

Veja [Migração](../getting-started/migrating.md).

## Crumbs fora do git

Uma crumb mora em `on-track/crumbs/`, que ignora a si mesma com um `.gitignore` contendo `*`. Crumbs ficam fora do git e do índice. Ao preparar commits, o mantenedor ou a ferramenta apaga crumbs consumidas e crumbs cujos arquivos já não diferem de `HEAD`.

Pesado contra: versionar a nota, ou dar uma track à via Express. A crumb não tem id, status nem número, então não usa a numeração de tracks. O bloco gerenciado define os campos e as seções da crumb, então o Express não precisa de skill dedicada. `ot-intent` traz o mesmo procedimento Express quando classifica um pedido nessa via. Campo novo só entra quando a preparação do commit tem um leitor definido para ele.

Veja [Artefatos](../reference/artifacts.md#crumb).
