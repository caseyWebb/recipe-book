'use strict'

const path = require('path')
const TSCheckerPlugin = require('fork-ts-checker-webpack-plugin')
const HtmlPlugin = require('html-webpack-plugin')

const PRODUCTION = process.env.NODE_ENV === 'production'

module.exports = {
  context: __dirname,

  mode: PRODUCTION ? 'production' : 'development',

  entry: './src/index.ts',

  devtool: 'inline-source-map',

  devServer: {
    historyApiFallback: true,
    hot: true,
    quiet: true
  },

  module: {
    rules: [
      {
        test: /\.ts$/,
        use: [
          {
            loader: 'ts-loader',
            options: {
              transpileOnly: true,
              experimentalWatchApi: true
            }
          }
        ]
      },
      {
        test: /\.html$/,
        use: {
          loader: 'html-loader',
          options: {
            removeAttributeQuotes: false,
            minifyJS: false,
            ignoreCustomComments: [/^\s*\/?ko/],
            ignoreCustomFragments: [/{{[^}]+}}/]
          }
        }
      }
    ]
  },

  plugins: [
    new HtmlPlugin({
      template: 'src/index.html'
    }),
    new TSCheckerPlugin()
  ],

  resolve: {
    mainFields: ['esnext', 'es2015', 'module', 'main'],
    modules: [
      path.join(__dirname, 'src'),
      path.join(__dirname, 'node_modules')
    ],
    extensions: ['.js', '.ts']
  }
}
