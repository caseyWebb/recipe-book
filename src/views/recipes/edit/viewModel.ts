import { ViewModelConstructorBuilder } from '@profiscience/knockout-contrib'
import { RecipeModel } from 'data/recipes'

export default class EditRecipeViewModel extends ViewModelConstructorBuilder {
  protected recipeModel = new RecipeModel()
}
