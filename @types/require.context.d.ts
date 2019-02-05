type RequireContext = {
  [k: string]: any
  (key: string): any
  keys(): any[]
}

type WebpackRequireMode =
  | 'sync'
  | 'eager'
  | 'weak'
  | 'async-weak'
  | 'lazy'
  | 'lazy-once'

interface NodeRequire {
  context(
    context: string,
    includeSubdirs: boolean,
    pattern: RegExp,
    mode?: WebpackRequireMode
  ): RequireContext
}
