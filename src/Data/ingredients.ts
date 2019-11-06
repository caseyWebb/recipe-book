import PouchDB from 'pouchdb'
import pouchDbFind from 'pouchdb-find'

PouchDB.plugin(pouchDbFind)

const db = new PouchDB<Ingredient>('ingredients')

export type Ingredient = {
  readonly _id: string
  readonly _ref: string
  name: string
  unitType: string
  groceryStoreSection: string
  note: string
}

type IngredientQuery = {
  search?: string
}

export async function fetchById(id: string) {
  return await db.get(id)
}

export async function save(doc: Ingredient) {
  await db.put(doc)
}

export async function list(query: IngredientQuery = {}) {
  return await db.find({
    selector: { name: { $regex: new RegExp(query.search || '', 'i') } }
  })
}
