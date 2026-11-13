---
title: Mudanças Express
description: Quando um pedido segue pela via Express, como escolher a via você mesmo, o que o agente faz e como desfazer uma mudança Express.
---

# Mudanças Express

Esta página responde quando uma edição segue pela via Express, como forçar qualquer uma das vias, o que o agente faz nela, o que é o crumb, como desfazer uma mudança Express e o que acontece quando a mudança se mostra maior do que parecia.

A via Express é para edições pequenas, delimitadas e reversíveis. Ela não tem track, intent nem spec, e não para à espera de sinal: o agente implementa, verifica, deixa uma nota e relata.

## Quando um pedido segue pela via Express

Os cinco critérios precisam valer:

1. O pedido diz o que construir, sem pergunta aberta que o mudaria.
2. No máximo três arquivos mudam.
3. Nada desta lista muda: um contrato público (API, flags de CLI, schema, um formato de arquivo que alguém consome), dado persistido ou migration, um controle de segurança (autenticação, autorização, segredos, permissões) ou uma dependência (adicionada, atualizada ou removida).
4. Reverter apenas o diff desfaz a mudança, sem backfill de dados e sem efeito colateral externo.
5. Um comando existente ou uma verificação observável a confirma.

Se algum critério estiver incerto, a edição segue pelo Highway. O Highway é o padrão.

Exemplos em um pequeno site institucional:

| Pedido | Via | Por quê |
|---|---|---|
| "Corrija o erro de digitação na linha de copyright do rodapé." | Express | Um arquivo, nada em aberto, a página mostra o resultado. |
| "Troque a cor do botão de cadastro para o verde da marca e atualize o snapshot dele." | Express | Dois arquivos, verificados pelo teste de snapshot existente. |
| "Adicione uma tabela de preços que lê os planos da API." | Highway | Restam perguntas de desenho em aberto (layout, ordem dos planos, estado de erro), então o critério 1 falha. |
| "Adicione uma flag `--draft` ao script de build." | Highway | Muda flags de CLI, um contrato público. |
| "Atualize o framework de CSS." | Highway | Muda uma dependência. |

Um pedido composto é separado primeiro. "Rode os testes e depois corrija o erro no rodapé" roda os testes como trabalho operacional, sem artefato, e corrige o erro pela via Express.

## Escolher a via você mesmo

A sua escolha explícita vence nos dois sentidos:

- **Highway**: nomeie `ot-intent`, ou peça uma track ou um intent. Até uma correção de uma linha passa então pelo ciclo completo.
- **Express**: peça para fazer direto ou sem track.

```text
Corrija o erro do rodapé direto, sem track.
```

## O que o agente faz

1. Diz em uma frase que a mudança segue pela via Express.
2. Implementa.
3. Roda a verificação.
4. Escreve um crumb com o resultado da verificação, tenha ela passado ou falhado.
5. Relata o que mudou e o resultado.

Esse relato encerra o trabalho. Não há resumo com linha de próximo passo nem espera por sinal.

Fora o crumb, o agente não cria track nem arquivo em `on-track/`, e não regenera o índice. A única exceção é uma decisão que atinge o limiar de ADR (veja [Limiares](../reference/thresholds.md)): o agente registra só essa ADR e regenera o índice.

## O crumb

O crumb é a nota local que uma mudança Express deixa para quem prepara o commit. Ele fica em `on-track/crumbs/<YYYY-MM-DD-HHMMSSZ>-<slug>.md`, com o horário em UTC.

```markdown
---
created: 2026-11-10T14:32:05Z
files:
  - src/partials/footer.html
---

## Request

Fix the typo in the footer copyright line.

## Cause

The year range was typed as "2024-2O26" with a capital O.

## Changes

- `src/partials/footer.html`: corrected the year range.

## Verification

Opened the home page; the footer reads "2024-2026".
```

| Parte | Conteúdo |
|---|---|
| `created` | O instante em UTC, ISO 8601. |
| `files` | Todo caminho que a mudança tocou, incluindo uma ADR registrada. |
| `## Request` | O que você pediu, em uma ou duas frases. |
| `## Cause` | Só em correções: a causa encontrada. |
| `## Changes` | Uma linha por arquivo. |
| `## Verification` | O comando ou a observação, e o resultado. |

O crumb não tem `id`, `status` nem número de track. Ele fica fora do git e fora do índice. Quando `on-track/crumbs/.gitignore` está ausente, por exemplo em um clone novo, o agente o cria com a única linha `*`. Como os crumbs são consumidos está em [Commit](committing.md).

## Desfazer uma mudança Express

Peça ao agente para desfazer. Ele reverte as próprias edições trecho por trecho, para que qualquer trabalho seu ainda sem commit nos mesmos arquivos sobreviva, e apaga o crumb da mudança. Ele não restaura arquivos inteiros pelo git.

## Quando um critério deixa de valer

Se, durante o trabalho, o agente descobre que um critério não vale mais (é preciso um quarto arquivo, uma dependência precisa mudar, surge uma pergunta aberta), ele para antes da edição que quebraria o critério, diz qual critério caiu e inicia o Highway com `ot-intent`. A partir daí o pedido segue [Sua primeira track](../getting-started/first-track.md).
