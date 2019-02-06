import * as ko from 'knockout'
import PouchDB from 'pouchdb'
import { DataModelConstructorBuilder } from '@profiscience/knockout-contrib'

const db = new PouchDB<Recipe>('recipes')

type Recipe = {
  id: string
  title: string
}

export class RecipesCollection extends DataModelConstructorBuilder<{}> {
  constructor() {
    super({})
  }
  protected async fetch() {
    return await db.allDocs()
  }
}

export class RecipeModel extends DataModelConstructorBuilder<{ id: string }> {
  public readonly id!: string
  public readonly title = ko.observable<string>()

  protected async fetch() {
    if (this.params.id) {
      return (await db.get(this.params.id)) as Recipe
    } else {
      return {
        id: null,
        title: 'New Recipe'
      }
    }
  }

  public async save() {
    const doc = this.toJS()
    if (this.id === null) {
      doc.id = doc.title
    }
    await db.put(doc)
    await super.save()
  }
}
