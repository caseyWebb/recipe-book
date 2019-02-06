import {
  Context,
  IContext,
  ViewModelConstructorBuilder
} from '@profiscience/knockout-contrib'
import { RecipeModel } from 'data'

export default class RecipeViewModel extends ViewModelConstructorBuilder {
  public readonly recipe = new RecipeModel(this.ctx.params.id)

  constructor(protected readonly ctx: Context & IContext) {
    super()
  }
}
