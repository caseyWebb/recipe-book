import ko from 'knockout'
import 'knockout-punches'

import 'bindings'
import 'routing'
import * as appComponent from 'components/app'
import { overlayLoader } from 'lib'

// eslint-disable-next-line
;(ko as any).punches.enableAll()

ko.components.register('app', appComponent)

ko.applyBindings({ showOverlayLoader: overlayLoader.isVisible }, document.body)
