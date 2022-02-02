export type Value = unknown;
export type AnyArgs = unknown[];
export type AnyArray = unknown[];
export type AnyRecord = Record<string, unknown>;
export type Class<T = Value, A extends AnyArgs = AnyArgs> = { new (...args: A): T };

export class BaseStringifyError extends Error {
  constructor(public x: Value, public cause: string) {
    super();
  }
  message = '';
  name = '';
}
export type BaseStringifyErrorClass = new (x: Value, cause: string) => BaseStringifyError;

export class BaseParseError extends Error {
  constructor(public s: string, public pos: number, public cause: string) {
    super();
  }
  message = '';
  name = '';
}
export type BaseParseErrorClass = new (s: string, pos: number, cause: string) => BaseParseError;

export type HowNext = boolean | [boolean, number] | null | Error;
export type PartialCb = (isText: boolean, part: string, pos: number) => HowNext;
export type BackrefCb = (idx: number) => Value;
export type HaverefCb = (x: Value) => number | null;

export type Splitter<T = unknown, A extends AnyArgs = AnyArgs> = (x: T) => A;
export type Creator<T = unknown, A extends AnyArgs = AnyArgs> = (args: A) => T;
export type Precreator<T = unknown> = () => T;
export type Postcreator<T = unknown, A extends AnyArgs = AnyArgs> = (x: T, args: A) => T | null | undefined;

export type WsonClass<T = Value, A extends AnyArgs = AnyArgs> = Class<T, A> & {
  __wsoncreate__?: Creator<T, A>;
  __wsonprecreate__?: Precreator<T>;
  __wsonpostcreate__?: Postcreator<T, A>;
};

export interface Connector<T = unknown, A extends AnyArgs = AnyArgs> {
  by: WsonClass<T, A>;
  split: Splitter<T, A>;
  create?: Creator<T, A>;
  precreate?: Precreator<T>;
  postcreate?: Postcreator<T, A>;
  name?: string;
  hasCreate?: boolean;
}

export type ConnectorBag = Record<string, Connector>;

export type PreConnector<T = unknown, A extends AnyArgs = AnyArgs> = Omit<Connector<T, A>, 'split' | 'postcreate'> & {
  split?: (x: T) => A;
  postcreate?: Postcreator<T, A>;
};

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type PreBag = Record<string, PreConnector<any, any> | WsonClass<any, any>>;

export interface FactoryOptions {
  connectors?: Record<string, Connector<Value>>;
}

export interface OpOptions {
  howNext?: HowNext;
  cb?: PartialCb;
  backrefCb?: BackrefCb;
  haverefCb?: HaverefCb;
}
