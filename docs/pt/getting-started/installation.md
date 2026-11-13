---
title: Instalação
description: Instale as sete skills do On Track Method com npx skills ou a partir de um checkout, e mantenha-as atualizadas.
---

# Instalação

Esta página responde como instalar o On Track Method em um projeto, o que a instalação coloca na sua máquina e como atualizar.

## Requisitos

- Node.js 22.20 ou superior e `npx`, para a instalação com `npx skills`.
- Git.
- Bash. Todo script do pacote é Bash local, sem chamadas de rede.
- Um agente de código com suporte a skills. O pacote é avaliado com Claude Code, Codex e Kiro.

## Instalar com npx skills

Na raiz do projeto em que você quer usar o método, execute:

```bash
npx skills add jotafurtado/on-track --skill '*'
```

O [skills CLI](https://github.com/vercel-labs/skills#install-a-skill) permite escolher os agentes e instala no projeto por padrão.

| Opção | Efeito |
|---|---|
| `--global` | Instala para o seu usuário em vez do projeto, para que todo projeto possa usar as skills. |
| `--agent claude-code`, `--agent codex`, `--agent kiro-cli` | Seleciona explicitamente um dos agentes avaliados. |

Instale o conjunto completo com `--skill '*'`. Cada script e cada template tem uma skill dona, e as outras skills o alcançam por caminhos entre irmãs, como `../ot-init/scripts/on-track-index.sh`. Uma instalação parcial pode deixar uma skill apontando para um recurso que não está lá.

Essa instalação coloca apenas as skills, não os wrappers de comando. Chame uma skill pelo nome do jeito do seu harness: `/ot-intent` no Claude Code, `$ot-intent` ou o seletor `/skills` no Codex, ou, em qualquer harness, um pedido simples como `Use a skill ot-intent para <objetivo>`.

## Instalar a partir de um checkout

Para desenvolver o pacote, ou manter links para um checkout local, clone o repositório e execute na raiz dele:

```bash
./install.sh
```

O script cria links de cada diretório `skills/ot-*` e de cada wrapper `commands/ot-*.md` nos diretórios do seu harness. Ele é idempotente: rodar de novo recria os links.

| Destino | Padrão | Flag |
|---|---|---|
| Skills do harness | `~/.agents/skills` | `--agents-dir DIR` |
| Espelho de skills do Claude Code | `~/.claude/skills` | `--claude-dir DIR` |
| Wrappers de comando | `~/.claude/commands` | `--commands-dir DIR` |

- O espelho do Claude Code só é atualizado quando o diretório pai do espelho existe (por padrão, quando `~/.claude/` existe). Cada entrada do espelho é um link relativo para a entrada no diretório de skills do harness.
- Quando você passa `--claude-dir` sem `--commands-dir`, os wrappers vão para um diretório `commands` ao lado desse diretório de skills.
- Qualquer outro argumento interrompe o script com `ERROR: unknown argument`.

Para disponibilizar as skills também ao Kiro mantendo a instalação padrão, rode uma segunda vez com o diretório dele:

```bash
./install.sh --agents-dir "$HOME/.kiro/skills"
```

Esse diretório recebe links para o mesmo checkout, não uma cópia independente.

## O que é instalado

Sete skills, cada uma com o procedimento que o agente segue e os recursos que ela possui:

| Skill | Possui |
|---|---|
| `ot-init` | `scripts/on-track-init.sh`, `scripts/on-track-index.sh`, `assets/AGENTS-snippet.md` |
| `ot-intent` | `assets/intent.md`, `assets/ref.md` |
| `ot-spec` | `scripts/on-track-gate.sh`, `assets/spec.md`, `assets/tasks.md`, `assets/decisions.md` |
| `ot-implement` | Só o seu procedimento |
| `ot-research` | `assets/research.md` |
| `ot-assess` | `assets/assessment.md` |
| `ot-handoff` | `assets/handoff.md` |

A instalação pelo checkout também cria links para sete wrappers de comando, de `commands/ot-init.md` a `commands/ot-handoff.md`. Cada um manda o agente executar a skill de mesmo nome. Os nomes `ot-*` são os nomes das skills, não aliases.

O instalador do checkout grava links nos diretórios configurados do harness. Execute `ot-init` em um projeto de destino para criar a árvore `on-track/`, o bloco gerenciado e o índice dele (veja [Sua primeira track](first-track.md)).

## Atualizar

- Com `npx skills`, rode de novo o mesmo comando `npx skills add` para instalar a versão atual.
- Com um checkout, atualize o repositório com pull; os links já apontam para ele. Rode `./install.sh` de novo quando skills ou comandos forem adicionados ou renomeados.

Depois de uma atualização que muda o bloco gerenciado, rode `ot-init` de novo em cada projeto para renovar o bloco no `AGENTS.md`. Ele é idempotente e nunca duplica o bloco.

Se você usava uma versão anterior com outros nomes de skill, remova essas entradas do seu harness depois de reinstalar. Projetos criados antes da renomeação precisam dos passos de [Migração do fast-track-ai](migrating.md).
