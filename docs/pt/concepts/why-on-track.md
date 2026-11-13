---
title: Por que On Track
description: O problema que o On Track Method resolve, o registro proporcional, a divisão entre decisão humana e execução do agente, e a metáfora por trás dos nomes.
---

# Por que On Track

Esta página responde por que o método existe e por que tem esta forma. As regras estão nas páginas de [Referência](../reference/request-classes.md).

## O problema

Um agente de código trabalhando num repositório real costuma errar para um de dois lados.

Ele interroga. Pergunta o que o repositório ou um comando responderia, pergunta sobre escolhas que não mudam o resultado e transforma uma mudança pequena numa reunião.

Ou ele chuta. Decide sozinho escopo, segurança, persistência ou aceite, e o usuário descobre depois que o código já está escrito.

Os registros em volta desse trabalho erram do mesmo jeito. Ou nada fica escrito, e a próxima sessão, agente ou pessoa não sabe por que o código é como é, ou toda mudança gera a mesma pilha de documentos, e a pilha deixa de ser lida.

## Registro proporcional

O On Track Method faz o registro acompanhar o tamanho do pedido. O que não precisa de track não ganha track.

| Pedido | Registro |
|---|---|
| Rodar, compilar, inspecionar, relatar | Nenhum |
| Edição pequena, delimitada e reversível (Express) | Uma crumb local, consumida na hora do commit |
| Qualquer outra edição (Highway) | Uma track: intent, spec, tasks e evidência em `assets/` |
| Pergunta sobre o mundo externo | Um arquivo de research |
| Pedido de só avaliação, ou mudança cujo escopo ou desenho passa no limiar de assessment | Um arquivo de assessment |

Os registros de apoio seguem a mesma ideia. Um assessment auxiliar é escrito quando uma mudança passa no limiar de assessment; um pedido direto de avaliação não exige track. Uma ADR só é escrita para escolha real que custa caro errar. `ot-handoff` registra contexto ao trocar de harness ou modelo, encerrar sessão ou atender pedido de handoff. Os limiares estão em [Limiares](../reference/thresholds.md).

## O humano decide, o agente executa

O humano define o rumo e responde os sinais. O agente documenta, planeja, implementa e valida entre eles.

Essa divisão aparece em três lugares:

- **Perguntas.** O agente investiga primeiro e faz só perguntas bloqueadoras, aquelas cuja resposta muda escopo, segurança, persistência, integração externa, arquitetura ou aceite, com a recomendação dele primeiro. O usuário pode delegar qualquer pergunta com "decida você", e toda decisão delegada volta no resumo para veto. Quando o usuário quer mais voz, o Off Road também leva a ele as escolhas do próprio agente, até a spec ser aprovada.
- **Sinais.** Cada etapa do Highway termina numa parada em que o usuário responde em texto: siga, ajuste ou pare. Nada é aprovado por silêncio nem por verificação que passou. Veja [Sinais](../reference/signals.md).
- **Commits.** O método nunca faz commit. O commit é do mantenedor.

O agente classifica o pedido, grava os artefatos, roda as verificações e registra a evidência. A revisão corrige todo achado `[blocking]` e cada `[important]` cuja correção cabe nos `Files:` da spec; os demais ficam abertos.

## A metáfora

O nome diz para que serve o método: manter o trabalho do agente nos trilhos, com o humano segurando o rumo.

O vocabulário segue uma estrada:

- **Express** é a faixa curta para a mudança que não precisa de paradas.
- **Highway** é a estrada principal por onde passa toda outra mudança, com três paradas até o ship.
- **Off Road** é o acesso consultado ao Highway, para pedido que depende de mais decisões do usuário. Ele volta ao Highway quando a spec é aprovada.
- **Sinais** são verde, amarelo e vermelho, como um semáforo.
- **Crumbs** são a trilha que uma mudança Express deixa para o commit achar o caminho de volta.

Os motivos por trás de cada uma dessas escolhas estão em [Escolhas de desenho](design-choices.md).
