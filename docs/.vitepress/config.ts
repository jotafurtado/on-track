import { defineConfig, type DefaultTheme } from 'vitepress'

const englishSidebar: DefaultTheme.SidebarItem[] = [
  {
    text: 'Getting started',
    items: [
      { text: 'Installation', link: '/getting-started/installation' },
      { text: 'Your first track', link: '/getting-started/first-track' },
      { text: 'Migrating from fast-track-ai', link: '/getting-started/migrating' }
    ]
  },
  {
    text: 'Guides',
    items: [
      { text: 'Express changes', link: '/guides/express-changes' },
      { text: 'Highway signals', link: '/guides/highway-signals' },
      { text: 'Off Road', link: '/guides/off-road' },
      { text: 'Questions and delegation', link: '/guides/questions-and-delegation' },
      { text: 'Supporting artifacts', link: '/guides/supporting-artifacts' },
      { text: 'Committing', link: '/guides/committing' }
    ]
  },
  {
    text: 'Reference',
    items: [
      { text: 'Request classes', link: '/reference/request-classes' },
      { text: 'Cycle', link: '/reference/cycle' },
      { text: 'Signals', link: '/reference/signals' },
      { text: 'Artifacts', link: '/reference/artifacts' },
      { text: 'Thresholds', link: '/reference/thresholds' },
      { text: 'Commands', link: '/reference/commands' },
      { text: 'Validation', link: '/reference/validation' },
      { text: 'Agent rules', link: '/reference/agent-rules' }
    ]
  },
  {
    text: 'Concepts',
    items: [
      { text: 'Why On Track', link: '/concepts/why-on-track' },
      { text: 'Design choices', link: '/concepts/design-choices' }
    ]
  }
]

const portugueseSidebar: DefaultTheme.SidebarItem[] = [
  {
    text: 'Primeiros Passos',
    items: [
      { text: 'Instalação', link: '/pt/getting-started/installation' },
      { text: 'Sua Primeira Track', link: '/pt/getting-started/first-track' },
      { text: 'Migração do fast-track-ai', link: '/pt/getting-started/migrating' }
    ]
  },
  {
    text: 'Guias',
    items: [
      { text: 'Mudanças Express', link: '/pt/guides/express-changes' },
      { text: 'Sinais do Highway', link: '/pt/guides/highway-signals' },
      { text: 'Off Road', link: '/pt/guides/off-road' },
      { text: 'Perguntas e Delegação', link: '/pt/guides/questions-and-delegation' },
      { text: 'Artefatos de Apoio', link: '/pt/guides/supporting-artifacts' },
      { text: 'Commit', link: '/pt/guides/committing' }
    ]
  },
  {
    text: 'Referência',
    items: [
      { text: 'Classes de Pedido', link: '/pt/reference/request-classes' },
      { text: 'Ciclo', link: '/pt/reference/cycle' },
      { text: 'Sinais', link: '/pt/reference/signals' },
      { text: 'Artefatos', link: '/pt/reference/artifacts' },
      { text: 'Limiares', link: '/pt/reference/thresholds' },
      { text: 'Comandos', link: '/pt/reference/commands' },
      { text: 'Validação', link: '/pt/reference/validation' },
      { text: 'Regras para Agentes', link: '/pt/reference/agent-rules' }
    ]
  },
  {
    text: 'Conceitos',
    items: [
      { text: 'Por Que On Track', link: '/pt/concepts/why-on-track' },
      { text: 'Escolhas de Design', link: '/pt/concepts/design-choices' }
    ]
  }
]

const englishNav: DefaultTheme.NavItem[] = [
  { text: 'Getting started', link: '/getting-started/installation' },
  { text: 'Guides', link: '/guides/express-changes' },
  { text: 'Reference', link: '/reference/request-classes' },
  { text: 'Concepts', link: '/concepts/why-on-track' }
]

const portugueseNav: DefaultTheme.NavItem[] = [
  { text: 'Primeiros Passos', link: '/pt/getting-started/installation' },
  { text: 'Guias', link: '/pt/guides/express-changes' },
  { text: 'Referência', link: '/pt/reference/request-classes' },
  { text: 'Conceitos', link: '/pt/concepts/why-on-track' }
]

export default defineConfig({
  title: 'On Track Method',
  description: 'A lightweight, agent-driven software development life cycle.',
  base: '/on-track/',
  srcExclude: ['**/node_modules/**'],
  themeConfig: {
    socialLinks: [{ icon: 'github', link: 'https://github.com/jotafurtado/on-track' }],
    search: {
      provider: 'local',
      options: {
        locales: {
          pt: {
            translations: {
              button: { buttonText: 'Buscar', buttonAriaLabel: 'Buscar' },
              modal: {
                displayDetails: 'Mostrar lista detalhada',
                resetButtonTitle: 'Limpar a busca',
                backButtonTitle: 'Fechar a busca',
                noResultsText: 'Nenhum resultado para',
                footer: {
                  selectText: 'para selecionar',
                  navigateText: 'para navegar',
                  closeText: 'para fechar'
                }
              }
            }
          }
        }
      }
    }
  },
  locales: {
    root: {
      label: 'English',
      lang: 'en',
      themeConfig: {
        nav: englishNav,
        sidebar: englishSidebar
      }
    },
    pt: {
      label: 'Português (Brasil)',
      lang: 'pt-BR',
      link: '/pt/',
      description: 'Um ciclo de desenvolvimento de software leve, conduzido por agentes.',
      themeConfig: {
        nav: portugueseNav,
        sidebar: portugueseSidebar,
        outline: { label: 'Nesta Página' },
        docFooter: { prev: 'Página Anterior', next: 'Próxima Página' },
        darkModeSwitchLabel: 'Aparência',
        lightModeSwitchTitle: 'Mudar para o tema claro',
        darkModeSwitchTitle: 'Mudar para o tema escuro',
        sidebarMenuLabel: 'Menu',
        returnToTopLabel: 'Voltar ao Topo',
        langMenuLabel: 'Mudar o Idioma'
      }
    }
  }
})
