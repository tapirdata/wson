
export type HowNext = boolean | [boolean, number] | null | Error
export type PartialCb = (isText: boolean, part: string, pos: number) => HowNext
export type BackrefCb = (idx: number) => any
export type HaverefCb = (x: any) => number | null

export interface Connector<T> {
  by: T
  split: (x: T) => any[]
  create?: (...args: any[]) => T
  precreate?: () => T
  postcreate?: (x: T, args: any[]) => T | null | undefined
  name?: string
  hasCreate?: boolean
}
