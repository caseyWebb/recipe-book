import * as ko from 'knockout'
import { ViewModelConstructorBuilder } from '@profiscience/knockout-contrib'
import { RecipeModel } from 'data'

export default class IngredientsFormWidgetViewModel extends ViewModelConstructorBuilder {
  protected recipe: RecipeModel

  protected ingredientsCollection = new IngredientsCollection()

  protected newIngredientName = ko.observable('')

  constructor(params: { recipe: RecipeModel }) {
    super()
    this.recipe = params.recipe
  }

  protected addIngredient() {
    // TODO
  }

  protected setIngredient() {
    // TODO
  }
}
