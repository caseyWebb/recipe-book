import * as ko from 'knockout'
import { increment, decrement } from '@profiscience/knockout-contrib'

type AutocompleteInputComponentParams<T> = {
  placeholder: string
  search: ko.Observable<string>
  onSelect(opt: T): void
  options: ko.ObservableArray<T>
  getOptionText(opt: T): string
}

export default class AutocompleteInputComponentViewModel {
  protected selectedIndex = ko.observable(0)

  constructor(protected params: AutocompleteInputComponentParams<any>) {}

  protected onKeydown(data: any, e: KeyboardEvent): boolean {
    // Tab
    if (
      (e.keyCode === 9 || e.keyCode === 13) &&
      this.params.options().length > 0
    ) {
      this.params.onSelect(this.params.options()[this.selectedIndex()])
      this.params.search('')
      return false
    }
    // Up
    if (e.keyCode === 38 && this.selectedIndex() > 0) {
      decrement(this.selectedIndex)
    }
    // Down
    if (
      e.keyCode === 40 &&
      this.selectedIndex() < this.params.options().length - 1
    ) {
      increment(this.selectedIndex)
    }
    return true
  }
}
