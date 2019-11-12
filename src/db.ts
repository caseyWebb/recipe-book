import { openDB, DBSchema } from 'idb'
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

type Recipe = ExtractElmPortData<'saveRecipe'>

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

async function getDB() {
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
  const tx = await db.transaction(['recipes', 'ingredients'], 'readonly')
  const recipesStore = tx.objectStore('recipes')
  const ingredientsStore = tx.objectStore('ingredients')
  const count = await recipesStore.count()
  const recipes: Recipe[] = []
  let cursor = await recipesStore.openCursor(undefined)
  while (cursor) {
    recipes.push({
      ...cursor.value,
      ingredients: (await Promise.all(
        cursor.value.ingredients.map((i) => ingredientsStore.get(i))
      )).filter((i) => typeof i !== 'undefined') as Ingredient[]
    })
    cursor = await cursor.continue()
  }
  await tx.done
  return { count, recipes }
}

export async function fetchRecipeById(id: string): Promise<string | Recipe> {
  const db = await getDB()
  const tx = await db.transaction(['recipes', 'ingredients'])
  const recipesStore = await tx.objectStore('recipes')
  const ingredientsStore = await tx.objectStore('ingredients')
  const recipe = await recipesStore.get(id)
  if (!recipe) return 'Recipe not found'
  const ingredients = (await Promise.all(
    recipe.ingredients.map((i) => ingredientsStore.get(i))
  )).filter((i) => typeof i !== 'undefined') as Ingredient[]
  await tx.done
  return {
    ...recipe,
    ingredients
  }
}

export async function listIngredients(): Promise<string[]> {
  const db = await getDB()
  const tx = await db.transaction('ingredients', 'readonly')
  const ingredientsStore = tx.objectStore('ingredients')
  const ingredients: string[] = []
  let cursor = await ingredientsStore
    .index('name')
    .openCursor(undefined, 'nextunique')
  while (cursor) {
    ingredients.push(cursor.value.name)
    cursor = await cursor.continue()
  }
  await tx.done
  return ingredients
}
