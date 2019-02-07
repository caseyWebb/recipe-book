import * as ko from 'knockout'
import 'knockout-punches'

import 'bindings'
import 'routing'
import * as appComponent from 'components/app'
import { overlayLoader } from 'lib'
;(ko as any).punches.enableAll()

ko.components.register('app', appComponent)

ko.applyBindings({ showOverlayLoader: overlayLoader.isVisible }, document.body)
;(window as any).ko = ko
