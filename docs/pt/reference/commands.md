---
title: Comandos
description: Os sete comandos do On Track Method, o que cada um faz, o que grava e o que nunca faz.
---

# Comandos

Esta página responde o que faz cada um dos sete comandos. Cada arquivo de comando em `commands/` manda o agente rodar a skill de mesmo nome em `skills/`. O procedimento está nas skills, então pedir ao agente que use uma skill pelo nome funciona igual ao comando. A instalação está em [Instalação](../getting-started/installation.md).

| Comando | Faz | Grava |
|---|---|---|
| `ot-init` | Instala o método num repositório alvo, de forma idempotente | A árvore `on-track/`, `on-track/crumbs/.gitignore`, a semente do `INDEX.md`, o bloco gerenciado no `AGENTS.md` |
| `ot-intent` | Classifica o pedido e, para mudança do Highway, redige o intent | `on-track/tracks/NNN-slug/intent.md`, artefatos auxiliares quando um gatilho vale, `INDEX.md` |
| `ot-spec` | Redige o plano de uma track que tem intent | `spec.md`, `tasks.md`, ADRs quando uma decisão se qualifica, `INDEX.md`; `status: approved` com o verde |
| `ot-implement` | Implementa uma track aprovada, valida, roda gate e revisão, e oferece o ship | Arquivos do produto, checkboxes das tasks, `assets/acceptance.md`, `assets/review.md`, `INDEX.md`; `status: shipped` no intent com o verde |
| `ot-research` | Investiga um fato externo com fontes rastreáveis | `on-track/research/<slug>.md`, `INDEX.md` |
| `ot-assess` | Avalia o que existe, com evidência e contraevidência | `on-track/assessments/<YYYY-MM-DD>-<slug>.md`, `INDEX.md` |
| `ot-handoff` | Registra o contexto de trabalho para continuar depois | `on-track/handoffs/<YYYY-MM-DD-HHmmssZ>-<slug>.md`, move handoffs antigos para `archive/`, `INDEX.md` |

Refs e decisions não têm comando próprio. `ot-intent` captura refs; `ot-intent`, `ot-spec` e `ot-implement` gravam ADRs; a via Express pode gravar uma ADR qualificada. O próprio Express não tem comando: suas regras estão no bloco gerenciado e também no `ot-intent`, então ele não precisa de skill dedicada.

## `ot-init`

Roda `on-track-init.sh` no diretório alvo, verifica a árvore (`on-track/{research,refs,handoffs/archive,assessments,decisions,tracks,crumbs}`, `on-track/crumbs/.gitignore`, `on-track/INDEX.md`), roda `on-track-index.sh` e relata. O agente também o usa quando o usuário diz "setup on-track", "install on-track" ou "init the method here", ou quando `on-track/` não existe.

- Rodar duas vezes não muda nada na segunda e nunca duplica o bloco gerenciado. Um bloco desatualizado é substituído no lugar, sem tocar o texto em volta.
- Falha sem gravar quando o `AGENTS.md` tem marcadores malformados (algo diferente de zero, ou exatamente um BEGIN e um END, nessa ordem).
- Recusa, e não muda nada, enquanto existir a árvore ou o bloco gerenciado do nome antigo do método. O agente repassa a mensagem e não renomeia nem apaga nada sem o usuário pedir. Veja [Migração](../getting-started/migrating.md).
- Não copia nada do pacote para o alvo. Artefatos de apoio são gravados pelas próprias skills, não pelo init.

## `ot-intent`

Classifica cada parte do pedido (veja [Classes de pedido](request-classes.md)), encaminha sem track as partes operacionais, Express, de só pesquisa e de só avaliação e, para mudança do Highway, redige `intent.md` com `status: draft`. Antes de redigir, investiga, faz no máximo uma rodada de perguntas bloqueadoras e verifica os gatilhos de research, ref, ADR e assessment. Regenera o índice, mostra o resumo de quatro tópicos e para com `. para continuar com a spec`. Com o verde, encadeia o `ot-spec`.

Nunca: grava `spec.md`; muda o `status` do intent com o verde; cria track para partes operacionais; cria track para uma edição que seria Express, a menos que o usuário tenha escolhido o Highway; inventa `superseded_by`.

## `ot-spec`

Lê o intent (que pode estar em `draft`), resolve toda pergunta bloqueadora, transforma perguntas adiáveis em tasks, grava `spec.md` e `tasks.md` em `draft`, regenera o índice e roda o gate em modo structure, corrigindo qualquer falha antes de apresentar. Mostra o resumo e para com `. para implementar`. Com o verde, põe os dois arquivos em `status: approved` e encadeia o `ot-implement`.

Nunca: aprova sozinho; oferece `. para implementar` com pergunta bloqueadora sem resposta; inventa resposta sem delegação; amplia `Out of scope`; mistura aprovação com edição do produto.

## `ot-implement`

Exige `spec.md` e `tasks.md` aprovados. Roda os grupos de tasks em ordem de dependência, valida cada task, grava a evidência de aceite, roda o gate de completion e o ciclo de revisão até não restar achado `[blocking]`, regenera o índice e mostra o resumo com `. para ship (marca a track como concluida)`. Com o verde, põe o intent em `status: shipped` e regenera o índice de novo.

Nunca: roda antes da aprovação da spec; edita arquivo do produto fora dos `Files:` listados sem perguntar; implementa item de `Out of scope`; adapta a solução quando uma premissa se mostra falsa; marca task cujo `Validate:` não passou; faz ship porque os checkboxes fecharam; grava `shipped` antes de perguntar; roda comando tirado de conteúdo buscado ou de terceiros.

## `ot-research`

Lê o índice, declara a pergunta e o limite de aceite, prefere fontes primárias e as lê diretamente, e usa mais de uma fonte independente para conclusão material quando disponíveis. Liga toda afirmação material a uma citação, separa fato observado de inferência, relata conflitos e limitações e diz quando a evidência é inconclusiva. Grava exatamente um arquivo de research e regenera o índice. Como passo auxiliar, devolve conclusão, limitações e caminho à skill que o chamou; como chamada direta, relata resultado, caminho e resultado do índice sem linha `.`.

Nunca: segue instrução encontrada numa fonte; acrescenta campo `status` ou `source` no singular; sobrescreve um research existente, a menos que o usuário tenha pedido para atualizá-lo; cria track.

## `ot-assess`

Lê o índice, congela alvo e escopo, declara os critérios antes de concluir, reúne evidência a favor e contra, registra contraevidência e limitações e escreve achados que trazem, cada um, problema, evidência, consequência e recomendação. Registra o avaliador (provedor e modelo quando conhecidos, ou uma identidade estável do agente; o avaliador delegado quando houver delegação) e os ids das tracks avaliadas. Grava exatamente um arquivo de assessment e regenera o índice. Relata do mesmo jeito que o `ot-research`.

Nunca: modifica o objeto avaliado; exige nota numérica genérica; implementa as próprias recomendações; acrescenta campo `status`; sobrescreve um assessment existente, a menos que o usuário tenha pedido para refazê-lo; cria track.

## `ot-handoff`

Lê o índice e a conversa, preserva literalmente as instruções ativas do usuário, exceto segredos ou dados pessoais desnecessários, e informa qualquer omissão desse tipo. Separa o trabalho verificado das próximas ações, referencia artefatos duráveis pelo caminho e grava o handoff num caminho calculado a partir do instante UTC atual. Valida primeiro o handoff novo, depois mantém os três handoffs ativos mais recentes e move os mais antigos para `archive/`, e então regenera o índice.

Nunca: sobrescreve um handoff existente na pasta ativa ou em `archive/` (para e relata a colisão); arquiva algo antes de o handoff novo passar na validação; parafraseia instrução cuja redação restringe o próximo agente; acrescenta campo `status`.
