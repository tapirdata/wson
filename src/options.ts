import { AddonFactory } from './addon';
import { HaverefCb, BackrefCb, PartialCb, HowNext, ConnectorBag, PreBag } from './types';

export interface WsonOptions {
  version?: number;
  addon?: AddonFactory;
  useAddon?: boolean;
  connectors?: PreBag | null;
}

export interface StringifyOptions {
  connectors?: ConnectorBag;
  haverefCb?: HaverefCb | null;
}

export interface ParseOptions {
  connectors?: ConnectorBag;
  backrefCb?: BackrefCb | null;
}

export interface ParsePartialOptions extends ParseOptions {
  howNext: HowNext;
  cb: PartialCb;
}
