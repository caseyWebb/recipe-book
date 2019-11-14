import { openDB, DBSchema, IDBPTransaction, IDBPDatabase } from 'idb'
import { Elm } from './Main'

const VERSION = 1

type ExtractElmPortData<
  TProp extends keyof Elm.Main.App['ports']
> = Elm.Main.App['ports'][TProp] extends {
  subscribe(callback: (data: infer TData) => void): void
}
  ? TData
  : Elm.Main.App['ports'][TProp] extends {
      send(data: infer TData): void
    }
  ? TData
  : unknown

/* Types used in DB */
type RecipeSchema = {
  slug: string
  name: string
  ingredients: {
    ingredientId: string
    quantity: number
    unit: string
  }[]
}

type IngredientSchema = {
  name: string
  section: string
}

/* Types used in Elm app */
type Recipe = ExtractElmPortData<'saveRecipe'>
type Ingredient = IngredientSchema

interface DB extends DBSchema {
  recipes: {
    key: string
    value: RecipeSchema
  }
  ingredients: {
    key: string
    value: IngredientSchema
    indexes: { name: string }
  }
}

async function getDB(): Promise<IDBPDatabase<DB>> {
  return await openDB<DB>('recipe-book', VERSION, {
    upgrade(db) {
      db.createObjectStore('recipes', { keyPath: 'slug' })
      const ingredientStore = db.createObjectStore('ingredients', {
        keyPath: 'name'
      })
      ingredientStore.createIndex('name', 'name')
    }
  })
}

export async function saveRecipe(recipe: Recipe): Promise<null> {
  const db = await getDB()
  const ingredientDocs = recipe.ingredients
  const recipeDoc = Object.assign({}, recipe, {
    ingredients: recipe.ingredients.map((i) => ({
      ingredientId: i.name,
      quantity: 0,
      unit: ''
    }))
  })
  await Promise.all([
    db.put('recipes', recipeDoc),
    ...ingredientDocs.map((i) => db.put('ingredients', i))
  ])
  return null
}

export async function listRecipes(): Promise<{
  count: number
  recipes: Recipe[]
}> {
  const db = await getDB()
  const tx = db.transaction(['recipes', 'ingredients'], 'readonly')
  const recipesStore = tx.objectStore('recipes')
  const count = await recipesStore.count()
  const recipes: Recipe[] = []
  let cursor = await recipesStore.openCursor(undefined)
  while (cursor) {
    const recipe = cursor.value
    recipes.push(await _joinIngredients(recipe, tx))
    cursor = await cursor.continue()
  }
  await tx.done
  return { count, recipes }
}

export async function fetchRecipeById(id: string): Promise<string | Recipe> {
  const db = await getDB()
  const tx = db.transaction(['recipes', 'ingredients'])
  const recipesStore = tx.objectStore('recipes')
  const recipe = await recipesStore.get(id)
  if (!recipe) return 'Recipe not found'
  const ret = await _joinIngredients(recipe, tx)
  await tx.done
  return ret
}

export async function listIngredients(): Promise<Ingredient[]> {
  const db = await getDB()
  const tx = db.transaction('ingredients', 'readonly')
  const ingredientsStore = tx.objectStore('ingredients')
  const ingredients: Ingredient[] = []
  let cursor = await ingredientsStore
    .index('name')
    .openCursor(undefined, 'nextunique')
  while (cursor) {
    ingredients.push(cursor.value)
    cursor = await cursor.continue()
  }
  await tx.done
  return ingredients
}

async function _joinIngredients(
  recipe: RecipeSchema,
  tx: IDBPTransaction<DB, ('recipes' | 'ingredients')[]>
): Promise<Recipe> {
  const ingredientsStore = tx.objectStore('ingredients')
  const ingredients = await Promise.all(
    recipe.ingredients.map(async (i) => {
      const ingredient = await ingredientsStore.get(i.ingredientId)
      if (!ingredient) throw new Error()
      return {
        quantity: i.quantity,
        unit: i.unit,
        ...ingredient
      }
    })
  )
  return {
    ...recipe,
    ingredients
  }
}
