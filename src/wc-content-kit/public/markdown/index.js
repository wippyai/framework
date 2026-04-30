import { inject as Dr, ref as ku, createApp as bi, defineComponent as pi, computed as uu, openBlock as Pt, createElementBlock as Gt } from "vue";
import { addCollection as gi } from "@iconify/vue";
import { hostCss as mi, loadCss as xi, addIcons as yi, define as wi } from "@wippy-fe/proxy";
import { getActivePinia as Ci, createPinia as vi, setActivePinia as Ei } from "pinia";
const Di = Symbol("wippy:emit"), Ir = Symbol("wippy:props"), Ii = Symbol("wippy:props_error"), _r = Symbol("wippy:content"), _i = Symbol("wippy:panel-id"), ki = Symbol("wippy:layout-bus"), Bi = Symbol("wippy:host");
function Fi() {
  const e = Dr(Ir);
  if (!e)
    throw new Error("useProps() must be called inside a WippyVueElement");
  return e;
}
function Si() {
  const e = Dr(_r);
  if (!e)
    throw new Error("useContent() must be called inside a WippyVueElement with contentTemplate configured");
  return e;
}
const Ri = [
  "themeConfigUrl",
  "primeVueCssUrl",
  "markdownCssUrl",
  "iframeCssUrl"
];
function Ti(e, u) {
  const c = (u ?? Ri).map(async (s) => {
    const i = mi[s];
    if (!i)
      return console.warn(`[wippy-fe/webcomponent-core] hostCss key "${s}" is undefined — skipping. Remove it from hostCssKeys if the CSS was removed.`), null;
    try {
      return await xi(i);
    } catch (l) {
      return console.warn(`[wippy-fe/webcomponent-core] Failed to load hostCss "${s}" (${i}):`, l), null;
    }
  });
  return Promise.all(c).then((s) => {
    for (const i of s) {
      if (!i)
        continue;
      const l = document.createElement("style");
      l.textContent = i, l.setAttribute("role", "@wippy-fe/host-css"), e.appendChild(l);
    }
  });
}
function Ni(e, u) {
  const t = document.createElement("style");
  t.textContent = u, e.appendChild(t);
}
function kr(e) {
  return e.__wippyHost ?? null;
}
function Oi(e) {
  return e.replace(/-([a-z])/g, (u, t) => t.toUpperCase());
}
function Mi(e, u, t) {
  switch (t.type) {
    case "string":
      return { value: u };
    case "number": {
      const c = Number.parseFloat(u);
      return Number.isNaN(c) ? { value: void 0, error: `Invalid ${e}: expected a number` } : { value: c };
    }
    case "integer": {
      const c = Number.parseInt(u, 10);
      return Number.isNaN(c) ? { value: void 0, error: `Invalid ${e}: expected an integer` } : { value: c };
    }
    case "boolean":
      return { value: u !== "false" };
    case "array":
    case "object":
      try {
        const c = JSON.parse(u);
        return t.type === "array" && !Array.isArray(c) ? { value: void 0, error: `Invalid ${e}: expected a JSON array` } : { value: c };
      } catch {
        return { value: void 0, error: `Invalid ${e}: must be valid JSON` };
      }
    default:
      return { value: u };
  }
}
function qt(e, u) {
  const t = {}, c = [];
  for (const [s, i] of Object.entries(u.properties)) {
    const l = e.getAttribute(s), a = Oi(s);
    if (l === null) {
      i.default !== void 0 && (t[a] = i.default);
      continue;
    }
    const o = Mi(s, l, i);
    o.error ? c.push(o.error) : t[a] = o.value;
  }
  return { props: t, errors: c };
}
class Qi extends HTMLElement {
  constructor() {
    super(), this._contentObserver = null, this._initialized = !1, this._container = null, this._internals = this.attachInternals();
  }
  /**
   * Override to provide the component's configuration.
   * Must be static because `observedAttributes` reads it before construction.
   *
   * Specify the generic to get typed `validateProps`:
   * ```ts
   * static get wippyConfig(): WippyElementConfig<MyProps> { ... }
   * ```
   */
  static get wippyConfig() {
    return { propsSchema: { properties: {} } };
  }
  /**
   * Derived from the props schema + any `extraObservedAttributes`.
   */
  static get observedAttributes() {
    const u = this.wippyConfig, t = Object.keys(u.propsSchema.properties), c = u.extraObservedAttributes ?? [];
    return [...t, ...c];
  }
  /**
   * Panel-scoped `host` wrapper attached by the managed-layout shell's
   * content resolvers (`ComponentResolver` / `WebComponentPackageLoader`).
   *
   * Inside a managed-layout panel, this is a wrapper around the universal
   * `host` API where context-aware calls (`layout.broadcast / send / on`)
   * are routed through the panel-bound bus — so `sourcePanelId` is
   * attributed correctly without postMessage indirection. Layout
   * mutations and other host methods pass through unchanged.
   *
   * `null` outside a managed-layout context (compat shell, chat sidebar,
   * standalone playground). Subclass code that needs a host in those
   * cases can fall back to `import { host } from '@wippy-fe/proxy'`.
   */
  get host() {
    return kr(this);
  }
  /**
   * Emit a CustomEvent that bubbles and crosses shadow DOM boundaries.
   */
  emitEvent(u, t) {
    this.dispatchEvent(new CustomEvent(u, {
      bubbles: !0,
      composed: !0,
      detail: t
    }));
  }
  // ── Lifecycle ──────────────────────────────────────────────
  connectedCallback() {
    this._internals.states.add("loading");
    try {
      const u = this.constructor.wippyConfig, t = this._initialized, c = this.shadowRoot ?? this.attachShadow({ mode: u.shadowMode ?? "open" });
      let s;
      if (t)
        s = this._container;
      else {
        this.onInit(c), u.inlineCss && Ni(c, u.inlineCss), (u.hostCssKeys === void 0 || u.hostCssKeys.length > 0) && Ti(c, u.hostCssKeys), s = document.createElement("div");
        const r = u.containerClasses ?? [];
        r.length > 0 && s.classList.add(...r), c.appendChild(s), this._container = s, yi(gi);
      }
      const { props: i, errors: l } = qt(this, u.propsSchema);
      u.validateProps && l.push(...u.validateProps(i));
      const a = i;
      let o = null;
      u.contentTemplate && (o = this._extractContent(u.contentTemplate), this._contentObserver = new MutationObserver(() => {
        const r = this._extractContent(u.contentTemplate);
        this.onContentChanged(r);
      }), this._contentObserver.observe(this, {
        childList: !0,
        characterData: !0,
        subtree: !0
      })), this.onMount(c, s, a, l, o, t), this._internals.states.delete("loading"), this._internals.states.add("ready"), t || (this._initialized = !0), this.onReady(), this.emitEvent("load");
    } catch (u) {
      this.onError(u), this._internals.states.delete("loading"), this._internals.states.add("error"), this.emitEvent("error", {
        message: u instanceof Error ? u.message : String(u),
        error: u
      });
    }
  }
  disconnectedCallback() {
    this._contentObserver && (this._contentObserver.disconnect(), this._contentObserver = null), this.onUnmount(), this.emitEvent("unload"), this._internals.states.clear(), delete this.__wippyHost, delete this.__wippyHostBus;
  }
  attributeChangedCallback(u, t, c) {
    if (t === c)
      return;
    const s = this.constructor.wippyConfig, { props: i, errors: l } = qt(this, s.propsSchema);
    s.validateProps && l.push(...s.validateProps(i)), this.onPropsChanged(i, l);
  }
  // ── Hooks ──────────────────────────────────────────────────
  /** Called right after shadow DOM is attached, before CSS or container. */
  onInit(u) {
  }
  /** Called after internals state is set to ready, before the `load` event. */
  onReady() {
  }
  /** Called when connectedCallback throws. Default logs to console. */
  onError(u) {
    console.error(`${this.constructor.name} initialization failed:`, u);
  }
  /** Called when observed attributes change. Override to update framework state. */
  onPropsChanged(u, t) {
  }
  /**
   * Extract text from a child `<template data-type="...">` element.
   * Uses `.content.textContent` since `<template>` stores content in a DocumentFragment.
   */
  _extractContent(u) {
    return this.querySelector(`template[data-type="${u}"]`)?.content.textContent?.trim() ?? null;
  }
  /** Called when child `<template>` content changes. Override to update framework state. */
  onContentChanged(u) {
  }
}
function Li(e) {
  return e.__wippyHostBus ?? null;
}
function Pi(e) {
  return e.dataset.wippyPanelId ?? null;
}
class Gi extends Qi {
  constructor() {
    super(...arguments), this._vueApp = null, this._propsRef = ku({}), this._errorsRef = ku([]), this._contentRef = ku(null);
  }
  /**
   * Override to provide Vue-specific configuration.
   */
  static get vueConfig() {
    throw new Error("WippyVueElement subclass must override static get vueConfig()");
  }
  onMount(u, t, c, s, i, l) {
    const a = this.constructor.vueConfig;
    this._propsRef.value = c, this._errorsRef.value = s, this._contentRef.value = i ?? null;
    for (const n of s)
      this.emitEvent("invalid", { message: n });
    const o = Ci();
    this._vueApp = bi(a.rootComponent);
    const r = vi();
    if (a.piniaPlugins)
      for (const n of a.piniaPlugins)
        r.use(n);
    if (this._vueApp.use(r), a.plugins)
      for (const n of a.plugins)
        this._vueApp.use(n);
    this._vueApp.provide(Ir, this._propsRef), this._vueApp.provide(Ii, this._errorsRef), this._vueApp.provide(Di, this.emitEvent.bind(this)), this._vueApp.provide(_r, this._contentRef), this._vueApp.provide(_i, Pi(this)), this._vueApp.provide(ki, Li(this)), this._vueApp.provide(Bi, kr(this)), a.providers && a.providers(this._vueApp, this), this._vueApp.mount(t), o && Ei(o);
  }
  onUnmount() {
    this._vueApp && (this._vueApp.unmount(), this._vueApp = null);
  }
  onPropsChanged(u, t) {
    this._propsRef.value = u, this._errorsRef.value = t;
    for (const c of t)
      this.emitEvent("invalid", { message: c });
  }
  onContentChanged(u) {
    this._contentRef.value = u;
  }
}
const Ht = {};
function qi(e) {
  let u = Ht[e];
  if (u)
    return u;
  u = Ht[e] = [];
  for (let t = 0; t < 128; t++) {
    const c = String.fromCharCode(t);
    u.push(c);
  }
  for (let t = 0; t < e.length; t++) {
    const c = e.charCodeAt(t);
    u[c] = "%" + ("0" + c.toString(16).toUpperCase()).slice(-2);
  }
  return u;
}
function Qe(e, u) {
  typeof u != "string" && (u = Qe.defaultChars);
  const t = qi(u);
  return e.replace(/(%[a-f0-9]{2})+/gi, function(c) {
    let s = "";
    for (let i = 0, l = c.length; i < l; i += 3) {
      const a = parseInt(c.slice(i + 1, i + 3), 16);
      if (a < 128) {
        s += t[a];
        continue;
      }
      if ((a & 224) === 192 && i + 3 < l) {
        const o = parseInt(c.slice(i + 4, i + 6), 16);
        if ((o & 192) === 128) {
          const r = a << 6 & 1984 | o & 63;
          r < 128 ? s += "��" : s += String.fromCharCode(r), i += 3;
          continue;
        }
      }
      if ((a & 240) === 224 && i + 6 < l) {
        const o = parseInt(c.slice(i + 4, i + 6), 16), r = parseInt(c.slice(i + 7, i + 9), 16);
        if ((o & 192) === 128 && (r & 192) === 128) {
          const n = a << 12 & 61440 | o << 6 & 4032 | r & 63;
          n < 2048 || n >= 55296 && n <= 57343 ? s += "���" : s += String.fromCharCode(n), i += 6;
          continue;
        }
      }
      if ((a & 248) === 240 && i + 9 < l) {
        const o = parseInt(c.slice(i + 4, i + 6), 16), r = parseInt(c.slice(i + 7, i + 9), 16), n = parseInt(c.slice(i + 10, i + 12), 16);
        if ((o & 192) === 128 && (r & 192) === 128 && (n & 192) === 128) {
          let f = a << 18 & 1835008 | o << 12 & 258048 | r << 6 & 4032 | n & 63;
          f < 65536 || f > 1114111 ? s += "����" : (f -= 65536, s += String.fromCharCode(55296 + (f >> 10), 56320 + (f & 1023))), i += 9;
          continue;
        }
      }
      s += "�";
    }
    return s;
  });
}
Qe.defaultChars = ";/?:@&=+$,#";
Qe.componentChars = "";
const Wt = {};
function Hi(e) {
  let u = Wt[e];
  if (u)
    return u;
  u = Wt[e] = [];
  for (let t = 0; t < 128; t++) {
    const c = String.fromCharCode(t);
    /^[0-9a-z]$/i.test(c) ? u.push(c) : u.push("%" + ("0" + t.toString(16).toUpperCase()).slice(-2));
  }
  for (let t = 0; t < e.length; t++)
    u[e.charCodeAt(t)] = e[t];
  return u;
}
function Ze(e, u, t) {
  typeof u != "string" && (t = u, u = Ze.defaultChars), typeof t > "u" && (t = !0);
  const c = Hi(u);
  let s = "";
  for (let i = 0, l = e.length; i < l; i++) {
    const a = e.charCodeAt(i);
    if (t && a === 37 && i + 2 < l && /^[0-9a-f]{2}$/i.test(e.slice(i + 1, i + 3))) {
      s += e.slice(i, i + 3), i += 2;
      continue;
    }
    if (a < 128) {
      s += c[a];
      continue;
    }
    if (a >= 55296 && a <= 57343) {
      if (a >= 55296 && a <= 56319 && i + 1 < l) {
        const o = e.charCodeAt(i + 1);
        if (o >= 56320 && o <= 57343) {
          s += encodeURIComponent(e[i] + e[i + 1]), i++;
          continue;
        }
      }
      s += "%EF%BF%BD";
      continue;
    }
    s += encodeURIComponent(e[i]);
  }
  return s;
}
Ze.defaultChars = ";/?:@&=+$,-_.!~*'()#";
Ze.componentChars = "-_.!~*'()";
function vt(e) {
  let u = "";
  return u += e.protocol || "", u += e.slashes ? "//" : "", u += e.auth ? e.auth + "@" : "", e.hostname && e.hostname.indexOf(":") !== -1 ? u += "[" + e.hostname + "]" : u += e.hostname || "", u += e.port ? ":" + e.port : "", u += e.pathname || "", u += e.search || "", u += e.hash || "", u;
}
function Au() {
  this.protocol = null, this.slashes = null, this.auth = null, this.port = null, this.hostname = null, this.hash = null, this.search = null, this.pathname = null;
}
const Wi = /^([a-z0-9.+-]+:)/i, Ui = /:[0-9]*$/, Ki = /^(\/\/?(?!\/)[^\?\s]*)(\?[^\s]*)?$/, Yi = ["<", ">", '"', "`", " ", "\r", `
`, "	"], ji = ["{", "}", "|", "\\", "^", "`"].concat(Yi), Ji = ["'"].concat(ji), Ut = ["%", "/", "?", ";", "#"].concat(Ji), Kt = ["/", "?", "#"], Zi = 255, Yt = /^[+a-z0-9A-Z_-]{0,63}$/, Vi = /^([+a-z0-9A-Z_-]{0,63})(.*)$/, jt = {
  javascript: !0,
  "javascript:": !0
}, Jt = {
  http: !0,
  https: !0,
  ftp: !0,
  gopher: !0,
  file: !0,
  "http:": !0,
  "https:": !0,
  "ftp:": !0,
  "gopher:": !0,
  "file:": !0
};
function Et(e, u) {
  if (e && e instanceof Au) return e;
  const t = new Au();
  return t.parse(e, u), t;
}
Au.prototype.parse = function(e, u) {
  let t, c, s, i = e;
  if (i = i.trim(), !u && e.split("#").length === 1) {
    const r = Ki.exec(i);
    if (r)
      return this.pathname = r[1], r[2] && (this.search = r[2]), this;
  }
  let l = Wi.exec(i);
  if (l && (l = l[0], t = l.toLowerCase(), this.protocol = l, i = i.substr(l.length)), (u || l || i.match(/^\/\/[^@\/]+@[^@\/]+/)) && (s = i.substr(0, 2) === "//", s && !(l && jt[l]) && (i = i.substr(2), this.slashes = !0)), !jt[l] && (s || l && !Jt[l])) {
    let r = -1;
    for (let h = 0; h < Kt.length; h++)
      c = i.indexOf(Kt[h]), c !== -1 && (r === -1 || c < r) && (r = c);
    let n, f;
    r === -1 ? f = i.lastIndexOf("@") : f = i.lastIndexOf("@", r), f !== -1 && (n = i.slice(0, f), i = i.slice(f + 1), this.auth = n), r = -1;
    for (let h = 0; h < Ut.length; h++)
      c = i.indexOf(Ut[h]), c !== -1 && (r === -1 || c < r) && (r = c);
    r === -1 && (r = i.length), i[r - 1] === ":" && r--;
    const d = i.slice(0, r);
    i = i.slice(r), this.parseHost(d), this.hostname = this.hostname || "";
    const A = this.hostname[0] === "[" && this.hostname[this.hostname.length - 1] === "]";
    if (!A) {
      const h = this.hostname.split(/\./);
      for (let w = 0, C = h.length; w < C; w++) {
        const b = h[w];
        if (b && !b.match(Yt)) {
          let m = "";
          for (let g = 0, x = b.length; g < x; g++)
            b.charCodeAt(g) > 127 ? m += "x" : m += b[g];
          if (!m.match(Yt)) {
            const g = h.slice(0, w), x = h.slice(w + 1), p = b.match(Vi);
            p && (g.push(p[1]), x.unshift(p[2])), x.length && (i = x.join(".") + i), this.hostname = g.join(".");
            break;
          }
        }
      }
    }
    this.hostname.length > Zi && (this.hostname = ""), A && (this.hostname = this.hostname.substr(1, this.hostname.length - 2));
  }
  const a = i.indexOf("#");
  a !== -1 && (this.hash = i.substr(a), i = i.slice(0, a));
  const o = i.indexOf("?");
  return o !== -1 && (this.search = i.substr(o), i = i.slice(0, o)), i && (this.pathname = i), Jt[t] && this.hostname && !this.pathname && (this.pathname = ""), this;
};
Au.prototype.parseHost = function(e) {
  let u = Ui.exec(e);
  u && (u = u[0], u !== ":" && (this.port = u.substr(1)), e = e.substr(0, e.length - u.length)), e && (this.hostname = e);
};
const zi = /* @__PURE__ */ Object.freeze(/* @__PURE__ */ Object.defineProperty({
  __proto__: null,
  decode: Qe,
  encode: Ze,
  format: vt,
  parse: Et
}, Symbol.toStringTag, { value: "Module" })), Br = /[\0-\uD7FF\uE000-\uFFFF]|[\uD800-\uDBFF][\uDC00-\uDFFF]|[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?:[^\uD800-\uDBFF]|^)[\uDC00-\uDFFF]/, Fr = /[\0-\x1F\x7F-\x9F]/, Xi = /[\xAD\u0600-\u0605\u061C\u06DD\u070F\u0890\u0891\u08E2\u180E\u200B-\u200F\u202A-\u202E\u2060-\u2064\u2066-\u206F\uFEFF\uFFF9-\uFFFB]|\uD804[\uDCBD\uDCCD]|\uD80D[\uDC30-\uDC3F]|\uD82F[\uDCA0-\uDCA3]|\uD834[\uDD73-\uDD7A]|\uDB40[\uDC01\uDC20-\uDC7F]/, Dt = /[!-#%-\*,-\/:;\?@\[-\]_\{\}\xA1\xA7\xAB\xB6\xB7\xBB\xBF\u037E\u0387\u055A-\u055F\u0589\u058A\u05BE\u05C0\u05C3\u05C6\u05F3\u05F4\u0609\u060A\u060C\u060D\u061B\u061D-\u061F\u066A-\u066D\u06D4\u0700-\u070D\u07F7-\u07F9\u0830-\u083E\u085E\u0964\u0965\u0970\u09FD\u0A76\u0AF0\u0C77\u0C84\u0DF4\u0E4F\u0E5A\u0E5B\u0F04-\u0F12\u0F14\u0F3A-\u0F3D\u0F85\u0FD0-\u0FD4\u0FD9\u0FDA\u104A-\u104F\u10FB\u1360-\u1368\u1400\u166E\u169B\u169C\u16EB-\u16ED\u1735\u1736\u17D4-\u17D6\u17D8-\u17DA\u1800-\u180A\u1944\u1945\u1A1E\u1A1F\u1AA0-\u1AA6\u1AA8-\u1AAD\u1B5A-\u1B60\u1B7D\u1B7E\u1BFC-\u1BFF\u1C3B-\u1C3F\u1C7E\u1C7F\u1CC0-\u1CC7\u1CD3\u2010-\u2027\u2030-\u2043\u2045-\u2051\u2053-\u205E\u207D\u207E\u208D\u208E\u2308-\u230B\u2329\u232A\u2768-\u2775\u27C5\u27C6\u27E6-\u27EF\u2983-\u2998\u29D8-\u29DB\u29FC\u29FD\u2CF9-\u2CFC\u2CFE\u2CFF\u2D70\u2E00-\u2E2E\u2E30-\u2E4F\u2E52-\u2E5D\u3001-\u3003\u3008-\u3011\u3014-\u301F\u3030\u303D\u30A0\u30FB\uA4FE\uA4FF\uA60D-\uA60F\uA673\uA67E\uA6F2-\uA6F7\uA874-\uA877\uA8CE\uA8CF\uA8F8-\uA8FA\uA8FC\uA92E\uA92F\uA95F\uA9C1-\uA9CD\uA9DE\uA9DF\uAA5C-\uAA5F\uAADE\uAADF\uAAF0\uAAF1\uABEB\uFD3E\uFD3F\uFE10-\uFE19\uFE30-\uFE52\uFE54-\uFE61\uFE63\uFE68\uFE6A\uFE6B\uFF01-\uFF03\uFF05-\uFF0A\uFF0C-\uFF0F\uFF1A\uFF1B\uFF1F\uFF20\uFF3B-\uFF3D\uFF3F\uFF5B\uFF5D\uFF5F-\uFF65]|\uD800[\uDD00-\uDD02\uDF9F\uDFD0]|\uD801\uDD6F|\uD802[\uDC57\uDD1F\uDD3F\uDE50-\uDE58\uDE7F\uDEF0-\uDEF6\uDF39-\uDF3F\uDF99-\uDF9C]|\uD803[\uDEAD\uDF55-\uDF59\uDF86-\uDF89]|\uD804[\uDC47-\uDC4D\uDCBB\uDCBC\uDCBE-\uDCC1\uDD40-\uDD43\uDD74\uDD75\uDDC5-\uDDC8\uDDCD\uDDDB\uDDDD-\uDDDF\uDE38-\uDE3D\uDEA9]|\uD805[\uDC4B-\uDC4F\uDC5A\uDC5B\uDC5D\uDCC6\uDDC1-\uDDD7\uDE41-\uDE43\uDE60-\uDE6C\uDEB9\uDF3C-\uDF3E]|\uD806[\uDC3B\uDD44-\uDD46\uDDE2\uDE3F-\uDE46\uDE9A-\uDE9C\uDE9E-\uDEA2\uDF00-\uDF09]|\uD807[\uDC41-\uDC45\uDC70\uDC71\uDEF7\uDEF8\uDF43-\uDF4F\uDFFF]|\uD809[\uDC70-\uDC74]|\uD80B[\uDFF1\uDFF2]|\uD81A[\uDE6E\uDE6F\uDEF5\uDF37-\uDF3B\uDF44]|\uD81B[\uDE97-\uDE9A\uDFE2]|\uD82F\uDC9F|\uD836[\uDE87-\uDE8B]|\uD83A[\uDD5E\uDD5F]/, Sr = /[\$\+<->\^`\|~\xA2-\xA6\xA8\xA9\xAC\xAE-\xB1\xB4\xB8\xD7\xF7\u02C2-\u02C5\u02D2-\u02DF\u02E5-\u02EB\u02ED\u02EF-\u02FF\u0375\u0384\u0385\u03F6\u0482\u058D-\u058F\u0606-\u0608\u060B\u060E\u060F\u06DE\u06E9\u06FD\u06FE\u07F6\u07FE\u07FF\u0888\u09F2\u09F3\u09FA\u09FB\u0AF1\u0B70\u0BF3-\u0BFA\u0C7F\u0D4F\u0D79\u0E3F\u0F01-\u0F03\u0F13\u0F15-\u0F17\u0F1A-\u0F1F\u0F34\u0F36\u0F38\u0FBE-\u0FC5\u0FC7-\u0FCC\u0FCE\u0FCF\u0FD5-\u0FD8\u109E\u109F\u1390-\u1399\u166D\u17DB\u1940\u19DE-\u19FF\u1B61-\u1B6A\u1B74-\u1B7C\u1FBD\u1FBF-\u1FC1\u1FCD-\u1FCF\u1FDD-\u1FDF\u1FED-\u1FEF\u1FFD\u1FFE\u2044\u2052\u207A-\u207C\u208A-\u208C\u20A0-\u20C0\u2100\u2101\u2103-\u2106\u2108\u2109\u2114\u2116-\u2118\u211E-\u2123\u2125\u2127\u2129\u212E\u213A\u213B\u2140-\u2144\u214A-\u214D\u214F\u218A\u218B\u2190-\u2307\u230C-\u2328\u232B-\u2426\u2440-\u244A\u249C-\u24E9\u2500-\u2767\u2794-\u27C4\u27C7-\u27E5\u27F0-\u2982\u2999-\u29D7\u29DC-\u29FB\u29FE-\u2B73\u2B76-\u2B95\u2B97-\u2BFF\u2CE5-\u2CEA\u2E50\u2E51\u2E80-\u2E99\u2E9B-\u2EF3\u2F00-\u2FD5\u2FF0-\u2FFF\u3004\u3012\u3013\u3020\u3036\u3037\u303E\u303F\u309B\u309C\u3190\u3191\u3196-\u319F\u31C0-\u31E3\u31EF\u3200-\u321E\u322A-\u3247\u3250\u3260-\u327F\u328A-\u32B0\u32C0-\u33FF\u4DC0-\u4DFF\uA490-\uA4C6\uA700-\uA716\uA720\uA721\uA789\uA78A\uA828-\uA82B\uA836-\uA839\uAA77-\uAA79\uAB5B\uAB6A\uAB6B\uFB29\uFBB2-\uFBC2\uFD40-\uFD4F\uFDCF\uFDFC-\uFDFF\uFE62\uFE64-\uFE66\uFE69\uFF04\uFF0B\uFF1C-\uFF1E\uFF3E\uFF40\uFF5C\uFF5E\uFFE0-\uFFE6\uFFE8-\uFFEE\uFFFC\uFFFD]|\uD800[\uDD37-\uDD3F\uDD79-\uDD89\uDD8C-\uDD8E\uDD90-\uDD9C\uDDA0\uDDD0-\uDDFC]|\uD802[\uDC77\uDC78\uDEC8]|\uD805\uDF3F|\uD807[\uDFD5-\uDFF1]|\uD81A[\uDF3C-\uDF3F\uDF45]|\uD82F\uDC9C|\uD833[\uDF50-\uDFC3]|\uD834[\uDC00-\uDCF5\uDD00-\uDD26\uDD29-\uDD64\uDD6A-\uDD6C\uDD83\uDD84\uDD8C-\uDDA9\uDDAE-\uDDEA\uDE00-\uDE41\uDE45\uDF00-\uDF56]|\uD835[\uDEC1\uDEDB\uDEFB\uDF15\uDF35\uDF4F\uDF6F\uDF89\uDFA9\uDFC3]|\uD836[\uDC00-\uDDFF\uDE37-\uDE3A\uDE6D-\uDE74\uDE76-\uDE83\uDE85\uDE86]|\uD838[\uDD4F\uDEFF]|\uD83B[\uDCAC\uDCB0\uDD2E\uDEF0\uDEF1]|\uD83C[\uDC00-\uDC2B\uDC30-\uDC93\uDCA0-\uDCAE\uDCB1-\uDCBF\uDCC1-\uDCCF\uDCD1-\uDCF5\uDD0D-\uDDAD\uDDE6-\uDE02\uDE10-\uDE3B\uDE40-\uDE48\uDE50\uDE51\uDE60-\uDE65\uDF00-\uDFFF]|\uD83D[\uDC00-\uDED7\uDEDC-\uDEEC\uDEF0-\uDEFC\uDF00-\uDF76\uDF7B-\uDFD9\uDFE0-\uDFEB\uDFF0]|\uD83E[\uDC00-\uDC0B\uDC10-\uDC47\uDC50-\uDC59\uDC60-\uDC87\uDC90-\uDCAD\uDCB0\uDCB1\uDD00-\uDE53\uDE60-\uDE6D\uDE70-\uDE7C\uDE80-\uDE88\uDE90-\uDEBD\uDEBF-\uDEC5\uDECE-\uDEDB\uDEE0-\uDEE8\uDEF0-\uDEF8\uDF00-\uDF92\uDF94-\uDFCA]/, Rr = /[ \xA0\u1680\u2000-\u200A\u2028\u2029\u202F\u205F\u3000]/, $i = /* @__PURE__ */ Object.freeze(/* @__PURE__ */ Object.defineProperty({
  __proto__: null,
  Any: Br,
  Cc: Fr,
  Cf: Xi,
  P: Dt,
  S: Sr,
  Z: Rr
}, Symbol.toStringTag, { value: "Module" })), en = new Uint16Array(
  // prettier-ignore
  'ᵁ<Õıʊҝջאٵ۞ޢߖࠏ੊ઑඡ๭༉༦჊ረዡᐕᒝᓃᓟᔥ\0\0\0\0\0\0ᕫᛍᦍᰒᷝ὾⁠↰⊍⏀⏻⑂⠤⤒ⴈ⹈⿎〖㊺㘹㞬㣾㨨㩱㫠㬮ࠀEMabcfglmnoprstu\\bfms¦³¹ÈÏlig耻Æ䃆P耻&䀦cute耻Á䃁reve;䄂Āiyx}rc耻Â䃂;䐐r;쀀𝔄rave耻À䃀pha;䎑acr;䄀d;橓Āgp¡on;䄄f;쀀𝔸plyFunction;恡ing耻Å䃅Ācs¾Ãr;쀀𝒜ign;扔ilde耻Ã䃃ml耻Ä䃄ЀaceforsuåûþėĜĢħĪĀcrêòkslash;或Ŷöø;櫧ed;挆y;䐑ƀcrtąċĔause;戵noullis;愬a;䎒r;쀀𝔅pf;쀀𝔹eve;䋘còēmpeq;扎܀HOacdefhilorsuōőŖƀƞƢƵƷƺǜȕɳɸɾcy;䐧PY耻©䂩ƀcpyŝŢźute;䄆Ā;iŧŨ拒talDifferentialD;慅leys;愭ȀaeioƉƎƔƘron;䄌dil耻Ç䃇rc;䄈nint;戰ot;䄊ĀdnƧƭilla;䂸terDot;䂷òſi;䎧rcleȀDMPTǇǋǑǖot;抙inus;抖lus;投imes;抗oĀcsǢǸkwiseContourIntegral;戲eCurlyĀDQȃȏoubleQuote;思uote;怙ȀlnpuȞȨɇɕonĀ;eȥȦ户;橴ƀgitȯȶȺruent;扡nt;戯ourIntegral;戮ĀfrɌɎ;愂oduct;成nterClockwiseContourIntegral;戳oss;樯cr;쀀𝒞pĀ;Cʄʅ拓ap;才րDJSZacefiosʠʬʰʴʸˋ˗ˡ˦̳ҍĀ;oŹʥtrahd;椑cy;䐂cy;䐅cy;䐏ƀgrsʿ˄ˇger;怡r;憡hv;櫤Āayː˕ron;䄎;䐔lĀ;t˝˞戇a;䎔r;쀀𝔇Āaf˫̧Ācm˰̢riticalȀADGT̖̜̀̆cute;䂴oŴ̋̍;䋙bleAcute;䋝rave;䁠ilde;䋜ond;拄ferentialD;慆Ѱ̽\0\0\0͔͂\0Ѕf;쀀𝔻ƀ;DE͈͉͍䂨ot;惜qual;扐blèCDLRUVͣͲ΂ϏϢϸontourIntegraìȹoɴ͹\0\0ͻ»͉nArrow;懓Āeo·ΤftƀARTΐΖΡrrow;懐ightArrow;懔eåˊngĀLRΫτeftĀARγιrrow;柸ightArrow;柺ightArrow;柹ightĀATϘϞrrow;懒ee;抨pɁϩ\0\0ϯrrow;懑ownArrow;懕erticalBar;戥ǹABLRTaВЪаўѿͼrrowƀ;BUНОТ憓ar;椓pArrow;懵reve;䌑eft˒к\0ц\0ѐightVector;楐eeVector;楞ectorĀ;Bљњ憽ar;楖ightǔѧ\0ѱeeVector;楟ectorĀ;BѺѻ懁ar;楗eeĀ;A҆҇护rrow;憧ĀctҒҗr;쀀𝒟rok;䄐ࠀNTacdfglmopqstuxҽӀӄӋӞӢӧӮӵԡԯԶՒ՝ՠեG;䅊H耻Ð䃐cute耻É䃉ƀaiyӒӗӜron;䄚rc耻Ê䃊;䐭ot;䄖r;쀀𝔈rave耻È䃈ement;戈ĀapӺӾcr;䄒tyɓԆ\0\0ԒmallSquare;旻erySmallSquare;斫ĀgpԦԪon;䄘f;쀀𝔼silon;䎕uĀaiԼՉlĀ;TՂՃ橵ilde;扂librium;懌Āci՗՚r;愰m;橳a;䎗ml耻Ë䃋Āipժկsts;戃onentialE;慇ʀcfiosօֈ֍ֲ׌y;䐤r;쀀𝔉lledɓ֗\0\0֣mallSquare;旼erySmallSquare;斪Ͱֺ\0ֿ\0\0ׄf;쀀𝔽All;戀riertrf;愱cò׋؀JTabcdfgorstר׬ׯ׺؀ؒؖ؛؝أ٬ٲcy;䐃耻>䀾mmaĀ;d׷׸䎓;䏜reve;䄞ƀeiy؇،ؐdil;䄢rc;䄜;䐓ot;䄠r;쀀𝔊;拙pf;쀀𝔾eater̀EFGLSTصلَٖٛ٦qualĀ;Lؾؿ扥ess;招ullEqual;执reater;檢ess;扷lantEqual;橾ilde;扳cr;쀀𝒢;扫ЀAacfiosuڅڋږڛڞڪھۊRDcy;䐪Āctڐڔek;䋇;䁞irc;䄤r;愌lbertSpace;愋ǰگ\0ڲf;愍izontalLine;攀Āctۃۅòکrok;䄦mpńېۘownHumðįqual;扏܀EJOacdfgmnostuۺ۾܃܇܎ܚܞܡܨ݄ݸދޏޕcy;䐕lig;䄲cy;䐁cute耻Í䃍Āiyܓܘrc耻Î䃎;䐘ot;䄰r;愑rave耻Ì䃌ƀ;apܠܯܿĀcgܴܷr;䄪inaryI;慈lieóϝǴ݉\0ݢĀ;eݍݎ戬Āgrݓݘral;戫section;拂isibleĀCTݬݲomma;恣imes;恢ƀgptݿރވon;䄮f;쀀𝕀a;䎙cr;愐ilde;䄨ǫޚ\0ޞcy;䐆l耻Ï䃏ʀcfosuެ޷޼߂ߐĀiyޱ޵rc;䄴;䐙r;쀀𝔍pf;쀀𝕁ǣ߇\0ߌr;쀀𝒥rcy;䐈kcy;䐄΀HJacfosߤߨ߽߬߱ࠂࠈcy;䐥cy;䐌ppa;䎚Āey߶߻dil;䄶;䐚r;쀀𝔎pf;쀀𝕂cr;쀀𝒦րJTaceflmostࠥࠩࠬࡐࡣ঳সে্਷ੇcy;䐉耻<䀼ʀcmnpr࠷࠼ࡁࡄࡍute;䄹bda;䎛g;柪lacetrf;愒r;憞ƀaeyࡗ࡜ࡡron;䄽dil;䄻;䐛Āfsࡨ॰tԀACDFRTUVarࡾࢩࢱࣦ࣠ࣼयज़ΐ४Ānrࢃ࢏gleBracket;柨rowƀ;BR࢙࢚࢞憐ar;懤ightArrow;懆eiling;挈oǵࢷ\0ࣃbleBracket;柦nǔࣈ\0࣒eeVector;楡ectorĀ;Bࣛࣜ懃ar;楙loor;挊ightĀAV࣯ࣵrrow;憔ector;楎Āerँगeƀ;AVउऊऐ抣rrow;憤ector;楚iangleƀ;BEतथऩ抲ar;槏qual;抴pƀDTVषूौownVector;楑eeVector;楠ectorĀ;Bॖॗ憿ar;楘ectorĀ;B॥०憼ar;楒ightáΜs̀EFGLSTॾঋকঝঢভqualGreater;拚ullEqual;扦reater;扶ess;檡lantEqual;橽ilde;扲r;쀀𝔏Ā;eঽা拘ftarrow;懚idot;䄿ƀnpw৔ਖਛgȀLRlr৞৷ਂਐeftĀAR০৬rrow;柵ightArrow;柷ightArrow;柶eftĀarγਊightáοightáϊf;쀀𝕃erĀLRਢਬeftArrow;憙ightArrow;憘ƀchtਾੀੂòࡌ;憰rok;䅁;扪Ѐacefiosuਗ਼੝੠੷੼અઋ઎p;椅y;䐜Ādl੥੯iumSpace;恟lintrf;愳r;쀀𝔐nusPlus;戓pf;쀀𝕄cò੶;䎜ҀJacefostuણધભીଔଙඑ඗ඞcy;䐊cute;䅃ƀaey઴હાron;䅇dil;䅅;䐝ƀgswે૰଎ativeƀMTV૓૟૨ediumSpace;怋hiĀcn૦૘ë૙eryThiî૙tedĀGL૸ଆreaterGreateòٳessLesóੈLine;䀊r;쀀𝔑ȀBnptଢନଷ଺reak;恠BreakingSpace;䂠f;愕ڀ;CDEGHLNPRSTV୕ୖ୪୼஡௫ఄ౞಄ದ೘ൡඅ櫬Āou୛୤ngruent;扢pCap;扭oubleVerticalBar;戦ƀlqxஃஊ஛ement;戉ualĀ;Tஒஓ扠ilde;쀀≂̸ists;戄reater΀;EFGLSTஶஷ஽௉௓௘௥扯qual;扱ullEqual;쀀≧̸reater;쀀≫̸ess;批lantEqual;쀀⩾̸ilde;扵umpń௲௽ownHump;쀀≎̸qual;쀀≏̸eĀfsఊధtTriangleƀ;BEచఛడ拪ar;쀀⧏̸qual;括s̀;EGLSTవశ఼ౄోౘ扮qual;扰reater;扸ess;쀀≪̸lantEqual;쀀⩽̸ilde;扴estedĀGL౨౹reaterGreater;쀀⪢̸essLess;쀀⪡̸recedesƀ;ESಒಓಛ技qual;쀀⪯̸lantEqual;拠ĀeiಫಹverseElement;戌ghtTriangleƀ;BEೋೌ೒拫ar;쀀⧐̸qual;拭ĀquೝഌuareSuĀbp೨೹setĀ;E೰ೳ쀀⊏̸qual;拢ersetĀ;Eഃആ쀀⊐̸qual;拣ƀbcpഓതൎsetĀ;Eഛഞ쀀⊂⃒qual;抈ceedsȀ;ESTലള഻െ抁qual;쀀⪰̸lantEqual;拡ilde;쀀≿̸ersetĀ;E൘൛쀀⊃⃒qual;抉ildeȀ;EFT൮൯൵ൿ扁qual;扄ullEqual;扇ilde;扉erticalBar;戤cr;쀀𝒩ilde耻Ñ䃑;䎝܀Eacdfgmoprstuvලෂ෉෕ෛ෠෧෼ขภยา฿ไlig;䅒cute耻Ó䃓Āiy෎ීrc耻Ô䃔;䐞blac;䅐r;쀀𝔒rave耻Ò䃒ƀaei෮ෲ෶cr;䅌ga;䎩cron;䎟pf;쀀𝕆enCurlyĀDQฎบoubleQuote;怜uote;怘;橔Āclวฬr;쀀𝒪ash耻Ø䃘iŬื฼de耻Õ䃕es;樷ml耻Ö䃖erĀBP๋๠Āar๐๓r;怾acĀek๚๜;揞et;掴arenthesis;揜Ҁacfhilors๿ງຊຏຒດຝະ໼rtialD;戂y;䐟r;쀀𝔓i;䎦;䎠usMinus;䂱Āipຢອncareplanåڝf;愙Ȁ;eio຺ູ໠໤檻cedesȀ;EST່້໏໚扺qual;檯lantEqual;扼ilde;找me;怳Ādp໩໮uct;戏ortionĀ;aȥ໹l;戝Āci༁༆r;쀀𝒫;䎨ȀUfos༑༖༛༟OT耻"䀢r;쀀𝔔pf;愚cr;쀀𝒬؀BEacefhiorsu༾གྷཇའཱིྦྷྪྭ႖ႩႴႾarr;椐G耻®䂮ƀcnrཎནབute;䅔g;柫rĀ;tཛྷཝ憠l;椖ƀaeyཧཬཱron;䅘dil;䅖;䐠Ā;vླྀཹ愜erseĀEUྂྙĀlq྇ྎement;戋uilibrium;懋pEquilibrium;楯r»ཹo;䎡ghtЀACDFTUVa࿁࿫࿳ဢဨၛႇϘĀnr࿆࿒gleBracket;柩rowƀ;BL࿜࿝࿡憒ar;懥eftArrow;懄eiling;按oǵ࿹\0စbleBracket;柧nǔည\0နeeVector;楝ectorĀ;Bဝသ懂ar;楕loor;挋Āerိ၃eƀ;AVဵံြ抢rrow;憦ector;楛iangleƀ;BEၐၑၕ抳ar;槐qual;抵pƀDTVၣၮၸownVector;楏eeVector;楜ectorĀ;Bႂႃ憾ar;楔ectorĀ;B႑႒懀ar;楓Āpuႛ႞f;愝ndImplies;楰ightarrow;懛ĀchႹႼr;愛;憱leDelayed;槴ڀHOacfhimoqstuფჱჷჽᄙᄞᅑᅖᅡᅧᆵᆻᆿĀCcჩხHcy;䐩y;䐨FTcy;䐬cute;䅚ʀ;aeiyᄈᄉᄎᄓᄗ檼ron;䅠dil;䅞rc;䅜;䐡r;쀀𝔖ortȀDLRUᄪᄴᄾᅉownArrow»ОeftArrow»࢚ightArrow»࿝pArrow;憑gma;䎣allCircle;战pf;쀀𝕊ɲᅭ\0\0ᅰt;戚areȀ;ISUᅻᅼᆉᆯ斡ntersection;抓uĀbpᆏᆞsetĀ;Eᆗᆘ抏qual;抑ersetĀ;Eᆨᆩ抐qual;抒nion;抔cr;쀀𝒮ar;拆ȀbcmpᇈᇛሉላĀ;sᇍᇎ拐etĀ;Eᇍᇕqual;抆ĀchᇠህeedsȀ;ESTᇭᇮᇴᇿ扻qual;檰lantEqual;扽ilde;承Tháྌ;我ƀ;esሒሓሣ拑rsetĀ;Eሜም抃qual;抇et»ሓրHRSacfhiorsሾቄ቉ቕ቞ቱቶኟዂወዑORN耻Þ䃞ADE;愢ĀHc቎ቒcy;䐋y;䐦Ābuቚቜ;䀉;䎤ƀaeyብቪቯron;䅤dil;䅢;䐢r;쀀𝔗Āeiቻ኉ǲኀ\0ኇefore;戴a;䎘Ācn኎ኘkSpace;쀀  Space;怉ldeȀ;EFTካኬኲኼ戼qual;扃ullEqual;扅ilde;扈pf;쀀𝕋ipleDot;惛Āctዖዛr;쀀𝒯rok;䅦ૡዷጎጚጦ\0ጬጱ\0\0\0\0\0ጸጽ፷ᎅ\0᏿ᐄᐊᐐĀcrዻጁute耻Ú䃚rĀ;oጇገ憟cir;楉rǣጓ\0጖y;䐎ve;䅬Āiyጞጣrc耻Û䃛;䐣blac;䅰r;쀀𝔘rave耻Ù䃙acr;䅪Ādiፁ፩erĀBPፈ፝Āarፍፐr;䁟acĀekፗፙ;揟et;掵arenthesis;揝onĀ;P፰፱拃lus;抎Āgp፻፿on;䅲f;쀀𝕌ЀADETadps᎕ᎮᎸᏄϨᏒᏗᏳrrowƀ;BDᅐᎠᎤar;椒ownArrow;懅ownArrow;憕quilibrium;楮eeĀ;AᏋᏌ报rrow;憥ownáϳerĀLRᏞᏨeftArrow;憖ightArrow;憗iĀ;lᏹᏺ䏒on;䎥ing;䅮cr;쀀𝒰ilde;䅨ml耻Ü䃜ҀDbcdefosvᐧᐬᐰᐳᐾᒅᒊᒐᒖash;披ar;櫫y;䐒ashĀ;lᐻᐼ抩;櫦Āerᑃᑅ;拁ƀbtyᑌᑐᑺar;怖Ā;iᑏᑕcalȀBLSTᑡᑥᑪᑴar;戣ine;䁼eparator;杘ilde;所ThinSpace;怊r;쀀𝔙pf;쀀𝕍cr;쀀𝒱dash;抪ʀcefosᒧᒬᒱᒶᒼirc;䅴dge;拀r;쀀𝔚pf;쀀𝕎cr;쀀𝒲Ȁfiosᓋᓐᓒᓘr;쀀𝔛;䎞pf;쀀𝕏cr;쀀𝒳ҀAIUacfosuᓱᓵᓹᓽᔄᔏᔔᔚᔠcy;䐯cy;䐇cy;䐮cute耻Ý䃝Āiyᔉᔍrc;䅶;䐫r;쀀𝔜pf;쀀𝕐cr;쀀𝒴ml;䅸ЀHacdefosᔵᔹᔿᕋᕏᕝᕠᕤcy;䐖cute;䅹Āayᕄᕉron;䅽;䐗ot;䅻ǲᕔ\0ᕛoWidtè૙a;䎖r;愨pf;愤cr;쀀𝒵௡ᖃᖊᖐ\0ᖰᖶᖿ\0\0\0\0ᗆᗛᗫᙟ᙭\0ᚕ᚛ᚲᚹ\0ᚾcute耻á䃡reve;䄃̀;Ediuyᖜᖝᖡᖣᖨᖭ戾;쀀∾̳;房rc耻â䃢te肻´̆;䐰lig耻æ䃦Ā;r²ᖺ;쀀𝔞rave耻à䃠ĀepᗊᗖĀfpᗏᗔsym;愵èᗓha;䎱ĀapᗟcĀclᗤᗧr;䄁g;樿ɤᗰ\0\0ᘊʀ;adsvᗺᗻᗿᘁᘇ戧nd;橕;橜lope;橘;橚΀;elmrszᘘᘙᘛᘞᘿᙏᙙ戠;榤e»ᘙsdĀ;aᘥᘦ戡ѡᘰᘲᘴᘶᘸᘺᘼᘾ;榨;榩;榪;榫;榬;榭;榮;榯tĀ;vᙅᙆ戟bĀ;dᙌᙍ抾;榝Āptᙔᙗh;戢»¹arr;捼Āgpᙣᙧon;䄅f;쀀𝕒΀;Eaeiop዁ᙻᙽᚂᚄᚇᚊ;橰cir;橯;扊d;手s;䀧roxĀ;e዁ᚒñᚃing耻å䃥ƀctyᚡᚦᚨr;쀀𝒶;䀪mpĀ;e዁ᚯñʈilde耻ã䃣ml耻ä䃤Āciᛂᛈoninôɲnt;樑ࠀNabcdefiklnoprsu᛭ᛱᜰ᜼ᝃᝈ᝸᝽០៦ᠹᡐᜍ᤽᥈ᥰot;櫭Ācrᛶ᜞kȀcepsᜀᜅᜍᜓong;扌psilon;䏶rime;怵imĀ;e᜚᜛戽q;拍Ŷᜢᜦee;抽edĀ;gᜬᜭ挅e»ᜭrkĀ;t፜᜷brk;掶Āoyᜁᝁ;䐱quo;怞ʀcmprtᝓ᝛ᝡᝤᝨausĀ;eĊĉptyv;榰séᜌnoõēƀahwᝯ᝱ᝳ;䎲;愶een;扬r;쀀𝔟g΀costuvwឍឝឳេ៕៛៞ƀaiuបពរðݠrc;旯p»፱ƀdptឤឨឭot;樀lus;樁imes;樂ɱឹ\0\0ើcup;樆ar;昅riangleĀdu៍្own;施p;斳plus;樄eåᑄåᒭarow;植ƀako៭ᠦᠵĀcn៲ᠣkƀlst៺֫᠂ozenge;槫riangleȀ;dlr᠒᠓᠘᠝斴own;斾eft;旂ight;斸k;搣Ʊᠫ\0ᠳƲᠯ\0ᠱ;斒;斑4;斓ck;斈ĀeoᠾᡍĀ;qᡃᡆ쀀=⃥uiv;쀀≡⃥t;挐Ȁptwxᡙᡞᡧᡬf;쀀𝕓Ā;tᏋᡣom»Ꮜtie;拈؀DHUVbdhmptuvᢅᢖᢪᢻᣗᣛᣬ᣿ᤅᤊᤐᤡȀLRlrᢎᢐᢒᢔ;敗;敔;敖;敓ʀ;DUduᢡᢢᢤᢦᢨ敐;敦;敩;敤;敧ȀLRlrᢳᢵᢷᢹ;敝;敚;敜;教΀;HLRhlrᣊᣋᣍᣏᣑᣓᣕ救;敬;散;敠;敫;敢;敟ox;槉ȀLRlrᣤᣦᣨᣪ;敕;敒;攐;攌ʀ;DUduڽ᣷᣹᣻᣽;敥;敨;攬;攴inus;抟lus;択imes;抠ȀLRlrᤙᤛᤝ᤟;敛;敘;攘;攔΀;HLRhlrᤰᤱᤳᤵᤷ᤻᤹攂;敪;敡;敞;攼;攤;攜Āevģ᥂bar耻¦䂦Ȁceioᥑᥖᥚᥠr;쀀𝒷mi;恏mĀ;e᜚᜜lƀ;bhᥨᥩᥫ䁜;槅sub;柈Ŭᥴ᥾lĀ;e᥹᥺怢t»᥺pƀ;Eeįᦅᦇ;檮Ā;qۜۛೡᦧ\0᧨ᨑᨕᨲ\0ᨷᩐ\0\0᪴\0\0᫁\0\0ᬡᬮ᭍᭒\0᯽\0ᰌƀcpr᦭ᦲ᧝ute;䄇̀;abcdsᦿᧀᧄ᧊᧕᧙戩nd;橄rcup;橉Āau᧏᧒p;橋p;橇ot;橀;쀀∩︀Āeo᧢᧥t;恁îړȀaeiu᧰᧻ᨁᨅǰ᧵\0᧸s;橍on;䄍dil耻ç䃧rc;䄉psĀ;sᨌᨍ橌m;橐ot;䄋ƀdmnᨛᨠᨦil肻¸ƭptyv;榲t脀¢;eᨭᨮ䂢räƲr;쀀𝔠ƀceiᨽᩀᩍy;䑇ckĀ;mᩇᩈ朓ark»ᩈ;䏇r΀;Ecefms᩟᩠ᩢᩫ᪤᪪᪮旋;槃ƀ;elᩩᩪᩭ䋆q;扗eɡᩴ\0\0᪈rrowĀlr᩼᪁eft;憺ight;憻ʀRSacd᪒᪔᪖᪚᪟»ཇ;擈st;抛irc;抚ash;抝nint;樐id;櫯cir;槂ubsĀ;u᪻᪼晣it»᪼ˬ᫇᫔᫺\0ᬊonĀ;eᫍᫎ䀺Ā;qÇÆɭ᫙\0\0᫢aĀ;t᫞᫟䀬;䁀ƀ;fl᫨᫩᫫戁îᅠeĀmx᫱᫶ent»᫩eóɍǧ᫾\0ᬇĀ;dኻᬂot;橭nôɆƀfryᬐᬔᬗ;쀀𝕔oäɔ脀©;sŕᬝr;愗Āaoᬥᬩrr;憵ss;朗Ācuᬲᬷr;쀀𝒸Ābpᬼ᭄Ā;eᭁᭂ櫏;櫑Ā;eᭉᭊ櫐;櫒dot;拯΀delprvw᭠᭬᭷ᮂᮬᯔ᯹arrĀlr᭨᭪;椸;椵ɰ᭲\0\0᭵r;拞c;拟arrĀ;p᭿ᮀ憶;椽̀;bcdosᮏᮐᮖᮡᮥᮨ截rcap;橈Āauᮛᮞp;橆p;橊ot;抍r;橅;쀀∪︀Ȁalrv᮵ᮿᯞᯣrrĀ;mᮼᮽ憷;椼yƀevwᯇᯔᯘqɰᯎ\0\0ᯒreã᭳uã᭵ee;拎edge;拏en耻¤䂤earrowĀlrᯮ᯳eft»ᮀight»ᮽeäᯝĀciᰁᰇoninôǷnt;戱lcty;挭ঀAHabcdefhijlorstuwz᰸᰻᰿ᱝᱩᱵᲊᲞᲬᲷ᳻᳿ᴍᵻᶑᶫᶻ᷆᷍rò΁ar;楥Ȁglrs᱈ᱍ᱒᱔ger;怠eth;愸òᄳhĀ;vᱚᱛ怐»ऊūᱡᱧarow;椏aã̕Āayᱮᱳron;䄏;䐴ƀ;ao̲ᱼᲄĀgrʿᲁr;懊tseq;橷ƀglmᲑᲔᲘ耻°䂰ta;䎴ptyv;榱ĀirᲣᲨsht;楿;쀀𝔡arĀlrᲳᲵ»ࣜ»သʀaegsv᳂͸᳖᳜᳠mƀ;oș᳊᳔ndĀ;ș᳑uit;晦amma;䏝in;拲ƀ;io᳧᳨᳸䃷de脀÷;o᳧ᳰntimes;拇nø᳷cy;䑒cɯᴆ\0\0ᴊrn;挞op;挍ʀlptuwᴘᴝᴢᵉᵕlar;䀤f;쀀𝕕ʀ;emps̋ᴭᴷᴽᵂqĀ;d͒ᴳot;扑inus;戸lus;戔quare;抡blebarwedgåúnƀadhᄮᵝᵧownarrowóᲃarpoonĀlrᵲᵶefôᲴighôᲶŢᵿᶅkaro÷གɯᶊ\0\0ᶎrn;挟op;挌ƀcotᶘᶣᶦĀryᶝᶡ;쀀𝒹;䑕l;槶rok;䄑Ādrᶰᶴot;拱iĀ;fᶺ᠖斿Āah᷀᷃ròЩaòྦangle;榦Āci᷒ᷕy;䑟grarr;柿ऀDacdefglmnopqrstuxḁḉḙḸոḼṉṡṾấắẽỡἪἷὄ὎὚ĀDoḆᴴoôᲉĀcsḎḔute耻é䃩ter;橮ȀaioyḢḧḱḶron;䄛rĀ;cḭḮ扖耻ê䃪lon;払;䑍ot;䄗ĀDrṁṅot;扒;쀀𝔢ƀ;rsṐṑṗ檚ave耻è䃨Ā;dṜṝ檖ot;檘Ȁ;ilsṪṫṲṴ檙nters;揧;愓Ā;dṹṺ檕ot;檗ƀapsẅẉẗcr;䄓tyƀ;svẒẓẕ戅et»ẓpĀ1;ẝẤĳạả;怄;怅怃ĀgsẪẬ;䅋p;怂ĀgpẴẸon;䄙f;쀀𝕖ƀalsỄỎỒrĀ;sỊị拕l;槣us;橱iƀ;lvỚớở䎵on»ớ;䏵ȀcsuvỪỳἋἣĀioữḱrc»Ḯɩỹ\0\0ỻíՈantĀglἂἆtr»ṝess»Ṻƀaeiἒ἖Ἒls;䀽st;扟vĀ;DȵἠD;橸parsl;槥ĀDaἯἳot;打rr;楱ƀcdiἾὁỸr;愯oô͒ĀahὉὋ;䎷耻ð䃰Āmrὓὗl耻ë䃫o;悬ƀcipὡὤὧl;䀡sôծĀeoὬὴctatioîՙnentialåչৡᾒ\0ᾞ\0ᾡᾧ\0\0ῆῌ\0ΐ\0ῦῪ \0 ⁚llingdotseñṄy;䑄male;晀ƀilrᾭᾳ῁lig;耀ﬃɩᾹ\0\0᾽g;耀ﬀig;耀ﬄ;쀀𝔣lig;耀ﬁlig;쀀fjƀaltῙ῜ῡt;晭ig;耀ﬂns;斱of;䆒ǰ΅\0ῳf;쀀𝕗ĀakֿῷĀ;vῼ´拔;櫙artint;樍Āao‌⁕Ācs‑⁒α‚‰‸⁅⁈\0⁐β•‥‧‪‬\0‮耻½䂽;慓耻¼䂼;慕;慙;慛Ƴ‴\0‶;慔;慖ʴ‾⁁\0\0⁃耻¾䂾;慗;慜5;慘ƶ⁌\0⁎;慚;慝8;慞l;恄wn;挢cr;쀀𝒻ࢀEabcdefgijlnorstv₂₉₟₥₰₴⃰⃵⃺⃿℃ℒℸ̗ℾ⅒↞Ā;lٍ₇;檌ƀcmpₐₕ₝ute;䇵maĀ;dₜ᳚䎳;檆reve;䄟Āiy₪₮rc;䄝;䐳ot;䄡Ȁ;lqsؾق₽⃉ƀ;qsؾٌ⃄lanô٥Ȁ;cdl٥⃒⃥⃕c;檩otĀ;o⃜⃝檀Ā;l⃢⃣檂;檄Ā;e⃪⃭쀀⋛︀s;檔r;쀀𝔤Ā;gٳ؛mel;愷cy;䑓Ȁ;Eajٚℌℎℐ;檒;檥;檤ȀEaesℛℝ℩ℴ;扩pĀ;p℣ℤ檊rox»ℤĀ;q℮ℯ檈Ā;q℮ℛim;拧pf;쀀𝕘Āci⅃ⅆr;愊mƀ;el٫ⅎ⅐;檎;檐茀>;cdlqr׮ⅠⅪⅮⅳⅹĀciⅥⅧ;檧r;橺ot;拗Par;榕uest;橼ʀadelsↄⅪ←ٖ↛ǰ↉\0↎proø₞r;楸qĀlqؿ↖lesó₈ií٫Āen↣↭rtneqq;쀀≩︀Å↪ԀAabcefkosy⇄⇇⇱⇵⇺∘∝∯≨≽ròΠȀilmr⇐⇔⇗⇛rsðᒄf»․ilôکĀdr⇠⇤cy;䑊ƀ;cwࣴ⇫⇯ir;楈;憭ar;意irc;䄥ƀalr∁∎∓rtsĀ;u∉∊晥it»∊lip;怦con;抹r;쀀𝔥sĀew∣∩arow;椥arow;椦ʀamopr∺∾≃≞≣rr;懿tht;戻kĀlr≉≓eftarrow;憩ightarrow;憪f;쀀𝕙bar;怕ƀclt≯≴≸r;쀀𝒽asè⇴rok;䄧Ābp⊂⊇ull;恃hen»ᱛૡ⊣\0⊪\0⊸⋅⋎\0⋕⋳\0\0⋸⌢⍧⍢⍿\0⎆⎪⎴cute耻í䃭ƀ;iyݱ⊰⊵rc耻î䃮;䐸Ācx⊼⊿y;䐵cl耻¡䂡ĀfrΟ⋉;쀀𝔦rave耻ì䃬Ȁ;inoܾ⋝⋩⋮Āin⋢⋦nt;樌t;戭fin;槜ta;愩lig;䄳ƀaop⋾⌚⌝ƀcgt⌅⌈⌗r;䄫ƀelpܟ⌏⌓inåގarôܠh;䄱f;抷ed;䆵ʀ;cfotӴ⌬⌱⌽⍁are;愅inĀ;t⌸⌹戞ie;槝doô⌙ʀ;celpݗ⍌⍐⍛⍡al;抺Āgr⍕⍙eróᕣã⍍arhk;樗rod;樼Ȁcgpt⍯⍲⍶⍻y;䑑on;䄯f;쀀𝕚a;䎹uest耻¿䂿Āci⎊⎏r;쀀𝒾nʀ;EdsvӴ⎛⎝⎡ӳ;拹ot;拵Ā;v⎦⎧拴;拳Ā;iݷ⎮lde;䄩ǫ⎸\0⎼cy;䑖l耻ï䃯̀cfmosu⏌⏗⏜⏡⏧⏵Āiy⏑⏕rc;䄵;䐹r;쀀𝔧ath;䈷pf;쀀𝕛ǣ⏬\0⏱r;쀀𝒿rcy;䑘kcy;䑔Ѐacfghjos␋␖␢␧␭␱␵␻ppaĀ;v␓␔䎺;䏰Āey␛␠dil;䄷;䐺r;쀀𝔨reen;䄸cy;䑅cy;䑜pf;쀀𝕜cr;쀀𝓀஀ABEHabcdefghjlmnoprstuv⑰⒁⒆⒍⒑┎┽╚▀♎♞♥♹♽⚚⚲⛘❝❨➋⟀⠁⠒ƀart⑷⑺⑼rò৆òΕail;椛arr;椎Ā;gঔ⒋;檋ar;楢ॣ⒥\0⒪\0⒱\0\0\0\0\0⒵Ⓔ\0ⓆⓈⓍ\0⓹ute;䄺mptyv;榴raîࡌbda;䎻gƀ;dlࢎⓁⓃ;榑åࢎ;檅uo耻«䂫rЀ;bfhlpst࢙ⓞⓦⓩ⓫⓮⓱⓵Ā;f࢝ⓣs;椟s;椝ë≒p;憫l;椹im;楳l;憢ƀ;ae⓿─┄檫il;椙Ā;s┉┊檭;쀀⪭︀ƀabr┕┙┝rr;椌rk;杲Āak┢┬cĀek┨┪;䁻;䁛Āes┱┳;榋lĀdu┹┻;榏;榍Ȁaeuy╆╋╖╘ron;䄾Ādi═╔il;䄼ìࢰâ┩;䐻Ȁcqrs╣╦╭╽a;椶uoĀ;rนᝆĀdu╲╷har;楧shar;楋h;憲ʀ;fgqs▋▌উ◳◿扤tʀahlrt▘▤▷◂◨rrowĀ;t࢙□aé⓶arpoonĀdu▯▴own»њp»०eftarrows;懇ightƀahs◍◖◞rrowĀ;sࣴࢧarpoonó྘quigarro÷⇰hreetimes;拋ƀ;qs▋ও◺lanôবʀ;cdgsব☊☍☝☨c;檨otĀ;o☔☕橿Ā;r☚☛檁;檃Ā;e☢☥쀀⋚︀s;檓ʀadegs☳☹☽♉♋pproøⓆot;拖qĀgq♃♅ôউgtò⒌ôছiíলƀilr♕࣡♚sht;楼;쀀𝔩Ā;Eজ♣;檑š♩♶rĀdu▲♮Ā;l॥♳;楪lk;斄cy;䑙ʀ;achtੈ⚈⚋⚑⚖rò◁orneòᴈard;楫ri;旺Āio⚟⚤dot;䅀ustĀ;a⚬⚭掰che»⚭ȀEaes⚻⚽⛉⛔;扨pĀ;p⛃⛄檉rox»⛄Ā;q⛎⛏檇Ā;q⛎⚻im;拦Ѐabnoptwz⛩⛴⛷✚✯❁❇❐Ānr⛮⛱g;柬r;懽rëࣁgƀlmr⛿✍✔eftĀar০✇ightá৲apsto;柼ightá৽parrowĀlr✥✩efô⓭ight;憬ƀafl✶✹✽r;榅;쀀𝕝us;樭imes;樴š❋❏st;戗áፎƀ;ef❗❘᠀旊nge»❘arĀ;l❤❥䀨t;榓ʀachmt❳❶❼➅➇ròࢨorneòᶌarĀ;d྘➃;業;怎ri;抿̀achiqt➘➝ੀ➢➮➻quo;怹r;쀀𝓁mƀ;egল➪➬;檍;檏Ābu┪➳oĀ;rฟ➹;怚rok;䅂萀<;cdhilqrࠫ⟒☹⟜⟠⟥⟪⟰Āci⟗⟙;檦r;橹reå◲mes;拉arr;楶uest;橻ĀPi⟵⟹ar;榖ƀ;ef⠀भ᠛旃rĀdu⠇⠍shar;楊har;楦Āen⠗⠡rtneqq;쀀≨︀Å⠞܀Dacdefhilnopsu⡀⡅⢂⢎⢓⢠⢥⢨⣚⣢⣤ઃ⣳⤂Dot;戺Ȁclpr⡎⡒⡣⡽r耻¯䂯Āet⡗⡙;時Ā;e⡞⡟朠se»⡟Ā;sျ⡨toȀ;dluျ⡳⡷⡻owîҌefôएðᏑker;斮Āoy⢇⢌mma;権;䐼ash;怔asuredangle»ᘦr;쀀𝔪o;愧ƀcdn⢯⢴⣉ro耻µ䂵Ȁ;acdᑤ⢽⣀⣄sôᚧir;櫰ot肻·Ƶusƀ;bd⣒ᤃ⣓戒Ā;uᴼ⣘;横ţ⣞⣡p;櫛ò−ðઁĀdp⣩⣮els;抧f;쀀𝕞Āct⣸⣽r;쀀𝓂pos»ᖝƀ;lm⤉⤊⤍䎼timap;抸ఀGLRVabcdefghijlmoprstuvw⥂⥓⥾⦉⦘⧚⧩⨕⨚⩘⩝⪃⪕⪤⪨⬄⬇⭄⭿⮮ⰴⱧⱼ⳩Āgt⥇⥋;쀀⋙̸Ā;v⥐௏쀀≫⃒ƀelt⥚⥲⥶ftĀar⥡⥧rrow;懍ightarrow;懎;쀀⋘̸Ā;v⥻ే쀀≪⃒ightarrow;懏ĀDd⦎⦓ash;抯ash;抮ʀbcnpt⦣⦧⦬⦱⧌la»˞ute;䅄g;쀀∠⃒ʀ;Eiop඄⦼⧀⧅⧈;쀀⩰̸d;쀀≋̸s;䅉roø඄urĀ;a⧓⧔普lĀ;s⧓ସǳ⧟\0⧣p肻 ଷmpĀ;e௹ఀʀaeouy⧴⧾⨃⨐⨓ǰ⧹\0⧻;橃on;䅈dil;䅆ngĀ;dൾ⨊ot;쀀⩭̸p;橂;䐽ash;怓΀;Aadqsxஒ⨩⨭⨻⩁⩅⩐rr;懗rĀhr⨳⨶k;椤Ā;oᏲᏰot;쀀≐̸uiöୣĀei⩊⩎ar;椨í஘istĀ;s஠டr;쀀𝔫ȀEest௅⩦⩹⩼ƀ;qs஼⩭௡ƀ;qs஼௅⩴lanô௢ií௪Ā;rஶ⪁»ஷƀAap⪊⪍⪑rò⥱rr;憮ar;櫲ƀ;svྍ⪜ྌĀ;d⪡⪢拼;拺cy;䑚΀AEadest⪷⪺⪾⫂⫅⫶⫹rò⥦;쀀≦̸rr;憚r;急Ȁ;fqs఻⫎⫣⫯tĀar⫔⫙rro÷⫁ightarro÷⪐ƀ;qs఻⪺⫪lanôౕĀ;sౕ⫴»శiíౝĀ;rవ⫾iĀ;eచథiäඐĀpt⬌⬑f;쀀𝕟膀¬;in⬙⬚⬶䂬nȀ;Edvஉ⬤⬨⬮;쀀⋹̸ot;쀀⋵̸ǡஉ⬳⬵;拷;拶iĀ;vಸ⬼ǡಸ⭁⭃;拾;拽ƀaor⭋⭣⭩rȀ;ast୻⭕⭚⭟lleì୻l;쀀⫽⃥;쀀∂̸lint;樔ƀ;ceಒ⭰⭳uåಥĀ;cಘ⭸Ā;eಒ⭽ñಘȀAait⮈⮋⮝⮧rò⦈rrƀ;cw⮔⮕⮙憛;쀀⤳̸;쀀↝̸ghtarrow»⮕riĀ;eೋೖ΀chimpqu⮽⯍⯙⬄୸⯤⯯Ȁ;cerല⯆ഷ⯉uå൅;쀀𝓃ortɭ⬅\0\0⯖ará⭖mĀ;e൮⯟Ā;q൴൳suĀbp⯫⯭å೸åഋƀbcp⯶ⰑⰙȀ;Ees⯿ⰀഢⰄ抄;쀀⫅̸etĀ;eഛⰋqĀ;qണⰀcĀ;eലⰗñസȀ;EesⰢⰣൟⰧ抅;쀀⫆̸etĀ;e൘ⰮqĀ;qൠⰣȀgilrⰽⰿⱅⱇìௗlde耻ñ䃱çృiangleĀlrⱒⱜeftĀ;eచⱚñదightĀ;eೋⱥñ೗Ā;mⱬⱭ䎽ƀ;esⱴⱵⱹ䀣ro;愖p;怇ҀDHadgilrsⲏⲔⲙⲞⲣⲰⲶⳓⳣash;抭arr;椄p;쀀≍⃒ash;抬ĀetⲨⲬ;쀀≥⃒;쀀>⃒nfin;槞ƀAetⲽⳁⳅrr;椂;쀀≤⃒Ā;rⳊⳍ쀀<⃒ie;쀀⊴⃒ĀAtⳘⳜrr;椃rie;쀀⊵⃒im;쀀∼⃒ƀAan⳰⳴ⴂrr;懖rĀhr⳺⳽k;椣Ā;oᏧᏥear;椧ቓ᪕\0\0\0\0\0\0\0\0\0\0\0\0\0ⴭ\0ⴸⵈⵠⵥ⵲ⶄᬇ\0\0ⶍⶫ\0ⷈⷎ\0ⷜ⸙⸫⸾⹃Ācsⴱ᪗ute耻ó䃳ĀiyⴼⵅrĀ;c᪞ⵂ耻ô䃴;䐾ʀabios᪠ⵒⵗǈⵚlac;䅑v;樸old;榼lig;䅓Ācr⵩⵭ir;榿;쀀𝔬ͯ⵹\0\0⵼\0ⶂn;䋛ave耻ò䃲;槁Ābmⶈ෴ar;榵Ȁacitⶕ⶘ⶥⶨrò᪀Āir⶝ⶠr;榾oss;榻nå๒;槀ƀaeiⶱⶵⶹcr;䅍ga;䏉ƀcdnⷀⷅǍron;䎿;榶pf;쀀𝕠ƀaelⷔ⷗ǒr;榷rp;榹΀;adiosvⷪⷫⷮ⸈⸍⸐⸖戨rò᪆Ȁ;efmⷷⷸ⸂⸅橝rĀ;oⷾⷿ愴f»ⷿ耻ª䂪耻º䂺gof;抶r;橖lope;橗;橛ƀclo⸟⸡⸧ò⸁ash耻ø䃸l;折iŬⸯ⸴de耻õ䃵esĀ;aǛ⸺s;樶ml耻ö䃶bar;挽ૡ⹞\0⹽\0⺀⺝\0⺢⺹\0\0⻋ຜ\0⼓\0\0⼫⾼\0⿈rȀ;astЃ⹧⹲຅脀¶;l⹭⹮䂶leìЃɩ⹸\0\0⹻m;櫳;櫽y;䐿rʀcimpt⺋⺏⺓ᡥ⺗nt;䀥od;䀮il;怰enk;怱r;쀀𝔭ƀimo⺨⺰⺴Ā;v⺭⺮䏆;䏕maô੶ne;明ƀ;tv⺿⻀⻈䏀chfork»´;䏖Āau⻏⻟nĀck⻕⻝kĀ;h⇴⻛;愎ö⇴sҀ;abcdemst⻳⻴ᤈ⻹⻽⼄⼆⼊⼎䀫cir;樣ir;樢Āouᵀ⼂;樥;橲n肻±ຝim;樦wo;樧ƀipu⼙⼠⼥ntint;樕f;쀀𝕡nd耻£䂣Ԁ;Eaceinosu່⼿⽁⽄⽇⾁⾉⾒⽾⾶;檳p;檷uå໙Ā;c໎⽌̀;acens່⽙⽟⽦⽨⽾pproø⽃urlyeñ໙ñ໎ƀaes⽯⽶⽺pprox;檹qq;檵im;拨iíໟmeĀ;s⾈ຮ怲ƀEas⽸⾐⽺ð⽵ƀdfp໬⾙⾯ƀals⾠⾥⾪lar;挮ine;挒urf;挓Ā;t໻⾴ï໻rel;抰Āci⿀⿅r;쀀𝓅;䏈ncsp;怈̀fiopsu⿚⋢⿟⿥⿫⿱r;쀀𝔮pf;쀀𝕢rime;恗cr;쀀𝓆ƀaeo⿸〉〓tĀei⿾々rnionóڰnt;樖stĀ;e【】䀿ñἙô༔઀ABHabcdefhilmnoprstux぀けさすムㄎㄫㅇㅢㅲㆎ㈆㈕㈤㈩㉘㉮㉲㊐㊰㊷ƀartぇおがròႳòϝail;検aròᱥar;楤΀cdenqrtとふへみわゔヌĀeuねぱ;쀀∽̱te;䅕iãᅮmptyv;榳gȀ;del࿑らるろ;榒;榥å࿑uo耻»䂻rր;abcfhlpstw࿜ガクシスゼゾダッデナp;極Ā;f࿠ゴs;椠;椳s;椞ë≝ð✮l;楅im;楴l;憣;憝Āaiパフil;椚oĀ;nホボ戶aló༞ƀabrョリヮrò៥rk;杳ĀakンヽcĀekヹ・;䁽;䁝Āes㄂㄄;榌lĀduㄊㄌ;榎;榐Ȁaeuyㄗㄜㄧㄩron;䅙Ādiㄡㄥil;䅗ì࿲âヺ;䑀Ȁclqsㄴㄷㄽㅄa;椷dhar;楩uoĀ;rȎȍh;憳ƀacgㅎㅟངlȀ;ipsླྀㅘㅛႜnåႻarôྩt;断ƀilrㅩဣㅮsht;楽;쀀𝔯ĀaoㅷㆆrĀduㅽㅿ»ѻĀ;l႑ㆄ;楬Ā;vㆋㆌ䏁;䏱ƀgns㆕ㇹㇼht̀ahlrstㆤㆰ㇂㇘㇤㇮rrowĀ;t࿜ㆭaéトarpoonĀduㆻㆿowîㅾp»႒eftĀah㇊㇐rrowó࿪arpoonóՑightarrows;應quigarro÷ニhreetimes;拌g;䋚ingdotseñἲƀahm㈍㈐㈓rò࿪aòՑ;怏oustĀ;a㈞㈟掱che»㈟mid;櫮Ȁabpt㈲㈽㉀㉒Ānr㈷㈺g;柭r;懾rëဃƀafl㉇㉊㉎r;榆;쀀𝕣us;樮imes;樵Āap㉝㉧rĀ;g㉣㉤䀩t;榔olint;樒arò㇣Ȁachq㉻㊀Ⴜ㊅quo;怺r;쀀𝓇Ābu・㊊oĀ;rȔȓƀhir㊗㊛㊠reåㇸmes;拊iȀ;efl㊪ၙᠡ㊫方tri;槎luhar;楨;愞ൡ㋕㋛㋟㌬㌸㍱\0㍺㎤\0\0㏬㏰\0㐨㑈㑚㒭㒱㓊㓱\0㘖\0\0㘳cute;䅛quï➺Ԁ;Eaceinpsyᇭ㋳㋵㋿㌂㌋㌏㌟㌦㌩;檴ǰ㋺\0㋼;檸on;䅡uåᇾĀ;dᇳ㌇il;䅟rc;䅝ƀEas㌖㌘㌛;檶p;檺im;择olint;樓iíሄ;䑁otƀ;be㌴ᵇ㌵担;橦΀Aacmstx㍆㍊㍗㍛㍞㍣㍭rr;懘rĀhr㍐㍒ë∨Ā;oਸ਼਴t耻§䂧i;䀻war;椩mĀin㍩ðnuóñt;朶rĀ;o㍶⁕쀀𝔰Ȁacoy㎂㎆㎑㎠rp;景Āhy㎋㎏cy;䑉;䑈rtɭ㎙\0\0㎜iäᑤaraì⹯耻­䂭Āgm㎨㎴maƀ;fv㎱㎲㎲䏃;䏂Ѐ;deglnprካ㏅㏉㏎㏖㏞㏡㏦ot;橪Ā;q኱ኰĀ;E㏓㏔檞;檠Ā;E㏛㏜檝;檟e;扆lus;樤arr;楲aròᄽȀaeit㏸㐈㐏㐗Āls㏽㐄lsetmé㍪hp;樳parsl;槤Ādlᑣ㐔e;挣Ā;e㐜㐝檪Ā;s㐢㐣檬;쀀⪬︀ƀflp㐮㐳㑂tcy;䑌Ā;b㐸㐹䀯Ā;a㐾㐿槄r;挿f;쀀𝕤aĀdr㑍ЂesĀ;u㑔㑕晠it»㑕ƀcsu㑠㑹㒟Āau㑥㑯pĀ;sᆈ㑫;쀀⊓︀pĀ;sᆴ㑵;쀀⊔︀uĀbp㑿㒏ƀ;esᆗᆜ㒆etĀ;eᆗ㒍ñᆝƀ;esᆨᆭ㒖etĀ;eᆨ㒝ñᆮƀ;afᅻ㒦ְrť㒫ֱ»ᅼaròᅈȀcemt㒹㒾㓂㓅r;쀀𝓈tmîñiì㐕aræᆾĀar㓎㓕rĀ;f㓔ឿ昆Āan㓚㓭ightĀep㓣㓪psiloîỠhé⺯s»⡒ʀbcmnp㓻㕞ሉ㖋㖎Ҁ;Edemnprs㔎㔏㔑㔕㔞㔣㔬㔱㔶抂;櫅ot;檽Ā;dᇚ㔚ot;櫃ult;櫁ĀEe㔨㔪;櫋;把lus;檿arr;楹ƀeiu㔽㕒㕕tƀ;en㔎㕅㕋qĀ;qᇚ㔏eqĀ;q㔫㔨m;櫇Ābp㕚㕜;櫕;櫓c̀;acensᇭ㕬㕲㕹㕻㌦pproø㋺urlyeñᇾñᇳƀaes㖂㖈㌛pproø㌚qñ㌗g;晪ڀ123;Edehlmnps㖩㖬㖯ሜ㖲㖴㗀㗉㗕㗚㗟㗨㗭耻¹䂹耻²䂲耻³䂳;櫆Āos㖹㖼t;檾ub;櫘Ā;dሢ㗅ot;櫄sĀou㗏㗒l;柉b;櫗arr;楻ult;櫂ĀEe㗤㗦;櫌;抋lus;櫀ƀeiu㗴㘉㘌tƀ;enሜ㗼㘂qĀ;qሢ㖲eqĀ;q㗧㗤m;櫈Ābp㘑㘓;櫔;櫖ƀAan㘜㘠㘭rr;懙rĀhr㘦㘨ë∮Ā;oਫ਩war;椪lig耻ß䃟௡㙑㙝㙠ዎ㙳㙹\0㙾㛂\0\0\0\0\0㛛㜃\0㜉㝬\0\0\0㞇ɲ㙖\0\0㙛get;挖;䏄rë๟ƀaey㙦㙫㙰ron;䅥dil;䅣;䑂lrec;挕r;쀀𝔱Ȁeiko㚆㚝㚵㚼ǲ㚋\0㚑eĀ4fኄኁaƀ;sv㚘㚙㚛䎸ym;䏑Ācn㚢㚲kĀas㚨㚮pproø዁im»ኬsðኞĀas㚺㚮ð዁rn耻þ䃾Ǭ̟㛆⋧es膀×;bd㛏㛐㛘䃗Ā;aᤏ㛕r;樱;樰ƀeps㛡㛣㜀á⩍Ȁ;bcf҆㛬㛰㛴ot;挶ir;櫱Ā;o㛹㛼쀀𝕥rk;櫚á㍢rime;怴ƀaip㜏㜒㝤dåቈ΀adempst㜡㝍㝀㝑㝗㝜㝟ngleʀ;dlqr㜰㜱㜶㝀㝂斵own»ᶻeftĀ;e⠀㜾ñम;扜ightĀ;e㊪㝋ñၚot;旬inus;樺lus;樹b;槍ime;樻ezium;揢ƀcht㝲㝽㞁Āry㝷㝻;쀀𝓉;䑆cy;䑛rok;䅧Āio㞋㞎xô᝷headĀlr㞗㞠eftarro÷ࡏightarrow»ཝऀAHabcdfghlmoprstuw㟐㟓㟗㟤㟰㟼㠎㠜㠣㠴㡑㡝㡫㢩㣌㣒㣪㣶ròϭar;楣Ācr㟜㟢ute耻ú䃺òᅐrǣ㟪\0㟭y;䑞ve;䅭Āiy㟵㟺rc耻û䃻;䑃ƀabh㠃㠆㠋ròᎭlac;䅱aòᏃĀir㠓㠘sht;楾;쀀𝔲rave耻ù䃹š㠧㠱rĀlr㠬㠮»ॗ»ႃlk;斀Āct㠹㡍ɯ㠿\0\0㡊rnĀ;e㡅㡆挜r»㡆op;挏ri;旸Āal㡖㡚cr;䅫肻¨͉Āgp㡢㡦on;䅳f;쀀𝕦̀adhlsuᅋ㡸㡽፲㢑㢠ownáᎳarpoonĀlr㢈㢌efô㠭ighô㠯iƀ;hl㢙㢚㢜䏅»ᏺon»㢚parrows;懈ƀcit㢰㣄㣈ɯ㢶\0\0㣁rnĀ;e㢼㢽挝r»㢽op;挎ng;䅯ri;旹cr;쀀𝓊ƀdir㣙㣝㣢ot;拰lde;䅩iĀ;f㜰㣨»᠓Āam㣯㣲rò㢨l耻ü䃼angle;榧ހABDacdeflnoprsz㤜㤟㤩㤭㦵㦸㦽㧟㧤㧨㧳㧹㧽㨁㨠ròϷarĀ;v㤦㤧櫨;櫩asèϡĀnr㤲㤷grt;榜΀eknprst㓣㥆㥋㥒㥝㥤㦖appá␕othinçẖƀhir㓫⻈㥙opô⾵Ā;hᎷ㥢ïㆍĀiu㥩㥭gmá㎳Ābp㥲㦄setneqĀ;q㥽㦀쀀⊊︀;쀀⫋︀setneqĀ;q㦏㦒쀀⊋︀;쀀⫌︀Āhr㦛㦟etá㚜iangleĀlr㦪㦯eft»थight»ၑy;䐲ash»ံƀelr㧄㧒㧗ƀ;beⷪ㧋㧏ar;抻q;扚lip;拮Ābt㧜ᑨaòᑩr;쀀𝔳tré㦮suĀbp㧯㧱»ജ»൙pf;쀀𝕧roð໻tré㦴Ācu㨆㨋r;쀀𝓋Ābp㨐㨘nĀEe㦀㨖»㥾nĀEe㦒㨞»㦐igzag;榚΀cefoprs㨶㨻㩖㩛㩔㩡㩪irc;䅵Ādi㩀㩑Ābg㩅㩉ar;機eĀ;qᗺ㩏;扙erp;愘r;쀀𝔴pf;쀀𝕨Ā;eᑹ㩦atèᑹcr;쀀𝓌ૣណ㪇\0㪋\0㪐㪛\0\0㪝㪨㪫㪯\0\0㫃㫎\0㫘ៜ៟tré៑r;쀀𝔵ĀAa㪔㪗ròσrò৶;䎾ĀAa㪡㪤ròθrò৫að✓is;拻ƀdptឤ㪵㪾Āfl㪺ឩ;쀀𝕩imåឲĀAa㫇㫊ròώròਁĀcq㫒ីr;쀀𝓍Āpt៖㫜ré។Ѐacefiosu㫰㫽㬈㬌㬑㬕㬛㬡cĀuy㫶㫻te耻ý䃽;䑏Āiy㬂㬆rc;䅷;䑋n耻¥䂥r;쀀𝔶cy;䑗pf;쀀𝕪cr;쀀𝓎Ācm㬦㬩y;䑎l耻ÿ䃿Ԁacdefhiosw㭂㭈㭔㭘㭤㭩㭭㭴㭺㮀cute;䅺Āay㭍㭒ron;䅾;䐷ot;䅼Āet㭝㭡træᕟa;䎶r;쀀𝔷cy;䐶grarr;懝pf;쀀𝕫cr;쀀𝓏Ājn㮅㮇;怍j;怌'.split("").map((e) => e.charCodeAt(0))
), un = new Uint16Array(
  // prettier-ignore
  "Ȁaglq	\x1Bɭ\0\0p;䀦os;䀧t;䀾t;䀼uot;䀢".split("").map((e) => e.charCodeAt(0))
);
var Bu;
const tn = /* @__PURE__ */ new Map([
  [0, 65533],
  // C1 Unicode control character reference replacements
  [128, 8364],
  [130, 8218],
  [131, 402],
  [132, 8222],
  [133, 8230],
  [134, 8224],
  [135, 8225],
  [136, 710],
  [137, 8240],
  [138, 352],
  [139, 8249],
  [140, 338],
  [142, 381],
  [145, 8216],
  [146, 8217],
  [147, 8220],
  [148, 8221],
  [149, 8226],
  [150, 8211],
  [151, 8212],
  [152, 732],
  [153, 8482],
  [154, 353],
  [155, 8250],
  [156, 339],
  [158, 382],
  [159, 376]
]), rn = (
  // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition, node/no-unsupported-features/es-builtins
  (Bu = String.fromCodePoint) !== null && Bu !== void 0 ? Bu : function(e) {
    let u = "";
    return e > 65535 && (e -= 65536, u += String.fromCharCode(e >>> 10 & 1023 | 55296), e = 56320 | e & 1023), u += String.fromCharCode(e), u;
  }
);
function nn(e) {
  var u;
  return e >= 55296 && e <= 57343 || e > 1114111 ? 65533 : (u = tn.get(e)) !== null && u !== void 0 ? u : e;
}
var Z;
(function(e) {
  e[e.NUM = 35] = "NUM", e[e.SEMI = 59] = "SEMI", e[e.EQUALS = 61] = "EQUALS", e[e.ZERO = 48] = "ZERO", e[e.NINE = 57] = "NINE", e[e.LOWER_A = 97] = "LOWER_A", e[e.LOWER_F = 102] = "LOWER_F", e[e.LOWER_X = 120] = "LOWER_X", e[e.LOWER_Z = 122] = "LOWER_Z", e[e.UPPER_A = 65] = "UPPER_A", e[e.UPPER_F = 70] = "UPPER_F", e[e.UPPER_Z = 90] = "UPPER_Z";
})(Z || (Z = {}));
const an = 32;
var Ee;
(function(e) {
  e[e.VALUE_LENGTH = 49152] = "VALUE_LENGTH", e[e.BRANCH_LENGTH = 16256] = "BRANCH_LENGTH", e[e.JUMP_TABLE = 127] = "JUMP_TABLE";
})(Ee || (Ee = {}));
function xt(e) {
  return e >= Z.ZERO && e <= Z.NINE;
}
function sn(e) {
  return e >= Z.UPPER_A && e <= Z.UPPER_F || e >= Z.LOWER_A && e <= Z.LOWER_F;
}
function cn(e) {
  return e >= Z.UPPER_A && e <= Z.UPPER_Z || e >= Z.LOWER_A && e <= Z.LOWER_Z || xt(e);
}
function on(e) {
  return e === Z.EQUALS || cn(e);
}
var J;
(function(e) {
  e[e.EntityStart = 0] = "EntityStart", e[e.NumericStart = 1] = "NumericStart", e[e.NumericDecimal = 2] = "NumericDecimal", e[e.NumericHex = 3] = "NumericHex", e[e.NamedEntity = 4] = "NamedEntity";
})(J || (J = {}));
var ve;
(function(e) {
  e[e.Legacy = 0] = "Legacy", e[e.Strict = 1] = "Strict", e[e.Attribute = 2] = "Attribute";
})(ve || (ve = {}));
class ln {
  constructor(u, t, c) {
    this.decodeTree = u, this.emitCodePoint = t, this.errors = c, this.state = J.EntityStart, this.consumed = 1, this.result = 0, this.treeIndex = 0, this.excess = 1, this.decodeMode = ve.Strict;
  }
  /** Resets the instance to make it reusable. */
  startEntity(u) {
    this.decodeMode = u, this.state = J.EntityStart, this.result = 0, this.treeIndex = 0, this.excess = 1, this.consumed = 1;
  }
  /**
   * Write an entity to the decoder. This can be called multiple times with partial entities.
   * If the entity is incomplete, the decoder will return -1.
   *
   * Mirrors the implementation of `getDecoder`, but with the ability to stop decoding if the
   * entity is incomplete, and resume when the next string is written.
   *
   * @param string The string containing the entity (or a continuation of the entity).
   * @param offset The offset at which the entity begins. Should be 0 if this is not the first call.
   * @returns The number of characters that were consumed, or -1 if the entity is incomplete.
   */
  write(u, t) {
    switch (this.state) {
      case J.EntityStart:
        return u.charCodeAt(t) === Z.NUM ? (this.state = J.NumericStart, this.consumed += 1, this.stateNumericStart(u, t + 1)) : (this.state = J.NamedEntity, this.stateNamedEntity(u, t));
      case J.NumericStart:
        return this.stateNumericStart(u, t);
      case J.NumericDecimal:
        return this.stateNumericDecimal(u, t);
      case J.NumericHex:
        return this.stateNumericHex(u, t);
      case J.NamedEntity:
        return this.stateNamedEntity(u, t);
    }
  }
  /**
   * Switches between the numeric decimal and hexadecimal states.
   *
   * Equivalent to the `Numeric character reference state` in the HTML spec.
   *
   * @param str The string containing the entity (or a continuation of the entity).
   * @param offset The current offset.
   * @returns The number of characters that were consumed, or -1 if the entity is incomplete.
   */
  stateNumericStart(u, t) {
    return t >= u.length ? -1 : (u.charCodeAt(t) | an) === Z.LOWER_X ? (this.state = J.NumericHex, this.consumed += 1, this.stateNumericHex(u, t + 1)) : (this.state = J.NumericDecimal, this.stateNumericDecimal(u, t));
  }
  addToNumericResult(u, t, c, s) {
    if (t !== c) {
      const i = c - t;
      this.result = this.result * Math.pow(s, i) + parseInt(u.substr(t, i), s), this.consumed += i;
    }
  }
  /**
   * Parses a hexadecimal numeric entity.
   *
   * Equivalent to the `Hexademical character reference state` in the HTML spec.
   *
   * @param str The string containing the entity (or a continuation of the entity).
   * @param offset The current offset.
   * @returns The number of characters that were consumed, or -1 if the entity is incomplete.
   */
  stateNumericHex(u, t) {
    const c = t;
    for (; t < u.length; ) {
      const s = u.charCodeAt(t);
      if (xt(s) || sn(s))
        t += 1;
      else
        return this.addToNumericResult(u, c, t, 16), this.emitNumericEntity(s, 3);
    }
    return this.addToNumericResult(u, c, t, 16), -1;
  }
  /**
   * Parses a decimal numeric entity.
   *
   * Equivalent to the `Decimal character reference state` in the HTML spec.
   *
   * @param str The string containing the entity (or a continuation of the entity).
   * @param offset The current offset.
   * @returns The number of characters that were consumed, or -1 if the entity is incomplete.
   */
  stateNumericDecimal(u, t) {
    const c = t;
    for (; t < u.length; ) {
      const s = u.charCodeAt(t);
      if (xt(s))
        t += 1;
      else
        return this.addToNumericResult(u, c, t, 10), this.emitNumericEntity(s, 2);
    }
    return this.addToNumericResult(u, c, t, 10), -1;
  }
  /**
   * Validate and emit a numeric entity.
   *
   * Implements the logic from the `Hexademical character reference start
   * state` and `Numeric character reference end state` in the HTML spec.
   *
   * @param lastCp The last code point of the entity. Used to see if the
   *               entity was terminated with a semicolon.
   * @param expectedLength The minimum number of characters that should be
   *                       consumed. Used to validate that at least one digit
   *                       was consumed.
   * @returns The number of characters that were consumed.
   */
  emitNumericEntity(u, t) {
    var c;
    if (this.consumed <= t)
      return (c = this.errors) === null || c === void 0 || c.absenceOfDigitsInNumericCharacterReference(this.consumed), 0;
    if (u === Z.SEMI)
      this.consumed += 1;
    else if (this.decodeMode === ve.Strict)
      return 0;
    return this.emitCodePoint(nn(this.result), this.consumed), this.errors && (u !== Z.SEMI && this.errors.missingSemicolonAfterCharacterReference(), this.errors.validateNumericCharacterReference(this.result)), this.consumed;
  }
  /**
   * Parses a named entity.
   *
   * Equivalent to the `Named character reference state` in the HTML spec.
   *
   * @param str The string containing the entity (or a continuation of the entity).
   * @param offset The current offset.
   * @returns The number of characters that were consumed, or -1 if the entity is incomplete.
   */
  stateNamedEntity(u, t) {
    const { decodeTree: c } = this;
    let s = c[this.treeIndex], i = (s & Ee.VALUE_LENGTH) >> 14;
    for (; t < u.length; t++, this.excess++) {
      const l = u.charCodeAt(t);
      if (this.treeIndex = fn(c, s, this.treeIndex + Math.max(1, i), l), this.treeIndex < 0)
        return this.result === 0 || // If we are parsing an attribute
        this.decodeMode === ve.Attribute && // We shouldn't have consumed any characters after the entity,
        (i === 0 || // And there should be no invalid characters.
        on(l)) ? 0 : this.emitNotTerminatedNamedEntity();
      if (s = c[this.treeIndex], i = (s & Ee.VALUE_LENGTH) >> 14, i !== 0) {
        if (l === Z.SEMI)
          return this.emitNamedEntityData(this.treeIndex, i, this.consumed + this.excess);
        this.decodeMode !== ve.Strict && (this.result = this.treeIndex, this.consumed += this.excess, this.excess = 0);
      }
    }
    return -1;
  }
  /**
   * Emit a named entity that was not terminated with a semicolon.
   *
   * @returns The number of characters consumed.
   */
  emitNotTerminatedNamedEntity() {
    var u;
    const { result: t, decodeTree: c } = this, s = (c[t] & Ee.VALUE_LENGTH) >> 14;
    return this.emitNamedEntityData(t, s, this.consumed), (u = this.errors) === null || u === void 0 || u.missingSemicolonAfterCharacterReference(), this.consumed;
  }
  /**
   * Emit a named entity.
   *
   * @param result The index of the entity in the decode tree.
   * @param valueLength The number of bytes in the entity.
   * @param consumed The number of characters consumed.
   *
   * @returns The number of characters consumed.
   */
  emitNamedEntityData(u, t, c) {
    const { decodeTree: s } = this;
    return this.emitCodePoint(t === 1 ? s[u] & ~Ee.VALUE_LENGTH : s[u + 1], c), t === 3 && this.emitCodePoint(s[u + 2], c), c;
  }
  /**
   * Signal to the parser that the end of the input was reached.
   *
   * Remaining data will be emitted and relevant errors will be produced.
   *
   * @returns The number of characters consumed.
   */
  end() {
    var u;
    switch (this.state) {
      case J.NamedEntity:
        return this.result !== 0 && (this.decodeMode !== ve.Attribute || this.result === this.treeIndex) ? this.emitNotTerminatedNamedEntity() : 0;
      // Otherwise, emit a numeric entity if we have one.
      case J.NumericDecimal:
        return this.emitNumericEntity(0, 2);
      case J.NumericHex:
        return this.emitNumericEntity(0, 3);
      case J.NumericStart:
        return (u = this.errors) === null || u === void 0 || u.absenceOfDigitsInNumericCharacterReference(this.consumed), 0;
      case J.EntityStart:
        return 0;
    }
  }
}
function Tr(e) {
  let u = "";
  const t = new ln(e, (c) => u += rn(c));
  return function(s, i) {
    let l = 0, a = 0;
    for (; (a = s.indexOf("&", a)) >= 0; ) {
      u += s.slice(l, a), t.startEntity(i);
      const r = t.write(
        s,
        // Skip the "&"
        a + 1
      );
      if (r < 0) {
        l = a + t.end();
        break;
      }
      l = a + r, a = r === 0 ? l + 1 : l;
    }
    const o = u + s.slice(l);
    return u = "", o;
  };
}
function fn(e, u, t, c) {
  const s = (u & Ee.BRANCH_LENGTH) >> 7, i = u & Ee.JUMP_TABLE;
  if (s === 0)
    return i !== 0 && c === i ? t : -1;
  if (i) {
    const o = c - i;
    return o < 0 || o >= s ? -1 : e[t + o] - 1;
  }
  let l = t, a = l + s - 1;
  for (; l <= a; ) {
    const o = l + a >>> 1, r = e[o];
    if (r < c)
      l = o + 1;
    else if (r > c)
      a = o - 1;
    else
      return e[o + s];
  }
  return -1;
}
const dn = Tr(en);
Tr(un);
function Nr(e, u = ve.Legacy) {
  return dn(e, u);
}
function An(e) {
  return Object.prototype.toString.call(e);
}
function It(e) {
  return An(e) === "[object String]";
}
const hn = Object.prototype.hasOwnProperty;
function bn(e, u) {
  return hn.call(e, u);
}
function pu(e) {
  return Array.prototype.slice.call(arguments, 1).forEach(function(t) {
    if (t) {
      if (typeof t != "object")
        throw new TypeError(t + "must be object");
      Object.keys(t).forEach(function(c) {
        e[c] = t[c];
      });
    }
  }), e;
}
function Or(e, u, t) {
  return [].concat(e.slice(0, u), t, e.slice(u + 1));
}
function _t(e) {
  return !(e >= 55296 && e <= 57343 || e >= 64976 && e <= 65007 || (e & 65535) === 65535 || (e & 65535) === 65534 || e >= 0 && e <= 8 || e === 11 || e >= 14 && e <= 31 || e >= 127 && e <= 159 || e > 1114111);
}
function hu(e) {
  if (e > 65535) {
    e -= 65536;
    const u = 55296 + (e >> 10), t = 56320 + (e & 1023);
    return String.fromCharCode(u, t);
  }
  return String.fromCharCode(e);
}
const Mr = /\\([!"#$%&'()*+,\-./:;<=>?@[\\\]^_`{|}~])/g, pn = /&([a-z#][a-z0-9]{1,31});/gi, gn = new RegExp(Mr.source + "|" + pn.source, "gi"), mn = /^#((?:x[a-f0-9]{1,8}|[0-9]{1,8}))$/i;
function xn(e, u) {
  if (u.charCodeAt(0) === 35 && mn.test(u)) {
    const c = u[1].toLowerCase() === "x" ? parseInt(u.slice(2), 16) : parseInt(u.slice(1), 10);
    return _t(c) ? hu(c) : e;
  }
  const t = Nr(e);
  return t !== e ? t : e;
}
function yn(e) {
  return e.indexOf("\\") < 0 ? e : e.replace(Mr, "$1");
}
function Le(e) {
  return e.indexOf("\\") < 0 && e.indexOf("&") < 0 ? e : e.replace(gn, function(u, t, c) {
    return t || xn(u, c);
  });
}
const wn = /[&<>"]/, Cn = /[&<>"]/g, vn = {
  "&": "&amp;",
  "<": "&lt;",
  ">": "&gt;",
  '"': "&quot;"
};
function En(e) {
  return vn[e];
}
function De(e) {
  return wn.test(e) ? e.replace(Cn, En) : e;
}
const Dn = /[.?*+^$[\]\\(){}|-]/g;
function In(e) {
  return e.replace(Dn, "\\$&");
}
function Y(e) {
  switch (e) {
    case 9:
    case 32:
      return !0;
  }
  return !1;
}
function Ke(e) {
  if (e >= 8192 && e <= 8202)
    return !0;
  switch (e) {
    case 9:
    // \t
    case 10:
    // \n
    case 11:
    // \v
    case 12:
    // \f
    case 13:
    // \r
    case 32:
    case 160:
    case 5760:
    case 8239:
    case 8287:
    case 12288:
      return !0;
  }
  return !1;
}
function Ye(e) {
  return Dt.test(e) || Sr.test(e);
}
function je(e) {
  switch (e) {
    case 33:
    case 34:
    case 35:
    case 36:
    case 37:
    case 38:
    case 39:
    case 40:
    case 41:
    case 42:
    case 43:
    case 44:
    case 45:
    case 46:
    case 47:
    case 58:
    case 59:
    case 60:
    case 61:
    case 62:
    case 63:
    case 64:
    case 91:
    case 92:
    case 93:
    case 94:
    case 95:
    case 96:
    case 123:
    case 124:
    case 125:
    case 126:
      return !0;
    default:
      return !1;
  }
}
function gu(e) {
  return e = e.trim().replace(/\s+/g, " "), "ẞ".toLowerCase() === "Ṿ" && (e = e.replace(/ẞ/g, "ß")), e.toLowerCase().toUpperCase();
}
const _n = { mdurl: zi, ucmicro: $i }, kn = /* @__PURE__ */ Object.freeze(/* @__PURE__ */ Object.defineProperty({
  __proto__: null,
  arrayReplaceAt: Or,
  assign: pu,
  escapeHtml: De,
  escapeRE: In,
  fromCodePoint: hu,
  has: bn,
  isMdAsciiPunct: je,
  isPunctChar: Ye,
  isSpace: Y,
  isString: It,
  isValidEntityCode: _t,
  isWhiteSpace: Ke,
  lib: _n,
  normalizeReference: gu,
  unescapeAll: Le,
  unescapeMd: yn
}, Symbol.toStringTag, { value: "Module" }));
function Bn(e, u, t) {
  let c, s, i, l;
  const a = e.posMax, o = e.pos;
  for (e.pos = u + 1, c = 1; e.pos < a; ) {
    if (i = e.src.charCodeAt(e.pos), i === 93 && (c--, c === 0)) {
      s = !0;
      break;
    }
    if (l = e.pos, e.md.inline.skipToken(e), i === 91) {
      if (l === e.pos - 1)
        c++;
      else if (t)
        return e.pos = o, -1;
    }
  }
  let r = -1;
  return s && (r = e.pos), e.pos = o, r;
}
function Fn(e, u, t) {
  let c, s = u;
  const i = {
    ok: !1,
    pos: 0,
    str: ""
  };
  if (e.charCodeAt(s) === 60) {
    for (s++; s < t; ) {
      if (c = e.charCodeAt(s), c === 10 || c === 60)
        return i;
      if (c === 62)
        return i.pos = s + 1, i.str = Le(e.slice(u + 1, s)), i.ok = !0, i;
      if (c === 92 && s + 1 < t) {
        s += 2;
        continue;
      }
      s++;
    }
    return i;
  }
  let l = 0;
  for (; s < t && (c = e.charCodeAt(s), !(c === 32 || c < 32 || c === 127)); ) {
    if (c === 92 && s + 1 < t) {
      if (e.charCodeAt(s + 1) === 32)
        break;
      s += 2;
      continue;
    }
    if (c === 40 && (l++, l > 32))
      return i;
    if (c === 41) {
      if (l === 0)
        break;
      l--;
    }
    s++;
  }
  return u === s || l !== 0 || (i.str = Le(e.slice(u, s)), i.pos = s, i.ok = !0), i;
}
function Sn(e, u, t, c) {
  let s, i = u;
  const l = {
    // if `true`, this is a valid link title
    ok: !1,
    // if `true`, this link can be continued on the next line
    can_continue: !1,
    // if `ok`, it's the position of the first character after the closing marker
    pos: 0,
    // if `ok`, it's the unescaped title
    str: "",
    // expected closing marker character code
    marker: 0
  };
  if (c)
    l.str = c.str, l.marker = c.marker;
  else {
    if (i >= t)
      return l;
    let a = e.charCodeAt(i);
    if (a !== 34 && a !== 39 && a !== 40)
      return l;
    u++, i++, a === 40 && (a = 41), l.marker = a;
  }
  for (; i < t; ) {
    if (s = e.charCodeAt(i), s === l.marker)
      return l.pos = i + 1, l.str += Le(e.slice(u, i)), l.ok = !0, l;
    if (s === 40 && l.marker === 41)
      return l;
    s === 92 && i + 1 < t && i++, i++;
  }
  return l.can_continue = !0, l.str += Le(e.slice(u, i)), l;
}
const Rn = /* @__PURE__ */ Object.freeze(/* @__PURE__ */ Object.defineProperty({
  __proto__: null,
  parseLinkDestination: Fn,
  parseLinkLabel: Bn,
  parseLinkTitle: Sn
}, Symbol.toStringTag, { value: "Module" })), he = {};
he.code_inline = function(e, u, t, c, s) {
  const i = e[u];
  return "<code" + s.renderAttrs(i) + ">" + De(i.content) + "</code>";
};
he.code_block = function(e, u, t, c, s) {
  const i = e[u];
  return "<pre" + s.renderAttrs(i) + "><code>" + De(e[u].content) + `</code></pre>
`;
};
he.fence = function(e, u, t, c, s) {
  const i = e[u], l = i.info ? Le(i.info).trim() : "";
  let a = "", o = "";
  if (l) {
    const n = l.split(/(\s+)/g);
    a = n[0], o = n.slice(2).join("");
  }
  let r;
  if (t.highlight ? r = t.highlight(i.content, a, o) || De(i.content) : r = De(i.content), r.indexOf("<pre") === 0)
    return r + `
`;
  if (l) {
    const n = i.attrIndex("class"), f = i.attrs ? i.attrs.slice() : [];
    n < 0 ? f.push(["class", t.langPrefix + a]) : (f[n] = f[n].slice(), f[n][1] += " " + t.langPrefix + a);
    const d = {
      attrs: f
    };
    return `<pre><code${s.renderAttrs(d)}>${r}</code></pre>
`;
  }
  return `<pre><code${s.renderAttrs(i)}>${r}</code></pre>
`;
};
he.image = function(e, u, t, c, s) {
  const i = e[u];
  return i.attrs[i.attrIndex("alt")][1] = s.renderInlineAsText(i.children, t, c), s.renderToken(e, u, t);
};
he.hardbreak = function(e, u, t) {
  return t.xhtmlOut ? `<br />
` : `<br>
`;
};
he.softbreak = function(e, u, t) {
  return t.breaks ? t.xhtmlOut ? `<br />
` : `<br>
` : `
`;
};
he.text = function(e, u) {
  return De(e[u].content);
};
he.html_block = function(e, u) {
  return e[u].content;
};
he.html_inline = function(e, u) {
  return e[u].content;
};
function Pe() {
  this.rules = pu({}, he);
}
Pe.prototype.renderAttrs = function(u) {
  let t, c, s;
  if (!u.attrs)
    return "";
  for (s = "", t = 0, c = u.attrs.length; t < c; t++)
    s += " " + De(u.attrs[t][0]) + '="' + De(u.attrs[t][1]) + '"';
  return s;
};
Pe.prototype.renderToken = function(u, t, c) {
  const s = u[t];
  let i = "";
  if (s.hidden)
    return "";
  s.block && s.nesting !== -1 && t && u[t - 1].hidden && (i += `
`), i += (s.nesting === -1 ? "</" : "<") + s.tag, i += this.renderAttrs(s), s.nesting === 0 && c.xhtmlOut && (i += " /");
  let l = !1;
  if (s.block && (l = !0, s.nesting === 1 && t + 1 < u.length)) {
    const a = u[t + 1];
    (a.type === "inline" || a.hidden || a.nesting === -1 && a.tag === s.tag) && (l = !1);
  }
  return i += l ? `>
` : ">", i;
};
Pe.prototype.renderInline = function(e, u, t) {
  let c = "";
  const s = this.rules;
  for (let i = 0, l = e.length; i < l; i++) {
    const a = e[i].type;
    typeof s[a] < "u" ? c += s[a](e, i, u, t, this) : c += this.renderToken(e, i, u);
  }
  return c;
};
Pe.prototype.renderInlineAsText = function(e, u, t) {
  let c = "";
  for (let s = 0, i = e.length; s < i; s++)
    switch (e[s].type) {
      case "text":
        c += e[s].content;
        break;
      case "image":
        c += this.renderInlineAsText(e[s].children, u, t);
        break;
      case "html_inline":
      case "html_block":
        c += e[s].content;
        break;
      case "softbreak":
      case "hardbreak":
        c += `
`;
        break;
    }
  return c;
};
Pe.prototype.render = function(e, u, t) {
  let c = "";
  const s = this.rules;
  for (let i = 0, l = e.length; i < l; i++) {
    const a = e[i].type;
    a === "inline" ? c += this.renderInline(e[i].children, u, t) : typeof s[a] < "u" ? c += s[a](e, i, u, t, this) : c += this.renderToken(e, i, u, t);
  }
  return c;
};
function $() {
  this.__rules__ = [], this.__cache__ = null;
}
$.prototype.__find__ = function(e) {
  for (let u = 0; u < this.__rules__.length; u++)
    if (this.__rules__[u].name === e)
      return u;
  return -1;
};
$.prototype.__compile__ = function() {
  const e = this, u = [""];
  e.__rules__.forEach(function(t) {
    t.enabled && t.alt.forEach(function(c) {
      u.indexOf(c) < 0 && u.push(c);
    });
  }), e.__cache__ = {}, u.forEach(function(t) {
    e.__cache__[t] = [], e.__rules__.forEach(function(c) {
      c.enabled && (t && c.alt.indexOf(t) < 0 || e.__cache__[t].push(c.fn));
    });
  });
};
$.prototype.at = function(e, u, t) {
  const c = this.__find__(e), s = t || {};
  if (c === -1)
    throw new Error("Parser rule not found: " + e);
  this.__rules__[c].fn = u, this.__rules__[c].alt = s.alt || [], this.__cache__ = null;
};
$.prototype.before = function(e, u, t, c) {
  const s = this.__find__(e), i = c || {};
  if (s === -1)
    throw new Error("Parser rule not found: " + e);
  this.__rules__.splice(s, 0, {
    name: u,
    enabled: !0,
    fn: t,
    alt: i.alt || []
  }), this.__cache__ = null;
};
$.prototype.after = function(e, u, t, c) {
  const s = this.__find__(e), i = c || {};
  if (s === -1)
    throw new Error("Parser rule not found: " + e);
  this.__rules__.splice(s + 1, 0, {
    name: u,
    enabled: !0,
    fn: t,
    alt: i.alt || []
  }), this.__cache__ = null;
};
$.prototype.push = function(e, u, t) {
  const c = t || {};
  this.__rules__.push({
    name: e,
    enabled: !0,
    fn: u,
    alt: c.alt || []
  }), this.__cache__ = null;
};
$.prototype.enable = function(e, u) {
  Array.isArray(e) || (e = [e]);
  const t = [];
  return e.forEach(function(c) {
    const s = this.__find__(c);
    if (s < 0) {
      if (u)
        return;
      throw new Error("Rules manager: invalid rule name " + c);
    }
    this.__rules__[s].enabled = !0, t.push(c);
  }, this), this.__cache__ = null, t;
};
$.prototype.enableOnly = function(e, u) {
  Array.isArray(e) || (e = [e]), this.__rules__.forEach(function(t) {
    t.enabled = !1;
  }), this.enable(e, u);
};
$.prototype.disable = function(e, u) {
  Array.isArray(e) || (e = [e]);
  const t = [];
  return e.forEach(function(c) {
    const s = this.__find__(c);
    if (s < 0) {
      if (u)
        return;
      throw new Error("Rules manager: invalid rule name " + c);
    }
    this.__rules__[s].enabled = !1, t.push(c);
  }, this), this.__cache__ = null, t;
};
$.prototype.getRules = function(e) {
  return this.__cache__ === null && this.__compile__(), this.__cache__[e] || [];
};
function le(e, u, t) {
  this.type = e, this.tag = u, this.attrs = null, this.map = null, this.nesting = t, this.level = 0, this.children = null, this.content = "", this.markup = "", this.info = "", this.meta = null, this.block = !1, this.hidden = !1;
}
le.prototype.attrIndex = function(u) {
  if (!this.attrs)
    return -1;
  const t = this.attrs;
  for (let c = 0, s = t.length; c < s; c++)
    if (t[c][0] === u)
      return c;
  return -1;
};
le.prototype.attrPush = function(u) {
  this.attrs ? this.attrs.push(u) : this.attrs = [u];
};
le.prototype.attrSet = function(u, t) {
  const c = this.attrIndex(u), s = [u, t];
  c < 0 ? this.attrPush(s) : this.attrs[c] = s;
};
le.prototype.attrGet = function(u) {
  const t = this.attrIndex(u);
  let c = null;
  return t >= 0 && (c = this.attrs[t][1]), c;
};
le.prototype.attrJoin = function(u, t) {
  const c = this.attrIndex(u);
  c < 0 ? this.attrPush([u, t]) : this.attrs[c][1] = this.attrs[c][1] + " " + t;
};
function Qr(e, u, t) {
  this.src = e, this.env = t, this.tokens = [], this.inlineMode = !1, this.md = u;
}
Qr.prototype.Token = le;
const Tn = /\r\n?|\n/g, Nn = /\0/g;
function On(e) {
  let u;
  u = e.src.replace(Tn, `
`), u = u.replace(Nn, "�"), e.src = u;
}
function Mn(e) {
  let u;
  e.inlineMode ? (u = new e.Token("inline", "", 0), u.content = e.src, u.map = [0, 1], u.children = [], e.tokens.push(u)) : e.md.block.parse(e.src, e.md, e.env, e.tokens);
}
function Qn(e) {
  const u = e.tokens;
  for (let t = 0, c = u.length; t < c; t++) {
    const s = u[t];
    s.type === "inline" && e.md.inline.parse(s.content, e.md, e.env, s.children);
  }
}
function Ln(e) {
  return /^<a[>\s]/i.test(e);
}
function Pn(e) {
  return /^<\/a\s*>/i.test(e);
}
function Gn(e) {
  const u = e.tokens;
  if (e.md.options.linkify)
    for (let t = 0, c = u.length; t < c; t++) {
      if (u[t].type !== "inline" || !e.md.linkify.pretest(u[t].content))
        continue;
      let s = u[t].children, i = 0;
      for (let l = s.length - 1; l >= 0; l--) {
        const a = s[l];
        if (a.type === "link_close") {
          for (l--; s[l].level !== a.level && s[l].type !== "link_open"; )
            l--;
          continue;
        }
        if (a.type === "html_inline" && (Ln(a.content) && i > 0 && i--, Pn(a.content) && i++), !(i > 0) && a.type === "text" && e.md.linkify.test(a.content)) {
          const o = a.content;
          let r = e.md.linkify.match(o);
          const n = [];
          let f = a.level, d = 0;
          r.length > 0 && r[0].index === 0 && l > 0 && s[l - 1].type === "text_special" && (r = r.slice(1));
          for (let A = 0; A < r.length; A++) {
            const h = r[A].url, w = e.md.normalizeLink(h);
            if (!e.md.validateLink(w))
              continue;
            let C = r[A].text;
            r[A].schema ? r[A].schema === "mailto:" && !/^mailto:/i.test(C) ? C = e.md.normalizeLinkText("mailto:" + C).replace(/^mailto:/, "") : C = e.md.normalizeLinkText(C) : C = e.md.normalizeLinkText("http://" + C).replace(/^http:\/\//, "");
            const b = r[A].index;
            if (b > d) {
              const p = new e.Token("text", "", 0);
              p.content = o.slice(d, b), p.level = f, n.push(p);
            }
            const m = new e.Token("link_open", "a", 1);
            m.attrs = [["href", w]], m.level = f++, m.markup = "linkify", m.info = "auto", n.push(m);
            const g = new e.Token("text", "", 0);
            g.content = C, g.level = f, n.push(g);
            const x = new e.Token("link_close", "a", -1);
            x.level = --f, x.markup = "linkify", x.info = "auto", n.push(x), d = r[A].lastIndex;
          }
          if (d < o.length) {
            const A = new e.Token("text", "", 0);
            A.content = o.slice(d), A.level = f, n.push(A);
          }
          u[t].children = s = Or(s, l, n);
        }
      }
    }
}
const Lr = /\+-|\.\.|\?\?\?\?|!!!!|,,|--/, qn = /\((c|tm|r)\)/i, Hn = /\((c|tm|r)\)/ig, Wn = {
  c: "©",
  r: "®",
  tm: "™"
};
function Un(e, u) {
  return Wn[u.toLowerCase()];
}
function Kn(e) {
  let u = 0;
  for (let t = e.length - 1; t >= 0; t--) {
    const c = e[t];
    c.type === "text" && !u && (c.content = c.content.replace(Hn, Un)), c.type === "link_open" && c.info === "auto" && u--, c.type === "link_close" && c.info === "auto" && u++;
  }
}
function Yn(e) {
  let u = 0;
  for (let t = e.length - 1; t >= 0; t--) {
    const c = e[t];
    c.type === "text" && !u && Lr.test(c.content) && (c.content = c.content.replace(/\+-/g, "±").replace(/\.{2,}/g, "…").replace(/([?!])…/g, "$1..").replace(/([?!]){4,}/g, "$1$1$1").replace(/,{2,}/g, ",").replace(/(^|[^-])---(?=[^-]|$)/mg, "$1—").replace(/(^|\s)--(?=\s|$)/mg, "$1–").replace(/(^|[^-\s])--(?=[^-\s]|$)/mg, "$1–")), c.type === "link_open" && c.info === "auto" && u--, c.type === "link_close" && c.info === "auto" && u++;
  }
}
function jn(e) {
  let u;
  if (e.md.options.typographer)
    for (u = e.tokens.length - 1; u >= 0; u--)
      e.tokens[u].type === "inline" && (qn.test(e.tokens[u].content) && Kn(e.tokens[u].children), Lr.test(e.tokens[u].content) && Yn(e.tokens[u].children));
}
const Jn = /['"]/, Zt = /['"]/g, Vt = "’";
function tu(e, u, t) {
  return e.slice(0, u) + t + e.slice(u + 1);
}
function Zn(e, u) {
  let t;
  const c = [];
  for (let s = 0; s < e.length; s++) {
    const i = e[s], l = e[s].level;
    for (t = c.length - 1; t >= 0 && !(c[t].level <= l); t--)
      ;
    if (c.length = t + 1, i.type !== "text")
      continue;
    let a = i.content, o = 0, r = a.length;
    e:
      for (; o < r; ) {
        Zt.lastIndex = o;
        const n = Zt.exec(a);
        if (!n)
          break;
        let f = !0, d = !0;
        o = n.index + 1;
        const A = n[0] === "'";
        let h = 32;
        if (n.index - 1 >= 0)
          h = a.charCodeAt(n.index - 1);
        else
          for (t = s - 1; t >= 0 && !(e[t].type === "softbreak" || e[t].type === "hardbreak"); t--)
            if (e[t].content) {
              h = e[t].content.charCodeAt(e[t].content.length - 1);
              break;
            }
        let w = 32;
        if (o < r)
          w = a.charCodeAt(o);
        else
          for (t = s + 1; t < e.length && !(e[t].type === "softbreak" || e[t].type === "hardbreak"); t++)
            if (e[t].content) {
              w = e[t].content.charCodeAt(0);
              break;
            }
        const C = je(h) || Ye(String.fromCharCode(h)), b = je(w) || Ye(String.fromCharCode(w)), m = Ke(h), g = Ke(w);
        if (g ? f = !1 : b && (m || C || (f = !1)), m ? d = !1 : C && (g || b || (d = !1)), w === 34 && n[0] === '"' && h >= 48 && h <= 57 && (d = f = !1), f && d && (f = C, d = b), !f && !d) {
          A && (i.content = tu(i.content, n.index, Vt));
          continue;
        }
        if (d)
          for (t = c.length - 1; t >= 0; t--) {
            let x = c[t];
            if (c[t].level < l)
              break;
            if (x.single === A && c[t].level === l) {
              x = c[t];
              let p, y;
              A ? (p = u.md.options.quotes[2], y = u.md.options.quotes[3]) : (p = u.md.options.quotes[0], y = u.md.options.quotes[1]), i.content = tu(i.content, n.index, y), e[x.token].content = tu(
                e[x.token].content,
                x.pos,
                p
              ), o += y.length - 1, x.token === s && (o += p.length - 1), a = i.content, r = a.length, c.length = t;
              continue e;
            }
          }
        f ? c.push({
          token: s,
          pos: n.index,
          single: A,
          level: l
        }) : d && A && (i.content = tu(i.content, n.index, Vt));
      }
  }
}
function Vn(e) {
  if (e.md.options.typographer)
    for (let u = e.tokens.length - 1; u >= 0; u--)
      e.tokens[u].type !== "inline" || !Jn.test(e.tokens[u].content) || Zn(e.tokens[u].children, e);
}
function zn(e) {
  let u, t;
  const c = e.tokens, s = c.length;
  for (let i = 0; i < s; i++) {
    if (c[i].type !== "inline") continue;
    const l = c[i].children, a = l.length;
    for (u = 0; u < a; u++)
      l[u].type === "text_special" && (l[u].type = "text");
    for (u = t = 0; u < a; u++)
      l[u].type === "text" && u + 1 < a && l[u + 1].type === "text" ? l[u + 1].content = l[u].content + l[u + 1].content : (u !== t && (l[t] = l[u]), t++);
    u !== t && (l.length = t);
  }
}
const Fu = [
  ["normalize", On],
  ["block", Mn],
  ["inline", Qn],
  ["linkify", Gn],
  ["replacements", jn],
  ["smartquotes", Vn],
  // `text_join` finds `text_special` tokens (for escape sequences)
  // and joins them with the rest of the text
  ["text_join", zn]
];
function kt() {
  this.ruler = new $();
  for (let e = 0; e < Fu.length; e++)
    this.ruler.push(Fu[e][0], Fu[e][1]);
}
kt.prototype.process = function(e) {
  const u = this.ruler.getRules("");
  for (let t = 0, c = u.length; t < c; t++)
    u[t](e);
};
kt.prototype.State = Qr;
function be(e, u, t, c) {
  this.src = e, this.md = u, this.env = t, this.tokens = c, this.bMarks = [], this.eMarks = [], this.tShift = [], this.sCount = [], this.bsCount = [], this.blkIndent = 0, this.line = 0, this.lineMax = 0, this.tight = !1, this.ddIndent = -1, this.listIndent = -1, this.parentType = "root", this.level = 0;
  const s = this.src;
  for (let i = 0, l = 0, a = 0, o = 0, r = s.length, n = !1; l < r; l++) {
    const f = s.charCodeAt(l);
    if (!n)
      if (Y(f)) {
        a++, f === 9 ? o += 4 - o % 4 : o++;
        continue;
      } else
        n = !0;
    (f === 10 || l === r - 1) && (f !== 10 && l++, this.bMarks.push(i), this.eMarks.push(l), this.tShift.push(a), this.sCount.push(o), this.bsCount.push(0), n = !1, a = 0, o = 0, i = l + 1);
  }
  this.bMarks.push(s.length), this.eMarks.push(s.length), this.tShift.push(0), this.sCount.push(0), this.bsCount.push(0), this.lineMax = this.bMarks.length - 1;
}
be.prototype.push = function(e, u, t) {
  const c = new le(e, u, t);
  return c.block = !0, t < 0 && this.level--, c.level = this.level, t > 0 && this.level++, this.tokens.push(c), c;
};
be.prototype.isEmpty = function(u) {
  return this.bMarks[u] + this.tShift[u] >= this.eMarks[u];
};
be.prototype.skipEmptyLines = function(u) {
  for (let t = this.lineMax; u < t && !(this.bMarks[u] + this.tShift[u] < this.eMarks[u]); u++)
    ;
  return u;
};
be.prototype.skipSpaces = function(u) {
  for (let t = this.src.length; u < t; u++) {
    const c = this.src.charCodeAt(u);
    if (!Y(c))
      break;
  }
  return u;
};
be.prototype.skipSpacesBack = function(u, t) {
  if (u <= t)
    return u;
  for (; u > t; )
    if (!Y(this.src.charCodeAt(--u)))
      return u + 1;
  return u;
};
be.prototype.skipChars = function(u, t) {
  for (let c = this.src.length; u < c && this.src.charCodeAt(u) === t; u++)
    ;
  return u;
};
be.prototype.skipCharsBack = function(u, t, c) {
  if (u <= c)
    return u;
  for (; u > c; )
    if (t !== this.src.charCodeAt(--u))
      return u + 1;
  return u;
};
be.prototype.getLines = function(u, t, c, s) {
  if (u >= t)
    return "";
  const i = new Array(t - u);
  for (let l = 0, a = u; a < t; a++, l++) {
    let o = 0;
    const r = this.bMarks[a];
    let n = r, f;
    for (a + 1 < t || s ? f = this.eMarks[a] + 1 : f = this.eMarks[a]; n < f && o < c; ) {
      const d = this.src.charCodeAt(n);
      if (Y(d))
        d === 9 ? o += 4 - (o + this.bsCount[a]) % 4 : o++;
      else if (n - r < this.tShift[a])
        o++;
      else
        break;
      n++;
    }
    o > c ? i[l] = new Array(o - c + 1).join(" ") + this.src.slice(n, f) : i[l] = this.src.slice(n, f);
  }
  return i.join("");
};
be.prototype.Token = le;
const Xn = 65536;
function Su(e, u) {
  const t = e.bMarks[u] + e.tShift[u], c = e.eMarks[u];
  return e.src.slice(t, c);
}
function zt(e) {
  const u = [], t = e.length;
  let c = 0, s = e.charCodeAt(c), i = !1, l = 0, a = "";
  for (; c < t; )
    s === 124 && (i ? (a += e.substring(l, c - 1), l = c) : (u.push(a + e.substring(l, c)), a = "", l = c + 1)), i = s === 92, c++, s = e.charCodeAt(c);
  return u.push(a + e.substring(l)), u;
}
function $n(e, u, t, c) {
  if (u + 2 > t)
    return !1;
  let s = u + 1;
  if (e.sCount[s] < e.blkIndent || e.sCount[s] - e.blkIndent >= 4)
    return !1;
  let i = e.bMarks[s] + e.tShift[s];
  if (i >= e.eMarks[s])
    return !1;
  const l = e.src.charCodeAt(i++);
  if (l !== 124 && l !== 45 && l !== 58 || i >= e.eMarks[s])
    return !1;
  const a = e.src.charCodeAt(i++);
  if (a !== 124 && a !== 45 && a !== 58 && !Y(a) || l === 45 && Y(a))
    return !1;
  for (; i < e.eMarks[s]; ) {
    const x = e.src.charCodeAt(i);
    if (x !== 124 && x !== 45 && x !== 58 && !Y(x))
      return !1;
    i++;
  }
  let o = Su(e, u + 1), r = o.split("|");
  const n = [];
  for (let x = 0; x < r.length; x++) {
    const p = r[x].trim();
    if (!p) {
      if (x === 0 || x === r.length - 1)
        continue;
      return !1;
    }
    if (!/^:?-+:?$/.test(p))
      return !1;
    p.charCodeAt(p.length - 1) === 58 ? n.push(p.charCodeAt(0) === 58 ? "center" : "right") : p.charCodeAt(0) === 58 ? n.push("left") : n.push("");
  }
  if (o = Su(e, u).trim(), o.indexOf("|") === -1 || e.sCount[u] - e.blkIndent >= 4)
    return !1;
  r = zt(o), r.length && r[0] === "" && r.shift(), r.length && r[r.length - 1] === "" && r.pop();
  const f = r.length;
  if (f === 0 || f !== n.length)
    return !1;
  if (c)
    return !0;
  const d = e.parentType;
  e.parentType = "table";
  const A = e.md.block.ruler.getRules("blockquote"), h = e.push("table_open", "table", 1), w = [u, 0];
  h.map = w;
  const C = e.push("thead_open", "thead", 1);
  C.map = [u, u + 1];
  const b = e.push("tr_open", "tr", 1);
  b.map = [u, u + 1];
  for (let x = 0; x < r.length; x++) {
    const p = e.push("th_open", "th", 1);
    n[x] && (p.attrs = [["style", "text-align:" + n[x]]]);
    const y = e.push("inline", "", 0);
    y.content = r[x].trim(), y.children = [], e.push("th_close", "th", -1);
  }
  e.push("tr_close", "tr", -1), e.push("thead_close", "thead", -1);
  let m, g = 0;
  for (s = u + 2; s < t && !(e.sCount[s] < e.blkIndent); s++) {
    let x = !1;
    for (let y = 0, v = A.length; y < v; y++)
      if (A[y](e, s, t, !0)) {
        x = !0;
        break;
      }
    if (x || (o = Su(e, s).trim(), !o) || e.sCount[s] - e.blkIndent >= 4 || (r = zt(o), r.length && r[0] === "" && r.shift(), r.length && r[r.length - 1] === "" && r.pop(), g += f - r.length, g > Xn))
      break;
    if (s === u + 2) {
      const y = e.push("tbody_open", "tbody", 1);
      y.map = m = [u + 2, 0];
    }
    const p = e.push("tr_open", "tr", 1);
    p.map = [s, s + 1];
    for (let y = 0; y < f; y++) {
      const v = e.push("td_open", "td", 1);
      n[y] && (v.attrs = [["style", "text-align:" + n[y]]]);
      const I = e.push("inline", "", 0);
      I.content = r[y] ? r[y].trim() : "", I.children = [], e.push("td_close", "td", -1);
    }
    e.push("tr_close", "tr", -1);
  }
  return m && (e.push("tbody_close", "tbody", -1), m[1] = s), e.push("table_close", "table", -1), w[1] = s, e.parentType = d, e.line = s, !0;
}
function ea(e, u, t) {
  if (e.sCount[u] - e.blkIndent < 4)
    return !1;
  let c = u + 1, s = c;
  for (; c < t; ) {
    if (e.isEmpty(c)) {
      c++;
      continue;
    }
    if (e.sCount[c] - e.blkIndent >= 4) {
      c++, s = c;
      continue;
    }
    break;
  }
  e.line = s;
  const i = e.push("code_block", "code", 0);
  return i.content = e.getLines(u, s, 4 + e.blkIndent, !1) + `
`, i.map = [u, e.line], !0;
}
function ua(e, u, t, c) {
  let s = e.bMarks[u] + e.tShift[u], i = e.eMarks[u];
  if (e.sCount[u] - e.blkIndent >= 4 || s + 3 > i)
    return !1;
  const l = e.src.charCodeAt(s);
  if (l !== 126 && l !== 96)
    return !1;
  let a = s;
  s = e.skipChars(s, l);
  let o = s - a;
  if (o < 3)
    return !1;
  const r = e.src.slice(a, s), n = e.src.slice(s, i);
  if (l === 96 && n.indexOf(String.fromCharCode(l)) >= 0)
    return !1;
  if (c)
    return !0;
  let f = u, d = !1;
  for (; f++, !(f >= t || (s = a = e.bMarks[f] + e.tShift[f], i = e.eMarks[f], s < i && e.sCount[f] < e.blkIndent)); )
    if (e.src.charCodeAt(s) === l && !(e.sCount[f] - e.blkIndent >= 4) && (s = e.skipChars(s, l), !(s - a < o) && (s = e.skipSpaces(s), !(s < i)))) {
      d = !0;
      break;
    }
  o = e.sCount[u], e.line = f + (d ? 1 : 0);
  const A = e.push("fence", "code", 0);
  return A.info = n, A.content = e.getLines(u + 1, f, o, !0), A.markup = r, A.map = [u, e.line], !0;
}
function ta(e, u, t, c) {
  let s = e.bMarks[u] + e.tShift[u], i = e.eMarks[u];
  const l = e.lineMax;
  if (e.sCount[u] - e.blkIndent >= 4 || e.src.charCodeAt(s) !== 62)
    return !1;
  if (c)
    return !0;
  const a = [], o = [], r = [], n = [], f = e.md.block.ruler.getRules("blockquote"), d = e.parentType;
  e.parentType = "blockquote";
  let A = !1, h;
  for (h = u; h < t; h++) {
    const g = e.sCount[h] < e.blkIndent;
    if (s = e.bMarks[h] + e.tShift[h], i = e.eMarks[h], s >= i)
      break;
    if (e.src.charCodeAt(s++) === 62 && !g) {
      let p = e.sCount[h] + 1, y, v;
      e.src.charCodeAt(s) === 32 ? (s++, p++, v = !1, y = !0) : e.src.charCodeAt(s) === 9 ? (y = !0, (e.bsCount[h] + p) % 4 === 3 ? (s++, p++, v = !1) : v = !0) : y = !1;
      let I = p;
      for (a.push(e.bMarks[h]), e.bMarks[h] = s; s < i; ) {
        const D = e.src.charCodeAt(s);
        if (Y(D))
          D === 9 ? I += 4 - (I + e.bsCount[h] + (v ? 1 : 0)) % 4 : I++;
        else
          break;
        s++;
      }
      A = s >= i, o.push(e.bsCount[h]), e.bsCount[h] = e.sCount[h] + 1 + (y ? 1 : 0), r.push(e.sCount[h]), e.sCount[h] = I - p, n.push(e.tShift[h]), e.tShift[h] = s - e.bMarks[h];
      continue;
    }
    if (A)
      break;
    let x = !1;
    for (let p = 0, y = f.length; p < y; p++)
      if (f[p](e, h, t, !0)) {
        x = !0;
        break;
      }
    if (x) {
      e.lineMax = h, e.blkIndent !== 0 && (a.push(e.bMarks[h]), o.push(e.bsCount[h]), n.push(e.tShift[h]), r.push(e.sCount[h]), e.sCount[h] -= e.blkIndent);
      break;
    }
    a.push(e.bMarks[h]), o.push(e.bsCount[h]), n.push(e.tShift[h]), r.push(e.sCount[h]), e.sCount[h] = -1;
  }
  const w = e.blkIndent;
  e.blkIndent = 0;
  const C = e.push("blockquote_open", "blockquote", 1);
  C.markup = ">";
  const b = [u, 0];
  C.map = b, e.md.block.tokenize(e, u, h);
  const m = e.push("blockquote_close", "blockquote", -1);
  m.markup = ">", e.lineMax = l, e.parentType = d, b[1] = e.line;
  for (let g = 0; g < n.length; g++)
    e.bMarks[g + u] = a[g], e.tShift[g + u] = n[g], e.sCount[g + u] = r[g], e.bsCount[g + u] = o[g];
  return e.blkIndent = w, !0;
}
function ra(e, u, t, c) {
  const s = e.eMarks[u];
  if (e.sCount[u] - e.blkIndent >= 4)
    return !1;
  let i = e.bMarks[u] + e.tShift[u];
  const l = e.src.charCodeAt(i++);
  if (l !== 42 && l !== 45 && l !== 95)
    return !1;
  let a = 1;
  for (; i < s; ) {
    const r = e.src.charCodeAt(i++);
    if (r !== l && !Y(r))
      return !1;
    r === l && a++;
  }
  if (a < 3)
    return !1;
  if (c)
    return !0;
  e.line = u + 1;
  const o = e.push("hr", "hr", 0);
  return o.map = [u, e.line], o.markup = Array(a + 1).join(String.fromCharCode(l)), !0;
}
function Xt(e, u) {
  const t = e.eMarks[u];
  let c = e.bMarks[u] + e.tShift[u];
  const s = e.src.charCodeAt(c++);
  if (s !== 42 && s !== 45 && s !== 43)
    return -1;
  if (c < t) {
    const i = e.src.charCodeAt(c);
    if (!Y(i))
      return -1;
  }
  return c;
}
function $t(e, u) {
  const t = e.bMarks[u] + e.tShift[u], c = e.eMarks[u];
  let s = t;
  if (s + 1 >= c)
    return -1;
  let i = e.src.charCodeAt(s++);
  if (i < 48 || i > 57)
    return -1;
  for (; ; ) {
    if (s >= c)
      return -1;
    if (i = e.src.charCodeAt(s++), i >= 48 && i <= 57) {
      if (s - t >= 10)
        return -1;
      continue;
    }
    if (i === 41 || i === 46)
      break;
    return -1;
  }
  return s < c && (i = e.src.charCodeAt(s), !Y(i)) ? -1 : s;
}
function ia(e, u) {
  const t = e.level + 2;
  for (let c = u + 2, s = e.tokens.length - 2; c < s; c++)
    e.tokens[c].level === t && e.tokens[c].type === "paragraph_open" && (e.tokens[c + 2].hidden = !0, e.tokens[c].hidden = !0, c += 2);
}
function na(e, u, t, c) {
  let s, i, l, a, o = u, r = !0;
  if (e.sCount[o] - e.blkIndent >= 4 || e.listIndent >= 0 && e.sCount[o] - e.listIndent >= 4 && e.sCount[o] < e.blkIndent)
    return !1;
  let n = !1;
  c && e.parentType === "paragraph" && e.sCount[o] >= e.blkIndent && (n = !0);
  let f, d, A;
  if ((A = $t(e, o)) >= 0) {
    if (f = !0, l = e.bMarks[o] + e.tShift[o], d = Number(e.src.slice(l, A - 1)), n && d !== 1) return !1;
  } else if ((A = Xt(e, o)) >= 0)
    f = !1;
  else
    return !1;
  if (n && e.skipSpaces(A) >= e.eMarks[o])
    return !1;
  if (c)
    return !0;
  const h = e.src.charCodeAt(A - 1), w = e.tokens.length;
  f ? (a = e.push("ordered_list_open", "ol", 1), d !== 1 && (a.attrs = [["start", d]])) : a = e.push("bullet_list_open", "ul", 1);
  const C = [o, 0];
  a.map = C, a.markup = String.fromCharCode(h);
  let b = !1;
  const m = e.md.block.ruler.getRules("list"), g = e.parentType;
  for (e.parentType = "list"; o < t; ) {
    i = A, s = e.eMarks[o];
    const x = e.sCount[o] + A - (e.bMarks[o] + e.tShift[o]);
    let p = x;
    for (; i < s; ) {
      const B = e.src.charCodeAt(i);
      if (B === 9)
        p += 4 - (p + e.bsCount[o]) % 4;
      else if (B === 32)
        p++;
      else
        break;
      i++;
    }
    const y = i;
    let v;
    y >= s ? v = 1 : v = p - x, v > 4 && (v = 1);
    const I = x + v;
    a = e.push("list_item_open", "li", 1), a.markup = String.fromCharCode(h);
    const D = [o, 0];
    a.map = D, f && (a.info = e.src.slice(l, A - 1));
    const _ = e.tight, E = e.tShift[o], k = e.sCount[o], F = e.listIndent;
    if (e.listIndent = e.blkIndent, e.blkIndent = I, e.tight = !0, e.tShift[o] = y - e.bMarks[o], e.sCount[o] = p, y >= s && e.isEmpty(o + 1) ? e.line = Math.min(e.line + 2, t) : e.md.block.tokenize(e, o, t, !0), (!e.tight || b) && (r = !1), b = e.line - o > 1 && e.isEmpty(e.line - 1), e.blkIndent = e.listIndent, e.listIndent = F, e.tShift[o] = E, e.sCount[o] = k, e.tight = _, a = e.push("list_item_close", "li", -1), a.markup = String.fromCharCode(h), o = e.line, D[1] = o, o >= t || e.sCount[o] < e.blkIndent || e.sCount[o] - e.blkIndent >= 4)
      break;
    let T = !1;
    for (let B = 0, O = m.length; B < O; B++)
      if (m[B](e, o, t, !0)) {
        T = !0;
        break;
      }
    if (T)
      break;
    if (f) {
      if (A = $t(e, o), A < 0)
        break;
      l = e.bMarks[o] + e.tShift[o];
    } else if (A = Xt(e, o), A < 0)
      break;
    if (h !== e.src.charCodeAt(A - 1))
      break;
  }
  return f ? a = e.push("ordered_list_close", "ol", -1) : a = e.push("bullet_list_close", "ul", -1), a.markup = String.fromCharCode(h), C[1] = o, e.line = o, e.parentType = g, r && ia(e, w), !0;
}
function aa(e, u, t, c) {
  let s = e.bMarks[u] + e.tShift[u], i = e.eMarks[u], l = u + 1;
  if (e.sCount[u] - e.blkIndent >= 4 || e.src.charCodeAt(s) !== 91)
    return !1;
  function a(m) {
    const g = e.lineMax;
    if (m >= g || e.isEmpty(m))
      return null;
    let x = !1;
    if (e.sCount[m] - e.blkIndent > 3 && (x = !0), e.sCount[m] < 0 && (x = !0), !x) {
      const v = e.md.block.ruler.getRules("reference"), I = e.parentType;
      e.parentType = "reference";
      let D = !1;
      for (let _ = 0, E = v.length; _ < E; _++)
        if (v[_](e, m, g, !0)) {
          D = !0;
          break;
        }
      if (e.parentType = I, D)
        return null;
    }
    const p = e.bMarks[m] + e.tShift[m], y = e.eMarks[m];
    return e.src.slice(p, y + 1);
  }
  let o = e.src.slice(s, i + 1);
  i = o.length;
  let r = -1;
  for (s = 1; s < i; s++) {
    const m = o.charCodeAt(s);
    if (m === 91)
      return !1;
    if (m === 93) {
      r = s;
      break;
    } else if (m === 10) {
      const g = a(l);
      g !== null && (o += g, i = o.length, l++);
    } else if (m === 92 && (s++, s < i && o.charCodeAt(s) === 10)) {
      const g = a(l);
      g !== null && (o += g, i = o.length, l++);
    }
  }
  if (r < 0 || o.charCodeAt(r + 1) !== 58)
    return !1;
  for (s = r + 2; s < i; s++) {
    const m = o.charCodeAt(s);
    if (m === 10) {
      const g = a(l);
      g !== null && (o += g, i = o.length, l++);
    } else if (!Y(m)) break;
  }
  const n = e.md.helpers.parseLinkDestination(o, s, i);
  if (!n.ok)
    return !1;
  const f = e.md.normalizeLink(n.str);
  if (!e.md.validateLink(f))
    return !1;
  s = n.pos;
  const d = s, A = l, h = s;
  for (; s < i; s++) {
    const m = o.charCodeAt(s);
    if (m === 10) {
      const g = a(l);
      g !== null && (o += g, i = o.length, l++);
    } else if (!Y(m)) break;
  }
  let w = e.md.helpers.parseLinkTitle(o, s, i);
  for (; w.can_continue; ) {
    const m = a(l);
    if (m === null) break;
    o += m, s = i, i = o.length, l++, w = e.md.helpers.parseLinkTitle(o, s, i, w);
  }
  let C;
  for (s < i && h !== s && w.ok ? (C = w.str, s = w.pos) : (C = "", s = d, l = A); s < i; ) {
    const m = o.charCodeAt(s);
    if (!Y(m))
      break;
    s++;
  }
  if (s < i && o.charCodeAt(s) !== 10 && C)
    for (C = "", s = d, l = A; s < i; ) {
      const m = o.charCodeAt(s);
      if (!Y(m))
        break;
      s++;
    }
  if (s < i && o.charCodeAt(s) !== 10)
    return !1;
  const b = gu(o.slice(1, r));
  return b ? (c || (typeof e.env.references > "u" && (e.env.references = {}), typeof e.env.references[b] > "u" && (e.env.references[b] = { title: C, href: f }), e.line = l), !0) : !1;
}
const sa = [
  "address",
  "article",
  "aside",
  "base",
  "basefont",
  "blockquote",
  "body",
  "caption",
  "center",
  "col",
  "colgroup",
  "dd",
  "details",
  "dialog",
  "dir",
  "div",
  "dl",
  "dt",
  "fieldset",
  "figcaption",
  "figure",
  "footer",
  "form",
  "frame",
  "frameset",
  "h1",
  "h2",
  "h3",
  "h4",
  "h5",
  "h6",
  "head",
  "header",
  "hr",
  "html",
  "iframe",
  "legend",
  "li",
  "link",
  "main",
  "menu",
  "menuitem",
  "nav",
  "noframes",
  "ol",
  "optgroup",
  "option",
  "p",
  "param",
  "search",
  "section",
  "summary",
  "table",
  "tbody",
  "td",
  "tfoot",
  "th",
  "thead",
  "title",
  "tr",
  "track",
  "ul"
], ca = "[a-zA-Z_:][a-zA-Z0-9:._-]*", oa = "[^\"'=<>`\\x00-\\x20]+", la = "'[^']*'", fa = '"[^"]*"', da = "(?:" + oa + "|" + la + "|" + fa + ")", Aa = "(?:\\s+" + ca + "(?:\\s*=\\s*" + da + ")?)", Pr = "<[A-Za-z][A-Za-z0-9\\-]*" + Aa + "*\\s*\\/?>", Gr = "<\\/[A-Za-z][A-Za-z0-9\\-]*\\s*>", ha = "<!---?>|<!--(?:[^-]|-[^-]|--[^>])*-->", ba = "<[?][\\s\\S]*?[?]>", pa = "<![A-Za-z][^>]*>", ga = "<!\\[CDATA\\[[\\s\\S]*?\\]\\]>", ma = new RegExp("^(?:" + Pr + "|" + Gr + "|" + ha + "|" + ba + "|" + pa + "|" + ga + ")"), xa = new RegExp("^(?:" + Pr + "|" + Gr + ")"), Ne = [
  [/^<(script|pre|style|textarea)(?=(\s|>|$))/i, /<\/(script|pre|style|textarea)>/i, !0],
  [/^<!--/, /-->/, !0],
  [/^<\?/, /\?>/, !0],
  [/^<![A-Z]/, />/, !0],
  [/^<!\[CDATA\[/, /\]\]>/, !0],
  [new RegExp("^</?(" + sa.join("|") + ")(?=(\\s|/?>|$))", "i"), /^$/, !0],
  [new RegExp(xa.source + "\\s*$"), /^$/, !1]
];
function ya(e, u, t, c) {
  let s = e.bMarks[u] + e.tShift[u], i = e.eMarks[u];
  if (e.sCount[u] - e.blkIndent >= 4 || !e.md.options.html || e.src.charCodeAt(s) !== 60)
    return !1;
  let l = e.src.slice(s, i), a = 0;
  for (; a < Ne.length && !Ne[a][0].test(l); a++)
    ;
  if (a === Ne.length)
    return !1;
  if (c)
    return Ne[a][2];
  let o = u + 1;
  if (!Ne[a][1].test(l)) {
    for (; o < t && !(e.sCount[o] < e.blkIndent); o++)
      if (s = e.bMarks[o] + e.tShift[o], i = e.eMarks[o], l = e.src.slice(s, i), Ne[a][1].test(l)) {
        l.length !== 0 && o++;
        break;
      }
  }
  e.line = o;
  const r = e.push("html_block", "", 0);
  return r.map = [u, o], r.content = e.getLines(u, o, e.blkIndent, !0), !0;
}
function wa(e, u, t, c) {
  let s = e.bMarks[u] + e.tShift[u], i = e.eMarks[u];
  if (e.sCount[u] - e.blkIndent >= 4)
    return !1;
  let l = e.src.charCodeAt(s);
  if (l !== 35 || s >= i)
    return !1;
  let a = 1;
  for (l = e.src.charCodeAt(++s); l === 35 && s < i && a <= 6; )
    a++, l = e.src.charCodeAt(++s);
  if (a > 6 || s < i && !Y(l))
    return !1;
  if (c)
    return !0;
  i = e.skipSpacesBack(i, s);
  const o = e.skipCharsBack(i, 35, s);
  o > s && Y(e.src.charCodeAt(o - 1)) && (i = o), e.line = u + 1;
  const r = e.push("heading_open", "h" + String(a), 1);
  r.markup = "########".slice(0, a), r.map = [u, e.line];
  const n = e.push("inline", "", 0);
  n.content = e.src.slice(s, i).trim(), n.map = [u, e.line], n.children = [];
  const f = e.push("heading_close", "h" + String(a), -1);
  return f.markup = "########".slice(0, a), !0;
}
function Ca(e, u, t) {
  const c = e.md.block.ruler.getRules("paragraph");
  if (e.sCount[u] - e.blkIndent >= 4)
    return !1;
  const s = e.parentType;
  e.parentType = "paragraph";
  let i = 0, l, a = u + 1;
  for (; a < t && !e.isEmpty(a); a++) {
    if (e.sCount[a] - e.blkIndent > 3)
      continue;
    if (e.sCount[a] >= e.blkIndent) {
      let A = e.bMarks[a] + e.tShift[a];
      const h = e.eMarks[a];
      if (A < h && (l = e.src.charCodeAt(A), (l === 45 || l === 61) && (A = e.skipChars(A, l), A = e.skipSpaces(A), A >= h))) {
        i = l === 61 ? 1 : 2;
        break;
      }
    }
    if (e.sCount[a] < 0)
      continue;
    let d = !1;
    for (let A = 0, h = c.length; A < h; A++)
      if (c[A](e, a, t, !0)) {
        d = !0;
        break;
      }
    if (d)
      break;
  }
  if (!i)
    return !1;
  const o = e.getLines(u, a, e.blkIndent, !1).trim();
  e.line = a + 1;
  const r = e.push("heading_open", "h" + String(i), 1);
  r.markup = String.fromCharCode(l), r.map = [u, e.line];
  const n = e.push("inline", "", 0);
  n.content = o, n.map = [u, e.line - 1], n.children = [];
  const f = e.push("heading_close", "h" + String(i), -1);
  return f.markup = String.fromCharCode(l), e.parentType = s, !0;
}
function va(e, u, t) {
  const c = e.md.block.ruler.getRules("paragraph"), s = e.parentType;
  let i = u + 1;
  for (e.parentType = "paragraph"; i < t && !e.isEmpty(i); i++) {
    if (e.sCount[i] - e.blkIndent > 3 || e.sCount[i] < 0)
      continue;
    let r = !1;
    for (let n = 0, f = c.length; n < f; n++)
      if (c[n](e, i, t, !0)) {
        r = !0;
        break;
      }
    if (r)
      break;
  }
  const l = e.getLines(u, i, e.blkIndent, !1).trim();
  e.line = i;
  const a = e.push("paragraph_open", "p", 1);
  a.map = [u, e.line];
  const o = e.push("inline", "", 0);
  return o.content = l, o.map = [u, e.line], o.children = [], e.push("paragraph_close", "p", -1), e.parentType = s, !0;
}
const ru = [
  // First 2 params - rule name & source. Secondary array - list of rules,
  // which can be terminated by this one.
  ["table", $n, ["paragraph", "reference"]],
  ["code", ea],
  ["fence", ua, ["paragraph", "reference", "blockquote", "list"]],
  ["blockquote", ta, ["paragraph", "reference", "blockquote", "list"]],
  ["hr", ra, ["paragraph", "reference", "blockquote", "list"]],
  ["list", na, ["paragraph", "reference", "blockquote"]],
  ["reference", aa],
  ["html_block", ya, ["paragraph", "reference", "blockquote"]],
  ["heading", wa, ["paragraph", "reference", "blockquote"]],
  ["lheading", Ca],
  ["paragraph", va]
];
function mu() {
  this.ruler = new $();
  for (let e = 0; e < ru.length; e++)
    this.ruler.push(ru[e][0], ru[e][1], { alt: (ru[e][2] || []).slice() });
}
mu.prototype.tokenize = function(e, u, t) {
  const c = this.ruler.getRules(""), s = c.length, i = e.md.options.maxNesting;
  let l = u, a = !1;
  for (; l < t && (e.line = l = e.skipEmptyLines(l), !(l >= t || e.sCount[l] < e.blkIndent)); ) {
    if (e.level >= i) {
      e.line = t;
      break;
    }
    const o = e.line;
    let r = !1;
    for (let n = 0; n < s; n++)
      if (r = c[n](e, l, t, !1), r) {
        if (o >= e.line)
          throw new Error("block rule didn't increment state.line");
        break;
      }
    if (!r) throw new Error("none of the block rules matched");
    e.tight = !a, e.isEmpty(e.line - 1) && (a = !0), l = e.line, l < t && e.isEmpty(l) && (a = !0, l++, e.line = l);
  }
};
mu.prototype.parse = function(e, u, t, c) {
  if (!e)
    return;
  const s = new this.State(e, u, t, c);
  this.tokenize(s, s.line, s.lineMax);
};
mu.prototype.State = be;
function Ve(e, u, t, c) {
  this.src = e, this.env = t, this.md = u, this.tokens = c, this.tokens_meta = Array(c.length), this.pos = 0, this.posMax = this.src.length, this.level = 0, this.pending = "", this.pendingLevel = 0, this.cache = {}, this.delimiters = [], this._prev_delimiters = [], this.backticks = {}, this.backticksScanned = !1, this.linkLevel = 0;
}
Ve.prototype.pushPending = function() {
  const e = new le("text", "", 0);
  return e.content = this.pending, e.level = this.pendingLevel, this.tokens.push(e), this.pending = "", e;
};
Ve.prototype.push = function(e, u, t) {
  this.pending && this.pushPending();
  const c = new le(e, u, t);
  let s = null;
  return t < 0 && (this.level--, this.delimiters = this._prev_delimiters.pop()), c.level = this.level, t > 0 && (this.level++, this._prev_delimiters.push(this.delimiters), this.delimiters = [], s = { delimiters: this.delimiters }), this.pendingLevel = this.level, this.tokens.push(c), this.tokens_meta.push(s), c;
};
Ve.prototype.scanDelims = function(e, u) {
  const t = this.posMax, c = this.src.charCodeAt(e), s = e > 0 ? this.src.charCodeAt(e - 1) : 32;
  let i = e;
  for (; i < t && this.src.charCodeAt(i) === c; )
    i++;
  const l = i - e, a = i < t ? this.src.charCodeAt(i) : 32, o = je(s) || Ye(String.fromCharCode(s)), r = je(a) || Ye(String.fromCharCode(a)), n = Ke(s), f = Ke(a), d = !f && (!r || n || o), A = !n && (!o || f || r);
  return { can_open: d && (u || !A || o), can_close: A && (u || !d || r), length: l };
};
Ve.prototype.Token = le;
function Ea(e) {
  switch (e) {
    case 10:
    case 33:
    case 35:
    case 36:
    case 37:
    case 38:
    case 42:
    case 43:
    case 45:
    case 58:
    case 60:
    case 61:
    case 62:
    case 64:
    case 91:
    case 92:
    case 93:
    case 94:
    case 95:
    case 96:
    case 123:
    case 125:
    case 126:
      return !0;
    default:
      return !1;
  }
}
function Da(e, u) {
  let t = e.pos;
  for (; t < e.posMax && !Ea(e.src.charCodeAt(t)); )
    t++;
  return t === e.pos ? !1 : (u || (e.pending += e.src.slice(e.pos, t)), e.pos = t, !0);
}
const Ia = /(?:^|[^a-z0-9.+-])([a-z][a-z0-9.+-]*)$/i;
function _a(e, u) {
  if (!e.md.options.linkify || e.linkLevel > 0) return !1;
  const t = e.pos, c = e.posMax;
  if (t + 3 > c || e.src.charCodeAt(t) !== 58 || e.src.charCodeAt(t + 1) !== 47 || e.src.charCodeAt(t + 2) !== 47) return !1;
  const s = e.pending.match(Ia);
  if (!s) return !1;
  const i = s[1], l = e.md.linkify.matchAtStart(e.src.slice(t - i.length));
  if (!l) return !1;
  let a = l.url;
  if (a.length <= i.length) return !1;
  let o = a.length;
  for (; o > 0 && a.charCodeAt(o - 1) === 42; )
    o--;
  o !== a.length && (a = a.slice(0, o));
  const r = e.md.normalizeLink(a);
  if (!e.md.validateLink(r)) return !1;
  if (!u) {
    e.pending = e.pending.slice(0, -i.length);
    const n = e.push("link_open", "a", 1);
    n.attrs = [["href", r]], n.markup = "linkify", n.info = "auto";
    const f = e.push("text", "", 0);
    f.content = e.md.normalizeLinkText(a);
    const d = e.push("link_close", "a", -1);
    d.markup = "linkify", d.info = "auto";
  }
  return e.pos += a.length - i.length, !0;
}
function ka(e, u) {
  let t = e.pos;
  if (e.src.charCodeAt(t) !== 10)
    return !1;
  const c = e.pending.length - 1, s = e.posMax;
  if (!u)
    if (c >= 0 && e.pending.charCodeAt(c) === 32)
      if (c >= 1 && e.pending.charCodeAt(c - 1) === 32) {
        let i = c - 1;
        for (; i >= 1 && e.pending.charCodeAt(i - 1) === 32; ) i--;
        e.pending = e.pending.slice(0, i), e.push("hardbreak", "br", 0);
      } else
        e.pending = e.pending.slice(0, -1), e.push("softbreak", "br", 0);
    else
      e.push("softbreak", "br", 0);
  for (t++; t < s && Y(e.src.charCodeAt(t)); )
    t++;
  return e.pos = t, !0;
}
const Bt = [];
for (let e = 0; e < 256; e++)
  Bt.push(0);
"\\!\"#$%&'()*+,./:;<=>?@[]^_`{|}~-".split("").forEach(function(e) {
  Bt[e.charCodeAt(0)] = 1;
});
function Ba(e, u) {
  let t = e.pos;
  const c = e.posMax;
  if (e.src.charCodeAt(t) !== 92 || (t++, t >= c)) return !1;
  let s = e.src.charCodeAt(t);
  if (s === 10) {
    for (u || e.push("hardbreak", "br", 0), t++; t < c && (s = e.src.charCodeAt(t), !!Y(s)); )
      t++;
    return e.pos = t, !0;
  }
  let i = e.src[t];
  if (s >= 55296 && s <= 56319 && t + 1 < c) {
    const a = e.src.charCodeAt(t + 1);
    a >= 56320 && a <= 57343 && (i += e.src[t + 1], t++);
  }
  const l = "\\" + i;
  if (!u) {
    const a = e.push("text_special", "", 0);
    s < 256 && Bt[s] !== 0 ? a.content = i : a.content = l, a.markup = l, a.info = "escape";
  }
  return e.pos = t + 1, !0;
}
function Fa(e, u) {
  let t = e.pos;
  if (e.src.charCodeAt(t) !== 96)
    return !1;
  const s = t;
  t++;
  const i = e.posMax;
  for (; t < i && e.src.charCodeAt(t) === 96; )
    t++;
  const l = e.src.slice(s, t), a = l.length;
  if (e.backticksScanned && (e.backticks[a] || 0) <= s)
    return u || (e.pending += l), e.pos += a, !0;
  let o = t, r;
  for (; (r = e.src.indexOf("`", o)) !== -1; ) {
    for (o = r + 1; o < i && e.src.charCodeAt(o) === 96; )
      o++;
    const n = o - r;
    if (n === a) {
      if (!u) {
        const f = e.push("code_inline", "code", 0);
        f.markup = l, f.content = e.src.slice(t, r).replace(/\n/g, " ").replace(/^ (.+) $/, "$1");
      }
      return e.pos = o, !0;
    }
    e.backticks[n] = r;
  }
  return e.backticksScanned = !0, u || (e.pending += l), e.pos += a, !0;
}
function Sa(e, u) {
  const t = e.pos, c = e.src.charCodeAt(t);
  if (u || c !== 126)
    return !1;
  const s = e.scanDelims(e.pos, !0);
  let i = s.length;
  const l = String.fromCharCode(c);
  if (i < 2)
    return !1;
  let a;
  i % 2 && (a = e.push("text", "", 0), a.content = l, i--);
  for (let o = 0; o < i; o += 2)
    a = e.push("text", "", 0), a.content = l + l, e.delimiters.push({
      marker: c,
      length: 0,
      // disable "rule of 3" length checks meant for emphasis
      token: e.tokens.length - 1,
      end: -1,
      open: s.can_open,
      close: s.can_close
    });
  return e.pos += s.length, !0;
}
function e0(e, u) {
  let t;
  const c = [], s = u.length;
  for (let i = 0; i < s; i++) {
    const l = u[i];
    if (l.marker !== 126 || l.end === -1)
      continue;
    const a = u[l.end];
    t = e.tokens[l.token], t.type = "s_open", t.tag = "s", t.nesting = 1, t.markup = "~~", t.content = "", t = e.tokens[a.token], t.type = "s_close", t.tag = "s", t.nesting = -1, t.markup = "~~", t.content = "", e.tokens[a.token - 1].type === "text" && e.tokens[a.token - 1].content === "~" && c.push(a.token - 1);
  }
  for (; c.length; ) {
    const i = c.pop();
    let l = i + 1;
    for (; l < e.tokens.length && e.tokens[l].type === "s_close"; )
      l++;
    l--, i !== l && (t = e.tokens[l], e.tokens[l] = e.tokens[i], e.tokens[i] = t);
  }
}
function Ra(e) {
  const u = e.tokens_meta, t = e.tokens_meta.length;
  e0(e, e.delimiters);
  for (let c = 0; c < t; c++)
    u[c] && u[c].delimiters && e0(e, u[c].delimiters);
}
const qr = {
  tokenize: Sa,
  postProcess: Ra
};
function Ta(e, u) {
  const t = e.pos, c = e.src.charCodeAt(t);
  if (u || c !== 95 && c !== 42)
    return !1;
  const s = e.scanDelims(e.pos, c === 42);
  for (let i = 0; i < s.length; i++) {
    const l = e.push("text", "", 0);
    l.content = String.fromCharCode(c), e.delimiters.push({
      // Char code of the starting marker (number).
      //
      marker: c,
      // Total length of these series of delimiters.
      //
      length: s.length,
      // A position of the token this delimiter corresponds to.
      //
      token: e.tokens.length - 1,
      // If this delimiter is matched as a valid opener, `end` will be
      // equal to its position, otherwise it's `-1`.
      //
      end: -1,
      // Boolean flags that determine if this delimiter could open or close
      // an emphasis.
      //
      open: s.can_open,
      close: s.can_close
    });
  }
  return e.pos += s.length, !0;
}
function u0(e, u) {
  const t = u.length;
  for (let c = t - 1; c >= 0; c--) {
    const s = u[c];
    if (s.marker !== 95 && s.marker !== 42 || s.end === -1)
      continue;
    const i = u[s.end], l = c > 0 && u[c - 1].end === s.end + 1 && // check that first two markers match and adjacent
    u[c - 1].marker === s.marker && u[c - 1].token === s.token - 1 && // check that last two markers are adjacent (we can safely assume they match)
    u[s.end + 1].token === i.token + 1, a = String.fromCharCode(s.marker), o = e.tokens[s.token];
    o.type = l ? "strong_open" : "em_open", o.tag = l ? "strong" : "em", o.nesting = 1, o.markup = l ? a + a : a, o.content = "";
    const r = e.tokens[i.token];
    r.type = l ? "strong_close" : "em_close", r.tag = l ? "strong" : "em", r.nesting = -1, r.markup = l ? a + a : a, r.content = "", l && (e.tokens[u[c - 1].token].content = "", e.tokens[u[s.end + 1].token].content = "", c--);
  }
}
function Na(e) {
  const u = e.tokens_meta, t = e.tokens_meta.length;
  u0(e, e.delimiters);
  for (let c = 0; c < t; c++)
    u[c] && u[c].delimiters && u0(e, u[c].delimiters);
}
const Hr = {
  tokenize: Ta,
  postProcess: Na
};
function Oa(e, u) {
  let t, c, s, i, l = "", a = "", o = e.pos, r = !0;
  if (e.src.charCodeAt(e.pos) !== 91)
    return !1;
  const n = e.pos, f = e.posMax, d = e.pos + 1, A = e.md.helpers.parseLinkLabel(e, e.pos, !0);
  if (A < 0)
    return !1;
  let h = A + 1;
  if (h < f && e.src.charCodeAt(h) === 40) {
    for (r = !1, h++; h < f && (t = e.src.charCodeAt(h), !(!Y(t) && t !== 10)); h++)
      ;
    if (h >= f)
      return !1;
    if (o = h, s = e.md.helpers.parseLinkDestination(e.src, h, e.posMax), s.ok) {
      for (l = e.md.normalizeLink(s.str), e.md.validateLink(l) ? h = s.pos : l = "", o = h; h < f && (t = e.src.charCodeAt(h), !(!Y(t) && t !== 10)); h++)
        ;
      if (s = e.md.helpers.parseLinkTitle(e.src, h, e.posMax), h < f && o !== h && s.ok)
        for (a = s.str, h = s.pos; h < f && (t = e.src.charCodeAt(h), !(!Y(t) && t !== 10)); h++)
          ;
    }
    (h >= f || e.src.charCodeAt(h) !== 41) && (r = !0), h++;
  }
  if (r) {
    if (typeof e.env.references > "u")
      return !1;
    if (h < f && e.src.charCodeAt(h) === 91 ? (o = h + 1, h = e.md.helpers.parseLinkLabel(e, h), h >= 0 ? c = e.src.slice(o, h++) : h = A + 1) : h = A + 1, c || (c = e.src.slice(d, A)), i = e.env.references[gu(c)], !i)
      return e.pos = n, !1;
    l = i.href, a = i.title;
  }
  if (!u) {
    e.pos = d, e.posMax = A;
    const w = e.push("link_open", "a", 1), C = [["href", l]];
    w.attrs = C, a && C.push(["title", a]), e.linkLevel++, e.md.inline.tokenize(e), e.linkLevel--, e.push("link_close", "a", -1);
  }
  return e.pos = h, e.posMax = f, !0;
}
function Ma(e, u) {
  let t, c, s, i, l, a, o, r, n = "";
  const f = e.pos, d = e.posMax;
  if (e.src.charCodeAt(e.pos) !== 33 || e.src.charCodeAt(e.pos + 1) !== 91)
    return !1;
  const A = e.pos + 2, h = e.md.helpers.parseLinkLabel(e, e.pos + 1, !1);
  if (h < 0)
    return !1;
  if (i = h + 1, i < d && e.src.charCodeAt(i) === 40) {
    for (i++; i < d && (t = e.src.charCodeAt(i), !(!Y(t) && t !== 10)); i++)
      ;
    if (i >= d)
      return !1;
    for (r = i, a = e.md.helpers.parseLinkDestination(e.src, i, e.posMax), a.ok && (n = e.md.normalizeLink(a.str), e.md.validateLink(n) ? i = a.pos : n = ""), r = i; i < d && (t = e.src.charCodeAt(i), !(!Y(t) && t !== 10)); i++)
      ;
    if (a = e.md.helpers.parseLinkTitle(e.src, i, e.posMax), i < d && r !== i && a.ok)
      for (o = a.str, i = a.pos; i < d && (t = e.src.charCodeAt(i), !(!Y(t) && t !== 10)); i++)
        ;
    else
      o = "";
    if (i >= d || e.src.charCodeAt(i) !== 41)
      return e.pos = f, !1;
    i++;
  } else {
    if (typeof e.env.references > "u")
      return !1;
    if (i < d && e.src.charCodeAt(i) === 91 ? (r = i + 1, i = e.md.helpers.parseLinkLabel(e, i), i >= 0 ? s = e.src.slice(r, i++) : i = h + 1) : i = h + 1, s || (s = e.src.slice(A, h)), l = e.env.references[gu(s)], !l)
      return e.pos = f, !1;
    n = l.href, o = l.title;
  }
  if (!u) {
    c = e.src.slice(A, h);
    const w = [];
    e.md.inline.parse(
      c,
      e.md,
      e.env,
      w
    );
    const C = e.push("image", "img", 0), b = [["src", n], ["alt", ""]];
    C.attrs = b, C.children = w, C.content = c, o && b.push(["title", o]);
  }
  return e.pos = i, e.posMax = d, !0;
}
const Qa = /^([a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*)$/, La = /^([a-zA-Z][a-zA-Z0-9+.-]{1,31}):([^<>\x00-\x20]*)$/;
function Pa(e, u) {
  let t = e.pos;
  if (e.src.charCodeAt(t) !== 60)
    return !1;
  const c = e.pos, s = e.posMax;
  for (; ; ) {
    if (++t >= s) return !1;
    const l = e.src.charCodeAt(t);
    if (l === 60) return !1;
    if (l === 62) break;
  }
  const i = e.src.slice(c + 1, t);
  if (La.test(i)) {
    const l = e.md.normalizeLink(i);
    if (!e.md.validateLink(l))
      return !1;
    if (!u) {
      const a = e.push("link_open", "a", 1);
      a.attrs = [["href", l]], a.markup = "autolink", a.info = "auto";
      const o = e.push("text", "", 0);
      o.content = e.md.normalizeLinkText(i);
      const r = e.push("link_close", "a", -1);
      r.markup = "autolink", r.info = "auto";
    }
    return e.pos += i.length + 2, !0;
  }
  if (Qa.test(i)) {
    const l = e.md.normalizeLink("mailto:" + i);
    if (!e.md.validateLink(l))
      return !1;
    if (!u) {
      const a = e.push("link_open", "a", 1);
      a.attrs = [["href", l]], a.markup = "autolink", a.info = "auto";
      const o = e.push("text", "", 0);
      o.content = e.md.normalizeLinkText(i);
      const r = e.push("link_close", "a", -1);
      r.markup = "autolink", r.info = "auto";
    }
    return e.pos += i.length + 2, !0;
  }
  return !1;
}
function Ga(e) {
  return /^<a[>\s]/i.test(e);
}
function qa(e) {
  return /^<\/a\s*>/i.test(e);
}
function Ha(e) {
  const u = e | 32;
  return u >= 97 && u <= 122;
}
function Wa(e, u) {
  if (!e.md.options.html)
    return !1;
  const t = e.posMax, c = e.pos;
  if (e.src.charCodeAt(c) !== 60 || c + 2 >= t)
    return !1;
  const s = e.src.charCodeAt(c + 1);
  if (s !== 33 && s !== 63 && s !== 47 && !Ha(s))
    return !1;
  const i = e.src.slice(c).match(ma);
  if (!i)
    return !1;
  if (!u) {
    const l = e.push("html_inline", "", 0);
    l.content = i[0], Ga(l.content) && e.linkLevel++, qa(l.content) && e.linkLevel--;
  }
  return e.pos += i[0].length, !0;
}
const Ua = /^&#((?:x[a-f0-9]{1,6}|[0-9]{1,7}));/i, Ka = /^&([a-z][a-z0-9]{1,31});/i;
function Ya(e, u) {
  const t = e.pos, c = e.posMax;
  if (e.src.charCodeAt(t) !== 38 || t + 1 >= c) return !1;
  if (e.src.charCodeAt(t + 1) === 35) {
    const i = e.src.slice(t).match(Ua);
    if (i) {
      if (!u) {
        const l = i[1][0].toLowerCase() === "x" ? parseInt(i[1].slice(1), 16) : parseInt(i[1], 10), a = e.push("text_special", "", 0);
        a.content = _t(l) ? hu(l) : hu(65533), a.markup = i[0], a.info = "entity";
      }
      return e.pos += i[0].length, !0;
    }
  } else {
    const i = e.src.slice(t).match(Ka);
    if (i) {
      const l = Nr(i[0]);
      if (l !== i[0]) {
        if (!u) {
          const a = e.push("text_special", "", 0);
          a.content = l, a.markup = i[0], a.info = "entity";
        }
        return e.pos += i[0].length, !0;
      }
    }
  }
  return !1;
}
function t0(e) {
  const u = {}, t = e.length;
  if (!t) return;
  let c = 0, s = -2;
  const i = [];
  for (let l = 0; l < t; l++) {
    const a = e[l];
    if (i.push(0), (e[c].marker !== a.marker || s !== a.token - 1) && (c = l), s = a.token, a.length = a.length || 0, !a.close) continue;
    u.hasOwnProperty(a.marker) || (u[a.marker] = [-1, -1, -1, -1, -1, -1]);
    const o = u[a.marker][(a.open ? 3 : 0) + a.length % 3];
    let r = c - i[c] - 1, n = r;
    for (; r > o; r -= i[r] + 1) {
      const f = e[r];
      if (f.marker === a.marker && f.open && f.end < 0) {
        let d = !1;
        if ((f.close || a.open) && (f.length + a.length) % 3 === 0 && (f.length % 3 !== 0 || a.length % 3 !== 0) && (d = !0), !d) {
          const A = r > 0 && !e[r - 1].open ? i[r - 1] + 1 : 0;
          i[l] = l - r + A, i[r] = A, a.open = !1, f.end = l, f.close = !1, n = -1, s = -2;
          break;
        }
      }
    }
    n !== -1 && (u[a.marker][(a.open ? 3 : 0) + (a.length || 0) % 3] = n);
  }
}
function ja(e) {
  const u = e.tokens_meta, t = e.tokens_meta.length;
  t0(e.delimiters);
  for (let c = 0; c < t; c++)
    u[c] && u[c].delimiters && t0(u[c].delimiters);
}
function Ja(e) {
  let u, t, c = 0;
  const s = e.tokens, i = e.tokens.length;
  for (u = t = 0; u < i; u++)
    s[u].nesting < 0 && c--, s[u].level = c, s[u].nesting > 0 && c++, s[u].type === "text" && u + 1 < i && s[u + 1].type === "text" ? s[u + 1].content = s[u].content + s[u + 1].content : (u !== t && (s[t] = s[u]), t++);
  u !== t && (s.length = t);
}
const Ru = [
  ["text", Da],
  ["linkify", _a],
  ["newline", ka],
  ["escape", Ba],
  ["backticks", Fa],
  ["strikethrough", qr.tokenize],
  ["emphasis", Hr.tokenize],
  ["link", Oa],
  ["image", Ma],
  ["autolink", Pa],
  ["html_inline", Wa],
  ["entity", Ya]
], Tu = [
  ["balance_pairs", ja],
  ["strikethrough", qr.postProcess],
  ["emphasis", Hr.postProcess],
  // rules for pairs separate '**' into its own text tokens, which may be left unused,
  // rule below merges unused segments back with the rest of the text
  ["fragments_join", Ja]
];
function ze() {
  this.ruler = new $();
  for (let e = 0; e < Ru.length; e++)
    this.ruler.push(Ru[e][0], Ru[e][1]);
  this.ruler2 = new $();
  for (let e = 0; e < Tu.length; e++)
    this.ruler2.push(Tu[e][0], Tu[e][1]);
}
ze.prototype.skipToken = function(e) {
  const u = e.pos, t = this.ruler.getRules(""), c = t.length, s = e.md.options.maxNesting, i = e.cache;
  if (typeof i[u] < "u") {
    e.pos = i[u];
    return;
  }
  let l = !1;
  if (e.level < s) {
    for (let a = 0; a < c; a++)
      if (e.level++, l = t[a](e, !0), e.level--, l) {
        if (u >= e.pos)
          throw new Error("inline rule didn't increment state.pos");
        break;
      }
  } else
    e.pos = e.posMax;
  l || e.pos++, i[u] = e.pos;
};
ze.prototype.tokenize = function(e) {
  const u = this.ruler.getRules(""), t = u.length, c = e.posMax, s = e.md.options.maxNesting;
  for (; e.pos < c; ) {
    const i = e.pos;
    let l = !1;
    if (e.level < s) {
      for (let a = 0; a < t; a++)
        if (l = u[a](e, !1), l) {
          if (i >= e.pos)
            throw new Error("inline rule didn't increment state.pos");
          break;
        }
    }
    if (l) {
      if (e.pos >= c)
        break;
      continue;
    }
    e.pending += e.src[e.pos++];
  }
  e.pending && e.pushPending();
};
ze.prototype.parse = function(e, u, t, c) {
  const s = new this.State(e, u, t, c);
  this.tokenize(s);
  const i = this.ruler2.getRules(""), l = i.length;
  for (let a = 0; a < l; a++)
    i[a](s);
};
ze.prototype.State = Ve;
function Za(e) {
  const u = {};
  e = e || {}, u.src_Any = Br.source, u.src_Cc = Fr.source, u.src_Z = Rr.source, u.src_P = Dt.source, u.src_ZPCc = [u.src_Z, u.src_P, u.src_Cc].join("|"), u.src_ZCc = [u.src_Z, u.src_Cc].join("|");
  const t = "[><｜]";
  return u.src_pseudo_letter = "(?:(?!" + t + "|" + u.src_ZPCc + ")" + u.src_Any + ")", u.src_ip4 = "(?:(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)", u.src_auth = "(?:(?:(?!" + u.src_ZCc + "|[@/\\[\\]()]).)+@)?", u.src_port = "(?::(?:6(?:[0-4]\\d{3}|5(?:[0-4]\\d{2}|5(?:[0-2]\\d|3[0-5])))|[1-5]?\\d{1,4}))?", u.src_host_terminator = "(?=$|" + t + "|" + u.src_ZPCc + ")(?!" + (e["---"] ? "-(?!--)|" : "-|") + "_|:\\d|\\.-|\\.(?!$|" + u.src_ZPCc + "))", u.src_path = "(?:[/?#](?:(?!" + u.src_ZCc + "|" + t + `|[()[\\]{}.,"'?!\\-;]).|\\[(?:(?!` + u.src_ZCc + "|\\]).)*\\]|\\((?:(?!" + u.src_ZCc + "|[)]).)*\\)|\\{(?:(?!" + u.src_ZCc + '|[}]).)*\\}|\\"(?:(?!' + u.src_ZCc + `|["]).)+\\"|\\'(?:(?!` + u.src_ZCc + "|[']).)+\\'|\\'(?=" + u.src_pseudo_letter + "|[-])|\\.{2,}[a-zA-Z0-9%/&]|\\.(?!" + u.src_ZCc + "|[.]|$)|" + (e["---"] ? "\\-(?!--(?:[^-]|$))(?:-*)|" : "\\-+|") + // allow `,,,` in paths
  ",(?!" + u.src_ZCc + "|$)|;(?!" + u.src_ZCc + "|$)|\\!+(?!" + u.src_ZCc + "|[!]|$)|\\?(?!" + u.src_ZCc + "|[?]|$))+|\\/)?", u.src_email_name = '[\\-;:&=\\+\\$,\\.a-zA-Z0-9_][\\-;:&=\\+\\$,\\"\\.a-zA-Z0-9_]*', u.src_xn = "xn--[a-z0-9\\-]{1,59}", u.src_domain_root = // Allow letters & digits (http://test1)
  "(?:" + u.src_xn + "|" + u.src_pseudo_letter + "{1,63})", u.src_domain = "(?:" + u.src_xn + "|(?:" + u.src_pseudo_letter + ")|(?:" + u.src_pseudo_letter + "(?:-|" + u.src_pseudo_letter + "){0,61}" + u.src_pseudo_letter + "))", u.src_host = "(?:(?:(?:(?:" + u.src_domain + ")\\.)*" + u.src_domain + "))", u.tpl_host_fuzzy = "(?:" + u.src_ip4 + "|(?:(?:(?:" + u.src_domain + ")\\.)+(?:%TLDS%)))", u.tpl_host_no_ip_fuzzy = "(?:(?:(?:" + u.src_domain + ")\\.)+(?:%TLDS%))", u.src_host_strict = u.src_host + u.src_host_terminator, u.tpl_host_fuzzy_strict = u.tpl_host_fuzzy + u.src_host_terminator, u.src_host_port_strict = u.src_host + u.src_port + u.src_host_terminator, u.tpl_host_port_fuzzy_strict = u.tpl_host_fuzzy + u.src_port + u.src_host_terminator, u.tpl_host_port_no_ip_fuzzy_strict = u.tpl_host_no_ip_fuzzy + u.src_port + u.src_host_terminator, u.tpl_host_fuzzy_test = "localhost|www\\.|\\.\\d{1,3}\\.|(?:\\.(?:%TLDS%)(?:" + u.src_ZPCc + "|>|$))", u.tpl_email_fuzzy = "(^|" + t + '|"|\\(|' + u.src_ZCc + ")(" + u.src_email_name + "@" + u.tpl_host_fuzzy_strict + ")", u.tpl_link_fuzzy = // Fuzzy link can't be prepended with .:/\- and non punctuation.
  // but can start with > (markdown blockquote)
  "(^|(?![.:/\\-_@])(?:[$+<=>^`|｜]|" + u.src_ZPCc + "))((?![$+<=>^`|｜])" + u.tpl_host_port_fuzzy_strict + u.src_path + ")", u.tpl_link_no_ip_fuzzy = // Fuzzy link can't be prepended with .:/\- and non punctuation.
  // but can start with > (markdown blockquote)
  "(^|(?![.:/\\-_@])(?:[$+<=>^`|｜]|" + u.src_ZPCc + "))((?![$+<=>^`|｜])" + u.tpl_host_port_no_ip_fuzzy_strict + u.src_path + ")", u;
}
function yt(e) {
  return Array.prototype.slice.call(arguments, 1).forEach(function(t) {
    t && Object.keys(t).forEach(function(c) {
      e[c] = t[c];
    });
  }), e;
}
function xu(e) {
  return Object.prototype.toString.call(e);
}
function Va(e) {
  return xu(e) === "[object String]";
}
function za(e) {
  return xu(e) === "[object Object]";
}
function Xa(e) {
  return xu(e) === "[object RegExp]";
}
function r0(e) {
  return xu(e) === "[object Function]";
}
function $a(e) {
  return e.replace(/[.?*+^$[\]\\(){}|-]/g, "\\$&");
}
const Wr = {
  fuzzyLink: !0,
  fuzzyEmail: !0,
  fuzzyIP: !1
};
function es(e) {
  return Object.keys(e || {}).reduce(function(u, t) {
    return u || Wr.hasOwnProperty(t);
  }, !1);
}
const us = {
  "http:": {
    validate: function(e, u, t) {
      const c = e.slice(u);
      return t.re.http || (t.re.http = new RegExp(
        "^\\/\\/" + t.re.src_auth + t.re.src_host_port_strict + t.re.src_path,
        "i"
      )), t.re.http.test(c) ? c.match(t.re.http)[0].length : 0;
    }
  },
  "https:": "http:",
  "ftp:": "http:",
  "//": {
    validate: function(e, u, t) {
      const c = e.slice(u);
      return t.re.no_http || (t.re.no_http = new RegExp(
        "^" + t.re.src_auth + // Don't allow single-level domains, because of false positives like '//test'
        // with code comments
        "(?:localhost|(?:(?:" + t.re.src_domain + ")\\.)+" + t.re.src_domain_root + ")" + t.re.src_port + t.re.src_host_terminator + t.re.src_path,
        "i"
      )), t.re.no_http.test(c) ? u >= 3 && e[u - 3] === ":" || u >= 3 && e[u - 3] === "/" ? 0 : c.match(t.re.no_http)[0].length : 0;
    }
  },
  "mailto:": {
    validate: function(e, u, t) {
      const c = e.slice(u);
      return t.re.mailto || (t.re.mailto = new RegExp(
        "^" + t.re.src_email_name + "@" + t.re.src_host_strict,
        "i"
      )), t.re.mailto.test(c) ? c.match(t.re.mailto)[0].length : 0;
    }
  }
}, ts = "a[cdefgilmnoqrstuwxz]|b[abdefghijmnorstvwyz]|c[acdfghiklmnoruvwxyz]|d[ejkmoz]|e[cegrstu]|f[ijkmor]|g[abdefghilmnpqrstuwy]|h[kmnrtu]|i[delmnoqrst]|j[emop]|k[eghimnprwyz]|l[abcikrstuvy]|m[acdeghklmnopqrstuvwxyz]|n[acefgilopruz]|om|p[aefghklmnrstwy]|qa|r[eosuw]|s[abcdeghijklmnortuvxyz]|t[cdfghjklmnortvwz]|u[agksyz]|v[aceginu]|w[fs]|y[et]|z[amw]", rs = "biz|com|edu|gov|net|org|pro|web|xxx|aero|asia|coop|info|museum|name|shop|рф".split("|");
function is(e) {
  e.__index__ = -1, e.__text_cache__ = "";
}
function ns(e) {
  return function(u, t) {
    const c = u.slice(t);
    return e.test(c) ? c.match(e)[0].length : 0;
  };
}
function i0() {
  return function(e, u) {
    u.normalize(e);
  };
}
function bu(e) {
  const u = e.re = Za(e.__opts__), t = e.__tlds__.slice();
  e.onCompile(), e.__tlds_replaced__ || t.push(ts), t.push(u.src_xn), u.src_tlds = t.join("|");
  function c(a) {
    return a.replace("%TLDS%", u.src_tlds);
  }
  u.email_fuzzy = RegExp(c(u.tpl_email_fuzzy), "i"), u.link_fuzzy = RegExp(c(u.tpl_link_fuzzy), "i"), u.link_no_ip_fuzzy = RegExp(c(u.tpl_link_no_ip_fuzzy), "i"), u.host_fuzzy_test = RegExp(c(u.tpl_host_fuzzy_test), "i");
  const s = [];
  e.__compiled__ = {};
  function i(a, o) {
    throw new Error('(LinkifyIt) Invalid schema "' + a + '": ' + o);
  }
  Object.keys(e.__schemas__).forEach(function(a) {
    const o = e.__schemas__[a];
    if (o === null)
      return;
    const r = { validate: null, link: null };
    if (e.__compiled__[a] = r, za(o)) {
      Xa(o.validate) ? r.validate = ns(o.validate) : r0(o.validate) ? r.validate = o.validate : i(a, o), r0(o.normalize) ? r.normalize = o.normalize : o.normalize ? i(a, o) : r.normalize = i0();
      return;
    }
    if (Va(o)) {
      s.push(a);
      return;
    }
    i(a, o);
  }), s.forEach(function(a) {
    e.__compiled__[e.__schemas__[a]] && (e.__compiled__[a].validate = e.__compiled__[e.__schemas__[a]].validate, e.__compiled__[a].normalize = e.__compiled__[e.__schemas__[a]].normalize);
  }), e.__compiled__[""] = { validate: null, normalize: i0() };
  const l = Object.keys(e.__compiled__).filter(function(a) {
    return a.length > 0 && e.__compiled__[a];
  }).map($a).join("|");
  e.re.schema_test = RegExp("(^|(?!_)(?:[><｜]|" + u.src_ZPCc + "))(" + l + ")", "i"), e.re.schema_search = RegExp("(^|(?!_)(?:[><｜]|" + u.src_ZPCc + "))(" + l + ")", "ig"), e.re.schema_at_start = RegExp("^" + e.re.schema_search.source, "i"), e.re.pretest = RegExp(
    "(" + e.re.schema_test.source + ")|(" + e.re.host_fuzzy_test.source + ")|@",
    "i"
  ), is(e);
}
function as(e, u) {
  const t = e.__index__, c = e.__last_index__, s = e.__text_cache__.slice(t, c);
  this.schema = e.__schema__.toLowerCase(), this.index = t + u, this.lastIndex = c + u, this.raw = s, this.text = s, this.url = s;
}
function wt(e, u) {
  const t = new as(e, u);
  return e.__compiled__[t.schema].normalize(t, e), t;
}
function te(e, u) {
  if (!(this instanceof te))
    return new te(e, u);
  u || es(e) && (u = e, e = {}), this.__opts__ = yt({}, Wr, u), this.__index__ = -1, this.__last_index__ = -1, this.__schema__ = "", this.__text_cache__ = "", this.__schemas__ = yt({}, us, e), this.__compiled__ = {}, this.__tlds__ = rs, this.__tlds_replaced__ = !1, this.re = {}, bu(this);
}
te.prototype.add = function(u, t) {
  return this.__schemas__[u] = t, bu(this), this;
};
te.prototype.set = function(u) {
  return this.__opts__ = yt(this.__opts__, u), this;
};
te.prototype.test = function(u) {
  if (this.__text_cache__ = u, this.__index__ = -1, !u.length)
    return !1;
  let t, c, s, i, l, a, o, r, n;
  if (this.re.schema_test.test(u)) {
    for (o = this.re.schema_search, o.lastIndex = 0; (t = o.exec(u)) !== null; )
      if (i = this.testSchemaAt(u, t[2], o.lastIndex), i) {
        this.__schema__ = t[2], this.__index__ = t.index + t[1].length, this.__last_index__ = t.index + t[0].length + i;
        break;
      }
  }
  return this.__opts__.fuzzyLink && this.__compiled__["http:"] && (r = u.search(this.re.host_fuzzy_test), r >= 0 && (this.__index__ < 0 || r < this.__index__) && (c = u.match(this.__opts__.fuzzyIP ? this.re.link_fuzzy : this.re.link_no_ip_fuzzy)) !== null && (l = c.index + c[1].length, (this.__index__ < 0 || l < this.__index__) && (this.__schema__ = "", this.__index__ = l, this.__last_index__ = c.index + c[0].length))), this.__opts__.fuzzyEmail && this.__compiled__["mailto:"] && (n = u.indexOf("@"), n >= 0 && (s = u.match(this.re.email_fuzzy)) !== null && (l = s.index + s[1].length, a = s.index + s[0].length, (this.__index__ < 0 || l < this.__index__ || l === this.__index__ && a > this.__last_index__) && (this.__schema__ = "mailto:", this.__index__ = l, this.__last_index__ = a))), this.__index__ >= 0;
};
te.prototype.pretest = function(u) {
  return this.re.pretest.test(u);
};
te.prototype.testSchemaAt = function(u, t, c) {
  return this.__compiled__[t.toLowerCase()] ? this.__compiled__[t.toLowerCase()].validate(u, c, this) : 0;
};
te.prototype.match = function(u) {
  const t = [];
  let c = 0;
  this.__index__ >= 0 && this.__text_cache__ === u && (t.push(wt(this, c)), c = this.__last_index__);
  let s = c ? u.slice(c) : u;
  for (; this.test(s); )
    t.push(wt(this, c)), s = s.slice(this.__last_index__), c += this.__last_index__;
  return t.length ? t : null;
};
te.prototype.matchAtStart = function(u) {
  if (this.__text_cache__ = u, this.__index__ = -1, !u.length) return null;
  const t = this.re.schema_at_start.exec(u);
  if (!t) return null;
  const c = this.testSchemaAt(u, t[2], t[0].length);
  return c ? (this.__schema__ = t[2], this.__index__ = t.index + t[1].length, this.__last_index__ = t.index + t[0].length + c, wt(this, 0)) : null;
};
te.prototype.tlds = function(u, t) {
  return u = Array.isArray(u) ? u : [u], t ? (this.__tlds__ = this.__tlds__.concat(u).sort().filter(function(c, s, i) {
    return c !== i[s - 1];
  }).reverse(), bu(this), this) : (this.__tlds__ = u.slice(), this.__tlds_replaced__ = !0, bu(this), this);
};
te.prototype.normalize = function(u) {
  u.schema || (u.url = "http://" + u.url), u.schema === "mailto:" && !/^mailto:/i.test(u.url) && (u.url = "mailto:" + u.url);
};
te.prototype.onCompile = function() {
};
const Me = 2147483647, de = 36, Ft = 1, Je = 26, ss = 38, cs = 700, Ur = 72, Kr = 128, Yr = "-", os = /^xn--/, ls = /[^\0-\x7F]/, fs = /[\x2E\u3002\uFF0E\uFF61]/g, ds = {
  overflow: "Overflow: input needs wider integers to process",
  "not-basic": "Illegal input >= 0x80 (not a basic code point)",
  "invalid-input": "Invalid input"
}, Nu = de - Ft, Ae = Math.floor, Ou = String.fromCharCode;
function Ce(e) {
  throw new RangeError(ds[e]);
}
function As(e, u) {
  const t = [];
  let c = e.length;
  for (; c--; )
    t[c] = u(e[c]);
  return t;
}
function jr(e, u) {
  const t = e.split("@");
  let c = "";
  t.length > 1 && (c = t[0] + "@", e = t[1]), e = e.replace(fs, ".");
  const s = e.split("."), i = As(s, u).join(".");
  return c + i;
}
function Jr(e) {
  const u = [];
  let t = 0;
  const c = e.length;
  for (; t < c; ) {
    const s = e.charCodeAt(t++);
    if (s >= 55296 && s <= 56319 && t < c) {
      const i = e.charCodeAt(t++);
      (i & 64512) == 56320 ? u.push(((s & 1023) << 10) + (i & 1023) + 65536) : (u.push(s), t--);
    } else
      u.push(s);
  }
  return u;
}
const hs = (e) => String.fromCodePoint(...e), bs = function(e) {
  return e >= 48 && e < 58 ? 26 + (e - 48) : e >= 65 && e < 91 ? e - 65 : e >= 97 && e < 123 ? e - 97 : de;
}, n0 = function(e, u) {
  return e + 22 + 75 * (e < 26) - ((u != 0) << 5);
}, Zr = function(e, u, t) {
  let c = 0;
  for (e = t ? Ae(e / cs) : e >> 1, e += Ae(e / u); e > Nu * Je >> 1; c += de)
    e = Ae(e / Nu);
  return Ae(c + (Nu + 1) * e / (e + ss));
}, Vr = function(e) {
  const u = [], t = e.length;
  let c = 0, s = Kr, i = Ur, l = e.lastIndexOf(Yr);
  l < 0 && (l = 0);
  for (let a = 0; a < l; ++a)
    e.charCodeAt(a) >= 128 && Ce("not-basic"), u.push(e.charCodeAt(a));
  for (let a = l > 0 ? l + 1 : 0; a < t; ) {
    const o = c;
    for (let n = 1, f = de; ; f += de) {
      a >= t && Ce("invalid-input");
      const d = bs(e.charCodeAt(a++));
      d >= de && Ce("invalid-input"), d > Ae((Me - c) / n) && Ce("overflow"), c += d * n;
      const A = f <= i ? Ft : f >= i + Je ? Je : f - i;
      if (d < A)
        break;
      const h = de - A;
      n > Ae(Me / h) && Ce("overflow"), n *= h;
    }
    const r = u.length + 1;
    i = Zr(c - o, r, o == 0), Ae(c / r) > Me - s && Ce("overflow"), s += Ae(c / r), c %= r, u.splice(c++, 0, s);
  }
  return String.fromCodePoint(...u);
}, zr = function(e) {
  const u = [];
  e = Jr(e);
  const t = e.length;
  let c = Kr, s = 0, i = Ur;
  for (const o of e)
    o < 128 && u.push(Ou(o));
  const l = u.length;
  let a = l;
  for (l && u.push(Yr); a < t; ) {
    let o = Me;
    for (const n of e)
      n >= c && n < o && (o = n);
    const r = a + 1;
    o - c > Ae((Me - s) / r) && Ce("overflow"), s += (o - c) * r, c = o;
    for (const n of e)
      if (n < c && ++s > Me && Ce("overflow"), n === c) {
        let f = s;
        for (let d = de; ; d += de) {
          const A = d <= i ? Ft : d >= i + Je ? Je : d - i;
          if (f < A)
            break;
          const h = f - A, w = de - A;
          u.push(
            Ou(n0(A + h % w, 0))
          ), f = Ae(h / w);
        }
        u.push(Ou(n0(f, 0))), i = Zr(s, r, a === l), s = 0, ++a;
      }
    ++s, ++c;
  }
  return u.join("");
}, ps = function(e) {
  return jr(e, function(u) {
    return os.test(u) ? Vr(u.slice(4).toLowerCase()) : u;
  });
}, gs = function(e) {
  return jr(e, function(u) {
    return ls.test(u) ? "xn--" + zr(u) : u;
  });
}, Xr = {
  /**
   * A string representing the current Punycode.js version number.
   * @memberOf punycode
   * @type String
   */
  version: "2.3.1",
  /**
   * An object of methods to convert from JavaScript's internal character
   * representation (UCS-2) to Unicode code points, and back.
   * @see <https://mathiasbynens.be/notes/javascript-encoding>
   * @memberOf punycode
   * @type Object
   */
  ucs2: {
    decode: Jr,
    encode: hs
  },
  decode: Vr,
  encode: zr,
  toASCII: gs,
  toUnicode: ps
}, ms = {
  options: {
    // Enable HTML tags in source
    html: !1,
    // Use '/' to close single tags (<br />)
    xhtmlOut: !1,
    // Convert '\n' in paragraphs into <br>
    breaks: !1,
    // CSS language prefix for fenced blocks
    langPrefix: "language-",
    // autoconvert URL-like texts to links
    linkify: !1,
    // Enable some language-neutral replacements + quotes beautification
    typographer: !1,
    // Double + single quotes replacement pairs, when typographer enabled,
    // and smartquotes on. Could be either a String or an Array.
    //
    // For example, you can use '«»„“' for Russian, '„“‚‘' for German,
    // and ['«\xA0', '\xA0»', '‹\xA0', '\xA0›'] for French (including nbsp).
    quotes: "“”‘’",
    /* “”‘’ */
    // Highlighter function. Should return escaped HTML,
    // or '' if the source string is not changed and should be escaped externaly.
    // If result starts with <pre... internal wrapper is skipped.
    //
    // function (/*str, lang*/) { return ''; }
    //
    highlight: null,
    // Internal protection, recursion limit
    maxNesting: 100
  },
  components: {
    core: {},
    block: {},
    inline: {}
  }
}, xs = {
  options: {
    // Enable HTML tags in source
    html: !1,
    // Use '/' to close single tags (<br />)
    xhtmlOut: !1,
    // Convert '\n' in paragraphs into <br>
    breaks: !1,
    // CSS language prefix for fenced blocks
    langPrefix: "language-",
    // autoconvert URL-like texts to links
    linkify: !1,
    // Enable some language-neutral replacements + quotes beautification
    typographer: !1,
    // Double + single quotes replacement pairs, when typographer enabled,
    // and smartquotes on. Could be either a String or an Array.
    //
    // For example, you can use '«»„“' for Russian, '„“‚‘' for German,
    // and ['«\xA0', '\xA0»', '‹\xA0', '\xA0›'] for French (including nbsp).
    quotes: "“”‘’",
    /* “”‘’ */
    // Highlighter function. Should return escaped HTML,
    // or '' if the source string is not changed and should be escaped externaly.
    // If result starts with <pre... internal wrapper is skipped.
    //
    // function (/*str, lang*/) { return ''; }
    //
    highlight: null,
    // Internal protection, recursion limit
    maxNesting: 20
  },
  components: {
    core: {
      rules: [
        "normalize",
        "block",
        "inline",
        "text_join"
      ]
    },
    block: {
      rules: [
        "paragraph"
      ]
    },
    inline: {
      rules: [
        "text"
      ],
      rules2: [
        "balance_pairs",
        "fragments_join"
      ]
    }
  }
}, ys = {
  options: {
    // Enable HTML tags in source
    html: !0,
    // Use '/' to close single tags (<br />)
    xhtmlOut: !0,
    // Convert '\n' in paragraphs into <br>
    breaks: !1,
    // CSS language prefix for fenced blocks
    langPrefix: "language-",
    // autoconvert URL-like texts to links
    linkify: !1,
    // Enable some language-neutral replacements + quotes beautification
    typographer: !1,
    // Double + single quotes replacement pairs, when typographer enabled,
    // and smartquotes on. Could be either a String or an Array.
    //
    // For example, you can use '«»„“' for Russian, '„“‚‘' for German,
    // and ['«\xA0', '\xA0»', '‹\xA0', '\xA0›'] for French (including nbsp).
    quotes: "“”‘’",
    /* “”‘’ */
    // Highlighter function. Should return escaped HTML,
    // or '' if the source string is not changed and should be escaped externaly.
    // If result starts with <pre... internal wrapper is skipped.
    //
    // function (/*str, lang*/) { return ''; }
    //
    highlight: null,
    // Internal protection, recursion limit
    maxNesting: 20
  },
  components: {
    core: {
      rules: [
        "normalize",
        "block",
        "inline",
        "text_join"
      ]
    },
    block: {
      rules: [
        "blockquote",
        "code",
        "fence",
        "heading",
        "hr",
        "html_block",
        "lheading",
        "list",
        "reference",
        "paragraph"
      ]
    },
    inline: {
      rules: [
        "autolink",
        "backticks",
        "emphasis",
        "entity",
        "escape",
        "html_inline",
        "image",
        "link",
        "newline",
        "text"
      ],
      rules2: [
        "balance_pairs",
        "emphasis",
        "fragments_join"
      ]
    }
  }
}, ws = {
  default: ms,
  zero: xs,
  commonmark: ys
}, Cs = /^(vbscript|javascript|file|data):/, vs = /^data:image\/(gif|png|jpeg|webp);/;
function Es(e) {
  const u = e.trim().toLowerCase();
  return Cs.test(u) ? vs.test(u) : !0;
}
const $r = ["http:", "https:", "mailto:"];
function Ds(e) {
  const u = Et(e, !0);
  if (u.hostname && (!u.protocol || $r.indexOf(u.protocol) >= 0))
    try {
      u.hostname = Xr.toASCII(u.hostname);
    } catch {
    }
  return Ze(vt(u));
}
function Is(e) {
  const u = Et(e, !0);
  if (u.hostname && (!u.protocol || $r.indexOf(u.protocol) >= 0))
    try {
      u.hostname = Xr.toUnicode(u.hostname);
    } catch {
    }
  return Qe(vt(u), Qe.defaultChars + "%");
}
function re(e, u) {
  if (!(this instanceof re))
    return new re(e, u);
  u || It(e) || (u = e || {}, e = "default"), this.inline = new ze(), this.block = new mu(), this.core = new kt(), this.renderer = new Pe(), this.linkify = new te(), this.validateLink = Es, this.normalizeLink = Ds, this.normalizeLinkText = Is, this.utils = kn, this.helpers = pu({}, Rn), this.options = {}, this.configure(e), u && this.set(u);
}
re.prototype.set = function(e) {
  return pu(this.options, e), this;
};
re.prototype.configure = function(e) {
  const u = this;
  if (It(e)) {
    const t = e;
    if (e = ws[t], !e)
      throw new Error('Wrong `markdown-it` preset "' + t + '", check name');
  }
  if (!e)
    throw new Error("Wrong `markdown-it` preset, can't be empty");
  return e.options && u.set(e.options), e.components && Object.keys(e.components).forEach(function(t) {
    e.components[t].rules && u[t].ruler.enableOnly(e.components[t].rules), e.components[t].rules2 && u[t].ruler2.enableOnly(e.components[t].rules2);
  }), this;
};
re.prototype.enable = function(e, u) {
  let t = [];
  Array.isArray(e) || (e = [e]), ["core", "block", "inline"].forEach(function(s) {
    t = t.concat(this[s].ruler.enable(e, !0));
  }, this), t = t.concat(this.inline.ruler2.enable(e, !0));
  const c = e.filter(function(s) {
    return t.indexOf(s) < 0;
  });
  if (c.length && !u)
    throw new Error("MarkdownIt. Failed to enable unknown rule(s): " + c);
  return this;
};
re.prototype.disable = function(e, u) {
  let t = [];
  Array.isArray(e) || (e = [e]), ["core", "block", "inline"].forEach(function(s) {
    t = t.concat(this[s].ruler.disable(e, !0));
  }, this), t = t.concat(this.inline.ruler2.disable(e, !0));
  const c = e.filter(function(s) {
    return t.indexOf(s) < 0;
  });
  if (c.length && !u)
    throw new Error("MarkdownIt. Failed to disable unknown rule(s): " + c);
  return this;
};
re.prototype.use = function(e) {
  const u = [this].concat(Array.prototype.slice.call(arguments, 1));
  return e.apply(e, u), this;
};
re.prototype.parse = function(e, u) {
  if (typeof e != "string")
    throw new Error("Input data should be a String");
  const t = new this.core.State(e, this, u);
  return this.core.process(t), t.tokens;
};
re.prototype.render = function(e, u) {
  return u = u || {}, this.renderer.render(this.parse(e, u), this.options, u);
};
re.prototype.parseInline = function(e, u) {
  const t = new this.core.State(e, this, u);
  return t.inlineMode = !0, this.core.process(t), t.tokens;
};
re.prototype.renderInline = function(e, u) {
  return u = u || {}, this.renderer.render(this.parseInline(e, u), this.options, u);
};
function _s(e) {
  return e && e.__esModule && Object.prototype.hasOwnProperty.call(e, "default") ? e.default : e;
}
function ks(e) {
  if (Object.prototype.hasOwnProperty.call(e, "__esModule")) return e;
  var u = e.default;
  if (typeof u == "function") {
    var t = function c() {
      return this instanceof c ? Reflect.construct(u, arguments, this.constructor) : u.apply(this, arguments);
    };
    t.prototype = u.prototype;
  } else t = {};
  return Object.defineProperty(t, "__esModule", { value: !0 }), Object.keys(e).forEach(function(c) {
    var s = Object.getOwnPropertyDescriptor(e, c);
    Object.defineProperty(t, c, s.get ? s : {
      enumerable: !0,
      get: function() {
        return e[c];
      }
    });
  }), t;
}
var ne = {}, ae = {}, Oe = {}, Mu = {}, Qu = {}, a0;
function s0() {
  return a0 || (a0 = 1, (function(e) {
    var u;
    Object.defineProperty(e, "__esModule", { value: !0 }), e.fromCodePoint = void 0, e.replaceCodePoint = c, e.decodeCodePoint = s;
    const t = /* @__PURE__ */ new Map([
      [0, 65533],
      // C1 Unicode control character reference replacements
      [128, 8364],
      [130, 8218],
      [131, 402],
      [132, 8222],
      [133, 8230],
      [134, 8224],
      [135, 8225],
      [136, 710],
      [137, 8240],
      [138, 352],
      [139, 8249],
      [140, 338],
      [142, 381],
      [145, 8216],
      [146, 8217],
      [147, 8220],
      [148, 8221],
      [149, 8226],
      [150, 8211],
      [151, 8212],
      [152, 732],
      [153, 8482],
      [154, 353],
      [155, 8250],
      [156, 339],
      [158, 382],
      [159, 376]
    ]);
    e.fromCodePoint = // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition, n/no-unsupported-features/es-builtins
    (u = String.fromCodePoint) !== null && u !== void 0 ? u : ((i) => {
      let l = "";
      return i > 65535 && (i -= 65536, l += String.fromCharCode(i >>> 10 & 1023 | 55296), i = 56320 | i & 1023), l += String.fromCharCode(i), l;
    });
    function c(i) {
      var l;
      return i >= 55296 && i <= 57343 || i > 1114111 ? 65533 : (l = t.get(i)) !== null && l !== void 0 ? l : i;
    }
    function s(i) {
      return (0, e.fromCodePoint)(c(i));
    }
  })(Qu)), Qu;
}
var He = {}, iu = {}, c0;
function ei() {
  if (c0) return iu;
  c0 = 1, Object.defineProperty(iu, "__esModule", { value: !0 }), iu.decodeBase64 = e;
  function e(u) {
    const t = (
      // eslint-disable-next-line n/no-unsupported-features/node-builtins
      typeof atob == "function" ? (
        // Browser (and Node >=16)
        // eslint-disable-next-line n/no-unsupported-features/node-builtins
        atob(u)
      ) : (
        // Older Node versions (<16)
        // eslint-disable-next-line n/no-unsupported-features/node-builtins
        typeof Buffer.from == "function" ? (
          // eslint-disable-next-line n/no-unsupported-features/node-builtins
          Buffer.from(u, "base64").toString("binary")
        ) : (
          // eslint-disable-next-line unicorn/no-new-buffer, n/no-deprecated-api
          new Buffer(u, "base64").toString("binary")
        )
      )
    ), c = t.length & -2, s = new Uint16Array(c / 2);
    for (let i = 0, l = 0; i < c; i += 2) {
      const a = t.charCodeAt(i), o = t.charCodeAt(i + 1);
      s[l++] = a | o << 8;
    }
    return s;
  }
  return iu;
}
var o0;
function l0() {
  if (o0) return He;
  o0 = 1, Object.defineProperty(He, "__esModule", { value: !0 }), He.htmlDecodeTree = void 0;
  const e = ei();
  return He.htmlDecodeTree = (0, e.decodeBase64)("QR08ALkAAgH6AYsDNQR2BO0EPgXZBQEGLAbdBxMISQrvCmQLfQurDKQNLw4fD4YPpA+6D/IPAAAAAAAAAAAAAAAAKhBMEY8TmxUWF2EYLBkxGuAa3RsJHDscWR8YIC8jSCSIJcMl6ie3Ku8rEC0CLjoupS7kLgAIRU1hYmNmZ2xtbm9wcnN0dVQAWgBeAGUAaQBzAHcAfgCBAIQAhwCSAJoAoACsALMAbABpAGcAO4DGAMZAUAA7gCYAJkBjAHUAdABlADuAwQDBQHIiZXZlAAJhAAFpeW0AcgByAGMAO4DCAMJAEGRyAADgNdgE3XIAYQB2AGUAO4DAAMBA8CFoYZFj4SFjcgBhZAAAoFMqAAFncIsAjgBvAG4ABGFmAADgNdg43fAlbHlGdW5jdGlvbgCgYSBpAG4AZwA7gMUAxUAAAWNzpACoAHIAAOA12Jzc6SFnbgCgVCJpAGwAZABlADuAwwDDQG0AbAA7gMQAxEAABGFjZWZvcnN1xQDYANoA7QDxAPYA+QD8AAABY3LJAM8AayNzbGFzaAAAoBYidgHTANUAAKDnKmUAZAAAoAYjeQARZIABY3J0AOAA5QDrAGEidXNlAACgNSLuI291bGxpcwCgLCFhAJJjcgAA4DXYBd1wAGYAAOA12Dnd5SF2ZdhiYwDyAOoAbSJwZXEAAKBOIgAHSE9hY2RlZmhpbG9yc3UXARoBHwE6AVIBVQFiAWQBZgGCAakB6QHtAfIBYwB5ACdkUABZADuAqQCpQIABY3B5ACUBKAE1AfUhdGUGYWmg0iJ0KGFsRGlmZmVyZW50aWFsRAAAoEUhbCJleXMAAKAtIQACYWVpb0EBRAFKAU0B8iFvbgxhZABpAGwAO4DHAMdAcgBjAAhhbiJpbnQAAKAwIm8AdAAKYQABZG5ZAV0BaSJsbGEAuGB0I2VyRG90ALdg8gA5AWkAp2NyImNsZQAAAkRNUFRwAXQBeQF9AW8AdAAAoJkiaSJudXMAAKCWIuwhdXMAoJUiaSJtZXMAAKCXIm8AAAFjc4cBlAFrKndpc2VDb250b3VySW50ZWdyYWwAAKAyImUjQ3VybHkAAAFEUZwBpAFvJXVibGVRdW90ZQAAoB0gdSJvdGUAAKAZIAACbG5wdbABtgHNAdgBbwBuAGWgNyIAoHQqgAFnaXQAvAHBAcUB8iJ1ZW50AKBhIm4AdAAAoC8i7yV1ckludGVncmFsAKAuIgABZnLRAdMBAKACIe8iZHVjdACgECJuLnRlckNsb2Nrd2lzZUNvbnRvdXJJbnRlZ3JhbAAAoDMi7yFzcwCgLypjAHIAAOA12J7ccABDoNMiYQBwAACgTSKABURKU1phY2VmaW9zAAsCEgIVAhgCGwIsAjQCOQI9AnMCfwNvoEUh9CJyYWhkAKARKWMAeQACZGMAeQAFZGMAeQAPZIABZ3JzACECJQIoAuchZXIAoCEgcgAAoKEhaAB2AACg5CoAAWF5MAIzAvIhb24OYRRkbAB0oAciYQCUY3IAAOA12AfdAAFhZkECawIAAWNtRQJnAvIjaXRpY2FsAAJBREdUUAJUAl8CYwJjInV0ZQC0YG8AdAFZAloC2WJiJGxlQWN1dGUA3WJyImF2ZQBgYGkibGRlANxi7yFuZACgxCJmJWVyZW50aWFsRAAAoEYhcAR9AgAAAAAAAIECjgIAABoDZgAA4DXYO91EoagAhQKJAm8AdAAAoNwgcSJ1YWwAAKBQIuIhbGUAA0NETFJVVpkCqAK1Au8C/wIRA28AbgB0AG8AdQByAEkAbgB0AGUAZwByAGEA7ADEAW8AdAKvAgAAAACwAqhgbiNBcnJvdwAAoNMhAAFlb7kC0AJmAHQAgAFBUlQAwQLGAs0CciJyb3cAAKDQIekkZ2h0QXJyb3cAoNQhZQDlACsCbgBnAAABTFLWAugC5SFmdAABQVLcAuECciJyb3cAAKD4J+kkZ2h0QXJyb3cAoPon6SRnaHRBcnJvdwCg+SdpImdodAAAAUFU9gL7AnIicm93AACg0iFlAGUAAKCoInAAQQIGAwAAAAALA3Iicm93AACg0SFvJHduQXJyb3cAAKDVIWUlcnRpY2FsQmFyAACgJSJuAAADQUJMUlRhJAM2AzoDWgNxA3oDciJyb3cAAKGTIUJVLAMwA2EAcgAAoBMpcCNBcnJvdwAAoPUhciJldmUAEWPlIWZ00gJDAwAASwMAAFIDaSVnaHRWZWN0b3IAAKBQKWUkZVZlY3RvcgAAoF4p5SJjdG9yQqC9IWEAcgAAoFYpaSJnaHQA1AFiAwAAaQNlJGVWZWN0b3IAAKBfKeUiY3RvckKgwSFhAHIAAKBXKWUAZQBBoKQiciJyb3cAAKCnIXIAcgBvAPcAtAIAAWN0gwOHA3IA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YwAAoN8i4SFycnCgtiEAoD0pgKIqImJjZG9zACsVMBU6FT4VQRVyImNhcAAAoEgqAAFhdTQVNxVwAACgRipwAACgSipvAHQAAKCNInIAAKBFKgDgKiIA/gACYWxydksVURVuFXMVcgByAG2gtyEAoDwpeQCAAWV2dwBYFWUVaRVxAHACXxUAAAAAYxVyAGUA4wAXFXUA4wAZFWUAZQAAoM4iZSJkZ2UAAKDPImUAbgA7gKQApEBlI2Fycm93AAABbHJ7FX8V5SFmdACgtiFpImdodAAAoLchZQDkAG0VAAFjaYsVkRVvAG4AaQBuAPQAkwFuAHQAAKAxImwiY3R5AACgLSOACUFIYWJjZGVmaGlqbG9yc3R1d3oAuBW7Fb8V1RXgFegV+RUKFhUWHxZUFlcWZRbFFtsW7xb7FgUXChdyAPIAtAJhAHIAAKBlKQACZ2xyc8YVyhXOFdAV5yFlcgCgICDlIXRoAKA4IfIA9QxoAHagECAAoKMiawHZFd4VYSJyb3cAAKAPKWEA4wBfAgABYXnkFecV8iFvbg9hNGQAoUYhYW/tFfQVAAFnciEC8RVyAACgyiF0InNlcQAAoHcqgAFnbG0A/xUCFgUWO4CwALBAdABhALRjcCJ0eXYAAKCxKQABaXIOFhIW8yFodACgfykA4DXYId1hAHIAAAFschsWHRYAoMMhAKDCIYACYWVnc3YAKBauAjYWOhY+Fm0AAKHEIm9zLhY0Fm4AZABzoMQi9SFpdACgZiZhIm1tYQDdY2kAbgAAoPIiAKH3AGlvQxZRFmQAZQAAgfcAO29KFksW90BuI3RpbWVzAACgxyJuAPgAUBZjAHkAUmRjAG8CXhYAAAAAYhZyAG4AAKAeI28AcAAAoA0jgAJscHR1dwBuFnEWdRaSFp4W7CFhciRgZgAA4DXYVd0AotkCZW1wc30WhBaJFo0WcQBkoFAibwB0AACgUSJpIm51cwAAoDgi7CF1cwCgFCLxInVhcmUAoKEiYgBsAGUAYgBhAHIAdwBlAGQAZwDlANcAbgCAAWFkaAClFqoWtBZyAHIAbwD3APUMbwB3AG4AYQByAHIAbwB3APMA8xVhI3Jwb29uAAABbHK8FsAWZQBmAPQAHBZpAGcAaAD0AB4WYgHJFs8WawBhAHIAbwD3AJILbwLUFgAAAADYFnIAbgAAoB8jbwBwAACgDCOAAWNvdADhFukW7BYAAXJ55RboFgDgNdi53FVkbAAAoPYp8iFvaxFhAAFkcvMW9xZvAHQAAKDxImkA5qC/JVsSAAFhaP8WAhdyAPIANQNhAPIA1wvhIm5nbGUAoKYpAAFjaQ4XEBd5AF9k5yJyYXJyAKD/JwAJRGFjZGVmZ2xtbm9wcXJzdHV4MRc4F0YXWxcyBF4XaRd5F40XrBe0F78X2RcVGCEYLRg1GEAYAAFEbzUXgRZvAPQA+BUAAWNzPBdCF3UAdABlADuA6QDpQPQhZXIAoG4qAAJhaW95TRdQF1YXWhfyIW9uG2FyAGOgViI7gOoA6kDsIW9uAKBVIk1kbwB0ABdhAAFEcmIXZhdvAHQAAKBSIgDgNdgi3XKhmipuF3QXYQB2AGUAO4DoAOhAZKCWKm8AdAAAoJgqgKGZKmlscwCAF4UXhxfuInRlcnMAoOcjAKATIWSglSpvAHQAAKCXKoABYXBzAJMXlheiF2MAcgATYXQAeQBzogUinxcAAAAAoRdlAHQAAKAFInAAMaADIDMBqRerFwCgBCAAoAUgAAFnc7AXsRdLYXAAAKACIAABZ3C4F7sXbwBuABlhZgAA4DXYVt2AAWFscwDFF8sXzxdyAHOg1SJsAACg4yl1AHMAAKBxKmkAAKG1A2x21RfYF28AbgC1Y/VjAAJjc3V24BfoF/0XEBgAAWlv5BdWF3IAYwAAoFYiaQLuFwAAAADwF+0ADQThIW50AAFnbPUX+Rd0AHIAAKCWKuUhc3MAoJUqgAFhZWkAAxgGGAoYbABzAD1gcwB0AACgXyJ2AESgYSJEAACgeCrwImFyc2wAoOUpAAFEYRkYHRhvAHQAAKBTInIAcgAAoHEpgAFjZGkAJxgqGO0XcgAAoC8hbwD0AIwCAAFhaDEYMhi3YzuA8ADwQAABbXI5GD0YbAA7gOsA60BvAACgrCCAAWNpcABGGEgYSxhsACFgcwD0ACwEAAFlb08YVxhjAHQAYQB0AGkAbwDuABoEbgBlAG4AdABpAGEAbADlADME4Ql1GAAAgRgAAIMYiBgAAAAAoRilGAAAqhgAALsYvhjRGAAA1xgnGWwAbABpAG4AZwBkAG8AdABzAGUA8QBlF3kARGRtImFsZQAAoEAmgAFpbHIAjRiRGJ0Y7CFpZwCgA/tpApcYAAAAAJoYZwAAoAD7aQBnAACgBPsA4DXYI93sIWlnAKAB++whaWcA4GYAagCAAWFsdACvGLIYthh0AACgbSZpAGcAAKAC+24AcwAAoLElbwBmAJJh8AHCGAAAxhhmAADgNdhX3QABYWvJGMwYbADsAGsEdqDUIgCg2SphI3J0aW50AACgDSoAAWFv2hgiGQABY3PeGB8ZsQPnGP0YBRkSGRUZAAAdGbID7xjyGPQY9xj5GAAA+xg7gL0AvUAAoFMhO4C8ALxAAKBVIQCgWSEAoFshswEBGQAAAxkAoFQhAKBWIbQCCxkOGQAAAAAQGTuAvgC+QACgVyEAoFwhNQAAoFghtgEZGQAAGxkAoFohAKBdITgAAKBeIWwAAKBEIHcAbgAAoCIjYwByAADgNdi73IAIRWFiY2RlZmdpamxub3JzdHYARhlKGVoZXhlmGWkZkhmWGZkZnRmgGa0ZxhnLGc8Z4BkjGmygZyIAoIwqgAFjbXAAUBlTGVgZ9SF0ZfVhbQBhAOSgswM6FgCghipyImV2ZQAfYQABaXliGWUZcgBjAB1hM2RvAHQAIWGAoWUibHFzAMYEcBl6GfGhZSLOBAAAdhlsAGEAbgD0AN8EgKF+KmNkbACBGYQZjBljAACgqSpvAHQAb6CAKmyggioAoIQqZeDbIgD+cwAAoJQqcgAA4DXYJN3noGsirATtIWVsAKA3IWMAeQBTZIChdyJFYWoApxmpGasZAKCSKgCgpSoAoKQqAAJFYWVztBm2Gb0ZwhkAoGkicABwoIoq8iFveACgiipxoIgq8aCIKrUZaQBtAACg5yJwAGYAAOA12FjdYQB2AOUAYwIAAWNp0xnWGXIAAKAKIW0AAKFzImVs3BneGQCgjioAoJAqAIM+ADtjZGxxco0E6xn0GfgZ/BkBGgABY2nvGfEZAKCnKnIAAKB6Km8AdAAAoNci0CFhcgCglSl1ImVzdAAAoHwqgAJhZGVscwAKGvQZFhrVBCAa8AEPGgAAFBpwAHIAbwD4AFkZcgAAoHgpcQAAAWxxxAQbGmwAZQBzAPMASRlpAO0A5AQAAWVuJxouGnIjdG5lcXEAAOBpIgD+xQAsGgAFQWFiY2Vma29zeUAaQxpmGmoabRqDGocalhrCGtMacgDyAMwCAAJpbG1yShpOGlAaVBpyAHMA8ABxD2YAvWBpAGwA9AASBQABZHJYGlsaYwB5AEpkAKGUIWN3YBpkGmkAcgAAoEgpAKCtIWEAcgAAoA8h6SFyYyVhgAFhbHIAcxp7Gn8a8iF0c3WgZSZpAHQAAKBlJuwhaXAAoCYg4yFvbgCguSJyAADgNdgl3XMAAAFld4wakRphInJvdwAAoCUpYSJyb3cAAKAmKYACYW1vcHIAnxqjGqcauhq+GnIAcgAAoP8h9CFodACgOyJrAAABbHKsGrMaZSRmdGFycm93AACgqSHpJGdodGFycm93AKCqIWYAAOA12Fnd4iFhcgCgFSCAAWNsdADIGswa0BpyAADgNdi93GEAcwDoAGka8iFvaydhAAFicNca2xr1IWxsAKBDIOghZW4AoBAg4Qr2GgAA/RoAAAgbExsaGwAAIRs7GwAAAAA+G2IbmRuVG6sbAACyG80b0htjAHUAdABlADuA7QDtQAChYyBpeQEbBhtyAGMAO4DuAO5AOGQAAWN4CxsNG3kANWRjAGwAO4ChAKFAAAFmcssCFhsA4DXYJt1yAGEAdgBlADuA7ADsQIChSCFpbm8AJxsyGzYbAAFpbisbLxtuAHQAAKAMKnQAAKAtIuYhaW4AoNwpdABhAACgKSHsIWlnM2GAAWFvcABDG1sbXhuAAWNndABJG0sbWRtyACthgAFlbHAAcQVRG1UbaQBuAOUAyAVhAHIA9AByBWgAMWFmAACgtyJlAGQAtWEAoggiY2ZvdGkbbRt1G3kb4SFyZQCgBSFpAG4AdKAeImkAZQAAoN0pZABvAPQAWxsAoisiY2VscIEbhRuPG5QbYQBsAACguiIAAWdyiRuNG2UAcgDzACMQ4wCCG2EicmhrAACgFyryIW9kAKA8KgACY2dwdJ8boRukG6gbeQBRZG8AbgAvYWYAAOA12FrdYQC5Y3UAZQBzAHQAO4C/AL9AAAFjabUbuRtyAADgNdi+3G4AAKIIIkVkc3bCG8QbyBvQAwCg+SJvAHQAAKD1Inag9CIAoPMiaaBiIOwhZGUpYesB1hsAANkbYwB5AFZkbAA7gO8A70AAA2NmbW9zdeYb7hvyG/Ub+hsFHAABaXnqG+0bcgBjADVhOWRyAADgNdgn3eEhdGg3YnAAZgAA4DXYW93jAf8bAAADHHIAAOA12L/c8iFjeVhk6yFjeVRkAARhY2ZnaGpvcxUcGhwiHCYcKhwtHDAcNRzwIXBhdqC6A/BjAAFleR4cIRzkIWls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ZmdobG1vcHJzdHV3CiwNLBEsHSwnLDEsQCxLLFIsYix6LIQsjyzLLOgs7Sz/LAotcgDyAAkDYQByAACgYykAAWNyFSwbLHUAdABlADuA+gD6QPIACQ1yAOMBIywAACUseQBeZHYAZQBtYQABaXkrLDAscgBjADuA+wD7QENkgAFhYmgANyw6LD0scgDyANEO7CFhY3FhYQDyAOAOAAFpckQsSCzzIWh0AKB+KQDgNdgy3XIAYQB2AGUAO4D5APlAYQFWLF8scgAAAWxyWixcLACgvyEAoL4hbABrAACggCUAAWN0Zix2LG8CbCwAAAAAcyxyAG4AZaAcI3IAAKAcI28AcAAAoA8jcgBpAACg+CUAAWFsfiyBLGMAcgBrYTuAqACoQAABZ3CILIssbwBuAHNhZgAA4DXYZt0AA2FkaGxzdZksniynLLgsuyzFLHIAcgBvAPcACQ1vAHcAbgBhAHIAcgBvAPcA2A5hI3Jwb29uAAABbHKvLLMsZQBmAPQAWyxpAGcAaAD0AF0sdQDzAKYOaQAAocUDaGzBLMIs0mNvAG4AxWPwI2Fycm93cwCgyCGAAWNpdADRLOEs5CxvAtcsAAAAAN4scgBuAGWgHSNyAACgHSNvAHAAAKAOI24AZwBvYXIAaQAAoPklYwByAADgNdjK3IABZGlyAPMs9yz6LG8AdAAAoPAi7CFkZWlhaQBmoLUlAKC0JQABYW0DLQYtcgDyAMosbAA7gPwA/EDhIm5nbGUAoKcpgAdBQkRhY2RlZmxub3Byc3oAJy0qLTAtNC2bLZ0toS2/LcMtxy3TLdgt3C3gLfwtcgDyABADYQByAHag6CoAoOkqYQBzAOgA/gIAAW5yOC08LechcnQAoJwpgANla25wcnN0AJkpSC1NLVQtXi1iLYItYQBwAHAA4QAaHG8AdABoAGkAbgDnAKEXgAFoaXIAoSmzJFotbwBwAPQAdCVooJUh7wD4JgABaXVmLWotZwBtAOEAuygAAWJwbi14LXMjZXRuZXEAceCKIgD+AODLKgD+cyNldG5lcQBx4IsiAP4A4MwqAP4AAWhyhi2KLWUAdADhABIraSNhbmdsZQAAAWxyki2WLeUhZnQAoLIiaSJnaHQAAKCzInkAMmThIXNoAKCiIoABZWxyAKcttC24LWKiKCKuLQAAAACyLWEAcgAAoLsicQAAoFoi7CFpcACg7iIAAWJ0vC1eD2EA8gBfD3IAAOA12DPddAByAOkAlS1zAHUAAAFicM0t0C0A4IIi0iAA4IMi0iBwAGYAAOA12GfdcgBvAPAAWQt0AHIA6QCaLQABY3XkLegtcgAA4DXYy9wAAWJw7C30LW4AAAFFZXUt8S0A4IoiAP5uAAABRWV/LfktAOCLIgD+6SJnemFnAKCaKYADY2Vmb3BycwANLhAuJS4pLiMuLi40LukhcmN1YQABZGkULiEuAAFiZxguHC5hAHIAAKBfKmUAcaAnIgCgWSLlIXJwAKAYIXIAAOA12DTdcABmAADgNdho3WWgQCJhAHQA6ABqD2MAcgAA4DXYzNzjCuQRUC4AAFQuAABYLmIuAAAAAGMubS5wLnQuAAAAAIguki4AAJouJxIqEnQAcgDpAB0ScgAA4DXYNd0AAUFhWy5eLnIA8gDnAnIA8gCTB75jAAFBYWYuaS5yAPIA4AJyAPIAjAdhAPAAeh5pAHMAAKD7IoABZHB0APgReS6DLgABZmx9LoAuAOA12GnddQDzAP8RaQBtAOUABBIAAUFhiy6OLnIA8gDuAnIA8gCaBwABY3GVLgoScgAA4DXYzdwAAXB0nS6hLmwAdQDzACUScgDpACASAARhY2VmaW9zdbEuvC7ELsguzC7PLtQu2S5jAAABdXm2LrsudABlADuA/QD9QE9kAAFpecAuwy5yAGMAd2FLZG4AO4ClAKVAcgAA4DXYNt1jAHkAV2RwAGYAAOA12GrdYwByAADgNdjO3AABY23dLt8ueQBOZGwAO4D/AP9AAAVhY2RlZmhpb3N38y73Lv8uAi8MLxAvEy8YLx0vIi9jInV0ZQB6YQABYXn7Lv4u8iFvbn5hN2RvAHQAfGEAAWV0Bi8KL3QAcgDmAB8QYQC2Y3IAAOA12DfdYwB5ADZk5yJyYXJyAKDdIXAAZgAA4DXYa91jAHIAAOA12M/cAAFqbiYvKC8AoA0gagAAoAwg"), He;
}
var We = {}, f0;
function d0() {
  if (f0) return We;
  f0 = 1, Object.defineProperty(We, "__esModule", { value: !0 }), We.xmlDecodeTree = void 0;
  const e = ei();
  return We.xmlDecodeTree = (0, e.decodeBase64)("AAJhZ2xxBwARABMAFQBtAg0AAAAAAA8AcAAmYG8AcwAnYHQAPmB0ADxg9SFvdCJg"), We;
}
var Ue = {}, A0;
function Bs() {
  if (A0) return Ue;
  A0 = 1, Object.defineProperty(Ue, "__esModule", { value: !0 }), Ue.BinTrieFlags = void 0;
  var e;
  return (function(u) {
    u[u.VALUE_LENGTH = 49152] = "VALUE_LENGTH", u[u.FLAG13 = 8192] = "FLAG13", u[u.BRANCH_LENGTH = 8064] = "BRANCH_LENGTH", u[u.JUMP_TABLE = 127] = "JUMP_TABLE";
  })(e || (Ue.BinTrieFlags = e = {})), Ue;
}
var h0;
function ui() {
  return h0 || (h0 = 1, (function(e) {
    Object.defineProperty(e, "__esModule", { value: !0 }), e.xmlDecodeTree = e.htmlDecodeTree = e.replaceCodePoint = e.fromCodePoint = e.decodeCodePoint = e.EntityDecoder = e.DecodingMode = void 0, e.determineBranch = w, e.decodeHTML = m, e.decodeHTMLAttribute = g, e.decodeHTMLStrict = x, e.decodeXML = p;
    const u = s0(), t = l0(), c = d0(), s = Bs();
    var i;
    (function(D) {
      D[D.NUM = 35] = "NUM", D[D.SEMI = 59] = "SEMI", D[D.EQUALS = 61] = "EQUALS", D[D.ZERO = 48] = "ZERO", D[D.NINE = 57] = "NINE", D[D.LOWER_A = 97] = "LOWER_A", D[D.LOWER_F = 102] = "LOWER_F", D[D.LOWER_X = 120] = "LOWER_X", D[D.LOWER_Z = 122] = "LOWER_Z", D[D.UPPER_A = 65] = "UPPER_A", D[D.UPPER_F = 70] = "UPPER_F", D[D.UPPER_Z = 90] = "UPPER_Z";
    })(i || (i = {}));
    const l = 32;
    function a(D) {
      return D >= i.ZERO && D <= i.NINE;
    }
    function o(D) {
      return D >= i.UPPER_A && D <= i.UPPER_F || D >= i.LOWER_A && D <= i.LOWER_F;
    }
    function r(D) {
      return D >= i.UPPER_A && D <= i.UPPER_Z || D >= i.LOWER_A && D <= i.LOWER_Z || a(D);
    }
    function n(D) {
      return D === i.EQUALS || r(D);
    }
    var f;
    (function(D) {
      D[D.EntityStart = 0] = "EntityStart", D[D.NumericStart = 1] = "NumericStart", D[D.NumericDecimal = 2] = "NumericDecimal", D[D.NumericHex = 3] = "NumericHex", D[D.NamedEntity = 4] = "NamedEntity";
    })(f || (f = {}));
    var d;
    (function(D) {
      D[D.Legacy = 0] = "Legacy", D[D.Strict = 1] = "Strict", D[D.Attribute = 2] = "Attribute";
    })(d || (e.DecodingMode = d = {}));
    class A {
      constructor(_, E, k) {
        this.decodeTree = _, this.emitCodePoint = E, this.errors = k, this.state = f.EntityStart, this.consumed = 1, this.result = 0, this.treeIndex = 0, this.excess = 1, this.decodeMode = d.Strict, this.runConsumed = 0;
      }
      /** Resets the instance to make it reusable. */
      startEntity(_) {
        this.decodeMode = _, this.state = f.EntityStart, this.result = 0, this.treeIndex = 0, this.excess = 1, this.consumed = 1, this.runConsumed = 0;
      }
      /**
       * Write an entity to the decoder. This can be called multiple times with partial entities.
       * If the entity is incomplete, the decoder will return -1.
       *
       * Mirrors the implementation of `getDecoder`, but with the ability to stop decoding if the
       * entity is incomplete, and resume when the next string is written.
       *
       * @param input The string containing the entity (or a continuation of the entity).
       * @param offset The offset at which the entity begins. Should be 0 if this is not the first call.
       * @returns The number of characters that were consumed, or -1 if the entity is incomplete.
       */
      write(_, E) {
        switch (this.state) {
          case f.EntityStart:
            return _.charCodeAt(E) === i.NUM ? (this.state = f.NumericStart, this.consumed += 1, this.stateNumericStart(_, E + 1)) : (this.state = f.NamedEntity, this.stateNamedEntity(_, E));
          case f.NumericStart:
            return this.stateNumericStart(_, E);
          case f.NumericDecimal:
            return this.stateNumericDecimal(_, E);
          case f.NumericHex:
            return this.stateNumericHex(_, E);
          case f.NamedEntity:
            return this.stateNamedEntity(_, E);
        }
      }
      /**
       * Switches between the numeric decimal and hexadecimal states.
       *
       * Equivalent to the `Numeric character reference state` in the HTML spec.
       *
       * @param input The string containing the entity (or a continuation of the entity).
       * @param offset The current offset.
       * @returns The number of characters that were consumed, or -1 if the entity is incomplete.
       */
      stateNumericStart(_, E) {
        return E >= _.length ? -1 : (_.charCodeAt(E) | l) === i.LOWER_X ? (this.state = f.NumericHex, this.consumed += 1, this.stateNumericHex(_, E + 1)) : (this.state = f.NumericDecimal, this.stateNumericDecimal(_, E));
      }
      /**
       * Parses a hexadecimal numeric entity.
       *
       * Equivalent to the `Hexademical character reference state` in the HTML spec.
       *
       * @param input The string containing the entity (or a continuation of the entity).
       * @param offset The current offset.
       * @returns The number of characters that were consumed, or -1 if the entity is incomplete.
       */
      stateNumericHex(_, E) {
        for (; E < _.length; ) {
          const k = _.charCodeAt(E);
          if (a(k) || o(k)) {
            const F = k <= i.NINE ? k - i.ZERO : (k | l) - i.LOWER_A + 10;
            this.result = this.result * 16 + F, this.consumed++, E++;
          } else
            return this.emitNumericEntity(k, 3);
        }
        return -1;
      }
      /**
       * Parses a decimal numeric entity.
       *
       * Equivalent to the `Decimal character reference state` in the HTML spec.
       *
       * @param input The string containing the entity (or a continuation of the entity).
       * @param offset The current offset.
       * @returns The number of characters that were consumed, or -1 if the entity is incomplete.
       */
      stateNumericDecimal(_, E) {
        for (; E < _.length; ) {
          const k = _.charCodeAt(E);
          if (a(k))
            this.result = this.result * 10 + (k - i.ZERO), this.consumed++, E++;
          else
            return this.emitNumericEntity(k, 2);
        }
        return -1;
      }
      /**
       * Validate and emit a numeric entity.
       *
       * Implements the logic from the `Hexademical character reference start
       * state` and `Numeric character reference end state` in the HTML spec.
       *
       * @param lastCp The last code point of the entity. Used to see if the
       *               entity was terminated with a semicolon.
       * @param expectedLength The minimum number of characters that should be
       *                       consumed. Used to validate that at least one digit
       *                       was consumed.
       * @returns The number of characters that were consumed.
       */
      emitNumericEntity(_, E) {
        var k;
        if (this.consumed <= E)
          return (k = this.errors) === null || k === void 0 || k.absenceOfDigitsInNumericCharacterReference(this.consumed), 0;
        if (_ === i.SEMI)
          this.consumed += 1;
        else if (this.decodeMode === d.Strict)
          return 0;
        return this.emitCodePoint((0, u.replaceCodePoint)(this.result), this.consumed), this.errors && (_ !== i.SEMI && this.errors.missingSemicolonAfterCharacterReference(), this.errors.validateNumericCharacterReference(this.result)), this.consumed;
      }
      /**
       * Parses a named entity.
       *
       * Equivalent to the `Named character reference state` in the HTML spec.
       *
       * @param input The string containing the entity (or a continuation of the entity).
       * @param offset The current offset.
       * @returns The number of characters that were consumed, or -1 if the entity is incomplete.
       */
      stateNamedEntity(_, E) {
        const { decodeTree: k } = this;
        let F = k[this.treeIndex], T = (F & s.BinTrieFlags.VALUE_LENGTH) >> 14;
        for (; E < _.length; ) {
          if (T === 0 && (F & s.BinTrieFlags.FLAG13) !== 0) {
            const O = (F & s.BinTrieFlags.BRANCH_LENGTH) >> 7;
            if (this.runConsumed === 0) {
              const Q = F & s.BinTrieFlags.JUMP_TABLE;
              if (_.charCodeAt(E) !== Q)
                return this.result === 0 ? 0 : this.emitNotTerminatedNamedEntity();
              E++, this.excess++, this.runConsumed++;
            }
            for (; this.runConsumed < O; ) {
              if (E >= _.length)
                return -1;
              const Q = this.runConsumed - 1, L = k[this.treeIndex + 1 + (Q >> 1)], K = Q % 2 === 0 ? L & 255 : L >> 8 & 255;
              if (_.charCodeAt(E) !== K)
                return this.runConsumed = 0, this.result === 0 ? 0 : this.emitNotTerminatedNamedEntity();
              E++, this.excess++, this.runConsumed++;
            }
            this.runConsumed = 0, this.treeIndex += 1 + (O >> 1), F = k[this.treeIndex], T = (F & s.BinTrieFlags.VALUE_LENGTH) >> 14;
          }
          if (E >= _.length)
            break;
          const B = _.charCodeAt(E);
          if (B === i.SEMI && T !== 0 && (F & s.BinTrieFlags.FLAG13) !== 0)
            return this.emitNamedEntityData(this.treeIndex, T, this.consumed + this.excess);
          if (this.treeIndex = w(k, F, this.treeIndex + Math.max(1, T), B), this.treeIndex < 0)
            return this.result === 0 || // If we are parsing an attribute
            this.decodeMode === d.Attribute && // We shouldn't have consumed any characters after the entity,
            (T === 0 || // And there should be no invalid characters.
            n(B)) ? 0 : this.emitNotTerminatedNamedEntity();
          if (F = k[this.treeIndex], T = (F & s.BinTrieFlags.VALUE_LENGTH) >> 14, T !== 0) {
            if (B === i.SEMI)
              return this.emitNamedEntityData(this.treeIndex, T, this.consumed + this.excess);
            this.decodeMode !== d.Strict && (F & s.BinTrieFlags.FLAG13) === 0 && (this.result = this.treeIndex, this.consumed += this.excess, this.excess = 0);
          }
          E++, this.excess++;
        }
        return -1;
      }
      /**
       * Emit a named entity that was not terminated with a semicolon.
       *
       * @returns The number of characters consumed.
       */
      emitNotTerminatedNamedEntity() {
        var _;
        const { result: E, decodeTree: k } = this, F = (k[E] & s.BinTrieFlags.VALUE_LENGTH) >> 14;
        return this.emitNamedEntityData(E, F, this.consumed), (_ = this.errors) === null || _ === void 0 || _.missingSemicolonAfterCharacterReference(), this.consumed;
      }
      /**
       * Emit a named entity.
       *
       * @param result The index of the entity in the decode tree.
       * @param valueLength The number of bytes in the entity.
       * @param consumed The number of characters consumed.
       *
       * @returns The number of characters consumed.
       */
      emitNamedEntityData(_, E, k) {
        const { decodeTree: F } = this;
        return this.emitCodePoint(E === 1 ? F[_] & ~(s.BinTrieFlags.VALUE_LENGTH | s.BinTrieFlags.FLAG13) : F[_ + 1], k), E === 3 && this.emitCodePoint(F[_ + 2], k), k;
      }
      /**
       * Signal to the parser that the end of the input was reached.
       *
       * Remaining data will be emitted and relevant errors will be produced.
       *
       * @returns The number of characters consumed.
       */
      end() {
        var _;
        switch (this.state) {
          case f.NamedEntity:
            return this.result !== 0 && (this.decodeMode !== d.Attribute || this.result === this.treeIndex) ? this.emitNotTerminatedNamedEntity() : 0;
          // Otherwise, emit a numeric entity if we have one.
          case f.NumericDecimal:
            return this.emitNumericEntity(0, 2);
          case f.NumericHex:
            return this.emitNumericEntity(0, 3);
          case f.NumericStart:
            return (_ = this.errors) === null || _ === void 0 || _.absenceOfDigitsInNumericCharacterReference(this.consumed), 0;
          case f.EntityStart:
            return 0;
        }
      }
    }
    e.EntityDecoder = A;
    function h(D) {
      let _ = "";
      const E = new A(D, (k) => _ += (0, u.fromCodePoint)(k));
      return function(F, T) {
        let B = 0, O = 0;
        for (; (O = F.indexOf("&", O)) >= 0; ) {
          _ += F.slice(B, O), E.startEntity(T);
          const L = E.write(
            F,
            // Skip the "&"
            O + 1
          );
          if (L < 0) {
            B = O + E.end();
            break;
          }
          B = O + L, O = L === 0 ? B + 1 : B;
        }
        const Q = _ + F.slice(B);
        return _ = "", Q;
      };
    }
    function w(D, _, E, k) {
      const F = (_ & s.BinTrieFlags.BRANCH_LENGTH) >> 7, T = _ & s.BinTrieFlags.JUMP_TABLE;
      if (F === 0)
        return T !== 0 && k === T ? E : -1;
      if (T) {
        const L = k - T;
        return L < 0 || L >= F ? -1 : D[E + L] - 1;
      }
      const B = F + 1 >> 1;
      let O = 0, Q = F - 1;
      for (; O <= Q; ) {
        const L = O + Q >>> 1, K = L >> 1, ee = D[E + K] >> (L & 1) * 8 & 255;
        if (ee < k)
          O = L + 1;
        else if (ee > k)
          Q = L - 1;
        else
          return D[E + B + L];
      }
      return -1;
    }
    const C = /* @__PURE__ */ h(t.htmlDecodeTree), b = /* @__PURE__ */ h(c.xmlDecodeTree);
    function m(D, _ = d.Legacy) {
      return C(D, _);
    }
    function g(D) {
      return C(D, d.Attribute);
    }
    function x(D) {
      return C(D, d.Strict);
    }
    function p(D) {
      return b(D, d.Strict);
    }
    var y = s0();
    Object.defineProperty(e, "decodeCodePoint", { enumerable: !0, get: function() {
      return y.decodeCodePoint;
    } }), Object.defineProperty(e, "fromCodePoint", { enumerable: !0, get: function() {
      return y.fromCodePoint;
    } }), Object.defineProperty(e, "replaceCodePoint", { enumerable: !0, get: function() {
      return y.replaceCodePoint;
    } });
    var v = l0();
    Object.defineProperty(e, "htmlDecodeTree", { enumerable: !0, get: function() {
      return v.htmlDecodeTree;
    } });
    var I = d0();
    Object.defineProperty(e, "xmlDecodeTree", { enumerable: !0, get: function() {
      return I.xmlDecodeTree;
    } });
  })(Mu)), Mu;
}
var b0;
function ti() {
  if (b0) return Oe;
  b0 = 1, Object.defineProperty(Oe, "__esModule", { value: !0 }), Oe.QuoteType = void 0;
  const e = /* @__PURE__ */ ui();
  var u;
  (function(r) {
    r[r.Tab = 9] = "Tab", r[r.NewLine = 10] = "NewLine", r[r.FormFeed = 12] = "FormFeed", r[r.CarriageReturn = 13] = "CarriageReturn", r[r.Space = 32] = "Space", r[r.ExclamationMark = 33] = "ExclamationMark", r[r.Number = 35] = "Number", r[r.Amp = 38] = "Amp", r[r.SingleQuote = 39] = "SingleQuote", r[r.DoubleQuote = 34] = "DoubleQuote", r[r.Dash = 45] = "Dash", r[r.Slash = 47] = "Slash", r[r.Zero = 48] = "Zero", r[r.Nine = 57] = "Nine", r[r.Semi = 59] = "Semi", r[r.Lt = 60] = "Lt", r[r.Eq = 61] = "Eq", r[r.Gt = 62] = "Gt", r[r.Questionmark = 63] = "Questionmark", r[r.UpperA = 65] = "UpperA", r[r.LowerA = 97] = "LowerA", r[r.UpperF = 70] = "UpperF", r[r.LowerF = 102] = "LowerF", r[r.UpperZ = 90] = "UpperZ", r[r.LowerZ = 122] = "LowerZ", r[r.LowerX = 120] = "LowerX", r[r.OpeningSquareBracket = 91] = "OpeningSquareBracket";
  })(u || (u = {}));
  var t;
  (function(r) {
    r[r.Text = 1] = "Text", r[r.BeforeTagName = 2] = "BeforeTagName", r[r.InTagName = 3] = "InTagName", r[r.InSelfClosingTag = 4] = "InSelfClosingTag", r[r.BeforeClosingTagName = 5] = "BeforeClosingTagName", r[r.InClosingTagName = 6] = "InClosingTagName", r[r.AfterClosingTagName = 7] = "AfterClosingTagName", r[r.BeforeAttributeName = 8] = "BeforeAttributeName", r[r.InAttributeName = 9] = "InAttributeName", r[r.AfterAttributeName = 10] = "AfterAttributeName", r[r.BeforeAttributeValue = 11] = "BeforeAttributeValue", r[r.InAttributeValueDq = 12] = "InAttributeValueDq", r[r.InAttributeValueSq = 13] = "InAttributeValueSq", r[r.InAttributeValueNq = 14] = "InAttributeValueNq", r[r.BeforeDeclaration = 15] = "BeforeDeclaration", r[r.InDeclaration = 16] = "InDeclaration", r[r.InProcessingInstruction = 17] = "InProcessingInstruction", r[r.BeforeComment = 18] = "BeforeComment", r[r.CDATASequence = 19] = "CDATASequence", r[r.InSpecialComment = 20] = "InSpecialComment", r[r.InCommentLike = 21] = "InCommentLike", r[r.BeforeSpecialS = 22] = "BeforeSpecialS", r[r.BeforeSpecialT = 23] = "BeforeSpecialT", r[r.SpecialStartSequence = 24] = "SpecialStartSequence", r[r.InSpecialTag = 25] = "InSpecialTag", r[r.InEntity = 26] = "InEntity";
  })(t || (t = {}));
  function c(r) {
    return r === u.Space || r === u.NewLine || r === u.Tab || r === u.FormFeed || r === u.CarriageReturn;
  }
  function s(r) {
    return r === u.Slash || r === u.Gt || c(r);
  }
  function i(r) {
    return r >= u.LowerA && r <= u.LowerZ || r >= u.UpperA && r <= u.UpperZ;
  }
  var l;
  (function(r) {
    r[r.NoValue = 0] = "NoValue", r[r.Unquoted = 1] = "Unquoted", r[r.Single = 2] = "Single", r[r.Double = 3] = "Double";
  })(l || (Oe.QuoteType = l = {}));
  const a = {
    Cdata: new Uint8Array([67, 68, 65, 84, 65, 91]),
    // CDATA[
    CdataEnd: new Uint8Array([93, 93, 62]),
    // ]]>
    CommentEnd: new Uint8Array([45, 45, 62]),
    // `-->`
    ScriptEnd: new Uint8Array([60, 47, 115, 99, 114, 105, 112, 116]),
    // `<\/script`
    StyleEnd: new Uint8Array([60, 47, 115, 116, 121, 108, 101]),
    // `</style`
    TitleEnd: new Uint8Array([60, 47, 116, 105, 116, 108, 101]),
    // `</title`
    TextareaEnd: new Uint8Array([
      60,
      47,
      116,
      101,
      120,
      116,
      97,
      114,
      101,
      97
    ]),
    // `</textarea`
    XmpEnd: new Uint8Array([60, 47, 120, 109, 112])
    // `</xmp`
  };
  let o = class {
    constructor({ xmlMode: n = !1, decodeEntities: f = !0 }, d) {
      this.cbs = d, this.state = t.Text, this.buffer = "", this.sectionStart = 0, this.index = 0, this.entityStart = 0, this.baseState = t.Text, this.isSpecial = !1, this.running = !0, this.offset = 0, this.currentSequence = void 0, this.sequenceIndex = 0, this.xmlMode = n, this.decodeEntities = f, this.entityDecoder = new e.EntityDecoder(n ? e.xmlDecodeTree : e.htmlDecodeTree, (A, h) => this.emitCodePoint(A, h));
    }
    reset() {
      this.state = t.Text, this.buffer = "", this.sectionStart = 0, this.index = 0, this.baseState = t.Text, this.currentSequence = void 0, this.running = !0, this.offset = 0;
    }
    write(n) {
      this.offset += this.buffer.length, this.buffer = n, this.parse();
    }
    end() {
      this.running && this.finish();
    }
    pause() {
      this.running = !1;
    }
    resume() {
      this.running = !0, this.index < this.buffer.length + this.offset && this.parse();
    }
    stateText(n) {
      n === u.Lt || !this.decodeEntities && this.fastForwardTo(u.Lt) ? (this.index > this.sectionStart && this.cbs.ontext(this.sectionStart, this.index), this.state = t.BeforeTagName, this.sectionStart = this.index) : this.decodeEntities && n === u.Amp && this.startEntity();
    }
    stateSpecialStartSequence(n) {
      const f = this.sequenceIndex === this.currentSequence.length;
      if (!(f ? (
        // If we are at the end of the sequence, make sure the tag name has ended
        s(n)
      ) : (
        // Otherwise, do a case-insensitive comparison
        (n | 32) === this.currentSequence[this.sequenceIndex]
      )))
        this.isSpecial = !1;
      else if (!f) {
        this.sequenceIndex++;
        return;
      }
      this.sequenceIndex = 0, this.state = t.InTagName, this.stateInTagName(n);
    }
    /** Look for an end tag. For <title> tags, also decode entities. */
    stateInSpecialTag(n) {
      if (this.sequenceIndex === this.currentSequence.length) {
        if (n === u.Gt || c(n)) {
          const f = this.index - this.currentSequence.length;
          if (this.sectionStart < f) {
            const d = this.index;
            this.index = f, this.cbs.ontext(this.sectionStart, f), this.index = d;
          }
          this.isSpecial = !1, this.sectionStart = f + 2, this.stateInClosingTagName(n);
          return;
        }
        this.sequenceIndex = 0;
      }
      (n | 32) === this.currentSequence[this.sequenceIndex] ? this.sequenceIndex += 1 : this.sequenceIndex === 0 ? this.currentSequence === a.TitleEnd ? this.decodeEntities && n === u.Amp && this.startEntity() : this.fastForwardTo(u.Lt) && (this.sequenceIndex = 1) : this.sequenceIndex = +(n === u.Lt);
    }
    stateCDATASequence(n) {
      n === a.Cdata[this.sequenceIndex] ? ++this.sequenceIndex === a.Cdata.length && (this.state = t.InCommentLike, this.currentSequence = a.CdataEnd, this.sequenceIndex = 0, this.sectionStart = this.index + 1) : (this.sequenceIndex = 0, this.state = t.InDeclaration, this.stateInDeclaration(n));
    }
    /**
     * When we wait for one specific character, we can speed things up
     * by skipping through the buffer until we find it.
     *
     * @returns Whether the character was found.
     */
    fastForwardTo(n) {
      for (; ++this.index < this.buffer.length + this.offset; )
        if (this.buffer.charCodeAt(this.index - this.offset) === n)
          return !0;
      return this.index = this.buffer.length + this.offset - 1, !1;
    }
    /**
     * Comments and CDATA end with `-->` and `]]>`.
     *
     * Their common qualities are:
     * - Their end sequences have a distinct character they start with.
     * - That character is then repeated, so we have to check multiple repeats.
     * - All characters but the start character of the sequence can be skipped.
     */
    stateInCommentLike(n) {
      n === this.currentSequence[this.sequenceIndex] ? ++this.sequenceIndex === this.currentSequence.length && (this.currentSequence === a.CdataEnd ? this.cbs.oncdata(this.sectionStart, this.index, 2) : this.cbs.oncomment(this.sectionStart, this.index, 2), this.sequenceIndex = 0, this.sectionStart = this.index + 1, this.state = t.Text) : this.sequenceIndex === 0 ? this.fastForwardTo(this.currentSequence[0]) && (this.sequenceIndex = 1) : n !== this.currentSequence[this.sequenceIndex - 1] && (this.sequenceIndex = 0);
    }
    /**
     * HTML only allows ASCII alpha characters (a-z and A-Z) at the beginning of a tag name.
     *
     * XML allows a lot more characters here (@see https://www.w3.org/TR/REC-xml/#NT-NameStartChar).
     * We allow anything that wouldn't end the tag.
     */
    isTagStartChar(n) {
      return this.xmlMode ? !s(n) : i(n);
    }
    startSpecial(n, f) {
      this.isSpecial = !0, this.currentSequence = n, this.sequenceIndex = f, this.state = t.SpecialStartSequence;
    }
    stateBeforeTagName(n) {
      if (n === u.ExclamationMark)
        this.state = t.BeforeDeclaration, this.sectionStart = this.index + 1;
      else if (n === u.Questionmark)
        this.state = t.InProcessingInstruction, this.sectionStart = this.index + 1;
      else if (this.isTagStartChar(n)) {
        const f = n | 32;
        this.sectionStart = this.index, this.xmlMode ? this.state = t.InTagName : f === a.ScriptEnd[2] ? this.state = t.BeforeSpecialS : f === a.TitleEnd[2] || f === a.XmpEnd[2] ? this.state = t.BeforeSpecialT : this.state = t.InTagName;
      } else n === u.Slash ? this.state = t.BeforeClosingTagName : (this.state = t.Text, this.stateText(n));
    }
    stateInTagName(n) {
      s(n) && (this.cbs.onopentagname(this.sectionStart, this.index), this.sectionStart = -1, this.state = t.BeforeAttributeName, this.stateBeforeAttributeName(n));
    }
    stateBeforeClosingTagName(n) {
      c(n) || (n === u.Gt ? this.state = t.Text : (this.state = this.isTagStartChar(n) ? t.InClosingTagName : t.InSpecialComment, this.sectionStart = this.index));
    }
    stateInClosingTagName(n) {
      (n === u.Gt || c(n)) && (this.cbs.onclosetag(this.sectionStart, this.index), this.sectionStart = -1, this.state = t.AfterClosingTagName, this.stateAfterClosingTagName(n));
    }
    stateAfterClosingTagName(n) {
      (n === u.Gt || this.fastForwardTo(u.Gt)) && (this.state = t.Text, this.sectionStart = this.index + 1);
    }
    stateBeforeAttributeName(n) {
      n === u.Gt ? (this.cbs.onopentagend(this.index), this.isSpecial ? (this.state = t.InSpecialTag, this.sequenceIndex = 0) : this.state = t.Text, this.sectionStart = this.index + 1) : n === u.Slash ? this.state = t.InSelfClosingTag : c(n) || (this.state = t.InAttributeName, this.sectionStart = this.index);
    }
    stateInSelfClosingTag(n) {
      n === u.Gt ? (this.cbs.onselfclosingtag(this.index), this.state = t.Text, this.sectionStart = this.index + 1, this.isSpecial = !1) : c(n) || (this.state = t.BeforeAttributeName, this.stateBeforeAttributeName(n));
    }
    stateInAttributeName(n) {
      (n === u.Eq || s(n)) && (this.cbs.onattribname(this.sectionStart, this.index), this.sectionStart = this.index, this.state = t.AfterAttributeName, this.stateAfterAttributeName(n));
    }
    stateAfterAttributeName(n) {
      n === u.Eq ? this.state = t.BeforeAttributeValue : n === u.Slash || n === u.Gt ? (this.cbs.onattribend(l.NoValue, this.sectionStart), this.sectionStart = -1, this.state = t.BeforeAttributeName, this.stateBeforeAttributeName(n)) : c(n) || (this.cbs.onattribend(l.NoValue, this.sectionStart), this.state = t.InAttributeName, this.sectionStart = this.index);
    }
    stateBeforeAttributeValue(n) {
      n === u.DoubleQuote ? (this.state = t.InAttributeValueDq, this.sectionStart = this.index + 1) : n === u.SingleQuote ? (this.state = t.InAttributeValueSq, this.sectionStart = this.index + 1) : c(n) || (this.sectionStart = this.index, this.state = t.InAttributeValueNq, this.stateInAttributeValueNoQuotes(n));
    }
    handleInAttributeValue(n, f) {
      n === f || !this.decodeEntities && this.fastForwardTo(f) ? (this.cbs.onattribdata(this.sectionStart, this.index), this.sectionStart = -1, this.cbs.onattribend(f === u.DoubleQuote ? l.Double : l.Single, this.index + 1), this.state = t.BeforeAttributeName) : this.decodeEntities && n === u.Amp && this.startEntity();
    }
    stateInAttributeValueDoubleQuotes(n) {
      this.handleInAttributeValue(n, u.DoubleQuote);
    }
    stateInAttributeValueSingleQuotes(n) {
      this.handleInAttributeValue(n, u.SingleQuote);
    }
    stateInAttributeValueNoQuotes(n) {
      c(n) || n === u.Gt ? (this.cbs.onattribdata(this.sectionStart, this.index), this.sectionStart = -1, this.cbs.onattribend(l.Unquoted, this.index), this.state = t.BeforeAttributeName, this.stateBeforeAttributeName(n)) : this.decodeEntities && n === u.Amp && this.startEntity();
    }
    stateBeforeDeclaration(n) {
      n === u.OpeningSquareBracket ? (this.state = t.CDATASequence, this.sequenceIndex = 0) : this.state = n === u.Dash ? t.BeforeComment : t.InDeclaration;
    }
    stateInDeclaration(n) {
      (n === u.Gt || this.fastForwardTo(u.Gt)) && (this.cbs.ondeclaration(this.sectionStart, this.index), this.state = t.Text, this.sectionStart = this.index + 1);
    }
    stateInProcessingInstruction(n) {
      (n === u.Gt || this.fastForwardTo(u.Gt)) && (this.cbs.onprocessinginstruction(this.sectionStart, this.index), this.state = t.Text, this.sectionStart = this.index + 1);
    }
    stateBeforeComment(n) {
      n === u.Dash ? (this.state = t.InCommentLike, this.currentSequence = a.CommentEnd, this.sequenceIndex = 2, this.sectionStart = this.index + 1) : this.state = t.InDeclaration;
    }
    stateInSpecialComment(n) {
      (n === u.Gt || this.fastForwardTo(u.Gt)) && (this.cbs.oncomment(this.sectionStart, this.index, 0), this.state = t.Text, this.sectionStart = this.index + 1);
    }
    stateBeforeSpecialS(n) {
      const f = n | 32;
      f === a.ScriptEnd[3] ? this.startSpecial(a.ScriptEnd, 4) : f === a.StyleEnd[3] ? this.startSpecial(a.StyleEnd, 4) : (this.state = t.InTagName, this.stateInTagName(n));
    }
    stateBeforeSpecialT(n) {
      switch (n | 32) {
        case a.TitleEnd[3]: {
          this.startSpecial(a.TitleEnd, 4);
          break;
        }
        case a.TextareaEnd[3]: {
          this.startSpecial(a.TextareaEnd, 4);
          break;
        }
        case a.XmpEnd[3]: {
          this.startSpecial(a.XmpEnd, 4);
          break;
        }
        default:
          this.state = t.InTagName, this.stateInTagName(n);
      }
    }
    startEntity() {
      this.baseState = this.state, this.state = t.InEntity, this.entityStart = this.index, this.entityDecoder.startEntity(this.xmlMode ? e.DecodingMode.Strict : this.baseState === t.Text || this.baseState === t.InSpecialTag ? e.DecodingMode.Legacy : e.DecodingMode.Attribute);
    }
    stateInEntity() {
      const n = this.index - this.offset, f = this.entityDecoder.write(this.buffer, n);
      if (f >= 0)
        this.state = this.baseState, f === 0 && (this.index -= 1);
      else {
        if (n < this.buffer.length && this.buffer.charCodeAt(n) === u.Amp) {
          this.state = this.baseState, this.index -= 1;
          return;
        }
        this.index = this.offset + this.buffer.length - 1;
      }
    }
    /**
     * Remove data that has already been consumed from the buffer.
     */
    cleanup() {
      this.running && this.sectionStart !== this.index && (this.state === t.Text || this.state === t.InSpecialTag && this.sequenceIndex === 0 ? (this.cbs.ontext(this.sectionStart, this.index), this.sectionStart = this.index) : (this.state === t.InAttributeValueDq || this.state === t.InAttributeValueSq || this.state === t.InAttributeValueNq) && (this.cbs.onattribdata(this.sectionStart, this.index), this.sectionStart = this.index));
    }
    shouldContinue() {
      return this.index < this.buffer.length + this.offset && this.running;
    }
    /**
     * Iterates through the buffer, calling the function corresponding to the current state.
     *
     * States that are more likely to be hit are higher up, as a performance improvement.
     */
    parse() {
      for (; this.shouldContinue(); ) {
        const n = this.buffer.charCodeAt(this.index - this.offset);
        switch (this.state) {
          case t.Text: {
            this.stateText(n);
            break;
          }
          case t.SpecialStartSequence: {
            this.stateSpecialStartSequence(n);
            break;
          }
          case t.InSpecialTag: {
            this.stateInSpecialTag(n);
            break;
          }
          case t.CDATASequence: {
            this.stateCDATASequence(n);
            break;
          }
          case t.InAttributeValueDq: {
            this.stateInAttributeValueDoubleQuotes(n);
            break;
          }
          case t.InAttributeName: {
            this.stateInAttributeName(n);
            break;
          }
          case t.InCommentLike: {
            this.stateInCommentLike(n);
            break;
          }
          case t.InSpecialComment: {
            this.stateInSpecialComment(n);
            break;
          }
          case t.BeforeAttributeName: {
            this.stateBeforeAttributeName(n);
            break;
          }
          case t.InTagName: {
            this.stateInTagName(n);
            break;
          }
          case t.InClosingTagName: {
            this.stateInClosingTagName(n);
            break;
          }
          case t.BeforeTagName: {
            this.stateBeforeTagName(n);
            break;
          }
          case t.AfterAttributeName: {
            this.stateAfterAttributeName(n);
            break;
          }
          case t.InAttributeValueSq: {
            this.stateInAttributeValueSingleQuotes(n);
            break;
          }
          case t.BeforeAttributeValue: {
            this.stateBeforeAttributeValue(n);
            break;
          }
          case t.BeforeClosingTagName: {
            this.stateBeforeClosingTagName(n);
            break;
          }
          case t.AfterClosingTagName: {
            this.stateAfterClosingTagName(n);
            break;
          }
          case t.BeforeSpecialS: {
            this.stateBeforeSpecialS(n);
            break;
          }
          case t.BeforeSpecialT: {
            this.stateBeforeSpecialT(n);
            break;
          }
          case t.InAttributeValueNq: {
            this.stateInAttributeValueNoQuotes(n);
            break;
          }
          case t.InSelfClosingTag: {
            this.stateInSelfClosingTag(n);
            break;
          }
          case t.InDeclaration: {
            this.stateInDeclaration(n);
            break;
          }
          case t.BeforeDeclaration: {
            this.stateBeforeDeclaration(n);
            break;
          }
          case t.BeforeComment: {
            this.stateBeforeComment(n);
            break;
          }
          case t.InProcessingInstruction: {
            this.stateInProcessingInstruction(n);
            break;
          }
          case t.InEntity: {
            this.stateInEntity();
            break;
          }
        }
        this.index++;
      }
      this.cleanup();
    }
    finish() {
      this.state === t.InEntity && (this.entityDecoder.end(), this.state = this.baseState), this.handleTrailingData(), this.cbs.onend();
    }
    /** Handle any trailing data. */
    handleTrailingData() {
      const n = this.buffer.length + this.offset;
      this.sectionStart >= n || (this.state === t.InCommentLike ? this.currentSequence === a.CdataEnd ? this.cbs.oncdata(this.sectionStart, n, 0) : this.cbs.oncomment(this.sectionStart, n, 0) : this.state === t.InTagName || this.state === t.BeforeAttributeName || this.state === t.BeforeAttributeValue || this.state === t.AfterAttributeName || this.state === t.InAttributeName || this.state === t.InAttributeValueSq || this.state === t.InAttributeValueDq || this.state === t.InAttributeValueNq || this.state === t.InClosingTagName || this.cbs.ontext(this.sectionStart, n));
    }
    emitCodePoint(n, f) {
      this.baseState !== t.Text && this.baseState !== t.InSpecialTag ? (this.sectionStart < this.entityStart && this.cbs.onattribdata(this.sectionStart, this.entityStart), this.sectionStart = this.entityStart + f, this.index = this.sectionStart - 1, this.cbs.onattribentity(n)) : (this.sectionStart < this.entityStart && this.cbs.ontext(this.sectionStart, this.entityStart), this.sectionStart = this.entityStart + f, this.index = this.sectionStart - 1, this.cbs.ontextentity(n, this.sectionStart));
    }
  };
  return Oe.default = o, Oe;
}
var p0;
function g0() {
  if (p0) return ae;
  p0 = 1;
  var e = ae && ae.__createBinding || (Object.create ? (function(C, b, m, g) {
    g === void 0 && (g = m);
    var x = Object.getOwnPropertyDescriptor(b, m);
    (!x || ("get" in x ? !b.__esModule : x.writable || x.configurable)) && (x = { enumerable: !0, get: function() {
      return b[m];
    } }), Object.defineProperty(C, g, x);
  }) : (function(C, b, m, g) {
    g === void 0 && (g = m), C[g] = b[m];
  })), u = ae && ae.__setModuleDefault || (Object.create ? (function(C, b) {
    Object.defineProperty(C, "default", { enumerable: !0, value: b });
  }) : function(C, b) {
    C.default = b;
  }), t = ae && ae.__importStar || /* @__PURE__ */ (function() {
    var C = function(b) {
      return C = Object.getOwnPropertyNames || function(m) {
        var g = [];
        for (var x in m) Object.prototype.hasOwnProperty.call(m, x) && (g[g.length] = x);
        return g;
      }, C(b);
    };
    return function(b) {
      if (b && b.__esModule) return b;
      var m = {};
      if (b != null) for (var g = C(b), x = 0; x < g.length; x++) g[x] !== "default" && e(m, b, g[x]);
      return u(m, b), m;
    };
  })();
  Object.defineProperty(ae, "__esModule", { value: !0 }), ae.Parser = void 0;
  const c = t(ti()), s = /* @__PURE__ */ ui(), i = /* @__PURE__ */ new Set([
    "input",
    "option",
    "optgroup",
    "select",
    "button",
    "datalist",
    "textarea"
  ]), l = /* @__PURE__ */ new Set(["p"]), a = /* @__PURE__ */ new Set(["thead", "tbody"]), o = /* @__PURE__ */ new Set(["dd", "dt"]), r = /* @__PURE__ */ new Set(["rt", "rp"]), n = /* @__PURE__ */ new Map([
    ["tr", /* @__PURE__ */ new Set(["tr", "th", "td"])],
    ["th", /* @__PURE__ */ new Set(["th"])],
    ["td", /* @__PURE__ */ new Set(["thead", "th", "td"])],
    ["body", /* @__PURE__ */ new Set(["head", "link", "script"])],
    ["li", /* @__PURE__ */ new Set(["li"])],
    ["p", l],
    ["h1", l],
    ["h2", l],
    ["h3", l],
    ["h4", l],
    ["h5", l],
    ["h6", l],
    ["select", i],
    ["input", i],
    ["output", i],
    ["button", i],
    ["datalist", i],
    ["textarea", i],
    ["option", /* @__PURE__ */ new Set(["option"])],
    ["optgroup", /* @__PURE__ */ new Set(["optgroup", "option"])],
    ["dd", o],
    ["dt", o],
    ["address", l],
    ["article", l],
    ["aside", l],
    ["blockquote", l],
    ["details", l],
    ["div", l],
    ["dl", l],
    ["fieldset", l],
    ["figcaption", l],
    ["figure", l],
    ["footer", l],
    ["form", l],
    ["header", l],
    ["hr", l],
    ["main", l],
    ["nav", l],
    ["ol", l],
    ["pre", l],
    ["section", l],
    ["table", l],
    ["ul", l],
    ["rt", r],
    ["rp", r],
    ["tbody", a],
    ["tfoot", a]
  ]), f = /* @__PURE__ */ new Set([
    "area",
    "base",
    "basefont",
    "br",
    "col",
    "command",
    "embed",
    "frame",
    "hr",
    "img",
    "input",
    "isindex",
    "keygen",
    "link",
    "meta",
    "param",
    "source",
    "track",
    "wbr"
  ]), d = /* @__PURE__ */ new Set(["math", "svg"]), A = /* @__PURE__ */ new Set([
    "mi",
    "mo",
    "mn",
    "ms",
    "mtext",
    "annotation-xml",
    "foreignobject",
    "desc",
    "title"
  ]), h = /\s|\//;
  let w = class {
    constructor(b, m = {}) {
      var g, x, p, y, v, I;
      this.options = m, this.startIndex = 0, this.endIndex = 0, this.openTagStart = 0, this.tagname = "", this.attribname = "", this.attribvalue = "", this.attribs = null, this.stack = [], this.buffers = [], this.bufferOffset = 0, this.writeIndex = 0, this.ended = !1, this.cbs = b ?? {}, this.htmlMode = !this.options.xmlMode, this.lowerCaseTagNames = (g = m.lowerCaseTags) !== null && g !== void 0 ? g : this.htmlMode, this.lowerCaseAttributeNames = (x = m.lowerCaseAttributeNames) !== null && x !== void 0 ? x : this.htmlMode, this.recognizeSelfClosing = (p = m.recognizeSelfClosing) !== null && p !== void 0 ? p : !this.htmlMode, this.tokenizer = new ((y = m.Tokenizer) !== null && y !== void 0 ? y : c.default)(this.options, this), this.foreignContext = [!this.htmlMode], (I = (v = this.cbs).onparserinit) === null || I === void 0 || I.call(v, this);
    }
    // Tokenizer event handlers
    /** @internal */
    ontext(b, m) {
      var g, x;
      const p = this.getSlice(b, m);
      this.endIndex = m - 1, (x = (g = this.cbs).ontext) === null || x === void 0 || x.call(g, p), this.startIndex = m;
    }
    /** @internal */
    ontextentity(b, m) {
      var g, x;
      this.endIndex = m - 1, (x = (g = this.cbs).ontext) === null || x === void 0 || x.call(g, (0, s.fromCodePoint)(b)), this.startIndex = m;
    }
    /**
     * Checks if the current tag is a void element. Override this if you want
     * to specify your own additional void elements.
     */
    isVoidElement(b) {
      return this.htmlMode && f.has(b);
    }
    /** @internal */
    onopentagname(b, m) {
      this.endIndex = m;
      let g = this.getSlice(b, m);
      this.lowerCaseTagNames && (g = g.toLowerCase()), this.emitOpenTag(g);
    }
    emitOpenTag(b) {
      var m, g, x, p;
      this.openTagStart = this.startIndex, this.tagname = b;
      const y = this.htmlMode && n.get(b);
      if (y)
        for (; this.stack.length > 0 && y.has(this.stack[0]); ) {
          const v = this.stack.shift();
          (g = (m = this.cbs).onclosetag) === null || g === void 0 || g.call(m, v, !0);
        }
      this.isVoidElement(b) || (this.stack.unshift(b), this.htmlMode && (d.has(b) ? this.foreignContext.unshift(!0) : A.has(b) && this.foreignContext.unshift(!1))), (p = (x = this.cbs).onopentagname) === null || p === void 0 || p.call(x, b), this.cbs.onopentag && (this.attribs = {});
    }
    endOpenTag(b) {
      var m, g;
      this.startIndex = this.openTagStart, this.attribs && ((g = (m = this.cbs).onopentag) === null || g === void 0 || g.call(m, this.tagname, this.attribs, b), this.attribs = null), this.cbs.onclosetag && this.isVoidElement(this.tagname) && this.cbs.onclosetag(this.tagname, !0), this.tagname = "";
    }
    /** @internal */
    onopentagend(b) {
      this.endIndex = b, this.endOpenTag(!1), this.startIndex = b + 1;
    }
    /** @internal */
    onclosetag(b, m) {
      var g, x, p, y, v, I, D, _;
      this.endIndex = m;
      let E = this.getSlice(b, m);
      if (this.lowerCaseTagNames && (E = E.toLowerCase()), this.htmlMode && (d.has(E) || A.has(E)) && this.foreignContext.shift(), this.isVoidElement(E))
        this.htmlMode && E === "br" && ((y = (p = this.cbs).onopentagname) === null || y === void 0 || y.call(p, "br"), (I = (v = this.cbs).onopentag) === null || I === void 0 || I.call(v, "br", {}, !0), (_ = (D = this.cbs).onclosetag) === null || _ === void 0 || _.call(D, "br", !1));
      else {
        const k = this.stack.indexOf(E);
        if (k !== -1)
          for (let F = 0; F <= k; F++) {
            const T = this.stack.shift();
            (x = (g = this.cbs).onclosetag) === null || x === void 0 || x.call(g, T, F !== k);
          }
        else this.htmlMode && E === "p" && (this.emitOpenTag("p"), this.closeCurrentTag(!0));
      }
      this.startIndex = m + 1;
    }
    /** @internal */
    onselfclosingtag(b) {
      this.endIndex = b, this.recognizeSelfClosing || this.foreignContext[0] ? (this.closeCurrentTag(!1), this.startIndex = b + 1) : this.onopentagend(b);
    }
    closeCurrentTag(b) {
      var m, g;
      const x = this.tagname;
      this.endOpenTag(b), this.stack[0] === x && ((g = (m = this.cbs).onclosetag) === null || g === void 0 || g.call(m, x, !b), this.stack.shift());
    }
    /** @internal */
    onattribname(b, m) {
      this.startIndex = b;
      const g = this.getSlice(b, m);
      this.attribname = this.lowerCaseAttributeNames ? g.toLowerCase() : g;
    }
    /** @internal */
    onattribdata(b, m) {
      this.attribvalue += this.getSlice(b, m);
    }
    /** @internal */
    onattribentity(b) {
      this.attribvalue += (0, s.fromCodePoint)(b);
    }
    /** @internal */
    onattribend(b, m) {
      var g, x;
      this.endIndex = m, (x = (g = this.cbs).onattribute) === null || x === void 0 || x.call(g, this.attribname, this.attribvalue, b === c.QuoteType.Double ? '"' : b === c.QuoteType.Single ? "'" : b === c.QuoteType.NoValue ? void 0 : null), this.attribs && !Object.prototype.hasOwnProperty.call(this.attribs, this.attribname) && (this.attribs[this.attribname] = this.attribvalue), this.attribvalue = "";
    }
    getInstructionName(b) {
      const m = b.search(h);
      let g = m < 0 ? b : b.substr(0, m);
      return this.lowerCaseTagNames && (g = g.toLowerCase()), g;
    }
    /** @internal */
    ondeclaration(b, m) {
      this.endIndex = m;
      const g = this.getSlice(b, m);
      if (this.cbs.onprocessinginstruction) {
        const x = this.getInstructionName(g);
        this.cbs.onprocessinginstruction(`!${x}`, `!${g}`);
      }
      this.startIndex = m + 1;
    }
    /** @internal */
    onprocessinginstruction(b, m) {
      this.endIndex = m;
      const g = this.getSlice(b, m);
      if (this.cbs.onprocessinginstruction) {
        const x = this.getInstructionName(g);
        this.cbs.onprocessinginstruction(`?${x}`, `?${g}`);
      }
      this.startIndex = m + 1;
    }
    /** @internal */
    oncomment(b, m, g) {
      var x, p, y, v;
      this.endIndex = m, (p = (x = this.cbs).oncomment) === null || p === void 0 || p.call(x, this.getSlice(b, m - g)), (v = (y = this.cbs).oncommentend) === null || v === void 0 || v.call(y), this.startIndex = m + 1;
    }
    /** @internal */
    oncdata(b, m, g) {
      var x, p, y, v, I, D, _, E, k, F;
      this.endIndex = m;
      const T = this.getSlice(b, m - g);
      !this.htmlMode || this.options.recognizeCDATA ? ((p = (x = this.cbs).oncdatastart) === null || p === void 0 || p.call(x), (v = (y = this.cbs).ontext) === null || v === void 0 || v.call(y, T), (D = (I = this.cbs).oncdataend) === null || D === void 0 || D.call(I)) : ((E = (_ = this.cbs).oncomment) === null || E === void 0 || E.call(_, `[CDATA[${T}]]`), (F = (k = this.cbs).oncommentend) === null || F === void 0 || F.call(k)), this.startIndex = m + 1;
    }
    /** @internal */
    onend() {
      var b, m;
      if (this.cbs.onclosetag) {
        this.endIndex = this.startIndex;
        for (let g = 0; g < this.stack.length; g++)
          this.cbs.onclosetag(this.stack[g], !0);
      }
      (m = (b = this.cbs).onend) === null || m === void 0 || m.call(b);
    }
    /**
     * Resets the parser to a blank state, ready to parse a new HTML document
     */
    reset() {
      var b, m, g, x;
      (m = (b = this.cbs).onreset) === null || m === void 0 || m.call(b), this.tokenizer.reset(), this.tagname = "", this.attribname = "", this.attribs = null, this.stack.length = 0, this.startIndex = 0, this.endIndex = 0, (x = (g = this.cbs).onparserinit) === null || x === void 0 || x.call(g, this), this.buffers.length = 0, this.foreignContext.length = 0, this.foreignContext.unshift(!this.htmlMode), this.bufferOffset = 0, this.writeIndex = 0, this.ended = !1;
    }
    /**
     * Resets the parser, then parses a complete document and
     * pushes it to the handler.
     *
     * @param data Document to parse.
     */
    parseComplete(b) {
      this.reset(), this.end(b);
    }
    getSlice(b, m) {
      for (; b - this.bufferOffset >= this.buffers[0].length; )
        this.shiftBuffer();
      let g = this.buffers[0].slice(b - this.bufferOffset, m - this.bufferOffset);
      for (; m - this.bufferOffset > this.buffers[0].length; )
        this.shiftBuffer(), g += this.buffers[0].slice(0, m - this.bufferOffset);
      return g;
    }
    shiftBuffer() {
      this.bufferOffset += this.buffers[0].length, this.writeIndex--, this.buffers.shift();
    }
    /**
     * Parses a chunk of data and calls the corresponding callbacks.
     *
     * @param chunk Chunk to parse.
     */
    write(b) {
      var m, g;
      if (this.ended) {
        (g = (m = this.cbs).onerror) === null || g === void 0 || g.call(m, new Error(".write() after done!"));
        return;
      }
      this.buffers.push(b), this.tokenizer.running && (this.tokenizer.write(b), this.writeIndex++);
    }
    /**
     * Parses the end of the buffer and clears the stack, calls onend.
     *
     * @param chunk Optional final chunk to parse.
     */
    end(b) {
      var m, g;
      if (this.ended) {
        (g = (m = this.cbs).onerror) === null || g === void 0 || g.call(m, new Error(".end() after done!"));
        return;
      }
      b && this.write(b), this.ended = !0, this.tokenizer.end();
    }
    /**
     * Pauses parsing. The parser won't emit events until `resume` is called.
     */
    pause() {
      this.tokenizer.pause();
    }
    /**
     * Resumes parsing after `pause` was called.
     */
    resume() {
      for (this.tokenizer.resume(); this.tokenizer.running && this.writeIndex < this.buffers.length; )
        this.tokenizer.write(this.buffers[this.writeIndex++]);
      this.ended && this.tokenizer.end();
    }
    /**
     * Alias of `write`, for backwards compatibility.
     *
     * @param chunk Chunk to parse.
     * @deprecated
     */
    parseChunk(b) {
      this.write(b);
    }
    /**
     * Alias of `end`, for backwards compatibility.
     *
     * @param chunk Optional final chunk to parse.
     * @deprecated
     */
    done(b) {
      this.end(b);
    }
  };
  return ae.Parser = w, ae;
}
var Fe = {}, Lu = {}, m0;
function Xe() {
  return m0 || (m0 = 1, (function(e) {
    Object.defineProperty(e, "__esModule", { value: !0 }), e.Doctype = e.CDATA = e.Tag = e.Style = e.Script = e.Comment = e.Directive = e.Text = e.Root = e.isTag = e.ElementType = void 0;
    var u;
    (function(c) {
      c.Root = "root", c.Text = "text", c.Directive = "directive", c.Comment = "comment", c.Script = "script", c.Style = "style", c.Tag = "tag", c.CDATA = "cdata", c.Doctype = "doctype";
    })(u = e.ElementType || (e.ElementType = {}));
    function t(c) {
      return c.type === u.Tag || c.type === u.Script || c.type === u.Style;
    }
    e.isTag = t, e.Root = u.Root, e.Text = u.Text, e.Directive = u.Directive, e.Comment = u.Comment, e.Script = u.Script, e.Style = u.Style, e.Tag = u.Tag, e.CDATA = u.CDATA, e.Doctype = u.Doctype;
  })(Lu)), Lu;
}
var G = {}, x0;
function y0() {
  if (x0) return G;
  x0 = 1;
  var e = G && G.__extends || /* @__PURE__ */ (function() {
    var p = function(y, v) {
      return p = Object.setPrototypeOf || { __proto__: [] } instanceof Array && function(I, D) {
        I.__proto__ = D;
      } || function(I, D) {
        for (var _ in D) Object.prototype.hasOwnProperty.call(D, _) && (I[_] = D[_]);
      }, p(y, v);
    };
    return function(y, v) {
      if (typeof v != "function" && v !== null)
        throw new TypeError("Class extends value " + String(v) + " is not a constructor or null");
      p(y, v);
      function I() {
        this.constructor = y;
      }
      y.prototype = v === null ? Object.create(v) : (I.prototype = v.prototype, new I());
    };
  })(), u = G && G.__assign || function() {
    return u = Object.assign || function(p) {
      for (var y, v = 1, I = arguments.length; v < I; v++) {
        y = arguments[v];
        for (var D in y) Object.prototype.hasOwnProperty.call(y, D) && (p[D] = y[D]);
      }
      return p;
    }, u.apply(this, arguments);
  };
  Object.defineProperty(G, "__esModule", { value: !0 }), G.cloneNode = G.hasChildren = G.isDocument = G.isDirective = G.isComment = G.isText = G.isCDATA = G.isTag = G.Element = G.Document = G.CDATA = G.NodeWithChildren = G.ProcessingInstruction = G.Comment = G.Text = G.DataNode = G.Node = void 0;
  var t = /* @__PURE__ */ Xe(), c = (
    /** @class */
    (function() {
      function p() {
        this.parent = null, this.prev = null, this.next = null, this.startIndex = null, this.endIndex = null;
      }
      return Object.defineProperty(p.prototype, "parentNode", {
        // Read-write aliases for properties
        /**
         * Same as {@link parent}.
         * [DOM spec](https://dom.spec.whatwg.org)-compatible alias.
         */
        get: function() {
          return this.parent;
        },
        set: function(y) {
          this.parent = y;
        },
        enumerable: !1,
        configurable: !0
      }), Object.defineProperty(p.prototype, "previousSibling", {
        /**
         * Same as {@link prev}.
         * [DOM spec](https://dom.spec.whatwg.org)-compatible alias.
         */
        get: function() {
          return this.prev;
        },
        set: function(y) {
          this.prev = y;
        },
        enumerable: !1,
        configurable: !0
      }), Object.defineProperty(p.prototype, "nextSibling", {
        /**
         * Same as {@link next}.
         * [DOM spec](https://dom.spec.whatwg.org)-compatible alias.
         */
        get: function() {
          return this.next;
        },
        set: function(y) {
          this.next = y;
        },
        enumerable: !1,
        configurable: !0
      }), p.prototype.cloneNode = function(y) {
        return y === void 0 && (y = !1), g(this, y);
      }, p;
    })()
  );
  G.Node = c;
  var s = (
    /** @class */
    (function(p) {
      e(y, p);
      function y(v) {
        var I = p.call(this) || this;
        return I.data = v, I;
      }
      return Object.defineProperty(y.prototype, "nodeValue", {
        /**
         * Same as {@link data}.
         * [DOM spec](https://dom.spec.whatwg.org)-compatible alias.
         */
        get: function() {
          return this.data;
        },
        set: function(v) {
          this.data = v;
        },
        enumerable: !1,
        configurable: !0
      }), y;
    })(c)
  );
  G.DataNode = s;
  var i = (
    /** @class */
    (function(p) {
      e(y, p);
      function y() {
        var v = p !== null && p.apply(this, arguments) || this;
        return v.type = t.ElementType.Text, v;
      }
      return Object.defineProperty(y.prototype, "nodeType", {
        get: function() {
          return 3;
        },
        enumerable: !1,
        configurable: !0
      }), y;
    })(s)
  );
  G.Text = i;
  var l = (
    /** @class */
    (function(p) {
      e(y, p);
      function y() {
        var v = p !== null && p.apply(this, arguments) || this;
        return v.type = t.ElementType.Comment, v;
      }
      return Object.defineProperty(y.prototype, "nodeType", {
        get: function() {
          return 8;
        },
        enumerable: !1,
        configurable: !0
      }), y;
    })(s)
  );
  G.Comment = l;
  var a = (
    /** @class */
    (function(p) {
      e(y, p);
      function y(v, I) {
        var D = p.call(this, I) || this;
        return D.name = v, D.type = t.ElementType.Directive, D;
      }
      return Object.defineProperty(y.prototype, "nodeType", {
        get: function() {
          return 1;
        },
        enumerable: !1,
        configurable: !0
      }), y;
    })(s)
  );
  G.ProcessingInstruction = a;
  var o = (
    /** @class */
    (function(p) {
      e(y, p);
      function y(v) {
        var I = p.call(this) || this;
        return I.children = v, I;
      }
      return Object.defineProperty(y.prototype, "firstChild", {
        // Aliases
        /** First child of the node. */
        get: function() {
          var v;
          return (v = this.children[0]) !== null && v !== void 0 ? v : null;
        },
        enumerable: !1,
        configurable: !0
      }), Object.defineProperty(y.prototype, "lastChild", {
        /** Last child of the node. */
        get: function() {
          return this.children.length > 0 ? this.children[this.children.length - 1] : null;
        },
        enumerable: !1,
        configurable: !0
      }), Object.defineProperty(y.prototype, "childNodes", {
        /**
         * Same as {@link children}.
         * [DOM spec](https://dom.spec.whatwg.org)-compatible alias.
         */
        get: function() {
          return this.children;
        },
        set: function(v) {
          this.children = v;
        },
        enumerable: !1,
        configurable: !0
      }), y;
    })(c)
  );
  G.NodeWithChildren = o;
  var r = (
    /** @class */
    (function(p) {
      e(y, p);
      function y() {
        var v = p !== null && p.apply(this, arguments) || this;
        return v.type = t.ElementType.CDATA, v;
      }
      return Object.defineProperty(y.prototype, "nodeType", {
        get: function() {
          return 4;
        },
        enumerable: !1,
        configurable: !0
      }), y;
    })(o)
  );
  G.CDATA = r;
  var n = (
    /** @class */
    (function(p) {
      e(y, p);
      function y() {
        var v = p !== null && p.apply(this, arguments) || this;
        return v.type = t.ElementType.Root, v;
      }
      return Object.defineProperty(y.prototype, "nodeType", {
        get: function() {
          return 9;
        },
        enumerable: !1,
        configurable: !0
      }), y;
    })(o)
  );
  G.Document = n;
  var f = (
    /** @class */
    (function(p) {
      e(y, p);
      function y(v, I, D, _) {
        D === void 0 && (D = []), _ === void 0 && (_ = v === "script" ? t.ElementType.Script : v === "style" ? t.ElementType.Style : t.ElementType.Tag);
        var E = p.call(this, D) || this;
        return E.name = v, E.attribs = I, E.type = _, E;
      }
      return Object.defineProperty(y.prototype, "nodeType", {
        get: function() {
          return 1;
        },
        enumerable: !1,
        configurable: !0
      }), Object.defineProperty(y.prototype, "tagName", {
        // DOM Level 1 aliases
        /**
         * Same as {@link name}.
         * [DOM spec](https://dom.spec.whatwg.org)-compatible alias.
         */
        get: function() {
          return this.name;
        },
        set: function(v) {
          this.name = v;
        },
        enumerable: !1,
        configurable: !0
      }), Object.defineProperty(y.prototype, "attributes", {
        get: function() {
          var v = this;
          return Object.keys(this.attribs).map(function(I) {
            var D, _;
            return {
              name: I,
              value: v.attribs[I],
              namespace: (D = v["x-attribsNamespace"]) === null || D === void 0 ? void 0 : D[I],
              prefix: (_ = v["x-attribsPrefix"]) === null || _ === void 0 ? void 0 : _[I]
            };
          });
        },
        enumerable: !1,
        configurable: !0
      }), y;
    })(o)
  );
  G.Element = f;
  function d(p) {
    return (0, t.isTag)(p);
  }
  G.isTag = d;
  function A(p) {
    return p.type === t.ElementType.CDATA;
  }
  G.isCDATA = A;
  function h(p) {
    return p.type === t.ElementType.Text;
  }
  G.isText = h;
  function w(p) {
    return p.type === t.ElementType.Comment;
  }
  G.isComment = w;
  function C(p) {
    return p.type === t.ElementType.Directive;
  }
  G.isDirective = C;
  function b(p) {
    return p.type === t.ElementType.Root;
  }
  G.isDocument = b;
  function m(p) {
    return Object.prototype.hasOwnProperty.call(p, "children");
  }
  G.hasChildren = m;
  function g(p, y) {
    y === void 0 && (y = !1);
    var v;
    if (h(p))
      v = new i(p.data);
    else if (w(p))
      v = new l(p.data);
    else if (d(p)) {
      var I = y ? x(p.children) : [], D = new f(p.name, u({}, p.attribs), I);
      I.forEach(function(F) {
        return F.parent = D;
      }), p.namespace != null && (D.namespace = p.namespace), p["x-attribsNamespace"] && (D["x-attribsNamespace"] = u({}, p["x-attribsNamespace"])), p["x-attribsPrefix"] && (D["x-attribsPrefix"] = u({}, p["x-attribsPrefix"])), v = D;
    } else if (A(p)) {
      var I = y ? x(p.children) : [], _ = new r(I);
      I.forEach(function(T) {
        return T.parent = _;
      }), v = _;
    } else if (b(p)) {
      var I = y ? x(p.children) : [], E = new n(I);
      I.forEach(function(T) {
        return T.parent = E;
      }), p["x-mode"] && (E["x-mode"] = p["x-mode"]), v = E;
    } else if (C(p)) {
      var k = new a(p.name, p.data);
      p["x-name"] != null && (k["x-name"] = p["x-name"], k["x-publicId"] = p["x-publicId"], k["x-systemId"] = p["x-systemId"]), v = k;
    } else
      throw new Error("Not implemented yet: ".concat(p.type));
    return v.startIndex = p.startIndex, v.endIndex = p.endIndex, p.sourceCodeLocation != null && (v.sourceCodeLocation = p.sourceCodeLocation), v;
  }
  G.cloneNode = g;
  function x(p) {
    for (var y = p.map(function(I) {
      return g(I, !0);
    }), v = 1; v < y.length; v++)
      y[v].prev = y[v - 1], y[v - 1].next = y[v];
    return y;
  }
  return G;
}
var w0;
function Ie() {
  return w0 || (w0 = 1, (function(e) {
    var u = Fe && Fe.__createBinding || (Object.create ? (function(a, o, r, n) {
      n === void 0 && (n = r);
      var f = Object.getOwnPropertyDescriptor(o, r);
      (!f || ("get" in f ? !o.__esModule : f.writable || f.configurable)) && (f = { enumerable: !0, get: function() {
        return o[r];
      } }), Object.defineProperty(a, n, f);
    }) : (function(a, o, r, n) {
      n === void 0 && (n = r), a[n] = o[r];
    })), t = Fe && Fe.__exportStar || function(a, o) {
      for (var r in a) r !== "default" && !Object.prototype.hasOwnProperty.call(o, r) && u(o, a, r);
    };
    Object.defineProperty(e, "__esModule", { value: !0 }), e.DomHandler = void 0;
    var c = /* @__PURE__ */ Xe(), s = /* @__PURE__ */ y0();
    t(/* @__PURE__ */ y0(), e);
    var i = {
      withStartIndices: !1,
      withEndIndices: !1,
      xmlMode: !1
    }, l = (
      /** @class */
      (function() {
        function a(o, r, n) {
          this.dom = [], this.root = new s.Document(this.dom), this.done = !1, this.tagStack = [this.root], this.lastNode = null, this.parser = null, typeof r == "function" && (n = r, r = i), typeof o == "object" && (r = o, o = void 0), this.callback = o ?? null, this.options = r ?? i, this.elementCB = n ?? null;
        }
        return a.prototype.onparserinit = function(o) {
          this.parser = o;
        }, a.prototype.onreset = function() {
          this.dom = [], this.root = new s.Document(this.dom), this.done = !1, this.tagStack = [this.root], this.lastNode = null, this.parser = null;
        }, a.prototype.onend = function() {
          this.done || (this.done = !0, this.parser = null, this.handleCallback(null));
        }, a.prototype.onerror = function(o) {
          this.handleCallback(o);
        }, a.prototype.onclosetag = function() {
          this.lastNode = null;
          var o = this.tagStack.pop();
          this.options.withEndIndices && (o.endIndex = this.parser.endIndex), this.elementCB && this.elementCB(o);
        }, a.prototype.onopentag = function(o, r) {
          var n = this.options.xmlMode ? c.ElementType.Tag : void 0, f = new s.Element(o, r, void 0, n);
          this.addNode(f), this.tagStack.push(f);
        }, a.prototype.ontext = function(o) {
          var r = this.lastNode;
          if (r && r.type === c.ElementType.Text)
            r.data += o, this.options.withEndIndices && (r.endIndex = this.parser.endIndex);
          else {
            var n = new s.Text(o);
            this.addNode(n), this.lastNode = n;
          }
        }, a.prototype.oncomment = function(o) {
          if (this.lastNode && this.lastNode.type === c.ElementType.Comment) {
            this.lastNode.data += o;
            return;
          }
          var r = new s.Comment(o);
          this.addNode(r), this.lastNode = r;
        }, a.prototype.oncommentend = function() {
          this.lastNode = null;
        }, a.prototype.oncdatastart = function() {
          var o = new s.Text(""), r = new s.CDATA([o]);
          this.addNode(r), o.parent = r, this.lastNode = o;
        }, a.prototype.oncdataend = function() {
          this.lastNode = null;
        }, a.prototype.onprocessinginstruction = function(o, r) {
          var n = new s.ProcessingInstruction(o, r);
          this.addNode(n);
        }, a.prototype.handleCallback = function(o) {
          if (typeof this.callback == "function")
            this.callback(o, this.dom);
          else if (o)
            throw o;
        }, a.prototype.addNode = function(o) {
          var r = this.tagStack[this.tagStack.length - 1], n = r.children[r.children.length - 1];
          this.options.withStartIndices && (o.startIndex = this.parser.startIndex), this.options.withEndIndices && (o.endIndex = this.parser.endIndex), r.children.push(o), n && (o.prev = n, n.next = o), o.parent = r, this.lastNode = null;
        }, a;
      })()
    );
    e.DomHandler = l, e.default = l;
  })(Fe)), Fe;
}
var Se = {}, fe = {}, X = {}, Pu = {}, se = {}, nu = {}, C0;
function Fs() {
  return C0 || (C0 = 1, Object.defineProperty(nu, "__esModule", { value: !0 }), nu.default = new Uint16Array(
    // prettier-ignore
    'ᵁ<Õıʊҝջאٵ۞ޢߖࠏ੊ઑඡ๭༉༦჊ረዡᐕᒝᓃᓟᔥ\0\0\0\0\0\0ᕫᛍᦍᰒᷝ὾⁠↰⊍⏀⏻⑂⠤⤒ⴈ⹈⿎〖㊺㘹㞬㣾㨨㩱㫠㬮ࠀEMabcfglmnoprstu\\bfms¦³¹ÈÏlig耻Æ䃆P耻&䀦cute耻Á䃁reve;䄂Āiyx}rc耻Â䃂;䐐r;쀀𝔄rave耻À䃀pha;䎑acr;䄀d;橓Āgp¡on;䄄f;쀀𝔸plyFunction;恡ing耻Å䃅Ācs¾Ãr;쀀𝒜ign;扔ilde耻Ã䃃ml耻Ä䃄ЀaceforsuåûþėĜĢħĪĀcrêòkslash;或Ŷöø;櫧ed;挆y;䐑ƀcrtąċĔause;戵noullis;愬a;䎒r;쀀𝔅pf;쀀𝔹eve;䋘còēmpeq;扎܀HOacdefhilorsuōőŖƀƞƢƵƷƺǜȕɳɸɾcy;䐧PY耻©䂩ƀcpyŝŢźute;䄆Ā;iŧŨ拒talDifferentialD;慅leys;愭ȀaeioƉƎƔƘron;䄌dil耻Ç䃇rc;䄈nint;戰ot;䄊ĀdnƧƭilla;䂸terDot;䂷òſi;䎧rcleȀDMPTǇǋǑǖot;抙inus;抖lus;投imes;抗oĀcsǢǸkwiseContourIntegral;戲eCurlyĀDQȃȏoubleQuote;思uote;怙ȀlnpuȞȨɇɕonĀ;eȥȦ户;橴ƀgitȯȶȺruent;扡nt;戯ourIntegral;戮ĀfrɌɎ;愂oduct;成nterClockwiseContourIntegral;戳oss;樯cr;쀀𝒞pĀ;Cʄʅ拓ap;才րDJSZacefiosʠʬʰʴʸˋ˗ˡ˦̳ҍĀ;oŹʥtrahd;椑cy;䐂cy;䐅cy;䐏ƀgrsʿ˄ˇger;怡r;憡hv;櫤Āayː˕ron;䄎;䐔lĀ;t˝˞戇a;䎔r;쀀𝔇Āaf˫̧Ācm˰̢riticalȀADGT̖̜̀̆cute;䂴oŴ̋̍;䋙bleAcute;䋝rave;䁠ilde;䋜ond;拄ferentialD;慆Ѱ̽\0\0\0͔͂\0Ѕf;쀀𝔻ƀ;DE͈͉͍䂨ot;惜qual;扐blèCDLRUVͣͲ΂ϏϢϸontourIntegraìȹoɴ͹\0\0ͻ»͉nArrow;懓Āeo·ΤftƀARTΐΖΡrrow;懐ightArrow;懔eåˊngĀLRΫτeftĀARγιrrow;柸ightArrow;柺ightArrow;柹ightĀATϘϞrrow;懒ee;抨pɁϩ\0\0ϯrrow;懑ownArrow;懕erticalBar;戥ǹABLRTaВЪаўѿͼrrowƀ;BUНОТ憓ar;椓pArrow;懵reve;䌑eft˒к\0ц\0ѐightVector;楐eeVector;楞ectorĀ;Bљњ憽ar;楖ightǔѧ\0ѱeeVector;楟ectorĀ;BѺѻ懁ar;楗eeĀ;A҆҇护rrow;憧ĀctҒҗr;쀀𝒟rok;䄐ࠀNTacdfglmopqstuxҽӀӄӋӞӢӧӮӵԡԯԶՒ՝ՠեG;䅊H耻Ð䃐cute耻É䃉ƀaiyӒӗӜron;䄚rc耻Ê䃊;䐭ot;䄖r;쀀𝔈rave耻È䃈ement;戈ĀapӺӾcr;䄒tyɓԆ\0\0ԒmallSquare;旻erySmallSquare;斫ĀgpԦԪon;䄘f;쀀𝔼silon;䎕uĀaiԼՉlĀ;TՂՃ橵ilde;扂librium;懌Āci՗՚r;愰m;橳a;䎗ml耻Ë䃋Āipժկsts;戃onentialE;慇ʀcfiosօֈ֍ֲ׌y;䐤r;쀀𝔉lledɓ֗\0\0֣mallSquare;旼erySmallSquare;斪Ͱֺ\0ֿ\0\0ׄf;쀀𝔽All;戀riertrf;愱cò׋؀JTabcdfgorstר׬ׯ׺؀ؒؖ؛؝أ٬ٲcy;䐃耻>䀾mmaĀ;d׷׸䎓;䏜reve;䄞ƀeiy؇،ؐdil;䄢rc;䄜;䐓ot;䄠r;쀀𝔊;拙pf;쀀𝔾eater̀EFGLSTصلَٖٛ٦qualĀ;Lؾؿ扥ess;招ullEqual;执reater;檢ess;扷lantEqual;橾ilde;扳cr;쀀𝒢;扫ЀAacfiosuڅڋږڛڞڪھۊRDcy;䐪Āctڐڔek;䋇;䁞irc;䄤r;愌lbertSpace;愋ǰگ\0ڲf;愍izontalLine;攀Āctۃۅòکrok;䄦mpńېۘownHumðįqual;扏܀EJOacdfgmnostuۺ۾܃܇܎ܚܞܡܨ݄ݸދޏޕcy;䐕lig;䄲cy;䐁cute耻Í䃍Āiyܓܘrc耻Î䃎;䐘ot;䄰r;愑rave耻Ì䃌ƀ;apܠܯܿĀcgܴܷr;䄪inaryI;慈lieóϝǴ݉\0ݢĀ;eݍݎ戬Āgrݓݘral;戫section;拂isibleĀCTݬݲomma;恣imes;恢ƀgptݿރވon;䄮f;쀀𝕀a;䎙cr;愐ilde;䄨ǫޚ\0ޞcy;䐆l耻Ï䃏ʀcfosuެ޷޼߂ߐĀiyޱ޵rc;䄴;䐙r;쀀𝔍pf;쀀𝕁ǣ߇\0ߌr;쀀𝒥rcy;䐈kcy;䐄΀HJacfosߤߨ߽߬߱ࠂࠈcy;䐥cy;䐌ppa;䎚Āey߶߻dil;䄶;䐚r;쀀𝔎pf;쀀𝕂cr;쀀𝒦րJTaceflmostࠥࠩࠬࡐࡣ঳সে্਷ੇcy;䐉耻<䀼ʀcmnpr࠷࠼ࡁࡄࡍute;䄹bda;䎛g;柪lacetrf;愒r;憞ƀaeyࡗ࡜ࡡron;䄽dil;䄻;䐛Āfsࡨ॰tԀACDFRTUVarࡾࢩࢱࣦ࣠ࣼयज़ΐ४Ānrࢃ࢏gleBracket;柨rowƀ;BR࢙࢚࢞憐ar;懤ightArrow;懆eiling;挈oǵࢷ\0ࣃbleBracket;柦nǔࣈ\0࣒eeVector;楡ectorĀ;Bࣛࣜ懃ar;楙loor;挊ightĀAV࣯ࣵrrow;憔ector;楎Āerँगeƀ;AVउऊऐ抣rrow;憤ector;楚iangleƀ;BEतथऩ抲ar;槏qual;抴pƀDTVषूौownVector;楑eeVector;楠ectorĀ;Bॖॗ憿ar;楘ectorĀ;B॥०憼ar;楒ightáΜs̀EFGLSTॾঋকঝঢভqualGreater;拚ullEqual;扦reater;扶ess;檡lantEqual;橽ilde;扲r;쀀𝔏Ā;eঽা拘ftarrow;懚idot;䄿ƀnpw৔ਖਛgȀLRlr৞৷ਂਐeftĀAR০৬rrow;柵ightArrow;柷ightArrow;柶eftĀarγਊightáοightáϊf;쀀𝕃erĀLRਢਬeftArrow;憙ightArrow;憘ƀchtਾੀੂòࡌ;憰rok;䅁;扪Ѐacefiosuਗ਼੝੠੷੼અઋ઎p;椅y;䐜Ādl੥੯iumSpace;恟lintrf;愳r;쀀𝔐nusPlus;戓pf;쀀𝕄cò੶;䎜ҀJacefostuણધભીଔଙඑ඗ඞcy;䐊cute;䅃ƀaey઴હાron;䅇dil;䅅;䐝ƀgswે૰଎ativeƀMTV૓૟૨ediumSpace;怋hiĀcn૦૘ë૙eryThiî૙tedĀGL૸ଆreaterGreateòٳessLesóੈLine;䀊r;쀀𝔑ȀBnptଢନଷ଺reak;恠BreakingSpace;䂠f;愕ڀ;CDEGHLNPRSTV୕ୖ୪୼஡௫ఄ౞಄ದ೘ൡඅ櫬Āou୛୤ngruent;扢pCap;扭oubleVerticalBar;戦ƀlqxஃஊ஛ement;戉ualĀ;Tஒஓ扠ilde;쀀≂̸ists;戄reater΀;EFGLSTஶஷ஽௉௓௘௥扯qual;扱ullEqual;쀀≧̸reater;쀀≫̸ess;批lantEqual;쀀⩾̸ilde;扵umpń௲௽ownHump;쀀≎̸qual;쀀≏̸eĀfsఊధtTriangleƀ;BEచఛడ拪ar;쀀⧏̸qual;括s̀;EGLSTవశ఼ౄోౘ扮qual;扰reater;扸ess;쀀≪̸lantEqual;쀀⩽̸ilde;扴estedĀGL౨౹reaterGreater;쀀⪢̸essLess;쀀⪡̸recedesƀ;ESಒಓಛ技qual;쀀⪯̸lantEqual;拠ĀeiಫಹverseElement;戌ghtTriangleƀ;BEೋೌ೒拫ar;쀀⧐̸qual;拭ĀquೝഌuareSuĀbp೨೹setĀ;E೰ೳ쀀⊏̸qual;拢ersetĀ;Eഃആ쀀⊐̸qual;拣ƀbcpഓതൎsetĀ;Eഛഞ쀀⊂⃒qual;抈ceedsȀ;ESTലള഻െ抁qual;쀀⪰̸lantEqual;拡ilde;쀀≿̸ersetĀ;E൘൛쀀⊃⃒qual;抉ildeȀ;EFT൮൯൵ൿ扁qual;扄ullEqual;扇ilde;扉erticalBar;戤cr;쀀𝒩ilde耻Ñ䃑;䎝܀Eacdfgmoprstuvලෂ෉෕ෛ෠෧෼ขภยา฿ไlig;䅒cute耻Ó䃓Āiy෎ීrc耻Ô䃔;䐞blac;䅐r;쀀𝔒rave耻Ò䃒ƀaei෮ෲ෶cr;䅌ga;䎩cron;䎟pf;쀀𝕆enCurlyĀDQฎบoubleQuote;怜uote;怘;橔Āclวฬr;쀀𝒪ash耻Ø䃘iŬื฼de耻Õ䃕es;樷ml耻Ö䃖erĀBP๋๠Āar๐๓r;怾acĀek๚๜;揞et;掴arenthesis;揜Ҁacfhilors๿ງຊຏຒດຝະ໼rtialD;戂y;䐟r;쀀𝔓i;䎦;䎠usMinus;䂱Āipຢອncareplanåڝf;愙Ȁ;eio຺ູ໠໤檻cedesȀ;EST່້໏໚扺qual;檯lantEqual;扼ilde;找me;怳Ādp໩໮uct;戏ortionĀ;aȥ໹l;戝Āci༁༆r;쀀𝒫;䎨ȀUfos༑༖༛༟OT耻"䀢r;쀀𝔔pf;愚cr;쀀𝒬؀BEacefhiorsu༾གྷཇའཱིྦྷྪྭ႖ႩႴႾarr;椐G耻®䂮ƀcnrཎནབute;䅔g;柫rĀ;tཛྷཝ憠l;椖ƀaeyཧཬཱron;䅘dil;䅖;䐠Ā;vླྀཹ愜erseĀEUྂྙĀlq྇ྎement;戋uilibrium;懋pEquilibrium;楯r»ཹo;䎡ghtЀACDFTUVa࿁࿫࿳ဢဨၛႇϘĀnr࿆࿒gleBracket;柩rowƀ;BL࿜࿝࿡憒ar;懥eftArrow;懄eiling;按oǵ࿹\0စbleBracket;柧nǔည\0နeeVector;楝ectorĀ;Bဝသ懂ar;楕loor;挋Āerိ၃eƀ;AVဵံြ抢rrow;憦ector;楛iangleƀ;BEၐၑၕ抳ar;槐qual;抵pƀDTVၣၮၸownVector;楏eeVector;楜ectorĀ;Bႂႃ憾ar;楔ectorĀ;B႑႒懀ar;楓Āpuႛ႞f;愝ndImplies;楰ightarrow;懛ĀchႹႼr;愛;憱leDelayed;槴ڀHOacfhimoqstuფჱჷჽᄙᄞᅑᅖᅡᅧᆵᆻᆿĀCcჩხHcy;䐩y;䐨FTcy;䐬cute;䅚ʀ;aeiyᄈᄉᄎᄓᄗ檼ron;䅠dil;䅞rc;䅜;䐡r;쀀𝔖ortȀDLRUᄪᄴᄾᅉownArrow»ОeftArrow»࢚ightArrow»࿝pArrow;憑gma;䎣allCircle;战pf;쀀𝕊ɲᅭ\0\0ᅰt;戚areȀ;ISUᅻᅼᆉᆯ斡ntersection;抓uĀbpᆏᆞsetĀ;Eᆗᆘ抏qual;抑ersetĀ;Eᆨᆩ抐qual;抒nion;抔cr;쀀𝒮ar;拆ȀbcmpᇈᇛሉላĀ;sᇍᇎ拐etĀ;Eᇍᇕqual;抆ĀchᇠህeedsȀ;ESTᇭᇮᇴᇿ扻qual;檰lantEqual;扽ilde;承Tháྌ;我ƀ;esሒሓሣ拑rsetĀ;Eሜም抃qual;抇et»ሓրHRSacfhiorsሾቄ቉ቕ቞ቱቶኟዂወዑORN耻Þ䃞ADE;愢ĀHc቎ቒcy;䐋y;䐦Ābuቚቜ;䀉;䎤ƀaeyብቪቯron;䅤dil;䅢;䐢r;쀀𝔗Āeiቻ኉ǲኀ\0ኇefore;戴a;䎘Ācn኎ኘkSpace;쀀  Space;怉ldeȀ;EFTካኬኲኼ戼qual;扃ullEqual;扅ilde;扈pf;쀀𝕋ipleDot;惛Āctዖዛr;쀀𝒯rok;䅦ૡዷጎጚጦ\0ጬጱ\0\0\0\0\0ጸጽ፷ᎅ\0᏿ᐄᐊᐐĀcrዻጁute耻Ú䃚rĀ;oጇገ憟cir;楉rǣጓ\0጖y;䐎ve;䅬Āiyጞጣrc耻Û䃛;䐣blac;䅰r;쀀𝔘rave耻Ù䃙acr;䅪Ādiፁ፩erĀBPፈ፝Āarፍፐr;䁟acĀekፗፙ;揟et;掵arenthesis;揝onĀ;P፰፱拃lus;抎Āgp፻፿on;䅲f;쀀𝕌ЀADETadps᎕ᎮᎸᏄϨᏒᏗᏳrrowƀ;BDᅐᎠᎤar;椒ownArrow;懅ownArrow;憕quilibrium;楮eeĀ;AᏋᏌ报rrow;憥ownáϳerĀLRᏞᏨeftArrow;憖ightArrow;憗iĀ;lᏹᏺ䏒on;䎥ing;䅮cr;쀀𝒰ilde;䅨ml耻Ü䃜ҀDbcdefosvᐧᐬᐰᐳᐾᒅᒊᒐᒖash;披ar;櫫y;䐒ashĀ;lᐻᐼ抩;櫦Āerᑃᑅ;拁ƀbtyᑌᑐᑺar;怖Ā;iᑏᑕcalȀBLSTᑡᑥᑪᑴar;戣ine;䁼eparator;杘ilde;所ThinSpace;怊r;쀀𝔙pf;쀀𝕍cr;쀀𝒱dash;抪ʀcefosᒧᒬᒱᒶᒼirc;䅴dge;拀r;쀀𝔚pf;쀀𝕎cr;쀀𝒲Ȁfiosᓋᓐᓒᓘr;쀀𝔛;䎞pf;쀀𝕏cr;쀀𝒳ҀAIUacfosuᓱᓵᓹᓽᔄᔏᔔᔚᔠcy;䐯cy;䐇cy;䐮cute耻Ý䃝Āiyᔉᔍrc;䅶;䐫r;쀀𝔜pf;쀀𝕐cr;쀀𝒴ml;䅸ЀHacdefosᔵᔹᔿᕋᕏᕝᕠᕤcy;䐖cute;䅹Āayᕄᕉron;䅽;䐗ot;䅻ǲᕔ\0ᕛoWidtè૙a;䎖r;愨pf;愤cr;쀀𝒵௡ᖃᖊᖐ\0ᖰᖶᖿ\0\0\0\0ᗆᗛᗫᙟ᙭\0ᚕ᚛ᚲᚹ\0ᚾcute耻á䃡reve;䄃̀;Ediuyᖜᖝᖡᖣᖨᖭ戾;쀀∾̳;房rc耻â䃢te肻´̆;䐰lig耻æ䃦Ā;r²ᖺ;쀀𝔞rave耻à䃠ĀepᗊᗖĀfpᗏᗔsym;愵èᗓha;䎱ĀapᗟcĀclᗤᗧr;䄁g;樿ɤᗰ\0\0ᘊʀ;adsvᗺᗻᗿᘁᘇ戧nd;橕;橜lope;橘;橚΀;elmrszᘘᘙᘛᘞᘿᙏᙙ戠;榤e»ᘙsdĀ;aᘥᘦ戡ѡᘰᘲᘴᘶᘸᘺᘼᘾ;榨;榩;榪;榫;榬;榭;榮;榯tĀ;vᙅᙆ戟bĀ;dᙌᙍ抾;榝Āptᙔᙗh;戢»¹arr;捼Āgpᙣᙧon;䄅f;쀀𝕒΀;Eaeiop዁ᙻᙽᚂᚄᚇᚊ;橰cir;橯;扊d;手s;䀧roxĀ;e዁ᚒñᚃing耻å䃥ƀctyᚡᚦᚨr;쀀𝒶;䀪mpĀ;e዁ᚯñʈilde耻ã䃣ml耻ä䃤Āciᛂᛈoninôɲnt;樑ࠀNabcdefiklnoprsu᛭ᛱᜰ᜼ᝃᝈ᝸᝽០៦ᠹᡐᜍ᤽᥈ᥰot;櫭Ācrᛶ᜞kȀcepsᜀᜅᜍᜓong;扌psilon;䏶rime;怵imĀ;e᜚᜛戽q;拍Ŷᜢᜦee;抽edĀ;gᜬᜭ挅e»ᜭrkĀ;t፜᜷brk;掶Āoyᜁᝁ;䐱quo;怞ʀcmprtᝓ᝛ᝡᝤᝨausĀ;eĊĉptyv;榰séᜌnoõēƀahwᝯ᝱ᝳ;䎲;愶een;扬r;쀀𝔟g΀costuvwឍឝឳេ៕៛៞ƀaiuបពរðݠrc;旯p»፱ƀdptឤឨឭot;樀lus;樁imes;樂ɱឹ\0\0ើcup;樆ar;昅riangleĀdu៍្own;施p;斳plus;樄eåᑄåᒭarow;植ƀako៭ᠦᠵĀcn៲ᠣkƀlst៺֫᠂ozenge;槫riangleȀ;dlr᠒᠓᠘᠝斴own;斾eft;旂ight;斸k;搣Ʊᠫ\0ᠳƲᠯ\0ᠱ;斒;斑4;斓ck;斈ĀeoᠾᡍĀ;qᡃᡆ쀀=⃥uiv;쀀≡⃥t;挐Ȁptwxᡙᡞᡧᡬf;쀀𝕓Ā;tᏋᡣom»Ꮜtie;拈؀DHUVbdhmptuvᢅᢖᢪᢻᣗᣛᣬ᣿ᤅᤊᤐᤡȀLRlrᢎᢐᢒᢔ;敗;敔;敖;敓ʀ;DUduᢡᢢᢤᢦᢨ敐;敦;敩;敤;敧ȀLRlrᢳᢵᢷᢹ;敝;敚;敜;教΀;HLRhlrᣊᣋᣍᣏᣑᣓᣕ救;敬;散;敠;敫;敢;敟ox;槉ȀLRlrᣤᣦᣨᣪ;敕;敒;攐;攌ʀ;DUduڽ᣷᣹᣻᣽;敥;敨;攬;攴inus;抟lus;択imes;抠ȀLRlrᤙᤛᤝ᤟;敛;敘;攘;攔΀;HLRhlrᤰᤱᤳᤵᤷ᤻᤹攂;敪;敡;敞;攼;攤;攜Āevģ᥂bar耻¦䂦Ȁceioᥑᥖᥚᥠr;쀀𝒷mi;恏mĀ;e᜚᜜lƀ;bhᥨᥩᥫ䁜;槅sub;柈Ŭᥴ᥾lĀ;e᥹᥺怢t»᥺pƀ;Eeįᦅᦇ;檮Ā;qۜۛೡᦧ\0᧨ᨑᨕᨲ\0ᨷᩐ\0\0᪴\0\0᫁\0\0ᬡᬮ᭍᭒\0᯽\0ᰌƀcpr᦭ᦲ᧝ute;䄇̀;abcdsᦿᧀᧄ᧊᧕᧙戩nd;橄rcup;橉Āau᧏᧒p;橋p;橇ot;橀;쀀∩︀Āeo᧢᧥t;恁îړȀaeiu᧰᧻ᨁᨅǰ᧵\0᧸s;橍on;䄍dil耻ç䃧rc;䄉psĀ;sᨌᨍ橌m;橐ot;䄋ƀdmnᨛᨠᨦil肻¸ƭptyv;榲t脀¢;eᨭᨮ䂢räƲr;쀀𝔠ƀceiᨽᩀᩍy;䑇ckĀ;mᩇᩈ朓ark»ᩈ;䏇r΀;Ecefms᩟᩠ᩢᩫ᪤᪪᪮旋;槃ƀ;elᩩᩪᩭ䋆q;扗eɡᩴ\0\0᪈rrowĀlr᩼᪁eft;憺ight;憻ʀRSacd᪒᪔᪖᪚᪟»ཇ;擈st;抛irc;抚ash;抝nint;樐id;櫯cir;槂ubsĀ;u᪻᪼晣it»᪼ˬ᫇᫔᫺\0ᬊonĀ;eᫍᫎ䀺Ā;qÇÆɭ᫙\0\0᫢aĀ;t᫞᫟䀬;䁀ƀ;fl᫨᫩᫫戁îᅠeĀmx᫱᫶ent»᫩eóɍǧ᫾\0ᬇĀ;dኻᬂot;橭nôɆƀfryᬐᬔᬗ;쀀𝕔oäɔ脀©;sŕᬝr;愗Āaoᬥᬩrr;憵ss;朗Ācuᬲᬷr;쀀𝒸Ābpᬼ᭄Ā;eᭁᭂ櫏;櫑Ā;eᭉᭊ櫐;櫒dot;拯΀delprvw᭠᭬᭷ᮂᮬᯔ᯹arrĀlr᭨᭪;椸;椵ɰ᭲\0\0᭵r;拞c;拟arrĀ;p᭿ᮀ憶;椽̀;bcdosᮏᮐᮖᮡᮥᮨ截rcap;橈Āauᮛᮞp;橆p;橊ot;抍r;橅;쀀∪︀Ȁalrv᮵ᮿᯞᯣrrĀ;mᮼᮽ憷;椼yƀevwᯇᯔᯘqɰᯎ\0\0ᯒreã᭳uã᭵ee;拎edge;拏en耻¤䂤earrowĀlrᯮ᯳eft»ᮀight»ᮽeäᯝĀciᰁᰇoninôǷnt;戱lcty;挭ঀAHabcdefhijlorstuwz᰸᰻᰿ᱝᱩᱵᲊᲞᲬᲷ᳻᳿ᴍᵻᶑᶫᶻ᷆᷍rò΁ar;楥Ȁglrs᱈ᱍ᱒᱔ger;怠eth;愸òᄳhĀ;vᱚᱛ怐»ऊūᱡᱧarow;椏aã̕Āayᱮᱳron;䄏;䐴ƀ;ao̲ᱼᲄĀgrʿᲁr;懊tseq;橷ƀglmᲑᲔᲘ耻°䂰ta;䎴ptyv;榱ĀirᲣᲨsht;楿;쀀𝔡arĀlrᲳᲵ»ࣜ»သʀaegsv᳂͸᳖᳜᳠mƀ;oș᳊᳔ndĀ;ș᳑uit;晦amma;䏝in;拲ƀ;io᳧᳨᳸䃷de脀÷;o᳧ᳰntimes;拇nø᳷cy;䑒cɯᴆ\0\0ᴊrn;挞op;挍ʀlptuwᴘᴝᴢᵉᵕlar;䀤f;쀀𝕕ʀ;emps̋ᴭᴷᴽᵂqĀ;d͒ᴳot;扑inus;戸lus;戔quare;抡blebarwedgåúnƀadhᄮᵝᵧownarrowóᲃarpoonĀlrᵲᵶefôᲴighôᲶŢᵿᶅkaro÷གɯᶊ\0\0ᶎrn;挟op;挌ƀcotᶘᶣᶦĀryᶝᶡ;쀀𝒹;䑕l;槶rok;䄑Ādrᶰᶴot;拱iĀ;fᶺ᠖斿Āah᷀᷃ròЩaòྦangle;榦Āci᷒ᷕy;䑟grarr;柿ऀDacdefglmnopqrstuxḁḉḙḸոḼṉṡṾấắẽỡἪἷὄ὎὚ĀDoḆᴴoôᲉĀcsḎḔute耻é䃩ter;橮ȀaioyḢḧḱḶron;䄛rĀ;cḭḮ扖耻ê䃪lon;払;䑍ot;䄗ĀDrṁṅot;扒;쀀𝔢ƀ;rsṐṑṗ檚ave耻è䃨Ā;dṜṝ檖ot;檘Ȁ;ilsṪṫṲṴ檙nters;揧;愓Ā;dṹṺ檕ot;檗ƀapsẅẉẗcr;䄓tyƀ;svẒẓẕ戅et»ẓpĀ1;ẝẤĳạả;怄;怅怃ĀgsẪẬ;䅋p;怂ĀgpẴẸon;䄙f;쀀𝕖ƀalsỄỎỒrĀ;sỊị拕l;槣us;橱iƀ;lvỚớở䎵on»ớ;䏵ȀcsuvỪỳἋἣĀioữḱrc»Ḯɩỹ\0\0ỻíՈantĀglἂἆtr»ṝess»Ṻƀaeiἒ἖Ἒls;䀽st;扟vĀ;DȵἠD;橸parsl;槥ĀDaἯἳot;打rr;楱ƀcdiἾὁỸr;愯oô͒ĀahὉὋ;䎷耻ð䃰Āmrὓὗl耻ë䃫o;悬ƀcipὡὤὧl;䀡sôծĀeoὬὴctatioîՙnentialåչৡᾒ\0ᾞ\0ᾡᾧ\0\0ῆῌ\0ΐ\0ῦῪ \0 ⁚llingdotseñṄy;䑄male;晀ƀilrᾭᾳ῁lig;耀ﬃɩᾹ\0\0᾽g;耀ﬀig;耀ﬄ;쀀𝔣lig;耀ﬁlig;쀀fjƀaltῙ῜ῡt;晭ig;耀ﬂns;斱of;䆒ǰ΅\0ῳf;쀀𝕗ĀakֿῷĀ;vῼ´拔;櫙artint;樍Āao‌⁕Ācs‑⁒α‚‰‸⁅⁈\0⁐β•‥‧‪‬\0‮耻½䂽;慓耻¼䂼;慕;慙;慛Ƴ‴\0‶;慔;慖ʴ‾⁁\0\0⁃耻¾䂾;慗;慜5;慘ƶ⁌\0⁎;慚;慝8;慞l;恄wn;挢cr;쀀𝒻ࢀEabcdefgijlnorstv₂₉₟₥₰₴⃰⃵⃺⃿℃ℒℸ̗ℾ⅒↞Ā;lٍ₇;檌ƀcmpₐₕ₝ute;䇵maĀ;dₜ᳚䎳;檆reve;䄟Āiy₪₮rc;䄝;䐳ot;䄡Ȁ;lqsؾق₽⃉ƀ;qsؾٌ⃄lanô٥Ȁ;cdl٥⃒⃥⃕c;檩otĀ;o⃜⃝檀Ā;l⃢⃣檂;檄Ā;e⃪⃭쀀⋛︀s;檔r;쀀𝔤Ā;gٳ؛mel;愷cy;䑓Ȁ;Eajٚℌℎℐ;檒;檥;檤ȀEaesℛℝ℩ℴ;扩pĀ;p℣ℤ檊rox»ℤĀ;q℮ℯ檈Ā;q℮ℛim;拧pf;쀀𝕘Āci⅃ⅆr;愊mƀ;el٫ⅎ⅐;檎;檐茀>;cdlqr׮ⅠⅪⅮⅳⅹĀciⅥⅧ;檧r;橺ot;拗Par;榕uest;橼ʀadelsↄⅪ←ٖ↛ǰ↉\0↎proø₞r;楸qĀlqؿ↖lesó₈ií٫Āen↣↭rtneqq;쀀≩︀Å↪ԀAabcefkosy⇄⇇⇱⇵⇺∘∝∯≨≽ròΠȀilmr⇐⇔⇗⇛rsðᒄf»․ilôکĀdr⇠⇤cy;䑊ƀ;cwࣴ⇫⇯ir;楈;憭ar;意irc;䄥ƀalr∁∎∓rtsĀ;u∉∊晥it»∊lip;怦con;抹r;쀀𝔥sĀew∣∩arow;椥arow;椦ʀamopr∺∾≃≞≣rr;懿tht;戻kĀlr≉≓eftarrow;憩ightarrow;憪f;쀀𝕙bar;怕ƀclt≯≴≸r;쀀𝒽asè⇴rok;䄧Ābp⊂⊇ull;恃hen»ᱛૡ⊣\0⊪\0⊸⋅⋎\0⋕⋳\0\0⋸⌢⍧⍢⍿\0⎆⎪⎴cute耻í䃭ƀ;iyݱ⊰⊵rc耻î䃮;䐸Ācx⊼⊿y;䐵cl耻¡䂡ĀfrΟ⋉;쀀𝔦rave耻ì䃬Ȁ;inoܾ⋝⋩⋮Āin⋢⋦nt;樌t;戭fin;槜ta;愩lig;䄳ƀaop⋾⌚⌝ƀcgt⌅⌈⌗r;䄫ƀelpܟ⌏⌓inåގarôܠh;䄱f;抷ed;䆵ʀ;cfotӴ⌬⌱⌽⍁are;愅inĀ;t⌸⌹戞ie;槝doô⌙ʀ;celpݗ⍌⍐⍛⍡al;抺Āgr⍕⍙eróᕣã⍍arhk;樗rod;樼Ȁcgpt⍯⍲⍶⍻y;䑑on;䄯f;쀀𝕚a;䎹uest耻¿䂿Āci⎊⎏r;쀀𝒾nʀ;EdsvӴ⎛⎝⎡ӳ;拹ot;拵Ā;v⎦⎧拴;拳Ā;iݷ⎮lde;䄩ǫ⎸\0⎼cy;䑖l耻ï䃯̀cfmosu⏌⏗⏜⏡⏧⏵Āiy⏑⏕rc;䄵;䐹r;쀀𝔧ath;䈷pf;쀀𝕛ǣ⏬\0⏱r;쀀𝒿rcy;䑘kcy;䑔Ѐacfghjos␋␖␢␧␭␱␵␻ppaĀ;v␓␔䎺;䏰Āey␛␠dil;䄷;䐺r;쀀𝔨reen;䄸cy;䑅cy;䑜pf;쀀𝕜cr;쀀𝓀஀ABEHabcdefghjlmnoprstuv⑰⒁⒆⒍⒑┎┽╚▀♎♞♥♹♽⚚⚲⛘❝❨➋⟀⠁⠒ƀart⑷⑺⑼rò৆òΕail;椛arr;椎Ā;gঔ⒋;檋ar;楢ॣ⒥\0⒪\0⒱\0\0\0\0\0⒵Ⓔ\0ⓆⓈⓍ\0⓹ute;䄺mptyv;榴raîࡌbda;䎻gƀ;dlࢎⓁⓃ;榑åࢎ;檅uo耻«䂫rЀ;bfhlpst࢙ⓞⓦⓩ⓫⓮⓱⓵Ā;f࢝ⓣs;椟s;椝ë≒p;憫l;椹im;楳l;憢ƀ;ae⓿─┄檫il;椙Ā;s┉┊檭;쀀⪭︀ƀabr┕┙┝rr;椌rk;杲Āak┢┬cĀek┨┪;䁻;䁛Āes┱┳;榋lĀdu┹┻;榏;榍Ȁaeuy╆╋╖╘ron;䄾Ādi═╔il;䄼ìࢰâ┩;䐻Ȁcqrs╣╦╭╽a;椶uoĀ;rนᝆĀdu╲╷har;楧shar;楋h;憲ʀ;fgqs▋▌উ◳◿扤tʀahlrt▘▤▷◂◨rrowĀ;t࢙□aé⓶arpoonĀdu▯▴own»њp»०eftarrows;懇ightƀahs◍◖◞rrowĀ;sࣴࢧarpoonó྘quigarro÷⇰hreetimes;拋ƀ;qs▋ও◺lanôবʀ;cdgsব☊☍☝☨c;檨otĀ;o☔☕橿Ā;r☚☛檁;檃Ā;e☢☥쀀⋚︀s;檓ʀadegs☳☹☽♉♋pproøⓆot;拖qĀgq♃♅ôউgtò⒌ôছiíলƀilr♕࣡♚sht;楼;쀀𝔩Ā;Eজ♣;檑š♩♶rĀdu▲♮Ā;l॥♳;楪lk;斄cy;䑙ʀ;achtੈ⚈⚋⚑⚖rò◁orneòᴈard;楫ri;旺Āio⚟⚤dot;䅀ustĀ;a⚬⚭掰che»⚭ȀEaes⚻⚽⛉⛔;扨pĀ;p⛃⛄檉rox»⛄Ā;q⛎⛏檇Ā;q⛎⚻im;拦Ѐabnoptwz⛩⛴⛷✚✯❁❇❐Ānr⛮⛱g;柬r;懽rëࣁgƀlmr⛿✍✔eftĀar০✇ightá৲apsto;柼ightá৽parrowĀlr✥✩efô⓭ight;憬ƀafl✶✹✽r;榅;쀀𝕝us;樭imes;樴š❋❏st;戗áፎƀ;ef❗❘᠀旊nge»❘arĀ;l❤❥䀨t;榓ʀachmt❳❶❼➅➇ròࢨorneòᶌarĀ;d྘➃;業;怎ri;抿̀achiqt➘➝ੀ➢➮➻quo;怹r;쀀𝓁mƀ;egল➪➬;檍;檏Ābu┪➳oĀ;rฟ➹;怚rok;䅂萀<;cdhilqrࠫ⟒☹⟜⟠⟥⟪⟰Āci⟗⟙;檦r;橹reå◲mes;拉arr;楶uest;橻ĀPi⟵⟹ar;榖ƀ;ef⠀भ᠛旃rĀdu⠇⠍shar;楊har;楦Āen⠗⠡rtneqq;쀀≨︀Å⠞܀Dacdefhilnopsu⡀⡅⢂⢎⢓⢠⢥⢨⣚⣢⣤ઃ⣳⤂Dot;戺Ȁclpr⡎⡒⡣⡽r耻¯䂯Āet⡗⡙;時Ā;e⡞⡟朠se»⡟Ā;sျ⡨toȀ;dluျ⡳⡷⡻owîҌefôएðᏑker;斮Āoy⢇⢌mma;権;䐼ash;怔asuredangle»ᘦr;쀀𝔪o;愧ƀcdn⢯⢴⣉ro耻µ䂵Ȁ;acdᑤ⢽⣀⣄sôᚧir;櫰ot肻·Ƶusƀ;bd⣒ᤃ⣓戒Ā;uᴼ⣘;横ţ⣞⣡p;櫛ò−ðઁĀdp⣩⣮els;抧f;쀀𝕞Āct⣸⣽r;쀀𝓂pos»ᖝƀ;lm⤉⤊⤍䎼timap;抸ఀGLRVabcdefghijlmoprstuvw⥂⥓⥾⦉⦘⧚⧩⨕⨚⩘⩝⪃⪕⪤⪨⬄⬇⭄⭿⮮ⰴⱧⱼ⳩Āgt⥇⥋;쀀⋙̸Ā;v⥐௏쀀≫⃒ƀelt⥚⥲⥶ftĀar⥡⥧rrow;懍ightarrow;懎;쀀⋘̸Ā;v⥻ే쀀≪⃒ightarrow;懏ĀDd⦎⦓ash;抯ash;抮ʀbcnpt⦣⦧⦬⦱⧌la»˞ute;䅄g;쀀∠⃒ʀ;Eiop඄⦼⧀⧅⧈;쀀⩰̸d;쀀≋̸s;䅉roø඄urĀ;a⧓⧔普lĀ;s⧓ସǳ⧟\0⧣p肻 ଷmpĀ;e௹ఀʀaeouy⧴⧾⨃⨐⨓ǰ⧹\0⧻;橃on;䅈dil;䅆ngĀ;dൾ⨊ot;쀀⩭̸p;橂;䐽ash;怓΀;Aadqsxஒ⨩⨭⨻⩁⩅⩐rr;懗rĀhr⨳⨶k;椤Ā;oᏲᏰot;쀀≐̸uiöୣĀei⩊⩎ar;椨í஘istĀ;s஠டr;쀀𝔫ȀEest௅⩦⩹⩼ƀ;qs஼⩭௡ƀ;qs஼௅⩴lanô௢ií௪Ā;rஶ⪁»ஷƀAap⪊⪍⪑rò⥱rr;憮ar;櫲ƀ;svྍ⪜ྌĀ;d⪡⪢拼;拺cy;䑚΀AEadest⪷⪺⪾⫂⫅⫶⫹rò⥦;쀀≦̸rr;憚r;急Ȁ;fqs఻⫎⫣⫯tĀar⫔⫙rro÷⫁ightarro÷⪐ƀ;qs఻⪺⫪lanôౕĀ;sౕ⫴»శiíౝĀ;rవ⫾iĀ;eచథiäඐĀpt⬌⬑f;쀀𝕟膀¬;in⬙⬚⬶䂬nȀ;Edvஉ⬤⬨⬮;쀀⋹̸ot;쀀⋵̸ǡஉ⬳⬵;拷;拶iĀ;vಸ⬼ǡಸ⭁⭃;拾;拽ƀaor⭋⭣⭩rȀ;ast୻⭕⭚⭟lleì୻l;쀀⫽⃥;쀀∂̸lint;樔ƀ;ceಒ⭰⭳uåಥĀ;cಘ⭸Ā;eಒ⭽ñಘȀAait⮈⮋⮝⮧rò⦈rrƀ;cw⮔⮕⮙憛;쀀⤳̸;쀀↝̸ghtarrow»⮕riĀ;eೋೖ΀chimpqu⮽⯍⯙⬄୸⯤⯯Ȁ;cerല⯆ഷ⯉uå൅;쀀𝓃ortɭ⬅\0\0⯖ará⭖mĀ;e൮⯟Ā;q൴൳suĀbp⯫⯭å೸åഋƀbcp⯶ⰑⰙȀ;Ees⯿ⰀഢⰄ抄;쀀⫅̸etĀ;eഛⰋqĀ;qണⰀcĀ;eലⰗñസȀ;EesⰢⰣൟⰧ抅;쀀⫆̸etĀ;e൘ⰮqĀ;qൠⰣȀgilrⰽⰿⱅⱇìௗlde耻ñ䃱çృiangleĀlrⱒⱜeftĀ;eచⱚñదightĀ;eೋⱥñ೗Ā;mⱬⱭ䎽ƀ;esⱴⱵⱹ䀣ro;愖p;怇ҀDHadgilrsⲏⲔⲙⲞⲣⲰⲶⳓⳣash;抭arr;椄p;쀀≍⃒ash;抬ĀetⲨⲬ;쀀≥⃒;쀀>⃒nfin;槞ƀAetⲽⳁⳅrr;椂;쀀≤⃒Ā;rⳊⳍ쀀<⃒ie;쀀⊴⃒ĀAtⳘⳜrr;椃rie;쀀⊵⃒im;쀀∼⃒ƀAan⳰⳴ⴂrr;懖rĀhr⳺⳽k;椣Ā;oᏧᏥear;椧ቓ᪕\0\0\0\0\0\0\0\0\0\0\0\0\0ⴭ\0ⴸⵈⵠⵥ⵲ⶄᬇ\0\0ⶍⶫ\0ⷈⷎ\0ⷜ⸙⸫⸾⹃Ācsⴱ᪗ute耻ó䃳ĀiyⴼⵅrĀ;c᪞ⵂ耻ô䃴;䐾ʀabios᪠ⵒⵗǈⵚlac;䅑v;樸old;榼lig;䅓Ācr⵩⵭ir;榿;쀀𝔬ͯ⵹\0\0⵼\0ⶂn;䋛ave耻ò䃲;槁Ābmⶈ෴ar;榵Ȁacitⶕ⶘ⶥⶨrò᪀Āir⶝ⶠr;榾oss;榻nå๒;槀ƀaeiⶱⶵⶹcr;䅍ga;䏉ƀcdnⷀⷅǍron;䎿;榶pf;쀀𝕠ƀaelⷔ⷗ǒr;榷rp;榹΀;adiosvⷪⷫⷮ⸈⸍⸐⸖戨rò᪆Ȁ;efmⷷⷸ⸂⸅橝rĀ;oⷾⷿ愴f»ⷿ耻ª䂪耻º䂺gof;抶r;橖lope;橗;橛ƀclo⸟⸡⸧ò⸁ash耻ø䃸l;折iŬⸯ⸴de耻õ䃵esĀ;aǛ⸺s;樶ml耻ö䃶bar;挽ૡ⹞\0⹽\0⺀⺝\0⺢⺹\0\0⻋ຜ\0⼓\0\0⼫⾼\0⿈rȀ;astЃ⹧⹲຅脀¶;l⹭⹮䂶leìЃɩ⹸\0\0⹻m;櫳;櫽y;䐿rʀcimpt⺋⺏⺓ᡥ⺗nt;䀥od;䀮il;怰enk;怱r;쀀𝔭ƀimo⺨⺰⺴Ā;v⺭⺮䏆;䏕maô੶ne;明ƀ;tv⺿⻀⻈䏀chfork»´;䏖Āau⻏⻟nĀck⻕⻝kĀ;h⇴⻛;愎ö⇴sҀ;abcdemst⻳⻴ᤈ⻹⻽⼄⼆⼊⼎䀫cir;樣ir;樢Āouᵀ⼂;樥;橲n肻±ຝim;樦wo;樧ƀipu⼙⼠⼥ntint;樕f;쀀𝕡nd耻£䂣Ԁ;Eaceinosu່⼿⽁⽄⽇⾁⾉⾒⽾⾶;檳p;檷uå໙Ā;c໎⽌̀;acens່⽙⽟⽦⽨⽾pproø⽃urlyeñ໙ñ໎ƀaes⽯⽶⽺pprox;檹qq;檵im;拨iíໟmeĀ;s⾈ຮ怲ƀEas⽸⾐⽺ð⽵ƀdfp໬⾙⾯ƀals⾠⾥⾪lar;挮ine;挒urf;挓Ā;t໻⾴ï໻rel;抰Āci⿀⿅r;쀀𝓅;䏈ncsp;怈̀fiopsu⿚⋢⿟⿥⿫⿱r;쀀𝔮pf;쀀𝕢rime;恗cr;쀀𝓆ƀaeo⿸〉〓tĀei⿾々rnionóڰnt;樖stĀ;e【】䀿ñἙô༔઀ABHabcdefhilmnoprstux぀けさすムㄎㄫㅇㅢㅲㆎ㈆㈕㈤㈩㉘㉮㉲㊐㊰㊷ƀartぇおがròႳòϝail;検aròᱥar;楤΀cdenqrtとふへみわゔヌĀeuねぱ;쀀∽̱te;䅕iãᅮmptyv;榳gȀ;del࿑らるろ;榒;榥å࿑uo耻»䂻rր;abcfhlpstw࿜ガクシスゼゾダッデナp;極Ā;f࿠ゴs;椠;椳s;椞ë≝ð✮l;楅im;楴l;憣;憝Āaiパフil;椚oĀ;nホボ戶aló༞ƀabrョリヮrò៥rk;杳ĀakンヽcĀekヹ・;䁽;䁝Āes㄂㄄;榌lĀduㄊㄌ;榎;榐Ȁaeuyㄗㄜㄧㄩron;䅙Ādiㄡㄥil;䅗ì࿲âヺ;䑀Ȁclqsㄴㄷㄽㅄa;椷dhar;楩uoĀ;rȎȍh;憳ƀacgㅎㅟངlȀ;ipsླྀㅘㅛႜnåႻarôྩt;断ƀilrㅩဣㅮsht;楽;쀀𝔯ĀaoㅷㆆrĀduㅽㅿ»ѻĀ;l႑ㆄ;楬Ā;vㆋㆌ䏁;䏱ƀgns㆕ㇹㇼht̀ahlrstㆤㆰ㇂㇘㇤㇮rrowĀ;t࿜ㆭaéトarpoonĀduㆻㆿowîㅾp»႒eftĀah㇊㇐rrowó࿪arpoonóՑightarrows;應quigarro÷ニhreetimes;拌g;䋚ingdotseñἲƀahm㈍㈐㈓rò࿪aòՑ;怏oustĀ;a㈞㈟掱che»㈟mid;櫮Ȁabpt㈲㈽㉀㉒Ānr㈷㈺g;柭r;懾rëဃƀafl㉇㉊㉎r;榆;쀀𝕣us;樮imes;樵Āap㉝㉧rĀ;g㉣㉤䀩t;榔olint;樒arò㇣Ȁachq㉻㊀Ⴜ㊅quo;怺r;쀀𝓇Ābu・㊊oĀ;rȔȓƀhir㊗㊛㊠reåㇸmes;拊iȀ;efl㊪ၙᠡ㊫方tri;槎luhar;楨;愞ൡ㋕㋛㋟㌬㌸㍱\0㍺㎤\0\0㏬㏰\0㐨㑈㑚㒭㒱㓊㓱\0㘖\0\0㘳cute;䅛quï➺Ԁ;Eaceinpsyᇭ㋳㋵㋿㌂㌋㌏㌟㌦㌩;檴ǰ㋺\0㋼;檸on;䅡uåᇾĀ;dᇳ㌇il;䅟rc;䅝ƀEas㌖㌘㌛;檶p;檺im;择olint;樓iíሄ;䑁otƀ;be㌴ᵇ㌵担;橦΀Aacmstx㍆㍊㍗㍛㍞㍣㍭rr;懘rĀhr㍐㍒ë∨Ā;oਸ਼਴t耻§䂧i;䀻war;椩mĀin㍩ðnuóñt;朶rĀ;o㍶⁕쀀𝔰Ȁacoy㎂㎆㎑㎠rp;景Āhy㎋㎏cy;䑉;䑈rtɭ㎙\0\0㎜iäᑤaraì⹯耻­䂭Āgm㎨㎴maƀ;fv㎱㎲㎲䏃;䏂Ѐ;deglnprካ㏅㏉㏎㏖㏞㏡㏦ot;橪Ā;q኱ኰĀ;E㏓㏔檞;檠Ā;E㏛㏜檝;檟e;扆lus;樤arr;楲aròᄽȀaeit㏸㐈㐏㐗Āls㏽㐄lsetmé㍪hp;樳parsl;槤Ādlᑣ㐔e;挣Ā;e㐜㐝檪Ā;s㐢㐣檬;쀀⪬︀ƀflp㐮㐳㑂tcy;䑌Ā;b㐸㐹䀯Ā;a㐾㐿槄r;挿f;쀀𝕤aĀdr㑍ЂesĀ;u㑔㑕晠it»㑕ƀcsu㑠㑹㒟Āau㑥㑯pĀ;sᆈ㑫;쀀⊓︀pĀ;sᆴ㑵;쀀⊔︀uĀbp㑿㒏ƀ;esᆗᆜ㒆etĀ;eᆗ㒍ñᆝƀ;esᆨᆭ㒖etĀ;eᆨ㒝ñᆮƀ;afᅻ㒦ְrť㒫ֱ»ᅼaròᅈȀcemt㒹㒾㓂㓅r;쀀𝓈tmîñiì㐕aræᆾĀar㓎㓕rĀ;f㓔ឿ昆Āan㓚㓭ightĀep㓣㓪psiloîỠhé⺯s»⡒ʀbcmnp㓻㕞ሉ㖋㖎Ҁ;Edemnprs㔎㔏㔑㔕㔞㔣㔬㔱㔶抂;櫅ot;檽Ā;dᇚ㔚ot;櫃ult;櫁ĀEe㔨㔪;櫋;把lus;檿arr;楹ƀeiu㔽㕒㕕tƀ;en㔎㕅㕋qĀ;qᇚ㔏eqĀ;q㔫㔨m;櫇Ābp㕚㕜;櫕;櫓c̀;acensᇭ㕬㕲㕹㕻㌦pproø㋺urlyeñᇾñᇳƀaes㖂㖈㌛pproø㌚qñ㌗g;晪ڀ123;Edehlmnps㖩㖬㖯ሜ㖲㖴㗀㗉㗕㗚㗟㗨㗭耻¹䂹耻²䂲耻³䂳;櫆Āos㖹㖼t;檾ub;櫘Ā;dሢ㗅ot;櫄sĀou㗏㗒l;柉b;櫗arr;楻ult;櫂ĀEe㗤㗦;櫌;抋lus;櫀ƀeiu㗴㘉㘌tƀ;enሜ㗼㘂qĀ;qሢ㖲eqĀ;q㗧㗤m;櫈Ābp㘑㘓;櫔;櫖ƀAan㘜㘠㘭rr;懙rĀhr㘦㘨ë∮Ā;oਫ਩war;椪lig耻ß䃟௡㙑㙝㙠ዎ㙳㙹\0㙾㛂\0\0\0\0\0㛛㜃\0㜉㝬\0\0\0㞇ɲ㙖\0\0㙛get;挖;䏄rë๟ƀaey㙦㙫㙰ron;䅥dil;䅣;䑂lrec;挕r;쀀𝔱Ȁeiko㚆㚝㚵㚼ǲ㚋\0㚑eĀ4fኄኁaƀ;sv㚘㚙㚛䎸ym;䏑Ācn㚢㚲kĀas㚨㚮pproø዁im»ኬsðኞĀas㚺㚮ð዁rn耻þ䃾Ǭ̟㛆⋧es膀×;bd㛏㛐㛘䃗Ā;aᤏ㛕r;樱;樰ƀeps㛡㛣㜀á⩍Ȁ;bcf҆㛬㛰㛴ot;挶ir;櫱Ā;o㛹㛼쀀𝕥rk;櫚á㍢rime;怴ƀaip㜏㜒㝤dåቈ΀adempst㜡㝍㝀㝑㝗㝜㝟ngleʀ;dlqr㜰㜱㜶㝀㝂斵own»ᶻeftĀ;e⠀㜾ñम;扜ightĀ;e㊪㝋ñၚot;旬inus;樺lus;樹b;槍ime;樻ezium;揢ƀcht㝲㝽㞁Āry㝷㝻;쀀𝓉;䑆cy;䑛rok;䅧Āio㞋㞎xô᝷headĀlr㞗㞠eftarro÷ࡏightarrow»ཝऀAHabcdfghlmoprstuw㟐㟓㟗㟤㟰㟼㠎㠜㠣㠴㡑㡝㡫㢩㣌㣒㣪㣶ròϭar;楣Ācr㟜㟢ute耻ú䃺òᅐrǣ㟪\0㟭y;䑞ve;䅭Āiy㟵㟺rc耻û䃻;䑃ƀabh㠃㠆㠋ròᎭlac;䅱aòᏃĀir㠓㠘sht;楾;쀀𝔲rave耻ù䃹š㠧㠱rĀlr㠬㠮»ॗ»ႃlk;斀Āct㠹㡍ɯ㠿\0\0㡊rnĀ;e㡅㡆挜r»㡆op;挏ri;旸Āal㡖㡚cr;䅫肻¨͉Āgp㡢㡦on;䅳f;쀀𝕦̀adhlsuᅋ㡸㡽፲㢑㢠ownáᎳarpoonĀlr㢈㢌efô㠭ighô㠯iƀ;hl㢙㢚㢜䏅»ᏺon»㢚parrows;懈ƀcit㢰㣄㣈ɯ㢶\0\0㣁rnĀ;e㢼㢽挝r»㢽op;挎ng;䅯ri;旹cr;쀀𝓊ƀdir㣙㣝㣢ot;拰lde;䅩iĀ;f㜰㣨»᠓Āam㣯㣲rò㢨l耻ü䃼angle;榧ހABDacdeflnoprsz㤜㤟㤩㤭㦵㦸㦽㧟㧤㧨㧳㧹㧽㨁㨠ròϷarĀ;v㤦㤧櫨;櫩asèϡĀnr㤲㤷grt;榜΀eknprst㓣㥆㥋㥒㥝㥤㦖appá␕othinçẖƀhir㓫⻈㥙opô⾵Ā;hᎷ㥢ïㆍĀiu㥩㥭gmá㎳Ābp㥲㦄setneqĀ;q㥽㦀쀀⊊︀;쀀⫋︀setneqĀ;q㦏㦒쀀⊋︀;쀀⫌︀Āhr㦛㦟etá㚜iangleĀlr㦪㦯eft»थight»ၑy;䐲ash»ံƀelr㧄㧒㧗ƀ;beⷪ㧋㧏ar;抻q;扚lip;拮Ābt㧜ᑨaòᑩr;쀀𝔳tré㦮suĀbp㧯㧱»ജ»൙pf;쀀𝕧roð໻tré㦴Ācu㨆㨋r;쀀𝓋Ābp㨐㨘nĀEe㦀㨖»㥾nĀEe㦒㨞»㦐igzag;榚΀cefoprs㨶㨻㩖㩛㩔㩡㩪irc;䅵Ādi㩀㩑Ābg㩅㩉ar;機eĀ;qᗺ㩏;扙erp;愘r;쀀𝔴pf;쀀𝕨Ā;eᑹ㩦atèᑹcr;쀀𝓌ૣណ㪇\0㪋\0㪐㪛\0\0㪝㪨㪫㪯\0\0㫃㫎\0㫘ៜ៟tré៑r;쀀𝔵ĀAa㪔㪗ròσrò৶;䎾ĀAa㪡㪤ròθrò৫að✓is;拻ƀdptឤ㪵㪾Āfl㪺ឩ;쀀𝕩imåឲĀAa㫇㫊ròώròਁĀcq㫒ីr;쀀𝓍Āpt៖㫜ré។Ѐacefiosu㫰㫽㬈㬌㬑㬕㬛㬡cĀuy㫶㫻te耻ý䃽;䑏Āiy㬂㬆rc;䅷;䑋n耻¥䂥r;쀀𝔶cy;䑗pf;쀀𝕪cr;쀀𝓎Ācm㬦㬩y;䑎l耻ÿ䃿Ԁacdefhiosw㭂㭈㭔㭘㭤㭩㭭㭴㭺㮀cute;䅺Āay㭍㭒ron;䅾;䐷ot;䅼Āet㭝㭡træᕟa;䎶r;쀀𝔷cy;䐶grarr;懝pf;쀀𝕫cr;쀀𝓏Ājn㮅㮇;怍j;怌'.split("").map(function(e) {
      return e.charCodeAt(0);
    })
  )), nu;
}
var au = {}, v0;
function Ss() {
  return v0 || (v0 = 1, Object.defineProperty(au, "__esModule", { value: !0 }), au.default = new Uint16Array(
    // prettier-ignore
    "Ȁaglq	\x1Bɭ\0\0p;䀦os;䀧t;䀾t;䀼uot;䀢".split("").map(function(e) {
      return e.charCodeAt(0);
    })
  )), au;
}
var Gu = {}, E0;
function D0() {
  return E0 || (E0 = 1, (function(e) {
    var u;
    Object.defineProperty(e, "__esModule", { value: !0 }), e.replaceCodePoint = e.fromCodePoint = void 0;
    var t = /* @__PURE__ */ new Map([
      [0, 65533],
      // C1 Unicode control character reference replacements
      [128, 8364],
      [130, 8218],
      [131, 402],
      [132, 8222],
      [133, 8230],
      [134, 8224],
      [135, 8225],
      [136, 710],
      [137, 8240],
      [138, 352],
      [139, 8249],
      [140, 338],
      [142, 381],
      [145, 8216],
      [146, 8217],
      [147, 8220],
      [148, 8221],
      [149, 8226],
      [150, 8211],
      [151, 8212],
      [152, 732],
      [153, 8482],
      [154, 353],
      [155, 8250],
      [156, 339],
      [158, 382],
      [159, 376]
    ]);
    e.fromCodePoint = // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition, node/no-unsupported-features/es-builtins
    (u = String.fromCodePoint) !== null && u !== void 0 ? u : function(i) {
      var l = "";
      return i > 65535 && (i -= 65536, l += String.fromCharCode(i >>> 10 & 1023 | 55296), i = 56320 | i & 1023), l += String.fromCharCode(i), l;
    };
    function c(i) {
      var l;
      return i >= 55296 && i <= 57343 || i > 1114111 ? 65533 : (l = t.get(i)) !== null && l !== void 0 ? l : i;
    }
    e.replaceCodePoint = c;
    function s(i) {
      return (0, e.fromCodePoint)(c(i));
    }
    e.default = s;
  })(Gu)), Gu;
}
var I0;
function _0() {
  return I0 || (I0 = 1, (function(e) {
    var u = se && se.__createBinding || (Object.create ? (function(E, k, F, T) {
      T === void 0 && (T = F);
      var B = Object.getOwnPropertyDescriptor(k, F);
      (!B || ("get" in B ? !k.__esModule : B.writable || B.configurable)) && (B = { enumerable: !0, get: function() {
        return k[F];
      } }), Object.defineProperty(E, T, B);
    }) : (function(E, k, F, T) {
      T === void 0 && (T = F), E[T] = k[F];
    })), t = se && se.__setModuleDefault || (Object.create ? (function(E, k) {
      Object.defineProperty(E, "default", { enumerable: !0, value: k });
    }) : function(E, k) {
      E.default = k;
    }), c = se && se.__importStar || function(E) {
      if (E && E.__esModule) return E;
      var k = {};
      if (E != null) for (var F in E) F !== "default" && Object.prototype.hasOwnProperty.call(E, F) && u(k, E, F);
      return t(k, E), k;
    }, s = se && se.__importDefault || function(E) {
      return E && E.__esModule ? E : { default: E };
    };
    Object.defineProperty(e, "__esModule", { value: !0 }), e.decodeXML = e.decodeHTMLStrict = e.decodeHTMLAttribute = e.decodeHTML = e.determineBranch = e.EntityDecoder = e.DecodingMode = e.BinTrieFlags = e.fromCodePoint = e.replaceCodePoint = e.decodeCodePoint = e.xmlDecodeTree = e.htmlDecodeTree = void 0;
    var i = s(/* @__PURE__ */ Fs());
    e.htmlDecodeTree = i.default;
    var l = s(/* @__PURE__ */ Ss());
    e.xmlDecodeTree = l.default;
    var a = c(/* @__PURE__ */ D0());
    e.decodeCodePoint = a.default;
    var o = /* @__PURE__ */ D0();
    Object.defineProperty(e, "replaceCodePoint", { enumerable: !0, get: function() {
      return o.replaceCodePoint;
    } }), Object.defineProperty(e, "fromCodePoint", { enumerable: !0, get: function() {
      return o.fromCodePoint;
    } });
    var r;
    (function(E) {
      E[E.NUM = 35] = "NUM", E[E.SEMI = 59] = "SEMI", E[E.EQUALS = 61] = "EQUALS", E[E.ZERO = 48] = "ZERO", E[E.NINE = 57] = "NINE", E[E.LOWER_A = 97] = "LOWER_A", E[E.LOWER_F = 102] = "LOWER_F", E[E.LOWER_X = 120] = "LOWER_X", E[E.LOWER_Z = 122] = "LOWER_Z", E[E.UPPER_A = 65] = "UPPER_A", E[E.UPPER_F = 70] = "UPPER_F", E[E.UPPER_Z = 90] = "UPPER_Z";
    })(r || (r = {}));
    var n = 32, f;
    (function(E) {
      E[E.VALUE_LENGTH = 49152] = "VALUE_LENGTH", E[E.BRANCH_LENGTH = 16256] = "BRANCH_LENGTH", E[E.JUMP_TABLE = 127] = "JUMP_TABLE";
    })(f = e.BinTrieFlags || (e.BinTrieFlags = {}));
    function d(E) {
      return E >= r.ZERO && E <= r.NINE;
    }
    function A(E) {
      return E >= r.UPPER_A && E <= r.UPPER_F || E >= r.LOWER_A && E <= r.LOWER_F;
    }
    function h(E) {
      return E >= r.UPPER_A && E <= r.UPPER_Z || E >= r.LOWER_A && E <= r.LOWER_Z || d(E);
    }
    function w(E) {
      return E === r.EQUALS || h(E);
    }
    var C;
    (function(E) {
      E[E.EntityStart = 0] = "EntityStart", E[E.NumericStart = 1] = "NumericStart", E[E.NumericDecimal = 2] = "NumericDecimal", E[E.NumericHex = 3] = "NumericHex", E[E.NamedEntity = 4] = "NamedEntity";
    })(C || (C = {}));
    var b;
    (function(E) {
      E[E.Legacy = 0] = "Legacy", E[E.Strict = 1] = "Strict", E[E.Attribute = 2] = "Attribute";
    })(b = e.DecodingMode || (e.DecodingMode = {}));
    var m = (
      /** @class */
      (function() {
        function E(k, F, T) {
          this.decodeTree = k, this.emitCodePoint = F, this.errors = T, this.state = C.EntityStart, this.consumed = 1, this.result = 0, this.treeIndex = 0, this.excess = 1, this.decodeMode = b.Strict;
        }
        return E.prototype.startEntity = function(k) {
          this.decodeMode = k, this.state = C.EntityStart, this.result = 0, this.treeIndex = 0, this.excess = 1, this.consumed = 1;
        }, E.prototype.write = function(k, F) {
          switch (this.state) {
            case C.EntityStart:
              return k.charCodeAt(F) === r.NUM ? (this.state = C.NumericStart, this.consumed += 1, this.stateNumericStart(k, F + 1)) : (this.state = C.NamedEntity, this.stateNamedEntity(k, F));
            case C.NumericStart:
              return this.stateNumericStart(k, F);
            case C.NumericDecimal:
              return this.stateNumericDecimal(k, F);
            case C.NumericHex:
              return this.stateNumericHex(k, F);
            case C.NamedEntity:
              return this.stateNamedEntity(k, F);
          }
        }, E.prototype.stateNumericStart = function(k, F) {
          return F >= k.length ? -1 : (k.charCodeAt(F) | n) === r.LOWER_X ? (this.state = C.NumericHex, this.consumed += 1, this.stateNumericHex(k, F + 1)) : (this.state = C.NumericDecimal, this.stateNumericDecimal(k, F));
        }, E.prototype.addToNumericResult = function(k, F, T, B) {
          if (F !== T) {
            var O = T - F;
            this.result = this.result * Math.pow(B, O) + parseInt(k.substr(F, O), B), this.consumed += O;
          }
        }, E.prototype.stateNumericHex = function(k, F) {
          for (var T = F; F < k.length; ) {
            var B = k.charCodeAt(F);
            if (d(B) || A(B))
              F += 1;
            else
              return this.addToNumericResult(k, T, F, 16), this.emitNumericEntity(B, 3);
          }
          return this.addToNumericResult(k, T, F, 16), -1;
        }, E.prototype.stateNumericDecimal = function(k, F) {
          for (var T = F; F < k.length; ) {
            var B = k.charCodeAt(F);
            if (d(B))
              F += 1;
            else
              return this.addToNumericResult(k, T, F, 10), this.emitNumericEntity(B, 2);
          }
          return this.addToNumericResult(k, T, F, 10), -1;
        }, E.prototype.emitNumericEntity = function(k, F) {
          var T;
          if (this.consumed <= F)
            return (T = this.errors) === null || T === void 0 || T.absenceOfDigitsInNumericCharacterReference(this.consumed), 0;
          if (k === r.SEMI)
            this.consumed += 1;
          else if (this.decodeMode === b.Strict)
            return 0;
          return this.emitCodePoint((0, a.replaceCodePoint)(this.result), this.consumed), this.errors && (k !== r.SEMI && this.errors.missingSemicolonAfterCharacterReference(), this.errors.validateNumericCharacterReference(this.result)), this.consumed;
        }, E.prototype.stateNamedEntity = function(k, F) {
          for (var T = this.decodeTree, B = T[this.treeIndex], O = (B & f.VALUE_LENGTH) >> 14; F < k.length; F++, this.excess++) {
            var Q = k.charCodeAt(F);
            if (this.treeIndex = x(T, B, this.treeIndex + Math.max(1, O), Q), this.treeIndex < 0)
              return this.result === 0 || // If we are parsing an attribute
              this.decodeMode === b.Attribute && // We shouldn't have consumed any characters after the entity,
              (O === 0 || // And there should be no invalid characters.
              w(Q)) ? 0 : this.emitNotTerminatedNamedEntity();
            if (B = T[this.treeIndex], O = (B & f.VALUE_LENGTH) >> 14, O !== 0) {
              if (Q === r.SEMI)
                return this.emitNamedEntityData(this.treeIndex, O, this.consumed + this.excess);
              this.decodeMode !== b.Strict && (this.result = this.treeIndex, this.consumed += this.excess, this.excess = 0);
            }
          }
          return -1;
        }, E.prototype.emitNotTerminatedNamedEntity = function() {
          var k, F = this, T = F.result, B = F.decodeTree, O = (B[T] & f.VALUE_LENGTH) >> 14;
          return this.emitNamedEntityData(T, O, this.consumed), (k = this.errors) === null || k === void 0 || k.missingSemicolonAfterCharacterReference(), this.consumed;
        }, E.prototype.emitNamedEntityData = function(k, F, T) {
          var B = this.decodeTree;
          return this.emitCodePoint(F === 1 ? B[k] & ~f.VALUE_LENGTH : B[k + 1], T), F === 3 && this.emitCodePoint(B[k + 2], T), T;
        }, E.prototype.end = function() {
          var k;
          switch (this.state) {
            case C.NamedEntity:
              return this.result !== 0 && (this.decodeMode !== b.Attribute || this.result === this.treeIndex) ? this.emitNotTerminatedNamedEntity() : 0;
            // Otherwise, emit a numeric entity if we have one.
            case C.NumericDecimal:
              return this.emitNumericEntity(0, 2);
            case C.NumericHex:
              return this.emitNumericEntity(0, 3);
            case C.NumericStart:
              return (k = this.errors) === null || k === void 0 || k.absenceOfDigitsInNumericCharacterReference(this.consumed), 0;
            case C.EntityStart:
              return 0;
          }
        }, E;
      })()
    );
    e.EntityDecoder = m;
    function g(E) {
      var k = "", F = new m(E, function(T) {
        return k += (0, a.fromCodePoint)(T);
      });
      return function(B, O) {
        for (var Q = 0, L = 0; (L = B.indexOf("&", L)) >= 0; ) {
          k += B.slice(Q, L), F.startEntity(O);
          var K = F.write(
            B,
            // Skip the "&"
            L + 1
          );
          if (K < 0) {
            Q = L + F.end();
            break;
          }
          Q = L + K, L = K === 0 ? Q + 1 : Q;
        }
        var j = k + B.slice(Q);
        return k = "", j;
      };
    }
    function x(E, k, F, T) {
      var B = (k & f.BRANCH_LENGTH) >> 7, O = k & f.JUMP_TABLE;
      if (B === 0)
        return O !== 0 && T === O ? F : -1;
      if (O) {
        var Q = T - O;
        return Q < 0 || Q >= B ? -1 : E[F + Q] - 1;
      }
      for (var L = F, K = L + B - 1; L <= K; ) {
        var j = L + K >>> 1, ee = E[j];
        if (ee < T)
          L = j + 1;
        else if (ee > T)
          K = j - 1;
        else
          return E[j + B];
      }
      return -1;
    }
    e.determineBranch = x;
    var p = g(i.default), y = g(l.default);
    function v(E, k) {
      return k === void 0 && (k = b.Legacy), p(E, k);
    }
    e.decodeHTML = v;
    function I(E) {
      return p(E, b.Attribute);
    }
    e.decodeHTMLAttribute = I;
    function D(E) {
      return p(E, b.Strict);
    }
    e.decodeHTMLStrict = D;
    function _(E) {
      return y(E, b.Strict);
    }
    e.decodeXML = _;
  })(se)), se;
}
var ge = {}, su = {}, k0;
function Rs() {
  if (k0) return su;
  k0 = 1, Object.defineProperty(su, "__esModule", { value: !0 });
  function e(u) {
    for (var t = 1; t < u.length; t++)
      u[t][0] += u[t - 1][0] + 1;
    return u;
  }
  return su.default = new Map(/* @__PURE__ */ e([[9, "&Tab;"], [0, "&NewLine;"], [22, "&excl;"], [0, "&quot;"], [0, "&num;"], [0, "&dollar;"], [0, "&percnt;"], [0, "&amp;"], [0, "&apos;"], [0, "&lpar;"], [0, "&rpar;"], [0, "&ast;"], [0, "&plus;"], [0, "&comma;"], [1, "&period;"], [0, "&sol;"], [10, "&colon;"], [0, "&semi;"], [0, { v: "&lt;", n: 8402, o: "&nvlt;" }], [0, { v: "&equals;", n: 8421, o: "&bne;" }], [0, { v: "&gt;", n: 8402, o: "&nvgt;" }], [0, "&quest;"], [0, "&commat;"], [26, "&lbrack;"], [0, "&bsol;"], [0, "&rbrack;"], [0, "&Hat;"], [0, "&lowbar;"], [0, "&DiacriticalGrave;"], [5, { n: 106, o: "&fjlig;" }], [20, "&lbrace;"], [0, "&verbar;"], [0, "&rbrace;"], [34, "&nbsp;"], [0, "&iexcl;"], [0, "&cent;"], [0, "&pound;"], [0, "&curren;"], [0, "&yen;"], [0, "&brvbar;"], [0, "&sect;"], [0, "&die;"], [0, "&copy;"], [0, "&ordf;"], [0, "&laquo;"], [0, "&not;"], [0, "&shy;"], [0, "&circledR;"], [0, "&macr;"], [0, "&deg;"], [0, "&PlusMinus;"], [0, "&sup2;"], [0, "&sup3;"], [0, "&acute;"], [0, "&micro;"], [0, "&para;"], [0, "&centerdot;"], [0, "&cedil;"], [0, "&sup1;"], [0, "&ordm;"], [0, "&raquo;"], [0, "&frac14;"], [0, "&frac12;"], [0, "&frac34;"], [0, "&iquest;"], [0, "&Agrave;"], [0, "&Aacute;"], [0, "&Acirc;"], [0, "&Atilde;"], [0, "&Auml;"], [0, "&angst;"], [0, "&AElig;"], [0, "&Ccedil;"], [0, "&Egrave;"], [0, "&Eacute;"], [0, "&Ecirc;"], [0, "&Euml;"], [0, "&Igrave;"], [0, "&Iacute;"], [0, "&Icirc;"], [0, "&Iuml;"], [0, "&ETH;"], [0, "&Ntilde;"], [0, "&Ograve;"], [0, "&Oacute;"], [0, "&Ocirc;"], [0, "&Otilde;"], [0, "&Ouml;"], [0, "&times;"], [0, "&Oslash;"], [0, "&Ugrave;"], [0, "&Uacute;"], [0, "&Ucirc;"], [0, "&Uuml;"], [0, "&Yacute;"], [0, "&THORN;"], [0, "&szlig;"], [0, "&agrave;"], [0, "&aacute;"], [0, "&acirc;"], [0, "&atilde;"], [0, "&auml;"], [0, "&aring;"], [0, "&aelig;"], [0, "&ccedil;"], [0, "&egrave;"], [0, "&eacute;"], [0, "&ecirc;"], [0, "&euml;"], [0, "&igrave;"], [0, "&iacute;"], [0, "&icirc;"], [0, "&iuml;"], [0, "&eth;"], [0, "&ntilde;"], [0, "&ograve;"], [0, "&oacute;"], [0, "&ocirc;"], [0, "&otilde;"], [0, "&ouml;"], [0, "&div;"], [0, "&oslash;"], [0, "&ugrave;"], [0, "&uacute;"], [0, "&ucirc;"], [0, "&uuml;"], [0, "&yacute;"], [0, "&thorn;"], [0, "&yuml;"], [0, "&Amacr;"], [0, "&amacr;"], [0, "&Abreve;"], [0, "&abreve;"], [0, "&Aogon;"], [0, "&aogon;"], [0, "&Cacute;"], [0, "&cacute;"], [0, "&Ccirc;"], [0, "&ccirc;"], [0, "&Cdot;"], [0, "&cdot;"], [0, "&Ccaron;"], [0, "&ccaron;"], [0, "&Dcaron;"], [0, "&dcaron;"], [0, "&Dstrok;"], [0, "&dstrok;"], [0, "&Emacr;"], [0, "&emacr;"], [2, "&Edot;"], [0, "&edot;"], [0, "&Eogon;"], [0, "&eogon;"], [0, "&Ecaron;"], [0, "&ecaron;"], [0, "&Gcirc;"], [0, "&gcirc;"], [0, "&Gbreve;"], [0, "&gbreve;"], [0, "&Gdot;"], [0, "&gdot;"], [0, "&Gcedil;"], [1, "&Hcirc;"], [0, "&hcirc;"], [0, "&Hstrok;"], [0, "&hstrok;"], [0, "&Itilde;"], [0, "&itilde;"], [0, "&Imacr;"], [0, "&imacr;"], [2, "&Iogon;"], [0, "&iogon;"], [0, "&Idot;"], [0, "&imath;"], [0, "&IJlig;"], [0, "&ijlig;"], [0, "&Jcirc;"], [0, "&jcirc;"], [0, "&Kcedil;"], [0, "&kcedil;"], [0, "&kgreen;"], [0, "&Lacute;"], [0, "&lacute;"], [0, "&Lcedil;"], [0, "&lcedil;"], [0, "&Lcaron;"], [0, "&lcaron;"], [0, "&Lmidot;"], [0, "&lmidot;"], [0, "&Lstrok;"], [0, "&lstrok;"], [0, "&Nacute;"], [0, "&nacute;"], [0, "&Ncedil;"], [0, "&ncedil;"], [0, "&Ncaron;"], [0, "&ncaron;"], [0, "&napos;"], [0, "&ENG;"], [0, "&eng;"], [0, "&Omacr;"], [0, "&omacr;"], [2, "&Odblac;"], [0, "&odblac;"], [0, "&OElig;"], [0, "&oelig;"], [0, "&Racute;"], [0, "&racute;"], [0, "&Rcedil;"], [0, "&rcedil;"], [0, "&Rcaron;"], [0, "&rcaron;"], [0, "&Sacute;"], [0, "&sacute;"], [0, "&Scirc;"], [0, "&scirc;"], [0, "&Scedil;"], [0, "&scedil;"], [0, "&Scaron;"], [0, "&scaron;"], [0, "&Tcedil;"], [0, "&tcedil;"], [0, "&Tcaron;"], [0, "&tcaron;"], [0, "&Tstrok;"], [0, "&tstrok;"], [0, "&Utilde;"], [0, "&utilde;"], [0, "&Umacr;"], [0, "&umacr;"], [0, "&Ubreve;"], [0, "&ubreve;"], [0, "&Uring;"], [0, "&uring;"], [0, "&Udblac;"], [0, "&udblac;"], [0, "&Uogon;"], [0, "&uogon;"], [0, "&Wcirc;"], [0, "&wcirc;"], [0, "&Ycirc;"], [0, "&ycirc;"], [0, "&Yuml;"], [0, "&Zacute;"], [0, "&zacute;"], [0, "&Zdot;"], [0, "&zdot;"], [0, "&Zcaron;"], [0, "&zcaron;"], [19, "&fnof;"], [34, "&imped;"], [63, "&gacute;"], [65, "&jmath;"], [142, "&circ;"], [0, "&caron;"], [16, "&breve;"], [0, "&DiacriticalDot;"], [0, "&ring;"], [0, "&ogon;"], [0, "&DiacriticalTilde;"], [0, "&dblac;"], [51, "&DownBreve;"], [127, "&Alpha;"], [0, "&Beta;"], [0, "&Gamma;"], [0, "&Delta;"], [0, "&Epsilon;"], [0, "&Zeta;"], [0, "&Eta;"], [0, "&Theta;"], [0, "&Iota;"], [0, "&Kappa;"], [0, "&Lambda;"], [0, "&Mu;"], [0, "&Nu;"], [0, "&Xi;"], [0, "&Omicron;"], [0, "&Pi;"], [0, "&Rho;"], [1, "&Sigma;"], [0, "&Tau;"], [0, "&Upsilon;"], [0, "&Phi;"], [0, "&Chi;"], [0, "&Psi;"], [0, "&ohm;"], [7, "&alpha;"], [0, "&beta;"], [0, "&gamma;"], [0, "&delta;"], [0, "&epsi;"], [0, "&zeta;"], [0, "&eta;"], [0, "&theta;"], [0, "&iota;"], [0, "&kappa;"], [0, "&lambda;"], [0, "&mu;"], [0, "&nu;"], [0, "&xi;"], [0, "&omicron;"], [0, "&pi;"], [0, "&rho;"], [0, "&sigmaf;"], [0, "&sigma;"], [0, "&tau;"], [0, "&upsi;"], [0, "&phi;"], [0, "&chi;"], [0, "&psi;"], [0, "&omega;"], [7, "&thetasym;"], [0, "&Upsi;"], [2, "&phiv;"], [0, "&piv;"], [5, "&Gammad;"], [0, "&digamma;"], [18, "&kappav;"], [0, "&rhov;"], [3, "&epsiv;"], [0, "&backepsilon;"], [10, "&IOcy;"], [0, "&DJcy;"], [0, "&GJcy;"], [0, "&Jukcy;"], [0, "&DScy;"], [0, "&Iukcy;"], [0, "&YIcy;"], [0, "&Jsercy;"], [0, "&LJcy;"], [0, "&NJcy;"], [0, "&TSHcy;"], [0, "&KJcy;"], [1, "&Ubrcy;"], [0, "&DZcy;"], [0, "&Acy;"], [0, "&Bcy;"], [0, "&Vcy;"], [0, "&Gcy;"], [0, "&Dcy;"], [0, "&IEcy;"], [0, "&ZHcy;"], [0, "&Zcy;"], [0, "&Icy;"], [0, "&Jcy;"], [0, "&Kcy;"], [0, "&Lcy;"], [0, "&Mcy;"], [0, "&Ncy;"], [0, "&Ocy;"], [0, "&Pcy;"], [0, "&Rcy;"], [0, "&Scy;"], [0, "&Tcy;"], [0, "&Ucy;"], [0, "&Fcy;"], [0, "&KHcy;"], [0, "&TScy;"], [0, "&CHcy;"], [0, "&SHcy;"], [0, "&SHCHcy;"], [0, "&HARDcy;"], [0, "&Ycy;"], [0, "&SOFTcy;"], [0, "&Ecy;"], [0, "&YUcy;"], [0, "&YAcy;"], [0, "&acy;"], [0, "&bcy;"], [0, "&vcy;"], [0, "&gcy;"], [0, "&dcy;"], [0, "&iecy;"], [0, "&zhcy;"], [0, "&zcy;"], [0, "&icy;"], [0, "&jcy;"], [0, "&kcy;"], [0, "&lcy;"], [0, "&mcy;"], [0, "&ncy;"], [0, "&ocy;"], [0, "&pcy;"], [0, "&rcy;"], [0, "&scy;"], [0, "&tcy;"], [0, "&ucy;"], [0, "&fcy;"], [0, "&khcy;"], [0, "&tscy;"], [0, "&chcy;"], [0, "&shcy;"], [0, "&shchcy;"], [0, "&hardcy;"], [0, "&ycy;"], [0, "&softcy;"], [0, "&ecy;"], [0, "&yucy;"], [0, "&yacy;"], [1, "&iocy;"], [0, "&djcy;"], [0, "&gjcy;"], [0, "&jukcy;"], [0, "&dscy;"], [0, "&iukcy;"], [0, "&yicy;"], [0, "&jsercy;"], [0, "&ljcy;"], [0, "&njcy;"], [0, "&tshcy;"], [0, "&kjcy;"], [1, "&ubrcy;"], [0, "&dzcy;"], [7074, "&ensp;"], [0, "&emsp;"], [0, "&emsp13;"], [0, "&emsp14;"], [1, "&numsp;"], [0, "&puncsp;"], [0, "&ThinSpace;"], [0, "&hairsp;"], [0, "&NegativeMediumSpace;"], [0, "&zwnj;"], [0, "&zwj;"], [0, "&lrm;"], [0, "&rlm;"], [0, "&dash;"], [2, "&ndash;"], [0, "&mdash;"], [0, "&horbar;"], [0, "&Verbar;"], [1, "&lsquo;"], [0, "&CloseCurlyQuote;"], [0, "&lsquor;"], [1, "&ldquo;"], [0, "&CloseCurlyDoubleQuote;"], [0, "&bdquo;"], [1, "&dagger;"], [0, "&Dagger;"], [0, "&bull;"], [2, "&nldr;"], [0, "&hellip;"], [9, "&permil;"], [0, "&pertenk;"], [0, "&prime;"], [0, "&Prime;"], [0, "&tprime;"], [0, "&backprime;"], [3, "&lsaquo;"], [0, "&rsaquo;"], [3, "&oline;"], [2, "&caret;"], [1, "&hybull;"], [0, "&frasl;"], [10, "&bsemi;"], [7, "&qprime;"], [7, { v: "&MediumSpace;", n: 8202, o: "&ThickSpace;" }], [0, "&NoBreak;"], [0, "&af;"], [0, "&InvisibleTimes;"], [0, "&ic;"], [72, "&euro;"], [46, "&tdot;"], [0, "&DotDot;"], [37, "&complexes;"], [2, "&incare;"], [4, "&gscr;"], [0, "&hamilt;"], [0, "&Hfr;"], [0, "&Hopf;"], [0, "&planckh;"], [0, "&hbar;"], [0, "&imagline;"], [0, "&Ifr;"], [0, "&lagran;"], [0, "&ell;"], [1, "&naturals;"], [0, "&numero;"], [0, "&copysr;"], [0, "&weierp;"], [0, "&Popf;"], [0, "&Qopf;"], [0, "&realine;"], [0, "&real;"], [0, "&reals;"], [0, "&rx;"], [3, "&trade;"], [1, "&integers;"], [2, "&mho;"], [0, "&zeetrf;"], [0, "&iiota;"], [2, "&bernou;"], [0, "&Cayleys;"], [1, "&escr;"], [0, "&Escr;"], [0, "&Fouriertrf;"], [1, "&Mellintrf;"], [0, "&order;"], [0, "&alefsym;"], [0, "&beth;"], [0, "&gimel;"], [0, "&daleth;"], [12, "&CapitalDifferentialD;"], [0, "&dd;"], [0, "&ee;"], [0, "&ii;"], [10, "&frac13;"], [0, "&frac23;"], [0, "&frac15;"], [0, "&frac25;"], [0, "&frac35;"], [0, "&frac45;"], [0, "&frac16;"], [0, "&frac56;"], [0, "&frac18;"], [0, "&frac38;"], [0, "&frac58;"], [0, "&frac78;"], [49, "&larr;"], [0, "&ShortUpArrow;"], [0, "&rarr;"], [0, "&darr;"], [0, "&harr;"], [0, "&updownarrow;"], [0, "&nwarr;"], [0, "&nearr;"], [0, "&LowerRightArrow;"], [0, "&LowerLeftArrow;"], [0, "&nlarr;"], [0, "&nrarr;"], [1, { v: "&rarrw;", n: 824, o: "&nrarrw;" }], [0, "&Larr;"], [0, "&Uarr;"], [0, "&Rarr;"], [0, "&Darr;"], [0, "&larrtl;"], [0, "&rarrtl;"], [0, "&LeftTeeArrow;"], [0, "&mapstoup;"], [0, "&map;"], [0, "&DownTeeArrow;"], [1, "&hookleftarrow;"], [0, "&hookrightarrow;"], [0, "&larrlp;"], [0, "&looparrowright;"], [0, "&harrw;"], [0, "&nharr;"], [1, "&lsh;"], [0, "&rsh;"], [0, "&ldsh;"], [0, "&rdsh;"], [1, "&crarr;"], [0, "&cularr;"], [0, "&curarr;"], [2, "&circlearrowleft;"], [0, "&circlearrowright;"], [0, "&leftharpoonup;"], [0, "&DownLeftVector;"], [0, "&RightUpVector;"], [0, "&LeftUpVector;"], [0, "&rharu;"], [0, "&DownRightVector;"], [0, "&dharr;"], [0, "&dharl;"], [0, "&RightArrowLeftArrow;"], [0, "&udarr;"], [0, "&LeftArrowRightArrow;"], [0, "&leftleftarrows;"], [0, "&upuparrows;"], [0, "&rightrightarrows;"], [0, "&ddarr;"], [0, "&leftrightharpoons;"], [0, "&Equilibrium;"], [0, "&nlArr;"], [0, "&nhArr;"], [0, "&nrArr;"], [0, "&DoubleLeftArrow;"], [0, "&DoubleUpArrow;"], [0, "&DoubleRightArrow;"], [0, "&dArr;"], [0, "&DoubleLeftRightArrow;"], [0, "&DoubleUpDownArrow;"], [0, "&nwArr;"], [0, "&neArr;"], [0, "&seArr;"], [0, "&swArr;"], [0, "&lAarr;"], [0, "&rAarr;"], [1, "&zigrarr;"], [6, "&larrb;"], [0, "&rarrb;"], [15, "&DownArrowUpArrow;"], [7, "&loarr;"], [0, "&roarr;"], [0, "&hoarr;"], [0, "&forall;"], [0, "&comp;"], [0, { v: "&part;", n: 824, o: "&npart;" }], [0, "&exist;"], [0, "&nexist;"], [0, "&empty;"], [1, "&Del;"], [0, "&Element;"], [0, "&NotElement;"], [1, "&ni;"], [0, "&notni;"], [2, "&prod;"], [0, "&coprod;"], [0, "&sum;"], [0, "&minus;"], [0, "&MinusPlus;"], [0, "&dotplus;"], [1, "&Backslash;"], [0, "&lowast;"], [0, "&compfn;"], [1, "&radic;"], [2, "&prop;"], [0, "&infin;"], [0, "&angrt;"], [0, { v: "&ang;", n: 8402, o: "&nang;" }], [0, "&angmsd;"], [0, "&angsph;"], [0, "&mid;"], [0, "&nmid;"], [0, "&DoubleVerticalBar;"], [0, "&NotDoubleVerticalBar;"], [0, "&and;"], [0, "&or;"], [0, { v: "&cap;", n: 65024, o: "&caps;" }], [0, { v: "&cup;", n: 65024, o: "&cups;" }], [0, "&int;"], [0, "&Int;"], [0, "&iiint;"], [0, "&conint;"], [0, "&Conint;"], [0, "&Cconint;"], [0, "&cwint;"], [0, "&ClockwiseContourIntegral;"], [0, "&awconint;"], [0, "&there4;"], [0, "&becaus;"], [0, "&ratio;"], [0, "&Colon;"], [0, "&dotminus;"], [1, "&mDDot;"], [0, "&homtht;"], [0, { v: "&sim;", n: 8402, o: "&nvsim;" }], [0, { v: "&backsim;", n: 817, o: "&race;" }], [0, { v: "&ac;", n: 819, o: "&acE;" }], [0, "&acd;"], [0, "&VerticalTilde;"], [0, "&NotTilde;"], [0, { v: "&eqsim;", n: 824, o: "&nesim;" }], [0, "&sime;"], [0, "&NotTildeEqual;"], [0, "&cong;"], [0, "&simne;"], [0, "&ncong;"], [0, "&ap;"], [0, "&nap;"], [0, "&ape;"], [0, { v: "&apid;", n: 824, o: "&napid;" }], [0, "&backcong;"], [0, { v: "&asympeq;", n: 8402, o: "&nvap;" }], [0, { v: "&bump;", n: 824, o: "&nbump;" }], [0, { v: "&bumpe;", n: 824, o: "&nbumpe;" }], [0, { v: "&doteq;", n: 824, o: "&nedot;" }], [0, "&doteqdot;"], [0, "&efDot;"], [0, "&erDot;"], [0, "&Assign;"], [0, "&ecolon;"], [0, "&ecir;"], [0, "&circeq;"], [1, "&wedgeq;"], [0, "&veeeq;"], [1, "&triangleq;"], [2, "&equest;"], [0, "&ne;"], [0, { v: "&Congruent;", n: 8421, o: "&bnequiv;" }], [0, "&nequiv;"], [1, { v: "&le;", n: 8402, o: "&nvle;" }], [0, { v: "&ge;", n: 8402, o: "&nvge;" }], [0, { v: "&lE;", n: 824, o: "&nlE;" }], [0, { v: "&gE;", n: 824, o: "&ngE;" }], [0, { v: "&lnE;", n: 65024, o: "&lvertneqq;" }], [0, { v: "&gnE;", n: 65024, o: "&gvertneqq;" }], [0, { v: "&ll;", n: new Map(/* @__PURE__ */ e([[824, "&nLtv;"], [7577, "&nLt;"]])) }], [0, { v: "&gg;", n: new Map(/* @__PURE__ */ e([[824, "&nGtv;"], [7577, "&nGt;"]])) }], [0, "&between;"], [0, "&NotCupCap;"], [0, "&nless;"], [0, "&ngt;"], [0, "&nle;"], [0, "&nge;"], [0, "&lesssim;"], [0, "&GreaterTilde;"], [0, "&nlsim;"], [0, "&ngsim;"], [0, "&LessGreater;"], [0, "&gl;"], [0, "&NotLessGreater;"], [0, "&NotGreaterLess;"], [0, "&pr;"], [0, "&sc;"], [0, "&prcue;"], [0, "&sccue;"], [0, "&PrecedesTilde;"], [0, { v: "&scsim;", n: 824, o: "&NotSucceedsTilde;" }], [0, "&NotPrecedes;"], [0, "&NotSucceeds;"], [0, { v: "&sub;", n: 8402, o: "&NotSubset;" }], [0, { v: "&sup;", n: 8402, o: "&NotSuperset;" }], [0, "&nsub;"], [0, "&nsup;"], [0, "&sube;"], [0, "&supe;"], [0, "&NotSubsetEqual;"], [0, "&NotSupersetEqual;"], [0, { v: "&subne;", n: 65024, o: "&varsubsetneq;" }], [0, { v: "&supne;", n: 65024, o: "&varsupsetneq;" }], [1, "&cupdot;"], [0, "&UnionPlus;"], [0, { v: "&sqsub;", n: 824, o: "&NotSquareSubset;" }], [0, { v: "&sqsup;", n: 824, o: "&NotSquareSuperset;" }], [0, "&sqsube;"], [0, "&sqsupe;"], [0, { v: "&sqcap;", n: 65024, o: "&sqcaps;" }], [0, { v: "&sqcup;", n: 65024, o: "&sqcups;" }], [0, "&CirclePlus;"], [0, "&CircleMinus;"], [0, "&CircleTimes;"], [0, "&osol;"], [0, "&CircleDot;"], [0, "&circledcirc;"], [0, "&circledast;"], [1, "&circleddash;"], [0, "&boxplus;"], [0, "&boxminus;"], [0, "&boxtimes;"], [0, "&dotsquare;"], [0, "&RightTee;"], [0, "&dashv;"], [0, "&DownTee;"], [0, "&bot;"], [1, "&models;"], [0, "&DoubleRightTee;"], [0, "&Vdash;"], [0, "&Vvdash;"], [0, "&VDash;"], [0, "&nvdash;"], [0, "&nvDash;"], [0, "&nVdash;"], [0, "&nVDash;"], [0, "&prurel;"], [1, "&LeftTriangle;"], [0, "&RightTriangle;"], [0, { v: "&LeftTriangleEqual;", n: 8402, o: "&nvltrie;" }], [0, { v: "&RightTriangleEqual;", n: 8402, o: "&nvrtrie;" }], [0, "&origof;"], [0, "&imof;"], [0, "&multimap;"], [0, "&hercon;"], [0, "&intcal;"], [0, "&veebar;"], [1, "&barvee;"], [0, "&angrtvb;"], [0, "&lrtri;"], [0, "&bigwedge;"], [0, "&bigvee;"], [0, "&bigcap;"], [0, "&bigcup;"], [0, "&diam;"], [0, "&sdot;"], [0, "&sstarf;"], [0, "&divideontimes;"], [0, "&bowtie;"], [0, "&ltimes;"], [0, "&rtimes;"], [0, "&leftthreetimes;"], [0, "&rightthreetimes;"], [0, "&backsimeq;"], [0, "&curlyvee;"], [0, "&curlywedge;"], [0, "&Sub;"], [0, "&Sup;"], [0, "&Cap;"], [0, "&Cup;"], [0, "&fork;"], [0, "&epar;"], [0, "&lessdot;"], [0, "&gtdot;"], [0, { v: "&Ll;", n: 824, o: "&nLl;" }], [0, { v: "&Gg;", n: 824, o: "&nGg;" }], [0, { v: "&leg;", n: 65024, o: "&lesg;" }], [0, { v: "&gel;", n: 65024, o: "&gesl;" }], [2, "&cuepr;"], [0, "&cuesc;"], [0, "&NotPrecedesSlantEqual;"], [0, "&NotSucceedsSlantEqual;"], [0, "&NotSquareSubsetEqual;"], [0, "&NotSquareSupersetEqual;"], [2, "&lnsim;"], [0, "&gnsim;"], [0, "&precnsim;"], [0, "&scnsim;"], [0, "&nltri;"], [0, "&NotRightTriangle;"], [0, "&nltrie;"], [0, "&NotRightTriangleEqual;"], [0, "&vellip;"], [0, "&ctdot;"], [0, "&utdot;"], [0, "&dtdot;"], [0, "&disin;"], [0, "&isinsv;"], [0, "&isins;"], [0, { v: "&isindot;", n: 824, o: "&notindot;" }], [0, "&notinvc;"], [0, "&notinvb;"], [1, { v: "&isinE;", n: 824, o: "&notinE;" }], [0, "&nisd;"], [0, "&xnis;"], [0, "&nis;"], [0, "&notnivc;"], [0, "&notnivb;"], [6, "&barwed;"], [0, "&Barwed;"], [1, "&lceil;"], [0, "&rceil;"], [0, "&LeftFloor;"], [0, "&rfloor;"], [0, "&drcrop;"], [0, "&dlcrop;"], [0, "&urcrop;"], [0, "&ulcrop;"], [0, "&bnot;"], [1, "&profline;"], [0, "&profsurf;"], [1, "&telrec;"], [0, "&target;"], [5, "&ulcorn;"], [0, "&urcorn;"], [0, "&dlcorn;"], [0, "&drcorn;"], [2, "&frown;"], [0, "&smile;"], [9, "&cylcty;"], [0, "&profalar;"], [7, "&topbot;"], [6, "&ovbar;"], [1, "&solbar;"], [60, "&angzarr;"], [51, "&lmoustache;"], [0, "&rmoustache;"], [2, "&OverBracket;"], [0, "&bbrk;"], [0, "&bbrktbrk;"], [37, "&OverParenthesis;"], [0, "&UnderParenthesis;"], [0, "&OverBrace;"], [0, "&UnderBrace;"], [2, "&trpezium;"], [4, "&elinters;"], [59, "&blank;"], [164, "&circledS;"], [55, "&boxh;"], [1, "&boxv;"], [9, "&boxdr;"], [3, "&boxdl;"], [3, "&boxur;"], [3, "&boxul;"], [3, "&boxvr;"], [7, "&boxvl;"], [7, "&boxhd;"], [7, "&boxhu;"], [7, "&boxvh;"], [19, "&boxH;"], [0, "&boxV;"], [0, "&boxdR;"], [0, "&boxDr;"], [0, "&boxDR;"], [0, "&boxdL;"], [0, "&boxDl;"], [0, "&boxDL;"], [0, "&boxuR;"], [0, "&boxUr;"], [0, "&boxUR;"], [0, "&boxuL;"], [0, "&boxUl;"], [0, "&boxUL;"], [0, "&boxvR;"], [0, "&boxVr;"], [0, "&boxVR;"], [0, "&boxvL;"], [0, "&boxVl;"], [0, "&boxVL;"], [0, "&boxHd;"], [0, "&boxhD;"], [0, "&boxHD;"], [0, "&boxHu;"], [0, "&boxhU;"], [0, "&boxHU;"], [0, "&boxvH;"], [0, "&boxVh;"], [0, "&boxVH;"], [19, "&uhblk;"], [3, "&lhblk;"], [3, "&block;"], [8, "&blk14;"], [0, "&blk12;"], [0, "&blk34;"], [13, "&square;"], [8, "&blacksquare;"], [0, "&EmptyVerySmallSquare;"], [1, "&rect;"], [0, "&marker;"], [2, "&fltns;"], [1, "&bigtriangleup;"], [0, "&blacktriangle;"], [0, "&triangle;"], [2, "&blacktriangleright;"], [0, "&rtri;"], [3, "&bigtriangledown;"], [0, "&blacktriangledown;"], [0, "&dtri;"], [2, "&blacktriangleleft;"], [0, "&ltri;"], [6, "&loz;"], [0, "&cir;"], [32, "&tridot;"], [2, "&bigcirc;"], [8, "&ultri;"], [0, "&urtri;"], [0, "&lltri;"], [0, "&EmptySmallSquare;"], [0, "&FilledSmallSquare;"], [8, "&bigstar;"], [0, "&star;"], [7, "&phone;"], [49, "&female;"], [1, "&male;"], [29, "&spades;"], [2, "&clubs;"], [1, "&hearts;"], [0, "&diamondsuit;"], [3, "&sung;"], [2, "&flat;"], [0, "&natural;"], [0, "&sharp;"], [163, "&check;"], [3, "&cross;"], [8, "&malt;"], [21, "&sext;"], [33, "&VerticalSeparator;"], [25, "&lbbrk;"], [0, "&rbbrk;"], [84, "&bsolhsub;"], [0, "&suphsol;"], [28, "&LeftDoubleBracket;"], [0, "&RightDoubleBracket;"], [0, "&lang;"], [0, "&rang;"], [0, "&Lang;"], [0, "&Rang;"], [0, "&loang;"], [0, "&roang;"], [7, "&longleftarrow;"], [0, "&longrightarrow;"], [0, "&longleftrightarrow;"], [0, "&DoubleLongLeftArrow;"], [0, "&DoubleLongRightArrow;"], [0, "&DoubleLongLeftRightArrow;"], [1, "&longmapsto;"], [2, "&dzigrarr;"], [258, "&nvlArr;"], [0, "&nvrArr;"], [0, "&nvHarr;"], [0, "&Map;"], [6, "&lbarr;"], [0, "&bkarow;"], [0, "&lBarr;"], [0, "&dbkarow;"], [0, "&drbkarow;"], [0, "&DDotrahd;"], [0, "&UpArrowBar;"], [0, "&DownArrowBar;"], [2, "&Rarrtl;"], [2, "&latail;"], [0, "&ratail;"], [0, "&lAtail;"], [0, "&rAtail;"], [0, "&larrfs;"], [0, "&rarrfs;"], [0, "&larrbfs;"], [0, "&rarrbfs;"], [2, "&nwarhk;"], [0, "&nearhk;"], [0, "&hksearow;"], [0, "&hkswarow;"], [0, "&nwnear;"], [0, "&nesear;"], [0, "&seswar;"], [0, "&swnwar;"], [8, { v: "&rarrc;", n: 824, o: "&nrarrc;" }], [1, "&cudarrr;"], [0, "&ldca;"], [0, "&rdca;"], [0, "&cudarrl;"], [0, "&larrpl;"], [2, "&curarrm;"], [0, "&cularrp;"], [7, "&rarrpl;"], [2, "&harrcir;"], [0, "&Uarrocir;"], [0, "&lurdshar;"], [0, "&ldrushar;"], [2, "&LeftRightVector;"], [0, "&RightUpDownVector;"], [0, "&DownLeftRightVector;"], [0, "&LeftUpDownVector;"], [0, "&LeftVectorBar;"], [0, "&RightVectorBar;"], [0, "&RightUpVectorBar;"], [0, "&RightDownVectorBar;"], [0, "&DownLeftVectorBar;"], [0, "&DownRightVectorBar;"], [0, "&LeftUpVectorBar;"], [0, "&LeftDownVectorBar;"], [0, "&LeftTeeVector;"], [0, "&RightTeeVector;"], [0, "&RightUpTeeVector;"], [0, "&RightDownTeeVector;"], [0, "&DownLeftTeeVector;"], [0, "&DownRightTeeVector;"], [0, "&LeftUpTeeVector;"], [0, "&LeftDownTeeVector;"], [0, "&lHar;"], [0, "&uHar;"], [0, "&rHar;"], [0, "&dHar;"], [0, "&luruhar;"], [0, "&ldrdhar;"], [0, "&ruluhar;"], [0, "&rdldhar;"], [0, "&lharul;"], [0, "&llhard;"], [0, "&rharul;"], [0, "&lrhard;"], [0, "&udhar;"], [0, "&duhar;"], [0, "&RoundImplies;"], [0, "&erarr;"], [0, "&simrarr;"], [0, "&larrsim;"], [0, "&rarrsim;"], [0, "&rarrap;"], [0, "&ltlarr;"], [1, "&gtrarr;"], [0, "&subrarr;"], [1, "&suplarr;"], [0, "&lfisht;"], [0, "&rfisht;"], [0, "&ufisht;"], [0, "&dfisht;"], [5, "&lopar;"], [0, "&ropar;"], [4, "&lbrke;"], [0, "&rbrke;"], [0, "&lbrkslu;"], [0, "&rbrksld;"], [0, "&lbrksld;"], [0, "&rbrkslu;"], [0, "&langd;"], [0, "&rangd;"], [0, "&lparlt;"], [0, "&rpargt;"], [0, "&gtlPar;"], [0, "&ltrPar;"], [3, "&vzigzag;"], [1, "&vangrt;"], [0, "&angrtvbd;"], [6, "&ange;"], [0, "&range;"], [0, "&dwangle;"], [0, "&uwangle;"], [0, "&angmsdaa;"], [0, "&angmsdab;"], [0, "&angmsdac;"], [0, "&angmsdad;"], [0, "&angmsdae;"], [0, "&angmsdaf;"], [0, "&angmsdag;"], [0, "&angmsdah;"], [0, "&bemptyv;"], [0, "&demptyv;"], [0, "&cemptyv;"], [0, "&raemptyv;"], [0, "&laemptyv;"], [0, "&ohbar;"], [0, "&omid;"], [0, "&opar;"], [1, "&operp;"], [1, "&olcross;"], [0, "&odsold;"], [1, "&olcir;"], [0, "&ofcir;"], [0, "&olt;"], [0, "&ogt;"], [0, "&cirscir;"], [0, "&cirE;"], [0, "&solb;"], [0, "&bsolb;"], [3, "&boxbox;"], [3, "&trisb;"], [0, "&rtriltri;"], [0, { v: "&LeftTriangleBar;", n: 824, o: "&NotLeftTriangleBar;" }], [0, { v: "&RightTriangleBar;", n: 824, o: "&NotRightTriangleBar;" }], [11, "&iinfin;"], [0, "&infintie;"], [0, "&nvinfin;"], [4, "&eparsl;"], [0, "&smeparsl;"], [0, "&eqvparsl;"], [5, "&blacklozenge;"], [8, "&RuleDelayed;"], [1, "&dsol;"], [9, "&bigodot;"], [0, "&bigoplus;"], [0, "&bigotimes;"], [1, "&biguplus;"], [1, "&bigsqcup;"], [5, "&iiiint;"], [0, "&fpartint;"], [2, "&cirfnint;"], [0, "&awint;"], [0, "&rppolint;"], [0, "&scpolint;"], [0, "&npolint;"], [0, "&pointint;"], [0, "&quatint;"], [0, "&intlarhk;"], [10, "&pluscir;"], [0, "&plusacir;"], [0, "&simplus;"], [0, "&plusdu;"], [0, "&plussim;"], [0, "&plustwo;"], [1, "&mcomma;"], [0, "&minusdu;"], [2, "&loplus;"], [0, "&roplus;"], [0, "&Cross;"], [0, "&timesd;"], [0, "&timesbar;"], [1, "&smashp;"], [0, "&lotimes;"], [0, "&rotimes;"], [0, "&otimesas;"], [0, "&Otimes;"], [0, "&odiv;"], [0, "&triplus;"], [0, "&triminus;"], [0, "&tritime;"], [0, "&intprod;"], [2, "&amalg;"], [0, "&capdot;"], [1, "&ncup;"], [0, "&ncap;"], [0, "&capand;"], [0, "&cupor;"], [0, "&cupcap;"], [0, "&capcup;"], [0, "&cupbrcap;"], [0, "&capbrcup;"], [0, "&cupcup;"], [0, "&capcap;"], [0, "&ccups;"], [0, "&ccaps;"], [2, "&ccupssm;"], [2, "&And;"], [0, "&Or;"], [0, "&andand;"], [0, "&oror;"], [0, "&orslope;"], [0, "&andslope;"], [1, "&andv;"], [0, "&orv;"], [0, "&andd;"], [0, "&ord;"], [1, "&wedbar;"], [6, "&sdote;"], [3, "&simdot;"], [2, { v: "&congdot;", n: 824, o: "&ncongdot;" }], [0, "&easter;"], [0, "&apacir;"], [0, { v: "&apE;", n: 824, o: "&napE;" }], [0, "&eplus;"], [0, "&pluse;"], [0, "&Esim;"], [0, "&Colone;"], [0, "&Equal;"], [1, "&ddotseq;"], [0, "&equivDD;"], [0, "&ltcir;"], [0, "&gtcir;"], [0, "&ltquest;"], [0, "&gtquest;"], [0, { v: "&leqslant;", n: 824, o: "&nleqslant;" }], [0, { v: "&geqslant;", n: 824, o: "&ngeqslant;" }], [0, "&lesdot;"], [0, "&gesdot;"], [0, "&lesdoto;"], [0, "&gesdoto;"], [0, "&lesdotor;"], [0, "&gesdotol;"], [0, "&lap;"], [0, "&gap;"], [0, "&lne;"], [0, "&gne;"], [0, "&lnap;"], [0, "&gnap;"], [0, "&lEg;"], [0, "&gEl;"], [0, "&lsime;"], [0, "&gsime;"], [0, "&lsimg;"], [0, "&gsiml;"], [0, "&lgE;"], [0, "&glE;"], [0, "&lesges;"], [0, "&gesles;"], [0, "&els;"], [0, "&egs;"], [0, "&elsdot;"], [0, "&egsdot;"], [0, "&el;"], [0, "&eg;"], [2, "&siml;"], [0, "&simg;"], [0, "&simlE;"], [0, "&simgE;"], [0, { v: "&LessLess;", n: 824, o: "&NotNestedLessLess;" }], [0, { v: "&GreaterGreater;", n: 824, o: "&NotNestedGreaterGreater;" }], [1, "&glj;"], [0, "&gla;"], [0, "&ltcc;"], [0, "&gtcc;"], [0, "&lescc;"], [0, "&gescc;"], [0, "&smt;"], [0, "&lat;"], [0, { v: "&smte;", n: 65024, o: "&smtes;" }], [0, { v: "&late;", n: 65024, o: "&lates;" }], [0, "&bumpE;"], [0, { v: "&PrecedesEqual;", n: 824, o: "&NotPrecedesEqual;" }], [0, { v: "&sce;", n: 824, o: "&NotSucceedsEqual;" }], [2, "&prE;"], [0, "&scE;"], [0, "&precneqq;"], [0, "&scnE;"], [0, "&prap;"], [0, "&scap;"], [0, "&precnapprox;"], [0, "&scnap;"], [0, "&Pr;"], [0, "&Sc;"], [0, "&subdot;"], [0, "&supdot;"], [0, "&subplus;"], [0, "&supplus;"], [0, "&submult;"], [0, "&supmult;"], [0, "&subedot;"], [0, "&supedot;"], [0, { v: "&subE;", n: 824, o: "&nsubE;" }], [0, { v: "&supE;", n: 824, o: "&nsupE;" }], [0, "&subsim;"], [0, "&supsim;"], [2, { v: "&subnE;", n: 65024, o: "&varsubsetneqq;" }], [0, { v: "&supnE;", n: 65024, o: "&varsupsetneqq;" }], [2, "&csub;"], [0, "&csup;"], [0, "&csube;"], [0, "&csupe;"], [0, "&subsup;"], [0, "&supsub;"], [0, "&subsub;"], [0, "&supsup;"], [0, "&suphsub;"], [0, "&supdsub;"], [0, "&forkv;"], [0, "&topfork;"], [0, "&mlcp;"], [8, "&Dashv;"], [1, "&Vdashl;"], [0, "&Barv;"], [0, "&vBar;"], [0, "&vBarv;"], [1, "&Vbar;"], [0, "&Not;"], [0, "&bNot;"], [0, "&rnmid;"], [0, "&cirmid;"], [0, "&midcir;"], [0, "&topcir;"], [0, "&nhpar;"], [0, "&parsim;"], [9, { v: "&parsl;", n: 8421, o: "&nparsl;" }], [44343, { n: new Map(/* @__PURE__ */ e([[56476, "&Ascr;"], [1, "&Cscr;"], [0, "&Dscr;"], [2, "&Gscr;"], [2, "&Jscr;"], [0, "&Kscr;"], [2, "&Nscr;"], [0, "&Oscr;"], [0, "&Pscr;"], [0, "&Qscr;"], [1, "&Sscr;"], [0, "&Tscr;"], [0, "&Uscr;"], [0, "&Vscr;"], [0, "&Wscr;"], [0, "&Xscr;"], [0, "&Yscr;"], [0, "&Zscr;"], [0, "&ascr;"], [0, "&bscr;"], [0, "&cscr;"], [0, "&dscr;"], [1, "&fscr;"], [1, "&hscr;"], [0, "&iscr;"], [0, "&jscr;"], [0, "&kscr;"], [0, "&lscr;"], [0, "&mscr;"], [0, "&nscr;"], [1, "&pscr;"], [0, "&qscr;"], [0, "&rscr;"], [0, "&sscr;"], [0, "&tscr;"], [0, "&uscr;"], [0, "&vscr;"], [0, "&wscr;"], [0, "&xscr;"], [0, "&yscr;"], [0, "&zscr;"], [52, "&Afr;"], [0, "&Bfr;"], [1, "&Dfr;"], [0, "&Efr;"], [0, "&Ffr;"], [0, "&Gfr;"], [2, "&Jfr;"], [0, "&Kfr;"], [0, "&Lfr;"], [0, "&Mfr;"], [0, "&Nfr;"], [0, "&Ofr;"], [0, "&Pfr;"], [0, "&Qfr;"], [1, "&Sfr;"], [0, "&Tfr;"], [0, "&Ufr;"], [0, "&Vfr;"], [0, "&Wfr;"], [0, "&Xfr;"], [0, "&Yfr;"], [1, "&afr;"], [0, "&bfr;"], [0, "&cfr;"], [0, "&dfr;"], [0, "&efr;"], [0, "&ffr;"], [0, "&gfr;"], [0, "&hfr;"], [0, "&ifr;"], [0, "&jfr;"], [0, "&kfr;"], [0, "&lfr;"], [0, "&mfr;"], [0, "&nfr;"], [0, "&ofr;"], [0, "&pfr;"], [0, "&qfr;"], [0, "&rfr;"], [0, "&sfr;"], [0, "&tfr;"], [0, "&ufr;"], [0, "&vfr;"], [0, "&wfr;"], [0, "&xfr;"], [0, "&yfr;"], [0, "&zfr;"], [0, "&Aopf;"], [0, "&Bopf;"], [1, "&Dopf;"], [0, "&Eopf;"], [0, "&Fopf;"], [0, "&Gopf;"], [1, "&Iopf;"], [0, "&Jopf;"], [0, "&Kopf;"], [0, "&Lopf;"], [0, "&Mopf;"], [1, "&Oopf;"], [3, "&Sopf;"], [0, "&Topf;"], [0, "&Uopf;"], [0, "&Vopf;"], [0, "&Wopf;"], [0, "&Xopf;"], [0, "&Yopf;"], [1, "&aopf;"], [0, "&bopf;"], [0, "&copf;"], [0, "&dopf;"], [0, "&eopf;"], [0, "&fopf;"], [0, "&gopf;"], [0, "&hopf;"], [0, "&iopf;"], [0, "&jopf;"], [0, "&kopf;"], [0, "&lopf;"], [0, "&mopf;"], [0, "&nopf;"], [0, "&oopf;"], [0, "&popf;"], [0, "&qopf;"], [0, "&ropf;"], [0, "&sopf;"], [0, "&topf;"], [0, "&uopf;"], [0, "&vopf;"], [0, "&wopf;"], [0, "&xopf;"], [0, "&yopf;"], [0, "&zopf;"]])) }], [8906, "&fflig;"], [0, "&filig;"], [0, "&fllig;"], [0, "&ffilig;"], [0, "&ffllig;"]])), su;
}
var qu = {}, B0;
function Ct() {
  return B0 || (B0 = 1, (function(e) {
    Object.defineProperty(e, "__esModule", { value: !0 }), e.escapeText = e.escapeAttribute = e.escapeUTF8 = e.escape = e.encodeXML = e.getCodePoint = e.xmlReplacer = void 0, e.xmlReplacer = /["&'<>$\x80-\uFFFF]/g;
    var u = /* @__PURE__ */ new Map([
      [34, "&quot;"],
      [38, "&amp;"],
      [39, "&apos;"],
      [60, "&lt;"],
      [62, "&gt;"]
    ]);
    e.getCodePoint = // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    String.prototype.codePointAt != null ? function(s, i) {
      return s.codePointAt(i);
    } : (
      // http://mathiasbynens.be/notes/javascript-encoding#surrogate-formulae
      function(s, i) {
        return (s.charCodeAt(i) & 64512) === 55296 ? (s.charCodeAt(i) - 55296) * 1024 + s.charCodeAt(i + 1) - 56320 + 65536 : s.charCodeAt(i);
      }
    );
    function t(s) {
      for (var i = "", l = 0, a; (a = e.xmlReplacer.exec(s)) !== null; ) {
        var o = a.index, r = s.charCodeAt(o), n = u.get(r);
        n !== void 0 ? (i += s.substring(l, o) + n, l = o + 1) : (i += "".concat(s.substring(l, o), "&#x").concat((0, e.getCodePoint)(s, o).toString(16), ";"), l = e.xmlReplacer.lastIndex += +((r & 64512) === 55296));
      }
      return i + s.substr(l);
    }
    e.encodeXML = t, e.escape = t;
    function c(s, i) {
      return function(a) {
        for (var o, r = 0, n = ""; o = s.exec(a); )
          r !== o.index && (n += a.substring(r, o.index)), n += i.get(o[0].charCodeAt(0)), r = o.index + 1;
        return n + a.substring(r);
      };
    }
    e.escapeUTF8 = c(/[&<>'"]/g, u), e.escapeAttribute = c(/["&\u00A0]/g, /* @__PURE__ */ new Map([
      [34, "&quot;"],
      [38, "&amp;"],
      [160, "&nbsp;"]
    ])), e.escapeText = c(/[&<>\u00A0]/g, /* @__PURE__ */ new Map([
      [38, "&amp;"],
      [60, "&lt;"],
      [62, "&gt;"],
      [160, "&nbsp;"]
    ]));
  })(qu)), qu;
}
var F0;
function S0() {
  if (F0) return ge;
  F0 = 1;
  var e = ge && ge.__importDefault || function(a) {
    return a && a.__esModule ? a : { default: a };
  };
  Object.defineProperty(ge, "__esModule", { value: !0 }), ge.encodeNonAsciiHTML = ge.encodeHTML = void 0;
  var u = e(/* @__PURE__ */ Rs()), t = /* @__PURE__ */ Ct(), c = /[\t\n!-,./:-@[-`\f{-}$\x80-\uFFFF]/g;
  function s(a) {
    return l(c, a);
  }
  ge.encodeHTML = s;
  function i(a) {
    return l(t.xmlReplacer, a);
  }
  ge.encodeNonAsciiHTML = i;
  function l(a, o) {
    for (var r = "", n = 0, f; (f = a.exec(o)) !== null; ) {
      var d = f.index;
      r += o.substring(n, d);
      var A = o.charCodeAt(d), h = u.default.get(A);
      if (typeof h == "object") {
        if (d + 1 < o.length) {
          var w = o.charCodeAt(d + 1), C = typeof h.n == "number" ? h.n === w ? h.o : void 0 : h.n.get(w);
          if (C !== void 0) {
            r += C, n = a.lastIndex += 1;
            continue;
          }
        }
        h = h.v;
      }
      if (h !== void 0)
        r += h, n = d + 1;
      else {
        var b = (0, t.getCodePoint)(o, d);
        r += "&#x".concat(b.toString(16), ";"), n = a.lastIndex += +(b !== A);
      }
    }
    return r + o.substr(n);
  }
  return ge;
}
var R0;
function Ts() {
  return R0 || (R0 = 1, (function(e) {
    Object.defineProperty(e, "__esModule", { value: !0 }), e.decodeXMLStrict = e.decodeHTML5Strict = e.decodeHTML4Strict = e.decodeHTML5 = e.decodeHTML4 = e.decodeHTMLAttribute = e.decodeHTMLStrict = e.decodeHTML = e.decodeXML = e.DecodingMode = e.EntityDecoder = e.encodeHTML5 = e.encodeHTML4 = e.encodeNonAsciiHTML = e.encodeHTML = e.escapeText = e.escapeAttribute = e.escapeUTF8 = e.escape = e.encodeXML = e.encode = e.decodeStrict = e.decode = e.EncodingMode = e.EntityLevel = void 0;
    var u = /* @__PURE__ */ _0(), t = /* @__PURE__ */ S0(), c = /* @__PURE__ */ Ct(), s;
    (function(d) {
      d[d.XML = 0] = "XML", d[d.HTML = 1] = "HTML";
    })(s = e.EntityLevel || (e.EntityLevel = {}));
    var i;
    (function(d) {
      d[d.UTF8 = 0] = "UTF8", d[d.ASCII = 1] = "ASCII", d[d.Extensive = 2] = "Extensive", d[d.Attribute = 3] = "Attribute", d[d.Text = 4] = "Text";
    })(i = e.EncodingMode || (e.EncodingMode = {}));
    function l(d, A) {
      A === void 0 && (A = s.XML);
      var h = typeof A == "number" ? A : A.level;
      if (h === s.HTML) {
        var w = typeof A == "object" ? A.mode : void 0;
        return (0, u.decodeHTML)(d, w);
      }
      return (0, u.decodeXML)(d);
    }
    e.decode = l;
    function a(d, A) {
      var h;
      A === void 0 && (A = s.XML);
      var w = typeof A == "number" ? { level: A } : A;
      return (h = w.mode) !== null && h !== void 0 || (w.mode = u.DecodingMode.Strict), l(d, w);
    }
    e.decodeStrict = a;
    function o(d, A) {
      A === void 0 && (A = s.XML);
      var h = typeof A == "number" ? { level: A } : A;
      return h.mode === i.UTF8 ? (0, c.escapeUTF8)(d) : h.mode === i.Attribute ? (0, c.escapeAttribute)(d) : h.mode === i.Text ? (0, c.escapeText)(d) : h.level === s.HTML ? h.mode === i.ASCII ? (0, t.encodeNonAsciiHTML)(d) : (0, t.encodeHTML)(d) : (0, c.encodeXML)(d);
    }
    e.encode = o;
    var r = /* @__PURE__ */ Ct();
    Object.defineProperty(e, "encodeXML", { enumerable: !0, get: function() {
      return r.encodeXML;
    } }), Object.defineProperty(e, "escape", { enumerable: !0, get: function() {
      return r.escape;
    } }), Object.defineProperty(e, "escapeUTF8", { enumerable: !0, get: function() {
      return r.escapeUTF8;
    } }), Object.defineProperty(e, "escapeAttribute", { enumerable: !0, get: function() {
      return r.escapeAttribute;
    } }), Object.defineProperty(e, "escapeText", { enumerable: !0, get: function() {
      return r.escapeText;
    } });
    var n = /* @__PURE__ */ S0();
    Object.defineProperty(e, "encodeHTML", { enumerable: !0, get: function() {
      return n.encodeHTML;
    } }), Object.defineProperty(e, "encodeNonAsciiHTML", { enumerable: !0, get: function() {
      return n.encodeNonAsciiHTML;
    } }), Object.defineProperty(e, "encodeHTML4", { enumerable: !0, get: function() {
      return n.encodeHTML;
    } }), Object.defineProperty(e, "encodeHTML5", { enumerable: !0, get: function() {
      return n.encodeHTML;
    } });
    var f = /* @__PURE__ */ _0();
    Object.defineProperty(e, "EntityDecoder", { enumerable: !0, get: function() {
      return f.EntityDecoder;
    } }), Object.defineProperty(e, "DecodingMode", { enumerable: !0, get: function() {
      return f.DecodingMode;
    } }), Object.defineProperty(e, "decodeXML", { enumerable: !0, get: function() {
      return f.decodeXML;
    } }), Object.defineProperty(e, "decodeHTML", { enumerable: !0, get: function() {
      return f.decodeHTML;
    } }), Object.defineProperty(e, "decodeHTMLStrict", { enumerable: !0, get: function() {
      return f.decodeHTMLStrict;
    } }), Object.defineProperty(e, "decodeHTMLAttribute", { enumerable: !0, get: function() {
      return f.decodeHTMLAttribute;
    } }), Object.defineProperty(e, "decodeHTML4", { enumerable: !0, get: function() {
      return f.decodeHTML;
    } }), Object.defineProperty(e, "decodeHTML5", { enumerable: !0, get: function() {
      return f.decodeHTML;
    } }), Object.defineProperty(e, "decodeHTML4Strict", { enumerable: !0, get: function() {
      return f.decodeHTMLStrict;
    } }), Object.defineProperty(e, "decodeHTML5Strict", { enumerable: !0, get: function() {
      return f.decodeHTMLStrict;
    } }), Object.defineProperty(e, "decodeXMLStrict", { enumerable: !0, get: function() {
      return f.decodeXML;
    } });
  })(Pu)), Pu;
}
var Re = {}, T0;
function Ns() {
  return T0 || (T0 = 1, Object.defineProperty(Re, "__esModule", { value: !0 }), Re.attributeNames = Re.elementNames = void 0, Re.elementNames = new Map([
    "altGlyph",
    "altGlyphDef",
    "altGlyphItem",
    "animateColor",
    "animateMotion",
    "animateTransform",
    "clipPath",
    "feBlend",
    "feColorMatrix",
    "feComponentTransfer",
    "feComposite",
    "feConvolveMatrix",
    "feDiffuseLighting",
    "feDisplacementMap",
    "feDistantLight",
    "feDropShadow",
    "feFlood",
    "feFuncA",
    "feFuncB",
    "feFuncG",
    "feFuncR",
    "feGaussianBlur",
    "feImage",
    "feMerge",
    "feMergeNode",
    "feMorphology",
    "feOffset",
    "fePointLight",
    "feSpecularLighting",
    "feSpotLight",
    "feTile",
    "feTurbulence",
    "foreignObject",
    "glyphRef",
    "linearGradient",
    "radialGradient",
    "textPath"
  ].map(function(e) {
    return [e.toLowerCase(), e];
  })), Re.attributeNames = new Map([
    "definitionURL",
    "attributeName",
    "attributeType",
    "baseFrequency",
    "baseProfile",
    "calcMode",
    "clipPathUnits",
    "diffuseConstant",
    "edgeMode",
    "filterUnits",
    "glyphRef",
    "gradientTransform",
    "gradientUnits",
    "kernelMatrix",
    "kernelUnitLength",
    "keyPoints",
    "keySplines",
    "keyTimes",
    "lengthAdjust",
    "limitingConeAngle",
    "markerHeight",
    "markerUnits",
    "markerWidth",
    "maskContentUnits",
    "maskUnits",
    "numOctaves",
    "pathLength",
    "patternContentUnits",
    "patternTransform",
    "patternUnits",
    "pointsAtX",
    "pointsAtY",
    "pointsAtZ",
    "preserveAlpha",
    "preserveAspectRatio",
    "primitiveUnits",
    "refX",
    "refY",
    "repeatCount",
    "repeatDur",
    "requiredExtensions",
    "requiredFeatures",
    "specularConstant",
    "specularExponent",
    "spreadMethod",
    "startOffset",
    "stdDeviation",
    "stitchTiles",
    "surfaceScale",
    "systemLanguage",
    "tableValues",
    "targetX",
    "targetY",
    "textLength",
    "viewBox",
    "viewTarget",
    "xChannelSelector",
    "yChannelSelector",
    "zoomAndPan"
  ].map(function(e) {
    return [e.toLowerCase(), e];
  }))), Re;
}
var N0;
function Os() {
  if (N0) return X;
  N0 = 1;
  var e = X && X.__assign || function() {
    return e = Object.assign || function(x) {
      for (var p, y = 1, v = arguments.length; y < v; y++) {
        p = arguments[y];
        for (var I in p) Object.prototype.hasOwnProperty.call(p, I) && (x[I] = p[I]);
      }
      return x;
    }, e.apply(this, arguments);
  }, u = X && X.__createBinding || (Object.create ? (function(x, p, y, v) {
    v === void 0 && (v = y);
    var I = Object.getOwnPropertyDescriptor(p, y);
    (!I || ("get" in I ? !p.__esModule : I.writable || I.configurable)) && (I = { enumerable: !0, get: function() {
      return p[y];
    } }), Object.defineProperty(x, v, I);
  }) : (function(x, p, y, v) {
    v === void 0 && (v = y), x[v] = p[y];
  })), t = X && X.__setModuleDefault || (Object.create ? (function(x, p) {
    Object.defineProperty(x, "default", { enumerable: !0, value: p });
  }) : function(x, p) {
    x.default = p;
  }), c = X && X.__importStar || function(x) {
    if (x && x.__esModule) return x;
    var p = {};
    if (x != null) for (var y in x) y !== "default" && Object.prototype.hasOwnProperty.call(x, y) && u(p, x, y);
    return t(p, x), p;
  };
  Object.defineProperty(X, "__esModule", { value: !0 }), X.render = void 0;
  var s = c(/* @__PURE__ */ Xe()), i = /* @__PURE__ */ Ts(), l = /* @__PURE__ */ Ns(), a = /* @__PURE__ */ new Set([
    "style",
    "script",
    "xmp",
    "iframe",
    "noembed",
    "noframes",
    "plaintext",
    "noscript"
  ]);
  function o(x) {
    return x.replace(/"/g, "&quot;");
  }
  function r(x, p) {
    var y;
    if (x) {
      var v = ((y = p.encodeEntities) !== null && y !== void 0 ? y : p.decodeEntities) === !1 ? o : p.xmlMode || p.encodeEntities !== "utf8" ? i.encodeXML : i.escapeAttribute;
      return Object.keys(x).map(function(I) {
        var D, _, E = (D = x[I]) !== null && D !== void 0 ? D : "";
        return p.xmlMode === "foreign" && (I = (_ = l.attributeNames.get(I)) !== null && _ !== void 0 ? _ : I), !p.emptyAttrs && !p.xmlMode && E === "" ? I : "".concat(I, '="').concat(v(E), '"');
      }).join(" ");
    }
  }
  var n = /* @__PURE__ */ new Set([
    "area",
    "base",
    "basefont",
    "br",
    "col",
    "command",
    "embed",
    "frame",
    "hr",
    "img",
    "input",
    "isindex",
    "keygen",
    "link",
    "meta",
    "param",
    "source",
    "track",
    "wbr"
  ]);
  function f(x, p) {
    p === void 0 && (p = {});
    for (var y = ("length" in x) ? x : [x], v = "", I = 0; I < y.length; I++)
      v += d(y[I], p);
    return v;
  }
  X.render = f, X.default = f;
  function d(x, p) {
    switch (x.type) {
      case s.Root:
        return f(x.children, p);
      // @ts-expect-error We don't use `Doctype` yet
      case s.Doctype:
      case s.Directive:
        return C(x);
      case s.Comment:
        return g(x);
      case s.CDATA:
        return m(x);
      case s.Script:
      case s.Style:
      case s.Tag:
        return w(x, p);
      case s.Text:
        return b(x, p);
    }
  }
  var A = /* @__PURE__ */ new Set([
    "mi",
    "mo",
    "mn",
    "ms",
    "mtext",
    "annotation-xml",
    "foreignObject",
    "desc",
    "title"
  ]), h = /* @__PURE__ */ new Set(["svg", "math"]);
  function w(x, p) {
    var y;
    p.xmlMode === "foreign" && (x.name = (y = l.elementNames.get(x.name)) !== null && y !== void 0 ? y : x.name, x.parent && A.has(x.parent.name) && (p = e(e({}, p), { xmlMode: !1 }))), !p.xmlMode && h.has(x.name) && (p = e(e({}, p), { xmlMode: "foreign" }));
    var v = "<".concat(x.name), I = r(x.attribs, p);
    return I && (v += " ".concat(I)), x.children.length === 0 && (p.xmlMode ? (
      // In XML mode or foreign mode, and user hasn't explicitly turned off self-closing tags
      p.selfClosingTags !== !1
    ) : (
      // User explicitly asked for self-closing tags, even in HTML mode
      p.selfClosingTags && n.has(x.name)
    )) ? (p.xmlMode || (v += " "), v += "/>") : (v += ">", x.children.length > 0 && (v += f(x.children, p)), (p.xmlMode || !n.has(x.name)) && (v += "</".concat(x.name, ">"))), v;
  }
  function C(x) {
    return "<".concat(x.data, ">");
  }
  function b(x, p) {
    var y, v = x.data || "";
    return ((y = p.encodeEntities) !== null && y !== void 0 ? y : p.decodeEntities) !== !1 && !(!p.xmlMode && x.parent && a.has(x.parent.name)) && (v = p.xmlMode || p.encodeEntities !== "utf8" ? (0, i.encodeXML)(v) : (0, i.escapeText)(v)), v;
  }
  function m(x) {
    return "<![CDATA[".concat(x.children[0].data, "]]>");
  }
  function g(x) {
    return "<!--".concat(x.data, "-->");
  }
  return X;
}
var O0;
function ri() {
  if (O0) return fe;
  O0 = 1;
  var e = fe && fe.__importDefault || function(r) {
    return r && r.__esModule ? r : { default: r };
  };
  Object.defineProperty(fe, "__esModule", { value: !0 }), fe.getOuterHTML = s, fe.getInnerHTML = i, fe.getText = l, fe.textContent = a, fe.innerText = o;
  var u = /* @__PURE__ */ Ie(), t = e(/* @__PURE__ */ Os()), c = /* @__PURE__ */ Xe();
  function s(r, n) {
    return (0, t.default)(r, n);
  }
  function i(r, n) {
    return (0, u.hasChildren)(r) ? r.children.map(function(f) {
      return s(f, n);
    }).join("") : "";
  }
  function l(r) {
    return Array.isArray(r) ? r.map(l).join("") : (0, u.isTag)(r) ? r.name === "br" ? `
` : l(r.children) : (0, u.isCDATA)(r) ? l(r.children) : (0, u.isText)(r) ? r.data : "";
  }
  function a(r) {
    return Array.isArray(r) ? r.map(a).join("") : (0, u.hasChildren)(r) && !(0, u.isComment)(r) ? a(r.children) : (0, u.isText)(r) ? r.data : "";
  }
  function o(r) {
    return Array.isArray(r) ? r.map(o).join("") : (0, u.hasChildren)(r) && (r.type === c.ElementType.Tag || (0, u.isCDATA)(r)) ? o(r.children) : (0, u.isText)(r) ? r.data : "";
  }
  return fe;
}
var ce = {}, M0;
function Ms() {
  if (M0) return ce;
  M0 = 1, Object.defineProperty(ce, "__esModule", { value: !0 }), ce.getChildren = u, ce.getParent = t, ce.getSiblings = c, ce.getAttributeValue = s, ce.hasAttrib = i, ce.getName = l, ce.nextElementSibling = a, ce.prevElementSibling = o;
  var e = /* @__PURE__ */ Ie();
  function u(r) {
    return (0, e.hasChildren)(r) ? r.children : [];
  }
  function t(r) {
    return r.parent || null;
  }
  function c(r) {
    var n, f, d = t(r);
    if (d != null)
      return u(d);
    for (var A = [r], h = r.prev, w = r.next; h != null; )
      A.unshift(h), n = h, h = n.prev;
    for (; w != null; )
      A.push(w), f = w, w = f.next;
    return A;
  }
  function s(r, n) {
    var f;
    return (f = r.attribs) === null || f === void 0 ? void 0 : f[n];
  }
  function i(r, n) {
    return r.attribs != null && Object.prototype.hasOwnProperty.call(r.attribs, n) && r.attribs[n] != null;
  }
  function l(r) {
    return r.name;
  }
  function a(r) {
    for (var n, f = r.next; f !== null && !(0, e.isTag)(f); )
      n = f, f = n.next;
    return f;
  }
  function o(r) {
    for (var n, f = r.prev; f !== null && !(0, e.isTag)(f); )
      n = f, f = n.prev;
    return f;
  }
  return ce;
}
var me = {}, Q0;
function Qs() {
  if (Q0) return me;
  Q0 = 1, Object.defineProperty(me, "__esModule", { value: !0 }), me.removeElement = e, me.replaceElement = u, me.appendChild = t, me.append = c, me.prependChild = s, me.prepend = i;
  function e(l) {
    if (l.prev && (l.prev.next = l.next), l.next && (l.next.prev = l.prev), l.parent) {
      var a = l.parent.children, o = a.lastIndexOf(l);
      o >= 0 && a.splice(o, 1);
    }
    l.next = null, l.prev = null, l.parent = null;
  }
  function u(l, a) {
    var o = a.prev = l.prev;
    o && (o.next = a);
    var r = a.next = l.next;
    r && (r.prev = a);
    var n = a.parent = l.parent;
    if (n) {
      var f = n.children;
      f[f.lastIndexOf(l)] = a, l.parent = null;
    }
  }
  function t(l, a) {
    if (e(a), a.next = null, a.parent = l, l.children.push(a) > 1) {
      var o = l.children[l.children.length - 2];
      o.next = a, a.prev = o;
    } else
      a.prev = null;
  }
  function c(l, a) {
    e(a);
    var o = l.parent, r = l.next;
    if (a.next = r, a.prev = l, l.next = a, a.parent = o, r) {
      if (r.prev = a, o) {
        var n = o.children;
        n.splice(n.lastIndexOf(r), 0, a);
      }
    } else o && o.children.push(a);
  }
  function s(l, a) {
    if (e(a), a.parent = l, a.prev = null, l.children.unshift(a) !== 1) {
      var o = l.children[1];
      o.prev = a, a.next = o;
    } else
      a.next = null;
  }
  function i(l, a) {
    e(a);
    var o = l.parent;
    if (o) {
      var r = o.children;
      r.splice(r.indexOf(l), 0, a);
    }
    l.prev && (l.prev.next = a), a.parent = o, a.prev = l.prev, a.next = l, l.prev = a;
  }
  return me;
}
var xe = {}, L0;
function ii() {
  if (L0) return xe;
  L0 = 1, Object.defineProperty(xe, "__esModule", { value: !0 }), xe.filter = u, xe.find = t, xe.findOneChild = c, xe.findOne = s, xe.existsOne = i, xe.findAll = l;
  var e = /* @__PURE__ */ Ie();
  function u(a, o, r, n) {
    return r === void 0 && (r = !0), n === void 0 && (n = 1 / 0), t(a, Array.isArray(o) ? o : [o], r, n);
  }
  function t(a, o, r, n) {
    for (var f = [], d = [Array.isArray(o) ? o : [o]], A = [0]; ; ) {
      if (A[0] >= d[0].length) {
        if (A.length === 1)
          return f;
        d.shift(), A.shift();
        continue;
      }
      var h = d[0][A[0]++];
      if (a(h) && (f.push(h), --n <= 0))
        return f;
      r && (0, e.hasChildren)(h) && h.children.length > 0 && (A.unshift(0), d.unshift(h.children));
    }
  }
  function c(a, o) {
    return o.find(a);
  }
  function s(a, o, r) {
    r === void 0 && (r = !0);
    for (var n = Array.isArray(o) ? o : [o], f = 0; f < n.length; f++) {
      var d = n[f];
      if ((0, e.isTag)(d) && a(d))
        return d;
      if (r && (0, e.hasChildren)(d) && d.children.length > 0) {
        var A = s(a, d.children, !0);
        if (A)
          return A;
      }
    }
    return null;
  }
  function i(a, o) {
    return (Array.isArray(o) ? o : [o]).some(function(r) {
      return (0, e.isTag)(r) && a(r) || (0, e.hasChildren)(r) && i(a, r.children);
    });
  }
  function l(a, o) {
    for (var r = [], n = [Array.isArray(o) ? o : [o]], f = [0]; ; ) {
      if (f[0] >= n[0].length) {
        if (n.length === 1)
          return r;
        n.shift(), f.shift();
        continue;
      }
      var d = n[0][f[0]++];
      (0, e.isTag)(d) && a(d) && r.push(d), (0, e.hasChildren)(d) && d.children.length > 0 && (f.unshift(0), n.unshift(d.children));
    }
  }
  return xe;
}
var ye = {}, P0;
function ni() {
  if (P0) return ye;
  P0 = 1, Object.defineProperty(ye, "__esModule", { value: !0 }), ye.testElement = l, ye.getElements = a, ye.getElementById = o, ye.getElementsByTagName = r, ye.getElementsByClassName = n, ye.getElementsByTagType = f;
  var e = /* @__PURE__ */ Ie(), u = /* @__PURE__ */ ii(), t = {
    tag_name: function(d) {
      return typeof d == "function" ? function(A) {
        return (0, e.isTag)(A) && d(A.name);
      } : d === "*" ? e.isTag : function(A) {
        return (0, e.isTag)(A) && A.name === d;
      };
    },
    tag_type: function(d) {
      return typeof d == "function" ? function(A) {
        return d(A.type);
      } : function(A) {
        return A.type === d;
      };
    },
    tag_contains: function(d) {
      return typeof d == "function" ? function(A) {
        return (0, e.isText)(A) && d(A.data);
      } : function(A) {
        return (0, e.isText)(A) && A.data === d;
      };
    }
  };
  function c(d, A) {
    return typeof A == "function" ? function(h) {
      return (0, e.isTag)(h) && A(h.attribs[d]);
    } : function(h) {
      return (0, e.isTag)(h) && h.attribs[d] === A;
    };
  }
  function s(d, A) {
    return function(h) {
      return d(h) || A(h);
    };
  }
  function i(d) {
    var A = Object.keys(d).map(function(h) {
      var w = d[h];
      return Object.prototype.hasOwnProperty.call(t, h) ? t[h](w) : c(h, w);
    });
    return A.length === 0 ? null : A.reduce(s);
  }
  function l(d, A) {
    var h = i(d);
    return h ? h(A) : !0;
  }
  function a(d, A, h, w) {
    w === void 0 && (w = 1 / 0);
    var C = i(d);
    return C ? (0, u.filter)(C, A, h, w) : [];
  }
  function o(d, A, h) {
    return h === void 0 && (h = !0), Array.isArray(A) || (A = [A]), (0, u.findOne)(c("id", d), A, h);
  }
  function r(d, A, h, w) {
    return h === void 0 && (h = !0), w === void 0 && (w = 1 / 0), (0, u.filter)(t.tag_name(d), A, h, w);
  }
  function n(d, A, h, w) {
    return h === void 0 && (h = !0), w === void 0 && (w = 1 / 0), (0, u.filter)(c("class", d), A, h, w);
  }
  function f(d, A, h, w) {
    return h === void 0 && (h = !0), w === void 0 && (w = 1 / 0), (0, u.filter)(t.tag_type(d), A, h, w);
  }
  return ye;
}
var we = {}, G0;
function Ls() {
  if (G0) return we;
  G0 = 1, Object.defineProperty(we, "__esModule", { value: !0 }), we.DocumentPosition = void 0, we.removeSubsets = u, we.compareDocumentPosition = c, we.uniqueSort = s;
  var e = /* @__PURE__ */ Ie();
  function u(i) {
    for (var l = i.length; --l >= 0; ) {
      var a = i[l];
      if (l > 0 && i.lastIndexOf(a, l - 1) >= 0) {
        i.splice(l, 1);
        continue;
      }
      for (var o = a.parent; o; o = o.parent)
        if (i.includes(o)) {
          i.splice(l, 1);
          break;
        }
    }
    return i;
  }
  var t;
  (function(i) {
    i[i.DISCONNECTED = 1] = "DISCONNECTED", i[i.PRECEDING = 2] = "PRECEDING", i[i.FOLLOWING = 4] = "FOLLOWING", i[i.CONTAINS = 8] = "CONTAINS", i[i.CONTAINED_BY = 16] = "CONTAINED_BY";
  })(t || (we.DocumentPosition = t = {}));
  function c(i, l) {
    var a = [], o = [];
    if (i === l)
      return 0;
    for (var r = (0, e.hasChildren)(i) ? i : i.parent; r; )
      a.unshift(r), r = r.parent;
    for (r = (0, e.hasChildren)(l) ? l : l.parent; r; )
      o.unshift(r), r = r.parent;
    for (var n = Math.min(a.length, o.length), f = 0; f < n && a[f] === o[f]; )
      f++;
    if (f === 0)
      return t.DISCONNECTED;
    var d = a[f - 1], A = d.children, h = a[f], w = o[f];
    return A.indexOf(h) > A.indexOf(w) ? d === l ? t.FOLLOWING | t.CONTAINED_BY : t.FOLLOWING : d === i ? t.PRECEDING | t.CONTAINS : t.PRECEDING;
  }
  function s(i) {
    return i = i.filter(function(l, a, o) {
      return !o.includes(l, a + 1);
    }), i.sort(function(l, a) {
      var o = c(l, a);
      return o & t.PRECEDING ? -1 : o & t.FOLLOWING ? 1 : 0;
    }), i;
  }
  return we;
}
var cu = {}, q0;
function Ps() {
  if (q0) return cu;
  q0 = 1, Object.defineProperty(cu, "__esModule", { value: !0 }), cu.getFeed = t;
  var e = /* @__PURE__ */ ri(), u = /* @__PURE__ */ ni();
  function t(d) {
    var A = o(f, d);
    return A ? A.name === "feed" ? c(A) : s(A) : null;
  }
  function c(d) {
    var A, h = d.children, w = {
      type: "atom",
      items: (0, u.getElementsByTagName)("entry", h).map(function(m) {
        var g, x = m.children, p = { media: a(x) };
        n(p, "id", "id", x), n(p, "title", "title", x);
        var y = (g = o("link", x)) === null || g === void 0 ? void 0 : g.attribs.href;
        y && (p.link = y);
        var v = r("summary", x) || r("content", x);
        v && (p.description = v);
        var I = r("updated", x);
        return I && (p.pubDate = new Date(I)), p;
      })
    };
    n(w, "id", "id", h), n(w, "title", "title", h);
    var C = (A = o("link", h)) === null || A === void 0 ? void 0 : A.attribs.href;
    C && (w.link = C), n(w, "description", "subtitle", h);
    var b = r("updated", h);
    return b && (w.updated = new Date(b)), n(w, "author", "email", h, !0), w;
  }
  function s(d) {
    var A, h, w = (h = (A = o("channel", d.children)) === null || A === void 0 ? void 0 : A.children) !== null && h !== void 0 ? h : [], C = {
      type: d.name.substr(0, 3),
      id: "",
      items: (0, u.getElementsByTagName)("item", d.children).map(function(m) {
        var g = m.children, x = { media: a(g) };
        n(x, "id", "guid", g), n(x, "title", "title", g), n(x, "link", "link", g), n(x, "description", "description", g);
        var p = r("pubDate", g) || r("dc:date", g);
        return p && (x.pubDate = new Date(p)), x;
      })
    };
    n(C, "title", "title", w), n(C, "link", "link", w), n(C, "description", "description", w);
    var b = r("lastBuildDate", w);
    return b && (C.updated = new Date(b)), n(C, "author", "managingEditor", w, !0), C;
  }
  var i = ["url", "type", "lang"], l = [
    "fileSize",
    "bitrate",
    "framerate",
    "samplingrate",
    "channels",
    "duration",
    "height",
    "width"
  ];
  function a(d) {
    return (0, u.getElementsByTagName)("media:content", d).map(function(A) {
      for (var h = A.attribs, w = {
        medium: h.medium,
        isDefault: !!h.isDefault
      }, C = 0, b = i; C < b.length; C++) {
        var m = b[C];
        h[m] && (w[m] = h[m]);
      }
      for (var g = 0, x = l; g < x.length; g++) {
        var m = x[g];
        h[m] && (w[m] = parseInt(h[m], 10));
      }
      return h.expression && (w.expression = h.expression), w;
    });
  }
  function o(d, A) {
    return (0, u.getElementsByTagName)(d, A, !0, 1)[0];
  }
  function r(d, A, h) {
    return h === void 0 && (h = !1), (0, e.textContent)((0, u.getElementsByTagName)(d, A, h, 1)).trim();
  }
  function n(d, A, h, w, C) {
    C === void 0 && (C = !1);
    var b = r(h, w, C);
    b && (d[A] = b);
  }
  function f(d) {
    return d === "rss" || d === "feed" || d === "rdf:RDF";
  }
  return cu;
}
var H0;
function Hu() {
  return H0 || (H0 = 1, (function(e) {
    var u = Se && Se.__createBinding || (Object.create ? (function(s, i, l, a) {
      a === void 0 && (a = l);
      var o = Object.getOwnPropertyDescriptor(i, l);
      (!o || ("get" in o ? !i.__esModule : o.writable || o.configurable)) && (o = { enumerable: !0, get: function() {
        return i[l];
      } }), Object.defineProperty(s, a, o);
    }) : (function(s, i, l, a) {
      a === void 0 && (a = l), s[a] = i[l];
    })), t = Se && Se.__exportStar || function(s, i) {
      for (var l in s) l !== "default" && !Object.prototype.hasOwnProperty.call(i, l) && u(i, s, l);
    };
    Object.defineProperty(e, "__esModule", { value: !0 }), e.hasChildren = e.isDocument = e.isComment = e.isText = e.isCDATA = e.isTag = void 0, t(/* @__PURE__ */ ri(), e), t(/* @__PURE__ */ Ms(), e), t(/* @__PURE__ */ Qs(), e), t(/* @__PURE__ */ ii(), e), t(/* @__PURE__ */ ni(), e), t(/* @__PURE__ */ Ls(), e), t(/* @__PURE__ */ Ps(), e);
    var c = /* @__PURE__ */ Ie();
    Object.defineProperty(e, "isTag", { enumerable: !0, get: function() {
      return c.isTag;
    } }), Object.defineProperty(e, "isCDATA", { enumerable: !0, get: function() {
      return c.isCDATA;
    } }), Object.defineProperty(e, "isText", { enumerable: !0, get: function() {
      return c.isText;
    } }), Object.defineProperty(e, "isComment", { enumerable: !0, get: function() {
      return c.isComment;
    } }), Object.defineProperty(e, "isDocument", { enumerable: !0, get: function() {
      return c.isDocument;
    } }), Object.defineProperty(e, "hasChildren", { enumerable: !0, get: function() {
      return c.hasChildren;
    } });
  })(Se)), Se;
}
var W0;
function Gs() {
  return W0 || (W0 = 1, (function(e) {
    var u = ne && ne.__createBinding || (Object.create ? (function(m, g, x, p) {
      p === void 0 && (p = x);
      var y = Object.getOwnPropertyDescriptor(g, x);
      (!y || ("get" in y ? !g.__esModule : y.writable || y.configurable)) && (y = { enumerable: !0, get: function() {
        return g[x];
      } }), Object.defineProperty(m, p, y);
    }) : (function(m, g, x, p) {
      p === void 0 && (p = x), m[p] = g[x];
    })), t = ne && ne.__setModuleDefault || (Object.create ? (function(m, g) {
      Object.defineProperty(m, "default", { enumerable: !0, value: g });
    }) : function(m, g) {
      m.default = g;
    }), c = ne && ne.__importStar || /* @__PURE__ */ (function() {
      var m = function(g) {
        return m = Object.getOwnPropertyNames || function(x) {
          var p = [];
          for (var y in x) Object.prototype.hasOwnProperty.call(x, y) && (p[p.length] = y);
          return p;
        }, m(g);
      };
      return function(g) {
        if (g && g.__esModule) return g;
        var x = {};
        if (g != null) for (var p = m(g), y = 0; y < p.length; y++) p[y] !== "default" && u(x, g, p[y]);
        return t(x, g), x;
      };
    })(), s = ne && ne.__importDefault || function(m) {
      return m && m.__esModule ? m : { default: m };
    };
    Object.defineProperty(e, "__esModule", { value: !0 }), e.DomUtils = e.getFeed = e.ElementType = e.QuoteType = e.Tokenizer = e.DefaultHandler = e.DomHandler = e.Parser = void 0, e.parseDocument = r, e.parseDOM = n, e.createDocumentStream = f, e.createDomStream = d, e.parseFeed = b;
    const i = g0();
    var l = g0();
    Object.defineProperty(e, "Parser", { enumerable: !0, get: function() {
      return l.Parser;
    } });
    const a = /* @__PURE__ */ Ie();
    var o = /* @__PURE__ */ Ie();
    Object.defineProperty(e, "DomHandler", { enumerable: !0, get: function() {
      return o.DomHandler;
    } }), Object.defineProperty(e, "DefaultHandler", { enumerable: !0, get: function() {
      return o.DomHandler;
    } });
    function r(m, g) {
      const x = new a.DomHandler(void 0, g);
      return new i.Parser(x, g).end(m), x.root;
    }
    function n(m, g) {
      return r(m, g).children;
    }
    function f(m, g, x) {
      const p = new a.DomHandler((y) => m(y, p.root), g, x);
      return new i.Parser(p, g);
    }
    function d(m, g, x) {
      const p = new a.DomHandler(m, g, x);
      return new i.Parser(p, g);
    }
    var A = ti();
    Object.defineProperty(e, "Tokenizer", { enumerable: !0, get: function() {
      return s(A).default;
    } }), Object.defineProperty(e, "QuoteType", { enumerable: !0, get: function() {
      return A.QuoteType;
    } }), e.ElementType = c(/* @__PURE__ */ Xe());
    const h = /* @__PURE__ */ Hu();
    var w = /* @__PURE__ */ Hu();
    Object.defineProperty(e, "getFeed", { enumerable: !0, get: function() {
      return w.getFeed;
    } });
    const C = { xmlMode: !0 };
    function b(m, g = C) {
      return (0, h.getFeed)(n(m, g));
    }
    e.DomUtils = c(/* @__PURE__ */ Hu());
  })(ne)), ne;
}
var Wu, U0;
function qs() {
  return U0 || (U0 = 1, Wu = (e) => {
    if (typeof e != "string")
      throw new TypeError("Expected a string");
    return e.replace(/[|\\{}()[\]^$+*?.]/g, "\\$&").replace(/-/g, "\\x2d");
  }), Wu;
}
var ou = {}, K0;
function Hs() {
  if (K0) return ou;
  K0 = 1, Object.defineProperty(ou, "__esModule", { value: !0 });
  /*!
   * is-plain-object <https://github.com/jonschlinkert/is-plain-object>
   *
   * Copyright (c) 2014-2017, Jon Schlinkert.
   * Released under the MIT License.
   */
  function e(t) {
    return Object.prototype.toString.call(t) === "[object Object]";
  }
  function u(t) {
    var c, s;
    return e(t) === !1 ? !1 : (c = t.constructor, c === void 0 ? !0 : (s = c.prototype, !(e(s) === !1 || s.hasOwnProperty("isPrototypeOf") === !1)));
  }
  return ou.isPlainObject = u, ou;
}
var Uu, Y0;
function Ws() {
  if (Y0) return Uu;
  Y0 = 1;
  var e = function(m) {
    return u(m) && !t(m);
  };
  function u(b) {
    return !!b && typeof b == "object";
  }
  function t(b) {
    var m = Object.prototype.toString.call(b);
    return m === "[object RegExp]" || m === "[object Date]" || i(b);
  }
  var c = typeof Symbol == "function" && Symbol.for, s = c ? Symbol.for("react.element") : 60103;
  function i(b) {
    return b.$$typeof === s;
  }
  function l(b) {
    return Array.isArray(b) ? [] : {};
  }
  function a(b, m) {
    return m.clone !== !1 && m.isMergeableObject(b) ? w(l(b), b, m) : b;
  }
  function o(b, m, g) {
    return b.concat(m).map(function(x) {
      return a(x, g);
    });
  }
  function r(b, m) {
    if (!m.customMerge)
      return w;
    var g = m.customMerge(b);
    return typeof g == "function" ? g : w;
  }
  function n(b) {
    return Object.getOwnPropertySymbols ? Object.getOwnPropertySymbols(b).filter(function(m) {
      return Object.propertyIsEnumerable.call(b, m);
    }) : [];
  }
  function f(b) {
    return Object.keys(b).concat(n(b));
  }
  function d(b, m) {
    try {
      return m in b;
    } catch {
      return !1;
    }
  }
  function A(b, m) {
    return d(b, m) && !(Object.hasOwnProperty.call(b, m) && Object.propertyIsEnumerable.call(b, m));
  }
  function h(b, m, g) {
    var x = {};
    return g.isMergeableObject(b) && f(b).forEach(function(p) {
      x[p] = a(b[p], g);
    }), f(m).forEach(function(p) {
      A(b, p) || (d(b, p) && g.isMergeableObject(m[p]) ? x[p] = r(p, g)(b[p], m[p], g) : x[p] = a(m[p], g));
    }), x;
  }
  function w(b, m, g) {
    g = g || {}, g.arrayMerge = g.arrayMerge || o, g.isMergeableObject = g.isMergeableObject || e, g.cloneUnlessOtherwiseSpecified = a;
    var x = Array.isArray(m), p = Array.isArray(b), y = x === p;
    return y ? x ? g.arrayMerge(b, m, g) : h(b, m, g) : a(m, g);
  }
  w.all = function(m, g) {
    if (!Array.isArray(m))
      throw new Error("first argument should be an array");
    return m.reduce(function(x, p) {
      return w(x, p, g);
    }, {});
  };
  var C = w;
  return Uu = C, Uu;
}
var du = { exports: {} }, Us = du.exports, j0;
function Ks() {
  return j0 || (j0 = 1, (function(e) {
    (function(u, t) {
      e.exports ? e.exports = t() : u.parseSrcset = t();
    })(Us, function() {
      return function(u) {
        function t(x) {
          return x === " " || // space
          x === "	" || // horizontal tab
          x === `
` || // new line
          x === "\f" || // form feed
          x === "\r";
        }
        function c(x) {
          var p, y = x.exec(u.substring(C));
          if (y)
            return p = y[0], C += p.length, p;
        }
        for (var s = u.length, i = /^[ \t\n\r\u000c]+/, l = /^[, \t\n\r\u000c]+/, a = /^[^ \t\n\r\u000c]+/, o = /[,]+$/, r = /^\d+$/, n = /^-?(?:[0-9]+|[0-9]*\.[0-9]+)(?:[eE][+-]?[0-9]+)?$/, f, d, A, h, w, C = 0, b = []; ; ) {
          if (c(l), C >= s)
            return b;
          f = c(a), d = [], f.slice(-1) === "," ? (f = f.replace(o, ""), g()) : m();
        }
        function m() {
          for (c(i), A = "", h = "in descriptor"; ; ) {
            if (w = u.charAt(C), h === "in descriptor")
              if (t(w))
                A && (d.push(A), A = "", h = "after descriptor");
              else if (w === ",") {
                C += 1, A && d.push(A), g();
                return;
              } else if (w === "(")
                A = A + w, h = "in parens";
              else if (w === "") {
                A && d.push(A), g();
                return;
              } else
                A = A + w;
            else if (h === "in parens")
              if (w === ")")
                A = A + w, h = "in descriptor";
              else if (w === "") {
                d.push(A), g();
                return;
              } else
                A = A + w;
            else if (h === "after descriptor" && !t(w))
              if (w === "") {
                g();
                return;
              } else
                h = "in descriptor", C -= 1;
            C += 1;
          }
        }
        function g() {
          var x = !1, p, y, v, I, D = {}, _, E, k, F, T;
          for (I = 0; I < d.length; I++)
            _ = d[I], E = _[_.length - 1], k = _.substring(0, _.length - 1), F = parseInt(k, 10), T = parseFloat(k), r.test(k) && E === "w" ? ((p || y) && (x = !0), F === 0 ? x = !0 : p = F) : n.test(k) && E === "x" ? ((p || y || v) && (x = !0), T < 0 ? x = !0 : y = T) : r.test(k) && E === "h" ? ((v || y) && (x = !0), F === 0 ? x = !0 : v = F) : x = !0;
          x ? console && console.log && console.log("Invalid srcset descriptor found in '" + u + "' at '" + _ + "'.") : (D.url = f, p && (D.w = p), y && (D.d = y), v && (D.h = v), b.push(D));
        }
      };
    });
  })(du)), du.exports;
}
var lu = { exports: {} }, J0;
function Ys() {
  if (J0) return lu.exports;
  J0 = 1;
  var e = String, u = function() {
    return { isColorSupported: !1, reset: e, bold: e, dim: e, italic: e, underline: e, inverse: e, hidden: e, strikethrough: e, black: e, red: e, green: e, yellow: e, blue: e, magenta: e, cyan: e, white: e, gray: e, bgBlack: e, bgRed: e, bgGreen: e, bgYellow: e, bgBlue: e, bgMagenta: e, bgCyan: e, bgWhite: e, blackBright: e, redBright: e, greenBright: e, yellowBright: e, blueBright: e, magentaBright: e, cyanBright: e, whiteBright: e, bgBlackBright: e, bgRedBright: e, bgGreenBright: e, bgYellowBright: e, bgBlueBright: e, bgMagentaBright: e, bgCyanBright: e, bgWhiteBright: e };
  };
  return lu.exports = u(), lu.exports.createColors = u, lu.exports;
}
const js = {}, Js = /* @__PURE__ */ Object.freeze(/* @__PURE__ */ Object.defineProperty({
  __proto__: null,
  default: js
}, Symbol.toStringTag, { value: "Module" })), oe = /* @__PURE__ */ ks(Js);
var Ku, Z0;
function St() {
  if (Z0) return Ku;
  Z0 = 1;
  let e = /* @__PURE__ */ Ys(), u = oe;
  class t extends Error {
    constructor(s, i, l, a, o, r) {
      super(s), this.name = "CssSyntaxError", this.reason = s, o && (this.file = o), a && (this.source = a), r && (this.plugin = r), typeof i < "u" && typeof l < "u" && (typeof i == "number" ? (this.line = i, this.column = l) : (this.line = i.line, this.column = i.column, this.endLine = l.line, this.endColumn = l.column)), this.setMessage(), Error.captureStackTrace && Error.captureStackTrace(this, t);
    }
    setMessage() {
      this.message = this.plugin ? this.plugin + ": " : "", this.message += this.file ? this.file : "<css input>", typeof this.line < "u" && (this.message += ":" + this.line + ":" + this.column), this.message += ": " + this.reason;
    }
    showSourceCode(s) {
      if (!this.source) return "";
      let i = this.source;
      s == null && (s = e.isColorSupported);
      let l = (A) => A, a = (A) => A, o = (A) => A;
      if (s) {
        let { bold: A, gray: h, red: w } = e.createColors(!0);
        a = (C) => A(w(C)), l = (C) => h(C), u && (o = (C) => u(C));
      }
      let r = i.split(/\r?\n/), n = Math.max(this.line - 3, 0), f = Math.min(this.line + 2, r.length), d = String(f).length;
      return r.slice(n, f).map((A, h) => {
        let w = n + 1 + h, C = " " + (" " + w).slice(-d) + " | ";
        if (w === this.line) {
          if (A.length > 160) {
            let m = 20, g = Math.max(0, this.column - m), x = Math.max(
              this.column + m,
              this.endColumn + m
            ), p = A.slice(g, x), y = l(C.replace(/\d/g, " ")) + A.slice(0, Math.min(this.column - 1, m - 1)).replace(/[^\t]/g, " ");
            return a(">") + l(C) + o(p) + `
 ` + y + a("^");
          }
          let b = l(C.replace(/\d/g, " ")) + A.slice(0, this.column - 1).replace(/[^\t]/g, " ");
          return a(">") + l(C) + o(A) + `
 ` + b + a("^");
        }
        return " " + l(C) + o(A);
      }).join(`
`);
    }
    toString() {
      let s = this.showSourceCode();
      return s && (s = `

` + s + `
`), this.name + ": " + this.message + s;
    }
  }
  return Ku = t, t.default = t, Ku;
}
var Yu, V0;
function ai() {
  if (V0) return Yu;
  V0 = 1;
  const e = /(<)(\/?style\b)/gi, u = /(<)(!--)/g;
  function t(l) {
    return typeof l != "string" || !l.includes("<") ? l : l.replace(e, "\\3c $2").replace(u, "\\3c $2");
  }
  const c = {
    after: `
`,
    beforeClose: `
`,
    beforeComment: `
`,
    beforeDecl: `
`,
    beforeOpen: " ",
    beforeRule: `
`,
    colon: ": ",
    commentLeft: " ",
    commentRight: " ",
    emptyBody: "",
    indent: "    ",
    semicolon: !1
  };
  function s(l) {
    return l[0].toUpperCase() + l.slice(1);
  }
  class i {
    constructor(a) {
      this.builder = a;
    }
    atrule(a, o) {
      let r = a.raws, n = "@" + a.name, f = a.params ? this.rawValue(a, "params") : "";
      if (typeof r.afterName < "u" ? n += r.afterName : f && (n += " "), a.nodes)
        this.block(a, n + f);
      else {
        let d = (r.between || "") + (o ? ";" : "");
        this.builder(t(n + f + d), a);
      }
    }
    beforeAfter(a, o) {
      let r;
      a.type === "decl" ? r = this.raw(a, null, "beforeDecl") : a.type === "comment" ? r = this.raw(a, null, "beforeComment") : o === "before" ? r = this.raw(a, null, "beforeRule") : r = this.raw(a, null, "beforeClose");
      let n = a.parent, f = 0;
      for (; n && n.type !== "root"; )
        f += 1, n = n.parent;
      if (r.includes(`
`)) {
        let d = this.raw(a, null, "indent");
        if (d.length)
          for (let A = 0; A < f; A++) r += d;
      }
      return r;
    }
    block(a, o) {
      let r = a.raws, n = typeof r.between < "u" ? r.between : this.raw(a, "between", "beforeOpen");
      this.builder(t(o + n) + "{", a, "start");
      let f;
      a.nodes && a.nodes.length ? (this.body(a), f = typeof r.after < "u" ? r.after : this.raw(a, "after")) : f = typeof r.after < "u" ? r.after : this.raw(a, "after", "emptyBody"), f && this.builder(t(f)), this.builder("}", a, "end");
    }
    body(a) {
      let o = a.nodes, r = o.length - 1;
      for (; r > 0 && o[r].type === "comment"; )
        r -= 1;
      let n = this.raw(a, "semicolon"), f = a.type === "document";
      for (let d = 0; d < o.length; d++) {
        let A = o[d], h = A.raws.before;
        typeof h > "u" && (h = this.raw(A, "before")), h && this.builder(f ? h : t(h)), this.stringify(A, r !== d || n);
      }
    }
    comment(a) {
      let o = a.raws, r = typeof o.left < "u" ? o.left : this.raw(a, "left", "commentLeft"), n = typeof o.right < "u" ? o.right : this.raw(a, "right", "commentRight");
      this.builder(t("/*" + r + a.text + n + "*/"), a);
    }
    decl(a, o) {
      let r = a.raws, n = typeof r.between < "u" ? r.between : this.raw(a, "between", "colon"), f = r.value, d = f && f.value === a.value ? f.raw : a.value, A = a.prop + n + d;
      a.important && (A += r.important || " !important"), o && (A += ";"), this.builder(t(A), a);
    }
    document(a) {
      this.body(a);
    }
    raw(a, o, r) {
      let n;
      if (r || (r = o), o && (n = a.raws[o], typeof n < "u"))
        return n;
      let f = a.parent;
      if (r === "before" && (!f || f.type === "root" && f.first === a || f && f.type === "document"))
        return "";
      if (!f) return c[r];
      let d = a.root(), A = d.rawCache || (d.rawCache = {});
      if (typeof A[r] < "u")
        return A[r];
      if (r === "before" || r === "after")
        return this.beforeAfter(a, r);
      {
        let h = "raw" + s(r);
        this[h] ? n = this[h](d, a) : d.walk((w) => {
          if (n = w.raws[o], typeof n < "u") return !1;
        });
      }
      return typeof n > "u" && (n = c[r]), A[r] = n, n;
    }
    rawBeforeClose(a) {
      let o;
      return a.walk((r) => {
        if (r.nodes && r.nodes.length > 0 && typeof r.raws.after < "u")
          return o = r.raws.after, o.includes(`
`) && (o = o.replace(/[^\n]+$/, "")), !1;
      }), o && (o = o.replace(/\S/g, "")), o;
    }
    rawBeforeComment(a, o) {
      let r;
      return a.walkComments((n) => {
        if (typeof n.raws.before < "u")
          return r = n.raws.before, r.includes(`
`) && (r = r.replace(/[^\n]+$/, "")), !1;
      }), typeof r > "u" ? r = this.raw(o, null, "beforeDecl") : r && (r = r.replace(/\S/g, "")), r;
    }
    rawBeforeDecl(a, o) {
      let r;
      return a.walkDecls((n) => {
        if (typeof n.raws.before < "u")
          return r = n.raws.before, r.includes(`
`) && (r = r.replace(/[^\n]+$/, "")), !1;
      }), typeof r > "u" ? r = this.raw(o, null, "beforeRule") : r && (r = r.replace(/\S/g, "")), r;
    }
    rawBeforeOpen(a) {
      let o;
      return a.walk((r) => {
        if (r.type !== "decl" && (o = r.raws.between, typeof o < "u"))
          return !1;
      }), o;
    }
    rawBeforeRule(a) {
      let o;
      return a.walk((r) => {
        if (r.nodes && (r.parent !== a || a.first !== r) && typeof r.raws.before < "u")
          return o = r.raws.before, o.includes(`
`) && (o = o.replace(/[^\n]+$/, "")), !1;
      }), o && (o = o.replace(/\S/g, "")), o;
    }
    rawColon(a) {
      let o;
      return a.walkDecls((r) => {
        if (typeof r.raws.between < "u")
          return o = r.raws.between.replace(/[^\s:]/g, ""), !1;
      }), o;
    }
    rawEmptyBody(a) {
      let o;
      return a.walk((r) => {
        if (r.nodes && r.nodes.length === 0 && (o = r.raws.after, typeof o < "u"))
          return !1;
      }), o;
    }
    rawIndent(a) {
      if (a.raws.indent) return a.raws.indent;
      let o;
      return a.walk((r) => {
        let n = r.parent;
        if (n && n !== a && n.parent && n.parent === a && typeof r.raws.before < "u") {
          let f = r.raws.before.split(`
`);
          return o = f[f.length - 1], o = o.replace(/\S/g, ""), !1;
        }
      }), o;
    }
    rawSemicolon(a) {
      let o;
      return a.walk((r) => {
        if (r.nodes && r.nodes.length && r.last.type === "decl" && (o = r.raws.semicolon, typeof o < "u"))
          return !1;
      }), o;
    }
    rawValue(a, o) {
      let r = a[o], n = a.raws[o];
      return n && n.value === r ? n.raw : r;
    }
    root(a) {
      if (this.body(a), a.raws.after) {
        let o = a.raws.after, r = a.parent && a.parent.type === "document";
        this.builder(r ? o : t(o));
      }
    }
    rule(a) {
      this.block(a, this.rawValue(a, "selector")), a.raws.ownSemicolon && this.builder(t(a.raws.ownSemicolon), a, "end");
    }
    stringify(a, o) {
      if (!this[a.type])
        throw new Error(
          "Unknown AST node type " + a.type + ". Maybe you need to change PostCSS stringifier."
        );
      this[a.type](a, o);
    }
  }
  return Yu = i, i.default = i, Yu;
}
var ju, z0;
function yu() {
  if (z0) return ju;
  z0 = 1;
  let e = ai();
  function u(t, c) {
    new e(c).stringify(t);
  }
  return ju = u, u.default = u, ju;
}
var fu = {}, X0;
function Rt() {
  return X0 || (X0 = 1, fu.isClean = Symbol("isClean"), fu.my = Symbol("my")), fu;
}
var Ju, $0;
function wu() {
  if ($0) return Ju;
  $0 = 1;
  let e = St(), u = ai(), t = yu(), { isClean: c, my: s } = Rt();
  function i(o, r) {
    let n = new o.constructor();
    for (let f in o) {
      if (!Object.prototype.hasOwnProperty.call(o, f) || f === "proxyCache") continue;
      let d = o[f], A = typeof d;
      f === "parent" && A === "object" ? r && (n[f] = r) : f === "source" ? n[f] = d : Array.isArray(d) ? n[f] = d.map((h) => i(h, n)) : (A === "object" && d !== null && (d = i(d)), n[f] = d);
    }
    return n;
  }
  function l(o, r) {
    if (r && typeof r.offset < "u")
      return r.offset;
    let n = 1, f = 1, d = 0;
    for (let A = 0; A < o.length; A++) {
      if (f === r.line && n === r.column) {
        d = A;
        break;
      }
      o[A] === `
` ? (n = 1, f += 1) : n += 1;
    }
    return d;
  }
  class a {
    get proxyOf() {
      return this;
    }
    constructor(r = {}) {
      this.raws = {}, this[c] = !1, this[s] = !0;
      for (let n in r)
        if (n === "nodes") {
          this.nodes = [];
          for (let f of r[n])
            typeof f.clone == "function" ? this.append(f.clone()) : this.append(f);
        } else
          this[n] = r[n];
    }
    addToError(r) {
      if (r.postcssNode = this, r.stack && this.source && /\n\s{4}at /.test(r.stack)) {
        let n = this.source;
        r.stack = r.stack.replace(
          /\n\s{4}at /,
          `$&${n.input.from}:${n.start.line}:${n.start.column}$&`
        );
      }
      return r;
    }
    after(r) {
      return this.parent.insertAfter(this, r), this;
    }
    assign(r = {}) {
      for (let n in r)
        this[n] = r[n];
      return this;
    }
    before(r) {
      return this.parent.insertBefore(this, r), this;
    }
    cleanRaws(r) {
      delete this.raws.before, delete this.raws.after, r || delete this.raws.between;
    }
    clone(r = {}) {
      let n = i(this);
      for (let f in r)
        n[f] = r[f];
      return n;
    }
    cloneAfter(r = {}) {
      let n = this.clone(r);
      return this.parent.insertAfter(this, n), n;
    }
    cloneBefore(r = {}) {
      let n = this.clone(r);
      return this.parent.insertBefore(this, n), n;
    }
    error(r, n = {}) {
      if (this.source) {
        let { end: f, start: d } = this.rangeBy(n);
        return this.source.input.error(
          r,
          { column: d.column, line: d.line },
          { column: f.column, line: f.line },
          n
        );
      }
      return new e(r);
    }
    getProxyProcessor() {
      return {
        get(r, n) {
          return n === "proxyOf" ? r : n === "root" ? () => r.root().toProxy() : r[n];
        },
        set(r, n, f) {
          return r[n] === f || (r[n] = f, (n === "prop" || n === "value" || n === "name" || n === "params" || n === "important" || /* c8 ignore next */
          n === "text") && r.markDirty()), !0;
        }
      };
    }
    /* c8 ignore next 3 */
    markClean() {
      this[c] = !0;
    }
    markDirty() {
      if (this[c]) {
        this[c] = !1;
        let r = this;
        for (; r = r.parent; )
          r[c] = !1;
      }
    }
    next() {
      if (!this.parent) return;
      let r = this.parent.index(this);
      return this.parent.nodes[r + 1];
    }
    positionBy(r = {}) {
      let n = this.source.start;
      if (r.index)
        n = this.positionInside(r.index);
      else if (r.word) {
        let f = "document" in this.source.input ? this.source.input.document : this.source.input.css, A = f.slice(
          l(f, this.source.start),
          l(f, this.source.end)
        ).indexOf(r.word);
        A !== -1 && (n = this.positionInside(A));
      }
      return n;
    }
    positionInside(r) {
      let n = this.source.start.column, f = this.source.start.line, d = "document" in this.source.input ? this.source.input.document : this.source.input.css, A = l(d, this.source.start), h = A + r;
      for (let w = A; w < h; w++)
        d[w] === `
` ? (n = 1, f += 1) : n += 1;
      return { column: n, line: f, offset: h };
    }
    prev() {
      if (!this.parent) return;
      let r = this.parent.index(this);
      return this.parent.nodes[r - 1];
    }
    rangeBy(r = {}) {
      let n = "document" in this.source.input ? this.source.input.document : this.source.input.css, f = {
        column: this.source.start.column,
        line: this.source.start.line,
        offset: l(n, this.source.start)
      }, d = this.source.end ? {
        column: this.source.end.column + 1,
        line: this.source.end.line,
        offset: typeof this.source.end.offset == "number" ? (
          // `source.end.offset` is exclusive, so we don't need to add 1
          this.source.end.offset
        ) : (
          // Since line/column in this.source.end is inclusive,
          // the `sourceOffset(... , this.source.end)` returns an inclusive offset.
          // So, we add 1 to convert it to exclusive.
          l(n, this.source.end) + 1
        )
      } : {
        column: f.column + 1,
        line: f.line,
        offset: f.offset + 1
      };
      if (r.word) {
        let h = n.slice(
          l(n, this.source.start),
          l(n, this.source.end)
        ).indexOf(r.word);
        h !== -1 && (f = this.positionInside(h), d = this.positionInside(h + r.word.length));
      } else
        r.start ? f = {
          column: r.start.column,
          line: r.start.line,
          offset: l(n, r.start)
        } : r.index && (f = this.positionInside(r.index)), r.end ? d = {
          column: r.end.column,
          line: r.end.line,
          offset: l(n, r.end)
        } : typeof r.endIndex == "number" ? d = this.positionInside(r.endIndex) : r.index && (d = this.positionInside(r.index + 1));
      return (d.line < f.line || d.line === f.line && d.column <= f.column) && (d = {
        column: f.column + 1,
        line: f.line,
        offset: f.offset + 1
      }), { end: d, start: f };
    }
    raw(r, n) {
      return new u().raw(this, r, n);
    }
    remove() {
      return this.parent && this.parent.removeChild(this), this.parent = void 0, this;
    }
    replaceWith(...r) {
      if (this.parent) {
        let n = this, f = !1;
        for (let d of r)
          d === this ? f = !0 : f ? (this.parent.insertAfter(n, d), n = d) : this.parent.insertBefore(n, d);
        f || this.remove();
      }
      return this;
    }
    root() {
      let r = this;
      for (; r.parent && r.parent.type !== "document"; )
        r = r.parent;
      return r;
    }
    toJSON(r, n) {
      let f = {}, d = n == null;
      n = n || /* @__PURE__ */ new Map();
      let A = 0;
      for (let h in this) {
        if (!Object.prototype.hasOwnProperty.call(this, h) || h === "parent" || h === "proxyCache") continue;
        let w = this[h];
        if (Array.isArray(w))
          f[h] = w.map((C) => typeof C == "object" && C.toJSON ? C.toJSON(null, n) : C);
        else if (typeof w == "object" && w.toJSON)
          f[h] = w.toJSON(null, n);
        else if (h === "source") {
          if (w == null) continue;
          let C = n.get(w.input);
          C == null && (C = A, n.set(w.input, A), A++), f[h] = {
            end: w.end,
            inputId: C,
            start: w.start
          };
        } else
          f[h] = w;
      }
      return d && (f.inputs = [...n.keys()].map((h) => h.toJSON())), f;
    }
    toProxy() {
      return this.proxyCache || (this.proxyCache = new Proxy(this, this.getProxyProcessor())), this.proxyCache;
    }
    toString(r = t) {
      r.stringify && (r = r.stringify);
      let n = "";
      return r(this, (f) => {
        n += f;
      }), n;
    }
    warn(r, n, f = {}) {
      let d = { node: this };
      for (let A in f) d[A] = f[A];
      return r.warn(n, d);
    }
  }
  return Ju = a, a.default = a, Ju;
}
var Zu, er;
function Cu() {
  if (er) return Zu;
  er = 1;
  let e = wu();
  class u extends e {
    constructor(c) {
      super(c), this.type = "comment";
    }
  }
  return Zu = u, u.default = u, Zu;
}
var Vu, ur;
function vu() {
  if (ur) return Vu;
  ur = 1;
  let e = wu();
  class u extends e {
    get variable() {
      return this.prop.startsWith("--") || this.prop[0] === "$";
    }
    constructor(c) {
      c && typeof c.value < "u" && typeof c.value != "string" && (c = { ...c, value: String(c.value) }), super(c), this.type = "decl";
    }
  }
  return Vu = u, u.default = u, Vu;
}
var zu, tr;
function Te() {
  if (tr) return zu;
  tr = 1;
  let e = Cu(), u = vu(), t = wu(), { isClean: c, my: s } = Rt(), i, l, a, o;
  function r(d) {
    return d.map((A) => (A.nodes && (A.nodes = r(A.nodes)), delete A.source, A));
  }
  function n(d) {
    if (d[c] = !1, d.proxyOf.nodes)
      for (let A of d.proxyOf.nodes)
        n(A);
  }
  class f extends t {
    get first() {
      if (this.proxyOf.nodes)
        return this.proxyOf.nodes[0];
    }
    get last() {
      if (this.proxyOf.nodes)
        return this.proxyOf.nodes[this.proxyOf.nodes.length - 1];
    }
    append(...A) {
      for (let h of A) {
        let w = this.normalize(h, this.last);
        for (let C of w) this.proxyOf.nodes.push(C);
      }
      return this.markDirty(), this;
    }
    cleanRaws(A) {
      if (super.cleanRaws(A), this.nodes)
        for (let h of this.nodes) h.cleanRaws(A);
    }
    each(A) {
      if (!this.proxyOf.nodes) return;
      let h = this.getIterator(), w, C;
      for (; this.indexes[h] < this.proxyOf.nodes.length && (w = this.indexes[h], C = A(this.proxyOf.nodes[w], w), C !== !1); )
        this.indexes[h] += 1;
      return delete this.indexes[h], C;
    }
    every(A) {
      return this.nodes.every(A);
    }
    getIterator() {
      this.lastEach || (this.lastEach = 0), this.indexes || (this.indexes = {}), this.lastEach += 1;
      let A = this.lastEach;
      return this.indexes[A] = 0, A;
    }
    getProxyProcessor() {
      return {
        get(A, h) {
          return h === "proxyOf" ? A : A[h] ? h === "each" || typeof h == "string" && h.startsWith("walk") ? (...w) => A[h](
            ...w.map((C) => typeof C == "function" ? (b, m) => C(b.toProxy(), m) : C)
          ) : h === "every" || h === "some" ? (w) => A[h](
            (C, ...b) => w(C.toProxy(), ...b)
          ) : h === "root" ? () => A.root().toProxy() : h === "nodes" ? A.nodes.map((w) => w.toProxy()) : h === "first" || h === "last" ? A[h].toProxy() : A[h] : A[h];
        },
        set(A, h, w) {
          return A[h] === w || (A[h] = w, (h === "name" || h === "params" || h === "selector") && A.markDirty()), !0;
        }
      };
    }
    index(A) {
      return typeof A == "number" ? A : (A.proxyOf && (A = A.proxyOf), this.proxyOf.nodes.indexOf(A));
    }
    insertAfter(A, h) {
      let w = this.index(A), C = this.normalize(h, this.proxyOf.nodes[w]).reverse();
      w = this.index(A);
      for (let m of C) this.proxyOf.nodes.splice(w + 1, 0, m);
      let b;
      for (let m in this.indexes)
        b = this.indexes[m], w < b && (this.indexes[m] = b + C.length);
      return this.markDirty(), this;
    }
    insertBefore(A, h) {
      let w = this.index(A), C = w === 0 ? "prepend" : !1, b = this.normalize(
        h,
        this.proxyOf.nodes[w],
        C
      ).reverse();
      w = this.index(A);
      for (let g of b) this.proxyOf.nodes.splice(w, 0, g);
      let m;
      for (let g in this.indexes)
        m = this.indexes[g], w <= m && (this.indexes[g] = m + b.length);
      return this.markDirty(), this;
    }
    normalize(A, h) {
      if (typeof A == "string")
        A = r(l(A).nodes);
      else if (typeof A > "u")
        A = [];
      else if (Array.isArray(A)) {
        A = A.slice(0);
        for (let C of A)
          C.parent && C.parent.removeChild(C, "ignore");
      } else if (A.type === "root" && this.type !== "document") {
        A = A.nodes.slice(0);
        for (let C of A)
          C.parent && C.parent.removeChild(C, "ignore");
      } else if (A.type)
        A = [A];
      else if (A.prop) {
        if (typeof A.value > "u")
          throw new Error("Value field is missed in node creation");
        typeof A.value != "string" && (A.value = String(A.value)), A = [new u(A)];
      } else if (A.selector || A.selectors)
        A = [new o(A)];
      else if (A.name)
        A = [new i(A)];
      else if (A.text)
        A = [new e(A)];
      else
        throw new Error("Unknown node type in node creation");
      return A.map((C) => (C[s] || f.rebuild(C), C = C.proxyOf, C.parent && C.parent.removeChild(C), C[c] && n(C), C.raws || (C.raws = {}), typeof C.raws.before > "u" && h && typeof h.raws.before < "u" && (C.raws.before = h.raws.before.replace(/\S/g, "")), C.parent = this.proxyOf, C));
    }
    prepend(...A) {
      A = A.reverse();
      for (let h of A) {
        let w = this.normalize(h, this.first, "prepend").reverse();
        for (let C of w) this.proxyOf.nodes.unshift(C);
        for (let C in this.indexes)
          this.indexes[C] = this.indexes[C] + w.length;
      }
      return this.markDirty(), this;
    }
    push(A) {
      return A.parent = this, this.proxyOf.nodes.push(A), this;
    }
    removeAll() {
      for (let A of this.proxyOf.nodes) A.parent = void 0;
      return this.proxyOf.nodes = [], this.markDirty(), this;
    }
    removeChild(A) {
      A = this.index(A), this.proxyOf.nodes[A].parent = void 0, this.proxyOf.nodes.splice(A, 1);
      let h;
      for (let w in this.indexes)
        h = this.indexes[w], h >= A && (this.indexes[w] = h - 1);
      return this.markDirty(), this;
    }
    replaceValues(A, h, w) {
      return w || (w = h, h = {}), this.walkDecls((C) => {
        h.props && !h.props.includes(C.prop) || h.fast && !C.value.includes(h.fast) || (C.value = C.value.replace(A, w));
      }), this.markDirty(), this;
    }
    some(A) {
      return this.nodes.some(A);
    }
    walk(A) {
      return this.each((h, w) => {
        let C;
        try {
          C = A(h, w);
        } catch (b) {
          throw h.addToError(b);
        }
        return C !== !1 && h.walk && (C = h.walk(A)), C;
      });
    }
    walkAtRules(A, h) {
      return h ? A instanceof RegExp ? this.walk((w, C) => {
        if (w.type === "atrule" && A.test(w.name))
          return h(w, C);
      }) : this.walk((w, C) => {
        if (w.type === "atrule" && w.name === A)
          return h(w, C);
      }) : (h = A, this.walk((w, C) => {
        if (w.type === "atrule")
          return h(w, C);
      }));
    }
    walkComments(A) {
      return this.walk((h, w) => {
        if (h.type === "comment")
          return A(h, w);
      });
    }
    walkDecls(A, h) {
      return h ? A instanceof RegExp ? this.walk((w, C) => {
        if (w.type === "decl" && A.test(w.prop))
          return h(w, C);
      }) : this.walk((w, C) => {
        if (w.type === "decl" && w.prop === A)
          return h(w, C);
      }) : (h = A, this.walk((w, C) => {
        if (w.type === "decl")
          return h(w, C);
      }));
    }
    walkRules(A, h) {
      return h ? A instanceof RegExp ? this.walk((w, C) => {
        if (w.type === "rule" && A.test(w.selector))
          return h(w, C);
      }) : this.walk((w, C) => {
        if (w.type === "rule" && w.selector === A)
          return h(w, C);
      }) : (h = A, this.walk((w, C) => {
        if (w.type === "rule")
          return h(w, C);
      }));
    }
  }
  return f.registerParse = (d) => {
    l = d;
  }, f.registerRule = (d) => {
    o = d;
  }, f.registerAtRule = (d) => {
    i = d;
  }, f.registerRoot = (d) => {
    a = d;
  }, zu = f, f.default = f, f.rebuild = (d) => {
    d.type === "atrule" ? Object.setPrototypeOf(d, i.prototype) : d.type === "rule" ? Object.setPrototypeOf(d, o.prototype) : d.type === "decl" ? Object.setPrototypeOf(d, u.prototype) : d.type === "comment" ? Object.setPrototypeOf(d, e.prototype) : d.type === "root" && Object.setPrototypeOf(d, a.prototype), d[s] = !0, d.nodes && d.nodes.forEach((A) => {
      f.rebuild(A);
    });
  }, zu;
}
var Xu, rr;
function Tt() {
  if (rr) return Xu;
  rr = 1;
  let e = Te();
  class u extends e {
    constructor(c) {
      super(c), this.type = "atrule";
    }
    append(...c) {
      return this.proxyOf.nodes || (this.nodes = []), super.append(...c);
    }
    prepend(...c) {
      return this.proxyOf.nodes || (this.nodes = []), super.prepend(...c);
    }
  }
  return Xu = u, u.default = u, e.registerAtRule(u), Xu;
}
var $u, ir;
function Nt() {
  if (ir) return $u;
  ir = 1;
  let e = Te(), u, t;
  class c extends e {
    constructor(i) {
      super({ type: "document", ...i }), this.nodes || (this.nodes = []);
    }
    toResult(i = {}) {
      return new u(new t(), this, i).stringify();
    }
  }
  return c.registerLazyResult = (s) => {
    u = s;
  }, c.registerProcessor = (s) => {
    t = s;
  }, $u = c, c.default = c, $u;
}
var et, nr;
function Zs() {
  if (nr) return et;
  nr = 1;
  let e = "useandom-26T198340PX75pxJACKVERYMINDBUSHWOLF_GQZbfghjklqvwyzrict";
  return et = { nanoid: (c = 21) => {
    let s = "", i = c | 0;
    for (; i--; )
      s += e[Math.random() * 64 | 0];
    return s;
  }, customAlphabet: (c, s = 21) => (i = s) => {
    let l = "", a = i | 0;
    for (; a--; )
      l += c[Math.random() * c.length | 0];
    return l;
  } }, et;
}
var ut, ar;
function si() {
  if (ar) return ut;
  ar = 1;
  let { existsSync: e, readFileSync: u } = oe, { dirname: t, join: c } = oe, { SourceMapConsumer: s, SourceMapGenerator: i } = oe;
  function l(o) {
    return Buffer ? Buffer.from(o, "base64").toString() : window.atob(o);
  }
  class a {
    constructor(r, n) {
      if (n.map === !1) return;
      n.unsafeMap && (this.unsafeMap = !0), this.loadAnnotation(r), this.inline = this.startWith(this.annotation, "data:");
      let f = n.map ? n.map.prev : void 0, d = this.loadMap(n.from, f);
      !this.mapFile && n.from && (this.mapFile = n.from), this.mapFile && (this.root = t(this.mapFile)), d && (this.text = d);
    }
    consumer() {
      return this.consumerCache || (this.consumerCache = new s(this.json || this.text)), this.consumerCache;
    }
    decodeInline(r) {
      let n = /^data:application\/json;charset=utf-?8;base64,/, f = /^data:application\/json;base64,/, d = /^data:application\/json;charset=utf-?8,/, A = /^data:application\/json,/, h = r.match(d) || r.match(A);
      if (h)
        return decodeURIComponent(r.substr(h[0].length));
      let w = r.match(n) || r.match(f);
      if (w)
        return l(r.substr(w[0].length));
      let C = r.slice(22);
      throw C = C.slice(0, C.indexOf(",")), new Error("Unsupported source map encoding " + C);
    }
    getAnnotationURL(r) {
      return r.replace(/^\/\*\s*# sourceMappingURL=/, "").trim();
    }
    isMap(r) {
      return typeof r != "object" ? !1 : typeof r.mappings == "string" || typeof r._mappings == "string" || Array.isArray(r.sections);
    }
    loadAnnotation(r) {
      let n = r.match(/\/\*\s*# sourceMappingURL=/g);
      if (!n) return;
      let f = r.lastIndexOf(n.pop()), d = r.indexOf("*/", f);
      f > -1 && d > -1 && (this.annotation = this.getAnnotationURL(r.substring(f, d)));
    }
    loadFile(r, n, f) {
      if (!(!f && !this.unsafeMap && !/\.map$/i.test(r)) && (this.root = t(r), e(r)))
        return this.mapFile = r, u(r, "utf-8").toString().trim();
    }
    loadMap(r, n) {
      if (n === !1) return !1;
      if (n) {
        if (typeof n == "string")
          return n;
        if (typeof n == "function") {
          let f = n(r);
          if (f) {
            let d = this.loadFile(f, r, !0);
            if (!d)
              throw new Error(
                "Unable to load previous source map: " + f.toString()
              );
            return d;
          }
        } else {
          if (n instanceof s)
            return i.fromSourceMap(n).toString();
          if (n instanceof i)
            return n.toString();
          if (this.isMap(n))
            return JSON.stringify(n);
          throw new Error(
            "Unsupported previous source map format: " + n.toString()
          );
        }
      } else {
        if (this.inline)
          return this.decodeInline(this.annotation);
        if (this.annotation) {
          let f = this.annotation;
          r && (f = c(t(r), f));
          let d = this.loadFile(f, r, !1);
          if (d)
            try {
              this.json = JSON.parse(d.replace(/^\)]}'[^\n]*\n/, ""));
            } catch {
              return;
            }
          return d;
        }
      }
    }
    startWith(r, n) {
      return r ? r.substr(0, n.length) === n : !1;
    }
    withContent() {
      return !!(this.consumer().sourcesContent && this.consumer().sourcesContent.length > 0);
    }
  }
  return ut = a, a.default = a, ut;
}
var tt, sr;
function Eu() {
  if (sr) return tt;
  sr = 1;
  let { nanoid: e } = /* @__PURE__ */ Zs(), { isAbsolute: u, resolve: t } = oe, { SourceMapConsumer: c, SourceMapGenerator: s } = oe, { fileURLToPath: i, pathToFileURL: l } = oe, a = St(), o = si(), r = oe, n = Symbol("lineToIndexCache"), f = !!(c && s), d = !!(t && u);
  function A(w) {
    if (w[n]) return w[n];
    let C = w.css.split(`
`), b = new Array(C.length), m = 0;
    for (let g = 0, x = C.length; g < x; g++)
      b[g] = m, m += C[g].length + 1;
    return w[n] = b, b;
  }
  class h {
    get from() {
      return this.file || this.id;
    }
    constructor(C, b = {}) {
      if (C === null || typeof C > "u" || typeof C == "object" && !C.toString)
        throw new Error(`PostCSS received ${C} instead of CSS string`);
      if (this.css = C.toString(), this.css[0] === "\uFEFF" || this.css[0] === "￾" ? (this.hasBOM = !0, this.css = this.css.slice(1)) : this.hasBOM = !1, this.document = this.css, b.document && (this.document = b.document.toString()), b.from && (!d || /^\w+:\/\//.test(b.from) || u(b.from) ? this.file = b.from : this.file = t(b.from)), d && f) {
        let m = new o(this.css, b);
        if (m.text) {
          this.map = m;
          let g = m.consumer().file;
          !this.file && g && (this.file = this.mapResolve(g));
        }
      }
      this.file || (this.id = "<input css " + e(6) + ">"), this.map && (this.map.file = this.from);
    }
    error(C, b, m, g = {}) {
      let x, p, y, v, I;
      if (b && typeof b == "object") {
        let _ = b, E = m;
        if (typeof _.offset == "number") {
          v = _.offset;
          let k = this.fromOffset(v);
          b = k.line, m = k.col;
        } else
          b = _.line, m = _.column, v = this.fromLineAndColumn(b, m);
        if (typeof E.offset == "number") {
          y = E.offset;
          let k = this.fromOffset(y);
          p = k.line, x = k.col;
        } else
          p = E.line, x = E.column, y = this.fromLineAndColumn(E.line, E.column);
      } else if (m)
        v = this.fromLineAndColumn(b, m);
      else {
        v = b;
        let _ = this.fromOffset(v);
        b = _.line, m = _.col;
      }
      let D = this.origin(b, m, p, x);
      return D ? I = new a(
        C,
        D.endLine === void 0 ? D.line : { column: D.column, line: D.line },
        D.endLine === void 0 ? D.column : { column: D.endColumn, line: D.endLine },
        D.source,
        D.file,
        g.plugin
      ) : I = new a(
        C,
        p === void 0 ? b : { column: m, line: b },
        p === void 0 ? m : { column: x, line: p },
        this.css,
        this.file,
        g.plugin
      ), I.input = {
        column: m,
        endColumn: x,
        endLine: p,
        endOffset: y,
        line: b,
        offset: v,
        source: this.css
      }, this.file && (l && (I.input.url = l(this.file).toString()), I.input.file = this.file), I;
    }
    fromLineAndColumn(C, b) {
      return A(this)[C - 1] + b - 1;
    }
    fromOffset(C) {
      let b = A(this), m = b[b.length - 1], g = 0;
      if (C >= m)
        g = b.length - 1;
      else {
        let x = b.length - 2, p;
        for (; g < x; )
          if (p = g + (x - g >> 1), C < b[p])
            x = p - 1;
          else if (C >= b[p + 1])
            g = p + 1;
          else {
            g = p;
            break;
          }
      }
      return {
        col: C - b[g] + 1,
        line: g + 1
      };
    }
    mapResolve(C) {
      return /^\w+:\/\//.test(C) ? C : t(this.map.consumer().sourceRoot || this.map.root || ".", C);
    }
    origin(C, b, m, g) {
      if (!this.map) return !1;
      let x = this.map.consumer(), p = x.originalPositionFor({ column: b, line: C });
      if (!p.source) return !1;
      let y;
      typeof m == "number" && (y = x.originalPositionFor({ column: g, line: m }));
      let v;
      u(p.source) ? v = l(p.source) : v = new URL(
        p.source,
        this.map.consumer().sourceRoot || l(this.map.mapFile)
      );
      let I = {
        column: p.column,
        endColumn: y && y.column,
        endLine: y && y.line,
        line: p.line,
        url: v.toString()
      };
      if (v.protocol === "file:")
        if (i)
          I.file = i(v);
        else
          throw new Error("file: protocol is not available in this PostCSS build");
      let D = x.sourceContentFor(p.source);
      return D && (I.source = D), I;
    }
    toJSON() {
      let C = {};
      for (let b of ["hasBOM", "css", "file", "id"])
        this[b] != null && (C[b] = this[b]);
      return this.map && (C.map = { ...this.map }, C.map.consumerCache && (C.map.consumerCache = void 0)), C;
    }
  }
  return tt = h, h.default = h, r && r.registerInput && r.registerInput(h), tt;
}
var rt, cr;
function $e() {
  if (cr) return rt;
  cr = 1;
  let e = Te(), u, t;
  class c extends e {
    constructor(i) {
      super(i), this.type = "root", this.nodes || (this.nodes = []);
    }
    normalize(i, l, a) {
      let o = super.normalize(i);
      if (l) {
        if (a === "prepend")
          this.nodes.length > 1 ? l.raws.before = this.nodes[1].raws.before : delete l.raws.before;
        else if (this.first !== l)
          for (let r of o)
            r.raws.before = l.raws.before;
      }
      return o;
    }
    removeChild(i, l) {
      let a = this.index(i);
      return !l && a === 0 && this.nodes.length > 1 && (this.nodes[1].raws.before = this.nodes[a].raws.before), super.removeChild(i);
    }
    toResult(i = {}) {
      return new u(new t(), this, i).stringify();
    }
  }
  return c.registerLazyResult = (s) => {
    u = s;
  }, c.registerProcessor = (s) => {
    t = s;
  }, rt = c, c.default = c, e.registerRoot(c), rt;
}
var it, or;
function ci() {
  if (or) return it;
  or = 1;
  let e = {
    comma(u) {
      return e.split(u, [","], !0);
    },
    space(u) {
      let t = [" ", `
`, "	"];
      return e.split(u, t);
    },
    split(u, t, c) {
      let s = [], i = "", l = !1, a = 0, o = !1, r = "", n = !1;
      for (let f of u)
        n ? n = !1 : f === "\\" ? n = !0 : o ? f === r && (o = !1) : f === '"' || f === "'" ? (o = !0, r = f) : f === "(" ? a += 1 : f === ")" ? a > 0 && (a -= 1) : a === 0 && t.includes(f) && (l = !0), l ? (i !== "" && s.push(i.trim()), i = "", l = !1) : i += f;
      return (c || i !== "") && s.push(i.trim()), s;
    }
  };
  return it = e, e.default = e, it;
}
var nt, lr;
function Ot() {
  if (lr) return nt;
  lr = 1;
  let e = Te(), u = ci();
  class t extends e {
    get selectors() {
      return u.comma(this.selector);
    }
    set selectors(s) {
      let i = this.selector ? this.selector.match(/,\s*/) : null, l = i ? i[0] : "," + this.raw("between", "beforeOpen");
      this.selector = s.join(l);
    }
    constructor(s) {
      super(s), this.type = "rule", this.nodes || (this.nodes = []);
    }
  }
  return nt = t, t.default = t, e.registerRule(t), nt;
}
var at, fr;
function Vs() {
  if (fr) return at;
  fr = 1;
  let e = Tt(), u = Cu(), t = vu(), c = Eu(), s = si(), i = $e(), l = Ot();
  function a(o, r) {
    if (Array.isArray(o)) return o.map((d) => a(d));
    let { inputs: n, ...f } = o;
    if (n) {
      r = [];
      for (let d of n) {
        let A = { ...d, __proto__: c.prototype };
        A.map && (A.map = {
          ...A.map,
          __proto__: s.prototype
        }), r.push(A);
      }
    }
    if (f.nodes && (f.nodes = o.nodes.map((d) => a(d, r))), f.source) {
      let { inputId: d, ...A } = f.source;
      f.source = A, d != null && (f.source.input = r[d]);
    }
    if (f.type === "root")
      return new i(f);
    if (f.type === "decl")
      return new t(f);
    if (f.type === "rule")
      return new l(f);
    if (f.type === "comment")
      return new u(f);
    if (f.type === "atrule")
      return new e(f);
    throw new Error("Unknown node type: " + o.type);
  }
  return at = a, a.default = a, at;
}
var st, dr;
function oi() {
  if (dr) return st;
  dr = 1;
  let { dirname: e, relative: u, resolve: t, sep: c } = oe, { SourceMapConsumer: s, SourceMapGenerator: i } = oe, { pathToFileURL: l } = oe, a = Eu(), o = !!(s && i), r = !!(e && t && u && c);
  class n {
    constructor(d, A, h, w) {
      this.stringify = d, this.mapOpts = h.map || {}, this.root = A, this.opts = h, this.css = w, this.originalCSS = w, this.usesFileUrls = !this.mapOpts.from && this.mapOpts.absolute, this.memoizedFileURLs = /* @__PURE__ */ new Map(), this.memoizedPaths = /* @__PURE__ */ new Map(), this.memoizedURLs = /* @__PURE__ */ new Map();
    }
    addAnnotation() {
      let d;
      this.isInline() ? d = "data:application/json;base64," + this.toBase64(this.map.toString()) : typeof this.mapOpts.annotation == "string" ? d = this.mapOpts.annotation : typeof this.mapOpts.annotation == "function" ? d = this.mapOpts.annotation(this.opts.to, this.root) : d = this.outputFile() + ".map";
      let A = `
`;
      this.css.includes(`\r
`) && (A = `\r
`), this.css += A + "/*# sourceMappingURL=" + d + " */";
    }
    applyPrevMaps() {
      for (let d of this.previous()) {
        let A = this.toUrl(this.path(d.file)), h = d.root || e(d.file), w;
        this.mapOpts.sourcesContent === !1 ? (w = new s(d.text), w.sourcesContent && (w.sourcesContent = null)) : w = d.consumer(), this.map.applySourceMap(w, A, this.toUrl(this.path(h)));
      }
    }
    clearAnnotation() {
      if (this.mapOpts.annotation !== !1) {
        if (this.root) {
          let d;
          for (let A = this.root.nodes.length - 1; A >= 0; A--)
            d = this.root.nodes[A], d.type === "comment" && d.text.startsWith("# sourceMappingURL=") && this.root.removeChild(A);
        } else if (this.css) {
          let d;
          for (; (d = this.css.lastIndexOf("/*#")) !== -1; ) {
            let A = this.css.indexOf("*/", d + 3);
            if (A === -1) break;
            for (; d > 0 && this.css[d - 1] === `
`; )
              d--;
            this.css = this.css.slice(0, d) + this.css.slice(A + 2);
          }
        }
      }
    }
    generate() {
      if (this.clearAnnotation(), r && o && this.isMap())
        return this.generateMap();
      {
        let d = "";
        return this.stringify(this.root, (A) => {
          d += A;
        }), [d];
      }
    }
    generateMap() {
      if (this.root)
        this.generateString();
      else if (this.previous().length === 1) {
        let d = this.previous()[0].consumer();
        d.file = this.outputFile(), this.map = i.fromSourceMap(d, {
          ignoreInvalidMapping: !0
        });
      } else
        this.map = new i({
          file: this.outputFile(),
          ignoreInvalidMapping: !0
        }), this.map.addMapping({
          generated: { column: 0, line: 1 },
          original: { column: 0, line: 1 },
          source: this.opts.from ? this.toUrl(this.path(this.opts.from)) : "<no source>"
        });
      return this.isSourcesContent() && this.setSourcesContent(), this.root && this.previous().length > 0 && this.applyPrevMaps(), this.isAnnotation() && this.addAnnotation(), this.isInline() ? [this.css] : [this.css, this.map];
    }
    generateString() {
      this.css = "", this.map = new i({
        file: this.outputFile(),
        ignoreInvalidMapping: !0
      });
      let d = 1, A = 1, h = "<no source>", w = {
        generated: { column: 0, line: 0 },
        original: { column: 0, line: 0 },
        source: ""
      }, C, b;
      this.stringify(this.root, (m, g, x) => {
        if (this.css += m, g && x !== "end" && (w.generated.line = d, w.generated.column = A - 1, g.source && g.source.start ? (w.source = this.sourcePath(g), w.original.line = g.source.start.line, w.original.column = g.source.start.column - 1, this.map.addMapping(w)) : (w.source = h, w.original.line = 1, w.original.column = 0, this.map.addMapping(w))), b = m.match(/\n/g), b ? (d += b.length, C = m.lastIndexOf(`
`), A = m.length - C) : A += m.length, g && x !== "start") {
          let p = g.parent || { raws: {} };
          (!(g.type === "decl" || g.type === "atrule" && !g.nodes) || g !== p.last || p.raws.semicolon) && (g.source && g.source.end ? (w.source = this.sourcePath(g), w.original.line = g.source.end.line, w.original.column = g.source.end.column - 1, w.generated.line = d, w.generated.column = A - 2, this.map.addMapping(w)) : (w.source = h, w.original.line = 1, w.original.column = 0, w.generated.line = d, w.generated.column = A - 1, this.map.addMapping(w)));
        }
      });
    }
    isAnnotation() {
      return this.isInline() ? !0 : typeof this.mapOpts.annotation < "u" ? this.mapOpts.annotation : this.previous().length ? this.previous().some((d) => d.annotation) : !0;
    }
    isInline() {
      if (typeof this.mapOpts.inline < "u")
        return this.mapOpts.inline;
      let d = this.mapOpts.annotation;
      return typeof d < "u" && d !== !0 ? !1 : this.previous().length ? this.previous().some((A) => A.inline) : !0;
    }
    isMap() {
      return typeof this.opts.map < "u" ? !!this.opts.map : this.previous().length > 0;
    }
    isSourcesContent() {
      return typeof this.mapOpts.sourcesContent < "u" ? this.mapOpts.sourcesContent : this.previous().length ? this.previous().some((d) => d.withContent()) : !0;
    }
    outputFile() {
      return this.opts.to ? this.path(this.opts.to) : this.opts.from ? this.path(this.opts.from) : "to.css";
    }
    path(d) {
      if (this.mapOpts.absolute || d.charCodeAt(0) === 60 || /^\w+:\/\//.test(d)) return d;
      let A = this.memoizedPaths.get(d);
      if (A) return A;
      let h = this.opts.to ? e(this.opts.to) : ".";
      typeof this.mapOpts.annotation == "string" && (h = e(t(h, this.mapOpts.annotation)));
      let w = u(h, d);
      return this.memoizedPaths.set(d, w), w;
    }
    previous() {
      if (!this.previousMaps)
        if (this.previousMaps = [], this.root)
          this.root.walk((d) => {
            if (d.source && d.source.input.map) {
              let A = d.source.input.map;
              this.previousMaps.includes(A) || this.previousMaps.push(A);
            }
          });
        else {
          let d = new a(this.originalCSS, this.opts);
          d.map && this.previousMaps.push(d.map);
        }
      return this.previousMaps;
    }
    setSourcesContent() {
      let d = {};
      if (this.root)
        this.root.walk((A) => {
          if (A.source) {
            let h = A.source.input.from;
            if (h && !d[h]) {
              d[h] = !0;
              let w = this.usesFileUrls ? this.toFileUrl(h) : this.toUrl(this.path(h));
              this.map.setSourceContent(w, A.source.input.css);
            }
          }
        });
      else if (this.css) {
        let A = this.opts.from ? this.toUrl(this.path(this.opts.from)) : "<no source>";
        this.map.setSourceContent(A, this.css);
      }
    }
    sourcePath(d) {
      return this.mapOpts.from ? this.toUrl(this.mapOpts.from) : this.usesFileUrls ? this.toFileUrl(d.source.input.from) : this.toUrl(this.path(d.source.input.from));
    }
    toBase64(d) {
      return Buffer ? Buffer.from(d).toString("base64") : window.btoa(unescape(encodeURIComponent(d)));
    }
    toFileUrl(d) {
      let A = this.memoizedFileURLs.get(d);
      if (A) return A;
      if (l) {
        let h = l(d).toString();
        return this.memoizedFileURLs.set(d, h), h;
      } else
        throw new Error(
          "`map.absolute` option is not available in this PostCSS build"
        );
    }
    toUrl(d) {
      let A = this.memoizedURLs.get(d);
      if (A) return A;
      c === "\\" && (d = d.replace(/\\/g, "/"));
      let h = encodeURI(d).replace(/[#?]/g, encodeURIComponent);
      return this.memoizedURLs.set(d, h), h;
    }
  }
  return st = n, st;
}
var ct, Ar;
function zs() {
  if (Ar) return ct;
  Ar = 1;
  const e = 39, u = 34, t = 92, c = 47, s = 10, i = 32, l = 12, a = 9, o = 13, r = 91, n = 93, f = 40, d = 41, A = 123, h = 125, w = 59, C = 42, b = 58, m = 64, g = /[\t\n\f\r "#'()/;[\\\]{}]/g, x = /[\t\n\f\r !"#'():;@[\\\]{}]|\/(?=\*)/g, p = /.[\r\n"'(/\\]/, y = /[\da-f]/i;
  return ct = function(I, D = {}) {
    let _ = I.css.valueOf(), E = D.ignoreErrors, k, F, T, B, O, Q, L, K, j, ee, _e = _.length, M = 0, ue = [], ke = [], Ge = -1;
    function Du() {
      return M;
    }
    function qe(N) {
      throw I.error("Unclosed " + N, M);
    }
    function Iu() {
      return ke.length === 0 && M >= _e;
    }
    function eu(N) {
      if (ke.length) return ke.pop();
      if (M >= _e) return;
      let R = N ? N.ignoreUnclosed : !1;
      switch (k = _.charCodeAt(M), k) {
        case s:
        case i:
        case a:
        case o:
        case l: {
          B = M;
          do
            B += 1, k = _.charCodeAt(B);
          while (k === i || k === s || k === a || k === o || k === l);
          Q = ["space", _.slice(M, B)], M = B - 1;
          break;
        }
        case r:
        case n:
        case A:
        case h:
        case b:
        case w:
        case d: {
          let P = String.fromCharCode(k);
          Q = [P, P, M];
          break;
        }
        case f: {
          if (ee = ue.length ? ue.pop()[1] : "", j = _.charCodeAt(M + 1), ee === "url" && j !== e && j !== u && j !== i && j !== s && j !== a && j !== l && j !== o) {
            B = M;
            do {
              if (L = !1, B = _.indexOf(")", B + 1), B === -1)
                if (E || R) {
                  B = M;
                  break;
                } else
                  qe("bracket");
              for (K = B; _.charCodeAt(K - 1) === t; )
                K -= 1, L = !L;
            } while (L);
            Q = ["brackets", _.slice(M, B + 1), M, B], M = B;
          } else M <= Ge ? Q = ["(", "(", M] : (B = _.indexOf(")", M + 1), F = _.slice(M, B + 1), B === -1 || p.test(F) ? (Ge = B === -1 ? _e : B, Q = ["(", "(", M]) : (Q = ["brackets", F, M, B], M = B));
          break;
        }
        case e:
        case u: {
          O = k === e ? "'" : '"', B = M;
          do {
            if (L = !1, B = _.indexOf(O, B + 1), B === -1)
              if (E || R) {
                B = M + 1;
                break;
              } else
                qe("string");
            for (K = B; _.charCodeAt(K - 1) === t; )
              K -= 1, L = !L;
          } while (L);
          Q = ["string", _.slice(M, B + 1), M, B], M = B;
          break;
        }
        case m: {
          g.lastIndex = M + 1, g.test(_), g.lastIndex === 0 ? B = _.length - 1 : B = g.lastIndex - 2, Q = ["at-word", _.slice(M, B + 1), M, B], M = B;
          break;
        }
        case t: {
          for (B = M, T = !0; _.charCodeAt(B + 1) === t; )
            B += 1, T = !T;
          if (k = _.charCodeAt(B + 1), T && k !== c && k !== i && k !== s && k !== a && k !== o && k !== l && (B += 1, y.test(_.charAt(B)))) {
            for (; y.test(_.charAt(B + 1)); )
              B += 1;
            _.charCodeAt(B + 1) === i && (B += 1);
          }
          Q = ["word", _.slice(M, B + 1), M, B], M = B;
          break;
        }
        default: {
          k === c && _.charCodeAt(M + 1) === C ? (B = _.indexOf("*/", M + 2) + 1, B === 0 && (E || R ? B = _.length : qe("comment")), Q = ["comment", _.slice(M, B + 1), M, B], M = B) : (x.lastIndex = M + 1, x.test(_), x.lastIndex === 0 ? B = _.length - 1 : B = x.lastIndex - 2, Q = ["word", _.slice(M, B + 1), M, B], ue.push(Q), M = B);
          break;
        }
      }
      return M++, Q;
    }
    function S(N) {
      ke.push(N);
    }
    return {
      back: S,
      endOfFile: Iu,
      nextToken: eu,
      position: Du
    };
  }, ct;
}
var ot, hr;
function Xs() {
  if (hr) return ot;
  hr = 1;
  let e = Tt(), u = Cu(), t = vu(), c = $e(), s = Ot(), i = zs();
  const l = {
    empty: !0,
    space: !0
  };
  function a(r) {
    for (let n = r.length - 1; n >= 0; n--) {
      let f = r[n], d = f[3] || f[2];
      if (d) return d;
    }
  }
  class o {
    constructor(n) {
      this.input = n, this.root = new c(), this.current = this.root, this.spaces = "", this.semicolon = !1, this.createTokenizer(), this.root.source = { input: n, start: { column: 1, line: 1, offset: 0 } };
    }
    atrule(n) {
      let f = new e();
      f.name = n[1].slice(1), f.name === "" && this.unnamedAtrule(f, n), this.init(f, n[2]);
      let d, A, h, w = !1, C = !1, b = [], m = [];
      for (; !this.tokenizer.endOfFile(); ) {
        if (n = this.tokenizer.nextToken(), d = n[0], d === "(" || d === "[" ? m.push(d === "(" ? ")" : "]") : d === "{" && m.length > 0 ? m.push("}") : d === m[m.length - 1] && m.pop(), m.length === 0)
          if (d === ";") {
            f.source.end = this.getPosition(n[2]), f.source.end.offset++, this.semicolon = !0;
            break;
          } else if (d === "{") {
            C = !0;
            break;
          } else if (d === "}") {
            if (b.length > 0) {
              for (h = b.length - 1, A = b[h]; A && A[0] === "space"; )
                A = b[--h];
              A && (f.source.end = this.getPosition(A[3] || A[2]), f.source.end.offset++);
            }
            this.end(n);
            break;
          } else
            b.push(n);
        else
          b.push(n);
        if (this.tokenizer.endOfFile()) {
          w = !0;
          break;
        }
      }
      f.raws.between = this.spacesAndCommentsFromEnd(b), b.length ? (f.raws.afterName = this.spacesAndCommentsFromStart(b), this.raw(f, "params", b), w && (n = b[b.length - 1], f.source.end = this.getPosition(n[3] || n[2]), f.source.end.offset++, this.spaces = f.raws.between, f.raws.between = "")) : (f.raws.afterName = "", f.params = ""), C && (f.nodes = [], this.current = f);
    }
    checkMissedSemicolon(n) {
      let f = this.colon(n);
      if (f === !1) return;
      let d = 0, A;
      for (let h = f - 1; h >= 0 && (A = n[h], !(A[0] !== "space" && (d += 1, d === 2))); h--)
        ;
      throw this.input.error(
        "Missed semicolon",
        A[0] === "word" ? A[3] + 1 : A[2]
      );
    }
    colon(n) {
      let f = 0, d, A, h;
      for (let [w, C] of n.entries()) {
        if (A = C, h = A[0], h === "(" && (f += 1), h === ")" && (f -= 1), f === 0 && h === ":")
          if (!d)
            this.doubleColon(A);
          else {
            if (d[0] === "word" && d[1] === "progid")
              continue;
            return w;
          }
        d = A;
      }
      return !1;
    }
    comment(n) {
      let f = new u();
      this.init(f, n[2]), f.source.end = this.getPosition(n[3] || n[2]), f.source.end.offset++;
      let d = n[1].slice(2, -2);
      if (!d.trim())
        f.text = "", f.raws.left = d, f.raws.right = "";
      else {
        let A = d.match(/^(\s*)([^]*\S)(\s*)$/);
        f.text = A[2], f.raws.left = A[1], f.raws.right = A[3];
      }
    }
    createTokenizer() {
      this.tokenizer = i(this.input);
    }
    decl(n, f) {
      let d = new t();
      this.init(d, n[0][2]);
      let A = n[n.length - 1];
      for (A[0] === ";" && (this.semicolon = !0, n.pop()), d.source.end = this.getPosition(
        A[3] || A[2] || a(n)
      ), d.source.end.offset++; n[0][0] !== "word"; )
        n.length === 1 && this.unknownWord(n), d.raws.before += n.shift()[1];
      for (d.source.start = this.getPosition(n[0][2]), d.prop = ""; n.length; ) {
        let m = n[0][0];
        if (m === ":" || m === "space" || m === "comment")
          break;
        d.prop += n.shift()[1];
      }
      d.raws.between = "";
      let h;
      for (; n.length; )
        if (h = n.shift(), h[0] === ":") {
          d.raws.between += h[1];
          break;
        } else
          h[0] === "word" && /\w/.test(h[1]) && this.unknownWord([h]), d.raws.between += h[1];
      (d.prop[0] === "_" || d.prop[0] === "*") && (d.raws.before += d.prop[0], d.prop = d.prop.slice(1));
      let w = [], C;
      for (; n.length && (C = n[0][0], !(C !== "space" && C !== "comment")); )
        w.push(n.shift());
      this.precheckMissedSemicolon(n);
      for (let m = n.length - 1; m >= 0; m--) {
        if (h = n[m], h[1].toLowerCase() === "!important") {
          d.important = !0;
          let g = this.stringFrom(n, m);
          g = this.spacesFromEnd(n) + g, g !== " !important" && (d.raws.important = g);
          break;
        } else if (h[1].toLowerCase() === "important") {
          let g = n.slice(0), x = "";
          for (let p = m; p > 0; p--) {
            let y = g[p][0];
            if (x.trim().startsWith("!") && y !== "space")
              break;
            x = g.pop()[1] + x;
          }
          x.trim().startsWith("!") && (d.important = !0, d.raws.important = x, n = g);
        }
        if (h[0] !== "space" && h[0] !== "comment")
          break;
      }
      n.some((m) => m[0] !== "space" && m[0] !== "comment") && (d.raws.between += w.map((m) => m[1]).join(""), w = []), this.raw(d, "value", w.concat(n), f), d.value.includes(":") && !f && this.checkMissedSemicolon(n);
    }
    doubleColon(n) {
      throw this.input.error(
        "Double colon",
        { offset: n[2] },
        { offset: n[2] + n[1].length }
      );
    }
    emptyRule(n) {
      let f = new s();
      this.init(f, n[2]), f.selector = "", f.raws.between = "", this.current = f;
    }
    end(n) {
      this.current.nodes && this.current.nodes.length && (this.current.raws.semicolon = this.semicolon), this.semicolon = !1, this.current.raws.after = (this.current.raws.after || "") + this.spaces, this.spaces = "", this.current.parent ? (this.current.source.end = this.getPosition(n[2]), this.current.source.end.offset++, this.current = this.current.parent) : this.unexpectedClose(n);
    }
    endFile() {
      this.current.parent && this.unclosedBlock(), this.current.nodes && this.current.nodes.length && (this.current.raws.semicolon = this.semicolon), this.current.raws.after = (this.current.raws.after || "") + this.spaces, this.root.source.end = this.getPosition(this.tokenizer.position());
    }
    freeSemicolon(n) {
      if (this.spaces += n[1], this.current.nodes) {
        let f = this.current.nodes[this.current.nodes.length - 1];
        f && f.type === "rule" && !f.raws.ownSemicolon && (f.raws.ownSemicolon = this.spaces, this.spaces = "", f.source.end = this.getPosition(n[2]), f.source.end.offset += f.raws.ownSemicolon.length);
      }
    }
    // Helpers
    getPosition(n) {
      let f = this.input.fromOffset(n);
      return {
        column: f.col,
        line: f.line,
        offset: n
      };
    }
    init(n, f) {
      this.current.push(n), n.source = {
        input: this.input,
        start: this.getPosition(f)
      }, n.raws.before = this.spaces, this.spaces = "", n.type !== "comment" && (this.semicolon = !1);
    }
    other(n) {
      let f = !1, d = null, A = !1, h = null, w = [], C = n[1].startsWith("--"), b = [], m = n;
      for (; m; ) {
        if (d = m[0], b.push(m), d === "(" || d === "[")
          h || (h = m), w.push(d === "(" ? ")" : "]");
        else if (C && A && d === "{")
          h || (h = m), w.push("}");
        else if (w.length === 0)
          if (d === ";")
            if (A) {
              this.decl(b, C);
              return;
            } else
              break;
          else if (d === "{") {
            this.rule(b);
            return;
          } else if (d === "}") {
            this.tokenizer.back(b.pop()), f = !0;
            break;
          } else d === ":" && (A = !0);
        else d === w[w.length - 1] && (w.pop(), w.length === 0 && (h = null));
        m = this.tokenizer.nextToken();
      }
      if (this.tokenizer.endOfFile() && (f = !0), w.length > 0 && this.unclosedBracket(h), f && A) {
        if (!C)
          for (; b.length && (m = b[b.length - 1][0], !(m !== "space" && m !== "comment")); )
            this.tokenizer.back(b.pop());
        this.decl(b, C);
      } else
        this.unknownWord(b);
    }
    parse() {
      let n;
      for (; !this.tokenizer.endOfFile(); )
        switch (n = this.tokenizer.nextToken(), n[0]) {
          case "space":
            this.spaces += n[1];
            break;
          case ";":
            this.freeSemicolon(n);
            break;
          case "}":
            this.end(n);
            break;
          case "comment":
            this.comment(n);
            break;
          case "at-word":
            this.atrule(n);
            break;
          case "{":
            this.emptyRule(n);
            break;
          default:
            this.other(n);
            break;
        }
      this.endFile();
    }
    precheckMissedSemicolon() {
    }
    raw(n, f, d, A) {
      let h, w, C = d.length, b = "", m = !0, g, x;
      for (let p = 0; p < C; p += 1)
        h = d[p], w = h[0], w === "space" && p === C - 1 && !A ? m = !1 : w === "comment" ? (x = d[p - 1] ? d[p - 1][0] : "empty", g = d[p + 1] ? d[p + 1][0] : "empty", !l[x] && !l[g] ? b.slice(-1) === "," ? m = !1 : b += h[1] : m = !1) : b += h[1];
      if (!m) {
        let p = d.reduce((y, v) => y + v[1], "");
        n.raws[f] = { raw: p, value: b };
      }
      n[f] = b;
    }
    rule(n) {
      n.pop();
      let f = new s();
      this.init(f, n[0][2]), f.raws.between = this.spacesAndCommentsFromEnd(n), this.raw(f, "selector", n), this.current = f;
    }
    spacesAndCommentsFromEnd(n) {
      let f, d = "";
      for (; n.length && (f = n[n.length - 1][0], !(f !== "space" && f !== "comment")); )
        d = n.pop()[1] + d;
      return d;
    }
    // Errors
    spacesAndCommentsFromStart(n) {
      let f, d = "";
      for (; n.length && (f = n[0][0], !(f !== "space" && f !== "comment")); )
        d += n.shift()[1];
      return d;
    }
    spacesFromEnd(n) {
      let f, d = "";
      for (; n.length && (f = n[n.length - 1][0], f === "space"); )
        d = n.pop()[1] + d;
      return d;
    }
    stringFrom(n, f) {
      let d = "";
      for (let A = f; A < n.length; A++)
        d += n[A][1];
      return n.splice(f, n.length - f), d;
    }
    unclosedBlock() {
      let n = this.current.source.start;
      throw this.input.error("Unclosed block", n.line, n.column);
    }
    unclosedBracket(n) {
      throw this.input.error(
        "Unclosed bracket",
        { offset: n[2] },
        { offset: n[2] + 1 }
      );
    }
    unexpectedClose(n) {
      throw this.input.error(
        "Unexpected }",
        { offset: n[2] },
        { offset: n[2] + 1 }
      );
    }
    unknownWord(n) {
      throw this.input.error(
        "Unknown word " + n[0][1],
        { offset: n[0][2] },
        { offset: n[0][2] + n[0][1].length }
      );
    }
    unnamedAtrule(n, f) {
      throw this.input.error(
        "At-rule without name",
        { offset: f[2] },
        { offset: f[2] + f[1].length }
      );
    }
  }
  return ot = o, ot;
}
var lt, br;
function Mt() {
  if (br) return lt;
  br = 1;
  let e = Te(), u = Eu(), t = Xs();
  function c(s, i) {
    let l = new u(s, i), a = new t(l);
    try {
      a.parse();
    } catch (o) {
      throw process.env.NODE_ENV !== "production" && o.name === "CssSyntaxError" && i && i.from && (/\.scss$/i.test(i.from) ? o.message += `
You tried to parse SCSS with the standard CSS parser; try again with the postcss-scss parser` : /\.sass/i.test(i.from) ? o.message += `
You tried to parse Sass with the standard CSS parser; try again with the postcss-sass parser` : /\.less$/i.test(i.from) && (o.message += `
You tried to parse Less with the standard CSS parser; try again with the postcss-less parser`)), o;
    }
    return a.root;
  }
  return lt = c, c.default = c, e.registerParse(c), lt;
}
var ft, pr;
function li() {
  if (pr) return ft;
  pr = 1;
  class e {
    constructor(t, c = {}) {
      if (this.type = "warning", this.text = t, c.node && c.node.source) {
        let s = c.node.rangeBy(c);
        this.line = s.start.line, this.column = s.start.column, this.endLine = s.end.line, this.endColumn = s.end.column;
      }
      for (let s in c) this[s] = c[s];
    }
    toString() {
      return this.node ? this.node.error(this.text, {
        index: this.index,
        plugin: this.plugin,
        word: this.word
      }).message : this.plugin ? this.plugin + ": " + this.text : this.text;
    }
  }
  return ft = e, e.default = e, ft;
}
var dt, gr;
function Qt() {
  if (gr) return dt;
  gr = 1;
  let e = li();
  class u {
    get content() {
      return this.css;
    }
    constructor(c, s, i) {
      this.processor = c, this.messages = [], this.root = s, this.opts = i, this.css = "", this.map = void 0;
    }
    toString() {
      return this.css;
    }
    warn(c, s = {}) {
      s.plugin || this.lastPlugin && this.lastPlugin.postcssPlugin && (s.plugin = this.lastPlugin.postcssPlugin);
      let i = new e(c, s);
      return this.messages.push(i), i;
    }
    warnings() {
      return this.messages.filter((c) => c.type === "warning");
    }
  }
  return dt = u, u.default = u, dt;
}
var At, mr;
function fi() {
  if (mr) return At;
  mr = 1;
  let e = {};
  return At = function(t) {
    e[t] || (e[t] = !0, typeof console < "u" && console.warn && console.warn(t));
  }, At;
}
var ht, xr;
function di() {
  if (xr) return ht;
  xr = 1;
  let e = Te(), u = Nt(), t = oi(), c = Mt(), s = Qt(), i = $e(), l = yu(), { isClean: a, my: o } = Rt(), r = fi();
  const n = {
    atrule: "AtRule",
    comment: "Comment",
    decl: "Declaration",
    document: "Document",
    root: "Root",
    rule: "Rule"
  }, f = {
    AtRule: !0,
    AtRuleExit: !0,
    Comment: !0,
    CommentExit: !0,
    Declaration: !0,
    DeclarationExit: !0,
    Document: !0,
    DocumentExit: !0,
    Once: !0,
    OnceExit: !0,
    postcssPlugin: !0,
    prepare: !0,
    Root: !0,
    RootExit: !0,
    Rule: !0,
    RuleExit: !0
  }, d = {
    Once: !0,
    postcssPlugin: !0,
    prepare: !0
  }, A = 0;
  function h(x) {
    return typeof x == "object" && typeof x.then == "function";
  }
  function w(x) {
    let p = !1, y = n[x.type];
    return x.type === "decl" ? p = x.prop.toLowerCase() : x.type === "atrule" && (p = x.name.toLowerCase()), p && x.append ? [
      y,
      y + "-" + p,
      A,
      y + "Exit",
      y + "Exit-" + p
    ] : p ? [y, y + "-" + p, y + "Exit", y + "Exit-" + p] : x.append ? [y, A, y + "Exit"] : [y, y + "Exit"];
  }
  function C(x) {
    let p;
    return x.type === "document" ? p = ["Document", A, "DocumentExit"] : x.type === "root" ? p = ["Root", A, "RootExit"] : p = w(x), {
      eventIndex: 0,
      events: p,
      iterator: 0,
      node: x,
      visitorIndex: 0,
      visitors: []
    };
  }
  function b(x) {
    return x[a] = !1, x.nodes && x.nodes.forEach((p) => b(p)), x;
  }
  let m = {};
  class g {
    get content() {
      return this.stringify().content;
    }
    get css() {
      return this.stringify().css;
    }
    get map() {
      return this.stringify().map;
    }
    get messages() {
      return this.sync().messages;
    }
    get opts() {
      return this.result.opts;
    }
    get processor() {
      return this.result.processor;
    }
    get root() {
      return this.sync().root;
    }
    get [Symbol.toStringTag]() {
      return "LazyResult";
    }
    constructor(p, y, v) {
      this.stringified = !1, this.processed = !1;
      let I;
      if (typeof y == "object" && y !== null && (y.type === "root" || y.type === "document"))
        I = b(y);
      else if (y instanceof g || y instanceof s)
        I = b(y.root), y.map && (typeof v.map > "u" && (v.map = {}), v.map.inline || (v.map.inline = !1), v.map.prev = y.map);
      else {
        let D = c;
        v.syntax && (D = v.syntax.parse), v.parser && (D = v.parser), D.parse && (D = D.parse);
        try {
          I = D(y, v);
        } catch (_) {
          this.processed = !0, this.error = _;
        }
        I && !I[o] && e.rebuild(I);
      }
      this.result = new s(p, I, v), this.helpers = { ...m, postcss: m, result: this.result }, this.plugins = this.processor.plugins.map((D) => typeof D == "object" && D.prepare ? { ...D, ...D.prepare(this.result) } : D);
    }
    async() {
      return this.error ? Promise.reject(this.error) : this.processed ? Promise.resolve(this.result) : (this.processing || (this.processing = this.runAsync()), this.processing);
    }
    catch(p) {
      return this.async().catch(p);
    }
    finally(p) {
      return this.async().then(p, p);
    }
    getAsyncError() {
      throw new Error("Use process(css).then(cb) to work with async plugins");
    }
    handleError(p, y) {
      let v = this.result.lastPlugin;
      try {
        if (y && y.addToError(p), this.error = p, p.name === "CssSyntaxError" && !p.plugin)
          p.plugin = v.postcssPlugin, p.setMessage();
        else if (v.postcssVersion && process.env.NODE_ENV !== "production") {
          let I = v.postcssPlugin, D = v.postcssVersion, _ = this.result.processor.version, E = D.split("."), k = _.split(".");
          (E[0] !== k[0] || parseInt(E[1]) > parseInt(k[1])) && console.error(
            "Unknown error from PostCSS plugin. Your current PostCSS version is " + _ + ", but " + I + " uses " + D + ". Perhaps this is the source of the error below."
          );
        }
      } catch (I) {
        console && console.error && console.error(I);
      }
      return p;
    }
    prepareVisitors() {
      this.listeners = {};
      let p = (y, v, I) => {
        this.listeners[v] || (this.listeners[v] = []), this.listeners[v].push([y, I]);
      };
      for (let y of this.plugins)
        if (typeof y == "object")
          for (let v in y) {
            if (!f[v] && /^[A-Z]/.test(v))
              throw new Error(
                `Unknown event ${v} in ${y.postcssPlugin}. Try to update PostCSS (${this.processor.version} now).`
              );
            if (!d[v])
              if (typeof y[v] == "object")
                for (let I in y[v])
                  I === "*" ? p(y, v, y[v][I]) : p(
                    y,
                    v + "-" + I.toLowerCase(),
                    y[v][I]
                  );
              else typeof y[v] == "function" && p(y, v, y[v]);
          }
      this.hasListener = Object.keys(this.listeners).length > 0;
    }
    async runAsync() {
      this.plugin = 0;
      for (let p = 0; p < this.plugins.length; p++) {
        let y = this.plugins[p], v = this.runOnRoot(y);
        if (h(v))
          try {
            await v;
          } catch (I) {
            throw this.handleError(I);
          }
      }
      if (this.prepareVisitors(), this.hasListener) {
        let p = this.result.root;
        for (; !p[a]; ) {
          p[a] = !0;
          let y = [C(p)];
          for (; y.length > 0; ) {
            let v = this.visitTick(y);
            if (h(v))
              try {
                await v;
              } catch (I) {
                let D = y[y.length - 1].node;
                throw this.handleError(I, D);
              }
          }
        }
        if (this.listeners.OnceExit)
          for (let [y, v] of this.listeners.OnceExit) {
            this.result.lastPlugin = y;
            try {
              if (p.type === "document") {
                let I = p.nodes.map(
                  (D) => v(D, this.helpers)
                );
                await Promise.all(I);
              } else
                await v(p, this.helpers);
            } catch (I) {
              throw this.handleError(I);
            }
          }
      }
      return this.processed = !0, this.stringify();
    }
    runOnRoot(p) {
      this.result.lastPlugin = p;
      try {
        if (typeof p == "object" && p.Once) {
          if (this.result.root.type === "document") {
            let y = this.result.root.nodes.map(
              (v) => p.Once(v, this.helpers)
            );
            return h(y[0]) ? Promise.all(y) : y;
          }
          return p.Once(this.result.root, this.helpers);
        } else if (typeof p == "function")
          return p(this.result.root, this.result);
      } catch (y) {
        throw this.handleError(y);
      }
    }
    stringify() {
      if (this.error) throw this.error;
      if (this.stringified) return this.result;
      this.stringified = !0, this.sync();
      let p = this.result.opts, y = l;
      p.syntax && (y = p.syntax.stringify), p.stringifier && (y = p.stringifier), y.stringify && (y = y.stringify);
      let v = this.result.root.source;
      if (p.map === void 0 && !(v && v.input && v.input.map)) {
        let _ = "";
        return y(this.result.root, (E) => {
          _ += E;
        }), this.result.css = _, this.result;
      }
      let D = new t(y, this.result.root, this.result.opts).generate();
      return this.result.css = D[0], this.result.map = D[1], this.result;
    }
    sync() {
      if (this.error) throw this.error;
      if (this.processed) return this.result;
      if (this.processed = !0, this.processing)
        throw this.getAsyncError();
      for (let p of this.plugins) {
        let y = this.runOnRoot(p);
        if (h(y))
          throw this.getAsyncError();
      }
      if (this.prepareVisitors(), this.hasListener) {
        let p = this.result.root;
        for (; !p[a]; )
          p[a] = !0, this.walkSync(p);
        if (this.listeners.OnceExit)
          if (p.type === "document")
            for (let y of p.nodes)
              this.visitSync(this.listeners.OnceExit, y);
          else
            this.visitSync(this.listeners.OnceExit, p);
      }
      return this.result;
    }
    then(p, y) {
      return process.env.NODE_ENV !== "production" && ("from" in this.opts || r(
        "Without `from` option PostCSS could generate wrong source map and will not find Browserslist config. Set it to CSS file path or to `undefined` to prevent this warning."
      )), this.async().then(p, y);
    }
    toString() {
      return this.css;
    }
    visitSync(p, y) {
      for (let [v, I] of p) {
        this.result.lastPlugin = v;
        let D;
        try {
          D = I(y, this.helpers);
        } catch (_) {
          throw this.handleError(_, y.proxyOf);
        }
        if (y.type !== "root" && y.type !== "document" && !y.parent)
          return !0;
        if (h(D))
          throw this.getAsyncError();
      }
    }
    visitTick(p) {
      let y = p[p.length - 1], { node: v, visitors: I } = y;
      if (v.type !== "root" && v.type !== "document" && !v.parent) {
        p.pop();
        return;
      }
      if (I.length > 0 && y.visitorIndex < I.length) {
        let [_, E] = I[y.visitorIndex];
        y.visitorIndex += 1, y.visitorIndex === I.length && (y.visitors = [], y.visitorIndex = 0), this.result.lastPlugin = _;
        try {
          return E(v.toProxy(), this.helpers);
        } catch (k) {
          throw this.handleError(k, v);
        }
      }
      if (y.iterator !== 0) {
        let _ = y.iterator, E;
        for (; E = v.nodes[v.indexes[_]]; )
          if (v.indexes[_] += 1, !E[a]) {
            E[a] = !0, p.push(C(E));
            return;
          }
        y.iterator = 0, delete v.indexes[_];
      }
      let D = y.events;
      for (; y.eventIndex < D.length; ) {
        let _ = D[y.eventIndex];
        if (y.eventIndex += 1, _ === A) {
          v.nodes && v.nodes.length && (v[a] = !0, y.iterator = v.getIterator());
          return;
        } else if (this.listeners[_]) {
          y.visitors = this.listeners[_];
          return;
        }
      }
      p.pop();
    }
    walkSync(p) {
      p[a] = !0;
      let y = w(p);
      for (let v of y)
        if (v === A)
          p.nodes && p.each((I) => {
            I[a] || this.walkSync(I);
          });
        else {
          let I = this.listeners[v];
          if (I && this.visitSync(I, p.toProxy()))
            return;
        }
    }
    warnings() {
      return this.sync().warnings();
    }
  }
  return g.registerPostcss = (x) => {
    m = x;
  }, ht = g, g.default = g, i.registerLazyResult(g), u.registerLazyResult(g), ht;
}
var bt, yr;
function $s() {
  if (yr) return bt;
  yr = 1;
  let e = oi(), u = Mt(), t = Qt(), c = yu(), s = fi();
  class i {
    get content() {
      return this.result.css;
    }
    get css() {
      return this.result.css;
    }
    get map() {
      return this.result.map;
    }
    get messages() {
      return [];
    }
    get opts() {
      return this.result.opts;
    }
    get processor() {
      return this.result.processor;
    }
    get root() {
      if (this._root)
        return this._root;
      let a, o = u;
      try {
        a = o(this._css, this._opts);
      } catch (r) {
        this.error = r;
      }
      if (this.error)
        throw this.error;
      return this._root = a, a;
    }
    get [Symbol.toStringTag]() {
      return "NoWorkResult";
    }
    constructor(a, o, r) {
      o = o.toString(), this.stringified = !1, this._processor = a, this._css = o, this._opts = r, this._map = void 0;
      let n = c;
      this.result = new t(this._processor, void 0, this._opts), this.result.css = o;
      let f = this;
      Object.defineProperty(this.result, "root", {
        get() {
          return f.root;
        }
      });
      let d = new e(n, void 0, this._opts, o);
      if (d.isMap()) {
        let [A, h] = d.generate();
        A && (this.result.css = A), h && (this.result.map = h);
      } else
        d.clearAnnotation(), this.result.css = d.css;
    }
    async() {
      return this.error ? Promise.reject(this.error) : Promise.resolve(this.result);
    }
    catch(a) {
      return this.async().catch(a);
    }
    finally(a) {
      return this.async().then(a, a);
    }
    sync() {
      if (this.error) throw this.error;
      return this.result;
    }
    then(a, o) {
      return process.env.NODE_ENV !== "production" && ("from" in this._opts || s(
        "Without `from` option PostCSS could generate wrong source map and will not find Browserslist config. Set it to CSS file path or to `undefined` to prevent this warning."
      )), this.async().then(a, o);
    }
    toString() {
      return this._css;
    }
    warnings() {
      return [];
    }
  }
  return bt = i, i.default = i, bt;
}
var pt, wr;
function ec() {
  if (wr) return pt;
  wr = 1;
  let e = Nt(), u = di(), t = $s(), c = $e();
  class s {
    constructor(l = []) {
      this.version = "8.5.12", this.plugins = this.normalize(l);
    }
    normalize(l) {
      let a = [];
      for (let o of l)
        if (o.postcss === !0 ? o = o() : o.postcss && (o = o.postcss), typeof o == "object" && Array.isArray(o.plugins))
          a = a.concat(o.plugins);
        else if (typeof o == "object" && o.postcssPlugin)
          a.push(o);
        else if (typeof o == "function")
          a.push(o);
        else if (typeof o == "object" && (o.parse || o.stringify)) {
          if (process.env.NODE_ENV !== "production")
            throw new Error(
              "PostCSS syntaxes cannot be used as plugins. Instead, please use one of the syntax/parser/stringifier options as outlined in your PostCSS runner documentation."
            );
        } else
          throw new Error(o + " is not a PostCSS plugin");
      return a;
    }
    process(l, a = {}) {
      return !this.plugins.length && !a.parser && !a.stringifier && !a.syntax ? new t(this, l, a) : new u(this, l, a);
    }
    use(l) {
      return this.plugins = this.plugins.concat(this.normalize([l])), this;
    }
  }
  return pt = s, s.default = s, c.registerProcessor(s), e.registerProcessor(s), pt;
}
var gt, Cr;
function uc() {
  if (Cr) return gt;
  Cr = 1;
  let e = Tt(), u = Cu(), t = Te(), c = St(), s = vu(), i = Nt(), l = Vs(), a = Eu(), o = di(), r = ci(), n = wu(), f = Mt(), d = ec(), A = Qt(), h = $e(), w = Ot(), C = yu(), b = li();
  function m(...g) {
    return g.length === 1 && Array.isArray(g[0]) && (g = g[0]), new d(g);
  }
  return m.plugin = function(x, p) {
    let y = !1;
    function v(...D) {
      console && console.warn && !y && (y = !0, console.warn(
        x + `: postcss.plugin was deprecated. Migration guide:
https://evilmartians.com/chronicles/postcss-8-plugin-migration`
      ), process.env.LANG && process.env.LANG.startsWith("cn") && console.warn(
        x + `: 里面 postcss.plugin 被弃用. 迁移指南:
https://www.w3ctech.com/topic/2226`
      ));
      let _ = p(...D);
      return _.postcssPlugin = x, _.postcssVersion = new d().version, _;
    }
    let I;
    return Object.defineProperty(v, "postcss", {
      get() {
        return I || (I = v()), I;
      }
    }), v.process = function(D, _, E) {
      return m([v(E)]).process(D, _);
    }, v;
  }, m.stringify = C, m.parse = f, m.fromJSON = l, m.list = r, m.comment = (g) => new u(g), m.atRule = (g) => new e(g), m.decl = (g) => new s(g), m.rule = (g) => new w(g), m.root = (g) => new h(g), m.document = (g) => new i(g), m.CssSyntaxError = c, m.Declaration = s, m.Container = t, m.Processor = d, m.Document = i, m.Comment = u, m.Warning = b, m.AtRule = e, m.Result = A, m.Input = a, m.Rule = w, m.Root = h, m.Node = n, o.registerPostcss(m), gt = m, m.default = m, gt;
}
var mt, vr;
function tc() {
  if (vr) return mt;
  vr = 1;
  const e = /* @__PURE__ */ Gs(), u = qs(), { isPlainObject: t } = Hs(), c = Ws(), s = Ks(), { parse: i } = uc(), l = [
    "img",
    "audio",
    "video",
    "picture",
    "svg",
    "object",
    "map",
    "iframe",
    "embed"
  ], a = ["script", "style"];
  function o(C, b) {
    C && Object.keys(C).forEach(function(m) {
      b(C[m], m);
    });
  }
  function r(C, b) {
    return {}.hasOwnProperty.call(C, b);
  }
  function n(C, b) {
    const m = [];
    return o(C, function(g) {
      b(g) && m.push(g);
    }), m;
  }
  function f(C) {
    for (const b in C)
      if (r(C, b))
        return !1;
    return !0;
  }
  function d(C) {
    return C.map(function(b) {
      if (!b.url)
        throw new Error("URL missing");
      return b.url + (b.w ? ` ${b.w}w` : "") + (b.h ? ` ${b.h}h` : "") + (b.d ? ` ${b.d}x` : "");
    }).join(", ");
  }
  mt = h;
  const A = /^[^\0\t\n\f\r /<=>]+$/;
  function h(C, b, m) {
    if (C == null)
      return "";
    typeof C == "number" && (C = C.toString());
    let g = "", x = "";
    function p(S, N) {
      const R = this;
      this.tag = S, this.attribs = N || {}, this.tagPosition = g.length, this.text = "", this.openingTagLength = 0, this.mediaChildren = [], this.updateParentNodeText = function() {
        if (O.length) {
          const P = O[O.length - 1];
          P.text += R.text;
        }
      }, this.updateParentNodeMediaChildren = function() {
        O.length && l.includes(this.tag) && O[O.length - 1].mediaChildren.push(this.tag);
      };
    }
    b = Object.assign({}, h.defaults, b), b.parser = Object.assign({}, w, b.parser);
    const y = function(S) {
      return b.allowedTags === !1 || (b.allowedTags || []).indexOf(S) > -1;
    };
    a.forEach(function(S) {
      y(S) && !b.allowVulnerableTags && console.warn(`

⚠️ Your \`allowedTags\` option includes, \`${S}\`, which is inherently
vulnerable to XSS attacks. Please remove it from \`allowedTags\`.
Or, to disable this warning, add the \`allowVulnerableTags\` option
and ensure you are accounting for this risk.

`);
    });
    const v = b.nonTextTags || [
      "script",
      "style",
      "textarea",
      "option"
    ];
    let I, D;
    b.allowedAttributes && (I = {}, D = {}, o(b.allowedAttributes, function(S, N) {
      I[N] = [];
      const R = [];
      S.forEach(function(P) {
        typeof P == "string" && P.indexOf("*") >= 0 ? R.push(u(P).replace(/\\\*/g, ".*")) : I[N].push(P);
      }), R.length && (D[N] = new RegExp("^(" + R.join("|") + ")$"));
    }));
    const _ = {}, E = {}, k = {};
    o(b.allowedClasses, function(S, N) {
      if (I && (r(I, N) || (I[N] = []), I[N].push("class")), _[N] = S, Array.isArray(S)) {
        const R = [];
        _[N] = [], k[N] = [], S.forEach(function(P) {
          typeof P == "string" && P.indexOf("*") >= 0 ? R.push(u(P).replace(/\\\*/g, ".*")) : P instanceof RegExp ? k[N].push(P) : _[N].push(P);
        }), R.length && (E[N] = new RegExp("^(" + R.join("|") + ")$"));
      }
    });
    const F = {};
    let T;
    o(b.transformTags, function(S, N) {
      let R;
      typeof S == "function" ? R = S : typeof S == "string" && (R = h.simpleTransform(S)), N === "*" ? T = R : F[N] = R;
    });
    let B, O, Q, L, K, j, ee = !1;
    M();
    const _e = new e.Parser({
      onopentag: function(S, N) {
        if (b.onOpenTag && b.onOpenTag(S, N), b.enforceHtmlBoundary && S === "html" && M(), K) {
          j++;
          return;
        }
        const R = new p(S, N);
        O.push(R);
        let P = !1;
        const V = !!R.text;
        let z;
        if (r(F, S) && (z = F[S](S, N), R.attribs = N = z.attribs, z.text !== void 0 && (R.innerText = z.text), S !== z.tagName && (R.name = S = z.tagName, L[B] = z.tagName)), T && (z = T(S, N), R.attribs = N = z.attribs, S !== z.tagName && (R.name = S = z.tagName, L[B] = z.tagName)), (!y(S) || b.disallowedTagsMode === "recursiveEscape" && !f(Q) || b.nestingLimit != null && B >= b.nestingLimit) && (P = !0, Q[B] = !0, (b.disallowedTagsMode === "discard" || b.disallowedTagsMode === "completelyDiscard") && v.indexOf(S) !== -1 && (K = !0, j = 1)), B++, P) {
          if (b.disallowedTagsMode === "discard" || b.disallowedTagsMode === "completelyDiscard") {
            if (R.innerText && !V) {
              const U = ue(R.innerText);
              b.textFilter ? g += b.textFilter(U, S) : g += U, ee = !0;
            }
            return;
          }
          x = g, g = "";
        }
        g += "<" + S, S === "script" && (b.allowedScriptHostnames || b.allowedScriptDomains) && (R.innerText = ""), P && (b.disallowedTagsMode === "escape" || b.disallowedTagsMode === "recursiveEscape") && b.preserveEscapedAttributes ? o(N, function(U, q) {
          g += " " + q + '="' + ue(U || "", !0) + '"';
        }) : (!I || r(I, S) || I["*"]) && o(N, function(U, q) {
          if (!A.test(q)) {
            delete R.attribs[q];
            return;
          }
          if (U === "" && !b.allowedEmptyAttributes.includes(q) && (b.nonBooleanAttributes.includes(q) || b.nonBooleanAttributes.includes("*"))) {
            delete R.attribs[q];
            return;
          }
          let _u = !1;
          if (!I || r(I, S) && I[S].indexOf(q) !== -1 || I["*"] && I["*"].indexOf(q) !== -1 || r(D, S) && D[S].test(q) || D["*"] && D["*"].test(q))
            _u = !0;
          else if (I && I[S]) {
            for (const H of I[S])
              if (t(H) && H.name && H.name === q) {
                _u = !0;
                let W = "";
                if (H.multiple === !0) {
                  const Be = U.split(" ");
                  for (const pe of Be)
                    H.values.indexOf(pe) !== -1 && (W === "" ? W = pe : W += " " + pe);
                } else H.values.indexOf(U) >= 0 && (W = U);
                U = W;
              }
          }
          if (_u) {
            if (b.allowedSchemesAppliedToAttributes.indexOf(q) !== -1 && ke(S, U)) {
              delete R.attribs[q];
              return;
            }
            if (S === "script" && q === "src") {
              let H = !0;
              try {
                const W = Ge(U);
                if (b.allowedScriptHostnames || b.allowedScriptDomains) {
                  const Be = (b.allowedScriptHostnames || []).find(function(ie) {
                    return ie === W.url.hostname;
                  }), pe = (b.allowedScriptDomains || []).find(function(ie) {
                    return W.url.hostname === ie || W.url.hostname.endsWith(`.${ie}`);
                  });
                  H = Be || pe;
                }
              } catch {
                H = !1;
              }
              if (!H) {
                delete R.attribs[q];
                return;
              }
            }
            if (S === "iframe" && q === "src") {
              let H = !0;
              try {
                const W = Ge(U);
                if (W.isRelativeUrl)
                  H = r(b, "allowIframeRelativeUrls") ? b.allowIframeRelativeUrls : !b.allowedIframeHostnames && !b.allowedIframeDomains;
                else if (b.allowedIframeHostnames || b.allowedIframeDomains) {
                  const Be = (b.allowedIframeHostnames || []).find(function(ie) {
                    return ie === W.url.hostname;
                  }), pe = (b.allowedIframeDomains || []).find(function(ie) {
                    return W.url.hostname === ie || W.url.hostname.endsWith(`.${ie}`);
                  });
                  H = Be || pe;
                }
              } catch {
                H = !1;
              }
              if (!H) {
                delete R.attribs[q];
                return;
              }
            }
            if (q === "srcset")
              try {
                let H = s(U);
                if (H.forEach(function(W) {
                  ke("srcset", W.url) && (W.evil = !0);
                }), H = n(H, function(W) {
                  return !W.evil;
                }), H.length)
                  U = d(n(H, function(W) {
                    return !W.evil;
                  })), R.attribs[q] = U;
                else {
                  delete R.attribs[q];
                  return;
                }
              } catch {
                delete R.attribs[q];
                return;
              }
            if (q === "class") {
              const H = _[S], W = _["*"], Be = E[S], pe = k[S], ie = k["*"], Ai = E["*"], Lt = [
                Be,
                Ai
              ].concat(pe, ie).filter(function(hi) {
                return hi;
              });
              if (H && W ? U = eu(
                U,
                c(H, W),
                Lt
              ) : U = eu(
                U,
                H || W,
                Lt
              ), !U.length) {
                delete R.attribs[q];
                return;
              }
            }
            if (q === "style") {
              if (b.parseStyleAttributes)
                try {
                  const H = i(S + " {" + U + "}", { map: !1 }), W = Du(
                    H,
                    b.allowedStyles
                  );
                  if (U = qe(W), U.length === 0) {
                    delete R.attribs[q];
                    return;
                  }
                } catch {
                  typeof window < "u" && console.warn('Failed to parse "' + S + " {" + U + `}", If you're running this in a browser, we recommend to disable style parsing: options.parseStyleAttributes: false, since this only works in a node environment due to a postcss dependency, More info: https://github.com/apostrophecms/sanitize-html/issues/547`), delete R.attribs[q];
                  return;
                }
              else if (b.allowedStyles)
                throw new Error("allowedStyles option cannot be used together with parseStyleAttributes: false.");
            }
            g += " " + q, U && U.length ? g += '="' + ue(U, !0) + '"' : b.allowedEmptyAttributes.includes(q) && (g += '=""');
          } else
            delete R.attribs[q];
        }), b.selfClosing.indexOf(S) !== -1 ? g += " />" : (g += ">", R.innerText && !V && !b.textFilter && (g += ue(R.innerText), ee = !0)), P && (g = x + ue(g), x = ""), R.openingTagLength = g.length - R.tagPosition;
      },
      ontext: function(S) {
        if (K)
          return;
        const N = O[O.length - 1];
        let R;
        if (N && (R = N.tag, S = N.innerText !== void 0 ? N.innerText : S), b.disallowedTagsMode === "completelyDiscard" && !y(R))
          S = "";
        else if ((b.disallowedTagsMode === "discard" || b.disallowedTagsMode === "completelyDiscard") && (R === "script" || R === "style"))
          g += S;
        else if ((b.disallowedTagsMode === "discard" || b.disallowedTagsMode === "completelyDiscard") && (R === "textarea" || R === "xmp"))
          g += S;
        else if (!ee) {
          const P = ue(S, !1);
          b.textFilter ? g += b.textFilter(P, R) : g += P;
        }
        if (O.length) {
          const P = O[O.length - 1];
          P.text += S;
        }
      },
      onclosetag: function(S, N) {
        if (b.onCloseTag && b.onCloseTag(S, N), K)
          if (j--, !j)
            K = !1;
          else
            return;
        const R = O.pop();
        if (!R)
          return;
        if (R.tag !== S) {
          O.push(R);
          return;
        }
        K = b.enforceHtmlBoundary ? S === "html" : !1, B--;
        const P = Q[B];
        if (P) {
          if (delete Q[B], b.disallowedTagsMode === "discard" || b.disallowedTagsMode === "completelyDiscard") {
            R.updateParentNodeText();
            return;
          }
          x = g, g = "";
        }
        if (L[B] && (S = L[B], delete L[B]), b.exclusiveFilter) {
          const V = b.exclusiveFilter(R);
          if (V === "excludeTag") {
            P && (g = x, x = ""), g = g.substring(0, R.tagPosition) + g.substring(R.tagPosition + R.openingTagLength);
            return;
          } else if (V) {
            g = g.substring(0, R.tagPosition);
            return;
          }
        }
        if (R.updateParentNodeMediaChildren(), R.updateParentNodeText(), // Already output />
        b.selfClosing.indexOf(S) !== -1 || // Escaped tag, closing tag is implied
        N && !y(S) && ["escape", "recursiveEscape"].indexOf(b.disallowedTagsMode) >= 0) {
          P && (g = x, x = "");
          return;
        }
        g += "</" + S + ">", P && (g = x + ue(g), x = ""), ee = !1;
      }
    }, b.parser);
    if (_e.write(C), _e.end(), b.disallowedTagsMode === "escape" || b.disallowedTagsMode === "recursiveEscape") {
      const S = _e.endIndex;
      if (S != null && S >= 0 && S < C.length) {
        const N = C.substring(S);
        g += ue(N);
      } else (S == null || S < 0) && C.length > 0 && g === "" && (g = ue(C));
    }
    return g;
    function M() {
      g = "", B = 0, O = [], Q = {}, L = {}, K = !1, j = 0;
    }
    function ue(S, N) {
      return typeof S != "string" && (S = S + ""), b.parser.decodeEntities && (S = S.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;"), N && (S = S.replace(/"/g, "&quot;"))), S = S.replace(/&(?![a-zA-Z0-9#]{1,20};)/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;"), N && (S = S.replace(/"/g, "&quot;")), S;
    }
    function ke(S, N) {
      for (N = N.replace(/[\x00-\x20]+/g, ""); ; ) {
        const V = N.indexOf("<!--");
        if (V === -1)
          break;
        const z = N.indexOf("-->", V + 4);
        if (z === -1)
          break;
        N = N.substring(0, V) + N.substring(z + 3);
      }
      const R = N.match(/^([a-zA-Z][a-zA-Z0-9.\-+]*):/);
      if (!R)
        return N.match(/^[/\\]{2}/) ? !b.allowProtocolRelative : !1;
      const P = R[1].toLowerCase();
      return r(b.allowedSchemesByTag, S) ? b.allowedSchemesByTag[S].indexOf(P) === -1 : !b.allowedSchemes || b.allowedSchemes.indexOf(P) === -1;
    }
    function Ge(S) {
      if (S = S.replace(/^(\w+:)?\s*[\\/]\s*[\\/]/, "$1//"), S.startsWith("relative:"))
        throw new Error("relative: exploit attempt");
      let N = "relative://relative-site";
      for (let V = 0; V < 100; V++)
        N += `/${V}`;
      const R = new URL(S, N);
      return {
        isRelativeUrl: R && R.hostname === "relative-site" && R.protocol === "relative:",
        url: R
      };
    }
    function Du(S, N) {
      if (!N)
        return S;
      const R = S.nodes[0];
      let P;
      return N[R.selector] && N["*"] ? P = c(
        N[R.selector],
        N["*"]
      ) : P = N[R.selector] || N["*"], P && (S.nodes[0].nodes = R.nodes.reduce(Iu(P), [])), S;
    }
    function qe(S) {
      return S.nodes[0].nodes.reduce(function(N, R) {
        return N.push(
          `${R.prop}:${R.value}${R.important ? " !important" : ""}`
        ), N;
      }, []).join(";");
    }
    function Iu(S) {
      return function(N, R) {
        return r(S, R.prop) && S[R.prop].some(function(V) {
          return V.test(R.value);
        }) && N.push(R), N;
      };
    }
    function eu(S, N, R) {
      return N ? (S = S.split(/\s+/), S.filter(function(P) {
        return N.indexOf(P) !== -1 || R.some(function(V) {
          return V.test(P);
        });
      }).join(" ")) : S;
    }
  }
  const w = {
    decodeEntities: !0
  };
  return h.defaults = {
    allowedTags: [
      // Sections derived from MDN element categories and limited to the more
      // benign categories.
      // https://developer.mozilla.org/en-US/docs/Web/HTML/Element
      // Content sectioning
      "address",
      "article",
      "aside",
      "footer",
      "header",
      "h1",
      "h2",
      "h3",
      "h4",
      "h5",
      "h6",
      "hgroup",
      "main",
      "nav",
      "section",
      // Text content
      "blockquote",
      "dd",
      "div",
      "dl",
      "dt",
      "figcaption",
      "figure",
      "hr",
      "li",
      "menu",
      "ol",
      "p",
      "pre",
      "ul",
      // Inline text semantics
      "a",
      "abbr",
      "b",
      "bdi",
      "bdo",
      "br",
      "cite",
      "code",
      "data",
      "dfn",
      "em",
      "i",
      "kbd",
      "mark",
      "q",
      "rb",
      "rp",
      "rt",
      "rtc",
      "ruby",
      "s",
      "samp",
      "small",
      "span",
      "strong",
      "sub",
      "sup",
      "time",
      "u",
      "var",
      "wbr",
      // Table content
      "caption",
      "col",
      "colgroup",
      "table",
      "tbody",
      "td",
      "tfoot",
      "th",
      "thead",
      "tr"
    ],
    // Tags that cannot be boolean
    nonBooleanAttributes: [
      "abbr",
      "accept",
      "accept-charset",
      "accesskey",
      "action",
      "allow",
      "alt",
      "as",
      "autocapitalize",
      "autocomplete",
      "blocking",
      "charset",
      "cite",
      "class",
      "color",
      "cols",
      "colspan",
      "content",
      "contenteditable",
      "coords",
      "crossorigin",
      "data",
      "datetime",
      "decoding",
      "dir",
      "dirname",
      "download",
      "draggable",
      "enctype",
      "enterkeyhint",
      "fetchpriority",
      "for",
      "form",
      "formaction",
      "formenctype",
      "formmethod",
      "formtarget",
      "headers",
      "height",
      "hidden",
      "high",
      "href",
      "hreflang",
      "http-equiv",
      "id",
      "imagesizes",
      "imagesrcset",
      "inputmode",
      "integrity",
      "is",
      "itemid",
      "itemprop",
      "itemref",
      "itemtype",
      "kind",
      "label",
      "lang",
      "list",
      "loading",
      "low",
      "max",
      "maxlength",
      "media",
      "method",
      "min",
      "minlength",
      "name",
      "nonce",
      "optimum",
      "pattern",
      "ping",
      "placeholder",
      "popover",
      "popovertarget",
      "popovertargetaction",
      "poster",
      "preload",
      "referrerpolicy",
      "rel",
      "rows",
      "rowspan",
      "sandbox",
      "scope",
      "shape",
      "size",
      "sizes",
      "slot",
      "span",
      "spellcheck",
      "src",
      "srcdoc",
      "srclang",
      "srcset",
      "start",
      "step",
      "style",
      "tabindex",
      "target",
      "title",
      "translate",
      "type",
      "usemap",
      "value",
      "width",
      "wrap",
      // Event handlers
      "onauxclick",
      "onafterprint",
      "onbeforematch",
      "onbeforeprint",
      "onbeforeunload",
      "onbeforetoggle",
      "onblur",
      "oncancel",
      "oncanplay",
      "oncanplaythrough",
      "onchange",
      "onclick",
      "onclose",
      "oncontextlost",
      "oncontextmenu",
      "oncontextrestored",
      "oncopy",
      "oncuechange",
      "oncut",
      "ondblclick",
      "ondrag",
      "ondragend",
      "ondragenter",
      "ondragleave",
      "ondragover",
      "ondragstart",
      "ondrop",
      "ondurationchange",
      "onemptied",
      "onended",
      "onerror",
      "onfocus",
      "onformdata",
      "onhashchange",
      "oninput",
      "oninvalid",
      "onkeydown",
      "onkeypress",
      "onkeyup",
      "onlanguagechange",
      "onload",
      "onloadeddata",
      "onloadedmetadata",
      "onloadstart",
      "onmessage",
      "onmessageerror",
      "onmousedown",
      "onmouseenter",
      "onmouseleave",
      "onmousemove",
      "onmouseout",
      "onmouseover",
      "onmouseup",
      "onoffline",
      "ononline",
      "onpagehide",
      "onpageshow",
      "onpaste",
      "onpause",
      "onplay",
      "onplaying",
      "onpopstate",
      "onprogress",
      "onratechange",
      "onreset",
      "onresize",
      "onrejectionhandled",
      "onscroll",
      "onscrollend",
      "onsecuritypolicyviolation",
      "onseeked",
      "onseeking",
      "onselect",
      "onslotchange",
      "onstalled",
      "onstorage",
      "onsubmit",
      "onsuspend",
      "ontimeupdate",
      "ontoggle",
      "onunhandledrejection",
      "onunload",
      "onvolumechange",
      "onwaiting",
      "onwheel"
    ],
    disallowedTagsMode: "discard",
    allowedAttributes: {
      a: ["href", "name", "target"],
      // We don't currently allow img itself by default, but
      // these attributes would make sense if we did.
      img: ["src", "srcset", "alt", "title", "width", "height", "loading"]
    },
    allowedEmptyAttributes: [
      "alt"
    ],
    // Lots of these won't come up by default because we don't allow them
    selfClosing: ["img", "br", "hr", "area", "base", "basefont", "input", "link", "meta"],
    // URL schemes we permit
    allowedSchemes: ["http", "https", "ftp", "mailto", "tel"],
    allowedSchemesByTag: {},
    allowedSchemesAppliedToAttributes: ["href", "src", "cite"],
    allowProtocolRelative: !0,
    enforceHtmlBoundary: !1,
    parseStyleAttributes: !0,
    preserveEscapedAttributes: !1
  }, h.simpleTransform = function(C, b, m) {
    return m = m === void 0 ? !0 : m, b = b || {}, function(g, x) {
      let p;
      if (m)
        for (p in b)
          x[p] = b[p];
      else
        x = b;
      return {
        tagName: C,
        attribs: x
      };
    };
  }, mt;
}
var rc = /* @__PURE__ */ tc();
const Er = /* @__PURE__ */ _s(rc), ic = () => Fi(), nc = [
  "address",
  "article",
  "aside",
  "footer",
  "header",
  "h1",
  "h2",
  "h3",
  "h4",
  "h5",
  "h6",
  "hgroup",
  "main",
  "nav",
  "section",
  "blockquote",
  "dd",
  "div",
  "dl",
  "dt",
  "figcaption",
  "figure",
  "hr",
  "li",
  "ol",
  "p",
  "pre",
  "ul",
  "a",
  "abbr",
  "b",
  "bdi",
  "bdo",
  "br",
  "cite",
  "code",
  "data",
  "dfn",
  "em",
  "i",
  "img",
  "kbd",
  "mark",
  "q",
  "rb",
  "rp",
  "rt",
  "rtc",
  "ruby",
  "s",
  "samp",
  "small",
  "span",
  "strong",
  "sub",
  "sup",
  "time",
  "u",
  "var",
  "wbr",
  "caption",
  "col",
  "colgroup",
  "table",
  "tbody",
  "td",
  "tfoot",
  "th",
  "thead",
  "tr"
], ac = {
  a: ["href", "name", "target"],
  span: ["class"],
  pre: ["class"],
  code: ["class"],
  img: ["src", "alt", "title", "width", "height", "loading"]
}, sc = ["innerHTML"], cc = {
  key: 1,
  class: "markdown-empty"
}, oc = /* @__PURE__ */ pi({
  __name: "markdown-view",
  setup(e) {
    const u = ic(), t = Si(), c = new re({
      html: !1,
      breaks: !0,
      linkify: !0,
      typographer: !1
    }), s = uu(
      () => u.value.content || t.value || ""
    ), i = uu(() => {
      const o = u.value.allowedTags;
      return o && o.length > 0 ? o : nc;
    }), l = uu(() => {
      const o = u.value.allowedAttributes;
      if (o)
        try {
          return JSON.parse(o);
        } catch {
        }
      return ac;
    }), a = uu(() => {
      if (!s.value) return "";
      const o = c.render(s.value);
      return Er(o, {
        allowedTags: i.value,
        allowedAttributes: l.value,
        allowedClasses: {
          code: ["language-*"],
          pre: ["language-*"],
          span: ["language-*"]
        },
        transformTags: {
          a: Er.simpleTransform("a", { rel: "noopener noreferrer" })
        }
      });
    });
    return (o, r) => a.value ? (Pt(), Gt("article", {
      key: 0,
      class: "data-body markdown-container",
      innerHTML: a.value
    }, null, 8, sc)) : (Pt(), Gt("div", cc, " No markdown content provided. "));
  }
}), lc = ":root{--p-primary: rgb(0, 95, 178);--p-primary-50: color-mix(in srgb, var(--p-primary) 5%, white);--p-primary-100: color-mix(in srgb, var(--p-primary) 10%, white);--p-primary-200: color-mix(in srgb, var(--p-primary) 20%, white);--p-primary-300: color-mix(in srgb, var(--p-primary) 30%, white);--p-primary-400: color-mix(in srgb, var(--p-primary) 40%, white);--p-primary-500: var(--p-primary);--p-primary-600: color-mix(in srgb, var(--p-primary) 80%, black);--p-primary-700: color-mix(in srgb, var(--p-primary) 70%, black);--p-primary-800: color-mix(in srgb, var(--p-primary) 60%, black);--p-primary-900: color-mix(in srgb, var(--p-primary) 50%, black);--p-primary-950: color-mix(in srgb, var(--p-primary) 40%, black);--p-secondary: #6f7385;--p-secondary-50: color-mix(in srgb, var(--p-secondary) 5%, white);--p-secondary-100: color-mix(in srgb, var(--p-secondary) 10%, white);--p-secondary-200: color-mix(in srgb, var(--p-secondary) 20%, white);--p-secondary-300: color-mix(in srgb, var(--p-secondary) 35%, white);--p-secondary-400: color-mix(in srgb, var(--p-secondary) 65%, white);--p-secondary-500: var(--p-secondary);--p-secondary-600: color-mix(in srgb, var(--p-secondary) 80%, black);--p-secondary-700: color-mix(in srgb, var(--p-secondary) 65%, black);--p-secondary-800: color-mix(in srgb, var(--p-secondary) 55%, black);--p-secondary-900: color-mix(in srgb, var(--p-secondary) 50%, black);--p-secondary-950: color-mix(in srgb, var(--p-secondary) 30%, black);--p-danger: rgb(239, 68, 68);--p-danger-50: color-mix(in srgb, var(--p-danger) 5%, white);--p-danger-100: color-mix(in srgb, var(--p-danger) 10%, white);--p-danger-200: color-mix(in srgb, var(--p-danger) 20%, white);--p-danger-300: color-mix(in srgb, var(--p-danger) 30%, white);--p-danger-400: color-mix(in srgb, var(--p-danger) 40%, white);--p-danger-500: var(--p-danger);--p-danger-600: color-mix(in srgb, var(--p-danger) 80%, black);--p-danger-700: color-mix(in srgb, var(--p-danger) 70%, black);--p-danger-800: color-mix(in srgb, var(--p-danger) 60%, black);--p-danger-900: color-mix(in srgb, var(--p-danger) 50%, black);--p-danger-950: color-mix(in srgb, var(--p-danger) 40%, black);--p-success: rgb(34, 197, 94);--p-success-50: color-mix(in srgb, var(--p-success) 5%, white);--p-success-100: color-mix(in srgb, var(--p-success) 10%, white);--p-success-200: color-mix(in srgb, var(--p-success) 20%, white);--p-success-300: color-mix(in srgb, var(--p-success) 30%, white);--p-success-400: color-mix(in srgb, var(--p-success) 40%, white);--p-success-500: var(--p-success);--p-success-600: color-mix(in srgb, var(--p-success) 80%, black);--p-success-700: color-mix(in srgb, var(--p-success) 70%, black);--p-success-800: color-mix(in srgb, var(--p-success) 60%, black);--p-success-900: color-mix(in srgb, var(--p-success) 50%, black);--p-success-950: color-mix(in srgb, var(--p-success) 40%, black);--p-warn: rgb(249, 115, 22);--p-warn-50: color-mix(in srgb, var(--p-warn) 5%, white);--p-warn-100: color-mix(in srgb, var(--p-warn) 10%, white);--p-warn-200: color-mix(in srgb, var(--p-warn) 20%, white);--p-warn-300: color-mix(in srgb, var(--p-warn) 30%, white);--p-warn-400: color-mix(in srgb, var(--p-warn) 40%, white);--p-warn-500: var(--p-warn);--p-warn-600: color-mix(in srgb, var(--p-warn) 80%, black);--p-warn-700: color-mix(in srgb, var(--p-warn) 70%, black);--p-warn-800: color-mix(in srgb, var(--p-warn) 60%, black);--p-warn-900: color-mix(in srgb, var(--p-warn) 50%, black);--p-warn-950: color-mix(in srgb, var(--p-warn) 40%, black);--p-info: rgb(14, 165, 233);--p-info-50: color-mix(in srgb, var(--p-info) 5%, white);--p-info-100: color-mix(in srgb, var(--p-info) 10%, white);--p-info-200: color-mix(in srgb, var(--p-info) 20%, white);--p-info-300: color-mix(in srgb, var(--p-info) 30%, white);--p-info-400: color-mix(in srgb, var(--p-info) 40%, white);--p-info-500: var(--p-info);--p-info-600: color-mix(in srgb, var(--p-info) 80%, black);--p-info-700: color-mix(in srgb, var(--p-info) 70%, black);--p-info-800: color-mix(in srgb, var(--p-info) 60%, black);--p-info-900: color-mix(in srgb, var(--p-info) 50%, black);--p-info-950: color-mix(in srgb, var(--p-info) 40%, black);--p-help: rgb(168, 85, 247);--p-help-50: color-mix(in srgb, var(--p-help) 5%, white);--p-help-100: color-mix(in srgb, var(--p-help) 10%, white);--p-help-200: color-mix(in srgb, var(--p-help) 20%, white);--p-help-300: color-mix(in srgb, var(--p-help) 30%, white);--p-help-400: color-mix(in srgb, var(--p-help) 40%, white);--p-help-500: var(--p-help);--p-help-600: color-mix(in srgb, var(--p-help) 80%, black);--p-help-700: color-mix(in srgb, var(--p-help) 70%, black);--p-help-800: color-mix(in srgb, var(--p-help) 60%, black);--p-help-900: color-mix(in srgb, var(--p-help) 50%, black);--p-help-950: color-mix(in srgb, var(--p-help) 40%, black);--p-accent: rgb(20, 184, 166);--p-accent-50: color-mix(in srgb, var(--p-accent) 5%, white);--p-accent-100: color-mix(in srgb, var(--p-accent) 10%, white);--p-accent-200: color-mix(in srgb, var(--p-accent) 20%, white);--p-accent-300: color-mix(in srgb, var(--p-accent) 30%, white);--p-accent-400: color-mix(in srgb, var(--p-accent) 40%, white);--p-accent-500: var(--p-accent);--p-accent-600: color-mix(in srgb, var(--p-accent) 80%, black);--p-accent-700: color-mix(in srgb, var(--p-accent) 70%, black);--p-accent-800: color-mix(in srgb, var(--p-accent) 60%, black);--p-accent-900: color-mix(in srgb, var(--p-accent) 50%, black);--p-accent-950: color-mix(in srgb, var(--p-accent) 40%, black);--p-surface-0: #ffffff;--p-surface-50: #fafafa;--p-surface-100: #f5f5f5;--p-surface-200: #e5e5e5;--p-surface-300: #d4d4d4;--p-surface-400: #a3a3a3;--p-surface-500: #737373;--p-surface-600: #525252;--p-surface-700: #404040;--p-surface-800: #262626;--p-surface-850: color-mix(in srgb, var(--p-surface-800) 50%, var(--p-surface-900));--p-surface-900: #171717;--p-surface-950: #0a0a0a;--p-content-border-radius: 6px}:root{--p-primary-color: var(--p-primary-500);--p-primary-contrast-color: var(--p-surface-0);--p-primary-hover-color: var(--p-primary-600);--p-primary-active-color: var(--p-primary-700);--p-content-border-color: var(--p-surface-200);--p-content-hover-background: var(--p-surface-100);--p-content-hover-color: var(--p-surface-800);--p-highlight-background: var(--p-primary-50);--p-highlight-color: var(--p-primary-700);--p-highlight-focus-background: var(--p-primary-100);--p-highlight-focus-color: var(--p-primary-800);--p-content-background: var(--p-surface-0);--p-text-color: var(--p-surface-700);--p-text-hover-color: var(--p-surface-800);--p-text-muted-color: var(--p-surface-500);--p-text-hover-muted-color: var(--p-surface-600)}@media(prefers-color-scheme:dark){:root{--p-surface-D: #fff;--p-surface-0: #fff;--p-surface-50: #fafafa;--p-surface-100: #f4f4f5;--p-surface-200: #e4e4e7;--p-surface-300: #d4d4d8;--p-surface-400: #a1a1aa;--p-surface-500: #71717a;--p-surface-600: #545250;--p-surface-700: #403e3c;--p-surface-800: #2b2927;--p-surface-850: color-mix(in srgb, var(--p-surface-800) 50%, var(--p-surface-900));--p-surface-900: #1c1a19;--p-surface-950: #0f0e0d;--p-primary: rgb(0, 125, 178);--p-primary-50: color-mix(in srgb, var(--p-primary) 5%, white);--p-primary-100: color-mix(in srgb, var(--p-primary) 10%, white);--p-primary-200: color-mix(in srgb, var(--p-primary) 20%, white);--p-primary-300: color-mix(in srgb, var(--p-primary) 30%, white);--p-primary-400: color-mix(in srgb, var(--p-primary) 40%, white);--p-primary-500: var(--p-primary);--p-primary-600: color-mix(in srgb, var(--p-primary) 80%, black);--p-primary-700: color-mix(in srgb, var(--p-primary) 70%, black);--p-primary-800: color-mix(in srgb, var(--p-primary) 60%, black);--p-primary-900: color-mix(in srgb, var(--p-primary) 50%, black);--p-primary-950: color-mix(in srgb, var(--p-primary) 40%, black);--p-primary-color: var(--p-primary-400);--p-primary-contrast-color: var(--p-surface-900);--p-primary-hover-color: var(--p-primary-300);--p-primary-active-color: var(--p-primary-200);--p-content-border-color: var(--p-surface-700);--p-content-hover-background: var(--p-surface-800);--p-content-hover-color: var(--p-surface-0);--p-highlight-background: color-mix(in srgb, var(--p-primary-400), transparent 84%);--p-highlight-color: rgba(255, 255, 255, 87%);--p-highlight-focus-background: color-mix(in srgb, var(--p-primary-400), transparent 76%);--p-highlight-focus-color: rgba(255, 255, 255, 87%);--p-content-background: var(--p-surface-900);--p-text-color: var(--p-surface-0);--p-text-hover-color: var(--p-surface-0);--p-text-muted-color: var(--p-surface-400);--p-text-hover-muted-color: var(--p-surface-300)}}.markdown-container{font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif;color:var(--p-text-color, #333);line-height:1.6;width:100%;box-sizing:border-box;overflow-wrap:break-word;word-break:break-word}.markdown-empty{color:var(--p-text-muted-color, #999);font-style:italic;text-align:center}", fc = { props: { type: "object", properties: { content: { type: "string", default: "", description: "Markdown source text to render (GFM)" }, "allowed-tags": { type: "array", items: { type: "string" }, default: [], description: "Override sanitizer tag whitelist (empty = built-in defaults). WARNING: widening this is a security decision — only do it for trusted input." }, "allowed-attributes": { type: "string", default: "", description: "JSON-stringified `{tag: [attr,...]}` map for sanitize-html (empty = defaults)" } } } }, dc = {
  wippy: fc
};
class Ac extends Gi {
  static get wippyConfig() {
    return {
      propsSchema: dc.wippy.props,
      hostCssKeys: ["themeConfigUrl", "markdownCssUrl"],
      inlineCss: lc,
      contentTemplate: "text/markdown"
    };
  }
  static get vueConfig() {
    return {
      rootComponent: oc
    };
  }
}
wi(import.meta.url, Ac);
