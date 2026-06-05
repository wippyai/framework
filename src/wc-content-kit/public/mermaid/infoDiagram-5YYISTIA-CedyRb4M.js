import { b as e, aD as s, a$ as o, E as i } from "./mermaid.core-FRDjOodn.js";
import { p as g } from "./wardley-L42UT6IY-C-B6soca.js";
var p = {
  parse: /* @__PURE__ */ e(async (r) => {
    const a = await g("info", r);
    s.debug(a);
  }, "parse")
}, v = {
  version: "11.15.0"
}, d = /* @__PURE__ */ e(() => v.version, "getVersion"), m = {
  getVersion: d
}, c = /* @__PURE__ */ e((r, a, n) => {
  s.debug(`rendering info diagram
` + r);
  const t = o(a);
  i(t, 100, 400, !0), t.append("g").append("text").attr("x", 100).attr("y", 40).attr("class", "version").attr("font-size", 32).style("text-anchor", "middle").text(`v${n}`);
}, "draw"), f = { draw: c }, b = {
  parser: p,
  db: m,
  renderer: f
};
export {
  b as diagram
};
