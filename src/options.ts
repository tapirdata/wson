
export type Cb = (err?: any, val?: any) => void
export type HaverefCb = (X: any) => number | null

export interface Connector {
  by: any
  split: (x: any) => any[]
  create?: (...args: any[]) => any
  precreate?: () => any
  postcreate?: (x: any, args: any[]) => any
  name?: string
  hasCreate?: boolean
}
