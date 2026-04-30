import { g as Ty } from "./index.js";
var _s = { exports: {} }, wy = _s.exports, jl;
function Sy() {
  return jl || (jl = 1, (function(e, t) {
    (function(r, i) {
      e.exports = i();
    })(wy, (function() {
      var r = 1e3, i = 6e4, s = 36e5, o = "millisecond", a = "second", n = "minute", l = "hour", c = "day", h = "week", u = "month", p = "quarter", d = "year", g = "date", m = "Invalid Date", y = /^(\d{4})[-/]?(\d{1,2})?[-/]?(\d{0,2})[Tt\s]*(\d{1,2})?:?(\d{1,2})?:?(\d{1,2})?[.:]?(\d+)?$/, x = /\[([^\]]+)]|Y{1,4}|M{1,4}|D{1,2}|d{1,4}|H{1,2}|h{1,2}|a|A|m{1,2}|s{1,2}|Z{1,2}|SSS/g, b = { name: "en", weekdays: "Sunday_Monday_Tuesday_Wednesday_Thursday_Friday_Saturday".split("_"), months: "January_February_March_April_May_June_July_August_September_October_November_December".split("_"), ordinal: function(I) {
        var F = ["th", "st", "nd", "rd"], L = I % 100;
        return "[" + I + (F[(L - 20) % 10] || F[L] || F[0]) + "]";
      } }, k = function(I, F, L) {
        var E = String(I);
        return !E || E.length >= F ? I : "" + Array(F + 1 - E.length).join(L) + I;
      }, w = { s: k, z: function(I) {
        var F = -I.utcOffset(), L = Math.abs(F), E = Math.floor(L / 60), P = L % 60;
        return (F <= 0 ? "+" : "-") + k(E, 2, "0") + ":" + k(P, 2, "0");
      }, m: function I(F, L) {
        if (F.date() < L.date()) return -I(L, F);
        var E = 12 * (L.year() - F.year()) + (L.month() - F.month()), P = F.clone().add(E, u), H = L - P < 0, Y = F.clone().add(E + (H ? -1 : 1), u);
        return +(-(E + (L - P) / (H ? P - Y : Y - P)) || 0);
      }, a: function(I) {
        return I < 0 ? Math.ceil(I) || 0 : Math.floor(I);
      }, p: function(I) {
        return { M: u, y: d, w: h, d: c, D: g, h: l, m: n, s: a, ms: o, Q: p }[I] || String(I || "").toLowerCase().replace(/s$/, "");
      }, u: function(I) {
        return I === void 0;
      } }, S = "en", v = {};
      v[S] = b;
      var M = "$isDayjsObject", B = function(I) {
        return I instanceof W || !(!I || !I[M]);
      }, N = function I(F, L, E) {
        var P;
        if (!F) return S;
        if (typeof F == "string") {
          var H = F.toLowerCase();
          v[H] && (P = H), L && (v[H] = L, P = H);
          var Y = F.split("-");
          if (!P && Y.length > 1) return I(Y[0]);
        } else {
          var Q = F.name;
          v[Q] = F, P = Q;
        }
        return !E && P && (S = P), P || !E && S;
      }, D = function(I, F) {
        if (B(I)) return I.clone();
        var L = typeof F == "object" ? F : {};
        return L.date = I, L.args = arguments, new W(L);
      }, O = w;
      O.l = N, O.i = B, O.w = function(I, F) {
        return D(I, { locale: F.$L, utc: F.$u, x: F.$x, $offset: F.$offset });
      };
      var W = (function() {
        function I(L) {
          this.$L = N(L.locale, null, !0), this.parse(L), this.$x = this.$x || L.x || {}, this[M] = !0;
        }
        var F = I.prototype;
        return F.parse = function(L) {
          this.$d = (function(E) {
            var P = E.date, H = E.utc;
            if (P === null) return /* @__PURE__ */ new Date(NaN);
            if (O.u(P)) return /* @__PURE__ */ new Date();
            if (P instanceof Date) return new Date(P);
            if (typeof P == "string" && !/Z$/i.test(P)) {
              var Y = P.match(y);
              if (Y) {
                var Q = Y[2] - 1 || 0, dt = (Y[7] || "0").substring(0, 3);
                return H ? new Date(Date.UTC(Y[1], Q, Y[3] || 1, Y[4] || 0, Y[5] || 0, Y[6] || 0, dt)) : new Date(Y[1], Q, Y[3] || 1, Y[4] || 0, Y[5] || 0, Y[6] || 0, dt);
              }
            }
            return new Date(P);
          })(L), this.init();
        }, F.init = function() {
          var L = this.$d;
          this.$y = L.getFullYear(), this.$M = L.getMonth(), this.$D = L.getDate(), this.$W = L.getDay(), this.$H = L.getHours(), this.$m = L.getMinutes(), this.$s = L.getSeconds(), this.$ms = L.getMilliseconds();
        }, F.$utils = function() {
          return O;
        }, F.isValid = function() {
          return this.$d.toString() !== m;
        }, F.isSame = function(L, E) {
          var P = D(L);
          return this.startOf(E) <= P && P <= this.endOf(E);
        }, F.isAfter = function(L, E) {
          return D(L) < this.startOf(E);
        }, F.isBefore = function(L, E) {
          return this.endOf(E) < D(L);
        }, F.$g = function(L, E, P) {
          return O.u(L) ? this[E] : this.set(P, L);
        }, F.unix = function() {
          return Math.floor(this.valueOf() / 1e3);
        }, F.valueOf = function() {
          return this.$d.getTime();
        }, F.startOf = function(L, E) {
          var P = this, H = !!O.u(E) || E, Y = O.p(L), Q = function(bt, Ct) {
            var Bt = O.w(P.$u ? Date.UTC(P.$y, Ct, bt) : new Date(P.$y, Ct, bt), P);
            return H ? Bt : Bt.endOf(c);
          }, dt = function(bt, Ct) {
            return O.w(P.toDate()[bt].apply(P.toDate("s"), (H ? [0, 0, 0, 0] : [23, 59, 59, 999]).slice(Ct)), P);
          }, et = this.$W, ut = this.$M, it = this.$D, rt = "set" + (this.$u ? "UTC" : "");
          switch (Y) {
            case d:
              return H ? Q(1, 0) : Q(31, 11);
            case u:
              return H ? Q(1, ut) : Q(0, ut + 1);
            case h:
              var ht = this.$locale().weekStart || 0, ft = (et < ht ? et + 7 : et) - ht;
              return Q(H ? it - ft : it + (6 - ft), ut);
            case c:
            case g:
              return dt(rt + "Hours", 0);
            case l:
              return dt(rt + "Minutes", 1);
            case n:
              return dt(rt + "Seconds", 2);
            case a:
              return dt(rt + "Milliseconds", 3);
            default:
              return this.clone();
          }
        }, F.endOf = function(L) {
          return this.startOf(L, !1);
        }, F.$set = function(L, E) {
          var P, H = O.p(L), Y = "set" + (this.$u ? "UTC" : ""), Q = (P = {}, P[c] = Y + "Date", P[g] = Y + "Date", P[u] = Y + "Month", P[d] = Y + "FullYear", P[l] = Y + "Hours", P[n] = Y + "Minutes", P[a] = Y + "Seconds", P[o] = Y + "Milliseconds", P)[H], dt = H === c ? this.$D + (E - this.$W) : E;
          if (H === u || H === d) {
            var et = this.clone().set(g, 1);
            et.$d[Q](dt), et.init(), this.$d = et.set(g, Math.min(this.$D, et.daysInMonth())).$d;
          } else Q && this.$d[Q](dt);
          return this.init(), this;
        }, F.set = function(L, E) {
          return this.clone().$set(L, E);
        }, F.get = function(L) {
          return this[O.p(L)]();
        }, F.add = function(L, E) {
          var P, H = this;
          L = Number(L);
          var Y = O.p(E), Q = function(ut) {
            var it = D(H);
            return O.w(it.date(it.date() + Math.round(ut * L)), H);
          };
          if (Y === u) return this.set(u, this.$M + L);
          if (Y === d) return this.set(d, this.$y + L);
          if (Y === c) return Q(1);
          if (Y === h) return Q(7);
          var dt = (P = {}, P[n] = i, P[l] = s, P[a] = r, P)[Y] || 1, et = this.$d.getTime() + L * dt;
          return O.w(et, this);
        }, F.subtract = function(L, E) {
          return this.add(-1 * L, E);
        }, F.format = function(L) {
          var E = this, P = this.$locale();
          if (!this.isValid()) return P.invalidDate || m;
          var H = L || "YYYY-MM-DDTHH:mm:ssZ", Y = O.z(this), Q = this.$H, dt = this.$m, et = this.$M, ut = P.weekdays, it = P.months, rt = P.meridiem, ht = function(Ct, Bt, ce, re) {
            return Ct && (Ct[Bt] || Ct(E, H)) || ce[Bt].slice(0, re);
          }, ft = function(Ct) {
            return O.s(Q % 12 || 12, Ct, "0");
          }, bt = rt || function(Ct, Bt, ce) {
            var re = Ct < 12 ? "AM" : "PM";
            return ce ? re.toLowerCase() : re;
          };
          return H.replace(x, (function(Ct, Bt) {
            return Bt || (function(ce) {
              switch (ce) {
                case "YY":
                  return String(E.$y).slice(-2);
                case "YYYY":
                  return O.s(E.$y, 4, "0");
                case "M":
                  return et + 1;
                case "MM":
                  return O.s(et + 1, 2, "0");
                case "MMM":
                  return ht(P.monthsShort, et, it, 3);
                case "MMMM":
                  return ht(it, et);
                case "D":
                  return E.$D;
                case "DD":
                  return O.s(E.$D, 2, "0");
                case "d":
                  return String(E.$W);
                case "dd":
                  return ht(P.weekdaysMin, E.$W, ut, 2);
                case "ddd":
                  return ht(P.weekdaysShort, E.$W, ut, 3);
                case "dddd":
                  return ut[E.$W];
                case "H":
                  return String(Q);
                case "HH":
                  return O.s(Q, 2, "0");
                case "h":
                  return ft(1);
                case "hh":
                  return ft(2);
                case "a":
                  return bt(Q, dt, !0);
                case "A":
                  return bt(Q, dt, !1);
                case "m":
                  return String(dt);
                case "mm":
                  return O.s(dt, 2, "0");
                case "s":
                  return String(E.$s);
                case "ss":
                  return O.s(E.$s, 2, "0");
                case "SSS":
                  return O.s(E.$ms, 3, "0");
                case "Z":
                  return Y;
              }
              return null;
            })(Ct) || Y.replace(":", "");
          }));
        }, F.utcOffset = function() {
          return 15 * -Math.round(this.$d.getTimezoneOffset() / 15);
        }, F.diff = function(L, E, P) {
          var H, Y = this, Q = O.p(E), dt = D(L), et = (dt.utcOffset() - this.utcOffset()) * i, ut = this - dt, it = function() {
            return O.m(Y, dt);
          };
          switch (Q) {
            case d:
              H = it() / 12;
              break;
            case u:
              H = it();
              break;
            case p:
              H = it() / 3;
              break;
            case h:
              H = (ut - et) / 6048e5;
              break;
            case c:
              H = (ut - et) / 864e5;
              break;
            case l:
              H = ut / s;
              break;
            case n:
              H = ut / i;
              break;
            case a:
              H = ut / r;
              break;
            default:
              H = ut;
          }
          return P ? H : O.a(H);
        }, F.daysInMonth = function() {
          return this.endOf(u).$D;
        }, F.$locale = function() {
          return v[this.$L];
        }, F.locale = function(L, E) {
          if (!L) return this.$L;
          var P = this.clone(), H = N(L, E, !0);
          return H && (P.$L = H), P;
        }, F.clone = function() {
          return O.w(this.$d, this);
        }, F.toDate = function() {
          return new Date(this.valueOf());
        }, F.toJSON = function() {
          return this.isValid() ? this.toISOString() : null;
        }, F.toISOString = function() {
          return this.$d.toISOString();
        }, F.toString = function() {
          return this.$d.toUTCString();
        }, I;
      })(), z = W.prototype;
      return D.prototype = z, [["$ms", o], ["$s", a], ["$m", n], ["$H", l], ["$W", c], ["$M", u], ["$y", d], ["$D", g]].forEach((function(I) {
        z[I[1]] = function(F) {
          return this.$g(F, I[0], I[1]);
        };
      })), D.extend = function(I, F) {
        return I.$i || (I(F, W, D), I.$i = !0), D;
      }, D.locale = N, D.isDayjs = B, D.unix = function(I) {
        return D(1e3 * I);
      }, D.en = v[S], D.Ls = v, D.p = {}, D;
    }));
  })(_s)), _s.exports;
}
var _y = Sy();
const vy = /* @__PURE__ */ Ty(_y);
var Wc = Object.defineProperty, f = (e, t) => Wc(e, "name", { value: t, configurable: !0 }), By = (e, t) => {
  for (var r in t)
    Wc(e, r, { get: t[r], enumerable: !0 });
}, De = {
  trace: 0,
  debug: 1,
  info: 2,
  warn: 3,
  error: 4,
  fatal: 5
}, R = {
  trace: /* @__PURE__ */ f((...e) => {
  }, "trace"),
  debug: /* @__PURE__ */ f((...e) => {
  }, "debug"),
  info: /* @__PURE__ */ f((...e) => {
  }, "info"),
  warn: /* @__PURE__ */ f((...e) => {
  }, "warn"),
  error: /* @__PURE__ */ f((...e) => {
  }, "error"),
  fatal: /* @__PURE__ */ f((...e) => {
  }, "fatal")
}, vn = /* @__PURE__ */ f(function(e = "fatal") {
  let t = De.fatal;
  typeof e == "string" ? e.toLowerCase() in De && (t = De[e]) : typeof e == "number" && (t = e), R.trace = () => {
  }, R.debug = () => {
  }, R.info = () => {
  }, R.warn = () => {
  }, R.error = () => {
  }, R.fatal = () => {
  }, t <= De.fatal && (R.fatal = console.error ? console.error.bind(console, ne("FATAL"), "color: orange") : console.log.bind(console, "\x1B[35m", ne("FATAL"))), t <= De.error && (R.error = console.error ? console.error.bind(console, ne("ERROR"), "color: orange") : console.log.bind(console, "\x1B[31m", ne("ERROR"))), t <= De.warn && (R.warn = console.warn ? console.warn.bind(console, ne("WARN"), "color: orange") : console.log.bind(console, "\x1B[33m", ne("WARN"))), t <= De.info && (R.info = console.info ? console.info.bind(console, ne("INFO"), "color: lightblue") : console.log.bind(console, "\x1B[34m", ne("INFO"))), t <= De.debug && (R.debug = console.debug ? console.debug.bind(console, ne("DEBUG"), "color: lightgreen") : console.log.bind(console, "\x1B[32m", ne("DEBUG"))), t <= De.trace && (R.trace = console.debug ? console.debug.bind(console, ne("TRACE"), "color: lightgreen") : console.log.bind(console, "\x1B[32m", ne("TRACE")));
}, "setLogLevel"), ne = /* @__PURE__ */ f((e) => `%c${vy().format("ss.SSS")} : ${e} : `, "format");
const vs = {
  /* CLAMP */
  min: {
    r: 0,
    g: 0,
    b: 0,
    s: 0,
    l: 0,
    a: 0
  },
  max: {
    r: 255,
    g: 255,
    b: 255,
    h: 360,
    s: 100,
    l: 100,
    a: 1
  },
  clamp: {
    r: (e) => e >= 255 ? 255 : e < 0 ? 0 : e,
    g: (e) => e >= 255 ? 255 : e < 0 ? 0 : e,
    b: (e) => e >= 255 ? 255 : e < 0 ? 0 : e,
    h: (e) => e % 360,
    s: (e) => e >= 100 ? 100 : e < 0 ? 0 : e,
    l: (e) => e >= 100 ? 100 : e < 0 ? 0 : e,
    a: (e) => e >= 1 ? 1 : e < 0 ? 0 : e
  },
  /* CONVERSION */
  //SOURCE: https://planetcalc.com/7779
  toLinear: (e) => {
    const t = e / 255;
    return e > 0.03928 ? Math.pow((t + 0.055) / 1.055, 2.4) : t / 12.92;
  },
  //SOURCE: https://gist.github.com/mjackson/5311256
  hue2rgb: (e, t, r) => (r < 0 && (r += 1), r > 1 && (r -= 1), r < 1 / 6 ? e + (t - e) * 6 * r : r < 1 / 2 ? t : r < 2 / 3 ? e + (t - e) * (2 / 3 - r) * 6 : e),
  hsl2rgb: ({ h: e, s: t, l: r }, i) => {
    if (!t)
      return r * 2.55;
    e /= 360, t /= 100, r /= 100;
    const s = r < 0.5 ? r * (1 + t) : r + t - r * t, o = 2 * r - s;
    switch (i) {
      case "r":
        return vs.hue2rgb(o, s, e + 1 / 3) * 255;
      case "g":
        return vs.hue2rgb(o, s, e) * 255;
      case "b":
        return vs.hue2rgb(o, s, e - 1 / 3) * 255;
    }
  },
  rgb2hsl: ({ r: e, g: t, b: r }, i) => {
    e /= 255, t /= 255, r /= 255;
    const s = Math.max(e, t, r), o = Math.min(e, t, r), a = (s + o) / 2;
    if (i === "l")
      return a * 100;
    if (s === o)
      return 0;
    const n = s - o, l = a > 0.5 ? n / (2 - s - o) : n / (s + o);
    if (i === "s")
      return l * 100;
    switch (s) {
      case e:
        return ((t - r) / n + (t < r ? 6 : 0)) * 60;
      case t:
        return ((r - e) / n + 2) * 60;
      case r:
        return ((e - t) / n + 4) * 60;
      default:
        return -1;
    }
  }
}, Ly = {
  /* API */
  clamp: (e, t, r) => t > r ? Math.min(t, Math.max(r, e)) : Math.min(r, Math.max(t, e)),
  round: (e) => Math.round(e * 1e10) / 1e10
}, Fy = {
  /* API */
  dec2hex: (e) => {
    const t = Math.round(e).toString(16);
    return t.length > 1 ? t : `0${t}`;
  }
}, nt = {
  channel: vs,
  lang: Ly,
  unit: Fy
}, Ve = {};
for (let e = 0; e <= 255; e++)
  Ve[e] = nt.unit.dec2hex(e);
const zt = {
  ALL: 0,
  RGB: 1,
  HSL: 2
};
class Ay {
  constructor() {
    this.type = zt.ALL;
  }
  /* API */
  get() {
    return this.type;
  }
  set(t) {
    if (this.type && this.type !== t)
      throw new Error("Cannot change both RGB and HSL channels at the same time");
    this.type = t;
  }
  reset() {
    this.type = zt.ALL;
  }
  is(t) {
    return this.type === t;
  }
}
class My {
  /* CONSTRUCTOR */
  constructor(t, r) {
    this.color = r, this.changed = !1, this.data = t, this.type = new Ay();
  }
  /* API */
  set(t, r) {
    return this.color = r, this.changed = !1, this.data = t, this.type.type = zt.ALL, this;
  }
  /* HELPERS */
  _ensureHSL() {
    const t = this.data, { h: r, s: i, l: s } = t;
    r === void 0 && (t.h = nt.channel.rgb2hsl(t, "h")), i === void 0 && (t.s = nt.channel.rgb2hsl(t, "s")), s === void 0 && (t.l = nt.channel.rgb2hsl(t, "l"));
  }
  _ensureRGB() {
    const t = this.data, { r, g: i, b: s } = t;
    r === void 0 && (t.r = nt.channel.hsl2rgb(t, "r")), i === void 0 && (t.g = nt.channel.hsl2rgb(t, "g")), s === void 0 && (t.b = nt.channel.hsl2rgb(t, "b"));
  }
  /* GETTERS */
  get r() {
    const t = this.data, r = t.r;
    return !this.type.is(zt.HSL) && r !== void 0 ? r : (this._ensureHSL(), nt.channel.hsl2rgb(t, "r"));
  }
  get g() {
    const t = this.data, r = t.g;
    return !this.type.is(zt.HSL) && r !== void 0 ? r : (this._ensureHSL(), nt.channel.hsl2rgb(t, "g"));
  }
  get b() {
    const t = this.data, r = t.b;
    return !this.type.is(zt.HSL) && r !== void 0 ? r : (this._ensureHSL(), nt.channel.hsl2rgb(t, "b"));
  }
  get h() {
    const t = this.data, r = t.h;
    return !this.type.is(zt.RGB) && r !== void 0 ? r : (this._ensureRGB(), nt.channel.rgb2hsl(t, "h"));
  }
  get s() {
    const t = this.data, r = t.s;
    return !this.type.is(zt.RGB) && r !== void 0 ? r : (this._ensureRGB(), nt.channel.rgb2hsl(t, "s"));
  }
  get l() {
    const t = this.data, r = t.l;
    return !this.type.is(zt.RGB) && r !== void 0 ? r : (this._ensureRGB(), nt.channel.rgb2hsl(t, "l"));
  }
  get a() {
    return this.data.a;
  }
  /* SETTERS */
  set r(t) {
    this.type.set(zt.RGB), this.changed = !0, this.data.r = t;
  }
  set g(t) {
    this.type.set(zt.RGB), this.changed = !0, this.data.g = t;
  }
  set b(t) {
    this.type.set(zt.RGB), this.changed = !0, this.data.b = t;
  }
  set h(t) {
    this.type.set(zt.HSL), this.changed = !0, this.data.h = t;
  }
  set s(t) {
    this.type.set(zt.HSL), this.changed = !0, this.data.s = t;
  }
  set l(t) {
    this.type.set(zt.HSL), this.changed = !0, this.data.l = t;
  }
  set a(t) {
    this.changed = !0, this.data.a = t;
  }
}
const xo = new My({ r: 0, g: 0, b: 0, a: 0 }, "transparent"), jr = {
  /* VARIABLES */
  re: /^#((?:[a-f0-9]{2}){2,4}|[a-f0-9]{3})$/i,
  /* API */
  parse: (e) => {
    if (e.charCodeAt(0) !== 35)
      return;
    const t = e.match(jr.re);
    if (!t)
      return;
    const r = t[1], i = parseInt(r, 16), s = r.length, o = s % 4 === 0, a = s > 4, n = a ? 1 : 17, l = a ? 8 : 4, c = o ? 0 : -1, h = a ? 255 : 15;
    return xo.set({
      r: (i >> l * (c + 3) & h) * n,
      g: (i >> l * (c + 2) & h) * n,
      b: (i >> l * (c + 1) & h) * n,
      a: o ? (i & h) * n / 255 : 1
    }, e);
  },
  stringify: (e) => {
    const { r: t, g: r, b: i, a: s } = e;
    return s < 1 ? `#${Ve[Math.round(t)]}${Ve[Math.round(r)]}${Ve[Math.round(i)]}${Ve[Math.round(s * 255)]}` : `#${Ve[Math.round(t)]}${Ve[Math.round(r)]}${Ve[Math.round(i)]}`;
  }
}, fr = {
  /* VARIABLES */
  re: /^hsla?\(\s*?(-?(?:\d+(?:\.\d+)?|(?:\.\d+))(?:e-?\d+)?(?:deg|grad|rad|turn)?)\s*?(?:,|\s)\s*?(-?(?:\d+(?:\.\d+)?|(?:\.\d+))(?:e-?\d+)?%)\s*?(?:,|\s)\s*?(-?(?:\d+(?:\.\d+)?|(?:\.\d+))(?:e-?\d+)?%)(?:\s*?(?:,|\/)\s*?\+?(-?(?:\d+(?:\.\d+)?|(?:\.\d+))(?:e-?\d+)?(%)?))?\s*?\)$/i,
  hueRe: /^(.+?)(deg|grad|rad|turn)$/i,
  /* HELPERS */
  _hue2deg: (e) => {
    const t = e.match(fr.hueRe);
    if (t) {
      const [, r, i] = t;
      switch (i) {
        case "grad":
          return nt.channel.clamp.h(parseFloat(r) * 0.9);
        case "rad":
          return nt.channel.clamp.h(parseFloat(r) * 180 / Math.PI);
        case "turn":
          return nt.channel.clamp.h(parseFloat(r) * 360);
      }
    }
    return nt.channel.clamp.h(parseFloat(e));
  },
  /* API */
  parse: (e) => {
    const t = e.charCodeAt(0);
    if (t !== 104 && t !== 72)
      return;
    const r = e.match(fr.re);
    if (!r)
      return;
    const [, i, s, o, a, n] = r;
    return xo.set({
      h: fr._hue2deg(i),
      s: nt.channel.clamp.s(parseFloat(s)),
      l: nt.channel.clamp.l(parseFloat(o)),
      a: a ? nt.channel.clamp.a(n ? parseFloat(a) / 100 : parseFloat(a)) : 1
    }, e);
  },
  stringify: (e) => {
    const { h: t, s: r, l: i, a: s } = e;
    return s < 1 ? `hsla(${nt.lang.round(t)}, ${nt.lang.round(r)}%, ${nt.lang.round(i)}%, ${s})` : `hsl(${nt.lang.round(t)}, ${nt.lang.round(r)}%, ${nt.lang.round(i)}%)`;
  }
}, Ai = {
  /* VARIABLES */
  colors: {
    aliceblue: "#f0f8ff",
    antiquewhite: "#faebd7",
    aqua: "#00ffff",
    aquamarine: "#7fffd4",
    azure: "#f0ffff",
    beige: "#f5f5dc",
    bisque: "#ffe4c4",
    black: "#000000",
    blanchedalmond: "#ffebcd",
    blue: "#0000ff",
    blueviolet: "#8a2be2",
    brown: "#a52a2a",
    burlywood: "#deb887",
    cadetblue: "#5f9ea0",
    chartreuse: "#7fff00",
    chocolate: "#d2691e",
    coral: "#ff7f50",
    cornflowerblue: "#6495ed",
    cornsilk: "#fff8dc",
    crimson: "#dc143c",
    cyanaqua: "#00ffff",
    darkblue: "#00008b",
    darkcyan: "#008b8b",
    darkgoldenrod: "#b8860b",
    darkgray: "#a9a9a9",
    darkgreen: "#006400",
    darkgrey: "#a9a9a9",
    darkkhaki: "#bdb76b",
    darkmagenta: "#8b008b",
    darkolivegreen: "#556b2f",
    darkorange: "#ff8c00",
    darkorchid: "#9932cc",
    darkred: "#8b0000",
    darksalmon: "#e9967a",
    darkseagreen: "#8fbc8f",
    darkslateblue: "#483d8b",
    darkslategray: "#2f4f4f",
    darkslategrey: "#2f4f4f",
    darkturquoise: "#00ced1",
    darkviolet: "#9400d3",
    deeppink: "#ff1493",
    deepskyblue: "#00bfff",
    dimgray: "#696969",
    dimgrey: "#696969",
    dodgerblue: "#1e90ff",
    firebrick: "#b22222",
    floralwhite: "#fffaf0",
    forestgreen: "#228b22",
    fuchsia: "#ff00ff",
    gainsboro: "#dcdcdc",
    ghostwhite: "#f8f8ff",
    gold: "#ffd700",
    goldenrod: "#daa520",
    gray: "#808080",
    green: "#008000",
    greenyellow: "#adff2f",
    grey: "#808080",
    honeydew: "#f0fff0",
    hotpink: "#ff69b4",
    indianred: "#cd5c5c",
    indigo: "#4b0082",
    ivory: "#fffff0",
    khaki: "#f0e68c",
    lavender: "#e6e6fa",
    lavenderblush: "#fff0f5",
    lawngreen: "#7cfc00",
    lemonchiffon: "#fffacd",
    lightblue: "#add8e6",
    lightcoral: "#f08080",
    lightcyan: "#e0ffff",
    lightgoldenrodyellow: "#fafad2",
    lightgray: "#d3d3d3",
    lightgreen: "#90ee90",
    lightgrey: "#d3d3d3",
    lightpink: "#ffb6c1",
    lightsalmon: "#ffa07a",
    lightseagreen: "#20b2aa",
    lightskyblue: "#87cefa",
    lightslategray: "#778899",
    lightslategrey: "#778899",
    lightsteelblue: "#b0c4de",
    lightyellow: "#ffffe0",
    lime: "#00ff00",
    limegreen: "#32cd32",
    linen: "#faf0e6",
    magenta: "#ff00ff",
    maroon: "#800000",
    mediumaquamarine: "#66cdaa",
    mediumblue: "#0000cd",
    mediumorchid: "#ba55d3",
    mediumpurple: "#9370db",
    mediumseagreen: "#3cb371",
    mediumslateblue: "#7b68ee",
    mediumspringgreen: "#00fa9a",
    mediumturquoise: "#48d1cc",
    mediumvioletred: "#c71585",
    midnightblue: "#191970",
    mintcream: "#f5fffa",
    mistyrose: "#ffe4e1",
    moccasin: "#ffe4b5",
    navajowhite: "#ffdead",
    navy: "#000080",
    oldlace: "#fdf5e6",
    olive: "#808000",
    olivedrab: "#6b8e23",
    orange: "#ffa500",
    orangered: "#ff4500",
    orchid: "#da70d6",
    palegoldenrod: "#eee8aa",
    palegreen: "#98fb98",
    paleturquoise: "#afeeee",
    palevioletred: "#db7093",
    papayawhip: "#ffefd5",
    peachpuff: "#ffdab9",
    peru: "#cd853f",
    pink: "#ffc0cb",
    plum: "#dda0dd",
    powderblue: "#b0e0e6",
    purple: "#800080",
    rebeccapurple: "#663399",
    red: "#ff0000",
    rosybrown: "#bc8f8f",
    royalblue: "#4169e1",
    saddlebrown: "#8b4513",
    salmon: "#fa8072",
    sandybrown: "#f4a460",
    seagreen: "#2e8b57",
    seashell: "#fff5ee",
    sienna: "#a0522d",
    silver: "#c0c0c0",
    skyblue: "#87ceeb",
    slateblue: "#6a5acd",
    slategray: "#708090",
    slategrey: "#708090",
    snow: "#fffafa",
    springgreen: "#00ff7f",
    tan: "#d2b48c",
    teal: "#008080",
    thistle: "#d8bfd8",
    transparent: "#00000000",
    turquoise: "#40e0d0",
    violet: "#ee82ee",
    wheat: "#f5deb3",
    white: "#ffffff",
    whitesmoke: "#f5f5f5",
    yellow: "#ffff00",
    yellowgreen: "#9acd32"
  },
  /* API */
  parse: (e) => {
    e = e.toLowerCase();
    const t = Ai.colors[e];
    if (t)
      return jr.parse(t);
  },
  stringify: (e) => {
    const t = jr.stringify(e);
    for (const r in Ai.colors)
      if (Ai.colors[r] === t)
        return r;
  }
}, ki = {
  /* VARIABLES */
  re: /^rgba?\(\s*?(-?(?:\d+(?:\.\d+)?|(?:\.\d+))(?:e\d+)?(%?))\s*?(?:,|\s)\s*?(-?(?:\d+(?:\.\d+)?|(?:\.\d+))(?:e\d+)?(%?))\s*?(?:,|\s)\s*?(-?(?:\d+(?:\.\d+)?|(?:\.\d+))(?:e\d+)?(%?))(?:\s*?(?:,|\/)\s*?\+?(-?(?:\d+(?:\.\d+)?|(?:\.\d+))(?:e\d+)?(%?)))?\s*?\)$/i,
  /* API */
  parse: (e) => {
    const t = e.charCodeAt(0);
    if (t !== 114 && t !== 82)
      return;
    const r = e.match(ki.re);
    if (!r)
      return;
    const [, i, s, o, a, n, l, c, h] = r;
    return xo.set({
      r: nt.channel.clamp.r(s ? parseFloat(i) * 2.55 : parseFloat(i)),
      g: nt.channel.clamp.g(a ? parseFloat(o) * 2.55 : parseFloat(o)),
      b: nt.channel.clamp.b(l ? parseFloat(n) * 2.55 : parseFloat(n)),
      a: c ? nt.channel.clamp.a(h ? parseFloat(c) / 100 : parseFloat(c)) : 1
    }, e);
  },
  stringify: (e) => {
    const { r: t, g: r, b: i, a: s } = e;
    return s < 1 ? `rgba(${nt.lang.round(t)}, ${nt.lang.round(r)}, ${nt.lang.round(i)}, ${nt.lang.round(s)})` : `rgb(${nt.lang.round(t)}, ${nt.lang.round(r)}, ${nt.lang.round(i)})`;
  }
}, Le = {
  /* VARIABLES */
  format: {
    keyword: Ai,
    hex: jr,
    rgb: ki,
    rgba: ki,
    hsl: fr,
    hsla: fr
  },
  /* API */
  parse: (e) => {
    if (typeof e != "string")
      return e;
    const t = jr.parse(e) || ki.parse(e) || fr.parse(e) || Ai.parse(e);
    if (t)
      return t;
    throw new Error(`Unsupported color format: "${e}"`);
  },
  stringify: (e) => !e.changed && e.color ? e.color : e.type.is(zt.HSL) || e.data.r === void 0 ? fr.stringify(e) : e.a < 1 || !Number.isInteger(e.r) || !Number.isInteger(e.g) || !Number.isInteger(e.b) ? ki.stringify(e) : jr.stringify(e)
}, Hc = (e, t) => {
  const r = Le.parse(e);
  for (const i in t)
    r[i] = nt.channel.clamp[i](t[i]);
  return Le.stringify(r);
}, Je = (e, t, r = 0, i = 1) => {
  if (typeof e != "number")
    return Hc(e, { a: t });
  const s = xo.set({
    r: nt.channel.clamp.r(e),
    g: nt.channel.clamp.g(t),
    b: nt.channel.clamp.b(r),
    a: nt.channel.clamp.a(i)
  });
  return Le.stringify(s);
}, Ey = (e) => {
  const { r: t, g: r, b: i } = Le.parse(e), s = 0.2126 * nt.channel.toLinear(t) + 0.7152 * nt.channel.toLinear(r) + 0.0722 * nt.channel.toLinear(i);
  return nt.lang.round(s);
}, $y = (e) => Ey(e) >= 0.5, be = (e) => !$y(e), Yc = (e, t, r) => {
  const i = Le.parse(e), s = i[t], o = nt.channel.clamp[t](s + r);
  return s !== o && (i[t] = o), Le.stringify(i);
}, $ = (e, t) => Yc(e, "l", t), A = (e, t) => Yc(e, "l", -t), C = (e, t) => {
  const r = Le.parse(e), i = {};
  for (const s in t)
    t[s] && (i[s] = r[s] + t[s]);
  return Hc(e, i);
}, Oy = (e, t, r = 50) => {
  const { r: i, g: s, b: o, a } = Le.parse(e), { r: n, g: l, b: c, a: h } = Le.parse(t), u = r / 100, p = u * 2 - 1, d = a - h, m = ((p * d === -1 ? p : (p + d) / (1 + p * d)) + 1) / 2, y = 1 - m, x = i * m + n * y, b = s * m + l * y, k = o * m + c * y, w = a * u + h * (1 - u);
  return Je(x, b, k, w);
}, _ = (e, t = 100) => {
  const r = Le.parse(e);
  return r.r = 255 - r.r, r.g = 255 - r.g, r.b = 255 - r.b, Oy(r, e, t);
};
/*! @license DOMPurify 3.4.1 | (c) Cure53 and other contributors | Released under the Apache license 2.0 and Mozilla Public License 2.0 | github.com/cure53/DOMPurify/blob/3.4.1/LICENSE */
const {
  entries: jc,
  setPrototypeOf: Ul,
  isFrozen: Iy,
  getPrototypeOf: Dy,
  getOwnPropertyDescriptor: Py
} = Object;
let {
  freeze: Xt,
  seal: le,
  create: Nr
} = Object, {
  apply: wa,
  construct: Sa
} = typeof Reflect < "u" && Reflect;
Xt || (Xt = function(t) {
  return t;
});
le || (le = function(t) {
  return t;
});
wa || (wa = function(t, r) {
  for (var i = arguments.length, s = new Array(i > 2 ? i - 2 : 0), o = 2; o < i; o++)
    s[o - 2] = arguments[o];
  return t.apply(r, s);
});
Sa || (Sa = function(t) {
  for (var r = arguments.length, i = new Array(r > 1 ? r - 1 : 0), s = 1; s < r; s++)
    i[s - 1] = arguments[s];
  return new t(...i);
});
const hi = At(Array.prototype.forEach), Ry = At(Array.prototype.lastIndexOf), Gl = At(Array.prototype.pop), ci = At(Array.prototype.push), Ny = At(Array.prototype.splice), jt = Array.isArray, Ti = At(String.prototype.toLowerCase), ra = At(String.prototype.toString), Xl = At(String.prototype.match), Ir = At(String.prototype.replace), Vl = At(String.prototype.indexOf), qy = At(String.prototype.trim), zy = At(Number.prototype.toString), Wy = At(Boolean.prototype.toString), Zl = typeof BigInt > "u" ? null : At(BigInt.prototype.toString), Kl = typeof Symbol > "u" ? null : At(Symbol.prototype.toString), _t = At(Object.prototype.hasOwnProperty), ui = At(Object.prototype.toString), Pt = At(RegExp.prototype.test), ds = Hy(TypeError);
function At(e) {
  return function(t) {
    t instanceof RegExp && (t.lastIndex = 0);
    for (var r = arguments.length, i = new Array(r > 1 ? r - 1 : 0), s = 1; s < r; s++)
      i[s - 1] = arguments[s];
    return wa(e, t, i);
  };
}
function Hy(e) {
  return function() {
    for (var t = arguments.length, r = new Array(t), i = 0; i < t; i++)
      r[i] = arguments[i];
    return Sa(e, r);
  };
}
function lt(e, t) {
  let r = arguments.length > 2 && arguments[2] !== void 0 ? arguments[2] : Ti;
  if (Ul && Ul(e, null), !jt(t))
    return e;
  let i = t.length;
  for (; i--; ) {
    let s = t[i];
    if (typeof s == "string") {
      const o = r(s);
      o !== s && (Iy(t) || (t[i] = o), s = o);
    }
    e[s] = !0;
  }
  return e;
}
function Yy(e) {
  for (let t = 0; t < e.length; t++)
    _t(e, t) || (e[t] = null);
  return e;
}
function Qt(e) {
  const t = Nr(null);
  for (const [r, i] of jc(e))
    _t(e, r) && (jt(i) ? t[r] = Yy(i) : i && typeof i == "object" && i.constructor === Object ? t[r] = Qt(i) : t[r] = i);
  return t;
}
function jy(e) {
  switch (typeof e) {
    case "string":
      return e;
    case "number":
      return zy(e);
    case "boolean":
      return Wy(e);
    case "bigint":
      return Zl ? Zl(e) : "0";
    case "symbol":
      return Kl ? Kl(e) : "Symbol()";
    case "undefined":
      return ui(e);
    case "function":
    case "object": {
      if (e === null)
        return ui(e);
      const t = e, r = qr(t, "toString");
      if (typeof r == "function") {
        const i = r(t);
        return typeof i == "string" ? i : ui(i);
      }
      return ui(e);
    }
    default:
      return ui(e);
  }
}
function qr(e, t) {
  for (; e !== null; ) {
    const i = Py(e, t);
    if (i) {
      if (i.get)
        return At(i.get);
      if (typeof i.value == "function")
        return At(i.value);
    }
    e = Dy(e);
  }
  function r() {
    return null;
  }
  return r;
}
function Uy(e) {
  try {
    return Pt(e, ""), !0;
  } catch {
    return !1;
  }
}
const Ql = Xt(["a", "abbr", "acronym", "address", "area", "article", "aside", "audio", "b", "bdi", "bdo", "big", "blink", "blockquote", "body", "br", "button", "canvas", "caption", "center", "cite", "code", "col", "colgroup", "content", "data", "datalist", "dd", "decorator", "del", "details", "dfn", "dialog", "dir", "div", "dl", "dt", "element", "em", "fieldset", "figcaption", "figure", "font", "footer", "form", "h1", "h2", "h3", "h4", "h5", "h6", "head", "header", "hgroup", "hr", "html", "i", "img", "input", "ins", "kbd", "label", "legend", "li", "main", "map", "mark", "marquee", "menu", "menuitem", "meter", "nav", "nobr", "ol", "optgroup", "option", "output", "p", "picture", "pre", "progress", "q", "rp", "rt", "ruby", "s", "samp", "search", "section", "select", "shadow", "slot", "small", "source", "spacer", "span", "strike", "strong", "style", "sub", "summary", "sup", "table", "tbody", "td", "template", "textarea", "tfoot", "th", "thead", "time", "tr", "track", "tt", "u", "ul", "var", "video", "wbr"]), ia = Xt(["svg", "a", "altglyph", "altglyphdef", "altglyphitem", "animatecolor", "animatemotion", "animatetransform", "circle", "clippath", "defs", "desc", "ellipse", "enterkeyhint", "exportparts", "filter", "font", "g", "glyph", "glyphref", "hkern", "image", "inputmode", "line", "lineargradient", "marker", "mask", "metadata", "mpath", "part", "path", "pattern", "polygon", "polyline", "radialgradient", "rect", "stop", "style", "switch", "symbol", "text", "textpath", "title", "tref", "tspan", "view", "vkern"]), sa = Xt(["feBlend", "feColorMatrix", "feComponentTransfer", "feComposite", "feConvolveMatrix", "feDiffuseLighting", "feDisplacementMap", "feDistantLight", "feDropShadow", "feFlood", "feFuncA", "feFuncB", "feFuncG", "feFuncR", "feGaussianBlur", "feImage", "feMerge", "feMergeNode", "feMorphology", "feOffset", "fePointLight", "feSpecularLighting", "feSpotLight", "feTile", "feTurbulence"]), Gy = Xt(["animate", "color-profile", "cursor", "discard", "font-face", "font-face-format", "font-face-name", "font-face-src", "font-face-uri", "foreignobject", "hatch", "hatchpath", "mesh", "meshgradient", "meshpatch", "meshrow", "missing-glyph", "script", "set", "solidcolor", "unknown", "use"]), oa = Xt(["math", "menclose", "merror", "mfenced", "mfrac", "mglyph", "mi", "mlabeledtr", "mmultiscripts", "mn", "mo", "mover", "mpadded", "mphantom", "mroot", "mrow", "ms", "mspace", "msqrt", "mstyle", "msub", "msup", "msubsup", "mtable", "mtd", "mtext", "mtr", "munder", "munderover", "mprescripts"]), Xy = Xt(["maction", "maligngroup", "malignmark", "mlongdiv", "mscarries", "mscarry", "msgroup", "mstack", "msline", "msrow", "semantics", "annotation", "annotation-xml", "mprescripts", "none"]), Jl = Xt(["#text"]), th = Xt(["accept", "action", "align", "alt", "autocapitalize", "autocomplete", "autopictureinpicture", "autoplay", "background", "bgcolor", "border", "capture", "cellpadding", "cellspacing", "checked", "cite", "class", "clear", "color", "cols", "colspan", "controls", "controlslist", "coords", "crossorigin", "datetime", "decoding", "default", "dir", "disabled", "disablepictureinpicture", "disableremoteplayback", "download", "draggable", "enctype", "enterkeyhint", "exportparts", "face", "for", "headers", "height", "hidden", "high", "href", "hreflang", "id", "inert", "inputmode", "integrity", "ismap", "kind", "label", "lang", "list", "loading", "loop", "low", "max", "maxlength", "media", "method", "min", "minlength", "multiple", "muted", "name", "nonce", "noshade", "novalidate", "nowrap", "open", "optimum", "part", "pattern", "placeholder", "playsinline", "popover", "popovertarget", "popovertargetaction", "poster", "preload", "pubdate", "radiogroup", "readonly", "rel", "required", "rev", "reversed", "role", "rows", "rowspan", "spellcheck", "scope", "selected", "shape", "size", "sizes", "slot", "span", "srclang", "start", "src", "srcset", "step", "style", "summary", "tabindex", "title", "translate", "type", "usemap", "valign", "value", "width", "wrap", "xmlns"]), aa = Xt(["accent-height", "accumulate", "additive", "alignment-baseline", "amplitude", "ascent", "attributename", "attributetype", "azimuth", "basefrequency", "baseline-shift", "begin", "bias", "by", "class", "clip", "clippathunits", "clip-path", "clip-rule", "color", "color-interpolation", "color-interpolation-filters", "color-profile", "color-rendering", "cx", "cy", "d", "dx", "dy", "diffuseconstant", "direction", "display", "divisor", "dur", "edgemode", "elevation", "end", "exponent", "fill", "fill-opacity", "fill-rule", "filter", "filterunits", "flood-color", "flood-opacity", "font-family", "font-size", "font-size-adjust", "font-stretch", "font-style", "font-variant", "font-weight", "fx", "fy", "g1", "g2", "glyph-name", "glyphref", "gradientunits", "gradienttransform", "height", "href", "id", "image-rendering", "in", "in2", "intercept", "k", "k1", "k2", "k3", "k4", "kerning", "keypoints", "keysplines", "keytimes", "lang", "lengthadjust", "letter-spacing", "kernelmatrix", "kernelunitlength", "lighting-color", "local", "marker-end", "marker-mid", "marker-start", "markerheight", "markerunits", "markerwidth", "maskcontentunits", "maskunits", "max", "mask", "mask-type", "media", "method", "mode", "min", "name", "numoctaves", "offset", "operator", "opacity", "order", "orient", "orientation", "origin", "overflow", "paint-order", "path", "pathlength", "patterncontentunits", "patterntransform", "patternunits", "points", "preservealpha", "preserveaspectratio", "primitiveunits", "r", "rx", "ry", "radius", "refx", "refy", "repeatcount", "repeatdur", "restart", "result", "rotate", "scale", "seed", "shape-rendering", "slope", "specularconstant", "specularexponent", "spreadmethod", "startoffset", "stddeviation", "stitchtiles", "stop-color", "stop-opacity", "stroke-dasharray", "stroke-dashoffset", "stroke-linecap", "stroke-linejoin", "stroke-miterlimit", "stroke-opacity", "stroke", "stroke-width", "style", "surfacescale", "systemlanguage", "tabindex", "tablevalues", "targetx", "targety", "transform", "transform-origin", "text-anchor", "text-decoration", "text-rendering", "textlength", "type", "u1", "u2", "unicode", "values", "viewbox", "visibility", "version", "vert-adv-y", "vert-origin-x", "vert-origin-y", "width", "word-spacing", "wrap", "writing-mode", "xchannelselector", "ychannelselector", "x", "x1", "x2", "xmlns", "y", "y1", "y2", "z", "zoomandpan"]), eh = Xt(["accent", "accentunder", "align", "bevelled", "close", "columnalign", "columnlines", "columnspacing", "columnspan", "denomalign", "depth", "dir", "display", "displaystyle", "encoding", "fence", "frame", "height", "href", "id", "largeop", "length", "linethickness", "lquote", "lspace", "mathbackground", "mathcolor", "mathsize", "mathvariant", "maxsize", "minsize", "movablelimits", "notation", "numalign", "open", "rowalign", "rowlines", "rowspacing", "rowspan", "rspace", "rquote", "scriptlevel", "scriptminsize", "scriptsizemultiplier", "selection", "separator", "separators", "stretchy", "subscriptshift", "supscriptshift", "symmetric", "voffset", "width", "xmlns"]), ps = Xt(["xlink:href", "xml:id", "xlink:title", "xml:space", "xmlns:xlink"]), Vy = le(/\{\{[\w\W]*|[\w\W]*\}\}/gm), Zy = le(/<%[\w\W]*|[\w\W]*%>/gm), Ky = le(/\$\{[\w\W]*/gm), Qy = le(/^data-[\-\w.\u00B7-\uFFFF]+$/), Jy = le(/^aria-[\-\w]+$/), Uc = le(
  /^(?:(?:(?:f|ht)tps?|mailto|tel|callto|sms|cid|xmpp|matrix):|[^a-z]|[a-z+.\-]+(?:[^a-z+.\-:]|$))/i
  // eslint-disable-line no-useless-escape
), t0 = le(/^(?:\w+script|data):/i), e0 = le(
  /[\u0000-\u0020\u00A0\u1680\u180E\u2000-\u2029\u205F\u3000]/g
  // eslint-disable-line no-control-regex
), Gc = le(/^html$/i), r0 = le(/^[a-z][.\w]*(-[.\w]+)+$/i);
var rh = /* @__PURE__ */ Object.freeze({
  __proto__: null,
  ARIA_ATTR: Jy,
  ATTR_WHITESPACE: e0,
  CUSTOM_ELEMENT: r0,
  DATA_ATTR: Qy,
  DOCTYPE_NAME: Gc,
  ERB_EXPR: Zy,
  IS_ALLOWED_URI: Uc,
  IS_SCRIPT_OR_DATA: t0,
  MUSTACHE_EXPR: Vy,
  TMPLIT_EXPR: Ky
});
const di = {
  element: 1,
  text: 3,
  // Deprecated
  progressingInstruction: 7,
  comment: 8,
  document: 9
}, i0 = function() {
  return typeof window > "u" ? null : window;
}, s0 = function(t, r) {
  if (typeof t != "object" || typeof t.createPolicy != "function")
    return null;
  let i = null;
  const s = "data-tt-policy-suffix";
  r && r.hasAttribute(s) && (i = r.getAttribute(s));
  const o = "dompurify" + (i ? "#" + i : "");
  try {
    return t.createPolicy(o, {
      createHTML(a) {
        return a;
      },
      createScriptURL(a) {
        return a;
      }
    });
  } catch {
    return console.warn("TrustedTypes policy " + o + " could not be created."), null;
  }
}, ih = function() {
  return {
    afterSanitizeAttributes: [],
    afterSanitizeElements: [],
    afterSanitizeShadowDOM: [],
    beforeSanitizeAttributes: [],
    beforeSanitizeElements: [],
    beforeSanitizeShadowDOM: [],
    uponSanitizeAttribute: [],
    uponSanitizeElement: [],
    uponSanitizeShadowNode: []
  };
};
function Xc() {
  let e = arguments.length > 0 && arguments[0] !== void 0 ? arguments[0] : i0();
  const t = (J) => Xc(J);
  if (t.version = "3.4.1", t.removed = [], !e || !e.document || e.document.nodeType !== di.document || !e.Element)
    return t.isSupported = !1, t;
  let {
    document: r
  } = e;
  const i = r, s = i.currentScript, {
    DocumentFragment: o,
    HTMLTemplateElement: a,
    Node: n,
    Element: l,
    NodeFilter: c,
    NamedNodeMap: h = e.NamedNodeMap || e.MozNamedAttrMap,
    HTMLFormElement: u,
    DOMParser: p,
    trustedTypes: d
  } = e, g = l.prototype, m = qr(g, "cloneNode"), y = qr(g, "remove"), x = qr(g, "nextSibling"), b = qr(g, "childNodes"), k = qr(g, "parentNode");
  if (typeof a == "function") {
    const J = r.createElement("template");
    J.content && J.content.ownerDocument && (r = J.content.ownerDocument);
  }
  let w, S = "";
  const {
    implementation: v,
    createNodeIterator: M,
    createDocumentFragment: B,
    getElementsByTagName: N
  } = r, {
    importNode: D
  } = i;
  let O = ih();
  t.isSupported = typeof jc == "function" && typeof k == "function" && v && v.createHTMLDocument !== void 0;
  const {
    MUSTACHE_EXPR: W,
    ERB_EXPR: z,
    TMPLIT_EXPR: I,
    DATA_ATTR: F,
    ARIA_ATTR: L,
    IS_SCRIPT_OR_DATA: E,
    ATTR_WHITESPACE: P,
    CUSTOM_ELEMENT: H
  } = rh;
  let {
    IS_ALLOWED_URI: Y
  } = rh, Q = null;
  const dt = lt({}, [...Ql, ...ia, ...sa, ...oa, ...Jl]);
  let et = null;
  const ut = lt({}, [...th, ...aa, ...eh, ...ps]);
  let it = Object.seal(Nr(null, {
    tagNameCheck: {
      writable: !0,
      configurable: !1,
      enumerable: !0,
      value: null
    },
    attributeNameCheck: {
      writable: !0,
      configurable: !1,
      enumerable: !0,
      value: null
    },
    allowCustomizedBuiltInElements: {
      writable: !0,
      configurable: !1,
      enumerable: !0,
      value: !1
    }
  })), rt = null, ht = null;
  const ft = Object.seal(Nr(null, {
    tagCheck: {
      writable: !0,
      configurable: !1,
      enumerable: !0,
      value: null
    },
    attributeCheck: {
      writable: !0,
      configurable: !1,
      enumerable: !0,
      value: null
    }
  }));
  let bt = !0, Ct = !0, Bt = !1, ce = !0, re = !1, Oe = !0, nr = !1, Ho = !1, Yo = !1, Mr = !1, ls = !1, hs = !1, Bl = !0, Ll = !1;
  const Fl = "user-content-";
  let jo = !0, ni = !1, Er = {}, Te = null;
  const Uo = lt({}, ["annotation-xml", "audio", "colgroup", "desc", "foreignobject", "head", "iframe", "math", "mi", "mn", "mo", "ms", "mtext", "noembed", "noframes", "noscript", "plaintext", "script", "style", "svg", "template", "thead", "title", "video", "xmp"]);
  let Al = null;
  const Ml = lt({}, ["audio", "video", "img", "source", "image", "track"]);
  let Go = null;
  const El = lt({}, ["alt", "class", "for", "id", "label", "name", "pattern", "placeholder", "role", "summary", "title", "value", "style", "xmlns"]), cs = "http://www.w3.org/1998/Math/MathML", us = "http://www.w3.org/2000/svg", we = "http://www.w3.org/1999/xhtml";
  let $r = we, Xo = !1, Vo = null;
  const gy = lt({}, [cs, us, we], ra);
  let Zo = lt({}, ["mi", "mo", "mn", "ms", "mtext"]), Ko = lt({}, ["annotation-xml"]);
  const my = lt({}, ["title", "style", "font", "a", "script"]);
  let li = null;
  const yy = ["application/xhtml+xml", "text/html"], Cy = "text/html";
  let Mt = null, Or = null;
  const xy = r.createElement("form"), $l = function(T) {
    return T instanceof RegExp || T instanceof Function;
  }, Qo = function() {
    let T = arguments.length > 0 && arguments[0] !== void 0 ? arguments[0] : {};
    if (Or && Or === T)
      return;
    (!T || typeof T != "object") && (T = {}), T = Qt(T), li = // eslint-disable-next-line unicorn/prefer-includes
    yy.indexOf(T.PARSER_MEDIA_TYPE) === -1 ? Cy : T.PARSER_MEDIA_TYPE, Mt = li === "application/xhtml+xml" ? ra : Ti, Q = _t(T, "ALLOWED_TAGS") && jt(T.ALLOWED_TAGS) ? lt({}, T.ALLOWED_TAGS, Mt) : dt, et = _t(T, "ALLOWED_ATTR") && jt(T.ALLOWED_ATTR) ? lt({}, T.ALLOWED_ATTR, Mt) : ut, Vo = _t(T, "ALLOWED_NAMESPACES") && jt(T.ALLOWED_NAMESPACES) ? lt({}, T.ALLOWED_NAMESPACES, ra) : gy, Go = _t(T, "ADD_URI_SAFE_ATTR") && jt(T.ADD_URI_SAFE_ATTR) ? lt(Qt(El), T.ADD_URI_SAFE_ATTR, Mt) : El, Al = _t(T, "ADD_DATA_URI_TAGS") && jt(T.ADD_DATA_URI_TAGS) ? lt(Qt(Ml), T.ADD_DATA_URI_TAGS, Mt) : Ml, Te = _t(T, "FORBID_CONTENTS") && jt(T.FORBID_CONTENTS) ? lt({}, T.FORBID_CONTENTS, Mt) : Uo, rt = _t(T, "FORBID_TAGS") && jt(T.FORBID_TAGS) ? lt({}, T.FORBID_TAGS, Mt) : Qt({}), ht = _t(T, "FORBID_ATTR") && jt(T.FORBID_ATTR) ? lt({}, T.FORBID_ATTR, Mt) : Qt({}), Er = _t(T, "USE_PROFILES") ? T.USE_PROFILES && typeof T.USE_PROFILES == "object" ? Qt(T.USE_PROFILES) : T.USE_PROFILES : !1, bt = T.ALLOW_ARIA_ATTR !== !1, Ct = T.ALLOW_DATA_ATTR !== !1, Bt = T.ALLOW_UNKNOWN_PROTOCOLS || !1, ce = T.ALLOW_SELF_CLOSE_IN_ATTR !== !1, re = T.SAFE_FOR_TEMPLATES || !1, Oe = T.SAFE_FOR_XML !== !1, nr = T.WHOLE_DOCUMENT || !1, Mr = T.RETURN_DOM || !1, ls = T.RETURN_DOM_FRAGMENT || !1, hs = T.RETURN_TRUSTED_TYPE || !1, Yo = T.FORCE_BODY || !1, Bl = T.SANITIZE_DOM !== !1, Ll = T.SANITIZE_NAMED_PROPS || !1, jo = T.KEEP_CONTENT !== !1, ni = T.IN_PLACE || !1, Y = Uy(T.ALLOWED_URI_REGEXP) ? T.ALLOWED_URI_REGEXP : Uc, $r = typeof T.NAMESPACE == "string" ? T.NAMESPACE : we, Zo = _t(T, "MATHML_TEXT_INTEGRATION_POINTS") && T.MATHML_TEXT_INTEGRATION_POINTS && typeof T.MATHML_TEXT_INTEGRATION_POINTS == "object" ? Qt(T.MATHML_TEXT_INTEGRATION_POINTS) : lt({}, ["mi", "mo", "mn", "ms", "mtext"]), Ko = _t(T, "HTML_INTEGRATION_POINTS") && T.HTML_INTEGRATION_POINTS && typeof T.HTML_INTEGRATION_POINTS == "object" ? Qt(T.HTML_INTEGRATION_POINTS) : lt({}, ["annotation-xml"]);
    const q = _t(T, "CUSTOM_ELEMENT_HANDLING") && T.CUSTOM_ELEMENT_HANDLING && typeof T.CUSTOM_ELEMENT_HANDLING == "object" ? Qt(T.CUSTOM_ELEMENT_HANDLING) : Nr(null);
    if (it = Nr(null), _t(q, "tagNameCheck") && $l(q.tagNameCheck) && (it.tagNameCheck = q.tagNameCheck), _t(q, "attributeNameCheck") && $l(q.attributeNameCheck) && (it.attributeNameCheck = q.attributeNameCheck), _t(q, "allowCustomizedBuiltInElements") && typeof q.allowCustomizedBuiltInElements == "boolean" && (it.allowCustomizedBuiltInElements = q.allowCustomizedBuiltInElements), re && (Ct = !1), ls && (Mr = !0), Er && (Q = lt({}, Jl), et = Nr(null), Er.html === !0 && (lt(Q, Ql), lt(et, th)), Er.svg === !0 && (lt(Q, ia), lt(et, aa), lt(et, ps)), Er.svgFilters === !0 && (lt(Q, sa), lt(et, aa), lt(et, ps)), Er.mathMl === !0 && (lt(Q, oa), lt(et, eh), lt(et, ps))), ft.tagCheck = null, ft.attributeCheck = null, _t(T, "ADD_TAGS") && (typeof T.ADD_TAGS == "function" ? ft.tagCheck = T.ADD_TAGS : jt(T.ADD_TAGS) && (Q === dt && (Q = Qt(Q)), lt(Q, T.ADD_TAGS, Mt))), _t(T, "ADD_ATTR") && (typeof T.ADD_ATTR == "function" ? ft.attributeCheck = T.ADD_ATTR : jt(T.ADD_ATTR) && (et === ut && (et = Qt(et)), lt(et, T.ADD_ATTR, Mt))), _t(T, "ADD_URI_SAFE_ATTR") && jt(T.ADD_URI_SAFE_ATTR) && lt(Go, T.ADD_URI_SAFE_ATTR, Mt), _t(T, "FORBID_CONTENTS") && jt(T.FORBID_CONTENTS) && (Te === Uo && (Te = Qt(Te)), lt(Te, T.FORBID_CONTENTS, Mt)), _t(T, "ADD_FORBID_CONTENTS") && jt(T.ADD_FORBID_CONTENTS) && (Te === Uo && (Te = Qt(Te)), lt(Te, T.ADD_FORBID_CONTENTS, Mt)), jo && (Q["#text"] = !0), nr && lt(Q, ["html", "head", "body"]), Q.table && (lt(Q, ["tbody"]), delete rt.tbody), T.TRUSTED_TYPES_POLICY) {
      if (typeof T.TRUSTED_TYPES_POLICY.createHTML != "function")
        throw ds('TRUSTED_TYPES_POLICY configuration option must provide a "createHTML" hook.');
      if (typeof T.TRUSTED_TYPES_POLICY.createScriptURL != "function")
        throw ds('TRUSTED_TYPES_POLICY configuration option must provide a "createScriptURL" hook.');
      w = T.TRUSTED_TYPES_POLICY, S = w.createHTML("");
    } else
      w === void 0 && (w = s0(d, s)), w !== null && typeof S == "string" && (S = w.createHTML(""));
    Xt && Xt(T), Or = T;
  }, Ol = lt({}, [...ia, ...sa, ...Gy]), Il = lt({}, [...oa, ...Xy]), by = function(T) {
    let q = k(T);
    (!q || !q.tagName) && (q = {
      namespaceURI: $r,
      tagName: "template"
    });
    const G = Ti(T.tagName), kt = Ti(q.tagName);
    return Vo[T.namespaceURI] ? T.namespaceURI === us ? q.namespaceURI === we ? G === "svg" : q.namespaceURI === cs ? G === "svg" && (kt === "annotation-xml" || Zo[kt]) : !!Ol[G] : T.namespaceURI === cs ? q.namespaceURI === we ? G === "math" : q.namespaceURI === us ? G === "math" && Ko[kt] : !!Il[G] : T.namespaceURI === we ? q.namespaceURI === us && !Ko[kt] || q.namespaceURI === cs && !Zo[kt] ? !1 : !Il[G] && (my[G] || !Ol[G]) : !!(li === "application/xhtml+xml" && Vo[T.namespaceURI]) : !1;
  }, ue = function(T) {
    ci(t.removed, {
      element: T
    });
    try {
      k(T).removeChild(T);
    } catch {
      y(T);
    }
  }, lr = function(T, q) {
    try {
      ci(t.removed, {
        attribute: q.getAttributeNode(T),
        from: q
      });
    } catch {
      ci(t.removed, {
        attribute: null,
        from: q
      });
    }
    if (q.removeAttribute(T), T === "is")
      if (Mr || ls)
        try {
          ue(q);
        } catch {
        }
      else
        try {
          q.setAttribute(T, "");
        } catch {
        }
  }, Dl = function(T) {
    let q = null, G = null;
    if (Yo)
      T = "<remove></remove>" + T;
    else {
      const Lt = Xl(T, /^[\r\n\t ]+/);
      G = Lt && Lt[0];
    }
    li === "application/xhtml+xml" && $r === we && (T = '<html xmlns="http://www.w3.org/1999/xhtml"><head></head><body>' + T + "</body></html>");
    const kt = w ? w.createHTML(T) : T;
    if ($r === we)
      try {
        q = new p().parseFromString(kt, li);
      } catch {
      }
    if (!q || !q.documentElement) {
      q = v.createDocument($r, "template", null);
      try {
        q.documentElement.innerHTML = Xo ? S : kt;
      } catch {
      }
    }
    const qt = q.body || q.documentElement;
    return T && G && qt.insertBefore(r.createTextNode(G), qt.childNodes[0] || null), $r === we ? N.call(q, nr ? "html" : "body")[0] : nr ? q.documentElement : qt;
  }, Pl = function(T) {
    return M.call(
      T.ownerDocument || T,
      T,
      // eslint-disable-next-line no-bitwise
      c.SHOW_ELEMENT | c.SHOW_COMMENT | c.SHOW_TEXT | c.SHOW_PROCESSING_INSTRUCTION | c.SHOW_CDATA_SECTION,
      null
    );
  }, Jo = function(T) {
    return T instanceof u && (typeof T.nodeName != "string" || typeof T.textContent != "string" || typeof T.removeChild != "function" || !(T.attributes instanceof h) || typeof T.removeAttribute != "function" || typeof T.setAttribute != "function" || typeof T.namespaceURI != "string" || typeof T.insertBefore != "function" || typeof T.hasChildNodes != "function");
  }, ta = function(T) {
    return typeof n == "function" && T instanceof n;
  };
  function Ie(J, T, q) {
    hi(J, (G) => {
      G.call(t, T, q, Or);
    });
  }
  const Rl = function(T) {
    let q = null;
    if (Ie(O.beforeSanitizeElements, T, null), Jo(T))
      return ue(T), !0;
    const G = Mt(T.nodeName);
    if (Ie(O.uponSanitizeElement, T, {
      tagName: G,
      allowedTags: Q
    }), Oe && T.hasChildNodes() && !ta(T.firstElementChild) && Pt(/<[/\w!]/g, T.innerHTML) && Pt(/<[/\w!]/g, T.textContent) || Oe && T.namespaceURI === we && G === "style" && ta(T.firstElementChild) || T.nodeType === di.progressingInstruction || Oe && T.nodeType === di.comment && Pt(/<[/\w]/g, T.data))
      return ue(T), !0;
    if (rt[G] || !(ft.tagCheck instanceof Function && ft.tagCheck(G)) && !Q[G]) {
      if (!rt[G] && ql(G) && (it.tagNameCheck instanceof RegExp && Pt(it.tagNameCheck, G) || it.tagNameCheck instanceof Function && it.tagNameCheck(G)))
        return !1;
      if (jo && !Te[G]) {
        const kt = k(T) || T.parentNode, qt = b(T) || T.childNodes;
        if (qt && kt) {
          const Lt = qt.length;
          for (let Zt = Lt - 1; Zt >= 0; --Zt) {
            const ae = m(qt[Zt], !0);
            kt.insertBefore(ae, x(T));
          }
        }
      }
      return ue(T), !0;
    }
    return T instanceof l && !by(T) || (G === "noscript" || G === "noembed" || G === "noframes") && Pt(/<\/no(script|embed|frames)/i, T.innerHTML) ? (ue(T), !0) : (re && T.nodeType === di.text && (q = T.textContent, hi([W, z, I], (kt) => {
      q = Ir(q, kt, " ");
    }), T.textContent !== q && (ci(t.removed, {
      element: T.cloneNode()
    }), T.textContent = q)), Ie(O.afterSanitizeElements, T, null), !1);
  }, Nl = function(T, q, G) {
    if (ht[q] || Bl && (q === "id" || q === "name") && (G in r || G in xy))
      return !1;
    if (!(Ct && !ht[q] && Pt(F, q))) {
      if (!(bt && Pt(L, q))) {
        if (!(ft.attributeCheck instanceof Function && ft.attributeCheck(q, T))) {
          if (!et[q] || ht[q]) {
            if (
              // First condition does a very basic check if a) it's basically a valid custom element tagname AND
              // b) if the tagName passes whatever the user has configured for CUSTOM_ELEMENT_HANDLING.tagNameCheck
              // and c) if the attribute name passes whatever the user has configured for CUSTOM_ELEMENT_HANDLING.attributeNameCheck
              !(ql(T) && (it.tagNameCheck instanceof RegExp && Pt(it.tagNameCheck, T) || it.tagNameCheck instanceof Function && it.tagNameCheck(T)) && (it.attributeNameCheck instanceof RegExp && Pt(it.attributeNameCheck, q) || it.attributeNameCheck instanceof Function && it.attributeNameCheck(q, T)) || // Alternative, second condition checks if it's an `is`-attribute, AND
              // the value passes whatever the user has configured for CUSTOM_ELEMENT_HANDLING.tagNameCheck
              q === "is" && it.allowCustomizedBuiltInElements && (it.tagNameCheck instanceof RegExp && Pt(it.tagNameCheck, G) || it.tagNameCheck instanceof Function && it.tagNameCheck(G)))
            ) return !1;
          } else if (!Go[q]) {
            if (!Pt(Y, Ir(G, P, ""))) {
              if (!((q === "src" || q === "xlink:href" || q === "href") && T !== "script" && Vl(G, "data:") === 0 && Al[T])) {
                if (!(Bt && !Pt(E, Ir(G, P, "")))) {
                  if (G)
                    return !1;
                }
              }
            }
          }
        }
      }
    }
    return !0;
  }, ky = lt({}, ["annotation-xml", "color-profile", "font-face", "font-face-format", "font-face-name", "font-face-src", "font-face-uri", "missing-glyph"]), ql = function(T) {
    return !ky[Ti(T)] && Pt(H, T);
  }, zl = function(T) {
    Ie(O.beforeSanitizeAttributes, T, null);
    const {
      attributes: q
    } = T;
    if (!q || Jo(T))
      return;
    const G = {
      attrName: "",
      attrValue: "",
      keepAttr: !0,
      allowedAttributes: et,
      forceKeepAttr: void 0
    };
    let kt = q.length;
    for (; kt--; ) {
      const qt = q[kt], {
        name: Lt,
        namespaceURI: Zt,
        value: ae
      } = qt, de = Mt(Lt), ea = ae;
      let It = Lt === "value" ? ea : qy(ea);
      if (G.attrName = de, G.attrValue = It, G.keepAttr = !0, G.forceKeepAttr = void 0, Ie(O.uponSanitizeAttribute, T, G), It = G.attrValue, Ll && (de === "id" || de === "name") && Vl(It, Fl) !== 0 && (lr(Lt, T), It = Fl + It), Oe && Pt(/((--!?|])>)|<\/(style|script|title|xmp|textarea|noscript|iframe|noembed|noframes)/i, It)) {
        lr(Lt, T);
        continue;
      }
      if (de === "attributename" && Xl(It, "href")) {
        lr(Lt, T);
        continue;
      }
      if (G.forceKeepAttr)
        continue;
      if (!G.keepAttr) {
        lr(Lt, T);
        continue;
      }
      if (!ce && Pt(/\/>/i, It)) {
        lr(Lt, T);
        continue;
      }
      re && hi([W, z, I], (Yl) => {
        It = Ir(It, Yl, " ");
      });
      const Hl = Mt(T.nodeName);
      if (!Nl(Hl, de, It)) {
        lr(Lt, T);
        continue;
      }
      if (w && typeof d == "object" && typeof d.getAttributeType == "function" && !Zt)
        switch (d.getAttributeType(Hl, de)) {
          case "TrustedHTML": {
            It = w.createHTML(It);
            break;
          }
          case "TrustedScriptURL": {
            It = w.createScriptURL(It);
            break;
          }
        }
      if (It !== ea)
        try {
          Zt ? T.setAttributeNS(Zt, Lt, It) : T.setAttribute(Lt, It), Jo(T) ? ue(T) : Gl(t.removed);
        } catch {
          lr(Lt, T);
        }
    }
    Ie(O.afterSanitizeAttributes, T, null);
  }, Wl = function(T) {
    let q = null;
    const G = Pl(T);
    for (Ie(O.beforeSanitizeShadowDOM, T, null); q = G.nextNode(); )
      Ie(O.uponSanitizeShadowNode, q, null), Rl(q), zl(q), q.content instanceof o && Wl(q.content);
    Ie(O.afterSanitizeShadowDOM, T, null);
  };
  return t.sanitize = function(J) {
    let T = arguments.length > 1 && arguments[1] !== void 0 ? arguments[1] : {}, q = null, G = null, kt = null, qt = null;
    if (Xo = !J, Xo && (J = "<!-->"), typeof J != "string" && !ta(J) && (J = jy(J), typeof J != "string"))
      throw ds("dirty is not a string, aborting");
    if (!t.isSupported)
      return J;
    if (Ho || Qo(T), t.removed = [], typeof J == "string" && (ni = !1), ni) {
      const ae = J.nodeName;
      if (typeof ae == "string") {
        const de = Mt(ae);
        if (!Q[de] || rt[de])
          throw ds("root node is forbidden and cannot be sanitized in-place");
      }
    } else if (J instanceof n)
      q = Dl("<!---->"), G = q.ownerDocument.importNode(J, !0), G.nodeType === di.element && G.nodeName === "BODY" || G.nodeName === "HTML" ? q = G : q.appendChild(G);
    else {
      if (!Mr && !re && !nr && // eslint-disable-next-line unicorn/prefer-includes
      J.indexOf("<") === -1)
        return w && hs ? w.createHTML(J) : J;
      if (q = Dl(J), !q)
        return Mr ? null : hs ? S : "";
    }
    q && Yo && ue(q.firstChild);
    const Lt = Pl(ni ? J : q);
    for (; kt = Lt.nextNode(); )
      Rl(kt), zl(kt), kt.content instanceof o && Wl(kt.content);
    if (ni)
      return J;
    if (Mr) {
      if (re) {
        q.normalize();
        let ae = q.innerHTML;
        hi([W, z, I], (de) => {
          ae = Ir(ae, de, " ");
        }), q.innerHTML = ae;
      }
      if (ls)
        for (qt = B.call(q.ownerDocument); q.firstChild; )
          qt.appendChild(q.firstChild);
      else
        qt = q;
      return (et.shadowroot || et.shadowrootmode) && (qt = D.call(i, qt, !0)), qt;
    }
    let Zt = nr ? q.outerHTML : q.innerHTML;
    return nr && Q["!doctype"] && q.ownerDocument && q.ownerDocument.doctype && q.ownerDocument.doctype.name && Pt(Gc, q.ownerDocument.doctype.name) && (Zt = "<!DOCTYPE " + q.ownerDocument.doctype.name + `>
` + Zt), re && hi([W, z, I], (ae) => {
      Zt = Ir(Zt, ae, " ");
    }), w && hs ? w.createHTML(Zt) : Zt;
  }, t.setConfig = function() {
    let J = arguments.length > 0 && arguments[0] !== void 0 ? arguments[0] : {};
    Qo(J), Ho = !0;
  }, t.clearConfig = function() {
    Or = null, Ho = !1;
  }, t.isValidAttribute = function(J, T, q) {
    Or || Qo({});
    const G = Mt(J), kt = Mt(T);
    return Nl(G, kt, q);
  }, t.addHook = function(J, T) {
    typeof T == "function" && ci(O[J], T);
  }, t.removeHook = function(J, T) {
    if (T !== void 0) {
      const q = Ry(O[J], T);
      return q === -1 ? void 0 : Ny(O[J], q, 1)[0];
    }
    return Gl(O[J]);
  }, t.removeHooks = function(J) {
    O[J] = [];
  }, t.removeAllHooks = function() {
    O = ih();
  }, t;
}
var Xr = Xc(), Vc = /^-{3}\s*[\n\r](.*?)[\n\r]-{3}\s*[\n\r]+/s, Mi = /%{2}{\s*(?:(\w+)\s*:|(\w+))\s*(?:(\w+)|((?:(?!}%{2}).|\r?\n)*))?\s*(?:}%{2})?/gi, o0 = /\s*%%.*\n/gm, Zc = class extends Error {
  static {
    f(this, "UnknownDiagramError");
  }
  constructor(e) {
    super(e), this.name = "UnknownDiagramError";
  }
}, xr = {}, Bn = /* @__PURE__ */ f(function(e, t) {
  e = e.replace(Vc, "").replace(Mi, "").replace(o0, `
`);
  for (const [r, { detector: i }] of Object.entries(xr))
    if (i(e, t))
      return r;
  throw new Zc(
    `No diagram type detected matching given configuration for text: ${e}`
  );
}, "detectType"), _a = /* @__PURE__ */ f((...e) => {
  for (const { id: t, detector: r, loader: i } of e)
    Kc(t, r, i);
}, "registerLazyLoadedDiagrams"), Kc = /* @__PURE__ */ f((e, t, r) => {
  xr[e] && R.warn(`Detector with key ${e} already exists. Overwriting.`), xr[e] = { detector: t, loader: r }, R.debug(`Detector with key ${e} added${r ? " with loader" : ""}`);
}, "addDetector"), a0 = /* @__PURE__ */ f((e) => xr[e].loader, "getDiagramLoader"), va = /* @__PURE__ */ f((e, t, { depth: r = 2, clobber: i = !1 } = {}) => {
  const s = { depth: r, clobber: i };
  return Array.isArray(t) && !Array.isArray(e) ? (t.forEach((o) => va(e, o, s)), e) : Array.isArray(t) && Array.isArray(e) ? (t.forEach((o) => {
    e.includes(o) || e.push(o);
  }), e) : e === void 0 || r <= 0 ? e != null && typeof e == "object" && typeof t == "object" ? Object.assign(e, t) : t : (t !== void 0 && typeof e == "object" && typeof t == "object" && Object.keys(t).forEach((o) => {
    typeof t[o] == "object" && t[o] !== null && (e[o] === void 0 || typeof e[o] == "object") ? (e[o] === void 0 && (e[o] = Array.isArray(t[o]) ? [] : {}), e[o] = va(e[o], t[o], { depth: r - 1, clobber: i })) : (i || typeof e[o] != "object" && typeof t[o] != "object") && (e[o] = t[o]);
  }), e);
}, "assignWithDepth"), $t = va, Ae = "#ffffff", Me = "#f2f2f2", at = /* @__PURE__ */ f((e, t) => t ? C(e, { s: -40, l: 10 }) : C(e, { s: -40, l: -10 }), "mkBorder"), n0 = class {
  static {
    f(this, "Theme");
  }
  constructor() {
    this.background = "#f4f4f4", this.primaryColor = "#fff4dd", this.noteBkgColor = "#fff5ad", this.noteTextColor = "#333", this.THEME_COLOR_LIMIT = 12, this.radius = 5, this.strokeWidth = 1, this.fontFamily = '"trebuchet ms", verdana, arial, sans-serif', this.fontSize = "16px", this.useGradient = !0, this.dropShadow = "drop-shadow( 1px 2px 2px rgba(185,185,185,1))";
  }
  updateColors() {
    if (this.primaryTextColor = this.primaryTextColor || (this.darkMode ? "#eee" : "#333"), this.secondaryColor = this.secondaryColor || C(this.primaryColor, { h: -120 }), this.tertiaryColor = this.tertiaryColor || C(this.primaryColor, { h: 180, l: 5 }), this.primaryBorderColor = this.primaryBorderColor || at(this.primaryColor, this.darkMode), this.secondaryBorderColor = this.secondaryBorderColor || at(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = this.tertiaryBorderColor || at(this.tertiaryColor, this.darkMode), this.noteBorderColor = this.noteBorderColor || at(this.noteBkgColor, this.darkMode), this.noteBkgColor = this.noteBkgColor || "#fff5ad", this.noteTextColor = this.noteTextColor || "#333", this.secondaryTextColor = this.secondaryTextColor || _(this.secondaryColor), this.tertiaryTextColor = this.tertiaryTextColor || _(this.tertiaryColor), this.lineColor = this.lineColor || _(this.background), this.arrowheadColor = this.arrowheadColor || _(this.background), this.textColor = this.textColor || this.primaryTextColor, this.border2 = this.border2 || this.tertiaryBorderColor, this.nodeBkg = this.nodeBkg || this.primaryColor, this.mainBkg = this.mainBkg || this.primaryColor, this.nodeBorder = this.nodeBorder || this.primaryBorderColor, this.clusterBkg = this.clusterBkg || this.tertiaryColor, this.clusterBorder = this.clusterBorder || this.tertiaryBorderColor, this.defaultLinkColor = this.defaultLinkColor || this.lineColor, this.titleColor = this.titleColor || this.tertiaryTextColor, this.edgeLabelBackground = this.edgeLabelBackground || (this.darkMode ? A(this.secondaryColor, 30) : this.secondaryColor), this.nodeTextColor = this.nodeTextColor || this.primaryTextColor, this.actorBorder = this.actorBorder || this.primaryBorderColor, this.actorBkg = this.actorBkg || this.mainBkg, this.actorTextColor = this.actorTextColor || this.primaryTextColor, this.actorLineColor = this.actorLineColor || this.actorBorder, this.labelBoxBkgColor = this.labelBoxBkgColor || this.actorBkg, this.signalColor = this.signalColor || this.textColor, this.signalTextColor = this.signalTextColor || this.textColor, this.labelBoxBorderColor = this.labelBoxBorderColor || this.actorBorder, this.labelTextColor = this.labelTextColor || this.actorTextColor, this.loopTextColor = this.loopTextColor || this.actorTextColor, this.activationBorderColor = this.activationBorderColor || A(this.secondaryColor, 10), this.activationBkgColor = this.activationBkgColor || this.secondaryColor, this.sequenceNumberColor = this.sequenceNumberColor || _(this.lineColor), this.sectionBkgColor = this.sectionBkgColor || this.tertiaryColor, this.altSectionBkgColor = this.altSectionBkgColor || "white", this.sectionBkgColor = this.sectionBkgColor || this.secondaryColor, this.sectionBkgColor2 = this.sectionBkgColor2 || this.primaryColor, this.excludeBkgColor = this.excludeBkgColor || "#eeeeee", this.taskBorderColor = this.taskBorderColor || this.primaryBorderColor, this.taskBkgColor = this.taskBkgColor || this.primaryColor, this.activeTaskBorderColor = this.activeTaskBorderColor || this.primaryColor, this.activeTaskBkgColor = this.activeTaskBkgColor || $(this.primaryColor, 23), this.gridColor = this.gridColor || "lightgrey", this.doneTaskBkgColor = this.doneTaskBkgColor || "lightgrey", this.doneTaskBorderColor = this.doneTaskBorderColor || "grey", this.critBorderColor = this.critBorderColor || "#ff8888", this.critBkgColor = this.critBkgColor || "red", this.todayLineColor = this.todayLineColor || "red", this.vertLineColor = this.vertLineColor || "navy", this.taskTextColor = this.taskTextColor || this.textColor, this.taskTextOutsideColor = this.taskTextOutsideColor || this.textColor, this.taskTextLightColor = this.taskTextLightColor || this.textColor, this.taskTextColor = this.taskTextColor || this.primaryTextColor, this.taskTextDarkColor = this.taskTextDarkColor || this.textColor, this.taskTextClickableColor = this.taskTextClickableColor || "#003163", this.noteFontWeight = this.noteFontWeight || "normal", this.fontWeight = this.fontWeight || "normal", this.personBorder = this.personBorder || this.primaryBorderColor, this.personBkg = this.personBkg || this.mainBkg, this.darkMode ? (this.rowOdd = this.rowOdd || A(this.mainBkg, 5) || "#ffffff", this.rowEven = this.rowEven || A(this.mainBkg, 10)) : (this.rowOdd = this.rowOdd || $(this.mainBkg, 75) || "#ffffff", this.rowEven = this.rowEven || $(this.mainBkg, 5)), this.transitionColor = this.transitionColor || this.lineColor, this.transitionLabelColor = this.transitionLabelColor || this.textColor, this.stateLabelColor = this.stateLabelColor || this.stateBkg || this.primaryTextColor, this.stateBkg = this.stateBkg || this.mainBkg, this.labelBackgroundColor = this.labelBackgroundColor || this.stateBkg, this.compositeBackground = this.compositeBackground || this.background || this.tertiaryColor, this.altBackground = this.altBackground || this.tertiaryColor, this.compositeTitleBackground = this.compositeTitleBackground || this.mainBkg, this.compositeBorder = this.compositeBorder || this.nodeBorder, this.innerEndBackground = this.nodeBorder, this.errorBkgColor = this.errorBkgColor || this.tertiaryColor, this.errorTextColor = this.errorTextColor || this.tertiaryTextColor, this.transitionColor = this.transitionColor || this.lineColor, this.specialStateColor = this.lineColor, this.cScale0 = this.cScale0 || this.primaryColor, this.cScale1 = this.cScale1 || this.secondaryColor, this.cScale2 = this.cScale2 || this.tertiaryColor, this.cScale3 = this.cScale3 || C(this.primaryColor, { h: 30 }), this.cScale4 = this.cScale4 || C(this.primaryColor, { h: 60 }), this.cScale5 = this.cScale5 || C(this.primaryColor, { h: 90 }), this.cScale6 = this.cScale6 || C(this.primaryColor, { h: 120 }), this.cScale7 = this.cScale7 || C(this.primaryColor, { h: 150 }), this.cScale8 = this.cScale8 || C(this.primaryColor, { h: 210, l: 150 }), this.cScale9 = this.cScale9 || C(this.primaryColor, { h: 270 }), this.cScale10 = this.cScale10 || C(this.primaryColor, { h: 300 }), this.cScale11 = this.cScale11 || C(this.primaryColor, { h: 330 }), this.darkMode)
      for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
        this["cScale" + t] = A(this["cScale" + t], 75);
    else
      for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
        this["cScale" + t] = A(this["cScale" + t], 25);
    for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
      this["cScaleInv" + t] = this["cScaleInv" + t] || _(this["cScale" + t]);
    for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
      this.darkMode ? this["cScalePeer" + t] = this["cScalePeer" + t] || $(this["cScale" + t], 10) : this["cScalePeer" + t] = this["cScalePeer" + t] || A(this["cScale" + t], 10);
    this.scaleLabelColor = this.scaleLabelColor || this.labelTextColor;
    for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
      this["cScaleLabel" + t] = this["cScaleLabel" + t] || this.scaleLabelColor;
    const e = this.darkMode ? -4 : -1;
    for (let t = 0; t < 5; t++)
      this["surface" + t] = this["surface" + t] || C(this.mainBkg, { h: 180, s: -15, l: e * (5 + t * 3) }), this["surfacePeer" + t] = this["surfacePeer" + t] || C(this.mainBkg, { h: 180, s: -15, l: e * (8 + t * 3) });
    this.classText = this.classText || this.textColor, this.fillType0 = this.fillType0 || this.primaryColor, this.fillType1 = this.fillType1 || this.secondaryColor, this.fillType2 = this.fillType2 || C(this.primaryColor, { h: 64 }), this.fillType3 = this.fillType3 || C(this.secondaryColor, { h: 64 }), this.fillType4 = this.fillType4 || C(this.primaryColor, { h: -64 }), this.fillType5 = this.fillType5 || C(this.secondaryColor, { h: -64 }), this.fillType6 = this.fillType6 || C(this.primaryColor, { h: 128 }), this.fillType7 = this.fillType7 || C(this.secondaryColor, { h: 128 }), this.pie1 = this.pie1 || this.primaryColor, this.pie2 = this.pie2 || this.secondaryColor, this.pie3 = this.pie3 || this.tertiaryColor, this.pie4 = this.pie4 || C(this.primaryColor, { l: -10 }), this.pie5 = this.pie5 || C(this.secondaryColor, { l: -10 }), this.pie6 = this.pie6 || C(this.tertiaryColor, { l: -10 }), this.pie7 = this.pie7 || C(this.primaryColor, { h: 60, l: -10 }), this.pie8 = this.pie8 || C(this.primaryColor, { h: -60, l: -10 }), this.pie9 = this.pie9 || C(this.primaryColor, { h: 120, l: 0 }), this.pie10 = this.pie10 || C(this.primaryColor, { h: 60, l: -20 }), this.pie11 = this.pie11 || C(this.primaryColor, { h: -60, l: -20 }), this.pie12 = this.pie12 || C(this.primaryColor, { h: 120, l: -10 }), this.pieTitleTextSize = this.pieTitleTextSize || "25px", this.pieTitleTextColor = this.pieTitleTextColor || this.taskTextDarkColor, this.pieSectionTextSize = this.pieSectionTextSize || "17px", this.pieSectionTextColor = this.pieSectionTextColor || this.textColor, this.pieLegendTextSize = this.pieLegendTextSize || "17px", this.pieLegendTextColor = this.pieLegendTextColor || this.taskTextDarkColor, this.pieStrokeColor = this.pieStrokeColor || "black", this.pieStrokeWidth = this.pieStrokeWidth || "2px", this.pieOuterStrokeWidth = this.pieOuterStrokeWidth || "2px", this.pieOuterStrokeColor = this.pieOuterStrokeColor || "black", this.pieOpacity = this.pieOpacity || "0.7", this.venn1 = this.venn1 ?? C(this.primaryColor, { l: -30 }), this.venn2 = this.venn2 ?? C(this.secondaryColor, { l: -30 }), this.venn3 = this.venn3 ?? C(this.tertiaryColor, { l: -30 }), this.venn4 = this.venn4 ?? C(this.primaryColor, { h: 60, l: -30 }), this.venn5 = this.venn5 ?? C(this.primaryColor, { h: -60, l: -30 }), this.venn6 = this.venn6 ?? C(this.secondaryColor, { h: 60, l: -30 }), this.venn7 = this.venn7 ?? C(this.primaryColor, { h: 120, l: -30 }), this.venn8 = this.venn8 ?? C(this.secondaryColor, { h: 120, l: -30 }), this.vennTitleTextColor = this.vennTitleTextColor ?? this.titleColor, this.vennSetTextColor = this.vennSetTextColor ?? this.textColor, this.radar = {
      axisColor: this.radar?.axisColor || this.lineColor,
      axisStrokeWidth: this.radar?.axisStrokeWidth || 2,
      axisLabelFontSize: this.radar?.axisLabelFontSize || 12,
      curveOpacity: this.radar?.curveOpacity || 0.5,
      curveStrokeWidth: this.radar?.curveStrokeWidth || 2,
      graticuleColor: this.radar?.graticuleColor || "#DEDEDE",
      graticuleStrokeWidth: this.radar?.graticuleStrokeWidth || 1,
      graticuleOpacity: this.radar?.graticuleOpacity || 0.3,
      legendBoxSize: this.radar?.legendBoxSize || 12,
      legendFontSize: this.radar?.legendFontSize || 12
    }, this.archEdgeColor = this.archEdgeColor || "#777", this.archEdgeArrowColor = this.archEdgeArrowColor || "#777", this.archEdgeWidth = this.archEdgeWidth || "3", this.archGroupBorderColor = this.archGroupBorderColor || "#000", this.archGroupBorderWidth = this.archGroupBorderWidth || "2px", this.quadrant1Fill = this.quadrant1Fill || this.primaryColor, this.quadrant2Fill = this.quadrant2Fill || C(this.primaryColor, { r: 5, g: 5, b: 5 }), this.quadrant3Fill = this.quadrant3Fill || C(this.primaryColor, { r: 10, g: 10, b: 10 }), this.quadrant4Fill = this.quadrant4Fill || C(this.primaryColor, { r: 15, g: 15, b: 15 }), this.quadrant1TextFill = this.quadrant1TextFill || this.primaryTextColor, this.quadrant2TextFill = this.quadrant2TextFill || C(this.primaryTextColor, { r: -5, g: -5, b: -5 }), this.quadrant3TextFill = this.quadrant3TextFill || C(this.primaryTextColor, { r: -10, g: -10, b: -10 }), this.quadrant4TextFill = this.quadrant4TextFill || C(this.primaryTextColor, { r: -15, g: -15, b: -15 }), this.quadrantPointFill = this.quadrantPointFill || be(this.quadrant1Fill) ? $(this.quadrant1Fill) : A(this.quadrant1Fill), this.quadrantPointTextFill = this.quadrantPointTextFill || this.primaryTextColor, this.quadrantXAxisTextFill = this.quadrantXAxisTextFill || this.primaryTextColor, this.quadrantYAxisTextFill = this.quadrantYAxisTextFill || this.primaryTextColor, this.quadrantInternalBorderStrokeFill = this.quadrantInternalBorderStrokeFill || this.primaryBorderColor, this.quadrantExternalBorderStrokeFill = this.quadrantExternalBorderStrokeFill || this.primaryBorderColor, this.quadrantTitleFill = this.quadrantTitleFill || this.primaryTextColor, this.xyChart = {
      backgroundColor: this.xyChart?.backgroundColor || this.background,
      titleColor: this.xyChart?.titleColor || this.primaryTextColor,
      dataLabelColor: this.xyChart?.dataLabelColor || this.primaryTextColor,
      xAxisTitleColor: this.xyChart?.xAxisTitleColor || this.primaryTextColor,
      xAxisLabelColor: this.xyChart?.xAxisLabelColor || this.primaryTextColor,
      xAxisTickColor: this.xyChart?.xAxisTickColor || this.primaryTextColor,
      xAxisLineColor: this.xyChart?.xAxisLineColor || this.primaryTextColor,
      yAxisTitleColor: this.xyChart?.yAxisTitleColor || this.primaryTextColor,
      yAxisLabelColor: this.xyChart?.yAxisLabelColor || this.primaryTextColor,
      yAxisTickColor: this.xyChart?.yAxisTickColor || this.primaryTextColor,
      yAxisLineColor: this.xyChart?.yAxisLineColor || this.primaryTextColor,
      plotColorPalette: this.xyChart?.plotColorPalette || "#FFF4DD,#FFD8B1,#FFA07A,#ECEFF1,#D6DBDF,#C3E0A8,#FFB6A4,#FFD74D,#738FA7,#FFFFF0"
    }, this.requirementBackground = this.requirementBackground || this.primaryColor, this.requirementBorderColor = this.requirementBorderColor || this.primaryBorderColor, this.requirementBorderSize = this.requirementBorderSize || "1", this.requirementTextColor = this.requirementTextColor || this.primaryTextColor, this.relationColor = this.relationColor || this.lineColor, this.relationLabelBackground = this.relationLabelBackground || (this.darkMode ? A(this.secondaryColor, 30) : this.secondaryColor), this.relationLabelColor = this.relationLabelColor || this.actorTextColor, this.git0 = this.git0 || this.primaryColor, this.git1 = this.git1 || this.secondaryColor, this.git2 = this.git2 || this.tertiaryColor, this.git3 = this.git3 || C(this.primaryColor, { h: -30 }), this.git4 = this.git4 || C(this.primaryColor, { h: -60 }), this.git5 = this.git5 || C(this.primaryColor, { h: -90 }), this.git6 = this.git6 || C(this.primaryColor, { h: 60 }), this.git7 = this.git7 || C(this.primaryColor, { h: 120 }), this.darkMode ? (this.git0 = $(this.git0, 25), this.git1 = $(this.git1, 25), this.git2 = $(this.git2, 25), this.git3 = $(this.git3, 25), this.git4 = $(this.git4, 25), this.git5 = $(this.git5, 25), this.git6 = $(this.git6, 25), this.git7 = $(this.git7, 25)) : (this.git0 = A(this.git0, 25), this.git1 = A(this.git1, 25), this.git2 = A(this.git2, 25), this.git3 = A(this.git3, 25), this.git4 = A(this.git4, 25), this.git5 = A(this.git5, 25), this.git6 = A(this.git6, 25), this.git7 = A(this.git7, 25)), this.gitInv0 = this.gitInv0 || _(this.git0), this.gitInv1 = this.gitInv1 || _(this.git1), this.gitInv2 = this.gitInv2 || _(this.git2), this.gitInv3 = this.gitInv3 || _(this.git3), this.gitInv4 = this.gitInv4 || _(this.git4), this.gitInv5 = this.gitInv5 || _(this.git5), this.gitInv6 = this.gitInv6 || _(this.git6), this.gitInv7 = this.gitInv7 || _(this.git7), this.branchLabelColor = this.branchLabelColor || (this.darkMode ? "black" : this.labelTextColor), this.gitBranchLabel0 = this.gitBranchLabel0 || this.branchLabelColor, this.gitBranchLabel1 = this.gitBranchLabel1 || this.branchLabelColor, this.gitBranchLabel2 = this.gitBranchLabel2 || this.branchLabelColor, this.gitBranchLabel3 = this.gitBranchLabel3 || this.branchLabelColor, this.gitBranchLabel4 = this.gitBranchLabel4 || this.branchLabelColor, this.gitBranchLabel5 = this.gitBranchLabel5 || this.branchLabelColor, this.gitBranchLabel6 = this.gitBranchLabel6 || this.branchLabelColor, this.gitBranchLabel7 = this.gitBranchLabel7 || this.branchLabelColor, this.tagLabelColor = this.tagLabelColor || this.primaryTextColor, this.tagLabelBackground = this.tagLabelBackground || this.primaryColor, this.tagLabelBorder = this.tagBorder || this.primaryBorderColor, this.tagLabelFontSize = this.tagLabelFontSize || "10px", this.commitLabelColor = this.commitLabelColor || this.secondaryTextColor, this.commitLabelBackground = this.commitLabelBackground || this.secondaryColor, this.commitLabelFontSize = this.commitLabelFontSize || "10px", this.attributeBackgroundColorOdd = this.attributeBackgroundColorOdd || Ae, this.attributeBackgroundColorEven = this.attributeBackgroundColorEven || Me, this.gradientStart = this.primaryBorderColor, this.gradientStop = this.secondaryBorderColor;
  }
  calculate(e) {
    if (typeof e != "object") {
      this.updateColors();
      return;
    }
    const t = Object.keys(e);
    t.forEach((r) => {
      this[r] = e[r];
    }), this.updateColors(), t.forEach((r) => {
      this[r] = e[r];
    });
  }
}, l0 = /* @__PURE__ */ f((e) => {
  const t = new n0();
  return t.calculate(e), t;
}, "getThemeVariables"), h0 = class {
  static {
    f(this, "Theme");
  }
  constructor() {
    this.background = "#333", this.primaryColor = "#1f2020", this.secondaryColor = $(this.primaryColor, 16), this.tertiaryColor = C(this.primaryColor, { h: -160 }), this.primaryBorderColor = _(this.background), this.secondaryBorderColor = at(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = at(this.tertiaryColor, this.darkMode), this.primaryTextColor = _(this.primaryColor), this.secondaryTextColor = _(this.secondaryColor), this.tertiaryTextColor = _(this.tertiaryColor), this.lineColor = _(this.background), this.textColor = _(this.background), this.mainBkg = "#1f2020", this.secondBkg = "calculated", this.mainContrastColor = "lightgrey", this.darkTextColor = $(_("#323D47"), 10), this.lineColor = "calculated", this.border1 = "#ccc", this.border2 = Je(255, 255, 255, 0.25), this.arrowheadColor = "calculated", this.fontFamily = '"trebuchet ms", verdana, arial, sans-serif', this.fontSize = "16px", this.labelBackground = "#181818", this.textColor = "#ccc", this.THEME_COLOR_LIMIT = 12, this.radius = 5, this.strokeWidth = 1, this.nodeBkg = "calculated", this.nodeBorder = "calculated", this.clusterBkg = "calculated", this.clusterBorder = "calculated", this.defaultLinkColor = "calculated", this.titleColor = "#F9FFFE", this.edgeLabelBackground = "calculated", this.actorBorder = "calculated", this.actorBkg = "calculated", this.actorTextColor = "calculated", this.actorLineColor = "calculated", this.signalColor = "calculated", this.signalTextColor = "calculated", this.labelBoxBkgColor = "calculated", this.labelBoxBorderColor = "calculated", this.labelTextColor = "calculated", this.loopTextColor = "calculated", this.noteBorderColor = "calculated", this.noteBkgColor = "#fff5ad", this.noteTextColor = "calculated", this.activationBorderColor = "calculated", this.activationBkgColor = "calculated", this.sequenceNumberColor = "black", this.clusterBkg = "#302F3D", this.sectionBkgColor = A("#EAE8D9", 30), this.altSectionBkgColor = "calculated", this.sectionBkgColor2 = "#EAE8D9", this.excludeBkgColor = A(this.sectionBkgColor, 10), this.taskBorderColor = Je(255, 255, 255, 70), this.taskBkgColor = "calculated", this.taskTextColor = "calculated", this.taskTextLightColor = "calculated", this.taskTextOutsideColor = "calculated", this.taskTextClickableColor = "#003163", this.activeTaskBorderColor = Je(255, 255, 255, 50), this.activeTaskBkgColor = "#81B1DB", this.gridColor = "calculated", this.doneTaskBkgColor = "calculated", this.doneTaskBorderColor = "grey", this.critBorderColor = "#E83737", this.critBkgColor = "#E83737", this.taskTextDarkColor = "calculated", this.todayLineColor = "#DB5757", this.vertLineColor = "#00BFFF", this.personBorder = this.primaryBorderColor, this.personBkg = this.mainBkg, this.archEdgeColor = "calculated", this.archEdgeArrowColor = "calculated", this.archEdgeWidth = "3", this.archGroupBorderColor = this.primaryBorderColor, this.archGroupBorderWidth = "2px", this.rowOdd = this.rowOdd || $(this.mainBkg, 5) || "#ffffff", this.rowEven = this.rowEven || A(this.mainBkg, 10), this.labelColor = "calculated", this.errorBkgColor = "#a44141", this.errorTextColor = "#ddd", this.useGradient = !0, this.gradientStart = this.primaryBorderColor, this.gradientStop = this.secondaryBorderColor, this.dropShadow = "drop-shadow( 1px 2px 2px rgba(185,185,185,1))", this.noteFontWeight = this.noteFontWeight || "normal", this.fontWeight = this.fontWeight || "normal";
  }
  updateColors() {
    this.secondBkg = $(this.mainBkg, 16), this.lineColor = this.mainContrastColor, this.arrowheadColor = this.mainContrastColor, this.nodeBkg = this.mainBkg, this.nodeBorder = this.border1, this.clusterBkg = this.secondBkg, this.clusterBorder = this.border2, this.defaultLinkColor = this.lineColor, this.edgeLabelBackground = $(this.labelBackground, 25), this.actorBorder = this.border1, this.actorBkg = this.mainBkg, this.actorTextColor = this.mainContrastColor, this.actorLineColor = this.actorBorder, this.signalColor = this.mainContrastColor, this.signalTextColor = this.mainContrastColor, this.labelBoxBkgColor = this.actorBkg, this.labelBoxBorderColor = this.actorBorder, this.labelTextColor = this.mainContrastColor, this.loopTextColor = this.mainContrastColor, this.noteBorderColor = this.secondaryBorderColor, this.noteBkgColor = this.secondBkg, this.noteTextColor = this.secondaryTextColor, this.activationBorderColor = this.border1, this.activationBkgColor = this.secondBkg, this.altSectionBkgColor = this.background, this.taskBkgColor = $(this.mainBkg, 23), this.taskTextColor = this.darkTextColor, this.taskTextLightColor = this.mainContrastColor, this.taskTextOutsideColor = this.taskTextLightColor, this.gridColor = this.mainContrastColor, this.doneTaskBkgColor = this.mainContrastColor, this.taskTextDarkColor = _(this.doneTaskBkgColor), this.archEdgeColor = this.lineColor, this.archEdgeArrowColor = this.lineColor, this.transitionColor = this.transitionColor || this.lineColor, this.transitionLabelColor = this.transitionLabelColor || this.textColor, this.stateLabelColor = this.stateLabelColor || this.stateBkg || this.primaryTextColor, this.stateBkg = this.stateBkg || this.mainBkg, this.labelBackgroundColor = this.labelBackgroundColor || this.stateBkg, this.compositeBackground = this.compositeBackground || this.background || this.tertiaryColor, this.altBackground = this.altBackground || "#555", this.compositeTitleBackground = this.compositeTitleBackground || this.mainBkg, this.compositeBorder = this.compositeBorder || this.nodeBorder, this.innerEndBackground = this.primaryBorderColor, this.specialStateColor = "#f4f4f4", this.errorBkgColor = this.errorBkgColor || this.tertiaryColor, this.errorTextColor = this.errorTextColor || this.tertiaryTextColor, this.fillType0 = this.primaryColor, this.fillType1 = this.secondaryColor, this.fillType2 = C(this.primaryColor, { h: 64 }), this.fillType3 = C(this.secondaryColor, { h: 64 }), this.fillType4 = C(this.primaryColor, { h: -64 }), this.fillType5 = C(this.secondaryColor, { h: -64 }), this.fillType6 = C(this.primaryColor, { h: 128 }), this.fillType7 = C(this.secondaryColor, { h: 128 }), this.cScale1 = this.cScale1 || "#0b0000", this.cScale2 = this.cScale2 || "#4d1037", this.cScale3 = this.cScale3 || "#3f5258", this.cScale4 = this.cScale4 || "#4f2f1b", this.cScale5 = this.cScale5 || "#6e0a0a", this.cScale6 = this.cScale6 || "#3b0048", this.cScale7 = this.cScale7 || "#995a01", this.cScale8 = this.cScale8 || "#154706", this.cScale9 = this.cScale9 || "#161722", this.cScale10 = this.cScale10 || "#00296f", this.cScale11 = this.cScale11 || "#01629c", this.cScale12 = this.cScale12 || "#010029", this.cScale0 = this.cScale0 || this.primaryColor, this.cScale1 = this.cScale1 || this.secondaryColor, this.cScale2 = this.cScale2 || this.tertiaryColor, this.cScale3 = this.cScale3 || C(this.primaryColor, { h: 30 }), this.cScale4 = this.cScale4 || C(this.primaryColor, { h: 60 }), this.cScale5 = this.cScale5 || C(this.primaryColor, { h: 90 }), this.cScale6 = this.cScale6 || C(this.primaryColor, { h: 120 }), this.cScale7 = this.cScale7 || C(this.primaryColor, { h: 150 }), this.cScale8 = this.cScale8 || C(this.primaryColor, { h: 210 }), this.cScale9 = this.cScale9 || C(this.primaryColor, { h: 270 }), this.cScale10 = this.cScale10 || C(this.primaryColor, { h: 300 }), this.cScale11 = this.cScale11 || C(this.primaryColor, { h: 330 });
    for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
      this["cScaleInv" + e] = this["cScaleInv" + e] || _(this["cScale" + e]);
    for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
      this["cScalePeer" + e] = this["cScalePeer" + e] || $(this["cScale" + e], 10);
    for (let e = 0; e < 5; e++)
      this["surface" + e] = this["surface" + e] || C(this.mainBkg, { h: 30, s: -30, l: -(-10 + e * 4) }), this["surfacePeer" + e] = this["surfacePeer" + e] || C(this.mainBkg, { h: 30, s: -30, l: -(-7 + e * 4) });
    this.scaleLabelColor = this.scaleLabelColor || (this.darkMode ? "black" : this.labelTextColor);
    for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
      this["cScaleLabel" + e] = this["cScaleLabel" + e] || this.scaleLabelColor;
    for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
      this["pie" + e] = this["cScale" + e];
    this.pieTitleTextSize = this.pieTitleTextSize || "25px", this.pieTitleTextColor = this.pieTitleTextColor || this.mainContrastColor, this.pieSectionTextSize = this.pieSectionTextSize || "17px", this.pieSectionTextColor = this.pieSectionTextColor || this.textColor, this.pieLegendTextSize = this.pieLegendTextSize || "17px", this.pieLegendTextColor = this.pieLegendTextColor || this.mainContrastColor, this.pieStrokeColor = this.pieStrokeColor || "black", this.pieStrokeWidth = this.pieStrokeWidth || "2px", this.pieOuterStrokeWidth = this.pieOuterStrokeWidth || "2px", this.pieOuterStrokeColor = this.pieOuterStrokeColor || "black", this.pieOpacity = this.pieOpacity || "0.7";
    for (let e = 0; e < 8; e++)
      this["venn" + (e + 1)] = this["venn" + (e + 1)] ?? $(this["cScale" + e], 30);
    this.vennTitleTextColor = this.vennTitleTextColor ?? this.titleColor, this.vennSetTextColor = this.vennSetTextColor ?? this.textColor, this.quadrant1Fill = this.quadrant1Fill || this.primaryColor, this.quadrant2Fill = this.quadrant2Fill || C(this.primaryColor, { r: 5, g: 5, b: 5 }), this.quadrant3Fill = this.quadrant3Fill || C(this.primaryColor, { r: 10, g: 10, b: 10 }), this.quadrant4Fill = this.quadrant4Fill || C(this.primaryColor, { r: 15, g: 15, b: 15 }), this.quadrant1TextFill = this.quadrant1TextFill || this.primaryTextColor, this.quadrant2TextFill = this.quadrant2TextFill || C(this.primaryTextColor, { r: -5, g: -5, b: -5 }), this.quadrant3TextFill = this.quadrant3TextFill || C(this.primaryTextColor, { r: -10, g: -10, b: -10 }), this.quadrant4TextFill = this.quadrant4TextFill || C(this.primaryTextColor, { r: -15, g: -15, b: -15 }), this.quadrantPointFill = this.quadrantPointFill || be(this.quadrant1Fill) ? $(this.quadrant1Fill) : A(this.quadrant1Fill), this.quadrantPointTextFill = this.quadrantPointTextFill || this.primaryTextColor, this.quadrantXAxisTextFill = this.quadrantXAxisTextFill || this.primaryTextColor, this.quadrantYAxisTextFill = this.quadrantYAxisTextFill || this.primaryTextColor, this.quadrantInternalBorderStrokeFill = this.quadrantInternalBorderStrokeFill || this.primaryBorderColor, this.quadrantExternalBorderStrokeFill = this.quadrantExternalBorderStrokeFill || this.primaryBorderColor, this.quadrantTitleFill = this.quadrantTitleFill || this.primaryTextColor, this.xyChart = {
      backgroundColor: this.xyChart?.backgroundColor || this.background,
      titleColor: this.xyChart?.titleColor || this.primaryTextColor,
      dataLabelColor: this.xyChart?.dataLabelColor || this.primaryTextColor,
      xAxisTitleColor: this.xyChart?.xAxisTitleColor || this.primaryTextColor,
      xAxisLabelColor: this.xyChart?.xAxisLabelColor || this.primaryTextColor,
      xAxisTickColor: this.xyChart?.xAxisTickColor || this.primaryTextColor,
      xAxisLineColor: this.xyChart?.xAxisLineColor || this.primaryTextColor,
      yAxisTitleColor: this.xyChart?.yAxisTitleColor || this.primaryTextColor,
      yAxisLabelColor: this.xyChart?.yAxisLabelColor || this.primaryTextColor,
      yAxisTickColor: this.xyChart?.yAxisTickColor || this.primaryTextColor,
      yAxisLineColor: this.xyChart?.yAxisLineColor || this.primaryTextColor,
      plotColorPalette: this.xyChart?.plotColorPalette || "#3498db,#2ecc71,#e74c3c,#f1c40f,#bdc3c7,#ffffff,#34495e,#9b59b6,#1abc9c,#e67e22"
    }, this.packet = {
      startByteColor: this.primaryTextColor,
      endByteColor: this.primaryTextColor,
      labelColor: this.primaryTextColor,
      titleColor: this.primaryTextColor,
      blockStrokeColor: this.primaryTextColor,
      blockFillColor: this.background
    }, this.radar = {
      axisColor: this.radar?.axisColor || this.lineColor,
      axisStrokeWidth: this.radar?.axisStrokeWidth || 2,
      axisLabelFontSize: this.radar?.axisLabelFontSize || 12,
      curveOpacity: this.radar?.curveOpacity || 0.5,
      curveStrokeWidth: this.radar?.curveStrokeWidth || 2,
      graticuleColor: this.radar?.graticuleColor || "#DEDEDE",
      graticuleStrokeWidth: this.radar?.graticuleStrokeWidth || 1,
      graticuleOpacity: this.radar?.graticuleOpacity || 0.3,
      legendBoxSize: this.radar?.legendBoxSize || 12,
      legendFontSize: this.radar?.legendFontSize || 12
    }, this.classText = this.primaryTextColor, this.requirementBackground = this.requirementBackground || this.primaryColor, this.requirementBorderColor = this.requirementBorderColor || this.primaryBorderColor, this.requirementBorderSize = this.requirementBorderSize || "1", this.requirementTextColor = this.requirementTextColor || this.primaryTextColor, this.relationColor = this.relationColor || this.lineColor, this.relationLabelBackground = this.relationLabelBackground || (this.darkMode ? A(this.secondaryColor, 30) : this.secondaryColor), this.relationLabelColor = this.relationLabelColor || this.actorTextColor, this.git0 = $(this.secondaryColor, 20), this.git1 = $(this.pie2 || this.secondaryColor, 20), this.git2 = $(this.pie3 || this.tertiaryColor, 20), this.git3 = $(this.pie4 || C(this.primaryColor, { h: -30 }), 20), this.git4 = $(this.pie5 || C(this.primaryColor, { h: -60 }), 20), this.git5 = $(this.pie6 || C(this.primaryColor, { h: -90 }), 10), this.git6 = $(this.pie7 || C(this.primaryColor, { h: 60 }), 10), this.git7 = $(this.pie8 || C(this.primaryColor, { h: 120 }), 20), this.gitInv0 = this.gitInv0 || _(this.git0), this.gitInv1 = this.gitInv1 || _(this.git1), this.gitInv2 = this.gitInv2 || _(this.git2), this.gitInv3 = this.gitInv3 || _(this.git3), this.gitInv4 = this.gitInv4 || _(this.git4), this.gitInv5 = this.gitInv5 || _(this.git5), this.gitInv6 = this.gitInv6 || _(this.git6), this.gitInv7 = this.gitInv7 || _(this.git7), this.gitBranchLabel0 = this.gitBranchLabel0 || _(this.labelTextColor), this.gitBranchLabel1 = this.gitBranchLabel1 || this.labelTextColor, this.gitBranchLabel2 = this.gitBranchLabel2 || this.labelTextColor, this.gitBranchLabel3 = this.gitBranchLabel3 || _(this.labelTextColor), this.gitBranchLabel4 = this.gitBranchLabel4 || this.labelTextColor, this.gitBranchLabel5 = this.gitBranchLabel5 || this.labelTextColor, this.gitBranchLabel6 = this.gitBranchLabel6 || this.labelTextColor, this.gitBranchLabel7 = this.gitBranchLabel7 || this.labelTextColor, this.tagLabelColor = this.tagLabelColor || this.primaryTextColor, this.tagLabelBackground = this.tagLabelBackground || this.primaryColor, this.tagLabelBorder = this.tagBorder || this.primaryBorderColor, this.tagLabelFontSize = this.tagLabelFontSize || "10px", this.commitLabelColor = this.commitLabelColor || this.secondaryTextColor, this.commitLabelBackground = this.commitLabelBackground || this.secondaryColor, this.commitLabelFontSize = this.commitLabelFontSize || "10px", this.attributeBackgroundColorOdd = this.attributeBackgroundColorOdd || $(this.background, 12), this.attributeBackgroundColorEven = this.attributeBackgroundColorEven || $(this.background, 2), this.nodeBorder = this.nodeBorder || "#999";
  }
  calculate(e) {
    if (typeof e != "object") {
      this.updateColors();
      return;
    }
    const t = Object.keys(e);
    t.forEach((r) => {
      this[r] = e[r];
    }), this.updateColors(), t.forEach((r) => {
      this[r] = e[r];
    });
  }
}, c0 = /* @__PURE__ */ f((e) => {
  const t = new h0();
  return t.calculate(e), t;
}, "getThemeVariables"), u0 = class {
  static {
    f(this, "Theme");
  }
  constructor() {
    this.background = "#f4f4f4", this.primaryColor = "#ECECFF", this.secondaryColor = C(this.primaryColor, { h: 120 }), this.secondaryColor = "#ffffde", this.tertiaryColor = C(this.primaryColor, { h: -160 }), this.primaryBorderColor = at(this.primaryColor, this.darkMode), this.secondaryBorderColor = at(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = at(this.tertiaryColor, this.darkMode), this.primaryTextColor = _(this.primaryColor), this.secondaryTextColor = _(this.secondaryColor), this.tertiaryTextColor = _(this.tertiaryColor), this.lineColor = _(this.background), this.textColor = _(this.background), this.background = "white", this.mainBkg = "#ECECFF", this.secondBkg = "#ffffde", this.lineColor = "#333333", this.border1 = "#9370DB", this.primaryBorderColor = at(this.primaryColor, this.darkMode), this.border2 = "#aaaa33", this.arrowheadColor = "#333333", this.fontFamily = '"trebuchet ms", verdana, arial, sans-serif', this.fontSize = "16px", this.labelBackground = "rgba(232,232,232, 0.8)", this.textColor = "#333", this.THEME_COLOR_LIMIT = 12, this.radius = 5, this.strokeWidth = 1, this.nodeBkg = "calculated", this.nodeBorder = "calculated", this.clusterBkg = "calculated", this.clusterBorder = "calculated", this.defaultLinkColor = "calculated", this.titleColor = "calculated", this.edgeLabelBackground = "calculated", this.actorBorder = "calculated", this.actorBkg = "calculated", this.actorTextColor = "black", this.actorLineColor = "calculated", this.signalColor = "calculated", this.signalTextColor = "calculated", this.labelBoxBkgColor = "calculated", this.labelBoxBorderColor = "calculated", this.labelTextColor = "calculated", this.loopTextColor = "calculated", this.noteBorderColor = "calculated", this.noteBkgColor = "#fff5ad", this.noteTextColor = "calculated", this.activationBorderColor = "#666", this.activationBkgColor = "#f4f4f4", this.sequenceNumberColor = "white", this.clusterBkg = "#FBFBFF", this.sectionBkgColor = "calculated", this.altSectionBkgColor = "calculated", this.sectionBkgColor2 = "calculated", this.excludeBkgColor = "#eeeeee", this.taskBorderColor = "calculated", this.taskBkgColor = "calculated", this.taskTextLightColor = "calculated", this.taskTextColor = this.taskTextLightColor, this.taskTextDarkColor = "calculated", this.taskTextOutsideColor = this.taskTextDarkColor, this.taskTextClickableColor = "calculated", this.activeTaskBorderColor = "calculated", this.activeTaskBkgColor = "calculated", this.gridColor = "calculated", this.doneTaskBkgColor = "calculated", this.doneTaskBorderColor = "calculated", this.critBorderColor = "calculated", this.critBkgColor = "calculated", this.todayLineColor = "calculated", this.vertLineColor = "calculated", this.sectionBkgColor = Je(102, 102, 255, 0.49), this.altSectionBkgColor = "white", this.sectionBkgColor2 = "#fff400", this.taskBorderColor = "#534fbc", this.taskBkgColor = "#8a90dd", this.taskTextLightColor = "white", this.taskTextColor = "calculated", this.taskTextDarkColor = "black", this.taskTextOutsideColor = "calculated", this.taskTextClickableColor = "#003163", this.activeTaskBorderColor = "#534fbc", this.activeTaskBkgColor = "#bfc7ff", this.gridColor = "lightgrey", this.doneTaskBkgColor = "lightgrey", this.doneTaskBorderColor = "grey", this.critBorderColor = "#ff8888", this.critBkgColor = "red", this.todayLineColor = "red", this.vertLineColor = "navy", this.noteFontWeight = this.noteFontWeight || "normal", this.fontWeight = this.fontWeight || "normal", this.personBorder = this.primaryBorderColor, this.personBkg = this.mainBkg, this.archEdgeColor = "calculated", this.archEdgeArrowColor = "calculated", this.archEdgeWidth = "3", this.archGroupBorderColor = this.primaryBorderColor, this.archGroupBorderWidth = "2px", this.rowOdd = "calculated", this.rowEven = "calculated", this.labelColor = "black", this.errorBkgColor = "#552222", this.errorTextColor = "#552222", this.useGradient = !1, this.gradientStart = this.primaryBorderColor, this.gradientStop = this.secondaryBorderColor, this.dropShadow = "drop-shadow(1px 2px 2px rgba(185, 185, 185, 1))", this.updateColors();
  }
  updateColors() {
    this.cScale0 = this.cScale0 || this.primaryColor, this.cScale1 = this.cScale1 || this.secondaryColor, this.cScale2 = this.cScale2 || this.tertiaryColor, this.cScale3 = this.cScale3 || C(this.primaryColor, { h: 30 }), this.cScale4 = this.cScale4 || C(this.primaryColor, { h: 60 }), this.cScale5 = this.cScale5 || C(this.primaryColor, { h: 90 }), this.cScale6 = this.cScale6 || C(this.primaryColor, { h: 120 }), this.cScale7 = this.cScale7 || C(this.primaryColor, { h: 150 }), this.cScale8 = this.cScale8 || C(this.primaryColor, { h: 210 }), this.cScale9 = this.cScale9 || C(this.primaryColor, { h: 270 }), this.cScale10 = this.cScale10 || C(this.primaryColor, { h: 300 }), this.cScale11 = this.cScale11 || C(this.primaryColor, { h: 330 }), this.cScalePeer1 = this.cScalePeer1 || A(this.secondaryColor, 45), this.cScalePeer2 = this.cScalePeer2 || A(this.tertiaryColor, 40);
    for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
      this["cScale" + e] = A(this["cScale" + e], 10), this["cScalePeer" + e] = this["cScalePeer" + e] || A(this["cScale" + e], 25);
    for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
      this["cScaleInv" + e] = this["cScaleInv" + e] || C(this["cScale" + e], { h: 180 });
    for (let e = 0; e < 5; e++)
      this["surface" + e] = this["surface" + e] || C(this.mainBkg, { h: 30, l: -(5 + e * 5) }), this["surfacePeer" + e] = this["surfacePeer" + e] || C(this.mainBkg, { h: 30, l: -(7 + e * 5) });
    if (this.scaleLabelColor = this.scaleLabelColor !== "calculated" && this.scaleLabelColor ? this.scaleLabelColor : this.labelTextColor, this.labelTextColor !== "calculated") {
      this.cScaleLabel0 = this.cScaleLabel0 || _(this.labelTextColor), this.cScaleLabel3 = this.cScaleLabel3 || _(this.labelTextColor);
      for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
        this["cScaleLabel" + e] = this["cScaleLabel" + e] || this.labelTextColor;
    }
    this.nodeBkg = this.mainBkg, this.nodeBorder = this.border1, this.clusterBkg = this.secondBkg, this.clusterBorder = this.border2, this.defaultLinkColor = this.lineColor, this.titleColor = this.textColor, this.edgeLabelBackground = this.labelBackground, this.actorBorder = this.border1, this.actorBkg = this.mainBkg, this.labelBoxBkgColor = this.actorBkg, this.signalColor = this.textColor, this.signalTextColor = this.textColor, this.labelBoxBorderColor = this.actorBorder, this.labelTextColor = this.actorTextColor, this.loopTextColor = this.actorTextColor, this.noteBorderColor = this.border2, this.noteTextColor = this.actorTextColor, this.actorLineColor = this.actorBorder, this.taskTextColor = this.taskTextLightColor, this.taskTextOutsideColor = this.taskTextDarkColor, this.archEdgeColor = this.lineColor, this.archEdgeArrowColor = this.lineColor, this.rowOdd = this.rowOdd || $(this.primaryColor, 75) || "#ffffff", this.rowEven = this.rowEven || $(this.primaryColor, 1), this.transitionColor = this.transitionColor || this.lineColor, this.transitionLabelColor = this.transitionLabelColor || this.textColor, this.stateLabelColor = this.stateLabelColor || this.stateBkg || this.primaryTextColor, this.stateBkg = this.stateBkg || this.mainBkg, this.labelBackgroundColor = this.labelBackgroundColor || this.stateBkg, this.compositeBackground = this.compositeBackground || this.background || this.tertiaryColor, this.altBackground = this.altBackground || "#f0f0f0", this.compositeTitleBackground = this.compositeTitleBackground || this.mainBkg, this.compositeBorder = this.compositeBorder || this.nodeBorder, this.innerEndBackground = this.nodeBorder, this.specialStateColor = this.lineColor, this.errorBkgColor = this.errorBkgColor || this.tertiaryColor, this.errorTextColor = this.errorTextColor || this.tertiaryTextColor, this.transitionColor = this.transitionColor || this.lineColor, this.classText = this.primaryTextColor, this.fillType0 = this.primaryColor, this.fillType1 = this.secondaryColor, this.fillType2 = C(this.primaryColor, { h: 64 }), this.fillType3 = C(this.secondaryColor, { h: 64 }), this.fillType4 = C(this.primaryColor, { h: -64 }), this.fillType5 = C(this.secondaryColor, { h: -64 }), this.fillType6 = C(this.primaryColor, { h: 128 }), this.fillType7 = C(this.secondaryColor, { h: 128 }), this.pie1 = this.pie1 || this.primaryColor, this.pie2 = this.pie2 || this.secondaryColor, this.pie3 = this.pie3 || C(this.tertiaryColor, { l: -40 }), this.pie4 = this.pie4 || C(this.primaryColor, { l: -10 }), this.pie5 = this.pie5 || C(this.secondaryColor, { l: -30 }), this.pie6 = this.pie6 || C(this.tertiaryColor, { l: -20 }), this.pie7 = this.pie7 || C(this.primaryColor, { h: 60, l: -20 }), this.pie8 = this.pie8 || C(this.primaryColor, { h: -60, l: -40 }), this.pie9 = this.pie9 || C(this.primaryColor, { h: 120, l: -40 }), this.pie10 = this.pie10 || C(this.primaryColor, { h: 60, l: -40 }), this.pie11 = this.pie11 || C(this.primaryColor, { h: -90, l: -40 }), this.pie12 = this.pie12 || C(this.primaryColor, { h: 120, l: -30 }), this.pieTitleTextSize = this.pieTitleTextSize || "25px", this.pieTitleTextColor = this.pieTitleTextColor || this.taskTextDarkColor, this.pieSectionTextSize = this.pieSectionTextSize || "17px", this.pieSectionTextColor = this.pieSectionTextColor || this.textColor, this.pieLegendTextSize = this.pieLegendTextSize || "17px", this.pieLegendTextColor = this.pieLegendTextColor || this.taskTextDarkColor, this.pieStrokeColor = this.pieStrokeColor || "black", this.pieStrokeWidth = this.pieStrokeWidth || "2px", this.pieOuterStrokeWidth = this.pieOuterStrokeWidth || "2px", this.pieOuterStrokeColor = this.pieOuterStrokeColor || "black", this.pieOpacity = this.pieOpacity || "0.7", this.venn1 = this.venn1 ?? C(this.primaryColor, { l: -30 }), this.venn2 = this.venn2 ?? C(this.secondaryColor, { l: -30 }), this.venn3 = this.venn3 ?? C(this.tertiaryColor, { l: -40 }), this.venn4 = this.venn4 ?? C(this.primaryColor, { h: 60, l: -30 }), this.venn5 = this.venn5 ?? C(this.primaryColor, { h: -60, l: -30 }), this.venn6 = this.venn6 ?? C(this.secondaryColor, { h: 60, l: -30 }), this.venn7 = this.venn7 ?? C(this.primaryColor, { h: 120, l: -30 }), this.venn8 = this.venn8 ?? C(this.secondaryColor, { h: 120, l: -30 }), this.vennTitleTextColor = this.vennTitleTextColor ?? this.titleColor, this.vennSetTextColor = this.vennSetTextColor ?? this.textColor, this.quadrant1Fill = this.quadrant1Fill || this.primaryColor, this.quadrant2Fill = this.quadrant2Fill || C(this.primaryColor, { r: 5, g: 5, b: 5 }), this.quadrant3Fill = this.quadrant3Fill || C(this.primaryColor, { r: 10, g: 10, b: 10 }), this.quadrant4Fill = this.quadrant4Fill || C(this.primaryColor, { r: 15, g: 15, b: 15 }), this.quadrant1TextFill = this.quadrant1TextFill || this.primaryTextColor, this.quadrant2TextFill = this.quadrant2TextFill || C(this.primaryTextColor, { r: -5, g: -5, b: -5 }), this.quadrant3TextFill = this.quadrant3TextFill || C(this.primaryTextColor, { r: -10, g: -10, b: -10 }), this.quadrant4TextFill = this.quadrant4TextFill || C(this.primaryTextColor, { r: -15, g: -15, b: -15 }), this.quadrantPointFill = this.quadrantPointFill || be(this.quadrant1Fill) ? $(this.quadrant1Fill) : A(this.quadrant1Fill), this.quadrantPointTextFill = this.quadrantPointTextFill || this.primaryTextColor, this.quadrantXAxisTextFill = this.quadrantXAxisTextFill || this.primaryTextColor, this.quadrantYAxisTextFill = this.quadrantYAxisTextFill || this.primaryTextColor, this.quadrantInternalBorderStrokeFill = this.quadrantInternalBorderStrokeFill || this.primaryBorderColor, this.quadrantExternalBorderStrokeFill = this.quadrantExternalBorderStrokeFill || this.primaryBorderColor, this.quadrantTitleFill = this.quadrantTitleFill || this.primaryTextColor, this.radar = {
      axisColor: this.radar?.axisColor || this.lineColor,
      axisStrokeWidth: this.radar?.axisStrokeWidth || 2,
      axisLabelFontSize: this.radar?.axisLabelFontSize || 12,
      curveOpacity: this.radar?.curveOpacity || 0.5,
      curveStrokeWidth: this.radar?.curveStrokeWidth || 2,
      graticuleColor: this.radar?.graticuleColor || "#DEDEDE",
      graticuleStrokeWidth: this.radar?.graticuleStrokeWidth || 1,
      graticuleOpacity: this.radar?.graticuleOpacity || 0.3,
      legendBoxSize: this.radar?.legendBoxSize || 12,
      legendFontSize: this.radar?.legendFontSize || 12
    }, this.xyChart = {
      backgroundColor: this.xyChart?.backgroundColor || this.background,
      titleColor: this.xyChart?.titleColor || this.primaryTextColor,
      dataLabelColor: this.xyChart?.dataLabelColor || this.primaryTextColor,
      xAxisTitleColor: this.xyChart?.xAxisTitleColor || this.primaryTextColor,
      xAxisLabelColor: this.xyChart?.xAxisLabelColor || this.primaryTextColor,
      xAxisTickColor: this.xyChart?.xAxisTickColor || this.primaryTextColor,
      xAxisLineColor: this.xyChart?.xAxisLineColor || this.primaryTextColor,
      yAxisTitleColor: this.xyChart?.yAxisTitleColor || this.primaryTextColor,
      yAxisLabelColor: this.xyChart?.yAxisLabelColor || this.primaryTextColor,
      yAxisTickColor: this.xyChart?.yAxisTickColor || this.primaryTextColor,
      yAxisLineColor: this.xyChart?.yAxisLineColor || this.primaryTextColor,
      plotColorPalette: this.xyChart?.plotColorPalette || "#ECECFF,#8493A6,#FFC3A0,#DCDDE1,#B8E994,#D1A36F,#C3CDE6,#FFB6C1,#496078,#F8F3E3"
    }, this.requirementBackground = this.requirementBackground || this.primaryColor, this.requirementBorderColor = this.requirementBorderColor || this.primaryBorderColor, this.requirementBorderSize = this.requirementBorderSize || "1", this.requirementTextColor = this.requirementTextColor || this.primaryTextColor, this.relationColor = this.relationColor || this.lineColor, this.relationLabelBackground = this.relationLabelBackground || this.labelBackground, this.relationLabelColor = this.relationLabelColor || this.actorTextColor, this.git0 = this.git0 || this.primaryColor, this.git1 = this.git1 || this.secondaryColor, this.git2 = this.git2 || this.tertiaryColor, this.git3 = this.git3 || C(this.primaryColor, { h: -30 }), this.git4 = this.git4 || C(this.primaryColor, { h: -60 }), this.git5 = this.git5 || C(this.primaryColor, { h: -90 }), this.git6 = this.git6 || C(this.primaryColor, { h: 60 }), this.git7 = this.git7 || C(this.primaryColor, { h: 120 }), this.darkMode ? (this.git0 = $(this.git0, 25), this.git1 = $(this.git1, 25), this.git2 = $(this.git2, 25), this.git3 = $(this.git3, 25), this.git4 = $(this.git4, 25), this.git5 = $(this.git5, 25), this.git6 = $(this.git6, 25), this.git7 = $(this.git7, 25)) : (this.git0 = A(this.git0, 25), this.git1 = A(this.git1, 25), this.git2 = A(this.git2, 25), this.git3 = A(this.git3, 25), this.git4 = A(this.git4, 25), this.git5 = A(this.git5, 25), this.git6 = A(this.git6, 25), this.git7 = A(this.git7, 25)), this.gitInv0 = this.gitInv0 || A(_(this.git0), 25), this.gitInv1 = this.gitInv1 || _(this.git1), this.gitInv2 = this.gitInv2 || _(this.git2), this.gitInv3 = this.gitInv3 || _(this.git3), this.gitInv4 = this.gitInv4 || _(this.git4), this.gitInv5 = this.gitInv5 || _(this.git5), this.gitInv6 = this.gitInv6 || _(this.git6), this.gitInv7 = this.gitInv7 || _(this.git7), this.gitBranchLabel0 = this.gitBranchLabel0 || _(this.labelTextColor), this.gitBranchLabel1 = this.gitBranchLabel1 || this.labelTextColor, this.gitBranchLabel2 = this.gitBranchLabel2 || this.labelTextColor, this.gitBranchLabel3 = this.gitBranchLabel3 || _(this.labelTextColor), this.gitBranchLabel4 = this.gitBranchLabel4 || this.labelTextColor, this.gitBranchLabel5 = this.gitBranchLabel5 || this.labelTextColor, this.gitBranchLabel6 = this.gitBranchLabel6 || this.labelTextColor, this.gitBranchLabel7 = this.gitBranchLabel7 || this.labelTextColor, this.tagLabelColor = this.tagLabelColor || this.primaryTextColor, this.tagLabelBackground = this.tagLabelBackground || this.primaryColor, this.tagLabelBorder = this.tagBorder || this.primaryBorderColor, this.tagLabelFontSize = this.tagLabelFontSize || "10px", this.commitLabelColor = this.commitLabelColor || this.secondaryTextColor, this.commitLabelBackground = this.commitLabelBackground || this.secondaryColor, this.commitLabelFontSize = this.commitLabelFontSize || "10px", this.attributeBackgroundColorOdd = this.attributeBackgroundColorOdd || Ae, this.attributeBackgroundColorEven = this.attributeBackgroundColorEven || Me;
  }
  calculate(e) {
    if (Object.keys(this).forEach((r) => {
      this[r] === "calculated" && (this[r] = void 0);
    }), typeof e != "object") {
      this.updateColors();
      return;
    }
    const t = Object.keys(e);
    t.forEach((r) => {
      this[r] = e[r];
    }), this.updateColors(), t.forEach((r) => {
      this[r] = e[r];
    });
  }
}, d0 = /* @__PURE__ */ f((e) => {
  const t = new u0();
  return t.calculate(e), t;
}, "getThemeVariables"), p0 = class {
  static {
    f(this, "Theme");
  }
  constructor() {
    this.background = "#f4f4f4", this.primaryColor = "#cde498", this.secondaryColor = "#cdffb2", this.background = "white", this.mainBkg = "#cde498", this.secondBkg = "#cdffb2", this.lineColor = "green", this.border1 = "#13540c", this.border2 = "#6eaa49", this.arrowheadColor = "green", this.fontFamily = '"trebuchet ms", verdana, arial, sans-serif', this.fontSize = "16px", this.tertiaryColor = $("#cde498", 10), this.primaryBorderColor = at(this.primaryColor, this.darkMode), this.secondaryBorderColor = at(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = at(this.tertiaryColor, this.darkMode), this.primaryTextColor = _(this.primaryColor), this.secondaryTextColor = _(this.secondaryColor), this.tertiaryTextColor = _(this.primaryColor), this.lineColor = _(this.background), this.textColor = _(this.background), this.THEME_COLOR_LIMIT = 12, this.radius = 5, this.strokeWidth = 1, this.nodeBkg = "calculated", this.nodeBorder = "calculated", this.clusterBkg = "calculated", this.clusterBorder = "calculated", this.defaultLinkColor = "calculated", this.titleColor = "#333", this.edgeLabelBackground = "#e8e8e8", this.actorBorder = "calculated", this.actorBkg = "calculated", this.actorTextColor = "black", this.actorLineColor = "calculated", this.signalColor = "#333", this.signalTextColor = "#333", this.labelBoxBkgColor = "calculated", this.labelBoxBorderColor = "#326932", this.labelTextColor = "calculated", this.loopTextColor = "calculated", this.noteBorderColor = "calculated", this.noteBkgColor = "#fff5ad", this.noteTextColor = "calculated", this.activationBorderColor = "#666", this.activationBkgColor = "#f4f4f4", this.sequenceNumberColor = "white", this.sectionBkgColor = "#6eaa49", this.altSectionBkgColor = "white", this.sectionBkgColor2 = "#6eaa49", this.excludeBkgColor = "#eeeeee", this.taskBorderColor = "calculated", this.taskBkgColor = "#487e3a", this.taskTextLightColor = "white", this.taskTextColor = "calculated", this.taskTextDarkColor = "black", this.taskTextOutsideColor = "calculated", this.taskTextClickableColor = "#003163", this.activeTaskBorderColor = "calculated", this.activeTaskBkgColor = "calculated", this.gridColor = "lightgrey", this.doneTaskBkgColor = "lightgrey", this.doneTaskBorderColor = "grey", this.critBorderColor = "#ff8888", this.critBkgColor = "red", this.todayLineColor = "red", this.vertLineColor = "#00BFFF", this.personBorder = this.primaryBorderColor, this.personBkg = this.mainBkg, this.archEdgeColor = "calculated", this.archEdgeArrowColor = "calculated", this.archEdgeWidth = "3", this.archGroupBorderColor = this.primaryBorderColor, this.archGroupBorderWidth = "2px", this.noteFontWeight = "normal", this.fontWeight = "normal", this.labelColor = "black", this.errorBkgColor = "#552222", this.errorTextColor = "#552222", this.useGradient = !0, this.gradientStart = this.primaryBorderColor, this.gradientStop = this.secondaryBorderColor, this.dropShadow = "drop-shadow( 1px 2px 2px rgba(185,185,185,0.5))";
  }
  updateColors() {
    this.actorBorder = A(this.mainBkg, 20), this.actorBkg = this.mainBkg, this.labelBoxBkgColor = this.actorBkg, this.labelTextColor = this.actorTextColor, this.loopTextColor = this.actorTextColor, this.noteBorderColor = this.border2, this.noteTextColor = this.actorTextColor, this.actorLineColor = this.actorBorder, this.cScale0 = this.cScale0 || this.primaryColor, this.cScale1 = this.cScale1 || this.secondaryColor, this.cScale2 = this.cScale2 || this.tertiaryColor, this.cScale3 = this.cScale3 || C(this.primaryColor, { h: 30 }), this.cScale4 = this.cScale4 || C(this.primaryColor, { h: 60 }), this.cScale5 = this.cScale5 || C(this.primaryColor, { h: 90 }), this.cScale6 = this.cScale6 || C(this.primaryColor, { h: 120 }), this.cScale7 = this.cScale7 || C(this.primaryColor, { h: 150 }), this.cScale8 = this.cScale8 || C(this.primaryColor, { h: 210 }), this.cScale9 = this.cScale9 || C(this.primaryColor, { h: 270 }), this.cScale10 = this.cScale10 || C(this.primaryColor, { h: 300 }), this.cScale11 = this.cScale11 || C(this.primaryColor, { h: 330 }), this.cScalePeer1 = this.cScalePeer1 || A(this.secondaryColor, 45), this.cScalePeer2 = this.cScalePeer2 || A(this.tertiaryColor, 40);
    for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
      this["cScale" + e] = A(this["cScale" + e], 10), this["cScalePeer" + e] = this["cScalePeer" + e] || A(this["cScale" + e], 25);
    for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
      this["cScaleInv" + e] = this["cScaleInv" + e] || C(this["cScale" + e], { h: 180 });
    this.scaleLabelColor = this.scaleLabelColor !== "calculated" && this.scaleLabelColor ? this.scaleLabelColor : this.labelTextColor;
    for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
      this["cScaleLabel" + e] = this["cScaleLabel" + e] || this.scaleLabelColor;
    for (let e = 0; e < 5; e++)
      this["surface" + e] = this["surface" + e] || C(this.mainBkg, { h: 30, s: -30, l: -(5 + e * 5) }), this["surfacePeer" + e] = this["surfacePeer" + e] || C(this.mainBkg, { h: 30, s: -30, l: -(8 + e * 5) });
    this.nodeBkg = this.mainBkg, this.nodeBorder = this.border1, this.clusterBkg = this.secondBkg, this.clusterBorder = this.border2, this.defaultLinkColor = this.lineColor, this.taskBorderColor = this.border1, this.taskTextColor = this.taskTextLightColor, this.taskTextOutsideColor = this.taskTextDarkColor, this.activeTaskBorderColor = this.taskBorderColor, this.activeTaskBkgColor = this.mainBkg, this.archEdgeColor = this.lineColor, this.archEdgeArrowColor = this.lineColor, this.rowOdd = this.rowOdd || $(this.mainBkg, 75) || "#ffffff", this.rowEven = this.rowEven || $(this.mainBkg, 20), this.transitionColor = this.transitionColor || this.lineColor, this.transitionLabelColor = this.transitionLabelColor || this.textColor, this.stateLabelColor = this.stateLabelColor || this.stateBkg || this.primaryTextColor, this.stateBkg = this.stateBkg || this.mainBkg, this.labelBackgroundColor = this.labelBackgroundColor || this.stateBkg, this.compositeBackground = this.compositeBackground || this.background || this.tertiaryColor, this.altBackground = this.altBackground || "#f0f0f0", this.compositeTitleBackground = this.compositeTitleBackground || this.mainBkg, this.compositeBorder = this.compositeBorder || this.nodeBorder, this.innerEndBackground = this.primaryBorderColor, this.specialStateColor = this.lineColor, this.errorBkgColor = this.errorBkgColor || this.tertiaryColor, this.errorTextColor = this.errorTextColor || this.tertiaryTextColor, this.transitionColor = this.transitionColor || this.lineColor, this.classText = this.primaryTextColor, this.fillType0 = this.primaryColor, this.fillType1 = this.secondaryColor, this.fillType2 = C(this.primaryColor, { h: 64 }), this.fillType3 = C(this.secondaryColor, { h: 64 }), this.fillType4 = C(this.primaryColor, { h: -64 }), this.fillType5 = C(this.secondaryColor, { h: -64 }), this.fillType6 = C(this.primaryColor, { h: 128 }), this.fillType7 = C(this.secondaryColor, { h: 128 }), this.pie1 = this.pie1 || this.primaryColor, this.pie2 = this.pie2 || this.secondaryColor, this.pie3 = this.pie3 || this.tertiaryColor, this.pie4 = this.pie4 || C(this.primaryColor, { l: -30 }), this.pie5 = this.pie5 || C(this.secondaryColor, { l: -30 }), this.pie6 = this.pie6 || C(this.tertiaryColor, { h: 40, l: -40 }), this.pie7 = this.pie7 || C(this.primaryColor, { h: 60, l: -10 }), this.pie8 = this.pie8 || C(this.primaryColor, { h: -60, l: -10 }), this.pie9 = this.pie9 || C(this.primaryColor, { h: 120, l: 0 }), this.pie10 = this.pie10 || C(this.primaryColor, { h: 60, l: -50 }), this.pie11 = this.pie11 || C(this.primaryColor, { h: -60, l: -50 }), this.pie12 = this.pie12 || C(this.primaryColor, { h: 120, l: -50 }), this.pieTitleTextSize = this.pieTitleTextSize || "25px", this.pieTitleTextColor = this.pieTitleTextColor || this.taskTextDarkColor, this.pieSectionTextSize = this.pieSectionTextSize || "17px", this.pieSectionTextColor = this.pieSectionTextColor || this.textColor, this.pieLegendTextSize = this.pieLegendTextSize || "17px", this.pieLegendTextColor = this.pieLegendTextColor || this.taskTextDarkColor, this.pieStrokeColor = this.pieStrokeColor || "black", this.pieStrokeWidth = this.pieStrokeWidth || "2px", this.pieOuterStrokeWidth = this.pieOuterStrokeWidth || "2px", this.pieOuterStrokeColor = this.pieOuterStrokeColor || "black", this.pieOpacity = this.pieOpacity || "0.7", this.venn1 = this.venn1 ?? C(this.primaryColor, { l: -30 }), this.venn2 = this.venn2 ?? C(this.secondaryColor, { l: -30 }), this.venn3 = this.venn3 ?? C(this.tertiaryColor, { l: -30 }), this.venn4 = this.venn4 ?? C(this.primaryColor, { h: 60, l: -30 }), this.venn5 = this.venn5 ?? C(this.primaryColor, { h: -60, l: -30 }), this.venn6 = this.venn6 ?? C(this.secondaryColor, { h: 60, l: -30 }), this.venn7 = this.venn7 ?? C(this.primaryColor, { h: 120, l: -30 }), this.venn8 = this.venn8 ?? C(this.secondaryColor, { h: 120, l: -30 }), this.vennTitleTextColor = this.vennTitleTextColor ?? this.titleColor, this.vennSetTextColor = this.vennSetTextColor ?? this.textColor, this.quadrant1Fill = this.quadrant1Fill || this.primaryColor, this.quadrant2Fill = this.quadrant2Fill || C(this.primaryColor, { r: 5, g: 5, b: 5 }), this.quadrant3Fill = this.quadrant3Fill || C(this.primaryColor, { r: 10, g: 10, b: 10 }), this.quadrant4Fill = this.quadrant4Fill || C(this.primaryColor, { r: 15, g: 15, b: 15 }), this.quadrant1TextFill = this.quadrant1TextFill || this.primaryTextColor, this.quadrant2TextFill = this.quadrant2TextFill || C(this.primaryTextColor, { r: -5, g: -5, b: -5 }), this.quadrant3TextFill = this.quadrant3TextFill || C(this.primaryTextColor, { r: -10, g: -10, b: -10 }), this.quadrant4TextFill = this.quadrant4TextFill || C(this.primaryTextColor, { r: -15, g: -15, b: -15 }), this.quadrantPointFill = this.quadrantPointFill || be(this.quadrant1Fill) ? $(this.quadrant1Fill) : A(this.quadrant1Fill), this.quadrantPointTextFill = this.quadrantPointTextFill || this.primaryTextColor, this.quadrantXAxisTextFill = this.quadrantXAxisTextFill || this.primaryTextColor, this.quadrantYAxisTextFill = this.quadrantYAxisTextFill || this.primaryTextColor, this.quadrantInternalBorderStrokeFill = this.quadrantInternalBorderStrokeFill || this.primaryBorderColor, this.quadrantExternalBorderStrokeFill = this.quadrantExternalBorderStrokeFill || this.primaryBorderColor, this.quadrantTitleFill = this.quadrantTitleFill || this.primaryTextColor, this.packet = {
      startByteColor: this.primaryTextColor,
      endByteColor: this.primaryTextColor,
      labelColor: this.primaryTextColor,
      titleColor: this.primaryTextColor,
      blockStrokeColor: this.primaryTextColor,
      blockFillColor: this.mainBkg
    }, this.radar = {
      axisColor: this.radar?.axisColor || this.lineColor,
      axisStrokeWidth: this.radar?.axisStrokeWidth || 2,
      axisLabelFontSize: this.radar?.axisLabelFontSize || 12,
      curveOpacity: this.radar?.curveOpacity || 0.5,
      curveStrokeWidth: this.radar?.curveStrokeWidth || 2,
      graticuleColor: this.radar?.graticuleColor || "#DEDEDE",
      graticuleStrokeWidth: this.radar?.graticuleStrokeWidth || 1,
      graticuleOpacity: this.radar?.graticuleOpacity || 0.3,
      legendBoxSize: this.radar?.legendBoxSize || 12,
      legendFontSize: this.radar?.legendFontSize || 12
    }, this.xyChart = {
      backgroundColor: this.xyChart?.backgroundColor || this.background,
      titleColor: this.xyChart?.titleColor || this.primaryTextColor,
      dataLabelColor: this.xyChart?.dataLabelColor || this.primaryTextColor,
      xAxisTitleColor: this.xyChart?.xAxisTitleColor || this.primaryTextColor,
      xAxisLabelColor: this.xyChart?.xAxisLabelColor || this.primaryTextColor,
      xAxisTickColor: this.xyChart?.xAxisTickColor || this.primaryTextColor,
      xAxisLineColor: this.xyChart?.xAxisLineColor || this.primaryTextColor,
      yAxisTitleColor: this.xyChart?.yAxisTitleColor || this.primaryTextColor,
      yAxisLabelColor: this.xyChart?.yAxisLabelColor || this.primaryTextColor,
      yAxisTickColor: this.xyChart?.yAxisTickColor || this.primaryTextColor,
      yAxisLineColor: this.xyChart?.yAxisLineColor || this.primaryTextColor,
      plotColorPalette: this.xyChart?.plotColorPalette || "#CDE498,#FF6B6B,#A0D2DB,#D7BDE2,#F0F0F0,#FFC3A0,#7FD8BE,#FF9A8B,#FAF3E0,#FFF176"
    }, this.requirementBackground = this.requirementBackground || this.primaryColor, this.requirementBorderColor = this.requirementBorderColor || this.primaryBorderColor, this.requirementBorderSize = this.requirementBorderSize || "1", this.requirementTextColor = this.requirementTextColor || this.primaryTextColor, this.relationColor = this.relationColor || this.lineColor, this.relationLabelBackground = this.relationLabelBackground || this.edgeLabelBackground, this.relationLabelColor = this.relationLabelColor || this.actorTextColor, this.git0 = this.git0 || this.primaryColor, this.git1 = this.git1 || this.secondaryColor, this.git2 = this.git2 || this.tertiaryColor, this.git3 = this.git3 || C(this.primaryColor, { h: -30 }), this.git4 = this.git4 || C(this.primaryColor, { h: -60 }), this.git5 = this.git5 || C(this.primaryColor, { h: -90 }), this.git6 = this.git6 || C(this.primaryColor, { h: 60 }), this.git7 = this.git7 || C(this.primaryColor, { h: 120 }), this.darkMode ? (this.git0 = $(this.git0, 25), this.git1 = $(this.git1, 25), this.git2 = $(this.git2, 25), this.git3 = $(this.git3, 25), this.git4 = $(this.git4, 25), this.git5 = $(this.git5, 25), this.git6 = $(this.git6, 25), this.git7 = $(this.git7, 25)) : (this.git0 = A(this.git0, 25), this.git1 = A(this.git1, 25), this.git2 = A(this.git2, 25), this.git3 = A(this.git3, 25), this.git4 = A(this.git4, 25), this.git5 = A(this.git5, 25), this.git6 = A(this.git6, 25), this.git7 = A(this.git7, 25)), this.gitInv0 = this.gitInv0 || _(this.git0), this.gitInv1 = this.gitInv1 || _(this.git1), this.gitInv2 = this.gitInv2 || _(this.git2), this.gitInv3 = this.gitInv3 || _(this.git3), this.gitInv4 = this.gitInv4 || _(this.git4), this.gitInv5 = this.gitInv5 || _(this.git5), this.gitInv6 = this.gitInv6 || _(this.git6), this.gitInv7 = this.gitInv7 || _(this.git7), this.gitBranchLabel0 = this.gitBranchLabel0 || _(this.labelTextColor), this.gitBranchLabel1 = this.gitBranchLabel1 || this.labelTextColor, this.gitBranchLabel2 = this.gitBranchLabel2 || this.labelTextColor, this.gitBranchLabel3 = this.gitBranchLabel3 || _(this.labelTextColor), this.gitBranchLabel4 = this.gitBranchLabel4 || this.labelTextColor, this.gitBranchLabel5 = this.gitBranchLabel5 || this.labelTextColor, this.gitBranchLabel6 = this.gitBranchLabel6 || this.labelTextColor, this.gitBranchLabel7 = this.gitBranchLabel7 || this.labelTextColor, this.tagLabelColor = this.tagLabelColor || this.primaryTextColor, this.tagLabelBackground = this.tagLabelBackground || this.primaryColor, this.tagLabelBorder = this.tagBorder || this.primaryBorderColor, this.tagLabelFontSize = this.tagLabelFontSize || "10px", this.commitLabelColor = this.commitLabelColor || this.secondaryTextColor, this.commitLabelBackground = this.commitLabelBackground || this.secondaryColor, this.commitLabelFontSize = this.commitLabelFontSize || "10px", this.attributeBackgroundColorOdd = this.attributeBackgroundColorOdd || Ae, this.attributeBackgroundColorEven = this.attributeBackgroundColorEven || Me;
  }
  calculate(e) {
    if (typeof e != "object") {
      this.updateColors();
      return;
    }
    const t = Object.keys(e);
    t.forEach((r) => {
      this[r] = e[r];
    }), this.updateColors(), t.forEach((r) => {
      this[r] = e[r];
    });
  }
}, f0 = /* @__PURE__ */ f((e) => {
  const t = new p0();
  return t.calculate(e), t;
}, "getThemeVariables"), g0 = class {
  static {
    f(this, "Theme");
  }
  constructor() {
    this.primaryColor = "#eee", this.contrast = "#707070", this.secondaryColor = $(this.contrast, 55), this.background = "#ffffff", this.tertiaryColor = C(this.primaryColor, { h: -160 }), this.primaryBorderColor = at(this.primaryColor, this.darkMode), this.secondaryBorderColor = at(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = at(this.tertiaryColor, this.darkMode), this.primaryTextColor = _(this.primaryColor), this.secondaryTextColor = _(this.secondaryColor), this.tertiaryTextColor = _(this.tertiaryColor), this.lineColor = _(this.background), this.textColor = _(this.background), this.mainBkg = "#eee", this.secondBkg = "calculated", this.lineColor = "#666", this.border1 = "#999", this.border2 = "calculated", this.note = "#ffa", this.text = "#333", this.critical = "#d42", this.done = "#bbb", this.arrowheadColor = "#333333", this.fontFamily = '"trebuchet ms", verdana, arial, sans-serif', this.fontSize = "16px", this.THEME_COLOR_LIMIT = 12, this.radius = 5, this.strokeWidth = 1, this.nodeBkg = "calculated", this.nodeBorder = "calculated", this.clusterBkg = "calculated", this.clusterBorder = "calculated", this.defaultLinkColor = "calculated", this.titleColor = "calculated", this.edgeLabelBackground = "white", this.actorBorder = "calculated", this.actorBkg = "calculated", this.actorTextColor = "calculated", this.actorLineColor = this.actorBorder, this.signalColor = "calculated", this.signalTextColor = "calculated", this.labelBoxBkgColor = "calculated", this.labelBoxBorderColor = "calculated", this.labelTextColor = "calculated", this.loopTextColor = "calculated", this.noteBorderColor = "calculated", this.noteBkgColor = "calculated", this.noteTextColor = "calculated", this.activationBorderColor = "#666", this.activationBkgColor = "#f4f4f4", this.sequenceNumberColor = "white", this.sectionBkgColor = "calculated", this.altSectionBkgColor = "white", this.sectionBkgColor2 = "calculated", this.excludeBkgColor = "#eeeeee", this.taskBorderColor = "calculated", this.taskBkgColor = "calculated", this.taskTextLightColor = "white", this.taskTextColor = "calculated", this.taskTextDarkColor = "calculated", this.taskTextOutsideColor = "calculated", this.taskTextClickableColor = "#003163", this.activeTaskBorderColor = "calculated", this.activeTaskBkgColor = "calculated", this.gridColor = "calculated", this.doneTaskBkgColor = "calculated", this.doneTaskBorderColor = "calculated", this.critBkgColor = "calculated", this.critBorderColor = "calculated", this.todayLineColor = "calculated", this.vertLineColor = "calculated", this.personBorder = this.primaryBorderColor, this.personBkg = this.mainBkg, this.archEdgeColor = "calculated", this.archEdgeArrowColor = "calculated", this.archEdgeWidth = "3", this.archGroupBorderColor = this.primaryBorderColor, this.archGroupBorderWidth = "2px", this.noteFontWeight = "normal", this.fontWeight = "normal", this.rowOdd = this.rowOdd || $(this.mainBkg, 75) || "#ffffff", this.rowEven = this.rowEven || "#f4f4f4", this.labelColor = "black", this.errorBkgColor = "#552222", this.errorTextColor = "#552222", this.useGradient = !0, this.gradientStart = this.primaryBorderColor, this.gradientStop = this.secondaryBorderColor, this.dropShadow = "drop-shadow( 1px 2px 2px rgba(185,185,185,1))";
  }
  updateColors() {
    this.secondBkg = $(this.contrast, 55), this.border2 = this.contrast, this.actorBorder = $(this.border1, 23), this.actorBkg = this.mainBkg, this.actorTextColor = this.text, this.actorLineColor = this.actorBorder, this.signalColor = this.text, this.signalTextColor = this.text, this.labelBoxBkgColor = this.actorBkg, this.labelBoxBorderColor = this.actorBorder, this.labelTextColor = this.text, this.loopTextColor = this.text, this.noteBorderColor = "#999", this.noteBkgColor = "#666", this.noteTextColor = "#fff", this.cScale0 = this.cScale0 || "#555", this.cScale1 = this.cScale1 || "#F4F4F4", this.cScale2 = this.cScale2 || "#555", this.cScale3 = this.cScale3 || "#BBB", this.cScale4 = this.cScale4 || "#777", this.cScale5 = this.cScale5 || "#999", this.cScale6 = this.cScale6 || "#DDD", this.cScale7 = this.cScale7 || "#FFF", this.cScale8 = this.cScale8 || "#DDD", this.cScale9 = this.cScale9 || "#BBB", this.cScale10 = this.cScale10 || "#999", this.cScale11 = this.cScale11 || "#777";
    for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
      this["cScaleInv" + e] = this["cScaleInv" + e] || _(this["cScale" + e]);
    for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
      this.darkMode ? this["cScalePeer" + e] = this["cScalePeer" + e] || $(this["cScale" + e], 10) : this["cScalePeer" + e] = this["cScalePeer" + e] || A(this["cScale" + e], 10);
    this.scaleLabelColor = this.scaleLabelColor || (this.darkMode ? "black" : this.labelTextColor), this.cScaleLabel0 = this.cScaleLabel0 || this.cScale1, this.cScaleLabel2 = this.cScaleLabel2 || this.cScale1;
    for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
      this["cScaleLabel" + e] = this["cScaleLabel" + e] || this.scaleLabelColor;
    for (let e = 0; e < 5; e++)
      this["surface" + e] = this["surface" + e] || C(this.mainBkg, { l: -(5 + e * 5) }), this["surfacePeer" + e] = this["surfacePeer" + e] || C(this.mainBkg, { l: -(8 + e * 5) });
    this.nodeBkg = this.mainBkg, this.nodeBorder = this.border1, this.clusterBkg = this.secondBkg, this.clusterBorder = this.border2, this.defaultLinkColor = this.lineColor, this.titleColor = this.text, this.sectionBkgColor = $(this.contrast, 30), this.sectionBkgColor2 = $(this.contrast, 30), this.taskBorderColor = A(this.contrast, 10), this.taskBkgColor = this.contrast, this.taskTextColor = this.taskTextLightColor, this.taskTextDarkColor = this.text, this.taskTextOutsideColor = this.taskTextDarkColor, this.activeTaskBorderColor = this.taskBorderColor, this.activeTaskBkgColor = this.mainBkg, this.gridColor = $(this.border1, 30), this.doneTaskBkgColor = this.done, this.doneTaskBorderColor = this.lineColor, this.critBkgColor = this.critical, this.critBorderColor = A(this.critBkgColor, 10), this.todayLineColor = this.critBkgColor, this.vertLineColor = this.critBkgColor, this.archEdgeColor = this.lineColor, this.archEdgeArrowColor = this.lineColor, this.transitionColor = this.transitionColor || "#000", this.transitionLabelColor = this.transitionLabelColor || this.textColor, this.stateLabelColor = this.stateLabelColor || this.stateBkg || this.primaryTextColor, this.stateBkg = this.stateBkg || this.mainBkg, this.labelBackgroundColor = this.labelBackgroundColor || this.stateBkg, this.compositeBackground = this.compositeBackground || this.background || this.tertiaryColor, this.altBackground = this.altBackground || "#f4f4f4", this.compositeTitleBackground = this.compositeTitleBackground || this.mainBkg, this.stateBorder = this.stateBorder || "#000", this.innerEndBackground = this.primaryBorderColor, this.specialStateColor = "#222", this.errorBkgColor = this.errorBkgColor || this.tertiaryColor, this.errorTextColor = this.errorTextColor || this.tertiaryTextColor, this.classText = this.primaryTextColor, this.fillType0 = this.primaryColor, this.fillType1 = this.secondaryColor, this.fillType2 = C(this.primaryColor, { h: 64 }), this.fillType3 = C(this.secondaryColor, { h: 64 }), this.fillType4 = C(this.primaryColor, { h: -64 }), this.fillType5 = C(this.secondaryColor, { h: -64 }), this.fillType6 = C(this.primaryColor, { h: 128 }), this.fillType7 = C(this.secondaryColor, { h: 128 });
    for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
      this["pie" + e] = this["cScale" + e];
    this.pie12 = this.pie0, this.pieTitleTextSize = this.pieTitleTextSize || "25px", this.pieTitleTextColor = this.pieTitleTextColor || this.taskTextDarkColor, this.pieSectionTextSize = this.pieSectionTextSize || "17px", this.pieSectionTextColor = this.pieSectionTextColor || this.textColor, this.pieLegendTextSize = this.pieLegendTextSize || "17px", this.pieLegendTextColor = this.pieLegendTextColor || this.taskTextDarkColor, this.pieStrokeColor = this.pieStrokeColor || "black", this.pieStrokeWidth = this.pieStrokeWidth || "2px", this.pieOuterStrokeWidth = this.pieOuterStrokeWidth || "2px", this.pieOuterStrokeColor = this.pieOuterStrokeColor || "black", this.pieOpacity = this.pieOpacity || "0.7";
    for (let e = 0; e < 8; e++)
      this["venn" + (e + 1)] = this["venn" + (e + 1)] ?? this["cScale" + e];
    this.vennTitleTextColor = this.vennTitleTextColor ?? this.titleColor, this.vennSetTextColor = this.vennSetTextColor ?? this.textColor, this.quadrant1Fill = this.quadrant1Fill || this.primaryColor, this.quadrant2Fill = this.quadrant2Fill || C(this.primaryColor, { r: 5, g: 5, b: 5 }), this.quadrant3Fill = this.quadrant3Fill || C(this.primaryColor, { r: 10, g: 10, b: 10 }), this.quadrant4Fill = this.quadrant4Fill || C(this.primaryColor, { r: 15, g: 15, b: 15 }), this.quadrant1TextFill = this.quadrant1TextFill || this.primaryTextColor, this.quadrant2TextFill = this.quadrant2TextFill || C(this.primaryTextColor, { r: -5, g: -5, b: -5 }), this.quadrant3TextFill = this.quadrant3TextFill || C(this.primaryTextColor, { r: -10, g: -10, b: -10 }), this.quadrant4TextFill = this.quadrant4TextFill || C(this.primaryTextColor, { r: -15, g: -15, b: -15 }), this.quadrantPointFill = this.quadrantPointFill || be(this.quadrant1Fill) ? $(this.quadrant1Fill) : A(this.quadrant1Fill), this.quadrantPointTextFill = this.quadrantPointTextFill || this.primaryTextColor, this.quadrantXAxisTextFill = this.quadrantXAxisTextFill || this.primaryTextColor, this.quadrantYAxisTextFill = this.quadrantYAxisTextFill || this.primaryTextColor, this.quadrantInternalBorderStrokeFill = this.quadrantInternalBorderStrokeFill || this.primaryBorderColor, this.quadrantExternalBorderStrokeFill = this.quadrantExternalBorderStrokeFill || this.primaryBorderColor, this.quadrantTitleFill = this.quadrantTitleFill || this.primaryTextColor, this.xyChart = {
      backgroundColor: this.xyChart?.backgroundColor || this.background,
      titleColor: this.xyChart?.titleColor || this.primaryTextColor,
      dataLabelColor: this.xyChart?.dataLabelColor || this.primaryTextColor,
      xAxisTitleColor: this.xyChart?.xAxisTitleColor || this.primaryTextColor,
      xAxisLabelColor: this.xyChart?.xAxisLabelColor || this.primaryTextColor,
      xAxisTickColor: this.xyChart?.xAxisTickColor || this.primaryTextColor,
      xAxisLineColor: this.xyChart?.xAxisLineColor || this.primaryTextColor,
      yAxisTitleColor: this.xyChart?.yAxisTitleColor || this.primaryTextColor,
      yAxisLabelColor: this.xyChart?.yAxisLabelColor || this.primaryTextColor,
      yAxisTickColor: this.xyChart?.yAxisTickColor || this.primaryTextColor,
      yAxisLineColor: this.xyChart?.yAxisLineColor || this.primaryTextColor,
      plotColorPalette: this.xyChart?.plotColorPalette || "#EEE,#6BB8E4,#8ACB88,#C7ACD6,#E8DCC2,#FFB2A8,#FFF380,#7E8D91,#FFD8B1,#FAF3E0"
    }, this.radar = {
      axisColor: this.radar?.axisColor || this.lineColor,
      axisStrokeWidth: this.radar?.axisStrokeWidth || 2,
      axisLabelFontSize: this.radar?.axisLabelFontSize || 12,
      curveOpacity: this.radar?.curveOpacity || 0.5,
      curveStrokeWidth: this.radar?.curveStrokeWidth || 2,
      graticuleColor: this.radar?.graticuleColor || "#DEDEDE",
      graticuleStrokeWidth: this.radar?.graticuleStrokeWidth || 1,
      graticuleOpacity: this.radar?.graticuleOpacity || 0.3,
      legendBoxSize: this.radar?.legendBoxSize || 12,
      legendFontSize: this.radar?.legendFontSize || 12
    }, this.requirementBackground = this.requirementBackground || this.primaryColor, this.requirementBorderColor = this.requirementBorderColor || this.primaryBorderColor, this.requirementBorderSize = this.requirementBorderSize || "1", this.requirementTextColor = this.requirementTextColor || this.primaryTextColor, this.relationColor = this.relationColor || this.lineColor, this.relationLabelBackground = this.relationLabelBackground || this.edgeLabelBackground, this.relationLabelColor = this.relationLabelColor || this.actorTextColor, this.git0 = A(this.pie1, 25) || this.primaryColor, this.git1 = this.pie2 || this.secondaryColor, this.git2 = this.pie3 || this.tertiaryColor, this.git3 = this.pie4 || C(this.primaryColor, { h: -30 }), this.git4 = this.pie5 || C(this.primaryColor, { h: -60 }), this.git5 = this.pie6 || C(this.primaryColor, { h: -90 }), this.git6 = this.pie7 || C(this.primaryColor, { h: 60 }), this.git7 = this.pie8 || C(this.primaryColor, { h: 120 }), this.gitInv0 = this.gitInv0 || _(this.git0), this.gitInv1 = this.gitInv1 || _(this.git1), this.gitInv2 = this.gitInv2 || _(this.git2), this.gitInv3 = this.gitInv3 || _(this.git3), this.gitInv4 = this.gitInv4 || _(this.git4), this.gitInv5 = this.gitInv5 || _(this.git5), this.gitInv6 = this.gitInv6 || _(this.git6), this.gitInv7 = this.gitInv7 || _(this.git7), this.branchLabelColor = this.branchLabelColor || this.labelTextColor, this.gitBranchLabel0 = this.branchLabelColor, this.gitBranchLabel1 = "white", this.gitBranchLabel2 = this.branchLabelColor, this.gitBranchLabel3 = "white", this.gitBranchLabel4 = this.branchLabelColor, this.gitBranchLabel5 = this.branchLabelColor, this.gitBranchLabel6 = this.branchLabelColor, this.gitBranchLabel7 = this.branchLabelColor, this.tagLabelColor = this.tagLabelColor || this.primaryTextColor, this.tagLabelBackground = this.tagLabelBackground || this.primaryColor, this.tagLabelBorder = this.tagBorder || this.primaryBorderColor, this.tagLabelFontSize = this.tagLabelFontSize || "10px", this.commitLabelColor = this.commitLabelColor || this.secondaryTextColor, this.commitLabelBackground = this.commitLabelBackground || this.secondaryColor, this.commitLabelFontSize = this.commitLabelFontSize || "10px", this.attributeBackgroundColorOdd = this.attributeBackgroundColorOdd || Ae, this.attributeBackgroundColorEven = this.attributeBackgroundColorEven || Me;
  }
  calculate(e) {
    if (typeof e != "object") {
      this.updateColors();
      return;
    }
    const t = Object.keys(e);
    t.forEach((r) => {
      this[r] = e[r];
    }), this.updateColors(), t.forEach((r) => {
      this[r] = e[r];
    });
  }
}, m0 = /* @__PURE__ */ f((e) => {
  const t = new g0();
  return t.calculate(e), t;
}, "getThemeVariables"), y0 = class {
  static {
    f(this, "Theme");
  }
  constructor() {
    this.background = "#ffffff", this.primaryColor = "#cccccc", this.mainBkg = "#ffffff", this.noteBkgColor = "#fff5ad", this.noteTextColor = "#333", this.THEME_COLOR_LIMIT = 12, this.radius = 3, this.strokeWidth = 2, this.primaryBorderColor = at(this.primaryColor, this.darkMode), this.fontFamily = "arial, sans-serif", this.fontSize = "14px", this.nodeBorder = "#000000", this.stateBorder = "#000000", this.useGradient = !0, this.gradientStart = "#0042eb", this.gradientStop = "#eb0042", this.dropShadow = "drop-shadow( 0px 1px 2px rgba(0, 0, 0, 0.25));", this.tertiaryColor = "#ffffff", this.archEdgeColor = "calculated", this.archEdgeArrowColor = "calculated", this.archEdgeWidth = "3", this.archGroupBorderColor = this.primaryBorderColor, this.archGroupBorderWidth = "2px", this.noteFontWeight = "normal", this.fontWeight = "normal";
  }
  updateColors() {
    this.primaryTextColor = this.primaryTextColor || (this.darkMode ? "#eee" : "#333"), this.secondaryColor = this.secondaryColor || C(this.primaryColor, { h: -120 }), this.tertiaryColor = this.tertiaryColor || C(this.primaryColor, { h: 180, l: 5 }), this.primaryBorderColor = this.primaryBorderColor || at(this.primaryColor, this.darkMode), this.secondaryBorderColor = this.secondaryBorderColor || at(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = this.tertiaryBorderColor || at(this.tertiaryColor, this.darkMode), this.noteBorderColor = this.noteBorderColor || at(this.noteBkgColor, this.darkMode), this.noteBkgColor = this.noteBkgColor || "#fff5ad", this.noteTextColor = this.noteTextColor || "#333", this.secondaryTextColor = this.secondaryTextColor || _(this.secondaryColor), this.tertiaryTextColor = this.tertiaryTextColor || _(this.tertiaryColor), this.lineColor = this.lineColor || _(this.background), this.arrowheadColor = this.arrowheadColor || _(this.background), this.textColor = this.textColor || this.primaryTextColor, this.border2 = this.border2 || this.tertiaryBorderColor, this.nodeBkg = this.nodeBkg || this.primaryColor, this.mainBkg = this.mainBkg || this.primaryColor, this.nodeBorder = this.nodeBorder || this.primaryBorderColor, this.clusterBkg = this.clusterBkg || this.tertiaryColor, this.clusterBorder = this.clusterBorder || this.tertiaryBorderColor, this.defaultLinkColor = this.defaultLinkColor || this.lineColor, this.titleColor = this.titleColor || this.tertiaryTextColor, this.edgeLabelBackground = this.edgeLabelBackground || (this.darkMode ? A(this.secondaryColor, 30) : this.secondaryColor), this.nodeTextColor = this.nodeTextColor || this.primaryTextColor, this.actorBorder = this.actorBorder || this.primaryBorderColor, this.actorBkg = this.actorBkg || this.mainBkg, this.actorTextColor = this.actorTextColor || this.primaryTextColor, this.actorLineColor = this.actorLineColor || this.actorBorder, this.labelBoxBkgColor = this.labelBoxBkgColor || this.actorBkg, this.signalColor = this.signalColor || this.textColor, this.signalTextColor = this.signalTextColor || this.textColor, this.labelBoxBorderColor = this.labelBoxBorderColor || this.actorBorder, this.labelTextColor = this.labelTextColor || this.actorTextColor, this.loopTextColor = this.loopTextColor || this.actorTextColor, this.activationBorderColor = this.activationBorderColor || A(this.secondaryColor, 10), this.activationBkgColor = this.activationBkgColor || this.secondaryColor, this.sequenceNumberColor = this.sequenceNumberColor || _(this.lineColor);
    const e = "#ECECFE", t = "#E9E9F1", r = C(e, { h: 180, l: 5 });
    if (this.sectionBkgColor = this.sectionBkgColor || r, this.altSectionBkgColor = this.altSectionBkgColor || "white", this.sectionBkgColor = this.sectionBkgColor || t, this.sectionBkgColor2 = this.sectionBkgColor2 || e, this.excludeBkgColor = this.excludeBkgColor || "#eeeeee", this.taskBorderColor = this.taskBorderColor || this.primaryBorderColor, this.taskBkgColor = this.taskBkgColor || e, this.activeTaskBorderColor = this.activeTaskBorderColor || e, this.activeTaskBkgColor = this.activeTaskBkgColor || $(e, 23), this.gridColor = this.gridColor || "lightgrey", this.doneTaskBkgColor = this.doneTaskBkgColor || "lightgrey", this.doneTaskBorderColor = this.doneTaskBorderColor || "grey", this.critBorderColor = this.critBorderColor || "#ff8888", this.critBkgColor = this.critBkgColor || "red", this.todayLineColor = this.todayLineColor || "red", this.taskTextColor = this.taskTextColor || this.textColor, this.taskTextOutsideColor = this.taskTextOutsideColor || this.textColor, this.vertLineColor = this.vertLineColor || this.primaryBorderColor, this.taskTextLightColor = this.taskTextLightColor || this.textColor, this.taskTextColor = this.taskTextColor || this.primaryTextColor, this.taskTextDarkColor = this.taskTextDarkColor || this.textColor, this.taskTextClickableColor = this.taskTextClickableColor || "#003163", this.archEdgeColor = this.lineColor, this.archEdgeArrowColor = this.lineColor, this.personBorder = this.personBorder || this.primaryBorderColor, this.personBkg = this.personBkg || this.mainBkg, this.transitionColor = this.transitionColor || this.lineColor, this.transitionLabelColor = this.transitionLabelColor || this.textColor, this.stateLabelColor = this.stateLabelColor || this.stateBkg || this.primaryTextColor, this.stateBkg = this.stateBkg || this.mainBkg, this.labelBackgroundColor = this.labelBackgroundColor || this.stateBkg, this.compositeBackground = this.compositeBackground || this.background || this.tertiaryColor, this.altBackground = this.altBackground || "#f0f0f0", this.compositeTitleBackground = this.compositeTitleBackground || this.mainBkg, this.compositeBorder = this.compositeBorder || this.nodeBorder, this.innerEndBackground = this.nodeBorder, this.errorBkgColor = this.errorBkgColor || this.tertiaryColor, this.errorTextColor = this.errorTextColor || this.tertiaryTextColor, this.transitionColor = this.transitionColor || this.lineColor, this.specialStateColor = this.lineColor, this.cScale0 = this.cScale0 || e, this.cScale1 = this.cScale1 || t, this.cScale2 = this.cScale2 || r, this.cScale3 = this.cScale3 || C(e, { h: 30 }), this.cScale4 = this.cScale4 || C(e, { h: 60 }), this.cScale5 = this.cScale5 || C(e, { h: 90 }), this.cScale6 = this.cScale6 || C(e, { h: 120 }), this.cScale7 = this.cScale7 || C(e, { h: 150 }), this.cScale8 = this.cScale8 || C(e, { h: 210, l: 150 }), this.cScale9 = this.cScale9 || C(e, { h: 270 }), this.cScale10 = this.cScale10 || C(e, { h: 300 }), this.cScale11 = this.cScale11 || C(e, { h: 330 }), this.darkMode)
      for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
        this["cScale" + s] = A(this["cScale" + s], 75);
    else
      for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
        this["cScale" + s] = A(this["cScale" + s], 25);
    for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
      this["cScaleInv" + s] = this["cScaleInv" + s] || _(this["cScale" + s]);
    for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
      this.darkMode ? this["cScalePeer" + s] = this["cScalePeer" + s] || $(this["cScale" + s], 10) : this["cScalePeer" + s] = this["cScalePeer" + s] || A(this["cScale" + s], 10);
    this.scaleLabelColor = this.scaleLabelColor || this.labelTextColor;
    for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
      this["cScaleLabel" + s] = this["cScaleLabel" + s] || this.scaleLabelColor;
    const i = this.darkMode ? -4 : -1;
    for (let s = 0; s < 5; s++)
      this["surface" + s] = this["surface" + s] || C(this.mainBkg, { h: 180, s: -15, l: i * (5 + s * 3) }), this["surfacePeer" + s] = this["surfacePeer" + s] || C(this.mainBkg, { h: 180, s: -15, l: i * (8 + s * 3) });
    this.classText = this.classText || this.textColor, this.fillType0 = this.fillType0 || e, this.fillType1 = this.fillType1 || t, this.fillType2 = this.fillType2 || C(e, { h: 64 }), this.fillType3 = this.fillType3 || C(t, { h: 64 }), this.fillType4 = this.fillType4 || C(e, { h: -64 }), this.fillType5 = this.fillType5 || C(t, { h: -64 }), this.fillType6 = this.fillType6 || C(e, { h: 128 }), this.fillType7 = this.fillType7 || C(t, { h: 128 }), this.pie1 = this.pie1 || e, this.pie2 = this.pie2 || t, this.pie3 = this.pie3 || r, this.pie4 = this.pie4 || C(e, { l: -10 }), this.pie5 = this.pie5 || C(t, { l: -10 }), this.pie6 = this.pie6 || C(r, { l: -10 }), this.pie7 = this.pie7 || C(e, { h: 60, l: -10 }), this.pie8 = this.pie8 || C(e, { h: -60, l: -10 }), this.pie9 = this.pie9 || C(e, { h: 120, l: 0 }), this.pie10 = this.pie10 || C(e, { h: 60, l: -20 }), this.pie11 = this.pie11 || C(e, { h: -60, l: -20 }), this.pie12 = this.pie12 || C(e, { h: 120, l: -10 }), this.pieTitleTextSize = this.pieTitleTextSize || "25px", this.pieTitleTextColor = this.pieTitleTextColor || this.taskTextDarkColor, this.pieSectionTextSize = this.pieSectionTextSize || "17px", this.pieSectionTextColor = this.pieSectionTextColor || this.textColor, this.pieLegendTextSize = this.pieLegendTextSize || "17px", this.pieLegendTextColor = this.pieLegendTextColor || this.taskTextDarkColor, this.pieStrokeColor = this.pieStrokeColor || "black", this.pieStrokeWidth = this.pieStrokeWidth || "2px", this.pieOuterStrokeWidth = this.pieOuterStrokeWidth || "2px", this.pieOuterStrokeColor = this.pieOuterStrokeColor || "black", this.pieOpacity = this.pieOpacity || "0.7", this.vennTitleTextColor = this.vennTitleTextColor ?? this.titleColor, this.vennSetTextColor = this.vennSetTextColor ?? this.textColor, this.quadrant1Fill = this.quadrant1Fill || e, this.quadrant2Fill = this.quadrant2Fill || C(e, { r: 5, g: 5, b: 5 }), this.quadrant3Fill = this.quadrant3Fill || C(e, { r: 10, g: 10, b: 10 }), this.quadrant4Fill = this.quadrant4Fill || C(e, { r: 15, g: 15, b: 15 }), this.quadrant1TextFill = this.quadrant1TextFill || this.primaryTextColor, this.quadrant2TextFill = this.quadrant2TextFill || C(this.primaryTextColor, { r: -5, g: -5, b: -5 }), this.quadrant3TextFill = this.quadrant3TextFill || C(this.primaryTextColor, { r: -10, g: -10, b: -10 }), this.quadrant4TextFill = this.quadrant4TextFill || C(this.primaryTextColor, { r: -15, g: -15, b: -15 }), this.quadrantPointFill = this.quadrantPointFill || be(this.quadrant1Fill) ? $(this.quadrant1Fill) : A(this.quadrant1Fill), this.quadrantPointTextFill = this.quadrantPointTextFill || this.primaryTextColor, this.quadrantXAxisTextFill = this.quadrantXAxisTextFill || this.primaryTextColor, this.quadrantYAxisTextFill = this.quadrantYAxisTextFill || this.primaryTextColor, this.quadrantInternalBorderStrokeFill = this.quadrantInternalBorderStrokeFill || this.primaryBorderColor, this.quadrantExternalBorderStrokeFill = this.quadrantExternalBorderStrokeFill || this.primaryBorderColor, this.quadrantTitleFill = this.quadrantTitleFill || this.primaryTextColor, this.xyChart = {
      backgroundColor: this.xyChart?.backgroundColor || this.background,
      titleColor: this.xyChart?.titleColor || this.primaryTextColor,
      xAxisTitleColor: this.xyChart?.xAxisTitleColor || this.primaryTextColor,
      xAxisLabelColor: this.xyChart?.xAxisLabelColor || this.primaryTextColor,
      xAxisTickColor: this.xyChart?.xAxisTickColor || this.primaryTextColor,
      xAxisLineColor: this.xyChart?.xAxisLineColor || this.primaryTextColor,
      yAxisTitleColor: this.xyChart?.yAxisTitleColor || this.primaryTextColor,
      yAxisLabelColor: this.xyChart?.yAxisLabelColor || this.primaryTextColor,
      yAxisTickColor: this.xyChart?.yAxisTickColor || this.primaryTextColor,
      yAxisLineColor: this.xyChart?.yAxisLineColor || this.primaryTextColor,
      plotColorPalette: this.xyChart?.plotColorPalette || "#FFF4DD,#FFD8B1,#FFA07A,#ECEFF1,#D6DBDF,#C3E0A8,#FFB6A4,#FFD74D,#738FA7,#FFFFF0"
    }, this.requirementBackground = this.requirementBackground || e, this.requirementBorderColor = this.requirementBorderColor || this.primaryBorderColor, this.requirementBorderSize = this.requirementBorderSize || "1", this.requirementTextColor = this.requirementTextColor || this.primaryTextColor, this.relationColor = this.relationColor || this.lineColor, this.relationLabelBackground = this.relationLabelBackground || (this.darkMode ? A(this.secondaryColor, 30) : this.secondaryColor), this.relationLabelColor = this.relationLabelColor || this.actorTextColor, this.git0 = this.git0 || e, this.git1 = this.git1 || t, this.git2 = this.git2 || r, this.git3 = this.git3 || C(e, { h: -30 }), this.git4 = this.git4 || C(e, { h: -60 }), this.git5 = this.git5 || C(e, { h: -90 }), this.git6 = this.git6 || C(e, { h: 60 }), this.git7 = this.git7 || C(e, { h: 120 }), this.darkMode ? (this.git0 = $(this.git0, 25), this.git1 = $(this.git1, 25), this.git2 = $(this.git2, 25), this.git3 = $(this.git3, 25), this.git4 = $(this.git4, 25), this.git5 = $(this.git5, 25), this.git6 = $(this.git6, 25), this.git7 = $(this.git7, 25)) : (this.git0 = A(this.git0, 25), this.git1 = A(this.git1, 25), this.git2 = A(this.git2, 25), this.git3 = A(this.git3, 25), this.git4 = A(this.git4, 25), this.git5 = A(this.git5, 25), this.git6 = A(this.git6, 25), this.git7 = A(this.git7, 25)), this.gitInv0 = this.gitInv0 || _(this.git0), this.gitInv1 = this.gitInv1 || _(this.git1), this.gitInv2 = this.gitInv2 || _(this.git2), this.gitInv3 = this.gitInv3 || _(this.git3), this.gitInv4 = this.gitInv4 || _(this.git4), this.gitInv5 = this.gitInv5 || _(this.git5), this.gitInv6 = this.gitInv6 || _(this.git6), this.gitInv7 = this.gitInv7 || _(this.git7), this.branchLabelColor = this.branchLabelColor || (this.darkMode ? "black" : this.labelTextColor), this.gitBranchLabel0 = this.gitBranchLabel0 || this.branchLabelColor, this.gitBranchLabel1 = this.gitBranchLabel1 || this.branchLabelColor, this.gitBranchLabel2 = this.gitBranchLabel2 || this.branchLabelColor, this.gitBranchLabel3 = this.gitBranchLabel3 || this.branchLabelColor, this.gitBranchLabel4 = this.gitBranchLabel4 || this.branchLabelColor, this.gitBranchLabel5 = this.gitBranchLabel5 || this.branchLabelColor, this.gitBranchLabel6 = this.gitBranchLabel6 || this.branchLabelColor, this.gitBranchLabel7 = this.gitBranchLabel7 || this.branchLabelColor, this.tagLabelColor = this.tagLabelColor || this.primaryTextColor, this.tagLabelBackground = this.tagLabelBackground || this.primaryColor, this.tagLabelBorder = this.tagBorder || this.primaryBorderColor, this.tagLabelFontSize = this.tagLabelFontSize || "10px", this.commitLabelColor = this.commitLabelColor || this.secondaryTextColor, this.commitLabelBackground = this.commitLabelBackground || this.secondaryColor, this.commitLabelFontSize = this.commitLabelFontSize || "10px", this.attributeBackgroundColorOdd = this.attributeBackgroundColorOdd || Ae, this.attributeBackgroundColorEven = this.attributeBackgroundColorEven || Me;
  }
  calculate(e) {
    if (typeof e != "object") {
      this.updateColors();
      return;
    }
    const t = Object.keys(e);
    t.forEach((r) => {
      this[r] = e[r];
    }), this.updateColors(), t.forEach((r) => {
      this[r] = e[r];
    });
  }
}, C0 = /* @__PURE__ */ f((e) => {
  const t = new y0();
  return t.calculate(e), t;
}, "getThemeVariables"), x0 = class {
  static {
    f(this, "Theme");
  }
  constructor() {
    this.background = "#333", this.primaryColor = "#1f2020", this.secondaryColor = $(this.primaryColor, 16), this.tertiaryColor = C(this.primaryColor, { h: -160 }), this.primaryBorderColor = _(this.background), this.secondaryBorderColor = at(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = at(this.tertiaryColor, this.darkMode), this.primaryTextColor = _(this.primaryColor), this.secondaryTextColor = _(this.secondaryColor), this.tertiaryTextColor = _(this.tertiaryColor), this.mainBkg = "#2a2020", this.secondBkg = "calculated", this.mainContrastColor = "lightgrey", this.darkTextColor = $(_("#323D47"), 10), this.border1 = "#ccc", this.border2 = Je(255, 255, 255, 0.25), this.arrowheadColor = _(this.background), this.fontFamily = "arial, sans-serif", this.fontSize = "14px", this.labelBackground = "#181818", this.textColor = "#ccc", this.THEME_COLOR_LIMIT = 12, this.radius = 3, this.strokeWidth = 1, this.noteBkgColor = "#fff5ad", this.noteTextColor = "#333", this.THEME_COLOR_LIMIT = 12, this.fontFamily = "arial, sans-serif", this.fontSize = "14px", this.useGradient = !0, this.gradientStart = "#0042eb", this.gradientStop = "#eb0042", this.dropShadow = "drop-shadow( 1px 2px 2px rgba(185,185,185,0.2))", this.archEdgeColor = "calculated", this.archEdgeArrowColor = "calculated", this.archEdgeWidth = "3", this.archGroupBorderColor = this.primaryBorderColor, this.archGroupBorderWidth = "2px", this.noteFontWeight = "normal", this.fontWeight = "normal";
  }
  updateColors() {
    if (this.primaryTextColor = this.primaryTextColor || (this.darkMode ? "#eee" : "#333"), this.secondaryColor = this.secondaryColor || C(this.primaryColor, { h: -120 }), this.tertiaryColor = this.tertiaryColor || C(this.primaryColor, { h: 180, l: 5 }), this.primaryBorderColor = this.primaryBorderColor || at(this.primaryColor, this.darkMode), this.secondaryBorderColor = this.secondaryBorderColor || at(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = this.tertiaryBorderColor || at(this.tertiaryColor, this.darkMode), this.noteBorderColor = this.noteBorderColor || at(this.noteBkgColor, this.darkMode), this.noteBkgColor = this.noteBkgColor || "#fff5ad", this.noteTextColor = this.noteTextColor || "#333", this.secondaryTextColor = this.secondaryTextColor || _(this.secondaryColor), this.tertiaryTextColor = this.tertiaryTextColor || _(this.tertiaryColor), this.lineColor = this.lineColor || _(this.background), this.arrowheadColor = this.arrowheadColor || _(this.background), this.textColor = this.textColor || this.primaryTextColor, this.border2 = this.border2 || this.tertiaryBorderColor, this.nodeBkg = this.nodeBkg || this.primaryColor, this.mainBkg = this.mainBkg || this.primaryColor, this.nodeBorder = this.nodeBorder || this.border1, this.clusterBkg = this.clusterBkg || this.tertiaryColor, this.clusterBorder = this.clusterBorder || this.tertiaryBorderColor, this.defaultLinkColor = this.defaultLinkColor || this.lineColor, this.titleColor = this.titleColor || this.tertiaryTextColor, this.edgeLabelBackground = this.edgeLabelBackground || (this.darkMode ? A(this.secondaryColor, 30) : this.secondaryColor), this.nodeTextColor = this.nodeTextColor || this.primaryTextColor, this.actorBorder = this.actorBorder || this.primaryBorderColor, this.actorBkg = this.actorBkg || this.mainBkg, this.actorTextColor = this.actorTextColor || this.primaryTextColor, this.actorLineColor = this.actorLineColor || this.actorBorder, this.labelBoxBkgColor = this.labelBoxBkgColor || this.actorBkg, this.signalColor = this.signalColor || this.textColor, this.signalTextColor = this.signalTextColor || this.textColor, this.labelBoxBorderColor = this.labelBoxBorderColor || this.actorBorder, this.labelTextColor = this.labelTextColor || this.actorTextColor, this.loopTextColor = this.loopTextColor || this.actorTextColor, this.activationBorderColor = this.activationBorderColor || A(this.secondaryColor, 10), this.activationBkgColor = this.activationBkgColor || this.secondaryColor, this.sequenceNumberColor = this.sequenceNumberColor || _(this.lineColor), this.sectionBkgColor = this.sectionBkgColor || this.tertiaryColor, this.altSectionBkgColor = this.altSectionBkgColor || "white", this.sectionBkgColor = this.sectionBkgColor || this.secondaryColor, this.sectionBkgColor2 = this.sectionBkgColor2 || this.primaryColor, this.excludeBkgColor = this.excludeBkgColor || "#eeeeee", this.taskBorderColor = this.taskBorderColor || this.primaryBorderColor, this.taskBkgColor = this.taskBkgColor || this.primaryColor, this.activeTaskBorderColor = this.activeTaskBorderColor || this.primaryColor, this.activeTaskBkgColor = this.activeTaskBkgColor || $(this.primaryColor, 23), this.gridColor = this.gridColor || "lightgrey", this.doneTaskBkgColor = this.doneTaskBkgColor || "lightgrey", this.doneTaskBorderColor = this.doneTaskBorderColor || "grey", this.critBorderColor = this.critBorderColor || "#ff8888", this.critBkgColor = this.critBkgColor || "red", this.todayLineColor = this.todayLineColor || "red", this.vertLineColor = this.vertLineColor || this.primaryBorderColor, this.taskTextColor = this.taskTextColor || this.textColor, this.taskTextOutsideColor = this.taskTextOutsideColor || this.textColor, this.taskTextLightColor = this.taskTextLightColor || this.textColor, this.taskTextColor = this.taskTextColor || this.primaryTextColor, this.taskTextDarkColor = this.taskTextDarkColor || this.textColor, this.taskTextClickableColor = this.taskTextClickableColor || "#003163", this.archEdgeColor = this.lineColor, this.archEdgeArrowColor = this.lineColor, this.personBorder = this.personBorder || this.primaryBorderColor, this.personBkg = this.personBkg || this.mainBkg, this.transitionColor = this.transitionColor || this.lineColor, this.transitionLabelColor = this.transitionLabelColor || this.textColor, this.stateLabelColor = this.stateLabelColor || this.stateBkg || this.primaryTextColor, this.stateBkg = this.stateBkg || this.mainBkg, this.labelBackgroundColor = this.labelBackgroundColor || this.stateBkg, this.compositeBackground = this.compositeBackground || this.background || this.tertiaryColor, this.altBackground = this.altBackground || "#f0f0f0", this.compositeTitleBackground = this.compositeTitleBackground || this.mainBkg, this.compositeBorder = this.compositeBorder || this.nodeBorder, this.innerEndBackground = this.nodeBorder, this.errorBkgColor = this.errorBkgColor || this.tertiaryColor, this.errorTextColor = this.errorTextColor || this.tertiaryTextColor, this.transitionColor = this.transitionColor || this.lineColor, this.specialStateColor = this.lineColor, this.cScale0 = this.cScale0 || this.primaryColor, this.cScale1 = this.cScale1 || this.secondaryColor, this.cScale2 = this.cScale2 || this.tertiaryColor, this.cScale3 = this.cScale3 || C(this.primaryColor, { h: 30 }), this.cScale4 = this.cScale4 || C(this.primaryColor, { h: 60 }), this.cScale5 = this.cScale5 || C(this.primaryColor, { h: 90 }), this.cScale6 = this.cScale6 || C(this.primaryColor, { h: 120 }), this.cScale7 = this.cScale7 || C(this.primaryColor, { h: 150 }), this.cScale8 = this.cScale8 || C(this.primaryColor, { h: 210, l: 150 }), this.cScale9 = this.cScale9 || C(this.primaryColor, { h: 270 }), this.cScale10 = this.cScale10 || C(this.primaryColor, { h: 300 }), this.cScale11 = this.cScale11 || C(this.primaryColor, { h: 330 }), this.darkMode)
      for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
        this["cScale" + t] = A(this["cScale" + t], 75);
    else
      for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
        this["cScale" + t] = A(this["cScale" + t], 25);
    for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
      this["cScaleInv" + t] = this["cScaleInv" + t] || _(this["cScale" + t]);
    for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
      this.darkMode ? this["cScalePeer" + t] = this["cScalePeer" + t] || $(this["cScale" + t], 10) : this["cScalePeer" + t] = this["cScalePeer" + t] || A(this["cScale" + t], 10);
    this.scaleLabelColor = this.scaleLabelColor || this.labelTextColor;
    for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
      this["cScaleLabel" + t] = this["cScaleLabel" + t] || this.scaleLabelColor;
    const e = this.darkMode ? -4 : -1;
    for (let t = 0; t < 5; t++)
      this["surface" + t] = this["surface" + t] || C(this.mainBkg, { h: 180, s: -15, l: e * (5 + t * 3) }), this["surfacePeer" + t] = this["surfacePeer" + t] || C(this.mainBkg, { h: 180, s: -15, l: e * (8 + t * 3) });
    this.classText = this.classText || this.textColor, this.fillType0 = this.fillType0 || this.primaryColor, this.fillType1 = this.fillType1 || this.secondaryColor, this.fillType2 = this.fillType2 || C(this.primaryColor, { h: 64 }), this.fillType3 = this.fillType3 || C(this.secondaryColor, { h: 64 }), this.fillType4 = this.fillType4 || C(this.primaryColor, { h: -64 }), this.fillType5 = this.fillType5 || C(this.secondaryColor, { h: -64 }), this.fillType6 = this.fillType6 || C(this.primaryColor, { h: 128 }), this.fillType7 = this.fillType7 || C(this.secondaryColor, { h: 128 }), this.pie1 = this.pie1 || this.primaryColor, this.pie2 = this.pie2 || this.secondaryColor, this.pie3 = this.pie3 || this.tertiaryColor, this.pie4 = this.pie4 || C(this.primaryColor, { l: -10 }), this.pie5 = this.pie5 || C(this.secondaryColor, { l: -10 }), this.pie6 = this.pie6 || C(this.tertiaryColor, { l: -10 }), this.pie7 = this.pie7 || C(this.primaryColor, { h: 60, l: -10 }), this.pie8 = this.pie8 || C(this.primaryColor, { h: -60, l: -10 }), this.pie9 = this.pie9 || C(this.primaryColor, { h: 120, l: 0 }), this.pie10 = this.pie10 || C(this.primaryColor, { h: 60, l: -20 }), this.pie11 = this.pie11 || C(this.primaryColor, { h: -60, l: -20 }), this.pie12 = this.pie12 || C(this.primaryColor, { h: 120, l: -10 }), this.pieTitleTextSize = this.pieTitleTextSize || "25px", this.pieTitleTextColor = this.pieTitleTextColor || this.taskTextDarkColor, this.pieSectionTextSize = this.pieSectionTextSize || "17px", this.pieSectionTextColor = this.pieSectionTextColor || this.textColor, this.pieLegendTextSize = this.pieLegendTextSize || "17px", this.pieLegendTextColor = this.pieLegendTextColor || this.taskTextDarkColor, this.pieStrokeColor = this.pieStrokeColor || "black", this.pieStrokeWidth = this.pieStrokeWidth || "2px", this.pieOuterStrokeWidth = this.pieOuterStrokeWidth || "2px", this.pieOuterStrokeColor = this.pieOuterStrokeColor || "black", this.pieOpacity = this.pieOpacity || "0.7", this.vennTitleTextColor = this.vennTitleTextColor ?? this.titleColor, this.vennSetTextColor = this.vennSetTextColor ?? this.textColor, this.quadrant1Fill = this.quadrant1Fill || this.primaryColor, this.quadrant2Fill = this.quadrant2Fill || C(this.primaryColor, { r: 5, g: 5, b: 5 }), this.quadrant3Fill = this.quadrant3Fill || C(this.primaryColor, { r: 10, g: 10, b: 10 }), this.quadrant4Fill = this.quadrant4Fill || C(this.primaryColor, { r: 15, g: 15, b: 15 }), this.quadrant1TextFill = this.quadrant1TextFill || this.primaryTextColor, this.quadrant2TextFill = this.quadrant2TextFill || C(this.primaryTextColor, { r: -5, g: -5, b: -5 }), this.quadrant3TextFill = this.quadrant3TextFill || C(this.primaryTextColor, { r: -10, g: -10, b: -10 }), this.quadrant4TextFill = this.quadrant4TextFill || C(this.primaryTextColor, { r: -15, g: -15, b: -15 }), this.quadrantPointFill = this.quadrantPointFill || be(this.quadrant1Fill) ? $(this.quadrant1Fill) : A(this.quadrant1Fill), this.quadrantPointTextFill = this.quadrantPointTextFill || this.primaryTextColor, this.quadrantXAxisTextFill = this.quadrantXAxisTextFill || this.primaryTextColor, this.quadrantYAxisTextFill = this.quadrantYAxisTextFill || this.primaryTextColor, this.quadrantInternalBorderStrokeFill = this.quadrantInternalBorderStrokeFill || this.primaryBorderColor, this.quadrantExternalBorderStrokeFill = this.quadrantExternalBorderStrokeFill || this.primaryBorderColor, this.quadrantTitleFill = this.quadrantTitleFill || this.primaryTextColor, this.xyChart = {
      backgroundColor: this.xyChart?.backgroundColor || this.background,
      titleColor: this.xyChart?.titleColor || this.primaryTextColor,
      xAxisTitleColor: this.xyChart?.xAxisTitleColor || this.primaryTextColor,
      xAxisLabelColor: this.xyChart?.xAxisLabelColor || this.primaryTextColor,
      xAxisTickColor: this.xyChart?.xAxisTickColor || this.primaryTextColor,
      xAxisLineColor: this.xyChart?.xAxisLineColor || this.primaryTextColor,
      yAxisTitleColor: this.xyChart?.yAxisTitleColor || this.primaryTextColor,
      yAxisLabelColor: this.xyChart?.yAxisLabelColor || this.primaryTextColor,
      yAxisTickColor: this.xyChart?.yAxisTickColor || this.primaryTextColor,
      yAxisLineColor: this.xyChart?.yAxisLineColor || this.primaryTextColor,
      plotColorPalette: this.xyChart?.plotColorPalette || "#FFF4DD,#FFD8B1,#FFA07A,#ECEFF1,#D6DBDF,#C3E0A8,#FFB6A4,#FFD74D,#738FA7,#FFFFF0"
    }, this.requirementBackground = this.requirementBackground || this.primaryColor, this.requirementBorderColor = this.requirementBorderColor || this.primaryBorderColor, this.requirementBorderSize = this.requirementBorderSize || "1", this.requirementTextColor = this.requirementTextColor || this.primaryTextColor, this.relationColor = this.relationColor || this.lineColor, this.relationLabelBackground = this.relationLabelBackground || (this.darkMode ? A(this.secondaryColor, 30) : this.secondaryColor), this.relationLabelColor = this.relationLabelColor || this.actorTextColor, this.git0 = this.git0 || "#0b0000", this.git1 = this.git1 || "#4d1037", this.git2 = this.git2 || "#3f5258", this.git3 = this.git3 || "#4f2f1b", this.git4 = this.git4 || "#6e0a0a", this.git5 = this.git5 || "#3b0048", this.git6 = this.git6 || "#995a01", this.git7 = this.git7 || "#154706", this.gitDarkMode = !0, this.gitDarkMode ? (this.git0 = $(this.git0, 25), this.git1 = $(this.git1, 25), this.git2 = $(this.git2, 25), this.git3 = $(this.git3, 25), this.git4 = $(this.git4, 25), this.git5 = $(this.git5, 25), this.git6 = $(this.git6, 25), this.git7 = $(this.git7, 25)) : (this.git0 = A(this.git0, 25), this.git1 = A(this.git1, 25), this.git2 = A(this.git2, 25), this.git3 = A(this.git3, 25), this.git4 = A(this.git4, 25), this.git5 = A(this.git5, 25), this.git6 = A(this.git6, 25), this.git7 = A(this.git7, 25)), this.gitInv0 = this.gitInv0 || _(this.git0), this.gitInv1 = this.gitInv1 || _(this.git1), this.gitInv2 = this.gitInv2 || _(this.git2), this.gitInv3 = this.gitInv3 || _(this.git3), this.gitInv4 = this.gitInv4 || _(this.git4), this.gitInv5 = this.gitInv5 || _(this.git5), this.gitInv6 = this.gitInv6 || _(this.git6), this.gitInv7 = this.gitInv7 || _(this.git7), this.branchLabelColor = this.branchLabelColor || (this.darkMode ? "black" : this.labelTextColor), this.gitBranchLabel0 = this.gitBranchLabel0 || this.branchLabelColor, this.gitBranchLabel1 = this.gitBranchLabel1 || this.branchLabelColor, this.gitBranchLabel2 = this.gitBranchLabel2 || this.branchLabelColor, this.gitBranchLabel3 = this.gitBranchLabel3 || this.branchLabelColor, this.gitBranchLabel4 = this.gitBranchLabel4 || this.branchLabelColor, this.gitBranchLabel5 = this.gitBranchLabel5 || this.branchLabelColor, this.gitBranchLabel6 = this.gitBranchLabel6 || this.branchLabelColor, this.gitBranchLabel7 = this.gitBranchLabel7 || this.branchLabelColor, this.tagLabelColor = this.tagLabelColor || this.primaryTextColor, this.tagLabelBackground = this.tagLabelBackground || this.primaryColor, this.tagLabelBorder = this.tagBorder || this.primaryBorderColor, this.tagLabelFontSize = this.tagLabelFontSize || "10px", this.commitLabelColor = this.commitLabelColor || this.secondaryTextColor, this.commitLabelBackground = this.commitLabelBackground || this.secondaryColor, this.commitLabelFontSize = this.commitLabelFontSize || "10px", this.attributeBackgroundColorOdd = this.attributeBackgroundColorOdd || Ae, this.attributeBackgroundColorEven = this.attributeBackgroundColorEven || Me;
  }
  calculate(e) {
    if (typeof e != "object") {
      this.updateColors();
      return;
    }
    const t = Object.keys(e);
    t.forEach((r) => {
      this[r] = e[r];
    }), this.updateColors(), t.forEach((r) => {
      this[r] = e[r];
    });
  }
}, b0 = /* @__PURE__ */ f((e) => {
  const t = new x0();
  return t.calculate(e), t;
}, "getThemeVariables"), k0 = class {
  static {
    f(this, "Theme");
  }
  constructor() {
    this.background = "#ffffff", this.primaryColor = "#cccccc", this.mainBkg = "#ffffff", this.noteBkgColor = "#fff5ad", this.noteTextColor = "#28253D", this.THEME_COLOR_LIMIT = 12, this.radius = 12, this.strokeWidth = 2, this.primaryBorderColor = at("#28253D", this.darkMode), this.fontFamily = '"Recursive Variable", arial, sans-serif', this.fontSize = "14px", this.nodeBorder = "#28253D", this.stateBorder = "#28253D", this.useGradient = !1, this.gradientStart = "#0042eb", this.gradientStop = "#eb0042", this.dropShadow = "url(#drop-shadow)", this.nodeShadow = !0, this.tertiaryColor = "#ffffff", this.clusterBkg = "#F9F9FB", this.clusterBorder = "#BDBCCC", this.noteBorderColor = "#FACC15", this.archEdgeColor = "calculated", this.archEdgeArrowColor = "calculated", this.archEdgeWidth = "3", this.archGroupBorderColor = this.primaryBorderColor, this.archGroupBorderWidth = "2px", this.actorBorder = "#28253D", this.filterColor = "#000000";
  }
  updateColors() {
    this.primaryTextColor = this.primaryTextColor || (this.darkMode ? "#eee" : "#28253D"), this.secondaryColor = this.secondaryColor || C(this.primaryColor, { h: -120 }), this.tertiaryColor = this.tertiaryColor || C(this.primaryColor, { h: 180, l: 5 }), this.primaryBorderColor = this.primaryBorderColor || at(this.primaryColor, this.darkMode), this.secondaryBorderColor = this.secondaryBorderColor || at(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = this.tertiaryBorderColor || at(this.tertiaryColor, this.darkMode), this.noteBorderColor = this.noteBorderColor || at(this.noteBkgColor, this.darkMode), this.noteBkgColor = this.noteBkgColor || "#FEF9C3", this.noteTextColor = this.noteTextColor || "#28253D", this.secondaryTextColor = this.secondaryTextColor || _(this.secondaryColor), this.tertiaryTextColor = this.tertiaryTextColor || _(this.tertiaryColor), this.lineColor = this.lineColor || _(this.background), this.arrowheadColor = this.arrowheadColor || _(this.background), this.textColor = this.textColor || this.primaryTextColor, this.border2 = this.border2 || this.tertiaryBorderColor, this.nodeBkg = this.nodeBkg || this.primaryColor, this.mainBkg = this.mainBkg || this.primaryColor, this.nodeBorder = this.nodeBorder || this.primaryBorderColor, this.clusterBkg = this.clusterBkg || this.tertiaryColor, this.clusterBorder = this.clusterBorder || this.tertiaryBorderColor, this.defaultLinkColor = this.defaultLinkColor || this.lineColor, this.titleColor = this.titleColor || this.tertiaryTextColor, this.edgeLabelBackground = this.edgeLabelBackground || (this.darkMode ? A(this.secondaryColor, 30) : this.secondaryColor), this.nodeTextColor = this.nodeTextColor || this.primaryTextColor, this.noteFontWeight = 600, this.actorBorder = this.actorBorder || this.primaryBorderColor, this.actorBkg = this.actorBkg || this.mainBkg, this.actorTextColor = this.actorTextColor || this.primaryTextColor, this.actorLineColor = this.actorLineColor || this.actorBorder, this.labelBoxBkgColor = this.labelBoxBkgColor || this.actorBkg, this.signalColor = this.signalColor || this.textColor, this.signalTextColor = this.signalTextColor || this.textColor, this.labelBoxBorderColor = this.labelBoxBorderColor || this.actorBorder, this.labelTextColor = this.labelTextColor || this.actorTextColor, this.loopTextColor = this.loopTextColor || this.actorTextColor, this.activationBorderColor = this.activationBorderColor || A(this.secondaryColor, 10), this.activationBkgColor = this.activationBkgColor || this.secondaryColor, this.sequenceNumberColor = this.sequenceNumberColor || _(this.lineColor);
    const e = "#ECECFE", t = "#E9E9F1", r = C(e, { h: 180, l: 5 });
    this.sectionBkgColor = this.sectionBkgColor || r, this.altSectionBkgColor = this.altSectionBkgColor || "white", this.sectionBkgColor = this.sectionBkgColor || t, this.sectionBkgColor2 = this.sectionBkgColor2 || e, this.excludeBkgColor = this.excludeBkgColor || "#eeeeee", this.taskBorderColor = this.taskBorderColor || this.primaryBorderColor, this.taskBkgColor = this.taskBkgColor || e, this.activeTaskBorderColor = this.activeTaskBorderColor || e, this.activeTaskBkgColor = this.activeTaskBkgColor || $(e, 23), this.gridColor = this.gridColor || "lightgrey", this.doneTaskBkgColor = this.doneTaskBkgColor || "lightgrey", this.doneTaskBorderColor = this.doneTaskBorderColor || "grey", this.critBorderColor = this.critBorderColor || "#ff8888", this.critBkgColor = this.critBkgColor || "red", this.todayLineColor = this.todayLineColor || "red", this.taskTextColor = this.taskTextColor || this.textColor, this.vertLineColor = this.vertLineColor || this.primaryBorderColor, this.taskTextOutsideColor = this.taskTextOutsideColor || this.textColor, this.taskTextLightColor = this.taskTextLightColor || this.textColor, this.taskTextColor = this.taskTextColor || this.primaryTextColor, this.taskTextDarkColor = this.taskTextDarkColor || this.textColor, this.taskTextClickableColor = this.taskTextClickableColor || "#003163", this.archEdgeColor = this.lineColor, this.archEdgeArrowColor = this.lineColor, this.personBorder = this.personBorder || this.primaryBorderColor, this.personBkg = this.personBkg || this.mainBkg, this.transitionColor = this.transitionColor || this.lineColor, this.transitionLabelColor = this.transitionLabelColor || this.textColor, this.stateLabelColor = this.stateLabelColor || this.stateBkg || this.primaryTextColor, this.compositeTitleBackground = "#F9F9FB", this.altBackground = "#F9F9FB", this.stateEdgeLabelBackground = "#FFFFFF", this.fontWeight = 600, this.stateBkg = this.stateBkg || this.mainBkg, this.labelBackgroundColor = this.labelBackgroundColor || this.stateBkg, this.compositeBackground = this.compositeBackground || this.background || this.tertiaryColor, this.altBackground = this.altBackground || "#f0f0f0", this.compositeTitleBackground = this.compositeTitleBackground || this.mainBkg, this.compositeBorder = this.compositeBorder || this.nodeBorder, this.innerEndBackground = this.nodeBorder, this.errorBkgColor = this.errorBkgColor || this.tertiaryColor, this.errorTextColor = this.errorTextColor || this.tertiaryTextColor, this.transitionColor = this.transitionColor || this.lineColor, this.specialStateColor = this.lineColor;
    for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
      this["cScale" + s] = this.mainBkg;
    if (this.darkMode)
      for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
        this["cScale" + s] = A(this["cScale" + s], 75);
    else
      for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
        this["cScale" + s] = A(this["cScale" + s], 25);
    for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
      this["cScaleInv" + s] = this["cScaleInv" + s] || _(this["cScale" + s]);
    for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
      this.darkMode ? this["cScalePeer" + s] = this["cScalePeer" + s] || $(this["cScale" + s], 10) : this["cScalePeer" + s] = this["cScalePeer" + s] || A(this["cScale" + s], 10);
    this.scaleLabelColor = this.scaleLabelColor || this.labelTextColor;
    for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
      this["cScaleLabel" + s] = this["cScaleLabel" + s] || this.scaleLabelColor;
    const i = this.darkMode ? -4 : -1;
    for (let s = 0; s < 5; s++)
      this["surface" + s] = this["surface" + s] || C(this.mainBkg, { h: 180, s: -15, l: i * (5 + s * 3) }), this["surfacePeer" + s] = this["surfacePeer" + s] || C(this.mainBkg, { h: 180, s: -15, l: i * (8 + s * 3) });
    this.classText = this.classText || this.textColor, this.fillType0 = this.fillType0 || e, this.fillType1 = this.fillType1 || t, this.fillType2 = this.fillType2 || C(e, { h: 64 }), this.fillType3 = this.fillType3 || C(t, { h: 64 }), this.fillType4 = this.fillType4 || C(e, { h: -64 }), this.fillType5 = this.fillType5 || C(t, { h: -64 }), this.fillType6 = this.fillType6 || C(e, { h: 128 }), this.fillType7 = this.fillType7 || C(t, { h: 128 }), this.pie1 = this.pie1 || e, this.pie2 = this.pie2 || t, this.pie3 = this.pie3 || r, this.pie4 = this.pie4 || C(e, { l: -10 }), this.pie5 = this.pie5 || C(t, { l: -10 }), this.pie6 = this.pie6 || C(r, { l: -10 }), this.pie7 = this.pie7 || C(e, { h: 60, l: -10 }), this.pie8 = this.pie8 || C(e, { h: -60, l: -10 }), this.pie9 = this.pie9 || C(e, { h: 120, l: 0 }), this.pie10 = this.pie10 || C(e, { h: 60, l: -20 }), this.pie11 = this.pie11 || C(e, { h: -60, l: -20 }), this.pie12 = this.pie12 || C(e, { h: 120, l: -10 }), this.pieTitleTextSize = this.pieTitleTextSize || "25px", this.pieTitleTextColor = this.pieTitleTextColor || this.taskTextDarkColor, this.pieSectionTextSize = this.pieSectionTextSize || "17px", this.pieSectionTextColor = this.pieSectionTextColor || this.textColor, this.pieLegendTextSize = this.pieLegendTextSize || "17px", this.pieLegendTextColor = this.pieLegendTextColor || this.taskTextDarkColor, this.pieStrokeColor = this.pieStrokeColor || "black", this.pieStrokeWidth = this.pieStrokeWidth || "2px", this.pieOuterStrokeWidth = this.pieOuterStrokeWidth || "2px", this.pieOuterStrokeColor = this.pieOuterStrokeColor || "black", this.pieOpacity = this.pieOpacity || "0.7", this.vennTitleTextColor = this.vennTitleTextColor ?? this.titleColor, this.vennSetTextColor = this.vennSetTextColor ?? this.textColor, this.quadrant1Fill = this.quadrant1Fill || e, this.quadrant2Fill = this.quadrant2Fill || C(e, { r: 5, g: 5, b: 5 }), this.quadrant3Fill = this.quadrant3Fill || C(e, { r: 10, g: 10, b: 10 }), this.quadrant4Fill = this.quadrant4Fill || C(e, { r: 15, g: 15, b: 15 }), this.quadrant1TextFill = this.quadrant1TextFill || this.primaryTextColor, this.quadrant2TextFill = this.quadrant2TextFill || C(this.primaryTextColor, { r: -5, g: -5, b: -5 }), this.quadrant3TextFill = this.quadrant3TextFill || C(this.primaryTextColor, { r: -10, g: -10, b: -10 }), this.quadrant4TextFill = this.quadrant4TextFill || C(this.primaryTextColor, { r: -15, g: -15, b: -15 }), this.quadrantPointFill = this.quadrantPointFill || be(this.quadrant1Fill) ? $(this.quadrant1Fill) : A(this.quadrant1Fill), this.quadrantPointTextFill = this.quadrantPointTextFill || this.primaryTextColor, this.quadrantXAxisTextFill = this.quadrantXAxisTextFill || this.primaryTextColor, this.quadrantYAxisTextFill = this.quadrantYAxisTextFill || this.primaryTextColor, this.quadrantInternalBorderStrokeFill = this.quadrantInternalBorderStrokeFill || this.primaryBorderColor, this.quadrantExternalBorderStrokeFill = this.quadrantExternalBorderStrokeFill || this.primaryBorderColor, this.quadrantTitleFill = this.quadrantTitleFill || this.primaryTextColor, this.xyChart = {
      backgroundColor: this.xyChart?.backgroundColor || this.background,
      titleColor: this.xyChart?.titleColor || this.primaryTextColor,
      xAxisTitleColor: this.xyChart?.xAxisTitleColor || this.primaryTextColor,
      xAxisLabelColor: this.xyChart?.xAxisLabelColor || this.primaryTextColor,
      xAxisTickColor: this.xyChart?.xAxisTickColor || this.primaryTextColor,
      xAxisLineColor: this.xyChart?.xAxisLineColor || this.primaryTextColor,
      yAxisTitleColor: this.xyChart?.yAxisTitleColor || this.primaryTextColor,
      yAxisLabelColor: this.xyChart?.yAxisLabelColor || this.primaryTextColor,
      yAxisTickColor: this.xyChart?.yAxisTickColor || this.primaryTextColor,
      yAxisLineColor: this.xyChart?.yAxisLineColor || this.primaryTextColor,
      plotColorPalette: this.xyChart?.plotColorPalette || "#FFF4DD,#FFD8B1,#FFA07A,#ECEFF1,#D6DBDF,#C3E0A8,#FFB6A4,#FFD74D,#738FA7,#FFFFF0"
    }, this.requirementBackground = this.requirementBackground || e, this.requirementBorderColor = this.requirementBorderColor || this.primaryBorderColor, this.requirementBorderSize = this.requirementBorderSize || "1", this.requirementTextColor = this.requirementTextColor || this.primaryTextColor, this.relationColor = this.relationColor || this.lineColor, this.relationLabelBackground = this.relationLabelBackground || (this.darkMode ? A(this.secondaryColor, 30) : this.secondaryColor), this.relationLabelColor = this.relationLabelColor || this.actorTextColor, this.requirementEdgeLabelBackground = "#FFFFFF", this.git0 = this.git0 || e, this.git1 = this.git1 || t, this.git2 = this.git2 || r, this.git3 = this.git3 || C(e, { h: -30 }), this.git4 = this.git4 || C(e, { h: -60 }), this.git5 = this.git5 || C(e, { h: -90 }), this.git6 = this.git6 || C(e, { h: 60 }), this.git7 = this.git7 || C(e, { h: 120 }), this.darkMode ? (this.git0 = $(this.git0, 25), this.git1 = $(this.git1, 25), this.git2 = $(this.git2, 25), this.git3 = $(this.git3, 25), this.git4 = $(this.git4, 25), this.git5 = $(this.git5, 25), this.git6 = $(this.git6, 25), this.git7 = $(this.git7, 25)) : (this.git0 = A(this.git0, 25), this.git1 = A(this.git1, 25), this.git2 = A(this.git2, 25), this.git3 = A(this.git3, 25), this.git4 = A(this.git4, 25), this.git5 = A(this.git5, 25), this.git6 = A(this.git6, 25), this.git7 = A(this.git7, 25)), this.gitInv0 = this.gitInv0 || _(this.git0), this.gitInv1 = this.gitInv1 || _(this.git1), this.gitInv2 = this.gitInv2 || _(this.git2), this.gitInv3 = this.gitInv3 || _(this.git3), this.gitInv4 = this.gitInv4 || _(this.git4), this.gitInv5 = this.gitInv5 || _(this.git5), this.gitInv6 = this.gitInv6 || _(this.git6), this.gitInv7 = this.gitInv7 || _(this.git7), this.branchLabelColor = this.branchLabelColor || (this.darkMode ? "black" : this.labelTextColor), this.gitBranchLabel0 = this.gitBranchLabel0 || this.branchLabelColor, this.gitBranchLabel1 = this.gitBranchLabel1 || this.branchLabelColor, this.gitBranchLabel2 = this.gitBranchLabel2 || this.branchLabelColor, this.gitBranchLabel3 = this.gitBranchLabel3 || this.branchLabelColor, this.gitBranchLabel4 = this.gitBranchLabel4 || this.branchLabelColor, this.gitBranchLabel5 = this.gitBranchLabel5 || this.branchLabelColor, this.gitBranchLabel6 = this.gitBranchLabel6 || this.branchLabelColor, this.gitBranchLabel7 = this.gitBranchLabel7 || this.branchLabelColor, this.tagLabelColor = this.tagLabelColor || this.primaryTextColor, this.tagLabelBackground = this.tagLabelBackground || this.primaryColor, this.tagLabelBorder = this.tagBorder || this.primaryBorderColor, this.tagLabelFontSize = this.tagLabelFontSize || "10px", this.commitLabelColor = this.commitLabelColor || this.secondaryTextColor, this.commitLabelBackground = this.commitLabelBackground || this.secondaryColor, this.commitLabelFontSize = this.commitLabelFontSize || "10px", this.commitLineColor = this.commitLineColor ?? "#BDBCCC", this.erEdgeLabelBackground = "#FFFFFF", this.attributeBackgroundColorOdd = this.attributeBackgroundColorOdd || Ae, this.attributeBackgroundColorEven = this.attributeBackgroundColorEven || Me;
  }
  calculate(e) {
    if (typeof e != "object") {
      this.updateColors();
      return;
    }
    const t = Object.keys(e);
    t.forEach((r) => {
      this[r] = e[r];
    }), this.updateColors(), t.forEach((r) => {
      this[r] = e[r];
    });
  }
}, T0 = /* @__PURE__ */ f((e) => {
  const t = new k0();
  return t.calculate(e), t;
}, "getThemeVariables"), w0 = class {
  static {
    f(this, "Theme");
  }
  constructor() {
    this.background = "#333", this.primaryColor = "#1f2020", this.secondaryColor = $(this.primaryColor, 16), this.tertiaryColor = C(this.primaryColor, { h: -160 }), this.primaryBorderColor = _(this.background), this.secondaryBorderColor = at(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = at(this.tertiaryColor, this.darkMode), this.primaryTextColor = _(this.primaryColor), this.secondaryTextColor = _(this.secondaryColor), this.tertiaryTextColor = _(this.tertiaryColor), this.mainBkg = "#111113", this.secondBkg = "calculated", this.mainContrastColor = "lightgrey", this.darkTextColor = $(_("#323D47"), 10), this.border1 = "#ccc", this.border2 = Je(255, 255, 255, 0.25), this.arrowheadColor = _(this.background), this.fontFamily = '"Recursive Variable", arial, sans-serif', this.fontSize = "14px", this.labelBackground = "#111113", this.textColor = "#ccc", this.THEME_COLOR_LIMIT = 12, this.radius = 12, this.strokeWidth = 2, this.noteBkgColor = this.noteBkgColor ?? "#FEF9C3", this.noteTextColor = this.noteTextColor ?? "#28253D", this.THEME_COLOR_LIMIT = 12, this.fontFamily = '"Recursive Variable", arial, sans-serif', this.fontSize = "14px", this.nodeBorder = "#FFFFFF", this.stateBorder = "#FFFFFF", this.useGradient = !1, this.gradientStart = "#0042eb", this.gradientStop = "#eb0042", this.dropShadow = "url(#drop-shadow)", this.nodeShadow = !0, this.archEdgeColor = "calculated", this.archEdgeArrowColor = "calculated", this.archEdgeWidth = "3", this.archGroupBorderColor = this.primaryBorderColor, this.archGroupBorderWidth = "2px", this.clusterBkg = "#1E1A2E", this.clusterBorder = "#BDBCCC", this.noteBorderColor = "#FACC15", this.noteFontWeight = 600, this.filterColor = "#FFFFFF";
  }
  updateColors() {
    if (this.primaryTextColor = this.primaryTextColor || (this.darkMode ? "#eee" : "#FFFFFF"), this.secondaryColor = this.secondaryColor || C(this.primaryColor, { h: -120 }), this.tertiaryColor = this.tertiaryColor || C(this.primaryColor, { h: 180, l: 5 }), this.primaryBorderColor = this.primaryBorderColor || at(this.primaryColor, this.darkMode), this.secondaryBorderColor = this.secondaryBorderColor || at(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = this.tertiaryBorderColor || at(this.tertiaryColor, this.darkMode), this.noteBorderColor = this.noteBorderColor || at(this.noteBkgColor, this.darkMode), this.noteBkgColor = this.noteBkgColor || "#fff5ad", this.noteTextColor = this.noteTextColor || "#FFFFFF", this.secondaryTextColor = this.secondaryTextColor || _(this.secondaryColor), this.tertiaryTextColor = this.tertiaryTextColor || _(this.tertiaryColor), this.lineColor = this.lineColor || _(this.background), this.arrowheadColor = this.arrowheadColor || _(this.background), this.textColor = this.textColor || this.primaryTextColor, this.border2 = this.border2 || this.tertiaryBorderColor, this.nodeBkg = this.nodeBkg || this.primaryColor, this.mainBkg = this.mainBkg || this.primaryColor, this.nodeBorder = this.nodeBorder || this.border1, this.clusterBkg = this.clusterBkg || this.tertiaryColor, this.clusterBorder = this.clusterBorder || this.tertiaryBorderColor, this.defaultLinkColor = this.defaultLinkColor || this.lineColor, this.titleColor = this.titleColor || this.tertiaryTextColor, this.edgeLabelBackground = this.edgeLabelBackground || (this.darkMode ? A(this.secondaryColor, 30) : this.secondaryColor), this.nodeTextColor = this.nodeTextColor || this.primaryTextColor, this.actorBorder = "#FFFFFF", this.signalColor = "#FFFFFF", this.labelBoxBorderColor = "#BDBCCC", this.actorBorder = this.actorBorder || this.primaryBorderColor, this.actorBkg = this.actorBkg || this.mainBkg, this.actorTextColor = this.actorTextColor || this.primaryTextColor, this.actorLineColor = this.actorLineColor || this.actorBorder, this.labelBoxBkgColor = this.labelBoxBkgColor || this.actorBkg, this.signalColor = this.signalColor || this.textColor, this.signalTextColor = this.signalTextColor || this.textColor, this.labelBoxBorderColor = this.labelBoxBorderColor || this.actorBorder, this.labelTextColor = this.labelTextColor || this.actorTextColor, this.loopTextColor = this.loopTextColor || this.actorTextColor, this.activationBorderColor = this.activationBorderColor || A(this.secondaryColor, 10), this.activationBkgColor = this.activationBkgColor || this.secondaryColor, this.sequenceNumberColor = this.sequenceNumberColor || _(this.lineColor), this.sectionBkgColor = this.sectionBkgColor || this.tertiaryColor, this.altSectionBkgColor = this.altSectionBkgColor || "white", this.sectionBkgColor = this.sectionBkgColor || this.secondaryColor, this.sectionBkgColor2 = this.sectionBkgColor2 || this.primaryColor, this.excludeBkgColor = this.excludeBkgColor || "#eeeeee", this.taskBorderColor = this.taskBorderColor || this.primaryBorderColor, this.taskBkgColor = this.taskBkgColor || this.primaryColor, this.activeTaskBorderColor = this.activeTaskBorderColor || this.primaryColor, this.activeTaskBkgColor = this.activeTaskBkgColor || $(this.primaryColor, 23), this.gridColor = this.gridColor || "lightgrey", this.doneTaskBkgColor = this.doneTaskBkgColor || "lightgrey", this.doneTaskBorderColor = this.doneTaskBorderColor || "grey", this.critBorderColor = this.critBorderColor || "#ff8888", this.critBkgColor = this.critBkgColor || "red", this.todayLineColor = this.todayLineColor || "red", this.taskTextColor = this.taskTextColor || this.textColor, this.taskTextOutsideColor = this.taskTextOutsideColor || this.textColor, this.taskTextLightColor = this.taskTextLightColor || this.textColor, this.taskTextColor = this.taskTextColor || this.primaryTextColor, this.taskTextDarkColor = this.taskTextDarkColor || this.textColor, this.taskTextClickableColor = this.taskTextClickableColor || "#003163", this.archEdgeColor = this.lineColor, this.archEdgeArrowColor = this.lineColor, this.personBorder = this.personBorder || this.primaryBorderColor, this.personBkg = this.personBkg || this.mainBkg, this.transitionColor = this.transitionColor || this.lineColor, this.transitionLabelColor = this.transitionLabelColor || this.textColor, this.stateLabelColor = this.stateLabelColor || this.stateBkg || this.primaryTextColor, this.vertLineColor = this.vertLineColor || this.primaryBorderColor, this.compositeBackground = "#16141F", this.altBackground = "#16141F", this.compositeTitleBackground = "#16141F", this.stateEdgeLabelBackground = "#16141F", this.fontWeight = 600, this.stateBkg = this.stateBkg || this.mainBkg, this.labelBackgroundColor = this.labelBackgroundColor || this.stateBkg, this.compositeBackground = this.compositeBackground || this.background || this.tertiaryColor, this.altBackground = this.altBackground || "#f0f0f0", this.compositeTitleBackground = this.compositeTitleBackground || this.mainBkg, this.compositeBorder = this.compositeBorder || this.nodeBorder, this.innerEndBackground = this.nodeBorder, this.errorBkgColor = this.errorBkgColor || this.tertiaryColor, this.errorTextColor = this.errorTextColor || this.tertiaryTextColor, this.transitionColor = this.transitionColor || this.lineColor, this.specialStateColor = this.lineColor, this.cScale0 = this.cScale0 || this.primaryColor, this.cScale1 = this.cScale1 || this.secondaryColor, this.cScale2 = this.cScale2 || this.tertiaryColor, this.cScale3 = this.cScale3 || C(this.primaryColor, { h: 30 }), this.cScale4 = this.cScale4 || C(this.primaryColor, { h: 60 }), this.cScale5 = this.cScale5 || C(this.primaryColor, { h: 90 }), this.cScale6 = this.cScale6 || C(this.primaryColor, { h: 120 }), this.cScale7 = this.cScale7 || C(this.primaryColor, { h: 150 }), this.cScale8 = this.cScale8 || C(this.primaryColor, { h: 210, l: 150 }), this.cScale9 = this.cScale9 || C(this.primaryColor, { h: 270 }), this.cScale10 = this.cScale10 || C(this.primaryColor, { h: 300 }), this.cScale11 = this.cScale11 || C(this.primaryColor, { h: 330 }), this.darkMode)
      for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
        this["cScale" + t] = A(this["cScale" + t], 75);
    else
      for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
        this["cScale" + t] = A(this["cScale" + t], 25);
    for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
      this["cScaleInv" + t] = this["cScaleInv" + t] || _(this["cScale" + t]);
    for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
      this.darkMode ? this["cScalePeer" + t] = this["cScalePeer" + t] || $(this["cScale" + t], 10) : this["cScalePeer" + t] = this["cScalePeer" + t] || A(this["cScale" + t], 10);
    this.scaleLabelColor = this.scaleLabelColor || this.labelTextColor;
    for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
      this["cScaleLabel" + t] = this["cScaleLabel" + t] || this.scaleLabelColor;
    const e = this.darkMode ? -4 : -1;
    for (let t = 0; t < 5; t++)
      this["surface" + t] = this["surface" + t] || C(this.mainBkg, { h: 180, s: -15, l: e * (5 + t * 3) }), this["surfacePeer" + t] = this["surfacePeer" + t] || C(this.mainBkg, { h: 180, s: -15, l: e * (8 + t * 3) });
    this.classText = this.classText || this.textColor, this.fillType0 = this.fillType0 || this.primaryColor, this.fillType1 = this.fillType1 || this.secondaryColor, this.fillType2 = this.fillType2 || C(this.primaryColor, { h: 64 }), this.fillType3 = this.fillType3 || C(this.secondaryColor, { h: 64 }), this.fillType4 = this.fillType4 || C(this.primaryColor, { h: -64 }), this.fillType5 = this.fillType5 || C(this.secondaryColor, { h: -64 }), this.fillType6 = this.fillType6 || C(this.primaryColor, { h: 128 }), this.fillType7 = this.fillType7 || C(this.secondaryColor, { h: 128 }), this.pie1 = this.pie1 || this.primaryColor, this.pie2 = this.pie2 || this.secondaryColor, this.pie3 = this.pie3 || this.tertiaryColor, this.pie4 = this.pie4 || C(this.primaryColor, { l: -10 }), this.pie5 = this.pie5 || C(this.secondaryColor, { l: -10 }), this.pie6 = this.pie6 || C(this.tertiaryColor, { l: -10 }), this.pie7 = this.pie7 || C(this.primaryColor, { h: 60, l: -10 }), this.pie8 = this.pie8 || C(this.primaryColor, { h: -60, l: -10 }), this.pie9 = this.pie9 || C(this.primaryColor, { h: 120, l: 0 }), this.pie10 = this.pie10 || C(this.primaryColor, { h: 60, l: -20 }), this.pie11 = this.pie11 || C(this.primaryColor, { h: -60, l: -20 }), this.pie12 = this.pie12 || C(this.primaryColor, { h: 120, l: -10 }), this.pieTitleTextSize = this.pieTitleTextSize || "25px", this.pieTitleTextColor = this.pieTitleTextColor || this.taskTextDarkColor, this.pieSectionTextSize = this.pieSectionTextSize || "17px", this.pieSectionTextColor = this.pieSectionTextColor || this.textColor, this.pieLegendTextSize = this.pieLegendTextSize || "17px", this.pieLegendTextColor = this.pieLegendTextColor || this.taskTextDarkColor, this.pieStrokeColor = this.pieStrokeColor || "black", this.pieStrokeWidth = this.pieStrokeWidth || "2px", this.pieOuterStrokeWidth = this.pieOuterStrokeWidth || "2px", this.pieOuterStrokeColor = this.pieOuterStrokeColor || "black", this.pieOpacity = this.pieOpacity || "0.7", this.vennTitleTextColor = this.vennTitleTextColor ?? this.titleColor, this.vennSetTextColor = this.vennSetTextColor ?? this.textColor, this.quadrant1Fill = this.quadrant1Fill || this.primaryColor, this.quadrant2Fill = this.quadrant2Fill || C(this.primaryColor, { r: 5, g: 5, b: 5 }), this.quadrant3Fill = this.quadrant3Fill || C(this.primaryColor, { r: 10, g: 10, b: 10 }), this.quadrant4Fill = this.quadrant4Fill || C(this.primaryColor, { r: 15, g: 15, b: 15 }), this.quadrant1TextFill = this.quadrant1TextFill || this.primaryTextColor, this.quadrant2TextFill = this.quadrant2TextFill || C(this.primaryTextColor, { r: -5, g: -5, b: -5 }), this.quadrant3TextFill = this.quadrant3TextFill || C(this.primaryTextColor, { r: -10, g: -10, b: -10 }), this.quadrant4TextFill = this.quadrant4TextFill || C(this.primaryTextColor, { r: -15, g: -15, b: -15 }), this.quadrantPointFill = this.quadrantPointFill || be(this.quadrant1Fill) ? $(this.quadrant1Fill) : A(this.quadrant1Fill), this.quadrantPointTextFill = this.quadrantPointTextFill || this.primaryTextColor, this.quadrantXAxisTextFill = this.quadrantXAxisTextFill || this.primaryTextColor, this.quadrantYAxisTextFill = this.quadrantYAxisTextFill || this.primaryTextColor, this.quadrantInternalBorderStrokeFill = this.quadrantInternalBorderStrokeFill || this.primaryBorderColor, this.quadrantExternalBorderStrokeFill = this.quadrantExternalBorderStrokeFill || this.primaryBorderColor, this.quadrantTitleFill = this.quadrantTitleFill || this.primaryTextColor, this.xyChart = {
      backgroundColor: this.xyChart?.backgroundColor || this.background,
      titleColor: this.xyChart?.titleColor || this.primaryTextColor,
      xAxisTitleColor: this.xyChart?.xAxisTitleColor || this.primaryTextColor,
      xAxisLabelColor: this.xyChart?.xAxisLabelColor || this.primaryTextColor,
      xAxisTickColor: this.xyChart?.xAxisTickColor || this.primaryTextColor,
      xAxisLineColor: this.xyChart?.xAxisLineColor || this.primaryTextColor,
      yAxisTitleColor: this.xyChart?.yAxisTitleColor || this.primaryTextColor,
      yAxisLabelColor: this.xyChart?.yAxisLabelColor || this.primaryTextColor,
      yAxisTickColor: this.xyChart?.yAxisTickColor || this.primaryTextColor,
      yAxisLineColor: this.xyChart?.yAxisLineColor || this.primaryTextColor,
      plotColorPalette: this.xyChart?.plotColorPalette || "#FFF4DD,#FFD8B1,#FFA07A,#ECEFF1,#D6DBDF,#C3E0A8,#FFB6A4,#FFD74D,#738FA7,#FFFFF0"
    }, this.requirementBackground = this.requirementBackground || this.primaryColor, this.requirementBorderColor = this.requirementBorderColor || this.primaryBorderColor, this.requirementBorderSize = this.requirementBorderSize || "1", this.requirementTextColor = this.requirementTextColor || this.primaryTextColor, this.relationColor = this.relationColor || this.lineColor, this.relationLabelBackground = this.relationLabelBackground || (this.darkMode ? A(this.secondaryColor, 30) : this.secondaryColor), this.relationLabelColor = this.relationLabelColor || this.actorTextColor, this.requirementEdgeLabelBackground = "#16141F", this.git0 = this.git0 || this.primaryColor, this.git1 = this.git1 || this.secondaryColor, this.git2 = this.git2 || this.tertiaryColor, this.git3 = this.git3 || C(this.primaryColor, { h: -30 }), this.git4 = this.git4 || C(this.primaryColor, { h: -60 }), this.git5 = this.git5 || C(this.primaryColor, { h: -90 }), this.git6 = this.git6 || C(this.primaryColor, { h: 60 }), this.git7 = this.git7 || C(this.primaryColor, { h: 120 }), this.darkMode ? (this.git0 = $(this.git0, 25), this.git1 = $(this.git1, 25), this.git2 = $(this.git2, 25), this.git3 = $(this.git3, 25), this.git4 = $(this.git4, 25), this.git5 = $(this.git5, 25), this.git6 = $(this.git6, 25), this.git7 = $(this.git7, 25)) : (this.git0 = A(this.git0, 25), this.git1 = A(this.git1, 25), this.git2 = A(this.git2, 25), this.git3 = A(this.git3, 25), this.git4 = A(this.git4, 25), this.git5 = A(this.git5, 25), this.git6 = A(this.git6, 25), this.git7 = A(this.git7, 25)), this.gitInv0 = this.gitInv0 || _(this.git0), this.gitInv1 = this.gitInv1 || _(this.git1), this.gitInv2 = this.gitInv2 || _(this.git2), this.gitInv3 = this.gitInv3 || _(this.git3), this.gitInv4 = this.gitInv4 || _(this.git4), this.gitInv5 = this.gitInv5 || _(this.git5), this.gitInv6 = this.gitInv6 || _(this.git6), this.gitInv7 = this.gitInv7 || _(this.git7), this.branchLabelColor = this.branchLabelColor || (this.darkMode ? "black" : this.labelTextColor), this.gitBranchLabel0 = this.gitBranchLabel0 || this.branchLabelColor, this.gitBranchLabel1 = this.gitBranchLabel1 || this.branchLabelColor, this.gitBranchLabel2 = this.gitBranchLabel2 || this.branchLabelColor, this.gitBranchLabel3 = this.gitBranchLabel3 || this.branchLabelColor, this.gitBranchLabel4 = this.gitBranchLabel4 || this.branchLabelColor, this.gitBranchLabel5 = this.gitBranchLabel5 || this.branchLabelColor, this.gitBranchLabel6 = this.gitBranchLabel6 || this.branchLabelColor, this.gitBranchLabel7 = this.gitBranchLabel7 || this.branchLabelColor, this.tagLabelColor = this.tagLabelColor || this.primaryTextColor, this.tagLabelBackground = this.tagLabelBackground || this.primaryColor, this.tagLabelBorder = this.tagBorder || this.primaryBorderColor, this.tagLabelFontSize = this.tagLabelFontSize || "10px", this.commitLabelColor = this.commitLabelColor || this.secondaryTextColor, this.commitLabelBackground = this.commitLabelBackground || this.secondaryColor, this.commitLabelFontSize = this.commitLabelFontSize || "10px", this.commitLineColor = this.commitLineColor ?? "#BDBCCC", this.erEdgeLabelBackground = "#16141F", this.attributeBackgroundColorOdd = this.attributeBackgroundColorOdd || Ae, this.attributeBackgroundColorEven = this.attributeBackgroundColorEven || Me;
  }
  calculate(e) {
    if (typeof e != "object") {
      this.updateColors();
      return;
    }
    const t = Object.keys(e);
    t.forEach((r) => {
      this[r] = e[r];
    }), this.updateColors(), t.forEach((r) => {
      this[r] = e[r];
    });
  }
}, S0 = /* @__PURE__ */ f((e) => {
  const t = new w0();
  return t.calculate(e), t;
}, "getThemeVariables"), _0 = class {
  static {
    f(this, "Theme");
  }
  constructor() {
    this.background = "#ffffff", this.primaryColor = "#cccccc", this.mainBkg = "#ffffff", this.noteBkgColor = "#fff5ad", this.noteTextColor = "#28253D", this.THEME_COLOR_LIMIT = 12, this.radius = 12, this.strokeWidth = 2, this.primaryBorderColor = at(this.primaryColor, this.darkMode), this.fontFamily = '"Recursive Variable", arial, sans-serif', this.fontSize = "14px", this.nodeBorder = "#28253D", this.stateBorder = "#28253D", this.useGradient = !1, this.gradientStart = "#0042eb", this.gradientStop = "#eb0042", this.dropShadow = "url(#drop-shadow)", this.nodeShadow = !0, this.tertiaryColor = "#ffffff", this.archEdgeColor = "calculated", this.archEdgeArrowColor = "calculated", this.archEdgeWidth = "3", this.archGroupBorderColor = this.primaryBorderColor, this.archGroupBorderWidth = "2px", this.actorBorder = "#28253D", this.noteBorderColor = "#FACC15", this.noteFontWeight = 600, this.borderColorArray = [
      "#E879F9",
      //Fuchsia-400
      "#2DD4BF",
      //Teal-400
      "#FB923C",
      //Orange-400
      "#22D3EE",
      // Cyan-400
      "#4ADE80",
      // Green-400
      "#A78BFA",
      //Violet-400
      "#F87171",
      //red-400
      "#FACC15",
      //yellow-400
      "#818CF8",
      //indigo-400
      "#A3E635 ",
      //Lime-400
      "#38BDF8",
      //Sky-400
      "#FB7185"
      //Rose-400
    ], this.bkgColorArray = [
      "#FDF4FF",
      //Fuchsia-50
      "#F0FDFA",
      //Teal-50
      "#FFF7ED",
      //Orange-50
      "#ECFEFF",
      // Cyan-50
      "#F0FDF4",
      // Green-50
      "#F5F3FF",
      //Violet-50
      "#FEF2F2",
      //red-50
      "#FEFCE8",
      //yellow-50
      "#EEF2FF",
      //indigo-50
      "#F7FEE7",
      //Lime-50
      "#F0F9FF",
      //Sky-50
      "#FFF1F2"
      //Rose-50
    ], this.filterColor = "#000000";
  }
  updateColors() {
    this.primaryTextColor = this.primaryTextColor || (this.darkMode ? "#eee" : "#28253D"), this.secondaryColor = this.secondaryColor || C(this.primaryColor, { h: -120 }), this.tertiaryColor = this.tertiaryColor || C(this.primaryColor, { h: 180, l: 5 }), this.primaryBorderColor = this.primaryBorderColor || at(this.primaryColor, this.darkMode), this.secondaryBorderColor = this.secondaryBorderColor || at(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = this.tertiaryBorderColor || at(this.tertiaryColor, this.darkMode), this.noteBorderColor = this.noteBorderColor || at(this.noteBkgColor, this.darkMode), this.noteBkgColor = this.noteBkgColor || "#fff5ad", this.noteTextColor = this.noteTextColor || "#28253D", this.secondaryTextColor = this.secondaryTextColor || _(this.secondaryColor), this.tertiaryTextColor = this.tertiaryTextColor || _(this.tertiaryColor), this.lineColor = this.lineColor || _(this.background), this.arrowheadColor = this.arrowheadColor || _(this.background), this.textColor = this.textColor || this.primaryTextColor, this.border2 = this.border2 || this.tertiaryBorderColor, this.nodeBkg = this.nodeBkg || this.primaryColor, this.mainBkg = this.mainBkg || this.primaryColor, this.nodeBorder = this.nodeBorder || this.primaryBorderColor, this.clusterBkg = this.clusterBkg || this.tertiaryColor, this.clusterBorder = this.clusterBorder || this.tertiaryBorderColor, this.defaultLinkColor = this.defaultLinkColor || this.lineColor, this.titleColor = this.titleColor || this.tertiaryTextColor, this.edgeLabelBackground = this.edgeLabelBackground || (this.darkMode ? A(this.secondaryColor, 30) : this.secondaryColor), this.nodeTextColor = this.nodeTextColor || this.primaryTextColor, this.actorBorder = this.actorBorder || this.primaryBorderColor, this.actorBkg = this.actorBkg || this.mainBkg, this.actorTextColor = this.actorTextColor || this.primaryTextColor, this.actorLineColor = this.actorLineColor || this.actorBorder, this.labelBoxBkgColor = this.labelBoxBkgColor || this.actorBkg, this.signalColor = this.signalColor || this.textColor, this.signalTextColor = this.signalTextColor || this.textColor, this.labelBoxBorderColor = this.labelBoxBorderColor || this.actorBorder, this.labelTextColor = this.labelTextColor || this.actorTextColor, this.loopTextColor = this.loopTextColor || this.actorTextColor, this.activationBorderColor = this.activationBorderColor || A(this.secondaryColor, 10), this.activationBkgColor = this.activationBkgColor || this.secondaryColor, this.sequenceNumberColor = this.sequenceNumberColor || _(this.lineColor);
    const e = "#ECECFE", t = "#E9E9F1", r = C(e, { h: 180, l: 5 });
    this.sectionBkgColor = this.sectionBkgColor || r, this.altSectionBkgColor = this.altSectionBkgColor || "white", this.sectionBkgColor = this.sectionBkgColor || t, this.sectionBkgColor2 = this.sectionBkgColor2 || e, this.excludeBkgColor = this.excludeBkgColor || "#eeeeee", this.taskBorderColor = this.taskBorderColor || this.primaryBorderColor, this.taskBkgColor = this.taskBkgColor || e, this.activeTaskBorderColor = this.activeTaskBorderColor || e, this.activeTaskBkgColor = this.activeTaskBkgColor || $(e, 23), this.gridColor = this.gridColor || "lightgrey", this.doneTaskBkgColor = this.doneTaskBkgColor || "lightgrey", this.doneTaskBorderColor = this.doneTaskBorderColor || "grey", this.critBorderColor = this.critBorderColor || "#ff8888", this.critBkgColor = this.critBkgColor || "red", this.todayLineColor = this.todayLineColor || "red", this.taskTextColor = this.taskTextColor || this.textColor, this.vertLineColor = this.vertLineColor || this.primaryBorderColor, this.taskTextOutsideColor = this.taskTextOutsideColor || this.textColor, this.taskTextLightColor = this.taskTextLightColor || this.textColor, this.taskTextColor = this.taskTextColor || this.primaryTextColor, this.taskTextDarkColor = this.taskTextDarkColor || this.textColor, this.taskTextClickableColor = this.taskTextClickableColor || "#003163", this.archEdgeColor = this.lineColor, this.archEdgeArrowColor = this.lineColor, this.personBorder = this.personBorder || this.primaryBorderColor, this.personBkg = this.personBkg || this.mainBkg, this.transitionColor = this.transitionColor || this.lineColor, this.transitionLabelColor = this.transitionLabelColor || this.textColor, this.stateLabelColor = this.stateLabelColor || this.stateBkg || this.primaryTextColor, this.stateBkg = this.stateBkg || this.mainBkg, this.labelBackgroundColor = this.labelBackgroundColor || this.stateBkg, this.compositeBackground = this.compositeBackground || this.background || this.tertiaryColor, this.altBackground = this.altBackground || "#f0f0f0", this.compositeTitleBackground = this.compositeTitleBackground || this.mainBkg, this.compositeBorder = this.compositeBorder || this.nodeBorder, this.innerEndBackground = this.nodeBorder, this.errorBkgColor = this.errorBkgColor || this.tertiaryColor, this.errorTextColor = this.errorTextColor || this.tertiaryTextColor, this.transitionColor = this.transitionColor || this.lineColor, this.specialStateColor = this.lineColor, this.cScale0 = this.cScale0 || "#f4a8ff", this.cScale1 = this.cScale1 || "#46ecd5", this.cScale2 = this.cScale2 || "#ffb86a", this.cScale3 = this.cScale3 || "#dab2ff", this.cScale4 = this.cScale4 || "#7bf1a8", this.cScale5 = this.cScale5 || "#c4b4ff", this.cScale6 = this.cScale6 || "#ffa2a2", this.cScale7 = this.cScale7 || "#ffdf20", this.cScale8 = this.cScale8 || "#a3b3ff", this.cScale9 = this.cScale9 || "#bbf451", this.cScale10 = this.cScale10 || "#74d4ff", this.cScale11 = this.cScale11 || "#ffa1ad";
    for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
      this["cScaleInv" + s] = this["cScaleInv" + s] || _(this["cScale" + s]);
    for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
      this.darkMode ? this["cScalePeer" + s] = this["cScalePeer" + s] || $(this["cScale" + s], 10) : this["cScalePeer" + s] = this["cScalePeer" + s] || A(this["cScale" + s], 10);
    this.scaleLabelColor = this.scaleLabelColor || this.labelTextColor;
    for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
      this["cScaleLabel" + s] = this["cScaleLabel" + s] || this.scaleLabelColor;
    const i = this.darkMode ? -4 : -1;
    for (let s = 0; s < 5; s++)
      this["surface" + s] = this["surface" + s] || C(this.mainBkg, { h: 180, s: -15, l: i * (5 + s * 3) }), this["surfacePeer" + s] = this["surfacePeer" + s] || C(this.mainBkg, { h: 180, s: -15, l: i * (8 + s * 3) });
    this.classText = this.classText || this.textColor, this.fillType0 = this.fillType0 || e, this.fillType1 = this.fillType1 || t, this.fillType2 = this.fillType2 || C(e, { h: 64 }), this.fillType3 = this.fillType3 || C(t, { h: 64 }), this.fillType4 = this.fillType4 || C(e, { h: -64 }), this.fillType5 = this.fillType5 || C(t, { h: -64 }), this.fillType6 = this.fillType6 || C(e, { h: 128 }), this.fillType7 = this.fillType7 || C(t, { h: 128 }), this.pie1 = this.pie1 || e, this.pie2 = this.pie2 || t, this.pie3 = this.pie3 || r, this.pie4 = this.pie4 || C(e, { l: -10 }), this.pie5 = this.pie5 || C(t, { l: -10 }), this.pie6 = this.pie6 || C(r, { l: -10 }), this.pie7 = this.pie7 || C(e, { h: 60, l: -10 }), this.pie8 = this.pie8 || C(e, { h: -60, l: -10 }), this.pie9 = this.pie9 || C(e, { h: 120, l: 0 }), this.pie10 = this.pie10 || C(e, { h: 60, l: -20 }), this.pie11 = this.pie11 || C(e, { h: -60, l: -20 }), this.pie12 = this.pie12 || C(e, { h: 120, l: -10 }), this.pieTitleTextSize = this.pieTitleTextSize || "25px", this.pieTitleTextColor = this.pieTitleTextColor || this.taskTextDarkColor, this.pieSectionTextSize = this.pieSectionTextSize || "17px", this.pieSectionTextColor = this.pieSectionTextColor || this.textColor, this.pieLegendTextSize = this.pieLegendTextSize || "17px", this.pieLegendTextColor = this.pieLegendTextColor || this.taskTextDarkColor, this.pieStrokeColor = this.pieStrokeColor || "black", this.pieStrokeWidth = this.pieStrokeWidth || "2px", this.pieOuterStrokeWidth = this.pieOuterStrokeWidth || "2px", this.pieOuterStrokeColor = this.pieOuterStrokeColor || "black", this.pieOpacity = this.pieOpacity || "0.7", this.vennTitleTextColor = this.vennTitleTextColor ?? this.titleColor, this.vennSetTextColor = this.vennSetTextColor ?? this.textColor, this.quadrant1Fill = this.quadrant1Fill || e, this.quadrant2Fill = this.quadrant2Fill || C(e, { r: 5, g: 5, b: 5 }), this.quadrant3Fill = this.quadrant3Fill || C(e, { r: 10, g: 10, b: 10 }), this.quadrant4Fill = this.quadrant4Fill || C(e, { r: 15, g: 15, b: 15 }), this.quadrant1TextFill = this.quadrant1TextFill || this.primaryTextColor, this.quadrant2TextFill = this.quadrant2TextFill || C(this.primaryTextColor, { r: -5, g: -5, b: -5 }), this.quadrant3TextFill = this.quadrant3TextFill || C(this.primaryTextColor, { r: -10, g: -10, b: -10 }), this.quadrant4TextFill = this.quadrant4TextFill || C(this.primaryTextColor, { r: -15, g: -15, b: -15 }), this.quadrantPointFill = this.quadrantPointFill || be(this.quadrant1Fill) ? $(this.quadrant1Fill) : A(this.quadrant1Fill), this.quadrantPointTextFill = this.quadrantPointTextFill || this.primaryTextColor, this.quadrantXAxisTextFill = this.quadrantXAxisTextFill || this.primaryTextColor, this.quadrantYAxisTextFill = this.quadrantYAxisTextFill || this.primaryTextColor, this.quadrantInternalBorderStrokeFill = this.quadrantInternalBorderStrokeFill || this.primaryBorderColor, this.quadrantExternalBorderStrokeFill = this.quadrantExternalBorderStrokeFill || this.primaryBorderColor, this.quadrantTitleFill = this.quadrantTitleFill || this.primaryTextColor, this.xyChart = {
      backgroundColor: this.xyChart?.backgroundColor || this.background,
      titleColor: this.xyChart?.titleColor || this.primaryTextColor,
      xAxisTitleColor: this.xyChart?.xAxisTitleColor || this.primaryTextColor,
      xAxisLabelColor: this.xyChart?.xAxisLabelColor || this.primaryTextColor,
      xAxisTickColor: this.xyChart?.xAxisTickColor || this.primaryTextColor,
      xAxisLineColor: this.xyChart?.xAxisLineColor || this.primaryTextColor,
      yAxisTitleColor: this.xyChart?.yAxisTitleColor || this.primaryTextColor,
      yAxisLabelColor: this.xyChart?.yAxisLabelColor || this.primaryTextColor,
      yAxisTickColor: this.xyChart?.yAxisTickColor || this.primaryTextColor,
      yAxisLineColor: this.xyChart?.yAxisLineColor || this.primaryTextColor,
      plotColorPalette: this.xyChart?.plotColorPalette || "#FFF4DD,#FFD8B1,#FFA07A,#ECEFF1,#D6DBDF,#C3E0A8,#FFB6A4,#FFD74D,#738FA7,#FFFFF0"
    }, this.requirementBackground = this.requirementBackground || e, this.requirementBorderColor = this.requirementBorderColor || this.primaryBorderColor, this.requirementBorderSize = this.requirementBorderSize || "1", this.requirementTextColor = this.requirementTextColor || this.primaryTextColor, this.relationColor = this.relationColor || this.lineColor, this.relationLabelBackground = this.relationLabelBackground || (this.darkMode ? A(this.secondaryColor, 30) : this.secondaryColor), this.relationLabelColor = this.relationLabelColor || this.actorTextColor, this.git0 = this.git0 || e, this.git1 = this.git1 || t, this.git2 = this.git2 || r, this.git3 = this.git3 || C(e, { h: -30 }), this.git4 = this.git4 || C(e, { h: -60 }), this.git5 = this.git5 || C(e, { h: -90 }), this.git6 = this.git6 || C(e, { h: 60 }), this.git7 = this.git7 || C(e, { h: 120 }), this.darkMode ? (this.git0 = $(this.git0, 25), this.git1 = $(this.git1, 25), this.git2 = $(this.git2, 25), this.git3 = $(this.git3, 25), this.git4 = $(this.git4, 25), this.git5 = $(this.git5, 25), this.git6 = $(this.git6, 25), this.git7 = $(this.git7, 25)) : (this.git0 = A(this.git0, 25), this.git1 = A(this.git1, 25), this.git2 = A(this.git2, 25), this.git3 = A(this.git3, 25), this.git4 = A(this.git4, 25), this.git5 = A(this.git5, 25), this.git6 = A(this.git6, 25), this.git7 = A(this.git7, 25)), this.gitInv0 = this.gitInv0 || _(this.git0), this.gitInv1 = this.gitInv1 || _(this.git1), this.gitInv2 = this.gitInv2 || _(this.git2), this.gitInv3 = this.gitInv3 || _(this.git3), this.gitInv4 = this.gitInv4 || _(this.git4), this.gitInv5 = this.gitInv5 || _(this.git5), this.gitInv6 = this.gitInv6 || _(this.git6), this.gitInv7 = this.gitInv7 || _(this.git7), this.branchLabelColor = this.branchLabelColor || (this.darkMode ? "black" : this.labelTextColor), this.gitBranchLabel0 = this.gitBranchLabel0 || this.branchLabelColor, this.gitBranchLabel1 = this.gitBranchLabel1 || this.branchLabelColor, this.gitBranchLabel2 = this.gitBranchLabel2 || this.branchLabelColor, this.gitBranchLabel3 = this.gitBranchLabel3 || this.branchLabelColor, this.gitBranchLabel4 = this.gitBranchLabel4 || this.branchLabelColor, this.gitBranchLabel5 = this.gitBranchLabel5 || this.branchLabelColor, this.gitBranchLabel6 = this.gitBranchLabel6 || this.branchLabelColor, this.gitBranchLabel7 = this.gitBranchLabel7 || this.branchLabelColor, this.tagLabelColor = this.tagLabelColor || this.primaryTextColor, this.tagLabelBackground = this.tagLabelBackground || this.primaryColor, this.tagLabelBorder = this.tagBorder || this.primaryBorderColor, this.tagLabelFontSize = this.tagLabelFontSize || "10px", this.commitLabelColor = this.commitLabelColor || this.secondaryTextColor, this.commitLabelBackground = this.commitLabelBackground || this.secondaryColor, this.commitLineColor = this.commitLineColor ?? "#BDBCCC", this.commitLabelFontSize = this.commitLabelFontSize || "10px", this.fontWeight = 600, this.erEdgeLabelBackground = "#FFFFFF", this.attributeBackgroundColorOdd = this.attributeBackgroundColorOdd || Ae, this.attributeBackgroundColorEven = this.attributeBackgroundColorEven || Me;
  }
  calculate(e) {
    if (typeof e != "object") {
      this.updateColors();
      return;
    }
    const t = Object.keys(e);
    t.forEach((r) => {
      this[r] = e[r];
    }), this.updateColors(), t.forEach((r) => {
      this[r] = e[r];
    });
  }
}, v0 = /* @__PURE__ */ f((e) => {
  const t = new _0();
  return t.calculate(e), t;
}, "getThemeVariables"), B0 = class {
  static {
    f(this, "Theme");
  }
  constructor() {
    this.background = "#333", this.primaryColor = "#1f2020", this.secondaryColor = $(this.primaryColor, 16), this.tertiaryColor = C(this.primaryColor, { h: -160 }), this.primaryBorderColor = _(this.background), this.secondaryBorderColor = at(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = at(this.tertiaryColor, this.darkMode), this.primaryTextColor = _(this.primaryColor), this.secondaryTextColor = _(this.secondaryColor), this.tertiaryTextColor = _(this.tertiaryColor), this.mainBkg = "#111113", this.secondBkg = "calculated", this.mainContrastColor = "lightgrey", this.darkTextColor = $(_("#323D47"), 10), this.border1 = "#ccc", this.border2 = Je(255, 255, 255, 0.25), this.arrowheadColor = _(this.background), this.fontFamily = '"Recursive Variable", arial, sans-serif', this.fontSize = "14px", this.labelBackground = "#111113", this.textColor = "#ccc", this.THEME_COLOR_LIMIT = 12, this.radius = 12, this.strokeWidth = 2, this.noteBkgColor = this.noteBkgColor ?? "#FEF9C3", this.noteTextColor = this.noteTextColor ?? "#28253D", this.THEME_COLOR_LIMIT = 12, this.fontFamily = '"Recursive Variable", arial, sans-serif', this.fontSize = "14px", this.nodeBorder = "#FFFFFF", this.stateBorder = "#FFFFFF", this.useGradient = !1, this.gradientStart = "#0042eb", this.gradientStop = "#eb0042", this.dropShadow = "url(#drop-shadow)", this.nodeShadow = !0, this.archEdgeColor = "calculated", this.archEdgeArrowColor = "calculated", this.archEdgeWidth = "3", this.archGroupBorderColor = this.primaryBorderColor, this.archGroupBorderWidth = "2px", this.clusterBkg = "#1E1A2E", this.clusterBorder = "#BDBCCC", this.noteBorderColor = "#FACC15", this.noteFontWeight = 600, this.borderColorArray = [
      "#E879F9",
      //Fuchsia-400
      "#2DD4BF",
      //Teal-400
      "#FB923C",
      //Orange-400
      "#22D3EE",
      // Cyan-400
      "#4ADE80",
      // Green-400
      "#A78BFA",
      //Violet-400
      "#F87171",
      //red-400
      "#FACC15",
      //yellow-400
      "#818CF8",
      //indigo-400
      "#A3E635 ",
      //Lime-400
      "#38BDF8",
      //Sky-400
      "#FB7185"
      //Rose-400
    ], this.bkgColorArray = [], this.filterColor = "#FFFFFF";
  }
  updateColors() {
    this.primaryTextColor = this.primaryTextColor || (this.darkMode ? "#eee" : "#FFFFFF"), this.secondaryColor = this.secondaryColor || C(this.primaryColor, { h: -120 }), this.tertiaryColor = this.tertiaryColor || C(this.primaryColor, { h: 180, l: 5 }), this.primaryBorderColor = this.primaryBorderColor || at(this.primaryColor, this.darkMode), this.secondaryBorderColor = this.secondaryBorderColor || at(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = this.tertiaryBorderColor || at(this.tertiaryColor, this.darkMode), this.noteBorderColor = this.noteBorderColor || at(this.noteBkgColor, this.darkMode), this.noteBkgColor = this.noteBkgColor || "#fff5ad", this.noteTextColor = this.noteTextColor || "#FFFFFF", this.secondaryTextColor = this.secondaryTextColor || _(this.secondaryColor), this.tertiaryTextColor = this.tertiaryTextColor || _(this.tertiaryColor), this.lineColor = this.lineColor || _(this.background), this.arrowheadColor = this.arrowheadColor || _(this.background), this.textColor = this.textColor || this.primaryTextColor, this.border2 = this.border2 || this.tertiaryBorderColor, this.nodeBkg = this.nodeBkg || this.primaryColor, this.mainBkg = this.mainBkg || this.primaryColor, this.nodeBorder = this.nodeBorder || this.border1, this.clusterBkg = this.clusterBkg || this.tertiaryColor, this.clusterBorder = this.clusterBorder || this.tertiaryBorderColor, this.defaultLinkColor = this.defaultLinkColor || this.lineColor, this.titleColor = this.titleColor || this.tertiaryTextColor, this.edgeLabelBackground = this.edgeLabelBackground || (this.darkMode ? A(this.secondaryColor, 30) : this.secondaryColor), this.nodeTextColor = this.nodeTextColor || this.primaryTextColor, this.actorBorder = "#FFFFFF", this.signalColor = "#FFFFFF", this.labelBoxBorderColor = "#BDBCCC", this.actorBorder = this.actorBorder || this.primaryBorderColor, this.actorBkg = this.actorBkg || this.mainBkg, this.actorTextColor = this.actorTextColor || this.primaryTextColor, this.actorLineColor = this.actorLineColor || this.actorBorder, this.labelBoxBkgColor = this.labelBoxBkgColor || this.actorBkg, this.signalColor = this.signalColor || this.textColor, this.signalTextColor = this.signalTextColor || this.textColor, this.labelBoxBorderColor = this.labelBoxBorderColor || this.actorBorder, this.labelTextColor = this.labelTextColor || this.actorTextColor, this.loopTextColor = this.loopTextColor || this.actorTextColor, this.activationBorderColor = this.activationBorderColor || A(this.secondaryColor, 10), this.activationBkgColor = this.activationBkgColor || this.secondaryColor, this.sequenceNumberColor = this.sequenceNumberColor || _(this.lineColor), this.rootLabelColor = "#FFFFFF", this.sectionBkgColor = this.sectionBkgColor || this.tertiaryColor, this.altSectionBkgColor = this.altSectionBkgColor || "white", this.sectionBkgColor = this.sectionBkgColor || this.secondaryColor, this.sectionBkgColor2 = this.sectionBkgColor2 || this.primaryColor, this.excludeBkgColor = this.excludeBkgColor || "#eeeeee", this.taskBorderColor = this.taskBorderColor || this.primaryBorderColor, this.taskBkgColor = this.taskBkgColor || this.primaryColor, this.activeTaskBorderColor = this.activeTaskBorderColor || this.primaryColor, this.activeTaskBkgColor = this.activeTaskBkgColor || $(this.primaryColor, 23), this.gridColor = this.gridColor || "lightgrey", this.doneTaskBkgColor = this.doneTaskBkgColor || "lightgrey", this.doneTaskBorderColor = this.doneTaskBorderColor || "grey", this.critBorderColor = this.critBorderColor || "#ff8888", this.critBkgColor = this.critBkgColor || "red", this.todayLineColor = this.todayLineColor || "red", this.taskTextColor = this.taskTextColor || this.textColor, this.vertLineColor = this.vertLineColor || this.primaryBorderColor, this.taskTextOutsideColor = this.taskTextOutsideColor || this.textColor, this.taskTextLightColor = this.taskTextLightColor || this.textColor, this.taskTextColor = this.taskTextColor || this.primaryTextColor, this.taskTextDarkColor = this.taskTextDarkColor || this.textColor, this.taskTextClickableColor = this.taskTextClickableColor || "#003163", this.archEdgeColor = this.lineColor, this.archEdgeArrowColor = this.lineColor, this.personBorder = this.personBorder || this.primaryBorderColor, this.personBkg = this.personBkg || this.mainBkg, this.transitionColor = this.transitionColor || this.lineColor, this.transitionLabelColor = this.transitionLabelColor || this.textColor, this.stateLabelColor = this.stateLabelColor || this.stateBkg || this.primaryTextColor, this.stateBkg = this.stateBkg || this.mainBkg, this.labelBackgroundColor = this.labelBackgroundColor || this.stateBkg, this.compositeBackground = this.compositeBackground || this.background || this.tertiaryColor, this.altBackground = this.altBackground || "#f0f0f0", this.compositeTitleBackground = this.compositeTitleBackground || this.mainBkg, this.compositeBorder = this.compositeBorder || this.nodeBorder, this.innerEndBackground = this.nodeBorder, this.errorBkgColor = this.errorBkgColor || this.tertiaryColor, this.errorTextColor = this.errorTextColor || this.tertiaryTextColor, this.transitionColor = this.transitionColor || this.lineColor, this.specialStateColor = this.lineColor, this.cScale0 = this.cScale0 || "#f4a8ff", this.cScale1 = this.cScale1 || "#46ecd5", this.cScale2 = this.cScale2 || "#ffb86a", this.cScale3 = this.cScale3 || "#dab2ff", this.cScale4 = this.cScale4 || "#7bf1a8", this.cScale5 = this.cScale5 || "#c4b4ff", this.cScale6 = this.cScale6 || "#ffa2a2", this.cScale7 = this.cScale7 || "#ffdf20", this.cScale8 = this.cScale8 || "#a3b3ff", this.cScale9 = this.cScale9 || "#bbf451", this.cScale10 = this.cScale10 || "#74d4ff", this.cScale11 = this.cScale11 || "#ffa1ad";
    for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
      this["cScaleInv" + t] = this["cScaleInv" + t] || _(this["cScale" + t]);
    for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
      this.darkMode ? this["cScalePeer" + t] = this["cScalePeer" + t] || $(this["cScale" + t], 10) : this["cScalePeer" + t] = this["cScalePeer" + t] || A(this["cScale" + t], 10);
    this.scaleLabelColor = this.scaleLabelColor || this.labelTextColor;
    for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
      this["cScaleLabel" + t] = A(this["cScale" + t], 75);
    const e = this.darkMode ? -4 : -1;
    for (let t = 0; t < 5; t++)
      this["surface" + t] = this["surface" + t] || C(this.mainBkg, { h: 180, s: -15, l: e * (5 + t * 3) }), this["surfacePeer" + t] = this["surfacePeer" + t] || C(this.mainBkg, { h: 180, s: -15, l: e * (8 + t * 3) });
    this.classText = this.classText || this.textColor, this.fillType0 = this.fillType0 || this.primaryColor, this.fillType1 = this.fillType1 || this.secondaryColor, this.fillType2 = this.fillType2 || C(this.primaryColor, { h: 64 }), this.fillType3 = this.fillType3 || C(this.secondaryColor, { h: 64 }), this.fillType4 = this.fillType4 || C(this.primaryColor, { h: -64 }), this.fillType5 = this.fillType5 || C(this.secondaryColor, { h: -64 }), this.fillType6 = this.fillType6 || C(this.primaryColor, { h: 128 }), this.fillType7 = this.fillType7 || C(this.secondaryColor, { h: 128 }), this.pie1 = this.pie1 || this.primaryColor, this.pie2 = this.pie2 || this.secondaryColor, this.pie3 = this.pie3 || this.tertiaryColor, this.pie4 = this.pie4 || C(this.primaryColor, { l: -10 }), this.pie5 = this.pie5 || C(this.secondaryColor, { l: -10 }), this.pie6 = this.pie6 || C(this.tertiaryColor, { l: -10 }), this.pie7 = this.pie7 || C(this.primaryColor, { h: 60, l: -10 }), this.pie8 = this.pie8 || C(this.primaryColor, { h: -60, l: -10 }), this.pie9 = this.pie9 || C(this.primaryColor, { h: 120, l: 0 }), this.pie10 = this.pie10 || C(this.primaryColor, { h: 60, l: -20 }), this.pie11 = this.pie11 || C(this.primaryColor, { h: -60, l: -20 }), this.pie12 = this.pie12 || C(this.primaryColor, { h: 120, l: -10 }), this.pieTitleTextSize = this.pieTitleTextSize || "25px", this.pieTitleTextColor = this.pieTitleTextColor || this.taskTextDarkColor, this.pieSectionTextSize = this.pieSectionTextSize || "17px", this.pieSectionTextColor = this.pieSectionTextColor || this.textColor, this.pieLegendTextSize = this.pieLegendTextSize || "17px", this.pieLegendTextColor = this.pieLegendTextColor || this.taskTextDarkColor, this.pieStrokeColor = this.pieStrokeColor || "black", this.pieStrokeWidth = this.pieStrokeWidth || "2px", this.pieOuterStrokeWidth = this.pieOuterStrokeWidth || "2px", this.pieOuterStrokeColor = this.pieOuterStrokeColor || "black", this.pieOpacity = this.pieOpacity || "0.7", this.vennTitleTextColor = this.vennTitleTextColor ?? this.titleColor, this.vennSetTextColor = this.vennSetTextColor ?? this.textColor, this.quadrant1Fill = this.quadrant1Fill || this.primaryColor, this.quadrant2Fill = this.quadrant2Fill || C(this.primaryColor, { r: 5, g: 5, b: 5 }), this.quadrant3Fill = this.quadrant3Fill || C(this.primaryColor, { r: 10, g: 10, b: 10 }), this.quadrant4Fill = this.quadrant4Fill || C(this.primaryColor, { r: 15, g: 15, b: 15 }), this.quadrant1TextFill = this.quadrant1TextFill || this.primaryTextColor, this.quadrant2TextFill = this.quadrant2TextFill || C(this.primaryTextColor, { r: -5, g: -5, b: -5 }), this.quadrant3TextFill = this.quadrant3TextFill || C(this.primaryTextColor, { r: -10, g: -10, b: -10 }), this.quadrant4TextFill = this.quadrant4TextFill || C(this.primaryTextColor, { r: -15, g: -15, b: -15 }), this.quadrantPointFill = this.quadrantPointFill || be(this.quadrant1Fill) ? $(this.quadrant1Fill) : A(this.quadrant1Fill), this.quadrantPointTextFill = this.quadrantPointTextFill || this.primaryTextColor, this.quadrantXAxisTextFill = this.quadrantXAxisTextFill || this.primaryTextColor, this.quadrantYAxisTextFill = this.quadrantYAxisTextFill || this.primaryTextColor, this.quadrantInternalBorderStrokeFill = this.quadrantInternalBorderStrokeFill || this.primaryBorderColor, this.quadrantExternalBorderStrokeFill = this.quadrantExternalBorderStrokeFill || this.primaryBorderColor, this.quadrantTitleFill = this.quadrantTitleFill || this.primaryTextColor, this.xyChart = {
      backgroundColor: this.xyChart?.backgroundColor || this.background,
      titleColor: this.xyChart?.titleColor || this.primaryTextColor,
      xAxisTitleColor: this.xyChart?.xAxisTitleColor || this.primaryTextColor,
      xAxisLabelColor: this.xyChart?.xAxisLabelColor || this.primaryTextColor,
      xAxisTickColor: this.xyChart?.xAxisTickColor || this.primaryTextColor,
      xAxisLineColor: this.xyChart?.xAxisLineColor || this.primaryTextColor,
      yAxisTitleColor: this.xyChart?.yAxisTitleColor || this.primaryTextColor,
      yAxisLabelColor: this.xyChart?.yAxisLabelColor || this.primaryTextColor,
      yAxisTickColor: this.xyChart?.yAxisTickColor || this.primaryTextColor,
      yAxisLineColor: this.xyChart?.yAxisLineColor || this.primaryTextColor,
      plotColorPalette: this.xyChart?.plotColorPalette || "#FFF4DD,#FFD8B1,#FFA07A,#ECEFF1,#D6DBDF,#C3E0A8,#FFB6A4,#FFD74D,#738FA7,#FFFFF0"
    }, this.requirementBackground = this.requirementBackground || this.primaryColor, this.requirementBorderColor = this.requirementBorderColor || this.primaryBorderColor, this.requirementBorderSize = this.requirementBorderSize || "1", this.requirementTextColor = this.requirementTextColor || this.primaryTextColor, this.relationColor = this.relationColor || this.lineColor, this.relationLabelBackground = this.relationLabelBackground || (this.darkMode ? A(this.secondaryColor, 30) : this.secondaryColor), this.relationLabelColor = this.relationLabelColor || this.actorTextColor, this.git0 = this.git0 || this.primaryColor, this.git1 = this.git1 || this.secondaryColor, this.git2 = this.git2 || this.tertiaryColor, this.git3 = this.git3 || C(this.primaryColor, { h: -30 }), this.git4 = this.git4 || C(this.primaryColor, { h: -60 }), this.git5 = this.git5 || C(this.primaryColor, { h: -90 }), this.git6 = this.git6 || C(this.primaryColor, { h: 60 }), this.git7 = this.git7 || C(this.primaryColor, { h: 120 }), this.darkMode ? (this.git0 = $(this.git0, 25), this.git1 = $(this.git1, 25), this.git2 = $(this.git2, 25), this.git3 = $(this.git3, 25), this.git4 = $(this.git4, 25), this.git5 = $(this.git5, 25), this.git6 = $(this.git6, 25), this.git7 = $(this.git7, 25)) : (this.git0 = A(this.git0, 25), this.git1 = A(this.git1, 25), this.git2 = A(this.git2, 25), this.git3 = A(this.git3, 25), this.git4 = A(this.git4, 25), this.git5 = A(this.git5, 25), this.git6 = A(this.git6, 25), this.git7 = A(this.git7, 25)), this.gitInv0 = this.gitInv0 || _(this.git0), this.gitInv1 = this.gitInv1 || _(this.git1), this.gitInv2 = this.gitInv2 || _(this.git2), this.gitInv3 = this.gitInv3 || _(this.git3), this.gitInv4 = this.gitInv4 || _(this.git4), this.gitInv5 = this.gitInv5 || _(this.git5), this.gitInv6 = this.gitInv6 || _(this.git6), this.gitInv7 = this.gitInv7 || _(this.git7), this.branchLabelColor = this.branchLabelColor || (this.darkMode ? "black" : this.labelTextColor), this.gitBranchLabel0 = this.gitBranchLabel0 || this.branchLabelColor, this.gitBranchLabel1 = this.gitBranchLabel1 || this.branchLabelColor, this.gitBranchLabel2 = this.gitBranchLabel2 || this.branchLabelColor, this.gitBranchLabel3 = this.gitBranchLabel3 || this.branchLabelColor, this.gitBranchLabel4 = this.gitBranchLabel4 || this.branchLabelColor, this.gitBranchLabel5 = this.gitBranchLabel5 || this.branchLabelColor, this.gitBranchLabel6 = this.gitBranchLabel6 || this.branchLabelColor, this.gitBranchLabel7 = this.gitBranchLabel7 || this.branchLabelColor, this.tagLabelColor = this.tagLabelColor || this.primaryTextColor, this.tagLabelBackground = this.tagLabelBackground || this.primaryColor, this.tagLabelBorder = this.tagBorder || this.primaryBorderColor, this.tagLabelFontSize = this.tagLabelFontSize || "10px", this.commitLabelColor = this.commitLabelColor || this.secondaryTextColor, this.commitLabelBackground = this.commitLabelBackground || this.secondaryColor, this.commitLabelFontSize = this.commitLabelFontSize || "10px", this.commitLineColor = this.commitLineColor ?? "#BDBCCC", this.fontWeight = 600, this.erEdgeLabelBackground = "#16141F", this.attributeBackgroundColorOdd = this.attributeBackgroundColorOdd || Ae, this.attributeBackgroundColorEven = this.attributeBackgroundColorEven || Me;
  }
  calculate(e) {
    if (typeof e != "object") {
      this.updateColors();
      return;
    }
    const t = Object.keys(e);
    t.forEach((r) => {
      this[r] = e[r];
    }), this.updateColors(), t.forEach((r) => {
      this[r] = e[r];
    });
  }
}, L0 = /* @__PURE__ */ f((e) => {
  const t = new B0();
  return t.calculate(e), t;
}, "getThemeVariables"), qe = {
  base: {
    getThemeVariables: l0
  },
  dark: {
    getThemeVariables: c0
  },
  default: {
    getThemeVariables: d0
  },
  forest: {
    getThemeVariables: f0
  },
  neutral: {
    getThemeVariables: m0
  },
  neo: {
    getThemeVariables: C0
  },
  "neo-dark": {
    getThemeVariables: b0
  },
  redux: {
    getThemeVariables: T0
  },
  "redux-dark": {
    getThemeVariables: S0
  },
  "redux-color": {
    getThemeVariables: v0
  },
  "redux-dark-color": {
    getThemeVariables: L0
  }
}, ie = {
  flowchart: {
    useMaxWidth: !0,
    titleTopMargin: 25,
    subGraphTitleMargin: {
      top: 0,
      bottom: 0
    },
    diagramPadding: 8,
    htmlLabels: null,
    nodeSpacing: 50,
    rankSpacing: 50,
    curve: "basis",
    padding: 15,
    defaultRenderer: "dagre-wrapper",
    wrappingWidth: 200,
    inheritDir: !1
  },
  sequence: {
    useMaxWidth: !0,
    hideUnusedParticipants: !1,
    activationWidth: 10,
    diagramMarginX: 50,
    diagramMarginY: 10,
    actorMargin: 50,
    width: 150,
    height: 65,
    boxMargin: 10,
    boxTextMargin: 5,
    noteMargin: 10,
    messageMargin: 35,
    messageAlign: "center",
    mirrorActors: !0,
    forceMenus: !1,
    bottomMarginAdj: 1,
    rightAngles: !1,
    showSequenceNumbers: !1,
    actorFontSize: 14,
    actorFontFamily: '"Open Sans", sans-serif',
    actorFontWeight: 400,
    noteFontSize: 14,
    noteFontFamily: '"trebuchet ms", verdana, arial, sans-serif',
    noteFontWeight: 400,
    noteAlign: "center",
    messageFontSize: 16,
    messageFontFamily: '"trebuchet ms", verdana, arial, sans-serif',
    messageFontWeight: 400,
    wrap: !1,
    wrapPadding: 10,
    labelBoxWidth: 50,
    labelBoxHeight: 20
  },
  gantt: {
    useMaxWidth: !0,
    titleTopMargin: 25,
    barHeight: 20,
    barGap: 4,
    topPadding: 50,
    rightPadding: 75,
    leftPadding: 75,
    gridLineStartPadding: 35,
    fontSize: 11,
    sectionFontSize: 11,
    numberSectionStyles: 4,
    axisFormat: "%Y-%m-%d",
    topAxis: !1,
    displayMode: "",
    weekday: "sunday"
  },
  journey: {
    useMaxWidth: !0,
    diagramMarginX: 50,
    diagramMarginY: 10,
    leftMargin: 150,
    maxLabelWidth: 360,
    width: 150,
    height: 50,
    boxMargin: 10,
    boxTextMargin: 5,
    noteMargin: 10,
    messageMargin: 35,
    messageAlign: "center",
    bottomMarginAdj: 1,
    rightAngles: !1,
    taskFontSize: 14,
    taskFontFamily: '"Open Sans", sans-serif',
    taskMargin: 50,
    activationWidth: 10,
    textPlacement: "fo",
    actorColours: [
      "#8FBC8F",
      "#7CFC00",
      "#00FFFF",
      "#20B2AA",
      "#B0E0E6",
      "#FFFFE0"
    ],
    sectionFills: [
      "#191970",
      "#8B008B",
      "#4B0082",
      "#2F4F4F",
      "#800000",
      "#8B4513",
      "#00008B"
    ],
    sectionColours: [
      "#fff"
    ],
    titleColor: "",
    titleFontFamily: '"trebuchet ms", verdana, arial, sans-serif',
    titleFontSize: "4ex"
  },
  class: {
    useMaxWidth: !0,
    titleTopMargin: 25,
    arrowMarkerAbsolute: !1,
    dividerMargin: 10,
    padding: 5,
    textHeight: 10,
    defaultRenderer: "dagre-wrapper",
    htmlLabels: !1,
    hideEmptyMembersBox: !1
  },
  state: {
    useMaxWidth: !0,
    titleTopMargin: 25,
    dividerMargin: 10,
    sizeUnit: 5,
    padding: 8,
    textHeight: 10,
    titleShift: -15,
    noteMargin: 10,
    forkWidth: 70,
    forkHeight: 7,
    miniPadding: 2,
    fontSizeFactor: 5.02,
    fontSize: 24,
    labelHeight: 16,
    edgeLengthFactor: "20",
    compositTitleSize: 35,
    radius: 5,
    defaultRenderer: "dagre-wrapper"
  },
  er: {
    useMaxWidth: !0,
    titleTopMargin: 25,
    diagramPadding: 20,
    layoutDirection: "TB",
    minEntityWidth: 100,
    minEntityHeight: 75,
    entityPadding: 15,
    nodeSpacing: 140,
    rankSpacing: 80,
    stroke: "gray",
    fill: "honeydew",
    fontSize: 12
  },
  pie: {
    useMaxWidth: !0,
    textPosition: 0.75
  },
  quadrantChart: {
    useMaxWidth: !0,
    chartWidth: 500,
    chartHeight: 500,
    titleFontSize: 20,
    titlePadding: 10,
    quadrantPadding: 5,
    xAxisLabelPadding: 5,
    yAxisLabelPadding: 5,
    xAxisLabelFontSize: 16,
    yAxisLabelFontSize: 16,
    quadrantLabelFontSize: 16,
    quadrantTextTopPadding: 5,
    pointTextPadding: 5,
    pointLabelFontSize: 12,
    pointRadius: 5,
    xAxisPosition: "top",
    yAxisPosition: "left",
    quadrantInternalBorderStrokeWidth: 1,
    quadrantExternalBorderStrokeWidth: 2
  },
  xyChart: {
    useMaxWidth: !0,
    width: 700,
    height: 500,
    titleFontSize: 20,
    titlePadding: 10,
    showDataLabel: !1,
    showDataLabelOutsideBar: !1,
    showTitle: !0,
    xAxis: {
      $ref: "#/$defs/XYChartAxisConfig",
      showLabel: !0,
      labelFontSize: 14,
      labelPadding: 5,
      showTitle: !0,
      titleFontSize: 16,
      titlePadding: 5,
      showTick: !0,
      tickLength: 5,
      tickWidth: 2,
      showAxisLine: !0,
      axisLineWidth: 2
    },
    yAxis: {
      $ref: "#/$defs/XYChartAxisConfig",
      showLabel: !0,
      labelFontSize: 14,
      labelPadding: 5,
      showTitle: !0,
      titleFontSize: 16,
      titlePadding: 5,
      showTick: !0,
      tickLength: 5,
      tickWidth: 2,
      showAxisLine: !0,
      axisLineWidth: 2
    },
    chartOrientation: "vertical",
    plotReservedSpacePercent: 50
  },
  requirement: {
    useMaxWidth: !0,
    rect_fill: "#f9f9f9",
    text_color: "#333",
    rect_border_size: "0.5px",
    rect_border_color: "#bbb",
    rect_min_width: 200,
    rect_min_height: 200,
    fontSize: 14,
    rect_padding: 10,
    line_height: 20
  },
  mindmap: {
    useMaxWidth: !0,
    padding: 10,
    maxNodeWidth: 200,
    layoutAlgorithm: "cose-bilkent"
  },
  ishikawa: {
    useMaxWidth: !0,
    diagramPadding: 20
  },
  kanban: {
    useMaxWidth: !0,
    padding: 8,
    sectionWidth: 200,
    ticketBaseUrl: ""
  },
  timeline: {
    useMaxWidth: !0,
    diagramMarginX: 50,
    diagramMarginY: 10,
    leftMargin: 150,
    width: 150,
    height: 50,
    boxMargin: 10,
    boxTextMargin: 5,
    noteMargin: 10,
    messageMargin: 35,
    messageAlign: "center",
    bottomMarginAdj: 1,
    rightAngles: !1,
    taskFontSize: 14,
    taskFontFamily: '"Open Sans", sans-serif',
    taskMargin: 50,
    activationWidth: 10,
    textPlacement: "fo",
    actorColours: [
      "#8FBC8F",
      "#7CFC00",
      "#00FFFF",
      "#20B2AA",
      "#B0E0E6",
      "#FFFFE0"
    ],
    sectionFills: [
      "#191970",
      "#8B008B",
      "#4B0082",
      "#2F4F4F",
      "#800000",
      "#8B4513",
      "#00008B"
    ],
    sectionColours: [
      "#fff"
    ],
    disableMulticolor: !1
  },
  gitGraph: {
    useMaxWidth: !0,
    titleTopMargin: 25,
    diagramPadding: 8,
    nodeLabel: {
      width: 75,
      height: 100,
      x: -25,
      y: 0
    },
    mainBranchName: "main",
    mainBranchOrder: 0,
    showCommitLabel: !0,
    showBranches: !0,
    rotateCommitLabel: !0,
    parallelCommits: !1,
    arrowMarkerAbsolute: !1
  },
  c4: {
    useMaxWidth: !0,
    diagramMarginX: 50,
    diagramMarginY: 10,
    c4ShapeMargin: 50,
    c4ShapePadding: 20,
    width: 216,
    height: 60,
    boxMargin: 10,
    c4ShapeInRow: 4,
    nextLinePaddingX: 0,
    c4BoundaryInRow: 2,
    personFontSize: 14,
    personFontFamily: '"Open Sans", sans-serif',
    personFontWeight: "normal",
    external_personFontSize: 14,
    external_personFontFamily: '"Open Sans", sans-serif',
    external_personFontWeight: "normal",
    systemFontSize: 14,
    systemFontFamily: '"Open Sans", sans-serif',
    systemFontWeight: "normal",
    external_systemFontSize: 14,
    external_systemFontFamily: '"Open Sans", sans-serif',
    external_systemFontWeight: "normal",
    system_dbFontSize: 14,
    system_dbFontFamily: '"Open Sans", sans-serif',
    system_dbFontWeight: "normal",
    external_system_dbFontSize: 14,
    external_system_dbFontFamily: '"Open Sans", sans-serif',
    external_system_dbFontWeight: "normal",
    system_queueFontSize: 14,
    system_queueFontFamily: '"Open Sans", sans-serif',
    system_queueFontWeight: "normal",
    external_system_queueFontSize: 14,
    external_system_queueFontFamily: '"Open Sans", sans-serif',
    external_system_queueFontWeight: "normal",
    boundaryFontSize: 14,
    boundaryFontFamily: '"Open Sans", sans-serif',
    boundaryFontWeight: "normal",
    messageFontSize: 12,
    messageFontFamily: '"Open Sans", sans-serif',
    messageFontWeight: "normal",
    containerFontSize: 14,
    containerFontFamily: '"Open Sans", sans-serif',
    containerFontWeight: "normal",
    external_containerFontSize: 14,
    external_containerFontFamily: '"Open Sans", sans-serif',
    external_containerFontWeight: "normal",
    container_dbFontSize: 14,
    container_dbFontFamily: '"Open Sans", sans-serif',
    container_dbFontWeight: "normal",
    external_container_dbFontSize: 14,
    external_container_dbFontFamily: '"Open Sans", sans-serif',
    external_container_dbFontWeight: "normal",
    container_queueFontSize: 14,
    container_queueFontFamily: '"Open Sans", sans-serif',
    container_queueFontWeight: "normal",
    external_container_queueFontSize: 14,
    external_container_queueFontFamily: '"Open Sans", sans-serif',
    external_container_queueFontWeight: "normal",
    componentFontSize: 14,
    componentFontFamily: '"Open Sans", sans-serif',
    componentFontWeight: "normal",
    external_componentFontSize: 14,
    external_componentFontFamily: '"Open Sans", sans-serif',
    external_componentFontWeight: "normal",
    component_dbFontSize: 14,
    component_dbFontFamily: '"Open Sans", sans-serif',
    component_dbFontWeight: "normal",
    external_component_dbFontSize: 14,
    external_component_dbFontFamily: '"Open Sans", sans-serif',
    external_component_dbFontWeight: "normal",
    component_queueFontSize: 14,
    component_queueFontFamily: '"Open Sans", sans-serif',
    component_queueFontWeight: "normal",
    external_component_queueFontSize: 14,
    external_component_queueFontFamily: '"Open Sans", sans-serif',
    external_component_queueFontWeight: "normal",
    wrap: !0,
    wrapPadding: 10,
    person_bg_color: "#08427B",
    person_border_color: "#073B6F",
    external_person_bg_color: "#686868",
    external_person_border_color: "#8A8A8A",
    system_bg_color: "#1168BD",
    system_border_color: "#3C7FC0",
    system_db_bg_color: "#1168BD",
    system_db_border_color: "#3C7FC0",
    system_queue_bg_color: "#1168BD",
    system_queue_border_color: "#3C7FC0",
    external_system_bg_color: "#999999",
    external_system_border_color: "#8A8A8A",
    external_system_db_bg_color: "#999999",
    external_system_db_border_color: "#8A8A8A",
    external_system_queue_bg_color: "#999999",
    external_system_queue_border_color: "#8A8A8A",
    container_bg_color: "#438DD5",
    container_border_color: "#3C7FC0",
    container_db_bg_color: "#438DD5",
    container_db_border_color: "#3C7FC0",
    container_queue_bg_color: "#438DD5",
    container_queue_border_color: "#3C7FC0",
    external_container_bg_color: "#B3B3B3",
    external_container_border_color: "#A6A6A6",
    external_container_db_bg_color: "#B3B3B3",
    external_container_db_border_color: "#A6A6A6",
    external_container_queue_bg_color: "#B3B3B3",
    external_container_queue_border_color: "#A6A6A6",
    component_bg_color: "#85BBF0",
    component_border_color: "#78A8D8",
    component_db_bg_color: "#85BBF0",
    component_db_border_color: "#78A8D8",
    component_queue_bg_color: "#85BBF0",
    component_queue_border_color: "#78A8D8",
    external_component_bg_color: "#CCCCCC",
    external_component_border_color: "#BFBFBF",
    external_component_db_bg_color: "#CCCCCC",
    external_component_db_border_color: "#BFBFBF",
    external_component_queue_bg_color: "#CCCCCC",
    external_component_queue_border_color: "#BFBFBF"
  },
  sankey: {
    useMaxWidth: !0,
    width: 600,
    height: 400,
    linkColor: "gradient",
    nodeAlignment: "justify",
    showValues: !0,
    prefix: "",
    suffix: ""
  },
  block: {
    useMaxWidth: !0,
    padding: 8
  },
  packet: {
    useMaxWidth: !0,
    rowHeight: 32,
    bitWidth: 32,
    bitsPerRow: 32,
    showBits: !0,
    paddingX: 5,
    paddingY: 5
  },
  treeView: {
    useMaxWidth: !0,
    rowIndent: 10,
    paddingX: 5,
    paddingY: 5,
    lineThickness: 1
  },
  architecture: {
    useMaxWidth: !0,
    padding: 40,
    iconSize: 80,
    fontSize: 16,
    randomize: !1
  },
  radar: {
    useMaxWidth: !0,
    width: 600,
    height: 600,
    marginTop: 50,
    marginRight: 50,
    marginBottom: 50,
    marginLeft: 50,
    axisScaleFactor: 1,
    axisLabelFactor: 1.05,
    curveTension: 0.17
  },
  venn: {
    useMaxWidth: !0,
    width: 800,
    height: 450,
    padding: 8,
    useDebugLayout: !1
  },
  theme: "default",
  look: "classic",
  handDrawnSeed: 0,
  layout: "dagre",
  maxTextSize: 5e4,
  maxEdges: 500,
  darkMode: !1,
  fontFamily: '"trebuchet ms", verdana, arial, sans-serif;',
  logLevel: 5,
  securityLevel: "strict",
  startOnLoad: !0,
  arrowMarkerAbsolute: !1,
  secure: [
    "secure",
    "securityLevel",
    "startOnLoad",
    "maxTextSize",
    "suppressErrorRendering",
    "maxEdges"
  ],
  legacyMathML: !1,
  forceLegacyMathML: !1,
  deterministicIds: !1,
  fontSize: 16,
  markdownAutoWrap: !0,
  suppressErrorRendering: !1
}, Qc = {
  ...ie,
  // Set, even though they're `undefined` so that `configKeys` finds these keys
  // TODO: Should we replace these with `null` so that they can go in the JSON Schema?
  deterministicIDSeed: void 0,
  elk: {
    // mergeEdges is needed here to be considered
    mergeEdges: !1,
    nodePlacementStrategy: "BRANDES_KOEPF",
    forceNodeModelOrder: !1,
    considerModelOrder: "NODES_AND_EDGES"
  },
  themeCSS: void 0,
  // add non-JSON default config values
  themeVariables: qe.default.getThemeVariables(),
  sequence: {
    ...ie.sequence,
    messageFont: /* @__PURE__ */ f(function() {
      return {
        fontFamily: this.messageFontFamily,
        fontSize: this.messageFontSize,
        fontWeight: this.messageFontWeight
      };
    }, "messageFont"),
    noteFont: /* @__PURE__ */ f(function() {
      return {
        fontFamily: this.noteFontFamily,
        fontSize: this.noteFontSize,
        fontWeight: this.noteFontWeight
      };
    }, "noteFont"),
    actorFont: /* @__PURE__ */ f(function() {
      return {
        fontFamily: this.actorFontFamily,
        fontSize: this.actorFontSize,
        fontWeight: this.actorFontWeight
      };
    }, "actorFont")
  },
  class: {
    hideEmptyMembersBox: !1
  },
  gantt: {
    ...ie.gantt,
    tickInterval: void 0,
    useWidth: void 0
    // can probably be removed since `configKeys` already includes this
  },
  c4: {
    ...ie.c4,
    useWidth: void 0,
    personFont: /* @__PURE__ */ f(function() {
      return {
        fontFamily: this.personFontFamily,
        fontSize: this.personFontSize,
        fontWeight: this.personFontWeight
      };
    }, "personFont"),
    flowchart: {
      ...ie.flowchart,
      inheritDir: !1
      // default to legacy behavior
    },
    external_personFont: /* @__PURE__ */ f(function() {
      return {
        fontFamily: this.external_personFontFamily,
        fontSize: this.external_personFontSize,
        fontWeight: this.external_personFontWeight
      };
    }, "external_personFont"),
    systemFont: /* @__PURE__ */ f(function() {
      return {
        fontFamily: this.systemFontFamily,
        fontSize: this.systemFontSize,
        fontWeight: this.systemFontWeight
      };
    }, "systemFont"),
    external_systemFont: /* @__PURE__ */ f(function() {
      return {
        fontFamily: this.external_systemFontFamily,
        fontSize: this.external_systemFontSize,
        fontWeight: this.external_systemFontWeight
      };
    }, "external_systemFont"),
    system_dbFont: /* @__PURE__ */ f(function() {
      return {
        fontFamily: this.system_dbFontFamily,
        fontSize: this.system_dbFontSize,
        fontWeight: this.system_dbFontWeight
      };
    }, "system_dbFont"),
    external_system_dbFont: /* @__PURE__ */ f(function() {
      return {
        fontFamily: this.external_system_dbFontFamily,
        fontSize: this.external_system_dbFontSize,
        fontWeight: this.external_system_dbFontWeight
      };
    }, "external_system_dbFont"),
    system_queueFont: /* @__PURE__ */ f(function() {
      return {
        fontFamily: this.system_queueFontFamily,
        fontSize: this.system_queueFontSize,
        fontWeight: this.system_queueFontWeight
      };
    }, "system_queueFont"),
    external_system_queueFont: /* @__PURE__ */ f(function() {
      return {
        fontFamily: this.external_system_queueFontFamily,
        fontSize: this.external_system_queueFontSize,
        fontWeight: this.external_system_queueFontWeight
      };
    }, "external_system_queueFont"),
    containerFont: /* @__PURE__ */ f(function() {
      return {
        fontFamily: this.containerFontFamily,
        fontSize: this.containerFontSize,
        fontWeight: this.containerFontWeight
      };
    }, "containerFont"),
    external_containerFont: /* @__PURE__ */ f(function() {
      return {
        fontFamily: this.external_containerFontFamily,
        fontSize: this.external_containerFontSize,
        fontWeight: this.external_containerFontWeight
      };
    }, "external_containerFont"),
    container_dbFont: /* @__PURE__ */ f(function() {
      return {
        fontFamily: this.container_dbFontFamily,
        fontSize: this.container_dbFontSize,
        fontWeight: this.container_dbFontWeight
      };
    }, "container_dbFont"),
    external_container_dbFont: /* @__PURE__ */ f(function() {
      return {
        fontFamily: this.external_container_dbFontFamily,
        fontSize: this.external_container_dbFontSize,
        fontWeight: this.external_container_dbFontWeight
      };
    }, "external_container_dbFont"),
    container_queueFont: /* @__PURE__ */ f(function() {
      return {
        fontFamily: this.container_queueFontFamily,
        fontSize: this.container_queueFontSize,
        fontWeight: this.container_queueFontWeight
      };
    }, "container_queueFont"),
    external_container_queueFont: /* @__PURE__ */ f(function() {
      return {
        fontFamily: this.external_container_queueFontFamily,
        fontSize: this.external_container_queueFontSize,
        fontWeight: this.external_container_queueFontWeight
      };
    }, "external_container_queueFont"),
    componentFont: /* @__PURE__ */ f(function() {
      return {
        fontFamily: this.componentFontFamily,
        fontSize: this.componentFontSize,
        fontWeight: this.componentFontWeight
      };
    }, "componentFont"),
    external_componentFont: /* @__PURE__ */ f(function() {
      return {
        fontFamily: this.external_componentFontFamily,
        fontSize: this.external_componentFontSize,
        fontWeight: this.external_componentFontWeight
      };
    }, "external_componentFont"),
    component_dbFont: /* @__PURE__ */ f(function() {
      return {
        fontFamily: this.component_dbFontFamily,
        fontSize: this.component_dbFontSize,
        fontWeight: this.component_dbFontWeight
      };
    }, "component_dbFont"),
    external_component_dbFont: /* @__PURE__ */ f(function() {
      return {
        fontFamily: this.external_component_dbFontFamily,
        fontSize: this.external_component_dbFontSize,
        fontWeight: this.external_component_dbFontWeight
      };
    }, "external_component_dbFont"),
    component_queueFont: /* @__PURE__ */ f(function() {
      return {
        fontFamily: this.component_queueFontFamily,
        fontSize: this.component_queueFontSize,
        fontWeight: this.component_queueFontWeight
      };
    }, "component_queueFont"),
    external_component_queueFont: /* @__PURE__ */ f(function() {
      return {
        fontFamily: this.external_component_queueFontFamily,
        fontSize: this.external_component_queueFontSize,
        fontWeight: this.external_component_queueFontWeight
      };
    }, "external_component_queueFont"),
    boundaryFont: /* @__PURE__ */ f(function() {
      return {
        fontFamily: this.boundaryFontFamily,
        fontSize: this.boundaryFontSize,
        fontWeight: this.boundaryFontWeight
      };
    }, "boundaryFont"),
    messageFont: /* @__PURE__ */ f(function() {
      return {
        fontFamily: this.messageFontFamily,
        fontSize: this.messageFontSize,
        fontWeight: this.messageFontWeight
      };
    }, "messageFont")
  },
  pie: {
    ...ie.pie,
    useWidth: 984
  },
  xyChart: {
    ...ie.xyChart,
    useWidth: void 0
  },
  requirement: {
    ...ie.requirement,
    useWidth: void 0
  },
  packet: {
    ...ie.packet
  },
  treeView: {
    ...ie.treeView,
    useWidth: void 0
  },
  radar: {
    ...ie.radar
  },
  ishikawa: {
    ...ie.ishikawa
  },
  treemap: {
    useMaxWidth: !0,
    padding: 10,
    diagramPadding: 8,
    showValues: !0,
    nodeWidth: 100,
    nodeHeight: 40,
    borderWidth: 1,
    valueFontSize: 12,
    labelFontSize: 14,
    valueFormat: ","
  },
  venn: {
    ...ie.venn
  }
}, Jc = /* @__PURE__ */ f((e, t = "") => Object.keys(e).reduce((r, i) => Array.isArray(e[i]) ? r : typeof e[i] == "object" && e[i] !== null ? [...r, t + i, ...Jc(e[i], "")] : [...r, t + i], []), "keyify"), F0 = new Set(Jc(Qc, "")), tu = Qc, Ps = /* @__PURE__ */ f((e) => {
  if (R.debug("sanitizeDirective called with", e), !(typeof e != "object" || e == null)) {
    if (Array.isArray(e)) {
      e.forEach((t) => Ps(t));
      return;
    }
    for (const t of Object.keys(e)) {
      if (R.debug("Checking key", t), t.startsWith("__") || t.includes("proto") || t.includes("constr") || !F0.has(t) || e[t] == null) {
        R.debug("sanitize deleting key: ", t), delete e[t];
        continue;
      }
      if (typeof e[t] == "object") {
        R.debug("sanitizing object", t), Ps(e[t]);
        continue;
      }
      const r = ["themeCSS", "fontFamily", "altFontFamily"];
      for (const i of r)
        t.includes(i) && (R.debug("sanitizing css option", t), e[t] = A0(e[t]));
    }
    if (e.themeVariables)
      for (const t of Object.keys(e.themeVariables)) {
        const r = e.themeVariables[t];
        r?.match && !r.match(/^[\d "#%(),.;A-Za-z]+$/) && (e.themeVariables[t] = "");
      }
    R.debug("After sanitization", e);
  }
}, "sanitizeDirective"), A0 = /* @__PURE__ */ f((e) => {
  let t = 0, r = 0;
  for (const i of e) {
    if (t < r)
      return "{ /* ERROR: Unbalanced CSS */ }";
    i === "{" ? t++ : i === "}" && r++;
  }
  return t !== r ? "{ /* ERROR: Unbalanced CSS */ }" : e;
}, "sanitizeCss"), Vr = Object.freeze(tu), je = /* @__PURE__ */ f((e) => !(e === !1 || ["false", "null", "0"].includes(String(e).trim().toLowerCase())), "evaluate"), Jt = $t({}, Vr), Rs, br = [], Ei = $t({}, Vr), bo = /* @__PURE__ */ f((e, t) => {
  let r = $t({}, e), i = {};
  for (const s of t)
    iu(s), i = $t(i, s);
  if (r = $t(r, i), i.theme && i.theme in qe) {
    const s = $t({}, Rs), o = $t(
      s.themeVariables || {},
      i.themeVariables
    );
    r.theme && r.theme in qe && (r.themeVariables = qe[r.theme].getThemeVariables(o));
  }
  return Ei = r, ou(Ei), Ei;
}, "updateCurrentConfig"), M0 = /* @__PURE__ */ f((e) => (Jt = $t({}, Vr), Jt = $t(Jt, e), e.theme && qe[e.theme] && (Jt.themeVariables = qe[e.theme].getThemeVariables(e.themeVariables)), bo(Jt, br), Jt), "setSiteConfig"), E0 = /* @__PURE__ */ f((e) => {
  Rs = $t({}, e);
}, "saveConfigFromInitialize"), $0 = /* @__PURE__ */ f((e) => (Jt = $t(Jt, e), bo(Jt, br), Jt), "updateSiteConfig"), eu = /* @__PURE__ */ f(() => $t({}, Jt), "getSiteConfig"), ru = /* @__PURE__ */ f((e) => (ou(e), $t(Ei, e), wt()), "setConfig"), wt = /* @__PURE__ */ f(() => $t({}, Ei), "getConfig"), iu = /* @__PURE__ */ f((e) => {
  e && (["secure", ...Jt.secure ?? []].forEach((t) => {
    Object.hasOwn(e, t) && (R.debug(`Denied attempt to modify a secure key ${t}`, e[t]), delete e[t]);
  }), Object.keys(e).forEach((t) => {
    t.startsWith("__") && delete e[t];
  }), Object.keys(e).forEach((t) => {
    typeof e[t] == "string" && (e[t].includes("<") || e[t].includes(">") || e[t].includes("url(data:")) && delete e[t], typeof e[t] == "object" && iu(e[t]);
  }));
}, "sanitize"), O0 = /* @__PURE__ */ f((e) => {
  Ps(e), e.fontFamily && !e.themeVariables?.fontFamily && (e.themeVariables = {
    ...e.themeVariables,
    fontFamily: e.fontFamily
  }), br.push(e), bo(Jt, br);
}, "addDirective"), Ns = /* @__PURE__ */ f((e = Jt) => {
  br = [], bo(e, br);
}, "reset"), I0 = {
  LAZY_LOAD_DEPRECATED: "The configuration options lazyLoadedDiagrams and loadExternalDiagramsAtStartup are deprecated. Please use registerExternalDiagrams instead.",
  FLOWCHART_HTML_LABELS_DEPRECATED: "flowchart.htmlLabels is deprecated. Please use global htmlLabels instead."
}, sh = {}, su = /* @__PURE__ */ f((e) => {
  sh[e] || (R.warn(I0[e]), sh[e] = !0);
}, "issueWarning"), ou = /* @__PURE__ */ f((e) => {
  e && (e.lazyLoadedDiagrams || e.loadExternalDiagramsAtStartup) && su("LAZY_LOAD_DEPRECATED");
}, "checkConfig"), iA = /* @__PURE__ */ f(() => {
  let e = {};
  Rs && (e = $t(e, Rs));
  for (const t of br)
    e = $t(e, t);
  return e;
}, "getUserDefinedConfig"), Vt = /* @__PURE__ */ f((e) => (e.flowchart?.htmlLabels != null && su("FLOWCHART_HTML_LABELS_DEPRECATED"), je(e.htmlLabels ?? e.flowchart?.htmlLabels ?? !0)), "getEffectiveHtmlLabels"), Ki = /<br\s*\/?>/gi, D0 = /* @__PURE__ */ f((e) => e ? lu(e).replace(/\\n/g, "#br#").split("#br#") : [""], "getRows"), P0 = /* @__PURE__ */ (() => {
  let e = !1;
  return () => {
    e || (au(), e = !0);
  };
})();
function au() {
  const e = "data-temp-href-target";
  Xr.addHook("beforeSanitizeAttributes", (t) => {
    t.tagName === "A" && t.hasAttribute("target") && t.setAttribute(e, t.getAttribute("target") ?? "");
  }), Xr.addHook("afterSanitizeAttributes", (t) => {
    t.tagName === "A" && t.hasAttribute(e) && (t.setAttribute("target", t.getAttribute(e) ?? ""), t.removeAttribute(e), t.getAttribute("target") === "_blank" && t.setAttribute("rel", "noopener"));
  });
}
f(au, "setupDompurifyHooks");
var nu = /* @__PURE__ */ f((e) => (P0(), Xr.sanitize(e)), "removeScript"), oh = /* @__PURE__ */ f((e, t) => {
  if (Vt(t)) {
    const r = t.securityLevel;
    r === "antiscript" || r === "strict" || r === "sandbox" ? e = nu(e) : r !== "loose" && (e = lu(e), e = e.replace(/</g, "&lt;").replace(/>/g, "&gt;"), e = e.replace(/=/g, "&equals;"), e = z0(e));
  }
  return e;
}, "sanitizeMore"), xe = /* @__PURE__ */ f((e, t) => e && (t.dompurifyConfig ? e = Xr.sanitize(oh(e, t), t.dompurifyConfig).toString() : e = Xr.sanitize(oh(e, t), {
  FORBID_TAGS: ["style"]
}).toString(), e), "sanitizeText"), R0 = /* @__PURE__ */ f((e, t) => typeof e == "string" ? xe(e, t) : e.flat().map((r) => xe(r, t)), "sanitizeTextOrArray"), N0 = /* @__PURE__ */ f((e) => Ki.test(e), "hasBreaks"), q0 = /* @__PURE__ */ f((e) => e.split(Ki), "splitBreaks"), z0 = /* @__PURE__ */ f((e) => e.replace(/#br#/g, "<br/>"), "placeholderToBreak"), lu = /* @__PURE__ */ f((e) => e.replace(Ki, "#br#"), "breakToPlaceholder"), W0 = /* @__PURE__ */ f((e) => {
  let t = "";
  return e && (t = window.location.protocol + "//" + window.location.host + window.location.pathname + window.location.search, t = CSS.escape(t)), t;
}, "getUrl"), H0 = /* @__PURE__ */ f(function(...e) {
  const t = e.filter((r) => !isNaN(r));
  return Math.max(...t);
}, "getMax"), Y0 = /* @__PURE__ */ f(function(...e) {
  const t = e.filter((r) => !isNaN(r));
  return Math.min(...t);
}, "getMin"), ah = /* @__PURE__ */ f(function(e) {
  const t = e.split(/(,)/), r = [];
  for (let i = 0; i < t.length; i++) {
    let s = t[i];
    if (s === "," && i > 0 && i + 1 < t.length) {
      const o = t[i - 1], a = t[i + 1];
      j0(o, a) && (s = o + "," + a, i++, r.pop());
    }
    r.push(U0(s));
  }
  return r.join("");
}, "parseGenericTypes"), Ba = /* @__PURE__ */ f((e, t) => Math.max(0, e.split(t).length - 1), "countOccurrence"), j0 = /* @__PURE__ */ f((e, t) => {
  const r = Ba(e, "~"), i = Ba(t, "~");
  return r === 1 && i === 1;
}, "shouldCombineSets"), U0 = /* @__PURE__ */ f((e) => {
  const t = Ba(e, "~");
  let r = !1;
  if (t <= 1)
    return e;
  t % 2 !== 0 && e.startsWith("~") && (e = e.substring(1), r = !0);
  const i = [...e];
  let s = i.indexOf("~"), o = i.lastIndexOf("~");
  for (; s !== -1 && o !== -1 && s !== o; )
    i[s] = "<", i[o] = ">", s = i.indexOf("~"), o = i.lastIndexOf("~");
  return r && i.unshift("~"), i.join("");
}, "processSet"), nh = /* @__PURE__ */ f(() => window.MathMLElement !== void 0, "isMathMLSupported"), La = /\$\$(.*)\$\$/g, Pi = /* @__PURE__ */ f((e) => (e.match(La)?.length ?? 0) > 0, "hasKatex"), sA = /* @__PURE__ */ f(async (e, t) => {
  const r = document.createElement("div");
  r.innerHTML = await hu(e, t), r.id = "katex-temp", r.style.visibility = "hidden", r.style.position = "absolute", r.style.top = "0", document.querySelector("body")?.insertAdjacentElement("beforeend", r);
  const s = { width: r.clientWidth, height: r.clientHeight };
  return r.remove(), s;
}, "calculateMathMLDimensions"), G0 = /* @__PURE__ */ f(async (e, t) => {
  if (!Pi(e))
    return e;
  if (!(nh() || t.legacyMathML || t.forceLegacyMathML))
    return e.replace(La, "MathML is unsupported in this environment.");
  {
    const { default: r } = await import("./katex-D3uLT2GX.js"), i = t.forceLegacyMathML || !nh() && t.legacyMathML ? "htmlAndMathml" : "mathml";
    return e.split(Ki).map(
      (s) => Pi(s) ? `<div style="display: flex; align-items: center; justify-content: center; white-space: nowrap;">${s}</div>` : `<div>${s}</div>`
    ).join("").replace(
      La,
      (s, o) => r.renderToString(o, {
        throwOnError: !0,
        displayMode: !0,
        output: i
      }).replace(/\n/g, " ").replace(/<annotation.*<\/annotation>/g, "")
    );
  }
}, "renderKatexUnsanitized"), hu = /* @__PURE__ */ f(async (e, t) => xe(await G0(e, t), t), "renderKatexSanitized"), Qi = {
  getRows: D0,
  sanitizeText: xe,
  sanitizeTextOrArray: R0,
  hasBreaks: N0,
  splitBreaks: q0,
  lineBreakRegex: Ki,
  removeScript: nu,
  getUrl: W0,
  evaluate: je,
  getMax: H0,
  getMin: Y0
}, X0 = /* @__PURE__ */ f(function(e, t) {
  for (let r of t)
    e.attr(r[0], r[1]);
}, "d3Attrs"), V0 = /* @__PURE__ */ f(function(e, t, r) {
  let i = /* @__PURE__ */ new Map();
  return r ? (i.set("width", "100%"), i.set("style", `max-width: ${t}px;`)) : (i.set("height", e), i.set("width", t)), i;
}, "calculateSvgSizeAttrs"), cu = /* @__PURE__ */ f(function(e, t, r, i) {
  const s = V0(t, r, i);
  X0(e, s);
}, "configureSvgSize"), Z0 = /* @__PURE__ */ f(function(e, t, r, i) {
  const s = t.node().getBBox(), o = s.width, a = s.height;
  R.info(`SVG bounds: ${o}x${a}`, s);
  let n = 0, l = 0;
  R.info(`Graph bounds: ${n}x${l}`, e), n = o + r * 2, l = a + r * 2, R.info(`Calculated bounds: ${n}x${l}`), cu(t, l, n, i);
  const c = `${s.x - r} ${s.y - r} ${s.width + 2 * r} ${s.height + 2 * r}`;
  t.attr("viewBox", c);
}, "setupGraphViewbox"), Bs = {}, K0 = /* @__PURE__ */ f((e, t, r, i) => {
  let s = "";
  return e in Bs && Bs[e] ? s = Bs[e]({ ...r, svgId: i }) : R.warn(`No theme found for ${e}`), ` & {
    font-family: ${r.fontFamily};
    font-size: ${r.fontSize};
    fill: ${r.textColor}
  }
  @keyframes edge-animation-frame {
    from {
      stroke-dashoffset: 0;
    }
  }
  @keyframes dash {
    to {
      stroke-dashoffset: 0;
    }
  }
  & .edge-animation-slow {
    stroke-dasharray: 9,5 !important;
    stroke-dashoffset: 900;
    animation: dash 50s linear infinite;
    stroke-linecap: round;
  }
  & .edge-animation-fast {
    stroke-dasharray: 9,5 !important;
    stroke-dashoffset: 900;
    animation: dash 20s linear infinite;
    stroke-linecap: round;
  }
  /* Classes common for multiple diagrams */

  & .error-icon {
    fill: ${r.errorBkgColor};
  }
  & .error-text {
    fill: ${r.errorTextColor};
    stroke: ${r.errorTextColor};
  }

  & .edge-thickness-normal {
    stroke-width: ${r.strokeWidth ?? 1}px;
  }
  & .edge-thickness-thick {
    stroke-width: 3.5px
  }
  & .edge-pattern-solid {
    stroke-dasharray: 0;
  }
  & .edge-thickness-invisible {
    stroke-width: 0;
    fill: none;
  }
  & .edge-pattern-dashed{
    stroke-dasharray: 3;
  }
  .edge-pattern-dotted {
    stroke-dasharray: 2;
  }

  & .marker {
    fill: ${r.lineColor};
    stroke: ${r.lineColor};
  }
  & .marker.cross {
    stroke: ${r.lineColor};
  }

  & svg {
    font-family: ${r.fontFamily};
    font-size: ${r.fontSize};
  }
   & p {
    margin: 0
   }

  ${s}
  .node .neo-node {
    stroke: ${r.nodeBorder};
  }

  [data-look="neo"].node rect, [data-look="neo"].cluster rect, [data-look="neo"].node polygon {
    stroke: ${r.useGradient ? "url(" + i + "-gradient)" : r.nodeBorder};
    filter: ${r.dropShadow ? r.dropShadow.replace("url(#drop-shadow)", `url(${i}-drop-shadow)`) : "none"};
  }


  [data-look="neo"].node path {
    stroke: ${r.useGradient ? "url(" + i + "-gradient)" : r.nodeBorder};
    stroke-width: ${r.strokeWidth ?? 1}px;
  }

  [data-look="neo"].node .outer-path {
    filter: ${r.dropShadow ? r.dropShadow.replace("url(#drop-shadow)", `url(${i}-drop-shadow)`) : "none"};
  }

  [data-look="neo"].node .neo-line path {
    stroke: ${r.nodeBorder};
    filter: none;
  }

  [data-look="neo"].node circle{
    stroke: ${r.useGradient ? "url(" + i + "-gradient)" : r.nodeBorder};
    filter: ${r.dropShadow ? r.dropShadow.replace("url(#drop-shadow)", `url(${i}-drop-shadow)`) : "none"};
  }

  [data-look="neo"].node circle .state-start{
    fill: #000000;
  }

  [data-look="neo"].icon-shape .icon {
    fill: ${r.useGradient ? "url(" + i + "-gradient)" : r.nodeBorder};
    filter: ${r.dropShadow ? r.dropShadow.replace("url(#drop-shadow)", `url(${i}-drop-shadow)`) : "none"};
  }

    [data-look="neo"].icon-shape .icon-neo path {
    stroke: ${r.useGradient ? "url(" + i + "-gradient)" : r.nodeBorder};
    filter: ${r.dropShadow ? r.dropShadow.replace("url(#drop-shadow)", `url(${i}-drop-shadow)`) : "none"};
  }

  ${t}
`;
}, "getStyles"), Q0 = /* @__PURE__ */ f((e, t) => {
  t !== void 0 && (Bs[e] = t);
}, "addStylesForDiagram"), J0 = K0, uu = {};
By(uu, {
  clear: () => tC,
  getAccDescription: () => sC,
  getAccTitle: () => rC,
  getDiagramTitle: () => aC,
  setAccDescription: () => iC,
  setAccTitle: () => eC,
  setDiagramTitle: () => oC
});
var Ln = "", Fn = "", An = "", Mn = /* @__PURE__ */ f((e) => xe(e, wt()), "sanitizeText"), tC = /* @__PURE__ */ f(() => {
  Ln = "", An = "", Fn = "";
}, "clear"), eC = /* @__PURE__ */ f((e) => {
  Ln = Mn(e).replace(/^\s+/g, "");
}, "setAccTitle"), rC = /* @__PURE__ */ f(() => Ln, "getAccTitle"), iC = /* @__PURE__ */ f((e) => {
  An = Mn(e).replace(/\n\s+/g, `
`);
}, "setAccDescription"), sC = /* @__PURE__ */ f(() => An, "getAccDescription"), oC = /* @__PURE__ */ f((e) => {
  Fn = Mn(e);
}, "setDiagramTitle"), aC = /* @__PURE__ */ f(() => Fn, "getDiagramTitle"), lh = R, nC = vn, gt = wt, oA = ru, aA = Vr, En = /* @__PURE__ */ f((e) => xe(e, gt()), "sanitizeText"), lC = Z0, hC = /* @__PURE__ */ f(() => uu, "getCommonDb"), qs = {}, zs = /* @__PURE__ */ f((e, t, r) => {
  qs[e] && lh.warn(`Diagram with id ${e} already registered. Overwriting.`), qs[e] = t, r && Kc(e, r), Q0(e, t.styles), t.injectUtils?.(
    lh,
    nC,
    gt,
    En,
    lC,
    hC(),
    () => {
    }
  );
}, "registerDiagram"), Fa = /* @__PURE__ */ f((e) => {
  if (e in qs)
    return qs[e];
  throw new cC(e);
}, "getDiagram"), cC = class extends Error {
  static {
    f(this, "DiagramNotFoundError");
  }
  constructor(e) {
    super(`Diagram ${e} not found.`);
  }
}, uC = { value: () => {
} };
function du() {
  for (var e = 0, t = arguments.length, r = {}, i; e < t; ++e) {
    if (!(i = arguments[e] + "") || i in r || /[\s.]/.test(i)) throw new Error("illegal type: " + i);
    r[i] = [];
  }
  return new Ls(r);
}
function Ls(e) {
  this._ = e;
}
function dC(e, t) {
  return e.trim().split(/^|\s+/).map(function(r) {
    var i = "", s = r.indexOf(".");
    if (s >= 0 && (i = r.slice(s + 1), r = r.slice(0, s)), r && !t.hasOwnProperty(r)) throw new Error("unknown type: " + r);
    return { type: r, name: i };
  });
}
Ls.prototype = du.prototype = {
  constructor: Ls,
  on: function(e, t) {
    var r = this._, i = dC(e + "", r), s, o = -1, a = i.length;
    if (arguments.length < 2) {
      for (; ++o < a; ) if ((s = (e = i[o]).type) && (s = pC(r[s], e.name))) return s;
      return;
    }
    if (t != null && typeof t != "function") throw new Error("invalid callback: " + t);
    for (; ++o < a; )
      if (s = (e = i[o]).type) r[s] = hh(r[s], e.name, t);
      else if (t == null) for (s in r) r[s] = hh(r[s], e.name, null);
    return this;
  },
  copy: function() {
    var e = {}, t = this._;
    for (var r in t) e[r] = t[r].slice();
    return new Ls(e);
  },
  call: function(e, t) {
    if ((s = arguments.length - 2) > 0) for (var r = new Array(s), i = 0, s, o; i < s; ++i) r[i] = arguments[i + 2];
    if (!this._.hasOwnProperty(e)) throw new Error("unknown type: " + e);
    for (o = this._[e], i = 0, s = o.length; i < s; ++i) o[i].value.apply(t, r);
  },
  apply: function(e, t, r) {
    if (!this._.hasOwnProperty(e)) throw new Error("unknown type: " + e);
    for (var i = this._[e], s = 0, o = i.length; s < o; ++s) i[s].value.apply(t, r);
  }
};
function pC(e, t) {
  for (var r = 0, i = e.length, s; r < i; ++r)
    if ((s = e[r]).name === t)
      return s.value;
}
function hh(e, t, r) {
  for (var i = 0, s = e.length; i < s; ++i)
    if (e[i].name === t) {
      e[i] = uC, e = e.slice(0, i).concat(e.slice(i + 1));
      break;
    }
  return r != null && e.push({ name: t, value: r }), e;
}
var Aa = "http://www.w3.org/1999/xhtml";
const ch = {
  svg: "http://www.w3.org/2000/svg",
  xhtml: Aa,
  xlink: "http://www.w3.org/1999/xlink",
  xml: "http://www.w3.org/XML/1998/namespace",
  xmlns: "http://www.w3.org/2000/xmlns/"
};
function ko(e) {
  var t = e += "", r = t.indexOf(":");
  return r >= 0 && (t = e.slice(0, r)) !== "xmlns" && (e = e.slice(r + 1)), ch.hasOwnProperty(t) ? { space: ch[t], local: e } : e;
}
function fC(e) {
  return function() {
    var t = this.ownerDocument, r = this.namespaceURI;
    return r === Aa && t.documentElement.namespaceURI === Aa ? t.createElement(e) : t.createElementNS(r, e);
  };
}
function gC(e) {
  return function() {
    return this.ownerDocument.createElementNS(e.space, e.local);
  };
}
function pu(e) {
  var t = ko(e);
  return (t.local ? gC : fC)(t);
}
function mC() {
}
function $n(e) {
  return e == null ? mC : function() {
    return this.querySelector(e);
  };
}
function yC(e) {
  typeof e != "function" && (e = $n(e));
  for (var t = this._groups, r = t.length, i = new Array(r), s = 0; s < r; ++s)
    for (var o = t[s], a = o.length, n = i[s] = new Array(a), l, c, h = 0; h < a; ++h)
      (l = o[h]) && (c = e.call(l, l.__data__, h, o)) && ("__data__" in l && (c.__data__ = l.__data__), n[h] = c);
  return new oe(i, this._parents);
}
function CC(e) {
  return e == null ? [] : Array.isArray(e) ? e : Array.from(e);
}
function xC() {
  return [];
}
function fu(e) {
  return e == null ? xC : function() {
    return this.querySelectorAll(e);
  };
}
function bC(e) {
  return function() {
    return CC(e.apply(this, arguments));
  };
}
function kC(e) {
  typeof e == "function" ? e = bC(e) : e = fu(e);
  for (var t = this._groups, r = t.length, i = [], s = [], o = 0; o < r; ++o)
    for (var a = t[o], n = a.length, l, c = 0; c < n; ++c)
      (l = a[c]) && (i.push(e.call(l, l.__data__, c, a)), s.push(l));
  return new oe(i, s);
}
function gu(e) {
  return function() {
    return this.matches(e);
  };
}
function mu(e) {
  return function(t) {
    return t.matches(e);
  };
}
var TC = Array.prototype.find;
function wC(e) {
  return function() {
    return TC.call(this.children, e);
  };
}
function SC() {
  return this.firstElementChild;
}
function _C(e) {
  return this.select(e == null ? SC : wC(typeof e == "function" ? e : mu(e)));
}
var vC = Array.prototype.filter;
function BC() {
  return Array.from(this.children);
}
function LC(e) {
  return function() {
    return vC.call(this.children, e);
  };
}
function FC(e) {
  return this.selectAll(e == null ? BC : LC(typeof e == "function" ? e : mu(e)));
}
function AC(e) {
  typeof e != "function" && (e = gu(e));
  for (var t = this._groups, r = t.length, i = new Array(r), s = 0; s < r; ++s)
    for (var o = t[s], a = o.length, n = i[s] = [], l, c = 0; c < a; ++c)
      (l = o[c]) && e.call(l, l.__data__, c, o) && n.push(l);
  return new oe(i, this._parents);
}
function yu(e) {
  return new Array(e.length);
}
function MC() {
  return new oe(this._enter || this._groups.map(yu), this._parents);
}
function Ws(e, t) {
  this.ownerDocument = e.ownerDocument, this.namespaceURI = e.namespaceURI, this._next = null, this._parent = e, this.__data__ = t;
}
Ws.prototype = {
  constructor: Ws,
  appendChild: function(e) {
    return this._parent.insertBefore(e, this._next);
  },
  insertBefore: function(e, t) {
    return this._parent.insertBefore(e, t);
  },
  querySelector: function(e) {
    return this._parent.querySelector(e);
  },
  querySelectorAll: function(e) {
    return this._parent.querySelectorAll(e);
  }
};
function EC(e) {
  return function() {
    return e;
  };
}
function $C(e, t, r, i, s, o) {
  for (var a = 0, n, l = t.length, c = o.length; a < c; ++a)
    (n = t[a]) ? (n.__data__ = o[a], i[a] = n) : r[a] = new Ws(e, o[a]);
  for (; a < l; ++a)
    (n = t[a]) && (s[a] = n);
}
function OC(e, t, r, i, s, o, a) {
  var n, l, c = /* @__PURE__ */ new Map(), h = t.length, u = o.length, p = new Array(h), d;
  for (n = 0; n < h; ++n)
    (l = t[n]) && (p[n] = d = a.call(l, l.__data__, n, t) + "", c.has(d) ? s[n] = l : c.set(d, l));
  for (n = 0; n < u; ++n)
    d = a.call(e, o[n], n, o) + "", (l = c.get(d)) ? (i[n] = l, l.__data__ = o[n], c.delete(d)) : r[n] = new Ws(e, o[n]);
  for (n = 0; n < h; ++n)
    (l = t[n]) && c.get(p[n]) === l && (s[n] = l);
}
function IC(e) {
  return e.__data__;
}
function DC(e, t) {
  if (!arguments.length) return Array.from(this, IC);
  var r = t ? OC : $C, i = this._parents, s = this._groups;
  typeof e != "function" && (e = EC(e));
  for (var o = s.length, a = new Array(o), n = new Array(o), l = new Array(o), c = 0; c < o; ++c) {
    var h = i[c], u = s[c], p = u.length, d = PC(e.call(h, h && h.__data__, c, i)), g = d.length, m = n[c] = new Array(g), y = a[c] = new Array(g), x = l[c] = new Array(p);
    r(h, u, m, y, x, d, t);
    for (var b = 0, k = 0, w, S; b < g; ++b)
      if (w = m[b]) {
        for (b >= k && (k = b + 1); !(S = y[k]) && ++k < g; ) ;
        w._next = S || null;
      }
  }
  return a = new oe(a, i), a._enter = n, a._exit = l, a;
}
function PC(e) {
  return typeof e == "object" && "length" in e ? e : Array.from(e);
}
function RC() {
  return new oe(this._exit || this._groups.map(yu), this._parents);
}
function NC(e, t, r) {
  var i = this.enter(), s = this, o = this.exit();
  return typeof e == "function" ? (i = e(i), i && (i = i.selection())) : i = i.append(e + ""), t != null && (s = t(s), s && (s = s.selection())), r == null ? o.remove() : r(o), i && s ? i.merge(s).order() : s;
}
function qC(e) {
  for (var t = e.selection ? e.selection() : e, r = this._groups, i = t._groups, s = r.length, o = i.length, a = Math.min(s, o), n = new Array(s), l = 0; l < a; ++l)
    for (var c = r[l], h = i[l], u = c.length, p = n[l] = new Array(u), d, g = 0; g < u; ++g)
      (d = c[g] || h[g]) && (p[g] = d);
  for (; l < s; ++l)
    n[l] = r[l];
  return new oe(n, this._parents);
}
function zC() {
  for (var e = this._groups, t = -1, r = e.length; ++t < r; )
    for (var i = e[t], s = i.length - 1, o = i[s], a; --s >= 0; )
      (a = i[s]) && (o && a.compareDocumentPosition(o) ^ 4 && o.parentNode.insertBefore(a, o), o = a);
  return this;
}
function WC(e) {
  e || (e = HC);
  function t(u, p) {
    return u && p ? e(u.__data__, p.__data__) : !u - !p;
  }
  for (var r = this._groups, i = r.length, s = new Array(i), o = 0; o < i; ++o) {
    for (var a = r[o], n = a.length, l = s[o] = new Array(n), c, h = 0; h < n; ++h)
      (c = a[h]) && (l[h] = c);
    l.sort(t);
  }
  return new oe(s, this._parents).order();
}
function HC(e, t) {
  return e < t ? -1 : e > t ? 1 : e >= t ? 0 : NaN;
}
function YC() {
  var e = arguments[0];
  return arguments[0] = this, e.apply(null, arguments), this;
}
function jC() {
  return Array.from(this);
}
function UC() {
  for (var e = this._groups, t = 0, r = e.length; t < r; ++t)
    for (var i = e[t], s = 0, o = i.length; s < o; ++s) {
      var a = i[s];
      if (a) return a;
    }
  return null;
}
function GC() {
  let e = 0;
  for (const t of this) ++e;
  return e;
}
function XC() {
  return !this.node();
}
function VC(e) {
  for (var t = this._groups, r = 0, i = t.length; r < i; ++r)
    for (var s = t[r], o = 0, a = s.length, n; o < a; ++o)
      (n = s[o]) && e.call(n, n.__data__, o, s);
  return this;
}
function ZC(e) {
  return function() {
    this.removeAttribute(e);
  };
}
function KC(e) {
  return function() {
    this.removeAttributeNS(e.space, e.local);
  };
}
function QC(e, t) {
  return function() {
    this.setAttribute(e, t);
  };
}
function JC(e, t) {
  return function() {
    this.setAttributeNS(e.space, e.local, t);
  };
}
function tx(e, t) {
  return function() {
    var r = t.apply(this, arguments);
    r == null ? this.removeAttribute(e) : this.setAttribute(e, r);
  };
}
function ex(e, t) {
  return function() {
    var r = t.apply(this, arguments);
    r == null ? this.removeAttributeNS(e.space, e.local) : this.setAttributeNS(e.space, e.local, r);
  };
}
function rx(e, t) {
  var r = ko(e);
  if (arguments.length < 2) {
    var i = this.node();
    return r.local ? i.getAttributeNS(r.space, r.local) : i.getAttribute(r);
  }
  return this.each((t == null ? r.local ? KC : ZC : typeof t == "function" ? r.local ? ex : tx : r.local ? JC : QC)(r, t));
}
function Cu(e) {
  return e.ownerDocument && e.ownerDocument.defaultView || e.document && e || e.defaultView;
}
function ix(e) {
  return function() {
    this.style.removeProperty(e);
  };
}
function sx(e, t, r) {
  return function() {
    this.style.setProperty(e, t, r);
  };
}
function ox(e, t, r) {
  return function() {
    var i = t.apply(this, arguments);
    i == null ? this.style.removeProperty(e) : this.style.setProperty(e, i, r);
  };
}
function ax(e, t, r) {
  return arguments.length > 1 ? this.each((t == null ? ix : typeof t == "function" ? ox : sx)(e, t, r ?? "")) : Zr(this.node(), e);
}
function Zr(e, t) {
  return e.style.getPropertyValue(t) || Cu(e).getComputedStyle(e, null).getPropertyValue(t);
}
function nx(e) {
  return function() {
    delete this[e];
  };
}
function lx(e, t) {
  return function() {
    this[e] = t;
  };
}
function hx(e, t) {
  return function() {
    var r = t.apply(this, arguments);
    r == null ? delete this[e] : this[e] = r;
  };
}
function cx(e, t) {
  return arguments.length > 1 ? this.each((t == null ? nx : typeof t == "function" ? hx : lx)(e, t)) : this.node()[e];
}
function xu(e) {
  return e.trim().split(/^|\s+/);
}
function On(e) {
  return e.classList || new bu(e);
}
function bu(e) {
  this._node = e, this._names = xu(e.getAttribute("class") || "");
}
bu.prototype = {
  add: function(e) {
    var t = this._names.indexOf(e);
    t < 0 && (this._names.push(e), this._node.setAttribute("class", this._names.join(" ")));
  },
  remove: function(e) {
    var t = this._names.indexOf(e);
    t >= 0 && (this._names.splice(t, 1), this._node.setAttribute("class", this._names.join(" ")));
  },
  contains: function(e) {
    return this._names.indexOf(e) >= 0;
  }
};
function ku(e, t) {
  for (var r = On(e), i = -1, s = t.length; ++i < s; ) r.add(t[i]);
}
function Tu(e, t) {
  for (var r = On(e), i = -1, s = t.length; ++i < s; ) r.remove(t[i]);
}
function ux(e) {
  return function() {
    ku(this, e);
  };
}
function dx(e) {
  return function() {
    Tu(this, e);
  };
}
function px(e, t) {
  return function() {
    (t.apply(this, arguments) ? ku : Tu)(this, e);
  };
}
function fx(e, t) {
  var r = xu(e + "");
  if (arguments.length < 2) {
    for (var i = On(this.node()), s = -1, o = r.length; ++s < o; ) if (!i.contains(r[s])) return !1;
    return !0;
  }
  return this.each((typeof t == "function" ? px : t ? ux : dx)(r, t));
}
function gx() {
  this.textContent = "";
}
function mx(e) {
  return function() {
    this.textContent = e;
  };
}
function yx(e) {
  return function() {
    var t = e.apply(this, arguments);
    this.textContent = t ?? "";
  };
}
function Cx(e) {
  return arguments.length ? this.each(e == null ? gx : (typeof e == "function" ? yx : mx)(e)) : this.node().textContent;
}
function xx() {
  this.innerHTML = "";
}
function bx(e) {
  return function() {
    this.innerHTML = e;
  };
}
function kx(e) {
  return function() {
    var t = e.apply(this, arguments);
    this.innerHTML = t ?? "";
  };
}
function Tx(e) {
  return arguments.length ? this.each(e == null ? xx : (typeof e == "function" ? kx : bx)(e)) : this.node().innerHTML;
}
function wx() {
  this.nextSibling && this.parentNode.appendChild(this);
}
function Sx() {
  return this.each(wx);
}
function _x() {
  this.previousSibling && this.parentNode.insertBefore(this, this.parentNode.firstChild);
}
function vx() {
  return this.each(_x);
}
function Bx(e) {
  var t = typeof e == "function" ? e : pu(e);
  return this.select(function() {
    return this.appendChild(t.apply(this, arguments));
  });
}
function Lx() {
  return null;
}
function Fx(e, t) {
  var r = typeof e == "function" ? e : pu(e), i = t == null ? Lx : typeof t == "function" ? t : $n(t);
  return this.select(function() {
    return this.insertBefore(r.apply(this, arguments), i.apply(this, arguments) || null);
  });
}
function Ax() {
  var e = this.parentNode;
  e && e.removeChild(this);
}
function Mx() {
  return this.each(Ax);
}
function Ex() {
  var e = this.cloneNode(!1), t = this.parentNode;
  return t ? t.insertBefore(e, this.nextSibling) : e;
}
function $x() {
  var e = this.cloneNode(!0), t = this.parentNode;
  return t ? t.insertBefore(e, this.nextSibling) : e;
}
function Ox(e) {
  return this.select(e ? $x : Ex);
}
function Ix(e) {
  return arguments.length ? this.property("__data__", e) : this.node().__data__;
}
function Dx(e) {
  return function(t) {
    e.call(this, t, this.__data__);
  };
}
function Px(e) {
  return e.trim().split(/^|\s+/).map(function(t) {
    var r = "", i = t.indexOf(".");
    return i >= 0 && (r = t.slice(i + 1), t = t.slice(0, i)), { type: t, name: r };
  });
}
function Rx(e) {
  return function() {
    var t = this.__on;
    if (t) {
      for (var r = 0, i = -1, s = t.length, o; r < s; ++r)
        o = t[r], (!e.type || o.type === e.type) && o.name === e.name ? this.removeEventListener(o.type, o.listener, o.options) : t[++i] = o;
      ++i ? t.length = i : delete this.__on;
    }
  };
}
function Nx(e, t, r) {
  return function() {
    var i = this.__on, s, o = Dx(t);
    if (i) {
      for (var a = 0, n = i.length; a < n; ++a)
        if ((s = i[a]).type === e.type && s.name === e.name) {
          this.removeEventListener(s.type, s.listener, s.options), this.addEventListener(s.type, s.listener = o, s.options = r), s.value = t;
          return;
        }
    }
    this.addEventListener(e.type, o, r), s = { type: e.type, name: e.name, value: t, listener: o, options: r }, i ? i.push(s) : this.__on = [s];
  };
}
function qx(e, t, r) {
  var i = Px(e + ""), s, o = i.length, a;
  if (arguments.length < 2) {
    var n = this.node().__on;
    if (n) {
      for (var l = 0, c = n.length, h; l < c; ++l)
        for (s = 0, h = n[l]; s < o; ++s)
          if ((a = i[s]).type === h.type && a.name === h.name)
            return h.value;
    }
    return;
  }
  for (n = t ? Nx : Rx, s = 0; s < o; ++s) this.each(n(i[s], t, r));
  return this;
}
function wu(e, t, r) {
  var i = Cu(e), s = i.CustomEvent;
  typeof s == "function" ? s = new s(t, r) : (s = i.document.createEvent("Event"), r ? (s.initEvent(t, r.bubbles, r.cancelable), s.detail = r.detail) : s.initEvent(t, !1, !1)), e.dispatchEvent(s);
}
function zx(e, t) {
  return function() {
    return wu(this, e, t);
  };
}
function Wx(e, t) {
  return function() {
    return wu(this, e, t.apply(this, arguments));
  };
}
function Hx(e, t) {
  return this.each((typeof t == "function" ? Wx : zx)(e, t));
}
function* Yx() {
  for (var e = this._groups, t = 0, r = e.length; t < r; ++t)
    for (var i = e[t], s = 0, o = i.length, a; s < o; ++s)
      (a = i[s]) && (yield a);
}
var Su = [null];
function oe(e, t) {
  this._groups = e, this._parents = t;
}
function Ji() {
  return new oe([[document.documentElement]], Su);
}
function jx() {
  return this;
}
oe.prototype = Ji.prototype = {
  constructor: oe,
  select: yC,
  selectAll: kC,
  selectChild: _C,
  selectChildren: FC,
  filter: AC,
  data: DC,
  enter: MC,
  exit: RC,
  join: NC,
  merge: qC,
  selection: jx,
  order: zC,
  sort: WC,
  call: YC,
  nodes: jC,
  node: UC,
  size: GC,
  empty: XC,
  each: VC,
  attr: rx,
  style: ax,
  property: cx,
  classed: fx,
  text: Cx,
  html: Tx,
  raise: Sx,
  lower: vx,
  append: Bx,
  insert: Fx,
  remove: Mx,
  clone: Ox,
  datum: Ix,
  on: qx,
  dispatch: Hx,
  [Symbol.iterator]: Yx
};
function ct(e) {
  return typeof e == "string" ? new oe([[document.querySelector(e)]], [document.documentElement]) : new oe([[e]], Su);
}
function In(e, t, r) {
  e.prototype = t.prototype = r, r.constructor = e;
}
function _u(e, t) {
  var r = Object.create(e.prototype);
  for (var i in t) r[i] = t[i];
  return r;
}
function ts() {
}
var Ri = 0.7, Hs = 1 / Ri, Ur = "\\s*([+-]?\\d+)\\s*", Ni = "\\s*([+-]?(?:\\d*\\.)?\\d+(?:[eE][+-]?\\d+)?)\\s*", Be = "\\s*([+-]?(?:\\d*\\.)?\\d+(?:[eE][+-]?\\d+)?)%\\s*", Ux = /^#([0-9a-f]{3,8})$/, Gx = new RegExp(`^rgb\\(${Ur},${Ur},${Ur}\\)$`), Xx = new RegExp(`^rgb\\(${Be},${Be},${Be}\\)$`), Vx = new RegExp(`^rgba\\(${Ur},${Ur},${Ur},${Ni}\\)$`), Zx = new RegExp(`^rgba\\(${Be},${Be},${Be},${Ni}\\)$`), Kx = new RegExp(`^hsl\\(${Ni},${Be},${Be}\\)$`), Qx = new RegExp(`^hsla\\(${Ni},${Be},${Be},${Ni}\\)$`), uh = {
  aliceblue: 15792383,
  antiquewhite: 16444375,
  aqua: 65535,
  aquamarine: 8388564,
  azure: 15794175,
  beige: 16119260,
  bisque: 16770244,
  black: 0,
  blanchedalmond: 16772045,
  blue: 255,
  blueviolet: 9055202,
  brown: 10824234,
  burlywood: 14596231,
  cadetblue: 6266528,
  chartreuse: 8388352,
  chocolate: 13789470,
  coral: 16744272,
  cornflowerblue: 6591981,
  cornsilk: 16775388,
  crimson: 14423100,
  cyan: 65535,
  darkblue: 139,
  darkcyan: 35723,
  darkgoldenrod: 12092939,
  darkgray: 11119017,
  darkgreen: 25600,
  darkgrey: 11119017,
  darkkhaki: 12433259,
  darkmagenta: 9109643,
  darkolivegreen: 5597999,
  darkorange: 16747520,
  darkorchid: 10040012,
  darkred: 9109504,
  darksalmon: 15308410,
  darkseagreen: 9419919,
  darkslateblue: 4734347,
  darkslategray: 3100495,
  darkslategrey: 3100495,
  darkturquoise: 52945,
  darkviolet: 9699539,
  deeppink: 16716947,
  deepskyblue: 49151,
  dimgray: 6908265,
  dimgrey: 6908265,
  dodgerblue: 2003199,
  firebrick: 11674146,
  floralwhite: 16775920,
  forestgreen: 2263842,
  fuchsia: 16711935,
  gainsboro: 14474460,
  ghostwhite: 16316671,
  gold: 16766720,
  goldenrod: 14329120,
  gray: 8421504,
  green: 32768,
  greenyellow: 11403055,
  grey: 8421504,
  honeydew: 15794160,
  hotpink: 16738740,
  indianred: 13458524,
  indigo: 4915330,
  ivory: 16777200,
  khaki: 15787660,
  lavender: 15132410,
  lavenderblush: 16773365,
  lawngreen: 8190976,
  lemonchiffon: 16775885,
  lightblue: 11393254,
  lightcoral: 15761536,
  lightcyan: 14745599,
  lightgoldenrodyellow: 16448210,
  lightgray: 13882323,
  lightgreen: 9498256,
  lightgrey: 13882323,
  lightpink: 16758465,
  lightsalmon: 16752762,
  lightseagreen: 2142890,
  lightskyblue: 8900346,
  lightslategray: 7833753,
  lightslategrey: 7833753,
  lightsteelblue: 11584734,
  lightyellow: 16777184,
  lime: 65280,
  limegreen: 3329330,
  linen: 16445670,
  magenta: 16711935,
  maroon: 8388608,
  mediumaquamarine: 6737322,
  mediumblue: 205,
  mediumorchid: 12211667,
  mediumpurple: 9662683,
  mediumseagreen: 3978097,
  mediumslateblue: 8087790,
  mediumspringgreen: 64154,
  mediumturquoise: 4772300,
  mediumvioletred: 13047173,
  midnightblue: 1644912,
  mintcream: 16121850,
  mistyrose: 16770273,
  moccasin: 16770229,
  navajowhite: 16768685,
  navy: 128,
  oldlace: 16643558,
  olive: 8421376,
  olivedrab: 7048739,
  orange: 16753920,
  orangered: 16729344,
  orchid: 14315734,
  palegoldenrod: 15657130,
  palegreen: 10025880,
  paleturquoise: 11529966,
  palevioletred: 14381203,
  papayawhip: 16773077,
  peachpuff: 16767673,
  peru: 13468991,
  pink: 16761035,
  plum: 14524637,
  powderblue: 11591910,
  purple: 8388736,
  rebeccapurple: 6697881,
  red: 16711680,
  rosybrown: 12357519,
  royalblue: 4286945,
  saddlebrown: 9127187,
  salmon: 16416882,
  sandybrown: 16032864,
  seagreen: 3050327,
  seashell: 16774638,
  sienna: 10506797,
  silver: 12632256,
  skyblue: 8900331,
  slateblue: 6970061,
  slategray: 7372944,
  slategrey: 7372944,
  snow: 16775930,
  springgreen: 65407,
  steelblue: 4620980,
  tan: 13808780,
  teal: 32896,
  thistle: 14204888,
  tomato: 16737095,
  turquoise: 4251856,
  violet: 15631086,
  wheat: 16113331,
  white: 16777215,
  whitesmoke: 16119285,
  yellow: 16776960,
  yellowgreen: 10145074
};
In(ts, qi, {
  copy(e) {
    return Object.assign(new this.constructor(), this, e);
  },
  displayable() {
    return this.rgb().displayable();
  },
  hex: dh,
  // Deprecated! Use color.formatHex.
  formatHex: dh,
  formatHex8: Jx,
  formatHsl: tb,
  formatRgb: ph,
  toString: ph
});
function dh() {
  return this.rgb().formatHex();
}
function Jx() {
  return this.rgb().formatHex8();
}
function tb() {
  return vu(this).formatHsl();
}
function ph() {
  return this.rgb().formatRgb();
}
function qi(e) {
  var t, r;
  return e = (e + "").trim().toLowerCase(), (t = Ux.exec(e)) ? (r = t[1].length, t = parseInt(t[1], 16), r === 6 ? fh(t) : r === 3 ? new ee(t >> 8 & 15 | t >> 4 & 240, t >> 4 & 15 | t & 240, (t & 15) << 4 | t & 15, 1) : r === 8 ? fs(t >> 24 & 255, t >> 16 & 255, t >> 8 & 255, (t & 255) / 255) : r === 4 ? fs(t >> 12 & 15 | t >> 8 & 240, t >> 8 & 15 | t >> 4 & 240, t >> 4 & 15 | t & 240, ((t & 15) << 4 | t & 15) / 255) : null) : (t = Gx.exec(e)) ? new ee(t[1], t[2], t[3], 1) : (t = Xx.exec(e)) ? new ee(t[1] * 255 / 100, t[2] * 255 / 100, t[3] * 255 / 100, 1) : (t = Vx.exec(e)) ? fs(t[1], t[2], t[3], t[4]) : (t = Zx.exec(e)) ? fs(t[1] * 255 / 100, t[2] * 255 / 100, t[3] * 255 / 100, t[4]) : (t = Kx.exec(e)) ? yh(t[1], t[2] / 100, t[3] / 100, 1) : (t = Qx.exec(e)) ? yh(t[1], t[2] / 100, t[3] / 100, t[4]) : uh.hasOwnProperty(e) ? fh(uh[e]) : e === "transparent" ? new ee(NaN, NaN, NaN, 0) : null;
}
function fh(e) {
  return new ee(e >> 16 & 255, e >> 8 & 255, e & 255, 1);
}
function fs(e, t, r, i) {
  return i <= 0 && (e = t = r = NaN), new ee(e, t, r, i);
}
function eb(e) {
  return e instanceof ts || (e = qi(e)), e ? (e = e.rgb(), new ee(e.r, e.g, e.b, e.opacity)) : new ee();
}
function Ma(e, t, r, i) {
  return arguments.length === 1 ? eb(e) : new ee(e, t, r, i ?? 1);
}
function ee(e, t, r, i) {
  this.r = +e, this.g = +t, this.b = +r, this.opacity = +i;
}
In(ee, Ma, _u(ts, {
  brighter(e) {
    return e = e == null ? Hs : Math.pow(Hs, e), new ee(this.r * e, this.g * e, this.b * e, this.opacity);
  },
  darker(e) {
    return e = e == null ? Ri : Math.pow(Ri, e), new ee(this.r * e, this.g * e, this.b * e, this.opacity);
  },
  rgb() {
    return this;
  },
  clamp() {
    return new ee(Cr(this.r), Cr(this.g), Cr(this.b), Ys(this.opacity));
  },
  displayable() {
    return -0.5 <= this.r && this.r < 255.5 && -0.5 <= this.g && this.g < 255.5 && -0.5 <= this.b && this.b < 255.5 && 0 <= this.opacity && this.opacity <= 1;
  },
  hex: gh,
  // Deprecated! Use color.formatHex.
  formatHex: gh,
  formatHex8: rb,
  formatRgb: mh,
  toString: mh
}));
function gh() {
  return `#${gr(this.r)}${gr(this.g)}${gr(this.b)}`;
}
function rb() {
  return `#${gr(this.r)}${gr(this.g)}${gr(this.b)}${gr((isNaN(this.opacity) ? 1 : this.opacity) * 255)}`;
}
function mh() {
  const e = Ys(this.opacity);
  return `${e === 1 ? "rgb(" : "rgba("}${Cr(this.r)}, ${Cr(this.g)}, ${Cr(this.b)}${e === 1 ? ")" : `, ${e})`}`;
}
function Ys(e) {
  return isNaN(e) ? 1 : Math.max(0, Math.min(1, e));
}
function Cr(e) {
  return Math.max(0, Math.min(255, Math.round(e) || 0));
}
function gr(e) {
  return e = Cr(e), (e < 16 ? "0" : "") + e.toString(16);
}
function yh(e, t, r, i) {
  return i <= 0 ? e = t = r = NaN : r <= 0 || r >= 1 ? e = t = NaN : t <= 0 && (e = NaN), new ge(e, t, r, i);
}
function vu(e) {
  if (e instanceof ge) return new ge(e.h, e.s, e.l, e.opacity);
  if (e instanceof ts || (e = qi(e)), !e) return new ge();
  if (e instanceof ge) return e;
  e = e.rgb();
  var t = e.r / 255, r = e.g / 255, i = e.b / 255, s = Math.min(t, r, i), o = Math.max(t, r, i), a = NaN, n = o - s, l = (o + s) / 2;
  return n ? (t === o ? a = (r - i) / n + (r < i) * 6 : r === o ? a = (i - t) / n + 2 : a = (t - r) / n + 4, n /= l < 0.5 ? o + s : 2 - o - s, a *= 60) : n = l > 0 && l < 1 ? 0 : a, new ge(a, n, l, e.opacity);
}
function ib(e, t, r, i) {
  return arguments.length === 1 ? vu(e) : new ge(e, t, r, i ?? 1);
}
function ge(e, t, r, i) {
  this.h = +e, this.s = +t, this.l = +r, this.opacity = +i;
}
In(ge, ib, _u(ts, {
  brighter(e) {
    return e = e == null ? Hs : Math.pow(Hs, e), new ge(this.h, this.s, this.l * e, this.opacity);
  },
  darker(e) {
    return e = e == null ? Ri : Math.pow(Ri, e), new ge(this.h, this.s, this.l * e, this.opacity);
  },
  rgb() {
    var e = this.h % 360 + (this.h < 0) * 360, t = isNaN(e) || isNaN(this.s) ? 0 : this.s, r = this.l, i = r + (r < 0.5 ? r : 1 - r) * t, s = 2 * r - i;
    return new ee(
      na(e >= 240 ? e - 240 : e + 120, s, i),
      na(e, s, i),
      na(e < 120 ? e + 240 : e - 120, s, i),
      this.opacity
    );
  },
  clamp() {
    return new ge(Ch(this.h), gs(this.s), gs(this.l), Ys(this.opacity));
  },
  displayable() {
    return (0 <= this.s && this.s <= 1 || isNaN(this.s)) && 0 <= this.l && this.l <= 1 && 0 <= this.opacity && this.opacity <= 1;
  },
  formatHsl() {
    const e = Ys(this.opacity);
    return `${e === 1 ? "hsl(" : "hsla("}${Ch(this.h)}, ${gs(this.s) * 100}%, ${gs(this.l) * 100}%${e === 1 ? ")" : `, ${e})`}`;
  }
}));
function Ch(e) {
  return e = (e || 0) % 360, e < 0 ? e + 360 : e;
}
function gs(e) {
  return Math.max(0, Math.min(1, e || 0));
}
function na(e, t, r) {
  return (e < 60 ? t + (r - t) * e / 60 : e < 180 ? r : e < 240 ? t + (r - t) * (240 - e) / 60 : t) * 255;
}
const Dn = (e) => () => e;
function Bu(e, t) {
  return function(r) {
    return e + r * t;
  };
}
function sb(e, t, r) {
  return e = Math.pow(e, r), t = Math.pow(t, r) - e, r = 1 / r, function(i) {
    return Math.pow(e + i * t, r);
  };
}
function nA(e, t) {
  var r = t - e;
  return r ? Bu(e, r > 180 || r < -180 ? r - 360 * Math.round(r / 360) : r) : Dn(isNaN(e) ? t : e);
}
function ob(e) {
  return (e = +e) == 1 ? Lu : function(t, r) {
    return r - t ? sb(t, r, e) : Dn(isNaN(t) ? r : t);
  };
}
function Lu(e, t) {
  var r = t - e;
  return r ? Bu(e, r) : Dn(isNaN(e) ? t : e);
}
const xh = (function e(t) {
  var r = ob(t);
  function i(s, o) {
    var a = r((s = Ma(s)).r, (o = Ma(o)).r), n = r(s.g, o.g), l = r(s.b, o.b), c = Lu(s.opacity, o.opacity);
    return function(h) {
      return s.r = a(h), s.g = n(h), s.b = l(h), s.opacity = c(h), s + "";
    };
  }
  return i.gamma = e, i;
})(1);
function Ze(e, t) {
  return e = +e, t = +t, function(r) {
    return e * (1 - r) + t * r;
  };
}
var Ea = /[-+]?(?:\d+\.?\d*|\.?\d+)(?:[eE][-+]?\d+)?/g, la = new RegExp(Ea.source, "g");
function ab(e) {
  return function() {
    return e;
  };
}
function nb(e) {
  return function(t) {
    return e(t) + "";
  };
}
function lb(e, t) {
  var r = Ea.lastIndex = la.lastIndex = 0, i, s, o, a = -1, n = [], l = [];
  for (e = e + "", t = t + ""; (i = Ea.exec(e)) && (s = la.exec(t)); )
    (o = s.index) > r && (o = t.slice(r, o), n[a] ? n[a] += o : n[++a] = o), (i = i[0]) === (s = s[0]) ? n[a] ? n[a] += s : n[++a] = s : (n[++a] = null, l.push({ i: a, x: Ze(i, s) })), r = la.lastIndex;
  return r < t.length && (o = t.slice(r), n[a] ? n[a] += o : n[++a] = o), n.length < 2 ? l[0] ? nb(l[0].x) : ab(t) : (t = l.length, function(c) {
    for (var h = 0, u; h < t; ++h) n[(u = l[h]).i] = u.x(c);
    return n.join("");
  });
}
var bh = 180 / Math.PI, $a = {
  translateX: 0,
  translateY: 0,
  rotate: 0,
  skewX: 0,
  scaleX: 1,
  scaleY: 1
};
function Fu(e, t, r, i, s, o) {
  var a, n, l;
  return (a = Math.sqrt(e * e + t * t)) && (e /= a, t /= a), (l = e * r + t * i) && (r -= e * l, i -= t * l), (n = Math.sqrt(r * r + i * i)) && (r /= n, i /= n, l /= n), e * i < t * r && (e = -e, t = -t, l = -l, a = -a), {
    translateX: s,
    translateY: o,
    rotate: Math.atan2(t, e) * bh,
    skewX: Math.atan(l) * bh,
    scaleX: a,
    scaleY: n
  };
}
var ms;
function hb(e) {
  const t = new (typeof DOMMatrix == "function" ? DOMMatrix : WebKitCSSMatrix)(e + "");
  return t.isIdentity ? $a : Fu(t.a, t.b, t.c, t.d, t.e, t.f);
}
function cb(e) {
  return e == null || (ms || (ms = document.createElementNS("http://www.w3.org/2000/svg", "g")), ms.setAttribute("transform", e), !(e = ms.transform.baseVal.consolidate())) ? $a : (e = e.matrix, Fu(e.a, e.b, e.c, e.d, e.e, e.f));
}
function Au(e, t, r, i) {
  function s(c) {
    return c.length ? c.pop() + " " : "";
  }
  function o(c, h, u, p, d, g) {
    if (c !== u || h !== p) {
      var m = d.push("translate(", null, t, null, r);
      g.push({ i: m - 4, x: Ze(c, u) }, { i: m - 2, x: Ze(h, p) });
    } else (u || p) && d.push("translate(" + u + t + p + r);
  }
  function a(c, h, u, p) {
    c !== h ? (c - h > 180 ? h += 360 : h - c > 180 && (c += 360), p.push({ i: u.push(s(u) + "rotate(", null, i) - 2, x: Ze(c, h) })) : h && u.push(s(u) + "rotate(" + h + i);
  }
  function n(c, h, u, p) {
    c !== h ? p.push({ i: u.push(s(u) + "skewX(", null, i) - 2, x: Ze(c, h) }) : h && u.push(s(u) + "skewX(" + h + i);
  }
  function l(c, h, u, p, d, g) {
    if (c !== u || h !== p) {
      var m = d.push(s(d) + "scale(", null, ",", null, ")");
      g.push({ i: m - 4, x: Ze(c, u) }, { i: m - 2, x: Ze(h, p) });
    } else (u !== 1 || p !== 1) && d.push(s(d) + "scale(" + u + "," + p + ")");
  }
  return function(c, h) {
    var u = [], p = [];
    return c = e(c), h = e(h), o(c.translateX, c.translateY, h.translateX, h.translateY, u, p), a(c.rotate, h.rotate, u, p), n(c.skewX, h.skewX, u, p), l(c.scaleX, c.scaleY, h.scaleX, h.scaleY, u, p), c = h = null, function(d) {
      for (var g = -1, m = p.length, y; ++g < m; ) u[(y = p[g]).i] = y.x(d);
      return u.join("");
    };
  };
}
var ub = Au(hb, "px, ", "px)", "deg)"), db = Au(cb, ", ", ")", ")"), Kr = 0, wi = 0, pi = 0, Mu = 1e3, js, Si, Us = 0, kr = 0, To = 0, zi = typeof performance == "object" && performance.now ? performance : Date, Eu = typeof window == "object" && window.requestAnimationFrame ? window.requestAnimationFrame.bind(window) : function(e) {
  setTimeout(e, 17);
};
function Pn() {
  return kr || (Eu(pb), kr = zi.now() + To);
}
function pb() {
  kr = 0;
}
function Gs() {
  this._call = this._time = this._next = null;
}
Gs.prototype = $u.prototype = {
  constructor: Gs,
  restart: function(e, t, r) {
    if (typeof e != "function") throw new TypeError("callback is not a function");
    r = (r == null ? Pn() : +r) + (t == null ? 0 : +t), !this._next && Si !== this && (Si ? Si._next = this : js = this, Si = this), this._call = e, this._time = r, Oa();
  },
  stop: function() {
    this._call && (this._call = null, this._time = 1 / 0, Oa());
  }
};
function $u(e, t, r) {
  var i = new Gs();
  return i.restart(e, t, r), i;
}
function fb() {
  Pn(), ++Kr;
  for (var e = js, t; e; )
    (t = kr - e._time) >= 0 && e._call.call(void 0, t), e = e._next;
  --Kr;
}
function kh() {
  kr = (Us = zi.now()) + To, Kr = wi = 0;
  try {
    fb();
  } finally {
    Kr = 0, mb(), kr = 0;
  }
}
function gb() {
  var e = zi.now(), t = e - Us;
  t > Mu && (To -= t, Us = e);
}
function mb() {
  for (var e, t = js, r, i = 1 / 0; t; )
    t._call ? (i > t._time && (i = t._time), e = t, t = t._next) : (r = t._next, t._next = null, t = e ? e._next = r : js = r);
  Si = e, Oa(i);
}
function Oa(e) {
  if (!Kr) {
    wi && (wi = clearTimeout(wi));
    var t = e - kr;
    t > 24 ? (e < 1 / 0 && (wi = setTimeout(kh, e - zi.now() - To)), pi && (pi = clearInterval(pi))) : (pi || (Us = zi.now(), pi = setInterval(gb, Mu)), Kr = 1, Eu(kh));
  }
}
function Th(e, t, r) {
  var i = new Gs();
  return t = t == null ? 0 : +t, i.restart((s) => {
    i.stop(), e(s + t);
  }, t, r), i;
}
var yb = du("start", "end", "cancel", "interrupt"), Cb = [], Ou = 0, wh = 1, Ia = 2, Fs = 3, Sh = 4, Da = 5, As = 6;
function wo(e, t, r, i, s, o) {
  var a = e.__transition;
  if (!a) e.__transition = {};
  else if (r in a) return;
  xb(e, r, {
    name: t,
    index: i,
    // For context during callback.
    group: s,
    // For context during callback.
    on: yb,
    tween: Cb,
    time: o.time,
    delay: o.delay,
    duration: o.duration,
    ease: o.ease,
    timer: null,
    state: Ou
  });
}
function Rn(e, t) {
  var r = ke(e, t);
  if (r.state > Ou) throw new Error("too late; already scheduled");
  return r;
}
function Ee(e, t) {
  var r = ke(e, t);
  if (r.state > Fs) throw new Error("too late; already running");
  return r;
}
function ke(e, t) {
  var r = e.__transition;
  if (!r || !(r = r[t])) throw new Error("transition not found");
  return r;
}
function xb(e, t, r) {
  var i = e.__transition, s;
  i[t] = r, r.timer = $u(o, 0, r.time);
  function o(c) {
    r.state = wh, r.timer.restart(a, r.delay, r.time), r.delay <= c && a(c - r.delay);
  }
  function a(c) {
    var h, u, p, d;
    if (r.state !== wh) return l();
    for (h in i)
      if (d = i[h], d.name === r.name) {
        if (d.state === Fs) return Th(a);
        d.state === Sh ? (d.state = As, d.timer.stop(), d.on.call("interrupt", e, e.__data__, d.index, d.group), delete i[h]) : +h < t && (d.state = As, d.timer.stop(), d.on.call("cancel", e, e.__data__, d.index, d.group), delete i[h]);
      }
    if (Th(function() {
      r.state === Fs && (r.state = Sh, r.timer.restart(n, r.delay, r.time), n(c));
    }), r.state = Ia, r.on.call("start", e, e.__data__, r.index, r.group), r.state === Ia) {
      for (r.state = Fs, s = new Array(p = r.tween.length), h = 0, u = -1; h < p; ++h)
        (d = r.tween[h].value.call(e, e.__data__, r.index, r.group)) && (s[++u] = d);
      s.length = u + 1;
    }
  }
  function n(c) {
    for (var h = c < r.duration ? r.ease.call(null, c / r.duration) : (r.timer.restart(l), r.state = Da, 1), u = -1, p = s.length; ++u < p; )
      s[u].call(e, h);
    r.state === Da && (r.on.call("end", e, e.__data__, r.index, r.group), l());
  }
  function l() {
    r.state = As, r.timer.stop(), delete i[t];
    for (var c in i) return;
    delete e.__transition;
  }
}
function bb(e, t) {
  var r = e.__transition, i, s, o = !0, a;
  if (r) {
    t = t == null ? null : t + "";
    for (a in r) {
      if ((i = r[a]).name !== t) {
        o = !1;
        continue;
      }
      s = i.state > Ia && i.state < Da, i.state = As, i.timer.stop(), i.on.call(s ? "interrupt" : "cancel", e, e.__data__, i.index, i.group), delete r[a];
    }
    o && delete e.__transition;
  }
}
function kb(e) {
  return this.each(function() {
    bb(this, e);
  });
}
function Tb(e, t) {
  var r, i;
  return function() {
    var s = Ee(this, e), o = s.tween;
    if (o !== r) {
      i = r = o;
      for (var a = 0, n = i.length; a < n; ++a)
        if (i[a].name === t) {
          i = i.slice(), i.splice(a, 1);
          break;
        }
    }
    s.tween = i;
  };
}
function wb(e, t, r) {
  var i, s;
  if (typeof r != "function") throw new Error();
  return function() {
    var o = Ee(this, e), a = o.tween;
    if (a !== i) {
      s = (i = a).slice();
      for (var n = { name: t, value: r }, l = 0, c = s.length; l < c; ++l)
        if (s[l].name === t) {
          s[l] = n;
          break;
        }
      l === c && s.push(n);
    }
    o.tween = s;
  };
}
function Sb(e, t) {
  var r = this._id;
  if (e += "", arguments.length < 2) {
    for (var i = ke(this.node(), r).tween, s = 0, o = i.length, a; s < o; ++s)
      if ((a = i[s]).name === e)
        return a.value;
    return null;
  }
  return this.each((t == null ? Tb : wb)(r, e, t));
}
function Nn(e, t, r) {
  var i = e._id;
  return e.each(function() {
    var s = Ee(this, i);
    (s.value || (s.value = {}))[t] = r.apply(this, arguments);
  }), function(s) {
    return ke(s, i).value[t];
  };
}
function Iu(e, t) {
  var r;
  return (typeof t == "number" ? Ze : t instanceof qi ? xh : (r = qi(t)) ? (t = r, xh) : lb)(e, t);
}
function _b(e) {
  return function() {
    this.removeAttribute(e);
  };
}
function vb(e) {
  return function() {
    this.removeAttributeNS(e.space, e.local);
  };
}
function Bb(e, t, r) {
  var i, s = r + "", o;
  return function() {
    var a = this.getAttribute(e);
    return a === s ? null : a === i ? o : o = t(i = a, r);
  };
}
function Lb(e, t, r) {
  var i, s = r + "", o;
  return function() {
    var a = this.getAttributeNS(e.space, e.local);
    return a === s ? null : a === i ? o : o = t(i = a, r);
  };
}
function Fb(e, t, r) {
  var i, s, o;
  return function() {
    var a, n = r(this), l;
    return n == null ? void this.removeAttribute(e) : (a = this.getAttribute(e), l = n + "", a === l ? null : a === i && l === s ? o : (s = l, o = t(i = a, n)));
  };
}
function Ab(e, t, r) {
  var i, s, o;
  return function() {
    var a, n = r(this), l;
    return n == null ? void this.removeAttributeNS(e.space, e.local) : (a = this.getAttributeNS(e.space, e.local), l = n + "", a === l ? null : a === i && l === s ? o : (s = l, o = t(i = a, n)));
  };
}
function Mb(e, t) {
  var r = ko(e), i = r === "transform" ? db : Iu;
  return this.attrTween(e, typeof t == "function" ? (r.local ? Ab : Fb)(r, i, Nn(this, "attr." + e, t)) : t == null ? (r.local ? vb : _b)(r) : (r.local ? Lb : Bb)(r, i, t));
}
function Eb(e, t) {
  return function(r) {
    this.setAttribute(e, t.call(this, r));
  };
}
function $b(e, t) {
  return function(r) {
    this.setAttributeNS(e.space, e.local, t.call(this, r));
  };
}
function Ob(e, t) {
  var r, i;
  function s() {
    var o = t.apply(this, arguments);
    return o !== i && (r = (i = o) && $b(e, o)), r;
  }
  return s._value = t, s;
}
function Ib(e, t) {
  var r, i;
  function s() {
    var o = t.apply(this, arguments);
    return o !== i && (r = (i = o) && Eb(e, o)), r;
  }
  return s._value = t, s;
}
function Db(e, t) {
  var r = "attr." + e;
  if (arguments.length < 2) return (r = this.tween(r)) && r._value;
  if (t == null) return this.tween(r, null);
  if (typeof t != "function") throw new Error();
  var i = ko(e);
  return this.tween(r, (i.local ? Ob : Ib)(i, t));
}
function Pb(e, t) {
  return function() {
    Rn(this, e).delay = +t.apply(this, arguments);
  };
}
function Rb(e, t) {
  return t = +t, function() {
    Rn(this, e).delay = t;
  };
}
function Nb(e) {
  var t = this._id;
  return arguments.length ? this.each((typeof e == "function" ? Pb : Rb)(t, e)) : ke(this.node(), t).delay;
}
function qb(e, t) {
  return function() {
    Ee(this, e).duration = +t.apply(this, arguments);
  };
}
function zb(e, t) {
  return t = +t, function() {
    Ee(this, e).duration = t;
  };
}
function Wb(e) {
  var t = this._id;
  return arguments.length ? this.each((typeof e == "function" ? qb : zb)(t, e)) : ke(this.node(), t).duration;
}
function Hb(e, t) {
  if (typeof t != "function") throw new Error();
  return function() {
    Ee(this, e).ease = t;
  };
}
function Yb(e) {
  var t = this._id;
  return arguments.length ? this.each(Hb(t, e)) : ke(this.node(), t).ease;
}
function jb(e, t) {
  return function() {
    var r = t.apply(this, arguments);
    if (typeof r != "function") throw new Error();
    Ee(this, e).ease = r;
  };
}
function Ub(e) {
  if (typeof e != "function") throw new Error();
  return this.each(jb(this._id, e));
}
function Gb(e) {
  typeof e != "function" && (e = gu(e));
  for (var t = this._groups, r = t.length, i = new Array(r), s = 0; s < r; ++s)
    for (var o = t[s], a = o.length, n = i[s] = [], l, c = 0; c < a; ++c)
      (l = o[c]) && e.call(l, l.__data__, c, o) && n.push(l);
  return new We(i, this._parents, this._name, this._id);
}
function Xb(e) {
  if (e._id !== this._id) throw new Error();
  for (var t = this._groups, r = e._groups, i = t.length, s = r.length, o = Math.min(i, s), a = new Array(i), n = 0; n < o; ++n)
    for (var l = t[n], c = r[n], h = l.length, u = a[n] = new Array(h), p, d = 0; d < h; ++d)
      (p = l[d] || c[d]) && (u[d] = p);
  for (; n < i; ++n)
    a[n] = t[n];
  return new We(a, this._parents, this._name, this._id);
}
function Vb(e) {
  return (e + "").trim().split(/^|\s+/).every(function(t) {
    var r = t.indexOf(".");
    return r >= 0 && (t = t.slice(0, r)), !t || t === "start";
  });
}
function Zb(e, t, r) {
  var i, s, o = Vb(t) ? Rn : Ee;
  return function() {
    var a = o(this, e), n = a.on;
    n !== i && (s = (i = n).copy()).on(t, r), a.on = s;
  };
}
function Kb(e, t) {
  var r = this._id;
  return arguments.length < 2 ? ke(this.node(), r).on.on(e) : this.each(Zb(r, e, t));
}
function Qb(e) {
  return function() {
    var t = this.parentNode;
    for (var r in this.__transition) if (+r !== e) return;
    t && t.removeChild(this);
  };
}
function Jb() {
  return this.on("end.remove", Qb(this._id));
}
function t1(e) {
  var t = this._name, r = this._id;
  typeof e != "function" && (e = $n(e));
  for (var i = this._groups, s = i.length, o = new Array(s), a = 0; a < s; ++a)
    for (var n = i[a], l = n.length, c = o[a] = new Array(l), h, u, p = 0; p < l; ++p)
      (h = n[p]) && (u = e.call(h, h.__data__, p, n)) && ("__data__" in h && (u.__data__ = h.__data__), c[p] = u, wo(c[p], t, r, p, c, ke(h, r)));
  return new We(o, this._parents, t, r);
}
function e1(e) {
  var t = this._name, r = this._id;
  typeof e != "function" && (e = fu(e));
  for (var i = this._groups, s = i.length, o = [], a = [], n = 0; n < s; ++n)
    for (var l = i[n], c = l.length, h, u = 0; u < c; ++u)
      if (h = l[u]) {
        for (var p = e.call(h, h.__data__, u, l), d, g = ke(h, r), m = 0, y = p.length; m < y; ++m)
          (d = p[m]) && wo(d, t, r, m, p, g);
        o.push(p), a.push(h);
      }
  return new We(o, a, t, r);
}
var r1 = Ji.prototype.constructor;
function i1() {
  return new r1(this._groups, this._parents);
}
function s1(e, t) {
  var r, i, s;
  return function() {
    var o = Zr(this, e), a = (this.style.removeProperty(e), Zr(this, e));
    return o === a ? null : o === r && a === i ? s : s = t(r = o, i = a);
  };
}
function Du(e) {
  return function() {
    this.style.removeProperty(e);
  };
}
function o1(e, t, r) {
  var i, s = r + "", o;
  return function() {
    var a = Zr(this, e);
    return a === s ? null : a === i ? o : o = t(i = a, r);
  };
}
function a1(e, t, r) {
  var i, s, o;
  return function() {
    var a = Zr(this, e), n = r(this), l = n + "";
    return n == null && (l = n = (this.style.removeProperty(e), Zr(this, e))), a === l ? null : a === i && l === s ? o : (s = l, o = t(i = a, n));
  };
}
function n1(e, t) {
  var r, i, s, o = "style." + t, a = "end." + o, n;
  return function() {
    var l = Ee(this, e), c = l.on, h = l.value[o] == null ? n || (n = Du(t)) : void 0;
    (c !== r || s !== h) && (i = (r = c).copy()).on(a, s = h), l.on = i;
  };
}
function l1(e, t, r) {
  var i = (e += "") == "transform" ? ub : Iu;
  return t == null ? this.styleTween(e, s1(e, i)).on("end.style." + e, Du(e)) : typeof t == "function" ? this.styleTween(e, a1(e, i, Nn(this, "style." + e, t))).each(n1(this._id, e)) : this.styleTween(e, o1(e, i, t), r).on("end.style." + e, null);
}
function h1(e, t, r) {
  return function(i) {
    this.style.setProperty(e, t.call(this, i), r);
  };
}
function c1(e, t, r) {
  var i, s;
  function o() {
    var a = t.apply(this, arguments);
    return a !== s && (i = (s = a) && h1(e, a, r)), i;
  }
  return o._value = t, o;
}
function u1(e, t, r) {
  var i = "style." + (e += "");
  if (arguments.length < 2) return (i = this.tween(i)) && i._value;
  if (t == null) return this.tween(i, null);
  if (typeof t != "function") throw new Error();
  return this.tween(i, c1(e, t, r ?? ""));
}
function d1(e) {
  return function() {
    this.textContent = e;
  };
}
function p1(e) {
  return function() {
    var t = e(this);
    this.textContent = t ?? "";
  };
}
function f1(e) {
  return this.tween("text", typeof e == "function" ? p1(Nn(this, "text", e)) : d1(e == null ? "" : e + ""));
}
function g1(e) {
  return function(t) {
    this.textContent = e.call(this, t);
  };
}
function m1(e) {
  var t, r;
  function i() {
    var s = e.apply(this, arguments);
    return s !== r && (t = (r = s) && g1(s)), t;
  }
  return i._value = e, i;
}
function y1(e) {
  var t = "text";
  if (arguments.length < 1) return (t = this.tween(t)) && t._value;
  if (e == null) return this.tween(t, null);
  if (typeof e != "function") throw new Error();
  return this.tween(t, m1(e));
}
function C1() {
  for (var e = this._name, t = this._id, r = Pu(), i = this._groups, s = i.length, o = 0; o < s; ++o)
    for (var a = i[o], n = a.length, l, c = 0; c < n; ++c)
      if (l = a[c]) {
        var h = ke(l, t);
        wo(l, e, r, c, a, {
          time: h.time + h.delay + h.duration,
          delay: 0,
          duration: h.duration,
          ease: h.ease
        });
      }
  return new We(i, this._parents, e, r);
}
function x1() {
  var e, t, r = this, i = r._id, s = r.size();
  return new Promise(function(o, a) {
    var n = { value: a }, l = { value: function() {
      --s === 0 && o();
    } };
    r.each(function() {
      var c = Ee(this, i), h = c.on;
      h !== e && (t = (e = h).copy(), t._.cancel.push(n), t._.interrupt.push(n), t._.end.push(l)), c.on = t;
    }), s === 0 && o();
  });
}
var b1 = 0;
function We(e, t, r, i) {
  this._groups = e, this._parents = t, this._name = r, this._id = i;
}
function Pu() {
  return ++b1;
}
var Pe = Ji.prototype;
We.prototype = {
  constructor: We,
  select: t1,
  selectAll: e1,
  selectChild: Pe.selectChild,
  selectChildren: Pe.selectChildren,
  filter: Gb,
  merge: Xb,
  selection: i1,
  transition: C1,
  call: Pe.call,
  nodes: Pe.nodes,
  node: Pe.node,
  size: Pe.size,
  empty: Pe.empty,
  each: Pe.each,
  on: Kb,
  attr: Mb,
  attrTween: Db,
  style: l1,
  styleTween: u1,
  text: f1,
  textTween: y1,
  remove: Jb,
  tween: Sb,
  delay: Nb,
  duration: Wb,
  ease: Yb,
  easeVarying: Ub,
  end: x1,
  [Symbol.iterator]: Pe[Symbol.iterator]
};
function k1(e) {
  return ((e *= 2) <= 1 ? e * e * e : (e -= 2) * e * e + 2) / 2;
}
var T1 = {
  time: null,
  // Set on use.
  delay: 0,
  duration: 250,
  ease: k1
};
function w1(e, t) {
  for (var r; !(r = e.__transition) || !(r = r[t]); )
    if (!(e = e.parentNode))
      throw new Error(`transition ${t} not found`);
  return r;
}
function S1(e) {
  var t, r;
  e instanceof We ? (t = e._id, e = e._name) : (t = Pu(), (r = T1).time = Pn(), e = e == null ? null : e + "");
  for (var i = this._groups, s = i.length, o = 0; o < s; ++o)
    for (var a = i[o], n = a.length, l, c = 0; c < n; ++c)
      (l = a[c]) && wo(l, e, t, c, a, r || w1(l, t));
  return new We(i, this._parents, e, t);
}
Ji.prototype.interrupt = kb;
Ji.prototype.transition = S1;
const Pa = Math.PI, Ra = 2 * Pa, ur = 1e-6, _1 = Ra - ur;
function Ru(e) {
  this._ += e[0];
  for (let t = 1, r = e.length; t < r; ++t)
    this._ += arguments[t] + e[t];
}
function v1(e) {
  let t = Math.floor(e);
  if (!(t >= 0)) throw new Error(`invalid digits: ${e}`);
  if (t > 15) return Ru;
  const r = 10 ** t;
  return function(i) {
    this._ += i[0];
    for (let s = 1, o = i.length; s < o; ++s)
      this._ += Math.round(arguments[s] * r) / r + i[s];
  };
}
class B1 {
  constructor(t) {
    this._x0 = this._y0 = // start of current subpath
    this._x1 = this._y1 = null, this._ = "", this._append = t == null ? Ru : v1(t);
  }
  moveTo(t, r) {
    this._append`M${this._x0 = this._x1 = +t},${this._y0 = this._y1 = +r}`;
  }
  closePath() {
    this._x1 !== null && (this._x1 = this._x0, this._y1 = this._y0, this._append`Z`);
  }
  lineTo(t, r) {
    this._append`L${this._x1 = +t},${this._y1 = +r}`;
  }
  quadraticCurveTo(t, r, i, s) {
    this._append`Q${+t},${+r},${this._x1 = +i},${this._y1 = +s}`;
  }
  bezierCurveTo(t, r, i, s, o, a) {
    this._append`C${+t},${+r},${+i},${+s},${this._x1 = +o},${this._y1 = +a}`;
  }
  arcTo(t, r, i, s, o) {
    if (t = +t, r = +r, i = +i, s = +s, o = +o, o < 0) throw new Error(`negative radius: ${o}`);
    let a = this._x1, n = this._y1, l = i - t, c = s - r, h = a - t, u = n - r, p = h * h + u * u;
    if (this._x1 === null)
      this._append`M${this._x1 = t},${this._y1 = r}`;
    else if (p > ur) if (!(Math.abs(u * l - c * h) > ur) || !o)
      this._append`L${this._x1 = t},${this._y1 = r}`;
    else {
      let d = i - a, g = s - n, m = l * l + c * c, y = d * d + g * g, x = Math.sqrt(m), b = Math.sqrt(p), k = o * Math.tan((Pa - Math.acos((m + p - y) / (2 * x * b))) / 2), w = k / b, S = k / x;
      Math.abs(w - 1) > ur && this._append`L${t + w * h},${r + w * u}`, this._append`A${o},${o},0,0,${+(u * d > h * g)},${this._x1 = t + S * l},${this._y1 = r + S * c}`;
    }
  }
  arc(t, r, i, s, o, a) {
    if (t = +t, r = +r, i = +i, a = !!a, i < 0) throw new Error(`negative radius: ${i}`);
    let n = i * Math.cos(s), l = i * Math.sin(s), c = t + n, h = r + l, u = 1 ^ a, p = a ? s - o : o - s;
    this._x1 === null ? this._append`M${c},${h}` : (Math.abs(this._x1 - c) > ur || Math.abs(this._y1 - h) > ur) && this._append`L${c},${h}`, i && (p < 0 && (p = p % Ra + Ra), p > _1 ? this._append`A${i},${i},0,1,${u},${t - n},${r - l}A${i},${i},0,1,${u},${this._x1 = c},${this._y1 = h}` : p > ur && this._append`A${i},${i},0,${+(p >= Pa)},${u},${this._x1 = t + i * Math.cos(o)},${this._y1 = r + i * Math.sin(o)}`);
  }
  rect(t, r, i, s) {
    this._append`M${this._x0 = this._x1 = +t},${this._y0 = this._y1 = +r}h${i = +i}v${+s}h${-i}Z`;
  }
  toString() {
    return this._;
  }
}
function Dr(e) {
  return function() {
    return e;
  };
}
const lA = Math.abs, hA = Math.atan2, cA = Math.cos, uA = Math.max, dA = Math.min, pA = Math.sin, fA = Math.sqrt, _h = 1e-12, qn = Math.PI, vh = qn / 2, gA = 2 * qn;
function mA(e) {
  return e > 1 ? 0 : e < -1 ? qn : Math.acos(e);
}
function yA(e) {
  return e >= 1 ? vh : e <= -1 ? -vh : Math.asin(e);
}
function L1(e) {
  let t = 3;
  return e.digits = function(r) {
    if (!arguments.length) return t;
    if (r == null)
      t = null;
    else {
      const i = Math.floor(r);
      if (!(i >= 0)) throw new RangeError(`invalid digits: ${r}`);
      t = i;
    }
    return e;
  }, () => new B1(t);
}
function F1(e) {
  return typeof e == "object" && "length" in e ? e : Array.from(e);
}
function Nu(e) {
  this._context = e;
}
Nu.prototype = {
  areaStart: function() {
    this._line = 0;
  },
  areaEnd: function() {
    this._line = NaN;
  },
  lineStart: function() {
    this._point = 0;
  },
  lineEnd: function() {
    (this._line || this._line !== 0 && this._point === 1) && this._context.closePath(), this._line = 1 - this._line;
  },
  point: function(e, t) {
    switch (e = +e, t = +t, this._point) {
      case 0:
        this._point = 1, this._line ? this._context.lineTo(e, t) : this._context.moveTo(e, t);
        break;
      case 1:
        this._point = 2;
      // falls through
      default:
        this._context.lineTo(e, t);
        break;
    }
  }
};
function $i(e) {
  return new Nu(e);
}
function A1(e) {
  return e[0];
}
function M1(e) {
  return e[1];
}
function E1(e, t) {
  var r = Dr(!0), i = null, s = $i, o = null, a = L1(n);
  e = typeof e == "function" ? e : e === void 0 ? A1 : Dr(e), t = typeof t == "function" ? t : t === void 0 ? M1 : Dr(t);
  function n(l) {
    var c, h = (l = F1(l)).length, u, p = !1, d;
    for (i == null && (o = s(d = a())), c = 0; c <= h; ++c)
      !(c < h && r(u = l[c], c, l)) === p && ((p = !p) ? o.lineStart() : o.lineEnd()), p && o.point(+e(u, c, l), +t(u, c, l));
    if (d) return o = null, d + "" || null;
  }
  return n.x = function(l) {
    return arguments.length ? (e = typeof l == "function" ? l : Dr(+l), n) : e;
  }, n.y = function(l) {
    return arguments.length ? (t = typeof l == "function" ? l : Dr(+l), n) : t;
  }, n.defined = function(l) {
    return arguments.length ? (r = typeof l == "function" ? l : Dr(!!l), n) : r;
  }, n.curve = function(l) {
    return arguments.length ? (s = l, i != null && (o = s(i)), n) : s;
  }, n.context = function(l) {
    return arguments.length ? (l == null ? i = o = null : o = s(i = l), n) : i;
  }, n;
}
class qu {
  constructor(t, r) {
    this._context = t, this._x = r;
  }
  areaStart() {
    this._line = 0;
  }
  areaEnd() {
    this._line = NaN;
  }
  lineStart() {
    this._point = 0;
  }
  lineEnd() {
    (this._line || this._line !== 0 && this._point === 1) && this._context.closePath(), this._line = 1 - this._line;
  }
  point(t, r) {
    switch (t = +t, r = +r, this._point) {
      case 0: {
        this._point = 1, this._line ? this._context.lineTo(t, r) : this._context.moveTo(t, r);
        break;
      }
      case 1:
        this._point = 2;
      // falls through
      default: {
        this._x ? this._context.bezierCurveTo(this._x0 = (this._x0 + t) / 2, this._y0, this._x0, r, t, r) : this._context.bezierCurveTo(this._x0, this._y0 = (this._y0 + r) / 2, t, this._y0, t, r);
        break;
      }
    }
    this._x0 = t, this._y0 = r;
  }
}
function zu(e) {
  return new qu(e, !0);
}
function Wu(e) {
  return new qu(e, !1);
}
function er() {
}
function Xs(e, t, r) {
  e._context.bezierCurveTo(
    (2 * e._x0 + e._x1) / 3,
    (2 * e._y0 + e._y1) / 3,
    (e._x0 + 2 * e._x1) / 3,
    (e._y0 + 2 * e._y1) / 3,
    (e._x0 + 4 * e._x1 + t) / 6,
    (e._y0 + 4 * e._y1 + r) / 6
  );
}
function So(e) {
  this._context = e;
}
So.prototype = {
  areaStart: function() {
    this._line = 0;
  },
  areaEnd: function() {
    this._line = NaN;
  },
  lineStart: function() {
    this._x0 = this._x1 = this._y0 = this._y1 = NaN, this._point = 0;
  },
  lineEnd: function() {
    switch (this._point) {
      case 3:
        Xs(this, this._x1, this._y1);
      // falls through
      case 2:
        this._context.lineTo(this._x1, this._y1);
        break;
    }
    (this._line || this._line !== 0 && this._point === 1) && this._context.closePath(), this._line = 1 - this._line;
  },
  point: function(e, t) {
    switch (e = +e, t = +t, this._point) {
      case 0:
        this._point = 1, this._line ? this._context.lineTo(e, t) : this._context.moveTo(e, t);
        break;
      case 1:
        this._point = 2;
        break;
      case 2:
        this._point = 3, this._context.lineTo((5 * this._x0 + this._x1) / 6, (5 * this._y0 + this._y1) / 6);
      // falls through
      default:
        Xs(this, e, t);
        break;
    }
    this._x0 = this._x1, this._x1 = e, this._y0 = this._y1, this._y1 = t;
  }
};
function Na(e) {
  return new So(e);
}
function Hu(e) {
  this._context = e;
}
Hu.prototype = {
  areaStart: er,
  areaEnd: er,
  lineStart: function() {
    this._x0 = this._x1 = this._x2 = this._x3 = this._x4 = this._y0 = this._y1 = this._y2 = this._y3 = this._y4 = NaN, this._point = 0;
  },
  lineEnd: function() {
    switch (this._point) {
      case 1: {
        this._context.moveTo(this._x2, this._y2), this._context.closePath();
        break;
      }
      case 2: {
        this._context.moveTo((this._x2 + 2 * this._x3) / 3, (this._y2 + 2 * this._y3) / 3), this._context.lineTo((this._x3 + 2 * this._x2) / 3, (this._y3 + 2 * this._y2) / 3), this._context.closePath();
        break;
      }
      case 3: {
        this.point(this._x2, this._y2), this.point(this._x3, this._y3), this.point(this._x4, this._y4);
        break;
      }
    }
  },
  point: function(e, t) {
    switch (e = +e, t = +t, this._point) {
      case 0:
        this._point = 1, this._x2 = e, this._y2 = t;
        break;
      case 1:
        this._point = 2, this._x3 = e, this._y3 = t;
        break;
      case 2:
        this._point = 3, this._x4 = e, this._y4 = t, this._context.moveTo((this._x0 + 4 * this._x1 + e) / 6, (this._y0 + 4 * this._y1 + t) / 6);
        break;
      default:
        Xs(this, e, t);
        break;
    }
    this._x0 = this._x1, this._x1 = e, this._y0 = this._y1, this._y1 = t;
  }
};
function $1(e) {
  return new Hu(e);
}
function Yu(e) {
  this._context = e;
}
Yu.prototype = {
  areaStart: function() {
    this._line = 0;
  },
  areaEnd: function() {
    this._line = NaN;
  },
  lineStart: function() {
    this._x0 = this._x1 = this._y0 = this._y1 = NaN, this._point = 0;
  },
  lineEnd: function() {
    (this._line || this._line !== 0 && this._point === 3) && this._context.closePath(), this._line = 1 - this._line;
  },
  point: function(e, t) {
    switch (e = +e, t = +t, this._point) {
      case 0:
        this._point = 1;
        break;
      case 1:
        this._point = 2;
        break;
      case 2:
        this._point = 3;
        var r = (this._x0 + 4 * this._x1 + e) / 6, i = (this._y0 + 4 * this._y1 + t) / 6;
        this._line ? this._context.lineTo(r, i) : this._context.moveTo(r, i);
        break;
      case 3:
        this._point = 4;
      // falls through
      default:
        Xs(this, e, t);
        break;
    }
    this._x0 = this._x1, this._x1 = e, this._y0 = this._y1, this._y1 = t;
  }
};
function O1(e) {
  return new Yu(e);
}
function ju(e, t) {
  this._basis = new So(e), this._beta = t;
}
ju.prototype = {
  lineStart: function() {
    this._x = [], this._y = [], this._basis.lineStart();
  },
  lineEnd: function() {
    var e = this._x, t = this._y, r = e.length - 1;
    if (r > 0)
      for (var i = e[0], s = t[0], o = e[r] - i, a = t[r] - s, n = -1, l; ++n <= r; )
        l = n / r, this._basis.point(
          this._beta * e[n] + (1 - this._beta) * (i + l * o),
          this._beta * t[n] + (1 - this._beta) * (s + l * a)
        );
    this._x = this._y = null, this._basis.lineEnd();
  },
  point: function(e, t) {
    this._x.push(+e), this._y.push(+t);
  }
};
const I1 = (function e(t) {
  function r(i) {
    return t === 1 ? new So(i) : new ju(i, t);
  }
  return r.beta = function(i) {
    return e(+i);
  }, r;
})(0.85);
function Vs(e, t, r) {
  e._context.bezierCurveTo(
    e._x1 + e._k * (e._x2 - e._x0),
    e._y1 + e._k * (e._y2 - e._y0),
    e._x2 + e._k * (e._x1 - t),
    e._y2 + e._k * (e._y1 - r),
    e._x2,
    e._y2
  );
}
function zn(e, t) {
  this._context = e, this._k = (1 - t) / 6;
}
zn.prototype = {
  areaStart: function() {
    this._line = 0;
  },
  areaEnd: function() {
    this._line = NaN;
  },
  lineStart: function() {
    this._x0 = this._x1 = this._x2 = this._y0 = this._y1 = this._y2 = NaN, this._point = 0;
  },
  lineEnd: function() {
    switch (this._point) {
      case 2:
        this._context.lineTo(this._x2, this._y2);
        break;
      case 3:
        Vs(this, this._x1, this._y1);
        break;
    }
    (this._line || this._line !== 0 && this._point === 1) && this._context.closePath(), this._line = 1 - this._line;
  },
  point: function(e, t) {
    switch (e = +e, t = +t, this._point) {
      case 0:
        this._point = 1, this._line ? this._context.lineTo(e, t) : this._context.moveTo(e, t);
        break;
      case 1:
        this._point = 2, this._x1 = e, this._y1 = t;
        break;
      case 2:
        this._point = 3;
      // falls through
      default:
        Vs(this, e, t);
        break;
    }
    this._x0 = this._x1, this._x1 = this._x2, this._x2 = e, this._y0 = this._y1, this._y1 = this._y2, this._y2 = t;
  }
};
const Uu = (function e(t) {
  function r(i) {
    return new zn(i, t);
  }
  return r.tension = function(i) {
    return e(+i);
  }, r;
})(0);
function Wn(e, t) {
  this._context = e, this._k = (1 - t) / 6;
}
Wn.prototype = {
  areaStart: er,
  areaEnd: er,
  lineStart: function() {
    this._x0 = this._x1 = this._x2 = this._x3 = this._x4 = this._x5 = this._y0 = this._y1 = this._y2 = this._y3 = this._y4 = this._y5 = NaN, this._point = 0;
  },
  lineEnd: function() {
    switch (this._point) {
      case 1: {
        this._context.moveTo(this._x3, this._y3), this._context.closePath();
        break;
      }
      case 2: {
        this._context.lineTo(this._x3, this._y3), this._context.closePath();
        break;
      }
      case 3: {
        this.point(this._x3, this._y3), this.point(this._x4, this._y4), this.point(this._x5, this._y5);
        break;
      }
    }
  },
  point: function(e, t) {
    switch (e = +e, t = +t, this._point) {
      case 0:
        this._point = 1, this._x3 = e, this._y3 = t;
        break;
      case 1:
        this._point = 2, this._context.moveTo(this._x4 = e, this._y4 = t);
        break;
      case 2:
        this._point = 3, this._x5 = e, this._y5 = t;
        break;
      default:
        Vs(this, e, t);
        break;
    }
    this._x0 = this._x1, this._x1 = this._x2, this._x2 = e, this._y0 = this._y1, this._y1 = this._y2, this._y2 = t;
  }
};
const D1 = (function e(t) {
  function r(i) {
    return new Wn(i, t);
  }
  return r.tension = function(i) {
    return e(+i);
  }, r;
})(0);
function Hn(e, t) {
  this._context = e, this._k = (1 - t) / 6;
}
Hn.prototype = {
  areaStart: function() {
    this._line = 0;
  },
  areaEnd: function() {
    this._line = NaN;
  },
  lineStart: function() {
    this._x0 = this._x1 = this._x2 = this._y0 = this._y1 = this._y2 = NaN, this._point = 0;
  },
  lineEnd: function() {
    (this._line || this._line !== 0 && this._point === 3) && this._context.closePath(), this._line = 1 - this._line;
  },
  point: function(e, t) {
    switch (e = +e, t = +t, this._point) {
      case 0:
        this._point = 1;
        break;
      case 1:
        this._point = 2;
        break;
      case 2:
        this._point = 3, this._line ? this._context.lineTo(this._x2, this._y2) : this._context.moveTo(this._x2, this._y2);
        break;
      case 3:
        this._point = 4;
      // falls through
      default:
        Vs(this, e, t);
        break;
    }
    this._x0 = this._x1, this._x1 = this._x2, this._x2 = e, this._y0 = this._y1, this._y1 = this._y2, this._y2 = t;
  }
};
const P1 = (function e(t) {
  function r(i) {
    return new Hn(i, t);
  }
  return r.tension = function(i) {
    return e(+i);
  }, r;
})(0);
function Yn(e, t, r) {
  var i = e._x1, s = e._y1, o = e._x2, a = e._y2;
  if (e._l01_a > _h) {
    var n = 2 * e._l01_2a + 3 * e._l01_a * e._l12_a + e._l12_2a, l = 3 * e._l01_a * (e._l01_a + e._l12_a);
    i = (i * n - e._x0 * e._l12_2a + e._x2 * e._l01_2a) / l, s = (s * n - e._y0 * e._l12_2a + e._y2 * e._l01_2a) / l;
  }
  if (e._l23_a > _h) {
    var c = 2 * e._l23_2a + 3 * e._l23_a * e._l12_a + e._l12_2a, h = 3 * e._l23_a * (e._l23_a + e._l12_a);
    o = (o * c + e._x1 * e._l23_2a - t * e._l12_2a) / h, a = (a * c + e._y1 * e._l23_2a - r * e._l12_2a) / h;
  }
  e._context.bezierCurveTo(i, s, o, a, e._x2, e._y2);
}
function Gu(e, t) {
  this._context = e, this._alpha = t;
}
Gu.prototype = {
  areaStart: function() {
    this._line = 0;
  },
  areaEnd: function() {
    this._line = NaN;
  },
  lineStart: function() {
    this._x0 = this._x1 = this._x2 = this._y0 = this._y1 = this._y2 = NaN, this._l01_a = this._l12_a = this._l23_a = this._l01_2a = this._l12_2a = this._l23_2a = this._point = 0;
  },
  lineEnd: function() {
    switch (this._point) {
      case 2:
        this._context.lineTo(this._x2, this._y2);
        break;
      case 3:
        this.point(this._x2, this._y2);
        break;
    }
    (this._line || this._line !== 0 && this._point === 1) && this._context.closePath(), this._line = 1 - this._line;
  },
  point: function(e, t) {
    if (e = +e, t = +t, this._point) {
      var r = this._x2 - e, i = this._y2 - t;
      this._l23_a = Math.sqrt(this._l23_2a = Math.pow(r * r + i * i, this._alpha));
    }
    switch (this._point) {
      case 0:
        this._point = 1, this._line ? this._context.lineTo(e, t) : this._context.moveTo(e, t);
        break;
      case 1:
        this._point = 2;
        break;
      case 2:
        this._point = 3;
      // falls through
      default:
        Yn(this, e, t);
        break;
    }
    this._l01_a = this._l12_a, this._l12_a = this._l23_a, this._l01_2a = this._l12_2a, this._l12_2a = this._l23_2a, this._x0 = this._x1, this._x1 = this._x2, this._x2 = e, this._y0 = this._y1, this._y1 = this._y2, this._y2 = t;
  }
};
const Xu = (function e(t) {
  function r(i) {
    return t ? new Gu(i, t) : new zn(i, 0);
  }
  return r.alpha = function(i) {
    return e(+i);
  }, r;
})(0.5);
function Vu(e, t) {
  this._context = e, this._alpha = t;
}
Vu.prototype = {
  areaStart: er,
  areaEnd: er,
  lineStart: function() {
    this._x0 = this._x1 = this._x2 = this._x3 = this._x4 = this._x5 = this._y0 = this._y1 = this._y2 = this._y3 = this._y4 = this._y5 = NaN, this._l01_a = this._l12_a = this._l23_a = this._l01_2a = this._l12_2a = this._l23_2a = this._point = 0;
  },
  lineEnd: function() {
    switch (this._point) {
      case 1: {
        this._context.moveTo(this._x3, this._y3), this._context.closePath();
        break;
      }
      case 2: {
        this._context.lineTo(this._x3, this._y3), this._context.closePath();
        break;
      }
      case 3: {
        this.point(this._x3, this._y3), this.point(this._x4, this._y4), this.point(this._x5, this._y5);
        break;
      }
    }
  },
  point: function(e, t) {
    if (e = +e, t = +t, this._point) {
      var r = this._x2 - e, i = this._y2 - t;
      this._l23_a = Math.sqrt(this._l23_2a = Math.pow(r * r + i * i, this._alpha));
    }
    switch (this._point) {
      case 0:
        this._point = 1, this._x3 = e, this._y3 = t;
        break;
      case 1:
        this._point = 2, this._context.moveTo(this._x4 = e, this._y4 = t);
        break;
      case 2:
        this._point = 3, this._x5 = e, this._y5 = t;
        break;
      default:
        Yn(this, e, t);
        break;
    }
    this._l01_a = this._l12_a, this._l12_a = this._l23_a, this._l01_2a = this._l12_2a, this._l12_2a = this._l23_2a, this._x0 = this._x1, this._x1 = this._x2, this._x2 = e, this._y0 = this._y1, this._y1 = this._y2, this._y2 = t;
  }
};
const R1 = (function e(t) {
  function r(i) {
    return t ? new Vu(i, t) : new Wn(i, 0);
  }
  return r.alpha = function(i) {
    return e(+i);
  }, r;
})(0.5);
function Zu(e, t) {
  this._context = e, this._alpha = t;
}
Zu.prototype = {
  areaStart: function() {
    this._line = 0;
  },
  areaEnd: function() {
    this._line = NaN;
  },
  lineStart: function() {
    this._x0 = this._x1 = this._x2 = this._y0 = this._y1 = this._y2 = NaN, this._l01_a = this._l12_a = this._l23_a = this._l01_2a = this._l12_2a = this._l23_2a = this._point = 0;
  },
  lineEnd: function() {
    (this._line || this._line !== 0 && this._point === 3) && this._context.closePath(), this._line = 1 - this._line;
  },
  point: function(e, t) {
    if (e = +e, t = +t, this._point) {
      var r = this._x2 - e, i = this._y2 - t;
      this._l23_a = Math.sqrt(this._l23_2a = Math.pow(r * r + i * i, this._alpha));
    }
    switch (this._point) {
      case 0:
        this._point = 1;
        break;
      case 1:
        this._point = 2;
        break;
      case 2:
        this._point = 3, this._line ? this._context.lineTo(this._x2, this._y2) : this._context.moveTo(this._x2, this._y2);
        break;
      case 3:
        this._point = 4;
      // falls through
      default:
        Yn(this, e, t);
        break;
    }
    this._l01_a = this._l12_a, this._l12_a = this._l23_a, this._l01_2a = this._l12_2a, this._l12_2a = this._l23_2a, this._x0 = this._x1, this._x1 = this._x2, this._x2 = e, this._y0 = this._y1, this._y1 = this._y2, this._y2 = t;
  }
};
const N1 = (function e(t) {
  function r(i) {
    return t ? new Zu(i, t) : new Hn(i, 0);
  }
  return r.alpha = function(i) {
    return e(+i);
  }, r;
})(0.5);
function Ku(e) {
  this._context = e;
}
Ku.prototype = {
  areaStart: er,
  areaEnd: er,
  lineStart: function() {
    this._point = 0;
  },
  lineEnd: function() {
    this._point && this._context.closePath();
  },
  point: function(e, t) {
    e = +e, t = +t, this._point ? this._context.lineTo(e, t) : (this._point = 1, this._context.moveTo(e, t));
  }
};
function q1(e) {
  return new Ku(e);
}
function Bh(e) {
  return e < 0 ? -1 : 1;
}
function Lh(e, t, r) {
  var i = e._x1 - e._x0, s = t - e._x1, o = (e._y1 - e._y0) / (i || s < 0 && -0), a = (r - e._y1) / (s || i < 0 && -0), n = (o * s + a * i) / (i + s);
  return (Bh(o) + Bh(a)) * Math.min(Math.abs(o), Math.abs(a), 0.5 * Math.abs(n)) || 0;
}
function Fh(e, t) {
  var r = e._x1 - e._x0;
  return r ? (3 * (e._y1 - e._y0) / r - t) / 2 : t;
}
function ha(e, t, r) {
  var i = e._x0, s = e._y0, o = e._x1, a = e._y1, n = (o - i) / 3;
  e._context.bezierCurveTo(i + n, s + n * t, o - n, a - n * r, o, a);
}
function Zs(e) {
  this._context = e;
}
Zs.prototype = {
  areaStart: function() {
    this._line = 0;
  },
  areaEnd: function() {
    this._line = NaN;
  },
  lineStart: function() {
    this._x0 = this._x1 = this._y0 = this._y1 = this._t0 = NaN, this._point = 0;
  },
  lineEnd: function() {
    switch (this._point) {
      case 2:
        this._context.lineTo(this._x1, this._y1);
        break;
      case 3:
        ha(this, this._t0, Fh(this, this._t0));
        break;
    }
    (this._line || this._line !== 0 && this._point === 1) && this._context.closePath(), this._line = 1 - this._line;
  },
  point: function(e, t) {
    var r = NaN;
    if (e = +e, t = +t, !(e === this._x1 && t === this._y1)) {
      switch (this._point) {
        case 0:
          this._point = 1, this._line ? this._context.lineTo(e, t) : this._context.moveTo(e, t);
          break;
        case 1:
          this._point = 2;
          break;
        case 2:
          this._point = 3, ha(this, Fh(this, r = Lh(this, e, t)), r);
          break;
        default:
          ha(this, this._t0, r = Lh(this, e, t));
          break;
      }
      this._x0 = this._x1, this._x1 = e, this._y0 = this._y1, this._y1 = t, this._t0 = r;
    }
  }
};
function Qu(e) {
  this._context = new Ju(e);
}
(Qu.prototype = Object.create(Zs.prototype)).point = function(e, t) {
  Zs.prototype.point.call(this, t, e);
};
function Ju(e) {
  this._context = e;
}
Ju.prototype = {
  moveTo: function(e, t) {
    this._context.moveTo(t, e);
  },
  closePath: function() {
    this._context.closePath();
  },
  lineTo: function(e, t) {
    this._context.lineTo(t, e);
  },
  bezierCurveTo: function(e, t, r, i, s, o) {
    this._context.bezierCurveTo(t, e, i, r, o, s);
  }
};
function td(e) {
  return new Zs(e);
}
function ed(e) {
  return new Qu(e);
}
function rd(e) {
  this._context = e;
}
rd.prototype = {
  areaStart: function() {
    this._line = 0;
  },
  areaEnd: function() {
    this._line = NaN;
  },
  lineStart: function() {
    this._x = [], this._y = [];
  },
  lineEnd: function() {
    var e = this._x, t = this._y, r = e.length;
    if (r)
      if (this._line ? this._context.lineTo(e[0], t[0]) : this._context.moveTo(e[0], t[0]), r === 2)
        this._context.lineTo(e[1], t[1]);
      else
        for (var i = Ah(e), s = Ah(t), o = 0, a = 1; a < r; ++o, ++a)
          this._context.bezierCurveTo(i[0][o], s[0][o], i[1][o], s[1][o], e[a], t[a]);
    (this._line || this._line !== 0 && r === 1) && this._context.closePath(), this._line = 1 - this._line, this._x = this._y = null;
  },
  point: function(e, t) {
    this._x.push(+e), this._y.push(+t);
  }
};
function Ah(e) {
  var t, r = e.length - 1, i, s = new Array(r), o = new Array(r), a = new Array(r);
  for (s[0] = 0, o[0] = 2, a[0] = e[0] + 2 * e[1], t = 1; t < r - 1; ++t) s[t] = 1, o[t] = 4, a[t] = 4 * e[t] + 2 * e[t + 1];
  for (s[r - 1] = 2, o[r - 1] = 7, a[r - 1] = 8 * e[r - 1] + e[r], t = 1; t < r; ++t) i = s[t] / o[t - 1], o[t] -= i, a[t] -= i * a[t - 1];
  for (s[r - 1] = a[r - 1] / o[r - 1], t = r - 2; t >= 0; --t) s[t] = (a[t] - s[t + 1]) / o[t];
  for (o[r - 1] = (e[r] + s[r - 1]) / 2, t = 0; t < r - 1; ++t) o[t] = 2 * e[t + 1] - s[t + 1];
  return [s, o];
}
function id(e) {
  return new rd(e);
}
function _o(e, t) {
  this._context = e, this._t = t;
}
_o.prototype = {
  areaStart: function() {
    this._line = 0;
  },
  areaEnd: function() {
    this._line = NaN;
  },
  lineStart: function() {
    this._x = this._y = NaN, this._point = 0;
  },
  lineEnd: function() {
    0 < this._t && this._t < 1 && this._point === 2 && this._context.lineTo(this._x, this._y), (this._line || this._line !== 0 && this._point === 1) && this._context.closePath(), this._line >= 0 && (this._t = 1 - this._t, this._line = 1 - this._line);
  },
  point: function(e, t) {
    switch (e = +e, t = +t, this._point) {
      case 0:
        this._point = 1, this._line ? this._context.lineTo(e, t) : this._context.moveTo(e, t);
        break;
      case 1:
        this._point = 2;
      // falls through
      default: {
        if (this._t <= 0)
          this._context.lineTo(this._x, t), this._context.lineTo(e, t);
        else {
          var r = this._x * (1 - this._t) + e * this._t;
          this._context.lineTo(r, this._y), this._context.lineTo(r, t);
        }
        break;
      }
    }
    this._x = e, this._y = t;
  }
};
function sd(e) {
  return new _o(e, 0.5);
}
function od(e) {
  return new _o(e, 0);
}
function ad(e) {
  return new _o(e, 1);
}
function _i(e, t, r) {
  this.k = e, this.x = t, this.y = r;
}
_i.prototype = {
  constructor: _i,
  scale: function(e) {
    return e === 1 ? this : new _i(this.k * e, this.x, this.y);
  },
  translate: function(e, t) {
    return e === 0 & t === 0 ? this : new _i(this.k, this.x + this.k * e, this.y + this.k * t);
  },
  apply: function(e) {
    return [e[0] * this.k + this.x, e[1] * this.k + this.y];
  },
  applyX: function(e) {
    return e * this.k + this.x;
  },
  applyY: function(e) {
    return e * this.k + this.y;
  },
  invert: function(e) {
    return [(e[0] - this.x) / this.k, (e[1] - this.y) / this.k];
  },
  invertX: function(e) {
    return (e - this.x) / this.k;
  },
  invertY: function(e) {
    return (e - this.y) / this.k;
  },
  rescaleX: function(e) {
    return e.copy().domain(e.range().map(this.invertX, this).map(e.invert, e));
  },
  rescaleY: function(e) {
    return e.copy().domain(e.range().map(this.invertY, this).map(e.invert, e));
  },
  toString: function() {
    return "translate(" + this.x + "," + this.y + ") scale(" + this.k + ")";
  }
};
_i.prototype;
var z1 = /* @__PURE__ */ f((e) => {
  const { securityLevel: t } = gt();
  let r = ct("body");
  if (t === "sandbox") {
    const o = ct(`#i${e}`).node()?.contentDocument ?? document;
    r = ct(o.body);
  }
  return r.select(`#${e}`);
}, "selectSvgElement");
function jn(e) {
  return typeof e > "u" || e === null;
}
f(jn, "isNothing");
function nd(e) {
  return typeof e == "object" && e !== null;
}
f(nd, "isObject");
function ld(e) {
  return Array.isArray(e) ? e : jn(e) ? [] : [e];
}
f(ld, "toArray");
function hd(e, t) {
  var r, i, s, o;
  if (t)
    for (o = Object.keys(t), r = 0, i = o.length; r < i; r += 1)
      s = o[r], e[s] = t[s];
  return e;
}
f(hd, "extend");
function cd(e, t) {
  var r = "", i;
  for (i = 0; i < t; i += 1)
    r += e;
  return r;
}
f(cd, "repeat");
function ud(e) {
  return e === 0 && Number.NEGATIVE_INFINITY === 1 / e;
}
f(ud, "isNegativeZero");
var W1 = jn, H1 = nd, Y1 = ld, j1 = cd, U1 = ud, G1 = hd, Ot = {
  isNothing: W1,
  isObject: H1,
  toArray: Y1,
  repeat: j1,
  isNegativeZero: U1,
  extend: G1
};
function Un(e, t) {
  var r = "", i = e.reason || "(unknown reason)";
  return e.mark ? (e.mark.name && (r += 'in "' + e.mark.name + '" '), r += "(" + (e.mark.line + 1) + ":" + (e.mark.column + 1) + ")", !t && e.mark.snippet && (r += `

` + e.mark.snippet), i + " " + r) : i;
}
f(Un, "formatError");
function Qr(e, t) {
  Error.call(this), this.name = "YAMLException", this.reason = e, this.mark = t, this.message = Un(this, !1), Error.captureStackTrace ? Error.captureStackTrace(this, this.constructor) : this.stack = new Error().stack || "";
}
f(Qr, "YAMLException$1");
Qr.prototype = Object.create(Error.prototype);
Qr.prototype.constructor = Qr;
Qr.prototype.toString = /* @__PURE__ */ f(function(t) {
  return this.name + ": " + Un(this, t);
}, "toString");
var te = Qr;
function Ms(e, t, r, i, s) {
  var o = "", a = "", n = Math.floor(s / 2) - 1;
  return i - t > n && (o = " ... ", t = i - n + o.length), r - i > n && (a = " ...", r = i + n - a.length), {
    str: o + e.slice(t, r).replace(/\t/g, "→") + a,
    pos: i - t + o.length
    // relative position
  };
}
f(Ms, "getLine");
function Es(e, t) {
  return Ot.repeat(" ", t - e.length) + e;
}
f(Es, "padStart");
function dd(e, t) {
  if (t = Object.create(t || null), !e.buffer) return null;
  t.maxLength || (t.maxLength = 79), typeof t.indent != "number" && (t.indent = 1), typeof t.linesBefore != "number" && (t.linesBefore = 3), typeof t.linesAfter != "number" && (t.linesAfter = 2);
  for (var r = /\r?\n|\r|\0/g, i = [0], s = [], o, a = -1; o = r.exec(e.buffer); )
    s.push(o.index), i.push(o.index + o[0].length), e.position <= o.index && a < 0 && (a = i.length - 2);
  a < 0 && (a = i.length - 1);
  var n = "", l, c, h = Math.min(e.line + t.linesAfter, s.length).toString().length, u = t.maxLength - (t.indent + h + 3);
  for (l = 1; l <= t.linesBefore && !(a - l < 0); l++)
    c = Ms(
      e.buffer,
      i[a - l],
      s[a - l],
      e.position - (i[a] - i[a - l]),
      u
    ), n = Ot.repeat(" ", t.indent) + Es((e.line - l + 1).toString(), h) + " | " + c.str + `
` + n;
  for (c = Ms(e.buffer, i[a], s[a], e.position, u), n += Ot.repeat(" ", t.indent) + Es((e.line + 1).toString(), h) + " | " + c.str + `
`, n += Ot.repeat("-", t.indent + h + 3 + c.pos) + `^
`, l = 1; l <= t.linesAfter && !(a + l >= s.length); l++)
    c = Ms(
      e.buffer,
      i[a + l],
      s[a + l],
      e.position - (i[a] - i[a + l]),
      u
    ), n += Ot.repeat(" ", t.indent) + Es((e.line + l + 1).toString(), h) + " | " + c.str + `
`;
  return n.replace(/\n$/, "");
}
f(dd, "makeSnippet");
var X1 = dd, V1 = [
  "kind",
  "multi",
  "resolve",
  "construct",
  "instanceOf",
  "predicate",
  "represent",
  "representName",
  "defaultStyle",
  "styleAliases"
], Z1 = [
  "scalar",
  "sequence",
  "mapping"
];
function pd(e) {
  var t = {};
  return e !== null && Object.keys(e).forEach(function(r) {
    e[r].forEach(function(i) {
      t[String(i)] = r;
    });
  }), t;
}
f(pd, "compileStyleAliases");
function fd(e, t) {
  if (t = t || {}, Object.keys(t).forEach(function(r) {
    if (V1.indexOf(r) === -1)
      throw new te('Unknown option "' + r + '" is met in definition of "' + e + '" YAML type.');
  }), this.options = t, this.tag = e, this.kind = t.kind || null, this.resolve = t.resolve || function() {
    return !0;
  }, this.construct = t.construct || function(r) {
    return r;
  }, this.instanceOf = t.instanceOf || null, this.predicate = t.predicate || null, this.represent = t.represent || null, this.representName = t.representName || null, this.defaultStyle = t.defaultStyle || null, this.multi = t.multi || !1, this.styleAliases = pd(t.styleAliases || null), Z1.indexOf(this.kind) === -1)
    throw new te('Unknown kind "' + this.kind + '" is specified for "' + e + '" YAML type.');
}
f(fd, "Type$1");
var Ht = fd;
function qa(e, t) {
  var r = [];
  return e[t].forEach(function(i) {
    var s = r.length;
    r.forEach(function(o, a) {
      o.tag === i.tag && o.kind === i.kind && o.multi === i.multi && (s = a);
    }), r[s] = i;
  }), r;
}
f(qa, "compileList");
function gd() {
  var e = {
    scalar: {},
    sequence: {},
    mapping: {},
    fallback: {},
    multi: {
      scalar: [],
      sequence: [],
      mapping: [],
      fallback: []
    }
  }, t, r;
  function i(s) {
    s.multi ? (e.multi[s.kind].push(s), e.multi.fallback.push(s)) : e[s.kind][s.tag] = e.fallback[s.tag] = s;
  }
  for (f(i, "collectType"), t = 0, r = arguments.length; t < r; t += 1)
    arguments[t].forEach(i);
  return e;
}
f(gd, "compileMap");
function Ks(e) {
  return this.extend(e);
}
f(Ks, "Schema$1");
Ks.prototype.extend = /* @__PURE__ */ f(function(t) {
  var r = [], i = [];
  if (t instanceof Ht)
    i.push(t);
  else if (Array.isArray(t))
    i = i.concat(t);
  else if (t && (Array.isArray(t.implicit) || Array.isArray(t.explicit)))
    t.implicit && (r = r.concat(t.implicit)), t.explicit && (i = i.concat(t.explicit));
  else
    throw new te("Schema.extend argument should be a Type, [ Type ], or a schema definition ({ implicit: [...], explicit: [...] })");
  r.forEach(function(o) {
    if (!(o instanceof Ht))
      throw new te("Specified list of YAML types (or a single Type object) contains a non-Type object.");
    if (o.loadKind && o.loadKind !== "scalar")
      throw new te("There is a non-scalar type in the implicit list of a schema. Implicit resolving of such types is not supported.");
    if (o.multi)
      throw new te("There is a multi type in the implicit list of a schema. Multi tags can only be listed as explicit.");
  }), i.forEach(function(o) {
    if (!(o instanceof Ht))
      throw new te("Specified list of YAML types (or a single Type object) contains a non-Type object.");
  });
  var s = Object.create(Ks.prototype);
  return s.implicit = (this.implicit || []).concat(r), s.explicit = (this.explicit || []).concat(i), s.compiledImplicit = qa(s, "implicit"), s.compiledExplicit = qa(s, "explicit"), s.compiledTypeMap = gd(s.compiledImplicit, s.compiledExplicit), s;
}, "extend");
var K1 = Ks, Q1 = new Ht("tag:yaml.org,2002:str", {
  kind: "scalar",
  construct: /* @__PURE__ */ f(function(e) {
    return e !== null ? e : "";
  }, "construct")
}), J1 = new Ht("tag:yaml.org,2002:seq", {
  kind: "sequence",
  construct: /* @__PURE__ */ f(function(e) {
    return e !== null ? e : [];
  }, "construct")
}), tk = new Ht("tag:yaml.org,2002:map", {
  kind: "mapping",
  construct: /* @__PURE__ */ f(function(e) {
    return e !== null ? e : {};
  }, "construct")
}), ek = new K1({
  explicit: [
    Q1,
    J1,
    tk
  ]
});
function md(e) {
  if (e === null) return !0;
  var t = e.length;
  return t === 1 && e === "~" || t === 4 && (e === "null" || e === "Null" || e === "NULL");
}
f(md, "resolveYamlNull");
function yd() {
  return null;
}
f(yd, "constructYamlNull");
function Cd(e) {
  return e === null;
}
f(Cd, "isNull");
var rk = new Ht("tag:yaml.org,2002:null", {
  kind: "scalar",
  resolve: md,
  construct: yd,
  predicate: Cd,
  represent: {
    canonical: /* @__PURE__ */ f(function() {
      return "~";
    }, "canonical"),
    lowercase: /* @__PURE__ */ f(function() {
      return "null";
    }, "lowercase"),
    uppercase: /* @__PURE__ */ f(function() {
      return "NULL";
    }, "uppercase"),
    camelcase: /* @__PURE__ */ f(function() {
      return "Null";
    }, "camelcase"),
    empty: /* @__PURE__ */ f(function() {
      return "";
    }, "empty")
  },
  defaultStyle: "lowercase"
});
function xd(e) {
  if (e === null) return !1;
  var t = e.length;
  return t === 4 && (e === "true" || e === "True" || e === "TRUE") || t === 5 && (e === "false" || e === "False" || e === "FALSE");
}
f(xd, "resolveYamlBoolean");
function bd(e) {
  return e === "true" || e === "True" || e === "TRUE";
}
f(bd, "constructYamlBoolean");
function kd(e) {
  return Object.prototype.toString.call(e) === "[object Boolean]";
}
f(kd, "isBoolean");
var ik = new Ht("tag:yaml.org,2002:bool", {
  kind: "scalar",
  resolve: xd,
  construct: bd,
  predicate: kd,
  represent: {
    lowercase: /* @__PURE__ */ f(function(e) {
      return e ? "true" : "false";
    }, "lowercase"),
    uppercase: /* @__PURE__ */ f(function(e) {
      return e ? "TRUE" : "FALSE";
    }, "uppercase"),
    camelcase: /* @__PURE__ */ f(function(e) {
      return e ? "True" : "False";
    }, "camelcase")
  },
  defaultStyle: "lowercase"
});
function Td(e) {
  return 48 <= e && e <= 57 || 65 <= e && e <= 70 || 97 <= e && e <= 102;
}
f(Td, "isHexCode");
function wd(e) {
  return 48 <= e && e <= 55;
}
f(wd, "isOctCode");
function Sd(e) {
  return 48 <= e && e <= 57;
}
f(Sd, "isDecCode");
function _d(e) {
  if (e === null) return !1;
  var t = e.length, r = 0, i = !1, s;
  if (!t) return !1;
  if (s = e[r], (s === "-" || s === "+") && (s = e[++r]), s === "0") {
    if (r + 1 === t) return !0;
    if (s = e[++r], s === "b") {
      for (r++; r < t; r++)
        if (s = e[r], s !== "_") {
          if (s !== "0" && s !== "1") return !1;
          i = !0;
        }
      return i && s !== "_";
    }
    if (s === "x") {
      for (r++; r < t; r++)
        if (s = e[r], s !== "_") {
          if (!Td(e.charCodeAt(r))) return !1;
          i = !0;
        }
      return i && s !== "_";
    }
    if (s === "o") {
      for (r++; r < t; r++)
        if (s = e[r], s !== "_") {
          if (!wd(e.charCodeAt(r))) return !1;
          i = !0;
        }
      return i && s !== "_";
    }
  }
  if (s === "_") return !1;
  for (; r < t; r++)
    if (s = e[r], s !== "_") {
      if (!Sd(e.charCodeAt(r)))
        return !1;
      i = !0;
    }
  return !(!i || s === "_");
}
f(_d, "resolveYamlInteger");
function vd(e) {
  var t = e, r = 1, i;
  if (t.indexOf("_") !== -1 && (t = t.replace(/_/g, "")), i = t[0], (i === "-" || i === "+") && (i === "-" && (r = -1), t = t.slice(1), i = t[0]), t === "0") return 0;
  if (i === "0") {
    if (t[1] === "b") return r * parseInt(t.slice(2), 2);
    if (t[1] === "x") return r * parseInt(t.slice(2), 16);
    if (t[1] === "o") return r * parseInt(t.slice(2), 8);
  }
  return r * parseInt(t, 10);
}
f(vd, "constructYamlInteger");
function Bd(e) {
  return Object.prototype.toString.call(e) === "[object Number]" && e % 1 === 0 && !Ot.isNegativeZero(e);
}
f(Bd, "isInteger");
var sk = new Ht("tag:yaml.org,2002:int", {
  kind: "scalar",
  resolve: _d,
  construct: vd,
  predicate: Bd,
  represent: {
    binary: /* @__PURE__ */ f(function(e) {
      return e >= 0 ? "0b" + e.toString(2) : "-0b" + e.toString(2).slice(1);
    }, "binary"),
    octal: /* @__PURE__ */ f(function(e) {
      return e >= 0 ? "0o" + e.toString(8) : "-0o" + e.toString(8).slice(1);
    }, "octal"),
    decimal: /* @__PURE__ */ f(function(e) {
      return e.toString(10);
    }, "decimal"),
    /* eslint-disable max-len */
    hexadecimal: /* @__PURE__ */ f(function(e) {
      return e >= 0 ? "0x" + e.toString(16).toUpperCase() : "-0x" + e.toString(16).toUpperCase().slice(1);
    }, "hexadecimal")
  },
  defaultStyle: "decimal",
  styleAliases: {
    binary: [2, "bin"],
    octal: [8, "oct"],
    decimal: [10, "dec"],
    hexadecimal: [16, "hex"]
  }
}), ok = new RegExp(
  // 2.5e4, 2.5 and integers
  "^(?:[-+]?(?:[0-9][0-9_]*)(?:\\.[0-9_]*)?(?:[eE][-+]?[0-9]+)?|\\.[0-9_]+(?:[eE][-+]?[0-9]+)?|[-+]?\\.(?:inf|Inf|INF)|\\.(?:nan|NaN|NAN))$"
);
function Ld(e) {
  return !(e === null || !ok.test(e) || // Quick hack to not allow integers end with `_`
  // Probably should update regexp & check speed
  e[e.length - 1] === "_");
}
f(Ld, "resolveYamlFloat");
function Fd(e) {
  var t, r;
  return t = e.replace(/_/g, "").toLowerCase(), r = t[0] === "-" ? -1 : 1, "+-".indexOf(t[0]) >= 0 && (t = t.slice(1)), t === ".inf" ? r === 1 ? Number.POSITIVE_INFINITY : Number.NEGATIVE_INFINITY : t === ".nan" ? NaN : r * parseFloat(t, 10);
}
f(Fd, "constructYamlFloat");
var ak = /^[-+]?[0-9]+e/;
function Ad(e, t) {
  var r;
  if (isNaN(e))
    switch (t) {
      case "lowercase":
        return ".nan";
      case "uppercase":
        return ".NAN";
      case "camelcase":
        return ".NaN";
    }
  else if (Number.POSITIVE_INFINITY === e)
    switch (t) {
      case "lowercase":
        return ".inf";
      case "uppercase":
        return ".INF";
      case "camelcase":
        return ".Inf";
    }
  else if (Number.NEGATIVE_INFINITY === e)
    switch (t) {
      case "lowercase":
        return "-.inf";
      case "uppercase":
        return "-.INF";
      case "camelcase":
        return "-.Inf";
    }
  else if (Ot.isNegativeZero(e))
    return "-0.0";
  return r = e.toString(10), ak.test(r) ? r.replace("e", ".e") : r;
}
f(Ad, "representYamlFloat");
function Md(e) {
  return Object.prototype.toString.call(e) === "[object Number]" && (e % 1 !== 0 || Ot.isNegativeZero(e));
}
f(Md, "isFloat");
var nk = new Ht("tag:yaml.org,2002:float", {
  kind: "scalar",
  resolve: Ld,
  construct: Fd,
  predicate: Md,
  represent: Ad,
  defaultStyle: "lowercase"
}), Ed = ek.extend({
  implicit: [
    rk,
    ik,
    sk,
    nk
  ]
}), lk = Ed, $d = new RegExp(
  "^([0-9][0-9][0-9][0-9])-([0-9][0-9])-([0-9][0-9])$"
), Od = new RegExp(
  "^([0-9][0-9][0-9][0-9])-([0-9][0-9]?)-([0-9][0-9]?)(?:[Tt]|[ \\t]+)([0-9][0-9]?):([0-9][0-9]):([0-9][0-9])(?:\\.([0-9]*))?(?:[ \\t]*(Z|([-+])([0-9][0-9]?)(?::([0-9][0-9]))?))?$"
);
function Id(e) {
  return e === null ? !1 : $d.exec(e) !== null || Od.exec(e) !== null;
}
f(Id, "resolveYamlTimestamp");
function Dd(e) {
  var t, r, i, s, o, a, n, l = 0, c = null, h, u, p;
  if (t = $d.exec(e), t === null && (t = Od.exec(e)), t === null) throw new Error("Date resolve error");
  if (r = +t[1], i = +t[2] - 1, s = +t[3], !t[4])
    return new Date(Date.UTC(r, i, s));
  if (o = +t[4], a = +t[5], n = +t[6], t[7]) {
    for (l = t[7].slice(0, 3); l.length < 3; )
      l += "0";
    l = +l;
  }
  return t[9] && (h = +t[10], u = +(t[11] || 0), c = (h * 60 + u) * 6e4, t[9] === "-" && (c = -c)), p = new Date(Date.UTC(r, i, s, o, a, n, l)), c && p.setTime(p.getTime() - c), p;
}
f(Dd, "constructYamlTimestamp");
function Pd(e) {
  return e.toISOString();
}
f(Pd, "representYamlTimestamp");
var hk = new Ht("tag:yaml.org,2002:timestamp", {
  kind: "scalar",
  resolve: Id,
  construct: Dd,
  instanceOf: Date,
  represent: Pd
});
function Rd(e) {
  return e === "<<" || e === null;
}
f(Rd, "resolveYamlMerge");
var ck = new Ht("tag:yaml.org,2002:merge", {
  kind: "scalar",
  resolve: Rd
}), Gn = `ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=
\r`;
function Nd(e) {
  if (e === null) return !1;
  var t, r, i = 0, s = e.length, o = Gn;
  for (r = 0; r < s; r++)
    if (t = o.indexOf(e.charAt(r)), !(t > 64)) {
      if (t < 0) return !1;
      i += 6;
    }
  return i % 8 === 0;
}
f(Nd, "resolveYamlBinary");
function qd(e) {
  var t, r, i = e.replace(/[\r\n=]/g, ""), s = i.length, o = Gn, a = 0, n = [];
  for (t = 0; t < s; t++)
    t % 4 === 0 && t && (n.push(a >> 16 & 255), n.push(a >> 8 & 255), n.push(a & 255)), a = a << 6 | o.indexOf(i.charAt(t));
  return r = s % 4 * 6, r === 0 ? (n.push(a >> 16 & 255), n.push(a >> 8 & 255), n.push(a & 255)) : r === 18 ? (n.push(a >> 10 & 255), n.push(a >> 2 & 255)) : r === 12 && n.push(a >> 4 & 255), new Uint8Array(n);
}
f(qd, "constructYamlBinary");
function zd(e) {
  var t = "", r = 0, i, s, o = e.length, a = Gn;
  for (i = 0; i < o; i++)
    i % 3 === 0 && i && (t += a[r >> 18 & 63], t += a[r >> 12 & 63], t += a[r >> 6 & 63], t += a[r & 63]), r = (r << 8) + e[i];
  return s = o % 3, s === 0 ? (t += a[r >> 18 & 63], t += a[r >> 12 & 63], t += a[r >> 6 & 63], t += a[r & 63]) : s === 2 ? (t += a[r >> 10 & 63], t += a[r >> 4 & 63], t += a[r << 2 & 63], t += a[64]) : s === 1 && (t += a[r >> 2 & 63], t += a[r << 4 & 63], t += a[64], t += a[64]), t;
}
f(zd, "representYamlBinary");
function Wd(e) {
  return Object.prototype.toString.call(e) === "[object Uint8Array]";
}
f(Wd, "isBinary");
var uk = new Ht("tag:yaml.org,2002:binary", {
  kind: "scalar",
  resolve: Nd,
  construct: qd,
  predicate: Wd,
  represent: zd
}), dk = Object.prototype.hasOwnProperty, pk = Object.prototype.toString;
function Hd(e) {
  if (e === null) return !0;
  var t = [], r, i, s, o, a, n = e;
  for (r = 0, i = n.length; r < i; r += 1) {
    if (s = n[r], a = !1, pk.call(s) !== "[object Object]") return !1;
    for (o in s)
      if (dk.call(s, o))
        if (!a) a = !0;
        else return !1;
    if (!a) return !1;
    if (t.indexOf(o) === -1) t.push(o);
    else return !1;
  }
  return !0;
}
f(Hd, "resolveYamlOmap");
function Yd(e) {
  return e !== null ? e : [];
}
f(Yd, "constructYamlOmap");
var fk = new Ht("tag:yaml.org,2002:omap", {
  kind: "sequence",
  resolve: Hd,
  construct: Yd
}), gk = Object.prototype.toString;
function jd(e) {
  if (e === null) return !0;
  var t, r, i, s, o, a = e;
  for (o = new Array(a.length), t = 0, r = a.length; t < r; t += 1) {
    if (i = a[t], gk.call(i) !== "[object Object]" || (s = Object.keys(i), s.length !== 1)) return !1;
    o[t] = [s[0], i[s[0]]];
  }
  return !0;
}
f(jd, "resolveYamlPairs");
function Ud(e) {
  if (e === null) return [];
  var t, r, i, s, o, a = e;
  for (o = new Array(a.length), t = 0, r = a.length; t < r; t += 1)
    i = a[t], s = Object.keys(i), o[t] = [s[0], i[s[0]]];
  return o;
}
f(Ud, "constructYamlPairs");
var mk = new Ht("tag:yaml.org,2002:pairs", {
  kind: "sequence",
  resolve: jd,
  construct: Ud
}), yk = Object.prototype.hasOwnProperty;
function Gd(e) {
  if (e === null) return !0;
  var t, r = e;
  for (t in r)
    if (yk.call(r, t) && r[t] !== null)
      return !1;
  return !0;
}
f(Gd, "resolveYamlSet");
function Xd(e) {
  return e !== null ? e : {};
}
f(Xd, "constructYamlSet");
var Ck = new Ht("tag:yaml.org,2002:set", {
  kind: "mapping",
  resolve: Gd,
  construct: Xd
}), Vd = lk.extend({
  implicit: [
    hk,
    ck
  ],
  explicit: [
    uk,
    fk,
    mk,
    Ck
  ]
}), rr = Object.prototype.hasOwnProperty, Qs = 1, Zd = 2, Kd = 3, Js = 4, ca = 1, xk = 2, Mh = 3, bk = /[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x84\x86-\x9F\uFFFE\uFFFF]|[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?:[^\uD800-\uDBFF]|^)[\uDC00-\uDFFF]/, kk = /[\x85\u2028\u2029]/, Tk = /[,\[\]\{\}]/, Qd = /^(?:!|!!|![a-z\-]+!)$/i, Jd = /^(?:!|[^,\[\]\{\}])(?:%[0-9a-f]{2}|[0-9a-z\-#;\/\?:@&=\+\$,_\.!~\*'\(\)\[\]])*$/i;
function za(e) {
  return Object.prototype.toString.call(e);
}
f(za, "_class");
function ye(e) {
  return e === 10 || e === 13;
}
f(ye, "is_EOL");
function tr(e) {
  return e === 9 || e === 32;
}
f(tr, "is_WHITE_SPACE");
function Ut(e) {
  return e === 9 || e === 32 || e === 10 || e === 13;
}
f(Ut, "is_WS_OR_EOL");
function mr(e) {
  return e === 44 || e === 91 || e === 93 || e === 123 || e === 125;
}
f(mr, "is_FLOW_INDICATOR");
function tp(e) {
  var t;
  return 48 <= e && e <= 57 ? e - 48 : (t = e | 32, 97 <= t && t <= 102 ? t - 97 + 10 : -1);
}
f(tp, "fromHexCode");
function ep(e) {
  return e === 120 ? 2 : e === 117 ? 4 : e === 85 ? 8 : 0;
}
f(ep, "escapedHexLen");
function rp(e) {
  return 48 <= e && e <= 57 ? e - 48 : -1;
}
f(rp, "fromDecimalCode");
function Wa(e) {
  return e === 48 ? "\0" : e === 97 ? "\x07" : e === 98 ? "\b" : e === 116 || e === 9 ? "	" : e === 110 ? `
` : e === 118 ? "\v" : e === 102 ? "\f" : e === 114 ? "\r" : e === 101 ? "\x1B" : e === 32 ? " " : e === 34 ? '"' : e === 47 ? "/" : e === 92 ? "\\" : e === 78 ? "" : e === 95 ? " " : e === 76 ? "\u2028" : e === 80 ? "\u2029" : "";
}
f(Wa, "simpleEscapeSequence");
function ip(e) {
  return e <= 65535 ? String.fromCharCode(e) : String.fromCharCode(
    (e - 65536 >> 10) + 55296,
    (e - 65536 & 1023) + 56320
  );
}
f(ip, "charFromCodepoint");
function Xn(e, t, r) {
  t === "__proto__" ? Object.defineProperty(e, t, {
    configurable: !0,
    enumerable: !0,
    writable: !0,
    value: r
  }) : e[t] = r;
}
f(Xn, "setProperty");
var sp = new Array(256), op = new Array(256);
for (hr = 0; hr < 256; hr++)
  sp[hr] = Wa(hr) ? 1 : 0, op[hr] = Wa(hr);
var hr;
function ap(e, t) {
  this.input = e, this.filename = t.filename || null, this.schema = t.schema || Vd, this.onWarning = t.onWarning || null, this.legacy = t.legacy || !1, this.json = t.json || !1, this.listener = t.listener || null, this.implicitTypes = this.schema.compiledImplicit, this.typeMap = this.schema.compiledTypeMap, this.length = e.length, this.position = 0, this.line = 0, this.lineStart = 0, this.lineIndent = 0, this.firstTabInLine = -1, this.documents = [];
}
f(ap, "State$1");
function Vn(e, t) {
  var r = {
    name: e.filename,
    buffer: e.input.slice(0, -1),
    // omit trailing \0
    position: e.position,
    line: e.line,
    column: e.position - e.lineStart
  };
  return r.snippet = X1(r), new te(t, r);
}
f(Vn, "generateError");
function K(e, t) {
  throw Vn(e, t);
}
f(K, "throwError");
function Wi(e, t) {
  e.onWarning && e.onWarning.call(null, Vn(e, t));
}
f(Wi, "throwWarning");
var Eh = {
  YAML: /* @__PURE__ */ f(function(t, r, i) {
    var s, o, a;
    t.version !== null && K(t, "duplication of %YAML directive"), i.length !== 1 && K(t, "YAML directive accepts exactly one argument"), s = /^([0-9]+)\.([0-9]+)$/.exec(i[0]), s === null && K(t, "ill-formed argument of the YAML directive"), o = parseInt(s[1], 10), a = parseInt(s[2], 10), o !== 1 && K(t, "unacceptable YAML version of the document"), t.version = i[0], t.checkLineBreaks = a < 2, a !== 1 && a !== 2 && Wi(t, "unsupported YAML version of the document");
  }, "handleYamlDirective"),
  TAG: /* @__PURE__ */ f(function(t, r, i) {
    var s, o;
    i.length !== 2 && K(t, "TAG directive accepts exactly two arguments"), s = i[0], o = i[1], Qd.test(s) || K(t, "ill-formed tag handle (first argument) of the TAG directive"), rr.call(t.tagMap, s) && K(t, 'there is a previously declared suffix for "' + s + '" tag handle'), Jd.test(o) || K(t, "ill-formed tag prefix (second argument) of the TAG directive");
    try {
      o = decodeURIComponent(o);
    } catch {
      K(t, "tag prefix is malformed: " + o);
    }
    t.tagMap[s] = o;
  }, "handleTagDirective")
};
function ze(e, t, r, i) {
  var s, o, a, n;
  if (t < r) {
    if (n = e.input.slice(t, r), i)
      for (s = 0, o = n.length; s < o; s += 1)
        a = n.charCodeAt(s), a === 9 || 32 <= a && a <= 1114111 || K(e, "expected valid JSON character");
    else bk.test(n) && K(e, "the stream contains non-printable characters");
    e.result += n;
  }
}
f(ze, "captureSegment");
function Ha(e, t, r, i) {
  var s, o, a, n;
  for (Ot.isObject(r) || K(e, "cannot merge mappings; the provided source object is unacceptable"), s = Object.keys(r), a = 0, n = s.length; a < n; a += 1)
    o = s[a], rr.call(t, o) || (Xn(t, o, r[o]), i[o] = !0);
}
f(Ha, "mergeMappings");
function yr(e, t, r, i, s, o, a, n, l) {
  var c, h;
  if (Array.isArray(s))
    for (s = Array.prototype.slice.call(s), c = 0, h = s.length; c < h; c += 1)
      Array.isArray(s[c]) && K(e, "nested arrays are not supported inside keys"), typeof s == "object" && za(s[c]) === "[object Object]" && (s[c] = "[object Object]");
  if (typeof s == "object" && za(s) === "[object Object]" && (s = "[object Object]"), s = String(s), t === null && (t = {}), i === "tag:yaml.org,2002:merge")
    if (Array.isArray(o))
      for (c = 0, h = o.length; c < h; c += 1)
        Ha(e, t, o[c], r);
    else
      Ha(e, t, o, r);
  else
    !e.json && !rr.call(r, s) && rr.call(t, s) && (e.line = a || e.line, e.lineStart = n || e.lineStart, e.position = l || e.position, K(e, "duplicated mapping key")), Xn(t, s, o), delete r[s];
  return t;
}
f(yr, "storeMappingPair");
function vo(e) {
  var t;
  t = e.input.charCodeAt(e.position), t === 10 ? e.position++ : t === 13 ? (e.position++, e.input.charCodeAt(e.position) === 10 && e.position++) : K(e, "a line break is expected"), e.line += 1, e.lineStart = e.position, e.firstTabInLine = -1;
}
f(vo, "readLineBreak");
function vt(e, t, r) {
  for (var i = 0, s = e.input.charCodeAt(e.position); s !== 0; ) {
    for (; tr(s); )
      s === 9 && e.firstTabInLine === -1 && (e.firstTabInLine = e.position), s = e.input.charCodeAt(++e.position);
    if (t && s === 35)
      do
        s = e.input.charCodeAt(++e.position);
      while (s !== 10 && s !== 13 && s !== 0);
    if (ye(s))
      for (vo(e), s = e.input.charCodeAt(e.position), i++, e.lineIndent = 0; s === 32; )
        e.lineIndent++, s = e.input.charCodeAt(++e.position);
    else
      break;
  }
  return r !== -1 && i !== 0 && e.lineIndent < r && Wi(e, "deficient indentation"), i;
}
f(vt, "skipSeparationSpace");
function es(e) {
  var t = e.position, r;
  return r = e.input.charCodeAt(t), !!((r === 45 || r === 46) && r === e.input.charCodeAt(t + 1) && r === e.input.charCodeAt(t + 2) && (t += 3, r = e.input.charCodeAt(t), r === 0 || Ut(r)));
}
f(es, "testDocumentSeparator");
function Bo(e, t) {
  t === 1 ? e.result += " " : t > 1 && (e.result += Ot.repeat(`
`, t - 1));
}
f(Bo, "writeFoldedLines");
function np(e, t, r) {
  var i, s, o, a, n, l, c, h, u = e.kind, p = e.result, d;
  if (d = e.input.charCodeAt(e.position), Ut(d) || mr(d) || d === 35 || d === 38 || d === 42 || d === 33 || d === 124 || d === 62 || d === 39 || d === 34 || d === 37 || d === 64 || d === 96 || (d === 63 || d === 45) && (s = e.input.charCodeAt(e.position + 1), Ut(s) || r && mr(s)))
    return !1;
  for (e.kind = "scalar", e.result = "", o = a = e.position, n = !1; d !== 0; ) {
    if (d === 58) {
      if (s = e.input.charCodeAt(e.position + 1), Ut(s) || r && mr(s))
        break;
    } else if (d === 35) {
      if (i = e.input.charCodeAt(e.position - 1), Ut(i))
        break;
    } else {
      if (e.position === e.lineStart && es(e) || r && mr(d))
        break;
      if (ye(d))
        if (l = e.line, c = e.lineStart, h = e.lineIndent, vt(e, !1, -1), e.lineIndent >= t) {
          n = !0, d = e.input.charCodeAt(e.position);
          continue;
        } else {
          e.position = a, e.line = l, e.lineStart = c, e.lineIndent = h;
          break;
        }
    }
    n && (ze(e, o, a, !1), Bo(e, e.line - l), o = a = e.position, n = !1), tr(d) || (a = e.position + 1), d = e.input.charCodeAt(++e.position);
  }
  return ze(e, o, a, !1), e.result ? !0 : (e.kind = u, e.result = p, !1);
}
f(np, "readPlainScalar");
function lp(e, t) {
  var r, i, s;
  if (r = e.input.charCodeAt(e.position), r !== 39)
    return !1;
  for (e.kind = "scalar", e.result = "", e.position++, i = s = e.position; (r = e.input.charCodeAt(e.position)) !== 0; )
    if (r === 39)
      if (ze(e, i, e.position, !0), r = e.input.charCodeAt(++e.position), r === 39)
        i = e.position, e.position++, s = e.position;
      else
        return !0;
    else ye(r) ? (ze(e, i, s, !0), Bo(e, vt(e, !1, t)), i = s = e.position) : e.position === e.lineStart && es(e) ? K(e, "unexpected end of the document within a single quoted scalar") : (e.position++, s = e.position);
  K(e, "unexpected end of the stream within a single quoted scalar");
}
f(lp, "readSingleQuotedScalar");
function hp(e, t) {
  var r, i, s, o, a, n;
  if (n = e.input.charCodeAt(e.position), n !== 34)
    return !1;
  for (e.kind = "scalar", e.result = "", e.position++, r = i = e.position; (n = e.input.charCodeAt(e.position)) !== 0; ) {
    if (n === 34)
      return ze(e, r, e.position, !0), e.position++, !0;
    if (n === 92) {
      if (ze(e, r, e.position, !0), n = e.input.charCodeAt(++e.position), ye(n))
        vt(e, !1, t);
      else if (n < 256 && sp[n])
        e.result += op[n], e.position++;
      else if ((a = ep(n)) > 0) {
        for (s = a, o = 0; s > 0; s--)
          n = e.input.charCodeAt(++e.position), (a = tp(n)) >= 0 ? o = (o << 4) + a : K(e, "expected hexadecimal character");
        e.result += ip(o), e.position++;
      } else
        K(e, "unknown escape sequence");
      r = i = e.position;
    } else ye(n) ? (ze(e, r, i, !0), Bo(e, vt(e, !1, t)), r = i = e.position) : e.position === e.lineStart && es(e) ? K(e, "unexpected end of the document within a double quoted scalar") : (e.position++, i = e.position);
  }
  K(e, "unexpected end of the stream within a double quoted scalar");
}
f(hp, "readDoubleQuotedScalar");
function cp(e, t) {
  var r = !0, i, s, o, a = e.tag, n, l = e.anchor, c, h, u, p, d, g = /* @__PURE__ */ Object.create(null), m, y, x, b;
  if (b = e.input.charCodeAt(e.position), b === 91)
    h = 93, d = !1, n = [];
  else if (b === 123)
    h = 125, d = !0, n = {};
  else
    return !1;
  for (e.anchor !== null && (e.anchorMap[e.anchor] = n), b = e.input.charCodeAt(++e.position); b !== 0; ) {
    if (vt(e, !0, t), b = e.input.charCodeAt(e.position), b === h)
      return e.position++, e.tag = a, e.anchor = l, e.kind = d ? "mapping" : "sequence", e.result = n, !0;
    r ? b === 44 && K(e, "expected the node content, but found ','") : K(e, "missed comma between flow collection entries"), y = m = x = null, u = p = !1, b === 63 && (c = e.input.charCodeAt(e.position + 1), Ut(c) && (u = p = !0, e.position++, vt(e, !0, t))), i = e.line, s = e.lineStart, o = e.position, Tr(e, t, Qs, !1, !0), y = e.tag, m = e.result, vt(e, !0, t), b = e.input.charCodeAt(e.position), (p || e.line === i) && b === 58 && (u = !0, b = e.input.charCodeAt(++e.position), vt(e, !0, t), Tr(e, t, Qs, !1, !0), x = e.result), d ? yr(e, n, g, y, m, x, i, s, o) : u ? n.push(yr(e, null, g, y, m, x, i, s, o)) : n.push(m), vt(e, !0, t), b = e.input.charCodeAt(e.position), b === 44 ? (r = !0, b = e.input.charCodeAt(++e.position)) : r = !1;
  }
  K(e, "unexpected end of the stream within a flow collection");
}
f(cp, "readFlowCollection");
function up(e, t) {
  var r, i, s = ca, o = !1, a = !1, n = t, l = 0, c = !1, h, u;
  if (u = e.input.charCodeAt(e.position), u === 124)
    i = !1;
  else if (u === 62)
    i = !0;
  else
    return !1;
  for (e.kind = "scalar", e.result = ""; u !== 0; )
    if (u = e.input.charCodeAt(++e.position), u === 43 || u === 45)
      ca === s ? s = u === 43 ? Mh : xk : K(e, "repeat of a chomping mode identifier");
    else if ((h = rp(u)) >= 0)
      h === 0 ? K(e, "bad explicit indentation width of a block scalar; it cannot be less than one") : a ? K(e, "repeat of an indentation width identifier") : (n = t + h - 1, a = !0);
    else
      break;
  if (tr(u)) {
    do
      u = e.input.charCodeAt(++e.position);
    while (tr(u));
    if (u === 35)
      do
        u = e.input.charCodeAt(++e.position);
      while (!ye(u) && u !== 0);
  }
  for (; u !== 0; ) {
    for (vo(e), e.lineIndent = 0, u = e.input.charCodeAt(e.position); (!a || e.lineIndent < n) && u === 32; )
      e.lineIndent++, u = e.input.charCodeAt(++e.position);
    if (!a && e.lineIndent > n && (n = e.lineIndent), ye(u)) {
      l++;
      continue;
    }
    if (e.lineIndent < n) {
      s === Mh ? e.result += Ot.repeat(`
`, o ? 1 + l : l) : s === ca && o && (e.result += `
`);
      break;
    }
    for (i ? tr(u) ? (c = !0, e.result += Ot.repeat(`
`, o ? 1 + l : l)) : c ? (c = !1, e.result += Ot.repeat(`
`, l + 1)) : l === 0 ? o && (e.result += " ") : e.result += Ot.repeat(`
`, l) : e.result += Ot.repeat(`
`, o ? 1 + l : l), o = !0, a = !0, l = 0, r = e.position; !ye(u) && u !== 0; )
      u = e.input.charCodeAt(++e.position);
    ze(e, r, e.position, !1);
  }
  return !0;
}
f(up, "readBlockScalar");
function Ya(e, t) {
  var r, i = e.tag, s = e.anchor, o = [], a, n = !1, l;
  if (e.firstTabInLine !== -1) return !1;
  for (e.anchor !== null && (e.anchorMap[e.anchor] = o), l = e.input.charCodeAt(e.position); l !== 0 && (e.firstTabInLine !== -1 && (e.position = e.firstTabInLine, K(e, "tab characters must not be used in indentation")), !(l !== 45 || (a = e.input.charCodeAt(e.position + 1), !Ut(a)))); ) {
    if (n = !0, e.position++, vt(e, !0, -1) && e.lineIndent <= t) {
      o.push(null), l = e.input.charCodeAt(e.position);
      continue;
    }
    if (r = e.line, Tr(e, t, Kd, !1, !0), o.push(e.result), vt(e, !0, -1), l = e.input.charCodeAt(e.position), (e.line === r || e.lineIndent > t) && l !== 0)
      K(e, "bad indentation of a sequence entry");
    else if (e.lineIndent < t)
      break;
  }
  return n ? (e.tag = i, e.anchor = s, e.kind = "sequence", e.result = o, !0) : !1;
}
f(Ya, "readBlockSequence");
function dp(e, t, r) {
  var i, s, o, a, n, l, c = e.tag, h = e.anchor, u = {}, p = /* @__PURE__ */ Object.create(null), d = null, g = null, m = null, y = !1, x = !1, b;
  if (e.firstTabInLine !== -1) return !1;
  for (e.anchor !== null && (e.anchorMap[e.anchor] = u), b = e.input.charCodeAt(e.position); b !== 0; ) {
    if (!y && e.firstTabInLine !== -1 && (e.position = e.firstTabInLine, K(e, "tab characters must not be used in indentation")), i = e.input.charCodeAt(e.position + 1), o = e.line, (b === 63 || b === 58) && Ut(i))
      b === 63 ? (y && (yr(e, u, p, d, g, null, a, n, l), d = g = m = null), x = !0, y = !0, s = !0) : y ? (y = !1, s = !0) : K(e, "incomplete explicit mapping pair; a key node is missed; or followed by a non-tabulated empty line"), e.position += 1, b = i;
    else {
      if (a = e.line, n = e.lineStart, l = e.position, !Tr(e, r, Zd, !1, !0))
        break;
      if (e.line === o) {
        for (b = e.input.charCodeAt(e.position); tr(b); )
          b = e.input.charCodeAt(++e.position);
        if (b === 58)
          b = e.input.charCodeAt(++e.position), Ut(b) || K(e, "a whitespace character is expected after the key-value separator within a block mapping"), y && (yr(e, u, p, d, g, null, a, n, l), d = g = m = null), x = !0, y = !1, s = !1, d = e.tag, g = e.result;
        else if (x)
          K(e, "can not read an implicit mapping pair; a colon is missed");
        else
          return e.tag = c, e.anchor = h, !0;
      } else if (x)
        K(e, "can not read a block mapping entry; a multiline key may not be an implicit key");
      else
        return e.tag = c, e.anchor = h, !0;
    }
    if ((e.line === o || e.lineIndent > t) && (y && (a = e.line, n = e.lineStart, l = e.position), Tr(e, t, Js, !0, s) && (y ? g = e.result : m = e.result), y || (yr(e, u, p, d, g, m, a, n, l), d = g = m = null), vt(e, !0, -1), b = e.input.charCodeAt(e.position)), (e.line === o || e.lineIndent > t) && b !== 0)
      K(e, "bad indentation of a mapping entry");
    else if (e.lineIndent < t)
      break;
  }
  return y && yr(e, u, p, d, g, null, a, n, l), x && (e.tag = c, e.anchor = h, e.kind = "mapping", e.result = u), x;
}
f(dp, "readBlockMapping");
function pp(e) {
  var t, r = !1, i = !1, s, o, a;
  if (a = e.input.charCodeAt(e.position), a !== 33) return !1;
  if (e.tag !== null && K(e, "duplication of a tag property"), a = e.input.charCodeAt(++e.position), a === 60 ? (r = !0, a = e.input.charCodeAt(++e.position)) : a === 33 ? (i = !0, s = "!!", a = e.input.charCodeAt(++e.position)) : s = "!", t = e.position, r) {
    do
      a = e.input.charCodeAt(++e.position);
    while (a !== 0 && a !== 62);
    e.position < e.length ? (o = e.input.slice(t, e.position), a = e.input.charCodeAt(++e.position)) : K(e, "unexpected end of the stream within a verbatim tag");
  } else {
    for (; a !== 0 && !Ut(a); )
      a === 33 && (i ? K(e, "tag suffix cannot contain exclamation marks") : (s = e.input.slice(t - 1, e.position + 1), Qd.test(s) || K(e, "named tag handle cannot contain such characters"), i = !0, t = e.position + 1)), a = e.input.charCodeAt(++e.position);
    o = e.input.slice(t, e.position), Tk.test(o) && K(e, "tag suffix cannot contain flow indicator characters");
  }
  o && !Jd.test(o) && K(e, "tag name cannot contain such characters: " + o);
  try {
    o = decodeURIComponent(o);
  } catch {
    K(e, "tag name is malformed: " + o);
  }
  return r ? e.tag = o : rr.call(e.tagMap, s) ? e.tag = e.tagMap[s] + o : s === "!" ? e.tag = "!" + o : s === "!!" ? e.tag = "tag:yaml.org,2002:" + o : K(e, 'undeclared tag handle "' + s + '"'), !0;
}
f(pp, "readTagProperty");
function fp(e) {
  var t, r;
  if (r = e.input.charCodeAt(e.position), r !== 38) return !1;
  for (e.anchor !== null && K(e, "duplication of an anchor property"), r = e.input.charCodeAt(++e.position), t = e.position; r !== 0 && !Ut(r) && !mr(r); )
    r = e.input.charCodeAt(++e.position);
  return e.position === t && K(e, "name of an anchor node must contain at least one character"), e.anchor = e.input.slice(t, e.position), !0;
}
f(fp, "readAnchorProperty");
function gp(e) {
  var t, r, i;
  if (i = e.input.charCodeAt(e.position), i !== 42) return !1;
  for (i = e.input.charCodeAt(++e.position), t = e.position; i !== 0 && !Ut(i) && !mr(i); )
    i = e.input.charCodeAt(++e.position);
  return e.position === t && K(e, "name of an alias node must contain at least one character"), r = e.input.slice(t, e.position), rr.call(e.anchorMap, r) || K(e, 'unidentified alias "' + r + '"'), e.result = e.anchorMap[r], vt(e, !0, -1), !0;
}
f(gp, "readAlias");
function Tr(e, t, r, i, s) {
  var o, a, n, l = 1, c = !1, h = !1, u, p, d, g, m, y;
  if (e.listener !== null && e.listener("open", e), e.tag = null, e.anchor = null, e.kind = null, e.result = null, o = a = n = Js === r || Kd === r, i && vt(e, !0, -1) && (c = !0, e.lineIndent > t ? l = 1 : e.lineIndent === t ? l = 0 : e.lineIndent < t && (l = -1)), l === 1)
    for (; pp(e) || fp(e); )
      vt(e, !0, -1) ? (c = !0, n = o, e.lineIndent > t ? l = 1 : e.lineIndent === t ? l = 0 : e.lineIndent < t && (l = -1)) : n = !1;
  if (n && (n = c || s), (l === 1 || Js === r) && (Qs === r || Zd === r ? m = t : m = t + 1, y = e.position - e.lineStart, l === 1 ? n && (Ya(e, y) || dp(e, y, m)) || cp(e, m) ? h = !0 : (a && up(e, m) || lp(e, m) || hp(e, m) ? h = !0 : gp(e) ? (h = !0, (e.tag !== null || e.anchor !== null) && K(e, "alias node should not have any properties")) : np(e, m, Qs === r) && (h = !0, e.tag === null && (e.tag = "?")), e.anchor !== null && (e.anchorMap[e.anchor] = e.result)) : l === 0 && (h = n && Ya(e, y))), e.tag === null)
    e.anchor !== null && (e.anchorMap[e.anchor] = e.result);
  else if (e.tag === "?") {
    for (e.result !== null && e.kind !== "scalar" && K(e, 'unacceptable node kind for !<?> tag; it should be "scalar", not "' + e.kind + '"'), u = 0, p = e.implicitTypes.length; u < p; u += 1)
      if (g = e.implicitTypes[u], g.resolve(e.result)) {
        e.result = g.construct(e.result), e.tag = g.tag, e.anchor !== null && (e.anchorMap[e.anchor] = e.result);
        break;
      }
  } else if (e.tag !== "!") {
    if (rr.call(e.typeMap[e.kind || "fallback"], e.tag))
      g = e.typeMap[e.kind || "fallback"][e.tag];
    else
      for (g = null, d = e.typeMap.multi[e.kind || "fallback"], u = 0, p = d.length; u < p; u += 1)
        if (e.tag.slice(0, d[u].tag.length) === d[u].tag) {
          g = d[u];
          break;
        }
    g || K(e, "unknown tag !<" + e.tag + ">"), e.result !== null && g.kind !== e.kind && K(e, "unacceptable node kind for !<" + e.tag + '> tag; it should be "' + g.kind + '", not "' + e.kind + '"'), g.resolve(e.result, e.tag) ? (e.result = g.construct(e.result, e.tag), e.anchor !== null && (e.anchorMap[e.anchor] = e.result)) : K(e, "cannot resolve a node with !<" + e.tag + "> explicit tag");
  }
  return e.listener !== null && e.listener("close", e), e.tag !== null || e.anchor !== null || h;
}
f(Tr, "composeNode");
function mp(e) {
  var t = e.position, r, i, s, o = !1, a;
  for (e.version = null, e.checkLineBreaks = e.legacy, e.tagMap = /* @__PURE__ */ Object.create(null), e.anchorMap = /* @__PURE__ */ Object.create(null); (a = e.input.charCodeAt(e.position)) !== 0 && (vt(e, !0, -1), a = e.input.charCodeAt(e.position), !(e.lineIndent > 0 || a !== 37)); ) {
    for (o = !0, a = e.input.charCodeAt(++e.position), r = e.position; a !== 0 && !Ut(a); )
      a = e.input.charCodeAt(++e.position);
    for (i = e.input.slice(r, e.position), s = [], i.length < 1 && K(e, "directive name must not be less than one character in length"); a !== 0; ) {
      for (; tr(a); )
        a = e.input.charCodeAt(++e.position);
      if (a === 35) {
        do
          a = e.input.charCodeAt(++e.position);
        while (a !== 0 && !ye(a));
        break;
      }
      if (ye(a)) break;
      for (r = e.position; a !== 0 && !Ut(a); )
        a = e.input.charCodeAt(++e.position);
      s.push(e.input.slice(r, e.position));
    }
    a !== 0 && vo(e), rr.call(Eh, i) ? Eh[i](e, i, s) : Wi(e, 'unknown document directive "' + i + '"');
  }
  if (vt(e, !0, -1), e.lineIndent === 0 && e.input.charCodeAt(e.position) === 45 && e.input.charCodeAt(e.position + 1) === 45 && e.input.charCodeAt(e.position + 2) === 45 ? (e.position += 3, vt(e, !0, -1)) : o && K(e, "directives end mark is expected"), Tr(e, e.lineIndent - 1, Js, !1, !0), vt(e, !0, -1), e.checkLineBreaks && kk.test(e.input.slice(t, e.position)) && Wi(e, "non-ASCII line breaks are interpreted as content"), e.documents.push(e.result), e.position === e.lineStart && es(e)) {
    e.input.charCodeAt(e.position) === 46 && (e.position += 3, vt(e, !0, -1));
    return;
  }
  if (e.position < e.length - 1)
    K(e, "end of the stream or a document separator is expected");
  else
    return;
}
f(mp, "readDocument");
function Zn(e, t) {
  e = String(e), t = t || {}, e.length !== 0 && (e.charCodeAt(e.length - 1) !== 10 && e.charCodeAt(e.length - 1) !== 13 && (e += `
`), e.charCodeAt(0) === 65279 && (e = e.slice(1)));
  var r = new ap(e, t), i = e.indexOf("\0");
  for (i !== -1 && (r.position = i, K(r, "null byte is not allowed in input")), r.input += "\0"; r.input.charCodeAt(r.position) === 32; )
    r.lineIndent += 1, r.position += 1;
  for (; r.position < r.length - 1; )
    mp(r);
  return r.documents;
}
f(Zn, "loadDocuments");
function wk(e, t, r) {
  t !== null && typeof t == "object" && typeof r > "u" && (r = t, t = null);
  var i = Zn(e, r);
  if (typeof t != "function")
    return i;
  for (var s = 0, o = i.length; s < o; s += 1)
    t(i[s]);
}
f(wk, "loadAll$1");
function yp(e, t) {
  var r = Zn(e, t);
  if (r.length !== 0) {
    if (r.length === 1)
      return r[0];
    throw new te("expected a single document in the stream, but found more");
  }
}
f(yp, "load$1");
var Sk = yp, _k = {
  load: Sk
}, Cp = Object.prototype.toString, xp = Object.prototype.hasOwnProperty, Kn = 65279, vk = 9, Hi = 10, Bk = 13, Lk = 32, Fk = 33, Ak = 34, ja = 35, Mk = 37, Ek = 38, $k = 39, Ok = 42, bp = 44, Ik = 45, to = 58, Dk = 61, Pk = 62, Rk = 63, Nk = 64, kp = 91, Tp = 93, qk = 96, wp = 123, zk = 124, Sp = 125, Yt = {};
Yt[0] = "\\0";
Yt[7] = "\\a";
Yt[8] = "\\b";
Yt[9] = "\\t";
Yt[10] = "\\n";
Yt[11] = "\\v";
Yt[12] = "\\f";
Yt[13] = "\\r";
Yt[27] = "\\e";
Yt[34] = '\\"';
Yt[92] = "\\\\";
Yt[133] = "\\N";
Yt[160] = "\\_";
Yt[8232] = "\\L";
Yt[8233] = "\\P";
var Wk = [
  "y",
  "Y",
  "yes",
  "Yes",
  "YES",
  "on",
  "On",
  "ON",
  "n",
  "N",
  "no",
  "No",
  "NO",
  "off",
  "Off",
  "OFF"
], Hk = /^[-+]?[0-9_]+(?::[0-9_]+)+(?:\.[0-9_]*)?$/;
function _p(e, t) {
  var r, i, s, o, a, n, l;
  if (t === null) return {};
  for (r = {}, i = Object.keys(t), s = 0, o = i.length; s < o; s += 1)
    a = i[s], n = String(t[a]), a.slice(0, 2) === "!!" && (a = "tag:yaml.org,2002:" + a.slice(2)), l = e.compiledTypeMap.fallback[a], l && xp.call(l.styleAliases, n) && (n = l.styleAliases[n]), r[a] = n;
  return r;
}
f(_p, "compileStyleMap");
function vp(e) {
  var t, r, i;
  if (t = e.toString(16).toUpperCase(), e <= 255)
    r = "x", i = 2;
  else if (e <= 65535)
    r = "u", i = 4;
  else if (e <= 4294967295)
    r = "U", i = 8;
  else
    throw new te("code point within a string may not be greater than 0xFFFFFFFF");
  return "\\" + r + Ot.repeat("0", i - t.length) + t;
}
f(vp, "encodeHex");
var Yk = 1, Yi = 2;
function Bp(e) {
  this.schema = e.schema || Vd, this.indent = Math.max(1, e.indent || 2), this.noArrayIndent = e.noArrayIndent || !1, this.skipInvalid = e.skipInvalid || !1, this.flowLevel = Ot.isNothing(e.flowLevel) ? -1 : e.flowLevel, this.styleMap = _p(this.schema, e.styles || null), this.sortKeys = e.sortKeys || !1, this.lineWidth = e.lineWidth || 80, this.noRefs = e.noRefs || !1, this.noCompatMode = e.noCompatMode || !1, this.condenseFlow = e.condenseFlow || !1, this.quotingType = e.quotingType === '"' ? Yi : Yk, this.forceQuotes = e.forceQuotes || !1, this.replacer = typeof e.replacer == "function" ? e.replacer : null, this.implicitTypes = this.schema.compiledImplicit, this.explicitTypes = this.schema.compiledExplicit, this.tag = null, this.result = "", this.duplicates = [], this.usedDuplicates = null;
}
f(Bp, "State");
function Ua(e, t) {
  for (var r = Ot.repeat(" ", t), i = 0, s = -1, o = "", a, n = e.length; i < n; )
    s = e.indexOf(`
`, i), s === -1 ? (a = e.slice(i), i = n) : (a = e.slice(i, s + 1), i = s + 1), a.length && a !== `
` && (o += r), o += a;
  return o;
}
f(Ua, "indentString");
function eo(e, t) {
  return `
` + Ot.repeat(" ", e.indent * t);
}
f(eo, "generateNextLine");
function Lp(e, t) {
  var r, i, s;
  for (r = 0, i = e.implicitTypes.length; r < i; r += 1)
    if (s = e.implicitTypes[r], s.resolve(t))
      return !0;
  return !1;
}
f(Lp, "testImplicitResolving");
function ji(e) {
  return e === Lk || e === vk;
}
f(ji, "isWhitespace");
function Jr(e) {
  return 32 <= e && e <= 126 || 161 <= e && e <= 55295 && e !== 8232 && e !== 8233 || 57344 <= e && e <= 65533 && e !== Kn || 65536 <= e && e <= 1114111;
}
f(Jr, "isPrintable");
function Ga(e) {
  return Jr(e) && e !== Kn && e !== Bk && e !== Hi;
}
f(Ga, "isNsCharOrWhitespace");
function Xa(e, t, r) {
  var i = Ga(e), s = i && !ji(e);
  return (
    // ns-plain-safe
    (r ? (
      // c = flow-in
      i
    ) : i && e !== bp && e !== kp && e !== Tp && e !== wp && e !== Sp) && e !== ja && !(t === to && !s) || Ga(t) && !ji(t) && e === ja || t === to && s
  );
}
f(Xa, "isPlainSafe");
function Fp(e) {
  return Jr(e) && e !== Kn && !ji(e) && e !== Ik && e !== Rk && e !== to && e !== bp && e !== kp && e !== Tp && e !== wp && e !== Sp && e !== ja && e !== Ek && e !== Ok && e !== Fk && e !== zk && e !== Dk && e !== Pk && e !== $k && e !== Ak && e !== Mk && e !== Nk && e !== qk;
}
f(Fp, "isPlainSafeFirst");
function Ap(e) {
  return !ji(e) && e !== to;
}
f(Ap, "isPlainSafeLast");
function Yr(e, t) {
  var r = e.charCodeAt(t), i;
  return r >= 55296 && r <= 56319 && t + 1 < e.length && (i = e.charCodeAt(t + 1), i >= 56320 && i <= 57343) ? (r - 55296) * 1024 + i - 56320 + 65536 : r;
}
f(Yr, "codePointAt");
function Qn(e) {
  var t = /^\n* /;
  return t.test(e);
}
f(Qn, "needIndentIndicator");
var Mp = 1, Va = 2, Ep = 3, $p = 4, zr = 5;
function Op(e, t, r, i, s, o, a, n) {
  var l, c = 0, h = null, u = !1, p = !1, d = i !== -1, g = -1, m = Fp(Yr(e, 0)) && Ap(Yr(e, e.length - 1));
  if (t || a)
    for (l = 0; l < e.length; c >= 65536 ? l += 2 : l++) {
      if (c = Yr(e, l), !Jr(c))
        return zr;
      m = m && Xa(c, h, n), h = c;
    }
  else {
    for (l = 0; l < e.length; c >= 65536 ? l += 2 : l++) {
      if (c = Yr(e, l), c === Hi)
        u = !0, d && (p = p || // Foldable line = too long, and not more-indented.
        l - g - 1 > i && e[g + 1] !== " ", g = l);
      else if (!Jr(c))
        return zr;
      m = m && Xa(c, h, n), h = c;
    }
    p = p || d && l - g - 1 > i && e[g + 1] !== " ";
  }
  return !u && !p ? m && !a && !s(e) ? Mp : o === Yi ? zr : Va : r > 9 && Qn(e) ? zr : a ? o === Yi ? zr : Va : p ? $p : Ep;
}
f(Op, "chooseScalarStyle");
function Ip(e, t, r, i, s) {
  e.dump = (function() {
    if (t.length === 0)
      return e.quotingType === Yi ? '""' : "''";
    if (!e.noCompatMode && (Wk.indexOf(t) !== -1 || Hk.test(t)))
      return e.quotingType === Yi ? '"' + t + '"' : "'" + t + "'";
    var o = e.indent * Math.max(1, r), a = e.lineWidth === -1 ? -1 : Math.max(Math.min(e.lineWidth, 40), e.lineWidth - o), n = i || e.flowLevel > -1 && r >= e.flowLevel;
    function l(c) {
      return Lp(e, c);
    }
    switch (f(l, "testAmbiguity"), Op(
      t,
      n,
      e.indent,
      a,
      l,
      e.quotingType,
      e.forceQuotes && !i,
      s
    )) {
      case Mp:
        return t;
      case Va:
        return "'" + t.replace(/'/g, "''") + "'";
      case Ep:
        return "|" + Za(t, e.indent) + Ka(Ua(t, o));
      case $p:
        return ">" + Za(t, e.indent) + Ka(Ua(Dp(t, a), o));
      case zr:
        return '"' + Pp(t) + '"';
      default:
        throw new te("impossible error: invalid scalar style");
    }
  })();
}
f(Ip, "writeScalar");
function Za(e, t) {
  var r = Qn(e) ? String(t) : "", i = e[e.length - 1] === `
`, s = i && (e[e.length - 2] === `
` || e === `
`), o = s ? "+" : i ? "" : "-";
  return r + o + `
`;
}
f(Za, "blockHeader");
function Ka(e) {
  return e[e.length - 1] === `
` ? e.slice(0, -1) : e;
}
f(Ka, "dropEndingNewline");
function Dp(e, t) {
  for (var r = /(\n+)([^\n]*)/g, i = (function() {
    var c = e.indexOf(`
`);
    return c = c !== -1 ? c : e.length, r.lastIndex = c, Qa(e.slice(0, c), t);
  })(), s = e[0] === `
` || e[0] === " ", o, a; a = r.exec(e); ) {
    var n = a[1], l = a[2];
    o = l[0] === " ", i += n + (!s && !o && l !== "" ? `
` : "") + Qa(l, t), s = o;
  }
  return i;
}
f(Dp, "foldString");
function Qa(e, t) {
  if (e === "" || e[0] === " ") return e;
  for (var r = / [^ ]/g, i, s = 0, o, a = 0, n = 0, l = ""; i = r.exec(e); )
    n = i.index, n - s > t && (o = a > s ? a : n, l += `
` + e.slice(s, o), s = o + 1), a = n;
  return l += `
`, e.length - s > t && a > s ? l += e.slice(s, a) + `
` + e.slice(a + 1) : l += e.slice(s), l.slice(1);
}
f(Qa, "foldLine");
function Pp(e) {
  for (var t = "", r = 0, i, s = 0; s < e.length; r >= 65536 ? s += 2 : s++)
    r = Yr(e, s), i = Yt[r], !i && Jr(r) ? (t += e[s], r >= 65536 && (t += e[s + 1])) : t += i || vp(r);
  return t;
}
f(Pp, "escapeString");
function Rp(e, t, r) {
  var i = "", s = e.tag, o, a, n;
  for (o = 0, a = r.length; o < a; o += 1)
    n = r[o], e.replacer && (n = e.replacer.call(r, String(o), n)), (Fe(e, t, n, !1, !1) || typeof n > "u" && Fe(e, t, null, !1, !1)) && (i !== "" && (i += "," + (e.condenseFlow ? "" : " ")), i += e.dump);
  e.tag = s, e.dump = "[" + i + "]";
}
f(Rp, "writeFlowSequence");
function Ja(e, t, r, i) {
  var s = "", o = e.tag, a, n, l;
  for (a = 0, n = r.length; a < n; a += 1)
    l = r[a], e.replacer && (l = e.replacer.call(r, String(a), l)), (Fe(e, t + 1, l, !0, !0, !1, !0) || typeof l > "u" && Fe(e, t + 1, null, !0, !0, !1, !0)) && ((!i || s !== "") && (s += eo(e, t)), e.dump && Hi === e.dump.charCodeAt(0) ? s += "-" : s += "- ", s += e.dump);
  e.tag = o, e.dump = s || "[]";
}
f(Ja, "writeBlockSequence");
function Np(e, t, r) {
  var i = "", s = e.tag, o = Object.keys(r), a, n, l, c, h;
  for (a = 0, n = o.length; a < n; a += 1)
    h = "", i !== "" && (h += ", "), e.condenseFlow && (h += '"'), l = o[a], c = r[l], e.replacer && (c = e.replacer.call(r, l, c)), Fe(e, t, l, !1, !1) && (e.dump.length > 1024 && (h += "? "), h += e.dump + (e.condenseFlow ? '"' : "") + ":" + (e.condenseFlow ? "" : " "), Fe(e, t, c, !1, !1) && (h += e.dump, i += h));
  e.tag = s, e.dump = "{" + i + "}";
}
f(Np, "writeFlowMapping");
function qp(e, t, r, i) {
  var s = "", o = e.tag, a = Object.keys(r), n, l, c, h, u, p;
  if (e.sortKeys === !0)
    a.sort();
  else if (typeof e.sortKeys == "function")
    a.sort(e.sortKeys);
  else if (e.sortKeys)
    throw new te("sortKeys must be a boolean or a function");
  for (n = 0, l = a.length; n < l; n += 1)
    p = "", (!i || s !== "") && (p += eo(e, t)), c = a[n], h = r[c], e.replacer && (h = e.replacer.call(r, c, h)), Fe(e, t + 1, c, !0, !0, !0) && (u = e.tag !== null && e.tag !== "?" || e.dump && e.dump.length > 1024, u && (e.dump && Hi === e.dump.charCodeAt(0) ? p += "?" : p += "? "), p += e.dump, u && (p += eo(e, t)), Fe(e, t + 1, h, !0, u) && (e.dump && Hi === e.dump.charCodeAt(0) ? p += ":" : p += ": ", p += e.dump, s += p));
  e.tag = o, e.dump = s || "{}";
}
f(qp, "writeBlockMapping");
function tn(e, t, r) {
  var i, s, o, a, n, l;
  for (s = r ? e.explicitTypes : e.implicitTypes, o = 0, a = s.length; o < a; o += 1)
    if (n = s[o], (n.instanceOf || n.predicate) && (!n.instanceOf || typeof t == "object" && t instanceof n.instanceOf) && (!n.predicate || n.predicate(t))) {
      if (r ? n.multi && n.representName ? e.tag = n.representName(t) : e.tag = n.tag : e.tag = "?", n.represent) {
        if (l = e.styleMap[n.tag] || n.defaultStyle, Cp.call(n.represent) === "[object Function]")
          i = n.represent(t, l);
        else if (xp.call(n.represent, l))
          i = n.represent[l](t, l);
        else
          throw new te("!<" + n.tag + '> tag resolver accepts not "' + l + '" style');
        e.dump = i;
      }
      return !0;
    }
  return !1;
}
f(tn, "detectType");
function Fe(e, t, r, i, s, o, a) {
  e.tag = null, e.dump = r, tn(e, r, !1) || tn(e, r, !0);
  var n = Cp.call(e.dump), l = i, c;
  i && (i = e.flowLevel < 0 || e.flowLevel > t);
  var h = n === "[object Object]" || n === "[object Array]", u, p;
  if (h && (u = e.duplicates.indexOf(r), p = u !== -1), (e.tag !== null && e.tag !== "?" || p || e.indent !== 2 && t > 0) && (s = !1), p && e.usedDuplicates[u])
    e.dump = "*ref_" + u;
  else {
    if (h && p && !e.usedDuplicates[u] && (e.usedDuplicates[u] = !0), n === "[object Object]")
      i && Object.keys(e.dump).length !== 0 ? (qp(e, t, e.dump, s), p && (e.dump = "&ref_" + u + e.dump)) : (Np(e, t, e.dump), p && (e.dump = "&ref_" + u + " " + e.dump));
    else if (n === "[object Array]")
      i && e.dump.length !== 0 ? (e.noArrayIndent && !a && t > 0 ? Ja(e, t - 1, e.dump, s) : Ja(e, t, e.dump, s), p && (e.dump = "&ref_" + u + e.dump)) : (Rp(e, t, e.dump), p && (e.dump = "&ref_" + u + " " + e.dump));
    else if (n === "[object String]")
      e.tag !== "?" && Ip(e, e.dump, t, o, l);
    else {
      if (n === "[object Undefined]")
        return !1;
      if (e.skipInvalid) return !1;
      throw new te("unacceptable kind of an object to dump " + n);
    }
    e.tag !== null && e.tag !== "?" && (c = encodeURI(
      e.tag[0] === "!" ? e.tag.slice(1) : e.tag
    ).replace(/!/g, "%21"), e.tag[0] === "!" ? c = "!" + c : c.slice(0, 18) === "tag:yaml.org,2002:" ? c = "!!" + c.slice(18) : c = "!<" + c + ">", e.dump = c + " " + e.dump);
  }
  return !0;
}
f(Fe, "writeNode");
function zp(e, t) {
  var r = [], i = [], s, o;
  for (ro(e, r, i), s = 0, o = i.length; s < o; s += 1)
    t.duplicates.push(r[i[s]]);
  t.usedDuplicates = new Array(o);
}
f(zp, "getDuplicateReferences");
function ro(e, t, r) {
  var i, s, o;
  if (e !== null && typeof e == "object")
    if (s = t.indexOf(e), s !== -1)
      r.indexOf(s) === -1 && r.push(s);
    else if (t.push(e), Array.isArray(e))
      for (s = 0, o = e.length; s < o; s += 1)
        ro(e[s], t, r);
    else
      for (i = Object.keys(e), s = 0, o = i.length; s < o; s += 1)
        ro(e[i[s]], t, r);
}
f(ro, "inspectNode");
function jk(e, t) {
  t = t || {};
  var r = new Bp(t);
  r.noRefs || zp(e, r);
  var i = e;
  return r.replacer && (i = r.replacer.call({ "": i }, "", i)), Fe(r, 0, i, !0, !0) ? r.dump + `
` : "";
}
f(jk, "dump$1");
function Uk(e, t) {
  return function() {
    throw new Error("Function yaml." + e + " is removed in js-yaml 4. Use yaml." + t + " instead, which is now safe by default.");
  };
}
f(Uk, "renamed");
var Gk = Ed, Xk = _k.load;
/*! Bundled license information:

js-yaml/dist/js-yaml.mjs:
  (*! js-yaml 4.1.1 https://github.com/nodeca/js-yaml @license MIT *)
*/
var fi = /* @__PURE__ */ f((e, t) => {
  if (t)
    return "translate(" + -e.width / 2 + ", " + -e.height / 2 + ")";
  const r = e.x ?? 0, i = e.y ?? 0;
  return "translate(" + -(r + e.width / 2) + ", " + -(i + e.height / 2) + ")";
}, "computeLabelTransform"), Wt = {
  aggregation: 17.25,
  extension: 17.25,
  composition: 17.25,
  dependency: 6,
  lollipop: 13.5,
  arrow_point: 4,
  arrow_barb: 0,
  arrow_barb_neo: 5.5
  //arrow_cross: 24,
}, $h = {
  arrow_point: 4,
  arrow_cross: 12.5,
  arrow_circle: 12.5
};
function vi(e, t) {
  if (e === void 0 || t === void 0)
    return { angle: 0, deltaX: 0, deltaY: 0 };
  e = Tt(e), t = Tt(t);
  const [r, i] = [e.x, e.y], [s, o] = [t.x, t.y], a = s - r, n = o - i;
  return { angle: Math.atan(n / a), deltaX: a, deltaY: n };
}
f(vi, "calculateDeltaAndAngle");
var Tt = /* @__PURE__ */ f((e) => Array.isArray(e) ? { x: e[0], y: e[1] } : e, "pointTransformer"), Vk = /* @__PURE__ */ f((e) => ({
  x: /* @__PURE__ */ f(function(t, r, i) {
    let s = 0;
    const o = Tt(i[0]).x < Tt(i[i.length - 1]).x ? "left" : "right";
    if (r === 0 && Object.hasOwn(Wt, e.arrowTypeStart)) {
      const { angle: d, deltaX: g } = vi(i[0], i[1]);
      s = Wt[e.arrowTypeStart] * Math.cos(d) * (g >= 0 ? 1 : -1);
    } else if (r === i.length - 1 && Object.hasOwn(Wt, e.arrowTypeEnd)) {
      const { angle: d, deltaX: g } = vi(
        i[i.length - 1],
        i[i.length - 2]
      );
      s = Wt[e.arrowTypeEnd] * Math.cos(d) * (g >= 0 ? 1 : -1);
    }
    const a = Math.abs(
      Tt(t).x - Tt(i[i.length - 1]).x
    ), n = Math.abs(
      Tt(t).y - Tt(i[i.length - 1]).y
    ), l = Math.abs(Tt(t).x - Tt(i[0]).x), c = Math.abs(Tt(t).y - Tt(i[0]).y), h = Wt[e.arrowTypeStart], u = Wt[e.arrowTypeEnd], p = 1;
    if (a < u && a > 0 && n < u) {
      let d = u + p - a;
      d *= o === "right" ? -1 : 1, s -= d;
    }
    if (l < h && l > 0 && c < h) {
      let d = h + p - l;
      d *= o === "right" ? -1 : 1, s += d;
    }
    return Tt(t).x + s;
  }, "x"),
  y: /* @__PURE__ */ f(function(t, r, i) {
    let s = 0;
    const o = Tt(i[0]).y < Tt(i[i.length - 1]).y ? "down" : "up";
    if (r === 0 && Object.hasOwn(Wt, e.arrowTypeStart)) {
      const { angle: d, deltaY: g } = vi(i[0], i[1]);
      s = Wt[e.arrowTypeStart] * Math.abs(Math.sin(d)) * (g >= 0 ? 1 : -1);
    } else if (r === i.length - 1 && Object.hasOwn(Wt, e.arrowTypeEnd)) {
      const { angle: d, deltaY: g } = vi(
        i[i.length - 1],
        i[i.length - 2]
      );
      s = Wt[e.arrowTypeEnd] * Math.abs(Math.sin(d)) * (g >= 0 ? 1 : -1);
    }
    const a = Math.abs(
      Tt(t).y - Tt(i[i.length - 1]).y
    ), n = Math.abs(
      Tt(t).x - Tt(i[i.length - 1]).x
    ), l = Math.abs(Tt(t).y - Tt(i[0]).y), c = Math.abs(Tt(t).x - Tt(i[0]).x), h = Wt[e.arrowTypeStart], u = Wt[e.arrowTypeEnd], p = 1;
    if (a < u && a > 0 && n < u) {
      let d = u + p - a;
      d *= o === "up" ? -1 : 1, s -= d;
    }
    if (l < h && l > 0 && c < h) {
      let d = h + p - l;
      d *= o === "up" ? -1 : 1, s += d;
    }
    return Tt(t).y + s;
  }, "y")
}), "getLineFunctionsWithOffset"), ys = {}, Et = {}, Oh;
function Zk() {
  return Oh || (Oh = 1, Object.defineProperty(Et, "__esModule", { value: !0 }), Et.BLANK_URL = Et.relativeFirstCharacters = Et.whitespaceEscapeCharsRegex = Et.urlSchemeRegex = Et.ctrlCharactersRegex = Et.htmlCtrlEntityRegex = Et.htmlEntitiesRegex = Et.invalidProtocolRegex = void 0, Et.invalidProtocolRegex = /^([^\w]*)(javascript|data|vbscript)/im, Et.htmlEntitiesRegex = /&#(\w+)(^\w|;)?/g, Et.htmlCtrlEntityRegex = /&(newline|tab);/gi, Et.ctrlCharactersRegex = /[\u0000-\u001F\u007F-\u009F\u2000-\u200D\uFEFF]/gim, Et.urlSchemeRegex = /^.+(:|&colon;)/gim, Et.whitespaceEscapeCharsRegex = /(\\|%5[cC])((%(6[eE]|72|74))|[nrt])/g, Et.relativeFirstCharacters = [".", "/"], Et.BLANK_URL = "about:blank"), Et;
}
var Ih;
function Kk() {
  if (Ih) return ys;
  Ih = 1, Object.defineProperty(ys, "__esModule", { value: !0 }), ys.sanitizeUrl = o;
  var e = Zk();
  function t(a) {
    return e.relativeFirstCharacters.indexOf(a[0]) > -1;
  }
  function r(a) {
    var n = a.replace(e.ctrlCharactersRegex, "");
    return n.replace(e.htmlEntitiesRegex, function(l, c) {
      return String.fromCharCode(c);
    });
  }
  function i(a) {
    return URL.canParse(a);
  }
  function s(a) {
    try {
      return decodeURIComponent(a);
    } catch {
      return a;
    }
  }
  function o(a) {
    if (!a)
      return e.BLANK_URL;
    var n, l = s(a.trim());
    do
      l = r(l).replace(e.htmlCtrlEntityRegex, "").replace(e.ctrlCharactersRegex, "").replace(e.whitespaceEscapeCharsRegex, "").trim(), l = s(l), n = l.match(e.ctrlCharactersRegex) || l.match(e.htmlEntitiesRegex) || l.match(e.htmlCtrlEntityRegex) || l.match(e.whitespaceEscapeCharsRegex);
    while (n && n.length > 0);
    var c = l;
    if (!c)
      return e.BLANK_URL;
    if (t(c))
      return c;
    var h = c.trimStart(), u = h.match(e.urlSchemeRegex);
    if (!u)
      return c;
    var p = u[0].toLowerCase().trim();
    if (e.invalidProtocolRegex.test(p))
      return e.BLANK_URL;
    var d = h.replace(/\\/g, "/");
    if (p === "mailto:" || p.includes("://"))
      return d;
    if (p === "http:" || p === "https:") {
      if (!i(d))
        return e.BLANK_URL;
      var g = new URL(d);
      return g.protocol = g.protocol.toLowerCase(), g.hostname = g.hostname.toLowerCase(), g.toString();
    }
    return d;
  }
  return ys;
}
var Qk = Kk(), Wp = typeof global == "object" && global && global.Object === Object && global, Jk = typeof self == "object" && self && self.Object === Object && self, $e = Wp || Jk || Function("return this")(), io = $e.Symbol, Hp = Object.prototype, t2 = Hp.hasOwnProperty, e2 = Hp.toString, gi = io ? io.toStringTag : void 0;
function r2(e) {
  var t = t2.call(e, gi), r = e[gi];
  try {
    e[gi] = void 0;
    var i = !0;
  } catch {
  }
  var s = e2.call(e);
  return i && (t ? e[gi] = r : delete e[gi]), s;
}
var i2 = Object.prototype, s2 = i2.toString;
function o2(e) {
  return s2.call(e);
}
var a2 = "[object Null]", n2 = "[object Undefined]", Dh = io ? io.toStringTag : void 0;
function ri(e) {
  return e == null ? e === void 0 ? n2 : a2 : Dh && Dh in Object(e) ? r2(e) : o2(e);
}
function Br(e) {
  var t = typeof e;
  return e != null && (t == "object" || t == "function");
}
var l2 = "[object AsyncFunction]", h2 = "[object Function]", c2 = "[object GeneratorFunction]", u2 = "[object Proxy]";
function Jn(e) {
  if (!Br(e))
    return !1;
  var t = ri(e);
  return t == h2 || t == c2 || t == l2 || t == u2;
}
var ua = $e["__core-js_shared__"], Ph = (function() {
  var e = /[^.]+$/.exec(ua && ua.keys && ua.keys.IE_PROTO || "");
  return e ? "Symbol(src)_1." + e : "";
})();
function d2(e) {
  return !!Ph && Ph in e;
}
var p2 = Function.prototype, f2 = p2.toString;
function Lr(e) {
  if (e != null) {
    try {
      return f2.call(e);
    } catch {
    }
    try {
      return e + "";
    } catch {
    }
  }
  return "";
}
var g2 = /[\\^$.*+?()[\]{}|]/g, m2 = /^\[object .+?Constructor\]$/, y2 = Function.prototype, C2 = Object.prototype, x2 = y2.toString, b2 = C2.hasOwnProperty, k2 = RegExp(
  "^" + x2.call(b2).replace(g2, "\\$&").replace(/hasOwnProperty|(function).*?(?=\\\()| for .+?(?=\\\])/g, "$1.*?") + "$"
);
function T2(e) {
  if (!Br(e) || d2(e))
    return !1;
  var t = Jn(e) ? k2 : m2;
  return t.test(Lr(e));
}
function w2(e, t) {
  return e?.[t];
}
function Fr(e, t) {
  var r = w2(e, t);
  return T2(r) ? r : void 0;
}
var Ui = Fr(Object, "create");
function S2() {
  this.__data__ = Ui ? Ui(null) : {}, this.size = 0;
}
function _2(e) {
  var t = this.has(e) && delete this.__data__[e];
  return this.size -= t ? 1 : 0, t;
}
var v2 = "__lodash_hash_undefined__", B2 = Object.prototype, L2 = B2.hasOwnProperty;
function F2(e) {
  var t = this.__data__;
  if (Ui) {
    var r = t[e];
    return r === v2 ? void 0 : r;
  }
  return L2.call(t, e) ? t[e] : void 0;
}
var A2 = Object.prototype, M2 = A2.hasOwnProperty;
function E2(e) {
  var t = this.__data__;
  return Ui ? t[e] !== void 0 : M2.call(t, e);
}
var $2 = "__lodash_hash_undefined__";
function O2(e, t) {
  var r = this.__data__;
  return this.size += this.has(e) ? 0 : 1, r[e] = Ui && t === void 0 ? $2 : t, this;
}
function wr(e) {
  var t = -1, r = e == null ? 0 : e.length;
  for (this.clear(); ++t < r; ) {
    var i = e[t];
    this.set(i[0], i[1]);
  }
}
wr.prototype.clear = S2;
wr.prototype.delete = _2;
wr.prototype.get = F2;
wr.prototype.has = E2;
wr.prototype.set = O2;
function I2() {
  this.__data__ = [], this.size = 0;
}
function Lo(e, t) {
  return e === t || e !== e && t !== t;
}
function Fo(e, t) {
  for (var r = e.length; r--; )
    if (Lo(e[r][0], t))
      return r;
  return -1;
}
var D2 = Array.prototype, P2 = D2.splice;
function R2(e) {
  var t = this.__data__, r = Fo(t, e);
  if (r < 0)
    return !1;
  var i = t.length - 1;
  return r == i ? t.pop() : P2.call(t, r, 1), --this.size, !0;
}
function N2(e) {
  var t = this.__data__, r = Fo(t, e);
  return r < 0 ? void 0 : t[r][1];
}
function q2(e) {
  return Fo(this.__data__, e) > -1;
}
function z2(e, t) {
  var r = this.__data__, i = Fo(r, e);
  return i < 0 ? (++this.size, r.push([e, t])) : r[i][1] = t, this;
}
function Ue(e) {
  var t = -1, r = e == null ? 0 : e.length;
  for (this.clear(); ++t < r; ) {
    var i = e[t];
    this.set(i[0], i[1]);
  }
}
Ue.prototype.clear = I2;
Ue.prototype.delete = R2;
Ue.prototype.get = N2;
Ue.prototype.has = q2;
Ue.prototype.set = z2;
var Gi = Fr($e, "Map");
function W2() {
  this.size = 0, this.__data__ = {
    hash: new wr(),
    map: new (Gi || Ue)(),
    string: new wr()
  };
}
function H2(e) {
  var t = typeof e;
  return t == "string" || t == "number" || t == "symbol" || t == "boolean" ? e !== "__proto__" : e === null;
}
function Ao(e, t) {
  var r = e.__data__;
  return H2(t) ? r[typeof t == "string" ? "string" : "hash"] : r.map;
}
function Y2(e) {
  var t = Ao(this, e).delete(e);
  return this.size -= t ? 1 : 0, t;
}
function j2(e) {
  return Ao(this, e).get(e);
}
function U2(e) {
  return Ao(this, e).has(e);
}
function G2(e, t) {
  var r = Ao(this, e), i = r.size;
  return r.set(e, t), this.size += r.size == i ? 0 : 1, this;
}
function or(e) {
  var t = -1, r = e == null ? 0 : e.length;
  for (this.clear(); ++t < r; ) {
    var i = e[t];
    this.set(i[0], i[1]);
  }
}
or.prototype.clear = W2;
or.prototype.delete = Y2;
or.prototype.get = j2;
or.prototype.has = U2;
or.prototype.set = G2;
var X2 = "Expected a function";
function rs(e, t) {
  if (typeof e != "function" || t != null && typeof t != "function")
    throw new TypeError(X2);
  var r = function() {
    var i = arguments, s = t ? t.apply(this, i) : i[0], o = r.cache;
    if (o.has(s))
      return o.get(s);
    var a = e.apply(this, i);
    return r.cache = o.set(s, a) || o, a;
  };
  return r.cache = new (rs.Cache || or)(), r;
}
rs.Cache = or;
function V2() {
  this.__data__ = new Ue(), this.size = 0;
}
function Z2(e) {
  var t = this.__data__, r = t.delete(e);
  return this.size = t.size, r;
}
function K2(e) {
  return this.__data__.get(e);
}
function Q2(e) {
  return this.__data__.has(e);
}
var J2 = 200;
function tT(e, t) {
  var r = this.__data__;
  if (r instanceof Ue) {
    var i = r.__data__;
    if (!Gi || i.length < J2 - 1)
      return i.push([e, t]), this.size = ++r.size, this;
    r = this.__data__ = new or(i);
  }
  return r.set(e, t), this.size = r.size, this;
}
function ii(e) {
  var t = this.__data__ = new Ue(e);
  this.size = t.size;
}
ii.prototype.clear = V2;
ii.prototype.delete = Z2;
ii.prototype.get = K2;
ii.prototype.has = Q2;
ii.prototype.set = tT;
var so = (function() {
  try {
    var e = Fr(Object, "defineProperty");
    return e({}, "", {}), e;
  } catch {
  }
})();
function tl(e, t, r) {
  t == "__proto__" && so ? so(e, t, {
    configurable: !0,
    enumerable: !0,
    value: r,
    writable: !0
  }) : e[t] = r;
}
function en(e, t, r) {
  (r !== void 0 && !Lo(e[t], r) || r === void 0 && !(t in e)) && tl(e, t, r);
}
function eT(e) {
  return function(t, r, i) {
    for (var s = -1, o = Object(t), a = i(t), n = a.length; n--; ) {
      var l = a[++s];
      if (r(o[l], l, o) === !1)
        break;
    }
    return t;
  };
}
var rT = eT(), Yp = typeof exports == "object" && exports && !exports.nodeType && exports, Rh = Yp && typeof module == "object" && module && !module.nodeType && module, iT = Rh && Rh.exports === Yp, Nh = iT ? $e.Buffer : void 0, qh = Nh ? Nh.allocUnsafe : void 0;
function sT(e, t) {
  if (t)
    return e.slice();
  var r = e.length, i = qh ? qh(r) : new e.constructor(r);
  return e.copy(i), i;
}
var zh = $e.Uint8Array;
function oT(e) {
  var t = new e.constructor(e.byteLength);
  return new zh(t).set(new zh(e)), t;
}
function aT(e, t) {
  var r = t ? oT(e.buffer) : e.buffer;
  return new e.constructor(r, e.byteOffset, e.length);
}
function nT(e, t) {
  var r = -1, i = e.length;
  for (t || (t = Array(i)); ++r < i; )
    t[r] = e[r];
  return t;
}
var Wh = Object.create, lT = /* @__PURE__ */ (function() {
  function e() {
  }
  return function(t) {
    if (!Br(t))
      return {};
    if (Wh)
      return Wh(t);
    e.prototype = t;
    var r = new e();
    return e.prototype = void 0, r;
  };
})();
function jp(e, t) {
  return function(r) {
    return e(t(r));
  };
}
var Up = jp(Object.getPrototypeOf, Object), hT = Object.prototype;
function Mo(e) {
  var t = e && e.constructor, r = typeof t == "function" && t.prototype || hT;
  return e === r;
}
function cT(e) {
  return typeof e.constructor == "function" && !Mo(e) ? lT(Up(e)) : {};
}
function is(e) {
  return e != null && typeof e == "object";
}
var uT = "[object Arguments]";
function Hh(e) {
  return is(e) && ri(e) == uT;
}
var Gp = Object.prototype, dT = Gp.hasOwnProperty, pT = Gp.propertyIsEnumerable, oo = Hh(/* @__PURE__ */ (function() {
  return arguments;
})()) ? Hh : function(e) {
  return is(e) && dT.call(e, "callee") && !pT.call(e, "callee");
}, ao = Array.isArray, fT = 9007199254740991;
function Xp(e) {
  return typeof e == "number" && e > -1 && e % 1 == 0 && e <= fT;
}
function Eo(e) {
  return e != null && Xp(e.length) && !Jn(e);
}
function gT(e) {
  return is(e) && Eo(e);
}
function mT() {
  return !1;
}
var Vp = typeof exports == "object" && exports && !exports.nodeType && exports, Yh = Vp && typeof module == "object" && module && !module.nodeType && module, yT = Yh && Yh.exports === Vp, jh = yT ? $e.Buffer : void 0, CT = jh ? jh.isBuffer : void 0, el = CT || mT, xT = "[object Object]", bT = Function.prototype, kT = Object.prototype, Zp = bT.toString, TT = kT.hasOwnProperty, wT = Zp.call(Object);
function ST(e) {
  if (!is(e) || ri(e) != xT)
    return !1;
  var t = Up(e);
  if (t === null)
    return !0;
  var r = TT.call(t, "constructor") && t.constructor;
  return typeof r == "function" && r instanceof r && Zp.call(r) == wT;
}
var _T = "[object Arguments]", vT = "[object Array]", BT = "[object Boolean]", LT = "[object Date]", FT = "[object Error]", AT = "[object Function]", MT = "[object Map]", ET = "[object Number]", $T = "[object Object]", OT = "[object RegExp]", IT = "[object Set]", DT = "[object String]", PT = "[object WeakMap]", RT = "[object ArrayBuffer]", NT = "[object DataView]", qT = "[object Float32Array]", zT = "[object Float64Array]", WT = "[object Int8Array]", HT = "[object Int16Array]", YT = "[object Int32Array]", jT = "[object Uint8Array]", UT = "[object Uint8ClampedArray]", GT = "[object Uint16Array]", XT = "[object Uint32Array]", xt = {};
xt[qT] = xt[zT] = xt[WT] = xt[HT] = xt[YT] = xt[jT] = xt[UT] = xt[GT] = xt[XT] = !0;
xt[_T] = xt[vT] = xt[RT] = xt[BT] = xt[NT] = xt[LT] = xt[FT] = xt[AT] = xt[MT] = xt[ET] = xt[$T] = xt[OT] = xt[IT] = xt[DT] = xt[PT] = !1;
function VT(e) {
  return is(e) && Xp(e.length) && !!xt[ri(e)];
}
function ZT(e) {
  return function(t) {
    return e(t);
  };
}
var Kp = typeof exports == "object" && exports && !exports.nodeType && exports, Oi = Kp && typeof module == "object" && module && !module.nodeType && module, KT = Oi && Oi.exports === Kp, da = KT && Wp.process, Uh = (function() {
  try {
    var e = Oi && Oi.require && Oi.require("util").types;
    return e || da && da.binding && da.binding("util");
  } catch {
  }
})(), Gh = Uh && Uh.isTypedArray, rl = Gh ? ZT(Gh) : VT;
function rn(e, t) {
  if (!(t === "constructor" && typeof e[t] == "function") && t != "__proto__")
    return e[t];
}
var QT = Object.prototype, JT = QT.hasOwnProperty;
function tw(e, t, r) {
  var i = e[t];
  (!(JT.call(e, t) && Lo(i, r)) || r === void 0 && !(t in e)) && tl(e, t, r);
}
function ew(e, t, r, i) {
  var s = !r;
  r || (r = {});
  for (var o = -1, a = t.length; ++o < a; ) {
    var n = t[o], l = void 0;
    l === void 0 && (l = e[n]), s ? tl(r, n, l) : tw(r, n, l);
  }
  return r;
}
function rw(e, t) {
  for (var r = -1, i = Array(e); ++r < e; )
    i[r] = t(r);
  return i;
}
var iw = 9007199254740991, sw = /^(?:0|[1-9]\d*)$/;
function Qp(e, t) {
  var r = typeof e;
  return t = t ?? iw, !!t && (r == "number" || r != "symbol" && sw.test(e)) && e > -1 && e % 1 == 0 && e < t;
}
var ow = Object.prototype, aw = ow.hasOwnProperty;
function nw(e, t) {
  var r = ao(e), i = !r && oo(e), s = !r && !i && el(e), o = !r && !i && !s && rl(e), a = r || i || s || o, n = a ? rw(e.length, String) : [], l = n.length;
  for (var c in e)
    (t || aw.call(e, c)) && !(a && // Safari 9 has enumerable `arguments.length` in strict mode.
    (c == "length" || // Node.js 0.10 has enumerable non-index properties on buffers.
    s && (c == "offset" || c == "parent") || // PhantomJS 2 has enumerable non-index properties on typed arrays.
    o && (c == "buffer" || c == "byteLength" || c == "byteOffset") || // Skip index properties.
    Qp(c, l))) && n.push(c);
  return n;
}
function lw(e) {
  var t = [];
  if (e != null)
    for (var r in Object(e))
      t.push(r);
  return t;
}
var hw = Object.prototype, cw = hw.hasOwnProperty;
function uw(e) {
  if (!Br(e))
    return lw(e);
  var t = Mo(e), r = [];
  for (var i in e)
    i == "constructor" && (t || !cw.call(e, i)) || r.push(i);
  return r;
}
function Jp(e) {
  return Eo(e) ? nw(e, !0) : uw(e);
}
function dw(e) {
  return ew(e, Jp(e));
}
function pw(e, t, r, i, s, o, a) {
  var n = rn(e, r), l = rn(t, r), c = a.get(l);
  if (c) {
    en(e, r, c);
    return;
  }
  var h = o ? o(n, l, r + "", e, t, a) : void 0, u = h === void 0;
  if (u) {
    var p = ao(l), d = !p && el(l), g = !p && !d && rl(l);
    h = l, p || d || g ? ao(n) ? h = n : gT(n) ? h = nT(n) : d ? (u = !1, h = sT(l, !0)) : g ? (u = !1, h = aT(l, !0)) : h = [] : ST(l) || oo(l) ? (h = n, oo(n) ? h = dw(n) : (!Br(n) || Jn(n)) && (h = cT(l))) : u = !1;
  }
  u && (a.set(l, h), s(h, l, i, o, a), a.delete(l)), en(e, r, h);
}
function tf(e, t, r, i, s) {
  e !== t && rT(t, function(o, a) {
    if (s || (s = new ii()), Br(o))
      pw(e, t, a, r, tf, i, s);
    else {
      var n = i ? i(rn(e, a), o, a + "", e, t, s) : void 0;
      n === void 0 && (n = o), en(e, a, n);
    }
  }, Jp);
}
function ef(e) {
  return e;
}
function fw(e, t, r) {
  switch (r.length) {
    case 0:
      return e.call(t);
    case 1:
      return e.call(t, r[0]);
    case 2:
      return e.call(t, r[0], r[1]);
    case 3:
      return e.call(t, r[0], r[1], r[2]);
  }
  return e.apply(t, r);
}
var Xh = Math.max;
function gw(e, t, r) {
  return t = Xh(t === void 0 ? e.length - 1 : t, 0), function() {
    for (var i = arguments, s = -1, o = Xh(i.length - t, 0), a = Array(o); ++s < o; )
      a[s] = i[t + s];
    s = -1;
    for (var n = Array(t + 1); ++s < t; )
      n[s] = i[s];
    return n[t] = r(a), fw(e, this, n);
  };
}
function mw(e) {
  return function() {
    return e;
  };
}
var yw = so ? function(e, t) {
  return so(e, "toString", {
    configurable: !0,
    enumerable: !1,
    value: mw(t),
    writable: !0
  });
} : ef, Cw = 800, xw = 16, bw = Date.now;
function kw(e) {
  var t = 0, r = 0;
  return function() {
    var i = bw(), s = xw - (i - r);
    if (r = i, s > 0) {
      if (++t >= Cw)
        return arguments[0];
    } else
      t = 0;
    return e.apply(void 0, arguments);
  };
}
var Tw = kw(yw);
function ww(e, t) {
  return Tw(gw(e, t, ef), e + "");
}
function Sw(e, t, r) {
  if (!Br(r))
    return !1;
  var i = typeof t;
  return (i == "number" ? Eo(r) && Qp(t, r.length) : i == "string" && t in r) ? Lo(r[t], e) : !1;
}
function _w(e) {
  return ww(function(t, r) {
    var i = -1, s = r.length, o = s > 1 ? r[s - 1] : void 0, a = s > 2 ? r[2] : void 0;
    for (o = e.length > 3 && typeof o == "function" ? (s--, o) : void 0, a && Sw(r[0], r[1], a) && (o = s < 3 ? void 0 : o, s = 1), t = Object(t); ++i < s; ) {
      var n = r[i];
      n && e(t, n, i, o);
    }
    return t;
  });
}
var vw = _w(function(e, t, r) {
  tf(e, t, r);
}), Bw = "​", Lw = {
  curveBasis: Na,
  curveBasisClosed: $1,
  curveBasisOpen: O1,
  curveBumpX: zu,
  curveBumpY: Wu,
  curveBundle: I1,
  curveCardinalClosed: D1,
  curveCardinalOpen: P1,
  curveCardinal: Uu,
  curveCatmullRomClosed: R1,
  curveCatmullRomOpen: N1,
  curveCatmullRom: Xu,
  curveLinear: $i,
  curveLinearClosed: q1,
  curveMonotoneX: td,
  curveMonotoneY: ed,
  curveNatural: id,
  curveStep: sd,
  curveStepAfter: ad,
  curveStepBefore: od
}, Fw = /\s*(?:(\w+)(?=:):|(\w+))\s*(?:(\w+)|((?:(?!}%{2}).|\r?\n)*))?\s*(?:}%{2})?/gi, Aw = /* @__PURE__ */ f(function(e, t) {
  const r = rf(e, /(?:init\b)|(?:initialize\b)/);
  let i = {};
  if (Array.isArray(r)) {
    const a = r.map((n) => n.args);
    Ps(a), i = $t(i, [...a]);
  } else
    i = r.args;
  if (!i)
    return;
  let s = Bn(e, t);
  const o = "config";
  return i[o] !== void 0 && (s === "flowchart-v2" && (s = "flowchart"), i[s] = i[o], delete i[o]), i;
}, "detectInit"), rf = /* @__PURE__ */ f(function(e, t = null) {
  try {
    const r = new RegExp(
      `[%]{2}(?![{]${Fw.source})(?=[}][%]{2}).*
`,
      "ig"
    );
    e = e.trim().replace(r, "").replace(/'/gm, '"'), R.debug(
      `Detecting diagram directive${t !== null ? " type:" + t : ""} based on the text:${e}`
    );
    let i;
    const s = [];
    for (; (i = Mi.exec(e)) !== null; )
      if (i.index === Mi.lastIndex && Mi.lastIndex++, i && !t || t && i[1]?.match(t) || t && i[2]?.match(t)) {
        const o = i[1] ? i[1] : i[2], a = i[3] ? i[3].trim() : i[4] ? JSON.parse(i[4].trim()) : null;
        s.push({ type: o, args: a });
      }
    return s.length === 0 ? { type: e, args: null } : s.length === 1 ? s[0] : s;
  } catch (r) {
    return R.error(
      `ERROR: ${r.message} - Unable to parse directive type: '${t}' based on the text: '${e}'`
    ), { type: void 0, args: null };
  }
}, "detectDirective"), Mw = /* @__PURE__ */ f(function(e) {
  return e.replace(Mi, "");
}, "removeDirectives"), Ew = /* @__PURE__ */ f(function(e, t) {
  for (const [r, i] of t.entries())
    if (i.match(e))
      return r;
  return -1;
}, "isSubstringInArray");
function il(e, t) {
  if (!e)
    return t;
  const r = `curve${e.charAt(0).toUpperCase() + e.slice(1)}`;
  return Lw[r] ?? t;
}
f(il, "interpolateToCurve");
function sf(e, t) {
  const r = e.trim();
  if (r)
    return t.securityLevel !== "loose" ? Qk.sanitizeUrl(r) : r;
}
f(sf, "formatUrl");
var $w = /* @__PURE__ */ f((e, ...t) => {
  const r = e.split("."), i = r.length - 1, s = r[i];
  let o = window;
  for (let a = 0; a < i; a++)
    if (o = o[r[a]], !o) {
      R.error(`Function name: ${e} not found in window`);
      return;
    }
  o[s](...t);
}, "runFunc");
function sl(e, t) {
  return !e || !t ? 0 : Math.sqrt(Math.pow(t.x - e.x, 2) + Math.pow(t.y - e.y, 2));
}
f(sl, "distance");
function of(e) {
  let t, r = 0;
  e.forEach((s) => {
    r += sl(s, t), t = s;
  });
  const i = r / 2;
  return ol(e, i);
}
f(of, "traverseEdge");
function af(e) {
  return e.length === 1 ? e[0] : of(e);
}
f(af, "calcLabelPosition");
var Vh = /* @__PURE__ */ f((e, t = 2) => {
  const r = Math.pow(10, t);
  return Math.round(e * r) / r;
}, "roundNumber"), ol = /* @__PURE__ */ f((e, t) => {
  let r, i = t;
  for (const s of e) {
    if (r) {
      const o = sl(s, r);
      if (o === 0)
        return r;
      if (o < i)
        i -= o;
      else {
        const a = i / o;
        if (a <= 0)
          return r;
        if (a >= 1)
          return { x: s.x, y: s.y };
        if (a > 0 && a < 1)
          return {
            x: Vh((1 - a) * r.x + a * s.x, 5),
            y: Vh((1 - a) * r.y + a * s.y, 5)
          };
      }
    }
    r = s;
  }
  throw new Error("Could not find a suitable point for the given distance");
}, "calculatePoint"), Ow = /* @__PURE__ */ f((e, t, r) => {
  R.info(`our points ${JSON.stringify(t)}`), t[0] !== r && (t = t.reverse());
  const s = ol(t, 25), o = e ? 10 : 5, a = Math.atan2(t[0].y - s.y, t[0].x - s.x), n = { x: 0, y: 0 };
  return n.x = Math.sin(a) * o + (t[0].x + s.x) / 2, n.y = -Math.cos(a) * o + (t[0].y + s.y) / 2, n;
}, "calcCardinalityPosition");
function nf(e, t, r) {
  const i = structuredClone(r);
  R.info("our points", i), t !== "start_left" && t !== "start_right" && i.reverse();
  const s = 25 + e, o = ol(i, s), a = 10 + e * 0.5, n = Math.atan2(i[0].y - o.y, i[0].x - o.x), l = { x: 0, y: 0 };
  return t === "start_left" ? (l.x = Math.sin(n + Math.PI) * a + (i[0].x + o.x) / 2, l.y = -Math.cos(n + Math.PI) * a + (i[0].y + o.y) / 2) : t === "end_right" ? (l.x = Math.sin(n - Math.PI) * a + (i[0].x + o.x) / 2 - 5, l.y = -Math.cos(n - Math.PI) * a + (i[0].y + o.y) / 2 - 5) : t === "end_left" ? (l.x = Math.sin(n) * a + (i[0].x + o.x) / 2 - 5, l.y = -Math.cos(n) * a + (i[0].y + o.y) / 2 - 5) : (l.x = Math.sin(n) * a + (i[0].x + o.x) / 2, l.y = -Math.cos(n) * a + (i[0].y + o.y) / 2), l;
}
f(nf, "calcTerminalLabelPosition");
function lf(e) {
  let t = "", r = "";
  for (const i of e)
    i !== void 0 && (i.startsWith("color:") || i.startsWith("text-align:") ? r = r + i + ";" : t = t + i + ";");
  return { style: t, labelStyle: r };
}
f(lf, "getStylesFromArray");
var Zh = 0, Iw = /* @__PURE__ */ f(() => (Zh++, "id-" + Math.random().toString(36).substr(2, 12) + "-" + Zh), "generateId");
function hf(e) {
  let t = "";
  const r = "0123456789abcdef", i = r.length;
  for (let s = 0; s < e; s++)
    t += r.charAt(Math.floor(Math.random() * i));
  return t;
}
f(hf, "makeRandomHex");
var Dw = /* @__PURE__ */ f((e) => hf(e.length), "random"), Pw = /* @__PURE__ */ f(function() {
  return {
    x: 0,
    y: 0,
    fill: void 0,
    anchor: "start",
    style: "#666",
    width: 100,
    height: 100,
    textMargin: 0,
    rx: 0,
    ry: 0,
    valign: void 0,
    text: ""
  };
}, "getTextObj"), Rw = /* @__PURE__ */ f(function(e, t) {
  const r = t.text.replace(Qi.lineBreakRegex, " "), [, i] = $o(t.fontSize), s = e.append("text");
  s.attr("x", t.x), s.attr("y", t.y), s.style("text-anchor", t.anchor), s.style("font-family", t.fontFamily), s.style("font-size", i), s.style("font-weight", t.fontWeight), s.attr("fill", t.fill), t.class !== void 0 && s.attr("class", t.class);
  const o = s.append("tspan");
  return o.attr("x", t.x + t.textMargin * 2), o.attr("fill", t.fill), o.text(r), s;
}, "drawSimpleText"), Nw = rs(
  (e, t, r) => {
    if (!e || (r = Object.assign(
      { fontSize: 12, fontWeight: 400, fontFamily: "Arial", joinWith: "<br/>" },
      r
    ), Qi.lineBreakRegex.test(e)))
      return e;
    const i = e.split(" ").filter(Boolean), s = [];
    let o = "";
    return i.forEach((a, n) => {
      const l = He(`${a} `, r), c = He(o, r);
      if (l > t) {
        const { hyphenatedStrings: p, remainingWord: d } = qw(a, t, "-", r);
        s.push(o, ...p), o = d;
      } else c + l >= t ? (s.push(o), o = a) : o = [o, a].filter(Boolean).join(" ");
      n + 1 === i.length && s.push(o);
    }), s.filter((a) => a !== "").join(r.joinWith);
  },
  (e, t, r) => `${e}${t}${r.fontSize}${r.fontWeight}${r.fontFamily}${r.joinWith}`
), qw = rs(
  (e, t, r = "-", i) => {
    i = Object.assign(
      { fontSize: 12, fontWeight: 400, fontFamily: "Arial", margin: 0 },
      i
    );
    const s = [...e], o = [];
    let a = "";
    return s.forEach((n, l) => {
      const c = `${a}${n}`;
      if (He(c, i) >= t) {
        const u = l + 1, p = s.length === u, d = `${c}${r}`;
        o.push(p ? c : d), a = "";
      } else
        a = c;
    }), { hyphenatedStrings: o, remainingWord: a };
  },
  (e, t, r = "-", i) => `${e}${t}${r}${i.fontSize}${i.fontWeight}${i.fontFamily}`
);
function cf(e, t) {
  return al(e, t).height;
}
f(cf, "calculateTextHeight");
function He(e, t) {
  return al(e, t).width;
}
f(He, "calculateTextWidth");
var al = rs(
  (e, t) => {
    const { fontSize: r = 12, fontFamily: i = "Arial", fontWeight: s = 400 } = t;
    if (!e)
      return { width: 0, height: 0 };
    const [, o] = $o(r), a = ["sans-serif", i], n = e.split(Qi.lineBreakRegex), l = [], c = ct("body");
    if (!c.remove)
      return { width: 0, height: 0, lineHeight: 0 };
    const h = c.append("svg");
    for (const p of a) {
      let d = 0;
      const g = { width: 0, height: 0, lineHeight: 0 };
      for (const m of n) {
        const y = Pw();
        y.text = m || Bw;
        const x = Rw(h, y).style("font-size", o).style("font-weight", s).style("font-family", p), b = (x._groups || x)[0][0].getBBox();
        if (b.width === 0 && b.height === 0)
          throw new Error("svg element not in render tree");
        g.width = Math.round(Math.max(g.width, b.width)), d = Math.round(b.height), g.height += d, g.lineHeight = Math.round(Math.max(g.lineHeight, d));
      }
      l.push(g);
    }
    h.remove();
    const u = isNaN(l[1].height) || isNaN(l[1].width) || isNaN(l[1].lineHeight) || l[0].height > l[1].height && l[0].width > l[1].width && l[0].lineHeight > l[1].lineHeight ? 0 : 1;
    return l[u];
  },
  (e, t) => `${e}${t.fontSize}${t.fontWeight}${t.fontFamily}`
), zw = class {
  constructor(e = !1, t) {
    this.count = 0, this.count = t ? t.length : 0, this.next = e ? () => this.count++ : () => Date.now();
  }
  static {
    f(this, "InitIDGenerator");
  }
}, Cs, Ww = /* @__PURE__ */ f(function(e) {
  return Cs = Cs || document.createElement("div"), e = escape(e).replace(/%26/g, "&").replace(/%23/g, "#").replace(/%3B/g, ";"), Cs.innerHTML = e, unescape(Cs.textContent);
}, "entityDecode");
function nl(e) {
  return "str" in e;
}
f(nl, "isDetailedError");
var Hw = /* @__PURE__ */ f((e, t, r, i) => {
  if (!i)
    return;
  const s = e.node()?.getBBox();
  s && e.append("text").text(i).attr("text-anchor", "middle").attr("x", s.x + s.width / 2).attr("y", -r).attr("class", t);
}, "insertTitle"), $o = /* @__PURE__ */ f((e) => {
  if (typeof e == "number")
    return [e, e + "px"];
  const t = parseInt(e ?? "", 10);
  return Number.isNaN(t) ? [void 0, void 0] : e === String(t) ? [t, e + "px"] : [t, e];
}, "parseFontSize");
function ll(e, t) {
  return vw({}, e, t);
}
f(ll, "cleanAndMerge");
var me = {
  assignWithDepth: $t,
  wrapLabel: Nw,
  calculateTextHeight: cf,
  calculateTextWidth: He,
  calculateTextDimensions: al,
  cleanAndMerge: ll,
  detectInit: Aw,
  detectDirective: rf,
  isSubstringInArray: Ew,
  interpolateToCurve: il,
  calcLabelPosition: af,
  calcCardinalityPosition: Ow,
  calcTerminalLabelPosition: nf,
  formatUrl: sf,
  getStylesFromArray: lf,
  generateId: Iw,
  random: Dw,
  runFunc: $w,
  entityDecode: Ww,
  insertTitle: Hw,
  isLabelCoordinateInPath: uf,
  parseFontSize: $o,
  InitIDGenerator: zw
}, Yw = /* @__PURE__ */ f(function(e) {
  let t = e;
  return t = t.replace(/style.*:\S*#.*;/g, function(r) {
    return r.substring(0, r.length - 1);
  }), t = t.replace(/classDef.*:\S*#.*;/g, function(r) {
    return r.substring(0, r.length - 1);
  }), t = t.replace(/#\w+;/g, function(r) {
    const i = r.substring(1, r.length - 1);
    return /^\+?\d+$/.test(i) ? "ﬂ°°" + i + "¶ß" : "ﬂ°" + i + "¶ß";
  }), t;
}, "encodeEntities"), Sr = /* @__PURE__ */ f(function(e) {
  return e.replace(/ﬂ°°/g, "&#").replace(/ﬂ°/g, "&").replace(/¶ß/g, ";");
}, "decodeEntities"), CA = /* @__PURE__ */ f((e, t, {
  counter: r = 0,
  prefix: i,
  suffix: s
}, o) => o || `${i ? `${i}_` : ""}${e}_${t}_${r}${s ? `_${s}` : ""}`, "getEdgeId");
function Dt(e) {
  return e ?? null;
}
f(Dt, "handleUndefinedAttr");
function uf(e, t) {
  const r = Math.round(e.x), i = Math.round(e.y), s = t.replace(
    /(\d+\.\d+)/g,
    (o) => Math.round(parseFloat(o)).toString()
  );
  return s.includes(r.toString()) || s.includes(i.toString());
}
f(uf, "isLabelCoordinateInPath");
var hl = /* @__PURE__ */ f(({
  flowchart: e
}) => {
  const t = e?.subGraphTitleMargin?.top ?? 0, r = e?.subGraphTitleMargin?.bottom ?? 0, i = t + r;
  return {
    subGraphTitleTopMargin: t,
    subGraphTitleBottomMargin: r,
    subGraphTitleTotalMargin: i
  };
}, "getSubGraphTitleMargins");
async function df(e, t) {
  const r = e.getElementsByTagName("img");
  if (!r || r.length === 0)
    return;
  const i = t.replace(/<img[^>]*>/g, "").trim() === "";
  await Promise.all(
    [...r].map(
      (s) => new Promise((o) => {
        function a() {
          if (s.style.display = "flex", s.style.flexDirection = "column", i) {
            const n = gt().fontSize ? gt().fontSize : window.getComputedStyle(document.body).fontSize, l = 5, [c = tu.fontSize] = $o(n), h = c * l + "px";
            s.style.minWidth = h, s.style.maxWidth = h;
          } else
            s.style.width = "100%";
          o(s);
        }
        f(a, "setupImage"), setTimeout(() => {
          s.complete && a();
        }), s.addEventListener("error", a), s.addEventListener("load", a);
      })
    )
  );
}
f(df, "configureLabelImages");
var jw = /* @__PURE__ */ f((e) => {
  const { handDrawnSeed: t } = gt();
  return {
    fill: e,
    hachureAngle: 120,
    // angle of hachure,
    hachureGap: 4,
    fillWeight: 2,
    roughness: 0.7,
    stroke: e,
    seed: t
  };
}, "solidStateFill"), si = /* @__PURE__ */ f((e) => {
  const t = Uw([
    ...e.cssCompiledStyles || [],
    ...e.cssStyles || [],
    ...e.labelStyle || []
  ]);
  return { stylesMap: t, stylesArray: [...t] };
}, "compileStyles"), Uw = /* @__PURE__ */ f((e) => {
  const t = /* @__PURE__ */ new Map();
  return e.forEach((r) => {
    const [i, s] = r.split(":");
    t.set(i.trim(), s?.trim());
  }), t;
}, "styles2Map"), pf = /* @__PURE__ */ f((e) => e === "color" || e === "font-size" || e === "font-family" || e === "font-weight" || e === "font-style" || e === "text-decoration" || e === "text-align" || e === "text-transform" || e === "line-height" || e === "letter-spacing" || e === "word-spacing" || e === "text-shadow" || e === "text-overflow" || e === "white-space" || e === "word-wrap" || e === "word-break" || e === "overflow-wrap" || e === "hyphens", "isLabelStyle"), V = /* @__PURE__ */ f((e) => {
  const { stylesArray: t } = si(e), r = [], i = [], s = [], o = [];
  return t.forEach((a) => {
    const n = a[0];
    pf(n) ? r.push(a.join(":") + " !important") : (i.push(a.join(":") + " !important"), n.includes("stroke") && s.push(a.join(":") + " !important"), n === "fill" && o.push(a.join(":") + " !important"));
  }), {
    labelStyles: r.join(";"),
    nodeStyles: i.join(";"),
    stylesArray: t,
    borderStyles: s,
    backgroundStyles: o
  };
}, "styles2String"), X = /* @__PURE__ */ f((e, t) => {
  const { themeVariables: r, handDrawnSeed: i } = gt(), { nodeBorder: s, mainBkg: o } = r, { stylesMap: a } = si(e);
  return Object.assign(
    {
      roughness: 0.7,
      fill: a.get("fill") || o,
      fillStyle: "hachure",
      // solid fill
      fillWeight: 4,
      hachureGap: 5.2,
      stroke: a.get("stroke") || s,
      seed: i,
      strokeWidth: a.get("stroke-width")?.replace("px", "") || 1.3,
      fillLineDash: [0, 0],
      strokeLineDash: Gw(a.get("stroke-dasharray"))
    },
    t
  );
}, "userNodeOverrides"), Gw = /* @__PURE__ */ f((e) => {
  if (!e)
    return [0, 0];
  const t = e.trim().split(/\s+/).map(Number);
  if (t.length === 1) {
    const s = isNaN(t[0]) ? 0 : t[0];
    return [s, s];
  }
  const r = isNaN(t[0]) ? 0 : t[0], i = isNaN(t[1]) ? 0 : t[1];
  return [r, i];
}, "getStrokeDashArray");
const Xw = Object.freeze({
  left: 0,
  top: 0,
  width: 16,
  height: 16
}), no = Object.freeze({
  rotate: 0,
  vFlip: !1,
  hFlip: !1
}), ff = Object.freeze({
  ...Xw,
  ...no
}), Vw = Object.freeze({
  ...ff,
  body: "",
  hidden: !1
}), Zw = Object.freeze({
  width: null,
  height: null
}), Kw = Object.freeze({
  ...Zw,
  ...no
}), Qw = (e, t, r, i = "") => {
  const s = e.split(":");
  if (e.slice(0, 1) === "@") {
    if (s.length < 2 || s.length > 3) return null;
    i = s.shift().slice(1);
  }
  if (s.length > 3 || !s.length) return null;
  if (s.length > 1) {
    const n = s.pop(), l = s.pop(), c = {
      provider: s.length > 0 ? s[0] : i,
      prefix: l,
      name: n
    };
    return pa(c) ? c : null;
  }
  const o = s[0], a = o.split("-");
  if (a.length > 1) {
    const n = {
      provider: i,
      prefix: a.shift(),
      name: a.join("-")
    };
    return pa(n) ? n : null;
  }
  if (r && i === "") {
    const n = {
      provider: i,
      prefix: "",
      name: o
    };
    return pa(n, r) ? n : null;
  }
  return null;
}, pa = (e, t) => e ? !!((t && e.prefix === "" || e.prefix) && e.name) : !1;
function Jw(e, t) {
  const r = {};
  !e.hFlip != !t.hFlip && (r.hFlip = !0), !e.vFlip != !t.vFlip && (r.vFlip = !0);
  const i = ((e.rotate || 0) + (t.rotate || 0)) % 4;
  return i && (r.rotate = i), r;
}
function Kh(e, t) {
  const r = Jw(e, t);
  for (const i in Vw) i in no ? i in e && !(i in r) && (r[i] = no[i]) : i in t ? r[i] = t[i] : i in e && (r[i] = e[i]);
  return r;
}
function tS(e, t) {
  const r = e.icons, i = e.aliases || /* @__PURE__ */ Object.create(null), s = /* @__PURE__ */ Object.create(null);
  function o(a) {
    if (r[a]) return s[a] = [];
    if (!(a in s)) {
      s[a] = null;
      const n = i[a] && i[a].parent, l = n && o(n);
      l && (s[a] = [n].concat(l));
    }
    return s[a];
  }
  return (t || Object.keys(r).concat(Object.keys(i))).forEach(o), s;
}
function Qh(e, t, r) {
  const i = e.icons, s = e.aliases || /* @__PURE__ */ Object.create(null);
  let o = {};
  function a(n) {
    o = Kh(i[n] || s[n], o);
  }
  return a(t), r.forEach(a), Kh(e, o);
}
function eS(e, t) {
  if (e.icons[t]) return Qh(e, t, []);
  const r = tS(e, [t])[t];
  return r ? Qh(e, t, r) : null;
}
const rS = /(-?[0-9.]*[0-9]+[0-9.]*)/g, iS = /^-?[0-9.]*[0-9]+[0-9.]*$/g;
function Jh(e, t, r) {
  if (t === 1) return e;
  if (r = r || 100, typeof e == "number") return Math.ceil(e * t * r) / r;
  if (typeof e != "string") return e;
  const i = e.split(rS);
  if (i === null || !i.length) return e;
  const s = [];
  let o = i.shift(), a = iS.test(o);
  for (; ; ) {
    if (a) {
      const n = parseFloat(o);
      isNaN(n) ? s.push(o) : s.push(Math.ceil(n * t * r) / r);
    } else s.push(o);
    if (o = i.shift(), o === void 0) return s.join("");
    a = !a;
  }
}
function sS(e, t = "defs") {
  let r = "";
  const i = e.indexOf("<" + t);
  for (; i >= 0; ) {
    const s = e.indexOf(">", i), o = e.indexOf("</" + t);
    if (s === -1 || o === -1) break;
    const a = e.indexOf(">", o);
    if (a === -1) break;
    r += e.slice(s + 1, o).trim(), e = e.slice(0, i).trim() + e.slice(a + 1);
  }
  return {
    defs: r,
    content: e
  };
}
function oS(e, t) {
  return e ? "<defs>" + e + "</defs>" + t : t;
}
function aS(e, t, r) {
  const i = sS(e);
  return oS(i.defs, t + i.content + r);
}
const nS = (e) => e === "unset" || e === "undefined" || e === "none";
function lS(e, t) {
  const r = {
    ...ff,
    ...e
  }, i = {
    ...Kw,
    ...t
  }, s = {
    left: r.left,
    top: r.top,
    width: r.width,
    height: r.height
  };
  let o = r.body;
  [r, i].forEach((m) => {
    const y = [], x = m.hFlip, b = m.vFlip;
    let k = m.rotate;
    x ? b ? k += 2 : (y.push("translate(" + (s.width + s.left).toString() + " " + (0 - s.top).toString() + ")"), y.push("scale(-1 1)"), s.top = s.left = 0) : b && (y.push("translate(" + (0 - s.left).toString() + " " + (s.height + s.top).toString() + ")"), y.push("scale(1 -1)"), s.top = s.left = 0);
    let w;
    switch (k < 0 && (k -= Math.floor(k / 4) * 4), k = k % 4, k) {
      case 1:
        w = s.height / 2 + s.top, y.unshift("rotate(90 " + w.toString() + " " + w.toString() + ")");
        break;
      case 2:
        y.unshift("rotate(180 " + (s.width / 2 + s.left).toString() + " " + (s.height / 2 + s.top).toString() + ")");
        break;
      case 3:
        w = s.width / 2 + s.left, y.unshift("rotate(-90 " + w.toString() + " " + w.toString() + ")");
        break;
    }
    k % 2 === 1 && (s.left !== s.top && (w = s.left, s.left = s.top, s.top = w), s.width !== s.height && (w = s.width, s.width = s.height, s.height = w)), y.length && (o = aS(o, '<g transform="' + y.join(" ") + '">', "</g>"));
  });
  const a = i.width, n = i.height, l = s.width, c = s.height;
  let h, u;
  a === null ? (u = n === null ? "1em" : n === "auto" ? c : n, h = Jh(u, l / c)) : (h = a === "auto" ? l : a, u = n === null ? Jh(h, c / l) : n === "auto" ? c : n);
  const p = {}, d = (m, y) => {
    nS(y) || (p[m] = y.toString());
  };
  d("width", h), d("height", u);
  const g = [
    s.left,
    s.top,
    l,
    c
  ];
  return p.viewBox = g.join(" "), {
    attributes: p,
    viewBox: g,
    body: o
  };
}
const hS = /\sid="(\S+)"/g, tc = /* @__PURE__ */ new Map();
function cS(e) {
  e = e.replace(/[0-9]+$/, "") || "a";
  const t = tc.get(e) || 0;
  return tc.set(e, t + 1), t ? `${e}${t}` : e;
}
function uS(e) {
  const t = [];
  let r;
  for (; r = hS.exec(e); ) t.push(r[1]);
  if (!t.length) return e;
  const i = "suffix" + (Math.random() * 16777216 | Date.now()).toString(16);
  return t.forEach((s) => {
    const o = cS(s), a = s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    e = e.replace(new RegExp('([#;"])(' + a + ')([")]|\\.[a-z])', "g"), "$1" + o + i + "$3");
  }), e = e.replace(new RegExp(i, "g"), ""), e;
}
function dS(e, t) {
  let r = e.indexOf("xlink:") === -1 ? "" : ' xmlns:xlink="http://www.w3.org/1999/xlink"';
  for (const i in t) r += " " + i + '="' + t[i] + '"';
  return '<svg xmlns="http://www.w3.org/2000/svg"' + r + ">" + e + "</svg>";
}
function cl() {
  return { async: !1, breaks: !1, extensions: null, gfm: !0, hooks: null, pedantic: !1, renderer: null, silent: !1, tokenizer: null, walkTokens: null };
}
var Ar = cl();
function gf(e) {
  Ar = e;
}
var Ii = { exec: () => null };
function mt(e, t = "") {
  let r = typeof e == "string" ? e : e.source, i = { replace: (s, o) => {
    let a = typeof o == "string" ? o : o.source;
    return a = a.replace(Gt.caret, "$1"), r = r.replace(s, a), i;
  }, getRegex: () => new RegExp(r, t) };
  return i;
}
var pS = (() => {
  try {
    return !!new RegExp("(?<=1)(?<!1)");
  } catch {
    return !1;
  }
})(), Gt = { codeRemoveIndent: /^(?: {1,4}| {0,3}\t)/gm, outputLinkReplace: /\\([\[\]])/g, indentCodeCompensation: /^(\s+)(?:```)/, beginningSpace: /^\s+/, endingHash: /#$/, startingSpaceChar: /^ /, endingSpaceChar: / $/, nonSpaceChar: /[^ ]/, newLineCharGlobal: /\n/g, tabCharGlobal: /\t/g, multipleSpaceGlobal: /\s+/g, blankLine: /^[ \t]*$/, doubleBlankLine: /\n[ \t]*\n[ \t]*$/, blockquoteStart: /^ {0,3}>/, blockquoteSetextReplace: /\n {0,3}((?:=+|-+) *)(?=\n|$)/g, blockquoteSetextReplace2: /^ {0,3}>[ \t]?/gm, listReplaceTabs: /^\t+/, listReplaceNesting: /^ {1,4}(?=( {4})*[^ ])/g, listIsTask: /^\[[ xX]\] /, listReplaceTask: /^\[[ xX]\] +/, anyLine: /\n.*\n/, hrefBrackets: /^<(.*)>$/, tableDelimiter: /[:|]/, tableAlignChars: /^\||\| *$/g, tableRowBlankLine: /\n[ \t]*$/, tableAlignRight: /^ *-+: *$/, tableAlignCenter: /^ *:-+: *$/, tableAlignLeft: /^ *:-+ *$/, startATag: /^<a /i, endATag: /^<\/a>/i, startPreScriptTag: /^<(pre|code|kbd|script)(\s|>)/i, endPreScriptTag: /^<\/(pre|code|kbd|script)(\s|>)/i, startAngleBracket: /^</, endAngleBracket: />$/, pedanticHrefTitle: /^([^'"]*[^\s])\s+(['"])(.*)\2/, unicodeAlphaNumeric: /[\p{L}\p{N}]/u, escapeTest: /[&<>"']/, escapeReplace: /[&<>"']/g, escapeTestNoEncode: /[<>"']|&(?!(#\d{1,7}|#[Xx][a-fA-F0-9]{1,6}|\w+);)/, escapeReplaceNoEncode: /[<>"']|&(?!(#\d{1,7}|#[Xx][a-fA-F0-9]{1,6}|\w+);)/g, unescapeTest: /&(#(?:\d+)|(?:#x[0-9A-Fa-f]+)|(?:\w+));?/ig, caret: /(^|[^\[])\^/g, percentDecode: /%25/g, findPipe: /\|/g, splitPipe: / \|/, slashPipe: /\\\|/g, carriageReturn: /\r\n|\r/g, spaceLine: /^ +$/gm, notSpaceStart: /^\S*/, endingNewline: /\n$/, listItemRegex: (e) => new RegExp(`^( {0,3}${e})((?:[	 ][^\\n]*)?(?:\\n|$))`), nextBulletRegex: (e) => new RegExp(`^ {0,${Math.min(3, e - 1)}}(?:[*+-]|\\d{1,9}[.)])((?:[ 	][^\\n]*)?(?:\\n|$))`), hrRegex: (e) => new RegExp(`^ {0,${Math.min(3, e - 1)}}((?:- *){3,}|(?:_ *){3,}|(?:\\* *){3,})(?:\\n+|$)`), fencesBeginRegex: (e) => new RegExp(`^ {0,${Math.min(3, e - 1)}}(?:\`\`\`|~~~)`), headingBeginRegex: (e) => new RegExp(`^ {0,${Math.min(3, e - 1)}}#`), htmlBeginRegex: (e) => new RegExp(`^ {0,${Math.min(3, e - 1)}}<(?:[a-z].*>|!--)`, "i") }, fS = /^(?:[ \t]*(?:\n|$))+/, gS = /^((?: {4}| {0,3}\t)[^\n]+(?:\n(?:[ \t]*(?:\n|$))*)?)+/, mS = /^ {0,3}(`{3,}(?=[^`\n]*(?:\n|$))|~{3,})([^\n]*)(?:\n|$)(?:|([\s\S]*?)(?:\n|$))(?: {0,3}\1[~`]* *(?=\n|$)|$)/, ss = /^ {0,3}((?:-[\t ]*){3,}|(?:_[ \t]*){3,}|(?:\*[ \t]*){3,})(?:\n+|$)/, yS = /^ {0,3}(#{1,6})(?=\s|$)(.*)(?:\n+|$)/, ul = /(?:[*+-]|\d{1,9}[.)])/, mf = /^(?!bull |blockCode|fences|blockquote|heading|html|table)((?:.|\n(?!\s*?\n|bull |blockCode|fences|blockquote|heading|html|table))+?)\n {0,3}(=+|-+) *(?:\n+|$)/, yf = mt(mf).replace(/bull/g, ul).replace(/blockCode/g, /(?: {4}| {0,3}\t)/).replace(/fences/g, / {0,3}(?:`{3,}|~{3,})/).replace(/blockquote/g, / {0,3}>/).replace(/heading/g, / {0,3}#{1,6}/).replace(/html/g, / {0,3}<[^\n>]+>\n/).replace(/\|table/g, "").getRegex(), CS = mt(mf).replace(/bull/g, ul).replace(/blockCode/g, /(?: {4}| {0,3}\t)/).replace(/fences/g, / {0,3}(?:`{3,}|~{3,})/).replace(/blockquote/g, / {0,3}>/).replace(/heading/g, / {0,3}#{1,6}/).replace(/html/g, / {0,3}<[^\n>]+>\n/).replace(/table/g, / {0,3}\|?(?:[:\- ]*\|)+[\:\- ]*\n/).getRegex(), dl = /^([^\n]+(?:\n(?!hr|heading|lheading|blockquote|fences|list|html|table| +\n)[^\n]+)*)/, xS = /^[^\n]+/, pl = /(?!\s*\])(?:\\[\s\S]|[^\[\]\\])+/, bS = mt(/^ {0,3}\[(label)\]: *(?:\n[ \t]*)?([^<\s][^\s]*|<.*?>)(?:(?: +(?:\n[ \t]*)?| *\n[ \t]*)(title))? *(?:\n+|$)/).replace("label", pl).replace("title", /(?:"(?:\\"?|[^"\\])*"|'[^'\n]*(?:\n[^'\n]+)*\n?'|\([^()]*\))/).getRegex(), kS = mt(/^( {0,3}bull)([ \t][^\n]+?)?(?:\n|$)/).replace(/bull/g, ul).getRegex(), Oo = "address|article|aside|base|basefont|blockquote|body|caption|center|col|colgroup|dd|details|dialog|dir|div|dl|dt|fieldset|figcaption|figure|footer|form|frame|frameset|h[1-6]|head|header|hr|html|iframe|legend|li|link|main|menu|menuitem|meta|nav|noframes|ol|optgroup|option|p|param|search|section|summary|table|tbody|td|tfoot|th|thead|title|tr|track|ul", fl = /<!--(?:-?>|[\s\S]*?(?:-->|$))/, TS = mt("^ {0,3}(?:<(script|pre|style|textarea)[\\s>][\\s\\S]*?(?:</\\1>[^\\n]*\\n+|$)|comment[^\\n]*(\\n+|$)|<\\?[\\s\\S]*?(?:\\?>\\n*|$)|<![A-Z][\\s\\S]*?(?:>\\n*|$)|<!\\[CDATA\\[[\\s\\S]*?(?:\\]\\]>\\n*|$)|</?(tag)(?: +|\\n|/?>)[\\s\\S]*?(?:(?:\\n[ 	]*)+\\n|$)|<(?!script|pre|style|textarea)([a-z][\\w-]*)(?:attribute)*? */?>(?=[ \\t]*(?:\\n|$))[\\s\\S]*?(?:(?:\\n[ 	]*)+\\n|$)|</(?!script|pre|style|textarea)[a-z][\\w-]*\\s*>(?=[ \\t]*(?:\\n|$))[\\s\\S]*?(?:(?:\\n[ 	]*)+\\n|$))", "i").replace("comment", fl).replace("tag", Oo).replace("attribute", / +[a-zA-Z:_][\w.:-]*(?: *= *"[^"\n]*"| *= *'[^'\n]*'| *= *[^\s"'=<>`]+)?/).getRegex(), Cf = mt(dl).replace("hr", ss).replace("heading", " {0,3}#{1,6}(?:\\s|$)").replace("|lheading", "").replace("|table", "").replace("blockquote", " {0,3}>").replace("fences", " {0,3}(?:`{3,}(?=[^`\\n]*\\n)|~{3,})[^\\n]*\\n").replace("list", " {0,3}(?:[*+-]|1[.)]) ").replace("html", "</?(?:tag)(?: +|\\n|/?>)|<(?:script|pre|style|textarea|!--)").replace("tag", Oo).getRegex(), wS = mt(/^( {0,3}> ?(paragraph|[^\n]*)(?:\n|$))+/).replace("paragraph", Cf).getRegex(), gl = { blockquote: wS, code: gS, def: bS, fences: mS, heading: yS, hr: ss, html: TS, lheading: yf, list: kS, newline: fS, paragraph: Cf, table: Ii, text: xS }, ec = mt("^ *([^\\n ].*)\\n {0,3}((?:\\| *)?:?-+:? *(?:\\| *:?-+:? *)*(?:\\| *)?)(?:\\n((?:(?! *\\n|hr|heading|blockquote|code|fences|list|html).*(?:\\n|$))*)\\n*|$)").replace("hr", ss).replace("heading", " {0,3}#{1,6}(?:\\s|$)").replace("blockquote", " {0,3}>").replace("code", "(?: {4}| {0,3}	)[^\\n]").replace("fences", " {0,3}(?:`{3,}(?=[^`\\n]*\\n)|~{3,})[^\\n]*\\n").replace("list", " {0,3}(?:[*+-]|1[.)]) ").replace("html", "</?(?:tag)(?: +|\\n|/?>)|<(?:script|pre|style|textarea|!--)").replace("tag", Oo).getRegex(), SS = { ...gl, lheading: CS, table: ec, paragraph: mt(dl).replace("hr", ss).replace("heading", " {0,3}#{1,6}(?:\\s|$)").replace("|lheading", "").replace("table", ec).replace("blockquote", " {0,3}>").replace("fences", " {0,3}(?:`{3,}(?=[^`\\n]*\\n)|~{3,})[^\\n]*\\n").replace("list", " {0,3}(?:[*+-]|1[.)]) ").replace("html", "</?(?:tag)(?: +|\\n|/?>)|<(?:script|pre|style|textarea|!--)").replace("tag", Oo).getRegex() }, _S = { ...gl, html: mt(`^ *(?:comment *(?:\\n|\\s*$)|<(tag)[\\s\\S]+?</\\1> *(?:\\n{2,}|\\s*$)|<tag(?:"[^"]*"|'[^']*'|\\s[^'"/>\\s]*)*?/?> *(?:\\n{2,}|\\s*$))`).replace("comment", fl).replace(/tag/g, "(?!(?:a|em|strong|small|s|cite|q|dfn|abbr|data|time|code|var|samp|kbd|sub|sup|i|b|u|mark|ruby|rt|rp|bdi|bdo|span|br|wbr|ins|del|img)\\b)\\w+(?!:|[^\\w\\s@]*@)\\b").getRegex(), def: /^ *\[([^\]]+)\]: *<?([^\s>]+)>?(?: +(["(][^\n]+[")]))? *(?:\n+|$)/, heading: /^(#{1,6})(.*)(?:\n+|$)/, fences: Ii, lheading: /^(.+?)\n {0,3}(=+|-+) *(?:\n+|$)/, paragraph: mt(dl).replace("hr", ss).replace("heading", ` *#{1,6} *[^
]`).replace("lheading", yf).replace("|table", "").replace("blockquote", " {0,3}>").replace("|fences", "").replace("|list", "").replace("|html", "").replace("|tag", "").getRegex() }, vS = /^\\([!"#$%&'()*+,\-./:;<=>?@\[\]\\^_`{|}~])/, BS = /^(`+)([^`]|[^`][\s\S]*?[^`])\1(?!`)/, xf = /^( {2,}|\\)\n(?!\s*$)/, LS = /^(`+|[^`])(?:(?= {2,}\n)|[\s\S]*?(?:(?=[\\<!\[`*_]|\b_|$)|[^ ](?= {2,}\n)))/, Io = /[\p{P}\p{S}]/u, ml = /[\s\p{P}\p{S}]/u, bf = /[^\s\p{P}\p{S}]/u, FS = mt(/^((?![*_])punctSpace)/, "u").replace(/punctSpace/g, ml).getRegex(), kf = /(?!~)[\p{P}\p{S}]/u, AS = /(?!~)[\s\p{P}\p{S}]/u, MS = /(?:[^\s\p{P}\p{S}]|~)/u, ES = mt(/link|precode-code|html/, "g").replace("link", /\[(?:[^\[\]`]|(?<a>`+)[^`]+\k<a>(?!`))*?\]\((?:\\[\s\S]|[^\\\(\)]|\((?:\\[\s\S]|[^\\\(\)])*\))*\)/).replace("precode-", pS ? "(?<!`)()" : "(^^|[^`])").replace("code", /(?<b>`+)[^`]+\k<b>(?!`)/).replace("html", /<(?! )[^<>]*?>/).getRegex(), Tf = /^(?:\*+(?:((?!\*)punct)|[^\s*]))|^_+(?:((?!_)punct)|([^\s_]))/, $S = mt(Tf, "u").replace(/punct/g, Io).getRegex(), OS = mt(Tf, "u").replace(/punct/g, kf).getRegex(), wf = "^[^_*]*?__[^_*]*?\\*[^_*]*?(?=__)|[^*]+(?=[^*])|(?!\\*)punct(\\*+)(?=[\\s]|$)|notPunctSpace(\\*+)(?!\\*)(?=punctSpace|$)|(?!\\*)punctSpace(\\*+)(?=notPunctSpace)|[\\s](\\*+)(?!\\*)(?=punct)|(?!\\*)punct(\\*+)(?!\\*)(?=punct)|notPunctSpace(\\*+)(?=notPunctSpace)", IS = mt(wf, "gu").replace(/notPunctSpace/g, bf).replace(/punctSpace/g, ml).replace(/punct/g, Io).getRegex(), DS = mt(wf, "gu").replace(/notPunctSpace/g, MS).replace(/punctSpace/g, AS).replace(/punct/g, kf).getRegex(), PS = mt("^[^_*]*?\\*\\*[^_*]*?_[^_*]*?(?=\\*\\*)|[^_]+(?=[^_])|(?!_)punct(_+)(?=[\\s]|$)|notPunctSpace(_+)(?!_)(?=punctSpace|$)|(?!_)punctSpace(_+)(?=notPunctSpace)|[\\s](_+)(?!_)(?=punct)|(?!_)punct(_+)(?!_)(?=punct)", "gu").replace(/notPunctSpace/g, bf).replace(/punctSpace/g, ml).replace(/punct/g, Io).getRegex(), RS = mt(/\\(punct)/, "gu").replace(/punct/g, Io).getRegex(), NS = mt(/^<(scheme:[^\s\x00-\x1f<>]*|email)>/).replace("scheme", /[a-zA-Z][a-zA-Z0-9+.-]{1,31}/).replace("email", /[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+(@)[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+(?![-_])/).getRegex(), qS = mt(fl).replace("(?:-->|$)", "-->").getRegex(), zS = mt("^comment|^</[a-zA-Z][\\w:-]*\\s*>|^<[a-zA-Z][\\w-]*(?:attribute)*?\\s*/?>|^<\\?[\\s\\S]*?\\?>|^<![a-zA-Z]+\\s[\\s\\S]*?>|^<!\\[CDATA\\[[\\s\\S]*?\\]\\]>").replace("comment", qS).replace("attribute", /\s+[a-zA-Z:_][\w.:-]*(?:\s*=\s*"[^"]*"|\s*=\s*'[^']*'|\s*=\s*[^\s"'=<>`]+)?/).getRegex(), lo = /(?:\[(?:\\[\s\S]|[^\[\]\\])*\]|\\[\s\S]|`+[^`]*?`+(?!`)|[^\[\]\\`])*?/, WS = mt(/^!?\[(label)\]\(\s*(href)(?:(?:[ \t]*(?:\n[ \t]*)?)(title))?\s*\)/).replace("label", lo).replace("href", /<(?:\\.|[^\n<>\\])+>|[^ \t\n\x00-\x1f]*/).replace("title", /"(?:\\"?|[^"\\])*"|'(?:\\'?|[^'\\])*'|\((?:\\\)?|[^)\\])*\)/).getRegex(), Sf = mt(/^!?\[(label)\]\[(ref)\]/).replace("label", lo).replace("ref", pl).getRegex(), _f = mt(/^!?\[(ref)\](?:\[\])?/).replace("ref", pl).getRegex(), HS = mt("reflink|nolink(?!\\()", "g").replace("reflink", Sf).replace("nolink", _f).getRegex(), rc = /[hH][tT][tT][pP][sS]?|[fF][tT][pP]/, yl = { _backpedal: Ii, anyPunctuation: RS, autolink: NS, blockSkip: ES, br: xf, code: BS, del: Ii, emStrongLDelim: $S, emStrongRDelimAst: IS, emStrongRDelimUnd: PS, escape: vS, link: WS, nolink: _f, punctuation: FS, reflink: Sf, reflinkSearch: HS, tag: zS, text: LS, url: Ii }, YS = { ...yl, link: mt(/^!?\[(label)\]\((.*?)\)/).replace("label", lo).getRegex(), reflink: mt(/^!?\[(label)\]\s*\[([^\]]*)\]/).replace("label", lo).getRegex() }, sn = { ...yl, emStrongRDelimAst: DS, emStrongLDelim: OS, url: mt(/^((?:protocol):\/\/|www\.)(?:[a-zA-Z0-9\-]+\.?)+[^\s<]*|^email/).replace("protocol", rc).replace("email", /[A-Za-z0-9._+-]+(@)[a-zA-Z0-9-_]+(?:\.[a-zA-Z0-9-_]*[a-zA-Z0-9])+(?![-_])/).getRegex(), _backpedal: /(?:[^?!.,:;*_'"~()&]+|\([^)]*\)|&(?![a-zA-Z0-9]+;$)|[?!.,:;*_'"~)]+(?!$))+/, del: /^(~~?)(?=[^\s~])((?:\\[\s\S]|[^\\])*?(?:\\[\s\S]|[^\s~\\]))\1(?=[^~]|$)/, text: mt(/^([`~]+|[^`~])(?:(?= {2,}\n)|(?=[a-zA-Z0-9.!#$%&'*+\/=?_`{\|}~-]+@)|[\s\S]*?(?:(?=[\\<!\[`*~_]|\b_|protocol:\/\/|www\.|$)|[^ ](?= {2,}\n)|[^a-zA-Z0-9.!#$%&'*+\/=?_`{\|}~-](?=[a-zA-Z0-9.!#$%&'*+\/=?_`{\|}~-]+@)))/).replace("protocol", rc).getRegex() }, jS = { ...sn, br: mt(xf).replace("{2,}", "*").getRegex(), text: mt(sn.text).replace("\\b_", "\\b_| {2,}\\n").replace(/\{2,\}/g, "*").getRegex() }, xs = { normal: gl, gfm: SS, pedantic: _S }, mi = { normal: yl, gfm: sn, breaks: jS, pedantic: YS }, US = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }, ic = (e) => US[e];
function Se(e, t) {
  if (t) {
    if (Gt.escapeTest.test(e)) return e.replace(Gt.escapeReplace, ic);
  } else if (Gt.escapeTestNoEncode.test(e)) return e.replace(Gt.escapeReplaceNoEncode, ic);
  return e;
}
function sc(e) {
  try {
    e = encodeURI(e).replace(Gt.percentDecode, "%");
  } catch {
    return null;
  }
  return e;
}
function oc(e, t) {
  let r = e.replace(Gt.findPipe, (o, a, n) => {
    let l = !1, c = a;
    for (; --c >= 0 && n[c] === "\\"; ) l = !l;
    return l ? "|" : " |";
  }), i = r.split(Gt.splitPipe), s = 0;
  if (i[0].trim() || i.shift(), i.length > 0 && !i.at(-1)?.trim() && i.pop(), t) if (i.length > t) i.splice(t);
  else for (; i.length < t; ) i.push("");
  for (; s < i.length; s++) i[s] = i[s].trim().replace(Gt.slashPipe, "|");
  return i;
}
function yi(e, t, r) {
  let i = e.length;
  if (i === 0) return "";
  let s = 0;
  for (; s < i && e.charAt(i - s - 1) === t; )
    s++;
  return e.slice(0, i - s);
}
function GS(e, t) {
  if (e.indexOf(t[1]) === -1) return -1;
  let r = 0;
  for (let i = 0; i < e.length; i++) if (e[i] === "\\") i++;
  else if (e[i] === t[0]) r++;
  else if (e[i] === t[1] && (r--, r < 0)) return i;
  return r > 0 ? -2 : -1;
}
function ac(e, t, r, i, s) {
  let o = t.href, a = t.title || null, n = e[1].replace(s.other.outputLinkReplace, "$1");
  i.state.inLink = !0;
  let l = { type: e[0].charAt(0) === "!" ? "image" : "link", raw: r, href: o, title: a, text: n, tokens: i.inlineTokens(n) };
  return i.state.inLink = !1, l;
}
function XS(e, t, r) {
  let i = e.match(r.other.indentCodeCompensation);
  if (i === null) return t;
  let s = i[1];
  return t.split(`
`).map((o) => {
    let a = o.match(r.other.beginningSpace);
    if (a === null) return o;
    let [n] = a;
    return n.length >= s.length ? o.slice(s.length) : o;
  }).join(`
`);
}
var ho = class {
  options;
  rules;
  lexer;
  constructor(t) {
    this.options = t || Ar;
  }
  space(t) {
    let r = this.rules.block.newline.exec(t);
    if (r && r[0].length > 0) return { type: "space", raw: r[0] };
  }
  code(t) {
    let r = this.rules.block.code.exec(t);
    if (r) {
      let i = r[0].replace(this.rules.other.codeRemoveIndent, "");
      return { type: "code", raw: r[0], codeBlockStyle: "indented", text: this.options.pedantic ? i : yi(i, `
`) };
    }
  }
  fences(t) {
    let r = this.rules.block.fences.exec(t);
    if (r) {
      let i = r[0], s = XS(i, r[3] || "", this.rules);
      return { type: "code", raw: i, lang: r[2] ? r[2].trim().replace(this.rules.inline.anyPunctuation, "$1") : r[2], text: s };
    }
  }
  heading(t) {
    let r = this.rules.block.heading.exec(t);
    if (r) {
      let i = r[2].trim();
      if (this.rules.other.endingHash.test(i)) {
        let s = yi(i, "#");
        (this.options.pedantic || !s || this.rules.other.endingSpaceChar.test(s)) && (i = s.trim());
      }
      return { type: "heading", raw: r[0], depth: r[1].length, text: i, tokens: this.lexer.inline(i) };
    }
  }
  hr(t) {
    let r = this.rules.block.hr.exec(t);
    if (r) return { type: "hr", raw: yi(r[0], `
`) };
  }
  blockquote(t) {
    let r = this.rules.block.blockquote.exec(t);
    if (r) {
      let i = yi(r[0], `
`).split(`
`), s = "", o = "", a = [];
      for (; i.length > 0; ) {
        let n = !1, l = [], c;
        for (c = 0; c < i.length; c++) if (this.rules.other.blockquoteStart.test(i[c])) l.push(i[c]), n = !0;
        else if (!n) l.push(i[c]);
        else break;
        i = i.slice(c);
        let h = l.join(`
`), u = h.replace(this.rules.other.blockquoteSetextReplace, `
    $1`).replace(this.rules.other.blockquoteSetextReplace2, "");
        s = s ? `${s}
${h}` : h, o = o ? `${o}
${u}` : u;
        let p = this.lexer.state.top;
        if (this.lexer.state.top = !0, this.lexer.blockTokens(u, a, !0), this.lexer.state.top = p, i.length === 0) break;
        let d = a.at(-1);
        if (d?.type === "code") break;
        if (d?.type === "blockquote") {
          let g = d, m = g.raw + `
` + i.join(`
`), y = this.blockquote(m);
          a[a.length - 1] = y, s = s.substring(0, s.length - g.raw.length) + y.raw, o = o.substring(0, o.length - g.text.length) + y.text;
          break;
        } else if (d?.type === "list") {
          let g = d, m = g.raw + `
` + i.join(`
`), y = this.list(m);
          a[a.length - 1] = y, s = s.substring(0, s.length - d.raw.length) + y.raw, o = o.substring(0, o.length - g.raw.length) + y.raw, i = m.substring(a.at(-1).raw.length).split(`
`);
          continue;
        }
      }
      return { type: "blockquote", raw: s, tokens: a, text: o };
    }
  }
  list(t) {
    let r = this.rules.block.list.exec(t);
    if (r) {
      let i = r[1].trim(), s = i.length > 1, o = { type: "list", raw: "", ordered: s, start: s ? +i.slice(0, -1) : "", loose: !1, items: [] };
      i = s ? `\\d{1,9}\\${i.slice(-1)}` : `\\${i}`, this.options.pedantic && (i = s ? i : "[*+-]");
      let a = this.rules.other.listItemRegex(i), n = !1;
      for (; t; ) {
        let c = !1, h = "", u = "";
        if (!(r = a.exec(t)) || this.rules.block.hr.test(t)) break;
        h = r[0], t = t.substring(h.length);
        let p = r[2].split(`
`, 1)[0].replace(this.rules.other.listReplaceTabs, (b) => " ".repeat(3 * b.length)), d = t.split(`
`, 1)[0], g = !p.trim(), m = 0;
        if (this.options.pedantic ? (m = 2, u = p.trimStart()) : g ? m = r[1].length + 1 : (m = r[2].search(this.rules.other.nonSpaceChar), m = m > 4 ? 1 : m, u = p.slice(m), m += r[1].length), g && this.rules.other.blankLine.test(d) && (h += d + `
`, t = t.substring(d.length + 1), c = !0), !c) {
          let b = this.rules.other.nextBulletRegex(m), k = this.rules.other.hrRegex(m), w = this.rules.other.fencesBeginRegex(m), S = this.rules.other.headingBeginRegex(m), v = this.rules.other.htmlBeginRegex(m);
          for (; t; ) {
            let M = t.split(`
`, 1)[0], B;
            if (d = M, this.options.pedantic ? (d = d.replace(this.rules.other.listReplaceNesting, "  "), B = d) : B = d.replace(this.rules.other.tabCharGlobal, "    "), w.test(d) || S.test(d) || v.test(d) || b.test(d) || k.test(d)) break;
            if (B.search(this.rules.other.nonSpaceChar) >= m || !d.trim()) u += `
` + B.slice(m);
            else {
              if (g || p.replace(this.rules.other.tabCharGlobal, "    ").search(this.rules.other.nonSpaceChar) >= 4 || w.test(p) || S.test(p) || k.test(p)) break;
              u += `
` + d;
            }
            !g && !d.trim() && (g = !0), h += M + `
`, t = t.substring(M.length + 1), p = B.slice(m);
          }
        }
        o.loose || (n ? o.loose = !0 : this.rules.other.doubleBlankLine.test(h) && (n = !0));
        let y = null, x;
        this.options.gfm && (y = this.rules.other.listIsTask.exec(u), y && (x = y[0] !== "[ ] ", u = u.replace(this.rules.other.listReplaceTask, ""))), o.items.push({ type: "list_item", raw: h, task: !!y, checked: x, loose: !1, text: u, tokens: [] }), o.raw += h;
      }
      let l = o.items.at(-1);
      if (l) l.raw = l.raw.trimEnd(), l.text = l.text.trimEnd();
      else return;
      o.raw = o.raw.trimEnd();
      for (let c = 0; c < o.items.length; c++) if (this.lexer.state.top = !1, o.items[c].tokens = this.lexer.blockTokens(o.items[c].text, []), !o.loose) {
        let h = o.items[c].tokens.filter((p) => p.type === "space"), u = h.length > 0 && h.some((p) => this.rules.other.anyLine.test(p.raw));
        o.loose = u;
      }
      if (o.loose) for (let c = 0; c < o.items.length; c++) o.items[c].loose = !0;
      return o;
    }
  }
  html(t) {
    let r = this.rules.block.html.exec(t);
    if (r) return { type: "html", block: !0, raw: r[0], pre: r[1] === "pre" || r[1] === "script" || r[1] === "style", text: r[0] };
  }
  def(t) {
    let r = this.rules.block.def.exec(t);
    if (r) {
      let i = r[1].toLowerCase().replace(this.rules.other.multipleSpaceGlobal, " "), s = r[2] ? r[2].replace(this.rules.other.hrefBrackets, "$1").replace(this.rules.inline.anyPunctuation, "$1") : "", o = r[3] ? r[3].substring(1, r[3].length - 1).replace(this.rules.inline.anyPunctuation, "$1") : r[3];
      return { type: "def", tag: i, raw: r[0], href: s, title: o };
    }
  }
  table(t) {
    let r = this.rules.block.table.exec(t);
    if (!r || !this.rules.other.tableDelimiter.test(r[2])) return;
    let i = oc(r[1]), s = r[2].replace(this.rules.other.tableAlignChars, "").split("|"), o = r[3]?.trim() ? r[3].replace(this.rules.other.tableRowBlankLine, "").split(`
`) : [], a = { type: "table", raw: r[0], header: [], align: [], rows: [] };
    if (i.length === s.length) {
      for (let n of s) this.rules.other.tableAlignRight.test(n) ? a.align.push("right") : this.rules.other.tableAlignCenter.test(n) ? a.align.push("center") : this.rules.other.tableAlignLeft.test(n) ? a.align.push("left") : a.align.push(null);
      for (let n = 0; n < i.length; n++) a.header.push({ text: i[n], tokens: this.lexer.inline(i[n]), header: !0, align: a.align[n] });
      for (let n of o) a.rows.push(oc(n, a.header.length).map((l, c) => ({ text: l, tokens: this.lexer.inline(l), header: !1, align: a.align[c] })));
      return a;
    }
  }
  lheading(t) {
    let r = this.rules.block.lheading.exec(t);
    if (r) return { type: "heading", raw: r[0], depth: r[2].charAt(0) === "=" ? 1 : 2, text: r[1], tokens: this.lexer.inline(r[1]) };
  }
  paragraph(t) {
    let r = this.rules.block.paragraph.exec(t);
    if (r) {
      let i = r[1].charAt(r[1].length - 1) === `
` ? r[1].slice(0, -1) : r[1];
      return { type: "paragraph", raw: r[0], text: i, tokens: this.lexer.inline(i) };
    }
  }
  text(t) {
    let r = this.rules.block.text.exec(t);
    if (r) return { type: "text", raw: r[0], text: r[0], tokens: this.lexer.inline(r[0]) };
  }
  escape(t) {
    let r = this.rules.inline.escape.exec(t);
    if (r) return { type: "escape", raw: r[0], text: r[1] };
  }
  tag(t) {
    let r = this.rules.inline.tag.exec(t);
    if (r) return !this.lexer.state.inLink && this.rules.other.startATag.test(r[0]) ? this.lexer.state.inLink = !0 : this.lexer.state.inLink && this.rules.other.endATag.test(r[0]) && (this.lexer.state.inLink = !1), !this.lexer.state.inRawBlock && this.rules.other.startPreScriptTag.test(r[0]) ? this.lexer.state.inRawBlock = !0 : this.lexer.state.inRawBlock && this.rules.other.endPreScriptTag.test(r[0]) && (this.lexer.state.inRawBlock = !1), { type: "html", raw: r[0], inLink: this.lexer.state.inLink, inRawBlock: this.lexer.state.inRawBlock, block: !1, text: r[0] };
  }
  link(t) {
    let r = this.rules.inline.link.exec(t);
    if (r) {
      let i = r[2].trim();
      if (!this.options.pedantic && this.rules.other.startAngleBracket.test(i)) {
        if (!this.rules.other.endAngleBracket.test(i)) return;
        let a = yi(i.slice(0, -1), "\\");
        if ((i.length - a.length) % 2 === 0) return;
      } else {
        let a = GS(r[2], "()");
        if (a === -2) return;
        if (a > -1) {
          let n = (r[0].indexOf("!") === 0 ? 5 : 4) + r[1].length + a;
          r[2] = r[2].substring(0, a), r[0] = r[0].substring(0, n).trim(), r[3] = "";
        }
      }
      let s = r[2], o = "";
      if (this.options.pedantic) {
        let a = this.rules.other.pedanticHrefTitle.exec(s);
        a && (s = a[1], o = a[3]);
      } else o = r[3] ? r[3].slice(1, -1) : "";
      return s = s.trim(), this.rules.other.startAngleBracket.test(s) && (this.options.pedantic && !this.rules.other.endAngleBracket.test(i) ? s = s.slice(1) : s = s.slice(1, -1)), ac(r, { href: s && s.replace(this.rules.inline.anyPunctuation, "$1"), title: o && o.replace(this.rules.inline.anyPunctuation, "$1") }, r[0], this.lexer, this.rules);
    }
  }
  reflink(t, r) {
    let i;
    if ((i = this.rules.inline.reflink.exec(t)) || (i = this.rules.inline.nolink.exec(t))) {
      let s = (i[2] || i[1]).replace(this.rules.other.multipleSpaceGlobal, " "), o = r[s.toLowerCase()];
      if (!o) {
        let a = i[0].charAt(0);
        return { type: "text", raw: a, text: a };
      }
      return ac(i, o, i[0], this.lexer, this.rules);
    }
  }
  emStrong(t, r, i = "") {
    let s = this.rules.inline.emStrongLDelim.exec(t);
    if (!(!s || s[3] && i.match(this.rules.other.unicodeAlphaNumeric)) && (!(s[1] || s[2]) || !i || this.rules.inline.punctuation.exec(i))) {
      let o = [...s[0]].length - 1, a, n, l = o, c = 0, h = s[0][0] === "*" ? this.rules.inline.emStrongRDelimAst : this.rules.inline.emStrongRDelimUnd;
      for (h.lastIndex = 0, r = r.slice(-1 * t.length + o); (s = h.exec(r)) != null; ) {
        if (a = s[1] || s[2] || s[3] || s[4] || s[5] || s[6], !a) continue;
        if (n = [...a].length, s[3] || s[4]) {
          l += n;
          continue;
        } else if ((s[5] || s[6]) && o % 3 && !((o + n) % 3)) {
          c += n;
          continue;
        }
        if (l -= n, l > 0) continue;
        n = Math.min(n, n + l + c);
        let u = [...s[0]][0].length, p = t.slice(0, o + s.index + u + n);
        if (Math.min(o, n) % 2) {
          let g = p.slice(1, -1);
          return { type: "em", raw: p, text: g, tokens: this.lexer.inlineTokens(g) };
        }
        let d = p.slice(2, -2);
        return { type: "strong", raw: p, text: d, tokens: this.lexer.inlineTokens(d) };
      }
    }
  }
  codespan(t) {
    let r = this.rules.inline.code.exec(t);
    if (r) {
      let i = r[2].replace(this.rules.other.newLineCharGlobal, " "), s = this.rules.other.nonSpaceChar.test(i), o = this.rules.other.startingSpaceChar.test(i) && this.rules.other.endingSpaceChar.test(i);
      return s && o && (i = i.substring(1, i.length - 1)), { type: "codespan", raw: r[0], text: i };
    }
  }
  br(t) {
    let r = this.rules.inline.br.exec(t);
    if (r) return { type: "br", raw: r[0] };
  }
  del(t) {
    let r = this.rules.inline.del.exec(t);
    if (r) return { type: "del", raw: r[0], text: r[2], tokens: this.lexer.inlineTokens(r[2]) };
  }
  autolink(t) {
    let r = this.rules.inline.autolink.exec(t);
    if (r) {
      let i, s;
      return r[2] === "@" ? (i = r[1], s = "mailto:" + i) : (i = r[1], s = i), { type: "link", raw: r[0], text: i, href: s, tokens: [{ type: "text", raw: i, text: i }] };
    }
  }
  url(t) {
    let r;
    if (r = this.rules.inline.url.exec(t)) {
      let i, s;
      if (r[2] === "@") i = r[0], s = "mailto:" + i;
      else {
        let o;
        do
          o = r[0], r[0] = this.rules.inline._backpedal.exec(r[0])?.[0] ?? "";
        while (o !== r[0]);
        i = r[0], r[1] === "www." ? s = "http://" + r[0] : s = r[0];
      }
      return { type: "link", raw: r[0], text: i, href: s, tokens: [{ type: "text", raw: i, text: i }] };
    }
  }
  inlineText(t) {
    let r = this.rules.inline.text.exec(t);
    if (r) {
      let i = this.lexer.state.inRawBlock;
      return { type: "text", raw: r[0], text: r[0], escaped: i };
    }
  }
}, pe = class on {
  tokens;
  options;
  state;
  tokenizer;
  inlineQueue;
  constructor(t) {
    this.tokens = [], this.tokens.links = /* @__PURE__ */ Object.create(null), this.options = t || Ar, this.options.tokenizer = this.options.tokenizer || new ho(), this.tokenizer = this.options.tokenizer, this.tokenizer.options = this.options, this.tokenizer.lexer = this, this.inlineQueue = [], this.state = { inLink: !1, inRawBlock: !1, top: !0 };
    let r = { other: Gt, block: xs.normal, inline: mi.normal };
    this.options.pedantic ? (r.block = xs.pedantic, r.inline = mi.pedantic) : this.options.gfm && (r.block = xs.gfm, this.options.breaks ? r.inline = mi.breaks : r.inline = mi.gfm), this.tokenizer.rules = r;
  }
  static get rules() {
    return { block: xs, inline: mi };
  }
  static lex(t, r) {
    return new on(r).lex(t);
  }
  static lexInline(t, r) {
    return new on(r).inlineTokens(t);
  }
  lex(t) {
    t = t.replace(Gt.carriageReturn, `
`), this.blockTokens(t, this.tokens);
    for (let r = 0; r < this.inlineQueue.length; r++) {
      let i = this.inlineQueue[r];
      this.inlineTokens(i.src, i.tokens);
    }
    return this.inlineQueue = [], this.tokens;
  }
  blockTokens(t, r = [], i = !1) {
    for (this.options.pedantic && (t = t.replace(Gt.tabCharGlobal, "    ").replace(Gt.spaceLine, "")); t; ) {
      let s;
      if (this.options.extensions?.block?.some((a) => (s = a.call({ lexer: this }, t, r)) ? (t = t.substring(s.raw.length), r.push(s), !0) : !1)) continue;
      if (s = this.tokenizer.space(t)) {
        t = t.substring(s.raw.length);
        let a = r.at(-1);
        s.raw.length === 1 && a !== void 0 ? a.raw += `
` : r.push(s);
        continue;
      }
      if (s = this.tokenizer.code(t)) {
        t = t.substring(s.raw.length);
        let a = r.at(-1);
        a?.type === "paragraph" || a?.type === "text" ? (a.raw += (a.raw.endsWith(`
`) ? "" : `
`) + s.raw, a.text += `
` + s.text, this.inlineQueue.at(-1).src = a.text) : r.push(s);
        continue;
      }
      if (s = this.tokenizer.fences(t)) {
        t = t.substring(s.raw.length), r.push(s);
        continue;
      }
      if (s = this.tokenizer.heading(t)) {
        t = t.substring(s.raw.length), r.push(s);
        continue;
      }
      if (s = this.tokenizer.hr(t)) {
        t = t.substring(s.raw.length), r.push(s);
        continue;
      }
      if (s = this.tokenizer.blockquote(t)) {
        t = t.substring(s.raw.length), r.push(s);
        continue;
      }
      if (s = this.tokenizer.list(t)) {
        t = t.substring(s.raw.length), r.push(s);
        continue;
      }
      if (s = this.tokenizer.html(t)) {
        t = t.substring(s.raw.length), r.push(s);
        continue;
      }
      if (s = this.tokenizer.def(t)) {
        t = t.substring(s.raw.length);
        let a = r.at(-1);
        a?.type === "paragraph" || a?.type === "text" ? (a.raw += (a.raw.endsWith(`
`) ? "" : `
`) + s.raw, a.text += `
` + s.raw, this.inlineQueue.at(-1).src = a.text) : this.tokens.links[s.tag] || (this.tokens.links[s.tag] = { href: s.href, title: s.title }, r.push(s));
        continue;
      }
      if (s = this.tokenizer.table(t)) {
        t = t.substring(s.raw.length), r.push(s);
        continue;
      }
      if (s = this.tokenizer.lheading(t)) {
        t = t.substring(s.raw.length), r.push(s);
        continue;
      }
      let o = t;
      if (this.options.extensions?.startBlock) {
        let a = 1 / 0, n = t.slice(1), l;
        this.options.extensions.startBlock.forEach((c) => {
          l = c.call({ lexer: this }, n), typeof l == "number" && l >= 0 && (a = Math.min(a, l));
        }), a < 1 / 0 && a >= 0 && (o = t.substring(0, a + 1));
      }
      if (this.state.top && (s = this.tokenizer.paragraph(o))) {
        let a = r.at(-1);
        i && a?.type === "paragraph" ? (a.raw += (a.raw.endsWith(`
`) ? "" : `
`) + s.raw, a.text += `
` + s.text, this.inlineQueue.pop(), this.inlineQueue.at(-1).src = a.text) : r.push(s), i = o.length !== t.length, t = t.substring(s.raw.length);
        continue;
      }
      if (s = this.tokenizer.text(t)) {
        t = t.substring(s.raw.length);
        let a = r.at(-1);
        a?.type === "text" ? (a.raw += (a.raw.endsWith(`
`) ? "" : `
`) + s.raw, a.text += `
` + s.text, this.inlineQueue.pop(), this.inlineQueue.at(-1).src = a.text) : r.push(s);
        continue;
      }
      if (t) {
        let a = "Infinite loop on byte: " + t.charCodeAt(0);
        if (this.options.silent) {
          console.error(a);
          break;
        } else throw new Error(a);
      }
    }
    return this.state.top = !0, r;
  }
  inline(t, r = []) {
    return this.inlineQueue.push({ src: t, tokens: r }), r;
  }
  inlineTokens(t, r = []) {
    let i = t, s = null;
    if (this.tokens.links) {
      let l = Object.keys(this.tokens.links);
      if (l.length > 0) for (; (s = this.tokenizer.rules.inline.reflinkSearch.exec(i)) != null; ) l.includes(s[0].slice(s[0].lastIndexOf("[") + 1, -1)) && (i = i.slice(0, s.index) + "[" + "a".repeat(s[0].length - 2) + "]" + i.slice(this.tokenizer.rules.inline.reflinkSearch.lastIndex));
    }
    for (; (s = this.tokenizer.rules.inline.anyPunctuation.exec(i)) != null; ) i = i.slice(0, s.index) + "++" + i.slice(this.tokenizer.rules.inline.anyPunctuation.lastIndex);
    let o;
    for (; (s = this.tokenizer.rules.inline.blockSkip.exec(i)) != null; ) o = s[2] ? s[2].length : 0, i = i.slice(0, s.index + o) + "[" + "a".repeat(s[0].length - o - 2) + "]" + i.slice(this.tokenizer.rules.inline.blockSkip.lastIndex);
    i = this.options.hooks?.emStrongMask?.call({ lexer: this }, i) ?? i;
    let a = !1, n = "";
    for (; t; ) {
      a || (n = ""), a = !1;
      let l;
      if (this.options.extensions?.inline?.some((h) => (l = h.call({ lexer: this }, t, r)) ? (t = t.substring(l.raw.length), r.push(l), !0) : !1)) continue;
      if (l = this.tokenizer.escape(t)) {
        t = t.substring(l.raw.length), r.push(l);
        continue;
      }
      if (l = this.tokenizer.tag(t)) {
        t = t.substring(l.raw.length), r.push(l);
        continue;
      }
      if (l = this.tokenizer.link(t)) {
        t = t.substring(l.raw.length), r.push(l);
        continue;
      }
      if (l = this.tokenizer.reflink(t, this.tokens.links)) {
        t = t.substring(l.raw.length);
        let h = r.at(-1);
        l.type === "text" && h?.type === "text" ? (h.raw += l.raw, h.text += l.text) : r.push(l);
        continue;
      }
      if (l = this.tokenizer.emStrong(t, i, n)) {
        t = t.substring(l.raw.length), r.push(l);
        continue;
      }
      if (l = this.tokenizer.codespan(t)) {
        t = t.substring(l.raw.length), r.push(l);
        continue;
      }
      if (l = this.tokenizer.br(t)) {
        t = t.substring(l.raw.length), r.push(l);
        continue;
      }
      if (l = this.tokenizer.del(t)) {
        t = t.substring(l.raw.length), r.push(l);
        continue;
      }
      if (l = this.tokenizer.autolink(t)) {
        t = t.substring(l.raw.length), r.push(l);
        continue;
      }
      if (!this.state.inLink && (l = this.tokenizer.url(t))) {
        t = t.substring(l.raw.length), r.push(l);
        continue;
      }
      let c = t;
      if (this.options.extensions?.startInline) {
        let h = 1 / 0, u = t.slice(1), p;
        this.options.extensions.startInline.forEach((d) => {
          p = d.call({ lexer: this }, u), typeof p == "number" && p >= 0 && (h = Math.min(h, p));
        }), h < 1 / 0 && h >= 0 && (c = t.substring(0, h + 1));
      }
      if (l = this.tokenizer.inlineText(c)) {
        t = t.substring(l.raw.length), l.raw.slice(-1) !== "_" && (n = l.raw.slice(-1)), a = !0;
        let h = r.at(-1);
        h?.type === "text" ? (h.raw += l.raw, h.text += l.text) : r.push(l);
        continue;
      }
      if (t) {
        let h = "Infinite loop on byte: " + t.charCodeAt(0);
        if (this.options.silent) {
          console.error(h);
          break;
        } else throw new Error(h);
      }
    }
    return r;
  }
}, co = class {
  options;
  parser;
  constructor(t) {
    this.options = t || Ar;
  }
  space(t) {
    return "";
  }
  code({ text: t, lang: r, escaped: i }) {
    let s = (r || "").match(Gt.notSpaceStart)?.[0], o = t.replace(Gt.endingNewline, "") + `
`;
    return s ? '<pre><code class="language-' + Se(s) + '">' + (i ? o : Se(o, !0)) + `</code></pre>
` : "<pre><code>" + (i ? o : Se(o, !0)) + `</code></pre>
`;
  }
  blockquote({ tokens: t }) {
    return `<blockquote>
${this.parser.parse(t)}</blockquote>
`;
  }
  html({ text: t }) {
    return t;
  }
  def(t) {
    return "";
  }
  heading({ tokens: t, depth: r }) {
    return `<h${r}>${this.parser.parseInline(t)}</h${r}>
`;
  }
  hr(t) {
    return `<hr>
`;
  }
  list(t) {
    let r = t.ordered, i = t.start, s = "";
    for (let n = 0; n < t.items.length; n++) {
      let l = t.items[n];
      s += this.listitem(l);
    }
    let o = r ? "ol" : "ul", a = r && i !== 1 ? ' start="' + i + '"' : "";
    return "<" + o + a + `>
` + s + "</" + o + `>
`;
  }
  listitem(t) {
    let r = "";
    if (t.task) {
      let i = this.checkbox({ checked: !!t.checked });
      t.loose ? t.tokens[0]?.type === "paragraph" ? (t.tokens[0].text = i + " " + t.tokens[0].text, t.tokens[0].tokens && t.tokens[0].tokens.length > 0 && t.tokens[0].tokens[0].type === "text" && (t.tokens[0].tokens[0].text = i + " " + Se(t.tokens[0].tokens[0].text), t.tokens[0].tokens[0].escaped = !0)) : t.tokens.unshift({ type: "text", raw: i + " ", text: i + " ", escaped: !0 }) : r += i + " ";
    }
    return r += this.parser.parse(t.tokens, !!t.loose), `<li>${r}</li>
`;
  }
  checkbox({ checked: t }) {
    return "<input " + (t ? 'checked="" ' : "") + 'disabled="" type="checkbox">';
  }
  paragraph({ tokens: t }) {
    return `<p>${this.parser.parseInline(t)}</p>
`;
  }
  table(t) {
    let r = "", i = "";
    for (let o = 0; o < t.header.length; o++) i += this.tablecell(t.header[o]);
    r += this.tablerow({ text: i });
    let s = "";
    for (let o = 0; o < t.rows.length; o++) {
      let a = t.rows[o];
      i = "";
      for (let n = 0; n < a.length; n++) i += this.tablecell(a[n]);
      s += this.tablerow({ text: i });
    }
    return s && (s = `<tbody>${s}</tbody>`), `<table>
<thead>
` + r + `</thead>
` + s + `</table>
`;
  }
  tablerow({ text: t }) {
    return `<tr>
${t}</tr>
`;
  }
  tablecell(t) {
    let r = this.parser.parseInline(t.tokens), i = t.header ? "th" : "td";
    return (t.align ? `<${i} align="${t.align}">` : `<${i}>`) + r + `</${i}>
`;
  }
  strong({ tokens: t }) {
    return `<strong>${this.parser.parseInline(t)}</strong>`;
  }
  em({ tokens: t }) {
    return `<em>${this.parser.parseInline(t)}</em>`;
  }
  codespan({ text: t }) {
    return `<code>${Se(t, !0)}</code>`;
  }
  br(t) {
    return "<br>";
  }
  del({ tokens: t }) {
    return `<del>${this.parser.parseInline(t)}</del>`;
  }
  link({ href: t, title: r, tokens: i }) {
    let s = this.parser.parseInline(i), o = sc(t);
    if (o === null) return s;
    t = o;
    let a = '<a href="' + t + '"';
    return r && (a += ' title="' + Se(r) + '"'), a += ">" + s + "</a>", a;
  }
  image({ href: t, title: r, text: i, tokens: s }) {
    s && (i = this.parser.parseInline(s, this.parser.textRenderer));
    let o = sc(t);
    if (o === null) return Se(i);
    t = o;
    let a = `<img src="${t}" alt="${i}"`;
    return r && (a += ` title="${Se(r)}"`), a += ">", a;
  }
  text(t) {
    return "tokens" in t && t.tokens ? this.parser.parseInline(t.tokens) : "escaped" in t && t.escaped ? t.text : Se(t.text);
  }
}, Cl = class {
  strong({ text: t }) {
    return t;
  }
  em({ text: t }) {
    return t;
  }
  codespan({ text: t }) {
    return t;
  }
  del({ text: t }) {
    return t;
  }
  html({ text: t }) {
    return t;
  }
  text({ text: t }) {
    return t;
  }
  link({ text: t }) {
    return "" + t;
  }
  image({ text: t }) {
    return "" + t;
  }
  br() {
    return "";
  }
}, fe = class an {
  options;
  renderer;
  textRenderer;
  constructor(t) {
    this.options = t || Ar, this.options.renderer = this.options.renderer || new co(), this.renderer = this.options.renderer, this.renderer.options = this.options, this.renderer.parser = this, this.textRenderer = new Cl();
  }
  static parse(t, r) {
    return new an(r).parse(t);
  }
  static parseInline(t, r) {
    return new an(r).parseInline(t);
  }
  parse(t, r = !0) {
    let i = "";
    for (let s = 0; s < t.length; s++) {
      let o = t[s];
      if (this.options.extensions?.renderers?.[o.type]) {
        let n = o, l = this.options.extensions.renderers[n.type].call({ parser: this }, n);
        if (l !== !1 || !["space", "hr", "heading", "code", "table", "blockquote", "list", "html", "def", "paragraph", "text"].includes(n.type)) {
          i += l || "";
          continue;
        }
      }
      let a = o;
      switch (a.type) {
        case "space": {
          i += this.renderer.space(a);
          continue;
        }
        case "hr": {
          i += this.renderer.hr(a);
          continue;
        }
        case "heading": {
          i += this.renderer.heading(a);
          continue;
        }
        case "code": {
          i += this.renderer.code(a);
          continue;
        }
        case "table": {
          i += this.renderer.table(a);
          continue;
        }
        case "blockquote": {
          i += this.renderer.blockquote(a);
          continue;
        }
        case "list": {
          i += this.renderer.list(a);
          continue;
        }
        case "html": {
          i += this.renderer.html(a);
          continue;
        }
        case "def": {
          i += this.renderer.def(a);
          continue;
        }
        case "paragraph": {
          i += this.renderer.paragraph(a);
          continue;
        }
        case "text": {
          let n = a, l = this.renderer.text(n);
          for (; s + 1 < t.length && t[s + 1].type === "text"; ) n = t[++s], l += `
` + this.renderer.text(n);
          r ? i += this.renderer.paragraph({ type: "paragraph", raw: l, text: l, tokens: [{ type: "text", raw: l, text: l, escaped: !0 }] }) : i += l;
          continue;
        }
        default: {
          let n = 'Token with "' + a.type + '" type was not found.';
          if (this.options.silent) return console.error(n), "";
          throw new Error(n);
        }
      }
    }
    return i;
  }
  parseInline(t, r = this.renderer) {
    let i = "";
    for (let s = 0; s < t.length; s++) {
      let o = t[s];
      if (this.options.extensions?.renderers?.[o.type]) {
        let n = this.options.extensions.renderers[o.type].call({ parser: this }, o);
        if (n !== !1 || !["escape", "html", "link", "image", "strong", "em", "codespan", "br", "del", "text"].includes(o.type)) {
          i += n || "";
          continue;
        }
      }
      let a = o;
      switch (a.type) {
        case "escape": {
          i += r.text(a);
          break;
        }
        case "html": {
          i += r.html(a);
          break;
        }
        case "link": {
          i += r.link(a);
          break;
        }
        case "image": {
          i += r.image(a);
          break;
        }
        case "strong": {
          i += r.strong(a);
          break;
        }
        case "em": {
          i += r.em(a);
          break;
        }
        case "codespan": {
          i += r.codespan(a);
          break;
        }
        case "br": {
          i += r.br(a);
          break;
        }
        case "del": {
          i += r.del(a);
          break;
        }
        case "text": {
          i += r.text(a);
          break;
        }
        default: {
          let n = 'Token with "' + a.type + '" type was not found.';
          if (this.options.silent) return console.error(n), "";
          throw new Error(n);
        }
      }
    }
    return i;
  }
}, Bi = class {
  options;
  block;
  constructor(t) {
    this.options = t || Ar;
  }
  static passThroughHooks = /* @__PURE__ */ new Set(["preprocess", "postprocess", "processAllTokens", "emStrongMask"]);
  static passThroughHooksRespectAsync = /* @__PURE__ */ new Set(["preprocess", "postprocess", "processAllTokens"]);
  preprocess(t) {
    return t;
  }
  postprocess(t) {
    return t;
  }
  processAllTokens(t) {
    return t;
  }
  emStrongMask(t) {
    return t;
  }
  provideLexer() {
    return this.block ? pe.lex : pe.lexInline;
  }
  provideParser() {
    return this.block ? fe.parse : fe.parseInline;
  }
}, VS = class {
  defaults = cl();
  options = this.setOptions;
  parse = this.parseMarkdown(!0);
  parseInline = this.parseMarkdown(!1);
  Parser = fe;
  Renderer = co;
  TextRenderer = Cl;
  Lexer = pe;
  Tokenizer = ho;
  Hooks = Bi;
  constructor(...t) {
    this.use(...t);
  }
  walkTokens(t, r) {
    let i = [];
    for (let s of t) switch (i = i.concat(r.call(this, s)), s.type) {
      case "table": {
        let o = s;
        for (let a of o.header) i = i.concat(this.walkTokens(a.tokens, r));
        for (let a of o.rows) for (let n of a) i = i.concat(this.walkTokens(n.tokens, r));
        break;
      }
      case "list": {
        let o = s;
        i = i.concat(this.walkTokens(o.items, r));
        break;
      }
      default: {
        let o = s;
        this.defaults.extensions?.childTokens?.[o.type] ? this.defaults.extensions.childTokens[o.type].forEach((a) => {
          let n = o[a].flat(1 / 0);
          i = i.concat(this.walkTokens(n, r));
        }) : o.tokens && (i = i.concat(this.walkTokens(o.tokens, r)));
      }
    }
    return i;
  }
  use(...t) {
    let r = this.defaults.extensions || { renderers: {}, childTokens: {} };
    return t.forEach((i) => {
      let s = { ...i };
      if (s.async = this.defaults.async || s.async || !1, i.extensions && (i.extensions.forEach((o) => {
        if (!o.name) throw new Error("extension name required");
        if ("renderer" in o) {
          let a = r.renderers[o.name];
          a ? r.renderers[o.name] = function(...n) {
            let l = o.renderer.apply(this, n);
            return l === !1 && (l = a.apply(this, n)), l;
          } : r.renderers[o.name] = o.renderer;
        }
        if ("tokenizer" in o) {
          if (!o.level || o.level !== "block" && o.level !== "inline") throw new Error("extension level must be 'block' or 'inline'");
          let a = r[o.level];
          a ? a.unshift(o.tokenizer) : r[o.level] = [o.tokenizer], o.start && (o.level === "block" ? r.startBlock ? r.startBlock.push(o.start) : r.startBlock = [o.start] : o.level === "inline" && (r.startInline ? r.startInline.push(o.start) : r.startInline = [o.start]));
        }
        "childTokens" in o && o.childTokens && (r.childTokens[o.name] = o.childTokens);
      }), s.extensions = r), i.renderer) {
        let o = this.defaults.renderer || new co(this.defaults);
        for (let a in i.renderer) {
          if (!(a in o)) throw new Error(`renderer '${a}' does not exist`);
          if (["options", "parser"].includes(a)) continue;
          let n = a, l = i.renderer[n], c = o[n];
          o[n] = (...h) => {
            let u = l.apply(o, h);
            return u === !1 && (u = c.apply(o, h)), u || "";
          };
        }
        s.renderer = o;
      }
      if (i.tokenizer) {
        let o = this.defaults.tokenizer || new ho(this.defaults);
        for (let a in i.tokenizer) {
          if (!(a in o)) throw new Error(`tokenizer '${a}' does not exist`);
          if (["options", "rules", "lexer"].includes(a)) continue;
          let n = a, l = i.tokenizer[n], c = o[n];
          o[n] = (...h) => {
            let u = l.apply(o, h);
            return u === !1 && (u = c.apply(o, h)), u;
          };
        }
        s.tokenizer = o;
      }
      if (i.hooks) {
        let o = this.defaults.hooks || new Bi();
        for (let a in i.hooks) {
          if (!(a in o)) throw new Error(`hook '${a}' does not exist`);
          if (["options", "block"].includes(a)) continue;
          let n = a, l = i.hooks[n], c = o[n];
          Bi.passThroughHooks.has(a) ? o[n] = (h) => {
            if (this.defaults.async && Bi.passThroughHooksRespectAsync.has(a)) return (async () => {
              let p = await l.call(o, h);
              return c.call(o, p);
            })();
            let u = l.call(o, h);
            return c.call(o, u);
          } : o[n] = (...h) => {
            if (this.defaults.async) return (async () => {
              let p = await l.apply(o, h);
              return p === !1 && (p = await c.apply(o, h)), p;
            })();
            let u = l.apply(o, h);
            return u === !1 && (u = c.apply(o, h)), u;
          };
        }
        s.hooks = o;
      }
      if (i.walkTokens) {
        let o = this.defaults.walkTokens, a = i.walkTokens;
        s.walkTokens = function(n) {
          let l = [];
          return l.push(a.call(this, n)), o && (l = l.concat(o.call(this, n))), l;
        };
      }
      this.defaults = { ...this.defaults, ...s };
    }), this;
  }
  setOptions(t) {
    return this.defaults = { ...this.defaults, ...t }, this;
  }
  lexer(t, r) {
    return pe.lex(t, r ?? this.defaults);
  }
  parser(t, r) {
    return fe.parse(t, r ?? this.defaults);
  }
  parseMarkdown(t) {
    return (r, i) => {
      let s = { ...i }, o = { ...this.defaults, ...s }, a = this.onError(!!o.silent, !!o.async);
      if (this.defaults.async === !0 && s.async === !1) return a(new Error("marked(): The async option was set to true by an extension. Remove async: false from the parse options object to return a Promise."));
      if (typeof r > "u" || r === null) return a(new Error("marked(): input parameter is undefined or null"));
      if (typeof r != "string") return a(new Error("marked(): input parameter is of type " + Object.prototype.toString.call(r) + ", string expected"));
      if (o.hooks && (o.hooks.options = o, o.hooks.block = t), o.async) return (async () => {
        let n = o.hooks ? await o.hooks.preprocess(r) : r, l = await (o.hooks ? await o.hooks.provideLexer() : t ? pe.lex : pe.lexInline)(n, o), c = o.hooks ? await o.hooks.processAllTokens(l) : l;
        o.walkTokens && await Promise.all(this.walkTokens(c, o.walkTokens));
        let h = await (o.hooks ? await o.hooks.provideParser() : t ? fe.parse : fe.parseInline)(c, o);
        return o.hooks ? await o.hooks.postprocess(h) : h;
      })().catch(a);
      try {
        o.hooks && (r = o.hooks.preprocess(r));
        let n = (o.hooks ? o.hooks.provideLexer() : t ? pe.lex : pe.lexInline)(r, o);
        o.hooks && (n = o.hooks.processAllTokens(n)), o.walkTokens && this.walkTokens(n, o.walkTokens);
        let l = (o.hooks ? o.hooks.provideParser() : t ? fe.parse : fe.parseInline)(n, o);
        return o.hooks && (l = o.hooks.postprocess(l)), l;
      } catch (n) {
        return a(n);
      }
    };
  }
  onError(t, r) {
    return (i) => {
      if (i.message += `
Please report this to https://github.com/markedjs/marked.`, t) {
        let s = "<p>An error occurred:</p><pre>" + Se(i.message + "", !0) + "</pre>";
        return r ? Promise.resolve(s) : s;
      }
      if (r) return Promise.reject(i);
      throw i;
    };
  }
}, _r = new VS();
function yt(e, t) {
  return _r.parse(e, t);
}
yt.options = yt.setOptions = function(e) {
  return _r.setOptions(e), yt.defaults = _r.defaults, gf(yt.defaults), yt;
};
yt.getDefaults = cl;
yt.defaults = Ar;
yt.use = function(...e) {
  return _r.use(...e), yt.defaults = _r.defaults, gf(yt.defaults), yt;
};
yt.walkTokens = function(e, t) {
  return _r.walkTokens(e, t);
};
yt.parseInline = _r.parseInline;
yt.Parser = fe;
yt.parser = fe.parse;
yt.Renderer = co;
yt.TextRenderer = Cl;
yt.Lexer = pe;
yt.lexer = pe.lex;
yt.Tokenizer = ho;
yt.Hooks = Bi;
yt.parse = yt;
yt.options;
yt.setOptions;
yt.use;
yt.walkTokens;
yt.parseInline;
fe.parse;
pe.lex;
function vf(e) {
  for (var t = [], r = 1; r < arguments.length; r++)
    t[r - 1] = arguments[r];
  var i = Array.from(typeof e == "string" ? [e] : e);
  i[i.length - 1] = i[i.length - 1].replace(/\r?\n([\t ]*)$/, "");
  var s = i.reduce(function(n, l) {
    var c = l.match(/\n([\t ]+|(?!\s).)/g);
    return c ? n.concat(c.map(function(h) {
      var u, p;
      return (p = (u = h.match(/[\t ]/g)) === null || u === void 0 ? void 0 : u.length) !== null && p !== void 0 ? p : 0;
    })) : n;
  }, []);
  if (s.length) {
    var o = new RegExp(`
[	 ]{` + Math.min.apply(Math, s) + "}", "g");
    i = i.map(function(n) {
      return n.replace(o, `
`);
    });
  }
  i[0] = i[0].replace(/^\r?\n/, "");
  var a = i[0];
  return t.forEach(function(n, l) {
    var c = a.match(/(?:^|\n)( *)$/), h = c ? c[1] : "", u = n;
    typeof n == "string" && n.includes(`
`) && (u = String(n).split(`
`).map(function(p, d) {
      return d === 0 ? p : "" + h + p;
    }).join(`
`)), a += u + i[l + 1];
  }), a;
}
var ZS = {
  body: '<g><rect width="80" height="80" style="fill: #087ebf; stroke-width: 0px;"/><text transform="translate(21.16 64.67)" style="fill: #fff; font-family: ArialMT, Arial; font-size: 67.75px;"><tspan x="0" y="0">?</tspan></text></g>',
  height: 80,
  width: 80
}, nn = /* @__PURE__ */ new Map(), Bf = /* @__PURE__ */ new Map(), KS = /* @__PURE__ */ f((e) => {
  for (const t of e) {
    if (!t.name)
      throw new Error(
        'Invalid icon loader. Must have a "name" property with non-empty string value.'
      );
    if (R.debug("Registering icon pack:", t.name), "loader" in t)
      Bf.set(t.name, t.loader);
    else if ("icons" in t)
      nn.set(t.name, t.icons);
    else
      throw R.error("Invalid icon loader:", t), new Error('Invalid icon loader. Must have either "icons" or "loader" property.');
  }
}, "registerIconPacks"), Lf = /* @__PURE__ */ f(async (e, t) => {
  const r = Qw(e, !0, t !== void 0);
  if (!r)
    throw new Error(`Invalid icon name: ${e}`);
  const i = r.prefix || t;
  if (!i)
    throw new Error(`Icon name must contain a prefix: ${e}`);
  let s = nn.get(i);
  if (!s) {
    const a = Bf.get(i);
    if (!a)
      throw new Error(`Icon set not found: ${r.prefix}`);
    try {
      s = { ...await a(), prefix: i }, nn.set(i, s);
    } catch (n) {
      throw R.error(n), new Error(`Failed to load icon set: ${r.prefix}`);
    }
  }
  const o = eS(s, r.name);
  if (!o)
    throw new Error(`Icon not found: ${e}`);
  return o;
}, "getRegisteredIconData"), QS = /* @__PURE__ */ f(async (e) => {
  try {
    return await Lf(e), !0;
  } catch {
    return !1;
  }
}, "isIconAvailable"), os = /* @__PURE__ */ f(async (e, t, r) => {
  let i;
  try {
    i = await Lf(e, t?.fallbackPrefix);
  } catch (a) {
    R.error(a), i = ZS;
  }
  const s = lS(i, t), o = dS(uS(s.body), {
    ...s.attributes,
    ...r
  });
  return xe(o, wt());
}, "getIconSVG");
function Ff(e, { markdownAutoWrap: t }) {
  const i = e.replace(/<br\/>/g, `
`).replace(/\n{2,}/g, `
`);
  return vf(i);
}
f(Ff, "preprocessMarkdown");
function Af(e) {
  return e.split(/\\n|\n|<br\s*\/?>/gi).map(
    (t) => t.trim().match(/<[^>]+>|[^\s<>]+/g)?.map((r) => ({ content: r, type: "normal" })) ?? []
  );
}
f(Af, "nonMarkdownToLines");
function Mf(e, t = {}) {
  const r = Ff(e, t), i = yt.lexer(r), s = [[]];
  let o = 0;
  function a(n, l = "normal") {
    n.type === "text" ? n.text.split(`
`).forEach((h, u) => {
      u !== 0 && (o++, s.push([])), h.split(" ").forEach((p) => {
        p = p.replace(/&#39;/g, "'"), p && s[o].push({ content: p, type: l });
      });
    }) : n.type === "strong" || n.type === "em" ? n.tokens.forEach((c) => {
      a(c, n.type);
    }) : n.type === "html" && s[o].push({ content: n.text, type: "normal" });
  }
  return f(a, "processNode"), i.forEach((n) => {
    n.type === "paragraph" ? n.tokens?.forEach((l) => {
      a(l);
    }) : n.type === "html" ? s[o].push({ content: n.text, type: "normal" }) : s[o].push({ content: n.raw, type: "normal" });
  }), s;
}
f(Mf, "markdownToLines");
function Ef(e) {
  return e ? `<p>${/**
  * Replace new lines with <br /> tags.
  *
  * Unlike in markdown text, `\n` sequences are treated as line breaks here.
  */
  e.replace(/\\n|\n/g, "<br />")}</p>` : "";
}
f(Ef, "nonMarkdownToHTML");
function $f(e, { markdownAutoWrap: t } = {}) {
  const r = yt.lexer(e);
  function i(s) {
    return s.type === "text" ? t === !1 ? s.text.replace(/\n */g, "<br/>").replace(/ /g, "&nbsp;") : s.text.replace(/\n */g, "<br/>") : s.type === "strong" ? `<strong>${s.tokens?.map(i).join("")}</strong>` : s.type === "em" ? `<em>${s.tokens?.map(i).join("")}</em>` : s.type === "paragraph" ? `<p>${s.tokens?.map(i).join("")}</p>` : s.type === "space" ? "" : s.type === "html" ? `${s.text}` : s.type === "escape" ? s.text : (R.warn(`Unsupported markdown: ${s.type}`), s.raw);
  }
  return f(i, "output"), r.map(i).join("");
}
f($f, "markdownToHTML");
function Of(e) {
  return Intl.Segmenter ? [...new Intl.Segmenter().segment(e)].map((t) => t.segment) : [...e];
}
f(Of, "splitTextToChars");
function If(e, t) {
  const r = Of(t.content);
  return xl(e, [], r, t.type);
}
f(If, "splitWordToFitWidth");
function xl(e, t, r, i) {
  if (r.length === 0)
    return [
      { content: t.join(""), type: i },
      { content: "", type: i }
    ];
  const [s, ...o] = r, a = [...t, s];
  return e([{ content: a.join(""), type: i }]) ? xl(e, a, o, i) : (t.length === 0 && s && (t.push(s), r.shift()), [
    { content: t.join(""), type: i },
    { content: r.join(""), type: i }
  ]);
}
f(xl, "splitWordToFitWidthRecursion");
function Df(e, t) {
  if (e.some(({ content: r }) => r.includes(`
`)))
    throw new Error("splitLineToFitWidth does not support newlines in the line");
  return uo(e, t);
}
f(Df, "splitLineToFitWidth");
function uo(e, t, r = [], i = []) {
  if (e.length === 0)
    return i.length > 0 && r.push(i), r.length > 0 ? r : [];
  let s = "";
  e[0].content === " " && (s = " ", e.shift());
  const o = e.shift() ?? { content: " ", type: "normal" }, a = [...i];
  if (s !== "" && a.push({ content: s, type: "normal" }), a.push(o), t(a))
    return uo(e, t, r, a);
  if (i.length > 0)
    r.push(i), e.unshift(o);
  else if (o.content) {
    const [n, l] = If(t, o);
    r.push([n]), l.content && e.unshift(l);
  }
  return uo(e, t, r);
}
f(uo, "splitLineToFitWidthRecursion");
function ln(e, t) {
  t && e.attr("style", t);
}
f(ln, "applyStyle");
var nc = 16384;
async function Pf(e, t, r, i, s = !1, o = wt()) {
  const a = e.append("foreignObject");
  a.attr("width", `${Math.min(10 * r, nc)}px`), a.attr("height", `${Math.min(10 * r, nc)}px`);
  const n = a.append("xhtml:div"), l = Pi(t.label) ? await hu(t.label.replace(Qi.lineBreakRegex, `
`), o) : xe(t.label, o), c = t.isNode ? "nodeLabel" : "edgeLabel", h = n.append("span");
  h.html(l), ln(h, t.labelStyle), h.attr("class", `${c} ${i}`), ln(n, t.labelStyle), n.style("display", "table-cell"), n.style("white-space", "nowrap"), n.style("line-height", "1.5"), r !== Number.POSITIVE_INFINITY && (n.style("max-width", r + "px"), n.style("text-align", "center")), n.attr("xmlns", "http://www.w3.org/1999/xhtml"), s && n.attr("class", "labelBkg");
  let u = n.node().getBoundingClientRect();
  return u.width === r && (n.style("display", "table"), n.style("white-space", "break-spaces"), n.style("width", r + "px"), u = n.node().getBoundingClientRect()), a.node();
}
f(Pf, "addHtmlSpan");
function Do(e, t, r, i = !1) {
  const s = e.append("tspan").attr("class", "text-outer-tspan").attr("x", 0).attr("y", t * r - 0.1 + "em").attr("dy", r + "em");
  return i && s.attr("text-anchor", "middle"), s;
}
f(Do, "createTspan");
function Rf(e, t, r) {
  const i = e.append("text"), s = Do(i, 1, t);
  Po(s, r);
  const o = s.node().getComputedTextLength();
  return i.remove(), o;
}
f(Rf, "computeWidthOfText");
function JS(e, t, r) {
  const i = e.append("text"), s = Do(i, 1, t);
  Po(s, [{ content: r, type: "normal" }]);
  const o = s.node()?.getBoundingClientRect();
  return o && i.remove(), o;
}
f(JS, "computeDimensionOfText");
function Nf(e, t, r, i = !1, s = !1) {
  const a = t.append("g"), n = a.insert("rect").attr("class", "background").attr("style", "stroke: none"), l = a.append("text").attr("y", "-10.1");
  s && l.attr("text-anchor", "middle");
  let c = 0;
  for (const h of r) {
    const u = /* @__PURE__ */ f((d) => Rf(a, 1.1, d) <= e, "checkWidth"), p = u(h) ? [h] : Df(h, u);
    for (const d of p) {
      const g = Do(l, c, 1.1, s);
      Po(g, d), c++;
    }
  }
  if (i) {
    const h = l.node().getBBox(), u = 2;
    return n.attr("x", h.x - u).attr("y", h.y - u).attr("width", h.width + 2 * u).attr("height", h.height + 2 * u), a.node();
  } else
    return l.node();
}
f(Nf, "createFormattedText");
function hn(e) {
  const t = /&(amp|lt|gt);/g;
  return e.replace(t, (r, i) => {
    switch (i) {
      case "amp":
        return "&";
      case "lt":
        return "<";
      case "gt":
        return ">";
      default:
        return r;
    }
  });
}
f(hn, "decodeHTMLEntities");
function Po(e, t) {
  e.text(""), t.forEach((r, i) => {
    const s = e.append("tspan").attr("font-style", r.type === "em" ? "italic" : "normal").attr("class", "text-inner-tspan").attr("font-weight", r.type === "strong" ? "bold" : "normal");
    i === 0 ? s.text(hn(r.content)) : s.text(" " + hn(r.content));
  });
}
f(Po, "updateTextContentAndStyles");
async function qf(e, t = {}) {
  const r = [];
  e.replace(/(fa[bklrs]?):fa-([\w-]+)/g, (s, o, a) => (r.push(
    (async () => {
      const n = `${o}:${a}`;
      return await QS(n) ? await os(n, void 0, { class: "label-icon" }) : `<i class='${xe(s, t).replace(":", " ")}'></i>`;
    })()
  ), s));
  const i = await Promise.all(r);
  return e.replace(/(fa[bklrs]?):fa-([\w-]+)/g, () => i.shift() ?? "");
}
f(qf, "replaceIconSubstring");
var Ge = /* @__PURE__ */ f(async (e, t = "", {
  style: r = "",
  isTitle: i = !1,
  classes: s = "",
  useHtmlLabels: o = !0,
  markdown: a = !0,
  isNode: n = !0,
  /**
   * The width to wrap the text within. Set to `Number.POSITIVE_INFINITY` for no wrapping.
   */
  width: l = 200,
  addSvgBackground: c = !1
} = {}, h) => {
  if (R.debug(
    "XYZ createText",
    t,
    r,
    i,
    s,
    o,
    n,
    "addSvgBackground: ",
    c
  ), o) {
    const u = a ? $f(t, h) : Ef(t), p = await qf(Sr(u), h), d = t.replace(/\\\\/g, "\\"), g = {
      isNode: n,
      label: Pi(t) ? d : p,
      labelStyle: r.replace("fill:", "color:")
    };
    return await Pf(e, g, l, s, c, h);
  } else {
    const u = Sr(t.replace(/<br\s*\/?>/g, "<br/>")), p = a ? Mf(u.replace("<br>", "<br/>"), h) : Af(u), d = Nf(
      l,
      e,
      p,
      t ? c : !1,
      !n
    );
    if (n) {
      /stroke:/.exec(r) && (r = r.replace("stroke:", "lineColor:"));
      const g = r.replace(/stroke:[^;]+;?/g, "").replace(/stroke-width:[^;]+;?/g, "").replace(/fill:[^;]+;?/g, "").replace(/color:/g, "fill:");
      ct(d).attr("style", g);
    } else {
      const g = r.replace(/stroke:[^;]+;?/g, "").replace(/stroke-width:[^;]+;?/g, "").replace(/fill:[^;]+;?/g, "").replace(/background:/g, "fill:");
      ct(d).select("rect").attr("style", g.replace(/background:/g, "fill:"));
      const m = r.replace(/stroke:[^;]+;?/g, "").replace(/stroke-width:[^;]+;?/g, "").replace(/fill:[^;]+;?/g, "").replace(/color:/g, "fill:");
      ct(d).select("text").attr("style", m);
    }
    return i ? ct(d).selectAll("tspan.text-outer-tspan").classed("title-row", !0) : ct(d).selectAll("tspan.text-outer-tspan").classed("row", !0), d;
  }
}, "createText");
function fa(e, t, r) {
  if (e && e.length) {
    const [i, s] = t, o = Math.PI / 180 * r, a = Math.cos(o), n = Math.sin(o);
    for (const l of e) {
      const [c, h] = l;
      l[0] = (c - i) * a - (h - s) * n + i, l[1] = (c - i) * n + (h - s) * a + s;
    }
  }
}
function t_(e, t) {
  return e[0] === t[0] && e[1] === t[1];
}
function e_(e, t, r, i = 1) {
  const s = r, o = Math.max(t, 0.1), a = e[0] && e[0][0] && typeof e[0][0] == "number" ? [e] : e, n = [0, 0];
  if (s) for (const c of a) fa(c, n, s);
  const l = (function(c, h, u) {
    const p = [];
    for (const b of c) {
      const k = [...b];
      t_(k[0], k[k.length - 1]) || k.push([k[0][0], k[0][1]]), k.length > 2 && p.push(k);
    }
    const d = [];
    h = Math.max(h, 0.1);
    const g = [];
    for (const b of p) for (let k = 0; k < b.length - 1; k++) {
      const w = b[k], S = b[k + 1];
      if (w[1] !== S[1]) {
        const v = Math.min(w[1], S[1]);
        g.push({ ymin: v, ymax: Math.max(w[1], S[1]), x: v === w[1] ? w[0] : S[0], islope: (S[0] - w[0]) / (S[1] - w[1]) });
      }
    }
    if (g.sort(((b, k) => b.ymin < k.ymin ? -1 : b.ymin > k.ymin ? 1 : b.x < k.x ? -1 : b.x > k.x ? 1 : b.ymax === k.ymax ? 0 : (b.ymax - k.ymax) / Math.abs(b.ymax - k.ymax))), !g.length) return d;
    let m = [], y = g[0].ymin, x = 0;
    for (; m.length || g.length; ) {
      if (g.length) {
        let b = -1;
        for (let k = 0; k < g.length && !(g[k].ymin > y); k++) b = k;
        g.splice(0, b + 1).forEach(((k) => {
          m.push({ s: y, edge: k });
        }));
      }
      if (m = m.filter(((b) => !(b.edge.ymax <= y))), m.sort(((b, k) => b.edge.x === k.edge.x ? 0 : (b.edge.x - k.edge.x) / Math.abs(b.edge.x - k.edge.x))), (u !== 1 || x % h == 0) && m.length > 1) for (let b = 0; b < m.length; b += 2) {
        const k = b + 1;
        if (k >= m.length) break;
        const w = m[b].edge, S = m[k].edge;
        d.push([[Math.round(w.x), y], [Math.round(S.x), y]]);
      }
      y += u, m.forEach(((b) => {
        b.edge.x = b.edge.x + u * b.edge.islope;
      })), x++;
    }
    return d;
  })(a, o, i);
  if (s) {
    for (const c of a) fa(c, n, -s);
    (function(c, h, u) {
      const p = [];
      c.forEach(((d) => p.push(...d))), fa(p, h, u);
    })(l, n, -s);
  }
  return l;
}
function as(e, t) {
  var r;
  const i = t.hachureAngle + 90;
  let s = t.hachureGap;
  s < 0 && (s = 4 * t.strokeWidth), s = Math.round(Math.max(s, 0.1));
  let o = 1;
  return t.roughness >= 1 && (((r = t.randomizer) === null || r === void 0 ? void 0 : r.next()) || Math.random()) > 0.7 && (o = s), e_(e, s, i, o || 1);
}
class bl {
  constructor(t) {
    this.helper = t;
  }
  fillPolygons(t, r) {
    return this._fillPolygons(t, r);
  }
  _fillPolygons(t, r) {
    const i = as(t, r);
    return { type: "fillSketch", ops: this.renderLines(i, r) };
  }
  renderLines(t, r) {
    const i = [];
    for (const s of t) i.push(...this.helper.doubleLineOps(s[0][0], s[0][1], s[1][0], s[1][1], r));
    return i;
  }
}
function Ro(e) {
  const t = e[0], r = e[1];
  return Math.sqrt(Math.pow(t[0] - r[0], 2) + Math.pow(t[1] - r[1], 2));
}
class r_ extends bl {
  fillPolygons(t, r) {
    let i = r.hachureGap;
    i < 0 && (i = 4 * r.strokeWidth), i = Math.max(i, 0.1);
    const s = as(t, Object.assign({}, r, { hachureGap: i })), o = Math.PI / 180 * r.hachureAngle, a = [], n = 0.5 * i * Math.cos(o), l = 0.5 * i * Math.sin(o);
    for (const [c, h] of s) Ro([c, h]) && a.push([[c[0] - n, c[1] + l], [...h]], [[c[0] + n, c[1] - l], [...h]]);
    return { type: "fillSketch", ops: this.renderLines(a, r) };
  }
}
class i_ extends bl {
  fillPolygons(t, r) {
    const i = this._fillPolygons(t, r), s = Object.assign({}, r, { hachureAngle: r.hachureAngle + 90 }), o = this._fillPolygons(t, s);
    return i.ops = i.ops.concat(o.ops), i;
  }
}
class s_ {
  constructor(t) {
    this.helper = t;
  }
  fillPolygons(t, r) {
    const i = as(t, r = Object.assign({}, r, { hachureAngle: 0 }));
    return this.dotsOnLines(i, r);
  }
  dotsOnLines(t, r) {
    const i = [];
    let s = r.hachureGap;
    s < 0 && (s = 4 * r.strokeWidth), s = Math.max(s, 0.1);
    let o = r.fillWeight;
    o < 0 && (o = r.strokeWidth / 2);
    const a = s / 4;
    for (const n of t) {
      const l = Ro(n), c = l / s, h = Math.ceil(c) - 1, u = l - h * s, p = (n[0][0] + n[1][0]) / 2 - s / 4, d = Math.min(n[0][1], n[1][1]);
      for (let g = 0; g < h; g++) {
        const m = d + u + g * s, y = p - a + 2 * Math.random() * a, x = m - a + 2 * Math.random() * a, b = this.helper.ellipse(y, x, o, o, r);
        i.push(...b.ops);
      }
    }
    return { type: "fillSketch", ops: i };
  }
}
class o_ {
  constructor(t) {
    this.helper = t;
  }
  fillPolygons(t, r) {
    const i = as(t, r);
    return { type: "fillSketch", ops: this.dashedLine(i, r) };
  }
  dashedLine(t, r) {
    const i = r.dashOffset < 0 ? r.hachureGap < 0 ? 4 * r.strokeWidth : r.hachureGap : r.dashOffset, s = r.dashGap < 0 ? r.hachureGap < 0 ? 4 * r.strokeWidth : r.hachureGap : r.dashGap, o = [];
    return t.forEach(((a) => {
      const n = Ro(a), l = Math.floor(n / (i + s)), c = (n + s - l * (i + s)) / 2;
      let h = a[0], u = a[1];
      h[0] > u[0] && (h = a[1], u = a[0]);
      const p = Math.atan((u[1] - h[1]) / (u[0] - h[0]));
      for (let d = 0; d < l; d++) {
        const g = d * (i + s), m = g + i, y = [h[0] + g * Math.cos(p) + c * Math.cos(p), h[1] + g * Math.sin(p) + c * Math.sin(p)], x = [h[0] + m * Math.cos(p) + c * Math.cos(p), h[1] + m * Math.sin(p) + c * Math.sin(p)];
        o.push(...this.helper.doubleLineOps(y[0], y[1], x[0], x[1], r));
      }
    })), o;
  }
}
class a_ {
  constructor(t) {
    this.helper = t;
  }
  fillPolygons(t, r) {
    const i = r.hachureGap < 0 ? 4 * r.strokeWidth : r.hachureGap, s = r.zigzagOffset < 0 ? i : r.zigzagOffset, o = as(t, r = Object.assign({}, r, { hachureGap: i + s }));
    return { type: "fillSketch", ops: this.zigzagLines(o, s, r) };
  }
  zigzagLines(t, r, i) {
    const s = [];
    return t.forEach(((o) => {
      const a = Ro(o), n = Math.round(a / (2 * r));
      let l = o[0], c = o[1];
      l[0] > c[0] && (l = o[1], c = o[0]);
      const h = Math.atan((c[1] - l[1]) / (c[0] - l[0]));
      for (let u = 0; u < n; u++) {
        const p = 2 * u * r, d = 2 * (u + 1) * r, g = Math.sqrt(2 * Math.pow(r, 2)), m = [l[0] + p * Math.cos(h), l[1] + p * Math.sin(h)], y = [l[0] + d * Math.cos(h), l[1] + d * Math.sin(h)], x = [m[0] + g * Math.cos(h + Math.PI / 4), m[1] + g * Math.sin(h + Math.PI / 4)];
        s.push(...this.helper.doubleLineOps(m[0], m[1], x[0], x[1], i), ...this.helper.doubleLineOps(x[0], x[1], y[0], y[1], i));
      }
    })), s;
  }
}
const Kt = {};
class n_ {
  constructor(t) {
    this.seed = t;
  }
  next() {
    return this.seed ? (2 ** 31 - 1 & (this.seed = Math.imul(48271, this.seed))) / 2 ** 31 : Math.random();
  }
}
const l_ = 0, ga = 1, lc = 2, bs = { A: 7, a: 7, C: 6, c: 6, H: 1, h: 1, L: 2, l: 2, M: 2, m: 2, Q: 4, q: 4, S: 4, s: 4, T: 2, t: 2, V: 1, v: 1, Z: 0, z: 0 };
function ma(e, t) {
  return e.type === t;
}
function kl(e) {
  const t = [], r = (function(a) {
    const n = new Array();
    for (; a !== ""; ) if (a.match(/^([ \t\r\n,]+)/)) a = a.substr(RegExp.$1.length);
    else if (a.match(/^([aAcChHlLmMqQsStTvVzZ])/)) n[n.length] = { type: l_, text: RegExp.$1 }, a = a.substr(RegExp.$1.length);
    else {
      if (!a.match(/^(([-+]?[0-9]+(\.[0-9]*)?|[-+]?\.[0-9]+)([eE][-+]?[0-9]+)?)/)) return [];
      n[n.length] = { type: ga, text: `${parseFloat(RegExp.$1)}` }, a = a.substr(RegExp.$1.length);
    }
    return n[n.length] = { type: lc, text: "" }, n;
  })(e);
  let i = "BOD", s = 0, o = r[s];
  for (; !ma(o, lc); ) {
    let a = 0;
    const n = [];
    if (i === "BOD") {
      if (o.text !== "M" && o.text !== "m") return kl("M0,0" + e);
      s++, a = bs[o.text], i = o.text;
    } else ma(o, ga) ? a = bs[i] : (s++, a = bs[o.text], i = o.text);
    if (!(s + a < r.length)) throw new Error("Path data ended short");
    for (let l = s; l < s + a; l++) {
      const c = r[l];
      if (!ma(c, ga)) throw new Error("Param not a number: " + i + "," + c.text);
      n[n.length] = +c.text;
    }
    if (typeof bs[i] != "number") throw new Error("Bad segment: " + i);
    {
      const l = { key: i, data: n };
      t.push(l), s += a, o = r[s], i === "M" && (i = "L"), i === "m" && (i = "l");
    }
  }
  return t;
}
function zf(e) {
  let t = 0, r = 0, i = 0, s = 0;
  const o = [];
  for (const { key: a, data: n } of e) switch (a) {
    case "M":
      o.push({ key: "M", data: [...n] }), [t, r] = n, [i, s] = n;
      break;
    case "m":
      t += n[0], r += n[1], o.push({ key: "M", data: [t, r] }), i = t, s = r;
      break;
    case "L":
      o.push({ key: "L", data: [...n] }), [t, r] = n;
      break;
    case "l":
      t += n[0], r += n[1], o.push({ key: "L", data: [t, r] });
      break;
    case "C":
      o.push({ key: "C", data: [...n] }), t = n[4], r = n[5];
      break;
    case "c": {
      const l = n.map(((c, h) => h % 2 ? c + r : c + t));
      o.push({ key: "C", data: l }), t = l[4], r = l[5];
      break;
    }
    case "Q":
      o.push({ key: "Q", data: [...n] }), t = n[2], r = n[3];
      break;
    case "q": {
      const l = n.map(((c, h) => h % 2 ? c + r : c + t));
      o.push({ key: "Q", data: l }), t = l[2], r = l[3];
      break;
    }
    case "A":
      o.push({ key: "A", data: [...n] }), t = n[5], r = n[6];
      break;
    case "a":
      t += n[5], r += n[6], o.push({ key: "A", data: [n[0], n[1], n[2], n[3], n[4], t, r] });
      break;
    case "H":
      o.push({ key: "H", data: [...n] }), t = n[0];
      break;
    case "h":
      t += n[0], o.push({ key: "H", data: [t] });
      break;
    case "V":
      o.push({ key: "V", data: [...n] }), r = n[0];
      break;
    case "v":
      r += n[0], o.push({ key: "V", data: [r] });
      break;
    case "S":
      o.push({ key: "S", data: [...n] }), t = n[2], r = n[3];
      break;
    case "s": {
      const l = n.map(((c, h) => h % 2 ? c + r : c + t));
      o.push({ key: "S", data: l }), t = l[2], r = l[3];
      break;
    }
    case "T":
      o.push({ key: "T", data: [...n] }), t = n[0], r = n[1];
      break;
    case "t":
      t += n[0], r += n[1], o.push({ key: "T", data: [t, r] });
      break;
    case "Z":
    case "z":
      o.push({ key: "Z", data: [] }), t = i, r = s;
  }
  return o;
}
function Wf(e) {
  const t = [];
  let r = "", i = 0, s = 0, o = 0, a = 0, n = 0, l = 0;
  for (const { key: c, data: h } of e) {
    switch (c) {
      case "M":
        t.push({ key: "M", data: [...h] }), [i, s] = h, [o, a] = h;
        break;
      case "C":
        t.push({ key: "C", data: [...h] }), i = h[4], s = h[5], n = h[2], l = h[3];
        break;
      case "L":
        t.push({ key: "L", data: [...h] }), [i, s] = h;
        break;
      case "H":
        i = h[0], t.push({ key: "L", data: [i, s] });
        break;
      case "V":
        s = h[0], t.push({ key: "L", data: [i, s] });
        break;
      case "S": {
        let u = 0, p = 0;
        r === "C" || r === "S" ? (u = i + (i - n), p = s + (s - l)) : (u = i, p = s), t.push({ key: "C", data: [u, p, ...h] }), n = h[0], l = h[1], i = h[2], s = h[3];
        break;
      }
      case "T": {
        const [u, p] = h;
        let d = 0, g = 0;
        r === "Q" || r === "T" ? (d = i + (i - n), g = s + (s - l)) : (d = i, g = s);
        const m = i + 2 * (d - i) / 3, y = s + 2 * (g - s) / 3, x = u + 2 * (d - u) / 3, b = p + 2 * (g - p) / 3;
        t.push({ key: "C", data: [m, y, x, b, u, p] }), n = d, l = g, i = u, s = p;
        break;
      }
      case "Q": {
        const [u, p, d, g] = h, m = i + 2 * (u - i) / 3, y = s + 2 * (p - s) / 3, x = d + 2 * (u - d) / 3, b = g + 2 * (p - g) / 3;
        t.push({ key: "C", data: [m, y, x, b, d, g] }), n = u, l = p, i = d, s = g;
        break;
      }
      case "A": {
        const u = Math.abs(h[0]), p = Math.abs(h[1]), d = h[2], g = h[3], m = h[4], y = h[5], x = h[6];
        u === 0 || p === 0 ? (t.push({ key: "C", data: [i, s, y, x, y, x] }), i = y, s = x) : (i !== y || s !== x) && (Hf(i, s, y, x, u, p, d, g, m).forEach((function(b) {
          t.push({ key: "C", data: b });
        })), i = y, s = x);
        break;
      }
      case "Z":
        t.push({ key: "Z", data: [] }), i = o, s = a;
    }
    r = c;
  }
  return t;
}
function Ci(e, t, r) {
  return [e * Math.cos(r) - t * Math.sin(r), e * Math.sin(r) + t * Math.cos(r)];
}
function Hf(e, t, r, i, s, o, a, n, l, c) {
  const h = (u = a, Math.PI * u / 180);
  var u;
  let p = [], d = 0, g = 0, m = 0, y = 0;
  if (c) [d, g, m, y] = c;
  else {
    [e, t] = Ci(e, t, -h), [r, i] = Ci(r, i, -h);
    const z = (e - r) / 2, I = (t - i) / 2;
    let F = z * z / (s * s) + I * I / (o * o);
    F > 1 && (F = Math.sqrt(F), s *= F, o *= F);
    const L = s * s, E = o * o, P = L * E - L * I * I - E * z * z, H = L * I * I + E * z * z, Y = (n === l ? -1 : 1) * Math.sqrt(Math.abs(P / H));
    m = Y * s * I / o + (e + r) / 2, y = Y * -o * z / s + (t + i) / 2, d = Math.asin(parseFloat(((t - y) / o).toFixed(9))), g = Math.asin(parseFloat(((i - y) / o).toFixed(9))), e < m && (d = Math.PI - d), r < m && (g = Math.PI - g), d < 0 && (d = 2 * Math.PI + d), g < 0 && (g = 2 * Math.PI + g), l && d > g && (d -= 2 * Math.PI), !l && g > d && (g -= 2 * Math.PI);
  }
  let x = g - d;
  if (Math.abs(x) > 120 * Math.PI / 180) {
    const z = g, I = r, F = i;
    g = l && g > d ? d + 120 * Math.PI / 180 * 1 : d + 120 * Math.PI / 180 * -1, p = Hf(r = m + s * Math.cos(g), i = y + o * Math.sin(g), I, F, s, o, a, 0, l, [g, z, m, y]);
  }
  x = g - d;
  const b = Math.cos(d), k = Math.sin(d), w = Math.cos(g), S = Math.sin(g), v = Math.tan(x / 4), M = 4 / 3 * s * v, B = 4 / 3 * o * v, N = [e, t], D = [e + M * k, t - B * b], O = [r + M * S, i - B * w], W = [r, i];
  if (D[0] = 2 * N[0] - D[0], D[1] = 2 * N[1] - D[1], c) return [D, O, W].concat(p);
  {
    p = [D, O, W].concat(p);
    const z = [];
    for (let I = 0; I < p.length; I += 3) {
      const F = Ci(p[I][0], p[I][1], h), L = Ci(p[I + 1][0], p[I + 1][1], h), E = Ci(p[I + 2][0], p[I + 2][1], h);
      z.push([F[0], F[1], L[0], L[1], E[0], E[1]]);
    }
    return z;
  }
}
const h_ = { randOffset: function(e, t) {
  return ot(e, t);
}, randOffsetWithRange: function(e, t, r) {
  return po(e, t, r);
}, ellipse: function(e, t, r, i, s) {
  const o = jf(r, i, s);
  return cn(e, t, s, o).opset;
}, doubleLineOps: function(e, t, r, i, s) {
  return ir(e, t, r, i, s, !0);
} };
function Yf(e, t, r, i, s) {
  return { type: "path", ops: ir(e, t, r, i, s) };
}
function $s(e, t, r) {
  const i = (e || []).length;
  if (i > 2) {
    const s = [];
    for (let o = 0; o < i - 1; o++) s.push(...ir(e[o][0], e[o][1], e[o + 1][0], e[o + 1][1], r));
    return t && s.push(...ir(e[i - 1][0], e[i - 1][1], e[0][0], e[0][1], r)), { type: "path", ops: s };
  }
  return i === 2 ? Yf(e[0][0], e[0][1], e[1][0], e[1][1], r) : { type: "path", ops: [] };
}
function c_(e, t, r, i, s) {
  return (function(o, a) {
    return $s(o, !0, a);
  })([[e, t], [e + r, t], [e + r, t + i], [e, t + i]], s);
}
function hc(e, t) {
  if (e.length) {
    const r = typeof e[0][0] == "number" ? [e] : e, i = ks(r[0], 1 * (1 + 0.2 * t.roughness), t), s = t.disableMultiStroke ? [] : ks(r[0], 1.5 * (1 + 0.22 * t.roughness), dc(t));
    for (let o = 1; o < r.length; o++) {
      const a = r[o];
      if (a.length) {
        const n = ks(a, 1 * (1 + 0.2 * t.roughness), t), l = t.disableMultiStroke ? [] : ks(a, 1.5 * (1 + 0.22 * t.roughness), dc(t));
        for (const c of n) c.op !== "move" && i.push(c);
        for (const c of l) c.op !== "move" && s.push(c);
      }
    }
    return { type: "path", ops: i.concat(s) };
  }
  return { type: "path", ops: [] };
}
function jf(e, t, r) {
  const i = Math.sqrt(2 * Math.PI * Math.sqrt((Math.pow(e / 2, 2) + Math.pow(t / 2, 2)) / 2)), s = Math.ceil(Math.max(r.curveStepCount, r.curveStepCount / Math.sqrt(200) * i)), o = 2 * Math.PI / s;
  let a = Math.abs(e / 2), n = Math.abs(t / 2);
  const l = 1 - r.curveFitting;
  return a += ot(a * l, r), n += ot(n * l, r), { increment: o, rx: a, ry: n };
}
function cn(e, t, r, i) {
  const [s, o] = pc(i.increment, e, t, i.rx, i.ry, 1, i.increment * po(0.1, po(0.4, 1, r), r), r);
  let a = fo(s, null, r);
  if (!r.disableMultiStroke && r.roughness !== 0) {
    const [n] = pc(i.increment, e, t, i.rx, i.ry, 1.5, 0, r), l = fo(n, null, r);
    a = a.concat(l);
  }
  return { estimatedPoints: o, opset: { type: "path", ops: a } };
}
function cc(e, t, r, i, s, o, a, n, l) {
  const c = e, h = t;
  let u = Math.abs(r / 2), p = Math.abs(i / 2);
  u += ot(0.01 * u, l), p += ot(0.01 * p, l);
  let d = s, g = o;
  for (; d < 0; ) d += 2 * Math.PI, g += 2 * Math.PI;
  g - d > 2 * Math.PI && (d = 0, g = 2 * Math.PI);
  const m = 2 * Math.PI / l.curveStepCount, y = Math.min(m / 2, (g - d) / 2), x = fc(y, c, h, u, p, d, g, 1, l);
  if (!l.disableMultiStroke) {
    const b = fc(y, c, h, u, p, d, g, 1.5, l);
    x.push(...b);
  }
  return a && (n ? x.push(...ir(c, h, c + u * Math.cos(d), h + p * Math.sin(d), l), ...ir(c, h, c + u * Math.cos(g), h + p * Math.sin(g), l)) : x.push({ op: "lineTo", data: [c, h] }, { op: "lineTo", data: [c + u * Math.cos(d), h + p * Math.sin(d)] })), { type: "path", ops: x };
}
function uc(e, t) {
  const r = Wf(zf(kl(e))), i = [];
  let s = [0, 0], o = [0, 0];
  for (const { key: a, data: n } of r) switch (a) {
    case "M":
      o = [n[0], n[1]], s = [n[0], n[1]];
      break;
    case "L":
      i.push(...ir(o[0], o[1], n[0], n[1], t)), o = [n[0], n[1]];
      break;
    case "C": {
      const [l, c, h, u, p, d] = n;
      i.push(...u_(l, c, h, u, p, d, o, t)), o = [p, d];
      break;
    }
    case "Z":
      i.push(...ir(o[0], o[1], s[0], s[1], t)), o = [s[0], s[1]];
  }
  return { type: "path", ops: i };
}
function ya(e, t) {
  const r = [];
  for (const i of e) if (i.length) {
    const s = t.maxRandomnessOffset || 0, o = i.length;
    if (o > 2) {
      r.push({ op: "move", data: [i[0][0] + ot(s, t), i[0][1] + ot(s, t)] });
      for (let a = 1; a < o; a++) r.push({ op: "lineTo", data: [i[a][0] + ot(s, t), i[a][1] + ot(s, t)] });
    }
  }
  return { type: "fillPath", ops: r };
}
function Pr(e, t) {
  return (function(r, i) {
    let s = r.fillStyle || "hachure";
    if (!Kt[s]) switch (s) {
      case "zigzag":
        Kt[s] || (Kt[s] = new r_(i));
        break;
      case "cross-hatch":
        Kt[s] || (Kt[s] = new i_(i));
        break;
      case "dots":
        Kt[s] || (Kt[s] = new s_(i));
        break;
      case "dashed":
        Kt[s] || (Kt[s] = new o_(i));
        break;
      case "zigzag-line":
        Kt[s] || (Kt[s] = new a_(i));
        break;
      default:
        s = "hachure", Kt[s] || (Kt[s] = new bl(i));
    }
    return Kt[s];
  })(t, h_).fillPolygons(e, t);
}
function dc(e) {
  const t = Object.assign({}, e);
  return t.randomizer = void 0, e.seed && (t.seed = e.seed + 1), t;
}
function Uf(e) {
  return e.randomizer || (e.randomizer = new n_(e.seed || 0)), e.randomizer.next();
}
function po(e, t, r, i = 1) {
  return r.roughness * i * (Uf(r) * (t - e) + e);
}
function ot(e, t, r = 1) {
  return po(-e, e, t, r);
}
function ir(e, t, r, i, s, o = !1) {
  const a = o ? s.disableMultiStrokeFill : s.disableMultiStroke, n = un(e, t, r, i, s, !0, !1);
  if (a) return n;
  const l = un(e, t, r, i, s, !0, !0);
  return n.concat(l);
}
function un(e, t, r, i, s, o, a) {
  const n = Math.pow(e - r, 2) + Math.pow(t - i, 2), l = Math.sqrt(n);
  let c = 1;
  c = l < 200 ? 1 : l > 500 ? 0.4 : -16668e-7 * l + 1.233334;
  let h = s.maxRandomnessOffset || 0;
  h * h * 100 > n && (h = l / 10);
  const u = h / 2, p = 0.2 + 0.2 * Uf(s);
  let d = s.bowing * s.maxRandomnessOffset * (i - t) / 200, g = s.bowing * s.maxRandomnessOffset * (e - r) / 200;
  d = ot(d, s, c), g = ot(g, s, c);
  const m = [], y = () => ot(u, s, c), x = () => ot(h, s, c), b = s.preserveVertices;
  return a ? m.push({ op: "move", data: [e + (b ? 0 : y()), t + (b ? 0 : y())] }) : m.push({ op: "move", data: [e + (b ? 0 : ot(h, s, c)), t + (b ? 0 : ot(h, s, c))] }), a ? m.push({ op: "bcurveTo", data: [d + e + (r - e) * p + y(), g + t + (i - t) * p + y(), d + e + 2 * (r - e) * p + y(), g + t + 2 * (i - t) * p + y(), r + (b ? 0 : y()), i + (b ? 0 : y())] }) : m.push({ op: "bcurveTo", data: [d + e + (r - e) * p + x(), g + t + (i - t) * p + x(), d + e + 2 * (r - e) * p + x(), g + t + 2 * (i - t) * p + x(), r + (b ? 0 : x()), i + (b ? 0 : x())] }), m;
}
function ks(e, t, r) {
  if (!e.length) return [];
  const i = [];
  i.push([e[0][0] + ot(t, r), e[0][1] + ot(t, r)]), i.push([e[0][0] + ot(t, r), e[0][1] + ot(t, r)]);
  for (let s = 1; s < e.length; s++) i.push([e[s][0] + ot(t, r), e[s][1] + ot(t, r)]), s === e.length - 1 && i.push([e[s][0] + ot(t, r), e[s][1] + ot(t, r)]);
  return fo(i, null, r);
}
function fo(e, t, r) {
  const i = e.length, s = [];
  if (i > 3) {
    const o = [], a = 1 - r.curveTightness;
    s.push({ op: "move", data: [e[1][0], e[1][1]] });
    for (let n = 1; n + 2 < i; n++) {
      const l = e[n];
      o[0] = [l[0], l[1]], o[1] = [l[0] + (a * e[n + 1][0] - a * e[n - 1][0]) / 6, l[1] + (a * e[n + 1][1] - a * e[n - 1][1]) / 6], o[2] = [e[n + 1][0] + (a * e[n][0] - a * e[n + 2][0]) / 6, e[n + 1][1] + (a * e[n][1] - a * e[n + 2][1]) / 6], o[3] = [e[n + 1][0], e[n + 1][1]], s.push({ op: "bcurveTo", data: [o[1][0], o[1][1], o[2][0], o[2][1], o[3][0], o[3][1]] });
    }
  } else i === 3 ? (s.push({ op: "move", data: [e[1][0], e[1][1]] }), s.push({ op: "bcurveTo", data: [e[1][0], e[1][1], e[2][0], e[2][1], e[2][0], e[2][1]] })) : i === 2 && s.push(...un(e[0][0], e[0][1], e[1][0], e[1][1], r, !0, !0));
  return s;
}
function pc(e, t, r, i, s, o, a, n) {
  const l = [], c = [];
  if (n.roughness === 0) {
    e /= 4, c.push([t + i * Math.cos(-e), r + s * Math.sin(-e)]);
    for (let h = 0; h <= 2 * Math.PI; h += e) {
      const u = [t + i * Math.cos(h), r + s * Math.sin(h)];
      l.push(u), c.push(u);
    }
    c.push([t + i * Math.cos(0), r + s * Math.sin(0)]), c.push([t + i * Math.cos(e), r + s * Math.sin(e)]);
  } else {
    const h = ot(0.5, n) - Math.PI / 2;
    c.push([ot(o, n) + t + 0.9 * i * Math.cos(h - e), ot(o, n) + r + 0.9 * s * Math.sin(h - e)]);
    const u = 2 * Math.PI + h - 0.01;
    for (let p = h; p < u; p += e) {
      const d = [ot(o, n) + t + i * Math.cos(p), ot(o, n) + r + s * Math.sin(p)];
      l.push(d), c.push(d);
    }
    c.push([ot(o, n) + t + i * Math.cos(h + 2 * Math.PI + 0.5 * a), ot(o, n) + r + s * Math.sin(h + 2 * Math.PI + 0.5 * a)]), c.push([ot(o, n) + t + 0.98 * i * Math.cos(h + a), ot(o, n) + r + 0.98 * s * Math.sin(h + a)]), c.push([ot(o, n) + t + 0.9 * i * Math.cos(h + 0.5 * a), ot(o, n) + r + 0.9 * s * Math.sin(h + 0.5 * a)]);
  }
  return [c, l];
}
function fc(e, t, r, i, s, o, a, n, l) {
  const c = o + ot(0.1, l), h = [];
  h.push([ot(n, l) + t + 0.9 * i * Math.cos(c - e), ot(n, l) + r + 0.9 * s * Math.sin(c - e)]);
  for (let u = c; u <= a; u += e) h.push([ot(n, l) + t + i * Math.cos(u), ot(n, l) + r + s * Math.sin(u)]);
  return h.push([t + i * Math.cos(a), r + s * Math.sin(a)]), h.push([t + i * Math.cos(a), r + s * Math.sin(a)]), fo(h, null, l);
}
function u_(e, t, r, i, s, o, a, n) {
  const l = [], c = [n.maxRandomnessOffset || 1, (n.maxRandomnessOffset || 1) + 0.3];
  let h = [0, 0];
  const u = n.disableMultiStroke ? 1 : 2, p = n.preserveVertices;
  for (let d = 0; d < u; d++) d === 0 ? l.push({ op: "move", data: [a[0], a[1]] }) : l.push({ op: "move", data: [a[0] + (p ? 0 : ot(c[0], n)), a[1] + (p ? 0 : ot(c[0], n))] }), h = p ? [s, o] : [s + ot(c[d], n), o + ot(c[d], n)], l.push({ op: "bcurveTo", data: [e + ot(c[d], n), t + ot(c[d], n), r + ot(c[d], n), i + ot(c[d], n), h[0], h[1]] });
  return l;
}
function xi(e) {
  return [...e];
}
function gc(e, t = 0) {
  const r = e.length;
  if (r < 3) throw new Error("A curve must have at least three points.");
  const i = [];
  if (r === 3) i.push(xi(e[0]), xi(e[1]), xi(e[2]), xi(e[2]));
  else {
    const s = [];
    s.push(e[0], e[0]);
    for (let n = 1; n < e.length; n++) s.push(e[n]), n === e.length - 1 && s.push(e[n]);
    const o = [], a = 1 - t;
    i.push(xi(s[0]));
    for (let n = 1; n + 2 < s.length; n++) {
      const l = s[n];
      o[0] = [l[0], l[1]], o[1] = [l[0] + (a * s[n + 1][0] - a * s[n - 1][0]) / 6, l[1] + (a * s[n + 1][1] - a * s[n - 1][1]) / 6], o[2] = [s[n + 1][0] + (a * s[n][0] - a * s[n + 2][0]) / 6, s[n + 1][1] + (a * s[n][1] - a * s[n + 2][1]) / 6], o[3] = [s[n + 1][0], s[n + 1][1]], i.push(o[1], o[2], o[3]);
    }
  }
  return i;
}
function Os(e, t) {
  return Math.pow(e[0] - t[0], 2) + Math.pow(e[1] - t[1], 2);
}
function d_(e, t, r) {
  const i = Os(t, r);
  if (i === 0) return Os(e, t);
  let s = ((e[0] - t[0]) * (r[0] - t[0]) + (e[1] - t[1]) * (r[1] - t[1])) / i;
  return s = Math.max(0, Math.min(1, s)), Os(e, dr(t, r, s));
}
function dr(e, t, r) {
  return [e[0] + (t[0] - e[0]) * r, e[1] + (t[1] - e[1]) * r];
}
function dn(e, t, r, i) {
  const s = i || [];
  if ((function(n, l) {
    const c = n[l + 0], h = n[l + 1], u = n[l + 2], p = n[l + 3];
    let d = 3 * h[0] - 2 * c[0] - p[0];
    d *= d;
    let g = 3 * h[1] - 2 * c[1] - p[1];
    g *= g;
    let m = 3 * u[0] - 2 * p[0] - c[0];
    m *= m;
    let y = 3 * u[1] - 2 * p[1] - c[1];
    return y *= y, d < m && (d = m), g < y && (g = y), d + g;
  })(e, t) < r) {
    const n = e[t + 0];
    s.length ? (o = s[s.length - 1], a = n, Math.sqrt(Os(o, a)) > 1 && s.push(n)) : s.push(n), s.push(e[t + 3]);
  } else {
    const l = e[t + 0], c = e[t + 1], h = e[t + 2], u = e[t + 3], p = dr(l, c, 0.5), d = dr(c, h, 0.5), g = dr(h, u, 0.5), m = dr(p, d, 0.5), y = dr(d, g, 0.5), x = dr(m, y, 0.5);
    dn([l, p, m, x], 0, r, s), dn([x, y, g, u], 0, r, s);
  }
  var o, a;
  return s;
}
function p_(e, t) {
  return go(e, 0, e.length, t);
}
function go(e, t, r, i, s) {
  const o = s || [], a = e[t], n = e[r - 1];
  let l = 0, c = 1;
  for (let h = t + 1; h < r - 1; ++h) {
    const u = d_(e[h], a, n);
    u > l && (l = u, c = h);
  }
  return Math.sqrt(l) > i ? (go(e, t, c + 1, i, o), go(e, c, r, i, o)) : (o.length || o.push(a), o.push(n)), o;
}
function Ca(e, t = 0.15, r) {
  const i = [], s = (e.length - 1) / 3;
  for (let o = 0; o < s; o++)
    dn(e, 3 * o, t, i);
  return r && r > 0 ? go(i, 0, i.length, r) : i;
}
const se = "none";
class mo {
  constructor(t) {
    this.defaultOptions = { maxRandomnessOffset: 2, roughness: 1, bowing: 1, stroke: "#000", strokeWidth: 1, curveTightness: 0, curveFitting: 0.95, curveStepCount: 9, fillStyle: "hachure", fillWeight: -1, hachureAngle: -41, hachureGap: -1, dashOffset: -1, dashGap: -1, zigzagOffset: -1, seed: 0, disableMultiStroke: !1, disableMultiStrokeFill: !1, preserveVertices: !1, fillShapeRoughnessGain: 0.8 }, this.config = t || {}, this.config.options && (this.defaultOptions = this._o(this.config.options));
  }
  static newSeed() {
    return Math.floor(Math.random() * 2 ** 31);
  }
  _o(t) {
    return t ? Object.assign({}, this.defaultOptions, t) : this.defaultOptions;
  }
  _d(t, r, i) {
    return { shape: t, sets: r || [], options: i || this.defaultOptions };
  }
  line(t, r, i, s, o) {
    const a = this._o(o);
    return this._d("line", [Yf(t, r, i, s, a)], a);
  }
  rectangle(t, r, i, s, o) {
    const a = this._o(o), n = [], l = c_(t, r, i, s, a);
    if (a.fill) {
      const c = [[t, r], [t + i, r], [t + i, r + s], [t, r + s]];
      a.fillStyle === "solid" ? n.push(ya([c], a)) : n.push(Pr([c], a));
    }
    return a.stroke !== se && n.push(l), this._d("rectangle", n, a);
  }
  ellipse(t, r, i, s, o) {
    const a = this._o(o), n = [], l = jf(i, s, a), c = cn(t, r, a, l);
    if (a.fill) if (a.fillStyle === "solid") {
      const h = cn(t, r, a, l).opset;
      h.type = "fillPath", n.push(h);
    } else n.push(Pr([c.estimatedPoints], a));
    return a.stroke !== se && n.push(c.opset), this._d("ellipse", n, a);
  }
  circle(t, r, i, s) {
    const o = this.ellipse(t, r, i, i, s);
    return o.shape = "circle", o;
  }
  linearPath(t, r) {
    const i = this._o(r);
    return this._d("linearPath", [$s(t, !1, i)], i);
  }
  arc(t, r, i, s, o, a, n = !1, l) {
    const c = this._o(l), h = [], u = cc(t, r, i, s, o, a, n, !0, c);
    if (n && c.fill) if (c.fillStyle === "solid") {
      const p = Object.assign({}, c);
      p.disableMultiStroke = !0;
      const d = cc(t, r, i, s, o, a, !0, !1, p);
      d.type = "fillPath", h.push(d);
    } else h.push((function(p, d, g, m, y, x, b) {
      const k = p, w = d;
      let S = Math.abs(g / 2), v = Math.abs(m / 2);
      S += ot(0.01 * S, b), v += ot(0.01 * v, b);
      let M = y, B = x;
      for (; M < 0; ) M += 2 * Math.PI, B += 2 * Math.PI;
      B - M > 2 * Math.PI && (M = 0, B = 2 * Math.PI);
      const N = (B - M) / b.curveStepCount, D = [];
      for (let O = M; O <= B; O += N) D.push([k + S * Math.cos(O), w + v * Math.sin(O)]);
      return D.push([k + S * Math.cos(B), w + v * Math.sin(B)]), D.push([k, w]), Pr([D], b);
    })(t, r, i, s, o, a, c));
    return c.stroke !== se && h.push(u), this._d("arc", h, c);
  }
  curve(t, r) {
    const i = this._o(r), s = [], o = hc(t, i);
    if (i.fill && i.fill !== se) if (i.fillStyle === "solid") {
      const a = hc(t, Object.assign(Object.assign({}, i), { disableMultiStroke: !0, roughness: i.roughness ? i.roughness + i.fillShapeRoughnessGain : 0 }));
      s.push({ type: "fillPath", ops: this._mergedShape(a.ops) });
    } else {
      const a = [], n = t;
      if (n.length) {
        const l = typeof n[0][0] == "number" ? [n] : n;
        for (const c of l) c.length < 3 ? a.push(...c) : c.length === 3 ? a.push(...Ca(gc([c[0], c[0], c[1], c[2]]), 10, (1 + i.roughness) / 2)) : a.push(...Ca(gc(c), 10, (1 + i.roughness) / 2));
      }
      a.length && s.push(Pr([a], i));
    }
    return i.stroke !== se && s.push(o), this._d("curve", s, i);
  }
  polygon(t, r) {
    const i = this._o(r), s = [], o = $s(t, !0, i);
    return i.fill && (i.fillStyle === "solid" ? s.push(ya([t], i)) : s.push(Pr([t], i))), i.stroke !== se && s.push(o), this._d("polygon", s, i);
  }
  path(t, r) {
    const i = this._o(r), s = [];
    if (!t) return this._d("path", s, i);
    t = (t || "").replace(/\n/g, " ").replace(/(-\s)/g, "-").replace("/(ss)/g", " ");
    const o = i.fill && i.fill !== "transparent" && i.fill !== se, a = i.stroke !== se, n = !!(i.simplification && i.simplification < 1), l = (function(h, u, p) {
      const d = Wf(zf(kl(h))), g = [];
      let m = [], y = [0, 0], x = [];
      const b = () => {
        x.length >= 4 && m.push(...Ca(x, u)), x = [];
      }, k = () => {
        b(), m.length && (g.push(m), m = []);
      };
      for (const { key: S, data: v } of d) switch (S) {
        case "M":
          k(), y = [v[0], v[1]], m.push(y);
          break;
        case "L":
          b(), m.push([v[0], v[1]]);
          break;
        case "C":
          if (!x.length) {
            const M = m.length ? m[m.length - 1] : y;
            x.push([M[0], M[1]]);
          }
          x.push([v[0], v[1]]), x.push([v[2], v[3]]), x.push([v[4], v[5]]);
          break;
        case "Z":
          b(), m.push([y[0], y[1]]);
      }
      if (k(), !p) return g;
      const w = [];
      for (const S of g) {
        const v = p_(S, p);
        v.length && w.push(v);
      }
      return w;
    })(t, 1, n ? 4 - 4 * (i.simplification || 1) : (1 + i.roughness) / 2), c = uc(t, i);
    if (o) if (i.fillStyle === "solid") if (l.length === 1) {
      const h = uc(t, Object.assign(Object.assign({}, i), { disableMultiStroke: !0, roughness: i.roughness ? i.roughness + i.fillShapeRoughnessGain : 0 }));
      s.push({ type: "fillPath", ops: this._mergedShape(h.ops) });
    } else s.push(ya(l, i));
    else s.push(Pr(l, i));
    return a && (n ? l.forEach(((h) => {
      s.push($s(h, !1, i));
    })) : s.push(c)), this._d("path", s, i);
  }
  opsToPath(t, r) {
    let i = "";
    for (const s of t.ops) {
      const o = typeof r == "number" && r >= 0 ? s.data.map(((a) => +a.toFixed(r))) : s.data;
      switch (s.op) {
        case "move":
          i += `M${o[0]} ${o[1]} `;
          break;
        case "bcurveTo":
          i += `C${o[0]} ${o[1]}, ${o[2]} ${o[3]}, ${o[4]} ${o[5]} `;
          break;
        case "lineTo":
          i += `L${o[0]} ${o[1]} `;
      }
    }
    return i.trim();
  }
  toPaths(t) {
    const r = t.sets || [], i = t.options || this.defaultOptions, s = [];
    for (const o of r) {
      let a = null;
      switch (o.type) {
        case "path":
          a = { d: this.opsToPath(o), stroke: i.stroke, strokeWidth: i.strokeWidth, fill: se };
          break;
        case "fillPath":
          a = { d: this.opsToPath(o), stroke: se, strokeWidth: 0, fill: i.fill || se };
          break;
        case "fillSketch":
          a = this.fillSketch(o, i);
      }
      a && s.push(a);
    }
    return s;
  }
  fillSketch(t, r) {
    let i = r.fillWeight;
    return i < 0 && (i = r.strokeWidth / 2), { d: this.opsToPath(t), stroke: r.fill || se, strokeWidth: i, fill: se };
  }
  _mergedShape(t) {
    return t.filter(((r, i) => i === 0 || r.op !== "move"));
  }
}
class f_ {
  constructor(t, r) {
    this.canvas = t, this.ctx = this.canvas.getContext("2d"), this.gen = new mo(r);
  }
  draw(t) {
    const r = t.sets || [], i = t.options || this.getDefaultOptions(), s = this.ctx, o = t.options.fixedDecimalPlaceDigits;
    for (const a of r) switch (a.type) {
      case "path":
        s.save(), s.strokeStyle = i.stroke === "none" ? "transparent" : i.stroke, s.lineWidth = i.strokeWidth, i.strokeLineDash && s.setLineDash(i.strokeLineDash), i.strokeLineDashOffset && (s.lineDashOffset = i.strokeLineDashOffset), this._drawToContext(s, a, o), s.restore();
        break;
      case "fillPath": {
        s.save(), s.fillStyle = i.fill || "";
        const n = t.shape === "curve" || t.shape === "polygon" || t.shape === "path" ? "evenodd" : "nonzero";
        this._drawToContext(s, a, o, n), s.restore();
        break;
      }
      case "fillSketch":
        this.fillSketch(s, a, i);
    }
  }
  fillSketch(t, r, i) {
    let s = i.fillWeight;
    s < 0 && (s = i.strokeWidth / 2), t.save(), i.fillLineDash && t.setLineDash(i.fillLineDash), i.fillLineDashOffset && (t.lineDashOffset = i.fillLineDashOffset), t.strokeStyle = i.fill || "", t.lineWidth = s, this._drawToContext(t, r, i.fixedDecimalPlaceDigits), t.restore();
  }
  _drawToContext(t, r, i, s = "nonzero") {
    t.beginPath();
    for (const o of r.ops) {
      const a = typeof i == "number" && i >= 0 ? o.data.map(((n) => +n.toFixed(i))) : o.data;
      switch (o.op) {
        case "move":
          t.moveTo(a[0], a[1]);
          break;
        case "bcurveTo":
          t.bezierCurveTo(a[0], a[1], a[2], a[3], a[4], a[5]);
          break;
        case "lineTo":
          t.lineTo(a[0], a[1]);
      }
    }
    r.type === "fillPath" ? t.fill(s) : t.stroke();
  }
  get generator() {
    return this.gen;
  }
  getDefaultOptions() {
    return this.gen.defaultOptions;
  }
  line(t, r, i, s, o) {
    const a = this.gen.line(t, r, i, s, o);
    return this.draw(a), a;
  }
  rectangle(t, r, i, s, o) {
    const a = this.gen.rectangle(t, r, i, s, o);
    return this.draw(a), a;
  }
  ellipse(t, r, i, s, o) {
    const a = this.gen.ellipse(t, r, i, s, o);
    return this.draw(a), a;
  }
  circle(t, r, i, s) {
    const o = this.gen.circle(t, r, i, s);
    return this.draw(o), o;
  }
  linearPath(t, r) {
    const i = this.gen.linearPath(t, r);
    return this.draw(i), i;
  }
  polygon(t, r) {
    const i = this.gen.polygon(t, r);
    return this.draw(i), i;
  }
  arc(t, r, i, s, o, a, n = !1, l) {
    const c = this.gen.arc(t, r, i, s, o, a, n, l);
    return this.draw(c), c;
  }
  curve(t, r) {
    const i = this.gen.curve(t, r);
    return this.draw(i), i;
  }
  path(t, r) {
    const i = this.gen.path(t, r);
    return this.draw(i), i;
  }
}
const Ts = "http://www.w3.org/2000/svg";
class g_ {
  constructor(t, r) {
    this.svg = t, this.gen = new mo(r);
  }
  draw(t) {
    const r = t.sets || [], i = t.options || this.getDefaultOptions(), s = this.svg.ownerDocument || window.document, o = s.createElementNS(Ts, "g"), a = t.options.fixedDecimalPlaceDigits;
    for (const n of r) {
      let l = null;
      switch (n.type) {
        case "path":
          l = s.createElementNS(Ts, "path"), l.setAttribute("d", this.opsToPath(n, a)), l.setAttribute("stroke", i.stroke), l.setAttribute("stroke-width", i.strokeWidth + ""), l.setAttribute("fill", "none"), i.strokeLineDash && l.setAttribute("stroke-dasharray", i.strokeLineDash.join(" ").trim()), i.strokeLineDashOffset && l.setAttribute("stroke-dashoffset", `${i.strokeLineDashOffset}`);
          break;
        case "fillPath":
          l = s.createElementNS(Ts, "path"), l.setAttribute("d", this.opsToPath(n, a)), l.setAttribute("stroke", "none"), l.setAttribute("stroke-width", "0"), l.setAttribute("fill", i.fill || ""), t.shape !== "curve" && t.shape !== "polygon" || l.setAttribute("fill-rule", "evenodd");
          break;
        case "fillSketch":
          l = this.fillSketch(s, n, i);
      }
      l && o.appendChild(l);
    }
    return o;
  }
  fillSketch(t, r, i) {
    let s = i.fillWeight;
    s < 0 && (s = i.strokeWidth / 2);
    const o = t.createElementNS(Ts, "path");
    return o.setAttribute("d", this.opsToPath(r, i.fixedDecimalPlaceDigits)), o.setAttribute("stroke", i.fill || ""), o.setAttribute("stroke-width", s + ""), o.setAttribute("fill", "none"), i.fillLineDash && o.setAttribute("stroke-dasharray", i.fillLineDash.join(" ").trim()), i.fillLineDashOffset && o.setAttribute("stroke-dashoffset", `${i.fillLineDashOffset}`), o;
  }
  get generator() {
    return this.gen;
  }
  getDefaultOptions() {
    return this.gen.defaultOptions;
  }
  opsToPath(t, r) {
    return this.gen.opsToPath(t, r);
  }
  line(t, r, i, s, o) {
    const a = this.gen.line(t, r, i, s, o);
    return this.draw(a);
  }
  rectangle(t, r, i, s, o) {
    const a = this.gen.rectangle(t, r, i, s, o);
    return this.draw(a);
  }
  ellipse(t, r, i, s, o) {
    const a = this.gen.ellipse(t, r, i, s, o);
    return this.draw(a);
  }
  circle(t, r, i, s) {
    const o = this.gen.circle(t, r, i, s);
    return this.draw(o);
  }
  linearPath(t, r) {
    const i = this.gen.linearPath(t, r);
    return this.draw(i);
  }
  polygon(t, r) {
    const i = this.gen.polygon(t, r);
    return this.draw(i);
  }
  arc(t, r, i, s, o, a, n = !1, l) {
    const c = this.gen.arc(t, r, i, s, o, a, n, l);
    return this.draw(c);
  }
  curve(t, r) {
    const i = this.gen.curve(t, r);
    return this.draw(i);
  }
  path(t, r) {
    const i = this.gen.path(t, r);
    return this.draw(i);
  }
}
var U = { canvas: (e, t) => new f_(e, t), svg: (e, t) => new g_(e, t), generator: (e) => new mo(e), newSeed: () => mo.newSeed() }, st = /* @__PURE__ */ f(async (e, t, r) => {
  let i;
  const s = t.useHtmlLabels || je(gt()?.htmlLabels);
  r ? i = r : i = "node default";
  const o = e.insert("g").attr("class", i).attr("id", t.domId || t.id), a = o.insert("g").attr("class", "label").attr("style", Dt(t.labelStyle));
  let n;
  t.label === void 0 ? n = "" : n = typeof t.label == "string" ? t.label : t.label[0];
  const l = !!t.icon || !!t.img, c = t.labelType === "markdown", h = await Ge(
    a,
    xe(Sr(n), gt()),
    {
      useHtmlLabels: s,
      width: t.width || gt().flowchart?.wrappingWidth,
      classes: c ? "markdown-node-label" : "",
      style: t.labelStyle,
      addSvgBackground: l,
      markdown: c
    },
    gt()
  );
  let u = h.getBBox();
  const p = (t?.padding ?? 0) / 2;
  if (s) {
    const d = h.children[0], g = ct(h);
    await df(d, n), u = d.getBoundingClientRect(), g.attr("width", u.width), g.attr("height", u.height);
  }
  return s ? a.attr("transform", "translate(" + -u.width / 2 + ", " + -u.height / 2 + ")") : a.attr("transform", "translate(0, " + -u.height / 2 + ")"), t.centerLabel && a.attr("transform", "translate(" + -u.width / 2 + ", " + -u.height / 2 + ")"), a.insert("rect", ":first-child"), { shapeSvg: o, bbox: u, halfPadding: p, label: a };
}, "labelHelper"), xa = /* @__PURE__ */ f(async (e, t, r) => {
  const i = r.useHtmlLabels ?? Vt(gt()), s = e.insert("g").attr("class", "label").attr("style", r.labelStyle || ""), o = await Ge(s, xe(Sr(t), gt()), {
    useHtmlLabels: i,
    width: r.width || gt()?.flowchart?.wrappingWidth,
    style: r.labelStyle,
    addSvgBackground: !!r.icon || !!r.img
  });
  let a = o.getBBox();
  const n = r.padding / 2;
  if (Vt(gt())) {
    const l = o.children[0], c = ct(o);
    a = l.getBoundingClientRect(), c.attr("width", a.width), c.attr("height", a.height);
  }
  return i ? s.attr("transform", "translate(" + -a.width / 2 + ", " + -a.height / 2 + ")") : s.attr("transform", "translate(0, " + -a.height / 2 + ")"), r.centerLabel && s.attr("transform", "translate(" + -a.width / 2 + ", " + -a.height / 2 + ")"), s.insert("rect", ":first-child"), { shapeSvg: e, bbox: a, halfPadding: n, label: s };
}, "insertLabel"), Z = /* @__PURE__ */ f((e, t) => {
  const r = t.node().getBBox();
  e.width = r.width, e.height = r.height;
}, "updateNodeBounds"), tt = /* @__PURE__ */ f((e, t) => (e.look === "handDrawn" ? "rough-node" : "node") + " " + e.cssClasses + " " + (t || ""), "getNodeClasses");
function pt(e) {
  const t = e.map((r, i) => `${i === 0 ? "M" : "L"}${r.x},${r.y}`);
  return t.push("Z"), t.join(" ");
}
f(pt, "createPathFromPoints");
function sr(e, t, r, i, s, o) {
  const a = [], l = r - e, c = i - t, h = l / o, u = 2 * Math.PI / h, p = t + c / 2;
  for (let d = 0; d <= 50; d++) {
    const g = d / 50, m = e + g * l, y = p + s * Math.sin(u * (m - e));
    a.push({ x: m, y });
  }
  return a;
}
f(sr, "generateFullSineWavePoints");
function Xi(e, t, r, i, s, o) {
  const a = [], n = s * Math.PI / 180, h = (o * Math.PI / 180 - n) / (i - 1);
  for (let u = 0; u < i; u++) {
    const p = n + u * h, d = e + r * Math.cos(p), g = t + r * Math.sin(p);
    a.push({ x: -d, y: -g });
  }
  return a;
}
f(Xi, "generateCirclePoints");
function pn(e) {
  const t = Array.from(e.childNodes).filter(
    (l) => l.tagName === "path"
  ), r = document.createElementNS("http://www.w3.org/2000/svg", "path"), i = t.map((l) => l.getAttribute("d")).filter((l) => l !== null).join(" ");
  r.setAttribute("d", i);
  const s = t.find((l) => l.getAttribute("fill") !== "none"), o = t.find((l) => l.getAttribute("stroke") !== "none"), a = /* @__PURE__ */ f((l, c) => l?.getAttribute(c) ?? void 0, "getAttr");
  if (s) {
    const l = {
      fill: a(s, "fill"),
      "fill-opacity": a(s, "fill-opacity") ?? "1"
    };
    Object.entries(l).forEach(([c, h]) => {
      h && r.setAttribute(c, h);
    });
  }
  if (o) {
    const l = {
      stroke: a(o, "stroke"),
      "stroke-width": a(o, "stroke-width") ?? "1",
      "stroke-opacity": a(o, "stroke-opacity") ?? "1"
    };
    Object.entries(l).forEach(([c, h]) => {
      h && r.setAttribute(c, h);
    });
  }
  const n = document.createElementNS("http://www.w3.org/2000/svg", "g");
  return n.appendChild(r), n;
}
f(pn, "mergePaths");
var m_ = /* @__PURE__ */ f((e, t) => {
  var r = e.x, i = e.y, s = t.x - r, o = t.y - i, a = e.width / 2, n = e.height / 2, l, c;
  return Math.abs(o) * a > Math.abs(s) * n ? (o < 0 && (n = -n), l = o === 0 ? 0 : n * s / o, c = n) : (s < 0 && (a = -a), l = a, c = s === 0 ? 0 : a * o / s), { x: r + l, y: i + c };
}, "intersectRect"), oi = m_, y_ = /* @__PURE__ */ f(async (e, t, r, i = !1, s = !1) => {
  let o = t || "";
  typeof o == "object" && (o = o[0]);
  const a = gt(), n = Vt(a);
  return await Ge(
    e,
    o,
    {
      style: r,
      isTitle: i,
      useHtmlLabels: n,
      markdown: !1,
      isNode: s,
      width: Number.POSITIVE_INFINITY
    },
    a
  );
}, "createLabel"), Ke = y_, ar = /* @__PURE__ */ f((e, t, r, i, s) => [
  "M",
  e + s,
  t,
  // Move to the first point
  "H",
  e + r - s,
  // Draw horizontal line to the beginning of the right corner
  "A",
  s,
  s,
  0,
  0,
  1,
  e + r,
  t + s,
  // Draw arc to the right top corner
  "V",
  t + i - s,
  // Draw vertical line down to the beginning of the right bottom corner
  "A",
  s,
  s,
  0,
  0,
  1,
  e + r - s,
  t + i,
  // Draw arc to the right bottom corner
  "H",
  e + s,
  // Draw horizontal line to the beginning of the left bottom corner
  "A",
  s,
  s,
  0,
  0,
  1,
  e,
  t + i - s,
  // Draw arc to the left bottom corner
  "V",
  t + s,
  // Draw vertical line up to the beginning of the left top corner
  "A",
  s,
  s,
  0,
  0,
  1,
  e + s,
  t,
  // Draw arc to the left top corner
  "Z"
  // Close the path
].join(" "), "createRoundedRectPathD"), Gf = /* @__PURE__ */ f(async (e, t) => {
  R.info("Creating subgraph rect for ", t.id, t);
  const r = gt(), { themeVariables: i, handDrawnSeed: s } = r, { clusterBkg: o, clusterBorder: a } = i, { labelStyles: n, nodeStyles: l, borderStyles: c, backgroundStyles: h } = V(t), u = e.insert("g").attr("class", "cluster " + t.cssClasses).attr("id", t.domId).attr("data-look", t.look), p = Vt(r), d = u.insert("g").attr("class", "cluster-label ");
  let g;
  t.labelType === "markdown" ? g = await Ge(d, t.label, {
    style: t.labelStyle,
    useHtmlLabels: p,
    isNode: !0,
    width: t.width
  }) : g = await Ke(d, t.label, t.labelStyle || "", !1, !0);
  let m = g.getBBox();
  if (Vt(r)) {
    const M = g.children[0], B = ct(g);
    m = M.getBoundingClientRect(), B.attr("width", m.width), B.attr("height", m.height);
  }
  const y = t.width <= m.width + t.padding ? m.width + t.padding : t.width;
  t.width <= m.width + t.padding ? t.diff = (y - t.width) / 2 - t.padding : t.diff = -t.padding;
  const x = t.height, b = t.x - y / 2, k = t.y - x / 2;
  R.trace("Data ", t, JSON.stringify(t));
  let w;
  if (t.look === "handDrawn") {
    const M = U.svg(u), B = X(t, {
      roughness: 0.7,
      fill: o,
      // fill: 'red',
      stroke: a,
      fillWeight: 3,
      seed: s
    }), N = M.path(ar(b, k, y, x, 0), B);
    w = u.insert(() => (R.debug("Rough node insert CXC", N), N), ":first-child"), w.select("path:nth-child(2)").attr("style", c.join(";")), w.select("path").attr("style", h.join(";").replace("fill", "stroke"));
  } else
    w = u.insert("rect", ":first-child"), w.attr("style", l).attr("rx", t.rx).attr("ry", t.ry).attr("x", b).attr("y", k).attr("width", y).attr("height", x);
  const { subGraphTitleTopMargin: S } = hl(r);
  if (d.attr(
    "transform",
    // This puts the label on top of the box instead of inside it
    `translate(${t.x - m.width / 2}, ${t.y - t.height / 2 + S})`
  ), n) {
    const M = d.select("span");
    M && M.attr("style", n);
  }
  const v = w.node().getBBox();
  return t.offsetX = 0, t.width = v.width, t.height = v.height, t.offsetY = m.height - t.padding / 2, t.intersect = function(M) {
    return oi(t, M);
  }, { cluster: u, labelBBox: m };
}, "rect"), C_ = /* @__PURE__ */ f((e, t) => {
  const r = e.insert("g").attr("class", "note-cluster").attr("id", t.domId), i = r.insert("rect", ":first-child"), s = 0 * t.padding, o = s / 2;
  i.attr("rx", t.rx).attr("ry", t.ry).attr("x", t.x - t.width / 2 - o).attr("y", t.y - t.height / 2 - o).attr("width", t.width + s).attr("height", t.height + s).attr("fill", "none");
  const a = i.node().getBBox();
  return t.width = a.width, t.height = a.height, t.intersect = function(n) {
    return oi(t, n);
  }, { cluster: r, labelBBox: { width: 0, height: 0 } };
}, "noteGroup"), x_ = /* @__PURE__ */ f(async (e, t) => {
  const r = gt(), { themeVariables: i, handDrawnSeed: s } = r, { altBackground: o, compositeBackground: a, compositeTitleBackground: n, nodeBorder: l } = i, c = e.insert("g").attr("class", t.cssClasses).attr("id", t.domId).attr("data-id", t.id).attr("data-look", t.look), h = c.insert("g", ":first-child"), u = c.insert("g").attr("class", "cluster-label");
  let p = c.append("rect");
  const d = await Ke(u, t.label, t.labelStyle, void 0, !0);
  let g = d.getBBox();
  if (Vt(r)) {
    const N = d.children[0], D = ct(d);
    g = N.getBoundingClientRect(), D.attr("width", g.width), D.attr("height", g.height);
  }
  const m = 0 * t.padding, y = m / 2, x = (t.width <= g.width + t.padding ? g.width + t.padding : t.width) + m;
  t.width <= g.width + t.padding ? t.diff = (x - t.width) / 2 - t.padding : t.diff = -t.padding;
  const b = t.height + m, k = t.height + m - g.height - 6, w = t.x - x / 2, S = t.y - b / 2;
  t.width = x;
  const v = t.y - t.height / 2 - y + g.height + 2;
  let M;
  if (t.look === "handDrawn") {
    const N = t.cssClasses.includes("statediagram-cluster-alt"), D = U.svg(c), O = t.rx || t.ry ? D.path(ar(w, S, x, b, 10), {
      roughness: 0.7,
      fill: n,
      fillStyle: "solid",
      stroke: l,
      seed: s
    }) : D.rectangle(w, S, x, b, { seed: s });
    M = c.insert(() => O, ":first-child");
    const W = D.rectangle(w, v, x, k, {
      fill: N ? o : a,
      fillStyle: N ? "hachure" : "solid",
      stroke: l,
      seed: s
    });
    M = c.insert(() => O, ":first-child"), p = c.insert(() => W);
  } else
    M = h.insert("rect", ":first-child"), M.attr("class", "outer").attr("x", w).attr("y", S).attr("width", x).attr("height", b).attr("data-look", t.look), p.attr("class", "inner").attr("x", w).attr("y", v).attr("width", x).attr("height", k);
  u.attr(
    "transform",
    `translate(${t.x - g.width / 2}, ${S + 1 - (Vt(r) ? 0 : 3)})`
  );
  const B = M.node().getBBox();
  return t.height = B.height, t.offsetX = 0, t.offsetY = g.height - t.padding / 2, t.labelBBox = g, t.intersect = function(N) {
    return oi(t, N);
  }, { cluster: c, labelBBox: g };
}, "roundedWithTitle"), b_ = /* @__PURE__ */ f(async (e, t) => {
  R.info("Creating subgraph rect for ", t.id, t);
  const r = gt(), { themeVariables: i, handDrawnSeed: s } = r, { clusterBkg: o, clusterBorder: a } = i, { labelStyles: n, nodeStyles: l, borderStyles: c, backgroundStyles: h } = V(t), u = e.insert("g").attr("class", "cluster " + t.cssClasses).attr("id", t.domId).attr("data-look", t.look), p = Vt(r), d = u.insert("g").attr("class", "cluster-label "), g = await Ge(d, t.label, {
    style: t.labelStyle,
    useHtmlLabels: p,
    isNode: !0,
    width: t.width
  });
  let m = g.getBBox();
  if (Vt(r)) {
    const M = g.children[0], B = ct(g);
    m = M.getBoundingClientRect(), B.attr("width", m.width), B.attr("height", m.height);
  }
  const y = t.width <= m.width + t.padding ? m.width + t.padding : t.width;
  t.width <= m.width + t.padding ? t.diff = (y - t.width) / 2 - t.padding : t.diff = -t.padding;
  const x = t.height, b = t.x - y / 2, k = t.y - x / 2;
  R.trace("Data ", t, JSON.stringify(t));
  let w;
  if (t.look === "handDrawn") {
    const M = U.svg(u), B = X(t, {
      roughness: 0.7,
      fill: o,
      // fill: 'red',
      stroke: a,
      fillWeight: 4,
      seed: s
    }), N = M.path(ar(b, k, y, x, t.rx), B);
    w = u.insert(() => (R.debug("Rough node insert CXC", N), N), ":first-child"), w.select("path:nth-child(2)").attr("style", c.join(";")), w.select("path").attr("style", h.join(";").replace("fill", "stroke"));
  } else
    w = u.insert("rect", ":first-child"), w.attr("style", l).attr("rx", t.rx).attr("ry", t.ry).attr("x", b).attr("y", k).attr("width", y).attr("height", x);
  const { subGraphTitleTopMargin: S } = hl(r);
  if (d.attr(
    "transform",
    // This puts the label on top of the box instead of inside it
    `translate(${t.x - m.width / 2}, ${t.y - t.height / 2 + S})`
  ), n) {
    const M = d.select("span");
    M && M.attr("style", n);
  }
  const v = w.node().getBBox();
  return t.offsetX = 0, t.width = v.width, t.height = v.height, t.offsetY = m.height - t.padding / 2, t.intersect = function(M) {
    return oi(t, M);
  }, { cluster: u, labelBBox: m };
}, "kanbanSection"), k_ = /* @__PURE__ */ f((e, t) => {
  const r = gt(), { themeVariables: i, handDrawnSeed: s } = r, { nodeBorder: o } = i, a = e.insert("g").attr("class", t.cssClasses).attr("id", t.domId).attr("data-look", t.look), n = a.insert("g", ":first-child"), l = 0 * t.padding, c = t.width + l;
  t.diff = -t.padding;
  const h = t.height + l, u = t.x - c / 2, p = t.y - h / 2;
  t.width = c;
  let d;
  if (t.look === "handDrawn") {
    const y = U.svg(a).rectangle(u, p, c, h, {
      fill: "lightgrey",
      roughness: 0.5,
      strokeLineDash: [5],
      stroke: o,
      seed: s
    });
    d = a.insert(() => y, ":first-child");
  } else {
    d = n.insert("rect", ":first-child");
    let m = "outer";
    t.look, m = "divider", d.attr("class", m).attr("x", u).attr("y", p).attr("width", c).attr("height", h).attr("data-look", t.look);
  }
  const g = d.node().getBBox();
  return t.height = g.height, t.offsetX = 0, t.offsetY = 0, t.intersect = function(m) {
    return oi(t, m);
  }, { cluster: a, labelBBox: {} };
}, "divider"), T_ = Gf, w_ = {
  rect: Gf,
  squareRect: T_,
  roundedWithTitle: x_,
  noteGroup: C_,
  divider: k_,
  kanbanSection: b_
}, Xf = /* @__PURE__ */ new Map(), S_ = /* @__PURE__ */ f(async (e, t) => {
  const r = t.shape || "rect", i = await w_[r](e, t);
  return Xf.set(t.id, i), i;
}, "insertCluster"), SA = /* @__PURE__ */ f(() => {
  Xf = /* @__PURE__ */ new Map();
}, "clear");
function Vf(e, t) {
  return e.intersect(t);
}
f(Vf, "intersectNode");
var __ = Vf;
function Zf(e, t, r, i) {
  var s = e.x, o = e.y, a = s - i.x, n = o - i.y, l = Math.sqrt(t * t * n * n + r * r * a * a), c = Math.abs(t * r * a / l);
  i.x < s && (c = -c);
  var h = Math.abs(t * r * n / l);
  return i.y < o && (h = -h), { x: s + c, y: o + h };
}
f(Zf, "intersectEllipse");
var Kf = Zf;
function Qf(e, t, r) {
  return Kf(e, t, t, r);
}
f(Qf, "intersectCircle");
var v_ = Qf;
function Jf(e, t, r, i) {
  {
    const s = t.y - e.y, o = e.x - t.x, a = t.x * e.y - e.x * t.y, n = s * r.x + o * r.y + a, l = s * i.x + o * i.y + a, c = 1e-6;
    if (n !== 0 && l !== 0 && fn(n, l))
      return;
    const h = i.y - r.y, u = r.x - i.x, p = i.x * r.y - r.x * i.y, d = h * e.x + u * e.y + p, g = h * t.x + u * t.y + p;
    if (Math.abs(d) < c && Math.abs(g) < c && fn(d, g))
      return;
    const m = s * u - h * o;
    if (m === 0)
      return;
    const y = Math.abs(m / 2);
    let x = o * p - u * a;
    const b = x < 0 ? (x - y) / m : (x + y) / m;
    x = h * a - s * p;
    const k = x < 0 ? (x - y) / m : (x + y) / m;
    return { x: b, y: k };
  }
}
f(Jf, "intersectLine");
function fn(e, t) {
  return e * t > 0;
}
f(fn, "sameSign");
var B_ = Jf;
function tg(e, t, r) {
  let i = e.x, s = e.y, o = [], a = Number.POSITIVE_INFINITY, n = Number.POSITIVE_INFINITY;
  typeof t.forEach == "function" ? t.forEach(function(h) {
    a = Math.min(a, h.x), n = Math.min(n, h.y);
  }) : (a = Math.min(a, t.x), n = Math.min(n, t.y));
  let l = i - e.width / 2 - a, c = s - e.height / 2 - n;
  for (let h = 0; h < t.length; h++) {
    let u = t[h], p = t[h < t.length - 1 ? h + 1 : 0], d = B_(
      e,
      r,
      { x: l + u.x, y: c + u.y },
      { x: l + p.x, y: c + p.y }
    );
    d && o.push(d);
  }
  return o.length ? (o.length > 1 && o.sort(function(h, u) {
    let p = h.x - r.x, d = h.y - r.y, g = Math.sqrt(p * p + d * d), m = u.x - r.x, y = u.y - r.y, x = Math.sqrt(m * m + y * y);
    return g < x ? -1 : g === x ? 0 : 1;
  }), o[0]) : e;
}
f(tg, "intersectPolygon");
var L_ = tg, j = {
  node: __,
  circle: v_,
  ellipse: Kf,
  polygon: L_,
  rect: oi
};
function eg(e, t) {
  const { labelStyles: r } = V(t);
  t.labelStyle = r;
  const i = tt(t);
  let s = i;
  i || (s = "anchor");
  const o = e.insert("g").attr("class", s).attr("id", t.domId || t.id), a = 1, { cssStyles: n } = t, l = U.svg(o), c = X(t, { fill: "black", stroke: "none", fillStyle: "solid" });
  t.look !== "handDrawn" && (c.roughness = 0);
  const h = l.circle(0, 0, a * 2, c), u = o.insert(() => h, ":first-child");
  return u.attr("class", "anchor").attr("style", Dt(n)), Z(t, u), t.intersect = function(p) {
    return R.info("Circle intersect", t, a, p), j.circle(t, a, p);
  }, o;
}
f(eg, "anchor");
function gn(e, t, r, i, s, o, a) {
  const l = (e + r) / 2, c = (t + i) / 2, h = Math.atan2(i - t, r - e), u = (r - e) / 2, p = (i - t) / 2, d = u / s, g = p / o, m = Math.sqrt(d ** 2 + g ** 2);
  if (m > 1)
    throw new Error("The given radii are too small to create an arc between the points.");
  const y = Math.sqrt(1 - m ** 2), x = l + y * o * Math.sin(h) * (a ? -1 : 1), b = c - y * s * Math.cos(h) * (a ? -1 : 1), k = Math.atan2((t - b) / o, (e - x) / s);
  let S = Math.atan2((i - b) / o, (r - x) / s) - k;
  a && S < 0 && (S += 2 * Math.PI), !a && S > 0 && (S -= 2 * Math.PI);
  const v = [];
  for (let M = 0; M < 20; M++) {
    const B = M / 19, N = k + B * S, D = x + s * Math.cos(N), O = b + o * Math.sin(N);
    v.push({ x: D, y: O });
  }
  return v;
}
f(gn, "generateArcPoints");
function rg(e, t, r) {
  const [i, s] = [t, r].sort((o, a) => a - o);
  return s * (1 - Math.sqrt(1 - (e / i / 2) ** 2));
}
f(rg, "calculateArcSagitta");
async function ig(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 16 : s, a = t.look === "neo" ? 12 : s, n = /* @__PURE__ */ f((N) => N + a, "calcTotalHeight"), l = /* @__PURE__ */ f((N) => {
    const D = N / 2;
    return [D / (2.5 + N / 50), D];
  }, "calcEllipseRadius"), { shapeSvg: c, bbox: h } = await st(e, t, tt(t)), u = n(t?.height ? t?.height : h.height), [p, d] = l(u), g = rg(u, p, d), y = (t?.width ? t?.width : h.width) + o * 2 + g - g, x = u, { cssStyles: b } = t, k = [
    { x: y / 2, y: -x / 2 },
    { x: -y / 2, y: -x / 2 },
    ...gn(-y / 2, -x / 2, -y / 2, x / 2, p, d, !1),
    { x: y / 2, y: x / 2 },
    ...gn(y / 2, x / 2, y / 2, -x / 2, p, d, !0)
  ], w = U.svg(c), S = X(t, {});
  t.look !== "handDrawn" && (S.roughness = 0, S.fillStyle = "solid");
  const v = pt(k), M = w.path(v, S), B = c.insert(() => M, ":first-child");
  return B.attr("class", "basic label-container outer-path"), b && t.look !== "handDrawn" && B.selectAll("path").attr("style", b), i && t.look !== "handDrawn" && B.selectAll("path").attr("style", i), B.attr("transform", `translate(${p / 2}, 0)`), Z(t, B), t.intersect = function(N) {
    return j.polygon(t, k, N);
  }, c;
}
f(ig, "bowTieRect");
function Xe(e, t, r, i) {
  return e.insert("polygon", ":first-child").attr(
    "points",
    i.map(function(s) {
      return s.x + "," + s.y;
    }).join(" ")
  ).attr("class", "label-container").attr("transform", "translate(" + -t / 2 + "," + r / 2 + ")");
}
f(Xe, "insertPolygonShape");
var ws = 12;
async function sg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 28 : s, a = t.look === "neo" ? 24 : s, { shapeSvg: n, bbox: l } = await st(e, t, tt(t)), c = (t?.width ?? l.width) + (t.look === "neo" ? o * 2 : o + ws), h = (t?.height ?? l.height) + (t.look === "neo" ? a * 2 : a), u = 0, p = c, d = -h, g = 0, m = [
    { x: u + ws, y: d },
    { x: p, y: d },
    { x: p, y: g },
    { x: u, y: g },
    { x: u, y: d + ws },
    { x: u + ws, y: d }
  ];
  let y;
  const { cssStyles: x } = t;
  if (t.look === "handDrawn") {
    const b = U.svg(n), k = X(t, {}), w = pt(m), S = b.path(w, k);
    y = n.insert(() => S, ":first-child").attr("transform", `translate(${-c / 2}, ${h / 2})`), x && y.attr("style", x);
  } else
    y = Xe(n, c, h, m);
  return i && y.attr("style", i), Z(t, y), t.intersect = function(b) {
    return j.polygon(t, m, b);
  }, n;
}
f(sg, "card");
function og(e, t) {
  const { nodeStyles: r } = V(t);
  t.label = "";
  const i = e.insert("g").attr("class", tt(t)).attr("id", t.domId ?? t.id), { cssStyles: s } = t, o = Math.max(28, t.width ?? 0), a = [
    { x: 0, y: o / 2 },
    { x: o / 2, y: 0 },
    { x: 0, y: -o / 2 },
    { x: -o / 2, y: 0 }
  ], n = U.svg(i), l = X(t, {});
  t.look !== "handDrawn" && (l.roughness = 0, l.fillStyle = "solid");
  const c = pt(a), h = n.path(c, l), u = i.insert(() => h, ":first-child");
  return s && t.look !== "handDrawn" && u.selectAll("path").attr("style", s), r && t.look !== "handDrawn" && u.selectAll("path").attr("style", r), t.width = 28, t.height = 28, t.intersect = function(p) {
    return j.polygon(t, a, p);
  }, i;
}
f(og, "choice");
async function Tl(e, t, r) {
  const { labelStyles: i, nodeStyles: s } = V(t);
  t.labelStyle = i;
  const { shapeSvg: o, bbox: a, halfPadding: n } = await st(e, t, tt(t)), l = 16, c = r?.padding ?? n, h = t.look === "neo" ? a.width / 2 + l * 2 : a.width / 2 + c;
  let u;
  const { cssStyles: p } = t;
  if (t.look === "handDrawn") {
    const d = U.svg(o), g = X(t, {}), m = d.circle(0, 0, h * 2, g);
    u = o.insert(() => m, ":first-child"), u.attr("class", "basic label-container").attr("style", Dt(p));
  } else
    u = o.insert("circle", ":first-child").attr("class", "basic label-container").attr("style", s).attr("r", h).attr("cx", 0).attr("cy", 0);
  return Z(t, u), t.calcIntersect = function(d, g) {
    const m = d.width / 2;
    return j.circle(d, m, g);
  }, t.intersect = function(d) {
    return R.info("Circle intersect", t, h, d), j.circle(t, h, d);
  }, o;
}
f(Tl, "circle");
function ag(e) {
  const t = Math.cos(Math.PI / 4), r = Math.sin(Math.PI / 4), i = e * 2, s = { x: i / 2 * t, y: i / 2 * r }, o = { x: -(i / 2) * t, y: i / 2 * r }, a = { x: -(i / 2) * t, y: -(i / 2) * r }, n = { x: i / 2 * t, y: -(i / 2) * r };
  return `M ${o.x},${o.y} L ${n.x},${n.y}
                   M ${s.x},${s.y} L ${a.x},${a.y}`;
}
f(ag, "createLine");
function ng(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r, t.label = "";
  const s = e.insert("g").attr("class", tt(t)).attr("id", t.domId ?? t.id), o = Math.max(30, t?.width ?? 0), { cssStyles: a } = t, n = U.svg(s), l = X(t, {});
  t.look !== "handDrawn" && (l.roughness = 0, l.fillStyle = "solid");
  const c = n.circle(0, 0, o * 2, l), h = ag(o), u = n.path(h, l), p = s.insert(() => c, ":first-child");
  return p.insert(() => u), p.attr("class", "outer-path"), a && t.look !== "handDrawn" && p.selectAll("path").attr("style", a), i && t.look !== "handDrawn" && p.selectAll("path").attr("style", i), Z(t, p), t.intersect = function(d) {
    return R.info("crossedCircle intersect", t, { radius: o, point: d }), j.circle(t, o, d);
  }, s;
}
f(ng, "crossedCircle");
function Re(e, t, r, i = 100, s = 0, o = 180) {
  const a = [], n = s * Math.PI / 180, h = (o * Math.PI / 180 - n) / (i - 1);
  for (let u = 0; u < i; u++) {
    const p = n + u * h, d = e + r * Math.cos(p), g = t + r * Math.sin(p);
    a.push({ x: -d, y: -g });
  }
  return a;
}
f(Re, "generateCirclePoints");
async function lg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const { shapeSvg: s, bbox: o, label: a } = await st(e, t, tt(t)), n = t.look === "neo" ? 18 : t.padding ?? 0, l = t.look === "neo" ? 12 : t.padding ?? 0, c = o.width + n, h = o.height + l, u = Math.max(5, h * 0.1), { cssStyles: p } = t, d = [
    ...Re(c / 2, -h / 2, u, 30, -90, 0),
    { x: -c / 2 - u, y: u },
    ...Re(c / 2 + u * 2, -u, u, 20, -180, -270),
    ...Re(c / 2 + u * 2, u, u, 20, -90, -180),
    { x: -c / 2 - u, y: -h / 2 },
    ...Re(c / 2, h / 2, u, 20, 0, 90)
  ], g = [
    { x: c / 2, y: -h / 2 - u },
    { x: -c / 2, y: -h / 2 - u },
    ...Re(c / 2, -h / 2, u, 20, -90, 0),
    { x: -c / 2 - u, y: -u },
    ...Re(c / 2 + c * 0.1, -u, u, 20, -180, -270),
    ...Re(c / 2 + c * 0.1, u, u, 20, -90, -180),
    { x: -c / 2 - u, y: h / 2 },
    ...Re(c / 2, h / 2, u, 20, 0, 90),
    { x: -c / 2, y: h / 2 + u },
    { x: c / 2, y: h / 2 + u }
  ], m = U.svg(s), y = X(t, { fill: "none" });
  t.look !== "handDrawn" && (y.roughness = 0, y.fillStyle = "solid");
  const b = pt(d).replace("Z", ""), k = m.path(b, y), w = pt(g), S = m.path(w, { ...y }), v = s.insert("g", ":first-child");
  return v.insert(() => S, ":first-child").attr("stroke-opacity", 0), v.insert(() => k, ":first-child"), v.attr("class", "text"), p && t.look !== "handDrawn" && v.selectAll("path").attr("style", p), i && t.look !== "handDrawn" && v.selectAll("path").attr("style", i), v.attr("transform", `translate(${u}, 0)`), a.attr(
    "transform",
    `translate(${-c / 2 + u - (o.x - (o.left ?? 0))},${-h / 2 + (t.padding ?? 0) / 2 - (o.y - (o.top ?? 0))})`
  ), Z(t, v), t.intersect = function(M) {
    return j.polygon(t, g, M);
  }, s;
}
f(lg, "curlyBraceLeft");
function Ne(e, t, r, i = 100, s = 0, o = 180) {
  const a = [], n = s * Math.PI / 180, h = (o * Math.PI / 180 - n) / (i - 1);
  for (let u = 0; u < i; u++) {
    const p = n + u * h, d = e + r * Math.cos(p), g = t + r * Math.sin(p);
    a.push({ x: d, y: g });
  }
  return a;
}
f(Ne, "generateCirclePoints");
async function hg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const { shapeSvg: s, bbox: o, label: a } = await st(e, t, tt(t)), n = t.look === "neo" ? 18 : t.padding ?? 0, l = t.look === "neo" ? 12 : t.padding ?? 0, c = o.width + (t.look === "neo" ? n * 2 : n), h = o.height + (t.look === "neo" ? l * 2 : l), u = Math.max(5, h * 0.1), { cssStyles: p } = t, d = [
    ...Ne(c / 2, -h / 2, u, 20, -90, 0),
    { x: c / 2 + u, y: -u },
    ...Ne(c / 2 + u * 2, -u, u, 20, -180, -270),
    ...Ne(c / 2 + u * 2, u, u, 20, -90, -180),
    { x: c / 2 + u, y: h / 2 },
    ...Ne(c / 2, h / 2, u, 20, 0, 90)
  ], g = [
    { x: -c / 2, y: -h / 2 - u },
    { x: c / 2, y: -h / 2 - u },
    ...Ne(c / 2, -h / 2, u, 20, -90, 0),
    { x: c / 2 + u, y: -u },
    ...Ne(c / 2 + u * 2, -u, u, 20, -180, -270),
    ...Ne(c / 2 + u * 2, u, u, 20, -90, -180),
    { x: c / 2 + u, y: h / 2 },
    ...Ne(c / 2, h / 2, u, 20, 0, 90),
    { x: c / 2, y: h / 2 + u },
    { x: -c / 2, y: h / 2 + u }
  ], m = U.svg(s), y = X(t, { fill: "none" });
  t.look !== "handDrawn" && (y.roughness = 0, y.fillStyle = "solid");
  const b = pt(d).replace("Z", ""), k = m.path(b, y), w = pt(g), S = m.path(w, { ...y }), v = s.insert("g", ":first-child");
  return v.insert(() => S, ":first-child").attr("stroke-opacity", 0), v.insert(() => k, ":first-child"), v.attr("class", "text"), p && t.look !== "handDrawn" && v.selectAll("path").attr("style", p), i && t.look !== "handDrawn" && v.selectAll("path").attr("style", i), v.attr("transform", `translate(${-u}, 0)`), a.attr(
    "transform",
    `translate(${-c / 2 + (t.padding ?? 0) / 2 - (o.x - (o.left ?? 0))},${-h / 2 + (t.padding ?? 0) / 2 - (o.y - (o.top ?? 0))})`
  ), Z(t, v), t.intersect = function(M) {
    return j.polygon(t, g, M);
  }, s;
}
f(hg, "curlyBraceRight");
function Rt(e, t, r, i = 100, s = 0, o = 180) {
  const a = [], n = s * Math.PI / 180, h = (o * Math.PI / 180 - n) / (i - 1);
  for (let u = 0; u < i; u++) {
    const p = n + u * h, d = e + r * Math.cos(p), g = t + r * Math.sin(p);
    a.push({ x: -d, y: -g });
  }
  return a;
}
f(Rt, "generateCirclePoints");
async function cg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const { shapeSvg: s, bbox: o, label: a } = await st(e, t, tt(t)), n = t.look === "neo" ? 18 : t.padding ?? 0, l = t.look === "neo" ? 12 : t.padding ?? 0, c = o.width + (t.look === "neo" ? n * 2 : n), h = o.height + (t.look === "neo" ? l * 2 : l), u = Math.max(5, h * 0.1), { cssStyles: p } = t, d = [
    ...Rt(c / 2, -h / 2, u, 30, -90, 0),
    { x: -c / 2 - u, y: u },
    ...Rt(c / 2 + u * 2, -u, u, 20, -180, -270),
    ...Rt(c / 2 + u * 2, u, u, 20, -90, -180),
    { x: -c / 2 - u, y: -h / 2 },
    ...Rt(c / 2, h / 2, u, 20, 0, 90)
  ], g = [
    ...Rt(-c / 2 + u + u / 2, -h / 2, u, 20, -90, -180),
    { x: c / 2 - u / 2, y: u },
    ...Rt(-c / 2 - u / 2, -u, u, 20, 0, 90),
    ...Rt(-c / 2 - u / 2, u, u, 20, -90, 0),
    { x: c / 2 - u / 2, y: -u },
    ...Rt(-c / 2 + u + u / 2, h / 2, u, 30, -180, -270)
  ], m = [
    { x: c / 2, y: -h / 2 - u },
    { x: -c / 2, y: -h / 2 - u },
    ...Rt(c / 2, -h / 2, u, 20, -90, 0),
    { x: -c / 2 - u, y: -u },
    ...Rt(c / 2 + u * 2, -u, u, 20, -180, -270),
    ...Rt(c / 2 + u * 2, u, u, 20, -90, -180),
    { x: -c / 2 - u, y: h / 2 },
    ...Rt(c / 2, h / 2, u, 20, 0, 90),
    { x: -c / 2, y: h / 2 + u },
    { x: c / 2 - u - u / 2, y: h / 2 + u },
    ...Rt(-c / 2 + u + u / 2, -h / 2, u, 20, -90, -180),
    { x: c / 2 - u / 2, y: u },
    ...Rt(-c / 2 - u / 2, -u, u, 20, 0, 90),
    ...Rt(-c / 2 - u / 2, u, u, 20, -90, 0),
    { x: c / 2 - u / 2, y: -u },
    ...Rt(-c / 2 + u + u / 2, h / 2, u, 30, -180, -270)
  ], y = U.svg(s), x = X(t, { fill: "none" });
  t.look !== "handDrawn" && (x.roughness = 0, x.fillStyle = "solid");
  const k = pt(d).replace("Z", ""), w = y.path(k, x), v = pt(g).replace("Z", ""), M = y.path(v, x), B = pt(m), N = y.path(B, { ...x }), D = s.insert("g", ":first-child");
  return D.insert(() => N, ":first-child").attr("stroke-opacity", 0), D.insert(() => w, ":first-child"), D.insert(() => M, ":first-child"), D.attr("class", "text"), p && t.look !== "handDrawn" && D.selectAll("path").attr("style", p), i && t.look !== "handDrawn" && D.selectAll("path").attr("style", i), D.attr("transform", `translate(${u - u / 4}, 0)`), a.attr(
    "transform",
    `translate(${-c / 2 + (t.padding ?? 0) / 2 - (o.x - (o.left ?? 0))},${-h / 2 + (t.padding ?? 0) / 2 - (o.y - (o.top ?? 0))})`
  ), Z(t, D), t.intersect = function(O) {
    return j.polygon(t, m, O);
  }, s;
}
f(cg, "curlyBraces");
async function ug(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 16 : s, a = t.look === "neo" ? 12 : s, n = 20, l = 5, { shapeSvg: c, bbox: h } = await st(e, t, tt(t)), u = Math.max(n, (h.width + o * 2) * 1.25, t?.width ?? 0), p = Math.max(l, h.height + a * 2, t?.height ?? 0), d = p / 2, { cssStyles: g } = t, m = U.svg(c), y = X(t, {});
  t.look !== "handDrawn" && (y.roughness = 0, y.fillStyle = "solid");
  const x = u, b = p, k = x - d, w = b / 4, S = [
    { x: k, y: 0 },
    { x: w, y: 0 },
    { x: 0, y: b / 2 },
    { x: w, y: b },
    { x: k, y: b },
    ...Xi(-k, -b / 2, d, 50, 270, 90)
  ], v = pt(S), M = m.path(v, y), B = c.insert(() => M, ":first-child");
  return B.attr("class", "basic label-container outer-path"), g && t.look !== "handDrawn" && B.selectChildren("path").attr("style", g), i && t.look !== "handDrawn" && B.selectChildren("path").attr("style", i), B.attr("transform", `translate(${-u / 2}, ${-p / 2})`), Z(t, B), t.intersect = function(N) {
    return j.polygon(t, S, N);
  }, c;
}
f(ug, "curvedTrapezoid");
var F_ = /* @__PURE__ */ f((e, t, r, i, s, o) => [
  `M${e},${t + o}`,
  `a${s},${o} 0,0,0 ${r},0`,
  `a${s},${o} 0,0,0 ${-r},0`,
  `l0,${i}`,
  `a${s},${o} 0,0,0 ${r},0`,
  `l0,${-i}`
].join(" "), "createCylinderPathD"), A_ = /* @__PURE__ */ f((e, t, r, i, s, o) => [
  `M${e},${t + o}`,
  `M${e + r},${t + o}`,
  `a${s},${o} 0,0,0 ${-r},0`,
  `l0,${i}`,
  `a${s},${o} 0,0,0 ${r},0`,
  `l0,${-i}`
].join(" "), "createOuterCylinderPathD"), M_ = /* @__PURE__ */ f((e, t, r, i, s, o) => [`M${e - r / 2},${-i / 2}`, `a${s},${o} 0,0,0 ${r},0`].join(" "), "createInnerCylinderPathD"), mc = 8, yc = 8;
async function dg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 24 : s, a = t.look === "neo" ? 24 : s;
  if (t.width || t.height) {
    const y = t.width ?? 0;
    t.width = (t.width ?? 0) - a, t.width < yc && (t.width = yc);
    const b = y / 2 / (2.5 + y / 50);
    t.height = (t.height ?? 0) - o - b * 3, t.height < mc && (t.height = mc);
  }
  const { shapeSvg: n, bbox: l, label: c } = await st(e, t, tt(t)), h = (t.width ? t.width : l.width) + a, u = h / 2, p = u / (2.5 + h / 50), d = (t.height ? t.height : l.height) + o + p;
  let g;
  const { cssStyles: m } = t;
  if (t.look === "handDrawn") {
    const y = U.svg(n), x = A_(0, 0, h, d, u, p), b = M_(0, p, h, d, u, p), k = X(t, {}), w = y.path(x, k), S = y.path(b, X(t, { fill: "none" }));
    g = n.insert(() => S, ":first-child"), g = n.insert(() => w, ":first-child"), g.attr("class", "basic label-container"), m && g.attr("style", m);
  } else {
    const y = F_(0, 0, h, d, u, p);
    g = n.insert("path", ":first-child").attr("d", y).attr("class", "basic label-container outer-path").attr("style", Dt(m)).attr("style", i);
  }
  return g.attr("label-offset-y", p), g.attr("transform", `translate(${-h / 2}, ${-(d / 2 + p)})`), Z(t, g), c.attr(
    "transform",
    `translate(${-(l.width / 2) - (l.x - (l.left ?? 0))}, ${-(l.height / 2) + (t.padding ?? 0) / 1.5 - (l.y - (l.top ?? 0))})`
  ), t.intersect = function(y) {
    const x = j.rect(t, y), b = x.x - (t.x ?? 0);
    if (u != 0 && (Math.abs(b) < (t.width ?? 0) / 2 || Math.abs(b) == (t.width ?? 0) / 2 && Math.abs(x.y - (t.y ?? 0)) > (t.height ?? 0) / 2 - p)) {
      let k = p * p * (1 - b * b / (u * u));
      k > 0 && (k = Math.sqrt(k)), k = p - k, y.y - (t.y ?? 0) > 0 && (k = -k), x.y += k;
    }
    return x;
  }, n;
}
f(dg, "cylinder");
async function pg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const s = t.look === "neo" ? 16 : t.padding ?? 0, o = t.look === "neo" ? 16 : t.padding ?? 0, { shapeSvg: a, bbox: n, label: l } = await st(e, t, tt(t)), c = n.width + s, h = n.height + o, u = h * 0.2, p = -c / 2, d = -h / 2 - u / 2, { cssStyles: g } = t, m = U.svg(a), y = X(t, {});
  t.look !== "handDrawn" && (y.roughness = 0, y.fillStyle = "solid");
  const x = [
    { x: p, y: d + u },
    { x: -p, y: d + u },
    { x: -p, y: -d },
    { x: p, y: -d },
    { x: p, y: d },
    { x: -p, y: d },
    { x: -p, y: d + u }
  ], b = m.polygon(
    x.map((w) => [w.x, w.y]),
    y
  ), k = a.insert(() => b, ":first-child");
  return k.attr("class", "basic label-container outer-path"), g && t.look !== "handDrawn" && k.selectAll("path").attr("style", g), i && t.look !== "handDrawn" && k.selectAll("path").attr("style", i), l.attr(
    "transform",
    `translate(${p + (t.padding ?? 0) / 2 - (n.x - (n.left ?? 0))}, ${d + u + (t.padding ?? 0) / 2 - (n.y - (n.top ?? 0))})`
  ), Z(t, k), t.intersect = function(w) {
    return j.rect(t, w);
  }, a;
}
f(pg, "dividedRectangle");
async function fg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t), s = t.look === "neo" ? 12 : 5;
  t.labelStyle = r;
  const o = t.padding ?? 0, a = t.look === "neo" ? 16 : o, { shapeSvg: n, bbox: l } = await st(e, t, tt(t)), c = (t?.width ? t?.width / 2 : l.width / 2) + (a ?? 0), h = c - s;
  let u;
  const { cssStyles: p } = t;
  if (t.look === "handDrawn") {
    const d = U.svg(n), g = X(t, { roughness: 0.2, strokeWidth: 2.5 }), m = X(t, { roughness: 0.2, strokeWidth: 1.5 }), y = d.circle(0, 0, c * 2, g), x = d.circle(0, 0, h * 2, m);
    u = n.insert("g", ":first-child"), u.attr("class", Dt(t.cssClasses)).attr("style", Dt(p)), u.node()?.appendChild(y), u.node()?.appendChild(x);
  } else {
    u = n.insert("g", ":first-child");
    const d = u.insert("circle", ":first-child"), g = u.insert("circle");
    u.attr("class", "basic label-container").attr("style", i), d.attr("class", "outer-circle").attr("style", i).attr("r", c).attr("cx", 0).attr("cy", 0), g.attr("class", "inner-circle").attr("style", i).attr("r", h).attr("cx", 0).attr("cy", 0);
  }
  return Z(t, u), t.intersect = function(d) {
    return R.info("DoubleCircle intersect", t, c, d), j.circle(t, c, d);
  }, n;
}
f(fg, "doublecircle");
function gg(e, t, { config: { themeVariables: r } }) {
  const { labelStyles: i, nodeStyles: s } = V(t);
  t.label = "", t.labelStyle = i;
  const o = e.insert("g").attr("class", tt(t)).attr("id", t.domId ?? t.id), a = 7, { cssStyles: n } = t, l = U.svg(o), { nodeBorder: c } = r, h = X(t, { fillStyle: "solid" });
  t.look !== "handDrawn" && (h.roughness = 0);
  const u = l.circle(0, 0, a * 2, h), p = o.insert(() => u, ":first-child");
  return p.selectAll("path").attr("style", `fill: ${c} !important;`), n && n.length > 0 && t.look !== "handDrawn" && p.selectAll("path").attr("style", n), s && t.look !== "handDrawn" && p.selectAll("path").attr("style", s), Z(t, p), t.intersect = function(d) {
    return R.info("filledCircle intersect", t, { radius: a, point: d }), j.circle(t, a, d);
  }, o;
}
f(gg, "filledCircle");
var Cc = 10, xc = 10;
async function mg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? s * 2 : s;
  (t.width || t.height) && (t.height = t?.height ?? 0, t.height < Cc && (t.height = Cc), t.width = (t?.width ?? 0) - o - o / 2, t.width < xc && (t.width = xc));
  const { shapeSvg: a, bbox: n, label: l } = await st(e, t, tt(t)), c = (t?.width ? t?.width : n.width) + (o ?? 0), h = t?.height ? t?.height : c + n.height, u = h, p = [
    { x: 0, y: -h },
    { x: u, y: -h },
    { x: u / 2, y: 0 }
  ], { cssStyles: d } = t, g = U.svg(a), m = X(t, {});
  t.look !== "handDrawn" && (m.roughness = 0, m.fillStyle = "solid");
  const y = pt(p), x = g.path(y, m), b = a.insert(() => x, ":first-child").attr("transform", `translate(${-h / 2}, ${h / 2})`).attr("class", "outer-path");
  return d && t.look !== "handDrawn" && b.selectChildren("path").attr("style", d), i && t.look !== "handDrawn" && b.selectChildren("path").attr("style", i), t.width = c, t.height = h, Z(t, b), l.attr(
    "transform",
    `translate(${-n.width / 2 - (n.x - (n.left ?? 0))}, ${-h / 2 + (t.padding ?? 0) / 2 + (n.y - (n.top ?? 0))})`
  ), t.intersect = function(k) {
    return R.info("Triangle intersect", t, p, k), j.polygon(t, p, k);
  }, a;
}
f(mg, "flippedTriangle");
function yg(e, t, { dir: r, config: { state: i, themeVariables: s } }) {
  const { nodeStyles: o } = V(t);
  t.label = "";
  const a = e.insert("g").attr("class", tt(t)).attr("id", t.domId ?? t.id), { cssStyles: n } = t;
  let l = Math.max(70, t?.width ?? 0), c = Math.max(10, t?.height ?? 0);
  r === "LR" && (l = Math.max(10, t?.width ?? 0), c = Math.max(70, t?.height ?? 0));
  const h = -1 * l / 2, u = -1 * c / 2, p = U.svg(a), d = X(t, {
    stroke: s.lineColor,
    fill: s.lineColor
  });
  t.look !== "handDrawn" && (d.roughness = 0, d.fillStyle = "solid");
  const g = p.rectangle(h, u, l, c, d), m = a.insert(() => g, ":first-child");
  n && t.look !== "handDrawn" && m.selectAll("path").attr("style", n), o && t.look !== "handDrawn" && m.selectAll("path").attr("style", o), Z(t, m);
  const y = i?.padding ?? 0;
  return t.width && t.height && (t.width += y / 2 || 0, t.height += y / 2 || 0), t.intersect = function(x) {
    return j.rect(t, x);
  }, a;
}
f(yg, "forkJoin");
async function Cg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const s = 15, o = 10, a = t.look === "neo" ? 16 : t.padding ?? 0, n = t.look === "neo" ? 12 : t.padding ?? 0;
  (t.width || t.height) && (t.height = (t?.height ?? 0) - n * 2, t.height < o && (t.height = o), t.width = (t?.width ?? 0) - a * 2, t.width < s && (t.width = s));
  const { shapeSvg: l, bbox: c } = await st(e, t, tt(t)), h = (t?.width ? t?.width : Math.max(s, c.width)) + a * 2, u = (t?.height ? t?.height : Math.max(o, c.height)) + n * 2, p = u / 2, { cssStyles: d } = t, g = U.svg(l), m = X(t, {});
  t.look !== "handDrawn" && (m.roughness = 0, m.fillStyle = "solid");
  const y = [
    { x: -h / 2, y: -u / 2 },
    { x: h / 2 - p, y: -u / 2 },
    ...Xi(-h / 2 + p, 0, p, 50, 90, 270),
    { x: h / 2 - p, y: u / 2 },
    { x: -h / 2, y: u / 2 }
  ], x = pt(y), b = g.path(x, m), k = l.insert(() => b, ":first-child");
  return k.attr("class", "basic label-container outer-path"), d && t.look !== "handDrawn" && k.selectChildren("path").attr("style", d), i && t.look !== "handDrawn" && k.selectChildren("path").attr("style", i), Z(t, k), t.intersect = function(w) {
    return R.info("Pill intersect", t, { radius: p, point: w }), j.polygon(t, y, w);
  }, l;
}
f(Cg, "halfRoundedRectangle");
var E_ = /* @__PURE__ */ f((e, t, r, i, s) => [
  `M${e + s},${t}`,
  `L${e + r - s},${t}`,
  `L${e + r},${t - i / 2}`,
  `L${e + r - s},${t - i}`,
  `L${e + s},${t - i}`,
  `L${e},${t - i / 2}`,
  "Z"
].join(" "), "createHexagonPathD");
async function xg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t), s = t.look === "neo" ? 3.5 : 4;
  t.labelStyle = r;
  const o = t.padding ?? 0, a = 70, n = 32, l = t.look === "neo" ? a : o, c = t.look === "neo" ? n : o;
  if (t.width || t.height) {
    const k = (t.height ?? 0) / s;
    t.width = (t?.width ?? 0) - 2 * k - c, t.height = (t.height ?? 0) - l;
  }
  const { shapeSvg: h, bbox: u } = await st(e, t, tt(t)), p = (t?.height ? t?.height : u.height) + l, d = p / s, g = (t?.width ? t?.width : u.width) + 2 * d + c, m = [
    { x: d, y: 0 },
    { x: g - d, y: 0 },
    { x: g, y: -p / 2 },
    { x: g - d, y: -p },
    { x: d, y: -p },
    { x: 0, y: -p / 2 }
  ];
  let y;
  const { cssStyles: x } = t;
  if (t.look === "handDrawn") {
    const b = U.svg(h), k = X(t, {}), w = E_(0, 0, g, p, d), S = b.path(w, k);
    y = h.insert(() => S, ":first-child").attr("transform", `translate(${-g / 2}, ${p / 2})`), x && y.attr("style", x);
  } else
    y = Xe(h, g, p, m);
  return i && y.attr("style", i), t.width = g, t.height = p, Z(t, y), t.intersect = function(b) {
    return j.polygon(t, m, b);
  }, h;
}
f(xg, "hexagon");
async function bg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.label = "", t.labelStyle = r;
  const { shapeSvg: s } = await st(e, t, tt(t)), o = Math.max(30, t?.width ?? 0), a = Math.max(30, t?.height ?? 0), { cssStyles: n } = t, l = U.svg(s), c = X(t, {});
  t.look !== "handDrawn" && (c.roughness = 0, c.fillStyle = "solid");
  const h = [
    { x: 0, y: 0 },
    { x: o, y: 0 },
    { x: 0, y: a },
    { x: o, y: a }
  ], u = pt(h), p = l.path(u, c), d = s.insert(() => p, ":first-child");
  return d.attr("class", "basic label-container outer-path"), n && t.look !== "handDrawn" && d.selectChildren("path").attr("style", n), i && t.look !== "handDrawn" && d.selectChildren("path").attr("style", i), d.attr("transform", `translate(${-o / 2}, ${-a / 2})`), Z(t, d), t.intersect = function(g) {
    return R.info("Pill intersect", t, { points: h }), j.polygon(t, h, g);
  }, s;
}
f(bg, "hourglass");
async function kg(e, t, { config: { themeVariables: r, flowchart: i } }) {
  const { labelStyles: s } = V(t);
  t.labelStyle = s;
  const o = t.assetHeight ?? 48, a = t.assetWidth ?? 48, n = Math.max(o, a), l = i?.wrappingWidth;
  t.width = Math.max(n, l ?? 0);
  const { shapeSvg: c, bbox: h, label: u } = await st(e, t, "icon-shape default"), p = t.pos === "t", d = n, g = n, { nodeBorder: m } = r, { stylesMap: y } = si(t), x = -g / 2, b = -d / 2, k = t.label ? 8 : 0, w = U.svg(c), S = X(t, { stroke: "none", fill: "none" });
  t.look !== "handDrawn" && (S.roughness = 0, S.fillStyle = "solid");
  const v = w.rectangle(x, b, g, d, S), M = Math.max(g, h.width), B = d + h.height + k, N = w.rectangle(-M / 2, -B / 2, M, B, {
    ...S,
    fill: "transparent",
    stroke: "none"
  }), D = c.insert(() => v, ":first-child"), O = c.insert(() => N);
  if (t.icon) {
    const W = c.append("g");
    W.html(
      `<g>${await os(t.icon, {
        height: n,
        width: n,
        fallbackPrefix: ""
      })}</g>`
    );
    const z = W.node().getBBox(), I = z.width, F = z.height, L = z.x, E = z.y;
    W.attr(
      "transform",
      `translate(${-I / 2 - L},${p ? h.height / 2 + k / 2 - F / 2 - E : -h.height / 2 - k / 2 - F / 2 - E})`
    ), W.attr("style", `color: ${y.get("stroke") ?? m};`);
  }
  return u.attr(
    "transform",
    `translate(${-h.width / 2 - (h.x - (h.left ?? 0))},${p ? -B / 2 : B / 2 - h.height})`
  ), D.attr(
    "transform",
    `translate(0,${p ? h.height / 2 + k / 2 : -h.height / 2 - k / 2})`
  ), Z(t, O), t.intersect = function(W) {
    if (R.info("iconSquare intersect", t, W), !t.label)
      return j.rect(t, W);
    const z = t.x ?? 0, I = t.y ?? 0, F = t.height ?? 0;
    let L = [];
    return p ? L = [
      { x: z - h.width / 2, y: I - F / 2 },
      { x: z + h.width / 2, y: I - F / 2 },
      { x: z + h.width / 2, y: I - F / 2 + h.height + k },
      { x: z + g / 2, y: I - F / 2 + h.height + k },
      { x: z + g / 2, y: I + F / 2 },
      { x: z - g / 2, y: I + F / 2 },
      { x: z - g / 2, y: I - F / 2 + h.height + k },
      { x: z - h.width / 2, y: I - F / 2 + h.height + k }
    ] : L = [
      { x: z - g / 2, y: I - F / 2 },
      { x: z + g / 2, y: I - F / 2 },
      { x: z + g / 2, y: I - F / 2 + d },
      { x: z + h.width / 2, y: I - F / 2 + d },
      { x: z + h.width / 2 / 2, y: I + F / 2 },
      { x: z - h.width / 2, y: I + F / 2 },
      { x: z - h.width / 2, y: I - F / 2 + d },
      { x: z - g / 2, y: I - F / 2 + d }
    ], j.polygon(t, L, W);
  }, c;
}
f(kg, "icon");
async function Tg(e, t, { config: { themeVariables: r, flowchart: i } }) {
  const { labelStyles: s } = V(t);
  t.labelStyle = s;
  const o = t.assetHeight ?? 48, a = t.assetWidth ?? 48, n = Math.max(o, a), l = i?.wrappingWidth;
  t.width = Math.max(n, l ?? 0);
  const { shapeSvg: c, bbox: h, label: u } = await st(e, t, "icon-shape default"), p = 20, d = t.label ? 8 : 0, g = t.pos === "t", { nodeBorder: m, mainBkg: y } = r, { stylesMap: x } = si(t), b = U.svg(c), k = X(t, {});
  t.look !== "handDrawn" && (k.roughness = 0, k.fillStyle = "solid");
  const w = x.get("fill");
  k.stroke = w ?? y;
  const S = c.append("g");
  t.icon && S.html(
    `<g>${await os(t.icon, {
      height: n,
      width: n,
      fallbackPrefix: ""
    })}</g>`
  );
  const v = S.node().getBBox(), M = v.width, B = v.height, N = v.x, D = v.y, O = Math.max(M, B) * Math.SQRT2 + p * 2, W = b.circle(0, 0, O, k), z = Math.max(O, h.width), I = O + h.height + d, F = b.rectangle(-z / 2, -I / 2, z, I, {
    ...k,
    fill: "transparent",
    stroke: "none"
  }), L = c.insert(() => W, ":first-child"), E = c.insert(() => F);
  return S.attr(
    "transform",
    `translate(${-M / 2 - N},${g ? h.height / 2 + d / 2 - B / 2 - D : -h.height / 2 - d / 2 - B / 2 - D})`
  ), S.attr("style", `color: ${x.get("stroke") ?? m};`), u.attr(
    "transform",
    `translate(${-h.width / 2 - (h.x - (h.left ?? 0))},${g ? -I / 2 : I / 2 - h.height})`
  ), L.attr(
    "transform",
    `translate(0,${g ? h.height / 2 + d / 2 : -h.height / 2 - d / 2})`
  ), Z(t, E), t.intersect = function(P) {
    return R.info("iconSquare intersect", t, P), j.rect(t, P);
  }, c;
}
f(Tg, "iconCircle");
async function wg(e, t, { config: { themeVariables: r, flowchart: i } }) {
  const { labelStyles: s } = V(t);
  t.labelStyle = s;
  const o = t.assetHeight ?? 48, a = t.assetWidth ?? 48, n = Math.max(o, a), l = i?.wrappingWidth;
  t.width = Math.max(n, l ?? 0);
  const { shapeSvg: c, bbox: h, halfPadding: u, label: p } = await st(
    e,
    t,
    "icon-shape default"
  ), d = t.pos === "t", g = n + u * 2, m = n + u * 2, { nodeBorder: y, mainBkg: x } = r, { stylesMap: b } = si(t), k = -m / 2, w = -g / 2, S = t.label ? 8 : 0, v = U.svg(c), M = X(t, {});
  t.look !== "handDrawn" && (M.roughness = 0, M.fillStyle = "solid");
  const B = b.get("fill");
  M.stroke = B ?? x;
  const N = v.path(ar(k, w, m, g, 5), M), D = Math.max(m, h.width), O = g + h.height + S, W = v.rectangle(-D / 2, -O / 2, D, O, {
    ...M,
    fill: "transparent",
    stroke: "none"
  }), z = c.insert(() => N, ":first-child").attr("class", "icon-shape2"), I = c.insert(() => W);
  if (t.icon) {
    const F = c.append("g");
    F.html(
      `<g>${await os(t.icon, {
        height: n,
        width: n,
        fallbackPrefix: ""
      })}</g>`
    );
    const L = F.node().getBBox(), E = L.width, P = L.height, H = L.x, Y = L.y;
    F.attr(
      "transform",
      `translate(${-E / 2 - H},${d ? h.height / 2 + S / 2 - P / 2 - Y : -h.height / 2 - S / 2 - P / 2 - Y})`
    ), F.attr("style", `color: ${b.get("stroke") ?? y};`);
  }
  return p.attr(
    "transform",
    `translate(${-h.width / 2 - (h.x - (h.left ?? 0))},${d ? -O / 2 : O / 2 - h.height})`
  ), z.attr(
    "transform",
    `translate(0,${d ? h.height / 2 + S / 2 : -h.height / 2 - S / 2})`
  ), Z(t, I), t.intersect = function(F) {
    if (R.info("iconSquare intersect", t, F), !t.label)
      return j.rect(t, F);
    const L = t.x ?? 0, E = t.y ?? 0, P = t.height ?? 0;
    let H = [];
    return d ? H = [
      { x: L - h.width / 2, y: E - P / 2 },
      { x: L + h.width / 2, y: E - P / 2 },
      { x: L + h.width / 2, y: E - P / 2 + h.height + S },
      { x: L + m / 2, y: E - P / 2 + h.height + S },
      { x: L + m / 2, y: E + P / 2 },
      { x: L - m / 2, y: E + P / 2 },
      { x: L - m / 2, y: E - P / 2 + h.height + S },
      { x: L - h.width / 2, y: E - P / 2 + h.height + S }
    ] : H = [
      { x: L - m / 2, y: E - P / 2 },
      { x: L + m / 2, y: E - P / 2 },
      { x: L + m / 2, y: E - P / 2 + g },
      { x: L + h.width / 2, y: E - P / 2 + g },
      { x: L + h.width / 2 / 2, y: E + P / 2 },
      { x: L - h.width / 2, y: E + P / 2 },
      { x: L - h.width / 2, y: E - P / 2 + g },
      { x: L - m / 2, y: E - P / 2 + g }
    ], j.polygon(t, H, F);
  }, c;
}
f(wg, "iconRounded");
async function Sg(e, t, { config: { themeVariables: r, flowchart: i } }) {
  const { labelStyles: s } = V(t);
  t.labelStyle = s;
  const o = t.assetHeight ?? 48, a = t.assetWidth ?? 48, n = Math.max(o, a), l = i?.wrappingWidth;
  t.width = Math.max(n, l ?? 0);
  const { shapeSvg: c, bbox: h, halfPadding: u, label: p } = await st(
    e,
    t,
    "icon-shape default"
  ), d = t.pos === "t", g = n + u * 2, m = n + u * 2, { nodeBorder: y, mainBkg: x } = r, { stylesMap: b } = si(t), k = -m / 2, w = -g / 2, S = t.label ? 8 : 0, v = U.svg(c), M = X(t, {});
  t.look !== "handDrawn" && (M.roughness = 0, M.fillStyle = "solid");
  const B = b.get("fill");
  M.stroke = B ?? x;
  const N = v.path(ar(k, w, m, g, 0.1), M), D = Math.max(m, h.width), O = g + h.height + S, W = v.rectangle(-D / 2, -O / 2, D, O, {
    ...M,
    fill: "transparent",
    stroke: "none"
  }), z = c.insert(() => N, ":first-child"), I = c.insert(() => W);
  if (t.icon) {
    const F = c.append("g");
    F.html(
      `<g>${await os(t.icon, {
        height: n,
        width: n,
        fallbackPrefix: ""
      })}</g>`
    );
    const L = F.node().getBBox(), E = L.width, P = L.height, H = L.x, Y = L.y;
    F.attr(
      "transform",
      `translate(${-E / 2 - H},${d ? h.height / 2 + S / 2 - P / 2 - Y : -h.height / 2 - S / 2 - P / 2 - Y})`
    ), F.attr("style", `color: ${b.get("stroke") ?? y};`);
  }
  return p.attr(
    "transform",
    `translate(${-h.width / 2 - (h.x - (h.left ?? 0))},${d ? -O / 2 : O / 2 - h.height})`
  ), z.attr(
    "transform",
    `translate(0,${d ? h.height / 2 + S / 2 : -h.height / 2 - S / 2})`
  ), Z(t, I), t.intersect = function(F) {
    if (R.info("iconSquare intersect", t, F), !t.label)
      return j.rect(t, F);
    const L = t.x ?? 0, E = t.y ?? 0, P = t.height ?? 0;
    let H = [];
    return d ? H = [
      { x: L - h.width / 2, y: E - P / 2 },
      { x: L + h.width / 2, y: E - P / 2 },
      { x: L + h.width / 2, y: E - P / 2 + h.height + S },
      { x: L + m / 2, y: E - P / 2 + h.height + S },
      { x: L + m / 2, y: E + P / 2 },
      { x: L - m / 2, y: E + P / 2 },
      { x: L - m / 2, y: E - P / 2 + h.height + S },
      { x: L - h.width / 2, y: E - P / 2 + h.height + S }
    ] : H = [
      { x: L - m / 2, y: E - P / 2 },
      { x: L + m / 2, y: E - P / 2 },
      { x: L + m / 2, y: E - P / 2 + g },
      { x: L + h.width / 2, y: E - P / 2 + g },
      { x: L + h.width / 2 / 2, y: E + P / 2 },
      { x: L - h.width / 2, y: E + P / 2 },
      { x: L - h.width / 2, y: E - P / 2 + g },
      { x: L - m / 2, y: E - P / 2 + g }
    ], j.polygon(t, H, F);
  }, c;
}
f(Sg, "iconSquare");
async function _g(e, t, { config: { flowchart: r } }) {
  const i = new Image();
  i.src = t?.img ?? "", await i.decode();
  const s = Number(i.naturalWidth.toString().replace("px", "")), o = Number(i.naturalHeight.toString().replace("px", ""));
  t.imageAspectRatio = s / o;
  const { labelStyles: a } = V(t);
  t.labelStyle = a;
  const n = r?.wrappingWidth;
  t.defaultWidth = r?.wrappingWidth;
  const l = Math.max(
    t.label ? n ?? 0 : 0,
    t?.assetWidth ?? s
  ), c = t.constraint === "on" && t?.assetHeight ? t.assetHeight * t.imageAspectRatio : l, h = t.constraint === "on" ? c / t.imageAspectRatio : t?.assetHeight ?? o;
  t.width = Math.max(c, n ?? 0);
  const { shapeSvg: u, bbox: p, label: d } = await st(e, t, "image-shape default"), g = t.pos === "t", m = -c / 2, y = -h / 2, x = t.label ? 8 : 0, b = U.svg(u), k = X(t, {});
  t.look !== "handDrawn" && (k.roughness = 0, k.fillStyle = "solid");
  const w = b.rectangle(m, y, c, h, k), S = Math.max(c, p.width), v = h + p.height + x, M = b.rectangle(-S / 2, -v / 2, S, v, {
    ...k,
    fill: "none",
    stroke: "none"
  }), B = u.insert(() => w, ":first-child"), N = u.insert(() => M);
  if (t.img) {
    const D = u.append("image");
    D.attr("href", t.img), D.attr("width", c), D.attr("height", h), D.attr("preserveAspectRatio", "none"), D.attr(
      "transform",
      `translate(${-c / 2},${g ? v / 2 - h : -v / 2})`
    );
  }
  return d.attr(
    "transform",
    `translate(${-p.width / 2 - (p.x - (p.left ?? 0))},${g ? -h / 2 - p.height / 2 - x / 2 : h / 2 - p.height / 2 + x / 2})`
  ), B.attr(
    "transform",
    `translate(0,${g ? p.height / 2 + x / 2 : -p.height / 2 - x / 2})`
  ), Z(t, N), t.intersect = function(D) {
    if (R.info("iconSquare intersect", t, D), !t.label)
      return j.rect(t, D);
    const O = t.x ?? 0, W = t.y ?? 0, z = t.height ?? 0;
    let I = [];
    return g ? I = [
      { x: O - p.width / 2, y: W - z / 2 },
      { x: O + p.width / 2, y: W - z / 2 },
      { x: O + p.width / 2, y: W - z / 2 + p.height + x },
      { x: O + c / 2, y: W - z / 2 + p.height + x },
      { x: O + c / 2, y: W + z / 2 },
      { x: O - c / 2, y: W + z / 2 },
      { x: O - c / 2, y: W - z / 2 + p.height + x },
      { x: O - p.width / 2, y: W - z / 2 + p.height + x }
    ] : I = [
      { x: O - c / 2, y: W - z / 2 },
      { x: O + c / 2, y: W - z / 2 },
      { x: O + c / 2, y: W - z / 2 + h },
      { x: O + p.width / 2, y: W - z / 2 + h },
      { x: O + p.width / 2 / 2, y: W + z / 2 },
      { x: O - p.width / 2, y: W + z / 2 },
      { x: O - p.width / 2, y: W - z / 2 + h },
      { x: O - c / 2, y: W - z / 2 + h }
    ], j.polygon(t, I, D);
  }, u;
}
f(_g, "imageSquare");
async function vg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = s, a = t.look === "neo" ? s * 2 : s, { shapeSvg: n, bbox: l } = await st(e, t, tt(t)), c = Math.max(l.width + (a ?? 0) * 2, t?.width ?? 0), h = Math.max(l.height + (o ?? 0) * 2, t?.height ?? 0), u = [
    { x: 0, y: 0 },
    { x: c, y: 0 },
    { x: c + 3 * h / 6, y: -h },
    { x: -3 * h / 6, y: -h }
  ];
  let p;
  const { cssStyles: d } = t;
  if (t.look === "handDrawn") {
    const g = U.svg(n), m = X(t, {}), y = pt(u), x = g.path(y, m);
    p = n.insert(() => x, ":first-child").attr("transform", `translate(${-c / 2}, ${h / 2})`), d && p.attr("style", d);
  } else
    p = Xe(n, c, h, u);
  return i && p.attr("style", i), t.width = c, t.height = h, Z(t, p), t.intersect = function(g) {
    return j.polygon(t, u, g);
  }, n;
}
f(vg, "inv_trapezoid");
async function ns(e, t, r) {
  const { labelStyles: i, nodeStyles: s } = V(t);
  t.labelStyle = i;
  const { shapeSvg: o, bbox: a } = await st(e, t, tt(t)), n = Math.max(a.width + r.labelPaddingX * 2, t?.width || 0), l = Math.max(a.height + r.labelPaddingY * 2, t?.height || 0), c = -n / 2, h = -l / 2;
  let u, { rx: p, ry: d } = t;
  const { cssStyles: g } = t;
  if (r?.rx && r.ry && (p = r.rx, d = r.ry), t.look === "handDrawn") {
    const m = U.svg(o), y = X(t, {}), x = p || d ? m.path(ar(c, h, n, l, p || 0), y) : m.rectangle(c, h, n, l, y);
    u = o.insert(() => x, ":first-child"), u.attr("class", "basic label-container").attr("style", Dt(g));
  } else
    u = o.insert("rect", ":first-child"), u.attr("class", "basic label-container").attr("style", s).attr("rx", Dt(p)).attr("ry", Dt(d)).attr("x", c).attr("y", h).attr("width", n).attr("height", l);
  return Z(t, u), t.calcIntersect = function(m, y) {
    return j.rect(m, y);
  }, t.intersect = function(m) {
    return j.rect(t, m);
  }, o;
}
f(ns, "drawRect");
async function Bg(e, t) {
  const { shapeSvg: r, bbox: i, label: s } = await st(e, t, "label"), o = r.insert("rect", ":first-child");
  return o.attr("width", 0.1).attr("height", 0.1), r.attr("class", "label edgeLabel"), s.attr(
    "transform",
    `translate(${-(i.width / 2) - (i.x - (i.left ?? 0))}, ${-(i.height / 2) - (i.y - (i.top ?? 0))})`
  ), Z(t, o), t.intersect = function(l) {
    return j.rect(t, l);
  }, r;
}
f(Bg, "labelRect");
async function Lg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = s, a = t.look === "neo" ? s * 2 : s, { shapeSvg: n, bbox: l } = await st(e, t, tt(t)), c = (t?.height ?? l.height) + o, h = (t?.width ?? l.width) + a, u = [
    { x: 0, y: 0 },
    { x: h + 3 * c / 6, y: 0 },
    { x: h, y: -c },
    { x: -(3 * c) / 6, y: -c }
  ];
  let p;
  const { cssStyles: d } = t;
  if (t.look === "handDrawn") {
    const g = U.svg(n), m = X(t, {}), y = pt(u), x = g.path(y, m);
    p = n.insert(() => x, ":first-child").attr("transform", `translate(${-h / 2}, ${c / 2})`), d && p.attr("style", d);
  } else
    p = Xe(n, h, c, u);
  return i && p.attr("style", i), t.width = h, t.height = c, Z(t, p), t.intersect = function(g) {
    return j.polygon(t, u, g);
  }, n;
}
f(Lg, "lean_left");
async function Fg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = s, a = t.look === "neo" ? s * 2 : s, { shapeSvg: n, bbox: l } = await st(e, t, tt(t)), c = (t?.height ?? l.height) + o, h = (t?.width ?? l.width) + a, u = [
    { x: -3 * c / 6, y: 0 },
    { x: h, y: 0 },
    { x: h + 3 * c / 6, y: -c },
    { x: 0, y: -c }
  ];
  let p;
  const { cssStyles: d } = t;
  if (t.look === "handDrawn") {
    const g = U.svg(n), m = X(t, {}), y = pt(u), x = g.path(y, m);
    p = n.insert(() => x, ":first-child").attr("transform", `translate(${-h / 2}, ${c / 2})`), d && p.attr("style", d);
  } else
    p = Xe(n, h, c, u);
  return i && p.attr("style", i), t.width = h, t.height = c, Z(t, p), t.intersect = function(g) {
    return j.polygon(t, u, g);
  }, n;
}
f(Fg, "lean_right");
function Ag(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.label = "", t.labelStyle = r;
  const s = e.insert("g").attr("class", tt(t)).attr("id", t.domId ?? t.id), { cssStyles: o } = t, a = Math.max(35, t?.width ?? 0), n = Math.max(35, t?.height ?? 0), l = 7, c = [
    { x: a, y: 0 },
    { x: 0, y: n + l / 2 },
    { x: a - 2 * l, y: n + l / 2 },
    { x: 0, y: 2 * n },
    { x: a, y: n - l / 2 },
    { x: 2 * l, y: n - l / 2 }
  ], h = U.svg(s), u = X(t, {});
  t.look !== "handDrawn" && (u.roughness = 0, u.fillStyle = "solid");
  const p = pt(c), d = h.path(p, u), g = s.insert(() => d, ":first-child");
  return g.attr("class", "outer-path"), o && t.look !== "handDrawn" && g.selectAll("path").attr("style", o), i && t.look !== "handDrawn" && g.selectAll("path").attr("style", i), g.attr("transform", `translate(-${a / 2},${-n})`), Z(t, g), t.intersect = function(m) {
    return R.info("lightningBolt intersect", t, m), j.polygon(t, c, m);
  }, s;
}
f(Ag, "lightningBolt");
var $_ = /* @__PURE__ */ f((e, t, r, i, s, o, a) => [
  `M${e},${t + o}`,
  `a${s},${o} 0,0,0 ${r},0`,
  `a${s},${o} 0,0,0 ${-r},0`,
  `l0,${i}`,
  `a${s},${o} 0,0,0 ${r},0`,
  `l0,${-i}`,
  `M${e},${t + o + a}`,
  `a${s},${o} 0,0,0 ${r},0`
].join(" "), "createCylinderPathD"), O_ = /* @__PURE__ */ f((e, t, r, i, s, o, a) => [
  `M${e},${t + o}`,
  `M${e + r},${t + o}`,
  `a${s},${o} 0,0,0 ${-r},0`,
  `l0,${i}`,
  `a${s},${o} 0,0,0 ${r},0`,
  `l0,${-i}`,
  `M${e},${t + o + a}`,
  `a${s},${o} 0,0,0 ${r},0`
].join(" "), "createOuterCylinderPathD"), I_ = /* @__PURE__ */ f((e, t, r, i, s, o) => [`M${e - r / 2},${-i / 2}`, `a${s},${o} 0,0,0 ${r},0`].join(" "), "createInnerCylinderPathD"), bc = 10, kc = 10;
async function Mg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 16 : s, a = t.look === "neo" ? 24 : s;
  if (t.width || t.height) {
    const x = t.width ?? 0;
    t.width = (t.width ?? 0) - o, t.width < kc && (t.width = kc);
    const k = x / 2 / (2.5 + x / 50);
    t.height = (t.height ?? 0) - a - k * 3, t.height < bc && (t.height = bc);
  }
  const { shapeSvg: n, bbox: l, label: c } = await st(e, t, tt(t)), h = (t?.width ? t?.width : l.width) + o * 2, u = h / 2, p = u / (2.5 + h / 50), d = (t?.height ? t?.height : l.height) + p + a * 2, g = d * 0.1;
  let m;
  const { cssStyles: y } = t;
  if (t.look === "handDrawn") {
    const x = U.svg(n), b = O_(0, 0, h, d, u, p, g), k = I_(0, p, h, d, u, p), w = X(t, {}), S = x.path(b, w), v = x.path(k, w);
    n.insert(() => v, ":first-child").attr("class", "line"), m = n.insert(() => S, ":first-child"), m.attr("class", "basic label-container"), y && m.attr("style", y);
  } else {
    const x = $_(0, 0, h, d, u, p, g);
    m = n.insert("path", ":first-child").attr("d", x).attr("class", "basic label-container outer-path").attr("style", Dt(y)).attr("style", i);
  }
  return m.attr("label-offset-y", p), m.attr("transform", `translate(${-h / 2}, ${-(d / 2 + p)})`), Z(t, m), c.attr(
    "transform",
    `translate(${-(l.width / 2) - (l.x - (l.left ?? 0))}, ${-(l.height / 2) + p - (l.y - (l.top ?? 0))})`
  ), t.intersect = function(x) {
    const b = j.rect(t, x), k = b.x - (t.x ?? 0);
    if (u != 0 && (Math.abs(k) < (t.width ?? 0) / 2 || Math.abs(k) == (t.width ?? 0) / 2 && Math.abs(b.y - (t.y ?? 0)) > (t.height ?? 0) / 2 - p)) {
      let w = p * p * (1 - k * k / (u * u));
      w > 0 && (w = Math.sqrt(w)), w = p - w, x.y - (t.y ?? 0) > 0 && (w = -w), b.y += w;
    }
    return b;
  }, n;
}
f(Mg, "linedCylinder");
async function Eg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 16 : s, a = t.look === "neo" ? 12 : s;
  if (t.width || t.height) {
    const w = t.width;
    t.width = (w ?? 0) * 10 / 11 - o * 2, t.width < 10 && (t.width = 10), t.height = (t?.height ?? 0) - a * 2, t.height < 10 && (t.height = 10);
  }
  const { shapeSvg: n, bbox: l, label: c } = await st(e, t, tt(t)), h = (t?.width ? t?.width : l.width) + (o ?? 0) * 2, u = (t?.height ? t?.height : l.height) + (a ?? 0) * 2, p = t.look === "neo" ? u / 4 : u / 8, d = u + p, { cssStyles: g } = t, m = U.svg(n), y = X(t, {});
  t.look !== "handDrawn" && (y.roughness = 0, y.fillStyle = "solid");
  const x = [
    { x: -h / 2 - h / 2 * 0.1, y: -d / 2 },
    { x: -h / 2 - h / 2 * 0.1, y: d / 2 },
    ...sr(
      -h / 2 - h / 2 * 0.1,
      d / 2,
      h / 2 + h / 2 * 0.1,
      d / 2,
      p,
      0.8
    ),
    { x: h / 2 + h / 2 * 0.1, y: -d / 2 },
    { x: -h / 2 - h / 2 * 0.1, y: -d / 2 },
    { x: -h / 2, y: -d / 2 },
    { x: -h / 2, y: d / 2 * 1.1 },
    { x: -h / 2, y: -d / 2 }
  ], b = m.polygon(
    x.map((w) => [w.x, w.y]),
    y
  ), k = n.insert(() => b, ":first-child");
  return k.attr("class", "basic label-container outer-path"), g && t.look !== "handDrawn" && k.selectAll("path").attr("style", g), i && t.look !== "handDrawn" && k.selectAll("path").attr("style", i), k.attr("transform", `translate(0,${-p / 2})`), c.attr(
    "transform",
    `translate(${-h / 2 + (t.padding ?? 0) + h / 2 * 0.1 / 2 - (l.x - (l.left ?? 0))},${-u / 2 + (t.padding ?? 0) - p / 2 - (l.y - (l.top ?? 0))})`
  ), Z(t, k), t.intersect = function(w) {
    return j.polygon(t, x, w);
  }, n;
}
f(Eg, "linedWaveEdgedRect");
async function $g(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 16 : s, a = t.look === "neo" ? 12 : s, n = t.look === "neo" ? 10 : 5;
  (t.width || t.height) && (t.width = Math.max((t?.width ?? 0) - o * 2 - 2 * n, 10), t.height = Math.max((t?.height ?? 0) - a * 2 - 2 * n, 10));
  const { shapeSvg: l, bbox: c, label: h } = await st(e, t, tt(t)), u = (t?.width ? t?.width : c.width) + o * 2 + 2 * n, p = (t?.height ? t?.height : c.height) + a * 2 + 2 * n, d = u - 2 * n, g = p - 2 * n, m = -d / 2, y = -g / 2, { cssStyles: x } = t, b = U.svg(l), k = X(t, {}), w = [
    { x: m - n, y: y + n },
    { x: m - n, y: y + g + n },
    { x: m + d - n, y: y + g + n },
    { x: m + d - n, y: y + g },
    { x: m + d, y: y + g },
    { x: m + d, y: y + g - n },
    { x: m + d + n, y: y + g - n },
    { x: m + d + n, y: y - n },
    { x: m + n, y: y - n },
    { x: m + n, y },
    { x: m, y },
    { x: m, y: y + n }
  ], S = [
    { x: m, y: y + n },
    { x: m + d - n, y: y + n },
    { x: m + d - n, y: y + g },
    { x: m + d, y: y + g },
    { x: m + d, y },
    { x: m, y }
  ];
  t.look !== "handDrawn" && (k.roughness = 0, k.fillStyle = "solid");
  const v = pt(w);
  let M = b.path(v, k);
  const B = pt(S);
  let N = b.path(B, k);
  t.look !== "handDrawn" && (M = pn(M), N = pn(N));
  const D = l.insert("g", ":first-child");
  return D.insert(() => M), D.insert(() => N), D.attr("class", "basic label-container outer-path"), x && t.look !== "handDrawn" && D.selectAll("path").attr("style", x), i && t.look !== "handDrawn" && D.selectAll("path").attr("style", i), h.attr(
    "transform",
    `translate(${-(c.width / 2) - n - (c.x - (c.left ?? 0))}, ${-(c.height / 2) + n - (c.y - (c.top ?? 0))})`
  ), Z(t, D), t.intersect = function(O) {
    return j.polygon(t, w, O);
  }, l;
}
f($g, "multiRect");
async function Og(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const { shapeSvg: s, bbox: o, label: a } = await st(e, t, tt(t)), n = t.padding ?? 0, l = t.look === "neo" ? 16 : n, c = t.look === "neo" ? 12 : n;
  let h = !0;
  (t.width || t.height) && (h = !1, t.width = (t?.width ?? 0) - l * 2, t.height = (t?.height ?? 0) - c * 3);
  const u = Math.max(o.width, t?.width ?? 0) + l * 2, p = Math.max(o.height, t?.height ?? 0) + c * 3, d = t.look === "neo" ? p / 4 : p / 8, g = p + (h ? d / 2 : -d / 2), m = -u / 2, y = -g / 2, x = 10, { cssStyles: b } = t, k = sr(
    m - x,
    y + g + x,
    m + u - x,
    y + g + x,
    d,
    0.8
  ), w = k?.[k.length - 1], S = [
    { x: m - x, y: y + x },
    { x: m - x, y: y + g + x },
    ...k,
    { x: m + u - x, y: w.y - x },
    { x: m + u, y: w.y - x },
    { x: m + u, y: w.y - 2 * x },
    { x: m + u + x, y: w.y - 2 * x },
    { x: m + u + x, y: y - x },
    { x: m + x, y: y - x },
    { x: m + x, y },
    { x: m, y },
    { x: m, y: y + x }
  ], v = [
    { x: m, y: y + x },
    { x: m + u - x, y: y + x },
    { x: m + u - x, y: w.y - x },
    { x: m + u, y: w.y - x },
    { x: m + u, y },
    { x: m, y }
  ], M = U.svg(s), B = X(t, {});
  t.look !== "handDrawn" && (B.roughness = 0, B.fillStyle = "solid");
  const N = pt(S), D = M.path(N, B), O = pt(v), W = M.path(O, B), z = s.insert(() => D, ":first-child");
  return z.insert(() => W), z.attr("class", "basic label-container outer-path"), b && t.look !== "handDrawn" && z.selectAll("path").attr("style", b), i && t.look !== "handDrawn" && z.selectAll("path").attr("style", i), z.attr("transform", `translate(0,${-d / 2})`), a.attr(
    "transform",
    `translate(${-(o.width / 2) - x - (o.x - (o.left ?? 0))}, ${-(o.height / 2) + x - d / 2 - (o.y - (o.top ?? 0))})`
  ), Z(t, z), t.intersect = function(I) {
    return j.polygon(t, S, I);
  }, s;
}
f(Og, "multiWaveEdgedRectangle");
async function Ig(e, t, { config: { themeVariables: r } }) {
  const { labelStyles: i, nodeStyles: s } = V(t);
  t.labelStyle = i, t.useHtmlLabels || Vt(wt()) || (t.centerLabel = !0);
  const { shapeSvg: a, bbox: n, label: l } = await st(e, t, tt(t)), c = Math.max(n.width + (t.padding ?? 0) * 2, t?.width ?? 0), h = Math.max(n.height + (t.padding ?? 0) * 2, t?.height ?? 0), u = -c / 2, p = -h / 2, { cssStyles: d } = t, g = U.svg(a), m = X(t, {
    fill: r.noteBkgColor,
    stroke: r.noteBorderColor
  });
  t.look !== "handDrawn" && (m.roughness = 0, m.fillStyle = "solid");
  const y = g.rectangle(u, p, c, h, m), x = a.insert(() => y, ":first-child");
  return x.attr("class", "basic label-container outer-path"), l.attr("class", "label noteLabel"), d && t.look !== "handDrawn" && x.selectAll("path").attr("style", d), s && t.look !== "handDrawn" && x.selectAll("path").attr("style", s), l.attr(
    "transform",
    `translate(${-n.width / 2 - (n.x - (n.left ?? 0))}, ${-(n.height / 2) - (n.y - (n.top ?? 0))})`
  ), Z(t, x), t.intersect = function(b) {
    return j.rect(t, b);
  }, a;
}
f(Ig, "note");
var D_ = /* @__PURE__ */ f((e, t, r) => [
  `M${e + r / 2},${t}`,
  `L${e + r},${t - r / 2}`,
  `L${e + r / 2},${t - r}`,
  `L${e},${t - r / 2}`,
  "Z"
].join(" "), "createDecisionBoxPathD");
async function Dg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const { shapeSvg: s, bbox: o } = await st(e, t, tt(t)), a = o.width + (t.padding ?? 0), n = o.height + (t.padding ?? 0), l = a + n, c = 0.5, h = [
    { x: l / 2, y: 0 },
    { x: l, y: -l / 2 },
    { x: l / 2, y: -l },
    { x: 0, y: -l / 2 }
  ];
  let u;
  const { cssStyles: p } = t;
  if (t.look === "handDrawn") {
    const d = U.svg(s), g = X(t, {}), m = D_(0, 0, l), y = d.path(m, g);
    u = s.insert(() => y, ":first-child").attr("transform", `translate(${-l / 2 + c}, ${l / 2})`), p && u.attr("style", p);
  } else
    u = Xe(s, l, l, h), u.attr("transform", `translate(${-l / 2 + c}, ${l / 2})`);
  return i && u.attr("style", i), Z(t, u), t.calcIntersect = function(d, g) {
    const m = d.width, y = [
      { x: m / 2, y: 0 },
      { x: m, y: -m / 2 },
      { x: m / 2, y: -m },
      { x: 0, y: -m / 2 }
    ], x = j.polygon(d, y, g);
    return { x: x.x - 0.5, y: x.y - 0.5 };
  }, t.intersect = function(d) {
    return this.calcIntersect(t, d);
  }, s;
}
f(Dg, "question");
async function Pg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 21 : s ?? 0, a = t.look === "neo" ? 12 : s ?? 0, { shapeSvg: n, bbox: l, label: c } = await st(e, t, tt(t)), h = (t?.width ?? l.width) + (t.look === "neo" ? o * 2 : o), u = (t?.height ?? l.height) + (t.look === "neo" ? a * 2 : a), p = -h / 2, d = -u / 2, g = d / 2, m = [
    { x: p + g, y: d },
    { x: p, y: 0 },
    { x: p + g, y: -d },
    { x: -p, y: -d },
    { x: -p, y: d }
  ], { cssStyles: y } = t, x = U.svg(n), b = X(t, {});
  t.look !== "handDrawn" && (b.roughness = 0, b.fillStyle = "solid");
  const k = pt(m), w = x.path(k, b), S = n.insert(() => w, ":first-child");
  return S.attr("class", "basic label-container outer-path"), y && t.look !== "handDrawn" && S.selectAll("path").attr("style", y), i && t.look !== "handDrawn" && S.selectAll("path").attr("style", i), S.attr("transform", `translate(${-g / 2},0)`), c.attr(
    "transform",
    `translate(${-g / 2 - l.width / 2 - (l.x - (l.left ?? 0))}, ${-(l.height / 2) - (l.y - (l.top ?? 0))})`
  ), Z(t, S), t.intersect = function(v) {
    return j.polygon(t, m, v);
  }, n;
}
f(Pg, "rect_left_inv_arrow");
async function Rg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  let s;
  t.cssClasses ? s = "node " + t.cssClasses : s = "node default";
  const o = e.insert("g").attr("class", s).attr("id", t.domId || t.id), a = o.insert("g"), n = o.insert("g").attr("class", "label").attr("style", i), l = t.description, c = t.label, h = await Ke(n, c, t.labelStyle, !0, !0);
  let u = { width: 0, height: 0 };
  if (Vt(gt())) {
    const B = h.children[0], N = ct(h);
    u = B.getBoundingClientRect(), N.attr("width", u.width), N.attr("height", u.height);
  }
  R.info("Text 2", l);
  const p = l || [], d = h.getBBox(), g = await Ke(
    n,
    Array.isArray(p) ? p.join("<br/>") : p,
    t.labelStyle,
    !0,
    !0
  ), m = g.children[0], y = ct(g);
  u = m.getBoundingClientRect(), y.attr("width", u.width), y.attr("height", u.height);
  const x = (t.padding || 0) / 2;
  ct(g).attr(
    "transform",
    "translate( " + (u.width > d.width ? 0 : (d.width - u.width) / 2) + ", " + (d.height + x + 5) + ")"
  ), ct(h).attr(
    "transform",
    "translate( " + (u.width < d.width ? 0 : -(d.width - u.width) / 2) + ", 0)"
  ), u = n.node().getBBox(), n.attr(
    "transform",
    "translate(" + -u.width / 2 + ", " + (-u.height / 2 - x + 3) + ")"
  );
  const b = u.width + (t.padding || 0), k = u.height + (t.padding || 0), w = -u.width / 2 - x, S = -u.height / 2 - x;
  let v, M;
  if (t.look === "handDrawn") {
    const B = U.svg(o), N = X(t, {}), D = B.path(
      ar(w, S, b, k, t.rx || 0),
      N
    ), O = B.line(
      -u.width / 2 - x,
      -u.height / 2 - x + d.height + x,
      u.width / 2 + x,
      -u.height / 2 - x + d.height + x,
      N
    );
    M = o.insert(() => (R.debug("Rough node insert CXC", D), O), ":first-child"), v = o.insert(() => (R.debug("Rough node insert CXC", D), D), ":first-child");
  } else
    v = a.insert("rect", ":first-child"), M = a.insert("line"), v.attr("class", "outer title-state").attr("style", i).attr("x", -u.width / 2 - x).attr("y", -u.height / 2 - x).attr("width", u.width + (t.padding || 0)).attr("height", u.height + (t.padding || 0)), M.attr("class", "divider").attr("x1", -u.width / 2 - x).attr("x2", u.width / 2 + x).attr("y1", -u.height / 2 - x + d.height + x).attr("y2", -u.height / 2 - x + d.height + x);
  return Z(t, v), t.intersect = function(B) {
    return j.rect(t, B);
  }, o;
}
f(Rg, "rectWithTitle");
async function Ng(e, t, { config: { themeVariables: r } }) {
  const i = r?.radius ?? 5, s = {
    rx: i,
    ry: i,
    labelPaddingX: (t?.padding ?? 0) * 1,
    labelPaddingY: (t?.padding ?? 0) * 1
  };
  return ns(e, t, s);
}
f(Ng, "roundedRect");
var cr = 8;
async function qg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const s = t.look === "neo" ? 16 : t.padding ?? 0, o = t.look === "neo" ? 12 : t.padding ?? 0, { shapeSvg: a, bbox: n, label: l } = await st(e, t, tt(t)), c = (t?.width ?? n.width) + s * 2 + (t.look === "neo" ? cr : cr * 2), h = (t?.height ?? n.height) + o * 2, u = c - cr, p = h, d = cr - c / 2, g = -h / 2, { cssStyles: m } = t, y = U.svg(a), x = X(t, {});
  t.look !== "handDrawn" && (x.roughness = 0, x.fillStyle = "solid");
  const b = [
    { x: d, y: g },
    { x: d + u, y: g },
    { x: d + u, y: g + p },
    { x: d - cr, y: g + p },
    { x: d - cr, y: g },
    { x: d, y: g },
    { x: d, y: g + p }
  ], k = y.polygon(
    b.map((S) => [S.x, S.y]),
    x
  ), w = a.insert(() => k, ":first-child");
  return w.attr("class", "basic label-container outer-path").attr("style", Dt(m)), i && t.look !== "handDrawn" && w.selectAll("path").attr("style", i), m && t.look !== "handDrawn" && w.selectAll("path").attr("style", i), l.attr(
    "transform",
    `translate(${cr / 2 - n.width / 2 - (n.x - (n.left ?? 0))}, ${-(n.height / 2) - (n.y - (n.top ?? 0))})`
  ), Z(t, w), t.intersect = function(S) {
    return j.rect(t, S);
  }, a;
}
f(qg, "shadedProcess");
async function zg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 16 : s, a = t.look === "neo" ? 12 : s;
  (t.width || t.height) && (t.width = Math.max((t?.width ?? 0) - o * 2, 10), t.height = Math.max((t?.height ?? 0) / 1.5 - a * 2, 10));
  const { shapeSvg: n, bbox: l, label: c } = await st(e, t, tt(t)), h = (t?.width ? t?.width : l.width) + o * 2, u = ((t?.height ? t?.height : l.height) + a * 2) * 1.5, p = h, d = u / 1.5, g = -p / 2, m = -d / 2, { cssStyles: y } = t, x = U.svg(n), b = X(t, {});
  t.look !== "handDrawn" && (b.roughness = 0, b.fillStyle = "solid");
  const k = [
    { x: g, y: m },
    { x: g, y: m + d },
    { x: g + p, y: m + d },
    { x: g + p, y: m - d / 2 }
  ], w = pt(k), S = x.path(w, b), v = n.insert(() => S, ":first-child");
  return v.attr("class", "basic label-container  outer-path"), y && t.look !== "handDrawn" && v.selectChildren("path").attr("style", y), i && t.look !== "handDrawn" && v.selectChildren("path").attr("style", i), v.attr("transform", `translate(0, ${d / 4})`), c.attr(
    "transform",
    `translate(${-p / 2 + (t.padding ?? 0) - (l.x - (l.left ?? 0))}, ${-d / 4 + (t.padding ?? 0) - (l.y - (l.top ?? 0))})`
  ), Z(t, v), t.intersect = function(M) {
    return j.polygon(t, k, M);
  }, n;
}
f(zg, "slopedRect");
async function Wg(e, t) {
  const r = t.padding ?? 0, i = t.look === "neo" ? 16 : r * 2, s = t.look === "neo" ? 12 : r, o = {
    rx: 0,
    ry: 0,
    labelPaddingX: t.labelPaddingX ?? i,
    labelPaddingY: s
  };
  return ns(e, t, o);
}
f(Wg, "squareRect");
async function Hg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 20 : s, a = t.look === "neo" ? 12 : s, { shapeSvg: n, bbox: l } = await st(e, t, tt(t)), c = l.height + (t.look === "neo" ? a * 2 : a), h = l.width + c / 4 + (t.look === "neo" ? o * 2 : o), u = c / 2, { cssStyles: p } = t, d = U.svg(n), g = X(t, {});
  t.look !== "handDrawn" && (g.roughness = 0, g.fillStyle = "solid");
  const m = [
    { x: -h / 2 + u, y: -c / 2 },
    { x: h / 2 - u, y: -c / 2 },
    ...Xi(-h / 2 + u, 0, u, 50, 90, 270),
    { x: h / 2 - u, y: c / 2 },
    ...Xi(h / 2 - u, 0, u, 50, 270, 450)
  ], y = pt(m), x = d.path(y, g), b = n.insert(() => x, ":first-child");
  return b.attr("class", "basic label-container outer-path"), p && t.look !== "handDrawn" && b.selectChildren("path").attr("style", p), i && t.look !== "handDrawn" && b.selectChildren("path").attr("style", i), Z(t, b), t.intersect = function(k) {
    return j.polygon(t, m, k);
  }, n;
}
f(Hg, "stadium");
async function Yg(e, t) {
  const r = {
    rx: t.look === "neo" ? 3 : 5,
    ry: t.look === "neo" ? 3 : 5
  };
  return ns(e, t, r);
}
f(Yg, "state");
function jg(e, t, { config: { themeVariables: r } }) {
  const { labelStyles: i, nodeStyles: s } = V(t);
  t.labelStyle = i;
  const { cssStyles: o } = t, { lineColor: a, stateBorder: n, nodeBorder: l, nodeShadow: c } = r;
  (t.width || t.height) && ((t.width ?? 0) < 14 && (t.width = 14), (t.height ?? 0) < 14 && (t.height = 14)), t.width || (t.width = 14), t.height || (t.height = 14);
  const h = e.insert("g").attr("class", "node default").attr("id", t.domId ?? t.id), u = U.svg(h), p = X(t, {});
  t.look !== "handDrawn" && (p.roughness = 0, p.fillStyle = "solid");
  const d = u.circle(0, 0, t.width, {
    ...p,
    stroke: a,
    strokeWidth: 2
  }), g = n ?? l, m = (t.width ?? 0) * 5 / 14, y = u.circle(0, 0, m, {
    ...p,
    fill: g,
    stroke: g,
    strokeWidth: 2,
    fillStyle: "solid"
  }), x = h.insert(() => d, ":first-child");
  if (x.insert(() => y), t.look !== "handDrawn" && x.attr("class", "outer-path"), o && x.selectAll("path").attr("style", o), s && x.selectAll("path").attr("style", s), t.width < 25 && c && t.look !== "handDrawn") {
    const b = e.node()?.ownerSVGElement?.id ?? "", k = b ? `${b}-drop-shadow-small` : "drop-shadow-small";
    x.attr("style", `filter:url(#${k})`);
  }
  return Z(t, x), t.intersect = function(b) {
    return j.circle(t, (t.width ?? 0) / 2, b);
  }, h;
}
f(jg, "stateEnd");
function Ug(e, t, { config: { themeVariables: r } }) {
  const { lineColor: i, nodeShadow: s } = r;
  (t.width || t.height) && ((t.width ?? 0) < 14 && (t.width = 14), (t.height ?? 0) < 14 && (t.height = 14)), t.width || (t.width = 14), t.height || (t.height = 14);
  const o = e.insert("g").attr("class", "node default").attr("id", t.domId || t.id);
  let a;
  if (t.look === "handDrawn") {
    const l = U.svg(o).circle(0, 0, t.width, jw(i));
    a = o.insert(() => l), a.attr("class", "state-start").attr("r", (t.width ?? 7) / 2).attr("width", t.width ?? 14).attr("height", t.height ?? 14);
  } else
    a = o.insert("circle", ":first-child"), a.attr("class", "state-start").attr("r", (t.width ?? 7) / 2).attr("width", t.width ?? 14).attr("height", t.height ?? 14);
  if (t.width < 25 && s && t.look !== "handDrawn") {
    const n = e.node()?.ownerSVGElement?.id ?? "", l = n ? `${n}-drop-shadow-small` : "drop-shadow-small";
    a.attr("style", `filter:url(#${l})`);
  }
  return Z(t, a), t.intersect = function(n) {
    return j.circle(t, (t.width ?? 7) / 2, n);
  }, o;
}
f(Ug, "stateStart");
var Rr = 8;
async function Gg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const s = t?.padding ?? 8, o = t.look === "neo" ? 28 : s, a = t.look === "neo" ? 12 : s, { shapeSvg: n, bbox: l } = await st(e, t, tt(t)), c = (t?.width ?? l.width) + 2 * Rr + o, h = (t?.height ?? l.height) + a, u = c - 2 * Rr, p = h, d = -c / 2, g = -h / 2, m = [
    { x: 0, y: 0 },
    { x: u, y: 0 },
    { x: u, y: -p },
    { x: 0, y: -p },
    { x: 0, y: 0 },
    { x: -8, y: 0 },
    { x: u + 8, y: 0 },
    { x: u + 8, y: -p },
    { x: -8, y: -p },
    { x: -8, y: 0 }
  ];
  if (t.look === "handDrawn") {
    const y = U.svg(n), x = X(t, {}), b = y.rectangle(d, g, u + 16, p, x), k = y.line(d + Rr, g, d + Rr, g + p, x), w = y.line(d + Rr + u, g, d + Rr + u, g + p, x);
    n.insert(() => k, ":first-child"), n.insert(() => w, ":first-child");
    const S = n.insert(() => b, ":first-child"), { cssStyles: v } = t;
    S.attr("class", "basic label-container").attr("style", Dt(v)), Z(t, S);
  } else {
    const y = Xe(n, u, p, m);
    i && y.attr("style", i), Z(t, y);
  }
  return t.intersect = function(y) {
    return j.polygon(t, m, y);
  }, n;
}
f(Gg, "subroutine");
var ba = 0.2;
async function Xg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 16 : s, a = t.look === "neo" ? 12 : s;
  (t.width || t.height) && (t.height = Math.max((t?.height ?? 0) - a * 2, 10), t.width = Math.max(
    (t?.width ?? 0) - o * 2 - ba * (t.height + a * 2),
    10
  ));
  const { shapeSvg: n, bbox: l } = await st(e, t, tt(t)), c = (t?.height ? t?.height : l.height) + a * 2, h = ba * c, u = ba * c, d = (t?.width ? t?.width : l.width) + o * 2 + h - h, g = c, m = -d / 2, y = -g / 2, { cssStyles: x } = t, b = U.svg(n), k = X(t, {}), w = [
    { x: m - h / 2, y },
    { x: m + d + h / 2, y },
    { x: m + d + h / 2, y: y + g },
    { x: m - h / 2, y: y + g }
  ], S = [
    { x: m + d - h / 2, y: y + g },
    { x: m + d + h / 2, y: y + g },
    { x: m + d + h / 2, y: y + g - u }
  ];
  t.look !== "handDrawn" && (k.roughness = 0, k.fillStyle = "solid");
  const v = pt(w), M = b.path(v, k), B = pt(S), N = b.path(B, { ...k, fillStyle: "solid" }), D = n.insert(() => N, ":first-child");
  return D.insert(() => M, ":first-child"), D.attr("class", "basic label-container outer-path"), x && t.look !== "handDrawn" && D.selectAll("path").attr("style", x), i && t.look !== "handDrawn" && D.selectAll("path").attr("style", i), Z(t, D), t.intersect = function(O) {
    return j.polygon(t, w, O);
  }, n;
}
f(Xg, "taggedRect");
async function Vg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const { shapeSvg: s, bbox: o, label: a } = await st(e, t, tt(t)), n = Math.max(o.width + (t.padding ?? 0) * 2, t?.width ?? 0), l = Math.max(o.height + (t.padding ?? 0) * 2, t?.height ?? 0), c = l / 8, h = 0.2 * n, u = 0.2 * l, p = l + c, { cssStyles: d } = t, g = U.svg(s), m = X(t, {});
  t.look !== "handDrawn" && (m.roughness = 0, m.fillStyle = "solid");
  const y = [
    { x: -n / 2 - n / 2 * 0.1, y: p / 2 },
    ...sr(
      -n / 2 - n / 2 * 0.1,
      p / 2,
      n / 2 + n / 2 * 0.1,
      p / 2,
      c,
      0.8
    ),
    { x: n / 2 + n / 2 * 0.1, y: -p / 2 },
    { x: -n / 2 - n / 2 * 0.1, y: -p / 2 }
  ], x = -n / 2 + n / 2 * 0.1, b = -p / 2 - u * 0.4, k = [
    { x: x + n - h, y: (b + l) * 1.3 },
    { x: x + n, y: b + l - u },
    { x: x + n, y: (b + l) * 0.9 },
    ...sr(
      x + n,
      (b + l) * 1.25,
      x + n - h,
      (b + l) * 1.3,
      -l * 0.02,
      0.5
    )
  ], w = pt(y), S = g.path(w, m), v = pt(k), M = g.path(v, {
    ...m,
    fillStyle: "solid"
  }), B = s.insert(() => M, ":first-child");
  return B.insert(() => S, ":first-child"), B.attr("class", "basic label-container outer-path"), d && t.look !== "handDrawn" && B.selectAll("path").attr("style", d), i && t.look !== "handDrawn" && B.selectAll("path").attr("style", i), B.attr("transform", `translate(0,${-c / 2})`), a.attr(
    "transform",
    `translate(${-n / 2 + (t.padding ?? 0) - (o.x - (o.left ?? 0))},${-l / 2 + (t.padding ?? 0) - c / 2 - (o.y - (o.top ?? 0))})`
  ), Z(t, B), t.intersect = function(N) {
    return j.polygon(t, y, N);
  }, s;
}
f(Vg, "taggedWaveEdgedRectangle");
async function Zg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const { shapeSvg: s, bbox: o } = await st(e, t, tt(t)), a = Math.max(o.width + (t.padding ?? 0), t?.width || 0), n = Math.max(o.height + (t.padding ?? 0), t?.height || 0), l = -a / 2, c = -n / 2, h = s.insert("rect", ":first-child");
  return h.attr("class", "text").attr("style", i).attr("rx", 0).attr("ry", 0).attr("x", l).attr("y", c).attr("width", a).attr("height", n), Z(t, h), t.intersect = function(u) {
    return j.rect(t, u);
  }, s;
}
f(Zg, "text");
var P_ = /* @__PURE__ */ f((e, t, r, i, s, o) => `M${e},${t}
    a${s},${o} 0,0,1 0,${-i}
    l${r},0
    a${s},${o} 0,0,1 0,${i}
    M${r},${-i}
    a${s},${o} 0,0,0 0,${i}
    l${-r},0`, "createCylinderPathD"), R_ = /* @__PURE__ */ f((e, t, r, i, s, o) => [
  `M${e},${t}`,
  `M${e + r},${t}`,
  `a${s},${o} 0,0,0 0,${-i}`,
  `l${-r},0`,
  `a${s},${o} 0,0,0 0,${i}`,
  `l${r},0`
].join(" "), "createOuterCylinderPathD"), N_ = /* @__PURE__ */ f((e, t, r, i, s, o) => [`M${e + r / 2},${-i / 2}`, `a${s},${o} 0,0,0 0,${i}`].join(" "), "createInnerCylinderPathD"), Tc = 5, wc = 10;
async function Kg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 12 : s / 2;
  if (t.width || t.height) {
    const m = t.height ?? 0;
    t.height = (t.height ?? 0) - o, t.height < Tc && (t.height = Tc);
    const x = m / 2 / (2.5 + m / 50);
    t.width = (t.width ?? 0) - o - x * 3, t.width < wc && (t.width = wc);
  }
  const { shapeSvg: a, bbox: n, label: l } = await st(e, t, tt(t)), c = (t.height ? t.height : n.height) + o, h = c / 2, u = h / (2.5 + c / 50), p = (t.width ? t.width : n.width) + u + o, { cssStyles: d } = t;
  let g;
  if (t.look === "handDrawn") {
    const m = U.svg(a), y = R_(0, 0, p, c, u, h), x = N_(0, 0, p, c, u, h), b = m.path(y, X(t, {})), k = m.path(x, X(t, { fill: "none" }));
    g = a.insert(() => k, ":first-child"), g = a.insert(() => b, ":first-child"), g.attr("class", "basic label-container"), d && g.attr("style", d);
  } else {
    const m = P_(0, 0, p, c, u, h);
    g = a.insert("path", ":first-child").attr("d", m).attr("class", "basic label-container").attr("style", Dt(d)).attr("style", i), g.attr("class", "basic label-container outer-path"), d && g.selectAll("path").attr("style", d), i && g.selectAll("path").attr("style", i);
  }
  return g.attr("label-offset-x", u), g.attr("transform", `translate(${-p / 2}, ${c / 2} )`), l.attr(
    "transform",
    `translate(${-(n.width / 2) - u - (n.x - (n.left ?? 0))}, ${-(n.height / 2) - (n.y - (n.top ?? 0))})`
  ), Z(t, g), t.intersect = function(m) {
    const y = j.rect(t, m), x = y.y - (t.y ?? 0);
    if (h != 0 && (Math.abs(x) < (t.height ?? 0) / 2 || Math.abs(x) == (t.height ?? 0) / 2 && Math.abs(y.x - (t.x ?? 0)) > (t.width ?? 0) / 2 - u)) {
      let b = u * u * (1 - x * x / (h * h));
      b != 0 && (b = Math.sqrt(Math.abs(b))), b = u - b, m.x - (t.x ?? 0) > 0 && (b = -b), y.x += b;
    }
    return y;
  }, a;
}
f(Kg, "tiltedCylinder");
async function Qg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = (t.look === "neo", s), a = t.look === "neo" ? s * 2 : s, { shapeSvg: n, bbox: l } = await st(e, t, tt(t)), c = (t?.height ?? l.height) + o, h = (t?.width ?? l.width) + a, u = [
    { x: -3 * c / 6, y: 0 },
    { x: h + 3 * c / 6, y: 0 },
    { x: h, y: -c },
    { x: 0, y: -c }
  ];
  let p;
  const { cssStyles: d } = t;
  if (t.look === "handDrawn") {
    const g = U.svg(n), m = X(t, {}), y = pt(u), x = g.path(y, m);
    p = n.insert(() => x, ":first-child").attr("transform", `translate(${-h / 2}, ${c / 2})`), d && p.attr("style", d);
  } else
    p = Xe(n, h, c, u);
  return i && p.attr("style", i), t.width = h, t.height = c, Z(t, p), t.intersect = function(g) {
    return j.polygon(t, u, g);
  }, n;
}
f(Qg, "trapezoid");
async function Jg(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 16 : s, a = t.look === "neo" ? 12 : s, n = 15, l = 5;
  (t.width || t.height) && (t.height = (t.height ?? 0) - a * 2, t.height < l && (t.height = l), t.width = (t.width ?? 0) - o * 2, t.width < n && (t.width = n));
  const { shapeSvg: c, bbox: h } = await st(e, t, tt(t)), u = (t?.width ? t?.width : h.width) + o * 2, p = (t?.height ? t?.height : h.height) + a * 2, { cssStyles: d } = t, g = U.svg(c), m = X(t, {});
  t.look !== "handDrawn" && (m.roughness = 0, m.fillStyle = "solid");
  const y = [
    { x: -u / 2 * 0.8, y: -p / 2 },
    { x: u / 2 * 0.8, y: -p / 2 },
    { x: u / 2, y: -p / 2 * 0.6 },
    { x: u / 2, y: p / 2 },
    { x: -u / 2, y: p / 2 },
    { x: -u / 2, y: -p / 2 * 0.6 }
  ], x = pt(y), b = g.path(x, m), k = c.insert(() => b, ":first-child");
  return k.attr("class", "basic label-container outer-path"), d && t.look !== "handDrawn" && k.selectChildren("path").attr("style", d), i && t.look !== "handDrawn" && k.selectChildren("path").attr("style", i), Z(t, k), t.intersect = function(w) {
    return j.polygon(t, y, w);
  }, c;
}
f(Jg, "trapezoidalPentagon");
var Sc = 10, _c = 10;
async function tm(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? s * 2 : s;
  (t.width || t.height) && (t.width = ((t?.width ?? 0) - o) / 2, t.width < _c && (t.width = _c), t.height = t?.height ?? 0, t.height < Sc && (t.height = Sc));
  const { shapeSvg: a, bbox: n, label: l } = await st(e, t, tt(t)), c = je(gt().flowchart?.htmlLabels), h = (t?.width ? t?.width : n.width) + o, u = t?.height ? t?.height : h + n.height, p = u, d = [
    { x: 0, y: 0 },
    { x: p, y: 0 },
    { x: p / 2, y: -u }
  ], { cssStyles: g } = t, m = U.svg(a), y = X(t, {});
  t.look !== "handDrawn" && (y.roughness = 0, y.fillStyle = "solid");
  const x = pt(d), b = m.path(x, y), k = a.insert(() => b, ":first-child").attr("transform", `translate(${-u / 2}, ${u / 2})`).attr("class", "outer-path");
  return g && t.look !== "handDrawn" && k.selectChildren("path").attr("style", g), i && t.look !== "handDrawn" && k.selectChildren("path").attr("style", i), t.width = h, t.height = u, Z(t, k), l.attr(
    "transform",
    `translate(${-n.width / 2 - (n.x - (n.left ?? 0))}, ${u / 2 - (n.height + (t.padding ?? 0) / (c ? 2 : 1) - (n.y - (n.top ?? 0)))})`
  ), t.intersect = function(w) {
    return R.info("Triangle intersect", t, d, w), j.polygon(t, d, w);
  }, a;
}
f(tm, "triangle");
async function em(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 16 : s, a = t.look === "neo" ? 12 : s;
  let n = !0;
  (t.width || t.height) && (n = !1, t.width = (t?.width ?? 0) - o * 2, t.width < 10 && (t.width = 10), t.height = (t?.height ?? 0) - a * 2, t.height < 10 && (t.height = 10));
  const { shapeSvg: l, bbox: c, label: h } = await st(e, t, tt(t)), u = (t?.width ? t?.width : c.width) + (o ?? 0) * 2, p = (t?.height ? t?.height : c.height) + (a ?? 0) * 2, d = t.look === "neo" ? p / 4 : p / 8, g = p + (n ? d : -d), { cssStyles: m } = t, x = 14 - u, b = x > 0 ? x / 2 : 0, k = U.svg(l), w = X(t, {});
  t.look !== "handDrawn" && (w.roughness = 0, w.fillStyle = "solid");
  const S = [
    { x: -u / 2 - b, y: g / 2 },
    ...sr(
      -u / 2 - b,
      g / 2,
      u / 2 + b,
      g / 2,
      d,
      0.8
    ),
    { x: u / 2 + b, y: -g / 2 },
    { x: -u / 2 - b, y: -g / 2 }
  ], v = pt(S), M = k.path(v, w), B = l.insert(() => M, ":first-child");
  return B.attr("class", "basic label-container outer-path"), m && t.look !== "handDrawn" && B.selectAll("path").attr("style", m), i && t.look !== "handDrawn" && B.selectAll("path").attr("style", i), B.attr("transform", `translate(0,${-d / 2})`), h.attr(
    "transform",
    `translate(${-u / 2 + (t.padding ?? 0) - (c.x - (c.left ?? 0))},${-p / 2 + (t.padding ?? 0) - d - (c.y - (c.top ?? 0))})`
  ), Z(t, B), t.intersect = function(N) {
    return j.polygon(t, S, N);
  }, l;
}
f(em, "waveEdgedRectangle");
async function rm(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 16 : s, a = t.look === "neo" ? 20 : s;
  if (t.width || t.height) {
    t.width = t?.width ?? 0, t.width < 20 && (t.width = 20), t.height = t?.height ?? 0, t.height < 10 && (t.height = 10);
    const w = Math.min(t.height * 0.2, t.height / 4);
    t.height = Math.ceil(t.height - a - w * (20 / 9)), t.width = t.width - o * 2;
  }
  const { shapeSvg: n, bbox: l } = await st(e, t, tt(t)), c = (t?.width ? t?.width : l.width) + o * 2, h = (t?.height ? t?.height : l.height) + a, u = h / 8, p = h + u * 2, { cssStyles: d } = t, g = U.svg(n), m = X(t, {});
  t.look !== "handDrawn" && (m.roughness = 0, m.fillStyle = "solid");
  const y = [
    { x: -c / 2, y: p / 2 },
    ...sr(-c / 2, p / 2, c / 2, p / 2, u, 1),
    { x: c / 2, y: -p / 2 },
    ...sr(c / 2, -p / 2, -c / 2, -p / 2, u, -1)
  ], x = pt(y), b = g.path(x, m), k = n.insert(() => b, ":first-child");
  return k.attr("class", "basic label-container"), d && t.look !== "handDrawn" && k.selectAll("path").attr("style", d), i && t.look !== "handDrawn" && k.selectAll("path").attr("style", i), Z(t, k), t.intersect = function(w) {
    return j.polygon(t, y, w);
  }, n;
}
f(rm, "waveRectangle");
var St = 10;
async function im(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const s = t.look === "neo" ? 16 : t.padding ?? 0, o = t.look === "neo" ? 12 : t.padding ?? 0;
  (t.width || t.height) && (t.width = Math.max((t?.width ?? 0) - s * 2 - St, 10), t.height = Math.max((t?.height ?? 0) - o * 2 - St, 10));
  const { shapeSvg: a, bbox: n, label: l } = await st(e, t, tt(t)), c = (t?.width ? t?.width : n.width) + s * 2 + St, h = (t?.height ? t?.height : n.height) + o * 2 + St, u = c - St, p = h - St, d = -u / 2, g = -p / 2, { cssStyles: m } = t, y = U.svg(a), x = X(t, {}), b = [
    { x: d - St, y: g - St },
    { x: d - St, y: g + p },
    { x: d + u, y: g + p },
    { x: d + u, y: g - St }
  ], k = `M${d - St},${g - St} L${d + u},${g - St} L${d + u},${g + p} L${d - St},${g + p} L${d - St},${g - St}
                M${d - St},${g} L${d + u},${g}
                M${d},${g - St} L${d},${g + p}`;
  t.look !== "handDrawn" && (x.roughness = 0, x.fillStyle = "solid");
  const w = y.path(k, x), S = a.insert(() => w, ":first-child");
  return S.attr("transform", `translate(${St / 2}, ${St / 2})`), S.attr("class", "basic label-container outer-path"), m && t.look !== "handDrawn" && S.selectAll("path").attr("style", m), i && t.look !== "handDrawn" && S.selectAll("path").attr("style", i), l.attr(
    "transform",
    `translate(${-(n.width / 2) + St / 2 - (n.x - (n.left ?? 0))}, ${-(n.height / 2) + St / 2 - (n.y - (n.top ?? 0))})`
  ), Z(t, S), t.intersect = function(v) {
    return j.polygon(t, b, v);
  }, a;
}
f(im, "windowPane");
var vc = /* @__PURE__ */ new Set(["redux-color", "redux-dark-color"]), q_ = /* @__PURE__ */ new Set(["redux", "redux-dark", "redux-color", "redux-dark-color"]);
async function wl(e, t) {
  const r = t;
  r.alias && (t.label = r.alias);
  const { theme: i, themeVariables: s } = wt(), { rowEven: o, rowOdd: a, nodeBorder: n, borderColorArray: l } = s;
  if (t.look === "handDrawn") {
    const { themeVariables: rt } = wt(), { background: ht } = rt, ft = {
      ...t,
      id: t.id + "-background",
      domId: (t.domId || t.id) + "-background",
      look: "default",
      cssStyles: ["stroke: none", `fill: ${ht}`]
    };
    await wl(e, ft);
  }
  const c = wt();
  t.useHtmlLabels = c.htmlLabels;
  let h = c.er?.diagramPadding ?? 10, u = c.er?.entityPadding ?? 6;
  const { cssStyles: p } = t, { labelStyles: d, nodeStyles: g } = V(t);
  if (r.attributes.length === 0 && t.label) {
    const rt = {
      rx: 0,
      ry: 0,
      labelPaddingX: h,
      labelPaddingY: h * 1.5
    };
    He(t.label, c) + rt.labelPaddingX * 2 < c.er.minEntityWidth && (t.width = c.er.minEntityWidth);
    const ht = await ns(e, t, rt);
    if (i != null && vc.has(i)) {
      const ft = r.colorIndex ?? 0;
      ht.attr("data-color-id", `color-${ft % l.length}`);
    }
    if (!je(c.htmlLabels)) {
      const ft = ht.select("text"), bt = ft.node()?.getBBox();
      ft.attr("transform", `translate(${-bt.width / 2}, 0)`);
    }
    return ht;
  }
  c.htmlLabels || (h *= 1.25, u *= 1.25);
  let m = tt(t);
  m || (m = "node default");
  const y = e.insert("g").attr("class", m).attr("id", t.domId || t.id), x = await Wr(y, t.label ?? "", c, 0, 0, ["name"], d);
  x.height += u;
  let b = 0;
  const k = [], w = [];
  let S = 0, v = 0, M = 0, B = 0, N = !0, D = !0;
  for (const rt of r.attributes) {
    const ht = await Wr(
      y,
      rt.type,
      c,
      0,
      b,
      ["attribute-type"],
      d
    );
    S = Math.max(S, ht.width + h);
    const ft = await Wr(
      y,
      rt.name,
      c,
      0,
      b,
      ["attribute-name"],
      d
    );
    v = Math.max(v, ft.width + h);
    const bt = await Wr(
      y,
      rt.keys.join(),
      c,
      0,
      b,
      ["attribute-keys"],
      d
    );
    M = Math.max(M, bt.width + h);
    const Ct = await Wr(
      y,
      rt.comment,
      c,
      0,
      b,
      ["attribute-comment"],
      d
    );
    B = Math.max(B, Ct.width + h);
    const Bt = Math.max(ht.height, ft.height, bt.height, Ct.height) + u;
    w.push({ yOffset: b, rowHeight: Bt }), b += Bt;
  }
  let O = 4;
  M <= h && (N = !1, M = 0, O--), B <= h && (D = !1, B = 0, O--);
  const W = y.node().getBBox();
  if (x.width + h * 2 - (S + v + M + B) > 0) {
    const rt = x.width + h * 2 - (S + v + M + B);
    S += rt / O, v += rt / O, M > 0 && (M += rt / O), B > 0 && (B += rt / O);
  }
  const z = S + v + M + B, I = U.svg(y), F = X(t, {});
  t.look !== "handDrawn" && (F.roughness = 0, F.fillStyle = "solid");
  let L = 0;
  w.length > 0 && (L = w.reduce((rt, ht) => rt + (ht?.rowHeight ?? 0), 0));
  const E = Math.max(W.width + h * 2, t?.width || 0, z), P = Math.max((L ?? 0) + x.height, t?.height || 0), H = -E / 2, Y = -P / 2;
  if (y.selectAll("g:not(:first-child)").each((rt, ht, ft) => {
    const bt = ct(ft[ht]), Ct = bt.attr("transform");
    let Bt = 0, ce = 0;
    if (Ct) {
      const Oe = RegExp(/translate\(([^,]+),([^)]+)\)/).exec(Ct);
      Oe && (Bt = parseFloat(Oe[1]), ce = parseFloat(Oe[2]), bt.attr("class").includes("attribute-name") ? Bt += S : bt.attr("class").includes("attribute-keys") ? Bt += S + v : bt.attr("class").includes("attribute-comment") && (Bt += S + v + M));
    }
    bt.attr(
      "transform",
      `translate(${H + h / 2 + Bt}, ${ce + Y + x.height + u / 2})`
    );
  }), y.select(".name").attr("transform", "translate(" + -x.width / 2 + ", " + (Y + u / 2) + ")"), i != null && vc.has(i)) {
    const rt = r.colorIndex ?? 0;
    y.attr("data-color-id", `color-${rt % l.length}`);
  }
  const Q = I.rectangle(H, Y, E, P, F), dt = y.insert(() => Q, ":first-child").attr("class", "outer-path").attr("style", p.join(""));
  k.push(0);
  for (const [rt, ht] of w.entries()) {
    const bt = (rt + 1) % 2 === 0 && ht.yOffset !== 0, Ct = I.rectangle(H, x.height + Y + ht?.yOffset, E, ht?.rowHeight, {
      ...F,
      fill: bt ? o : a,
      stroke: n
    });
    y.insert(() => Ct, "g.label").attr("style", p.join("")).attr("class", `row-rect-${bt ? "even" : "odd"}`);
  }
  const et = 1e-4;
  let ut = Hr(H, x.height + Y, E + H, x.height + Y, et), it = I.polygon(
    ut.map((rt) => [rt.x, rt.y]),
    F
  );
  if (y.insert(() => it).attr("class", "divider"), ut = Hr(S + H, x.height + Y, S + H, P + Y, et), it = I.polygon(
    ut.map((rt) => [rt.x, rt.y]),
    F
  ), y.insert(() => it).attr("class", "divider"), N) {
    const rt = S + v + H;
    ut = Hr(rt, x.height + Y, rt, P + Y, et), it = I.polygon(
      ut.map((ht) => [ht.x, ht.y]),
      F
    ), y.insert(() => it).attr("class", "divider");
  }
  if (D) {
    const rt = S + v + M + H;
    ut = Hr(rt, x.height + Y, rt, P + Y, et), it = I.polygon(
      ut.map((ht) => [ht.x, ht.y]),
      F
    ), y.insert(() => it).attr("class", "divider");
  }
  for (const rt of k) {
    const ht = x.height + Y + rt;
    ut = Hr(H, ht, E + H, ht, et), it = I.polygon(
      ut.map((ft) => [ft.x, ft.y]),
      F
    ), y.insert(() => it).attr("class", "divider");
  }
  if (Z(t, dt), g && t.look !== "handDrawn")
    if (i != null && q_.has(i))
      y.selectAll("path").attr("style", g);
    else {
      const ht = g.split(";")?.filter((ft) => ft.includes("stroke"))?.map((ft) => `${ft}`).join("; ");
      y.selectAll("path").attr("style", ht ?? ""), y.selectAll(".row-rect-even path").attr("style", g);
    }
  return t.intersect = function(rt) {
    return j.rect(t, rt);
  }, y;
}
f(wl, "erBox");
async function Wr(e, t, r, i = 0, s = 0, o = [], a = "") {
  const n = e.insert("g").attr("class", `label ${o.join(" ")}`).attr("transform", `translate(${i}, ${s})`).attr("style", a);
  t !== ah(t) && (t = ah(t), t = t.replaceAll("<", "&lt;").replaceAll(">", "&gt;"));
  const l = n.node().appendChild(
    await Ge(
      n,
      t,
      {
        width: He(t, r) + 100,
        style: a,
        useHtmlLabels: r.htmlLabels
      },
      r
    )
  );
  if (t.includes("&lt;") || t.includes("&gt;")) {
    let h = l.children[0];
    for (h.textContent = h.textContent.replaceAll("&lt;", "<").replaceAll("&gt;", ">"); h.childNodes[0]; )
      h = h.childNodes[0], h.textContent = h.textContent.replaceAll("&lt;", "<").replaceAll("&gt;", ">");
  }
  let c = l.getBBox();
  if (je(r.htmlLabels)) {
    const h = l.children[0];
    h.style.textAlign = "start";
    const u = ct(l);
    c = h.getBoundingClientRect(), u.attr("width", c.width), u.attr("height", c.height);
  }
  return c;
}
f(Wr, "addText");
function Hr(e, t, r, i, s) {
  return e === r ? [
    { x: e - s / 2, y: t },
    { x: e + s / 2, y: t },
    { x: r + s / 2, y: i },
    { x: r - s / 2, y: i }
  ] : [
    { x: e, y: t - s / 2 },
    { x: e, y: t + s / 2 },
    { x: r, y: i + s / 2 },
    { x: r, y: i - s / 2 }
  ];
}
f(Hr, "lineToPolygon");
async function sm(e, t, r, i, s = r.class.padding ?? 12) {
  const o = i ? 0 : 3, a = e.insert("g").attr("class", tt(t)).attr("id", t.domId || t.id);
  let n = null, l = null, c = null, h = null, u = 0, p = 0, d = 0;
  if (n = a.insert("g").attr("class", "annotation-group text"), t.annotations.length > 0) {
    const b = t.annotations[0];
    await Li(n, { text: `«${b}»` }, 0), u = n.node().getBBox().height;
  }
  l = a.insert("g").attr("class", "label-group text"), await Li(l, t, 0, ["font-weight: bolder"]);
  const g = l.node().getBBox();
  p = g.height, c = a.insert("g").attr("class", "members-group text");
  let m = 0;
  for (const b of t.members) {
    const k = await Li(c, b, m, [b.parseClassifier()]);
    m += k + o;
  }
  d = c.node().getBBox().height, d <= 0 && (d = s / 2), h = a.insert("g").attr("class", "methods-group text");
  let y = 0;
  for (const b of t.methods) {
    const k = await Li(h, b, y, [b.parseClassifier()]);
    y += k + o;
  }
  let x = a.node().getBBox();
  if (n !== null) {
    const b = n.node().getBBox();
    n.attr("transform", `translate(${-b.width / 2})`);
  }
  return l.attr("transform", `translate(${-g.width / 2}, ${u})`), x = a.node().getBBox(), c.attr(
    "transform",
    `translate(0, ${u + p + s * 2})`
  ), x = a.node().getBBox(), h.attr(
    "transform",
    `translate(0, ${u + p + (d ? d + s * 4 : s * 2)})`
  ), x = a.node().getBBox(), { shapeSvg: a, bbox: x };
}
f(sm, "textHelper");
async function Li(e, t, r, i = []) {
  const s = e.insert("g").attr("class", "label").attr("style", i.join("; ")), o = wt();
  let a = "useHtmlLabels" in t ? t.useHtmlLabels : je(o.htmlLabels) ?? !0, n = "";
  "text" in t ? n = t.text : n = t.label, !a && n.startsWith("\\") && (n = n.substring(1)), Pi(n) && (a = !0);
  const l = await Ge(
    s,
    En(Sr(n)),
    {
      width: He(n, o) + 50,
      // Add room for error when splitting text into multiple lines
      classes: "markdown-node-label",
      useHtmlLabels: a
    },
    o
  );
  let c, h = 1;
  if (a) {
    const u = l.children[0], p = ct(l);
    h = u.innerHTML.split("<br>").length, u.innerHTML.includes("</math>") && (h += u.innerHTML.split("<mrow>").length - 1);
    const d = u.getElementsByTagName("img");
    if (d) {
      const g = n.replace(/<img[^>]*>/g, "").trim() === "";
      await Promise.all(
        [...d].map(
          (m) => new Promise((y) => {
            function x() {
              if (m.style.display = "flex", m.style.flexDirection = "column", g) {
                const b = o.fontSize?.toString() ?? window.getComputedStyle(document.body).fontSize, w = parseInt(b, 10) * 5 + "px";
                m.style.minWidth = w, m.style.maxWidth = w;
              } else
                m.style.width = "100%";
              y(m);
            }
            f(x, "setupImage"), setTimeout(() => {
              m.complete && x();
            }), m.addEventListener("error", x), m.addEventListener("load", x);
          })
        )
      );
    }
    c = u.getBoundingClientRect(), p.attr("width", c.width), p.attr("height", c.height);
  } else {
    i.includes("font-weight: bolder") && ct(l).selectAll("tspan").attr("font-weight", ""), h = l.children.length;
    const u = l.children[0];
    (l.textContent === "" || l.textContent.includes("&gt")) && (u.textContent = n[0] + n.substring(1).replaceAll("&gt;", ">").replaceAll("&lt;", "<").trim(), n[1] === " " && (u.textContent = u.textContent[0] + " " + u.textContent.substring(1))), u.textContent === "undefined" && (u.textContent = ""), c = l.getBBox();
  }
  return s.attr("transform", "translate(0," + (-c.height / (2 * h) + r) + ")"), c.height;
}
f(Li, "addText");
async function om(e, t) {
  const r = gt(), { themeVariables: i } = r, { useGradient: s } = i, o = r.class.padding ?? 12, a = o, n = t.useHtmlLabels ?? je(r.htmlLabels) ?? !0, l = t;
  l.annotations = l.annotations ?? [], l.members = l.members ?? [], l.methods = l.methods ?? [];
  const { shapeSvg: c, bbox: h } = await sm(e, t, r, n, a), { labelStyles: u, nodeStyles: p } = V(t);
  t.labelStyle = u, t.cssStyles = l.styles || "";
  const d = l.styles?.join(";") || p || "";
  t.cssStyles || (t.cssStyles = d.replaceAll("!important", "").split(";"));
  const g = l.members.length === 0 && l.methods.length === 0 && !r.class?.hideEmptyMembersBox, m = U.svg(c), y = X(t, {});
  t.look !== "handDrawn" && (y.roughness = 0, y.fillStyle = "solid");
  const x = Math.max(t.width ?? 0, h.width);
  let b = Math.max(t.height ?? 0, h.height);
  const k = (t.height ?? 0) > h.height;
  l.members.length === 0 && l.methods.length === 0 ? b += a : l.members.length > 0 && l.methods.length === 0 && (b += a * 2);
  const w = -x / 2, S = -b / 2;
  let v = g ? o * 2 : l.members.length === 0 && l.methods.length === 0 ? -o : 0;
  k && (v = o * 2);
  const M = m.rectangle(
    w - o,
    S - o - (g ? o : l.members.length === 0 && l.methods.length === 0 ? -o / 2 : 0),
    x + 2 * o,
    b + 2 * o + v,
    y
  ), B = c.insert(() => M, ":first-child");
  B.attr("class", "basic label-container outer-path");
  const N = B.node().getBBox(), D = c.select(".annotation-group").node().getBBox().height - (g ? o / 2 : 0) || 0, O = c.select(".label-group").node().getBBox().height - (g ? o / 2 : 0) || 0, W = c.select(".members-group").node().getBBox().height - (g ? o / 2 : 0) || 0, z = (D + O + S + o - (S - o - (g ? o : l.members.length === 0 && l.methods.length === 0 ? -o / 2 : 0))) / 2;
  if (c.selectAll(".text").each((I, F, L) => {
    const E = ct(L[F]), P = E.attr("transform");
    let H = 0;
    if (P) {
      const et = RegExp(/translate\(([^,]+),([^)]+)\)/).exec(P);
      et && (H = parseFloat(et[2]));
    }
    let Y = H + S + o - (g ? o : l.members.length === 0 && l.methods.length === 0 ? -o / 2 : 0);
    if (E.attr("class").includes("methods-group")) {
      const dt = Math.max(W, a / 2);
      k ? Y = Math.max(
        z,
        D + O + dt + S + a * 2 + o
      ) + a * 2 : Y = D + O + dt + S + a * 4 + o;
    }
    l.members.length === 0 && l.methods.length === 0 && r.class?.hideEmptyMembersBox && (l.annotations.length > 0 ? Y = H - a : Y = H), n || (Y -= 4);
    let Q = w;
    (E.attr("class").includes("label-group") || E.attr("class").includes("annotation-group")) && (Q = -E.node()?.getBBox().width / 2 || 0, c.selectAll("text").each(function(dt, et, ut) {
      window.getComputedStyle(ut[et]).textAnchor === "middle" && (Q = 0);
    })), E.attr("transform", `translate(${Q}, ${Y})`);
  }), l.members.length > 0 || l.methods.length > 0 || g) {
    const I = D + O + S + o, F = m.line(
      N.x,
      I,
      N.x + N.width,
      I + 1e-3,
      y
    );
    c.insert(() => F).attr("class", `divider${t.look === "neo" && !s ? " neo-line" : ""}`).attr("style", d);
  }
  if (g || l.members.length > 0 || l.methods.length > 0) {
    const I = D + O + W + S + a * 2 + o, F = m.line(
      N.x,
      k ? Math.max(z, I) : I,
      N.x + N.width,
      (k ? Math.max(z, I) : I) + 1e-3,
      y
    );
    c.insert(() => F).attr("class", `divider${t.look === "neo" && !s ? " neo-line" : ""}`).attr("style", d);
  }
  if (l.look !== "handDrawn" && c.selectAll("path").attr("style", d), B.select(":nth-child(2)").attr("style", d), c.selectAll(".divider").select("path").attr("style", d), t.labelStyle ? c.selectAll("span").attr("style", t.labelStyle) : c.selectAll("span").attr("style", d), !n) {
    const I = RegExp(/color\s*:\s*([^;]*)/), F = I.exec(d);
    if (F) {
      const L = F[0].replace("color", "fill");
      c.selectAll("tspan").attr("style", L);
    } else if (u) {
      const L = I.exec(u);
      if (L) {
        const E = L[0].replace("color", "fill");
        c.selectAll("tspan").attr("style", E);
      }
    }
  }
  return Z(t, B), t.intersect = function(I) {
    return j.rect(t, I);
  }, c;
}
f(om, "classBox");
async function am(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const s = t, o = t, a = 20, n = 20, l = "verifyMethod" in t, c = tt(t), { themeVariables: h } = gt(), { borderColorArray: u, requirementEdgeLabelBackground: p } = h, d = e.insert("g").attr("class", c).attr("id", t.domId ?? t.id);
  let g;
  l ? g = await _e(
    d,
    `&lt;&lt;${s.type}&gt;&gt;`,
    0,
    t.labelStyle
  ) : g = await _e(d, "&lt;&lt;Element&gt;&gt;", 0, t.labelStyle);
  let m = g;
  const y = await _e(
    d,
    s.name,
    m,
    t.labelStyle + "; font-weight: bold;"
  );
  if (m += y + n, l) {
    const N = await _e(
      d,
      `${s.requirementId ? `ID: ${s.requirementId}` : ""}`,
      m,
      t.labelStyle
    );
    m += N;
    const D = await _e(
      d,
      `${s.text ? `Text: ${s.text}` : ""}`,
      m,
      t.labelStyle
    );
    m += D;
    const O = await _e(
      d,
      `${s.risk ? `Risk: ${s.risk}` : ""}`,
      m,
      t.labelStyle
    );
    m += O, await _e(
      d,
      `${s.verifyMethod ? `Verification: ${s.verifyMethod}` : ""}`,
      m,
      t.labelStyle
    );
  } else {
    const N = await _e(
      d,
      `${o.type ? `Type: ${o.type}` : ""}`,
      m,
      t.labelStyle
    );
    m += N, await _e(
      d,
      `${o.docRef ? `Doc Ref: ${o.docRef}` : ""}`,
      m,
      t.labelStyle
    );
  }
  const x = (d.node()?.getBBox().width ?? 200) + a, b = (d.node()?.getBBox().height ?? 200) + a, k = -x / 2, w = -b / 2, S = U.svg(d), v = X(t, {});
  t.look !== "handDrawn" && (v.roughness = 0, v.fillStyle = "solid");
  const M = S.rectangle(k, w, x, b, v), B = d.insert(() => M, ":first-child");
  if (B.attr("class", "basic label-container outer-path").attr("style", i), u?.length) {
    const N = t.colorIndex ?? 0;
    d.attr("data-color-id", `color-${N % u.length}`);
  }
  if (d.selectAll(".label").each((N, D, O) => {
    const W = ct(O[D]), z = W.attr("transform");
    let I = 0, F = 0;
    if (z) {
      const H = RegExp(/translate\(([^,]+),([^)]+)\)/).exec(z);
      H && (I = parseFloat(H[1]), F = parseFloat(H[2]));
    }
    const L = F - b / 2;
    let E = k + a / 2;
    (D === 0 || D === 1) && (E = I), W.attr("transform", `translate(${E}, ${L + a})`);
  }), m > g + y + n) {
    const N = w + g + y + n;
    let D;
    if (t.look === "neo") {
      const z = [
        [k, N],
        [k + x, N],
        [k + x, N + 1e-3],
        [k, N + 1e-3]
      ];
      D = S.polygon(z, v);
    } else
      D = S.line(k, N, k + x, N, v);
    d.insert(() => D).attr("class", "divider");
  }
  return Z(t, B), t.intersect = function(N) {
    return j.rect(t, N);
  }, i && t.look !== "handDrawn" && (p || u?.length) && d.selectAll("path").attr("style", i), d;
}
f(am, "requirementBox");
async function _e(e, t, r, i = "") {
  if (t === "")
    return 0;
  const s = e.insert("g").attr("class", "label").attr("style", i), o = gt(), a = o.htmlLabels ?? !0, n = await Ge(
    s,
    En(Sr(t)),
    {
      width: He(t, o) + 50,
      // Add room for error when splitting text into multiple lines
      classes: "markdown-node-label",
      useHtmlLabels: a,
      style: i
    },
    o
  );
  let l;
  if (a) {
    const c = n.children[0], h = ct(n);
    l = c.getBoundingClientRect(), h.attr("width", l.width), h.attr("height", l.height);
  } else {
    const c = n.children[0];
    for (const h of c.children)
      i && h.setAttribute("style", i);
    l = n.getBBox(), l.height += 6;
  }
  return s.attr("transform", `translate(${-l.width / 2},${-l.height / 2 + r})`), l.height;
}
f(_e, "addText");
var z_ = /* @__PURE__ */ f((e) => {
  switch (e) {
    case "Very High":
      return "red";
    case "High":
      return "orange";
    case "Medium":
      return null;
    // no stroke
    case "Low":
      return "blue";
    case "Very Low":
      return "lightblue";
  }
}, "colorFromPriority");
async function nm(e, t, { config: r }) {
  const { labelStyles: i, nodeStyles: s } = V(t);
  t.labelStyle = i || "";
  const o = 10, a = t.width;
  t.width = (t.width ?? 200) - 10;
  const {
    shapeSvg: n,
    bbox: l,
    label: c
  } = await st(e, t, tt(t)), h = t.padding || 10;
  let u = "", p;
  "ticket" in t && t.ticket && r?.kanban?.ticketBaseUrl && (u = r?.kanban?.ticketBaseUrl.replace("#TICKET#", t.ticket), p = n.insert("svg:a", ":first-child").attr("class", "kanban-ticket-link").attr("xlink:href", u).attr("target", "_blank"));
  const d = {
    useHtmlLabels: t.useHtmlLabels,
    labelStyle: t.labelStyle || "",
    width: t.width,
    img: t.img,
    padding: t.padding || 8,
    centerLabel: !1
  };
  let g, m;
  p ? { label: g, bbox: m } = await xa(
    p,
    "ticket" in t && t.ticket || "",
    d
  ) : { label: g, bbox: m } = await xa(
    n,
    "ticket" in t && t.ticket || "",
    d
  );
  const { label: y, bbox: x } = await xa(
    n,
    "assigned" in t && t.assigned || "",
    d
  );
  t.width = a;
  const b = 10, k = t?.width || 0, w = Math.max(m.height, x.height) / 2, S = Math.max(l.height + b * 2, t?.height || 0) + w, v = -k / 2, M = -S / 2;
  c.attr(
    "transform",
    "translate(" + (h - k / 2) + ", " + (-w - l.height / 2) + ")"
  ), g.attr(
    "transform",
    "translate(" + (h - k / 2) + ", " + (-w + l.height / 2) + ")"
  ), y.attr(
    "transform",
    "translate(" + (h + k / 2 - x.width - 2 * o) + ", " + (-w + l.height / 2) + ")"
  );
  let B;
  const { rx: N, ry: D } = t, { cssStyles: O } = t;
  if (t.look === "handDrawn") {
    const W = U.svg(n), z = X(t, {}), I = N || D ? W.path(ar(v, M, k, S, N || 0), z) : W.rectangle(v, M, k, S, z);
    B = n.insert(() => I, ":first-child"), B.attr("class", "basic label-container").attr("style", O || null);
  } else {
    B = n.insert("rect", ":first-child"), B.attr("class", "basic label-container __APA__").attr("style", s).attr("rx", N ?? 5).attr("ry", D ?? 5).attr("x", v).attr("y", M).attr("width", k).attr("height", S);
    const W = "priority" in t && t.priority;
    if (W) {
      const z = n.append("line"), I = v + 2, F = M + Math.floor((N ?? 0) / 2), L = M + S - Math.floor((N ?? 0) / 2);
      z.attr("x1", I).attr("y1", F).attr("x2", I).attr("y2", L).attr("stroke-width", "4").attr("stroke", z_(W));
    }
  }
  return Z(t, B), t.height = S, t.intersect = function(W) {
    return j.rect(t, W);
  }, n;
}
f(nm, "kanbanItem");
async function lm(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const { shapeSvg: s, bbox: o, halfPadding: a, label: n } = await st(
    e,
    t,
    tt(t)
  ), l = o.width + 10 * a, c = o.height + 8 * a, h = 0.15 * l, { cssStyles: u } = t, p = o.width + 20, d = o.height + 20, g = Math.max(l, p), m = Math.max(c, d);
  n.attr("transform", `translate(${-o.width / 2}, ${-o.height / 2})`);
  let y;
  const x = `M0 0 
    a${h},${h} 1 0,0 ${g * 0.25},${-1 * m * 0.1}
    a${h},${h} 1 0,0 ${g * 0.25},0
    a${h},${h} 1 0,0 ${g * 0.25},0
    a${h},${h} 1 0,0 ${g * 0.25},${m * 0.1}

    a${h},${h} 1 0,0 ${g * 0.15},${m * 0.33}
    a${h * 0.8},${h * 0.8} 1 0,0 0,${m * 0.34}
    a${h},${h} 1 0,0 ${-1 * g * 0.15},${m * 0.33}

    a${h},${h} 1 0,0 ${-1 * g * 0.25},${m * 0.15}
    a${h},${h} 1 0,0 ${-1 * g * 0.25},0
    a${h},${h} 1 0,0 ${-1 * g * 0.25},0
    a${h},${h} 1 0,0 ${-1 * g * 0.25},${-1 * m * 0.15}

    a${h},${h} 1 0,0 ${-1 * g * 0.1},${-1 * m * 0.33}
    a${h * 0.8},${h * 0.8} 1 0,0 0,${-1 * m * 0.34}
    a${h},${h} 1 0,0 ${g * 0.1},${-1 * m * 0.33}
  H0 V0 Z`;
  if (t.look === "handDrawn") {
    const b = U.svg(s), k = X(t, {}), w = b.path(x, k);
    y = s.insert(() => w, ":first-child"), y.attr("class", "basic label-container").attr("style", Dt(u));
  } else
    y = s.insert("path", ":first-child").attr("class", "basic label-container").attr("style", i).attr("d", x);
  return y.attr("transform", `translate(${-g / 2}, ${-m / 2})`), Z(t, y), t.calcIntersect = function(b, k) {
    return j.rect(b, k);
  }, t.intersect = function(b) {
    return R.info("Bang intersect", t, b), j.rect(t, b);
  }, s;
}
f(lm, "bang");
async function hm(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const { shapeSvg: s, bbox: o, halfPadding: a, label: n } = await st(
    e,
    t,
    tt(t)
  ), l = o.width + 2 * a, c = o.height + 2 * a, h = 0.15 * l, u = 0.25 * l, p = 0.35 * l, d = 0.2 * l, { cssStyles: g } = t;
  let m;
  const y = `M0 0 
    a${h},${h} 0 0,1 ${l * 0.25},${-1 * l * 0.1}
    a${p},${p} 1 0,1 ${l * 0.4},${-1 * l * 0.1}
    a${u},${u} 1 0,1 ${l * 0.35},${l * 0.2}

    a${h},${h} 1 0,1 ${l * 0.15},${c * 0.35}
    a${d},${d} 1 0,1 ${-1 * l * 0.15},${c * 0.65}

    a${u},${h} 1 0,1 ${-1 * l * 0.25},${l * 0.15}
    a${p},${p} 1 0,1 ${-1 * l * 0.5},0
    a${h},${h} 1 0,1 ${-1 * l * 0.25},${-1 * l * 0.15}

    a${h},${h} 1 0,1 ${-1 * l * 0.1},${-1 * c * 0.35}
    a${d},${d} 1 0,1 ${l * 0.1},${-1 * c * 0.65}
  H0 V0 Z`;
  if (t.look === "handDrawn") {
    const x = U.svg(s), b = X(t, {}), k = x.path(y, b);
    m = s.insert(() => k, ":first-child"), m.attr("class", "basic label-container").attr("style", Dt(g));
  } else
    m = s.insert("path", ":first-child").attr("class", "basic label-container").attr("style", i).attr("d", y);
  return n.attr("transform", `translate(${-o.width / 2}, ${-o.height / 2})`), m.attr("transform", `translate(${-l / 2}, ${-c / 2})`), Z(t, m), t.calcIntersect = function(x, b) {
    return j.rect(x, b);
  }, t.intersect = function(x) {
    return R.info("Cloud intersect", t, x), j.rect(t, x);
  }, s;
}
f(hm, "cloud");
async function cm(e, t) {
  const { labelStyles: r, nodeStyles: i } = V(t);
  t.labelStyle = r;
  const { shapeSvg: s, bbox: o, halfPadding: a, label: n } = await st(
    e,
    t,
    tt(t)
  ), l = o.width + 8 * a, c = o.height + 2 * a, h = 5, u = t.look === "neo" ? `
    M${-l / 2} ${c / 2 - h}
    v${-c + 2 * h}
    q0,-${h} ${h},-${h}
    h${l - 2 * h}
    q${h},0 ${h},${h}
    v${c - h}
    H${-l / 2}
    Z
  ` : `
    M${-l / 2} ${c / 2 - h}
    v${-c + 2 * h}
    q0,-${h} ${h},-${h}
    h${l - 2 * h}
    q${h},0 ${h},${h}
    v${c - 2 * h}
    q0,${h} ${-h},${h}
    h${-(l - 2 * h)}
    q${-h},0 ${-h},${-h}
    Z
  `;
  if (!t.domId)
    throw new Error(
      `defaultMindmapNode: node "${t.id}" is missing a domId — was render.ts domId prefixing skipped?`
    );
  const p = s.append("path").attr("id", t.domId).attr("class", "node-bkg node-" + t.type).attr("style", i).attr("d", u);
  return s.append("line").attr("class", "node-line-").attr("x1", -l / 2).attr("y1", c / 2).attr("x2", l / 2).attr("y2", c / 2), n.attr("transform", `translate(${-o.width / 2}, ${-o.height / 2})`), s.append(() => n.node()), Z(t, p), t.calcIntersect = function(d, g) {
    return j.rect(d, g);
  }, t.intersect = function(d) {
    return j.rect(t, d);
  }, s;
}
f(cm, "defaultMindmapNode");
async function um(e, t) {
  const r = {
    padding: t.padding ?? 0
  };
  return Tl(e, t, r);
}
f(um, "mindmapCircle");
var W_ = [
  {
    semanticName: "Process",
    name: "Rectangle",
    shortName: "rect",
    description: "Standard process shape",
    aliases: ["proc", "process", "rectangle"],
    internalAliases: ["squareRect"],
    handler: Wg
  },
  {
    semanticName: "Event",
    name: "Rounded Rectangle",
    shortName: "rounded",
    description: "Represents an event",
    aliases: ["event"],
    internalAliases: ["roundedRect"],
    handler: Ng
  },
  {
    semanticName: "Terminal Point",
    name: "Stadium",
    shortName: "stadium",
    description: "Terminal point",
    aliases: ["terminal", "pill"],
    handler: Hg
  },
  {
    semanticName: "Subprocess",
    name: "Framed Rectangle",
    shortName: "fr-rect",
    description: "Subprocess",
    aliases: ["subprocess", "subproc", "framed-rectangle", "subroutine"],
    handler: Gg
  },
  {
    semanticName: "Database",
    name: "Cylinder",
    shortName: "cyl",
    description: "Database storage",
    aliases: ["db", "database", "cylinder"],
    handler: dg
  },
  {
    semanticName: "Start",
    name: "Circle",
    shortName: "circle",
    description: "Starting point",
    aliases: ["circ"],
    handler: Tl
  },
  {
    semanticName: "Bang",
    name: "Bang",
    shortName: "bang",
    description: "Bang",
    aliases: ["bang"],
    handler: lm
  },
  {
    semanticName: "Cloud",
    name: "Cloud",
    shortName: "cloud",
    description: "cloud",
    aliases: ["cloud"],
    handler: hm
  },
  {
    semanticName: "Decision",
    name: "Diamond",
    shortName: "diam",
    description: "Decision-making step",
    aliases: ["decision", "diamond", "question"],
    handler: Dg
  },
  {
    semanticName: "Prepare Conditional",
    name: "Hexagon",
    shortName: "hex",
    description: "Preparation or condition step",
    aliases: ["hexagon", "prepare"],
    handler: xg
  },
  {
    semanticName: "Data Input/Output",
    name: "Lean Right",
    shortName: "lean-r",
    description: "Represents input or output",
    aliases: ["lean-right", "in-out"],
    internalAliases: ["lean_right"],
    handler: Fg
  },
  {
    semanticName: "Data Input/Output",
    name: "Lean Left",
    shortName: "lean-l",
    description: "Represents output or input",
    aliases: ["lean-left", "out-in"],
    internalAliases: ["lean_left"],
    handler: Lg
  },
  {
    semanticName: "Priority Action",
    name: "Trapezoid Base Bottom",
    shortName: "trap-b",
    description: "Priority action",
    aliases: ["priority", "trapezoid-bottom", "trapezoid"],
    handler: Qg
  },
  {
    semanticName: "Manual Operation",
    name: "Trapezoid Base Top",
    shortName: "trap-t",
    description: "Represents a manual task",
    aliases: ["manual", "trapezoid-top", "inv-trapezoid"],
    internalAliases: ["inv_trapezoid"],
    handler: vg
  },
  {
    semanticName: "Stop",
    name: "Double Circle",
    shortName: "dbl-circ",
    description: "Represents a stop point",
    aliases: ["double-circle"],
    internalAliases: ["doublecircle"],
    handler: fg
  },
  {
    semanticName: "Text Block",
    name: "Text Block",
    shortName: "text",
    description: "Text block",
    handler: Zg
  },
  {
    semanticName: "Card",
    name: "Notched Rectangle",
    shortName: "notch-rect",
    description: "Represents a card",
    aliases: ["card", "notched-rectangle"],
    handler: sg
  },
  {
    semanticName: "Lined/Shaded Process",
    name: "Lined Rectangle",
    shortName: "lin-rect",
    description: "Lined process shape",
    aliases: ["lined-rectangle", "lined-process", "lin-proc", "shaded-process"],
    handler: qg
  },
  {
    semanticName: "Start",
    name: "Small Circle",
    shortName: "sm-circ",
    description: "Small starting point",
    aliases: ["start", "small-circle"],
    internalAliases: ["stateStart"],
    handler: Ug
  },
  {
    semanticName: "Stop",
    name: "Framed Circle",
    shortName: "fr-circ",
    description: "Stop point",
    aliases: ["stop", "framed-circle"],
    internalAliases: ["stateEnd"],
    handler: jg
  },
  {
    semanticName: "Fork/Join",
    name: "Filled Rectangle",
    shortName: "fork",
    description: "Fork or join in process flow",
    aliases: ["join"],
    internalAliases: ["forkJoin"],
    handler: yg
  },
  {
    semanticName: "Collate",
    name: "Hourglass",
    shortName: "hourglass",
    description: "Represents a collate operation",
    aliases: ["hourglass", "collate"],
    handler: bg
  },
  {
    semanticName: "Comment",
    name: "Curly Brace",
    shortName: "brace",
    description: "Adds a comment",
    aliases: ["comment", "brace-l"],
    handler: lg
  },
  {
    semanticName: "Comment Right",
    name: "Curly Brace",
    shortName: "brace-r",
    description: "Adds a comment",
    handler: hg
  },
  {
    semanticName: "Comment with braces on both sides",
    name: "Curly Braces",
    shortName: "braces",
    description: "Adds a comment",
    handler: cg
  },
  {
    semanticName: "Com Link",
    name: "Lightning Bolt",
    shortName: "bolt",
    description: "Communication link",
    aliases: ["com-link", "lightning-bolt"],
    handler: Ag
  },
  {
    semanticName: "Document",
    name: "Document",
    shortName: "doc",
    description: "Represents a document",
    aliases: ["doc", "document"],
    handler: em
  },
  {
    semanticName: "Delay",
    name: "Half-Rounded Rectangle",
    shortName: "delay",
    description: "Represents a delay",
    aliases: ["half-rounded-rectangle"],
    handler: Cg
  },
  {
    semanticName: "Direct Access Storage",
    name: "Horizontal Cylinder",
    shortName: "h-cyl",
    description: "Direct access storage",
    aliases: ["das", "horizontal-cylinder"],
    handler: Kg
  },
  {
    semanticName: "Disk Storage",
    name: "Lined Cylinder",
    shortName: "lin-cyl",
    description: "Disk storage",
    aliases: ["disk", "lined-cylinder"],
    handler: Mg
  },
  {
    semanticName: "Display",
    name: "Curved Trapezoid",
    shortName: "curv-trap",
    description: "Represents a display",
    aliases: ["curved-trapezoid", "display"],
    handler: ug
  },
  {
    semanticName: "Divided Process",
    name: "Divided Rectangle",
    shortName: "div-rect",
    description: "Divided process shape",
    aliases: ["div-proc", "divided-rectangle", "divided-process"],
    handler: pg
  },
  {
    semanticName: "Extract",
    name: "Triangle",
    shortName: "tri",
    description: "Extraction process",
    aliases: ["extract", "triangle"],
    handler: tm
  },
  {
    semanticName: "Internal Storage",
    name: "Window Pane",
    shortName: "win-pane",
    description: "Internal storage",
    aliases: ["internal-storage", "window-pane"],
    handler: im
  },
  {
    semanticName: "Junction",
    name: "Filled Circle",
    shortName: "f-circ",
    description: "Junction point",
    aliases: ["junction", "filled-circle"],
    handler: gg
  },
  {
    semanticName: "Loop Limit",
    name: "Trapezoidal Pentagon",
    shortName: "notch-pent",
    description: "Loop limit step",
    aliases: ["loop-limit", "notched-pentagon"],
    handler: Jg
  },
  {
    semanticName: "Manual File",
    name: "Flipped Triangle",
    shortName: "flip-tri",
    description: "Manual file operation",
    aliases: ["manual-file", "flipped-triangle"],
    handler: mg
  },
  {
    semanticName: "Manual Input",
    name: "Sloped Rectangle",
    shortName: "sl-rect",
    description: "Manual input step",
    aliases: ["manual-input", "sloped-rectangle"],
    handler: zg
  },
  {
    semanticName: "Multi-Document",
    name: "Stacked Document",
    shortName: "docs",
    description: "Multiple documents",
    aliases: ["documents", "st-doc", "stacked-document"],
    handler: Og
  },
  {
    semanticName: "Multi-Process",
    name: "Stacked Rectangle",
    shortName: "st-rect",
    description: "Multiple processes",
    aliases: ["procs", "processes", "stacked-rectangle"],
    handler: $g
  },
  {
    semanticName: "Stored Data",
    name: "Bow Tie Rectangle",
    shortName: "bow-rect",
    description: "Stored data",
    aliases: ["stored-data", "bow-tie-rectangle"],
    handler: ig
  },
  {
    semanticName: "Summary",
    name: "Crossed Circle",
    shortName: "cross-circ",
    description: "Summary",
    aliases: ["summary", "crossed-circle"],
    handler: ng
  },
  {
    semanticName: "Tagged Document",
    name: "Tagged Document",
    shortName: "tag-doc",
    description: "Tagged document",
    aliases: ["tag-doc", "tagged-document"],
    handler: Vg
  },
  {
    semanticName: "Tagged Process",
    name: "Tagged Rectangle",
    shortName: "tag-rect",
    description: "Tagged process",
    aliases: ["tagged-rectangle", "tag-proc", "tagged-process"],
    handler: Xg
  },
  {
    semanticName: "Paper Tape",
    name: "Flag",
    shortName: "flag",
    description: "Paper tape",
    aliases: ["paper-tape"],
    handler: rm
  },
  {
    semanticName: "Odd",
    name: "Odd",
    shortName: "odd",
    description: "Odd shape",
    internalAliases: ["rect_left_inv_arrow"],
    handler: Pg
  },
  {
    semanticName: "Lined Document",
    name: "Lined Document",
    shortName: "lin-doc",
    description: "Lined document",
    aliases: ["lined-document"],
    handler: Eg
  }
], H_ = /* @__PURE__ */ f(() => {
  const t = [
    ...Object.entries({
      // States
      state: Yg,
      choice: og,
      note: Ig,
      // Rectangles
      rectWithTitle: Rg,
      labelRect: Bg,
      // Icons
      iconSquare: Sg,
      iconCircle: Tg,
      icon: kg,
      iconRounded: wg,
      imageSquare: _g,
      anchor: eg,
      // Kanban diagram
      kanbanItem: nm,
      //Mindmap diagram
      mindmapCircle: um,
      defaultMindmapNode: cm,
      // class diagram
      classBox: om,
      // er diagram
      erBox: wl,
      // Requirement diagram
      requirementBox: am
    }),
    ...W_.flatMap((r) => [
      r.shortName,
      ..."aliases" in r ? r.aliases : [],
      ..."internalAliases" in r ? r.internalAliases : []
    ].map((s) => [s, r.handler]))
  ];
  return Object.fromEntries(t);
}, "generateShapeMap"), dm = H_();
function Y_(e) {
  return e in dm;
}
f(Y_, "isValidShape");
var No = /* @__PURE__ */ new Map();
async function pm(e, t, r) {
  let i, s;
  t.shape === "rect" && (t.rx && t.ry ? t.shape = "roundedRect" : t.shape = "squareRect");
  const o = t.shape ? dm[t.shape] : void 0;
  if (!o)
    throw new Error(`No such shape: ${t.shape}. Please check your syntax.`);
  if (t.link) {
    let a;
    r.config.securityLevel === "sandbox" ? a = "_top" : t.linkTarget && (a = t.linkTarget || "_blank"), i = e.insert("svg:a").attr("xlink:href", t.link).attr("target", a ?? null), s = await o(i, t, r);
  } else
    s = await o(e, t, r), i = s;
  return i.attr("data-look", Dt(t.look)), t.tooltip && s.attr("title", t.tooltip), No.set(t.id, i), t.haveCallback && i.attr("class", i.attr("class") + " clickable"), i;
}
f(pm, "insertNode");
var _A = /* @__PURE__ */ f((e, t) => {
  No.set(t.id, e);
}, "setNodeElem"), vA = /* @__PURE__ */ f(() => {
  No.clear();
}, "clear"), BA = /* @__PURE__ */ f((e) => {
  const t = No.get(e.id);
  R.trace(
    "Transforming node",
    e.diff,
    e,
    "translate(" + (e.x - e.width / 2 - 5) + ", " + e.width / 2 + ")"
  );
  const r = 8, i = e.diff || 0;
  return e.clusterNode ? t.attr(
    "transform",
    "translate(" + (e.x + i - e.width / 2) + ", " + (e.y - e.height / 2 - r) + ")"
  ) : t.attr("transform", "translate(" + e.x + ", " + e.y + ")"), i;
}, "positionNode"), j_ = /* @__PURE__ */ f((e, t, r, i, s, o = !1, a) => {
  t.arrowTypeStart && Bc(
    e,
    "start",
    t.arrowTypeStart,
    r,
    i,
    s,
    o,
    a
  ), t.arrowTypeEnd && Bc(e, "end", t.arrowTypeEnd, r, i, s, o, a);
}, "addEdgeMarkers"), U_ = {
  arrow_cross: { type: "cross", fill: !1 },
  arrow_point: { type: "point", fill: !0 },
  arrow_barb: { type: "barb", fill: !0 },
  arrow_barb_neo: { type: "barb", fill: !0 },
  arrow_circle: { type: "circle", fill: !1 },
  aggregation: { type: "aggregation", fill: !1 },
  extension: { type: "extension", fill: !1 },
  composition: { type: "composition", fill: !0 },
  dependency: { type: "dependency", fill: !0 },
  lollipop: { type: "lollipop", fill: !1 },
  only_one: { type: "onlyOne", fill: !1 },
  zero_or_one: { type: "zeroOrOne", fill: !1 },
  one_or_more: { type: "oneOrMore", fill: !1 },
  zero_or_more: { type: "zeroOrMore", fill: !1 },
  requirement_arrow: { type: "requirement_arrow", fill: !1 },
  requirement_contains: { type: "requirement_contains", fill: !1 }
}, G_ = [
  "cross",
  "point",
  "circle",
  "lollipop",
  "aggregation",
  "extension",
  "composition",
  "dependency",
  "barb"
], Bc = /* @__PURE__ */ f((e, t, r, i, s, o, a = !1, n) => {
  const l = U_[r], c = l && G_.includes(l.type);
  if (!l) {
    R.warn(`Unknown arrow type: ${r}`);
    return;
  }
  const h = l.type, d = `${s}_${o}-${h}${t === "start" ? "Start" : "End"}${a && c ? "-margin" : ""}`;
  if (n && n.trim() !== "") {
    const g = n.replace(/[^\dA-Za-z]/g, "_"), m = `${d}_${g}`;
    if (!document.getElementById(m)) {
      const y = document.getElementById(d);
      if (y) {
        const x = y.cloneNode(!0);
        x.id = m, x.querySelectorAll("path, circle, line").forEach((k) => {
          k.setAttribute("stroke", n), l.fill && k.setAttribute("fill", n);
        }), y.parentNode?.appendChild(x);
      }
    }
    e.attr(`marker-${t}`, `url(${i}#${m})`);
  } else
    e.attr(`marker-${t}`, `url(${i}#${d})`);
}, "addEdgeMarker"), X_ = /* @__PURE__ */ f((e) => typeof e == "string" ? e : gt()?.flowchart?.curve, "resolveEdgeCurveType"), yo = /* @__PURE__ */ new Map(), Nt = /* @__PURE__ */ new Map(), LA = /* @__PURE__ */ f(() => {
  yo.clear(), Nt.clear();
}, "clear"), bi = /* @__PURE__ */ f((e) => e ? typeof e == "string" ? e : e.reduce((t, r) => t + ";" + r, "") : "", "getLabelStyles"), V_ = /* @__PURE__ */ f(async (e, t) => {
  const r = gt();
  let i = Vt(r);
  const { labelStyles: s } = V(t);
  t.labelStyle = s;
  const o = e.insert("g").attr("class", "edgeLabel"), a = o.insert("g").attr("class", "label").attr("data-id", t.id), n = t.labelType === "markdown", c = await Ge(
    e,
    t.label,
    {
      style: bi(t.labelStyle),
      useHtmlLabels: i,
      addSvgBackground: !0,
      isNode: !1,
      markdown: n,
      // Plain text edge labels should auto-wrap, markdown edge labels respect markdownAutoWrap config
      width: n ? void 0 : void 0
    },
    r
  );
  a.node().appendChild(c), R.info("abc82", t, t.labelType);
  let h = c.getBBox(), u = h;
  if (i) {
    const d = c.children[0], g = ct(c);
    h = d.getBoundingClientRect(), u = h, g.attr("width", h.width), g.attr("height", h.height);
  } else {
    const d = ct(c).select("text").node();
    d && typeof d.getBBox == "function" && (u = d.getBBox());
  }
  a.attr("transform", fi(u, i)), yo.set(t.id, o), t.width = h.width, t.height = h.height;
  let p;
  if (t.startLabelLeft) {
    const d = e.insert("g").attr("class", "edgeTerminals"), g = d.insert("g").attr("class", "inner"), m = await Ke(
      g,
      t.startLabelLeft,
      bi(t.labelStyle) || "",
      !1,
      !1
    );
    p = m;
    let y = m.getBBox();
    if (i) {
      const x = m.children[0], b = ct(m);
      y = x.getBoundingClientRect(), b.attr("width", y.width), b.attr("height", y.height);
    }
    g.attr("transform", fi(y, i)), Nt.get(t.id) || Nt.set(t.id, {}), Nt.get(t.id).startLeft = d, Fi(p, t.startLabelLeft);
  }
  if (t.startLabelRight) {
    const d = e.insert("g").attr("class", "edgeTerminals"), g = d.insert("g").attr("class", "inner"), m = await Ke(
      g,
      t.startLabelRight,
      bi(t.labelStyle) || "",
      !1,
      !1
    );
    p = m, g.node().appendChild(m);
    let y = m.getBBox();
    if (i) {
      const x = m.children[0], b = ct(m);
      y = x.getBoundingClientRect(), b.attr("width", y.width), b.attr("height", y.height);
    }
    g.attr("transform", fi(y, i)), Nt.get(t.id) || Nt.set(t.id, {}), Nt.get(t.id).startRight = d, Fi(p, t.startLabelRight);
  }
  if (t.endLabelLeft) {
    const d = e.insert("g").attr("class", "edgeTerminals"), g = d.insert("g").attr("class", "inner"), m = await Ke(
      g,
      t.endLabelLeft,
      bi(t.labelStyle) || "",
      !1,
      !1
    );
    p = m;
    let y = m.getBBox();
    if (i) {
      const x = m.children[0], b = ct(m);
      y = x.getBoundingClientRect(), b.attr("width", y.width), b.attr("height", y.height);
    }
    g.attr("transform", fi(y, i)), d.node().appendChild(m), Nt.get(t.id) || Nt.set(t.id, {}), Nt.get(t.id).endLeft = d, Fi(p, t.endLabelLeft);
  }
  if (t.endLabelRight) {
    const d = e.insert("g").attr("class", "edgeTerminals"), g = d.insert("g").attr("class", "inner"), m = await Ke(
      g,
      t.endLabelRight,
      bi(t.labelStyle) || "",
      !1,
      !1
    );
    p = m;
    let y = m.getBBox();
    if (i) {
      const x = m.children[0], b = ct(m);
      y = x.getBoundingClientRect(), b.attr("width", y.width), b.attr("height", y.height);
    }
    g.attr("transform", fi(y, i)), d.node().appendChild(m), Nt.get(t.id) || Nt.set(t.id, {}), Nt.get(t.id).endRight = d, Fi(p, t.endLabelRight);
  }
  return c;
}, "insertEdgeLabel");
function Fi(e, t) {
  Vt(gt()) && e && (e.style.width = t.length * 9 + "px", e.style.height = "12px");
}
f(Fi, "setTerminalWidth");
var Z_ = /* @__PURE__ */ f((e, t) => {
  R.debug("Moving label abc88 ", e.id, e.label, yo.get(e.id), t);
  let r = t.updatedPath ? t.updatedPath : t.originalPath;
  const i = gt(), { subGraphTitleTotalMargin: s } = hl(i);
  if (e.label) {
    const o = yo.get(e.id);
    let a = e.x, n = e.y;
    if (r) {
      const l = me.calcLabelPosition(r);
      R.debug(
        "Moving label " + e.label + " from (",
        a,
        ",",
        n,
        ") to (",
        l.x,
        ",",
        l.y,
        ") abc88"
      ), t.updatedPath && (a = l.x, n = l.y);
    }
    o.attr("transform", `translate(${a}, ${n + s / 2})`);
  }
  if (e.startLabelLeft) {
    const o = Nt.get(e.id).startLeft;
    let a = e.x, n = e.y;
    if (r) {
      const l = me.calcTerminalLabelPosition(e.arrowTypeStart ? 10 : 0, "start_left", r);
      a = l.x, n = l.y;
    }
    o.attr("transform", `translate(${a}, ${n})`);
  }
  if (e.startLabelRight) {
    const o = Nt.get(e.id).startRight;
    let a = e.x, n = e.y;
    if (r) {
      const l = me.calcTerminalLabelPosition(
        e.arrowTypeStart ? 10 : 0,
        "start_right",
        r
      );
      a = l.x, n = l.y;
    }
    o.attr("transform", `translate(${a}, ${n})`);
  }
  if (e.endLabelLeft) {
    const o = Nt.get(e.id).endLeft;
    let a = e.x, n = e.y;
    if (r) {
      const l = me.calcTerminalLabelPosition(e.arrowTypeEnd ? 10 : 0, "end_left", r);
      a = l.x, n = l.y;
    }
    o.attr("transform", `translate(${a}, ${n})`);
  }
  if (e.endLabelRight) {
    const o = Nt.get(e.id).endRight;
    let a = e.x, n = e.y;
    if (r) {
      const l = me.calcTerminalLabelPosition(e.arrowTypeEnd ? 10 : 0, "end_right", r);
      a = l.x, n = l.y;
    }
    o.attr("transform", `translate(${a}, ${n})`);
  }
}, "positionEdgeLabel"), K_ = /* @__PURE__ */ f((e, t) => {
  const r = e.x, i = e.y, s = Math.abs(t.x - r), o = Math.abs(t.y - i), a = e.width / 2, n = e.height / 2;
  return s >= a || o >= n;
}, "outsideNode"), Q_ = /* @__PURE__ */ f((e, t, r) => {
  R.debug(`intersection calc abc89:
  outsidePoint: ${JSON.stringify(t)}
  insidePoint : ${JSON.stringify(r)}
  node        : x:${e.x} y:${e.y} w:${e.width} h:${e.height}`);
  const i = e.x, s = e.y, o = Math.abs(i - r.x), a = e.width / 2;
  let n = r.x < t.x ? a - o : a + o;
  const l = e.height / 2, c = Math.abs(t.y - r.y), h = Math.abs(t.x - r.x);
  if (Math.abs(s - t.y) * a > Math.abs(i - t.x) * l) {
    let u = r.y < t.y ? t.y - l - s : s - l - t.y;
    n = h * u / c;
    const p = {
      x: r.x < t.x ? r.x + n : r.x - h + n,
      y: r.y < t.y ? r.y + c - u : r.y - c + u
    };
    return n === 0 && (p.x = t.x, p.y = t.y), h === 0 && (p.x = t.x), c === 0 && (p.y = t.y), R.debug(`abc89 top/bottom calc, Q ${c}, q ${u}, R ${h}, r ${n}`, p), p;
  } else {
    r.x < t.x ? n = t.x - a - i : n = i - a - t.x;
    let u = c * n / h, p = r.x < t.x ? r.x + h - n : r.x - h + n, d = r.y < t.y ? r.y + u : r.y - u;
    return R.debug(`sides calc abc89, Q ${c}, q ${u}, R ${h}, r ${n}`, { _x: p, _y: d }), n === 0 && (p = t.x, d = t.y), h === 0 && (p = t.x), c === 0 && (d = t.y), { x: p, y: d };
  }
}, "intersection"), Lc = /* @__PURE__ */ f((e, t) => {
  R.warn("abc88 cutPathAtIntersect", e, t);
  let r = [], i = e[0], s = !1;
  return e.forEach((o) => {
    if (R.info("abc88 checking point", o, t), !K_(t, o) && !s) {
      const a = Q_(t, i, o);
      R.debug("abc88 inside", o, i, a), R.debug("abc88 intersection", a, t);
      let n = !1;
      r.forEach((l) => {
        n = n || l.x === a.x && l.y === a.y;
      }), r.some((l) => l.x === a.x && l.y === a.y) ? R.warn("abc88 no intersect", a, r) : r.push(a), s = !0;
    } else
      R.warn("abc88 outside", o, i), i = o, s || r.push(o);
  }), R.debug("returning points", r), r;
}, "cutPathAtIntersect");
function fm(e) {
  const t = [], r = [];
  for (let i = 1; i < e.length - 1; i++) {
    const s = e[i - 1], o = e[i], a = e[i + 1];
    (s.x === o.x && o.y === a.y && Math.abs(o.x - a.x) > 5 && Math.abs(o.y - s.y) > 5 || s.y === o.y && o.x === a.x && Math.abs(o.x - s.x) > 5 && Math.abs(o.y - a.y) > 5) && (t.push(o), r.push(i));
  }
  return { cornerPoints: t, cornerPointPositions: r };
}
f(fm, "extractCornerPoints");
var Fc = /* @__PURE__ */ f(function(e, t, r) {
  const i = t.x - e.x, s = t.y - e.y, o = Math.sqrt(i * i + s * s), a = r / o;
  return { x: t.x - a * i, y: t.y - a * s };
}, "findAdjacentPoint"), J_ = /* @__PURE__ */ f(function(e) {
  const { cornerPointPositions: t } = fm(e), r = [];
  for (let i = 0; i < e.length; i++)
    if (t.includes(i)) {
      const s = e[i - 1], o = e[i + 1], a = e[i], n = Fc(s, a, 5), l = Fc(o, a, 5), c = l.x - n.x, h = l.y - n.y;
      r.push(n);
      const u = Math.sqrt(2) * 2;
      let p = { x: a.x, y: a.y };
      if (Math.abs(o.x - s.x) > 10 && Math.abs(o.y - s.y) >= 10) {
        R.debug(
          "Corner point fixing",
          Math.abs(o.x - s.x),
          Math.abs(o.y - s.y)
        );
        const d = 5;
        a.x === n.x ? p = {
          x: c < 0 ? n.x - d + u : n.x + d - u,
          y: h < 0 ? n.y - u : n.y + u
        } : p = {
          x: c < 0 ? n.x - u : n.x + u,
          y: h < 0 ? n.y - d + u : n.y + d - u
        };
      } else
        R.debug(
          "Corner point skipping fixing",
          Math.abs(o.x - s.x),
          Math.abs(o.y - s.y)
        );
      r.push(p, l);
    } else
      r.push(e[i]);
  return r;
}, "fixCorners"), tv = /* @__PURE__ */ f((e, t, r) => {
  const i = e - t - r, s = 2, o = 2, a = s + o, n = Math.floor(i / a), l = Array(n).fill(`${s} ${o}`).join(" ");
  return `0 ${t} ${l} ${r}`;
}, "generateDashArray"), ev = /* @__PURE__ */ f(function(e, t, r, i, s, o, a, n = !1) {
  if (!a)
    throw new Error(
      `insertEdge: missing diagramId for edge "${t.id}" — edge IDs require a diagram prefix for uniqueness`
    );
  const { handDrawnSeed: l } = gt();
  let c = t.points, h = !1;
  const u = s;
  var p = o;
  const d = [];
  for (const E in t.cssCompiledStyles)
    pf(E) || d.push(t.cssCompiledStyles[E]);
  R.debug("UIO intersect check", t.points, p.x, u.x), p.intersect && u.intersect && !n && (c = c.slice(1, t.points.length - 1), c.unshift(u.intersect(c[0])), R.debug(
    "Last point UIO",
    t.start,
    "-->",
    t.end,
    c[c.length - 1],
    p,
    p.intersect(c[c.length - 1])
  ), c.push(p.intersect(c[c.length - 1])));
  const g = btoa(JSON.stringify(c));
  t.toCluster && (R.info("to cluster abc88", r.get(t.toCluster)), c = Lc(t.points, r.get(t.toCluster).node), h = !0), t.fromCluster && (R.debug(
    "from cluster abc88",
    r.get(t.fromCluster),
    JSON.stringify(c, null, 2)
  ), c = Lc(c.reverse(), r.get(t.fromCluster).node).reverse(), h = !0);
  let m = c.filter((E) => !Number.isNaN(E.y));
  const y = X_(t.curve);
  y !== "rounded" && (m = J_(m));
  let x = $i;
  switch (y) {
    case "linear":
      x = $i;
      break;
    case "basis":
      x = Na;
      break;
    case "cardinal":
      x = Uu;
      break;
    case "bumpX":
      x = zu;
      break;
    case "bumpY":
      x = Wu;
      break;
    case "catmullRom":
      x = Xu;
      break;
    case "monotoneX":
      x = td;
      break;
    case "monotoneY":
      x = ed;
      break;
    case "natural":
      x = id;
      break;
    case "step":
      x = sd;
      break;
    case "stepAfter":
      x = ad;
      break;
    case "stepBefore":
      x = od;
      break;
    case "rounded":
      x = $i;
      break;
    default:
      x = Na;
  }
  const { x: b, y: k } = Vk(t), w = E1().x(b).y(k).curve(x);
  let S;
  switch (t.thickness) {
    case "normal":
      S = "edge-thickness-normal";
      break;
    case "thick":
      S = "edge-thickness-thick";
      break;
    case "invisible":
      S = "edge-thickness-invisible";
      break;
    default:
      S = "edge-thickness-normal";
  }
  switch (t.pattern) {
    case "solid":
      S += " edge-pattern-solid";
      break;
    case "dotted":
      S += " edge-pattern-dotted";
      break;
    case "dashed":
      S += " edge-pattern-dashed";
      break;
    default:
      S += " edge-pattern-solid";
  }
  let v, M = y === "rounded" ? gm(mm(m, t), 5) : w(m);
  const B = Array.isArray(t.style) ? t.style : [t.style];
  let N = B.find((E) => E?.startsWith("stroke:")), D = "";
  t.animate && (D = "edge-animation-fast"), t.animation && (D = "edge-animation-" + t.animation);
  let O = !1;
  if (t.look === "handDrawn") {
    const E = U.svg(e);
    Object.assign([], m);
    const P = E.path(M, {
      roughness: 0.3,
      seed: l
    });
    S += " transition", v = ct(P).select("path").attr("id", `${a}-${t.id}`).attr(
      "class",
      " " + S + (t.classes ? " " + t.classes : "") + (D ? " " + D : "")
    ).attr("style", B ? B.reduce((Y, Q) => Y + ";" + Q, "") : "");
    let H = v.attr("d");
    v.attr("d", H), e.node().appendChild(v.node());
  } else {
    const E = d.join(";"), P = B ? B.reduce((ut, it) => ut + it + ";", "") : "", H = (E ? E + ";" + P + ";" : P) + ";" + (B ? B.reduce((ut, it) => ut + ";" + it, "") : "");
    v = e.append("path").attr("d", M).attr("id", `${a}-${t.id}`).attr(
      "class",
      " " + S + (t.classes ? " " + t.classes : "") + (D ? " " + D : "")
    ).attr("style", H), N = H.match(/stroke:([^;]+)/)?.[1], O = t.animate === !0 || !!t.animation || E.includes("animation");
    const Y = v.node(), Q = typeof Y.getTotalLength == "function" ? Y.getTotalLength() : 0, dt = $h[t.arrowTypeStart] || 0, et = $h[t.arrowTypeEnd] || 0;
    if (t.look === "neo" && !O) {
      const it = `stroke-dasharray: ${t.pattern === "dotted" || t.pattern === "dashed" ? tv(Q, dt, et) : `0 ${dt} ${Q - dt - et} ${et}`}; stroke-dashoffset: 0;`;
      v.attr("style", it + v.attr("style"));
    }
  }
  v.attr("data-edge", !0), v.attr("data-et", "edge"), v.attr("data-id", t.id), v.attr("data-points", g), v.attr("data-look", Dt(t.look)), t.showPoints && m.forEach((E) => {
    e.append("circle").style("stroke", "red").style("fill", "red").attr("r", 1).attr("cx", E.x).attr("cy", E.y);
  });
  let W = "";
  (gt().flowchart.arrowMarkerAbsolute || gt().state.arrowMarkerAbsolute) && (W = window.location.protocol + "//" + window.location.host + window.location.pathname + window.location.search, W = W.replace(/\(/g, "\\(").replace(/\)/g, "\\)")), R.info("arrowTypeStart", t.arrowTypeStart), R.info("arrowTypeEnd", t.arrowTypeEnd);
  const z = !O && t?.look === "neo";
  j_(v, t, W, a, i, z, N);
  const I = Math.floor(c.length / 2), F = c[I];
  me.isLabelCoordinateInPath(F, v.attr("d")) || (h = !0);
  let L = {};
  return h && (L.updatedPath = c), L.originalPath = t.points, L;
}, "insertEdge");
function gm(e, t) {
  if (e.length < 2)
    return "";
  let r = "";
  const i = e.length, s = 1e-5;
  for (let o = 0; o < i; o++) {
    const a = e[o], n = e[o - 1], l = e[o + 1];
    if (o === 0)
      r += `M${a.x},${a.y}`;
    else if (o === i - 1)
      r += `L${a.x},${a.y}`;
    else {
      const c = a.x - n.x, h = a.y - n.y, u = l.x - a.x, p = l.y - a.y, d = Math.hypot(c, h), g = Math.hypot(u, p);
      if (d < s || g < s) {
        r += `L${a.x},${a.y}`;
        continue;
      }
      const m = c / d, y = h / d, x = u / g, b = p / g, k = m * x + y * b, w = Math.max(-1, Math.min(1, k)), S = Math.acos(w);
      if (S < s || Math.abs(Math.PI - S) < s) {
        r += `L${a.x},${a.y}`;
        continue;
      }
      const v = Math.min(t / Math.sin(S / 2), d / 2, g / 2), M = a.x - m * v, B = a.y - y * v, N = a.x + x * v, D = a.y + b * v;
      r += `L${M},${B}`, r += `Q${a.x},${a.y} ${N},${D}`;
    }
  }
  return r;
}
f(gm, "generateRoundedPath");
function mn(e, t) {
  if (!e || !t)
    return { angle: 0, deltaX: 0, deltaY: 0 };
  const r = t.x - e.x, i = t.y - e.y;
  return { angle: Math.atan2(i, r), deltaX: r, deltaY: i };
}
f(mn, "calculateDeltaAndAngle");
function mm(e, t) {
  const r = e.map((s) => ({ ...s }));
  if (e.length >= 2 && Wt[t.arrowTypeStart]) {
    const s = Wt[t.arrowTypeStart], o = e[0], a = e[1], { angle: n } = mn(o, a), l = s * Math.cos(n), c = s * Math.sin(n);
    r[0].x = o.x + l, r[0].y = o.y + c;
  }
  const i = e.length;
  if (i >= 2 && Wt[t.arrowTypeEnd]) {
    const s = Wt[t.arrowTypeEnd], o = e[i - 1], a = e[i - 2], { angle: n } = mn(a, o), l = s * Math.cos(n), c = s * Math.sin(n);
    r[i - 1].x = o.x - l, r[i - 1].y = o.y - c;
  }
  return r;
}
f(mm, "applyMarkerOffsetsToPoints");
var rv = /* @__PURE__ */ f((e, t, r, i) => {
  t.forEach((s) => {
    _v[s](e, r, i);
  });
}, "insertMarkers"), iv = /* @__PURE__ */ f((e, t, r) => {
  R.trace("Making markers for ", r), e.append("defs").append("marker").attr("id", r + "_" + t + "-extensionStart").attr("class", "marker extension " + t).attr("refX", 18).attr("refY", 7).attr("markerWidth", 190).attr("markerHeight", 240).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").append("path").attr("d", "M 1,7 L18,13 V 1 Z"), e.append("defs").append("marker").attr("id", r + "_" + t + "-extensionEnd").attr("class", "marker extension " + t).attr("refX", 1).attr("refY", 7).attr("markerWidth", 20).attr("markerHeight", 28).attr("orient", "auto").append("path").attr("d", "M 1,1 V 13 L18,7 Z"), e.append("marker").attr("id", r + "_" + t + "-extensionStart-margin").attr("class", "marker extension " + t).attr("refX", 18).attr("refY", 7).attr("markerWidth", 20).attr("markerHeight", 28).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").attr("viewBox", "0 0 20 14").append("polygon").attr("points", "10,7 18,13 18,1").style("stroke-width", 2).style("stroke-dasharray", "0"), e.append("defs").append("marker").attr("id", r + "_" + t + "-extensionEnd-margin").attr("class", "marker extension " + t).attr("refX", 9).attr("refY", 7).attr("markerWidth", 20).attr("markerHeight", 28).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").attr("viewBox", "0 0 20 14").append("polygon").attr("points", "10,1 10,13 18,7").style("stroke-width", 2).style("stroke-dasharray", "0");
}, "extension"), sv = /* @__PURE__ */ f((e, t, r) => {
  e.append("defs").append("marker").attr("id", r + "_" + t + "-compositionStart").attr("class", "marker composition " + t).attr("refX", 18).attr("refY", 7).attr("markerWidth", 190).attr("markerHeight", 240).attr("orient", "auto").append("path").attr("d", "M 18,7 L9,13 L1,7 L9,1 Z"), e.append("defs").append("marker").attr("id", r + "_" + t + "-compositionEnd").attr("class", "marker composition " + t).attr("refX", 1).attr("refY", 7).attr("markerWidth", 20).attr("markerHeight", 28).attr("orient", "auto").append("path").attr("d", "M 18,7 L9,13 L1,7 L9,1 Z"), e.append("defs").append("marker").attr("id", r + "_" + t + "-compositionStart-margin").attr("class", "marker composition " + t).attr("refX", 15).attr("refY", 7).attr("markerWidth", 190).attr("markerHeight", 240).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").append("path").style("stroke-width", 0).attr("viewBox", "0 0 15 15").attr("d", "M 18,7 L9,13 L1,7 L9,1 Z"), e.append("defs").append("marker").attr("id", r + "_" + t + "-compositionEnd-margin").attr("class", "marker composition " + t).attr("refX", 3.5).attr("refY", 7).attr("markerWidth", 20).attr("markerHeight", 28).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").append("path").style("stroke-width", 0).attr("d", "M 18,7 L9,13 L1,7 L9,1 Z");
}, "composition"), ov = /* @__PURE__ */ f((e, t, r) => {
  e.append("defs").append("marker").attr("id", r + "_" + t + "-aggregationStart").attr("class", "marker aggregation " + t).attr("refX", 18).attr("refY", 7).attr("markerWidth", 190).attr("markerHeight", 240).attr("orient", "auto").append("path").attr("d", "M 18,7 L9,13 L1,7 L9,1 Z"), e.append("defs").append("marker").attr("id", r + "_" + t + "-aggregationEnd").attr("class", "marker aggregation " + t).attr("refX", 1).attr("refY", 7).attr("markerWidth", 20).attr("markerHeight", 28).attr("orient", "auto").append("path").attr("d", "M 18,7 L9,13 L1,7 L9,1 Z"), e.append("defs").append("marker").attr("id", r + "_" + t + "-aggregationStart-margin").attr("class", "marker aggregation " + t).attr("refX", 15).attr("refY", 7).attr("markerWidth", 190).attr("markerHeight", 240).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").append("path").style("stroke-width", 2).attr("d", "M 18,7 L9,13 L1,7 L9,1 Z"), e.append("defs").append("marker").attr("id", r + "_" + t + "-aggregationEnd-margin").attr("class", "marker aggregation " + t).attr("refX", 1).attr("refY", 7).attr("markerWidth", 20).attr("markerHeight", 28).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").append("path").style("stroke-width", 2).attr("d", "M 18,7 L9,13 L1,7 L9,1 Z");
}, "aggregation"), av = /* @__PURE__ */ f((e, t, r) => {
  e.append("defs").append("marker").attr("id", r + "_" + t + "-dependencyStart").attr("class", "marker dependency " + t).attr("refX", 6).attr("refY", 7).attr("markerWidth", 190).attr("markerHeight", 240).attr("orient", "auto").append("path").attr("d", "M 5,7 L9,13 L1,7 L9,1 Z"), e.append("defs").append("marker").attr("id", r + "_" + t + "-dependencyEnd").attr("class", "marker dependency " + t).attr("refX", 13).attr("refY", 7).attr("markerWidth", 20).attr("markerHeight", 28).attr("orient", "auto").append("path").attr("d", "M 18,7 L9,13 L14,7 L9,1 Z"), e.append("defs").append("marker").attr("id", r + "_" + t + "-dependencyStart-margin").attr("class", "marker dependency " + t).attr("refX", 4).attr("refY", 7).attr("markerWidth", 190).attr("markerHeight", 240).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").append("path").style("stroke-width", 0).attr("d", "M 5,7 L9,13 L1,7 L9,1 Z"), e.append("defs").append("marker").attr("id", r + "_" + t + "-dependencyEnd-margin").attr("class", "marker dependency " + t).attr("refX", 16).attr("refY", 7).attr("markerWidth", 20).attr("markerHeight", 28).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").append("path").style("stroke-width", 0).attr("d", "M 18,7 L9,13 L14,7 L9,1 Z");
}, "dependency"), nv = /* @__PURE__ */ f((e, t, r) => {
  e.append("defs").append("marker").attr("id", r + "_" + t + "-lollipopStart").attr("class", "marker lollipop " + t).attr("refX", 13).attr("refY", 7).attr("markerWidth", 190).attr("markerHeight", 240).attr("orient", "auto").append("circle").attr("fill", "transparent").attr("cx", 7).attr("cy", 7).attr("r", 6), e.append("defs").append("marker").attr("id", r + "_" + t + "-lollipopEnd").attr("class", "marker lollipop " + t).attr("refX", 1).attr("refY", 7).attr("markerWidth", 190).attr("markerHeight", 240).attr("orient", "auto").append("circle").attr("fill", "transparent").attr("cx", 7).attr("cy", 7).attr("r", 6), e.append("defs").append("marker").attr("id", r + "_" + t + "-lollipopStart-margin").attr("class", "marker lollipop " + t).attr("refX", 13).attr("refY", 7).attr("markerWidth", 190).attr("markerHeight", 240).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").append("circle").attr("fill", "transparent").attr("cx", 7).attr("cy", 7).attr("r", 6).attr("stroke-width", 2), e.append("defs").append("marker").attr("id", r + "_" + t + "-lollipopEnd-margin").attr("class", "marker lollipop " + t).attr("refX", 1).attr("refY", 7).attr("markerWidth", 190).attr("markerHeight", 240).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").append("circle").attr("fill", "transparent").attr("cx", 7).attr("cy", 7).attr("r", 6).attr("stroke-width", 2);
}, "lollipop"), lv = /* @__PURE__ */ f((e, t, r) => {
  e.append("marker").attr("id", r + "_" + t + "-pointEnd").attr("class", "marker " + t).attr("viewBox", "0 0 10 10").attr("refX", 5).attr("refY", 5).attr("markerUnits", "userSpaceOnUse").attr("markerWidth", 8).attr("markerHeight", 8).attr("orient", "auto").append("path").attr("d", "M 0 0 L 10 5 L 0 10 z").attr("class", "arrowMarkerPath").style("stroke-width", 1).style("stroke-dasharray", "1,0"), e.append("marker").attr("id", r + "_" + t + "-pointStart").attr("class", "marker " + t).attr("viewBox", "0 0 10 10").attr("refX", 4.5).attr("refY", 5).attr("markerUnits", "userSpaceOnUse").attr("markerWidth", 8).attr("markerHeight", 8).attr("orient", "auto").append("path").attr("d", "M 0 5 L 10 10 L 10 0 z").attr("class", "arrowMarkerPath").style("stroke-width", 1).style("stroke-dasharray", "1,0"), e.append("marker").attr("id", r + "_" + t + "-pointEnd-margin").attr("class", "marker " + t).attr("viewBox", "0 0 11.5 14").attr("refX", 11.5).attr("refY", 7).attr("markerUnits", "userSpaceOnUse").attr("markerWidth", 10.5).attr("markerHeight", 14).attr("orient", "auto").append("path").attr("d", "M 0 0 L 11.5 7 L 0 14 z").attr("class", "arrowMarkerPath").style("stroke-width", 0).style("stroke-dasharray", "1,0"), e.append("marker").attr("id", r + "_" + t + "-pointStart-margin").attr("class", "marker " + t).attr("viewBox", "0 0 11.5 14").attr("refX", 1).attr("refY", 7).attr("markerUnits", "userSpaceOnUse").attr("markerWidth", 11.5).attr("markerHeight", 14).attr("orient", "auto").append("polygon").attr("points", "0,7 11.5,14 11.5,0").attr("class", "arrowMarkerPath").style("stroke-width", 0).style("stroke-dasharray", "1,0");
}, "point"), hv = /* @__PURE__ */ f((e, t, r) => {
  e.append("marker").attr("id", r + "_" + t + "-circleEnd").attr("class", "marker " + t).attr("viewBox", "0 0 10 10").attr("refX", 11).attr("refY", 5).attr("markerUnits", "userSpaceOnUse").attr("markerWidth", 11).attr("markerHeight", 11).attr("orient", "auto").append("circle").attr("cx", "5").attr("cy", "5").attr("r", "5").attr("class", "arrowMarkerPath").style("stroke-width", 1).style("stroke-dasharray", "1,0"), e.append("marker").attr("id", r + "_" + t + "-circleStart").attr("class", "marker " + t).attr("viewBox", "0 0 10 10").attr("refX", -1).attr("refY", 5).attr("markerUnits", "userSpaceOnUse").attr("markerWidth", 11).attr("markerHeight", 11).attr("orient", "auto").append("circle").attr("cx", "5").attr("cy", "5").attr("r", "5").attr("class", "arrowMarkerPath").style("stroke-width", 1).style("stroke-dasharray", "1,0"), e.append("marker").attr("id", r + "_" + t + "-circleEnd-margin").attr("class", "marker " + t).attr("viewBox", "0 0 10 10").attr("refY", 5).attr("refX", 12.25).attr("markerUnits", "userSpaceOnUse").attr("markerWidth", 14).attr("markerHeight", 14).attr("orient", "auto").append("circle").attr("cx", "5").attr("cy", "5").attr("r", "5").attr("class", "arrowMarkerPath").style("stroke-width", 0).style("stroke-dasharray", "1,0"), e.append("marker").attr("id", r + "_" + t + "-circleStart-margin").attr("class", "marker " + t).attr("viewBox", "0 0 10 10").attr("refX", -2).attr("refY", 5).attr("markerUnits", "userSpaceOnUse").attr("markerWidth", 14).attr("markerHeight", 14).attr("orient", "auto").append("circle").attr("cx", "5").attr("cy", "5").attr("r", "5").attr("class", "arrowMarkerPath").style("stroke-width", 0).style("stroke-dasharray", "1,0");
}, "circle"), cv = /* @__PURE__ */ f((e, t, r) => {
  e.append("marker").attr("id", r + "_" + t + "-crossEnd").attr("class", "marker cross " + t).attr("viewBox", "0 0 11 11").attr("refX", 12).attr("refY", 5.2).attr("markerUnits", "userSpaceOnUse").attr("markerWidth", 11).attr("markerHeight", 11).attr("orient", "auto").append("path").attr("d", "M 1,1 l 9,9 M 10,1 l -9,9").attr("class", "arrowMarkerPath").style("stroke-width", 2).style("stroke-dasharray", "1,0"), e.append("marker").attr("id", r + "_" + t + "-crossStart").attr("class", "marker cross " + t).attr("viewBox", "0 0 11 11").attr("refX", -1).attr("refY", 5.2).attr("markerUnits", "userSpaceOnUse").attr("markerWidth", 11).attr("markerHeight", 11).attr("orient", "auto").append("path").attr("d", "M 1,1 l 9,9 M 10,1 l -9,9").attr("class", "arrowMarkerPath").style("stroke-width", 2).style("stroke-dasharray", "1,0"), e.append("marker").attr("id", r + "_" + t + "-crossEnd-margin").attr("class", "marker cross " + t).attr("viewBox", "0 0 15 15").attr("refX", 17.7).attr("refY", 7.5).attr("markerUnits", "userSpaceOnUse").attr("markerWidth", 12).attr("markerHeight", 12).attr("orient", "auto").append("path").attr("d", "M 1,1 L 14,14 M 1,14 L 14,1").attr("class", "arrowMarkerPath").style("stroke-width", 2.5), e.append("marker").attr("id", r + "_" + t + "-crossStart-margin").attr("class", "marker cross " + t).attr("viewBox", "0 0 15 15").attr("refX", -3.5).attr("refY", 7.5).attr("markerUnits", "userSpaceOnUse").attr("markerWidth", 12).attr("markerHeight", 12).attr("orient", "auto").append("path").attr("d", "M 1,1 L 14,14 M 1,14 L 14,1").attr("class", "arrowMarkerPath").style("stroke-width", 2.5).style("stroke-dasharray", "1,0");
}, "cross"), uv = /* @__PURE__ */ f((e, t, r) => {
  e.append("defs").append("marker").attr("id", r + "_" + t + "-barbEnd").attr("refX", 19).attr("refY", 7).attr("markerWidth", 20).attr("markerHeight", 14).attr("markerUnits", "userSpaceOnUse").attr("orient", "auto").append("path").attr("d", "M 19,7 L9,13 L14,7 L9,1 Z");
}, "barb"), dv = /* @__PURE__ */ f((e, t, r) => {
  const i = wt(), { themeVariables: s } = i, { transitionColor: o } = s;
  e.append("defs").append("marker").attr("id", r + "_" + t + "-barbEnd").attr("refX", 19).attr("refY", 7).attr("markerWidth", 20).attr("markerHeight", 14).attr("markerUnits", "strokeWidth").attr("orient", "auto").append("path").attr("d", "M 19,7 L11,14 L13,7 L11,0 Z"), e.append("defs").append("marker").attr("id", r + "_" + t + "-barbEnd-margin").attr("refX", 17).attr("refY", 7).attr("markerWidth", 20).attr("markerHeight", 14).attr("markerUnits", "userSpaceOnUse").attr("orient", "auto").append("path").attr("d", "M 19,7 L11,14 L13,7 L11,0 Z").attr("fill", `${o}`);
}, "barbNeo"), pv = /* @__PURE__ */ f((e, t, r) => {
  e.append("defs").append("marker").attr("id", r + "_" + t + "-onlyOneStart").attr("class", "marker onlyOne " + t).attr("refX", 0).attr("refY", 9).attr("markerWidth", 18).attr("markerHeight", 18).attr("orient", "auto").append("path").attr("d", "M9,0 L9,18 M15,0 L15,18"), e.append("defs").append("marker").attr("id", r + "_" + t + "-onlyOneEnd").attr("class", "marker onlyOne " + t).attr("refX", 18).attr("refY", 9).attr("markerWidth", 18).attr("markerHeight", 18).attr("orient", "auto").append("path").attr("d", "M3,0 L3,18 M9,0 L9,18");
}, "only_one"), fv = /* @__PURE__ */ f((e, t, r) => {
  const i = e.append("defs").append("marker").attr("id", r + "_" + t + "-zeroOrOneStart").attr("class", "marker zeroOrOne " + t).attr("refX", 0).attr("refY", 9).attr("markerWidth", 30).attr("markerHeight", 18).attr("orient", "auto");
  i.append("circle").attr("fill", "white").attr("cx", 21).attr("cy", 9).attr("r", 6), i.append("path").attr("d", "M9,0 L9,18");
  const s = e.append("defs").append("marker").attr("id", r + "_" + t + "-zeroOrOneEnd").attr("class", "marker zeroOrOne " + t).attr("refX", 30).attr("refY", 9).attr("markerWidth", 30).attr("markerHeight", 18).attr("orient", "auto");
  s.append("circle").attr("fill", "white").attr("cx", 9).attr("cy", 9).attr("r", 6), s.append("path").attr("d", "M21,0 L21,18");
}, "zero_or_one"), gv = /* @__PURE__ */ f((e, t, r) => {
  e.append("defs").append("marker").attr("id", r + "_" + t + "-oneOrMoreStart").attr("class", "marker oneOrMore " + t).attr("refX", 18).attr("refY", 18).attr("markerWidth", 45).attr("markerHeight", 36).attr("orient", "auto").append("path").attr("d", "M0,18 Q 18,0 36,18 Q 18,36 0,18 M42,9 L42,27"), e.append("defs").append("marker").attr("id", r + "_" + t + "-oneOrMoreEnd").attr("class", "marker oneOrMore " + t).attr("refX", 27).attr("refY", 18).attr("markerWidth", 45).attr("markerHeight", 36).attr("orient", "auto").append("path").attr("d", "M3,9 L3,27 M9,18 Q27,0 45,18 Q27,36 9,18");
}, "one_or_more"), mv = /* @__PURE__ */ f((e, t, r) => {
  const i = e.append("defs").append("marker").attr("id", r + "_" + t + "-zeroOrMoreStart").attr("class", "marker zeroOrMore " + t).attr("refX", 18).attr("refY", 18).attr("markerWidth", 57).attr("markerHeight", 36).attr("orient", "auto");
  i.append("circle").attr("fill", "white").attr("cx", 48).attr("cy", 18).attr("r", 6), i.append("path").attr("d", "M0,18 Q18,0 36,18 Q18,36 0,18");
  const s = e.append("defs").append("marker").attr("id", r + "_" + t + "-zeroOrMoreEnd").attr("class", "marker zeroOrMore " + t).attr("refX", 39).attr("refY", 18).attr("markerWidth", 57).attr("markerHeight", 36).attr("orient", "auto");
  s.append("circle").attr("fill", "white").attr("cx", 9).attr("cy", 18).attr("r", 6), s.append("path").attr("d", "M21,18 Q39,0 57,18 Q39,36 21,18");
}, "zero_or_more"), yv = /* @__PURE__ */ f((e, t, r) => {
  const i = wt(), { themeVariables: s } = i, { strokeWidth: o } = s;
  e.append("defs").append("marker").attr("id", r + "_" + t + "-onlyOneStart").attr("class", "marker onlyOne " + t).attr("refX", 0).attr("refY", 9).attr("markerWidth", 18).attr("markerHeight", 18).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").append("path").attr("d", "M9,0 L9,18 M15,0 L15,18").attr("stroke-width", `${o}`), e.append("defs").append("marker").attr("id", r + "_" + t + "-onlyOneEnd").attr("class", "marker onlyOne " + t).attr("refX", 18).attr("refY", 9).attr("markerWidth", 18).attr("markerHeight", 18).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").append("path").attr("d", "M3,0 L3,18 M9,0 L9,18").attr("stroke-width", `${o}`);
}, "only_one_neo"), Cv = /* @__PURE__ */ f((e, t, r) => {
  const i = wt(), { themeVariables: s } = i, { strokeWidth: o, mainBkg: a } = s, n = e.append("defs").append("marker").attr("id", r + "_" + t + "-zeroOrOneStart").attr("class", "marker zeroOrOne " + t).attr("refX", 0).attr("refY", 9).attr("markerWidth", 30).attr("markerHeight", 18).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse");
  n.append("circle").attr("fill", a ?? "white").attr("cx", 21).attr("cy", 9).attr("stroke-width", `${o}`).attr("r", 6), n.append("path").attr("d", "M9,0 L9,18").attr("stroke-width", `${o}`);
  const l = e.append("defs").append("marker").attr("id", r + "_" + t + "-zeroOrOneEnd").attr("class", "marker zeroOrOne " + t).attr("refX", 30).attr("refY", 9).attr("markerWidth", 30).attr("markerHeight", 18).attr("markerUnits", "userSpaceOnUse").attr("orient", "auto");
  l.append("circle").attr("fill", a ?? "white").attr("cx", 9).attr("cy", 9).attr("stroke-width", `${o}`).attr("r", 6), l.append("path").attr("d", "M21,0 L21,18").attr("stroke-width", `${o}`);
}, "zero_or_one_neo"), xv = /* @__PURE__ */ f((e, t, r) => {
  const i = wt(), { themeVariables: s } = i, { strokeWidth: o } = s;
  e.append("defs").append("marker").attr("id", r + "_" + t + "-oneOrMoreStart").attr("class", "marker oneOrMore " + t).attr("refX", 18).attr("refY", 18).attr("markerWidth", 45).attr("markerHeight", 36).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").append("path").attr("d", "M0,18 Q 18,0 36,18 Q 18,36 0,18 M42,9 L42,27").attr("stroke-width", `${o}`), e.append("defs").append("marker").attr("id", r + "_" + t + "-oneOrMoreEnd").attr("class", "marker oneOrMore " + t).attr("refX", 27).attr("refY", 18).attr("markerWidth", 45).attr("markerHeight", 36).attr("markerUnits", "userSpaceOnUse").attr("orient", "auto").append("path").attr("d", "M3,9 L3,27 M9,18 Q27,0 45,18 Q27,36 9,18").attr("stroke-width", `${o}`);
}, "one_or_more_neo"), bv = /* @__PURE__ */ f((e, t, r) => {
  const i = wt(), { themeVariables: s } = i, { strokeWidth: o, mainBkg: a } = s, n = e.append("defs").append("marker").attr("id", r + "_" + t + "-zeroOrMoreStart").attr("class", "marker zeroOrMore " + t).attr("refX", 18).attr("refY", 18).attr("markerWidth", 57).attr("markerHeight", 36).attr("markerUnits", "userSpaceOnUse").attr("orient", "auto");
  n.append("circle").attr("fill", a ?? "white").attr("cx", 45.5).attr("cy", 18).attr("r", 6).attr("stroke-width", `${o}`), n.append("path").attr("d", "M0,18 Q18,0 36,18 Q18,36 0,18").attr("stroke-width", `${o}`);
  const l = e.append("defs").append("marker").attr("id", r + "_" + t + "-zeroOrMoreEnd").attr("class", "marker zeroOrMore " + t).attr("refX", 39).attr("refY", 18).attr("markerWidth", 57).attr("markerHeight", 36).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse");
  l.append("circle").attr("fill", a ?? "white").attr("cx", 11).attr("cy", 18).attr("r", 6).attr("stroke-width", `${o}`), l.append("path").attr("d", "M21,18 Q39,0 57,18 Q39,36 21,18").attr("stroke-width", `${o}`);
}, "zero_or_more_neo"), kv = /* @__PURE__ */ f((e, t, r) => {
  e.append("defs").append("marker").attr("id", r + "_" + t + "-requirement_arrowEnd").attr("refX", 20).attr("refY", 10).attr("markerWidth", 20).attr("markerHeight", 20).attr("orient", "auto").append("path").attr(
    "d",
    `M0,0
      L20,10
      M20,10
      L0,20`
  );
}, "requirement_arrow"), Tv = /* @__PURE__ */ f((e, t, r) => {
  const i = wt(), { themeVariables: s } = i, { strokeWidth: o } = s;
  e.append("defs").append("marker").attr("id", r + "_" + t + "-requirement_arrowEnd").attr("refX", 20).attr("refY", 10).attr("markerWidth", 20).attr("markerHeight", 20).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").attr("stroke-width", `${o}`).attr("viewBox", "0 0 25 20").append("path").attr(
    "d",
    `M0,0
      L20,10
      M20,10
      L0,20`
  ).attr("stroke-linejoin", "miter");
}, "requirement_arrow_neo"), wv = /* @__PURE__ */ f((e, t, r) => {
  const i = e.append("defs").append("marker").attr("id", r + "_" + t + "-requirement_containsStart").attr("refX", 0).attr("refY", 10).attr("markerWidth", 20).attr("markerHeight", 20).attr("orient", "auto").append("g");
  i.append("circle").attr("cx", 10).attr("cy", 10).attr("r", 9).attr("fill", "none"), i.append("line").attr("x1", 1).attr("x2", 19).attr("y1", 10).attr("y2", 10), i.append("line").attr("y1", 1).attr("y2", 19).attr("x1", 10).attr("x2", 10);
}, "requirement_contains"), Sv = /* @__PURE__ */ f((e, t, r) => {
  const i = wt(), { themeVariables: s } = i, { strokeWidth: o } = s, a = e.append("defs").append("marker").attr("id", r + "_" + t + "-requirement_containsStart").attr("refX", 0).attr("refY", 10).attr("markerWidth", 20).attr("markerHeight", 20).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").append("g");
  a.append("circle").attr("cx", 10).attr("cy", 10).attr("r", 9).attr("fill", "none"), a.append("line").attr("x1", 1).attr("x2", 19).attr("y1", 10).attr("y2", 10), a.append("line").attr("y1", 1).attr("y2", 19).attr("x1", 10).attr("x2", 10), a.selectAll("*").attr("stroke-width", `${o}`);
}, "requirement_contains_neo"), _v = {
  extension: iv,
  composition: sv,
  aggregation: ov,
  dependency: av,
  lollipop: nv,
  point: lv,
  circle: hv,
  cross: cv,
  barb: uv,
  barbNeo: dv,
  only_one: pv,
  zero_or_one: fv,
  one_or_more: gv,
  zero_or_more: mv,
  only_one_neo: yv,
  zero_or_one_neo: Cv,
  one_or_more_neo: xv,
  zero_or_more_neo: bv,
  requirement_arrow: kv,
  requirement_contains: wv,
  requirement_arrow_neo: Tv,
  requirement_contains_neo: Sv
}, vv = rv, Bv = {
  common: Qi,
  getConfig: wt,
  insertCluster: S_,
  insertEdge: ev,
  insertEdgeLabel: V_,
  insertMarkers: vv,
  insertNode: pm,
  interpolateToCurve: il,
  labelHelper: st,
  log: R,
  positionEdgeLabel: Z_
}, Vi = {}, ym = /* @__PURE__ */ f((e) => {
  for (const t of e)
    Vi[t.name] = t;
}, "registerLayoutLoaders"), Lv = /* @__PURE__ */ f(() => {
  ym([
    {
      name: "dagre",
      loader: /* @__PURE__ */ f(async () => await import("./dagre-KV5264BT-umRLwpDH.js"), "loader")
    },
    {
      name: "cose-bilkent",
      loader: /* @__PURE__ */ f(async () => await import("./cose-bilkent-S5V4N54A-Xuf6MkgG.js"), "loader")
    }
  ]);
}, "registerDefaultLayoutLoaders");
Lv();
var FA = /* @__PURE__ */ f(async (e, t) => {
  if (!(e.layoutAlgorithm in Vi))
    throw new Error(`Unknown layout algorithm: ${e.layoutAlgorithm}`);
  if (e.diagramId)
    for (const h of e.nodes) {
      const u = h.domId || h.id;
      h.domId = `${e.diagramId}-${u}`;
    }
  const r = Vi[e.layoutAlgorithm], i = await r.loader(), { theme: s, themeVariables: o } = e.config, { useGradient: a, gradientStart: n, gradientStop: l } = o, c = t.attr("id");
  if (t.append("defs").append("filter").attr("id", `${c}-drop-shadow`).attr("height", "130%").attr("width", "130%").append("feDropShadow").attr("dx", "4").attr("dy", "4").attr("stdDeviation", 0).attr("flood-opacity", "0.06").attr("flood-color", `${s?.includes("dark") ? "#FFFFFF" : "#000000"}`), t.append("defs").append("filter").attr("id", `${c}-drop-shadow-small`).attr("height", "150%").attr("width", "150%").append("feDropShadow").attr("dx", "2").attr("dy", "2").attr("stdDeviation", 0).attr("flood-opacity", "0.06").attr("flood-color", `${s?.includes("dark") ? "#FFFFFF" : "#000000"}`), a) {
    const h = t.append("linearGradient").attr("id", t.attr("id") + "-gradient").attr("gradientUnits", "objectBoundingBox").attr("x1", "0%").attr("y1", "0%").attr("x2", "100%").attr("y2", "0%");
    h.append("svg:stop").attr("offset", "0%").attr("stop-color", n).attr("stop-opacity", 1), h.append("svg:stop").attr("offset", "100%").attr("stop-color", l).attr("stop-opacity", 1);
  }
  return i.render(e, t, Bv, {
    algorithm: r.algorithm
  });
}, "render"), AA = /* @__PURE__ */ f((e = "", { fallback: t = "dagre" } = {}) => {
  if (e in Vi)
    return e;
  if (t in Vi)
    return R.warn(`Layout algorithm ${e} is not registered. Using ${t} as fallback.`), t;
  throw new Error(`Both layout algorithms ${e} and ${t} are not registered.`);
}, "getRegisteredLayoutAlgorithm"), Cm = "comm", xm = "rule", bm = "decl", Fv = "@import", Av = "@namespace", Mv = "@keyframes", Ev = "@layer", $v = Math.abs, Di = String.fromCharCode;
function km(e) {
  return e.trim();
}
function yn(e, t, r) {
  return e.replace(t, r);
}
function Gr(e, t) {
  return e.charCodeAt(t) | 0;
}
function ti(e, t, r) {
  return e.slice(t, r);
}
function ve(e) {
  return e.length;
}
function Ov(e) {
  return e.length;
}
function Ss(e, t) {
  return t.push(e), e;
}
var qo = 1, ei = 1, Tm = 0, he = 0, Ft = 0, ai = "";
function Sl(e, t, r, i, s, o, a, n) {
  return { value: e, root: t, parent: r, type: i, props: s, children: o, line: qo, column: ei, length: a, return: "", siblings: n };
}
function Iv() {
  return Ft;
}
function Dv() {
  return Ft = he > 0 ? Gr(ai, --he) : 0, ei--, Ft === 10 && (ei = 1, qo--), Ft;
}
function Ce() {
  return Ft = he < Tm ? Gr(ai, he++) : 0, ei++, Ft === 10 && (ei = 1, qo++), Ft;
}
function Qe() {
  return Gr(ai, he);
}
function Is() {
  return he;
}
function zo(e, t) {
  return ti(ai, e, t);
}
function Zi(e) {
  switch (e) {
    // \0 \t \n \r \s whitespace token
    case 0:
    case 9:
    case 10:
    case 13:
    case 32:
      return 5;
    // ! + , / > @ ~ isolate token
    case 33:
    case 43:
    case 44:
    case 47:
    case 62:
    case 64:
    case 126:
    // ; { } breakpoint token
    case 59:
    case 123:
    case 125:
      return 4;
    // : accompanied token
    case 58:
      return 3;
    // " ' ( [ opening delimit token
    case 34:
    case 39:
    case 40:
    case 91:
      return 2;
    // ) ] closing delimit token
    case 41:
    case 93:
      return 1;
  }
  return 0;
}
function Pv(e) {
  return qo = ei = 1, Tm = ve(ai = e), he = 0, [];
}
function Rv(e) {
  return ai = "", e;
}
function ka(e) {
  return km(zo(he - 1, Cn(e === 91 ? e + 2 : e === 40 ? e + 1 : e)));
}
function Nv(e) {
  for (; (Ft = Qe()) && Ft < 33; )
    Ce();
  return Zi(e) > 2 || Zi(Ft) > 3 ? "" : " ";
}
function qv(e, t) {
  for (; --t && Ce() && !(Ft < 48 || Ft > 102 || Ft > 57 && Ft < 65 || Ft > 70 && Ft < 97); )
    ;
  return zo(e, Is() + (t < 6 && Qe() == 32 && Ce() == 32));
}
function Cn(e) {
  for (; Ce(); )
    switch (Ft) {
      // ] ) " '
      case e:
        return he;
      // " '
      case 34:
      case 39:
        e !== 34 && e !== 39 && Cn(Ft);
        break;
      // (
      case 40:
        e === 41 && Cn(e);
        break;
      // \
      case 92:
        Ce();
        break;
    }
  return he;
}
function zv(e, t) {
  for (; Ce() && e + Ft !== 57; )
    if (e + Ft === 84 && Qe() === 47)
      break;
  return "/*" + zo(t, he - 1) + "*" + Di(e === 47 ? e : Ce());
}
function Wv(e) {
  for (; !Zi(Qe()); )
    Ce();
  return zo(e, he);
}
function Hv(e) {
  return Rv(Ds("", null, null, null, [""], e = Pv(e), 0, [0], e));
}
function Ds(e, t, r, i, s, o, a, n, l) {
  for (var c = 0, h = 0, u = a, p = 0, d = 0, g = 0, m = 1, y = 1, x = 1, b = 0, k = 0, w = "", S = s, v = o, M = i, B = w; y; )
    switch (g = k, k = Ce()) {
      // (
      case 40:
        g != 108 && Gr(B, u - 1) == 58 ? (b++, B += "(") : B += ka(k);
        break;
      // )
      case 41:
        b--, B += ")";
        break;
      // " ' [
      case 34:
      case 39:
      case 91:
        B += ka(k);
        break;
      // \t \n \r \s
      case 9:
      case 10:
      case 13:
      case 32:
        if (b > 0) {
          B += Di(k);
          break;
        }
        B += Nv(g);
        break;
      // \
      case 92:
        B += qv(Is() - 1, 7);
        continue;
      // /
      case 47:
        switch (Qe()) {
          case 42:
          case 47:
            Ss(Yv(zv(Ce(), Is()), t, r, l), l), (Zi(g || 1) == 5 || Zi(Qe() || 1) == 5) && ve(B) && ti(B, -1, void 0) !== " " && (B += " ");
            break;
          default:
            B += "/";
        }
        break;
      // {
      case 123 * m:
        n[c++] = ve(B) * x;
      // } ; \0
      case 125 * m:
      case 59:
      case 0:
        if (b > 0 && k) {
          B += Di(k);
          break;
        }
        switch (k) {
          // \0 }
          case 0:
          case 125:
            y = 0;
          // ;
          case 59 + h:
            x == -1 && (B = yn(B, /\f/g, "")), d > 0 && (ve(B) - u || m === 0) && Ss(d > 32 ? Mc(B + ";", i, r, u - 1, l) : Mc(yn(B, " ", "") + ";", i, r, u - 2, l), l);
            break;
          // @ ;
          case 59:
            B += ";";
          // { rule/at-rule
          default:
            if (Ss(M = Ac(B, t, r, c, h, s, n, w, S = [], v = [], u, o), o), k === 123)
              if (h === 0)
                Ds(B, t, M, M, S, o, u, n, v);
              else {
                switch (p) {
                  // c(ontainer)
                  case 99:
                    if (Gr(B, 3) === 110) break;
                  // l(ayer)
                  case 108:
                    if (Gr(B, 2) === 97) break;
                  default:
                    h = 0;
                  // d(ocument) m(edia) s(upports)
                  case 100:
                  case 109:
                  case 115:
                }
                h ? Ds(e, M, M, i && Ss(Ac(e, M, M, 0, 0, s, n, w, s, S = [], u, v), v), s, v, u, n, i ? S : v) : Ds(B, M, M, M, [""], v, 0, n, v);
              }
        }
        c = h = d = 0, m = x = 1, w = B = "", u = a;
        break;
      // :
      case 58:
        u = 1 + ve(B), d = g;
      default:
        if (m < 1) {
          if (k == 123)
            --m;
          else if (k == 125 && m++ == 0 && Dv() == 125)
            continue;
        }
        switch (B += Di(k), k * m) {
          // &
          case 38:
            x = h > 0 ? 1 : (B += "\f", -1);
            break;
          // ,
          case 44:
            if (b > 0) break;
            n[c++] = (ve(B) - 1) * x, x = 1;
            break;
          // @
          case 64:
            Qe() === 45 && (B += ka(Ce())), p = Qe(), h = u = ve(w = B += Wv(Is())), k++;
            break;
          // -
          case 45:
            g === 45 && ve(B) == 2 && (m = 0);
        }
    }
  return o;
}
function Ac(e, t, r, i, s, o, a, n, l, c, h, u) {
  for (var p = s - 1, d = s === 0 ? o : [""], g = Ov(d), m = 0, y = 0, x = 0; m < i; ++m)
    for (var b = 0, k = ti(e, p + 1, p = $v(y = a[m])), w = e; b < g; ++b)
      (w = km(y > 0 ? d[b] + " " + k : yn(k, /&\f/g, d[b]))) && (l[x++] = w);
  return Sl(e, t, r, s === 0 ? xm : n, l, c, h, u);
}
function Yv(e, t, r, i) {
  return Sl(e, t, r, Cm, Di(Iv()), ti(e, 2, -2), 0, i);
}
function Mc(e, t, r, i, s) {
  return Sl(e, t, r, bm, ti(e, 0, i), ti(e, i + 1, -1), i, s);
}
function xn(e, t) {
  for (var r = "", i = 0; i < e.length; i++)
    r += t(e[i], i, e, t) || "";
  return r;
}
function jv(e, t, r, i) {
  switch (e.type) {
    case Ev:
      if (e.children.length) break;
    case Fv:
    case Av:
    case bm:
      return e.return = e.return || e.value;
    case Cm:
      return "";
    case Mv:
      return e.return = e.value + "{" + xn(e.children, i) + "}";
    case xm:
      if (!ve(e.value = e.props.join(","))) return "";
  }
  return ve(r = xn(e.children, i)) ? e.return = e.value + "{" + r + "}" : "";
}
var Uv = jp(Object.keys, Object), Gv = Object.prototype, Xv = Gv.hasOwnProperty;
function Vv(e) {
  if (!Mo(e))
    return Uv(e);
  var t = [];
  for (var r in Object(e))
    Xv.call(e, r) && r != "constructor" && t.push(r);
  return t;
}
var bn = Fr($e, "DataView"), kn = Fr($e, "Promise"), Tn = Fr($e, "Set"), wn = Fr($e, "WeakMap"), Ec = "[object Map]", Zv = "[object Object]", $c = "[object Promise]", Oc = "[object Set]", Ic = "[object WeakMap]", Dc = "[object DataView]", Kv = Lr(bn), Qv = Lr(Gi), Jv = Lr(kn), tB = Lr(Tn), eB = Lr(wn), pr = ri;
(bn && pr(new bn(new ArrayBuffer(1))) != Dc || Gi && pr(new Gi()) != Ec || kn && pr(kn.resolve()) != $c || Tn && pr(new Tn()) != Oc || wn && pr(new wn()) != Ic) && (pr = function(e) {
  var t = ri(e), r = t == Zv ? e.constructor : void 0, i = r ? Lr(r) : "";
  if (i)
    switch (i) {
      case Kv:
        return Dc;
      case Qv:
        return Ec;
      case Jv:
        return $c;
      case tB:
        return Oc;
      case eB:
        return Ic;
    }
  return t;
});
var rB = "[object Map]", iB = "[object Set]", sB = Object.prototype, oB = sB.hasOwnProperty;
function Pc(e) {
  if (e == null)
    return !0;
  if (Eo(e) && (ao(e) || typeof e == "string" || typeof e.splice == "function" || el(e) || rl(e) || oo(e)))
    return !e.length;
  var t = pr(e);
  if (t == rB || t == iB)
    return !e.size;
  if (Mo(e))
    return !Vv(e).length;
  for (var r in e)
    if (oB.call(e, r))
      return !1;
  return !0;
}
var wm = "c4", aB = /* @__PURE__ */ f((e) => /^\s*C4Context|C4Container|C4Component|C4Dynamic|C4Deployment/.test(e), "detector"), nB = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./c4Diagram-AHTNJAMY-vnta9HxX.js");
  return { id: wm, diagram: e };
}, "loader"), lB = {
  id: wm,
  detector: aB,
  loader: nB
}, hB = lB, Sm = "flowchart", cB = /* @__PURE__ */ f((e, t) => t?.flowchart?.defaultRenderer === "dagre-wrapper" || t?.flowchart?.defaultRenderer === "elk" ? !1 : /^\s*graph/.test(e), "detector"), uB = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./flowDiagram-DWJPFMVM-B-xylKtj.js");
  return { id: Sm, diagram: e };
}, "loader"), dB = {
  id: Sm,
  detector: cB,
  loader: uB
}, pB = dB, _m = "flowchart-v2", fB = /* @__PURE__ */ f((e, t) => t?.flowchart?.defaultRenderer === "dagre-d3" ? !1 : (t?.flowchart?.defaultRenderer === "elk" && (t.layout = "elk"), /^\s*graph/.test(e) && t?.flowchart?.defaultRenderer === "dagre-wrapper" ? !0 : /^\s*flowchart/.test(e)), "detector"), gB = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./flowDiagram-DWJPFMVM-B-xylKtj.js");
  return { id: _m, diagram: e };
}, "loader"), mB = {
  id: _m,
  detector: fB,
  loader: gB
}, yB = mB, vm = "er", CB = /* @__PURE__ */ f((e) => /^\s*erDiagram/.test(e), "detector"), xB = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./erDiagram-SMLLAGMA-DaAngXDK.js");
  return { id: vm, diagram: e };
}, "loader"), bB = {
  id: vm,
  detector: CB,
  loader: xB
}, kB = bB, Bm = "gitGraph", TB = /* @__PURE__ */ f((e) => /^\s*gitGraph/.test(e), "detector"), wB = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./gitGraphDiagram-UUTBAWPF-B5zuasYQ.js");
  return { id: Bm, diagram: e };
}, "loader"), SB = {
  id: Bm,
  detector: TB,
  loader: wB
}, _B = SB, Lm = "gantt", vB = /* @__PURE__ */ f((e) => /^\s*gantt/.test(e), "detector"), BB = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./ganttDiagram-T4ZO3ILL-BQN3bK4W.js");
  return { id: Lm, diagram: e };
}, "loader"), LB = {
  id: Lm,
  detector: vB,
  loader: BB
}, FB = LB, Fm = "info", AB = /* @__PURE__ */ f((e) => /^\s*info/.test(e), "detector"), MB = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./infoDiagram-42DDH7IO-C3QWADuJ.js");
  return { id: Fm, diagram: e };
}, "loader"), EB = {
  id: Fm,
  detector: AB,
  loader: MB
}, Am = "pie", $B = /* @__PURE__ */ f((e) => /^\s*pie/.test(e), "detector"), OB = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./pieDiagram-DEJITSTG-DxhD0E2d.js");
  return { id: Am, diagram: e };
}, "loader"), IB = {
  id: Am,
  detector: $B,
  loader: OB
}, Mm = "quadrantChart", DB = /* @__PURE__ */ f((e) => /^\s*quadrantChart/.test(e), "detector"), PB = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./quadrantDiagram-34T5L4WZ-DyibwQsA.js");
  return { id: Mm, diagram: e };
}, "loader"), RB = {
  id: Mm,
  detector: DB,
  loader: PB
}, NB = RB, Em = "xychart", qB = /* @__PURE__ */ f((e) => /^\s*xychart(-beta)?/.test(e), "detector"), zB = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./xychartDiagram-5P7HB3ND-fbchxqmk.js");
  return { id: Em, diagram: e };
}, "loader"), WB = {
  id: Em,
  detector: qB,
  loader: zB
}, HB = WB, $m = "requirement", YB = /* @__PURE__ */ f((e) => /^\s*requirement(Diagram)?/.test(e), "detector"), jB = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./requirementDiagram-MS252O5E-B1k1nzXp.js");
  return { id: $m, diagram: e };
}, "loader"), UB = {
  id: $m,
  detector: YB,
  loader: jB
}, GB = UB, Om = "sequence", XB = /* @__PURE__ */ f((e) => /^\s*sequenceDiagram/.test(e), "detector"), VB = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./sequenceDiagram-FGHM5R23-BZlhPGhp.js");
  return { id: Om, diagram: e };
}, "loader"), ZB = {
  id: Om,
  detector: XB,
  loader: VB
}, KB = ZB, Im = "class", QB = /* @__PURE__ */ f((e, t) => t?.class?.defaultRenderer === "dagre-wrapper" ? !1 : /^\s*classDiagram/.test(e), "detector"), JB = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./classDiagram-6PBFFD2Q-CLIJ9e67.js");
  return { id: Im, diagram: e };
}, "loader"), tL = {
  id: Im,
  detector: QB,
  loader: JB
}, eL = tL, Dm = "classDiagram", rL = /* @__PURE__ */ f((e, t) => /^\s*classDiagram/.test(e) && t?.class?.defaultRenderer === "dagre-wrapper" ? !0 : /^\s*classDiagram-v2/.test(e), "detector"), iL = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./classDiagram-v2-HSJHXN6E-CLIJ9e67.js");
  return { id: Dm, diagram: e };
}, "loader"), sL = {
  id: Dm,
  detector: rL,
  loader: iL
}, oL = sL, Pm = "state", aL = /* @__PURE__ */ f((e, t) => t?.state?.defaultRenderer === "dagre-wrapper" ? !1 : /^\s*stateDiagram/.test(e), "detector"), nL = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./stateDiagram-FHFEXIEX-B95qSryT.js");
  return { id: Pm, diagram: e };
}, "loader"), lL = {
  id: Pm,
  detector: aL,
  loader: nL
}, hL = lL, Rm = "stateDiagram", cL = /* @__PURE__ */ f((e, t) => !!(/^\s*stateDiagram-v2/.test(e) || /^\s*stateDiagram/.test(e) && t?.state?.defaultRenderer === "dagre-wrapper"), "detector"), uL = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./stateDiagram-v2-QKLJ7IA2-BcCmL5be.js");
  return { id: Rm, diagram: e };
}, "loader"), dL = {
  id: Rm,
  detector: cL,
  loader: uL
}, pL = dL, Nm = "journey", fL = /* @__PURE__ */ f((e) => /^\s*journey/.test(e), "detector"), gL = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./journeyDiagram-VCZTEJTY-BjKGMf6G.js");
  return { id: Nm, diagram: e };
}, "loader"), mL = {
  id: Nm,
  detector: fL,
  loader: gL
}, yL = mL, CL = /* @__PURE__ */ f((e, t, r) => {
  R.debug(`rendering svg for syntax error
`);
  const i = z1(t), s = i.append("g");
  i.attr("viewBox", "0 0 2412 512"), cu(i, 100, 512, !0), s.append("path").attr("class", "error-icon").attr(
    "d",
    "m411.313,123.313c6.25-6.25 6.25-16.375 0-22.625s-16.375-6.25-22.625,0l-32,32-9.375,9.375-20.688-20.688c-12.484-12.5-32.766-12.5-45.25,0l-16,16c-1.261,1.261-2.304,2.648-3.31,4.051-21.739-8.561-45.324-13.426-70.065-13.426-105.867,0-192,86.133-192,192s86.133,192 192,192 192-86.133 192-192c0-24.741-4.864-48.327-13.426-70.065 1.402-1.007 2.79-2.049 4.051-3.31l16-16c12.5-12.492 12.5-32.758 0-45.25l-20.688-20.688 9.375-9.375 32.001-31.999zm-219.313,100.687c-52.938,0-96,43.063-96,96 0,8.836-7.164,16-16,16s-16-7.164-16-16c0-70.578 57.422-128 128-128 8.836,0 16,7.164 16,16s-7.164,16-16,16z"
  ), s.append("path").attr("class", "error-icon").attr(
    "d",
    "m459.02,148.98c-6.25-6.25-16.375-6.25-22.625,0s-6.25,16.375 0,22.625l16,16c3.125,3.125 7.219,4.688 11.313,4.688 4.094,0 8.188-1.563 11.313-4.688 6.25-6.25 6.25-16.375 0-22.625l-16.001-16z"
  ), s.append("path").attr("class", "error-icon").attr(
    "d",
    "m340.395,75.605c3.125,3.125 7.219,4.688 11.313,4.688 4.094,0 8.188-1.563 11.313-4.688 6.25-6.25 6.25-16.375 0-22.625l-16-16c-6.25-6.25-16.375-6.25-22.625,0s-6.25,16.375 0,22.625l15.999,16z"
  ), s.append("path").attr("class", "error-icon").attr(
    "d",
    "m400,64c8.844,0 16-7.164 16-16v-32c0-8.836-7.156-16-16-16-8.844,0-16,7.164-16,16v32c0,8.836 7.156,16 16,16z"
  ), s.append("path").attr("class", "error-icon").attr(
    "d",
    "m496,96.586h-32c-8.844,0-16,7.164-16,16 0,8.836 7.156,16 16,16h32c8.844,0 16-7.164 16-16 0-8.836-7.156-16-16-16z"
  ), s.append("path").attr("class", "error-icon").attr(
    "d",
    "m436.98,75.605c3.125,3.125 7.219,4.688 11.313,4.688 4.094,0 8.188-1.563 11.313-4.688l32-32c6.25-6.25 6.25-16.375 0-22.625s-16.375-6.25-22.625,0l-32,32c-6.251,6.25-6.251,16.375-0.001,22.625z"
  ), s.append("text").attr("class", "error-text").attr("x", 1440).attr("y", 250).attr("font-size", "150px").style("text-anchor", "middle").text("Syntax error in text"), s.append("text").attr("class", "error-text").attr("x", 1250).attr("y", 400).attr("font-size", "100px").style("text-anchor", "middle").text(`mermaid version ${r}`);
}, "draw"), qm = { draw: CL }, xL = qm, bL = {
  db: {},
  renderer: qm,
  parser: {
    parse: /* @__PURE__ */ f(() => {
    }, "parse")
  }
}, kL = bL, zm = "flowchart-elk", TL = /* @__PURE__ */ f((e, t = {}) => (
  // If diagram explicitly states flowchart-elk
  /^\s*flowchart-elk/.test(e) || // If a flowchart/graph diagram has their default renderer set to elk
  /^\s*(flowchart|graph)/.test(e) && t?.flowchart?.defaultRenderer === "elk" ? (t.layout = "elk", !0) : !1
), "detector"), wL = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./flowDiagram-DWJPFMVM-B-xylKtj.js");
  return { id: zm, diagram: e };
}, "loader"), SL = {
  id: zm,
  detector: TL,
  loader: wL
}, _L = SL, Wm = "timeline", vL = /* @__PURE__ */ f((e) => /^\s*timeline/.test(e), "detector"), BL = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./timeline-definition-GMOUNBTQ-C99biSYp.js");
  return { id: Wm, diagram: e };
}, "loader"), LL = {
  id: Wm,
  detector: vL,
  loader: BL
}, FL = LL, Hm = "mindmap", AL = /* @__PURE__ */ f((e) => /^\s*mindmap/.test(e), "detector"), ML = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./mindmap-definition-QFDTVHPH-BPyQNVV8.js");
  return { id: Hm, diagram: e };
}, "loader"), EL = {
  id: Hm,
  detector: AL,
  loader: ML
}, $L = EL, Ym = "kanban", OL = /* @__PURE__ */ f((e) => /^\s*kanban/.test(e), "detector"), IL = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./kanban-definition-6JOO6SKY-Cj5VW-_i.js");
  return { id: Ym, diagram: e };
}, "loader"), DL = {
  id: Ym,
  detector: OL,
  loader: IL
}, PL = DL, jm = "sankey", RL = /* @__PURE__ */ f((e) => /^\s*sankey(-beta)?/.test(e), "detector"), NL = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./sankeyDiagram-XADWPNL6-Be61kRTn.js");
  return { id: jm, diagram: e };
}, "loader"), qL = {
  id: jm,
  detector: RL,
  loader: NL
}, zL = qL, Um = "packet", WL = /* @__PURE__ */ f((e) => /^\s*packet(-beta)?/.test(e), "detector"), HL = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./diagram-TYMM5635-CDA657xg.js");
  return { id: Um, diagram: e };
}, "loader"), YL = {
  id: Um,
  detector: WL,
  loader: HL
}, Gm = "radar", jL = /* @__PURE__ */ f((e) => /^\s*radar-beta/.test(e), "detector"), UL = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./diagram-MMDJMWI5-CaBNe67n.js");
  return { id: Gm, diagram: e };
}, "loader"), GL = {
  id: Gm,
  detector: jL,
  loader: UL
}, Xm = "block", XL = /* @__PURE__ */ f((e) => /^\s*block(-beta)?/.test(e), "detector"), VL = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./blockDiagram-DXYQGD6D-DWqRIMGa.js");
  return { id: Xm, diagram: e };
}, "loader"), ZL = {
  id: Xm,
  detector: XL,
  loader: VL
}, KL = ZL, Vm = "treeView", QL = /* @__PURE__ */ f((e) => /^\s*treeView-beta/.test(e), "detector"), JL = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./diagram-5BDNPKRD-BxdQZUPY.js");
  return { id: Vm, diagram: e };
}, "loader"), tF = {
  id: Vm,
  detector: QL,
  loader: JL
}, eF = tF, Zm = "architecture", rF = /* @__PURE__ */ f((e) => /^\s*architecture/.test(e), "detector"), iF = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./architectureDiagram-Q4EWVU46-Chtsrrsm.js");
  return { id: Zm, diagram: e };
}, "loader"), sF = {
  id: Zm,
  detector: rF,
  loader: iF
}, oF = sF, Km = "ishikawa", aF = /* @__PURE__ */ f((e) => /^\s*ishikawa(-beta)?\b/i.test(e), "detector"), nF = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./ishikawaDiagram-UXIWVN3A-DpfbOS-L.js");
  return { id: Km, diagram: e };
}, "loader"), lF = {
  id: Km,
  detector: aF,
  loader: nF
}, Qm = "venn", hF = /* @__PURE__ */ f((e) => /^\s*venn-beta/.test(e), "detector"), cF = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./vennDiagram-DHZGUBPP-UT8BSHk_.js");
  return { id: Qm, diagram: e };
}, "loader"), uF = {
  id: Qm,
  detector: hF,
  loader: cF
}, dF = uF, Jm = "treemap", pF = /* @__PURE__ */ f((e) => /^\s*treemap/.test(e), "detector"), fF = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./diagram-G4DWMVQ6-BobEleCI.js");
  return { id: Jm, diagram: e };
}, "loader"), gF = {
  id: Jm,
  detector: pF,
  loader: fF
}, ty = "wardley-beta", mF = /* @__PURE__ */ f((e) => /^\s*wardley-beta/i.test(e), "detector"), yF = /* @__PURE__ */ f(async () => {
  const { diagram: e } = await import("./wardleyDiagram-NUSXRM2D-CZun_nrn.js");
  return { id: ty, diagram: e };
}, "loader"), CF = {
  id: ty,
  detector: mF,
  loader: yF
}, xF = CF, Rc = !1, Wo = /* @__PURE__ */ f(() => {
  Rc || (Rc = !0, zs("error", kL, (e) => e.toLowerCase().trim() === "error"), zs(
    "---",
    // --- diagram type may appear if YAML front-matter is not parsed correctly
    {
      db: {
        clear: /* @__PURE__ */ f(() => {
        }, "clear")
      },
      styles: {},
      // should never be used
      renderer: {
        draw: /* @__PURE__ */ f(() => {
        }, "draw")
      },
      parser: {
        parse: /* @__PURE__ */ f(() => {
          throw new Error(
            "Diagrams beginning with --- are not valid. If you were trying to use a YAML front-matter, please ensure that you've correctly opened and closed the YAML front-matter with un-indented `---` blocks"
          );
        }, "parse")
      },
      init: /* @__PURE__ */ f(() => null, "init")
      // no op
    },
    (e) => e.toLowerCase().trimStart().startsWith("---")
  ), _a(_L, $L, oF), _a(
    hB,
    PL,
    oL,
    eL,
    kB,
    FB,
    EB,
    IB,
    GB,
    KB,
    yB,
    pB,
    FL,
    _B,
    pL,
    hL,
    yL,
    NB,
    zL,
    YL,
    HB,
    KL,
    eF,
    GL,
    lF,
    gF,
    dF,
    xF
  ));
}, "addDiagrams"), bF = /* @__PURE__ */ f(async () => {
  R.debug("Loading registered diagrams");
  const t = (await Promise.allSettled(
    Object.entries(xr).map(async ([r, { detector: i, loader: s }]) => {
      if (s)
        try {
          Fa(r);
        } catch {
          try {
            const { diagram: o, id: a } = await s();
            zs(a, o, i);
          } catch (o) {
            throw R.error(`Failed to load external diagram with key ${r}. Removing from detectors.`), delete xr[r], o;
          }
        }
    })
  )).filter((r) => r.status === "rejected");
  if (t.length > 0) {
    R.error(`Failed to load ${t.length} external diagrams`);
    for (const r of t)
      R.error(r);
    throw new Error(`Failed to load ${t.length} external diagrams`);
  }
}, "loadRegisteredDiagrams"), kF = "graphics-document document";
function ey(e, t) {
  e.attr("role", kF), t !== "" && e.attr("aria-roledescription", t);
}
f(ey, "setA11yDiagramInfo");
function ry(e, t, r, i) {
  if (e.insert !== void 0) {
    if (r) {
      const s = `chart-desc-${i}`;
      e.attr("aria-describedby", s), e.insert("desc", ":first-child").attr("id", s).text(r);
    }
    if (t) {
      const s = `chart-title-${i}`;
      e.attr("aria-labelledby", s), e.insert("title", ":first-child").attr("id", s).text(t);
    }
  }
}
f(ry, "addSVGa11yTitleDescription");
var Sn = class iy {
  constructor(t, r, i, s, o) {
    this.type = t, this.text = r, this.db = i, this.parser = s, this.renderer = o;
  }
  static {
    f(this, "Diagram");
  }
  static async fromText(t, r = {}) {
    const i = wt(), s = Bn(t, i);
    t = Yw(t) + `
`;
    try {
      Fa(s);
    } catch {
      const c = a0(s);
      if (!c)
        throw new Zc(`Diagram ${s} not found.`);
      const { id: h, diagram: u } = await c();
      zs(h, u);
    }
    const { db: o, parser: a, renderer: n, init: l } = Fa(s);
    return a.parser && (a.parser.yy = o), o.clear?.(), l?.(i), r.title && o.setDiagramTitle?.(r.title), await a.parse(t), new iy(s, t, o, a, n);
  }
  async render(t, r) {
    await this.renderer.draw(this.text, t, r, this);
  }
  getParser() {
    return this.parser;
  }
  getType() {
    return this.type;
  }
}, Nc = [], TF = /* @__PURE__ */ f(() => {
  Nc.forEach((e) => {
    e();
  }), Nc = [];
}, "attachFunctions"), wF = /* @__PURE__ */ f((e) => e.replace(/^\s*%%(?!{)[^\n]+\n?/gm, "").trimStart(), "cleanupComments");
function sy(e) {
  const t = e.match(Vc);
  if (!t)
    return {
      text: e,
      metadata: {}
    };
  let r = Xk(t[1], {
    // To support config, we need JSON schema.
    // https://www.yaml.org/spec/1.2/spec.html#id2803231
    schema: Gk
  }) ?? {};
  r = typeof r == "object" && !Array.isArray(r) ? r : {};
  const i = {};
  return r.displayMode && (i.displayMode = r.displayMode.toString()), r.title && (i.title = r.title.toString()), r.config && (i.config = r.config), {
    text: e.slice(t[0].length),
    metadata: i
  };
}
f(sy, "extractFrontMatter");
var SF = /* @__PURE__ */ f((e) => e.replace(/\r\n?/g, `
`).replace(
  /<(\w+)([^>]*)>/g,
  (t, r, i) => "<" + r + i.replace(/="([^"]*)"/g, "='$1'") + ">"
), "cleanupText"), _F = /* @__PURE__ */ f((e) => {
  const { text: t, metadata: r } = sy(e), { displayMode: i, title: s, config: o = {} } = r;
  return i && (o.gantt || (o.gantt = {}), o.gantt.displayMode = i), { title: s, config: o, text: t };
}, "processFrontmatter"), vF = /* @__PURE__ */ f((e) => {
  const t = me.detectInit(e) ?? {}, r = me.detectDirective(e, "wrap");
  return Array.isArray(r) ? t.wrap = r.some(({ type: i }) => i === "wrap") : r?.type === "wrap" && (t.wrap = !0), {
    text: Mw(e),
    directive: t
  };
}, "processDirectives");
function _l(e) {
  const t = SF(e), r = _F(t), i = vF(r.text), s = ll(r.config, i.directive);
  return e = wF(i.text), {
    code: e,
    title: r.title,
    config: s
  };
}
f(_l, "preprocessDiagram");
function oy(e) {
  const t = new TextEncoder().encode(e), r = Array.from(t, (i) => String.fromCodePoint(i)).join("");
  return btoa(r);
}
f(oy, "toBase64");
var BF = 5e4, LF = "graph TB;a[Maximum text size in diagram exceeded];style a fill:#faa", FF = "sandbox", AF = "loose", MF = "http://www.w3.org/2000/svg", EF = "http://www.w3.org/1999/xlink", $F = "http://www.w3.org/1999/xhtml", OF = "100%", IF = "100%", DF = "border:0;margin:0;", PF = "margin:0", RF = "allow-top-navigation-by-user-activation allow-popups", NF = 'The "iframe" tag is not supported by your browser.', qF = ["foreignobject"], zF = ["dominant-baseline"];
function vl(e) {
  const t = _l(e);
  return Ns(), O0(t.config ?? {}), t;
}
f(vl, "processAndSetConfigs");
async function ay(e, t) {
  Wo();
  try {
    const { code: r, config: i } = vl(e);
    return { diagramType: (await ly(r)).type, config: i };
  } catch (r) {
    if (t?.suppressErrors)
      return !1;
    throw r;
  }
}
f(ay, "parse");
var qc = /* @__PURE__ */ f((e, t, r = []) => `
.${e} ${t} { ${r.join(" !important; ")} !important; }`, "cssImportantStyles"), WF = /* @__PURE__ */ f((e, t = /* @__PURE__ */ new Map()) => {
  let r = "";
  if (e.themeCSS !== void 0 && (r += `
${e.themeCSS}`), e.fontFamily !== void 0 && (r += `
:root { --mermaid-font-family: ${e.fontFamily}}`), e.altFontFamily !== void 0 && (r += `
:root { --mermaid-alt-font-family: ${e.altFontFamily}}`), t instanceof Map) {
    const a = Vt(e) ? ["> *", "span"] : ["rect", "polygon", "ellipse", "circle", "path"];
    t.forEach((n) => {
      Pc(n.styles) || a.forEach((l) => {
        r += qc(n.id, l, n.styles);
      }), Pc(n.textStyles) || (r += qc(
        n.id,
        "tspan",
        (n?.textStyles || []).map((l) => l.replace("color", "fill"))
      ));
    });
  }
  return r;
}, "createCssStyles"), HF = /* @__PURE__ */ f((e, t, r, i) => {
  const s = WF(e, r), o = J0(
    t,
    s,
    { ...e.themeVariables, theme: e.theme, look: e.look },
    i
  );
  return xn(Hv(`${i}{${o}}`), jv);
}, "createUserStyles"), YF = /* @__PURE__ */ f((e = "", t, r) => {
  let i = e;
  return !r && !t && (i = i.replace(
    /marker-end="url\([\d+./:=?A-Za-z-]*?#/g,
    'marker-end="url(#'
  )), i = Sr(i), i = i.replace(/<br>/g, "<br/>"), i;
}, "cleanUpSvgCode"), jF = /* @__PURE__ */ f((e = "", t) => {
  const r = t?.viewBox?.baseVal?.height ? t.viewBox.baseVal.height + "px" : IF, i = oy(`<body style="${PF}">${e}</body>`);
  return `<iframe style="width:${OF};height:${r};${DF}" src="data:text/html;charset=UTF-8;base64,${i}" sandbox="${RF}">
  ${NF}
</iframe>`;
}, "putIntoIFrame"), zc = /* @__PURE__ */ f((e, t, r, i, s) => {
  const o = e.append("div");
  o.attr("id", r), i && o.attr("style", i);
  const a = o.append("svg").attr("id", t).attr("width", "100%").attr("xmlns", MF);
  return s && a.attr("xmlns:xlink", s), a.append("g"), e;
}, "appendDivSvgG");
function _n(e, t) {
  return e.append("iframe").attr("id", t).attr("style", "width: 100%; height: 100%;").attr("sandbox", "");
}
f(_n, "sandboxedIframe");
var UF = /* @__PURE__ */ f((e, t, r, i) => {
  e.getElementById(t)?.remove(), e.getElementById(r)?.remove(), e.getElementById(i)?.remove();
}, "removeExistingElements"), GF = /* @__PURE__ */ f(async function(e, t, r) {
  Wo();
  const i = vl(t);
  t = i.code;
  const s = wt();
  R.debug(s), t.length > (s?.maxTextSize ?? BF) && (t = LF);
  const o = "#" + e, a = "i" + e, n = "#" + a, l = "d" + e, c = "#" + l, h = /* @__PURE__ */ f(() => {
    const z = ct(p ? n : c).node();
    z && "remove" in z && z.remove();
  }, "removeTempElements");
  let u = ct("body");
  const p = s.securityLevel === FF, d = s.securityLevel === AF, g = s.fontFamily;
  if (r !== void 0) {
    if (r && (r.innerHTML = ""), p) {
      const W = _n(ct(r), a);
      u = ct(W.nodes()[0].contentDocument.body), u.node().style.margin = 0;
    } else
      u = ct(r);
    zc(u, e, l, `font-family: ${g}`, EF);
  } else {
    if (UF(document, e, l, a), p) {
      const W = _n(ct("body"), a);
      u = ct(W.nodes()[0].contentDocument.body), u.node().style.margin = 0;
    } else
      u = ct("body");
    zc(u, e, l);
  }
  let m, y;
  try {
    m = await Sn.fromText(t, { title: i.title });
  } catch (W) {
    if (s.suppressErrorRendering)
      throw h(), W;
    m = await Sn.fromText("error"), y = W;
  }
  const x = u.select(c).node(), b = m.type, k = x.firstChild, w = k.firstChild, S = m.renderer.getClasses?.(t, m), v = HF(s, b, S, o), M = document.createElement("style");
  M.innerHTML = v, k.insertBefore(M, w);
  try {
    await m.renderer.draw(t, e, "11.14.0", m);
  } catch (W) {
    throw s.suppressErrorRendering ? h() : xL.draw(t, e, "11.14.0"), W;
  }
  const B = u.select(`${c} svg`), N = m.db.getAccTitle?.(), D = m.db.getAccDescription?.();
  hy(b, B, N, D), u.select(`[id="${e}"]`).selectAll("foreignobject > *").attr("xmlns", $F);
  let O = u.select(c).node().innerHTML;
  if (R.debug("config.arrowMarkerAbsolute", s.arrowMarkerAbsolute), O = YF(O, p, je(s.arrowMarkerAbsolute)), p) {
    const W = u.select(c + " svg").node();
    O = jF(O, W);
  } else d || (O = Xr.sanitize(O, {
    ADD_TAGS: qF,
    ADD_ATTR: zF,
    HTML_INTEGRATION_POINTS: { foreignobject: !0 }
  }));
  if (TF(), y)
    throw y;
  return h(), {
    diagramType: b,
    svg: O,
    bindFunctions: m.db.bindFunctions
  };
}, "render");
function ny(e = {}) {
  const t = $t({}, e);
  t?.fontFamily && !t.themeVariables?.fontFamily && (t.themeVariables || (t.themeVariables = {}), t.themeVariables.fontFamily = t.fontFamily), E0(t), t?.theme && t.theme in qe ? t.themeVariables = qe[t.theme].getThemeVariables(
    t.themeVariables
  ) : t && (t.themeVariables = qe.default.getThemeVariables(t.themeVariables));
  const r = typeof t == "object" ? M0(t) : eu();
  vn(r.logLevel), Wo();
}
f(ny, "initialize");
var ly = /* @__PURE__ */ f((e, t = {}) => {
  const { code: r } = _l(e);
  return Sn.fromText(r, t);
}, "getDiagramFromText");
function hy(e, t, r, i) {
  ey(t, e), ry(t, r, i, t.attr("id"));
}
f(hy, "addA11yInfo");
var vr = Object.freeze({
  render: GF,
  parse: ay,
  getDiagramFromText: ly,
  initialize: ny,
  getConfig: wt,
  setConfig: ru,
  getSiteConfig: eu,
  updateSiteConfig: $0,
  reset: /* @__PURE__ */ f(() => {
    Ns();
  }, "reset"),
  globalReset: /* @__PURE__ */ f(() => {
    Ns(Vr);
  }, "globalReset"),
  defaultConfig: Vr
});
vn(wt().logLevel);
Ns(wt());
var XF = /* @__PURE__ */ f((e, t, r) => {
  R.warn(e), nl(e) ? (r && r(e.str, e.hash), t.push({ ...e, message: e.str, error: e })) : (r && r(e), e instanceof Error && t.push({
    str: e.message,
    message: e.message,
    hash: e.name,
    error: e
  }));
}, "handleError"), cy = /* @__PURE__ */ f(async function(e = {
  querySelector: ".mermaid"
}) {
  try {
    await VF(e);
  } catch (t) {
    if (nl(t) && R.error(t.str), Ye.parseError && Ye.parseError(t), !e.suppressErrors)
      throw R.error("Use the suppressErrors option to suppress these errors"), t;
  }
}, "run"), VF = /* @__PURE__ */ f(async function({ postRenderCallback: e, querySelector: t, nodes: r } = {
  querySelector: ".mermaid"
}) {
  const i = vr.getConfig();
  R.debug(`${e ? "" : "No "}Callback function found`);
  let s;
  if (r)
    s = r;
  else if (t)
    s = document.querySelectorAll(t);
  else
    throw new Error("Nodes and querySelector are both undefined");
  R.debug(`Found ${s.length} diagrams`), i?.startOnLoad !== void 0 && (R.debug("Start On Load: " + i?.startOnLoad), vr.updateSiteConfig({ startOnLoad: i?.startOnLoad }));
  const o = new me.InitIDGenerator(i.deterministicIds, i.deterministicIDSeed);
  let a;
  const n = [];
  for (const l of Array.from(s)) {
    if (R.info("Rendering diagram: " + l.id), l.getAttribute("data-processed"))
      continue;
    l.setAttribute("data-processed", "true");
    const c = `mermaid-${o.next()}`;
    a = l.innerHTML, a = vf(me.entityDecode(a)).trim().replace(/<br\s*\/?>/gi, "<br/>");
    const h = me.detectInit(a);
    h && R.debug("Detected early reinit: ", h);
    try {
      const { svg: u, bindFunctions: p } = await fy(c, a, l);
      l.innerHTML = u, e && await e(c), p && p(l);
    } catch (u) {
      XF(u, n, Ye.parseError);
    }
  }
  if (n.length > 0)
    throw n[0];
}, "runThrowsErrors"), uy = /* @__PURE__ */ f(function(e) {
  vr.initialize(e);
}, "initialize"), ZF = /* @__PURE__ */ f(async function(e, t, r) {
  R.warn("mermaid.init is deprecated. Please use run instead."), e && uy(e);
  const i = { postRenderCallback: r, querySelector: ".mermaid" };
  typeof t == "string" ? i.querySelector = t : t && (t instanceof HTMLElement ? i.nodes = [t] : i.nodes = t), await cy(i);
}, "init"), KF = /* @__PURE__ */ f(async (e, {
  lazyLoad: t = !0
} = {}) => {
  Wo(), _a(...e), t === !1 && await bF();
}, "registerExternalDiagrams"), dy = /* @__PURE__ */ f(function() {
  if (Ye.startOnLoad) {
    const { startOnLoad: e } = vr.getConfig();
    e && Ye.run().catch((t) => R.error("Mermaid failed to initialize", t));
  }
}, "contentLoaded");
typeof document < "u" && window.addEventListener("load", dy, !1);
var QF = /* @__PURE__ */ f(function(e) {
  Ye.parseError = e;
}, "setParseErrorHandler"), Co = [], Ta = !1, py = /* @__PURE__ */ f(async () => {
  if (!Ta) {
    for (Ta = !0; Co.length > 0; ) {
      const e = Co.shift();
      if (e)
        try {
          await e();
        } catch (t) {
          R.error("Error executing queue", t);
        }
    }
    Ta = !1;
  }
}, "executeQueue"), JF = /* @__PURE__ */ f(async (e, t) => new Promise((r, i) => {
  const s = /* @__PURE__ */ f(() => new Promise((o, a) => {
    vr.parse(e, t).then(
      (n) => {
        o(n), r(n);
      },
      (n) => {
        R.error("Error parsing", n), Ye.parseError?.(n), a(n), i(n);
      }
    );
  }), "performCall");
  Co.push(s), py().catch(i);
}), "parse"), fy = /* @__PURE__ */ f((e, t, r) => new Promise((i, s) => {
  const o = /* @__PURE__ */ f(() => new Promise((a, n) => {
    vr.render(e, t, r).then(
      (l) => {
        a(l), i(l);
      },
      (l) => {
        R.error("Error parsing", l), Ye.parseError?.(l), n(l), s(l);
      }
    );
  }), "performCall");
  Co.push(o), py().catch(s);
}), "render"), tA = /* @__PURE__ */ f(() => Object.keys(xr).map((e) => ({
  id: e
})), "getRegisteredDiagramsMetadata"), Ye = {
  startOnLoad: !0,
  mermaidAPI: vr,
  parse: JF,
  render: fy,
  init: ZF,
  run: cy,
  registerExternalDiagrams: KF,
  registerLayoutLoaders: ym,
  initialize: uy,
  parseError: void 0,
  contentLoaded: dy,
  setParseErrorHandler: QF,
  detectType: Bn,
  registerIconPacks: KS,
  getRegisteredDiagramsMetadata: tA
}, eA = Ye;
/*! Check if previously processed */
/*!
 * Wait for document loaded before starting the execution
 */
const MA = /* @__PURE__ */ Object.freeze(/* @__PURE__ */ Object.defineProperty({
  __proto__: null,
  default: eA
}, Symbol.toStringTag, { value: "Module" }));
export {
  uu as $,
  aA as A,
  Je as B,
  By as C,
  wt as D,
  lC as E,
  ll as F,
  tu as G,
  Dw as H,
  z1 as I,
  Gk as J,
  d0 as K,
  Pi as L,
  sA as M,
  $o as N,
  W0 as O,
  hu as P,
  ah as Q,
  E1 as R,
  Na as S,
  Iw as T,
  Ki as U,
  be as V,
  $ as W,
  A as X,
  Z0 as Y,
  Bw as Z,
  f as _,
  rC as a,
  Br as a$,
  L1 as a0,
  qn as a1,
  cA as a2,
  pA as a3,
  Dr as a4,
  vh as a5,
  _h as a6,
  gA as a7,
  fA as a8,
  dA as a9,
  Z_ as aA,
  V_ as aB,
  JS as aC,
  Yc as aD,
  F1 as aE,
  iA as aF,
  Eo as aG,
  ao as aH,
  ef as aI,
  os as aJ,
  KS as aK,
  ZS as aL,
  Dn as aM,
  Ze as aN,
  qi as aO,
  xh as aP,
  lb as aQ,
  ew as aR,
  Jp as aS,
  Up as aT,
  oT as aU,
  io as aV,
  aT as aW,
  is as aX,
  pr as aY,
  ZT as aZ,
  Uh as a_,
  lA as aa,
  hA as ab,
  uA as ac,
  yA as ad,
  mA as ae,
  S_ as af,
  pm as ag,
  BA as ah,
  Vk as ai,
  Vt as aj,
  Ge as ak,
  fi as al,
  hl as am,
  lf as an,
  Sr as ao,
  df as ap,
  nt as aq,
  Le as ar,
  U as as,
  vv as at,
  vA as au,
  LA as av,
  SA as aw,
  Z as ax,
  _A as ay,
  ev as az,
  eC as b,
  nT as b0,
  el as b1,
  sT as b2,
  cT as b3,
  ii as b4,
  tw as b5,
  ww as b6,
  gT as b7,
  mw as b8,
  Jn as b9,
  Sw as bA,
  tl as bB,
  vw as bC,
  MA as bD,
  Pc as ba,
  V as bb,
  pf as bc,
  ee as bd,
  eb as be,
  In as bf,
  _u as bg,
  ts as bh,
  Lu as bi,
  nA as bj,
  vy as bk,
  ri as bl,
  nw as bm,
  Vv as bn,
  rs as bo,
  oo as bp,
  or as bq,
  Lo as br,
  zh as bs,
  rl as bt,
  Xp as bu,
  Qp as bv,
  rT as bw,
  Tn as bx,
  Tw as by,
  gw as bz,
  gt as c,
  ct as d,
  cu as e,
  $t as f,
  sC as g,
  He as h,
  xe as i,
  Qk as j,
  Qi as k,
  R as l,
  cf as m,
  oA as n,
  AA as o,
  oC as p,
  aC as q,
  FA as r,
  iC as s,
  Xk as t,
  me as u,
  Y_ as v,
  Nw as w,
  CA as x,
  Xr as y,
  tC as z
};
