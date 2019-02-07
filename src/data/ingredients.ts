import * as ko from 'knockout'
import PouchDB from 'pouchdb'
import * as pouchDBFind from 'pouchdb-find'
import {
  DataModelConstructorBuilder,
  QueryMixin
} from '@profiscience/knockout-contrib'
import { GroceryStoreSection, MeasurementUnitType } from 'enum'

PouchDB.plugin(pouchDBFind)

const db = new PouchDB<Ingredient>('ingredients')

export type Ingredient = {
  _id: string
  name: string
  unitType: MeasurementUnitType
  groceryStoreSection: GroceryStoreSection
  note: string
}

export class IngredientsCollection extends DataModelConstructorBuilder.Mixin(
  QueryMixin({
    search: ''
  })
)<{}> {
  public docs!: Ingredient[]

  protected async fetch() {
    const { rows } = await db.find()
    return {
      docs: rows
    }
  }
}

export class IngredientModel {
  public readonly _id!: string
  public readonly _ref!: string
  public readonly name!: string

  protected async fetch() {}
}
