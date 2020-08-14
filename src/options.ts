import { Addon } from "./addon"
import { HaverefCb, BackrefCb, PartialCb, HowNext } from "./types"

export interface WsonOptions {
  version?: number
  addon?: Addon
  useAddon?: boolean
  connectors?: Record<string, any> | null
}

export interface StringifyOptions {
  haverefCb?: HaverefCb | null
}

export interface ParseOptions {
  backrefCb?: BackrefCb | null
}

export interface ParsePartialOptions extends ParseOptions {
  howNext: HowNext
  cb: PartialCb
}
