---
layout: home
title: On Track Method
description: A lightweight, agent-driven software development life cycle that keeps records proportional to the size of each request.
hero:
  name: On Track Method
  text: Keep your coding agent on track.
  tagline: You set the direction and give the signals. The agent documents, plans, implements, and validates.
  image:
    light: /brand/on-track-mark-on-light.svg
    dark: /brand/on-track-mark-on-dark.svg
    alt: On Track Method mark, a route from a start dot through a lane switch to a green station
  actions:
    - theme: brand
      text: Quick Start
      link: /getting-started/quick-start
    - theme: alt
      text: Why On Track?
      link: /concepts/why-on-track
    - theme: alt
      text: GitHub
      link: https://github.com/jotafurtado/on-track
---

<div class="ot-home">

<section class="ot-split">
  <div class="ot-what">
    <p class="ot-eyebrow">What it is</p>
    <h2>A lightweight method for working with coding agents.</h2>
    <p>A package of skills and a block in your <code>AGENTS.md</code>. It runs in Claude Code, Codex, and other harnesses that support skills, and it keeps its records in your repository as plain Markdown.</p>
  </div>
  <div class="ot-who">
    <p class="ot-eyebrow">Who decides what</p>
    <div class="ot-role ot-role-human">
      <h3><span class="ot-dot"></span>You</h3>
      <ul class="ot-chips">
        <li>Set the direction</li>
        <li>Answer the blocking questions</li>
        <li>Give the signal at each Highway stop</li>
      </ul>
    </div>
    <div class="ot-role ot-role-agent">
      <h3><span class="ot-dot"></span>The agent</h3>
      <ul class="ot-chips">
        <li>Classifies the request</li>
        <li>Investigates</li>
        <li>Documents the <em>intent</em></li>
        <li>Plans the <em>spec</em> and tasks</li>
        <li>Implements</li>
        <li>Validates and reviews</li>
        <li>Reports</li>
      </ul>
    </div>
  </div>
</section>

![Three lanes. Express, the fastest way: implement, check, crumb, and report, with no stops. Highway, the default: intent, spec, implement, and ship, with your signal after each stage. Off Road, for uncharted terrain: intent and spec with more questions, joining the Highway when the Spec is approved. A signal of . proceeds, x stops, and any other reply revises the stage.](images/en/lanes.png)

<div class="ot-lanes">
  <a class="ot-lane ot-lane-express" href="./guides/express-changes.html">
    <p class="ot-eyebrow">The fastest way</p>
    <h3>Express</h3>
    <p>For a small, reversible edit. The agent implements it, checks it, leaves a local note called a <em>crumb</em> for your commit, and reports. No stops.</p>
  </a>
  <a class="ot-lane ot-lane-highway" href="./guides/highway-signals.html">
    <p class="ot-eyebrow">The default</p>
    <h3>Highway</h3>
    <p>For every other change. The <em>intent</em> says what changes and why, the <em>spec</em> lays out the plan and tasks, and the implementation delivers. Each stage ends at your signal.</p>
  </a>
  <a class="ot-lane ot-lane-offroad" href="./guides/off-road.html">
    <p class="ot-eyebrow">Uncharted terrain</p>
    <h3>Off Road</h3>
    <p>For a request with no map yet. The agent also brings you the design choices it would otherwise make alone, until the Spec is approved. It can suggest this way itself.</p>
  </a>
</div>

<section class="ot-cta">
  <h2>Ready to put your agent on track?</h2>
  <p>Install the package, initialize your project, and make your first change in a few minutes.</p>
  <a class="ot-button" href="./getting-started/quick-start.html">Get Started</a>
</section>

</div>
