---
title: Migração do fast-track-ai
description: Leve um projeto do layout fast-track-ai para o layout on-track à mão e depois rode o ot-init.
---

# Migração do fast-track-ai

Esta página responde como levar um projeto que usava o método com o nome anterior, `fast-track-ai`, para o layout atual do On Track Method. Não há migração automática: você faz cinco passos manuais, e o `ot-init` confere o resultado.

## O que mudou

| Antes | Agora |
|---|---|
| Árvore `fast-track-ai/` | Árvore `on-track/` |
| Skills e comandos `ft-*` | Skills e comandos `ot-*` |
| Bloco gerenciado `fast-track-ai` no `AGENTS.md` | Bloco gerenciado `on-track` no `AGENTS.md` |

O comando de instalação e o slug do repositório não mudaram.

## Passos

1. Reinstale as skills. O comando é o mesmo:

   ```bash
   npx skills add jotafurtado/on-track --skill '*'
   ```

   Remova do seu harness as entradas antigas de skills e comandos. Os nomes novos não são aliases dos antigos.

2. Em cada projeto, renomeie a pasta `fast-track-ai/` para `on-track/`.

   ```bash
   git mv fast-track-ai on-track
   ```

3. Troque `fast-track-ai/` por `on-track/` nos caminhos dentro dos arquivos dessa pasta.

4. No `AGENTS.md`, apague o bloco gerenciado antigo, tudo do marcador `<!-- BEGIN MANAGED BLOCK: fast-track-ai` até o marcador END dele.

5. Rode o `ot-init`. Ele grava o novo bloco gerenciado, cria qualquer pasta que falte (inclusive `on-track/crumbs/` com o `.gitignore` dela) e regenera `on-track/INDEX.md`. Leia o relato e resolva os erros de validação do índice; ele não é atualizado enquanto a validação falha.

## Por que o ot-init recusa

O `ot-init` procura o layout antigo antes de fazer qualquer outra coisa. Enquanto qualquer um destes existir, ele imprime uma mensagem `FAIL:` com o passo manual de cada um, sai com erro e não altera nada:

| Encontrado | A mensagem manda |
|---|---|
| Um arquivo, pasta ou link `fast-track-ai` na raiz do projeto | Renomeá-lo para `on-track/` e trocar `fast-track-ai/` por `on-track/` nos caminhos dentro dos arquivos dele. |
| Uma linha do `AGENTS.md` que começa com `<!-- BEGIN MANAGED BLOCK: fast-track-ai` | Apagar tudo do marcador BEGIN até o marcador END dele. |

Quando os dois existem, as duas mensagens aparecem. O agente repassa a mensagem e para; não renomeia nem apaga nada a menos que você peça.
