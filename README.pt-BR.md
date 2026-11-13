# On Track Method

[English](README.md)

O On Track Method é um ciclo de desenvolvimento de software (SDLC) leve que mantém os agentes de código nos trilhos: você define o rumo e responde aos sinais, e o agente documenta, planeja, implementa e valida. O registro é proporcional ao pedido, então o que não precisa de track não ganha track.

## Por Quê

Sem um processo explícito, um pedido vira código antes de alguém definir o que precisa mudar. As decisões se perdem na conversa. A sessão seguinte precisa reconstruir o contexto do zero.

O On Track Method classifica cada pedido antes de tocar em qualquer coisa, registra o problema, o resultado e os limites quando a mudança merece, e só implementa uma mudança completa depois que você aprova a spec e as tarefas. Os artefatos ficam no seu repositório, em Markdown simples, e não só na conversa.

## Como um Pedido Viaja

![Diagrama intitulado "Três Caminhos para um Pedido". Express, usada quando cinco critérios valem, passa por Implementar, Verificar, Crumb e Relatar, sem track e sem sinal. Highway, o padrão, passa por Intent e Spec com perguntas bloqueadoras, depois Implement com gate e revisão, depois Ship, que você confirma, com um sinal depois de cada etapa. Off Road, a pedido, passa por Intent e Spec com as escolhas do agente somadas às perguntas e entra no Highway quando a spec é aprovada. Rodapé: no sinal, ponto segue, x para e qualquer outra resposta revisa a etapa; a via Express deixa um crumb local até o commit; sem commit, push ou deploy automático.](docs/images/pt/lanes.png)

- **Express**: uma edição pequena e reversível que cumpre cinco critérios, como no máximo três arquivos e uma verificação que a confirme. O agente implementa, roda a verificação, deixa uma nota local chamada crumb para o seu commit e relata, sem track e sem parada.
- **Highway**: toda outra edição, e o padrão. O agente escreve um intent, depois uma spec e as tarefas, então implementa e oferece o ship, parando para o seu sinal depois de cada etapa.
- **Off Road**: o acesso consultado ao Highway, para quando você quer tomar mais decisões. As perguntas do intent e da spec também trazem as escolhas que o agente resolveria sozinho, até a spec ser aprovada.

A sua escolha explícita de via sempre vence. Os critérios estão na [referência de classes de pedido](docs/pt/reference/request-classes.md); veja também os guias de [mudanças Express](docs/pt/guides/express-changes.md) e de [Off Road](docs/pt/guides/off-road.md).

## O Highway

![Fluxo numerado intitulado "Você Decide. A IA Implementa.", desenhado como um arco aberto do pedido à entrega. 1, você: Iniciar, descreva o pedido com /ot-intent. 2, agente de IA: Documentar a intenção e os limites em intent.md. 3, você: Revisar, confira a intenção. 4, agente de IA: Planejar a especificação e as tarefas em spec.md e tasks.md com /ot-spec. 5, você: Aprovar, autorize a implementação. 6, agente de IA: Implementar com código, validação e revisão, com /ot-implement. 7, você: Concluir, confira e confirme, e a mudança fica concluída. Um selo indica rodar /ot-init antes de começar. Rodapé: digite ponto para avançar ou escreva outra instrução; revise os artefatos antes de continuar; sem commit, push ou deploy automático.](docs/images/pt/workflow.png)

As imagens usam a chamada do [Claude Code](https://code.claude.com/docs/en/skills): `/ot-intent`. No [Codex](https://developers.openai.com/codex/skills), use `$ot-intent` ou o seletor `/skills`. Nos demais harnesses, você também pode pedir `Use a skill ot-intent para <objetivo>`.

Ao fim de cada etapa do Highway, o agente mostra um resumo de quatro tópicos e os artefatos que escreveu, e espera o seu sinal em texto:

- **Verde**: `.`, ou uma mensagem que signifique apenas avançar, no seu idioma, leva a mesma track à próxima etapa; depois da spec, aprova a spec e as tarefas, e depois da implementação, confirma o ship.
- **Vermelho**: `x`, ou uma mensagem que signifique apenas parar, interrompe sem mudar status, apagar arquivos ou desfazer código, e você retoma pedindo a mesma etapa.
- **Amarelo**: qualquer outra resposta, inclusive ambígua, é uma instrução para a etapa atual, que revisa e mostra o resumo de novo.

O ship marca a track como concluída; ele nunca faz commit, push ou deploy. Leia o [guia de sinais do Highway](docs/pt/guides/highway-signals.md) e a [referência do ciclo](docs/pt/reference/cycle.md) para todas as regras.

## Contexto que Fica no Projeto

![Diagrama intitulado "Contexto que Fica no Projeto.": um agente de IA no centro consulta o índice em on-track/INDEX.md e se liga a cinco artefatos de apoio. Referências, material fornecido por você, registradas durante o fluxo em refs/<slug>.md, sem comando próprio. Avaliações, evidências do estado atual com limitações e recomendações, em assessments/<YYYY-MM-DD>-<slug>.md, por /ot-assess. Pesquisas, fatos externos e fontes, em research/<slug>.md, por /ot-research. Handoff, continuidade entre sessões, agentes e modelos, em handoffs/<timestamp>-<slug>.md, por /ot-handoff. Decisões, o que, por quê e consequências, registradas durante o fluxo em decisions/<NNN-slug>.md, sem comando próprio. Todos os caminhos ficam em on-track/. Rodapé: a memória fica nos arquivos do projeto, não no chat nem no modelo.](docs/images/pt/support-context.png)

Pesquisas, avaliações e handoffs podem ser pedidos a qualquer momento, sem iniciar uma mudança, e referências e decisões são registradas sozinhas durante o fluxo quando se justificam. Os agentes encontram todos eles pelo índice gerado, então a memória fica nos arquivos em vez de depender de o modelo lembrar de conversas anteriores.

| Artefato | O que preserva | Onde fica |
|---|---|---|
| **Referência (`ref`)** | Material fornecido por você, como uma URL, um documento ou um trecho de código externo que fundamenta a mudança. | `on-track/refs/<slug>.md` |
| **Pesquisa (`research`)** | Fatos externos, alternativas e fontes consultadas pelo agente. | `on-track/research/<slug>.md` |
| **Avaliação (`assessment`)** | Evidências sobre o estado atual do que foi avaliado, com limitações e recomendações. | `on-track/assessments/<YYYY-MM-DD>-<slug>.md` |
| **Decisão (ADR)** | O que foi decidido, por quê e quais consequências a escolha traz. | `on-track/decisions/<NNN-slug>.md` |
| **Handoff** | O contexto necessário para continuar em outra sessão, agente ou modelo. | `on-track/handoffs/<timestamp>-<slug>.md` |

Veja o [guia de artefatos de apoio](docs/pt/guides/supporting-artifacts.md) e, para saber quando uma avaliação ou uma ADR se justifica, a [referência de limiares](docs/pt/reference/thresholds.md).

## Começo Rápido

Você precisa de Node.js 22.20 ou superior, `npx`, Git, Bash e um agente de código com suporte a skills.

Na raiz do seu projeto, instale as sete skills:

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

Responder `.` em cada parada leva a track à próxima etapa, então você não precisa chamar cada skill. A [página de instalação](docs/pt/getting-started/installation.md) cobre as opções e o instalador pelo checkout; [Sua primeira track](docs/pt/getting-started/first-track.md) leva um pedido do intent ao ship.

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

## Documentação

| Seção | Comece por |
|---|---|
| Primeiros passos | [Instalação](docs/pt/getting-started/installation.md) |
| Guias | [Mudanças Express](docs/pt/guides/express-changes.md) |
| Referência | [Classes de pedido](docs/pt/reference/request-classes.md) |
| Conceitos | [Por que On Track](docs/pt/concepts/why-on-track.md) |

O sumário completo está na [página inicial da documentação](docs/pt/index.md). Os [evals e seus resultados](evals/evals.md) registram como o pacote é validado com Claude Code, Codex e Kiro.

Vem do `fast-track-ai`? Siga os [passos de migração](docs/pt/getting-started/migrating.md).

## Licença

[MIT](LICENSE).
