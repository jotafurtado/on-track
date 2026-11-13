---
title: Perguntas e delegação
description: Quando o agente pergunta no Highway, como funciona uma rodada de perguntas e como delegar uma decisão com "decida você".
---

# Perguntas e delegação

Esta página responde quando o agente pergunta algo no Highway, qual é o formato de uma rodada de perguntas, como as etapas de intent e spec diferem e o que acontece quando você responde "decida você".

## Investigar primeiro

O agente investiga antes de perguntar. Ele nunca pergunta o que o repositório ou um comando podem responder: lê os arquivos, faz a inspeção de que precisa e registra o que encontrou. No intent, um fato que ele confirmou vai para `Assumed state` > `Verified by the agent`, com o caminho ou o comando que o mostrou.

## Perguntas bloqueadoras

No Highway o agente faz só perguntas bloqueadoras. Uma pergunta é bloqueadora quando a resposta muda um destes:

- escopo,
- segurança,
- persistência,
- integração externa,
- arquitetura,
- aceitação.

Toda outra escolha o agente resolve sozinho, ou registra como pergunta em aberto no intent, ou transforma em tarefa na spec. Para ser consultado também sobre essas escolhas, use o [Off Road](off-road.md).

## A rodada

Uma rodada tem no máximo quatro perguntas, feitas pela ferramenta de perguntas do host quando ela existe. Cada pergunta:

- nomeia a decisão que destrava,
- oferece opções,
- coloca a recomendação do agente primeiro.

```text
Armazenamento dos cadastros (destrava: persistência dos envios do formulário)
  1. Enviar ao provedor de newsletter atual (recomendado)
  2. Gravar em uma nova tabela do banco
  3. Mandar por e-mail para a caixa da equipe
```

Sinais não são perguntas. A parada no fim de cada etapa é lida como texto simples, nunca pela ferramenta de perguntas (veja [Sinais do Highway](highway-signals.md)).

## Intent: uma rodada

A etapa de intent tem uma rodada. O agente faz nela todas as perguntas bloqueadoras, até quatro, e escreve cada resposta no corpo do intent.

- Uma pergunta bloqueadora além do limite vai para `Open questions`, para a etapa de spec resolver.
- Qualquer outra pergunta o agente resolve sozinho ou deixa em `Open questions`.
- Cada entrada em `Open questions` é uma pergunta de verdade: termina com ponto de interrogação e nomeia a decisão que destrava, com um responsável quando houver.

## Spec: quantas rodadas forem necessárias

A etapa de spec lê as `Open questions` do intent e classifica cada uma:

| Tipo | O que acontece |
|---|---|
| Bloqueadora | Resolvida antes do resumo, em quantas rodadas de até quatro forem necessárias. O resumo e `. para implementar` ficam retidos enquanto qualquer pergunta bloqueadora estiver sem resposta. |
| Adiável | A resposta não bloqueia a arquitetura geral nem o escopo. Vira uma tarefa delimitada cujo `Validate` nomeia a resposta ou o artefato esperado, em um grupo que os grupos dependentes listam em `(depends: ...)`. |

Sem delegação, o agente não inventa resposta para nenhum dos dois tipos.

## "Decida você"

Você pode responder qualquer pergunta com "decida você". Isso é uma delegação: o agente decide, registra a decisão e a mostra para você vetar.

| Etapa | Onde a decisão delegada é registrada |
|---|---|
| Intent | `intent.md`, em `Constraints` > `Proposed by the agent`, marcada `(delegated)` |
| Spec | `spec.md`, em `Constraints`, marcada `(delegated)` |

```markdown
### Proposed by the agent
- Signup submissions go to the existing newsletter provider. (delegated)
```

## Vetar uma decisão delegada

As decisões delegadas aparecem no resumo da etapa, antes da localização da track e da linha de próximo passo. Para vetar uma, responda com a mudança que você quer em vez de `.`: qualquer resposta assim é um sinal amarelo, então o agente revisa o intent ou a spec e mostra o resumo de novo. No resumo do intent, as outras restrições que o agente propôs por conta própria são listadas do mesmo jeito, para o mesmo veto. Uma restrição proposta pelo agente só é permitida quando omiti-la traz risco de perda de dados, problema de segurança ou quebra do resultado pedido. Ela deve nomear esse risco e não pode ampliar o resultado. Decisões delegadas, marcadas `(delegated)`, são as outras entradas permitidas.
