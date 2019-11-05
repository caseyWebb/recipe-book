import { ViewModelConstructorBuilder } from '@profiscience/knockout-contrib'
import { IngredientModel } from 'data'
import {
  DiscreteUnit,
  VolumetricUnit,
  WeightUnit,
  GroceryStoreSection
} from 'enum'
import { ModalMixin } from 'model.mixins'

import template from './template.html'

export class NewIngredientModal extends ViewModelConstructorBuilder.Mixin(
  ModalMixin({
    template,
    destroyOnClose: true
  })
) {
  protected groceryStoreSections = GroceryStoreSection

  constructor(protected readonly ingredient: IngredientModel) {
    super()
  }

  protected onSubmit() {
    this.ingredient.save()
    this.destroy()
  }
}
