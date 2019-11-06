import * as ko from 'knockout'
import PouchDB from 'pouchdb'
import pouchDbFind from 'pouchdb-find'
import {
  DataModelConstructorBuilder,
  QueryMixin
} from '@profiscience/knockout-contrib'
import { GroceryStoreSection, MeasurementUnitType } from 'enum'

PouchDB.plugin(pouchDbFind)

const db = new PouchDB<IngredientSchema>('ingredients')

type IngredientSchema = {
  readonly _id: string
  readonly _ref: string
  name: string
  unitType: keyof typeof MeasurementUnitType
  groceryStoreSection: keyof typeof GroceryStoreSection
  note: string
}

export class IngredientModel extends DataModelConstructorBuilder<{
  id: null | string
}> {
  public _id: null | string = null
  public readonly _ref?: string
  public readonly name = ko.observable('')
  public readonly unitType = ko.observable<MeasurementUnitType>()
  public readonly groceryStoreSection = ko.observable<
    keyof typeof GroceryStoreSection
  >()
  public readonly note = ko.observable('')

  protected async fetch(initData?: IngredientSchema): Promise<any> {
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
      selector: { name: { $regex: new RegExp(this.query.search(), 'i') } }
    })
    return {
      docs: await Promise.all(
        docs.map((d) => IngredientModel.create({ id: d._id }, d))
      )
    }
  }
}
