import { g as Nm } from "./index.js";
var gs = { exports: {} }, qm = gs.exports, vl;
function Wm() {
  return vl || (vl = 1, (function(e, t) {
    (function(r, i) {
      e.exports = i();
    })(qm, (function() {
      var r = 1e3, i = 6e4, s = 36e5, o = "millisecond", a = "second", n = "minute", l = "hour", c = "day", h = "week", d = "month", f = "quarter", u = "year", g = "date", m = "Invalid Date", y = /^(\d{4})[-/]?(\d{1,2})?[-/]?(\d{0,2})[Tt\s]*(\d{1,2})?:?(\d{1,2})?:?(\d{1,2})?[.:]?(\d+)?$/, C = /\[([^\]]+)]|Y{1,4}|M{1,4}|D{1,2}|d{1,4}|H{1,2}|h{1,2}|a|A|m{1,2}|s{1,2}|Z{1,2}|SSS/g, b = { name: "en", weekdays: "Sunday_Monday_Tuesday_Wednesday_Thursday_Friday_Saturday".split("_"), months: "January_February_March_April_May_June_July_August_September_October_November_December".split("_"), ordinal: function(M) {
        var F = ["th", "st", "nd", "rd"], L = M % 100;
        return "[" + M + (F[(L - 20) % 10] || F[L] || F[0]) + "]";
      } }, k = function(M, F, L) {
        var E = String(M);
        return !E || E.length >= F ? M : "" + Array(F + 1 - E.length).join(L) + M;
      }, T = { s: k, z: function(M) {
        var F = -M.utcOffset(), L = Math.abs(F), E = Math.floor(L / 60), D = L % 60;
        return (F <= 0 ? "+" : "-") + k(E, 2, "0") + ":" + k(D, 2, "0");
      }, m: function M(F, L) {
        if (F.date() < L.date()) return -M(L, F);
        var E = 12 * (L.year() - F.year()) + (L.month() - F.month()), D = F.clone().add(E, d), z = L - D < 0, Y = F.clone().add(E + (z ? -1 : 1), d);
        return +(-(E + (L - D) / (z ? D - Y : Y - D)) || 0);
      }, a: function(M) {
        return M < 0 ? Math.ceil(M) || 0 : Math.floor(M);
      }, p: function(M) {
        return { M: d, y: u, w: h, d: c, D: g, h: l, m: n, s: a, ms: o, Q: f }[M] || String(M || "").toLowerCase().replace(/s$/, "");
      }, u: function(M) {
        return M === void 0;
      } }, S = "en", _ = {};
      _[S] = b;
      var A = "$isDayjsObject", v = function(M) {
        return M instanceof H || !(!M || !M[A]);
      }, q = function M(F, L, E) {
        var D;
        if (!F) return S;
        if (typeof F == "string") {
          var z = F.toLowerCase();
          _[z] && (D = z), L && (_[z] = L, D = z);
          var Y = F.split("-");
          if (!D && Y.length > 1) return M(Y[0]);
        } else {
          var lt = F.name;
          _[lt] = F, D = lt;
        }
        return !E && D && (S = D), D || !E && S;
      }, I = function(M, F) {
        if (v(M)) return M.clone();
        var L = typeof F == "object" ? F : {};
        return L.date = M, L.args = arguments, new H(L);
      }, R = T;
      R.l = q, R.i = v, R.w = function(M, F) {
        return I(M, { locale: F.$L, utc: F.$u, x: F.$x, $offset: F.$offset });
      };
      var H = (function() {
        function M(L) {
          this.$L = q(L.locale, null, !0), this.parse(L), this.$x = this.$x || L.x || {}, this[A] = !0;
        }
        var F = M.prototype;
        return F.parse = function(L) {
          this.$d = (function(E) {
            var D = E.date, z = E.utc;
            if (D === null) return /* @__PURE__ */ new Date(NaN);
            if (R.u(D)) return /* @__PURE__ */ new Date();
            if (D instanceof Date) return new Date(D);
            if (typeof D == "string" && !/Z$/i.test(D)) {
              var Y = D.match(y);
              if (Y) {
                var lt = Y[2] - 1 || 0, pt = (Y[7] || "0").substring(0, 3);
                return z ? new Date(Date.UTC(Y[1], lt, Y[3] || 1, Y[4] || 0, Y[5] || 0, Y[6] || 0, pt)) : new Date(Y[1], lt, Y[3] || 1, Y[4] || 0, Y[5] || 0, Y[6] || 0, pt);
              }
            }
            return new Date(D);
          })(L), this.init();
        }, F.init = function() {
          var L = this.$d;
          this.$y = L.getFullYear(), this.$M = L.getMonth(), this.$D = L.getDate(), this.$W = L.getDay(), this.$H = L.getHours(), this.$m = L.getMinutes(), this.$s = L.getSeconds(), this.$ms = L.getMilliseconds();
        }, F.$utils = function() {
          return R;
        }, F.isValid = function() {
          return this.$d.toString() !== m;
        }, F.isSame = function(L, E) {
          var D = I(L);
          return this.startOf(E) <= D && D <= this.endOf(E);
        }, F.isAfter = function(L, E) {
          return I(L) < this.startOf(E);
        }, F.isBefore = function(L, E) {
          return this.endOf(E) < I(L);
        }, F.$g = function(L, E, D) {
          return R.u(L) ? this[E] : this.set(D, L);
        }, F.unix = function() {
          return Math.floor(this.valueOf() / 1e3);
        }, F.valueOf = function() {
          return this.$d.getTime();
        }, F.startOf = function(L, E) {
          var D = this, z = !!R.u(E) || E, Y = R.p(L), lt = function(xt, bt) {
            var kt = R.w(D.$u ? Date.UTC(D.$y, bt, xt) : new Date(D.$y, bt, xt), D);
            return z ? kt : kt.endOf(c);
          }, pt = function(xt, bt) {
            return R.w(D.toDate()[xt].apply(D.toDate("s"), (z ? [0, 0, 0, 0] : [23, 59, 59, 999]).slice(bt)), D);
          }, ut = this.$W, tt = this.$M, yt = this.$D, X = "set" + (this.$u ? "UTC" : "");
          switch (Y) {
            case u:
              return z ? lt(1, 0) : lt(31, 11);
            case d:
              return z ? lt(1, tt) : lt(0, tt + 1);
            case h:
              var ct = this.$locale().weekStart || 0, ot = (ut < ct ? ut + 7 : ut) - ct;
              return lt(z ? yt - ot : yt + (6 - ot), tt);
            case c:
            case g:
              return pt(X + "Hours", 0);
            case l:
              return pt(X + "Minutes", 1);
            case n:
              return pt(X + "Seconds", 2);
            case a:
              return pt(X + "Milliseconds", 3);
            default:
              return this.clone();
          }
        }, F.endOf = function(L) {
          return this.startOf(L, !1);
        }, F.$set = function(L, E) {
          var D, z = R.p(L), Y = "set" + (this.$u ? "UTC" : ""), lt = (D = {}, D[c] = Y + "Date", D[g] = Y + "Date", D[d] = Y + "Month", D[u] = Y + "FullYear", D[l] = Y + "Hours", D[n] = Y + "Minutes", D[a] = Y + "Seconds", D[o] = Y + "Milliseconds", D)[z], pt = z === c ? this.$D + (E - this.$W) : E;
          if (z === d || z === u) {
            var ut = this.clone().set(g, 1);
            ut.$d[lt](pt), ut.init(), this.$d = ut.set(g, Math.min(this.$D, ut.daysInMonth())).$d;
          } else lt && this.$d[lt](pt);
          return this.init(), this;
        }, F.set = function(L, E) {
          return this.clone().$set(L, E);
        }, F.get = function(L) {
          return this[R.p(L)]();
        }, F.add = function(L, E) {
          var D, z = this;
          L = Number(L);
          var Y = R.p(E), lt = function(tt) {
            var yt = I(z);
            return R.w(yt.date(yt.date() + Math.round(tt * L)), z);
          };
          if (Y === d) return this.set(d, this.$M + L);
          if (Y === u) return this.set(u, this.$y + L);
          if (Y === c) return lt(1);
          if (Y === h) return lt(7);
          var pt = (D = {}, D[n] = i, D[l] = s, D[a] = r, D)[Y] || 1, ut = this.$d.getTime() + L * pt;
          return R.w(ut, this);
        }, F.subtract = function(L, E) {
          return this.add(-1 * L, E);
        }, F.format = function(L) {
          var E = this, D = this.$locale();
          if (!this.isValid()) return D.invalidDate || m;
          var z = L || "YYYY-MM-DDTHH:mm:ssZ", Y = R.z(this), lt = this.$H, pt = this.$m, ut = this.$M, tt = D.weekdays, yt = D.months, X = D.meridiem, ct = function(bt, kt, ne, Ae) {
            return bt && (bt[kt] || bt(E, z)) || ne[kt].slice(0, Ae);
          }, ot = function(bt) {
            return R.s(lt % 12 || 12, bt, "0");
          }, xt = X || function(bt, kt, ne) {
            var Ae = bt < 12 ? "AM" : "PM";
            return ne ? Ae.toLowerCase() : Ae;
          };
          return z.replace(C, (function(bt, kt) {
            return kt || (function(ne) {
              switch (ne) {
                case "YY":
                  return String(E.$y).slice(-2);
                case "YYYY":
                  return R.s(E.$y, 4, "0");
                case "M":
                  return ut + 1;
                case "MM":
                  return R.s(ut + 1, 2, "0");
                case "MMM":
                  return ct(D.monthsShort, ut, yt, 3);
                case "MMMM":
                  return ct(yt, ut);
                case "D":
                  return E.$D;
                case "DD":
                  return R.s(E.$D, 2, "0");
                case "d":
                  return String(E.$W);
                case "dd":
                  return ct(D.weekdaysMin, E.$W, tt, 2);
                case "ddd":
                  return ct(D.weekdaysShort, E.$W, tt, 3);
                case "dddd":
                  return tt[E.$W];
                case "H":
                  return String(lt);
                case "HH":
                  return R.s(lt, 2, "0");
                case "h":
                  return ot(1);
                case "hh":
                  return ot(2);
                case "a":
                  return xt(lt, pt, !0);
                case "A":
                  return xt(lt, pt, !1);
                case "m":
                  return String(pt);
                case "mm":
                  return R.s(pt, 2, "0");
                case "s":
                  return String(E.$s);
                case "ss":
                  return R.s(E.$s, 2, "0");
                case "SSS":
                  return R.s(E.$ms, 3, "0");
                case "Z":
                  return Y;
              }
              return null;
            })(bt) || Y.replace(":", "");
          }));
        }, F.utcOffset = function() {
          return 15 * -Math.round(this.$d.getTimezoneOffset() / 15);
        }, F.diff = function(L, E, D) {
          var z, Y = this, lt = R.p(E), pt = I(L), ut = (pt.utcOffset() - this.utcOffset()) * i, tt = this - pt, yt = function() {
            return R.m(Y, pt);
          };
          switch (lt) {
            case u:
              z = yt() / 12;
              break;
            case d:
              z = yt();
              break;
            case f:
              z = yt() / 3;
              break;
            case h:
              z = (tt - ut) / 6048e5;
              break;
            case c:
              z = (tt - ut) / 864e5;
              break;
            case l:
              z = tt / s;
              break;
            case n:
              z = tt / i;
              break;
            case a:
              z = tt / r;
              break;
            default:
              z = tt;
          }
          return D ? z : R.a(z);
        }, F.daysInMonth = function() {
          return this.endOf(d).$D;
        }, F.$locale = function() {
          return _[this.$L];
        }, F.locale = function(L, E) {
          if (!L) return this.$L;
          var D = this.clone(), z = q(L, E, !0);
          return z && (D.$L = z), D;
        }, F.clone = function() {
          return R.w(this.$d, this);
        }, F.toDate = function() {
          return new Date(this.valueOf());
        }, F.toJSON = function() {
          return this.isValid() ? this.toISOString() : null;
        }, F.toISOString = function() {
          return this.$d.toISOString();
        }, F.toString = function() {
          return this.$d.toUTCString();
        }, M;
      })(), W = H.prototype;
      return I.prototype = W, [["$ms", o], ["$s", a], ["$m", n], ["$H", l], ["$W", c], ["$M", d], ["$y", u], ["$D", g]].forEach((function(M) {
        W[M[1]] = function(F) {
          return this.$g(F, M[0], M[1]);
        };
      })), I.extend = function(M, F) {
        return M.$i || (M(F, H, I), M.$i = !0), I;
      }, I.locale = q, I.isDayjs = v, I.unix = function(M) {
        return I(1e3 * M);
      }, I.en = _[S], I.Ls = _, I.p = {}, I;
    }));
  })(gs)), gs.exports;
}
var zm = Wm();
const Hm = /* @__PURE__ */ Nm(zm);
var hc = Object.defineProperty, p = (e, t) => hc(e, "name", { value: t, configurable: !0 }), Ym = (e, t) => {
  for (var r in t)
    hc(e, r, { get: t[r], enumerable: !0 });
}, $e = {
  trace: 0,
  debug: 1,
  info: 2,
  warn: 3,
  error: 4,
  fatal: 5
}, P = {
  trace: /* @__PURE__ */ p((...e) => {
  }, "trace"),
  debug: /* @__PURE__ */ p((...e) => {
  }, "debug"),
  info: /* @__PURE__ */ p((...e) => {
  }, "info"),
  warn: /* @__PURE__ */ p((...e) => {
  }, "warn"),
  error: /* @__PURE__ */ p((...e) => {
  }, "error"),
  fatal: /* @__PURE__ */ p((...e) => {
  }, "fatal")
}, an = /* @__PURE__ */ p(function(e = "fatal") {
  let t = $e.fatal;
  typeof e == "string" ? e.toLowerCase() in $e && (t = $e[e]) : typeof e == "number" && (t = e), P.trace = () => {
  }, P.debug = () => {
  }, P.info = () => {
  }, P.warn = () => {
  }, P.error = () => {
  }, P.fatal = () => {
  }, t <= $e.fatal && (P.fatal = console.error ? console.error.bind(console, se("FATAL"), "color: orange") : console.log.bind(console, "\x1B[35m", se("FATAL"))), t <= $e.error && (P.error = console.error ? console.error.bind(console, se("ERROR"), "color: orange") : console.log.bind(console, "\x1B[31m", se("ERROR"))), t <= $e.warn && (P.warn = console.warn ? console.warn.bind(console, se("WARN"), "color: orange") : console.log.bind(console, "\x1B[33m", se("WARN"))), t <= $e.info && (P.info = console.info ? console.info.bind(console, se("INFO"), "color: lightblue") : console.log.bind(console, "\x1B[34m", se("INFO"))), t <= $e.debug && (P.debug = console.debug ? console.debug.bind(console, se("DEBUG"), "color: lightgreen") : console.log.bind(console, "\x1B[32m", se("DEBUG"))), t <= $e.trace && (P.trace = console.debug ? console.debug.bind(console, se("TRACE"), "color: lightgreen") : console.log.bind(console, "\x1B[32m", se("TRACE")));
}, "setLogLevel"), se = /* @__PURE__ */ p((e) => `%c${Hm().format("ss.SSS")} : ${e} : `, "format");
const ms = {
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
        return ms.hue2rgb(o, s, e + 1 / 3) * 255;
      case "g":
        return ms.hue2rgb(o, s, e) * 255;
      case "b":
        return ms.hue2rgb(o, s, e - 1 / 3) * 255;
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
}, Um = {
  /* API */
  clamp: (e, t, r) => t > r ? Math.min(t, Math.max(r, e)) : Math.min(r, Math.max(t, e)),
  round: (e) => Math.round(e * 1e10) / 1e10
}, Gm = {
  /* API */
  dec2hex: (e) => {
    const t = Math.round(e).toString(16);
    return t.length > 1 ? t : `0${t}`;
  }
}, at = {
  channel: ms,
  lang: Um,
  unit: Gm
}, je = {};
for (let e = 0; e <= 255; e++)
  je[e] = at.unit.dec2hex(e);
const qt = {
  ALL: 0,
  RGB: 1,
  HSL: 2
};
class jm {
  constructor() {
    this.type = qt.ALL;
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
    this.type = qt.ALL;
  }
  is(t) {
    return this.type === t;
  }
}
class Xm {
  /* CONSTRUCTOR */
  constructor(t, r) {
    this.color = r, this.changed = !1, this.data = t, this.type = new jm();
  }
  /* API */
  set(t, r) {
    return this.color = r, this.changed = !1, this.data = t, this.type.type = qt.ALL, this;
  }
  /* HELPERS */
  _ensureHSL() {
    const t = this.data, { h: r, s: i, l: s } = t;
    r === void 0 && (t.h = at.channel.rgb2hsl(t, "h")), i === void 0 && (t.s = at.channel.rgb2hsl(t, "s")), s === void 0 && (t.l = at.channel.rgb2hsl(t, "l"));
  }
  _ensureRGB() {
    const t = this.data, { r, g: i, b: s } = t;
    r === void 0 && (t.r = at.channel.hsl2rgb(t, "r")), i === void 0 && (t.g = at.channel.hsl2rgb(t, "g")), s === void 0 && (t.b = at.channel.hsl2rgb(t, "b"));
  }
  /* GETTERS */
  get r() {
    const t = this.data, r = t.r;
    return !this.type.is(qt.HSL) && r !== void 0 ? r : (this._ensureHSL(), at.channel.hsl2rgb(t, "r"));
  }
  get g() {
    const t = this.data, r = t.g;
    return !this.type.is(qt.HSL) && r !== void 0 ? r : (this._ensureHSL(), at.channel.hsl2rgb(t, "g"));
  }
  get b() {
    const t = this.data, r = t.b;
    return !this.type.is(qt.HSL) && r !== void 0 ? r : (this._ensureHSL(), at.channel.hsl2rgb(t, "b"));
  }
  get h() {
    const t = this.data, r = t.h;
    return !this.type.is(qt.RGB) && r !== void 0 ? r : (this._ensureRGB(), at.channel.rgb2hsl(t, "h"));
  }
  get s() {
    const t = this.data, r = t.s;
    return !this.type.is(qt.RGB) && r !== void 0 ? r : (this._ensureRGB(), at.channel.rgb2hsl(t, "s"));
  }
  get l() {
    const t = this.data, r = t.l;
    return !this.type.is(qt.RGB) && r !== void 0 ? r : (this._ensureRGB(), at.channel.rgb2hsl(t, "l"));
  }
  get a() {
    return this.data.a;
  }
  /* SETTERS */
  set r(t) {
    this.type.set(qt.RGB), this.changed = !0, this.data.r = t;
  }
  set g(t) {
    this.type.set(qt.RGB), this.changed = !0, this.data.g = t;
  }
  set b(t) {
    this.type.set(qt.RGB), this.changed = !0, this.data.b = t;
  }
  set h(t) {
    this.type.set(qt.HSL), this.changed = !0, this.data.h = t;
  }
  set s(t) {
    this.type.set(qt.HSL), this.changed = !0, this.data.s = t;
  }
  set l(t) {
    this.type.set(qt.HSL), this.changed = !0, this.data.l = t;
  }
  set a(t) {
    this.changed = !0, this.data.a = t;
  }
}
const ao = new Xm({ r: 0, g: 0, b: 0, a: 0 }, "transparent"), zr = {
  /* VARIABLES */
  re: /^#((?:[a-f0-9]{2}){2,4}|[a-f0-9]{3})$/i,
  /* API */
  parse: (e) => {
    if (e.charCodeAt(0) !== 35)
      return;
    const t = e.match(zr.re);
    if (!t)
      return;
    const r = t[1], i = parseInt(r, 16), s = r.length, o = s % 4 === 0, a = s > 4, n = a ? 1 : 17, l = a ? 8 : 4, c = o ? 0 : -1, h = a ? 255 : 15;
    return ao.set({
      r: (i >> l * (c + 3) & h) * n,
      g: (i >> l * (c + 2) & h) * n,
      b: (i >> l * (c + 1) & h) * n,
      a: o ? (i & h) * n / 255 : 1
    }, e);
  },
  stringify: (e) => {
    const { r: t, g: r, b: i, a: s } = e;
    return s < 1 ? `#${je[Math.round(t)]}${je[Math.round(r)]}${je[Math.round(i)]}${je[Math.round(s * 255)]}` : `#${je[Math.round(t)]}${je[Math.round(r)]}${je[Math.round(i)]}`;
  }
}, dr = {
  /* VARIABLES */
  re: /^hsla?\(\s*?(-?(?:\d+(?:\.\d+)?|(?:\.\d+))(?:e-?\d+)?(?:deg|grad|rad|turn)?)\s*?(?:,|\s)\s*?(-?(?:\d+(?:\.\d+)?|(?:\.\d+))(?:e-?\d+)?%)\s*?(?:,|\s)\s*?(-?(?:\d+(?:\.\d+)?|(?:\.\d+))(?:e-?\d+)?%)(?:\s*?(?:,|\/)\s*?\+?(-?(?:\d+(?:\.\d+)?|(?:\.\d+))(?:e-?\d+)?(%)?))?\s*?\)$/i,
  hueRe: /^(.+?)(deg|grad|rad|turn)$/i,
  /* HELPERS */
  _hue2deg: (e) => {
    const t = e.match(dr.hueRe);
    if (t) {
      const [, r, i] = t;
      switch (i) {
        case "grad":
          return at.channel.clamp.h(parseFloat(r) * 0.9);
        case "rad":
          return at.channel.clamp.h(parseFloat(r) * 180 / Math.PI);
        case "turn":
          return at.channel.clamp.h(parseFloat(r) * 360);
      }
    }
    return at.channel.clamp.h(parseFloat(e));
  },
  /* API */
  parse: (e) => {
    const t = e.charCodeAt(0);
    if (t !== 104 && t !== 72)
      return;
    const r = e.match(dr.re);
    if (!r)
      return;
    const [, i, s, o, a, n] = r;
    return ao.set({
      h: dr._hue2deg(i),
      s: at.channel.clamp.s(parseFloat(s)),
      l: at.channel.clamp.l(parseFloat(o)),
      a: a ? at.channel.clamp.a(n ? parseFloat(a) / 100 : parseFloat(a)) : 1
    }, e);
  },
  stringify: (e) => {
    const { h: t, s: r, l: i, a: s } = e;
    return s < 1 ? `hsla(${at.lang.round(t)}, ${at.lang.round(r)}%, ${at.lang.round(i)}%, ${s})` : `hsl(${at.lang.round(t)}, ${at.lang.round(r)}%, ${at.lang.round(i)}%)`;
  }
}, Ti = {
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
    const t = Ti.colors[e];
    if (t)
      return zr.parse(t);
  },
  stringify: (e) => {
    const t = zr.stringify(e);
    for (const r in Ti.colors)
      if (Ti.colors[r] === t)
        return r;
  }
}, pi = {
  /* VARIABLES */
  re: /^rgba?\(\s*?(-?(?:\d+(?:\.\d+)?|(?:\.\d+))(?:e\d+)?(%?))\s*?(?:,|\s)\s*?(-?(?:\d+(?:\.\d+)?|(?:\.\d+))(?:e\d+)?(%?))\s*?(?:,|\s)\s*?(-?(?:\d+(?:\.\d+)?|(?:\.\d+))(?:e\d+)?(%?))(?:\s*?(?:,|\/)\s*?\+?(-?(?:\d+(?:\.\d+)?|(?:\.\d+))(?:e\d+)?(%?)))?\s*?\)$/i,
  /* API */
  parse: (e) => {
    const t = e.charCodeAt(0);
    if (t !== 114 && t !== 82)
      return;
    const r = e.match(pi.re);
    if (!r)
      return;
    const [, i, s, o, a, n, l, c, h] = r;
    return ao.set({
      r: at.channel.clamp.r(s ? parseFloat(i) * 2.55 : parseFloat(i)),
      g: at.channel.clamp.g(a ? parseFloat(o) * 2.55 : parseFloat(o)),
      b: at.channel.clamp.b(l ? parseFloat(n) * 2.55 : parseFloat(n)),
      a: c ? at.channel.clamp.a(h ? parseFloat(c) / 100 : parseFloat(c)) : 1
    }, e);
  },
  stringify: (e) => {
    const { r: t, g: r, b: i, a: s } = e;
    return s < 1 ? `rgba(${at.lang.round(t)}, ${at.lang.round(r)}, ${at.lang.round(i)}, ${at.lang.round(s)})` : `rgb(${at.lang.round(t)}, ${at.lang.round(r)}, ${at.lang.round(i)})`;
  }
}, _e = {
  /* VARIABLES */
  format: {
    keyword: Ti,
    hex: zr,
    rgb: pi,
    rgba: pi,
    hsl: dr,
    hsla: dr
  },
  /* API */
  parse: (e) => {
    if (typeof e != "string")
      return e;
    const t = zr.parse(e) || pi.parse(e) || dr.parse(e) || Ti.parse(e);
    if (t)
      return t;
    throw new Error(`Unsupported color format: "${e}"`);
  },
  stringify: (e) => !e.changed && e.color ? e.color : e.type.is(qt.HSL) || e.data.r === void 0 ? dr.stringify(e) : e.a < 1 || !Number.isInteger(e.r) || !Number.isInteger(e.g) || !Number.isInteger(e.b) ? pi.stringify(e) : zr.stringify(e)
}, cc = (e, t) => {
  const r = _e.parse(e);
  for (const i in t)
    r[i] = at.channel.clamp[i](t[i]);
  return _e.stringify(r);
}, Ke = (e, t, r = 0, i = 1) => {
  if (typeof e != "number")
    return cc(e, { a: t });
  const s = ao.set({
    r: at.channel.clamp.r(e),
    g: at.channel.clamp.g(t),
    b: at.channel.clamp.b(r),
    a: at.channel.clamp.a(i)
  });
  return _e.stringify(s);
}, Vm = (e) => {
  const { r: t, g: r, b: i } = _e.parse(e), s = 0.2126 * at.channel.toLinear(t) + 0.7152 * at.channel.toLinear(r) + 0.0722 * at.channel.toLinear(i);
  return at.lang.round(s);
}, Zm = (e) => Vm(e) >= 0.5, ye = (e) => !Zm(e), dc = (e, t, r) => {
  const i = _e.parse(e), s = i[t], o = at.channel.clamp[t](s + r);
  return s !== o && (i[t] = o), _e.stringify(i);
}, $ = (e, t) => dc(e, "l", t), O = (e, t) => dc(e, "l", -t), x = (e, t) => {
  const r = _e.parse(e), i = {};
  for (const s in t)
    t[s] && (i[s] = r[s] + t[s]);
  return cc(e, i);
}, Km = (e, t, r = 50) => {
  const { r: i, g: s, b: o, a } = _e.parse(e), { r: n, g: l, b: c, a: h } = _e.parse(t), d = r / 100, f = d * 2 - 1, u = a - h, m = ((f * u === -1 ? f : (f + u) / (1 + f * u)) + 1) / 2, y = 1 - m, C = i * m + n * y, b = s * m + l * y, k = o * m + c * y, T = a * d + h * (1 - d);
  return Ke(C, b, k, T);
}, B = (e, t = 100) => {
  const r = _e.parse(e);
  return r.r = 255 - r.r, r.g = 255 - r.g, r.b = 255 - r.b, Km(r, e, t);
};
/*! @license DOMPurify 3.4.5 | (c) Cure53 and other contributors | Released under the Apache license 2.0 and Mozilla Public License 2.0 | github.com/cure53/DOMPurify/blob/3.4.5/LICENSE */
function Ll(e, t) {
  (t == null || t > e.length) && (t = e.length);
  for (var r = 0, i = Array(t); r < t; r++) i[r] = e[r];
  return i;
}
function Qm(e) {
  if (Array.isArray(e)) return e;
}
function Jm(e, t) {
  var r = e == null ? null : typeof Symbol < "u" && e[Symbol.iterator] || e["@@iterator"];
  if (r != null) {
    var i, s, o, a, n = [], l = !0, c = !1;
    try {
      if (o = (r = r.call(e)).next, t !== 0) for (; !(l = (i = o.call(r)).done) && (n.push(i.value), n.length !== t); l = !0) ;
    } catch (h) {
      c = !0, s = h;
    } finally {
      try {
        if (!l && r.return != null && (a = r.return(), Object(a) !== a)) return;
      } finally {
        if (c) throw s;
      }
    }
    return n;
  }
}
function ty() {
  throw new TypeError(`Invalid attempt to destructure non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`);
}
function ey(e, t) {
  return Qm(e) || Jm(e, t) || ry(e, t) || ty();
}
function ry(e, t) {
  if (e) {
    if (typeof e == "string") return Ll(e, t);
    var r = {}.toString.call(e).slice(8, -1);
    return r === "Object" && e.constructor && (r = e.constructor.name), r === "Map" || r === "Set" ? Array.from(e) : r === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(r) ? Ll(e, t) : void 0;
  }
}
const uc = Object.entries, Fl = Object.setPrototypeOf, iy = Object.isFrozen, sy = Object.getPrototypeOf, oy = Object.getOwnPropertyDescriptor;
let Xt = Object.freeze, oe = Object.seal, Dr = Object.create, fc = typeof Reflect < "u" && Reflect, oa = fc.apply, aa = fc.construct;
Xt || (Xt = function(t) {
  return t;
});
oe || (oe = function(t) {
  return t;
});
oa || (oa = function(t, r) {
  for (var i = arguments.length, s = new Array(i > 2 ? i - 2 : 0), o = 2; o < i; o++)
    s[o - 2] = arguments[o];
  return t.apply(r, s);
});
aa || (aa = function(t) {
  for (var r = arguments.length, i = new Array(r > 1 ? r - 1 : 0), s = 1; s < r; s++)
    i[s - 1] = arguments[s];
  return new t(...i);
});
const Fr = At(Array.prototype.forEach), ay = At(Array.prototype.lastIndexOf), Al = At(Array.prototype.pop), Ar = At(Array.prototype.push), ny = At(Array.prototype.splice), Ut = Array.isArray, gi = At(String.prototype.toLowerCase), No = At(String.prototype.toString), Ml = At(String.prototype.match), Mr = At(String.prototype.replace), El = At(String.prototype.indexOf), ly = At(String.prototype.trim), hy = At(Number.prototype.toString), cy = At(Boolean.prototype.toString), $l = typeof BigInt > "u" ? null : At(BigInt.prototype.toString), Ol = typeof Symbol > "u" ? null : At(Symbol.prototype.toString), _t = At(Object.prototype.hasOwnProperty), ai = At(Object.prototype.toString), Rt = At(RegExp.prototype.test), rs = dy(TypeError);
function At(e) {
  return function(t) {
    t instanceof RegExp && (t.lastIndex = 0);
    for (var r = arguments.length, i = new Array(r > 1 ? r - 1 : 0), s = 1; s < r; s++)
      i[s - 1] = arguments[s];
    return oa(e, t, i);
  };
}
function dy(e) {
  return function() {
    for (var t = arguments.length, r = new Array(t), i = 0; i < t; i++)
      r[i] = arguments[i];
    return aa(e, r);
  };
}
function nt(e, t) {
  let r = arguments.length > 2 && arguments[2] !== void 0 ? arguments[2] : gi;
  if (Fl && Fl(e, null), !Ut(t))
    return e;
  let i = t.length;
  for (; i--; ) {
    let s = t[i];
    if (typeof s == "string") {
      const o = r(s);
      o !== s && (iy(t) || (t[i] = o), s = o);
    }
    e[s] = !0;
  }
  return e;
}
function uy(e) {
  for (let t = 0; t < e.length; t++)
    _t(e, t) || (e[t] = null);
  return e;
}
function Qt(e) {
  const t = Dr(null);
  for (const i of uc(e)) {
    var r = ey(i, 2);
    const s = r[0], o = r[1];
    _t(e, s) && (Ut(o) ? t[s] = uy(o) : o && typeof o == "object" && o.constructor === Object ? t[s] = Qt(o) : t[s] = o);
  }
  return t;
}
function fy(e) {
  switch (typeof e) {
    case "string":
      return e;
    case "number":
      return hy(e);
    case "boolean":
      return cy(e);
    case "bigint":
      return $l ? $l(e) : "0";
    case "symbol":
      return Ol ? Ol(e) : "Symbol()";
    case "undefined":
      return ai(e);
    case "function":
    case "object": {
      if (e === null)
        return ai(e);
      const t = e, r = lr(t, "toString");
      if (typeof r == "function") {
        const i = r(t);
        return typeof i == "string" ? i : ai(i);
      }
      return ai(e);
    }
    default:
      return ai(e);
  }
}
function lr(e, t) {
  for (; e !== null; ) {
    const i = oy(e, t);
    if (i) {
      if (i.get)
        return At(i.get);
      if (typeof i.value == "function")
        return At(i.value);
    }
    e = sy(e);
  }
  function r() {
    return null;
  }
  return r;
}
function py(e) {
  try {
    return Rt(e, ""), !0;
  } catch {
    return !1;
  }
}
const Il = Xt(["a", "abbr", "acronym", "address", "area", "article", "aside", "audio", "b", "bdi", "bdo", "big", "blink", "blockquote", "body", "br", "button", "canvas", "caption", "center", "cite", "code", "col", "colgroup", "content", "data", "datalist", "dd", "decorator", "del", "details", "dfn", "dialog", "dir", "div", "dl", "dt", "element", "em", "fieldset", "figcaption", "figure", "font", "footer", "form", "h1", "h2", "h3", "h4", "h5", "h6", "head", "header", "hgroup", "hr", "html", "i", "img", "input", "ins", "kbd", "label", "legend", "li", "main", "map", "mark", "marquee", "menu", "menuitem", "meter", "nav", "nobr", "ol", "optgroup", "option", "output", "p", "picture", "pre", "progress", "q", "rp", "rt", "ruby", "s", "samp", "search", "section", "select", "shadow", "slot", "small", "source", "spacer", "span", "strike", "strong", "style", "sub", "summary", "sup", "table", "tbody", "td", "template", "textarea", "tfoot", "th", "thead", "time", "tr", "track", "tt", "u", "ul", "var", "video", "wbr"]), qo = Xt(["svg", "a", "altglyph", "altglyphdef", "altglyphitem", "animatecolor", "animatemotion", "animatetransform", "circle", "clippath", "defs", "desc", "ellipse", "enterkeyhint", "exportparts", "filter", "font", "g", "glyph", "glyphref", "hkern", "image", "inputmode", "line", "lineargradient", "marker", "mask", "metadata", "mpath", "part", "path", "pattern", "polygon", "polyline", "radialgradient", "rect", "stop", "style", "switch", "symbol", "text", "textpath", "title", "tref", "tspan", "view", "vkern"]), Wo = Xt(["feBlend", "feColorMatrix", "feComponentTransfer", "feComposite", "feConvolveMatrix", "feDiffuseLighting", "feDisplacementMap", "feDistantLight", "feDropShadow", "feFlood", "feFuncA", "feFuncB", "feFuncG", "feFuncR", "feGaussianBlur", "feImage", "feMerge", "feMergeNode", "feMorphology", "feOffset", "fePointLight", "feSpecularLighting", "feSpotLight", "feTile", "feTurbulence"]), gy = Xt(["animate", "color-profile", "cursor", "discard", "font-face", "font-face-format", "font-face-name", "font-face-src", "font-face-uri", "foreignobject", "hatch", "hatchpath", "mesh", "meshgradient", "meshpatch", "meshrow", "missing-glyph", "script", "set", "solidcolor", "unknown", "use"]), zo = Xt(["math", "menclose", "merror", "mfenced", "mfrac", "mglyph", "mi", "mlabeledtr", "mmultiscripts", "mn", "mo", "mover", "mpadded", "mphantom", "mroot", "mrow", "ms", "mspace", "msqrt", "mstyle", "msub", "msup", "msubsup", "mtable", "mtd", "mtext", "mtr", "munder", "munderover", "mprescripts"]), my = Xt(["maction", "maligngroup", "malignmark", "mlongdiv", "mscarries", "mscarry", "msgroup", "mstack", "msline", "msrow", "semantics", "annotation", "annotation-xml", "mprescripts", "none"]), Dl = Xt(["#text"]), Rl = Xt(["accept", "action", "align", "alt", "autocapitalize", "autocomplete", "autopictureinpicture", "autoplay", "background", "bgcolor", "border", "capture", "cellpadding", "cellspacing", "checked", "cite", "class", "clear", "color", "cols", "colspan", "command", "commandfor", "controls", "controlslist", "coords", "crossorigin", "datetime", "decoding", "default", "dir", "disabled", "disablepictureinpicture", "disableremoteplayback", "download", "draggable", "enctype", "enterkeyhint", "exportparts", "face", "for", "headers", "height", "hidden", "high", "href", "hreflang", "id", "inert", "inputmode", "integrity", "ismap", "kind", "label", "lang", "list", "loading", "loop", "low", "max", "maxlength", "media", "method", "min", "minlength", "multiple", "muted", "name", "nonce", "noshade", "novalidate", "nowrap", "open", "optimum", "part", "pattern", "placeholder", "playsinline", "popover", "popovertarget", "popovertargetaction", "poster", "preload", "pubdate", "radiogroup", "readonly", "rel", "required", "rev", "reversed", "role", "rows", "rowspan", "spellcheck", "scope", "selected", "shape", "size", "sizes", "slot", "span", "srclang", "start", "src", "srcset", "step", "style", "summary", "tabindex", "title", "translate", "type", "usemap", "valign", "value", "width", "wrap", "xmlns"]), Ho = Xt(["accent-height", "accumulate", "additive", "alignment-baseline", "amplitude", "ascent", "attributename", "attributetype", "azimuth", "basefrequency", "baseline-shift", "begin", "bias", "by", "class", "clip", "clippathunits", "clip-path", "clip-rule", "color", "color-interpolation", "color-interpolation-filters", "color-profile", "color-rendering", "cx", "cy", "d", "dx", "dy", "diffuseconstant", "direction", "display", "divisor", "dur", "edgemode", "elevation", "end", "exponent", "fill", "fill-opacity", "fill-rule", "filter", "filterunits", "flood-color", "flood-opacity", "font-family", "font-size", "font-size-adjust", "font-stretch", "font-style", "font-variant", "font-weight", "fx", "fy", "g1", "g2", "glyph-name", "glyphref", "gradientunits", "gradienttransform", "height", "href", "id", "image-rendering", "in", "in2", "intercept", "k", "k1", "k2", "k3", "k4", "kerning", "keypoints", "keysplines", "keytimes", "lang", "lengthadjust", "letter-spacing", "kernelmatrix", "kernelunitlength", "lighting-color", "local", "marker-end", "marker-mid", "marker-start", "markerheight", "markerunits", "markerwidth", "maskcontentunits", "maskunits", "max", "mask", "mask-type", "media", "method", "mode", "min", "name", "numoctaves", "offset", "operator", "opacity", "order", "orient", "orientation", "origin", "overflow", "paint-order", "path", "pathlength", "patterncontentunits", "patterntransform", "patternunits", "points", "preservealpha", "preserveaspectratio", "primitiveunits", "r", "rx", "ry", "radius", "refx", "refy", "repeatcount", "repeatdur", "restart", "result", "rotate", "scale", "seed", "shape-rendering", "slope", "specularconstant", "specularexponent", "spreadmethod", "startoffset", "stddeviation", "stitchtiles", "stop-color", "stop-opacity", "stroke-dasharray", "stroke-dashoffset", "stroke-linecap", "stroke-linejoin", "stroke-miterlimit", "stroke-opacity", "stroke", "stroke-width", "style", "surfacescale", "systemlanguage", "tabindex", "tablevalues", "targetx", "targety", "transform", "transform-origin", "text-anchor", "text-decoration", "text-rendering", "textlength", "type", "u1", "u2", "unicode", "values", "viewbox", "visibility", "version", "vert-adv-y", "vert-origin-x", "vert-origin-y", "width", "word-spacing", "wrap", "writing-mode", "xchannelselector", "ychannelselector", "x", "x1", "x2", "xmlns", "y", "y1", "y2", "z", "zoomandpan"]), Pl = Xt(["accent", "accentunder", "align", "bevelled", "close", "columnalign", "columnlines", "columnspacing", "columnspan", "denomalign", "depth", "dir", "display", "displaystyle", "encoding", "fence", "frame", "height", "href", "id", "largeop", "length", "linethickness", "lquote", "lspace", "mathbackground", "mathcolor", "mathsize", "mathvariant", "maxsize", "minsize", "movablelimits", "notation", "numalign", "open", "rowalign", "rowlines", "rowspacing", "rowspan", "rspace", "rquote", "scriptlevel", "scriptminsize", "scriptsizemultiplier", "selection", "separator", "separators", "stretchy", "subscriptshift", "supscriptshift", "symmetric", "voffset", "width", "xmlns"]), is = Xt(["xlink:href", "xml:id", "xlink:title", "xml:space", "xmlns:xlink"]), yy = oe(/{{[\w\W]*|^[\w\W]*}}/g), Cy = oe(/<%[\w\W]*|^[\w\W]*%>/g), xy = oe(/\${[\w\W]*/g), by = oe(/^data-[\-\w.\u00B7-\uFFFF]+$/), ky = oe(/^aria-[\-\w]+$/), Nl = oe(
  /^(?:(?:(?:f|ht)tps?|mailto|tel|callto|sms|cid|xmpp|matrix):|[^a-z]|[a-z+.\-]+(?:[^a-z+.\-:]|$))/i
  // eslint-disable-line no-useless-escape
), wy = oe(/^(?:\w+script|data):/i), Ty = oe(
  /[\u0000-\u0020\u00A0\u1680\u180E\u2000-\u2029\u205F\u3000]/g
  // eslint-disable-line no-control-regex
), Sy = oe(/^html$/i), _y = oe(/^[a-z][.\w]*(-[.\w]+)+$/i), Er = {
  element: 1,
  text: 3,
  // Deprecated
  progressingInstruction: 7,
  comment: 8,
  document: 9
}, By = function() {
  return typeof window > "u" ? null : window;
}, vy = function(t, r) {
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
}, ql = function() {
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
function pc() {
  let e = arguments.length > 0 && arguments[0] !== void 0 ? arguments[0] : By();
  const t = (J) => pc(J);
  if (t.version = "3.4.5", t.removed = [], !e || !e.document || e.document.nodeType !== Er.document || !e.Element)
    return t.isSupported = !1, t;
  let r = e.document;
  const i = r, s = i.currentScript, o = e.DocumentFragment, a = e.HTMLTemplateElement, n = e.Node, l = e.Element, c = e.NodeFilter, h = e.NamedNodeMap, d = h === void 0 ? e.NamedNodeMap || e.MozNamedAttrMap : h, f = e.HTMLFormElement, u = e.DOMParser, g = e.trustedTypes, m = l.prototype, y = lr(m, "cloneNode"), C = lr(m, "remove"), b = lr(m, "nextSibling"), k = lr(m, "childNodes"), T = lr(m, "parentNode"), S = n && n.prototype ? lr(n.prototype, "nodeType") : null;
  if (typeof a == "function") {
    const J = r.createElement("template");
    J.content && J.content.ownerDocument && (r = J.content.ownerDocument);
  }
  let _, A = "";
  const v = r, q = v.implementation, I = v.createNodeIterator, R = v.createDocumentFragment, H = v.getElementsByTagName, W = i.importNode;
  let M = ql();
  t.isSupported = typeof uc == "function" && typeof T == "function" && q && q.createHTMLDocument !== void 0;
  const F = yy, L = Cy, E = xy, D = by, z = ky, Y = wy, lt = Ty, pt = _y;
  let ut = Nl, tt = null;
  const yt = nt({}, [...Il, ...qo, ...Wo, ...zo, ...Dl]);
  let X = null;
  const ct = nt({}, [...Rl, ...Ho, ...Pl, ...is]);
  let ot = Object.seal(Dr(null, {
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
  })), xt = null, bt = null;
  const kt = Object.seal(Dr(null, {
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
  let ne = !0, Ae = !0, Sr = !1, ll = !0, Ue = !1, ii = !0, sr = !1, Bo = !1, vo = !1, _r = !1, Zi = !1, Ki = !1, hl = !0, cl = !1;
  const dl = "user-content-";
  let Lo = !0, si = !1, Br = {}, xe = null;
  const Fo = nt({}, ["annotation-xml", "audio", "colgroup", "desc", "foreignobject", "head", "iframe", "math", "mi", "mn", "mo", "ms", "mtext", "noembed", "noframes", "noscript", "plaintext", "script", "style", "svg", "template", "thead", "title", "video", "xmp"]);
  let ul = null;
  const fl = nt({}, ["audio", "video", "img", "source", "image", "track"]);
  let Ao = null;
  const pl = nt({}, ["alt", "class", "for", "id", "label", "name", "pattern", "placeholder", "role", "summary", "title", "value", "style", "xmlns"]), Qi = "http://www.w3.org/1998/Math/MathML", Ji = "http://www.w3.org/2000/svg", be = "http://www.w3.org/1999/xhtml";
  let vr = be, Mo = !1, Eo = null;
  const Em = nt({}, [Qi, Ji, be], No);
  let $o = nt({}, ["mi", "mo", "mn", "ms", "mtext"]), Oo = nt({}, ["annotation-xml"]);
  const $m = nt({}, ["title", "style", "font", "a", "script"]);
  let oi = null;
  const Om = ["application/xhtml+xml", "text/html"], Im = "text/html";
  let Mt = null, Lr = null;
  const Dm = r.createElement("form"), gl = function(w) {
    return w instanceof RegExp || w instanceof Function;
  }, Io = function() {
    let w = arguments.length > 0 && arguments[0] !== void 0 ? arguments[0] : {};
    if (Lr && Lr === w)
      return;
    (!w || typeof w != "object") && (w = {}), w = Qt(w), oi = // eslint-disable-next-line unicorn/prefer-includes
    Om.indexOf(w.PARSER_MEDIA_TYPE) === -1 ? Im : w.PARSER_MEDIA_TYPE, Mt = oi === "application/xhtml+xml" ? No : gi, tt = _t(w, "ALLOWED_TAGS") && Ut(w.ALLOWED_TAGS) ? nt({}, w.ALLOWED_TAGS, Mt) : yt, X = _t(w, "ALLOWED_ATTR") && Ut(w.ALLOWED_ATTR) ? nt({}, w.ALLOWED_ATTR, Mt) : ct, Eo = _t(w, "ALLOWED_NAMESPACES") && Ut(w.ALLOWED_NAMESPACES) ? nt({}, w.ALLOWED_NAMESPACES, No) : Em, Ao = _t(w, "ADD_URI_SAFE_ATTR") && Ut(w.ADD_URI_SAFE_ATTR) ? nt(Qt(pl), w.ADD_URI_SAFE_ATTR, Mt) : pl, ul = _t(w, "ADD_DATA_URI_TAGS") && Ut(w.ADD_DATA_URI_TAGS) ? nt(Qt(fl), w.ADD_DATA_URI_TAGS, Mt) : fl, xe = _t(w, "FORBID_CONTENTS") && Ut(w.FORBID_CONTENTS) ? nt({}, w.FORBID_CONTENTS, Mt) : Fo, xt = _t(w, "FORBID_TAGS") && Ut(w.FORBID_TAGS) ? nt({}, w.FORBID_TAGS, Mt) : Qt({}), bt = _t(w, "FORBID_ATTR") && Ut(w.FORBID_ATTR) ? nt({}, w.FORBID_ATTR, Mt) : Qt({}), Br = _t(w, "USE_PROFILES") ? w.USE_PROFILES && typeof w.USE_PROFILES == "object" ? Qt(w.USE_PROFILES) : w.USE_PROFILES : !1, ne = w.ALLOW_ARIA_ATTR !== !1, Ae = w.ALLOW_DATA_ATTR !== !1, Sr = w.ALLOW_UNKNOWN_PROTOCOLS || !1, ll = w.ALLOW_SELF_CLOSE_IN_ATTR !== !1, Ue = w.SAFE_FOR_TEMPLATES || !1, ii = w.SAFE_FOR_XML !== !1, sr = w.WHOLE_DOCUMENT || !1, _r = w.RETURN_DOM || !1, Zi = w.RETURN_DOM_FRAGMENT || !1, Ki = w.RETURN_TRUSTED_TYPE || !1, vo = w.FORCE_BODY || !1, hl = w.SANITIZE_DOM !== !1, cl = w.SANITIZE_NAMED_PROPS || !1, Lo = w.KEEP_CONTENT !== !1, si = w.IN_PLACE || !1, ut = py(w.ALLOWED_URI_REGEXP) ? w.ALLOWED_URI_REGEXP : Nl, vr = typeof w.NAMESPACE == "string" ? w.NAMESPACE : be, $o = _t(w, "MATHML_TEXT_INTEGRATION_POINTS") && w.MATHML_TEXT_INTEGRATION_POINTS && typeof w.MATHML_TEXT_INTEGRATION_POINTS == "object" ? Qt(w.MATHML_TEXT_INTEGRATION_POINTS) : nt({}, ["mi", "mo", "mn", "ms", "mtext"]), Oo = _t(w, "HTML_INTEGRATION_POINTS") && w.HTML_INTEGRATION_POINTS && typeof w.HTML_INTEGRATION_POINTS == "object" ? Qt(w.HTML_INTEGRATION_POINTS) : nt({}, ["annotation-xml"]);
    const N = _t(w, "CUSTOM_ELEMENT_HANDLING") && w.CUSTOM_ELEMENT_HANDLING && typeof w.CUSTOM_ELEMENT_HANDLING == "object" ? Qt(w.CUSTOM_ELEMENT_HANDLING) : Dr(null);
    if (ot = Dr(null), _t(N, "tagNameCheck") && gl(N.tagNameCheck) && (ot.tagNameCheck = N.tagNameCheck), _t(N, "attributeNameCheck") && gl(N.attributeNameCheck) && (ot.attributeNameCheck = N.attributeNameCheck), _t(N, "allowCustomizedBuiltInElements") && typeof N.allowCustomizedBuiltInElements == "boolean" && (ot.allowCustomizedBuiltInElements = N.allowCustomizedBuiltInElements), Ue && (Ae = !1), Zi && (_r = !0), Br && (tt = nt({}, Dl), X = Dr(null), Br.html === !0 && (nt(tt, Il), nt(X, Rl)), Br.svg === !0 && (nt(tt, qo), nt(X, Ho), nt(X, is)), Br.svgFilters === !0 && (nt(tt, Wo), nt(X, Ho), nt(X, is)), Br.mathMl === !0 && (nt(tt, zo), nt(X, Pl), nt(X, is))), kt.tagCheck = null, kt.attributeCheck = null, _t(w, "ADD_TAGS") && (typeof w.ADD_TAGS == "function" ? kt.tagCheck = w.ADD_TAGS : Ut(w.ADD_TAGS) && (tt === yt && (tt = Qt(tt)), nt(tt, w.ADD_TAGS, Mt))), _t(w, "ADD_ATTR") && (typeof w.ADD_ATTR == "function" ? kt.attributeCheck = w.ADD_ATTR : Ut(w.ADD_ATTR) && (X === ct && (X = Qt(X)), nt(X, w.ADD_ATTR, Mt))), _t(w, "ADD_URI_SAFE_ATTR") && Ut(w.ADD_URI_SAFE_ATTR) && nt(Ao, w.ADD_URI_SAFE_ATTR, Mt), _t(w, "FORBID_CONTENTS") && Ut(w.FORBID_CONTENTS) && (xe === Fo && (xe = Qt(xe)), nt(xe, w.FORBID_CONTENTS, Mt)), _t(w, "ADD_FORBID_CONTENTS") && Ut(w.ADD_FORBID_CONTENTS) && (xe === Fo && (xe = Qt(xe)), nt(xe, w.ADD_FORBID_CONTENTS, Mt)), Lo && (tt["#text"] = !0), sr && nt(tt, ["html", "head", "body"]), tt.table && (nt(tt, ["tbody"]), delete xt.tbody), w.TRUSTED_TYPES_POLICY) {
      if (typeof w.TRUSTED_TYPES_POLICY.createHTML != "function")
        throw rs('TRUSTED_TYPES_POLICY configuration option must provide a "createHTML" hook.');
      if (typeof w.TRUSTED_TYPES_POLICY.createScriptURL != "function")
        throw rs('TRUSTED_TYPES_POLICY configuration option must provide a "createScriptURL" hook.');
      _ = w.TRUSTED_TYPES_POLICY, A = _.createHTML("");
    } else
      _ === void 0 && (_ = vy(g, s)), _ !== null && typeof A == "string" && (A = _.createHTML(""));
    Xt && Xt(w), Lr = w;
  }, ml = nt({}, [...qo, ...Wo, ...gy]), yl = nt({}, [...zo, ...my]), Rm = function(w) {
    let N = T(w);
    (!N || !N.tagName) && (N = {
      namespaceURI: vr,
      tagName: "template"
    });
    const U = gi(w.tagName), dt = gi(N.tagName);
    return Eo[w.namespaceURI] ? w.namespaceURI === Ji ? N.namespaceURI === be ? U === "svg" : N.namespaceURI === Qi ? U === "svg" && (dt === "annotation-xml" || $o[dt]) : !!ml[U] : w.namespaceURI === Qi ? N.namespaceURI === be ? U === "math" : N.namespaceURI === Ji ? U === "math" && Oo[dt] : !!yl[U] : w.namespaceURI === be ? N.namespaceURI === Ji && !Oo[dt] || N.namespaceURI === Qi && !$o[dt] ? !1 : !yl[U] && ($m[U] || !ml[U]) : !!(oi === "application/xhtml+xml" && Eo[w.namespaceURI]) : !1;
  }, le = function(w) {
    Ar(t.removed, {
      element: w
    });
    try {
      T(w).removeChild(w);
    } catch {
      C(w);
    }
  }, or = function(w, N) {
    try {
      Ar(t.removed, {
        attribute: N.getAttributeNode(w),
        from: N
      });
    } catch {
      Ar(t.removed, {
        attribute: null,
        from: N
      });
    }
    if (N.removeAttribute(w), w === "is")
      if (_r || Zi)
        try {
          le(N);
        } catch {
        }
      else
        try {
          N.setAttribute(w, "");
        } catch {
        }
  }, Cl = function(w) {
    let N = null, U = null;
    if (vo)
      w = "<remove></remove>" + w;
    else {
      const Lt = Ml(w, /^[\r\n\t ]+/);
      U = Lt && Lt[0];
    }
    oi === "application/xhtml+xml" && vr === be && (w = '<html xmlns="http://www.w3.org/1999/xhtml"><head></head><body>' + w + "</body></html>");
    const dt = _ ? _.createHTML(w) : w;
    if (vr === be)
      try {
        N = new u().parseFromString(dt, oi);
      } catch {
      }
    if (!N || !N.documentElement) {
      N = q.createDocument(vr, "template", null);
      try {
        N.documentElement.innerHTML = Mo ? A : dt;
      } catch {
      }
    }
    const vt = N.body || N.documentElement;
    return w && U && vt.insertBefore(r.createTextNode(U), vt.childNodes[0] || null), vr === be ? H.call(N, sr ? "html" : "body")[0] : sr ? N.documentElement : vt;
  }, xl = function(w) {
    return I.call(
      w.ownerDocument || w,
      w,
      // eslint-disable-next-line no-bitwise
      c.SHOW_ELEMENT | c.SHOW_COMMENT | c.SHOW_TEXT | c.SHOW_PROCESSING_INSTRUCTION | c.SHOW_CDATA_SECTION,
      null
    );
  }, bl = function(w) {
    w.normalize();
    const N = I.call(
      w.ownerDocument || w,
      w,
      // eslint-disable-next-line no-bitwise
      c.SHOW_TEXT | c.SHOW_COMMENT | c.SHOW_CDATA_SECTION | c.SHOW_PROCESSING_INSTRUCTION,
      null
    );
    let U = N.nextNode();
    for (; U; ) {
      let dt = U.data;
      Fr([F, L, E], (vt) => {
        dt = Mr(dt, vt, " ");
      }), U.data = dt, U = N.nextNode();
    }
  }, Do = function(w) {
    return w instanceof f && (typeof w.nodeName != "string" || typeof w.textContent != "string" || typeof w.removeChild != "function" || !(w.attributes instanceof d) || typeof w.removeAttribute != "function" || typeof w.setAttribute != "function" || typeof w.namespaceURI != "string" || typeof w.insertBefore != "function" || typeof w.hasChildNodes != "function");
  }, ts = function(w) {
    if (!S || typeof w != "object" || w === null)
      return !1;
    try {
      return typeof S(w) == "number";
    } catch {
      return !1;
    }
  };
  function Me(J, w, N) {
    Fr(J, (U) => {
      U.call(t, w, N, Lr);
    });
  }
  const kl = function(w) {
    let N = null;
    if (Me(M.beforeSanitizeElements, w, null), Do(w))
      return le(w), !0;
    const U = Mt(w.nodeName);
    if (Me(M.uponSanitizeElement, w, {
      tagName: U,
      allowedTags: tt
    }), ii && w.hasChildNodes() && !ts(w.firstElementChild) && Rt(/<[/\w!]/g, w.innerHTML) && Rt(/<[/\w!]/g, w.textContent) || ii && w.namespaceURI === be && U === "style" && ts(w.firstElementChild) || w.nodeType === Er.progressingInstruction || ii && w.nodeType === Er.comment && Rt(/<[/\w]/g, w.data))
      return le(w), !0;
    if (xt[U] || !(kt.tagCheck instanceof Function && kt.tagCheck(U)) && !tt[U]) {
      if (!xt[U] && Tl(U) && (ot.tagNameCheck instanceof RegExp && Rt(ot.tagNameCheck, U) || ot.tagNameCheck instanceof Function && ot.tagNameCheck(U)))
        return !1;
      if (Lo && !xe[U]) {
        const dt = T(w) || w.parentNode, vt = k(w) || w.childNodes;
        if (vt && dt) {
          const Lt = vt.length;
          for (let Zt = Lt - 1; Zt >= 0; --Zt) {
            const Ge = y(vt[Zt], !0);
            dt.insertBefore(Ge, b(w));
          }
        }
      }
      return le(w), !0;
    }
    return w instanceof l && !Rm(w) || (U === "noscript" || U === "noembed" || U === "noframes") && Rt(/<\/no(script|embed|frames)/i, w.innerHTML) ? (le(w), !0) : (Ue && w.nodeType === Er.text && (N = w.textContent, Fr([F, L, E], (dt) => {
      N = Mr(N, dt, " ");
    }), w.textContent !== N && (Ar(t.removed, {
      element: w.cloneNode()
    }), w.textContent = N)), Me(M.afterSanitizeElements, w, null), !1);
  }, wl = function(w, N, U) {
    if (bt[N] || hl && (N === "id" || N === "name") && (U in r || U in Dm))
      return !1;
    const dt = X[N] || kt.attributeCheck instanceof Function && kt.attributeCheck(N, w);
    if (!(Ae && !bt[N] && Rt(D, N))) {
      if (!(ne && Rt(z, N))) {
        if (!dt || bt[N]) {
          if (
            // First condition does a very basic check if a) it's basically a valid custom element tagname AND
            // b) if the tagName passes whatever the user has configured for CUSTOM_ELEMENT_HANDLING.tagNameCheck
            // and c) if the attribute name passes whatever the user has configured for CUSTOM_ELEMENT_HANDLING.attributeNameCheck
            !(Tl(w) && (ot.tagNameCheck instanceof RegExp && Rt(ot.tagNameCheck, w) || ot.tagNameCheck instanceof Function && ot.tagNameCheck(w)) && (ot.attributeNameCheck instanceof RegExp && Rt(ot.attributeNameCheck, N) || ot.attributeNameCheck instanceof Function && ot.attributeNameCheck(N, w)) || // Alternative, second condition checks if it's an `is`-attribute, AND
            // the value passes whatever the user has configured for CUSTOM_ELEMENT_HANDLING.tagNameCheck
            N === "is" && ot.allowCustomizedBuiltInElements && (ot.tagNameCheck instanceof RegExp && Rt(ot.tagNameCheck, U) || ot.tagNameCheck instanceof Function && ot.tagNameCheck(U)))
          ) return !1;
        } else if (!Ao[N]) {
          if (!Rt(ut, Mr(U, lt, ""))) {
            if (!((N === "src" || N === "xlink:href" || N === "href") && w !== "script" && El(U, "data:") === 0 && ul[w])) {
              if (!(Sr && !Rt(Y, Mr(U, lt, "")))) {
                if (U)
                  return !1;
              }
            }
          }
        }
      }
    }
    return !0;
  }, Pm = nt({}, ["annotation-xml", "color-profile", "font-face", "font-face-format", "font-face-name", "font-face-src", "font-face-uri", "missing-glyph"]), Tl = function(w) {
    return !Pm[gi(w)] && Rt(pt, w);
  }, Sl = function(w) {
    Me(M.beforeSanitizeAttributes, w, null);
    const N = w.attributes;
    if (!N || Do(w))
      return;
    const U = {
      attrName: "",
      attrValue: "",
      keepAttr: !0,
      allowedAttributes: X,
      forceKeepAttr: void 0
    };
    let dt = N.length;
    for (; dt--; ) {
      const vt = N[dt], Lt = vt.name, Zt = vt.namespaceURI, Ge = vt.value, Ee = Mt(Lt), Po = Ge;
      let It = Lt === "value" ? Po : ly(Po);
      if (U.attrName = Ee, U.attrValue = It, U.keepAttr = !0, U.forceKeepAttr = void 0, Me(M.uponSanitizeAttribute, w, U), It = U.attrValue, cl && (Ee === "id" || Ee === "name") && El(It, dl) !== 0 && (or(Lt, w), It = dl + It), ii && Rt(/((--!?|])>)|<\/(style|script|title|xmp|textarea|noscript|iframe|noembed|noframes)/i, It)) {
        or(Lt, w);
        continue;
      }
      if (Ee === "attributename" && Ml(It, "href")) {
        or(Lt, w);
        continue;
      }
      if (U.forceKeepAttr)
        continue;
      if (!U.keepAttr) {
        or(Lt, w);
        continue;
      }
      if (!ll && Rt(/\/>/i, It)) {
        or(Lt, w);
        continue;
      }
      Ue && Fr([F, L, E], (Bl) => {
        It = Mr(It, Bl, " ");
      });
      const _l = Mt(w.nodeName);
      if (!wl(_l, Ee, It)) {
        or(Lt, w);
        continue;
      }
      if (_ && typeof g == "object" && typeof g.getAttributeType == "function" && !Zt)
        switch (g.getAttributeType(_l, Ee)) {
          case "TrustedHTML": {
            It = _.createHTML(It);
            break;
          }
          case "TrustedScriptURL": {
            It = _.createScriptURL(It);
            break;
          }
        }
      if (It !== Po)
        try {
          Zt ? w.setAttributeNS(Zt, Lt, It) : w.setAttribute(Lt, It), Do(w) ? le(w) : Al(t.removed);
        } catch {
          or(Lt, w);
        }
    }
    Me(M.afterSanitizeAttributes, w, null);
  }, Ro = function(w) {
    let N = null;
    const U = xl(w);
    for (Me(M.beforeSanitizeShadowDOM, w, null); N = U.nextNode(); )
      Me(M.uponSanitizeShadowNode, N, null), kl(N), Sl(N), N.content instanceof o && Ro(N.content);
    Me(M.afterSanitizeShadowDOM, w, null);
  }, es = function(w) {
    if (w.nodeType === Er.element && w.shadowRoot instanceof o) {
      const dt = w.shadowRoot;
      es(dt), Ro(dt);
    }
    const N = w.childNodes;
    if (!N)
      return;
    const U = [];
    Fr(N, (dt) => {
      Ar(U, dt);
    });
    for (const dt of U)
      es(dt);
  };
  return t.sanitize = function(J) {
    let w = arguments.length > 1 && arguments[1] !== void 0 ? arguments[1] : {}, N = null, U = null, dt = null, vt = null;
    if (Mo = !J, Mo && (J = "<!-->"), typeof J != "string" && !ts(J) && (J = fy(J), typeof J != "string"))
      throw rs("dirty is not a string, aborting");
    if (!t.isSupported)
      return J;
    if (Bo || Io(w), t.removed = [], typeof J == "string" && (si = !1), si) {
      const Ge = J.nodeName;
      if (typeof Ge == "string") {
        const Ee = Mt(Ge);
        if (!tt[Ee] || xt[Ee])
          throw rs("root node is forbidden and cannot be sanitized in-place");
      }
      es(J);
    } else if (ts(J))
      N = Cl("<!---->"), U = N.ownerDocument.importNode(J, !0), U.nodeType === Er.element && U.nodeName === "BODY" || U.nodeName === "HTML" ? N = U : N.appendChild(U), es(U);
    else {
      if (!_r && !Ue && !sr && // eslint-disable-next-line unicorn/prefer-includes
      J.indexOf("<") === -1)
        return _ && Ki ? _.createHTML(J) : J;
      if (N = Cl(J), !N)
        return _r ? null : Ki ? A : "";
    }
    N && vo && le(N.firstChild);
    const Lt = xl(si ? J : N);
    for (; dt = Lt.nextNode(); )
      kl(dt), Sl(dt), dt.content instanceof o && Ro(dt.content);
    if (si)
      return Ue && bl(J), J;
    if (_r) {
      if (Ue && bl(N), Zi)
        for (vt = R.call(N.ownerDocument); N.firstChild; )
          vt.appendChild(N.firstChild);
      else
        vt = N;
      return (X.shadowroot || X.shadowrootmode) && (vt = W.call(i, vt, !0)), vt;
    }
    let Zt = sr ? N.outerHTML : N.innerHTML;
    return sr && tt["!doctype"] && N.ownerDocument && N.ownerDocument.doctype && N.ownerDocument.doctype.name && Rt(Sy, N.ownerDocument.doctype.name) && (Zt = "<!DOCTYPE " + N.ownerDocument.doctype.name + `>
` + Zt), Ue && Fr([F, L, E], (Ge) => {
      Zt = Mr(Zt, Ge, " ");
    }), _ && Ki ? _.createHTML(Zt) : Zt;
  }, t.setConfig = function() {
    let J = arguments.length > 0 && arguments[0] !== void 0 ? arguments[0] : {};
    Io(J), Bo = !0;
  }, t.clearConfig = function() {
    Lr = null, Bo = !1;
  }, t.isValidAttribute = function(J, w, N) {
    Lr || Io({});
    const U = Mt(J), dt = Mt(w);
    return wl(U, dt, N);
  }, t.addHook = function(J, w) {
    typeof w == "function" && Ar(M[J], w);
  }, t.removeHook = function(J, w) {
    if (w !== void 0) {
      const N = ay(M[J], w);
      return N === -1 ? void 0 : ny(M[J], N, 1)[0];
    }
    return Al(M[J]);
  }, t.removeHooks = function(J) {
    M[J] = [];
  }, t.removeAllHooks = function() {
    M = ql();
  }, t;
}
var Ur = pc(), gc = /^-{3}\s*[\n\r](.*?)[\n\r]-{3}\s*[\n\r]+/s, Si = /%{2}{\s*(?:(\w+)\s*:|(\w+))\s*(?:(\w+)|((?:(?!}%{2}).|\r?\n)*))?\s*(?:}%{2})?/gi, Ly = /\s*%%.*\n/gm, mc = class extends Error {
  static {
    p(this, "UnknownDiagramError");
  }
  constructor(e) {
    super(e), this.name = "UnknownDiagramError";
  }
}, mr = {}, nn = /* @__PURE__ */ p(function(e, t) {
  e = e.replace(gc, "").replace(Si, "").replace(Ly, `
`);
  for (const [r, { detector: i }] of Object.entries(mr))
    if (i(e, t))
      return r;
  throw new mc(
    `No diagram type detected matching given configuration for text: ${e}`
  );
}, "detectType"), na = /* @__PURE__ */ p((...e) => {
  for (const { id: t, detector: r, loader: i } of e)
    yc(t, r, i);
}, "registerLazyLoadedDiagrams"), yc = /* @__PURE__ */ p((e, t, r) => {
  mr[e] && P.warn(`Detector with key ${e} already exists. Overwriting.`), mr[e] = { detector: t, loader: r }, P.debug(`Detector with key ${e} added${r ? " with loader" : ""}`);
}, "addDetector"), Fy = /* @__PURE__ */ p((e) => mr[e].loader, "getDiagramLoader"), la = /* @__PURE__ */ p((e, t, { depth: r = 2, clobber: i = !1 } = {}) => {
  const s = { depth: r, clobber: i };
  return Array.isArray(t) && !Array.isArray(e) ? (t.forEach((o) => la(e, o, s)), e) : Array.isArray(t) && Array.isArray(e) ? (t.forEach((o) => {
    e.includes(o) || e.push(o);
  }), e) : e === void 0 || r <= 0 ? e != null && typeof e == "object" && typeof t == "object" ? Object.assign(e, t) : t : (t !== void 0 && typeof e == "object" && typeof t == "object" && Object.keys(t).forEach((o) => {
    typeof t[o] == "object" && t[o] !== null && (e[o] === void 0 || typeof e[o] == "object") ? (e[o] === void 0 && (e[o] = Array.isArray(t[o]) ? [] : {}), e[o] = la(e[o], t[o], { depth: r - 1, clobber: i })) : (i || typeof e[o] != "object" && typeof t[o] != "object") && (e[o] = t[o]);
  }), e);
}, "assignWithDepth"), $t = la, ve = "#ffffff", Le = "#f2f2f2", st = /* @__PURE__ */ p((e, t) => t ? x(e, { s: -40, l: 10 }) : x(e, { s: -40, l: -10 }), "mkBorder"), Ay = class {
  static {
    p(this, "Theme");
  }
  constructor() {
    this.background = "#f4f4f4", this.primaryColor = "#fff4dd", this.noteBkgColor = "#fff5ad", this.noteTextColor = "#333", this.THEME_COLOR_LIMIT = 12, this.radius = 5, this.strokeWidth = 1, this.fontFamily = '"trebuchet ms", verdana, arial, sans-serif', this.fontSize = "16px", this.useGradient = !0, this.dropShadow = "drop-shadow( 1px 2px 2px rgba(185,185,185,1))";
  }
  updateColors() {
    if (this.primaryTextColor = this.primaryTextColor || (this.darkMode ? "#eee" : "#333"), this.secondaryColor = this.secondaryColor || x(this.primaryColor, { h: -120 }), this.tertiaryColor = this.tertiaryColor || x(this.primaryColor, { h: 180, l: 5 }), this.primaryBorderColor = this.primaryBorderColor || st(this.primaryColor, this.darkMode), this.secondaryBorderColor = this.secondaryBorderColor || st(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = this.tertiaryBorderColor || st(this.tertiaryColor, this.darkMode), this.noteBorderColor = this.noteBorderColor || st(this.noteBkgColor, this.darkMode), this.noteBkgColor = this.noteBkgColor || "#fff5ad", this.noteTextColor = this.noteTextColor || "#333", this.secondaryTextColor = this.secondaryTextColor || B(this.secondaryColor), this.tertiaryTextColor = this.tertiaryTextColor || B(this.tertiaryColor), this.lineColor = this.lineColor || B(this.background), this.arrowheadColor = this.arrowheadColor || B(this.background), this.textColor = this.textColor || this.primaryTextColor, this.border2 = this.border2 || this.tertiaryBorderColor, this.nodeBkg = this.nodeBkg || this.primaryColor, this.mainBkg = this.mainBkg || this.primaryColor, this.nodeBorder = this.nodeBorder || this.primaryBorderColor, this.clusterBkg = this.clusterBkg || this.tertiaryColor, this.clusterBorder = this.clusterBorder || this.tertiaryBorderColor, this.defaultLinkColor = this.defaultLinkColor || this.lineColor, this.titleColor = this.titleColor || this.tertiaryTextColor, this.edgeLabelBackground = this.edgeLabelBackground || (this.darkMode ? O(this.secondaryColor, 30) : this.secondaryColor), this.nodeTextColor = this.nodeTextColor || this.primaryTextColor, this.actorBorder = this.actorBorder || this.primaryBorderColor, this.actorBkg = this.actorBkg || this.mainBkg, this.actorTextColor = this.actorTextColor || this.primaryTextColor, this.actorLineColor = this.actorLineColor || this.actorBorder, this.labelBoxBkgColor = this.labelBoxBkgColor || this.actorBkg, this.signalColor = this.signalColor || this.textColor, this.signalTextColor = this.signalTextColor || this.textColor, this.labelBoxBorderColor = this.labelBoxBorderColor || this.actorBorder, this.labelTextColor = this.labelTextColor || this.actorTextColor, this.loopTextColor = this.loopTextColor || this.actorTextColor, this.activationBorderColor = this.activationBorderColor || O(this.secondaryColor, 10), this.activationBkgColor = this.activationBkgColor || this.secondaryColor, this.sequenceNumberColor = this.sequenceNumberColor || B(this.lineColor), this.sectionBkgColor = this.sectionBkgColor || this.tertiaryColor, this.altSectionBkgColor = this.altSectionBkgColor || "white", this.sectionBkgColor = this.sectionBkgColor || this.secondaryColor, this.sectionBkgColor2 = this.sectionBkgColor2 || this.primaryColor, this.excludeBkgColor = this.excludeBkgColor || "#eeeeee", this.taskBorderColor = this.taskBorderColor || this.primaryBorderColor, this.taskBkgColor = this.taskBkgColor || this.primaryColor, this.activeTaskBorderColor = this.activeTaskBorderColor || this.primaryColor, this.activeTaskBkgColor = this.activeTaskBkgColor || $(this.primaryColor, 23), this.gridColor = this.gridColor || "lightgrey", this.doneTaskBkgColor = this.doneTaskBkgColor || "lightgrey", this.doneTaskBorderColor = this.doneTaskBorderColor || "grey", this.critBorderColor = this.critBorderColor || "#ff8888", this.critBkgColor = this.critBkgColor || "red", this.todayLineColor = this.todayLineColor || "red", this.vertLineColor = this.vertLineColor || "navy", this.taskTextColor = this.taskTextColor || this.textColor, this.taskTextOutsideColor = this.taskTextOutsideColor || this.textColor, this.taskTextLightColor = this.taskTextLightColor || this.textColor, this.taskTextColor = this.taskTextColor || this.primaryTextColor, this.taskTextDarkColor = this.taskTextDarkColor || this.textColor, this.taskTextClickableColor = this.taskTextClickableColor || "#003163", this.noteFontWeight = this.noteFontWeight || "normal", this.fontWeight = this.fontWeight || "normal", this.personBorder = this.personBorder || this.primaryBorderColor, this.personBkg = this.personBkg || this.mainBkg, this.darkMode ? (this.rowOdd = this.rowOdd || O(this.mainBkg, 5) || "#ffffff", this.rowEven = this.rowEven || O(this.mainBkg, 10)) : (this.rowOdd = this.rowOdd || $(this.mainBkg, 75) || "#ffffff", this.rowEven = this.rowEven || $(this.mainBkg, 5)), this.transitionColor = this.transitionColor || this.lineColor, this.transitionLabelColor = this.transitionLabelColor || this.textColor, this.stateLabelColor = this.stateLabelColor || this.stateBkg || this.primaryTextColor, this.stateBkg = this.stateBkg || this.mainBkg, this.labelBackgroundColor = this.labelBackgroundColor || this.stateBkg, this.compositeBackground = this.compositeBackground || this.background || this.tertiaryColor, this.altBackground = this.altBackground || this.tertiaryColor, this.compositeTitleBackground = this.compositeTitleBackground || this.mainBkg, this.compositeBorder = this.compositeBorder || this.nodeBorder, this.innerEndBackground = this.nodeBorder, this.errorBkgColor = this.errorBkgColor || this.tertiaryColor, this.errorTextColor = this.errorTextColor || this.tertiaryTextColor, this.transitionColor = this.transitionColor || this.lineColor, this.specialStateColor = this.lineColor, this.cScale0 = this.cScale0 || this.primaryColor, this.cScale1 = this.cScale1 || this.secondaryColor, this.cScale2 = this.cScale2 || this.tertiaryColor, this.cScale3 = this.cScale3 || x(this.primaryColor, { h: 30 }), this.cScale4 = this.cScale4 || x(this.primaryColor, { h: 60 }), this.cScale5 = this.cScale5 || x(this.primaryColor, { h: 90 }), this.cScale6 = this.cScale6 || x(this.primaryColor, { h: 120 }), this.cScale7 = this.cScale7 || x(this.primaryColor, { h: 150 }), this.cScale8 = this.cScale8 || x(this.primaryColor, { h: 210, l: 150 }), this.cScale9 = this.cScale9 || x(this.primaryColor, { h: 270 }), this.cScale10 = this.cScale10 || x(this.primaryColor, { h: 300 }), this.cScale11 = this.cScale11 || x(this.primaryColor, { h: 330 }), this.darkMode)
      for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
        this["cScale" + t] = O(this["cScale" + t], 75);
    else
      for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
        this["cScale" + t] = O(this["cScale" + t], 25);
    for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
      this["cScaleInv" + t] = this["cScaleInv" + t] || B(this["cScale" + t]);
    for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
      this.darkMode ? this["cScalePeer" + t] = this["cScalePeer" + t] || $(this["cScale" + t], 10) : this["cScalePeer" + t] = this["cScalePeer" + t] || O(this["cScale" + t], 10);
    this.scaleLabelColor = this.scaleLabelColor || this.labelTextColor;
    for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
      this["cScaleLabel" + t] = this["cScaleLabel" + t] || this.scaleLabelColor;
    const e = this.darkMode ? -4 : -1;
    for (let t = 0; t < 5; t++)
      this["surface" + t] = this["surface" + t] || x(this.mainBkg, { h: 180, s: -15, l: e * (5 + t * 3) }), this["surfacePeer" + t] = this["surfacePeer" + t] || x(this.mainBkg, { h: 180, s: -15, l: e * (8 + t * 3) });
    this.classText = this.classText || this.textColor, this.fillType0 = this.fillType0 || this.primaryColor, this.fillType1 = this.fillType1 || this.secondaryColor, this.fillType2 = this.fillType2 || x(this.primaryColor, { h: 64 }), this.fillType3 = this.fillType3 || x(this.secondaryColor, { h: 64 }), this.fillType4 = this.fillType4 || x(this.primaryColor, { h: -64 }), this.fillType5 = this.fillType5 || x(this.secondaryColor, { h: -64 }), this.fillType6 = this.fillType6 || x(this.primaryColor, { h: 128 }), this.fillType7 = this.fillType7 || x(this.secondaryColor, { h: 128 }), this.pie1 = this.pie1 || this.primaryColor, this.pie2 = this.pie2 || this.secondaryColor, this.pie3 = this.pie3 || this.tertiaryColor, this.pie4 = this.pie4 || x(this.primaryColor, { l: -10 }), this.pie5 = this.pie5 || x(this.secondaryColor, { l: -10 }), this.pie6 = this.pie6 || x(this.tertiaryColor, { l: -10 }), this.pie7 = this.pie7 || x(this.primaryColor, { h: 60, l: -10 }), this.pie8 = this.pie8 || x(this.primaryColor, { h: -60, l: -10 }), this.pie9 = this.pie9 || x(this.primaryColor, { h: 120, l: 0 }), this.pie10 = this.pie10 || x(this.primaryColor, { h: 60, l: -20 }), this.pie11 = this.pie11 || x(this.primaryColor, { h: -60, l: -20 }), this.pie12 = this.pie12 || x(this.primaryColor, { h: 120, l: -10 }), this.pieTitleTextSize = this.pieTitleTextSize || "25px", this.pieTitleTextColor = this.pieTitleTextColor || this.taskTextDarkColor, this.pieSectionTextSize = this.pieSectionTextSize || "17px", this.pieSectionTextColor = this.pieSectionTextColor || this.textColor, this.pieLegendTextSize = this.pieLegendTextSize || "17px", this.pieLegendTextColor = this.pieLegendTextColor || this.taskTextDarkColor, this.pieStrokeColor = this.pieStrokeColor || "black", this.pieStrokeWidth = this.pieStrokeWidth || "2px", this.pieOuterStrokeWidth = this.pieOuterStrokeWidth || "2px", this.pieOuterStrokeColor = this.pieOuterStrokeColor || "black", this.pieOpacity = this.pieOpacity || "0.7", this.venn1 = this.venn1 ?? x(this.primaryColor, { l: -30 }), this.venn2 = this.venn2 ?? x(this.secondaryColor, { l: -30 }), this.venn3 = this.venn3 ?? x(this.tertiaryColor, { l: -30 }), this.venn4 = this.venn4 ?? x(this.primaryColor, { h: 60, l: -30 }), this.venn5 = this.venn5 ?? x(this.primaryColor, { h: -60, l: -30 }), this.venn6 = this.venn6 ?? x(this.secondaryColor, { h: 60, l: -30 }), this.venn7 = this.venn7 ?? x(this.primaryColor, { h: 120, l: -30 }), this.venn8 = this.venn8 ?? x(this.secondaryColor, { h: 120, l: -30 }), this.vennTitleTextColor = this.vennTitleTextColor ?? this.titleColor, this.vennSetTextColor = this.vennSetTextColor ?? this.textColor, this.radar = {
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
    }, this.wardleyEvolutionColor = this.wardleyEvolutionColor || "#dc3545", this.wardley = {
      backgroundColor: this.wardley?.backgroundColor || this.background,
      axisColor: this.wardley?.axisColor || this.lineColor,
      axisTextColor: this.wardley?.axisTextColor || this.primaryTextColor,
      gridColor: this.wardley?.gridColor || this.gridColor,
      componentFill: this.wardley?.componentFill || this.background,
      componentStroke: this.wardley?.componentStroke || this.lineColor,
      componentLabelColor: this.wardley?.componentLabelColor || this.primaryTextColor,
      linkStroke: this.wardley?.linkStroke || this.lineColor,
      evolutionStroke: this.wardley?.evolutionStroke || this.wardleyEvolutionColor,
      annotationStroke: this.wardley?.annotationStroke || this.lineColor,
      annotationTextColor: this.wardley?.annotationTextColor || this.primaryTextColor,
      annotationFill: this.wardley?.annotationFill || this.background
    }, this.archEdgeColor = this.archEdgeColor || "#777", this.archEdgeArrowColor = this.archEdgeArrowColor || "#777", this.archEdgeWidth = this.archEdgeWidth || "3", this.archGroupBorderColor = this.archGroupBorderColor || "#000", this.archGroupBorderWidth = this.archGroupBorderWidth || "2px", this.quadrant1Fill = this.quadrant1Fill || this.primaryColor, this.quadrant2Fill = this.quadrant2Fill || x(this.primaryColor, { r: 5, g: 5, b: 5 }), this.quadrant3Fill = this.quadrant3Fill || x(this.primaryColor, { r: 10, g: 10, b: 10 }), this.quadrant4Fill = this.quadrant4Fill || x(this.primaryColor, { r: 15, g: 15, b: 15 }), this.quadrant1TextFill = this.quadrant1TextFill || this.primaryTextColor, this.quadrant2TextFill = this.quadrant2TextFill || x(this.primaryTextColor, { r: -5, g: -5, b: -5 }), this.quadrant3TextFill = this.quadrant3TextFill || x(this.primaryTextColor, { r: -10, g: -10, b: -10 }), this.quadrant4TextFill = this.quadrant4TextFill || x(this.primaryTextColor, { r: -15, g: -15, b: -15 }), this.quadrantPointFill = this.quadrantPointFill || ye(this.quadrant1Fill) ? $(this.quadrant1Fill) : O(this.quadrant1Fill), this.quadrantPointTextFill = this.quadrantPointTextFill || this.primaryTextColor, this.quadrantXAxisTextFill = this.quadrantXAxisTextFill || this.primaryTextColor, this.quadrantYAxisTextFill = this.quadrantYAxisTextFill || this.primaryTextColor, this.quadrantInternalBorderStrokeFill = this.quadrantInternalBorderStrokeFill || this.primaryBorderColor, this.quadrantExternalBorderStrokeFill = this.quadrantExternalBorderStrokeFill || this.primaryBorderColor, this.quadrantTitleFill = this.quadrantTitleFill || this.primaryTextColor, this.xyChart = {
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
    }, this.requirementBackground = this.requirementBackground || this.primaryColor, this.requirementBorderColor = this.requirementBorderColor || this.primaryBorderColor, this.requirementBorderSize = this.requirementBorderSize || "1", this.requirementTextColor = this.requirementTextColor || this.primaryTextColor, this.relationColor = this.relationColor || this.lineColor, this.relationLabelBackground = this.relationLabelBackground || (this.darkMode ? O(this.secondaryColor, 30) : this.secondaryColor), this.relationLabelColor = this.relationLabelColor || this.actorTextColor, this.git0 = this.git0 || this.primaryColor, this.git1 = this.git1 || this.secondaryColor, this.git2 = this.git2 || this.tertiaryColor, this.git3 = this.git3 || x(this.primaryColor, { h: -30 }), this.git4 = this.git4 || x(this.primaryColor, { h: -60 }), this.git5 = this.git5 || x(this.primaryColor, { h: -90 }), this.git6 = this.git6 || x(this.primaryColor, { h: 60 }), this.git7 = this.git7 || x(this.primaryColor, { h: 120 }), this.darkMode ? (this.git0 = $(this.git0, 25), this.git1 = $(this.git1, 25), this.git2 = $(this.git2, 25), this.git3 = $(this.git3, 25), this.git4 = $(this.git4, 25), this.git5 = $(this.git5, 25), this.git6 = $(this.git6, 25), this.git7 = $(this.git7, 25)) : (this.git0 = O(this.git0, 25), this.git1 = O(this.git1, 25), this.git2 = O(this.git2, 25), this.git3 = O(this.git3, 25), this.git4 = O(this.git4, 25), this.git5 = O(this.git5, 25), this.git6 = O(this.git6, 25), this.git7 = O(this.git7, 25)), this.gitInv0 = this.gitInv0 || B(this.git0), this.gitInv1 = this.gitInv1 || B(this.git1), this.gitInv2 = this.gitInv2 || B(this.git2), this.gitInv3 = this.gitInv3 || B(this.git3), this.gitInv4 = this.gitInv4 || B(this.git4), this.gitInv5 = this.gitInv5 || B(this.git5), this.gitInv6 = this.gitInv6 || B(this.git6), this.gitInv7 = this.gitInv7 || B(this.git7), this.branchLabelColor = this.branchLabelColor || (this.darkMode ? "black" : this.labelTextColor), this.gitBranchLabel0 = this.gitBranchLabel0 || this.branchLabelColor, this.gitBranchLabel1 = this.gitBranchLabel1 || this.branchLabelColor, this.gitBranchLabel2 = this.gitBranchLabel2 || this.branchLabelColor, this.gitBranchLabel3 = this.gitBranchLabel3 || this.branchLabelColor, this.gitBranchLabel4 = this.gitBranchLabel4 || this.branchLabelColor, this.gitBranchLabel5 = this.gitBranchLabel5 || this.branchLabelColor, this.gitBranchLabel6 = this.gitBranchLabel6 || this.branchLabelColor, this.gitBranchLabel7 = this.gitBranchLabel7 || this.branchLabelColor, this.tagLabelColor = this.tagLabelColor || this.primaryTextColor, this.tagLabelBackground = this.tagLabelBackground || this.primaryColor, this.tagLabelBorder = this.tagBorder || this.primaryBorderColor, this.tagLabelFontSize = this.tagLabelFontSize || "10px", this.commitLabelColor = this.commitLabelColor || this.secondaryTextColor, this.commitLabelBackground = this.commitLabelBackground || this.secondaryColor, this.commitLabelFontSize = this.commitLabelFontSize || "10px", this.emUiFill = this.emUiFill || "white", this.emUiStroke = this.emUiStroke || "#dbdada", this.emProcessorFill = this.emProcessorFill || "#edb3f6", this.emProcessorStroke = this.emProcessorStroke || "#b88cbf", this.emReadModelFill = this.emReadModelFill || "#d3f1a2", this.emReadModelStroke = this.emReadModelStroke || "#a3b732", this.emCommandFill = this.emCommandFill || "#bcd6fe", this.emCommandStroke = this.emCommandStroke || "#679ac3", this.emEventFill = this.emEventFill || "#ffb778", this.emEventStroke = this.emEventStroke || "#c19a0f", this.emSwimlaneBackgroundOdd = this.emSwimlaneBackgroundOdd || "rgb(250,250,250)", this.emSwimlaneBackgroundStroke = this.emSwimlaneBackgroundStroke || "rgb(240,240,240)", this.emArrowhead = this.emArrowhead || this.lineColor, this.emRelationStroke = this.emRelationStroke || this.lineColor, this.attributeBackgroundColorOdd = this.attributeBackgroundColorOdd || ve, this.attributeBackgroundColorEven = this.attributeBackgroundColorEven || Le, this.gradientStart = this.primaryBorderColor, this.gradientStop = this.secondaryBorderColor;
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
}, My = /* @__PURE__ */ p((e) => {
  const t = new Ay();
  return t.calculate(e), t;
}, "getThemeVariables"), Ey = class {
  static {
    p(this, "Theme");
  }
  constructor() {
    this.background = "#333", this.primaryColor = "#1f2020", this.secondaryColor = $(this.primaryColor, 16), this.tertiaryColor = x(this.primaryColor, { h: -160 }), this.primaryBorderColor = B(this.background), this.secondaryBorderColor = st(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = st(this.tertiaryColor, this.darkMode), this.primaryTextColor = B(this.primaryColor), this.secondaryTextColor = B(this.secondaryColor), this.tertiaryTextColor = B(this.tertiaryColor), this.lineColor = B(this.background), this.textColor = B(this.background), this.mainBkg = "#1f2020", this.secondBkg = "calculated", this.mainContrastColor = "lightgrey", this.darkTextColor = $(B("#323D47"), 10), this.lineColor = "calculated", this.border1 = "#ccc", this.border2 = Ke(255, 255, 255, 0.25), this.arrowheadColor = "calculated", this.fontFamily = '"trebuchet ms", verdana, arial, sans-serif', this.fontSize = "16px", this.labelBackground = "#181818", this.textColor = "#ccc", this.THEME_COLOR_LIMIT = 12, this.radius = 5, this.strokeWidth = 1, this.nodeBkg = "calculated", this.nodeBorder = "calculated", this.clusterBkg = "calculated", this.clusterBorder = "calculated", this.defaultLinkColor = "calculated", this.titleColor = "#F9FFFE", this.edgeLabelBackground = "calculated", this.actorBorder = "calculated", this.actorBkg = "calculated", this.actorTextColor = "calculated", this.actorLineColor = "calculated", this.signalColor = "calculated", this.signalTextColor = "calculated", this.labelBoxBkgColor = "calculated", this.labelBoxBorderColor = "calculated", this.labelTextColor = "calculated", this.loopTextColor = "calculated", this.noteBorderColor = "calculated", this.noteBkgColor = "#fff5ad", this.noteTextColor = "calculated", this.activationBorderColor = "calculated", this.activationBkgColor = "calculated", this.sequenceNumberColor = "black", this.clusterBkg = "#302F3D", this.sectionBkgColor = O("#EAE8D9", 30), this.altSectionBkgColor = "calculated", this.sectionBkgColor2 = "#EAE8D9", this.excludeBkgColor = O(this.sectionBkgColor, 10), this.taskBorderColor = Ke(255, 255, 255, 70), this.taskBkgColor = "calculated", this.taskTextColor = "calculated", this.taskTextLightColor = "calculated", this.taskTextOutsideColor = "calculated", this.taskTextClickableColor = "#003163", this.activeTaskBorderColor = Ke(255, 255, 255, 50), this.activeTaskBkgColor = "#81B1DB", this.gridColor = "calculated", this.doneTaskBkgColor = "calculated", this.doneTaskBorderColor = "grey", this.critBorderColor = "#E83737", this.critBkgColor = "#E83737", this.taskTextDarkColor = "calculated", this.todayLineColor = "#DB5757", this.vertLineColor = "#00BFFF", this.personBorder = this.primaryBorderColor, this.personBkg = this.mainBkg, this.archEdgeColor = "calculated", this.archEdgeArrowColor = "calculated", this.archEdgeWidth = "3", this.archGroupBorderColor = this.primaryBorderColor, this.archGroupBorderWidth = "2px", this.rowOdd = this.rowOdd || $(this.mainBkg, 5) || "#ffffff", this.rowEven = this.rowEven || O(this.mainBkg, 10), this.labelColor = "calculated", this.errorBkgColor = "#a44141", this.errorTextColor = "#ddd", this.useGradient = !0, this.gradientStart = this.primaryBorderColor, this.gradientStop = this.secondaryBorderColor, this.dropShadow = "drop-shadow( 1px 2px 2px rgba(185,185,185,1))", this.noteFontWeight = this.noteFontWeight || "normal", this.fontWeight = this.fontWeight || "normal";
  }
  updateColors() {
    this.secondBkg = $(this.mainBkg, 16), this.lineColor = this.mainContrastColor, this.arrowheadColor = this.mainContrastColor, this.nodeBkg = this.mainBkg, this.nodeBorder = this.border1, this.clusterBkg = this.secondBkg, this.clusterBorder = this.border2, this.defaultLinkColor = this.lineColor, this.edgeLabelBackground = $(this.labelBackground, 25), this.actorBorder = this.border1, this.actorBkg = this.mainBkg, this.actorTextColor = this.mainContrastColor, this.actorLineColor = this.actorBorder, this.signalColor = this.mainContrastColor, this.signalTextColor = this.mainContrastColor, this.labelBoxBkgColor = this.actorBkg, this.labelBoxBorderColor = this.actorBorder, this.labelTextColor = this.mainContrastColor, this.loopTextColor = this.mainContrastColor, this.noteBorderColor = this.secondaryBorderColor, this.noteBkgColor = this.secondBkg, this.noteTextColor = this.secondaryTextColor, this.activationBorderColor = this.border1, this.activationBkgColor = this.secondBkg, this.altSectionBkgColor = this.background, this.taskBkgColor = $(this.mainBkg, 23), this.taskTextColor = this.darkTextColor, this.taskTextLightColor = this.mainContrastColor, this.taskTextOutsideColor = this.taskTextLightColor, this.gridColor = this.mainContrastColor, this.doneTaskBkgColor = this.mainContrastColor, this.taskTextDarkColor = B(this.doneTaskBkgColor), this.archEdgeColor = this.lineColor, this.archEdgeArrowColor = this.lineColor, this.transitionColor = this.transitionColor || this.lineColor, this.transitionLabelColor = this.transitionLabelColor || this.textColor, this.stateLabelColor = this.stateLabelColor || this.stateBkg || this.primaryTextColor, this.stateBkg = this.stateBkg || this.mainBkg, this.labelBackgroundColor = this.labelBackgroundColor || this.stateBkg, this.compositeBackground = this.compositeBackground || this.background || this.tertiaryColor, this.altBackground = this.altBackground || "#555", this.compositeTitleBackground = this.compositeTitleBackground || this.mainBkg, this.compositeBorder = this.compositeBorder || this.nodeBorder, this.innerEndBackground = this.primaryBorderColor, this.specialStateColor = "#f4f4f4", this.errorBkgColor = this.errorBkgColor || this.tertiaryColor, this.errorTextColor = this.errorTextColor || this.tertiaryTextColor, this.fillType0 = this.primaryColor, this.fillType1 = this.secondaryColor, this.fillType2 = x(this.primaryColor, { h: 64 }), this.fillType3 = x(this.secondaryColor, { h: 64 }), this.fillType4 = x(this.primaryColor, { h: -64 }), this.fillType5 = x(this.secondaryColor, { h: -64 }), this.fillType6 = x(this.primaryColor, { h: 128 }), this.fillType7 = x(this.secondaryColor, { h: 128 }), this.cScale1 = this.cScale1 || "#0b0000", this.cScale2 = this.cScale2 || "#4d1037", this.cScale3 = this.cScale3 || "#3f5258", this.cScale4 = this.cScale4 || "#4f2f1b", this.cScale5 = this.cScale5 || "#6e0a0a", this.cScale6 = this.cScale6 || "#3b0048", this.cScale7 = this.cScale7 || "#995a01", this.cScale8 = this.cScale8 || "#154706", this.cScale9 = this.cScale9 || "#161722", this.cScale10 = this.cScale10 || "#00296f", this.cScale11 = this.cScale11 || "#01629c", this.cScale12 = this.cScale12 || "#010029", this.cScale0 = this.cScale0 || this.primaryColor, this.cScale1 = this.cScale1 || this.secondaryColor, this.cScale2 = this.cScale2 || this.tertiaryColor, this.cScale3 = this.cScale3 || x(this.primaryColor, { h: 30 }), this.cScale4 = this.cScale4 || x(this.primaryColor, { h: 60 }), this.cScale5 = this.cScale5 || x(this.primaryColor, { h: 90 }), this.cScale6 = this.cScale6 || x(this.primaryColor, { h: 120 }), this.cScale7 = this.cScale7 || x(this.primaryColor, { h: 150 }), this.cScale8 = this.cScale8 || x(this.primaryColor, { h: 210 }), this.cScale9 = this.cScale9 || x(this.primaryColor, { h: 270 }), this.cScale10 = this.cScale10 || x(this.primaryColor, { h: 300 }), this.cScale11 = this.cScale11 || x(this.primaryColor, { h: 330 });
    for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
      this["cScaleInv" + e] = this["cScaleInv" + e] || B(this["cScale" + e]);
    for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
      this["cScalePeer" + e] = this["cScalePeer" + e] || $(this["cScale" + e], 10);
    for (let e = 0; e < 5; e++)
      this["surface" + e] = this["surface" + e] || x(this.mainBkg, { h: 30, s: -30, l: -(-10 + e * 4) }), this["surfacePeer" + e] = this["surfacePeer" + e] || x(this.mainBkg, { h: 30, s: -30, l: -(-7 + e * 4) });
    this.scaleLabelColor = this.scaleLabelColor || (this.darkMode ? "black" : this.labelTextColor);
    for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
      this["cScaleLabel" + e] = this["cScaleLabel" + e] || this.scaleLabelColor;
    for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
      this["pie" + e] = this["cScale" + e];
    this.pieTitleTextSize = this.pieTitleTextSize || "25px", this.pieTitleTextColor = this.pieTitleTextColor || this.mainContrastColor, this.pieSectionTextSize = this.pieSectionTextSize || "17px", this.pieSectionTextColor = this.pieSectionTextColor || this.textColor, this.pieLegendTextSize = this.pieLegendTextSize || "17px", this.pieLegendTextColor = this.pieLegendTextColor || this.mainContrastColor, this.pieStrokeColor = this.pieStrokeColor || "black", this.pieStrokeWidth = this.pieStrokeWidth || "2px", this.pieOuterStrokeWidth = this.pieOuterStrokeWidth || "2px", this.pieOuterStrokeColor = this.pieOuterStrokeColor || "black", this.pieOpacity = this.pieOpacity || "0.7";
    for (let e = 0; e < 8; e++)
      this["venn" + (e + 1)] = this["venn" + (e + 1)] ?? $(this["cScale" + e], 30);
    this.vennTitleTextColor = this.vennTitleTextColor ?? this.titleColor, this.vennSetTextColor = this.vennSetTextColor ?? this.textColor, this.quadrant1Fill = this.quadrant1Fill || this.primaryColor, this.quadrant2Fill = this.quadrant2Fill || x(this.primaryColor, { r: 5, g: 5, b: 5 }), this.quadrant3Fill = this.quadrant3Fill || x(this.primaryColor, { r: 10, g: 10, b: 10 }), this.quadrant4Fill = this.quadrant4Fill || x(this.primaryColor, { r: 15, g: 15, b: 15 }), this.quadrant1TextFill = this.quadrant1TextFill || this.primaryTextColor, this.quadrant2TextFill = this.quadrant2TextFill || x(this.primaryTextColor, { r: -5, g: -5, b: -5 }), this.quadrant3TextFill = this.quadrant3TextFill || x(this.primaryTextColor, { r: -10, g: -10, b: -10 }), this.quadrant4TextFill = this.quadrant4TextFill || x(this.primaryTextColor, { r: -15, g: -15, b: -15 }), this.quadrantPointFill = this.quadrantPointFill || ye(this.quadrant1Fill) ? $(this.quadrant1Fill) : O(this.quadrant1Fill), this.quadrantPointTextFill = this.quadrantPointTextFill || this.primaryTextColor, this.quadrantXAxisTextFill = this.quadrantXAxisTextFill || this.primaryTextColor, this.quadrantYAxisTextFill = this.quadrantYAxisTextFill || this.primaryTextColor, this.quadrantInternalBorderStrokeFill = this.quadrantInternalBorderStrokeFill || this.primaryBorderColor, this.quadrantExternalBorderStrokeFill = this.quadrantExternalBorderStrokeFill || this.primaryBorderColor, this.quadrantTitleFill = this.quadrantTitleFill || this.primaryTextColor, this.xyChart = {
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
    }, this.wardleyEvolutionColor = this.wardleyEvolutionColor || "#ff6b6b", this.wardley = {
      backgroundColor: this.wardley?.backgroundColor || this.background,
      axisColor: this.wardley?.axisColor || this.lineColor,
      axisTextColor: this.wardley?.axisTextColor || this.primaryTextColor,
      gridColor: this.wardley?.gridColor || this.gridColor,
      componentFill: this.wardley?.componentFill || this.mainBkg,
      componentStroke: this.wardley?.componentStroke || this.lineColor,
      componentLabelColor: this.wardley?.componentLabelColor || this.primaryTextColor,
      linkStroke: this.wardley?.linkStroke || this.lineColor,
      evolutionStroke: this.wardley?.evolutionStroke || this.wardleyEvolutionColor,
      annotationStroke: this.wardley?.annotationStroke || this.lineColor,
      annotationTextColor: this.wardley?.annotationTextColor || this.primaryTextColor,
      annotationFill: this.wardley?.annotationFill || this.mainBkg
    }, this.classText = this.primaryTextColor, this.requirementBackground = this.requirementBackground || this.primaryColor, this.requirementBorderColor = this.requirementBorderColor || this.primaryBorderColor, this.requirementBorderSize = this.requirementBorderSize || "1", this.requirementTextColor = this.requirementTextColor || this.primaryTextColor, this.relationColor = this.relationColor || this.lineColor, this.relationLabelBackground = this.relationLabelBackground || (this.darkMode ? O(this.secondaryColor, 30) : this.secondaryColor), this.relationLabelColor = this.relationLabelColor || this.actorTextColor, this.git0 = $(this.secondaryColor, 20), this.git1 = $(this.pie2 || this.secondaryColor, 20), this.git2 = $(this.pie3 || this.tertiaryColor, 20), this.git3 = $(this.pie4 || x(this.primaryColor, { h: -30 }), 20), this.git4 = $(this.pie5 || x(this.primaryColor, { h: -60 }), 20), this.git5 = $(this.pie6 || x(this.primaryColor, { h: -90 }), 10), this.git6 = $(this.pie7 || x(this.primaryColor, { h: 60 }), 10), this.git7 = $(this.pie8 || x(this.primaryColor, { h: 120 }), 20), this.gitInv0 = this.gitInv0 || B(this.git0), this.gitInv1 = this.gitInv1 || B(this.git1), this.gitInv2 = this.gitInv2 || B(this.git2), this.gitInv3 = this.gitInv3 || B(this.git3), this.gitInv4 = this.gitInv4 || B(this.git4), this.gitInv5 = this.gitInv5 || B(this.git5), this.gitInv6 = this.gitInv6 || B(this.git6), this.gitInv7 = this.gitInv7 || B(this.git7), this.gitBranchLabel0 = this.gitBranchLabel0 || B(this.labelTextColor), this.gitBranchLabel1 = this.gitBranchLabel1 || this.labelTextColor, this.gitBranchLabel2 = this.gitBranchLabel2 || this.labelTextColor, this.gitBranchLabel3 = this.gitBranchLabel3 || B(this.labelTextColor), this.gitBranchLabel4 = this.gitBranchLabel4 || this.labelTextColor, this.gitBranchLabel5 = this.gitBranchLabel5 || this.labelTextColor, this.gitBranchLabel6 = this.gitBranchLabel6 || this.labelTextColor, this.gitBranchLabel7 = this.gitBranchLabel7 || this.labelTextColor, this.tagLabelColor = this.tagLabelColor || this.primaryTextColor, this.tagLabelBackground = this.tagLabelBackground || this.primaryColor, this.tagLabelBorder = this.tagBorder || this.primaryBorderColor, this.tagLabelFontSize = this.tagLabelFontSize || "10px", this.commitLabelColor = this.commitLabelColor || this.secondaryTextColor, this.commitLabelBackground = this.commitLabelBackground || this.secondaryColor, this.commitLabelFontSize = this.commitLabelFontSize || "10px", this.emUiFill = this.emUiFill || "#2d2d2d", this.emUiStroke = this.emUiStroke || "#555", this.emProcessorFill = this.emProcessorFill || $("#5a3d5c", 10), this.emProcessorStroke = this.emProcessorStroke || "#8a6d8c", this.emReadModelFill = this.emReadModelFill || $("#3d5a2d", 10), this.emReadModelStroke = this.emReadModelStroke || "#6d8c5c", this.emCommandFill = this.emCommandFill || $("#2d3d5a", 10), this.emCommandStroke = this.emCommandStroke || "#5c6d8c", this.emEventFill = this.emEventFill || $("#5a452d", 10), this.emEventStroke = this.emEventStroke || "#8c755c", this.emSwimlaneBackgroundOdd = this.emSwimlaneBackgroundOdd || $(this.background, 5), this.emSwimlaneBackgroundStroke = this.emSwimlaneBackgroundStroke || $(this.background, 12), this.emArrowhead = this.emArrowhead || this.lineColor, this.emRelationStroke = this.emRelationStroke || this.lineColor, this.attributeBackgroundColorOdd = this.attributeBackgroundColorOdd || $(this.background, 12), this.attributeBackgroundColorEven = this.attributeBackgroundColorEven || $(this.background, 2), this.nodeBorder = this.nodeBorder || "#999";
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
}, $y = /* @__PURE__ */ p((e) => {
  const t = new Ey();
  return t.calculate(e), t;
}, "getThemeVariables"), Oy = class {
  static {
    p(this, "Theme");
  }
  constructor() {
    this.background = "#f4f4f4", this.primaryColor = "#ECECFF", this.secondaryColor = x(this.primaryColor, { h: 120 }), this.secondaryColor = "#ffffde", this.tertiaryColor = x(this.primaryColor, { h: -160 }), this.primaryBorderColor = st(this.primaryColor, this.darkMode), this.secondaryBorderColor = st(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = st(this.tertiaryColor, this.darkMode), this.primaryTextColor = B(this.primaryColor), this.secondaryTextColor = B(this.secondaryColor), this.tertiaryTextColor = B(this.tertiaryColor), this.lineColor = B(this.background), this.textColor = B(this.background), this.background = "white", this.mainBkg = "#ECECFF", this.secondBkg = "#ffffde", this.lineColor = "#333333", this.border1 = "#9370DB", this.primaryBorderColor = st(this.primaryColor, this.darkMode), this.border2 = "#aaaa33", this.arrowheadColor = "#333333", this.fontFamily = '"trebuchet ms", verdana, arial, sans-serif', this.fontSize = "16px", this.labelBackground = "rgba(232,232,232, 0.8)", this.textColor = "#333", this.THEME_COLOR_LIMIT = 12, this.radius = 5, this.strokeWidth = 1, this.nodeBkg = "calculated", this.nodeBorder = "calculated", this.clusterBkg = "calculated", this.clusterBorder = "calculated", this.defaultLinkColor = "calculated", this.titleColor = "calculated", this.edgeLabelBackground = "calculated", this.actorBorder = "calculated", this.actorBkg = "calculated", this.actorTextColor = "black", this.actorLineColor = "calculated", this.signalColor = "calculated", this.signalTextColor = "calculated", this.labelBoxBkgColor = "calculated", this.labelBoxBorderColor = "calculated", this.labelTextColor = "calculated", this.loopTextColor = "calculated", this.noteBorderColor = "calculated", this.noteBkgColor = "#fff5ad", this.noteTextColor = "calculated", this.activationBorderColor = "#666", this.activationBkgColor = "#f4f4f4", this.sequenceNumberColor = "white", this.clusterBkg = "#FBFBFF", this.sectionBkgColor = "calculated", this.altSectionBkgColor = "calculated", this.sectionBkgColor2 = "calculated", this.excludeBkgColor = "#eeeeee", this.taskBorderColor = "calculated", this.taskBkgColor = "calculated", this.taskTextLightColor = "calculated", this.taskTextColor = this.taskTextLightColor, this.taskTextDarkColor = "calculated", this.taskTextOutsideColor = this.taskTextDarkColor, this.taskTextClickableColor = "calculated", this.activeTaskBorderColor = "calculated", this.activeTaskBkgColor = "calculated", this.gridColor = "calculated", this.doneTaskBkgColor = "calculated", this.doneTaskBorderColor = "calculated", this.critBorderColor = "calculated", this.critBkgColor = "calculated", this.todayLineColor = "calculated", this.vertLineColor = "calculated", this.sectionBkgColor = Ke(102, 102, 255, 0.49), this.altSectionBkgColor = "white", this.sectionBkgColor2 = "#fff400", this.taskBorderColor = "#534fbc", this.taskBkgColor = "#8a90dd", this.taskTextLightColor = "white", this.taskTextColor = "calculated", this.taskTextDarkColor = "black", this.taskTextOutsideColor = "calculated", this.taskTextClickableColor = "#003163", this.activeTaskBorderColor = "#534fbc", this.activeTaskBkgColor = "#bfc7ff", this.gridColor = "lightgrey", this.doneTaskBkgColor = "lightgrey", this.doneTaskBorderColor = "grey", this.critBorderColor = "#ff8888", this.critBkgColor = "red", this.todayLineColor = "red", this.vertLineColor = "navy", this.noteFontWeight = this.noteFontWeight || "normal", this.fontWeight = this.fontWeight || "normal", this.personBorder = this.primaryBorderColor, this.personBkg = this.mainBkg, this.archEdgeColor = "calculated", this.archEdgeArrowColor = "calculated", this.archEdgeWidth = "3", this.archGroupBorderColor = this.primaryBorderColor, this.archGroupBorderWidth = "2px", this.rowOdd = "calculated", this.rowEven = "calculated", this.labelColor = "black", this.errorBkgColor = "#552222", this.errorTextColor = "#552222", this.useGradient = !1, this.gradientStart = this.primaryBorderColor, this.gradientStop = this.secondaryBorderColor, this.dropShadow = "drop-shadow(1px 2px 2px rgba(185, 185, 185, 1))", this.updateColors();
  }
  updateColors() {
    this.cScale0 = this.cScale0 || this.primaryColor, this.cScale1 = this.cScale1 || this.secondaryColor, this.cScale2 = this.cScale2 || this.tertiaryColor, this.cScale3 = this.cScale3 || x(this.primaryColor, { h: 30 }), this.cScale4 = this.cScale4 || x(this.primaryColor, { h: 60 }), this.cScale5 = this.cScale5 || x(this.primaryColor, { h: 90 }), this.cScale6 = this.cScale6 || x(this.primaryColor, { h: 120 }), this.cScale7 = this.cScale7 || x(this.primaryColor, { h: 150 }), this.cScale8 = this.cScale8 || x(this.primaryColor, { h: 210 }), this.cScale9 = this.cScale9 || x(this.primaryColor, { h: 270 }), this.cScale10 = this.cScale10 || x(this.primaryColor, { h: 300 }), this.cScale11 = this.cScale11 || x(this.primaryColor, { h: 330 }), this.cScalePeer1 = this.cScalePeer1 || O(this.secondaryColor, 45), this.cScalePeer2 = this.cScalePeer2 || O(this.tertiaryColor, 40);
    for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
      this["cScale" + e] = O(this["cScale" + e], 10), this["cScalePeer" + e] = this["cScalePeer" + e] || O(this["cScale" + e], 25);
    for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
      this["cScaleInv" + e] = this["cScaleInv" + e] || x(this["cScale" + e], { h: 180 });
    for (let e = 0; e < 5; e++)
      this["surface" + e] = this["surface" + e] || x(this.mainBkg, { h: 30, l: -(5 + e * 5) }), this["surfacePeer" + e] = this["surfacePeer" + e] || x(this.mainBkg, { h: 30, l: -(7 + e * 5) });
    if (this.scaleLabelColor = this.scaleLabelColor !== "calculated" && this.scaleLabelColor ? this.scaleLabelColor : this.labelTextColor, this.labelTextColor !== "calculated") {
      this.cScaleLabel0 = this.cScaleLabel0 || B(this.labelTextColor), this.cScaleLabel3 = this.cScaleLabel3 || B(this.labelTextColor);
      for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
        this["cScaleLabel" + e] = this["cScaleLabel" + e] || this.labelTextColor;
    }
    this.nodeBkg = this.mainBkg, this.nodeBorder = this.border1, this.clusterBkg = this.secondBkg, this.clusterBorder = this.border2, this.defaultLinkColor = this.lineColor, this.titleColor = this.textColor, this.edgeLabelBackground = this.labelBackground, this.actorBorder = this.border1, this.actorBkg = this.mainBkg, this.labelBoxBkgColor = this.actorBkg, this.signalColor = this.textColor, this.signalTextColor = this.textColor, this.labelBoxBorderColor = this.actorBorder, this.labelTextColor = this.actorTextColor, this.loopTextColor = this.actorTextColor, this.noteBorderColor = this.border2, this.noteTextColor = this.actorTextColor, this.actorLineColor = this.actorBorder, this.taskTextColor = this.taskTextLightColor, this.taskTextOutsideColor = this.taskTextDarkColor, this.archEdgeColor = this.lineColor, this.archEdgeArrowColor = this.lineColor, this.rowOdd = this.rowOdd || $(this.primaryColor, 75) || "#ffffff", this.rowEven = this.rowEven || $(this.primaryColor, 1), this.transitionColor = this.transitionColor || this.lineColor, this.transitionLabelColor = this.transitionLabelColor || this.textColor, this.stateLabelColor = this.stateLabelColor || this.stateBkg || this.primaryTextColor, this.stateBkg = this.stateBkg || this.mainBkg, this.labelBackgroundColor = this.labelBackgroundColor || this.stateBkg, this.compositeBackground = this.compositeBackground || this.background || this.tertiaryColor, this.altBackground = this.altBackground || "#f0f0f0", this.compositeTitleBackground = this.compositeTitleBackground || this.mainBkg, this.compositeBorder = this.compositeBorder || this.nodeBorder, this.innerEndBackground = this.nodeBorder, this.specialStateColor = this.lineColor, this.errorBkgColor = this.errorBkgColor || this.tertiaryColor, this.errorTextColor = this.errorTextColor || this.tertiaryTextColor, this.transitionColor = this.transitionColor || this.lineColor, this.classText = this.primaryTextColor, this.fillType0 = this.primaryColor, this.fillType1 = this.secondaryColor, this.fillType2 = x(this.primaryColor, { h: 64 }), this.fillType3 = x(this.secondaryColor, { h: 64 }), this.fillType4 = x(this.primaryColor, { h: -64 }), this.fillType5 = x(this.secondaryColor, { h: -64 }), this.fillType6 = x(this.primaryColor, { h: 128 }), this.fillType7 = x(this.secondaryColor, { h: 128 }), this.pie1 = this.pie1 || this.primaryColor, this.pie2 = this.pie2 || this.secondaryColor, this.pie3 = this.pie3 || x(this.tertiaryColor, { l: -40 }), this.pie4 = this.pie4 || x(this.primaryColor, { l: -10 }), this.pie5 = this.pie5 || x(this.secondaryColor, { l: -30 }), this.pie6 = this.pie6 || x(this.tertiaryColor, { l: -20 }), this.pie7 = this.pie7 || x(this.primaryColor, { h: 60, l: -20 }), this.pie8 = this.pie8 || x(this.primaryColor, { h: -60, l: -40 }), this.pie9 = this.pie9 || x(this.primaryColor, { h: 120, l: -40 }), this.pie10 = this.pie10 || x(this.primaryColor, { h: 60, l: -40 }), this.pie11 = this.pie11 || x(this.primaryColor, { h: -90, l: -40 }), this.pie12 = this.pie12 || x(this.primaryColor, { h: 120, l: -30 }), this.pieTitleTextSize = this.pieTitleTextSize || "25px", this.pieTitleTextColor = this.pieTitleTextColor || this.taskTextDarkColor, this.pieSectionTextSize = this.pieSectionTextSize || "17px", this.pieSectionTextColor = this.pieSectionTextColor || this.textColor, this.pieLegendTextSize = this.pieLegendTextSize || "17px", this.pieLegendTextColor = this.pieLegendTextColor || this.taskTextDarkColor, this.pieStrokeColor = this.pieStrokeColor || "black", this.pieStrokeWidth = this.pieStrokeWidth || "2px", this.pieOuterStrokeWidth = this.pieOuterStrokeWidth || "2px", this.pieOuterStrokeColor = this.pieOuterStrokeColor || "black", this.pieOpacity = this.pieOpacity || "0.7", this.venn1 = this.venn1 ?? x(this.primaryColor, { l: -30 }), this.venn2 = this.venn2 ?? x(this.secondaryColor, { l: -30 }), this.venn3 = this.venn3 ?? x(this.tertiaryColor, { l: -40 }), this.venn4 = this.venn4 ?? x(this.primaryColor, { h: 60, l: -30 }), this.venn5 = this.venn5 ?? x(this.primaryColor, { h: -60, l: -30 }), this.venn6 = this.venn6 ?? x(this.secondaryColor, { h: 60, l: -30 }), this.venn7 = this.venn7 ?? x(this.primaryColor, { h: 120, l: -30 }), this.venn8 = this.venn8 ?? x(this.secondaryColor, { h: 120, l: -30 }), this.vennTitleTextColor = this.vennTitleTextColor ?? this.titleColor, this.vennSetTextColor = this.vennSetTextColor ?? this.textColor, this.quadrant1Fill = this.quadrant1Fill || this.primaryColor, this.quadrant2Fill = this.quadrant2Fill || x(this.primaryColor, { r: 5, g: 5, b: 5 }), this.quadrant3Fill = this.quadrant3Fill || x(this.primaryColor, { r: 10, g: 10, b: 10 }), this.quadrant4Fill = this.quadrant4Fill || x(this.primaryColor, { r: 15, g: 15, b: 15 }), this.quadrant1TextFill = this.quadrant1TextFill || this.primaryTextColor, this.quadrant2TextFill = this.quadrant2TextFill || x(this.primaryTextColor, { r: -5, g: -5, b: -5 }), this.quadrant3TextFill = this.quadrant3TextFill || x(this.primaryTextColor, { r: -10, g: -10, b: -10 }), this.quadrant4TextFill = this.quadrant4TextFill || x(this.primaryTextColor, { r: -15, g: -15, b: -15 }), this.quadrantPointFill = this.quadrantPointFill || ye(this.quadrant1Fill) ? $(this.quadrant1Fill) : O(this.quadrant1Fill), this.quadrantPointTextFill = this.quadrantPointTextFill || this.primaryTextColor, this.quadrantXAxisTextFill = this.quadrantXAxisTextFill || this.primaryTextColor, this.quadrantYAxisTextFill = this.quadrantYAxisTextFill || this.primaryTextColor, this.quadrantInternalBorderStrokeFill = this.quadrantInternalBorderStrokeFill || this.primaryBorderColor, this.quadrantExternalBorderStrokeFill = this.quadrantExternalBorderStrokeFill || this.primaryBorderColor, this.quadrantTitleFill = this.quadrantTitleFill || this.primaryTextColor, this.radar = {
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
    }, this.wardleyEvolutionColor = this.wardleyEvolutionColor || "#dc3545", this.wardley = {
      backgroundColor: this.wardley?.backgroundColor || this.background,
      axisColor: this.wardley?.axisColor || this.lineColor,
      axisTextColor: this.wardley?.axisTextColor || this.primaryTextColor,
      gridColor: this.wardley?.gridColor || this.gridColor,
      componentFill: this.wardley?.componentFill || this.background,
      componentStroke: this.wardley?.componentStroke || this.lineColor,
      componentLabelColor: this.wardley?.componentLabelColor || this.primaryTextColor,
      linkStroke: this.wardley?.linkStroke || this.lineColor,
      evolutionStroke: this.wardley?.evolutionStroke || this.wardleyEvolutionColor,
      annotationStroke: this.wardley?.annotationStroke || this.lineColor,
      annotationTextColor: this.wardley?.annotationTextColor || this.primaryTextColor,
      annotationFill: this.wardley?.annotationFill || this.background
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
    }, this.requirementBackground = this.requirementBackground || this.primaryColor, this.requirementBorderColor = this.requirementBorderColor || this.primaryBorderColor, this.requirementBorderSize = this.requirementBorderSize || "1", this.requirementTextColor = this.requirementTextColor || this.primaryTextColor, this.relationColor = this.relationColor || this.lineColor, this.relationLabelBackground = this.relationLabelBackground || this.labelBackground, this.relationLabelColor = this.relationLabelColor || this.actorTextColor, this.git0 = this.git0 || this.primaryColor, this.git1 = this.git1 || this.secondaryColor, this.git2 = this.git2 || this.tertiaryColor, this.git3 = this.git3 || x(this.primaryColor, { h: -30 }), this.git4 = this.git4 || x(this.primaryColor, { h: -60 }), this.git5 = this.git5 || x(this.primaryColor, { h: -90 }), this.git6 = this.git6 || x(this.primaryColor, { h: 60 }), this.git7 = this.git7 || x(this.primaryColor, { h: 120 }), this.darkMode ? (this.git0 = $(this.git0, 25), this.git1 = $(this.git1, 25), this.git2 = $(this.git2, 25), this.git3 = $(this.git3, 25), this.git4 = $(this.git4, 25), this.git5 = $(this.git5, 25), this.git6 = $(this.git6, 25), this.git7 = $(this.git7, 25)) : (this.git0 = O(this.git0, 25), this.git1 = O(this.git1, 25), this.git2 = O(this.git2, 25), this.git3 = O(this.git3, 25), this.git4 = O(this.git4, 25), this.git5 = O(this.git5, 25), this.git6 = O(this.git6, 25), this.git7 = O(this.git7, 25)), this.gitInv0 = this.gitInv0 || O(B(this.git0), 25), this.gitInv1 = this.gitInv1 || B(this.git1), this.gitInv2 = this.gitInv2 || B(this.git2), this.gitInv3 = this.gitInv3 || B(this.git3), this.gitInv4 = this.gitInv4 || B(this.git4), this.gitInv5 = this.gitInv5 || B(this.git5), this.gitInv6 = this.gitInv6 || B(this.git6), this.gitInv7 = this.gitInv7 || B(this.git7), this.gitBranchLabel0 = this.gitBranchLabel0 || B(this.labelTextColor), this.gitBranchLabel1 = this.gitBranchLabel1 || this.labelTextColor, this.gitBranchLabel2 = this.gitBranchLabel2 || this.labelTextColor, this.gitBranchLabel3 = this.gitBranchLabel3 || B(this.labelTextColor), this.gitBranchLabel4 = this.gitBranchLabel4 || this.labelTextColor, this.gitBranchLabel5 = this.gitBranchLabel5 || this.labelTextColor, this.gitBranchLabel6 = this.gitBranchLabel6 || this.labelTextColor, this.gitBranchLabel7 = this.gitBranchLabel7 || this.labelTextColor, this.tagLabelColor = this.tagLabelColor || this.primaryTextColor, this.tagLabelBackground = this.tagLabelBackground || this.primaryColor, this.tagLabelBorder = this.tagBorder || this.primaryBorderColor, this.tagLabelFontSize = this.tagLabelFontSize || "10px", this.commitLabelColor = this.commitLabelColor || this.secondaryTextColor, this.commitLabelBackground = this.commitLabelBackground || this.secondaryColor, this.commitLabelFontSize = this.commitLabelFontSize || "10px", this.emUiFill = this.emUiFill || "white", this.emUiStroke = this.emUiStroke || "#dbdada", this.emProcessorFill = this.emProcessorFill || "#edb3f6", this.emProcessorStroke = this.emProcessorStroke || "#b88cbf", this.emReadModelFill = this.emReadModelFill || "#d3f1a2", this.emReadModelStroke = this.emReadModelStroke || "#a3b732", this.emCommandFill = this.emCommandFill || "#bcd6fe", this.emCommandStroke = this.emCommandStroke || "#679ac3", this.emEventFill = this.emEventFill || "#ffb778", this.emEventStroke = this.emEventStroke || "#c19a0f", this.emSwimlaneBackgroundOdd = this.emSwimlaneBackgroundOdd || "rgb(250,250,250)", this.emSwimlaneBackgroundStroke = this.emSwimlaneBackgroundStroke || "rgb(240,240,240)", this.emArrowhead = this.emArrowhead || this.lineColor, this.emRelationStroke = this.emRelationStroke || this.lineColor, this.attributeBackgroundColorOdd = this.attributeBackgroundColorOdd || ve, this.attributeBackgroundColorEven = this.attributeBackgroundColorEven || Le;
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
}, Iy = /* @__PURE__ */ p((e) => {
  const t = new Oy();
  return t.calculate(e), t;
}, "getThemeVariables"), Dy = class {
  static {
    p(this, "Theme");
  }
  constructor() {
    this.background = "#f4f4f4", this.primaryColor = "#cde498", this.secondaryColor = "#cdffb2", this.background = "white", this.mainBkg = "#cde498", this.secondBkg = "#cdffb2", this.lineColor = "green", this.border1 = "#13540c", this.border2 = "#6eaa49", this.arrowheadColor = "green", this.fontFamily = '"trebuchet ms", verdana, arial, sans-serif', this.fontSize = "16px", this.tertiaryColor = $("#cde498", 10), this.primaryBorderColor = st(this.primaryColor, this.darkMode), this.secondaryBorderColor = st(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = st(this.tertiaryColor, this.darkMode), this.primaryTextColor = B(this.primaryColor), this.secondaryTextColor = B(this.secondaryColor), this.tertiaryTextColor = B(this.primaryColor), this.lineColor = B(this.background), this.textColor = B(this.background), this.THEME_COLOR_LIMIT = 12, this.radius = 5, this.strokeWidth = 1, this.nodeBkg = "calculated", this.nodeBorder = "calculated", this.clusterBkg = "calculated", this.clusterBorder = "calculated", this.defaultLinkColor = "calculated", this.titleColor = "#333", this.edgeLabelBackground = "#e8e8e8", this.actorBorder = "calculated", this.actorBkg = "calculated", this.actorTextColor = "black", this.actorLineColor = "calculated", this.signalColor = "#333", this.signalTextColor = "#333", this.labelBoxBkgColor = "calculated", this.labelBoxBorderColor = "#326932", this.labelTextColor = "calculated", this.loopTextColor = "calculated", this.noteBorderColor = "calculated", this.noteBkgColor = "#fff5ad", this.noteTextColor = "calculated", this.activationBorderColor = "#666", this.activationBkgColor = "#f4f4f4", this.sequenceNumberColor = "white", this.sectionBkgColor = "#6eaa49", this.altSectionBkgColor = "white", this.sectionBkgColor2 = "#6eaa49", this.excludeBkgColor = "#eeeeee", this.taskBorderColor = "calculated", this.taskBkgColor = "#487e3a", this.taskTextLightColor = "white", this.taskTextColor = "calculated", this.taskTextDarkColor = "black", this.taskTextOutsideColor = "calculated", this.taskTextClickableColor = "#003163", this.activeTaskBorderColor = "calculated", this.activeTaskBkgColor = "calculated", this.gridColor = "lightgrey", this.doneTaskBkgColor = "lightgrey", this.doneTaskBorderColor = "grey", this.critBorderColor = "#ff8888", this.critBkgColor = "red", this.todayLineColor = "red", this.vertLineColor = "#00BFFF", this.personBorder = this.primaryBorderColor, this.personBkg = this.mainBkg, this.archEdgeColor = "calculated", this.archEdgeArrowColor = "calculated", this.archEdgeWidth = "3", this.archGroupBorderColor = this.primaryBorderColor, this.archGroupBorderWidth = "2px", this.noteFontWeight = "normal", this.fontWeight = "normal", this.labelColor = "black", this.errorBkgColor = "#552222", this.errorTextColor = "#552222", this.useGradient = !0, this.gradientStart = this.primaryBorderColor, this.gradientStop = this.secondaryBorderColor, this.dropShadow = "drop-shadow( 1px 2px 2px rgba(185,185,185,0.5))";
  }
  updateColors() {
    this.actorBorder = O(this.mainBkg, 20), this.actorBkg = this.mainBkg, this.labelBoxBkgColor = this.actorBkg, this.labelTextColor = this.actorTextColor, this.loopTextColor = this.actorTextColor, this.noteBorderColor = this.border2, this.noteTextColor = this.actorTextColor, this.actorLineColor = this.actorBorder, this.cScale0 = this.cScale0 || this.primaryColor, this.cScale1 = this.cScale1 || this.secondaryColor, this.cScale2 = this.cScale2 || this.tertiaryColor, this.cScale3 = this.cScale3 || x(this.primaryColor, { h: 30 }), this.cScale4 = this.cScale4 || x(this.primaryColor, { h: 60 }), this.cScale5 = this.cScale5 || x(this.primaryColor, { h: 90 }), this.cScale6 = this.cScale6 || x(this.primaryColor, { h: 120 }), this.cScale7 = this.cScale7 || x(this.primaryColor, { h: 150 }), this.cScale8 = this.cScale8 || x(this.primaryColor, { h: 210 }), this.cScale9 = this.cScale9 || x(this.primaryColor, { h: 270 }), this.cScale10 = this.cScale10 || x(this.primaryColor, { h: 300 }), this.cScale11 = this.cScale11 || x(this.primaryColor, { h: 330 }), this.cScalePeer1 = this.cScalePeer1 || O(this.secondaryColor, 45), this.cScalePeer2 = this.cScalePeer2 || O(this.tertiaryColor, 40);
    for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
      this["cScale" + e] = O(this["cScale" + e], 10), this["cScalePeer" + e] = this["cScalePeer" + e] || O(this["cScale" + e], 25);
    for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
      this["cScaleInv" + e] = this["cScaleInv" + e] || x(this["cScale" + e], { h: 180 });
    this.scaleLabelColor = this.scaleLabelColor !== "calculated" && this.scaleLabelColor ? this.scaleLabelColor : this.labelTextColor;
    for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
      this["cScaleLabel" + e] = this["cScaleLabel" + e] || this.scaleLabelColor;
    for (let e = 0; e < 5; e++)
      this["surface" + e] = this["surface" + e] || x(this.mainBkg, { h: 30, s: -30, l: -(5 + e * 5) }), this["surfacePeer" + e] = this["surfacePeer" + e] || x(this.mainBkg, { h: 30, s: -30, l: -(8 + e * 5) });
    this.nodeBkg = this.mainBkg, this.nodeBorder = this.border1, this.clusterBkg = this.secondBkg, this.clusterBorder = this.border2, this.defaultLinkColor = this.lineColor, this.taskBorderColor = this.border1, this.taskTextColor = this.taskTextLightColor, this.taskTextOutsideColor = this.taskTextDarkColor, this.activeTaskBorderColor = this.taskBorderColor, this.activeTaskBkgColor = this.mainBkg, this.archEdgeColor = this.lineColor, this.archEdgeArrowColor = this.lineColor, this.rowOdd = this.rowOdd || $(this.mainBkg, 75) || "#ffffff", this.rowEven = this.rowEven || $(this.mainBkg, 20), this.transitionColor = this.transitionColor || this.lineColor, this.transitionLabelColor = this.transitionLabelColor || this.textColor, this.stateLabelColor = this.stateLabelColor || this.stateBkg || this.primaryTextColor, this.stateBkg = this.stateBkg || this.mainBkg, this.labelBackgroundColor = this.labelBackgroundColor || this.stateBkg, this.compositeBackground = this.compositeBackground || this.background || this.tertiaryColor, this.altBackground = this.altBackground || "#f0f0f0", this.compositeTitleBackground = this.compositeTitleBackground || this.mainBkg, this.compositeBorder = this.compositeBorder || this.nodeBorder, this.innerEndBackground = this.primaryBorderColor, this.specialStateColor = this.lineColor, this.errorBkgColor = this.errorBkgColor || this.tertiaryColor, this.errorTextColor = this.errorTextColor || this.tertiaryTextColor, this.transitionColor = this.transitionColor || this.lineColor, this.classText = this.primaryTextColor, this.fillType0 = this.primaryColor, this.fillType1 = this.secondaryColor, this.fillType2 = x(this.primaryColor, { h: 64 }), this.fillType3 = x(this.secondaryColor, { h: 64 }), this.fillType4 = x(this.primaryColor, { h: -64 }), this.fillType5 = x(this.secondaryColor, { h: -64 }), this.fillType6 = x(this.primaryColor, { h: 128 }), this.fillType7 = x(this.secondaryColor, { h: 128 }), this.pie1 = this.pie1 || this.primaryColor, this.pie2 = this.pie2 || this.secondaryColor, this.pie3 = this.pie3 || this.tertiaryColor, this.pie4 = this.pie4 || x(this.primaryColor, { l: -30 }), this.pie5 = this.pie5 || x(this.secondaryColor, { l: -30 }), this.pie6 = this.pie6 || x(this.tertiaryColor, { h: 40, l: -40 }), this.pie7 = this.pie7 || x(this.primaryColor, { h: 60, l: -10 }), this.pie8 = this.pie8 || x(this.primaryColor, { h: -60, l: -10 }), this.pie9 = this.pie9 || x(this.primaryColor, { h: 120, l: 0 }), this.pie10 = this.pie10 || x(this.primaryColor, { h: 60, l: -50 }), this.pie11 = this.pie11 || x(this.primaryColor, { h: -60, l: -50 }), this.pie12 = this.pie12 || x(this.primaryColor, { h: 120, l: -50 }), this.pieTitleTextSize = this.pieTitleTextSize || "25px", this.pieTitleTextColor = this.pieTitleTextColor || this.taskTextDarkColor, this.pieSectionTextSize = this.pieSectionTextSize || "17px", this.pieSectionTextColor = this.pieSectionTextColor || this.textColor, this.pieLegendTextSize = this.pieLegendTextSize || "17px", this.pieLegendTextColor = this.pieLegendTextColor || this.taskTextDarkColor, this.pieStrokeColor = this.pieStrokeColor || "black", this.pieStrokeWidth = this.pieStrokeWidth || "2px", this.pieOuterStrokeWidth = this.pieOuterStrokeWidth || "2px", this.pieOuterStrokeColor = this.pieOuterStrokeColor || "black", this.pieOpacity = this.pieOpacity || "0.7", this.venn1 = this.venn1 ?? x(this.primaryColor, { l: -30 }), this.venn2 = this.venn2 ?? x(this.secondaryColor, { l: -30 }), this.venn3 = this.venn3 ?? x(this.tertiaryColor, { l: -30 }), this.venn4 = this.venn4 ?? x(this.primaryColor, { h: 60, l: -30 }), this.venn5 = this.venn5 ?? x(this.primaryColor, { h: -60, l: -30 }), this.venn6 = this.venn6 ?? x(this.secondaryColor, { h: 60, l: -30 }), this.venn7 = this.venn7 ?? x(this.primaryColor, { h: 120, l: -30 }), this.venn8 = this.venn8 ?? x(this.secondaryColor, { h: 120, l: -30 }), this.vennTitleTextColor = this.vennTitleTextColor ?? this.titleColor, this.vennSetTextColor = this.vennSetTextColor ?? this.textColor, this.quadrant1Fill = this.quadrant1Fill || this.primaryColor, this.quadrant2Fill = this.quadrant2Fill || x(this.primaryColor, { r: 5, g: 5, b: 5 }), this.quadrant3Fill = this.quadrant3Fill || x(this.primaryColor, { r: 10, g: 10, b: 10 }), this.quadrant4Fill = this.quadrant4Fill || x(this.primaryColor, { r: 15, g: 15, b: 15 }), this.quadrant1TextFill = this.quadrant1TextFill || this.primaryTextColor, this.quadrant2TextFill = this.quadrant2TextFill || x(this.primaryTextColor, { r: -5, g: -5, b: -5 }), this.quadrant3TextFill = this.quadrant3TextFill || x(this.primaryTextColor, { r: -10, g: -10, b: -10 }), this.quadrant4TextFill = this.quadrant4TextFill || x(this.primaryTextColor, { r: -15, g: -15, b: -15 }), this.quadrantPointFill = this.quadrantPointFill || ye(this.quadrant1Fill) ? $(this.quadrant1Fill) : O(this.quadrant1Fill), this.quadrantPointTextFill = this.quadrantPointTextFill || this.primaryTextColor, this.quadrantXAxisTextFill = this.quadrantXAxisTextFill || this.primaryTextColor, this.quadrantYAxisTextFill = this.quadrantYAxisTextFill || this.primaryTextColor, this.quadrantInternalBorderStrokeFill = this.quadrantInternalBorderStrokeFill || this.primaryBorderColor, this.quadrantExternalBorderStrokeFill = this.quadrantExternalBorderStrokeFill || this.primaryBorderColor, this.quadrantTitleFill = this.quadrantTitleFill || this.primaryTextColor, this.packet = {
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
    }, this.wardleyEvolutionColor = this.wardleyEvolutionColor || "#dc3545", this.wardley = {
      backgroundColor: this.wardley?.backgroundColor || this.background,
      axisColor: this.wardley?.axisColor || this.lineColor,
      axisTextColor: this.wardley?.axisTextColor || this.primaryTextColor,
      gridColor: this.wardley?.gridColor || this.gridColor,
      componentFill: this.wardley?.componentFill || this.background,
      componentStroke: this.wardley?.componentStroke || this.lineColor,
      componentLabelColor: this.wardley?.componentLabelColor || this.primaryTextColor,
      linkStroke: this.wardley?.linkStroke || this.lineColor,
      evolutionStroke: this.wardley?.evolutionStroke || this.wardleyEvolutionColor,
      annotationStroke: this.wardley?.annotationStroke || this.lineColor,
      annotationTextColor: this.wardley?.annotationTextColor || this.primaryTextColor,
      annotationFill: this.wardley?.annotationFill || this.background
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
    }, this.requirementBackground = this.requirementBackground || this.primaryColor, this.requirementBorderColor = this.requirementBorderColor || this.primaryBorderColor, this.requirementBorderSize = this.requirementBorderSize || "1", this.requirementTextColor = this.requirementTextColor || this.primaryTextColor, this.relationColor = this.relationColor || this.lineColor, this.relationLabelBackground = this.relationLabelBackground || this.edgeLabelBackground, this.relationLabelColor = this.relationLabelColor || this.actorTextColor, this.git0 = this.git0 || this.primaryColor, this.git1 = this.git1 || this.secondaryColor, this.git2 = this.git2 || this.tertiaryColor, this.git3 = this.git3 || x(this.primaryColor, { h: -30 }), this.git4 = this.git4 || x(this.primaryColor, { h: -60 }), this.git5 = this.git5 || x(this.primaryColor, { h: -90 }), this.git6 = this.git6 || x(this.primaryColor, { h: 60 }), this.git7 = this.git7 || x(this.primaryColor, { h: 120 }), this.darkMode ? (this.git0 = $(this.git0, 25), this.git1 = $(this.git1, 25), this.git2 = $(this.git2, 25), this.git3 = $(this.git3, 25), this.git4 = $(this.git4, 25), this.git5 = $(this.git5, 25), this.git6 = $(this.git6, 25), this.git7 = $(this.git7, 25)) : (this.git0 = O(this.git0, 25), this.git1 = O(this.git1, 25), this.git2 = O(this.git2, 25), this.git3 = O(this.git3, 25), this.git4 = O(this.git4, 25), this.git5 = O(this.git5, 25), this.git6 = O(this.git6, 25), this.git7 = O(this.git7, 25)), this.gitInv0 = this.gitInv0 || B(this.git0), this.gitInv1 = this.gitInv1 || B(this.git1), this.gitInv2 = this.gitInv2 || B(this.git2), this.gitInv3 = this.gitInv3 || B(this.git3), this.gitInv4 = this.gitInv4 || B(this.git4), this.gitInv5 = this.gitInv5 || B(this.git5), this.gitInv6 = this.gitInv6 || B(this.git6), this.gitInv7 = this.gitInv7 || B(this.git7), this.gitBranchLabel0 = this.gitBranchLabel0 || B(this.labelTextColor), this.gitBranchLabel1 = this.gitBranchLabel1 || this.labelTextColor, this.gitBranchLabel2 = this.gitBranchLabel2 || this.labelTextColor, this.gitBranchLabel3 = this.gitBranchLabel3 || B(this.labelTextColor), this.gitBranchLabel4 = this.gitBranchLabel4 || this.labelTextColor, this.gitBranchLabel5 = this.gitBranchLabel5 || this.labelTextColor, this.gitBranchLabel6 = this.gitBranchLabel6 || this.labelTextColor, this.gitBranchLabel7 = this.gitBranchLabel7 || this.labelTextColor, this.tagLabelColor = this.tagLabelColor || this.primaryTextColor, this.tagLabelBackground = this.tagLabelBackground || this.primaryColor, this.tagLabelBorder = this.tagBorder || this.primaryBorderColor, this.tagLabelFontSize = this.tagLabelFontSize || "10px", this.commitLabelColor = this.commitLabelColor || this.secondaryTextColor, this.commitLabelBackground = this.commitLabelBackground || this.secondaryColor, this.commitLabelFontSize = this.commitLabelFontSize || "10px", this.emUiFill = this.emUiFill || "white", this.emUiStroke = this.emUiStroke || "#dbdada", this.emProcessorFill = this.emProcessorFill || "#edb3f6", this.emProcessorStroke = this.emProcessorStroke || "#b88cbf", this.emReadModelFill = this.emReadModelFill || "#d3f1a2", this.emReadModelStroke = this.emReadModelStroke || "#a3b732", this.emCommandFill = this.emCommandFill || "#bcd6fe", this.emCommandStroke = this.emCommandStroke || "#679ac3", this.emEventFill = this.emEventFill || "#ffb778", this.emEventStroke = this.emEventStroke || "#c19a0f", this.emSwimlaneBackgroundOdd = this.emSwimlaneBackgroundOdd || "rgb(250,250,250)", this.emSwimlaneBackgroundStroke = this.emSwimlaneBackgroundStroke || "rgb(240,240,240)", this.emArrowhead = this.emArrowhead || this.lineColor, this.emRelationStroke = this.emRelationStroke || this.lineColor, this.attributeBackgroundColorOdd = this.attributeBackgroundColorOdd || ve, this.attributeBackgroundColorEven = this.attributeBackgroundColorEven || Le;
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
}, Ry = /* @__PURE__ */ p((e) => {
  const t = new Dy();
  return t.calculate(e), t;
}, "getThemeVariables"), Py = class {
  static {
    p(this, "Theme");
  }
  constructor() {
    this.primaryColor = "#eee", this.contrast = "#707070", this.secondaryColor = $(this.contrast, 55), this.background = "#ffffff", this.tertiaryColor = x(this.primaryColor, { h: -160 }), this.primaryBorderColor = st(this.primaryColor, this.darkMode), this.secondaryBorderColor = st(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = st(this.tertiaryColor, this.darkMode), this.primaryTextColor = B(this.primaryColor), this.secondaryTextColor = B(this.secondaryColor), this.tertiaryTextColor = B(this.tertiaryColor), this.lineColor = B(this.background), this.textColor = B(this.background), this.mainBkg = "#eee", this.secondBkg = "calculated", this.lineColor = "#666", this.border1 = "#999", this.border2 = "calculated", this.note = "#ffa", this.text = "#333", this.critical = "#d42", this.done = "#bbb", this.arrowheadColor = "#333333", this.fontFamily = '"trebuchet ms", verdana, arial, sans-serif', this.fontSize = "16px", this.THEME_COLOR_LIMIT = 12, this.radius = 5, this.strokeWidth = 1, this.nodeBkg = "calculated", this.nodeBorder = "calculated", this.clusterBkg = "calculated", this.clusterBorder = "calculated", this.defaultLinkColor = "calculated", this.titleColor = "calculated", this.edgeLabelBackground = "white", this.actorBorder = "calculated", this.actorBkg = "calculated", this.actorTextColor = "calculated", this.actorLineColor = this.actorBorder, this.signalColor = "calculated", this.signalTextColor = "calculated", this.labelBoxBkgColor = "calculated", this.labelBoxBorderColor = "calculated", this.labelTextColor = "calculated", this.loopTextColor = "calculated", this.noteBorderColor = "calculated", this.noteBkgColor = "calculated", this.noteTextColor = "calculated", this.activationBorderColor = "#666", this.activationBkgColor = "#f4f4f4", this.sequenceNumberColor = "white", this.sectionBkgColor = "calculated", this.altSectionBkgColor = "white", this.sectionBkgColor2 = "calculated", this.excludeBkgColor = "#eeeeee", this.taskBorderColor = "calculated", this.taskBkgColor = "calculated", this.taskTextLightColor = "white", this.taskTextColor = "calculated", this.taskTextDarkColor = "calculated", this.taskTextOutsideColor = "calculated", this.taskTextClickableColor = "#003163", this.activeTaskBorderColor = "calculated", this.activeTaskBkgColor = "calculated", this.gridColor = "calculated", this.doneTaskBkgColor = "calculated", this.doneTaskBorderColor = "calculated", this.critBkgColor = "calculated", this.critBorderColor = "calculated", this.todayLineColor = "calculated", this.vertLineColor = "calculated", this.personBorder = this.primaryBorderColor, this.personBkg = this.mainBkg, this.archEdgeColor = "calculated", this.archEdgeArrowColor = "calculated", this.archEdgeWidth = "3", this.archGroupBorderColor = this.primaryBorderColor, this.archGroupBorderWidth = "2px", this.noteFontWeight = "normal", this.fontWeight = "normal", this.rowOdd = this.rowOdd || $(this.mainBkg, 75) || "#ffffff", this.rowEven = this.rowEven || "#f4f4f4", this.labelColor = "black", this.errorBkgColor = "#552222", this.errorTextColor = "#552222", this.useGradient = !0, this.gradientStart = this.primaryBorderColor, this.gradientStop = this.secondaryBorderColor, this.dropShadow = "drop-shadow( 1px 2px 2px rgba(185,185,185,1))";
  }
  updateColors() {
    this.secondBkg = $(this.contrast, 55), this.border2 = this.contrast, this.actorBorder = $(this.border1, 23), this.actorBkg = this.mainBkg, this.actorTextColor = this.text, this.actorLineColor = this.actorBorder, this.signalColor = this.text, this.signalTextColor = this.text, this.labelBoxBkgColor = this.actorBkg, this.labelBoxBorderColor = this.actorBorder, this.labelTextColor = this.text, this.loopTextColor = this.text, this.noteBorderColor = "#999", this.noteBkgColor = "#666", this.noteTextColor = "#fff", this.cScale0 = this.cScale0 || "#555", this.cScale1 = this.cScale1 || "#F4F4F4", this.cScale2 = this.cScale2 || "#555", this.cScale3 = this.cScale3 || "#BBB", this.cScale4 = this.cScale4 || "#777", this.cScale5 = this.cScale5 || "#999", this.cScale6 = this.cScale6 || "#DDD", this.cScale7 = this.cScale7 || "#FFF", this.cScale8 = this.cScale8 || "#DDD", this.cScale9 = this.cScale9 || "#BBB", this.cScale10 = this.cScale10 || "#999", this.cScale11 = this.cScale11 || "#777";
    for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
      this["cScaleInv" + e] = this["cScaleInv" + e] || B(this["cScale" + e]);
    for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
      this.darkMode ? this["cScalePeer" + e] = this["cScalePeer" + e] || $(this["cScale" + e], 10) : this["cScalePeer" + e] = this["cScalePeer" + e] || O(this["cScale" + e], 10);
    this.scaleLabelColor = this.scaleLabelColor || (this.darkMode ? "black" : this.labelTextColor), this.cScaleLabel0 = this.cScaleLabel0 || this.cScale1, this.cScaleLabel2 = this.cScaleLabel2 || this.cScale1;
    for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
      this["cScaleLabel" + e] = this["cScaleLabel" + e] || this.scaleLabelColor;
    for (let e = 0; e < 5; e++)
      this["surface" + e] = this["surface" + e] || x(this.mainBkg, { l: -(5 + e * 5) }), this["surfacePeer" + e] = this["surfacePeer" + e] || x(this.mainBkg, { l: -(8 + e * 5) });
    this.nodeBkg = this.mainBkg, this.nodeBorder = this.border1, this.clusterBkg = this.secondBkg, this.clusterBorder = this.border2, this.defaultLinkColor = this.lineColor, this.titleColor = this.text, this.sectionBkgColor = $(this.contrast, 30), this.sectionBkgColor2 = $(this.contrast, 30), this.taskBorderColor = O(this.contrast, 10), this.taskBkgColor = this.contrast, this.taskTextColor = this.taskTextLightColor, this.taskTextDarkColor = this.text, this.taskTextOutsideColor = this.taskTextDarkColor, this.activeTaskBorderColor = this.taskBorderColor, this.activeTaskBkgColor = this.mainBkg, this.gridColor = $(this.border1, 30), this.doneTaskBkgColor = this.done, this.doneTaskBorderColor = this.lineColor, this.critBkgColor = this.critical, this.critBorderColor = O(this.critBkgColor, 10), this.todayLineColor = this.critBkgColor, this.vertLineColor = this.critBkgColor, this.archEdgeColor = this.lineColor, this.archEdgeArrowColor = this.lineColor, this.transitionColor = this.transitionColor || "#000", this.transitionLabelColor = this.transitionLabelColor || this.textColor, this.stateLabelColor = this.stateLabelColor || this.stateBkg || this.primaryTextColor, this.stateBkg = this.stateBkg || this.mainBkg, this.labelBackgroundColor = this.labelBackgroundColor || this.stateBkg, this.compositeBackground = this.compositeBackground || this.background || this.tertiaryColor, this.altBackground = this.altBackground || "#f4f4f4", this.compositeTitleBackground = this.compositeTitleBackground || this.mainBkg, this.stateBorder = this.stateBorder || "#000", this.innerEndBackground = this.primaryBorderColor, this.specialStateColor = "#222", this.errorBkgColor = this.errorBkgColor || this.tertiaryColor, this.errorTextColor = this.errorTextColor || this.tertiaryTextColor, this.classText = this.primaryTextColor, this.fillType0 = this.primaryColor, this.fillType1 = this.secondaryColor, this.fillType2 = x(this.primaryColor, { h: 64 }), this.fillType3 = x(this.secondaryColor, { h: 64 }), this.fillType4 = x(this.primaryColor, { h: -64 }), this.fillType5 = x(this.secondaryColor, { h: -64 }), this.fillType6 = x(this.primaryColor, { h: 128 }), this.fillType7 = x(this.secondaryColor, { h: 128 });
    for (let e = 0; e < this.THEME_COLOR_LIMIT; e++)
      this["pie" + e] = this["cScale" + e];
    this.pie12 = this.pie0, this.pieTitleTextSize = this.pieTitleTextSize || "25px", this.pieTitleTextColor = this.pieTitleTextColor || this.taskTextDarkColor, this.pieSectionTextSize = this.pieSectionTextSize || "17px", this.pieSectionTextColor = this.pieSectionTextColor || this.textColor, this.pieLegendTextSize = this.pieLegendTextSize || "17px", this.pieLegendTextColor = this.pieLegendTextColor || this.taskTextDarkColor, this.pieStrokeColor = this.pieStrokeColor || "black", this.pieStrokeWidth = this.pieStrokeWidth || "2px", this.pieOuterStrokeWidth = this.pieOuterStrokeWidth || "2px", this.pieOuterStrokeColor = this.pieOuterStrokeColor || "black", this.pieOpacity = this.pieOpacity || "0.7";
    for (let e = 0; e < 8; e++)
      this["venn" + (e + 1)] = this["venn" + (e + 1)] ?? this["cScale" + e];
    this.vennTitleTextColor = this.vennTitleTextColor ?? this.titleColor, this.vennSetTextColor = this.vennSetTextColor ?? this.textColor, this.quadrant1Fill = this.quadrant1Fill || this.primaryColor, this.quadrant2Fill = this.quadrant2Fill || x(this.primaryColor, { r: 5, g: 5, b: 5 }), this.quadrant3Fill = this.quadrant3Fill || x(this.primaryColor, { r: 10, g: 10, b: 10 }), this.quadrant4Fill = this.quadrant4Fill || x(this.primaryColor, { r: 15, g: 15, b: 15 }), this.quadrant1TextFill = this.quadrant1TextFill || this.primaryTextColor, this.quadrant2TextFill = this.quadrant2TextFill || x(this.primaryTextColor, { r: -5, g: -5, b: -5 }), this.quadrant3TextFill = this.quadrant3TextFill || x(this.primaryTextColor, { r: -10, g: -10, b: -10 }), this.quadrant4TextFill = this.quadrant4TextFill || x(this.primaryTextColor, { r: -15, g: -15, b: -15 }), this.quadrantPointFill = this.quadrantPointFill || ye(this.quadrant1Fill) ? $(this.quadrant1Fill) : O(this.quadrant1Fill), this.quadrantPointTextFill = this.quadrantPointTextFill || this.primaryTextColor, this.quadrantXAxisTextFill = this.quadrantXAxisTextFill || this.primaryTextColor, this.quadrantYAxisTextFill = this.quadrantYAxisTextFill || this.primaryTextColor, this.quadrantInternalBorderStrokeFill = this.quadrantInternalBorderStrokeFill || this.primaryBorderColor, this.quadrantExternalBorderStrokeFill = this.quadrantExternalBorderStrokeFill || this.primaryBorderColor, this.quadrantTitleFill = this.quadrantTitleFill || this.primaryTextColor, this.xyChart = {
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
    }, this.wardleyEvolutionColor = this.wardleyEvolutionColor || "#dc3545", this.wardley = {
      backgroundColor: this.wardley?.backgroundColor || this.background,
      axisColor: this.wardley?.axisColor || this.lineColor,
      axisTextColor: this.wardley?.axisTextColor || this.primaryTextColor,
      gridColor: this.wardley?.gridColor || this.gridColor,
      componentFill: this.wardley?.componentFill || this.background,
      componentStroke: this.wardley?.componentStroke || this.lineColor,
      componentLabelColor: this.wardley?.componentLabelColor || this.primaryTextColor,
      linkStroke: this.wardley?.linkStroke || this.lineColor,
      evolutionStroke: this.wardley?.evolutionStroke || this.wardleyEvolutionColor,
      annotationStroke: this.wardley?.annotationStroke || this.lineColor,
      annotationTextColor: this.wardley?.annotationTextColor || this.primaryTextColor,
      annotationFill: this.wardley?.annotationFill || this.background
    }, this.requirementBackground = this.requirementBackground || this.primaryColor, this.requirementBorderColor = this.requirementBorderColor || this.primaryBorderColor, this.requirementBorderSize = this.requirementBorderSize || "1", this.requirementTextColor = this.requirementTextColor || this.primaryTextColor, this.relationColor = this.relationColor || this.lineColor, this.relationLabelBackground = this.relationLabelBackground || this.edgeLabelBackground, this.relationLabelColor = this.relationLabelColor || this.actorTextColor, this.git0 = O(this.pie1, 25) || this.primaryColor, this.git1 = this.pie2 || this.secondaryColor, this.git2 = this.pie3 || this.tertiaryColor, this.git3 = this.pie4 || x(this.primaryColor, { h: -30 }), this.git4 = this.pie5 || x(this.primaryColor, { h: -60 }), this.git5 = this.pie6 || x(this.primaryColor, { h: -90 }), this.git6 = this.pie7 || x(this.primaryColor, { h: 60 }), this.git7 = this.pie8 || x(this.primaryColor, { h: 120 }), this.gitInv0 = this.gitInv0 || B(this.git0), this.gitInv1 = this.gitInv1 || B(this.git1), this.gitInv2 = this.gitInv2 || B(this.git2), this.gitInv3 = this.gitInv3 || B(this.git3), this.gitInv4 = this.gitInv4 || B(this.git4), this.gitInv5 = this.gitInv5 || B(this.git5), this.gitInv6 = this.gitInv6 || B(this.git6), this.gitInv7 = this.gitInv7 || B(this.git7), this.branchLabelColor = this.branchLabelColor || this.labelTextColor, this.gitBranchLabel0 = this.branchLabelColor, this.gitBranchLabel1 = "white", this.gitBranchLabel2 = this.branchLabelColor, this.gitBranchLabel3 = "white", this.gitBranchLabel4 = this.branchLabelColor, this.gitBranchLabel5 = this.branchLabelColor, this.gitBranchLabel6 = this.branchLabelColor, this.gitBranchLabel7 = this.branchLabelColor, this.tagLabelColor = this.tagLabelColor || this.primaryTextColor, this.tagLabelBackground = this.tagLabelBackground || this.primaryColor, this.tagLabelBorder = this.tagBorder || this.primaryBorderColor, this.tagLabelFontSize = this.tagLabelFontSize || "10px", this.commitLabelColor = this.commitLabelColor || this.secondaryTextColor, this.commitLabelBackground = this.commitLabelBackground || this.secondaryColor, this.commitLabelFontSize = this.commitLabelFontSize || "10px", this.emUiFill = this.emUiFill || "white", this.emUiStroke = this.emUiStroke || "#dbdada", this.emProcessorFill = this.emProcessorFill || "#edb3f6", this.emProcessorStroke = this.emProcessorStroke || "#b88cbf", this.emReadModelFill = this.emReadModelFill || "#d3f1a2", this.emReadModelStroke = this.emReadModelStroke || "#a3b732", this.emCommandFill = this.emCommandFill || "#bcd6fe", this.emCommandStroke = this.emCommandStroke || "#679ac3", this.emEventFill = this.emEventFill || "#ffb778", this.emEventStroke = this.emEventStroke || "#c19a0f", this.emSwimlaneBackgroundOdd = this.emSwimlaneBackgroundOdd || "rgb(250,250,250)", this.emSwimlaneBackgroundStroke = this.emSwimlaneBackgroundStroke || "rgb(240,240,240)", this.emArrowhead = this.emArrowhead || this.lineColor, this.emRelationStroke = this.emRelationStroke || this.lineColor, this.attributeBackgroundColorOdd = this.attributeBackgroundColorOdd || ve, this.attributeBackgroundColorEven = this.attributeBackgroundColorEven || Le;
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
}, Ny = /* @__PURE__ */ p((e) => {
  const t = new Py();
  return t.calculate(e), t;
}, "getThemeVariables"), qy = class {
  static {
    p(this, "Theme");
  }
  constructor() {
    this.background = "#ffffff", this.primaryColor = "#cccccc", this.mainBkg = "#ffffff", this.noteBkgColor = "#fff5ad", this.noteTextColor = "#333", this.THEME_COLOR_LIMIT = 12, this.radius = 3, this.strokeWidth = 2, this.primaryBorderColor = st(this.primaryColor, this.darkMode), this.fontFamily = "arial, sans-serif", this.fontSize = "14px", this.nodeBorder = "#000000", this.stateBorder = "#000000", this.useGradient = !0, this.gradientStart = "#0042eb", this.gradientStop = "#eb0042", this.dropShadow = "drop-shadow( 0px 1px 2px rgba(0, 0, 0, 0.25));", this.tertiaryColor = "#ffffff", this.archEdgeColor = "calculated", this.archEdgeArrowColor = "calculated", this.archEdgeWidth = "3", this.archGroupBorderColor = this.primaryBorderColor, this.archGroupBorderWidth = "2px", this.noteFontWeight = "normal", this.fontWeight = "normal";
  }
  updateColors() {
    this.primaryTextColor = this.primaryTextColor || (this.darkMode ? "#eee" : "#333"), this.secondaryColor = this.secondaryColor || x(this.primaryColor, { h: -120 }), this.tertiaryColor = this.tertiaryColor || x(this.primaryColor, { h: 180, l: 5 }), this.primaryBorderColor = this.primaryBorderColor || st(this.primaryColor, this.darkMode), this.secondaryBorderColor = this.secondaryBorderColor || st(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = this.tertiaryBorderColor || st(this.tertiaryColor, this.darkMode), this.noteBorderColor = this.noteBorderColor || st(this.noteBkgColor, this.darkMode), this.noteBkgColor = this.noteBkgColor || "#fff5ad", this.noteTextColor = this.noteTextColor || "#333", this.secondaryTextColor = this.secondaryTextColor || B(this.secondaryColor), this.tertiaryTextColor = this.tertiaryTextColor || B(this.tertiaryColor), this.lineColor = this.lineColor || B(this.background), this.arrowheadColor = this.arrowheadColor || B(this.background), this.textColor = this.textColor || this.primaryTextColor, this.border2 = this.border2 || this.tertiaryBorderColor, this.nodeBkg = this.nodeBkg || this.primaryColor, this.mainBkg = this.mainBkg || this.primaryColor, this.nodeBorder = this.nodeBorder || this.primaryBorderColor, this.clusterBkg = this.clusterBkg || this.tertiaryColor, this.clusterBorder = this.clusterBorder || this.tertiaryBorderColor, this.defaultLinkColor = this.defaultLinkColor || this.lineColor, this.titleColor = this.titleColor || this.tertiaryTextColor, this.edgeLabelBackground = this.edgeLabelBackground || (this.darkMode ? O(this.secondaryColor, 30) : this.secondaryColor), this.nodeTextColor = this.nodeTextColor || this.primaryTextColor, this.actorBorder = this.actorBorder || this.primaryBorderColor, this.actorBkg = this.actorBkg || this.mainBkg, this.actorTextColor = this.actorTextColor || this.primaryTextColor, this.actorLineColor = this.actorLineColor || this.actorBorder, this.labelBoxBkgColor = this.labelBoxBkgColor || this.actorBkg, this.signalColor = this.signalColor || this.textColor, this.signalTextColor = this.signalTextColor || this.textColor, this.labelBoxBorderColor = this.labelBoxBorderColor || this.actorBorder, this.labelTextColor = this.labelTextColor || this.actorTextColor, this.loopTextColor = this.loopTextColor || this.actorTextColor, this.activationBorderColor = this.activationBorderColor || O(this.secondaryColor, 10), this.activationBkgColor = this.activationBkgColor || this.secondaryColor, this.sequenceNumberColor = this.sequenceNumberColor || B(this.lineColor);
    const e = "#ECECFE", t = "#E9E9F1", r = x(e, { h: 180, l: 5 });
    if (this.sectionBkgColor = this.sectionBkgColor || r, this.altSectionBkgColor = this.altSectionBkgColor || "white", this.sectionBkgColor = this.sectionBkgColor || t, this.sectionBkgColor2 = this.sectionBkgColor2 || e, this.excludeBkgColor = this.excludeBkgColor || "#eeeeee", this.taskBorderColor = this.taskBorderColor || this.primaryBorderColor, this.taskBkgColor = this.taskBkgColor || e, this.activeTaskBorderColor = this.activeTaskBorderColor || e, this.activeTaskBkgColor = this.activeTaskBkgColor || $(e, 23), this.gridColor = this.gridColor || "lightgrey", this.doneTaskBkgColor = this.doneTaskBkgColor || "lightgrey", this.doneTaskBorderColor = this.doneTaskBorderColor || "grey", this.critBorderColor = this.critBorderColor || "#ff8888", this.critBkgColor = this.critBkgColor || "red", this.todayLineColor = this.todayLineColor || "red", this.taskTextColor = this.taskTextColor || this.textColor, this.taskTextOutsideColor = this.taskTextOutsideColor || this.textColor, this.vertLineColor = this.vertLineColor || this.primaryBorderColor, this.taskTextLightColor = this.taskTextLightColor || this.textColor, this.taskTextColor = this.taskTextColor || this.primaryTextColor, this.taskTextDarkColor = this.taskTextDarkColor || this.textColor, this.taskTextClickableColor = this.taskTextClickableColor || "#003163", this.archEdgeColor = this.lineColor, this.archEdgeArrowColor = this.lineColor, this.personBorder = this.personBorder || this.primaryBorderColor, this.personBkg = this.personBkg || this.mainBkg, this.transitionColor = this.transitionColor || this.lineColor, this.transitionLabelColor = this.transitionLabelColor || this.textColor, this.stateLabelColor = this.stateLabelColor || this.stateBkg || this.primaryTextColor, this.stateBkg = this.stateBkg || this.mainBkg, this.labelBackgroundColor = this.labelBackgroundColor || this.stateBkg, this.compositeBackground = this.compositeBackground || this.background || this.tertiaryColor, this.altBackground = this.altBackground || "#f0f0f0", this.compositeTitleBackground = this.compositeTitleBackground || this.mainBkg, this.compositeBorder = this.compositeBorder || this.nodeBorder, this.innerEndBackground = this.nodeBorder, this.errorBkgColor = this.errorBkgColor || this.tertiaryColor, this.errorTextColor = this.errorTextColor || this.tertiaryTextColor, this.transitionColor = this.transitionColor || this.lineColor, this.specialStateColor = this.lineColor, this.cScale0 = this.cScale0 || e, this.cScale1 = this.cScale1 || t, this.cScale2 = this.cScale2 || r, this.cScale3 = this.cScale3 || x(e, { h: 30 }), this.cScale4 = this.cScale4 || x(e, { h: 60 }), this.cScale5 = this.cScale5 || x(e, { h: 90 }), this.cScale6 = this.cScale6 || x(e, { h: 120 }), this.cScale7 = this.cScale7 || x(e, { h: 150 }), this.cScale8 = this.cScale8 || x(e, { h: 210, l: 150 }), this.cScale9 = this.cScale9 || x(e, { h: 270 }), this.cScale10 = this.cScale10 || x(e, { h: 300 }), this.cScale11 = this.cScale11 || x(e, { h: 330 }), this.darkMode)
      for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
        this["cScale" + s] = O(this["cScale" + s], 75);
    else
      for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
        this["cScale" + s] = O(this["cScale" + s], 25);
    for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
      this["cScaleInv" + s] = this["cScaleInv" + s] || B(this["cScale" + s]);
    for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
      this.darkMode ? this["cScalePeer" + s] = this["cScalePeer" + s] || $(this["cScale" + s], 10) : this["cScalePeer" + s] = this["cScalePeer" + s] || O(this["cScale" + s], 10);
    this.scaleLabelColor = this.scaleLabelColor || this.labelTextColor;
    for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
      this["cScaleLabel" + s] = this["cScaleLabel" + s] || this.scaleLabelColor;
    const i = this.darkMode ? -4 : -1;
    for (let s = 0; s < 5; s++)
      this["surface" + s] = this["surface" + s] || x(this.mainBkg, { h: 180, s: -15, l: i * (5 + s * 3) }), this["surfacePeer" + s] = this["surfacePeer" + s] || x(this.mainBkg, { h: 180, s: -15, l: i * (8 + s * 3) });
    this.classText = this.classText || this.textColor, this.fillType0 = this.fillType0 || e, this.fillType1 = this.fillType1 || t, this.fillType2 = this.fillType2 || x(e, { h: 64 }), this.fillType3 = this.fillType3 || x(t, { h: 64 }), this.fillType4 = this.fillType4 || x(e, { h: -64 }), this.fillType5 = this.fillType5 || x(t, { h: -64 }), this.fillType6 = this.fillType6 || x(e, { h: 128 }), this.fillType7 = this.fillType7 || x(t, { h: 128 }), this.pie1 = this.pie1 || e, this.pie2 = this.pie2 || t, this.pie3 = this.pie3 || r, this.pie4 = this.pie4 || x(e, { l: -10 }), this.pie5 = this.pie5 || x(t, { l: -10 }), this.pie6 = this.pie6 || x(r, { l: -10 }), this.pie7 = this.pie7 || x(e, { h: 60, l: -10 }), this.pie8 = this.pie8 || x(e, { h: -60, l: -10 }), this.pie9 = this.pie9 || x(e, { h: 120, l: 0 }), this.pie10 = this.pie10 || x(e, { h: 60, l: -20 }), this.pie11 = this.pie11 || x(e, { h: -60, l: -20 }), this.pie12 = this.pie12 || x(e, { h: 120, l: -10 }), this.pieTitleTextSize = this.pieTitleTextSize || "25px", this.pieTitleTextColor = this.pieTitleTextColor || this.taskTextDarkColor, this.pieSectionTextSize = this.pieSectionTextSize || "17px", this.pieSectionTextColor = this.pieSectionTextColor || this.textColor, this.pieLegendTextSize = this.pieLegendTextSize || "17px", this.pieLegendTextColor = this.pieLegendTextColor || this.taskTextDarkColor, this.pieStrokeColor = this.pieStrokeColor || "black", this.pieStrokeWidth = this.pieStrokeWidth || "2px", this.pieOuterStrokeWidth = this.pieOuterStrokeWidth || "2px", this.pieOuterStrokeColor = this.pieOuterStrokeColor || "black", this.pieOpacity = this.pieOpacity || "0.7", this.vennTitleTextColor = this.vennTitleTextColor ?? this.titleColor, this.vennSetTextColor = this.vennSetTextColor ?? this.textColor, this.quadrant1Fill = this.quadrant1Fill || e, this.quadrant2Fill = this.quadrant2Fill || x(e, { r: 5, g: 5, b: 5 }), this.quadrant3Fill = this.quadrant3Fill || x(e, { r: 10, g: 10, b: 10 }), this.quadrant4Fill = this.quadrant4Fill || x(e, { r: 15, g: 15, b: 15 }), this.quadrant1TextFill = this.quadrant1TextFill || this.primaryTextColor, this.quadrant2TextFill = this.quadrant2TextFill || x(this.primaryTextColor, { r: -5, g: -5, b: -5 }), this.quadrant3TextFill = this.quadrant3TextFill || x(this.primaryTextColor, { r: -10, g: -10, b: -10 }), this.quadrant4TextFill = this.quadrant4TextFill || x(this.primaryTextColor, { r: -15, g: -15, b: -15 }), this.quadrantPointFill = this.quadrantPointFill || ye(this.quadrant1Fill) ? $(this.quadrant1Fill) : O(this.quadrant1Fill), this.quadrantPointTextFill = this.quadrantPointTextFill || this.primaryTextColor, this.quadrantXAxisTextFill = this.quadrantXAxisTextFill || this.primaryTextColor, this.quadrantYAxisTextFill = this.quadrantYAxisTextFill || this.primaryTextColor, this.quadrantInternalBorderStrokeFill = this.quadrantInternalBorderStrokeFill || this.primaryBorderColor, this.quadrantExternalBorderStrokeFill = this.quadrantExternalBorderStrokeFill || this.primaryBorderColor, this.quadrantTitleFill = this.quadrantTitleFill || this.primaryTextColor, this.xyChart = {
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
    }, this.requirementBackground = this.requirementBackground || e, this.requirementBorderColor = this.requirementBorderColor || this.primaryBorderColor, this.requirementBorderSize = this.requirementBorderSize || "1", this.requirementTextColor = this.requirementTextColor || this.primaryTextColor, this.relationColor = this.relationColor || this.lineColor, this.relationLabelBackground = this.relationLabelBackground || (this.darkMode ? O(this.secondaryColor, 30) : this.secondaryColor), this.relationLabelColor = this.relationLabelColor || this.actorTextColor, this.git0 = this.git0 || e, this.git1 = this.git1 || t, this.git2 = this.git2 || r, this.git3 = this.git3 || x(e, { h: -30 }), this.git4 = this.git4 || x(e, { h: -60 }), this.git5 = this.git5 || x(e, { h: -90 }), this.git6 = this.git6 || x(e, { h: 60 }), this.git7 = this.git7 || x(e, { h: 120 }), this.darkMode ? (this.git0 = $(this.git0, 25), this.git1 = $(this.git1, 25), this.git2 = $(this.git2, 25), this.git3 = $(this.git3, 25), this.git4 = $(this.git4, 25), this.git5 = $(this.git5, 25), this.git6 = $(this.git6, 25), this.git7 = $(this.git7, 25)) : (this.git0 = O(this.git0, 25), this.git1 = O(this.git1, 25), this.git2 = O(this.git2, 25), this.git3 = O(this.git3, 25), this.git4 = O(this.git4, 25), this.git5 = O(this.git5, 25), this.git6 = O(this.git6, 25), this.git7 = O(this.git7, 25)), this.gitInv0 = this.gitInv0 || B(this.git0), this.gitInv1 = this.gitInv1 || B(this.git1), this.gitInv2 = this.gitInv2 || B(this.git2), this.gitInv3 = this.gitInv3 || B(this.git3), this.gitInv4 = this.gitInv4 || B(this.git4), this.gitInv5 = this.gitInv5 || B(this.git5), this.gitInv6 = this.gitInv6 || B(this.git6), this.gitInv7 = this.gitInv7 || B(this.git7), this.branchLabelColor = this.branchLabelColor || (this.darkMode ? "black" : this.labelTextColor), this.gitBranchLabel0 = this.gitBranchLabel0 || this.branchLabelColor, this.gitBranchLabel1 = this.gitBranchLabel1 || this.branchLabelColor, this.gitBranchLabel2 = this.gitBranchLabel2 || this.branchLabelColor, this.gitBranchLabel3 = this.gitBranchLabel3 || this.branchLabelColor, this.gitBranchLabel4 = this.gitBranchLabel4 || this.branchLabelColor, this.gitBranchLabel5 = this.gitBranchLabel5 || this.branchLabelColor, this.gitBranchLabel6 = this.gitBranchLabel6 || this.branchLabelColor, this.gitBranchLabel7 = this.gitBranchLabel7 || this.branchLabelColor, this.tagLabelColor = this.tagLabelColor || this.primaryTextColor, this.tagLabelBackground = this.tagLabelBackground || this.primaryColor, this.tagLabelBorder = this.tagBorder || this.primaryBorderColor, this.tagLabelFontSize = this.tagLabelFontSize || "10px", this.commitLabelColor = this.commitLabelColor || this.secondaryTextColor, this.commitLabelBackground = this.commitLabelBackground || this.secondaryColor, this.commitLabelFontSize = this.commitLabelFontSize || "10px", this.attributeBackgroundColorOdd = this.attributeBackgroundColorOdd || ve, this.attributeBackgroundColorEven = this.attributeBackgroundColorEven || Le;
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
}, Wy = /* @__PURE__ */ p((e) => {
  const t = new qy();
  return t.calculate(e), t;
}, "getThemeVariables"), zy = class {
  static {
    p(this, "Theme");
  }
  constructor() {
    this.background = "#333", this.primaryColor = "#1f2020", this.secondaryColor = $(this.primaryColor, 16), this.tertiaryColor = x(this.primaryColor, { h: -160 }), this.primaryBorderColor = B(this.background), this.secondaryBorderColor = st(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = st(this.tertiaryColor, this.darkMode), this.primaryTextColor = B(this.primaryColor), this.secondaryTextColor = B(this.secondaryColor), this.tertiaryTextColor = B(this.tertiaryColor), this.mainBkg = "#2a2020", this.secondBkg = "calculated", this.mainContrastColor = "lightgrey", this.darkTextColor = $(B("#323D47"), 10), this.border1 = "#ccc", this.border2 = Ke(255, 255, 255, 0.25), this.arrowheadColor = B(this.background), this.fontFamily = "arial, sans-serif", this.fontSize = "14px", this.labelBackground = "#181818", this.textColor = "#ccc", this.THEME_COLOR_LIMIT = 12, this.radius = 3, this.strokeWidth = 1, this.noteBkgColor = "#fff5ad", this.noteTextColor = "#333", this.THEME_COLOR_LIMIT = 12, this.fontFamily = "arial, sans-serif", this.fontSize = "14px", this.useGradient = !0, this.gradientStart = "#0042eb", this.gradientStop = "#eb0042", this.dropShadow = "drop-shadow( 1px 2px 2px rgba(185,185,185,0.2))", this.archEdgeColor = "calculated", this.archEdgeArrowColor = "calculated", this.archEdgeWidth = "3", this.archGroupBorderColor = this.primaryBorderColor, this.archGroupBorderWidth = "2px", this.noteFontWeight = "normal", this.fontWeight = "normal";
  }
  updateColors() {
    if (this.primaryTextColor = this.primaryTextColor || (this.darkMode ? "#eee" : "#333"), this.secondaryColor = this.secondaryColor || x(this.primaryColor, { h: -120 }), this.tertiaryColor = this.tertiaryColor || x(this.primaryColor, { h: 180, l: 5 }), this.primaryBorderColor = this.primaryBorderColor || st(this.primaryColor, this.darkMode), this.secondaryBorderColor = this.secondaryBorderColor || st(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = this.tertiaryBorderColor || st(this.tertiaryColor, this.darkMode), this.noteBorderColor = this.noteBorderColor || st(this.noteBkgColor, this.darkMode), this.noteBkgColor = this.noteBkgColor || "#fff5ad", this.noteTextColor = this.noteTextColor || "#333", this.secondaryTextColor = this.secondaryTextColor || B(this.secondaryColor), this.tertiaryTextColor = this.tertiaryTextColor || B(this.tertiaryColor), this.lineColor = this.lineColor || B(this.background), this.arrowheadColor = this.arrowheadColor || B(this.background), this.textColor = this.textColor || this.primaryTextColor, this.border2 = this.border2 || this.tertiaryBorderColor, this.nodeBkg = this.nodeBkg || this.primaryColor, this.mainBkg = this.mainBkg || this.primaryColor, this.nodeBorder = this.nodeBorder || this.border1, this.clusterBkg = this.clusterBkg || this.tertiaryColor, this.clusterBorder = this.clusterBorder || this.tertiaryBorderColor, this.defaultLinkColor = this.defaultLinkColor || this.lineColor, this.titleColor = this.titleColor || this.tertiaryTextColor, this.edgeLabelBackground = this.edgeLabelBackground || (this.darkMode ? O(this.secondaryColor, 30) : this.secondaryColor), this.nodeTextColor = this.nodeTextColor || this.primaryTextColor, this.actorBorder = this.actorBorder || this.primaryBorderColor, this.actorBkg = this.actorBkg || this.mainBkg, this.actorTextColor = this.actorTextColor || this.primaryTextColor, this.actorLineColor = this.actorLineColor || this.actorBorder, this.labelBoxBkgColor = this.labelBoxBkgColor || this.actorBkg, this.signalColor = this.signalColor || this.textColor, this.signalTextColor = this.signalTextColor || this.textColor, this.labelBoxBorderColor = this.labelBoxBorderColor || this.actorBorder, this.labelTextColor = this.labelTextColor || this.actorTextColor, this.loopTextColor = this.loopTextColor || this.actorTextColor, this.activationBorderColor = this.activationBorderColor || O(this.secondaryColor, 10), this.activationBkgColor = this.activationBkgColor || this.secondaryColor, this.sequenceNumberColor = this.sequenceNumberColor || B(this.lineColor), this.sectionBkgColor = this.sectionBkgColor || this.tertiaryColor, this.altSectionBkgColor = this.altSectionBkgColor || "white", this.sectionBkgColor = this.sectionBkgColor || this.secondaryColor, this.sectionBkgColor2 = this.sectionBkgColor2 || this.primaryColor, this.excludeBkgColor = this.excludeBkgColor || "#eeeeee", this.taskBorderColor = this.taskBorderColor || this.primaryBorderColor, this.taskBkgColor = this.taskBkgColor || this.primaryColor, this.activeTaskBorderColor = this.activeTaskBorderColor || this.primaryColor, this.activeTaskBkgColor = this.activeTaskBkgColor || $(this.primaryColor, 23), this.gridColor = this.gridColor || "lightgrey", this.doneTaskBkgColor = this.doneTaskBkgColor || "lightgrey", this.doneTaskBorderColor = this.doneTaskBorderColor || "grey", this.critBorderColor = this.critBorderColor || "#ff8888", this.critBkgColor = this.critBkgColor || "red", this.todayLineColor = this.todayLineColor || "red", this.vertLineColor = this.vertLineColor || this.primaryBorderColor, this.taskTextColor = this.taskTextColor || this.textColor, this.taskTextOutsideColor = this.taskTextOutsideColor || this.textColor, this.taskTextLightColor = this.taskTextLightColor || this.textColor, this.taskTextColor = this.taskTextColor || this.primaryTextColor, this.taskTextDarkColor = this.taskTextDarkColor || this.textColor, this.taskTextClickableColor = this.taskTextClickableColor || "#003163", this.archEdgeColor = this.lineColor, this.archEdgeArrowColor = this.lineColor, this.personBorder = this.personBorder || this.primaryBorderColor, this.personBkg = this.personBkg || this.mainBkg, this.transitionColor = this.transitionColor || this.lineColor, this.transitionLabelColor = this.transitionLabelColor || this.textColor, this.stateLabelColor = this.stateLabelColor || this.stateBkg || this.primaryTextColor, this.stateBkg = this.stateBkg || this.mainBkg, this.labelBackgroundColor = this.labelBackgroundColor || this.stateBkg, this.compositeBackground = this.compositeBackground || this.background || this.tertiaryColor, this.altBackground = this.altBackground || "#f0f0f0", this.compositeTitleBackground = this.compositeTitleBackground || this.mainBkg, this.compositeBorder = this.compositeBorder || this.nodeBorder, this.innerEndBackground = this.nodeBorder, this.errorBkgColor = this.errorBkgColor || this.tertiaryColor, this.errorTextColor = this.errorTextColor || this.tertiaryTextColor, this.transitionColor = this.transitionColor || this.lineColor, this.specialStateColor = this.lineColor, this.cScale0 = this.cScale0 || this.primaryColor, this.cScale1 = this.cScale1 || this.secondaryColor, this.cScale2 = this.cScale2 || this.tertiaryColor, this.cScale3 = this.cScale3 || x(this.primaryColor, { h: 30 }), this.cScale4 = this.cScale4 || x(this.primaryColor, { h: 60 }), this.cScale5 = this.cScale5 || x(this.primaryColor, { h: 90 }), this.cScale6 = this.cScale6 || x(this.primaryColor, { h: 120 }), this.cScale7 = this.cScale7 || x(this.primaryColor, { h: 150 }), this.cScale8 = this.cScale8 || x(this.primaryColor, { h: 210, l: 150 }), this.cScale9 = this.cScale9 || x(this.primaryColor, { h: 270 }), this.cScale10 = this.cScale10 || x(this.primaryColor, { h: 300 }), this.cScale11 = this.cScale11 || x(this.primaryColor, { h: 330 }), this.darkMode)
      for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
        this["cScale" + t] = O(this["cScale" + t], 75);
    else
      for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
        this["cScale" + t] = O(this["cScale" + t], 25);
    for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
      this["cScaleInv" + t] = this["cScaleInv" + t] || B(this["cScale" + t]);
    for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
      this.darkMode ? this["cScalePeer" + t] = this["cScalePeer" + t] || $(this["cScale" + t], 10) : this["cScalePeer" + t] = this["cScalePeer" + t] || O(this["cScale" + t], 10);
    this.scaleLabelColor = this.scaleLabelColor || this.labelTextColor;
    for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
      this["cScaleLabel" + t] = this["cScaleLabel" + t] || this.scaleLabelColor;
    const e = this.darkMode ? -4 : -1;
    for (let t = 0; t < 5; t++)
      this["surface" + t] = this["surface" + t] || x(this.mainBkg, { h: 180, s: -15, l: e * (5 + t * 3) }), this["surfacePeer" + t] = this["surfacePeer" + t] || x(this.mainBkg, { h: 180, s: -15, l: e * (8 + t * 3) });
    this.classText = this.classText || this.textColor, this.fillType0 = this.fillType0 || this.primaryColor, this.fillType1 = this.fillType1 || this.secondaryColor, this.fillType2 = this.fillType2 || x(this.primaryColor, { h: 64 }), this.fillType3 = this.fillType3 || x(this.secondaryColor, { h: 64 }), this.fillType4 = this.fillType4 || x(this.primaryColor, { h: -64 }), this.fillType5 = this.fillType5 || x(this.secondaryColor, { h: -64 }), this.fillType6 = this.fillType6 || x(this.primaryColor, { h: 128 }), this.fillType7 = this.fillType7 || x(this.secondaryColor, { h: 128 }), this.pie1 = this.pie1 || this.primaryColor, this.pie2 = this.pie2 || this.secondaryColor, this.pie3 = this.pie3 || this.tertiaryColor, this.pie4 = this.pie4 || x(this.primaryColor, { l: -10 }), this.pie5 = this.pie5 || x(this.secondaryColor, { l: -10 }), this.pie6 = this.pie6 || x(this.tertiaryColor, { l: -10 }), this.pie7 = this.pie7 || x(this.primaryColor, { h: 60, l: -10 }), this.pie8 = this.pie8 || x(this.primaryColor, { h: -60, l: -10 }), this.pie9 = this.pie9 || x(this.primaryColor, { h: 120, l: 0 }), this.pie10 = this.pie10 || x(this.primaryColor, { h: 60, l: -20 }), this.pie11 = this.pie11 || x(this.primaryColor, { h: -60, l: -20 }), this.pie12 = this.pie12 || x(this.primaryColor, { h: 120, l: -10 }), this.pieTitleTextSize = this.pieTitleTextSize || "25px", this.pieTitleTextColor = this.pieTitleTextColor || this.taskTextDarkColor, this.pieSectionTextSize = this.pieSectionTextSize || "17px", this.pieSectionTextColor = this.pieSectionTextColor || this.textColor, this.pieLegendTextSize = this.pieLegendTextSize || "17px", this.pieLegendTextColor = this.pieLegendTextColor || this.taskTextDarkColor, this.pieStrokeColor = this.pieStrokeColor || "black", this.pieStrokeWidth = this.pieStrokeWidth || "2px", this.pieOuterStrokeWidth = this.pieOuterStrokeWidth || "2px", this.pieOuterStrokeColor = this.pieOuterStrokeColor || "black", this.pieOpacity = this.pieOpacity || "0.7", this.vennTitleTextColor = this.vennTitleTextColor ?? this.titleColor, this.vennSetTextColor = this.vennSetTextColor ?? this.textColor, this.quadrant1Fill = this.quadrant1Fill || this.primaryColor, this.quadrant2Fill = this.quadrant2Fill || x(this.primaryColor, { r: 5, g: 5, b: 5 }), this.quadrant3Fill = this.quadrant3Fill || x(this.primaryColor, { r: 10, g: 10, b: 10 }), this.quadrant4Fill = this.quadrant4Fill || x(this.primaryColor, { r: 15, g: 15, b: 15 }), this.quadrant1TextFill = this.quadrant1TextFill || this.primaryTextColor, this.quadrant2TextFill = this.quadrant2TextFill || x(this.primaryTextColor, { r: -5, g: -5, b: -5 }), this.quadrant3TextFill = this.quadrant3TextFill || x(this.primaryTextColor, { r: -10, g: -10, b: -10 }), this.quadrant4TextFill = this.quadrant4TextFill || x(this.primaryTextColor, { r: -15, g: -15, b: -15 }), this.quadrantPointFill = this.quadrantPointFill || ye(this.quadrant1Fill) ? $(this.quadrant1Fill) : O(this.quadrant1Fill), this.quadrantPointTextFill = this.quadrantPointTextFill || this.primaryTextColor, this.quadrantXAxisTextFill = this.quadrantXAxisTextFill || this.primaryTextColor, this.quadrantYAxisTextFill = this.quadrantYAxisTextFill || this.primaryTextColor, this.quadrantInternalBorderStrokeFill = this.quadrantInternalBorderStrokeFill || this.primaryBorderColor, this.quadrantExternalBorderStrokeFill = this.quadrantExternalBorderStrokeFill || this.primaryBorderColor, this.quadrantTitleFill = this.quadrantTitleFill || this.primaryTextColor, this.xyChart = {
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
    }, this.requirementBackground = this.requirementBackground || this.primaryColor, this.requirementBorderColor = this.requirementBorderColor || this.primaryBorderColor, this.requirementBorderSize = this.requirementBorderSize || "1", this.requirementTextColor = this.requirementTextColor || this.primaryTextColor, this.relationColor = this.relationColor || this.lineColor, this.relationLabelBackground = this.relationLabelBackground || (this.darkMode ? O(this.secondaryColor, 30) : this.secondaryColor), this.relationLabelColor = this.relationLabelColor || this.actorTextColor, this.git0 = this.git0 || "#0b0000", this.git1 = this.git1 || "#4d1037", this.git2 = this.git2 || "#3f5258", this.git3 = this.git3 || "#4f2f1b", this.git4 = this.git4 || "#6e0a0a", this.git5 = this.git5 || "#3b0048", this.git6 = this.git6 || "#995a01", this.git7 = this.git7 || "#154706", this.gitDarkMode = !0, this.gitDarkMode ? (this.git0 = $(this.git0, 25), this.git1 = $(this.git1, 25), this.git2 = $(this.git2, 25), this.git3 = $(this.git3, 25), this.git4 = $(this.git4, 25), this.git5 = $(this.git5, 25), this.git6 = $(this.git6, 25), this.git7 = $(this.git7, 25)) : (this.git0 = O(this.git0, 25), this.git1 = O(this.git1, 25), this.git2 = O(this.git2, 25), this.git3 = O(this.git3, 25), this.git4 = O(this.git4, 25), this.git5 = O(this.git5, 25), this.git6 = O(this.git6, 25), this.git7 = O(this.git7, 25)), this.gitInv0 = this.gitInv0 || B(this.git0), this.gitInv1 = this.gitInv1 || B(this.git1), this.gitInv2 = this.gitInv2 || B(this.git2), this.gitInv3 = this.gitInv3 || B(this.git3), this.gitInv4 = this.gitInv4 || B(this.git4), this.gitInv5 = this.gitInv5 || B(this.git5), this.gitInv6 = this.gitInv6 || B(this.git6), this.gitInv7 = this.gitInv7 || B(this.git7), this.branchLabelColor = this.branchLabelColor || (this.darkMode ? "black" : this.labelTextColor), this.gitBranchLabel0 = this.gitBranchLabel0 || this.branchLabelColor, this.gitBranchLabel1 = this.gitBranchLabel1 || this.branchLabelColor, this.gitBranchLabel2 = this.gitBranchLabel2 || this.branchLabelColor, this.gitBranchLabel3 = this.gitBranchLabel3 || this.branchLabelColor, this.gitBranchLabel4 = this.gitBranchLabel4 || this.branchLabelColor, this.gitBranchLabel5 = this.gitBranchLabel5 || this.branchLabelColor, this.gitBranchLabel6 = this.gitBranchLabel6 || this.branchLabelColor, this.gitBranchLabel7 = this.gitBranchLabel7 || this.branchLabelColor, this.tagLabelColor = this.tagLabelColor || this.primaryTextColor, this.tagLabelBackground = this.tagLabelBackground || this.primaryColor, this.tagLabelBorder = this.tagBorder || this.primaryBorderColor, this.tagLabelFontSize = this.tagLabelFontSize || "10px", this.commitLabelColor = this.commitLabelColor || this.secondaryTextColor, this.commitLabelBackground = this.commitLabelBackground || this.secondaryColor, this.commitLabelFontSize = this.commitLabelFontSize || "10px", this.attributeBackgroundColorOdd = this.attributeBackgroundColorOdd || ve, this.attributeBackgroundColorEven = this.attributeBackgroundColorEven || Le;
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
}, Hy = /* @__PURE__ */ p((e) => {
  const t = new zy();
  return t.calculate(e), t;
}, "getThemeVariables"), Yy = class {
  static {
    p(this, "Theme");
  }
  constructor() {
    this.background = "#ffffff", this.primaryColor = "#cccccc", this.mainBkg = "#ffffff", this.noteBkgColor = "#fff5ad", this.noteTextColor = "#28253D", this.THEME_COLOR_LIMIT = 12, this.radius = 12, this.strokeWidth = 2, this.primaryBorderColor = st("#28253D", this.darkMode), this.fontFamily = '"Recursive Variable", arial, sans-serif', this.fontSize = "14px", this.nodeBorder = "#28253D", this.stateBorder = "#28253D", this.useGradient = !1, this.gradientStart = "#0042eb", this.gradientStop = "#eb0042", this.dropShadow = "url(#drop-shadow)", this.nodeShadow = !0, this.tertiaryColor = "#ffffff", this.clusterBkg = "#F9F9FB", this.clusterBorder = "#BDBCCC", this.noteBorderColor = "#FACC15", this.archEdgeColor = "calculated", this.archEdgeArrowColor = "calculated", this.archEdgeWidth = "3", this.archGroupBorderColor = this.primaryBorderColor, this.archGroupBorderWidth = "2px", this.actorBorder = "#28253D", this.filterColor = "#000000";
  }
  updateColors() {
    this.primaryTextColor = this.primaryTextColor || (this.darkMode ? "#eee" : "#28253D"), this.secondaryColor = this.secondaryColor || x(this.primaryColor, { h: -120 }), this.tertiaryColor = this.tertiaryColor || x(this.primaryColor, { h: 180, l: 5 }), this.primaryBorderColor = this.primaryBorderColor || st(this.primaryColor, this.darkMode), this.secondaryBorderColor = this.secondaryBorderColor || st(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = this.tertiaryBorderColor || st(this.tertiaryColor, this.darkMode), this.noteBorderColor = this.noteBorderColor || st(this.noteBkgColor, this.darkMode), this.noteBkgColor = this.noteBkgColor || "#FEF9C3", this.noteTextColor = this.noteTextColor || "#28253D", this.secondaryTextColor = this.secondaryTextColor || B(this.secondaryColor), this.tertiaryTextColor = this.tertiaryTextColor || B(this.tertiaryColor), this.lineColor = this.lineColor || B(this.background), this.arrowheadColor = this.arrowheadColor || B(this.background), this.textColor = this.textColor || this.primaryTextColor, this.border2 = this.border2 || this.tertiaryBorderColor, this.nodeBkg = this.nodeBkg || this.primaryColor, this.mainBkg = this.mainBkg || this.primaryColor, this.nodeBorder = this.nodeBorder || this.primaryBorderColor, this.clusterBkg = this.clusterBkg || this.tertiaryColor, this.clusterBorder = this.clusterBorder || this.tertiaryBorderColor, this.defaultLinkColor = this.defaultLinkColor || this.lineColor, this.titleColor = this.titleColor || this.tertiaryTextColor, this.edgeLabelBackground = this.edgeLabelBackground || (this.darkMode ? O(this.secondaryColor, 30) : this.secondaryColor), this.nodeTextColor = this.nodeTextColor || this.primaryTextColor, this.noteFontWeight = 600, this.actorBorder = this.actorBorder || this.primaryBorderColor, this.actorBkg = this.actorBkg || this.mainBkg, this.actorTextColor = this.actorTextColor || this.primaryTextColor, this.actorLineColor = this.actorLineColor || this.actorBorder, this.labelBoxBkgColor = this.labelBoxBkgColor || this.actorBkg, this.signalColor = this.signalColor || this.textColor, this.signalTextColor = this.signalTextColor || this.textColor, this.labelBoxBorderColor = this.labelBoxBorderColor || this.actorBorder, this.labelTextColor = this.labelTextColor || this.actorTextColor, this.loopTextColor = this.loopTextColor || this.actorTextColor, this.activationBorderColor = this.activationBorderColor || O(this.secondaryColor, 10), this.activationBkgColor = this.activationBkgColor || this.secondaryColor, this.sequenceNumberColor = this.sequenceNumberColor || B(this.lineColor);
    const e = "#ECECFE", t = "#E9E9F1", r = x(e, { h: 180, l: 5 });
    this.sectionBkgColor = this.sectionBkgColor || r, this.altSectionBkgColor = this.altSectionBkgColor || "white", this.sectionBkgColor = this.sectionBkgColor || t, this.sectionBkgColor2 = this.sectionBkgColor2 || e, this.excludeBkgColor = this.excludeBkgColor || "#eeeeee", this.taskBorderColor = this.taskBorderColor || this.primaryBorderColor, this.taskBkgColor = this.taskBkgColor || e, this.activeTaskBorderColor = this.activeTaskBorderColor || e, this.activeTaskBkgColor = this.activeTaskBkgColor || $(e, 23), this.gridColor = this.gridColor || "lightgrey", this.doneTaskBkgColor = this.doneTaskBkgColor || "lightgrey", this.doneTaskBorderColor = this.doneTaskBorderColor || "grey", this.critBorderColor = this.critBorderColor || "#ff8888", this.critBkgColor = this.critBkgColor || "red", this.todayLineColor = this.todayLineColor || "red", this.taskTextColor = this.taskTextColor || this.textColor, this.vertLineColor = this.vertLineColor || this.primaryBorderColor, this.taskTextOutsideColor = this.taskTextOutsideColor || this.textColor, this.taskTextLightColor = this.taskTextLightColor || this.textColor, this.taskTextColor = this.taskTextColor || this.primaryTextColor, this.taskTextDarkColor = this.taskTextDarkColor || this.textColor, this.taskTextClickableColor = this.taskTextClickableColor || "#003163", this.archEdgeColor = this.lineColor, this.archEdgeArrowColor = this.lineColor, this.personBorder = this.personBorder || this.primaryBorderColor, this.personBkg = this.personBkg || this.mainBkg, this.transitionColor = this.transitionColor || this.lineColor, this.transitionLabelColor = this.transitionLabelColor || this.textColor, this.stateLabelColor = this.stateLabelColor || this.stateBkg || this.primaryTextColor, this.compositeTitleBackground = "#F9F9FB", this.altBackground = "#F9F9FB", this.stateEdgeLabelBackground = "#FFFFFF", this.fontWeight = 600, this.stateBkg = this.stateBkg || this.mainBkg, this.labelBackgroundColor = this.labelBackgroundColor || this.stateBkg, this.compositeBackground = this.compositeBackground || this.background || this.tertiaryColor, this.altBackground = this.altBackground || "#f0f0f0", this.compositeTitleBackground = this.compositeTitleBackground || this.mainBkg, this.compositeBorder = this.compositeBorder || this.nodeBorder, this.innerEndBackground = this.nodeBorder, this.errorBkgColor = this.errorBkgColor || this.tertiaryColor, this.errorTextColor = this.errorTextColor || this.tertiaryTextColor, this.transitionColor = this.transitionColor || this.lineColor, this.specialStateColor = this.lineColor;
    for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
      this["cScale" + s] = this.mainBkg;
    if (this.darkMode)
      for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
        this["cScale" + s] = O(this["cScale" + s], 75);
    else
      for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
        this["cScale" + s] = O(this["cScale" + s], 25);
    for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
      this["cScaleInv" + s] = this["cScaleInv" + s] || B(this["cScale" + s]);
    for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
      this.darkMode ? this["cScalePeer" + s] = this["cScalePeer" + s] || $(this["cScale" + s], 10) : this["cScalePeer" + s] = this["cScalePeer" + s] || O(this["cScale" + s], 10);
    this.scaleLabelColor = this.scaleLabelColor || this.labelTextColor;
    for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
      this["cScaleLabel" + s] = this["cScaleLabel" + s] || this.scaleLabelColor;
    const i = this.darkMode ? -4 : -1;
    for (let s = 0; s < 5; s++)
      this["surface" + s] = this["surface" + s] || x(this.mainBkg, { h: 180, s: -15, l: i * (5 + s * 3) }), this["surfacePeer" + s] = this["surfacePeer" + s] || x(this.mainBkg, { h: 180, s: -15, l: i * (8 + s * 3) });
    this.classText = this.classText || this.textColor, this.fillType0 = this.fillType0 || e, this.fillType1 = this.fillType1 || t, this.fillType2 = this.fillType2 || x(e, { h: 64 }), this.fillType3 = this.fillType3 || x(t, { h: 64 }), this.fillType4 = this.fillType4 || x(e, { h: -64 }), this.fillType5 = this.fillType5 || x(t, { h: -64 }), this.fillType6 = this.fillType6 || x(e, { h: 128 }), this.fillType7 = this.fillType7 || x(t, { h: 128 }), this.pie1 = this.pie1 || e, this.pie2 = this.pie2 || t, this.pie3 = this.pie3 || r, this.pie4 = this.pie4 || x(e, { l: -10 }), this.pie5 = this.pie5 || x(t, { l: -10 }), this.pie6 = this.pie6 || x(r, { l: -10 }), this.pie7 = this.pie7 || x(e, { h: 60, l: -10 }), this.pie8 = this.pie8 || x(e, { h: -60, l: -10 }), this.pie9 = this.pie9 || x(e, { h: 120, l: 0 }), this.pie10 = this.pie10 || x(e, { h: 60, l: -20 }), this.pie11 = this.pie11 || x(e, { h: -60, l: -20 }), this.pie12 = this.pie12 || x(e, { h: 120, l: -10 }), this.pieTitleTextSize = this.pieTitleTextSize || "25px", this.pieTitleTextColor = this.pieTitleTextColor || this.taskTextDarkColor, this.pieSectionTextSize = this.pieSectionTextSize || "17px", this.pieSectionTextColor = this.pieSectionTextColor || this.textColor, this.pieLegendTextSize = this.pieLegendTextSize || "17px", this.pieLegendTextColor = this.pieLegendTextColor || this.taskTextDarkColor, this.pieStrokeColor = this.pieStrokeColor || "black", this.pieStrokeWidth = this.pieStrokeWidth || "2px", this.pieOuterStrokeWidth = this.pieOuterStrokeWidth || "2px", this.pieOuterStrokeColor = this.pieOuterStrokeColor || "black", this.pieOpacity = this.pieOpacity || "0.7", this.vennTitleTextColor = this.vennTitleTextColor ?? this.titleColor, this.vennSetTextColor = this.vennSetTextColor ?? this.textColor, this.quadrant1Fill = this.quadrant1Fill || e, this.quadrant2Fill = this.quadrant2Fill || x(e, { r: 5, g: 5, b: 5 }), this.quadrant3Fill = this.quadrant3Fill || x(e, { r: 10, g: 10, b: 10 }), this.quadrant4Fill = this.quadrant4Fill || x(e, { r: 15, g: 15, b: 15 }), this.quadrant1TextFill = this.quadrant1TextFill || this.primaryTextColor, this.quadrant2TextFill = this.quadrant2TextFill || x(this.primaryTextColor, { r: -5, g: -5, b: -5 }), this.quadrant3TextFill = this.quadrant3TextFill || x(this.primaryTextColor, { r: -10, g: -10, b: -10 }), this.quadrant4TextFill = this.quadrant4TextFill || x(this.primaryTextColor, { r: -15, g: -15, b: -15 }), this.quadrantPointFill = this.quadrantPointFill || ye(this.quadrant1Fill) ? $(this.quadrant1Fill) : O(this.quadrant1Fill), this.quadrantPointTextFill = this.quadrantPointTextFill || this.primaryTextColor, this.quadrantXAxisTextFill = this.quadrantXAxisTextFill || this.primaryTextColor, this.quadrantYAxisTextFill = this.quadrantYAxisTextFill || this.primaryTextColor, this.quadrantInternalBorderStrokeFill = this.quadrantInternalBorderStrokeFill || this.primaryBorderColor, this.quadrantExternalBorderStrokeFill = this.quadrantExternalBorderStrokeFill || this.primaryBorderColor, this.quadrantTitleFill = this.quadrantTitleFill || this.primaryTextColor, this.xyChart = {
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
    }, this.requirementBackground = this.requirementBackground || e, this.requirementBorderColor = this.requirementBorderColor || this.primaryBorderColor, this.requirementBorderSize = this.requirementBorderSize || "1", this.requirementTextColor = this.requirementTextColor || this.primaryTextColor, this.relationColor = this.relationColor || this.lineColor, this.relationLabelBackground = this.relationLabelBackground || (this.darkMode ? O(this.secondaryColor, 30) : this.secondaryColor), this.relationLabelColor = this.relationLabelColor || this.actorTextColor, this.requirementEdgeLabelBackground = "#FFFFFF", this.git0 = this.git0 || e, this.git1 = this.git1 || t, this.git2 = this.git2 || r, this.git3 = this.git3 || x(e, { h: -30 }), this.git4 = this.git4 || x(e, { h: -60 }), this.git5 = this.git5 || x(e, { h: -90 }), this.git6 = this.git6 || x(e, { h: 60 }), this.git7 = this.git7 || x(e, { h: 120 }), this.darkMode ? (this.git0 = $(this.git0, 25), this.git1 = $(this.git1, 25), this.git2 = $(this.git2, 25), this.git3 = $(this.git3, 25), this.git4 = $(this.git4, 25), this.git5 = $(this.git5, 25), this.git6 = $(this.git6, 25), this.git7 = $(this.git7, 25)) : (this.git0 = O(this.git0, 25), this.git1 = O(this.git1, 25), this.git2 = O(this.git2, 25), this.git3 = O(this.git3, 25), this.git4 = O(this.git4, 25), this.git5 = O(this.git5, 25), this.git6 = O(this.git6, 25), this.git7 = O(this.git7, 25)), this.gitInv0 = this.gitInv0 || B(this.git0), this.gitInv1 = this.gitInv1 || B(this.git1), this.gitInv2 = this.gitInv2 || B(this.git2), this.gitInv3 = this.gitInv3 || B(this.git3), this.gitInv4 = this.gitInv4 || B(this.git4), this.gitInv5 = this.gitInv5 || B(this.git5), this.gitInv6 = this.gitInv6 || B(this.git6), this.gitInv7 = this.gitInv7 || B(this.git7), this.branchLabelColor = this.branchLabelColor || (this.darkMode ? "black" : this.labelTextColor), this.gitBranchLabel0 = this.gitBranchLabel0 || this.branchLabelColor, this.gitBranchLabel1 = this.gitBranchLabel1 || this.branchLabelColor, this.gitBranchLabel2 = this.gitBranchLabel2 || this.branchLabelColor, this.gitBranchLabel3 = this.gitBranchLabel3 || this.branchLabelColor, this.gitBranchLabel4 = this.gitBranchLabel4 || this.branchLabelColor, this.gitBranchLabel5 = this.gitBranchLabel5 || this.branchLabelColor, this.gitBranchLabel6 = this.gitBranchLabel6 || this.branchLabelColor, this.gitBranchLabel7 = this.gitBranchLabel7 || this.branchLabelColor, this.tagLabelColor = this.tagLabelColor || this.primaryTextColor, this.tagLabelBackground = this.tagLabelBackground || this.primaryColor, this.tagLabelBorder = this.tagBorder || this.primaryBorderColor, this.tagLabelFontSize = this.tagLabelFontSize || "10px", this.commitLabelColor = this.commitLabelColor || this.secondaryTextColor, this.commitLabelBackground = this.commitLabelBackground || this.secondaryColor, this.commitLabelFontSize = this.commitLabelFontSize || "10px", this.commitLineColor = this.commitLineColor ?? "#BDBCCC", this.erEdgeLabelBackground = "#FFFFFF", this.attributeBackgroundColorOdd = this.attributeBackgroundColorOdd || ve, this.attributeBackgroundColorEven = this.attributeBackgroundColorEven || Le;
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
}, Uy = /* @__PURE__ */ p((e) => {
  const t = new Yy();
  return t.calculate(e), t;
}, "getThemeVariables"), Gy = class {
  static {
    p(this, "Theme");
  }
  constructor() {
    this.background = "#333", this.primaryColor = "#1f2020", this.secondaryColor = $(this.primaryColor, 16), this.tertiaryColor = x(this.primaryColor, { h: -160 }), this.primaryBorderColor = B(this.background), this.secondaryBorderColor = st(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = st(this.tertiaryColor, this.darkMode), this.primaryTextColor = B(this.primaryColor), this.secondaryTextColor = B(this.secondaryColor), this.tertiaryTextColor = B(this.tertiaryColor), this.mainBkg = "#111113", this.secondBkg = "calculated", this.mainContrastColor = "lightgrey", this.darkTextColor = $(B("#323D47"), 10), this.border1 = "#ccc", this.border2 = Ke(255, 255, 255, 0.25), this.arrowheadColor = B(this.background), this.fontFamily = '"Recursive Variable", arial, sans-serif', this.fontSize = "14px", this.labelBackground = "#111113", this.textColor = "#ccc", this.THEME_COLOR_LIMIT = 12, this.radius = 12, this.strokeWidth = 2, this.noteBkgColor = this.noteBkgColor ?? "#FEF9C3", this.noteTextColor = this.noteTextColor ?? "#28253D", this.THEME_COLOR_LIMIT = 12, this.fontFamily = '"Recursive Variable", arial, sans-serif', this.fontSize = "14px", this.nodeBorder = "#FFFFFF", this.stateBorder = "#FFFFFF", this.useGradient = !1, this.gradientStart = "#0042eb", this.gradientStop = "#eb0042", this.dropShadow = "url(#drop-shadow)", this.nodeShadow = !0, this.archEdgeColor = "calculated", this.archEdgeArrowColor = "calculated", this.archEdgeWidth = "3", this.archGroupBorderColor = this.primaryBorderColor, this.archGroupBorderWidth = "2px", this.clusterBkg = "#1E1A2E", this.clusterBorder = "#BDBCCC", this.noteBorderColor = "#FACC15", this.noteFontWeight = 600, this.filterColor = "#FFFFFF";
  }
  updateColors() {
    if (this.primaryTextColor = this.primaryTextColor || (this.darkMode ? "#eee" : "#FFFFFF"), this.secondaryColor = this.secondaryColor || x(this.primaryColor, { h: -120 }), this.tertiaryColor = this.tertiaryColor || x(this.primaryColor, { h: 180, l: 5 }), this.primaryBorderColor = this.primaryBorderColor || st(this.primaryColor, this.darkMode), this.secondaryBorderColor = this.secondaryBorderColor || st(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = this.tertiaryBorderColor || st(this.tertiaryColor, this.darkMode), this.noteBorderColor = this.noteBorderColor || st(this.noteBkgColor, this.darkMode), this.noteBkgColor = this.noteBkgColor || "#fff5ad", this.noteTextColor = this.noteTextColor || "#FFFFFF", this.secondaryTextColor = this.secondaryTextColor || B(this.secondaryColor), this.tertiaryTextColor = this.tertiaryTextColor || B(this.tertiaryColor), this.lineColor = this.lineColor || B(this.background), this.arrowheadColor = this.arrowheadColor || B(this.background), this.textColor = this.textColor || this.primaryTextColor, this.border2 = this.border2 || this.tertiaryBorderColor, this.nodeBkg = this.nodeBkg || this.primaryColor, this.mainBkg = this.mainBkg || this.primaryColor, this.nodeBorder = this.nodeBorder || this.border1, this.clusterBkg = this.clusterBkg || this.tertiaryColor, this.clusterBorder = this.clusterBorder || this.tertiaryBorderColor, this.defaultLinkColor = this.defaultLinkColor || this.lineColor, this.titleColor = this.titleColor || this.tertiaryTextColor, this.edgeLabelBackground = this.edgeLabelBackground || (this.darkMode ? O(this.secondaryColor, 30) : this.secondaryColor), this.nodeTextColor = this.nodeTextColor || this.primaryTextColor, this.actorBorder = "#FFFFFF", this.signalColor = "#FFFFFF", this.labelBoxBorderColor = "#BDBCCC", this.actorBorder = this.actorBorder || this.primaryBorderColor, this.actorBkg = this.actorBkg || this.mainBkg, this.actorTextColor = this.actorTextColor || this.primaryTextColor, this.actorLineColor = this.actorLineColor || this.actorBorder, this.labelBoxBkgColor = this.labelBoxBkgColor || this.actorBkg, this.signalColor = this.signalColor || this.textColor, this.signalTextColor = this.signalTextColor || this.textColor, this.labelBoxBorderColor = this.labelBoxBorderColor || this.actorBorder, this.labelTextColor = this.labelTextColor || this.actorTextColor, this.loopTextColor = this.loopTextColor || this.actorTextColor, this.activationBorderColor = this.activationBorderColor || O(this.secondaryColor, 10), this.activationBkgColor = this.activationBkgColor || this.secondaryColor, this.sequenceNumberColor = this.sequenceNumberColor || B(this.lineColor), this.sectionBkgColor = this.sectionBkgColor || this.tertiaryColor, this.altSectionBkgColor = this.altSectionBkgColor || "white", this.sectionBkgColor = this.sectionBkgColor || this.secondaryColor, this.sectionBkgColor2 = this.sectionBkgColor2 || this.primaryColor, this.excludeBkgColor = this.excludeBkgColor || "#eeeeee", this.taskBorderColor = this.taskBorderColor || this.primaryBorderColor, this.taskBkgColor = this.taskBkgColor || this.primaryColor, this.activeTaskBorderColor = this.activeTaskBorderColor || this.primaryColor, this.activeTaskBkgColor = this.activeTaskBkgColor || $(this.primaryColor, 23), this.gridColor = this.gridColor || "lightgrey", this.doneTaskBkgColor = this.doneTaskBkgColor || "lightgrey", this.doneTaskBorderColor = this.doneTaskBorderColor || "grey", this.critBorderColor = this.critBorderColor || "#ff8888", this.critBkgColor = this.critBkgColor || "red", this.todayLineColor = this.todayLineColor || "red", this.taskTextColor = this.taskTextColor || this.textColor, this.taskTextOutsideColor = this.taskTextOutsideColor || this.textColor, this.taskTextLightColor = this.taskTextLightColor || this.textColor, this.taskTextColor = this.taskTextColor || this.primaryTextColor, this.taskTextDarkColor = this.taskTextDarkColor || this.textColor, this.taskTextClickableColor = this.taskTextClickableColor || "#003163", this.archEdgeColor = this.lineColor, this.archEdgeArrowColor = this.lineColor, this.personBorder = this.personBorder || this.primaryBorderColor, this.personBkg = this.personBkg || this.mainBkg, this.transitionColor = this.transitionColor || this.lineColor, this.transitionLabelColor = this.transitionLabelColor || this.textColor, this.stateLabelColor = this.stateLabelColor || this.stateBkg || this.primaryTextColor, this.vertLineColor = this.vertLineColor || this.primaryBorderColor, this.compositeBackground = "#16141F", this.altBackground = "#16141F", this.compositeTitleBackground = "#16141F", this.stateEdgeLabelBackground = "#16141F", this.fontWeight = 600, this.stateBkg = this.stateBkg || this.mainBkg, this.labelBackgroundColor = this.labelBackgroundColor || this.stateBkg, this.compositeBackground = this.compositeBackground || this.background || this.tertiaryColor, this.altBackground = this.altBackground || "#f0f0f0", this.compositeTitleBackground = this.compositeTitleBackground || this.mainBkg, this.compositeBorder = this.compositeBorder || this.nodeBorder, this.innerEndBackground = this.nodeBorder, this.errorBkgColor = this.errorBkgColor || this.tertiaryColor, this.errorTextColor = this.errorTextColor || this.tertiaryTextColor, this.transitionColor = this.transitionColor || this.lineColor, this.specialStateColor = this.lineColor, this.cScale0 = this.cScale0 || this.primaryColor, this.cScale1 = this.cScale1 || this.secondaryColor, this.cScale2 = this.cScale2 || this.tertiaryColor, this.cScale3 = this.cScale3 || x(this.primaryColor, { h: 30 }), this.cScale4 = this.cScale4 || x(this.primaryColor, { h: 60 }), this.cScale5 = this.cScale5 || x(this.primaryColor, { h: 90 }), this.cScale6 = this.cScale6 || x(this.primaryColor, { h: 120 }), this.cScale7 = this.cScale7 || x(this.primaryColor, { h: 150 }), this.cScale8 = this.cScale8 || x(this.primaryColor, { h: 210, l: 150 }), this.cScale9 = this.cScale9 || x(this.primaryColor, { h: 270 }), this.cScale10 = this.cScale10 || x(this.primaryColor, { h: 300 }), this.cScale11 = this.cScale11 || x(this.primaryColor, { h: 330 }), this.darkMode)
      for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
        this["cScale" + t] = O(this["cScale" + t], 75);
    else
      for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
        this["cScale" + t] = O(this["cScale" + t], 25);
    for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
      this["cScaleInv" + t] = this["cScaleInv" + t] || B(this["cScale" + t]);
    for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
      this.darkMode ? this["cScalePeer" + t] = this["cScalePeer" + t] || $(this["cScale" + t], 10) : this["cScalePeer" + t] = this["cScalePeer" + t] || O(this["cScale" + t], 10);
    this.scaleLabelColor = this.scaleLabelColor || this.labelTextColor;
    for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
      this["cScaleLabel" + t] = this["cScaleLabel" + t] || this.scaleLabelColor;
    const e = this.darkMode ? -4 : -1;
    for (let t = 0; t < 5; t++)
      this["surface" + t] = this["surface" + t] || x(this.mainBkg, { h: 180, s: -15, l: e * (5 + t * 3) }), this["surfacePeer" + t] = this["surfacePeer" + t] || x(this.mainBkg, { h: 180, s: -15, l: e * (8 + t * 3) });
    this.classText = this.classText || this.textColor, this.fillType0 = this.fillType0 || this.primaryColor, this.fillType1 = this.fillType1 || this.secondaryColor, this.fillType2 = this.fillType2 || x(this.primaryColor, { h: 64 }), this.fillType3 = this.fillType3 || x(this.secondaryColor, { h: 64 }), this.fillType4 = this.fillType4 || x(this.primaryColor, { h: -64 }), this.fillType5 = this.fillType5 || x(this.secondaryColor, { h: -64 }), this.fillType6 = this.fillType6 || x(this.primaryColor, { h: 128 }), this.fillType7 = this.fillType7 || x(this.secondaryColor, { h: 128 }), this.pie1 = this.pie1 || this.primaryColor, this.pie2 = this.pie2 || this.secondaryColor, this.pie3 = this.pie3 || this.tertiaryColor, this.pie4 = this.pie4 || x(this.primaryColor, { l: -10 }), this.pie5 = this.pie5 || x(this.secondaryColor, { l: -10 }), this.pie6 = this.pie6 || x(this.tertiaryColor, { l: -10 }), this.pie7 = this.pie7 || x(this.primaryColor, { h: 60, l: -10 }), this.pie8 = this.pie8 || x(this.primaryColor, { h: -60, l: -10 }), this.pie9 = this.pie9 || x(this.primaryColor, { h: 120, l: 0 }), this.pie10 = this.pie10 || x(this.primaryColor, { h: 60, l: -20 }), this.pie11 = this.pie11 || x(this.primaryColor, { h: -60, l: -20 }), this.pie12 = this.pie12 || x(this.primaryColor, { h: 120, l: -10 }), this.pieTitleTextSize = this.pieTitleTextSize || "25px", this.pieTitleTextColor = this.pieTitleTextColor || this.taskTextDarkColor, this.pieSectionTextSize = this.pieSectionTextSize || "17px", this.pieSectionTextColor = this.pieSectionTextColor || this.textColor, this.pieLegendTextSize = this.pieLegendTextSize || "17px", this.pieLegendTextColor = this.pieLegendTextColor || this.taskTextDarkColor, this.pieStrokeColor = this.pieStrokeColor || "black", this.pieStrokeWidth = this.pieStrokeWidth || "2px", this.pieOuterStrokeWidth = this.pieOuterStrokeWidth || "2px", this.pieOuterStrokeColor = this.pieOuterStrokeColor || "black", this.pieOpacity = this.pieOpacity || "0.7", this.vennTitleTextColor = this.vennTitleTextColor ?? this.titleColor, this.vennSetTextColor = this.vennSetTextColor ?? this.textColor, this.quadrant1Fill = this.quadrant1Fill || this.primaryColor, this.quadrant2Fill = this.quadrant2Fill || x(this.primaryColor, { r: 5, g: 5, b: 5 }), this.quadrant3Fill = this.quadrant3Fill || x(this.primaryColor, { r: 10, g: 10, b: 10 }), this.quadrant4Fill = this.quadrant4Fill || x(this.primaryColor, { r: 15, g: 15, b: 15 }), this.quadrant1TextFill = this.quadrant1TextFill || this.primaryTextColor, this.quadrant2TextFill = this.quadrant2TextFill || x(this.primaryTextColor, { r: -5, g: -5, b: -5 }), this.quadrant3TextFill = this.quadrant3TextFill || x(this.primaryTextColor, { r: -10, g: -10, b: -10 }), this.quadrant4TextFill = this.quadrant4TextFill || x(this.primaryTextColor, { r: -15, g: -15, b: -15 }), this.quadrantPointFill = this.quadrantPointFill || ye(this.quadrant1Fill) ? $(this.quadrant1Fill) : O(this.quadrant1Fill), this.quadrantPointTextFill = this.quadrantPointTextFill || this.primaryTextColor, this.quadrantXAxisTextFill = this.quadrantXAxisTextFill || this.primaryTextColor, this.quadrantYAxisTextFill = this.quadrantYAxisTextFill || this.primaryTextColor, this.quadrantInternalBorderStrokeFill = this.quadrantInternalBorderStrokeFill || this.primaryBorderColor, this.quadrantExternalBorderStrokeFill = this.quadrantExternalBorderStrokeFill || this.primaryBorderColor, this.quadrantTitleFill = this.quadrantTitleFill || this.primaryTextColor, this.xyChart = {
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
    }, this.requirementBackground = this.requirementBackground || this.primaryColor, this.requirementBorderColor = this.requirementBorderColor || this.primaryBorderColor, this.requirementBorderSize = this.requirementBorderSize || "1", this.requirementTextColor = this.requirementTextColor || this.primaryTextColor, this.relationColor = this.relationColor || this.lineColor, this.relationLabelBackground = this.relationLabelBackground || (this.darkMode ? O(this.secondaryColor, 30) : this.secondaryColor), this.relationLabelColor = this.relationLabelColor || this.actorTextColor, this.requirementEdgeLabelBackground = "#16141F", this.git0 = this.git0 || this.primaryColor, this.git1 = this.git1 || this.secondaryColor, this.git2 = this.git2 || this.tertiaryColor, this.git3 = this.git3 || x(this.primaryColor, { h: -30 }), this.git4 = this.git4 || x(this.primaryColor, { h: -60 }), this.git5 = this.git5 || x(this.primaryColor, { h: -90 }), this.git6 = this.git6 || x(this.primaryColor, { h: 60 }), this.git7 = this.git7 || x(this.primaryColor, { h: 120 }), this.darkMode ? (this.git0 = $(this.git0, 25), this.git1 = $(this.git1, 25), this.git2 = $(this.git2, 25), this.git3 = $(this.git3, 25), this.git4 = $(this.git4, 25), this.git5 = $(this.git5, 25), this.git6 = $(this.git6, 25), this.git7 = $(this.git7, 25)) : (this.git0 = O(this.git0, 25), this.git1 = O(this.git1, 25), this.git2 = O(this.git2, 25), this.git3 = O(this.git3, 25), this.git4 = O(this.git4, 25), this.git5 = O(this.git5, 25), this.git6 = O(this.git6, 25), this.git7 = O(this.git7, 25)), this.gitInv0 = this.gitInv0 || B(this.git0), this.gitInv1 = this.gitInv1 || B(this.git1), this.gitInv2 = this.gitInv2 || B(this.git2), this.gitInv3 = this.gitInv3 || B(this.git3), this.gitInv4 = this.gitInv4 || B(this.git4), this.gitInv5 = this.gitInv5 || B(this.git5), this.gitInv6 = this.gitInv6 || B(this.git6), this.gitInv7 = this.gitInv7 || B(this.git7), this.branchLabelColor = this.branchLabelColor || (this.darkMode ? "black" : this.labelTextColor), this.gitBranchLabel0 = this.gitBranchLabel0 || this.branchLabelColor, this.gitBranchLabel1 = this.gitBranchLabel1 || this.branchLabelColor, this.gitBranchLabel2 = this.gitBranchLabel2 || this.branchLabelColor, this.gitBranchLabel3 = this.gitBranchLabel3 || this.branchLabelColor, this.gitBranchLabel4 = this.gitBranchLabel4 || this.branchLabelColor, this.gitBranchLabel5 = this.gitBranchLabel5 || this.branchLabelColor, this.gitBranchLabel6 = this.gitBranchLabel6 || this.branchLabelColor, this.gitBranchLabel7 = this.gitBranchLabel7 || this.branchLabelColor, this.tagLabelColor = this.tagLabelColor || this.primaryTextColor, this.tagLabelBackground = this.tagLabelBackground || this.primaryColor, this.tagLabelBorder = this.tagBorder || this.primaryBorderColor, this.tagLabelFontSize = this.tagLabelFontSize || "10px", this.commitLabelColor = this.commitLabelColor || this.secondaryTextColor, this.commitLabelBackground = this.commitLabelBackground || this.secondaryColor, this.commitLabelFontSize = this.commitLabelFontSize || "10px", this.commitLineColor = this.commitLineColor ?? "#BDBCCC", this.erEdgeLabelBackground = "#16141F", this.attributeBackgroundColorOdd = this.attributeBackgroundColorOdd || ve, this.attributeBackgroundColorEven = this.attributeBackgroundColorEven || Le;
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
}, jy = /* @__PURE__ */ p((e) => {
  const t = new Gy();
  return t.calculate(e), t;
}, "getThemeVariables"), Xy = class {
  static {
    p(this, "Theme");
  }
  constructor() {
    this.background = "#ffffff", this.primaryColor = "#cccccc", this.mainBkg = "#ffffff", this.noteBkgColor = "#fff5ad", this.noteTextColor = "#28253D", this.THEME_COLOR_LIMIT = 12, this.radius = 12, this.strokeWidth = 2, this.primaryBorderColor = st(this.primaryColor, this.darkMode), this.fontFamily = '"Recursive Variable", arial, sans-serif', this.fontSize = "14px", this.nodeBorder = "#28253D", this.stateBorder = "#28253D", this.useGradient = !1, this.gradientStart = "#0042eb", this.gradientStop = "#eb0042", this.dropShadow = "url(#drop-shadow)", this.nodeShadow = !0, this.tertiaryColor = "#ffffff", this.archEdgeColor = "calculated", this.archEdgeArrowColor = "calculated", this.archEdgeWidth = "3", this.archGroupBorderColor = this.primaryBorderColor, this.archGroupBorderWidth = "2px", this.actorBorder = "#28253D", this.noteBorderColor = "#FACC15", this.noteFontWeight = 600, this.borderColorArray = [
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
    this.primaryTextColor = this.primaryTextColor || (this.darkMode ? "#eee" : "#28253D"), this.secondaryColor = this.secondaryColor || x(this.primaryColor, { h: -120 }), this.tertiaryColor = this.tertiaryColor || x(this.primaryColor, { h: 180, l: 5 }), this.primaryBorderColor = this.primaryBorderColor || st(this.primaryColor, this.darkMode), this.secondaryBorderColor = this.secondaryBorderColor || st(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = this.tertiaryBorderColor || st(this.tertiaryColor, this.darkMode), this.noteBorderColor = this.noteBorderColor || st(this.noteBkgColor, this.darkMode), this.noteBkgColor = this.noteBkgColor || "#fff5ad", this.noteTextColor = this.noteTextColor || "#28253D", this.secondaryTextColor = this.secondaryTextColor || B(this.secondaryColor), this.tertiaryTextColor = this.tertiaryTextColor || B(this.tertiaryColor), this.lineColor = this.lineColor || B(this.background), this.arrowheadColor = this.arrowheadColor || B(this.background), this.textColor = this.textColor || this.primaryTextColor, this.border2 = this.border2 || this.tertiaryBorderColor, this.nodeBkg = this.nodeBkg || this.primaryColor, this.mainBkg = this.mainBkg || this.primaryColor, this.nodeBorder = this.nodeBorder || this.primaryBorderColor, this.clusterBkg = this.clusterBkg || this.tertiaryColor, this.clusterBorder = this.clusterBorder || this.tertiaryBorderColor, this.defaultLinkColor = this.defaultLinkColor || this.lineColor, this.titleColor = this.titleColor || this.tertiaryTextColor, this.edgeLabelBackground = this.edgeLabelBackground || (this.darkMode ? O(this.secondaryColor, 30) : this.secondaryColor), this.nodeTextColor = this.nodeTextColor || this.primaryTextColor, this.actorBorder = this.actorBorder || this.primaryBorderColor, this.actorBkg = this.actorBkg || this.mainBkg, this.actorTextColor = this.actorTextColor || this.primaryTextColor, this.actorLineColor = this.actorLineColor || this.actorBorder, this.labelBoxBkgColor = this.labelBoxBkgColor || this.actorBkg, this.signalColor = this.signalColor || this.textColor, this.signalTextColor = this.signalTextColor || this.textColor, this.labelBoxBorderColor = this.labelBoxBorderColor || this.actorBorder, this.labelTextColor = this.labelTextColor || this.actorTextColor, this.loopTextColor = this.loopTextColor || this.actorTextColor, this.activationBorderColor = this.activationBorderColor || O(this.secondaryColor, 10), this.activationBkgColor = this.activationBkgColor || this.secondaryColor, this.sequenceNumberColor = this.sequenceNumberColor || B(this.lineColor);
    const e = "#ECECFE", t = "#E9E9F1", r = x(e, { h: 180, l: 5 });
    this.sectionBkgColor = this.sectionBkgColor || r, this.altSectionBkgColor = this.altSectionBkgColor || "white", this.sectionBkgColor = this.sectionBkgColor || t, this.sectionBkgColor2 = this.sectionBkgColor2 || e, this.excludeBkgColor = this.excludeBkgColor || "#eeeeee", this.taskBorderColor = this.taskBorderColor || this.primaryBorderColor, this.taskBkgColor = this.taskBkgColor || e, this.activeTaskBorderColor = this.activeTaskBorderColor || e, this.activeTaskBkgColor = this.activeTaskBkgColor || $(e, 23), this.gridColor = this.gridColor || "lightgrey", this.doneTaskBkgColor = this.doneTaskBkgColor || "lightgrey", this.doneTaskBorderColor = this.doneTaskBorderColor || "grey", this.critBorderColor = this.critBorderColor || "#ff8888", this.critBkgColor = this.critBkgColor || "red", this.todayLineColor = this.todayLineColor || "red", this.taskTextColor = this.taskTextColor || this.textColor, this.vertLineColor = this.vertLineColor || this.primaryBorderColor, this.taskTextOutsideColor = this.taskTextOutsideColor || this.textColor, this.taskTextLightColor = this.taskTextLightColor || this.textColor, this.taskTextColor = this.taskTextColor || this.primaryTextColor, this.taskTextDarkColor = this.taskTextDarkColor || this.textColor, this.taskTextClickableColor = this.taskTextClickableColor || "#003163", this.archEdgeColor = this.lineColor, this.archEdgeArrowColor = this.lineColor, this.personBorder = this.personBorder || this.primaryBorderColor, this.personBkg = this.personBkg || this.mainBkg, this.transitionColor = this.transitionColor || this.lineColor, this.transitionLabelColor = this.transitionLabelColor || this.textColor, this.stateLabelColor = this.stateLabelColor || this.stateBkg || this.primaryTextColor, this.stateBkg = this.stateBkg || this.mainBkg, this.labelBackgroundColor = this.labelBackgroundColor || this.stateBkg, this.compositeBackground = this.compositeBackground || this.background || this.tertiaryColor, this.altBackground = this.altBackground || "#f0f0f0", this.compositeTitleBackground = this.compositeTitleBackground || this.mainBkg, this.compositeBorder = this.compositeBorder || this.nodeBorder, this.innerEndBackground = this.nodeBorder, this.errorBkgColor = this.errorBkgColor || this.tertiaryColor, this.errorTextColor = this.errorTextColor || this.tertiaryTextColor, this.transitionColor = this.transitionColor || this.lineColor, this.specialStateColor = this.lineColor, this.cScale0 = this.cScale0 || "#f4a8ff", this.cScale1 = this.cScale1 || "#46ecd5", this.cScale2 = this.cScale2 || "#ffb86a", this.cScale3 = this.cScale3 || "#dab2ff", this.cScale4 = this.cScale4 || "#7bf1a8", this.cScale5 = this.cScale5 || "#c4b4ff", this.cScale6 = this.cScale6 || "#ffa2a2", this.cScale7 = this.cScale7 || "#ffdf20", this.cScale8 = this.cScale8 || "#a3b3ff", this.cScale9 = this.cScale9 || "#bbf451", this.cScale10 = this.cScale10 || "#74d4ff", this.cScale11 = this.cScale11 || "#ffa1ad";
    for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
      this["cScaleInv" + s] = this["cScaleInv" + s] || B(this["cScale" + s]);
    for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
      this.darkMode ? this["cScalePeer" + s] = this["cScalePeer" + s] || $(this["cScale" + s], 10) : this["cScalePeer" + s] = this["cScalePeer" + s] || O(this["cScale" + s], 10);
    this.scaleLabelColor = this.scaleLabelColor || this.labelTextColor;
    for (let s = 0; s < this.THEME_COLOR_LIMIT; s++)
      this["cScaleLabel" + s] = this["cScaleLabel" + s] || this.scaleLabelColor;
    const i = this.darkMode ? -4 : -1;
    for (let s = 0; s < 5; s++)
      this["surface" + s] = this["surface" + s] || x(this.mainBkg, { h: 180, s: -15, l: i * (5 + s * 3) }), this["surfacePeer" + s] = this["surfacePeer" + s] || x(this.mainBkg, { h: 180, s: -15, l: i * (8 + s * 3) });
    this.classText = this.classText || this.textColor, this.fillType0 = this.fillType0 || e, this.fillType1 = this.fillType1 || t, this.fillType2 = this.fillType2 || x(e, { h: 64 }), this.fillType3 = this.fillType3 || x(t, { h: 64 }), this.fillType4 = this.fillType4 || x(e, { h: -64 }), this.fillType5 = this.fillType5 || x(t, { h: -64 }), this.fillType6 = this.fillType6 || x(e, { h: 128 }), this.fillType7 = this.fillType7 || x(t, { h: 128 }), this.pie1 = this.pie1 || e, this.pie2 = this.pie2 || t, this.pie3 = this.pie3 || r, this.pie4 = this.pie4 || x(e, { l: -10 }), this.pie5 = this.pie5 || x(t, { l: -10 }), this.pie6 = this.pie6 || x(r, { l: -10 }), this.pie7 = this.pie7 || x(e, { h: 60, l: -10 }), this.pie8 = this.pie8 || x(e, { h: -60, l: -10 }), this.pie9 = this.pie9 || x(e, { h: 120, l: 0 }), this.pie10 = this.pie10 || x(e, { h: 60, l: -20 }), this.pie11 = this.pie11 || x(e, { h: -60, l: -20 }), this.pie12 = this.pie12 || x(e, { h: 120, l: -10 }), this.pieTitleTextSize = this.pieTitleTextSize || "25px", this.pieTitleTextColor = this.pieTitleTextColor || this.taskTextDarkColor, this.pieSectionTextSize = this.pieSectionTextSize || "17px", this.pieSectionTextColor = this.pieSectionTextColor || this.textColor, this.pieLegendTextSize = this.pieLegendTextSize || "17px", this.pieLegendTextColor = this.pieLegendTextColor || this.taskTextDarkColor, this.pieStrokeColor = this.pieStrokeColor || "black", this.pieStrokeWidth = this.pieStrokeWidth || "2px", this.pieOuterStrokeWidth = this.pieOuterStrokeWidth || "2px", this.pieOuterStrokeColor = this.pieOuterStrokeColor || "black", this.pieOpacity = this.pieOpacity || "0.7", this.vennTitleTextColor = this.vennTitleTextColor ?? this.titleColor, this.vennSetTextColor = this.vennSetTextColor ?? this.textColor, this.quadrant1Fill = this.quadrant1Fill || e, this.quadrant2Fill = this.quadrant2Fill || x(e, { r: 5, g: 5, b: 5 }), this.quadrant3Fill = this.quadrant3Fill || x(e, { r: 10, g: 10, b: 10 }), this.quadrant4Fill = this.quadrant4Fill || x(e, { r: 15, g: 15, b: 15 }), this.quadrant1TextFill = this.quadrant1TextFill || this.primaryTextColor, this.quadrant2TextFill = this.quadrant2TextFill || x(this.primaryTextColor, { r: -5, g: -5, b: -5 }), this.quadrant3TextFill = this.quadrant3TextFill || x(this.primaryTextColor, { r: -10, g: -10, b: -10 }), this.quadrant4TextFill = this.quadrant4TextFill || x(this.primaryTextColor, { r: -15, g: -15, b: -15 }), this.quadrantPointFill = this.quadrantPointFill || ye(this.quadrant1Fill) ? $(this.quadrant1Fill) : O(this.quadrant1Fill), this.quadrantPointTextFill = this.quadrantPointTextFill || this.primaryTextColor, this.quadrantXAxisTextFill = this.quadrantXAxisTextFill || this.primaryTextColor, this.quadrantYAxisTextFill = this.quadrantYAxisTextFill || this.primaryTextColor, this.quadrantInternalBorderStrokeFill = this.quadrantInternalBorderStrokeFill || this.primaryBorderColor, this.quadrantExternalBorderStrokeFill = this.quadrantExternalBorderStrokeFill || this.primaryBorderColor, this.quadrantTitleFill = this.quadrantTitleFill || this.primaryTextColor, this.xyChart = {
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
    }, this.requirementBackground = this.requirementBackground || e, this.requirementBorderColor = this.requirementBorderColor || this.primaryBorderColor, this.requirementBorderSize = this.requirementBorderSize || "1", this.requirementTextColor = this.requirementTextColor || this.primaryTextColor, this.relationColor = this.relationColor || this.lineColor, this.relationLabelBackground = this.relationLabelBackground || (this.darkMode ? O(this.secondaryColor, 30) : this.secondaryColor), this.relationLabelColor = this.relationLabelColor || this.actorTextColor, this.git0 = this.git0 || e, this.git1 = this.git1 || t, this.git2 = this.git2 || r, this.git3 = this.git3 || x(e, { h: -30 }), this.git4 = this.git4 || x(e, { h: -60 }), this.git5 = this.git5 || x(e, { h: -90 }), this.git6 = this.git6 || x(e, { h: 60 }), this.git7 = this.git7 || x(e, { h: 120 }), this.darkMode ? (this.git0 = $(this.git0, 25), this.git1 = $(this.git1, 25), this.git2 = $(this.git2, 25), this.git3 = $(this.git3, 25), this.git4 = $(this.git4, 25), this.git5 = $(this.git5, 25), this.git6 = $(this.git6, 25), this.git7 = $(this.git7, 25)) : (this.git0 = O(this.git0, 25), this.git1 = O(this.git1, 25), this.git2 = O(this.git2, 25), this.git3 = O(this.git3, 25), this.git4 = O(this.git4, 25), this.git5 = O(this.git5, 25), this.git6 = O(this.git6, 25), this.git7 = O(this.git7, 25)), this.gitInv0 = this.gitInv0 || B(this.git0), this.gitInv1 = this.gitInv1 || B(this.git1), this.gitInv2 = this.gitInv2 || B(this.git2), this.gitInv3 = this.gitInv3 || B(this.git3), this.gitInv4 = this.gitInv4 || B(this.git4), this.gitInv5 = this.gitInv5 || B(this.git5), this.gitInv6 = this.gitInv6 || B(this.git6), this.gitInv7 = this.gitInv7 || B(this.git7), this.branchLabelColor = this.branchLabelColor || (this.darkMode ? "black" : this.labelTextColor), this.gitBranchLabel0 = this.gitBranchLabel0 || this.branchLabelColor, this.gitBranchLabel1 = this.gitBranchLabel1 || this.branchLabelColor, this.gitBranchLabel2 = this.gitBranchLabel2 || this.branchLabelColor, this.gitBranchLabel3 = this.gitBranchLabel3 || this.branchLabelColor, this.gitBranchLabel4 = this.gitBranchLabel4 || this.branchLabelColor, this.gitBranchLabel5 = this.gitBranchLabel5 || this.branchLabelColor, this.gitBranchLabel6 = this.gitBranchLabel6 || this.branchLabelColor, this.gitBranchLabel7 = this.gitBranchLabel7 || this.branchLabelColor, this.tagLabelColor = this.tagLabelColor || this.primaryTextColor, this.tagLabelBackground = this.tagLabelBackground || this.primaryColor, this.tagLabelBorder = this.tagBorder || this.primaryBorderColor, this.tagLabelFontSize = this.tagLabelFontSize || "10px", this.commitLabelColor = this.commitLabelColor || this.secondaryTextColor, this.commitLabelBackground = this.commitLabelBackground || this.secondaryColor, this.commitLineColor = this.commitLineColor ?? "#BDBCCC", this.commitLabelFontSize = this.commitLabelFontSize || "10px", this.fontWeight = 600, this.erEdgeLabelBackground = "#FFFFFF", this.attributeBackgroundColorOdd = this.attributeBackgroundColorOdd || ve, this.attributeBackgroundColorEven = this.attributeBackgroundColorEven || Le;
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
}, Vy = /* @__PURE__ */ p((e) => {
  const t = new Xy();
  return t.calculate(e), t;
}, "getThemeVariables"), Zy = class {
  static {
    p(this, "Theme");
  }
  constructor() {
    this.background = "#333", this.primaryColor = "#1f2020", this.secondaryColor = $(this.primaryColor, 16), this.tertiaryColor = x(this.primaryColor, { h: -160 }), this.primaryBorderColor = B(this.background), this.secondaryBorderColor = st(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = st(this.tertiaryColor, this.darkMode), this.primaryTextColor = B(this.primaryColor), this.secondaryTextColor = B(this.secondaryColor), this.tertiaryTextColor = B(this.tertiaryColor), this.mainBkg = "#111113", this.secondBkg = "calculated", this.mainContrastColor = "lightgrey", this.darkTextColor = $(B("#323D47"), 10), this.border1 = "#ccc", this.border2 = Ke(255, 255, 255, 0.25), this.arrowheadColor = B(this.background), this.fontFamily = '"Recursive Variable", arial, sans-serif', this.fontSize = "14px", this.labelBackground = "#111113", this.textColor = "#ccc", this.THEME_COLOR_LIMIT = 12, this.radius = 12, this.strokeWidth = 2, this.noteBkgColor = this.noteBkgColor ?? "#FEF9C3", this.noteTextColor = this.noteTextColor ?? "#28253D", this.THEME_COLOR_LIMIT = 12, this.fontFamily = '"Recursive Variable", arial, sans-serif', this.fontSize = "14px", this.nodeBorder = "#FFFFFF", this.stateBorder = "#FFFFFF", this.useGradient = !1, this.gradientStart = "#0042eb", this.gradientStop = "#eb0042", this.dropShadow = "url(#drop-shadow)", this.nodeShadow = !0, this.archEdgeColor = "calculated", this.archEdgeArrowColor = "calculated", this.archEdgeWidth = "3", this.archGroupBorderColor = this.primaryBorderColor, this.archGroupBorderWidth = "2px", this.clusterBkg = "#1E1A2E", this.clusterBorder = "#BDBCCC", this.noteBorderColor = "#FACC15", this.noteFontWeight = 600, this.borderColorArray = [
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
    this.primaryTextColor = this.primaryTextColor || (this.darkMode ? "#eee" : "#FFFFFF"), this.secondaryColor = this.secondaryColor || x(this.primaryColor, { h: -120 }), this.tertiaryColor = this.tertiaryColor || x(this.primaryColor, { h: 180, l: 5 }), this.primaryBorderColor = this.primaryBorderColor || st(this.primaryColor, this.darkMode), this.secondaryBorderColor = this.secondaryBorderColor || st(this.secondaryColor, this.darkMode), this.tertiaryBorderColor = this.tertiaryBorderColor || st(this.tertiaryColor, this.darkMode), this.noteBorderColor = this.noteBorderColor || st(this.noteBkgColor, this.darkMode), this.noteBkgColor = this.noteBkgColor || "#fff5ad", this.noteTextColor = this.noteTextColor || "#FFFFFF", this.secondaryTextColor = this.secondaryTextColor || B(this.secondaryColor), this.tertiaryTextColor = this.tertiaryTextColor || B(this.tertiaryColor), this.lineColor = this.lineColor || B(this.background), this.arrowheadColor = this.arrowheadColor || B(this.background), this.textColor = this.textColor || this.primaryTextColor, this.border2 = this.border2 || this.tertiaryBorderColor, this.nodeBkg = this.nodeBkg || this.primaryColor, this.mainBkg = this.mainBkg || this.primaryColor, this.nodeBorder = this.nodeBorder || this.border1, this.clusterBkg = this.clusterBkg || this.tertiaryColor, this.clusterBorder = this.clusterBorder || this.tertiaryBorderColor, this.defaultLinkColor = this.defaultLinkColor || this.lineColor, this.titleColor = this.titleColor || this.tertiaryTextColor, this.edgeLabelBackground = this.edgeLabelBackground || (this.darkMode ? O(this.secondaryColor, 30) : this.secondaryColor), this.nodeTextColor = this.nodeTextColor || this.primaryTextColor, this.actorBorder = "#FFFFFF", this.signalColor = "#FFFFFF", this.labelBoxBorderColor = "#BDBCCC", this.actorBorder = this.actorBorder || this.primaryBorderColor, this.actorBkg = this.actorBkg || this.mainBkg, this.actorTextColor = this.actorTextColor || this.primaryTextColor, this.actorLineColor = this.actorLineColor || this.actorBorder, this.labelBoxBkgColor = this.labelBoxBkgColor || this.actorBkg, this.signalColor = this.signalColor || this.textColor, this.signalTextColor = this.signalTextColor || this.textColor, this.labelBoxBorderColor = this.labelBoxBorderColor || this.actorBorder, this.labelTextColor = this.labelTextColor || this.actorTextColor, this.loopTextColor = this.loopTextColor || this.actorTextColor, this.activationBorderColor = this.activationBorderColor || O(this.secondaryColor, 10), this.activationBkgColor = this.activationBkgColor || this.secondaryColor, this.sequenceNumberColor = this.sequenceNumberColor || B(this.lineColor), this.rootLabelColor = "#FFFFFF", this.sectionBkgColor = this.sectionBkgColor || this.tertiaryColor, this.altSectionBkgColor = this.altSectionBkgColor || "white", this.sectionBkgColor = this.sectionBkgColor || this.secondaryColor, this.sectionBkgColor2 = this.sectionBkgColor2 || this.primaryColor, this.excludeBkgColor = this.excludeBkgColor || "#eeeeee", this.taskBorderColor = this.taskBorderColor || this.primaryBorderColor, this.taskBkgColor = this.taskBkgColor || this.primaryColor, this.activeTaskBorderColor = this.activeTaskBorderColor || this.primaryColor, this.activeTaskBkgColor = this.activeTaskBkgColor || $(this.primaryColor, 23), this.gridColor = this.gridColor || "lightgrey", this.doneTaskBkgColor = this.doneTaskBkgColor || "lightgrey", this.doneTaskBorderColor = this.doneTaskBorderColor || "grey", this.critBorderColor = this.critBorderColor || "#ff8888", this.critBkgColor = this.critBkgColor || "red", this.todayLineColor = this.todayLineColor || "red", this.taskTextColor = this.taskTextColor || this.textColor, this.vertLineColor = this.vertLineColor || this.primaryBorderColor, this.taskTextOutsideColor = this.taskTextOutsideColor || this.textColor, this.taskTextLightColor = this.taskTextLightColor || this.textColor, this.taskTextColor = this.taskTextColor || this.primaryTextColor, this.taskTextDarkColor = this.taskTextDarkColor || this.textColor, this.taskTextClickableColor = this.taskTextClickableColor || "#003163", this.archEdgeColor = this.lineColor, this.archEdgeArrowColor = this.lineColor, this.personBorder = this.personBorder || this.primaryBorderColor, this.personBkg = this.personBkg || this.mainBkg, this.transitionColor = this.transitionColor || this.lineColor, this.transitionLabelColor = this.transitionLabelColor || this.textColor, this.stateLabelColor = this.stateLabelColor || this.stateBkg || this.primaryTextColor, this.stateBkg = this.stateBkg || this.mainBkg, this.labelBackgroundColor = this.labelBackgroundColor || this.stateBkg, this.compositeBackground = this.compositeBackground || this.background || this.tertiaryColor, this.altBackground = this.altBackground || "#f0f0f0", this.compositeTitleBackground = this.compositeTitleBackground || this.mainBkg, this.compositeBorder = this.compositeBorder || this.nodeBorder, this.innerEndBackground = this.nodeBorder, this.errorBkgColor = this.errorBkgColor || this.tertiaryColor, this.errorTextColor = this.errorTextColor || this.tertiaryTextColor, this.transitionColor = this.transitionColor || this.lineColor, this.specialStateColor = this.lineColor, this.cScale0 = this.cScale0 || "#f4a8ff", this.cScale1 = this.cScale1 || "#46ecd5", this.cScale2 = this.cScale2 || "#ffb86a", this.cScale3 = this.cScale3 || "#dab2ff", this.cScale4 = this.cScale4 || "#7bf1a8", this.cScale5 = this.cScale5 || "#c4b4ff", this.cScale6 = this.cScale6 || "#ffa2a2", this.cScale7 = this.cScale7 || "#ffdf20", this.cScale8 = this.cScale8 || "#a3b3ff", this.cScale9 = this.cScale9 || "#bbf451", this.cScale10 = this.cScale10 || "#74d4ff", this.cScale11 = this.cScale11 || "#ffa1ad";
    for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
      this["cScaleInv" + t] = this["cScaleInv" + t] || B(this["cScale" + t]);
    for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
      this.darkMode ? this["cScalePeer" + t] = this["cScalePeer" + t] || $(this["cScale" + t], 10) : this["cScalePeer" + t] = this["cScalePeer" + t] || O(this["cScale" + t], 10);
    this.scaleLabelColor = this.scaleLabelColor || this.labelTextColor;
    for (let t = 0; t < this.THEME_COLOR_LIMIT; t++)
      this["cScaleLabel" + t] = O(this["cScale" + t], 75);
    const e = this.darkMode ? -4 : -1;
    for (let t = 0; t < 5; t++)
      this["surface" + t] = this["surface" + t] || x(this.mainBkg, { h: 180, s: -15, l: e * (5 + t * 3) }), this["surfacePeer" + t] = this["surfacePeer" + t] || x(this.mainBkg, { h: 180, s: -15, l: e * (8 + t * 3) });
    this.classText = this.classText || this.textColor, this.fillType0 = this.fillType0 || this.primaryColor, this.fillType1 = this.fillType1 || this.secondaryColor, this.fillType2 = this.fillType2 || x(this.primaryColor, { h: 64 }), this.fillType3 = this.fillType3 || x(this.secondaryColor, { h: 64 }), this.fillType4 = this.fillType4 || x(this.primaryColor, { h: -64 }), this.fillType5 = this.fillType5 || x(this.secondaryColor, { h: -64 }), this.fillType6 = this.fillType6 || x(this.primaryColor, { h: 128 }), this.fillType7 = this.fillType7 || x(this.secondaryColor, { h: 128 }), this.pie1 = this.pie1 || this.primaryColor, this.pie2 = this.pie2 || this.secondaryColor, this.pie3 = this.pie3 || this.tertiaryColor, this.pie4 = this.pie4 || x(this.primaryColor, { l: -10 }), this.pie5 = this.pie5 || x(this.secondaryColor, { l: -10 }), this.pie6 = this.pie6 || x(this.tertiaryColor, { l: -10 }), this.pie7 = this.pie7 || x(this.primaryColor, { h: 60, l: -10 }), this.pie8 = this.pie8 || x(this.primaryColor, { h: -60, l: -10 }), this.pie9 = this.pie9 || x(this.primaryColor, { h: 120, l: 0 }), this.pie10 = this.pie10 || x(this.primaryColor, { h: 60, l: -20 }), this.pie11 = this.pie11 || x(this.primaryColor, { h: -60, l: -20 }), this.pie12 = this.pie12 || x(this.primaryColor, { h: 120, l: -10 }), this.pieTitleTextSize = this.pieTitleTextSize || "25px", this.pieTitleTextColor = this.pieTitleTextColor || this.taskTextDarkColor, this.pieSectionTextSize = this.pieSectionTextSize || "17px", this.pieSectionTextColor = this.pieSectionTextColor || this.textColor, this.pieLegendTextSize = this.pieLegendTextSize || "17px", this.pieLegendTextColor = this.pieLegendTextColor || this.taskTextDarkColor, this.pieStrokeColor = this.pieStrokeColor || "black", this.pieStrokeWidth = this.pieStrokeWidth || "2px", this.pieOuterStrokeWidth = this.pieOuterStrokeWidth || "2px", this.pieOuterStrokeColor = this.pieOuterStrokeColor || "black", this.pieOpacity = this.pieOpacity || "0.7", this.vennTitleTextColor = this.vennTitleTextColor ?? this.titleColor, this.vennSetTextColor = this.vennSetTextColor ?? this.textColor, this.quadrant1Fill = this.quadrant1Fill || this.primaryColor, this.quadrant2Fill = this.quadrant2Fill || x(this.primaryColor, { r: 5, g: 5, b: 5 }), this.quadrant3Fill = this.quadrant3Fill || x(this.primaryColor, { r: 10, g: 10, b: 10 }), this.quadrant4Fill = this.quadrant4Fill || x(this.primaryColor, { r: 15, g: 15, b: 15 }), this.quadrant1TextFill = this.quadrant1TextFill || this.primaryTextColor, this.quadrant2TextFill = this.quadrant2TextFill || x(this.primaryTextColor, { r: -5, g: -5, b: -5 }), this.quadrant3TextFill = this.quadrant3TextFill || x(this.primaryTextColor, { r: -10, g: -10, b: -10 }), this.quadrant4TextFill = this.quadrant4TextFill || x(this.primaryTextColor, { r: -15, g: -15, b: -15 }), this.quadrantPointFill = this.quadrantPointFill || ye(this.quadrant1Fill) ? $(this.quadrant1Fill) : O(this.quadrant1Fill), this.quadrantPointTextFill = this.quadrantPointTextFill || this.primaryTextColor, this.quadrantXAxisTextFill = this.quadrantXAxisTextFill || this.primaryTextColor, this.quadrantYAxisTextFill = this.quadrantYAxisTextFill || this.primaryTextColor, this.quadrantInternalBorderStrokeFill = this.quadrantInternalBorderStrokeFill || this.primaryBorderColor, this.quadrantExternalBorderStrokeFill = this.quadrantExternalBorderStrokeFill || this.primaryBorderColor, this.quadrantTitleFill = this.quadrantTitleFill || this.primaryTextColor, this.xyChart = {
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
    }, this.requirementBackground = this.requirementBackground || this.primaryColor, this.requirementBorderColor = this.requirementBorderColor || this.primaryBorderColor, this.requirementBorderSize = this.requirementBorderSize || "1", this.requirementTextColor = this.requirementTextColor || this.primaryTextColor, this.relationColor = this.relationColor || this.lineColor, this.relationLabelBackground = this.relationLabelBackground || (this.darkMode ? O(this.secondaryColor, 30) : this.secondaryColor), this.relationLabelColor = this.relationLabelColor || this.actorTextColor, this.git0 = this.git0 || this.primaryColor, this.git1 = this.git1 || this.secondaryColor, this.git2 = this.git2 || this.tertiaryColor, this.git3 = this.git3 || x(this.primaryColor, { h: -30 }), this.git4 = this.git4 || x(this.primaryColor, { h: -60 }), this.git5 = this.git5 || x(this.primaryColor, { h: -90 }), this.git6 = this.git6 || x(this.primaryColor, { h: 60 }), this.git7 = this.git7 || x(this.primaryColor, { h: 120 }), this.darkMode ? (this.git0 = $(this.git0, 25), this.git1 = $(this.git1, 25), this.git2 = $(this.git2, 25), this.git3 = $(this.git3, 25), this.git4 = $(this.git4, 25), this.git5 = $(this.git5, 25), this.git6 = $(this.git6, 25), this.git7 = $(this.git7, 25)) : (this.git0 = O(this.git0, 25), this.git1 = O(this.git1, 25), this.git2 = O(this.git2, 25), this.git3 = O(this.git3, 25), this.git4 = O(this.git4, 25), this.git5 = O(this.git5, 25), this.git6 = O(this.git6, 25), this.git7 = O(this.git7, 25)), this.gitInv0 = this.gitInv0 || B(this.git0), this.gitInv1 = this.gitInv1 || B(this.git1), this.gitInv2 = this.gitInv2 || B(this.git2), this.gitInv3 = this.gitInv3 || B(this.git3), this.gitInv4 = this.gitInv4 || B(this.git4), this.gitInv5 = this.gitInv5 || B(this.git5), this.gitInv6 = this.gitInv6 || B(this.git6), this.gitInv7 = this.gitInv7 || B(this.git7), this.branchLabelColor = this.branchLabelColor || (this.darkMode ? "black" : this.labelTextColor), this.gitBranchLabel0 = this.gitBranchLabel0 || this.branchLabelColor, this.gitBranchLabel1 = this.gitBranchLabel1 || this.branchLabelColor, this.gitBranchLabel2 = this.gitBranchLabel2 || this.branchLabelColor, this.gitBranchLabel3 = this.gitBranchLabel3 || this.branchLabelColor, this.gitBranchLabel4 = this.gitBranchLabel4 || this.branchLabelColor, this.gitBranchLabel5 = this.gitBranchLabel5 || this.branchLabelColor, this.gitBranchLabel6 = this.gitBranchLabel6 || this.branchLabelColor, this.gitBranchLabel7 = this.gitBranchLabel7 || this.branchLabelColor, this.tagLabelColor = this.tagLabelColor || this.primaryTextColor, this.tagLabelBackground = this.tagLabelBackground || this.primaryColor, this.tagLabelBorder = this.tagBorder || this.primaryBorderColor, this.tagLabelFontSize = this.tagLabelFontSize || "10px", this.commitLabelColor = this.commitLabelColor || this.secondaryTextColor, this.commitLabelBackground = this.commitLabelBackground || this.secondaryColor, this.commitLabelFontSize = this.commitLabelFontSize || "10px", this.commitLineColor = this.commitLineColor ?? "#BDBCCC", this.fontWeight = 600, this.erEdgeLabelBackground = "#16141F", this.attributeBackgroundColorOdd = this.attributeBackgroundColorOdd || ve, this.attributeBackgroundColorEven = this.attributeBackgroundColorEven || Le;
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
}, Ky = /* @__PURE__ */ p((e) => {
  const t = new Zy();
  return t.calculate(e), t;
}, "getThemeVariables"), Re = {
  base: {
    getThemeVariables: My
  },
  dark: {
    getThemeVariables: $y
  },
  default: {
    getThemeVariables: Iy
  },
  forest: {
    getThemeVariables: Ry
  },
  neutral: {
    getThemeVariables: Ny
  },
  neo: {
    getThemeVariables: Wy
  },
  "neo-dark": {
    getThemeVariables: Hy
  },
  redux: {
    getThemeVariables: Uy
  },
  "redux-dark": {
    getThemeVariables: jy
  },
  "redux-color": {
    getThemeVariables: Vy
  },
  "redux-dark-color": {
    getThemeVariables: Ky
  }
}, Yt = {
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
    hideEmptyMembersBox: !1,
    hierarchicalNamespaces: !0
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
    suffix: "",
    nodeWidth: 10,
    nodePadding: 12,
    labelStyle: "legacy"
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
    randomize: !1,
    nodeSeparation: 75,
    idealEdgeLengthMultiplier: 1.5,
    edgeElasticity: 0.45,
    numIter: 2500
  },
  eventmodeling: {
    useMaxWidth: !0,
    padding: 30,
    rowHeight: 32
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
}, Cc = {
  ...Yt,
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
  themeVariables: Re.default.getThemeVariables(),
  sequence: {
    ...Yt.sequence,
    messageFont: /* @__PURE__ */ p(function() {
      return {
        fontFamily: this.messageFontFamily,
        fontSize: this.messageFontSize,
        fontWeight: this.messageFontWeight
      };
    }, "messageFont"),
    noteFont: /* @__PURE__ */ p(function() {
      return {
        fontFamily: this.noteFontFamily,
        fontSize: this.noteFontSize,
        fontWeight: this.noteFontWeight
      };
    }, "noteFont"),
    actorFont: /* @__PURE__ */ p(function() {
      return {
        fontFamily: this.actorFontFamily,
        fontSize: this.actorFontSize,
        fontWeight: this.actorFontWeight
      };
    }, "actorFont")
  },
  class: {
    hideEmptyMembersBox: !1,
    hierarchicalNamespaces: !0
  },
  gantt: {
    ...Yt.gantt,
    tickInterval: void 0,
    useWidth: void 0
    // can probably be removed since `configKeys` already includes this
  },
  c4: {
    ...Yt.c4,
    useWidth: void 0,
    personFont: /* @__PURE__ */ p(function() {
      return {
        fontFamily: this.personFontFamily,
        fontSize: this.personFontSize,
        fontWeight: this.personFontWeight
      };
    }, "personFont"),
    flowchart: {
      ...Yt.flowchart,
      inheritDir: !1
      // default to legacy behavior
    },
    external_personFont: /* @__PURE__ */ p(function() {
      return {
        fontFamily: this.external_personFontFamily,
        fontSize: this.external_personFontSize,
        fontWeight: this.external_personFontWeight
      };
    }, "external_personFont"),
    systemFont: /* @__PURE__ */ p(function() {
      return {
        fontFamily: this.systemFontFamily,
        fontSize: this.systemFontSize,
        fontWeight: this.systemFontWeight
      };
    }, "systemFont"),
    external_systemFont: /* @__PURE__ */ p(function() {
      return {
        fontFamily: this.external_systemFontFamily,
        fontSize: this.external_systemFontSize,
        fontWeight: this.external_systemFontWeight
      };
    }, "external_systemFont"),
    system_dbFont: /* @__PURE__ */ p(function() {
      return {
        fontFamily: this.system_dbFontFamily,
        fontSize: this.system_dbFontSize,
        fontWeight: this.system_dbFontWeight
      };
    }, "system_dbFont"),
    external_system_dbFont: /* @__PURE__ */ p(function() {
      return {
        fontFamily: this.external_system_dbFontFamily,
        fontSize: this.external_system_dbFontSize,
        fontWeight: this.external_system_dbFontWeight
      };
    }, "external_system_dbFont"),
    system_queueFont: /* @__PURE__ */ p(function() {
      return {
        fontFamily: this.system_queueFontFamily,
        fontSize: this.system_queueFontSize,
        fontWeight: this.system_queueFontWeight
      };
    }, "system_queueFont"),
    external_system_queueFont: /* @__PURE__ */ p(function() {
      return {
        fontFamily: this.external_system_queueFontFamily,
        fontSize: this.external_system_queueFontSize,
        fontWeight: this.external_system_queueFontWeight
      };
    }, "external_system_queueFont"),
    containerFont: /* @__PURE__ */ p(function() {
      return {
        fontFamily: this.containerFontFamily,
        fontSize: this.containerFontSize,
        fontWeight: this.containerFontWeight
      };
    }, "containerFont"),
    external_containerFont: /* @__PURE__ */ p(function() {
      return {
        fontFamily: this.external_containerFontFamily,
        fontSize: this.external_containerFontSize,
        fontWeight: this.external_containerFontWeight
      };
    }, "external_containerFont"),
    container_dbFont: /* @__PURE__ */ p(function() {
      return {
        fontFamily: this.container_dbFontFamily,
        fontSize: this.container_dbFontSize,
        fontWeight: this.container_dbFontWeight
      };
    }, "container_dbFont"),
    external_container_dbFont: /* @__PURE__ */ p(function() {
      return {
        fontFamily: this.external_container_dbFontFamily,
        fontSize: this.external_container_dbFontSize,
        fontWeight: this.external_container_dbFontWeight
      };
    }, "external_container_dbFont"),
    container_queueFont: /* @__PURE__ */ p(function() {
      return {
        fontFamily: this.container_queueFontFamily,
        fontSize: this.container_queueFontSize,
        fontWeight: this.container_queueFontWeight
      };
    }, "container_queueFont"),
    external_container_queueFont: /* @__PURE__ */ p(function() {
      return {
        fontFamily: this.external_container_queueFontFamily,
        fontSize: this.external_container_queueFontSize,
        fontWeight: this.external_container_queueFontWeight
      };
    }, "external_container_queueFont"),
    componentFont: /* @__PURE__ */ p(function() {
      return {
        fontFamily: this.componentFontFamily,
        fontSize: this.componentFontSize,
        fontWeight: this.componentFontWeight
      };
    }, "componentFont"),
    external_componentFont: /* @__PURE__ */ p(function() {
      return {
        fontFamily: this.external_componentFontFamily,
        fontSize: this.external_componentFontSize,
        fontWeight: this.external_componentFontWeight
      };
    }, "external_componentFont"),
    component_dbFont: /* @__PURE__ */ p(function() {
      return {
        fontFamily: this.component_dbFontFamily,
        fontSize: this.component_dbFontSize,
        fontWeight: this.component_dbFontWeight
      };
    }, "component_dbFont"),
    external_component_dbFont: /* @__PURE__ */ p(function() {
      return {
        fontFamily: this.external_component_dbFontFamily,
        fontSize: this.external_component_dbFontSize,
        fontWeight: this.external_component_dbFontWeight
      };
    }, "external_component_dbFont"),
    component_queueFont: /* @__PURE__ */ p(function() {
      return {
        fontFamily: this.component_queueFontFamily,
        fontSize: this.component_queueFontSize,
        fontWeight: this.component_queueFontWeight
      };
    }, "component_queueFont"),
    external_component_queueFont: /* @__PURE__ */ p(function() {
      return {
        fontFamily: this.external_component_queueFontFamily,
        fontSize: this.external_component_queueFontSize,
        fontWeight: this.external_component_queueFontWeight
      };
    }, "external_component_queueFont"),
    boundaryFont: /* @__PURE__ */ p(function() {
      return {
        fontFamily: this.boundaryFontFamily,
        fontSize: this.boundaryFontSize,
        fontWeight: this.boundaryFontWeight
      };
    }, "boundaryFont"),
    messageFont: /* @__PURE__ */ p(function() {
      return {
        fontFamily: this.messageFontFamily,
        fontSize: this.messageFontSize,
        fontWeight: this.messageFontWeight
      };
    }, "messageFont")
  },
  pie: {
    ...Yt.pie,
    useWidth: 984
  },
  xyChart: {
    ...Yt.xyChart,
    useWidth: void 0
  },
  requirement: {
    ...Yt.requirement,
    useWidth: void 0
  },
  packet: {
    ...Yt.packet
  },
  eventmodeling: {
    ...Yt.eventmodeling
  },
  treeView: {
    ...Yt.treeView,
    useWidth: void 0
  },
  radar: {
    ...Yt.radar
  },
  ishikawa: {
    ...Yt.ishikawa
  },
  sankey: {
    ...Yt.sankey,
    // Set so that `configKeys` includes this key for sanitizeDirective
    nodeColors: void 0
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
    ...Yt.venn
  }
}, xc = /* @__PURE__ */ p((e, t = "") => Object.keys(e).reduce((r, i) => Array.isArray(e[i]) ? r : typeof e[i] == "object" && e[i] !== null ? [...r, t + i, ...xc(e[i], "")] : [...r, t + i], []), "keyify"), Qy = new Set(xc(Cc, "")), bc = Cc, Fs = /* @__PURE__ */ p((e) => {
  if (P.debug("sanitizeDirective called with", e), !(typeof e != "object" || e == null)) {
    if (Array.isArray(e)) {
      e.forEach((t) => Fs(t));
      return;
    }
    for (const t of Object.keys(e)) {
      if (P.debug("Checking key", t), t.startsWith("__") || t.includes("proto") || t.includes("constr") || !Qy.has(t) || e[t] == null) {
        P.debug("sanitize deleting key: ", t), delete e[t];
        continue;
      }
      if (typeof e[t] == "object") {
        if (t === "nodeColors") {
          const i = /^#[\da-f]{3,8}$|^rgb\([\d\s%,.]+\)$|^hsl\([\d\s%,.]+\)$|^[a-z]+$/i;
          for (const s of Object.keys(e[t]))
            (typeof e[t][s] != "string" || !i.test(e[t][s])) && (P.debug("sanitize deleting invalid color:", s, e[t][s]), delete e[t][s]);
        } else
          P.debug("sanitizing object", t), Fs(e[t]);
        continue;
      }
      const r = ["themeCSS", "fontFamily", "altFontFamily"];
      for (const i of r)
        t.includes(i) && (P.debug("sanitizing css option", t), e[t] = kc(e[t]));
    }
    if (e.themeVariables)
      for (const t of Object.keys(e.themeVariables)) {
        const r = e.themeVariables[t];
        r?.match && !r.match(/^[\d "#%(),.;A-Za-z]+$/) && (e.themeVariables[t] = "");
      }
    P.debug("After sanitization", e);
  }
}, "sanitizeDirective"), kc = /* @__PURE__ */ p((e) => {
  let t = 0, r = 0;
  for (const i of e) {
    if (t < r)
      return "{ /* ERROR: Unbalanced CSS */ }";
    i === "{" ? t++ : i === "}" && r++;
  }
  return t !== r ? "{ /* ERROR: Unbalanced CSS */ }" : e;
}, "sanitizeCss"), Gr = Object.freeze(bc), ze = /* @__PURE__ */ p((e) => !(e === !1 || ["false", "null", "0"].includes(String(e).trim().toLowerCase())), "evaluate"), Jt = $t({}, Gr), As, yr = [], _i = $t({}, Gr), no = /* @__PURE__ */ p((e, t) => {
  let r = $t({}, e), i = {};
  for (const s of t)
    Sc(s), i = $t(i, s);
  if (r = $t(r, i), i.theme && i.theme in Re) {
    const s = $t({}, As), o = $t(
      s.themeVariables || {},
      i.themeVariables
    );
    r.theme && r.theme in Re && (r.themeVariables = Re[r.theme].getThemeVariables(o));
  }
  return _i = r, Bc(_i), _i;
}, "updateCurrentConfig"), Jy = /* @__PURE__ */ p((e) => (Jt = $t({}, Gr), Jt = $t(Jt, e), e.theme && Re[e.theme] && (Jt.themeVariables = Re[e.theme].getThemeVariables(e.themeVariables)), no(Jt, yr), Jt), "setSiteConfig"), t0 = /* @__PURE__ */ p((e) => {
  As = $t({}, e);
}, "saveConfigFromInitialize"), e0 = /* @__PURE__ */ p((e) => (Jt = $t(Jt, e), no(Jt, yr), Jt), "updateSiteConfig"), wc = /* @__PURE__ */ p(() => $t({}, Jt), "getSiteConfig"), Tc = /* @__PURE__ */ p((e) => (Bc(e), $t(_i, e), Tt()), "setConfig"), Tt = /* @__PURE__ */ p(() => $t({}, _i), "getConfig"), Sc = /* @__PURE__ */ p((e) => {
  e && (["secure", ...Jt.secure ?? []].forEach((t) => {
    Object.hasOwn(e, t) && (P.debug(`Denied attempt to modify a secure key ${t}`, e[t]), delete e[t]);
  }), Object.keys(e).forEach((t) => {
    t.startsWith("__") && delete e[t];
  }), Object.keys(e).forEach((t) => {
    typeof e[t] == "string" && (e[t].includes("<") || e[t].includes(">") || e[t].includes("url(data:")) && delete e[t], typeof e[t] == "object" && Sc(e[t]);
  }));
}, "sanitize"), r0 = /* @__PURE__ */ p((e) => {
  Fs(e), e.fontFamily && !e.themeVariables?.fontFamily && (e.themeVariables = {
    ...e.themeVariables,
    fontFamily: e.fontFamily
  }), yr.push(e), no(Jt, yr);
}, "addDirective"), Ms = /* @__PURE__ */ p((e = Jt) => {
  yr = [], no(e, yr);
}, "reset"), i0 = {
  LAZY_LOAD_DEPRECATED: "The configuration options lazyLoadedDiagrams and loadExternalDiagramsAtStartup are deprecated. Please use registerExternalDiagrams instead.",
  FLOWCHART_HTML_LABELS_DEPRECATED: "flowchart.htmlLabels is deprecated. Please use global htmlLabels instead."
}, Wl = {}, _c = /* @__PURE__ */ p((e) => {
  Wl[e] || (P.warn(i0[e]), Wl[e] = !0);
}, "issueWarning"), Bc = /* @__PURE__ */ p((e) => {
  e && (e.lazyLoadedDiagrams || e.loadExternalDiagramsAtStartup) && _c("LAZY_LOAD_DEPRECATED");
}, "checkConfig"), yv = /* @__PURE__ */ p(() => {
  let e = {};
  As && (e = $t(e, As));
  for (const t of yr)
    e = $t(e, t);
  return e;
}, "getUserDefinedConfig"), Vt = /* @__PURE__ */ p((e) => (e.flowchart?.htmlLabels != null && _c("FLOWCHART_HTML_LABELS_DEPRECATED"), ze(e.htmlLabels ?? e.flowchart?.htmlLabels ?? !0)), "getEffectiveHtmlLabels"), Wi = /<br\s*\/?>/gi, s0 = /* @__PURE__ */ p((e) => e ? Fc(e).replace(/\\n/g, "#br#").split("#br#") : [""], "getRows"), o0 = /* @__PURE__ */ (() => {
  let e = !1;
  return () => {
    e || (vc(), e = !0);
  };
})();
function vc() {
  const e = "data-temp-href-target";
  Ur.addHook("beforeSanitizeAttributes", (t) => {
    t.tagName === "A" && t.hasAttribute("target") && t.setAttribute(e, t.getAttribute("target") ?? "");
  }), Ur.addHook("afterSanitizeAttributes", (t) => {
    t.tagName === "A" && t.hasAttribute(e) && (t.setAttribute("target", t.getAttribute(e) ?? ""), t.removeAttribute(e), t.getAttribute("target") === "_blank" && t.setAttribute("rel", "noopener"));
  });
}
p(vc, "setupDompurifyHooks");
var Lc = /* @__PURE__ */ p((e) => (o0(), Ur.sanitize(e)), "removeScript"), zl = /* @__PURE__ */ p((e, t) => {
  if (Vt(t)) {
    const r = t.securityLevel;
    r === "antiscript" || r === "strict" || r === "sandbox" ? e = Lc(e) : r !== "loose" && (e = Fc(e), e = e.replace(/</g, "&lt;").replace(/>/g, "&gt;"), e = e.replace(/=/g, "&equals;"), e = h0(e));
  }
  return e;
}, "sanitizeMore"), me = /* @__PURE__ */ p((e, t) => e && (t.dompurifyConfig ? e = Ur.sanitize(zl(e, t), t.dompurifyConfig).toString() : e = Ur.sanitize(zl(e, t), {
  FORBID_TAGS: ["style"]
}).toString(), e), "sanitizeText"), a0 = /* @__PURE__ */ p((e, t) => typeof e == "string" ? me(e, t) : e.flat().map((r) => me(r, t)), "sanitizeTextOrArray"), n0 = /* @__PURE__ */ p((e) => Wi.test(e), "hasBreaks"), l0 = /* @__PURE__ */ p((e) => e.split(Wi), "splitBreaks"), h0 = /* @__PURE__ */ p((e) => e.replace(/#br#/g, "<br/>"), "placeholderToBreak"), Fc = /* @__PURE__ */ p((e) => e.replace(Wi, "#br#"), "breakToPlaceholder"), c0 = /* @__PURE__ */ p((e) => {
  let t = "";
  return e && (t = window.location.protocol + "//" + window.location.host + window.location.pathname + window.location.search, t = CSS.escape(t)), t;
}, "getUrl"), d0 = /* @__PURE__ */ p(function(...e) {
  const t = e.filter((r) => !isNaN(r));
  return Math.max(...t);
}, "getMax"), u0 = /* @__PURE__ */ p(function(...e) {
  const t = e.filter((r) => !isNaN(r));
  return Math.min(...t);
}, "getMin"), Hl = /* @__PURE__ */ p(function(e) {
  const t = e.split(/(,)/), r = [];
  for (let i = 0; i < t.length; i++) {
    let s = t[i];
    if (s === "," && i > 0 && i + 1 < t.length) {
      const o = t[i - 1], a = t[i + 1];
      f0(o, a) && (s = o + "," + a, i++, r.pop());
    }
    r.push(p0(s));
  }
  return r.join("");
}, "parseGenericTypes"), ha = /* @__PURE__ */ p((e, t) => Math.max(0, e.split(t).length - 1), "countOccurrence"), f0 = /* @__PURE__ */ p((e, t) => {
  const r = ha(e, "~"), i = ha(t, "~");
  return r === 1 && i === 1;
}, "shouldCombineSets"), p0 = /* @__PURE__ */ p((e) => {
  const t = ha(e, "~");
  let r = !1;
  if (t <= 1)
    return e;
  t % 2 !== 0 && e.startsWith("~") && (e = e.substring(1), r = !0);
  const i = [...e];
  let s = i.indexOf("~"), o = i.lastIndexOf("~");
  for (; s !== -1 && o !== -1 && s !== o; )
    i[s] = "<", i[o] = ">", s = i.indexOf("~"), o = i.lastIndexOf("~");
  return r && i.unshift("~"), i.join("");
}, "processSet"), Yl = /* @__PURE__ */ p(() => window.MathMLElement !== void 0, "isMathMLSupported"), ca = /\$\$(.*)\$\$/g, Fi = /* @__PURE__ */ p((e) => (e.match(ca)?.length ?? 0) > 0, "hasKatex"), Cv = /* @__PURE__ */ p(async (e, t) => {
  const r = document.createElement("div");
  r.innerHTML = await Ac(e, t), r.id = "katex-temp", r.style.visibility = "hidden", r.style.position = "absolute", r.style.top = "0", document.querySelector("body")?.insertAdjacentElement("beforeend", r);
  const s = { width: r.clientWidth, height: r.clientHeight };
  return r.remove(), s;
}, "calculateMathMLDimensions"), g0 = /* @__PURE__ */ p(async (e, t) => {
  if (!Fi(e))
    return e;
  if (!(Yl() || t.legacyMathML || t.forceLegacyMathML))
    return e.replace(ca, "MathML is unsupported in this environment.");
  {
    const { default: r } = await import("./katex-DoRnZ_sp.js"), i = t.forceLegacyMathML || !Yl() && t.legacyMathML ? "htmlAndMathml" : "mathml";
    return e.split(Wi).map(
      (s) => Fi(s) ? `<div style="display: flex; align-items: center; justify-content: center; white-space: nowrap;">${s}</div>` : `<div>${s}</div>`
    ).join("").replace(
      ca,
      (s, o) => r.renderToString(o, {
        throwOnError: !0,
        displayMode: !0,
        output: i
      }).replace(/\n/g, " ").replace(/<annotation.*<\/annotation>/g, "")
    );
  }
}, "renderKatexUnsanitized"), Ac = /* @__PURE__ */ p(async (e, t) => me(await g0(e, t), t), "renderKatexSanitized"), zi = {
  getRows: s0,
  sanitizeText: me,
  sanitizeTextOrArray: a0,
  hasBreaks: n0,
  splitBreaks: l0,
  lineBreakRegex: Wi,
  removeScript: Lc,
  getUrl: c0,
  evaluate: ze,
  getMax: d0,
  getMin: u0
}, m0 = /* @__PURE__ */ p(function(e, t) {
  for (let r of t)
    e.attr(r[0], r[1]);
}, "d3Attrs"), y0 = /* @__PURE__ */ p(function(e, t, r) {
  let i = /* @__PURE__ */ new Map();
  return r ? (i.set("width", "100%"), i.set("style", `max-width: ${t}px;`)) : (i.set("height", e), i.set("width", t)), i;
}, "calculateSvgSizeAttrs"), Mc = /* @__PURE__ */ p(function(e, t, r, i) {
  const s = y0(t, r, i);
  m0(e, s);
}, "configureSvgSize"), C0 = /* @__PURE__ */ p(function(e, t, r, i) {
  const s = t.node().getBBox(), o = s.width, a = s.height;
  P.info(`SVG bounds: ${o}x${a}`, s);
  let n = 0, l = 0;
  P.info(`Graph bounds: ${n}x${l}`, e), n = o + r * 2, l = a + r * 2, P.info(`Calculated bounds: ${n}x${l}`), Mc(t, l, n, i);
  const c = `${s.x - r} ${s.y - r} ${s.width + 2 * r} ${s.height + 2 * r}`;
  t.attr("viewBox", c);
}, "setupGraphViewbox"), ys = {};
function da(e) {
  return [...e.cssRules].map((t) => t.cssText).join(`
`);
}
p(da, "cssStyleSheetToString");
var x0 = /* @__PURE__ */ p((e, t, r, i) => {
  let s = "";
  return e in ys && ys[e] ? s = ys[e]({ ...r, svgId: i }) : P.warn(`No theme found for ${e}`), ` & {
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
}, "getStyles"), b0 = /* @__PURE__ */ p((e, t) => {
  t !== void 0 && (ys[e] = t);
}, "addStylesForDiagram"), k0 = x0, Ec = {};
Ym(Ec, {
  clear: () => w0,
  getAccDescription: () => B0,
  getAccTitle: () => S0,
  getDiagramTitle: () => L0,
  setAccDescription: () => _0,
  setAccTitle: () => T0,
  setDiagramTitle: () => v0
});
var ln = "", hn = "", cn = "", dn = /* @__PURE__ */ p((e) => me(e, Tt()), "sanitizeText"), w0 = /* @__PURE__ */ p(() => {
  ln = "", cn = "", hn = "";
}, "clear"), T0 = /* @__PURE__ */ p((e) => {
  ln = dn(e).replace(/^\s+/g, "");
}, "setAccTitle"), S0 = /* @__PURE__ */ p(() => ln, "getAccTitle"), _0 = /* @__PURE__ */ p((e) => {
  cn = dn(e).replace(/\n\s+/g, `
`);
}, "setAccDescription"), B0 = /* @__PURE__ */ p(() => cn, "getAccDescription"), v0 = /* @__PURE__ */ p((e) => {
  hn = dn(e);
}, "setDiagramTitle"), L0 = /* @__PURE__ */ p(() => hn, "getDiagramTitle"), Ul = P, F0 = an, gt = Tt, xv = Tc, bv = Gr, un = /* @__PURE__ */ p((e) => me(e, gt()), "sanitizeText"), A0 = C0, M0 = /* @__PURE__ */ p(() => Ec, "getCommonDb"), Es = {}, $s = /* @__PURE__ */ p((e, t, r) => {
  Es[e] && Ul.warn(`Diagram with id ${e} already registered. Overwriting.`), Es[e] = t, r && yc(e, r), b0(e, t.styles), t.injectUtils?.(
    Ul,
    F0,
    gt,
    un,
    A0,
    M0(),
    () => {
    }
  );
}, "registerDiagram"), ua = /* @__PURE__ */ p((e) => {
  if (e in Es)
    return Es[e];
  throw new E0(e);
}, "getDiagram"), E0 = class extends Error {
  static {
    p(this, "DiagramNotFoundError");
  }
  constructor(e) {
    super(`Diagram ${e} not found.`);
  }
}, $0 = { value: () => {
} };
function $c() {
  for (var e = 0, t = arguments.length, r = {}, i; e < t; ++e) {
    if (!(i = arguments[e] + "") || i in r || /[\s.]/.test(i)) throw new Error("illegal type: " + i);
    r[i] = [];
  }
  return new Cs(r);
}
function Cs(e) {
  this._ = e;
}
function O0(e, t) {
  return e.trim().split(/^|\s+/).map(function(r) {
    var i = "", s = r.indexOf(".");
    if (s >= 0 && (i = r.slice(s + 1), r = r.slice(0, s)), r && !t.hasOwnProperty(r)) throw new Error("unknown type: " + r);
    return { type: r, name: i };
  });
}
Cs.prototype = $c.prototype = {
  constructor: Cs,
  on: function(e, t) {
    var r = this._, i = O0(e + "", r), s, o = -1, a = i.length;
    if (arguments.length < 2) {
      for (; ++o < a; ) if ((s = (e = i[o]).type) && (s = I0(r[s], e.name))) return s;
      return;
    }
    if (t != null && typeof t != "function") throw new Error("invalid callback: " + t);
    for (; ++o < a; )
      if (s = (e = i[o]).type) r[s] = Gl(r[s], e.name, t);
      else if (t == null) for (s in r) r[s] = Gl(r[s], e.name, null);
    return this;
  },
  copy: function() {
    var e = {}, t = this._;
    for (var r in t) e[r] = t[r].slice();
    return new Cs(e);
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
function I0(e, t) {
  for (var r = 0, i = e.length, s; r < i; ++r)
    if ((s = e[r]).name === t)
      return s.value;
}
function Gl(e, t, r) {
  for (var i = 0, s = e.length; i < s; ++i)
    if (e[i].name === t) {
      e[i] = $0, e = e.slice(0, i).concat(e.slice(i + 1));
      break;
    }
  return r != null && e.push({ name: t, value: r }), e;
}
var fa = "http://www.w3.org/1999/xhtml";
const jl = {
  svg: "http://www.w3.org/2000/svg",
  xhtml: fa,
  xlink: "http://www.w3.org/1999/xlink",
  xml: "http://www.w3.org/XML/1998/namespace",
  xmlns: "http://www.w3.org/2000/xmlns/"
};
function lo(e) {
  var t = e += "", r = t.indexOf(":");
  return r >= 0 && (t = e.slice(0, r)) !== "xmlns" && (e = e.slice(r + 1)), jl.hasOwnProperty(t) ? { space: jl[t], local: e } : e;
}
function D0(e) {
  return function() {
    var t = this.ownerDocument, r = this.namespaceURI;
    return r === fa && t.documentElement.namespaceURI === fa ? t.createElement(e) : t.createElementNS(r, e);
  };
}
function R0(e) {
  return function() {
    return this.ownerDocument.createElementNS(e.space, e.local);
  };
}
function Oc(e) {
  var t = lo(e);
  return (t.local ? R0 : D0)(t);
}
function P0() {
}
function fn(e) {
  return e == null ? P0 : function() {
    return this.querySelector(e);
  };
}
function N0(e) {
  typeof e != "function" && (e = fn(e));
  for (var t = this._groups, r = t.length, i = new Array(r), s = 0; s < r; ++s)
    for (var o = t[s], a = o.length, n = i[s] = new Array(a), l, c, h = 0; h < a; ++h)
      (l = o[h]) && (c = e.call(l, l.__data__, h, o)) && ("__data__" in l && (c.__data__ = l.__data__), n[h] = c);
  return new ie(i, this._parents);
}
function q0(e) {
  return e == null ? [] : Array.isArray(e) ? e : Array.from(e);
}
function W0() {
  return [];
}
function Ic(e) {
  return e == null ? W0 : function() {
    return this.querySelectorAll(e);
  };
}
function z0(e) {
  return function() {
    return q0(e.apply(this, arguments));
  };
}
function H0(e) {
  typeof e == "function" ? e = z0(e) : e = Ic(e);
  for (var t = this._groups, r = t.length, i = [], s = [], o = 0; o < r; ++o)
    for (var a = t[o], n = a.length, l, c = 0; c < n; ++c)
      (l = a[c]) && (i.push(e.call(l, l.__data__, c, a)), s.push(l));
  return new ie(i, s);
}
function Dc(e) {
  return function() {
    return this.matches(e);
  };
}
function Rc(e) {
  return function(t) {
    return t.matches(e);
  };
}
var Y0 = Array.prototype.find;
function U0(e) {
  return function() {
    return Y0.call(this.children, e);
  };
}
function G0() {
  return this.firstElementChild;
}
function j0(e) {
  return this.select(e == null ? G0 : U0(typeof e == "function" ? e : Rc(e)));
}
var X0 = Array.prototype.filter;
function V0() {
  return Array.from(this.children);
}
function Z0(e) {
  return function() {
    return X0.call(this.children, e);
  };
}
function K0(e) {
  return this.selectAll(e == null ? V0 : Z0(typeof e == "function" ? e : Rc(e)));
}
function Q0(e) {
  typeof e != "function" && (e = Dc(e));
  for (var t = this._groups, r = t.length, i = new Array(r), s = 0; s < r; ++s)
    for (var o = t[s], a = o.length, n = i[s] = [], l, c = 0; c < a; ++c)
      (l = o[c]) && e.call(l, l.__data__, c, o) && n.push(l);
  return new ie(i, this._parents);
}
function Pc(e) {
  return new Array(e.length);
}
function J0() {
  return new ie(this._enter || this._groups.map(Pc), this._parents);
}
function Os(e, t) {
  this.ownerDocument = e.ownerDocument, this.namespaceURI = e.namespaceURI, this._next = null, this._parent = e, this.__data__ = t;
}
Os.prototype = {
  constructor: Os,
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
function tC(e) {
  return function() {
    return e;
  };
}
function eC(e, t, r, i, s, o) {
  for (var a = 0, n, l = t.length, c = o.length; a < c; ++a)
    (n = t[a]) ? (n.__data__ = o[a], i[a] = n) : r[a] = new Os(e, o[a]);
  for (; a < l; ++a)
    (n = t[a]) && (s[a] = n);
}
function rC(e, t, r, i, s, o, a) {
  var n, l, c = /* @__PURE__ */ new Map(), h = t.length, d = o.length, f = new Array(h), u;
  for (n = 0; n < h; ++n)
    (l = t[n]) && (f[n] = u = a.call(l, l.__data__, n, t) + "", c.has(u) ? s[n] = l : c.set(u, l));
  for (n = 0; n < d; ++n)
    u = a.call(e, o[n], n, o) + "", (l = c.get(u)) ? (i[n] = l, l.__data__ = o[n], c.delete(u)) : r[n] = new Os(e, o[n]);
  for (n = 0; n < h; ++n)
    (l = t[n]) && c.get(f[n]) === l && (s[n] = l);
}
function iC(e) {
  return e.__data__;
}
function sC(e, t) {
  if (!arguments.length) return Array.from(this, iC);
  var r = t ? rC : eC, i = this._parents, s = this._groups;
  typeof e != "function" && (e = tC(e));
  for (var o = s.length, a = new Array(o), n = new Array(o), l = new Array(o), c = 0; c < o; ++c) {
    var h = i[c], d = s[c], f = d.length, u = oC(e.call(h, h && h.__data__, c, i)), g = u.length, m = n[c] = new Array(g), y = a[c] = new Array(g), C = l[c] = new Array(f);
    r(h, d, m, y, C, u, t);
    for (var b = 0, k = 0, T, S; b < g; ++b)
      if (T = m[b]) {
        for (b >= k && (k = b + 1); !(S = y[k]) && ++k < g; ) ;
        T._next = S || null;
      }
  }
  return a = new ie(a, i), a._enter = n, a._exit = l, a;
}
function oC(e) {
  return typeof e == "object" && "length" in e ? e : Array.from(e);
}
function aC() {
  return new ie(this._exit || this._groups.map(Pc), this._parents);
}
function nC(e, t, r) {
  var i = this.enter(), s = this, o = this.exit();
  return typeof e == "function" ? (i = e(i), i && (i = i.selection())) : i = i.append(e + ""), t != null && (s = t(s), s && (s = s.selection())), r == null ? o.remove() : r(o), i && s ? i.merge(s).order() : s;
}
function lC(e) {
  for (var t = e.selection ? e.selection() : e, r = this._groups, i = t._groups, s = r.length, o = i.length, a = Math.min(s, o), n = new Array(s), l = 0; l < a; ++l)
    for (var c = r[l], h = i[l], d = c.length, f = n[l] = new Array(d), u, g = 0; g < d; ++g)
      (u = c[g] || h[g]) && (f[g] = u);
  for (; l < s; ++l)
    n[l] = r[l];
  return new ie(n, this._parents);
}
function hC() {
  for (var e = this._groups, t = -1, r = e.length; ++t < r; )
    for (var i = e[t], s = i.length - 1, o = i[s], a; --s >= 0; )
      (a = i[s]) && (o && a.compareDocumentPosition(o) ^ 4 && o.parentNode.insertBefore(a, o), o = a);
  return this;
}
function cC(e) {
  e || (e = dC);
  function t(d, f) {
    return d && f ? e(d.__data__, f.__data__) : !d - !f;
  }
  for (var r = this._groups, i = r.length, s = new Array(i), o = 0; o < i; ++o) {
    for (var a = r[o], n = a.length, l = s[o] = new Array(n), c, h = 0; h < n; ++h)
      (c = a[h]) && (l[h] = c);
    l.sort(t);
  }
  return new ie(s, this._parents).order();
}
function dC(e, t) {
  return e < t ? -1 : e > t ? 1 : e >= t ? 0 : NaN;
}
function uC() {
  var e = arguments[0];
  return arguments[0] = this, e.apply(null, arguments), this;
}
function fC() {
  return Array.from(this);
}
function pC() {
  for (var e = this._groups, t = 0, r = e.length; t < r; ++t)
    for (var i = e[t], s = 0, o = i.length; s < o; ++s) {
      var a = i[s];
      if (a) return a;
    }
  return null;
}
function gC() {
  let e = 0;
  for (const t of this) ++e;
  return e;
}
function mC() {
  return !this.node();
}
function yC(e) {
  for (var t = this._groups, r = 0, i = t.length; r < i; ++r)
    for (var s = t[r], o = 0, a = s.length, n; o < a; ++o)
      (n = s[o]) && e.call(n, n.__data__, o, s);
  return this;
}
function CC(e) {
  return function() {
    this.removeAttribute(e);
  };
}
function xC(e) {
  return function() {
    this.removeAttributeNS(e.space, e.local);
  };
}
function bC(e, t) {
  return function() {
    this.setAttribute(e, t);
  };
}
function kC(e, t) {
  return function() {
    this.setAttributeNS(e.space, e.local, t);
  };
}
function wC(e, t) {
  return function() {
    var r = t.apply(this, arguments);
    r == null ? this.removeAttribute(e) : this.setAttribute(e, r);
  };
}
function TC(e, t) {
  return function() {
    var r = t.apply(this, arguments);
    r == null ? this.removeAttributeNS(e.space, e.local) : this.setAttributeNS(e.space, e.local, r);
  };
}
function SC(e, t) {
  var r = lo(e);
  if (arguments.length < 2) {
    var i = this.node();
    return r.local ? i.getAttributeNS(r.space, r.local) : i.getAttribute(r);
  }
  return this.each((t == null ? r.local ? xC : CC : typeof t == "function" ? r.local ? TC : wC : r.local ? kC : bC)(r, t));
}
function Nc(e) {
  return e.ownerDocument && e.ownerDocument.defaultView || e.document && e || e.defaultView;
}
function _C(e) {
  return function() {
    this.style.removeProperty(e);
  };
}
function BC(e, t, r) {
  return function() {
    this.style.setProperty(e, t, r);
  };
}
function vC(e, t, r) {
  return function() {
    var i = t.apply(this, arguments);
    i == null ? this.style.removeProperty(e) : this.style.setProperty(e, i, r);
  };
}
function LC(e, t, r) {
  return arguments.length > 1 ? this.each((t == null ? _C : typeof t == "function" ? vC : BC)(e, t, r ?? "")) : jr(this.node(), e);
}
function jr(e, t) {
  return e.style.getPropertyValue(t) || Nc(e).getComputedStyle(e, null).getPropertyValue(t);
}
function FC(e) {
  return function() {
    delete this[e];
  };
}
function AC(e, t) {
  return function() {
    this[e] = t;
  };
}
function MC(e, t) {
  return function() {
    var r = t.apply(this, arguments);
    r == null ? delete this[e] : this[e] = r;
  };
}
function EC(e, t) {
  return arguments.length > 1 ? this.each((t == null ? FC : typeof t == "function" ? MC : AC)(e, t)) : this.node()[e];
}
function qc(e) {
  return e.trim().split(/^|\s+/);
}
function pn(e) {
  return e.classList || new Wc(e);
}
function Wc(e) {
  this._node = e, this._names = qc(e.getAttribute("class") || "");
}
Wc.prototype = {
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
function zc(e, t) {
  for (var r = pn(e), i = -1, s = t.length; ++i < s; ) r.add(t[i]);
}
function Hc(e, t) {
  for (var r = pn(e), i = -1, s = t.length; ++i < s; ) r.remove(t[i]);
}
function $C(e) {
  return function() {
    zc(this, e);
  };
}
function OC(e) {
  return function() {
    Hc(this, e);
  };
}
function IC(e, t) {
  return function() {
    (t.apply(this, arguments) ? zc : Hc)(this, e);
  };
}
function DC(e, t) {
  var r = qc(e + "");
  if (arguments.length < 2) {
    for (var i = pn(this.node()), s = -1, o = r.length; ++s < o; ) if (!i.contains(r[s])) return !1;
    return !0;
  }
  return this.each((typeof t == "function" ? IC : t ? $C : OC)(r, t));
}
function RC() {
  this.textContent = "";
}
function PC(e) {
  return function() {
    this.textContent = e;
  };
}
function NC(e) {
  return function() {
    var t = e.apply(this, arguments);
    this.textContent = t ?? "";
  };
}
function qC(e) {
  return arguments.length ? this.each(e == null ? RC : (typeof e == "function" ? NC : PC)(e)) : this.node().textContent;
}
function WC() {
  this.innerHTML = "";
}
function zC(e) {
  return function() {
    this.innerHTML = e;
  };
}
function HC(e) {
  return function() {
    var t = e.apply(this, arguments);
    this.innerHTML = t ?? "";
  };
}
function YC(e) {
  return arguments.length ? this.each(e == null ? WC : (typeof e == "function" ? HC : zC)(e)) : this.node().innerHTML;
}
function UC() {
  this.nextSibling && this.parentNode.appendChild(this);
}
function GC() {
  return this.each(UC);
}
function jC() {
  this.previousSibling && this.parentNode.insertBefore(this, this.parentNode.firstChild);
}
function XC() {
  return this.each(jC);
}
function VC(e) {
  var t = typeof e == "function" ? e : Oc(e);
  return this.select(function() {
    return this.appendChild(t.apply(this, arguments));
  });
}
function ZC() {
  return null;
}
function KC(e, t) {
  var r = typeof e == "function" ? e : Oc(e), i = t == null ? ZC : typeof t == "function" ? t : fn(t);
  return this.select(function() {
    return this.insertBefore(r.apply(this, arguments), i.apply(this, arguments) || null);
  });
}
function QC() {
  var e = this.parentNode;
  e && e.removeChild(this);
}
function JC() {
  return this.each(QC);
}
function tx() {
  var e = this.cloneNode(!1), t = this.parentNode;
  return t ? t.insertBefore(e, this.nextSibling) : e;
}
function ex() {
  var e = this.cloneNode(!0), t = this.parentNode;
  return t ? t.insertBefore(e, this.nextSibling) : e;
}
function rx(e) {
  return this.select(e ? ex : tx);
}
function ix(e) {
  return arguments.length ? this.property("__data__", e) : this.node().__data__;
}
function sx(e) {
  return function(t) {
    e.call(this, t, this.__data__);
  };
}
function ox(e) {
  return e.trim().split(/^|\s+/).map(function(t) {
    var r = "", i = t.indexOf(".");
    return i >= 0 && (r = t.slice(i + 1), t = t.slice(0, i)), { type: t, name: r };
  });
}
function ax(e) {
  return function() {
    var t = this.__on;
    if (t) {
      for (var r = 0, i = -1, s = t.length, o; r < s; ++r)
        o = t[r], (!e.type || o.type === e.type) && o.name === e.name ? this.removeEventListener(o.type, o.listener, o.options) : t[++i] = o;
      ++i ? t.length = i : delete this.__on;
    }
  };
}
function nx(e, t, r) {
  return function() {
    var i = this.__on, s, o = sx(t);
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
function lx(e, t, r) {
  var i = ox(e + ""), s, o = i.length, a;
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
  for (n = t ? nx : ax, s = 0; s < o; ++s) this.each(n(i[s], t, r));
  return this;
}
function Yc(e, t, r) {
  var i = Nc(e), s = i.CustomEvent;
  typeof s == "function" ? s = new s(t, r) : (s = i.document.createEvent("Event"), r ? (s.initEvent(t, r.bubbles, r.cancelable), s.detail = r.detail) : s.initEvent(t, !1, !1)), e.dispatchEvent(s);
}
function hx(e, t) {
  return function() {
    return Yc(this, e, t);
  };
}
function cx(e, t) {
  return function() {
    return Yc(this, e, t.apply(this, arguments));
  };
}
function dx(e, t) {
  return this.each((typeof t == "function" ? cx : hx)(e, t));
}
function* ux() {
  for (var e = this._groups, t = 0, r = e.length; t < r; ++t)
    for (var i = e[t], s = 0, o = i.length, a; s < o; ++s)
      (a = i[s]) && (yield a);
}
var Uc = [null];
function ie(e, t) {
  this._groups = e, this._parents = t;
}
function Hi() {
  return new ie([[document.documentElement]], Uc);
}
function fx() {
  return this;
}
ie.prototype = Hi.prototype = {
  constructor: ie,
  select: N0,
  selectAll: H0,
  selectChild: j0,
  selectChildren: K0,
  filter: Q0,
  data: sC,
  enter: J0,
  exit: aC,
  join: nC,
  merge: lC,
  selection: fx,
  order: hC,
  sort: cC,
  call: uC,
  nodes: fC,
  node: pC,
  size: gC,
  empty: mC,
  each: yC,
  attr: SC,
  style: LC,
  property: EC,
  classed: DC,
  text: qC,
  html: YC,
  raise: GC,
  lower: XC,
  append: VC,
  insert: KC,
  remove: JC,
  clone: rx,
  datum: ix,
  on: lx,
  dispatch: dx,
  [Symbol.iterator]: ux
};
function ht(e) {
  return typeof e == "string" ? new ie([[document.querySelector(e)]], [document.documentElement]) : new ie([[e]], Uc);
}
function gn(e, t, r) {
  e.prototype = t.prototype = r, r.constructor = e;
}
function Gc(e, t) {
  var r = Object.create(e.prototype);
  for (var i in t) r[i] = t[i];
  return r;
}
function Yi() {
}
var Ai = 0.7, Is = 1 / Ai, Hr = "\\s*([+-]?\\d+)\\s*", Mi = "\\s*([+-]?(?:\\d*\\.)?\\d+(?:[eE][+-]?\\d+)?)\\s*", Se = "\\s*([+-]?(?:\\d*\\.)?\\d+(?:[eE][+-]?\\d+)?)%\\s*", px = /^#([0-9a-f]{3,8})$/, gx = new RegExp(`^rgb\\(${Hr},${Hr},${Hr}\\)$`), mx = new RegExp(`^rgb\\(${Se},${Se},${Se}\\)$`), yx = new RegExp(`^rgba\\(${Hr},${Hr},${Hr},${Mi}\\)$`), Cx = new RegExp(`^rgba\\(${Se},${Se},${Se},${Mi}\\)$`), xx = new RegExp(`^hsl\\(${Mi},${Se},${Se}\\)$`), bx = new RegExp(`^hsla\\(${Mi},${Se},${Se},${Mi}\\)$`), Xl = {
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
gn(Yi, Ei, {
  copy(e) {
    return Object.assign(new this.constructor(), this, e);
  },
  displayable() {
    return this.rgb().displayable();
  },
  hex: Vl,
  // Deprecated! Use color.formatHex.
  formatHex: Vl,
  formatHex8: kx,
  formatHsl: wx,
  formatRgb: Zl,
  toString: Zl
});
function Vl() {
  return this.rgb().formatHex();
}
function kx() {
  return this.rgb().formatHex8();
}
function wx() {
  return jc(this).formatHsl();
}
function Zl() {
  return this.rgb().formatRgb();
}
function Ei(e) {
  var t, r;
  return e = (e + "").trim().toLowerCase(), (t = px.exec(e)) ? (r = t[1].length, t = parseInt(t[1], 16), r === 6 ? Kl(t) : r === 3 ? new ee(t >> 8 & 15 | t >> 4 & 240, t >> 4 & 15 | t & 240, (t & 15) << 4 | t & 15, 1) : r === 8 ? ss(t >> 24 & 255, t >> 16 & 255, t >> 8 & 255, (t & 255) / 255) : r === 4 ? ss(t >> 12 & 15 | t >> 8 & 240, t >> 8 & 15 | t >> 4 & 240, t >> 4 & 15 | t & 240, ((t & 15) << 4 | t & 15) / 255) : null) : (t = gx.exec(e)) ? new ee(t[1], t[2], t[3], 1) : (t = mx.exec(e)) ? new ee(t[1] * 255 / 100, t[2] * 255 / 100, t[3] * 255 / 100, 1) : (t = yx.exec(e)) ? ss(t[1], t[2], t[3], t[4]) : (t = Cx.exec(e)) ? ss(t[1] * 255 / 100, t[2] * 255 / 100, t[3] * 255 / 100, t[4]) : (t = xx.exec(e)) ? th(t[1], t[2] / 100, t[3] / 100, 1) : (t = bx.exec(e)) ? th(t[1], t[2] / 100, t[3] / 100, t[4]) : Xl.hasOwnProperty(e) ? Kl(Xl[e]) : e === "transparent" ? new ee(NaN, NaN, NaN, 0) : null;
}
function Kl(e) {
  return new ee(e >> 16 & 255, e >> 8 & 255, e & 255, 1);
}
function ss(e, t, r, i) {
  return i <= 0 && (e = t = r = NaN), new ee(e, t, r, i);
}
function Tx(e) {
  return e instanceof Yi || (e = Ei(e)), e ? (e = e.rgb(), new ee(e.r, e.g, e.b, e.opacity)) : new ee();
}
function pa(e, t, r, i) {
  return arguments.length === 1 ? Tx(e) : new ee(e, t, r, i ?? 1);
}
function ee(e, t, r, i) {
  this.r = +e, this.g = +t, this.b = +r, this.opacity = +i;
}
gn(ee, pa, Gc(Yi, {
  brighter(e) {
    return e = e == null ? Is : Math.pow(Is, e), new ee(this.r * e, this.g * e, this.b * e, this.opacity);
  },
  darker(e) {
    return e = e == null ? Ai : Math.pow(Ai, e), new ee(this.r * e, this.g * e, this.b * e, this.opacity);
  },
  rgb() {
    return this;
  },
  clamp() {
    return new ee(gr(this.r), gr(this.g), gr(this.b), Ds(this.opacity));
  },
  displayable() {
    return -0.5 <= this.r && this.r < 255.5 && -0.5 <= this.g && this.g < 255.5 && -0.5 <= this.b && this.b < 255.5 && 0 <= this.opacity && this.opacity <= 1;
  },
  hex: Ql,
  // Deprecated! Use color.formatHex.
  formatHex: Ql,
  formatHex8: Sx,
  formatRgb: Jl,
  toString: Jl
}));
function Ql() {
  return `#${ur(this.r)}${ur(this.g)}${ur(this.b)}`;
}
function Sx() {
  return `#${ur(this.r)}${ur(this.g)}${ur(this.b)}${ur((isNaN(this.opacity) ? 1 : this.opacity) * 255)}`;
}
function Jl() {
  const e = Ds(this.opacity);
  return `${e === 1 ? "rgb(" : "rgba("}${gr(this.r)}, ${gr(this.g)}, ${gr(this.b)}${e === 1 ? ")" : `, ${e})`}`;
}
function Ds(e) {
  return isNaN(e) ? 1 : Math.max(0, Math.min(1, e));
}
function gr(e) {
  return Math.max(0, Math.min(255, Math.round(e) || 0));
}
function ur(e) {
  return e = gr(e), (e < 16 ? "0" : "") + e.toString(16);
}
function th(e, t, r, i) {
  return i <= 0 ? e = t = r = NaN : r <= 0 || r >= 1 ? e = t = NaN : t <= 0 && (e = NaN), new ue(e, t, r, i);
}
function jc(e) {
  if (e instanceof ue) return new ue(e.h, e.s, e.l, e.opacity);
  if (e instanceof Yi || (e = Ei(e)), !e) return new ue();
  if (e instanceof ue) return e;
  e = e.rgb();
  var t = e.r / 255, r = e.g / 255, i = e.b / 255, s = Math.min(t, r, i), o = Math.max(t, r, i), a = NaN, n = o - s, l = (o + s) / 2;
  return n ? (t === o ? a = (r - i) / n + (r < i) * 6 : r === o ? a = (i - t) / n + 2 : a = (t - r) / n + 4, n /= l < 0.5 ? o + s : 2 - o - s, a *= 60) : n = l > 0 && l < 1 ? 0 : a, new ue(a, n, l, e.opacity);
}
function _x(e, t, r, i) {
  return arguments.length === 1 ? jc(e) : new ue(e, t, r, i ?? 1);
}
function ue(e, t, r, i) {
  this.h = +e, this.s = +t, this.l = +r, this.opacity = +i;
}
gn(ue, _x, Gc(Yi, {
  brighter(e) {
    return e = e == null ? Is : Math.pow(Is, e), new ue(this.h, this.s, this.l * e, this.opacity);
  },
  darker(e) {
    return e = e == null ? Ai : Math.pow(Ai, e), new ue(this.h, this.s, this.l * e, this.opacity);
  },
  rgb() {
    var e = this.h % 360 + (this.h < 0) * 360, t = isNaN(e) || isNaN(this.s) ? 0 : this.s, r = this.l, i = r + (r < 0.5 ? r : 1 - r) * t, s = 2 * r - i;
    return new ee(
      Yo(e >= 240 ? e - 240 : e + 120, s, i),
      Yo(e, s, i),
      Yo(e < 120 ? e + 240 : e - 120, s, i),
      this.opacity
    );
  },
  clamp() {
    return new ue(eh(this.h), os(this.s), os(this.l), Ds(this.opacity));
  },
  displayable() {
    return (0 <= this.s && this.s <= 1 || isNaN(this.s)) && 0 <= this.l && this.l <= 1 && 0 <= this.opacity && this.opacity <= 1;
  },
  formatHsl() {
    const e = Ds(this.opacity);
    return `${e === 1 ? "hsl(" : "hsla("}${eh(this.h)}, ${os(this.s) * 100}%, ${os(this.l) * 100}%${e === 1 ? ")" : `, ${e})`}`;
  }
}));
function eh(e) {
  return e = (e || 0) % 360, e < 0 ? e + 360 : e;
}
function os(e) {
  return Math.max(0, Math.min(1, e || 0));
}
function Yo(e, t, r) {
  return (e < 60 ? t + (r - t) * e / 60 : e < 180 ? r : e < 240 ? t + (r - t) * (240 - e) / 60 : t) * 255;
}
const mn = (e) => () => e;
function Xc(e, t) {
  return function(r) {
    return e + r * t;
  };
}
function Bx(e, t, r) {
  return e = Math.pow(e, r), t = Math.pow(t, r) - e, r = 1 / r, function(i) {
    return Math.pow(e + i * t, r);
  };
}
function kv(e, t) {
  var r = t - e;
  return r ? Xc(e, r > 180 || r < -180 ? r - 360 * Math.round(r / 360) : r) : mn(isNaN(e) ? t : e);
}
function vx(e) {
  return (e = +e) == 1 ? Vc : function(t, r) {
    return r - t ? Bx(t, r, e) : mn(isNaN(t) ? r : t);
  };
}
function Vc(e, t) {
  var r = t - e;
  return r ? Xc(e, r) : mn(isNaN(e) ? t : e);
}
const rh = (function e(t) {
  var r = vx(t);
  function i(s, o) {
    var a = r((s = pa(s)).r, (o = pa(o)).r), n = r(s.g, o.g), l = r(s.b, o.b), c = Vc(s.opacity, o.opacity);
    return function(h) {
      return s.r = a(h), s.g = n(h), s.b = l(h), s.opacity = c(h), s + "";
    };
  }
  return i.gamma = e, i;
})(1);
function Xe(e, t) {
  return e = +e, t = +t, function(r) {
    return e * (1 - r) + t * r;
  };
}
var ga = /[-+]?(?:\d+\.?\d*|\.?\d+)(?:[eE][-+]?\d+)?/g, Uo = new RegExp(ga.source, "g");
function Lx(e) {
  return function() {
    return e;
  };
}
function Fx(e) {
  return function(t) {
    return e(t) + "";
  };
}
function Ax(e, t) {
  var r = ga.lastIndex = Uo.lastIndex = 0, i, s, o, a = -1, n = [], l = [];
  for (e = e + "", t = t + ""; (i = ga.exec(e)) && (s = Uo.exec(t)); )
    (o = s.index) > r && (o = t.slice(r, o), n[a] ? n[a] += o : n[++a] = o), (i = i[0]) === (s = s[0]) ? n[a] ? n[a] += s : n[++a] = s : (n[++a] = null, l.push({ i: a, x: Xe(i, s) })), r = Uo.lastIndex;
  return r < t.length && (o = t.slice(r), n[a] ? n[a] += o : n[++a] = o), n.length < 2 ? l[0] ? Fx(l[0].x) : Lx(t) : (t = l.length, function(c) {
    for (var h = 0, d; h < t; ++h) n[(d = l[h]).i] = d.x(c);
    return n.join("");
  });
}
var ih = 180 / Math.PI, ma = {
  translateX: 0,
  translateY: 0,
  rotate: 0,
  skewX: 0,
  scaleX: 1,
  scaleY: 1
};
function Zc(e, t, r, i, s, o) {
  var a, n, l;
  return (a = Math.sqrt(e * e + t * t)) && (e /= a, t /= a), (l = e * r + t * i) && (r -= e * l, i -= t * l), (n = Math.sqrt(r * r + i * i)) && (r /= n, i /= n, l /= n), e * i < t * r && (e = -e, t = -t, l = -l, a = -a), {
    translateX: s,
    translateY: o,
    rotate: Math.atan2(t, e) * ih,
    skewX: Math.atan(l) * ih,
    scaleX: a,
    scaleY: n
  };
}
var as;
function Mx(e) {
  const t = new (typeof DOMMatrix == "function" ? DOMMatrix : WebKitCSSMatrix)(e + "");
  return t.isIdentity ? ma : Zc(t.a, t.b, t.c, t.d, t.e, t.f);
}
function Ex(e) {
  return e == null || (as || (as = document.createElementNS("http://www.w3.org/2000/svg", "g")), as.setAttribute("transform", e), !(e = as.transform.baseVal.consolidate())) ? ma : (e = e.matrix, Zc(e.a, e.b, e.c, e.d, e.e, e.f));
}
function Kc(e, t, r, i) {
  function s(c) {
    return c.length ? c.pop() + " " : "";
  }
  function o(c, h, d, f, u, g) {
    if (c !== d || h !== f) {
      var m = u.push("translate(", null, t, null, r);
      g.push({ i: m - 4, x: Xe(c, d) }, { i: m - 2, x: Xe(h, f) });
    } else (d || f) && u.push("translate(" + d + t + f + r);
  }
  function a(c, h, d, f) {
    c !== h ? (c - h > 180 ? h += 360 : h - c > 180 && (c += 360), f.push({ i: d.push(s(d) + "rotate(", null, i) - 2, x: Xe(c, h) })) : h && d.push(s(d) + "rotate(" + h + i);
  }
  function n(c, h, d, f) {
    c !== h ? f.push({ i: d.push(s(d) + "skewX(", null, i) - 2, x: Xe(c, h) }) : h && d.push(s(d) + "skewX(" + h + i);
  }
  function l(c, h, d, f, u, g) {
    if (c !== d || h !== f) {
      var m = u.push(s(u) + "scale(", null, ",", null, ")");
      g.push({ i: m - 4, x: Xe(c, d) }, { i: m - 2, x: Xe(h, f) });
    } else (d !== 1 || f !== 1) && u.push(s(u) + "scale(" + d + "," + f + ")");
  }
  return function(c, h) {
    var d = [], f = [];
    return c = e(c), h = e(h), o(c.translateX, c.translateY, h.translateX, h.translateY, d, f), a(c.rotate, h.rotate, d, f), n(c.skewX, h.skewX, d, f), l(c.scaleX, c.scaleY, h.scaleX, h.scaleY, d, f), c = h = null, function(u) {
      for (var g = -1, m = f.length, y; ++g < m; ) d[(y = f[g]).i] = y.x(u);
      return d.join("");
    };
  };
}
var $x = Kc(Mx, "px, ", "px)", "deg)"), Ox = Kc(Ex, ", ", ")", ")"), Xr = 0, mi = 0, ni = 0, Qc = 1e3, Rs, yi, Ps = 0, Cr = 0, ho = 0, $i = typeof performance == "object" && performance.now ? performance : Date, Jc = typeof window == "object" && window.requestAnimationFrame ? window.requestAnimationFrame.bind(window) : function(e) {
  setTimeout(e, 17);
};
function yn() {
  return Cr || (Jc(Ix), Cr = $i.now() + ho);
}
function Ix() {
  Cr = 0;
}
function Ns() {
  this._call = this._time = this._next = null;
}
Ns.prototype = td.prototype = {
  constructor: Ns,
  restart: function(e, t, r) {
    if (typeof e != "function") throw new TypeError("callback is not a function");
    r = (r == null ? yn() : +r) + (t == null ? 0 : +t), !this._next && yi !== this && (yi ? yi._next = this : Rs = this, yi = this), this._call = e, this._time = r, ya();
  },
  stop: function() {
    this._call && (this._call = null, this._time = 1 / 0, ya());
  }
};
function td(e, t, r) {
  var i = new Ns();
  return i.restart(e, t, r), i;
}
function Dx() {
  yn(), ++Xr;
  for (var e = Rs, t; e; )
    (t = Cr - e._time) >= 0 && e._call.call(void 0, t), e = e._next;
  --Xr;
}
function sh() {
  Cr = (Ps = $i.now()) + ho, Xr = mi = 0;
  try {
    Dx();
  } finally {
    Xr = 0, Px(), Cr = 0;
  }
}
function Rx() {
  var e = $i.now(), t = e - Ps;
  t > Qc && (ho -= t, Ps = e);
}
function Px() {
  for (var e, t = Rs, r, i = 1 / 0; t; )
    t._call ? (i > t._time && (i = t._time), e = t, t = t._next) : (r = t._next, t._next = null, t = e ? e._next = r : Rs = r);
  yi = e, ya(i);
}
function ya(e) {
  if (!Xr) {
    mi && (mi = clearTimeout(mi));
    var t = e - Cr;
    t > 24 ? (e < 1 / 0 && (mi = setTimeout(sh, e - $i.now() - ho)), ni && (ni = clearInterval(ni))) : (ni || (Ps = $i.now(), ni = setInterval(Rx, Qc)), Xr = 1, Jc(sh));
  }
}
function oh(e, t, r) {
  var i = new Ns();
  return t = t == null ? 0 : +t, i.restart((s) => {
    i.stop(), e(s + t);
  }, t, r), i;
}
var Nx = $c("start", "end", "cancel", "interrupt"), qx = [], ed = 0, ah = 1, Ca = 2, xs = 3, nh = 4, xa = 5, bs = 6;
function co(e, t, r, i, s, o) {
  var a = e.__transition;
  if (!a) e.__transition = {};
  else if (r in a) return;
  Wx(e, r, {
    name: t,
    index: i,
    // For context during callback.
    group: s,
    // For context during callback.
    on: Nx,
    tween: qx,
    time: o.time,
    delay: o.delay,
    duration: o.duration,
    ease: o.ease,
    timer: null,
    state: ed
  });
}
function Cn(e, t) {
  var r = Ce(e, t);
  if (r.state > ed) throw new Error("too late; already scheduled");
  return r;
}
function Fe(e, t) {
  var r = Ce(e, t);
  if (r.state > xs) throw new Error("too late; already running");
  return r;
}
function Ce(e, t) {
  var r = e.__transition;
  if (!r || !(r = r[t])) throw new Error("transition not found");
  return r;
}
function Wx(e, t, r) {
  var i = e.__transition, s;
  i[t] = r, r.timer = td(o, 0, r.time);
  function o(c) {
    r.state = ah, r.timer.restart(a, r.delay, r.time), r.delay <= c && a(c - r.delay);
  }
  function a(c) {
    var h, d, f, u;
    if (r.state !== ah) return l();
    for (h in i)
      if (u = i[h], u.name === r.name) {
        if (u.state === xs) return oh(a);
        u.state === nh ? (u.state = bs, u.timer.stop(), u.on.call("interrupt", e, e.__data__, u.index, u.group), delete i[h]) : +h < t && (u.state = bs, u.timer.stop(), u.on.call("cancel", e, e.__data__, u.index, u.group), delete i[h]);
      }
    if (oh(function() {
      r.state === xs && (r.state = nh, r.timer.restart(n, r.delay, r.time), n(c));
    }), r.state = Ca, r.on.call("start", e, e.__data__, r.index, r.group), r.state === Ca) {
      for (r.state = xs, s = new Array(f = r.tween.length), h = 0, d = -1; h < f; ++h)
        (u = r.tween[h].value.call(e, e.__data__, r.index, r.group)) && (s[++d] = u);
      s.length = d + 1;
    }
  }
  function n(c) {
    for (var h = c < r.duration ? r.ease.call(null, c / r.duration) : (r.timer.restart(l), r.state = xa, 1), d = -1, f = s.length; ++d < f; )
      s[d].call(e, h);
    r.state === xa && (r.on.call("end", e, e.__data__, r.index, r.group), l());
  }
  function l() {
    r.state = bs, r.timer.stop(), delete i[t];
    for (var c in i) return;
    delete e.__transition;
  }
}
function zx(e, t) {
  var r = e.__transition, i, s, o = !0, a;
  if (r) {
    t = t == null ? null : t + "";
    for (a in r) {
      if ((i = r[a]).name !== t) {
        o = !1;
        continue;
      }
      s = i.state > Ca && i.state < xa, i.state = bs, i.timer.stop(), i.on.call(s ? "interrupt" : "cancel", e, e.__data__, i.index, i.group), delete r[a];
    }
    o && delete e.__transition;
  }
}
function Hx(e) {
  return this.each(function() {
    zx(this, e);
  });
}
function Yx(e, t) {
  var r, i;
  return function() {
    var s = Fe(this, e), o = s.tween;
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
function Ux(e, t, r) {
  var i, s;
  if (typeof r != "function") throw new Error();
  return function() {
    var o = Fe(this, e), a = o.tween;
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
function Gx(e, t) {
  var r = this._id;
  if (e += "", arguments.length < 2) {
    for (var i = Ce(this.node(), r).tween, s = 0, o = i.length, a; s < o; ++s)
      if ((a = i[s]).name === e)
        return a.value;
    return null;
  }
  return this.each((t == null ? Yx : Ux)(r, e, t));
}
function xn(e, t, r) {
  var i = e._id;
  return e.each(function() {
    var s = Fe(this, i);
    (s.value || (s.value = {}))[t] = r.apply(this, arguments);
  }), function(s) {
    return Ce(s, i).value[t];
  };
}
function rd(e, t) {
  var r;
  return (typeof t == "number" ? Xe : t instanceof Ei ? rh : (r = Ei(t)) ? (t = r, rh) : Ax)(e, t);
}
function jx(e) {
  return function() {
    this.removeAttribute(e);
  };
}
function Xx(e) {
  return function() {
    this.removeAttributeNS(e.space, e.local);
  };
}
function Vx(e, t, r) {
  var i, s = r + "", o;
  return function() {
    var a = this.getAttribute(e);
    return a === s ? null : a === i ? o : o = t(i = a, r);
  };
}
function Zx(e, t, r) {
  var i, s = r + "", o;
  return function() {
    var a = this.getAttributeNS(e.space, e.local);
    return a === s ? null : a === i ? o : o = t(i = a, r);
  };
}
function Kx(e, t, r) {
  var i, s, o;
  return function() {
    var a, n = r(this), l;
    return n == null ? void this.removeAttribute(e) : (a = this.getAttribute(e), l = n + "", a === l ? null : a === i && l === s ? o : (s = l, o = t(i = a, n)));
  };
}
function Qx(e, t, r) {
  var i, s, o;
  return function() {
    var a, n = r(this), l;
    return n == null ? void this.removeAttributeNS(e.space, e.local) : (a = this.getAttributeNS(e.space, e.local), l = n + "", a === l ? null : a === i && l === s ? o : (s = l, o = t(i = a, n)));
  };
}
function Jx(e, t) {
  var r = lo(e), i = r === "transform" ? Ox : rd;
  return this.attrTween(e, typeof t == "function" ? (r.local ? Qx : Kx)(r, i, xn(this, "attr." + e, t)) : t == null ? (r.local ? Xx : jx)(r) : (r.local ? Zx : Vx)(r, i, t));
}
function tb(e, t) {
  return function(r) {
    this.setAttribute(e, t.call(this, r));
  };
}
function eb(e, t) {
  return function(r) {
    this.setAttributeNS(e.space, e.local, t.call(this, r));
  };
}
function rb(e, t) {
  var r, i;
  function s() {
    var o = t.apply(this, arguments);
    return o !== i && (r = (i = o) && eb(e, o)), r;
  }
  return s._value = t, s;
}
function ib(e, t) {
  var r, i;
  function s() {
    var o = t.apply(this, arguments);
    return o !== i && (r = (i = o) && tb(e, o)), r;
  }
  return s._value = t, s;
}
function sb(e, t) {
  var r = "attr." + e;
  if (arguments.length < 2) return (r = this.tween(r)) && r._value;
  if (t == null) return this.tween(r, null);
  if (typeof t != "function") throw new Error();
  var i = lo(e);
  return this.tween(r, (i.local ? rb : ib)(i, t));
}
function ob(e, t) {
  return function() {
    Cn(this, e).delay = +t.apply(this, arguments);
  };
}
function ab(e, t) {
  return t = +t, function() {
    Cn(this, e).delay = t;
  };
}
function nb(e) {
  var t = this._id;
  return arguments.length ? this.each((typeof e == "function" ? ob : ab)(t, e)) : Ce(this.node(), t).delay;
}
function lb(e, t) {
  return function() {
    Fe(this, e).duration = +t.apply(this, arguments);
  };
}
function hb(e, t) {
  return t = +t, function() {
    Fe(this, e).duration = t;
  };
}
function cb(e) {
  var t = this._id;
  return arguments.length ? this.each((typeof e == "function" ? lb : hb)(t, e)) : Ce(this.node(), t).duration;
}
function db(e, t) {
  if (typeof t != "function") throw new Error();
  return function() {
    Fe(this, e).ease = t;
  };
}
function ub(e) {
  var t = this._id;
  return arguments.length ? this.each(db(t, e)) : Ce(this.node(), t).ease;
}
function fb(e, t) {
  return function() {
    var r = t.apply(this, arguments);
    if (typeof r != "function") throw new Error();
    Fe(this, e).ease = r;
  };
}
function pb(e) {
  if (typeof e != "function") throw new Error();
  return this.each(fb(this._id, e));
}
function gb(e) {
  typeof e != "function" && (e = Dc(e));
  for (var t = this._groups, r = t.length, i = new Array(r), s = 0; s < r; ++s)
    for (var o = t[s], a = o.length, n = i[s] = [], l, c = 0; c < a; ++c)
      (l = o[c]) && e.call(l, l.__data__, c, o) && n.push(l);
  return new Ne(i, this._parents, this._name, this._id);
}
function mb(e) {
  if (e._id !== this._id) throw new Error();
  for (var t = this._groups, r = e._groups, i = t.length, s = r.length, o = Math.min(i, s), a = new Array(i), n = 0; n < o; ++n)
    for (var l = t[n], c = r[n], h = l.length, d = a[n] = new Array(h), f, u = 0; u < h; ++u)
      (f = l[u] || c[u]) && (d[u] = f);
  for (; n < i; ++n)
    a[n] = t[n];
  return new Ne(a, this._parents, this._name, this._id);
}
function yb(e) {
  return (e + "").trim().split(/^|\s+/).every(function(t) {
    var r = t.indexOf(".");
    return r >= 0 && (t = t.slice(0, r)), !t || t === "start";
  });
}
function Cb(e, t, r) {
  var i, s, o = yb(t) ? Cn : Fe;
  return function() {
    var a = o(this, e), n = a.on;
    n !== i && (s = (i = n).copy()).on(t, r), a.on = s;
  };
}
function xb(e, t) {
  var r = this._id;
  return arguments.length < 2 ? Ce(this.node(), r).on.on(e) : this.each(Cb(r, e, t));
}
function bb(e) {
  return function() {
    var t = this.parentNode;
    for (var r in this.__transition) if (+r !== e) return;
    t && t.removeChild(this);
  };
}
function kb() {
  return this.on("end.remove", bb(this._id));
}
function wb(e) {
  var t = this._name, r = this._id;
  typeof e != "function" && (e = fn(e));
  for (var i = this._groups, s = i.length, o = new Array(s), a = 0; a < s; ++a)
    for (var n = i[a], l = n.length, c = o[a] = new Array(l), h, d, f = 0; f < l; ++f)
      (h = n[f]) && (d = e.call(h, h.__data__, f, n)) && ("__data__" in h && (d.__data__ = h.__data__), c[f] = d, co(c[f], t, r, f, c, Ce(h, r)));
  return new Ne(o, this._parents, t, r);
}
function Tb(e) {
  var t = this._name, r = this._id;
  typeof e != "function" && (e = Ic(e));
  for (var i = this._groups, s = i.length, o = [], a = [], n = 0; n < s; ++n)
    for (var l = i[n], c = l.length, h, d = 0; d < c; ++d)
      if (h = l[d]) {
        for (var f = e.call(h, h.__data__, d, l), u, g = Ce(h, r), m = 0, y = f.length; m < y; ++m)
          (u = f[m]) && co(u, t, r, m, f, g);
        o.push(f), a.push(h);
      }
  return new Ne(o, a, t, r);
}
var Sb = Hi.prototype.constructor;
function _b() {
  return new Sb(this._groups, this._parents);
}
function Bb(e, t) {
  var r, i, s;
  return function() {
    var o = jr(this, e), a = (this.style.removeProperty(e), jr(this, e));
    return o === a ? null : o === r && a === i ? s : s = t(r = o, i = a);
  };
}
function id(e) {
  return function() {
    this.style.removeProperty(e);
  };
}
function vb(e, t, r) {
  var i, s = r + "", o;
  return function() {
    var a = jr(this, e);
    return a === s ? null : a === i ? o : o = t(i = a, r);
  };
}
function Lb(e, t, r) {
  var i, s, o;
  return function() {
    var a = jr(this, e), n = r(this), l = n + "";
    return n == null && (l = n = (this.style.removeProperty(e), jr(this, e))), a === l ? null : a === i && l === s ? o : (s = l, o = t(i = a, n));
  };
}
function Fb(e, t) {
  var r, i, s, o = "style." + t, a = "end." + o, n;
  return function() {
    var l = Fe(this, e), c = l.on, h = l.value[o] == null ? n || (n = id(t)) : void 0;
    (c !== r || s !== h) && (i = (r = c).copy()).on(a, s = h), l.on = i;
  };
}
function Ab(e, t, r) {
  var i = (e += "") == "transform" ? $x : rd;
  return t == null ? this.styleTween(e, Bb(e, i)).on("end.style." + e, id(e)) : typeof t == "function" ? this.styleTween(e, Lb(e, i, xn(this, "style." + e, t))).each(Fb(this._id, e)) : this.styleTween(e, vb(e, i, t), r).on("end.style." + e, null);
}
function Mb(e, t, r) {
  return function(i) {
    this.style.setProperty(e, t.call(this, i), r);
  };
}
function Eb(e, t, r) {
  var i, s;
  function o() {
    var a = t.apply(this, arguments);
    return a !== s && (i = (s = a) && Mb(e, a, r)), i;
  }
  return o._value = t, o;
}
function $b(e, t, r) {
  var i = "style." + (e += "");
  if (arguments.length < 2) return (i = this.tween(i)) && i._value;
  if (t == null) return this.tween(i, null);
  if (typeof t != "function") throw new Error();
  return this.tween(i, Eb(e, t, r ?? ""));
}
function Ob(e) {
  return function() {
    this.textContent = e;
  };
}
function Ib(e) {
  return function() {
    var t = e(this);
    this.textContent = t ?? "";
  };
}
function Db(e) {
  return this.tween("text", typeof e == "function" ? Ib(xn(this, "text", e)) : Ob(e == null ? "" : e + ""));
}
function Rb(e) {
  return function(t) {
    this.textContent = e.call(this, t);
  };
}
function Pb(e) {
  var t, r;
  function i() {
    var s = e.apply(this, arguments);
    return s !== r && (t = (r = s) && Rb(s)), t;
  }
  return i._value = e, i;
}
function Nb(e) {
  var t = "text";
  if (arguments.length < 1) return (t = this.tween(t)) && t._value;
  if (e == null) return this.tween(t, null);
  if (typeof e != "function") throw new Error();
  return this.tween(t, Pb(e));
}
function qb() {
  for (var e = this._name, t = this._id, r = sd(), i = this._groups, s = i.length, o = 0; o < s; ++o)
    for (var a = i[o], n = a.length, l, c = 0; c < n; ++c)
      if (l = a[c]) {
        var h = Ce(l, t);
        co(l, e, r, c, a, {
          time: h.time + h.delay + h.duration,
          delay: 0,
          duration: h.duration,
          ease: h.ease
        });
      }
  return new Ne(i, this._parents, e, r);
}
function Wb() {
  var e, t, r = this, i = r._id, s = r.size();
  return new Promise(function(o, a) {
    var n = { value: a }, l = { value: function() {
      --s === 0 && o();
    } };
    r.each(function() {
      var c = Fe(this, i), h = c.on;
      h !== e && (t = (e = h).copy(), t._.cancel.push(n), t._.interrupt.push(n), t._.end.push(l)), c.on = t;
    }), s === 0 && o();
  });
}
var zb = 0;
function Ne(e, t, r, i) {
  this._groups = e, this._parents = t, this._name = r, this._id = i;
}
function sd() {
  return ++zb;
}
var Oe = Hi.prototype;
Ne.prototype = {
  constructor: Ne,
  select: wb,
  selectAll: Tb,
  selectChild: Oe.selectChild,
  selectChildren: Oe.selectChildren,
  filter: gb,
  merge: mb,
  selection: _b,
  transition: qb,
  call: Oe.call,
  nodes: Oe.nodes,
  node: Oe.node,
  size: Oe.size,
  empty: Oe.empty,
  each: Oe.each,
  on: xb,
  attr: Jx,
  attrTween: sb,
  style: Ab,
  styleTween: $b,
  text: Db,
  textTween: Nb,
  remove: kb,
  tween: Gx,
  delay: nb,
  duration: cb,
  ease: ub,
  easeVarying: pb,
  end: Wb,
  [Symbol.iterator]: Oe[Symbol.iterator]
};
function Hb(e) {
  return ((e *= 2) <= 1 ? e * e * e : (e -= 2) * e * e + 2) / 2;
}
var Yb = {
  time: null,
  // Set on use.
  delay: 0,
  duration: 250,
  ease: Hb
};
function Ub(e, t) {
  for (var r; !(r = e.__transition) || !(r = r[t]); )
    if (!(e = e.parentNode))
      throw new Error(`transition ${t} not found`);
  return r;
}
function Gb(e) {
  var t, r;
  e instanceof Ne ? (t = e._id, e = e._name) : (t = sd(), (r = Yb).time = yn(), e = e == null ? null : e + "");
  for (var i = this._groups, s = i.length, o = 0; o < s; ++o)
    for (var a = i[o], n = a.length, l, c = 0; c < n; ++c)
      (l = a[c]) && co(l, e, t, c, a, r || Ub(l, t));
  return new Ne(i, this._parents, e, t);
}
Hi.prototype.interrupt = Hx;
Hi.prototype.transition = Gb;
const ba = Math.PI, ka = 2 * ba, hr = 1e-6, jb = ka - hr;
function od(e) {
  this._ += e[0];
  for (let t = 1, r = e.length; t < r; ++t)
    this._ += arguments[t] + e[t];
}
function Xb(e) {
  let t = Math.floor(e);
  if (!(t >= 0)) throw new Error(`invalid digits: ${e}`);
  if (t > 15) return od;
  const r = 10 ** t;
  return function(i) {
    this._ += i[0];
    for (let s = 1, o = i.length; s < o; ++s)
      this._ += Math.round(arguments[s] * r) / r + i[s];
  };
}
class Vb {
  constructor(t) {
    this._x0 = this._y0 = // start of current subpath
    this._x1 = this._y1 = null, this._ = "", this._append = t == null ? od : Xb(t);
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
    let a = this._x1, n = this._y1, l = i - t, c = s - r, h = a - t, d = n - r, f = h * h + d * d;
    if (this._x1 === null)
      this._append`M${this._x1 = t},${this._y1 = r}`;
    else if (f > hr) if (!(Math.abs(d * l - c * h) > hr) || !o)
      this._append`L${this._x1 = t},${this._y1 = r}`;
    else {
      let u = i - a, g = s - n, m = l * l + c * c, y = u * u + g * g, C = Math.sqrt(m), b = Math.sqrt(f), k = o * Math.tan((ba - Math.acos((m + f - y) / (2 * C * b))) / 2), T = k / b, S = k / C;
      Math.abs(T - 1) > hr && this._append`L${t + T * h},${r + T * d}`, this._append`A${o},${o},0,0,${+(d * u > h * g)},${this._x1 = t + S * l},${this._y1 = r + S * c}`;
    }
  }
  arc(t, r, i, s, o, a) {
    if (t = +t, r = +r, i = +i, a = !!a, i < 0) throw new Error(`negative radius: ${i}`);
    let n = i * Math.cos(s), l = i * Math.sin(s), c = t + n, h = r + l, d = 1 ^ a, f = a ? s - o : o - s;
    this._x1 === null ? this._append`M${c},${h}` : (Math.abs(this._x1 - c) > hr || Math.abs(this._y1 - h) > hr) && this._append`L${c},${h}`, i && (f < 0 && (f = f % ka + ka), f > jb ? this._append`A${i},${i},0,1,${d},${t - n},${r - l}A${i},${i},0,1,${d},${this._x1 = c},${this._y1 = h}` : f > hr && this._append`A${i},${i},0,${+(f >= ba)},${d},${this._x1 = t + i * Math.cos(o)},${this._y1 = r + i * Math.sin(o)}`);
  }
  rect(t, r, i, s) {
    this._append`M${this._x0 = this._x1 = +t},${this._y0 = this._y1 = +r}h${i = +i}v${+s}h${-i}Z`;
  }
  toString() {
    return this._;
  }
}
function $r(e) {
  return function() {
    return e;
  };
}
const wv = Math.abs, Tv = Math.atan2, Sv = Math.cos, _v = Math.max, Bv = Math.min, vv = Math.sin, Lv = Math.sqrt, lh = 1e-12, bn = Math.PI, hh = bn / 2, Fv = 2 * bn;
function Av(e) {
  return e > 1 ? 0 : e < -1 ? bn : Math.acos(e);
}
function Mv(e) {
  return e >= 1 ? hh : e <= -1 ? -hh : Math.asin(e);
}
function Zb(e) {
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
  }, () => new Vb(t);
}
function Kb(e) {
  return typeof e == "object" && "length" in e ? e : Array.from(e);
}
function ad(e) {
  this._context = e;
}
ad.prototype = {
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
function Bi(e) {
  return new ad(e);
}
function Qb(e) {
  return e[0];
}
function Jb(e) {
  return e[1];
}
function tk(e, t) {
  var r = $r(!0), i = null, s = Bi, o = null, a = Zb(n);
  e = typeof e == "function" ? e : e === void 0 ? Qb : $r(e), t = typeof t == "function" ? t : t === void 0 ? Jb : $r(t);
  function n(l) {
    var c, h = (l = Kb(l)).length, d, f = !1, u;
    for (i == null && (o = s(u = a())), c = 0; c <= h; ++c)
      !(c < h && r(d = l[c], c, l)) === f && ((f = !f) ? o.lineStart() : o.lineEnd()), f && o.point(+e(d, c, l), +t(d, c, l));
    if (u) return o = null, u + "" || null;
  }
  return n.x = function(l) {
    return arguments.length ? (e = typeof l == "function" ? l : $r(+l), n) : e;
  }, n.y = function(l) {
    return arguments.length ? (t = typeof l == "function" ? l : $r(+l), n) : t;
  }, n.defined = function(l) {
    return arguments.length ? (r = typeof l == "function" ? l : $r(!!l), n) : r;
  }, n.curve = function(l) {
    return arguments.length ? (s = l, i != null && (o = s(i)), n) : s;
  }, n.context = function(l) {
    return arguments.length ? (l == null ? i = o = null : o = s(i = l), n) : i;
  }, n;
}
class nd {
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
function ld(e) {
  return new nd(e, !0);
}
function hd(e) {
  return new nd(e, !1);
}
function Je() {
}
function qs(e, t, r) {
  e._context.bezierCurveTo(
    (2 * e._x0 + e._x1) / 3,
    (2 * e._y0 + e._y1) / 3,
    (e._x0 + 2 * e._x1) / 3,
    (e._y0 + 2 * e._y1) / 3,
    (e._x0 + 4 * e._x1 + t) / 6,
    (e._y0 + 4 * e._y1 + r) / 6
  );
}
function uo(e) {
  this._context = e;
}
uo.prototype = {
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
        qs(this, this._x1, this._y1);
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
        qs(this, e, t);
        break;
    }
    this._x0 = this._x1, this._x1 = e, this._y0 = this._y1, this._y1 = t;
  }
};
function wa(e) {
  return new uo(e);
}
function cd(e) {
  this._context = e;
}
cd.prototype = {
  areaStart: Je,
  areaEnd: Je,
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
        qs(this, e, t);
        break;
    }
    this._x0 = this._x1, this._x1 = e, this._y0 = this._y1, this._y1 = t;
  }
};
function ek(e) {
  return new cd(e);
}
function dd(e) {
  this._context = e;
}
dd.prototype = {
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
        qs(this, e, t);
        break;
    }
    this._x0 = this._x1, this._x1 = e, this._y0 = this._y1, this._y1 = t;
  }
};
function rk(e) {
  return new dd(e);
}
function ud(e, t) {
  this._basis = new uo(e), this._beta = t;
}
ud.prototype = {
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
const ik = (function e(t) {
  function r(i) {
    return t === 1 ? new uo(i) : new ud(i, t);
  }
  return r.beta = function(i) {
    return e(+i);
  }, r;
})(0.85);
function Ws(e, t, r) {
  e._context.bezierCurveTo(
    e._x1 + e._k * (e._x2 - e._x0),
    e._y1 + e._k * (e._y2 - e._y0),
    e._x2 + e._k * (e._x1 - t),
    e._y2 + e._k * (e._y1 - r),
    e._x2,
    e._y2
  );
}
function kn(e, t) {
  this._context = e, this._k = (1 - t) / 6;
}
kn.prototype = {
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
        Ws(this, this._x1, this._y1);
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
        Ws(this, e, t);
        break;
    }
    this._x0 = this._x1, this._x1 = this._x2, this._x2 = e, this._y0 = this._y1, this._y1 = this._y2, this._y2 = t;
  }
};
const fd = (function e(t) {
  function r(i) {
    return new kn(i, t);
  }
  return r.tension = function(i) {
    return e(+i);
  }, r;
})(0);
function wn(e, t) {
  this._context = e, this._k = (1 - t) / 6;
}
wn.prototype = {
  areaStart: Je,
  areaEnd: Je,
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
        Ws(this, e, t);
        break;
    }
    this._x0 = this._x1, this._x1 = this._x2, this._x2 = e, this._y0 = this._y1, this._y1 = this._y2, this._y2 = t;
  }
};
const sk = (function e(t) {
  function r(i) {
    return new wn(i, t);
  }
  return r.tension = function(i) {
    return e(+i);
  }, r;
})(0);
function Tn(e, t) {
  this._context = e, this._k = (1 - t) / 6;
}
Tn.prototype = {
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
        Ws(this, e, t);
        break;
    }
    this._x0 = this._x1, this._x1 = this._x2, this._x2 = e, this._y0 = this._y1, this._y1 = this._y2, this._y2 = t;
  }
};
const ok = (function e(t) {
  function r(i) {
    return new Tn(i, t);
  }
  return r.tension = function(i) {
    return e(+i);
  }, r;
})(0);
function Sn(e, t, r) {
  var i = e._x1, s = e._y1, o = e._x2, a = e._y2;
  if (e._l01_a > lh) {
    var n = 2 * e._l01_2a + 3 * e._l01_a * e._l12_a + e._l12_2a, l = 3 * e._l01_a * (e._l01_a + e._l12_a);
    i = (i * n - e._x0 * e._l12_2a + e._x2 * e._l01_2a) / l, s = (s * n - e._y0 * e._l12_2a + e._y2 * e._l01_2a) / l;
  }
  if (e._l23_a > lh) {
    var c = 2 * e._l23_2a + 3 * e._l23_a * e._l12_a + e._l12_2a, h = 3 * e._l23_a * (e._l23_a + e._l12_a);
    o = (o * c + e._x1 * e._l23_2a - t * e._l12_2a) / h, a = (a * c + e._y1 * e._l23_2a - r * e._l12_2a) / h;
  }
  e._context.bezierCurveTo(i, s, o, a, e._x2, e._y2);
}
function pd(e, t) {
  this._context = e, this._alpha = t;
}
pd.prototype = {
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
        Sn(this, e, t);
        break;
    }
    this._l01_a = this._l12_a, this._l12_a = this._l23_a, this._l01_2a = this._l12_2a, this._l12_2a = this._l23_2a, this._x0 = this._x1, this._x1 = this._x2, this._x2 = e, this._y0 = this._y1, this._y1 = this._y2, this._y2 = t;
  }
};
const gd = (function e(t) {
  function r(i) {
    return t ? new pd(i, t) : new kn(i, 0);
  }
  return r.alpha = function(i) {
    return e(+i);
  }, r;
})(0.5);
function md(e, t) {
  this._context = e, this._alpha = t;
}
md.prototype = {
  areaStart: Je,
  areaEnd: Je,
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
        Sn(this, e, t);
        break;
    }
    this._l01_a = this._l12_a, this._l12_a = this._l23_a, this._l01_2a = this._l12_2a, this._l12_2a = this._l23_2a, this._x0 = this._x1, this._x1 = this._x2, this._x2 = e, this._y0 = this._y1, this._y1 = this._y2, this._y2 = t;
  }
};
const ak = (function e(t) {
  function r(i) {
    return t ? new md(i, t) : new wn(i, 0);
  }
  return r.alpha = function(i) {
    return e(+i);
  }, r;
})(0.5);
function yd(e, t) {
  this._context = e, this._alpha = t;
}
yd.prototype = {
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
        Sn(this, e, t);
        break;
    }
    this._l01_a = this._l12_a, this._l12_a = this._l23_a, this._l01_2a = this._l12_2a, this._l12_2a = this._l23_2a, this._x0 = this._x1, this._x1 = this._x2, this._x2 = e, this._y0 = this._y1, this._y1 = this._y2, this._y2 = t;
  }
};
const nk = (function e(t) {
  function r(i) {
    return t ? new yd(i, t) : new Tn(i, 0);
  }
  return r.alpha = function(i) {
    return e(+i);
  }, r;
})(0.5);
function Cd(e) {
  this._context = e;
}
Cd.prototype = {
  areaStart: Je,
  areaEnd: Je,
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
function lk(e) {
  return new Cd(e);
}
function ch(e) {
  return e < 0 ? -1 : 1;
}
function dh(e, t, r) {
  var i = e._x1 - e._x0, s = t - e._x1, o = (e._y1 - e._y0) / (i || s < 0 && -0), a = (r - e._y1) / (s || i < 0 && -0), n = (o * s + a * i) / (i + s);
  return (ch(o) + ch(a)) * Math.min(Math.abs(o), Math.abs(a), 0.5 * Math.abs(n)) || 0;
}
function uh(e, t) {
  var r = e._x1 - e._x0;
  return r ? (3 * (e._y1 - e._y0) / r - t) / 2 : t;
}
function Go(e, t, r) {
  var i = e._x0, s = e._y0, o = e._x1, a = e._y1, n = (o - i) / 3;
  e._context.bezierCurveTo(i + n, s + n * t, o - n, a - n * r, o, a);
}
function zs(e) {
  this._context = e;
}
zs.prototype = {
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
        Go(this, this._t0, uh(this, this._t0));
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
          this._point = 3, Go(this, uh(this, r = dh(this, e, t)), r);
          break;
        default:
          Go(this, this._t0, r = dh(this, e, t));
          break;
      }
      this._x0 = this._x1, this._x1 = e, this._y0 = this._y1, this._y1 = t, this._t0 = r;
    }
  }
};
function xd(e) {
  this._context = new bd(e);
}
(xd.prototype = Object.create(zs.prototype)).point = function(e, t) {
  zs.prototype.point.call(this, t, e);
};
function bd(e) {
  this._context = e;
}
bd.prototype = {
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
function kd(e) {
  return new zs(e);
}
function wd(e) {
  return new xd(e);
}
function Td(e) {
  this._context = e;
}
Td.prototype = {
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
        for (var i = fh(e), s = fh(t), o = 0, a = 1; a < r; ++o, ++a)
          this._context.bezierCurveTo(i[0][o], s[0][o], i[1][o], s[1][o], e[a], t[a]);
    (this._line || this._line !== 0 && r === 1) && this._context.closePath(), this._line = 1 - this._line, this._x = this._y = null;
  },
  point: function(e, t) {
    this._x.push(+e), this._y.push(+t);
  }
};
function fh(e) {
  var t, r = e.length - 1, i, s = new Array(r), o = new Array(r), a = new Array(r);
  for (s[0] = 0, o[0] = 2, a[0] = e[0] + 2 * e[1], t = 1; t < r - 1; ++t) s[t] = 1, o[t] = 4, a[t] = 4 * e[t] + 2 * e[t + 1];
  for (s[r - 1] = 2, o[r - 1] = 7, a[r - 1] = 8 * e[r - 1] + e[r], t = 1; t < r; ++t) i = s[t] / o[t - 1], o[t] -= i, a[t] -= i * a[t - 1];
  for (s[r - 1] = a[r - 1] / o[r - 1], t = r - 2; t >= 0; --t) s[t] = (a[t] - s[t + 1]) / o[t];
  for (o[r - 1] = (e[r] + s[r - 1]) / 2, t = 0; t < r - 1; ++t) o[t] = 2 * e[t + 1] - s[t + 1];
  return [s, o];
}
function Sd(e) {
  return new Td(e);
}
function fo(e, t) {
  this._context = e, this._t = t;
}
fo.prototype = {
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
function _d(e) {
  return new fo(e, 0.5);
}
function Bd(e) {
  return new fo(e, 0);
}
function vd(e) {
  return new fo(e, 1);
}
function Ci(e, t, r) {
  this.k = e, this.x = t, this.y = r;
}
Ci.prototype = {
  constructor: Ci,
  scale: function(e) {
    return e === 1 ? this : new Ci(this.k * e, this.x, this.y);
  },
  translate: function(e, t) {
    return e === 0 & t === 0 ? this : new Ci(this.k, this.x + this.k * e, this.y + this.k * t);
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
Ci.prototype;
var hk = /* @__PURE__ */ p((e) => {
  const { securityLevel: t } = gt();
  let r = ht("body");
  if (t === "sandbox") {
    const o = ht(`#i${e}`).node()?.contentDocument ?? document;
    r = ht(o.body);
  }
  return r.select(`#${e}`);
}, "selectSvgElement");
function _n(e) {
  return typeof e > "u" || e === null;
}
p(_n, "isNothing");
function Ld(e) {
  return typeof e == "object" && e !== null;
}
p(Ld, "isObject");
function Fd(e) {
  return Array.isArray(e) ? e : _n(e) ? [] : [e];
}
p(Fd, "toArray");
function Ad(e, t) {
  var r, i, s, o;
  if (t)
    for (o = Object.keys(t), r = 0, i = o.length; r < i; r += 1)
      s = o[r], e[s] = t[s];
  return e;
}
p(Ad, "extend");
function Md(e, t) {
  var r = "", i;
  for (i = 0; i < t; i += 1)
    r += e;
  return r;
}
p(Md, "repeat");
function Ed(e) {
  return e === 0 && Number.NEGATIVE_INFINITY === 1 / e;
}
p(Ed, "isNegativeZero");
var ck = _n, dk = Ld, uk = Fd, fk = Md, pk = Ed, gk = Ad, Ot = {
  isNothing: ck,
  isObject: dk,
  toArray: uk,
  repeat: fk,
  isNegativeZero: pk,
  extend: gk
};
function Bn(e, t) {
  var r = "", i = e.reason || "(unknown reason)";
  return e.mark ? (e.mark.name && (r += 'in "' + e.mark.name + '" '), r += "(" + (e.mark.line + 1) + ":" + (e.mark.column + 1) + ")", !t && e.mark.snippet && (r += `

` + e.mark.snippet), i + " " + r) : i;
}
p(Bn, "formatError");
function Vr(e, t) {
  Error.call(this), this.name = "YAMLException", this.reason = e, this.mark = t, this.message = Bn(this, !1), Error.captureStackTrace ? Error.captureStackTrace(this, this.constructor) : this.stack = new Error().stack || "";
}
p(Vr, "YAMLException$1");
Vr.prototype = Object.create(Error.prototype);
Vr.prototype.constructor = Vr;
Vr.prototype.toString = /* @__PURE__ */ p(function(t) {
  return this.name + ": " + Bn(this, t);
}, "toString");
var te = Vr;
function ks(e, t, r, i, s) {
  var o = "", a = "", n = Math.floor(s / 2) - 1;
  return i - t > n && (o = " ... ", t = i - n + o.length), r - i > n && (a = " ...", r = i + n - a.length), {
    str: o + e.slice(t, r).replace(/\t/g, "→") + a,
    pos: i - t + o.length
    // relative position
  };
}
p(ks, "getLine");
function ws(e, t) {
  return Ot.repeat(" ", t - e.length) + e;
}
p(ws, "padStart");
function $d(e, t) {
  if (t = Object.create(t || null), !e.buffer) return null;
  t.maxLength || (t.maxLength = 79), typeof t.indent != "number" && (t.indent = 1), typeof t.linesBefore != "number" && (t.linesBefore = 3), typeof t.linesAfter != "number" && (t.linesAfter = 2);
  for (var r = /\r?\n|\r|\0/g, i = [0], s = [], o, a = -1; o = r.exec(e.buffer); )
    s.push(o.index), i.push(o.index + o[0].length), e.position <= o.index && a < 0 && (a = i.length - 2);
  a < 0 && (a = i.length - 1);
  var n = "", l, c, h = Math.min(e.line + t.linesAfter, s.length).toString().length, d = t.maxLength - (t.indent + h + 3);
  for (l = 1; l <= t.linesBefore && !(a - l < 0); l++)
    c = ks(
      e.buffer,
      i[a - l],
      s[a - l],
      e.position - (i[a] - i[a - l]),
      d
    ), n = Ot.repeat(" ", t.indent) + ws((e.line - l + 1).toString(), h) + " | " + c.str + `
` + n;
  for (c = ks(e.buffer, i[a], s[a], e.position, d), n += Ot.repeat(" ", t.indent) + ws((e.line + 1).toString(), h) + " | " + c.str + `
`, n += Ot.repeat("-", t.indent + h + 3 + c.pos) + `^
`, l = 1; l <= t.linesAfter && !(a + l >= s.length); l++)
    c = ks(
      e.buffer,
      i[a + l],
      s[a + l],
      e.position - (i[a] - i[a + l]),
      d
    ), n += Ot.repeat(" ", t.indent) + ws((e.line + l + 1).toString(), h) + " | " + c.str + `
`;
  return n.replace(/\n$/, "");
}
p($d, "makeSnippet");
var mk = $d, yk = [
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
], Ck = [
  "scalar",
  "sequence",
  "mapping"
];
function Od(e) {
  var t = {};
  return e !== null && Object.keys(e).forEach(function(r) {
    e[r].forEach(function(i) {
      t[String(i)] = r;
    });
  }), t;
}
p(Od, "compileStyleAliases");
function Id(e, t) {
  if (t = t || {}, Object.keys(t).forEach(function(r) {
    if (yk.indexOf(r) === -1)
      throw new te('Unknown option "' + r + '" is met in definition of "' + e + '" YAML type.');
  }), this.options = t, this.tag = e, this.kind = t.kind || null, this.resolve = t.resolve || function() {
    return !0;
  }, this.construct = t.construct || function(r) {
    return r;
  }, this.instanceOf = t.instanceOf || null, this.predicate = t.predicate || null, this.represent = t.represent || null, this.representName = t.representName || null, this.defaultStyle = t.defaultStyle || null, this.multi = t.multi || !1, this.styleAliases = Od(t.styleAliases || null), Ck.indexOf(this.kind) === -1)
    throw new te('Unknown kind "' + this.kind + '" is specified for "' + e + '" YAML type.');
}
p(Id, "Type$1");
var zt = Id;
function Ta(e, t) {
  var r = [];
  return e[t].forEach(function(i) {
    var s = r.length;
    r.forEach(function(o, a) {
      o.tag === i.tag && o.kind === i.kind && o.multi === i.multi && (s = a);
    }), r[s] = i;
  }), r;
}
p(Ta, "compileList");
function Dd() {
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
  for (p(i, "collectType"), t = 0, r = arguments.length; t < r; t += 1)
    arguments[t].forEach(i);
  return e;
}
p(Dd, "compileMap");
function Hs(e) {
  return this.extend(e);
}
p(Hs, "Schema$1");
Hs.prototype.extend = /* @__PURE__ */ p(function(t) {
  var r = [], i = [];
  if (t instanceof zt)
    i.push(t);
  else if (Array.isArray(t))
    i = i.concat(t);
  else if (t && (Array.isArray(t.implicit) || Array.isArray(t.explicit)))
    t.implicit && (r = r.concat(t.implicit)), t.explicit && (i = i.concat(t.explicit));
  else
    throw new te("Schema.extend argument should be a Type, [ Type ], or a schema definition ({ implicit: [...], explicit: [...] })");
  r.forEach(function(o) {
    if (!(o instanceof zt))
      throw new te("Specified list of YAML types (or a single Type object) contains a non-Type object.");
    if (o.loadKind && o.loadKind !== "scalar")
      throw new te("There is a non-scalar type in the implicit list of a schema. Implicit resolving of such types is not supported.");
    if (o.multi)
      throw new te("There is a multi type in the implicit list of a schema. Multi tags can only be listed as explicit.");
  }), i.forEach(function(o) {
    if (!(o instanceof zt))
      throw new te("Specified list of YAML types (or a single Type object) contains a non-Type object.");
  });
  var s = Object.create(Hs.prototype);
  return s.implicit = (this.implicit || []).concat(r), s.explicit = (this.explicit || []).concat(i), s.compiledImplicit = Ta(s, "implicit"), s.compiledExplicit = Ta(s, "explicit"), s.compiledTypeMap = Dd(s.compiledImplicit, s.compiledExplicit), s;
}, "extend");
var xk = Hs, bk = new zt("tag:yaml.org,2002:str", {
  kind: "scalar",
  construct: /* @__PURE__ */ p(function(e) {
    return e !== null ? e : "";
  }, "construct")
}), kk = new zt("tag:yaml.org,2002:seq", {
  kind: "sequence",
  construct: /* @__PURE__ */ p(function(e) {
    return e !== null ? e : [];
  }, "construct")
}), wk = new zt("tag:yaml.org,2002:map", {
  kind: "mapping",
  construct: /* @__PURE__ */ p(function(e) {
    return e !== null ? e : {};
  }, "construct")
}), Tk = new xk({
  explicit: [
    bk,
    kk,
    wk
  ]
});
function Rd(e) {
  if (e === null) return !0;
  var t = e.length;
  return t === 1 && e === "~" || t === 4 && (e === "null" || e === "Null" || e === "NULL");
}
p(Rd, "resolveYamlNull");
function Pd() {
  return null;
}
p(Pd, "constructYamlNull");
function Nd(e) {
  return e === null;
}
p(Nd, "isNull");
var Sk = new zt("tag:yaml.org,2002:null", {
  kind: "scalar",
  resolve: Rd,
  construct: Pd,
  predicate: Nd,
  represent: {
    canonical: /* @__PURE__ */ p(function() {
      return "~";
    }, "canonical"),
    lowercase: /* @__PURE__ */ p(function() {
      return "null";
    }, "lowercase"),
    uppercase: /* @__PURE__ */ p(function() {
      return "NULL";
    }, "uppercase"),
    camelcase: /* @__PURE__ */ p(function() {
      return "Null";
    }, "camelcase"),
    empty: /* @__PURE__ */ p(function() {
      return "";
    }, "empty")
  },
  defaultStyle: "lowercase"
});
function qd(e) {
  if (e === null) return !1;
  var t = e.length;
  return t === 4 && (e === "true" || e === "True" || e === "TRUE") || t === 5 && (e === "false" || e === "False" || e === "FALSE");
}
p(qd, "resolveYamlBoolean");
function Wd(e) {
  return e === "true" || e === "True" || e === "TRUE";
}
p(Wd, "constructYamlBoolean");
function zd(e) {
  return Object.prototype.toString.call(e) === "[object Boolean]";
}
p(zd, "isBoolean");
var _k = new zt("tag:yaml.org,2002:bool", {
  kind: "scalar",
  resolve: qd,
  construct: Wd,
  predicate: zd,
  represent: {
    lowercase: /* @__PURE__ */ p(function(e) {
      return e ? "true" : "false";
    }, "lowercase"),
    uppercase: /* @__PURE__ */ p(function(e) {
      return e ? "TRUE" : "FALSE";
    }, "uppercase"),
    camelcase: /* @__PURE__ */ p(function(e) {
      return e ? "True" : "False";
    }, "camelcase")
  },
  defaultStyle: "lowercase"
});
function Hd(e) {
  return 48 <= e && e <= 57 || 65 <= e && e <= 70 || 97 <= e && e <= 102;
}
p(Hd, "isHexCode");
function Yd(e) {
  return 48 <= e && e <= 55;
}
p(Yd, "isOctCode");
function Ud(e) {
  return 48 <= e && e <= 57;
}
p(Ud, "isDecCode");
function Gd(e) {
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
          if (!Hd(e.charCodeAt(r))) return !1;
          i = !0;
        }
      return i && s !== "_";
    }
    if (s === "o") {
      for (r++; r < t; r++)
        if (s = e[r], s !== "_") {
          if (!Yd(e.charCodeAt(r))) return !1;
          i = !0;
        }
      return i && s !== "_";
    }
  }
  if (s === "_") return !1;
  for (; r < t; r++)
    if (s = e[r], s !== "_") {
      if (!Ud(e.charCodeAt(r)))
        return !1;
      i = !0;
    }
  return !(!i || s === "_");
}
p(Gd, "resolveYamlInteger");
function jd(e) {
  var t = e, r = 1, i;
  if (t.indexOf("_") !== -1 && (t = t.replace(/_/g, "")), i = t[0], (i === "-" || i === "+") && (i === "-" && (r = -1), t = t.slice(1), i = t[0]), t === "0") return 0;
  if (i === "0") {
    if (t[1] === "b") return r * parseInt(t.slice(2), 2);
    if (t[1] === "x") return r * parseInt(t.slice(2), 16);
    if (t[1] === "o") return r * parseInt(t.slice(2), 8);
  }
  return r * parseInt(t, 10);
}
p(jd, "constructYamlInteger");
function Xd(e) {
  return Object.prototype.toString.call(e) === "[object Number]" && e % 1 === 0 && !Ot.isNegativeZero(e);
}
p(Xd, "isInteger");
var Bk = new zt("tag:yaml.org,2002:int", {
  kind: "scalar",
  resolve: Gd,
  construct: jd,
  predicate: Xd,
  represent: {
    binary: /* @__PURE__ */ p(function(e) {
      return e >= 0 ? "0b" + e.toString(2) : "-0b" + e.toString(2).slice(1);
    }, "binary"),
    octal: /* @__PURE__ */ p(function(e) {
      return e >= 0 ? "0o" + e.toString(8) : "-0o" + e.toString(8).slice(1);
    }, "octal"),
    decimal: /* @__PURE__ */ p(function(e) {
      return e.toString(10);
    }, "decimal"),
    /* eslint-disable max-len */
    hexadecimal: /* @__PURE__ */ p(function(e) {
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
}), vk = new RegExp(
  // 2.5e4, 2.5 and integers
  "^(?:[-+]?(?:[0-9][0-9_]*)(?:\\.[0-9_]*)?(?:[eE][-+]?[0-9]+)?|\\.[0-9_]+(?:[eE][-+]?[0-9]+)?|[-+]?\\.(?:inf|Inf|INF)|\\.(?:nan|NaN|NAN))$"
);
function Vd(e) {
  return !(e === null || !vk.test(e) || // Quick hack to not allow integers end with `_`
  // Probably should update regexp & check speed
  e[e.length - 1] === "_");
}
p(Vd, "resolveYamlFloat");
function Zd(e) {
  var t, r;
  return t = e.replace(/_/g, "").toLowerCase(), r = t[0] === "-" ? -1 : 1, "+-".indexOf(t[0]) >= 0 && (t = t.slice(1)), t === ".inf" ? r === 1 ? Number.POSITIVE_INFINITY : Number.NEGATIVE_INFINITY : t === ".nan" ? NaN : r * parseFloat(t, 10);
}
p(Zd, "constructYamlFloat");
var Lk = /^[-+]?[0-9]+e/;
function Kd(e, t) {
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
  return r = e.toString(10), Lk.test(r) ? r.replace("e", ".e") : r;
}
p(Kd, "representYamlFloat");
function Qd(e) {
  return Object.prototype.toString.call(e) === "[object Number]" && (e % 1 !== 0 || Ot.isNegativeZero(e));
}
p(Qd, "isFloat");
var Fk = new zt("tag:yaml.org,2002:float", {
  kind: "scalar",
  resolve: Vd,
  construct: Zd,
  predicate: Qd,
  represent: Kd,
  defaultStyle: "lowercase"
}), Jd = Tk.extend({
  implicit: [
    Sk,
    _k,
    Bk,
    Fk
  ]
}), Ak = Jd, tu = new RegExp(
  "^([0-9][0-9][0-9][0-9])-([0-9][0-9])-([0-9][0-9])$"
), eu = new RegExp(
  "^([0-9][0-9][0-9][0-9])-([0-9][0-9]?)-([0-9][0-9]?)(?:[Tt]|[ \\t]+)([0-9][0-9]?):([0-9][0-9]):([0-9][0-9])(?:\\.([0-9]*))?(?:[ \\t]*(Z|([-+])([0-9][0-9]?)(?::([0-9][0-9]))?))?$"
);
function ru(e) {
  return e === null ? !1 : tu.exec(e) !== null || eu.exec(e) !== null;
}
p(ru, "resolveYamlTimestamp");
function iu(e) {
  var t, r, i, s, o, a, n, l = 0, c = null, h, d, f;
  if (t = tu.exec(e), t === null && (t = eu.exec(e)), t === null) throw new Error("Date resolve error");
  if (r = +t[1], i = +t[2] - 1, s = +t[3], !t[4])
    return new Date(Date.UTC(r, i, s));
  if (o = +t[4], a = +t[5], n = +t[6], t[7]) {
    for (l = t[7].slice(0, 3); l.length < 3; )
      l += "0";
    l = +l;
  }
  return t[9] && (h = +t[10], d = +(t[11] || 0), c = (h * 60 + d) * 6e4, t[9] === "-" && (c = -c)), f = new Date(Date.UTC(r, i, s, o, a, n, l)), c && f.setTime(f.getTime() - c), f;
}
p(iu, "constructYamlTimestamp");
function su(e) {
  return e.toISOString();
}
p(su, "representYamlTimestamp");
var Mk = new zt("tag:yaml.org,2002:timestamp", {
  kind: "scalar",
  resolve: ru,
  construct: iu,
  instanceOf: Date,
  represent: su
});
function ou(e) {
  return e === "<<" || e === null;
}
p(ou, "resolveYamlMerge");
var Ek = new zt("tag:yaml.org,2002:merge", {
  kind: "scalar",
  resolve: ou
}), vn = `ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=
\r`;
function au(e) {
  if (e === null) return !1;
  var t, r, i = 0, s = e.length, o = vn;
  for (r = 0; r < s; r++)
    if (t = o.indexOf(e.charAt(r)), !(t > 64)) {
      if (t < 0) return !1;
      i += 6;
    }
  return i % 8 === 0;
}
p(au, "resolveYamlBinary");
function nu(e) {
  var t, r, i = e.replace(/[\r\n=]/g, ""), s = i.length, o = vn, a = 0, n = [];
  for (t = 0; t < s; t++)
    t % 4 === 0 && t && (n.push(a >> 16 & 255), n.push(a >> 8 & 255), n.push(a & 255)), a = a << 6 | o.indexOf(i.charAt(t));
  return r = s % 4 * 6, r === 0 ? (n.push(a >> 16 & 255), n.push(a >> 8 & 255), n.push(a & 255)) : r === 18 ? (n.push(a >> 10 & 255), n.push(a >> 2 & 255)) : r === 12 && n.push(a >> 4 & 255), new Uint8Array(n);
}
p(nu, "constructYamlBinary");
function lu(e) {
  var t = "", r = 0, i, s, o = e.length, a = vn;
  for (i = 0; i < o; i++)
    i % 3 === 0 && i && (t += a[r >> 18 & 63], t += a[r >> 12 & 63], t += a[r >> 6 & 63], t += a[r & 63]), r = (r << 8) + e[i];
  return s = o % 3, s === 0 ? (t += a[r >> 18 & 63], t += a[r >> 12 & 63], t += a[r >> 6 & 63], t += a[r & 63]) : s === 2 ? (t += a[r >> 10 & 63], t += a[r >> 4 & 63], t += a[r << 2 & 63], t += a[64]) : s === 1 && (t += a[r >> 2 & 63], t += a[r << 4 & 63], t += a[64], t += a[64]), t;
}
p(lu, "representYamlBinary");
function hu(e) {
  return Object.prototype.toString.call(e) === "[object Uint8Array]";
}
p(hu, "isBinary");
var $k = new zt("tag:yaml.org,2002:binary", {
  kind: "scalar",
  resolve: au,
  construct: nu,
  predicate: hu,
  represent: lu
}), Ok = Object.prototype.hasOwnProperty, Ik = Object.prototype.toString;
function cu(e) {
  if (e === null) return !0;
  var t = [], r, i, s, o, a, n = e;
  for (r = 0, i = n.length; r < i; r += 1) {
    if (s = n[r], a = !1, Ik.call(s) !== "[object Object]") return !1;
    for (o in s)
      if (Ok.call(s, o))
        if (!a) a = !0;
        else return !1;
    if (!a) return !1;
    if (t.indexOf(o) === -1) t.push(o);
    else return !1;
  }
  return !0;
}
p(cu, "resolveYamlOmap");
function du(e) {
  return e !== null ? e : [];
}
p(du, "constructYamlOmap");
var Dk = new zt("tag:yaml.org,2002:omap", {
  kind: "sequence",
  resolve: cu,
  construct: du
}), Rk = Object.prototype.toString;
function uu(e) {
  if (e === null) return !0;
  var t, r, i, s, o, a = e;
  for (o = new Array(a.length), t = 0, r = a.length; t < r; t += 1) {
    if (i = a[t], Rk.call(i) !== "[object Object]" || (s = Object.keys(i), s.length !== 1)) return !1;
    o[t] = [s[0], i[s[0]]];
  }
  return !0;
}
p(uu, "resolveYamlPairs");
function fu(e) {
  if (e === null) return [];
  var t, r, i, s, o, a = e;
  for (o = new Array(a.length), t = 0, r = a.length; t < r; t += 1)
    i = a[t], s = Object.keys(i), o[t] = [s[0], i[s[0]]];
  return o;
}
p(fu, "constructYamlPairs");
var Pk = new zt("tag:yaml.org,2002:pairs", {
  kind: "sequence",
  resolve: uu,
  construct: fu
}), Nk = Object.prototype.hasOwnProperty;
function pu(e) {
  if (e === null) return !0;
  var t, r = e;
  for (t in r)
    if (Nk.call(r, t) && r[t] !== null)
      return !1;
  return !0;
}
p(pu, "resolveYamlSet");
function gu(e) {
  return e !== null ? e : {};
}
p(gu, "constructYamlSet");
var qk = new zt("tag:yaml.org,2002:set", {
  kind: "mapping",
  resolve: pu,
  construct: gu
}), mu = Ak.extend({
  implicit: [
    Mk,
    Ek
  ],
  explicit: [
    $k,
    Dk,
    Pk,
    qk
  ]
}), tr = Object.prototype.hasOwnProperty, Ys = 1, yu = 2, Cu = 3, Us = 4, jo = 1, Wk = 2, ph = 3, zk = /[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x84\x86-\x9F\uFFFE\uFFFF]|[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?:[^\uD800-\uDBFF]|^)[\uDC00-\uDFFF]/, Hk = /[\x85\u2028\u2029]/, Yk = /[,\[\]\{\}]/, xu = /^(?:!|!!|![a-z\-]+!)$/i, bu = /^(?:!|[^,\[\]\{\}])(?:%[0-9a-f]{2}|[0-9a-z\-#;\/\?:@&=\+\$,_\.!~\*'\(\)\[\]])*$/i;
function Sa(e) {
  return Object.prototype.toString.call(e);
}
p(Sa, "_class");
function pe(e) {
  return e === 10 || e === 13;
}
p(pe, "is_EOL");
function Qe(e) {
  return e === 9 || e === 32;
}
p(Qe, "is_WHITE_SPACE");
function Gt(e) {
  return e === 9 || e === 32 || e === 10 || e === 13;
}
p(Gt, "is_WS_OR_EOL");
function fr(e) {
  return e === 44 || e === 91 || e === 93 || e === 123 || e === 125;
}
p(fr, "is_FLOW_INDICATOR");
function ku(e) {
  var t;
  return 48 <= e && e <= 57 ? e - 48 : (t = e | 32, 97 <= t && t <= 102 ? t - 97 + 10 : -1);
}
p(ku, "fromHexCode");
function wu(e) {
  return e === 120 ? 2 : e === 117 ? 4 : e === 85 ? 8 : 0;
}
p(wu, "escapedHexLen");
function Tu(e) {
  return 48 <= e && e <= 57 ? e - 48 : -1;
}
p(Tu, "fromDecimalCode");
function _a(e) {
  return e === 48 ? "\0" : e === 97 ? "\x07" : e === 98 ? "\b" : e === 116 || e === 9 ? "	" : e === 110 ? `
` : e === 118 ? "\v" : e === 102 ? "\f" : e === 114 ? "\r" : e === 101 ? "\x1B" : e === 32 ? " " : e === 34 ? '"' : e === 47 ? "/" : e === 92 ? "\\" : e === 78 ? "" : e === 95 ? " " : e === 76 ? "\u2028" : e === 80 ? "\u2029" : "";
}
p(_a, "simpleEscapeSequence");
function Su(e) {
  return e <= 65535 ? String.fromCharCode(e) : String.fromCharCode(
    (e - 65536 >> 10) + 55296,
    (e - 65536 & 1023) + 56320
  );
}
p(Su, "charFromCodepoint");
function Ln(e, t, r) {
  t === "__proto__" ? Object.defineProperty(e, t, {
    configurable: !0,
    enumerable: !0,
    writable: !0,
    value: r
  }) : e[t] = r;
}
p(Ln, "setProperty");
var _u = new Array(256), Bu = new Array(256);
for (ar = 0; ar < 256; ar++)
  _u[ar] = _a(ar) ? 1 : 0, Bu[ar] = _a(ar);
var ar;
function vu(e, t) {
  this.input = e, this.filename = t.filename || null, this.schema = t.schema || mu, this.onWarning = t.onWarning || null, this.legacy = t.legacy || !1, this.json = t.json || !1, this.listener = t.listener || null, this.implicitTypes = this.schema.compiledImplicit, this.typeMap = this.schema.compiledTypeMap, this.length = e.length, this.position = 0, this.line = 0, this.lineStart = 0, this.lineIndent = 0, this.firstTabInLine = -1, this.documents = [];
}
p(vu, "State$1");
function Fn(e, t) {
  var r = {
    name: e.filename,
    buffer: e.input.slice(0, -1),
    // omit trailing \0
    position: e.position,
    line: e.line,
    column: e.position - e.lineStart
  };
  return r.snippet = mk(r), new te(t, r);
}
p(Fn, "generateError");
function Q(e, t) {
  throw Fn(e, t);
}
p(Q, "throwError");
function Oi(e, t) {
  e.onWarning && e.onWarning.call(null, Fn(e, t));
}
p(Oi, "throwWarning");
var gh = {
  YAML: /* @__PURE__ */ p(function(t, r, i) {
    var s, o, a;
    t.version !== null && Q(t, "duplication of %YAML directive"), i.length !== 1 && Q(t, "YAML directive accepts exactly one argument"), s = /^([0-9]+)\.([0-9]+)$/.exec(i[0]), s === null && Q(t, "ill-formed argument of the YAML directive"), o = parseInt(s[1], 10), a = parseInt(s[2], 10), o !== 1 && Q(t, "unacceptable YAML version of the document"), t.version = i[0], t.checkLineBreaks = a < 2, a !== 1 && a !== 2 && Oi(t, "unsupported YAML version of the document");
  }, "handleYamlDirective"),
  TAG: /* @__PURE__ */ p(function(t, r, i) {
    var s, o;
    i.length !== 2 && Q(t, "TAG directive accepts exactly two arguments"), s = i[0], o = i[1], xu.test(s) || Q(t, "ill-formed tag handle (first argument) of the TAG directive"), tr.call(t.tagMap, s) && Q(t, 'there is a previously declared suffix for "' + s + '" tag handle'), bu.test(o) || Q(t, "ill-formed tag prefix (second argument) of the TAG directive");
    try {
      o = decodeURIComponent(o);
    } catch {
      Q(t, "tag prefix is malformed: " + o);
    }
    t.tagMap[s] = o;
  }, "handleTagDirective")
};
function Pe(e, t, r, i) {
  var s, o, a, n;
  if (t < r) {
    if (n = e.input.slice(t, r), i)
      for (s = 0, o = n.length; s < o; s += 1)
        a = n.charCodeAt(s), a === 9 || 32 <= a && a <= 1114111 || Q(e, "expected valid JSON character");
    else zk.test(n) && Q(e, "the stream contains non-printable characters");
    e.result += n;
  }
}
p(Pe, "captureSegment");
function Ba(e, t, r, i) {
  var s, o, a, n;
  for (Ot.isObject(r) || Q(e, "cannot merge mappings; the provided source object is unacceptable"), s = Object.keys(r), a = 0, n = s.length; a < n; a += 1)
    o = s[a], tr.call(t, o) || (Ln(t, o, r[o]), i[o] = !0);
}
p(Ba, "mergeMappings");
function pr(e, t, r, i, s, o, a, n, l) {
  var c, h;
  if (Array.isArray(s))
    for (s = Array.prototype.slice.call(s), c = 0, h = s.length; c < h; c += 1)
      Array.isArray(s[c]) && Q(e, "nested arrays are not supported inside keys"), typeof s == "object" && Sa(s[c]) === "[object Object]" && (s[c] = "[object Object]");
  if (typeof s == "object" && Sa(s) === "[object Object]" && (s = "[object Object]"), s = String(s), t === null && (t = {}), i === "tag:yaml.org,2002:merge")
    if (Array.isArray(o))
      for (c = 0, h = o.length; c < h; c += 1)
        Ba(e, t, o[c], r);
    else
      Ba(e, t, o, r);
  else
    !e.json && !tr.call(r, s) && tr.call(t, s) && (e.line = a || e.line, e.lineStart = n || e.lineStart, e.position = l || e.position, Q(e, "duplicated mapping key")), Ln(t, s, o), delete r[s];
  return t;
}
p(pr, "storeMappingPair");
function po(e) {
  var t;
  t = e.input.charCodeAt(e.position), t === 10 ? e.position++ : t === 13 ? (e.position++, e.input.charCodeAt(e.position) === 10 && e.position++) : Q(e, "a line break is expected"), e.line += 1, e.lineStart = e.position, e.firstTabInLine = -1;
}
p(po, "readLineBreak");
function Bt(e, t, r) {
  for (var i = 0, s = e.input.charCodeAt(e.position); s !== 0; ) {
    for (; Qe(s); )
      s === 9 && e.firstTabInLine === -1 && (e.firstTabInLine = e.position), s = e.input.charCodeAt(++e.position);
    if (t && s === 35)
      do
        s = e.input.charCodeAt(++e.position);
      while (s !== 10 && s !== 13 && s !== 0);
    if (pe(s))
      for (po(e), s = e.input.charCodeAt(e.position), i++, e.lineIndent = 0; s === 32; )
        e.lineIndent++, s = e.input.charCodeAt(++e.position);
    else
      break;
  }
  return r !== -1 && i !== 0 && e.lineIndent < r && Oi(e, "deficient indentation"), i;
}
p(Bt, "skipSeparationSpace");
function Ui(e) {
  var t = e.position, r;
  return r = e.input.charCodeAt(t), !!((r === 45 || r === 46) && r === e.input.charCodeAt(t + 1) && r === e.input.charCodeAt(t + 2) && (t += 3, r = e.input.charCodeAt(t), r === 0 || Gt(r)));
}
p(Ui, "testDocumentSeparator");
function go(e, t) {
  t === 1 ? e.result += " " : t > 1 && (e.result += Ot.repeat(`
`, t - 1));
}
p(go, "writeFoldedLines");
function Lu(e, t, r) {
  var i, s, o, a, n, l, c, h, d = e.kind, f = e.result, u;
  if (u = e.input.charCodeAt(e.position), Gt(u) || fr(u) || u === 35 || u === 38 || u === 42 || u === 33 || u === 124 || u === 62 || u === 39 || u === 34 || u === 37 || u === 64 || u === 96 || (u === 63 || u === 45) && (s = e.input.charCodeAt(e.position + 1), Gt(s) || r && fr(s)))
    return !1;
  for (e.kind = "scalar", e.result = "", o = a = e.position, n = !1; u !== 0; ) {
    if (u === 58) {
      if (s = e.input.charCodeAt(e.position + 1), Gt(s) || r && fr(s))
        break;
    } else if (u === 35) {
      if (i = e.input.charCodeAt(e.position - 1), Gt(i))
        break;
    } else {
      if (e.position === e.lineStart && Ui(e) || r && fr(u))
        break;
      if (pe(u))
        if (l = e.line, c = e.lineStart, h = e.lineIndent, Bt(e, !1, -1), e.lineIndent >= t) {
          n = !0, u = e.input.charCodeAt(e.position);
          continue;
        } else {
          e.position = a, e.line = l, e.lineStart = c, e.lineIndent = h;
          break;
        }
    }
    n && (Pe(e, o, a, !1), go(e, e.line - l), o = a = e.position, n = !1), Qe(u) || (a = e.position + 1), u = e.input.charCodeAt(++e.position);
  }
  return Pe(e, o, a, !1), e.result ? !0 : (e.kind = d, e.result = f, !1);
}
p(Lu, "readPlainScalar");
function Fu(e, t) {
  var r, i, s;
  if (r = e.input.charCodeAt(e.position), r !== 39)
    return !1;
  for (e.kind = "scalar", e.result = "", e.position++, i = s = e.position; (r = e.input.charCodeAt(e.position)) !== 0; )
    if (r === 39)
      if (Pe(e, i, e.position, !0), r = e.input.charCodeAt(++e.position), r === 39)
        i = e.position, e.position++, s = e.position;
      else
        return !0;
    else pe(r) ? (Pe(e, i, s, !0), go(e, Bt(e, !1, t)), i = s = e.position) : e.position === e.lineStart && Ui(e) ? Q(e, "unexpected end of the document within a single quoted scalar") : (e.position++, s = e.position);
  Q(e, "unexpected end of the stream within a single quoted scalar");
}
p(Fu, "readSingleQuotedScalar");
function Au(e, t) {
  var r, i, s, o, a, n;
  if (n = e.input.charCodeAt(e.position), n !== 34)
    return !1;
  for (e.kind = "scalar", e.result = "", e.position++, r = i = e.position; (n = e.input.charCodeAt(e.position)) !== 0; ) {
    if (n === 34)
      return Pe(e, r, e.position, !0), e.position++, !0;
    if (n === 92) {
      if (Pe(e, r, e.position, !0), n = e.input.charCodeAt(++e.position), pe(n))
        Bt(e, !1, t);
      else if (n < 256 && _u[n])
        e.result += Bu[n], e.position++;
      else if ((a = wu(n)) > 0) {
        for (s = a, o = 0; s > 0; s--)
          n = e.input.charCodeAt(++e.position), (a = ku(n)) >= 0 ? o = (o << 4) + a : Q(e, "expected hexadecimal character");
        e.result += Su(o), e.position++;
      } else
        Q(e, "unknown escape sequence");
      r = i = e.position;
    } else pe(n) ? (Pe(e, r, i, !0), go(e, Bt(e, !1, t)), r = i = e.position) : e.position === e.lineStart && Ui(e) ? Q(e, "unexpected end of the document within a double quoted scalar") : (e.position++, i = e.position);
  }
  Q(e, "unexpected end of the stream within a double quoted scalar");
}
p(Au, "readDoubleQuotedScalar");
function Mu(e, t) {
  var r = !0, i, s, o, a = e.tag, n, l = e.anchor, c, h, d, f, u, g = /* @__PURE__ */ Object.create(null), m, y, C, b;
  if (b = e.input.charCodeAt(e.position), b === 91)
    h = 93, u = !1, n = [];
  else if (b === 123)
    h = 125, u = !0, n = {};
  else
    return !1;
  for (e.anchor !== null && (e.anchorMap[e.anchor] = n), b = e.input.charCodeAt(++e.position); b !== 0; ) {
    if (Bt(e, !0, t), b = e.input.charCodeAt(e.position), b === h)
      return e.position++, e.tag = a, e.anchor = l, e.kind = u ? "mapping" : "sequence", e.result = n, !0;
    r ? b === 44 && Q(e, "expected the node content, but found ','") : Q(e, "missed comma between flow collection entries"), y = m = C = null, d = f = !1, b === 63 && (c = e.input.charCodeAt(e.position + 1), Gt(c) && (d = f = !0, e.position++, Bt(e, !0, t))), i = e.line, s = e.lineStart, o = e.position, xr(e, t, Ys, !1, !0), y = e.tag, m = e.result, Bt(e, !0, t), b = e.input.charCodeAt(e.position), (f || e.line === i) && b === 58 && (d = !0, b = e.input.charCodeAt(++e.position), Bt(e, !0, t), xr(e, t, Ys, !1, !0), C = e.result), u ? pr(e, n, g, y, m, C, i, s, o) : d ? n.push(pr(e, null, g, y, m, C, i, s, o)) : n.push(m), Bt(e, !0, t), b = e.input.charCodeAt(e.position), b === 44 ? (r = !0, b = e.input.charCodeAt(++e.position)) : r = !1;
  }
  Q(e, "unexpected end of the stream within a flow collection");
}
p(Mu, "readFlowCollection");
function Eu(e, t) {
  var r, i, s = jo, o = !1, a = !1, n = t, l = 0, c = !1, h, d;
  if (d = e.input.charCodeAt(e.position), d === 124)
    i = !1;
  else if (d === 62)
    i = !0;
  else
    return !1;
  for (e.kind = "scalar", e.result = ""; d !== 0; )
    if (d = e.input.charCodeAt(++e.position), d === 43 || d === 45)
      jo === s ? s = d === 43 ? ph : Wk : Q(e, "repeat of a chomping mode identifier");
    else if ((h = Tu(d)) >= 0)
      h === 0 ? Q(e, "bad explicit indentation width of a block scalar; it cannot be less than one") : a ? Q(e, "repeat of an indentation width identifier") : (n = t + h - 1, a = !0);
    else
      break;
  if (Qe(d)) {
    do
      d = e.input.charCodeAt(++e.position);
    while (Qe(d));
    if (d === 35)
      do
        d = e.input.charCodeAt(++e.position);
      while (!pe(d) && d !== 0);
  }
  for (; d !== 0; ) {
    for (po(e), e.lineIndent = 0, d = e.input.charCodeAt(e.position); (!a || e.lineIndent < n) && d === 32; )
      e.lineIndent++, d = e.input.charCodeAt(++e.position);
    if (!a && e.lineIndent > n && (n = e.lineIndent), pe(d)) {
      l++;
      continue;
    }
    if (e.lineIndent < n) {
      s === ph ? e.result += Ot.repeat(`
`, o ? 1 + l : l) : s === jo && o && (e.result += `
`);
      break;
    }
    for (i ? Qe(d) ? (c = !0, e.result += Ot.repeat(`
`, o ? 1 + l : l)) : c ? (c = !1, e.result += Ot.repeat(`
`, l + 1)) : l === 0 ? o && (e.result += " ") : e.result += Ot.repeat(`
`, l) : e.result += Ot.repeat(`
`, o ? 1 + l : l), o = !0, a = !0, l = 0, r = e.position; !pe(d) && d !== 0; )
      d = e.input.charCodeAt(++e.position);
    Pe(e, r, e.position, !1);
  }
  return !0;
}
p(Eu, "readBlockScalar");
function va(e, t) {
  var r, i = e.tag, s = e.anchor, o = [], a, n = !1, l;
  if (e.firstTabInLine !== -1) return !1;
  for (e.anchor !== null && (e.anchorMap[e.anchor] = o), l = e.input.charCodeAt(e.position); l !== 0 && (e.firstTabInLine !== -1 && (e.position = e.firstTabInLine, Q(e, "tab characters must not be used in indentation")), !(l !== 45 || (a = e.input.charCodeAt(e.position + 1), !Gt(a)))); ) {
    if (n = !0, e.position++, Bt(e, !0, -1) && e.lineIndent <= t) {
      o.push(null), l = e.input.charCodeAt(e.position);
      continue;
    }
    if (r = e.line, xr(e, t, Cu, !1, !0), o.push(e.result), Bt(e, !0, -1), l = e.input.charCodeAt(e.position), (e.line === r || e.lineIndent > t) && l !== 0)
      Q(e, "bad indentation of a sequence entry");
    else if (e.lineIndent < t)
      break;
  }
  return n ? (e.tag = i, e.anchor = s, e.kind = "sequence", e.result = o, !0) : !1;
}
p(va, "readBlockSequence");
function $u(e, t, r) {
  var i, s, o, a, n, l, c = e.tag, h = e.anchor, d = {}, f = /* @__PURE__ */ Object.create(null), u = null, g = null, m = null, y = !1, C = !1, b;
  if (e.firstTabInLine !== -1) return !1;
  for (e.anchor !== null && (e.anchorMap[e.anchor] = d), b = e.input.charCodeAt(e.position); b !== 0; ) {
    if (!y && e.firstTabInLine !== -1 && (e.position = e.firstTabInLine, Q(e, "tab characters must not be used in indentation")), i = e.input.charCodeAt(e.position + 1), o = e.line, (b === 63 || b === 58) && Gt(i))
      b === 63 ? (y && (pr(e, d, f, u, g, null, a, n, l), u = g = m = null), C = !0, y = !0, s = !0) : y ? (y = !1, s = !0) : Q(e, "incomplete explicit mapping pair; a key node is missed; or followed by a non-tabulated empty line"), e.position += 1, b = i;
    else {
      if (a = e.line, n = e.lineStart, l = e.position, !xr(e, r, yu, !1, !0))
        break;
      if (e.line === o) {
        for (b = e.input.charCodeAt(e.position); Qe(b); )
          b = e.input.charCodeAt(++e.position);
        if (b === 58)
          b = e.input.charCodeAt(++e.position), Gt(b) || Q(e, "a whitespace character is expected after the key-value separator within a block mapping"), y && (pr(e, d, f, u, g, null, a, n, l), u = g = m = null), C = !0, y = !1, s = !1, u = e.tag, g = e.result;
        else if (C)
          Q(e, "can not read an implicit mapping pair; a colon is missed");
        else
          return e.tag = c, e.anchor = h, !0;
      } else if (C)
        Q(e, "can not read a block mapping entry; a multiline key may not be an implicit key");
      else
        return e.tag = c, e.anchor = h, !0;
    }
    if ((e.line === o || e.lineIndent > t) && (y && (a = e.line, n = e.lineStart, l = e.position), xr(e, t, Us, !0, s) && (y ? g = e.result : m = e.result), y || (pr(e, d, f, u, g, m, a, n, l), u = g = m = null), Bt(e, !0, -1), b = e.input.charCodeAt(e.position)), (e.line === o || e.lineIndent > t) && b !== 0)
      Q(e, "bad indentation of a mapping entry");
    else if (e.lineIndent < t)
      break;
  }
  return y && pr(e, d, f, u, g, null, a, n, l), C && (e.tag = c, e.anchor = h, e.kind = "mapping", e.result = d), C;
}
p($u, "readBlockMapping");
function Ou(e) {
  var t, r = !1, i = !1, s, o, a;
  if (a = e.input.charCodeAt(e.position), a !== 33) return !1;
  if (e.tag !== null && Q(e, "duplication of a tag property"), a = e.input.charCodeAt(++e.position), a === 60 ? (r = !0, a = e.input.charCodeAt(++e.position)) : a === 33 ? (i = !0, s = "!!", a = e.input.charCodeAt(++e.position)) : s = "!", t = e.position, r) {
    do
      a = e.input.charCodeAt(++e.position);
    while (a !== 0 && a !== 62);
    e.position < e.length ? (o = e.input.slice(t, e.position), a = e.input.charCodeAt(++e.position)) : Q(e, "unexpected end of the stream within a verbatim tag");
  } else {
    for (; a !== 0 && !Gt(a); )
      a === 33 && (i ? Q(e, "tag suffix cannot contain exclamation marks") : (s = e.input.slice(t - 1, e.position + 1), xu.test(s) || Q(e, "named tag handle cannot contain such characters"), i = !0, t = e.position + 1)), a = e.input.charCodeAt(++e.position);
    o = e.input.slice(t, e.position), Yk.test(o) && Q(e, "tag suffix cannot contain flow indicator characters");
  }
  o && !bu.test(o) && Q(e, "tag name cannot contain such characters: " + o);
  try {
    o = decodeURIComponent(o);
  } catch {
    Q(e, "tag name is malformed: " + o);
  }
  return r ? e.tag = o : tr.call(e.tagMap, s) ? e.tag = e.tagMap[s] + o : s === "!" ? e.tag = "!" + o : s === "!!" ? e.tag = "tag:yaml.org,2002:" + o : Q(e, 'undeclared tag handle "' + s + '"'), !0;
}
p(Ou, "readTagProperty");
function Iu(e) {
  var t, r;
  if (r = e.input.charCodeAt(e.position), r !== 38) return !1;
  for (e.anchor !== null && Q(e, "duplication of an anchor property"), r = e.input.charCodeAt(++e.position), t = e.position; r !== 0 && !Gt(r) && !fr(r); )
    r = e.input.charCodeAt(++e.position);
  return e.position === t && Q(e, "name of an anchor node must contain at least one character"), e.anchor = e.input.slice(t, e.position), !0;
}
p(Iu, "readAnchorProperty");
function Du(e) {
  var t, r, i;
  if (i = e.input.charCodeAt(e.position), i !== 42) return !1;
  for (i = e.input.charCodeAt(++e.position), t = e.position; i !== 0 && !Gt(i) && !fr(i); )
    i = e.input.charCodeAt(++e.position);
  return e.position === t && Q(e, "name of an alias node must contain at least one character"), r = e.input.slice(t, e.position), tr.call(e.anchorMap, r) || Q(e, 'unidentified alias "' + r + '"'), e.result = e.anchorMap[r], Bt(e, !0, -1), !0;
}
p(Du, "readAlias");
function xr(e, t, r, i, s) {
  var o, a, n, l = 1, c = !1, h = !1, d, f, u, g, m, y;
  if (e.listener !== null && e.listener("open", e), e.tag = null, e.anchor = null, e.kind = null, e.result = null, o = a = n = Us === r || Cu === r, i && Bt(e, !0, -1) && (c = !0, e.lineIndent > t ? l = 1 : e.lineIndent === t ? l = 0 : e.lineIndent < t && (l = -1)), l === 1)
    for (; Ou(e) || Iu(e); )
      Bt(e, !0, -1) ? (c = !0, n = o, e.lineIndent > t ? l = 1 : e.lineIndent === t ? l = 0 : e.lineIndent < t && (l = -1)) : n = !1;
  if (n && (n = c || s), (l === 1 || Us === r) && (Ys === r || yu === r ? m = t : m = t + 1, y = e.position - e.lineStart, l === 1 ? n && (va(e, y) || $u(e, y, m)) || Mu(e, m) ? h = !0 : (a && Eu(e, m) || Fu(e, m) || Au(e, m) ? h = !0 : Du(e) ? (h = !0, (e.tag !== null || e.anchor !== null) && Q(e, "alias node should not have any properties")) : Lu(e, m, Ys === r) && (h = !0, e.tag === null && (e.tag = "?")), e.anchor !== null && (e.anchorMap[e.anchor] = e.result)) : l === 0 && (h = n && va(e, y))), e.tag === null)
    e.anchor !== null && (e.anchorMap[e.anchor] = e.result);
  else if (e.tag === "?") {
    for (e.result !== null && e.kind !== "scalar" && Q(e, 'unacceptable node kind for !<?> tag; it should be "scalar", not "' + e.kind + '"'), d = 0, f = e.implicitTypes.length; d < f; d += 1)
      if (g = e.implicitTypes[d], g.resolve(e.result)) {
        e.result = g.construct(e.result), e.tag = g.tag, e.anchor !== null && (e.anchorMap[e.anchor] = e.result);
        break;
      }
  } else if (e.tag !== "!") {
    if (tr.call(e.typeMap[e.kind || "fallback"], e.tag))
      g = e.typeMap[e.kind || "fallback"][e.tag];
    else
      for (g = null, u = e.typeMap.multi[e.kind || "fallback"], d = 0, f = u.length; d < f; d += 1)
        if (e.tag.slice(0, u[d].tag.length) === u[d].tag) {
          g = u[d];
          break;
        }
    g || Q(e, "unknown tag !<" + e.tag + ">"), e.result !== null && g.kind !== e.kind && Q(e, "unacceptable node kind for !<" + e.tag + '> tag; it should be "' + g.kind + '", not "' + e.kind + '"'), g.resolve(e.result, e.tag) ? (e.result = g.construct(e.result, e.tag), e.anchor !== null && (e.anchorMap[e.anchor] = e.result)) : Q(e, "cannot resolve a node with !<" + e.tag + "> explicit tag");
  }
  return e.listener !== null && e.listener("close", e), e.tag !== null || e.anchor !== null || h;
}
p(xr, "composeNode");
function Ru(e) {
  var t = e.position, r, i, s, o = !1, a;
  for (e.version = null, e.checkLineBreaks = e.legacy, e.tagMap = /* @__PURE__ */ Object.create(null), e.anchorMap = /* @__PURE__ */ Object.create(null); (a = e.input.charCodeAt(e.position)) !== 0 && (Bt(e, !0, -1), a = e.input.charCodeAt(e.position), !(e.lineIndent > 0 || a !== 37)); ) {
    for (o = !0, a = e.input.charCodeAt(++e.position), r = e.position; a !== 0 && !Gt(a); )
      a = e.input.charCodeAt(++e.position);
    for (i = e.input.slice(r, e.position), s = [], i.length < 1 && Q(e, "directive name must not be less than one character in length"); a !== 0; ) {
      for (; Qe(a); )
        a = e.input.charCodeAt(++e.position);
      if (a === 35) {
        do
          a = e.input.charCodeAt(++e.position);
        while (a !== 0 && !pe(a));
        break;
      }
      if (pe(a)) break;
      for (r = e.position; a !== 0 && !Gt(a); )
        a = e.input.charCodeAt(++e.position);
      s.push(e.input.slice(r, e.position));
    }
    a !== 0 && po(e), tr.call(gh, i) ? gh[i](e, i, s) : Oi(e, 'unknown document directive "' + i + '"');
  }
  if (Bt(e, !0, -1), e.lineIndent === 0 && e.input.charCodeAt(e.position) === 45 && e.input.charCodeAt(e.position + 1) === 45 && e.input.charCodeAt(e.position + 2) === 45 ? (e.position += 3, Bt(e, !0, -1)) : o && Q(e, "directives end mark is expected"), xr(e, e.lineIndent - 1, Us, !1, !0), Bt(e, !0, -1), e.checkLineBreaks && Hk.test(e.input.slice(t, e.position)) && Oi(e, "non-ASCII line breaks are interpreted as content"), e.documents.push(e.result), e.position === e.lineStart && Ui(e)) {
    e.input.charCodeAt(e.position) === 46 && (e.position += 3, Bt(e, !0, -1));
    return;
  }
  if (e.position < e.length - 1)
    Q(e, "end of the stream or a document separator is expected");
  else
    return;
}
p(Ru, "readDocument");
function An(e, t) {
  e = String(e), t = t || {}, e.length !== 0 && (e.charCodeAt(e.length - 1) !== 10 && e.charCodeAt(e.length - 1) !== 13 && (e += `
`), e.charCodeAt(0) === 65279 && (e = e.slice(1)));
  var r = new vu(e, t), i = e.indexOf("\0");
  for (i !== -1 && (r.position = i, Q(r, "null byte is not allowed in input")), r.input += "\0"; r.input.charCodeAt(r.position) === 32; )
    r.lineIndent += 1, r.position += 1;
  for (; r.position < r.length - 1; )
    Ru(r);
  return r.documents;
}
p(An, "loadDocuments");
function Uk(e, t, r) {
  t !== null && typeof t == "object" && typeof r > "u" && (r = t, t = null);
  var i = An(e, r);
  if (typeof t != "function")
    return i;
  for (var s = 0, o = i.length; s < o; s += 1)
    t(i[s]);
}
p(Uk, "loadAll$1");
function Pu(e, t) {
  var r = An(e, t);
  if (r.length !== 0) {
    if (r.length === 1)
      return r[0];
    throw new te("expected a single document in the stream, but found more");
  }
}
p(Pu, "load$1");
var Gk = Pu, jk = {
  load: Gk
}, Nu = Object.prototype.toString, qu = Object.prototype.hasOwnProperty, Mn = 65279, Xk = 9, Ii = 10, Vk = 13, Zk = 32, Kk = 33, Qk = 34, La = 35, Jk = 37, t1 = 38, e1 = 39, r1 = 42, Wu = 44, i1 = 45, Gs = 58, s1 = 61, o1 = 62, a1 = 63, n1 = 64, zu = 91, Hu = 93, l1 = 96, Yu = 123, h1 = 124, Uu = 125, Ht = {};
Ht[0] = "\\0";
Ht[7] = "\\a";
Ht[8] = "\\b";
Ht[9] = "\\t";
Ht[10] = "\\n";
Ht[11] = "\\v";
Ht[12] = "\\f";
Ht[13] = "\\r";
Ht[27] = "\\e";
Ht[34] = '\\"';
Ht[92] = "\\\\";
Ht[133] = "\\N";
Ht[160] = "\\_";
Ht[8232] = "\\L";
Ht[8233] = "\\P";
var c1 = [
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
], d1 = /^[-+]?[0-9_]+(?::[0-9_]+)+(?:\.[0-9_]*)?$/;
function Gu(e, t) {
  var r, i, s, o, a, n, l;
  if (t === null) return {};
  for (r = {}, i = Object.keys(t), s = 0, o = i.length; s < o; s += 1)
    a = i[s], n = String(t[a]), a.slice(0, 2) === "!!" && (a = "tag:yaml.org,2002:" + a.slice(2)), l = e.compiledTypeMap.fallback[a], l && qu.call(l.styleAliases, n) && (n = l.styleAliases[n]), r[a] = n;
  return r;
}
p(Gu, "compileStyleMap");
function ju(e) {
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
p(ju, "encodeHex");
var u1 = 1, Di = 2;
function Xu(e) {
  this.schema = e.schema || mu, this.indent = Math.max(1, e.indent || 2), this.noArrayIndent = e.noArrayIndent || !1, this.skipInvalid = e.skipInvalid || !1, this.flowLevel = Ot.isNothing(e.flowLevel) ? -1 : e.flowLevel, this.styleMap = Gu(this.schema, e.styles || null), this.sortKeys = e.sortKeys || !1, this.lineWidth = e.lineWidth || 80, this.noRefs = e.noRefs || !1, this.noCompatMode = e.noCompatMode || !1, this.condenseFlow = e.condenseFlow || !1, this.quotingType = e.quotingType === '"' ? Di : u1, this.forceQuotes = e.forceQuotes || !1, this.replacer = typeof e.replacer == "function" ? e.replacer : null, this.implicitTypes = this.schema.compiledImplicit, this.explicitTypes = this.schema.compiledExplicit, this.tag = null, this.result = "", this.duplicates = [], this.usedDuplicates = null;
}
p(Xu, "State");
function Fa(e, t) {
  for (var r = Ot.repeat(" ", t), i = 0, s = -1, o = "", a, n = e.length; i < n; )
    s = e.indexOf(`
`, i), s === -1 ? (a = e.slice(i), i = n) : (a = e.slice(i, s + 1), i = s + 1), a.length && a !== `
` && (o += r), o += a;
  return o;
}
p(Fa, "indentString");
function js(e, t) {
  return `
` + Ot.repeat(" ", e.indent * t);
}
p(js, "generateNextLine");
function Vu(e, t) {
  var r, i, s;
  for (r = 0, i = e.implicitTypes.length; r < i; r += 1)
    if (s = e.implicitTypes[r], s.resolve(t))
      return !0;
  return !1;
}
p(Vu, "testImplicitResolving");
function Ri(e) {
  return e === Zk || e === Xk;
}
p(Ri, "isWhitespace");
function Zr(e) {
  return 32 <= e && e <= 126 || 161 <= e && e <= 55295 && e !== 8232 && e !== 8233 || 57344 <= e && e <= 65533 && e !== Mn || 65536 <= e && e <= 1114111;
}
p(Zr, "isPrintable");
function Aa(e) {
  return Zr(e) && e !== Mn && e !== Vk && e !== Ii;
}
p(Aa, "isNsCharOrWhitespace");
function Ma(e, t, r) {
  var i = Aa(e), s = i && !Ri(e);
  return (
    // ns-plain-safe
    (r ? (
      // c = flow-in
      i
    ) : i && e !== Wu && e !== zu && e !== Hu && e !== Yu && e !== Uu) && e !== La && !(t === Gs && !s) || Aa(t) && !Ri(t) && e === La || t === Gs && s
  );
}
p(Ma, "isPlainSafe");
function Zu(e) {
  return Zr(e) && e !== Mn && !Ri(e) && e !== i1 && e !== a1 && e !== Gs && e !== Wu && e !== zu && e !== Hu && e !== Yu && e !== Uu && e !== La && e !== t1 && e !== r1 && e !== Kk && e !== h1 && e !== s1 && e !== o1 && e !== e1 && e !== Qk && e !== Jk && e !== n1 && e !== l1;
}
p(Zu, "isPlainSafeFirst");
function Ku(e) {
  return !Ri(e) && e !== Gs;
}
p(Ku, "isPlainSafeLast");
function qr(e, t) {
  var r = e.charCodeAt(t), i;
  return r >= 55296 && r <= 56319 && t + 1 < e.length && (i = e.charCodeAt(t + 1), i >= 56320 && i <= 57343) ? (r - 55296) * 1024 + i - 56320 + 65536 : r;
}
p(qr, "codePointAt");
function En(e) {
  var t = /^\n* /;
  return t.test(e);
}
p(En, "needIndentIndicator");
var Qu = 1, Ea = 2, Ju = 3, tf = 4, Rr = 5;
function ef(e, t, r, i, s, o, a, n) {
  var l, c = 0, h = null, d = !1, f = !1, u = i !== -1, g = -1, m = Zu(qr(e, 0)) && Ku(qr(e, e.length - 1));
  if (t || a)
    for (l = 0; l < e.length; c >= 65536 ? l += 2 : l++) {
      if (c = qr(e, l), !Zr(c))
        return Rr;
      m = m && Ma(c, h, n), h = c;
    }
  else {
    for (l = 0; l < e.length; c >= 65536 ? l += 2 : l++) {
      if (c = qr(e, l), c === Ii)
        d = !0, u && (f = f || // Foldable line = too long, and not more-indented.
        l - g - 1 > i && e[g + 1] !== " ", g = l);
      else if (!Zr(c))
        return Rr;
      m = m && Ma(c, h, n), h = c;
    }
    f = f || u && l - g - 1 > i && e[g + 1] !== " ";
  }
  return !d && !f ? m && !a && !s(e) ? Qu : o === Di ? Rr : Ea : r > 9 && En(e) ? Rr : a ? o === Di ? Rr : Ea : f ? tf : Ju;
}
p(ef, "chooseScalarStyle");
function rf(e, t, r, i, s) {
  e.dump = (function() {
    if (t.length === 0)
      return e.quotingType === Di ? '""' : "''";
    if (!e.noCompatMode && (c1.indexOf(t) !== -1 || d1.test(t)))
      return e.quotingType === Di ? '"' + t + '"' : "'" + t + "'";
    var o = e.indent * Math.max(1, r), a = e.lineWidth === -1 ? -1 : Math.max(Math.min(e.lineWidth, 40), e.lineWidth - o), n = i || e.flowLevel > -1 && r >= e.flowLevel;
    function l(c) {
      return Vu(e, c);
    }
    switch (p(l, "testAmbiguity"), ef(
      t,
      n,
      e.indent,
      a,
      l,
      e.quotingType,
      e.forceQuotes && !i,
      s
    )) {
      case Qu:
        return t;
      case Ea:
        return "'" + t.replace(/'/g, "''") + "'";
      case Ju:
        return "|" + $a(t, e.indent) + Oa(Fa(t, o));
      case tf:
        return ">" + $a(t, e.indent) + Oa(Fa(sf(t, a), o));
      case Rr:
        return '"' + of(t) + '"';
      default:
        throw new te("impossible error: invalid scalar style");
    }
  })();
}
p(rf, "writeScalar");
function $a(e, t) {
  var r = En(e) ? String(t) : "", i = e[e.length - 1] === `
`, s = i && (e[e.length - 2] === `
` || e === `
`), o = s ? "+" : i ? "" : "-";
  return r + o + `
`;
}
p($a, "blockHeader");
function Oa(e) {
  return e[e.length - 1] === `
` ? e.slice(0, -1) : e;
}
p(Oa, "dropEndingNewline");
function sf(e, t) {
  for (var r = /(\n+)([^\n]*)/g, i = (function() {
    var c = e.indexOf(`
`);
    return c = c !== -1 ? c : e.length, r.lastIndex = c, Ia(e.slice(0, c), t);
  })(), s = e[0] === `
` || e[0] === " ", o, a; a = r.exec(e); ) {
    var n = a[1], l = a[2];
    o = l[0] === " ", i += n + (!s && !o && l !== "" ? `
` : "") + Ia(l, t), s = o;
  }
  return i;
}
p(sf, "foldString");
function Ia(e, t) {
  if (e === "" || e[0] === " ") return e;
  for (var r = / [^ ]/g, i, s = 0, o, a = 0, n = 0, l = ""; i = r.exec(e); )
    n = i.index, n - s > t && (o = a > s ? a : n, l += `
` + e.slice(s, o), s = o + 1), a = n;
  return l += `
`, e.length - s > t && a > s ? l += e.slice(s, a) + `
` + e.slice(a + 1) : l += e.slice(s), l.slice(1);
}
p(Ia, "foldLine");
function of(e) {
  for (var t = "", r = 0, i, s = 0; s < e.length; r >= 65536 ? s += 2 : s++)
    r = qr(e, s), i = Ht[r], !i && Zr(r) ? (t += e[s], r >= 65536 && (t += e[s + 1])) : t += i || ju(r);
  return t;
}
p(of, "escapeString");
function af(e, t, r) {
  var i = "", s = e.tag, o, a, n;
  for (o = 0, a = r.length; o < a; o += 1)
    n = r[o], e.replacer && (n = e.replacer.call(r, String(o), n)), (Be(e, t, n, !1, !1) || typeof n > "u" && Be(e, t, null, !1, !1)) && (i !== "" && (i += "," + (e.condenseFlow ? "" : " ")), i += e.dump);
  e.tag = s, e.dump = "[" + i + "]";
}
p(af, "writeFlowSequence");
function Da(e, t, r, i) {
  var s = "", o = e.tag, a, n, l;
  for (a = 0, n = r.length; a < n; a += 1)
    l = r[a], e.replacer && (l = e.replacer.call(r, String(a), l)), (Be(e, t + 1, l, !0, !0, !1, !0) || typeof l > "u" && Be(e, t + 1, null, !0, !0, !1, !0)) && ((!i || s !== "") && (s += js(e, t)), e.dump && Ii === e.dump.charCodeAt(0) ? s += "-" : s += "- ", s += e.dump);
  e.tag = o, e.dump = s || "[]";
}
p(Da, "writeBlockSequence");
function nf(e, t, r) {
  var i = "", s = e.tag, o = Object.keys(r), a, n, l, c, h;
  for (a = 0, n = o.length; a < n; a += 1)
    h = "", i !== "" && (h += ", "), e.condenseFlow && (h += '"'), l = o[a], c = r[l], e.replacer && (c = e.replacer.call(r, l, c)), Be(e, t, l, !1, !1) && (e.dump.length > 1024 && (h += "? "), h += e.dump + (e.condenseFlow ? '"' : "") + ":" + (e.condenseFlow ? "" : " "), Be(e, t, c, !1, !1) && (h += e.dump, i += h));
  e.tag = s, e.dump = "{" + i + "}";
}
p(nf, "writeFlowMapping");
function lf(e, t, r, i) {
  var s = "", o = e.tag, a = Object.keys(r), n, l, c, h, d, f;
  if (e.sortKeys === !0)
    a.sort();
  else if (typeof e.sortKeys == "function")
    a.sort(e.sortKeys);
  else if (e.sortKeys)
    throw new te("sortKeys must be a boolean or a function");
  for (n = 0, l = a.length; n < l; n += 1)
    f = "", (!i || s !== "") && (f += js(e, t)), c = a[n], h = r[c], e.replacer && (h = e.replacer.call(r, c, h)), Be(e, t + 1, c, !0, !0, !0) && (d = e.tag !== null && e.tag !== "?" || e.dump && e.dump.length > 1024, d && (e.dump && Ii === e.dump.charCodeAt(0) ? f += "?" : f += "? "), f += e.dump, d && (f += js(e, t)), Be(e, t + 1, h, !0, d) && (e.dump && Ii === e.dump.charCodeAt(0) ? f += ":" : f += ": ", f += e.dump, s += f));
  e.tag = o, e.dump = s || "{}";
}
p(lf, "writeBlockMapping");
function Ra(e, t, r) {
  var i, s, o, a, n, l;
  for (s = r ? e.explicitTypes : e.implicitTypes, o = 0, a = s.length; o < a; o += 1)
    if (n = s[o], (n.instanceOf || n.predicate) && (!n.instanceOf || typeof t == "object" && t instanceof n.instanceOf) && (!n.predicate || n.predicate(t))) {
      if (r ? n.multi && n.representName ? e.tag = n.representName(t) : e.tag = n.tag : e.tag = "?", n.represent) {
        if (l = e.styleMap[n.tag] || n.defaultStyle, Nu.call(n.represent) === "[object Function]")
          i = n.represent(t, l);
        else if (qu.call(n.represent, l))
          i = n.represent[l](t, l);
        else
          throw new te("!<" + n.tag + '> tag resolver accepts not "' + l + '" style');
        e.dump = i;
      }
      return !0;
    }
  return !1;
}
p(Ra, "detectType");
function Be(e, t, r, i, s, o, a) {
  e.tag = null, e.dump = r, Ra(e, r, !1) || Ra(e, r, !0);
  var n = Nu.call(e.dump), l = i, c;
  i && (i = e.flowLevel < 0 || e.flowLevel > t);
  var h = n === "[object Object]" || n === "[object Array]", d, f;
  if (h && (d = e.duplicates.indexOf(r), f = d !== -1), (e.tag !== null && e.tag !== "?" || f || e.indent !== 2 && t > 0) && (s = !1), f && e.usedDuplicates[d])
    e.dump = "*ref_" + d;
  else {
    if (h && f && !e.usedDuplicates[d] && (e.usedDuplicates[d] = !0), n === "[object Object]")
      i && Object.keys(e.dump).length !== 0 ? (lf(e, t, e.dump, s), f && (e.dump = "&ref_" + d + e.dump)) : (nf(e, t, e.dump), f && (e.dump = "&ref_" + d + " " + e.dump));
    else if (n === "[object Array]")
      i && e.dump.length !== 0 ? (e.noArrayIndent && !a && t > 0 ? Da(e, t - 1, e.dump, s) : Da(e, t, e.dump, s), f && (e.dump = "&ref_" + d + e.dump)) : (af(e, t, e.dump), f && (e.dump = "&ref_" + d + " " + e.dump));
    else if (n === "[object String]")
      e.tag !== "?" && rf(e, e.dump, t, o, l);
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
p(Be, "writeNode");
function hf(e, t) {
  var r = [], i = [], s, o;
  for (Xs(e, r, i), s = 0, o = i.length; s < o; s += 1)
    t.duplicates.push(r[i[s]]);
  t.usedDuplicates = new Array(o);
}
p(hf, "getDuplicateReferences");
function Xs(e, t, r) {
  var i, s, o;
  if (e !== null && typeof e == "object")
    if (s = t.indexOf(e), s !== -1)
      r.indexOf(s) === -1 && r.push(s);
    else if (t.push(e), Array.isArray(e))
      for (s = 0, o = e.length; s < o; s += 1)
        Xs(e[s], t, r);
    else
      for (i = Object.keys(e), s = 0, o = i.length; s < o; s += 1)
        Xs(e[i[s]], t, r);
}
p(Xs, "inspectNode");
function f1(e, t) {
  t = t || {};
  var r = new Xu(t);
  r.noRefs || hf(e, r);
  var i = e;
  return r.replacer && (i = r.replacer.call({ "": i }, "", i)), Be(r, 0, i, !0, !0) ? r.dump + `
` : "";
}
p(f1, "dump$1");
function p1(e, t) {
  return function() {
    throw new Error("Function yaml." + e + " is removed in js-yaml 4. Use yaml." + t + " instead, which is now safe by default.");
  };
}
p(p1, "renamed");
var g1 = Jd, m1 = jk.load;
/*! Bundled license information:

js-yaml/dist/js-yaml.mjs:
  (*! js-yaml 4.1.1 https://github.com/nodeca/js-yaml @license MIT *)
*/
var li = /* @__PURE__ */ p((e, t) => {
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
}, mh = {
  arrow_point: 4,
  arrow_cross: 12.5,
  arrow_circle: 12.5
};
function xi(e, t) {
  if (e === void 0 || t === void 0)
    return { angle: 0, deltaX: 0, deltaY: 0 };
  e = wt(e), t = wt(t);
  const [r, i] = [e.x, e.y], [s, o] = [t.x, t.y], a = s - r, n = o - i;
  return { angle: Math.atan(n / a), deltaX: a, deltaY: n };
}
p(xi, "calculateDeltaAndAngle");
var wt = /* @__PURE__ */ p((e) => Array.isArray(e) ? { x: e[0], y: e[1] } : e, "pointTransformer"), y1 = /* @__PURE__ */ p((e) => ({
  x: /* @__PURE__ */ p(function(t, r, i) {
    let s = 0;
    const o = wt(i[0]).x < wt(i[i.length - 1]).x ? "left" : "right";
    if (r === 0 && Object.hasOwn(Wt, e.arrowTypeStart)) {
      const { angle: u, deltaX: g } = xi(i[0], i[1]);
      s = Wt[e.arrowTypeStart] * Math.cos(u) * (g >= 0 ? 1 : -1);
    } else if (r === i.length - 1 && Object.hasOwn(Wt, e.arrowTypeEnd)) {
      const { angle: u, deltaX: g } = xi(
        i[i.length - 1],
        i[i.length - 2]
      );
      s = Wt[e.arrowTypeEnd] * Math.cos(u) * (g >= 0 ? 1 : -1);
    }
    const a = Math.abs(
      wt(t).x - wt(i[i.length - 1]).x
    ), n = Math.abs(
      wt(t).y - wt(i[i.length - 1]).y
    ), l = Math.abs(wt(t).x - wt(i[0]).x), c = Math.abs(wt(t).y - wt(i[0]).y), h = Wt[e.arrowTypeStart], d = Wt[e.arrowTypeEnd], f = 1;
    if (a < d && a > 0 && n < d) {
      let u = d + f - a;
      u *= o === "right" ? -1 : 1, s -= u;
    }
    if (l < h && l > 0 && c < h) {
      let u = h + f - l;
      u *= o === "right" ? -1 : 1, s += u;
    }
    return wt(t).x + s;
  }, "x"),
  y: /* @__PURE__ */ p(function(t, r, i) {
    let s = 0;
    const o = wt(i[0]).y < wt(i[i.length - 1]).y ? "down" : "up";
    if (r === 0 && Object.hasOwn(Wt, e.arrowTypeStart)) {
      const { angle: u, deltaY: g } = xi(i[0], i[1]);
      s = Wt[e.arrowTypeStart] * Math.abs(Math.sin(u)) * (g >= 0 ? 1 : -1);
    } else if (r === i.length - 1 && Object.hasOwn(Wt, e.arrowTypeEnd)) {
      const { angle: u, deltaY: g } = xi(
        i[i.length - 1],
        i[i.length - 2]
      );
      s = Wt[e.arrowTypeEnd] * Math.abs(Math.sin(u)) * (g >= 0 ? 1 : -1);
    }
    const a = Math.abs(
      wt(t).y - wt(i[i.length - 1]).y
    ), n = Math.abs(
      wt(t).x - wt(i[i.length - 1]).x
    ), l = Math.abs(wt(t).y - wt(i[0]).y), c = Math.abs(wt(t).x - wt(i[0]).x), h = Wt[e.arrowTypeStart], d = Wt[e.arrowTypeEnd], f = 1;
    if (a < d && a > 0 && n < d) {
      let u = d + f - a;
      u *= o === "up" ? -1 : 1, s -= u;
    }
    if (l < h && l > 0 && c < h) {
      let u = h + f - l;
      u *= o === "up" ? -1 : 1, s += u;
    }
    return wt(t).y + s;
  }, "y")
}), "getLineFunctionsWithOffset"), ns = {}, Et = {}, yh;
function C1() {
  return yh || (yh = 1, Object.defineProperty(Et, "__esModule", { value: !0 }), Et.BLANK_URL = Et.relativeFirstCharacters = Et.whitespaceEscapeCharsRegex = Et.urlSchemeRegex = Et.ctrlCharactersRegex = Et.htmlCtrlEntityRegex = Et.htmlEntitiesRegex = Et.invalidProtocolRegex = void 0, Et.invalidProtocolRegex = /^([^\w]*)(javascript|data|vbscript)/im, Et.htmlEntitiesRegex = /&#(\w+)(^\w|;)?/g, Et.htmlCtrlEntityRegex = /&(newline|tab);/gi, Et.ctrlCharactersRegex = /[\u0000-\u001F\u007F-\u009F\u2000-\u200D\uFEFF]/gim, Et.urlSchemeRegex = /^.+(:|&colon;)/gim, Et.whitespaceEscapeCharsRegex = /(\\|%5[cC])((%(6[eE]|72|74))|[nrt])/g, Et.relativeFirstCharacters = [".", "/"], Et.BLANK_URL = "about:blank"), Et;
}
var Ch;
function x1() {
  if (Ch) return ns;
  Ch = 1, Object.defineProperty(ns, "__esModule", { value: !0 }), ns.sanitizeUrl = o;
  var e = C1();
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
    var h = c.trimStart(), d = h.match(e.urlSchemeRegex);
    if (!d)
      return c;
    var f = d[0].toLowerCase().trim();
    if (e.invalidProtocolRegex.test(f))
      return e.BLANK_URL;
    var u = h.replace(/\\/g, "/");
    if (f === "mailto:" || f.includes("://"))
      return u;
    if (f === "http:" || f === "https:") {
      if (!i(u))
        return e.BLANK_URL;
      var g = new URL(u);
      return g.protocol = g.protocol.toLowerCase(), g.hostname = g.hostname.toLowerCase(), g.toString();
    }
    return u;
  }
  return ns;
}
var b1 = x1();
function k1(e) {
  return Number.isSafeInteger(e) && e >= 0;
}
function cf(e) {
  return e != null && typeof e != "function" && k1(e.length);
}
function w1(e) {
  return e === "__proto__";
}
function $n(e) {
  return e == null || typeof e != "object" && typeof e != "function";
}
function df(e) {
  return Object.getOwnPropertySymbols(e).filter((t) => Object.prototype.propertyIsEnumerable.call(e, t));
}
function On(e) {
  return e == null ? e === void 0 ? "[object Undefined]" : "[object Null]" : Object.prototype.toString.call(e);
}
const T1 = "[object RegExp]", uf = "[object String]", ff = "[object Number]", pf = "[object Boolean]", gf = "[object Arguments]", S1 = "[object Symbol]", _1 = "[object Date]", B1 = "[object Map]", v1 = "[object Set]", L1 = "[object Array]", F1 = "[object ArrayBuffer]", mf = "[object Object]", A1 = "[object DataView]", M1 = "[object Uint8Array]", E1 = "[object Uint8ClampedArray]", $1 = "[object Uint16Array]", O1 = "[object Uint32Array]", I1 = "[object Int8Array]", D1 = "[object Int16Array]", R1 = "[object Int32Array]", P1 = "[object Float32Array]", N1 = "[object Float64Array]", xh = typeof globalThis == "object" && globalThis || typeof window == "object" && window || typeof self == "object" && self || typeof global == "object" && global || /* @__PURE__ */ (function() {
  return this;
})() || Function("return this")();
function In(e) {
  return typeof xh.Buffer < "u" && xh.Buffer.isBuffer(e);
}
function Dn(e) {
  return ArrayBuffer.isView(e) && !(e instanceof DataView);
}
function q1(e, t) {
  return Wr(e, void 0, e, /* @__PURE__ */ new Map(), t);
}
function Wr(e, t, r, i = /* @__PURE__ */ new Map(), s = void 0) {
  const o = s?.(e, t, r, i);
  if (o !== void 0)
    return o;
  if ($n(e))
    return e;
  if (i.has(e))
    return i.get(e);
  if (Array.isArray(e)) {
    const a = new Array(e.length);
    i.set(e, a);
    for (let n = 0; n < e.length; n++)
      a[n] = Wr(e[n], n, r, i, s);
    return Object.hasOwn(e, "index") && (a.index = e.index), Object.hasOwn(e, "input") && (a.input = e.input), a;
  }
  if (e instanceof Date)
    return new Date(e.getTime());
  if (e instanceof RegExp) {
    const a = new RegExp(e.source, e.flags);
    return a.lastIndex = e.lastIndex, a;
  }
  if (e instanceof Map) {
    const a = /* @__PURE__ */ new Map();
    i.set(e, a);
    for (const [n, l] of e)
      a.set(n, Wr(l, n, r, i, s));
    return a;
  }
  if (e instanceof Set) {
    const a = /* @__PURE__ */ new Set();
    i.set(e, a);
    for (const n of e)
      a.add(Wr(n, void 0, r, i, s));
    return a;
  }
  if (In(e))
    return e.subarray();
  if (Dn(e)) {
    const a = new (Object.getPrototypeOf(e)).constructor(e.length);
    i.set(e, a);
    for (let n = 0; n < e.length; n++)
      a[n] = Wr(e[n], n, r, i, s);
    return a;
  }
  if (e instanceof ArrayBuffer || typeof SharedArrayBuffer < "u" && e instanceof SharedArrayBuffer)
    return e.slice(0);
  if (e instanceof DataView) {
    const a = new DataView(e.buffer.slice(0), e.byteOffset, e.byteLength);
    return i.set(e, a), he(a, e, r, i, s), a;
  }
  if (typeof File < "u" && e instanceof File) {
    const a = new File([e], e.name, {
      type: e.type
    });
    return i.set(e, a), he(a, e, r, i, s), a;
  }
  if (typeof Blob < "u" && e instanceof Blob) {
    const a = new Blob([e], { type: e.type });
    return i.set(e, a), he(a, e, r, i, s), a;
  }
  if (e instanceof Error) {
    const a = structuredClone(e);
    return i.set(e, a), a.message = e.message, a.name = e.name, a.stack = e.stack, a.cause = e.cause, a.constructor = e.constructor, he(a, e, r, i, s), a;
  }
  if (e instanceof Boolean) {
    const a = new Boolean(e.valueOf());
    return i.set(e, a), he(a, e, r, i, s), a;
  }
  if (e instanceof Number) {
    const a = new Number(e.valueOf());
    return i.set(e, a), he(a, e, r, i, s), a;
  }
  if (e instanceof String) {
    const a = new String(e.valueOf());
    return i.set(e, a), he(a, e, r, i, s), a;
  }
  if (typeof e == "object" && W1(e)) {
    const a = Object.create(Object.getPrototypeOf(e));
    return i.set(e, a), he(a, e, r, i, s), a;
  }
  return e;
}
function he(e, t, r = e, i, s) {
  const o = [...Object.keys(t), ...df(t)];
  for (let a = 0; a < o.length; a++) {
    const n = o[a], l = Object.getOwnPropertyDescriptor(e, n);
    (l == null || l.writable) && (e[n] = Wr(t[n], n, r, i, s));
  }
}
function W1(e) {
  switch (On(e)) {
    case gf:
    case L1:
    case F1:
    case A1:
    case pf:
    case _1:
    case P1:
    case N1:
    case I1:
    case D1:
    case R1:
    case B1:
    case ff:
    case mf:
    case T1:
    case v1:
    case uf:
    case S1:
    case M1:
    case E1:
    case $1:
    case O1:
      return !0;
    default:
      return !1;
  }
}
function z1(e, t) {
  return q1(e, (r, i, s, o) => {
    if (typeof e == "object") {
      if (On(e) === mf && typeof e.constructor != "function") {
        const a = {};
        return o.set(e, a), he(a, e, s, o), a;
      }
      switch (Object.prototype.toString.call(e)) {
        case ff:
        case uf:
        case pf: {
          const a = new e.constructor(e?.valueOf());
          return he(a, e), a;
        }
        case gf: {
          const a = {};
          return he(a, e), a.length = e.length, a[Symbol.iterator] = e[Symbol.iterator], a;
        }
        default:
          return;
      }
    }
  });
}
function bh(e) {
  return z1(e);
}
function Pa(e) {
  return e !== null && typeof e == "object" && On(e) === "[object Arguments]";
}
function Na(e) {
  return typeof e == "object" && e !== null;
}
function H1(e) {
  return Na(e) && cf(e);
}
function Gi(e, t) {
  if (typeof e != "function" || t != null && typeof t != "function")
    throw new TypeError("Expected a function");
  const r = function(...s) {
    const o = t ? t.apply(this, s) : s[0], a = r.cache;
    if (a.has(o))
      return a.get(o);
    const n = e.apply(this, s);
    return r.cache = a.set(o, n) || a, n;
  }, i = Gi.Cache || Map;
  return r.cache = new i(), r;
}
Gi.Cache = Map;
function Y1() {
}
function U1(e) {
  const t = e?.constructor, r = typeof t == "function" ? t.prototype : Object.prototype;
  return e === r;
}
function Ts(e) {
  return Dn(e);
}
function Xo(e) {
  if (typeof e != "object" || e == null)
    return !1;
  if (Object.getPrototypeOf(e) === null)
    return !0;
  if (Object.prototype.toString.call(e) !== "[object Object]") {
    const r = e[Symbol.toStringTag];
    return r == null || !Object.getOwnPropertyDescriptor(e, Symbol.toStringTag)?.writable ? !1 : e.toString() === `[object ${r}]`;
  }
  let t = e;
  for (; Object.getPrototypeOf(t) !== null; )
    t = Object.getPrototypeOf(t);
  return Object.getPrototypeOf(e) === t;
}
function G1(e) {
  if ($n(e))
    return e;
  if (Array.isArray(e) || Dn(e) || e instanceof ArrayBuffer || typeof SharedArrayBuffer < "u" && e instanceof SharedArrayBuffer)
    return e.slice(0);
  const t = Object.getPrototypeOf(e);
  if (t == null)
    return Object.assign(Object.create(t), e);
  const r = t.constructor;
  if (e instanceof Date || e instanceof Map || e instanceof Set)
    return new r(e);
  if (e instanceof RegExp) {
    const i = new r(e);
    return i.lastIndex = e.lastIndex, i;
  }
  if (e instanceof DataView)
    return new r(e.buffer.slice(0));
  if (e instanceof Error) {
    let i;
    return e instanceof AggregateError ? i = new r(e.errors, e.message, { cause: e.cause }) : i = new r(e.message, { cause: e.cause }), i.stack = e.stack, Object.assign(i, e), i;
  }
  if (typeof File < "u" && e instanceof File)
    return new r([e], e.name, { type: e.type, lastModified: e.lastModified });
  if (typeof e == "object") {
    const i = Object.create(t);
    return Object.assign(i, e);
  }
  return e;
}
function j1(e, ...t) {
  const r = t.slice(0, -1), i = t[t.length - 1];
  let s = e;
  for (let o = 0; o < r.length; o++) {
    const a = r[o];
    s = Ss(s, a, i, /* @__PURE__ */ new Map());
  }
  return s;
}
function Ss(e, t, r, i) {
  if ($n(e) && (e = Object(e)), t == null || typeof t != "object")
    return e;
  if (i.has(t))
    return G1(i.get(t));
  if (i.set(t, e), Array.isArray(t)) {
    t = t.slice();
    for (let o = 0; o < t.length; o++)
      t[o] = t[o] ?? void 0;
  }
  const s = [...Object.keys(t), ...df(t)];
  for (let o = 0; o < s.length; o++) {
    const a = s[o];
    if (w1(a))
      continue;
    let n = t[a], l = e[a];
    if (Pa(n) && (n = { ...n }), Pa(l) && (l = { ...l }), In(n) && (n = bh(n)), Array.isArray(n))
      if (Array.isArray(l)) {
        const h = [], d = Reflect.ownKeys(l);
        for (let f = 0; f < d.length; f++) {
          const u = d[f];
          h[u] = l[u];
        }
        l = h;
      } else if (H1(l)) {
        const h = [];
        for (let d = 0; d < l.length; d++)
          h[d] = l[d];
        l = h;
      } else
        l = [];
    const c = r(l, n, a, e, t, i);
    c !== void 0 ? e[a] = c : Array.isArray(n) || Na(l) && Na(n) && (Xo(l) || Xo(n) || Ts(l) || Ts(n)) ? e[a] = Ss(l, n, r, i) : l == null && Xo(n) ? e[a] = Ss({}, n, r, i) : l == null && Ts(n) ? e[a] = bh(n) : (l === void 0 || n !== void 0) && (e[a] = n);
  }
  return e;
}
function X1(e, ...t) {
  return j1(e, ...t, Y1);
}
function kh(e) {
  if (e == null)
    return !0;
  if (cf(e))
    return typeof e.splice != "function" && typeof e != "string" && !In(e) && !Ts(e) && !Pa(e) ? !1 : e.length === 0;
  if (typeof e == "object") {
    if (e instanceof Map || e instanceof Set)
      return e.size === 0;
    const t = Object.keys(e);
    return U1(e) ? t.filter((r) => r !== "constructor").length === 0 : t.length === 0;
  }
  return !0;
}
var V1 = "​", Z1 = {
  curveBasis: wa,
  curveBasisClosed: ek,
  curveBasisOpen: rk,
  curveBumpX: ld,
  curveBumpY: hd,
  curveBundle: ik,
  curveCardinalClosed: sk,
  curveCardinalOpen: ok,
  curveCardinal: fd,
  curveCatmullRomClosed: ak,
  curveCatmullRomOpen: nk,
  curveCatmullRom: gd,
  curveLinear: Bi,
  curveLinearClosed: lk,
  curveMonotoneX: kd,
  curveMonotoneY: wd,
  curveNatural: Sd,
  curveStep: _d,
  curveStepAfter: vd,
  curveStepBefore: Bd
}, K1 = /\s*(?:(\w+)(?=:):|(\w+))\s*(?:(\w+)|((?:(?!}%{2}).|\r?\n)*))?\s*(?:}%{2})?/gi, Q1 = /* @__PURE__ */ p(function(e, t) {
  const r = yf(e, /(?:init\b)|(?:initialize\b)/);
  let i = {};
  if (Array.isArray(r)) {
    const a = r.map((n) => n.args);
    Fs(a), i = $t(i, [...a]);
  } else
    i = r.args;
  if (!i)
    return;
  let s = nn(e, t);
  const o = "config";
  return i[o] !== void 0 && (s === "flowchart-v2" && (s = "flowchart"), i[s] = i[o], delete i[o]), i;
}, "detectInit"), yf = /* @__PURE__ */ p(function(e, t = null) {
  try {
    const r = new RegExp(
      `[%]{2}(?![{]${K1.source})(?=[}][%]{2}).*
`,
      "ig"
    );
    e = e.trim().replace(r, "").replace(/'/gm, '"'), P.debug(
      `Detecting diagram directive${t !== null ? " type:" + t : ""} based on the text:${e}`
    );
    let i;
    const s = [];
    for (; (i = Si.exec(e)) !== null; )
      if (i.index === Si.lastIndex && Si.lastIndex++, i && !t || t && i[1]?.match(t) || t && i[2]?.match(t)) {
        const o = i[1] ? i[1] : i[2], a = i[3] ? i[3].trim() : i[4] ? JSON.parse(i[4].trim()) : null;
        s.push({ type: o, args: a });
      }
    return s.length === 0 ? { type: e, args: null } : s.length === 1 ? s[0] : s;
  } catch (r) {
    return P.error(
      `ERROR: ${r.message} - Unable to parse directive type: '${t}' based on the text: '${e}'`
    ), { type: void 0, args: null };
  }
}, "detectDirective"), J1 = /* @__PURE__ */ p(function(e) {
  return e.replace(Si, "");
}, "removeDirectives"), t2 = /* @__PURE__ */ p(function(e, t) {
  for (const [r, i] of t.entries())
    if (i.match(e))
      return r;
  return -1;
}, "isSubstringInArray");
function Rn(e, t) {
  if (!e)
    return t;
  const r = `curve${e.charAt(0).toUpperCase() + e.slice(1)}`;
  return Z1[r] ?? t;
}
p(Rn, "interpolateToCurve");
function Cf(e, t) {
  const r = e.trim();
  if (r)
    return t.securityLevel !== "loose" ? b1.sanitizeUrl(r) : r;
}
p(Cf, "formatUrl");
var e2 = /* @__PURE__ */ p((e, ...t) => {
  const r = e.split("."), i = r.length - 1, s = r[i];
  let o = window;
  for (let a = 0; a < i; a++)
    if (o = o[r[a]], !o) {
      P.error(`Function name: ${e} not found in window`);
      return;
    }
  o[s](...t);
}, "runFunc");
function Pn(e, t) {
  return !e || !t ? 0 : Math.sqrt(Math.pow(t.x - e.x, 2) + Math.pow(t.y - e.y, 2));
}
p(Pn, "distance");
function xf(e) {
  let t, r = 0;
  e.forEach((s) => {
    r += Pn(s, t), t = s;
  });
  const i = r / 2;
  return Nn(e, i);
}
p(xf, "traverseEdge");
function bf(e) {
  return e.length === 1 ? e[0] : xf(e);
}
p(bf, "calcLabelPosition");
var wh = /* @__PURE__ */ p((e, t = 2) => {
  const r = Math.pow(10, t);
  return Math.round(e * r) / r;
}, "roundNumber"), Nn = /* @__PURE__ */ p((e, t) => {
  let r, i = t;
  for (const s of e) {
    if (r) {
      const o = Pn(s, r);
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
            x: wh((1 - a) * r.x + a * s.x, 5),
            y: wh((1 - a) * r.y + a * s.y, 5)
          };
      }
    }
    r = s;
  }
  throw new Error("Could not find a suitable point for the given distance");
}, "calculatePoint"), r2 = /* @__PURE__ */ p((e, t, r) => {
  P.info(`our points ${JSON.stringify(t)}`), t[0] !== r && (t = t.reverse());
  const s = Nn(t, 25), o = e ? 10 : 5, a = Math.atan2(t[0].y - s.y, t[0].x - s.x), n = { x: 0, y: 0 };
  return n.x = Math.sin(a) * o + (t[0].x + s.x) / 2, n.y = -Math.cos(a) * o + (t[0].y + s.y) / 2, n;
}, "calcCardinalityPosition");
function kf(e, t, r) {
  const i = structuredClone(r);
  P.info("our points", i), t !== "start_left" && t !== "start_right" && i.reverse();
  const s = 25 + e, o = Nn(i, s), a = 10 + e * 0.5, n = Math.atan2(i[0].y - o.y, i[0].x - o.x), l = { x: 0, y: 0 };
  return t === "start_left" ? (l.x = Math.sin(n + Math.PI) * a + (i[0].x + o.x) / 2, l.y = -Math.cos(n + Math.PI) * a + (i[0].y + o.y) / 2) : t === "end_right" ? (l.x = Math.sin(n - Math.PI) * a + (i[0].x + o.x) / 2 - 5, l.y = -Math.cos(n - Math.PI) * a + (i[0].y + o.y) / 2 - 5) : t === "end_left" ? (l.x = Math.sin(n) * a + (i[0].x + o.x) / 2 - 5, l.y = -Math.cos(n) * a + (i[0].y + o.y) / 2 - 5) : (l.x = Math.sin(n) * a + (i[0].x + o.x) / 2, l.y = -Math.cos(n) * a + (i[0].y + o.y) / 2), l;
}
p(kf, "calcTerminalLabelPosition");
function wf(e) {
  let t = "", r = "";
  for (const i of e)
    i !== void 0 && (i.startsWith("color:") || i.startsWith("text-align:") ? r = r + i + ";" : t = t + i + ";");
  return { style: t, labelStyle: r };
}
p(wf, "getStylesFromArray");
var Th = 0, i2 = /* @__PURE__ */ p(() => (Th++, "id-" + Math.random().toString(36).substr(2, 12) + "-" + Th), "generateId");
function Tf(e) {
  let t = "";
  const r = "0123456789abcdef", i = r.length;
  for (let s = 0; s < e; s++)
    t += r.charAt(Math.floor(Math.random() * i));
  return t;
}
p(Tf, "makeRandomHex");
var s2 = /* @__PURE__ */ p((e) => Tf(e.length), "random"), o2 = /* @__PURE__ */ p(function() {
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
}, "getTextObj"), a2 = /* @__PURE__ */ p(function(e, t) {
  const r = t.text.replace(zi.lineBreakRegex, " "), [, i] = mo(t.fontSize), s = e.append("text");
  s.attr("x", t.x), s.attr("y", t.y), s.style("text-anchor", t.anchor), s.style("font-family", t.fontFamily), s.style("font-size", i), s.style("font-weight", t.fontWeight), s.attr("fill", t.fill), t.class !== void 0 && s.attr("class", t.class);
  const o = s.append("tspan");
  return o.attr("x", t.x + t.textMargin * 2), o.attr("fill", t.fill), o.text(r), s;
}, "drawSimpleText"), n2 = Gi(
  (e, t, r) => {
    if (!e || (r = Object.assign(
      { fontSize: 12, fontWeight: 400, fontFamily: "Arial", joinWith: "<br/>" },
      r
    ), zi.lineBreakRegex.test(e)))
      return e;
    const i = e.split(" ").filter(Boolean), s = [];
    let o = "";
    return i.forEach((a, n) => {
      const l = qe(`${a} `, r), c = qe(o, r);
      if (l > t) {
        const { hyphenatedStrings: f, remainingWord: u } = l2(a, t, "-", r);
        s.push(o, ...f), o = u;
      } else c + l >= t ? (s.push(o), o = a) : o = [o, a].filter(Boolean).join(" ");
      n + 1 === i.length && s.push(o);
    }), s.filter((a) => a !== "").join(r.joinWith);
  },
  (e, t, r) => `${e}${t}${r.fontSize}${r.fontWeight}${r.fontFamily}${r.joinWith}`
), l2 = Gi(
  (e, t, r = "-", i) => {
    i = Object.assign(
      { fontSize: 12, fontWeight: 400, fontFamily: "Arial", margin: 0 },
      i
    );
    const s = [...e], o = [];
    let a = "";
    return s.forEach((n, l) => {
      const c = `${a}${n}`;
      if (qe(c, i) >= t) {
        const d = l + 1, f = s.length === d, u = `${c}${r}`;
        o.push(f ? c : u), a = "";
      } else
        a = c;
    }), { hyphenatedStrings: o, remainingWord: a };
  },
  (e, t, r = "-", i) => `${e}${t}${r}${i.fontSize}${i.fontWeight}${i.fontFamily}`
);
function Sf(e, t) {
  return qn(e, t).height;
}
p(Sf, "calculateTextHeight");
function qe(e, t) {
  return qn(e, t).width;
}
p(qe, "calculateTextWidth");
var qn = Gi(
  (e, t) => {
    const { fontSize: r = 12, fontFamily: i = "Arial", fontWeight: s = 400 } = t;
    if (!e)
      return { width: 0, height: 0 };
    const [, o] = mo(r), a = ["sans-serif", i], n = e.split(zi.lineBreakRegex), l = [], c = ht("body");
    if (!c.remove)
      return { width: 0, height: 0, lineHeight: 0 };
    const h = c.append("svg");
    for (const f of a) {
      let u = 0;
      const g = { width: 0, height: 0, lineHeight: 0 };
      for (const m of n) {
        const y = o2();
        y.text = m || V1;
        const C = a2(h, y).style("font-size", o).style("font-weight", s).style("font-family", f), b = (C._groups || C)[0][0].getBBox();
        if (b.width === 0 && b.height === 0)
          throw new Error("svg element not in render tree");
        g.width = Math.round(Math.max(g.width, b.width)), u = Math.round(b.height), g.height += u, g.lineHeight = Math.round(Math.max(g.lineHeight, u));
      }
      l.push(g);
    }
    h.remove();
    const d = isNaN(l[1].height) || isNaN(l[1].width) || isNaN(l[1].lineHeight) || l[0].height > l[1].height && l[0].width > l[1].width && l[0].lineHeight > l[1].lineHeight ? 0 : 1;
    return l[d];
  },
  (e, t) => `${e}${t.fontSize}${t.fontWeight}${t.fontFamily}`
), h2 = class {
  constructor(e = !1, t) {
    this.count = 0, this.count = t ? t.length : 0, this.next = e ? () => this.count++ : () => Date.now();
  }
  static {
    p(this, "InitIDGenerator");
  }
}, ls, c2 = /* @__PURE__ */ p(function(e) {
  return ls = ls || document.createElement("div"), e = escape(e).replace(/%26/g, "&").replace(/%23/g, "#").replace(/%3B/g, ";"), ls.innerHTML = e, unescape(ls.textContent);
}, "entityDecode");
function Wn(e) {
  return "str" in e;
}
p(Wn, "isDetailedError");
var d2 = /* @__PURE__ */ p((e, t, r, i) => {
  if (!i)
    return;
  const s = e.node()?.getBBox();
  s && e.append("text").text(i).attr("text-anchor", "middle").attr("x", s.x + s.width / 2).attr("y", -r).attr("class", t);
}, "insertTitle"), mo = /* @__PURE__ */ p((e) => {
  if (typeof e == "number")
    return [e, e + "px"];
  const t = parseInt(e ?? "", 10);
  return Number.isNaN(t) ? [void 0, void 0] : e === String(t) ? [t, e + "px"] : [t, e];
}, "parseFontSize");
function zn(e, t) {
  return X1({}, e, t);
}
p(zn, "cleanAndMerge");
var fe = {
  assignWithDepth: $t,
  wrapLabel: n2,
  calculateTextHeight: Sf,
  calculateTextWidth: qe,
  calculateTextDimensions: qn,
  cleanAndMerge: zn,
  detectInit: Q1,
  detectDirective: yf,
  isSubstringInArray: t2,
  interpolateToCurve: Rn,
  calcLabelPosition: bf,
  calcCardinalityPosition: r2,
  calcTerminalLabelPosition: kf,
  formatUrl: Cf,
  getStylesFromArray: wf,
  generateId: i2,
  random: s2,
  runFunc: e2,
  entityDecode: c2,
  insertTitle: d2,
  isLabelCoordinateInPath: _f,
  parseFontSize: mo,
  InitIDGenerator: h2
}, u2 = /* @__PURE__ */ p(function(e) {
  let t = e;
  return t = t.replace(/style.*:\S*#.*;/g, function(r) {
    return r.substring(0, r.length - 1);
  }), t = t.replace(/classDef.*:\S*#.*;/g, function(r) {
    return r.substring(0, r.length - 1);
  }), t = t.replace(/#\w+;/g, function(r) {
    const i = r.substring(1, r.length - 1);
    return /^\+?\d+$/.test(i) ? "ﬂ°°" + i + "¶ß" : "ﬂ°" + i + "¶ß";
  }), t;
}, "encodeEntities"), br = /* @__PURE__ */ p(function(e) {
  return e.replace(/ﬂ°°/g, "&#").replace(/ﬂ°/g, "&").replace(/¶ß/g, ";");
}, "decodeEntities"), Ev = /* @__PURE__ */ p((e, t, {
  counter: r = 0,
  prefix: i,
  suffix: s
}, o) => o || `${i ? `${i}_` : ""}${e}_${t}_${r}${s ? `_${s}` : ""}`, "getEdgeId");
function Dt(e) {
  return e ?? null;
}
p(Dt, "handleUndefinedAttr");
function _f(e, t) {
  const r = Math.round(e.x), i = Math.round(e.y), s = t.replace(
    /(\d+\.\d+)/g,
    (o) => Math.round(parseFloat(o)).toString()
  );
  return s.includes(r.toString()) || s.includes(i.toString());
}
p(_f, "isLabelCoordinateInPath");
var Hn = /* @__PURE__ */ p(({
  flowchart: e
}) => {
  const t = e?.subGraphTitleMargin?.top ?? 0, r = e?.subGraphTitleMargin?.bottom ?? 0, i = t + r;
  return {
    subGraphTitleTopMargin: t,
    subGraphTitleBottomMargin: r,
    subGraphTitleTotalMargin: i
  };
}, "getSubGraphTitleMargins");
async function Bf(e, t) {
  const r = e.getElementsByTagName("img");
  if (!r || r.length === 0)
    return;
  const i = t.replace(/<img[^>]*>/g, "").trim() === "";
  await Promise.all(
    [...r].map(
      (s) => new Promise((o) => {
        function a() {
          if (s.style.display = "flex", s.style.flexDirection = "column", i) {
            const n = gt().fontSize ? gt().fontSize : window.getComputedStyle(document.body).fontSize, l = 5, [c = bc.fontSize] = mo(n), h = c * l + "px";
            s.style.minWidth = h, s.style.maxWidth = h;
          } else
            s.style.width = "100%";
          o(s);
        }
        p(a, "setupImage"), setTimeout(() => {
          s.complete && a();
        }), s.addEventListener("error", a), s.addEventListener("load", a);
      })
    )
  );
}
p(Bf, "configureLabelImages");
var f2 = /* @__PURE__ */ p((e) => {
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
}, "solidStateFill"), Jr = /* @__PURE__ */ p((e) => {
  const t = p2([
    ...e.cssCompiledStyles || [],
    ...e.cssStyles || [],
    ...e.labelStyle || []
  ]);
  return { stylesMap: t, stylesArray: [...t] };
}, "compileStyles"), p2 = /* @__PURE__ */ p((e) => {
  const t = /* @__PURE__ */ new Map();
  return e.forEach((r) => {
    const [i, s] = r.split(":");
    t.set(i.trim(), s?.trim());
  }), t;
}, "styles2Map"), vf = /* @__PURE__ */ p((e) => e === "color" || e === "font-size" || e === "font-family" || e === "font-weight" || e === "font-style" || e === "text-decoration" || e === "text-align" || e === "text-transform" || e === "line-height" || e === "letter-spacing" || e === "word-spacing" || e === "text-shadow" || e === "text-overflow" || e === "white-space" || e === "word-wrap" || e === "word-break" || e === "overflow-wrap" || e === "hyphens", "isLabelStyle"), Z = /* @__PURE__ */ p((e) => {
  const { stylesArray: t } = Jr(e), r = [], i = [], s = [], o = [];
  return t.forEach((a) => {
    const n = a[0];
    vf(n) ? r.push(a.join(":") + " !important") : (i.push(a.join(":") + " !important"), n.includes("stroke") && s.push(a.join(":") + " !important"), n === "fill" && o.push(a.join(":") + " !important"));
  }), {
    labelStyles: r.join(";"),
    nodeStyles: i.join(";"),
    stylesArray: t,
    borderStyles: s,
    backgroundStyles: o
  };
}, "styles2String"), V = /* @__PURE__ */ p((e, t) => {
  const { themeVariables: r, handDrawnSeed: i } = gt(), { nodeBorder: s, mainBkg: o } = r, { stylesMap: a } = Jr(e);
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
      strokeLineDash: g2(a.get("stroke-dasharray"))
    },
    t
  );
}, "userNodeOverrides"), g2 = /* @__PURE__ */ p((e) => {
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
const m2 = Object.freeze({
  left: 0,
  top: 0,
  width: 16,
  height: 16
}), Vs = Object.freeze({
  rotate: 0,
  vFlip: !1,
  hFlip: !1
}), Lf = Object.freeze({
  ...m2,
  ...Vs
}), y2 = Object.freeze({
  ...Lf,
  body: "",
  hidden: !1
}), C2 = Object.freeze({
  width: null,
  height: null
}), x2 = Object.freeze({
  ...C2,
  ...Vs
}), b2 = (e, t, r, i = "") => {
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
    return Vo(c) ? c : null;
  }
  const o = s[0], a = o.split("-");
  if (a.length > 1) {
    const n = {
      provider: i,
      prefix: a.shift(),
      name: a.join("-")
    };
    return Vo(n) ? n : null;
  }
  if (r && i === "") {
    const n = {
      provider: i,
      prefix: "",
      name: o
    };
    return Vo(n, r) ? n : null;
  }
  return null;
}, Vo = (e, t) => e ? !!((t && e.prefix === "" || e.prefix) && e.name) : !1;
function k2(e, t) {
  const r = {};
  !e.hFlip != !t.hFlip && (r.hFlip = !0), !e.vFlip != !t.vFlip && (r.vFlip = !0);
  const i = ((e.rotate || 0) + (t.rotate || 0)) % 4;
  return i && (r.rotate = i), r;
}
function Sh(e, t) {
  const r = k2(e, t);
  for (const i in y2) i in Vs ? i in e && !(i in r) && (r[i] = Vs[i]) : i in t ? r[i] = t[i] : i in e && (r[i] = e[i]);
  return r;
}
function w2(e, t) {
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
function _h(e, t, r) {
  const i = e.icons, s = e.aliases || /* @__PURE__ */ Object.create(null);
  let o = {};
  function a(n) {
    o = Sh(i[n] || s[n], o);
  }
  return a(t), r.forEach(a), Sh(e, o);
}
function T2(e, t) {
  if (e.icons[t]) return _h(e, t, []);
  const r = w2(e, [t])[t];
  return r ? _h(e, t, r) : null;
}
const S2 = /(-?[0-9.]*[0-9]+[0-9.]*)/g, _2 = /^-?[0-9.]*[0-9]+[0-9.]*$/g;
function Bh(e, t, r) {
  if (t === 1) return e;
  if (r = r || 100, typeof e == "number") return Math.ceil(e * t * r) / r;
  if (typeof e != "string") return e;
  const i = e.split(S2);
  if (i === null || !i.length) return e;
  const s = [];
  let o = i.shift(), a = _2.test(o);
  for (; ; ) {
    if (a) {
      const n = parseFloat(o);
      isNaN(n) ? s.push(o) : s.push(Math.ceil(n * t * r) / r);
    } else s.push(o);
    if (o = i.shift(), o === void 0) return s.join("");
    a = !a;
  }
}
function B2(e, t = "defs") {
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
function v2(e, t) {
  return e ? "<defs>" + e + "</defs>" + t : t;
}
function L2(e, t, r) {
  const i = B2(e);
  return v2(i.defs, t + i.content + r);
}
const F2 = (e) => e === "unset" || e === "undefined" || e === "none";
function A2(e, t) {
  const r = {
    ...Lf,
    ...e
  }, i = {
    ...x2,
    ...t
  }, s = {
    left: r.left,
    top: r.top,
    width: r.width,
    height: r.height
  };
  let o = r.body;
  [r, i].forEach((m) => {
    const y = [], C = m.hFlip, b = m.vFlip;
    let k = m.rotate;
    C ? b ? k += 2 : (y.push("translate(" + (s.width + s.left).toString() + " " + (0 - s.top).toString() + ")"), y.push("scale(-1 1)"), s.top = s.left = 0) : b && (y.push("translate(" + (0 - s.left).toString() + " " + (s.height + s.top).toString() + ")"), y.push("scale(1 -1)"), s.top = s.left = 0);
    let T;
    switch (k < 0 && (k -= Math.floor(k / 4) * 4), k = k % 4, k) {
      case 1:
        T = s.height / 2 + s.top, y.unshift("rotate(90 " + T.toString() + " " + T.toString() + ")");
        break;
      case 2:
        y.unshift("rotate(180 " + (s.width / 2 + s.left).toString() + " " + (s.height / 2 + s.top).toString() + ")");
        break;
      case 3:
        T = s.width / 2 + s.left, y.unshift("rotate(-90 " + T.toString() + " " + T.toString() + ")");
        break;
    }
    k % 2 === 1 && (s.left !== s.top && (T = s.left, s.left = s.top, s.top = T), s.width !== s.height && (T = s.width, s.width = s.height, s.height = T)), y.length && (o = L2(o, '<g transform="' + y.join(" ") + '">', "</g>"));
  });
  const a = i.width, n = i.height, l = s.width, c = s.height;
  let h, d;
  a === null ? (d = n === null ? "1em" : n === "auto" ? c : n, h = Bh(d, l / c)) : (h = a === "auto" ? l : a, d = n === null ? Bh(h, c / l) : n === "auto" ? c : n);
  const f = {}, u = (m, y) => {
    F2(y) || (f[m] = y.toString());
  };
  u("width", h), u("height", d);
  const g = [
    s.left,
    s.top,
    l,
    c
  ];
  return f.viewBox = g.join(" "), {
    attributes: f,
    viewBox: g,
    body: o
  };
}
const M2 = /\sid="(\S+)"/g, vh = /* @__PURE__ */ new Map();
function E2(e) {
  e = e.replace(/[0-9]+$/, "") || "a";
  const t = vh.get(e) || 0;
  return vh.set(e, t + 1), t ? `${e}${t}` : e;
}
function $2(e) {
  const t = [];
  let r;
  for (; r = M2.exec(e); ) t.push(r[1]);
  if (!t.length) return e;
  const i = "suffix" + (Math.random() * 16777216 | Date.now()).toString(16);
  return t.forEach((s) => {
    const o = E2(s), a = s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    e = e.replace(new RegExp('([#;"])(' + a + ')([")]|\\.[a-z])', "g"), "$1" + o + i + "$3");
  }), e = e.replace(new RegExp(i, "g"), ""), e;
}
function O2(e, t) {
  let r = e.indexOf("xlink:") === -1 ? "" : ' xmlns:xlink="http://www.w3.org/1999/xlink"';
  for (const i in t) r += " " + i + '="' + t[i] + '"';
  return '<svg xmlns="http://www.w3.org/2000/svg"' + r + ">" + e + "</svg>";
}
function Yn() {
  return { async: !1, breaks: !1, extensions: null, gfm: !0, hooks: null, pedantic: !1, renderer: null, silent: !1, tokenizer: null, walkTokens: null };
}
var Tr = Yn();
function Ff(e) {
  Tr = e;
}
var vi = { exec: () => null };
function mt(e, t = "") {
  let r = typeof e == "string" ? e : e.source, i = { replace: (s, o) => {
    let a = typeof o == "string" ? o : o.source;
    return a = a.replace(jt.caret, "$1"), r = r.replace(s, a), i;
  }, getRegex: () => new RegExp(r, t) };
  return i;
}
var I2 = (() => {
  try {
    return !!new RegExp("(?<=1)(?<!1)");
  } catch {
    return !1;
  }
})(), jt = { codeRemoveIndent: /^(?: {1,4}| {0,3}\t)/gm, outputLinkReplace: /\\([\[\]])/g, indentCodeCompensation: /^(\s+)(?:```)/, beginningSpace: /^\s+/, endingHash: /#$/, startingSpaceChar: /^ /, endingSpaceChar: / $/, nonSpaceChar: /[^ ]/, newLineCharGlobal: /\n/g, tabCharGlobal: /\t/g, multipleSpaceGlobal: /\s+/g, blankLine: /^[ \t]*$/, doubleBlankLine: /\n[ \t]*\n[ \t]*$/, blockquoteStart: /^ {0,3}>/, blockquoteSetextReplace: /\n {0,3}((?:=+|-+) *)(?=\n|$)/g, blockquoteSetextReplace2: /^ {0,3}>[ \t]?/gm, listReplaceTabs: /^\t+/, listReplaceNesting: /^ {1,4}(?=( {4})*[^ ])/g, listIsTask: /^\[[ xX]\] /, listReplaceTask: /^\[[ xX]\] +/, anyLine: /\n.*\n/, hrefBrackets: /^<(.*)>$/, tableDelimiter: /[:|]/, tableAlignChars: /^\||\| *$/g, tableRowBlankLine: /\n[ \t]*$/, tableAlignRight: /^ *-+: *$/, tableAlignCenter: /^ *:-+: *$/, tableAlignLeft: /^ *:-+ *$/, startATag: /^<a /i, endATag: /^<\/a>/i, startPreScriptTag: /^<(pre|code|kbd|script)(\s|>)/i, endPreScriptTag: /^<\/(pre|code|kbd|script)(\s|>)/i, startAngleBracket: /^</, endAngleBracket: />$/, pedanticHrefTitle: /^([^'"]*[^\s])\s+(['"])(.*)\2/, unicodeAlphaNumeric: /[\p{L}\p{N}]/u, escapeTest: /[&<>"']/, escapeReplace: /[&<>"']/g, escapeTestNoEncode: /[<>"']|&(?!(#\d{1,7}|#[Xx][a-fA-F0-9]{1,6}|\w+);)/, escapeReplaceNoEncode: /[<>"']|&(?!(#\d{1,7}|#[Xx][a-fA-F0-9]{1,6}|\w+);)/g, unescapeTest: /&(#(?:\d+)|(?:#x[0-9A-Fa-f]+)|(?:\w+));?/ig, caret: /(^|[^\[])\^/g, percentDecode: /%25/g, findPipe: /\|/g, splitPipe: / \|/, slashPipe: /\\\|/g, carriageReturn: /\r\n|\r/g, spaceLine: /^ +$/gm, notSpaceStart: /^\S*/, endingNewline: /\n$/, listItemRegex: (e) => new RegExp(`^( {0,3}${e})((?:[	 ][^\\n]*)?(?:\\n|$))`), nextBulletRegex: (e) => new RegExp(`^ {0,${Math.min(3, e - 1)}}(?:[*+-]|\\d{1,9}[.)])((?:[ 	][^\\n]*)?(?:\\n|$))`), hrRegex: (e) => new RegExp(`^ {0,${Math.min(3, e - 1)}}((?:- *){3,}|(?:_ *){3,}|(?:\\* *){3,})(?:\\n+|$)`), fencesBeginRegex: (e) => new RegExp(`^ {0,${Math.min(3, e - 1)}}(?:\`\`\`|~~~)`), headingBeginRegex: (e) => new RegExp(`^ {0,${Math.min(3, e - 1)}}#`), htmlBeginRegex: (e) => new RegExp(`^ {0,${Math.min(3, e - 1)}}<(?:[a-z].*>|!--)`, "i") }, D2 = /^(?:[ \t]*(?:\n|$))+/, R2 = /^((?: {4}| {0,3}\t)[^\n]+(?:\n(?:[ \t]*(?:\n|$))*)?)+/, P2 = /^ {0,3}(`{3,}(?=[^`\n]*(?:\n|$))|~{3,})([^\n]*)(?:\n|$)(?:|([\s\S]*?)(?:\n|$))(?: {0,3}\1[~`]* *(?=\n|$)|$)/, ji = /^ {0,3}((?:-[\t ]*){3,}|(?:_[ \t]*){3,}|(?:\*[ \t]*){3,})(?:\n+|$)/, N2 = /^ {0,3}(#{1,6})(?=\s|$)(.*)(?:\n+|$)/, Un = /(?:[*+-]|\d{1,9}[.)])/, Af = /^(?!bull |blockCode|fences|blockquote|heading|html|table)((?:.|\n(?!\s*?\n|bull |blockCode|fences|blockquote|heading|html|table))+?)\n {0,3}(=+|-+) *(?:\n+|$)/, Mf = mt(Af).replace(/bull/g, Un).replace(/blockCode/g, /(?: {4}| {0,3}\t)/).replace(/fences/g, / {0,3}(?:`{3,}|~{3,})/).replace(/blockquote/g, / {0,3}>/).replace(/heading/g, / {0,3}#{1,6}/).replace(/html/g, / {0,3}<[^\n>]+>\n/).replace(/\|table/g, "").getRegex(), q2 = mt(Af).replace(/bull/g, Un).replace(/blockCode/g, /(?: {4}| {0,3}\t)/).replace(/fences/g, / {0,3}(?:`{3,}|~{3,})/).replace(/blockquote/g, / {0,3}>/).replace(/heading/g, / {0,3}#{1,6}/).replace(/html/g, / {0,3}<[^\n>]+>\n/).replace(/table/g, / {0,3}\|?(?:[:\- ]*\|)+[\:\- ]*\n/).getRegex(), Gn = /^([^\n]+(?:\n(?!hr|heading|lheading|blockquote|fences|list|html|table| +\n)[^\n]+)*)/, W2 = /^[^\n]+/, jn = /(?!\s*\])(?:\\[\s\S]|[^\[\]\\])+/, z2 = mt(/^ {0,3}\[(label)\]: *(?:\n[ \t]*)?([^<\s][^\s]*|<.*?>)(?:(?: +(?:\n[ \t]*)?| *\n[ \t]*)(title))? *(?:\n+|$)/).replace("label", jn).replace("title", /(?:"(?:\\"?|[^"\\])*"|'[^'\n]*(?:\n[^'\n]+)*\n?'|\([^()]*\))/).getRegex(), H2 = mt(/^( {0,3}bull)([ \t][^\n]+?)?(?:\n|$)/).replace(/bull/g, Un).getRegex(), yo = "address|article|aside|base|basefont|blockquote|body|caption|center|col|colgroup|dd|details|dialog|dir|div|dl|dt|fieldset|figcaption|figure|footer|form|frame|frameset|h[1-6]|head|header|hr|html|iframe|legend|li|link|main|menu|menuitem|meta|nav|noframes|ol|optgroup|option|p|param|search|section|summary|table|tbody|td|tfoot|th|thead|title|tr|track|ul", Xn = /<!--(?:-?>|[\s\S]*?(?:-->|$))/, Y2 = mt("^ {0,3}(?:<(script|pre|style|textarea)[\\s>][\\s\\S]*?(?:</\\1>[^\\n]*\\n+|$)|comment[^\\n]*(\\n+|$)|<\\?[\\s\\S]*?(?:\\?>\\n*|$)|<![A-Z][\\s\\S]*?(?:>\\n*|$)|<!\\[CDATA\\[[\\s\\S]*?(?:\\]\\]>\\n*|$)|</?(tag)(?: +|\\n|/?>)[\\s\\S]*?(?:(?:\\n[ 	]*)+\\n|$)|<(?!script|pre|style|textarea)([a-z][\\w-]*)(?:attribute)*? */?>(?=[ \\t]*(?:\\n|$))[\\s\\S]*?(?:(?:\\n[ 	]*)+\\n|$)|</(?!script|pre|style|textarea)[a-z][\\w-]*\\s*>(?=[ \\t]*(?:\\n|$))[\\s\\S]*?(?:(?:\\n[ 	]*)+\\n|$))", "i").replace("comment", Xn).replace("tag", yo).replace("attribute", / +[a-zA-Z:_][\w.:-]*(?: *= *"[^"\n]*"| *= *'[^'\n]*'| *= *[^\s"'=<>`]+)?/).getRegex(), Ef = mt(Gn).replace("hr", ji).replace("heading", " {0,3}#{1,6}(?:\\s|$)").replace("|lheading", "").replace("|table", "").replace("blockquote", " {0,3}>").replace("fences", " {0,3}(?:`{3,}(?=[^`\\n]*\\n)|~{3,})[^\\n]*\\n").replace("list", " {0,3}(?:[*+-]|1[.)]) ").replace("html", "</?(?:tag)(?: +|\\n|/?>)|<(?:script|pre|style|textarea|!--)").replace("tag", yo).getRegex(), U2 = mt(/^( {0,3}> ?(paragraph|[^\n]*)(?:\n|$))+/).replace("paragraph", Ef).getRegex(), Vn = { blockquote: U2, code: R2, def: z2, fences: P2, heading: N2, hr: ji, html: Y2, lheading: Mf, list: H2, newline: D2, paragraph: Ef, table: vi, text: W2 }, Lh = mt("^ *([^\\n ].*)\\n {0,3}((?:\\| *)?:?-+:? *(?:\\| *:?-+:? *)*(?:\\| *)?)(?:\\n((?:(?! *\\n|hr|heading|blockquote|code|fences|list|html).*(?:\\n|$))*)\\n*|$)").replace("hr", ji).replace("heading", " {0,3}#{1,6}(?:\\s|$)").replace("blockquote", " {0,3}>").replace("code", "(?: {4}| {0,3}	)[^\\n]").replace("fences", " {0,3}(?:`{3,}(?=[^`\\n]*\\n)|~{3,})[^\\n]*\\n").replace("list", " {0,3}(?:[*+-]|1[.)]) ").replace("html", "</?(?:tag)(?: +|\\n|/?>)|<(?:script|pre|style|textarea|!--)").replace("tag", yo).getRegex(), G2 = { ...Vn, lheading: q2, table: Lh, paragraph: mt(Gn).replace("hr", ji).replace("heading", " {0,3}#{1,6}(?:\\s|$)").replace("|lheading", "").replace("table", Lh).replace("blockquote", " {0,3}>").replace("fences", " {0,3}(?:`{3,}(?=[^`\\n]*\\n)|~{3,})[^\\n]*\\n").replace("list", " {0,3}(?:[*+-]|1[.)]) ").replace("html", "</?(?:tag)(?: +|\\n|/?>)|<(?:script|pre|style|textarea|!--)").replace("tag", yo).getRegex() }, j2 = { ...Vn, html: mt(`^ *(?:comment *(?:\\n|\\s*$)|<(tag)[\\s\\S]+?</\\1> *(?:\\n{2,}|\\s*$)|<tag(?:"[^"]*"|'[^']*'|\\s[^'"/>\\s]*)*?/?> *(?:\\n{2,}|\\s*$))`).replace("comment", Xn).replace(/tag/g, "(?!(?:a|em|strong|small|s|cite|q|dfn|abbr|data|time|code|var|samp|kbd|sub|sup|i|b|u|mark|ruby|rt|rp|bdi|bdo|span|br|wbr|ins|del|img)\\b)\\w+(?!:|[^\\w\\s@]*@)\\b").getRegex(), def: /^ *\[([^\]]+)\]: *<?([^\s>]+)>?(?: +(["(][^\n]+[")]))? *(?:\n+|$)/, heading: /^(#{1,6})(.*)(?:\n+|$)/, fences: vi, lheading: /^(.+?)\n {0,3}(=+|-+) *(?:\n+|$)/, paragraph: mt(Gn).replace("hr", ji).replace("heading", ` *#{1,6} *[^
]`).replace("lheading", Mf).replace("|table", "").replace("blockquote", " {0,3}>").replace("|fences", "").replace("|list", "").replace("|html", "").replace("|tag", "").getRegex() }, X2 = /^\\([!"#$%&'()*+,\-./:;<=>?@\[\]\\^_`{|}~])/, V2 = /^(`+)([^`]|[^`][\s\S]*?[^`])\1(?!`)/, $f = /^( {2,}|\\)\n(?!\s*$)/, Z2 = /^(`+|[^`])(?:(?= {2,}\n)|[\s\S]*?(?:(?=[\\<!\[`*_]|\b_|$)|[^ ](?= {2,}\n)))/, Co = /[\p{P}\p{S}]/u, Zn = /[\s\p{P}\p{S}]/u, Of = /[^\s\p{P}\p{S}]/u, K2 = mt(/^((?![*_])punctSpace)/, "u").replace(/punctSpace/g, Zn).getRegex(), If = /(?!~)[\p{P}\p{S}]/u, Q2 = /(?!~)[\s\p{P}\p{S}]/u, J2 = /(?:[^\s\p{P}\p{S}]|~)/u, tw = mt(/link|precode-code|html/, "g").replace("link", /\[(?:[^\[\]`]|(?<a>`+)[^`]+\k<a>(?!`))*?\]\((?:\\[\s\S]|[^\\\(\)]|\((?:\\[\s\S]|[^\\\(\)])*\))*\)/).replace("precode-", I2 ? "(?<!`)()" : "(^^|[^`])").replace("code", /(?<b>`+)[^`]+\k<b>(?!`)/).replace("html", /<(?! )[^<>]*?>/).getRegex(), Df = /^(?:\*+(?:((?!\*)punct)|[^\s*]))|^_+(?:((?!_)punct)|([^\s_]))/, ew = mt(Df, "u").replace(/punct/g, Co).getRegex(), rw = mt(Df, "u").replace(/punct/g, If).getRegex(), Rf = "^[^_*]*?__[^_*]*?\\*[^_*]*?(?=__)|[^*]+(?=[^*])|(?!\\*)punct(\\*+)(?=[\\s]|$)|notPunctSpace(\\*+)(?!\\*)(?=punctSpace|$)|(?!\\*)punctSpace(\\*+)(?=notPunctSpace)|[\\s](\\*+)(?!\\*)(?=punct)|(?!\\*)punct(\\*+)(?!\\*)(?=punct)|notPunctSpace(\\*+)(?=notPunctSpace)", iw = mt(Rf, "gu").replace(/notPunctSpace/g, Of).replace(/punctSpace/g, Zn).replace(/punct/g, Co).getRegex(), sw = mt(Rf, "gu").replace(/notPunctSpace/g, J2).replace(/punctSpace/g, Q2).replace(/punct/g, If).getRegex(), ow = mt("^[^_*]*?\\*\\*[^_*]*?_[^_*]*?(?=\\*\\*)|[^_]+(?=[^_])|(?!_)punct(_+)(?=[\\s]|$)|notPunctSpace(_+)(?!_)(?=punctSpace|$)|(?!_)punctSpace(_+)(?=notPunctSpace)|[\\s](_+)(?!_)(?=punct)|(?!_)punct(_+)(?!_)(?=punct)", "gu").replace(/notPunctSpace/g, Of).replace(/punctSpace/g, Zn).replace(/punct/g, Co).getRegex(), aw = mt(/\\(punct)/, "gu").replace(/punct/g, Co).getRegex(), nw = mt(/^<(scheme:[^\s\x00-\x1f<>]*|email)>/).replace("scheme", /[a-zA-Z][a-zA-Z0-9+.-]{1,31}/).replace("email", /[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+(@)[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+(?![-_])/).getRegex(), lw = mt(Xn).replace("(?:-->|$)", "-->").getRegex(), hw = mt("^comment|^</[a-zA-Z][\\w:-]*\\s*>|^<[a-zA-Z][\\w-]*(?:attribute)*?\\s*/?>|^<\\?[\\s\\S]*?\\?>|^<![a-zA-Z]+\\s[\\s\\S]*?>|^<!\\[CDATA\\[[\\s\\S]*?\\]\\]>").replace("comment", lw).replace("attribute", /\s+[a-zA-Z:_][\w.:-]*(?:\s*=\s*"[^"]*"|\s*=\s*'[^']*'|\s*=\s*[^\s"'=<>`]+)?/).getRegex(), Zs = /(?:\[(?:\\[\s\S]|[^\[\]\\])*\]|\\[\s\S]|`+[^`]*?`+(?!`)|[^\[\]\\`])*?/, cw = mt(/^!?\[(label)\]\(\s*(href)(?:(?:[ \t]*(?:\n[ \t]*)?)(title))?\s*\)/).replace("label", Zs).replace("href", /<(?:\\.|[^\n<>\\])+>|[^ \t\n\x00-\x1f]*/).replace("title", /"(?:\\"?|[^"\\])*"|'(?:\\'?|[^'\\])*'|\((?:\\\)?|[^)\\])*\)/).getRegex(), Pf = mt(/^!?\[(label)\]\[(ref)\]/).replace("label", Zs).replace("ref", jn).getRegex(), Nf = mt(/^!?\[(ref)\](?:\[\])?/).replace("ref", jn).getRegex(), dw = mt("reflink|nolink(?!\\()", "g").replace("reflink", Pf).replace("nolink", Nf).getRegex(), Fh = /[hH][tT][tT][pP][sS]?|[fF][tT][pP]/, Kn = { _backpedal: vi, anyPunctuation: aw, autolink: nw, blockSkip: tw, br: $f, code: V2, del: vi, emStrongLDelim: ew, emStrongRDelimAst: iw, emStrongRDelimUnd: ow, escape: X2, link: cw, nolink: Nf, punctuation: K2, reflink: Pf, reflinkSearch: dw, tag: hw, text: Z2, url: vi }, uw = { ...Kn, link: mt(/^!?\[(label)\]\((.*?)\)/).replace("label", Zs).getRegex(), reflink: mt(/^!?\[(label)\]\s*\[([^\]]*)\]/).replace("label", Zs).getRegex() }, qa = { ...Kn, emStrongRDelimAst: sw, emStrongLDelim: rw, url: mt(/^((?:protocol):\/\/|www\.)(?:[a-zA-Z0-9\-]+\.?)+[^\s<]*|^email/).replace("protocol", Fh).replace("email", /[A-Za-z0-9._+-]+(@)[a-zA-Z0-9-_]+(?:\.[a-zA-Z0-9-_]*[a-zA-Z0-9])+(?![-_])/).getRegex(), _backpedal: /(?:[^?!.,:;*_'"~()&]+|\([^)]*\)|&(?![a-zA-Z0-9]+;$)|[?!.,:;*_'"~)]+(?!$))+/, del: /^(~~?)(?=[^\s~])((?:\\[\s\S]|[^\\])*?(?:\\[\s\S]|[^\s~\\]))\1(?=[^~]|$)/, text: mt(/^([`~]+|[^`~])(?:(?= {2,}\n)|(?=[a-zA-Z0-9.!#$%&'*+\/=?_`{\|}~-]+@)|[\s\S]*?(?:(?=[\\<!\[`*~_]|\b_|protocol:\/\/|www\.|$)|[^ ](?= {2,}\n)|[^a-zA-Z0-9.!#$%&'*+\/=?_`{\|}~-](?=[a-zA-Z0-9.!#$%&'*+\/=?_`{\|}~-]+@)))/).replace("protocol", Fh).getRegex() }, fw = { ...qa, br: mt($f).replace("{2,}", "*").getRegex(), text: mt(qa.text).replace("\\b_", "\\b_| {2,}\\n").replace(/\{2,\}/g, "*").getRegex() }, hs = { normal: Vn, gfm: G2, pedantic: j2 }, hi = { normal: Kn, gfm: qa, breaks: fw, pedantic: uw }, pw = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }, Ah = (e) => pw[e];
function ke(e, t) {
  if (t) {
    if (jt.escapeTest.test(e)) return e.replace(jt.escapeReplace, Ah);
  } else if (jt.escapeTestNoEncode.test(e)) return e.replace(jt.escapeReplaceNoEncode, Ah);
  return e;
}
function Mh(e) {
  try {
    e = encodeURI(e).replace(jt.percentDecode, "%");
  } catch {
    return null;
  }
  return e;
}
function Eh(e, t) {
  let r = e.replace(jt.findPipe, (o, a, n) => {
    let l = !1, c = a;
    for (; --c >= 0 && n[c] === "\\"; ) l = !l;
    return l ? "|" : " |";
  }), i = r.split(jt.splitPipe), s = 0;
  if (i[0].trim() || i.shift(), i.length > 0 && !i.at(-1)?.trim() && i.pop(), t) if (i.length > t) i.splice(t);
  else for (; i.length < t; ) i.push("");
  for (; s < i.length; s++) i[s] = i[s].trim().replace(jt.slashPipe, "|");
  return i;
}
function ci(e, t, r) {
  let i = e.length;
  if (i === 0) return "";
  let s = 0;
  for (; s < i && e.charAt(i - s - 1) === t; )
    s++;
  return e.slice(0, i - s);
}
function gw(e, t) {
  if (e.indexOf(t[1]) === -1) return -1;
  let r = 0;
  for (let i = 0; i < e.length; i++) if (e[i] === "\\") i++;
  else if (e[i] === t[0]) r++;
  else if (e[i] === t[1] && (r--, r < 0)) return i;
  return r > 0 ? -2 : -1;
}
function $h(e, t, r, i, s) {
  let o = t.href, a = t.title || null, n = e[1].replace(s.other.outputLinkReplace, "$1");
  i.state.inLink = !0;
  let l = { type: e[0].charAt(0) === "!" ? "image" : "link", raw: r, href: o, title: a, text: n, tokens: i.inlineTokens(n) };
  return i.state.inLink = !1, l;
}
function mw(e, t, r) {
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
var Ks = class {
  options;
  rules;
  lexer;
  constructor(t) {
    this.options = t || Tr;
  }
  space(t) {
    let r = this.rules.block.newline.exec(t);
    if (r && r[0].length > 0) return { type: "space", raw: r[0] };
  }
  code(t) {
    let r = this.rules.block.code.exec(t);
    if (r) {
      let i = r[0].replace(this.rules.other.codeRemoveIndent, "");
      return { type: "code", raw: r[0], codeBlockStyle: "indented", text: this.options.pedantic ? i : ci(i, `
`) };
    }
  }
  fences(t) {
    let r = this.rules.block.fences.exec(t);
    if (r) {
      let i = r[0], s = mw(i, r[3] || "", this.rules);
      return { type: "code", raw: i, lang: r[2] ? r[2].trim().replace(this.rules.inline.anyPunctuation, "$1") : r[2], text: s };
    }
  }
  heading(t) {
    let r = this.rules.block.heading.exec(t);
    if (r) {
      let i = r[2].trim();
      if (this.rules.other.endingHash.test(i)) {
        let s = ci(i, "#");
        (this.options.pedantic || !s || this.rules.other.endingSpaceChar.test(s)) && (i = s.trim());
      }
      return { type: "heading", raw: r[0], depth: r[1].length, text: i, tokens: this.lexer.inline(i) };
    }
  }
  hr(t) {
    let r = this.rules.block.hr.exec(t);
    if (r) return { type: "hr", raw: ci(r[0], `
`) };
  }
  blockquote(t) {
    let r = this.rules.block.blockquote.exec(t);
    if (r) {
      let i = ci(r[0], `
`).split(`
`), s = "", o = "", a = [];
      for (; i.length > 0; ) {
        let n = !1, l = [], c;
        for (c = 0; c < i.length; c++) if (this.rules.other.blockquoteStart.test(i[c])) l.push(i[c]), n = !0;
        else if (!n) l.push(i[c]);
        else break;
        i = i.slice(c);
        let h = l.join(`
`), d = h.replace(this.rules.other.blockquoteSetextReplace, `
    $1`).replace(this.rules.other.blockquoteSetextReplace2, "");
        s = s ? `${s}
${h}` : h, o = o ? `${o}
${d}` : d;
        let f = this.lexer.state.top;
        if (this.lexer.state.top = !0, this.lexer.blockTokens(d, a, !0), this.lexer.state.top = f, i.length === 0) break;
        let u = a.at(-1);
        if (u?.type === "code") break;
        if (u?.type === "blockquote") {
          let g = u, m = g.raw + `
` + i.join(`
`), y = this.blockquote(m);
          a[a.length - 1] = y, s = s.substring(0, s.length - g.raw.length) + y.raw, o = o.substring(0, o.length - g.text.length) + y.text;
          break;
        } else if (u?.type === "list") {
          let g = u, m = g.raw + `
` + i.join(`
`), y = this.list(m);
          a[a.length - 1] = y, s = s.substring(0, s.length - u.raw.length) + y.raw, o = o.substring(0, o.length - g.raw.length) + y.raw, i = m.substring(a.at(-1).raw.length).split(`
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
        let c = !1, h = "", d = "";
        if (!(r = a.exec(t)) || this.rules.block.hr.test(t)) break;
        h = r[0], t = t.substring(h.length);
        let f = r[2].split(`
`, 1)[0].replace(this.rules.other.listReplaceTabs, (b) => " ".repeat(3 * b.length)), u = t.split(`
`, 1)[0], g = !f.trim(), m = 0;
        if (this.options.pedantic ? (m = 2, d = f.trimStart()) : g ? m = r[1].length + 1 : (m = r[2].search(this.rules.other.nonSpaceChar), m = m > 4 ? 1 : m, d = f.slice(m), m += r[1].length), g && this.rules.other.blankLine.test(u) && (h += u + `
`, t = t.substring(u.length + 1), c = !0), !c) {
          let b = this.rules.other.nextBulletRegex(m), k = this.rules.other.hrRegex(m), T = this.rules.other.fencesBeginRegex(m), S = this.rules.other.headingBeginRegex(m), _ = this.rules.other.htmlBeginRegex(m);
          for (; t; ) {
            let A = t.split(`
`, 1)[0], v;
            if (u = A, this.options.pedantic ? (u = u.replace(this.rules.other.listReplaceNesting, "  "), v = u) : v = u.replace(this.rules.other.tabCharGlobal, "    "), T.test(u) || S.test(u) || _.test(u) || b.test(u) || k.test(u)) break;
            if (v.search(this.rules.other.nonSpaceChar) >= m || !u.trim()) d += `
` + v.slice(m);
            else {
              if (g || f.replace(this.rules.other.tabCharGlobal, "    ").search(this.rules.other.nonSpaceChar) >= 4 || T.test(f) || S.test(f) || k.test(f)) break;
              d += `
` + u;
            }
            !g && !u.trim() && (g = !0), h += A + `
`, t = t.substring(A.length + 1), f = v.slice(m);
          }
        }
        o.loose || (n ? o.loose = !0 : this.rules.other.doubleBlankLine.test(h) && (n = !0));
        let y = null, C;
        this.options.gfm && (y = this.rules.other.listIsTask.exec(d), y && (C = y[0] !== "[ ] ", d = d.replace(this.rules.other.listReplaceTask, ""))), o.items.push({ type: "list_item", raw: h, task: !!y, checked: C, loose: !1, text: d, tokens: [] }), o.raw += h;
      }
      let l = o.items.at(-1);
      if (l) l.raw = l.raw.trimEnd(), l.text = l.text.trimEnd();
      else return;
      o.raw = o.raw.trimEnd();
      for (let c = 0; c < o.items.length; c++) if (this.lexer.state.top = !1, o.items[c].tokens = this.lexer.blockTokens(o.items[c].text, []), !o.loose) {
        let h = o.items[c].tokens.filter((f) => f.type === "space"), d = h.length > 0 && h.some((f) => this.rules.other.anyLine.test(f.raw));
        o.loose = d;
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
    let i = Eh(r[1]), s = r[2].replace(this.rules.other.tableAlignChars, "").split("|"), o = r[3]?.trim() ? r[3].replace(this.rules.other.tableRowBlankLine, "").split(`
`) : [], a = { type: "table", raw: r[0], header: [], align: [], rows: [] };
    if (i.length === s.length) {
      for (let n of s) this.rules.other.tableAlignRight.test(n) ? a.align.push("right") : this.rules.other.tableAlignCenter.test(n) ? a.align.push("center") : this.rules.other.tableAlignLeft.test(n) ? a.align.push("left") : a.align.push(null);
      for (let n = 0; n < i.length; n++) a.header.push({ text: i[n], tokens: this.lexer.inline(i[n]), header: !0, align: a.align[n] });
      for (let n of o) a.rows.push(Eh(n, a.header.length).map((l, c) => ({ text: l, tokens: this.lexer.inline(l), header: !1, align: a.align[c] })));
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
        let a = ci(i.slice(0, -1), "\\");
        if ((i.length - a.length) % 2 === 0) return;
      } else {
        let a = gw(r[2], "()");
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
      return s = s.trim(), this.rules.other.startAngleBracket.test(s) && (this.options.pedantic && !this.rules.other.endAngleBracket.test(i) ? s = s.slice(1) : s = s.slice(1, -1)), $h(r, { href: s && s.replace(this.rules.inline.anyPunctuation, "$1"), title: o && o.replace(this.rules.inline.anyPunctuation, "$1") }, r[0], this.lexer, this.rules);
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
      return $h(i, o, i[0], this.lexer, this.rules);
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
        let d = [...s[0]][0].length, f = t.slice(0, o + s.index + d + n);
        if (Math.min(o, n) % 2) {
          let g = f.slice(1, -1);
          return { type: "em", raw: f, text: g, tokens: this.lexer.inlineTokens(g) };
        }
        let u = f.slice(2, -2);
        return { type: "strong", raw: f, text: u, tokens: this.lexer.inlineTokens(u) };
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
}, ce = class Wa {
  tokens;
  options;
  state;
  tokenizer;
  inlineQueue;
  constructor(t) {
    this.tokens = [], this.tokens.links = /* @__PURE__ */ Object.create(null), this.options = t || Tr, this.options.tokenizer = this.options.tokenizer || new Ks(), this.tokenizer = this.options.tokenizer, this.tokenizer.options = this.options, this.tokenizer.lexer = this, this.inlineQueue = [], this.state = { inLink: !1, inRawBlock: !1, top: !0 };
    let r = { other: jt, block: hs.normal, inline: hi.normal };
    this.options.pedantic ? (r.block = hs.pedantic, r.inline = hi.pedantic) : this.options.gfm && (r.block = hs.gfm, this.options.breaks ? r.inline = hi.breaks : r.inline = hi.gfm), this.tokenizer.rules = r;
  }
  static get rules() {
    return { block: hs, inline: hi };
  }
  static lex(t, r) {
    return new Wa(r).lex(t);
  }
  static lexInline(t, r) {
    return new Wa(r).inlineTokens(t);
  }
  lex(t) {
    t = t.replace(jt.carriageReturn, `
`), this.blockTokens(t, this.tokens);
    for (let r = 0; r < this.inlineQueue.length; r++) {
      let i = this.inlineQueue[r];
      this.inlineTokens(i.src, i.tokens);
    }
    return this.inlineQueue = [], this.tokens;
  }
  blockTokens(t, r = [], i = !1) {
    for (this.options.pedantic && (t = t.replace(jt.tabCharGlobal, "    ").replace(jt.spaceLine, "")); t; ) {
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
        let h = 1 / 0, d = t.slice(1), f;
        this.options.extensions.startInline.forEach((u) => {
          f = u.call({ lexer: this }, d), typeof f == "number" && f >= 0 && (h = Math.min(h, f));
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
}, Qs = class {
  options;
  parser;
  constructor(t) {
    this.options = t || Tr;
  }
  space(t) {
    return "";
  }
  code({ text: t, lang: r, escaped: i }) {
    let s = (r || "").match(jt.notSpaceStart)?.[0], o = t.replace(jt.endingNewline, "") + `
`;
    return s ? '<pre><code class="language-' + ke(s) + '">' + (i ? o : ke(o, !0)) + `</code></pre>
` : "<pre><code>" + (i ? o : ke(o, !0)) + `</code></pre>
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
      t.loose ? t.tokens[0]?.type === "paragraph" ? (t.tokens[0].text = i + " " + t.tokens[0].text, t.tokens[0].tokens && t.tokens[0].tokens.length > 0 && t.tokens[0].tokens[0].type === "text" && (t.tokens[0].tokens[0].text = i + " " + ke(t.tokens[0].tokens[0].text), t.tokens[0].tokens[0].escaped = !0)) : t.tokens.unshift({ type: "text", raw: i + " ", text: i + " ", escaped: !0 }) : r += i + " ";
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
    return `<code>${ke(t, !0)}</code>`;
  }
  br(t) {
    return "<br>";
  }
  del({ tokens: t }) {
    return `<del>${this.parser.parseInline(t)}</del>`;
  }
  link({ href: t, title: r, tokens: i }) {
    let s = this.parser.parseInline(i), o = Mh(t);
    if (o === null) return s;
    t = o;
    let a = '<a href="' + t + '"';
    return r && (a += ' title="' + ke(r) + '"'), a += ">" + s + "</a>", a;
  }
  image({ href: t, title: r, text: i, tokens: s }) {
    s && (i = this.parser.parseInline(s, this.parser.textRenderer));
    let o = Mh(t);
    if (o === null) return ke(i);
    t = o;
    let a = `<img src="${t}" alt="${i}"`;
    return r && (a += ` title="${ke(r)}"`), a += ">", a;
  }
  text(t) {
    return "tokens" in t && t.tokens ? this.parser.parseInline(t.tokens) : "escaped" in t && t.escaped ? t.text : ke(t.text);
  }
}, Qn = class {
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
}, de = class za {
  options;
  renderer;
  textRenderer;
  constructor(t) {
    this.options = t || Tr, this.options.renderer = this.options.renderer || new Qs(), this.renderer = this.options.renderer, this.renderer.options = this.options, this.renderer.parser = this, this.textRenderer = new Qn();
  }
  static parse(t, r) {
    return new za(r).parse(t);
  }
  static parseInline(t, r) {
    return new za(r).parseInline(t);
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
}, bi = class {
  options;
  block;
  constructor(t) {
    this.options = t || Tr;
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
    return this.block ? ce.lex : ce.lexInline;
  }
  provideParser() {
    return this.block ? de.parse : de.parseInline;
  }
}, yw = class {
  defaults = Yn();
  options = this.setOptions;
  parse = this.parseMarkdown(!0);
  parseInline = this.parseMarkdown(!1);
  Parser = de;
  Renderer = Qs;
  TextRenderer = Qn;
  Lexer = ce;
  Tokenizer = Ks;
  Hooks = bi;
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
        let o = this.defaults.renderer || new Qs(this.defaults);
        for (let a in i.renderer) {
          if (!(a in o)) throw new Error(`renderer '${a}' does not exist`);
          if (["options", "parser"].includes(a)) continue;
          let n = a, l = i.renderer[n], c = o[n];
          o[n] = (...h) => {
            let d = l.apply(o, h);
            return d === !1 && (d = c.apply(o, h)), d || "";
          };
        }
        s.renderer = o;
      }
      if (i.tokenizer) {
        let o = this.defaults.tokenizer || new Ks(this.defaults);
        for (let a in i.tokenizer) {
          if (!(a in o)) throw new Error(`tokenizer '${a}' does not exist`);
          if (["options", "rules", "lexer"].includes(a)) continue;
          let n = a, l = i.tokenizer[n], c = o[n];
          o[n] = (...h) => {
            let d = l.apply(o, h);
            return d === !1 && (d = c.apply(o, h)), d;
          };
        }
        s.tokenizer = o;
      }
      if (i.hooks) {
        let o = this.defaults.hooks || new bi();
        for (let a in i.hooks) {
          if (!(a in o)) throw new Error(`hook '${a}' does not exist`);
          if (["options", "block"].includes(a)) continue;
          let n = a, l = i.hooks[n], c = o[n];
          bi.passThroughHooks.has(a) ? o[n] = (h) => {
            if (this.defaults.async && bi.passThroughHooksRespectAsync.has(a)) return (async () => {
              let f = await l.call(o, h);
              return c.call(o, f);
            })();
            let d = l.call(o, h);
            return c.call(o, d);
          } : o[n] = (...h) => {
            if (this.defaults.async) return (async () => {
              let f = await l.apply(o, h);
              return f === !1 && (f = await c.apply(o, h)), f;
            })();
            let d = l.apply(o, h);
            return d === !1 && (d = c.apply(o, h)), d;
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
    return ce.lex(t, r ?? this.defaults);
  }
  parser(t, r) {
    return de.parse(t, r ?? this.defaults);
  }
  parseMarkdown(t) {
    return (r, i) => {
      let s = { ...i }, o = { ...this.defaults, ...s }, a = this.onError(!!o.silent, !!o.async);
      if (this.defaults.async === !0 && s.async === !1) return a(new Error("marked(): The async option was set to true by an extension. Remove async: false from the parse options object to return a Promise."));
      if (typeof r > "u" || r === null) return a(new Error("marked(): input parameter is undefined or null"));
      if (typeof r != "string") return a(new Error("marked(): input parameter is of type " + Object.prototype.toString.call(r) + ", string expected"));
      if (o.hooks && (o.hooks.options = o, o.hooks.block = t), o.async) return (async () => {
        let n = o.hooks ? await o.hooks.preprocess(r) : r, l = await (o.hooks ? await o.hooks.provideLexer() : t ? ce.lex : ce.lexInline)(n, o), c = o.hooks ? await o.hooks.processAllTokens(l) : l;
        o.walkTokens && await Promise.all(this.walkTokens(c, o.walkTokens));
        let h = await (o.hooks ? await o.hooks.provideParser() : t ? de.parse : de.parseInline)(c, o);
        return o.hooks ? await o.hooks.postprocess(h) : h;
      })().catch(a);
      try {
        o.hooks && (r = o.hooks.preprocess(r));
        let n = (o.hooks ? o.hooks.provideLexer() : t ? ce.lex : ce.lexInline)(r, o);
        o.hooks && (n = o.hooks.processAllTokens(n)), o.walkTokens && this.walkTokens(n, o.walkTokens);
        let l = (o.hooks ? o.hooks.provideParser() : t ? de.parse : de.parseInline)(n, o);
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
        let s = "<p>An error occurred:</p><pre>" + ke(i.message + "", !0) + "</pre>";
        return r ? Promise.resolve(s) : s;
      }
      if (r) return Promise.reject(i);
      throw i;
    };
  }
}, kr = new yw();
function Ct(e, t) {
  return kr.parse(e, t);
}
Ct.options = Ct.setOptions = function(e) {
  return kr.setOptions(e), Ct.defaults = kr.defaults, Ff(Ct.defaults), Ct;
};
Ct.getDefaults = Yn;
Ct.defaults = Tr;
Ct.use = function(...e) {
  return kr.use(...e), Ct.defaults = kr.defaults, Ff(Ct.defaults), Ct;
};
Ct.walkTokens = function(e, t) {
  return kr.walkTokens(e, t);
};
Ct.parseInline = kr.parseInline;
Ct.Parser = de;
Ct.parser = de.parse;
Ct.Renderer = Qs;
Ct.TextRenderer = Qn;
Ct.Lexer = ce;
Ct.lexer = ce.lex;
Ct.Tokenizer = Ks;
Ct.Hooks = bi;
Ct.parse = Ct;
Ct.options;
Ct.setOptions;
Ct.use;
Ct.walkTokens;
Ct.parseInline;
de.parse;
ce.lex;
function qf(e) {
  for (var t = [], r = 1; r < arguments.length; r++)
    t[r - 1] = arguments[r];
  var i = Array.from(typeof e == "string" ? [e] : e);
  i[i.length - 1] = i[i.length - 1].replace(/\r?\n([\t ]*)$/, "");
  var s = i.reduce(function(n, l) {
    var c = l.match(/\n([\t ]+|(?!\s).)/g);
    return c ? n.concat(c.map(function(h) {
      var d, f;
      return (f = (d = h.match(/[\t ]/g)) === null || d === void 0 ? void 0 : d.length) !== null && f !== void 0 ? f : 0;
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
    var c = a.match(/(?:^|\n)( *)$/), h = c ? c[1] : "", d = n;
    typeof n == "string" && n.includes(`
`) && (d = String(n).split(`
`).map(function(f, u) {
      return u === 0 ? f : "" + h + f;
    }).join(`
`)), a += d + i[l + 1];
  }), a;
}
var Cw = {
  body: '<g><rect width="80" height="80" style="fill: #087ebf; stroke-width: 0px;"/><text transform="translate(21.16 64.67)" style="fill: #fff; font-family: ArialMT, Arial; font-size: 67.75px;"><tspan x="0" y="0">?</tspan></text></g>',
  height: 80,
  width: 80
}, Ha = /* @__PURE__ */ new Map(), Wf = /* @__PURE__ */ new Map(), xw = /* @__PURE__ */ p((e) => {
  for (const t of e) {
    if (!t.name)
      throw new Error(
        'Invalid icon loader. Must have a "name" property with non-empty string value.'
      );
    if (P.debug("Registering icon pack:", t.name), "loader" in t)
      Wf.set(t.name, t.loader);
    else if ("icons" in t)
      Ha.set(t.name, t.icons);
    else
      throw P.error("Invalid icon loader:", t), new Error('Invalid icon loader. Must have either "icons" or "loader" property.');
  }
}, "registerIconPacks"), zf = /* @__PURE__ */ p(async (e, t) => {
  const r = b2(e, !0, t !== void 0);
  if (!r)
    throw new Error(`Invalid icon name: ${e}`);
  const i = r.prefix || t;
  if (!i)
    throw new Error(`Icon name must contain a prefix: ${e}`);
  let s = Ha.get(i);
  if (!s) {
    const a = Wf.get(i);
    if (!a)
      throw new Error(`Icon set not found: ${r.prefix}`);
    try {
      s = { ...await a(), prefix: i }, Ha.set(i, s);
    } catch (n) {
      throw P.error(n), new Error(`Failed to load icon set: ${r.prefix}`);
    }
  }
  const o = T2(s, r.name);
  if (!o)
    throw new Error(`Icon not found: ${e}`);
  return o;
}, "getRegisteredIconData"), bw = /* @__PURE__ */ p(async (e) => {
  try {
    return await zf(e), !0;
  } catch {
    return !1;
  }
}, "isIconAvailable"), Xi = /* @__PURE__ */ p(async (e, t, r) => {
  let i;
  try {
    i = await zf(e, t?.fallbackPrefix);
  } catch (a) {
    P.error(a), i = Cw;
  }
  const s = A2(i, t), o = O2($2(s.body), {
    ...s.attributes,
    ...r
  });
  return me(o, Tt());
}, "getIconSVG");
function Hf(e, { markdownAutoWrap: t }) {
  const i = e.replace(/<br\/>/g, `
`).replace(/\n{2,}/g, `
`);
  return qf(i);
}
p(Hf, "preprocessMarkdown");
function Yf(e) {
  return e.split(/\\n|\n|<br\s*\/?>/gi).map(
    (t) => t.trim().match(/<[^>]+>|[^\s<>]+/g)?.map((r) => ({ content: r, type: "normal" })) ?? []
  );
}
p(Yf, "nonMarkdownToLines");
function Uf(e, t = {}) {
  const r = Hf(e, t), i = Ct.lexer(r), s = [[]];
  let o = 0;
  function a(n, l = "normal") {
    n.type === "text" ? n.text.split(`
`).forEach((h, d) => {
      d !== 0 && (o++, s.push([])), h.split(" ").forEach((f) => {
        f = f.replace(/&#39;/g, "'"), f && s[o].push({ content: f, type: l });
      });
    }) : n.type === "strong" || n.type === "em" ? n.tokens.forEach((c) => {
      a(c, n.type);
    }) : n.type === "html" && s[o].push({ content: n.text, type: "normal" });
  }
  return p(a, "processNode"), i.forEach((n) => {
    n.type === "paragraph" ? n.tokens?.forEach((l) => {
      a(l);
    }) : n.type === "html" ? s[o].push({ content: n.text, type: "normal" }) : s[o].push({ content: n.raw, type: "normal" });
  }), s;
}
p(Uf, "markdownToLines");
function Gf(e) {
  return e ? `<p>${/**
  * Replace new lines with <br /> tags.
  *
  * Unlike in markdown text, `\n` sequences are treated as line breaks here.
  */
  e.replace(/\\n|\n/g, "<br />")}</p>` : "";
}
p(Gf, "nonMarkdownToHTML");
function jf(e, { markdownAutoWrap: t } = {}) {
  const r = Ct.lexer(e);
  function i(s) {
    return s.type === "text" ? t === !1 ? s.text.replace(/\n */g, "<br/>").replace(/ /g, "&nbsp;") : s.text.replace(/\n */g, "<br/>") : s.type === "strong" ? `<strong>${s.tokens?.map(i).join("")}</strong>` : s.type === "em" ? `<em>${s.tokens?.map(i).join("")}</em>` : s.type === "paragraph" ? `<p>${s.tokens?.map(i).join("")}</p>` : s.type === "space" ? "" : s.type === "html" ? `${s.text}` : s.type === "escape" ? s.text : (P.warn(`Unsupported markdown: ${s.type}`), s.raw);
  }
  return p(i, "output"), r.map(i).join("");
}
p(jf, "markdownToHTML");
function Xf(e) {
  return Intl.Segmenter ? [...new Intl.Segmenter().segment(e)].map((t) => t.segment) : [...e];
}
p(Xf, "splitTextToChars");
function Vf(e, t) {
  const r = Xf(t.content);
  return Jn(e, [], r, t.type);
}
p(Vf, "splitWordToFitWidth");
function Jn(e, t, r, i) {
  if (r.length === 0)
    return [
      { content: t.join(""), type: i },
      { content: "", type: i }
    ];
  const [s, ...o] = r, a = [...t, s];
  return e([{ content: a.join(""), type: i }]) ? Jn(e, a, o, i) : (t.length === 0 && s && (t.push(s), r.shift()), [
    { content: t.join(""), type: i },
    { content: r.join(""), type: i }
  ]);
}
p(Jn, "splitWordToFitWidthRecursion");
function Zf(e, t) {
  if (e.some(({ content: r }) => r.includes(`
`)))
    throw new Error("splitLineToFitWidth does not support newlines in the line");
  return Js(e, t);
}
p(Zf, "splitLineToFitWidth");
function Js(e, t, r = [], i = []) {
  if (e.length === 0)
    return i.length > 0 && r.push(i), r.length > 0 ? r : [];
  let s = "";
  e[0].content === " " && (s = " ", e.shift());
  const o = e.shift() ?? { content: " ", type: "normal" }, a = [...i];
  if (s !== "" && a.push({ content: s, type: "normal" }), a.push(o), t(a))
    return Js(e, t, r, a);
  if (i.length > 0)
    r.push(i), e.unshift(o);
  else if (o.content) {
    const [n, l] = Vf(t, o);
    r.push([n]), l.content && e.unshift(l);
  }
  return Js(e, t, r);
}
p(Js, "splitLineToFitWidthRecursion");
function Ya(e, t) {
  t && e.attr("style", t);
}
p(Ya, "applyStyle");
var Oh = 16384;
async function Kf(e, t, r, i, s = !1, o = Tt()) {
  const a = e.append("foreignObject");
  a.attr("width", `${Math.min(10 * r, Oh)}px`), a.attr("height", `${Math.min(10 * r, Oh)}px`);
  const n = a.append("xhtml:div"), l = Fi(t.label) ? await Ac(t.label.replace(zi.lineBreakRegex, `
`), o) : me(t.label, o), c = t.isNode ? "nodeLabel" : "edgeLabel", h = n.append("span");
  h.html(l), Ya(h, t.labelStyle), h.attr("class", `${c} ${i}`), Ya(n, t.labelStyle), n.style("display", "table-cell"), n.style("white-space", "nowrap"), n.style("line-height", "1.5"), r !== Number.POSITIVE_INFINITY && (n.style("max-width", r + "px"), n.style("text-align", "center")), n.attr("xmlns", "http://www.w3.org/1999/xhtml"), s && n.attr("class", "labelBkg");
  let d = n.node().getBoundingClientRect();
  return d.width === r && (n.style("display", "table"), n.style("white-space", "break-spaces"), n.style("width", r + "px"), d = n.node().getBoundingClientRect()), a.node();
}
p(Kf, "addHtmlSpan");
function xo(e, t, r, i = !1) {
  const s = e.append("tspan").attr("class", "text-outer-tspan").attr("x", 0).attr("y", t * r - 0.1 + "em").attr("dy", r + "em");
  return i && s.attr("text-anchor", "middle"), s;
}
p(xo, "createTspan");
function Qf(e, t, r) {
  const i = e.append("text"), s = xo(i, 1, t);
  bo(s, r);
  const o = s.node().getComputedTextLength();
  return i.remove(), o;
}
p(Qf, "computeWidthOfText");
function kw(e, t, r) {
  const i = e.append("text"), s = xo(i, 1, t);
  bo(s, [{ content: r, type: "normal" }]);
  const o = s.node()?.getBoundingClientRect();
  return o && i.remove(), o;
}
p(kw, "computeDimensionOfText");
function Jf(e, t, r, i = !1, s = !1) {
  const a = t.append("g"), n = a.insert("rect").attr("class", "background").attr("style", "stroke: none"), l = a.append("text").attr("y", "-10.1");
  s && l.attr("text-anchor", "middle");
  let c = 0;
  for (const h of r) {
    const d = /* @__PURE__ */ p((u) => Qf(a, 1.1, u) <= e, "checkWidth"), f = d(h) ? [h] : Zf(h, d);
    for (const u of f) {
      const g = xo(l, c, 1.1, s);
      bo(g, u), c++;
    }
  }
  if (i) {
    const h = l.node().getBBox(), d = 2;
    return n.attr("x", h.x - d).attr("y", h.y - d).attr("width", h.width + 2 * d).attr("height", h.height + 2 * d), a.node();
  } else
    return l.node();
}
p(Jf, "createFormattedText");
function Ua(e) {
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
p(Ua, "decodeHTMLEntities");
function bo(e, t) {
  e.text(""), t.forEach((r, i) => {
    const s = e.append("tspan").attr("font-style", r.type === "em" ? "italic" : "normal").attr("class", "text-inner-tspan").attr("font-weight", r.type === "strong" ? "bold" : "normal");
    i === 0 ? s.text(Ua(r.content)) : s.text(" " + Ua(r.content));
  });
}
p(bo, "updateTextContentAndStyles");
async function tp(e, t = {}) {
  const r = [];
  e.replace(/(fa[bklrs]?):fa-([\w-]+)/g, (s, o, a) => (r.push(
    (async () => {
      const n = `${o}:${a}`;
      return await bw(n) ? await Xi(n, void 0, { class: "label-icon" }) : `<i class='${me(s, t).replace(":", " ")}'></i>`;
    })()
  ), s));
  const i = await Promise.all(r);
  return e.replace(/(fa[bklrs]?):fa-([\w-]+)/g, () => i.shift() ?? "");
}
p(tp, "replaceIconSubstring");
var He = /* @__PURE__ */ p(async (e, t = "", {
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
  if (P.debug(
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
    const d = a ? jf(t, h) : Gf(t), f = await tp(br(d), h), u = t.replace(/\\\\/g, "\\"), g = {
      isNode: n,
      label: Fi(t) ? u : f,
      labelStyle: r.replace("fill:", "color:")
    };
    return await Kf(e, g, l, s, c, h);
  } else {
    const d = br(t.replace(/<br\s*\/?>/g, "<br/>")), f = a ? Uf(d.replace("<br>", "<br/>"), h) : Yf(d), u = Jf(
      l,
      e,
      f,
      t ? c : !1,
      !n
    );
    if (n) {
      /stroke:/.exec(r) && (r = r.replace("stroke:", "lineColor:"));
      const g = r.replace(/stroke:[^;]+;?/g, "").replace(/stroke-width:[^;]+;?/g, "").replace(/fill:[^;]+;?/g, "").replace(/color:/g, "fill:");
      ht(u).attr("style", g);
    } else {
      const g = r.replace(/stroke:[^;]+;?/g, "").replace(/stroke-width:[^;]+;?/g, "").replace(/fill:[^;]+;?/g, "").replace(/background:/g, "fill:");
      ht(u).select("rect").attr("style", g.replace(/background:/g, "fill:"));
      const m = r.replace(/stroke:[^;]+;?/g, "").replace(/stroke-width:[^;]+;?/g, "").replace(/fill:[^;]+;?/g, "").replace(/color:/g, "fill:");
      ht(u).select("text").attr("style", m);
    }
    return i ? ht(u).selectAll("tspan.text-outer-tspan").classed("title-row", !0) : ht(u).selectAll("tspan.text-outer-tspan").classed("row", !0), u;
  }
}, "createText");
function Zo(e, t, r) {
  if (e && e.length) {
    const [i, s] = t, o = Math.PI / 180 * r, a = Math.cos(o), n = Math.sin(o);
    for (const l of e) {
      const [c, h] = l;
      l[0] = (c - i) * a - (h - s) * n + i, l[1] = (c - i) * n + (h - s) * a + s;
    }
  }
}
function ww(e, t) {
  return e[0] === t[0] && e[1] === t[1];
}
function Tw(e, t, r, i = 1) {
  const s = r, o = Math.max(t, 0.1), a = e[0] && e[0][0] && typeof e[0][0] == "number" ? [e] : e, n = [0, 0];
  if (s) for (const c of a) Zo(c, n, s);
  const l = (function(c, h, d) {
    const f = [];
    for (const b of c) {
      const k = [...b];
      ww(k[0], k[k.length - 1]) || k.push([k[0][0], k[0][1]]), k.length > 2 && f.push(k);
    }
    const u = [];
    h = Math.max(h, 0.1);
    const g = [];
    for (const b of f) for (let k = 0; k < b.length - 1; k++) {
      const T = b[k], S = b[k + 1];
      if (T[1] !== S[1]) {
        const _ = Math.min(T[1], S[1]);
        g.push({ ymin: _, ymax: Math.max(T[1], S[1]), x: _ === T[1] ? T[0] : S[0], islope: (S[0] - T[0]) / (S[1] - T[1]) });
      }
    }
    if (g.sort(((b, k) => b.ymin < k.ymin ? -1 : b.ymin > k.ymin ? 1 : b.x < k.x ? -1 : b.x > k.x ? 1 : b.ymax === k.ymax ? 0 : (b.ymax - k.ymax) / Math.abs(b.ymax - k.ymax))), !g.length) return u;
    let m = [], y = g[0].ymin, C = 0;
    for (; m.length || g.length; ) {
      if (g.length) {
        let b = -1;
        for (let k = 0; k < g.length && !(g[k].ymin > y); k++) b = k;
        g.splice(0, b + 1).forEach(((k) => {
          m.push({ s: y, edge: k });
        }));
      }
      if (m = m.filter(((b) => !(b.edge.ymax <= y))), m.sort(((b, k) => b.edge.x === k.edge.x ? 0 : (b.edge.x - k.edge.x) / Math.abs(b.edge.x - k.edge.x))), (d !== 1 || C % h == 0) && m.length > 1) for (let b = 0; b < m.length; b += 2) {
        const k = b + 1;
        if (k >= m.length) break;
        const T = m[b].edge, S = m[k].edge;
        u.push([[Math.round(T.x), y], [Math.round(S.x), y]]);
      }
      y += d, m.forEach(((b) => {
        b.edge.x = b.edge.x + d * b.edge.islope;
      })), C++;
    }
    return u;
  })(a, o, i);
  if (s) {
    for (const c of a) Zo(c, n, -s);
    (function(c, h, d) {
      const f = [];
      c.forEach(((u) => f.push(...u))), Zo(f, h, d);
    })(l, n, -s);
  }
  return l;
}
function Vi(e, t) {
  var r;
  const i = t.hachureAngle + 90;
  let s = t.hachureGap;
  s < 0 && (s = 4 * t.strokeWidth), s = Math.round(Math.max(s, 0.1));
  let o = 1;
  return t.roughness >= 1 && (((r = t.randomizer) === null || r === void 0 ? void 0 : r.next()) || Math.random()) > 0.7 && (o = s), Tw(e, s, i, o || 1);
}
class tl {
  constructor(t) {
    this.helper = t;
  }
  fillPolygons(t, r) {
    return this._fillPolygons(t, r);
  }
  _fillPolygons(t, r) {
    const i = Vi(t, r);
    return { type: "fillSketch", ops: this.renderLines(i, r) };
  }
  renderLines(t, r) {
    const i = [];
    for (const s of t) i.push(...this.helper.doubleLineOps(s[0][0], s[0][1], s[1][0], s[1][1], r));
    return i;
  }
}
function ko(e) {
  const t = e[0], r = e[1];
  return Math.sqrt(Math.pow(t[0] - r[0], 2) + Math.pow(t[1] - r[1], 2));
}
class Sw extends tl {
  fillPolygons(t, r) {
    let i = r.hachureGap;
    i < 0 && (i = 4 * r.strokeWidth), i = Math.max(i, 0.1);
    const s = Vi(t, Object.assign({}, r, { hachureGap: i })), o = Math.PI / 180 * r.hachureAngle, a = [], n = 0.5 * i * Math.cos(o), l = 0.5 * i * Math.sin(o);
    for (const [c, h] of s) ko([c, h]) && a.push([[c[0] - n, c[1] + l], [...h]], [[c[0] + n, c[1] - l], [...h]]);
    return { type: "fillSketch", ops: this.renderLines(a, r) };
  }
}
class _w extends tl {
  fillPolygons(t, r) {
    const i = this._fillPolygons(t, r), s = Object.assign({}, r, { hachureAngle: r.hachureAngle + 90 }), o = this._fillPolygons(t, s);
    return i.ops = i.ops.concat(o.ops), i;
  }
}
class Bw {
  constructor(t) {
    this.helper = t;
  }
  fillPolygons(t, r) {
    const i = Vi(t, r = Object.assign({}, r, { hachureAngle: 0 }));
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
      const l = ko(n), c = l / s, h = Math.ceil(c) - 1, d = l - h * s, f = (n[0][0] + n[1][0]) / 2 - s / 4, u = Math.min(n[0][1], n[1][1]);
      for (let g = 0; g < h; g++) {
        const m = u + d + g * s, y = f - a + 2 * Math.random() * a, C = m - a + 2 * Math.random() * a, b = this.helper.ellipse(y, C, o, o, r);
        i.push(...b.ops);
      }
    }
    return { type: "fillSketch", ops: i };
  }
}
class vw {
  constructor(t) {
    this.helper = t;
  }
  fillPolygons(t, r) {
    const i = Vi(t, r);
    return { type: "fillSketch", ops: this.dashedLine(i, r) };
  }
  dashedLine(t, r) {
    const i = r.dashOffset < 0 ? r.hachureGap < 0 ? 4 * r.strokeWidth : r.hachureGap : r.dashOffset, s = r.dashGap < 0 ? r.hachureGap < 0 ? 4 * r.strokeWidth : r.hachureGap : r.dashGap, o = [];
    return t.forEach(((a) => {
      const n = ko(a), l = Math.floor(n / (i + s)), c = (n + s - l * (i + s)) / 2;
      let h = a[0], d = a[1];
      h[0] > d[0] && (h = a[1], d = a[0]);
      const f = Math.atan((d[1] - h[1]) / (d[0] - h[0]));
      for (let u = 0; u < l; u++) {
        const g = u * (i + s), m = g + i, y = [h[0] + g * Math.cos(f) + c * Math.cos(f), h[1] + g * Math.sin(f) + c * Math.sin(f)], C = [h[0] + m * Math.cos(f) + c * Math.cos(f), h[1] + m * Math.sin(f) + c * Math.sin(f)];
        o.push(...this.helper.doubleLineOps(y[0], y[1], C[0], C[1], r));
      }
    })), o;
  }
}
class Lw {
  constructor(t) {
    this.helper = t;
  }
  fillPolygons(t, r) {
    const i = r.hachureGap < 0 ? 4 * r.strokeWidth : r.hachureGap, s = r.zigzagOffset < 0 ? i : r.zigzagOffset, o = Vi(t, r = Object.assign({}, r, { hachureGap: i + s }));
    return { type: "fillSketch", ops: this.zigzagLines(o, s, r) };
  }
  zigzagLines(t, r, i) {
    const s = [];
    return t.forEach(((o) => {
      const a = ko(o), n = Math.round(a / (2 * r));
      let l = o[0], c = o[1];
      l[0] > c[0] && (l = o[1], c = o[0]);
      const h = Math.atan((c[1] - l[1]) / (c[0] - l[0]));
      for (let d = 0; d < n; d++) {
        const f = 2 * d * r, u = 2 * (d + 1) * r, g = Math.sqrt(2 * Math.pow(r, 2)), m = [l[0] + f * Math.cos(h), l[1] + f * Math.sin(h)], y = [l[0] + u * Math.cos(h), l[1] + u * Math.sin(h)], C = [m[0] + g * Math.cos(h + Math.PI / 4), m[1] + g * Math.sin(h + Math.PI / 4)];
        s.push(...this.helper.doubleLineOps(m[0], m[1], C[0], C[1], i), ...this.helper.doubleLineOps(C[0], C[1], y[0], y[1], i));
      }
    })), s;
  }
}
const Kt = {};
class Fw {
  constructor(t) {
    this.seed = t;
  }
  next() {
    return this.seed ? (2 ** 31 - 1 & (this.seed = Math.imul(48271, this.seed))) / 2 ** 31 : Math.random();
  }
}
const Aw = 0, Ko = 1, Ih = 2, cs = { A: 7, a: 7, C: 6, c: 6, H: 1, h: 1, L: 2, l: 2, M: 2, m: 2, Q: 4, q: 4, S: 4, s: 4, T: 2, t: 2, V: 1, v: 1, Z: 0, z: 0 };
function Qo(e, t) {
  return e.type === t;
}
function el(e) {
  const t = [], r = (function(a) {
    const n = new Array();
    for (; a !== ""; ) if (a.match(/^([ \t\r\n,]+)/)) a = a.substr(RegExp.$1.length);
    else if (a.match(/^([aAcChHlLmMqQsStTvVzZ])/)) n[n.length] = { type: Aw, text: RegExp.$1 }, a = a.substr(RegExp.$1.length);
    else {
      if (!a.match(/^(([-+]?[0-9]+(\.[0-9]*)?|[-+]?\.[0-9]+)([eE][-+]?[0-9]+)?)/)) return [];
      n[n.length] = { type: Ko, text: `${parseFloat(RegExp.$1)}` }, a = a.substr(RegExp.$1.length);
    }
    return n[n.length] = { type: Ih, text: "" }, n;
  })(e);
  let i = "BOD", s = 0, o = r[s];
  for (; !Qo(o, Ih); ) {
    let a = 0;
    const n = [];
    if (i === "BOD") {
      if (o.text !== "M" && o.text !== "m") return el("M0,0" + e);
      s++, a = cs[o.text], i = o.text;
    } else Qo(o, Ko) ? a = cs[i] : (s++, a = cs[o.text], i = o.text);
    if (!(s + a < r.length)) throw new Error("Path data ended short");
    for (let l = s; l < s + a; l++) {
      const c = r[l];
      if (!Qo(c, Ko)) throw new Error("Param not a number: " + i + "," + c.text);
      n[n.length] = +c.text;
    }
    if (typeof cs[i] != "number") throw new Error("Bad segment: " + i);
    {
      const l = { key: i, data: n };
      t.push(l), s += a, o = r[s], i === "M" && (i = "L"), i === "m" && (i = "l");
    }
  }
  return t;
}
function ep(e) {
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
function rp(e) {
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
        let d = 0, f = 0;
        r === "C" || r === "S" ? (d = i + (i - n), f = s + (s - l)) : (d = i, f = s), t.push({ key: "C", data: [d, f, ...h] }), n = h[0], l = h[1], i = h[2], s = h[3];
        break;
      }
      case "T": {
        const [d, f] = h;
        let u = 0, g = 0;
        r === "Q" || r === "T" ? (u = i + (i - n), g = s + (s - l)) : (u = i, g = s);
        const m = i + 2 * (u - i) / 3, y = s + 2 * (g - s) / 3, C = d + 2 * (u - d) / 3, b = f + 2 * (g - f) / 3;
        t.push({ key: "C", data: [m, y, C, b, d, f] }), n = u, l = g, i = d, s = f;
        break;
      }
      case "Q": {
        const [d, f, u, g] = h, m = i + 2 * (d - i) / 3, y = s + 2 * (f - s) / 3, C = u + 2 * (d - u) / 3, b = g + 2 * (f - g) / 3;
        t.push({ key: "C", data: [m, y, C, b, u, g] }), n = d, l = f, i = u, s = g;
        break;
      }
      case "A": {
        const d = Math.abs(h[0]), f = Math.abs(h[1]), u = h[2], g = h[3], m = h[4], y = h[5], C = h[6];
        d === 0 || f === 0 ? (t.push({ key: "C", data: [i, s, y, C, y, C] }), i = y, s = C) : (i !== y || s !== C) && (ip(i, s, y, C, d, f, u, g, m).forEach((function(b) {
          t.push({ key: "C", data: b });
        })), i = y, s = C);
        break;
      }
      case "Z":
        t.push({ key: "Z", data: [] }), i = o, s = a;
    }
    r = c;
  }
  return t;
}
function di(e, t, r) {
  return [e * Math.cos(r) - t * Math.sin(r), e * Math.sin(r) + t * Math.cos(r)];
}
function ip(e, t, r, i, s, o, a, n, l, c) {
  const h = (d = a, Math.PI * d / 180);
  var d;
  let f = [], u = 0, g = 0, m = 0, y = 0;
  if (c) [u, g, m, y] = c;
  else {
    [e, t] = di(e, t, -h), [r, i] = di(r, i, -h);
    const W = (e - r) / 2, M = (t - i) / 2;
    let F = W * W / (s * s) + M * M / (o * o);
    F > 1 && (F = Math.sqrt(F), s *= F, o *= F);
    const L = s * s, E = o * o, D = L * E - L * M * M - E * W * W, z = L * M * M + E * W * W, Y = (n === l ? -1 : 1) * Math.sqrt(Math.abs(D / z));
    m = Y * s * M / o + (e + r) / 2, y = Y * -o * W / s + (t + i) / 2, u = Math.asin(parseFloat(((t - y) / o).toFixed(9))), g = Math.asin(parseFloat(((i - y) / o).toFixed(9))), e < m && (u = Math.PI - u), r < m && (g = Math.PI - g), u < 0 && (u = 2 * Math.PI + u), g < 0 && (g = 2 * Math.PI + g), l && u > g && (u -= 2 * Math.PI), !l && g > u && (g -= 2 * Math.PI);
  }
  let C = g - u;
  if (Math.abs(C) > 120 * Math.PI / 180) {
    const W = g, M = r, F = i;
    g = l && g > u ? u + 120 * Math.PI / 180 * 1 : u + 120 * Math.PI / 180 * -1, f = ip(r = m + s * Math.cos(g), i = y + o * Math.sin(g), M, F, s, o, a, 0, l, [g, W, m, y]);
  }
  C = g - u;
  const b = Math.cos(u), k = Math.sin(u), T = Math.cos(g), S = Math.sin(g), _ = Math.tan(C / 4), A = 4 / 3 * s * _, v = 4 / 3 * o * _, q = [e, t], I = [e + A * k, t - v * b], R = [r + A * S, i - v * T], H = [r, i];
  if (I[0] = 2 * q[0] - I[0], I[1] = 2 * q[1] - I[1], c) return [I, R, H].concat(f);
  {
    f = [I, R, H].concat(f);
    const W = [];
    for (let M = 0; M < f.length; M += 3) {
      const F = di(f[M][0], f[M][1], h), L = di(f[M + 1][0], f[M + 1][1], h), E = di(f[M + 2][0], f[M + 2][1], h);
      W.push([F[0], F[1], L[0], L[1], E[0], E[1]]);
    }
    return W;
  }
}
const Mw = { randOffset: function(e, t) {
  return it(e, t);
}, randOffsetWithRange: function(e, t, r) {
  return to(e, t, r);
}, ellipse: function(e, t, r, i, s) {
  const o = op(r, i, s);
  return Ga(e, t, s, o).opset;
}, doubleLineOps: function(e, t, r, i, s) {
  return er(e, t, r, i, s, !0);
} };
function sp(e, t, r, i, s) {
  return { type: "path", ops: er(e, t, r, i, s) };
}
function _s(e, t, r) {
  const i = (e || []).length;
  if (i > 2) {
    const s = [];
    for (let o = 0; o < i - 1; o++) s.push(...er(e[o][0], e[o][1], e[o + 1][0], e[o + 1][1], r));
    return t && s.push(...er(e[i - 1][0], e[i - 1][1], e[0][0], e[0][1], r)), { type: "path", ops: s };
  }
  return i === 2 ? sp(e[0][0], e[0][1], e[1][0], e[1][1], r) : { type: "path", ops: [] };
}
function Ew(e, t, r, i, s) {
  return (function(o, a) {
    return _s(o, !0, a);
  })([[e, t], [e + r, t], [e + r, t + i], [e, t + i]], s);
}
function Dh(e, t) {
  if (e.length) {
    const r = typeof e[0][0] == "number" ? [e] : e, i = ds(r[0], 1 * (1 + 0.2 * t.roughness), t), s = t.disableMultiStroke ? [] : ds(r[0], 1.5 * (1 + 0.22 * t.roughness), Nh(t));
    for (let o = 1; o < r.length; o++) {
      const a = r[o];
      if (a.length) {
        const n = ds(a, 1 * (1 + 0.2 * t.roughness), t), l = t.disableMultiStroke ? [] : ds(a, 1.5 * (1 + 0.22 * t.roughness), Nh(t));
        for (const c of n) c.op !== "move" && i.push(c);
        for (const c of l) c.op !== "move" && s.push(c);
      }
    }
    return { type: "path", ops: i.concat(s) };
  }
  return { type: "path", ops: [] };
}
function op(e, t, r) {
  const i = Math.sqrt(2 * Math.PI * Math.sqrt((Math.pow(e / 2, 2) + Math.pow(t / 2, 2)) / 2)), s = Math.ceil(Math.max(r.curveStepCount, r.curveStepCount / Math.sqrt(200) * i)), o = 2 * Math.PI / s;
  let a = Math.abs(e / 2), n = Math.abs(t / 2);
  const l = 1 - r.curveFitting;
  return a += it(a * l, r), n += it(n * l, r), { increment: o, rx: a, ry: n };
}
function Ga(e, t, r, i) {
  const [s, o] = qh(i.increment, e, t, i.rx, i.ry, 1, i.increment * to(0.1, to(0.4, 1, r), r), r);
  let a = eo(s, null, r);
  if (!r.disableMultiStroke && r.roughness !== 0) {
    const [n] = qh(i.increment, e, t, i.rx, i.ry, 1.5, 0, r), l = eo(n, null, r);
    a = a.concat(l);
  }
  return { estimatedPoints: o, opset: { type: "path", ops: a } };
}
function Rh(e, t, r, i, s, o, a, n, l) {
  const c = e, h = t;
  let d = Math.abs(r / 2), f = Math.abs(i / 2);
  d += it(0.01 * d, l), f += it(0.01 * f, l);
  let u = s, g = o;
  for (; u < 0; ) u += 2 * Math.PI, g += 2 * Math.PI;
  g - u > 2 * Math.PI && (u = 0, g = 2 * Math.PI);
  const m = 2 * Math.PI / l.curveStepCount, y = Math.min(m / 2, (g - u) / 2), C = Wh(y, c, h, d, f, u, g, 1, l);
  if (!l.disableMultiStroke) {
    const b = Wh(y, c, h, d, f, u, g, 1.5, l);
    C.push(...b);
  }
  return a && (n ? C.push(...er(c, h, c + d * Math.cos(u), h + f * Math.sin(u), l), ...er(c, h, c + d * Math.cos(g), h + f * Math.sin(g), l)) : C.push({ op: "lineTo", data: [c, h] }, { op: "lineTo", data: [c + d * Math.cos(u), h + f * Math.sin(u)] })), { type: "path", ops: C };
}
function Ph(e, t) {
  const r = rp(ep(el(e))), i = [];
  let s = [0, 0], o = [0, 0];
  for (const { key: a, data: n } of r) switch (a) {
    case "M":
      o = [n[0], n[1]], s = [n[0], n[1]];
      break;
    case "L":
      i.push(...er(o[0], o[1], n[0], n[1], t)), o = [n[0], n[1]];
      break;
    case "C": {
      const [l, c, h, d, f, u] = n;
      i.push(...$w(l, c, h, d, f, u, o, t)), o = [f, u];
      break;
    }
    case "Z":
      i.push(...er(o[0], o[1], s[0], s[1], t)), o = [s[0], s[1]];
  }
  return { type: "path", ops: i };
}
function Jo(e, t) {
  const r = [];
  for (const i of e) if (i.length) {
    const s = t.maxRandomnessOffset || 0, o = i.length;
    if (o > 2) {
      r.push({ op: "move", data: [i[0][0] + it(s, t), i[0][1] + it(s, t)] });
      for (let a = 1; a < o; a++) r.push({ op: "lineTo", data: [i[a][0] + it(s, t), i[a][1] + it(s, t)] });
    }
  }
  return { type: "fillPath", ops: r };
}
function Or(e, t) {
  return (function(r, i) {
    let s = r.fillStyle || "hachure";
    if (!Kt[s]) switch (s) {
      case "zigzag":
        Kt[s] || (Kt[s] = new Sw(i));
        break;
      case "cross-hatch":
        Kt[s] || (Kt[s] = new _w(i));
        break;
      case "dots":
        Kt[s] || (Kt[s] = new Bw(i));
        break;
      case "dashed":
        Kt[s] || (Kt[s] = new vw(i));
        break;
      case "zigzag-line":
        Kt[s] || (Kt[s] = new Lw(i));
        break;
      default:
        s = "hachure", Kt[s] || (Kt[s] = new tl(i));
    }
    return Kt[s];
  })(t, Mw).fillPolygons(e, t);
}
function Nh(e) {
  const t = Object.assign({}, e);
  return t.randomizer = void 0, e.seed && (t.seed = e.seed + 1), t;
}
function ap(e) {
  return e.randomizer || (e.randomizer = new Fw(e.seed || 0)), e.randomizer.next();
}
function to(e, t, r, i = 1) {
  return r.roughness * i * (ap(r) * (t - e) + e);
}
function it(e, t, r = 1) {
  return to(-e, e, t, r);
}
function er(e, t, r, i, s, o = !1) {
  const a = o ? s.disableMultiStrokeFill : s.disableMultiStroke, n = ja(e, t, r, i, s, !0, !1);
  if (a) return n;
  const l = ja(e, t, r, i, s, !0, !0);
  return n.concat(l);
}
function ja(e, t, r, i, s, o, a) {
  const n = Math.pow(e - r, 2) + Math.pow(t - i, 2), l = Math.sqrt(n);
  let c = 1;
  c = l < 200 ? 1 : l > 500 ? 0.4 : -16668e-7 * l + 1.233334;
  let h = s.maxRandomnessOffset || 0;
  h * h * 100 > n && (h = l / 10);
  const d = h / 2, f = 0.2 + 0.2 * ap(s);
  let u = s.bowing * s.maxRandomnessOffset * (i - t) / 200, g = s.bowing * s.maxRandomnessOffset * (e - r) / 200;
  u = it(u, s, c), g = it(g, s, c);
  const m = [], y = () => it(d, s, c), C = () => it(h, s, c), b = s.preserveVertices;
  return a ? m.push({ op: "move", data: [e + (b ? 0 : y()), t + (b ? 0 : y())] }) : m.push({ op: "move", data: [e + (b ? 0 : it(h, s, c)), t + (b ? 0 : it(h, s, c))] }), a ? m.push({ op: "bcurveTo", data: [u + e + (r - e) * f + y(), g + t + (i - t) * f + y(), u + e + 2 * (r - e) * f + y(), g + t + 2 * (i - t) * f + y(), r + (b ? 0 : y()), i + (b ? 0 : y())] }) : m.push({ op: "bcurveTo", data: [u + e + (r - e) * f + C(), g + t + (i - t) * f + C(), u + e + 2 * (r - e) * f + C(), g + t + 2 * (i - t) * f + C(), r + (b ? 0 : C()), i + (b ? 0 : C())] }), m;
}
function ds(e, t, r) {
  if (!e.length) return [];
  const i = [];
  i.push([e[0][0] + it(t, r), e[0][1] + it(t, r)]), i.push([e[0][0] + it(t, r), e[0][1] + it(t, r)]);
  for (let s = 1; s < e.length; s++) i.push([e[s][0] + it(t, r), e[s][1] + it(t, r)]), s === e.length - 1 && i.push([e[s][0] + it(t, r), e[s][1] + it(t, r)]);
  return eo(i, null, r);
}
function eo(e, t, r) {
  const i = e.length, s = [];
  if (i > 3) {
    const o = [], a = 1 - r.curveTightness;
    s.push({ op: "move", data: [e[1][0], e[1][1]] });
    for (let n = 1; n + 2 < i; n++) {
      const l = e[n];
      o[0] = [l[0], l[1]], o[1] = [l[0] + (a * e[n + 1][0] - a * e[n - 1][0]) / 6, l[1] + (a * e[n + 1][1] - a * e[n - 1][1]) / 6], o[2] = [e[n + 1][0] + (a * e[n][0] - a * e[n + 2][0]) / 6, e[n + 1][1] + (a * e[n][1] - a * e[n + 2][1]) / 6], o[3] = [e[n + 1][0], e[n + 1][1]], s.push({ op: "bcurveTo", data: [o[1][0], o[1][1], o[2][0], o[2][1], o[3][0], o[3][1]] });
    }
  } else i === 3 ? (s.push({ op: "move", data: [e[1][0], e[1][1]] }), s.push({ op: "bcurveTo", data: [e[1][0], e[1][1], e[2][0], e[2][1], e[2][0], e[2][1]] })) : i === 2 && s.push(...ja(e[0][0], e[0][1], e[1][0], e[1][1], r, !0, !0));
  return s;
}
function qh(e, t, r, i, s, o, a, n) {
  const l = [], c = [];
  if (n.roughness === 0) {
    e /= 4, c.push([t + i * Math.cos(-e), r + s * Math.sin(-e)]);
    for (let h = 0; h <= 2 * Math.PI; h += e) {
      const d = [t + i * Math.cos(h), r + s * Math.sin(h)];
      l.push(d), c.push(d);
    }
    c.push([t + i * Math.cos(0), r + s * Math.sin(0)]), c.push([t + i * Math.cos(e), r + s * Math.sin(e)]);
  } else {
    const h = it(0.5, n) - Math.PI / 2;
    c.push([it(o, n) + t + 0.9 * i * Math.cos(h - e), it(o, n) + r + 0.9 * s * Math.sin(h - e)]);
    const d = 2 * Math.PI + h - 0.01;
    for (let f = h; f < d; f += e) {
      const u = [it(o, n) + t + i * Math.cos(f), it(o, n) + r + s * Math.sin(f)];
      l.push(u), c.push(u);
    }
    c.push([it(o, n) + t + i * Math.cos(h + 2 * Math.PI + 0.5 * a), it(o, n) + r + s * Math.sin(h + 2 * Math.PI + 0.5 * a)]), c.push([it(o, n) + t + 0.98 * i * Math.cos(h + a), it(o, n) + r + 0.98 * s * Math.sin(h + a)]), c.push([it(o, n) + t + 0.9 * i * Math.cos(h + 0.5 * a), it(o, n) + r + 0.9 * s * Math.sin(h + 0.5 * a)]);
  }
  return [c, l];
}
function Wh(e, t, r, i, s, o, a, n, l) {
  const c = o + it(0.1, l), h = [];
  h.push([it(n, l) + t + 0.9 * i * Math.cos(c - e), it(n, l) + r + 0.9 * s * Math.sin(c - e)]);
  for (let d = c; d <= a; d += e) h.push([it(n, l) + t + i * Math.cos(d), it(n, l) + r + s * Math.sin(d)]);
  return h.push([t + i * Math.cos(a), r + s * Math.sin(a)]), h.push([t + i * Math.cos(a), r + s * Math.sin(a)]), eo(h, null, l);
}
function $w(e, t, r, i, s, o, a, n) {
  const l = [], c = [n.maxRandomnessOffset || 1, (n.maxRandomnessOffset || 1) + 0.3];
  let h = [0, 0];
  const d = n.disableMultiStroke ? 1 : 2, f = n.preserveVertices;
  for (let u = 0; u < d; u++) u === 0 ? l.push({ op: "move", data: [a[0], a[1]] }) : l.push({ op: "move", data: [a[0] + (f ? 0 : it(c[0], n)), a[1] + (f ? 0 : it(c[0], n))] }), h = f ? [s, o] : [s + it(c[u], n), o + it(c[u], n)], l.push({ op: "bcurveTo", data: [e + it(c[u], n), t + it(c[u], n), r + it(c[u], n), i + it(c[u], n), h[0], h[1]] });
  return l;
}
function ui(e) {
  return [...e];
}
function zh(e, t = 0) {
  const r = e.length;
  if (r < 3) throw new Error("A curve must have at least three points.");
  const i = [];
  if (r === 3) i.push(ui(e[0]), ui(e[1]), ui(e[2]), ui(e[2]));
  else {
    const s = [];
    s.push(e[0], e[0]);
    for (let n = 1; n < e.length; n++) s.push(e[n]), n === e.length - 1 && s.push(e[n]);
    const o = [], a = 1 - t;
    i.push(ui(s[0]));
    for (let n = 1; n + 2 < s.length; n++) {
      const l = s[n];
      o[0] = [l[0], l[1]], o[1] = [l[0] + (a * s[n + 1][0] - a * s[n - 1][0]) / 6, l[1] + (a * s[n + 1][1] - a * s[n - 1][1]) / 6], o[2] = [s[n + 1][0] + (a * s[n][0] - a * s[n + 2][0]) / 6, s[n + 1][1] + (a * s[n][1] - a * s[n + 2][1]) / 6], o[3] = [s[n + 1][0], s[n + 1][1]], i.push(o[1], o[2], o[3]);
    }
  }
  return i;
}
function Bs(e, t) {
  return Math.pow(e[0] - t[0], 2) + Math.pow(e[1] - t[1], 2);
}
function Ow(e, t, r) {
  const i = Bs(t, r);
  if (i === 0) return Bs(e, t);
  let s = ((e[0] - t[0]) * (r[0] - t[0]) + (e[1] - t[1]) * (r[1] - t[1])) / i;
  return s = Math.max(0, Math.min(1, s)), Bs(e, cr(t, r, s));
}
function cr(e, t, r) {
  return [e[0] + (t[0] - e[0]) * r, e[1] + (t[1] - e[1]) * r];
}
function Xa(e, t, r, i) {
  const s = i || [];
  if ((function(n, l) {
    const c = n[l + 0], h = n[l + 1], d = n[l + 2], f = n[l + 3];
    let u = 3 * h[0] - 2 * c[0] - f[0];
    u *= u;
    let g = 3 * h[1] - 2 * c[1] - f[1];
    g *= g;
    let m = 3 * d[0] - 2 * f[0] - c[0];
    m *= m;
    let y = 3 * d[1] - 2 * f[1] - c[1];
    return y *= y, u < m && (u = m), g < y && (g = y), u + g;
  })(e, t) < r) {
    const n = e[t + 0];
    s.length ? (o = s[s.length - 1], a = n, Math.sqrt(Bs(o, a)) > 1 && s.push(n)) : s.push(n), s.push(e[t + 3]);
  } else {
    const l = e[t + 0], c = e[t + 1], h = e[t + 2], d = e[t + 3], f = cr(l, c, 0.5), u = cr(c, h, 0.5), g = cr(h, d, 0.5), m = cr(f, u, 0.5), y = cr(u, g, 0.5), C = cr(m, y, 0.5);
    Xa([l, f, m, C], 0, r, s), Xa([C, y, g, d], 0, r, s);
  }
  var o, a;
  return s;
}
function Iw(e, t) {
  return ro(e, 0, e.length, t);
}
function ro(e, t, r, i, s) {
  const o = s || [], a = e[t], n = e[r - 1];
  let l = 0, c = 1;
  for (let h = t + 1; h < r - 1; ++h) {
    const d = Ow(e[h], a, n);
    d > l && (l = d, c = h);
  }
  return Math.sqrt(l) > i ? (ro(e, t, c + 1, i, o), ro(e, c, r, i, o)) : (o.length || o.push(a), o.push(n)), o;
}
function ta(e, t = 0.15, r) {
  const i = [], s = (e.length - 1) / 3;
  for (let o = 0; o < s; o++)
    Xa(e, 3 * o, t, i);
  return r && r > 0 ? ro(i, 0, i.length, r) : i;
}
const re = "none";
class io {
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
    return this._d("line", [sp(t, r, i, s, a)], a);
  }
  rectangle(t, r, i, s, o) {
    const a = this._o(o), n = [], l = Ew(t, r, i, s, a);
    if (a.fill) {
      const c = [[t, r], [t + i, r], [t + i, r + s], [t, r + s]];
      a.fillStyle === "solid" ? n.push(Jo([c], a)) : n.push(Or([c], a));
    }
    return a.stroke !== re && n.push(l), this._d("rectangle", n, a);
  }
  ellipse(t, r, i, s, o) {
    const a = this._o(o), n = [], l = op(i, s, a), c = Ga(t, r, a, l);
    if (a.fill) if (a.fillStyle === "solid") {
      const h = Ga(t, r, a, l).opset;
      h.type = "fillPath", n.push(h);
    } else n.push(Or([c.estimatedPoints], a));
    return a.stroke !== re && n.push(c.opset), this._d("ellipse", n, a);
  }
  circle(t, r, i, s) {
    const o = this.ellipse(t, r, i, i, s);
    return o.shape = "circle", o;
  }
  linearPath(t, r) {
    const i = this._o(r);
    return this._d("linearPath", [_s(t, !1, i)], i);
  }
  arc(t, r, i, s, o, a, n = !1, l) {
    const c = this._o(l), h = [], d = Rh(t, r, i, s, o, a, n, !0, c);
    if (n && c.fill) if (c.fillStyle === "solid") {
      const f = Object.assign({}, c);
      f.disableMultiStroke = !0;
      const u = Rh(t, r, i, s, o, a, !0, !1, f);
      u.type = "fillPath", h.push(u);
    } else h.push((function(f, u, g, m, y, C, b) {
      const k = f, T = u;
      let S = Math.abs(g / 2), _ = Math.abs(m / 2);
      S += it(0.01 * S, b), _ += it(0.01 * _, b);
      let A = y, v = C;
      for (; A < 0; ) A += 2 * Math.PI, v += 2 * Math.PI;
      v - A > 2 * Math.PI && (A = 0, v = 2 * Math.PI);
      const q = (v - A) / b.curveStepCount, I = [];
      for (let R = A; R <= v; R += q) I.push([k + S * Math.cos(R), T + _ * Math.sin(R)]);
      return I.push([k + S * Math.cos(v), T + _ * Math.sin(v)]), I.push([k, T]), Or([I], b);
    })(t, r, i, s, o, a, c));
    return c.stroke !== re && h.push(d), this._d("arc", h, c);
  }
  curve(t, r) {
    const i = this._o(r), s = [], o = Dh(t, i);
    if (i.fill && i.fill !== re) if (i.fillStyle === "solid") {
      const a = Dh(t, Object.assign(Object.assign({}, i), { disableMultiStroke: !0, roughness: i.roughness ? i.roughness + i.fillShapeRoughnessGain : 0 }));
      s.push({ type: "fillPath", ops: this._mergedShape(a.ops) });
    } else {
      const a = [], n = t;
      if (n.length) {
        const l = typeof n[0][0] == "number" ? [n] : n;
        for (const c of l) c.length < 3 ? a.push(...c) : c.length === 3 ? a.push(...ta(zh([c[0], c[0], c[1], c[2]]), 10, (1 + i.roughness) / 2)) : a.push(...ta(zh(c), 10, (1 + i.roughness) / 2));
      }
      a.length && s.push(Or([a], i));
    }
    return i.stroke !== re && s.push(o), this._d("curve", s, i);
  }
  polygon(t, r) {
    const i = this._o(r), s = [], o = _s(t, !0, i);
    return i.fill && (i.fillStyle === "solid" ? s.push(Jo([t], i)) : s.push(Or([t], i))), i.stroke !== re && s.push(o), this._d("polygon", s, i);
  }
  path(t, r) {
    const i = this._o(r), s = [];
    if (!t) return this._d("path", s, i);
    t = (t || "").replace(/\n/g, " ").replace(/(-\s)/g, "-").replace("/(ss)/g", " ");
    const o = i.fill && i.fill !== "transparent" && i.fill !== re, a = i.stroke !== re, n = !!(i.simplification && i.simplification < 1), l = (function(h, d, f) {
      const u = rp(ep(el(h))), g = [];
      let m = [], y = [0, 0], C = [];
      const b = () => {
        C.length >= 4 && m.push(...ta(C, d)), C = [];
      }, k = () => {
        b(), m.length && (g.push(m), m = []);
      };
      for (const { key: S, data: _ } of u) switch (S) {
        case "M":
          k(), y = [_[0], _[1]], m.push(y);
          break;
        case "L":
          b(), m.push([_[0], _[1]]);
          break;
        case "C":
          if (!C.length) {
            const A = m.length ? m[m.length - 1] : y;
            C.push([A[0], A[1]]);
          }
          C.push([_[0], _[1]]), C.push([_[2], _[3]]), C.push([_[4], _[5]]);
          break;
        case "Z":
          b(), m.push([y[0], y[1]]);
      }
      if (k(), !f) return g;
      const T = [];
      for (const S of g) {
        const _ = Iw(S, f);
        _.length && T.push(_);
      }
      return T;
    })(t, 1, n ? 4 - 4 * (i.simplification || 1) : (1 + i.roughness) / 2), c = Ph(t, i);
    if (o) if (i.fillStyle === "solid") if (l.length === 1) {
      const h = Ph(t, Object.assign(Object.assign({}, i), { disableMultiStroke: !0, roughness: i.roughness ? i.roughness + i.fillShapeRoughnessGain : 0 }));
      s.push({ type: "fillPath", ops: this._mergedShape(h.ops) });
    } else s.push(Jo(l, i));
    else s.push(Or(l, i));
    return a && (n ? l.forEach(((h) => {
      s.push(_s(h, !1, i));
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
          a = { d: this.opsToPath(o), stroke: i.stroke, strokeWidth: i.strokeWidth, fill: re };
          break;
        case "fillPath":
          a = { d: this.opsToPath(o), stroke: re, strokeWidth: 0, fill: i.fill || re };
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
    return i < 0 && (i = r.strokeWidth / 2), { d: this.opsToPath(t), stroke: r.fill || re, strokeWidth: i, fill: re };
  }
  _mergedShape(t) {
    return t.filter(((r, i) => i === 0 || r.op !== "move"));
  }
}
class Dw {
  constructor(t, r) {
    this.canvas = t, this.ctx = this.canvas.getContext("2d"), this.gen = new io(r);
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
const us = "http://www.w3.org/2000/svg";
class Rw {
  constructor(t, r) {
    this.svg = t, this.gen = new io(r);
  }
  draw(t) {
    const r = t.sets || [], i = t.options || this.getDefaultOptions(), s = this.svg.ownerDocument || window.document, o = s.createElementNS(us, "g"), a = t.options.fixedDecimalPlaceDigits;
    for (const n of r) {
      let l = null;
      switch (n.type) {
        case "path":
          l = s.createElementNS(us, "path"), l.setAttribute("d", this.opsToPath(n, a)), l.setAttribute("stroke", i.stroke), l.setAttribute("stroke-width", i.strokeWidth + ""), l.setAttribute("fill", "none"), i.strokeLineDash && l.setAttribute("stroke-dasharray", i.strokeLineDash.join(" ").trim()), i.strokeLineDashOffset && l.setAttribute("stroke-dashoffset", `${i.strokeLineDashOffset}`);
          break;
        case "fillPath":
          l = s.createElementNS(us, "path"), l.setAttribute("d", this.opsToPath(n, a)), l.setAttribute("stroke", "none"), l.setAttribute("stroke-width", "0"), l.setAttribute("fill", i.fill || ""), t.shape !== "curve" && t.shape !== "polygon" || l.setAttribute("fill-rule", "evenodd");
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
    const o = t.createElementNS(us, "path");
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
var j = { canvas: (e, t) => new Dw(e, t), svg: (e, t) => new Rw(e, t), generator: (e) => new io(e), newSeed: () => io.newSeed() }, rt = /* @__PURE__ */ p(async (e, t, r) => {
  let i;
  const s = t.useHtmlLabels || ze(gt()?.htmlLabels);
  r ? i = r : i = "node default";
  const o = e.insert("g").attr("class", i).attr("id", t.domId || t.id), a = o.insert("g").attr("class", "label").attr("style", Dt(t.labelStyle));
  let n;
  t.label === void 0 ? n = "" : n = typeof t.label == "string" ? t.label : t.label[0];
  const l = !!t.icon || !!t.img, c = t.labelType === "markdown", h = await He(
    a,
    me(br(n), gt()),
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
  let d = h.getBBox();
  const f = (t?.padding ?? 0) / 2;
  if (s) {
    const u = h.children[0], g = ht(h);
    await Bf(u, n), d = u.getBoundingClientRect(), g.attr("width", d.width), g.attr("height", d.height);
  }
  return s ? a.attr("transform", "translate(" + -d.width / 2 + ", " + -d.height / 2 + ")") : a.attr("transform", "translate(0, " + -d.height / 2 + ")"), t.centerLabel && a.attr("transform", "translate(" + -d.width / 2 + ", " + -d.height / 2 + ")"), a.insert("rect", ":first-child"), { shapeSvg: o, bbox: d, halfPadding: f, label: a };
}, "labelHelper"), ea = /* @__PURE__ */ p(async (e, t, r) => {
  const i = r.useHtmlLabels ?? Vt(gt()), s = e.insert("g").attr("class", "label").attr("style", r.labelStyle || ""), o = await He(s, me(br(t), gt()), {
    useHtmlLabels: i,
    width: r.width || gt()?.flowchart?.wrappingWidth,
    style: r.labelStyle,
    addSvgBackground: !!r.icon || !!r.img
  });
  let a = o.getBBox();
  const n = r.padding / 2;
  if (Vt(gt())) {
    const l = o.children[0], c = ht(o);
    a = l.getBoundingClientRect(), c.attr("width", a.width), c.attr("height", a.height);
  }
  return i ? s.attr("transform", "translate(" + -a.width / 2 + ", " + -a.height / 2 + ")") : s.attr("transform", "translate(0, " + -a.height / 2 + ")"), r.centerLabel && s.attr("transform", "translate(" + -a.width / 2 + ", " + -a.height / 2 + ")"), s.insert("rect", ":first-child"), { shapeSvg: e, bbox: a, halfPadding: n, label: s };
}, "insertLabel"), K = /* @__PURE__ */ p((e, t) => {
  const r = t.node().getBBox();
  e.width = r.width, e.height = r.height;
}, "updateNodeBounds"), et = /* @__PURE__ */ p((e, t) => (e.look === "handDrawn" ? "rough-node" : "node") + " " + e.cssClasses + " " + (t || ""), "getNodeClasses");
function ft(e) {
  const t = e.map((r, i) => `${i === 0 ? "M" : "L"}${r.x},${r.y}`);
  return t.push("Z"), t.join(" ");
}
p(ft, "createPathFromPoints");
function rr(e, t, r, i, s, o) {
  const a = [], l = r - e, c = i - t, h = l / o, d = 2 * Math.PI / h, f = t + c / 2;
  for (let u = 0; u <= 50; u++) {
    const g = u / 50, m = e + g * l, y = f + s * Math.sin(d * (m - e));
    a.push({ x: m, y });
  }
  return a;
}
p(rr, "generateFullSineWavePoints");
function Pi(e, t, r, i, s, o) {
  const a = [], n = s * Math.PI / 180, h = (o * Math.PI / 180 - n) / (i - 1);
  for (let d = 0; d < i; d++) {
    const f = n + d * h, u = e + r * Math.cos(f), g = t + r * Math.sin(f);
    a.push({ x: -u, y: -g });
  }
  return a;
}
p(Pi, "generateCirclePoints");
function Va(e) {
  const t = Array.from(e.childNodes).filter(
    (l) => l.tagName === "path"
  ), r = document.createElementNS("http://www.w3.org/2000/svg", "path"), i = t.map((l) => l.getAttribute("d")).filter((l) => l !== null).join(" ");
  r.setAttribute("d", i);
  const s = t.find((l) => l.getAttribute("fill") !== "none"), o = t.find((l) => l.getAttribute("stroke") !== "none"), a = /* @__PURE__ */ p((l, c) => l?.getAttribute(c) ?? void 0, "getAttr");
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
p(Va, "mergePaths");
var Pw = /* @__PURE__ */ p((e, t) => {
  var r = e.x, i = e.y, s = t.x - r, o = t.y - i, a = e.width / 2, n = e.height / 2, l, c;
  return Math.abs(o) * a > Math.abs(s) * n ? (o < 0 && (n = -n), l = o === 0 ? 0 : n * s / o, c = n) : (s < 0 && (a = -a), l = a, c = s === 0 ? 0 : a * o / s), { x: r + l, y: i + c };
}, "intersectRect"), ti = Pw, Nw = /* @__PURE__ */ p(async (e, t, r, i = !1, s = !1) => {
  let o = t || "";
  typeof o == "object" && (o = o[0]);
  const a = gt(), n = Vt(a);
  return await He(
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
}, "createLabel"), Ve = Nw, ir = /* @__PURE__ */ p((e, t, r, i, s) => [
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
].join(" "), "createRoundedRectPathD"), np = /* @__PURE__ */ p(async (e, t) => {
  P.info("Creating subgraph rect for ", t.id, t);
  const r = gt(), { themeVariables: i, handDrawnSeed: s } = r, { clusterBkg: o, clusterBorder: a } = i, { labelStyles: n, nodeStyles: l, borderStyles: c, backgroundStyles: h } = Z(t), d = e.insert("g").attr("class", "cluster " + t.cssClasses).attr("id", t.domId).attr("data-look", t.look), f = Vt(r), u = d.insert("g").attr("class", "cluster-label ");
  let g;
  t.labelType === "markdown" ? g = await He(u, t.label, {
    style: t.labelStyle,
    useHtmlLabels: f,
    isNode: !0,
    width: t.width
  }) : g = await Ve(u, t.label, t.labelStyle || "", !1, !0);
  let m = g.getBBox();
  if (Vt(r)) {
    const A = g.children[0], v = ht(g);
    m = A.getBoundingClientRect(), v.attr("width", m.width), v.attr("height", m.height);
  }
  const y = t.width <= m.width + t.padding ? m.width + t.padding : t.width;
  t.width <= m.width + t.padding ? t.diff = (y - t.width) / 2 - t.padding : t.diff = -t.padding;
  const C = t.height, b = t.x - y / 2, k = t.y - C / 2;
  P.trace("Data ", t, JSON.stringify(t));
  let T;
  if (t.look === "handDrawn") {
    const A = j.svg(d), v = V(t, {
      roughness: 0.7,
      fill: o,
      // fill: 'red',
      stroke: a,
      fillWeight: 3,
      seed: s
    }), q = A.path(ir(b, k, y, C, 0), v);
    T = d.insert(() => (P.debug("Rough node insert CXC", q), q), ":first-child"), T.select("path:nth-child(2)").attr("style", c.join(";")), T.select("path").attr("style", h.join(";").replace("fill", "stroke"));
  } else
    T = d.insert("rect", ":first-child"), T.attr("style", l).attr("rx", t.rx).attr("ry", t.ry).attr("x", b).attr("y", k).attr("width", y).attr("height", C);
  const { subGraphTitleTopMargin: S } = Hn(r);
  if (u.attr(
    "transform",
    // This puts the label on top of the box instead of inside it
    `translate(${t.x - m.width / 2}, ${t.y - t.height / 2 + S})`
  ), n) {
    const A = u.select("span");
    A && A.attr("style", n);
  }
  const _ = T.node().getBBox();
  return t.offsetX = 0, t.width = _.width, t.height = _.height, t.offsetY = m.height - t.padding / 2, t.intersect = function(A) {
    return ti(t, A);
  }, { cluster: d, labelBBox: m };
}, "rect"), qw = /* @__PURE__ */ p((e, t) => {
  const r = e.insert("g").attr("class", "note-cluster").attr("id", t.domId), i = r.insert("rect", ":first-child"), s = 0 * t.padding, o = s / 2;
  i.attr("rx", t.rx).attr("ry", t.ry).attr("x", t.x - t.width / 2 - o).attr("y", t.y - t.height / 2 - o).attr("width", t.width + s).attr("height", t.height + s).attr("fill", "none");
  const a = i.node().getBBox();
  return t.width = a.width, t.height = a.height, t.intersect = function(n) {
    return ti(t, n);
  }, { cluster: r, labelBBox: { width: 0, height: 0 } };
}, "noteGroup"), Ww = /* @__PURE__ */ p(async (e, t) => {
  const r = gt(), { themeVariables: i, handDrawnSeed: s } = r, { altBackground: o, compositeBackground: a, compositeTitleBackground: n, nodeBorder: l } = i, c = e.insert("g").attr("class", t.cssClasses).attr("id", t.domId).attr("data-id", t.id).attr("data-look", t.look), h = c.insert("g", ":first-child"), d = c.insert("g").attr("class", "cluster-label");
  let f = c.append("rect");
  const u = await Ve(d, t.label, t.labelStyle, void 0, !0);
  let g = u.getBBox();
  if (Vt(r)) {
    const q = u.children[0], I = ht(u);
    g = q.getBoundingClientRect(), I.attr("width", g.width), I.attr("height", g.height);
  }
  const m = 0 * t.padding, y = m / 2, C = (t.width <= g.width + t.padding ? g.width + t.padding : t.width) + m;
  t.width <= g.width + t.padding ? t.diff = (C - t.width) / 2 - t.padding : t.diff = -t.padding;
  const b = t.height + m, k = t.height + m - g.height - 6, T = t.x - C / 2, S = t.y - b / 2;
  t.width = C;
  const _ = t.y - t.height / 2 - y + g.height + 2;
  let A;
  if (t.look === "handDrawn") {
    const q = t.cssClasses.includes("statediagram-cluster-alt"), I = j.svg(c), R = t.rx || t.ry ? I.path(ir(T, S, C, b, 10), {
      roughness: 0.7,
      fill: n,
      fillStyle: "solid",
      stroke: l,
      seed: s
    }) : I.rectangle(T, S, C, b, { seed: s });
    A = c.insert(() => R, ":first-child");
    const H = I.rectangle(T, _, C, k, {
      fill: q ? o : a,
      fillStyle: q ? "hachure" : "solid",
      stroke: l,
      seed: s
    });
    A = c.insert(() => R, ":first-child"), f = c.insert(() => H);
  } else
    A = h.insert("rect", ":first-child"), A.attr("class", "outer").attr("x", T).attr("y", S).attr("width", C).attr("height", b).attr("data-look", t.look), f.attr("class", "inner").attr("x", T).attr("y", _).attr("width", C).attr("height", k);
  d.attr(
    "transform",
    `translate(${t.x - g.width / 2}, ${S + 1 - (Vt(r) ? 0 : 3)})`
  );
  const v = A.node().getBBox();
  return t.height = v.height, t.offsetX = 0, t.offsetY = g.height - t.padding / 2, t.labelBBox = g, t.intersect = function(q) {
    return ti(t, q);
  }, { cluster: c, labelBBox: g };
}, "roundedWithTitle"), zw = /* @__PURE__ */ p(async (e, t) => {
  P.info("Creating subgraph rect for ", t.id, t);
  const r = gt(), { themeVariables: i, handDrawnSeed: s } = r, { clusterBkg: o, clusterBorder: a } = i, { labelStyles: n, nodeStyles: l, borderStyles: c, backgroundStyles: h } = Z(t), d = e.insert("g").attr("class", "cluster " + t.cssClasses).attr("id", t.domId).attr("data-look", t.look), f = Vt(r), u = d.insert("g").attr("class", "cluster-label "), g = await He(u, t.label, {
    style: t.labelStyle,
    useHtmlLabels: f,
    isNode: !0,
    width: t.width
  });
  let m = g.getBBox();
  if (Vt(r)) {
    const A = g.children[0], v = ht(g);
    m = A.getBoundingClientRect(), v.attr("width", m.width), v.attr("height", m.height);
  }
  const y = t.width <= m.width + t.padding ? m.width + t.padding : t.width;
  t.width <= m.width + t.padding ? t.diff = (y - t.width) / 2 - t.padding : t.diff = -t.padding;
  const C = t.height, b = t.x - y / 2, k = t.y - C / 2;
  P.trace("Data ", t, JSON.stringify(t));
  let T;
  if (t.look === "handDrawn") {
    const A = j.svg(d), v = V(t, {
      roughness: 0.7,
      fill: o,
      // fill: 'red',
      stroke: a,
      fillWeight: 4,
      seed: s
    }), q = A.path(ir(b, k, y, C, t.rx), v);
    T = d.insert(() => (P.debug("Rough node insert CXC", q), q), ":first-child"), T.select("path:nth-child(2)").attr("style", c.join(";")), T.select("path").attr("style", h.join(";").replace("fill", "stroke"));
  } else
    T = d.insert("rect", ":first-child"), T.attr("style", l).attr("rx", t.rx).attr("ry", t.ry).attr("x", b).attr("y", k).attr("width", y).attr("height", C);
  const { subGraphTitleTopMargin: S } = Hn(r);
  if (u.attr(
    "transform",
    // This puts the label on top of the box instead of inside it
    `translate(${t.x - m.width / 2}, ${t.y - t.height / 2 + S})`
  ), n) {
    const A = u.select("span");
    A && A.attr("style", n);
  }
  const _ = T.node().getBBox();
  return t.offsetX = 0, t.width = _.width, t.height = _.height, t.offsetY = m.height - t.padding / 2, t.intersect = function(A) {
    return ti(t, A);
  }, { cluster: d, labelBBox: m };
}, "kanbanSection"), Hw = /* @__PURE__ */ p((e, t) => {
  const r = gt(), { themeVariables: i, handDrawnSeed: s } = r, { nodeBorder: o } = i, a = e.insert("g").attr("class", t.cssClasses).attr("id", t.domId).attr("data-look", t.look), n = a.insert("g", ":first-child"), l = 0 * t.padding, c = t.width + l;
  t.diff = -t.padding;
  const h = t.height + l, d = t.x - c / 2, f = t.y - h / 2;
  t.width = c;
  let u;
  if (t.look === "handDrawn") {
    const y = j.svg(a).rectangle(d, f, c, h, {
      fill: "lightgrey",
      roughness: 0.5,
      strokeLineDash: [5],
      stroke: o,
      seed: s
    });
    u = a.insert(() => y, ":first-child");
  } else {
    u = n.insert("rect", ":first-child");
    let m = "outer";
    t.look, m = "divider", u.attr("class", m).attr("x", d).attr("y", f).attr("width", c).attr("height", h).attr("data-look", t.look);
  }
  const g = u.node().getBBox();
  return t.height = g.height, t.offsetX = 0, t.offsetY = 0, t.intersect = function(m) {
    return ti(t, m);
  }, { cluster: a, labelBBox: {} };
}, "divider"), Yw = np, Uw = {
  rect: np,
  squareRect: Yw,
  roundedWithTitle: Ww,
  noteGroup: qw,
  divider: Hw,
  kanbanSection: zw
}, lp = /* @__PURE__ */ new Map(), Gw = /* @__PURE__ */ p(async (e, t) => {
  const r = t.shape || "rect", i = await Uw[r](e, t);
  return lp.set(t.id, i), i;
}, "insertCluster"), Pv = /* @__PURE__ */ p(() => {
  lp = /* @__PURE__ */ new Map();
}, "clear");
function hp(e, t) {
  return e.intersect(t);
}
p(hp, "intersectNode");
var jw = hp;
function cp(e, t, r, i) {
  var s = e.x, o = e.y, a = s - i.x, n = o - i.y, l = Math.sqrt(t * t * n * n + r * r * a * a), c = Math.abs(t * r * a / l);
  i.x < s && (c = -c);
  var h = Math.abs(t * r * n / l);
  return i.y < o && (h = -h), { x: s + c, y: o + h };
}
p(cp, "intersectEllipse");
var dp = cp;
function up(e, t, r) {
  return dp(e, t, t, r);
}
p(up, "intersectCircle");
var Xw = up;
function fp(e, t, r, i) {
  {
    const s = t.y - e.y, o = e.x - t.x, a = t.x * e.y - e.x * t.y, n = s * r.x + o * r.y + a, l = s * i.x + o * i.y + a, c = 1e-6;
    if (n !== 0 && l !== 0 && Za(n, l))
      return;
    const h = i.y - r.y, d = r.x - i.x, f = i.x * r.y - r.x * i.y, u = h * e.x + d * e.y + f, g = h * t.x + d * t.y + f;
    if (Math.abs(u) < c && Math.abs(g) < c && Za(u, g))
      return;
    const m = s * d - h * o;
    if (m === 0)
      return;
    const y = Math.abs(m / 2);
    let C = o * f - d * a;
    const b = C < 0 ? (C - y) / m : (C + y) / m;
    C = h * a - s * f;
    const k = C < 0 ? (C - y) / m : (C + y) / m;
    return { x: b, y: k };
  }
}
p(fp, "intersectLine");
function Za(e, t) {
  return e * t > 0;
}
p(Za, "sameSign");
var Vw = fp;
function pp(e, t, r) {
  let i = e.x, s = e.y, o = [], a = Number.POSITIVE_INFINITY, n = Number.POSITIVE_INFINITY;
  typeof t.forEach == "function" ? t.forEach(function(h) {
    a = Math.min(a, h.x), n = Math.min(n, h.y);
  }) : (a = Math.min(a, t.x), n = Math.min(n, t.y));
  let l = i - e.width / 2 - a, c = s - e.height / 2 - n;
  for (let h = 0; h < t.length; h++) {
    let d = t[h], f = t[h < t.length - 1 ? h + 1 : 0], u = Vw(
      e,
      r,
      { x: l + d.x, y: c + d.y },
      { x: l + f.x, y: c + f.y }
    );
    u && o.push(u);
  }
  return o.length ? (o.length > 1 && o.sort(function(h, d) {
    let f = h.x - r.x, u = h.y - r.y, g = Math.sqrt(f * f + u * u), m = d.x - r.x, y = d.y - r.y, C = Math.sqrt(m * m + y * y);
    return g < C ? -1 : g === C ? 0 : 1;
  }), o[0]) : e;
}
p(pp, "intersectPolygon");
var Zw = pp, G = {
  node: jw,
  circle: Xw,
  ellipse: dp,
  polygon: Zw,
  rect: ti
};
function gp(e, t) {
  const { labelStyles: r } = Z(t);
  t.labelStyle = r;
  const i = et(t);
  let s = i;
  i || (s = "anchor");
  const o = e.insert("g").attr("class", s).attr("id", t.domId || t.id), a = 1, { cssStyles: n } = t, l = j.svg(o), c = V(t, { fill: "black", stroke: "none", fillStyle: "solid" });
  t.look !== "handDrawn" && (c.roughness = 0);
  const h = l.circle(0, 0, a * 2, c), d = o.insert(() => h, ":first-child");
  return d.attr("class", "anchor").attr("style", Dt(n)), K(t, d), t.intersect = function(f) {
    return P.info("Circle intersect", t, a, f), G.circle(t, a, f);
  }, o;
}
p(gp, "anchor");
function Ka(e, t, r, i, s, o, a) {
  const l = (e + r) / 2, c = (t + i) / 2, h = Math.atan2(i - t, r - e), d = (r - e) / 2, f = (i - t) / 2, u = d / s, g = f / o, m = Math.sqrt(u ** 2 + g ** 2);
  if (m > 1)
    throw new Error("The given radii are too small to create an arc between the points.");
  const y = Math.sqrt(1 - m ** 2), C = l + y * o * Math.sin(h) * (a ? -1 : 1), b = c - y * s * Math.cos(h) * (a ? -1 : 1), k = Math.atan2((t - b) / o, (e - C) / s);
  let S = Math.atan2((i - b) / o, (r - C) / s) - k;
  a && S < 0 && (S += 2 * Math.PI), !a && S > 0 && (S -= 2 * Math.PI);
  const _ = [];
  for (let A = 0; A < 20; A++) {
    const v = A / 19, q = k + v * S, I = C + s * Math.cos(q), R = b + o * Math.sin(q);
    _.push({ x: I, y: R });
  }
  return _;
}
p(Ka, "generateArcPoints");
function mp(e, t, r) {
  const [i, s] = [t, r].sort((o, a) => a - o);
  return s * (1 - Math.sqrt(1 - (e / i / 2) ** 2));
}
p(mp, "calculateArcSagitta");
async function yp(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 16 : s, a = t.look === "neo" ? 12 : s, n = /* @__PURE__ */ p((q) => q + a, "calcTotalHeight"), l = /* @__PURE__ */ p((q) => {
    const I = q / 2;
    return [I / (2.5 + q / 50), I];
  }, "calcEllipseRadius"), { shapeSvg: c, bbox: h } = await rt(e, t, et(t)), d = n(t?.height ? t?.height : h.height), [f, u] = l(d), g = mp(d, f, u), y = (t?.width ? t?.width : h.width) + o * 2 + g - g, C = d, { cssStyles: b } = t, k = [
    { x: y / 2, y: -C / 2 },
    { x: -y / 2, y: -C / 2 },
    ...Ka(-y / 2, -C / 2, -y / 2, C / 2, f, u, !1),
    { x: y / 2, y: C / 2 },
    ...Ka(y / 2, C / 2, y / 2, -C / 2, f, u, !0)
  ], T = j.svg(c), S = V(t, {});
  t.look !== "handDrawn" && (S.roughness = 0, S.fillStyle = "solid");
  const _ = ft(k), A = T.path(_, S), v = c.insert(() => A, ":first-child");
  return v.attr("class", "basic label-container outer-path"), b && t.look !== "handDrawn" && v.selectAll("path").attr("style", b), i && t.look !== "handDrawn" && v.selectAll("path").attr("style", i), v.attr("transform", `translate(${f / 2}, 0)`), K(t, v), t.intersect = function(q) {
    return G.polygon(t, k, q);
  }, c;
}
p(yp, "bowTieRect");
function Ye(e, t, r, i) {
  return e.insert("polygon", ":first-child").attr(
    "points",
    i.map(function(s) {
      return s.x + "," + s.y;
    }).join(" ")
  ).attr("class", "label-container").attr("transform", "translate(" + -t / 2 + "," + r / 2 + ")");
}
p(Ye, "insertPolygonShape");
var fs = 12;
async function Cp(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 28 : s, a = t.look === "neo" ? 24 : s, { shapeSvg: n, bbox: l } = await rt(e, t, et(t)), c = (t?.width ?? l.width) + (t.look === "neo" ? o * 2 : o + fs), h = (t?.height ?? l.height) + (t.look === "neo" ? a * 2 : a), d = 0, f = c, u = -h, g = 0, m = [
    { x: d + fs, y: u },
    { x: f, y: u },
    { x: f, y: g },
    { x: d, y: g },
    { x: d, y: u + fs },
    { x: d + fs, y: u }
  ];
  let y;
  const { cssStyles: C } = t;
  if (t.look === "handDrawn") {
    const b = j.svg(n), k = V(t, {}), T = ft(m), S = b.path(T, k);
    y = n.insert(() => S, ":first-child").attr("transform", `translate(${-c / 2}, ${h / 2})`), C && y.attr("style", C);
  } else
    y = Ye(n, c, h, m);
  return i && y.attr("style", i), K(t, y), t.intersect = function(b) {
    return G.polygon(t, m, b);
  }, n;
}
p(Cp, "card");
function xp(e, t) {
  const { nodeStyles: r } = Z(t);
  t.label = "";
  const i = e.insert("g").attr("class", et(t)).attr("id", t.domId ?? t.id), { cssStyles: s } = t, o = Math.max(28, t.width ?? 0), a = [
    { x: 0, y: o / 2 },
    { x: o / 2, y: 0 },
    { x: 0, y: -o / 2 },
    { x: -o / 2, y: 0 }
  ], n = j.svg(i), l = V(t, {});
  t.look !== "handDrawn" && (l.roughness = 0, l.fillStyle = "solid");
  const c = ft(a), h = n.path(c, l), d = i.insert(() => h, ":first-child");
  return s && t.look !== "handDrawn" && d.selectAll("path").attr("style", s), r && t.look !== "handDrawn" && d.selectAll("path").attr("style", r), t.width = 28, t.height = 28, t.intersect = function(f) {
    return G.polygon(t, a, f);
  }, i;
}
p(xp, "choice");
async function rl(e, t, r) {
  const { labelStyles: i, nodeStyles: s } = Z(t);
  t.labelStyle = i;
  const { shapeSvg: o, bbox: a, halfPadding: n } = await rt(e, t, et(t)), l = 16, c = r?.padding ?? n, h = t.look === "neo" ? a.width / 2 + l * 2 : a.width / 2 + c;
  let d;
  const { cssStyles: f } = t;
  if (t.look === "handDrawn") {
    const u = j.svg(o), g = V(t, {}), m = u.circle(0, 0, h * 2, g);
    d = o.insert(() => m, ":first-child"), d.attr("class", "basic label-container").attr("style", Dt(f));
  } else
    d = o.insert("circle", ":first-child").attr("class", "basic label-container").attr("style", s).attr("r", h).attr("cx", 0).attr("cy", 0);
  return K(t, d), t.calcIntersect = function(u, g) {
    const m = u.width / 2;
    return G.circle(u, m, g);
  }, t.intersect = function(u) {
    return P.info("Circle intersect", t, h, u), G.circle(t, h, u);
  }, o;
}
p(rl, "circle");
function bp(e) {
  const t = Math.cos(Math.PI / 4), r = Math.sin(Math.PI / 4), i = e * 2, s = { x: i / 2 * t, y: i / 2 * r }, o = { x: -(i / 2) * t, y: i / 2 * r }, a = { x: -(i / 2) * t, y: -(i / 2) * r }, n = { x: i / 2 * t, y: -(i / 2) * r };
  return `M ${o.x},${o.y} L ${n.x},${n.y}
                   M ${s.x},${s.y} L ${a.x},${a.y}`;
}
p(bp, "createLine");
function kp(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r, t.label = "";
  const s = e.insert("g").attr("class", et(t)).attr("id", t.domId ?? t.id), o = Math.max(30, t?.width ?? 0), { cssStyles: a } = t, n = j.svg(s), l = V(t, {});
  t.look !== "handDrawn" && (l.roughness = 0, l.fillStyle = "solid");
  const c = n.circle(0, 0, o * 2, l), h = bp(o), d = n.path(h, l), f = s.insert(() => c, ":first-child");
  return f.insert(() => d), f.attr("class", "outer-path"), a && t.look !== "handDrawn" && f.selectAll("path").attr("style", a), i && t.look !== "handDrawn" && f.selectAll("path").attr("style", i), K(t, f), t.intersect = function(u) {
    return P.info("crossedCircle intersect", t, { radius: o, point: u }), G.circle(t, o, u);
  }, s;
}
p(kp, "crossedCircle");
function Ie(e, t, r, i = 100, s = 0, o = 180) {
  const a = [], n = s * Math.PI / 180, h = (o * Math.PI / 180 - n) / (i - 1);
  for (let d = 0; d < i; d++) {
    const f = n + d * h, u = e + r * Math.cos(f), g = t + r * Math.sin(f);
    a.push({ x: -u, y: -g });
  }
  return a;
}
p(Ie, "generateCirclePoints");
async function wp(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const { shapeSvg: s, bbox: o, label: a } = await rt(e, t, et(t)), n = t.look === "neo" ? 18 : t.padding ?? 0, l = t.look === "neo" ? 12 : t.padding ?? 0, c = o.width + n, h = o.height + l, d = Math.max(5, h * 0.1), { cssStyles: f } = t, u = [
    ...Ie(c / 2, -h / 2, d, 30, -90, 0),
    { x: -c / 2 - d, y: d },
    ...Ie(c / 2 + d * 2, -d, d, 20, -180, -270),
    ...Ie(c / 2 + d * 2, d, d, 20, -90, -180),
    { x: -c / 2 - d, y: -h / 2 },
    ...Ie(c / 2, h / 2, d, 20, 0, 90)
  ], g = [
    { x: c / 2, y: -h / 2 - d },
    { x: -c / 2, y: -h / 2 - d },
    ...Ie(c / 2, -h / 2, d, 20, -90, 0),
    { x: -c / 2 - d, y: -d },
    ...Ie(c / 2 + c * 0.1, -d, d, 20, -180, -270),
    ...Ie(c / 2 + c * 0.1, d, d, 20, -90, -180),
    { x: -c / 2 - d, y: h / 2 },
    ...Ie(c / 2, h / 2, d, 20, 0, 90),
    { x: -c / 2, y: h / 2 + d },
    { x: c / 2, y: h / 2 + d }
  ], m = j.svg(s), y = V(t, { fill: "none" });
  t.look !== "handDrawn" && (y.roughness = 0, y.fillStyle = "solid");
  const b = ft(u).replace("Z", ""), k = m.path(b, y), T = ft(g), S = m.path(T, { ...y }), _ = s.insert("g", ":first-child");
  return _.insert(() => S, ":first-child").attr("stroke-opacity", 0), _.insert(() => k, ":first-child"), _.attr("class", "text"), f && t.look !== "handDrawn" && _.selectAll("path").attr("style", f), i && t.look !== "handDrawn" && _.selectAll("path").attr("style", i), _.attr("transform", `translate(${d}, 0)`), a.attr(
    "transform",
    `translate(${-c / 2 + d - (o.x - (o.left ?? 0))},${-h / 2 + (t.padding ?? 0) / 2 - (o.y - (o.top ?? 0))})`
  ), K(t, _), t.intersect = function(A) {
    return G.polygon(t, g, A);
  }, s;
}
p(wp, "curlyBraceLeft");
function De(e, t, r, i = 100, s = 0, o = 180) {
  const a = [], n = s * Math.PI / 180, h = (o * Math.PI / 180 - n) / (i - 1);
  for (let d = 0; d < i; d++) {
    const f = n + d * h, u = e + r * Math.cos(f), g = t + r * Math.sin(f);
    a.push({ x: u, y: g });
  }
  return a;
}
p(De, "generateCirclePoints");
async function Tp(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const { shapeSvg: s, bbox: o, label: a } = await rt(e, t, et(t)), n = t.look === "neo" ? 18 : t.padding ?? 0, l = t.look === "neo" ? 12 : t.padding ?? 0, c = o.width + (t.look === "neo" ? n * 2 : n), h = o.height + (t.look === "neo" ? l * 2 : l), d = Math.max(5, h * 0.1), { cssStyles: f } = t, u = [
    ...De(c / 2, -h / 2, d, 20, -90, 0),
    { x: c / 2 + d, y: -d },
    ...De(c / 2 + d * 2, -d, d, 20, -180, -270),
    ...De(c / 2 + d * 2, d, d, 20, -90, -180),
    { x: c / 2 + d, y: h / 2 },
    ...De(c / 2, h / 2, d, 20, 0, 90)
  ], g = [
    { x: -c / 2, y: -h / 2 - d },
    { x: c / 2, y: -h / 2 - d },
    ...De(c / 2, -h / 2, d, 20, -90, 0),
    { x: c / 2 + d, y: -d },
    ...De(c / 2 + d * 2, -d, d, 20, -180, -270),
    ...De(c / 2 + d * 2, d, d, 20, -90, -180),
    { x: c / 2 + d, y: h / 2 },
    ...De(c / 2, h / 2, d, 20, 0, 90),
    { x: c / 2, y: h / 2 + d },
    { x: -c / 2, y: h / 2 + d }
  ], m = j.svg(s), y = V(t, { fill: "none" });
  t.look !== "handDrawn" && (y.roughness = 0, y.fillStyle = "solid");
  const b = ft(u).replace("Z", ""), k = m.path(b, y), T = ft(g), S = m.path(T, { ...y }), _ = s.insert("g", ":first-child");
  return _.insert(() => S, ":first-child").attr("stroke-opacity", 0), _.insert(() => k, ":first-child"), _.attr("class", "text"), f && t.look !== "handDrawn" && _.selectAll("path").attr("style", f), i && t.look !== "handDrawn" && _.selectAll("path").attr("style", i), _.attr("transform", `translate(${-d}, 0)`), a.attr(
    "transform",
    `translate(${-c / 2 + (t.padding ?? 0) / 2 - (o.x - (o.left ?? 0))},${-h / 2 + (t.padding ?? 0) / 2 - (o.y - (o.top ?? 0))})`
  ), K(t, _), t.intersect = function(A) {
    return G.polygon(t, g, A);
  }, s;
}
p(Tp, "curlyBraceRight");
function Pt(e, t, r, i = 100, s = 0, o = 180) {
  const a = [], n = s * Math.PI / 180, h = (o * Math.PI / 180 - n) / (i - 1);
  for (let d = 0; d < i; d++) {
    const f = n + d * h, u = e + r * Math.cos(f), g = t + r * Math.sin(f);
    a.push({ x: -u, y: -g });
  }
  return a;
}
p(Pt, "generateCirclePoints");
async function Sp(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const { shapeSvg: s, bbox: o, label: a } = await rt(e, t, et(t)), n = t.look === "neo" ? 18 : t.padding ?? 0, l = t.look === "neo" ? 12 : t.padding ?? 0, c = o.width + (t.look === "neo" ? n * 2 : n), h = o.height + (t.look === "neo" ? l * 2 : l), d = Math.max(5, h * 0.1), { cssStyles: f } = t, u = [
    ...Pt(c / 2, -h / 2, d, 30, -90, 0),
    { x: -c / 2 - d, y: d },
    ...Pt(c / 2 + d * 2, -d, d, 20, -180, -270),
    ...Pt(c / 2 + d * 2, d, d, 20, -90, -180),
    { x: -c / 2 - d, y: -h / 2 },
    ...Pt(c / 2, h / 2, d, 20, 0, 90)
  ], g = [
    ...Pt(-c / 2 + d + d / 2, -h / 2, d, 20, -90, -180),
    { x: c / 2 - d / 2, y: d },
    ...Pt(-c / 2 - d / 2, -d, d, 20, 0, 90),
    ...Pt(-c / 2 - d / 2, d, d, 20, -90, 0),
    { x: c / 2 - d / 2, y: -d },
    ...Pt(-c / 2 + d + d / 2, h / 2, d, 30, -180, -270)
  ], m = [
    { x: c / 2, y: -h / 2 - d },
    { x: -c / 2, y: -h / 2 - d },
    ...Pt(c / 2, -h / 2, d, 20, -90, 0),
    { x: -c / 2 - d, y: -d },
    ...Pt(c / 2 + d * 2, -d, d, 20, -180, -270),
    ...Pt(c / 2 + d * 2, d, d, 20, -90, -180),
    { x: -c / 2 - d, y: h / 2 },
    ...Pt(c / 2, h / 2, d, 20, 0, 90),
    { x: -c / 2, y: h / 2 + d },
    { x: c / 2 - d - d / 2, y: h / 2 + d },
    ...Pt(-c / 2 + d + d / 2, -h / 2, d, 20, -90, -180),
    { x: c / 2 - d / 2, y: d },
    ...Pt(-c / 2 - d / 2, -d, d, 20, 0, 90),
    ...Pt(-c / 2 - d / 2, d, d, 20, -90, 0),
    { x: c / 2 - d / 2, y: -d },
    ...Pt(-c / 2 + d + d / 2, h / 2, d, 30, -180, -270)
  ], y = j.svg(s), C = V(t, { fill: "none" });
  t.look !== "handDrawn" && (C.roughness = 0, C.fillStyle = "solid");
  const k = ft(u).replace("Z", ""), T = y.path(k, C), _ = ft(g).replace("Z", ""), A = y.path(_, C), v = ft(m), q = y.path(v, { ...C }), I = s.insert("g", ":first-child");
  return I.insert(() => q, ":first-child").attr("stroke-opacity", 0), I.insert(() => T, ":first-child"), I.insert(() => A, ":first-child"), I.attr("class", "text"), f && t.look !== "handDrawn" && I.selectAll("path").attr("style", f), i && t.look !== "handDrawn" && I.selectAll("path").attr("style", i), I.attr("transform", `translate(${d - d / 4}, 0)`), a.attr(
    "transform",
    `translate(${-c / 2 + (t.padding ?? 0) / 2 - (o.x - (o.left ?? 0))},${-h / 2 + (t.padding ?? 0) / 2 - (o.y - (o.top ?? 0))})`
  ), K(t, I), t.intersect = function(R) {
    return G.polygon(t, m, R);
  }, s;
}
p(Sp, "curlyBraces");
async function _p(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 16 : s, a = t.look === "neo" ? 12 : s, n = 20, l = 5, { shapeSvg: c, bbox: h } = await rt(e, t, et(t)), d = Math.max(n, (h.width + o * 2) * 1.25, t?.width ?? 0), f = Math.max(l, h.height + a * 2, t?.height ?? 0), u = f / 2, { cssStyles: g } = t, m = j.svg(c), y = V(t, {});
  t.look !== "handDrawn" && (y.roughness = 0, y.fillStyle = "solid");
  const C = d, b = f, k = C - u, T = b / 4, S = [
    { x: k, y: 0 },
    { x: T, y: 0 },
    { x: 0, y: b / 2 },
    { x: T, y: b },
    { x: k, y: b },
    ...Pi(-k, -b / 2, u, 50, 270, 90)
  ], _ = ft(S), A = m.path(_, y), v = c.insert(() => A, ":first-child");
  return v.attr("class", "basic label-container outer-path"), g && t.look !== "handDrawn" && v.selectChildren("path").attr("style", g), i && t.look !== "handDrawn" && v.selectChildren("path").attr("style", i), v.attr("transform", `translate(${-d / 2}, ${-f / 2})`), K(t, v), t.intersect = function(q) {
    return G.polygon(t, S, q);
  }, c;
}
p(_p, "curvedTrapezoid");
var Kw = /* @__PURE__ */ p((e, t, r, i, s, o) => [
  `M${e},${t + o}`,
  `a${s},${o} 0,0,0 ${r},0`,
  `a${s},${o} 0,0,0 ${-r},0`,
  `l0,${i}`,
  `a${s},${o} 0,0,0 ${r},0`,
  `l0,${-i}`
].join(" "), "createCylinderPathD"), Qw = /* @__PURE__ */ p((e, t, r, i, s, o) => [
  `M${e},${t + o}`,
  `M${e + r},${t + o}`,
  `a${s},${o} 0,0,0 ${-r},0`,
  `l0,${i}`,
  `a${s},${o} 0,0,0 ${r},0`,
  `l0,${-i}`
].join(" "), "createOuterCylinderPathD"), Jw = /* @__PURE__ */ p((e, t, r, i, s, o) => [`M${e - r / 2},${-i / 2}`, `a${s},${o} 0,0,0 ${r},0`].join(" "), "createInnerCylinderPathD"), Hh = 8, Yh = 8;
async function Bp(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 24 : s, a = t.look === "neo" ? 24 : s;
  if (t.width || t.height) {
    const y = t.width ?? 0;
    t.width = (t.width ?? 0) - a, t.width < Yh && (t.width = Yh);
    const b = y / 2 / (2.5 + y / 50);
    t.height = (t.height ?? 0) - o - b * 3, t.height < Hh && (t.height = Hh);
  }
  const { shapeSvg: n, bbox: l, label: c } = await rt(e, t, et(t)), h = (t.width ? t.width : l.width) + a, d = h / 2, f = d / (2.5 + h / 50), u = (t.height ? t.height : l.height) + o + f;
  let g;
  const { cssStyles: m } = t;
  if (t.look === "handDrawn") {
    const y = j.svg(n), C = Qw(0, 0, h, u, d, f), b = Jw(0, f, h, u, d, f), k = V(t, {}), T = y.path(C, k), S = y.path(b, V(t, { fill: "none" }));
    g = n.insert(() => S, ":first-child"), g = n.insert(() => T, ":first-child"), g.attr("class", "basic label-container"), m && g.attr("style", m);
  } else {
    const y = Kw(0, 0, h, u, d, f);
    g = n.insert("path", ":first-child").attr("d", y).attr("class", "basic label-container outer-path").attr("style", Dt(m)).attr("style", i);
  }
  return g.attr("label-offset-y", f), g.attr("transform", `translate(${-h / 2}, ${-(u / 2 + f)})`), K(t, g), c.attr(
    "transform",
    `translate(${-(l.width / 2) - (l.x - (l.left ?? 0))}, ${-(l.height / 2) + (t.padding ?? 0) / 1.5 - (l.y - (l.top ?? 0))})`
  ), t.intersect = function(y) {
    const C = G.rect(t, y), b = C.x - (t.x ?? 0);
    if (d != 0 && (Math.abs(b) < (t.width ?? 0) / 2 || Math.abs(b) == (t.width ?? 0) / 2 && Math.abs(C.y - (t.y ?? 0)) > (t.height ?? 0) / 2 - f)) {
      let k = f * f * (1 - b * b / (d * d));
      k > 0 && (k = Math.sqrt(k)), k = f - k, y.y - (t.y ?? 0) > 0 && (k = -k), C.y += k;
    }
    return C;
  }, n;
}
p(Bp, "cylinder");
async function ei(e, t, r) {
  const { labelStyles: i, nodeStyles: s } = Z(t);
  t.labelStyle = i;
  const { shapeSvg: o, bbox: a } = await rt(e, t, et(t)), n = Math.max(a.width + r.labelPaddingX * 2, t?.width || 0), l = Math.max(a.height + r.labelPaddingY * 2, t?.height || 0), c = -n / 2, h = -l / 2;
  let d, { rx: f, ry: u } = t;
  const { cssStyles: g } = t;
  if (r?.rx && r.ry && (f = r.rx, u = r.ry), t.look === "handDrawn") {
    const m = j.svg(o), y = V(t, {}), C = f || u ? m.path(ir(c, h, n, l, f || 0), y) : m.rectangle(c, h, n, l, y);
    d = o.insert(() => C, ":first-child"), d.attr("class", "basic label-container").attr("style", Dt(g));
  } else
    d = o.insert("rect", ":first-child"), d.attr("class", "basic label-container").attr("style", s).attr("rx", Dt(f)).attr("ry", Dt(u)).attr("x", c).attr("y", h).attr("width", n).attr("height", l);
  return K(t, d), t.calcIntersect = function(m, y) {
    return G.rect(m, y);
  }, t.intersect = function(m) {
    return G.rect(t, m);
  }, o;
}
p(ei, "drawRect");
async function vp(e, t) {
  const { cssClasses: r, labelPaddingX: i, labelPaddingY: s, padding: o, width: a, height: n } = t, l = {
    rx: 0,
    ry: 0,
    labelPaddingX: i ?? (o ?? 0) * 2,
    labelPaddingY: s ?? o ?? 0
  }, c = await ei(e, t, l);
  if (t.look === "handDrawn") {
    const u = j.svg(c), g = V(t, {}), m = c.select(".basic.label-container > path:nth-child(2)"), y = m.node();
    if (!y)
      return c;
    let C = null;
    if (y instanceof SVGGraphicsElement)
      C = y.getBBox();
    else
      return c;
    return c.insert(
      () => u.line(C.x, C.y, C.x + C.width, C.y, g),
      ".basic.label-container g.label"
    ), c.insert(
      () => u.line(
        C.x,
        C.y + C.height,
        C.x + C.width,
        C.y + C.height,
        g
      ),
      ".basic.label-container g.label"
    ), m.remove(), c;
  }
  const h = c.select(".basic.label-container"), d = (Number(h.attr("width")) || a) ?? 0, f = (Number(h.attr("height")) || n) ?? 0;
  return d > 0 && f > 0 && h.attr("stroke-dasharray", `${d} ${f}`), c;
}
p(vp, "datastore");
async function Lp(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const s = t.look === "neo" ? 16 : t.padding ?? 0, o = t.look === "neo" ? 16 : t.padding ?? 0, { shapeSvg: a, bbox: n, label: l } = await rt(e, t, et(t)), c = n.width + s, h = n.height + o, d = h * 0.2, f = -c / 2, u = -h / 2 - d / 2, { cssStyles: g } = t, m = j.svg(a), y = V(t, {});
  t.look !== "handDrawn" && (y.roughness = 0, y.fillStyle = "solid");
  const C = [
    { x: f, y: u + d },
    { x: -f, y: u + d },
    { x: -f, y: -u },
    { x: f, y: -u },
    { x: f, y: u },
    { x: -f, y: u },
    { x: -f, y: u + d }
  ], b = m.polygon(
    C.map((T) => [T.x, T.y]),
    y
  ), k = a.insert(() => b, ":first-child");
  return k.attr("class", "basic label-container outer-path"), g && t.look !== "handDrawn" && k.selectAll("path").attr("style", g), i && t.look !== "handDrawn" && k.selectAll("path").attr("style", i), l.attr(
    "transform",
    `translate(${f + (t.padding ?? 0) / 2 - (n.x - (n.left ?? 0))}, ${u + d + (t.padding ?? 0) / 2 - (n.y - (n.top ?? 0))})`
  ), K(t, k), t.intersect = function(T) {
    return G.rect(t, T);
  }, a;
}
p(Lp, "dividedRectangle");
async function Fp(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t), s = t.look === "neo" ? 12 : 5;
  t.labelStyle = r;
  const o = t.padding ?? 0, a = t.look === "neo" ? 16 : o, { shapeSvg: n, bbox: l } = await rt(e, t, et(t)), c = (t?.width ? t?.width / 2 : l.width / 2) + (a ?? 0), h = c - s;
  let d;
  const { cssStyles: f } = t;
  if (t.look === "handDrawn") {
    const u = j.svg(n), g = V(t, { roughness: 0.2, strokeWidth: 2.5 }), m = V(t, { roughness: 0.2, strokeWidth: 1.5 }), y = u.circle(0, 0, c * 2, g), C = u.circle(0, 0, h * 2, m);
    d = n.insert("g", ":first-child"), d.attr("class", Dt(t.cssClasses)).attr("style", Dt(f)), d.node()?.appendChild(y), d.node()?.appendChild(C);
  } else {
    d = n.insert("g", ":first-child");
    const u = d.insert("circle", ":first-child"), g = d.insert("circle");
    d.attr("class", "basic label-container").attr("style", i), u.attr("class", "outer-circle").attr("style", i).attr("r", c).attr("cx", 0).attr("cy", 0), g.attr("class", "inner-circle").attr("style", i).attr("r", h).attr("cx", 0).attr("cy", 0);
  }
  return K(t, d), t.intersect = function(u) {
    return P.info("DoubleCircle intersect", t, c, u), G.circle(t, c, u);
  }, n;
}
p(Fp, "doublecircle");
function Ap(e, t, { config: { themeVariables: r } }) {
  const { labelStyles: i, nodeStyles: s } = Z(t);
  t.label = "", t.labelStyle = i;
  const o = e.insert("g").attr("class", et(t)).attr("id", t.domId ?? t.id), a = 7, { cssStyles: n } = t, l = j.svg(o), { nodeBorder: c } = r, h = V(t, { fillStyle: "solid" });
  t.look !== "handDrawn" && (h.roughness = 0);
  const d = l.circle(0, 0, a * 2, h), f = o.insert(() => d, ":first-child");
  return f.selectAll("path").attr("style", `fill: ${c} !important;`), n && n.length > 0 && t.look !== "handDrawn" && f.selectAll("path").attr("style", n), s && t.look !== "handDrawn" && f.selectAll("path").attr("style", s), K(t, f), t.intersect = function(u) {
    return P.info("filledCircle intersect", t, { radius: a, point: u }), G.circle(t, a, u);
  }, o;
}
p(Ap, "filledCircle");
var Uh = 10, Gh = 10;
async function Mp(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? s * 2 : s;
  (t.width || t.height) && (t.height = t?.height ?? 0, t.height < Uh && (t.height = Uh), t.width = (t?.width ?? 0) - o - o / 2, t.width < Gh && (t.width = Gh));
  const { shapeSvg: a, bbox: n, label: l } = await rt(e, t, et(t)), c = (t?.width ? t?.width : n.width) + (o ?? 0), h = t?.height ? t?.height : c + n.height, d = h, f = [
    { x: 0, y: -h },
    { x: d, y: -h },
    { x: d / 2, y: 0 }
  ], { cssStyles: u } = t, g = j.svg(a), m = V(t, {});
  t.look !== "handDrawn" && (m.roughness = 0, m.fillStyle = "solid");
  const y = ft(f), C = g.path(y, m), b = a.insert(() => C, ":first-child").attr("transform", `translate(${-h / 2}, ${h / 2})`).attr("class", "outer-path");
  return u && t.look !== "handDrawn" && b.selectChildren("path").attr("style", u), i && t.look !== "handDrawn" && b.selectChildren("path").attr("style", i), t.width = c, t.height = h, K(t, b), l.attr(
    "transform",
    `translate(${-n.width / 2 - (n.x - (n.left ?? 0))}, ${-h / 2 + (t.padding ?? 0) / 2 + (n.y - (n.top ?? 0))})`
  ), t.intersect = function(k) {
    return P.info("Triangle intersect", t, f, k), G.polygon(t, f, k);
  }, a;
}
p(Mp, "flippedTriangle");
function Ep(e, t, { dir: r, config: { state: i, themeVariables: s } }) {
  const { nodeStyles: o } = Z(t);
  t.label = "";
  const a = e.insert("g").attr("class", et(t)).attr("id", t.domId ?? t.id), { cssStyles: n } = t;
  let l = Math.max(70, t?.width ?? 0), c = Math.max(10, t?.height ?? 0);
  r === "LR" && (l = Math.max(10, t?.width ?? 0), c = Math.max(70, t?.height ?? 0));
  const h = -1 * l / 2, d = -1 * c / 2, f = j.svg(a), u = V(t, {
    stroke: s.lineColor,
    fill: s.lineColor
  });
  t.look !== "handDrawn" && (u.roughness = 0, u.fillStyle = "solid");
  const g = f.rectangle(h, d, l, c, u), m = a.insert(() => g, ":first-child");
  n && t.look !== "handDrawn" && m.selectAll("path").attr("style", n), o && t.look !== "handDrawn" && m.selectAll("path").attr("style", o), K(t, m);
  const y = i?.padding ?? 0;
  return t.width && t.height && (t.width += y / 2 || 0, t.height += y / 2 || 0), t.intersect = function(C) {
    return G.rect(t, C);
  }, a;
}
p(Ep, "forkJoin");
async function $p(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const s = 15, o = 10, a = t.look === "neo" ? 16 : t.padding ?? 0, n = t.look === "neo" ? 12 : t.padding ?? 0;
  (t.width || t.height) && (t.height = (t?.height ?? 0) - n * 2, t.height < o && (t.height = o), t.width = (t?.width ?? 0) - a * 2, t.width < s && (t.width = s));
  const { shapeSvg: l, bbox: c } = await rt(e, t, et(t)), h = (t?.width ? t?.width : Math.max(s, c.width)) + a * 2, d = (t?.height ? t?.height : Math.max(o, c.height)) + n * 2, f = d / 2, { cssStyles: u } = t, g = j.svg(l), m = V(t, {});
  t.look !== "handDrawn" && (m.roughness = 0, m.fillStyle = "solid");
  const y = [
    { x: -h / 2, y: -d / 2 },
    { x: h / 2 - f, y: -d / 2 },
    ...Pi(-h / 2 + f, 0, f, 50, 90, 270),
    { x: h / 2 - f, y: d / 2 },
    { x: -h / 2, y: d / 2 }
  ], C = ft(y), b = g.path(C, m), k = l.insert(() => b, ":first-child");
  return k.attr("class", "basic label-container outer-path"), u && t.look !== "handDrawn" && k.selectChildren("path").attr("style", u), i && t.look !== "handDrawn" && k.selectChildren("path").attr("style", i), K(t, k), t.intersect = function(T) {
    return P.info("Pill intersect", t, { radius: f, point: T }), G.polygon(t, y, T);
  }, l;
}
p($p, "halfRoundedRectangle");
var tT = /* @__PURE__ */ p((e, t, r, i, s) => [
  `M${e + s},${t}`,
  `L${e + r - s},${t}`,
  `L${e + r},${t - i / 2}`,
  `L${e + r - s},${t - i}`,
  `L${e + s},${t - i}`,
  `L${e},${t - i / 2}`,
  "Z"
].join(" "), "createHexagonPathD");
async function Op(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t), s = t.look === "neo" ? 3.5 : 4;
  t.labelStyle = r;
  const o = t.padding ?? 0, a = 70, n = 32, l = t.look === "neo" ? a : o, c = t.look === "neo" ? n : o;
  if (t.width || t.height) {
    const k = (t.height ?? 0) / s;
    t.width = (t?.width ?? 0) - 2 * k - c, t.height = (t.height ?? 0) - l;
  }
  const { shapeSvg: h, bbox: d } = await rt(e, t, et(t)), f = (t?.height ? t?.height : d.height) + l, u = f / s, g = (t?.width ? t?.width : d.width) + 2 * u + c, m = [
    { x: u, y: 0 },
    { x: g - u, y: 0 },
    { x: g, y: -f / 2 },
    { x: g - u, y: -f },
    { x: u, y: -f },
    { x: 0, y: -f / 2 }
  ];
  let y;
  const { cssStyles: C } = t;
  if (t.look === "handDrawn") {
    const b = j.svg(h), k = V(t, {}), T = tT(0, 0, g, f, u), S = b.path(T, k);
    y = h.insert(() => S, ":first-child").attr("transform", `translate(${-g / 2}, ${f / 2})`), C && y.attr("style", C);
  } else
    y = Ye(h, g, f, m);
  return i && y.attr("style", i), t.width = g, t.height = f, K(t, y), t.intersect = function(b) {
    return G.polygon(t, m, b);
  }, h;
}
p(Op, "hexagon");
async function Ip(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.label = "", t.labelStyle = r;
  const { shapeSvg: s } = await rt(e, t, et(t)), o = Math.max(30, t?.width ?? 0), a = Math.max(30, t?.height ?? 0), { cssStyles: n } = t, l = j.svg(s), c = V(t, {});
  t.look !== "handDrawn" && (c.roughness = 0, c.fillStyle = "solid");
  const h = [
    { x: 0, y: 0 },
    { x: o, y: 0 },
    { x: 0, y: a },
    { x: o, y: a }
  ], d = ft(h), f = l.path(d, c), u = s.insert(() => f, ":first-child");
  return u.attr("class", "basic label-container outer-path"), n && t.look !== "handDrawn" && u.selectChildren("path").attr("style", n), i && t.look !== "handDrawn" && u.selectChildren("path").attr("style", i), u.attr("transform", `translate(${-o / 2}, ${-a / 2})`), K(t, u), t.intersect = function(g) {
    return P.info("Pill intersect", t, { points: h }), G.polygon(t, h, g);
  }, s;
}
p(Ip, "hourglass");
async function Dp(e, t, { config: { themeVariables: r, flowchart: i } }) {
  const { labelStyles: s } = Z(t);
  t.labelStyle = s;
  const o = t.assetHeight ?? 48, a = t.assetWidth ?? 48, n = Math.max(o, a), l = i?.wrappingWidth;
  t.width = Math.max(n, l ?? 0);
  const { shapeSvg: c, bbox: h, label: d } = await rt(e, t, "icon-shape default"), f = t.pos === "t", u = n, g = n, { nodeBorder: m } = r, { stylesMap: y } = Jr(t), C = -g / 2, b = -u / 2, k = t.label ? 8 : 0, T = j.svg(c), S = V(t, { stroke: "none", fill: "none" });
  t.look !== "handDrawn" && (S.roughness = 0, S.fillStyle = "solid");
  const _ = T.rectangle(C, b, g, u, S), A = Math.max(g, h.width), v = u + h.height + k, q = T.rectangle(-A / 2, -v / 2, A, v, {
    ...S,
    fill: "transparent",
    stroke: "none"
  }), I = c.insert(() => _, ":first-child"), R = c.insert(() => q);
  if (t.icon) {
    const H = c.append("g");
    H.html(
      `<g>${await Xi(t.icon, {
        height: n,
        width: n,
        fallbackPrefix: ""
      })}</g>`
    );
    const W = H.node().getBBox(), M = W.width, F = W.height, L = W.x, E = W.y;
    H.attr(
      "transform",
      `translate(${-M / 2 - L},${f ? h.height / 2 + k / 2 - F / 2 - E : -h.height / 2 - k / 2 - F / 2 - E})`
    ), H.attr("style", `color: ${y.get("stroke") ?? m};`);
  }
  return d.attr(
    "transform",
    `translate(${-h.width / 2 - (h.x - (h.left ?? 0))},${f ? -v / 2 : v / 2 - h.height})`
  ), I.attr(
    "transform",
    `translate(0,${f ? h.height / 2 + k / 2 : -h.height / 2 - k / 2})`
  ), K(t, R), t.intersect = function(H) {
    if (P.info("iconSquare intersect", t, H), !t.label)
      return G.rect(t, H);
    const W = t.x ?? 0, M = t.y ?? 0, F = t.height ?? 0;
    let L = [];
    return f ? L = [
      { x: W - h.width / 2, y: M - F / 2 },
      { x: W + h.width / 2, y: M - F / 2 },
      { x: W + h.width / 2, y: M - F / 2 + h.height + k },
      { x: W + g / 2, y: M - F / 2 + h.height + k },
      { x: W + g / 2, y: M + F / 2 },
      { x: W - g / 2, y: M + F / 2 },
      { x: W - g / 2, y: M - F / 2 + h.height + k },
      { x: W - h.width / 2, y: M - F / 2 + h.height + k }
    ] : L = [
      { x: W - g / 2, y: M - F / 2 },
      { x: W + g / 2, y: M - F / 2 },
      { x: W + g / 2, y: M - F / 2 + u },
      { x: W + h.width / 2, y: M - F / 2 + u },
      { x: W + h.width / 2 / 2, y: M + F / 2 },
      { x: W - h.width / 2, y: M + F / 2 },
      { x: W - h.width / 2, y: M - F / 2 + u },
      { x: W - g / 2, y: M - F / 2 + u }
    ], G.polygon(t, L, H);
  }, c;
}
p(Dp, "icon");
async function Rp(e, t, { config: { themeVariables: r, flowchart: i } }) {
  const { labelStyles: s } = Z(t);
  t.labelStyle = s;
  const o = t.assetHeight ?? 48, a = t.assetWidth ?? 48, n = Math.max(o, a), l = i?.wrappingWidth;
  t.width = Math.max(n, l ?? 0);
  const { shapeSvg: c, bbox: h, label: d } = await rt(e, t, "icon-shape default"), f = 20, u = t.label ? 8 : 0, g = t.pos === "t", { nodeBorder: m, mainBkg: y } = r, { stylesMap: C } = Jr(t), b = j.svg(c), k = V(t, {});
  t.look !== "handDrawn" && (k.roughness = 0, k.fillStyle = "solid");
  const T = C.get("fill");
  k.stroke = T ?? y;
  const S = c.append("g");
  t.icon && S.html(
    `<g>${await Xi(t.icon, {
      height: n,
      width: n,
      fallbackPrefix: ""
    })}</g>`
  );
  const _ = S.node().getBBox(), A = _.width, v = _.height, q = _.x, I = _.y, R = Math.max(A, v) * Math.SQRT2 + f * 2, H = b.circle(0, 0, R, k), W = Math.max(R, h.width), M = R + h.height + u, F = b.rectangle(-W / 2, -M / 2, W, M, {
    ...k,
    fill: "transparent",
    stroke: "none"
  }), L = c.insert(() => H, ":first-child"), E = c.insert(() => F);
  return S.attr(
    "transform",
    `translate(${-A / 2 - q},${g ? h.height / 2 + u / 2 - v / 2 - I : -h.height / 2 - u / 2 - v / 2 - I})`
  ), S.attr("style", `color: ${C.get("stroke") ?? m};`), d.attr(
    "transform",
    `translate(${-h.width / 2 - (h.x - (h.left ?? 0))},${g ? -M / 2 : M / 2 - h.height})`
  ), L.attr(
    "transform",
    `translate(0,${g ? h.height / 2 + u / 2 : -h.height / 2 - u / 2})`
  ), K(t, E), t.intersect = function(D) {
    return P.info("iconSquare intersect", t, D), G.rect(t, D);
  }, c;
}
p(Rp, "iconCircle");
async function Pp(e, t, { config: { themeVariables: r, flowchart: i } }) {
  const { labelStyles: s } = Z(t);
  t.labelStyle = s;
  const o = t.assetHeight ?? 48, a = t.assetWidth ?? 48, n = Math.max(o, a), l = i?.wrappingWidth;
  t.width = Math.max(n, l ?? 0);
  const { shapeSvg: c, bbox: h, halfPadding: d, label: f } = await rt(
    e,
    t,
    "icon-shape default"
  ), u = t.pos === "t", g = n + d * 2, m = n + d * 2, { nodeBorder: y, mainBkg: C } = r, { stylesMap: b } = Jr(t), k = -m / 2, T = -g / 2, S = t.label ? 8 : 0, _ = j.svg(c), A = V(t, {});
  t.look !== "handDrawn" && (A.roughness = 0, A.fillStyle = "solid");
  const v = b.get("fill");
  A.stroke = v ?? C;
  const q = _.path(ir(k, T, m, g, 5), A), I = Math.max(m, h.width), R = g + h.height + S, H = _.rectangle(-I / 2, -R / 2, I, R, {
    ...A,
    fill: "transparent",
    stroke: "none"
  }), W = c.insert(() => q, ":first-child").attr("class", "icon-shape2"), M = c.insert(() => H);
  if (t.icon) {
    const F = c.append("g");
    F.html(
      `<g>${await Xi(t.icon, {
        height: n,
        width: n,
        fallbackPrefix: ""
      })}</g>`
    );
    const L = F.node().getBBox(), E = L.width, D = L.height, z = L.x, Y = L.y;
    F.attr(
      "transform",
      `translate(${-E / 2 - z},${u ? h.height / 2 + S / 2 - D / 2 - Y : -h.height / 2 - S / 2 - D / 2 - Y})`
    ), F.attr("style", `color: ${b.get("stroke") ?? y};`);
  }
  return f.attr(
    "transform",
    `translate(${-h.width / 2 - (h.x - (h.left ?? 0))},${u ? -R / 2 : R / 2 - h.height})`
  ), W.attr(
    "transform",
    `translate(0,${u ? h.height / 2 + S / 2 : -h.height / 2 - S / 2})`
  ), K(t, M), t.intersect = function(F) {
    if (P.info("iconSquare intersect", t, F), !t.label)
      return G.rect(t, F);
    const L = t.x ?? 0, E = t.y ?? 0, D = t.height ?? 0;
    let z = [];
    return u ? z = [
      { x: L - h.width / 2, y: E - D / 2 },
      { x: L + h.width / 2, y: E - D / 2 },
      { x: L + h.width / 2, y: E - D / 2 + h.height + S },
      { x: L + m / 2, y: E - D / 2 + h.height + S },
      { x: L + m / 2, y: E + D / 2 },
      { x: L - m / 2, y: E + D / 2 },
      { x: L - m / 2, y: E - D / 2 + h.height + S },
      { x: L - h.width / 2, y: E - D / 2 + h.height + S }
    ] : z = [
      { x: L - m / 2, y: E - D / 2 },
      { x: L + m / 2, y: E - D / 2 },
      { x: L + m / 2, y: E - D / 2 + g },
      { x: L + h.width / 2, y: E - D / 2 + g },
      { x: L + h.width / 2 / 2, y: E + D / 2 },
      { x: L - h.width / 2, y: E + D / 2 },
      { x: L - h.width / 2, y: E - D / 2 + g },
      { x: L - m / 2, y: E - D / 2 + g }
    ], G.polygon(t, z, F);
  }, c;
}
p(Pp, "iconRounded");
async function Np(e, t, { config: { themeVariables: r, flowchart: i } }) {
  const { labelStyles: s } = Z(t);
  t.labelStyle = s;
  const o = t.assetHeight ?? 48, a = t.assetWidth ?? 48, n = Math.max(o, a), l = i?.wrappingWidth;
  t.width = Math.max(n, l ?? 0);
  const { shapeSvg: c, bbox: h, halfPadding: d, label: f } = await rt(
    e,
    t,
    "icon-shape default"
  ), u = t.pos === "t", g = n + d * 2, m = n + d * 2, { nodeBorder: y, mainBkg: C } = r, { stylesMap: b } = Jr(t), k = -m / 2, T = -g / 2, S = t.label ? 8 : 0, _ = j.svg(c), A = V(t, {});
  t.look !== "handDrawn" && (A.roughness = 0, A.fillStyle = "solid");
  const v = b.get("fill");
  A.stroke = v ?? C;
  const q = _.path(ir(k, T, m, g, 0.1), A), I = Math.max(m, h.width), R = g + h.height + S, H = _.rectangle(-I / 2, -R / 2, I, R, {
    ...A,
    fill: "transparent",
    stroke: "none"
  }), W = c.insert(() => q, ":first-child"), M = c.insert(() => H);
  if (t.icon) {
    const F = c.append("g");
    F.html(
      `<g>${await Xi(t.icon, {
        height: n,
        width: n,
        fallbackPrefix: ""
      })}</g>`
    );
    const L = F.node().getBBox(), E = L.width, D = L.height, z = L.x, Y = L.y;
    F.attr(
      "transform",
      `translate(${-E / 2 - z},${u ? h.height / 2 + S / 2 - D / 2 - Y : -h.height / 2 - S / 2 - D / 2 - Y})`
    ), F.attr("style", `color: ${b.get("stroke") ?? y};`);
  }
  return f.attr(
    "transform",
    `translate(${-h.width / 2 - (h.x - (h.left ?? 0))},${u ? -R / 2 : R / 2 - h.height})`
  ), W.attr(
    "transform",
    `translate(0,${u ? h.height / 2 + S / 2 : -h.height / 2 - S / 2})`
  ), K(t, M), t.intersect = function(F) {
    if (P.info("iconSquare intersect", t, F), !t.label)
      return G.rect(t, F);
    const L = t.x ?? 0, E = t.y ?? 0, D = t.height ?? 0;
    let z = [];
    return u ? z = [
      { x: L - h.width / 2, y: E - D / 2 },
      { x: L + h.width / 2, y: E - D / 2 },
      { x: L + h.width / 2, y: E - D / 2 + h.height + S },
      { x: L + m / 2, y: E - D / 2 + h.height + S },
      { x: L + m / 2, y: E + D / 2 },
      { x: L - m / 2, y: E + D / 2 },
      { x: L - m / 2, y: E - D / 2 + h.height + S },
      { x: L - h.width / 2, y: E - D / 2 + h.height + S }
    ] : z = [
      { x: L - m / 2, y: E - D / 2 },
      { x: L + m / 2, y: E - D / 2 },
      { x: L + m / 2, y: E - D / 2 + g },
      { x: L + h.width / 2, y: E - D / 2 + g },
      { x: L + h.width / 2 / 2, y: E + D / 2 },
      { x: L - h.width / 2, y: E + D / 2 },
      { x: L - h.width / 2, y: E - D / 2 + g },
      { x: L - m / 2, y: E - D / 2 + g }
    ], G.polygon(t, z, F);
  }, c;
}
p(Np, "iconSquare");
async function qp(e, t, { config: { flowchart: r } }) {
  const i = new Image();
  i.src = t?.img ?? "", await i.decode();
  const s = Number(i.naturalWidth.toString().replace("px", "")), o = Number(i.naturalHeight.toString().replace("px", ""));
  t.imageAspectRatio = s / o;
  const { labelStyles: a } = Z(t);
  t.labelStyle = a;
  const n = r?.wrappingWidth;
  t.defaultWidth = r?.wrappingWidth;
  const l = Math.max(
    t.label ? n ?? 0 : 0,
    t?.assetWidth ?? s
  ), c = t.constraint === "on" && t?.assetHeight ? t.assetHeight * t.imageAspectRatio : l, h = t.constraint === "on" ? c / t.imageAspectRatio : t?.assetHeight ?? o;
  t.width = Math.max(c, n ?? 0);
  const { shapeSvg: d, bbox: f, label: u } = await rt(e, t, "image-shape default"), g = t.pos === "t", m = -c / 2, y = -h / 2, C = t.label ? 8 : 0, b = j.svg(d), k = V(t, {});
  t.look !== "handDrawn" && (k.roughness = 0, k.fillStyle = "solid");
  const T = b.rectangle(m, y, c, h, k), S = Math.max(c, f.width), _ = h + f.height + C, A = b.rectangle(-S / 2, -_ / 2, S, _, {
    ...k,
    fill: "none",
    stroke: "none"
  }), v = d.insert(() => T, ":first-child"), q = d.insert(() => A);
  if (t.img) {
    const I = d.append("image");
    I.attr("href", t.img), I.attr("width", c), I.attr("height", h), I.attr("preserveAspectRatio", "none"), I.attr(
      "transform",
      `translate(${-c / 2},${g ? _ / 2 - h : -_ / 2})`
    );
  }
  return u.attr(
    "transform",
    `translate(${-f.width / 2 - (f.x - (f.left ?? 0))},${g ? -h / 2 - f.height / 2 - C / 2 : h / 2 - f.height / 2 + C / 2})`
  ), v.attr(
    "transform",
    `translate(0,${g ? f.height / 2 + C / 2 : -f.height / 2 - C / 2})`
  ), K(t, q), t.intersect = function(I) {
    if (P.info("iconSquare intersect", t, I), !t.label)
      return G.rect(t, I);
    const R = t.x ?? 0, H = t.y ?? 0, W = t.height ?? 0;
    let M = [];
    return g ? M = [
      { x: R - f.width / 2, y: H - W / 2 },
      { x: R + f.width / 2, y: H - W / 2 },
      { x: R + f.width / 2, y: H - W / 2 + f.height + C },
      { x: R + c / 2, y: H - W / 2 + f.height + C },
      { x: R + c / 2, y: H + W / 2 },
      { x: R - c / 2, y: H + W / 2 },
      { x: R - c / 2, y: H - W / 2 + f.height + C },
      { x: R - f.width / 2, y: H - W / 2 + f.height + C }
    ] : M = [
      { x: R - c / 2, y: H - W / 2 },
      { x: R + c / 2, y: H - W / 2 },
      { x: R + c / 2, y: H - W / 2 + h },
      { x: R + f.width / 2, y: H - W / 2 + h },
      { x: R + f.width / 2 / 2, y: H + W / 2 },
      { x: R - f.width / 2, y: H + W / 2 },
      { x: R - f.width / 2, y: H - W / 2 + h },
      { x: R - c / 2, y: H - W / 2 + h }
    ], G.polygon(t, M, I);
  }, d;
}
p(qp, "imageSquare");
async function Wp(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = s, a = t.look === "neo" ? s * 2 : s, { shapeSvg: n, bbox: l } = await rt(e, t, et(t)), c = Math.max(l.width + (a ?? 0) * 2, t?.width ?? 0), h = Math.max(l.height + (o ?? 0) * 2, t?.height ?? 0), d = [
    { x: 0, y: 0 },
    { x: c, y: 0 },
    { x: c + 3 * h / 6, y: -h },
    { x: -3 * h / 6, y: -h }
  ];
  let f;
  const { cssStyles: u } = t;
  if (t.look === "handDrawn") {
    const g = j.svg(n), m = V(t, {}), y = ft(d), C = g.path(y, m);
    f = n.insert(() => C, ":first-child").attr("transform", `translate(${-c / 2}, ${h / 2})`), u && f.attr("style", u);
  } else
    f = Ye(n, c, h, d);
  return i && f.attr("style", i), t.width = c, t.height = h, K(t, f), t.intersect = function(g) {
    return G.polygon(t, d, g);
  }, n;
}
p(Wp, "inv_trapezoid");
async function zp(e, t) {
  const { shapeSvg: r, bbox: i, label: s } = await rt(e, t, "label"), o = r.insert("rect", ":first-child");
  return o.attr("width", 0.1).attr("height", 0.1), r.attr("class", "label edgeLabel"), s.attr(
    "transform",
    `translate(${-(i.width / 2) - (i.x - (i.left ?? 0))}, ${-(i.height / 2) - (i.y - (i.top ?? 0))})`
  ), K(t, o), t.intersect = function(l) {
    return G.rect(t, l);
  }, r;
}
p(zp, "labelRect");
async function Hp(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = s, a = t.look === "neo" ? s * 2 : s, { shapeSvg: n, bbox: l } = await rt(e, t, et(t)), c = (t?.height ?? l.height) + o, h = (t?.width ?? l.width) + a, d = [
    { x: 0, y: 0 },
    { x: h + 3 * c / 6, y: 0 },
    { x: h, y: -c },
    { x: -(3 * c) / 6, y: -c }
  ];
  let f;
  const { cssStyles: u } = t;
  if (t.look === "handDrawn") {
    const g = j.svg(n), m = V(t, {}), y = ft(d), C = g.path(y, m);
    f = n.insert(() => C, ":first-child").attr("transform", `translate(${-h / 2}, ${c / 2})`), u && f.attr("style", u);
  } else
    f = Ye(n, h, c, d);
  return i && f.attr("style", i), t.width = h, t.height = c, K(t, f), t.intersect = function(g) {
    return G.polygon(t, d, g);
  }, n;
}
p(Hp, "lean_left");
async function Yp(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = s, a = t.look === "neo" ? s * 2 : s, { shapeSvg: n, bbox: l } = await rt(e, t, et(t)), c = (t?.height ?? l.height) + o, h = (t?.width ?? l.width) + a, d = [
    { x: -3 * c / 6, y: 0 },
    { x: h, y: 0 },
    { x: h + 3 * c / 6, y: -c },
    { x: 0, y: -c }
  ];
  let f;
  const { cssStyles: u } = t;
  if (t.look === "handDrawn") {
    const g = j.svg(n), m = V(t, {}), y = ft(d), C = g.path(y, m);
    f = n.insert(() => C, ":first-child").attr("transform", `translate(${-h / 2}, ${c / 2})`), u && f.attr("style", u);
  } else
    f = Ye(n, h, c, d);
  return i && f.attr("style", i), t.width = h, t.height = c, K(t, f), t.intersect = function(g) {
    return G.polygon(t, d, g);
  }, n;
}
p(Yp, "lean_right");
function Up(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.label = "", t.labelStyle = r;
  const s = e.insert("g").attr("class", et(t)).attr("id", t.domId ?? t.id), { cssStyles: o } = t, a = Math.max(35, t?.width ?? 0), n = Math.max(35, t?.height ?? 0), l = 7, c = [
    { x: a, y: 0 },
    { x: 0, y: n + l / 2 },
    { x: a - 2 * l, y: n + l / 2 },
    { x: 0, y: 2 * n },
    { x: a, y: n - l / 2 },
    { x: 2 * l, y: n - l / 2 }
  ], h = j.svg(s), d = V(t, {});
  t.look !== "handDrawn" && (d.roughness = 0, d.fillStyle = "solid");
  const f = ft(c), u = h.path(f, d), g = s.insert(() => u, ":first-child");
  return g.attr("class", "outer-path"), o && t.look !== "handDrawn" && g.selectAll("path").attr("style", o), i && t.look !== "handDrawn" && g.selectAll("path").attr("style", i), g.attr("transform", `translate(-${a / 2},${-n})`), K(t, g), t.intersect = function(m) {
    return P.info("lightningBolt intersect", t, m), G.polygon(t, c, m);
  }, s;
}
p(Up, "lightningBolt");
var eT = /* @__PURE__ */ p((e, t, r, i, s, o, a) => [
  `M${e},${t + o}`,
  `a${s},${o} 0,0,0 ${r},0`,
  `a${s},${o} 0,0,0 ${-r},0`,
  `l0,${i}`,
  `a${s},${o} 0,0,0 ${r},0`,
  `l0,${-i}`,
  `M${e},${t + o + a}`,
  `a${s},${o} 0,0,0 ${r},0`
].join(" "), "createCylinderPathD"), rT = /* @__PURE__ */ p((e, t, r, i, s, o, a) => [
  `M${e},${t + o}`,
  `M${e + r},${t + o}`,
  `a${s},${o} 0,0,0 ${-r},0`,
  `l0,${i}`,
  `a${s},${o} 0,0,0 ${r},0`,
  `l0,${-i}`,
  `M${e},${t + o + a}`,
  `a${s},${o} 0,0,0 ${r},0`
].join(" "), "createOuterCylinderPathD"), iT = /* @__PURE__ */ p((e, t, r, i, s, o) => [`M${e - r / 2},${-i / 2}`, `a${s},${o} 0,0,0 ${r},0`].join(" "), "createInnerCylinderPathD"), jh = 10, Xh = 10;
async function Gp(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 16 : s, a = t.look === "neo" ? 24 : s;
  if (t.width || t.height) {
    const C = t.width ?? 0;
    t.width = (t.width ?? 0) - o, t.width < Xh && (t.width = Xh);
    const k = C / 2 / (2.5 + C / 50);
    t.height = (t.height ?? 0) - a - k * 3, t.height < jh && (t.height = jh);
  }
  const { shapeSvg: n, bbox: l, label: c } = await rt(e, t, et(t)), h = (t?.width ? t?.width : l.width) + o * 2, d = h / 2, f = d / (2.5 + h / 50), u = (t?.height ? t?.height : l.height) + f + a * 2, g = u * 0.1;
  let m;
  const { cssStyles: y } = t;
  if (t.look === "handDrawn") {
    const C = j.svg(n), b = rT(0, 0, h, u, d, f, g), k = iT(0, f, h, u, d, f), T = V(t, {}), S = C.path(b, T), _ = C.path(k, T);
    n.insert(() => _, ":first-child").attr("class", "line"), m = n.insert(() => S, ":first-child"), m.attr("class", "basic label-container"), y && m.attr("style", y);
  } else {
    const C = eT(0, 0, h, u, d, f, g);
    m = n.insert("path", ":first-child").attr("d", C).attr("class", "basic label-container outer-path").attr("style", Dt(y)).attr("style", i);
  }
  return m.attr("label-offset-y", f), m.attr("transform", `translate(${-h / 2}, ${-(u / 2 + f)})`), K(t, m), c.attr(
    "transform",
    `translate(${-(l.width / 2) - (l.x - (l.left ?? 0))}, ${-(l.height / 2) + f - (l.y - (l.top ?? 0))})`
  ), t.intersect = function(C) {
    const b = G.rect(t, C), k = b.x - (t.x ?? 0);
    if (d != 0 && (Math.abs(k) < (t.width ?? 0) / 2 || Math.abs(k) == (t.width ?? 0) / 2 && Math.abs(b.y - (t.y ?? 0)) > (t.height ?? 0) / 2 - f)) {
      let T = f * f * (1 - k * k / (d * d));
      T > 0 && (T = Math.sqrt(T)), T = f - T, C.y - (t.y ?? 0) > 0 && (T = -T), b.y += T;
    }
    return b;
  }, n;
}
p(Gp, "linedCylinder");
async function jp(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 16 : s, a = t.look === "neo" ? 12 : s;
  if (t.width || t.height) {
    const T = t.width;
    t.width = (T ?? 0) * 10 / 11 - o * 2, t.width < 10 && (t.width = 10), t.height = (t?.height ?? 0) - a * 2, t.height < 10 && (t.height = 10);
  }
  const { shapeSvg: n, bbox: l, label: c } = await rt(e, t, et(t)), h = (t?.width ? t?.width : l.width) + (o ?? 0) * 2, d = (t?.height ? t?.height : l.height) + (a ?? 0) * 2, f = t.look === "neo" ? d / 4 : d / 8, u = d + f, { cssStyles: g } = t, m = j.svg(n), y = V(t, {});
  t.look !== "handDrawn" && (y.roughness = 0, y.fillStyle = "solid");
  const C = [
    { x: -h / 2 - h / 2 * 0.1, y: -u / 2 },
    { x: -h / 2 - h / 2 * 0.1, y: u / 2 },
    ...rr(
      -h / 2 - h / 2 * 0.1,
      u / 2,
      h / 2 + h / 2 * 0.1,
      u / 2,
      f,
      0.8
    ),
    { x: h / 2 + h / 2 * 0.1, y: -u / 2 },
    { x: -h / 2 - h / 2 * 0.1, y: -u / 2 },
    { x: -h / 2, y: -u / 2 },
    { x: -h / 2, y: u / 2 * 1.1 },
    { x: -h / 2, y: -u / 2 }
  ], b = m.polygon(
    C.map((T) => [T.x, T.y]),
    y
  ), k = n.insert(() => b, ":first-child");
  return k.attr("class", "basic label-container outer-path"), g && t.look !== "handDrawn" && k.selectAll("path").attr("style", g), i && t.look !== "handDrawn" && k.selectAll("path").attr("style", i), k.attr("transform", `translate(0,${-f / 2})`), c.attr(
    "transform",
    `translate(${-h / 2 + (t.padding ?? 0) + h / 2 * 0.1 / 2 - (l.x - (l.left ?? 0))},${-d / 2 + (t.padding ?? 0) - f / 2 - (l.y - (l.top ?? 0))})`
  ), K(t, k), t.intersect = function(T) {
    return G.polygon(t, C, T);
  }, n;
}
p(jp, "linedWaveEdgedRect");
async function Xp(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 16 : s, a = t.look === "neo" ? 12 : s, n = t.look === "neo" ? 10 : 5;
  (t.width || t.height) && (t.width = Math.max((t?.width ?? 0) - o * 2 - 2 * n, 10), t.height = Math.max((t?.height ?? 0) - a * 2 - 2 * n, 10));
  const { shapeSvg: l, bbox: c, label: h } = await rt(e, t, et(t)), d = (t?.width ? t?.width : c.width) + o * 2 + 2 * n, f = (t?.height ? t?.height : c.height) + a * 2 + 2 * n, u = d - 2 * n, g = f - 2 * n, m = -u / 2, y = -g / 2, { cssStyles: C } = t, b = j.svg(l), k = V(t, {}), T = [
    { x: m - n, y: y + n },
    { x: m - n, y: y + g + n },
    { x: m + u - n, y: y + g + n },
    { x: m + u - n, y: y + g },
    { x: m + u, y: y + g },
    { x: m + u, y: y + g - n },
    { x: m + u + n, y: y + g - n },
    { x: m + u + n, y: y - n },
    { x: m + n, y: y - n },
    { x: m + n, y },
    { x: m, y },
    { x: m, y: y + n }
  ], S = [
    { x: m, y: y + n },
    { x: m + u - n, y: y + n },
    { x: m + u - n, y: y + g },
    { x: m + u, y: y + g },
    { x: m + u, y },
    { x: m, y }
  ];
  t.look !== "handDrawn" && (k.roughness = 0, k.fillStyle = "solid");
  const _ = ft(T);
  let A = b.path(_, k);
  const v = ft(S);
  let q = b.path(v, k);
  t.look !== "handDrawn" && (A = Va(A), q = Va(q));
  const I = l.insert("g", ":first-child");
  return I.insert(() => A), I.insert(() => q), I.attr("class", "basic label-container outer-path"), C && t.look !== "handDrawn" && I.selectAll("path").attr("style", C), i && t.look !== "handDrawn" && I.selectAll("path").attr("style", i), h.attr(
    "transform",
    `translate(${-(c.width / 2) - n - (c.x - (c.left ?? 0))}, ${-(c.height / 2) + n - (c.y - (c.top ?? 0))})`
  ), K(t, I), t.intersect = function(R) {
    return G.polygon(t, T, R);
  }, l;
}
p(Xp, "multiRect");
async function Vp(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const { shapeSvg: s, bbox: o, label: a } = await rt(e, t, et(t)), n = t.padding ?? 0, l = t.look === "neo" ? 16 : n, c = t.look === "neo" ? 12 : n;
  let h = !0;
  (t.width || t.height) && (h = !1, t.width = (t?.width ?? 0) - l * 2, t.height = (t?.height ?? 0) - c * 3);
  const d = Math.max(o.width, t?.width ?? 0) + l * 2, f = Math.max(o.height, t?.height ?? 0) + c * 3, u = t.look === "neo" ? f / 4 : f / 8, g = f + (h ? u / 2 : -u / 2), m = -d / 2, y = -g / 2, C = 10, { cssStyles: b } = t, k = rr(
    m - C,
    y + g + C,
    m + d - C,
    y + g + C,
    u,
    0.8
  ), T = k?.[k.length - 1], S = [
    { x: m - C, y: y + C },
    { x: m - C, y: y + g + C },
    ...k,
    { x: m + d - C, y: T.y - C },
    { x: m + d, y: T.y - C },
    { x: m + d, y: T.y - 2 * C },
    { x: m + d + C, y: T.y - 2 * C },
    { x: m + d + C, y: y - C },
    { x: m + C, y: y - C },
    { x: m + C, y },
    { x: m, y },
    { x: m, y: y + C }
  ], _ = [
    { x: m, y: y + C },
    { x: m + d - C, y: y + C },
    { x: m + d - C, y: T.y - C },
    { x: m + d, y: T.y - C },
    { x: m + d, y },
    { x: m, y }
  ], A = j.svg(s), v = V(t, {});
  t.look !== "handDrawn" && (v.roughness = 0, v.fillStyle = "solid");
  const q = ft(S), I = A.path(q, v), R = ft(_), H = A.path(R, v), W = s.insert(() => I, ":first-child");
  return W.insert(() => H), W.attr("class", "basic label-container outer-path"), b && t.look !== "handDrawn" && W.selectAll("path").attr("style", b), i && t.look !== "handDrawn" && W.selectAll("path").attr("style", i), W.attr("transform", `translate(0,${-u / 2})`), a.attr(
    "transform",
    `translate(${-(o.width / 2) - C - (o.x - (o.left ?? 0))}, ${-(o.height / 2) + C - u / 2 - (o.y - (o.top ?? 0))})`
  ), K(t, W), t.intersect = function(M) {
    return G.polygon(t, S, M);
  }, s;
}
p(Vp, "multiWaveEdgedRectangle");
async function Zp(e, t, { config: { themeVariables: r } }) {
  const { labelStyles: i, nodeStyles: s } = Z(t);
  t.labelStyle = i, t.useHtmlLabels || Vt(Tt()) || (t.centerLabel = !0);
  const { shapeSvg: a, bbox: n, label: l } = await rt(e, t, et(t)), c = Math.max(n.width + (t.padding ?? 0) * 2, t?.width ?? 0), h = Math.max(n.height + (t.padding ?? 0) * 2, t?.height ?? 0), d = -c / 2, f = -h / 2, { cssStyles: u } = t, g = j.svg(a), m = V(t, {
    fill: r.noteBkgColor,
    stroke: r.noteBorderColor
  });
  t.look !== "handDrawn" && (m.roughness = 0, m.fillStyle = "solid");
  const y = g.rectangle(d, f, c, h, m), C = a.insert(() => y, ":first-child");
  return C.attr("class", "basic label-container outer-path"), l.attr("class", "label noteLabel"), u && t.look !== "handDrawn" && C.selectAll("path").attr("style", u), s && t.look !== "handDrawn" && C.selectAll("path").attr("style", s), l.attr(
    "transform",
    `translate(${-n.width / 2 - (n.x - (n.left ?? 0))}, ${-(n.height / 2) - (n.y - (n.top ?? 0))})`
  ), K(t, C), t.intersect = function(b) {
    return G.rect(t, b);
  }, a;
}
p(Zp, "note");
var sT = /* @__PURE__ */ p((e, t, r) => [
  `M${e + r / 2},${t}`,
  `L${e + r},${t - r / 2}`,
  `L${e + r / 2},${t - r}`,
  `L${e},${t - r / 2}`,
  "Z"
].join(" "), "createDecisionBoxPathD");
async function Kp(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const { shapeSvg: s, bbox: o } = await rt(e, t, et(t)), a = o.width + (t.padding ?? 0), n = o.height + (t.padding ?? 0), l = a + n, c = 0.5, h = [
    { x: l / 2, y: 0 },
    { x: l, y: -l / 2 },
    { x: l / 2, y: -l },
    { x: 0, y: -l / 2 }
  ];
  let d;
  const { cssStyles: f } = t;
  if (t.look === "handDrawn") {
    const u = j.svg(s), g = V(t, {}), m = sT(0, 0, l), y = u.path(m, g);
    d = s.insert(() => y, ":first-child").attr("transform", `translate(${-l / 2 + c}, ${l / 2})`), f && d.attr("style", f);
  } else
    d = Ye(s, l, l, h), d.attr("transform", `translate(${-l / 2 + c}, ${l / 2})`);
  return i && d.attr("style", i), K(t, d), t.calcIntersect = function(u, g) {
    const m = u.width, y = [
      { x: m / 2, y: 0 },
      { x: m, y: -m / 2 },
      { x: m / 2, y: -m },
      { x: 0, y: -m / 2 }
    ], C = G.polygon(u, y, g);
    return { x: C.x - 0.5, y: C.y - 0.5 };
  }, t.intersect = function(u) {
    return this.calcIntersect(t, u);
  }, s;
}
p(Kp, "question");
async function Qp(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 21 : s ?? 0, a = t.look === "neo" ? 12 : s ?? 0, { shapeSvg: n, bbox: l, label: c } = await rt(e, t, et(t)), h = (t?.width ?? l.width) + (t.look === "neo" ? o * 2 : o), d = (t?.height ?? l.height) + (t.look === "neo" ? a * 2 : a), f = -h / 2, u = -d / 2, g = u / 2, m = [
    { x: f + g, y: u },
    { x: f, y: 0 },
    { x: f + g, y: -u },
    { x: -f, y: -u },
    { x: -f, y: u }
  ], { cssStyles: y } = t, C = j.svg(n), b = V(t, {});
  t.look !== "handDrawn" && (b.roughness = 0, b.fillStyle = "solid");
  const k = ft(m), T = C.path(k, b), S = n.insert(() => T, ":first-child");
  return S.attr("class", "basic label-container outer-path"), y && t.look !== "handDrawn" && S.selectAll("path").attr("style", y), i && t.look !== "handDrawn" && S.selectAll("path").attr("style", i), S.attr("transform", `translate(${-g / 2},0)`), c.attr(
    "transform",
    `translate(${-g / 2 - l.width / 2 - (l.x - (l.left ?? 0))}, ${-(l.height / 2) - (l.y - (l.top ?? 0))})`
  ), K(t, S), t.intersect = function(_) {
    return G.polygon(t, m, _);
  }, n;
}
p(Qp, "rect_left_inv_arrow");
async function Jp(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  let s;
  t.cssClasses ? s = "node " + t.cssClasses : s = "node default";
  const o = e.insert("g").attr("class", s).attr("id", t.domId || t.id), a = o.insert("g"), n = o.insert("g").attr("class", "label").attr("style", i), l = t.description, c = t.label, h = await Ve(n, c, t.labelStyle, !0, !0);
  let d = { width: 0, height: 0 };
  if (Vt(gt())) {
    const v = h.children[0], q = ht(h);
    d = v.getBoundingClientRect(), q.attr("width", d.width), q.attr("height", d.height);
  }
  P.info("Text 2", l);
  const f = l || [], u = h.getBBox(), g = await Ve(
    n,
    Array.isArray(f) ? f.join("<br/>") : f,
    t.labelStyle,
    !0,
    !0
  ), m = g.children[0], y = ht(g);
  d = m.getBoundingClientRect(), y.attr("width", d.width), y.attr("height", d.height);
  const C = (t.padding || 0) / 2;
  ht(g).attr(
    "transform",
    "translate( " + (d.width > u.width ? 0 : (u.width - d.width) / 2) + ", " + (u.height + C + 5) + ")"
  ), ht(h).attr(
    "transform",
    "translate( " + (d.width < u.width ? 0 : -(u.width - d.width) / 2) + ", 0)"
  ), d = n.node().getBBox(), n.attr(
    "transform",
    "translate(" + -d.width / 2 + ", " + (-d.height / 2 - C + 3) + ")"
  );
  const b = d.width + (t.padding || 0), k = d.height + (t.padding || 0), T = -d.width / 2 - C, S = -d.height / 2 - C;
  let _, A;
  if (t.look === "handDrawn") {
    const v = j.svg(o), q = V(t, {}), I = v.path(
      ir(T, S, b, k, t.rx || 0),
      q
    ), R = v.line(
      -d.width / 2 - C,
      -d.height / 2 - C + u.height + C,
      d.width / 2 + C,
      -d.height / 2 - C + u.height + C,
      q
    );
    A = o.insert(() => (P.debug("Rough node insert CXC", I), R), ":first-child"), _ = o.insert(() => (P.debug("Rough node insert CXC", I), I), ":first-child");
  } else
    _ = a.insert("rect", ":first-child"), A = a.insert("line"), _.attr("class", "outer title-state").attr("style", i).attr("x", -d.width / 2 - C).attr("y", -d.height / 2 - C).attr("width", d.width + (t.padding || 0)).attr("height", d.height + (t.padding || 0)), A.attr("class", "divider").attr("x1", -d.width / 2 - C).attr("x2", d.width / 2 + C).attr("y1", -d.height / 2 - C + u.height + C).attr("y2", -d.height / 2 - C + u.height + C);
  return K(t, _), t.intersect = function(v) {
    return G.rect(t, v);
  }, o;
}
p(Jp, "rectWithTitle");
async function tg(e, t, { config: { themeVariables: r } }) {
  const i = r?.radius ?? 5, s = {
    rx: i,
    ry: i,
    labelPaddingX: (t?.padding ?? 0) * 1,
    labelPaddingY: (t?.padding ?? 0) * 1
  };
  return ei(e, t, s);
}
p(tg, "roundedRect");
var nr = 8;
async function eg(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const s = t.look === "neo" ? 16 : t.padding ?? 0, o = t.look === "neo" ? 12 : t.padding ?? 0, { shapeSvg: a, bbox: n, label: l } = await rt(e, t, et(t)), c = (t?.width ?? n.width) + s * 2 + (t.look === "neo" ? nr : nr * 2), h = (t?.height ?? n.height) + o * 2, d = c - nr, f = h, u = nr - c / 2, g = -h / 2, { cssStyles: m } = t, y = j.svg(a), C = V(t, {});
  t.look !== "handDrawn" && (C.roughness = 0, C.fillStyle = "solid");
  const b = [
    { x: u, y: g },
    { x: u + d, y: g },
    { x: u + d, y: g + f },
    { x: u - nr, y: g + f },
    { x: u - nr, y: g },
    { x: u, y: g },
    { x: u, y: g + f }
  ], k = y.polygon(
    b.map((S) => [S.x, S.y]),
    C
  ), T = a.insert(() => k, ":first-child");
  return T.attr("class", "basic label-container outer-path").attr("style", Dt(m)), i && t.look !== "handDrawn" && T.selectAll("path").attr("style", i), m && t.look !== "handDrawn" && T.selectAll("path").attr("style", i), l.attr(
    "transform",
    `translate(${nr / 2 - n.width / 2 - (n.x - (n.left ?? 0))}, ${-(n.height / 2) - (n.y - (n.top ?? 0))})`
  ), K(t, T), t.intersect = function(S) {
    return G.rect(t, S);
  }, a;
}
p(eg, "shadedProcess");
async function rg(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 16 : s, a = t.look === "neo" ? 12 : s;
  (t.width || t.height) && (t.width = Math.max((t?.width ?? 0) - o * 2, 10), t.height = Math.max((t?.height ?? 0) / 1.5 - a * 2, 10));
  const { shapeSvg: n, bbox: l, label: c } = await rt(e, t, et(t)), h = (t?.width ? t?.width : l.width) + o * 2, d = ((t?.height ? t?.height : l.height) + a * 2) * 1.5, f = h, u = d / 1.5, g = -f / 2, m = -u / 2, { cssStyles: y } = t, C = j.svg(n), b = V(t, {});
  t.look !== "handDrawn" && (b.roughness = 0, b.fillStyle = "solid");
  const k = [
    { x: g, y: m },
    { x: g, y: m + u },
    { x: g + f, y: m + u },
    { x: g + f, y: m - u / 2 }
  ], T = ft(k), S = C.path(T, b), _ = n.insert(() => S, ":first-child");
  return _.attr("class", "basic label-container  outer-path"), y && t.look !== "handDrawn" && _.selectChildren("path").attr("style", y), i && t.look !== "handDrawn" && _.selectChildren("path").attr("style", i), _.attr("transform", `translate(0, ${u / 4})`), c.attr(
    "transform",
    `translate(${-f / 2 + (t.padding ?? 0) - (l.x - (l.left ?? 0))}, ${-u / 4 + (t.padding ?? 0) - (l.y - (l.top ?? 0))})`
  ), K(t, _), t.intersect = function(A) {
    return G.polygon(t, k, A);
  }, n;
}
p(rg, "slopedRect");
async function ig(e, t) {
  const r = t.padding ?? 0, i = t.look === "neo" ? 16 : r * 2, s = t.look === "neo" ? 12 : r, o = {
    rx: 0,
    ry: 0,
    labelPaddingX: t.labelPaddingX ?? i,
    labelPaddingY: s
  };
  return ei(e, t, o);
}
p(ig, "squareRect");
async function sg(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 20 : s, a = t.look === "neo" ? 12 : s, { shapeSvg: n, bbox: l } = await rt(e, t, et(t)), c = l.height + (t.look === "neo" ? a * 2 : a), h = l.width + c / 4 + (t.look === "neo" ? o * 2 : o), d = c / 2, { cssStyles: f } = t, u = j.svg(n), g = V(t, {});
  t.look !== "handDrawn" && (g.roughness = 0, g.fillStyle = "solid");
  const m = [
    { x: -h / 2 + d, y: -c / 2 },
    { x: h / 2 - d, y: -c / 2 },
    ...Pi(-h / 2 + d, 0, d, 50, 90, 270),
    { x: h / 2 - d, y: c / 2 },
    ...Pi(h / 2 - d, 0, d, 50, 270, 450)
  ], y = ft(m), C = u.path(y, g), b = n.insert(() => C, ":first-child");
  return b.attr("class", "basic label-container outer-path"), f && t.look !== "handDrawn" && b.selectChildren("path").attr("style", f), i && t.look !== "handDrawn" && b.selectChildren("path").attr("style", i), K(t, b), t.intersect = function(k) {
    return G.polygon(t, m, k);
  }, n;
}
p(sg, "stadium");
async function og(e, t) {
  const r = {
    rx: t.look === "neo" ? 3 : 5,
    ry: t.look === "neo" ? 3 : 5
  };
  return ei(e, t, r);
}
p(og, "state");
function ag(e, t, { config: { themeVariables: r } }) {
  const { labelStyles: i, nodeStyles: s } = Z(t);
  t.labelStyle = i;
  const { cssStyles: o } = t, { lineColor: a, stateBorder: n, nodeBorder: l, nodeShadow: c } = r;
  (t.width || t.height) && ((t.width ?? 0) < 14 && (t.width = 14), (t.height ?? 0) < 14 && (t.height = 14)), t.width || (t.width = 14), t.height || (t.height = 14);
  const h = e.insert("g").attr("class", "node default").attr("id", t.domId ?? t.id), d = j.svg(h), f = V(t, {});
  t.look !== "handDrawn" && (f.roughness = 0, f.fillStyle = "solid");
  const u = d.circle(0, 0, t.width, {
    ...f,
    stroke: a,
    strokeWidth: 2
  }), g = n ?? l, m = (t.width ?? 0) * 5 / 14, y = d.circle(0, 0, m, {
    ...f,
    fill: g,
    stroke: g,
    strokeWidth: 2,
    fillStyle: "solid"
  }), C = h.insert(() => u, ":first-child");
  if (C.insert(() => y), t.look !== "handDrawn" && C.attr("class", "outer-path"), o && C.selectAll("path").attr("style", o), s && C.selectAll("path").attr("style", s), t.width < 25 && c && t.look !== "handDrawn") {
    const b = e.node()?.ownerSVGElement?.id ?? "", k = b ? `${b}-drop-shadow-small` : "drop-shadow-small";
    C.attr("style", `filter:url(#${k})`);
  }
  return K(t, C), t.intersect = function(b) {
    return G.circle(t, (t.width ?? 0) / 2, b);
  }, h;
}
p(ag, "stateEnd");
function ng(e, t, { config: { themeVariables: r } }) {
  const { lineColor: i, nodeShadow: s } = r;
  (t.width || t.height) && ((t.width ?? 0) < 14 && (t.width = 14), (t.height ?? 0) < 14 && (t.height = 14)), t.width || (t.width = 14), t.height || (t.height = 14);
  const o = e.insert("g").attr("class", "node default").attr("id", t.domId || t.id);
  let a;
  if (t.look === "handDrawn") {
    const l = j.svg(o).circle(0, 0, t.width, f2(i));
    a = o.insert(() => l), a.attr("class", "state-start").attr("r", (t.width ?? 7) / 2).attr("width", t.width ?? 14).attr("height", t.height ?? 14);
  } else
    a = o.insert("circle", ":first-child"), a.attr("class", "state-start").attr("r", (t.width ?? 7) / 2).attr("width", t.width ?? 14).attr("height", t.height ?? 14);
  if (t.width < 25 && s && t.look !== "handDrawn") {
    const n = e.node()?.ownerSVGElement?.id ?? "", l = n ? `${n}-drop-shadow-small` : "drop-shadow-small";
    a.attr("style", `filter:url(#${l})`);
  }
  return K(t, a), t.intersect = function(n) {
    return G.circle(t, (t.width ?? 7) / 2, n);
  }, o;
}
p(ng, "stateStart");
var Ir = 8;
async function lg(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const s = t?.padding ?? 8, o = t.look === "neo" ? 28 : s, a = t.look === "neo" ? 12 : s, { shapeSvg: n, bbox: l } = await rt(e, t, et(t)), c = (t?.width ?? l.width) + 2 * Ir + o, h = (t?.height ?? l.height) + a, d = c - 2 * Ir, f = h, u = -c / 2, g = -h / 2, m = [
    { x: 0, y: 0 },
    { x: d, y: 0 },
    { x: d, y: -f },
    { x: 0, y: -f },
    { x: 0, y: 0 },
    { x: -8, y: 0 },
    { x: d + 8, y: 0 },
    { x: d + 8, y: -f },
    { x: -8, y: -f },
    { x: -8, y: 0 }
  ];
  if (t.look === "handDrawn") {
    const y = j.svg(n), C = V(t, {}), b = y.rectangle(u, g, d + 16, f, C), k = y.line(u + Ir, g, u + Ir, g + f, C), T = y.line(u + Ir + d, g, u + Ir + d, g + f, C);
    n.insert(() => k, ":first-child"), n.insert(() => T, ":first-child");
    const S = n.insert(() => b, ":first-child"), { cssStyles: _ } = t;
    S.attr("class", "basic label-container").attr("style", Dt(_)), K(t, S);
  } else {
    const y = Ye(n, d, f, m);
    i && y.attr("style", i), K(t, y);
  }
  return t.intersect = function(y) {
    return G.polygon(t, m, y);
  }, n;
}
p(lg, "subroutine");
var ra = 0.2;
async function hg(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 16 : s, a = t.look === "neo" ? 12 : s;
  (t.width || t.height) && (t.height = Math.max((t?.height ?? 0) - a * 2, 10), t.width = Math.max(
    (t?.width ?? 0) - o * 2 - ra * (t.height + a * 2),
    10
  ));
  const { shapeSvg: n, bbox: l } = await rt(e, t, et(t)), c = (t?.height ? t?.height : l.height) + a * 2, h = ra * c, d = ra * c, u = (t?.width ? t?.width : l.width) + o * 2 + h - h, g = c, m = -u / 2, y = -g / 2, { cssStyles: C } = t, b = j.svg(n), k = V(t, {}), T = [
    { x: m - h / 2, y },
    { x: m + u + h / 2, y },
    { x: m + u + h / 2, y: y + g },
    { x: m - h / 2, y: y + g }
  ], S = [
    { x: m + u - h / 2, y: y + g },
    { x: m + u + h / 2, y: y + g },
    { x: m + u + h / 2, y: y + g - d }
  ];
  t.look !== "handDrawn" && (k.roughness = 0, k.fillStyle = "solid");
  const _ = ft(T), A = b.path(_, k), v = ft(S), q = b.path(v, { ...k, fillStyle: "solid" }), I = n.insert(() => q, ":first-child");
  return I.insert(() => A, ":first-child"), I.attr("class", "basic label-container outer-path"), C && t.look !== "handDrawn" && I.selectAll("path").attr("style", C), i && t.look !== "handDrawn" && I.selectAll("path").attr("style", i), K(t, I), t.intersect = function(R) {
    return G.polygon(t, T, R);
  }, n;
}
p(hg, "taggedRect");
async function cg(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const { shapeSvg: s, bbox: o, label: a } = await rt(e, t, et(t)), n = Math.max(o.width + (t.padding ?? 0) * 2, t?.width ?? 0), l = Math.max(o.height + (t.padding ?? 0) * 2, t?.height ?? 0), c = l / 8, h = 0.2 * n, d = 0.2 * l, f = l + c, { cssStyles: u } = t, g = j.svg(s), m = V(t, {});
  t.look !== "handDrawn" && (m.roughness = 0, m.fillStyle = "solid");
  const y = [
    { x: -n / 2 - n / 2 * 0.1, y: f / 2 },
    ...rr(
      -n / 2 - n / 2 * 0.1,
      f / 2,
      n / 2 + n / 2 * 0.1,
      f / 2,
      c,
      0.8
    ),
    { x: n / 2 + n / 2 * 0.1, y: -f / 2 },
    { x: -n / 2 - n / 2 * 0.1, y: -f / 2 }
  ], C = -n / 2 + n / 2 * 0.1, b = -f / 2 - d * 0.4, k = [
    { x: C + n - h, y: (b + l) * 1.3 },
    { x: C + n, y: b + l - d },
    { x: C + n, y: (b + l) * 0.9 },
    ...rr(
      C + n,
      (b + l) * 1.25,
      C + n - h,
      (b + l) * 1.3,
      -l * 0.02,
      0.5
    )
  ], T = ft(y), S = g.path(T, m), _ = ft(k), A = g.path(_, {
    ...m,
    fillStyle: "solid"
  }), v = s.insert(() => A, ":first-child");
  return v.insert(() => S, ":first-child"), v.attr("class", "basic label-container outer-path"), u && t.look !== "handDrawn" && v.selectAll("path").attr("style", u), i && t.look !== "handDrawn" && v.selectAll("path").attr("style", i), v.attr("transform", `translate(0,${-c / 2})`), a.attr(
    "transform",
    `translate(${-n / 2 + (t.padding ?? 0) - (o.x - (o.left ?? 0))},${-l / 2 + (t.padding ?? 0) - c / 2 - (o.y - (o.top ?? 0))})`
  ), K(t, v), t.intersect = function(q) {
    return G.polygon(t, y, q);
  }, s;
}
p(cg, "taggedWaveEdgedRectangle");
async function dg(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const { shapeSvg: s, bbox: o } = await rt(e, t, et(t)), a = Math.max(o.width + (t.padding ?? 0), t?.width || 0), n = Math.max(o.height + (t.padding ?? 0), t?.height || 0), l = -a / 2, c = -n / 2, h = s.insert("rect", ":first-child");
  return h.attr("class", "text").attr("style", i).attr("rx", 0).attr("ry", 0).attr("x", l).attr("y", c).attr("width", a).attr("height", n), K(t, h), t.intersect = function(d) {
    return G.rect(t, d);
  }, s;
}
p(dg, "text");
var oT = /* @__PURE__ */ p((e, t, r, i, s, o) => `M${e},${t}
    a${s},${o} 0,0,1 0,${-i}
    l${r},0
    a${s},${o} 0,0,1 0,${i}
    M${r},${-i}
    a${s},${o} 0,0,0 0,${i}
    l${-r},0`, "createCylinderPathD"), aT = /* @__PURE__ */ p((e, t, r, i, s, o) => [
  `M${e},${t}`,
  `M${e + r},${t}`,
  `a${s},${o} 0,0,0 0,${-i}`,
  `l${-r},0`,
  `a${s},${o} 0,0,0 0,${i}`,
  `l${r},0`
].join(" "), "createOuterCylinderPathD"), nT = /* @__PURE__ */ p((e, t, r, i, s, o) => [`M${e + r / 2},${-i / 2}`, `a${s},${o} 0,0,0 0,${i}`].join(" "), "createInnerCylinderPathD"), Vh = 5, Zh = 10;
async function ug(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 12 : s / 2;
  if (t.width || t.height) {
    const m = t.height ?? 0;
    t.height = (t.height ?? 0) - o, t.height < Vh && (t.height = Vh);
    const C = m / 2 / (2.5 + m / 50);
    t.width = (t.width ?? 0) - o - C * 3, t.width < Zh && (t.width = Zh);
  }
  const { shapeSvg: a, bbox: n, label: l } = await rt(e, t, et(t)), c = (t.height ? t.height : n.height) + o, h = c / 2, d = h / (2.5 + c / 50), f = (t.width ? t.width : n.width) + d + o, { cssStyles: u } = t;
  let g;
  if (t.look === "handDrawn") {
    const m = j.svg(a), y = aT(0, 0, f, c, d, h), C = nT(0, 0, f, c, d, h), b = m.path(y, V(t, {})), k = m.path(C, V(t, { fill: "none" }));
    g = a.insert(() => k, ":first-child"), g = a.insert(() => b, ":first-child"), g.attr("class", "basic label-container"), u && g.attr("style", u);
  } else {
    const m = oT(0, 0, f, c, d, h);
    g = a.insert("path", ":first-child").attr("d", m).attr("class", "basic label-container").attr("style", Dt(u)).attr("style", i), g.attr("class", "basic label-container outer-path"), u && g.selectAll("path").attr("style", u), i && g.selectAll("path").attr("style", i);
  }
  return g.attr("label-offset-x", d), g.attr("transform", `translate(${-f / 2}, ${c / 2} )`), l.attr(
    "transform",
    `translate(${-(n.width / 2) - d - (n.x - (n.left ?? 0))}, ${-(n.height / 2) - (n.y - (n.top ?? 0))})`
  ), K(t, g), t.intersect = function(m) {
    const y = G.rect(t, m), C = y.y - (t.y ?? 0);
    if (h != 0 && (Math.abs(C) < (t.height ?? 0) / 2 || Math.abs(C) == (t.height ?? 0) / 2 && Math.abs(y.x - (t.x ?? 0)) > (t.width ?? 0) / 2 - d)) {
      let b = d * d * (1 - C * C / (h * h));
      b != 0 && (b = Math.sqrt(Math.abs(b))), b = d - b, m.x - (t.x ?? 0) > 0 && (b = -b), y.x += b;
    }
    return y;
  }, a;
}
p(ug, "tiltedCylinder");
async function fg(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = (t.look === "neo", s), a = t.look === "neo" ? s * 2 : s, { shapeSvg: n, bbox: l } = await rt(e, t, et(t)), c = (t?.height ?? l.height) + o, h = (t?.width ?? l.width) + a, d = [
    { x: -3 * c / 6, y: 0 },
    { x: h + 3 * c / 6, y: 0 },
    { x: h, y: -c },
    { x: 0, y: -c }
  ];
  let f;
  const { cssStyles: u } = t;
  if (t.look === "handDrawn") {
    const g = j.svg(n), m = V(t, {}), y = ft(d), C = g.path(y, m);
    f = n.insert(() => C, ":first-child").attr("transform", `translate(${-h / 2}, ${c / 2})`), u && f.attr("style", u);
  } else
    f = Ye(n, h, c, d);
  return i && f.attr("style", i), t.width = h, t.height = c, K(t, f), t.intersect = function(g) {
    return G.polygon(t, d, g);
  }, n;
}
p(fg, "trapezoid");
async function pg(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 16 : s, a = t.look === "neo" ? 12 : s, n = 15, l = 5;
  (t.width || t.height) && (t.height = (t.height ?? 0) - a * 2, t.height < l && (t.height = l), t.width = (t.width ?? 0) - o * 2, t.width < n && (t.width = n));
  const { shapeSvg: c, bbox: h } = await rt(e, t, et(t)), d = (t?.width ? t?.width : h.width) + o * 2, f = (t?.height ? t?.height : h.height) + a * 2, { cssStyles: u } = t, g = j.svg(c), m = V(t, {});
  t.look !== "handDrawn" && (m.roughness = 0, m.fillStyle = "solid");
  const y = [
    { x: -d / 2 * 0.8, y: -f / 2 },
    { x: d / 2 * 0.8, y: -f / 2 },
    { x: d / 2, y: -f / 2 * 0.6 },
    { x: d / 2, y: f / 2 },
    { x: -d / 2, y: f / 2 },
    { x: -d / 2, y: -f / 2 * 0.6 }
  ], C = ft(y), b = g.path(C, m), k = c.insert(() => b, ":first-child");
  return k.attr("class", "basic label-container outer-path"), u && t.look !== "handDrawn" && k.selectChildren("path").attr("style", u), i && t.look !== "handDrawn" && k.selectChildren("path").attr("style", i), K(t, k), t.intersect = function(T) {
    return G.polygon(t, y, T);
  }, c;
}
p(pg, "trapezoidalPentagon");
var Kh = 10, Qh = 10;
async function gg(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? s * 2 : s;
  (t.width || t.height) && (t.width = ((t?.width ?? 0) - o) / 2, t.width < Qh && (t.width = Qh), t.height = t?.height ?? 0, t.height < Kh && (t.height = Kh));
  const { shapeSvg: a, bbox: n, label: l } = await rt(e, t, et(t)), c = ze(gt().flowchart?.htmlLabels), h = (t?.width ? t?.width : n.width) + o, d = t?.height ? t?.height : h + n.height, f = d, u = [
    { x: 0, y: 0 },
    { x: f, y: 0 },
    { x: f / 2, y: -d }
  ], { cssStyles: g } = t, m = j.svg(a), y = V(t, {});
  t.look !== "handDrawn" && (y.roughness = 0, y.fillStyle = "solid");
  const C = ft(u), b = m.path(C, y), k = a.insert(() => b, ":first-child").attr("transform", `translate(${-d / 2}, ${d / 2})`).attr("class", "outer-path");
  return g && t.look !== "handDrawn" && k.selectChildren("path").attr("style", g), i && t.look !== "handDrawn" && k.selectChildren("path").attr("style", i), t.width = h, t.height = d, K(t, k), l.attr(
    "transform",
    `translate(${-n.width / 2 - (n.x - (n.left ?? 0))}, ${d / 2 - (n.height + (t.padding ?? 0) / (c ? 2 : 1) - (n.y - (n.top ?? 0)))})`
  ), t.intersect = function(T) {
    return P.info("Triangle intersect", t, u, T), G.polygon(t, u, T);
  }, a;
}
p(gg, "triangle");
async function mg(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 16 : s, a = t.look === "neo" ? 12 : s;
  let n = !0;
  (t.width || t.height) && (n = !1, t.width = (t?.width ?? 0) - o * 2, t.width < 10 && (t.width = 10), t.height = (t?.height ?? 0) - a * 2, t.height < 10 && (t.height = 10));
  const { shapeSvg: l, bbox: c, label: h } = await rt(e, t, et(t)), d = (t?.width ? t?.width : c.width) + (o ?? 0) * 2, f = (t?.height ? t?.height : c.height) + (a ?? 0) * 2, u = t.look === "neo" ? f / 4 : f / 8, g = f + (n ? u : -u), { cssStyles: m } = t, C = 14 - d, b = C > 0 ? C / 2 : 0, k = j.svg(l), T = V(t, {});
  t.look !== "handDrawn" && (T.roughness = 0, T.fillStyle = "solid");
  const S = [
    { x: -d / 2 - b, y: g / 2 },
    ...rr(
      -d / 2 - b,
      g / 2,
      d / 2 + b,
      g / 2,
      u,
      0.8
    ),
    { x: d / 2 + b, y: -g / 2 },
    { x: -d / 2 - b, y: -g / 2 }
  ], _ = ft(S), A = k.path(_, T), v = l.insert(() => A, ":first-child");
  return v.attr("class", "basic label-container outer-path"), m && t.look !== "handDrawn" && v.selectAll("path").attr("style", m), i && t.look !== "handDrawn" && v.selectAll("path").attr("style", i), v.attr("transform", `translate(0,${-u / 2})`), h.attr(
    "transform",
    `translate(${-d / 2 + (t.padding ?? 0) - (c.x - (c.left ?? 0))},${-f / 2 + (t.padding ?? 0) - u - (c.y - (c.top ?? 0))})`
  ), K(t, v), t.intersect = function(q) {
    return G.polygon(t, S, q);
  }, l;
}
p(mg, "waveEdgedRectangle");
async function yg(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const s = t.padding ?? 0, o = t.look === "neo" ? 16 : s, a = t.look === "neo" ? 20 : s;
  if (t.width || t.height) {
    t.width = t?.width ?? 0, t.width < 20 && (t.width = 20), t.height = t?.height ?? 0, t.height < 10 && (t.height = 10);
    const T = Math.min(t.height * 0.2, t.height / 4);
    t.height = Math.ceil(t.height - a - T * (20 / 9)), t.width = t.width - o * 2;
  }
  const { shapeSvg: n, bbox: l } = await rt(e, t, et(t)), c = (t?.width ? t?.width : l.width) + o * 2, h = (t?.height ? t?.height : l.height) + a, d = h / 8, f = h + d * 2, { cssStyles: u } = t, g = j.svg(n), m = V(t, {});
  t.look !== "handDrawn" && (m.roughness = 0, m.fillStyle = "solid");
  const y = [
    { x: -c / 2, y: f / 2 },
    ...rr(-c / 2, f / 2, c / 2, f / 2, d, 1),
    { x: c / 2, y: -f / 2 },
    ...rr(c / 2, -f / 2, -c / 2, -f / 2, d, -1)
  ], C = ft(y), b = g.path(C, m), k = n.insert(() => b, ":first-child");
  return k.attr("class", "basic label-container"), u && t.look !== "handDrawn" && k.selectAll("path").attr("style", u), i && t.look !== "handDrawn" && k.selectAll("path").attr("style", i), K(t, k), t.intersect = function(T) {
    return G.polygon(t, y, T);
  }, n;
}
p(yg, "waveRectangle");
var St = 10;
async function Cg(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const s = t.look === "neo" ? 16 : t.padding ?? 0, o = t.look === "neo" ? 12 : t.padding ?? 0;
  (t.width || t.height) && (t.width = Math.max((t?.width ?? 0) - s * 2 - St, 10), t.height = Math.max((t?.height ?? 0) - o * 2 - St, 10));
  const { shapeSvg: a, bbox: n, label: l } = await rt(e, t, et(t)), c = (t?.width ? t?.width : n.width) + s * 2 + St, h = (t?.height ? t?.height : n.height) + o * 2 + St, d = c - St, f = h - St, u = -d / 2, g = -f / 2, { cssStyles: m } = t, y = j.svg(a), C = V(t, {}), b = [
    { x: u - St, y: g - St },
    { x: u - St, y: g + f },
    { x: u + d, y: g + f },
    { x: u + d, y: g - St }
  ], k = `M${u - St},${g - St} L${u + d},${g - St} L${u + d},${g + f} L${u - St},${g + f} L${u - St},${g - St}
                M${u - St},${g} L${u + d},${g}
                M${u},${g - St} L${u},${g + f}`;
  t.look !== "handDrawn" && (C.roughness = 0, C.fillStyle = "solid");
  const T = y.path(k, C), S = a.insert(() => T, ":first-child");
  return S.attr("transform", `translate(${St / 2}, ${St / 2})`), S.attr("class", "basic label-container outer-path"), m && t.look !== "handDrawn" && S.selectAll("path").attr("style", m), i && t.look !== "handDrawn" && S.selectAll("path").attr("style", i), l.attr(
    "transform",
    `translate(${-(n.width / 2) + St / 2 - (n.x - (n.left ?? 0))}, ${-(n.height / 2) + St / 2 - (n.y - (n.top ?? 0))})`
  ), K(t, S), t.intersect = function(_) {
    return G.polygon(t, b, _);
  }, a;
}
p(Cg, "windowPane");
var Jh = /* @__PURE__ */ new Set(["redux-color", "redux-dark-color"]), lT = /* @__PURE__ */ new Set(["redux", "redux-dark", "redux-color", "redux-dark-color"]);
async function il(e, t) {
  const r = t;
  r.alias && (t.label = r.alias);
  const { theme: i, themeVariables: s } = Tt(), { rowEven: o, rowOdd: a, nodeBorder: n, borderColorArray: l } = s;
  if (t.look === "handDrawn") {
    const { themeVariables: X } = Tt(), { background: ct } = X, ot = {
      ...t,
      id: t.id + "-background",
      domId: (t.domId || t.id) + "-background",
      look: "default",
      cssStyles: ["stroke: none", `fill: ${ct}`]
    };
    await il(e, ot);
  }
  const c = Tt();
  t.useHtmlLabels = c.htmlLabels;
  let h = c.er?.diagramPadding ?? 10, d = c.er?.entityPadding ?? 6;
  const { cssStyles: f } = t, { labelStyles: u, nodeStyles: g } = Z(t);
  if (r.attributes.length === 0 && t.label) {
    const X = {
      rx: 0,
      ry: 0,
      labelPaddingX: h,
      labelPaddingY: h * 1.5
    };
    qe(t.label, c) + X.labelPaddingX * 2 < c.er.minEntityWidth && (t.width = c.er.minEntityWidth);
    const ct = await ei(e, t, X);
    if (i != null && Jh.has(i)) {
      const ot = r.colorIndex ?? 0;
      ct.attr("data-color-id", `color-${ot % l.length}`);
    }
    if (!ze(c.htmlLabels)) {
      const ot = ct.select("text"), xt = ot.node()?.getBBox();
      ot.attr("transform", `translate(${-xt.width / 2}, 0)`);
    }
    return ct;
  }
  c.htmlLabels || (h *= 1.25, d *= 1.25);
  let m = et(t);
  m || (m = "node default");
  const y = e.insert("g").attr("class", m).attr("id", t.domId || t.id), C = await Pr(y, t.label ?? "", c, 0, 0, ["name"], u);
  C.height += d;
  let b = 0;
  const k = [], T = [];
  let S = 0, _ = 0, A = 0, v = 0, q = !0, I = !0;
  for (const X of r.attributes) {
    const ct = await Pr(
      y,
      X.type,
      c,
      0,
      b,
      ["attribute-type"],
      u
    );
    S = Math.max(S, ct.width + h);
    const ot = await Pr(
      y,
      X.name,
      c,
      0,
      b,
      ["attribute-name"],
      u
    );
    _ = Math.max(_, ot.width + h);
    const xt = await Pr(
      y,
      X.keys.join(),
      c,
      0,
      b,
      ["attribute-keys"],
      u
    );
    A = Math.max(A, xt.width + h);
    const bt = await Pr(
      y,
      X.comment,
      c,
      0,
      b,
      ["attribute-comment"],
      u
    );
    v = Math.max(v, bt.width + h);
    const kt = Math.max(ct.height, ot.height, xt.height, bt.height) + d;
    T.push({ yOffset: b, rowHeight: kt }), b += kt;
  }
  let R = 4;
  A <= h && (q = !1, A = 0, R--), v <= h && (I = !1, v = 0, R--);
  const H = y.node().getBBox();
  if (C.width + h * 2 - (S + _ + A + v) > 0) {
    const X = C.width + h * 2 - (S + _ + A + v);
    S += X / R, _ += X / R, A > 0 && (A += X / R), v > 0 && (v += X / R);
  }
  const W = S + _ + A + v, M = j.svg(y), F = V(t, {});
  t.look !== "handDrawn" && (F.roughness = 0, F.fillStyle = "solid");
  let L = 0;
  T.length > 0 && (L = T.reduce((X, ct) => X + (ct?.rowHeight ?? 0), 0));
  const E = Math.max(H.width + h * 2, t?.width || 0, W), D = Math.max((L ?? 0) + C.height, t?.height || 0), z = -E / 2, Y = -D / 2;
  if (y.selectAll("g:not(:first-child)").each((X, ct, ot) => {
    const xt = ht(ot[ct]), bt = xt.attr("transform");
    let kt = 0, ne = 0;
    if (bt) {
      const Sr = RegExp(/translate\(([^,]+),([^)]+)\)/).exec(bt);
      Sr && (kt = parseFloat(Sr[1]), ne = parseFloat(Sr[2]), xt.attr("class").includes("attribute-name") ? kt += S : xt.attr("class").includes("attribute-keys") ? kt += S + _ : xt.attr("class").includes("attribute-comment") && (kt += S + _ + A));
    }
    xt.attr(
      "transform",
      `translate(${z + h / 2 + kt}, ${ne + Y + C.height + d / 2})`
    );
  }), y.select(".name").attr("transform", "translate(" + -C.width / 2 + ", " + (Y + d / 2) + ")"), i != null && Jh.has(i)) {
    const X = r.colorIndex ?? 0;
    y.attr("data-color-id", `color-${X % l.length}`);
  }
  const lt = M.rectangle(z, Y, E, D, F), pt = y.insert(() => lt, ":first-child").attr("class", "outer-path").attr("style", f.join(""));
  k.push(0);
  for (const [X, ct] of T.entries()) {
    const xt = (X + 1) % 2 === 0 && ct.yOffset !== 0, bt = M.rectangle(z, C.height + Y + ct?.yOffset, E, ct?.rowHeight, {
      ...F,
      fill: xt ? o : a,
      stroke: n
    });
    y.insert(() => bt, "g.label").attr("style", f.join("")).attr("class", `row-rect-${xt ? "even" : "odd"}`);
  }
  const ut = 1e-4;
  let tt = Nr(z, C.height + Y, E + z, C.height + Y, ut), yt = M.polygon(
    tt.map((X) => [X.x, X.y]),
    F
  );
  if (y.insert(() => yt).attr("class", "divider"), tt = Nr(S + z, C.height + Y, S + z, D + Y, ut), yt = M.polygon(
    tt.map((X) => [X.x, X.y]),
    F
  ), y.insert(() => yt).attr("class", "divider"), q) {
    const X = S + _ + z;
    tt = Nr(X, C.height + Y, X, D + Y, ut), yt = M.polygon(
      tt.map((ct) => [ct.x, ct.y]),
      F
    ), y.insert(() => yt).attr("class", "divider");
  }
  if (I) {
    const X = S + _ + A + z;
    tt = Nr(X, C.height + Y, X, D + Y, ut), yt = M.polygon(
      tt.map((ct) => [ct.x, ct.y]),
      F
    ), y.insert(() => yt).attr("class", "divider");
  }
  for (const X of k) {
    const ct = C.height + Y + X;
    tt = Nr(z, ct, E + z, ct, ut), yt = M.polygon(
      tt.map((ot) => [ot.x, ot.y]),
      F
    ), y.insert(() => yt).attr("class", "divider");
  }
  if (K(t, pt), g && t.look !== "handDrawn")
    if (i != null && lT.has(i))
      y.selectAll("path").attr("style", g);
    else {
      const ct = g.split(";")?.filter((ot) => ot.includes("stroke"))?.map((ot) => `${ot}`).join("; ");
      y.selectAll("path").attr("style", ct ?? ""), y.selectAll(".row-rect-even path").attr("style", g);
    }
  return t.intersect = function(X) {
    return G.rect(t, X);
  }, y;
}
p(il, "erBox");
async function Pr(e, t, r, i = 0, s = 0, o = [], a = "") {
  const n = e.insert("g").attr("class", `label ${o.join(" ")}`).attr("transform", `translate(${i}, ${s})`).attr("style", a);
  t !== Hl(t) && (t = Hl(t), t = t.replaceAll("<", "&lt;").replaceAll(">", "&gt;"));
  const l = n.node().appendChild(
    await He(
      n,
      t,
      {
        width: qe(t, r) + 100,
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
  if (ze(r.htmlLabels)) {
    const h = l.children[0];
    h.style.textAlign = "start";
    const d = ht(l);
    c = h.getBoundingClientRect(), d.attr("width", c.width), d.attr("height", c.height);
  }
  return c;
}
p(Pr, "addText");
function Nr(e, t, r, i, s) {
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
p(Nr, "lineToPolygon");
async function xg(e, t, r, i, s = r.class.padding ?? 12) {
  const o = i ? 0 : 3, a = e.insert("g").attr("class", et(t)).attr("id", t.domId || t.id);
  let n = null, l = null, c = null, h = null, d = 0, f = 0, u = 0;
  if (n = a.insert("g").attr("class", "annotation-group text"), t.annotations.length > 0) {
    const b = t.annotations[0];
    await ki(n, { text: `«${b}»` }, 0), d = n.node().getBBox().height;
  }
  l = a.insert("g").attr("class", "label-group text"), await ki(l, t, 0, ["font-weight: bolder"]);
  const g = l.node().getBBox();
  f = g.height, c = a.insert("g").attr("class", "members-group text");
  let m = 0;
  for (const b of t.members) {
    const k = await ki(c, b, m, [b.parseClassifier()]);
    m += k + o;
  }
  u = c.node().getBBox().height, u <= 0 && (u = s / 2), h = a.insert("g").attr("class", "methods-group text");
  let y = 0;
  for (const b of t.methods) {
    const k = await ki(h, b, y, [b.parseClassifier()]);
    y += k + o;
  }
  let C = a.node().getBBox();
  if (n !== null) {
    const b = n.node().getBBox();
    n.attr("transform", `translate(${-b.width / 2})`);
  }
  return l.attr("transform", `translate(${-g.width / 2}, ${d})`), C = a.node().getBBox(), c.attr(
    "transform",
    `translate(0, ${d + f + s * 2})`
  ), C = a.node().getBBox(), h.attr(
    "transform",
    `translate(0, ${d + f + (u ? u + s * 4 : s * 2)})`
  ), C = a.node().getBBox(), { shapeSvg: a, bbox: C };
}
p(xg, "textHelper");
async function ki(e, t, r, i = []) {
  const s = e.insert("g").attr("class", "label").attr("style", i.join("; ")), o = Tt();
  let a = "useHtmlLabels" in t ? t.useHtmlLabels : ze(o.htmlLabels) ?? !0, n = "";
  "text" in t ? n = t.text : n = t.label, !a && n.startsWith("\\") && (n = n.substring(1)), Fi(n) && (a = !0);
  const l = await He(
    s,
    un(br(n)),
    {
      width: qe(n, o) + 50,
      // Add room for error when splitting text into multiple lines
      classes: "markdown-node-label",
      useHtmlLabels: a
    },
    o
  );
  let c, h = 1;
  if (a) {
    const d = l.children[0], f = ht(l);
    h = d.innerHTML.split("<br>").length, d.innerHTML.includes("</math>") && (h += d.innerHTML.split("<mrow>").length - 1);
    const u = d.getElementsByTagName("img");
    if (u) {
      const g = n.replace(/<img[^>]*>/g, "").trim() === "";
      await Promise.all(
        [...u].map(
          (m) => new Promise((y) => {
            function C() {
              if (m.style.display = "flex", m.style.flexDirection = "column", g) {
                const b = o.fontSize?.toString() ?? window.getComputedStyle(document.body).fontSize, T = parseInt(b, 10) * 5 + "px";
                m.style.minWidth = T, m.style.maxWidth = T;
              } else
                m.style.width = "100%";
              y(m);
            }
            p(C, "setupImage"), setTimeout(() => {
              m.complete && C();
            }), m.addEventListener("error", C), m.addEventListener("load", C);
          })
        )
      );
    }
    c = d.getBoundingClientRect(), f.attr("width", c.width), f.attr("height", c.height);
  } else {
    i.includes("font-weight: bolder") && ht(l).selectAll("tspan").attr("font-weight", ""), h = l.children.length;
    const d = l.children[0];
    (l.textContent === "" || l.textContent.includes("&gt")) && (d.textContent = n[0] + n.substring(1).replaceAll("&gt;", ">").replaceAll("&lt;", "<").trim(), n[1] === " " && (d.textContent = d.textContent[0] + " " + d.textContent.substring(1))), d.textContent === "undefined" && (d.textContent = ""), c = l.getBBox();
  }
  return s.attr("transform", "translate(0," + (-c.height / (2 * h) + r) + ")"), c.height;
}
p(ki, "addText");
async function bg(e, t) {
  const r = gt(), { themeVariables: i } = r, { useGradient: s } = i, o = r.class.padding ?? 12, a = o, n = t.useHtmlLabels ?? ze(r.htmlLabels) ?? !0, l = t;
  l.annotations = l.annotations ?? [], l.members = l.members ?? [], l.methods = l.methods ?? [];
  const { shapeSvg: c, bbox: h } = await xg(e, t, r, n, a), { labelStyles: d, nodeStyles: f } = Z(t);
  t.labelStyle = d, t.cssStyles = l.styles || "";
  const u = l.styles?.join(";") || f || "";
  t.cssStyles || (t.cssStyles = u.replaceAll("!important", "").split(";"));
  const g = l.members.length === 0 && l.methods.length === 0 && !r.class?.hideEmptyMembersBox, m = j.svg(c), y = V(t, {});
  t.look !== "handDrawn" && (y.roughness = 0, y.fillStyle = "solid");
  const C = Math.max(t.width ?? 0, h.width);
  let b = Math.max(t.height ?? 0, h.height);
  const k = (t.height ?? 0) > h.height;
  l.members.length === 0 && l.methods.length === 0 ? b += a : l.members.length > 0 && l.methods.length === 0 && (b += a * 2);
  const T = -C / 2, S = -b / 2;
  let _ = g ? o * 2 : l.members.length === 0 && l.methods.length === 0 ? -o : 0;
  k && (_ = o * 2);
  const A = m.rectangle(
    T - o,
    S - o - (g ? o : l.members.length === 0 && l.methods.length === 0 ? -o / 2 : 0),
    C + 2 * o,
    b + 2 * o + _,
    y
  ), v = c.insert(() => A, ":first-child");
  v.attr("class", "basic label-container outer-path");
  const q = v.node().getBBox(), I = c.select(".annotation-group").node().getBBox().height - (g ? o / 2 : 0) || 0, R = c.select(".label-group").node().getBBox().height - (g ? o / 2 : 0) || 0, H = c.select(".members-group").node().getBBox().height - (g ? o / 2 : 0) || 0, W = (I + R + S + o - (S - o - (g ? o : l.members.length === 0 && l.methods.length === 0 ? -o / 2 : 0))) / 2;
  if (c.selectAll(".text").each((M, F, L) => {
    const E = ht(L[F]), D = E.attr("transform");
    let z = 0;
    if (D) {
      const ut = RegExp(/translate\(([^,]+),([^)]+)\)/).exec(D);
      ut && (z = parseFloat(ut[2]));
    }
    let Y = z + S + o - (g ? o : l.members.length === 0 && l.methods.length === 0 ? -o / 2 : 0);
    if (E.attr("class").includes("methods-group")) {
      const pt = Math.max(H, a / 2);
      k ? Y = Math.max(
        W,
        I + R + pt + S + a * 2 + o
      ) + a * 2 : Y = I + R + pt + S + a * 4 + o;
    }
    l.members.length === 0 && l.methods.length === 0 && r.class?.hideEmptyMembersBox && (l.annotations.length > 0 ? Y = z - a : Y = z), n || (Y -= 4);
    let lt = T;
    (E.attr("class").includes("label-group") || E.attr("class").includes("annotation-group")) && (lt = -E.node()?.getBBox().width / 2 || 0, c.selectAll("text").each(function(pt, ut, tt) {
      window.getComputedStyle(tt[ut]).textAnchor === "middle" && (lt = 0);
    })), E.attr("transform", `translate(${lt}, ${Y})`);
  }), l.members.length > 0 || l.methods.length > 0 || g) {
    const M = I + R + S + o, F = m.line(
      q.x,
      M,
      q.x + q.width,
      M + 1e-3,
      y
    );
    c.insert(() => F).attr("class", `divider${t.look === "neo" && !s ? " neo-line" : ""}`).attr("style", u);
  }
  if (g || l.members.length > 0 || l.methods.length > 0) {
    const M = I + R + H + S + a * 2 + o, F = m.line(
      q.x,
      k ? Math.max(W, M) : M,
      q.x + q.width,
      (k ? Math.max(W, M) : M) + 1e-3,
      y
    );
    c.insert(() => F).attr("class", `divider${t.look === "neo" && !s ? " neo-line" : ""}`).attr("style", u);
  }
  if (l.look !== "handDrawn" && c.selectAll("path").attr("style", u), v.select(":nth-child(2)").attr("style", u), c.selectAll(".divider").select("path").attr("style", u), t.labelStyle ? c.selectAll("span").attr("style", t.labelStyle) : c.selectAll("span").attr("style", u), !n) {
    const M = RegExp(/color\s*:\s*([^;]*)/), F = M.exec(u);
    if (F) {
      const L = F[0].replace("color", "fill");
      c.selectAll("tspan").attr("style", L);
    } else if (d) {
      const L = M.exec(d);
      if (L) {
        const E = L[0].replace("color", "fill");
        c.selectAll("tspan").attr("style", E);
      }
    }
  }
  return K(t, v), t.intersect = function(M) {
    return G.rect(t, M);
  }, c;
}
p(bg, "classBox");
async function kg(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const s = t, o = t, a = 20, n = 20, l = "verifyMethod" in t, c = et(t), { themeVariables: h } = gt(), { borderColorArray: d, requirementEdgeLabelBackground: f } = h, u = e.insert("g").attr("class", c).attr("id", t.domId ?? t.id);
  let g;
  l ? g = await we(
    u,
    `&lt;&lt;${s.type}&gt;&gt;`,
    0,
    t.labelStyle
  ) : g = await we(u, "&lt;&lt;Element&gt;&gt;", 0, t.labelStyle);
  let m = g;
  const y = await we(
    u,
    s.name,
    m,
    t.labelStyle + "; font-weight: bold;"
  );
  if (m += y + n, l) {
    const q = await we(
      u,
      `${s.requirementId ? `ID: ${s.requirementId}` : ""}`,
      m,
      t.labelStyle
    );
    m += q;
    const I = await we(
      u,
      `${s.text ? `Text: ${s.text}` : ""}`,
      m,
      t.labelStyle
    );
    m += I;
    const R = await we(
      u,
      `${s.risk ? `Risk: ${s.risk}` : ""}`,
      m,
      t.labelStyle
    );
    m += R, await we(
      u,
      `${s.verifyMethod ? `Verification: ${s.verifyMethod}` : ""}`,
      m,
      t.labelStyle
    );
  } else {
    const q = await we(
      u,
      `${o.type ? `Type: ${o.type}` : ""}`,
      m,
      t.labelStyle
    );
    m += q, await we(
      u,
      `${o.docRef ? `Doc Ref: ${o.docRef}` : ""}`,
      m,
      t.labelStyle
    );
  }
  const C = (u.node()?.getBBox().width ?? 200) + a, b = (u.node()?.getBBox().height ?? 200) + a, k = -C / 2, T = -b / 2, S = j.svg(u), _ = V(t, {});
  t.look !== "handDrawn" && (_.roughness = 0, _.fillStyle = "solid");
  const A = S.rectangle(k, T, C, b, _), v = u.insert(() => A, ":first-child");
  if (v.attr("class", "basic label-container outer-path").attr("style", i), d?.length) {
    const q = t.colorIndex ?? 0;
    u.attr("data-color-id", `color-${q % d.length}`);
  }
  if (u.selectAll(".label").each((q, I, R) => {
    const H = ht(R[I]), W = H.attr("transform");
    let M = 0, F = 0;
    if (W) {
      const z = RegExp(/translate\(([^,]+),([^)]+)\)/).exec(W);
      z && (M = parseFloat(z[1]), F = parseFloat(z[2]));
    }
    const L = F - b / 2;
    let E = k + a / 2;
    (I === 0 || I === 1) && (E = M), H.attr("transform", `translate(${E}, ${L + a})`);
  }), m > g + y + n) {
    const q = T + g + y + n;
    let I;
    if (t.look === "neo") {
      const W = [
        [k, q],
        [k + C, q],
        [k + C, q + 1e-3],
        [k, q + 1e-3]
      ];
      I = S.polygon(W, _);
    } else
      I = S.line(k, q, k + C, q, _);
    u.insert(() => I).attr("class", "divider");
  }
  return K(t, v), t.intersect = function(q) {
    return G.rect(t, q);
  }, i && t.look !== "handDrawn" && (f || d?.length) && u.selectAll("path").attr("style", i), u;
}
p(kg, "requirementBox");
async function we(e, t, r, i = "") {
  if (t === "")
    return 0;
  const s = e.insert("g").attr("class", "label").attr("style", i), o = gt(), a = o.htmlLabels ?? !0, n = await He(
    s,
    un(br(t)),
    {
      width: qe(t, o) + 50,
      // Add room for error when splitting text into multiple lines
      classes: "markdown-node-label",
      useHtmlLabels: a,
      style: i
    },
    o
  );
  let l;
  if (a) {
    const c = n.children[0], h = ht(n);
    l = c.getBoundingClientRect(), h.attr("width", l.width), h.attr("height", l.height);
  } else {
    const c = n.children[0];
    for (const h of c.children)
      i && h.setAttribute("style", i);
    l = n.getBBox(), l.height += 6;
  }
  return s.attr("transform", `translate(${-l.width / 2},${-l.height / 2 + r})`), l.height;
}
p(we, "addText");
var hT = /* @__PURE__ */ p((e) => {
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
async function wg(e, t, { config: r }) {
  const { labelStyles: i, nodeStyles: s } = Z(t);
  t.labelStyle = i || "";
  const o = 10, a = t.width;
  t.width = (t.width ?? 200) - 10;
  const {
    shapeSvg: n,
    bbox: l,
    label: c
  } = await rt(e, t, et(t)), h = t.padding || 10;
  let d = "", f;
  "ticket" in t && t.ticket && r?.kanban?.ticketBaseUrl && (d = r?.kanban?.ticketBaseUrl.replace("#TICKET#", t.ticket), f = n.insert("svg:a", ":first-child").attr("class", "kanban-ticket-link").attr("xlink:href", d).attr("target", "_blank"));
  const u = {
    useHtmlLabels: t.useHtmlLabels,
    labelStyle: t.labelStyle || "",
    width: t.width,
    img: t.img,
    padding: t.padding || 8,
    centerLabel: !1
  };
  let g, m;
  f ? { label: g, bbox: m } = await ea(
    f,
    "ticket" in t && t.ticket || "",
    u
  ) : { label: g, bbox: m } = await ea(
    n,
    "ticket" in t && t.ticket || "",
    u
  );
  const { label: y, bbox: C } = await ea(
    n,
    "assigned" in t && t.assigned || "",
    u
  );
  t.width = a;
  const b = 10, k = t?.width || 0, T = Math.max(m.height, C.height) / 2, S = Math.max(l.height + b * 2, t?.height || 0) + T, _ = -k / 2, A = -S / 2;
  c.attr(
    "transform",
    "translate(" + (h - k / 2) + ", " + (-T - l.height / 2) + ")"
  ), g.attr(
    "transform",
    "translate(" + (h - k / 2) + ", " + (-T + l.height / 2) + ")"
  ), y.attr(
    "transform",
    "translate(" + (h + k / 2 - C.width - 2 * o) + ", " + (-T + l.height / 2) + ")"
  );
  let v;
  const { rx: q, ry: I } = t, { cssStyles: R } = t;
  if (t.look === "handDrawn") {
    const H = j.svg(n), W = V(t, {}), M = q || I ? H.path(ir(_, A, k, S, q || 0), W) : H.rectangle(_, A, k, S, W);
    v = n.insert(() => M, ":first-child"), v.attr("class", "basic label-container").attr("style", R || null);
  } else {
    v = n.insert("rect", ":first-child"), v.attr("class", "basic label-container __APA__").attr("style", s).attr("rx", q ?? 5).attr("ry", I ?? 5).attr("x", _).attr("y", A).attr("width", k).attr("height", S);
    const H = "priority" in t && t.priority;
    if (H) {
      const W = n.append("line"), M = _ + 2, F = A + Math.floor((q ?? 0) / 2), L = A + S - Math.floor((q ?? 0) / 2);
      W.attr("x1", M).attr("y1", F).attr("x2", M).attr("y2", L).attr("stroke-width", "4").attr("stroke", hT(H));
    }
  }
  return K(t, v), t.height = S, t.intersect = function(H) {
    return G.rect(t, H);
  }, n;
}
p(wg, "kanbanItem");
async function Tg(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const { shapeSvg: s, bbox: o, halfPadding: a, label: n } = await rt(
    e,
    t,
    et(t)
  ), l = o.width + 10 * a, c = o.height + 8 * a, h = 0.15 * l, { cssStyles: d } = t, f = o.width + 20, u = o.height + 20, g = Math.max(l, f), m = Math.max(c, u);
  n.attr("transform", `translate(${-o.width / 2}, ${-o.height / 2})`);
  let y;
  const C = `M0 0 
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
    const b = j.svg(s), k = V(t, {}), T = b.path(C, k);
    y = s.insert(() => T, ":first-child"), y.attr("class", "basic label-container").attr("style", Dt(d));
  } else
    y = s.insert("path", ":first-child").attr("class", "basic label-container").attr("style", i).attr("d", C);
  return y.attr("transform", `translate(${-g / 2}, ${-m / 2})`), K(t, y), t.calcIntersect = function(b, k) {
    return G.rect(b, k);
  }, t.intersect = function(b) {
    return P.info("Bang intersect", t, b), G.rect(t, b);
  }, s;
}
p(Tg, "bang");
async function Sg(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const { shapeSvg: s, bbox: o, halfPadding: a, label: n } = await rt(
    e,
    t,
    et(t)
  ), l = o.width + 2 * a, c = o.height + 2 * a, h = 0.15 * l, d = 0.25 * l, f = 0.35 * l, u = 0.2 * l, { cssStyles: g } = t;
  let m;
  const y = `M0 0 
    a${h},${h} 0 0,1 ${l * 0.25},${-1 * l * 0.1}
    a${f},${f} 1 0,1 ${l * 0.4},${-1 * l * 0.1}
    a${d},${d} 1 0,1 ${l * 0.35},${l * 0.2}

    a${h},${h} 1 0,1 ${l * 0.15},${c * 0.35}
    a${u},${u} 1 0,1 ${-1 * l * 0.15},${c * 0.65}

    a${d},${h} 1 0,1 ${-1 * l * 0.25},${l * 0.15}
    a${f},${f} 1 0,1 ${-1 * l * 0.5},0
    a${h},${h} 1 0,1 ${-1 * l * 0.25},${-1 * l * 0.15}

    a${h},${h} 1 0,1 ${-1 * l * 0.1},${-1 * c * 0.35}
    a${u},${u} 1 0,1 ${l * 0.1},${-1 * c * 0.65}
  H0 V0 Z`;
  if (t.look === "handDrawn") {
    const C = j.svg(s), b = V(t, {}), k = C.path(y, b);
    m = s.insert(() => k, ":first-child"), m.attr("class", "basic label-container").attr("style", Dt(g));
  } else
    m = s.insert("path", ":first-child").attr("class", "basic label-container").attr("style", i).attr("d", y);
  return n.attr("transform", `translate(${-o.width / 2}, ${-o.height / 2})`), m.attr("transform", `translate(${-l / 2}, ${-c / 2})`), K(t, m), t.calcIntersect = function(C, b) {
    return G.rect(C, b);
  }, t.intersect = function(C) {
    return P.info("Cloud intersect", t, C), G.rect(t, C);
  }, s;
}
p(Sg, "cloud");
async function _g(e, t) {
  const { labelStyles: r, nodeStyles: i } = Z(t);
  t.labelStyle = r;
  const { shapeSvg: s, bbox: o, halfPadding: a, label: n } = await rt(
    e,
    t,
    et(t)
  ), l = o.width + 8 * a, c = o.height + 2 * a, h = 5, d = t.look === "neo" ? `
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
  const f = s.append("path").attr("id", t.domId).attr("class", "node-bkg node-" + t.type).attr("style", i).attr("d", d);
  return s.append("line").attr("class", "node-line-").attr("x1", -l / 2).attr("y1", c / 2).attr("x2", l / 2).attr("y2", c / 2), n.attr("transform", `translate(${-o.width / 2}, ${-o.height / 2})`), s.append(() => n.node()), K(t, f), t.calcIntersect = function(u, g) {
    return G.rect(u, g);
  }, t.intersect = function(u) {
    return G.rect(t, u);
  }, s;
}
p(_g, "defaultMindmapNode");
async function Bg(e, t) {
  const r = {
    padding: t.padding ?? 0
  };
  return rl(e, t, r);
}
p(Bg, "mindmapCircle");
var cT = [
  {
    semanticName: "Process",
    name: "Rectangle",
    shortName: "rect",
    description: "Standard process shape",
    aliases: ["proc", "process", "rectangle"],
    internalAliases: ["squareRect"],
    handler: ig
  },
  {
    semanticName: "Event",
    name: "Rounded Rectangle",
    shortName: "rounded",
    description: "Represents an event",
    aliases: ["event"],
    internalAliases: ["roundedRect"],
    handler: tg
  },
  {
    semanticName: "Terminal Point",
    name: "Stadium",
    shortName: "stadium",
    description: "Terminal point",
    aliases: ["terminal", "pill"],
    handler: sg
  },
  {
    semanticName: "Subprocess",
    name: "Framed Rectangle",
    shortName: "fr-rect",
    description: "Subprocess",
    aliases: ["subprocess", "subproc", "framed-rectangle", "subroutine"],
    handler: lg
  },
  {
    semanticName: "Database",
    name: "Cylinder",
    shortName: "cyl",
    description: "Database storage",
    aliases: ["db", "database", "cylinder"],
    handler: Bp
  },
  {
    semanticName: "Data Store",
    name: "Data Store",
    shortName: "datastore",
    description: "Data flow diagram data store",
    aliases: ["data-store"],
    handler: vp
  },
  {
    semanticName: "Start",
    name: "Circle",
    shortName: "circle",
    description: "Starting point",
    aliases: ["circ"],
    handler: rl
  },
  {
    semanticName: "Bang",
    name: "Bang",
    shortName: "bang",
    description: "Bang",
    aliases: ["bang"],
    handler: Tg
  },
  {
    semanticName: "Cloud",
    name: "Cloud",
    shortName: "cloud",
    description: "cloud",
    aliases: ["cloud"],
    handler: Sg
  },
  {
    semanticName: "Decision",
    name: "Diamond",
    shortName: "diam",
    description: "Decision-making step",
    aliases: ["decision", "diamond", "question"],
    handler: Kp
  },
  {
    semanticName: "Prepare Conditional",
    name: "Hexagon",
    shortName: "hex",
    description: "Preparation or condition step",
    aliases: ["hexagon", "prepare"],
    handler: Op
  },
  {
    semanticName: "Data Input/Output",
    name: "Lean Right",
    shortName: "lean-r",
    description: "Represents input or output",
    aliases: ["lean-right", "in-out"],
    internalAliases: ["lean_right"],
    handler: Yp
  },
  {
    semanticName: "Data Input/Output",
    name: "Lean Left",
    shortName: "lean-l",
    description: "Represents output or input",
    aliases: ["lean-left", "out-in"],
    internalAliases: ["lean_left"],
    handler: Hp
  },
  {
    semanticName: "Priority Action",
    name: "Trapezoid Base Bottom",
    shortName: "trap-b",
    description: "Priority action",
    aliases: ["priority", "trapezoid-bottom", "trapezoid"],
    handler: fg
  },
  {
    semanticName: "Manual Operation",
    name: "Trapezoid Base Top",
    shortName: "trap-t",
    description: "Represents a manual task",
    aliases: ["manual", "trapezoid-top", "inv-trapezoid"],
    internalAliases: ["inv_trapezoid"],
    handler: Wp
  },
  {
    semanticName: "Stop",
    name: "Double Circle",
    shortName: "dbl-circ",
    description: "Represents a stop point",
    aliases: ["double-circle"],
    internalAliases: ["doublecircle"],
    handler: Fp
  },
  {
    semanticName: "Text Block",
    name: "Text Block",
    shortName: "text",
    description: "Text block",
    handler: dg
  },
  {
    semanticName: "Card",
    name: "Notched Rectangle",
    shortName: "notch-rect",
    description: "Represents a card",
    aliases: ["card", "notched-rectangle"],
    handler: Cp
  },
  {
    semanticName: "Lined/Shaded Process",
    name: "Lined Rectangle",
    shortName: "lin-rect",
    description: "Lined process shape",
    aliases: ["lined-rectangle", "lined-process", "lin-proc", "shaded-process"],
    handler: eg
  },
  {
    semanticName: "Start",
    name: "Small Circle",
    shortName: "sm-circ",
    description: "Small starting point",
    aliases: ["start", "small-circle"],
    internalAliases: ["stateStart"],
    handler: ng
  },
  {
    semanticName: "Stop",
    name: "Framed Circle",
    shortName: "fr-circ",
    description: "Stop point",
    aliases: ["stop", "framed-circle"],
    internalAliases: ["stateEnd"],
    handler: ag
  },
  {
    semanticName: "Fork/Join",
    name: "Filled Rectangle",
    shortName: "fork",
    description: "Fork or join in process flow",
    aliases: ["join"],
    internalAliases: ["forkJoin"],
    handler: Ep
  },
  {
    semanticName: "Collate",
    name: "Hourglass",
    shortName: "hourglass",
    description: "Represents a collate operation",
    aliases: ["hourglass", "collate"],
    handler: Ip
  },
  {
    semanticName: "Comment",
    name: "Curly Brace",
    shortName: "brace",
    description: "Adds a comment",
    aliases: ["comment", "brace-l"],
    handler: wp
  },
  {
    semanticName: "Comment Right",
    name: "Curly Brace",
    shortName: "brace-r",
    description: "Adds a comment",
    handler: Tp
  },
  {
    semanticName: "Comment with braces on both sides",
    name: "Curly Braces",
    shortName: "braces",
    description: "Adds a comment",
    handler: Sp
  },
  {
    semanticName: "Com Link",
    name: "Lightning Bolt",
    shortName: "bolt",
    description: "Communication link",
    aliases: ["com-link", "lightning-bolt"],
    handler: Up
  },
  {
    semanticName: "Document",
    name: "Document",
    shortName: "doc",
    description: "Represents a document",
    aliases: ["doc", "document"],
    handler: mg
  },
  {
    semanticName: "Delay",
    name: "Half-Rounded Rectangle",
    shortName: "delay",
    description: "Represents a delay",
    aliases: ["half-rounded-rectangle"],
    handler: $p
  },
  {
    semanticName: "Direct Access Storage",
    name: "Horizontal Cylinder",
    shortName: "h-cyl",
    description: "Direct access storage",
    aliases: ["das", "horizontal-cylinder"],
    handler: ug
  },
  {
    semanticName: "Disk Storage",
    name: "Lined Cylinder",
    shortName: "lin-cyl",
    description: "Disk storage",
    aliases: ["disk", "lined-cylinder"],
    handler: Gp
  },
  {
    semanticName: "Display",
    name: "Curved Trapezoid",
    shortName: "curv-trap",
    description: "Represents a display",
    aliases: ["curved-trapezoid", "display"],
    handler: _p
  },
  {
    semanticName: "Divided Process",
    name: "Divided Rectangle",
    shortName: "div-rect",
    description: "Divided process shape",
    aliases: ["div-proc", "divided-rectangle", "divided-process"],
    handler: Lp
  },
  {
    semanticName: "Extract",
    name: "Triangle",
    shortName: "tri",
    description: "Extraction process",
    aliases: ["extract", "triangle"],
    handler: gg
  },
  {
    semanticName: "Internal Storage",
    name: "Window Pane",
    shortName: "win-pane",
    description: "Internal storage",
    aliases: ["internal-storage", "window-pane"],
    handler: Cg
  },
  {
    semanticName: "Junction",
    name: "Filled Circle",
    shortName: "f-circ",
    description: "Junction point",
    aliases: ["junction", "filled-circle"],
    handler: Ap
  },
  {
    semanticName: "Loop Limit",
    name: "Trapezoidal Pentagon",
    shortName: "notch-pent",
    description: "Loop limit step",
    aliases: ["loop-limit", "notched-pentagon"],
    handler: pg
  },
  {
    semanticName: "Manual File",
    name: "Flipped Triangle",
    shortName: "flip-tri",
    description: "Manual file operation",
    aliases: ["manual-file", "flipped-triangle"],
    handler: Mp
  },
  {
    semanticName: "Manual Input",
    name: "Sloped Rectangle",
    shortName: "sl-rect",
    description: "Manual input step",
    aliases: ["manual-input", "sloped-rectangle"],
    handler: rg
  },
  {
    semanticName: "Multi-Document",
    name: "Stacked Document",
    shortName: "docs",
    description: "Multiple documents",
    aliases: ["documents", "st-doc", "stacked-document"],
    handler: Vp
  },
  {
    semanticName: "Multi-Process",
    name: "Stacked Rectangle",
    shortName: "st-rect",
    description: "Multiple processes",
    aliases: ["procs", "processes", "stacked-rectangle"],
    handler: Xp
  },
  {
    semanticName: "Stored Data",
    name: "Bow Tie Rectangle",
    shortName: "bow-rect",
    description: "Stored data",
    aliases: ["stored-data", "bow-tie-rectangle"],
    handler: yp
  },
  {
    semanticName: "Summary",
    name: "Crossed Circle",
    shortName: "cross-circ",
    description: "Summary",
    aliases: ["summary", "crossed-circle"],
    handler: kp
  },
  {
    semanticName: "Tagged Document",
    name: "Tagged Document",
    shortName: "tag-doc",
    description: "Tagged document",
    aliases: ["tag-doc", "tagged-document"],
    handler: cg
  },
  {
    semanticName: "Tagged Process",
    name: "Tagged Rectangle",
    shortName: "tag-rect",
    description: "Tagged process",
    aliases: ["tagged-rectangle", "tag-proc", "tagged-process"],
    handler: hg
  },
  {
    semanticName: "Paper Tape",
    name: "Flag",
    shortName: "flag",
    description: "Paper tape",
    aliases: ["paper-tape"],
    handler: yg
  },
  {
    semanticName: "Odd",
    name: "Odd",
    shortName: "odd",
    description: "Odd shape",
    internalAliases: ["rect_left_inv_arrow"],
    handler: Qp
  },
  {
    semanticName: "Lined Document",
    name: "Lined Document",
    shortName: "lin-doc",
    description: "Lined document",
    aliases: ["lined-document"],
    handler: jp
  }
], dT = /* @__PURE__ */ p(() => {
  const t = [
    ...Object.entries({
      // States
      state: og,
      choice: xp,
      note: Zp,
      // Rectangles
      rectWithTitle: Jp,
      labelRect: zp,
      // Icons
      iconSquare: Np,
      iconCircle: Rp,
      icon: Dp,
      iconRounded: Pp,
      imageSquare: qp,
      anchor: gp,
      // Kanban diagram
      kanbanItem: wg,
      //Mindmap diagram
      mindmapCircle: Bg,
      defaultMindmapNode: _g,
      // class diagram
      classBox: bg,
      // er diagram
      erBox: il,
      // Requirement diagram
      requirementBox: kg
    }),
    ...cT.flatMap((r) => [
      r.shortName,
      ..."aliases" in r ? r.aliases : [],
      ..."internalAliases" in r ? r.internalAliases : []
    ].map((s) => [s, r.handler]))
  ];
  return Object.fromEntries(t);
}, "generateShapeMap"), vg = dT();
function uT(e) {
  return e in vg;
}
p(uT, "isValidShape");
var wo = /* @__PURE__ */ new Map();
async function Lg(e, t, r) {
  let i, s;
  t.shape === "rect" && (t.rx && t.ry ? t.shape = "roundedRect" : t.shape = "squareRect");
  const o = t.shape ? vg[t.shape] : void 0;
  if (!o)
    throw new Error(`No such shape: ${t.shape}. Please check your syntax.`);
  if (t.link) {
    let a;
    r.config.securityLevel === "sandbox" ? a = "_top" : t.linkTarget && (a = t.linkTarget || "_blank"), i = e.insert("svg:a").attr("xlink:href", t.link).attr("target", a ?? null), s = await o(i, t, r);
  } else
    s = await o(e, t, r), i = s;
  return i.attr("data-look", Dt(t.look)), t.tooltip && s.attr("title", t.tooltip), wo.set(t.id, i), t.haveCallback && i.attr("class", i.attr("class") + " clickable"), i;
}
p(Lg, "insertNode");
var Nv = /* @__PURE__ */ p((e, t) => {
  wo.set(t.id, e);
}, "setNodeElem"), qv = /* @__PURE__ */ p(() => {
  wo.clear();
}, "clear"), Wv = /* @__PURE__ */ p((e) => {
  const t = wo.get(e.id);
  P.trace(
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
}, "positionNode"), fT = /* @__PURE__ */ p((e, t, r, i, s, o = !1, a) => {
  t.arrowTypeStart && tc(
    e,
    "start",
    t.arrowTypeStart,
    r,
    i,
    s,
    o,
    a
  ), t.arrowTypeEnd && tc(e, "end", t.arrowTypeEnd, r, i, s, o, a);
}, "addEdgeMarkers"), pT = {
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
}, gT = [
  "cross",
  "point",
  "circle",
  "lollipop",
  "aggregation",
  "extension",
  "composition",
  "dependency",
  "barb"
], tc = /* @__PURE__ */ p((e, t, r, i, s, o, a = !1, n) => {
  const l = pT[r], c = l && gT.includes(l.type);
  if (!l) {
    P.warn(`Unknown arrow type: ${r}`);
    return;
  }
  const h = l.type, u = `${s}_${o}-${h}${t === "start" ? "Start" : "End"}${a && c ? "-margin" : ""}`;
  if (n && n.trim() !== "") {
    const g = n.replace(/[^\dA-Za-z]/g, "_"), m = `${u}_${g}`;
    if (!document.getElementById(m)) {
      const y = document.getElementById(u);
      if (y) {
        const C = y.cloneNode(!0);
        C.id = m, C.querySelectorAll("path, circle, line").forEach((k) => {
          k.setAttribute("stroke", n), l.fill && k.setAttribute("fill", n);
        }), y.parentNode?.appendChild(C);
      }
    }
    e.attr(`marker-${t}`, `url(${i}#${m})`);
  } else
    e.attr(`marker-${t}`, `url(${i}#${u})`);
}, "addEdgeMarker"), mT = /* @__PURE__ */ p((e) => typeof e == "string" ? e : gt()?.flowchart?.curve, "resolveEdgeCurveType"), so = /* @__PURE__ */ new Map(), Nt = /* @__PURE__ */ new Map(), zv = /* @__PURE__ */ p(() => {
  so.clear(), Nt.clear();
}, "clear"), fi = /* @__PURE__ */ p((e) => e ? typeof e == "string" ? e : e.reduce((t, r) => t + ";" + r, "") : "", "getLabelStyles"), yT = /* @__PURE__ */ p(async (e, t) => {
  const r = gt();
  let i = Vt(r);
  const { labelStyles: s } = Z(t);
  t.labelStyle = s;
  const o = e.insert("g").attr("class", "edgeLabel"), a = o.insert("g").attr("class", "label").attr("data-id", t.id), n = t.labelType === "markdown", c = await He(
    e,
    t.label,
    {
      style: fi(t.labelStyle),
      useHtmlLabels: i,
      addSvgBackground: !0,
      isNode: !1,
      markdown: n,
      // Plain text edge labels should auto-wrap, markdown edge labels respect markdownAutoWrap config
      width: n ? void 0 : void 0
    },
    r
  );
  a.node().appendChild(c), P.info("abc82", t, t.labelType);
  let h = c.getBBox(), d = h;
  if (i) {
    const u = c.children[0], g = ht(c);
    h = u.getBoundingClientRect(), d = h, g.attr("width", h.width), g.attr("height", h.height);
  } else {
    const u = ht(c).select("text").node();
    u && typeof u.getBBox == "function" && (d = u.getBBox());
  }
  a.attr("transform", li(d, i)), so.set(t.id, o), t.width = h.width, t.height = h.height;
  let f;
  if (t.startLabelLeft) {
    const u = e.insert("g").attr("class", "edgeTerminals"), g = u.insert("g").attr("class", "inner"), m = await Ve(
      g,
      t.startLabelLeft,
      fi(t.labelStyle) || "",
      !1,
      !1
    );
    f = m;
    let y = m.getBBox();
    if (i) {
      const C = m.children[0], b = ht(m);
      y = C.getBoundingClientRect(), b.attr("width", y.width), b.attr("height", y.height);
    }
    g.attr("transform", li(y, i)), Nt.get(t.id) || Nt.set(t.id, {}), Nt.get(t.id).startLeft = u, wi(f, t.startLabelLeft);
  }
  if (t.startLabelRight) {
    const u = e.insert("g").attr("class", "edgeTerminals"), g = u.insert("g").attr("class", "inner"), m = await Ve(
      g,
      t.startLabelRight,
      fi(t.labelStyle) || "",
      !1,
      !1
    );
    f = m;
    let y = m.getBBox();
    if (i) {
      const C = m.children[0], b = ht(m);
      y = C.getBoundingClientRect(), b.attr("width", y.width), b.attr("height", y.height);
    }
    g.attr("transform", li(y, i)), Nt.get(t.id) || Nt.set(t.id, {}), Nt.get(t.id).startRight = u, wi(f, t.startLabelRight);
  }
  if (t.endLabelLeft) {
    const u = e.insert("g").attr("class", "edgeTerminals"), g = u.insert("g").attr("class", "inner"), m = await Ve(
      u,
      t.endLabelLeft,
      fi(t.labelStyle) || "",
      !1,
      !1
    );
    f = m;
    let y = m.getBBox();
    if (i) {
      const C = m.children[0], b = ht(m);
      y = C.getBoundingClientRect(), b.attr("width", y.width), b.attr("height", y.height);
    }
    g.attr("transform", li(y, i)), Nt.get(t.id) || Nt.set(t.id, {}), Nt.get(t.id).endLeft = u, wi(f, t.endLabelLeft);
  }
  if (t.endLabelRight) {
    const u = e.insert("g").attr("class", "edgeTerminals"), g = u.insert("g").attr("class", "inner"), m = await Ve(
      u,
      t.endLabelRight,
      fi(t.labelStyle) || "",
      !1,
      !1
    );
    f = m;
    let y = m.getBBox();
    if (i) {
      const C = m.children[0], b = ht(m);
      y = C.getBoundingClientRect(), b.attr("width", y.width), b.attr("height", y.height);
    }
    g.attr("transform", li(y, i)), Nt.get(t.id) || Nt.set(t.id, {}), Nt.get(t.id).endRight = u, wi(f, t.endLabelRight);
  }
  return c;
}, "insertEdgeLabel");
function wi(e, t) {
  Vt(gt()) && e && (e.style.width = t.length * 9 + "px", e.style.height = "12px");
}
p(wi, "setTerminalWidth");
var CT = /* @__PURE__ */ p((e, t) => {
  P.debug("Moving label abc88 ", e.id, e.label, so.get(e.id), t);
  let r = t.updatedPath ? t.updatedPath : t.originalPath;
  const i = gt(), { subGraphTitleTotalMargin: s } = Hn(i);
  if (e.label) {
    const o = so.get(e.id);
    let a = e.x, n = e.y;
    if (r) {
      const l = fe.calcLabelPosition(r);
      P.debug(
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
      const l = fe.calcTerminalLabelPosition(e.arrowTypeStart ? 10 : 0, "start_left", r);
      a = l.x, n = l.y;
    }
    o.attr("transform", `translate(${a}, ${n})`);
  }
  if (e.startLabelRight) {
    const o = Nt.get(e.id).startRight;
    let a = e.x, n = e.y;
    if (r) {
      const l = fe.calcTerminalLabelPosition(
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
      const l = fe.calcTerminalLabelPosition(e.arrowTypeEnd ? 10 : 0, "end_left", r);
      a = l.x, n = l.y;
    }
    o.attr("transform", `translate(${a}, ${n})`);
  }
  if (e.endLabelRight) {
    const o = Nt.get(e.id).endRight;
    let a = e.x, n = e.y;
    if (r) {
      const l = fe.calcTerminalLabelPosition(e.arrowTypeEnd ? 10 : 0, "end_right", r);
      a = l.x, n = l.y;
    }
    o.attr("transform", `translate(${a}, ${n})`);
  }
}, "positionEdgeLabel"), xT = /* @__PURE__ */ p((e, t) => {
  const r = e.x, i = e.y, s = Math.abs(t.x - r), o = Math.abs(t.y - i), a = e.width / 2, n = e.height / 2;
  return s >= a || o >= n;
}, "outsideNode"), bT = /* @__PURE__ */ p((e, t, r) => {
  P.debug(`intersection calc abc89:
  outsidePoint: ${JSON.stringify(t)}
  insidePoint : ${JSON.stringify(r)}
  node        : x:${e.x} y:${e.y} w:${e.width} h:${e.height}`);
  const i = e.x, s = e.y, o = Math.abs(i - r.x), a = e.width / 2;
  let n = r.x < t.x ? a - o : a + o;
  const l = e.height / 2, c = Math.abs(t.y - r.y), h = Math.abs(t.x - r.x);
  if (Math.abs(s - t.y) * a > Math.abs(i - t.x) * l) {
    let d = r.y < t.y ? t.y - l - s : s - l - t.y;
    n = h * d / c;
    const f = {
      x: r.x < t.x ? r.x + n : r.x - h + n,
      y: r.y < t.y ? r.y + c - d : r.y - c + d
    };
    return n === 0 && (f.x = t.x, f.y = t.y), h === 0 && (f.x = t.x), c === 0 && (f.y = t.y), P.debug(`abc89 top/bottom calc, Q ${c}, q ${d}, R ${h}, r ${n}`, f), f;
  } else {
    r.x < t.x ? n = t.x - a - i : n = i - a - t.x;
    let d = c * n / h, f = r.x < t.x ? r.x + h - n : r.x - h + n, u = r.y < t.y ? r.y + d : r.y - d;
    return P.debug(`sides calc abc89, Q ${c}, q ${d}, R ${h}, r ${n}`, { _x: f, _y: u }), n === 0 && (f = t.x, u = t.y), h === 0 && (f = t.x), c === 0 && (u = t.y), { x: f, y: u };
  }
}, "intersection"), ec = /* @__PURE__ */ p((e, t) => {
  P.warn("abc88 cutPathAtIntersect", e, t);
  let r = [], i = e[0], s = !1;
  return e.forEach((o) => {
    if (P.info("abc88 checking point", o, t), !xT(t, o) && !s) {
      const a = bT(t, i, o);
      P.debug("abc88 inside", o, i, a), P.debug("abc88 intersection", a, t);
      let n = !1;
      r.forEach((l) => {
        n = n || l.x === a.x && l.y === a.y;
      }), r.some((l) => l.x === a.x && l.y === a.y) ? P.warn("abc88 no intersect", a, r) : r.push(a), s = !0;
    } else
      P.warn("abc88 outside", o, i), i = o, s || r.push(o);
  }), P.debug("returning points", r), r;
}, "cutPathAtIntersect");
function Fg(e) {
  const t = [], r = [];
  for (let i = 1; i < e.length - 1; i++) {
    const s = e[i - 1], o = e[i], a = e[i + 1];
    (s.x === o.x && o.y === a.y && Math.abs(o.x - a.x) > 5 && Math.abs(o.y - s.y) > 5 || s.y === o.y && o.x === a.x && Math.abs(o.x - s.x) > 5 && Math.abs(o.y - a.y) > 5) && (t.push(o), r.push(i));
  }
  return { cornerPoints: t, cornerPointPositions: r };
}
p(Fg, "extractCornerPoints");
var rc = /* @__PURE__ */ p(function(e, t, r) {
  const i = t.x - e.x, s = t.y - e.y, o = Math.sqrt(i * i + s * s), a = r / o;
  return { x: t.x - a * i, y: t.y - a * s };
}, "findAdjacentPoint"), kT = /* @__PURE__ */ p(function(e) {
  const { cornerPointPositions: t } = Fg(e), r = [];
  for (let i = 0; i < e.length; i++)
    if (t.includes(i)) {
      const s = e[i - 1], o = e[i + 1], a = e[i], n = rc(s, a, 5), l = rc(o, a, 5), c = l.x - n.x, h = l.y - n.y;
      r.push(n);
      const d = Math.sqrt(2) * 2;
      let f = { x: a.x, y: a.y };
      if (Math.abs(o.x - s.x) > 10 && Math.abs(o.y - s.y) >= 10) {
        P.debug(
          "Corner point fixing",
          Math.abs(o.x - s.x),
          Math.abs(o.y - s.y)
        );
        const u = 5;
        a.x === n.x ? f = {
          x: c < 0 ? n.x - u + d : n.x + u - d,
          y: h < 0 ? n.y - d : n.y + d
        } : f = {
          x: c < 0 ? n.x - d : n.x + d,
          y: h < 0 ? n.y - u + d : n.y + u - d
        };
      } else
        P.debug(
          "Corner point skipping fixing",
          Math.abs(o.x - s.x),
          Math.abs(o.y - s.y)
        );
      r.push(f, l);
    } else
      r.push(e[i]);
  return r;
}, "fixCorners"), wT = /* @__PURE__ */ p((e, t, r) => {
  const i = e - t - r, s = 2, o = 2, a = s + o, n = Math.floor(i / a), l = Array(n).fill(`${s} ${o}`).join(" ");
  return `0 ${t} ${l} ${r}`;
}, "generateDashArray"), TT = /* @__PURE__ */ p(function(e, t, r, i, s, o, a, n = !1) {
  if (!a)
    throw new Error(
      `insertEdge: missing diagramId for edge "${t.id}" — edge IDs require a diagram prefix for uniqueness`
    );
  const { handDrawnSeed: l } = gt();
  let c = t.points, h = !1;
  const d = s;
  var f = o;
  const u = [];
  for (const E in t.cssCompiledStyles)
    vf(E) || u.push(t.cssCompiledStyles[E]);
  P.debug("UIO intersect check", t.points, f.x, d.x), f.intersect && d.intersect && !n && (c = c.slice(1, t.points.length - 1), c.unshift(d.intersect(c[0])), P.debug(
    "Last point UIO",
    t.start,
    "-->",
    t.end,
    c[c.length - 1],
    f,
    f.intersect(c[c.length - 1])
  ), c.push(f.intersect(c[c.length - 1])));
  const g = btoa(JSON.stringify(c));
  t.toCluster && (P.info("to cluster abc88", r.get(t.toCluster)), c = ec(t.points, r.get(t.toCluster).node), h = !0), t.fromCluster && (P.debug(
    "from cluster abc88",
    r.get(t.fromCluster),
    JSON.stringify(c, null, 2)
  ), c = ec(c.reverse(), r.get(t.fromCluster).node).reverse(), h = !0);
  let m = c.filter((E) => !Number.isNaN(E.y));
  const y = mT(t.curve);
  y !== "rounded" && (m = kT(m));
  let C = Bi;
  switch (y) {
    case "linear":
      C = Bi;
      break;
    case "basis":
      C = wa;
      break;
    case "cardinal":
      C = fd;
      break;
    case "bumpX":
      C = ld;
      break;
    case "bumpY":
      C = hd;
      break;
    case "catmullRom":
      C = gd;
      break;
    case "monotoneX":
      C = kd;
      break;
    case "monotoneY":
      C = wd;
      break;
    case "natural":
      C = Sd;
      break;
    case "step":
      C = _d;
      break;
    case "stepAfter":
      C = vd;
      break;
    case "stepBefore":
      C = Bd;
      break;
    case "rounded":
      C = Bi;
      break;
    default:
      C = wa;
  }
  const { x: b, y: k } = y1(t), T = tk().x(b).y(k).curve(C);
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
  let _, A = y === "rounded" ? Ag(Mg(m, t), 5) : T(m);
  const v = Array.isArray(t.style) ? t.style : [t.style];
  let q = v.find((E) => E?.startsWith("stroke:")), I = "";
  t.animate && (I = "edge-animation-fast"), t.animation && (I = "edge-animation-" + t.animation);
  let R = !1;
  if (t.look === "handDrawn") {
    const E = j.svg(e);
    Object.assign([], m);
    const D = E.path(A, {
      roughness: 0.3,
      seed: l
    });
    S += " transition", _ = ht(D).select("path").attr("id", `${a}-${t.id}`).attr(
      "class",
      " " + S + (t.classes ? " " + t.classes : "") + (I ? " " + I : "")
    ).attr("style", v ? v.reduce((Y, lt) => Y + ";" + lt, "") : "");
    let z = _.attr("d");
    _.attr("d", z), e.node().appendChild(_.node());
  } else {
    const E = u.join(";"), D = v ? v.reduce((tt, yt) => tt + yt + ";", "") : "", z = (E ? E + ";" + D + ";" : D) + ";" + (v ? v.reduce((tt, yt) => tt + ";" + yt, "") : "");
    _ = e.append("path").attr("d", A).attr("id", `${a}-${t.id}`).attr(
      "class",
      " " + S + (t.classes ? " " + t.classes : "") + (I ? " " + I : "")
    ).attr("style", z), q = z.match(/stroke:([^;]+)/)?.[1], R = t.animate === !0 || !!t.animation || E.includes("animation");
    const Y = _.node(), lt = typeof Y.getTotalLength == "function" ? Y.getTotalLength() : 0, pt = mh[t.arrowTypeStart] || 0, ut = mh[t.arrowTypeEnd] || 0;
    if (t.look === "neo" && !R) {
      const yt = `stroke-dasharray: ${t.pattern === "dotted" || t.pattern === "dashed" ? wT(lt, pt, ut) : `0 ${pt} ${lt - pt - ut} ${ut}`}; stroke-dashoffset: 0;`;
      _.attr("style", yt + _.attr("style"));
    }
  }
  _.attr("data-edge", !0), _.attr("data-et", "edge"), _.attr("data-id", t.id), _.attr("data-points", g), _.attr("data-look", Dt(t.look)), t.showPoints && m.forEach((E) => {
    e.append("circle").style("stroke", "red").style("fill", "red").attr("r", 1).attr("cx", E.x).attr("cy", E.y);
  });
  let H = "";
  (gt().flowchart.arrowMarkerAbsolute || gt().state.arrowMarkerAbsolute) && (H = window.location.protocol + "//" + window.location.host + window.location.pathname + window.location.search, H = H.replace(/\(/g, "\\(").replace(/\)/g, "\\)")), P.info("arrowTypeStart", t.arrowTypeStart), P.info("arrowTypeEnd", t.arrowTypeEnd);
  const W = !R && t?.look === "neo";
  fT(_, t, H, a, i, W, q);
  const M = Math.floor(c.length / 2), F = c[M];
  fe.isLabelCoordinateInPath(F, _.attr("d")) || (h = !0);
  let L = {};
  return h && (L.updatedPath = c), L.originalPath = t.points, L;
}, "insertEdge");
function Ag(e, t) {
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
      const c = a.x - n.x, h = a.y - n.y, d = l.x - a.x, f = l.y - a.y, u = Math.hypot(c, h), g = Math.hypot(d, f);
      if (u < s || g < s) {
        r += `L${a.x},${a.y}`;
        continue;
      }
      const m = c / u, y = h / u, C = d / g, b = f / g, k = m * C + y * b, T = Math.max(-1, Math.min(1, k)), S = Math.acos(T);
      if (S < s || Math.abs(Math.PI - S) < s) {
        r += `L${a.x},${a.y}`;
        continue;
      }
      const _ = Math.min(t / Math.sin(S / 2), u / 2, g / 2), A = a.x - m * _, v = a.y - y * _, q = a.x + C * _, I = a.y + b * _;
      r += `L${A},${v}`, r += `Q${a.x},${a.y} ${q},${I}`;
    }
  }
  return r;
}
p(Ag, "generateRoundedPath");
function Qa(e, t) {
  if (!e || !t)
    return { angle: 0, deltaX: 0, deltaY: 0 };
  const r = t.x - e.x, i = t.y - e.y;
  return { angle: Math.atan2(i, r), deltaX: r, deltaY: i };
}
p(Qa, "calculateDeltaAndAngle");
function Mg(e, t) {
  const r = e.map((s) => ({ ...s }));
  if (e.length >= 2 && Wt[t.arrowTypeStart]) {
    const s = Wt[t.arrowTypeStart], o = e[0], a = e[1], { angle: n } = Qa(o, a), l = s * Math.cos(n), c = s * Math.sin(n);
    r[0].x = o.x + l, r[0].y = o.y + c;
  }
  const i = e.length;
  if (i >= 2 && Wt[t.arrowTypeEnd]) {
    const s = Wt[t.arrowTypeEnd], o = e[i - 1], a = e[i - 2], { angle: n } = Qa(a, o), l = s * Math.cos(n), c = s * Math.sin(n);
    r[i - 1].x = o.x - l, r[i - 1].y = o.y - c;
  }
  return r;
}
p(Mg, "applyMarkerOffsetsToPoints");
var ST = /* @__PURE__ */ p((e, t, r, i) => {
  t.forEach((s) => {
    jT[s](e, r, i);
  });
}, "insertMarkers"), _T = /* @__PURE__ */ p((e, t, r) => {
  P.trace("Making markers for ", r), e.append("defs").append("marker").attr("id", r + "_" + t + "-extensionStart").attr("class", "marker extension " + t).attr("refX", 18).attr("refY", 7).attr("markerWidth", 20).attr("markerHeight", 28).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").append("path").attr("d", "M 1,7 L18,13 V 1 Z"), e.append("defs").append("marker").attr("id", r + "_" + t + "-extensionEnd").attr("class", "marker extension " + t).attr("refX", 1).attr("refY", 7).attr("markerWidth", 20).attr("markerHeight", 28).attr("orient", "auto").append("path").attr("d", "M 1,1 V 13 L18,7 Z"), e.append("marker").attr("id", r + "_" + t + "-extensionStart-margin").attr("class", "marker extension " + t).attr("refX", 18).attr("refY", 7).attr("markerWidth", 20).attr("markerHeight", 28).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").attr("viewBox", "0 0 20 14").append("polygon").attr("points", "10,7 18,13 18,1").style("stroke-width", 2).style("stroke-dasharray", "0"), e.append("defs").append("marker").attr("id", r + "_" + t + "-extensionEnd-margin").attr("class", "marker extension " + t).attr("refX", 9).attr("refY", 7).attr("markerWidth", 20).attr("markerHeight", 28).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").attr("viewBox", "0 0 20 14").append("polygon").attr("points", "10,1 10,13 18,7").style("stroke-width", 2).style("stroke-dasharray", "0");
}, "extension"), BT = /* @__PURE__ */ p((e, t, r) => {
  e.append("defs").append("marker").attr("id", r + "_" + t + "-compositionStart").attr("class", "marker composition " + t).attr("refX", 18).attr("refY", 7).attr("markerWidth", 190).attr("markerHeight", 240).attr("orient", "auto").append("path").attr("d", "M 18,7 L9,13 L1,7 L9,1 Z"), e.append("defs").append("marker").attr("id", r + "_" + t + "-compositionEnd").attr("class", "marker composition " + t).attr("refX", 1).attr("refY", 7).attr("markerWidth", 20).attr("markerHeight", 28).attr("orient", "auto").append("path").attr("d", "M 18,7 L9,13 L1,7 L9,1 Z"), e.append("defs").append("marker").attr("id", r + "_" + t + "-compositionStart-margin").attr("class", "marker composition " + t).attr("refX", 15).attr("refY", 7).attr("markerWidth", 190).attr("markerHeight", 240).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").append("path").style("stroke-width", 0).attr("viewBox", "0 0 15 15").attr("d", "M 18,7 L9,13 L1,7 L9,1 Z"), e.append("defs").append("marker").attr("id", r + "_" + t + "-compositionEnd-margin").attr("class", "marker composition " + t).attr("refX", 3.5).attr("refY", 7).attr("markerWidth", 20).attr("markerHeight", 28).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").append("path").style("stroke-width", 0).attr("d", "M 18,7 L9,13 L1,7 L9,1 Z");
}, "composition"), vT = /* @__PURE__ */ p((e, t, r) => {
  e.append("defs").append("marker").attr("id", r + "_" + t + "-aggregationStart").attr("class", "marker aggregation " + t).attr("refX", 18).attr("refY", 7).attr("markerWidth", 190).attr("markerHeight", 240).attr("orient", "auto").append("path").attr("d", "M 18,7 L9,13 L1,7 L9,1 Z"), e.append("defs").append("marker").attr("id", r + "_" + t + "-aggregationEnd").attr("class", "marker aggregation " + t).attr("refX", 1).attr("refY", 7).attr("markerWidth", 20).attr("markerHeight", 28).attr("orient", "auto").append("path").attr("d", "M 18,7 L9,13 L1,7 L9,1 Z"), e.append("defs").append("marker").attr("id", r + "_" + t + "-aggregationStart-margin").attr("class", "marker aggregation " + t).attr("refX", 15).attr("refY", 7).attr("markerWidth", 190).attr("markerHeight", 240).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").append("path").style("stroke-width", 2).attr("d", "M 18,7 L9,13 L1,7 L9,1 Z"), e.append("defs").append("marker").attr("id", r + "_" + t + "-aggregationEnd-margin").attr("class", "marker aggregation " + t).attr("refX", 1).attr("refY", 7).attr("markerWidth", 20).attr("markerHeight", 28).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").append("path").style("stroke-width", 2).attr("d", "M 18,7 L9,13 L1,7 L9,1 Z");
}, "aggregation"), LT = /* @__PURE__ */ p((e, t, r) => {
  e.append("defs").append("marker").attr("id", r + "_" + t + "-dependencyStart").attr("class", "marker dependency " + t).attr("refX", 6).attr("refY", 7).attr("markerWidth", 190).attr("markerHeight", 240).attr("orient", "auto").append("path").attr("d", "M 5,7 L9,13 L1,7 L9,1 Z"), e.append("defs").append("marker").attr("id", r + "_" + t + "-dependencyEnd").attr("class", "marker dependency " + t).attr("refX", 13).attr("refY", 7).attr("markerWidth", 20).attr("markerHeight", 28).attr("orient", "auto").append("path").attr("d", "M 18,7 L9,13 L14,7 L9,1 Z"), e.append("defs").append("marker").attr("id", r + "_" + t + "-dependencyStart-margin").attr("class", "marker dependency " + t).attr("refX", 4).attr("refY", 7).attr("markerWidth", 190).attr("markerHeight", 240).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").append("path").style("stroke-width", 0).attr("d", "M 5,7 L9,13 L1,7 L9,1 Z"), e.append("defs").append("marker").attr("id", r + "_" + t + "-dependencyEnd-margin").attr("class", "marker dependency " + t).attr("refX", 16).attr("refY", 7).attr("markerWidth", 20).attr("markerHeight", 28).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").append("path").style("stroke-width", 0).attr("d", "M 18,7 L9,13 L14,7 L9,1 Z");
}, "dependency"), FT = /* @__PURE__ */ p((e, t, r) => {
  e.append("defs").append("marker").attr("id", r + "_" + t + "-lollipopStart").attr("class", "marker lollipop " + t).attr("refX", 13).attr("refY", 7).attr("markerWidth", 190).attr("markerHeight", 240).attr("orient", "auto").append("circle").attr("fill", "transparent").attr("cx", 7).attr("cy", 7).attr("r", 6), e.append("defs").append("marker").attr("id", r + "_" + t + "-lollipopEnd").attr("class", "marker lollipop " + t).attr("refX", 1).attr("refY", 7).attr("markerWidth", 190).attr("markerHeight", 240).attr("orient", "auto").append("circle").attr("fill", "transparent").attr("cx", 7).attr("cy", 7).attr("r", 6), e.append("defs").append("marker").attr("id", r + "_" + t + "-lollipopStart-margin").attr("class", "marker lollipop " + t).attr("refX", 13).attr("refY", 7).attr("markerWidth", 190).attr("markerHeight", 240).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").append("circle").attr("fill", "transparent").attr("cx", 7).attr("cy", 7).attr("r", 6).attr("stroke-width", 2), e.append("defs").append("marker").attr("id", r + "_" + t + "-lollipopEnd-margin").attr("class", "marker lollipop " + t).attr("refX", 1).attr("refY", 7).attr("markerWidth", 190).attr("markerHeight", 240).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").append("circle").attr("fill", "transparent").attr("cx", 7).attr("cy", 7).attr("r", 6).attr("stroke-width", 2);
}, "lollipop"), AT = /* @__PURE__ */ p((e, t, r) => {
  e.append("marker").attr("id", r + "_" + t + "-pointEnd").attr("class", "marker " + t).attr("viewBox", "0 0 10 10").attr("refX", 5).attr("refY", 5).attr("markerUnits", "userSpaceOnUse").attr("markerWidth", 8).attr("markerHeight", 8).attr("orient", "auto").append("path").attr("d", "M 0 0 L 10 5 L 0 10 z").attr("class", "arrowMarkerPath").style("stroke-width", 1).style("stroke-dasharray", "1,0"), e.append("marker").attr("id", r + "_" + t + "-pointStart").attr("class", "marker " + t).attr("viewBox", "0 0 10 10").attr("refX", 4.5).attr("refY", 5).attr("markerUnits", "userSpaceOnUse").attr("markerWidth", 8).attr("markerHeight", 8).attr("orient", "auto").append("path").attr("d", "M 0 5 L 10 10 L 10 0 z").attr("class", "arrowMarkerPath").style("stroke-width", 1).style("stroke-dasharray", "1,0"), e.append("marker").attr("id", r + "_" + t + "-pointEnd-margin").attr("class", "marker " + t).attr("viewBox", "0 0 11.5 14").attr("refX", 11.5).attr("refY", 7).attr("markerUnits", "userSpaceOnUse").attr("markerWidth", 10.5).attr("markerHeight", 14).attr("orient", "auto").append("path").attr("d", "M 0 0 L 11.5 7 L 0 14 z").attr("class", "arrowMarkerPath").style("stroke-width", 0).style("stroke-dasharray", "1,0"), e.append("marker").attr("id", r + "_" + t + "-pointStart-margin").attr("class", "marker " + t).attr("viewBox", "0 0 11.5 14").attr("refX", 1).attr("refY", 7).attr("markerUnits", "userSpaceOnUse").attr("markerWidth", 11.5).attr("markerHeight", 14).attr("orient", "auto").append("polygon").attr("points", "0,7 11.5,14 11.5,0").attr("class", "arrowMarkerPath").style("stroke-width", 0).style("stroke-dasharray", "1,0");
}, "point"), MT = /* @__PURE__ */ p((e, t, r) => {
  e.append("marker").attr("id", r + "_" + t + "-circleEnd").attr("class", "marker " + t).attr("viewBox", "0 0 10 10").attr("refX", 11).attr("refY", 5).attr("markerUnits", "userSpaceOnUse").attr("markerWidth", 11).attr("markerHeight", 11).attr("orient", "auto").append("circle").attr("cx", "5").attr("cy", "5").attr("r", "5").attr("class", "arrowMarkerPath").style("stroke-width", 1).style("stroke-dasharray", "1,0"), e.append("marker").attr("id", r + "_" + t + "-circleStart").attr("class", "marker " + t).attr("viewBox", "0 0 10 10").attr("refX", -1).attr("refY", 5).attr("markerUnits", "userSpaceOnUse").attr("markerWidth", 11).attr("markerHeight", 11).attr("orient", "auto").append("circle").attr("cx", "5").attr("cy", "5").attr("r", "5").attr("class", "arrowMarkerPath").style("stroke-width", 1).style("stroke-dasharray", "1,0"), e.append("marker").attr("id", r + "_" + t + "-circleEnd-margin").attr("class", "marker " + t).attr("viewBox", "0 0 10 10").attr("refY", 5).attr("refX", 12.25).attr("markerUnits", "userSpaceOnUse").attr("markerWidth", 14).attr("markerHeight", 14).attr("orient", "auto").append("circle").attr("cx", "5").attr("cy", "5").attr("r", "5").attr("class", "arrowMarkerPath").style("stroke-width", 0).style("stroke-dasharray", "1,0"), e.append("marker").attr("id", r + "_" + t + "-circleStart-margin").attr("class", "marker " + t).attr("viewBox", "0 0 10 10").attr("refX", -2).attr("refY", 5).attr("markerUnits", "userSpaceOnUse").attr("markerWidth", 14).attr("markerHeight", 14).attr("orient", "auto").append("circle").attr("cx", "5").attr("cy", "5").attr("r", "5").attr("class", "arrowMarkerPath").style("stroke-width", 0).style("stroke-dasharray", "1,0");
}, "circle"), ET = /* @__PURE__ */ p((e, t, r) => {
  e.append("marker").attr("id", r + "_" + t + "-crossEnd").attr("class", "marker cross " + t).attr("viewBox", "0 0 11 11").attr("refX", 12).attr("refY", 5.2).attr("markerUnits", "userSpaceOnUse").attr("markerWidth", 11).attr("markerHeight", 11).attr("orient", "auto").append("path").attr("d", "M 1,1 l 9,9 M 10,1 l -9,9").attr("class", "arrowMarkerPath").style("stroke-width", 2).style("stroke-dasharray", "1,0"), e.append("marker").attr("id", r + "_" + t + "-crossStart").attr("class", "marker cross " + t).attr("viewBox", "0 0 11 11").attr("refX", -1).attr("refY", 5.2).attr("markerUnits", "userSpaceOnUse").attr("markerWidth", 11).attr("markerHeight", 11).attr("orient", "auto").append("path").attr("d", "M 1,1 l 9,9 M 10,1 l -9,9").attr("class", "arrowMarkerPath").style("stroke-width", 2).style("stroke-dasharray", "1,0"), e.append("marker").attr("id", r + "_" + t + "-crossEnd-margin").attr("class", "marker cross " + t).attr("viewBox", "0 0 15 15").attr("refX", 17.7).attr("refY", 7.5).attr("markerUnits", "userSpaceOnUse").attr("markerWidth", 12).attr("markerHeight", 12).attr("orient", "auto").append("path").attr("d", "M 1,1 L 14,14 M 1,14 L 14,1").attr("class", "arrowMarkerPath").style("stroke-width", 2.5), e.append("marker").attr("id", r + "_" + t + "-crossStart-margin").attr("class", "marker cross " + t).attr("viewBox", "0 0 15 15").attr("refX", -3.5).attr("refY", 7.5).attr("markerUnits", "userSpaceOnUse").attr("markerWidth", 12).attr("markerHeight", 12).attr("orient", "auto").append("path").attr("d", "M 1,1 L 14,14 M 1,14 L 14,1").attr("class", "arrowMarkerPath").style("stroke-width", 2.5).style("stroke-dasharray", "1,0");
}, "cross"), $T = /* @__PURE__ */ p((e, t, r) => {
  e.append("defs").append("marker").attr("id", r + "_" + t + "-barbEnd").attr("refX", 19).attr("refY", 7).attr("markerWidth", 20).attr("markerHeight", 14).attr("markerUnits", "userSpaceOnUse").attr("orient", "auto").append("path").attr("d", "M 19,7 L9,13 L14,7 L9,1 Z");
}, "barb"), OT = /* @__PURE__ */ p((e, t, r) => {
  const i = Tt(), { themeVariables: s } = i, { transitionColor: o } = s;
  e.append("defs").append("marker").attr("id", r + "_" + t + "-barbEnd").attr("refX", 19).attr("refY", 7).attr("markerWidth", 20).attr("markerHeight", 14).attr("markerUnits", "strokeWidth").attr("orient", "auto").append("path").attr("d", "M 19,7 L11,14 L13,7 L11,0 Z"), e.append("defs").append("marker").attr("id", r + "_" + t + "-barbEnd-margin").attr("refX", 17).attr("refY", 7).attr("markerWidth", 20).attr("markerHeight", 14).attr("markerUnits", "userSpaceOnUse").attr("orient", "auto").append("path").attr("d", "M 19,7 L11,14 L13,7 L11,0 Z").attr("fill", `${o}`);
}, "barbNeo"), IT = /* @__PURE__ */ p((e, t, r) => {
  e.append("defs").append("marker").attr("id", r + "_" + t + "-onlyOneStart").attr("class", "marker onlyOne " + t).attr("refX", 0).attr("refY", 9).attr("markerWidth", 18).attr("markerHeight", 18).attr("orient", "auto").append("path").attr("d", "M9,0 L9,18 M15,0 L15,18"), e.append("defs").append("marker").attr("id", r + "_" + t + "-onlyOneEnd").attr("class", "marker onlyOne " + t).attr("refX", 18).attr("refY", 9).attr("markerWidth", 18).attr("markerHeight", 18).attr("orient", "auto").append("path").attr("d", "M3,0 L3,18 M9,0 L9,18");
}, "only_one"), DT = /* @__PURE__ */ p((e, t, r) => {
  const i = e.append("defs").append("marker").attr("id", r + "_" + t + "-zeroOrOneStart").attr("class", "marker zeroOrOne " + t).attr("refX", 0).attr("refY", 9).attr("markerWidth", 30).attr("markerHeight", 18).attr("orient", "auto");
  i.append("circle").attr("fill", "white").attr("cx", 21).attr("cy", 9).attr("r", 6), i.append("path").attr("d", "M9,0 L9,18");
  const s = e.append("defs").append("marker").attr("id", r + "_" + t + "-zeroOrOneEnd").attr("class", "marker zeroOrOne " + t).attr("refX", 30).attr("refY", 9).attr("markerWidth", 30).attr("markerHeight", 18).attr("orient", "auto");
  s.append("circle").attr("fill", "white").attr("cx", 9).attr("cy", 9).attr("r", 6), s.append("path").attr("d", "M21,0 L21,18");
}, "zero_or_one"), RT = /* @__PURE__ */ p((e, t, r) => {
  e.append("defs").append("marker").attr("id", r + "_" + t + "-oneOrMoreStart").attr("class", "marker oneOrMore " + t).attr("refX", 18).attr("refY", 18).attr("markerWidth", 45).attr("markerHeight", 36).attr("orient", "auto").append("path").attr("d", "M0,18 Q 18,0 36,18 Q 18,36 0,18 M42,9 L42,27"), e.append("defs").append("marker").attr("id", r + "_" + t + "-oneOrMoreEnd").attr("class", "marker oneOrMore " + t).attr("refX", 27).attr("refY", 18).attr("markerWidth", 45).attr("markerHeight", 36).attr("orient", "auto").append("path").attr("d", "M3,9 L3,27 M9,18 Q27,0 45,18 Q27,36 9,18");
}, "one_or_more"), PT = /* @__PURE__ */ p((e, t, r) => {
  const i = e.append("defs").append("marker").attr("id", r + "_" + t + "-zeroOrMoreStart").attr("class", "marker zeroOrMore " + t).attr("refX", 18).attr("refY", 18).attr("markerWidth", 57).attr("markerHeight", 36).attr("orient", "auto");
  i.append("circle").attr("fill", "white").attr("cx", 48).attr("cy", 18).attr("r", 6), i.append("path").attr("d", "M0,18 Q18,0 36,18 Q18,36 0,18");
  const s = e.append("defs").append("marker").attr("id", r + "_" + t + "-zeroOrMoreEnd").attr("class", "marker zeroOrMore " + t).attr("refX", 39).attr("refY", 18).attr("markerWidth", 57).attr("markerHeight", 36).attr("orient", "auto");
  s.append("circle").attr("fill", "white").attr("cx", 9).attr("cy", 18).attr("r", 6), s.append("path").attr("d", "M21,18 Q39,0 57,18 Q39,36 21,18");
}, "zero_or_more"), NT = /* @__PURE__ */ p((e, t, r) => {
  const i = Tt(), { themeVariables: s } = i, { strokeWidth: o } = s;
  e.append("defs").append("marker").attr("id", r + "_" + t + "-onlyOneStart").attr("class", "marker onlyOne " + t).attr("refX", 0).attr("refY", 9).attr("markerWidth", 18).attr("markerHeight", 18).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").append("path").attr("d", "M9,0 L9,18 M15,0 L15,18").attr("stroke-width", `${o}`), e.append("defs").append("marker").attr("id", r + "_" + t + "-onlyOneEnd").attr("class", "marker onlyOne " + t).attr("refX", 18).attr("refY", 9).attr("markerWidth", 18).attr("markerHeight", 18).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").append("path").attr("d", "M3,0 L3,18 M9,0 L9,18").attr("stroke-width", `${o}`);
}, "only_one_neo"), qT = /* @__PURE__ */ p((e, t, r) => {
  const i = Tt(), { themeVariables: s } = i, { strokeWidth: o, mainBkg: a } = s, n = e.append("defs").append("marker").attr("id", r + "_" + t + "-zeroOrOneStart").attr("class", "marker zeroOrOne " + t).attr("refX", 0).attr("refY", 9).attr("markerWidth", 30).attr("markerHeight", 18).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse");
  n.append("circle").attr("fill", a ?? "white").attr("cx", 21).attr("cy", 9).attr("stroke-width", `${o}`).attr("r", 6), n.append("path").attr("d", "M9,0 L9,18").attr("stroke-width", `${o}`);
  const l = e.append("defs").append("marker").attr("id", r + "_" + t + "-zeroOrOneEnd").attr("class", "marker zeroOrOne " + t).attr("refX", 30).attr("refY", 9).attr("markerWidth", 30).attr("markerHeight", 18).attr("markerUnits", "userSpaceOnUse").attr("orient", "auto");
  l.append("circle").attr("fill", a ?? "white").attr("cx", 9).attr("cy", 9).attr("stroke-width", `${o}`).attr("r", 6), l.append("path").attr("d", "M21,0 L21,18").attr("stroke-width", `${o}`);
}, "zero_or_one_neo"), WT = /* @__PURE__ */ p((e, t, r) => {
  const i = Tt(), { themeVariables: s } = i, { strokeWidth: o } = s;
  e.append("defs").append("marker").attr("id", r + "_" + t + "-oneOrMoreStart").attr("class", "marker oneOrMore " + t).attr("refX", 18).attr("refY", 18).attr("markerWidth", 45).attr("markerHeight", 36).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").append("path").attr("d", "M0,18 Q 18,0 36,18 Q 18,36 0,18 M42,9 L42,27").attr("stroke-width", `${o}`), e.append("defs").append("marker").attr("id", r + "_" + t + "-oneOrMoreEnd").attr("class", "marker oneOrMore " + t).attr("refX", 27).attr("refY", 18).attr("markerWidth", 45).attr("markerHeight", 36).attr("markerUnits", "userSpaceOnUse").attr("orient", "auto").append("path").attr("d", "M3,9 L3,27 M9,18 Q27,0 45,18 Q27,36 9,18").attr("stroke-width", `${o}`);
}, "one_or_more_neo"), zT = /* @__PURE__ */ p((e, t, r) => {
  const i = Tt(), { themeVariables: s } = i, { strokeWidth: o, mainBkg: a } = s, n = e.append("defs").append("marker").attr("id", r + "_" + t + "-zeroOrMoreStart").attr("class", "marker zeroOrMore " + t).attr("refX", 18).attr("refY", 18).attr("markerWidth", 57).attr("markerHeight", 36).attr("markerUnits", "userSpaceOnUse").attr("orient", "auto");
  n.append("circle").attr("fill", a ?? "white").attr("cx", 45.5).attr("cy", 18).attr("r", 6).attr("stroke-width", `${o}`), n.append("path").attr("d", "M0,18 Q18,0 36,18 Q18,36 0,18").attr("stroke-width", `${o}`);
  const l = e.append("defs").append("marker").attr("id", r + "_" + t + "-zeroOrMoreEnd").attr("class", "marker zeroOrMore " + t).attr("refX", 39).attr("refY", 18).attr("markerWidth", 57).attr("markerHeight", 36).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse");
  l.append("circle").attr("fill", a ?? "white").attr("cx", 11).attr("cy", 18).attr("r", 6).attr("stroke-width", `${o}`), l.append("path").attr("d", "M21,18 Q39,0 57,18 Q39,36 21,18").attr("stroke-width", `${o}`);
}, "zero_or_more_neo"), HT = /* @__PURE__ */ p((e, t, r) => {
  e.append("defs").append("marker").attr("id", r + "_" + t + "-requirement_arrowEnd").attr("refX", 20).attr("refY", 10).attr("markerWidth", 20).attr("markerHeight", 20).attr("orient", "auto").append("path").attr(
    "d",
    `M0,0
      L20,10
      M20,10
      L0,20`
  );
}, "requirement_arrow"), YT = /* @__PURE__ */ p((e, t, r) => {
  const i = Tt(), { themeVariables: s } = i, { strokeWidth: o } = s;
  e.append("defs").append("marker").attr("id", r + "_" + t + "-requirement_arrowEnd").attr("refX", 20).attr("refY", 10).attr("markerWidth", 20).attr("markerHeight", 20).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").attr("stroke-width", `${o}`).attr("viewBox", "0 0 25 20").append("path").attr(
    "d",
    `M0,0
      L20,10
      M20,10
      L0,20`
  ).attr("stroke-linejoin", "miter");
}, "requirement_arrow_neo"), UT = /* @__PURE__ */ p((e, t, r) => {
  const i = e.append("defs").append("marker").attr("id", r + "_" + t + "-requirement_containsStart").attr("refX", 0).attr("refY", 10).attr("markerWidth", 20).attr("markerHeight", 20).attr("orient", "auto").append("g");
  i.append("circle").attr("cx", 10).attr("cy", 10).attr("r", 9).attr("fill", "none"), i.append("line").attr("x1", 1).attr("x2", 19).attr("y1", 10).attr("y2", 10), i.append("line").attr("y1", 1).attr("y2", 19).attr("x1", 10).attr("x2", 10);
}, "requirement_contains"), GT = /* @__PURE__ */ p((e, t, r) => {
  const i = Tt(), { themeVariables: s } = i, { strokeWidth: o } = s, a = e.append("defs").append("marker").attr("id", r + "_" + t + "-requirement_containsStart").attr("refX", 0).attr("refY", 10).attr("markerWidth", 20).attr("markerHeight", 20).attr("orient", "auto").attr("markerUnits", "userSpaceOnUse").append("g");
  a.append("circle").attr("cx", 10).attr("cy", 10).attr("r", 9).attr("fill", "none"), a.append("line").attr("x1", 1).attr("x2", 19).attr("y1", 10).attr("y2", 10), a.append("line").attr("y1", 1).attr("y2", 19).attr("x1", 10).attr("x2", 10), a.selectAll("*").attr("stroke-width", `${o}`);
}, "requirement_contains_neo"), jT = {
  extension: _T,
  composition: BT,
  aggregation: vT,
  dependency: LT,
  lollipop: FT,
  point: AT,
  circle: MT,
  cross: ET,
  barb: $T,
  barbNeo: OT,
  only_one: IT,
  zero_or_one: DT,
  one_or_more: RT,
  zero_or_more: PT,
  only_one_neo: NT,
  zero_or_one_neo: qT,
  one_or_more_neo: WT,
  zero_or_more_neo: zT,
  requirement_arrow: HT,
  requirement_contains: UT,
  requirement_arrow_neo: YT,
  requirement_contains_neo: GT
}, XT = ST, VT = {
  common: zi,
  getConfig: Tt,
  insertCluster: Gw,
  insertEdge: TT,
  insertEdgeLabel: yT,
  insertMarkers: XT,
  insertNode: Lg,
  interpolateToCurve: Rn,
  labelHelper: rt,
  log: P,
  positionEdgeLabel: CT
}, Ni = {}, Eg = /* @__PURE__ */ p((e) => {
  for (const t of e)
    Ni[t.name] = t;
}, "registerLayoutLoaders"), ZT = /* @__PURE__ */ p(() => {
  Eg([
    {
      name: "dagre",
      loader: /* @__PURE__ */ p(async () => await import("./dagre-BM42HDAG-DyfrzKXr.js"), "loader")
    },
    {
      name: "cose-bilkent",
      loader: /* @__PURE__ */ p(async () => await import("./cose-bilkent-S5V4N54A-B7FtS5C6.js"), "loader")
    }
  ]);
}, "registerDefaultLayoutLoaders");
ZT();
var Hv = /* @__PURE__ */ p(async (e, t) => {
  if (!(e.layoutAlgorithm in Ni))
    throw new Error(`Unknown layout algorithm: ${e.layoutAlgorithm}`);
  if (e.diagramId)
    for (const h of e.nodes) {
      const d = h.domId || h.id;
      h.domId = `${e.diagramId}-${d}`;
    }
  const r = Ni[e.layoutAlgorithm], i = await r.loader(), { theme: s, themeVariables: o } = e.config, { useGradient: a, gradientStart: n, gradientStop: l } = o, c = t.attr("id");
  if (t.append("defs").append("filter").attr("id", `${c}-drop-shadow`).attr("height", "130%").attr("width", "130%").append("feDropShadow").attr("dx", "4").attr("dy", "4").attr("stdDeviation", 0).attr("flood-opacity", "0.06").attr("flood-color", `${s?.includes("dark") ? "#FFFFFF" : "#000000"}`), t.append("defs").append("filter").attr("id", `${c}-drop-shadow-small`).attr("height", "150%").attr("width", "150%").append("feDropShadow").attr("dx", "2").attr("dy", "2").attr("stdDeviation", 0).attr("flood-opacity", "0.06").attr("flood-color", `${s?.includes("dark") ? "#FFFFFF" : "#000000"}`), a) {
    const h = t.append("linearGradient").attr("id", t.attr("id") + "-gradient").attr("gradientUnits", "objectBoundingBox").attr("x1", "0%").attr("y1", "0%").attr("x2", "100%").attr("y2", "0%");
    h.append("svg:stop").attr("offset", "0%").attr("stop-color", n).attr("stop-opacity", 1), h.append("svg:stop").attr("offset", "100%").attr("stop-color", l).attr("stop-opacity", 1);
  }
  return i.render(e, t, VT, {
    algorithm: r.algorithm
  });
}, "render"), Yv = /* @__PURE__ */ p((e = "", { fallback: t = "dagre" } = {}) => {
  if (e in Ni)
    return e;
  if (t in Ni)
    return P.warn(`Layout algorithm ${e} is not registered. Using ${t} as fallback.`), t;
  throw new Error(`Both layout algorithms ${e} and ${t} are not registered.`);
}, "getRegisteredLayoutAlgorithm"), sl = "comm", $g = "rule", Og = "decl", KT = "@media", QT = "@import", JT = "@supports", tS = "@namespace", Ja = "@keyframes", Ig = "@layer", eS = "@scope", rS = Math.abs, Li = String.fromCharCode;
function Dg(e) {
  return e.trim();
}
function tn(e, t, r) {
  return e.replace(t, r);
}
function Yr(e, t) {
  return e.charCodeAt(t) | 0;
}
function Kr(e, t, r) {
  return e.slice(t, r);
}
function Te(e) {
  return e.length;
}
function Rg(e) {
  return e.length;
}
function ps(e, t) {
  return t.push(e), e;
}
var To = 1, Qr = 1, Pg = 0, ae = 0, Ft = 0, ri = "";
function ol(e, t, r, i, s, o, a, n) {
  return { value: e, root: t, parent: r, type: i, props: s, children: o, line: To, column: Qr, length: a, return: "", siblings: n };
}
function iS() {
  return Ft;
}
function sS() {
  return Ft = ae > 0 ? Yr(ri, --ae) : 0, Qr--, Ft === 10 && (Qr = 1, To--), Ft;
}
function ge() {
  return Ft = ae < Pg ? Yr(ri, ae++) : 0, Qr++, Ft === 10 && (Qr = 1, To++), Ft;
}
function Ze() {
  return Yr(ri, ae);
}
function vs() {
  return ae;
}
function So(e, t) {
  return Kr(ri, e, t);
}
function qi(e) {
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
function oS(e) {
  return To = Qr = 1, Pg = Te(ri = e), ae = 0, [];
}
function aS(e) {
  return ri = "", e;
}
function ia(e) {
  return Dg(So(ae - 1, en(e === 91 ? e + 2 : e === 40 ? e + 1 : e)));
}
function nS(e) {
  for (; (Ft = Ze()) && Ft < 33; )
    ge();
  return qi(e) > 2 || qi(Ft) > 3 ? "" : " ";
}
function lS(e, t) {
  for (; --t && ge() && !(Ft < 48 || Ft > 102 || Ft > 57 && Ft < 65 || Ft > 70 && Ft < 97); )
    ;
  return So(e, vs() + (t < 6 && Ze() == 32 && ge() == 32));
}
function en(e) {
  for (; ge(); )
    switch (Ft) {
      // ] ) " '
      case e:
        return ae;
      // " '
      case 34:
      case 39:
        e !== 34 && e !== 39 && en(Ft);
        break;
      // (
      case 40:
        e === 41 && en(e);
        break;
      // \
      case 92:
        ge();
        break;
    }
  return ae;
}
function hS(e, t) {
  for (; ge() && e + Ft !== 57; )
    if (e + Ft === 84 && Ze() === 47)
      break;
  return "/*" + So(t, ae - 1) + "*" + Li(e === 47 ? e : ge());
}
function cS(e) {
  for (; !qi(Ze()); )
    ge();
  return So(e, ae);
}
function dS(e) {
  return aS(Ls("", null, null, null, [""], e = oS(e), 0, [0], e));
}
function Ls(e, t, r, i, s, o, a, n, l) {
  for (var c = 0, h = 0, d = a, f = 0, u = 0, g = 0, m = 1, y = 1, C = 1, b = 0, k = 0, T = "", S = s, _ = o, A = i, v = T; y; )
    switch (g = k, k = ge()) {
      // (
      case 40:
        g != 108 && Yr(v, d - 1) == 58 ? (b++, v += "(") : v += ia(k);
        break;
      // )
      case 41:
        b--, v += ")";
        break;
      // " ' [
      case 34:
      case 39:
      case 91:
        v += ia(k);
        break;
      // \t \n \r \s
      case 9:
      case 10:
      case 13:
      case 32:
        if (b > 0) {
          v += Li(k);
          break;
        }
        v += nS(g);
        break;
      // \
      case 92:
        v += lS(vs() - 1, 7);
        continue;
      // /
      case 47:
        switch (Ze()) {
          case 42:
          case 47:
            ps(uS(hS(ge(), vs()), t, r, l), l), (qi(g || 1) == 5 || qi(Ze() || 1) == 5) && Te(v) && Kr(v, -1, void 0) !== " " && (v += " ");
            break;
          default:
            v += "/";
        }
        break;
      // {
      case 123 * m:
        n[c++] = Te(v) * C;
      // } ; \0
      case 125 * m:
      case 59:
      case 0:
        if (b > 0 && k) {
          v += Li(k);
          break;
        }
        switch (k) {
          // \0 }
          case 0:
          case 125:
            y = 0;
          // ;
          case 59 + h:
            C == -1 && (v = tn(v, /\f/g, "")), u > 0 && (Te(v) - d || m === 0) && ps(u > 32 ? sc(v + ";", i, r, d - 1, l) : sc(tn(v, " ", "") + ";", i, r, d - 2, l), l);
            break;
          // @ ;
          case 59:
            v += ";";
          // { rule/at-rule
          default:
            if (ps(A = ic(v, t, r, c, h, s, n, T, S = [], _ = [], d, o), o), k === 123)
              if (h === 0)
                Ls(v, t, A, A, S, o, d, n, _);
              else {
                switch (f) {
                  // c(ontainer)
                  case 99:
                    if (Yr(v, 3) === 110) break;
                  // l(ayer)
                  case 108:
                    if (Yr(v, 2) === 97) break;
                  default:
                    h = 0;
                  // d(ocument) m(edia) s(upports)
                  case 100:
                  case 109:
                  case 115:
                }
                h ? Ls(e, A, A, i && ps(ic(e, A, A, 0, 0, s, n, T, s, S = [], d, _), _), s, _, d, n, i ? S : _) : Ls(v, A, A, A, [""], _, 0, n, _);
              }
        }
        c = h = u = 0, m = C = 1, T = v = "", d = a;
        break;
      // :
      case 58:
        d = 1 + Te(v), u = g;
      default:
        if (m < 1) {
          if (k == 123)
            --m;
          else if (k == 125 && m++ == 0 && sS() == 125)
            continue;
        }
        switch (v += Li(k), k * m) {
          // &
          case 38:
            C = h > 0 ? 1 : (v += "\f", -1);
            break;
          // ,
          case 44:
            if (b > 0) break;
            n[c++] = (Te(v) - 1) * C, C = 1;
            break;
          // @
          case 64:
            Ze() === 45 && (v += ia(ge())), f = Ze(), h = d = Te(T = v += cS(vs())), k++;
            break;
          // -
          case 45:
            g === 45 && Te(v) == 2 && (m = 0);
        }
    }
  return o;
}
function ic(e, t, r, i, s, o, a, n, l, c, h, d) {
  for (var f = s - 1, u = s === 0 ? o : [""], g = Rg(u), m = 0, y = 0, C = 0; m < i; ++m)
    for (var b = 0, k = Kr(e, f + 1, f = rS(y = a[m])), T = e; b < g; ++b)
      (T = Dg(y > 0 ? u[b] + " " + k : tn(k, /&\f/g, u[b]))) && (l[C++] = T);
  return ol(e, t, r, s === 0 ? $g : n, l, c, h, d);
}
function uS(e, t, r, i) {
  return ol(e, t, r, sl, Li(iS()), Kr(e, 2, -2), 0, i);
}
function sc(e, t, r, i, s) {
  return ol(e, t, r, Og, Kr(e, 0, i), Kr(e, i + 1, -1), i, s);
}
function rn(e, t) {
  for (var r = "", i = 0; i < e.length; i++)
    r += t(e[i], i, e, t) || "";
  return r;
}
function fS(e, t, r, i) {
  switch (e.type) {
    case Ig:
      if (e.children.length) break;
    case QT:
    case tS:
    case Og:
      return e.return = e.return || e.value;
    case sl:
      return "";
    case Ja:
      return e.return = e.value + "{" + rn(e.children, i) + "}";
    case $g:
      if (!Te(e.value = e.props.join(","))) return "";
  }
  return Te(r = rn(e.children, i)) ? e.return = e.value + "{" + r + "}" : "";
}
function pS(e) {
  var t = Rg(e);
  return function(r, i, s, o) {
    for (var a = "", n = 0; n < t; n++)
      a += e[n](r, i, s, o) || "";
    return a;
  };
}
var Ng = "c4", gS = /* @__PURE__ */ p((e) => /^\s*C4Context|C4Container|C4Component|C4Dynamic|C4Deployment/.test(e), "detector"), mS = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./c4Diagram-AAUBKEIU-CTxgmMuv.js");
  return { id: Ng, diagram: e };
}, "loader"), yS = {
  id: Ng,
  detector: gS,
  loader: mS
}, CS = yS, qg = "flowchart", xS = /* @__PURE__ */ p((e, t) => t?.flowchart?.defaultRenderer === "dagre-wrapper" || t?.flowchart?.defaultRenderer === "elk" ? !1 : /^\s*graph/.test(e), "detector"), bS = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./flowDiagram-I6XJVG4X-Bj113heQ.js");
  return { id: qg, diagram: e };
}, "loader"), kS = {
  id: qg,
  detector: xS,
  loader: bS
}, wS = kS, Wg = "flowchart-v2", TS = /* @__PURE__ */ p((e, t) => t?.flowchart?.defaultRenderer === "dagre-d3" ? !1 : (t?.flowchart?.defaultRenderer === "elk" && (t.layout = "elk"), /^\s*graph/.test(e) && t?.flowchart?.defaultRenderer === "dagre-wrapper" ? !0 : /^\s*flowchart/.test(e)), "detector"), SS = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./flowDiagram-I6XJVG4X-Bj113heQ.js");
  return { id: Wg, diagram: e };
}, "loader"), _S = {
  id: Wg,
  detector: TS,
  loader: SS
}, BS = _S, zg = "er", vS = /* @__PURE__ */ p((e) => /^\s*erDiagram/.test(e), "detector"), LS = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./erDiagram-TEJ5UH35-90KjDJaR.js");
  return { id: zg, diagram: e };
}, "loader"), FS = {
  id: zg,
  detector: vS,
  loader: LS
}, AS = FS, Hg = "gitGraph", MS = /* @__PURE__ */ p((e) => /^\s*gitGraph/.test(e), "detector"), ES = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./gitGraphDiagram-PVQCEYII-DFX6QdBH.js");
  return { id: Hg, diagram: e };
}, "loader"), $S = {
  id: Hg,
  detector: MS,
  loader: ES
}, OS = $S, Yg = "gantt", IS = /* @__PURE__ */ p((e) => /^\s*gantt/.test(e), "detector"), DS = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./ganttDiagram-6RSMTGT7-DaP27A93.js");
  return { id: Yg, diagram: e };
}, "loader"), RS = {
  id: Yg,
  detector: IS,
  loader: DS
}, PS = RS, Ug = "info", NS = /* @__PURE__ */ p((e) => /^\s*info/.test(e), "detector"), qS = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./infoDiagram-5YYISTIA-CedyRb4M.js");
  return { id: Ug, diagram: e };
}, "loader"), WS = {
  id: Ug,
  detector: NS,
  loader: qS
}, Gg = "pie", zS = /* @__PURE__ */ p((e) => /^\s*pie/.test(e), "detector"), HS = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./pieDiagram-4H26LBE5-Cdd8Rm_R.js");
  return { id: Gg, diagram: e };
}, "loader"), YS = {
  id: Gg,
  detector: zS,
  loader: HS
}, jg = "quadrantChart", US = /* @__PURE__ */ p((e) => /^\s*quadrantChart/.test(e), "detector"), GS = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./quadrantDiagram-W4KKPZXB-Clr-y7GI.js");
  return { id: jg, diagram: e };
}, "loader"), jS = {
  id: jg,
  detector: US,
  loader: GS
}, XS = jS, Xg = "xychart", VS = /* @__PURE__ */ p((e) => /^\s*xychart(-beta)?/.test(e), "detector"), ZS = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./xychartDiagram-2RQKCTM6-C9QuSfeC.js");
  return { id: Xg, diagram: e };
}, "loader"), KS = {
  id: Xg,
  detector: VS,
  loader: ZS
}, QS = KS, Vg = "requirement", JS = /* @__PURE__ */ p((e) => /^\s*requirement(Diagram)?/.test(e), "detector"), t_ = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./requirementDiagram-4Y6WPE33-BdVa3C2S.js");
  return { id: Vg, diagram: e };
}, "loader"), e_ = {
  id: Vg,
  detector: JS,
  loader: t_
}, r_ = e_, Zg = "sequence", i_ = /* @__PURE__ */ p((e) => /^\s*sequenceDiagram/.test(e), "detector"), s_ = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./sequenceDiagram-3UESZ5HK-DnhM7IMS.js");
  return { id: Zg, diagram: e };
}, "loader"), o_ = {
  id: Zg,
  detector: i_,
  loader: s_
}, a_ = o_, Kg = "class", n_ = /* @__PURE__ */ p((e, t) => t?.class?.defaultRenderer === "dagre-wrapper" ? !1 : /^\s*classDiagram/.test(e), "detector"), l_ = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./classDiagram-4FO5ZUOK-DibtwnCR.js");
  return { id: Kg, diagram: e };
}, "loader"), h_ = {
  id: Kg,
  detector: n_,
  loader: l_
}, c_ = h_, Qg = "classDiagram", d_ = /* @__PURE__ */ p((e, t) => /^\s*classDiagram/.test(e) && t?.class?.defaultRenderer === "dagre-wrapper" ? !0 : /^\s*classDiagram-v2/.test(e), "detector"), u_ = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./classDiagram-v2-Q7XG4LA2-DibtwnCR.js");
  return { id: Qg, diagram: e };
}, "loader"), f_ = {
  id: Qg,
  detector: d_,
  loader: u_
}, p_ = f_, Jg = "state", g_ = /* @__PURE__ */ p((e, t) => t?.state?.defaultRenderer === "dagre-wrapper" ? !1 : /^\s*stateDiagram/.test(e), "detector"), m_ = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./stateDiagram-AJRCARHV-GzeTGfIQ.js");
  return { id: Jg, diagram: e };
}, "loader"), y_ = {
  id: Jg,
  detector: g_,
  loader: m_
}, C_ = y_, tm = "stateDiagram", x_ = /* @__PURE__ */ p((e, t) => !!(/^\s*stateDiagram-v2/.test(e) || /^\s*stateDiagram/.test(e) && t?.state?.defaultRenderer === "dagre-wrapper"), "detector"), b_ = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./stateDiagram-v2-BHNVJYJU-BSm6TWAV.js");
  return { id: tm, diagram: e };
}, "loader"), k_ = {
  id: tm,
  detector: x_,
  loader: b_
}, w_ = k_, em = "journey", T_ = /* @__PURE__ */ p((e) => /^\s*journey/.test(e), "detector"), S_ = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./journeyDiagram-JHISSGLW-cravMGgb.js");
  return { id: em, diagram: e };
}, "loader"), __ = {
  id: em,
  detector: T_,
  loader: S_
}, B_ = __, v_ = /* @__PURE__ */ p((e, t, r) => {
  P.debug(`rendering svg for syntax error
`);
  const i = hk(t), s = i.append("g");
  i.attr("viewBox", "0 0 2412 512"), Mc(i, 100, 512, !0), s.append("path").attr("class", "error-icon").attr(
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
}, "draw"), rm = { draw: v_ }, L_ = rm, F_ = {
  db: {},
  renderer: rm,
  parser: {
    parse: /* @__PURE__ */ p(() => {
    }, "parse")
  }
}, A_ = F_, im = "flowchart-elk", M_ = /* @__PURE__ */ p((e, t = {}) => (
  // If diagram explicitly states flowchart-elk
  /^\s*flowchart-elk/.test(e) || // If a flowchart/graph diagram has their default renderer set to elk
  /^\s*(flowchart|graph)/.test(e) && t?.flowchart?.defaultRenderer === "elk" ? (t.layout = "elk", !0) : !1
), "detector"), E_ = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./flowDiagram-I6XJVG4X-Bj113heQ.js");
  return { id: im, diagram: e };
}, "loader"), $_ = {
  id: im,
  detector: M_,
  loader: E_
}, O_ = $_, sm = "timeline", I_ = /* @__PURE__ */ p((e) => /^\s*timeline/.test(e), "detector"), D_ = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./timeline-definition-PNZ67QCA-BhOBuke8.js");
  return { id: sm, diagram: e };
}, "loader"), R_ = {
  id: sm,
  detector: I_,
  loader: D_
}, P_ = R_, om = "mindmap", N_ = /* @__PURE__ */ p((e) => /^\s*mindmap/.test(e), "detector"), q_ = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./mindmap-definition-RKZ34NQL-LGqBYL8K.js");
  return { id: om, diagram: e };
}, "loader"), W_ = {
  id: om,
  detector: N_,
  loader: q_
}, z_ = W_, am = "kanban", H_ = /* @__PURE__ */ p((e) => /^\s*kanban/.test(e), "detector"), Y_ = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./kanban-definition-UN3LZRKU-BPM9GFPR.js");
  return { id: am, diagram: e };
}, "loader"), U_ = {
  id: am,
  detector: H_,
  loader: Y_
}, G_ = U_, nm = "sankey", j_ = /* @__PURE__ */ p((e) => /^\s*sankey(-beta)?/.test(e), "detector"), X_ = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./sankeyDiagram-5OEKKPKP--bYa-o5n.js");
  return { id: nm, diagram: e };
}, "loader"), V_ = {
  id: nm,
  detector: j_,
  loader: X_
}, Z_ = V_, lm = "packet", K_ = /* @__PURE__ */ p((e) => /^\s*packet(-beta)?/.test(e), "detector"), Q_ = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./diagram-LMA3HP47-m2nZarZy.js");
  return { id: lm, diagram: e };
}, "loader"), J_ = {
  id: lm,
  detector: K_,
  loader: Q_
}, hm = "radar", tB = /* @__PURE__ */ p((e) => /^\s*radar-beta/.test(e), "detector"), eB = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./diagram-2AECGRRQ-ltvfYbS8.js");
  return { id: hm, diagram: e };
}, "loader"), rB = {
  id: hm,
  detector: tB,
  loader: eB
}, cm = "block", iB = /* @__PURE__ */ p((e) => /^\s*block(-beta)?/.test(e), "detector"), sB = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./blockDiagram-GPEHLZMM-CXzdPkfm.js");
  return { id: cm, diagram: e };
}, "loader"), oB = {
  id: cm,
  detector: iB,
  loader: sB
}, aB = oB, dm = "treeView", nB = /* @__PURE__ */ p((e) => /^\s*treeView-beta/.test(e), "detector"), lB = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./diagram-5GNKFQAL-Bc-PVrmA.js");
  return { id: dm, diagram: e };
}, "loader"), hB = {
  id: dm,
  detector: nB,
  loader: lB
}, cB = hB, um = "architecture", dB = /* @__PURE__ */ p((e) => /^\s*architecture/.test(e), "detector"), uB = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./architectureDiagram-3BPJPVTR-BY0CigTr.js");
  return { id: um, diagram: e };
}, "loader"), fB = {
  id: um,
  detector: dB,
  loader: uB
}, pB = fB, fm = "eventmodeling", gB = /* @__PURE__ */ p((e) => /^\s*eventmodeling/.test(e), "detector"), mB = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./diagram-KO2AKTUF-AnsDy_s7.js");
  return { id: fm, diagram: e };
}, "loader"), yB = {
  id: fm,
  detector: gB,
  loader: mB
}, CB = yB, pm = "ishikawa", xB = /* @__PURE__ */ p((e) => /^\s*ishikawa(-beta)?\b/i.test(e), "detector"), bB = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./ishikawaDiagram-YF4QCWOH-CiiBUUql.js");
  return { id: pm, diagram: e };
}, "loader"), kB = {
  id: pm,
  detector: xB,
  loader: bB
}, gm = "venn", wB = /* @__PURE__ */ p((e) => /^\s*venn-beta/.test(e), "detector"), TB = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./vennDiagram-CIIHVFJN-7Te4RaTP.js");
  return { id: gm, diagram: e };
}, "loader"), SB = {
  id: gm,
  detector: wB,
  loader: TB
}, _B = SB, mm = "treemap", BB = /* @__PURE__ */ p((e) => /^\s*treemap/.test(e), "detector"), vB = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./diagram-OG6HWLK6-DV_6aBCz.js");
  return { id: mm, diagram: e };
}, "loader"), LB = {
  id: mm,
  detector: BB,
  loader: vB
}, ym = "wardley-beta", FB = /* @__PURE__ */ p((e) => /^\s*wardley-beta/i.test(e), "detector"), AB = /* @__PURE__ */ p(async () => {
  const { diagram: e } = await import("./wardleyDiagram-YWT4CUSO-Dl6_QOWf.js");
  return { id: ym, diagram: e };
}, "loader"), MB = {
  id: ym,
  detector: FB,
  loader: AB
}, EB = MB, oc = !1, _o = /* @__PURE__ */ p(() => {
  oc || (oc = !0, $s("error", A_, (e) => e.toLowerCase().trim() === "error"), $s(
    "---",
    // --- diagram type may appear if YAML front-matter is not parsed correctly
    {
      db: {
        clear: /* @__PURE__ */ p(() => {
        }, "clear")
      },
      styles: {},
      // should never be used
      renderer: {
        draw: /* @__PURE__ */ p(() => {
        }, "draw")
      },
      parser: {
        parse: /* @__PURE__ */ p(() => {
          throw new Error(
            "Diagrams beginning with --- are not valid. If you were trying to use a YAML front-matter, please ensure that you've correctly opened and closed the YAML front-matter with un-indented `---` blocks"
          );
        }, "parse")
      },
      init: /* @__PURE__ */ p(() => null, "init")
      // no op
    },
    (e) => e.toLowerCase().trimStart().startsWith("---")
  ), na(O_, z_, pB), na(
    CS,
    G_,
    p_,
    c_,
    AS,
    PS,
    WS,
    YS,
    r_,
    a_,
    BS,
    wS,
    P_,
    OS,
    w_,
    C_,
    B_,
    XS,
    Z_,
    J_,
    QS,
    aB,
    CB,
    cB,
    rB,
    kB,
    LB,
    _B,
    EB
  ));
}, "addDiagrams"), $B = /* @__PURE__ */ p(async () => {
  P.debug("Loading registered diagrams");
  const t = (await Promise.allSettled(
    Object.entries(mr).map(async ([r, { detector: i, loader: s }]) => {
      if (s)
        try {
          ua(r);
        } catch {
          try {
            const { diagram: o, id: a } = await s();
            $s(a, o, i);
          } catch (o) {
            throw P.error(`Failed to load external diagram with key ${r}. Removing from detectors.`), delete mr[r], o;
          }
        }
    })
  )).filter((r) => r.status === "rejected");
  if (t.length > 0) {
    P.error(`Failed to load ${t.length} external diagrams`);
    for (const r of t)
      P.error(r);
    throw new Error(`Failed to load ${t.length} external diagrams`);
  }
}, "loadRegisteredDiagrams"), OB = "graphics-document document";
function Cm(e, t) {
  e.attr("role", OB), t !== "" && e.attr("aria-roledescription", t);
}
p(Cm, "setA11yDiagramInfo");
function xm(e, t, r, i) {
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
p(xm, "addSVGa11yTitleDescription");
var sn = class bm {
  constructor(t, r, i, s, o) {
    this.type = t, this.text = r, this.db = i, this.parser = s, this.renderer = o;
  }
  static {
    p(this, "Diagram");
  }
  static async fromText(t, r = {}) {
    const i = Tt(), s = nn(t, i);
    t = u2(t) + `
`;
    try {
      ua(s);
    } catch {
      const c = Fy(s);
      if (!c)
        throw new mc(`Diagram ${s} not found.`);
      const { id: h, diagram: d } = await c();
      $s(h, d);
    }
    const { db: o, parser: a, renderer: n, init: l } = ua(s);
    return a.parser && (a.parser.yy = o), o.clear?.(), l?.(i), r.title && o.setDiagramTitle?.(r.title), await a.parse(t), new bm(s, t, o, a, n);
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
}, ac = [], IB = /* @__PURE__ */ p(() => {
  ac.forEach((e) => {
    e();
  }), ac = [];
}, "attachFunctions"), DB = /* @__PURE__ */ p((e) => e.replace(/^\s*%%(?!{)[^\n]+\n?/gm, "").trimStart(), "cleanupComments");
function km(e) {
  const t = e.match(gc);
  if (!t)
    return {
      text: e,
      metadata: {}
    };
  let r = m1(t[1], {
    // To support config, we need JSON schema.
    // https://www.yaml.org/spec/1.2/spec.html#id2803231
    schema: g1
  }) ?? {};
  r = typeof r == "object" && !Array.isArray(r) ? r : {};
  const i = {};
  return r.displayMode && (i.displayMode = r.displayMode.toString()), r.title && (i.title = r.title.toString()), r.config && (i.config = r.config), {
    text: e.slice(t[0].length),
    metadata: i
  };
}
p(km, "extractFrontMatter");
var RB = /* @__PURE__ */ p((e) => e.replace(/\r\n?/g, `
`).replace(
  /<(\w+)([^>]*)>/g,
  (t, r, i) => "<" + r + i.replace(/="([^"]*)"/g, "='$1'") + ">"
), "cleanupText"), PB = /* @__PURE__ */ p((e) => {
  const { text: t, metadata: r } = km(e), { displayMode: i, title: s, config: o = {} } = r;
  return i && (o.gantt || (o.gantt = {}), o.gantt.displayMode = i), { title: s, config: o, text: t };
}, "processFrontmatter"), NB = /* @__PURE__ */ p((e) => {
  const t = fe.detectInit(e) ?? {}, r = fe.detectDirective(e, "wrap");
  return Array.isArray(r) ? t.wrap = r.some(({ type: i }) => i === "wrap") : r?.type === "wrap" && (t.wrap = !0), {
    text: J1(e),
    directive: t
  };
}, "processDirectives");
function al(e) {
  const t = RB(e), r = PB(t), i = NB(r.text), s = zn(r.config, i.directive);
  return e = DB(i.text), {
    code: e,
    title: r.title,
    config: s
  };
}
p(al, "preprocessDiagram");
function wm(e) {
  const t = new TextEncoder().encode(e), r = Array.from(t, (i) => String.fromCodePoint(i)).join("");
  return btoa(r);
}
p(wm, "toBase64");
var qB = 5e4, WB = "graph TB;a[Maximum text size in diagram exceeded];style a fill:#faa", zB = "sandbox", HB = "loose", YB = "http://www.w3.org/2000/svg", UB = "http://www.w3.org/1999/xlink", GB = "http://www.w3.org/1999/xhtml", jB = "100%", XB = "100%", VB = "border:0;margin:0;", ZB = "margin:0", KB = "allow-top-navigation-by-user-activation allow-popups", QB = 'The "iframe" tag is not supported by your browser.', JB = ["foreignobject"], tv = ["dominant-baseline"];
function nl(e) {
  const t = al(e);
  return Ms(), r0(t.config ?? {}), t;
}
p(nl, "processAndSetConfigs");
async function Tm(e, t) {
  _o();
  try {
    const { code: r, config: i } = nl(e);
    return { diagramType: (await _m(r)).type, config: i };
  } catch (r) {
    if (t?.suppressErrors)
      return !1;
    throw r;
  }
}
p(Tm, "parse");
var nc = /* @__PURE__ */ p((e, t, r = []) => {
  const i = kc(`{ ${r.join(" !important; ")} !important; }`);
  return `.${e} ${t} ${i}`;
}, "cssImportantStyles"), ev = /* @__PURE__ */ p((e, t = /* @__PURE__ */ new Map()) => {
  const r = new CSSStyleSheet();
  if (e.fontFamily !== void 0 && r.insertRule(
    `:root { --mermaid-font-family: ${e.fontFamily}}`,
    r.cssRules.length
  ), e.altFontFamily !== void 0 && r.insertRule(
    `:root { --mermaid-alt-font-family: ${e.altFontFamily}}`,
    r.cssRules.length
  ), t instanceof Map) {
    const n = Vt(e) ? ["> *", "span"] : ["rect", "polygon", "ellipse", "circle", "path"];
    t.forEach((l) => {
      kh(l.styles) || n.forEach((c) => {
        r.insertRule(
          nc(l.id, c, l.styles),
          r.cssRules.length
        );
      }), kh(l.textStyles) || r.insertRule(
        nc(
          l.id,
          "tspan",
          (l?.textStyles || []).map((c) => c.replace("color", "fill"))
        ),
        r.cssRules.length
      );
    });
  }
  let i = "";
  if (e.themeCSS !== void 0)
    if (typeof r.replaceSync == "function") {
      const s = new CSSStyleSheet();
      s.replaceSync(e.themeCSS), i = da(s) + `
`;
    } else
      i += `${e.themeCSS}
`;
  return i + da(r);
}, "createCssStyles"), rv = /* @__PURE__ */ p((e, t) => rn(
  dS(`${e}{${t}}`),
  pS([
    /* @__PURE__ */ p(function(i, s, o, a) {
      if (i.type === "rule" && Array.isArray(i.props)) {
        if (i.parent && i.parent.type === Ja)
          return;
        i.props = i.props.map((n) => n.startsWith(e) ? n : `${e} ${n}`);
      } else i.type.startsWith("@") && ([
        ...[
          KT,
          JT,
          Ig,
          eS,
          "@container",
          "@starting-style"
        ],
        Ja
        // needed for Mermaid's animation feature
      ].includes(i.type) || (P.warn(`Removing unsupported at-rule ${i.type} from CSS`), i.type = sl));
    }, "addNamespace"),
    fS
  ])
), "compileCSS"), iv = /* @__PURE__ */ p((e, t, r, i) => {
  const s = ev(e, r), o = k0(
    t,
    s,
    { ...e.themeVariables, theme: e.theme, look: e.look },
    i
  );
  return rv(i, o);
}, "createUserStyles"), sv = /* @__PURE__ */ p((e = "", t, r) => {
  let i = e;
  return !r && !t && (i = i.replace(
    /marker-end="url\([\d+./:=?A-Za-z-]*?#/g,
    'marker-end="url(#'
  )), i = br(i), i = i.replace(/<br>/g, "<br/>"), i;
}, "cleanUpSvgCode"), ov = /* @__PURE__ */ p((e = "", t) => {
  const r = t?.viewBox?.baseVal?.height ? t.viewBox.baseVal.height + "px" : XB, i = wm(`<body style="${ZB}">${e}</body>`);
  return `<iframe style="width:${jB};height:${r};${VB}" src="data:text/html;charset=UTF-8;base64,${i}" sandbox="${KB}">
  ${QB}
</iframe>`;
}, "putIntoIFrame"), lc = /* @__PURE__ */ p((e, t, r, i, s) => {
  const o = e.append("div");
  o.attr("id", r), i && o.attr("style", i);
  const a = o.append("svg").attr("id", t).attr("width", "100%").attr("xmlns", YB);
  return s && a.attr("xmlns:xlink", s), a.append("g"), e;
}, "appendDivSvgG");
function on(e, t) {
  return e.append("iframe").attr("id", t).attr("style", "width: 100%; height: 100%;").attr("sandbox", "");
}
p(on, "sandboxedIframe");
var av = /* @__PURE__ */ p((e, t, r, i) => {
  e.getElementById(t)?.remove(), e.getElementById(r)?.remove(), e.getElementById(i)?.remove();
}, "removeExistingElements"), nv = /* @__PURE__ */ p(async function(e, t, r) {
  _o();
  const i = nl(t);
  t = i.code;
  const s = Tt();
  P.debug(s), t.length > (s?.maxTextSize ?? qB) && (t = WB);
  const o = `#${e}`, a = "i" + e, n = "#" + a, l = "d" + e, c = "#" + l, h = /* @__PURE__ */ p(() => {
    const W = ht(f ? n : c).node();
    W && "remove" in W && W.remove();
  }, "removeTempElements");
  let d = ht(document.body);
  const f = s.securityLevel === zB, u = s.securityLevel === HB, g = s.fontFamily;
  if (r !== void 0) {
    if (r && (r.innerHTML = ""), f) {
      const H = on(ht(r), a);
      d = ht(H.nodes()[0].contentDocument.body), d.node().style.margin = "0";
    } else
      d = ht(r);
    lc(d, e, l, `font-family: ${g}`, UB);
  } else {
    if (av(document, e, l, a), f) {
      const H = on(ht(document.body), a);
      d = ht(H.nodes()[0].contentDocument.body), d.node().style.margin = "0";
    } else
      d = ht("body");
    lc(d, e, l);
  }
  let m, y;
  try {
    m = await sn.fromText(t, { title: i.title });
  } catch (H) {
    if (s.suppressErrorRendering)
      throw h(), H;
    m = await sn.fromText("error"), y = H;
  }
  const C = d.select(c).node(), b = m.type, k = C.firstChild, T = k.firstChild, S = m.renderer.getClasses?.(t, m), _ = iv(s, b, S, o), A = document.createElement("style");
  A.innerHTML = _, k.insertBefore(A, T);
  try {
    await m.renderer.draw(t, e, "11.15.0", m);
  } catch (H) {
    throw s.suppressErrorRendering ? h() : L_.draw(t, e, "11.15.0"), H;
  }
  const v = d.select(`${c} svg`), q = m.db.getAccTitle?.(), I = m.db.getAccDescription?.();
  Bm(b, v, q, I), d.select(`[id="${e}"]`).selectAll("foreignobject > *").attr("xmlns", GB);
  let R = d.select(c).node().innerHTML;
  if (P.debug("config.arrowMarkerAbsolute", s.arrowMarkerAbsolute), R = sv(R, f, ze(s.arrowMarkerAbsolute)), f) {
    const H = d.select(c + " svg").node();
    R = ov(R, H);
  } else u || (R = Ur.sanitize(R, {
    ADD_TAGS: JB,
    ADD_ATTR: tv,
    HTML_INTEGRATION_POINTS: { foreignobject: !0 }
  }));
  if (IB(), y)
    throw y;
  return h(), {
    diagramType: b,
    svg: R,
    bindFunctions: m.db.bindFunctions
  };
}, "render");
function Sm(e = {}) {
  const t = $t({}, e);
  t?.fontFamily && !t.themeVariables?.fontFamily && (t.themeVariables || (t.themeVariables = {}), t.themeVariables.fontFamily = t.fontFamily), t0(t), t?.theme && t.theme in Re ? t.themeVariables = Re[t.theme].getThemeVariables(
    t.themeVariables
  ) : t && (t.themeVariables = Re.default.getThemeVariables(t.themeVariables));
  const r = typeof t == "object" ? Jy(t) : wc();
  an(r.logLevel), _o();
}
p(Sm, "initialize");
var _m = /* @__PURE__ */ p((e, t = {}) => {
  const { code: r } = al(e);
  return sn.fromText(r, t);
}, "getDiagramFromText");
function Bm(e, t, r, i) {
  Cm(t, e), xm(t, r, i, t.attr("id"));
}
p(Bm, "addA11yInfo");
var wr = Object.freeze({
  render: nv,
  parse: Tm,
  getDiagramFromText: _m,
  initialize: Sm,
  getConfig: Tt,
  setConfig: Tc,
  getSiteConfig: wc,
  updateSiteConfig: e0,
  reset: /* @__PURE__ */ p(() => {
    Ms();
  }, "reset"),
  globalReset: /* @__PURE__ */ p(() => {
    Ms(Gr);
  }, "globalReset"),
  defaultConfig: Gr
});
an(Tt().logLevel);
Ms(Tt());
var lv = /* @__PURE__ */ p((e, t, r) => {
  P.warn(e), Wn(e) ? (r && r(e.str, e.hash), t.push({ ...e, message: e.str, error: e })) : (r && r(e), e instanceof Error && t.push({
    str: e.message,
    message: e.message,
    hash: e.name,
    error: e
  }));
}, "handleError"), vm = /* @__PURE__ */ p(async function(e = {
  querySelector: ".mermaid"
}) {
  try {
    await hv(e);
  } catch (t) {
    if (Wn(t) && P.error(t.str), We.parseError && We.parseError(t), !e.suppressErrors)
      throw P.error("Use the suppressErrors option to suppress these errors"), t;
  }
}, "run"), hv = /* @__PURE__ */ p(async function({ postRenderCallback: e, querySelector: t, nodes: r } = {
  querySelector: ".mermaid"
}) {
  const i = wr.getConfig();
  P.debug(`${e ? "" : "No "}Callback function found`);
  let s;
  if (r)
    s = r;
  else if (t)
    s = document.querySelectorAll(t);
  else
    throw new Error("Nodes and querySelector are both undefined");
  P.debug(`Found ${s.length} diagrams`), i?.startOnLoad !== void 0 && (P.debug("Start On Load: " + i?.startOnLoad), wr.updateSiteConfig({ startOnLoad: i?.startOnLoad }));
  const o = new fe.InitIDGenerator(i.deterministicIds, i.deterministicIDSeed);
  let a;
  const n = [];
  for (const l of Array.from(s)) {
    if (P.info("Rendering diagram: " + l.id), l.getAttribute("data-processed"))
      continue;
    l.setAttribute("data-processed", "true");
    const c = `mermaid-${o.next()}`;
    a = l.innerHTML, a = qf(fe.entityDecode(a)).trim().replace(/<br\s*\/?>/gi, "<br/>");
    const h = fe.detectInit(a);
    h && P.debug("Detected early reinit: ", h);
    try {
      const { svg: d, bindFunctions: f } = await Mm(c, a, l);
      l.innerHTML = d, e && await e(c), f && f(l);
    } catch (d) {
      lv(d, n, We.parseError);
    }
  }
  if (n.length > 0)
    throw n[0];
}, "runThrowsErrors"), Lm = /* @__PURE__ */ p(function(e) {
  wr.initialize(e);
}, "initialize"), cv = /* @__PURE__ */ p(async function(e, t, r) {
  P.warn("mermaid.init is deprecated. Please use run instead."), e && Lm(e);
  const i = { postRenderCallback: r, querySelector: ".mermaid" };
  typeof t == "string" ? i.querySelector = t : t && (t instanceof HTMLElement ? i.nodes = [t] : i.nodes = t), await vm(i);
}, "init"), dv = /* @__PURE__ */ p(async (e, {
  lazyLoad: t = !0
} = {}) => {
  _o(), na(...e), t === !1 && await $B();
}, "registerExternalDiagrams"), Fm = /* @__PURE__ */ p(function() {
  if (We.startOnLoad) {
    const { startOnLoad: e } = wr.getConfig();
    e && We.run().catch((t) => P.error("Mermaid failed to initialize", t));
  }
}, "contentLoaded");
typeof document < "u" && window.addEventListener("load", Fm, !1);
var uv = /* @__PURE__ */ p(function(e) {
  We.parseError = e;
}, "setParseErrorHandler"), oo = [], sa = !1, Am = /* @__PURE__ */ p(async () => {
  if (!sa) {
    for (sa = !0; oo.length > 0; ) {
      const e = oo.shift();
      if (e)
        try {
          await e();
        } catch (t) {
          P.error("Error executing queue", t);
        }
    }
    sa = !1;
  }
}, "executeQueue"), fv = /* @__PURE__ */ p(async (e, t) => new Promise((r, i) => {
  const s = /* @__PURE__ */ p(() => new Promise((o, a) => {
    wr.parse(e, t).then(
      (n) => {
        o(n), r(n);
      },
      (n) => {
        P.error("Error parsing", n), We.parseError?.(n), a(n), i(n);
      }
    );
  }), "performCall");
  oo.push(s), Am().catch(i);
}), "parse"), Mm = /* @__PURE__ */ p((e, t, r) => new Promise((i, s) => {
  const o = /* @__PURE__ */ p(() => new Promise((a, n) => {
    wr.render(e, t, r).then(
      (l) => {
        a(l), i(l);
      },
      (l) => {
        P.error("Error parsing", l), We.parseError?.(l), n(l), s(l);
      }
    );
  }), "performCall");
  oo.push(o), Am().catch(s);
}), "render"), pv = /* @__PURE__ */ p(() => Object.keys(mr).map((e) => ({
  id: e
})), "getRegisteredDiagramsMetadata"), We = {
  startOnLoad: !0,
  mermaidAPI: wr,
  parse: fv,
  render: Mm,
  init: cv,
  run: vm,
  registerExternalDiagrams: dv,
  registerLayoutLoaders: Eg,
  initialize: Lm,
  parseError: void 0,
  contentLoaded: Fm,
  setParseErrorHandler: uv,
  detectType: nn,
  registerIconPacks: xw,
  getRegisteredDiagramsMetadata: pv
}, gv = We;
/*! Check if previously processed */
/*!
 * Wait for document loaded before starting the execution
 */
const Uv = /* @__PURE__ */ Object.freeze(/* @__PURE__ */ Object.defineProperty({
  __proto__: null,
  default: gv
}, Symbol.toStringTag, { value: "Module" }));
export {
  N1 as $,
  kw as A,
  li as B,
  _e as C,
  Bf as D,
  Mc as E,
  $r as F,
  mn as G,
  Sv as H,
  He as I,
  g1 as J,
  wa as K,
  O as L,
  A1 as M,
  _1 as N,
  Hm as O,
  br as P,
  bv as Q,
  ee as R,
  bc as S,
  gn as T,
  at as U,
  b1 as V,
  lh as W,
  Gc as X,
  P1 as Y,
  V1 as Z,
  Ym as _,
  Yi as a,
  hk as a$,
  i2 as a0,
  B0 as a1,
  S0 as a2,
  Tt as a3,
  gt as a4,
  L0 as a5,
  Ev as a6,
  Vt as a7,
  Xi as a8,
  y1 as a9,
  tk as aA,
  Wi as aB,
  m1 as aC,
  P as aD,
  B1 as aE,
  XT as aF,
  _v as aG,
  Uv as aH,
  Bv as aI,
  Vc as aJ,
  ff as aK,
  mf as aL,
  mo as aM,
  Hl as aN,
  bn as aO,
  CT as aP,
  Wv as aQ,
  Ur as aR,
  s2 as aS,
  T1 as aT,
  xw as aU,
  Hv as aV,
  Ac as aW,
  Tx as aX,
  Ke as aY,
  me as aZ,
  ht as a_,
  Yv as aa,
  wf as ab,
  Hn as ac,
  On as ad,
  Iy as ae,
  c0 as af,
  yv as ag,
  hh as ah,
  Fi as ai,
  kv as aj,
  Gw as ak,
  TT as al,
  yT as am,
  Lg as an,
  D1 as ao,
  R1 as ap,
  I1 as aq,
  Xe as ar,
  rh as as,
  Ax as at,
  ye as au,
  vf as av,
  $n as aw,
  Ts as ax,
  uT as ay,
  $ as az,
  p as b,
  _0 as b0,
  T0 as b1,
  xv as b2,
  v0 as b3,
  Nv as b4,
  v1 as b5,
  C0 as b6,
  A0 as b7,
  vv as b8,
  Lv as b9,
  uf as ba,
  Z as bb,
  S1 as bc,
  Fv as bd,
  $1 as be,
  O1 as bf,
  M1 as bg,
  E1 as bh,
  Cw as bi,
  K as bj,
  fe as bk,
  Zb as bl,
  n2 as bm,
  wv as c,
  Av as d,
  dc as e,
  gf as f,
  Kb as g,
  F1 as h,
  L1 as i,
  Mv as j,
  $t as k,
  j as l,
  Tv as m,
  pf as n,
  Cv as o,
  qn as p,
  Sf as q,
  qe as r,
  zn as s,
  w0 as t,
  zv as u,
  Pv as v,
  qv as w,
  Ei as x,
  Ec as y,
  zi as z
};
