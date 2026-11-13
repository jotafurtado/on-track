---
title: Regras para agentes
description: As regras que um agente segue num repositório que usa o On Track Method, como instaladas pelo bloco gerenciado no AGENTS.md.
---

# Regras para agentes

Esta página responde o que um agente precisa fazer num repositório que usa o método. `ot-init` instala estas regras como um bloco gerenciado no `AGENTS.md` do projeto. O bloco foi escrito para bastar sozinho, porque o agente o lê antes de qualquer skill carregar; cada skill também basta sozinha, sem o bloco. A lista abaixo repete o bloco em forma numerada, com links para as páginas que detalham cada regra.

1. Ler `on-track/INDEX.md` antes de procurar track ou artefato de apoio. Nunca varrer a árvore `on-track/` inteira para descobrir algo. Veja [Artefatos](artifacts.md#index-md).
2. Classificar cada pedido antes de alocar qualquer coisa. Separar o pedido composto em partes e tratar cada parte na própria via. Veja [Classes de pedido](request-classes.md).
3. A escolha explícita do usuário vence nos dois sentidos. Nomear `ot-intent`, ou pedir track ou intent, escolhe o Highway para uma edição. Pedir para fazer direto, ou sem track, escolhe a via Express.
4. Um pedido operacional (rodar, compilar, instalar, inspecionar ou relatar sem editar arquivo versionado) é executado direto, sem track nem artefato, e nunca é registrado dentro de uma track, nem como nota em `assets/`.
5. Uma edição só segue pela via Express quando os cinco critérios do Express valem. Anunciar a via em uma frase, implementar, rodar a verificação, gravar uma crumb e relatar. Não criar track nem outro arquivo em `on-track/` e não regenerar o índice. Não há sinal no fim.
6. Se um critério do Express deixar de valer, parar antes da edição que o quebra, nomear o critério que caiu e iniciar o Highway com `ot-intent`.
7. Toda outra edição, e toda edição com critério do Express incerto, segue pelo Highway: intent, spec, implement, ship. Ela começa como `intent.md` em `on-track/tracks/NNN-slug/`.
8. Encaminhar pedido de só pesquisa para `ot-research` e de só avaliação para `ot-assess`, sem track.
9. Não implementar no Highway até `spec.md` e `tasks.md` estarem ambos em `status: approved`. Aprovação do intent não é pré-requisito da spec.
10. No Highway, intent, spec e implement terminam com resumo de quatro tópicos e linha de próximo passo, e param à espera do sinal do usuário, lido como texto. Verde (`.` ou mensagem que só quer dizer siga) encadeia a próxima skill da mesma track e nunca muda o `status` do intent. Vermelho (`x` ou mensagem que só quer dizer pare) para, não muda `status`, não apaga nada e não desfaz código. Qualquer outra mensagem é amarelo: instrução para a skill atual, seguida do resumo de novo. A ferramenta de perguntas do host fica para perguntas, não para sinais. Veja [Sinais](signals.md).
11. Investigar primeiro e perguntar só o que o repositório ou um comando não responde. No Highway, fazer só perguntas bloqueadoras: uma rodada por etapa, no máximo quatro, cada uma nomeando a decisão que destrava, com opções e a recomendação do agente primeiro. "Decida você" delega; registrar a decisão delegada e listá-la no resumo para veto.
12. O Off Road vale do momento em que o usuário o pede até a aprovação da spec daquela track. Enquanto vale, a rodada do intent ou da spec também leva as escolhas que o agente resolveria sozinho, dentro do mesmo teto. Uma spec devolvida a `draft` depois da aprovação não religa o Off Road, a menos que o usuário peça de novo.
13. Gravar ADR só quando a decisão passa no limiar de ADR, em qualquer via. Na via Express, uma ADR qualificada é a única exceção de artefato: gravar só essa ADR e regenerar o índice. Veja [Limiares](thresholds.md).
14. Manter a raiz da track só com `intent.md`, `spec.md`, `tasks.md` e `assets/`. Arquivo solto é proibido; saídas auxiliares vão em `assets/`.
15. O intent fica em `draft` até `shipped`, `dropped` ou `superseded`. `dropped` abandona o trabalho sem implementação. `superseded` exige `superseded_by`; nunca inventá-lo. `shipped` é do implement, que pergunta antes de gravá-lo.
16. Gravar artefatos de apoio só nos seus lugares: `on-track/refs/<slug>.md`, `on-track/research/<slug>.md`, `on-track/assessments/<YYYY-MM-DD>-<slug>.md`, `on-track/decisions/<NNN-slug>.md`, `on-track/handoffs/<timestamp>-<slug>.md`.
17. Gravar a crumb depois da verificação do Express, passe ou não, em `on-track/crumbs/<YYYY-MM-DD-HHMMSSZ>-<slug>.md`, em UTC. Quando `on-track/crumbs/.gitignore` faltar, criá-lo com a única linha `*`. Veja [Artefatos](artifacts.md#crumb).
18. Para desfazer uma mudança Express, reverter só as próprias edições, trecho por trecho, para que o trabalho sem commit do usuário nos mesmos arquivos sobreviva, e apagar a crumb.
19. O método nunca faz commit sozinho. Ao preparar commits, ler as crumbs da mais antiga para a mais nova, agrupar o diff pelos `files` e `Changes` de cada crumb, escrever a mensagem a partir de `Request` e `Cause`, e depois apagar toda crumb consumida e toda crumb cujos arquivos já não diferem de `HEAD`. Veja [Commits](../guides/committing.md).
