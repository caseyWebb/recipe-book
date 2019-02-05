import { Route, IContext } from '@profiscience/knockout-contrib'

const component = () => ({
  template: import('./template.html'),
  viewModel: import('./viewModel')
})

export const edit = new Route('/:id/edit', {
  title: 'Edit',
  component
})

export const create = new Route('/new', {
  title: 'New',
  component,
  with: {
    params: {
      id: null
    }
  } as IContext
})
