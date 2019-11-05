import autobind from 'autobind-decorator'
import * as ko from 'knockout'
import { ViewModelConstructorBuilder } from '@profiscience/knockout-contrib'
import { NewIngredientModal } from 'components/modals/new-ingredient/index'
import {
  IngredientsCollection,
  IngredientModel,
  RecipeModel,
  RecipeIngredient
} from 'data'
import { VolumetricUnit } from 'enum'

const NEW_INGREDIENT = Symbol()

export default class IngredientsFormWidgetViewModel extends ViewModelConstructorBuilder {
  private ingredientsCollection = new IngredientsCollection()

  protected newIngredientName = ko.observable('')

  private addedIngredientIds = ko.pureComputed(() =>
    this.params.recipe.ingredients().map((i) => i.ingredient._id)
  )

  protected ingredientOptions = ko.pureComputed(() => [
    ...this.ingredientsCollection
      .docs()
      .filter((i) => !this.addedIngredientIds().includes(i._id)),
    { name: 'Add new ingredient', [NEW_INGREDIENT]: true }
  ])

  constructor(protected params: { recipe: RecipeModel }) {
    super()
  }

  @autobind
  protected async addIngredient(
    ingredient: IngredientModel & { [NEW_INGREDIENT]?: boolean }
  ): Promise<void> {
    if (ingredient[NEW_INGREDIENT]) {
      // eslint-disable-next-line
      ingredient = await IngredientModel.create(
        { id: null },
        {
          name: this.ingredientsCollection.query.search()
        }
      )
      await new Promise((resolve) =>
        NewIngredientModal.launch({ ingredient, afterAdd: resolve })
      )
    }
    this.params.recipe.ingredients.push({
      quantity: 0,
      unit: VolumetricUnit.Cup,
      ingredient
    })
    this.ingredientsCollection.query.search('')
  }

  protected removeIngredient(ingredient: RecipeIngredient): void {
    this.params.recipe.ingredients.remove(ingredient)
  }
}
