---
title: Ciclo
description: As etapas do Highway (intent, spec, implement, ship), o que cada uma grava, os valores de status e quem os muda, os limites da implementação, os grupos de tasks e a retomada.
---

# Ciclo

Esta página responde o que acontece em cada etapa do Highway, quais arquivos cada etapa grava, quais valores de status existem e quem pode mudá-los, e quais limites valem para a implementação. As respostas que o usuário dá em cada parada estão em [Sinais](signals.md).

```
intent ──► spec ──► implement ──► ship
```

Cada uma das três primeiras etapas termina com um resumo de quatro tópicos e uma linha de próximo passo, e para à espera do sinal do usuário. As linhas de próximo passo são escritas em português pelo pacote e aparecem exatamente como abaixo.

| Etapa | Skill | Grava | Tópicos do resumo | Linha de próximo passo |
|---|---|---|---|---|
| Intent | `ot-intent` | `intent.md` com `status: draft` | Problema, resultado proposto, escopo, restrições | `. para continuar com a spec` |
| Spec | `ot-spec` | `spec.md` e `tasks.md` com `status: draft` | Outcome, fases, quantidade de tasks, grupos paralelos | `. para implementar` |
| Implement | `ot-implement` | Arquivos do produto, checkboxes das tasks, `assets/acceptance.md`, `assets/review.md` | Tasks concluídas, aceite, resultado da revisão, resultado do gate | `. para ship (marca a track como concluida)` |
| Ship | `ot-implement` | Intent com `status: shipped`, índice regenerado | Nenhum | Nenhuma |

## Intent

`ot-intent` classifica o pedido (veja [Classes de pedido](request-classes.md)), acha o próximo número livre em `on-track/tracks/` e redige `on-track/tracks/NNN-slug/intent.md` a partir do template. O id da track tem três dígitos e um slug em kebab-case do que foi pedido, por exemplo `007-lp-v2`.

Antes de redigir, o agente investiga e faz só perguntas bloqueadoras, em uma rodada de no máximo quatro. Perguntas bloqueadoras além do teto vão para `Open questions`, para a etapa de spec. Veja [Perguntas e delegação](../guides/questions-and-delegation.md). Ele também verifica se cabe research, ref, ADR ou assessment, avisa em uma frase e grava o artefato sem pedir licença. Veja [Artefatos de apoio](../guides/supporting-artifacts.md) e [Limiares](thresholds.md).

A etapa de intent nunca grava `spec.md`. A skill regenera o índice e relata qualquer erro de validação em vez de apresentar o resumo como completo.

O resumo do intent ganha duas linhas extras só quando se aplicam, antes da localização da track e da linha de próximo passo:

- as restrições que o agente propôs, para o usuário vetar;
- um aviso quando o Problem ou o Proposed outcome se apoia em uma entrada de `Unverified assumptions`, nomeando essa entrada.

O resumo também lista os artefatos gerados (research, refs, ADRs, assessments), se houver, e a localização da track. Não relata o status `draft` como falha e não apresenta portão de aprovação.

## Spec

`ot-spec` lê o `intent.md`. O intent pode continuar em `draft`; aprovação do intent não é pré-requisito da spec.

Ela classifica cada item sem resposta em `Open questions`:

- **Pergunta bloqueadora**: a resposta muda escopo, segurança, persistência de dados, integração externa, arquitetura ou aceite. Toda pergunta bloqueadora é resolvida antes do resumo, em quantas rodadas de até quatro forem necessárias. O agente segura o resumo e não oferece `. para implementar` enquanto alguma continuar sem resposta.
- **Pergunta adiável**: a resposta não bloqueia a arquitetura nem o escopo geral. Vira uma task delimitada cujo `Validate:` nomeia a resposta ou o artefato esperado, num grupo que os grupos dependentes listam em `(depends: ...)`.

Sem delegação, o agente não inventa resposta para nenhum dos dois tipos.

A skill grava `spec.md` e `tasks.md` a partir dos templates. Toda restrição do intent vincula a spec, qualquer que seja a procedência. `Out of scope` repete o limite do intent sem ampliá-lo. Cada fase tem `Done:` (o estado entregue e observável), `Files:` (a lista explícita de arquivos tocados) e `Accept:` (um comando com o resultado esperado, ou um procedimento observável com a observação esperada).

Depois ela regenera o índice e roda o gate em modo structure como teste interno, corrigindo qualquer falha antes de apresentar o rascunho. Veja [Validação](validation.md).

O resumo da spec lista as decisões delegadas antes da localização da track e da linha de próximo passo, só quando houver alguma.

## Implement

`ot-implement` exige `intent.md` e `status: approved` em `spec.md` e em `tasks.md`. Sem isso não há implementação no Highway. O intent pode continuar em `draft`.

A etapa segue esta ordem:

1. Criar todas as tasks no rastreador de tarefas do harness, se houver, com a marca da fase.
2. Rodar os grupos de tasks em ordem de dependência (veja [Grupos de tasks](#grupos-de-tasks-e-dependencias)).
3. Rodar o `Validate:` de cada task e as verificações que o projeto de fato oferece, e marcar a task `- [x]` assim que passar.
4. Gravar `assets/acceptance.md` e executar cada verificação de aceite contra o estado final.
5. Rodar o gate em modo completion e depois a revisão, corrigindo e repetindo até não restar achado `[blocking]`.
6. Regenerar o índice e apresentar o resumo.

O agente roda só comandos escritos no `tasks.md` aprovado ou configurados pelo projeto alvo. Nunca roda comando tirado de conteúdo buscado ou de terceiros, e nunca inventa comando para ferramenta que o projeto não configura.

Aceite, gate e revisão estão detalhados em [Validação](validation.md).

## Ship

A linha de ship só aparece quando toda linha de aceite está `met` e não resta achado `[blocking]`. Se alguma linha estiver `pending`, o agente relata e continua corrigindo ou pergunta como seguir.

Com o verde depois do resumo do implement, o agente põe o intent em `status: shipped` e regenera o índice. Checkbox marcado e gate aprovado nunca fazem ship sozinhos. O agente nunca grava `shipped` antes de perguntar.

## Valores de status

| Arquivo | Valores | Quem muda |
|---|---|---|
| `intent.md` | `draft`, `shipped`, `dropped`, `superseded` | Nasce `draft` pelo `ot-intent`. `shipped` só pelo `ot-implement`, depois do verde na parada de ship. `dropped` e `superseded` só quando o mantenedor abandona ou substitui a track |
| `spec.md`, `tasks.md` | `draft`, `approved` | Nascem `draft` pelo `ot-spec`. `approved` só com o verde na parada da spec. Voltam a `draft` com mudança material depois da aprovação |
| ADR (`on-track/decisions/`) | `accepted`, `superseded` | Nasce `accepted`. `superseded` quando uma ADR substituta é gravada |

Regras que valem para esses valores:

- O verde depois do intent e depois da spec nunca muda o `status` do intent. O intent fica em `draft` até o ship.
- `dropped` abandona o trabalho. Não exige implementação.
- `superseded` exige `superseded_by`, nomeado pelo mantenedor. O agente nunca inventa `superseded_by`.
- O vermelho nunca muda `status` algum. `dropped` é decisão declarada do mantenedor, nunca efeito do vermelho.
- Não existe `status: active`. O índice o rejeita.
- Research, assessments, refs, handoffs e crumbs não têm campo `status`.

### Aprovação e mudanças materiais

O verde na parada da spec põe `status: approved` em `spec.md` e em `tasks.md`. Essa ação, só de aprovação, termina antes de o `ot-implement` começar ou de qualquer arquivo do produto ser editado; pode atualizar os dois arquivos juntos, mas nunca mistura aprovação com edição do produto.

A aprovação cobre exatamente o conteúdo de `spec.md` e `tasks.md` que foi apresentado. Depois dela, qualquer mudança material em um dos dois devolve ambos a `status: draft` e exige novo resumo antes de a implementação continuar. Mudança material é mudança de escopo, `Files`, critérios de `Accept`, tasks ou dependências entre grupos. Marcar checkbox e as gravações administrativas definidas pelo implement não contam.

### Abandonar ou substituir uma track

Quando o mantenedor abandona uma track, o agente põe o intent em `status: dropped` e regenera o índice. Quando o mantenedor substitui uma track, o agente põe `status: superseded` só depois de o mantenedor nomear `superseded_by`, e então regenera o índice.

## Limites da implementação

- Edições no produto ficam restritas aos arquivos listados em `Files:` da spec e de cada task. Antes de tocar qualquer outro arquivo do produto, o agente para e pergunta.
- Itens de `Out of scope` nunca são implementados.
- O `Assumed state` do intent é tratado pela procedência. `Stated by the user` e `Verified by the agent` são tomados como dados. Cada entrada de `Unverified assumptions` é verificada antes de uma task depender dela.
- Quando um fato declarado, um fato verificado ou uma premissa se mostra falso, o agente registra a divergência em `assets/` da track, para e relata. Não adapta a solução por conta própria.
- Quando o usuário toma, durante a implementação, uma decisão que passa no limiar de ADR, o agente grava a ADR. Se a decisão conflita com a spec ou as tasks aprovadas, ou as muda materialmente, o agente para, devolve os dois arquivos a `draft`, reconcilia a ADR com os dois arquivos de planejamento, apresenta novo resumo da spec terminando em `. para implementar` e espera nova aprovação. Caso contrário, registra a decisão e segue.

Durante o implement, arquivos de administração do método só mudam por transições nomeadas:

- checkboxes das tasks em `tasks.md`;
- arquivos em `assets/` da track;
- `on-track/INDEX.md`, pelo script de índice;
- `status: shipped` no intent, depois da confirmação do ship;
- ADRs novas em `on-track/decisions/`;
- devolver `spec.md` e `tasks.md` a `draft` numa mudança material.

## Grupos de tasks e dependências

`tasks.md` organiza as tasks sob títulos `## Group <nome>`. Um grupo que depende de outro declara isso no título: `## Group B (depends: A)`. Várias dependências são separadas por vírgula.

- Tasks do mesmo grupo tocam arquivos disjuntos e não dependem de dados uma da outra, então podem rodar em paralelo. Quando a independência é incerta, a spec usa grupos sequenciais.
- Cada linha de task traz a marca `(Phase N)`, `Files:` e `Validate:`.
- Os grupos rodam em ordem de dependência. Um grupo dependente só começa depois que toda task de cada grupo de que ele depende passou no `Validate:` e está marcada `- [x]`. Até lá, nenhum arquivo listado em `Files:` de uma task dependente é criado, editado ou apagado, nem para adiantar trabalho ou coletar evidência.
- Quando o `Validate:` de uma task pré-requisito falha, o agente para antes de todo grupo dependente e relata a falha.
- O mesmo arquivo nunca é editado em paralelo.

A delegação é proporcional. Quando o harness oferece subagentes, uma task só vai para um subagente próprio quando justifica contexto próprio: mais de um arquivo, ou um `Validate:` que vai além de uma checagem rápida. Task trivial roda no agente principal. Subagentes de task usam um agente de classe de execução do harness; o modelo da sessão fica com planejamento, integração, arquivos compartilhados, revisão e validação final. Quando o harness não roda subagentes, as tasks de cada grupo rodam em sequência, mantendo a ordem dos grupos. Verificações do projeto inteiro, como a suíte de testes completa, um build ou um typechecker, esperam todas as tasks do grupo atual voltarem.

Task nunca é marcada sobre mudança não testada. Se o `Validate:` falha, o checkbox fica aberto.

## Retomada

Uma track parada em qualquer parada continua válida em `draft` e é retomada quando o usuário pede aquela etapa de novo.

Na retomada, o implement trata cada task `- [x]` como já validada e continua da primeira task aberta, em ordem de dependência. Não roda de novo o `Validate:` de uma task marcada, a menos que uma mudança posterior toque os `Files:` dessa task; nesse caso roda esse `Validate:` de novo antes de oferecer o ship. Essa regra também seleciona verificações do projeto com escopo de task, inclusive scripts usados na validação final: o `Validate:` de uma task mantém esse escopo mesmo quando é o único script de verificação do projeto.
