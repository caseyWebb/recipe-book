import * as ko from 'knockout'

const showOverlay = ko.observable(false)

let stack = 0

export const overlayLoader = {
  isVisible: ko.pureComputed(() => showOverlay()), // keeps showOverlay publically readonly
  show() {
    ++stack
    showOverlay(true)
  },
  hide() {
    if (--stack === 0) showOverlay(false)
  }
}
