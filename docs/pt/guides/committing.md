---
title: Commit
description: O método nunca faz commit; como os crumbs e as tracks alimentam o commit que você ou a sua ferramenta prepara.
---

# Commit

Esta página responde quem faz o commit, como os crumbs deixados pelas mudanças Express alimentam o commit e o que a pessoa ou a ferramenta que prepara o commit faz com eles.

## O método nunca faz commit

Nenhuma etapa do On Track Method faz commit, push ou deploy. A via Express termina com um relato; o Highway termina com o ship, que grava `status: shipped` no intent e regenera `on-track/INDEX.md`. O commit é seu, ou do agente ou da ferramenta a que você pedir para prepará-lo.

Uma track do Highway já se explica na hora do commit: o intent, a spec e as tarefas guardam o porquê. Mudanças Express não têm track, então cada uma deixa um crumb.

## O que um crumb dá ao commit

Cada mudança Express escreve um crumb em `on-track/crumbs/`, depois da verificação, tenha passado ou falhado. O formato está em [Mudanças Express](express-changes.md#o-crumb).

| Parte do crumb | Usada para |
|---|---|
| `files` e `## Changes` | Agrupar o diff: quais trechos pertencem a esta mudança. |
| `## Request` e `## Cause` | Escrever a mensagem do commit. |

O crumb também registra em `## Verification` a verificação que o agente rodou e o resultado.

Um crumb registra uma mudança Express para preparar o commit. Compare seus arquivos com `HEAD` antes de usá-lo; crumbs obsoletos devem ser apagados.

## Preparar commits a partir dos crumbs

Quem prepara os commits, pessoa ou agente:

1. Lê os crumbs do mais antigo para o mais recente. O nome do arquivo começa com o horário UTC, então a ordem dos nomes é a ordem no tempo.
2. Agrupa o diff pelos `files` e `Changes` de cada crumb.
3. Escreve a mensagem de cada commit a partir do `Request` e do `Cause` do crumb.
4. Apaga todo crumb que consumiu.
5. Apaga todo crumb cujos arquivos já não diferem de `HEAD`, porque aquela mudança já entrou em commit ou foi desfeita.

```text
on-track/crumbs/
  2026-11-10-143205Z-footer-typo.md      files: [src/partials/footer.html]
  2026-11-10-151840Z-signup-button.md    files: [src/styles/button.css, tests/button.snap]
```

Leia esses dois crumbs em ordem de horário e use seus `files` e `Changes` para agrupar o diff. Use `Request` e `Cause` para preparar as mensagens dos commits.

## Crumbs são locais

Crumbs nunca entram no git nem no índice. O `ot-init` cria `on-track/crumbs/.gitignore` com a única linha `*`, que ignora a pasta e o próprio `.gitignore`. Por isso um clone novo não tem a pasta `crumbs/`; o agente a cria, com o `.gitignore`, quando uma mudança Express precisa dela.

Os crumbs existem só na cópia de trabalho em que a mudança foi feita. Desfazer uma mudança Express apaga o crumb dela (veja [Mudanças Express](express-changes.md#desfazer-uma-mudanca-express)).
