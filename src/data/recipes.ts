import * as ko from 'knockout'
import PouchDB from 'pouchdb'
import {
  DataModelConstructorBuilder,
  nonenumerable
} from '@profiscience/knockout-contrib'

const db = new PouchDB<Recipe>('recipes')

type Recipe = {
  _id: string
  title: string
}

export class RecipesCollection extends DataModelConstructorBuilder<{}> {
  public count!: number
  public docs!: Recipe[]

  constructor() {
    super({})
  }

  protected async fetch() {
    const { total_rows, rows } = await db.allDocs({ include_docs: true })
    return {
      count: total_rows,
      docs: rows.map((r) => r.doc)
    }
  }
}

export class RecipeModel extends DataModelConstructorBuilder<{ id: string }> {
  public readonly _id!: string
  public readonly _ref!: string
  public readonly title = ko.observable<string>()

  constructor(params: { id: string }) {
    super(params)
  }

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

  public async save() {
    const doc = this.toJS()
    if (this._id === null) {
      doc._id = doc.title.toLowerCase().replace(/\s/g, '-')
    }
    await db.put(doc)
    await super.save()
    ;(this as any)._id = doc._id
  }
}
