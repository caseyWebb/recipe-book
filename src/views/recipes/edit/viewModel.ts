import {
  Context,
  IContext,
  ViewModelConstructorBuilder
} from '@profiscience/knockout-contrib'
import { RecipeModel } from 'data/recipes'

export default class EditRecipeViewModel extends ViewModelConstructorBuilder {
  protected recipeModel = new RecipeModel({ id: this.ctx.params.id })

  constructor(private ctx: Context & IContext) {
    super()
  }
}
