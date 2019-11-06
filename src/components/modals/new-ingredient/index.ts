import { ViewModelConstructorBuilder } from '@profiscience/knockout-contrib'
import { IngredientModel } from 'data'
import { GroceryStoreSection, MeasurementUnitType } from 'enum'
import { ModalMixin } from 'model.mixins'

import template from './template.html'

export class NewIngredientModal extends ViewModelConstructorBuilder.Mixin(
  ModalMixin({
    template,
    destroyOnClose: true
  })
) {
  protected unitTypes = Object.keys(MeasurementUnitType)
  protected groceryStoreSections = GroceryStoreSection

  constructor(
    readonly params: {
      ingredient: IngredientModel
      afterAdd(): void
    }
  ) {
    super()
  }

  protected async onSubmit(): Promise<void> {
    await this.params.ingredient.save()
    this.params.afterAdd()
    this.destroy()
  }
}
