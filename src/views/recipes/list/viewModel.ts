import { ViewModelConstructorBuilder } from '@profiscience/knockout-contrib'
import { RecipesCollection } from 'data/recipes'

export default class HomeViewModel extends ViewModelConstructorBuilder {
  protected recipesCollection = new RecipesCollection()
}
