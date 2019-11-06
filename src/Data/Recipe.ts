import PouchDB from 'pouchdb'
import pouchDbFind from 'pouchdb-find'
// import { Ingredient, fetchById as fetchIngredientById } from './ingredients'

PouchDB.plugin(pouchDbFind)

const db = new PouchDB<RecipeSchema>('recipes')

type RecipeSchema = {
  readonly _id: string
  readonly _ref: string
  name: string
  // ingredients: {
  //   quantity: number
  //   unit: string
  //   ingredientId: string
  // }[]

  // directions: string[]
  // favorite: boolean
  // onDeck: boolean
  // lastCooked: Date
  // dateCreated: Date
  // images: string[]
  // tags: string[]
  // difficulty: number (0-5, based on cleanup, time, etc.)
  // note: string
  // pairsWithRecipeIds: string[]
}

export type Recipe = Omit<RecipeSchema, 'ingredients'> & {
  // ingredients: {
  //   quantity: number
  //   unit: string
  //   ingredient: Ingredient
  // }[]
}

export async function fetchById(id: string) {
  const doc = await db.get(id)
  // const ingredients = await Promise.all(
  //   doc.ingredients.map(async (i) => ({
  //     quantity: i.quantity,
  //     ingredient: fetchIngredientById(i.ingredientId)
  //   }))
  // )
  return {
    ...doc
    // ingredients
  }
}

export async function save(recipe: Recipe) {
  const _id =
    recipe._id === null
      ? recipe.name.toLowerCase().replace(/\s/g, '-')
      : recipe._id
  // const ingredients = recipe.ingredients.map((i) => ({
  //   quantity: i.quantity,
  //   unit: i.unit,
  //   ingredientId: i.ingredient._id
  // }))
  await db.put({
    ...recipe,
    _id
    // ingredients
  })
}

export async function list() {
  const { total_rows: count, rows } = await db.allDocs({ include_docs: true })
  return {
    count,
    recipes: rows.map((r) => ({
      id: r.doc!._id,
      name: r.doc!.name
    }))
  }
}
