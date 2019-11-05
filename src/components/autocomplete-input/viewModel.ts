import * as ko from 'knockout'
import { increment, decrement } from '@profiscience/knockout-contrib'

type AutocompleteInputComponentParams = {
  placeholder: string
  search: ko.Observable<string>
  onSelect(): void
  options: ko.ObservableArray<string>
}

export default class AutocompleteInputComponentViewModel {
  protected selectedIndex = ko.observable(0)

  constructor(protected params: AutocompleteInputComponentParams) {}

  protected onKeydown(data: any, e: KeyboardEvent): boolean {
    if (e.keyCode === 38 && this.selectedIndex() > 0) {
      decrement(this.selectedIndex)
    } else if (
      e.keyCode === 40 &&
      this.selectedIndex() < this.params.options().length - 1
    ) {
      increment(this.selectedIndex)
    }
    return true
  }
}
