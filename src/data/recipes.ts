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
  constructor() {
    super({})
  }
  protected async fetch() {
    const { rows } = await db.allDocs({ include_docs: true })
    return {
      docs: rows.map((r) => r.doc)
    }
  }
}

export class RecipeModel extends DataModelConstructorBuilder<{ id: string }> {
  public readonly _id!: string
  public readonly title = ko.observable<string>()

  public isNew = !!this.params.id

  constructor(params: { id: string }) {
    super(params)

    nonenumerable(this, 'isNew')
  }

  protected async fetch() {
    if (this.isNew) {
      return (await db.get(this.params.id)) as Recipe
    } else {
      return {
        _id: null,
        title: 'New Recipe'
      }
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
