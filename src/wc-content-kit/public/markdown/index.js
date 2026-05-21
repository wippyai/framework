import { inject as F0, ref as Su, createApp as wn, defineComponent as Cn, computed as nu, openBlock as Wt, createElementBlock as Ut } from "vue";
import { addCollection as vn } from "@iconify/vue";
import { hostCss as Dn, loadCss as En, addIcons as _n, define as In } from "@wippy-fe/proxy";
import { getActivePinia as kn, createPinia as Bn, setActivePinia as Fn } from "pinia";
const Sn = Symbol("wippy:emit"), S0 = Symbol("wippy:props"), Tn = Symbol("wippy:props_error"), T0 = Symbol("wippy:content"), Rn = Symbol("wippy:panel-id"), Nn = Symbol("wippy:layout-bus"), Mn = Symbol("wippy:host");
function On() {
  const e = F0(S0);
  if (!e)
    throw new Error("useProps() must be called inside a WippyVueElement");
  return e;
}
function Qn() {
  const e = F0(T0);
  if (!e)
    throw new Error("useContent() must be called inside a WippyVueElement with contentTemplate configured");
  return e;
}
const Ln = [
  "themeConfigUrl",
  "primeVueCssUrl",
  "markdownCssUrl",
  "iframeCssUrl"
];
function Pn(e, u) {
  const s = (u ?? Ln).map(async (a) => {
    const r = Dn[a];
    if (!r)
      return console.warn(`[wippy-fe/webcomponent-core] hostCss key "${a}" is undefined — skipping. Remove it from hostCssKeys if the CSS was removed.`), null;
    try {
      return await En(r);
    } catch (o) {
      return console.warn(`[wippy-fe/webcomponent-core] Failed to load hostCss "${a}" (${r}):`, o), null;
    }
  });
  return Promise.all(s).then((a) => {
    for (const r of a) {
      if (!r)
        continue;
      const o = document.createElement("style");
      o.textContent = r, o.setAttribute("role", "@wippy-fe/host-css"), e.appendChild(o);
    }
  });
}
function Gn(e, u) {
  const t = document.createElement("style");
  t.textContent = u, e.appendChild(t);
}
function R0(e) {
  return e.__wippyHost ?? null;
}
function Hn(e) {
  return e.replace(/-([a-z])/g, (u, t) => t.toUpperCase());
}
function qn(e, u, t) {
  switch (t.type) {
    case "string":
      return { value: u };
    case "number": {
      const s = Number.parseFloat(u);
      return Number.isNaN(s) ? { value: void 0, error: `Invalid ${e}: expected a number` } : { value: s };
    }
    case "integer": {
      const s = Number.parseInt(u, 10);
      return Number.isNaN(s) ? { value: void 0, error: `Invalid ${e}: expected an integer` } : { value: s };
    }
    case "boolean":
      return { value: u !== "false" };
    case "array":
    case "object":
      try {
        const s = JSON.parse(u);
        return t.type === "array" && !Array.isArray(s) ? { value: void 0, error: `Invalid ${e}: expected a JSON array` } : { value: s };
      } catch {
        return { value: void 0, error: `Invalid ${e}: must be valid JSON` };
      }
    default:
      return { value: u };
  }
}
function Tu(e, u) {
  const t = {}, s = [];
  for (const [a, r] of Object.entries(u.properties)) {
    const o = e.getAttribute(a), i = Hn(a);
    if (o === null) {
      r.default !== void 0 && (t[i] = r.default);
      continue;
    }
    const c = qn(a, o, r);
    c.error ? s.push(c.error) : t[i] = c.value;
  }
  return { props: t, errors: s };
}
class Wn {
  constructor(u, t) {
    this._propsListeners = /* @__PURE__ */ new Set(), this._contentListeners = /* @__PURE__ */ new Set(), this._disposed = !1, this._props = u.props, this._errors = u.errors, this._content = u.content, this._emitToDom = t;
    const s = this;
    this.props = {
      get value() {
        return s._props;
      },
      get errors() {
        return s._errors;
      },
      subscribe(a, r) {
        return s._subscribeProps(a, r);
      }
    }, this.events = {
      emit(a, r) {
        s._disposed || s._emitToDom(a, r);
      }
    }, this.content = u.hasContent ? {
      get value() {
        return s._content;
      },
      subscribe(a, r) {
        return s._subscribeContent(a, r);
      }
    } : null;
  }
  /** @internal */
  notifyProps(u, t) {
    if (!this._disposed) {
      this._props = u, this._errors = t;
      for (const s of this._propsListeners)
        s(u, t);
    }
  }
  /** @internal */
  notifyContent(u) {
    if (!this._disposed) {
      this._content = u;
      for (const t of this._contentListeners)
        t(u);
    }
  }
  /** @internal */
  dispose() {
    this._disposed || (this._disposed = !0, this._propsListeners.clear(), this._contentListeners.clear());
  }
  _subscribeProps(u, t) {
    if (this._disposed || t?.signal?.aborted)
      return () => {
      };
    this._propsListeners.add(u), t?.immediate && u(this._props, this._errors);
    const s = () => {
      this._propsListeners.delete(u), t?.signal?.removeEventListener("abort", s);
    };
    return t?.signal?.addEventListener("abort", s, { once: !0 }), s;
  }
  _subscribeContent(u, t) {
    if (this._disposed || t?.signal?.aborted)
      return () => {
      };
    this._contentListeners.add(u), t?.immediate && u(this._content);
    const s = () => {
      this._contentListeners.delete(u), t?.signal?.removeEventListener("abort", s);
    };
    return t?.signal?.addEventListener("abort", s, { once: !0 }), s;
  }
}
class Un extends HTMLElement {
  constructor() {
    super(), this._contentObserver = null, this._initialized = !1, this._container = null, this._reactive = null, this._lastProps = null, this._lastErrors = [], this._lastContent = null, this._internals = this.attachInternals();
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
    const u = this.wippyConfig, t = Object.keys(u.propsSchema.properties), s = u.extraObservedAttributes ?? [];
    return [...t, ...s];
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
    return R0(this);
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
  /**
   * Opt-in reactive adapter — framework-agnostic. Subscribe to prop
   * changes, content changes, or emit typed events from a non-Vue
   * consumer without re-rolling reactivity.
   *
   * ```ts
   * class MyEl extends WippyElement<{ count: number }, { tick: { n: number } }> {
   *   protected onMount() {
   *     const ctrl = new AbortController()
   *     this.reactive.props.subscribe(({ count }) => {
   *       this.shadowRoot!.querySelector('.n')!.textContent = String(count)
   *     }, { signal: ctrl.signal, immediate: true })
   *   }
   *   tick(n: number) { this.reactive.events.emit('tick', { n }) }
   * }
   * ```
   *
   * Allocation cost is zero unless this getter is touched. Disposed on
   * `disconnectedCallback`; a fresh adapter is allocated on the next
   * access after reconnect.
   */
  get reactive() {
    if (!this._reactive) {
      const u = this.constructor.wippyConfig, t = !!u.contentTemplate;
      let s, a;
      if (this._lastProps !== null)
        s = this._lastProps, a = this._lastErrors;
      else {
        const o = Tu(this, u.propsSchema);
        u.validateProps && o.errors.push(...u.validateProps(o.props)), s = o.props, a = o.errors, this._lastProps = s, this._lastErrors = a;
      }
      const r = t ? this._lastContent ?? this._extractContent(u.contentTemplate) : null;
      t && this._lastContent === null && (this._lastContent = r), this._reactive = new Wn(
        { props: s, errors: a, content: r, hasContent: t },
        this.emitEvent.bind(this)
      );
    }
    return this._reactive;
  }
  // ── Lifecycle ──────────────────────────────────────────────
  connectedCallback() {
    this._internals.states.add("loading");
    try {
      const u = this.constructor.wippyConfig, t = this._initialized, s = this.shadowRoot ?? this.attachShadow({ mode: u.shadowMode ?? "open" });
      let a;
      if (t)
        a = this._container;
      else {
        this.onInit(s), u.inlineCss && Gn(s, u.inlineCss), (u.hostCssKeys === void 0 || u.hostCssKeys.length > 0) && Pn(s, u.hostCssKeys), a = document.createElement("div");
        const n = u.containerClasses ?? [];
        n.length > 0 && a.classList.add(...n), s.appendChild(a), this._container = a, _n(vn);
      }
      const { props: r, errors: o } = Tu(this, u.propsSchema);
      u.validateProps && o.push(...u.validateProps(r));
      const i = r;
      this._lastProps = i, this._lastErrors = o;
      let c = null;
      u.contentTemplate && (c = this._extractContent(u.contentTemplate), this._lastContent = c, this._contentObserver = new MutationObserver(() => {
        const n = this._extractContent(u.contentTemplate);
        this._lastContent = n, this._reactive?.notifyContent(n), this.onContentChanged(n);
      }), this._contentObserver.observe(this, {
        childList: !0,
        characterData: !0,
        subtree: !0
      })), this.onMount(s, a, i, o, c, t), this._internals.states.delete("loading"), this._internals.states.add("ready"), t || (this._initialized = !0), this.onReady(), this.emitEvent("load");
    } catch (u) {
      this.onError(u), this._internals.states.delete("loading"), this._internals.states.add("error"), this.emitEvent("error", {
        message: u instanceof Error ? u.message : String(u),
        error: u
      });
    }
  }
  disconnectedCallback() {
    this._contentObserver && (this._contentObserver.disconnect(), this._contentObserver = null), this.onUnmount(), this.emitEvent("unload"), this._internals.states.clear(), this._reactive?.dispose(), this._reactive = null, this._lastProps = null, this._lastErrors = [], this._lastContent = null, delete this.__wippyHost, delete this.__wippyHostBus;
  }
  attributeChangedCallback(u, t, s) {
    if (t === s)
      return;
    const a = this.constructor.wippyConfig, { props: r, errors: o } = Tu(this, a.propsSchema);
    a.validateProps && o.push(...a.validateProps(r));
    const i = r;
    this._lastProps = i, this._lastErrors = o, this._reactive?.notifyProps(i, o), this.onPropsChanged(i, o);
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
function Kn(e) {
  return e.__wippyHostBus ?? null;
}
function Yn(e) {
  return e.dataset.wippyPanelId ?? null;
}
class jn extends Un {
  constructor() {
    super(...arguments), this._vueApp = null, this._propsRef = Su({}), this._errorsRef = Su([]), this._contentRef = Su(null), this._bridgeAbort = null;
  }
  /**
   * Override to provide Vue-specific configuration.
   */
  static get vueConfig() {
    throw new Error("WippyVueElement subclass must override static get vueConfig()");
  }
  onMount(u, t, s, a, r, o) {
    const i = this.constructor.vueConfig;
    this._propsRef.value = s, this._errorsRef.value = a, this._contentRef.value = r ?? null;
    for (const l of a)
      this.emitEvent("invalid", { message: l });
    this._bridgeAbort = new AbortController(), this.reactive.props.subscribe((l, f) => {
      this._propsRef.value = l, this._errorsRef.value = [...f];
      for (const A of f)
        this.emitEvent("invalid", { message: A });
    }, { signal: this._bridgeAbort.signal }), this.reactive.content && this.reactive.content.subscribe((l) => {
      this._contentRef.value = l;
    }, { signal: this._bridgeAbort.signal });
    const c = kn();
    this._vueApp = wn(i.rootComponent);
    const n = Bn();
    if (i.piniaPlugins)
      for (const l of i.piniaPlugins)
        n.use(l);
    if (this._vueApp.use(n), i.plugins)
      for (const l of i.plugins)
        this._vueApp.use(l);
    this._vueApp.provide(S0, this._propsRef), this._vueApp.provide(Tn, this._errorsRef), this._vueApp.provide(Sn, this.emitEvent.bind(this)), this._vueApp.provide(T0, this._contentRef), this._vueApp.provide(Rn, Yn(this)), this._vueApp.provide(Nn, Kn(this)), this._vueApp.provide(Mn, R0(this)), i.providers && i.providers(this._vueApp, this), this._vueApp.mount(t), c && Fn(c);
  }
  onUnmount() {
    this._bridgeAbort?.abort(), this._bridgeAbort = null, this._vueApp && (this._vueApp.unmount(), this._vueApp = null);
  }
}
const Kt = {};
function Jn(e) {
  let u = Kt[e];
  if (u)
    return u;
  u = Kt[e] = [];
  for (let t = 0; t < 128; t++) {
    const s = String.fromCharCode(t);
    u.push(s);
  }
  for (let t = 0; t < e.length; t++) {
    const s = e.charCodeAt(t);
    u[s] = "%" + ("0" + s.toString(16).toUpperCase()).slice(-2);
  }
  return u;
}
function We(e, u) {
  typeof u != "string" && (u = We.defaultChars);
  const t = Jn(u);
  return e.replace(/(%[a-f0-9]{2})+/gi, function(s) {
    let a = "";
    for (let r = 0, o = s.length; r < o; r += 3) {
      const i = parseInt(s.slice(r + 1, r + 3), 16);
      if (i < 128) {
        a += t[i];
        continue;
      }
      if ((i & 224) === 192 && r + 3 < o) {
        const c = parseInt(s.slice(r + 4, r + 6), 16);
        if ((c & 192) === 128) {
          const n = i << 6 & 1984 | c & 63;
          n < 128 ? a += "��" : a += String.fromCharCode(n), r += 3;
          continue;
        }
      }
      if ((i & 240) === 224 && r + 6 < o) {
        const c = parseInt(s.slice(r + 4, r + 6), 16), n = parseInt(s.slice(r + 7, r + 9), 16);
        if ((c & 192) === 128 && (n & 192) === 128) {
          const l = i << 12 & 61440 | c << 6 & 4032 | n & 63;
          l < 2048 || l >= 55296 && l <= 57343 ? a += "���" : a += String.fromCharCode(l), r += 6;
          continue;
        }
      }
      if ((i & 248) === 240 && r + 9 < o) {
        const c = parseInt(s.slice(r + 4, r + 6), 16), n = parseInt(s.slice(r + 7, r + 9), 16), l = parseInt(s.slice(r + 10, r + 12), 16);
        if ((c & 192) === 128 && (n & 192) === 128 && (l & 192) === 128) {
          let f = i << 18 & 1835008 | c << 12 & 258048 | n << 6 & 4032 | l & 63;
          f < 65536 || f > 1114111 ? a += "����" : (f -= 65536, a += String.fromCharCode(55296 + (f >> 10), 56320 + (f & 1023))), r += 9;
          continue;
        }
      }
      a += "�";
    }
    return a;
  });
}
We.defaultChars = ";/?:@&=+$,#";
We.componentChars = "";
const Yt = {};
function Zn(e) {
  let u = Yt[e];
  if (u)
    return u;
  u = Yt[e] = [];
  for (let t = 0; t < 128; t++) {
    const s = String.fromCharCode(t);
    /^[0-9a-z]$/i.test(s) ? u.push(s) : u.push("%" + ("0" + t.toString(16).toUpperCase()).slice(-2));
  }
  for (let t = 0; t < e.length; t++)
    u[e.charCodeAt(t)] = e[t];
  return u;
}
function $e(e, u, t) {
  typeof u != "string" && (t = u, u = $e.defaultChars), typeof t > "u" && (t = !0);
  const s = Zn(u);
  let a = "";
  for (let r = 0, o = e.length; r < o; r++) {
    const i = e.charCodeAt(r);
    if (t && i === 37 && r + 2 < o && /^[0-9a-f]{2}$/i.test(e.slice(r + 1, r + 3))) {
      a += e.slice(r, r + 3), r += 2;
      continue;
    }
    if (i < 128) {
      a += s[i];
      continue;
    }
    if (i >= 55296 && i <= 57343) {
      if (i >= 55296 && i <= 56319 && r + 1 < o) {
        const c = e.charCodeAt(r + 1);
        if (c >= 56320 && c <= 57343) {
          a += encodeURIComponent(e[r] + e[r + 1]), r++;
          continue;
        }
      }
      a += "%EF%BF%BD";
      continue;
    }
    a += encodeURIComponent(e[r]);
  }
  return a;
}
$e.defaultChars = ";/?:@&=+$,-_.!~*'()#";
$e.componentChars = "-_.!~*'()";
function It(e) {
  let u = "";
  return u += e.protocol || "", u += e.slashes ? "//" : "", u += e.auth ? e.auth + "@" : "", e.hostname && e.hostname.indexOf(":") !== -1 ? u += "[" + e.hostname + "]" : u += e.hostname || "", u += e.port ? ":" + e.port : "", u += e.pathname || "", u += e.search || "", u += e.hash || "", u;
}
function mu() {
  this.protocol = null, this.slashes = null, this.auth = null, this.port = null, this.hostname = null, this.hash = null, this.search = null, this.pathname = null;
}
const Vn = /^([a-z0-9.+-]+:)/i, zn = /:[0-9]*$/, Xn = /^(\/\/?(?!\/)[^\?\s]*)(\?[^\s]*)?$/, $n = ["<", ">", '"', "`", " ", "\r", `
`, "	"], ei = ["{", "}", "|", "\\", "^", "`"].concat($n), ui = ["'"].concat(ei), jt = ["%", "/", "?", ";", "#"].concat(ui), Jt = ["/", "?", "#"], ti = 255, Zt = /^[+a-z0-9A-Z_-]{0,63}$/, ri = /^([+a-z0-9A-Z_-]{0,63})(.*)$/, Vt = {
  javascript: !0,
  "javascript:": !0
}, zt = {
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
function kt(e, u) {
  if (e && e instanceof mu) return e;
  const t = new mu();
  return t.parse(e, u), t;
}
mu.prototype.parse = function(e, u) {
  let t, s, a, r = e;
  if (r = r.trim(), !u && e.split("#").length === 1) {
    const n = Xn.exec(r);
    if (n)
      return this.pathname = n[1], n[2] && (this.search = n[2]), this;
  }
  let o = Vn.exec(r);
  if (o && (o = o[0], t = o.toLowerCase(), this.protocol = o, r = r.substr(o.length)), (u || o || r.match(/^\/\/[^@\/]+@[^@\/]+/)) && (a = r.substr(0, 2) === "//", a && !(o && Vt[o]) && (r = r.substr(2), this.slashes = !0)), !Vt[o] && (a || o && !zt[o])) {
    let n = -1;
    for (let h = 0; h < Jt.length; h++)
      s = r.indexOf(Jt[h]), s !== -1 && (n === -1 || s < n) && (n = s);
    let l, f;
    n === -1 ? f = r.lastIndexOf("@") : f = r.lastIndexOf("@", n), f !== -1 && (l = r.slice(0, f), r = r.slice(f + 1), this.auth = l), n = -1;
    for (let h = 0; h < jt.length; h++)
      s = r.indexOf(jt[h]), s !== -1 && (n === -1 || s < n) && (n = s);
    n === -1 && (n = r.length), r[n - 1] === ":" && n--;
    const A = r.slice(0, n);
    r = r.slice(n), this.parseHost(A), this.hostname = this.hostname || "";
    const d = this.hostname[0] === "[" && this.hostname[this.hostname.length - 1] === "]";
    if (!d) {
      const h = this.hostname.split(/\./);
      for (let y = 0, C = h.length; y < C; y++) {
        const w = h[y];
        if (w && !w.match(Zt)) {
          let b = "";
          for (let x = 0, m = w.length; x < m; x++)
            w.charCodeAt(x) > 127 ? b += "x" : b += w[x];
          if (!b.match(Zt)) {
            const x = h.slice(0, y), m = h.slice(y + 1), p = w.match(ri);
            p && (x.push(p[1]), m.unshift(p[2])), m.length && (r = m.join(".") + r), this.hostname = x.join(".");
            break;
          }
        }
      }
    }
    this.hostname.length > ti && (this.hostname = ""), d && (this.hostname = this.hostname.substr(1, this.hostname.length - 2));
  }
  const i = r.indexOf("#");
  i !== -1 && (this.hash = r.substr(i), r = r.slice(0, i));
  const c = r.indexOf("?");
  return c !== -1 && (this.search = r.substr(c), r = r.slice(0, c)), r && (this.pathname = r), zt[t] && this.hostname && !this.pathname && (this.pathname = ""), this;
};
mu.prototype.parseHost = function(e) {
  let u = zn.exec(e);
  u && (u = u[0], u !== ":" && (this.port = u.substr(1)), e = e.substr(0, e.length - u.length)), e && (this.hostname = e);
};
const ni = /* @__PURE__ */ Object.freeze(/* @__PURE__ */ Object.defineProperty({
  __proto__: null,
  decode: We,
  encode: $e,
  format: It,
  parse: kt
}, Symbol.toStringTag, { value: "Module" })), N0 = /[\0-\uD7FF\uE000-\uFFFF]|[\uD800-\uDBFF][\uDC00-\uDFFF]|[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?:[^\uD800-\uDBFF]|^)[\uDC00-\uDFFF]/, M0 = /[\0-\x1F\x7F-\x9F]/, ii = /[\xAD\u0600-\u0605\u061C\u06DD\u070F\u0890\u0891\u08E2\u180E\u200B-\u200F\u202A-\u202E\u2060-\u2064\u2066-\u206F\uFEFF\uFFF9-\uFFFB]|\uD804[\uDCBD\uDCCD]|\uD80D[\uDC30-\uDC3F]|\uD82F[\uDCA0-\uDCA3]|\uD834[\uDD73-\uDD7A]|\uDB40[\uDC01\uDC20-\uDC7F]/, Bt = /[!-#%-\*,-\/:;\?@\[-\]_\{\}\xA1\xA7\xAB\xB6\xB7\xBB\xBF\u037E\u0387\u055A-\u055F\u0589\u058A\u05BE\u05C0\u05C3\u05C6\u05F3\u05F4\u0609\u060A\u060C\u060D\u061B\u061D-\u061F\u066A-\u066D\u06D4\u0700-\u070D\u07F7-\u07F9\u0830-\u083E\u085E\u0964\u0965\u0970\u09FD\u0A76\u0AF0\u0C77\u0C84\u0DF4\u0E4F\u0E5A\u0E5B\u0F04-\u0F12\u0F14\u0F3A-\u0F3D\u0F85\u0FD0-\u0FD4\u0FD9\u0FDA\u104A-\u104F\u10FB\u1360-\u1368\u1400\u166E\u169B\u169C\u16EB-\u16ED\u1735\u1736\u17D4-\u17D6\u17D8-\u17DA\u1800-\u180A\u1944\u1945\u1A1E\u1A1F\u1AA0-\u1AA6\u1AA8-\u1AAD\u1B5A-\u1B60\u1B7D\u1B7E\u1BFC-\u1BFF\u1C3B-\u1C3F\u1C7E\u1C7F\u1CC0-\u1CC7\u1CD3\u2010-\u2027\u2030-\u2043\u2045-\u2051\u2053-\u205E\u207D\u207E\u208D\u208E\u2308-\u230B\u2329\u232A\u2768-\u2775\u27C5\u27C6\u27E6-\u27EF\u2983-\u2998\u29D8-\u29DB\u29FC\u29FD\u2CF9-\u2CFC\u2CFE\u2CFF\u2D70\u2E00-\u2E2E\u2E30-\u2E4F\u2E52-\u2E5D\u3001-\u3003\u3008-\u3011\u3014-\u301F\u3030\u303D\u30A0\u30FB\uA4FE\uA4FF\uA60D-\uA60F\uA673\uA67E\uA6F2-\uA6F7\uA874-\uA877\uA8CE\uA8CF\uA8F8-\uA8FA\uA8FC\uA92E\uA92F\uA95F\uA9C1-\uA9CD\uA9DE\uA9DF\uAA5C-\uAA5F\uAADE\uAADF\uAAF0\uAAF1\uABEB\uFD3E\uFD3F\uFE10-\uFE19\uFE30-\uFE52\uFE54-\uFE61\uFE63\uFE68\uFE6A\uFE6B\uFF01-\uFF03\uFF05-\uFF0A\uFF0C-\uFF0F\uFF1A\uFF1B\uFF1F\uFF20\uFF3B-\uFF3D\uFF3F\uFF5B\uFF5D\uFF5F-\uFF65]|\uD800[\uDD00-\uDD02\uDF9F\uDFD0]|\uD801\uDD6F|\uD802[\uDC57\uDD1F\uDD3F\uDE50-\uDE58\uDE7F\uDEF0-\uDEF6\uDF39-\uDF3F\uDF99-\uDF9C]|\uD803[\uDEAD\uDF55-\uDF59\uDF86-\uDF89]|\uD804[\uDC47-\uDC4D\uDCBB\uDCBC\uDCBE-\uDCC1\uDD40-\uDD43\uDD74\uDD75\uDDC5-\uDDC8\uDDCD\uDDDB\uDDDD-\uDDDF\uDE38-\uDE3D\uDEA9]|\uD805[\uDC4B-\uDC4F\uDC5A\uDC5B\uDC5D\uDCC6\uDDC1-\uDDD7\uDE41-\uDE43\uDE60-\uDE6C\uDEB9\uDF3C-\uDF3E]|\uD806[\uDC3B\uDD44-\uDD46\uDDE2\uDE3F-\uDE46\uDE9A-\uDE9C\uDE9E-\uDEA2\uDF00-\uDF09]|\uD807[\uDC41-\uDC45\uDC70\uDC71\uDEF7\uDEF8\uDF43-\uDF4F\uDFFF]|\uD809[\uDC70-\uDC74]|\uD80B[\uDFF1\uDFF2]|\uD81A[\uDE6E\uDE6F\uDEF5\uDF37-\uDF3B\uDF44]|\uD81B[\uDE97-\uDE9A\uDFE2]|\uD82F\uDC9F|\uD836[\uDE87-\uDE8B]|\uD83A[\uDD5E\uDD5F]/, O0 = /[\$\+<->\^`\|~\xA2-\xA6\xA8\xA9\xAC\xAE-\xB1\xB4\xB8\xD7\xF7\u02C2-\u02C5\u02D2-\u02DF\u02E5-\u02EB\u02ED\u02EF-\u02FF\u0375\u0384\u0385\u03F6\u0482\u058D-\u058F\u0606-\u0608\u060B\u060E\u060F\u06DE\u06E9\u06FD\u06FE\u07F6\u07FE\u07FF\u0888\u09F2\u09F3\u09FA\u09FB\u0AF1\u0B70\u0BF3-\u0BFA\u0C7F\u0D4F\u0D79\u0E3F\u0F01-\u0F03\u0F13\u0F15-\u0F17\u0F1A-\u0F1F\u0F34\u0F36\u0F38\u0FBE-\u0FC5\u0FC7-\u0FCC\u0FCE\u0FCF\u0FD5-\u0FD8\u109E\u109F\u1390-\u1399\u166D\u17DB\u1940\u19DE-\u19FF\u1B61-\u1B6A\u1B74-\u1B7C\u1FBD\u1FBF-\u1FC1\u1FCD-\u1FCF\u1FDD-\u1FDF\u1FED-\u1FEF\u1FFD\u1FFE\u2044\u2052\u207A-\u207C\u208A-\u208C\u20A0-\u20C0\u2100\u2101\u2103-\u2106\u2108\u2109\u2114\u2116-\u2118\u211E-\u2123\u2125\u2127\u2129\u212E\u213A\u213B\u2140-\u2144\u214A-\u214D\u214F\u218A\u218B\u2190-\u2307\u230C-\u2328\u232B-\u2426\u2440-\u244A\u249C-\u24E9\u2500-\u2767\u2794-\u27C4\u27C7-\u27E5\u27F0-\u2982\u2999-\u29D7\u29DC-\u29FB\u29FE-\u2B73\u2B76-\u2B95\u2B97-\u2BFF\u2CE5-\u2CEA\u2E50\u2E51\u2E80-\u2E99\u2E9B-\u2EF3\u2F00-\u2FD5\u2FF0-\u2FFF\u3004\u3012\u3013\u3020\u3036\u3037\u303E\u303F\u309B\u309C\u3190\u3191\u3196-\u319F\u31C0-\u31E3\u31EF\u3200-\u321E\u322A-\u3247\u3250\u3260-\u327F\u328A-\u32B0\u32C0-\u33FF\u4DC0-\u4DFF\uA490-\uA4C6\uA700-\uA716\uA720\uA721\uA789\uA78A\uA828-\uA82B\uA836-\uA839\uAA77-\uAA79\uAB5B\uAB6A\uAB6B\uFB29\uFBB2-\uFBC2\uFD40-\uFD4F\uFDCF\uFDFC-\uFDFF\uFE62\uFE64-\uFE66\uFE69\uFF04\uFF0B\uFF1C-\uFF1E\uFF3E\uFF40\uFF5C\uFF5E\uFFE0-\uFFE6\uFFE8-\uFFEE\uFFFC\uFFFD]|\uD800[\uDD37-\uDD3F\uDD79-\uDD89\uDD8C-\uDD8E\uDD90-\uDD9C\uDDA0\uDDD0-\uDDFC]|\uD802[\uDC77\uDC78\uDEC8]|\uD805\uDF3F|\uD807[\uDFD5-\uDFF1]|\uD81A[\uDF3C-\uDF3F\uDF45]|\uD82F\uDC9C|\uD833[\uDF50-\uDFC3]|\uD834[\uDC00-\uDCF5\uDD00-\uDD26\uDD29-\uDD64\uDD6A-\uDD6C\uDD83\uDD84\uDD8C-\uDDA9\uDDAE-\uDDEA\uDE00-\uDE41\uDE45\uDF00-\uDF56]|\uD835[\uDEC1\uDEDB\uDEFB\uDF15\uDF35\uDF4F\uDF6F\uDF89\uDFA9\uDFC3]|\uD836[\uDC00-\uDDFF\uDE37-\uDE3A\uDE6D-\uDE74\uDE76-\uDE83\uDE85\uDE86]|\uD838[\uDD4F\uDEFF]|\uD83B[\uDCAC\uDCB0\uDD2E\uDEF0\uDEF1]|\uD83C[\uDC00-\uDC2B\uDC30-\uDC93\uDCA0-\uDCAE\uDCB1-\uDCBF\uDCC1-\uDCCF\uDCD1-\uDCF5\uDD0D-\uDDAD\uDDE6-\uDE02\uDE10-\uDE3B\uDE40-\uDE48\uDE50\uDE51\uDE60-\uDE65\uDF00-\uDFFF]|\uD83D[\uDC00-\uDED7\uDEDC-\uDEEC\uDEF0-\uDEFC\uDF00-\uDF76\uDF7B-\uDFD9\uDFE0-\uDFEB\uDFF0]|\uD83E[\uDC00-\uDC0B\uDC10-\uDC47\uDC50-\uDC59\uDC60-\uDC87\uDC90-\uDCAD\uDCB0\uDCB1\uDD00-\uDE53\uDE60-\uDE6D\uDE70-\uDE7C\uDE80-\uDE88\uDE90-\uDEBD\uDEBF-\uDEC5\uDECE-\uDEDB\uDEE0-\uDEE8\uDEF0-\uDEF8\uDF00-\uDF92\uDF94-\uDFCA]/, Q0 = /[ \xA0\u1680\u2000-\u200A\u2028\u2029\u202F\u205F\u3000]/, ai = /* @__PURE__ */ Object.freeze(/* @__PURE__ */ Object.defineProperty({
  __proto__: null,
  Any: N0,
  Cc: M0,
  Cf: ii,
  P: Bt,
  S: O0,
  Z: Q0
}, Symbol.toStringTag, { value: "Module" })), si = new Uint16Array(
  // prettier-ignore
  'ᵁ<Õıʊҝջאٵ۞ޢߖࠏ੊ઑඡ๭༉༦჊ረዡᐕᒝᓃᓟᔥ\0\0\0\0\0\0ᕫᛍᦍᰒᷝ὾⁠↰⊍⏀⏻⑂⠤⤒ⴈ⹈⿎〖㊺㘹㞬㣾㨨㩱㫠㬮ࠀEMabcfglmnoprstu\\bfms¦³¹ÈÏlig耻Æ䃆P耻&䀦cute耻Á䃁reve;䄂Āiyx}rc耻Â䃂;䐐r;쀀𝔄rave耻À䃀pha;䎑acr;䄀d;橓Āgp¡on;䄄f;쀀𝔸plyFunction;恡ing耻Å䃅Ācs¾Ãr;쀀𝒜ign;扔ilde耻Ã䃃ml耻Ä䃄ЀaceforsuåûþėĜĢħĪĀcrêòkslash;或Ŷöø;櫧ed;挆y;䐑ƀcrtąċĔause;戵noullis;愬a;䎒r;쀀𝔅pf;쀀𝔹eve;䋘còēmpeq;扎܀HOacdefhilorsuōőŖƀƞƢƵƷƺǜȕɳɸɾcy;䐧PY耻©䂩ƀcpyŝŢźute;䄆Ā;iŧŨ拒talDifferentialD;慅leys;愭ȀaeioƉƎƔƘron;䄌dil耻Ç䃇rc;䄈nint;戰ot;䄊ĀdnƧƭilla;䂸terDot;䂷òſi;䎧rcleȀDMPTǇǋǑǖot;抙inus;抖lus;投imes;抗oĀcsǢǸkwiseContourIntegral;戲eCurlyĀDQȃȏoubleQuote;思uote;怙ȀlnpuȞȨɇɕonĀ;eȥȦ户;橴ƀgitȯȶȺruent;扡nt;戯ourIntegral;戮ĀfrɌɎ;愂oduct;成nterClockwiseContourIntegral;戳oss;樯cr;쀀𝒞pĀ;Cʄʅ拓ap;才րDJSZacefiosʠʬʰʴʸˋ˗ˡ˦̳ҍĀ;oŹʥtrahd;椑cy;䐂cy;䐅cy;䐏ƀgrsʿ˄ˇger;怡r;憡hv;櫤Āayː˕ron;䄎;䐔lĀ;t˝˞戇a;䎔r;쀀𝔇Āaf˫̧Ācm˰̢riticalȀADGT̖̜̀̆cute;䂴oŴ̋̍;䋙bleAcute;䋝rave;䁠ilde;䋜ond;拄ferentialD;慆Ѱ̽\0\0\0͔͂\0Ѕf;쀀𝔻ƀ;DE͈͉͍䂨ot;惜qual;扐blèCDLRUVͣͲ΂ϏϢϸontourIntegraìȹoɴ͹\0\0ͻ»͉nArrow;懓Āeo·ΤftƀARTΐΖΡrrow;懐ightArrow;懔eåˊngĀLRΫτeftĀARγιrrow;柸ightArrow;柺ightArrow;柹ightĀATϘϞrrow;懒ee;抨pɁϩ\0\0ϯrrow;懑ownArrow;懕erticalBar;戥ǹABLRTaВЪаўѿͼrrowƀ;BUНОТ憓ar;椓pArrow;懵reve;䌑eft˒к\0ц\0ѐightVector;楐eeVector;楞ectorĀ;Bљњ憽ar;楖ightǔѧ\0ѱeeVector;楟ectorĀ;BѺѻ懁ar;楗eeĀ;A҆҇护rrow;憧ĀctҒҗr;쀀𝒟rok;䄐ࠀNTacdfglmopqstuxҽӀӄӋӞӢӧӮӵԡԯԶՒ՝ՠեG;䅊H耻Ð䃐cute耻É䃉ƀaiyӒӗӜron;䄚rc耻Ê䃊;䐭ot;䄖r;쀀𝔈rave耻È䃈ement;戈ĀapӺӾcr;䄒tyɓԆ\0\0ԒmallSquare;旻erySmallSquare;斫ĀgpԦԪon;䄘f;쀀𝔼silon;䎕uĀaiԼՉlĀ;TՂՃ橵ilde;扂librium;懌Āci՗՚r;愰m;橳a;䎗ml耻Ë䃋Āipժկsts;戃onentialE;慇ʀcfiosօֈ֍ֲ׌y;䐤r;쀀𝔉lledɓ֗\0\0֣mallSquare;旼erySmallSquare;斪Ͱֺ\0ֿ\0\0ׄf;쀀𝔽All;戀riertrf;愱cò׋؀JTabcdfgorstר׬ׯ׺؀ؒؖ؛؝أ٬ٲcy;䐃耻>䀾mmaĀ;d׷׸䎓;䏜reve;䄞ƀeiy؇،ؐdil;䄢rc;䄜;䐓ot;䄠r;쀀𝔊;拙pf;쀀𝔾eater̀EFGLSTصلَٖٛ٦qualĀ;Lؾؿ扥ess;招ullEqual;执reater;檢ess;扷lantEqual;橾ilde;扳cr;쀀𝒢;扫ЀAacfiosuڅڋږڛڞڪھۊRDcy;䐪Āctڐڔek;䋇;䁞irc;䄤r;愌lbertSpace;愋ǰگ\0ڲf;愍izontalLine;攀Āctۃۅòکrok;䄦mpńېۘownHumðįqual;扏܀EJOacdfgmnostuۺ۾܃܇܎ܚܞܡܨ݄ݸދޏޕcy;䐕lig;䄲cy;䐁cute耻Í䃍Āiyܓܘrc耻Î䃎;䐘ot;䄰r;愑rave耻Ì䃌ƀ;apܠܯܿĀcgܴܷr;䄪inaryI;慈lieóϝǴ݉\0ݢĀ;eݍݎ戬Āgrݓݘral;戫section;拂isibleĀCTݬݲomma;恣imes;恢ƀgptݿރވon;䄮f;쀀𝕀a;䎙cr;愐ilde;䄨ǫޚ\0ޞcy;䐆l耻Ï䃏ʀcfosuެ޷޼߂ߐĀiyޱ޵rc;䄴;䐙r;쀀𝔍pf;쀀𝕁ǣ߇\0ߌr;쀀𝒥rcy;䐈kcy;䐄΀HJacfosߤߨ߽߬߱ࠂࠈcy;䐥cy;䐌ppa;䎚Āey߶߻dil;䄶;䐚r;쀀𝔎pf;쀀𝕂cr;쀀𝒦րJTaceflmostࠥࠩࠬࡐࡣ঳সে্਷ੇcy;䐉耻<䀼ʀcmnpr࠷࠼ࡁࡄࡍute;䄹bda;䎛g;柪lacetrf;愒r;憞ƀaeyࡗ࡜ࡡron;䄽dil;䄻;䐛Āfsࡨ॰tԀACDFRTUVarࡾࢩࢱࣦ࣠ࣼयज़ΐ४Ānrࢃ࢏gleBracket;柨rowƀ;BR࢙࢚࢞憐ar;懤ightArrow;懆eiling;挈oǵࢷ\0ࣃbleBracket;柦nǔࣈ\0࣒eeVector;楡ectorĀ;Bࣛࣜ懃ar;楙loor;挊ightĀAV࣯ࣵrrow;憔ector;楎Āerँगeƀ;AVउऊऐ抣rrow;憤ector;楚iangleƀ;BEतथऩ抲ar;槏qual;抴pƀDTVषूौownVector;楑eeVector;楠ectorĀ;Bॖॗ憿ar;楘ectorĀ;B॥०憼ar;楒ightáΜs̀EFGLSTॾঋকঝঢভqualGreater;拚ullEqual;扦reater;扶ess;檡lantEqual;橽ilde;扲r;쀀𝔏Ā;eঽা拘ftarrow;懚idot;䄿ƀnpw৔ਖਛgȀLRlr৞৷ਂਐeftĀAR০৬rrow;柵ightArrow;柷ightArrow;柶eftĀarγਊightáοightáϊf;쀀𝕃erĀLRਢਬeftArrow;憙ightArrow;憘ƀchtਾੀੂòࡌ;憰rok;䅁;扪Ѐacefiosuਗ਼੝੠੷੼અઋ઎p;椅y;䐜Ādl੥੯iumSpace;恟lintrf;愳r;쀀𝔐nusPlus;戓pf;쀀𝕄cò੶;䎜ҀJacefostuણધભીଔଙඑ඗ඞcy;䐊cute;䅃ƀaey઴હાron;䅇dil;䅅;䐝ƀgswે૰଎ativeƀMTV૓૟૨ediumSpace;怋hiĀcn૦૘ë૙eryThiî૙tedĀGL૸ଆreaterGreateòٳessLesóੈLine;䀊r;쀀𝔑ȀBnptଢନଷ଺reak;恠BreakingSpace;䂠f;愕ڀ;CDEGHLNPRSTV୕ୖ୪୼஡௫ఄ౞಄ದ೘ൡඅ櫬Āou୛୤ngruent;扢pCap;扭oubleVerticalBar;戦ƀlqxஃஊ஛ement;戉ualĀ;Tஒஓ扠ilde;쀀≂̸ists;戄reater΀;EFGLSTஶஷ஽௉௓௘௥扯qual;扱ullEqual;쀀≧̸reater;쀀≫̸ess;批lantEqual;쀀⩾̸ilde;扵umpń௲௽ownHump;쀀≎̸qual;쀀≏̸eĀfsఊధtTriangleƀ;BEచఛడ拪ar;쀀⧏̸qual;括s̀;EGLSTవశ఼ౄోౘ扮qual;扰reater;扸ess;쀀≪̸lantEqual;쀀⩽̸ilde;扴estedĀGL౨౹reaterGreater;쀀⪢̸essLess;쀀⪡̸recedesƀ;ESಒಓಛ技qual;쀀⪯̸lantEqual;拠ĀeiಫಹverseElement;戌ghtTriangleƀ;BEೋೌ೒拫ar;쀀⧐̸qual;拭ĀquೝഌuareSuĀbp೨೹setĀ;E೰ೳ쀀⊏̸qual;拢ersetĀ;Eഃആ쀀⊐̸qual;拣ƀbcpഓതൎsetĀ;Eഛഞ쀀⊂⃒qual;抈ceedsȀ;ESTലള഻െ抁qual;쀀⪰̸lantEqual;拡ilde;쀀≿̸ersetĀ;E൘൛쀀⊃⃒qual;抉ildeȀ;EFT൮൯൵ൿ扁qual;扄ullEqual;扇ilde;扉erticalBar;戤cr;쀀𝒩ilde耻Ñ䃑;䎝܀Eacdfgmoprstuvලෂ෉෕ෛ෠෧෼ขภยา฿ไlig;䅒cute耻Ó䃓Āiy෎ීrc耻Ô䃔;䐞blac;䅐r;쀀𝔒rave耻Ò䃒ƀaei෮ෲ෶cr;䅌ga;䎩cron;䎟pf;쀀𝕆enCurlyĀDQฎบoubleQuote;怜uote;怘;橔Āclวฬr;쀀𝒪ash耻Ø䃘iŬื฼de耻Õ䃕es;樷ml耻Ö䃖erĀBP๋๠Āar๐๓r;怾acĀek๚๜;揞et;掴arenthesis;揜Ҁacfhilors๿ງຊຏຒດຝະ໼rtialD;戂y;䐟r;쀀𝔓i;䎦;䎠usMinus;䂱Āipຢອncareplanåڝf;愙Ȁ;eio຺ູ໠໤檻cedesȀ;EST່້໏໚扺qual;檯lantEqual;扼ilde;找me;怳Ādp໩໮uct;戏ortionĀ;aȥ໹l;戝Āci༁༆r;쀀𝒫;䎨ȀUfos༑༖༛༟OT耻"䀢r;쀀𝔔pf;愚cr;쀀𝒬؀BEacefhiorsu༾གྷཇའཱིྦྷྪྭ႖ႩႴႾarr;椐G耻®䂮ƀcnrཎནབute;䅔g;柫rĀ;tཛྷཝ憠l;椖ƀaeyཧཬཱron;䅘dil;䅖;䐠Ā;vླྀཹ愜erseĀEUྂྙĀlq྇ྎement;戋uilibrium;懋pEquilibrium;楯r»ཹo;䎡ghtЀACDFTUVa࿁࿫࿳ဢဨၛႇϘĀnr࿆࿒gleBracket;柩rowƀ;BL࿜࿝࿡憒ar;懥eftArrow;懄eiling;按oǵ࿹\0စbleBracket;柧nǔည\0နeeVector;楝ectorĀ;Bဝသ懂ar;楕loor;挋Āerိ၃eƀ;AVဵံြ抢rrow;憦ector;楛iangleƀ;BEၐၑၕ抳ar;槐qual;抵pƀDTVၣၮၸownVector;楏eeVector;楜ectorĀ;Bႂႃ憾ar;楔ectorĀ;B႑႒懀ar;楓Āpuႛ႞f;愝ndImplies;楰ightarrow;懛ĀchႹႼr;愛;憱leDelayed;槴ڀHOacfhimoqstuფჱჷჽᄙᄞᅑᅖᅡᅧᆵᆻᆿĀCcჩხHcy;䐩y;䐨FTcy;䐬cute;䅚ʀ;aeiyᄈᄉᄎᄓᄗ檼ron;䅠dil;䅞rc;䅜;䐡r;쀀𝔖ortȀDLRUᄪᄴᄾᅉownArrow»ОeftArrow»࢚ightArrow»࿝pArrow;憑gma;䎣allCircle;战pf;쀀𝕊ɲᅭ\0\0ᅰt;戚areȀ;ISUᅻᅼᆉᆯ斡ntersection;抓uĀbpᆏᆞsetĀ;Eᆗᆘ抏qual;抑ersetĀ;Eᆨᆩ抐qual;抒nion;抔cr;쀀𝒮ar;拆ȀbcmpᇈᇛሉላĀ;sᇍᇎ拐etĀ;Eᇍᇕqual;抆ĀchᇠህeedsȀ;ESTᇭᇮᇴᇿ扻qual;檰lantEqual;扽ilde;承Tháྌ;我ƀ;esሒሓሣ拑rsetĀ;Eሜም抃qual;抇et»ሓրHRSacfhiorsሾቄ቉ቕ቞ቱቶኟዂወዑORN耻Þ䃞ADE;愢ĀHc቎ቒcy;䐋y;䐦Ābuቚቜ;䀉;䎤ƀaeyብቪቯron;䅤dil;䅢;䐢r;쀀𝔗Āeiቻ኉ǲኀ\0ኇefore;戴a;䎘Ācn኎ኘkSpace;쀀  Space;怉ldeȀ;EFTካኬኲኼ戼qual;扃ullEqual;扅ilde;扈pf;쀀𝕋ipleDot;惛Āctዖዛr;쀀𝒯rok;䅦ૡዷጎጚጦ\0ጬጱ\0\0\0\0\0ጸጽ፷ᎅ\0᏿ᐄᐊᐐĀcrዻጁute耻Ú䃚rĀ;oጇገ憟cir;楉rǣጓ\0጖y;䐎ve;䅬Āiyጞጣrc耻Û䃛;䐣blac;䅰r;쀀𝔘rave耻Ù䃙acr;䅪Ādiፁ፩erĀBPፈ፝Āarፍፐr;䁟acĀekፗፙ;揟et;掵arenthesis;揝onĀ;P፰፱拃lus;抎Āgp፻፿on;䅲f;쀀𝕌ЀADETadps᎕ᎮᎸᏄϨᏒᏗᏳrrowƀ;BDᅐᎠᎤar;椒ownArrow;懅ownArrow;憕quilibrium;楮eeĀ;AᏋᏌ报rrow;憥ownáϳerĀLRᏞᏨeftArrow;憖ightArrow;憗iĀ;lᏹᏺ䏒on;䎥ing;䅮cr;쀀𝒰ilde;䅨ml耻Ü䃜ҀDbcdefosvᐧᐬᐰᐳᐾᒅᒊᒐᒖash;披ar;櫫y;䐒ashĀ;lᐻᐼ抩;櫦Āerᑃᑅ;拁ƀbtyᑌᑐᑺar;怖Ā;iᑏᑕcalȀBLSTᑡᑥᑪᑴar;戣ine;䁼eparator;杘ilde;所ThinSpace;怊r;쀀𝔙pf;쀀𝕍cr;쀀𝒱dash;抪ʀcefosᒧᒬᒱᒶᒼirc;䅴dge;拀r;쀀𝔚pf;쀀𝕎cr;쀀𝒲Ȁfiosᓋᓐᓒᓘr;쀀𝔛;䎞pf;쀀𝕏cr;쀀𝒳ҀAIUacfosuᓱᓵᓹᓽᔄᔏᔔᔚᔠcy;䐯cy;䐇cy;䐮cute耻Ý䃝Āiyᔉᔍrc;䅶;䐫r;쀀𝔜pf;쀀𝕐cr;쀀𝒴ml;䅸ЀHacdefosᔵᔹᔿᕋᕏᕝᕠᕤcy;䐖cute;䅹Āayᕄᕉron;䅽;䐗ot;䅻ǲᕔ\0ᕛoWidtè૙a;䎖r;愨pf;愤cr;쀀𝒵௡ᖃᖊᖐ\0ᖰᖶᖿ\0\0\0\0ᗆᗛᗫᙟ᙭\0ᚕ᚛ᚲᚹ\0ᚾcute耻á䃡reve;䄃̀;Ediuyᖜᖝᖡᖣᖨᖭ戾;쀀∾̳;房rc耻â䃢te肻´̆;䐰lig耻æ䃦Ā;r²ᖺ;쀀𝔞rave耻à䃠ĀepᗊᗖĀfpᗏᗔsym;愵èᗓha;䎱ĀapᗟcĀclᗤᗧr;䄁g;樿ɤᗰ\0\0ᘊʀ;adsvᗺᗻᗿᘁᘇ戧nd;橕;橜lope;橘;橚΀;elmrszᘘᘙᘛᘞᘿᙏᙙ戠;榤e»ᘙsdĀ;aᘥᘦ戡ѡᘰᘲᘴᘶᘸᘺᘼᘾ;榨;榩;榪;榫;榬;榭;榮;榯tĀ;vᙅᙆ戟bĀ;dᙌᙍ抾;榝Āptᙔᙗh;戢»¹arr;捼Āgpᙣᙧon;䄅f;쀀𝕒΀;Eaeiop዁ᙻᙽᚂᚄᚇᚊ;橰cir;橯;扊d;手s;䀧roxĀ;e዁ᚒñᚃing耻å䃥ƀctyᚡᚦᚨr;쀀𝒶;䀪mpĀ;e዁ᚯñʈilde耻ã䃣ml耻ä䃤Āciᛂᛈoninôɲnt;樑ࠀNabcdefiklnoprsu᛭ᛱᜰ᜼ᝃᝈ᝸᝽០៦ᠹᡐᜍ᤽᥈ᥰot;櫭Ācrᛶ᜞kȀcepsᜀᜅᜍᜓong;扌psilon;䏶rime;怵imĀ;e᜚᜛戽q;拍Ŷᜢᜦee;抽edĀ;gᜬᜭ挅e»ᜭrkĀ;t፜᜷brk;掶Āoyᜁᝁ;䐱quo;怞ʀcmprtᝓ᝛ᝡᝤᝨausĀ;eĊĉptyv;榰séᜌnoõēƀahwᝯ᝱ᝳ;䎲;愶een;扬r;쀀𝔟g΀costuvwឍឝឳេ៕៛៞ƀaiuបពរðݠrc;旯p»፱ƀdptឤឨឭot;樀lus;樁imes;樂ɱឹ\0\0ើcup;樆ar;昅riangleĀdu៍្own;施p;斳plus;樄eåᑄåᒭarow;植ƀako៭ᠦᠵĀcn៲ᠣkƀlst៺֫᠂ozenge;槫riangleȀ;dlr᠒᠓᠘᠝斴own;斾eft;旂ight;斸k;搣Ʊᠫ\0ᠳƲᠯ\0ᠱ;斒;斑4;斓ck;斈ĀeoᠾᡍĀ;qᡃᡆ쀀=⃥uiv;쀀≡⃥t;挐Ȁptwxᡙᡞᡧᡬf;쀀𝕓Ā;tᏋᡣom»Ꮜtie;拈؀DHUVbdhmptuvᢅᢖᢪᢻᣗᣛᣬ᣿ᤅᤊᤐᤡȀLRlrᢎᢐᢒᢔ;敗;敔;敖;敓ʀ;DUduᢡᢢᢤᢦᢨ敐;敦;敩;敤;敧ȀLRlrᢳᢵᢷᢹ;敝;敚;敜;教΀;HLRhlrᣊᣋᣍᣏᣑᣓᣕ救;敬;散;敠;敫;敢;敟ox;槉ȀLRlrᣤᣦᣨᣪ;敕;敒;攐;攌ʀ;DUduڽ᣷᣹᣻᣽;敥;敨;攬;攴inus;抟lus;択imes;抠ȀLRlrᤙᤛᤝ᤟;敛;敘;攘;攔΀;HLRhlrᤰᤱᤳᤵᤷ᤻᤹攂;敪;敡;敞;攼;攤;攜Āevģ᥂bar耻¦䂦Ȁceioᥑᥖᥚᥠr;쀀𝒷mi;恏mĀ;e᜚᜜lƀ;bhᥨᥩᥫ䁜;槅sub;柈Ŭᥴ᥾lĀ;e᥹᥺怢t»᥺pƀ;Eeįᦅᦇ;檮Ā;qۜۛೡᦧ\0᧨ᨑᨕᨲ\0ᨷᩐ\0\0᪴\0\0᫁\0\0ᬡᬮ᭍᭒\0᯽\0ᰌƀcpr᦭ᦲ᧝ute;䄇̀;abcdsᦿᧀᧄ᧊᧕᧙戩nd;橄rcup;橉Āau᧏᧒p;橋p;橇ot;橀;쀀∩︀Āeo᧢᧥t;恁îړȀaeiu᧰᧻ᨁᨅǰ᧵\0᧸s;橍on;䄍dil耻ç䃧rc;䄉psĀ;sᨌᨍ橌m;橐ot;䄋ƀdmnᨛᨠᨦil肻¸ƭptyv;榲t脀¢;eᨭᨮ䂢räƲr;쀀𝔠ƀceiᨽᩀᩍy;䑇ckĀ;mᩇᩈ朓ark»ᩈ;䏇r΀;Ecefms᩟᩠ᩢᩫ᪤᪪᪮旋;槃ƀ;elᩩᩪᩭ䋆q;扗eɡᩴ\0\0᪈rrowĀlr᩼᪁eft;憺ight;憻ʀRSacd᪒᪔᪖᪚᪟»ཇ;擈st;抛irc;抚ash;抝nint;樐id;櫯cir;槂ubsĀ;u᪻᪼晣it»᪼ˬ᫇᫔᫺\0ᬊonĀ;eᫍᫎ䀺Ā;qÇÆɭ᫙\0\0᫢aĀ;t᫞᫟䀬;䁀ƀ;fl᫨᫩᫫戁îᅠeĀmx᫱᫶ent»᫩eóɍǧ᫾\0ᬇĀ;dኻᬂot;橭nôɆƀfryᬐᬔᬗ;쀀𝕔oäɔ脀©;sŕᬝr;愗Āaoᬥᬩrr;憵ss;朗Ācuᬲᬷr;쀀𝒸Ābpᬼ᭄Ā;eᭁᭂ櫏;櫑Ā;eᭉᭊ櫐;櫒dot;拯΀delprvw᭠᭬᭷ᮂᮬᯔ᯹arrĀlr᭨᭪;椸;椵ɰ᭲\0\0᭵r;拞c;拟arrĀ;p᭿ᮀ憶;椽̀;bcdosᮏᮐᮖᮡᮥᮨ截rcap;橈Āauᮛᮞp;橆p;橊ot;抍r;橅;쀀∪︀Ȁalrv᮵ᮿᯞᯣrrĀ;mᮼᮽ憷;椼yƀevwᯇᯔᯘqɰᯎ\0\0ᯒreã᭳uã᭵ee;拎edge;拏en耻¤䂤earrowĀlrᯮ᯳eft»ᮀight»ᮽeäᯝĀciᰁᰇoninôǷnt;戱lcty;挭ঀAHabcdefhijlorstuwz᰸᰻᰿ᱝᱩᱵᲊᲞᲬᲷ᳻᳿ᴍᵻᶑᶫᶻ᷆᷍rò΁ar;楥Ȁglrs᱈ᱍ᱒᱔ger;怠eth;愸òᄳhĀ;vᱚᱛ怐»ऊūᱡᱧarow;椏aã̕Āayᱮᱳron;䄏;䐴ƀ;ao̲ᱼᲄĀgrʿᲁr;懊tseq;橷ƀglmᲑᲔᲘ耻°䂰ta;䎴ptyv;榱ĀirᲣᲨsht;楿;쀀𝔡arĀlrᲳᲵ»ࣜ»သʀaegsv᳂͸᳖᳜᳠mƀ;oș᳊᳔ndĀ;ș᳑uit;晦amma;䏝in;拲ƀ;io᳧᳨᳸䃷de脀÷;o᳧ᳰntimes;拇nø᳷cy;䑒cɯᴆ\0\0ᴊrn;挞op;挍ʀlptuwᴘᴝᴢᵉᵕlar;䀤f;쀀𝕕ʀ;emps̋ᴭᴷᴽᵂqĀ;d͒ᴳot;扑inus;戸lus;戔quare;抡blebarwedgåúnƀadhᄮᵝᵧownarrowóᲃarpoonĀlrᵲᵶefôᲴighôᲶŢᵿᶅkaro÷གɯᶊ\0\0ᶎrn;挟op;挌ƀcotᶘᶣᶦĀryᶝᶡ;쀀𝒹;䑕l;槶rok;䄑Ādrᶰᶴot;拱iĀ;fᶺ᠖斿Āah᷀᷃ròЩaòྦangle;榦Āci᷒ᷕy;䑟grarr;柿ऀDacdefglmnopqrstuxḁḉḙḸոḼṉṡṾấắẽỡἪἷὄ὎὚ĀDoḆᴴoôᲉĀcsḎḔute耻é䃩ter;橮ȀaioyḢḧḱḶron;䄛rĀ;cḭḮ扖耻ê䃪lon;払;䑍ot;䄗ĀDrṁṅot;扒;쀀𝔢ƀ;rsṐṑṗ檚ave耻è䃨Ā;dṜṝ檖ot;檘Ȁ;ilsṪṫṲṴ檙nters;揧;愓Ā;dṹṺ檕ot;檗ƀapsẅẉẗcr;䄓tyƀ;svẒẓẕ戅et»ẓpĀ1;ẝẤĳạả;怄;怅怃ĀgsẪẬ;䅋p;怂ĀgpẴẸon;䄙f;쀀𝕖ƀalsỄỎỒrĀ;sỊị拕l;槣us;橱iƀ;lvỚớở䎵on»ớ;䏵ȀcsuvỪỳἋἣĀioữḱrc»Ḯɩỹ\0\0ỻíՈantĀglἂἆtr»ṝess»Ṻƀaeiἒ἖Ἒls;䀽st;扟vĀ;DȵἠD;橸parsl;槥ĀDaἯἳot;打rr;楱ƀcdiἾὁỸr;愯oô͒ĀahὉὋ;䎷耻ð䃰Āmrὓὗl耻ë䃫o;悬ƀcipὡὤὧl;䀡sôծĀeoὬὴctatioîՙnentialåչৡᾒ\0ᾞ\0ᾡᾧ\0\0ῆῌ\0ΐ\0ῦῪ \0 ⁚llingdotseñṄy;䑄male;晀ƀilrᾭᾳ῁lig;耀ﬃɩᾹ\0\0᾽g;耀ﬀig;耀ﬄ;쀀𝔣lig;耀ﬁlig;쀀fjƀaltῙ῜ῡt;晭ig;耀ﬂns;斱of;䆒ǰ΅\0ῳf;쀀𝕗ĀakֿῷĀ;vῼ´拔;櫙artint;樍Āao‌⁕Ācs‑⁒α‚‰‸⁅⁈\0⁐β•‥‧‪‬\0‮耻½䂽;慓耻¼䂼;慕;慙;慛Ƴ‴\0‶;慔;慖ʴ‾⁁\0\0⁃耻¾䂾;慗;慜5;慘ƶ⁌\0⁎;慚;慝8;慞l;恄wn;挢cr;쀀𝒻ࢀEabcdefgijlnorstv₂₉₟₥₰₴⃰⃵⃺⃿℃ℒℸ̗ℾ⅒↞Ā;lٍ₇;檌ƀcmpₐₕ₝ute;䇵maĀ;dₜ᳚䎳;檆reve;䄟Āiy₪₮rc;䄝;䐳ot;䄡Ȁ;lqsؾق₽⃉ƀ;qsؾٌ⃄lanô٥Ȁ;cdl٥⃒⃥⃕c;檩otĀ;o⃜⃝檀Ā;l⃢⃣檂;檄Ā;e⃪⃭쀀⋛︀s;檔r;쀀𝔤Ā;gٳ؛mel;愷cy;䑓Ȁ;Eajٚℌℎℐ;檒;檥;檤ȀEaesℛℝ℩ℴ;扩pĀ;p℣ℤ檊rox»ℤĀ;q℮ℯ檈Ā;q℮ℛim;拧pf;쀀𝕘Āci⅃ⅆr;愊mƀ;el٫ⅎ⅐;檎;檐茀>;cdlqr׮ⅠⅪⅮⅳⅹĀciⅥⅧ;檧r;橺ot;拗Par;榕uest;橼ʀadelsↄⅪ←ٖ↛ǰ↉\0↎proø₞r;楸qĀlqؿ↖lesó₈ií٫Āen↣↭rtneqq;쀀≩︀Å↪ԀAabcefkosy⇄⇇⇱⇵⇺∘∝∯≨≽ròΠȀilmr⇐⇔⇗⇛rsðᒄf»․ilôکĀdr⇠⇤cy;䑊ƀ;cwࣴ⇫⇯ir;楈;憭ar;意irc;䄥ƀalr∁∎∓rtsĀ;u∉∊晥it»∊lip;怦con;抹r;쀀𝔥sĀew∣∩arow;椥arow;椦ʀamopr∺∾≃≞≣rr;懿tht;戻kĀlr≉≓eftarrow;憩ightarrow;憪f;쀀𝕙bar;怕ƀclt≯≴≸r;쀀𝒽asè⇴rok;䄧Ābp⊂⊇ull;恃hen»ᱛૡ⊣\0⊪\0⊸⋅⋎\0⋕⋳\0\0⋸⌢⍧⍢⍿\0⎆⎪⎴cute耻í䃭ƀ;iyݱ⊰⊵rc耻î䃮;䐸Ācx⊼⊿y;䐵cl耻¡䂡ĀfrΟ⋉;쀀𝔦rave耻ì䃬Ȁ;inoܾ⋝⋩⋮Āin⋢⋦nt;樌t;戭fin;槜ta;愩lig;䄳ƀaop⋾⌚⌝ƀcgt⌅⌈⌗r;䄫ƀelpܟ⌏⌓inåގarôܠh;䄱f;抷ed;䆵ʀ;cfotӴ⌬⌱⌽⍁are;愅inĀ;t⌸⌹戞ie;槝doô⌙ʀ;celpݗ⍌⍐⍛⍡al;抺Āgr⍕⍙eróᕣã⍍arhk;樗rod;樼Ȁcgpt⍯⍲⍶⍻y;䑑on;䄯f;쀀𝕚a;䎹uest耻¿䂿Āci⎊⎏r;쀀𝒾nʀ;EdsvӴ⎛⎝⎡ӳ;拹ot;拵Ā;v⎦⎧拴;拳Ā;iݷ⎮lde;䄩ǫ⎸\0⎼cy;䑖l耻ï䃯̀cfmosu⏌⏗⏜⏡⏧⏵Āiy⏑⏕rc;䄵;䐹r;쀀𝔧ath;䈷pf;쀀𝕛ǣ⏬\0⏱r;쀀𝒿rcy;䑘kcy;䑔Ѐacfghjos␋␖␢␧␭␱␵␻ppaĀ;v␓␔䎺;䏰Āey␛␠dil;䄷;䐺r;쀀𝔨reen;䄸cy;䑅cy;䑜pf;쀀𝕜cr;쀀𝓀஀ABEHabcdefghjlmnoprstuv⑰⒁⒆⒍⒑┎┽╚▀♎♞♥♹♽⚚⚲⛘❝❨➋⟀⠁⠒ƀart⑷⑺⑼rò৆òΕail;椛arr;椎Ā;gঔ⒋;檋ar;楢ॣ⒥\0⒪\0⒱\0\0\0\0\0⒵Ⓔ\0ⓆⓈⓍ\0⓹ute;䄺mptyv;榴raîࡌbda;䎻gƀ;dlࢎⓁⓃ;榑åࢎ;檅uo耻«䂫rЀ;bfhlpst࢙ⓞⓦⓩ⓫⓮⓱⓵Ā;f࢝ⓣs;椟s;椝ë≒p;憫l;椹im;楳l;憢ƀ;ae⓿─┄檫il;椙Ā;s┉┊檭;쀀⪭︀ƀabr┕┙┝rr;椌rk;杲Āak┢┬cĀek┨┪;䁻;䁛Āes┱┳;榋lĀdu┹┻;榏;榍Ȁaeuy╆╋╖╘ron;䄾Ādi═╔il;䄼ìࢰâ┩;䐻Ȁcqrs╣╦╭╽a;椶uoĀ;rนᝆĀdu╲╷har;楧shar;楋h;憲ʀ;fgqs▋▌উ◳◿扤tʀahlrt▘▤▷◂◨rrowĀ;t࢙□aé⓶arpoonĀdu▯▴own»њp»०eftarrows;懇ightƀahs◍◖◞rrowĀ;sࣴࢧarpoonó྘quigarro÷⇰hreetimes;拋ƀ;qs▋ও◺lanôবʀ;cdgsব☊☍☝☨c;檨otĀ;o☔☕橿Ā;r☚☛檁;檃Ā;e☢☥쀀⋚︀s;檓ʀadegs☳☹☽♉♋pproøⓆot;拖qĀgq♃♅ôউgtò⒌ôছiíলƀilr♕࣡♚sht;楼;쀀𝔩Ā;Eজ♣;檑š♩♶rĀdu▲♮Ā;l॥♳;楪lk;斄cy;䑙ʀ;achtੈ⚈⚋⚑⚖rò◁orneòᴈard;楫ri;旺Āio⚟⚤dot;䅀ustĀ;a⚬⚭掰che»⚭ȀEaes⚻⚽⛉⛔;扨pĀ;p⛃⛄檉rox»⛄Ā;q⛎⛏檇Ā;q⛎⚻im;拦Ѐabnoptwz⛩⛴⛷✚✯❁❇❐Ānr⛮⛱g;柬r;懽rëࣁgƀlmr⛿✍✔eftĀar০✇ightá৲apsto;柼ightá৽parrowĀlr✥✩efô⓭ight;憬ƀafl✶✹✽r;榅;쀀𝕝us;樭imes;樴š❋❏st;戗áፎƀ;ef❗❘᠀旊nge»❘arĀ;l❤❥䀨t;榓ʀachmt❳❶❼➅➇ròࢨorneòᶌarĀ;d྘➃;業;怎ri;抿̀achiqt➘➝ੀ➢➮➻quo;怹r;쀀𝓁mƀ;egল➪➬;檍;檏Ābu┪➳oĀ;rฟ➹;怚rok;䅂萀<;cdhilqrࠫ⟒☹⟜⟠⟥⟪⟰Āci⟗⟙;檦r;橹reå◲mes;拉arr;楶uest;橻ĀPi⟵⟹ar;榖ƀ;ef⠀भ᠛旃rĀdu⠇⠍shar;楊har;楦Āen⠗⠡rtneqq;쀀≨︀Å⠞܀Dacdefhilnopsu⡀⡅⢂⢎⢓⢠⢥⢨⣚⣢⣤ઃ⣳⤂Dot;戺Ȁclpr⡎⡒⡣⡽r耻¯䂯Āet⡗⡙;時Ā;e⡞⡟朠se»⡟Ā;sျ⡨toȀ;dluျ⡳⡷⡻owîҌefôएðᏑker;斮Āoy⢇⢌mma;権;䐼ash;怔asuredangle»ᘦr;쀀𝔪o;愧ƀcdn⢯⢴⣉ro耻µ䂵Ȁ;acdᑤ⢽⣀⣄sôᚧir;櫰ot肻·Ƶusƀ;bd⣒ᤃ⣓戒Ā;uᴼ⣘;横ţ⣞⣡p;櫛ò−ðઁĀdp⣩⣮els;抧f;쀀𝕞Āct⣸⣽r;쀀𝓂pos»ᖝƀ;lm⤉⤊⤍䎼timap;抸ఀGLRVabcdefghijlmoprstuvw⥂⥓⥾⦉⦘⧚⧩⨕⨚⩘⩝⪃⪕⪤⪨⬄⬇⭄⭿⮮ⰴⱧⱼ⳩Āgt⥇⥋;쀀⋙̸Ā;v⥐௏쀀≫⃒ƀelt⥚⥲⥶ftĀar⥡⥧rrow;懍ightarrow;懎;쀀⋘̸Ā;v⥻ే쀀≪⃒ightarrow;懏ĀDd⦎⦓ash;抯ash;抮ʀbcnpt⦣⦧⦬⦱⧌la»˞ute;䅄g;쀀∠⃒ʀ;Eiop඄⦼⧀⧅⧈;쀀⩰̸d;쀀≋̸s;䅉roø඄urĀ;a⧓⧔普lĀ;s⧓ସǳ⧟\0⧣p肻 ଷmpĀ;e௹ఀʀaeouy⧴⧾⨃⨐⨓ǰ⧹\0⧻;橃on;䅈dil;䅆ngĀ;dൾ⨊ot;쀀⩭̸p;橂;䐽ash;怓΀;Aadqsxஒ⨩⨭⨻⩁⩅⩐rr;懗rĀhr⨳⨶k;椤Ā;oᏲᏰot;쀀≐̸uiöୣĀei⩊⩎ar;椨í஘istĀ;s஠டr;쀀𝔫ȀEest௅⩦⩹⩼ƀ;qs஼⩭௡ƀ;qs஼௅⩴lanô௢ií௪Ā;rஶ⪁»ஷƀAap⪊⪍⪑rò⥱rr;憮ar;櫲ƀ;svྍ⪜ྌĀ;d⪡⪢拼;拺cy;䑚΀AEadest⪷⪺⪾⫂⫅⫶⫹rò⥦;쀀≦̸rr;憚r;急Ȁ;fqs఻⫎⫣⫯tĀar⫔⫙rro÷⫁ightarro÷⪐ƀ;qs఻⪺⫪lanôౕĀ;sౕ⫴»శiíౝĀ;rవ⫾iĀ;eచథiäඐĀpt⬌⬑f;쀀𝕟膀¬;in⬙⬚⬶䂬nȀ;Edvஉ⬤⬨⬮;쀀⋹̸ot;쀀⋵̸ǡஉ⬳⬵;拷;拶iĀ;vಸ⬼ǡಸ⭁⭃;拾;拽ƀaor⭋⭣⭩rȀ;ast୻⭕⭚⭟lleì୻l;쀀⫽⃥;쀀∂̸lint;樔ƀ;ceಒ⭰⭳uåಥĀ;cಘ⭸Ā;eಒ⭽ñಘȀAait⮈⮋⮝⮧rò⦈rrƀ;cw⮔⮕⮙憛;쀀⤳̸;쀀↝̸ghtarrow»⮕riĀ;eೋೖ΀chimpqu⮽⯍⯙⬄୸⯤⯯Ȁ;cerല⯆ഷ⯉uå൅;쀀𝓃ortɭ⬅\0\0⯖ará⭖mĀ;e൮⯟Ā;q൴൳suĀbp⯫⯭å೸åഋƀbcp⯶ⰑⰙȀ;Ees⯿ⰀഢⰄ抄;쀀⫅̸etĀ;eഛⰋqĀ;qണⰀcĀ;eലⰗñസȀ;EesⰢⰣൟⰧ抅;쀀⫆̸etĀ;e൘ⰮqĀ;qൠⰣȀgilrⰽⰿⱅⱇìௗlde耻ñ䃱çృiangleĀlrⱒⱜeftĀ;eచⱚñదightĀ;eೋⱥñ೗Ā;mⱬⱭ䎽ƀ;esⱴⱵⱹ䀣ro;愖p;怇ҀDHadgilrsⲏⲔⲙⲞⲣⲰⲶⳓⳣash;抭arr;椄p;쀀≍⃒ash;抬ĀetⲨⲬ;쀀≥⃒;쀀>⃒nfin;槞ƀAetⲽⳁⳅrr;椂;쀀≤⃒Ā;rⳊⳍ쀀<⃒ie;쀀⊴⃒ĀAtⳘⳜrr;椃rie;쀀⊵⃒im;쀀∼⃒ƀAan⳰⳴ⴂrr;懖rĀhr⳺⳽k;椣Ā;oᏧᏥear;椧ቓ᪕\0\0\0\0\0\0\0\0\0\0\0\0\0ⴭ\0ⴸⵈⵠⵥ⵲ⶄᬇ\0\0ⶍⶫ\0ⷈⷎ\0ⷜ⸙⸫⸾⹃Ācsⴱ᪗ute耻ó䃳ĀiyⴼⵅrĀ;c᪞ⵂ耻ô䃴;䐾ʀabios᪠ⵒⵗǈⵚlac;䅑v;樸old;榼lig;䅓Ācr⵩⵭ir;榿;쀀𝔬ͯ⵹\0\0⵼\0ⶂn;䋛ave耻ò䃲;槁Ābmⶈ෴ar;榵Ȁacitⶕ⶘ⶥⶨrò᪀Āir⶝ⶠr;榾oss;榻nå๒;槀ƀaeiⶱⶵⶹcr;䅍ga;䏉ƀcdnⷀⷅǍron;䎿;榶pf;쀀𝕠ƀaelⷔ⷗ǒr;榷rp;榹΀;adiosvⷪⷫⷮ⸈⸍⸐⸖戨rò᪆Ȁ;efmⷷⷸ⸂⸅橝rĀ;oⷾⷿ愴f»ⷿ耻ª䂪耻º䂺gof;抶r;橖lope;橗;橛ƀclo⸟⸡⸧ò⸁ash耻ø䃸l;折iŬⸯ⸴de耻õ䃵esĀ;aǛ⸺s;樶ml耻ö䃶bar;挽ૡ⹞\0⹽\0⺀⺝\0⺢⺹\0\0⻋ຜ\0⼓\0\0⼫⾼\0⿈rȀ;astЃ⹧⹲຅脀¶;l⹭⹮䂶leìЃɩ⹸\0\0⹻m;櫳;櫽y;䐿rʀcimpt⺋⺏⺓ᡥ⺗nt;䀥od;䀮il;怰enk;怱r;쀀𝔭ƀimo⺨⺰⺴Ā;v⺭⺮䏆;䏕maô੶ne;明ƀ;tv⺿⻀⻈䏀chfork»´;䏖Āau⻏⻟nĀck⻕⻝kĀ;h⇴⻛;愎ö⇴sҀ;abcdemst⻳⻴ᤈ⻹⻽⼄⼆⼊⼎䀫cir;樣ir;樢Āouᵀ⼂;樥;橲n肻±ຝim;樦wo;樧ƀipu⼙⼠⼥ntint;樕f;쀀𝕡nd耻£䂣Ԁ;Eaceinosu່⼿⽁⽄⽇⾁⾉⾒⽾⾶;檳p;檷uå໙Ā;c໎⽌̀;acens່⽙⽟⽦⽨⽾pproø⽃urlyeñ໙ñ໎ƀaes⽯⽶⽺pprox;檹qq;檵im;拨iíໟmeĀ;s⾈ຮ怲ƀEas⽸⾐⽺ð⽵ƀdfp໬⾙⾯ƀals⾠⾥⾪lar;挮ine;挒urf;挓Ā;t໻⾴ï໻rel;抰Āci⿀⿅r;쀀𝓅;䏈ncsp;怈̀fiopsu⿚⋢⿟⿥⿫⿱r;쀀𝔮pf;쀀𝕢rime;恗cr;쀀𝓆ƀaeo⿸〉〓tĀei⿾々rnionóڰnt;樖stĀ;e【】䀿ñἙô༔઀ABHabcdefhilmnoprstux぀けさすムㄎㄫㅇㅢㅲㆎ㈆㈕㈤㈩㉘㉮㉲㊐㊰㊷ƀartぇおがròႳòϝail;検aròᱥar;楤΀cdenqrtとふへみわゔヌĀeuねぱ;쀀∽̱te;䅕iãᅮmptyv;榳gȀ;del࿑らるろ;榒;榥å࿑uo耻»䂻rր;abcfhlpstw࿜ガクシスゼゾダッデナp;極Ā;f࿠ゴs;椠;椳s;椞ë≝ð✮l;楅im;楴l;憣;憝Āaiパフil;椚oĀ;nホボ戶aló༞ƀabrョリヮrò៥rk;杳ĀakンヽcĀekヹ・;䁽;䁝Āes㄂㄄;榌lĀduㄊㄌ;榎;榐Ȁaeuyㄗㄜㄧㄩron;䅙Ādiㄡㄥil;䅗ì࿲âヺ;䑀Ȁclqsㄴㄷㄽㅄa;椷dhar;楩uoĀ;rȎȍh;憳ƀacgㅎㅟངlȀ;ipsླྀㅘㅛႜnåႻarôྩt;断ƀilrㅩဣㅮsht;楽;쀀𝔯ĀaoㅷㆆrĀduㅽㅿ»ѻĀ;l႑ㆄ;楬Ā;vㆋㆌ䏁;䏱ƀgns㆕ㇹㇼht̀ahlrstㆤㆰ㇂㇘㇤㇮rrowĀ;t࿜ㆭaéトarpoonĀduㆻㆿowîㅾp»႒eftĀah㇊㇐rrowó࿪arpoonóՑightarrows;應quigarro÷ニhreetimes;拌g;䋚ingdotseñἲƀahm㈍㈐㈓rò࿪aòՑ;怏oustĀ;a㈞㈟掱che»㈟mid;櫮Ȁabpt㈲㈽㉀㉒Ānr㈷㈺g;柭r;懾rëဃƀafl㉇㉊㉎r;榆;쀀𝕣us;樮imes;樵Āap㉝㉧rĀ;g㉣㉤䀩t;榔olint;樒arò㇣Ȁachq㉻㊀Ⴜ㊅quo;怺r;쀀𝓇Ābu・㊊oĀ;rȔȓƀhir㊗㊛㊠reåㇸmes;拊iȀ;efl㊪ၙᠡ㊫方tri;槎luhar;楨;愞ൡ㋕㋛㋟㌬㌸㍱\0㍺㎤\0\0㏬㏰\0㐨㑈㑚㒭㒱㓊㓱\0㘖\0\0㘳cute;䅛quï➺Ԁ;Eaceinpsyᇭ㋳㋵㋿㌂㌋㌏㌟㌦㌩;檴ǰ㋺\0㋼;檸on;䅡uåᇾĀ;dᇳ㌇il;䅟rc;䅝ƀEas㌖㌘㌛;檶p;檺im;择olint;樓iíሄ;䑁otƀ;be㌴ᵇ㌵担;橦΀Aacmstx㍆㍊㍗㍛㍞㍣㍭rr;懘rĀhr㍐㍒ë∨Ā;oਸ਼਴t耻§䂧i;䀻war;椩mĀin㍩ðnuóñt;朶rĀ;o㍶⁕쀀𝔰Ȁacoy㎂㎆㎑㎠rp;景Āhy㎋㎏cy;䑉;䑈rtɭ㎙\0\0㎜iäᑤaraì⹯耻­䂭Āgm㎨㎴maƀ;fv㎱㎲㎲䏃;䏂Ѐ;deglnprካ㏅㏉㏎㏖㏞㏡㏦ot;橪Ā;q኱ኰĀ;E㏓㏔檞;檠Ā;E㏛㏜檝;檟e;扆lus;樤arr;楲aròᄽȀaeit㏸㐈㐏㐗Āls㏽㐄lsetmé㍪hp;樳parsl;槤Ādlᑣ㐔e;挣Ā;e㐜㐝檪Ā;s㐢㐣檬;쀀⪬︀ƀflp㐮㐳㑂tcy;䑌Ā;b㐸㐹䀯Ā;a㐾㐿槄r;挿f;쀀𝕤aĀdr㑍ЂesĀ;u㑔㑕晠it»㑕ƀcsu㑠㑹㒟Āau㑥㑯pĀ;sᆈ㑫;쀀⊓︀pĀ;sᆴ㑵;쀀⊔︀uĀbp㑿㒏ƀ;esᆗᆜ㒆etĀ;eᆗ㒍ñᆝƀ;esᆨᆭ㒖etĀ;eᆨ㒝ñᆮƀ;afᅻ㒦ְrť㒫ֱ»ᅼaròᅈȀcemt㒹㒾㓂㓅r;쀀𝓈tmîñiì㐕aræᆾĀar㓎㓕rĀ;f㓔ឿ昆Āan㓚㓭ightĀep㓣㓪psiloîỠhé⺯s»⡒ʀbcmnp㓻㕞ሉ㖋㖎Ҁ;Edemnprs㔎㔏㔑㔕㔞㔣㔬㔱㔶抂;櫅ot;檽Ā;dᇚ㔚ot;櫃ult;櫁ĀEe㔨㔪;櫋;把lus;檿arr;楹ƀeiu㔽㕒㕕tƀ;en㔎㕅㕋qĀ;qᇚ㔏eqĀ;q㔫㔨m;櫇Ābp㕚㕜;櫕;櫓c̀;acensᇭ㕬㕲㕹㕻㌦pproø㋺urlyeñᇾñᇳƀaes㖂㖈㌛pproø㌚qñ㌗g;晪ڀ123;Edehlmnps㖩㖬㖯ሜ㖲㖴㗀㗉㗕㗚㗟㗨㗭耻¹䂹耻²䂲耻³䂳;櫆Āos㖹㖼t;檾ub;櫘Ā;dሢ㗅ot;櫄sĀou㗏㗒l;柉b;櫗arr;楻ult;櫂ĀEe㗤㗦;櫌;抋lus;櫀ƀeiu㗴㘉㘌tƀ;enሜ㗼㘂qĀ;qሢ㖲eqĀ;q㗧㗤m;櫈Ābp㘑㘓;櫔;櫖ƀAan㘜㘠㘭rr;懙rĀhr㘦㘨ë∮Ā;oਫ਩war;椪lig耻ß䃟௡㙑㙝㙠ዎ㙳㙹\0㙾㛂\0\0\0\0\0㛛㜃\0㜉㝬\0\0\0㞇ɲ㙖\0\0㙛get;挖;䏄rë๟ƀaey㙦㙫㙰ron;䅥dil;䅣;䑂lrec;挕r;쀀𝔱Ȁeiko㚆㚝㚵㚼ǲ㚋\0㚑eĀ4fኄኁaƀ;sv㚘㚙㚛䎸ym;䏑Ācn㚢㚲kĀas㚨㚮pproø዁im»ኬsðኞĀas㚺㚮ð዁rn耻þ䃾Ǭ̟㛆⋧es膀×;bd㛏㛐㛘䃗Ā;aᤏ㛕r;樱;樰ƀeps㛡㛣㜀á⩍Ȁ;bcf҆㛬㛰㛴ot;挶ir;櫱Ā;o㛹㛼쀀𝕥rk;櫚á㍢rime;怴ƀaip㜏㜒㝤dåቈ΀adempst㜡㝍㝀㝑㝗㝜㝟ngleʀ;dlqr㜰㜱㜶㝀㝂斵own»ᶻeftĀ;e⠀㜾ñम;扜ightĀ;e㊪㝋ñၚot;旬inus;樺lus;樹b;槍ime;樻ezium;揢ƀcht㝲㝽㞁Āry㝷㝻;쀀𝓉;䑆cy;䑛rok;䅧Āio㞋㞎xô᝷headĀlr㞗㞠eftarro÷ࡏightarrow»ཝऀAHabcdfghlmoprstuw㟐㟓㟗㟤㟰㟼㠎㠜㠣㠴㡑㡝㡫㢩㣌㣒㣪㣶ròϭar;楣Ācr㟜㟢ute耻ú䃺òᅐrǣ㟪\0㟭y;䑞ve;䅭Āiy㟵㟺rc耻û䃻;䑃ƀabh㠃㠆㠋ròᎭlac;䅱aòᏃĀir㠓㠘sht;楾;쀀𝔲rave耻ù䃹š㠧㠱rĀlr㠬㠮»ॗ»ႃlk;斀Āct㠹㡍ɯ㠿\0\0㡊rnĀ;e㡅㡆挜r»㡆op;挏ri;旸Āal㡖㡚cr;䅫肻¨͉Āgp㡢㡦on;䅳f;쀀𝕦̀adhlsuᅋ㡸㡽፲㢑㢠ownáᎳarpoonĀlr㢈㢌efô㠭ighô㠯iƀ;hl㢙㢚㢜䏅»ᏺon»㢚parrows;懈ƀcit㢰㣄㣈ɯ㢶\0\0㣁rnĀ;e㢼㢽挝r»㢽op;挎ng;䅯ri;旹cr;쀀𝓊ƀdir㣙㣝㣢ot;拰lde;䅩iĀ;f㜰㣨»᠓Āam㣯㣲rò㢨l耻ü䃼angle;榧ހABDacdeflnoprsz㤜㤟㤩㤭㦵㦸㦽㧟㧤㧨㧳㧹㧽㨁㨠ròϷarĀ;v㤦㤧櫨;櫩asèϡĀnr㤲㤷grt;榜΀eknprst㓣㥆㥋㥒㥝㥤㦖appá␕othinçẖƀhir㓫⻈㥙opô⾵Ā;hᎷ㥢ïㆍĀiu㥩㥭gmá㎳Ābp㥲㦄setneqĀ;q㥽㦀쀀⊊︀;쀀⫋︀setneqĀ;q㦏㦒쀀⊋︀;쀀⫌︀Āhr㦛㦟etá㚜iangleĀlr㦪㦯eft»थight»ၑy;䐲ash»ံƀelr㧄㧒㧗ƀ;beⷪ㧋㧏ar;抻q;扚lip;拮Ābt㧜ᑨaòᑩr;쀀𝔳tré㦮suĀbp㧯㧱»ജ»൙pf;쀀𝕧roð໻tré㦴Ācu㨆㨋r;쀀𝓋Ābp㨐㨘nĀEe㦀㨖»㥾nĀEe㦒㨞»㦐igzag;榚΀cefoprs㨶㨻㩖㩛㩔㩡㩪irc;䅵Ādi㩀㩑Ābg㩅㩉ar;機eĀ;qᗺ㩏;扙erp;愘r;쀀𝔴pf;쀀𝕨Ā;eᑹ㩦atèᑹcr;쀀𝓌ૣណ㪇\0㪋\0㪐㪛\0\0㪝㪨㪫㪯\0\0㫃㫎\0㫘ៜ៟tré៑r;쀀𝔵ĀAa㪔㪗ròσrò৶;䎾ĀAa㪡㪤ròθrò৫að✓is;拻ƀdptឤ㪵㪾Āfl㪺ឩ;쀀𝕩imåឲĀAa㫇㫊ròώròਁĀcq㫒ីr;쀀𝓍Āpt៖㫜ré។Ѐacefiosu㫰㫽㬈㬌㬑㬕㬛㬡cĀuy㫶㫻te耻ý䃽;䑏Āiy㬂㬆rc;䅷;䑋n耻¥䂥r;쀀𝔶cy;䑗pf;쀀𝕪cr;쀀𝓎Ācm㬦㬩y;䑎l耻ÿ䃿Ԁacdefhiosw㭂㭈㭔㭘㭤㭩㭭㭴㭺㮀cute;䅺Āay㭍㭒ron;䅾;䐷ot;䅼Āet㭝㭡træᕟa;䎶r;쀀𝔷cy;䐶grarr;懝pf;쀀𝕫cr;쀀𝓏Ājn㮅㮇;怍j;怌'.split("").map((e) => e.charCodeAt(0))
), ci = new Uint16Array(
  // prettier-ignore
  "Ȁaglq	\x1Bɭ\0\0p;䀦os;䀧t;䀾t;䀼uot;䀢".split("").map((e) => e.charCodeAt(0))
);
var Ru;
const oi = /* @__PURE__ */ new Map([
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
]), li = (
  // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition, node/no-unsupported-features/es-builtins
  (Ru = String.fromCodePoint) !== null && Ru !== void 0 ? Ru : function(e) {
    let u = "";
    return e > 65535 && (e -= 65536, u += String.fromCharCode(e >>> 10 & 1023 | 55296), e = 56320 | e & 1023), u += String.fromCharCode(e), u;
  }
);
function fi(e) {
  var u;
  return e >= 55296 && e <= 57343 || e > 1114111 ? 65533 : (u = oi.get(e)) !== null && u !== void 0 ? u : e;
}
var ee;
(function(e) {
  e[e.NUM = 35] = "NUM", e[e.SEMI = 59] = "SEMI", e[e.EQUALS = 61] = "EQUALS", e[e.ZERO = 48] = "ZERO", e[e.NINE = 57] = "NINE", e[e.LOWER_A = 97] = "LOWER_A", e[e.LOWER_F = 102] = "LOWER_F", e[e.LOWER_X = 120] = "LOWER_X", e[e.LOWER_Z = 122] = "LOWER_Z", e[e.UPPER_A = 65] = "UPPER_A", e[e.UPPER_F = 70] = "UPPER_F", e[e.UPPER_Z = 90] = "UPPER_Z";
})(ee || (ee = {}));
const di = 32;
var Te;
(function(e) {
  e[e.VALUE_LENGTH = 49152] = "VALUE_LENGTH", e[e.BRANCH_LENGTH = 16256] = "BRANCH_LENGTH", e[e.JUMP_TABLE = 127] = "JUMP_TABLE";
})(Te || (Te = {}));
function vt(e) {
  return e >= ee.ZERO && e <= ee.NINE;
}
function Ai(e) {
  return e >= ee.UPPER_A && e <= ee.UPPER_F || e >= ee.LOWER_A && e <= ee.LOWER_F;
}
function hi(e) {
  return e >= ee.UPPER_A && e <= ee.UPPER_Z || e >= ee.LOWER_A && e <= ee.LOWER_Z || vt(e);
}
function bi(e) {
  return e === ee.EQUALS || hi(e);
}
var $;
(function(e) {
  e[e.EntityStart = 0] = "EntityStart", e[e.NumericStart = 1] = "NumericStart", e[e.NumericDecimal = 2] = "NumericDecimal", e[e.NumericHex = 3] = "NumericHex", e[e.NamedEntity = 4] = "NamedEntity";
})($ || ($ = {}));
var Se;
(function(e) {
  e[e.Legacy = 0] = "Legacy", e[e.Strict = 1] = "Strict", e[e.Attribute = 2] = "Attribute";
})(Se || (Se = {}));
class pi {
  constructor(u, t, s) {
    this.decodeTree = u, this.emitCodePoint = t, this.errors = s, this.state = $.EntityStart, this.consumed = 1, this.result = 0, this.treeIndex = 0, this.excess = 1, this.decodeMode = Se.Strict;
  }
  /** Resets the instance to make it reusable. */
  startEntity(u) {
    this.decodeMode = u, this.state = $.EntityStart, this.result = 0, this.treeIndex = 0, this.excess = 1, this.consumed = 1;
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
      case $.EntityStart:
        return u.charCodeAt(t) === ee.NUM ? (this.state = $.NumericStart, this.consumed += 1, this.stateNumericStart(u, t + 1)) : (this.state = $.NamedEntity, this.stateNamedEntity(u, t));
      case $.NumericStart:
        return this.stateNumericStart(u, t);
      case $.NumericDecimal:
        return this.stateNumericDecimal(u, t);
      case $.NumericHex:
        return this.stateNumericHex(u, t);
      case $.NamedEntity:
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
    return t >= u.length ? -1 : (u.charCodeAt(t) | di) === ee.LOWER_X ? (this.state = $.NumericHex, this.consumed += 1, this.stateNumericHex(u, t + 1)) : (this.state = $.NumericDecimal, this.stateNumericDecimal(u, t));
  }
  addToNumericResult(u, t, s, a) {
    if (t !== s) {
      const r = s - t;
      this.result = this.result * Math.pow(a, r) + parseInt(u.substr(t, r), a), this.consumed += r;
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
    const s = t;
    for (; t < u.length; ) {
      const a = u.charCodeAt(t);
      if (vt(a) || Ai(a))
        t += 1;
      else
        return this.addToNumericResult(u, s, t, 16), this.emitNumericEntity(a, 3);
    }
    return this.addToNumericResult(u, s, t, 16), -1;
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
    const s = t;
    for (; t < u.length; ) {
      const a = u.charCodeAt(t);
      if (vt(a))
        t += 1;
      else
        return this.addToNumericResult(u, s, t, 10), this.emitNumericEntity(a, 2);
    }
    return this.addToNumericResult(u, s, t, 10), -1;
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
    var s;
    if (this.consumed <= t)
      return (s = this.errors) === null || s === void 0 || s.absenceOfDigitsInNumericCharacterReference(this.consumed), 0;
    if (u === ee.SEMI)
      this.consumed += 1;
    else if (this.decodeMode === Se.Strict)
      return 0;
    return this.emitCodePoint(fi(this.result), this.consumed), this.errors && (u !== ee.SEMI && this.errors.missingSemicolonAfterCharacterReference(), this.errors.validateNumericCharacterReference(this.result)), this.consumed;
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
    const { decodeTree: s } = this;
    let a = s[this.treeIndex], r = (a & Te.VALUE_LENGTH) >> 14;
    for (; t < u.length; t++, this.excess++) {
      const o = u.charCodeAt(t);
      if (this.treeIndex = gi(s, a, this.treeIndex + Math.max(1, r), o), this.treeIndex < 0)
        return this.result === 0 || // If we are parsing an attribute
        this.decodeMode === Se.Attribute && // We shouldn't have consumed any characters after the entity,
        (r === 0 || // And there should be no invalid characters.
        bi(o)) ? 0 : this.emitNotTerminatedNamedEntity();
      if (a = s[this.treeIndex], r = (a & Te.VALUE_LENGTH) >> 14, r !== 0) {
        if (o === ee.SEMI)
          return this.emitNamedEntityData(this.treeIndex, r, this.consumed + this.excess);
        this.decodeMode !== Se.Strict && (this.result = this.treeIndex, this.consumed += this.excess, this.excess = 0);
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
    const { result: t, decodeTree: s } = this, a = (s[t] & Te.VALUE_LENGTH) >> 14;
    return this.emitNamedEntityData(t, a, this.consumed), (u = this.errors) === null || u === void 0 || u.missingSemicolonAfterCharacterReference(), this.consumed;
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
  emitNamedEntityData(u, t, s) {
    const { decodeTree: a } = this;
    return this.emitCodePoint(t === 1 ? a[u] & ~Te.VALUE_LENGTH : a[u + 1], s), t === 3 && this.emitCodePoint(a[u + 2], s), s;
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
      case $.NamedEntity:
        return this.result !== 0 && (this.decodeMode !== Se.Attribute || this.result === this.treeIndex) ? this.emitNotTerminatedNamedEntity() : 0;
      // Otherwise, emit a numeric entity if we have one.
      case $.NumericDecimal:
        return this.emitNumericEntity(0, 2);
      case $.NumericHex:
        return this.emitNumericEntity(0, 3);
      case $.NumericStart:
        return (u = this.errors) === null || u === void 0 || u.absenceOfDigitsInNumericCharacterReference(this.consumed), 0;
      case $.EntityStart:
        return 0;
    }
  }
}
function L0(e) {
  let u = "";
  const t = new pi(e, (s) => u += li(s));
  return function(a, r) {
    let o = 0, i = 0;
    for (; (i = a.indexOf("&", i)) >= 0; ) {
      u += a.slice(o, i), t.startEntity(r);
      const n = t.write(
        a,
        // Skip the "&"
        i + 1
      );
      if (n < 0) {
        o = i + t.end();
        break;
      }
      o = i + n, i = n === 0 ? o + 1 : o;
    }
    const c = u + a.slice(o);
    return u = "", c;
  };
}
function gi(e, u, t, s) {
  const a = (u & Te.BRANCH_LENGTH) >> 7, r = u & Te.JUMP_TABLE;
  if (a === 0)
    return r !== 0 && s === r ? t : -1;
  if (r) {
    const c = s - r;
    return c < 0 || c >= a ? -1 : e[t + c] - 1;
  }
  let o = t, i = o + a - 1;
  for (; o <= i; ) {
    const c = o + i >>> 1, n = e[c];
    if (n < s)
      o = c + 1;
    else if (n > s)
      i = c - 1;
    else
      return e[c + a];
  }
  return -1;
}
const mi = L0(si);
L0(ci);
function P0(e, u = Se.Legacy) {
  return mi(e, u);
}
function xi(e) {
  return Object.prototype.toString.call(e);
}
function Ft(e) {
  return xi(e) === "[object String]";
}
const yi = Object.prototype.hasOwnProperty;
function wi(e, u) {
  return yi.call(e, u);
}
function wu(e) {
  return Array.prototype.slice.call(arguments, 1).forEach(function(t) {
    if (t) {
      if (typeof t != "object")
        throw new TypeError(t + "must be object");
      Object.keys(t).forEach(function(s) {
        e[s] = t[s];
      });
    }
  }), e;
}
function G0(e, u, t) {
  return [].concat(e.slice(0, u), t, e.slice(u + 1));
}
function St(e) {
  return !(e >= 55296 && e <= 57343 || e >= 64976 && e <= 65007 || (e & 65535) === 65535 || (e & 65535) === 65534 || e >= 0 && e <= 8 || e === 11 || e >= 14 && e <= 31 || e >= 127 && e <= 159 || e > 1114111);
}
function xu(e) {
  if (e > 65535) {
    e -= 65536;
    const u = 55296 + (e >> 10), t = 56320 + (e & 1023);
    return String.fromCharCode(u, t);
  }
  return String.fromCharCode(e);
}
const H0 = /\\([!"#$%&'()*+,\-./:;<=>?@[\\\]^_`{|}~])/g, Ci = /&([a-z#][a-z0-9]{1,31});/gi, vi = new RegExp(H0.source + "|" + Ci.source, "gi"), Di = /^#((?:x[a-f0-9]{1,8}|[0-9]{1,8}))$/i;
function Ei(e, u) {
  if (u.charCodeAt(0) === 35 && Di.test(u)) {
    const s = u[1].toLowerCase() === "x" ? parseInt(u.slice(2), 16) : parseInt(u.slice(1), 10);
    return St(s) ? xu(s) : e;
  }
  const t = P0(e);
  return t !== e ? t : e;
}
function _i(e) {
  return e.indexOf("\\") < 0 ? e : e.replace(H0, "$1");
}
function Ue(e) {
  return e.indexOf("\\") < 0 && e.indexOf("&") < 0 ? e : e.replace(vi, function(u, t, s) {
    return t || Ei(u, s);
  });
}
const Ii = /[&<>"]/, ki = /[&<>"]/g, Bi = {
  "&": "&amp;",
  "<": "&lt;",
  ">": "&gt;",
  '"': "&quot;"
};
function Fi(e) {
  return Bi[e];
}
function Re(e) {
  return Ii.test(e) ? e.replace(ki, Fi) : e;
}
const Si = /[.?*+^$[\]\\(){}|-]/g;
function Ti(e) {
  return e.replace(Si, "\\$&");
}
function V(e) {
  switch (e) {
    case 9:
    case 32:
      return !0;
  }
  return !1;
}
function Ze(e) {
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
function Ve(e) {
  return Bt.test(e) || O0.test(e);
}
function ze(e) {
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
function Cu(e) {
  return e = e.trim().replace(/\s+/g, " "), "ẞ".toLowerCase() === "Ṿ" && (e = e.replace(/ẞ/g, "ß")), e.toLowerCase().toUpperCase();
}
const Ri = { mdurl: ni, ucmicro: ai }, Ni = /* @__PURE__ */ Object.freeze(/* @__PURE__ */ Object.defineProperty({
  __proto__: null,
  arrayReplaceAt: G0,
  assign: wu,
  escapeHtml: Re,
  escapeRE: Ti,
  fromCodePoint: xu,
  has: wi,
  isMdAsciiPunct: ze,
  isPunctChar: Ve,
  isSpace: V,
  isString: Ft,
  isValidEntityCode: St,
  isWhiteSpace: Ze,
  lib: Ri,
  normalizeReference: Cu,
  unescapeAll: Ue,
  unescapeMd: _i
}, Symbol.toStringTag, { value: "Module" }));
function Mi(e, u, t) {
  let s, a, r, o;
  const i = e.posMax, c = e.pos;
  for (e.pos = u + 1, s = 1; e.pos < i; ) {
    if (r = e.src.charCodeAt(e.pos), r === 93 && (s--, s === 0)) {
      a = !0;
      break;
    }
    if (o = e.pos, e.md.inline.skipToken(e), r === 91) {
      if (o === e.pos - 1)
        s++;
      else if (t)
        return e.pos = c, -1;
    }
  }
  let n = -1;
  return a && (n = e.pos), e.pos = c, n;
}
function Oi(e, u, t) {
  let s, a = u;
  const r = {
    ok: !1,
    pos: 0,
    str: ""
  };
  if (e.charCodeAt(a) === 60) {
    for (a++; a < t; ) {
      if (s = e.charCodeAt(a), s === 10 || s === 60)
        return r;
      if (s === 62)
        return r.pos = a + 1, r.str = Ue(e.slice(u + 1, a)), r.ok = !0, r;
      if (s === 92 && a + 1 < t) {
        a += 2;
        continue;
      }
      a++;
    }
    return r;
  }
  let o = 0;
  for (; a < t && (s = e.charCodeAt(a), !(s === 32 || s < 32 || s === 127)); ) {
    if (s === 92 && a + 1 < t) {
      if (e.charCodeAt(a + 1) === 32)
        break;
      a += 2;
      continue;
    }
    if (s === 40 && (o++, o > 32))
      return r;
    if (s === 41) {
      if (o === 0)
        break;
      o--;
    }
    a++;
  }
  return u === a || o !== 0 || (r.str = Ue(e.slice(u, a)), r.pos = a, r.ok = !0), r;
}
function Qi(e, u, t, s) {
  let a, r = u;
  const o = {
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
  if (s)
    o.str = s.str, o.marker = s.marker;
  else {
    if (r >= t)
      return o;
    let i = e.charCodeAt(r);
    if (i !== 34 && i !== 39 && i !== 40)
      return o;
    u++, r++, i === 40 && (i = 41), o.marker = i;
  }
  for (; r < t; ) {
    if (a = e.charCodeAt(r), a === o.marker)
      return o.pos = r + 1, o.str += Ue(e.slice(u, r)), o.ok = !0, o;
    if (a === 40 && o.marker === 41)
      return o;
    a === 92 && r + 1 < t && r++, r++;
  }
  return o.can_continue = !0, o.str += Ue(e.slice(u, r)), o;
}
const Li = /* @__PURE__ */ Object.freeze(/* @__PURE__ */ Object.defineProperty({
  __proto__: null,
  parseLinkDestination: Oi,
  parseLinkLabel: Mi,
  parseLinkTitle: Qi
}, Symbol.toStringTag, { value: "Module" })), Ce = {};
Ce.code_inline = function(e, u, t, s, a) {
  const r = e[u];
  return "<code" + a.renderAttrs(r) + ">" + Re(r.content) + "</code>";
};
Ce.code_block = function(e, u, t, s, a) {
  const r = e[u];
  return "<pre" + a.renderAttrs(r) + "><code>" + Re(e[u].content) + `</code></pre>
`;
};
Ce.fence = function(e, u, t, s, a) {
  const r = e[u], o = r.info ? Ue(r.info).trim() : "";
  let i = "", c = "";
  if (o) {
    const l = o.split(/(\s+)/g);
    i = l[0], c = l.slice(2).join("");
  }
  let n;
  if (t.highlight ? n = t.highlight(r.content, i, c) || Re(r.content) : n = Re(r.content), n.indexOf("<pre") === 0)
    return n + `
`;
  if (o) {
    const l = r.attrIndex("class"), f = r.attrs ? r.attrs.slice() : [];
    l < 0 ? f.push(["class", t.langPrefix + i]) : (f[l] = f[l].slice(), f[l][1] += " " + t.langPrefix + i);
    const A = {
      attrs: f
    };
    return `<pre><code${a.renderAttrs(A)}>${n}</code></pre>
`;
  }
  return `<pre><code${a.renderAttrs(r)}>${n}</code></pre>
`;
};
Ce.image = function(e, u, t, s, a) {
  const r = e[u];
  return r.attrs[r.attrIndex("alt")][1] = a.renderInlineAsText(r.children, t, s), a.renderToken(e, u, t);
};
Ce.hardbreak = function(e, u, t) {
  return t.xhtmlOut ? `<br />
` : `<br>
`;
};
Ce.softbreak = function(e, u, t) {
  return t.breaks ? t.xhtmlOut ? `<br />
` : `<br>
` : `
`;
};
Ce.text = function(e, u) {
  return Re(e[u].content);
};
Ce.html_block = function(e, u) {
  return e[u].content;
};
Ce.html_inline = function(e, u) {
  return e[u].content;
};
function Ke() {
  this.rules = wu({}, Ce);
}
Ke.prototype.renderAttrs = function(u) {
  let t, s, a;
  if (!u.attrs)
    return "";
  for (a = "", t = 0, s = u.attrs.length; t < s; t++)
    a += " " + Re(u.attrs[t][0]) + '="' + Re(u.attrs[t][1]) + '"';
  return a;
};
Ke.prototype.renderToken = function(u, t, s) {
  const a = u[t];
  let r = "";
  if (a.hidden)
    return "";
  a.block && a.nesting !== -1 && t && u[t - 1].hidden && (r += `
`), r += (a.nesting === -1 ? "</" : "<") + a.tag, r += this.renderAttrs(a), a.nesting === 0 && s.xhtmlOut && (r += " /");
  let o = !1;
  if (a.block && (o = !0, a.nesting === 1 && t + 1 < u.length)) {
    const i = u[t + 1];
    (i.type === "inline" || i.hidden || i.nesting === -1 && i.tag === a.tag) && (o = !1);
  }
  return r += o ? `>
` : ">", r;
};
Ke.prototype.renderInline = function(e, u, t) {
  let s = "";
  const a = this.rules;
  for (let r = 0, o = e.length; r < o; r++) {
    const i = e[r].type;
    typeof a[i] < "u" ? s += a[i](e, r, u, t, this) : s += this.renderToken(e, r, u);
  }
  return s;
};
Ke.prototype.renderInlineAsText = function(e, u, t) {
  let s = "";
  for (let a = 0, r = e.length; a < r; a++)
    switch (e[a].type) {
      case "text":
        s += e[a].content;
        break;
      case "image":
        s += this.renderInlineAsText(e[a].children, u, t);
        break;
      case "html_inline":
      case "html_block":
        s += e[a].content;
        break;
      case "softbreak":
      case "hardbreak":
        s += `
`;
        break;
    }
  return s;
};
Ke.prototype.render = function(e, u, t) {
  let s = "";
  const a = this.rules;
  for (let r = 0, o = e.length; r < o; r++) {
    const i = e[r].type;
    i === "inline" ? s += this.renderInline(e[r].children, u, t) : typeof a[i] < "u" ? s += a[i](e, r, u, t, this) : s += this.renderToken(e, r, u, t);
  }
  return s;
};
function te() {
  this.__rules__ = [], this.__cache__ = null;
}
te.prototype.__find__ = function(e) {
  for (let u = 0; u < this.__rules__.length; u++)
    if (this.__rules__[u].name === e)
      return u;
  return -1;
};
te.prototype.__compile__ = function() {
  const e = this, u = [""];
  e.__rules__.forEach(function(t) {
    t.enabled && t.alt.forEach(function(s) {
      u.indexOf(s) < 0 && u.push(s);
    });
  }), e.__cache__ = {}, u.forEach(function(t) {
    e.__cache__[t] = [], e.__rules__.forEach(function(s) {
      s.enabled && (t && s.alt.indexOf(t) < 0 || e.__cache__[t].push(s.fn));
    });
  });
};
te.prototype.at = function(e, u, t) {
  const s = this.__find__(e), a = t || {};
  if (s === -1)
    throw new Error("Parser rule not found: " + e);
  this.__rules__[s].fn = u, this.__rules__[s].alt = a.alt || [], this.__cache__ = null;
};
te.prototype.before = function(e, u, t, s) {
  const a = this.__find__(e), r = s || {};
  if (a === -1)
    throw new Error("Parser rule not found: " + e);
  this.__rules__.splice(a, 0, {
    name: u,
    enabled: !0,
    fn: t,
    alt: r.alt || []
  }), this.__cache__ = null;
};
te.prototype.after = function(e, u, t, s) {
  const a = this.__find__(e), r = s || {};
  if (a === -1)
    throw new Error("Parser rule not found: " + e);
  this.__rules__.splice(a + 1, 0, {
    name: u,
    enabled: !0,
    fn: t,
    alt: r.alt || []
  }), this.__cache__ = null;
};
te.prototype.push = function(e, u, t) {
  const s = t || {};
  this.__rules__.push({
    name: e,
    enabled: !0,
    fn: u,
    alt: s.alt || []
  }), this.__cache__ = null;
};
te.prototype.enable = function(e, u) {
  Array.isArray(e) || (e = [e]);
  const t = [];
  return e.forEach(function(s) {
    const a = this.__find__(s);
    if (a < 0) {
      if (u)
        return;
      throw new Error("Rules manager: invalid rule name " + s);
    }
    this.__rules__[a].enabled = !0, t.push(s);
  }, this), this.__cache__ = null, t;
};
te.prototype.enableOnly = function(e, u) {
  Array.isArray(e) || (e = [e]), this.__rules__.forEach(function(t) {
    t.enabled = !1;
  }), this.enable(e, u);
};
te.prototype.disable = function(e, u) {
  Array.isArray(e) || (e = [e]);
  const t = [];
  return e.forEach(function(s) {
    const a = this.__find__(s);
    if (a < 0) {
      if (u)
        return;
      throw new Error("Rules manager: invalid rule name " + s);
    }
    this.__rules__[a].enabled = !1, t.push(s);
  }, this), this.__cache__ = null, t;
};
te.prototype.getRules = function(e) {
  return this.__cache__ === null && this.__compile__(), this.__cache__[e] || [];
};
function me(e, u, t) {
  this.type = e, this.tag = u, this.attrs = null, this.map = null, this.nesting = t, this.level = 0, this.children = null, this.content = "", this.markup = "", this.info = "", this.meta = null, this.block = !1, this.hidden = !1;
}
me.prototype.attrIndex = function(u) {
  if (!this.attrs)
    return -1;
  const t = this.attrs;
  for (let s = 0, a = t.length; s < a; s++)
    if (t[s][0] === u)
      return s;
  return -1;
};
me.prototype.attrPush = function(u) {
  this.attrs ? this.attrs.push(u) : this.attrs = [u];
};
me.prototype.attrSet = function(u, t) {
  const s = this.attrIndex(u), a = [u, t];
  s < 0 ? this.attrPush(a) : this.attrs[s] = a;
};
me.prototype.attrGet = function(u) {
  const t = this.attrIndex(u);
  let s = null;
  return t >= 0 && (s = this.attrs[t][1]), s;
};
me.prototype.attrJoin = function(u, t) {
  const s = this.attrIndex(u);
  s < 0 ? this.attrPush([u, t]) : this.attrs[s][1] = this.attrs[s][1] + " " + t;
};
function q0(e, u, t) {
  this.src = e, this.env = t, this.tokens = [], this.inlineMode = !1, this.md = u;
}
q0.prototype.Token = me;
const Pi = /\r\n?|\n/g, Gi = /\0/g;
function Hi(e) {
  let u;
  u = e.src.replace(Pi, `
`), u = u.replace(Gi, "�"), e.src = u;
}
function qi(e) {
  let u;
  e.inlineMode ? (u = new e.Token("inline", "", 0), u.content = e.src, u.map = [0, 1], u.children = [], e.tokens.push(u)) : e.md.block.parse(e.src, e.md, e.env, e.tokens);
}
function Wi(e) {
  const u = e.tokens;
  for (let t = 0, s = u.length; t < s; t++) {
    const a = u[t];
    a.type === "inline" && e.md.inline.parse(a.content, e.md, e.env, a.children);
  }
}
function Ui(e) {
  return /^<a[>\s]/i.test(e);
}
function Ki(e) {
  return /^<\/a\s*>/i.test(e);
}
function Yi(e) {
  const u = e.tokens;
  if (e.md.options.linkify)
    for (let t = 0, s = u.length; t < s; t++) {
      if (u[t].type !== "inline" || !e.md.linkify.pretest(u[t].content))
        continue;
      let a = u[t].children, r = 0;
      for (let o = a.length - 1; o >= 0; o--) {
        const i = a[o];
        if (i.type === "link_close") {
          for (o--; a[o].level !== i.level && a[o].type !== "link_open"; )
            o--;
          continue;
        }
        if (i.type === "html_inline" && (Ui(i.content) && r > 0 && r--, Ki(i.content) && r++), !(r > 0) && i.type === "text" && e.md.linkify.test(i.content)) {
          const c = i.content;
          let n = e.md.linkify.match(c);
          const l = [];
          let f = i.level, A = 0;
          n.length > 0 && n[0].index === 0 && o > 0 && a[o - 1].type === "text_special" && (n = n.slice(1));
          for (let d = 0; d < n.length; d++) {
            const h = n[d].url, y = e.md.normalizeLink(h);
            if (!e.md.validateLink(y))
              continue;
            let C = n[d].text;
            n[d].schema ? n[d].schema === "mailto:" && !/^mailto:/i.test(C) ? C = e.md.normalizeLinkText("mailto:" + C).replace(/^mailto:/, "") : C = e.md.normalizeLinkText(C) : C = e.md.normalizeLinkText("http://" + C).replace(/^http:\/\//, "");
            const w = n[d].index;
            if (w > A) {
              const p = new e.Token("text", "", 0);
              p.content = c.slice(A, w), p.level = f, l.push(p);
            }
            const b = new e.Token("link_open", "a", 1);
            b.attrs = [["href", y]], b.level = f++, b.markup = "linkify", b.info = "auto", l.push(b);
            const x = new e.Token("text", "", 0);
            x.content = C, x.level = f, l.push(x);
            const m = new e.Token("link_close", "a", -1);
            m.level = --f, m.markup = "linkify", m.info = "auto", l.push(m), A = n[d].lastIndex;
          }
          if (A < c.length) {
            const d = new e.Token("text", "", 0);
            d.content = c.slice(A), d.level = f, l.push(d);
          }
          u[t].children = a = G0(a, o, l);
        }
      }
    }
}
const W0 = /\+-|\.\.|\?\?\?\?|!!!!|,,|--/, ji = /\((c|tm|r)\)/i, Ji = /\((c|tm|r)\)/ig, Zi = {
  c: "©",
  r: "®",
  tm: "™"
};
function Vi(e, u) {
  return Zi[u.toLowerCase()];
}
function zi(e) {
  let u = 0;
  for (let t = e.length - 1; t >= 0; t--) {
    const s = e[t];
    s.type === "text" && !u && (s.content = s.content.replace(Ji, Vi)), s.type === "link_open" && s.info === "auto" && u--, s.type === "link_close" && s.info === "auto" && u++;
  }
}
function Xi(e) {
  let u = 0;
  for (let t = e.length - 1; t >= 0; t--) {
    const s = e[t];
    s.type === "text" && !u && W0.test(s.content) && (s.content = s.content.replace(/\+-/g, "±").replace(/\.{2,}/g, "…").replace(/([?!])…/g, "$1..").replace(/([?!]){4,}/g, "$1$1$1").replace(/,{2,}/g, ",").replace(/(^|[^-])---(?=[^-]|$)/mg, "$1—").replace(/(^|\s)--(?=\s|$)/mg, "$1–").replace(/(^|[^-\s])--(?=[^-\s]|$)/mg, "$1–")), s.type === "link_open" && s.info === "auto" && u--, s.type === "link_close" && s.info === "auto" && u++;
  }
}
function $i(e) {
  let u;
  if (e.md.options.typographer)
    for (u = e.tokens.length - 1; u >= 0; u--)
      e.tokens[u].type === "inline" && (ji.test(e.tokens[u].content) && zi(e.tokens[u].children), W0.test(e.tokens[u].content) && Xi(e.tokens[u].children));
}
const ea = /['"]/, Xt = /['"]/g, $t = "’";
function iu(e, u, t) {
  return e.slice(0, u) + t + e.slice(u + 1);
}
function ua(e, u) {
  let t;
  const s = [];
  for (let a = 0; a < e.length; a++) {
    const r = e[a], o = e[a].level;
    for (t = s.length - 1; t >= 0 && !(s[t].level <= o); t--)
      ;
    if (s.length = t + 1, r.type !== "text")
      continue;
    let i = r.content, c = 0, n = i.length;
    e:
      for (; c < n; ) {
        Xt.lastIndex = c;
        const l = Xt.exec(i);
        if (!l)
          break;
        let f = !0, A = !0;
        c = l.index + 1;
        const d = l[0] === "'";
        let h = 32;
        if (l.index - 1 >= 0)
          h = i.charCodeAt(l.index - 1);
        else
          for (t = a - 1; t >= 0 && !(e[t].type === "softbreak" || e[t].type === "hardbreak"); t--)
            if (e[t].content) {
              h = e[t].content.charCodeAt(e[t].content.length - 1);
              break;
            }
        let y = 32;
        if (c < n)
          y = i.charCodeAt(c);
        else
          for (t = a + 1; t < e.length && !(e[t].type === "softbreak" || e[t].type === "hardbreak"); t++)
            if (e[t].content) {
              y = e[t].content.charCodeAt(0);
              break;
            }
        const C = ze(h) || Ve(String.fromCharCode(h)), w = ze(y) || Ve(String.fromCharCode(y)), b = Ze(h), x = Ze(y);
        if (x ? f = !1 : w && (b || C || (f = !1)), b ? A = !1 : C && (x || w || (A = !1)), y === 34 && l[0] === '"' && h >= 48 && h <= 57 && (A = f = !1), f && A && (f = C, A = w), !f && !A) {
          d && (r.content = iu(r.content, l.index, $t));
          continue;
        }
        if (A)
          for (t = s.length - 1; t >= 0; t--) {
            let m = s[t];
            if (s[t].level < o)
              break;
            if (m.single === d && s[t].level === o) {
              m = s[t];
              let p, g;
              d ? (p = u.md.options.quotes[2], g = u.md.options.quotes[3]) : (p = u.md.options.quotes[0], g = u.md.options.quotes[1]), r.content = iu(r.content, l.index, g), e[m.token].content = iu(
                e[m.token].content,
                m.pos,
                p
              ), c += g.length - 1, m.token === a && (c += p.length - 1), i = r.content, n = i.length, s.length = t;
              continue e;
            }
          }
        f ? s.push({
          token: a,
          pos: l.index,
          single: d,
          level: o
        }) : A && d && (r.content = iu(r.content, l.index, $t));
      }
  }
}
function ta(e) {
  if (e.md.options.typographer)
    for (let u = e.tokens.length - 1; u >= 0; u--)
      e.tokens[u].type !== "inline" || !ea.test(e.tokens[u].content) || ua(e.tokens[u].children, e);
}
function ra(e) {
  let u, t;
  const s = e.tokens, a = s.length;
  for (let r = 0; r < a; r++) {
    if (s[r].type !== "inline") continue;
    const o = s[r].children, i = o.length;
    for (u = 0; u < i; u++)
      o[u].type === "text_special" && (o[u].type = "text");
    for (u = t = 0; u < i; u++)
      o[u].type === "text" && u + 1 < i && o[u + 1].type === "text" ? o[u + 1].content = o[u].content + o[u + 1].content : (u !== t && (o[t] = o[u]), t++);
    u !== t && (o.length = t);
  }
}
const Nu = [
  ["normalize", Hi],
  ["block", qi],
  ["inline", Wi],
  ["linkify", Yi],
  ["replacements", $i],
  ["smartquotes", ta],
  // `text_join` finds `text_special` tokens (for escape sequences)
  // and joins them with the rest of the text
  ["text_join", ra]
];
function Tt() {
  this.ruler = new te();
  for (let e = 0; e < Nu.length; e++)
    this.ruler.push(Nu[e][0], Nu[e][1]);
}
Tt.prototype.process = function(e) {
  const u = this.ruler.getRules("");
  for (let t = 0, s = u.length; t < s; t++)
    u[t](e);
};
Tt.prototype.State = q0;
function ve(e, u, t, s) {
  this.src = e, this.md = u, this.env = t, this.tokens = s, this.bMarks = [], this.eMarks = [], this.tShift = [], this.sCount = [], this.bsCount = [], this.blkIndent = 0, this.line = 0, this.lineMax = 0, this.tight = !1, this.ddIndent = -1, this.listIndent = -1, this.parentType = "root", this.level = 0;
  const a = this.src;
  for (let r = 0, o = 0, i = 0, c = 0, n = a.length, l = !1; o < n; o++) {
    const f = a.charCodeAt(o);
    if (!l)
      if (V(f)) {
        i++, f === 9 ? c += 4 - c % 4 : c++;
        continue;
      } else
        l = !0;
    (f === 10 || o === n - 1) && (f !== 10 && o++, this.bMarks.push(r), this.eMarks.push(o), this.tShift.push(i), this.sCount.push(c), this.bsCount.push(0), l = !1, i = 0, c = 0, r = o + 1);
  }
  this.bMarks.push(a.length), this.eMarks.push(a.length), this.tShift.push(0), this.sCount.push(0), this.bsCount.push(0), this.lineMax = this.bMarks.length - 1;
}
ve.prototype.push = function(e, u, t) {
  const s = new me(e, u, t);
  return s.block = !0, t < 0 && this.level--, s.level = this.level, t > 0 && this.level++, this.tokens.push(s), s;
};
ve.prototype.isEmpty = function(u) {
  return this.bMarks[u] + this.tShift[u] >= this.eMarks[u];
};
ve.prototype.skipEmptyLines = function(u) {
  for (let t = this.lineMax; u < t && !(this.bMarks[u] + this.tShift[u] < this.eMarks[u]); u++)
    ;
  return u;
};
ve.prototype.skipSpaces = function(u) {
  for (let t = this.src.length; u < t; u++) {
    const s = this.src.charCodeAt(u);
    if (!V(s))
      break;
  }
  return u;
};
ve.prototype.skipSpacesBack = function(u, t) {
  if (u <= t)
    return u;
  for (; u > t; )
    if (!V(this.src.charCodeAt(--u)))
      return u + 1;
  return u;
};
ve.prototype.skipChars = function(u, t) {
  for (let s = this.src.length; u < s && this.src.charCodeAt(u) === t; u++)
    ;
  return u;
};
ve.prototype.skipCharsBack = function(u, t, s) {
  if (u <= s)
    return u;
  for (; u > s; )
    if (t !== this.src.charCodeAt(--u))
      return u + 1;
  return u;
};
ve.prototype.getLines = function(u, t, s, a) {
  if (u >= t)
    return "";
  const r = new Array(t - u);
  for (let o = 0, i = u; i < t; i++, o++) {
    let c = 0;
    const n = this.bMarks[i];
    let l = n, f;
    for (i + 1 < t || a ? f = this.eMarks[i] + 1 : f = this.eMarks[i]; l < f && c < s; ) {
      const A = this.src.charCodeAt(l);
      if (V(A))
        A === 9 ? c += 4 - (c + this.bsCount[i]) % 4 : c++;
      else if (l - n < this.tShift[i])
        c++;
      else
        break;
      l++;
    }
    c > s ? r[o] = new Array(c - s + 1).join(" ") + this.src.slice(l, f) : r[o] = this.src.slice(l, f);
  }
  return r.join("");
};
ve.prototype.Token = me;
const na = 65536;
function Mu(e, u) {
  const t = e.bMarks[u] + e.tShift[u], s = e.eMarks[u];
  return e.src.slice(t, s);
}
function er(e) {
  const u = [], t = e.length;
  let s = 0, a = e.charCodeAt(s), r = !1, o = 0, i = "";
  for (; s < t; )
    a === 124 && (r ? (i += e.substring(o, s - 1), o = s) : (u.push(i + e.substring(o, s)), i = "", o = s + 1)), r = a === 92, s++, a = e.charCodeAt(s);
  return u.push(i + e.substring(o)), u;
}
function ia(e, u, t, s) {
  if (u + 2 > t)
    return !1;
  let a = u + 1;
  if (e.sCount[a] < e.blkIndent || e.sCount[a] - e.blkIndent >= 4)
    return !1;
  let r = e.bMarks[a] + e.tShift[a];
  if (r >= e.eMarks[a])
    return !1;
  const o = e.src.charCodeAt(r++);
  if (o !== 124 && o !== 45 && o !== 58 || r >= e.eMarks[a])
    return !1;
  const i = e.src.charCodeAt(r++);
  if (i !== 124 && i !== 45 && i !== 58 && !V(i) || o === 45 && V(i))
    return !1;
  for (; r < e.eMarks[a]; ) {
    const m = e.src.charCodeAt(r);
    if (m !== 124 && m !== 45 && m !== 58 && !V(m))
      return !1;
    r++;
  }
  let c = Mu(e, u + 1), n = c.split("|");
  const l = [];
  for (let m = 0; m < n.length; m++) {
    const p = n[m].trim();
    if (!p) {
      if (m === 0 || m === n.length - 1)
        continue;
      return !1;
    }
    if (!/^:?-+:?$/.test(p))
      return !1;
    p.charCodeAt(p.length - 1) === 58 ? l.push(p.charCodeAt(0) === 58 ? "center" : "right") : p.charCodeAt(0) === 58 ? l.push("left") : l.push("");
  }
  if (c = Mu(e, u).trim(), c.indexOf("|") === -1 || e.sCount[u] - e.blkIndent >= 4)
    return !1;
  n = er(c), n.length && n[0] === "" && n.shift(), n.length && n[n.length - 1] === "" && n.pop();
  const f = n.length;
  if (f === 0 || f !== l.length)
    return !1;
  if (s)
    return !0;
  const A = e.parentType;
  e.parentType = "table";
  const d = e.md.block.ruler.getRules("blockquote"), h = e.push("table_open", "table", 1), y = [u, 0];
  h.map = y;
  const C = e.push("thead_open", "thead", 1);
  C.map = [u, u + 1];
  const w = e.push("tr_open", "tr", 1);
  w.map = [u, u + 1];
  for (let m = 0; m < n.length; m++) {
    const p = e.push("th_open", "th", 1);
    l[m] && (p.attrs = [["style", "text-align:" + l[m]]]);
    const g = e.push("inline", "", 0);
    g.content = n[m].trim(), g.children = [], e.push("th_close", "th", -1);
  }
  e.push("tr_close", "tr", -1), e.push("thead_close", "thead", -1);
  let b, x = 0;
  for (a = u + 2; a < t && !(e.sCount[a] < e.blkIndent); a++) {
    let m = !1;
    for (let g = 0, D = d.length; g < D; g++)
      if (d[g](e, a, t, !0)) {
        m = !0;
        break;
      }
    if (m || (c = Mu(e, a).trim(), !c) || e.sCount[a] - e.blkIndent >= 4 || (n = er(c), n.length && n[0] === "" && n.shift(), n.length && n[n.length - 1] === "" && n.pop(), x += f - n.length, x > na))
      break;
    if (a === u + 2) {
      const g = e.push("tbody_open", "tbody", 1);
      g.map = b = [u + 2, 0];
    }
    const p = e.push("tr_open", "tr", 1);
    p.map = [a, a + 1];
    for (let g = 0; g < f; g++) {
      const D = e.push("td_open", "td", 1);
      l[g] && (D.attrs = [["style", "text-align:" + l[g]]]);
      const B = e.push("inline", "", 0);
      B.content = n[g] ? n[g].trim() : "", B.children = [], e.push("td_close", "td", -1);
    }
    e.push("tr_close", "tr", -1);
  }
  return b && (e.push("tbody_close", "tbody", -1), b[1] = a), e.push("table_close", "table", -1), y[1] = a, e.parentType = A, e.line = a, !0;
}
function aa(e, u, t) {
  if (e.sCount[u] - e.blkIndent < 4)
    return !1;
  let s = u + 1, a = s;
  for (; s < t; ) {
    if (e.isEmpty(s)) {
      s++;
      continue;
    }
    if (e.sCount[s] - e.blkIndent >= 4) {
      s++, a = s;
      continue;
    }
    break;
  }
  e.line = a;
  const r = e.push("code_block", "code", 0);
  return r.content = e.getLines(u, a, 4 + e.blkIndent, !1) + `
`, r.map = [u, e.line], !0;
}
function sa(e, u, t, s) {
  let a = e.bMarks[u] + e.tShift[u], r = e.eMarks[u];
  if (e.sCount[u] - e.blkIndent >= 4 || a + 3 > r)
    return !1;
  const o = e.src.charCodeAt(a);
  if (o !== 126 && o !== 96)
    return !1;
  let i = a;
  a = e.skipChars(a, o);
  let c = a - i;
  if (c < 3)
    return !1;
  const n = e.src.slice(i, a), l = e.src.slice(a, r);
  if (o === 96 && l.indexOf(String.fromCharCode(o)) >= 0)
    return !1;
  if (s)
    return !0;
  let f = u, A = !1;
  for (; f++, !(f >= t || (a = i = e.bMarks[f] + e.tShift[f], r = e.eMarks[f], a < r && e.sCount[f] < e.blkIndent)); )
    if (e.src.charCodeAt(a) === o && !(e.sCount[f] - e.blkIndent >= 4) && (a = e.skipChars(a, o), !(a - i < c) && (a = e.skipSpaces(a), !(a < r)))) {
      A = !0;
      break;
    }
  c = e.sCount[u], e.line = f + (A ? 1 : 0);
  const d = e.push("fence", "code", 0);
  return d.info = l, d.content = e.getLines(u + 1, f, c, !0), d.markup = n, d.map = [u, e.line], !0;
}
function ca(e, u, t, s) {
  let a = e.bMarks[u] + e.tShift[u], r = e.eMarks[u];
  const o = e.lineMax;
  if (e.sCount[u] - e.blkIndent >= 4 || e.src.charCodeAt(a) !== 62)
    return !1;
  if (s)
    return !0;
  const i = [], c = [], n = [], l = [], f = e.md.block.ruler.getRules("blockquote"), A = e.parentType;
  e.parentType = "blockquote";
  let d = !1, h;
  for (h = u; h < t; h++) {
    const x = e.sCount[h] < e.blkIndent;
    if (a = e.bMarks[h] + e.tShift[h], r = e.eMarks[h], a >= r)
      break;
    if (e.src.charCodeAt(a++) === 62 && !x) {
      let p = e.sCount[h] + 1, g, D;
      e.src.charCodeAt(a) === 32 ? (a++, p++, D = !1, g = !0) : e.src.charCodeAt(a) === 9 ? (g = !0, (e.bsCount[h] + p) % 4 === 3 ? (a++, p++, D = !1) : D = !0) : g = !1;
      let B = p;
      for (i.push(e.bMarks[h]), e.bMarks[h] = a; a < r; ) {
        const E = e.src.charCodeAt(a);
        if (V(E))
          E === 9 ? B += 4 - (B + e.bsCount[h] + (D ? 1 : 0)) % 4 : B++;
        else
          break;
        a++;
      }
      d = a >= r, c.push(e.bsCount[h]), e.bsCount[h] = e.sCount[h] + 1 + (g ? 1 : 0), n.push(e.sCount[h]), e.sCount[h] = B - p, l.push(e.tShift[h]), e.tShift[h] = a - e.bMarks[h];
      continue;
    }
    if (d)
      break;
    let m = !1;
    for (let p = 0, g = f.length; p < g; p++)
      if (f[p](e, h, t, !0)) {
        m = !0;
        break;
      }
    if (m) {
      e.lineMax = h, e.blkIndent !== 0 && (i.push(e.bMarks[h]), c.push(e.bsCount[h]), l.push(e.tShift[h]), n.push(e.sCount[h]), e.sCount[h] -= e.blkIndent);
      break;
    }
    i.push(e.bMarks[h]), c.push(e.bsCount[h]), l.push(e.tShift[h]), n.push(e.sCount[h]), e.sCount[h] = -1;
  }
  const y = e.blkIndent;
  e.blkIndent = 0;
  const C = e.push("blockquote_open", "blockquote", 1);
  C.markup = ">";
  const w = [u, 0];
  C.map = w, e.md.block.tokenize(e, u, h);
  const b = e.push("blockquote_close", "blockquote", -1);
  b.markup = ">", e.lineMax = o, e.parentType = A, w[1] = e.line;
  for (let x = 0; x < l.length; x++)
    e.bMarks[x + u] = i[x], e.tShift[x + u] = l[x], e.sCount[x + u] = n[x], e.bsCount[x + u] = c[x];
  return e.blkIndent = y, !0;
}
function oa(e, u, t, s) {
  const a = e.eMarks[u];
  if (e.sCount[u] - e.blkIndent >= 4)
    return !1;
  let r = e.bMarks[u] + e.tShift[u];
  const o = e.src.charCodeAt(r++);
  if (o !== 42 && o !== 45 && o !== 95)
    return !1;
  let i = 1;
  for (; r < a; ) {
    const n = e.src.charCodeAt(r++);
    if (n !== o && !V(n))
      return !1;
    n === o && i++;
  }
  if (i < 3)
    return !1;
  if (s)
    return !0;
  e.line = u + 1;
  const c = e.push("hr", "hr", 0);
  return c.map = [u, e.line], c.markup = Array(i + 1).join(String.fromCharCode(o)), !0;
}
function ur(e, u) {
  const t = e.eMarks[u];
  let s = e.bMarks[u] + e.tShift[u];
  const a = e.src.charCodeAt(s++);
  if (a !== 42 && a !== 45 && a !== 43)
    return -1;
  if (s < t) {
    const r = e.src.charCodeAt(s);
    if (!V(r))
      return -1;
  }
  return s;
}
function tr(e, u) {
  const t = e.bMarks[u] + e.tShift[u], s = e.eMarks[u];
  let a = t;
  if (a + 1 >= s)
    return -1;
  let r = e.src.charCodeAt(a++);
  if (r < 48 || r > 57)
    return -1;
  for (; ; ) {
    if (a >= s)
      return -1;
    if (r = e.src.charCodeAt(a++), r >= 48 && r <= 57) {
      if (a - t >= 10)
        return -1;
      continue;
    }
    if (r === 41 || r === 46)
      break;
    return -1;
  }
  return a < s && (r = e.src.charCodeAt(a), !V(r)) ? -1 : a;
}
function la(e, u) {
  const t = e.level + 2;
  for (let s = u + 2, a = e.tokens.length - 2; s < a; s++)
    e.tokens[s].level === t && e.tokens[s].type === "paragraph_open" && (e.tokens[s + 2].hidden = !0, e.tokens[s].hidden = !0, s += 2);
}
function fa(e, u, t, s) {
  let a, r, o, i, c = u, n = !0;
  if (e.sCount[c] - e.blkIndent >= 4 || e.listIndent >= 0 && e.sCount[c] - e.listIndent >= 4 && e.sCount[c] < e.blkIndent)
    return !1;
  let l = !1;
  s && e.parentType === "paragraph" && e.sCount[c] >= e.blkIndent && (l = !0);
  let f, A, d;
  if ((d = tr(e, c)) >= 0) {
    if (f = !0, o = e.bMarks[c] + e.tShift[c], A = Number(e.src.slice(o, d - 1)), l && A !== 1) return !1;
  } else if ((d = ur(e, c)) >= 0)
    f = !1;
  else
    return !1;
  if (l && e.skipSpaces(d) >= e.eMarks[c])
    return !1;
  if (s)
    return !0;
  const h = e.src.charCodeAt(d - 1), y = e.tokens.length;
  f ? (i = e.push("ordered_list_open", "ol", 1), A !== 1 && (i.attrs = [["start", A]])) : i = e.push("bullet_list_open", "ul", 1);
  const C = [c, 0];
  i.map = C, i.markup = String.fromCharCode(h);
  let w = !1;
  const b = e.md.block.ruler.getRules("list"), x = e.parentType;
  for (e.parentType = "list"; c < t; ) {
    r = d, a = e.eMarks[c];
    const m = e.sCount[c] + d - (e.bMarks[c] + e.tShift[c]);
    let p = m;
    for (; r < a; ) {
      const I = e.src.charCodeAt(r);
      if (I === 9)
        p += 4 - (p + e.bsCount[c]) % 4;
      else if (I === 32)
        p++;
      else
        break;
      r++;
    }
    const g = r;
    let D;
    g >= a ? D = 1 : D = p - m, D > 4 && (D = 1);
    const B = m + D;
    i = e.push("list_item_open", "li", 1), i.markup = String.fromCharCode(h);
    const E = [c, 0];
    i.map = E, f && (i.info = e.src.slice(o, d - 1));
    const _ = e.tight, v = e.tShift[c], k = e.sCount[c], S = e.listIndent;
    if (e.listIndent = e.blkIndent, e.blkIndent = B, e.tight = !0, e.tShift[c] = g - e.bMarks[c], e.sCount[c] = p, g >= a && e.isEmpty(c + 1) ? e.line = Math.min(e.line + 2, t) : e.md.block.tokenize(e, c, t, !0), (!e.tight || w) && (n = !1), w = e.line - c > 1 && e.isEmpty(e.line - 1), e.blkIndent = e.listIndent, e.listIndent = S, e.tShift[c] = v, e.sCount[c] = k, e.tight = _, i = e.push("list_item_close", "li", -1), i.markup = String.fromCharCode(h), c = e.line, E[1] = c, c >= t || e.sCount[c] < e.blkIndent || e.sCount[c] - e.blkIndent >= 4)
      break;
    let F = !1;
    for (let I = 0, T = b.length; I < T; I++)
      if (b[I](e, c, t, !0)) {
        F = !0;
        break;
      }
    if (F)
      break;
    if (f) {
      if (d = tr(e, c), d < 0)
        break;
      o = e.bMarks[c] + e.tShift[c];
    } else if (d = ur(e, c), d < 0)
      break;
    if (h !== e.src.charCodeAt(d - 1))
      break;
  }
  return f ? i = e.push("ordered_list_close", "ol", -1) : i = e.push("bullet_list_close", "ul", -1), i.markup = String.fromCharCode(h), C[1] = c, e.line = c, e.parentType = x, n && la(e, y), !0;
}
function da(e, u, t, s) {
  let a = e.bMarks[u] + e.tShift[u], r = e.eMarks[u], o = u + 1;
  if (e.sCount[u] - e.blkIndent >= 4 || e.src.charCodeAt(a) !== 91)
    return !1;
  function i(b) {
    const x = e.lineMax;
    if (b >= x || e.isEmpty(b))
      return null;
    let m = !1;
    if (e.sCount[b] - e.blkIndent > 3 && (m = !0), e.sCount[b] < 0 && (m = !0), !m) {
      const D = e.md.block.ruler.getRules("reference"), B = e.parentType;
      e.parentType = "reference";
      let E = !1;
      for (let _ = 0, v = D.length; _ < v; _++)
        if (D[_](e, b, x, !0)) {
          E = !0;
          break;
        }
      if (e.parentType = B, E)
        return null;
    }
    const p = e.bMarks[b] + e.tShift[b], g = e.eMarks[b];
    return e.src.slice(p, g + 1);
  }
  let c = e.src.slice(a, r + 1);
  r = c.length;
  let n = -1;
  for (a = 1; a < r; a++) {
    const b = c.charCodeAt(a);
    if (b === 91)
      return !1;
    if (b === 93) {
      n = a;
      break;
    } else if (b === 10) {
      const x = i(o);
      x !== null && (c += x, r = c.length, o++);
    } else if (b === 92 && (a++, a < r && c.charCodeAt(a) === 10)) {
      const x = i(o);
      x !== null && (c += x, r = c.length, o++);
    }
  }
  if (n < 0 || c.charCodeAt(n + 1) !== 58)
    return !1;
  for (a = n + 2; a < r; a++) {
    const b = c.charCodeAt(a);
    if (b === 10) {
      const x = i(o);
      x !== null && (c += x, r = c.length, o++);
    } else if (!V(b)) break;
  }
  const l = e.md.helpers.parseLinkDestination(c, a, r);
  if (!l.ok)
    return !1;
  const f = e.md.normalizeLink(l.str);
  if (!e.md.validateLink(f))
    return !1;
  a = l.pos;
  const A = a, d = o, h = a;
  for (; a < r; a++) {
    const b = c.charCodeAt(a);
    if (b === 10) {
      const x = i(o);
      x !== null && (c += x, r = c.length, o++);
    } else if (!V(b)) break;
  }
  let y = e.md.helpers.parseLinkTitle(c, a, r);
  for (; y.can_continue; ) {
    const b = i(o);
    if (b === null) break;
    c += b, a = r, r = c.length, o++, y = e.md.helpers.parseLinkTitle(c, a, r, y);
  }
  let C;
  for (a < r && h !== a && y.ok ? (C = y.str, a = y.pos) : (C = "", a = A, o = d); a < r; ) {
    const b = c.charCodeAt(a);
    if (!V(b))
      break;
    a++;
  }
  if (a < r && c.charCodeAt(a) !== 10 && C)
    for (C = "", a = A, o = d; a < r; ) {
      const b = c.charCodeAt(a);
      if (!V(b))
        break;
      a++;
    }
  if (a < r && c.charCodeAt(a) !== 10)
    return !1;
  const w = Cu(c.slice(1, n));
  return w ? (s || (typeof e.env.references > "u" && (e.env.references = {}), typeof e.env.references[w] > "u" && (e.env.references[w] = { title: C, href: f }), e.line = o), !0) : !1;
}
const Aa = [
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
], ha = "[a-zA-Z_:][a-zA-Z0-9:._-]*", ba = "[^\"'=<>`\\x00-\\x20]+", pa = "'[^']*'", ga = '"[^"]*"', ma = "(?:" + ba + "|" + pa + "|" + ga + ")", xa = "(?:\\s+" + ha + "(?:\\s*=\\s*" + ma + ")?)", U0 = "<[A-Za-z][A-Za-z0-9\\-]*" + xa + "*\\s*\\/?>", K0 = "<\\/[A-Za-z][A-Za-z0-9\\-]*\\s*>", ya = "<!---?>|<!--(?:[^-]|-[^-]|--[^>])*-->", wa = "<[?][\\s\\S]*?[?]>", Ca = "<![A-Za-z][^>]*>", va = "<!\\[CDATA\\[[\\s\\S]*?\\]\\]>", Da = new RegExp("^(?:" + U0 + "|" + K0 + "|" + ya + "|" + wa + "|" + Ca + "|" + va + ")"), Ea = new RegExp("^(?:" + U0 + "|" + K0 + ")"), Ge = [
  [/^<(script|pre|style|textarea)(?=(\s|>|$))/i, /<\/(script|pre|style|textarea)>/i, !0],
  [/^<!--/, /-->/, !0],
  [/^<\?/, /\?>/, !0],
  [/^<![A-Z]/, />/, !0],
  [/^<!\[CDATA\[/, /\]\]>/, !0],
  [new RegExp("^</?(" + Aa.join("|") + ")(?=(\\s|/?>|$))", "i"), /^$/, !0],
  [new RegExp(Ea.source + "\\s*$"), /^$/, !1]
];
function _a(e, u, t, s) {
  let a = e.bMarks[u] + e.tShift[u], r = e.eMarks[u];
  if (e.sCount[u] - e.blkIndent >= 4 || !e.md.options.html || e.src.charCodeAt(a) !== 60)
    return !1;
  let o = e.src.slice(a, r), i = 0;
  for (; i < Ge.length && !Ge[i][0].test(o); i++)
    ;
  if (i === Ge.length)
    return !1;
  if (s)
    return Ge[i][2];
  let c = u + 1;
  if (!Ge[i][1].test(o)) {
    for (; c < t && !(e.sCount[c] < e.blkIndent); c++)
      if (a = e.bMarks[c] + e.tShift[c], r = e.eMarks[c], o = e.src.slice(a, r), Ge[i][1].test(o)) {
        o.length !== 0 && c++;
        break;
      }
  }
  e.line = c;
  const n = e.push("html_block", "", 0);
  return n.map = [u, c], n.content = e.getLines(u, c, e.blkIndent, !0), !0;
}
function Ia(e, u, t, s) {
  let a = e.bMarks[u] + e.tShift[u], r = e.eMarks[u];
  if (e.sCount[u] - e.blkIndent >= 4)
    return !1;
  let o = e.src.charCodeAt(a);
  if (o !== 35 || a >= r)
    return !1;
  let i = 1;
  for (o = e.src.charCodeAt(++a); o === 35 && a < r && i <= 6; )
    i++, o = e.src.charCodeAt(++a);
  if (i > 6 || a < r && !V(o))
    return !1;
  if (s)
    return !0;
  r = e.skipSpacesBack(r, a);
  const c = e.skipCharsBack(r, 35, a);
  c > a && V(e.src.charCodeAt(c - 1)) && (r = c), e.line = u + 1;
  const n = e.push("heading_open", "h" + String(i), 1);
  n.markup = "########".slice(0, i), n.map = [u, e.line];
  const l = e.push("inline", "", 0);
  l.content = e.src.slice(a, r).trim(), l.map = [u, e.line], l.children = [];
  const f = e.push("heading_close", "h" + String(i), -1);
  return f.markup = "########".slice(0, i), !0;
}
function ka(e, u, t) {
  const s = e.md.block.ruler.getRules("paragraph");
  if (e.sCount[u] - e.blkIndent >= 4)
    return !1;
  const a = e.parentType;
  e.parentType = "paragraph";
  let r = 0, o, i = u + 1;
  for (; i < t && !e.isEmpty(i); i++) {
    if (e.sCount[i] - e.blkIndent > 3)
      continue;
    if (e.sCount[i] >= e.blkIndent) {
      let d = e.bMarks[i] + e.tShift[i];
      const h = e.eMarks[i];
      if (d < h && (o = e.src.charCodeAt(d), (o === 45 || o === 61) && (d = e.skipChars(d, o), d = e.skipSpaces(d), d >= h))) {
        r = o === 61 ? 1 : 2;
        break;
      }
    }
    if (e.sCount[i] < 0)
      continue;
    let A = !1;
    for (let d = 0, h = s.length; d < h; d++)
      if (s[d](e, i, t, !0)) {
        A = !0;
        break;
      }
    if (A)
      break;
  }
  if (!r)
    return !1;
  const c = e.getLines(u, i, e.blkIndent, !1).trim();
  e.line = i + 1;
  const n = e.push("heading_open", "h" + String(r), 1);
  n.markup = String.fromCharCode(o), n.map = [u, e.line];
  const l = e.push("inline", "", 0);
  l.content = c, l.map = [u, e.line - 1], l.children = [];
  const f = e.push("heading_close", "h" + String(r), -1);
  return f.markup = String.fromCharCode(o), e.parentType = a, !0;
}
function Ba(e, u, t) {
  const s = e.md.block.ruler.getRules("paragraph"), a = e.parentType;
  let r = u + 1;
  for (e.parentType = "paragraph"; r < t && !e.isEmpty(r); r++) {
    if (e.sCount[r] - e.blkIndent > 3 || e.sCount[r] < 0)
      continue;
    let n = !1;
    for (let l = 0, f = s.length; l < f; l++)
      if (s[l](e, r, t, !0)) {
        n = !0;
        break;
      }
    if (n)
      break;
  }
  const o = e.getLines(u, r, e.blkIndent, !1).trim();
  e.line = r;
  const i = e.push("paragraph_open", "p", 1);
  i.map = [u, e.line];
  const c = e.push("inline", "", 0);
  return c.content = o, c.map = [u, e.line], c.children = [], e.push("paragraph_close", "p", -1), e.parentType = a, !0;
}
const au = [
  // First 2 params - rule name & source. Secondary array - list of rules,
  // which can be terminated by this one.
  ["table", ia, ["paragraph", "reference"]],
  ["code", aa],
  ["fence", sa, ["paragraph", "reference", "blockquote", "list"]],
  ["blockquote", ca, ["paragraph", "reference", "blockquote", "list"]],
  ["hr", oa, ["paragraph", "reference", "blockquote", "list"]],
  ["list", fa, ["paragraph", "reference", "blockquote"]],
  ["reference", da],
  ["html_block", _a, ["paragraph", "reference", "blockquote"]],
  ["heading", Ia, ["paragraph", "reference", "blockquote"]],
  ["lheading", ka],
  ["paragraph", Ba]
];
function vu() {
  this.ruler = new te();
  for (let e = 0; e < au.length; e++)
    this.ruler.push(au[e][0], au[e][1], { alt: (au[e][2] || []).slice() });
}
vu.prototype.tokenize = function(e, u, t) {
  const s = this.ruler.getRules(""), a = s.length, r = e.md.options.maxNesting;
  let o = u, i = !1;
  for (; o < t && (e.line = o = e.skipEmptyLines(o), !(o >= t || e.sCount[o] < e.blkIndent)); ) {
    if (e.level >= r) {
      e.line = t;
      break;
    }
    const c = e.line;
    let n = !1;
    for (let l = 0; l < a; l++)
      if (n = s[l](e, o, t, !1), n) {
        if (c >= e.line)
          throw new Error("block rule didn't increment state.line");
        break;
      }
    if (!n) throw new Error("none of the block rules matched");
    e.tight = !i, e.isEmpty(e.line - 1) && (i = !0), o = e.line, o < t && e.isEmpty(o) && (i = !0, o++, e.line = o);
  }
};
vu.prototype.parse = function(e, u, t, s) {
  if (!e)
    return;
  const a = new this.State(e, u, t, s);
  this.tokenize(a, a.line, a.lineMax);
};
vu.prototype.State = ve;
function eu(e, u, t, s) {
  this.src = e, this.env = t, this.md = u, this.tokens = s, this.tokens_meta = Array(s.length), this.pos = 0, this.posMax = this.src.length, this.level = 0, this.pending = "", this.pendingLevel = 0, this.cache = {}, this.delimiters = [], this._prev_delimiters = [], this.backticks = {}, this.backticksScanned = !1, this.linkLevel = 0;
}
eu.prototype.pushPending = function() {
  const e = new me("text", "", 0);
  return e.content = this.pending, e.level = this.pendingLevel, this.tokens.push(e), this.pending = "", e;
};
eu.prototype.push = function(e, u, t) {
  this.pending && this.pushPending();
  const s = new me(e, u, t);
  let a = null;
  return t < 0 && (this.level--, this.delimiters = this._prev_delimiters.pop()), s.level = this.level, t > 0 && (this.level++, this._prev_delimiters.push(this.delimiters), this.delimiters = [], a = { delimiters: this.delimiters }), this.pendingLevel = this.level, this.tokens.push(s), this.tokens_meta.push(a), s;
};
eu.prototype.scanDelims = function(e, u) {
  const t = this.posMax, s = this.src.charCodeAt(e), a = e > 0 ? this.src.charCodeAt(e - 1) : 32;
  let r = e;
  for (; r < t && this.src.charCodeAt(r) === s; )
    r++;
  const o = r - e, i = r < t ? this.src.charCodeAt(r) : 32, c = ze(a) || Ve(String.fromCharCode(a)), n = ze(i) || Ve(String.fromCharCode(i)), l = Ze(a), f = Ze(i), A = !f && (!n || l || c), d = !l && (!c || f || n);
  return { can_open: A && (u || !d || c), can_close: d && (u || !A || n), length: o };
};
eu.prototype.Token = me;
function Fa(e) {
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
function Sa(e, u) {
  let t = e.pos;
  for (; t < e.posMax && !Fa(e.src.charCodeAt(t)); )
    t++;
  return t === e.pos ? !1 : (u || (e.pending += e.src.slice(e.pos, t)), e.pos = t, !0);
}
const Ta = /(?:^|[^a-z0-9.+-])([a-z][a-z0-9.+-]*)$/i;
function Ra(e, u) {
  if (!e.md.options.linkify || e.linkLevel > 0) return !1;
  const t = e.pos, s = e.posMax;
  if (t + 3 > s || e.src.charCodeAt(t) !== 58 || e.src.charCodeAt(t + 1) !== 47 || e.src.charCodeAt(t + 2) !== 47) return !1;
  const a = e.pending.match(Ta);
  if (!a) return !1;
  const r = a[1], o = e.md.linkify.matchAtStart(e.src.slice(t - r.length));
  if (!o) return !1;
  let i = o.url;
  if (i.length <= r.length) return !1;
  let c = i.length;
  for (; c > 0 && i.charCodeAt(c - 1) === 42; )
    c--;
  c !== i.length && (i = i.slice(0, c));
  const n = e.md.normalizeLink(i);
  if (!e.md.validateLink(n)) return !1;
  if (!u) {
    e.pending = e.pending.slice(0, -r.length);
    const l = e.push("link_open", "a", 1);
    l.attrs = [["href", n]], l.markup = "linkify", l.info = "auto";
    const f = e.push("text", "", 0);
    f.content = e.md.normalizeLinkText(i);
    const A = e.push("link_close", "a", -1);
    A.markup = "linkify", A.info = "auto";
  }
  return e.pos += i.length - r.length, !0;
}
function Na(e, u) {
  let t = e.pos;
  if (e.src.charCodeAt(t) !== 10)
    return !1;
  const s = e.pending.length - 1, a = e.posMax;
  if (!u)
    if (s >= 0 && e.pending.charCodeAt(s) === 32)
      if (s >= 1 && e.pending.charCodeAt(s - 1) === 32) {
        let r = s - 1;
        for (; r >= 1 && e.pending.charCodeAt(r - 1) === 32; ) r--;
        e.pending = e.pending.slice(0, r), e.push("hardbreak", "br", 0);
      } else
        e.pending = e.pending.slice(0, -1), e.push("softbreak", "br", 0);
    else
      e.push("softbreak", "br", 0);
  for (t++; t < a && V(e.src.charCodeAt(t)); )
    t++;
  return e.pos = t, !0;
}
const Rt = [];
for (let e = 0; e < 256; e++)
  Rt.push(0);
"\\!\"#$%&'()*+,./:;<=>?@[]^_`{|}~-".split("").forEach(function(e) {
  Rt[e.charCodeAt(0)] = 1;
});
function Ma(e, u) {
  let t = e.pos;
  const s = e.posMax;
  if (e.src.charCodeAt(t) !== 92 || (t++, t >= s)) return !1;
  let a = e.src.charCodeAt(t);
  if (a === 10) {
    for (u || e.push("hardbreak", "br", 0), t++; t < s && (a = e.src.charCodeAt(t), !!V(a)); )
      t++;
    return e.pos = t, !0;
  }
  let r = e.src[t];
  if (a >= 55296 && a <= 56319 && t + 1 < s) {
    const i = e.src.charCodeAt(t + 1);
    i >= 56320 && i <= 57343 && (r += e.src[t + 1], t++);
  }
  const o = "\\" + r;
  if (!u) {
    const i = e.push("text_special", "", 0);
    a < 256 && Rt[a] !== 0 ? i.content = r : i.content = o, i.markup = o, i.info = "escape";
  }
  return e.pos = t + 1, !0;
}
function Oa(e, u) {
  let t = e.pos;
  if (e.src.charCodeAt(t) !== 96)
    return !1;
  const a = t;
  t++;
  const r = e.posMax;
  for (; t < r && e.src.charCodeAt(t) === 96; )
    t++;
  const o = e.src.slice(a, t), i = o.length;
  if (e.backticksScanned && (e.backticks[i] || 0) <= a)
    return u || (e.pending += o), e.pos += i, !0;
  let c = t, n;
  for (; (n = e.src.indexOf("`", c)) !== -1; ) {
    for (c = n + 1; c < r && e.src.charCodeAt(c) === 96; )
      c++;
    const l = c - n;
    if (l === i) {
      if (!u) {
        const f = e.push("code_inline", "code", 0);
        f.markup = o, f.content = e.src.slice(t, n).replace(/\n/g, " ").replace(/^ (.+) $/, "$1");
      }
      return e.pos = c, !0;
    }
    e.backticks[l] = n;
  }
  return e.backticksScanned = !0, u || (e.pending += o), e.pos += i, !0;
}
function Qa(e, u) {
  const t = e.pos, s = e.src.charCodeAt(t);
  if (u || s !== 126)
    return !1;
  const a = e.scanDelims(e.pos, !0);
  let r = a.length;
  const o = String.fromCharCode(s);
  if (r < 2)
    return !1;
  let i;
  r % 2 && (i = e.push("text", "", 0), i.content = o, r--);
  for (let c = 0; c < r; c += 2)
    i = e.push("text", "", 0), i.content = o + o, e.delimiters.push({
      marker: s,
      length: 0,
      // disable "rule of 3" length checks meant for emphasis
      token: e.tokens.length - 1,
      end: -1,
      open: a.can_open,
      close: a.can_close
    });
  return e.pos += a.length, !0;
}
function rr(e, u) {
  let t;
  const s = [], a = u.length;
  for (let r = 0; r < a; r++) {
    const o = u[r];
    if (o.marker !== 126 || o.end === -1)
      continue;
    const i = u[o.end];
    t = e.tokens[o.token], t.type = "s_open", t.tag = "s", t.nesting = 1, t.markup = "~~", t.content = "", t = e.tokens[i.token], t.type = "s_close", t.tag = "s", t.nesting = -1, t.markup = "~~", t.content = "", e.tokens[i.token - 1].type === "text" && e.tokens[i.token - 1].content === "~" && s.push(i.token - 1);
  }
  for (; s.length; ) {
    const r = s.pop();
    let o = r + 1;
    for (; o < e.tokens.length && e.tokens[o].type === "s_close"; )
      o++;
    o--, r !== o && (t = e.tokens[o], e.tokens[o] = e.tokens[r], e.tokens[r] = t);
  }
}
function La(e) {
  const u = e.tokens_meta, t = e.tokens_meta.length;
  rr(e, e.delimiters);
  for (let s = 0; s < t; s++)
    u[s] && u[s].delimiters && rr(e, u[s].delimiters);
}
const Y0 = {
  tokenize: Qa,
  postProcess: La
};
function Pa(e, u) {
  const t = e.pos, s = e.src.charCodeAt(t);
  if (u || s !== 95 && s !== 42)
    return !1;
  const a = e.scanDelims(e.pos, s === 42);
  for (let r = 0; r < a.length; r++) {
    const o = e.push("text", "", 0);
    o.content = String.fromCharCode(s), e.delimiters.push({
      // Char code of the starting marker (number).
      //
      marker: s,
      // Total length of these series of delimiters.
      //
      length: a.length,
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
      open: a.can_open,
      close: a.can_close
    });
  }
  return e.pos += a.length, !0;
}
function nr(e, u) {
  const t = u.length;
  for (let s = t - 1; s >= 0; s--) {
    const a = u[s];
    if (a.marker !== 95 && a.marker !== 42 || a.end === -1)
      continue;
    const r = u[a.end], o = s > 0 && u[s - 1].end === a.end + 1 && // check that first two markers match and adjacent
    u[s - 1].marker === a.marker && u[s - 1].token === a.token - 1 && // check that last two markers are adjacent (we can safely assume they match)
    u[a.end + 1].token === r.token + 1, i = String.fromCharCode(a.marker), c = e.tokens[a.token];
    c.type = o ? "strong_open" : "em_open", c.tag = o ? "strong" : "em", c.nesting = 1, c.markup = o ? i + i : i, c.content = "";
    const n = e.tokens[r.token];
    n.type = o ? "strong_close" : "em_close", n.tag = o ? "strong" : "em", n.nesting = -1, n.markup = o ? i + i : i, n.content = "", o && (e.tokens[u[s - 1].token].content = "", e.tokens[u[a.end + 1].token].content = "", s--);
  }
}
function Ga(e) {
  const u = e.tokens_meta, t = e.tokens_meta.length;
  nr(e, e.delimiters);
  for (let s = 0; s < t; s++)
    u[s] && u[s].delimiters && nr(e, u[s].delimiters);
}
const j0 = {
  tokenize: Pa,
  postProcess: Ga
};
function Ha(e, u) {
  let t, s, a, r, o = "", i = "", c = e.pos, n = !0;
  if (e.src.charCodeAt(e.pos) !== 91)
    return !1;
  const l = e.pos, f = e.posMax, A = e.pos + 1, d = e.md.helpers.parseLinkLabel(e, e.pos, !0);
  if (d < 0)
    return !1;
  let h = d + 1;
  if (h < f && e.src.charCodeAt(h) === 40) {
    for (n = !1, h++; h < f && (t = e.src.charCodeAt(h), !(!V(t) && t !== 10)); h++)
      ;
    if (h >= f)
      return !1;
    if (c = h, a = e.md.helpers.parseLinkDestination(e.src, h, e.posMax), a.ok) {
      for (o = e.md.normalizeLink(a.str), e.md.validateLink(o) ? h = a.pos : o = "", c = h; h < f && (t = e.src.charCodeAt(h), !(!V(t) && t !== 10)); h++)
        ;
      if (a = e.md.helpers.parseLinkTitle(e.src, h, e.posMax), h < f && c !== h && a.ok)
        for (i = a.str, h = a.pos; h < f && (t = e.src.charCodeAt(h), !(!V(t) && t !== 10)); h++)
          ;
    }
    (h >= f || e.src.charCodeAt(h) !== 41) && (n = !0), h++;
  }
  if (n) {
    if (typeof e.env.references > "u")
      return !1;
    if (h < f && e.src.charCodeAt(h) === 91 ? (c = h + 1, h = e.md.helpers.parseLinkLabel(e, h), h >= 0 ? s = e.src.slice(c, h++) : h = d + 1) : h = d + 1, s || (s = e.src.slice(A, d)), r = e.env.references[Cu(s)], !r)
      return e.pos = l, !1;
    o = r.href, i = r.title;
  }
  if (!u) {
    e.pos = A, e.posMax = d;
    const y = e.push("link_open", "a", 1), C = [["href", o]];
    y.attrs = C, i && C.push(["title", i]), e.linkLevel++, e.md.inline.tokenize(e), e.linkLevel--, e.push("link_close", "a", -1);
  }
  return e.pos = h, e.posMax = f, !0;
}
function qa(e, u) {
  let t, s, a, r, o, i, c, n, l = "";
  const f = e.pos, A = e.posMax;
  if (e.src.charCodeAt(e.pos) !== 33 || e.src.charCodeAt(e.pos + 1) !== 91)
    return !1;
  const d = e.pos + 2, h = e.md.helpers.parseLinkLabel(e, e.pos + 1, !1);
  if (h < 0)
    return !1;
  if (r = h + 1, r < A && e.src.charCodeAt(r) === 40) {
    for (r++; r < A && (t = e.src.charCodeAt(r), !(!V(t) && t !== 10)); r++)
      ;
    if (r >= A)
      return !1;
    for (n = r, i = e.md.helpers.parseLinkDestination(e.src, r, e.posMax), i.ok && (l = e.md.normalizeLink(i.str), e.md.validateLink(l) ? r = i.pos : l = ""), n = r; r < A && (t = e.src.charCodeAt(r), !(!V(t) && t !== 10)); r++)
      ;
    if (i = e.md.helpers.parseLinkTitle(e.src, r, e.posMax), r < A && n !== r && i.ok)
      for (c = i.str, r = i.pos; r < A && (t = e.src.charCodeAt(r), !(!V(t) && t !== 10)); r++)
        ;
    else
      c = "";
    if (r >= A || e.src.charCodeAt(r) !== 41)
      return e.pos = f, !1;
    r++;
  } else {
    if (typeof e.env.references > "u")
      return !1;
    if (r < A && e.src.charCodeAt(r) === 91 ? (n = r + 1, r = e.md.helpers.parseLinkLabel(e, r), r >= 0 ? a = e.src.slice(n, r++) : r = h + 1) : r = h + 1, a || (a = e.src.slice(d, h)), o = e.env.references[Cu(a)], !o)
      return e.pos = f, !1;
    l = o.href, c = o.title;
  }
  if (!u) {
    s = e.src.slice(d, h);
    const y = [];
    e.md.inline.parse(
      s,
      e.md,
      e.env,
      y
    );
    const C = e.push("image", "img", 0), w = [["src", l], ["alt", ""]];
    C.attrs = w, C.children = y, C.content = s, c && w.push(["title", c]);
  }
  return e.pos = r, e.posMax = A, !0;
}
const Wa = /^([a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*)$/, Ua = /^([a-zA-Z][a-zA-Z0-9+.-]{1,31}):([^<>\x00-\x20]*)$/;
function Ka(e, u) {
  let t = e.pos;
  if (e.src.charCodeAt(t) !== 60)
    return !1;
  const s = e.pos, a = e.posMax;
  for (; ; ) {
    if (++t >= a) return !1;
    const o = e.src.charCodeAt(t);
    if (o === 60) return !1;
    if (o === 62) break;
  }
  const r = e.src.slice(s + 1, t);
  if (Ua.test(r)) {
    const o = e.md.normalizeLink(r);
    if (!e.md.validateLink(o))
      return !1;
    if (!u) {
      const i = e.push("link_open", "a", 1);
      i.attrs = [["href", o]], i.markup = "autolink", i.info = "auto";
      const c = e.push("text", "", 0);
      c.content = e.md.normalizeLinkText(r);
      const n = e.push("link_close", "a", -1);
      n.markup = "autolink", n.info = "auto";
    }
    return e.pos += r.length + 2, !0;
  }
  if (Wa.test(r)) {
    const o = e.md.normalizeLink("mailto:" + r);
    if (!e.md.validateLink(o))
      return !1;
    if (!u) {
      const i = e.push("link_open", "a", 1);
      i.attrs = [["href", o]], i.markup = "autolink", i.info = "auto";
      const c = e.push("text", "", 0);
      c.content = e.md.normalizeLinkText(r);
      const n = e.push("link_close", "a", -1);
      n.markup = "autolink", n.info = "auto";
    }
    return e.pos += r.length + 2, !0;
  }
  return !1;
}
function Ya(e) {
  return /^<a[>\s]/i.test(e);
}
function ja(e) {
  return /^<\/a\s*>/i.test(e);
}
function Ja(e) {
  const u = e | 32;
  return u >= 97 && u <= 122;
}
function Za(e, u) {
  if (!e.md.options.html)
    return !1;
  const t = e.posMax, s = e.pos;
  if (e.src.charCodeAt(s) !== 60 || s + 2 >= t)
    return !1;
  const a = e.src.charCodeAt(s + 1);
  if (a !== 33 && a !== 63 && a !== 47 && !Ja(a))
    return !1;
  const r = e.src.slice(s).match(Da);
  if (!r)
    return !1;
  if (!u) {
    const o = e.push("html_inline", "", 0);
    o.content = r[0], Ya(o.content) && e.linkLevel++, ja(o.content) && e.linkLevel--;
  }
  return e.pos += r[0].length, !0;
}
const Va = /^&#((?:x[a-f0-9]{1,6}|[0-9]{1,7}));/i, za = /^&([a-z][a-z0-9]{1,31});/i;
function Xa(e, u) {
  const t = e.pos, s = e.posMax;
  if (e.src.charCodeAt(t) !== 38 || t + 1 >= s) return !1;
  if (e.src.charCodeAt(t + 1) === 35) {
    const r = e.src.slice(t).match(Va);
    if (r) {
      if (!u) {
        const o = r[1][0].toLowerCase() === "x" ? parseInt(r[1].slice(1), 16) : parseInt(r[1], 10), i = e.push("text_special", "", 0);
        i.content = St(o) ? xu(o) : xu(65533), i.markup = r[0], i.info = "entity";
      }
      return e.pos += r[0].length, !0;
    }
  } else {
    const r = e.src.slice(t).match(za);
    if (r) {
      const o = P0(r[0]);
      if (o !== r[0]) {
        if (!u) {
          const i = e.push("text_special", "", 0);
          i.content = o, i.markup = r[0], i.info = "entity";
        }
        return e.pos += r[0].length, !0;
      }
    }
  }
  return !1;
}
function ir(e) {
  const u = {}, t = e.length;
  if (!t) return;
  let s = 0, a = -2;
  const r = [];
  for (let o = 0; o < t; o++) {
    const i = e[o];
    if (r.push(0), (e[s].marker !== i.marker || a !== i.token - 1) && (s = o), a = i.token, i.length = i.length || 0, !i.close) continue;
    u.hasOwnProperty(i.marker) || (u[i.marker] = [-1, -1, -1, -1, -1, -1]);
    const c = u[i.marker][(i.open ? 3 : 0) + i.length % 3];
    let n = s - r[s] - 1, l = n;
    for (; n > c; n -= r[n] + 1) {
      const f = e[n];
      if (f.marker === i.marker && f.open && f.end < 0) {
        let A = !1;
        if ((f.close || i.open) && (f.length + i.length) % 3 === 0 && (f.length % 3 !== 0 || i.length % 3 !== 0) && (A = !0), !A) {
          const d = n > 0 && !e[n - 1].open ? r[n - 1] + 1 : 0;
          r[o] = o - n + d, r[n] = d, i.open = !1, f.end = o, f.close = !1, l = -1, a = -2;
          break;
        }
      }
    }
    l !== -1 && (u[i.marker][(i.open ? 3 : 0) + (i.length || 0) % 3] = l);
  }
}
function $a(e) {
  const u = e.tokens_meta, t = e.tokens_meta.length;
  ir(e.delimiters);
  for (let s = 0; s < t; s++)
    u[s] && u[s].delimiters && ir(u[s].delimiters);
}
function es(e) {
  let u, t, s = 0;
  const a = e.tokens, r = e.tokens.length;
  for (u = t = 0; u < r; u++)
    a[u].nesting < 0 && s--, a[u].level = s, a[u].nesting > 0 && s++, a[u].type === "text" && u + 1 < r && a[u + 1].type === "text" ? a[u + 1].content = a[u].content + a[u + 1].content : (u !== t && (a[t] = a[u]), t++);
  u !== t && (a.length = t);
}
const Ou = [
  ["text", Sa],
  ["linkify", Ra],
  ["newline", Na],
  ["escape", Ma],
  ["backticks", Oa],
  ["strikethrough", Y0.tokenize],
  ["emphasis", j0.tokenize],
  ["link", Ha],
  ["image", qa],
  ["autolink", Ka],
  ["html_inline", Za],
  ["entity", Xa]
], Qu = [
  ["balance_pairs", $a],
  ["strikethrough", Y0.postProcess],
  ["emphasis", j0.postProcess],
  // rules for pairs separate '**' into its own text tokens, which may be left unused,
  // rule below merges unused segments back with the rest of the text
  ["fragments_join", es]
];
function uu() {
  this.ruler = new te();
  for (let e = 0; e < Ou.length; e++)
    this.ruler.push(Ou[e][0], Ou[e][1]);
  this.ruler2 = new te();
  for (let e = 0; e < Qu.length; e++)
    this.ruler2.push(Qu[e][0], Qu[e][1]);
}
uu.prototype.skipToken = function(e) {
  const u = e.pos, t = this.ruler.getRules(""), s = t.length, a = e.md.options.maxNesting, r = e.cache;
  if (typeof r[u] < "u") {
    e.pos = r[u];
    return;
  }
  let o = !1;
  if (e.level < a) {
    for (let i = 0; i < s; i++)
      if (e.level++, o = t[i](e, !0), e.level--, o) {
        if (u >= e.pos)
          throw new Error("inline rule didn't increment state.pos");
        break;
      }
  } else
    e.pos = e.posMax;
  o || e.pos++, r[u] = e.pos;
};
uu.prototype.tokenize = function(e) {
  const u = this.ruler.getRules(""), t = u.length, s = e.posMax, a = e.md.options.maxNesting;
  for (; e.pos < s; ) {
    const r = e.pos;
    let o = !1;
    if (e.level < a) {
      for (let i = 0; i < t; i++)
        if (o = u[i](e, !1), o) {
          if (r >= e.pos)
            throw new Error("inline rule didn't increment state.pos");
          break;
        }
    }
    if (o) {
      if (e.pos >= s)
        break;
      continue;
    }
    e.pending += e.src[e.pos++];
  }
  e.pending && e.pushPending();
};
uu.prototype.parse = function(e, u, t, s) {
  const a = new this.State(e, u, t, s);
  this.tokenize(a);
  const r = this.ruler2.getRules(""), o = r.length;
  for (let i = 0; i < o; i++)
    r[i](a);
};
uu.prototype.State = eu;
function us(e) {
  const u = {};
  e = e || {}, u.src_Any = N0.source, u.src_Cc = M0.source, u.src_Z = Q0.source, u.src_P = Bt.source, u.src_ZPCc = [u.src_Z, u.src_P, u.src_Cc].join("|"), u.src_ZCc = [u.src_Z, u.src_Cc].join("|");
  const t = "[><｜]";
  return u.src_pseudo_letter = "(?:(?!" + t + "|" + u.src_ZPCc + ")" + u.src_Any + ")", u.src_ip4 = "(?:(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)", u.src_auth = "(?:(?:(?!" + u.src_ZCc + "|[@/\\[\\]()]).)+@)?", u.src_port = "(?::(?:6(?:[0-4]\\d{3}|5(?:[0-4]\\d{2}|5(?:[0-2]\\d|3[0-5])))|[1-5]?\\d{1,4}))?", u.src_host_terminator = "(?=$|" + t + "|" + u.src_ZPCc + ")(?!" + (e["---"] ? "-(?!--)|" : "-|") + "_|:\\d|\\.-|\\.(?!$|" + u.src_ZPCc + "))", u.src_path = "(?:[/?#](?:(?!" + u.src_ZCc + "|" + t + `|[()[\\]{}.,"'?!\\-;]).|\\[(?:(?!` + u.src_ZCc + "|\\]).)*\\]|\\((?:(?!" + u.src_ZCc + "|[)]).)*\\)|\\{(?:(?!" + u.src_ZCc + '|[}]).)*\\}|\\"(?:(?!' + u.src_ZCc + `|["]).)+\\"|\\'(?:(?!` + u.src_ZCc + "|[']).)+\\'|\\'(?=" + u.src_pseudo_letter + "|[-])|\\.{2,}[a-zA-Z0-9%/&]|\\.(?!" + u.src_ZCc + "|[.]|$)|" + (e["---"] ? "\\-(?!--(?:[^-]|$))(?:-*)|" : "\\-+|") + // allow `,,,` in paths
  ",(?!" + u.src_ZCc + "|$)|;(?!" + u.src_ZCc + "|$)|\\!+(?!" + u.src_ZCc + "|[!]|$)|\\?(?!" + u.src_ZCc + "|[?]|$))+|\\/)?", u.src_email_name = '[\\-;:&=\\+\\$,\\.a-zA-Z0-9_][\\-;:&=\\+\\$,\\"\\.a-zA-Z0-9_]*', u.src_xn = "xn--[a-z0-9\\-]{1,59}", u.src_domain_root = // Allow letters & digits (http://test1)
  "(?:" + u.src_xn + "|" + u.src_pseudo_letter + "{1,63})", u.src_domain = "(?:" + u.src_xn + "|(?:" + u.src_pseudo_letter + ")|(?:" + u.src_pseudo_letter + "(?:-|" + u.src_pseudo_letter + "){0,61}" + u.src_pseudo_letter + "))", u.src_host = "(?:(?:(?:(?:" + u.src_domain + ")\\.)*" + u.src_domain + "))", u.tpl_host_fuzzy = "(?:" + u.src_ip4 + "|(?:(?:(?:" + u.src_domain + ")\\.)+(?:%TLDS%)))", u.tpl_host_no_ip_fuzzy = "(?:(?:(?:" + u.src_domain + ")\\.)+(?:%TLDS%))", u.src_host_strict = u.src_host + u.src_host_terminator, u.tpl_host_fuzzy_strict = u.tpl_host_fuzzy + u.src_host_terminator, u.src_host_port_strict = u.src_host + u.src_port + u.src_host_terminator, u.tpl_host_port_fuzzy_strict = u.tpl_host_fuzzy + u.src_port + u.src_host_terminator, u.tpl_host_port_no_ip_fuzzy_strict = u.tpl_host_no_ip_fuzzy + u.src_port + u.src_host_terminator, u.tpl_host_fuzzy_test = "localhost|www\\.|\\.\\d{1,3}\\.|(?:\\.(?:%TLDS%)(?:" + u.src_ZPCc + "|>|$))", u.tpl_email_fuzzy = "(^|" + t + '|"|\\(|' + u.src_ZCc + ")(" + u.src_email_name + "@" + u.tpl_host_fuzzy_strict + ")", u.tpl_link_fuzzy = // Fuzzy link can't be prepended with .:/\- and non punctuation.
  // but can start with > (markdown blockquote)
  "(^|(?![.:/\\-_@])(?:[$+<=>^`|｜]|" + u.src_ZPCc + "))((?![$+<=>^`|｜])" + u.tpl_host_port_fuzzy_strict + u.src_path + ")", u.tpl_link_no_ip_fuzzy = // Fuzzy link can't be prepended with .:/\- and non punctuation.
  // but can start with > (markdown blockquote)
  "(^|(?![.:/\\-_@])(?:[$+<=>^`|｜]|" + u.src_ZPCc + "))((?![$+<=>^`|｜])" + u.tpl_host_port_no_ip_fuzzy_strict + u.src_path + ")", u;
}
function Dt(e) {
  return Array.prototype.slice.call(arguments, 1).forEach(function(t) {
    t && Object.keys(t).forEach(function(s) {
      e[s] = t[s];
    });
  }), e;
}
function Du(e) {
  return Object.prototype.toString.call(e);
}
function ts(e) {
  return Du(e) === "[object String]";
}
function rs(e) {
  return Du(e) === "[object Object]";
}
function ns(e) {
  return Du(e) === "[object RegExp]";
}
function ar(e) {
  return Du(e) === "[object Function]";
}
function is(e) {
  return e.replace(/[.?*+^$[\]\\(){}|-]/g, "\\$&");
}
const J0 = {
  fuzzyLink: !0,
  fuzzyEmail: !0,
  fuzzyIP: !1
};
function as(e) {
  return Object.keys(e || {}).reduce(function(u, t) {
    return u || J0.hasOwnProperty(t);
  }, !1);
}
const ss = {
  "http:": {
    validate: function(e, u, t) {
      const s = e.slice(u);
      return t.re.http || (t.re.http = new RegExp(
        "^\\/\\/" + t.re.src_auth + t.re.src_host_port_strict + t.re.src_path,
        "i"
      )), t.re.http.test(s) ? s.match(t.re.http)[0].length : 0;
    }
  },
  "https:": "http:",
  "ftp:": "http:",
  "//": {
    validate: function(e, u, t) {
      const s = e.slice(u);
      return t.re.no_http || (t.re.no_http = new RegExp(
        "^" + t.re.src_auth + // Don't allow single-level domains, because of false positives like '//test'
        // with code comments
        "(?:localhost|(?:(?:" + t.re.src_domain + ")\\.)+" + t.re.src_domain_root + ")" + t.re.src_port + t.re.src_host_terminator + t.re.src_path,
        "i"
      )), t.re.no_http.test(s) ? u >= 3 && e[u - 3] === ":" || u >= 3 && e[u - 3] === "/" ? 0 : s.match(t.re.no_http)[0].length : 0;
    }
  },
  "mailto:": {
    validate: function(e, u, t) {
      const s = e.slice(u);
      return t.re.mailto || (t.re.mailto = new RegExp(
        "^" + t.re.src_email_name + "@" + t.re.src_host_strict,
        "i"
      )), t.re.mailto.test(s) ? s.match(t.re.mailto)[0].length : 0;
    }
  }
}, cs = "a[cdefgilmnoqrstuwxz]|b[abdefghijmnorstvwyz]|c[acdfghiklmnoruvwxyz]|d[ejkmoz]|e[cegrstu]|f[ijkmor]|g[abdefghilmnpqrstuwy]|h[kmnrtu]|i[delmnoqrst]|j[emop]|k[eghimnprwyz]|l[abcikrstuvy]|m[acdeghklmnopqrstuvwxyz]|n[acefgilopruz]|om|p[aefghklmnrstwy]|qa|r[eosuw]|s[abcdeghijklmnortuvxyz]|t[cdfghjklmnortvwz]|u[agksyz]|v[aceginu]|w[fs]|y[et]|z[amw]", os = "biz|com|edu|gov|net|org|pro|web|xxx|aero|asia|coop|info|museum|name|shop|рф".split("|");
function ls(e) {
  e.__index__ = -1, e.__text_cache__ = "";
}
function fs(e) {
  return function(u, t) {
    const s = u.slice(t);
    return e.test(s) ? s.match(e)[0].length : 0;
  };
}
function sr() {
  return function(e, u) {
    u.normalize(e);
  };
}
function yu(e) {
  const u = e.re = us(e.__opts__), t = e.__tlds__.slice();
  e.onCompile(), e.__tlds_replaced__ || t.push(cs), t.push(u.src_xn), u.src_tlds = t.join("|");
  function s(i) {
    return i.replace("%TLDS%", u.src_tlds);
  }
  u.email_fuzzy = RegExp(s(u.tpl_email_fuzzy), "i"), u.link_fuzzy = RegExp(s(u.tpl_link_fuzzy), "i"), u.link_no_ip_fuzzy = RegExp(s(u.tpl_link_no_ip_fuzzy), "i"), u.host_fuzzy_test = RegExp(s(u.tpl_host_fuzzy_test), "i");
  const a = [];
  e.__compiled__ = {};
  function r(i, c) {
    throw new Error('(LinkifyIt) Invalid schema "' + i + '": ' + c);
  }
  Object.keys(e.__schemas__).forEach(function(i) {
    const c = e.__schemas__[i];
    if (c === null)
      return;
    const n = { validate: null, link: null };
    if (e.__compiled__[i] = n, rs(c)) {
      ns(c.validate) ? n.validate = fs(c.validate) : ar(c.validate) ? n.validate = c.validate : r(i, c), ar(c.normalize) ? n.normalize = c.normalize : c.normalize ? r(i, c) : n.normalize = sr();
      return;
    }
    if (ts(c)) {
      a.push(i);
      return;
    }
    r(i, c);
  }), a.forEach(function(i) {
    e.__compiled__[e.__schemas__[i]] && (e.__compiled__[i].validate = e.__compiled__[e.__schemas__[i]].validate, e.__compiled__[i].normalize = e.__compiled__[e.__schemas__[i]].normalize);
  }), e.__compiled__[""] = { validate: null, normalize: sr() };
  const o = Object.keys(e.__compiled__).filter(function(i) {
    return i.length > 0 && e.__compiled__[i];
  }).map(is).join("|");
  e.re.schema_test = RegExp("(^|(?!_)(?:[><｜]|" + u.src_ZPCc + "))(" + o + ")", "i"), e.re.schema_search = RegExp("(^|(?!_)(?:[><｜]|" + u.src_ZPCc + "))(" + o + ")", "ig"), e.re.schema_at_start = RegExp("^" + e.re.schema_search.source, "i"), e.re.pretest = RegExp(
    "(" + e.re.schema_test.source + ")|(" + e.re.host_fuzzy_test.source + ")|@",
    "i"
  ), ls(e);
}
function ds(e, u) {
  const t = e.__index__, s = e.__last_index__, a = e.__text_cache__.slice(t, s);
  this.schema = e.__schema__.toLowerCase(), this.index = t + u, this.lastIndex = s + u, this.raw = a, this.text = a, this.url = a;
}
function Et(e, u) {
  const t = new ds(e, u);
  return e.__compiled__[t.schema].normalize(t, e), t;
}
function ie(e, u) {
  if (!(this instanceof ie))
    return new ie(e, u);
  u || as(e) && (u = e, e = {}), this.__opts__ = Dt({}, J0, u), this.__index__ = -1, this.__last_index__ = -1, this.__schema__ = "", this.__text_cache__ = "", this.__schemas__ = Dt({}, ss, e), this.__compiled__ = {}, this.__tlds__ = os, this.__tlds_replaced__ = !1, this.re = {}, yu(this);
}
ie.prototype.add = function(u, t) {
  return this.__schemas__[u] = t, yu(this), this;
};
ie.prototype.set = function(u) {
  return this.__opts__ = Dt(this.__opts__, u), this;
};
ie.prototype.test = function(u) {
  if (this.__text_cache__ = u, this.__index__ = -1, !u.length)
    return !1;
  let t, s, a, r, o, i, c, n, l;
  if (this.re.schema_test.test(u)) {
    for (c = this.re.schema_search, c.lastIndex = 0; (t = c.exec(u)) !== null; )
      if (r = this.testSchemaAt(u, t[2], c.lastIndex), r) {
        this.__schema__ = t[2], this.__index__ = t.index + t[1].length, this.__last_index__ = t.index + t[0].length + r;
        break;
      }
  }
  return this.__opts__.fuzzyLink && this.__compiled__["http:"] && (n = u.search(this.re.host_fuzzy_test), n >= 0 && (this.__index__ < 0 || n < this.__index__) && (s = u.match(this.__opts__.fuzzyIP ? this.re.link_fuzzy : this.re.link_no_ip_fuzzy)) !== null && (o = s.index + s[1].length, (this.__index__ < 0 || o < this.__index__) && (this.__schema__ = "", this.__index__ = o, this.__last_index__ = s.index + s[0].length))), this.__opts__.fuzzyEmail && this.__compiled__["mailto:"] && (l = u.indexOf("@"), l >= 0 && (a = u.match(this.re.email_fuzzy)) !== null && (o = a.index + a[1].length, i = a.index + a[0].length, (this.__index__ < 0 || o < this.__index__ || o === this.__index__ && i > this.__last_index__) && (this.__schema__ = "mailto:", this.__index__ = o, this.__last_index__ = i))), this.__index__ >= 0;
};
ie.prototype.pretest = function(u) {
  return this.re.pretest.test(u);
};
ie.prototype.testSchemaAt = function(u, t, s) {
  return this.__compiled__[t.toLowerCase()] ? this.__compiled__[t.toLowerCase()].validate(u, s, this) : 0;
};
ie.prototype.match = function(u) {
  const t = [];
  let s = 0;
  this.__index__ >= 0 && this.__text_cache__ === u && (t.push(Et(this, s)), s = this.__last_index__);
  let a = s ? u.slice(s) : u;
  for (; this.test(a); )
    t.push(Et(this, s)), a = a.slice(this.__last_index__), s += this.__last_index__;
  return t.length ? t : null;
};
ie.prototype.matchAtStart = function(u) {
  if (this.__text_cache__ = u, this.__index__ = -1, !u.length) return null;
  const t = this.re.schema_at_start.exec(u);
  if (!t) return null;
  const s = this.testSchemaAt(u, t[2], t[0].length);
  return s ? (this.__schema__ = t[2], this.__index__ = t.index + t[1].length, this.__last_index__ = t.index + t[0].length + s, Et(this, 0)) : null;
};
ie.prototype.tlds = function(u, t) {
  return u = Array.isArray(u) ? u : [u], t ? (this.__tlds__ = this.__tlds__.concat(u).sort().filter(function(s, a, r) {
    return s !== r[a - 1];
  }).reverse(), yu(this), this) : (this.__tlds__ = u.slice(), this.__tlds_replaced__ = !0, yu(this), this);
};
ie.prototype.normalize = function(u) {
  u.schema || (u.url = "http://" + u.url), u.schema === "mailto:" && !/^mailto:/i.test(u.url) && (u.url = "mailto:" + u.url);
};
ie.prototype.onCompile = function() {
};
const qe = 2147483647, ye = 36, Nt = 1, Xe = 26, As = 38, hs = 700, Z0 = 72, V0 = 128, z0 = "-", bs = /^xn--/, ps = /[^\0-\x7F]/, gs = /[\x2E\u3002\uFF0E\uFF61]/g, ms = {
  overflow: "Overflow: input needs wider integers to process",
  "not-basic": "Illegal input >= 0x80 (not a basic code point)",
  "invalid-input": "Invalid input"
}, Lu = ye - Nt, we = Math.floor, Pu = String.fromCharCode;
function Fe(e) {
  throw new RangeError(ms[e]);
}
function xs(e, u) {
  const t = [];
  let s = e.length;
  for (; s--; )
    t[s] = u(e[s]);
  return t;
}
function X0(e, u) {
  const t = e.split("@");
  let s = "";
  t.length > 1 && (s = t[0] + "@", e = t[1]), e = e.replace(gs, ".");
  const a = e.split("."), r = xs(a, u).join(".");
  return s + r;
}
function $0(e) {
  const u = [];
  let t = 0;
  const s = e.length;
  for (; t < s; ) {
    const a = e.charCodeAt(t++);
    if (a >= 55296 && a <= 56319 && t < s) {
      const r = e.charCodeAt(t++);
      (r & 64512) == 56320 ? u.push(((a & 1023) << 10) + (r & 1023) + 65536) : (u.push(a), t--);
    } else
      u.push(a);
  }
  return u;
}
const ys = (e) => String.fromCodePoint(...e), ws = function(e) {
  return e >= 48 && e < 58 ? 26 + (e - 48) : e >= 65 && e < 91 ? e - 65 : e >= 97 && e < 123 ? e - 97 : ye;
}, cr = function(e, u) {
  return e + 22 + 75 * (e < 26) - ((u != 0) << 5);
}, en = function(e, u, t) {
  let s = 0;
  for (e = t ? we(e / hs) : e >> 1, e += we(e / u); e > Lu * Xe >> 1; s += ye)
    e = we(e / Lu);
  return we(s + (Lu + 1) * e / (e + As));
}, un = function(e) {
  const u = [], t = e.length;
  let s = 0, a = V0, r = Z0, o = e.lastIndexOf(z0);
  o < 0 && (o = 0);
  for (let i = 0; i < o; ++i)
    e.charCodeAt(i) >= 128 && Fe("not-basic"), u.push(e.charCodeAt(i));
  for (let i = o > 0 ? o + 1 : 0; i < t; ) {
    const c = s;
    for (let l = 1, f = ye; ; f += ye) {
      i >= t && Fe("invalid-input");
      const A = ws(e.charCodeAt(i++));
      A >= ye && Fe("invalid-input"), A > we((qe - s) / l) && Fe("overflow"), s += A * l;
      const d = f <= r ? Nt : f >= r + Xe ? Xe : f - r;
      if (A < d)
        break;
      const h = ye - d;
      l > we(qe / h) && Fe("overflow"), l *= h;
    }
    const n = u.length + 1;
    r = en(s - c, n, c == 0), we(s / n) > qe - a && Fe("overflow"), a += we(s / n), s %= n, u.splice(s++, 0, a);
  }
  return String.fromCodePoint(...u);
}, tn = function(e) {
  const u = [];
  e = $0(e);
  const t = e.length;
  let s = V0, a = 0, r = Z0;
  for (const c of e)
    c < 128 && u.push(Pu(c));
  const o = u.length;
  let i = o;
  for (o && u.push(z0); i < t; ) {
    let c = qe;
    for (const l of e)
      l >= s && l < c && (c = l);
    const n = i + 1;
    c - s > we((qe - a) / n) && Fe("overflow"), a += (c - s) * n, s = c;
    for (const l of e)
      if (l < s && ++a > qe && Fe("overflow"), l === s) {
        let f = a;
        for (let A = ye; ; A += ye) {
          const d = A <= r ? Nt : A >= r + Xe ? Xe : A - r;
          if (f < d)
            break;
          const h = f - d, y = ye - d;
          u.push(
            Pu(cr(d + h % y, 0))
          ), f = we(h / y);
        }
        u.push(Pu(cr(f, 0))), r = en(a, n, i === o), a = 0, ++i;
      }
    ++a, ++s;
  }
  return u.join("");
}, Cs = function(e) {
  return X0(e, function(u) {
    return bs.test(u) ? un(u.slice(4).toLowerCase()) : u;
  });
}, vs = function(e) {
  return X0(e, function(u) {
    return ps.test(u) ? "xn--" + tn(u) : u;
  });
}, rn = {
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
    decode: $0,
    encode: ys
  },
  decode: un,
  encode: tn,
  toASCII: vs,
  toUnicode: Cs
}, Ds = {
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
}, Es = {
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
}, _s = {
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
}, Is = {
  default: Ds,
  zero: Es,
  commonmark: _s
}, ks = /^(vbscript|javascript|file|data):/, Bs = /^data:image\/(gif|png|jpeg|webp);/;
function Fs(e) {
  const u = e.trim().toLowerCase();
  return ks.test(u) ? Bs.test(u) : !0;
}
const nn = ["http:", "https:", "mailto:"];
function Ss(e) {
  const u = kt(e, !0);
  if (u.hostname && (!u.protocol || nn.indexOf(u.protocol) >= 0))
    try {
      u.hostname = rn.toASCII(u.hostname);
    } catch {
    }
  return $e(It(u));
}
function Ts(e) {
  const u = kt(e, !0);
  if (u.hostname && (!u.protocol || nn.indexOf(u.protocol) >= 0))
    try {
      u.hostname = rn.toUnicode(u.hostname);
    } catch {
    }
  return We(It(u), We.defaultChars + "%");
}
function oe(e, u) {
  if (!(this instanceof oe))
    return new oe(e, u);
  u || Ft(e) || (u = e || {}, e = "default"), this.inline = new uu(), this.block = new vu(), this.core = new Tt(), this.renderer = new Ke(), this.linkify = new ie(), this.validateLink = Fs, this.normalizeLink = Ss, this.normalizeLinkText = Ts, this.utils = Ni, this.helpers = wu({}, Li), this.options = {}, this.configure(e), u && this.set(u);
}
oe.prototype.set = function(e) {
  return wu(this.options, e), this;
};
oe.prototype.configure = function(e) {
  const u = this;
  if (Ft(e)) {
    const t = e;
    if (e = Is[t], !e)
      throw new Error('Wrong `markdown-it` preset "' + t + '", check name');
  }
  if (!e)
    throw new Error("Wrong `markdown-it` preset, can't be empty");
  return e.options && u.set(e.options), e.components && Object.keys(e.components).forEach(function(t) {
    e.components[t].rules && u[t].ruler.enableOnly(e.components[t].rules), e.components[t].rules2 && u[t].ruler2.enableOnly(e.components[t].rules2);
  }), this;
};
oe.prototype.enable = function(e, u) {
  let t = [];
  Array.isArray(e) || (e = [e]), ["core", "block", "inline"].forEach(function(a) {
    t = t.concat(this[a].ruler.enable(e, !0));
  }, this), t = t.concat(this.inline.ruler2.enable(e, !0));
  const s = e.filter(function(a) {
    return t.indexOf(a) < 0;
  });
  if (s.length && !u)
    throw new Error("MarkdownIt. Failed to enable unknown rule(s): " + s);
  return this;
};
oe.prototype.disable = function(e, u) {
  let t = [];
  Array.isArray(e) || (e = [e]), ["core", "block", "inline"].forEach(function(a) {
    t = t.concat(this[a].ruler.disable(e, !0));
  }, this), t = t.concat(this.inline.ruler2.disable(e, !0));
  const s = e.filter(function(a) {
    return t.indexOf(a) < 0;
  });
  if (s.length && !u)
    throw new Error("MarkdownIt. Failed to disable unknown rule(s): " + s);
  return this;
};
oe.prototype.use = function(e) {
  const u = [this].concat(Array.prototype.slice.call(arguments, 1));
  return e.apply(e, u), this;
};
oe.prototype.parse = function(e, u) {
  if (typeof e != "string")
    throw new Error("Input data should be a String");
  const t = new this.core.State(e, this, u);
  return this.core.process(t), t.tokens;
};
oe.prototype.render = function(e, u) {
  return u = u || {}, this.renderer.render(this.parse(e, u), this.options, u);
};
oe.prototype.parseInline = function(e, u) {
  const t = new this.core.State(e, this, u);
  return t.inlineMode = !0, this.core.process(t), t.tokens;
};
oe.prototype.renderInline = function(e, u) {
  return u = u || {}, this.renderer.render(this.parseInline(e, u), this.options, u);
};
function Rs(e) {
  return e && e.__esModule && Object.prototype.hasOwnProperty.call(e, "default") ? e.default : e;
}
function Ns(e) {
  if (Object.prototype.hasOwnProperty.call(e, "__esModule")) return e;
  var u = e.default;
  if (typeof u == "function") {
    var t = function s() {
      return this instanceof s ? Reflect.construct(u, arguments, this.constructor) : u.apply(this, arguments);
    };
    t.prototype = u.prototype;
  } else t = {};
  return Object.defineProperty(t, "__esModule", { value: !0 }), Object.keys(e).forEach(function(s) {
    var a = Object.getOwnPropertyDescriptor(e, s);
    Object.defineProperty(t, s, a.get ? a : {
      enumerable: !0,
      get: function() {
        return e[s];
      }
    });
  }), t;
}
var Ae = {}, he = {}, He = {}, Gu = {}, Hu = {}, or;
function lr() {
  return or || (or = 1, (function(e) {
    var u;
    Object.defineProperty(e, "__esModule", { value: !0 }), e.fromCodePoint = void 0, e.replaceCodePoint = s, e.decodeCodePoint = a;
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
    (u = String.fromCodePoint) !== null && u !== void 0 ? u : ((r) => {
      let o = "";
      return r > 65535 && (r -= 65536, o += String.fromCharCode(r >>> 10 & 1023 | 55296), r = 56320 | r & 1023), o += String.fromCharCode(r), o;
    });
    function s(r) {
      var o;
      return r >= 55296 && r <= 57343 || r > 1114111 ? 65533 : (o = t.get(r)) !== null && o !== void 0 ? o : r;
    }
    function a(r) {
      return (0, e.fromCodePoint)(s(r));
    }
  })(Hu)), Hu;
}
var Ye = {}, su = {}, fr;
function an() {
  if (fr) return su;
  fr = 1, Object.defineProperty(su, "__esModule", { value: !0 }), su.decodeBase64 = e;
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
    ), s = t.length & -2, a = new Uint16Array(s / 2);
    for (let r = 0, o = 0; r < s; r += 2) {
      const i = t.charCodeAt(r), c = t.charCodeAt(r + 1);
      a[o++] = i | c << 8;
    }
    return a;
  }
  return su;
}
var dr;
function Ar() {
  if (dr) return Ye;
  dr = 1, Object.defineProperty(Ye, "__esModule", { value: !0 }), Ye.htmlDecodeTree = void 0;
  const e = an();
  return Ye.htmlDecodeTree = (0, e.decodeBase64)("QR08ALkAAgH6AYsDNQR2BO0EPgXZBQEGLAbdBxMISQrvCmQLfQurDKQNLw4fD4YPpA+6D/IPAAAAAAAAAAAAAAAAKhBMEY8TmxUWF2EYLBkxGuAa3RsJHDscWR8YIC8jSCSIJcMl6ie3Ku8rEC0CLjoupS7kLgAIRU1hYmNmZ2xtbm9wcnN0dVQAWgBeAGUAaQBzAHcAfgCBAIQAhwCSAJoAoACsALMAbABpAGcAO4DGAMZAUAA7gCYAJkBjAHUAdABlADuAwQDBQHIiZXZlAAJhAAFpeW0AcgByAGMAO4DCAMJAEGRyAADgNdgE3XIAYQB2AGUAO4DAAMBA8CFoYZFj4SFjcgBhZAAAoFMqAAFncIsAjgBvAG4ABGFmAADgNdg43fAlbHlGdW5jdGlvbgCgYSBpAG4AZwA7gMUAxUAAAWNzpACoAHIAAOA12Jzc6SFnbgCgVCJpAGwAZABlADuAwwDDQG0AbAA7gMQAxEAABGFjZWZvcnN1xQDYANoA7QDxAPYA+QD8AAABY3LJAM8AayNzbGFzaAAAoBYidgHTANUAAKDnKmUAZAAAoAYjeQARZIABY3J0AOAA5QDrAGEidXNlAACgNSLuI291bGxpcwCgLCFhAJJjcgAA4DXYBd1wAGYAAOA12Dnd5SF2ZdhiYwDyAOoAbSJwZXEAAKBOIgAHSE9hY2RlZmhpbG9yc3UXARoBHwE6AVIBVQFiAWQBZgGCAakB6QHtAfIBYwB5ACdkUABZADuAqQCpQIABY3B5ACUBKAE1AfUhdGUGYWmg0iJ0KGFsRGlmZmVyZW50aWFsRAAAoEUhbCJleXMAAKAtIQACYWVpb0EBRAFKAU0B8iFvbgxhZABpAGwAO4DHAMdAcgBjAAhhbiJpbnQAAKAwIm8AdAAKYQABZG5ZAV0BaSJsbGEAuGB0I2VyRG90ALdg8gA5AWkAp2NyImNsZQAAAkRNUFRwAXQBeQF9AW8AdAAAoJkiaSJudXMAAKCWIuwhdXMAoJUiaSJtZXMAAKCXIm8AAAFjc4cBlAFrKndpc2VDb250b3VySW50ZWdyYWwAAKAyImUjQ3VybHkAAAFEUZwBpAFvJXVibGVRdW90ZQAAoB0gdSJvdGUAAKAZIAACbG5wdbABtgHNAdgBbwBuAGWgNyIAoHQqgAFnaXQAvAHBAcUB8iJ1ZW50AKBhIm4AdAAAoC8i7yV1ckludGVncmFsAKAuIgABZnLRAdMBAKACIe8iZHVjdACgECJuLnRlckNsb2Nrd2lzZUNvbnRvdXJJbnRlZ3JhbAAAoDMi7yFzcwCgLypjAHIAAOA12J7ccABDoNMiYQBwAACgTSKABURKU1phY2VmaW9zAAsCEgIVAhgCGwIsAjQCOQI9AnMCfwNvoEUh9CJyYWhkAKARKWMAeQACZGMAeQAFZGMAeQAPZIABZ3JzACECJQIoAuchZXIAoCEgcgAAoKEhaAB2AACg5CoAAWF5MAIzAvIhb24OYRRkbAB0oAciYQCUY3IAAOA12AfdAAFhZkECawIAAWNtRQJnAvIjaXRpY2FsAAJBREdUUAJUAl8CYwJjInV0ZQC0YG8AdAFZAloC2WJiJGxlQWN1dGUA3WJyImF2ZQBgYGkibGRlANxi7yFuZACgxCJmJWVyZW50aWFsRAAAoEYhcAR9AgAAAAAAAIECjgIAABoDZgAA4DXYO91EoagAhQKJAm8AdAAAoNwgcSJ1YWwAAKBQIuIhbGUAA0NETFJVVpkCqAK1Au8C/wIRA28AbgB0AG8AdQByAEkAbgB0AGUAZwByAGEA7ADEAW8AdAKvAgAAAACwAqhgbiNBcnJvdwAAoNMhAAFlb7kC0AJmAHQAgAFBUlQAwQLGAs0CciJyb3cAAKDQIekkZ2h0QXJyb3cAoNQhZQDlACsCbgBnAAABTFLWAugC5SFmdAABQVLcAuECciJyb3cAAKD4J+kkZ2h0QXJyb3cAoPon6SRnaHRBcnJvdwCg+SdpImdodAAAAUFU9gL7AnIicm93AACg0iFlAGUAAKCoInAAQQIGAwAAAAALA3Iicm93AACg0SFvJHduQXJyb3cAAKDVIWUlcnRpY2FsQmFyAACgJSJuAAADQUJMUlRhJAM2AzoDWgNxA3oDciJyb3cAAKGTIUJVLAMwA2EAcgAAoBMpcCNBcnJvdwAAoPUhciJldmUAEWPlIWZ00gJDAwAASwMAAFIDaSVnaHRWZWN0b3IAAKBQKWUkZVZlY3RvcgAAoF4p5SJjdG9yQqC9IWEAcgAAoFYpaSJnaHQA1AFiAwAAaQNlJGVWZWN0b3IAAKBfKeUiY3RvckKgwSFhAHIAAKBXKWUAZQBBoKQiciJyb3cAAKCnIXIAcgBvAPcAtAIAAWN0gwOHA3IA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YwAAoN8i4SFycnCgtiEAoD0pgKIqImJjZG9zACsVMBU6FT4VQRVyImNhcAAAoEgqAAFhdTQVNxVwAACgRipwAACgSipvAHQAAKCNInIAAKBFKgDgKiIA/gACYWxydksVURVuFXMVcgByAG2gtyEAoDwpeQCAAWV2dwBYFWUVaRVxAHACXxUAAAAAYxVyAGUA4wAXFXUA4wAZFWUAZQAAoM4iZSJkZ2UAAKDPImUAbgA7gKQApEBlI2Fycm93AAABbHJ7FX8V5SFmdACgtiFpImdodAAAoLchZQDkAG0VAAFjaYsVkRVvAG4AaQBuAPQAkwFuAHQAAKAxImwiY3R5AACgLSOACUFIYWJjZGVmaGlqbG9yc3R1d3oAuBW7Fb8V1RXgFegV+RUKFhUWHxZUFlcWZRbFFtsW7xb7FgUXChdyAPIAtAJhAHIAAKBlKQACZ2xyc8YVyhXOFdAV5yFlcgCgICDlIXRoAKA4IfIA9QxoAHagECAAoKMiawHZFd4VYSJyb3cAAKAPKWEA4wBfAgABYXnkFecV8iFvbg9hNGQAoUYhYW/tFfQVAAFnciEC8RVyAACgyiF0InNlcQAAoHcqgAFnbG0A/xUCFgUWO4CwALBAdABhALRjcCJ0eXYAAKCxKQABaXIOFhIW8yFodACgfykA4DXYId1hAHIAAAFschsWHRYAoMMhAKDCIYACYWVnc3YAKBauAjYWOhY+Fm0AAKHEIm9zLhY0Fm4AZABzoMQi9SFpdACgZiZhIm1tYQDdY2kAbgAAoPIiAKH3AGlvQxZRFmQAZQAAgfcAO29KFksW90BuI3RpbWVzAACgxyJuAPgAUBZjAHkAUmRjAG8CXhYAAAAAYhZyAG4AAKAeI28AcAAAoA0jgAJscHR1dwBuFnEWdRaSFp4W7CFhciRgZgAA4DXYVd0AotkCZW1wc30WhBaJFo0WcQBkoFAibwB0AACgUSJpIm51cwAAoDgi7CF1cwCgFCLxInVhcmUAoKEiYgBsAGUAYgBhAHIAdwBlAGQAZwDlANcAbgCAAWFkaAClFqoWtBZyAHIAbwD3APUMbwB3AG4AYQByAHIAbwB3APMA8xVhI3Jwb29uAAABbHK8FsAWZQBmAPQAHBZpAGcAaAD0AB4WYgHJFs8WawBhAHIAbwD3AJILbwLUFgAAAADYFnIAbgAAoB8jbwBwAACgDCOAAWNvdADhFukW7BYAAXJ55RboFgDgNdi53FVkbAAAoPYp8iFvaxFhAAFkcvMW9xZvAHQAAKDxImkA5qC/JVsSAAFhaP8WAhdyAPIANQNhAPIA1wvhIm5nbGUAoKYpAAFjaQ4XEBd5AF9k5yJyYXJyAKD/JwAJRGFjZGVmZ2xtbm9wcXJzdHV4MRc4F0YXWxcyBF4XaRd5F40XrBe0F78X2RcVGCEYLRg1GEAYAAFEbzUXgRZvAPQA+BUAAWNzPBdCF3UAdABlADuA6QDpQPQhZXIAoG4qAAJhaW95TRdQF1YXWhfyIW9uG2FyAGOgViI7gOoA6kDsIW9uAKBVIk1kbwB0ABdhAAFEcmIXZhdvAHQAAKBSIgDgNdgi3XKhmipuF3QXYQB2AGUAO4DoAOhAZKCWKm8AdAAAoJgqgKGZKmlscwCAF4UXhxfuInRlcnMAoOcjAKATIWSglSpvAHQAAKCXKoABYXBzAJMXlheiF2MAcgATYXQAeQBzogUinxcAAAAAoRdlAHQAAKAFInAAMaADIDMBqRerFwCgBCAAoAUgAAFnc7AXsRdLYXAAAKACIAABZ3C4F7sXbwBuABlhZgAA4DXYVt2AAWFscwDFF8sXzxdyAHOg1SJsAACg4yl1AHMAAKBxKmkAAKG1A2x21RfYF28AbgC1Y/VjAAJjc3V24BfoF/0XEBgAAWlv5BdWF3IAYwAAoFYiaQLuFwAAAADwF+0ADQThIW50AAFnbPUX+Rd0AHIAAKCWKuUhc3MAoJUqgAFhZWkAAxgGGAoYbABzAD1gcwB0AACgXyJ2AESgYSJEAACgeCrwImFyc2wAoOUpAAFEYRkYHRhvAHQAAKBTInIAcgAAoHEpgAFjZGkAJxgqGO0XcgAAoC8hbwD0AIwCAAFhaDEYMhi3YzuA8ADwQAABbXI5GD0YbAA7gOsA60BvAACgrCCAAWNpcABGGEgYSxhsACFgcwD0ACwEAAFlb08YVxhjAHQAYQB0AGkAbwDuABoEbgBlAG4AdABpAGEAbADlADME4Ql1GAAAgRgAAIMYiBgAAAAAoRilGAAAqhgAALsYvhjRGAAA1xgnGWwAbABpAG4AZwBkAG8AdABzAGUA8QBlF3kARGRtImFsZQAAoEAmgAFpbHIAjRiRGJ0Y7CFpZwCgA/tpApcYAAAAAJoYZwAAoAD7aQBnAACgBPsA4DXYI93sIWlnAKAB++whaWcA4GYAagCAAWFsdACvGLIYthh0AACgbSZpAGcAAKAC+24AcwAAoLElbwBmAJJh8AHCGAAAxhhmAADgNdhX3QABYWvJGMwYbADsAGsEdqDUIgCg2SphI3J0aW50AACgDSoAAWFv2hgiGQABY3PeGB8ZsQPnGP0YBRkSGRUZAAAdGbID7xjyGPQY9xj5GAAA+xg7gL0AvUAAoFMhO4C8ALxAAKBVIQCgWSEAoFshswEBGQAAAxkAoFQhAKBWIbQCCxkOGQAAAAAQGTuAvgC+QACgVyEAoFwhNQAAoFghtgEZGQAAGxkAoFohAKBdITgAAKBeIWwAAKBEIHcAbgAAoCIjYwByAADgNdi73IAIRWFiY2RlZmdpamxub3JzdHYARhlKGVoZXhlmGWkZkhmWGZkZnRmgGa0ZxhnLGc8Z4BkjGmygZyIAoIwqgAFjbXAAUBlTGVgZ9SF0ZfVhbQBhAOSgswM6FgCghipyImV2ZQAfYQABaXliGWUZcgBjAB1hM2RvAHQAIWGAoWUibHFzAMYEcBl6GfGhZSLOBAAAdhlsAGEAbgD0AN8EgKF+KmNkbACBGYQZjBljAACgqSpvAHQAb6CAKmyggioAoIQqZeDbIgD+cwAAoJQqcgAA4DXYJN3noGsirATtIWVsAKA3IWMAeQBTZIChdyJFYWoApxmpGasZAKCSKgCgpSoAoKQqAAJFYWVztBm2Gb0ZwhkAoGkicABwoIoq8iFveACgiipxoIgq8aCIKrUZaQBtAACg5yJwAGYAAOA12FjdYQB2AOUAYwIAAWNp0xnWGXIAAKAKIW0AAKFzImVs3BneGQCgjioAoJAqAIM+ADtjZGxxco0E6xn0GfgZ/BkBGgABY2nvGfEZAKCnKnIAAKB6Km8AdAAAoNci0CFhcgCglSl1ImVzdAAAoHwqgAJhZGVscwAKGvQZFhrVBCAa8AEPGgAAFBpwAHIAbwD4AFkZcgAAoHgpcQAAAWxxxAQbGmwAZQBzAPMASRlpAO0A5AQAAWVuJxouGnIjdG5lcXEAAOBpIgD+xQAsGgAFQWFiY2Vma29zeUAaQxpmGmoabRqDGocalhrCGtMacgDyAMwCAAJpbG1yShpOGlAaVBpyAHMA8ABxD2YAvWBpAGwA9AASBQABZHJYGlsaYwB5AEpkAKGUIWN3YBpkGmkAcgAAoEgpAKCtIWEAcgAAoA8h6SFyYyVhgAFhbHIAcxp7Gn8a8iF0c3WgZSZpAHQAAKBlJuwhaXAAoCYg4yFvbgCguSJyAADgNdgl3XMAAAFld4wakRphInJvdwAAoCUpYSJyb3cAAKAmKYACYW1vcHIAnxqjGqcauhq+GnIAcgAAoP8h9CFodACgOyJrAAABbHKsGrMaZSRmdGFycm93AACgqSHpJGdodGFycm93AKCqIWYAAOA12Fnd4iFhcgCgFSCAAWNsdADIGswa0BpyAADgNdi93GEAcwDoAGka8iFvaydhAAFicNca2xr1IWxsAKBDIOghZW4AoBAg4Qr2GgAA/RoAAAgbExsaGwAAIRs7GwAAAAA+G2IbmRuVG6sbAACyG80b0htjAHUAdABlADuA7QDtQAChYyBpeQEbBhtyAGMAO4DuAO5AOGQAAWN4CxsNG3kANWRjAGwAO4ChAKFAAAFmcssCFhsA4DXYJt1yAGEAdgBlADuA7ADsQIChSCFpbm8AJxsyGzYbAAFpbisbLxtuAHQAAKAMKnQAAKAtIuYhaW4AoNwpdABhAACgKSHsIWlnM2GAAWFvcABDG1sbXhuAAWNndABJG0sbWRtyACthgAFlbHAAcQVRG1UbaQBuAOUAyAVhAHIA9AByBWgAMWFmAACgtyJlAGQAtWEAoggiY2ZvdGkbbRt1G3kb4SFyZQCgBSFpAG4AdKAeImkAZQAAoN0pZABvAPQAWxsAoisiY2VscIEbhRuPG5QbYQBsAACguiIAAWdyiRuNG2UAcgDzACMQ4wCCG2EicmhrAACgFyryIW9kAKA8KgACY2dwdJ8boRukG6gbeQBRZG8AbgAvYWYAAOA12FrdYQC5Y3UAZQBzAHQAO4C/AL9AAAFjabUbuRtyAADgNdi+3G4AAKIIIkVkc3bCG8QbyBvQAwCg+SJvAHQAAKD1Inag9CIAoPMiaaBiIOwhZGUpYesB1hsAANkbYwB5AFZkbAA7gO8A70AAA2NmbW9zdeYb7hvyG/Ub+hsFHAABaXnqG+0bcgBjADVhOWRyAADgNdgn3eEhdGg3YnAAZgAA4DXYW93jAf8bAAADHHIAAOA12L/c8iFjeVhk6yFjeVRkAARhY2ZnaGpvcxUcGhwiHCYcKhwtHDAcNRzwIXBhdqC6A/BjAAFleR4cIRzkIWls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ZmdobG1vcHJzdHV3CiwNLBEsHSwnLDEsQCxLLFIsYix6LIQsjyzLLOgs7Sz/LAotcgDyAAkDYQByAACgYykAAWNyFSwbLHUAdABlADuA+gD6QPIACQ1yAOMBIywAACUseQBeZHYAZQBtYQABaXkrLDAscgBjADuA+wD7QENkgAFhYmgANyw6LD0scgDyANEO7CFhY3FhYQDyAOAOAAFpckQsSCzzIWh0AKB+KQDgNdgy3XIAYQB2AGUAO4D5APlAYQFWLF8scgAAAWxyWixcLACgvyEAoL4hbABrAACggCUAAWN0Zix2LG8CbCwAAAAAcyxyAG4AZaAcI3IAAKAcI28AcAAAoA8jcgBpAACg+CUAAWFsfiyBLGMAcgBrYTuAqACoQAABZ3CILIssbwBuAHNhZgAA4DXYZt0AA2FkaGxzdZksniynLLgsuyzFLHIAcgBvAPcACQ1vAHcAbgBhAHIAcgBvAPcA2A5hI3Jwb29uAAABbHKvLLMsZQBmAPQAWyxpAGcAaAD0AF0sdQDzAKYOaQAAocUDaGzBLMIs0mNvAG4AxWPwI2Fycm93cwCgyCGAAWNpdADRLOEs5CxvAtcsAAAAAN4scgBuAGWgHSNyAACgHSNvAHAAAKAOI24AZwBvYXIAaQAAoPklYwByAADgNdjK3IABZGlyAPMs9yz6LG8AdAAAoPAi7CFkZWlhaQBmoLUlAKC0JQABYW0DLQYtcgDyAMosbAA7gPwA/EDhIm5nbGUAoKcpgAdBQkRhY2RlZmxub3Byc3oAJy0qLTAtNC2bLZ0toS2/LcMtxy3TLdgt3C3gLfwtcgDyABADYQByAHag6CoAoOkqYQBzAOgA/gIAAW5yOC08LechcnQAoJwpgANla25wcnN0AJkpSC1NLVQtXi1iLYItYQBwAHAA4QAaHG8AdABoAGkAbgDnAKEXgAFoaXIAoSmzJFotbwBwAPQAdCVooJUh7wD4JgABaXVmLWotZwBtAOEAuygAAWJwbi14LXMjZXRuZXEAceCKIgD+AODLKgD+cyNldG5lcQBx4IsiAP4A4MwqAP4AAWhyhi2KLWUAdADhABIraSNhbmdsZQAAAWxyki2WLeUhZnQAoLIiaSJnaHQAAKCzInkAMmThIXNoAKCiIoABZWxyAKcttC24LWKiKCKuLQAAAACyLWEAcgAAoLsicQAAoFoi7CFpcACg7iIAAWJ0vC1eD2EA8gBfD3IAAOA12DPddAByAOkAlS1zAHUAAAFicM0t0C0A4IIi0iAA4IMi0iBwAGYAAOA12GfdcgBvAPAAWQt0AHIA6QCaLQABY3XkLegtcgAA4DXYy9wAAWJw7C30LW4AAAFFZXUt8S0A4IoiAP5uAAABRWV/LfktAOCLIgD+6SJnemFnAKCaKYADY2Vmb3BycwANLhAuJS4pLiMuLi40LukhcmN1YQABZGkULiEuAAFiZxguHC5hAHIAAKBfKmUAcaAnIgCgWSLlIXJwAKAYIXIAAOA12DTdcABmAADgNdho3WWgQCJhAHQA6ABqD2MAcgAA4DXYzNzjCuQRUC4AAFQuAABYLmIuAAAAAGMubS5wLnQuAAAAAIguki4AAJouJxIqEnQAcgDpAB0ScgAA4DXYNd0AAUFhWy5eLnIA8gDnAnIA8gCTB75jAAFBYWYuaS5yAPIA4AJyAPIAjAdhAPAAeh5pAHMAAKD7IoABZHB0APgReS6DLgABZmx9LoAuAOA12GnddQDzAP8RaQBtAOUABBIAAUFhiy6OLnIA8gDuAnIA8gCaBwABY3GVLgoScgAA4DXYzdwAAXB0nS6hLmwAdQDzACUScgDpACASAARhY2VmaW9zdbEuvC7ELsguzC7PLtQu2S5jAAABdXm2LrsudABlADuA/QD9QE9kAAFpecAuwy5yAGMAd2FLZG4AO4ClAKVAcgAA4DXYNt1jAHkAV2RwAGYAAOA12GrdYwByAADgNdjO3AABY23dLt8ueQBOZGwAO4D/AP9AAAVhY2RlZmhpb3N38y73Lv8uAi8MLxAvEy8YLx0vIi9jInV0ZQB6YQABYXn7Lv4u8iFvbn5hN2RvAHQAfGEAAWV0Bi8KL3QAcgDmAB8QYQC2Y3IAAOA12DfdYwB5ADZk5yJyYXJyAKDdIXAAZgAA4DXYa91jAHIAAOA12M/cAAFqbiYvKC8AoA0gagAAoAwg"), Ye;
}
var je = {}, hr;
function br() {
  if (hr) return je;
  hr = 1, Object.defineProperty(je, "__esModule", { value: !0 }), je.xmlDecodeTree = void 0;
  const e = an();
  return je.xmlDecodeTree = (0, e.decodeBase64)("AAJhZ2xxBwARABMAFQBtAg0AAAAAAA8AcAAmYG8AcwAnYHQAPmB0ADxg9SFvdCJg"), je;
}
var Je = {}, pr;
function Ms() {
  if (pr) return Je;
  pr = 1, Object.defineProperty(Je, "__esModule", { value: !0 }), Je.BinTrieFlags = void 0;
  var e;
  return (function(u) {
    u[u.VALUE_LENGTH = 49152] = "VALUE_LENGTH", u[u.FLAG13 = 8192] = "FLAG13", u[u.BRANCH_LENGTH = 8064] = "BRANCH_LENGTH", u[u.JUMP_TABLE = 127] = "JUMP_TABLE";
  })(e || (Je.BinTrieFlags = e = {})), Je;
}
var gr;
function sn() {
  return gr || (gr = 1, (function(e) {
    Object.defineProperty(e, "__esModule", { value: !0 }), e.xmlDecodeTree = e.htmlDecodeTree = e.replaceCodePoint = e.fromCodePoint = e.decodeCodePoint = e.EntityDecoder = e.DecodingMode = void 0, e.determineBranch = y, e.decodeHTML = b, e.decodeHTMLAttribute = x, e.decodeHTMLStrict = m, e.decodeXML = p;
    const u = lr(), t = Ar(), s = br(), a = Ms();
    var r;
    (function(E) {
      E[E.NUM = 35] = "NUM", E[E.SEMI = 59] = "SEMI", E[E.EQUALS = 61] = "EQUALS", E[E.ZERO = 48] = "ZERO", E[E.NINE = 57] = "NINE", E[E.LOWER_A = 97] = "LOWER_A", E[E.LOWER_F = 102] = "LOWER_F", E[E.LOWER_X = 120] = "LOWER_X", E[E.LOWER_Z = 122] = "LOWER_Z", E[E.UPPER_A = 65] = "UPPER_A", E[E.UPPER_F = 70] = "UPPER_F", E[E.UPPER_Z = 90] = "UPPER_Z";
    })(r || (r = {}));
    const o = 32;
    function i(E) {
      return E >= r.ZERO && E <= r.NINE;
    }
    function c(E) {
      return E >= r.UPPER_A && E <= r.UPPER_F || E >= r.LOWER_A && E <= r.LOWER_F;
    }
    function n(E) {
      return E >= r.UPPER_A && E <= r.UPPER_Z || E >= r.LOWER_A && E <= r.LOWER_Z || i(E);
    }
    function l(E) {
      return E === r.EQUALS || n(E);
    }
    var f;
    (function(E) {
      E[E.EntityStart = 0] = "EntityStart", E[E.NumericStart = 1] = "NumericStart", E[E.NumericDecimal = 2] = "NumericDecimal", E[E.NumericHex = 3] = "NumericHex", E[E.NamedEntity = 4] = "NamedEntity";
    })(f || (f = {}));
    var A;
    (function(E) {
      E[E.Legacy = 0] = "Legacy", E[E.Strict = 1] = "Strict", E[E.Attribute = 2] = "Attribute";
    })(A || (e.DecodingMode = A = {}));
    class d {
      constructor(_, v, k) {
        this.decodeTree = _, this.emitCodePoint = v, this.errors = k, this.state = f.EntityStart, this.consumed = 1, this.result = 0, this.treeIndex = 0, this.excess = 1, this.decodeMode = A.Strict, this.runConsumed = 0;
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
      write(_, v) {
        switch (this.state) {
          case f.EntityStart:
            return _.charCodeAt(v) === r.NUM ? (this.state = f.NumericStart, this.consumed += 1, this.stateNumericStart(_, v + 1)) : (this.state = f.NamedEntity, this.stateNamedEntity(_, v));
          case f.NumericStart:
            return this.stateNumericStart(_, v);
          case f.NumericDecimal:
            return this.stateNumericDecimal(_, v);
          case f.NumericHex:
            return this.stateNumericHex(_, v);
          case f.NamedEntity:
            return this.stateNamedEntity(_, v);
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
      stateNumericStart(_, v) {
        return v >= _.length ? -1 : (_.charCodeAt(v) | o) === r.LOWER_X ? (this.state = f.NumericHex, this.consumed += 1, this.stateNumericHex(_, v + 1)) : (this.state = f.NumericDecimal, this.stateNumericDecimal(_, v));
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
      stateNumericHex(_, v) {
        for (; v < _.length; ) {
          const k = _.charCodeAt(v);
          if (i(k) || c(k)) {
            const S = k <= r.NINE ? k - r.ZERO : (k | o) - r.LOWER_A + 10;
            this.result = this.result * 16 + S, this.consumed++, v++;
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
      stateNumericDecimal(_, v) {
        for (; v < _.length; ) {
          const k = _.charCodeAt(v);
          if (i(k))
            this.result = this.result * 10 + (k - r.ZERO), this.consumed++, v++;
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
      emitNumericEntity(_, v) {
        var k;
        if (this.consumed <= v)
          return (k = this.errors) === null || k === void 0 || k.absenceOfDigitsInNumericCharacterReference(this.consumed), 0;
        if (_ === r.SEMI)
          this.consumed += 1;
        else if (this.decodeMode === A.Strict)
          return 0;
        return this.emitCodePoint((0, u.replaceCodePoint)(this.result), this.consumed), this.errors && (_ !== r.SEMI && this.errors.missingSemicolonAfterCharacterReference(), this.errors.validateNumericCharacterReference(this.result)), this.consumed;
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
      stateNamedEntity(_, v) {
        const { decodeTree: k } = this;
        let S = k[this.treeIndex], F = (S & a.BinTrieFlags.VALUE_LENGTH) >> 14;
        for (; v < _.length; ) {
          if (F === 0 && (S & a.BinTrieFlags.FLAG13) !== 0) {
            const T = (S & a.BinTrieFlags.BRANCH_LENGTH) >> 7;
            if (this.runConsumed === 0) {
              const M = S & a.BinTrieFlags.JUMP_TABLE;
              if (_.charCodeAt(v) !== M)
                return this.result === 0 ? 0 : this.emitNotTerminatedNamedEntity();
              v++, this.excess++, this.runConsumed++;
            }
            for (; this.runConsumed < T; ) {
              if (v >= _.length)
                return -1;
              const M = this.runConsumed - 1, N = k[this.treeIndex + 1 + (M >> 1)], P = M % 2 === 0 ? N & 255 : N >> 8 & 255;
              if (_.charCodeAt(v) !== P)
                return this.runConsumed = 0, this.result === 0 ? 0 : this.emitNotTerminatedNamedEntity();
              v++, this.excess++, this.runConsumed++;
            }
            this.runConsumed = 0, this.treeIndex += 1 + (T >> 1), S = k[this.treeIndex], F = (S & a.BinTrieFlags.VALUE_LENGTH) >> 14;
          }
          if (v >= _.length)
            break;
          const I = _.charCodeAt(v);
          if (I === r.SEMI && F !== 0 && (S & a.BinTrieFlags.FLAG13) !== 0)
            return this.emitNamedEntityData(this.treeIndex, F, this.consumed + this.excess);
          if (this.treeIndex = y(k, S, this.treeIndex + Math.max(1, F), I), this.treeIndex < 0)
            return this.result === 0 || // If we are parsing an attribute
            this.decodeMode === A.Attribute && // We shouldn't have consumed any characters after the entity,
            (F === 0 || // And there should be no invalid characters.
            l(I)) ? 0 : this.emitNotTerminatedNamedEntity();
          if (S = k[this.treeIndex], F = (S & a.BinTrieFlags.VALUE_LENGTH) >> 14, F !== 0) {
            if (I === r.SEMI)
              return this.emitNamedEntityData(this.treeIndex, F, this.consumed + this.excess);
            this.decodeMode !== A.Strict && (S & a.BinTrieFlags.FLAG13) === 0 && (this.result = this.treeIndex, this.consumed += this.excess, this.excess = 0);
          }
          v++, this.excess++;
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
        const { result: v, decodeTree: k } = this, S = (k[v] & a.BinTrieFlags.VALUE_LENGTH) >> 14;
        return this.emitNamedEntityData(v, S, this.consumed), (_ = this.errors) === null || _ === void 0 || _.missingSemicolonAfterCharacterReference(), this.consumed;
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
      emitNamedEntityData(_, v, k) {
        const { decodeTree: S } = this;
        return this.emitCodePoint(v === 1 ? S[_] & ~(a.BinTrieFlags.VALUE_LENGTH | a.BinTrieFlags.FLAG13) : S[_ + 1], k), v === 3 && this.emitCodePoint(S[_ + 2], k), k;
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
            return this.result !== 0 && (this.decodeMode !== A.Attribute || this.result === this.treeIndex) ? this.emitNotTerminatedNamedEntity() : 0;
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
    e.EntityDecoder = d;
    function h(E) {
      let _ = "";
      const v = new d(E, (k) => _ += (0, u.fromCodePoint)(k));
      return function(S, F) {
        let I = 0, T = 0;
        for (; (T = S.indexOf("&", T)) >= 0; ) {
          _ += S.slice(I, T), v.startEntity(F);
          const N = v.write(
            S,
            // Skip the "&"
            T + 1
          );
          if (N < 0) {
            I = T + v.end();
            break;
          }
          I = T + N, T = N === 0 ? I + 1 : I;
        }
        const M = _ + S.slice(I);
        return _ = "", M;
      };
    }
    function y(E, _, v, k) {
      const S = (_ & a.BinTrieFlags.BRANCH_LENGTH) >> 7, F = _ & a.BinTrieFlags.JUMP_TABLE;
      if (S === 0)
        return F !== 0 && k === F ? v : -1;
      if (F) {
        const N = k - F;
        return N < 0 || N >= S ? -1 : E[v + N] - 1;
      }
      const I = S + 1 >> 1;
      let T = 0, M = S - 1;
      for (; T <= M; ) {
        const N = T + M >>> 1, P = N >> 1, H = E[v + P] >> (N & 1) * 8 & 255;
        if (H < k)
          T = N + 1;
        else if (H > k)
          M = N - 1;
        else
          return E[v + I + N];
      }
      return -1;
    }
    const C = /* @__PURE__ */ h(t.htmlDecodeTree), w = /* @__PURE__ */ h(s.xmlDecodeTree);
    function b(E, _ = A.Legacy) {
      return C(E, _);
    }
    function x(E) {
      return C(E, A.Attribute);
    }
    function m(E) {
      return C(E, A.Strict);
    }
    function p(E) {
      return w(E, A.Strict);
    }
    var g = lr();
    Object.defineProperty(e, "decodeCodePoint", { enumerable: !0, get: function() {
      return g.decodeCodePoint;
    } }), Object.defineProperty(e, "fromCodePoint", { enumerable: !0, get: function() {
      return g.fromCodePoint;
    } }), Object.defineProperty(e, "replaceCodePoint", { enumerable: !0, get: function() {
      return g.replaceCodePoint;
    } });
    var D = Ar();
    Object.defineProperty(e, "htmlDecodeTree", { enumerable: !0, get: function() {
      return D.htmlDecodeTree;
    } });
    var B = br();
    Object.defineProperty(e, "xmlDecodeTree", { enumerable: !0, get: function() {
      return B.xmlDecodeTree;
    } });
  })(Gu)), Gu;
}
var mr;
function cn() {
  if (mr) return He;
  mr = 1, Object.defineProperty(He, "__esModule", { value: !0 }), He.QuoteType = void 0;
  const e = /* @__PURE__ */ sn();
  var u;
  (function(n) {
    n[n.Tab = 9] = "Tab", n[n.NewLine = 10] = "NewLine", n[n.FormFeed = 12] = "FormFeed", n[n.CarriageReturn = 13] = "CarriageReturn", n[n.Space = 32] = "Space", n[n.ExclamationMark = 33] = "ExclamationMark", n[n.Number = 35] = "Number", n[n.Amp = 38] = "Amp", n[n.SingleQuote = 39] = "SingleQuote", n[n.DoubleQuote = 34] = "DoubleQuote", n[n.Dash = 45] = "Dash", n[n.Slash = 47] = "Slash", n[n.Zero = 48] = "Zero", n[n.Nine = 57] = "Nine", n[n.Semi = 59] = "Semi", n[n.Lt = 60] = "Lt", n[n.Eq = 61] = "Eq", n[n.Gt = 62] = "Gt", n[n.Questionmark = 63] = "Questionmark", n[n.UpperA = 65] = "UpperA", n[n.LowerA = 97] = "LowerA", n[n.UpperF = 70] = "UpperF", n[n.LowerF = 102] = "LowerF", n[n.UpperZ = 90] = "UpperZ", n[n.LowerZ = 122] = "LowerZ", n[n.LowerX = 120] = "LowerX", n[n.OpeningSquareBracket = 91] = "OpeningSquareBracket";
  })(u || (u = {}));
  var t;
  (function(n) {
    n[n.Text = 1] = "Text", n[n.BeforeTagName = 2] = "BeforeTagName", n[n.InTagName = 3] = "InTagName", n[n.InSelfClosingTag = 4] = "InSelfClosingTag", n[n.BeforeClosingTagName = 5] = "BeforeClosingTagName", n[n.InClosingTagName = 6] = "InClosingTagName", n[n.AfterClosingTagName = 7] = "AfterClosingTagName", n[n.BeforeAttributeName = 8] = "BeforeAttributeName", n[n.InAttributeName = 9] = "InAttributeName", n[n.AfterAttributeName = 10] = "AfterAttributeName", n[n.BeforeAttributeValue = 11] = "BeforeAttributeValue", n[n.InAttributeValueDq = 12] = "InAttributeValueDq", n[n.InAttributeValueSq = 13] = "InAttributeValueSq", n[n.InAttributeValueNq = 14] = "InAttributeValueNq", n[n.BeforeDeclaration = 15] = "BeforeDeclaration", n[n.InDeclaration = 16] = "InDeclaration", n[n.InProcessingInstruction = 17] = "InProcessingInstruction", n[n.BeforeComment = 18] = "BeforeComment", n[n.CDATASequence = 19] = "CDATASequence", n[n.InSpecialComment = 20] = "InSpecialComment", n[n.InCommentLike = 21] = "InCommentLike", n[n.BeforeSpecialS = 22] = "BeforeSpecialS", n[n.BeforeSpecialT = 23] = "BeforeSpecialT", n[n.SpecialStartSequence = 24] = "SpecialStartSequence", n[n.InSpecialTag = 25] = "InSpecialTag", n[n.InEntity = 26] = "InEntity";
  })(t || (t = {}));
  function s(n) {
    return n === u.Space || n === u.NewLine || n === u.Tab || n === u.FormFeed || n === u.CarriageReturn;
  }
  function a(n) {
    return n === u.Slash || n === u.Gt || s(n);
  }
  function r(n) {
    return n >= u.LowerA && n <= u.LowerZ || n >= u.UpperA && n <= u.UpperZ;
  }
  var o;
  (function(n) {
    n[n.NoValue = 0] = "NoValue", n[n.Unquoted = 1] = "Unquoted", n[n.Single = 2] = "Single", n[n.Double = 3] = "Double";
  })(o || (He.QuoteType = o = {}));
  const i = {
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
  let c = class {
    constructor({ xmlMode: l = !1, decodeEntities: f = !0 }, A) {
      this.cbs = A, this.state = t.Text, this.buffer = "", this.sectionStart = 0, this.index = 0, this.entityStart = 0, this.baseState = t.Text, this.isSpecial = !1, this.running = !0, this.offset = 0, this.currentSequence = void 0, this.sequenceIndex = 0, this.xmlMode = l, this.decodeEntities = f, this.entityDecoder = new e.EntityDecoder(l ? e.xmlDecodeTree : e.htmlDecodeTree, (d, h) => this.emitCodePoint(d, h));
    }
    reset() {
      this.state = t.Text, this.buffer = "", this.sectionStart = 0, this.index = 0, this.baseState = t.Text, this.currentSequence = void 0, this.running = !0, this.offset = 0;
    }
    write(l) {
      this.offset += this.buffer.length, this.buffer = l, this.parse();
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
    stateText(l) {
      l === u.Lt || !this.decodeEntities && this.fastForwardTo(u.Lt) ? (this.index > this.sectionStart && this.cbs.ontext(this.sectionStart, this.index), this.state = t.BeforeTagName, this.sectionStart = this.index) : this.decodeEntities && l === u.Amp && this.startEntity();
    }
    stateSpecialStartSequence(l) {
      const f = this.sequenceIndex === this.currentSequence.length;
      if (!(f ? (
        // If we are at the end of the sequence, make sure the tag name has ended
        a(l)
      ) : (
        // Otherwise, do a case-insensitive comparison
        (l | 32) === this.currentSequence[this.sequenceIndex]
      )))
        this.isSpecial = !1;
      else if (!f) {
        this.sequenceIndex++;
        return;
      }
      this.sequenceIndex = 0, this.state = t.InTagName, this.stateInTagName(l);
    }
    /** Look for an end tag. For <title> tags, also decode entities. */
    stateInSpecialTag(l) {
      if (this.sequenceIndex === this.currentSequence.length) {
        if (l === u.Gt || s(l)) {
          const f = this.index - this.currentSequence.length;
          if (this.sectionStart < f) {
            const A = this.index;
            this.index = f, this.cbs.ontext(this.sectionStart, f), this.index = A;
          }
          this.isSpecial = !1, this.sectionStart = f + 2, this.stateInClosingTagName(l);
          return;
        }
        this.sequenceIndex = 0;
      }
      (l | 32) === this.currentSequence[this.sequenceIndex] ? this.sequenceIndex += 1 : this.sequenceIndex === 0 ? this.currentSequence === i.TitleEnd ? this.decodeEntities && l === u.Amp && this.startEntity() : this.fastForwardTo(u.Lt) && (this.sequenceIndex = 1) : this.sequenceIndex = +(l === u.Lt);
    }
    stateCDATASequence(l) {
      l === i.Cdata[this.sequenceIndex] ? ++this.sequenceIndex === i.Cdata.length && (this.state = t.InCommentLike, this.currentSequence = i.CdataEnd, this.sequenceIndex = 0, this.sectionStart = this.index + 1) : (this.sequenceIndex = 0, this.state = t.InDeclaration, this.stateInDeclaration(l));
    }
    /**
     * When we wait for one specific character, we can speed things up
     * by skipping through the buffer until we find it.
     *
     * @returns Whether the character was found.
     */
    fastForwardTo(l) {
      for (; ++this.index < this.buffer.length + this.offset; )
        if (this.buffer.charCodeAt(this.index - this.offset) === l)
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
    stateInCommentLike(l) {
      l === this.currentSequence[this.sequenceIndex] ? ++this.sequenceIndex === this.currentSequence.length && (this.currentSequence === i.CdataEnd ? this.cbs.oncdata(this.sectionStart, this.index, 2) : this.cbs.oncomment(this.sectionStart, this.index, 2), this.sequenceIndex = 0, this.sectionStart = this.index + 1, this.state = t.Text) : this.sequenceIndex === 0 ? this.fastForwardTo(this.currentSequence[0]) && (this.sequenceIndex = 1) : l !== this.currentSequence[this.sequenceIndex - 1] && (this.sequenceIndex = 0);
    }
    /**
     * HTML only allows ASCII alpha characters (a-z and A-Z) at the beginning of a tag name.
     *
     * XML allows a lot more characters here (@see https://www.w3.org/TR/REC-xml/#NT-NameStartChar).
     * We allow anything that wouldn't end the tag.
     */
    isTagStartChar(l) {
      return this.xmlMode ? !a(l) : r(l);
    }
    startSpecial(l, f) {
      this.isSpecial = !0, this.currentSequence = l, this.sequenceIndex = f, this.state = t.SpecialStartSequence;
    }
    stateBeforeTagName(l) {
      if (l === u.ExclamationMark)
        this.state = t.BeforeDeclaration, this.sectionStart = this.index + 1;
      else if (l === u.Questionmark)
        this.state = t.InProcessingInstruction, this.sectionStart = this.index + 1;
      else if (this.isTagStartChar(l)) {
        const f = l | 32;
        this.sectionStart = this.index, this.xmlMode ? this.state = t.InTagName : f === i.ScriptEnd[2] ? this.state = t.BeforeSpecialS : f === i.TitleEnd[2] || f === i.XmpEnd[2] ? this.state = t.BeforeSpecialT : this.state = t.InTagName;
      } else l === u.Slash ? this.state = t.BeforeClosingTagName : (this.state = t.Text, this.stateText(l));
    }
    stateInTagName(l) {
      a(l) && (this.cbs.onopentagname(this.sectionStart, this.index), this.sectionStart = -1, this.state = t.BeforeAttributeName, this.stateBeforeAttributeName(l));
    }
    stateBeforeClosingTagName(l) {
      s(l) || (l === u.Gt ? this.state = t.Text : (this.state = this.isTagStartChar(l) ? t.InClosingTagName : t.InSpecialComment, this.sectionStart = this.index));
    }
    stateInClosingTagName(l) {
      (l === u.Gt || s(l)) && (this.cbs.onclosetag(this.sectionStart, this.index), this.sectionStart = -1, this.state = t.AfterClosingTagName, this.stateAfterClosingTagName(l));
    }
    stateAfterClosingTagName(l) {
      (l === u.Gt || this.fastForwardTo(u.Gt)) && (this.state = t.Text, this.sectionStart = this.index + 1);
    }
    stateBeforeAttributeName(l) {
      l === u.Gt ? (this.cbs.onopentagend(this.index), this.isSpecial ? (this.state = t.InSpecialTag, this.sequenceIndex = 0) : this.state = t.Text, this.sectionStart = this.index + 1) : l === u.Slash ? this.state = t.InSelfClosingTag : s(l) || (this.state = t.InAttributeName, this.sectionStart = this.index);
    }
    stateInSelfClosingTag(l) {
      l === u.Gt ? (this.cbs.onselfclosingtag(this.index), this.state = t.Text, this.sectionStart = this.index + 1, this.isSpecial = !1) : s(l) || (this.state = t.BeforeAttributeName, this.stateBeforeAttributeName(l));
    }
    stateInAttributeName(l) {
      (l === u.Eq || a(l)) && (this.cbs.onattribname(this.sectionStart, this.index), this.sectionStart = this.index, this.state = t.AfterAttributeName, this.stateAfterAttributeName(l));
    }
    stateAfterAttributeName(l) {
      l === u.Eq ? this.state = t.BeforeAttributeValue : l === u.Slash || l === u.Gt ? (this.cbs.onattribend(o.NoValue, this.sectionStart), this.sectionStart = -1, this.state = t.BeforeAttributeName, this.stateBeforeAttributeName(l)) : s(l) || (this.cbs.onattribend(o.NoValue, this.sectionStart), this.state = t.InAttributeName, this.sectionStart = this.index);
    }
    stateBeforeAttributeValue(l) {
      l === u.DoubleQuote ? (this.state = t.InAttributeValueDq, this.sectionStart = this.index + 1) : l === u.SingleQuote ? (this.state = t.InAttributeValueSq, this.sectionStart = this.index + 1) : s(l) || (this.sectionStart = this.index, this.state = t.InAttributeValueNq, this.stateInAttributeValueNoQuotes(l));
    }
    handleInAttributeValue(l, f) {
      l === f || !this.decodeEntities && this.fastForwardTo(f) ? (this.cbs.onattribdata(this.sectionStart, this.index), this.sectionStart = -1, this.cbs.onattribend(f === u.DoubleQuote ? o.Double : o.Single, this.index + 1), this.state = t.BeforeAttributeName) : this.decodeEntities && l === u.Amp && this.startEntity();
    }
    stateInAttributeValueDoubleQuotes(l) {
      this.handleInAttributeValue(l, u.DoubleQuote);
    }
    stateInAttributeValueSingleQuotes(l) {
      this.handleInAttributeValue(l, u.SingleQuote);
    }
    stateInAttributeValueNoQuotes(l) {
      s(l) || l === u.Gt ? (this.cbs.onattribdata(this.sectionStart, this.index), this.sectionStart = -1, this.cbs.onattribend(o.Unquoted, this.index), this.state = t.BeforeAttributeName, this.stateBeforeAttributeName(l)) : this.decodeEntities && l === u.Amp && this.startEntity();
    }
    stateBeforeDeclaration(l) {
      l === u.OpeningSquareBracket ? (this.state = t.CDATASequence, this.sequenceIndex = 0) : this.state = l === u.Dash ? t.BeforeComment : t.InDeclaration;
    }
    stateInDeclaration(l) {
      (l === u.Gt || this.fastForwardTo(u.Gt)) && (this.cbs.ondeclaration(this.sectionStart, this.index), this.state = t.Text, this.sectionStart = this.index + 1);
    }
    stateInProcessingInstruction(l) {
      (l === u.Gt || this.fastForwardTo(u.Gt)) && (this.cbs.onprocessinginstruction(this.sectionStart, this.index), this.state = t.Text, this.sectionStart = this.index + 1);
    }
    stateBeforeComment(l) {
      l === u.Dash ? (this.state = t.InCommentLike, this.currentSequence = i.CommentEnd, this.sequenceIndex = 2, this.sectionStart = this.index + 1) : this.state = t.InDeclaration;
    }
    stateInSpecialComment(l) {
      (l === u.Gt || this.fastForwardTo(u.Gt)) && (this.cbs.oncomment(this.sectionStart, this.index, 0), this.state = t.Text, this.sectionStart = this.index + 1);
    }
    stateBeforeSpecialS(l) {
      const f = l | 32;
      f === i.ScriptEnd[3] ? this.startSpecial(i.ScriptEnd, 4) : f === i.StyleEnd[3] ? this.startSpecial(i.StyleEnd, 4) : (this.state = t.InTagName, this.stateInTagName(l));
    }
    stateBeforeSpecialT(l) {
      switch (l | 32) {
        case i.TitleEnd[3]: {
          this.startSpecial(i.TitleEnd, 4);
          break;
        }
        case i.TextareaEnd[3]: {
          this.startSpecial(i.TextareaEnd, 4);
          break;
        }
        case i.XmpEnd[3]: {
          this.startSpecial(i.XmpEnd, 4);
          break;
        }
        default:
          this.state = t.InTagName, this.stateInTagName(l);
      }
    }
    startEntity() {
      this.baseState = this.state, this.state = t.InEntity, this.entityStart = this.index, this.entityDecoder.startEntity(this.xmlMode ? e.DecodingMode.Strict : this.baseState === t.Text || this.baseState === t.InSpecialTag ? e.DecodingMode.Legacy : e.DecodingMode.Attribute);
    }
    stateInEntity() {
      const l = this.index - this.offset, f = this.entityDecoder.write(this.buffer, l);
      if (f >= 0)
        this.state = this.baseState, f === 0 && (this.index -= 1);
      else {
        if (l < this.buffer.length && this.buffer.charCodeAt(l) === u.Amp) {
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
        const l = this.buffer.charCodeAt(this.index - this.offset);
        switch (this.state) {
          case t.Text: {
            this.stateText(l);
            break;
          }
          case t.SpecialStartSequence: {
            this.stateSpecialStartSequence(l);
            break;
          }
          case t.InSpecialTag: {
            this.stateInSpecialTag(l);
            break;
          }
          case t.CDATASequence: {
            this.stateCDATASequence(l);
            break;
          }
          case t.InAttributeValueDq: {
            this.stateInAttributeValueDoubleQuotes(l);
            break;
          }
          case t.InAttributeName: {
            this.stateInAttributeName(l);
            break;
          }
          case t.InCommentLike: {
            this.stateInCommentLike(l);
            break;
          }
          case t.InSpecialComment: {
            this.stateInSpecialComment(l);
            break;
          }
          case t.BeforeAttributeName: {
            this.stateBeforeAttributeName(l);
            break;
          }
          case t.InTagName: {
            this.stateInTagName(l);
            break;
          }
          case t.InClosingTagName: {
            this.stateInClosingTagName(l);
            break;
          }
          case t.BeforeTagName: {
            this.stateBeforeTagName(l);
            break;
          }
          case t.AfterAttributeName: {
            this.stateAfterAttributeName(l);
            break;
          }
          case t.InAttributeValueSq: {
            this.stateInAttributeValueSingleQuotes(l);
            break;
          }
          case t.BeforeAttributeValue: {
            this.stateBeforeAttributeValue(l);
            break;
          }
          case t.BeforeClosingTagName: {
            this.stateBeforeClosingTagName(l);
            break;
          }
          case t.AfterClosingTagName: {
            this.stateAfterClosingTagName(l);
            break;
          }
          case t.BeforeSpecialS: {
            this.stateBeforeSpecialS(l);
            break;
          }
          case t.BeforeSpecialT: {
            this.stateBeforeSpecialT(l);
            break;
          }
          case t.InAttributeValueNq: {
            this.stateInAttributeValueNoQuotes(l);
            break;
          }
          case t.InSelfClosingTag: {
            this.stateInSelfClosingTag(l);
            break;
          }
          case t.InDeclaration: {
            this.stateInDeclaration(l);
            break;
          }
          case t.BeforeDeclaration: {
            this.stateBeforeDeclaration(l);
            break;
          }
          case t.BeforeComment: {
            this.stateBeforeComment(l);
            break;
          }
          case t.InProcessingInstruction: {
            this.stateInProcessingInstruction(l);
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
      const l = this.buffer.length + this.offset;
      this.sectionStart >= l || (this.state === t.InCommentLike ? this.currentSequence === i.CdataEnd ? this.cbs.oncdata(this.sectionStart, l, 0) : this.cbs.oncomment(this.sectionStart, l, 0) : this.state === t.InTagName || this.state === t.BeforeAttributeName || this.state === t.BeforeAttributeValue || this.state === t.AfterAttributeName || this.state === t.InAttributeName || this.state === t.InAttributeValueSq || this.state === t.InAttributeValueDq || this.state === t.InAttributeValueNq || this.state === t.InClosingTagName || this.cbs.ontext(this.sectionStart, l));
    }
    emitCodePoint(l, f) {
      this.baseState !== t.Text && this.baseState !== t.InSpecialTag ? (this.sectionStart < this.entityStart && this.cbs.onattribdata(this.sectionStart, this.entityStart), this.sectionStart = this.entityStart + f, this.index = this.sectionStart - 1, this.cbs.onattribentity(l)) : (this.sectionStart < this.entityStart && this.cbs.ontext(this.sectionStart, this.entityStart), this.sectionStart = this.entityStart + f, this.index = this.sectionStart - 1, this.cbs.ontextentity(l, this.sectionStart));
    }
  };
  return He.default = c, He;
}
var xr;
function yr() {
  if (xr) return he;
  xr = 1;
  var e = he && he.__createBinding || (Object.create ? (function(C, w, b, x) {
    x === void 0 && (x = b);
    var m = Object.getOwnPropertyDescriptor(w, b);
    (!m || ("get" in m ? !w.__esModule : m.writable || m.configurable)) && (m = { enumerable: !0, get: function() {
      return w[b];
    } }), Object.defineProperty(C, x, m);
  }) : (function(C, w, b, x) {
    x === void 0 && (x = b), C[x] = w[b];
  })), u = he && he.__setModuleDefault || (Object.create ? (function(C, w) {
    Object.defineProperty(C, "default", { enumerable: !0, value: w });
  }) : function(C, w) {
    C.default = w;
  }), t = he && he.__importStar || /* @__PURE__ */ (function() {
    var C = function(w) {
      return C = Object.getOwnPropertyNames || function(b) {
        var x = [];
        for (var m in b) Object.prototype.hasOwnProperty.call(b, m) && (x[x.length] = m);
        return x;
      }, C(w);
    };
    return function(w) {
      if (w && w.__esModule) return w;
      var b = {};
      if (w != null) for (var x = C(w), m = 0; m < x.length; m++) x[m] !== "default" && e(b, w, x[m]);
      return u(b, w), b;
    };
  })();
  Object.defineProperty(he, "__esModule", { value: !0 }), he.Parser = void 0;
  const s = t(cn()), a = /* @__PURE__ */ sn(), r = /* @__PURE__ */ new Set([
    "input",
    "option",
    "optgroup",
    "select",
    "button",
    "datalist",
    "textarea"
  ]), o = /* @__PURE__ */ new Set(["p"]), i = /* @__PURE__ */ new Set(["thead", "tbody"]), c = /* @__PURE__ */ new Set(["dd", "dt"]), n = /* @__PURE__ */ new Set(["rt", "rp"]), l = /* @__PURE__ */ new Map([
    ["tr", /* @__PURE__ */ new Set(["tr", "th", "td"])],
    ["th", /* @__PURE__ */ new Set(["th"])],
    ["td", /* @__PURE__ */ new Set(["thead", "th", "td"])],
    ["body", /* @__PURE__ */ new Set(["head", "link", "script"])],
    ["li", /* @__PURE__ */ new Set(["li"])],
    ["p", o],
    ["h1", o],
    ["h2", o],
    ["h3", o],
    ["h4", o],
    ["h5", o],
    ["h6", o],
    ["select", r],
    ["input", r],
    ["output", r],
    ["button", r],
    ["datalist", r],
    ["textarea", r],
    ["option", /* @__PURE__ */ new Set(["option"])],
    ["optgroup", /* @__PURE__ */ new Set(["optgroup", "option"])],
    ["dd", c],
    ["dt", c],
    ["address", o],
    ["article", o],
    ["aside", o],
    ["blockquote", o],
    ["details", o],
    ["div", o],
    ["dl", o],
    ["fieldset", o],
    ["figcaption", o],
    ["figure", o],
    ["footer", o],
    ["form", o],
    ["header", o],
    ["hr", o],
    ["main", o],
    ["nav", o],
    ["ol", o],
    ["pre", o],
    ["section", o],
    ["table", o],
    ["ul", o],
    ["rt", n],
    ["rp", n],
    ["tbody", i],
    ["tfoot", i]
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
  ]), A = /* @__PURE__ */ new Set(["math", "svg"]), d = /* @__PURE__ */ new Set([
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
  let y = class {
    constructor(w, b = {}) {
      var x, m, p, g, D, B;
      this.options = b, this.startIndex = 0, this.endIndex = 0, this.openTagStart = 0, this.tagname = "", this.attribname = "", this.attribvalue = "", this.attribs = null, this.stack = [], this.buffers = [], this.bufferOffset = 0, this.writeIndex = 0, this.ended = !1, this.cbs = w ?? {}, this.htmlMode = !this.options.xmlMode, this.lowerCaseTagNames = (x = b.lowerCaseTags) !== null && x !== void 0 ? x : this.htmlMode, this.lowerCaseAttributeNames = (m = b.lowerCaseAttributeNames) !== null && m !== void 0 ? m : this.htmlMode, this.recognizeSelfClosing = (p = b.recognizeSelfClosing) !== null && p !== void 0 ? p : !this.htmlMode, this.tokenizer = new ((g = b.Tokenizer) !== null && g !== void 0 ? g : s.default)(this.options, this), this.foreignContext = [!this.htmlMode], (B = (D = this.cbs).onparserinit) === null || B === void 0 || B.call(D, this);
    }
    // Tokenizer event handlers
    /** @internal */
    ontext(w, b) {
      var x, m;
      const p = this.getSlice(w, b);
      this.endIndex = b - 1, (m = (x = this.cbs).ontext) === null || m === void 0 || m.call(x, p), this.startIndex = b;
    }
    /** @internal */
    ontextentity(w, b) {
      var x, m;
      this.endIndex = b - 1, (m = (x = this.cbs).ontext) === null || m === void 0 || m.call(x, (0, a.fromCodePoint)(w)), this.startIndex = b;
    }
    /**
     * Checks if the current tag is a void element. Override this if you want
     * to specify your own additional void elements.
     */
    isVoidElement(w) {
      return this.htmlMode && f.has(w);
    }
    /** @internal */
    onopentagname(w, b) {
      this.endIndex = b;
      let x = this.getSlice(w, b);
      this.lowerCaseTagNames && (x = x.toLowerCase()), this.emitOpenTag(x);
    }
    emitOpenTag(w) {
      var b, x, m, p;
      this.openTagStart = this.startIndex, this.tagname = w;
      const g = this.htmlMode && l.get(w);
      if (g)
        for (; this.stack.length > 0 && g.has(this.stack[0]); ) {
          const D = this.stack.shift();
          (x = (b = this.cbs).onclosetag) === null || x === void 0 || x.call(b, D, !0);
        }
      this.isVoidElement(w) || (this.stack.unshift(w), this.htmlMode && (A.has(w) ? this.foreignContext.unshift(!0) : d.has(w) && this.foreignContext.unshift(!1))), (p = (m = this.cbs).onopentagname) === null || p === void 0 || p.call(m, w), this.cbs.onopentag && (this.attribs = {});
    }
    endOpenTag(w) {
      var b, x;
      this.startIndex = this.openTagStart, this.attribs && ((x = (b = this.cbs).onopentag) === null || x === void 0 || x.call(b, this.tagname, this.attribs, w), this.attribs = null), this.cbs.onclosetag && this.isVoidElement(this.tagname) && this.cbs.onclosetag(this.tagname, !0), this.tagname = "";
    }
    /** @internal */
    onopentagend(w) {
      this.endIndex = w, this.endOpenTag(!1), this.startIndex = w + 1;
    }
    /** @internal */
    onclosetag(w, b) {
      var x, m, p, g, D, B, E, _;
      this.endIndex = b;
      let v = this.getSlice(w, b);
      if (this.lowerCaseTagNames && (v = v.toLowerCase()), this.htmlMode && (A.has(v) || d.has(v)) && this.foreignContext.shift(), this.isVoidElement(v))
        this.htmlMode && v === "br" && ((g = (p = this.cbs).onopentagname) === null || g === void 0 || g.call(p, "br"), (B = (D = this.cbs).onopentag) === null || B === void 0 || B.call(D, "br", {}, !0), (_ = (E = this.cbs).onclosetag) === null || _ === void 0 || _.call(E, "br", !1));
      else {
        const k = this.stack.indexOf(v);
        if (k !== -1)
          for (let S = 0; S <= k; S++) {
            const F = this.stack.shift();
            (m = (x = this.cbs).onclosetag) === null || m === void 0 || m.call(x, F, S !== k);
          }
        else this.htmlMode && v === "p" && (this.emitOpenTag("p"), this.closeCurrentTag(!0));
      }
      this.startIndex = b + 1;
    }
    /** @internal */
    onselfclosingtag(w) {
      this.endIndex = w, this.recognizeSelfClosing || this.foreignContext[0] ? (this.closeCurrentTag(!1), this.startIndex = w + 1) : this.onopentagend(w);
    }
    closeCurrentTag(w) {
      var b, x;
      const m = this.tagname;
      this.endOpenTag(w), this.stack[0] === m && ((x = (b = this.cbs).onclosetag) === null || x === void 0 || x.call(b, m, !w), this.stack.shift());
    }
    /** @internal */
    onattribname(w, b) {
      this.startIndex = w;
      const x = this.getSlice(w, b);
      this.attribname = this.lowerCaseAttributeNames ? x.toLowerCase() : x;
    }
    /** @internal */
    onattribdata(w, b) {
      this.attribvalue += this.getSlice(w, b);
    }
    /** @internal */
    onattribentity(w) {
      this.attribvalue += (0, a.fromCodePoint)(w);
    }
    /** @internal */
    onattribend(w, b) {
      var x, m;
      this.endIndex = b, (m = (x = this.cbs).onattribute) === null || m === void 0 || m.call(x, this.attribname, this.attribvalue, w === s.QuoteType.Double ? '"' : w === s.QuoteType.Single ? "'" : w === s.QuoteType.NoValue ? void 0 : null), this.attribs && !Object.prototype.hasOwnProperty.call(this.attribs, this.attribname) && (this.attribs[this.attribname] = this.attribvalue), this.attribvalue = "";
    }
    getInstructionName(w) {
      const b = w.search(h);
      let x = b < 0 ? w : w.substr(0, b);
      return this.lowerCaseTagNames && (x = x.toLowerCase()), x;
    }
    /** @internal */
    ondeclaration(w, b) {
      this.endIndex = b;
      const x = this.getSlice(w, b);
      if (this.cbs.onprocessinginstruction) {
        const m = this.getInstructionName(x);
        this.cbs.onprocessinginstruction(`!${m}`, `!${x}`);
      }
      this.startIndex = b + 1;
    }
    /** @internal */
    onprocessinginstruction(w, b) {
      this.endIndex = b;
      const x = this.getSlice(w, b);
      if (this.cbs.onprocessinginstruction) {
        const m = this.getInstructionName(x);
        this.cbs.onprocessinginstruction(`?${m}`, `?${x}`);
      }
      this.startIndex = b + 1;
    }
    /** @internal */
    oncomment(w, b, x) {
      var m, p, g, D;
      this.endIndex = b, (p = (m = this.cbs).oncomment) === null || p === void 0 || p.call(m, this.getSlice(w, b - x)), (D = (g = this.cbs).oncommentend) === null || D === void 0 || D.call(g), this.startIndex = b + 1;
    }
    /** @internal */
    oncdata(w, b, x) {
      var m, p, g, D, B, E, _, v, k, S;
      this.endIndex = b;
      const F = this.getSlice(w, b - x);
      !this.htmlMode || this.options.recognizeCDATA ? ((p = (m = this.cbs).oncdatastart) === null || p === void 0 || p.call(m), (D = (g = this.cbs).ontext) === null || D === void 0 || D.call(g, F), (E = (B = this.cbs).oncdataend) === null || E === void 0 || E.call(B)) : ((v = (_ = this.cbs).oncomment) === null || v === void 0 || v.call(_, `[CDATA[${F}]]`), (S = (k = this.cbs).oncommentend) === null || S === void 0 || S.call(k)), this.startIndex = b + 1;
    }
    /** @internal */
    onend() {
      var w, b;
      if (this.cbs.onclosetag) {
        this.endIndex = this.startIndex;
        for (let x = 0; x < this.stack.length; x++)
          this.cbs.onclosetag(this.stack[x], !0);
      }
      (b = (w = this.cbs).onend) === null || b === void 0 || b.call(w);
    }
    /**
     * Resets the parser to a blank state, ready to parse a new HTML document
     */
    reset() {
      var w, b, x, m;
      (b = (w = this.cbs).onreset) === null || b === void 0 || b.call(w), this.tokenizer.reset(), this.tagname = "", this.attribname = "", this.attribs = null, this.stack.length = 0, this.startIndex = 0, this.endIndex = 0, (m = (x = this.cbs).onparserinit) === null || m === void 0 || m.call(x, this), this.buffers.length = 0, this.foreignContext.length = 0, this.foreignContext.unshift(!this.htmlMode), this.bufferOffset = 0, this.writeIndex = 0, this.ended = !1;
    }
    /**
     * Resets the parser, then parses a complete document and
     * pushes it to the handler.
     *
     * @param data Document to parse.
     */
    parseComplete(w) {
      this.reset(), this.end(w);
    }
    getSlice(w, b) {
      for (; w - this.bufferOffset >= this.buffers[0].length; )
        this.shiftBuffer();
      let x = this.buffers[0].slice(w - this.bufferOffset, b - this.bufferOffset);
      for (; b - this.bufferOffset > this.buffers[0].length; )
        this.shiftBuffer(), x += this.buffers[0].slice(0, b - this.bufferOffset);
      return x;
    }
    shiftBuffer() {
      this.bufferOffset += this.buffers[0].length, this.writeIndex--, this.buffers.shift();
    }
    /**
     * Parses a chunk of data and calls the corresponding callbacks.
     *
     * @param chunk Chunk to parse.
     */
    write(w) {
      var b, x;
      if (this.ended) {
        (x = (b = this.cbs).onerror) === null || x === void 0 || x.call(b, new Error(".write() after done!"));
        return;
      }
      this.buffers.push(w), this.tokenizer.running && (this.tokenizer.write(w), this.writeIndex++);
    }
    /**
     * Parses the end of the buffer and clears the stack, calls onend.
     *
     * @param chunk Optional final chunk to parse.
     */
    end(w) {
      var b, x;
      if (this.ended) {
        (x = (b = this.cbs).onerror) === null || x === void 0 || x.call(b, new Error(".end() after done!"));
        return;
      }
      w && this.write(w), this.ended = !0, this.tokenizer.end();
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
    parseChunk(w) {
      this.write(w);
    }
    /**
     * Alias of `end`, for backwards compatibility.
     *
     * @param chunk Optional final chunk to parse.
     * @deprecated
     */
    done(w) {
      this.end(w);
    }
  };
  return he.Parser = y, he;
}
var Oe = {}, qu = {}, wr;
function tu() {
  return wr || (wr = 1, (function(e) {
    Object.defineProperty(e, "__esModule", { value: !0 }), e.Doctype = e.CDATA = e.Tag = e.Style = e.Script = e.Comment = e.Directive = e.Text = e.Root = e.isTag = e.ElementType = void 0;
    var u;
    (function(s) {
      s.Root = "root", s.Text = "text", s.Directive = "directive", s.Comment = "comment", s.Script = "script", s.Style = "style", s.Tag = "tag", s.CDATA = "cdata", s.Doctype = "doctype";
    })(u = e.ElementType || (e.ElementType = {}));
    function t(s) {
      return s.type === u.Tag || s.type === u.Script || s.type === u.Style;
    }
    e.isTag = t, e.Root = u.Root, e.Text = u.Text, e.Directive = u.Directive, e.Comment = u.Comment, e.Script = u.Script, e.Style = u.Style, e.Tag = u.Tag, e.CDATA = u.CDATA, e.Doctype = u.Doctype;
  })(qu)), qu;
}
var q = {}, Cr;
function vr() {
  if (Cr) return q;
  Cr = 1;
  var e = q && q.__extends || /* @__PURE__ */ (function() {
    var p = function(g, D) {
      return p = Object.setPrototypeOf || { __proto__: [] } instanceof Array && function(B, E) {
        B.__proto__ = E;
      } || function(B, E) {
        for (var _ in E) Object.prototype.hasOwnProperty.call(E, _) && (B[_] = E[_]);
      }, p(g, D);
    };
    return function(g, D) {
      if (typeof D != "function" && D !== null)
        throw new TypeError("Class extends value " + String(D) + " is not a constructor or null");
      p(g, D);
      function B() {
        this.constructor = g;
      }
      g.prototype = D === null ? Object.create(D) : (B.prototype = D.prototype, new B());
    };
  })(), u = q && q.__assign || function() {
    return u = Object.assign || function(p) {
      for (var g, D = 1, B = arguments.length; D < B; D++) {
        g = arguments[D];
        for (var E in g) Object.prototype.hasOwnProperty.call(g, E) && (p[E] = g[E]);
      }
      return p;
    }, u.apply(this, arguments);
  };
  Object.defineProperty(q, "__esModule", { value: !0 }), q.cloneNode = q.hasChildren = q.isDocument = q.isDirective = q.isComment = q.isText = q.isCDATA = q.isTag = q.Element = q.Document = q.CDATA = q.NodeWithChildren = q.ProcessingInstruction = q.Comment = q.Text = q.DataNode = q.Node = void 0;
  var t = /* @__PURE__ */ tu(), s = (
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
        set: function(g) {
          this.parent = g;
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
        set: function(g) {
          this.prev = g;
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
        set: function(g) {
          this.next = g;
        },
        enumerable: !1,
        configurable: !0
      }), p.prototype.cloneNode = function(g) {
        return g === void 0 && (g = !1), x(this, g);
      }, p;
    })()
  );
  q.Node = s;
  var a = (
    /** @class */
    (function(p) {
      e(g, p);
      function g(D) {
        var B = p.call(this) || this;
        return B.data = D, B;
      }
      return Object.defineProperty(g.prototype, "nodeValue", {
        /**
         * Same as {@link data}.
         * [DOM spec](https://dom.spec.whatwg.org)-compatible alias.
         */
        get: function() {
          return this.data;
        },
        set: function(D) {
          this.data = D;
        },
        enumerable: !1,
        configurable: !0
      }), g;
    })(s)
  );
  q.DataNode = a;
  var r = (
    /** @class */
    (function(p) {
      e(g, p);
      function g() {
        var D = p !== null && p.apply(this, arguments) || this;
        return D.type = t.ElementType.Text, D;
      }
      return Object.defineProperty(g.prototype, "nodeType", {
        get: function() {
          return 3;
        },
        enumerable: !1,
        configurable: !0
      }), g;
    })(a)
  );
  q.Text = r;
  var o = (
    /** @class */
    (function(p) {
      e(g, p);
      function g() {
        var D = p !== null && p.apply(this, arguments) || this;
        return D.type = t.ElementType.Comment, D;
      }
      return Object.defineProperty(g.prototype, "nodeType", {
        get: function() {
          return 8;
        },
        enumerable: !1,
        configurable: !0
      }), g;
    })(a)
  );
  q.Comment = o;
  var i = (
    /** @class */
    (function(p) {
      e(g, p);
      function g(D, B) {
        var E = p.call(this, B) || this;
        return E.name = D, E.type = t.ElementType.Directive, E;
      }
      return Object.defineProperty(g.prototype, "nodeType", {
        get: function() {
          return 1;
        },
        enumerable: !1,
        configurable: !0
      }), g;
    })(a)
  );
  q.ProcessingInstruction = i;
  var c = (
    /** @class */
    (function(p) {
      e(g, p);
      function g(D) {
        var B = p.call(this) || this;
        return B.children = D, B;
      }
      return Object.defineProperty(g.prototype, "firstChild", {
        // Aliases
        /** First child of the node. */
        get: function() {
          var D;
          return (D = this.children[0]) !== null && D !== void 0 ? D : null;
        },
        enumerable: !1,
        configurable: !0
      }), Object.defineProperty(g.prototype, "lastChild", {
        /** Last child of the node. */
        get: function() {
          return this.children.length > 0 ? this.children[this.children.length - 1] : null;
        },
        enumerable: !1,
        configurable: !0
      }), Object.defineProperty(g.prototype, "childNodes", {
        /**
         * Same as {@link children}.
         * [DOM spec](https://dom.spec.whatwg.org)-compatible alias.
         */
        get: function() {
          return this.children;
        },
        set: function(D) {
          this.children = D;
        },
        enumerable: !1,
        configurable: !0
      }), g;
    })(s)
  );
  q.NodeWithChildren = c;
  var n = (
    /** @class */
    (function(p) {
      e(g, p);
      function g() {
        var D = p !== null && p.apply(this, arguments) || this;
        return D.type = t.ElementType.CDATA, D;
      }
      return Object.defineProperty(g.prototype, "nodeType", {
        get: function() {
          return 4;
        },
        enumerable: !1,
        configurable: !0
      }), g;
    })(c)
  );
  q.CDATA = n;
  var l = (
    /** @class */
    (function(p) {
      e(g, p);
      function g() {
        var D = p !== null && p.apply(this, arguments) || this;
        return D.type = t.ElementType.Root, D;
      }
      return Object.defineProperty(g.prototype, "nodeType", {
        get: function() {
          return 9;
        },
        enumerable: !1,
        configurable: !0
      }), g;
    })(c)
  );
  q.Document = l;
  var f = (
    /** @class */
    (function(p) {
      e(g, p);
      function g(D, B, E, _) {
        E === void 0 && (E = []), _ === void 0 && (_ = D === "script" ? t.ElementType.Script : D === "style" ? t.ElementType.Style : t.ElementType.Tag);
        var v = p.call(this, E) || this;
        return v.name = D, v.attribs = B, v.type = _, v;
      }
      return Object.defineProperty(g.prototype, "nodeType", {
        get: function() {
          return 1;
        },
        enumerable: !1,
        configurable: !0
      }), Object.defineProperty(g.prototype, "tagName", {
        // DOM Level 1 aliases
        /**
         * Same as {@link name}.
         * [DOM spec](https://dom.spec.whatwg.org)-compatible alias.
         */
        get: function() {
          return this.name;
        },
        set: function(D) {
          this.name = D;
        },
        enumerable: !1,
        configurable: !0
      }), Object.defineProperty(g.prototype, "attributes", {
        get: function() {
          var D = this;
          return Object.keys(this.attribs).map(function(B) {
            var E, _;
            return {
              name: B,
              value: D.attribs[B],
              namespace: (E = D["x-attribsNamespace"]) === null || E === void 0 ? void 0 : E[B],
              prefix: (_ = D["x-attribsPrefix"]) === null || _ === void 0 ? void 0 : _[B]
            };
          });
        },
        enumerable: !1,
        configurable: !0
      }), g;
    })(c)
  );
  q.Element = f;
  function A(p) {
    return (0, t.isTag)(p);
  }
  q.isTag = A;
  function d(p) {
    return p.type === t.ElementType.CDATA;
  }
  q.isCDATA = d;
  function h(p) {
    return p.type === t.ElementType.Text;
  }
  q.isText = h;
  function y(p) {
    return p.type === t.ElementType.Comment;
  }
  q.isComment = y;
  function C(p) {
    return p.type === t.ElementType.Directive;
  }
  q.isDirective = C;
  function w(p) {
    return p.type === t.ElementType.Root;
  }
  q.isDocument = w;
  function b(p) {
    return Object.prototype.hasOwnProperty.call(p, "children");
  }
  q.hasChildren = b;
  function x(p, g) {
    g === void 0 && (g = !1);
    var D;
    if (h(p))
      D = new r(p.data);
    else if (y(p))
      D = new o(p.data);
    else if (A(p)) {
      var B = g ? m(p.children) : [], E = new f(p.name, u({}, p.attribs), B);
      B.forEach(function(S) {
        return S.parent = E;
      }), p.namespace != null && (E.namespace = p.namespace), p["x-attribsNamespace"] && (E["x-attribsNamespace"] = u({}, p["x-attribsNamespace"])), p["x-attribsPrefix"] && (E["x-attribsPrefix"] = u({}, p["x-attribsPrefix"])), D = E;
    } else if (d(p)) {
      var B = g ? m(p.children) : [], _ = new n(B);
      B.forEach(function(F) {
        return F.parent = _;
      }), D = _;
    } else if (w(p)) {
      var B = g ? m(p.children) : [], v = new l(B);
      B.forEach(function(F) {
        return F.parent = v;
      }), p["x-mode"] && (v["x-mode"] = p["x-mode"]), D = v;
    } else if (C(p)) {
      var k = new i(p.name, p.data);
      p["x-name"] != null && (k["x-name"] = p["x-name"], k["x-publicId"] = p["x-publicId"], k["x-systemId"] = p["x-systemId"]), D = k;
    } else
      throw new Error("Not implemented yet: ".concat(p.type));
    return D.startIndex = p.startIndex, D.endIndex = p.endIndex, p.sourceCodeLocation != null && (D.sourceCodeLocation = p.sourceCodeLocation), D;
  }
  q.cloneNode = x;
  function m(p) {
    for (var g = p.map(function(B) {
      return x(B, !0);
    }), D = 1; D < g.length; D++)
      g[D].prev = g[D - 1], g[D - 1].next = g[D];
    return g;
  }
  return q;
}
var Dr;
function Ne() {
  return Dr || (Dr = 1, (function(e) {
    var u = Oe && Oe.__createBinding || (Object.create ? (function(i, c, n, l) {
      l === void 0 && (l = n);
      var f = Object.getOwnPropertyDescriptor(c, n);
      (!f || ("get" in f ? !c.__esModule : f.writable || f.configurable)) && (f = { enumerable: !0, get: function() {
        return c[n];
      } }), Object.defineProperty(i, l, f);
    }) : (function(i, c, n, l) {
      l === void 0 && (l = n), i[l] = c[n];
    })), t = Oe && Oe.__exportStar || function(i, c) {
      for (var n in i) n !== "default" && !Object.prototype.hasOwnProperty.call(c, n) && u(c, i, n);
    };
    Object.defineProperty(e, "__esModule", { value: !0 }), e.DomHandler = void 0;
    var s = /* @__PURE__ */ tu(), a = /* @__PURE__ */ vr();
    t(/* @__PURE__ */ vr(), e);
    var r = {
      withStartIndices: !1,
      withEndIndices: !1,
      xmlMode: !1
    }, o = (
      /** @class */
      (function() {
        function i(c, n, l) {
          this.dom = [], this.root = new a.Document(this.dom), this.done = !1, this.tagStack = [this.root], this.lastNode = null, this.parser = null, typeof n == "function" && (l = n, n = r), typeof c == "object" && (n = c, c = void 0), this.callback = c ?? null, this.options = n ?? r, this.elementCB = l ?? null;
        }
        return i.prototype.onparserinit = function(c) {
          this.parser = c;
        }, i.prototype.onreset = function() {
          this.dom = [], this.root = new a.Document(this.dom), this.done = !1, this.tagStack = [this.root], this.lastNode = null, this.parser = null;
        }, i.prototype.onend = function() {
          this.done || (this.done = !0, this.parser = null, this.handleCallback(null));
        }, i.prototype.onerror = function(c) {
          this.handleCallback(c);
        }, i.prototype.onclosetag = function() {
          this.lastNode = null;
          var c = this.tagStack.pop();
          this.options.withEndIndices && (c.endIndex = this.parser.endIndex), this.elementCB && this.elementCB(c);
        }, i.prototype.onopentag = function(c, n) {
          var l = this.options.xmlMode ? s.ElementType.Tag : void 0, f = new a.Element(c, n, void 0, l);
          this.addNode(f), this.tagStack.push(f);
        }, i.prototype.ontext = function(c) {
          var n = this.lastNode;
          if (n && n.type === s.ElementType.Text)
            n.data += c, this.options.withEndIndices && (n.endIndex = this.parser.endIndex);
          else {
            var l = new a.Text(c);
            this.addNode(l), this.lastNode = l;
          }
        }, i.prototype.oncomment = function(c) {
          if (this.lastNode && this.lastNode.type === s.ElementType.Comment) {
            this.lastNode.data += c;
            return;
          }
          var n = new a.Comment(c);
          this.addNode(n), this.lastNode = n;
        }, i.prototype.oncommentend = function() {
          this.lastNode = null;
        }, i.prototype.oncdatastart = function() {
          var c = new a.Text(""), n = new a.CDATA([c]);
          this.addNode(n), c.parent = n, this.lastNode = c;
        }, i.prototype.oncdataend = function() {
          this.lastNode = null;
        }, i.prototype.onprocessinginstruction = function(c, n) {
          var l = new a.ProcessingInstruction(c, n);
          this.addNode(l);
        }, i.prototype.handleCallback = function(c) {
          if (typeof this.callback == "function")
            this.callback(c, this.dom);
          else if (c)
            throw c;
        }, i.prototype.addNode = function(c) {
          var n = this.tagStack[this.tagStack.length - 1], l = n.children[n.children.length - 1];
          this.options.withStartIndices && (c.startIndex = this.parser.startIndex), this.options.withEndIndices && (c.endIndex = this.parser.endIndex), n.children.push(c), l && (c.prev = l, l.next = c), c.parent = n, this.lastNode = null;
        }, i;
      })()
    );
    e.DomHandler = o, e.default = o;
  })(Oe)), Oe;
}
var Qe = {}, xe = {}, ue = {}, Wu = {}, be = {}, cu = {}, Er;
function Os() {
  return Er || (Er = 1, Object.defineProperty(cu, "__esModule", { value: !0 }), cu.default = new Uint16Array(
    // prettier-ignore
    'ᵁ<Õıʊҝջאٵ۞ޢߖࠏ੊ઑඡ๭༉༦჊ረዡᐕᒝᓃᓟᔥ\0\0\0\0\0\0ᕫᛍᦍᰒᷝ὾⁠↰⊍⏀⏻⑂⠤⤒ⴈ⹈⿎〖㊺㘹㞬㣾㨨㩱㫠㬮ࠀEMabcfglmnoprstu\\bfms¦³¹ÈÏlig耻Æ䃆P耻&䀦cute耻Á䃁reve;䄂Āiyx}rc耻Â䃂;䐐r;쀀𝔄rave耻À䃀pha;䎑acr;䄀d;橓Āgp¡on;䄄f;쀀𝔸plyFunction;恡ing耻Å䃅Ācs¾Ãr;쀀𝒜ign;扔ilde耻Ã䃃ml耻Ä䃄ЀaceforsuåûþėĜĢħĪĀcrêòkslash;或Ŷöø;櫧ed;挆y;䐑ƀcrtąċĔause;戵noullis;愬a;䎒r;쀀𝔅pf;쀀𝔹eve;䋘còēmpeq;扎܀HOacdefhilorsuōőŖƀƞƢƵƷƺǜȕɳɸɾcy;䐧PY耻©䂩ƀcpyŝŢźute;䄆Ā;iŧŨ拒talDifferentialD;慅leys;愭ȀaeioƉƎƔƘron;䄌dil耻Ç䃇rc;䄈nint;戰ot;䄊ĀdnƧƭilla;䂸terDot;䂷òſi;䎧rcleȀDMPTǇǋǑǖot;抙inus;抖lus;投imes;抗oĀcsǢǸkwiseContourIntegral;戲eCurlyĀDQȃȏoubleQuote;思uote;怙ȀlnpuȞȨɇɕonĀ;eȥȦ户;橴ƀgitȯȶȺruent;扡nt;戯ourIntegral;戮ĀfrɌɎ;愂oduct;成nterClockwiseContourIntegral;戳oss;樯cr;쀀𝒞pĀ;Cʄʅ拓ap;才րDJSZacefiosʠʬʰʴʸˋ˗ˡ˦̳ҍĀ;oŹʥtrahd;椑cy;䐂cy;䐅cy;䐏ƀgrsʿ˄ˇger;怡r;憡hv;櫤Āayː˕ron;䄎;䐔lĀ;t˝˞戇a;䎔r;쀀𝔇Āaf˫̧Ācm˰̢riticalȀADGT̖̜̀̆cute;䂴oŴ̋̍;䋙bleAcute;䋝rave;䁠ilde;䋜ond;拄ferentialD;慆Ѱ̽\0\0\0͔͂\0Ѕf;쀀𝔻ƀ;DE͈͉͍䂨ot;惜qual;扐blèCDLRUVͣͲ΂ϏϢϸontourIntegraìȹoɴ͹\0\0ͻ»͉nArrow;懓Āeo·ΤftƀARTΐΖΡrrow;懐ightArrow;懔eåˊngĀLRΫτeftĀARγιrrow;柸ightArrow;柺ightArrow;柹ightĀATϘϞrrow;懒ee;抨pɁϩ\0\0ϯrrow;懑ownArrow;懕erticalBar;戥ǹABLRTaВЪаўѿͼrrowƀ;BUНОТ憓ar;椓pArrow;懵reve;䌑eft˒к\0ц\0ѐightVector;楐eeVector;楞ectorĀ;Bљњ憽ar;楖ightǔѧ\0ѱeeVector;楟ectorĀ;BѺѻ懁ar;楗eeĀ;A҆҇护rrow;憧ĀctҒҗr;쀀𝒟rok;䄐ࠀNTacdfglmopqstuxҽӀӄӋӞӢӧӮӵԡԯԶՒ՝ՠեG;䅊H耻Ð䃐cute耻É䃉ƀaiyӒӗӜron;䄚rc耻Ê䃊;䐭ot;䄖r;쀀𝔈rave耻È䃈ement;戈ĀapӺӾcr;䄒tyɓԆ\0\0ԒmallSquare;旻erySmallSquare;斫ĀgpԦԪon;䄘f;쀀𝔼silon;䎕uĀaiԼՉlĀ;TՂՃ橵ilde;扂librium;懌Āci՗՚r;愰m;橳a;䎗ml耻Ë䃋Āipժկsts;戃onentialE;慇ʀcfiosօֈ֍ֲ׌y;䐤r;쀀𝔉lledɓ֗\0\0֣mallSquare;旼erySmallSquare;斪Ͱֺ\0ֿ\0\0ׄf;쀀𝔽All;戀riertrf;愱cò׋؀JTabcdfgorstר׬ׯ׺؀ؒؖ؛؝أ٬ٲcy;䐃耻>䀾mmaĀ;d׷׸䎓;䏜reve;䄞ƀeiy؇،ؐdil;䄢rc;䄜;䐓ot;䄠r;쀀𝔊;拙pf;쀀𝔾eater̀EFGLSTصلَٖٛ٦qualĀ;Lؾؿ扥ess;招ullEqual;执reater;檢ess;扷lantEqual;橾ilde;扳cr;쀀𝒢;扫ЀAacfiosuڅڋږڛڞڪھۊRDcy;䐪Āctڐڔek;䋇;䁞irc;䄤r;愌lbertSpace;愋ǰگ\0ڲf;愍izontalLine;攀Āctۃۅòکrok;䄦mpńېۘownHumðįqual;扏܀EJOacdfgmnostuۺ۾܃܇܎ܚܞܡܨ݄ݸދޏޕcy;䐕lig;䄲cy;䐁cute耻Í䃍Āiyܓܘrc耻Î䃎;䐘ot;䄰r;愑rave耻Ì䃌ƀ;apܠܯܿĀcgܴܷr;䄪inaryI;慈lieóϝǴ݉\0ݢĀ;eݍݎ戬Āgrݓݘral;戫section;拂isibleĀCTݬݲomma;恣imes;恢ƀgptݿރވon;䄮f;쀀𝕀a;䎙cr;愐ilde;䄨ǫޚ\0ޞcy;䐆l耻Ï䃏ʀcfosuެ޷޼߂ߐĀiyޱ޵rc;䄴;䐙r;쀀𝔍pf;쀀𝕁ǣ߇\0ߌr;쀀𝒥rcy;䐈kcy;䐄΀HJacfosߤߨ߽߬߱ࠂࠈcy;䐥cy;䐌ppa;䎚Āey߶߻dil;䄶;䐚r;쀀𝔎pf;쀀𝕂cr;쀀𝒦րJTaceflmostࠥࠩࠬࡐࡣ঳সে্਷ੇcy;䐉耻<䀼ʀcmnpr࠷࠼ࡁࡄࡍute;䄹bda;䎛g;柪lacetrf;愒r;憞ƀaeyࡗ࡜ࡡron;䄽dil;䄻;䐛Āfsࡨ॰tԀACDFRTUVarࡾࢩࢱࣦ࣠ࣼयज़ΐ४Ānrࢃ࢏gleBracket;柨rowƀ;BR࢙࢚࢞憐ar;懤ightArrow;懆eiling;挈oǵࢷ\0ࣃbleBracket;柦nǔࣈ\0࣒eeVector;楡ectorĀ;Bࣛࣜ懃ar;楙loor;挊ightĀAV࣯ࣵrrow;憔ector;楎Āerँगeƀ;AVउऊऐ抣rrow;憤ector;楚iangleƀ;BEतथऩ抲ar;槏qual;抴pƀDTVषूौownVector;楑eeVector;楠ectorĀ;Bॖॗ憿ar;楘ectorĀ;B॥०憼ar;楒ightáΜs̀EFGLSTॾঋকঝঢভqualGreater;拚ullEqual;扦reater;扶ess;檡lantEqual;橽ilde;扲r;쀀𝔏Ā;eঽা拘ftarrow;懚idot;䄿ƀnpw৔ਖਛgȀLRlr৞৷ਂਐeftĀAR০৬rrow;柵ightArrow;柷ightArrow;柶eftĀarγਊightáοightáϊf;쀀𝕃erĀLRਢਬeftArrow;憙ightArrow;憘ƀchtਾੀੂòࡌ;憰rok;䅁;扪Ѐacefiosuਗ਼੝੠੷੼અઋ઎p;椅y;䐜Ādl੥੯iumSpace;恟lintrf;愳r;쀀𝔐nusPlus;戓pf;쀀𝕄cò੶;䎜ҀJacefostuણધભીଔଙඑ඗ඞcy;䐊cute;䅃ƀaey઴હાron;䅇dil;䅅;䐝ƀgswે૰଎ativeƀMTV૓૟૨ediumSpace;怋hiĀcn૦૘ë૙eryThiî૙tedĀGL૸ଆreaterGreateòٳessLesóੈLine;䀊r;쀀𝔑ȀBnptଢନଷ଺reak;恠BreakingSpace;䂠f;愕ڀ;CDEGHLNPRSTV୕ୖ୪୼஡௫ఄ౞಄ದ೘ൡඅ櫬Āou୛୤ngruent;扢pCap;扭oubleVerticalBar;戦ƀlqxஃஊ஛ement;戉ualĀ;Tஒஓ扠ilde;쀀≂̸ists;戄reater΀;EFGLSTஶஷ஽௉௓௘௥扯qual;扱ullEqual;쀀≧̸reater;쀀≫̸ess;批lantEqual;쀀⩾̸ilde;扵umpń௲௽ownHump;쀀≎̸qual;쀀≏̸eĀfsఊధtTriangleƀ;BEచఛడ拪ar;쀀⧏̸qual;括s̀;EGLSTవశ఼ౄోౘ扮qual;扰reater;扸ess;쀀≪̸lantEqual;쀀⩽̸ilde;扴estedĀGL౨౹reaterGreater;쀀⪢̸essLess;쀀⪡̸recedesƀ;ESಒಓಛ技qual;쀀⪯̸lantEqual;拠ĀeiಫಹverseElement;戌ghtTriangleƀ;BEೋೌ೒拫ar;쀀⧐̸qual;拭ĀquೝഌuareSuĀbp೨೹setĀ;E೰ೳ쀀⊏̸qual;拢ersetĀ;Eഃആ쀀⊐̸qual;拣ƀbcpഓതൎsetĀ;Eഛഞ쀀⊂⃒qual;抈ceedsȀ;ESTലള഻െ抁qual;쀀⪰̸lantEqual;拡ilde;쀀≿̸ersetĀ;E൘൛쀀⊃⃒qual;抉ildeȀ;EFT൮൯൵ൿ扁qual;扄ullEqual;扇ilde;扉erticalBar;戤cr;쀀𝒩ilde耻Ñ䃑;䎝܀Eacdfgmoprstuvලෂ෉෕ෛ෠෧෼ขภยา฿ไlig;䅒cute耻Ó䃓Āiy෎ීrc耻Ô䃔;䐞blac;䅐r;쀀𝔒rave耻Ò䃒ƀaei෮ෲ෶cr;䅌ga;䎩cron;䎟pf;쀀𝕆enCurlyĀDQฎบoubleQuote;怜uote;怘;橔Āclวฬr;쀀𝒪ash耻Ø䃘iŬื฼de耻Õ䃕es;樷ml耻Ö䃖erĀBP๋๠Āar๐๓r;怾acĀek๚๜;揞et;掴arenthesis;揜Ҁacfhilors๿ງຊຏຒດຝະ໼rtialD;戂y;䐟r;쀀𝔓i;䎦;䎠usMinus;䂱Āipຢອncareplanåڝf;愙Ȁ;eio຺ູ໠໤檻cedesȀ;EST່້໏໚扺qual;檯lantEqual;扼ilde;找me;怳Ādp໩໮uct;戏ortionĀ;aȥ໹l;戝Āci༁༆r;쀀𝒫;䎨ȀUfos༑༖༛༟OT耻"䀢r;쀀𝔔pf;愚cr;쀀𝒬؀BEacefhiorsu༾གྷཇའཱིྦྷྪྭ႖ႩႴႾarr;椐G耻®䂮ƀcnrཎནབute;䅔g;柫rĀ;tཛྷཝ憠l;椖ƀaeyཧཬཱron;䅘dil;䅖;䐠Ā;vླྀཹ愜erseĀEUྂྙĀlq྇ྎement;戋uilibrium;懋pEquilibrium;楯r»ཹo;䎡ghtЀACDFTUVa࿁࿫࿳ဢဨၛႇϘĀnr࿆࿒gleBracket;柩rowƀ;BL࿜࿝࿡憒ar;懥eftArrow;懄eiling;按oǵ࿹\0စbleBracket;柧nǔည\0နeeVector;楝ectorĀ;Bဝသ懂ar;楕loor;挋Āerိ၃eƀ;AVဵံြ抢rrow;憦ector;楛iangleƀ;BEၐၑၕ抳ar;槐qual;抵pƀDTVၣၮၸownVector;楏eeVector;楜ectorĀ;Bႂႃ憾ar;楔ectorĀ;B႑႒懀ar;楓Āpuႛ႞f;愝ndImplies;楰ightarrow;懛ĀchႹႼr;愛;憱leDelayed;槴ڀHOacfhimoqstuფჱჷჽᄙᄞᅑᅖᅡᅧᆵᆻᆿĀCcჩხHcy;䐩y;䐨FTcy;䐬cute;䅚ʀ;aeiyᄈᄉᄎᄓᄗ檼ron;䅠dil;䅞rc;䅜;䐡r;쀀𝔖ortȀDLRUᄪᄴᄾᅉownArrow»ОeftArrow»࢚ightArrow»࿝pArrow;憑gma;䎣allCircle;战pf;쀀𝕊ɲᅭ\0\0ᅰt;戚areȀ;ISUᅻᅼᆉᆯ斡ntersection;抓uĀbpᆏᆞsetĀ;Eᆗᆘ抏qual;抑ersetĀ;Eᆨᆩ抐qual;抒nion;抔cr;쀀𝒮ar;拆ȀbcmpᇈᇛሉላĀ;sᇍᇎ拐etĀ;Eᇍᇕqual;抆ĀchᇠህeedsȀ;ESTᇭᇮᇴᇿ扻qual;檰lantEqual;扽ilde;承Tháྌ;我ƀ;esሒሓሣ拑rsetĀ;Eሜም抃qual;抇et»ሓրHRSacfhiorsሾቄ቉ቕ቞ቱቶኟዂወዑORN耻Þ䃞ADE;愢ĀHc቎ቒcy;䐋y;䐦Ābuቚቜ;䀉;䎤ƀaeyብቪቯron;䅤dil;䅢;䐢r;쀀𝔗Āeiቻ኉ǲኀ\0ኇefore;戴a;䎘Ācn኎ኘkSpace;쀀  Space;怉ldeȀ;EFTካኬኲኼ戼qual;扃ullEqual;扅ilde;扈pf;쀀𝕋ipleDot;惛Āctዖዛr;쀀𝒯rok;䅦ૡዷጎጚጦ\0ጬጱ\0\0\0\0\0ጸጽ፷ᎅ\0᏿ᐄᐊᐐĀcrዻጁute耻Ú䃚rĀ;oጇገ憟cir;楉rǣጓ\0጖y;䐎ve;䅬Āiyጞጣrc耻Û䃛;䐣blac;䅰r;쀀𝔘rave耻Ù䃙acr;䅪Ādiፁ፩erĀBPፈ፝Āarፍፐr;䁟acĀekፗፙ;揟et;掵arenthesis;揝onĀ;P፰፱拃lus;抎Āgp፻፿on;䅲f;쀀𝕌ЀADETadps᎕ᎮᎸᏄϨᏒᏗᏳrrowƀ;BDᅐᎠᎤar;椒ownArrow;懅ownArrow;憕quilibrium;楮eeĀ;AᏋᏌ报rrow;憥ownáϳerĀLRᏞᏨeftArrow;憖ightArrow;憗iĀ;lᏹᏺ䏒on;䎥ing;䅮cr;쀀𝒰ilde;䅨ml耻Ü䃜ҀDbcdefosvᐧᐬᐰᐳᐾᒅᒊᒐᒖash;披ar;櫫y;䐒ashĀ;lᐻᐼ抩;櫦Āerᑃᑅ;拁ƀbtyᑌᑐᑺar;怖Ā;iᑏᑕcalȀBLSTᑡᑥᑪᑴar;戣ine;䁼eparator;杘ilde;所ThinSpace;怊r;쀀𝔙pf;쀀𝕍cr;쀀𝒱dash;抪ʀcefosᒧᒬᒱᒶᒼirc;䅴dge;拀r;쀀𝔚pf;쀀𝕎cr;쀀𝒲Ȁfiosᓋᓐᓒᓘr;쀀𝔛;䎞pf;쀀𝕏cr;쀀𝒳ҀAIUacfosuᓱᓵᓹᓽᔄᔏᔔᔚᔠcy;䐯cy;䐇cy;䐮cute耻Ý䃝Āiyᔉᔍrc;䅶;䐫r;쀀𝔜pf;쀀𝕐cr;쀀𝒴ml;䅸ЀHacdefosᔵᔹᔿᕋᕏᕝᕠᕤcy;䐖cute;䅹Āayᕄᕉron;䅽;䐗ot;䅻ǲᕔ\0ᕛoWidtè૙a;䎖r;愨pf;愤cr;쀀𝒵௡ᖃᖊᖐ\0ᖰᖶᖿ\0\0\0\0ᗆᗛᗫᙟ᙭\0ᚕ᚛ᚲᚹ\0ᚾcute耻á䃡reve;䄃̀;Ediuyᖜᖝᖡᖣᖨᖭ戾;쀀∾̳;房rc耻â䃢te肻´̆;䐰lig耻æ䃦Ā;r²ᖺ;쀀𝔞rave耻à䃠ĀepᗊᗖĀfpᗏᗔsym;愵èᗓha;䎱ĀapᗟcĀclᗤᗧr;䄁g;樿ɤᗰ\0\0ᘊʀ;adsvᗺᗻᗿᘁᘇ戧nd;橕;橜lope;橘;橚΀;elmrszᘘᘙᘛᘞᘿᙏᙙ戠;榤e»ᘙsdĀ;aᘥᘦ戡ѡᘰᘲᘴᘶᘸᘺᘼᘾ;榨;榩;榪;榫;榬;榭;榮;榯tĀ;vᙅᙆ戟bĀ;dᙌᙍ抾;榝Āptᙔᙗh;戢»¹arr;捼Āgpᙣᙧon;䄅f;쀀𝕒΀;Eaeiop዁ᙻᙽᚂᚄᚇᚊ;橰cir;橯;扊d;手s;䀧roxĀ;e዁ᚒñᚃing耻å䃥ƀctyᚡᚦᚨr;쀀𝒶;䀪mpĀ;e዁ᚯñʈilde耻ã䃣ml耻ä䃤Āciᛂᛈoninôɲnt;樑ࠀNabcdefiklnoprsu᛭ᛱᜰ᜼ᝃᝈ᝸᝽០៦ᠹᡐᜍ᤽᥈ᥰot;櫭Ācrᛶ᜞kȀcepsᜀᜅᜍᜓong;扌psilon;䏶rime;怵imĀ;e᜚᜛戽q;拍Ŷᜢᜦee;抽edĀ;gᜬᜭ挅e»ᜭrkĀ;t፜᜷brk;掶Āoyᜁᝁ;䐱quo;怞ʀcmprtᝓ᝛ᝡᝤᝨausĀ;eĊĉptyv;榰séᜌnoõēƀahwᝯ᝱ᝳ;䎲;愶een;扬r;쀀𝔟g΀costuvwឍឝឳេ៕៛៞ƀaiuបពរðݠrc;旯p»፱ƀdptឤឨឭot;樀lus;樁imes;樂ɱឹ\0\0ើcup;樆ar;昅riangleĀdu៍្own;施p;斳plus;樄eåᑄåᒭarow;植ƀako៭ᠦᠵĀcn៲ᠣkƀlst៺֫᠂ozenge;槫riangleȀ;dlr᠒᠓᠘᠝斴own;斾eft;旂ight;斸k;搣Ʊᠫ\0ᠳƲᠯ\0ᠱ;斒;斑4;斓ck;斈ĀeoᠾᡍĀ;qᡃᡆ쀀=⃥uiv;쀀≡⃥t;挐Ȁptwxᡙᡞᡧᡬf;쀀𝕓Ā;tᏋᡣom»Ꮜtie;拈؀DHUVbdhmptuvᢅᢖᢪᢻᣗᣛᣬ᣿ᤅᤊᤐᤡȀLRlrᢎᢐᢒᢔ;敗;敔;敖;敓ʀ;DUduᢡᢢᢤᢦᢨ敐;敦;敩;敤;敧ȀLRlrᢳᢵᢷᢹ;敝;敚;敜;教΀;HLRhlrᣊᣋᣍᣏᣑᣓᣕ救;敬;散;敠;敫;敢;敟ox;槉ȀLRlrᣤᣦᣨᣪ;敕;敒;攐;攌ʀ;DUduڽ᣷᣹᣻᣽;敥;敨;攬;攴inus;抟lus;択imes;抠ȀLRlrᤙᤛᤝ᤟;敛;敘;攘;攔΀;HLRhlrᤰᤱᤳᤵᤷ᤻᤹攂;敪;敡;敞;攼;攤;攜Āevģ᥂bar耻¦䂦Ȁceioᥑᥖᥚᥠr;쀀𝒷mi;恏mĀ;e᜚᜜lƀ;bhᥨᥩᥫ䁜;槅sub;柈Ŭᥴ᥾lĀ;e᥹᥺怢t»᥺pƀ;Eeįᦅᦇ;檮Ā;qۜۛೡᦧ\0᧨ᨑᨕᨲ\0ᨷᩐ\0\0᪴\0\0᫁\0\0ᬡᬮ᭍᭒\0᯽\0ᰌƀcpr᦭ᦲ᧝ute;䄇̀;abcdsᦿᧀᧄ᧊᧕᧙戩nd;橄rcup;橉Āau᧏᧒p;橋p;橇ot;橀;쀀∩︀Āeo᧢᧥t;恁îړȀaeiu᧰᧻ᨁᨅǰ᧵\0᧸s;橍on;䄍dil耻ç䃧rc;䄉psĀ;sᨌᨍ橌m;橐ot;䄋ƀdmnᨛᨠᨦil肻¸ƭptyv;榲t脀¢;eᨭᨮ䂢räƲr;쀀𝔠ƀceiᨽᩀᩍy;䑇ckĀ;mᩇᩈ朓ark»ᩈ;䏇r΀;Ecefms᩟᩠ᩢᩫ᪤᪪᪮旋;槃ƀ;elᩩᩪᩭ䋆q;扗eɡᩴ\0\0᪈rrowĀlr᩼᪁eft;憺ight;憻ʀRSacd᪒᪔᪖᪚᪟»ཇ;擈st;抛irc;抚ash;抝nint;樐id;櫯cir;槂ubsĀ;u᪻᪼晣it»᪼ˬ᫇᫔᫺\0ᬊonĀ;eᫍᫎ䀺Ā;qÇÆɭ᫙\0\0᫢aĀ;t᫞᫟䀬;䁀ƀ;fl᫨᫩᫫戁îᅠeĀmx᫱᫶ent»᫩eóɍǧ᫾\0ᬇĀ;dኻᬂot;橭nôɆƀfryᬐᬔᬗ;쀀𝕔oäɔ脀©;sŕᬝr;愗Āaoᬥᬩrr;憵ss;朗Ācuᬲᬷr;쀀𝒸Ābpᬼ᭄Ā;eᭁᭂ櫏;櫑Ā;eᭉᭊ櫐;櫒dot;拯΀delprvw᭠᭬᭷ᮂᮬᯔ᯹arrĀlr᭨᭪;椸;椵ɰ᭲\0\0᭵r;拞c;拟arrĀ;p᭿ᮀ憶;椽̀;bcdosᮏᮐᮖᮡᮥᮨ截rcap;橈Āauᮛᮞp;橆p;橊ot;抍r;橅;쀀∪︀Ȁalrv᮵ᮿᯞᯣrrĀ;mᮼᮽ憷;椼yƀevwᯇᯔᯘqɰᯎ\0\0ᯒreã᭳uã᭵ee;拎edge;拏en耻¤䂤earrowĀlrᯮ᯳eft»ᮀight»ᮽeäᯝĀciᰁᰇoninôǷnt;戱lcty;挭ঀAHabcdefhijlorstuwz᰸᰻᰿ᱝᱩᱵᲊᲞᲬᲷ᳻᳿ᴍᵻᶑᶫᶻ᷆᷍rò΁ar;楥Ȁglrs᱈ᱍ᱒᱔ger;怠eth;愸òᄳhĀ;vᱚᱛ怐»ऊūᱡᱧarow;椏aã̕Āayᱮᱳron;䄏;䐴ƀ;ao̲ᱼᲄĀgrʿᲁr;懊tseq;橷ƀglmᲑᲔᲘ耻°䂰ta;䎴ptyv;榱ĀirᲣᲨsht;楿;쀀𝔡arĀlrᲳᲵ»ࣜ»သʀaegsv᳂͸᳖᳜᳠mƀ;oș᳊᳔ndĀ;ș᳑uit;晦amma;䏝in;拲ƀ;io᳧᳨᳸䃷de脀÷;o᳧ᳰntimes;拇nø᳷cy;䑒cɯᴆ\0\0ᴊrn;挞op;挍ʀlptuwᴘᴝᴢᵉᵕlar;䀤f;쀀𝕕ʀ;emps̋ᴭᴷᴽᵂqĀ;d͒ᴳot;扑inus;戸lus;戔quare;抡blebarwedgåúnƀadhᄮᵝᵧownarrowóᲃarpoonĀlrᵲᵶefôᲴighôᲶŢᵿᶅkaro÷གɯᶊ\0\0ᶎrn;挟op;挌ƀcotᶘᶣᶦĀryᶝᶡ;쀀𝒹;䑕l;槶rok;䄑Ādrᶰᶴot;拱iĀ;fᶺ᠖斿Āah᷀᷃ròЩaòྦangle;榦Āci᷒ᷕy;䑟grarr;柿ऀDacdefglmnopqrstuxḁḉḙḸոḼṉṡṾấắẽỡἪἷὄ὎὚ĀDoḆᴴoôᲉĀcsḎḔute耻é䃩ter;橮ȀaioyḢḧḱḶron;䄛rĀ;cḭḮ扖耻ê䃪lon;払;䑍ot;䄗ĀDrṁṅot;扒;쀀𝔢ƀ;rsṐṑṗ檚ave耻è䃨Ā;dṜṝ檖ot;檘Ȁ;ilsṪṫṲṴ檙nters;揧;愓Ā;dṹṺ檕ot;檗ƀapsẅẉẗcr;䄓tyƀ;svẒẓẕ戅et»ẓpĀ1;ẝẤĳạả;怄;怅怃ĀgsẪẬ;䅋p;怂ĀgpẴẸon;䄙f;쀀𝕖ƀalsỄỎỒrĀ;sỊị拕l;槣us;橱iƀ;lvỚớở䎵on»ớ;䏵ȀcsuvỪỳἋἣĀioữḱrc»Ḯɩỹ\0\0ỻíՈantĀglἂἆtr»ṝess»Ṻƀaeiἒ἖Ἒls;䀽st;扟vĀ;DȵἠD;橸parsl;槥ĀDaἯἳot;打rr;楱ƀcdiἾὁỸr;愯oô͒ĀahὉὋ;䎷耻ð䃰Āmrὓὗl耻ë䃫o;悬ƀcipὡὤὧl;䀡sôծĀeoὬὴctatioîՙnentialåչৡᾒ\0ᾞ\0ᾡᾧ\0\0ῆῌ\0ΐ\0ῦῪ \0 ⁚llingdotseñṄy;䑄male;晀ƀilrᾭᾳ῁lig;耀ﬃɩᾹ\0\0᾽g;耀ﬀig;耀ﬄ;쀀𝔣lig;耀ﬁlig;쀀fjƀaltῙ῜ῡt;晭ig;耀ﬂns;斱of;䆒ǰ΅\0ῳf;쀀𝕗ĀakֿῷĀ;vῼ´拔;櫙artint;樍Āao‌⁕Ācs‑⁒α‚‰‸⁅⁈\0⁐β•‥‧‪‬\0‮耻½䂽;慓耻¼䂼;慕;慙;慛Ƴ‴\0‶;慔;慖ʴ‾⁁\0\0⁃耻¾䂾;慗;慜5;慘ƶ⁌\0⁎;慚;慝8;慞l;恄wn;挢cr;쀀𝒻ࢀEabcdefgijlnorstv₂₉₟₥₰₴⃰⃵⃺⃿℃ℒℸ̗ℾ⅒↞Ā;lٍ₇;檌ƀcmpₐₕ₝ute;䇵maĀ;dₜ᳚䎳;檆reve;䄟Āiy₪₮rc;䄝;䐳ot;䄡Ȁ;lqsؾق₽⃉ƀ;qsؾٌ⃄lanô٥Ȁ;cdl٥⃒⃥⃕c;檩otĀ;o⃜⃝檀Ā;l⃢⃣檂;檄Ā;e⃪⃭쀀⋛︀s;檔r;쀀𝔤Ā;gٳ؛mel;愷cy;䑓Ȁ;Eajٚℌℎℐ;檒;檥;檤ȀEaesℛℝ℩ℴ;扩pĀ;p℣ℤ檊rox»ℤĀ;q℮ℯ檈Ā;q℮ℛim;拧pf;쀀𝕘Āci⅃ⅆr;愊mƀ;el٫ⅎ⅐;檎;檐茀>;cdlqr׮ⅠⅪⅮⅳⅹĀciⅥⅧ;檧r;橺ot;拗Par;榕uest;橼ʀadelsↄⅪ←ٖ↛ǰ↉\0↎proø₞r;楸qĀlqؿ↖lesó₈ií٫Āen↣↭rtneqq;쀀≩︀Å↪ԀAabcefkosy⇄⇇⇱⇵⇺∘∝∯≨≽ròΠȀilmr⇐⇔⇗⇛rsðᒄf»․ilôکĀdr⇠⇤cy;䑊ƀ;cwࣴ⇫⇯ir;楈;憭ar;意irc;䄥ƀalr∁∎∓rtsĀ;u∉∊晥it»∊lip;怦con;抹r;쀀𝔥sĀew∣∩arow;椥arow;椦ʀamopr∺∾≃≞≣rr;懿tht;戻kĀlr≉≓eftarrow;憩ightarrow;憪f;쀀𝕙bar;怕ƀclt≯≴≸r;쀀𝒽asè⇴rok;䄧Ābp⊂⊇ull;恃hen»ᱛૡ⊣\0⊪\0⊸⋅⋎\0⋕⋳\0\0⋸⌢⍧⍢⍿\0⎆⎪⎴cute耻í䃭ƀ;iyݱ⊰⊵rc耻î䃮;䐸Ācx⊼⊿y;䐵cl耻¡䂡ĀfrΟ⋉;쀀𝔦rave耻ì䃬Ȁ;inoܾ⋝⋩⋮Āin⋢⋦nt;樌t;戭fin;槜ta;愩lig;䄳ƀaop⋾⌚⌝ƀcgt⌅⌈⌗r;䄫ƀelpܟ⌏⌓inåގarôܠh;䄱f;抷ed;䆵ʀ;cfotӴ⌬⌱⌽⍁are;愅inĀ;t⌸⌹戞ie;槝doô⌙ʀ;celpݗ⍌⍐⍛⍡al;抺Āgr⍕⍙eróᕣã⍍arhk;樗rod;樼Ȁcgpt⍯⍲⍶⍻y;䑑on;䄯f;쀀𝕚a;䎹uest耻¿䂿Āci⎊⎏r;쀀𝒾nʀ;EdsvӴ⎛⎝⎡ӳ;拹ot;拵Ā;v⎦⎧拴;拳Ā;iݷ⎮lde;䄩ǫ⎸\0⎼cy;䑖l耻ï䃯̀cfmosu⏌⏗⏜⏡⏧⏵Āiy⏑⏕rc;䄵;䐹r;쀀𝔧ath;䈷pf;쀀𝕛ǣ⏬\0⏱r;쀀𝒿rcy;䑘kcy;䑔Ѐacfghjos␋␖␢␧␭␱␵␻ppaĀ;v␓␔䎺;䏰Āey␛␠dil;䄷;䐺r;쀀𝔨reen;䄸cy;䑅cy;䑜pf;쀀𝕜cr;쀀𝓀஀ABEHabcdefghjlmnoprstuv⑰⒁⒆⒍⒑┎┽╚▀♎♞♥♹♽⚚⚲⛘❝❨➋⟀⠁⠒ƀart⑷⑺⑼rò৆òΕail;椛arr;椎Ā;gঔ⒋;檋ar;楢ॣ⒥\0⒪\0⒱\0\0\0\0\0⒵Ⓔ\0ⓆⓈⓍ\0⓹ute;䄺mptyv;榴raîࡌbda;䎻gƀ;dlࢎⓁⓃ;榑åࢎ;檅uo耻«䂫rЀ;bfhlpst࢙ⓞⓦⓩ⓫⓮⓱⓵Ā;f࢝ⓣs;椟s;椝ë≒p;憫l;椹im;楳l;憢ƀ;ae⓿─┄檫il;椙Ā;s┉┊檭;쀀⪭︀ƀabr┕┙┝rr;椌rk;杲Āak┢┬cĀek┨┪;䁻;䁛Āes┱┳;榋lĀdu┹┻;榏;榍Ȁaeuy╆╋╖╘ron;䄾Ādi═╔il;䄼ìࢰâ┩;䐻Ȁcqrs╣╦╭╽a;椶uoĀ;rนᝆĀdu╲╷har;楧shar;楋h;憲ʀ;fgqs▋▌উ◳◿扤tʀahlrt▘▤▷◂◨rrowĀ;t࢙□aé⓶arpoonĀdu▯▴own»њp»०eftarrows;懇ightƀahs◍◖◞rrowĀ;sࣴࢧarpoonó྘quigarro÷⇰hreetimes;拋ƀ;qs▋ও◺lanôবʀ;cdgsব☊☍☝☨c;檨otĀ;o☔☕橿Ā;r☚☛檁;檃Ā;e☢☥쀀⋚︀s;檓ʀadegs☳☹☽♉♋pproøⓆot;拖qĀgq♃♅ôউgtò⒌ôছiíলƀilr♕࣡♚sht;楼;쀀𝔩Ā;Eজ♣;檑š♩♶rĀdu▲♮Ā;l॥♳;楪lk;斄cy;䑙ʀ;achtੈ⚈⚋⚑⚖rò◁orneòᴈard;楫ri;旺Āio⚟⚤dot;䅀ustĀ;a⚬⚭掰che»⚭ȀEaes⚻⚽⛉⛔;扨pĀ;p⛃⛄檉rox»⛄Ā;q⛎⛏檇Ā;q⛎⚻im;拦Ѐabnoptwz⛩⛴⛷✚✯❁❇❐Ānr⛮⛱g;柬r;懽rëࣁgƀlmr⛿✍✔eftĀar০✇ightá৲apsto;柼ightá৽parrowĀlr✥✩efô⓭ight;憬ƀafl✶✹✽r;榅;쀀𝕝us;樭imes;樴š❋❏st;戗áፎƀ;ef❗❘᠀旊nge»❘arĀ;l❤❥䀨t;榓ʀachmt❳❶❼➅➇ròࢨorneòᶌarĀ;d྘➃;業;怎ri;抿̀achiqt➘➝ੀ➢➮➻quo;怹r;쀀𝓁mƀ;egল➪➬;檍;檏Ābu┪➳oĀ;rฟ➹;怚rok;䅂萀<;cdhilqrࠫ⟒☹⟜⟠⟥⟪⟰Āci⟗⟙;檦r;橹reå◲mes;拉arr;楶uest;橻ĀPi⟵⟹ar;榖ƀ;ef⠀भ᠛旃rĀdu⠇⠍shar;楊har;楦Āen⠗⠡rtneqq;쀀≨︀Å⠞܀Dacdefhilnopsu⡀⡅⢂⢎⢓⢠⢥⢨⣚⣢⣤ઃ⣳⤂Dot;戺Ȁclpr⡎⡒⡣⡽r耻¯䂯Āet⡗⡙;時Ā;e⡞⡟朠se»⡟Ā;sျ⡨toȀ;dluျ⡳⡷⡻owîҌefôएðᏑker;斮Āoy⢇⢌mma;権;䐼ash;怔asuredangle»ᘦr;쀀𝔪o;愧ƀcdn⢯⢴⣉ro耻µ䂵Ȁ;acdᑤ⢽⣀⣄sôᚧir;櫰ot肻·Ƶusƀ;bd⣒ᤃ⣓戒Ā;uᴼ⣘;横ţ⣞⣡p;櫛ò−ðઁĀdp⣩⣮els;抧f;쀀𝕞Āct⣸⣽r;쀀𝓂pos»ᖝƀ;lm⤉⤊⤍䎼timap;抸ఀGLRVabcdefghijlmoprstuvw⥂⥓⥾⦉⦘⧚⧩⨕⨚⩘⩝⪃⪕⪤⪨⬄⬇⭄⭿⮮ⰴⱧⱼ⳩Āgt⥇⥋;쀀⋙̸Ā;v⥐௏쀀≫⃒ƀelt⥚⥲⥶ftĀar⥡⥧rrow;懍ightarrow;懎;쀀⋘̸Ā;v⥻ే쀀≪⃒ightarrow;懏ĀDd⦎⦓ash;抯ash;抮ʀbcnpt⦣⦧⦬⦱⧌la»˞ute;䅄g;쀀∠⃒ʀ;Eiop඄⦼⧀⧅⧈;쀀⩰̸d;쀀≋̸s;䅉roø඄urĀ;a⧓⧔普lĀ;s⧓ସǳ⧟\0⧣p肻 ଷmpĀ;e௹ఀʀaeouy⧴⧾⨃⨐⨓ǰ⧹\0⧻;橃on;䅈dil;䅆ngĀ;dൾ⨊ot;쀀⩭̸p;橂;䐽ash;怓΀;Aadqsxஒ⨩⨭⨻⩁⩅⩐rr;懗rĀhr⨳⨶k;椤Ā;oᏲᏰot;쀀≐̸uiöୣĀei⩊⩎ar;椨í஘istĀ;s஠டr;쀀𝔫ȀEest௅⩦⩹⩼ƀ;qs஼⩭௡ƀ;qs஼௅⩴lanô௢ií௪Ā;rஶ⪁»ஷƀAap⪊⪍⪑rò⥱rr;憮ar;櫲ƀ;svྍ⪜ྌĀ;d⪡⪢拼;拺cy;䑚΀AEadest⪷⪺⪾⫂⫅⫶⫹rò⥦;쀀≦̸rr;憚r;急Ȁ;fqs఻⫎⫣⫯tĀar⫔⫙rro÷⫁ightarro÷⪐ƀ;qs఻⪺⫪lanôౕĀ;sౕ⫴»శiíౝĀ;rవ⫾iĀ;eచథiäඐĀpt⬌⬑f;쀀𝕟膀¬;in⬙⬚⬶䂬nȀ;Edvஉ⬤⬨⬮;쀀⋹̸ot;쀀⋵̸ǡஉ⬳⬵;拷;拶iĀ;vಸ⬼ǡಸ⭁⭃;拾;拽ƀaor⭋⭣⭩rȀ;ast୻⭕⭚⭟lleì୻l;쀀⫽⃥;쀀∂̸lint;樔ƀ;ceಒ⭰⭳uåಥĀ;cಘ⭸Ā;eಒ⭽ñಘȀAait⮈⮋⮝⮧rò⦈rrƀ;cw⮔⮕⮙憛;쀀⤳̸;쀀↝̸ghtarrow»⮕riĀ;eೋೖ΀chimpqu⮽⯍⯙⬄୸⯤⯯Ȁ;cerല⯆ഷ⯉uå൅;쀀𝓃ortɭ⬅\0\0⯖ará⭖mĀ;e൮⯟Ā;q൴൳suĀbp⯫⯭å೸åഋƀbcp⯶ⰑⰙȀ;Ees⯿ⰀഢⰄ抄;쀀⫅̸etĀ;eഛⰋqĀ;qണⰀcĀ;eലⰗñസȀ;EesⰢⰣൟⰧ抅;쀀⫆̸etĀ;e൘ⰮqĀ;qൠⰣȀgilrⰽⰿⱅⱇìௗlde耻ñ䃱çృiangleĀlrⱒⱜeftĀ;eచⱚñదightĀ;eೋⱥñ೗Ā;mⱬⱭ䎽ƀ;esⱴⱵⱹ䀣ro;愖p;怇ҀDHadgilrsⲏⲔⲙⲞⲣⲰⲶⳓⳣash;抭arr;椄p;쀀≍⃒ash;抬ĀetⲨⲬ;쀀≥⃒;쀀>⃒nfin;槞ƀAetⲽⳁⳅrr;椂;쀀≤⃒Ā;rⳊⳍ쀀<⃒ie;쀀⊴⃒ĀAtⳘⳜrr;椃rie;쀀⊵⃒im;쀀∼⃒ƀAan⳰⳴ⴂrr;懖rĀhr⳺⳽k;椣Ā;oᏧᏥear;椧ቓ᪕\0\0\0\0\0\0\0\0\0\0\0\0\0ⴭ\0ⴸⵈⵠⵥ⵲ⶄᬇ\0\0ⶍⶫ\0ⷈⷎ\0ⷜ⸙⸫⸾⹃Ācsⴱ᪗ute耻ó䃳ĀiyⴼⵅrĀ;c᪞ⵂ耻ô䃴;䐾ʀabios᪠ⵒⵗǈⵚlac;䅑v;樸old;榼lig;䅓Ācr⵩⵭ir;榿;쀀𝔬ͯ⵹\0\0⵼\0ⶂn;䋛ave耻ò䃲;槁Ābmⶈ෴ar;榵Ȁacitⶕ⶘ⶥⶨrò᪀Āir⶝ⶠr;榾oss;榻nå๒;槀ƀaeiⶱⶵⶹcr;䅍ga;䏉ƀcdnⷀⷅǍron;䎿;榶pf;쀀𝕠ƀaelⷔ⷗ǒr;榷rp;榹΀;adiosvⷪⷫⷮ⸈⸍⸐⸖戨rò᪆Ȁ;efmⷷⷸ⸂⸅橝rĀ;oⷾⷿ愴f»ⷿ耻ª䂪耻º䂺gof;抶r;橖lope;橗;橛ƀclo⸟⸡⸧ò⸁ash耻ø䃸l;折iŬⸯ⸴de耻õ䃵esĀ;aǛ⸺s;樶ml耻ö䃶bar;挽ૡ⹞\0⹽\0⺀⺝\0⺢⺹\0\0⻋ຜ\0⼓\0\0⼫⾼\0⿈rȀ;astЃ⹧⹲຅脀¶;l⹭⹮䂶leìЃɩ⹸\0\0⹻m;櫳;櫽y;䐿rʀcimpt⺋⺏⺓ᡥ⺗nt;䀥od;䀮il;怰enk;怱r;쀀𝔭ƀimo⺨⺰⺴Ā;v⺭⺮䏆;䏕maô੶ne;明ƀ;tv⺿⻀⻈䏀chfork»´;䏖Āau⻏⻟nĀck⻕⻝kĀ;h⇴⻛;愎ö⇴sҀ;abcdemst⻳⻴ᤈ⻹⻽⼄⼆⼊⼎䀫cir;樣ir;樢Āouᵀ⼂;樥;橲n肻±ຝim;樦wo;樧ƀipu⼙⼠⼥ntint;樕f;쀀𝕡nd耻£䂣Ԁ;Eaceinosu່⼿⽁⽄⽇⾁⾉⾒⽾⾶;檳p;檷uå໙Ā;c໎⽌̀;acens່⽙⽟⽦⽨⽾pproø⽃urlyeñ໙ñ໎ƀaes⽯⽶⽺pprox;檹qq;檵im;拨iíໟmeĀ;s⾈ຮ怲ƀEas⽸⾐⽺ð⽵ƀdfp໬⾙⾯ƀals⾠⾥⾪lar;挮ine;挒urf;挓Ā;t໻⾴ï໻rel;抰Āci⿀⿅r;쀀𝓅;䏈ncsp;怈̀fiopsu⿚⋢⿟⿥⿫⿱r;쀀𝔮pf;쀀𝕢rime;恗cr;쀀𝓆ƀaeo⿸〉〓tĀei⿾々rnionóڰnt;樖stĀ;e【】䀿ñἙô༔઀ABHabcdefhilmnoprstux぀けさすムㄎㄫㅇㅢㅲㆎ㈆㈕㈤㈩㉘㉮㉲㊐㊰㊷ƀartぇおがròႳòϝail;検aròᱥar;楤΀cdenqrtとふへみわゔヌĀeuねぱ;쀀∽̱te;䅕iãᅮmptyv;榳gȀ;del࿑らるろ;榒;榥å࿑uo耻»䂻rր;abcfhlpstw࿜ガクシスゼゾダッデナp;極Ā;f࿠ゴs;椠;椳s;椞ë≝ð✮l;楅im;楴l;憣;憝Āaiパフil;椚oĀ;nホボ戶aló༞ƀabrョリヮrò៥rk;杳ĀakンヽcĀekヹ・;䁽;䁝Āes㄂㄄;榌lĀduㄊㄌ;榎;榐Ȁaeuyㄗㄜㄧㄩron;䅙Ādiㄡㄥil;䅗ì࿲âヺ;䑀Ȁclqsㄴㄷㄽㅄa;椷dhar;楩uoĀ;rȎȍh;憳ƀacgㅎㅟངlȀ;ipsླྀㅘㅛႜnåႻarôྩt;断ƀilrㅩဣㅮsht;楽;쀀𝔯ĀaoㅷㆆrĀduㅽㅿ»ѻĀ;l႑ㆄ;楬Ā;vㆋㆌ䏁;䏱ƀgns㆕ㇹㇼht̀ahlrstㆤㆰ㇂㇘㇤㇮rrowĀ;t࿜ㆭaéトarpoonĀduㆻㆿowîㅾp»႒eftĀah㇊㇐rrowó࿪arpoonóՑightarrows;應quigarro÷ニhreetimes;拌g;䋚ingdotseñἲƀahm㈍㈐㈓rò࿪aòՑ;怏oustĀ;a㈞㈟掱che»㈟mid;櫮Ȁabpt㈲㈽㉀㉒Ānr㈷㈺g;柭r;懾rëဃƀafl㉇㉊㉎r;榆;쀀𝕣us;樮imes;樵Āap㉝㉧rĀ;g㉣㉤䀩t;榔olint;樒arò㇣Ȁachq㉻㊀Ⴜ㊅quo;怺r;쀀𝓇Ābu・㊊oĀ;rȔȓƀhir㊗㊛㊠reåㇸmes;拊iȀ;efl㊪ၙᠡ㊫方tri;槎luhar;楨;愞ൡ㋕㋛㋟㌬㌸㍱\0㍺㎤\0\0㏬㏰\0㐨㑈㑚㒭㒱㓊㓱\0㘖\0\0㘳cute;䅛quï➺Ԁ;Eaceinpsyᇭ㋳㋵㋿㌂㌋㌏㌟㌦㌩;檴ǰ㋺\0㋼;檸on;䅡uåᇾĀ;dᇳ㌇il;䅟rc;䅝ƀEas㌖㌘㌛;檶p;檺im;择olint;樓iíሄ;䑁otƀ;be㌴ᵇ㌵担;橦΀Aacmstx㍆㍊㍗㍛㍞㍣㍭rr;懘rĀhr㍐㍒ë∨Ā;oਸ਼਴t耻§䂧i;䀻war;椩mĀin㍩ðnuóñt;朶rĀ;o㍶⁕쀀𝔰Ȁacoy㎂㎆㎑㎠rp;景Āhy㎋㎏cy;䑉;䑈rtɭ㎙\0\0㎜iäᑤaraì⹯耻­䂭Āgm㎨㎴maƀ;fv㎱㎲㎲䏃;䏂Ѐ;deglnprካ㏅㏉㏎㏖㏞㏡㏦ot;橪Ā;q኱ኰĀ;E㏓㏔檞;檠Ā;E㏛㏜檝;檟e;扆lus;樤arr;楲aròᄽȀaeit㏸㐈㐏㐗Āls㏽㐄lsetmé㍪hp;樳parsl;槤Ādlᑣ㐔e;挣Ā;e㐜㐝檪Ā;s㐢㐣檬;쀀⪬︀ƀflp㐮㐳㑂tcy;䑌Ā;b㐸㐹䀯Ā;a㐾㐿槄r;挿f;쀀𝕤aĀdr㑍ЂesĀ;u㑔㑕晠it»㑕ƀcsu㑠㑹㒟Āau㑥㑯pĀ;sᆈ㑫;쀀⊓︀pĀ;sᆴ㑵;쀀⊔︀uĀbp㑿㒏ƀ;esᆗᆜ㒆etĀ;eᆗ㒍ñᆝƀ;esᆨᆭ㒖etĀ;eᆨ㒝ñᆮƀ;afᅻ㒦ְrť㒫ֱ»ᅼaròᅈȀcemt㒹㒾㓂㓅r;쀀𝓈tmîñiì㐕aræᆾĀar㓎㓕rĀ;f㓔ឿ昆Āan㓚㓭ightĀep㓣㓪psiloîỠhé⺯s»⡒ʀbcmnp㓻㕞ሉ㖋㖎Ҁ;Edemnprs㔎㔏㔑㔕㔞㔣㔬㔱㔶抂;櫅ot;檽Ā;dᇚ㔚ot;櫃ult;櫁ĀEe㔨㔪;櫋;把lus;檿arr;楹ƀeiu㔽㕒㕕tƀ;en㔎㕅㕋qĀ;qᇚ㔏eqĀ;q㔫㔨m;櫇Ābp㕚㕜;櫕;櫓c̀;acensᇭ㕬㕲㕹㕻㌦pproø㋺urlyeñᇾñᇳƀaes㖂㖈㌛pproø㌚qñ㌗g;晪ڀ123;Edehlmnps㖩㖬㖯ሜ㖲㖴㗀㗉㗕㗚㗟㗨㗭耻¹䂹耻²䂲耻³䂳;櫆Āos㖹㖼t;檾ub;櫘Ā;dሢ㗅ot;櫄sĀou㗏㗒l;柉b;櫗arr;楻ult;櫂ĀEe㗤㗦;櫌;抋lus;櫀ƀeiu㗴㘉㘌tƀ;enሜ㗼㘂qĀ;qሢ㖲eqĀ;q㗧㗤m;櫈Ābp㘑㘓;櫔;櫖ƀAan㘜㘠㘭rr;懙rĀhr㘦㘨ë∮Ā;oਫ਩war;椪lig耻ß䃟௡㙑㙝㙠ዎ㙳㙹\0㙾㛂\0\0\0\0\0㛛㜃\0㜉㝬\0\0\0㞇ɲ㙖\0\0㙛get;挖;䏄rë๟ƀaey㙦㙫㙰ron;䅥dil;䅣;䑂lrec;挕r;쀀𝔱Ȁeiko㚆㚝㚵㚼ǲ㚋\0㚑eĀ4fኄኁaƀ;sv㚘㚙㚛䎸ym;䏑Ācn㚢㚲kĀas㚨㚮pproø዁im»ኬsðኞĀas㚺㚮ð዁rn耻þ䃾Ǭ̟㛆⋧es膀×;bd㛏㛐㛘䃗Ā;aᤏ㛕r;樱;樰ƀeps㛡㛣㜀á⩍Ȁ;bcf҆㛬㛰㛴ot;挶ir;櫱Ā;o㛹㛼쀀𝕥rk;櫚á㍢rime;怴ƀaip㜏㜒㝤dåቈ΀adempst㜡㝍㝀㝑㝗㝜㝟ngleʀ;dlqr㜰㜱㜶㝀㝂斵own»ᶻeftĀ;e⠀㜾ñम;扜ightĀ;e㊪㝋ñၚot;旬inus;樺lus;樹b;槍ime;樻ezium;揢ƀcht㝲㝽㞁Āry㝷㝻;쀀𝓉;䑆cy;䑛rok;䅧Āio㞋㞎xô᝷headĀlr㞗㞠eftarro÷ࡏightarrow»ཝऀAHabcdfghlmoprstuw㟐㟓㟗㟤㟰㟼㠎㠜㠣㠴㡑㡝㡫㢩㣌㣒㣪㣶ròϭar;楣Ācr㟜㟢ute耻ú䃺òᅐrǣ㟪\0㟭y;䑞ve;䅭Āiy㟵㟺rc耻û䃻;䑃ƀabh㠃㠆㠋ròᎭlac;䅱aòᏃĀir㠓㠘sht;楾;쀀𝔲rave耻ù䃹š㠧㠱rĀlr㠬㠮»ॗ»ႃlk;斀Āct㠹㡍ɯ㠿\0\0㡊rnĀ;e㡅㡆挜r»㡆op;挏ri;旸Āal㡖㡚cr;䅫肻¨͉Āgp㡢㡦on;䅳f;쀀𝕦̀adhlsuᅋ㡸㡽፲㢑㢠ownáᎳarpoonĀlr㢈㢌efô㠭ighô㠯iƀ;hl㢙㢚㢜䏅»ᏺon»㢚parrows;懈ƀcit㢰㣄㣈ɯ㢶\0\0㣁rnĀ;e㢼㢽挝r»㢽op;挎ng;䅯ri;旹cr;쀀𝓊ƀdir㣙㣝㣢ot;拰lde;䅩iĀ;f㜰㣨»᠓Āam㣯㣲rò㢨l耻ü䃼angle;榧ހABDacdeflnoprsz㤜㤟㤩㤭㦵㦸㦽㧟㧤㧨㧳㧹㧽㨁㨠ròϷarĀ;v㤦㤧櫨;櫩asèϡĀnr㤲㤷grt;榜΀eknprst㓣㥆㥋㥒㥝㥤㦖appá␕othinçẖƀhir㓫⻈㥙opô⾵Ā;hᎷ㥢ïㆍĀiu㥩㥭gmá㎳Ābp㥲㦄setneqĀ;q㥽㦀쀀⊊︀;쀀⫋︀setneqĀ;q㦏㦒쀀⊋︀;쀀⫌︀Āhr㦛㦟etá㚜iangleĀlr㦪㦯eft»थight»ၑy;䐲ash»ံƀelr㧄㧒㧗ƀ;beⷪ㧋㧏ar;抻q;扚lip;拮Ābt㧜ᑨaòᑩr;쀀𝔳tré㦮suĀbp㧯㧱»ജ»൙pf;쀀𝕧roð໻tré㦴Ācu㨆㨋r;쀀𝓋Ābp㨐㨘nĀEe㦀㨖»㥾nĀEe㦒㨞»㦐igzag;榚΀cefoprs㨶㨻㩖㩛㩔㩡㩪irc;䅵Ādi㩀㩑Ābg㩅㩉ar;機eĀ;qᗺ㩏;扙erp;愘r;쀀𝔴pf;쀀𝕨Ā;eᑹ㩦atèᑹcr;쀀𝓌ૣណ㪇\0㪋\0㪐㪛\0\0㪝㪨㪫㪯\0\0㫃㫎\0㫘ៜ៟tré៑r;쀀𝔵ĀAa㪔㪗ròσrò৶;䎾ĀAa㪡㪤ròθrò৫að✓is;拻ƀdptឤ㪵㪾Āfl㪺ឩ;쀀𝕩imåឲĀAa㫇㫊ròώròਁĀcq㫒ីr;쀀𝓍Āpt៖㫜ré។Ѐacefiosu㫰㫽㬈㬌㬑㬕㬛㬡cĀuy㫶㫻te耻ý䃽;䑏Āiy㬂㬆rc;䅷;䑋n耻¥䂥r;쀀𝔶cy;䑗pf;쀀𝕪cr;쀀𝓎Ācm㬦㬩y;䑎l耻ÿ䃿Ԁacdefhiosw㭂㭈㭔㭘㭤㭩㭭㭴㭺㮀cute;䅺Āay㭍㭒ron;䅾;䐷ot;䅼Āet㭝㭡træᕟa;䎶r;쀀𝔷cy;䐶grarr;懝pf;쀀𝕫cr;쀀𝓏Ājn㮅㮇;怍j;怌'.split("").map(function(e) {
      return e.charCodeAt(0);
    })
  )), cu;
}
var ou = {}, _r;
function Qs() {
  return _r || (_r = 1, Object.defineProperty(ou, "__esModule", { value: !0 }), ou.default = new Uint16Array(
    // prettier-ignore
    "Ȁaglq	\x1Bɭ\0\0p;䀦os;䀧t;䀾t;䀼uot;䀢".split("").map(function(e) {
      return e.charCodeAt(0);
    })
  )), ou;
}
var Uu = {}, Ir;
function kr() {
  return Ir || (Ir = 1, (function(e) {
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
    (u = String.fromCodePoint) !== null && u !== void 0 ? u : function(r) {
      var o = "";
      return r > 65535 && (r -= 65536, o += String.fromCharCode(r >>> 10 & 1023 | 55296), r = 56320 | r & 1023), o += String.fromCharCode(r), o;
    };
    function s(r) {
      var o;
      return r >= 55296 && r <= 57343 || r > 1114111 ? 65533 : (o = t.get(r)) !== null && o !== void 0 ? o : r;
    }
    e.replaceCodePoint = s;
    function a(r) {
      return (0, e.fromCodePoint)(s(r));
    }
    e.default = a;
  })(Uu)), Uu;
}
var Br;
function Fr() {
  return Br || (Br = 1, (function(e) {
    var u = be && be.__createBinding || (Object.create ? (function(v, k, S, F) {
      F === void 0 && (F = S);
      var I = Object.getOwnPropertyDescriptor(k, S);
      (!I || ("get" in I ? !k.__esModule : I.writable || I.configurable)) && (I = { enumerable: !0, get: function() {
        return k[S];
      } }), Object.defineProperty(v, F, I);
    }) : (function(v, k, S, F) {
      F === void 0 && (F = S), v[F] = k[S];
    })), t = be && be.__setModuleDefault || (Object.create ? (function(v, k) {
      Object.defineProperty(v, "default", { enumerable: !0, value: k });
    }) : function(v, k) {
      v.default = k;
    }), s = be && be.__importStar || function(v) {
      if (v && v.__esModule) return v;
      var k = {};
      if (v != null) for (var S in v) S !== "default" && Object.prototype.hasOwnProperty.call(v, S) && u(k, v, S);
      return t(k, v), k;
    }, a = be && be.__importDefault || function(v) {
      return v && v.__esModule ? v : { default: v };
    };
    Object.defineProperty(e, "__esModule", { value: !0 }), e.decodeXML = e.decodeHTMLStrict = e.decodeHTMLAttribute = e.decodeHTML = e.determineBranch = e.EntityDecoder = e.DecodingMode = e.BinTrieFlags = e.fromCodePoint = e.replaceCodePoint = e.decodeCodePoint = e.xmlDecodeTree = e.htmlDecodeTree = void 0;
    var r = a(/* @__PURE__ */ Os());
    e.htmlDecodeTree = r.default;
    var o = a(/* @__PURE__ */ Qs());
    e.xmlDecodeTree = o.default;
    var i = s(/* @__PURE__ */ kr());
    e.decodeCodePoint = i.default;
    var c = /* @__PURE__ */ kr();
    Object.defineProperty(e, "replaceCodePoint", { enumerable: !0, get: function() {
      return c.replaceCodePoint;
    } }), Object.defineProperty(e, "fromCodePoint", { enumerable: !0, get: function() {
      return c.fromCodePoint;
    } });
    var n;
    (function(v) {
      v[v.NUM = 35] = "NUM", v[v.SEMI = 59] = "SEMI", v[v.EQUALS = 61] = "EQUALS", v[v.ZERO = 48] = "ZERO", v[v.NINE = 57] = "NINE", v[v.LOWER_A = 97] = "LOWER_A", v[v.LOWER_F = 102] = "LOWER_F", v[v.LOWER_X = 120] = "LOWER_X", v[v.LOWER_Z = 122] = "LOWER_Z", v[v.UPPER_A = 65] = "UPPER_A", v[v.UPPER_F = 70] = "UPPER_F", v[v.UPPER_Z = 90] = "UPPER_Z";
    })(n || (n = {}));
    var l = 32, f;
    (function(v) {
      v[v.VALUE_LENGTH = 49152] = "VALUE_LENGTH", v[v.BRANCH_LENGTH = 16256] = "BRANCH_LENGTH", v[v.JUMP_TABLE = 127] = "JUMP_TABLE";
    })(f = e.BinTrieFlags || (e.BinTrieFlags = {}));
    function A(v) {
      return v >= n.ZERO && v <= n.NINE;
    }
    function d(v) {
      return v >= n.UPPER_A && v <= n.UPPER_F || v >= n.LOWER_A && v <= n.LOWER_F;
    }
    function h(v) {
      return v >= n.UPPER_A && v <= n.UPPER_Z || v >= n.LOWER_A && v <= n.LOWER_Z || A(v);
    }
    function y(v) {
      return v === n.EQUALS || h(v);
    }
    var C;
    (function(v) {
      v[v.EntityStart = 0] = "EntityStart", v[v.NumericStart = 1] = "NumericStart", v[v.NumericDecimal = 2] = "NumericDecimal", v[v.NumericHex = 3] = "NumericHex", v[v.NamedEntity = 4] = "NamedEntity";
    })(C || (C = {}));
    var w;
    (function(v) {
      v[v.Legacy = 0] = "Legacy", v[v.Strict = 1] = "Strict", v[v.Attribute = 2] = "Attribute";
    })(w = e.DecodingMode || (e.DecodingMode = {}));
    var b = (
      /** @class */
      (function() {
        function v(k, S, F) {
          this.decodeTree = k, this.emitCodePoint = S, this.errors = F, this.state = C.EntityStart, this.consumed = 1, this.result = 0, this.treeIndex = 0, this.excess = 1, this.decodeMode = w.Strict;
        }
        return v.prototype.startEntity = function(k) {
          this.decodeMode = k, this.state = C.EntityStart, this.result = 0, this.treeIndex = 0, this.excess = 1, this.consumed = 1;
        }, v.prototype.write = function(k, S) {
          switch (this.state) {
            case C.EntityStart:
              return k.charCodeAt(S) === n.NUM ? (this.state = C.NumericStart, this.consumed += 1, this.stateNumericStart(k, S + 1)) : (this.state = C.NamedEntity, this.stateNamedEntity(k, S));
            case C.NumericStart:
              return this.stateNumericStart(k, S);
            case C.NumericDecimal:
              return this.stateNumericDecimal(k, S);
            case C.NumericHex:
              return this.stateNumericHex(k, S);
            case C.NamedEntity:
              return this.stateNamedEntity(k, S);
          }
        }, v.prototype.stateNumericStart = function(k, S) {
          return S >= k.length ? -1 : (k.charCodeAt(S) | l) === n.LOWER_X ? (this.state = C.NumericHex, this.consumed += 1, this.stateNumericHex(k, S + 1)) : (this.state = C.NumericDecimal, this.stateNumericDecimal(k, S));
        }, v.prototype.addToNumericResult = function(k, S, F, I) {
          if (S !== F) {
            var T = F - S;
            this.result = this.result * Math.pow(I, T) + parseInt(k.substr(S, T), I), this.consumed += T;
          }
        }, v.prototype.stateNumericHex = function(k, S) {
          for (var F = S; S < k.length; ) {
            var I = k.charCodeAt(S);
            if (A(I) || d(I))
              S += 1;
            else
              return this.addToNumericResult(k, F, S, 16), this.emitNumericEntity(I, 3);
          }
          return this.addToNumericResult(k, F, S, 16), -1;
        }, v.prototype.stateNumericDecimal = function(k, S) {
          for (var F = S; S < k.length; ) {
            var I = k.charCodeAt(S);
            if (A(I))
              S += 1;
            else
              return this.addToNumericResult(k, F, S, 10), this.emitNumericEntity(I, 2);
          }
          return this.addToNumericResult(k, F, S, 10), -1;
        }, v.prototype.emitNumericEntity = function(k, S) {
          var F;
          if (this.consumed <= S)
            return (F = this.errors) === null || F === void 0 || F.absenceOfDigitsInNumericCharacterReference(this.consumed), 0;
          if (k === n.SEMI)
            this.consumed += 1;
          else if (this.decodeMode === w.Strict)
            return 0;
          return this.emitCodePoint((0, i.replaceCodePoint)(this.result), this.consumed), this.errors && (k !== n.SEMI && this.errors.missingSemicolonAfterCharacterReference(), this.errors.validateNumericCharacterReference(this.result)), this.consumed;
        }, v.prototype.stateNamedEntity = function(k, S) {
          for (var F = this.decodeTree, I = F[this.treeIndex], T = (I & f.VALUE_LENGTH) >> 14; S < k.length; S++, this.excess++) {
            var M = k.charCodeAt(S);
            if (this.treeIndex = m(F, I, this.treeIndex + Math.max(1, T), M), this.treeIndex < 0)
              return this.result === 0 || // If we are parsing an attribute
              this.decodeMode === w.Attribute && // We shouldn't have consumed any characters after the entity,
              (T === 0 || // And there should be no invalid characters.
              y(M)) ? 0 : this.emitNotTerminatedNamedEntity();
            if (I = F[this.treeIndex], T = (I & f.VALUE_LENGTH) >> 14, T !== 0) {
              if (M === n.SEMI)
                return this.emitNamedEntityData(this.treeIndex, T, this.consumed + this.excess);
              this.decodeMode !== w.Strict && (this.result = this.treeIndex, this.consumed += this.excess, this.excess = 0);
            }
          }
          return -1;
        }, v.prototype.emitNotTerminatedNamedEntity = function() {
          var k, S = this, F = S.result, I = S.decodeTree, T = (I[F] & f.VALUE_LENGTH) >> 14;
          return this.emitNamedEntityData(F, T, this.consumed), (k = this.errors) === null || k === void 0 || k.missingSemicolonAfterCharacterReference(), this.consumed;
        }, v.prototype.emitNamedEntityData = function(k, S, F) {
          var I = this.decodeTree;
          return this.emitCodePoint(S === 1 ? I[k] & ~f.VALUE_LENGTH : I[k + 1], F), S === 3 && this.emitCodePoint(I[k + 2], F), F;
        }, v.prototype.end = function() {
          var k;
          switch (this.state) {
            case C.NamedEntity:
              return this.result !== 0 && (this.decodeMode !== w.Attribute || this.result === this.treeIndex) ? this.emitNotTerminatedNamedEntity() : 0;
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
        }, v;
      })()
    );
    e.EntityDecoder = b;
    function x(v) {
      var k = "", S = new b(v, function(F) {
        return k += (0, i.fromCodePoint)(F);
      });
      return function(I, T) {
        for (var M = 0, N = 0; (N = I.indexOf("&", N)) >= 0; ) {
          k += I.slice(M, N), S.startEntity(T);
          var P = S.write(
            I,
            // Skip the "&"
            N + 1
          );
          if (P < 0) {
            M = N + S.end();
            break;
          }
          M = N + P, N = P === 0 ? M + 1 : M;
        }
        var G = k + I.slice(M);
        return k = "", G;
      };
    }
    function m(v, k, S, F) {
      var I = (k & f.BRANCH_LENGTH) >> 7, T = k & f.JUMP_TABLE;
      if (I === 0)
        return T !== 0 && F === T ? S : -1;
      if (T) {
        var M = F - T;
        return M < 0 || M >= I ? -1 : v[S + M] - 1;
      }
      for (var N = S, P = N + I - 1; N <= P; ) {
        var G = N + P >>> 1, H = v[G];
        if (H < F)
          N = G + 1;
        else if (H > F)
          P = G - 1;
        else
          return v[G + I];
      }
      return -1;
    }
    e.determineBranch = m;
    var p = x(r.default), g = x(o.default);
    function D(v, k) {
      return k === void 0 && (k = w.Legacy), p(v, k);
    }
    e.decodeHTML = D;
    function B(v) {
      return p(v, w.Attribute);
    }
    e.decodeHTMLAttribute = B;
    function E(v) {
      return p(v, w.Strict);
    }
    e.decodeHTMLStrict = E;
    function _(v) {
      return g(v, w.Strict);
    }
    e.decodeXML = _;
  })(be)), be;
}
var Ee = {}, lu = {}, Sr;
function Ls() {
  if (Sr) return lu;
  Sr = 1, Object.defineProperty(lu, "__esModule", { value: !0 });
  function e(u) {
    for (var t = 1; t < u.length; t++)
      u[t][0] += u[t - 1][0] + 1;
    return u;
  }
  return lu.default = new Map(/* @__PURE__ */ e([[9, "&Tab;"], [0, "&NewLine;"], [22, "&excl;"], [0, "&quot;"], [0, "&num;"], [0, "&dollar;"], [0, "&percnt;"], [0, "&amp;"], [0, "&apos;"], [0, "&lpar;"], [0, "&rpar;"], [0, "&ast;"], [0, "&plus;"], [0, "&comma;"], [1, "&period;"], [0, "&sol;"], [10, "&colon;"], [0, "&semi;"], [0, { v: "&lt;", n: 8402, o: "&nvlt;" }], [0, { v: "&equals;", n: 8421, o: "&bne;" }], [0, { v: "&gt;", n: 8402, o: "&nvgt;" }], [0, "&quest;"], [0, "&commat;"], [26, "&lbrack;"], [0, "&bsol;"], [0, "&rbrack;"], [0, "&Hat;"], [0, "&lowbar;"], [0, "&DiacriticalGrave;"], [5, { n: 106, o: "&fjlig;" }], [20, "&lbrace;"], [0, "&verbar;"], [0, "&rbrace;"], [34, "&nbsp;"], [0, "&iexcl;"], [0, "&cent;"], [0, "&pound;"], [0, "&curren;"], [0, "&yen;"], [0, "&brvbar;"], [0, "&sect;"], [0, "&die;"], [0, "&copy;"], [0, "&ordf;"], [0, "&laquo;"], [0, "&not;"], [0, "&shy;"], [0, "&circledR;"], [0, "&macr;"], [0, "&deg;"], [0, "&PlusMinus;"], [0, "&sup2;"], [0, "&sup3;"], [0, "&acute;"], [0, "&micro;"], [0, "&para;"], [0, "&centerdot;"], [0, "&cedil;"], [0, "&sup1;"], [0, "&ordm;"], [0, "&raquo;"], [0, "&frac14;"], [0, "&frac12;"], [0, "&frac34;"], [0, "&iquest;"], [0, "&Agrave;"], [0, "&Aacute;"], [0, "&Acirc;"], [0, "&Atilde;"], [0, "&Auml;"], [0, "&angst;"], [0, "&AElig;"], [0, "&Ccedil;"], [0, "&Egrave;"], [0, "&Eacute;"], [0, "&Ecirc;"], [0, "&Euml;"], [0, "&Igrave;"], [0, "&Iacute;"], [0, "&Icirc;"], [0, "&Iuml;"], [0, "&ETH;"], [0, "&Ntilde;"], [0, "&Ograve;"], [0, "&Oacute;"], [0, "&Ocirc;"], [0, "&Otilde;"], [0, "&Ouml;"], [0, "&times;"], [0, "&Oslash;"], [0, "&Ugrave;"], [0, "&Uacute;"], [0, "&Ucirc;"], [0, "&Uuml;"], [0, "&Yacute;"], [0, "&THORN;"], [0, "&szlig;"], [0, "&agrave;"], [0, "&aacute;"], [0, "&acirc;"], [0, "&atilde;"], [0, "&auml;"], [0, "&aring;"], [0, "&aelig;"], [0, "&ccedil;"], [0, "&egrave;"], [0, "&eacute;"], [0, "&ecirc;"], [0, "&euml;"], [0, "&igrave;"], [0, "&iacute;"], [0, "&icirc;"], [0, "&iuml;"], [0, "&eth;"], [0, "&ntilde;"], [0, "&ograve;"], [0, "&oacute;"], [0, "&ocirc;"], [0, "&otilde;"], [0, "&ouml;"], [0, "&div;"], [0, "&oslash;"], [0, "&ugrave;"], [0, "&uacute;"], [0, "&ucirc;"], [0, "&uuml;"], [0, "&yacute;"], [0, "&thorn;"], [0, "&yuml;"], [0, "&Amacr;"], [0, "&amacr;"], [0, "&Abreve;"], [0, "&abreve;"], [0, "&Aogon;"], [0, "&aogon;"], [0, "&Cacute;"], [0, "&cacute;"], [0, "&Ccirc;"], [0, "&ccirc;"], [0, "&Cdot;"], [0, "&cdot;"], [0, "&Ccaron;"], [0, "&ccaron;"], [0, "&Dcaron;"], [0, "&dcaron;"], [0, "&Dstrok;"], [0, "&dstrok;"], [0, "&Emacr;"], [0, "&emacr;"], [2, "&Edot;"], [0, "&edot;"], [0, "&Eogon;"], [0, "&eogon;"], [0, "&Ecaron;"], [0, "&ecaron;"], [0, "&Gcirc;"], [0, "&gcirc;"], [0, "&Gbreve;"], [0, "&gbreve;"], [0, "&Gdot;"], [0, "&gdot;"], [0, "&Gcedil;"], [1, "&Hcirc;"], [0, "&hcirc;"], [0, "&Hstrok;"], [0, "&hstrok;"], [0, "&Itilde;"], [0, "&itilde;"], [0, "&Imacr;"], [0, "&imacr;"], [2, "&Iogon;"], [0, "&iogon;"], [0, "&Idot;"], [0, "&imath;"], [0, "&IJlig;"], [0, "&ijlig;"], [0, "&Jcirc;"], [0, "&jcirc;"], [0, "&Kcedil;"], [0, "&kcedil;"], [0, "&kgreen;"], [0, "&Lacute;"], [0, "&lacute;"], [0, "&Lcedil;"], [0, "&lcedil;"], [0, "&Lcaron;"], [0, "&lcaron;"], [0, "&Lmidot;"], [0, "&lmidot;"], [0, "&Lstrok;"], [0, "&lstrok;"], [0, "&Nacute;"], [0, "&nacute;"], [0, "&Ncedil;"], [0, "&ncedil;"], [0, "&Ncaron;"], [0, "&ncaron;"], [0, "&napos;"], [0, "&ENG;"], [0, "&eng;"], [0, "&Omacr;"], [0, "&omacr;"], [2, "&Odblac;"], [0, "&odblac;"], [0, "&OElig;"], [0, "&oelig;"], [0, "&Racute;"], [0, "&racute;"], [0, "&Rcedil;"], [0, "&rcedil;"], [0, "&Rcaron;"], [0, "&rcaron;"], [0, "&Sacute;"], [0, "&sacute;"], [0, "&Scirc;"], [0, "&scirc;"], [0, "&Scedil;"], [0, "&scedil;"], [0, "&Scaron;"], [0, "&scaron;"], [0, "&Tcedil;"], [0, "&tcedil;"], [0, "&Tcaron;"], [0, "&tcaron;"], [0, "&Tstrok;"], [0, "&tstrok;"], [0, "&Utilde;"], [0, "&utilde;"], [0, "&Umacr;"], [0, "&umacr;"], [0, "&Ubreve;"], [0, "&ubreve;"], [0, "&Uring;"], [0, "&uring;"], [0, "&Udblac;"], [0, "&udblac;"], [0, "&Uogon;"], [0, "&uogon;"], [0, "&Wcirc;"], [0, "&wcirc;"], [0, "&Ycirc;"], [0, "&ycirc;"], [0, "&Yuml;"], [0, "&Zacute;"], [0, "&zacute;"], [0, "&Zdot;"], [0, "&zdot;"], [0, "&Zcaron;"], [0, "&zcaron;"], [19, "&fnof;"], [34, "&imped;"], [63, "&gacute;"], [65, "&jmath;"], [142, "&circ;"], [0, "&caron;"], [16, "&breve;"], [0, "&DiacriticalDot;"], [0, "&ring;"], [0, "&ogon;"], [0, "&DiacriticalTilde;"], [0, "&dblac;"], [51, "&DownBreve;"], [127, "&Alpha;"], [0, "&Beta;"], [0, "&Gamma;"], [0, "&Delta;"], [0, "&Epsilon;"], [0, "&Zeta;"], [0, "&Eta;"], [0, "&Theta;"], [0, "&Iota;"], [0, "&Kappa;"], [0, "&Lambda;"], [0, "&Mu;"], [0, "&Nu;"], [0, "&Xi;"], [0, "&Omicron;"], [0, "&Pi;"], [0, "&Rho;"], [1, "&Sigma;"], [0, "&Tau;"], [0, "&Upsilon;"], [0, "&Phi;"], [0, "&Chi;"], [0, "&Psi;"], [0, "&ohm;"], [7, "&alpha;"], [0, "&beta;"], [0, "&gamma;"], [0, "&delta;"], [0, "&epsi;"], [0, "&zeta;"], [0, "&eta;"], [0, "&theta;"], [0, "&iota;"], [0, "&kappa;"], [0, "&lambda;"], [0, "&mu;"], [0, "&nu;"], [0, "&xi;"], [0, "&omicron;"], [0, "&pi;"], [0, "&rho;"], [0, "&sigmaf;"], [0, "&sigma;"], [0, "&tau;"], [0, "&upsi;"], [0, "&phi;"], [0, "&chi;"], [0, "&psi;"], [0, "&omega;"], [7, "&thetasym;"], [0, "&Upsi;"], [2, "&phiv;"], [0, "&piv;"], [5, "&Gammad;"], [0, "&digamma;"], [18, "&kappav;"], [0, "&rhov;"], [3, "&epsiv;"], [0, "&backepsilon;"], [10, "&IOcy;"], [0, "&DJcy;"], [0, "&GJcy;"], [0, "&Jukcy;"], [0, "&DScy;"], [0, "&Iukcy;"], [0, "&YIcy;"], [0, "&Jsercy;"], [0, "&LJcy;"], [0, "&NJcy;"], [0, "&TSHcy;"], [0, "&KJcy;"], [1, "&Ubrcy;"], [0, "&DZcy;"], [0, "&Acy;"], [0, "&Bcy;"], [0, "&Vcy;"], [0, "&Gcy;"], [0, "&Dcy;"], [0, "&IEcy;"], [0, "&ZHcy;"], [0, "&Zcy;"], [0, "&Icy;"], [0, "&Jcy;"], [0, "&Kcy;"], [0, "&Lcy;"], [0, "&Mcy;"], [0, "&Ncy;"], [0, "&Ocy;"], [0, "&Pcy;"], [0, "&Rcy;"], [0, "&Scy;"], [0, "&Tcy;"], [0, "&Ucy;"], [0, "&Fcy;"], [0, "&KHcy;"], [0, "&TScy;"], [0, "&CHcy;"], [0, "&SHcy;"], [0, "&SHCHcy;"], [0, "&HARDcy;"], [0, "&Ycy;"], [0, "&SOFTcy;"], [0, "&Ecy;"], [0, "&YUcy;"], [0, "&YAcy;"], [0, "&acy;"], [0, "&bcy;"], [0, "&vcy;"], [0, "&gcy;"], [0, "&dcy;"], [0, "&iecy;"], [0, "&zhcy;"], [0, "&zcy;"], [0, "&icy;"], [0, "&jcy;"], [0, "&kcy;"], [0, "&lcy;"], [0, "&mcy;"], [0, "&ncy;"], [0, "&ocy;"], [0, "&pcy;"], [0, "&rcy;"], [0, "&scy;"], [0, "&tcy;"], [0, "&ucy;"], [0, "&fcy;"], [0, "&khcy;"], [0, "&tscy;"], [0, "&chcy;"], [0, "&shcy;"], [0, "&shchcy;"], [0, "&hardcy;"], [0, "&ycy;"], [0, "&softcy;"], [0, "&ecy;"], [0, "&yucy;"], [0, "&yacy;"], [1, "&iocy;"], [0, "&djcy;"], [0, "&gjcy;"], [0, "&jukcy;"], [0, "&dscy;"], [0, "&iukcy;"], [0, "&yicy;"], [0, "&jsercy;"], [0, "&ljcy;"], [0, "&njcy;"], [0, "&tshcy;"], [0, "&kjcy;"], [1, "&ubrcy;"], [0, "&dzcy;"], [7074, "&ensp;"], [0, "&emsp;"], [0, "&emsp13;"], [0, "&emsp14;"], [1, "&numsp;"], [0, "&puncsp;"], [0, "&ThinSpace;"], [0, "&hairsp;"], [0, "&NegativeMediumSpace;"], [0, "&zwnj;"], [0, "&zwj;"], [0, "&lrm;"], [0, "&rlm;"], [0, "&dash;"], [2, "&ndash;"], [0, "&mdash;"], [0, "&horbar;"], [0, "&Verbar;"], [1, "&lsquo;"], [0, "&CloseCurlyQuote;"], [0, "&lsquor;"], [1, "&ldquo;"], [0, "&CloseCurlyDoubleQuote;"], [0, "&bdquo;"], [1, "&dagger;"], [0, "&Dagger;"], [0, "&bull;"], [2, "&nldr;"], [0, "&hellip;"], [9, "&permil;"], [0, "&pertenk;"], [0, "&prime;"], [0, "&Prime;"], [0, "&tprime;"], [0, "&backprime;"], [3, "&lsaquo;"], [0, "&rsaquo;"], [3, "&oline;"], [2, "&caret;"], [1, "&hybull;"], [0, "&frasl;"], [10, "&bsemi;"], [7, "&qprime;"], [7, { v: "&MediumSpace;", n: 8202, o: "&ThickSpace;" }], [0, "&NoBreak;"], [0, "&af;"], [0, "&InvisibleTimes;"], [0, "&ic;"], [72, "&euro;"], [46, "&tdot;"], [0, "&DotDot;"], [37, "&complexes;"], [2, "&incare;"], [4, "&gscr;"], [0, "&hamilt;"], [0, "&Hfr;"], [0, "&Hopf;"], [0, "&planckh;"], [0, "&hbar;"], [0, "&imagline;"], [0, "&Ifr;"], [0, "&lagran;"], [0, "&ell;"], [1, "&naturals;"], [0, "&numero;"], [0, "&copysr;"], [0, "&weierp;"], [0, "&Popf;"], [0, "&Qopf;"], [0, "&realine;"], [0, "&real;"], [0, "&reals;"], [0, "&rx;"], [3, "&trade;"], [1, "&integers;"], [2, "&mho;"], [0, "&zeetrf;"], [0, "&iiota;"], [2, "&bernou;"], [0, "&Cayleys;"], [1, "&escr;"], [0, "&Escr;"], [0, "&Fouriertrf;"], [1, "&Mellintrf;"], [0, "&order;"], [0, "&alefsym;"], [0, "&beth;"], [0, "&gimel;"], [0, "&daleth;"], [12, "&CapitalDifferentialD;"], [0, "&dd;"], [0, "&ee;"], [0, "&ii;"], [10, "&frac13;"], [0, "&frac23;"], [0, "&frac15;"], [0, "&frac25;"], [0, "&frac35;"], [0, "&frac45;"], [0, "&frac16;"], [0, "&frac56;"], [0, "&frac18;"], [0, "&frac38;"], [0, "&frac58;"], [0, "&frac78;"], [49, "&larr;"], [0, "&ShortUpArrow;"], [0, "&rarr;"], [0, "&darr;"], [0, "&harr;"], [0, "&updownarrow;"], [0, "&nwarr;"], [0, "&nearr;"], [0, "&LowerRightArrow;"], [0, "&LowerLeftArrow;"], [0, "&nlarr;"], [0, "&nrarr;"], [1, { v: "&rarrw;", n: 824, o: "&nrarrw;" }], [0, "&Larr;"], [0, "&Uarr;"], [0, "&Rarr;"], [0, "&Darr;"], [0, "&larrtl;"], [0, "&rarrtl;"], [0, "&LeftTeeArrow;"], [0, "&mapstoup;"], [0, "&map;"], [0, "&DownTeeArrow;"], [1, "&hookleftarrow;"], [0, "&hookrightarrow;"], [0, "&larrlp;"], [0, "&looparrowright;"], [0, "&harrw;"], [0, "&nharr;"], [1, "&lsh;"], [0, "&rsh;"], [0, "&ldsh;"], [0, "&rdsh;"], [1, "&crarr;"], [0, "&cularr;"], [0, "&curarr;"], [2, "&circlearrowleft;"], [0, "&circlearrowright;"], [0, "&leftharpoonup;"], [0, "&DownLeftVector;"], [0, "&RightUpVector;"], [0, "&LeftUpVector;"], [0, "&rharu;"], [0, "&DownRightVector;"], [0, "&dharr;"], [0, "&dharl;"], [0, "&RightArrowLeftArrow;"], [0, "&udarr;"], [0, "&LeftArrowRightArrow;"], [0, "&leftleftarrows;"], [0, "&upuparrows;"], [0, "&rightrightarrows;"], [0, "&ddarr;"], [0, "&leftrightharpoons;"], [0, "&Equilibrium;"], [0, "&nlArr;"], [0, "&nhArr;"], [0, "&nrArr;"], [0, "&DoubleLeftArrow;"], [0, "&DoubleUpArrow;"], [0, "&DoubleRightArrow;"], [0, "&dArr;"], [0, "&DoubleLeftRightArrow;"], [0, "&DoubleUpDownArrow;"], [0, "&nwArr;"], [0, "&neArr;"], [0, "&seArr;"], [0, "&swArr;"], [0, "&lAarr;"], [0, "&rAarr;"], [1, "&zigrarr;"], [6, "&larrb;"], [0, "&rarrb;"], [15, "&DownArrowUpArrow;"], [7, "&loarr;"], [0, "&roarr;"], [0, "&hoarr;"], [0, "&forall;"], [0, "&comp;"], [0, { v: "&part;", n: 824, o: "&npart;" }], [0, "&exist;"], [0, "&nexist;"], [0, "&empty;"], [1, "&Del;"], [0, "&Element;"], [0, "&NotElement;"], [1, "&ni;"], [0, "&notni;"], [2, "&prod;"], [0, "&coprod;"], [0, "&sum;"], [0, "&minus;"], [0, "&MinusPlus;"], [0, "&dotplus;"], [1, "&Backslash;"], [0, "&lowast;"], [0, "&compfn;"], [1, "&radic;"], [2, "&prop;"], [0, "&infin;"], [0, "&angrt;"], [0, { v: "&ang;", n: 8402, o: "&nang;" }], [0, "&angmsd;"], [0, "&angsph;"], [0, "&mid;"], [0, "&nmid;"], [0, "&DoubleVerticalBar;"], [0, "&NotDoubleVerticalBar;"], [0, "&and;"], [0, "&or;"], [0, { v: "&cap;", n: 65024, o: "&caps;" }], [0, { v: "&cup;", n: 65024, o: "&cups;" }], [0, "&int;"], [0, "&Int;"], [0, "&iiint;"], [0, "&conint;"], [0, "&Conint;"], [0, "&Cconint;"], [0, "&cwint;"], [0, "&ClockwiseContourIntegral;"], [0, "&awconint;"], [0, "&there4;"], [0, "&becaus;"], [0, "&ratio;"], [0, "&Colon;"], [0, "&dotminus;"], [1, "&mDDot;"], [0, "&homtht;"], [0, { v: "&sim;", n: 8402, o: "&nvsim;" }], [0, { v: "&backsim;", n: 817, o: "&race;" }], [0, { v: "&ac;", n: 819, o: "&acE;" }], [0, "&acd;"], [0, "&VerticalTilde;"], [0, "&NotTilde;"], [0, { v: "&eqsim;", n: 824, o: "&nesim;" }], [0, "&sime;"], [0, "&NotTildeEqual;"], [0, "&cong;"], [0, "&simne;"], [0, "&ncong;"], [0, "&ap;"], [0, "&nap;"], [0, "&ape;"], [0, { v: "&apid;", n: 824, o: "&napid;" }], [0, "&backcong;"], [0, { v: "&asympeq;", n: 8402, o: "&nvap;" }], [0, { v: "&bump;", n: 824, o: "&nbump;" }], [0, { v: "&bumpe;", n: 824, o: "&nbumpe;" }], [0, { v: "&doteq;", n: 824, o: "&nedot;" }], [0, "&doteqdot;"], [0, "&efDot;"], [0, "&erDot;"], [0, "&Assign;"], [0, "&ecolon;"], [0, "&ecir;"], [0, "&circeq;"], [1, "&wedgeq;"], [0, "&veeeq;"], [1, "&triangleq;"], [2, "&equest;"], [0, "&ne;"], [0, { v: "&Congruent;", n: 8421, o: "&bnequiv;" }], [0, "&nequiv;"], [1, { v: "&le;", n: 8402, o: "&nvle;" }], [0, { v: "&ge;", n: 8402, o: "&nvge;" }], [0, { v: "&lE;", n: 824, o: "&nlE;" }], [0, { v: "&gE;", n: 824, o: "&ngE;" }], [0, { v: "&lnE;", n: 65024, o: "&lvertneqq;" }], [0, { v: "&gnE;", n: 65024, o: "&gvertneqq;" }], [0, { v: "&ll;", n: new Map(/* @__PURE__ */ e([[824, "&nLtv;"], [7577, "&nLt;"]])) }], [0, { v: "&gg;", n: new Map(/* @__PURE__ */ e([[824, "&nGtv;"], [7577, "&nGt;"]])) }], [0, "&between;"], [0, "&NotCupCap;"], [0, "&nless;"], [0, "&ngt;"], [0, "&nle;"], [0, "&nge;"], [0, "&lesssim;"], [0, "&GreaterTilde;"], [0, "&nlsim;"], [0, "&ngsim;"], [0, "&LessGreater;"], [0, "&gl;"], [0, "&NotLessGreater;"], [0, "&NotGreaterLess;"], [0, "&pr;"], [0, "&sc;"], [0, "&prcue;"], [0, "&sccue;"], [0, "&PrecedesTilde;"], [0, { v: "&scsim;", n: 824, o: "&NotSucceedsTilde;" }], [0, "&NotPrecedes;"], [0, "&NotSucceeds;"], [0, { v: "&sub;", n: 8402, o: "&NotSubset;" }], [0, { v: "&sup;", n: 8402, o: "&NotSuperset;" }], [0, "&nsub;"], [0, "&nsup;"], [0, "&sube;"], [0, "&supe;"], [0, "&NotSubsetEqual;"], [0, "&NotSupersetEqual;"], [0, { v: "&subne;", n: 65024, o: "&varsubsetneq;" }], [0, { v: "&supne;", n: 65024, o: "&varsupsetneq;" }], [1, "&cupdot;"], [0, "&UnionPlus;"], [0, { v: "&sqsub;", n: 824, o: "&NotSquareSubset;" }], [0, { v: "&sqsup;", n: 824, o: "&NotSquareSuperset;" }], [0, "&sqsube;"], [0, "&sqsupe;"], [0, { v: "&sqcap;", n: 65024, o: "&sqcaps;" }], [0, { v: "&sqcup;", n: 65024, o: "&sqcups;" }], [0, "&CirclePlus;"], [0, "&CircleMinus;"], [0, "&CircleTimes;"], [0, "&osol;"], [0, "&CircleDot;"], [0, "&circledcirc;"], [0, "&circledast;"], [1, "&circleddash;"], [0, "&boxplus;"], [0, "&boxminus;"], [0, "&boxtimes;"], [0, "&dotsquare;"], [0, "&RightTee;"], [0, "&dashv;"], [0, "&DownTee;"], [0, "&bot;"], [1, "&models;"], [0, "&DoubleRightTee;"], [0, "&Vdash;"], [0, "&Vvdash;"], [0, "&VDash;"], [0, "&nvdash;"], [0, "&nvDash;"], [0, "&nVdash;"], [0, "&nVDash;"], [0, "&prurel;"], [1, "&LeftTriangle;"], [0, "&RightTriangle;"], [0, { v: "&LeftTriangleEqual;", n: 8402, o: "&nvltrie;" }], [0, { v: "&RightTriangleEqual;", n: 8402, o: "&nvrtrie;" }], [0, "&origof;"], [0, "&imof;"], [0, "&multimap;"], [0, "&hercon;"], [0, "&intcal;"], [0, "&veebar;"], [1, "&barvee;"], [0, "&angrtvb;"], [0, "&lrtri;"], [0, "&bigwedge;"], [0, "&bigvee;"], [0, "&bigcap;"], [0, "&bigcup;"], [0, "&diam;"], [0, "&sdot;"], [0, "&sstarf;"], [0, "&divideontimes;"], [0, "&bowtie;"], [0, "&ltimes;"], [0, "&rtimes;"], [0, "&leftthreetimes;"], [0, "&rightthreetimes;"], [0, "&backsimeq;"], [0, "&curlyvee;"], [0, "&curlywedge;"], [0, "&Sub;"], [0, "&Sup;"], [0, "&Cap;"], [0, "&Cup;"], [0, "&fork;"], [0, "&epar;"], [0, "&lessdot;"], [0, "&gtdot;"], [0, { v: "&Ll;", n: 824, o: "&nLl;" }], [0, { v: "&Gg;", n: 824, o: "&nGg;" }], [0, { v: "&leg;", n: 65024, o: "&lesg;" }], [0, { v: "&gel;", n: 65024, o: "&gesl;" }], [2, "&cuepr;"], [0, "&cuesc;"], [0, "&NotPrecedesSlantEqual;"], [0, "&NotSucceedsSlantEqual;"], [0, "&NotSquareSubsetEqual;"], [0, "&NotSquareSupersetEqual;"], [2, "&lnsim;"], [0, "&gnsim;"], [0, "&precnsim;"], [0, "&scnsim;"], [0, "&nltri;"], [0, "&NotRightTriangle;"], [0, "&nltrie;"], [0, "&NotRightTriangleEqual;"], [0, "&vellip;"], [0, "&ctdot;"], [0, "&utdot;"], [0, "&dtdot;"], [0, "&disin;"], [0, "&isinsv;"], [0, "&isins;"], [0, { v: "&isindot;", n: 824, o: "&notindot;" }], [0, "&notinvc;"], [0, "&notinvb;"], [1, { v: "&isinE;", n: 824, o: "&notinE;" }], [0, "&nisd;"], [0, "&xnis;"], [0, "&nis;"], [0, "&notnivc;"], [0, "&notnivb;"], [6, "&barwed;"], [0, "&Barwed;"], [1, "&lceil;"], [0, "&rceil;"], [0, "&LeftFloor;"], [0, "&rfloor;"], [0, "&drcrop;"], [0, "&dlcrop;"], [0, "&urcrop;"], [0, "&ulcrop;"], [0, "&bnot;"], [1, "&profline;"], [0, "&profsurf;"], [1, "&telrec;"], [0, "&target;"], [5, "&ulcorn;"], [0, "&urcorn;"], [0, "&dlcorn;"], [0, "&drcorn;"], [2, "&frown;"], [0, "&smile;"], [9, "&cylcty;"], [0, "&profalar;"], [7, "&topbot;"], [6, "&ovbar;"], [1, "&solbar;"], [60, "&angzarr;"], [51, "&lmoustache;"], [0, "&rmoustache;"], [2, "&OverBracket;"], [0, "&bbrk;"], [0, "&bbrktbrk;"], [37, "&OverParenthesis;"], [0, "&UnderParenthesis;"], [0, "&OverBrace;"], [0, "&UnderBrace;"], [2, "&trpezium;"], [4, "&elinters;"], [59, "&blank;"], [164, "&circledS;"], [55, "&boxh;"], [1, "&boxv;"], [9, "&boxdr;"], [3, "&boxdl;"], [3, "&boxur;"], [3, "&boxul;"], [3, "&boxvr;"], [7, "&boxvl;"], [7, "&boxhd;"], [7, "&boxhu;"], [7, "&boxvh;"], [19, "&boxH;"], [0, "&boxV;"], [0, "&boxdR;"], [0, "&boxDr;"], [0, "&boxDR;"], [0, "&boxdL;"], [0, "&boxDl;"], [0, "&boxDL;"], [0, "&boxuR;"], [0, "&boxUr;"], [0, "&boxUR;"], [0, "&boxuL;"], [0, "&boxUl;"], [0, "&boxUL;"], [0, "&boxvR;"], [0, "&boxVr;"], [0, "&boxVR;"], [0, "&boxvL;"], [0, "&boxVl;"], [0, "&boxVL;"], [0, "&boxHd;"], [0, "&boxhD;"], [0, "&boxHD;"], [0, "&boxHu;"], [0, "&boxhU;"], [0, "&boxHU;"], [0, "&boxvH;"], [0, "&boxVh;"], [0, "&boxVH;"], [19, "&uhblk;"], [3, "&lhblk;"], [3, "&block;"], [8, "&blk14;"], [0, "&blk12;"], [0, "&blk34;"], [13, "&square;"], [8, "&blacksquare;"], [0, "&EmptyVerySmallSquare;"], [1, "&rect;"], [0, "&marker;"], [2, "&fltns;"], [1, "&bigtriangleup;"], [0, "&blacktriangle;"], [0, "&triangle;"], [2, "&blacktriangleright;"], [0, "&rtri;"], [3, "&bigtriangledown;"], [0, "&blacktriangledown;"], [0, "&dtri;"], [2, "&blacktriangleleft;"], [0, "&ltri;"], [6, "&loz;"], [0, "&cir;"], [32, "&tridot;"], [2, "&bigcirc;"], [8, "&ultri;"], [0, "&urtri;"], [0, "&lltri;"], [0, "&EmptySmallSquare;"], [0, "&FilledSmallSquare;"], [8, "&bigstar;"], [0, "&star;"], [7, "&phone;"], [49, "&female;"], [1, "&male;"], [29, "&spades;"], [2, "&clubs;"], [1, "&hearts;"], [0, "&diamondsuit;"], [3, "&sung;"], [2, "&flat;"], [0, "&natural;"], [0, "&sharp;"], [163, "&check;"], [3, "&cross;"], [8, "&malt;"], [21, "&sext;"], [33, "&VerticalSeparator;"], [25, "&lbbrk;"], [0, "&rbbrk;"], [84, "&bsolhsub;"], [0, "&suphsol;"], [28, "&LeftDoubleBracket;"], [0, "&RightDoubleBracket;"], [0, "&lang;"], [0, "&rang;"], [0, "&Lang;"], [0, "&Rang;"], [0, "&loang;"], [0, "&roang;"], [7, "&longleftarrow;"], [0, "&longrightarrow;"], [0, "&longleftrightarrow;"], [0, "&DoubleLongLeftArrow;"], [0, "&DoubleLongRightArrow;"], [0, "&DoubleLongLeftRightArrow;"], [1, "&longmapsto;"], [2, "&dzigrarr;"], [258, "&nvlArr;"], [0, "&nvrArr;"], [0, "&nvHarr;"], [0, "&Map;"], [6, "&lbarr;"], [0, "&bkarow;"], [0, "&lBarr;"], [0, "&dbkarow;"], [0, "&drbkarow;"], [0, "&DDotrahd;"], [0, "&UpArrowBar;"], [0, "&DownArrowBar;"], [2, "&Rarrtl;"], [2, "&latail;"], [0, "&ratail;"], [0, "&lAtail;"], [0, "&rAtail;"], [0, "&larrfs;"], [0, "&rarrfs;"], [0, "&larrbfs;"], [0, "&rarrbfs;"], [2, "&nwarhk;"], [0, "&nearhk;"], [0, "&hksearow;"], [0, "&hkswarow;"], [0, "&nwnear;"], [0, "&nesear;"], [0, "&seswar;"], [0, "&swnwar;"], [8, { v: "&rarrc;", n: 824, o: "&nrarrc;" }], [1, "&cudarrr;"], [0, "&ldca;"], [0, "&rdca;"], [0, "&cudarrl;"], [0, "&larrpl;"], [2, "&curarrm;"], [0, "&cularrp;"], [7, "&rarrpl;"], [2, "&harrcir;"], [0, "&Uarrocir;"], [0, "&lurdshar;"], [0, "&ldrushar;"], [2, "&LeftRightVector;"], [0, "&RightUpDownVector;"], [0, "&DownLeftRightVector;"], [0, "&LeftUpDownVector;"], [0, "&LeftVectorBar;"], [0, "&RightVectorBar;"], [0, "&RightUpVectorBar;"], [0, "&RightDownVectorBar;"], [0, "&DownLeftVectorBar;"], [0, "&DownRightVectorBar;"], [0, "&LeftUpVectorBar;"], [0, "&LeftDownVectorBar;"], [0, "&LeftTeeVector;"], [0, "&RightTeeVector;"], [0, "&RightUpTeeVector;"], [0, "&RightDownTeeVector;"], [0, "&DownLeftTeeVector;"], [0, "&DownRightTeeVector;"], [0, "&LeftUpTeeVector;"], [0, "&LeftDownTeeVector;"], [0, "&lHar;"], [0, "&uHar;"], [0, "&rHar;"], [0, "&dHar;"], [0, "&luruhar;"], [0, "&ldrdhar;"], [0, "&ruluhar;"], [0, "&rdldhar;"], [0, "&lharul;"], [0, "&llhard;"], [0, "&rharul;"], [0, "&lrhard;"], [0, "&udhar;"], [0, "&duhar;"], [0, "&RoundImplies;"], [0, "&erarr;"], [0, "&simrarr;"], [0, "&larrsim;"], [0, "&rarrsim;"], [0, "&rarrap;"], [0, "&ltlarr;"], [1, "&gtrarr;"], [0, "&subrarr;"], [1, "&suplarr;"], [0, "&lfisht;"], [0, "&rfisht;"], [0, "&ufisht;"], [0, "&dfisht;"], [5, "&lopar;"], [0, "&ropar;"], [4, "&lbrke;"], [0, "&rbrke;"], [0, "&lbrkslu;"], [0, "&rbrksld;"], [0, "&lbrksld;"], [0, "&rbrkslu;"], [0, "&langd;"], [0, "&rangd;"], [0, "&lparlt;"], [0, "&rpargt;"], [0, "&gtlPar;"], [0, "&ltrPar;"], [3, "&vzigzag;"], [1, "&vangrt;"], [0, "&angrtvbd;"], [6, "&ange;"], [0, "&range;"], [0, "&dwangle;"], [0, "&uwangle;"], [0, "&angmsdaa;"], [0, "&angmsdab;"], [0, "&angmsdac;"], [0, "&angmsdad;"], [0, "&angmsdae;"], [0, "&angmsdaf;"], [0, "&angmsdag;"], [0, "&angmsdah;"], [0, "&bemptyv;"], [0, "&demptyv;"], [0, "&cemptyv;"], [0, "&raemptyv;"], [0, "&laemptyv;"], [0, "&ohbar;"], [0, "&omid;"], [0, "&opar;"], [1, "&operp;"], [1, "&olcross;"], [0, "&odsold;"], [1, "&olcir;"], [0, "&ofcir;"], [0, "&olt;"], [0, "&ogt;"], [0, "&cirscir;"], [0, "&cirE;"], [0, "&solb;"], [0, "&bsolb;"], [3, "&boxbox;"], [3, "&trisb;"], [0, "&rtriltri;"], [0, { v: "&LeftTriangleBar;", n: 824, o: "&NotLeftTriangleBar;" }], [0, { v: "&RightTriangleBar;", n: 824, o: "&NotRightTriangleBar;" }], [11, "&iinfin;"], [0, "&infintie;"], [0, "&nvinfin;"], [4, "&eparsl;"], [0, "&smeparsl;"], [0, "&eqvparsl;"], [5, "&blacklozenge;"], [8, "&RuleDelayed;"], [1, "&dsol;"], [9, "&bigodot;"], [0, "&bigoplus;"], [0, "&bigotimes;"], [1, "&biguplus;"], [1, "&bigsqcup;"], [5, "&iiiint;"], [0, "&fpartint;"], [2, "&cirfnint;"], [0, "&awint;"], [0, "&rppolint;"], [0, "&scpolint;"], [0, "&npolint;"], [0, "&pointint;"], [0, "&quatint;"], [0, "&intlarhk;"], [10, "&pluscir;"], [0, "&plusacir;"], [0, "&simplus;"], [0, "&plusdu;"], [0, "&plussim;"], [0, "&plustwo;"], [1, "&mcomma;"], [0, "&minusdu;"], [2, "&loplus;"], [0, "&roplus;"], [0, "&Cross;"], [0, "&timesd;"], [0, "&timesbar;"], [1, "&smashp;"], [0, "&lotimes;"], [0, "&rotimes;"], [0, "&otimesas;"], [0, "&Otimes;"], [0, "&odiv;"], [0, "&triplus;"], [0, "&triminus;"], [0, "&tritime;"], [0, "&intprod;"], [2, "&amalg;"], [0, "&capdot;"], [1, "&ncup;"], [0, "&ncap;"], [0, "&capand;"], [0, "&cupor;"], [0, "&cupcap;"], [0, "&capcup;"], [0, "&cupbrcap;"], [0, "&capbrcup;"], [0, "&cupcup;"], [0, "&capcap;"], [0, "&ccups;"], [0, "&ccaps;"], [2, "&ccupssm;"], [2, "&And;"], [0, "&Or;"], [0, "&andand;"], [0, "&oror;"], [0, "&orslope;"], [0, "&andslope;"], [1, "&andv;"], [0, "&orv;"], [0, "&andd;"], [0, "&ord;"], [1, "&wedbar;"], [6, "&sdote;"], [3, "&simdot;"], [2, { v: "&congdot;", n: 824, o: "&ncongdot;" }], [0, "&easter;"], [0, "&apacir;"], [0, { v: "&apE;", n: 824, o: "&napE;" }], [0, "&eplus;"], [0, "&pluse;"], [0, "&Esim;"], [0, "&Colone;"], [0, "&Equal;"], [1, "&ddotseq;"], [0, "&equivDD;"], [0, "&ltcir;"], [0, "&gtcir;"], [0, "&ltquest;"], [0, "&gtquest;"], [0, { v: "&leqslant;", n: 824, o: "&nleqslant;" }], [0, { v: "&geqslant;", n: 824, o: "&ngeqslant;" }], [0, "&lesdot;"], [0, "&gesdot;"], [0, "&lesdoto;"], [0, "&gesdoto;"], [0, "&lesdotor;"], [0, "&gesdotol;"], [0, "&lap;"], [0, "&gap;"], [0, "&lne;"], [0, "&gne;"], [0, "&lnap;"], [0, "&gnap;"], [0, "&lEg;"], [0, "&gEl;"], [0, "&lsime;"], [0, "&gsime;"], [0, "&lsimg;"], [0, "&gsiml;"], [0, "&lgE;"], [0, "&glE;"], [0, "&lesges;"], [0, "&gesles;"], [0, "&els;"], [0, "&egs;"], [0, "&elsdot;"], [0, "&egsdot;"], [0, "&el;"], [0, "&eg;"], [2, "&siml;"], [0, "&simg;"], [0, "&simlE;"], [0, "&simgE;"], [0, { v: "&LessLess;", n: 824, o: "&NotNestedLessLess;" }], [0, { v: "&GreaterGreater;", n: 824, o: "&NotNestedGreaterGreater;" }], [1, "&glj;"], [0, "&gla;"], [0, "&ltcc;"], [0, "&gtcc;"], [0, "&lescc;"], [0, "&gescc;"], [0, "&smt;"], [0, "&lat;"], [0, { v: "&smte;", n: 65024, o: "&smtes;" }], [0, { v: "&late;", n: 65024, o: "&lates;" }], [0, "&bumpE;"], [0, { v: "&PrecedesEqual;", n: 824, o: "&NotPrecedesEqual;" }], [0, { v: "&sce;", n: 824, o: "&NotSucceedsEqual;" }], [2, "&prE;"], [0, "&scE;"], [0, "&precneqq;"], [0, "&scnE;"], [0, "&prap;"], [0, "&scap;"], [0, "&precnapprox;"], [0, "&scnap;"], [0, "&Pr;"], [0, "&Sc;"], [0, "&subdot;"], [0, "&supdot;"], [0, "&subplus;"], [0, "&supplus;"], [0, "&submult;"], [0, "&supmult;"], [0, "&subedot;"], [0, "&supedot;"], [0, { v: "&subE;", n: 824, o: "&nsubE;" }], [0, { v: "&supE;", n: 824, o: "&nsupE;" }], [0, "&subsim;"], [0, "&supsim;"], [2, { v: "&subnE;", n: 65024, o: "&varsubsetneqq;" }], [0, { v: "&supnE;", n: 65024, o: "&varsupsetneqq;" }], [2, "&csub;"], [0, "&csup;"], [0, "&csube;"], [0, "&csupe;"], [0, "&subsup;"], [0, "&supsub;"], [0, "&subsub;"], [0, "&supsup;"], [0, "&suphsub;"], [0, "&supdsub;"], [0, "&forkv;"], [0, "&topfork;"], [0, "&mlcp;"], [8, "&Dashv;"], [1, "&Vdashl;"], [0, "&Barv;"], [0, "&vBar;"], [0, "&vBarv;"], [1, "&Vbar;"], [0, "&Not;"], [0, "&bNot;"], [0, "&rnmid;"], [0, "&cirmid;"], [0, "&midcir;"], [0, "&topcir;"], [0, "&nhpar;"], [0, "&parsim;"], [9, { v: "&parsl;", n: 8421, o: "&nparsl;" }], [44343, { n: new Map(/* @__PURE__ */ e([[56476, "&Ascr;"], [1, "&Cscr;"], [0, "&Dscr;"], [2, "&Gscr;"], [2, "&Jscr;"], [0, "&Kscr;"], [2, "&Nscr;"], [0, "&Oscr;"], [0, "&Pscr;"], [0, "&Qscr;"], [1, "&Sscr;"], [0, "&Tscr;"], [0, "&Uscr;"], [0, "&Vscr;"], [0, "&Wscr;"], [0, "&Xscr;"], [0, "&Yscr;"], [0, "&Zscr;"], [0, "&ascr;"], [0, "&bscr;"], [0, "&cscr;"], [0, "&dscr;"], [1, "&fscr;"], [1, "&hscr;"], [0, "&iscr;"], [0, "&jscr;"], [0, "&kscr;"], [0, "&lscr;"], [0, "&mscr;"], [0, "&nscr;"], [1, "&pscr;"], [0, "&qscr;"], [0, "&rscr;"], [0, "&sscr;"], [0, "&tscr;"], [0, "&uscr;"], [0, "&vscr;"], [0, "&wscr;"], [0, "&xscr;"], [0, "&yscr;"], [0, "&zscr;"], [52, "&Afr;"], [0, "&Bfr;"], [1, "&Dfr;"], [0, "&Efr;"], [0, "&Ffr;"], [0, "&Gfr;"], [2, "&Jfr;"], [0, "&Kfr;"], [0, "&Lfr;"], [0, "&Mfr;"], [0, "&Nfr;"], [0, "&Ofr;"], [0, "&Pfr;"], [0, "&Qfr;"], [1, "&Sfr;"], [0, "&Tfr;"], [0, "&Ufr;"], [0, "&Vfr;"], [0, "&Wfr;"], [0, "&Xfr;"], [0, "&Yfr;"], [1, "&afr;"], [0, "&bfr;"], [0, "&cfr;"], [0, "&dfr;"], [0, "&efr;"], [0, "&ffr;"], [0, "&gfr;"], [0, "&hfr;"], [0, "&ifr;"], [0, "&jfr;"], [0, "&kfr;"], [0, "&lfr;"], [0, "&mfr;"], [0, "&nfr;"], [0, "&ofr;"], [0, "&pfr;"], [0, "&qfr;"], [0, "&rfr;"], [0, "&sfr;"], [0, "&tfr;"], [0, "&ufr;"], [0, "&vfr;"], [0, "&wfr;"], [0, "&xfr;"], [0, "&yfr;"], [0, "&zfr;"], [0, "&Aopf;"], [0, "&Bopf;"], [1, "&Dopf;"], [0, "&Eopf;"], [0, "&Fopf;"], [0, "&Gopf;"], [1, "&Iopf;"], [0, "&Jopf;"], [0, "&Kopf;"], [0, "&Lopf;"], [0, "&Mopf;"], [1, "&Oopf;"], [3, "&Sopf;"], [0, "&Topf;"], [0, "&Uopf;"], [0, "&Vopf;"], [0, "&Wopf;"], [0, "&Xopf;"], [0, "&Yopf;"], [1, "&aopf;"], [0, "&bopf;"], [0, "&copf;"], [0, "&dopf;"], [0, "&eopf;"], [0, "&fopf;"], [0, "&gopf;"], [0, "&hopf;"], [0, "&iopf;"], [0, "&jopf;"], [0, "&kopf;"], [0, "&lopf;"], [0, "&mopf;"], [0, "&nopf;"], [0, "&oopf;"], [0, "&popf;"], [0, "&qopf;"], [0, "&ropf;"], [0, "&sopf;"], [0, "&topf;"], [0, "&uopf;"], [0, "&vopf;"], [0, "&wopf;"], [0, "&xopf;"], [0, "&yopf;"], [0, "&zopf;"]])) }], [8906, "&fflig;"], [0, "&filig;"], [0, "&fllig;"], [0, "&ffilig;"], [0, "&ffllig;"]])), lu;
}
var Ku = {}, Tr;
function _t() {
  return Tr || (Tr = 1, (function(e) {
    Object.defineProperty(e, "__esModule", { value: !0 }), e.escapeText = e.escapeAttribute = e.escapeUTF8 = e.escape = e.encodeXML = e.getCodePoint = e.xmlReplacer = void 0, e.xmlReplacer = /["&'<>$\x80-\uFFFF]/g;
    var u = /* @__PURE__ */ new Map([
      [34, "&quot;"],
      [38, "&amp;"],
      [39, "&apos;"],
      [60, "&lt;"],
      [62, "&gt;"]
    ]);
    e.getCodePoint = // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    String.prototype.codePointAt != null ? function(a, r) {
      return a.codePointAt(r);
    } : (
      // http://mathiasbynens.be/notes/javascript-encoding#surrogate-formulae
      function(a, r) {
        return (a.charCodeAt(r) & 64512) === 55296 ? (a.charCodeAt(r) - 55296) * 1024 + a.charCodeAt(r + 1) - 56320 + 65536 : a.charCodeAt(r);
      }
    );
    function t(a) {
      for (var r = "", o = 0, i; (i = e.xmlReplacer.exec(a)) !== null; ) {
        var c = i.index, n = a.charCodeAt(c), l = u.get(n);
        l !== void 0 ? (r += a.substring(o, c) + l, o = c + 1) : (r += "".concat(a.substring(o, c), "&#x").concat((0, e.getCodePoint)(a, c).toString(16), ";"), o = e.xmlReplacer.lastIndex += +((n & 64512) === 55296));
      }
      return r + a.substr(o);
    }
    e.encodeXML = t, e.escape = t;
    function s(a, r) {
      return function(i) {
        for (var c, n = 0, l = ""; c = a.exec(i); )
          n !== c.index && (l += i.substring(n, c.index)), l += r.get(c[0].charCodeAt(0)), n = c.index + 1;
        return l + i.substring(n);
      };
    }
    e.escapeUTF8 = s(/[&<>'"]/g, u), e.escapeAttribute = s(/["&\u00A0]/g, /* @__PURE__ */ new Map([
      [34, "&quot;"],
      [38, "&amp;"],
      [160, "&nbsp;"]
    ])), e.escapeText = s(/[&<>\u00A0]/g, /* @__PURE__ */ new Map([
      [38, "&amp;"],
      [60, "&lt;"],
      [62, "&gt;"],
      [160, "&nbsp;"]
    ]));
  })(Ku)), Ku;
}
var Rr;
function Nr() {
  if (Rr) return Ee;
  Rr = 1;
  var e = Ee && Ee.__importDefault || function(i) {
    return i && i.__esModule ? i : { default: i };
  };
  Object.defineProperty(Ee, "__esModule", { value: !0 }), Ee.encodeNonAsciiHTML = Ee.encodeHTML = void 0;
  var u = e(/* @__PURE__ */ Ls()), t = /* @__PURE__ */ _t(), s = /[\t\n!-,./:-@[-`\f{-}$\x80-\uFFFF]/g;
  function a(i) {
    return o(s, i);
  }
  Ee.encodeHTML = a;
  function r(i) {
    return o(t.xmlReplacer, i);
  }
  Ee.encodeNonAsciiHTML = r;
  function o(i, c) {
    for (var n = "", l = 0, f; (f = i.exec(c)) !== null; ) {
      var A = f.index;
      n += c.substring(l, A);
      var d = c.charCodeAt(A), h = u.default.get(d);
      if (typeof h == "object") {
        if (A + 1 < c.length) {
          var y = c.charCodeAt(A + 1), C = typeof h.n == "number" ? h.n === y ? h.o : void 0 : h.n.get(y);
          if (C !== void 0) {
            n += C, l = i.lastIndex += 1;
            continue;
          }
        }
        h = h.v;
      }
      if (h !== void 0)
        n += h, l = A + 1;
      else {
        var w = (0, t.getCodePoint)(c, A);
        n += "&#x".concat(w.toString(16), ";"), l = i.lastIndex += +(w !== d);
      }
    }
    return n + c.substr(l);
  }
  return Ee;
}
var Mr;
function Ps() {
  return Mr || (Mr = 1, (function(e) {
    Object.defineProperty(e, "__esModule", { value: !0 }), e.decodeXMLStrict = e.decodeHTML5Strict = e.decodeHTML4Strict = e.decodeHTML5 = e.decodeHTML4 = e.decodeHTMLAttribute = e.decodeHTMLStrict = e.decodeHTML = e.decodeXML = e.DecodingMode = e.EntityDecoder = e.encodeHTML5 = e.encodeHTML4 = e.encodeNonAsciiHTML = e.encodeHTML = e.escapeText = e.escapeAttribute = e.escapeUTF8 = e.escape = e.encodeXML = e.encode = e.decodeStrict = e.decode = e.EncodingMode = e.EntityLevel = void 0;
    var u = /* @__PURE__ */ Fr(), t = /* @__PURE__ */ Nr(), s = /* @__PURE__ */ _t(), a;
    (function(A) {
      A[A.XML = 0] = "XML", A[A.HTML = 1] = "HTML";
    })(a = e.EntityLevel || (e.EntityLevel = {}));
    var r;
    (function(A) {
      A[A.UTF8 = 0] = "UTF8", A[A.ASCII = 1] = "ASCII", A[A.Extensive = 2] = "Extensive", A[A.Attribute = 3] = "Attribute", A[A.Text = 4] = "Text";
    })(r = e.EncodingMode || (e.EncodingMode = {}));
    function o(A, d) {
      d === void 0 && (d = a.XML);
      var h = typeof d == "number" ? d : d.level;
      if (h === a.HTML) {
        var y = typeof d == "object" ? d.mode : void 0;
        return (0, u.decodeHTML)(A, y);
      }
      return (0, u.decodeXML)(A);
    }
    e.decode = o;
    function i(A, d) {
      var h;
      d === void 0 && (d = a.XML);
      var y = typeof d == "number" ? { level: d } : d;
      return (h = y.mode) !== null && h !== void 0 || (y.mode = u.DecodingMode.Strict), o(A, y);
    }
    e.decodeStrict = i;
    function c(A, d) {
      d === void 0 && (d = a.XML);
      var h = typeof d == "number" ? { level: d } : d;
      return h.mode === r.UTF8 ? (0, s.escapeUTF8)(A) : h.mode === r.Attribute ? (0, s.escapeAttribute)(A) : h.mode === r.Text ? (0, s.escapeText)(A) : h.level === a.HTML ? h.mode === r.ASCII ? (0, t.encodeNonAsciiHTML)(A) : (0, t.encodeHTML)(A) : (0, s.encodeXML)(A);
    }
    e.encode = c;
    var n = /* @__PURE__ */ _t();
    Object.defineProperty(e, "encodeXML", { enumerable: !0, get: function() {
      return n.encodeXML;
    } }), Object.defineProperty(e, "escape", { enumerable: !0, get: function() {
      return n.escape;
    } }), Object.defineProperty(e, "escapeUTF8", { enumerable: !0, get: function() {
      return n.escapeUTF8;
    } }), Object.defineProperty(e, "escapeAttribute", { enumerable: !0, get: function() {
      return n.escapeAttribute;
    } }), Object.defineProperty(e, "escapeText", { enumerable: !0, get: function() {
      return n.escapeText;
    } });
    var l = /* @__PURE__ */ Nr();
    Object.defineProperty(e, "encodeHTML", { enumerable: !0, get: function() {
      return l.encodeHTML;
    } }), Object.defineProperty(e, "encodeNonAsciiHTML", { enumerable: !0, get: function() {
      return l.encodeNonAsciiHTML;
    } }), Object.defineProperty(e, "encodeHTML4", { enumerable: !0, get: function() {
      return l.encodeHTML;
    } }), Object.defineProperty(e, "encodeHTML5", { enumerable: !0, get: function() {
      return l.encodeHTML;
    } });
    var f = /* @__PURE__ */ Fr();
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
  })(Wu)), Wu;
}
var Le = {}, Or;
function Gs() {
  return Or || (Or = 1, Object.defineProperty(Le, "__esModule", { value: !0 }), Le.attributeNames = Le.elementNames = void 0, Le.elementNames = new Map([
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
  })), Le.attributeNames = new Map([
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
  }))), Le;
}
var Qr;
function Hs() {
  if (Qr) return ue;
  Qr = 1;
  var e = ue && ue.__assign || function() {
    return e = Object.assign || function(m) {
      for (var p, g = 1, D = arguments.length; g < D; g++) {
        p = arguments[g];
        for (var B in p) Object.prototype.hasOwnProperty.call(p, B) && (m[B] = p[B]);
      }
      return m;
    }, e.apply(this, arguments);
  }, u = ue && ue.__createBinding || (Object.create ? (function(m, p, g, D) {
    D === void 0 && (D = g);
    var B = Object.getOwnPropertyDescriptor(p, g);
    (!B || ("get" in B ? !p.__esModule : B.writable || B.configurable)) && (B = { enumerable: !0, get: function() {
      return p[g];
    } }), Object.defineProperty(m, D, B);
  }) : (function(m, p, g, D) {
    D === void 0 && (D = g), m[D] = p[g];
  })), t = ue && ue.__setModuleDefault || (Object.create ? (function(m, p) {
    Object.defineProperty(m, "default", { enumerable: !0, value: p });
  }) : function(m, p) {
    m.default = p;
  }), s = ue && ue.__importStar || function(m) {
    if (m && m.__esModule) return m;
    var p = {};
    if (m != null) for (var g in m) g !== "default" && Object.prototype.hasOwnProperty.call(m, g) && u(p, m, g);
    return t(p, m), p;
  };
  Object.defineProperty(ue, "__esModule", { value: !0 }), ue.render = void 0;
  var a = s(/* @__PURE__ */ tu()), r = /* @__PURE__ */ Ps(), o = /* @__PURE__ */ Gs(), i = /* @__PURE__ */ new Set([
    "style",
    "script",
    "xmp",
    "iframe",
    "noembed",
    "noframes",
    "plaintext",
    "noscript"
  ]);
  function c(m) {
    return m.replace(/"/g, "&quot;");
  }
  function n(m, p) {
    var g;
    if (m) {
      var D = ((g = p.encodeEntities) !== null && g !== void 0 ? g : p.decodeEntities) === !1 ? c : p.xmlMode || p.encodeEntities !== "utf8" ? r.encodeXML : r.escapeAttribute;
      return Object.keys(m).map(function(B) {
        var E, _, v = (E = m[B]) !== null && E !== void 0 ? E : "";
        return p.xmlMode === "foreign" && (B = (_ = o.attributeNames.get(B)) !== null && _ !== void 0 ? _ : B), !p.emptyAttrs && !p.xmlMode && v === "" ? B : "".concat(B, '="').concat(D(v), '"');
      }).join(" ");
    }
  }
  var l = /* @__PURE__ */ new Set([
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
  function f(m, p) {
    p === void 0 && (p = {});
    for (var g = ("length" in m) ? m : [m], D = "", B = 0; B < g.length; B++)
      D += A(g[B], p);
    return D;
  }
  ue.render = f, ue.default = f;
  function A(m, p) {
    switch (m.type) {
      case a.Root:
        return f(m.children, p);
      // @ts-expect-error We don't use `Doctype` yet
      case a.Doctype:
      case a.Directive:
        return C(m);
      case a.Comment:
        return x(m);
      case a.CDATA:
        return b(m);
      case a.Script:
      case a.Style:
      case a.Tag:
        return y(m, p);
      case a.Text:
        return w(m, p);
    }
  }
  var d = /* @__PURE__ */ new Set([
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
  function y(m, p) {
    var g;
    p.xmlMode === "foreign" && (m.name = (g = o.elementNames.get(m.name)) !== null && g !== void 0 ? g : m.name, m.parent && d.has(m.parent.name) && (p = e(e({}, p), { xmlMode: !1 }))), !p.xmlMode && h.has(m.name) && (p = e(e({}, p), { xmlMode: "foreign" }));
    var D = "<".concat(m.name), B = n(m.attribs, p);
    return B && (D += " ".concat(B)), m.children.length === 0 && (p.xmlMode ? (
      // In XML mode or foreign mode, and user hasn't explicitly turned off self-closing tags
      p.selfClosingTags !== !1
    ) : (
      // User explicitly asked for self-closing tags, even in HTML mode
      p.selfClosingTags && l.has(m.name)
    )) ? (p.xmlMode || (D += " "), D += "/>") : (D += ">", m.children.length > 0 && (D += f(m.children, p)), (p.xmlMode || !l.has(m.name)) && (D += "</".concat(m.name, ">"))), D;
  }
  function C(m) {
    return "<".concat(m.data, ">");
  }
  function w(m, p) {
    var g, D = m.data || "";
    return ((g = p.encodeEntities) !== null && g !== void 0 ? g : p.decodeEntities) !== !1 && !(!p.xmlMode && m.parent && i.has(m.parent.name)) && (D = p.xmlMode || p.encodeEntities !== "utf8" ? (0, r.encodeXML)(D) : (0, r.escapeText)(D)), D;
  }
  function b(m) {
    return "<![CDATA[".concat(m.children[0].data, "]]>");
  }
  function x(m) {
    return "<!--".concat(m.data, "-->");
  }
  return ue;
}
var Lr;
function on() {
  if (Lr) return xe;
  Lr = 1;
  var e = xe && xe.__importDefault || function(n) {
    return n && n.__esModule ? n : { default: n };
  };
  Object.defineProperty(xe, "__esModule", { value: !0 }), xe.getOuterHTML = a, xe.getInnerHTML = r, xe.getText = o, xe.textContent = i, xe.innerText = c;
  var u = /* @__PURE__ */ Ne(), t = e(/* @__PURE__ */ Hs()), s = /* @__PURE__ */ tu();
  function a(n, l) {
    return (0, t.default)(n, l);
  }
  function r(n, l) {
    return (0, u.hasChildren)(n) ? n.children.map(function(f) {
      return a(f, l);
    }).join("") : "";
  }
  function o(n) {
    return Array.isArray(n) ? n.map(o).join("") : (0, u.isTag)(n) ? n.name === "br" ? `
` : o(n.children) : (0, u.isCDATA)(n) ? o(n.children) : (0, u.isText)(n) ? n.data : "";
  }
  function i(n) {
    return Array.isArray(n) ? n.map(i).join("") : (0, u.hasChildren)(n) && !(0, u.isComment)(n) ? i(n.children) : (0, u.isText)(n) ? n.data : "";
  }
  function c(n) {
    return Array.isArray(n) ? n.map(c).join("") : (0, u.hasChildren)(n) && (n.type === s.ElementType.Tag || (0, u.isCDATA)(n)) ? c(n.children) : (0, u.isText)(n) ? n.data : "";
  }
  return xe;
}
var pe = {}, Pr;
function qs() {
  if (Pr) return pe;
  Pr = 1, Object.defineProperty(pe, "__esModule", { value: !0 }), pe.getChildren = u, pe.getParent = t, pe.getSiblings = s, pe.getAttributeValue = a, pe.hasAttrib = r, pe.getName = o, pe.nextElementSibling = i, pe.prevElementSibling = c;
  var e = /* @__PURE__ */ Ne();
  function u(n) {
    return (0, e.hasChildren)(n) ? n.children : [];
  }
  function t(n) {
    return n.parent || null;
  }
  function s(n) {
    var l, f, A = t(n);
    if (A != null)
      return u(A);
    for (var d = [n], h = n.prev, y = n.next; h != null; )
      d.unshift(h), l = h, h = l.prev;
    for (; y != null; )
      d.push(y), f = y, y = f.next;
    return d;
  }
  function a(n, l) {
    var f;
    return (f = n.attribs) === null || f === void 0 ? void 0 : f[l];
  }
  function r(n, l) {
    return n.attribs != null && Object.prototype.hasOwnProperty.call(n.attribs, l) && n.attribs[l] != null;
  }
  function o(n) {
    return n.name;
  }
  function i(n) {
    for (var l, f = n.next; f !== null && !(0, e.isTag)(f); )
      l = f, f = l.next;
    return f;
  }
  function c(n) {
    for (var l, f = n.prev; f !== null && !(0, e.isTag)(f); )
      l = f, f = l.prev;
    return f;
  }
  return pe;
}
var _e = {}, Gr;
function Ws() {
  if (Gr) return _e;
  Gr = 1, Object.defineProperty(_e, "__esModule", { value: !0 }), _e.removeElement = e, _e.replaceElement = u, _e.appendChild = t, _e.append = s, _e.prependChild = a, _e.prepend = r;
  function e(o) {
    if (o.prev && (o.prev.next = o.next), o.next && (o.next.prev = o.prev), o.parent) {
      var i = o.parent.children, c = i.lastIndexOf(o);
      c >= 0 && i.splice(c, 1);
    }
    o.next = null, o.prev = null, o.parent = null;
  }
  function u(o, i) {
    var c = i.prev = o.prev;
    c && (c.next = i);
    var n = i.next = o.next;
    n && (n.prev = i);
    var l = i.parent = o.parent;
    if (l) {
      var f = l.children;
      f[f.lastIndexOf(o)] = i, o.parent = null;
    }
  }
  function t(o, i) {
    if (e(i), i.next = null, i.parent = o, o.children.push(i) > 1) {
      var c = o.children[o.children.length - 2];
      c.next = i, i.prev = c;
    } else
      i.prev = null;
  }
  function s(o, i) {
    e(i);
    var c = o.parent, n = o.next;
    if (i.next = n, i.prev = o, o.next = i, i.parent = c, n) {
      if (n.prev = i, c) {
        var l = c.children;
        l.splice(l.lastIndexOf(n), 0, i);
      }
    } else c && c.children.push(i);
  }
  function a(o, i) {
    if (e(i), i.parent = o, i.prev = null, o.children.unshift(i) !== 1) {
      var c = o.children[1];
      c.prev = i, i.next = c;
    } else
      i.next = null;
  }
  function r(o, i) {
    e(i);
    var c = o.parent;
    if (c) {
      var n = c.children;
      n.splice(n.indexOf(o), 0, i);
    }
    o.prev && (o.prev.next = i), i.parent = c, i.prev = o.prev, i.next = o, o.prev = i;
  }
  return _e;
}
var Ie = {}, Hr;
function ln() {
  if (Hr) return Ie;
  Hr = 1, Object.defineProperty(Ie, "__esModule", { value: !0 }), Ie.filter = u, Ie.find = t, Ie.findOneChild = s, Ie.findOne = a, Ie.existsOne = r, Ie.findAll = o;
  var e = /* @__PURE__ */ Ne();
  function u(i, c, n, l) {
    return n === void 0 && (n = !0), l === void 0 && (l = 1 / 0), t(i, Array.isArray(c) ? c : [c], n, l);
  }
  function t(i, c, n, l) {
    for (var f = [], A = [Array.isArray(c) ? c : [c]], d = [0]; ; ) {
      if (d[0] >= A[0].length) {
        if (d.length === 1)
          return f;
        A.shift(), d.shift();
        continue;
      }
      var h = A[0][d[0]++];
      if (i(h) && (f.push(h), --l <= 0))
        return f;
      n && (0, e.hasChildren)(h) && h.children.length > 0 && (d.unshift(0), A.unshift(h.children));
    }
  }
  function s(i, c) {
    return c.find(i);
  }
  function a(i, c, n) {
    n === void 0 && (n = !0);
    for (var l = Array.isArray(c) ? c : [c], f = 0; f < l.length; f++) {
      var A = l[f];
      if ((0, e.isTag)(A) && i(A))
        return A;
      if (n && (0, e.hasChildren)(A) && A.children.length > 0) {
        var d = a(i, A.children, !0);
        if (d)
          return d;
      }
    }
    return null;
  }
  function r(i, c) {
    return (Array.isArray(c) ? c : [c]).some(function(n) {
      return (0, e.isTag)(n) && i(n) || (0, e.hasChildren)(n) && r(i, n.children);
    });
  }
  function o(i, c) {
    for (var n = [], l = [Array.isArray(c) ? c : [c]], f = [0]; ; ) {
      if (f[0] >= l[0].length) {
        if (l.length === 1)
          return n;
        l.shift(), f.shift();
        continue;
      }
      var A = l[0][f[0]++];
      (0, e.isTag)(A) && i(A) && n.push(A), (0, e.hasChildren)(A) && A.children.length > 0 && (f.unshift(0), l.unshift(A.children));
    }
  }
  return Ie;
}
var ke = {}, qr;
function fn() {
  if (qr) return ke;
  qr = 1, Object.defineProperty(ke, "__esModule", { value: !0 }), ke.testElement = o, ke.getElements = i, ke.getElementById = c, ke.getElementsByTagName = n, ke.getElementsByClassName = l, ke.getElementsByTagType = f;
  var e = /* @__PURE__ */ Ne(), u = /* @__PURE__ */ ln(), t = {
    tag_name: function(A) {
      return typeof A == "function" ? function(d) {
        return (0, e.isTag)(d) && A(d.name);
      } : A === "*" ? e.isTag : function(d) {
        return (0, e.isTag)(d) && d.name === A;
      };
    },
    tag_type: function(A) {
      return typeof A == "function" ? function(d) {
        return A(d.type);
      } : function(d) {
        return d.type === A;
      };
    },
    tag_contains: function(A) {
      return typeof A == "function" ? function(d) {
        return (0, e.isText)(d) && A(d.data);
      } : function(d) {
        return (0, e.isText)(d) && d.data === A;
      };
    }
  };
  function s(A, d) {
    return typeof d == "function" ? function(h) {
      return (0, e.isTag)(h) && d(h.attribs[A]);
    } : function(h) {
      return (0, e.isTag)(h) && h.attribs[A] === d;
    };
  }
  function a(A, d) {
    return function(h) {
      return A(h) || d(h);
    };
  }
  function r(A) {
    var d = Object.keys(A).map(function(h) {
      var y = A[h];
      return Object.prototype.hasOwnProperty.call(t, h) ? t[h](y) : s(h, y);
    });
    return d.length === 0 ? null : d.reduce(a);
  }
  function o(A, d) {
    var h = r(A);
    return h ? h(d) : !0;
  }
  function i(A, d, h, y) {
    y === void 0 && (y = 1 / 0);
    var C = r(A);
    return C ? (0, u.filter)(C, d, h, y) : [];
  }
  function c(A, d, h) {
    return h === void 0 && (h = !0), Array.isArray(d) || (d = [d]), (0, u.findOne)(s("id", A), d, h);
  }
  function n(A, d, h, y) {
    return h === void 0 && (h = !0), y === void 0 && (y = 1 / 0), (0, u.filter)(t.tag_name(A), d, h, y);
  }
  function l(A, d, h, y) {
    return h === void 0 && (h = !0), y === void 0 && (y = 1 / 0), (0, u.filter)(s("class", A), d, h, y);
  }
  function f(A, d, h, y) {
    return h === void 0 && (h = !0), y === void 0 && (y = 1 / 0), (0, u.filter)(t.tag_type(A), d, h, y);
  }
  return ke;
}
var Be = {}, Wr;
function Us() {
  if (Wr) return Be;
  Wr = 1, Object.defineProperty(Be, "__esModule", { value: !0 }), Be.DocumentPosition = void 0, Be.removeSubsets = u, Be.compareDocumentPosition = s, Be.uniqueSort = a;
  var e = /* @__PURE__ */ Ne();
  function u(r) {
    for (var o = r.length; --o >= 0; ) {
      var i = r[o];
      if (o > 0 && r.lastIndexOf(i, o - 1) >= 0) {
        r.splice(o, 1);
        continue;
      }
      for (var c = i.parent; c; c = c.parent)
        if (r.includes(c)) {
          r.splice(o, 1);
          break;
        }
    }
    return r;
  }
  var t;
  (function(r) {
    r[r.DISCONNECTED = 1] = "DISCONNECTED", r[r.PRECEDING = 2] = "PRECEDING", r[r.FOLLOWING = 4] = "FOLLOWING", r[r.CONTAINS = 8] = "CONTAINS", r[r.CONTAINED_BY = 16] = "CONTAINED_BY";
  })(t || (Be.DocumentPosition = t = {}));
  function s(r, o) {
    var i = [], c = [];
    if (r === o)
      return 0;
    for (var n = (0, e.hasChildren)(r) ? r : r.parent; n; )
      i.unshift(n), n = n.parent;
    for (n = (0, e.hasChildren)(o) ? o : o.parent; n; )
      c.unshift(n), n = n.parent;
    for (var l = Math.min(i.length, c.length), f = 0; f < l && i[f] === c[f]; )
      f++;
    if (f === 0)
      return t.DISCONNECTED;
    var A = i[f - 1], d = A.children, h = i[f], y = c[f];
    return d.indexOf(h) > d.indexOf(y) ? A === o ? t.FOLLOWING | t.CONTAINED_BY : t.FOLLOWING : A === r ? t.PRECEDING | t.CONTAINS : t.PRECEDING;
  }
  function a(r) {
    return r = r.filter(function(o, i, c) {
      return !c.includes(o, i + 1);
    }), r.sort(function(o, i) {
      var c = s(o, i);
      return c & t.PRECEDING ? -1 : c & t.FOLLOWING ? 1 : 0;
    }), r;
  }
  return Be;
}
var fu = {}, Ur;
function Ks() {
  if (Ur) return fu;
  Ur = 1, Object.defineProperty(fu, "__esModule", { value: !0 }), fu.getFeed = t;
  var e = /* @__PURE__ */ on(), u = /* @__PURE__ */ fn();
  function t(A) {
    var d = c(f, A);
    return d ? d.name === "feed" ? s(d) : a(d) : null;
  }
  function s(A) {
    var d, h = A.children, y = {
      type: "atom",
      items: (0, u.getElementsByTagName)("entry", h).map(function(b) {
        var x, m = b.children, p = { media: i(m) };
        l(p, "id", "id", m), l(p, "title", "title", m);
        var g = (x = c("link", m)) === null || x === void 0 ? void 0 : x.attribs.href;
        g && (p.link = g);
        var D = n("summary", m) || n("content", m);
        D && (p.description = D);
        var B = n("updated", m);
        return B && (p.pubDate = new Date(B)), p;
      })
    };
    l(y, "id", "id", h), l(y, "title", "title", h);
    var C = (d = c("link", h)) === null || d === void 0 ? void 0 : d.attribs.href;
    C && (y.link = C), l(y, "description", "subtitle", h);
    var w = n("updated", h);
    return w && (y.updated = new Date(w)), l(y, "author", "email", h, !0), y;
  }
  function a(A) {
    var d, h, y = (h = (d = c("channel", A.children)) === null || d === void 0 ? void 0 : d.children) !== null && h !== void 0 ? h : [], C = {
      type: A.name.substr(0, 3),
      id: "",
      items: (0, u.getElementsByTagName)("item", A.children).map(function(b) {
        var x = b.children, m = { media: i(x) };
        l(m, "id", "guid", x), l(m, "title", "title", x), l(m, "link", "link", x), l(m, "description", "description", x);
        var p = n("pubDate", x) || n("dc:date", x);
        return p && (m.pubDate = new Date(p)), m;
      })
    };
    l(C, "title", "title", y), l(C, "link", "link", y), l(C, "description", "description", y);
    var w = n("lastBuildDate", y);
    return w && (C.updated = new Date(w)), l(C, "author", "managingEditor", y, !0), C;
  }
  var r = ["url", "type", "lang"], o = [
    "fileSize",
    "bitrate",
    "framerate",
    "samplingrate",
    "channels",
    "duration",
    "height",
    "width"
  ];
  function i(A) {
    return (0, u.getElementsByTagName)("media:content", A).map(function(d) {
      for (var h = d.attribs, y = {
        medium: h.medium,
        isDefault: !!h.isDefault
      }, C = 0, w = r; C < w.length; C++) {
        var b = w[C];
        h[b] && (y[b] = h[b]);
      }
      for (var x = 0, m = o; x < m.length; x++) {
        var b = m[x];
        h[b] && (y[b] = parseInt(h[b], 10));
      }
      return h.expression && (y.expression = h.expression), y;
    });
  }
  function c(A, d) {
    return (0, u.getElementsByTagName)(A, d, !0, 1)[0];
  }
  function n(A, d, h) {
    return h === void 0 && (h = !1), (0, e.textContent)((0, u.getElementsByTagName)(A, d, h, 1)).trim();
  }
  function l(A, d, h, y, C) {
    C === void 0 && (C = !1);
    var w = n(h, y, C);
    w && (A[d] = w);
  }
  function f(A) {
    return A === "rss" || A === "feed" || A === "rdf:RDF";
  }
  return fu;
}
var Kr;
function Yu() {
  return Kr || (Kr = 1, (function(e) {
    var u = Qe && Qe.__createBinding || (Object.create ? (function(a, r, o, i) {
      i === void 0 && (i = o);
      var c = Object.getOwnPropertyDescriptor(r, o);
      (!c || ("get" in c ? !r.__esModule : c.writable || c.configurable)) && (c = { enumerable: !0, get: function() {
        return r[o];
      } }), Object.defineProperty(a, i, c);
    }) : (function(a, r, o, i) {
      i === void 0 && (i = o), a[i] = r[o];
    })), t = Qe && Qe.__exportStar || function(a, r) {
      for (var o in a) o !== "default" && !Object.prototype.hasOwnProperty.call(r, o) && u(r, a, o);
    };
    Object.defineProperty(e, "__esModule", { value: !0 }), e.hasChildren = e.isDocument = e.isComment = e.isText = e.isCDATA = e.isTag = void 0, t(/* @__PURE__ */ on(), e), t(/* @__PURE__ */ qs(), e), t(/* @__PURE__ */ Ws(), e), t(/* @__PURE__ */ ln(), e), t(/* @__PURE__ */ fn(), e), t(/* @__PURE__ */ Us(), e), t(/* @__PURE__ */ Ks(), e);
    var s = /* @__PURE__ */ Ne();
    Object.defineProperty(e, "isTag", { enumerable: !0, get: function() {
      return s.isTag;
    } }), Object.defineProperty(e, "isCDATA", { enumerable: !0, get: function() {
      return s.isCDATA;
    } }), Object.defineProperty(e, "isText", { enumerable: !0, get: function() {
      return s.isText;
    } }), Object.defineProperty(e, "isComment", { enumerable: !0, get: function() {
      return s.isComment;
    } }), Object.defineProperty(e, "isDocument", { enumerable: !0, get: function() {
      return s.isDocument;
    } }), Object.defineProperty(e, "hasChildren", { enumerable: !0, get: function() {
      return s.hasChildren;
    } });
  })(Qe)), Qe;
}
var Yr;
function Ys() {
  return Yr || (Yr = 1, (function(e) {
    var u = Ae && Ae.__createBinding || (Object.create ? (function(b, x, m, p) {
      p === void 0 && (p = m);
      var g = Object.getOwnPropertyDescriptor(x, m);
      (!g || ("get" in g ? !x.__esModule : g.writable || g.configurable)) && (g = { enumerable: !0, get: function() {
        return x[m];
      } }), Object.defineProperty(b, p, g);
    }) : (function(b, x, m, p) {
      p === void 0 && (p = m), b[p] = x[m];
    })), t = Ae && Ae.__setModuleDefault || (Object.create ? (function(b, x) {
      Object.defineProperty(b, "default", { enumerable: !0, value: x });
    }) : function(b, x) {
      b.default = x;
    }), s = Ae && Ae.__importStar || /* @__PURE__ */ (function() {
      var b = function(x) {
        return b = Object.getOwnPropertyNames || function(m) {
          var p = [];
          for (var g in m) Object.prototype.hasOwnProperty.call(m, g) && (p[p.length] = g);
          return p;
        }, b(x);
      };
      return function(x) {
        if (x && x.__esModule) return x;
        var m = {};
        if (x != null) for (var p = b(x), g = 0; g < p.length; g++) p[g] !== "default" && u(m, x, p[g]);
        return t(m, x), m;
      };
    })(), a = Ae && Ae.__importDefault || function(b) {
      return b && b.__esModule ? b : { default: b };
    };
    Object.defineProperty(e, "__esModule", { value: !0 }), e.DomUtils = e.getFeed = e.ElementType = e.QuoteType = e.Tokenizer = e.DefaultHandler = e.DomHandler = e.Parser = void 0, e.parseDocument = n, e.parseDOM = l, e.createDocumentStream = f, e.createDomStream = A, e.parseFeed = w;
    const r = yr();
    var o = yr();
    Object.defineProperty(e, "Parser", { enumerable: !0, get: function() {
      return o.Parser;
    } });
    const i = /* @__PURE__ */ Ne();
    var c = /* @__PURE__ */ Ne();
    Object.defineProperty(e, "DomHandler", { enumerable: !0, get: function() {
      return c.DomHandler;
    } }), Object.defineProperty(e, "DefaultHandler", { enumerable: !0, get: function() {
      return c.DomHandler;
    } });
    function n(b, x) {
      const m = new i.DomHandler(void 0, x);
      return new r.Parser(m, x).end(b), m.root;
    }
    function l(b, x) {
      return n(b, x).children;
    }
    function f(b, x, m) {
      const p = new i.DomHandler((g) => b(g, p.root), x, m);
      return new r.Parser(p, x);
    }
    function A(b, x, m) {
      const p = new i.DomHandler(b, x, m);
      return new r.Parser(p, x);
    }
    var d = cn();
    Object.defineProperty(e, "Tokenizer", { enumerable: !0, get: function() {
      return a(d).default;
    } }), Object.defineProperty(e, "QuoteType", { enumerable: !0, get: function() {
      return d.QuoteType;
    } }), e.ElementType = s(/* @__PURE__ */ tu());
    const h = /* @__PURE__ */ Yu();
    var y = /* @__PURE__ */ Yu();
    Object.defineProperty(e, "getFeed", { enumerable: !0, get: function() {
      return y.getFeed;
    } });
    const C = { xmlMode: !0 };
    function w(b, x = C) {
      return (0, h.getFeed)(l(b, x));
    }
    e.DomUtils = s(/* @__PURE__ */ Yu());
  })(Ae)), Ae;
}
var ju, jr;
function js() {
  return jr || (jr = 1, ju = (e) => {
    if (typeof e != "string")
      throw new TypeError("Expected a string");
    return e.replace(/[|\\{}()[\]^$+*?.]/g, "\\$&").replace(/-/g, "\\x2d");
  }), ju;
}
var du = {}, Jr;
function Js() {
  if (Jr) return du;
  Jr = 1, Object.defineProperty(du, "__esModule", { value: !0 });
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
    var s, a;
    return e(t) === !1 ? !1 : (s = t.constructor, s === void 0 ? !0 : (a = s.prototype, !(e(a) === !1 || a.hasOwnProperty("isPrototypeOf") === !1)));
  }
  return du.isPlainObject = u, du;
}
var Ju, Zr;
function Zs() {
  if (Zr) return Ju;
  Zr = 1;
  var e = function(b) {
    return u(b) && !t(b);
  };
  function u(w) {
    return !!w && typeof w == "object";
  }
  function t(w) {
    var b = Object.prototype.toString.call(w);
    return b === "[object RegExp]" || b === "[object Date]" || r(w);
  }
  var s = typeof Symbol == "function" && Symbol.for, a = s ? Symbol.for("react.element") : 60103;
  function r(w) {
    return w.$$typeof === a;
  }
  function o(w) {
    return Array.isArray(w) ? [] : {};
  }
  function i(w, b) {
    return b.clone !== !1 && b.isMergeableObject(w) ? y(o(w), w, b) : w;
  }
  function c(w, b, x) {
    return w.concat(b).map(function(m) {
      return i(m, x);
    });
  }
  function n(w, b) {
    if (!b.customMerge)
      return y;
    var x = b.customMerge(w);
    return typeof x == "function" ? x : y;
  }
  function l(w) {
    return Object.getOwnPropertySymbols ? Object.getOwnPropertySymbols(w).filter(function(b) {
      return Object.propertyIsEnumerable.call(w, b);
    }) : [];
  }
  function f(w) {
    return Object.keys(w).concat(l(w));
  }
  function A(w, b) {
    try {
      return b in w;
    } catch {
      return !1;
    }
  }
  function d(w, b) {
    return A(w, b) && !(Object.hasOwnProperty.call(w, b) && Object.propertyIsEnumerable.call(w, b));
  }
  function h(w, b, x) {
    var m = {};
    return x.isMergeableObject(w) && f(w).forEach(function(p) {
      m[p] = i(w[p], x);
    }), f(b).forEach(function(p) {
      d(w, p) || (A(w, p) && x.isMergeableObject(b[p]) ? m[p] = n(p, x)(w[p], b[p], x) : m[p] = i(b[p], x));
    }), m;
  }
  function y(w, b, x) {
    x = x || {}, x.arrayMerge = x.arrayMerge || c, x.isMergeableObject = x.isMergeableObject || e, x.cloneUnlessOtherwiseSpecified = i;
    var m = Array.isArray(b), p = Array.isArray(w), g = m === p;
    return g ? m ? x.arrayMerge(w, b, x) : h(w, b, x) : i(b, x);
  }
  y.all = function(b, x) {
    if (!Array.isArray(b))
      throw new Error("first argument should be an array");
    return b.reduce(function(m, p) {
      return y(m, p, x);
    }, {});
  };
  var C = y;
  return Ju = C, Ju;
}
var pu = { exports: {} }, Vs = pu.exports, Vr;
function zs() {
  return Vr || (Vr = 1, (function(e) {
    (function(u, t) {
      e.exports ? e.exports = t() : u.parseSrcset = t();
    })(Vs, function() {
      return function(u) {
        function t(m) {
          return m === " " || // space
          m === "	" || // horizontal tab
          m === `
` || // new line
          m === "\f" || // form feed
          m === "\r";
        }
        function s(m) {
          var p, g = m.exec(u.substring(C));
          if (g)
            return p = g[0], C += p.length, p;
        }
        for (var a = u.length, r = /^[ \t\n\r\u000c]+/, o = /^[, \t\n\r\u000c]+/, i = /^[^ \t\n\r\u000c]+/, c = /[,]+$/, n = /^\d+$/, l = /^-?(?:[0-9]+|[0-9]*\.[0-9]+)(?:[eE][+-]?[0-9]+)?$/, f, A, d, h, y, C = 0, w = []; ; ) {
          if (s(o), C >= a)
            return w;
          f = s(i), A = [], f.slice(-1) === "," ? (f = f.replace(c, ""), x()) : b();
        }
        function b() {
          for (s(r), d = "", h = "in descriptor"; ; ) {
            if (y = u.charAt(C), h === "in descriptor")
              if (t(y))
                d && (A.push(d), d = "", h = "after descriptor");
              else if (y === ",") {
                C += 1, d && A.push(d), x();
                return;
              } else if (y === "(")
                d = d + y, h = "in parens";
              else if (y === "") {
                d && A.push(d), x();
                return;
              } else
                d = d + y;
            else if (h === "in parens")
              if (y === ")")
                d = d + y, h = "in descriptor";
              else if (y === "") {
                A.push(d), x();
                return;
              } else
                d = d + y;
            else if (h === "after descriptor" && !t(y))
              if (y === "") {
                x();
                return;
              } else
                h = "in descriptor", C -= 1;
            C += 1;
          }
        }
        function x() {
          var m = !1, p, g, D, B, E = {}, _, v, k, S, F;
          for (B = 0; B < A.length; B++)
            _ = A[B], v = _[_.length - 1], k = _.substring(0, _.length - 1), S = parseInt(k, 10), F = parseFloat(k), n.test(k) && v === "w" ? ((p || g) && (m = !0), S === 0 ? m = !0 : p = S) : l.test(k) && v === "x" ? ((p || g || D) && (m = !0), F < 0 ? m = !0 : g = F) : n.test(k) && v === "h" ? ((D || g) && (m = !0), S === 0 ? m = !0 : D = S) : m = !0;
          m ? console && console.log && console.log("Invalid srcset descriptor found in '" + u + "' at '" + _ + "'.") : (E.url = f, p && (E.w = p), g && (E.d = g), D && (E.h = D), w.push(E));
        }
      };
    });
  })(pu)), pu.exports;
}
var Au = { exports: {} }, zr;
function Xs() {
  if (zr) return Au.exports;
  zr = 1;
  var e = String, u = function() {
    return { isColorSupported: !1, reset: e, bold: e, dim: e, italic: e, underline: e, inverse: e, hidden: e, strikethrough: e, black: e, red: e, green: e, yellow: e, blue: e, magenta: e, cyan: e, white: e, gray: e, bgBlack: e, bgRed: e, bgGreen: e, bgYellow: e, bgBlue: e, bgMagenta: e, bgCyan: e, bgWhite: e, blackBright: e, redBright: e, greenBright: e, yellowBright: e, blueBright: e, magentaBright: e, cyanBright: e, whiteBright: e, bgBlackBright: e, bgRedBright: e, bgGreenBright: e, bgYellowBright: e, bgBlueBright: e, bgMagentaBright: e, bgCyanBright: e, bgWhiteBright: e };
  };
  return Au.exports = u(), Au.exports.createColors = u, Au.exports;
}
const $s = {}, ec = /* @__PURE__ */ Object.freeze(/* @__PURE__ */ Object.defineProperty({
  __proto__: null,
  default: $s
}, Symbol.toStringTag, { value: "Module" })), ge = /* @__PURE__ */ Ns(ec);
var Zu, Xr;
function Mt() {
  if (Xr) return Zu;
  Xr = 1;
  let e = /* @__PURE__ */ Xs(), u = ge;
  class t extends Error {
    constructor(a, r, o, i, c, n) {
      super(a), this.name = "CssSyntaxError", this.reason = a, c && (this.file = c), i && (this.source = i), n && (this.plugin = n), typeof r < "u" && typeof o < "u" && (typeof r == "number" ? (this.line = r, this.column = o) : (this.line = r.line, this.column = r.column, this.endLine = o.line, this.endColumn = o.column)), this.setMessage(), Error.captureStackTrace && Error.captureStackTrace(this, t);
    }
    setMessage() {
      this.message = this.plugin ? this.plugin + ": " : "", this.message += this.file ? this.file : "<css input>", typeof this.line < "u" && (this.message += ":" + this.line + ":" + this.column), this.message += ": " + this.reason;
    }
    showSourceCode(a) {
      if (!this.source) return "";
      let r = this.source;
      a == null && (a = e.isColorSupported);
      let o = (d) => d, i = (d) => d, c = (d) => d;
      if (a) {
        let { bold: d, gray: h, red: y } = e.createColors(!0);
        i = (C) => d(y(C)), o = (C) => h(C), u && (c = (C) => u(C));
      }
      let n = r.split(/\r?\n/), l = Math.max(this.line - 3, 0), f = Math.min(this.line + 2, n.length), A = String(f).length;
      return n.slice(l, f).map((d, h) => {
        let y = l + 1 + h, C = " " + (" " + y).slice(-A) + " | ";
        if (y === this.line) {
          if (d.length > 160) {
            let b = 20, x = Math.max(0, this.column - b), m = Math.max(
              this.column + b,
              this.endColumn + b
            ), p = d.slice(x, m), g = o(C.replace(/\d/g, " ")) + d.slice(0, Math.min(this.column - 1, b - 1)).replace(/[^\t]/g, " ");
            return i(">") + o(C) + c(p) + `
 ` + g + i("^");
          }
          let w = o(C.replace(/\d/g, " ")) + d.slice(0, this.column - 1).replace(/[^\t]/g, " ");
          return i(">") + o(C) + c(d) + `
 ` + w + i("^");
        }
        return " " + o(C) + c(d);
      }).join(`
`);
    }
    toString() {
      let a = this.showSourceCode();
      return a && (a = `

` + a + `
`), this.name + ": " + this.message + a;
    }
  }
  return Zu = t, t.default = t, Zu;
}
var Vu, $r;
function dn() {
  if ($r) return Vu;
  $r = 1;
  const e = /(<)(\/?style\b)/gi, u = /(<)(!--)/g;
  function t(o) {
    return typeof o != "string" || !o.includes("<") ? o : o.replace(e, "\\3c $2").replace(u, "\\3c $2");
  }
  const s = {
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
  function a(o) {
    return o[0].toUpperCase() + o.slice(1);
  }
  class r {
    constructor(i) {
      this.builder = i;
    }
    atrule(i, c) {
      let n = i.raws, l = "@" + i.name, f = i.params ? this.rawValue(i, "params") : "";
      if (typeof n.afterName < "u" ? l += n.afterName : f && (l += " "), i.nodes)
        this.block(i, l + f);
      else {
        let A = (n.between || "") + (c ? ";" : "");
        this.builder(t(l + f + A), i);
      }
    }
    beforeAfter(i, c) {
      let n;
      i.type === "decl" ? n = this.raw(i, null, "beforeDecl") : i.type === "comment" ? n = this.raw(i, null, "beforeComment") : c === "before" ? n = this.raw(i, null, "beforeRule") : n = this.raw(i, null, "beforeClose");
      let l = i.parent, f = 0;
      for (; l && l.type !== "root"; )
        f += 1, l = l.parent;
      if (n.includes(`
`)) {
        let A = this.raw(i, null, "indent");
        if (A.length)
          for (let d = 0; d < f; d++) n += A;
      }
      return n;
    }
    block(i, c) {
      let n = this.raw(i, "between", "beforeOpen");
      this.builder(t(c + n) + "{", i, "start");
      let l;
      i.nodes && i.nodes.length ? (this.body(i), l = this.raw(i, "after")) : l = this.raw(i, "after", "emptyBody"), l && this.builder(t(l)), this.builder("}", i, "end");
    }
    body(i) {
      let c = i.nodes, n = c.length - 1;
      for (; n > 0 && c[n].type === "comment"; )
        n -= 1;
      let l = this.raw(i, "semicolon"), f = i.type === "document";
      for (let A = 0; A < c.length; A++) {
        let d = c[A], h = this.raw(d, "before");
        h && this.builder(f ? h : t(h)), this.stringify(d, n !== A || l);
      }
    }
    comment(i) {
      let c = this.raw(i, "left", "commentLeft"), n = this.raw(i, "right", "commentRight");
      this.builder(t("/*" + c + i.text + n + "*/"), i);
    }
    decl(i, c) {
      let n = i.raws, l = this.raw(i, "between", "colon"), f = i.prop + l + this.rawValue(i, "value");
      i.important && (f += n.important || " !important"), c && (f += ";"), this.builder(t(f), i);
    }
    document(i) {
      this.body(i);
    }
    raw(i, c, n) {
      let l;
      if (n || (n = c), c && (l = i.raws[c], typeof l < "u"))
        return l;
      let f = i.parent;
      if (n === "before" && (!f || f.type === "root" && f.first === i || f && f.type === "document"))
        return "";
      if (!f) return s[n];
      let A = i.root(), d = A.rawCache || (A.rawCache = {});
      if (typeof d[n] < "u")
        return d[n];
      if (n === "before" || n === "after")
        return this.beforeAfter(i, n);
      {
        let h = "raw" + a(n);
        this[h] ? l = this[h](A, i) : A.walk((y) => {
          if (l = y.raws[c], typeof l < "u") return !1;
        });
      }
      return typeof l > "u" && (l = s[n]), d[n] = l, l;
    }
    rawBeforeClose(i) {
      let c;
      return i.walk((n) => {
        if (n.nodes && n.nodes.length > 0 && typeof n.raws.after < "u")
          return c = n.raws.after, c.includes(`
`) && (c = c.replace(/[^\n]+$/, "")), !1;
      }), c && (c = c.replace(/\S/g, "")), c;
    }
    rawBeforeComment(i, c) {
      let n;
      return i.walkComments((l) => {
        if (typeof l.raws.before < "u")
          return n = l.raws.before, n.includes(`
`) && (n = n.replace(/[^\n]+$/, "")), !1;
      }), typeof n > "u" ? n = this.raw(c, null, "beforeDecl") : n && (n = n.replace(/\S/g, "")), n;
    }
    rawBeforeDecl(i, c) {
      let n;
      return i.walkDecls((l) => {
        if (typeof l.raws.before < "u")
          return n = l.raws.before, n.includes(`
`) && (n = n.replace(/[^\n]+$/, "")), !1;
      }), typeof n > "u" ? n = this.raw(c, null, "beforeRule") : n && (n = n.replace(/\S/g, "")), n;
    }
    rawBeforeOpen(i) {
      let c;
      return i.walk((n) => {
        if (n.type !== "decl" && (c = n.raws.between, typeof c < "u"))
          return !1;
      }), c;
    }
    rawBeforeRule(i) {
      let c;
      return i.walk((n) => {
        if (n.nodes && (n.parent !== i || i.first !== n) && typeof n.raws.before < "u")
          return c = n.raws.before, c.includes(`
`) && (c = c.replace(/[^\n]+$/, "")), !1;
      }), c && (c = c.replace(/\S/g, "")), c;
    }
    rawColon(i) {
      let c;
      return i.walkDecls((n) => {
        if (typeof n.raws.between < "u")
          return c = n.raws.between.replace(/[^\s:]/g, ""), !1;
      }), c;
    }
    rawEmptyBody(i) {
      let c;
      return i.walk((n) => {
        if (n.nodes && n.nodes.length === 0 && (c = n.raws.after, typeof c < "u"))
          return !1;
      }), c;
    }
    rawIndent(i) {
      if (i.raws.indent) return i.raws.indent;
      let c;
      return i.walk((n) => {
        let l = n.parent;
        if (l && l !== i && l.parent && l.parent === i && typeof n.raws.before < "u") {
          let f = n.raws.before.split(`
`);
          return c = f[f.length - 1], c = c.replace(/\S/g, ""), !1;
        }
      }), c;
    }
    rawSemicolon(i) {
      let c;
      return i.walk((n) => {
        if (n.nodes && n.nodes.length && n.last.type === "decl" && (c = n.raws.semicolon, typeof c < "u"))
          return !1;
      }), c;
    }
    rawValue(i, c) {
      let n = i[c], l = i.raws[c];
      return l && l.value === n ? l.raw : n;
    }
    root(i) {
      if (this.body(i), i.raws.after) {
        let c = i.raws.after, n = i.parent && i.parent.type === "document";
        this.builder(n ? c : t(c));
      }
    }
    rule(i) {
      this.block(i, this.rawValue(i, "selector")), i.raws.ownSemicolon && this.builder(t(i.raws.ownSemicolon), i, "end");
    }
    stringify(i, c) {
      if (!this[i.type])
        throw new Error(
          "Unknown AST node type " + i.type + ". Maybe you need to change PostCSS stringifier."
        );
      this[i.type](i, c);
    }
  }
  return Vu = r, r.default = r, Vu;
}
var zu, e0;
function Eu() {
  if (e0) return zu;
  e0 = 1;
  let e = dn();
  function u(t, s) {
    new e(s).stringify(t);
  }
  return zu = u, u.default = u, zu;
}
var hu = {}, u0;
function Ot() {
  return u0 || (u0 = 1, hu.isClean = Symbol("isClean"), hu.my = Symbol("my")), hu;
}
var Xu, t0;
function _u() {
  if (t0) return Xu;
  t0 = 1;
  let e = Mt(), u = dn(), t = Eu(), { isClean: s, my: a } = Ot();
  function r(c, n) {
    let l = new c.constructor();
    for (let f in c) {
      if (!Object.prototype.hasOwnProperty.call(c, f) || f === "proxyCache") continue;
      let A = c[f], d = typeof A;
      f === "parent" && d === "object" ? n && (l[f] = n) : f === "source" ? l[f] = A : Array.isArray(A) ? l[f] = A.map((h) => r(h, l)) : (d === "object" && A !== null && (A = r(A)), l[f] = A);
    }
    return l;
  }
  function o(c, n) {
    if (n && typeof n.offset < "u")
      return n.offset;
    let l = 1, f = 1, A = 0;
    for (let d = 0; d < c.length; d++) {
      if (f === n.line && l === n.column) {
        A = d;
        break;
      }
      c[d] === `
` ? (l = 1, f += 1) : l += 1;
    }
    return A;
  }
  class i {
    get proxyOf() {
      return this;
    }
    constructor(n = {}) {
      this.raws = {}, this[s] = !1, this[a] = !0;
      for (let l in n)
        if (l === "nodes") {
          this.nodes = [];
          for (let f of n[l])
            typeof f.clone == "function" ? this.append(f.clone()) : this.append(f);
        } else
          this[l] = n[l];
    }
    addToError(n) {
      if (n.postcssNode = this, n.stack && this.source && /\n\s{4}at /.test(n.stack)) {
        let l = this.source;
        n.stack = n.stack.replace(
          /\n\s{4}at /,
          `$&${l.input.from}:${l.start.line}:${l.start.column}$&`
        );
      }
      return n;
    }
    after(n) {
      return this.parent.insertAfter(this, n), this;
    }
    assign(n = {}) {
      for (let l in n)
        this[l] = n[l];
      return this;
    }
    before(n) {
      return this.parent.insertBefore(this, n), this;
    }
    cleanRaws(n) {
      delete this.raws.before, delete this.raws.after, n || delete this.raws.between;
    }
    clone(n = {}) {
      let l = r(this);
      for (let f in n)
        l[f] = n[f];
      return l;
    }
    cloneAfter(n = {}) {
      let l = this.clone(n);
      return this.parent.insertAfter(this, l), l;
    }
    cloneBefore(n = {}) {
      let l = this.clone(n);
      return this.parent.insertBefore(this, l), l;
    }
    error(n, l = {}) {
      if (this.source) {
        let { end: f, start: A } = this.rangeBy(l);
        return this.source.input.error(
          n,
          { column: A.column, line: A.line },
          { column: f.column, line: f.line },
          l
        );
      }
      return new e(n);
    }
    getProxyProcessor() {
      return {
        get(n, l) {
          return l === "proxyOf" ? n : l === "root" ? () => n.root().toProxy() : n[l];
        },
        set(n, l, f) {
          return n[l] === f || (n[l] = f, (l === "prop" || l === "value" || l === "name" || l === "params" || l === "important" || /* c8 ignore next */
          l === "text") && n.markDirty()), !0;
        }
      };
    }
    /* c8 ignore next 3 */
    markClean() {
      this[s] = !0;
    }
    markDirty() {
      if (this[s]) {
        this[s] = !1;
        let n = this;
        for (; n = n.parent; )
          n[s] = !1;
      }
    }
    next() {
      if (!this.parent) return;
      let n = this.parent.index(this);
      return this.parent.nodes[n + 1];
    }
    positionBy(n = {}) {
      let l = this.source.start;
      if (n.index)
        l = this.positionInside(n.index);
      else if (n.word) {
        let f = "document" in this.source.input ? this.source.input.document : this.source.input.css, d = f.slice(
          o(f, this.source.start),
          o(f, this.source.end)
        ).indexOf(n.word);
        d !== -1 && (l = this.positionInside(d));
      }
      return l;
    }
    positionInside(n) {
      let l = this.source.start.column, f = this.source.start.line, A = "document" in this.source.input ? this.source.input.document : this.source.input.css, d = o(A, this.source.start), h = d + n;
      for (let y = d; y < h; y++)
        A[y] === `
` ? (l = 1, f += 1) : l += 1;
      return { column: l, line: f, offset: h };
    }
    prev() {
      if (!this.parent) return;
      let n = this.parent.index(this);
      return this.parent.nodes[n - 1];
    }
    rangeBy(n = {}) {
      let l = "document" in this.source.input ? this.source.input.document : this.source.input.css, f = {
        column: this.source.start.column,
        line: this.source.start.line,
        offset: o(l, this.source.start)
      }, A = this.source.end ? {
        column: this.source.end.column + 1,
        line: this.source.end.line,
        offset: typeof this.source.end.offset == "number" ? (
          // `source.end.offset` is exclusive, so we don't need to add 1
          this.source.end.offset
        ) : (
          // Since line/column in this.source.end is inclusive,
          // the `sourceOffset(... , this.source.end)` returns an inclusive offset.
          // So, we add 1 to convert it to exclusive.
          o(l, this.source.end) + 1
        )
      } : {
        column: f.column + 1,
        line: f.line,
        offset: f.offset + 1
      };
      if (n.word) {
        let h = l.slice(
          o(l, this.source.start),
          o(l, this.source.end)
        ).indexOf(n.word);
        h !== -1 && (f = this.positionInside(h), A = this.positionInside(h + n.word.length));
      } else
        n.start ? f = {
          column: n.start.column,
          line: n.start.line,
          offset: o(l, n.start)
        } : n.index && (f = this.positionInside(n.index)), n.end ? A = {
          column: n.end.column,
          line: n.end.line,
          offset: o(l, n.end)
        } : typeof n.endIndex == "number" ? A = this.positionInside(n.endIndex) : n.index && (A = this.positionInside(n.index + 1));
      return (A.line < f.line || A.line === f.line && A.column <= f.column) && (A = {
        column: f.column + 1,
        line: f.line,
        offset: f.offset + 1
      }), { end: A, start: f };
    }
    raw(n, l) {
      return new u().raw(this, n, l);
    }
    remove() {
      return this.parent && this.parent.removeChild(this), this.parent = void 0, this;
    }
    replaceWith(...n) {
      if (this.parent) {
        let l = this, f = !1;
        for (let A of n)
          A === this ? f = !0 : f ? (this.parent.insertAfter(l, A), l = A) : this.parent.insertBefore(l, A);
        f || this.remove();
      }
      return this;
    }
    root() {
      let n = this;
      for (; n.parent && n.parent.type !== "document"; )
        n = n.parent;
      return n;
    }
    toJSON(n, l) {
      let f = {}, A = l == null;
      l = l || /* @__PURE__ */ new Map();
      let d = 0;
      for (let h in this) {
        if (!Object.prototype.hasOwnProperty.call(this, h) || h === "parent" || h === "proxyCache") continue;
        let y = this[h];
        if (Array.isArray(y))
          f[h] = y.map((C) => typeof C == "object" && C.toJSON ? C.toJSON(null, l) : C);
        else if (typeof y == "object" && y.toJSON)
          f[h] = y.toJSON(null, l);
        else if (h === "source") {
          if (y == null) continue;
          let C = l.get(y.input);
          C == null && (C = d, l.set(y.input, d), d++), f[h] = {
            end: y.end,
            inputId: C,
            start: y.start
          };
        } else
          f[h] = y;
      }
      return A && (f.inputs = [...l.keys()].map((h) => h.toJSON())), f;
    }
    toProxy() {
      return this.proxyCache || (this.proxyCache = new Proxy(this, this.getProxyProcessor())), this.proxyCache;
    }
    toString(n = t) {
      n.stringify && (n = n.stringify);
      let l = "";
      return n(this, (f) => {
        l += f;
      }), l;
    }
    warn(n, l, f = {}) {
      let A = { node: this };
      for (let d in f) A[d] = f[d];
      return n.warn(l, A);
    }
  }
  return Xu = i, i.default = i, Xu;
}
var $u, r0;
function Iu() {
  if (r0) return $u;
  r0 = 1;
  let e = _u();
  class u extends e {
    constructor(s) {
      super(s), this.type = "comment";
    }
  }
  return $u = u, u.default = u, $u;
}
var et, n0;
function ku() {
  if (n0) return et;
  n0 = 1;
  let e = _u();
  class u extends e {
    get variable() {
      return this.prop.startsWith("--") || this.prop[0] === "$";
    }
    constructor(s) {
      s && typeof s.value < "u" && typeof s.value != "string" && (s = { ...s, value: String(s.value) }), super(s), this.type = "decl";
    }
  }
  return et = u, u.default = u, et;
}
var ut, i0;
function Pe() {
  if (i0) return ut;
  i0 = 1;
  let e = Iu(), u = ku(), t = _u(), { isClean: s, my: a } = Ot(), r, o, i, c;
  function n(A) {
    return A.map((d) => (d.nodes && (d.nodes = n(d.nodes)), delete d.source, d));
  }
  function l(A) {
    if (A[s] = !1, A.proxyOf.nodes)
      for (let d of A.proxyOf.nodes)
        l(d);
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
    append(...d) {
      for (let h of d) {
        let y = this.normalize(h, this.last);
        for (let C of y) this.proxyOf.nodes.push(C);
      }
      return this.markDirty(), this;
    }
    cleanRaws(d) {
      if (super.cleanRaws(d), this.nodes)
        for (let h of this.nodes) h.cleanRaws(d);
    }
    each(d) {
      if (!this.proxyOf.nodes) return;
      let h = this.getIterator(), y, C;
      for (; this.indexes[h] < this.proxyOf.nodes.length && (y = this.indexes[h], C = d(this.proxyOf.nodes[y], y), C !== !1); )
        this.indexes[h] += 1;
      return delete this.indexes[h], C;
    }
    every(d) {
      return this.nodes.every(d);
    }
    getIterator() {
      this.lastEach || (this.lastEach = 0), this.indexes || (this.indexes = {}), this.lastEach += 1;
      let d = this.lastEach;
      return this.indexes[d] = 0, d;
    }
    getProxyProcessor() {
      return {
        get(d, h) {
          return h === "proxyOf" ? d : d[h] ? h === "each" || typeof h == "string" && h.startsWith("walk") ? (...y) => d[h](
            ...y.map((C) => typeof C == "function" ? (w, b) => C(w.toProxy(), b) : C)
          ) : h === "every" || h === "some" ? (y) => d[h](
            (C, ...w) => y(C.toProxy(), ...w)
          ) : h === "root" ? () => d.root().toProxy() : h === "nodes" ? d.nodes.map((y) => y.toProxy()) : h === "first" || h === "last" ? d[h].toProxy() : d[h] : d[h];
        },
        set(d, h, y) {
          return d[h] === y || (d[h] = y, (h === "name" || h === "params" || h === "selector") && d.markDirty()), !0;
        }
      };
    }
    index(d) {
      return typeof d == "number" ? d : (d.proxyOf && (d = d.proxyOf), this.proxyOf.nodes.indexOf(d));
    }
    insertAfter(d, h) {
      let y = this.index(d), C = this.normalize(h, this.proxyOf.nodes[y]).reverse();
      y = this.index(d);
      for (let b of C) this.proxyOf.nodes.splice(y + 1, 0, b);
      let w;
      for (let b in this.indexes)
        w = this.indexes[b], y < w && (this.indexes[b] = w + C.length);
      return this.markDirty(), this;
    }
    insertBefore(d, h) {
      let y = this.index(d), C = y === 0 ? "prepend" : !1, w = this.normalize(
        h,
        this.proxyOf.nodes[y],
        C
      ).reverse();
      y = this.index(d);
      for (let x of w) this.proxyOf.nodes.splice(y, 0, x);
      let b;
      for (let x in this.indexes)
        b = this.indexes[x], y <= b && (this.indexes[x] = b + w.length);
      return this.markDirty(), this;
    }
    normalize(d, h) {
      if (typeof d == "string")
        d = n(o(d).nodes);
      else if (typeof d > "u")
        d = [];
      else if (Array.isArray(d)) {
        d = d.slice(0);
        for (let C of d)
          C.parent && C.parent.removeChild(C, "ignore");
      } else if (d.type === "root" && this.type !== "document") {
        d = d.nodes.slice(0);
        for (let C of d)
          C.parent && C.parent.removeChild(C, "ignore");
      } else if (d.type)
        d = [d];
      else if (d.prop) {
        if (typeof d.value > "u")
          throw new Error("Value field is missed in node creation");
        typeof d.value != "string" && (d.value = String(d.value)), d = [new u(d)];
      } else if (d.selector || d.selectors)
        d = [new c(d)];
      else if (d.name)
        d = [new r(d)];
      else if (d.text)
        d = [new e(d)];
      else
        throw new Error("Unknown node type in node creation");
      return d.map((C) => (C[a] || f.rebuild(C), C = C.proxyOf, C.parent && C.parent.removeChild(C), C[s] && l(C), C.raws || (C.raws = {}), typeof C.raws.before > "u" && h && typeof h.raws.before < "u" && (C.raws.before = h.raws.before.replace(/\S/g, "")), C.parent = this.proxyOf, C));
    }
    prepend(...d) {
      d = d.reverse();
      for (let h of d) {
        let y = this.normalize(h, this.first, "prepend").reverse();
        for (let C of y) this.proxyOf.nodes.unshift(C);
        for (let C in this.indexes)
          this.indexes[C] = this.indexes[C] + y.length;
      }
      return this.markDirty(), this;
    }
    push(d) {
      return d.parent = this, this.proxyOf.nodes.push(d), this;
    }
    removeAll() {
      for (let d of this.proxyOf.nodes) d.parent = void 0;
      return this.proxyOf.nodes = [], this.markDirty(), this;
    }
    removeChild(d) {
      d = this.index(d), this.proxyOf.nodes[d].parent = void 0, this.proxyOf.nodes.splice(d, 1);
      let h;
      for (let y in this.indexes)
        h = this.indexes[y], h >= d && (this.indexes[y] = h - 1);
      return this.markDirty(), this;
    }
    replaceValues(d, h, y) {
      return y || (y = h, h = {}), this.walkDecls((C) => {
        h.props && !h.props.includes(C.prop) || h.fast && !C.value.includes(h.fast) || (C.value = C.value.replace(d, y));
      }), this.markDirty(), this;
    }
    some(d) {
      return this.nodes.some(d);
    }
    walk(d) {
      return this.each((h, y) => {
        let C;
        try {
          C = d(h, y);
        } catch (w) {
          throw h.addToError(w);
        }
        return C !== !1 && h.walk && (C = h.walk(d)), C;
      });
    }
    walkAtRules(d, h) {
      return h ? d instanceof RegExp ? this.walk((y, C) => {
        if (y.type === "atrule" && d.test(y.name))
          return h(y, C);
      }) : this.walk((y, C) => {
        if (y.type === "atrule" && y.name === d)
          return h(y, C);
      }) : (h = d, this.walk((y, C) => {
        if (y.type === "atrule")
          return h(y, C);
      }));
    }
    walkComments(d) {
      return this.walk((h, y) => {
        if (h.type === "comment")
          return d(h, y);
      });
    }
    walkDecls(d, h) {
      return h ? d instanceof RegExp ? this.walk((y, C) => {
        if (y.type === "decl" && d.test(y.prop))
          return h(y, C);
      }) : this.walk((y, C) => {
        if (y.type === "decl" && y.prop === d)
          return h(y, C);
      }) : (h = d, this.walk((y, C) => {
        if (y.type === "decl")
          return h(y, C);
      }));
    }
    walkRules(d, h) {
      return h ? d instanceof RegExp ? this.walk((y, C) => {
        if (y.type === "rule" && d.test(y.selector))
          return h(y, C);
      }) : this.walk((y, C) => {
        if (y.type === "rule" && y.selector === d)
          return h(y, C);
      }) : (h = d, this.walk((y, C) => {
        if (y.type === "rule")
          return h(y, C);
      }));
    }
  }
  return f.registerParse = (A) => {
    o = A;
  }, f.registerRule = (A) => {
    c = A;
  }, f.registerAtRule = (A) => {
    r = A;
  }, f.registerRoot = (A) => {
    i = A;
  }, ut = f, f.default = f, f.rebuild = (A) => {
    A.type === "atrule" ? Object.setPrototypeOf(A, r.prototype) : A.type === "rule" ? Object.setPrototypeOf(A, c.prototype) : A.type === "decl" ? Object.setPrototypeOf(A, u.prototype) : A.type === "comment" ? Object.setPrototypeOf(A, e.prototype) : A.type === "root" && Object.setPrototypeOf(A, i.prototype), A[a] = !0, A.nodes && A.nodes.forEach((d) => {
      f.rebuild(d);
    });
  }, ut;
}
var tt, a0;
function Qt() {
  if (a0) return tt;
  a0 = 1;
  let e = Pe();
  class u extends e {
    constructor(s) {
      super(s), this.type = "atrule";
    }
    append(...s) {
      return this.proxyOf.nodes || (this.nodes = []), super.append(...s);
    }
    prepend(...s) {
      return this.proxyOf.nodes || (this.nodes = []), super.prepend(...s);
    }
  }
  return tt = u, u.default = u, e.registerAtRule(u), tt;
}
var rt, s0;
function Lt() {
  if (s0) return rt;
  s0 = 1;
  let e = Pe(), u, t;
  class s extends e {
    constructor(r) {
      super({ type: "document", ...r }), this.nodes || (this.nodes = []);
    }
    toResult(r = {}) {
      return new u(new t(), this, r).stringify();
    }
  }
  return s.registerLazyResult = (a) => {
    u = a;
  }, s.registerProcessor = (a) => {
    t = a;
  }, rt = s, s.default = s, rt;
}
var nt, c0;
function uc() {
  if (c0) return nt;
  c0 = 1;
  let e = "useandom-26T198340PX75pxJACKVERYMINDBUSHWOLF_GQZbfghjklqvwyzrict";
  return nt = { nanoid: (s = 21) => {
    let a = "", r = s | 0;
    for (; r--; )
      a += e[Math.random() * 64 | 0];
    return a;
  }, customAlphabet: (s, a = 21) => (r = a) => {
    let o = "", i = r | 0;
    for (; i--; )
      o += s[Math.random() * s.length | 0];
    return o;
  } }, nt;
}
var it, o0;
function An() {
  if (o0) return it;
  o0 = 1;
  let { existsSync: e, readFileSync: u } = ge, { dirname: t, join: s } = ge, { SourceMapConsumer: a, SourceMapGenerator: r } = ge;
  function o(c) {
    return Buffer ? Buffer.from(c, "base64").toString() : window.atob(c);
  }
  class i {
    constructor(n, l) {
      if (l.map === !1) return;
      l.unsafeMap && (this.unsafeMap = !0), this.loadAnnotation(n), this.inline = this.startWith(this.annotation, "data:");
      let f = l.map ? l.map.prev : void 0, A = this.loadMap(l.from, f);
      !this.mapFile && l.from && (this.mapFile = l.from), this.mapFile && (this.root = t(this.mapFile)), A && (this.text = A);
    }
    consumer() {
      return this.consumerCache || (this.consumerCache = new a(this.json || this.text)), this.consumerCache;
    }
    decodeInline(n) {
      let l = /^data:application\/json;charset=utf-?8;base64,/, f = /^data:application\/json;base64,/, A = /^data:application\/json;charset=utf-?8,/, d = /^data:application\/json,/, h = n.match(A) || n.match(d);
      if (h)
        return decodeURIComponent(n.substr(h[0].length));
      let y = n.match(l) || n.match(f);
      if (y)
        return o(n.substr(y[0].length));
      let C = n.slice(22);
      throw C = C.slice(0, C.indexOf(",")), new Error("Unsupported source map encoding " + C);
    }
    getAnnotationURL(n) {
      return n.replace(/^\/\*\s*# sourceMappingURL=/, "").trim();
    }
    isMap(n) {
      return typeof n != "object" ? !1 : typeof n.mappings == "string" || typeof n._mappings == "string" || Array.isArray(n.sections);
    }
    loadAnnotation(n) {
      let l = n.match(/\/\*\s*# sourceMappingURL=/g);
      if (!l) return;
      let f = n.lastIndexOf(l.pop()), A = n.indexOf("*/", f);
      f > -1 && A > -1 && (this.annotation = this.getAnnotationURL(n.substring(f, A)));
    }
    loadFile(n, l, f) {
      if (!(!f && !this.unsafeMap && !/\.map$/i.test(n)) && (this.root = t(n), e(n)))
        return this.mapFile = n, u(n, "utf-8").toString().trim();
    }
    loadMap(n, l) {
      if (l === !1) return !1;
      if (l) {
        if (typeof l == "string")
          return l;
        if (typeof l == "function") {
          let f = l(n);
          if (f) {
            let A = this.loadFile(f, n, !0);
            if (!A)
              throw new Error(
                "Unable to load previous source map: " + f.toString()
              );
            return A;
          }
        } else {
          if (l instanceof a)
            return r.fromSourceMap(l).toString();
          if (l instanceof r)
            return l.toString();
          if (this.isMap(l))
            return JSON.stringify(l);
          throw new Error(
            "Unsupported previous source map format: " + l.toString()
          );
        }
      } else {
        if (this.inline)
          return this.decodeInline(this.annotation);
        if (this.annotation) {
          let f = this.annotation;
          n && (f = s(t(n), f));
          let A = this.loadFile(f, n, !1);
          if (A)
            try {
              this.json = JSON.parse(A.replace(/^\)]}'[^\n]*\n/, ""));
            } catch {
              return;
            }
          return A;
        }
      }
    }
    startWith(n, l) {
      return n ? n.substr(0, l.length) === l : !1;
    }
    withContent() {
      return !!(this.consumer().sourcesContent && this.consumer().sourcesContent.length > 0);
    }
  }
  return it = i, i.default = i, it;
}
var at, l0;
function Bu() {
  if (l0) return at;
  l0 = 1;
  let { nanoid: e } = /* @__PURE__ */ uc(), { isAbsolute: u, resolve: t } = ge, { SourceMapConsumer: s, SourceMapGenerator: a } = ge, { fileURLToPath: r, pathToFileURL: o } = ge, i = Mt(), c = An(), n = ge, l = Symbol("lineToIndexCache"), f = !!(s && a), A = !!(t && u);
  function d(y) {
    if (y[l]) return y[l];
    let C = y.css.split(`
`), w = new Array(C.length), b = 0;
    for (let x = 0, m = C.length; x < m; x++)
      w[x] = b, b += C[x].length + 1;
    return y[l] = w, w;
  }
  class h {
    get from() {
      return this.file || this.id;
    }
    constructor(C, w = {}) {
      if (C === null || typeof C > "u" || typeof C == "object" && !C.toString)
        throw new Error(`PostCSS received ${C} instead of CSS string`);
      if (this.css = C.toString(), this.css[0] === "\uFEFF" || this.css[0] === "￾" ? (this.hasBOM = !0, this.css = this.css.slice(1)) : this.hasBOM = !1, this.document = this.css, w.document && (this.document = w.document.toString()), w.from && (!A || /^\w+:\/\//.test(w.from) || u(w.from) ? this.file = w.from : this.file = t(w.from)), A && f) {
        let b = new c(this.css, w);
        if (b.text) {
          this.map = b;
          let x = b.consumer().file;
          !this.file && x && (this.file = this.mapResolve(x));
        }
      }
      this.file || (this.id = "<input css " + e(6) + ">"), this.map && (this.map.file = this.from);
    }
    error(C, w, b, x = {}) {
      let m, p, g, D, B;
      if (w && typeof w == "object") {
        let _ = w, v = b;
        if (typeof _.offset == "number") {
          D = _.offset;
          let k = this.fromOffset(D);
          w = k.line, b = k.col;
        } else
          w = _.line, b = _.column, D = this.fromLineAndColumn(w, b);
        if (typeof v.offset == "number") {
          g = v.offset;
          let k = this.fromOffset(g);
          p = k.line, m = k.col;
        } else
          p = v.line, m = v.column, g = this.fromLineAndColumn(v.line, v.column);
      } else if (b)
        D = this.fromLineAndColumn(w, b);
      else {
        D = w;
        let _ = this.fromOffset(D);
        w = _.line, b = _.col;
      }
      let E = this.origin(w, b, p, m);
      return E ? B = new i(
        C,
        E.endLine === void 0 ? E.line : { column: E.column, line: E.line },
        E.endLine === void 0 ? E.column : { column: E.endColumn, line: E.endLine },
        E.source,
        E.file,
        x.plugin
      ) : B = new i(
        C,
        p === void 0 ? w : { column: b, line: w },
        p === void 0 ? b : { column: m, line: p },
        this.css,
        this.file,
        x.plugin
      ), B.input = {
        column: b,
        endColumn: m,
        endLine: p,
        endOffset: g,
        line: w,
        offset: D,
        source: this.css
      }, this.file && (o && (B.input.url = o(this.file).toString()), B.input.file = this.file), B;
    }
    fromLineAndColumn(C, w) {
      return d(this)[C - 1] + w - 1;
    }
    fromOffset(C) {
      let w = d(this), b = w[w.length - 1], x = 0;
      if (C >= b)
        x = w.length - 1;
      else {
        let m = w.length - 2, p;
        for (; x < m; )
          if (p = x + (m - x >> 1), C < w[p])
            m = p - 1;
          else if (C >= w[p + 1])
            x = p + 1;
          else {
            x = p;
            break;
          }
      }
      return {
        col: C - w[x] + 1,
        line: x + 1
      };
    }
    mapResolve(C) {
      return /^\w+:\/\//.test(C) ? C : t(this.map.consumer().sourceRoot || this.map.root || ".", C);
    }
    origin(C, w, b, x) {
      if (!this.map) return !1;
      let m = this.map.consumer(), p = m.originalPositionFor({ column: w, line: C });
      if (!p.source) return !1;
      let g;
      typeof b == "number" && (g = m.originalPositionFor({ column: x, line: b }));
      let D;
      u(p.source) ? D = o(p.source) : D = new URL(
        p.source,
        this.map.consumer().sourceRoot || o(this.map.mapFile)
      );
      let B = {
        column: p.column,
        endColumn: g && g.column,
        endLine: g && g.line,
        line: p.line,
        url: D.toString()
      };
      if (D.protocol === "file:")
        if (r)
          B.file = r(D);
        else
          throw new Error("file: protocol is not available in this PostCSS build");
      let E = m.sourceContentFor(p.source);
      return E && (B.source = E), B;
    }
    toJSON() {
      let C = {};
      for (let w of ["hasBOM", "css", "file", "id"])
        this[w] != null && (C[w] = this[w]);
      return this.map && (C.map = { ...this.map }, C.map.consumerCache && (C.map.consumerCache = void 0)), C;
    }
  }
  return at = h, h.default = h, n && n.registerInput && n.registerInput(h), at;
}
var st, f0;
function ru() {
  if (f0) return st;
  f0 = 1;
  let e = Pe(), u, t;
  class s extends e {
    constructor(r) {
      super(r), this.type = "root", this.nodes || (this.nodes = []);
    }
    normalize(r, o, i) {
      let c = super.normalize(r);
      if (o) {
        if (i === "prepend")
          this.nodes.length > 1 ? o.raws.before = this.nodes[1].raws.before : delete o.raws.before;
        else if (this.first !== o)
          for (let n of c)
            n.raws.before = o.raws.before;
      }
      return c;
    }
    removeChild(r, o) {
      let i = this.index(r);
      return !o && i === 0 && this.nodes.length > 1 && (this.nodes[1].raws.before = this.nodes[i].raws.before), super.removeChild(r);
    }
    toResult(r = {}) {
      return new u(new t(), this, r).stringify();
    }
  }
  return s.registerLazyResult = (a) => {
    u = a;
  }, s.registerProcessor = (a) => {
    t = a;
  }, st = s, s.default = s, e.registerRoot(s), st;
}
var ct, d0;
function hn() {
  if (d0) return ct;
  d0 = 1;
  let e = {
    comma(u) {
      return e.split(u, [","], !0);
    },
    space(u) {
      let t = [" ", `
`, "	"];
      return e.split(u, t);
    },
    split(u, t, s) {
      let a = [], r = "", o = !1, i = 0, c = !1, n = "", l = !1;
      for (let f of u)
        l ? l = !1 : f === "\\" ? l = !0 : c ? f === n && (c = !1) : f === '"' || f === "'" ? (c = !0, n = f) : f === "(" ? i += 1 : f === ")" ? i > 0 && (i -= 1) : i === 0 && t.includes(f) && (o = !0), o ? (r !== "" && a.push(r.trim()), r = "", o = !1) : r += f;
      return (s || r !== "") && a.push(r.trim()), a;
    }
  };
  return ct = e, e.default = e, ct;
}
var ot, A0;
function Pt() {
  if (A0) return ot;
  A0 = 1;
  let e = Pe(), u = hn();
  class t extends e {
    get selectors() {
      return u.comma(this.selector);
    }
    set selectors(a) {
      let r = this.selector ? this.selector.match(/,\s*/) : null, o = r ? r[0] : "," + this.raw("between", "beforeOpen");
      this.selector = a.join(o);
    }
    constructor(a) {
      super(a), this.type = "rule", this.nodes || (this.nodes = []);
    }
  }
  return ot = t, t.default = t, e.registerRule(t), ot;
}
var lt, h0;
function tc() {
  if (h0) return lt;
  h0 = 1;
  let e = Qt(), u = Iu(), t = ku(), s = Bu(), a = An(), r = ru(), o = Pt();
  function i(c, n) {
    if (Array.isArray(c)) return c.map((A) => i(A));
    let { inputs: l, ...f } = c;
    if (l) {
      n = [];
      for (let A of l) {
        let d = { ...A, __proto__: s.prototype };
        d.map && (d.map = {
          ...d.map,
          __proto__: a.prototype
        }), n.push(d);
      }
    }
    if (f.nodes && (f.nodes = c.nodes.map((A) => i(A, n))), f.source) {
      let { inputId: A, ...d } = f.source;
      f.source = d, A != null && (f.source.input = n[A]);
    }
    if (f.type === "root")
      return new r(f);
    if (f.type === "decl")
      return new t(f);
    if (f.type === "rule")
      return new o(f);
    if (f.type === "comment")
      return new u(f);
    if (f.type === "atrule")
      return new e(f);
    throw new Error("Unknown node type: " + c.type);
  }
  return lt = i, i.default = i, lt;
}
var ft, b0;
function bn() {
  if (b0) return ft;
  b0 = 1;
  let { dirname: e, relative: u, resolve: t, sep: s } = ge, { SourceMapConsumer: a, SourceMapGenerator: r } = ge, { pathToFileURL: o } = ge, i = Bu(), c = !!(a && r), n = !!(e && t && u && s);
  class l {
    constructor(A, d, h, y) {
      this.stringify = A, this.mapOpts = h.map || {}, this.root = d, this.opts = h, this.css = y, this.originalCSS = y, this.usesFileUrls = !this.mapOpts.from && this.mapOpts.absolute, this.memoizedFileURLs = /* @__PURE__ */ new Map(), this.memoizedPaths = /* @__PURE__ */ new Map(), this.memoizedURLs = /* @__PURE__ */ new Map();
    }
    addAnnotation() {
      let A;
      this.isInline() ? A = "data:application/json;base64," + this.toBase64(this.map.toString()) : typeof this.mapOpts.annotation == "string" ? A = this.mapOpts.annotation : typeof this.mapOpts.annotation == "function" ? A = this.mapOpts.annotation(this.opts.to, this.root) : A = this.outputFile() + ".map";
      let d = `
`;
      this.css.includes(`\r
`) && (d = `\r
`), this.css += d + "/*# sourceMappingURL=" + A + " */";
    }
    applyPrevMaps() {
      for (let A of this.previous()) {
        let d = this.toUrl(this.path(A.file)), h = A.root || e(A.file), y;
        this.mapOpts.sourcesContent === !1 ? (y = new a(A.text), y.sourcesContent && (y.sourcesContent = null)) : y = A.consumer(), this.map.applySourceMap(y, d, this.toUrl(this.path(h)));
      }
    }
    clearAnnotation() {
      if (this.mapOpts.annotation !== !1) {
        if (this.root) {
          let A;
          for (let d = this.root.nodes.length - 1; d >= 0; d--)
            A = this.root.nodes[d], A.type === "comment" && A.text.startsWith("# sourceMappingURL=") && this.root.removeChild(d);
        } else if (this.css) {
          let A;
          for (; (A = this.css.lastIndexOf("/*#")) !== -1; ) {
            let d = this.css.indexOf("*/", A + 3);
            if (d === -1) break;
            for (; A > 0 && this.css[A - 1] === `
`; )
              A--;
            this.css = this.css.slice(0, A) + this.css.slice(d + 2);
          }
        }
      }
    }
    generate() {
      if (this.clearAnnotation(), n && c && this.isMap())
        return this.generateMap();
      {
        let A = "";
        return this.stringify(this.root, (d) => {
          A += d;
        }), [A];
      }
    }
    generateMap() {
      if (this.root)
        this.generateString();
      else if (this.previous().length === 1) {
        let A = this.previous()[0].consumer();
        A.file = this.outputFile(), this.map = r.fromSourceMap(A, {
          ignoreInvalidMapping: !0
        });
      } else
        this.map = new r({
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
      this.css = "", this.map = new r({
        file: this.outputFile(),
        ignoreInvalidMapping: !0
      });
      let A = 1, d = 1, h = "<no source>", y = {
        generated: { column: 0, line: 0 },
        original: { column: 0, line: 0 },
        source: ""
      }, C, w;
      this.stringify(this.root, (b, x, m) => {
        if (this.css += b, x && m !== "end" && (y.generated.line = A, y.generated.column = d - 1, x.source && x.source.start ? (y.source = this.sourcePath(x), y.original.line = x.source.start.line, y.original.column = x.source.start.column - 1, this.map.addMapping(y)) : (y.source = h, y.original.line = 1, y.original.column = 0, this.map.addMapping(y))), w = b.match(/\n/g), w ? (A += w.length, C = b.lastIndexOf(`
`), d = b.length - C) : d += b.length, x && m !== "start") {
          let p = x.parent || { raws: {} };
          (!(x.type === "decl" || x.type === "atrule" && !x.nodes) || x !== p.last || p.raws.semicolon) && (x.source && x.source.end ? (y.source = this.sourcePath(x), y.original.line = x.source.end.line, y.original.column = x.source.end.column - 1, y.generated.line = A, y.generated.column = d - 2, this.map.addMapping(y)) : (y.source = h, y.original.line = 1, y.original.column = 0, y.generated.line = A, y.generated.column = d - 1, this.map.addMapping(y)));
        }
      });
    }
    isAnnotation() {
      return this.isInline() ? !0 : typeof this.mapOpts.annotation < "u" ? this.mapOpts.annotation : this.previous().length ? this.previous().some((A) => A.annotation) : !0;
    }
    isInline() {
      if (typeof this.mapOpts.inline < "u")
        return this.mapOpts.inline;
      let A = this.mapOpts.annotation;
      return typeof A < "u" && A !== !0 ? !1 : this.previous().length ? this.previous().some((d) => d.inline) : !0;
    }
    isMap() {
      return typeof this.opts.map < "u" ? !!this.opts.map : this.previous().length > 0;
    }
    isSourcesContent() {
      return typeof this.mapOpts.sourcesContent < "u" ? this.mapOpts.sourcesContent : this.previous().length ? this.previous().some((A) => A.withContent()) : !0;
    }
    outputFile() {
      return this.opts.to ? this.path(this.opts.to) : this.opts.from ? this.path(this.opts.from) : "to.css";
    }
    path(A) {
      if (this.mapOpts.absolute || A.charCodeAt(0) === 60 || /^\w+:\/\//.test(A)) return A;
      let d = this.memoizedPaths.get(A);
      if (d) return d;
      let h = this.opts.to ? e(this.opts.to) : ".";
      typeof this.mapOpts.annotation == "string" && (h = e(t(h, this.mapOpts.annotation)));
      let y = u(h, A);
      return this.memoizedPaths.set(A, y), y;
    }
    previous() {
      if (!this.previousMaps)
        if (this.previousMaps = [], this.root)
          this.root.walk((A) => {
            if (A.source && A.source.input.map) {
              let d = A.source.input.map;
              this.previousMaps.includes(d) || this.previousMaps.push(d);
            }
          });
        else {
          let A = new i(this.originalCSS, this.opts);
          A.map && this.previousMaps.push(A.map);
        }
      return this.previousMaps;
    }
    setSourcesContent() {
      let A = {};
      if (this.root)
        this.root.walk((d) => {
          if (d.source) {
            let h = d.source.input.from;
            if (h && !A[h]) {
              A[h] = !0;
              let y = this.usesFileUrls ? this.toFileUrl(h) : this.toUrl(this.path(h));
              this.map.setSourceContent(y, d.source.input.css);
            }
          }
        });
      else if (this.css) {
        let d = this.opts.from ? this.toUrl(this.path(this.opts.from)) : "<no source>";
        this.map.setSourceContent(d, this.css);
      }
    }
    sourcePath(A) {
      return this.mapOpts.from ? this.toUrl(this.mapOpts.from) : this.usesFileUrls ? this.toFileUrl(A.source.input.from) : this.toUrl(this.path(A.source.input.from));
    }
    toBase64(A) {
      return Buffer ? Buffer.from(A).toString("base64") : window.btoa(unescape(encodeURIComponent(A)));
    }
    toFileUrl(A) {
      let d = this.memoizedFileURLs.get(A);
      if (d) return d;
      if (o) {
        let h = o(A).toString();
        return this.memoizedFileURLs.set(A, h), h;
      } else
        throw new Error(
          "`map.absolute` option is not available in this PostCSS build"
        );
    }
    toUrl(A) {
      let d = this.memoizedURLs.get(A);
      if (d) return d;
      s === "\\" && (A = A.replace(/\\/g, "/"));
      let h = encodeURI(A).replace(/[#?]/g, encodeURIComponent);
      return this.memoizedURLs.set(A, h), h;
    }
  }
  return ft = l, ft;
}
var dt, p0;
function rc() {
  if (p0) return dt;
  p0 = 1;
  const e = 39, u = 34, t = 92, s = 47, a = 10, r = 32, o = 12, i = 9, c = 13, n = 91, l = 93, f = 40, A = 41, d = 123, h = 125, y = 59, C = 42, w = 58, b = 64, x = /[\t\n\f\r "#'()/;[\\\]{}]/g, m = /[\t\n\f\r !"#'():;@[\\\]{}]|\/(?=\*)/g, p = /.[\r\n"'(/\\]/, g = /[\da-f]/i;
  return dt = function(B, E = {}) {
    let _ = B.css.valueOf(), v = E.ignoreErrors, k, S, F, I, T, M, N, P, G, H, U = _.length, L = 0, z = [], Z = [], ae = -1;
    function se() {
      return L;
    }
    function le(R) {
      throw B.error("Unclosed " + R, L);
    }
    function fe() {
      return Z.length === 0 && L >= U;
    }
    function X(R) {
      if (Z.length) return Z.pop();
      if (L >= U) return;
      let Q = R ? R.ignoreUnclosed : !1;
      switch (k = _.charCodeAt(L), k) {
        case a:
        case r:
        case i:
        case c:
        case o: {
          I = L;
          do
            I += 1, k = _.charCodeAt(I);
          while (k === r || k === a || k === i || k === c || k === o);
          M = ["space", _.slice(L, I)], L = I - 1;
          break;
        }
        case n:
        case l:
        case d:
        case h:
        case w:
        case y:
        case A: {
          let O = String.fromCharCode(k);
          M = [O, O, L];
          break;
        }
        case f: {
          if (H = z.length ? z.pop()[1] : "", G = _.charCodeAt(L + 1), H === "url" && G !== e && G !== u && G !== r && G !== a && G !== i && G !== o && G !== c) {
            I = L;
            do {
              if (N = !1, I = _.indexOf(")", I + 1), I === -1)
                if (v || Q) {
                  I = L;
                  break;
                } else
                  le("bracket");
              for (P = I; _.charCodeAt(P - 1) === t; )
                P -= 1, N = !N;
            } while (N);
            M = ["brackets", _.slice(L, I + 1), L, I], L = I;
          } else L <= ae ? M = ["(", "(", L] : (I = _.indexOf(")", L + 1), S = _.slice(L, I + 1), I === -1 || p.test(S) ? (ae = I === -1 ? U : I, M = ["(", "(", L]) : (M = ["brackets", S, L, I], L = I));
          break;
        }
        case e:
        case u: {
          T = k === e ? "'" : '"', I = L;
          do {
            if (N = !1, I = _.indexOf(T, I + 1), I === -1)
              if (v || Q) {
                I = L + 1;
                break;
              } else
                le("string");
            for (P = I; _.charCodeAt(P - 1) === t; )
              P -= 1, N = !N;
          } while (N);
          M = ["string", _.slice(L, I + 1), L, I], L = I;
          break;
        }
        case b: {
          x.lastIndex = L + 1, x.test(_), x.lastIndex === 0 ? I = _.length - 1 : I = x.lastIndex - 2, M = ["at-word", _.slice(L, I + 1), L, I], L = I;
          break;
        }
        case t: {
          for (I = L, F = !0; _.charCodeAt(I + 1) === t; )
            I += 1, F = !F;
          if (k = _.charCodeAt(I + 1), F && k !== s && k !== r && k !== a && k !== i && k !== c && k !== o && (I += 1, g.test(_.charAt(I)))) {
            for (; g.test(_.charAt(I + 1)); )
              I += 1;
            _.charCodeAt(I + 1) === r && (I += 1);
          }
          M = ["word", _.slice(L, I + 1), L, I], L = I;
          break;
        }
        default: {
          k === s && _.charCodeAt(L + 1) === C ? (I = _.indexOf("*/", L + 2) + 1, I === 0 && (v || Q ? I = _.length : le("comment")), M = ["comment", _.slice(L, I + 1), L, I], L = I) : (m.lastIndex = L + 1, m.test(_), m.lastIndex === 0 ? I = _.length - 1 : I = m.lastIndex - 2, M = ["word", _.slice(L, I + 1), L, I], z.push(M), L = I);
          break;
        }
      }
      return L++, M;
    }
    function re(R) {
      Z.push(R);
    }
    return {
      back: re,
      endOfFile: fe,
      nextToken: X,
      position: se
    };
  }, dt;
}
var At, g0;
function nc() {
  if (g0) return At;
  g0 = 1;
  let e = Qt(), u = Iu(), t = ku(), s = ru(), a = Pt(), r = rc();
  const o = {
    empty: !0,
    space: !0
  };
  function i(l) {
    for (let f = l.length - 1; f >= 0; f--) {
      let A = l[f], d = A[3] || A[2];
      if (d) return d;
    }
  }
  function c(l, f, A) {
    let d = "";
    for (let h = f; h < A; h++) d += l[h][1];
    return d;
  }
  class n {
    constructor(f) {
      this.input = f, this.root = new s(), this.current = this.root, this.spaces = "", this.semicolon = !1, this.createTokenizer(), this.root.source = { input: f, start: { column: 1, line: 1, offset: 0 } };
    }
    atrule(f) {
      let A = new e();
      A.name = f[1].slice(1), A.name === "" && this.unnamedAtrule(A, f), this.init(A, f[2]);
      let d, h, y, C = !1, w = !1, b = [], x = [];
      for (; !this.tokenizer.endOfFile(); ) {
        if (f = this.tokenizer.nextToken(), d = f[0], d === "(" || d === "[" ? x.push(d === "(" ? ")" : "]") : d === "{" && x.length > 0 ? x.push("}") : d === x[x.length - 1] && x.pop(), x.length === 0)
          if (d === ";") {
            A.source.end = this.getPosition(f[2]), A.source.end.offset++, this.semicolon = !0;
            break;
          } else if (d === "{") {
            w = !0;
            break;
          } else if (d === "}") {
            if (b.length > 0) {
              for (y = b.length - 1, h = b[y]; h && h[0] === "space"; )
                h = b[--y];
              h && (A.source.end = this.getPosition(h[3] || h[2]), A.source.end.offset++);
            }
            this.end(f);
            break;
          } else
            b.push(f);
        else
          b.push(f);
        if (this.tokenizer.endOfFile()) {
          C = !0;
          break;
        }
      }
      A.raws.between = this.spacesAndCommentsFromEnd(b), b.length ? (A.raws.afterName = this.spacesAndCommentsFromStart(b), this.raw(A, "params", b), C && (f = b[b.length - 1], A.source.end = this.getPosition(f[3] || f[2]), A.source.end.offset++, this.spaces = A.raws.between, A.raws.between = "")) : (A.raws.afterName = "", A.params = ""), w && (A.nodes = [], this.current = A);
    }
    checkMissedSemicolon(f) {
      let A = this.colon(f);
      if (A === !1) return;
      let d = 0, h;
      for (let y = A - 1; y >= 0 && (h = f[y], !(h[0] !== "space" && (d += 1, d === 2))); y--)
        ;
      throw this.input.error(
        "Missed semicolon",
        h[0] === "word" ? h[3] + 1 : h[2]
      );
    }
    colon(f) {
      let A = 0, d, h, y;
      for (let [C, w] of f.entries()) {
        if (h = w, y = h[0], y === "(" && (A += 1), y === ")" && (A -= 1), A === 0 && y === ":")
          if (!d)
            this.doubleColon(h);
          else {
            if (d[0] === "word" && d[1] === "progid")
              continue;
            return C;
          }
        d = h;
      }
      return !1;
    }
    comment(f) {
      let A = new u();
      this.init(A, f[2]), A.source.end = this.getPosition(f[3] || f[2]), A.source.end.offset++;
      let d = f[1].slice(2, -2);
      if (!d.trim())
        A.text = "", A.raws.left = d, A.raws.right = "";
      else {
        let h = d.match(/^(\s*)([^]*\S)(\s*)$/);
        A.text = h[2], A.raws.left = h[1], A.raws.right = h[3];
      }
    }
    createTokenizer() {
      this.tokenizer = r(this.input);
    }
    decl(f, A) {
      let d = new t();
      this.init(d, f[0][2]);
      let h = f[f.length - 1];
      h[0] === ";" && (this.semicolon = !0, f.pop()), d.source.end = this.getPosition(
        h[3] || h[2] || i(f)
      ), d.source.end.offset++;
      let y = 0;
      for (; f[y][0] !== "word"; )
        y === f.length - 1 && this.unknownWord([f[y]]), y++;
      d.raws.before += c(f, 0, y), d.source.start = this.getPosition(f[y][2]);
      let C = y;
      for (; y < f.length; ) {
        let g = f[y][0];
        if (g === ":" || g === "space" || g === "comment")
          break;
        y++;
      }
      d.prop = c(f, C, y);
      let w = y, b;
      for (; y < f.length && (b = f[y], y++, b[0] !== ":"); )
        b[0] === "word" && /\w/.test(b[1]) && this.unknownWord([b]);
      d.raws.between = c(f, w, y), (d.prop[0] === "_" || d.prop[0] === "*") && (d.raws.before += d.prop[0], d.prop = d.prop.slice(1));
      let x = y;
      for (; y < f.length; ) {
        let g = f[y][0];
        if (g !== "space" && g !== "comment") break;
        y++;
      }
      let m = f.slice(x, y);
      f = f.slice(y), this.precheckMissedSemicolon(f);
      for (let g = f.length - 1; g >= 0; g--) {
        if (b = f[g], b[1].toLowerCase() === "!important") {
          d.important = !0;
          let D = this.stringFrom(f, g);
          D = this.spacesFromEnd(f) + D, D !== " !important" && (d.raws.important = D);
          break;
        } else if (b[1].toLowerCase() === "important") {
          let D = f.slice(0), B = "";
          for (let E = g; E > 0; E--) {
            let _ = D[E][0];
            if (B.trim().startsWith("!") && _ !== "space")
              break;
            B = D.pop()[1] + B;
          }
          B.trim().startsWith("!") && (d.important = !0, d.raws.important = B, f = D);
        }
        if (b[0] !== "space" && b[0] !== "comment")
          break;
      }
      f.some((g) => g[0] !== "space" && g[0] !== "comment") && (d.raws.between += m.map((g) => g[1]).join(""), m = []), this.raw(d, "value", m.concat(f), A), d.value.includes(":") && !A && this.checkMissedSemicolon(f);
    }
    doubleColon(f) {
      throw this.input.error(
        "Double colon",
        { offset: f[2] },
        { offset: f[2] + f[1].length }
      );
    }
    emptyRule(f) {
      let A = new a();
      this.init(A, f[2]), A.selector = "", A.raws.between = "", this.current = A;
    }
    end(f) {
      this.current.nodes && this.current.nodes.length && (this.current.raws.semicolon = this.semicolon), this.semicolon = !1, this.current.raws.after = (this.current.raws.after || "") + this.spaces, this.spaces = "", this.current.parent ? (this.current.source.end = this.getPosition(f[2]), this.current.source.end.offset++, this.current = this.current.parent) : this.unexpectedClose(f);
    }
    endFile() {
      this.current.parent && this.unclosedBlock(), this.current.nodes && this.current.nodes.length && (this.current.raws.semicolon = this.semicolon), this.current.raws.after = (this.current.raws.after || "") + this.spaces, this.root.source.end = this.getPosition(this.tokenizer.position());
    }
    freeSemicolon(f) {
      if (this.spaces += f[1], this.current.nodes) {
        let A = this.current.nodes[this.current.nodes.length - 1];
        A && A.type === "rule" && !A.raws.ownSemicolon && (A.raws.ownSemicolon = this.spaces, this.spaces = "", A.source.end = this.getPosition(f[2]), A.source.end.offset += A.raws.ownSemicolon.length);
      }
    }
    // Helpers
    getPosition(f) {
      let A = this.input.fromOffset(f);
      return {
        column: A.col,
        line: A.line,
        offset: f
      };
    }
    init(f, A) {
      this.current.push(f), f.source = {
        input: this.input,
        start: this.getPosition(A)
      }, f.raws.before = this.spaces, this.spaces = "", f.type !== "comment" && (this.semicolon = !1);
    }
    other(f) {
      let A = !1, d = null, h = !1, y = null, C = [], w = f[1].startsWith("--"), b = [], x = f;
      for (; x; ) {
        if (d = x[0], b.push(x), d === "(" || d === "[")
          y || (y = x), C.push(d === "(" ? ")" : "]");
        else if (w && h && d === "{")
          y || (y = x), C.push("}");
        else if (C.length === 0)
          if (d === ";")
            if (h) {
              this.decl(b, w);
              return;
            } else
              break;
          else if (d === "{") {
            this.rule(b);
            return;
          } else if (d === "}") {
            this.tokenizer.back(b.pop()), A = !0;
            break;
          } else d === ":" && (h = !0);
        else d === C[C.length - 1] && (C.pop(), C.length === 0 && (y = null));
        x = this.tokenizer.nextToken();
      }
      if (this.tokenizer.endOfFile() && (A = !0), C.length > 0 && this.unclosedBracket(y), A && h) {
        if (!w)
          for (; b.length && (x = b[b.length - 1][0], !(x !== "space" && x !== "comment")); )
            this.tokenizer.back(b.pop());
        this.decl(b, w);
      } else
        this.unknownWord(b);
    }
    parse() {
      let f;
      for (; !this.tokenizer.endOfFile(); )
        switch (f = this.tokenizer.nextToken(), f[0]) {
          case "space":
            this.spaces += f[1];
            break;
          case ";":
            this.freeSemicolon(f);
            break;
          case "}":
            this.end(f);
            break;
          case "comment":
            this.comment(f);
            break;
          case "at-word":
            this.atrule(f);
            break;
          case "{":
            this.emptyRule(f);
            break;
          default:
            this.other(f);
            break;
        }
      this.endFile();
    }
    precheckMissedSemicolon() {
    }
    raw(f, A, d, h) {
      let y, C, w = d.length, b = "", x = !0, m, p;
      for (let g = 0; g < w; g += 1)
        y = d[g], C = y[0], C === "space" && g === w - 1 && !h ? x = !1 : C === "comment" ? (p = d[g - 1] ? d[g - 1][0] : "empty", m = d[g + 1] ? d[g + 1][0] : "empty", !o[p] && !o[m] ? b.slice(-1) === "," ? x = !1 : b += y[1] : x = !1) : b += y[1];
      if (!x) {
        let g = d.reduce((D, B) => D + B[1], "");
        f.raws[A] = { raw: g, value: b };
      }
      f[A] = b;
    }
    rule(f) {
      f.pop();
      let A = new a();
      this.init(A, f[0][2]), A.raws.between = this.spacesAndCommentsFromEnd(f), this.raw(A, "selector", f), this.current = A;
    }
    spacesAndCommentsFromEnd(f) {
      let A, d = "";
      for (; f.length && (A = f[f.length - 1][0], !(A !== "space" && A !== "comment")); )
        d = f.pop()[1] + d;
      return d;
    }
    // Errors
    spacesAndCommentsFromStart(f) {
      let A, d = "";
      for (; f.length && (A = f[0][0], !(A !== "space" && A !== "comment")); )
        d += f.shift()[1];
      return d;
    }
    spacesFromEnd(f) {
      let A, d = "";
      for (; f.length && (A = f[f.length - 1][0], A === "space"); )
        d = f.pop()[1] + d;
      return d;
    }
    stringFrom(f, A) {
      let d = "";
      for (let h = A; h < f.length; h++)
        d += f[h][1];
      return f.splice(A, f.length - A), d;
    }
    unclosedBlock() {
      let f = this.current.source.start;
      throw this.input.error("Unclosed block", f.line, f.column);
    }
    unclosedBracket(f) {
      throw this.input.error(
        "Unclosed bracket",
        { offset: f[2] },
        { offset: f[2] + 1 }
      );
    }
    unexpectedClose(f) {
      throw this.input.error(
        "Unexpected }",
        { offset: f[2] },
        { offset: f[2] + 1 }
      );
    }
    unknownWord(f) {
      throw this.input.error(
        "Unknown word " + f[0][1],
        { offset: f[0][2] },
        { offset: f[0][2] + f[0][1].length }
      );
    }
    unnamedAtrule(f, A) {
      throw this.input.error(
        "At-rule without name",
        { offset: A[2] },
        { offset: A[2] + A[1].length }
      );
    }
  }
  return At = n, At;
}
var ht, m0;
function Gt() {
  if (m0) return ht;
  m0 = 1;
  let e = Pe(), u = Bu(), t = nc();
  function s(a, r) {
    let o = new u(a, r), i = new t(o);
    try {
      i.parse();
    } catch (c) {
      throw process.env.NODE_ENV !== "production" && c.name === "CssSyntaxError" && r && r.from && (/\.scss$/i.test(r.from) ? c.message += `
You tried to parse SCSS with the standard CSS parser; try again with the postcss-scss parser` : /\.sass/i.test(r.from) ? c.message += `
You tried to parse Sass with the standard CSS parser; try again with the postcss-sass parser` : /\.less$/i.test(r.from) && (c.message += `
You tried to parse Less with the standard CSS parser; try again with the postcss-less parser`)), c;
    }
    return i.root;
  }
  return ht = s, s.default = s, e.registerParse(s), ht;
}
var bt, x0;
function pn() {
  if (x0) return bt;
  x0 = 1;
  class e {
    constructor(t, s = {}) {
      if (this.type = "warning", this.text = t, s.node && s.node.source) {
        let a = s.node.rangeBy(s);
        this.line = a.start.line, this.column = a.start.column, this.endLine = a.end.line, this.endColumn = a.end.column;
      }
      for (let a in s) this[a] = s[a];
    }
    toString() {
      return this.node ? this.node.error(this.text, {
        index: this.index,
        plugin: this.plugin,
        word: this.word
      }).message : this.plugin ? this.plugin + ": " + this.text : this.text;
    }
  }
  return bt = e, e.default = e, bt;
}
var pt, y0;
function Ht() {
  if (y0) return pt;
  y0 = 1;
  let e = pn();
  class u {
    get content() {
      return this.css;
    }
    constructor(s, a, r) {
      this.processor = s, this.messages = [], this.root = a, this.opts = r, this.css = "", this.map = void 0;
    }
    toString() {
      return this.css;
    }
    warn(s, a = {}) {
      a.plugin || this.lastPlugin && this.lastPlugin.postcssPlugin && (a.plugin = this.lastPlugin.postcssPlugin);
      let r = new e(s, a);
      return this.messages.push(r), r;
    }
    warnings() {
      return this.messages.filter((s) => s.type === "warning");
    }
  }
  return pt = u, u.default = u, pt;
}
var gt, w0;
function gn() {
  if (w0) return gt;
  w0 = 1;
  let e = {};
  return gt = function(t) {
    e[t] || (e[t] = !0, typeof console < "u" && console.warn && console.warn(t));
  }, gt;
}
var mt, C0;
function mn() {
  if (C0) return mt;
  C0 = 1;
  let e = Pe(), u = Lt(), t = bn(), s = Gt(), a = Ht(), r = ru(), o = Eu(), { isClean: i, my: c } = Ot(), n = gn();
  const l = {
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
  }, A = {
    Once: !0,
    postcssPlugin: !0,
    prepare: !0
  }, d = 0;
  function h(m) {
    return typeof m == "object" && typeof m.then == "function";
  }
  function y(m) {
    let p = !1, g = l[m.type];
    return m.type === "decl" ? p = m.prop.toLowerCase() : m.type === "atrule" && (p = m.name.toLowerCase()), p && m.append ? [
      g,
      g + "-" + p,
      d,
      g + "Exit",
      g + "Exit-" + p
    ] : p ? [g, g + "-" + p, g + "Exit", g + "Exit-" + p] : m.append ? [g, d, g + "Exit"] : [g, g + "Exit"];
  }
  function C(m) {
    let p;
    return m.type === "document" ? p = ["Document", d, "DocumentExit"] : m.type === "root" ? p = ["Root", d, "RootExit"] : p = y(m), {
      eventIndex: 0,
      events: p,
      iterator: 0,
      node: m,
      visitorIndex: 0,
      visitors: []
    };
  }
  function w(m) {
    return m[i] = !1, m.nodes && m.nodes.forEach((p) => w(p)), m;
  }
  let b = {};
  class x {
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
    constructor(p, g, D) {
      this.stringified = !1, this.processed = !1;
      let B;
      if (typeof g == "object" && g !== null && (g.type === "root" || g.type === "document"))
        B = w(g);
      else if (g instanceof x || g instanceof a)
        B = w(g.root), g.map && (typeof D.map > "u" && (D.map = {}), D.map.inline || (D.map.inline = !1), D.map.prev = g.map);
      else {
        let E = s;
        D.syntax && (E = D.syntax.parse), D.parser && (E = D.parser), E.parse && (E = E.parse);
        try {
          B = E(g, D);
        } catch (_) {
          this.processed = !0, this.error = _;
        }
        B && !B[c] && e.rebuild(B);
      }
      this.result = new a(p, B, D), this.helpers = { ...b, postcss: b, result: this.result }, this.plugins = this.processor.plugins.map((E) => typeof E == "object" && E.prepare ? { ...E, ...E.prepare(this.result) } : E);
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
    handleError(p, g) {
      let D = this.result.lastPlugin;
      try {
        if (g && g.addToError(p), this.error = p, p.name === "CssSyntaxError" && !p.plugin)
          p.plugin = D.postcssPlugin, p.setMessage();
        else if (D.postcssVersion && process.env.NODE_ENV !== "production") {
          let B = D.postcssPlugin, E = D.postcssVersion, _ = this.result.processor.version, v = E.split("."), k = _.split(".");
          (v[0] !== k[0] || parseInt(v[1]) > parseInt(k[1])) && console.error(
            "Unknown error from PostCSS plugin. Your current PostCSS version is " + _ + ", but " + B + " uses " + E + ". Perhaps this is the source of the error below."
          );
        }
      } catch (B) {
        console && console.error && console.error(B);
      }
      return p;
    }
    prepareVisitors() {
      this.listeners = {};
      let p = (g, D, B) => {
        this.listeners[D] || (this.listeners[D] = []), this.listeners[D].push([g, B]);
      };
      for (let g of this.plugins)
        if (typeof g == "object")
          for (let D in g) {
            if (!f[D] && /^[A-Z]/.test(D))
              throw new Error(
                `Unknown event ${D} in ${g.postcssPlugin}. Try to update PostCSS (${this.processor.version} now).`
              );
            if (!A[D])
              if (typeof g[D] == "object")
                for (let B in g[D])
                  B === "*" ? p(g, D, g[D][B]) : p(
                    g,
                    D + "-" + B.toLowerCase(),
                    g[D][B]
                  );
              else typeof g[D] == "function" && p(g, D, g[D]);
          }
      this.hasListener = Object.keys(this.listeners).length > 0;
    }
    async runAsync() {
      this.plugin = 0;
      for (let p = 0; p < this.plugins.length; p++) {
        let g = this.plugins[p], D = this.runOnRoot(g);
        if (h(D))
          try {
            await D;
          } catch (B) {
            throw this.handleError(B);
          }
      }
      if (this.prepareVisitors(), this.hasListener) {
        let p = this.result.root;
        for (; !p[i]; ) {
          p[i] = !0;
          let g = [C(p)];
          for (; g.length > 0; ) {
            let D = this.visitTick(g);
            if (h(D))
              try {
                await D;
              } catch (B) {
                let E = g[g.length - 1].node;
                throw this.handleError(B, E);
              }
          }
        }
        if (this.listeners.OnceExit)
          for (let [g, D] of this.listeners.OnceExit) {
            this.result.lastPlugin = g;
            try {
              if (p.type === "document") {
                let B = p.nodes.map(
                  (E) => D(E, this.helpers)
                );
                await Promise.all(B);
              } else
                await D(p, this.helpers);
            } catch (B) {
              throw this.handleError(B);
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
            let g = this.result.root.nodes.map(
              (D) => p.Once(D, this.helpers)
            );
            return h(g[0]) ? Promise.all(g) : g;
          }
          return p.Once(this.result.root, this.helpers);
        } else if (typeof p == "function")
          return p(this.result.root, this.result);
      } catch (g) {
        throw this.handleError(g);
      }
    }
    stringify() {
      if (this.error) throw this.error;
      if (this.stringified) return this.result;
      this.stringified = !0, this.sync();
      let p = this.result.opts, g = o;
      p.syntax && (g = p.syntax.stringify), p.stringifier && (g = p.stringifier), g.stringify && (g = g.stringify);
      let D = this.result.root.source;
      if (p.map === void 0 && !(D && D.input && D.input.map)) {
        let _ = "";
        return g(this.result.root, (v) => {
          _ += v;
        }), this.result.css = _, this.result;
      }
      let E = new t(g, this.result.root, this.result.opts).generate();
      return this.result.css = E[0], this.result.map = E[1], this.result;
    }
    sync() {
      if (this.error) throw this.error;
      if (this.processed) return this.result;
      if (this.processed = !0, this.processing)
        throw this.getAsyncError();
      for (let p of this.plugins) {
        let g = this.runOnRoot(p);
        if (h(g))
          throw this.getAsyncError();
      }
      if (this.prepareVisitors(), this.hasListener) {
        let p = this.result.root;
        for (; !p[i]; )
          p[i] = !0, this.walkSync(p);
        if (this.listeners.OnceExit)
          if (p.type === "document")
            for (let g of p.nodes)
              this.visitSync(this.listeners.OnceExit, g);
          else
            this.visitSync(this.listeners.OnceExit, p);
      }
      return this.result;
    }
    then(p, g) {
      return process.env.NODE_ENV !== "production" && ("from" in this.opts || n(
        "Without `from` option PostCSS could generate wrong source map and will not find Browserslist config. Set it to CSS file path or to `undefined` to prevent this warning."
      )), this.async().then(p, g);
    }
    toString() {
      return this.css;
    }
    visitSync(p, g) {
      for (let [D, B] of p) {
        this.result.lastPlugin = D;
        let E;
        try {
          E = B(g, this.helpers);
        } catch (_) {
          throw this.handleError(_, g.proxyOf);
        }
        if (g.type !== "root" && g.type !== "document" && !g.parent)
          return !0;
        if (h(E))
          throw this.getAsyncError();
      }
    }
    visitTick(p) {
      let g = p[p.length - 1], { node: D, visitors: B } = g;
      if (D.type !== "root" && D.type !== "document" && !D.parent) {
        p.pop();
        return;
      }
      if (B.length > 0 && g.visitorIndex < B.length) {
        let [_, v] = B[g.visitorIndex];
        g.visitorIndex += 1, g.visitorIndex === B.length && (g.visitors = [], g.visitorIndex = 0), this.result.lastPlugin = _;
        try {
          return v(D.toProxy(), this.helpers);
        } catch (k) {
          throw this.handleError(k, D);
        }
      }
      if (g.iterator !== 0) {
        let _ = g.iterator, v;
        for (; v = D.nodes[D.indexes[_]]; )
          if (D.indexes[_] += 1, !v[i]) {
            v[i] = !0, p.push(C(v));
            return;
          }
        g.iterator = 0, delete D.indexes[_];
      }
      let E = g.events;
      for (; g.eventIndex < E.length; ) {
        let _ = E[g.eventIndex];
        if (g.eventIndex += 1, _ === d) {
          D.nodes && D.nodes.length && (D[i] = !0, g.iterator = D.getIterator());
          return;
        } else if (this.listeners[_]) {
          g.visitors = this.listeners[_];
          return;
        }
      }
      p.pop();
    }
    walkSync(p) {
      p[i] = !0;
      let g = y(p);
      for (let D of g)
        if (D === d)
          p.nodes && p.each((B) => {
            B[i] || this.walkSync(B);
          });
        else {
          let B = this.listeners[D];
          if (B && this.visitSync(B, p.toProxy()))
            return;
        }
    }
    warnings() {
      return this.sync().warnings();
    }
  }
  return x.registerPostcss = (m) => {
    b = m;
  }, mt = x, x.default = x, r.registerLazyResult(x), u.registerLazyResult(x), mt;
}
var xt, v0;
function ic() {
  if (v0) return xt;
  v0 = 1;
  let e = bn(), u = Gt(), t = Ht(), s = Eu(), a = gn();
  class r {
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
      let i, c = u;
      try {
        i = c(this._css, this._opts);
      } catch (n) {
        this.error = n;
      }
      if (this.error)
        throw this.error;
      return this._root = i, i;
    }
    get [Symbol.toStringTag]() {
      return "NoWorkResult";
    }
    constructor(i, c, n) {
      c = c.toString(), this.stringified = !1, this._processor = i, this._css = c, this._opts = n, this._map = void 0;
      let l = s;
      this.result = new t(this._processor, void 0, this._opts), this.result.css = c;
      let f = this;
      Object.defineProperty(this.result, "root", {
        get() {
          return f.root;
        }
      });
      let A = new e(l, void 0, this._opts, c);
      if (A.isMap()) {
        let [d, h] = A.generate();
        d && (this.result.css = d), h && (this.result.map = h);
      } else
        A.clearAnnotation(), this.result.css = A.css;
    }
    async() {
      return this.error ? Promise.reject(this.error) : Promise.resolve(this.result);
    }
    catch(i) {
      return this.async().catch(i);
    }
    finally(i) {
      return this.async().then(i, i);
    }
    sync() {
      if (this.error) throw this.error;
      return this.result;
    }
    then(i, c) {
      return process.env.NODE_ENV !== "production" && ("from" in this._opts || a(
        "Without `from` option PostCSS could generate wrong source map and will not find Browserslist config. Set it to CSS file path or to `undefined` to prevent this warning."
      )), this.async().then(i, c);
    }
    toString() {
      return this._css;
    }
    warnings() {
      return [];
    }
  }
  return xt = r, r.default = r, xt;
}
var yt, D0;
function ac() {
  if (D0) return yt;
  D0 = 1;
  let e = Lt(), u = mn(), t = ic(), s = ru();
  class a {
    constructor(o = []) {
      this.version = "8.5.15", this.plugins = this.normalize(o);
    }
    normalize(o) {
      let i = [];
      for (let c of o)
        if (c.postcss === !0 ? c = c() : c.postcss && (c = c.postcss), typeof c == "object" && Array.isArray(c.plugins))
          i = i.concat(c.plugins);
        else if (typeof c == "object" && c.postcssPlugin)
          i.push(c);
        else if (typeof c == "function")
          i.push(c);
        else if (typeof c == "object" && (c.parse || c.stringify)) {
          if (process.env.NODE_ENV !== "production")
            throw new Error(
              "PostCSS syntaxes cannot be used as plugins. Instead, please use one of the syntax/parser/stringifier options as outlined in your PostCSS runner documentation."
            );
        } else
          throw new Error(c + " is not a PostCSS plugin");
      return i;
    }
    process(o, i = {}) {
      return !this.plugins.length && !i.parser && !i.stringifier && !i.syntax ? new t(this, o, i) : new u(this, o, i);
    }
    use(o) {
      return this.plugins = this.plugins.concat(this.normalize([o])), this;
    }
  }
  return yt = a, a.default = a, s.registerProcessor(a), e.registerProcessor(a), yt;
}
var wt, E0;
function sc() {
  if (E0) return wt;
  E0 = 1;
  let e = Qt(), u = Iu(), t = Pe(), s = Mt(), a = ku(), r = Lt(), o = tc(), i = Bu(), c = mn(), n = hn(), l = _u(), f = Gt(), A = ac(), d = Ht(), h = ru(), y = Pt(), C = Eu(), w = pn();
  function b(...x) {
    return x.length === 1 && Array.isArray(x[0]) && (x = x[0]), new A(x);
  }
  return b.plugin = function(m, p) {
    let g = !1;
    function D(...E) {
      console && console.warn && !g && (g = !0, console.warn(
        m + `: postcss.plugin was deprecated. Migration guide:
https://evilmartians.com/chronicles/postcss-8-plugin-migration`
      ), process.env.LANG && process.env.LANG.startsWith("cn") && console.warn(
        m + `: 里面 postcss.plugin 被弃用. 迁移指南:
https://www.w3ctech.com/topic/2226`
      ));
      let _ = p(...E);
      return _.postcssPlugin = m, _.postcssVersion = new A().version, _;
    }
    let B;
    return Object.defineProperty(D, "postcss", {
      get() {
        return B || (B = D()), B;
      }
    }), D.process = function(E, _, v) {
      return b([D(v)]).process(E, _);
    }, D;
  }, b.stringify = C, b.parse = f, b.fromJSON = o, b.list = n, b.comment = (x) => new u(x), b.atRule = (x) => new e(x), b.decl = (x) => new a(x), b.rule = (x) => new y(x), b.root = (x) => new h(x), b.document = (x) => new r(x), b.CssSyntaxError = s, b.Declaration = a, b.Container = t, b.Processor = A, b.Document = r, b.Comment = u, b.Warning = w, b.AtRule = e, b.Result = d, b.Input = i, b.Rule = y, b.Root = h, b.Node = l, c.registerPostcss(b), wt = b, b.default = b, wt;
}
var bu = { exports: {} }, gu = { exports: {} }, cc = gu.exports, _0;
function oc() {
  return _0 || (_0 = 1, (function(e, u) {
    (function(t, s) {
      e.exports = s();
    })(cc, (function() {
      var t = 1e3, s = 6e4, a = 36e5, r = "millisecond", o = "second", i = "minute", c = "hour", n = "day", l = "week", f = "month", A = "quarter", d = "year", h = "date", y = "Invalid Date", C = /^(\d{4})[-/]?(\d{1,2})?[-/]?(\d{0,2})[Tt\s]*(\d{1,2})?:?(\d{1,2})?:?(\d{1,2})?[.:]?(\d+)?$/, w = /\[([^\]]+)]|Y{1,4}|M{1,4}|D{1,2}|d{1,4}|H{1,2}|h{1,2}|a|A|m{1,2}|s{1,2}|Z{1,2}|SSS/g, b = { name: "en", weekdays: "Sunday_Monday_Tuesday_Wednesday_Thursday_Friday_Saturday".split("_"), months: "January_February_March_April_May_June_July_August_September_October_November_December".split("_"), ordinal: function(F) {
        var I = ["th", "st", "nd", "rd"], T = F % 100;
        return "[" + F + (I[(T - 20) % 10] || I[T] || I[0]) + "]";
      } }, x = function(F, I, T) {
        var M = String(F);
        return !M || M.length >= I ? F : "" + Array(I + 1 - M.length).join(T) + F;
      }, m = { s: x, z: function(F) {
        var I = -F.utcOffset(), T = Math.abs(I), M = Math.floor(T / 60), N = T % 60;
        return (I <= 0 ? "+" : "-") + x(M, 2, "0") + ":" + x(N, 2, "0");
      }, m: function F(I, T) {
        if (I.date() < T.date()) return -F(T, I);
        var M = 12 * (T.year() - I.year()) + (T.month() - I.month()), N = I.clone().add(M, f), P = T - N < 0, G = I.clone().add(M + (P ? -1 : 1), f);
        return +(-(M + (T - N) / (P ? N - G : G - N)) || 0);
      }, a: function(F) {
        return F < 0 ? Math.ceil(F) || 0 : Math.floor(F);
      }, p: function(F) {
        return { M: f, y: d, w: l, d: n, D: h, h: c, m: i, s: o, ms: r, Q: A }[F] || String(F || "").toLowerCase().replace(/s$/, "");
      }, u: function(F) {
        return F === void 0;
      } }, p = "en", g = {};
      g[p] = b;
      var D = "$isDayjsObject", B = function(F) {
        return F instanceof k || !(!F || !F[D]);
      }, E = function F(I, T, M) {
        var N;
        if (!I) return p;
        if (typeof I == "string") {
          var P = I.toLowerCase();
          g[P] && (N = P), T && (g[P] = T, N = P);
          var G = I.split("-");
          if (!N && G.length > 1) return F(G[0]);
        } else {
          var H = I.name;
          g[H] = I, N = H;
        }
        return !M && N && (p = N), N || !M && p;
      }, _ = function(F, I) {
        if (B(F)) return F.clone();
        var T = typeof I == "object" ? I : {};
        return T.date = F, T.args = arguments, new k(T);
      }, v = m;
      v.l = E, v.i = B, v.w = function(F, I) {
        return _(F, { locale: I.$L, utc: I.$u, x: I.$x, $offset: I.$offset });
      };
      var k = (function() {
        function F(T) {
          this.$L = E(T.locale, null, !0), this.parse(T), this.$x = this.$x || T.x || {}, this[D] = !0;
        }
        var I = F.prototype;
        return I.parse = function(T) {
          this.$d = (function(M) {
            var N = M.date, P = M.utc;
            if (N === null) return /* @__PURE__ */ new Date(NaN);
            if (v.u(N)) return /* @__PURE__ */ new Date();
            if (N instanceof Date) return new Date(N);
            if (typeof N == "string" && !/Z$/i.test(N)) {
              var G = N.match(C);
              if (G) {
                var H = G[2] - 1 || 0, U = (G[7] || "0").substring(0, 3);
                return P ? new Date(Date.UTC(G[1], H, G[3] || 1, G[4] || 0, G[5] || 0, G[6] || 0, U)) : new Date(G[1], H, G[3] || 1, G[4] || 0, G[5] || 0, G[6] || 0, U);
              }
            }
            return new Date(N);
          })(T), this.init();
        }, I.init = function() {
          var T = this.$d;
          this.$y = T.getFullYear(), this.$M = T.getMonth(), this.$D = T.getDate(), this.$W = T.getDay(), this.$H = T.getHours(), this.$m = T.getMinutes(), this.$s = T.getSeconds(), this.$ms = T.getMilliseconds();
        }, I.$utils = function() {
          return v;
        }, I.isValid = function() {
          return this.$d.toString() !== y;
        }, I.isSame = function(T, M) {
          var N = _(T);
          return this.startOf(M) <= N && N <= this.endOf(M);
        }, I.isAfter = function(T, M) {
          return _(T) < this.startOf(M);
        }, I.isBefore = function(T, M) {
          return this.endOf(M) < _(T);
        }, I.$g = function(T, M, N) {
          return v.u(T) ? this[M] : this.set(N, T);
        }, I.unix = function() {
          return Math.floor(this.valueOf() / 1e3);
        }, I.valueOf = function() {
          return this.$d.getTime();
        }, I.startOf = function(T, M) {
          var N = this, P = !!v.u(M) || M, G = v.p(T), H = function(fe, X) {
            var re = v.w(N.$u ? Date.UTC(N.$y, X, fe) : new Date(N.$y, X, fe), N);
            return P ? re : re.endOf(n);
          }, U = function(fe, X) {
            return v.w(N.toDate()[fe].apply(N.toDate("s"), (P ? [0, 0, 0, 0] : [23, 59, 59, 999]).slice(X)), N);
          }, L = this.$W, z = this.$M, Z = this.$D, ae = "set" + (this.$u ? "UTC" : "");
          switch (G) {
            case d:
              return P ? H(1, 0) : H(31, 11);
            case f:
              return P ? H(1, z) : H(0, z + 1);
            case l:
              var se = this.$locale().weekStart || 0, le = (L < se ? L + 7 : L) - se;
              return H(P ? Z - le : Z + (6 - le), z);
            case n:
            case h:
              return U(ae + "Hours", 0);
            case c:
              return U(ae + "Minutes", 1);
            case i:
              return U(ae + "Seconds", 2);
            case o:
              return U(ae + "Milliseconds", 3);
            default:
              return this.clone();
          }
        }, I.endOf = function(T) {
          return this.startOf(T, !1);
        }, I.$set = function(T, M) {
          var N, P = v.p(T), G = "set" + (this.$u ? "UTC" : ""), H = (N = {}, N[n] = G + "Date", N[h] = G + "Date", N[f] = G + "Month", N[d] = G + "FullYear", N[c] = G + "Hours", N[i] = G + "Minutes", N[o] = G + "Seconds", N[r] = G + "Milliseconds", N)[P], U = P === n ? this.$D + (M - this.$W) : M;
          if (P === f || P === d) {
            var L = this.clone().set(h, 1);
            L.$d[H](U), L.init(), this.$d = L.set(h, Math.min(this.$D, L.daysInMonth())).$d;
          } else H && this.$d[H](U);
          return this.init(), this;
        }, I.set = function(T, M) {
          return this.clone().$set(T, M);
        }, I.get = function(T) {
          return this[v.p(T)]();
        }, I.add = function(T, M) {
          var N, P = this;
          T = Number(T);
          var G = v.p(M), H = function(z) {
            var Z = _(P);
            return v.w(Z.date(Z.date() + Math.round(z * T)), P);
          };
          if (G === f) return this.set(f, this.$M + T);
          if (G === d) return this.set(d, this.$y + T);
          if (G === n) return H(1);
          if (G === l) return H(7);
          var U = (N = {}, N[i] = s, N[c] = a, N[o] = t, N)[G] || 1, L = this.$d.getTime() + T * U;
          return v.w(L, this);
        }, I.subtract = function(T, M) {
          return this.add(-1 * T, M);
        }, I.format = function(T) {
          var M = this, N = this.$locale();
          if (!this.isValid()) return N.invalidDate || y;
          var P = T || "YYYY-MM-DDTHH:mm:ssZ", G = v.z(this), H = this.$H, U = this.$m, L = this.$M, z = N.weekdays, Z = N.months, ae = N.meridiem, se = function(X, re, R, Q) {
            return X && (X[re] || X(M, P)) || R[re].slice(0, Q);
          }, le = function(X) {
            return v.s(H % 12 || 12, X, "0");
          }, fe = ae || function(X, re, R) {
            var Q = X < 12 ? "AM" : "PM";
            return R ? Q.toLowerCase() : Q;
          };
          return P.replace(w, (function(X, re) {
            return re || (function(R) {
              switch (R) {
                case "YY":
                  return String(M.$y).slice(-2);
                case "YYYY":
                  return v.s(M.$y, 4, "0");
                case "M":
                  return L + 1;
                case "MM":
                  return v.s(L + 1, 2, "0");
                case "MMM":
                  return se(N.monthsShort, L, Z, 3);
                case "MMMM":
                  return se(Z, L);
                case "D":
                  return M.$D;
                case "DD":
                  return v.s(M.$D, 2, "0");
                case "d":
                  return String(M.$W);
                case "dd":
                  return se(N.weekdaysMin, M.$W, z, 2);
                case "ddd":
                  return se(N.weekdaysShort, M.$W, z, 3);
                case "dddd":
                  return z[M.$W];
                case "H":
                  return String(H);
                case "HH":
                  return v.s(H, 2, "0");
                case "h":
                  return le(1);
                case "hh":
                  return le(2);
                case "a":
                  return fe(H, U, !0);
                case "A":
                  return fe(H, U, !1);
                case "m":
                  return String(U);
                case "mm":
                  return v.s(U, 2, "0");
                case "s":
                  return String(M.$s);
                case "ss":
                  return v.s(M.$s, 2, "0");
                case "SSS":
                  return v.s(M.$ms, 3, "0");
                case "Z":
                  return G;
              }
              return null;
            })(X) || G.replace(":", "");
          }));
        }, I.utcOffset = function() {
          return 15 * -Math.round(this.$d.getTimezoneOffset() / 15);
        }, I.diff = function(T, M, N) {
          var P, G = this, H = v.p(M), U = _(T), L = (U.utcOffset() - this.utcOffset()) * s, z = this - U, Z = function() {
            return v.m(G, U);
          };
          switch (H) {
            case d:
              P = Z() / 12;
              break;
            case f:
              P = Z();
              break;
            case A:
              P = Z() / 3;
              break;
            case l:
              P = (z - L) / 6048e5;
              break;
            case n:
              P = (z - L) / 864e5;
              break;
            case c:
              P = z / a;
              break;
            case i:
              P = z / s;
              break;
            case o:
              P = z / t;
              break;
            default:
              P = z;
          }
          return N ? P : v.a(P);
        }, I.daysInMonth = function() {
          return this.endOf(f).$D;
        }, I.$locale = function() {
          return g[this.$L];
        }, I.locale = function(T, M) {
          if (!T) return this.$L;
          var N = this.clone(), P = E(T, M, !0);
          return P && (N.$L = P), N;
        }, I.clone = function() {
          return v.w(this.$d, this);
        }, I.toDate = function() {
          return new Date(this.valueOf());
        }, I.toJSON = function() {
          return this.isValid() ? this.toISOString() : null;
        }, I.toISOString = function() {
          return this.$d.toISOString();
        }, I.toString = function() {
          return this.$d.toUTCString();
        }, F;
      })(), S = k.prototype;
      return _.prototype = S, [["$ms", r], ["$s", o], ["$m", i], ["$H", c], ["$W", n], ["$M", f], ["$y", d], ["$D", h]].forEach((function(F) {
        S[F[1]] = function(I) {
          return this.$g(I, F[0], F[1]);
        };
      })), _.extend = function(F, I) {
        return F.$i || (F(I, k, _), F.$i = !0), _;
      }, _.locale = E, _.isDayjs = B, _.unix = function(F) {
        return _(1e3 * F);
      }, _.en = g[p], _.Ls = g, _.p = {}, _;
    }));
  })(gu)), gu.exports;
}
var I0;
function lc() {
  if (I0) return bu.exports;
  I0 = 1;
  const e = oc();
  function u(s) {
    for (s = s.replace(/[\x00-\x20]+/g, ""); ; ) {
      const a = s.indexOf("<!--");
      if (a === -1)
        break;
      const r = s.indexOf("-->", a + 4);
      if (r === -1)
        break;
      s = s.substring(0, a) + s.substring(r + 3);
    }
    return s;
  }
  function t(s, a) {
    a = a || {};
    const r = a.allowedSchemes || ["http", "https", "ftp", "mailto", "tel", "sms"], o = a.allowProtocolRelative !== !1;
    if (typeof s != "string")
      return !1;
    s = u(s);
    const i = s.match(/^([a-zA-Z][a-zA-Z0-9.\-+]*):/);
    if (!i)
      return s.match(/^[/\\]{2}/) ? !o : !1;
    const c = i[1].toLowerCase();
    return r.indexOf(c) === -1;
  }
  return bu.exports = function(s) {
    const a = {};
    return a.options = s || {}, a.filterTag = a.options.filterTag || function(r) {
      return r = r.trim(), r.toLowerCase();
    }, a.string = function(r, o) {
      return typeof r != "string" && (typeof r == "number" || typeof r == "boolean" ? r += "" : r = ""), r = r.trim(), o !== void 0 && r === "" && (r = o), r;
    }, a.strings = function(r) {
      return Array.isArray(r) ? r.map(function(o) {
        return a.string(o);
      }) : [];
    }, a.integer = function(r, o, i, c) {
      if (o === void 0 && (o = 0), typeof r == "number")
        r = Math.floor(r);
      else
        try {
          r = parseInt(r, 10), isNaN(r) && (r = o);
        } catch {
          r = o;
        }
      return typeof i == "number" && r < i && (r = i), typeof c == "number" && r > c && (r = c), r;
    }, a.padInteger = function(r, o) {
      let i = r + "";
      for (; i.length < o; )
        i = "0" + i;
      return i;
    }, a.float = function(r, o, i, c) {
      if (o === void 0 && (o = 0), typeof r != "number")
        try {
          r = parseFloat(r, 10), isNaN(r) && (r = o);
        } catch {
          r = o;
        }
      return typeof i == "number" && r < i && (r = i), typeof c == "number" && r > c && (r = c), r;
    }, a.naughtyHref = t, a.url = function(r, o, i) {
      if (r = a.string(r, o), r === o)
        return r;
      if (r = u(r), t(r) || (r = c(r), r === null))
        return o;
      return r;
      function c(n) {
        return n.match(/^(((https?|ftp):\/\/)|((mailto|tel|sms):)|#|([^/.]+)?\/|[^/.]+$)/) ? n : n.match(/^[^/.]+\.[^/.]+/) ? (i ? "https://" : "http://") + n : null;
      }
    }, a.select = function(r, o, i) {
      if (r = a.string(r), !o || !o.length)
        return i;
      let c;
      return typeof o[0] == "object" ? (c = o.find(function(n) {
        return n.value === null || n.value === void 0 ? !1 : n.value.toString() === r;
      }), c != null ? c.value : i) : (c = o.find(function(n) {
        return n == null ? !1 : n.toString() === r;
      }), c !== void 0 ? c : i);
    }, a.boolean = function(r, o) {
      return r === !0 ? !0 : r === !1 ? !1 : (r = a.string(r, o), r === o ? r === void 0 ? !1 : r : (r = r.toLowerCase().charAt(0), r === "" || r === "n" || r === "0" || r === "f" ? !1 : r === "t" || r === "y" || r === "1"));
    }, a.addBooleanFilterToCriteria = function(r, o, i, c) {
      c === void 0 && (c = null);
      let n = typeof r == "object" && r !== null ? r[o] : r;
      n = n === void 0 ? c : n, n = a.booleanOrNull(n), n === null || (n ? i[o] = !0 : i[o] = { $ne: !0 });
    }, a.booleanOrNull = function(r, o) {
      return r === !0 || r === !1 || r === null ? r : (r = a.string(r, o), r === o ? o === void 0 ? null : r : r === "null" ? null : (r = r.toLowerCase().charAt(0), r === "" || r === "n" || r === "0" || r === "f" ? !1 : r === "t" || r === "y" || r === "1" ? !0 : r === "a" ? null : o));
    }, a.date = function(r, o, i) {
      let c;
      function n() {
        return o === void 0 && (o = e().format("YYYY-MM-DD")), o;
      }
      if (typeof r == "string") {
        if (r.match(/\//)) {
          if (c = r.split("/"), c.length === 2)
            return (i || /* @__PURE__ */ new Date()).getFullYear() + "-" + a.padInteger(c[0], 2) + "-" + a.padInteger(c[1], 2);
          if (c.length === 3) {
            if (c[2] < 100) {
              const l = i || /* @__PURE__ */ new Date(), f = l.getFullYear() % 100, A = l.getFullYear() - f;
              let d = parseInt(c[2]) + A;
              d - l.getFullYear() > 50 && (d -= 100), c[2] = d;
            }
            return a.padInteger(c[2], 4) + "-" + a.padInteger(c[0], 2) + "-" + a.padInteger(c[1], 2);
          } else
            return n();
        } else if (r.match(/-/))
          return c = r.split("-"), c.length === 2 ? (i || /* @__PURE__ */ new Date()).getFullYear() + "-" + a.padInteger(c[0], 2) + "-" + a.padInteger(c[1], 2) : c.length === 3 ? a.padInteger(c[0], 4) + "-" + a.padInteger(c[1], 2) + "-" + a.padInteger(c[2], 2) : n();
      }
      try {
        return r === null || (r = i || new Date(r), isNaN(r.getTime())) ? n() : r.getFullYear() + "-" + a.padInteger(r.getMonth() + 1, 2) + "-" + a.padInteger(r.getDate(), 2);
      } catch {
        return n();
      }
    }, a.formatDate = function(r) {
      return e(r).format("YYYY-MM-DD");
    }, a.time = function(r, o) {
      r = a.string(r).toLowerCase(), r = r.trim();
      const i = r.match(/^(\d+)([:|.](\d+))?([:|.](\d+))?\s*(am|pm|AM|PM|a|p|A|M)?$/);
      if (i) {
        let c = parseInt(i[1], 10);
        const n = i[3] !== void 0 ? parseInt(i[3], 10) : 0, l = i[5] !== void 0 ? parseInt(i[5], 10) : 0;
        let f = i[6] ? i[6].toLowerCase() : i[6];
        return f = f && f.charAt(0), c === 12 && f === "a" ? c -= 12 : c === 12 && f === "p" || f === "p" && (c += 12), (c === 24 || c === "24") && (c = 0), a.padInteger(c, 2) + ":" + a.padInteger(n, 2) + ":" + a.padInteger(l, 2);
      } else
        return o !== void 0 ? o : e().format("HH:mm");
    }, a.formatTime = function(r) {
      return e(r).format("HH:mm:ss");
    }, a.tags = function(r, o) {
      return typeof r == "string" && (r = r.split(/,\s*/)), Array.isArray(r) ? r.map((l) => a.string(l)).map(o || a.filterTag).filter((l) => l.length > 0) : [];
    }, a.idRegExp = a.options.idRegExp || /^[A-Za-z0-9_]+$/, a.id = function(r, o) {
      const i = a.string(r, o);
      return i === o || i.match(a.idRegExp) ? i : o;
    }, a.ids = function(r) {
      return Array.isArray(r) ? r.filter(function(i) {
        return a.id(i) !== void 0;
      }) : [];
    }, a;
  }, bu.exports.naughtyHref = t, bu.exports;
}
var Ct, k0;
function fc() {
  if (k0) return Ct;
  k0 = 1;
  const e = /* @__PURE__ */ Ys(), u = js(), { isPlainObject: t } = Js(), s = Zs(), a = zs(), { parse: r } = sc(), { naughtyHref: o } = lc(), i = [
    "img",
    "audio",
    "video",
    "picture",
    "svg",
    "object",
    "map",
    "iframe",
    "embed"
  ], c = ["script", "style"];
  function n(w, b) {
    w && Object.keys(w).forEach(function(x) {
      b(w[x], x);
    });
  }
  function l(w, b) {
    return {}.hasOwnProperty.call(w, b);
  }
  function f(w, b) {
    const x = [];
    return n(w, function(m) {
      b(m) && x.push(m);
    }), x;
  }
  function A(w) {
    for (const b in w)
      if (l(w, b))
        return !1;
    return !0;
  }
  function d(w) {
    return w.map(function(b) {
      if (!b.url)
        throw new Error("URL missing");
      return b.url + (b.w ? ` ${b.w}w` : "") + (b.h ? ` ${b.h}h` : "") + (b.d ? ` ${b.d}x` : "");
    }).join(", ");
  }
  Ct = y;
  const h = /^[^\0\t\n\f\r /<=>]+$/;
  function y(w, b, x) {
    if (w == null)
      return "";
    typeof w == "number" && (w = w.toString());
    let m = "", p = "";
    function g(R, Q) {
      const O = this;
      this.tag = R, this.attribs = Q || {}, this.tagPosition = m.length, this.text = "", this.openingTagLength = 0, this.mediaChildren = [], this.updateParentNodeText = function() {
        if (M.length) {
          const W = M[M.length - 1];
          W.text += O.text;
        }
      }, this.updateParentNodeMediaChildren = function() {
        M.length && i.includes(this.tag) && M[M.length - 1].mediaChildren.push(this.tag);
      };
    }
    b = Object.assign({}, y.defaults, b), b.parser = Object.assign({}, C, b.parser);
    const D = function(R) {
      return b.allowedTags === !1 || (b.allowedTags || []).indexOf(R) > -1;
    };
    c.forEach(function(R) {
      D(R) && !b.allowVulnerableTags && console.warn(`

⚠️ Your \`allowedTags\` option includes, \`${R}\`, which is inherently
vulnerable to XSS attacks. Please remove it from \`allowedTags\`.
Or, to disable this warning, add the \`allowVulnerableTags\` option
and ensure you are accounting for this risk.

`);
    });
    const B = b.nonTextTags || [
      "script",
      "style",
      "textarea",
      "option",
      "xmp"
    ];
    let E, _;
    b.allowedAttributes && (E = {}, _ = {}, n(b.allowedAttributes, function(R, Q) {
      E[Q] = [];
      const O = [];
      R.forEach(function(W) {
        typeof W == "string" && W.indexOf("*") >= 0 ? O.push(u(W).replace(/\\\*/g, ".*")) : E[Q].push(W);
      }), O.length && (_[Q] = new RegExp("^(" + O.join("|") + ")$"));
    }));
    const v = {}, k = {}, S = {};
    n(b.allowedClasses, function(R, Q) {
      if (E && (l(E, Q) || (E[Q] = []), E[Q].push("class")), v[Q] = R, Array.isArray(R)) {
        const O = [];
        v[Q] = [], S[Q] = [], R.forEach(function(W) {
          typeof W == "string" && W.indexOf("*") >= 0 ? O.push(u(W).replace(/\\\*/g, ".*")) : W instanceof RegExp ? S[Q].push(W) : v[Q].push(W);
        }), O.length && (k[Q] = new RegExp("^(" + O.join("|") + ")$"));
      }
    });
    const F = {};
    let I;
    n(b.transformTags, function(R, Q) {
      let O;
      typeof R == "function" ? O = R : typeof R == "string" && (O = y.simpleTransform(R)), Q === "*" ? I = O : F[Q] = O;
    });
    let T, M, N, P, G, H, U = !1;
    z();
    const L = new e.Parser({
      onopentag: function(R, Q) {
        if (b.onOpenTag && b.onOpenTag(R, Q), b.enforceHtmlBoundary && R === "html" && z(), G) {
          H++;
          return;
        }
        const O = new g(R, Q);
        M.push(O);
        let W = !1;
        const ne = !!O.text;
        let ce;
        if (l(F, R) && (ce = F[R](R, Q), O.attribs = Q = ce.attribs, ce.text !== void 0 && (O.innerText = ce.text), R !== ce.tagName && (O.name = R = ce.tagName, P[T] = ce.tagName)), I && (ce = I(R, Q), O.attribs = Q = ce.attribs, R !== ce.tagName && (O.name = R = ce.tagName, P[T] = ce.tagName)), (!D(R) || b.disallowedTagsMode === "recursiveEscape" && !A(N) || b.nestingLimit != null && T >= b.nestingLimit) && (W = !0, N[T] = !0, (b.disallowedTagsMode === "discard" || b.disallowedTagsMode === "completelyDiscard") && B.indexOf(R) !== -1 && (G = !0, H = 1)), T++, W) {
          if (b.disallowedTagsMode === "discard" || b.disallowedTagsMode === "completelyDiscard") {
            if (O.innerText && !ne) {
              const J = Z(O.innerText);
              b.textFilter ? m += b.textFilter(J, R) : m += J, U = !0;
            }
            return;
          }
          p = m, m = "";
        }
        m += "<" + R, R === "script" && (b.allowedScriptHostnames || b.allowedScriptDomains) && (O.innerText = ""), W && (b.disallowedTagsMode === "escape" || b.disallowedTagsMode === "recursiveEscape") && b.preserveEscapedAttributes ? n(Q, function(J, K) {
          m += " " + K + '="' + Z(J || "", !0) + '"';
        }) : (!E || l(E, R) || E["*"]) && n(Q, function(J, K) {
          if (!h.test(K)) {
            delete O.attribs[K];
            return;
          }
          if (J === "" && !b.allowedEmptyAttributes.includes(K) && (b.nonBooleanAttributes.includes(K) || b.nonBooleanAttributes.includes("*"))) {
            delete O.attribs[K];
            return;
          }
          let Fu = !1;
          if (!E || l(E, R) && E[R].indexOf(K) !== -1 || E["*"] && E["*"].indexOf(K) !== -1 || l(_, R) && _[R].test(K) || _["*"] && _["*"].test(K))
            Fu = !0;
          else if (E && E[R]) {
            for (const Y of E[R])
              if (t(Y) && Y.name && Y.name === K) {
                Fu = !0;
                let j = "";
                if (Y.multiple === !0) {
                  const Me = J.split(" ");
                  for (const De of Me)
                    Y.values.indexOf(De) !== -1 && (j === "" ? j = De : j += " " + De);
                } else Y.values.indexOf(J) >= 0 && (j = J);
                J = j;
              }
          }
          if (Fu) {
            if (b.allowedSchemesAppliedToAttributes.indexOf(K) !== -1 && ae(R, J)) {
              delete O.attribs[K];
              return;
            }
            if (R === "script" && K === "src") {
              let Y = !0;
              try {
                const j = se(J);
                if (b.allowedScriptHostnames || b.allowedScriptDomains) {
                  const Me = (b.allowedScriptHostnames || []).find(function(de) {
                    return de === j.url.hostname;
                  }), De = (b.allowedScriptDomains || []).find(function(de) {
                    return j.url.hostname === de || j.url.hostname.endsWith(`.${de}`);
                  });
                  Y = Me || De;
                }
              } catch {
                Y = !1;
              }
              if (!Y) {
                delete O.attribs[K];
                return;
              }
            }
            if (R === "iframe" && K === "src") {
              let Y = !0;
              try {
                const j = se(J);
                if (j.isRelativeUrl)
                  Y = l(b, "allowIframeRelativeUrls") ? b.allowIframeRelativeUrls : !b.allowedIframeHostnames && !b.allowedIframeDomains;
                else if (b.allowedIframeHostnames || b.allowedIframeDomains) {
                  const Me = (b.allowedIframeHostnames || []).find(function(de) {
                    return de === j.url.hostname;
                  }), De = (b.allowedIframeDomains || []).find(function(de) {
                    return j.url.hostname === de || j.url.hostname.endsWith(`.${de}`);
                  });
                  Y = Me || De;
                }
              } catch {
                Y = !1;
              }
              if (!Y) {
                delete O.attribs[K];
                return;
              }
            }
            if (K === "srcset")
              try {
                let Y = a(J);
                if (Y.forEach(function(j) {
                  ae("srcset", j.url) && (j.evil = !0);
                }), Y = f(Y, function(j) {
                  return !j.evil;
                }), Y.length)
                  J = d(f(Y, function(j) {
                    return !j.evil;
                  })), O.attribs[K] = J;
                else {
                  delete O.attribs[K];
                  return;
                }
              } catch {
                delete O.attribs[K];
                return;
              }
            if (K === "class") {
              const Y = v[R], j = v["*"], Me = k[R], De = S[R], de = S["*"], xn = k["*"], qt = [
                Me,
                xn
              ].concat(De, de).filter(function(yn) {
                return yn;
              });
              if (Y && j ? J = re(
                J,
                s(Y, j),
                qt
              ) : J = re(
                J,
                Y || j,
                qt
              ), !J.length) {
                delete O.attribs[K];
                return;
              }
            }
            if (K === "style") {
              if (b.parseStyleAttributes)
                try {
                  const Y = r(R + " {" + J + "}", { map: !1 }), j = le(
                    Y,
                    b.allowedStyles
                  );
                  if (J = fe(j), J.length === 0) {
                    delete O.attribs[K];
                    return;
                  }
                } catch {
                  typeof window < "u" && console.warn('Failed to parse "' + R + " {" + J + `}", If you're running this in a browser, we recommend to disable style parsing: options.parseStyleAttributes: false, since this only works in a node environment due to a postcss dependency, More info: https://github.com/apostrophecms/sanitize-html/issues/547`), delete O.attribs[K];
                  return;
                }
              else if (b.allowedStyles)
                throw new Error("allowedStyles option cannot be used together with parseStyleAttributes: false.");
            }
            m += " " + K, J && J.length ? m += '="' + Z(J, !0) + '"' : b.allowedEmptyAttributes.includes(K) && (m += '=""');
          } else
            delete O.attribs[K];
        }), b.selfClosing.indexOf(R) !== -1 ? m += " />" : (m += ">", O.innerText && !ne && !b.textFilter && (m += Z(O.innerText), U = !0)), W && (m = p + Z(m), p = ""), O.openingTagLength = m.length - O.tagPosition;
      },
      ontext: function(R) {
        if (G)
          return;
        const Q = M[M.length - 1];
        let O;
        if (Q && (O = Q.tag, R = Q.innerText !== void 0 ? Q.innerText : R), b.disallowedTagsMode === "completelyDiscard" && !D(O))
          R = "";
        else if ((b.disallowedTagsMode === "discard" || b.disallowedTagsMode === "completelyDiscard") && (O === "script" || O === "style"))
          m += R;
        else if ((b.disallowedTagsMode === "discard" || b.disallowedTagsMode === "completelyDiscard") && (O === "textarea" || O === "xmp"))
          m += R;
        else if (!U) {
          const W = Z(R, !1);
          b.textFilter ? m += b.textFilter(W, O) : m += W;
        }
        if (M.length) {
          const W = M[M.length - 1];
          W.text += R;
        }
      },
      onclosetag: function(R, Q) {
        if (b.onCloseTag && b.onCloseTag(R, Q), G)
          if (H--, !H)
            G = !1;
          else
            return;
        const O = M.pop();
        if (!O)
          return;
        if (O.tag !== R) {
          M.push(O);
          return;
        }
        G = b.enforceHtmlBoundary ? R === "html" : !1, T--;
        const W = N[T];
        if (W) {
          if (delete N[T], b.disallowedTagsMode === "discard" || b.disallowedTagsMode === "completelyDiscard") {
            O.updateParentNodeText();
            return;
          }
          p = m, m = "";
        }
        if (P[T] && (R = P[T], delete P[T]), b.exclusiveFilter) {
          const ne = b.exclusiveFilter(O);
          if (ne === "excludeTag") {
            W && (m = p, p = ""), m = m.substring(0, O.tagPosition) + m.substring(O.tagPosition + O.openingTagLength);
            return;
          } else if (ne) {
            m = m.substring(0, O.tagPosition);
            return;
          }
        }
        if (O.updateParentNodeMediaChildren(), O.updateParentNodeText(), // Already output />
        b.selfClosing.indexOf(R) !== -1 || // Escaped tag, closing tag is implied
        Q && !D(R) && ["escape", "recursiveEscape"].indexOf(b.disallowedTagsMode) >= 0) {
          W && (m = p, p = "");
          return;
        }
        m += "</" + R + ">", W && (m = p + Z(m), p = ""), U = !1;
      }
    }, b.parser);
    if (L.write(w), L.end(), b.disallowedTagsMode === "escape" || b.disallowedTagsMode === "recursiveEscape") {
      const R = L.endIndex;
      if (R != null && R >= 0 && R < w.length) {
        const Q = w.substring(R);
        m += Z(Q);
      } else (R == null || R < 0) && w.length > 0 && m === "" && (m = Z(w));
    }
    return m;
    function z() {
      m = "", T = 0, M = [], N = {}, P = {}, G = !1, H = 0;
    }
    function Z(R, Q) {
      return typeof R != "string" && (R = R + ""), b.parser.decodeEntities && (R = R.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;"), Q && (R = R.replace(/"/g, "&quot;"))), R = R.replace(/&(?![a-zA-Z0-9#]{1,20};)/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;"), Q && (R = R.replace(/"/g, "&quot;")), R;
    }
    function ae(R, Q) {
      const O = l(b.allowedSchemesByTag, R) ? b.allowedSchemesByTag[R] : b.allowedSchemes || [];
      return o(Q, {
        allowedSchemes: O,
        allowProtocolRelative: b.allowProtocolRelative
      });
    }
    function se(R) {
      if (R = R.replace(/^(\w+:)?\s*[\\/]\s*[\\/]/, "$1//"), R.startsWith("relative:"))
        throw new Error("relative: exploit attempt");
      let Q = "relative://relative-site";
      for (let ne = 0; ne < 100; ne++)
        Q += `/${ne}`;
      const O = new URL(R, Q);
      return {
        isRelativeUrl: O && O.hostname === "relative-site" && O.protocol === "relative:",
        url: O
      };
    }
    function le(R, Q) {
      if (!Q)
        return R;
      const O = R.nodes[0];
      let W;
      return Q[O.selector] && Q["*"] ? W = s(
        Q[O.selector],
        Q["*"]
      ) : W = Q[O.selector] || Q["*"], W && (R.nodes[0].nodes = O.nodes.reduce(X(W), [])), R;
    }
    function fe(R) {
      return R.nodes[0].nodes.reduce(function(Q, O) {
        return Q.push(
          `${O.prop}:${O.value}${O.important ? " !important" : ""}`
        ), Q;
      }, []).join(";");
    }
    function X(R) {
      return function(Q, O) {
        return l(R, O.prop) && R[O.prop].some(function(ne) {
          return ne.test(O.value);
        }) && Q.push(O), Q;
      };
    }
    function re(R, Q, O) {
      return Q ? (R = R.split(/\s+/), R.filter(function(W) {
        return Q.indexOf(W) !== -1 || O.some(function(ne) {
          return ne.test(W);
        });
      }).join(" ")) : R;
    }
  }
  const C = {
    decodeEntities: !0
  };
  return y.defaults = {
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
  }, y.simpleTransform = function(w, b, x) {
    return x = x === void 0 ? !0 : x, b = b || {}, function(m, p) {
      let g;
      if (x)
        for (g in b)
          p[g] = b[g];
      else
        p = b;
      return {
        tagName: w,
        attribs: p
      };
    };
  }, Ct;
}
var dc = /* @__PURE__ */ fc();
const B0 = /* @__PURE__ */ Rs(dc), Ac = () => On(), hc = [
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
], bc = {
  a: ["href", "name", "target"],
  span: ["class"],
  pre: ["class"],
  code: ["class"],
  img: ["src", "alt", "title", "width", "height", "loading"]
}, pc = ["innerHTML"], gc = {
  key: 1,
  class: "markdown-empty"
}, mc = /* @__PURE__ */ Cn({
  __name: "markdown-view",
  setup(e) {
    const u = Ac(), t = Qn(), s = new oe({
      html: !1,
      breaks: !0,
      linkify: !0,
      typographer: !1
    }), a = nu(
      () => u.value.content || t.value || ""
    ), r = nu(() => {
      const c = u.value.allowedTags;
      return c && c.length > 0 ? c : hc;
    }), o = nu(() => {
      const c = u.value.allowedAttributes;
      if (c)
        try {
          return JSON.parse(c);
        } catch {
        }
      return bc;
    }), i = nu(() => {
      if (!a.value) return "";
      const c = s.render(a.value);
      return B0(c, {
        allowedTags: r.value,
        allowedAttributes: o.value,
        allowedClasses: {
          code: ["language-*"],
          pre: ["language-*"],
          span: ["language-*"]
        },
        transformTags: {
          a: B0.simpleTransform("a", { rel: "noopener noreferrer" })
        }
      });
    });
    return (c, n) => i.value ? (Wt(), Ut("article", {
      key: 0,
      class: "data-body markdown-container",
      innerHTML: i.value
    }, null, 8, pc)) : (Wt(), Ut("div", gc, " No markdown content provided. "));
  }
}), xc = ":root{--p-primary: rgb(0, 95, 178);--p-primary-50: color-mix(in srgb, var(--p-primary) 5%, white);--p-primary-100: color-mix(in srgb, var(--p-primary) 10%, white);--p-primary-200: color-mix(in srgb, var(--p-primary) 20%, white);--p-primary-300: color-mix(in srgb, var(--p-primary) 30%, white);--p-primary-400: color-mix(in srgb, var(--p-primary) 40%, white);--p-primary-500: var(--p-primary);--p-primary-600: color-mix(in srgb, var(--p-primary) 80%, black);--p-primary-700: color-mix(in srgb, var(--p-primary) 70%, black);--p-primary-800: color-mix(in srgb, var(--p-primary) 60%, black);--p-primary-900: color-mix(in srgb, var(--p-primary) 50%, black);--p-primary-950: color-mix(in srgb, var(--p-primary) 40%, black);--p-secondary: #6f7385;--p-secondary-50: color-mix(in srgb, var(--p-secondary) 5%, white);--p-secondary-100: color-mix(in srgb, var(--p-secondary) 10%, white);--p-secondary-200: color-mix(in srgb, var(--p-secondary) 20%, white);--p-secondary-300: color-mix(in srgb, var(--p-secondary) 35%, white);--p-secondary-400: color-mix(in srgb, var(--p-secondary) 65%, white);--p-secondary-500: var(--p-secondary);--p-secondary-600: color-mix(in srgb, var(--p-secondary) 80%, black);--p-secondary-700: color-mix(in srgb, var(--p-secondary) 65%, black);--p-secondary-800: color-mix(in srgb, var(--p-secondary) 55%, black);--p-secondary-900: color-mix(in srgb, var(--p-secondary) 50%, black);--p-secondary-950: color-mix(in srgb, var(--p-secondary) 30%, black);--p-danger: rgb(239, 68, 68);--p-danger-50: color-mix(in srgb, var(--p-danger) 5%, white);--p-danger-100: color-mix(in srgb, var(--p-danger) 10%, white);--p-danger-200: color-mix(in srgb, var(--p-danger) 20%, white);--p-danger-300: color-mix(in srgb, var(--p-danger) 30%, white);--p-danger-400: color-mix(in srgb, var(--p-danger) 40%, white);--p-danger-500: var(--p-danger);--p-danger-600: color-mix(in srgb, var(--p-danger) 80%, black);--p-danger-700: color-mix(in srgb, var(--p-danger) 70%, black);--p-danger-800: color-mix(in srgb, var(--p-danger) 60%, black);--p-danger-900: color-mix(in srgb, var(--p-danger) 50%, black);--p-danger-950: color-mix(in srgb, var(--p-danger) 40%, black);--p-success: rgb(34, 197, 94);--p-success-50: color-mix(in srgb, var(--p-success) 5%, white);--p-success-100: color-mix(in srgb, var(--p-success) 10%, white);--p-success-200: color-mix(in srgb, var(--p-success) 20%, white);--p-success-300: color-mix(in srgb, var(--p-success) 30%, white);--p-success-400: color-mix(in srgb, var(--p-success) 40%, white);--p-success-500: var(--p-success);--p-success-600: color-mix(in srgb, var(--p-success) 80%, black);--p-success-700: color-mix(in srgb, var(--p-success) 70%, black);--p-success-800: color-mix(in srgb, var(--p-success) 60%, black);--p-success-900: color-mix(in srgb, var(--p-success) 50%, black);--p-success-950: color-mix(in srgb, var(--p-success) 40%, black);--p-warn: rgb(249, 115, 22);--p-warn-50: color-mix(in srgb, var(--p-warn) 5%, white);--p-warn-100: color-mix(in srgb, var(--p-warn) 10%, white);--p-warn-200: color-mix(in srgb, var(--p-warn) 20%, white);--p-warn-300: color-mix(in srgb, var(--p-warn) 30%, white);--p-warn-400: color-mix(in srgb, var(--p-warn) 40%, white);--p-warn-500: var(--p-warn);--p-warn-600: color-mix(in srgb, var(--p-warn) 80%, black);--p-warn-700: color-mix(in srgb, var(--p-warn) 70%, black);--p-warn-800: color-mix(in srgb, var(--p-warn) 60%, black);--p-warn-900: color-mix(in srgb, var(--p-warn) 50%, black);--p-warn-950: color-mix(in srgb, var(--p-warn) 40%, black);--p-info: rgb(14, 165, 233);--p-info-50: color-mix(in srgb, var(--p-info) 5%, white);--p-info-100: color-mix(in srgb, var(--p-info) 10%, white);--p-info-200: color-mix(in srgb, var(--p-info) 20%, white);--p-info-300: color-mix(in srgb, var(--p-info) 30%, white);--p-info-400: color-mix(in srgb, var(--p-info) 40%, white);--p-info-500: var(--p-info);--p-info-600: color-mix(in srgb, var(--p-info) 80%, black);--p-info-700: color-mix(in srgb, var(--p-info) 70%, black);--p-info-800: color-mix(in srgb, var(--p-info) 60%, black);--p-info-900: color-mix(in srgb, var(--p-info) 50%, black);--p-info-950: color-mix(in srgb, var(--p-info) 40%, black);--p-help: rgb(168, 85, 247);--p-help-50: color-mix(in srgb, var(--p-help) 5%, white);--p-help-100: color-mix(in srgb, var(--p-help) 10%, white);--p-help-200: color-mix(in srgb, var(--p-help) 20%, white);--p-help-300: color-mix(in srgb, var(--p-help) 30%, white);--p-help-400: color-mix(in srgb, var(--p-help) 40%, white);--p-help-500: var(--p-help);--p-help-600: color-mix(in srgb, var(--p-help) 80%, black);--p-help-700: color-mix(in srgb, var(--p-help) 70%, black);--p-help-800: color-mix(in srgb, var(--p-help) 60%, black);--p-help-900: color-mix(in srgb, var(--p-help) 50%, black);--p-help-950: color-mix(in srgb, var(--p-help) 40%, black);--p-accent: rgb(20, 184, 166);--p-accent-50: color-mix(in srgb, var(--p-accent) 5%, white);--p-accent-100: color-mix(in srgb, var(--p-accent) 10%, white);--p-accent-200: color-mix(in srgb, var(--p-accent) 20%, white);--p-accent-300: color-mix(in srgb, var(--p-accent) 30%, white);--p-accent-400: color-mix(in srgb, var(--p-accent) 40%, white);--p-accent-500: var(--p-accent);--p-accent-600: color-mix(in srgb, var(--p-accent) 80%, black);--p-accent-700: color-mix(in srgb, var(--p-accent) 70%, black);--p-accent-800: color-mix(in srgb, var(--p-accent) 60%, black);--p-accent-900: color-mix(in srgb, var(--p-accent) 50%, black);--p-accent-950: color-mix(in srgb, var(--p-accent) 40%, black);--p-surface-0: #ffffff;--p-surface-50: #fafafa;--p-surface-100: #f5f5f5;--p-surface-200: #e5e5e5;--p-surface-300: #d4d4d4;--p-surface-400: #a3a3a3;--p-surface-500: #737373;--p-surface-600: #525252;--p-surface-700: #404040;--p-surface-800: #262626;--p-surface-850: color-mix(in srgb, var(--p-surface-800) 50%, var(--p-surface-900));--p-surface-900: #171717;--p-surface-950: #0a0a0a;--p-content-border-radius: 6px}:root{--p-primary-color: var(--p-primary-500);--p-primary-contrast-color: var(--p-surface-0);--p-primary-hover-color: var(--p-primary-600);--p-primary-active-color: var(--p-primary-700);--p-content-border-color: var(--p-surface-200);--p-content-hover-background: var(--p-surface-100);--p-content-hover-color: var(--p-surface-800);--p-highlight-background: var(--p-primary-50);--p-highlight-color: var(--p-primary-700);--p-highlight-focus-background: var(--p-primary-100);--p-highlight-focus-color: var(--p-primary-800);--p-content-background: var(--p-surface-0);--p-text-color: var(--p-surface-700);--p-text-hover-color: var(--p-surface-800);--p-text-muted-color: var(--p-surface-500);--p-text-hover-muted-color: var(--p-surface-600)}@media(prefers-color-scheme:dark){:root{--p-surface-D: #fff;--p-surface-0: #fff;--p-surface-50: #fafafa;--p-surface-100: #f4f4f5;--p-surface-200: #e4e4e7;--p-surface-300: #d4d4d8;--p-surface-400: #a1a1aa;--p-surface-500: #71717a;--p-surface-600: #545250;--p-surface-700: #403e3c;--p-surface-800: #2b2927;--p-surface-850: color-mix(in srgb, var(--p-surface-800) 50%, var(--p-surface-900));--p-surface-900: #1c1a19;--p-surface-950: #0f0e0d;--p-primary: rgb(0, 125, 178);--p-primary-50: color-mix(in srgb, var(--p-primary) 5%, white);--p-primary-100: color-mix(in srgb, var(--p-primary) 10%, white);--p-primary-200: color-mix(in srgb, var(--p-primary) 20%, white);--p-primary-300: color-mix(in srgb, var(--p-primary) 30%, white);--p-primary-400: color-mix(in srgb, var(--p-primary) 40%, white);--p-primary-500: var(--p-primary);--p-primary-600: color-mix(in srgb, var(--p-primary) 80%, black);--p-primary-700: color-mix(in srgb, var(--p-primary) 70%, black);--p-primary-800: color-mix(in srgb, var(--p-primary) 60%, black);--p-primary-900: color-mix(in srgb, var(--p-primary) 50%, black);--p-primary-950: color-mix(in srgb, var(--p-primary) 40%, black);--p-primary-color: var(--p-primary-400);--p-primary-contrast-color: var(--p-surface-900);--p-primary-hover-color: var(--p-primary-300);--p-primary-active-color: var(--p-primary-200);--p-content-border-color: var(--p-surface-700);--p-content-hover-background: var(--p-surface-800);--p-content-hover-color: var(--p-surface-0);--p-highlight-background: color-mix(in srgb, var(--p-primary-400), transparent 84%);--p-highlight-color: rgba(255, 255, 255, 87%);--p-highlight-focus-background: color-mix(in srgb, var(--p-primary-400), transparent 76%);--p-highlight-focus-color: rgba(255, 255, 255, 87%);--p-content-background: var(--p-surface-900);--p-text-color: var(--p-surface-0);--p-text-hover-color: var(--p-surface-0);--p-text-muted-color: var(--p-surface-400);--p-text-hover-muted-color: var(--p-surface-300)}}.markdown-container{font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif;color:var(--p-text-color, #333);line-height:1.6;width:100%;box-sizing:border-box;overflow-wrap:break-word;word-break:break-word}.markdown-empty{color:var(--p-text-muted-color, #999);font-style:italic;text-align:center}", yc = { props: { type: "object", properties: { content: { type: "string", default: "", description: "Markdown source text to render (GFM)" }, "allowed-tags": { type: "array", items: { type: "string" }, default: [], description: "Override sanitizer tag whitelist (empty = built-in defaults). WARNING: widening this is a security decision — only do it for trusted input." }, "allowed-attributes": { type: "string", default: "", description: "JSON-stringified `{tag: [attr,...]}` map for sanitize-html (empty = defaults)" } } } }, wc = {
  wippy: yc
};
class Cc extends jn {
  static get wippyConfig() {
    return {
      propsSchema: wc.wippy.props,
      hostCssKeys: ["themeConfigUrl", "markdownCssUrl"],
      inlineCss: xc,
      contentTemplate: "text/markdown"
    };
  }
  static get vueConfig() {
    return {
      rootComponent: mc
    };
  }
}
In(import.meta.url, Cc);
