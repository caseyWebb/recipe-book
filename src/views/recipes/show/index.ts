import { Route } from '@profiscience/knockout-contrib'

export const show = new Route('/:id', {
  component: () => ({
    template: import('./template.html'),
    viewModel: import('./viewModel')
  })
})
