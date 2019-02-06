import { Route } from '@profiscience/knockout-contrib'

import { create, edit } from './edit'
import { list } from './list'
import { show } from './show'

export default new Route('/', {
  title: 'Recipes',
  children: [create, edit, list, show]
})
