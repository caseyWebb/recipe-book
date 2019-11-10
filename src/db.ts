import { openDB, DBSchema } from 'idb'

const VERSION = 1

interface DB extends DBSchema {
  recipes: {
    key: string
    value: Recipe
  }
}

interface Recipe {
  slug: string
  name: string
}

async function getDB() {
  return await openDB<DB>('recipe-book', VERSION, {
    upgrade(db) {
      db.createObjectStore('recipes', { keyPath: 'slug' })
    }
  })
}

export async function saveRecipe(recipe: Recipe): Promise<null> {
  const db = await getDB()
  await db.put('recipes', recipe)
  return null
}

export async function listRecipes(): Promise<{
  count: number
  recipes: Recipe[]
}> {
  const db = await getDB()
  const count = await db.count('recipes')
  const recipes = await db.getAll('recipes')
  return { count, recipes }
}

export async function fetchRecipeById(id: string) {
  const db = await getDB()
  return await db.get('recipes', id)
}
