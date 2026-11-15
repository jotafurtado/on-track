---
layout: home
title: On Track Method
description: Um ciclo de desenvolvimento de software leve, conduzido por agentes, que mantém o registro proporcional ao tamanho de cada pedido.
hero:
  name: On Track Method
  text: Seu agente de código nos trilhos.
  tagline: Você define o rumo e dá os sinais. O agente documenta, planeja, implementa e valida.
  image:
    light: /brand/on-track-mark-on-light.svg
    dark: /brand/on-track-mark-on-dark.svg
    alt: Marca do On Track Method, uma rota que sai de um ponto, passa por uma troca de faixa e chega a uma estação verde
  actions:
    - theme: brand
      text: Começo Rápido
      link: /pt/getting-started/quick-start
    - theme: alt
      text: Por Que On Track?
      link: /pt/concepts/why-on-track
    - theme: alt
      text: GitHub
      link: https://github.com/jotafurtado/on-track
---

<div class="ot-home">

<section class="ot-split">
  <div class="ot-what">
    <p class="ot-eyebrow">O que é</p>
    <h2>Um método leve para trabalhar com agentes de código.</h2>
    <p>Um pacote de skills e um bloco no seu <code>AGENTS.md</code>. Funciona no Claude Code, no Codex e em outros harnesses com suporte a skills, e guarda os registros no seu repositório, em Markdown simples.</p>
  </div>
  <div class="ot-who">
    <p class="ot-eyebrow">Quem decide o quê</p>
    <div class="ot-role ot-role-human">
      <h3><span class="ot-dot"></span>Você</h3>
      <ul class="ot-chips">
        <li>Define o rumo</li>
        <li>Responde às perguntas bloqueadoras</li>
        <li>Dá o sinal em cada parada da Highway</li>
      </ul>
    </div>
    <div class="ot-role ot-role-agent">
      <h3><span class="ot-dot"></span>O agente</h3>
      <ul class="ot-chips">
        <li>Classifica o pedido</li>
        <li>Investiga</li>
        <li>Documenta a <em>intent</em></li>
        <li>Planeja a <em>spec</em> e as tarefas</li>
        <li>Implementa</li>
        <li>Valida e revisa</li>
        <li>Relata</li>
      </ul>
    </div>
  </div>
</section>

![Três vias. Express, o caminho mais rápido: implementar, verificar, crumb e relatar, sem paradas. Highway, o padrão: intent, spec, implementar e chegada, com um sinal seu depois de cada etapa. Off Road, para terreno sem mapa: intent e spec com mais perguntas, entrando na Highway quando a Spec é aprovada. No sinal, ponto segue, x para e qualquer outra resposta revisa a etapa.](../images/pt/lanes.png)

<div class="ot-lanes">
  <a class="ot-lane ot-lane-express" href="./guides/express-changes.html">
    <p class="ot-eyebrow">O caminho mais rápido</p>
    <h3>Express</h3>
    <p>Para a edição pequena e reversível. O agente implementa, verifica, deixa uma nota local chamada <em>crumb</em> para o seu commit e relata. Sem paradas.</p>
  </a>
  <a class="ot-lane ot-lane-highway" href="./guides/highway-signals.html">
    <p class="ot-eyebrow">O padrão</p>
    <h3>Highway</h3>
    <p>Para toda outra mudança. A <em>intent</em> diz o que muda e por quê, a <em>spec</em> detalha o plano e as tarefas, e a implementação entrega. Cada etapa termina num sinal seu.</p>
  </a>
  <a class="ot-lane ot-lane-offroad" href="./guides/off-road.html">
    <p class="ot-eyebrow">Terreno sem mapa</p>
    <h3>Off Road</h3>
    <p>Para o pedido que ainda não tem mapa. O agente traz para você também as escolhas de desenho que faria sozinho, até a Spec ser aprovada. Ele mesmo pode sugerir esse caminho.</p>
  </a>
</div>

<section class="ot-cta">
  <h2>Pronto para pôr seu agente nos trilhos?</h2>
  <p>Instale o pacote, inicialize o projeto e faça sua primeira mudança em poucos minutos.</p>
  <a class="ot-button" href="./getting-started/quick-start.html">Primeiros Passos</a>
</section>

</div>
