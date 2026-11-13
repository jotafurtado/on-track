---
title: Validação
description: O que o gerador do índice verifica, o gate nos modos structure e completion, a evidência de aceite, a revisão do implement e a suíte de evals do pacote.
---

# Validação

Esta página responde quais verificações o método roda, o que faz cada uma falhar e o que a revisão do implement faz com os achados. Todos os scripts do pacote são Bash local, sem chamada de rede.

## Gerador do índice

`skills/ot-init/scripts/on-track-index.sh [repo-root]` lê o frontmatter em `on-track/` e grava só `on-track/INDEX.md`. Monta o índice inteiro num arquivo temporário e só substitui o `INDEX.md` quando a validação não relata erros. Erros de validação de artefatos produzem linhas `ERROR:` seguidas de `INDEX not updated: N error(s).`, saída com código 1 e preservação do `INDEX.md`. Se `on-track/tracks` faltar, o script sai com código 1 depois de uma única linha `ERROR:`, sem esse resumo final. Com sucesso, imprime `INDEX ok at <caminho>`.

Toda skill que grava artefato regenera o índice e relata qualquer erro de validação em vez de apresentar o resultado como completo. O formato das tabelas está em [Artefatos](artifacts.md#index-md).

O gerador falha quando:

| Área | Falha |
|---|---|
| Preparação | `on-track/tracks` não existe |
| Frontmatter | Bloco não fechado, linha que não é campo `key: value`, ou chave repetida |
| Tracks | Pasta de track sem `intent.md`; nome da pasta fora do padrão `NNN-slug`; `id` ou `status` ausente; `id` diferente do nome da pasta; `status` fora de `draft`, `shipped`, `dropped` ou `superseded` |
| Citações | Valor não vazio de `research`, `assessments`, `refs` ou `decisions` fora da forma `[a, b]`, com slug vazio entre os itens processados, ou nomeando arquivo que não existe. Campos ausentes ou vazios não são validados |
| Substituição | `superseded` sem `superseded_by`; `superseded_by` apontando para si mesmo ou para track ou ADR inexistente |
| Refs | Nome de arquivo inválido; arquivo acima de 500 KB; `captured`, `owner` ou `content_license` ausente; `sha256` que não tem 64 caracteres hexadecimais minúsculos; campo `status`; `type` inválido; ref `inline` com `source`, `pin` ou `retrieved_at`, ou cujo `sha256` não confere com o `## Source content` normalizado; ref `pointer` sem `source`, com `pin` e `retrieved_at` juntos ou sem nenhum dos dois, ou cujo `sha256` é o hash do localizador `source`; `sha256` que duplica um ref anterior |
| Research | Nome de arquivo inválido; `captured` ou `owner` ausente; campo `status` ou `source` no singular; título obrigatório ausente |
| Assessments | Nome de arquivo fora de `YYYY-MM-DD-slug.md`; `captured`, `owner`, `scope`, `evaluator` ou `tracks` ausente; campo `status`; `captured` diferente da data do nome do arquivo; título obrigatório ausente |
| Decisions | Nome de arquivo fora de `NNN-slug.md`; `id`, `status`, `date` ou `owner` ausente; `id` diferente do nome do arquivo; `status` fora de `accepted` ou `superseded`; título obrigatório ausente |
| Handoffs | Nome de arquivo fora de `YYYY-MM-DD-HHmmssZ-slug.md`; `captured` fora de `YYYY-MM-DDTHH:MM:SSZ` ou diferente do instante do nome; `owner` ou `focus` ausente; campo `status`; título obrigatório ausente; mais de três handoffs ativos |

`spec.md` ou `tasks.md` ausente ou malformado nunca derruba o índice; só conta como não aprovado na hora de derivar a fase. `crumbs/` e `handoffs/archive/` nunca são lidos.

## Gate

`skills/ot-spec/scripts/on-track-gate.sh --track NNN-slug [--root DIR] [--mode structure|completion]` só lê e só relata. O modo padrão é `completion`. Uma etapa de validação que falha imprime uma ou mais linhas `FAIL:` e sai com código 1; o sucesso imprime uma linha `PASS`.

Os dois modos verificam:

1. `on-track/tracks/NNN-slug/intent.md` existe e é arquivo, o frontmatter é válido e o `id` é igual ao nome da track.
2. A raiz da track não tem entrada oculta nem entrada fora de `intent.md`, `spec.md`, `tasks.md` e `assets`. `spec.md` e `tasks.md` precisam ser arquivos. Se `assets` existir, precisa ser diretório; sua ausência é aceita.
3. `spec.md` e `tasks.md` existem. Quando um bloco de frontmatter abre na linha 1, linhas malformadas, chaves repetidas e bloco não fechado reprovam. O modo structure não exige bloco de abertura; o modo completion exige também `status: approved` em cada arquivo.
4. `spec.md` tem pelo menos uma seção `### Phase`, e cada fase tem linhas `Done:`, `Files:` e `Accept:` não vazias.
5. `tasks.md` tem pelo menos uma linha de task e pelo menos um título `## Group`, nenhuma task antes do primeiro título, `Files:` e `Validate:` não vazios em toda task, nomes de grupo não vazios e únicos, e dependências que nomeiam grupos existentes, nunca o próprio grupo, sem formar ciclo.

| Modo | Acrescenta | Linha de sucesso | Usado por |
|---|---|---|---|
| `structure` | Nada. Status de aprovação e checkboxes são ignorados | `PASS: NNN-slug structure valid` | `ot-spec`, como teste interno antes de cada resumo. A falha é corrigida antes de o rascunho ser apresentado; status `draft` não é falha |
| `completion` | `spec.md` e `tasks.md` com `status: approved`, e nenhuma task aberta (`- [ ]`) | `PASS: NNN-slug cycle intact` | `ot-implement`, depois que toda task foi marcada e antes da revisão |

Sem passar no modo completion, não há ship.

## Evidência de aceite

Depois que toda task passa no `Validate:`, o implement grava `on-track/tracks/NNN-slug/assets/acceptance.md` como tabela:

```markdown
| Criterion | Check | Observed | Result |
|---|---|---|---|
| Outcome: the new landing page is live at /v2 | curl -s -o /dev/null -w '%{http_code}' localhost:3000/v2 | 200 | met |
| Phase 1: hero renders the new copy | open /v2 and read the hero | "Plan less, ship more" shown | met |
```

Há uma linha para o `Outcome` da spec e uma por linha `Accept:` de fase. Cada verificação roda contra o estado final e registra o que foi observado. `Result` é `met` ou `pending`. Toda linha precisa estar `met` antes de o ship ser oferecido. O resumo do implement relata `N/M met (assets/acceptance.md)`.

## Revisão do implement

Depois que o gate de completion passa, o implement roda uma revisão que pertence ao pacote. O procedimento é o mesmo em toda track e não depende de nenhum arquivo do projeto consumidor. Ter pedido Off Road antes não o muda.

Princípios: pegar bugs e casos de borda; manter a mudança sustentável; comentar o código, não a pessoa; ignorar formatação que é papel do linter.

Fases:

1. Contexto a partir do intent, da spec e do diff.
2. Encaixe geral com os `Files:` e o `Out of scope` da spec.
3. Linha a linha nos arquivos listados, buscando correção, segurança e respostas inventadas ou edições fora da lista.
4. Resumo e uma decisão.

| Severidade | Significado | Destino |
|---|---|---|
| `[blocking]` | Precisa corrigir | Sempre corrigido antes do ship |
| `[important]` | Deve corrigir | Corrigido quando a correção cabe nos `Files:` da spec; senão fica `open` |
| `[nit]` | Opcional | Fica `open` |
| `[suggestion]` | Alternativa | Fica `open` |

Depois de cada correção, o agente roda de novo o `Validate:` das tasks afetadas e as verificações de aceite das fases afetadas, atualiza `Observed` e `Result` em `assets/acceptance.md`, roda de novo o gate de completion e revisa outra vez. O ciclo se repete até não restar achado `[blocking]`. Correção que exige arquivo fora da spec, ou que muda a spec aprovada, para e pergunta; veja [Ciclo](cycle.md#limites-da-implementacao).

Todo achado é registrado em `on-track/tracks/NNN-slug/assets/review.md`:

```markdown
| Severity | Finding | Location | Disposition |
|---|---|---|---|
| [important] | Empty email accepted by the signup form | src/signup.ts:42 | fixed |
| [nit] | Variable name `d` is unclear | src/hero.ts:10 | open |
```

Quando a revisão não acha nada, o arquivo traz o cabeçalho e uma linha dizendo isso. O resumo do implement conta os achados `fixed` e `open` e nomeia cada `[important]` aberto. Para mandar corrigir um achado aberto, responda amarelo na parada de ship. `assets/review.md` é evidência da revisão, não exigência extra do gate.

## Suíte de evals do pacote

O próprio pacote é verificado por uma suíte determinística que roda instalação, recursos e scripts contra projetos descartáveis, sem chamar modelo: `bash evals/run-evals.sh all` na raiz do repositório do pacote. Existem sessões opcionais com agentes reais, mas elas nunca aprovam o pacote sozinhas. Seletores, contratos e resultados estão em `evals/evals.md` no repositório do pacote (veja em [Instalação](../getting-started/installation.md) onde o repositório fica).
