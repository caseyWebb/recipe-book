import * as path from 'path'
import HtmlPlugin from 'html-webpack-plugin'

const PRODUCTION = process.env.NODE_ENV === 'production'

export default {
  context: __dirname,

  mode: PRODUCTION ? 'production' : 'development',

  entry: './src/index.ts',

  output: {
    publicPath: '/'
  },

  devtool: PRODUCTION ? 'source-map' : 'inline-source-map',

  devServer: {
    historyApiFallback: true,
    hot: true,
    quiet: true
  },

  module: {
    rules: [
      {
        // https://github.com/webpack/webpack/issues/6796
        test: path.resolve(__dirname, 'node_modules'),
        resolve: {
          mainFields: ['esnext', 'es2015', 'module', 'main']
        }
      },
      {
        test: /\.ts$/,
        use: [
          {
            loader: 'ts-loader',
            options: {
              experimentalWatchApi: true
            }
          }
        ]
      },
      {
        test: [/\.elm$/],
        exclude: [/elm-stuff/, /node_modules/],
        use: [
          { loader: 'elm-hot-webpack-loader' },
          {
            loader: 'elm-webpack-loader',
            options: PRODUCTION ? {} : { debug: true, forceWatch: true }
          }
        ]
      }
    ]
  },

  plugins: [new HtmlPlugin()],

  resolve: {
    modules: [path.join(__dirname, 'src'), 'node_modules'],
    extensions: ['.js', '.ts', '.elm']
  }
}
