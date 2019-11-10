import { Elm } from './Main'
import * as db from './db'

import './Styles/Main.css'

const app = Elm.Main.init({
  flags: null,
  node: document.body
})

callAndRespond(app.ports.fetchRecipes, app.ports.receiveRecipes, db.listRecipes)
callAndRespond(app.ports.saveRecipe, app.ports.recipeSaved, db.saveRecipe)
callAndRespond(
  app.ports.findRecipeById,
  app.ports.receiveRecipe,
  db.fetchRecipeById
)

function callAndRespond<TIn, TOut>(
  call: { subscribe(cb: (arg: TIn) => unknown): void },
  respond: { send(data: TOut): void },
  resolve: (arg: TIn) => Promise<TOut>
): void {
  call.subscribe(async (data) => respond.send(await resolve(data)))
}
