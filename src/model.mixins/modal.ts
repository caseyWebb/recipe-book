import * as ko from 'knockout'
import $ from 'jquery'
import { ViewModelConstructorBuilder } from '@profiscience/knockout-contrib'

let id = 0

export type ModalMixinParams = {
  template: string
  destroyOnClose?: boolean
}

export const ModalMixin = (modalParams: ModalMixinParams) => <
  T extends new (...args: any[]) => ViewModelConstructorBuilder
>(
  ctor: T
) =>
  class extends ctor {
    protected el = document.createElement('div')
    protected showModal = ko.observable(true)

    private _destroyed = false

    public destroy(): void {
      if (this._destroyed) return
      this._destroyed = true
      this.showModal(false)
    }

    public static launch<TT, P>(
      this: new (params: P, el: HTMLDivElement) => TT,
      params: P
    ): TT {
      const instance = Reflect.construct(this, [params])
      const template = [createModalDOM(modalParams, instance.el)]
      const componentName = `modal-${id++}`
      ko.components.register(componentName, {
        viewModel: {
          instance
        },
        template
      })
      const el = document.createElement('div')
      if (modalParams.destroyOnClose) {
        instance.subscribe(instance.showModal, () => {
          instance.destroy()
          el.remove()
        })
      }
      ko.applyBindingsToNode(
        el,
        { component: { name: componentName, params } },
        null
      )
      document.body.append(el)
      return instance
    }
  }

function createModalDOM(
  params: ModalMixinParams,
  container: HTMLDivElement
): HTMLDivElement {
  $(container)
    .addClass('modal-container')
    .attr('data-bind', 'css: showModal() ? "open" : "closed"').append(`
      <div class="modal-backdrop" data-bind="click: showModal.bind(null, false)"></div>
      <div class="modal-dialog">
        <button type="button" class="close" data-bind="toggle: showModal">
          <span aria-hidden="true">&times;</span>
          <span class="sr-only">Close</span>
        </button>
        ${params.template}
      </div>
  `)
  return container
}
