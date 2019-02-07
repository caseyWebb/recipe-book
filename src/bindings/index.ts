const context = require.context('./', true, /\.\/[^/_]+\.ts$/)

context.keys().forEach(context)
