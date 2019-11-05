import * as ko from 'knockout'
import PouchDB from 'pouchdb'
import { DataModelConstructorBuilder } from '@profiscience/knockout-contrib'
import { DiscreteUnit, VolumetricUnit, WeightUnit } from 'enum'

const db = new PouchDB<Recipe>('recipes')

interface Recipe {
  readonly _id: string
  readonly _ref: string
  readonly title: ko.Observable<string>
  readonly ingredients: ko.ObservableArray<{
    quantity: number
    unit: DiscreteUnit | VolumetricUnit | WeightUnit
    ingredientId: string
  }>

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

export interface RecipeModel extends Recipe {}
export class RecipeModel extends DataModelConstructorBuilder<{ id: string }> {
  public readonly _id!: string
  public readonly _ref!: string
  public readonly title = ko.observable()
  public readonly ingredients = ko.observableArray()

  protected async fetch() {
    if (this.params.id === null) {
      return {
        _id: null,
        _ref: undefined,
        title: 'New Recipe'
      }
    } else {
      return (await db.get(this.params.id)) as Recipe
    }
  }

  public async save(): Promise<void> {
    const doc = this.toJS()
    if (this._id === null) {
      doc._id = doc.title.toLowerCase().replace(/\s/g, '-')
    }
    await db.put(doc)
    await super.save()
    ;(this as any)._id = doc._id
  }
}

export class RecipesCollection extends DataModelConstructorBuilder<{}> {
  public count!: number
  public docs!: Recipe[]

  constructor() {
    super({})
  }

  protected async fetch() {
    const { total_rows: count, rows } = await db.allDocs({ include_docs: true })
    return {
      count,
      docs: rows.map((r) => r.doc)
    }
  }
}
