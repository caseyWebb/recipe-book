import * as ko from 'knockout'
import { toggleBindingHandler as toggle } from '@profiscience/knockout-contrib'

Object.assign(ko.bindingHandlers, { toggle })

const context = require.context('./', true, /\.\/[^/_]+\.ts$/)

context.keys().forEach(context)
