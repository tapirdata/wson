
export type AnyCb = (...args: any[]) => any
export type BackrefCb = (err?: any, val?: any) => void
export type HaverefCb = (x: any) => number | null

export interface Connector {
  by: any
  split: (x: any) => any[]
  create?: (...args: any[]) => any
  precreate?: () => any
  postcreate?: (x: any, args: any[]) => any
  name?: string
  hasCreate?: boolean
}
