import { openDB, DBSchema } from 'idb'

const VERSION = 1

type ForeignKey<T extends Record<string, any>, TProp extends keyof T> = Omit<
  T,
  TProp
> &
  Record<TProp, string[]>

type Recipe = {
  slug: string
  name: string
  ingredients: Ingredient[]
}

type Ingredient = {
  name: string
}

interface DB extends DBSchema {
  recipes: {
    key: string
    value: ForeignKey<Recipe, 'ingredients'>
  }
  ingredients: {
    key: string
    value: Ingredient
    indexes: { name: string }
  }
}

async function getDB() {
  return await openDB<DB>('recipe-book', VERSION, {
    upgrade(db) {
      const recipeStore = db.createObjectStore('recipes', { keyPath: 'slug' })
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
    ingredients: recipe.ingredients.map((i) => i.name)
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
  await tx.done
  if (!recipe) return 'Recipe not found'
  return {
    ...recipe,
    ingredients: (await Promise.all(
      recipe.ingredients.map((i) => ingredientsStore.get(i))
    )).filter((i) => typeof i !== 'undefined') as Ingredient[]
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
