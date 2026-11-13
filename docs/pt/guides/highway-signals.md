---
title: Sinais do Highway
description: O que responder em cada parada do Highway e o que cada resposta faz.
---

# Sinais do Highway

Esta página responde o que dizer em cada uma das três paradas do Highway, o que verde, amarelo e vermelho fazem em cada uma, como uma track parada é retomada e como funciona a aprovação da spec.

## As três paradas

No Highway, as etapas de intent, spec e implement terminam do mesmo jeito: um resumo de quatro tópicos, uma linha de próximo passo e uma parada. O agente então espera o seu sinal, lido como texto simples.

| Parada | Quatro tópicos | Linha de próximo passo |
|---|---|---|
| Depois do intent | Problema, resultado proposto, escopo, restrições | `. para continuar com a spec` |
| Depois da spec | Resultado, fases, quantidade de tarefas, grupos paralelos | `. para implementar` |
| Depois do implement | Tarefas concluídas, aceitação, resultado da revisão, resultado do gate | `. para ship (marca a track como concluida)` |

O agente mostra as linhas de próximo passo exatamente como estão no pacote.

O sinal é texto. O agente reserva a ferramenta de perguntas do host para perguntas e nunca transforma uma parada em diálogo.

## Os três sinais

| Sinal | Você digita | Significado |
|---|---|---|
| Verde | `.`, ou uma mensagem que só signifique avançar, no seu idioma (`go`, `yes`, `continue`, `sim`, `verde`) | Siga para a próxima etapa da mesma track. |
| Amarelo | Qualquer outra mensagem, inclusive ambígua | Uma instrução para a etapa atual. |
| Vermelho | `x`, ou uma mensagem que só signifique parar (`stop`, `red`, `pare`, `vermelho`) | Pare aqui. |

Verde e vermelho são lidos pelo sentido, não por uma lista fechada de palavras. Uma mensagem que mistura um sim com uma mudança, como "sim, mas renomeie a fase 2", é amarela: a etapa revisa e não avança.

## O que cada sinal faz em cada parada

| Parada | Verde | Amarelo | Vermelho |
|---|---|---|---|
| Depois do intent | Executa a etapa de spec da mesma track. O `status` do intent continua `draft`. | Revisa o intent, regenera o índice, mostra o resumo de novo. | Para. Não muda nenhum `status`, não apaga nada. |
| Depois da spec | Grava `status: approved` em `spec.md` e `tasks.md` e executa o implement. | Revisa a spec ou as tarefas, regenera o índice, roda de novo o gate de estrutura, mostra o resumo de novo. | Para. `spec.md` e `tasks.md` ficam em `draft`, nada é apagado. |
| Depois do implement | Grava `status: shipped` no intent e regenera o índice. | Corrige ou revisa conforme a instrução e mostra o resumo de novo. | Para. O `status` do intent não muda e o código implementado fica. |

O verde nunca muda o `status` do intent antes do ship. O intent fica em `draft` desde a criação até a etapa de implement gravar `shipped`; aprovar o intent não é um passo e não é exigido antes da spec.

Na parada do implement, a linha de ship só aparece quando toda linha de aceitação está `met` e não resta achado `[blocking]` da revisão. Se uma linha estiver `pending`, o agente relata e continua corrigindo ou pergunta como seguir. Use uma resposta amarela nessa parada para pedir a correção de um achado aberto da revisão; não existe parada separada para isso.

## Vermelho e retomada

O vermelho para sem efeitos colaterais: nenhum `status` muda, nenhum arquivo é apagado e nenhum código é desfeito. Ele não marca a track como `dropped`. A track continua válida em `draft` e aparece no índice com a fase atual.

Para retomar, peça a mesma etapa de novo na mesma track, por exemplo:

```text
Continue a spec da 001-lp-v2.
```

Depois de um vermelho na parada do implement, o ship continua disponível: peça e o agente apresenta o resumo de novo.

Abandonar uma track é outra decisão, explícita. Quando você diz que vai abandoná-la, o agente grava `status: dropped` no intent. Quando você a substitui por outra track e nomeia essa track, o agente grava `status: superseded` com `superseded_by`; ele nunca inventa a substituta. Veja [Ciclo](../reference/cycle.md).

## Como funciona a aprovação

A aprovação acontece em um só lugar: o verde depois do resumo da spec.

- O agente grava `status: approved` em `spec.md` e `tasks.md` como ação exclusiva de aprovação, concluída antes de qualquer edição de produto. Ele pode atualizar os dois arquivos juntos, mas nunca mistura a aprovação com edições de produto.
- O seu verde cobre exatamente o conteúdo de `spec.md` e `tasks.md` que foi apresentado.
- A implementação exige os dois arquivos aprovados. Sem isso, a skill de implement se recusa a começar.

## Uma mudança material depois da aprovação

Depois da aprovação, uma mudança material em qualquer um dos arquivos devolve `spec.md` e `tasks.md` a `status: draft`, e a implementação precisa de um novo resumo da spec e de um novo verde para continuar. Material é uma mudança de escopo, de `Files`, de critérios `Accept`, de tarefas ou de dependências entre grupos.

Não contam como mudança material: marcar caixas de tarefas e as escritas administrativas que a etapa de implement faz (arquivos em `assets/` da track, o índice, novas ADRs).

Uma mudança material no planejamento aprovado exige nova aprovação. Quando você toma uma decisão qualificada para ADR durante a implementação, o agente registra a ADR. Se ela conflita com a spec ou as tarefas aprovadas ou as muda materialmente, o agente para, devolve os dois arquivos a `draft`, concilia a ADR e os dois artefatos de planejamento e apresenta um novo resumo da spec terminando em `. para implementar`. Se ela não muda materialmente o escopo ou o desenho aprovado, o agente registra a ADR e continua.
