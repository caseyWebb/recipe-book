import {
  Route,
  Router,

  /**
   * Types
   */
  LifecycleMiddleware,

  /**
   * Middleware
   */
  flashMessageMiddleware,
  createProgressBarMiddleware,
  createScrollPositionMiddleware,

  /**
   * Plugins
   */
  childrenRoutePlugin,
  componentRoutePlugin,
  componentsRoutePlugin,
  componentInitializerRoutePlugin,
  createTitleRoutePlugin,
  withRoutePlugin
} from '@profiscience/knockout-contrib'

import { overlayLoader } from 'lib'

/**
 * Middleware
 */
const overlayMiddleware: LifecycleMiddleware = () => ({
  beforeRender() {
    overlayLoader.show()
  },
  afterRender() {
    overlayLoader.hide()
  }
})

Router.use(
  overlayMiddleware,

  flashMessageMiddleware,

  createProgressBarMiddleware({
    color: '#fff' // @TODO make configurable. store in globals (like other dynamic css, e.g. navbar)
  }),

  createScrollPositionMiddleware({
    scrollTo: (x, y) =>
      scrollTo({
        top: y,
        left: 0,
        behavior: 'smooth'
      })
  })
)

/**
 * Plugins
 */
Route.usePlugin(
  withRoutePlugin,
  childrenRoutePlugin,
  componentRoutePlugin,
  componentsRoutePlugin,
  componentInitializerRoutePlugin,
  createTitleRoutePlugin(
    (titles: string[]) => `recipe-book | ${titles.join(' > ')}`
  )
)

/**
 * Webpack voodoo to dynamically load all of the routes in ./views
 */
const context = require.context('./views', true, /\.\/[^/_]+\/index\.ts$/)
const routes = context
  .keys()
  .map(context)
  .map(({ default: r }) => r)

Router.useRoutes(routes)
