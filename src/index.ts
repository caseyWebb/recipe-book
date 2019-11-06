import { Elm } from './Main'
import * as recipe from './Data/Recipe'

const app = Elm.Main.init({
  flags: null,
  node: document.body
})

callAndRespond(app.ports.fetchRecipes, app.ports.receiveRecipes, recipe.list)

function callAndRespond<T>(
  call: { subscribe(cb: () => unknown): void },
  respond: { send(data: T): void },
  resolve: () => Promise<T>
): void {
  call.subscribe(async () => respond.send(await resolve()))
}
