import * as ko from 'knockout'
import PouchDB from 'pouchdb'
import { DataModelConstructorBuilder } from '@profiscience/knockout-contrib'
import { IngredientModel } from 'data'
import { DiscreteUnit, VolumetricUnit, WeightUnit } from 'enum'

const db = new PouchDB<RecipeSchema>('recipes')

type RecipeSchema = {
  readonly _id: string
  readonly _ref: string
  title: string
  ingredients: {
    quantity: number
    ingredient: string
  }[]

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

export type RecipeIngredient = {
  quantity: number
  unit: DiscreteUnit | VolumetricUnit | WeightUnit
  ingredient: IngredientModel
}

export class RecipeModel extends DataModelConstructorBuilder<{ id: string }> {
  public readonly _id!: string
  public readonly _ref!: string
  public readonly title = ko.observable('')
  public readonly ingredients = ko.observableArray<RecipeIngredient>()

  protected async fetch() {
    if (this.params.id === null) {
      return {
        _id: null,
        _ref: undefined
      }
    } else {
      const doc = await db.get(this.params.id)
      const ingredients = await Promise.all(
        doc.ingredients.map(async (i) => ({
          quantity: i.quantity,
          ingredient: await IngredientModel.create({ id: i.ingredient })
        }))
      )
      return {
        ...doc,
        ingredients
      }
    }
  }

  public async save(): Promise<void> {
    const recipe: Unwrapped<RecipeModel> = this.toJS()
    const _id =
      recipe._id === null
        ? recipe.title.toLowerCase().replace(/\s/g, '-')
        : recipe._id
    const ingredients = recipe.ingredients.map((i) => ({
      ...i,
      ingredient: i.ingredient._id as string
    }))
    const doc: RecipeSchema = {
      ...recipe,
      _id,
      ingredients
    }
    await db.put(doc)
    this.params.id = _id
    await super.save()
  }
}

export class RecipesCollection extends DataModelConstructorBuilder<{}> {
  public count!: number
  public docs = ko.observableArray<RecipeModel>()

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
