# Guia técnico do fast-track-ai

Para instalar e começar, veja o [README](../README.md). Este guia preserva os fluxos detalhados e explica os artefatos, as aprovações e as validações do método.

O [fluxo principal em PNG](images/workflow.png) tem uma [fonte vetorial editável](images/workflow.svg), assim como a [arte dos artefatos de apoio](images/support-context.png), com sua [fonte em SVG](images/support-context.svg). Os diagramas abaixo continuam em Mermaid para detalhar os caminhos que não precisam aparecer no início rápido.

Método leve de SDLC para agente. Um pedido de mudança vira track. A track só vira código depois de `spec.md` e `tasks.md` com `status: approved`.

Você avança o ciclo respondendo `.` no fim de cada resumo. Outra frase corrige a etapa atual e o agente mostra o resumo de novo.

## Instalar o pacote

### Instalação com npx skills

Na raiz do projeto consumidor:

```bash
npx skills add jotafurtado/fast-track-ai --skill '*'
```

O CLI permite selecionar os agentes e instala as sete skills no projeto por padrão. Use `--global` para instalação no usuário ou `--agent claude-code`, `--agent codex` ou `--agent kiro-cli` para selecionar explicitamente um dos agentes validados. A documentação do [skills CLI](https://github.com/vercel-labs/skills#install-a-skill) detalha os escopos e as opções.

Instale o conjunto completo: scripts e templates têm uma skill dona, e as demais resolvem esses recursos por caminhos relativos entre skills irmãs. Uma instalação parcial pode deixar dependências ausentes.

Essa instalação exige Node.js 22.20 ou superior e `npx`, além de Git. Os scripts do método usam Bash. Ela instala as skills, não os wrappers do diretório `commands/`; peça ao agente `Use a skill ft-init neste repositório` e, depois, `Use a skill ft-intent para <objetivo>`.

### Instalação manual do checkout

Para desenvolver o pacote ou manter links para um checkout local, execute na raiz deste repositório:

```bash
./install.sh
```

O script é idempotente. Rode de novo: os links são refeitos, sem bloco duplicado.

| Destino | Padrão |
|---|---|
| Skills do harness | `~/.agents/skills` |
| Espelho Claude | `~/.claude/skills` |
| Comandos | `~/.claude/commands` |

Flags: `--agents-dir`, `--claude-dir`, `--commands-dir`. Se você passar só `--claude-dir`, os comandos vão para `commands/` irmão dessa pasta de skills.

Para manter a instalação padrão e disponibilizar as mesmas skills ao Kiro, execute também `./install.sh --agents-dir "$HOME/.kiro/skills"`. Esse diretório recebe links para o mesmo pacote; não é uma cópia independente. O espelho Claude é atualizado quando `~/.claude/` existe. Os wrappers de comandos são instalados em `~/.claude/commands` por padrão.

Cada `commands/ft-*.md` manda o agente executar a skill de mesmo nome em `skills/`.

## Começar num repositório

Diga ao agente: `setup fast-track-ai`, `install fast-track-ai` ou `init the method here`. A skill `ft-init` também dispara quando a pasta `fast-track-ai/` não existe.

O script `skills/ft-init/scripts/fast-track-ai-init.sh` cria a árvore e o bloco gerenciado em `AGENTS.md`. Em seguida `fast-track-ai-index.sh` gera `fast-track-ai/INDEX.md`.

Leia o `INDEX.md` antes de procurar track, ref, research, assessment, decision ou handoff. Ele é gerado. Edição manual se perde na próxima geração.

A tabela de tracks traz `track`, `status` e `phase`: `intent` indica que ainda não há arquivos regulares `spec.md` nem `tasks.md`; `spec` indica que só um existe ou que algum ainda não está aprovado; `implement N/M` indica ambos aprovados, com N tarefas marcadas entre M tarefas. Tracks `shipped`, `dropped` ou `superseded` mostram `-`; entradas ausentes ou malformadas nos arquivos de fase não fazem a geração do índice falhar.

## Ciclo de uma mudança

```mermaid
sequenceDiagram
  actor Voce
  participant Intent
  participant Spec
  participant Implement
  Voce->>Intent: pedido de mudanca
  Intent-->>Voce: 4 bullets e . para continuar com a spec
  Voce->>Spec: .
  Note over Spec: intent permanece draft
  Spec-->>Voce: 4 bullets e . para implementar
  Voce->>Implement: .
  Note over Spec,Implement: spec.md e tasks.md passam a approved
  Implement-->>Voce: tarefas, testes, review, gate e . para ship
  Voce->>Implement: .
  Note over Implement: intent passa a shipped e o INDEX regenera
```

1. Diga o problema, o resultado e o limite. O agente grava `fast-track-ai/tracks/NNN-slug/intent.md` com `status: draft`. Pedido vago: até 3 perguntas, cada uma dizendo o que destrava.
2. Leia os 4 bullets (problema, resultado, escopo, limites). Responda `.` para a spec, ou escreva a correção.
3. A spec grava `spec.md` (Outcome e Phases) e `tasks.md` (grupos paralelos). Os dois nascem `draft`. Pergunta aberta do intent vira trabalho na fase e na task. O agente não inventa a resposta.
4. Leia os 4 bullets (outcome, fases, quantidade de tasks, grupos). Responda `.`. Só então os dois arquivos passam a `approved` e a implementação começa.
5. A implementação lê os grupos, roda tasks do mesmo grupo em paralelo, executa o `Validate` de cada task e, no fim, o gate e a review.
6. Leia os 4 bullets (tasks, testes, review, gate). Responda `.` para `shipped`. Checkbox marcado não shipa.

O `.` depois do intent e depois da spec mantém o intent em `draft`. `shipped` só entra no passo 6.

## O que responder

```mermaid
flowchart TD
  resumo["Resumo de 4 bullets"] --> escolha{"Sua resposta"}
  escolha -->|". sim pode continuar yes continue"| proxima["Proxima skill da mesma track"]
  escolha -->|"qualquer outra frase"| revisao["A skill atual revisa e mostra o resumo de novo"]
  proxima --> intentFim["Depois do intent: spec"]
  proxima --> specFim["Depois da spec: approved e implement"]
  proxima --> implFim["Depois do implement: intent shipped"]
```

Frases literais do protocolo:

- `. para continuar com a spec`
- `. para implementar`
- `. para ship (marca a track como concluida)`

Sinônimos do ponto: `sim`, `pode continuar`, `yes`, `continue`.

## Pedido sem código

```mermaid
flowchart TD
  pedido["Pedido"] --> tipo{"O que voce quer"}
  tipo -->|"mudanca no sistema"| ciclo["Ciclo intent spec implement"]
  tipo -->|"pesquise ou investigue"| research["fast-track-ai/research/slug.md"]
  tipo -->|"avalie ou audite"| assess["fast-track-ai/assessments/data-slug.md"]
  tipo -->|"handoff compact ou retomar depois"| handoff["fast-track-ai/handoffs/timestamp-slug.md"]
  research --> pare["Artefato mais INDEX. Sem spec."]
  assess --> pare
  handoff --> pare
```

Comando explícito de research, assess ou handoff para no artefato e no index. Não cria track.

Se o pedido entrar pela skill de intent e for só investigação ou avaliação, ele é roteado para research ou assess sem criar track.

## Artefatos que entram sozinhos

Durante o intent o agente avisa em uma frase e grava, sem pedir licença:

```mermaid
flowchart LR
  intent["Intent"] --> tech["Tecnologia ou API incerta"]
  intent --> fonte["URL documento ou trecho seu"]
  intent --> escolha["Decisao duravel ou dificil de reverter"]
  intent --> estado["Avaliacao do que ja existe"]
  tech --> research["research/slug.md"]
  fonte --> ref["refs/slug.md"]
  escolha --> adr["decisions/NNN-slug.md"]
  estado --> assess["assessments/data-slug.md"]
```

| Artefato | Caminho | Papel |
|---|---|---|
| Ref | `fast-track-ai/refs/<slug>.md` | Fonte usada como insumo. `inline` ou `pointer`. Hash igual reusa o slug. Bytes novos exigem ref novo. |
| Research | `fast-track-ai/research/<slug>.md` | Fato externo, com fontes, conflitos e limites. Sem `status`. |
| Assessment | `fast-track-ai/assessments/<YYYY-MM-DD>-<slug>.md` | Avaliação para dentro do projeto, com evidência e contraevidência. Sem `status`. |
| Decision | `fast-track-ai/decisions/<NNN-slug>.md` | Escolha aceita. Só `accepted` ou `superseded`. |
| Handoff | `fast-track-ai/handoffs/<YYYY-MM-DD-HHmmssZ>-<slug>.md` | Contexto para outra sessão. Os 3 mais novos ficam ativos. O resto vai para `handoffs/archive/`. |

No intent, cite o slug em `research:`, `refs:`, `assessments:` ou `decisions:`. Assessment não entra em `research:`.

Ref e decision não têm comando próprio. Research, assess e handoff têm.

## Grupos de tarefas

```mermaid
flowchart LR
  subgraph A["Group A"]
    T1["Task 1"]
    T2["Task 2"]
  end
  subgraph B["Group B depends A"]
    T3["Task 3"]
  end
  A --> B
```

O `tasks.md` exige ao menos um header `## Group`. Tasks do mesmo grupo rodam juntas. Cada uma tem `Files` e `Validate`. Arquivos disjuntos, sem dependência de dados.

Grupo seguinte declara `(depends: Nome)` no título e espera o anterior. Na dúvida, o agente separa em grupos sequenciais. O mesmo arquivo não é editado em paralelo.

A implementação toca só os arquivos listados na spec e na task. Item em `Out of scope` fica de fora. O `Assumed state` do intent separa três listas: `Stated by the user` são fatos que você afirmou e o executor toma como dados; `Unverified assumptions` são premissas que o agente adotou sem checar e que ele verifica antes de uma task depender delas; `Access limits` são fontes que o agente não alcançou. Se faltar arquivo na lista, o agente para e pergunta.

## Status

```mermaid
stateDiagram-v2
  [*] --> draft
  draft --> shipped: ponto no resumo de implementacao
  draft --> dropped: mantenedor abandona
  draft --> superseded: mantenedor nomeia superseded_by
```

Isso é o `status` do `intent.md`. `spec.md` e `tasks.md` usam `draft` e depois `approved` no ponto da spec.

`dropped` encerra sem implementação. `superseded` exige `superseded_by` dito por você. O agente não inventa esse campo.

## Gate

Script: `skills/ft-spec/scripts/fast-track-ai-gate.sh --track NNN-slug --root <repo>`.

Na spec, o gate é checagem interna. `draft` e task aberta não aparecem como falha para você.

Depois da implementação, `PASS` exige:

1. `intent.md` com `id`.
2. `spec.md` e `tasks.md` com `status: approved`.
3. `Files:` e `Accept:` na spec. `Files:` e `Validate:` nas tasks.
4. Nenhuma task `- [ ]`.
5. Sem arquivo solto na raiz da track.

Raiz da track: `intent.md`, `spec.md`, `tasks.md` e `assets/`. Saída auxiliar vai em `assets/`.

A review olha o diff contra a spec. Severidade: `[blocking]` corrige antes de seguir, `[important]` deve corrigir, `[nit]` é opcional, `[suggestion]` é alternativa.

## Árvore deste repositório

```text
commands/                 wrappers dos 7 comandos
skills/ft-*/   skill, template e script de cada comando
install.sh                links no harness
evals/                    suite de evals do mantenedor
.archive/                 histórico e propostas descartadas, somente locais e ignorados pelo Git
```

Cada script e cada template tem uma skill dona. Outra skill aponta para a cópia da dona. Não existe pasta `shared`.

## Validação

A suíte determinística verifica instalação, recursos e scripts em projetos descartáveis, sem chamar modelos:

```bash
bash evals/run-evals.sh all
```

As sessões reais são opcionais e consomem a cota do harness selecionado:

```bash
bash evals/run-agent-evals.sh all --harness kiro
bash evals/run-agent-evals.sh all --harness claude
bash evals/run-agent-evals.sh all --harness codex
```

Use `--model` e `--effort` para fixar a configuração avaliada. `.agents` é validado como instalação e resolução de recursos, não como um quarto executável. Resultados e limitações ficam em [`evals/evals.md`](../evals/evals.md); exit code zero também pode significar resultado inconclusivo e não aprova o pacote.

## Onde o ciclo quebra

1. Implementar com spec ou tasks em `draft`. A skill recusa.
2. Tratar o ponto do intent como aprovação. O intent segue `draft` até o ship.
3. Editar `INDEX.md` na mão.
4. Shipar porque os checkboxes fecharam. O ship é o ponto depois do resumo de implementação.

## Licença

MIT. Texto em [`LICENSE`](../LICENSE), no modelo publicado pela Open Source Initiative.
