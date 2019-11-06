import { Elm } from './Main'
import * as recipes from './data/recipes'

const app = Elm.Main.init({
  flags: null,
  node: document.body
})

callAndRespond(app.ports.fetchRecipes, app.ports.receiveRecipes, recipes.list)

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
