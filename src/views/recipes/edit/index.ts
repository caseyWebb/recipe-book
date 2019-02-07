import { Route, IContext } from '@profiscience/knockout-contrib'

export const edit = createRoute({
  path: '/:id/edit',
  title: 'Edit'
})

export const create = createRoute({
  path: '/new',
  title: 'New',
  with: {
    params: {
      id: null
    }
  } as IContext
})

function createRoute(opts: { path: string; title: string; with?: any }) {
  return new Route(opts.path, {
    title: opts.title,
    with: opts.with,
    component: () => ({
      template: import('./template.html'),
      viewModel: import('./viewModel')
    }),
    components: () => ({
      'ingredients-form-widget': import('components/ingredients-form-widget') as any
    })
  })
}
