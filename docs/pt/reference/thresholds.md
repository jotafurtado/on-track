---
title: Limiares
description: Quando um assessment se justifica e quando não, e quando uma decisão vira ADR e quando não.
---

# Limiares

Esta página responde duas perguntas que o agente resolve sozinho: quando rodar um assessment auxiliar e quando registrar uma decisão como ADR (Architecture Decision Record). Os dois limiares são altos de propósito, para que o registro acompanhe o tamanho do pedido. São os mesmos em todas as vias e o Off Road não os rebaixa.

## Limiar de assessment

Durante o intent, o agente roda `ot-assess` como passo auxiliar só quando o escopo ou o desenho depende de uma condição do sistema existente que a leitura dos arquivos relevantes não resolve. Isso acontece quando resolver exige pelo menos um destes:

- rodar comandos;
- medir comportamento;
- pesar evidência entre vários subsistemas;
- ou quando a conclusão enfrenta contraevidência material.

O agente avisa em uma frase que vai rodar o assessment, não pede licença e cita o slug do assessment na lista `assessments:` do intent, nunca em `research:`.

### O que não justifica assessment

| Situação | Para onde vai |
|---|---|
| Fato obtido lendo arquivos | `Verified by the agent` no intent, com o caminho que o mostrou |
| Fato obtido rodando um comando | `Verified by the agent` no intent, com o comando |
| Premissa adotada sem checar | `Unverified assumptions` no intent; verificada antes de uma task depender dela |

O usuário sempre pode pedir um assessment diretamente. Um pedido de só avaliação vai para `ot-assess` sem track; veja [Classes de pedido](request-classes.md).

### Gatilho de research, para comparar

Research tem outro gatilho. O agente roda `ot-research` quando uma decisão de escopo, desenho ou aceite no intent depende de um fato externo (comportamento de versão, contrato de API, configuração, limite, licença ou preço) que não está verificado no repositório nem nas fontes já lidas na sessão. Familiaridade com a tecnologia não dispensa o gatilho quando a decisão depende desse fato.

## Limiar de ADR

O limiar de ADR vale em todas as vias: Express, Highway e Off Road. Uma decisão só se qualifica quando as duas condições valem:

1. **Foi uma escolha real.** Pelo menos uma alternativa foi pesada e rejeitada por um motivo declarado.
2. **Errar custa caro.** Reverter exige mais que reverter um diff (migração de dados, mudança coordenada em consumidores, compromisso externo), ou um leitor futuro provavelmente a desfaria sem o motivo registrado.

### O que não se qualifica

- Durabilidade sozinha.
- Preferência ou instrução do usuário repetida.
- Escolha local, fácil de reverter ou óbvia.

Preferência do usuário sem alternativa pesada é restrição no intent, não ADR.

### De onde vem uma ADR

| Etapa | Gatilho | O que o agente faz |
|---|---|---|
| Intent | O usuário toma uma decisão qualificada na conversa | Grava a próxima `on-track/decisions/<NNN-slug>.md` numerada e cita o slug na lista `decisions:` do intent |
| Spec | O usuário toma uma decisão qualificada | Grava a ADR sem pedido separado, citando refs, research, assessments, URLs de fonte ou caminhos do repositório quando houver |
| Implement | O usuário toma uma decisão qualificada | Grava a ADR; se ela conflita com a spec ou as tasks aprovadas, ou as muda materialmente, as duas voltam a `draft` e exigem nova aprovação (veja [Ciclo](cycle.md#limites-da-implementacao)) |
| Express | Surge uma decisão qualificada | Grava só essa ADR e regenera o índice; o caminho da ADR entra em `files` da crumb |

Uma ADR nasce `accepted`. Substituir uma grava a substituta como a próxima ADR numerada em `accepted` e marca a original como `superseded`, com `superseded_by`, sem mudar o texto original. O template da ADR está em [Artefatos](artifacts.md#decisao-adr).
