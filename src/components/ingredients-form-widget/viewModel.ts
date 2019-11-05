import { NewIngredientModal } from './../modals/new-ingredient/index'
import * as ko from 'knockout'
import { ViewModelConstructorBuilder } from '@profiscience/knockout-contrib'
import { IngredientsCollection, RecipeModel, IngredientModel } from 'data'

export default class IngredientsFormWidgetViewModel extends ViewModelConstructorBuilder {
  protected recipe: RecipeModel

  protected ingredientsCollection = new IngredientsCollection()

  protected newIngredientName = ko.observable('')

  constructor(params: { recipe: RecipeModel }) {
    super()
    this.recipe = params.recipe
  }

  protected async addIngredient(): Promise<void> {
    const ingredient = await IngredientModel.create(
      { id: null },
      {
        name: this.ingredientsCollection.query.search()
      }
    )
    NewIngredientModal.launch(ingredient)
  }
}
