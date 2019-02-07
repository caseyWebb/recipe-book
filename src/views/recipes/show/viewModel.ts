import {
  Context,
  IContext,
  ViewModelConstructorBuilder
} from '@profiscience/knockout-contrib'
import { RecipeModel } from 'data'

export default class RecipeViewModel extends ViewModelConstructorBuilder {
  protected readonly recipe = new RecipeModel(this.ctx.params as { id: string })

  constructor(protected readonly ctx: Context & IContext) {
    super()
  }
}
