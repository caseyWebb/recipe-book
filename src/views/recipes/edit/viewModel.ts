import {
  Context,
  IContext,
  ViewModelConstructorBuilder,
  Router
} from '@profiscience/knockout-contrib'
import { RecipeModel } from 'data/recipes'
import { overlayLoader } from 'lib'

export default class EditRecipeViewModel extends ViewModelConstructorBuilder {
  protected recipe = new RecipeModel({ id: this.ctx.params.id })

  constructor(private ctx: Context & IContext) {
    super()
  }

  public async onSubmit() {
    overlayLoader.show()
    await this.recipe.save()
    overlayLoader.hide()
    Router.update(`//${this.recipe._id}`)
  }
}
