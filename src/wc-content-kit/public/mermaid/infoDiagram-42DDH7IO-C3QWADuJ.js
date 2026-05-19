import { _ as a, l as s, I as o, e as i } from "./mermaid.core-Jw3znkh4.js";
import { p as g } from "./mermaid-parser.core-DQ6c91Zg.js";
var p = {
  parse: /* @__PURE__ */ a(async (r) => {
    const e = await g("info", r);
    s.debug(e);
  }, "parse")
}, v = {
  version: "11.14.0"
}, d = /* @__PURE__ */ a(() => v.version, "getVersion"), m = {
  getVersion: d
}, c = /* @__PURE__ */ a((r, e, n) => {
  s.debug(`rendering info diagram
` + r);
  const t = o(e);
  i(t, 100, 400, !0), t.append("g").append("text").attr("x", 100).attr("y", 40).attr("class", "version").attr("font-size", 32).style("text-anchor", "middle").text(`v${n}`);
}, "draw"), l = { draw: c }, _ = {
  parser: p,
  db: m,
  renderer: l
};
export {
  _ as diagram
};
