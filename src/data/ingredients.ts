import { Ingredient } from './ingredients'
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
  _id: null | string
  readonly _ref?: string
  readonly name: ko.Observable<string>
  readonly unitType: ko.Observable<MeasurementUnitType>
  readonly groceryStoreSection: ko.Observable<keyof typeof GroceryStoreSection>
  readonly note: ko.Observable<string>
}

export interface IngredientModel extends Ingredient {}
export class IngredientModel extends DataModelConstructorBuilder<{
  id: null | string
}> {
  public _id: null | string = null
  public readonly _ref?: string
  public readonly name = ko.observable()
  public readonly unitType = ko.observable()
  public readonly groceryStoreSection = ko.observable()
  public readonly note = ko.observable()

  protected async fetch(
    initData?: Unwrapped<Partial<Ingredient>>
  ): Promise<any> {
    const id = this.params.id
    if (initData) return initData
    if (id === null) return {}
    return db.get(id)
  }

  public async save(): Promise<void> {
    const doc = this.toJS()
    if (this._id === null) {
      doc._id = doc.name.toLowerCase().replace(/\s/g, '-')
    }
    await db.put(doc)
    await super.save()
    this._id = doc._id
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
      selector: { name: { $regex: this.query.search() } }
    })
    return {
      docs: await Promise.all(
        docs.map((d) => IngredientModel.create({ id: d._id }, d))
      )
    }
  }
}
