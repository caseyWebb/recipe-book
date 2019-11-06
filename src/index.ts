import { Elm } from './Main'
import * as recipe from './Data/Recipe'

const app = Elm.Main.init({
  flags: null,
  node: document.body
})

callAndRespond(app.ports.fetchRecipes, app.ports.receiveRecipes, recipe.list)

interface Call {
  subscribe(cb: () => any): void
}

interface Response<T> {
  send(data: T): void
}

function callAndRespond<T>(
  call: Call,
  respond: Response<T>,
  resolve: () => Promise<T>
) {
  call.subscribe(async () => respond.send(await resolve()))
}
