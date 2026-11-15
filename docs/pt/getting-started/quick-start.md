---
title: Começo rápido
description: Instale o On Track Method, inicialize um projeto e veja em três diagramas como um pedido viaja, o que você decide e o que fica no repositório.
---

# Começo rápido

Esta página põe o On Track Method para rodar num projeto e mostra o método inteiro em três diagramas. Cada seção aponta para a página com as regras completas.

## Instalar e começar

Você precisa de Node.js 22.20 ou superior, `npx`, Git, Bash e um agente de código com suporte a skills.

Na raiz do seu projeto, instale as oito skills:

```bash
npx skills add jotafurtado/on-track --skill '*'
```

Abra o agente no mesmo projeto e inicialize o método:

```text
/ot-init
```

Isso cria a pasta `on-track/`, o índice dos artefatos e o bloco gerenciado no `AGENTS.md`. Rodar de novo não duplica nada.

Depois, inicie uma mudança com um pedido concreto:

```text
/ot-intent Adicione recuperação de senha por e-mail.
Não altere o login social.
```

Responder `.` em cada parada leva a track à próxima etapa, então você não precisa chamar cada skill. A [Instalação](installation.md) cobre as opções e o instalador pelo checkout; [Sua primeira track](first-track.md) leva um pedido do intent ao ship.

Os exemplos usam a chamada do Claude Code, `/ot-intent`. No Codex, use `$ot-intent` ou o seletor `/skills`. Nos demais harnesses, peça `Use a skill ot-intent para <objetivo>`.

## Como um pedido viaja

![Diagrama intitulado "Três Caminhos para um Pedido". Express, o caminho mais rápido, passa por Implementar, Verificar, Crumb e Relatar, sem paradas. Highway, o padrão, passa por Intent, Spec, Implementar e Chegada, com um sinal seu depois de cada etapa. Off Road, para terreno sem mapa, passa por Intent e Spec com mais perguntas e entra na Highway quando a Spec é aprovada. Rodapé: no sinal, ponto segue, x para e qualquer outra resposta revisa a etapa.](../../images/pt/lanes.png)

- **Express**: uma edição pequena e reversível que cumpre cinco critérios, como no máximo três edições distintas e uma verificação que a confirme. O agente implementa, roda a verificação, deixa uma nota local chamada crumb para o seu commit e relata, sem track e sem parada.
- **Highway**: toda outra edição, e o padrão. O agente escreve um intent, depois uma spec e as tarefas, então implementa e oferece o ship (a entrega, que marca a track como concluída), parando para o seu sinal depois de cada etapa.
- **Off Road**: o acesso consultado ao Highway, para terreno que você ainda não conhece. As perguntas do intent e da spec também trazem as escolhas de design que o agente resolveria sozinho, até a spec ser aprovada.

A sua escolha explícita de via sempre vence. Os critérios estão em [Classes de pedido](../reference/request-classes.md).

## O Highway

![Fluxo numerado intitulado "Você Decide. A IA Implementa.". 1, você: descreva o pedido com /ot-intent. 2, agente: documenta a intenção e os limites em intent.md. 3, você: revisa o intent. 4, agente: planeja spec.md e tasks.md com /ot-spec. 5, você: aprova. 6, agente: implementa com validação e revisão, com /ot-implement. 7, você: confirma, e a mudança fica concluída.](../../images/pt/workflow.png)

Ao fim de cada etapa do Highway, o agente mostra um resumo de quatro tópicos e os artefatos que escreveu, e espera o seu sinal em texto:

- **Verde**: `.`, ou uma mensagem que signifique apenas avançar, leva a mesma track à próxima etapa.
- **Vermelho**: `x`, ou uma mensagem que signifique apenas parar, interrompe sem mudar status, apagar arquivos ou desfazer código.
- **Amarelo**: qualquer outra resposta é uma instrução para a etapa atual, que revisa e mostra o resumo de novo.

O ship marca a track como concluída; ele nunca faz commit, push ou deploy. Veja [Sinais do Highway](../guides/highway-signals.md).

## Contexto que fica no projeto

![Diagrama intitulado "Contexto que Fica no Projeto.": um agente de IA consulta o índice em on-track/INDEX.md e se liga a cinco artefatos de apoio: referências, avaliações, pesquisas, handoffs e decisões, todos em on-track/.](../../images/pt/support-context.png)

| Artefato | O que preserva | Onde fica |
|---|---|---|
| **Referência (`ref`)** | Material fornecido por você, como uma URL, um documento ou um trecho de código externo que fundamenta a mudança. | `on-track/refs/<slug>.md` |
| **Pesquisa (`research`)** | Fatos externos, alternativas e fontes consultadas pelo agente. | `on-track/research/<slug>.md` |
| **Avaliação (`assessment`)** | Evidências sobre o estado atual do que foi avaliado, com limitações e recomendações. | `on-track/assessments/<YYYY-MM-DD>-<slug>.md` |
| **Decisão (ADR)** | O que foi decidido, por quê e quais consequências a escolha traz. | `on-track/decisions/<NNN-slug>.md` |
| **Handoff** | O contexto necessário para continuar em outra sessão, agente ou modelo. | `on-track/handoffs/<timestamp>-<slug>.md` |

Pesquisas, avaliações e handoffs podem ser pedidos a qualquer momento, sem iniciar uma mudança. Veja [Artefatos de apoio](../guides/supporting-artifacts.md).

## Comandos

| Grupo | Comando | Quando usar |
|---|---|---|
| **Preparação** | `/ot-init` | Ao adotar o método em um projeto. Prepara a estrutura e o índice. |
| **Desenvolvimento, nesta ordem** | `/ot-intent` | Inicia uma mudança no Highway: registra problema, resultado esperado, escopo e limites. |
| | `/ot-spec` | Depois do intent: escreve a spec e as tarefas para sua revisão e aprovação. |
| | `/ot-implement` | Depois do plano aprovado: implementa as tarefas, valida os resultados e revisa a entrega. |
| **Apoio, a qualquer momento** | `/ot-research` | Pesquisa fatos externos, documentação ou alternativas com fontes rastreáveis. |
| | `/ot-assess` | Avalia o que já existe, com evidências, limitações e recomendações. |
| | `/ot-handoff` | Registra o contexto para continuar em outra sessão, agente ou modelo. |
| | `/ot-doctor` | Verifica o projeto depois de atualizar o pacote e o corrige com a sua confirmação. |

Todos os comandos estão descritos em [Comandos](../reference/commands.md).
