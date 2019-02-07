import * as ko from 'knockout'

ko.bindingHandlers.ifNotEmpty = {
  init(container, valueAccessor, bindings, vm, ctx) {
    return ko.bindingHandlers.ifnot.init(
      container,
      ko.observable(
        ko.pureComputed(
          () =>
            !ko.unwrap(valueAccessor()) ||
            ko.unwrap(valueAccessor()).length === 0
        )
      ),
      bindings,
      vm,
      ctx
    )
  }
}

ko.virtualElements.allowedBindings.ifNotEmpty = true
