import PouchDB from 'pouchdb'
import pouchDbFind from 'pouchdb-find'
// import { Ingredient, fetchById as fetchIngredientById } from './ingredients'

PouchDB.plugin(pouchDbFind)

const db = new PouchDB<RecipeSchema>('recipes')

type RecipeSchema = {
  readonly _id: string
  readonly _rev?: string
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

export type Recipe = Omit<RecipeSchema, 'ingredients' | '_id' | '_rev'> & {
  id: null | string
  rev: null | string
  // ingredients: {
  //   quantity: number
  //   unit: string
  //   ingredient: Ingredient
  // }[]
}

export async function fetchById(id: string): Promise<Recipe> {
  const doc = await db.get(id)
  // const ingredients = await Promise.all(
  //   doc.ingredients.map(async (i) => ({
  //     quantity: i.quantity,
  //     ingredient: fetchIngredientById(i.ingredientId)
  //   }))
  // )
  return {
    ...doc,
    id: doc._id,
    rev: doc._rev
    // ingredients
  }
}

export async function save(recipe: Recipe): Promise<null> {
  const doc = {
    _id:
      recipe.id === null
        ? recipe.name.toLowerCase().replace(/\s/g, '-')
        : recipe.id,
    _rev: recipe.rev || undefined,
    name: recipe.name
  }
  // if (doc._ref === null) delete doc._ref
  // const ingredients = recipe.ingredients.map((i) => ({
  //   quantity: i.quantity,
  //   unit: i.unit,
  //   ingredientId: i.ingredient._id
  // }))
  try {
    await db.put(doc)
  } catch (e) {
    return e.message
  }
  return null
}

export async function list(): Promise<{ count: number; recipes: Recipe[] }> {
  const { total_rows: count, rows } = await db.allDocs({ include_docs: true })
  const ret = {
    count,
    recipes: rows.map((r) => ({
      id: r.doc!._id,
      rev: r.doc!._rev,
      name: r.doc!.name
    }))
  }
  return ret
}
