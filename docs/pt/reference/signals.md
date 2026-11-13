---
title: Sinais
description: "Verde, amarelo e vermelho em cada parada do Highway: os tokens, as mensagens que valem e o efeito em status e arquivos."
---

# Sinais

Esta página responde o que cada resposta faz em cada parada do Highway. As etapas de intent, spec e implement terminam com um resumo de quatro tópicos e uma linha de próximo passo, e param à espera do sinal do usuário. O sinal é texto. A ferramenta de perguntas do host fica para perguntas, não para sinais.

## Como uma resposta é lida

| Sinal | Token canônico | Também vale | Significado |
|---|---|---|---|
| Verde | `.` | Mensagem que só quer dizer siga, no idioma do usuário, como `go`, `yes`, `continue`, `sim`, `verde` | Siga: encadeia a próxima skill da mesma track sem pedir comando |
| Vermelho | `x` | Mensagem que só quer dizer pare, como `stop`, `red`, `pare`, `vermelho` | Pare |
| Amarelo | Nenhum | Qualquer outra mensagem, inclusive a ambígua | Vale como instrução para a skill atual, que depois mostra o resumo de novo |

As palavras listadas são exemplos, não uma lista fechada: vale o significado da mensagem. Uma mensagem que mistura aprovação com mudança, como "sim, mas renomeia a fase 2", é amarela.

## Depois do intent

Linha de próximo passo: `. para continuar com a spec`.

| Sinal | Efeito no status | Efeito nos arquivos | O que acontece depois |
|---|---|---|---|
| Verde | Nenhum. O intent fica em `draft` | Nenhum | `ot-spec` começa para a mesma track |
| Vermelho | Nenhum | Nada é apagado | O agente para. A track continua válida em `draft` e é retomada quando o usuário pede a etapa de intent de novo |
| Amarelo | Nenhum | `intent.md` revisado conforme a instrução e índice regenerado | O agente relata qualquer erro de validação do índice; senão, mostra o resumo do intent de novo |

## Depois da spec

Linha de próximo passo: `. para implementar`.

| Sinal | Efeito no status | Efeito nos arquivos | O que acontece depois |
|---|---|---|---|
| Verde | `spec.md` e `tasks.md` passam a `status: approved`. O status do intent não muda | Só a gravação da aprovação, concluída antes de qualquer edição do produto | `ot-implement` começa para a mesma track |
| Vermelho | Nenhum. `spec.md` e `tasks.md` ficam em `draft` | Nada é apagado | O agente para. A track é retomada quando o usuário pede a etapa de spec de novo |
| Amarelo | Nenhum | `spec.md` ou `tasks.md` revisados conforme a instrução, índice regenerado, gate de estrutura rodado de novo | O agente mostra o resumo da spec de novo |

A aprovação cobre exatamente a versão apresentada. Uma mudança material posterior devolve os dois arquivos a `draft`; veja [Ciclo](cycle.md#aprovacao-e-mudancas-materiais).

## Depois do implement

Linha de próximo passo: `. para ship (marca a track como concluida)`. Ela só aparece quando toda linha de aceite está `met` e não resta achado `[blocking]` da revisão.

| Sinal | Efeito no status | Efeito nos arquivos | O que acontece depois |
|---|---|---|---|
| Verde | O intent passa a `status: shipped` | Índice regenerado | A track está concluída |
| Vermelho | Nenhum. O `status` do intent fica como está | O código implementado fica. Nada é desfeito | O agente para. O ship continua disponível quando o usuário pedir de novo |
| Amarelo | Nenhum | O agente corrige ou revisa conforme a instrução antes do ship | O agente mostra o resumo do implement de novo |

Para mandar corrigir um achado aberto da revisão, responda amarelo nesta parada. Não há outra parada no ciclo para isso.

## O que o vermelho nunca faz

O vermelho para sem mudar `status` algum, não apaga nada e não desfaz código. Nunca marca a track como `dropped`; abandonar uma track é decisão separada, declarada pelo mantenedor. Veja [Ciclo](cycle.md#abandonar-ou-substituir-uma-track).

## Vias sem sinal

A via Express não tem sinal: o relato encerra o trabalho. Pedidos operacionais, de só pesquisa e de só avaliação também não têm sinal; uma chamada direta de `ot-research` ou `ot-assess` relata o resultado, o caminho e o resultado do índice sem linha `.`.
