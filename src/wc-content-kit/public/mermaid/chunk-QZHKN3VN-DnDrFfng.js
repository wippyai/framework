import { _ as i } from "./mermaid.core-Jw3znkh4.js";
var r = class {
  /**
   * @param init - Function that creates the default state.
   */
  constructor(t) {
    this.init = t, this.records = this.init();
  }
  static {
    i(this, "ImperativeState");
  }
  reset() {
    this.records = this.init();
  }
};
export {
  r as I
};
