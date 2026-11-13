---
title: Sua primeira track
description: Inicialize o On Track Method em um repositório e leve um pedido do Highway do intent ao ship.
---

# Sua primeira track

Esta página responde o que o `ot-init` cria no seu repositório e o que acontece, etapa por etapa, quando você leva um pedido pelo Highway: o que o agente escreve, o que ele mostra e o que você digita em cada sinal.

O projeto de exemplo é um pequeno site institucional. O pedido é uma nova versão da landing page, que vira a track `001-lp-v2`.

## Inicializar o repositório

Abra o agente na raiz do projeto e execute a skill de inicialização:

```text
/ot-init
```

Você também pode pedir com palavras simples: `setup on-track`, `install on-track` ou `init the method here`. A skill também se aplica quando a árvore `on-track/` não existe.

O `ot-init` executa `on-track-init.sh`, depois `on-track-index.sh`, e relata o resultado. Ele cria:

```text
AGENTS.md              bloco gerenciado adicionado ou renovado
on-track/
  INDEX.md             índice gerado, criado vazio
  research/
  refs/
  assessments/
  decisions/
  handoffs/
    archive/
  crumbs/
    .gitignore         uma única linha: *
  tracks/
```

- **O bloco gerenciado** é o texto entre `<!-- BEGIN MANAGED BLOCK: on-track. Installed by ot-init, idempotent block. -->` e `<!-- END MANAGED BLOCK: on-track -->` no `AGENTS.md`. Ele diz a qualquer agente que trabalhe no repositório como classificar pedidos, quando perguntar, como os sinais funcionam e onde ficam os artefatos. Se o `AGENTS.md` não existe, o init o cria com o bloco. Se o bloco já existe, o init o substitui no lugar e não toca no resto do arquivo.
- **`on-track/INDEX.md`** é gerado a partir do frontmatter dos arquivos em `on-track/`. Os agentes o leem antes de procurar uma track ou um artefato de apoio. Não o edite à mão: a próxima geração sobrescreve.
- **`on-track/crumbs/`** guarda as notas locais que as mudanças Express deixam para o commit. O `.gitignore` dela mantém a pasta fora do git. O init nunca sobrescreve um `.gitignore` que já exista ali.

O init é idempotente: rode duas vezes e nada se duplica. Ele para com erro e não altera nada quando os marcadores `on-track` do `AGENTS.md` estão malformados (qualquer coisa diferente de nenhum marcador ou de exatamente um BEGIN seguido de um END), ou quando encontra o layout antigo descrito em [Migração do nome anterior](migrating.md).

O init não escreve mais nada. Os artefatos de apoio são escritos depois, pelas skills donas deles.

## Fazer um pedido

Comece uma mudança com um pedido concreto. Nomear a skill de intent seleciona o Highway, mesmo para uma mudança pequena:

```text
/ot-intent Refaça a landing page com o novo hero, a tabela de preços e o formulário de cadastro.
Não altere o layout do blog.
```

Sem o nome da skill, o agente classifica o pedido sozinho. Um pedido que não cumpre os cinco critérios Express segue pelo Highway. Veja [Classes de pedido](../reference/request-classes.md).

## Etapa 1: intent

O agente investiga o repositório primeiro. Se restar uma pergunta bloqueadora, aquela cuja resposta muda escopo, segurança, persistência, integração externa, arquitetura ou aceitação, ele faz todas em uma rodada de até quatro, cada uma com opções e a recomendação dele primeiro. Veja [Perguntas e delegação](../guides/questions-and-delegation.md).

Depois ele grava `on-track/tracks/001-lp-v2/intent.md` com `status: draft`, regenera o índice e apresenta um resumo:

```text
- Problema: a landing page atual não tem seção de preços e o formulário de cadastro envia para um endpoint removido.
- Resultado: uma nova landing page com hero, tabela de preços e um formulário de cadastro funcionando.
- Escopo: src/pages/index.html, src/styles/landing.css, src/scripts/signup.js.
- Restrições: o layout do blog não muda.

Track: on-track/tracks/001-lp-v2/
. para continuar com a spec
```

Os quatro tópicos são sempre problema, resultado proposto, escopo e restrições. Quando se aplicam, mais duas linhas aparecem antes da localização da track: as restrições que o agente propôs, para você poder vetá-las, e um aviso quando o problema ou o resultado se apoia em uma premissa não verificada. Qualquer research, ref, ADR ou assessment que o agente tenha criado no caminho também é listado.

A linha de próximo passo aparece exatamente como está no pacote.

Agora o agente para e espera o seu sinal. Abra o `intent.md` se quiser lê-lo inteiro e responda:

| Você digita | O que acontece |
|---|---|
| `.` | O agente executa a etapa de spec para a mesma track. |
| `Mantenha também o formulário antigo funcionando até o lançamento.` | Amarelo: o agente revisa o intent, regenera o índice e mostra o resumo de novo. |
| `x` | O agente para. O intent fica em `draft` e a track é retomada quando você pedir esta etapa de novo. |

O verde não aprova o intent. Ele fica em `draft` até o ship.

## Etapa 2: spec

A etapa de spec lê o intent e resolve toda pergunta bloqueadora restante antes de apresentar o resumo, em quantas rodadas de até quatro perguntas forem necessárias. Ela grava dois arquivos, ambos com `status: draft`:

- `spec.md`: o resultado, as fases numeradas, as restrições e o que está fora do escopo. Cada fase tem `Done:` (o estado entregue e observável), `Files:` (a lista explícita dos arquivos que ela toca) e `Accept:` (o comando ou a observação que comprova).
- `tasks.md`: tarefas agrupadas sob títulos `## Group <name>`, com `(depends: <group>)` no grupo que precisa esperar outro. Cada tarefa leva uma marca `(Phase N)`, `Files:` e `Validate:`.

Ela regenera o índice, roda o gate no modo structure como checagem interna e apresenta:

```text
- Resultado: a nova landing page implementada, com um formulário de cadastro funcionando.
- Fases: 1 marcação e estilos, 2 formulário de cadastro.
- Tarefas: 3.
- Grupos: A (marcação, estilos), B depende de A (script de cadastro).

Track: on-track/tracks/001-lp-v2/
. para implementar
```

As decisões que você delegou com "decida você" são listadas antes da localização da track para você poder vetá-las.

| Você digita | O que acontece |
|---|---|
| `.` | O agente grava `status: approved` em `spec.md` e `tasks.md`, como passo exclusivo de aprovação, e então inicia a implementação. |
| `Junte as fases 1 e 2.` | Amarelo: o agente revisa a spec ou as tarefas, regenera o índice, roda de novo o gate de estrutura e mostra o resumo de novo. |
| `x` | O agente para. Os dois arquivos ficam em `draft`. |

O seu verde cobre exatamente a spec e as tarefas que foram mostradas. Uma mudança material posterior em qualquer um dos arquivos devolve os dois a `draft` e exige novo resumo e novo verde. Veja [Sinais do Highway](../guides/highway-signals.md).

## Etapa 3: implement

Com `spec.md` e `tasks.md` aprovados, o agente:

1. Executa os grupos de tarefas em ordem de dependência. Tarefas do mesmo grupo podem rodar em paralelo; um grupo dependente só começa depois que toda tarefa da qual depende passou no `Validate` e está marcada.
2. Restringe as edições de produto aos arquivos listados na spec e em cada tarefa, e nunca implementa `Out of scope`. Antes de tocar em outro arquivo de produto, para e pergunta. Os arquivos administrativos do método só mudam pelas transições definidas em `ot-implement`.
3. Roda o `Validate` de cada tarefa e as verificações que o projeto já tem, e só marca a tarefa `- [x]` quando elas passam.
4. Grava `assets/acceptance.md`, uma tabela com uma linha para o resultado e uma para cada linha `Accept:` das fases, cada uma executada e marcada `met` ou `pending`.
5. Roda o gate de conclusão e uma revisão do diff. Corrige todo achado `[blocking]` e todo achado `[important]` cuja correção fica dentro dos arquivos da spec, e registra todos os achados em `assets/review.md`. Depois de cada correção obrigatória da revisão, roda novamente os comandos `Validate` das tarefas afetadas e as verificações de aceitação das fases afetadas, atualiza as linhas de aceitação afetadas e roda novamente o gate de conclusão. Repete a revisão até não restar achado `[blocking]`.

Na retomada, tarefas marcadas já estão validadas: o agente continua pela primeira tarefa aberta em ordem de dependência e só roda novamente o `Validate` de uma tarefa marcada se uma mudança posterior tiver tocado seus `Files`. Se uma tarefa pré-requisito falhar no `Validate`, o agente a mantém aberta, para antes de todos os grupos dependentes e relata a falha.

Antes de uma tarefa depender de uma entrada em `Unverified assumptions`, o agente a verifica. Se um fato informado pelo usuário, um fato verificado na sessão ou uma premissa se mostrar falso, registra a divergência em `assets/` da track, para e relata antes de mudar a abordagem.

Ao terminar o trabalho, o agente regenera o índice e apresenta:

```text
- Tarefas: 3/3 concluídas.
- Aceitação: 3/3 met (assets/acceptance.md).
- Revisão: 2 fixed, 1 open; nenhum [important] aberto (assets/review.md).
- Gate: PASS.

. para ship (marca a track como concluida)
```

A linha de ship só aparece quando toda linha de aceitação está `met` e não resta nenhum achado `[blocking]`.

## Etapa 4: ship

| Você digita | O que acontece |
|---|---|
| `.` | O agente grava `status: shipped` no intent e regenera o índice. A track está concluída. |
| `Corrija também o nit aberto em signup.js.` | Amarelo: o agente faz a correção, roda de novo as verificações afetadas e mostra o resumo de novo. |
| `x` | O agente para. O código fica como está e o ship continua disponível quando você pedir. |

Caixas marcadas e um gate aprovado nunca fazem o ship de uma track sozinhos. O ship não faz commit, push nem deploy. O commit é seu; veja [Commit](../guides/committing.md).

## Como a track fica no fim

```text
on-track/tracks/001-lp-v2/
  intent.md        status: shipped
  spec.md          status: approved
  tasks.md         status: approved, toda tarefa marcada
  assets/
    acceptance.md
    review.md
```

O `INDEX.md` mostra a track com status `shipped` e fase `-`. Os formatos dos arquivos estão em [Artefatos](../reference/artifacts.md); todas as regras das etapas estão em [Ciclo](../reference/cycle.md).
