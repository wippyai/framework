let a = null;
function i() {
  return a || (a = import("./mermaid.core-Jw3znkh4.js").then((e) => e.bD).then((e) => e.default)), a;
}
function l(e) {
  const o = getComputedStyle(e), r = (n) => o.getPropertyValue(n).trim(), t = r("font-family") || "inherit";
  return {
    background: r("--p-content-background"),
    primaryColor: r("--p-primary-500"),
    primaryTextColor: r("--p-text-color"),
    primaryBorderColor: r("--p-content-border-color"),
    lineColor: r("--p-surface-400"),
    secondaryColor: r("--p-surface-100"),
    tertiaryColor: r("--p-surface-50"),
    secondaryTextColor: r("--p-text-muted-color"),
    tertiaryTextColor: r("--p-text-muted-color"),
    noteBkgColor: r("--p-surface-100"),
    noteTextColor: r("--p-text-color"),
    noteBorderColor: r("--p-content-border-color"),
    fontFamily: t
  };
}
async function c(e, o) {
  const r = await i();
  r.initialize({
    startOnLoad: !1,
    theme: "base",
    securityLevel: "strict",
    themeVariables: l(o)
  });
  const t = `m-${Math.random().toString(36).slice(2, 10)}`, { svg: n } = await r.render(t, e);
  return n;
}
export {
  c as renderWithMermaid
};
