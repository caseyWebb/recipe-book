import { Route } from '@profiscience/knockout-contrib'

export const list = new Route('/', {
  component: () => ({
    template: import('./template.html'),
    viewModel: import('./viewModel')
  })
})
