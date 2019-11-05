import * as ko from 'knockout'
import PouchDB from 'pouchdb'
import pouchDbFind from 'pouchdb-find'
import {
  DataModelConstructorBuilder,
  QueryMixin
} from '@profiscience/knockout-contrib'
import { GroceryStoreSection, MeasurementUnitType } from 'enum'

PouchDB.plugin(pouchDbFind)

const db = new PouchDB<Unwrapped<Ingredient>>('ingredients')

export interface Ingredient {
  readonly _id: string
  readonly _ref: string
  readonly name: ko.Observable<string>
  readonly unitType: ko.Observable<MeasurementUnitType>
  readonly groceryStoreSection: ko.Observable<GroceryStoreSection>
  readonly note: ko.Observable<string>
}

export interface IngredientModel extends Ingredient {}
export class IngredientModel extends DataModelConstructorBuilder {
  public readonly _id!: string
  public readonly _ref!: string
  public readonly name = ko.observable()
  public readonly unitType = ko.observable()
  public readonly groceryStoreSection = ko.observable()
  public readonly note = ko.observable()

  protected async fetch(): Promise<void> {
    return Promise.resolve()
  }
}

export class IngredientsCollection extends DataModelConstructorBuilder.Mixin(
  QueryMixin({
    search: ''
  })
)<{}> {
  public docs = ko.observableArray<IngredientModel>()

  constructor() {
    super({})
  }

  protected async fetch(): Promise<{ docs: IngredientModel[] }> {
    const { docs } = await db.find({
      selector: { title: { $regex: this.query.search() } }
    })
    return {
      docs: await Promise.all(
        docs.map((d) => IngredientModel.create(undefined, d))
      )
    }
  }
}
