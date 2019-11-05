import {
  Context,
  IContext,
  ViewModelConstructorBuilder,
  Router
} from '@profiscience/knockout-contrib'
import { RecipeModel } from 'data/recipes'
import { overlayLoader } from 'lib'

export default class EditRecipeViewModel extends ViewModelConstructorBuilder {
  protected readonly recipe = new RecipeModel(this.ctx.params as { id: string })

  constructor(protected readonly ctx: Context & IContext) {
    super()
  }

  public async onSubmit(): Promise<void> {
    overlayLoader.show()
    await this.recipe.save()
    overlayLoader.hide()
    Router.update(`//${this.recipe._id}`)
  }
}
