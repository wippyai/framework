import { m as Ft, f as Dd, d as Md } from "./min-Ds2tR2xq.js";
import { b as Fd, l as Gd, c as jd, m as zd, r as Zl, n as hs } from "./_baseUniq-B0FPZyMQ.js";
import { ba as Ud } from "./mermaid.core-Jw3znkh4.js";
import { a as qd } from "./index.js";
function Bd(t, e) {
  return Fd(Ft(t, e));
}
function Wd(t, e) {
  return t && t.length ? Gd(t, jd(e)) : [];
}
function Fe(t) {
  return typeof t == "object" && t !== null && typeof t.$type == "string";
}
function ut(t) {
  return typeof t == "object" && t !== null && typeof t.$refText == "string" && "ref" in t;
}
function Jt(t) {
  return typeof t == "object" && t !== null && typeof t.$refText == "string" && "items" in t;
}
function Kd(t) {
  return typeof t == "object" && t !== null && typeof t.name == "string" && typeof t.type == "string" && typeof t.path == "string";
}
function Nn(t) {
  return typeof t == "object" && t !== null && typeof t.info == "object" && typeof t.message == "string";
}
class Qu {
  constructor() {
    this.subtypes = {}, this.allSubtypes = {};
  }
  getAllTypes() {
    return Object.keys(this.types);
  }
  getReferenceType(e) {
    const r = this.types[e.container.$type];
    if (!r)
      throw new Error(`Type ${e.container.$type || "undefined"} not found.`);
    const n = r.properties[e.property]?.referenceType;
    if (!n)
      throw new Error(`Property ${e.property || "undefined"} of type ${e.container.$type} is not a reference.`);
    return n;
  }
  getTypeMetaData(e) {
    const r = this.types[e];
    return r || {
      name: e,
      properties: {},
      superTypes: []
    };
  }
  isInstance(e, r) {
    return Fe(e) && this.isSubtype(e.$type, r);
  }
  isSubtype(e, r) {
    if (e === r)
      return !0;
    let n = this.subtypes[e];
    n || (n = this.subtypes[e] = {});
    const i = n[r];
    if (i !== void 0)
      return i;
    {
      const a = this.types[e], s = a ? a.superTypes.some((o) => this.isSubtype(o, r)) : !1;
      return n[r] = s, s;
    }
  }
  getAllSubTypes(e) {
    const r = this.allSubtypes[e];
    if (r)
      return r;
    {
      const n = this.getAllTypes(), i = [];
      for (const a of n)
        this.isSubtype(a, e) && i.push(a);
      return this.allSubtypes[e] = i, i;
    }
  }
}
function ci(t) {
  return typeof t == "object" && t !== null && Array.isArray(t.content);
}
function ef(t) {
  return typeof t == "object" && t !== null && typeof t.tokenType == "object";
}
function tf(t) {
  return ci(t) && typeof t.fullText == "string";
}
class xe {
  constructor(e, r) {
    this.startFn = e, this.nextFn = r;
  }
  iterator() {
    const e = {
      state: this.startFn(),
      next: () => this.nextFn(e.state),
      [Symbol.iterator]: () => e
    };
    return e;
  }
  [Symbol.iterator]() {
    return this.iterator();
  }
  isEmpty() {
    return !!this.iterator().next().done;
  }
  count() {
    const e = this.iterator();
    let r = 0, n = e.next();
    for (; !n.done; )
      r++, n = e.next();
    return r;
  }
  toArray() {
    const e = [], r = this.iterator();
    let n;
    do
      n = r.next(), n.value !== void 0 && e.push(n.value);
    while (!n.done);
    return e;
  }
  toSet() {
    return new Set(this);
  }
  toMap(e, r) {
    const n = this.map((i) => [
      e ? e(i) : i,
      r ? r(i) : i
    ]);
    return new Map(n);
  }
  toString() {
    return this.join();
  }
  concat(e) {
    return new xe(() => ({ first: this.startFn(), firstDone: !1, iterator: e[Symbol.iterator]() }), (r) => {
      let n;
      if (!r.firstDone) {
        do
          if (n = this.nextFn(r.first), !n.done)
            return n;
        while (!n.done);
        r.firstDone = !0;
      }
      do
        if (n = r.iterator.next(), !n.done)
          return n;
      while (!n.done);
      return Ze;
    });
  }
  join(e = ",") {
    const r = this.iterator();
    let n = "", i, a = !1;
    do
      i = r.next(), i.done || (a && (n += e), n += Vd(i.value)), a = !0;
    while (!i.done);
    return n;
  }
  indexOf(e, r = 0) {
    const n = this.iterator();
    let i = 0, a = n.next();
    for (; !a.done; ) {
      if (i >= r && a.value === e)
        return i;
      a = n.next(), i++;
    }
    return -1;
  }
  every(e) {
    const r = this.iterator();
    let n = r.next();
    for (; !n.done; ) {
      if (!e(n.value))
        return !1;
      n = r.next();
    }
    return !0;
  }
  some(e) {
    const r = this.iterator();
    let n = r.next();
    for (; !n.done; ) {
      if (e(n.value))
        return !0;
      n = r.next();
    }
    return !1;
  }
  forEach(e) {
    const r = this.iterator();
    let n = 0, i = r.next();
    for (; !i.done; )
      e(i.value, n), i = r.next(), n++;
  }
  map(e) {
    return new xe(this.startFn, (r) => {
      const { done: n, value: i } = this.nextFn(r);
      return n ? Ze : { done: !1, value: e(i) };
    });
  }
  filter(e) {
    return new xe(this.startFn, (r) => {
      let n;
      do
        if (n = this.nextFn(r), !n.done && e(n.value))
          return n;
      while (!n.done);
      return Ze;
    });
  }
  nonNullable() {
    return this.filter((e) => e != null);
  }
  reduce(e, r) {
    const n = this.iterator();
    let i = r, a = n.next();
    for (; !a.done; )
      i === void 0 ? i = a.value : i = e(i, a.value), a = n.next();
    return i;
  }
  reduceRight(e, r) {
    return this.recursiveReduce(this.iterator(), e, r);
  }
  recursiveReduce(e, r, n) {
    const i = e.next();
    if (i.done)
      return n;
    const a = this.recursiveReduce(e, r, n);
    return a === void 0 ? i.value : r(a, i.value);
  }
  find(e) {
    const r = this.iterator();
    let n = r.next();
    for (; !n.done; ) {
      if (e(n.value))
        return n.value;
      n = r.next();
    }
  }
  findIndex(e) {
    const r = this.iterator();
    let n = 0, i = r.next();
    for (; !i.done; ) {
      if (e(i.value))
        return n;
      i = r.next(), n++;
    }
    return -1;
  }
  includes(e) {
    const r = this.iterator();
    let n = r.next();
    for (; !n.done; ) {
      if (n.value === e)
        return !0;
      n = r.next();
    }
    return !1;
  }
  flatMap(e) {
    return new xe(() => ({ this: this.startFn() }), (r) => {
      do {
        if (r.iterator) {
          const a = r.iterator.next();
          if (a.done)
            r.iterator = void 0;
          else
            return a;
        }
        const { done: n, value: i } = this.nextFn(r.this);
        if (!n) {
          const a = e(i);
          if (Na(a))
            r.iterator = a[Symbol.iterator]();
          else
            return { done: !1, value: a };
        }
      } while (r.iterator);
      return Ze;
    });
  }
  flat(e) {
    if (e === void 0 && (e = 1), e <= 0)
      return this;
    const r = e > 1 ? this.flat(e - 1) : this;
    return new xe(() => ({ this: r.startFn() }), (n) => {
      do {
        if (n.iterator) {
          const s = n.iterator.next();
          if (s.done)
            n.iterator = void 0;
          else
            return s;
        }
        const { done: i, value: a } = r.nextFn(n.this);
        if (!i)
          if (Na(a))
            n.iterator = a[Symbol.iterator]();
          else
            return { done: !1, value: a };
      } while (n.iterator);
      return Ze;
    });
  }
  head() {
    const r = this.iterator().next();
    if (!r.done)
      return r.value;
  }
  tail(e = 1) {
    return new xe(() => {
      const r = this.startFn();
      for (let n = 0; n < e; n++)
        if (this.nextFn(r).done)
          return r;
      return r;
    }, this.nextFn);
  }
  limit(e) {
    return new xe(() => ({ size: 0, state: this.startFn() }), (r) => (r.size++, r.size > e ? Ze : this.nextFn(r.state)));
  }
  distinct(e) {
    return new xe(() => ({ set: /* @__PURE__ */ new Set(), internalState: this.startFn() }), (r) => {
      let n;
      do
        if (n = this.nextFn(r.internalState), !n.done) {
          const i = e ? e(n.value) : n.value;
          if (!r.set.has(i))
            return r.set.add(i), n;
        }
      while (!n.done);
      return Ze;
    });
  }
  exclude(e, r) {
    const n = /* @__PURE__ */ new Set();
    for (const i of e) {
      const a = r ? r(i) : i;
      n.add(a);
    }
    return this.filter((i) => {
      const a = r ? r(i) : i;
      return !n.has(a);
    });
  }
}
function Vd(t) {
  return typeof t == "string" ? t : typeof t > "u" ? "undefined" : typeof t.toString == "function" ? t.toString() : Object.prototype.toString.call(t);
}
function Na(t) {
  return !!t && typeof t[Symbol.iterator] == "function";
}
const rf = new xe(() => {
}, () => Ze), Ze = Object.freeze({ done: !0, value: void 0 });
function fe(...t) {
  if (t.length === 1) {
    const e = t[0];
    if (e instanceof xe)
      return e;
    if (Na(e))
      return new xe(() => e[Symbol.iterator](), (r) => r.next());
    if (typeof e.length == "number")
      return new xe(() => ({ index: 0 }), (r) => r.index < e.length ? { done: !1, value: e[r.index++] } : Ze);
  }
  return t.length > 1 ? new xe(() => ({ collIndex: 0, arrIndex: 0 }), (e) => {
    do {
      if (e.iterator) {
        const r = e.iterator.next();
        if (!r.done)
          return r;
        e.iterator = void 0;
      }
      if (e.array) {
        if (e.arrIndex < e.array.length)
          return { done: !1, value: e.array[e.arrIndex++] };
        e.array = void 0, e.arrIndex = 0;
      }
      if (e.collIndex < t.length) {
        const r = t[e.collIndex++];
        Na(r) ? e.iterator = r[Symbol.iterator]() : r && typeof r.length == "number" && (e.array = r);
      }
    } while (e.iterator || e.array || e.collIndex < t.length);
    return Ze;
  }) : rf;
}
class Nl extends xe {
  constructor(e, r, n) {
    super(() => ({
      iterators: n?.includeRoot ? [[e][Symbol.iterator]()] : [r(e)[Symbol.iterator]()],
      pruned: !1
    }), (i) => {
      for (i.pruned && (i.iterators.pop(), i.pruned = !1); i.iterators.length > 0; ) {
        const s = i.iterators[i.iterators.length - 1].next();
        if (s.done)
          i.iterators.pop();
        else
          return i.iterators.push(r(s.value)[Symbol.iterator]()), s;
      }
      return Ze;
    });
  }
  iterator() {
    const e = {
      state: this.startFn(),
      next: () => this.nextFn(e.state),
      prune: () => {
        e.state.pruned = !0;
      },
      [Symbol.iterator]: () => e
    };
    return e;
  }
}
var qs;
(function(t) {
  function e(a) {
    return a.reduce((s, o) => s + o, 0);
  }
  t.sum = e;
  function r(a) {
    return a.reduce((s, o) => s * o, 0);
  }
  t.product = r;
  function n(a) {
    return a.reduce((s, o) => Math.min(s, o));
  }
  t.min = n;
  function i(a) {
    return a.reduce((s, o) => Math.max(s, o));
  }
  t.max = i;
})(qs || (qs = {}));
function Bs(t, e = {}) {
  for (const [r, n] of Object.entries(t))
    r.startsWith("$") || (Array.isArray(n) ? n.forEach((i, a) => {
      Fe(i) && (i.$container = t, i.$containerProperty = r, i.$containerIndex = a, e.deep && Bs(i, e));
    }) : Fe(n) && (n.$container = t, n.$containerProperty = r, e.deep && Bs(n, e)));
}
function Ja(t, e) {
  let r = t;
  for (; r; ) {
    if (e(r))
      return r;
    r = r.$container;
  }
}
function Gt(t) {
  const r = pa(t).$document;
  if (!r)
    throw new Error("AST node has no document.");
  return r;
}
function pa(t) {
  for (; t.$container; )
    t = t.$container;
  return t;
}
function Ql(t) {
  return ut(t) ? t.ref ? [t.ref] : [] : Jt(t) ? t.items.map((e) => e.ref) : [];
}
function _l(t, e) {
  if (!t)
    throw new Error("Node must be an AstNode.");
  const r = e?.range;
  return new xe(() => ({
    keys: Object.keys(t),
    keyIndex: 0,
    arrayIndex: 0
  }), (n) => {
    for (; n.keyIndex < n.keys.length; ) {
      const i = n.keys[n.keyIndex];
      if (!i.startsWith("$")) {
        const a = t[i];
        if (Fe(a)) {
          if (n.keyIndex++, ec(a, r))
            return { done: !1, value: a };
        } else if (Array.isArray(a)) {
          for (; n.arrayIndex < a.length; ) {
            const s = n.arrayIndex++, o = a[s];
            if (Fe(o) && ec(o, r))
              return { done: !1, value: o };
          }
          n.arrayIndex = 0;
        }
      }
      n.keyIndex++;
    }
    return Ze;
  });
}
function Ei(t, e) {
  if (!t)
    throw new Error("Root node must be an AstNode.");
  return new Nl(t, (r) => _l(r, e));
}
function jt(t, e) {
  if (!t)
    throw new Error("Root node must be an AstNode.");
  return new Nl(t, (r) => _l(r, e), { includeRoot: !0 });
}
function ec(t, e) {
  if (!e)
    return !0;
  const r = t.$cstNode?.range;
  return r ? gh(r, e) : !1;
}
function _a(t) {
  return new xe(() => ({
    keys: Object.keys(t),
    keyIndex: 0,
    arrayIndex: 0
  }), (e) => {
    for (; e.keyIndex < e.keys.length; ) {
      const r = e.keys[e.keyIndex];
      if (!r.startsWith("$")) {
        const n = t[r];
        if (ut(n) || Jt(n))
          return e.keyIndex++, { done: !1, value: { reference: n, container: t, property: r } };
        if (Array.isArray(n)) {
          for (; e.arrayIndex < n.length; ) {
            const i = e.arrayIndex++, a = n[i];
            if (ut(a) || Jt(n))
              return { done: !1, value: { reference: a, container: t, property: r, index: i } };
          }
          e.arrayIndex = 0;
        }
      }
      e.keyIndex++;
    }
    return Ze;
  });
}
function Hd(t, e) {
  const r = t.getTypeMetaData(e.$type), n = e;
  for (const i of Object.values(r.properties))
    i.defaultValue !== void 0 && n[i.name] === void 0 && (n[i.name] = nf(i.defaultValue));
}
function nf(t) {
  return Array.isArray(t) ? [...t.map(nf)] : t;
}
const Je = {
  $type: "AbstractElement",
  cardinality: "cardinality"
};
function Xd(t) {
  return J.isInstance(t, Je.$type);
}
const ma = {
  $type: "AbstractParserRule"
};
function Ai(t) {
  return J.isInstance(t, ma.$type);
}
const Vi = {
  $type: "AbstractRule"
}, ot = {
  $type: "AbstractType"
}, Tr = {
  $type: "Action",
  cardinality: "cardinality",
  feature: "feature",
  inferredType: "inferredType",
  operator: "operator",
  type: "type"
};
function Za(t) {
  return J.isInstance(t, Tr.$type);
}
const ga = {
  $type: "Alternatives",
  cardinality: "cardinality",
  elements: "elements"
};
function af(t) {
  return J.isInstance(t, ga.$type);
}
const tc = {
  $type: "ArrayLiteral",
  elements: "elements"
}, rc = {
  $type: "ArrayType",
  elementType: "elementType"
}, Rr = {
  $type: "Assignment",
  cardinality: "cardinality",
  feature: "feature",
  operator: "operator",
  predicate: "predicate",
  terminal: "terminal"
};
function kr(t) {
  return J.isInstance(t, Rr.$type);
}
const Ws = {
  $type: "BooleanLiteral",
  true: "true"
};
function Yd(t) {
  return J.isInstance(t, Ws.$type);
}
const vr = {
  $type: "CharacterRange",
  cardinality: "cardinality",
  left: "left",
  lookahead: "lookahead",
  parenthesized: "parenthesized",
  right: "right"
};
function Jd(t) {
  return J.isInstance(t, vr.$type);
}
const Dr = {
  $type: "Condition"
}, ya = {
  $type: "Conjunction",
  left: "left",
  right: "right"
};
function Zd(t) {
  return J.isInstance(t, ya.$type);
}
const Er = {
  $type: "CrossReference",
  cardinality: "cardinality",
  deprecatedSyntax: "deprecatedSyntax",
  isMulti: "isMulti",
  terminal: "terminal",
  type: "type"
};
function Qa(t) {
  return J.isInstance(t, Er.$type);
}
const Ta = {
  $type: "Disjunction",
  left: "left",
  right: "right"
};
function Qd(t) {
  return J.isInstance(t, Ta.$type);
}
const Ks = {
  $type: "EndOfFile",
  cardinality: "cardinality"
};
function eh(t) {
  return J.isInstance(t, Ks.$type);
}
const ir = {
  $type: "Grammar",
  imports: "imports",
  interfaces: "interfaces",
  isDeclared: "isDeclared",
  name: "name",
  rules: "rules",
  types: "types"
}, nc = {
  $type: "GrammarImport",
  path: "path"
}, Ur = {
  $type: "Group",
  cardinality: "cardinality",
  elements: "elements",
  guardCondition: "guardCondition",
  predicate: "predicate"
};
function Il(t) {
  return J.isInstance(t, Ur.$type);
}
const Vs = {
  $type: "InferredType",
  name: "name"
};
function sf(t) {
  return J.isInstance(t, Vs.$type);
}
const Ot = {
  $type: "InfixRule",
  call: "call",
  dataType: "dataType",
  inferredType: "inferredType",
  name: "name",
  operators: "operators",
  parameters: "parameters",
  returnType: "returnType"
};
function Ia(t) {
  return J.isInstance(t, Ot.$type);
}
const ps = {
  $type: "InfixRuleOperatorList",
  associativity: "associativity",
  operators: "operators"
}, ic = {
  $type: "InfixRuleOperators",
  precedences: "precedences"
}, Qn = {
  $type: "Interface",
  attributes: "attributes",
  name: "name",
  superTypes: "superTypes"
};
function th(t) {
  return J.isInstance(t, Qn.$type);
}
const ei = {
  $type: "Keyword",
  cardinality: "cardinality",
  predicate: "predicate",
  value: "value"
};
function wr(t) {
  return J.isInstance(t, ei.$type);
}
const Hi = {
  $type: "NamedArgument",
  calledByName: "calledByName",
  parameter: "parameter",
  value: "value"
}, qr = {
  $type: "NegatedToken",
  cardinality: "cardinality",
  lookahead: "lookahead",
  parenthesized: "parenthesized",
  terminal: "terminal"
};
function rh(t) {
  return J.isInstance(t, qr.$type);
}
const Hs = {
  $type: "Negation",
  value: "value"
};
function nh(t) {
  return J.isInstance(t, Hs.$type);
}
const ac = {
  $type: "NumberLiteral",
  value: "value"
}, Xi = {
  $type: "Parameter",
  name: "name"
}, Xs = {
  $type: "ParameterReference",
  parameter: "parameter"
};
function ih(t) {
  return J.isInstance(t, Xs.$type);
}
const pt = {
  $type: "ParserRule",
  dataType: "dataType",
  definition: "definition",
  entry: "entry",
  fragment: "fragment",
  inferredType: "inferredType",
  name: "name",
  parameters: "parameters",
  returnType: "returnType"
};
function qt(t) {
  return J.isInstance(t, pt.$type);
}
const ms = {
  $type: "ReferenceType",
  isMulti: "isMulti",
  referenceType: "referenceType"
}, Br = {
  $type: "RegexToken",
  cardinality: "cardinality",
  lookahead: "lookahead",
  parenthesized: "parenthesized",
  regex: "regex"
};
function ah(t) {
  return J.isInstance(t, Br.$type);
}
const Ys = {
  $type: "ReturnType",
  name: "name"
};
function sh(t) {
  return J.isInstance(t, Ys.$type);
}
const Wr = {
  $type: "RuleCall",
  arguments: "arguments",
  cardinality: "cardinality",
  predicate: "predicate",
  rule: "rule"
};
function br(t) {
  return J.isInstance(t, Wr.$type);
}
const ti = {
  $type: "SimpleType",
  primitiveType: "primitiveType",
  stringType: "stringType",
  typeRef: "typeRef"
};
function oh(t) {
  return J.isInstance(t, ti.$type);
}
const sc = {
  $type: "StringLiteral",
  value: "value"
}, Kr = {
  $type: "TerminalAlternatives",
  cardinality: "cardinality",
  elements: "elements",
  lookahead: "lookahead",
  parenthesized: "parenthesized"
};
function lh(t) {
  return J.isInstance(t, Kr.$type);
}
const rt = {
  $type: "TerminalElement",
  cardinality: "cardinality",
  lookahead: "lookahead",
  parenthesized: "parenthesized"
}, Vr = {
  $type: "TerminalGroup",
  cardinality: "cardinality",
  elements: "elements",
  lookahead: "lookahead",
  parenthesized: "parenthesized"
};
function ch(t) {
  return J.isInstance(t, Vr.$type);
}
const Yt = {
  $type: "TerminalRule",
  definition: "definition",
  fragment: "fragment",
  hidden: "hidden",
  name: "name",
  type: "type"
};
function Bt(t) {
  return J.isInstance(t, Yt.$type);
}
const Hr = {
  $type: "TerminalRuleCall",
  cardinality: "cardinality",
  lookahead: "lookahead",
  parenthesized: "parenthesized",
  rule: "rule"
};
function uh(t) {
  return J.isInstance(t, Hr.$type);
}
const Ra = {
  $type: "Type",
  name: "name",
  type: "type"
};
function fh(t) {
  return J.isInstance(t, Ra.$type);
}
const _n = {
  $type: "TypeAttribute",
  defaultValue: "defaultValue",
  isOptional: "isOptional",
  name: "name",
  type: "type"
}, In = {
  $type: "TypeDefinition"
}, oc = {
  $type: "UnionType",
  types: "types"
}, va = {
  $type: "UnorderedGroup",
  cardinality: "cardinality",
  elements: "elements"
};
function of(t) {
  return J.isInstance(t, va.$type);
}
const Xr = {
  $type: "UntilToken",
  cardinality: "cardinality",
  lookahead: "lookahead",
  parenthesized: "parenthesized",
  terminal: "terminal"
};
function dh(t) {
  return J.isInstance(t, Xr.$type);
}
const Pn = {
  $type: "ValueLiteral"
}, ri = {
  $type: "Wildcard",
  cardinality: "cardinality",
  lookahead: "lookahead",
  parenthesized: "parenthesized"
};
function hh(t) {
  return J.isInstance(t, ri.$type);
}
class lf extends Qu {
  constructor() {
    super(...arguments), this.types = {
      AbstractElement: {
        name: Je.$type,
        properties: {
          cardinality: {
            name: Je.cardinality
          }
        },
        superTypes: []
      },
      AbstractParserRule: {
        name: ma.$type,
        properties: {},
        superTypes: [Vi.$type, ot.$type]
      },
      AbstractRule: {
        name: Vi.$type,
        properties: {},
        superTypes: []
      },
      AbstractType: {
        name: ot.$type,
        properties: {},
        superTypes: []
      },
      Action: {
        name: Tr.$type,
        properties: {
          cardinality: {
            name: Tr.cardinality
          },
          feature: {
            name: Tr.feature
          },
          inferredType: {
            name: Tr.inferredType
          },
          operator: {
            name: Tr.operator
          },
          type: {
            name: Tr.type,
            referenceType: ot.$type
          }
        },
        superTypes: [Je.$type]
      },
      Alternatives: {
        name: ga.$type,
        properties: {
          cardinality: {
            name: ga.cardinality
          },
          elements: {
            name: ga.elements,
            defaultValue: []
          }
        },
        superTypes: [Je.$type]
      },
      ArrayLiteral: {
        name: tc.$type,
        properties: {
          elements: {
            name: tc.elements,
            defaultValue: []
          }
        },
        superTypes: [Pn.$type]
      },
      ArrayType: {
        name: rc.$type,
        properties: {
          elementType: {
            name: rc.elementType
          }
        },
        superTypes: [In.$type]
      },
      Assignment: {
        name: Rr.$type,
        properties: {
          cardinality: {
            name: Rr.cardinality
          },
          feature: {
            name: Rr.feature
          },
          operator: {
            name: Rr.operator
          },
          predicate: {
            name: Rr.predicate
          },
          terminal: {
            name: Rr.terminal
          }
        },
        superTypes: [Je.$type]
      },
      BooleanLiteral: {
        name: Ws.$type,
        properties: {
          true: {
            name: Ws.true,
            defaultValue: !1
          }
        },
        superTypes: [Dr.$type, Pn.$type]
      },
      CharacterRange: {
        name: vr.$type,
        properties: {
          cardinality: {
            name: vr.cardinality
          },
          left: {
            name: vr.left
          },
          lookahead: {
            name: vr.lookahead
          },
          parenthesized: {
            name: vr.parenthesized,
            defaultValue: !1
          },
          right: {
            name: vr.right
          }
        },
        superTypes: [rt.$type]
      },
      Condition: {
        name: Dr.$type,
        properties: {},
        superTypes: []
      },
      Conjunction: {
        name: ya.$type,
        properties: {
          left: {
            name: ya.left
          },
          right: {
            name: ya.right
          }
        },
        superTypes: [Dr.$type]
      },
      CrossReference: {
        name: Er.$type,
        properties: {
          cardinality: {
            name: Er.cardinality
          },
          deprecatedSyntax: {
            name: Er.deprecatedSyntax,
            defaultValue: !1
          },
          isMulti: {
            name: Er.isMulti,
            defaultValue: !1
          },
          terminal: {
            name: Er.terminal
          },
          type: {
            name: Er.type,
            referenceType: ot.$type
          }
        },
        superTypes: [Je.$type]
      },
      Disjunction: {
        name: Ta.$type,
        properties: {
          left: {
            name: Ta.left
          },
          right: {
            name: Ta.right
          }
        },
        superTypes: [Dr.$type]
      },
      EndOfFile: {
        name: Ks.$type,
        properties: {
          cardinality: {
            name: Ks.cardinality
          }
        },
        superTypes: [Je.$type]
      },
      Grammar: {
        name: ir.$type,
        properties: {
          imports: {
            name: ir.imports,
            defaultValue: []
          },
          interfaces: {
            name: ir.interfaces,
            defaultValue: []
          },
          isDeclared: {
            name: ir.isDeclared,
            defaultValue: !1
          },
          name: {
            name: ir.name
          },
          rules: {
            name: ir.rules,
            defaultValue: []
          },
          types: {
            name: ir.types,
            defaultValue: []
          }
        },
        superTypes: []
      },
      GrammarImport: {
        name: nc.$type,
        properties: {
          path: {
            name: nc.path
          }
        },
        superTypes: []
      },
      Group: {
        name: Ur.$type,
        properties: {
          cardinality: {
            name: Ur.cardinality
          },
          elements: {
            name: Ur.elements,
            defaultValue: []
          },
          guardCondition: {
            name: Ur.guardCondition
          },
          predicate: {
            name: Ur.predicate
          }
        },
        superTypes: [Je.$type]
      },
      InferredType: {
        name: Vs.$type,
        properties: {
          name: {
            name: Vs.name
          }
        },
        superTypes: [ot.$type]
      },
      InfixRule: {
        name: Ot.$type,
        properties: {
          call: {
            name: Ot.call
          },
          dataType: {
            name: Ot.dataType
          },
          inferredType: {
            name: Ot.inferredType
          },
          name: {
            name: Ot.name
          },
          operators: {
            name: Ot.operators
          },
          parameters: {
            name: Ot.parameters,
            defaultValue: []
          },
          returnType: {
            name: Ot.returnType,
            referenceType: ot.$type
          }
        },
        superTypes: [ma.$type]
      },
      InfixRuleOperatorList: {
        name: ps.$type,
        properties: {
          associativity: {
            name: ps.associativity
          },
          operators: {
            name: ps.operators,
            defaultValue: []
          }
        },
        superTypes: []
      },
      InfixRuleOperators: {
        name: ic.$type,
        properties: {
          precedences: {
            name: ic.precedences,
            defaultValue: []
          }
        },
        superTypes: []
      },
      Interface: {
        name: Qn.$type,
        properties: {
          attributes: {
            name: Qn.attributes,
            defaultValue: []
          },
          name: {
            name: Qn.name
          },
          superTypes: {
            name: Qn.superTypes,
            defaultValue: [],
            referenceType: ot.$type
          }
        },
        superTypes: [ot.$type]
      },
      Keyword: {
        name: ei.$type,
        properties: {
          cardinality: {
            name: ei.cardinality
          },
          predicate: {
            name: ei.predicate
          },
          value: {
            name: ei.value
          }
        },
        superTypes: [Je.$type]
      },
      NamedArgument: {
        name: Hi.$type,
        properties: {
          calledByName: {
            name: Hi.calledByName,
            defaultValue: !1
          },
          parameter: {
            name: Hi.parameter,
            referenceType: Xi.$type
          },
          value: {
            name: Hi.value
          }
        },
        superTypes: []
      },
      NegatedToken: {
        name: qr.$type,
        properties: {
          cardinality: {
            name: qr.cardinality
          },
          lookahead: {
            name: qr.lookahead
          },
          parenthesized: {
            name: qr.parenthesized,
            defaultValue: !1
          },
          terminal: {
            name: qr.terminal
          }
        },
        superTypes: [rt.$type]
      },
      Negation: {
        name: Hs.$type,
        properties: {
          value: {
            name: Hs.value
          }
        },
        superTypes: [Dr.$type]
      },
      NumberLiteral: {
        name: ac.$type,
        properties: {
          value: {
            name: ac.value
          }
        },
        superTypes: [Pn.$type]
      },
      Parameter: {
        name: Xi.$type,
        properties: {
          name: {
            name: Xi.name
          }
        },
        superTypes: []
      },
      ParameterReference: {
        name: Xs.$type,
        properties: {
          parameter: {
            name: Xs.parameter,
            referenceType: Xi.$type
          }
        },
        superTypes: [Dr.$type]
      },
      ParserRule: {
        name: pt.$type,
        properties: {
          dataType: {
            name: pt.dataType
          },
          definition: {
            name: pt.definition
          },
          entry: {
            name: pt.entry,
            defaultValue: !1
          },
          fragment: {
            name: pt.fragment,
            defaultValue: !1
          },
          inferredType: {
            name: pt.inferredType
          },
          name: {
            name: pt.name
          },
          parameters: {
            name: pt.parameters,
            defaultValue: []
          },
          returnType: {
            name: pt.returnType,
            referenceType: ot.$type
          }
        },
        superTypes: [ma.$type]
      },
      ReferenceType: {
        name: ms.$type,
        properties: {
          isMulti: {
            name: ms.isMulti,
            defaultValue: !1
          },
          referenceType: {
            name: ms.referenceType
          }
        },
        superTypes: [In.$type]
      },
      RegexToken: {
        name: Br.$type,
        properties: {
          cardinality: {
            name: Br.cardinality
          },
          lookahead: {
            name: Br.lookahead
          },
          parenthesized: {
            name: Br.parenthesized,
            defaultValue: !1
          },
          regex: {
            name: Br.regex
          }
        },
        superTypes: [rt.$type]
      },
      ReturnType: {
        name: Ys.$type,
        properties: {
          name: {
            name: Ys.name
          }
        },
        superTypes: []
      },
      RuleCall: {
        name: Wr.$type,
        properties: {
          arguments: {
            name: Wr.arguments,
            defaultValue: []
          },
          cardinality: {
            name: Wr.cardinality
          },
          predicate: {
            name: Wr.predicate
          },
          rule: {
            name: Wr.rule,
            referenceType: Vi.$type
          }
        },
        superTypes: [Je.$type]
      },
      SimpleType: {
        name: ti.$type,
        properties: {
          primitiveType: {
            name: ti.primitiveType
          },
          stringType: {
            name: ti.stringType
          },
          typeRef: {
            name: ti.typeRef,
            referenceType: ot.$type
          }
        },
        superTypes: [In.$type]
      },
      StringLiteral: {
        name: sc.$type,
        properties: {
          value: {
            name: sc.value
          }
        },
        superTypes: [Pn.$type]
      },
      TerminalAlternatives: {
        name: Kr.$type,
        properties: {
          cardinality: {
            name: Kr.cardinality
          },
          elements: {
            name: Kr.elements,
            defaultValue: []
          },
          lookahead: {
            name: Kr.lookahead
          },
          parenthesized: {
            name: Kr.parenthesized,
            defaultValue: !1
          }
        },
        superTypes: [rt.$type]
      },
      TerminalElement: {
        name: rt.$type,
        properties: {
          cardinality: {
            name: rt.cardinality
          },
          lookahead: {
            name: rt.lookahead
          },
          parenthesized: {
            name: rt.parenthesized,
            defaultValue: !1
          }
        },
        superTypes: [Je.$type]
      },
      TerminalGroup: {
        name: Vr.$type,
        properties: {
          cardinality: {
            name: Vr.cardinality
          },
          elements: {
            name: Vr.elements,
            defaultValue: []
          },
          lookahead: {
            name: Vr.lookahead
          },
          parenthesized: {
            name: Vr.parenthesized,
            defaultValue: !1
          }
        },
        superTypes: [rt.$type]
      },
      TerminalRule: {
        name: Yt.$type,
        properties: {
          definition: {
            name: Yt.definition
          },
          fragment: {
            name: Yt.fragment,
            defaultValue: !1
          },
          hidden: {
            name: Yt.hidden,
            defaultValue: !1
          },
          name: {
            name: Yt.name
          },
          type: {
            name: Yt.type
          }
        },
        superTypes: [Vi.$type]
      },
      TerminalRuleCall: {
        name: Hr.$type,
        properties: {
          cardinality: {
            name: Hr.cardinality
          },
          lookahead: {
            name: Hr.lookahead
          },
          parenthesized: {
            name: Hr.parenthesized,
            defaultValue: !1
          },
          rule: {
            name: Hr.rule,
            referenceType: Yt.$type
          }
        },
        superTypes: [rt.$type]
      },
      Type: {
        name: Ra.$type,
        properties: {
          name: {
            name: Ra.name
          },
          type: {
            name: Ra.type
          }
        },
        superTypes: [ot.$type]
      },
      TypeAttribute: {
        name: _n.$type,
        properties: {
          defaultValue: {
            name: _n.defaultValue
          },
          isOptional: {
            name: _n.isOptional,
            defaultValue: !1
          },
          name: {
            name: _n.name
          },
          type: {
            name: _n.type
          }
        },
        superTypes: []
      },
      TypeDefinition: {
        name: In.$type,
        properties: {},
        superTypes: []
      },
      UnionType: {
        name: oc.$type,
        properties: {
          types: {
            name: oc.types,
            defaultValue: []
          }
        },
        superTypes: [In.$type]
      },
      UnorderedGroup: {
        name: va.$type,
        properties: {
          cardinality: {
            name: va.cardinality
          },
          elements: {
            name: va.elements,
            defaultValue: []
          }
        },
        superTypes: [Je.$type]
      },
      UntilToken: {
        name: Xr.$type,
        properties: {
          cardinality: {
            name: Xr.cardinality
          },
          lookahead: {
            name: Xr.lookahead
          },
          parenthesized: {
            name: Xr.parenthesized,
            defaultValue: !1
          },
          terminal: {
            name: Xr.terminal
          }
        },
        superTypes: [rt.$type]
      },
      ValueLiteral: {
        name: Pn.$type,
        properties: {},
        superTypes: []
      },
      Wildcard: {
        name: ri.$type,
        properties: {
          cardinality: {
            name: ri.cardinality
          },
          lookahead: {
            name: ri.lookahead
          },
          parenthesized: {
            name: ri.parenthesized,
            defaultValue: !1
          }
        },
        superTypes: [rt.$type]
      }
    };
  }
}
const J = new lf();
function Js(t) {
  return new Nl(t, (e) => ci(e) ? e.content : [], { includeRoot: !0 });
}
function ph(t, e) {
  for (; t.container; )
    if (t = t.container, t === e)
      return !0;
  return !1;
}
function Zs(t) {
  return {
    start: {
      character: t.startColumn - 1,
      line: t.startLine - 1
    },
    end: {
      character: t.endColumn,
      // endColumn uses the correct index
      line: t.endLine - 1
    }
  };
}
function Pa(t) {
  if (!t)
    return;
  const { offset: e, end: r, range: n } = t;
  return {
    range: n,
    offset: e,
    end: r,
    length: r - e
  };
}
var Dt;
(function(t) {
  t[t.Before = 0] = "Before", t[t.After = 1] = "After", t[t.OverlapFront = 2] = "OverlapFront", t[t.OverlapBack = 3] = "OverlapBack", t[t.Inside = 4] = "Inside", t[t.Outside = 5] = "Outside";
})(Dt || (Dt = {}));
function mh(t, e) {
  if (t.end.line < e.start.line || t.end.line === e.start.line && t.end.character <= e.start.character)
    return Dt.Before;
  if (t.start.line > e.end.line || t.start.line === e.end.line && t.start.character >= e.end.character)
    return Dt.After;
  const r = t.start.line > e.start.line || t.start.line === e.start.line && t.start.character >= e.start.character, n = t.end.line < e.end.line || t.end.line === e.end.line && t.end.character <= e.end.character;
  return r && n ? Dt.Inside : r ? Dt.OverlapBack : n ? Dt.OverlapFront : Dt.Outside;
}
function gh(t, e) {
  return mh(t, e) > Dt.After;
}
const yh = /^[\w\p{L}]$/u;
function Th(t, e) {
  if (t) {
    const r = Rh(t, !0);
    if (r && lc(r, e))
      return r;
    if (tf(t)) {
      const n = t.content.findIndex((i) => !i.hidden);
      for (let i = n - 1; i >= 0; i--) {
        const a = t.content[i];
        if (lc(a, e))
          return a;
      }
    }
  }
}
function lc(t, e) {
  return ef(t) && e.includes(t.tokenType.name);
}
function Rh(t, e = !0) {
  for (; t.container; ) {
    const r = t.container;
    let n = r.content.indexOf(t);
    for (; n > 0; ) {
      n--;
      const i = r.content[n];
      if (e || !i.hidden)
        return i;
    }
    t = r;
  }
}
class cf extends Error {
  constructor(e, r) {
    super(e ? `${r} at ${e.range.start.line}:${e.range.start.character}` : r);
  }
}
function $i(t, e = "Error: Got unexpected value.") {
  throw new Error(e);
}
function U(t) {
  return t.charCodeAt(0);
}
function gs(t, e) {
  Array.isArray(t) ? t.forEach(function(r) {
    e.push(r);
  }) : e.push(t);
}
function On(t, e) {
  if (t[e] === !0)
    throw "duplicate flag " + e;
  t[e], t[e] = !0;
}
function Mr(t) {
  if (t === void 0)
    throw Error("Internal Error - Should never get here!");
  return !0;
}
function vh() {
  throw Error("Internal Error - Should never get here!");
}
function cc(t) {
  return t.type === "Character";
}
const Oa = [];
for (let t = U("0"); t <= U("9"); t++)
  Oa.push(t);
const La = [U("_")].concat(Oa);
for (let t = U("a"); t <= U("z"); t++)
  La.push(t);
for (let t = U("A"); t <= U("Z"); t++)
  La.push(t);
const uc = [
  U(" "),
  U("\f"),
  U(`
`),
  U("\r"),
  U("	"),
  U("\v"),
  U("	"),
  U(" "),
  U(" "),
  U(" "),
  U(" "),
  U(" "),
  U(" "),
  U(" "),
  U(" "),
  U(" "),
  U(" "),
  U(" "),
  U(" "),
  U(" "),
  U("\u2028"),
  U("\u2029"),
  U(" "),
  U(" "),
  U("　"),
  U("\uFEFF")
], Eh = /[0-9a-fA-F]/, Yi = /[0-9]/, Ah = /[1-9]/;
class uf {
  constructor() {
    this.idx = 0, this.input = "", this.groupIdx = 0;
  }
  saveState() {
    return {
      idx: this.idx,
      input: this.input,
      groupIdx: this.groupIdx
    };
  }
  restoreState(e) {
    this.idx = e.idx, this.input = e.input, this.groupIdx = e.groupIdx;
  }
  pattern(e) {
    this.idx = 0, this.input = e, this.groupIdx = 0, this.consumeChar("/");
    const r = this.disjunction();
    this.consumeChar("/");
    const n = {
      type: "Flags",
      loc: { begin: this.idx, end: e.length },
      global: !1,
      ignoreCase: !1,
      multiLine: !1,
      unicode: !1,
      sticky: !1
    };
    for (; this.isRegExpFlag(); )
      switch (this.popChar()) {
        case "g":
          On(n, "global");
          break;
        case "i":
          On(n, "ignoreCase");
          break;
        case "m":
          On(n, "multiLine");
          break;
        case "u":
          On(n, "unicode");
          break;
        case "y":
          On(n, "sticky");
          break;
      }
    if (this.idx !== this.input.length)
      throw Error("Redundant input: " + this.input.substring(this.idx));
    return {
      type: "Pattern",
      flags: n,
      value: r,
      loc: this.loc(0)
    };
  }
  disjunction() {
    const e = [], r = this.idx;
    for (e.push(this.alternative()); this.peekChar() === "|"; )
      this.consumeChar("|"), e.push(this.alternative());
    return { type: "Disjunction", value: e, loc: this.loc(r) };
  }
  alternative() {
    const e = [], r = this.idx;
    for (; this.isTerm(); )
      e.push(this.term());
    return { type: "Alternative", value: e, loc: this.loc(r) };
  }
  term() {
    return this.isAssertion() ? this.assertion() : this.atom();
  }
  assertion() {
    const e = this.idx;
    switch (this.popChar()) {
      case "^":
        return {
          type: "StartAnchor",
          loc: this.loc(e)
        };
      case "$":
        return { type: "EndAnchor", loc: this.loc(e) };
      // '\b' or '\B'
      case "\\":
        switch (this.popChar()) {
          case "b":
            return {
              type: "WordBoundary",
              loc: this.loc(e)
            };
          case "B":
            return {
              type: "NonWordBoundary",
              loc: this.loc(e)
            };
        }
        throw Error("Invalid Assertion Escape");
      // '(?=' or '(?!'
      case "(":
        this.consumeChar("?");
        let r;
        switch (this.popChar()) {
          case "=":
            r = "Lookahead";
            break;
          case "!":
            r = "NegativeLookahead";
            break;
          case "<": {
            switch (this.popChar()) {
              case "=":
                r = "Lookbehind";
                break;
              case "!":
                r = "NegativeLookbehind";
            }
            break;
          }
        }
        Mr(r);
        const n = this.disjunction();
        return this.consumeChar(")"), {
          type: r,
          value: n,
          loc: this.loc(e)
        };
    }
    return vh();
  }
  quantifier(e = !1) {
    let r;
    const n = this.idx;
    switch (this.popChar()) {
      case "*":
        r = {
          atLeast: 0,
          atMost: 1 / 0
        };
        break;
      case "+":
        r = {
          atLeast: 1,
          atMost: 1 / 0
        };
        break;
      case "?":
        r = {
          atLeast: 0,
          atMost: 1
        };
        break;
      case "{":
        const i = this.integerIncludingZero();
        switch (this.popChar()) {
          case "}":
            r = {
              atLeast: i,
              atMost: i
            };
            break;
          case ",":
            let a;
            this.isDigit() ? (a = this.integerIncludingZero(), r = {
              atLeast: i,
              atMost: a
            }) : r = {
              atLeast: i,
              atMost: 1 / 0
            }, this.consumeChar("}");
            break;
        }
        if (e === !0 && r === void 0)
          return;
        Mr(r);
        break;
    }
    if (!(e === !0 && r === void 0) && Mr(r))
      return this.peekChar(0) === "?" ? (this.consumeChar("?"), r.greedy = !1) : r.greedy = !0, r.type = "Quantifier", r.loc = this.loc(n), r;
  }
  atom() {
    let e;
    const r = this.idx;
    switch (this.peekChar()) {
      case ".":
        e = this.dotAll();
        break;
      case "\\":
        e = this.atomEscape();
        break;
      case "[":
        e = this.characterClass();
        break;
      case "(":
        e = this.group();
        break;
    }
    if (e === void 0 && this.isPatternCharacter() && (e = this.patternCharacter()), Mr(e))
      return e.loc = this.loc(r), this.isQuantifier() && (e.quantifier = this.quantifier()), e;
  }
  dotAll() {
    return this.consumeChar("."), {
      type: "Set",
      complement: !0,
      value: [U(`
`), U("\r"), U("\u2028"), U("\u2029")]
    };
  }
  atomEscape() {
    switch (this.consumeChar("\\"), this.peekChar()) {
      case "1":
      case "2":
      case "3":
      case "4":
      case "5":
      case "6":
      case "7":
      case "8":
      case "9":
        return this.decimalEscapeAtom();
      case "d":
      case "D":
      case "s":
      case "S":
      case "w":
      case "W":
        return this.characterClassEscape();
      case "f":
      case "n":
      case "r":
      case "t":
      case "v":
        return this.controlEscapeAtom();
      case "c":
        return this.controlLetterEscapeAtom();
      case "0":
        return this.nulCharacterAtom();
      case "x":
        return this.hexEscapeSequenceAtom();
      case "u":
        return this.regExpUnicodeEscapeSequenceAtom();
      default:
        return this.identityEscapeAtom();
    }
  }
  decimalEscapeAtom() {
    return { type: "GroupBackReference", value: this.positiveInteger() };
  }
  characterClassEscape() {
    let e, r = !1;
    switch (this.popChar()) {
      case "d":
        e = Oa;
        break;
      case "D":
        e = Oa, r = !0;
        break;
      case "s":
        e = uc;
        break;
      case "S":
        e = uc, r = !0;
        break;
      case "w":
        e = La;
        break;
      case "W":
        e = La, r = !0;
        break;
    }
    if (Mr(e))
      return { type: "Set", value: e, complement: r };
  }
  controlEscapeAtom() {
    let e;
    switch (this.popChar()) {
      case "f":
        e = U("\f");
        break;
      case "n":
        e = U(`
`);
        break;
      case "r":
        e = U("\r");
        break;
      case "t":
        e = U("	");
        break;
      case "v":
        e = U("\v");
        break;
    }
    if (Mr(e))
      return { type: "Character", value: e };
  }
  controlLetterEscapeAtom() {
    this.consumeChar("c");
    const e = this.popChar();
    if (/[a-zA-Z]/.test(e) === !1)
      throw Error("Invalid ");
    return { type: "Character", value: e.toUpperCase().charCodeAt(0) - 64 };
  }
  nulCharacterAtom() {
    return this.consumeChar("0"), { type: "Character", value: U("\0") };
  }
  hexEscapeSequenceAtom() {
    return this.consumeChar("x"), this.parseHexDigits(2);
  }
  regExpUnicodeEscapeSequenceAtom() {
    return this.consumeChar("u"), this.parseHexDigits(4);
  }
  identityEscapeAtom() {
    const e = this.popChar();
    return { type: "Character", value: U(e) };
  }
  classPatternCharacterAtom() {
    switch (this.peekChar()) {
      // istanbul ignore next
      case `
`:
      // istanbul ignore next
      case "\r":
      // istanbul ignore next
      case "\u2028":
      // istanbul ignore next
      case "\u2029":
      // istanbul ignore next
      case "\\":
      // istanbul ignore next
      case "]":
        throw Error("TBD");
      default:
        const e = this.popChar();
        return { type: "Character", value: U(e) };
    }
  }
  characterClass() {
    const e = [];
    let r = !1;
    for (this.consumeChar("["), this.peekChar(0) === "^" && (this.consumeChar("^"), r = !0); this.isClassAtom(); ) {
      const n = this.classAtom();
      if (n.type, cc(n) && this.isRangeDash()) {
        this.consumeChar("-");
        const i = this.classAtom();
        if (i.type, cc(i)) {
          if (i.value < n.value)
            throw Error("Range out of order in character class");
          e.push({ from: n.value, to: i.value });
        } else
          gs(n.value, e), e.push(U("-")), gs(i.value, e);
      } else
        gs(n.value, e);
    }
    return this.consumeChar("]"), { type: "Set", complement: r, value: e };
  }
  classAtom() {
    switch (this.peekChar()) {
      // istanbul ignore next
      case "]":
      // istanbul ignore next
      case `
`:
      // istanbul ignore next
      case "\r":
      // istanbul ignore next
      case "\u2028":
      // istanbul ignore next
      case "\u2029":
        throw Error("TBD");
      case "\\":
        return this.classEscape();
      default:
        return this.classPatternCharacterAtom();
    }
  }
  classEscape() {
    switch (this.consumeChar("\\"), this.peekChar()) {
      // Matches a backspace.
      // (Not to be confused with \b word boundary outside characterClass)
      case "b":
        return this.consumeChar("b"), { type: "Character", value: U("\b") };
      case "d":
      case "D":
      case "s":
      case "S":
      case "w":
      case "W":
        return this.characterClassEscape();
      case "f":
      case "n":
      case "r":
      case "t":
      case "v":
        return this.controlEscapeAtom();
      case "c":
        return this.controlLetterEscapeAtom();
      case "0":
        return this.nulCharacterAtom();
      case "x":
        return this.hexEscapeSequenceAtom();
      case "u":
        return this.regExpUnicodeEscapeSequenceAtom();
      default:
        return this.identityEscapeAtom();
    }
  }
  group() {
    let e = !0;
    switch (this.consumeChar("("), this.peekChar(0)) {
      case "?":
        this.consumeChar("?"), this.consumeChar(":"), e = !1;
        break;
      default:
        this.groupIdx++;
        break;
    }
    const r = this.disjunction();
    this.consumeChar(")");
    const n = {
      type: "Group",
      capturing: e,
      value: r
    };
    return e && (n.idx = this.groupIdx), n;
  }
  positiveInteger() {
    let e = this.popChar();
    if (Ah.test(e) === !1)
      throw Error("Expecting a positive integer");
    for (; Yi.test(this.peekChar(0)); )
      e += this.popChar();
    return parseInt(e, 10);
  }
  integerIncludingZero() {
    let e = this.popChar();
    if (Yi.test(e) === !1)
      throw Error("Expecting an integer");
    for (; Yi.test(this.peekChar(0)); )
      e += this.popChar();
    return parseInt(e, 10);
  }
  patternCharacter() {
    const e = this.popChar();
    switch (e) {
      // istanbul ignore next
      case `
`:
      // istanbul ignore next
      case "\r":
      // istanbul ignore next
      case "\u2028":
      // istanbul ignore next
      case "\u2029":
      // istanbul ignore next
      case "^":
      // istanbul ignore next
      case "$":
      // istanbul ignore next
      case "\\":
      // istanbul ignore next
      case ".":
      // istanbul ignore next
      case "*":
      // istanbul ignore next
      case "+":
      // istanbul ignore next
      case "?":
      // istanbul ignore next
      case "(":
      // istanbul ignore next
      case ")":
      // istanbul ignore next
      case "[":
      // istanbul ignore next
      case "|":
        throw Error("TBD");
      default:
        return { type: "Character", value: U(e) };
    }
  }
  isRegExpFlag() {
    switch (this.peekChar(0)) {
      case "g":
      case "i":
      case "m":
      case "u":
      case "y":
        return !0;
      default:
        return !1;
    }
  }
  isRangeDash() {
    return this.peekChar() === "-" && this.isClassAtom(1);
  }
  isDigit() {
    return Yi.test(this.peekChar(0));
  }
  isClassAtom(e = 0) {
    switch (this.peekChar(e)) {
      case "]":
      case `
`:
      case "\r":
      case "\u2028":
      case "\u2029":
        return !1;
      default:
        return !0;
    }
  }
  isTerm() {
    return this.isAtom() || this.isAssertion();
  }
  isAtom() {
    if (this.isPatternCharacter())
      return !0;
    switch (this.peekChar(0)) {
      case ".":
      case "\\":
      // atomEscape
      case "[":
      // characterClass
      // TODO: isAtom must be called before isAssertion - disambiguate
      case "(":
        return !0;
      default:
        return !1;
    }
  }
  isAssertion() {
    switch (this.peekChar(0)) {
      case "^":
      case "$":
        return !0;
      // '\b' or '\B'
      case "\\":
        switch (this.peekChar(1)) {
          case "b":
          case "B":
            return !0;
          default:
            return !1;
        }
      // '(?=' or '(?!' or `(?<=` or `(?<!`
      case "(":
        return this.peekChar(1) === "?" && (this.peekChar(2) === "=" || this.peekChar(2) === "!" || this.peekChar(2) === "<" && (this.peekChar(3) === "=" || this.peekChar(3) === "!"));
      default:
        return !1;
    }
  }
  isQuantifier() {
    const e = this.saveState();
    try {
      return this.quantifier(!0) !== void 0;
    } catch {
      return !1;
    } finally {
      this.restoreState(e);
    }
  }
  isPatternCharacter() {
    switch (this.peekChar()) {
      case "^":
      case "$":
      case "\\":
      case ".":
      case "*":
      case "+":
      case "?":
      case "(":
      case ")":
      case "[":
      case "|":
      case "/":
      case `
`:
      case "\r":
      case "\u2028":
      case "\u2029":
        return !1;
      default:
        return !0;
    }
  }
  parseHexDigits(e) {
    let r = "";
    for (let i = 0; i < e; i++) {
      const a = this.popChar();
      if (Eh.test(a) === !1)
        throw Error("Expecting a HexDecimal digits");
      r += a;
    }
    return { type: "Character", value: parseInt(r, 16) };
  }
  peekChar(e = 0) {
    return this.input[this.idx + e];
  }
  popChar() {
    const e = this.peekChar(0);
    return this.consumeChar(void 0), e;
  }
  consumeChar(e) {
    if (e !== void 0 && this.input[this.idx] !== e)
      throw Error("Expected: '" + e + "' but found: '" + this.input[this.idx] + "' at offset: " + this.idx);
    if (this.idx >= this.input.length)
      throw Error("Unexpected end of input");
    this.idx++;
  }
  loc(e) {
    return { begin: e, end: this.idx };
  }
}
class es {
  visitChildren(e) {
    for (const r in e) {
      const n = e[r];
      e.hasOwnProperty(r) && (n.type !== void 0 ? this.visit(n) : Array.isArray(n) && n.forEach((i) => {
        this.visit(i);
      }, this));
    }
  }
  visit(e) {
    switch (e.type) {
      case "Pattern":
        this.visitPattern(e);
        break;
      case "Flags":
        this.visitFlags(e);
        break;
      case "Disjunction":
        this.visitDisjunction(e);
        break;
      case "Alternative":
        this.visitAlternative(e);
        break;
      case "StartAnchor":
        this.visitStartAnchor(e);
        break;
      case "EndAnchor":
        this.visitEndAnchor(e);
        break;
      case "WordBoundary":
        this.visitWordBoundary(e);
        break;
      case "NonWordBoundary":
        this.visitNonWordBoundary(e);
        break;
      case "Lookahead":
        this.visitLookahead(e);
        break;
      case "NegativeLookahead":
        this.visitNegativeLookahead(e);
        break;
      case "Lookbehind":
        this.visitLookbehind(e);
        break;
      case "NegativeLookbehind":
        this.visitNegativeLookbehind(e);
        break;
      case "Character":
        this.visitCharacter(e);
        break;
      case "Set":
        this.visitSet(e);
        break;
      case "Group":
        this.visitGroup(e);
        break;
      case "GroupBackReference":
        this.visitGroupBackReference(e);
        break;
      case "Quantifier":
        this.visitQuantifier(e);
        break;
    }
    this.visitChildren(e);
  }
  visitPattern(e) {
  }
  visitFlags(e) {
  }
  visitDisjunction(e) {
  }
  visitAlternative(e) {
  }
  // Assertion
  visitStartAnchor(e) {
  }
  visitEndAnchor(e) {
  }
  visitWordBoundary(e) {
  }
  visitNonWordBoundary(e) {
  }
  visitLookahead(e) {
  }
  visitNegativeLookahead(e) {
  }
  visitLookbehind(e) {
  }
  visitNegativeLookbehind(e) {
  }
  // atoms
  visitCharacter(e) {
  }
  visitSet(e) {
  }
  visitGroup(e) {
  }
  visitGroupBackReference(e) {
  }
  visitQuantifier(e) {
  }
}
const $h = /\r?\n/gm, Ch = new uf();
class Sh extends es {
  constructor() {
    super(...arguments), this.isStarting = !0, this.endRegexpStack = [], this.multiline = !1;
  }
  get endRegex() {
    return this.endRegexpStack.join("");
  }
  reset(e) {
    this.multiline = !1, this.regex = e, this.startRegexp = "", this.isStarting = !0, this.endRegexpStack = [];
  }
  visitGroup(e) {
    e.quantifier && (this.isStarting = !1, this.endRegexpStack = []);
  }
  visitCharacter(e) {
    const r = String.fromCharCode(e.value);
    if (!this.multiline && r === `
` && (this.multiline = !0), e.quantifier)
      this.isStarting = !1, this.endRegexpStack = [];
    else {
      const n = ts(r);
      this.endRegexpStack.push(n), this.isStarting && (this.startRegexp += n);
    }
  }
  visitSet(e) {
    if (!this.multiline) {
      const r = this.regex.substring(e.loc.begin, e.loc.end), n = new RegExp(r);
      this.multiline = !!`
`.match(n);
    }
    if (e.quantifier)
      this.isStarting = !1, this.endRegexpStack = [];
    else {
      const r = this.regex.substring(e.loc.begin, e.loc.end);
      this.endRegexpStack.push(r), this.isStarting && (this.startRegexp += r);
    }
  }
  visitChildren(e) {
    e.type === "Group" && e.quantifier || super.visitChildren(e);
  }
}
const ys = new Sh();
function kh(t) {
  try {
    return typeof t == "string" && (t = new RegExp(t)), t = t.toString(), ys.reset(t), ys.visit(Ch.pattern(t)), ys.multiline;
  } catch {
    return !1;
  }
}
const wh = `\f
\r	\v              \u2028\u2029  　\uFEFF`.split("");
function ff(t) {
  const e = typeof t == "string" ? new RegExp(t) : t;
  return wh.some((r) => e.test(r));
}
function ts(t) {
  return t.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}
function bh(t, e) {
  const r = Nh(t), n = e.match(r);
  return !!n && n[0].length > 0;
}
function Nh(t) {
  typeof t == "string" && (t = new RegExp(t));
  const e = t, r = t.source;
  let n = 0;
  function i() {
    let a = "", s;
    function o(c) {
      a += r.substr(n, c), n += c;
    }
    function l(c) {
      a += "(?:" + r.substr(n, c) + "|$)", n += c;
    }
    for (; n < r.length; )
      switch (r[n]) {
        case "\\":
          switch (r[n + 1]) {
            case "c":
              l(3);
              break;
            case "x":
              l(4);
              break;
            case "u":
              e.unicode ? r[n + 2] === "{" ? l(r.indexOf("}", n) - n + 1) : l(6) : l(2);
              break;
            case "p":
            case "P":
              e.unicode ? l(r.indexOf("}", n) - n + 1) : l(2);
              break;
            case "k":
              l(r.indexOf(">", n) - n + 1);
              break;
            default:
              l(2);
              break;
          }
          break;
        case "[":
          s = /\[(?:\\.|.)*?\]/g, s.lastIndex = n, s = s.exec(r) || [], l(s[0].length);
          break;
        case "|":
        case "^":
        case "$":
        case "*":
        case "+":
        case "?":
          o(1);
          break;
        case "{":
          s = /\{\d+,?\d*\}/g, s.lastIndex = n, s = s.exec(r), s ? o(s[0].length) : l(1);
          break;
        case "(":
          if (r[n + 1] === "?")
            switch (r[n + 2]) {
              case ":":
                a += "(?:", n += 3, a += i() + "|$)";
                break;
              case "=":
                a += "(?=", n += 3, a += i() + ")";
                break;
              case "!":
                s = n, n += 3, i(), a += r.substr(s, n - s);
                break;
              case "<":
                switch (r[n + 3]) {
                  case "=":
                  case "!":
                    s = n, n += 4, i(), a += r.substr(s, n - s);
                    break;
                  default:
                    o(r.indexOf(">", n) - n + 1), a += i() + "|$)";
                    break;
                }
                break;
            }
          else
            o(1), a += i() + "|$)";
          break;
        case ")":
          return ++n, a;
        default:
          l(1);
          break;
      }
    return a;
  }
  return new RegExp(i(), t.flags);
}
function _h(t) {
  return t.rules.find((e) => qt(e) && e.entry);
}
function Ih(t) {
  return t.rules.filter((e) => Bt(e) && e.hidden);
}
function df(t, e) {
  const r = /* @__PURE__ */ new Set(), n = _h(t);
  if (!n)
    return new Set(t.rules);
  const i = [n].concat(Ih(t));
  for (const s of i)
    hf(s, r, e);
  const a = /* @__PURE__ */ new Set();
  for (const s of t.rules)
    (r.has(s.name) || Bt(s) && s.hidden) && a.add(s);
  return a;
}
function hf(t, e, r) {
  e.add(t.name), Ei(t).forEach((n) => {
    if (br(n) || r) {
      const i = n.rule.ref;
      i && !e.has(i.name) && hf(i, e, r);
    }
  });
}
function Ph(t) {
  if (t.terminal)
    return t.terminal;
  if (t.type.ref)
    return mf(t.type.ref)?.terminal;
}
function Oh(t) {
  return t.hidden && !ff(Ol(t));
}
function Lh(t, e) {
  return !t || !e ? [] : Pl(t, e, t.astNode, !0);
}
function pf(t, e, r) {
  if (!t || !e)
    return;
  const n = Pl(t, e, t.astNode, !0);
  if (n.length !== 0)
    return r !== void 0 ? r = Math.max(0, Math.min(r, n.length - 1)) : r = 0, n[r];
}
function Pl(t, e, r, n) {
  if (!n) {
    const i = Ja(t.grammarSource, kr);
    if (i && i.feature === e)
      return [t];
  }
  return ci(t) && t.astNode === r ? t.content.flatMap((i) => Pl(i, e, r, !1)) : [];
}
function xh(t, e, r) {
  if (!t)
    return;
  const n = Dh(t, e, t?.astNode);
  if (n.length !== 0)
    return r !== void 0 ? r = Math.max(0, Math.min(r, n.length - 1)) : r = 0, n[r];
}
function Dh(t, e, r) {
  if (t.astNode !== r)
    return [];
  if (wr(t.grammarSource) && t.grammarSource.value === e)
    return [t];
  const n = Js(t).iterator();
  let i;
  const a = [];
  do
    if (i = n.next(), !i.done) {
      const s = i.value;
      s.astNode === r ? wr(s.grammarSource) && s.grammarSource.value === e && a.push(s) : n.prune();
    }
  while (!i.done);
  return a;
}
function Mh(t) {
  const e = t.astNode;
  for (; e === t.container?.astNode; ) {
    const r = Ja(t.grammarSource, kr);
    if (r)
      return r;
    t = t.container;
  }
}
function mf(t) {
  let e = t;
  return sf(e) && (Za(e.$container) ? e = e.$container.$container : Ai(e.$container) ? e = e.$container : $i(e.$container)), gf(t, e, /* @__PURE__ */ new Map());
}
function gf(t, e, r) {
  function n(i, a) {
    let s;
    return Ja(i, kr) || (s = gf(a, a, r)), r.set(t, s), s;
  }
  if (r.has(t))
    return r.get(t);
  r.set(t, void 0);
  for (const i of Ei(e)) {
    if (kr(i) && i.feature.toLowerCase() === "name")
      return r.set(t, i), i;
    if (br(i) && qt(i.rule.ref))
      return n(i, i.rule.ref);
    if (oh(i) && i.typeRef?.ref)
      return n(i, i.typeRef.ref);
  }
}
function yf(t) {
  return Tf(t, /* @__PURE__ */ new Set());
}
function Tf(t, e) {
  if (e.has(t))
    return !0;
  e.add(t);
  for (const r of Ei(t))
    if (br(r)) {
      if (!r.rule.ref || qt(r.rule.ref) && !Tf(r.rule.ref, e) || Ia(r.rule.ref))
        return !1;
    } else {
      if (kr(r))
        return !1;
      if (Za(r))
        return !1;
    }
  return !!t.definition;
}
function Rf(t) {
  if (!Bt(t)) {
    if (t.inferredType)
      return t.inferredType.name;
    if (t.dataType)
      return t.dataType;
    if (t.returnType) {
      const e = t.returnType.ref;
      if (e)
        return e.name;
    }
  }
}
function ui(t) {
  if (Ai(t))
    return qt(t) && yf(t) ? t.name : Rf(t) ?? t.name;
  if (th(t) || fh(t) || sh(t))
    return t.name;
  if (Za(t)) {
    const e = Fh(t);
    if (e)
      return e;
  } else if (sf(t))
    return t.name;
  throw new Error("Cannot get name of Unknown Type");
}
function Fh(t) {
  if (t.inferredType)
    return t.inferredType.name;
  if (t.type?.ref)
    return ui(t.type.ref);
}
function Gh(t) {
  return Bt(t) ? t.type?.name ?? "string" : Rf(t) ?? t.name;
}
function Ol(t) {
  const e = {
    s: !1,
    i: !1,
    u: !1
  }, r = fn(t.definition, e), n = Object.entries(e).filter(([, i]) => i).map(([i]) => i).join("");
  return new RegExp(r, n);
}
const Ll = /[\s\S]/.source;
function fn(t, e) {
  if (lh(t))
    return jh(t);
  if (ch(t))
    return zh(t);
  if (Jd(t))
    return Bh(t);
  if (uh(t)) {
    const r = t.rule.ref;
    if (!r)
      throw new Error("Missing rule reference.");
    return zt(fn(r.definition), {
      cardinality: t.cardinality,
      lookahead: t.lookahead,
      parenthesized: t.parenthesized
    });
  } else {
    if (rh(t))
      return qh(t);
    if (dh(t))
      return Uh(t);
    if (ah(t)) {
      const r = t.regex.lastIndexOf("/"), n = t.regex.substring(1, r), i = t.regex.substring(r + 1);
      return e && (e.i = i.includes("i"), e.s = i.includes("s"), e.u = i.includes("u")), zt(n, {
        cardinality: t.cardinality,
        lookahead: t.lookahead,
        parenthesized: t.parenthesized,
        wrap: !1
      });
    } else {
      if (hh(t))
        return zt(Ll, {
          cardinality: t.cardinality,
          lookahead: t.lookahead,
          parenthesized: t.parenthesized
        });
      throw new Error(`Invalid terminal element: ${t?.$type}, ${t?.$cstNode?.text}`);
    }
  }
}
function jh(t) {
  return zt(t.elements.map((e) => fn(e)).join("|"), {
    cardinality: t.cardinality,
    lookahead: t.lookahead,
    parenthesized: t.parenthesized,
    wrap: !1
    // wrapping is not required for top level alternatives, and nested alternatives are already parenthesized according to the grammar
  });
}
function zh(t) {
  return zt(t.elements.map((e) => fn(e)).join(""), {
    cardinality: t.cardinality,
    lookahead: t.lookahead,
    parenthesized: t.parenthesized,
    wrap: !1
    // wrapping is not required for top level group, and nested group are already parenthesized according to the grammar
  });
}
function Uh(t) {
  return zt(`${Ll}*?${fn(t.terminal)}`, {
    cardinality: t.cardinality,
    lookahead: t.lookahead,
    parenthesized: t.parenthesized
  });
}
function qh(t) {
  return zt(`(?!${fn(t.terminal)})${Ll}*?`, {
    cardinality: t.cardinality,
    lookahead: t.lookahead,
    parenthesized: t.parenthesized
  });
}
function Bh(t) {
  return t.right ? zt(`[${Ts(t.left)}-${Ts(t.right)}]`, {
    cardinality: t.cardinality,
    lookahead: t.lookahead,
    parenthesized: t.parenthesized,
    wrap: !1
  }) : zt(Ts(t.left), {
    cardinality: t.cardinality,
    lookahead: t.lookahead,
    parenthesized: t.parenthesized,
    wrap: !1
  });
}
function Ts(t) {
  return ts(t.value);
}
function zt(t, e) {
  return (e.parenthesized || e.lookahead || e.wrap !== !1) && (t = `(${e.lookahead ?? (e.parenthesized ? "" : "?:")}${t})`), e.cardinality ? `${t}${e.cardinality}` : t;
}
function Wh(t) {
  const e = [], r = t.Grammar;
  for (const n of r.rules)
    Bt(n) && Oh(n) && kh(Ol(n)) && e.push(n.name);
  return {
    multilineCommentRules: e,
    nameRegexp: yh
  };
}
function Qs(t) {
  console && console.error && console.error(`Error: ${t}`);
}
function vf(t) {
  console && console.warn && console.warn(`Warning: ${t}`);
}
function Ef(t) {
  const e = (/* @__PURE__ */ new Date()).getTime(), r = t();
  return { time: (/* @__PURE__ */ new Date()).getTime() - e, value: r };
}
function Af(t) {
  function e() {
  }
  e.prototype = t;
  const r = new e();
  function n() {
    return typeof r.bar;
  }
  return n(), n(), t;
}
function Kh(t) {
  return Vh(t) ? t.LABEL : t.name;
}
function Vh(t) {
  return typeof t.LABEL == "string" && t.LABEL !== "";
}
class Tt {
  get definition() {
    return this._definition;
  }
  set definition(e) {
    this._definition = e;
  }
  constructor(e) {
    this._definition = e;
  }
  accept(e) {
    e.visit(this), this.definition.forEach((r) => {
      r.accept(e);
    });
  }
}
class qe extends Tt {
  constructor(e) {
    super([]), this.idx = 1, Object.assign(this, Rt(e));
  }
  set definition(e) {
  }
  get definition() {
    return this.referencedRule !== void 0 ? this.referencedRule.definition : [];
  }
  accept(e) {
    e.visit(this);
  }
}
class dn extends Tt {
  constructor(e) {
    super(e.definition), this.orgText = "", Object.assign(this, Rt(e));
  }
}
class Ke extends Tt {
  constructor(e) {
    super(e.definition), this.ignoreAmbiguities = !1, Object.assign(this, Rt(e));
  }
}
let Me = class extends Tt {
  constructor(e) {
    super(e.definition), this.idx = 1, Object.assign(this, Rt(e));
  }
};
class et extends Tt {
  constructor(e) {
    super(e.definition), this.idx = 1, Object.assign(this, Rt(e));
  }
}
class tt extends Tt {
  constructor(e) {
    super(e.definition), this.idx = 1, Object.assign(this, Rt(e));
  }
}
class Te extends Tt {
  constructor(e) {
    super(e.definition), this.idx = 1, Object.assign(this, Rt(e));
  }
}
class Ve extends Tt {
  constructor(e) {
    super(e.definition), this.idx = 1, Object.assign(this, Rt(e));
  }
}
class He extends Tt {
  get definition() {
    return this._definition;
  }
  set definition(e) {
    this._definition = e;
  }
  constructor(e) {
    super(e.definition), this.idx = 1, this.ignoreAmbiguities = !1, this.hasPredicates = !1, Object.assign(this, Rt(e));
  }
}
class ae {
  constructor(e) {
    this.idx = 1, Object.assign(this, Rt(e));
  }
  accept(e) {
    e.visit(this);
  }
}
function Hh(t) {
  return t.map(Ea);
}
function Ea(t) {
  function e(r) {
    return r.map(Ea);
  }
  if (t instanceof qe) {
    const r = {
      type: "NonTerminal",
      name: t.nonTerminalName,
      idx: t.idx
    };
    return typeof t.label == "string" && (r.label = t.label), r;
  } else {
    if (t instanceof Ke)
      return {
        type: "Alternative",
        definition: e(t.definition)
      };
    if (t instanceof Me)
      return {
        type: "Option",
        idx: t.idx,
        definition: e(t.definition)
      };
    if (t instanceof et)
      return {
        type: "RepetitionMandatory",
        idx: t.idx,
        definition: e(t.definition)
      };
    if (t instanceof tt)
      return {
        type: "RepetitionMandatoryWithSeparator",
        idx: t.idx,
        separator: Ea(new ae({ terminalType: t.separator })),
        definition: e(t.definition)
      };
    if (t instanceof Ve)
      return {
        type: "RepetitionWithSeparator",
        idx: t.idx,
        separator: Ea(new ae({ terminalType: t.separator })),
        definition: e(t.definition)
      };
    if (t instanceof Te)
      return {
        type: "Repetition",
        idx: t.idx,
        definition: e(t.definition)
      };
    if (t instanceof He)
      return {
        type: "Alternation",
        idx: t.idx,
        definition: e(t.definition)
      };
    if (t instanceof ae) {
      const r = {
        type: "Terminal",
        name: t.terminalType.name,
        label: Kh(t.terminalType),
        idx: t.idx
      };
      typeof t.label == "string" && (r.terminalLabel = t.label);
      const n = t.terminalType.PATTERN;
      return t.terminalType.PATTERN && (r.pattern = n instanceof RegExp ? n.source : n), r;
    } else {
      if (t instanceof dn)
        return {
          type: "Rule",
          name: t.name,
          orgText: t.orgText,
          definition: e(t.definition)
        };
      throw Error("non exhaustive match");
    }
  }
}
function Rt(t) {
  return Object.fromEntries(Object.entries(t).filter(([, e]) => e !== void 0));
}
class hn {
  visit(e) {
    const r = e;
    switch (r.constructor) {
      case qe:
        return this.visitNonTerminal(r);
      case Ke:
        return this.visitAlternative(r);
      case Me:
        return this.visitOption(r);
      case et:
        return this.visitRepetitionMandatory(r);
      case tt:
        return this.visitRepetitionMandatoryWithSeparator(r);
      case Ve:
        return this.visitRepetitionWithSeparator(r);
      case Te:
        return this.visitRepetition(r);
      case He:
        return this.visitAlternation(r);
      case ae:
        return this.visitTerminal(r);
      case dn:
        return this.visitRule(r);
      /* c8 ignore next 2 */
      default:
        throw Error("non exhaustive match");
    }
  }
  /* c8 ignore next */
  visitNonTerminal(e) {
  }
  /* c8 ignore next */
  visitAlternative(e) {
  }
  /* c8 ignore next */
  visitOption(e) {
  }
  /* c8 ignore next */
  visitRepetition(e) {
  }
  /* c8 ignore next */
  visitRepetitionMandatory(e) {
  }
  /* c8 ignore next 3 */
  visitRepetitionMandatoryWithSeparator(e) {
  }
  /* c8 ignore next */
  visitRepetitionWithSeparator(e) {
  }
  /* c8 ignore next */
  visitAlternation(e) {
  }
  /* c8 ignore next */
  visitTerminal(e) {
  }
  /* c8 ignore next */
  visitRule(e) {
  }
}
function Xh(t) {
  return t instanceof Ke || t instanceof Me || t instanceof Te || t instanceof et || t instanceof tt || t instanceof Ve || t instanceof ae || t instanceof dn;
}
function xa(t, e = []) {
  return t instanceof Me || t instanceof Te || t instanceof Ve ? !0 : t instanceof He ? t.definition.some((n) => xa(n, e)) : t instanceof qe && e.includes(t) ? !1 : t instanceof Tt ? (t instanceof qe && e.push(t), t.definition.every((n) => xa(n, e))) : !1;
}
function Yh(t) {
  return t instanceof He;
}
function mt(t) {
  if (t instanceof qe)
    return "SUBRULE";
  if (t instanceof Me)
    return "OPTION";
  if (t instanceof He)
    return "OR";
  if (t instanceof et)
    return "AT_LEAST_ONE";
  if (t instanceof tt)
    return "AT_LEAST_ONE_SEP";
  if (t instanceof Ve)
    return "MANY_SEP";
  if (t instanceof Te)
    return "MANY";
  if (t instanceof ae)
    return "CONSUME";
  throw Error("non exhaustive match");
}
class rs {
  walk(e, r = []) {
    e.definition.forEach((n, i) => {
      const a = e.definition.slice(i + 1);
      if (n instanceof qe)
        this.walkProdRef(n, a, r);
      else if (n instanceof ae)
        this.walkTerminal(n, a, r);
      else if (n instanceof Ke)
        this.walkFlat(n, a, r);
      else if (n instanceof Me)
        this.walkOption(n, a, r);
      else if (n instanceof et)
        this.walkAtLeastOne(n, a, r);
      else if (n instanceof tt)
        this.walkAtLeastOneSep(n, a, r);
      else if (n instanceof Ve)
        this.walkManySep(n, a, r);
      else if (n instanceof Te)
        this.walkMany(n, a, r);
      else if (n instanceof He)
        this.walkOr(n, a, r);
      else
        throw Error("non exhaustive match");
    });
  }
  walkTerminal(e, r, n) {
  }
  walkProdRef(e, r, n) {
  }
  walkFlat(e, r, n) {
    const i = r.concat(n);
    this.walk(e, i);
  }
  walkOption(e, r, n) {
    const i = r.concat(n);
    this.walk(e, i);
  }
  walkAtLeastOne(e, r, n) {
    const i = [
      new Me({ definition: e.definition })
    ].concat(r, n);
    this.walk(e, i);
  }
  walkAtLeastOneSep(e, r, n) {
    const i = fc(e, r, n);
    this.walk(e, i);
  }
  walkMany(e, r, n) {
    const i = [
      new Me({ definition: e.definition })
    ].concat(r, n);
    this.walk(e, i);
  }
  walkManySep(e, r, n) {
    const i = fc(e, r, n);
    this.walk(e, i);
  }
  walkOr(e, r, n) {
    const i = r.concat(n);
    e.definition.forEach((a) => {
      const s = new Ke({ definition: [a] });
      this.walk(s, i);
    });
  }
}
function fc(t, e, r) {
  return [
    new Me({
      definition: [
        new ae({ terminalType: t.separator })
      ].concat(t.definition)
    })
  ].concat(e, r);
}
function Ci(t) {
  if (t instanceof qe)
    return Ci(t.referencedRule);
  if (t instanceof ae)
    return Qh(t);
  if (Xh(t))
    return Jh(t);
  if (Yh(t))
    return Zh(t);
  throw Error("non exhaustive match");
}
function Jh(t) {
  let e = [];
  const r = t.definition;
  let n = 0, i = r.length > n, a, s = !0;
  for (; i && s; )
    a = r[n], s = xa(a), e = e.concat(Ci(a)), n = n + 1, i = r.length > n;
  return [...new Set(e)];
}
function Zh(t) {
  const e = t.definition.map((r) => Ci(r));
  return [...new Set(e.flat())];
}
function Qh(t) {
  return [t.terminalType];
}
const $f = "_~IN~_";
class ep extends rs {
  constructor(e) {
    super(), this.topProd = e, this.follows = {};
  }
  startWalking() {
    return this.walk(this.topProd), this.follows;
  }
  walkTerminal(e, r, n) {
  }
  walkProdRef(e, r, n) {
    const i = rp(e.referencedRule, e.idx) + this.topProd.name, a = r.concat(n), s = new Ke({ definition: a }), o = Ci(s);
    this.follows[i] = o;
  }
}
function tp(t) {
  const e = {};
  return t.forEach((r) => {
    const n = new ep(r).startWalking();
    Object.assign(e, n);
  }), e;
}
function rp(t, e) {
  return t.name + e + $f;
}
let Aa = {};
const np = new uf();
function ns(t) {
  const e = t.toString();
  if (Aa.hasOwnProperty(e))
    return Aa[e];
  {
    const r = np.pattern(e);
    return Aa[e] = r, r;
  }
}
function ip() {
  Aa = {};
}
const Cf = "Complement Sets are not supported for first char optimization", Da = `Unable to use "first char" lexer optimizations:
`;
function ap(t, e = !1) {
  try {
    const r = ns(t);
    return eo(r.value, {}, r.flags.ignoreCase);
  } catch (r) {
    if (r.message === Cf)
      e && vf(`${Da}	Unable to optimize: < ${t.toString()} >
	Complement Sets cannot be automatically optimized.
	This will disable the lexer's first char optimizations.
	See: https://chevrotain.io/docs/guide/resolving_lexer_errors.html#COMPLEMENT for details.`);
    else {
      let n = "";
      e && (n = `
	This will disable the lexer's first char optimizations.
	See: https://chevrotain.io/docs/guide/resolving_lexer_errors.html#REGEXP_PARSING for details.`), Qs(`${Da}
	Failed parsing: < ${t.toString()} >
	Using the @chevrotain/regexp-to-ast library
	Please open an issue at: https://github.com/chevrotain/chevrotain/issues` + n);
    }
  }
  return [];
}
function eo(t, e, r) {
  switch (t.type) {
    case "Disjunction":
      for (let i = 0; i < t.value.length; i++)
        eo(t.value[i], e, r);
      break;
    case "Alternative":
      const n = t.value;
      for (let i = 0; i < n.length; i++) {
        const a = n[i];
        switch (a.type) {
          case "EndAnchor":
          // A group back reference cannot affect potential starting char.
          // because if a back reference is the first production than automatically
          // the group being referenced has had to come BEFORE so its codes have already been added
          case "GroupBackReference":
          // assertions do not affect potential starting codes
          case "Lookahead":
          case "NegativeLookahead":
          case "Lookbehind":
          case "NegativeLookbehind":
          case "StartAnchor":
          case "WordBoundary":
          case "NonWordBoundary":
            continue;
        }
        const s = a;
        switch (s.type) {
          case "Character":
            Ji(s.value, e, r);
            break;
          case "Set":
            if (s.complement === !0)
              throw Error(Cf);
            s.value.forEach((l) => {
              if (typeof l == "number")
                Ji(l, e, r);
              else {
                const c = l;
                if (r === !0)
                  for (let u = c.from; u <= c.to; u++)
                    Ji(u, e, r);
                else {
                  for (let u = c.from; u <= c.to && u < ii; u++)
                    Ji(u, e, r);
                  if (c.to >= ii) {
                    const u = c.from >= ii ? c.from : ii, d = c.to, p = Zt(u), m = Zt(d);
                    for (let A = p; A <= m; A++)
                      e[A] = A;
                  }
                }
              }
            });
            break;
          case "Group":
            eo(s.value, e, r);
            break;
          /* istanbul ignore next */
          default:
            throw Error("Non Exhaustive Match");
        }
        const o = s.quantifier !== void 0 && s.quantifier.atLeast === 0;
        if (
          // A group may be optional due to empty contents /(?:)/
          // or if everything inside it is optional /((a)?)/
          s.type === "Group" && to(s) === !1 || // If this term is not a group it may only be optional if it has an optional quantifier
          s.type !== "Group" && o === !1
        )
          break;
      }
      break;
    /* istanbul ignore next */
    default:
      throw Error("non exhaustive match!");
  }
  return Object.values(e);
}
function Ji(t, e, r) {
  const n = Zt(t);
  e[n] = n, r === !0 && sp(t, e);
}
function sp(t, e) {
  const r = String.fromCharCode(t), n = r.toUpperCase();
  if (n !== r) {
    const i = Zt(n.charCodeAt(0));
    e[i] = i;
  } else {
    const i = r.toLowerCase();
    if (i !== r) {
      const a = Zt(i.charCodeAt(0));
      e[a] = a;
    }
  }
}
function dc(t, e) {
  return t.value.find((r) => {
    if (typeof r == "number")
      return e.includes(r);
    {
      const n = r;
      return e.find((i) => n.from <= i && i <= n.to) !== void 0;
    }
  });
}
function to(t) {
  const e = t.quantifier;
  return e && e.atLeast === 0 ? !0 : t.value ? Array.isArray(t.value) ? t.value.every(to) : to(t.value) : !1;
}
class op extends es {
  constructor(e) {
    super(), this.targetCharCodes = e, this.found = !1;
  }
  visitChildren(e) {
    if (this.found !== !0) {
      switch (e.type) {
        case "Lookahead":
          this.visitLookahead(e);
          return;
        case "NegativeLookahead":
          this.visitNegativeLookahead(e);
          return;
        case "Lookbehind":
          this.visitLookbehind(e);
          return;
        case "NegativeLookbehind":
          this.visitNegativeLookbehind(e);
          return;
      }
      super.visitChildren(e);
    }
  }
  visitCharacter(e) {
    this.targetCharCodes.includes(e.value) && (this.found = !0);
  }
  visitSet(e) {
    e.complement ? dc(e, this.targetCharCodes) === void 0 && (this.found = !0) : dc(e, this.targetCharCodes) !== void 0 && (this.found = !0);
  }
}
function xl(t, e) {
  if (e instanceof RegExp) {
    const r = ns(e), n = new op(t);
    return n.visit(r), n.found;
  } else {
    for (const r of e) {
      const n = r.charCodeAt(0);
      if (t.includes(n))
        return !0;
    }
    return !1;
  }
}
const Nr = "PATTERN", ni = "defaultMode", Zi = "modes";
function lp(t, e) {
  e = Object.assign({ safeMode: !1, positionTracking: "full", lineTerminatorCharacters: ["\r", `
`], tracer: (S, C) => C() }, e);
  const r = e.tracer;
  r("initCharCodeToOptimizedIndexMap", () => {
    Pp();
  });
  let n;
  r("Reject Lexer.NA", () => {
    n = t.filter((S) => S[Nr] !== We.NA);
  });
  let i = !1, a;
  r("Transform Patterns", () => {
    i = !1, a = n.map((S) => {
      const C = S[Nr];
      if (C instanceof RegExp) {
        const P = C.source;
        return P.length === 1 && // only these regExp meta characters which can appear in a length one regExp
        P !== "^" && P !== "$" && P !== "." && !C.ignoreCase ? P : P.length === 2 && P[0] === "\\" && // not a meta character
        ![
          "d",
          "D",
          "s",
          "S",
          "t",
          "r",
          "n",
          "t",
          "0",
          "c",
          "b",
          "B",
          "f",
          "v",
          "w",
          "W"
        ].includes(P[1]) ? P[1] : hc(C);
      } else {
        if (typeof C == "function")
          return i = !0, { exec: C };
        if (typeof C == "object")
          return i = !0, C;
        if (typeof C == "string") {
          if (C.length === 1)
            return C;
          {
            const P = C.replace(/[\\^$.*+?()[\]{}|]/g, "\\$&"), W = new RegExp(P);
            return hc(W);
          }
        } else
          throw Error("non exhaustive match");
      }
    });
  });
  let s, o, l, c, u;
  r("misc mapping", () => {
    s = n.map((S) => S.tokenTypeIdx), o = n.map((S) => {
      const C = S.GROUP;
      if (C !== We.SKIPPED) {
        if (typeof C == "string")
          return C;
        if (C === void 0)
          return !1;
        throw Error("non exhaustive match");
      }
    }), l = n.map((S) => {
      const C = S.LONGER_ALT;
      if (C)
        return Array.isArray(C) ? C.map((W) => n.indexOf(W)) : [n.indexOf(C)];
    }), c = n.map((S) => S.PUSH_MODE), u = n.map((S) => Object.hasOwn(S, "POP_MODE"));
  });
  let d;
  r("Line Terminator Handling", () => {
    const S = wf(e.lineTerminatorCharacters);
    d = n.map((C) => !1), e.positionTracking !== "onlyOffset" && (d = n.map((C) => Object.hasOwn(C, "LINE_BREAKS") ? !!C.LINE_BREAKS : kf(C, S) === !1 && xl(S, C.PATTERN)));
  });
  let p, m, A, b;
  r("Misc Mapping #2", () => {
    p = n.map(Sf), m = a.map(Np), A = n.reduce((S, C) => {
      const P = C.GROUP;
      return typeof P == "string" && P !== We.SKIPPED && (S[P] = []), S;
    }, {}), b = a.map((S, C) => ({
      pattern: a[C],
      longerAlt: l[C],
      canLineTerminator: d[C],
      isCustom: p[C],
      short: m[C],
      group: o[C],
      push: c[C],
      pop: u[C],
      tokenTypeIdx: s[C],
      tokenType: n[C]
    }));
  });
  let I = !0, k = [];
  return e.safeMode || r("First Char Optimization", () => {
    k = n.reduce((S, C, P) => {
      if (typeof C.PATTERN == "string") {
        const W = C.PATTERN.charCodeAt(0), B = Zt(W);
        Rs(S, B, b[P]);
      } else if (Array.isArray(C.START_CHARS_HINT)) {
        let W;
        C.START_CHARS_HINT.forEach((B) => {
          const H = typeof B == "string" ? B.charCodeAt(0) : B, ne = Zt(H);
          W !== ne && (W = ne, Rs(S, ne, b[P]));
        });
      } else if (C.PATTERN instanceof RegExp)
        if (C.PATTERN.unicode)
          I = !1, e.ensureOptimizations && Qs(`${Da}	Unable to analyze < ${C.PATTERN.toString()} > pattern.
	The regexp unicode flag is not currently supported by the regexp-to-ast library.
	This will disable the lexer's first char optimizations.
	For details See: https://chevrotain.io/docs/guide/resolving_lexer_errors.html#UNICODE_OPTIMIZE`);
        else {
          const W = ap(C.PATTERN, e.ensureOptimizations);
          W.length === 0 && (I = !1), W.forEach((B) => {
            Rs(S, B, b[P]);
          });
        }
      else
        e.ensureOptimizations && Qs(`${Da}	TokenType: <${C.name}> is using a custom token pattern without providing <start_chars_hint> parameter.
	This will disable the lexer's first char optimizations.
	For details See: https://chevrotain.io/docs/guide/resolving_lexer_errors.html#CUSTOM_OPTIMIZE`), I = !1;
      return S;
    }, []);
  }), {
    emptyGroups: A,
    patternIdxToConfig: b,
    charCodeToPatternIdxToConfig: k,
    hasCustom: i,
    canBeOptimized: I
  };
}
function cp(t, e) {
  let r = [];
  const n = fp(t);
  r = r.concat(n.errors);
  const i = dp(n.valid), a = i.valid;
  return r = r.concat(i.errors), r = r.concat(up(a)), r = r.concat(vp(a)), r = r.concat(Ep(a, e)), r = r.concat(Ap(a)), r;
}
function up(t) {
  let e = [];
  const r = t.filter((n) => n[Nr] instanceof RegExp);
  return e = e.concat(pp(r)), e = e.concat(yp(r)), e = e.concat(Tp(r)), e = e.concat(Rp(r)), e = e.concat(mp(r)), e;
}
function fp(t) {
  const e = t.filter((i) => !Object.hasOwn(i, Nr)), r = e.map((i) => ({
    message: "Token Type: ->" + i.name + "<- missing static 'PATTERN' property",
    type: Re.MISSING_PATTERN,
    tokenTypes: [i]
  })), n = t.filter((i) => !e.includes(i));
  return { errors: r, valid: n };
}
function dp(t) {
  const e = t.filter((i) => {
    const a = i[Nr];
    return !(a instanceof RegExp) && typeof a != "function" && !Object.hasOwn(a, "exec") && typeof a != "string";
  }), r = e.map((i) => ({
    message: "Token Type: ->" + i.name + "<- static 'PATTERN' can only be a RegExp, a Function matching the {CustomPatternMatcherFunc} type or an Object matching the {ICustomPattern} interface.",
    type: Re.INVALID_PATTERN,
    tokenTypes: [i]
  })), n = t.filter((i) => !e.includes(i));
  return { errors: r, valid: n };
}
const hp = /[^\\][$]/;
function pp(t) {
  class e extends es {
    constructor() {
      super(...arguments), this.found = !1;
    }
    visitEndAnchor(a) {
      this.found = !0;
    }
  }
  return t.filter((i) => {
    const a = i.PATTERN;
    try {
      const s = ns(a), o = new e();
      return o.visit(s), o.found;
    } catch {
      return hp.test(a.source);
    }
  }).map((i) => ({
    message: `Unexpected RegExp Anchor Error:
	Token Type: ->` + i.name + `<- static 'PATTERN' cannot contain end of input anchor '$'
	See chevrotain.io/docs/guide/resolving_lexer_errors.html#ANCHORS	for details.`,
    type: Re.EOI_ANCHOR_FOUND,
    tokenTypes: [i]
  }));
}
function mp(t) {
  return t.filter((n) => n.PATTERN.test("")).map((n) => ({
    message: "Token Type: ->" + n.name + "<- static 'PATTERN' must not match an empty string",
    type: Re.EMPTY_MATCH_PATTERN,
    tokenTypes: [n]
  }));
}
const gp = /[^\\[][\^]|^\^/;
function yp(t) {
  class e extends es {
    constructor() {
      super(...arguments), this.found = !1;
    }
    visitStartAnchor(a) {
      this.found = !0;
    }
  }
  return t.filter((i) => {
    const a = i.PATTERN;
    try {
      const s = ns(a), o = new e();
      return o.visit(s), o.found;
    } catch {
      return gp.test(a.source);
    }
  }).map((i) => ({
    message: `Unexpected RegExp Anchor Error:
	Token Type: ->` + i.name + `<- static 'PATTERN' cannot contain start of input anchor '^'
	See https://chevrotain.io/docs/guide/resolving_lexer_errors.html#ANCHORS	for details.`,
    type: Re.SOI_ANCHOR_FOUND,
    tokenTypes: [i]
  }));
}
function Tp(t) {
  return t.filter((n) => {
    const i = n[Nr];
    return i instanceof RegExp && (i.multiline || i.global);
  }).map((n) => ({
    message: "Token Type: ->" + n.name + "<- static 'PATTERN' may NOT contain global('g') or multiline('m')",
    type: Re.UNSUPPORTED_FLAGS_FOUND,
    tokenTypes: [n]
  }));
}
function Rp(t) {
  const e = [];
  let r = t.map((a) => t.reduce((s, o) => (a.PATTERN.source === o.PATTERN.source && !e.includes(o) && o.PATTERN !== We.NA && (e.push(o), s.push(o)), s), []));
  return r = r.filter(Boolean), r.filter((a) => a.length > 1).map((a) => {
    const s = a.map((l) => l.name);
    return {
      message: `The same RegExp pattern ->${a[0].PATTERN}<-has been used in all of the following Token Types: ${s.join(", ")} <-`,
      type: Re.DUPLICATE_PATTERNS_FOUND,
      tokenTypes: a
    };
  });
}
function vp(t) {
  return t.filter((n) => {
    if (!Object.hasOwn(n, "GROUP"))
      return !1;
    const i = n.GROUP;
    return i !== We.SKIPPED && i !== We.NA && typeof i != "string";
  }).map((n) => ({
    message: "Token Type: ->" + n.name + "<- static 'GROUP' can only be Lexer.SKIPPED/Lexer.NA/A String",
    type: Re.INVALID_GROUP_TYPE_FOUND,
    tokenTypes: [n]
  }));
}
function Ep(t, e) {
  return t.filter((i) => i.PUSH_MODE !== void 0 && !e.includes(i.PUSH_MODE)).map((i) => ({
    message: `Token Type: ->${i.name}<- static 'PUSH_MODE' value cannot refer to a Lexer Mode ->${i.PUSH_MODE}<-which does not exist`,
    type: Re.PUSH_MODE_DOES_NOT_EXIST,
    tokenTypes: [i]
  }));
}
function Ap(t) {
  const e = [], r = t.reduce((n, i, a) => {
    const s = i.PATTERN;
    return s === We.NA || (typeof s == "string" ? n.push({ str: s, idx: a, tokenType: i }) : s instanceof RegExp && Cp(s) && n.push({ str: s.source, idx: a, tokenType: i })), n;
  }, []);
  return t.forEach((n, i) => {
    r.forEach(({ str: a, idx: s, tokenType: o }) => {
      if (i < s && $p(a, n.PATTERN)) {
        const l = `Token: ->${o.name}<- can never be matched.
Because it appears AFTER the Token Type ->${n.name}<-in the lexer's definition.
See https://chevrotain.io/docs/guide/resolving_lexer_errors.html#UNREACHABLE`;
        e.push({
          message: l,
          type: Re.UNREACHABLE_PATTERN,
          tokenTypes: [n, o]
        });
      }
    });
  }), e;
}
function $p(t, e) {
  if (e instanceof RegExp) {
    if (Sp(e))
      return !1;
    const r = e.exec(t);
    return r !== null && r.index === 0;
  } else {
    if (typeof e == "function")
      return e(t, 0, [], {});
    if (Object.hasOwn(e, "exec"))
      return e.exec(t, 0, [], {});
    if (typeof e == "string")
      return e === t;
    throw Error("non exhaustive match");
  }
}
function Cp(t) {
  return [
    ".",
    "\\",
    "[",
    "]",
    "|",
    "^",
    "$",
    "(",
    ")",
    "?",
    "*",
    "+",
    "{"
  ].find((r) => t.source.indexOf(r) !== -1) === void 0;
}
function Sp(t) {
  return /(\(\?=)|(\(\?!)|(\(\?<=)|(\(\?<!)/.test(t.source);
}
function hc(t) {
  const e = t.ignoreCase ? "iy" : "y";
  return new RegExp(`${t.source}`, e);
}
function kp(t, e, r) {
  const n = [];
  return Object.hasOwn(t, ni) || n.push({
    message: "A MultiMode Lexer cannot be initialized without a <" + ni + `> property in its definition
`,
    type: Re.MULTI_MODE_LEXER_WITHOUT_DEFAULT_MODE
  }), Object.hasOwn(t, Zi) || n.push({
    message: "A MultiMode Lexer cannot be initialized without a <" + Zi + `> property in its definition
`,
    type: Re.MULTI_MODE_LEXER_WITHOUT_MODES_PROPERTY
  }), Object.hasOwn(t, Zi) && Object.hasOwn(t, ni) && !Object.hasOwn(t.modes, t.defaultMode) && n.push({
    message: `A MultiMode Lexer cannot be initialized with a ${ni}: <${t.defaultMode}>which does not exist
`,
    type: Re.MULTI_MODE_LEXER_DEFAULT_MODE_VALUE_DOES_NOT_EXIST
  }), Object.hasOwn(t, Zi) && Object.keys(t.modes).forEach((i) => {
    const a = t.modes[i];
    a.forEach((s, o) => {
      s === void 0 ? n.push({
        message: `A Lexer cannot be initialized using an undefined Token Type. Mode:<${i}> at index: <${o}>
`,
        type: Re.LEXER_DEFINITION_CANNOT_CONTAIN_UNDEFINED
      }) : Object.hasOwn(s, "LONGER_ALT") && (Array.isArray(s.LONGER_ALT) ? s.LONGER_ALT : [s.LONGER_ALT]).forEach((c) => {
        c !== void 0 && !a.includes(c) && n.push({
          message: `A MultiMode Lexer cannot be initialized with a longer_alt <${c.name}> on token <${s.name}> outside of mode <${i}>
`,
          type: Re.MULTI_MODE_LEXER_LONGER_ALT_NOT_IN_CURRENT_MODE
        });
      });
    });
  }), n;
}
function wp(t, e, r) {
  const n = [];
  let i = !1;
  const s = Object.values(t.modes || {}).flat().filter(Boolean).filter((l) => l[Nr] !== We.NA), o = wf(r);
  return e && s.forEach((l) => {
    const c = kf(l, o);
    if (c !== !1) {
      const d = {
        message: Ip(l, c),
        type: c.issue,
        tokenType: l
      };
      n.push(d);
    } else
      Object.hasOwn(l, "LINE_BREAKS") ? l.LINE_BREAKS === !0 && (i = !0) : xl(o, l.PATTERN) && (i = !0);
  }), e && !i && n.push({
    message: `Warning: No LINE_BREAKS Found.
	This Lexer has been defined to track line and column information,
	But none of the Token Types can be identified as matching a line terminator.
	See https://chevrotain.io/docs/guide/resolving_lexer_errors.html#LINE_BREAKS 
	for details.`,
    type: Re.NO_LINE_BREAKS_FLAGS
  }), n;
}
function bp(t) {
  const e = {};
  return Object.keys(t).forEach((n) => {
    const i = t[n];
    if (Array.isArray(i))
      e[n] = [];
    else
      throw Error("non exhaustive match");
  }), e;
}
function Sf(t) {
  const e = t.PATTERN;
  if (e instanceof RegExp)
    return !1;
  if (typeof e == "function")
    return !0;
  if (Object.hasOwn(e, "exec"))
    return !0;
  if (typeof e == "string")
    return !1;
  throw Error("non exhaustive match");
}
function Np(t) {
  return typeof t == "string" && t.length === 1 ? t.charCodeAt(0) : !1;
}
const _p = {
  // implements /\n|\r\n?/g.test
  test: function(t) {
    const e = t.length;
    for (let r = this.lastIndex; r < e; r++) {
      const n = t.charCodeAt(r);
      if (n === 10)
        return this.lastIndex = r + 1, !0;
      if (n === 13)
        return t.charCodeAt(r + 1) === 10 ? this.lastIndex = r + 2 : this.lastIndex = r + 1, !0;
    }
    return !1;
  },
  lastIndex: 0
};
function kf(t, e) {
  if (Object.hasOwn(t, "LINE_BREAKS"))
    return !1;
  if (t.PATTERN instanceof RegExp) {
    try {
      xl(e, t.PATTERN);
    } catch (r) {
      return {
        issue: Re.IDENTIFY_TERMINATOR,
        errMsg: r.message
      };
    }
    return !1;
  } else {
    if (typeof t.PATTERN == "string")
      return !1;
    if (Sf(t))
      return { issue: Re.CUSTOM_LINE_BREAK };
    throw Error("non exhaustive match");
  }
}
function Ip(t, e) {
  if (e.issue === Re.IDENTIFY_TERMINATOR)
    return `Warning: unable to identify line terminator usage in pattern.
	The problem is in the <${t.name}> Token Type
	 Root cause: ${e.errMsg}.
	For details See: https://chevrotain.io/docs/guide/resolving_lexer_errors.html#IDENTIFY_TERMINATOR`;
  if (e.issue === Re.CUSTOM_LINE_BREAK)
    return `Warning: A Custom Token Pattern should specify the <line_breaks> option.
	The problem is in the <${t.name}> Token Type
	For details See: https://chevrotain.io/docs/guide/resolving_lexer_errors.html#CUSTOM_LINE_BREAK`;
  throw Error("non exhaustive match");
}
function wf(t) {
  return t.map((r) => typeof r == "string" ? r.charCodeAt(0) : r);
}
function Rs(t, e, r) {
  t[e] === void 0 ? t[e] = [r] : t[e].push(r);
}
const ii = 256;
let $a = [];
function Zt(t) {
  return t < ii ? t : $a[t];
}
function Pp() {
  if ($a.length === 0) {
    $a = new Array(65536);
    for (let t = 0; t < 65536; t++)
      $a[t] = t > 255 ? 255 + ~~(t / 255) : t;
  }
}
function Si(t, e) {
  const r = t.tokenTypeIdx;
  return r === e.tokenTypeIdx ? !0 : e.isParent === !0 && e.categoryMatchesMap[r] === !0;
}
function Ma(t, e) {
  return t.tokenTypeIdx === e.tokenTypeIdx;
}
let pc = 1;
const bf = {};
function ki(t) {
  const e = Op(t);
  Lp(e), Dp(e), xp(e), e.forEach((r) => {
    r.isParent = r.categoryMatches.length > 0;
  });
}
function Op(t) {
  let e = [...t], r = t, n = !0;
  for (; n; ) {
    r = r.map((a) => a.CATEGORIES).flat().filter(Boolean);
    const i = r.filter((a) => !e.includes(a));
    e = e.concat(i), i.length === 0 ? n = !1 : r = i;
  }
  return e;
}
function Lp(t) {
  t.forEach((e) => {
    _f(e) || (bf[pc] = e, e.tokenTypeIdx = pc++), mc(e) && !Array.isArray(e.CATEGORIES) && (e.CATEGORIES = [e.CATEGORIES]), mc(e) || (e.CATEGORIES = []), Mp(e) || (e.categoryMatches = []), Fp(e) || (e.categoryMatchesMap = {});
  });
}
function xp(t) {
  t.forEach((e) => {
    e.categoryMatches = [], Object.keys(e.categoryMatchesMap).forEach((r) => {
      e.categoryMatches.push(bf[r].tokenTypeIdx);
    });
  });
}
function Dp(t) {
  t.forEach((e) => {
    Nf([], e);
  });
}
function Nf(t, e) {
  t.forEach((r) => {
    e.categoryMatchesMap[r.tokenTypeIdx] = !0;
  }), e.CATEGORIES.forEach((r) => {
    const n = t.concat(e);
    n.includes(r) || Nf(n, r);
  });
}
function _f(t) {
  return Object.hasOwn(t ?? {}, "tokenTypeIdx");
}
function mc(t) {
  return Object.hasOwn(t ?? {}, "CATEGORIES");
}
function Mp(t) {
  return Object.hasOwn(t ?? {}, "categoryMatches");
}
function Fp(t) {
  return Object.hasOwn(t ?? {}, "categoryMatchesMap");
}
function Gp(t) {
  return Object.hasOwn(t ?? {}, "tokenTypeIdx");
}
const ro = {
  buildUnableToPopLexerModeMessage(t) {
    return `Unable to pop Lexer Mode after encountering Token ->${t.image}<- The Mode Stack is empty`;
  },
  buildUnexpectedCharactersMessage(t, e, r, n, i, a) {
    return `unexpected character: ->${t.charAt(e)}<- at offset: ${e}, skipped ${r} characters.`;
  }
};
var Re;
(function(t) {
  t[t.MISSING_PATTERN = 0] = "MISSING_PATTERN", t[t.INVALID_PATTERN = 1] = "INVALID_PATTERN", t[t.EOI_ANCHOR_FOUND = 2] = "EOI_ANCHOR_FOUND", t[t.UNSUPPORTED_FLAGS_FOUND = 3] = "UNSUPPORTED_FLAGS_FOUND", t[t.DUPLICATE_PATTERNS_FOUND = 4] = "DUPLICATE_PATTERNS_FOUND", t[t.INVALID_GROUP_TYPE_FOUND = 5] = "INVALID_GROUP_TYPE_FOUND", t[t.PUSH_MODE_DOES_NOT_EXIST = 6] = "PUSH_MODE_DOES_NOT_EXIST", t[t.MULTI_MODE_LEXER_WITHOUT_DEFAULT_MODE = 7] = "MULTI_MODE_LEXER_WITHOUT_DEFAULT_MODE", t[t.MULTI_MODE_LEXER_WITHOUT_MODES_PROPERTY = 8] = "MULTI_MODE_LEXER_WITHOUT_MODES_PROPERTY", t[t.MULTI_MODE_LEXER_DEFAULT_MODE_VALUE_DOES_NOT_EXIST = 9] = "MULTI_MODE_LEXER_DEFAULT_MODE_VALUE_DOES_NOT_EXIST", t[t.LEXER_DEFINITION_CANNOT_CONTAIN_UNDEFINED = 10] = "LEXER_DEFINITION_CANNOT_CONTAIN_UNDEFINED", t[t.SOI_ANCHOR_FOUND = 11] = "SOI_ANCHOR_FOUND", t[t.EMPTY_MATCH_PATTERN = 12] = "EMPTY_MATCH_PATTERN", t[t.NO_LINE_BREAKS_FLAGS = 13] = "NO_LINE_BREAKS_FLAGS", t[t.UNREACHABLE_PATTERN = 14] = "UNREACHABLE_PATTERN", t[t.IDENTIFY_TERMINATOR = 15] = "IDENTIFY_TERMINATOR", t[t.CUSTOM_LINE_BREAK = 16] = "CUSTOM_LINE_BREAK", t[t.MULTI_MODE_LEXER_LONGER_ALT_NOT_IN_CURRENT_MODE = 17] = "MULTI_MODE_LEXER_LONGER_ALT_NOT_IN_CURRENT_MODE";
})(Re || (Re = {}));
const ai = {
  deferDefinitionErrorsHandling: !1,
  positionTracking: "full",
  lineTerminatorsPattern: /\n|\r\n?/g,
  lineTerminatorCharacters: [`
`, "\r"],
  ensureOptimizations: !1,
  safeMode: !1,
  errorMessageProvider: ro,
  traceInitPerf: !1,
  skipValidations: !1,
  recoveryEnabled: !0
};
Object.freeze(ai);
class We {
  constructor(e, r = ai) {
    if (this.lexerDefinition = e, this.lexerDefinitionErrors = [], this.lexerDefinitionWarning = [], this.patternIdxToConfig = {}, this.charCodeToPatternIdxToConfig = {}, this.modes = [], this.emptyGroups = {}, this.trackStartLines = !0, this.trackEndLines = !0, this.hasCustom = !1, this.canModeBeOptimized = {}, this.TRACE_INIT = (i, a) => {
      if (this.traceInitPerf === !0) {
        this.traceInitIndent++;
        const s = new Array(this.traceInitIndent + 1).join("	");
        this.traceInitIndent < this.traceInitMaxIdent && console.log(`${s}--> <${i}>`);
        const { time: o, value: l } = Ef(a), c = o > 10 ? console.warn : console.log;
        return this.traceInitIndent < this.traceInitMaxIdent && c(`${s}<-- <${i}> time: ${o}ms`), this.traceInitIndent--, l;
      } else
        return a();
    }, typeof r == "boolean")
      throw Error(`The second argument to the Lexer constructor is now an ILexerConfig Object.
a boolean 2nd argument is no longer supported`);
    this.config = Object.assign({}, ai, r);
    const n = this.config.traceInitPerf;
    n === !0 ? (this.traceInitMaxIdent = 1 / 0, this.traceInitPerf = !0) : typeof n == "number" && (this.traceInitMaxIdent = n, this.traceInitPerf = !0), this.traceInitIndent = -1, this.TRACE_INIT("Lexer Constructor", () => {
      let i, a = !0;
      this.TRACE_INIT("Lexer Config handling", () => {
        if (this.config.lineTerminatorsPattern === ai.lineTerminatorsPattern)
          this.config.lineTerminatorsPattern = _p;
        else if (this.config.lineTerminatorCharacters === ai.lineTerminatorCharacters)
          throw Error(`Error: Missing <lineTerminatorCharacters> property on the Lexer config.
	For details See: https://chevrotain.io/docs/guide/resolving_lexer_errors.html#MISSING_LINE_TERM_CHARS`);
        if (r.safeMode && r.ensureOptimizations)
          throw Error('"safeMode" and "ensureOptimizations" flags are mutually exclusive.');
        this.trackStartLines = /full|onlyStart/i.test(this.config.positionTracking), this.trackEndLines = /full/i.test(this.config.positionTracking), Array.isArray(e) ? i = {
          modes: { defaultMode: [...e] },
          defaultMode: ni
        } : (a = !1, i = Object.assign({}, e));
      }), this.config.skipValidations === !1 && (this.TRACE_INIT("performRuntimeChecks", () => {
        this.lexerDefinitionErrors = this.lexerDefinitionErrors.concat(kp(i, this.trackStartLines, this.config.lineTerminatorCharacters));
      }), this.TRACE_INIT("performWarningRuntimeChecks", () => {
        this.lexerDefinitionWarning = this.lexerDefinitionWarning.concat(wp(i, this.trackStartLines, this.config.lineTerminatorCharacters));
      })), i.modes = i.modes ? i.modes : {}, Object.entries(i.modes).forEach(([o, l]) => {
        i.modes[o] = l.filter((c) => c !== void 0);
      });
      const s = Object.keys(i.modes);
      if (Object.entries(i.modes).forEach(([o, l]) => {
        this.TRACE_INIT(`Mode: <${o}> processing`, () => {
          if (this.modes.push(o), this.config.skipValidations === !1 && this.TRACE_INIT("validatePatterns", () => {
            this.lexerDefinitionErrors = this.lexerDefinitionErrors.concat(cp(l, s));
          }), this.lexerDefinitionErrors.length === 0) {
            ki(l);
            let c;
            this.TRACE_INIT("analyzeTokenTypes", () => {
              c = lp(l, {
                lineTerminatorCharacters: this.config.lineTerminatorCharacters,
                positionTracking: r.positionTracking,
                ensureOptimizations: r.ensureOptimizations,
                safeMode: r.safeMode,
                tracer: this.TRACE_INIT
              });
            }), this.patternIdxToConfig[o] = c.patternIdxToConfig, this.charCodeToPatternIdxToConfig[o] = c.charCodeToPatternIdxToConfig, this.emptyGroups = Object.assign({}, this.emptyGroups, c.emptyGroups), this.hasCustom = c.hasCustom || this.hasCustom, this.canModeBeOptimized[o] = c.canBeOptimized;
          }
        });
      }), this.defaultMode = i.defaultMode, this.lexerDefinitionErrors.length > 0 && !this.config.deferDefinitionErrorsHandling) {
        const l = this.lexerDefinitionErrors.map((c) => c.message).join(`-----------------------
`);
        throw new Error(`Errors detected in definition of Lexer:
` + l);
      }
      this.lexerDefinitionWarning.forEach((o) => {
        vf(o.message);
      }), this.TRACE_INIT("Choosing sub-methods implementations", () => {
        if (a && (this.handleModes = () => {
        }), this.trackStartLines === !1 && (this.computeNewColumn = (o) => o), this.trackEndLines === !1 && (this.updateTokenEndLineColumnLocation = () => {
        }), /full/i.test(this.config.positionTracking))
          this.createTokenInstance = this.createFullToken;
        else if (/onlyStart/i.test(this.config.positionTracking))
          this.createTokenInstance = this.createStartOnlyToken;
        else if (/onlyOffset/i.test(this.config.positionTracking))
          this.createTokenInstance = this.createOffsetOnlyToken;
        else
          throw Error(`Invalid <positionTracking> config option: "${this.config.positionTracking}"`);
        this.hasCustom ? (this.addToken = this.addTokenUsingPush, this.handlePayload = this.handlePayloadWithCustom) : (this.addToken = this.addTokenUsingMemberAccess, this.handlePayload = this.handlePayloadNoCustom);
      }), this.TRACE_INIT("Failed Optimization Warnings", () => {
        const o = Object.entries(this.canModeBeOptimized).reduce((l, [c, u]) => (u === !1 && l.push(c), l), []);
        if (r.ensureOptimizations && o.length > 0)
          throw Error(`Lexer Modes: < ${o.join(", ")} > cannot be optimized.
	 Disable the "ensureOptimizations" lexer config flag to silently ignore this and run the lexer in an un-optimized mode.
	 Or inspect the console log for details on how to resolve these issues.`);
      }), this.TRACE_INIT("clearRegExpParserCache", () => {
        ip();
      }), this.TRACE_INIT("toFastProperties", () => {
        Af(this);
      });
    });
  }
  tokenize(e, r = this.defaultMode) {
    if (this.lexerDefinitionErrors.length > 0) {
      const i = this.lexerDefinitionErrors.map((a) => a.message).join(`-----------------------
`);
      throw new Error(`Unable to Tokenize because Errors detected in definition of Lexer:
` + i);
    }
    return this.tokenizeInternal(e, r);
  }
  // There is quite a bit of duplication between this and "tokenizeInternalLazy"
  // This is intentional due to performance considerations.
  // this method also used quite a bit of `!` none null assertions because it is too optimized
  // for `tsc` to always understand it is "safe"
  tokenizeInternal(e, r) {
    let n, i, a, s, o, l, c, u, d, p, m, A, b, I, k;
    const S = e, C = S.length;
    let P = 0, W = 0;
    const B = this.hasCustom ? 0 : Math.floor(e.length / 10), H = new Array(B), ne = [];
    let se = this.trackStartLines ? 1 : void 0, oe = this.trackStartLines ? 1 : void 0;
    const N = bp(this.emptyGroups), T = this.trackStartLines, g = this.config.lineTerminatorsPattern;
    let $ = 0, y = [], R = [];
    const E = [], L = [];
    Object.freeze(L);
    let D = !1;
    const x = (z) => {
      if (E.length === 1 && // if we have both a POP_MODE and a PUSH_MODE this is in-fact a "transition"
      // So no error should occur.
      z.tokenType.PUSH_MODE === void 0) {
        const Q = this.config.errorMessageProvider.buildUnableToPopLexerModeMessage(z);
        ne.push({
          offset: z.startOffset,
          line: z.startLine,
          column: z.startColumn,
          length: z.image.length,
          message: Q
        });
      } else {
        E.pop();
        const Q = E.at(-1);
        y = this.patternIdxToConfig[Q], R = this.charCodeToPatternIdxToConfig[Q], $ = y.length;
        const _e = this.canModeBeOptimized[Q] && this.config.safeMode === !1;
        R && _e ? D = !0 : D = !1;
      }
    };
    function j(z) {
      E.push(z), R = this.charCodeToPatternIdxToConfig[z], y = this.patternIdxToConfig[z], $ = y.length, $ = y.length;
      const Q = this.canModeBeOptimized[z] && this.config.safeMode === !1;
      R && Q ? D = !0 : D = !1;
    }
    j.call(this, r);
    let F;
    const te = this.config.recoveryEnabled;
    for (; P < C; ) {
      l = null, d = -1;
      const z = S.charCodeAt(P);
      let Q;
      if (D) {
        const me = Zt(z), le = R[me];
        Q = le !== void 0 ? le : L;
      } else
        Q = y;
      const _e = Q.length;
      for (n = 0; n < _e; n++) {
        F = Q[n];
        const me = F.pattern;
        c = null;
        const le = F.short;
        if (le !== !1 ? z === le && (d = 1, l = me) : F.isCustom === !0 ? (k = me.exec(S, P, H, N), k !== null ? (l = k[0], d = l.length, k.payload !== void 0 && (c = k.payload)) : l = null) : (me.lastIndex = P, d = this.matchLength(me, e, P)), d !== -1) {
          if (o = F.longerAlt, o !== void 0) {
            l = e.substring(P, P + d);
            const we = o.length;
            for (a = 0; a < we; a++) {
              const Ie = y[o[a]], Ce = Ie.pattern;
              if (u = null, Ie.isCustom === !0 ? (k = Ce.exec(S, P, H, N), k !== null ? (s = k[0], k.payload !== void 0 && (u = k.payload)) : s = null) : (Ce.lastIndex = P, s = this.match(Ce, e, P)), s && s.length > l.length) {
                l = s, d = s.length, c = u, F = Ie;
                break;
              }
            }
          }
          break;
        }
      }
      if (d !== -1) {
        if (p = F.group, p !== void 0 && (l = l !== null ? l : e.substring(P, P + d), m = F.tokenTypeIdx, A = this.createTokenInstance(l, P, m, F.tokenType, se, oe, d), this.handlePayload(A, c), p === !1 ? W = this.addToken(H, W, A) : N[p].push(A)), T === !0 && F.canLineTerminator === !0) {
          let me = 0, le, we;
          g.lastIndex = 0;
          do
            l = l !== null ? l : e.substring(P, P + d), le = g.test(l), le === !0 && (we = g.lastIndex - 1, me++);
          while (le === !0);
          me !== 0 ? (se = se + me, oe = d - we, this.updateTokenEndLineColumnLocation(A, p, we, me, se, oe, d)) : oe = this.computeNewColumn(oe, d);
        } else
          oe = this.computeNewColumn(oe, d);
        P = P + d, this.handleModes(F, x, j, A);
      } else {
        const me = P, le = se, we = oe;
        let Ie = te === !1;
        for (; Ie === !1 && P < C; )
          for (P++, i = 0; i < $; i++) {
            const Ce = y[i], Y = Ce.pattern, Xe = Ce.short;
            if (Xe !== !1 ? S.charCodeAt(P) === Xe && (Ie = !0) : Ce.isCustom === !0 ? Ie = Y.exec(S, P, H, N) !== null : (Y.lastIndex = P, Ie = Y.exec(e) !== null), Ie === !0)
              break;
          }
        if (b = P - me, oe = this.computeNewColumn(oe, b), I = this.config.errorMessageProvider.buildUnexpectedCharactersMessage(S, me, b, le, we, E.at(-1)), ne.push({
          offset: me,
          line: le,
          column: we,
          length: b,
          message: I
        }), te === !1)
          break;
      }
    }
    return this.hasCustom || (H.length = W), {
      tokens: H,
      groups: N,
      errors: ne
    };
  }
  handleModes(e, r, n, i) {
    if (e.pop === !0) {
      const a = e.push;
      r(i), a !== void 0 && n.call(this, a);
    } else e.push !== void 0 && n.call(this, e.push);
  }
  // TODO: decrease this under 600 characters? inspect stripping comments option in TSC compiler
  updateTokenEndLineColumnLocation(e, r, n, i, a, s, o) {
    let l, c;
    r !== void 0 && (l = n === o - 1, c = l ? -1 : 0, i === 1 && l === !0 || (e.endLine = a + c, e.endColumn = s - 1 + -c));
  }
  computeNewColumn(e, r) {
    return e + r;
  }
  createOffsetOnlyToken(e, r, n, i) {
    return {
      image: e,
      startOffset: r,
      tokenTypeIdx: n,
      tokenType: i
    };
  }
  createStartOnlyToken(e, r, n, i, a, s) {
    return {
      image: e,
      startOffset: r,
      startLine: a,
      startColumn: s,
      tokenTypeIdx: n,
      tokenType: i
    };
  }
  createFullToken(e, r, n, i, a, s, o) {
    return {
      image: e,
      startOffset: r,
      endOffset: r + o - 1,
      startLine: a,
      endLine: a,
      startColumn: s,
      endColumn: s + o - 1,
      tokenTypeIdx: n,
      tokenType: i
    };
  }
  addTokenUsingPush(e, r, n) {
    return e.push(n), r;
  }
  addTokenUsingMemberAccess(e, r, n) {
    return e[r] = n, r++, r;
  }
  handlePayloadNoCustom(e, r) {
  }
  handlePayloadWithCustom(e, r) {
    r !== null && (e.payload = r);
  }
  match(e, r, n) {
    return e.test(r) === !0 ? r.substring(n, e.lastIndex) : null;
  }
  matchLength(e, r, n) {
    return e.test(r) === !0 ? e.lastIndex - n : -1;
  }
}
We.SKIPPED = "This marks a skipped Token pattern, this means each token identified by it will be consumed and then thrown into oblivion, this can be used to for example to completely ignore whitespace.";
We.NA = /NOT_APPLICABLE/;
function nn(t) {
  return If(t) ? t.LABEL : t.name;
}
function If(t) {
  return typeof t.LABEL == "string" && t.LABEL !== "";
}
const jp = "parent", gc = "categories", yc = "label", Tc = "group", Rc = "push_mode", vc = "pop_mode", Ec = "longer_alt", Ac = "line_breaks", $c = "start_chars_hint";
function Pf(t) {
  return zp(t);
}
function zp(t) {
  const e = t.pattern, r = {};
  if (r.name = t.name, e !== void 0 && (r.PATTERN = e), Object.hasOwn(t, jp))
    throw `The parent property is no longer supported.
See: https://github.com/chevrotain/chevrotain/issues/564#issuecomment-349062346 for details.`;
  return Object.hasOwn(t, gc) && (r.CATEGORIES = t[gc]), ki([r]), Object.hasOwn(t, yc) && (r.LABEL = t[yc]), Object.hasOwn(t, Tc) && (r.GROUP = t[Tc]), Object.hasOwn(t, vc) && (r.POP_MODE = t[vc]), Object.hasOwn(t, Rc) && (r.PUSH_MODE = t[Rc]), Object.hasOwn(t, Ec) && (r.LONGER_ALT = t[Ec]), Object.hasOwn(t, Ac) && (r.LINE_BREAKS = t[Ac]), Object.hasOwn(t, $c) && (r.START_CHARS_HINT = t[$c]), r;
}
const Qt = Pf({ name: "EOF", pattern: We.NA });
ki([Qt]);
function Dl(t, e, r, n, i, a, s, o) {
  return {
    image: e,
    startOffset: r,
    endOffset: n,
    startLine: i,
    endLine: a,
    startColumn: s,
    endColumn: o,
    tokenTypeIdx: t.tokenTypeIdx,
    tokenType: t
  };
}
function Of(t, e) {
  return Si(t, e);
}
const tn = {
  buildMismatchTokenMessage({ expected: t, actual: e, previous: r, ruleName: n }) {
    return `Expecting ${If(t) ? `--> ${nn(t)} <--` : `token of type --> ${t.name} <--`} but found --> '${e.image}' <--`;
  },
  buildNotAllInputParsedMessage({ firstRedundant: t, ruleName: e }) {
    return "Redundant input, expecting EOF but found: " + t.image;
  },
  buildNoViableAltMessage({ expectedPathsPerAlt: t, actual: e, previous: r, customUserDescription: n, ruleName: i }) {
    const a = "Expecting: ", o = `
but found: '` + e[0].image + "'";
    if (n)
      return a + n + o;
    {
      const d = `one of these possible Token sequences:
${t.reduce((p, m) => p.concat(m), []).map((p) => `[${p.map((m) => nn(m)).join(", ")}]`).map((p, m) => `  ${m + 1}. ${p}`).join(`
`)}`;
      return a + d + o;
    }
  },
  buildEarlyExitMessage({ expectedIterationPaths: t, actual: e, customUserDescription: r, ruleName: n }) {
    const i = "Expecting: ", s = `
but found: '` + e[0].image + "'";
    if (r)
      return i + r + s;
    {
      const l = `expecting at least one iteration which starts with one of these possible Token sequences::
  <${t.map((c) => `[${c.map((u) => nn(u)).join(",")}]`).join(" ,")}>`;
      return i + l + s;
    }
  }
};
Object.freeze(tn);
const Up = {
  buildRuleNotFoundError(t, e) {
    return "Invalid grammar, reference to a rule which is not defined: ->" + e.nonTerminalName + `<-
inside top level rule: ->` + t.name + "<-";
  }
}, Cr = {
  buildDuplicateFoundError(t, e) {
    function r(u) {
      return u instanceof ae ? u.terminalType.name : u instanceof qe ? u.nonTerminalName : "";
    }
    const n = t.name, i = e[0], a = i.idx, s = mt(i), o = r(i), l = a > 0;
    let c = `->${s}${l ? a : ""}<- ${o ? `with argument: ->${o}<-` : ""}
                  appears more than once (${e.length} times) in the top level rule: ->${n}<-.                  
                  For further details see: https://chevrotain.io/docs/FAQ.html#NUMERICAL_SUFFIXES 
                  `;
    return c = c.replace(/[ \t]+/g, " "), c = c.replace(/\s\s+/g, `
`), c;
  },
  buildNamespaceConflictError(t) {
    return `Namespace conflict found in grammar.
The grammar has both a Terminal(Token) and a Non-Terminal(Rule) named: <${t.name}>.
To resolve this make sure each Terminal and Non-Terminal names are unique
This is easy to accomplish by using the convention that Terminal names start with an uppercase letter
and Non-Terminal names start with a lower case letter.`;
  },
  buildAlternationPrefixAmbiguityError(t) {
    const e = t.prefixPath.map((i) => nn(i)).join(", "), r = t.alternation.idx === 0 ? "" : t.alternation.idx;
    return `Ambiguous alternatives: <${t.ambiguityIndices.join(" ,")}> due to common lookahead prefix
in <OR${r}> inside <${t.topLevelRule.name}> Rule,
<${e}> may appears as a prefix path in all these alternatives.
See: https://chevrotain.io/docs/guide/resolving_grammar_errors.html#COMMON_PREFIX
For Further details.`;
  },
  buildAlternationAmbiguityError(t) {
    const e = t.alternation.idx === 0 ? "" : t.alternation.idx, r = t.prefixPath.length === 0;
    let n = `Ambiguous Alternatives Detected: <${t.ambiguityIndices.join(" ,")}> in <OR${e}> inside <${t.topLevelRule.name}> Rule,
`;
    if (r)
      n += `These alternatives are all empty (match no tokens), making them indistinguishable.
Only the last alternative may be empty.
`;
    else {
      const i = t.prefixPath.map((a) => nn(a)).join(", ");
      n += `<${i}> may appears as a prefix path in all these alternatives.
`;
    }
    return n += `See: https://chevrotain.io/docs/guide/resolving_grammar_errors.html#AMBIGUOUS_ALTERNATIVES
For Further details.`, n;
  },
  buildEmptyRepetitionError(t) {
    let e = mt(t.repetition);
    return t.repetition.idx !== 0 && (e += t.repetition.idx), `The repetition <${e}> within Rule <${t.topLevelRule.name}> can never consume any tokens.
This could lead to an infinite loop.`;
  },
  // TODO: remove - `errors_public` from nyc.config.js exclude
  //       once this method is fully removed from this file
  buildTokenNameError(t) {
    return "deprecated";
  },
  buildEmptyAlternationError(t) {
    return `Ambiguous empty alternative: <${t.emptyChoiceIdx + 1}> in <OR${t.alternation.idx}> inside <${t.topLevelRule.name}> Rule.
Only the last alternative may be an empty alternative.`;
  },
  buildTooManyAlternativesError(t) {
    return `An Alternation cannot have more than 256 alternatives:
<OR${t.alternation.idx}> inside <${t.topLevelRule.name}> Rule.
 has ${t.alternation.definition.length + 1} alternatives.`;
  },
  buildLeftRecursionError(t) {
    const e = t.topLevelRule.name, r = t.leftRecursionPath.map((a) => a.name), n = `${e} --> ${r.concat([e]).join(" --> ")}`;
    return `Left Recursion found in grammar.
rule: <${e}> can be invoked from itself (directly or indirectly)
without consuming any Tokens. The grammar path that causes this is: 
 ${n}
 To fix this refactor your grammar to remove the left recursion.
see: https://en.wikipedia.org/wiki/LL_parser#Left_factoring.`;
  },
  // TODO: remove - `errors_public` from nyc.config.js exclude
  //       once this method is fully removed from this file
  buildInvalidRuleNameError(t) {
    return "deprecated";
  },
  buildDuplicateRuleNameError(t) {
    let e;
    return t.topLevelRule instanceof dn ? e = t.topLevelRule.name : e = t.topLevelRule, `Duplicate definition, rule: ->${e}<- is already defined in the grammar: ->${t.grammarName}<-`;
  }
};
function qp(t, e) {
  const r = new Bp(t, e);
  return r.resolveRefs(), r.errors;
}
class Bp extends hn {
  constructor(e, r) {
    super(), this.nameToTopRule = e, this.errMsgProvider = r, this.errors = [];
  }
  resolveRefs() {
    Object.values(this.nameToTopRule).forEach((e) => {
      this.currTopLevel = e, e.accept(this);
    });
  }
  visitNonTerminal(e) {
    const r = this.nameToTopRule[e.nonTerminalName];
    if (r)
      e.referencedRule = r;
    else {
      const n = this.errMsgProvider.buildRuleNotFoundError(this.currTopLevel, e);
      this.errors.push({
        message: n,
        type: Be.UNRESOLVED_SUBRULE_REF,
        ruleName: this.currTopLevel.name,
        unresolvedRefName: e.nonTerminalName
      });
    }
  }
}
class Wp extends rs {
  constructor(e, r) {
    super(), this.topProd = e, this.path = r, this.possibleTokTypes = [], this.nextProductionName = "", this.nextProductionOccurrence = 0, this.found = !1, this.isAtEndOfPath = !1;
  }
  startWalking() {
    if (this.found = !1, this.path.ruleStack[0] !== this.topProd.name)
      throw Error("The path does not start with the walker's top Rule!");
    return this.ruleStack = [...this.path.ruleStack].reverse(), this.occurrenceStack = [...this.path.occurrenceStack].reverse(), this.ruleStack.pop(), this.occurrenceStack.pop(), this.updateExpectedNext(), this.walk(this.topProd), this.possibleTokTypes;
  }
  walk(e, r = []) {
    this.found || super.walk(e, r);
  }
  walkProdRef(e, r, n) {
    if (e.referencedRule.name === this.nextProductionName && e.idx === this.nextProductionOccurrence) {
      const i = r.concat(n);
      this.updateExpectedNext(), this.walk(e.referencedRule, i);
    }
  }
  updateExpectedNext() {
    this.ruleStack.length === 0 ? (this.nextProductionName = "", this.nextProductionOccurrence = 0, this.isAtEndOfPath = !0) : (this.nextProductionName = this.ruleStack.pop(), this.nextProductionOccurrence = this.occurrenceStack.pop());
  }
}
class Kp extends Wp {
  constructor(e, r) {
    super(e, r), this.path = r, this.nextTerminalName = "", this.nextTerminalOccurrence = 0, this.nextTerminalName = this.path.lastTok.name, this.nextTerminalOccurrence = this.path.lastTokOccurrence;
  }
  walkTerminal(e, r, n) {
    if (this.isAtEndOfPath && e.terminalType.name === this.nextTerminalName && e.idx === this.nextTerminalOccurrence && !this.found) {
      const i = r.concat(n), a = new Ke({ definition: i });
      this.possibleTokTypes = Ci(a), this.found = !0;
    }
  }
}
class is extends rs {
  constructor(e, r) {
    super(), this.topRule = e, this.occurrence = r, this.result = {
      token: void 0,
      occurrence: void 0,
      isEndOfRule: void 0
    };
  }
  startWalking() {
    return this.walk(this.topRule), this.result;
  }
}
class Vp extends is {
  walkMany(e, r, n) {
    if (e.idx === this.occurrence) {
      const i = r.concat(n)[0];
      this.result.isEndOfRule = i === void 0, i instanceof ae && (this.result.token = i.terminalType, this.result.occurrence = i.idx);
    } else
      super.walkMany(e, r, n);
  }
}
class Cc extends is {
  walkManySep(e, r, n) {
    if (e.idx === this.occurrence) {
      const i = r.concat(n)[0];
      this.result.isEndOfRule = i === void 0, i instanceof ae && (this.result.token = i.terminalType, this.result.occurrence = i.idx);
    } else
      super.walkManySep(e, r, n);
  }
}
class Hp extends is {
  walkAtLeastOne(e, r, n) {
    if (e.idx === this.occurrence) {
      const i = r.concat(n)[0];
      this.result.isEndOfRule = i === void 0, i instanceof ae && (this.result.token = i.terminalType, this.result.occurrence = i.idx);
    } else
      super.walkAtLeastOne(e, r, n);
  }
}
class Sc extends is {
  walkAtLeastOneSep(e, r, n) {
    if (e.idx === this.occurrence) {
      const i = r.concat(n)[0];
      this.result.isEndOfRule = i === void 0, i instanceof ae && (this.result.token = i.terminalType, this.result.occurrence = i.idx);
    } else
      super.walkAtLeastOneSep(e, r, n);
  }
}
function no(t, e, r = []) {
  r = [...r];
  let n = [], i = 0;
  function a(o) {
    return o.concat(t.slice(i + 1));
  }
  function s(o) {
    const l = no(a(o), e, r);
    return n.concat(l);
  }
  for (; r.length < e && i < t.length; ) {
    const o = t[i];
    if (o instanceof Ke)
      return s(o.definition);
    if (o instanceof qe)
      return s(o.definition);
    if (o instanceof Me)
      n = s(o.definition);
    else if (o instanceof et) {
      const l = o.definition.concat([
        new Te({
          definition: o.definition
        })
      ]);
      return s(l);
    } else if (o instanceof tt) {
      const l = [
        new Ke({ definition: o.definition }),
        new Te({
          definition: [new ae({ terminalType: o.separator })].concat(o.definition)
        })
      ];
      return s(l);
    } else if (o instanceof Ve) {
      const l = o.definition.concat([
        new Te({
          definition: [new ae({ terminalType: o.separator })].concat(o.definition)
        })
      ]);
      n = s(l);
    } else if (o instanceof Te) {
      const l = o.definition.concat([
        new Te({
          definition: o.definition
        })
      ]);
      n = s(l);
    } else {
      if (o instanceof He)
        return o.definition.forEach((l) => {
          l.definition.length !== 0 && (n = s(l.definition));
        }), n;
      if (o instanceof ae)
        r.push(o.terminalType);
      else
        throw Error("non exhaustive match");
    }
    i++;
  }
  return n.push({
    partialPath: r,
    suffixDef: t.slice(i)
  }), n;
}
function Xp(t, e, r, n) {
  const i = "EXIT_NONE_TERMINAL", a = [i], s = "EXIT_ALTERNATIVE";
  let o = !1;
  const l = e.length, c = l - n - 1, u = [], d = [];
  for (d.push({
    idx: -1,
    def: t,
    ruleStack: [],
    occurrenceStack: []
  }); d.length !== 0; ) {
    const p = d.pop();
    if (p === s) {
      o && d.at(-1).idx <= c && d.pop();
      continue;
    }
    const m = p.def, A = p.idx, b = p.ruleStack, I = p.occurrenceStack;
    if (m.length === 0)
      continue;
    const k = m[0];
    if (k === i) {
      const S = {
        idx: A,
        def: m.slice(1),
        ruleStack: b.slice(0, -1),
        occurrenceStack: I.slice(0, -1)
      };
      d.push(S);
    } else if (k instanceof ae)
      if (A < l - 1) {
        const S = A + 1, C = e[S];
        if (r(C, k.terminalType)) {
          const P = {
            idx: S,
            def: m.slice(1),
            ruleStack: b,
            occurrenceStack: I
          };
          d.push(P);
        }
      } else if (A === l - 1)
        u.push({
          nextTokenType: k.terminalType,
          nextTokenOccurrence: k.idx,
          ruleStack: b,
          occurrenceStack: I
        }), o = !0;
      else
        throw Error("non exhaustive match");
    else if (k instanceof qe) {
      const S = [...b];
      S.push(k.nonTerminalName);
      const C = [...I];
      C.push(k.idx);
      const P = {
        idx: A,
        def: k.definition.concat(a, m.slice(1)),
        ruleStack: S,
        occurrenceStack: C
      };
      d.push(P);
    } else if (k instanceof Me) {
      const S = {
        idx: A,
        def: m.slice(1),
        ruleStack: b,
        occurrenceStack: I
      };
      d.push(S), d.push(s);
      const C = {
        idx: A,
        def: k.definition.concat(m.slice(1)),
        ruleStack: b,
        occurrenceStack: I
      };
      d.push(C);
    } else if (k instanceof et) {
      const S = new Te({
        definition: k.definition,
        idx: k.idx
      }), C = k.definition.concat([S], m.slice(1)), P = {
        idx: A,
        def: C,
        ruleStack: b,
        occurrenceStack: I
      };
      d.push(P);
    } else if (k instanceof tt) {
      const S = new ae({
        terminalType: k.separator
      }), C = new Te({
        definition: [S].concat(k.definition),
        idx: k.idx
      }), P = k.definition.concat([C], m.slice(1)), W = {
        idx: A,
        def: P,
        ruleStack: b,
        occurrenceStack: I
      };
      d.push(W);
    } else if (k instanceof Ve) {
      const S = {
        idx: A,
        def: m.slice(1),
        ruleStack: b,
        occurrenceStack: I
      };
      d.push(S), d.push(s);
      const C = new ae({
        terminalType: k.separator
      }), P = new Te({
        definition: [C].concat(k.definition),
        idx: k.idx
      }), W = k.definition.concat([P], m.slice(1)), B = {
        idx: A,
        def: W,
        ruleStack: b,
        occurrenceStack: I
      };
      d.push(B);
    } else if (k instanceof Te) {
      const S = {
        idx: A,
        def: m.slice(1),
        ruleStack: b,
        occurrenceStack: I
      };
      d.push(S), d.push(s);
      const C = new Te({
        definition: k.definition,
        idx: k.idx
      }), P = k.definition.concat([C], m.slice(1)), W = {
        idx: A,
        def: P,
        ruleStack: b,
        occurrenceStack: I
      };
      d.push(W);
    } else if (k instanceof He)
      for (let S = k.definition.length - 1; S >= 0; S--) {
        const C = k.definition[S], P = {
          idx: A,
          def: C.definition.concat(m.slice(1)),
          ruleStack: b,
          occurrenceStack: I
        };
        d.push(P), d.push(s);
      }
    else if (k instanceof Ke)
      d.push({
        idx: A,
        def: k.definition.concat(m.slice(1)),
        ruleStack: b,
        occurrenceStack: I
      });
    else if (k instanceof dn)
      d.push(Yp(k, A, b, I));
    else
      throw Error("non exhaustive match");
  }
  return u;
}
function Yp(t, e, r, n) {
  const i = [...r];
  i.push(t.name);
  const a = [...n];
  return a.push(1), {
    idx: e,
    def: t.definition,
    ruleStack: i,
    occurrenceStack: a
  };
}
var de;
(function(t) {
  t[t.OPTION = 0] = "OPTION", t[t.REPETITION = 1] = "REPETITION", t[t.REPETITION_MANDATORY = 2] = "REPETITION_MANDATORY", t[t.REPETITION_MANDATORY_WITH_SEPARATOR = 3] = "REPETITION_MANDATORY_WITH_SEPARATOR", t[t.REPETITION_WITH_SEPARATOR = 4] = "REPETITION_WITH_SEPARATOR", t[t.ALTERNATION = 5] = "ALTERNATION";
})(de || (de = {}));
function Ml(t) {
  if (t instanceof Me || t === "Option")
    return de.OPTION;
  if (t instanceof Te || t === "Repetition")
    return de.REPETITION;
  if (t instanceof et || t === "RepetitionMandatory")
    return de.REPETITION_MANDATORY;
  if (t instanceof tt || t === "RepetitionMandatoryWithSeparator")
    return de.REPETITION_MANDATORY_WITH_SEPARATOR;
  if (t instanceof Ve || t === "RepetitionWithSeparator")
    return de.REPETITION_WITH_SEPARATOR;
  if (t instanceof He || t === "Alternation")
    return de.ALTERNATION;
  throw Error("non exhaustive match");
}
function kc(t) {
  const { occurrence: e, rule: r, prodType: n, maxLookahead: i } = t, a = Ml(n);
  return a === de.ALTERNATION ? as(e, r, i) : ss(e, r, a, i);
}
function Jp(t, e, r, n, i, a) {
  const s = as(t, e, r), o = Df(s) ? Ma : Si;
  return a(s, n, o, i);
}
function Zp(t, e, r, n, i, a) {
  const s = ss(t, e, i, r), o = Df(s) ? Ma : Si;
  return a(s[0], o, n);
}
function Qp(t, e, r, n) {
  const i = t.length, a = t.every((s) => s.every((o) => o.length === 1));
  if (e)
    return function(s) {
      const o = s.map((l) => l.GATE);
      for (let l = 0; l < i; l++) {
        const c = t[l], u = c.length, d = o[l];
        if (!(d !== void 0 && d.call(this) === !1))
          e: for (let p = 0; p < u; p++) {
            const m = c[p], A = m.length;
            for (let b = 0; b < A; b++) {
              const I = this.LA_FAST(b + 1);
              if (r(I, m[b]) === !1)
                continue e;
            }
            return l;
          }
      }
    };
  if (a && !n) {
    const o = t.map((l) => l.flat()).reduce((l, c, u) => (c.forEach((d) => {
      d.tokenTypeIdx in l || (l[d.tokenTypeIdx] = u), d.categoryMatches.forEach((p) => {
        Object.hasOwn(l, p) || (l[p] = u);
      });
    }), l), {});
    return function() {
      const l = this.LA_FAST(1);
      return o[l.tokenTypeIdx];
    };
  } else
    return function() {
      for (let s = 0; s < i; s++) {
        const o = t[s], l = o.length;
        e: for (let c = 0; c < l; c++) {
          const u = o[c], d = u.length;
          for (let p = 0; p < d; p++) {
            const m = this.LA_FAST(p + 1);
            if (r(m, u[p]) === !1)
              continue e;
          }
          return s;
        }
      }
    };
}
function em(t, e, r) {
  const n = t.every((a) => a.length === 1), i = t.length;
  if (n && !r) {
    const a = t.flat();
    if (a.length === 1 && a[0].categoryMatches.length === 0) {
      const o = a[0].tokenTypeIdx;
      return function() {
        return this.LA_FAST(1).tokenTypeIdx === o;
      };
    } else {
      const s = a.reduce((o, l, c) => (o[l.tokenTypeIdx] = !0, l.categoryMatches.forEach((u) => {
        o[u] = !0;
      }), o), []);
      return function() {
        const o = this.LA_FAST(1);
        return s[o.tokenTypeIdx] === !0;
      };
    }
  } else
    return function() {
      e: for (let a = 0; a < i; a++) {
        const s = t[a], o = s.length;
        for (let l = 0; l < o; l++) {
          const c = this.LA_FAST(l + 1);
          if (e(c, s[l]) === !1)
            continue e;
        }
        return !0;
      }
      return !1;
    };
}
class tm extends rs {
  constructor(e, r, n) {
    super(), this.topProd = e, this.targetOccurrence = r, this.targetProdType = n;
  }
  startWalking() {
    return this.walk(this.topProd), this.restDef;
  }
  checkIsTarget(e, r, n, i) {
    return e.idx === this.targetOccurrence && this.targetProdType === r ? (this.restDef = n.concat(i), !0) : !1;
  }
  walkOption(e, r, n) {
    this.checkIsTarget(e, de.OPTION, r, n) || super.walkOption(e, r, n);
  }
  walkAtLeastOne(e, r, n) {
    this.checkIsTarget(e, de.REPETITION_MANDATORY, r, n) || super.walkOption(e, r, n);
  }
  walkAtLeastOneSep(e, r, n) {
    this.checkIsTarget(e, de.REPETITION_MANDATORY_WITH_SEPARATOR, r, n) || super.walkOption(e, r, n);
  }
  walkMany(e, r, n) {
    this.checkIsTarget(e, de.REPETITION, r, n) || super.walkOption(e, r, n);
  }
  walkManySep(e, r, n) {
    this.checkIsTarget(e, de.REPETITION_WITH_SEPARATOR, r, n) || super.walkOption(e, r, n);
  }
}
class Lf extends hn {
  constructor(e, r, n) {
    super(), this.targetOccurrence = e, this.targetProdType = r, this.targetRef = n, this.result = [];
  }
  checkIsTarget(e, r) {
    e.idx === this.targetOccurrence && this.targetProdType === r && (this.targetRef === void 0 || e === this.targetRef) && (this.result = e.definition);
  }
  visitOption(e) {
    this.checkIsTarget(e, de.OPTION);
  }
  visitRepetition(e) {
    this.checkIsTarget(e, de.REPETITION);
  }
  visitRepetitionMandatory(e) {
    this.checkIsTarget(e, de.REPETITION_MANDATORY);
  }
  visitRepetitionMandatoryWithSeparator(e) {
    this.checkIsTarget(e, de.REPETITION_MANDATORY_WITH_SEPARATOR);
  }
  visitRepetitionWithSeparator(e) {
    this.checkIsTarget(e, de.REPETITION_WITH_SEPARATOR);
  }
  visitAlternation(e) {
    this.checkIsTarget(e, de.ALTERNATION);
  }
}
function wc(t) {
  const e = new Array(t);
  for (let r = 0; r < t; r++)
    e[r] = [];
  return e;
}
function vs(t) {
  let e = [""];
  for (let r = 0; r < t.length; r++) {
    const n = t[r], i = [];
    for (let a = 0; a < e.length; a++) {
      const s = e[a];
      i.push(s + "_" + n.tokenTypeIdx);
      for (let o = 0; o < n.categoryMatches.length; o++) {
        const l = "_" + n.categoryMatches[o];
        i.push(s + l);
      }
    }
    e = i;
  }
  return e;
}
function rm(t, e, r) {
  for (let n = 0; n < t.length; n++) {
    if (n === r)
      continue;
    const i = t[n];
    for (let a = 0; a < e.length; a++) {
      const s = e[a];
      if (i[s] === !0)
        return !1;
    }
  }
  return !0;
}
function xf(t, e) {
  const r = t.map((s) => no([s], 1)), n = wc(r.length), i = r.map((s) => {
    const o = {};
    return s.forEach((l) => {
      vs(l.partialPath).forEach((u) => {
        o[u] = !0;
      });
    }), o;
  });
  let a = r;
  for (let s = 1; s <= e; s++) {
    const o = a;
    a = wc(o.length);
    for (let l = 0; l < o.length; l++) {
      const c = o[l];
      for (let u = 0; u < c.length; u++) {
        const d = c[u].partialPath, p = c[u].suffixDef, m = vs(d);
        if (rm(i, m, l) || p.length === 0 || d.length === e) {
          const b = n[l];
          if (io(b, d) === !1) {
            b.push(d);
            for (let I = 0; I < m.length; I++) {
              const k = m[I];
              i[l][k] = !0;
            }
          }
        } else {
          const b = no(p, s + 1, d);
          a[l] = a[l].concat(b), b.forEach((I) => {
            vs(I.partialPath).forEach((S) => {
              i[l][S] = !0;
            });
          });
        }
      }
    }
  }
  return n;
}
function as(t, e, r, n) {
  const i = new Lf(t, de.ALTERNATION, n);
  return e.accept(i), xf(i.result, r);
}
function ss(t, e, r, n) {
  const i = new Lf(t, r);
  e.accept(i);
  const a = i.result, o = new tm(e, t, r).startWalking(), l = new Ke({ definition: a }), c = new Ke({ definition: o });
  return xf([l, c], n);
}
function io(t, e) {
  e: for (let r = 0; r < t.length; r++) {
    const n = t[r];
    if (n.length === e.length) {
      for (let i = 0; i < n.length; i++) {
        const a = e[i], s = n[i];
        if ((a === s || s.categoryMatchesMap[a.tokenTypeIdx] !== void 0) === !1)
          continue e;
      }
      return !0;
    }
  }
  return !1;
}
function nm(t, e) {
  return t.length < e.length && t.every((r, n) => {
    const i = e[n];
    return r === i || i.categoryMatchesMap[r.tokenTypeIdx];
  });
}
function Df(t) {
  return t.every((e) => e.every((r) => r.every((n) => n.categoryMatches.length === 0)));
}
function im(t) {
  return t.lookaheadStrategy.validate({
    rules: t.rules,
    tokenTypes: t.tokenTypes,
    grammarName: t.grammarName
  }).map((r) => Object.assign({ type: Be.CUSTOM_LOOKAHEAD_VALIDATION }, r));
}
function am(t, e, r, n) {
  const i = t.flatMap((l) => sm(l, r)), a = Tm(t, e, r), s = t.flatMap((l) => pm(l, r)), o = t.flatMap((l) => cm(l, t, n, r));
  return i.concat(a, s, o);
}
function sm(t, e) {
  const r = new lm();
  t.accept(r);
  const n = r.allProductions, i = Object.groupBy(n, om), a = Object.fromEntries(Object.entries(i).filter(([o, l]) => l.length > 1));
  return Object.values(a).map((o) => {
    const l = o[0], c = e.buildDuplicateFoundError(t, o), u = mt(l), d = {
      message: c,
      type: Be.DUPLICATE_PRODUCTIONS,
      ruleName: t.name,
      dslName: u,
      occurrence: l.idx
    }, p = Mf(l);
    return p && (d.parameter = p), d;
  });
}
function om(t) {
  return `${mt(t)}_#_${t.idx}_#_${Mf(t)}`;
}
function Mf(t) {
  return t instanceof ae ? t.terminalType.name : t instanceof qe ? t.nonTerminalName : "";
}
class lm extends hn {
  constructor() {
    super(...arguments), this.allProductions = [];
  }
  visitNonTerminal(e) {
    this.allProductions.push(e);
  }
  visitOption(e) {
    this.allProductions.push(e);
  }
  visitRepetitionWithSeparator(e) {
    this.allProductions.push(e);
  }
  visitRepetitionMandatory(e) {
    this.allProductions.push(e);
  }
  visitRepetitionMandatoryWithSeparator(e) {
    this.allProductions.push(e);
  }
  visitRepetition(e) {
    this.allProductions.push(e);
  }
  visitAlternation(e) {
    this.allProductions.push(e);
  }
  visitTerminal(e) {
    this.allProductions.push(e);
  }
}
function cm(t, e, r, n) {
  const i = [];
  if (e.reduce((s, o) => o.name === t.name ? s + 1 : s, 0) > 1) {
    const s = n.buildDuplicateRuleNameError({
      topLevelRule: t,
      grammarName: r
    });
    i.push({
      message: s,
      type: Be.DUPLICATE_RULE_NAME,
      ruleName: t.name
    });
  }
  return i;
}
function um(t, e, r) {
  const n = [];
  let i;
  return e.includes(t) || (i = `Invalid rule override, rule: ->${t}<- cannot be overridden in the grammar: ->${r}<-as it is not defined in any of the super grammars `, n.push({
    message: i,
    type: Be.INVALID_RULE_OVERRIDE,
    ruleName: t
  })), n;
}
function Ff(t, e, r, n = []) {
  const i = [], a = Ca(e.definition);
  if (a.length === 0)
    return [];
  {
    const s = t.name;
    a.includes(t) && i.push({
      message: r.buildLeftRecursionError({
        topLevelRule: t,
        leftRecursionPath: n
      }),
      type: Be.LEFT_RECURSION,
      ruleName: s
    });
    const l = n.concat([t]), u = a.filter((d) => !l.includes(d)).flatMap((d) => {
      const p = [...n];
      return p.push(d), Ff(t, d, r, p);
    });
    return i.concat(u);
  }
}
function Ca(t) {
  let e = [];
  if (t.length === 0)
    return e;
  const r = t[0];
  if (r instanceof qe)
    e.push(r.referencedRule);
  else if (r instanceof Ke || r instanceof Me || r instanceof et || r instanceof tt || r instanceof Ve || r instanceof Te)
    e = e.concat(Ca(r.definition));
  else if (r instanceof He)
    e = r.definition.map((a) => Ca(a.definition)).flat();
  else if (!(r instanceof ae)) throw Error("non exhaustive match");
  const n = xa(r), i = t.length > 1;
  if (n && i) {
    const a = t.slice(1);
    return e.concat(Ca(a));
  } else
    return e;
}
class Fl extends hn {
  constructor() {
    super(...arguments), this.alternations = [];
  }
  visitAlternation(e) {
    this.alternations.push(e);
  }
}
function fm(t, e) {
  const r = new Fl();
  return t.accept(r), r.alternations.flatMap((a) => a.definition.slice(0, -1).flatMap((o, l) => Xp([o], [], Si, 1).length === 0 ? [
    {
      message: e.buildEmptyAlternationError({
        topLevelRule: t,
        alternation: a,
        emptyChoiceIdx: l
      }),
      type: Be.NONE_LAST_EMPTY_ALT,
      ruleName: t.name,
      occurrence: a.idx,
      alternative: l + 1
    }
  ] : []));
}
function dm(t, e, r) {
  const n = new Fl();
  t.accept(n);
  let i = n.alternations;
  return i = i.filter((s) => s.ignoreAmbiguities !== !0), i.flatMap((s) => {
    const o = s.idx, l = s.maxLookahead || e, c = as(o, t, l, s), u = gm(c, s, t, r), d = ym(c, s, t, r);
    return u.concat(d);
  });
}
class hm extends hn {
  constructor() {
    super(...arguments), this.allProductions = [];
  }
  visitRepetitionWithSeparator(e) {
    this.allProductions.push(e);
  }
  visitRepetitionMandatory(e) {
    this.allProductions.push(e);
  }
  visitRepetitionMandatoryWithSeparator(e) {
    this.allProductions.push(e);
  }
  visitRepetition(e) {
    this.allProductions.push(e);
  }
}
function pm(t, e) {
  const r = new Fl();
  return t.accept(r), r.alternations.flatMap((a) => a.definition.length > 255 ? [
    {
      message: e.buildTooManyAlternativesError({
        topLevelRule: t,
        alternation: a
      }),
      type: Be.TOO_MANY_ALTS,
      ruleName: t.name,
      occurrence: a.idx
    }
  ] : []);
}
function mm(t, e, r) {
  const n = [];
  return t.forEach((i) => {
    const a = new hm();
    i.accept(a), a.allProductions.forEach((o) => {
      const l = Ml(o), c = o.maxLookahead || e, u = o.idx;
      if (ss(u, i, l, c)[0].flat().length === 0) {
        const m = r.buildEmptyRepetitionError({
          topLevelRule: i,
          repetition: o
        });
        n.push({
          message: m,
          type: Be.NO_NON_EMPTY_LOOKAHEAD,
          ruleName: i.name
        });
      }
    });
  }), n;
}
function gm(t, e, r, n) {
  const i = [];
  return t.reduce((o, l, c) => (e.definition[c].ignoreAmbiguities === !0 || l.forEach((u) => {
    const d = [c];
    t.forEach((p, m) => {
      c !== m && io(p, u) && // ignore (skip) ambiguities with this "other" alternative
      e.definition[m].ignoreAmbiguities !== !0 && d.push(m);
    }), d.length > 1 && !io(i, u) && (i.push(u), o.push({
      alts: d,
      path: u
    }));
  }), o), []).map((o) => {
    const l = o.alts.map((u) => u + 1);
    return {
      message: n.buildAlternationAmbiguityError({
        topLevelRule: r,
        alternation: e,
        ambiguityIndices: l,
        prefixPath: o.path
      }),
      type: Be.AMBIGUOUS_ALTS,
      ruleName: r.name,
      occurrence: e.idx,
      alternatives: o.alts
    };
  });
}
function ym(t, e, r, n) {
  const i = t.reduce((s, o, l) => {
    const c = o.map((u) => ({ idx: l, path: u }));
    return s.concat(c);
  }, []);
  return i.flatMap((s) => {
    if (e.definition[s.idx].ignoreAmbiguities === !0)
      return [];
    const l = s.idx, c = s.path;
    return i.filter((p) => (
      // ignore (skip) ambiguities with this "other" alternative
      e.definition[p.idx].ignoreAmbiguities !== !0 && p.idx < l && // checking for strict prefix because identical lookaheads
      // will be be detected using a different validation.
      nm(p.path, c)
    )).map((p) => {
      const m = [p.idx + 1, l + 1], A = e.idx === 0 ? "" : e.idx;
      return {
        message: n.buildAlternationPrefixAmbiguityError({
          topLevelRule: r,
          alternation: e,
          ambiguityIndices: m,
          prefixPath: p.path
        }),
        type: Be.AMBIGUOUS_PREFIX_ALTS,
        ruleName: r.name,
        occurrence: A,
        alternatives: m
      };
    });
  });
}
function Tm(t, e, r) {
  const n = [], i = e.map((a) => a.name);
  return t.forEach((a) => {
    const s = a.name;
    if (i.includes(s)) {
      const o = r.buildNamespaceConflictError(a);
      n.push({
        message: o,
        type: Be.CONFLICT_TOKENS_RULES_NAMESPACE,
        ruleName: s
      });
    }
  }), n;
}
function Rm(t) {
  const e = Object.assign({ errMsgProvider: Up }, t), r = {};
  return t.rules.forEach((n) => {
    r[n.name] = n;
  }), qp(r, e.errMsgProvider);
}
function vm(t) {
  var e;
  const r = (e = t.errMsgProvider) !== null && e !== void 0 ? e : Cr;
  return am(t.rules, t.tokenTypes, r, t.grammarName);
}
const Gf = "MismatchedTokenException", jf = "NoViableAltException", zf = "EarlyExitException", Uf = "NotAllInputParsedException", qf = [
  Gf,
  jf,
  zf,
  Uf
];
Object.freeze(qf);
function Fa(t) {
  return qf.includes(t.name);
}
class os extends Error {
  constructor(e, r) {
    super(e), this.token = r, this.resyncedTokens = [], Object.setPrototypeOf(this, new.target.prototype), Error.captureStackTrace && Error.captureStackTrace(this, this.constructor);
  }
}
class Bf extends os {
  constructor(e, r, n) {
    super(e, r), this.previousToken = n, this.name = Gf;
  }
}
class Em extends os {
  constructor(e, r, n) {
    super(e, r), this.previousToken = n, this.name = jf;
  }
}
class Am extends os {
  constructor(e, r) {
    super(e, r), this.name = Uf;
  }
}
class $m extends os {
  constructor(e, r, n) {
    super(e, r), this.previousToken = n, this.name = zf;
  }
}
const Es = {}, Wf = "InRuleRecoveryException";
class Cm extends Error {
  constructor(e) {
    super(e), this.name = Wf;
  }
}
class Sm {
  initRecoverable(e) {
    this.firstAfterRepMap = {}, this.resyncFollows = {}, this.recoveryEnabled = Object.hasOwn(e, "recoveryEnabled") ? e.recoveryEnabled : Ut.recoveryEnabled, this.recoveryEnabled && (this.attemptInRepetitionRecovery = km);
  }
  getTokenToInsert(e) {
    const r = Dl(e, "", NaN, NaN, NaN, NaN, NaN, NaN);
    return r.isInsertedInRecovery = !0, r;
  }
  canTokenTypeBeInsertedInRecovery(e) {
    return !0;
  }
  canTokenTypeBeDeletedInRecovery(e) {
    return !0;
  }
  tryInRepetitionRecovery(e, r, n, i) {
    const a = this.findReSyncTokenType(), s = this.exportLexerState(), o = [];
    let l = !1;
    const c = this.LA_FAST(1);
    let u = this.LA_FAST(1);
    const d = () => {
      const p = this.LA(0), m = this.errorMessageProvider.buildMismatchTokenMessage({
        expected: i,
        actual: c,
        previous: p,
        ruleName: this.getCurrRuleFullName()
      }), A = new Bf(m, c, this.LA(0));
      A.resyncedTokens = o.slice(0, -1), this.SAVE_ERROR(A);
    };
    for (; !l; )
      if (this.tokenMatcher(u, i)) {
        d();
        return;
      } else if (n.call(this)) {
        d(), e.apply(this, r);
        return;
      } else this.tokenMatcher(u, a) ? l = !0 : (u = this.SKIP_TOKEN(), this.addToResyncTokens(u, o));
    this.importLexerState(s);
  }
  shouldInRepetitionRecoveryBeTried(e, r, n) {
    return !(n === !1 || this.tokenMatcher(this.LA_FAST(1), e) || this.isBackTracking() || this.canPerformInRuleRecovery(e, this.getFollowsForInRuleRecovery(e, r)));
  }
  // TODO: should this be a member method or a utility? it does not have any state or usage of 'this'...
  // TODO: should this be more explicitly part of the public API?
  getNextPossibleTokenTypes(e) {
    const r = e.ruleStack[0], i = this.getGAstProductions()[r];
    return new Kp(i, e).startWalking();
  }
  // Error Recovery functionality
  getFollowsForInRuleRecovery(e, r) {
    const n = this.getCurrentGrammarPath(e, r);
    return this.getNextPossibleTokenTypes(n);
  }
  tryInRuleRecovery(e, r) {
    if (this.canRecoverWithSingleTokenInsertion(e, r))
      return this.getTokenToInsert(e);
    if (this.canRecoverWithSingleTokenDeletion(e)) {
      const n = this.SKIP_TOKEN();
      return this.consumeToken(), n;
    }
    throw new Cm("sad sad panda");
  }
  canPerformInRuleRecovery(e, r) {
    return this.canRecoverWithSingleTokenInsertion(e, r) || this.canRecoverWithSingleTokenDeletion(e);
  }
  canRecoverWithSingleTokenInsertion(e, r) {
    if (!this.canTokenTypeBeInsertedInRecovery(e) || r.length === 0)
      return !1;
    const n = this.LA_FAST(1);
    return r.find((a) => this.tokenMatcher(n, a)) !== void 0;
  }
  canRecoverWithSingleTokenDeletion(e) {
    return this.canTokenTypeBeDeletedInRecovery(e) ? this.tokenMatcher(
      // not using LA_FAST because LA(2) might be un-safe with maxLookahead=1
      // in some edge cases (?)
      this.LA(2),
      e
    ) : !1;
  }
  isInCurrentRuleReSyncSet(e) {
    const r = this.getCurrFollowKey();
    return this.getFollowSetFromFollowKey(r).includes(e);
  }
  findReSyncTokenType() {
    const e = this.flattenFollowSet();
    let r = this.LA_FAST(1), n = 2;
    for (; ; ) {
      const i = e.find((a) => Of(r, a));
      if (i !== void 0)
        return i;
      r = this.LA(n), n++;
    }
  }
  getCurrFollowKey() {
    if (this.RULE_STACK_IDX === 0)
      return Es;
    const e = this.currRuleShortName, r = this.getLastExplicitRuleOccurrenceIndex(), n = this.getPreviousExplicitRuleShortName();
    return {
      ruleName: this.shortRuleNameToFullName(e),
      idxInCallingRule: r,
      inRule: this.shortRuleNameToFullName(n)
    };
  }
  buildFullFollowKeyStack() {
    const e = this.RULE_STACK, r = this.RULE_OCCURRENCE_STACK, n = this.RULE_STACK_IDX + 1, i = new Array(n);
    for (let a = 0; a < n; a++)
      a === 0 ? i[a] = Es : i[a] = {
        ruleName: this.shortRuleNameToFullName(e[a]),
        idxInCallingRule: r[a],
        inRule: this.shortRuleNameToFullName(e[a - 1])
      };
    return i;
  }
  flattenFollowSet() {
    return this.buildFullFollowKeyStack().map((r) => this.getFollowSetFromFollowKey(r)).flat();
  }
  getFollowSetFromFollowKey(e) {
    if (e === Es)
      return [Qt];
    const r = e.ruleName + e.idxInCallingRule + $f + e.inRule;
    return this.resyncFollows[r];
  }
  // It does not make any sense to include a virtual EOF token in the list of resynced tokens
  // as EOF does not really exist and thus does not contain any useful information (line/column numbers)
  addToResyncTokens(e, r) {
    return this.tokenMatcher(e, Qt) || r.push(e), r;
  }
  reSyncTo(e) {
    const r = [];
    let n = this.LA_FAST(1);
    for (; this.tokenMatcher(n, e) === !1; )
      n = this.SKIP_TOKEN(), this.addToResyncTokens(n, r);
    return r.slice(0, -1);
  }
  attemptInRepetitionRecovery(e, r, n, i, a, s, o) {
  }
  getCurrentGrammarPath(e, r) {
    const n = this.getHumanReadableRuleStack(), i = this.RULE_OCCURRENCE_STACK.slice(0, this.RULE_OCCURRENCE_STACK_IDX + 1);
    return {
      ruleStack: n,
      occurrenceStack: i,
      lastTok: e,
      lastTokOccurrence: r
    };
  }
  getHumanReadableRuleStack() {
    const e = this.RULE_STACK_IDX + 1, r = new Array(e);
    for (let n = 0; n < e; n++)
      r[n] = this.shortRuleNameToFullName(this.RULE_STACK[n]);
    return r;
  }
}
function km(t, e, r, n, i, a, s) {
  const o = this.getKeyForAutomaticLookahead(n, i);
  let l = this.firstAfterRepMap[o];
  if (l === void 0) {
    const p = this.getCurrRuleFullName(), m = this.getGAstProductions()[p];
    l = new a(m, i).startWalking(), this.firstAfterRepMap[o] = l;
  }
  let c = l.token, u = l.occurrence;
  const d = l.isEndOfRule;
  this.RULE_STACK_IDX === 0 && d && c === void 0 && (c = Qt, u = 1), !(c === void 0 || u === void 0) && this.shouldInRepetitionRecoveryBeTried(c, u, s) && this.tryInRepetitionRecovery(t, e, r, c);
}
const wm = 4, tr = 8, Kf = 1 << tr, Vf = 2 << tr, ao = 3 << tr, so = 4 << tr, oo = 5 << tr, Sa = 6 << tr;
function As(t, e, r) {
  return r | e | t;
}
class Gl {
  constructor(e) {
    var r;
    this.maxLookahead = (r = e?.maxLookahead) !== null && r !== void 0 ? r : Ut.maxLookahead;
  }
  validate(e) {
    const r = this.validateNoLeftRecursion(e.rules);
    if (r.length === 0) {
      const n = this.validateEmptyOrAlternatives(e.rules), i = this.validateAmbiguousAlternationAlternatives(e.rules, this.maxLookahead), a = this.validateSomeNonEmptyLookaheadPath(e.rules, this.maxLookahead);
      return [
        ...r,
        ...n,
        ...i,
        ...a
      ];
    }
    return r;
  }
  validateNoLeftRecursion(e) {
    return e.flatMap((r) => Ff(r, r, Cr));
  }
  validateEmptyOrAlternatives(e) {
    return e.flatMap((r) => fm(r, Cr));
  }
  validateAmbiguousAlternationAlternatives(e, r) {
    return e.flatMap((n) => dm(n, r, Cr));
  }
  validateSomeNonEmptyLookaheadPath(e, r) {
    return mm(e, r, Cr);
  }
  buildLookaheadForAlternation(e) {
    return Jp(e.prodOccurrence, e.rule, e.maxLookahead, e.hasPredicates, e.dynamicTokensEnabled, Qp);
  }
  buildLookaheadForOptional(e) {
    return Zp(e.prodOccurrence, e.rule, e.maxLookahead, e.dynamicTokensEnabled, Ml(e.prodType), em);
  }
}
class bm {
  initLooksAhead(e) {
    this.dynamicTokensEnabled = Object.hasOwn(e, "dynamicTokensEnabled") ? e.dynamicTokensEnabled : Ut.dynamicTokensEnabled, this.maxLookahead = Object.hasOwn(e, "maxLookahead") ? e.maxLookahead : Ut.maxLookahead, this.lookaheadStrategy = Object.hasOwn(e, "lookaheadStrategy") ? e.lookaheadStrategy : new Gl({ maxLookahead: this.maxLookahead }), this.lookAheadFuncsCache = /* @__PURE__ */ new Map();
  }
  preComputeLookaheadFunctions(e) {
    e.forEach((r) => {
      this.TRACE_INIT(`${r.name} Rule Lookahead`, () => {
        const { alternation: n, repetition: i, option: a, repetitionMandatory: s, repetitionMandatoryWithSeparator: o, repetitionWithSeparator: l } = _m(r);
        n.forEach((c) => {
          const u = c.idx === 0 ? "" : c.idx;
          this.TRACE_INIT(`${mt(c)}${u}`, () => {
            const d = this.lookaheadStrategy.buildLookaheadForAlternation({
              prodOccurrence: c.idx,
              rule: r,
              maxLookahead: c.maxLookahead || this.maxLookahead,
              hasPredicates: c.hasPredicates,
              dynamicTokensEnabled: this.dynamicTokensEnabled
            }), p = As(this.fullRuleNameToShort[r.name], Kf, c.idx);
            this.setLaFuncCache(p, d);
          });
        }), i.forEach((c) => {
          this.computeLookaheadFunc(r, c.idx, ao, "Repetition", c.maxLookahead, mt(c));
        }), a.forEach((c) => {
          this.computeLookaheadFunc(r, c.idx, Vf, "Option", c.maxLookahead, mt(c));
        }), s.forEach((c) => {
          this.computeLookaheadFunc(r, c.idx, so, "RepetitionMandatory", c.maxLookahead, mt(c));
        }), o.forEach((c) => {
          this.computeLookaheadFunc(r, c.idx, Sa, "RepetitionMandatoryWithSeparator", c.maxLookahead, mt(c));
        }), l.forEach((c) => {
          this.computeLookaheadFunc(r, c.idx, oo, "RepetitionWithSeparator", c.maxLookahead, mt(c));
        });
      });
    });
  }
  computeLookaheadFunc(e, r, n, i, a, s) {
    this.TRACE_INIT(`${s}${r === 0 ? "" : r}`, () => {
      const o = this.lookaheadStrategy.buildLookaheadForOptional({
        prodOccurrence: r,
        rule: e,
        maxLookahead: a || this.maxLookahead,
        dynamicTokensEnabled: this.dynamicTokensEnabled,
        prodType: i
      }), l = As(this.fullRuleNameToShort[e.name], n, r);
      this.setLaFuncCache(l, o);
    });
  }
  // this actually returns a number, but it is always used as a string (object prop key)
  getKeyForAutomaticLookahead(e, r) {
    return As(this.currRuleShortName, e, r);
  }
  getLaFuncFromCache(e) {
    return this.lookAheadFuncsCache.get(e);
  }
  /* istanbul ignore next */
  setLaFuncCache(e, r) {
    this.lookAheadFuncsCache.set(e, r);
  }
}
class Nm extends hn {
  constructor() {
    super(...arguments), this.dslMethods = {
      option: [],
      alternation: [],
      repetition: [],
      repetitionWithSeparator: [],
      repetitionMandatory: [],
      repetitionMandatoryWithSeparator: []
    };
  }
  reset() {
    this.dslMethods = {
      option: [],
      alternation: [],
      repetition: [],
      repetitionWithSeparator: [],
      repetitionMandatory: [],
      repetitionMandatoryWithSeparator: []
    };
  }
  visitOption(e) {
    this.dslMethods.option.push(e);
  }
  visitRepetitionWithSeparator(e) {
    this.dslMethods.repetitionWithSeparator.push(e);
  }
  visitRepetitionMandatory(e) {
    this.dslMethods.repetitionMandatory.push(e);
  }
  visitRepetitionMandatoryWithSeparator(e) {
    this.dslMethods.repetitionMandatoryWithSeparator.push(e);
  }
  visitRepetition(e) {
    this.dslMethods.repetition.push(e);
  }
  visitAlternation(e) {
    this.dslMethods.alternation.push(e);
  }
}
const Qi = new Nm();
function _m(t) {
  Qi.reset(), t.accept(Qi);
  const e = Qi.dslMethods;
  return Qi.reset(), e;
}
function bc(t, e) {
  isNaN(t.startOffset) === !0 ? (t.startOffset = e.startOffset, t.endOffset = e.endOffset) : t.endOffset < e.endOffset && (t.endOffset = e.endOffset);
}
function Nc(t, e) {
  isNaN(t.startOffset) === !0 ? (t.startOffset = e.startOffset, t.startColumn = e.startColumn, t.startLine = e.startLine, t.endOffset = e.endOffset, t.endColumn = e.endColumn, t.endLine = e.endLine) : t.endOffset < e.endOffset && (t.endOffset = e.endOffset, t.endColumn = e.endColumn, t.endLine = e.endLine);
}
function Im(t, e, r) {
  t.children[r] === void 0 ? t.children[r] = [e] : t.children[r].push(e);
}
function Pm(t, e, r) {
  t.children[e] === void 0 ? t.children[e] = [r] : t.children[e].push(r);
}
const Om = "name";
function Hf(t, e) {
  Object.defineProperty(t, Om, {
    enumerable: !1,
    configurable: !0,
    writable: !1,
    value: e
  });
}
function Lm(t, e) {
  const r = Object.keys(t), n = r.length;
  for (let i = 0; i < n; i++) {
    const a = r[i], s = t[a], o = s.length;
    for (let l = 0; l < o; l++) {
      const c = s[l];
      c.tokenTypeIdx === void 0 && this[c.name](c.children, e);
    }
  }
}
function xm(t, e) {
  const r = function() {
  };
  Hf(r, t + "BaseSemantics");
  const n = {
    visit: function(i, a) {
      if (Array.isArray(i) && (i = i[0]), i !== void 0)
        return this[i.name](i.children, a);
    },
    validateVisitor: function() {
      const i = Mm(this, e);
      if (i.length !== 0) {
        const a = i.map((s) => s.msg);
        throw Error(`Errors Detected in CST Visitor <${this.constructor.name}>:
	${a.join(`

`).replace(/\n/g, `
	`)}`);
      }
    }
  };
  return r.prototype = n, r.prototype.constructor = r, r._RULE_NAMES = e, r;
}
function Dm(t, e, r) {
  const n = function() {
  };
  Hf(n, t + "BaseSemanticsWithDefaults");
  const i = Object.create(r.prototype);
  return e.forEach((a) => {
    i[a] = Lm;
  }), n.prototype = i, n.prototype.constructor = n, n;
}
var lo;
(function(t) {
  t[t.REDUNDANT_METHOD = 0] = "REDUNDANT_METHOD", t[t.MISSING_METHOD = 1] = "MISSING_METHOD";
})(lo || (lo = {}));
function Mm(t, e) {
  return Fm(t, e);
}
function Fm(t, e) {
  return e.filter((i) => typeof t[i] != "function").map((i) => ({
    msg: `Missing visitor method: <${i}> on ${t.constructor.name} CST Visitor.`,
    type: lo.MISSING_METHOD,
    methodName: i
  })).filter(Boolean);
}
class Gm {
  initTreeBuilder(e) {
    if (this.CST_STACK = [], this.outputCst = e.outputCst, this.nodeLocationTracking = Object.hasOwn(e, "nodeLocationTracking") ? e.nodeLocationTracking : Ut.nodeLocationTracking, !this.outputCst)
      this.cstInvocationStateUpdate = () => {
      }, this.cstFinallyStateUpdate = () => {
      }, this.cstPostTerminal = () => {
      }, this.cstPostNonTerminal = () => {
      }, this.cstPostRule = () => {
      };
    else if (/full/i.test(this.nodeLocationTracking))
      this.recoveryEnabled ? (this.setNodeLocationFromToken = Nc, this.setNodeLocationFromNode = Nc, this.cstPostRule = () => {
      }, this.setInitialNodeLocation = this.setInitialNodeLocationFullRecovery) : (this.setNodeLocationFromToken = () => {
      }, this.setNodeLocationFromNode = () => {
      }, this.cstPostRule = this.cstPostRuleFull, this.setInitialNodeLocation = this.setInitialNodeLocationFullRegular);
    else if (/onlyOffset/i.test(this.nodeLocationTracking))
      this.recoveryEnabled ? (this.setNodeLocationFromToken = bc, this.setNodeLocationFromNode = bc, this.cstPostRule = () => {
      }, this.setInitialNodeLocation = this.setInitialNodeLocationOnlyOffsetRecovery) : (this.setNodeLocationFromToken = () => {
      }, this.setNodeLocationFromNode = () => {
      }, this.cstPostRule = this.cstPostRuleOnlyOffset, this.setInitialNodeLocation = this.setInitialNodeLocationOnlyOffsetRegular);
    else if (/none/i.test(this.nodeLocationTracking))
      this.setNodeLocationFromToken = () => {
      }, this.setNodeLocationFromNode = () => {
      }, this.cstPostRule = () => {
      }, this.setInitialNodeLocation = () => {
      };
    else
      throw Error(`Invalid <nodeLocationTracking> config option: "${e.nodeLocationTracking}"`);
  }
  setInitialNodeLocationOnlyOffsetRecovery(e) {
    e.location = {
      startOffset: NaN,
      endOffset: NaN
    };
  }
  setInitialNodeLocationOnlyOffsetRegular(e) {
    e.location = {
      // without error recovery the starting Location of a new CstNode is guaranteed
      // To be the next Token's startOffset (for valid inputs).
      // For invalid inputs there won't be any CSTOutput so this potential
      // inaccuracy does not matter
      startOffset: this.LA_FAST(1).startOffset,
      endOffset: NaN
    };
  }
  setInitialNodeLocationFullRecovery(e) {
    e.location = {
      startOffset: NaN,
      startLine: NaN,
      startColumn: NaN,
      endOffset: NaN,
      endLine: NaN,
      endColumn: NaN
    };
  }
  /**
       *  @see setInitialNodeLocationOnlyOffsetRegular for explanation why this work
  
       * @param cstNode
       */
  setInitialNodeLocationFullRegular(e) {
    const r = this.LA_FAST(1);
    e.location = {
      startOffset: r.startOffset,
      startLine: r.startLine,
      startColumn: r.startColumn,
      endOffset: NaN,
      endLine: NaN,
      endColumn: NaN
    };
  }
  cstInvocationStateUpdate(e) {
    const r = {
      name: e,
      children: /* @__PURE__ */ Object.create(null)
    };
    this.setInitialNodeLocation(r), this.CST_STACK.push(r);
  }
  cstFinallyStateUpdate() {
    this.CST_STACK.pop();
  }
  cstPostRuleFull(e) {
    const r = this.LA(0), n = e.location;
    n.startOffset <= r.startOffset ? (n.endOffset = r.endOffset, n.endLine = r.endLine, n.endColumn = r.endColumn) : (n.startOffset = NaN, n.startLine = NaN, n.startColumn = NaN);
  }
  cstPostRuleOnlyOffset(e) {
    const r = this.LA(0), n = e.location;
    n.startOffset <= r.startOffset ? n.endOffset = r.endOffset : n.startOffset = NaN;
  }
  cstPostTerminal(e, r) {
    const n = this.CST_STACK[this.CST_STACK.length - 1];
    Im(n, r, e), this.setNodeLocationFromToken(n.location, r);
  }
  cstPostNonTerminal(e, r) {
    const n = this.CST_STACK[this.CST_STACK.length - 1];
    Pm(n, r, e), this.setNodeLocationFromNode(n.location, e.location);
  }
  getBaseCstVisitorConstructor() {
    if (this.baseCstVisitorConstructor === void 0) {
      const e = xm(this.className, Object.keys(this.gastProductionsCache));
      return this.baseCstVisitorConstructor = e, e;
    }
    return this.baseCstVisitorConstructor;
  }
  getBaseCstVisitorConstructorWithDefaults() {
    if (this.baseCstVisitorWithDefaultsConstructor === void 0) {
      const e = Dm(this.className, Object.keys(this.gastProductionsCache), this.getBaseCstVisitorConstructor());
      return this.baseCstVisitorWithDefaultsConstructor = e, e;
    }
    return this.baseCstVisitorWithDefaultsConstructor;
  }
  getPreviousExplicitRuleShortName() {
    return this.RULE_STACK[this.RULE_STACK_IDX - 1];
  }
  getLastExplicitRuleOccurrenceIndex() {
    return this.RULE_OCCURRENCE_STACK[this.RULE_OCCURRENCE_STACK_IDX];
  }
}
class jm {
  initLexerAdapter() {
    this.tokVector = [], this.tokVectorLength = 0, this.currIdx = -1;
  }
  set input(e) {
    if (this.selfAnalysisDone !== !0)
      throw Error("Missing <performSelfAnalysis> invocation at the end of the Parser's constructor.");
    this.reset(), this.tokVector = e, this.tokVectorLength = e.length;
  }
  get input() {
    return this.tokVector;
  }
  // skips a token and returns the next token
  SKIP_TOKEN() {
    return this.currIdx <= this.tokVectorLength - 2 ? (this.consumeToken(), this.LA_FAST(1)) : an;
  }
  // Lexer (accessing Token vector) related methods which can be overridden to implement lazy lexers
  // or lexers dependent on parser context.
  // Performance Optimized version of LA without bound checks
  // note that token beyond the end of the token vector EOF Token will still be returned
  // due to using sentinels at the end of the token vector. (for K=max lookahead)
  LA_FAST(e) {
    const r = this.currIdx + e;
    return this.tokVector[r];
  }
  LA(e) {
    const r = this.currIdx + e;
    return r < 0 || this.tokVectorLength <= r ? an : this.tokVector[r];
  }
  consumeToken() {
    this.currIdx++;
  }
  exportLexerState() {
    return this.currIdx;
  }
  importLexerState(e) {
    this.currIdx = e;
  }
  resetLexerState() {
    this.currIdx = -1;
  }
  moveToTerminatedState() {
    this.currIdx = this.tokVectorLength - 1;
  }
  getLexerPosition() {
    return this.exportLexerState();
  }
}
class zm {
  ACTION(e) {
    return e.call(this);
  }
  consume(e, r, n) {
    return this.consumeInternal(r, e, n);
  }
  subrule(e, r, n) {
    return this.subruleInternal(r, e, n);
  }
  option(e, r) {
    return this.optionInternal(r, e);
  }
  or(e, r) {
    return this.orInternal(r, e);
  }
  many(e, r) {
    return this.manyInternal(e, r);
  }
  atLeastOne(e, r) {
    return this.atLeastOneInternal(e, r);
  }
  CONSUME(e, r) {
    return this.consumeInternal(e, 0, r);
  }
  CONSUME1(e, r) {
    return this.consumeInternal(e, 1, r);
  }
  CONSUME2(e, r) {
    return this.consumeInternal(e, 2, r);
  }
  CONSUME3(e, r) {
    return this.consumeInternal(e, 3, r);
  }
  CONSUME4(e, r) {
    return this.consumeInternal(e, 4, r);
  }
  CONSUME5(e, r) {
    return this.consumeInternal(e, 5, r);
  }
  CONSUME6(e, r) {
    return this.consumeInternal(e, 6, r);
  }
  CONSUME7(e, r) {
    return this.consumeInternal(e, 7, r);
  }
  CONSUME8(e, r) {
    return this.consumeInternal(e, 8, r);
  }
  CONSUME9(e, r) {
    return this.consumeInternal(e, 9, r);
  }
  SUBRULE(e, r) {
    return this.subruleInternal(e, 0, r);
  }
  SUBRULE1(e, r) {
    return this.subruleInternal(e, 1, r);
  }
  SUBRULE2(e, r) {
    return this.subruleInternal(e, 2, r);
  }
  SUBRULE3(e, r) {
    return this.subruleInternal(e, 3, r);
  }
  SUBRULE4(e, r) {
    return this.subruleInternal(e, 4, r);
  }
  SUBRULE5(e, r) {
    return this.subruleInternal(e, 5, r);
  }
  SUBRULE6(e, r) {
    return this.subruleInternal(e, 6, r);
  }
  SUBRULE7(e, r) {
    return this.subruleInternal(e, 7, r);
  }
  SUBRULE8(e, r) {
    return this.subruleInternal(e, 8, r);
  }
  SUBRULE9(e, r) {
    return this.subruleInternal(e, 9, r);
  }
  OPTION(e) {
    return this.optionInternal(e, 0);
  }
  OPTION1(e) {
    return this.optionInternal(e, 1);
  }
  OPTION2(e) {
    return this.optionInternal(e, 2);
  }
  OPTION3(e) {
    return this.optionInternal(e, 3);
  }
  OPTION4(e) {
    return this.optionInternal(e, 4);
  }
  OPTION5(e) {
    return this.optionInternal(e, 5);
  }
  OPTION6(e) {
    return this.optionInternal(e, 6);
  }
  OPTION7(e) {
    return this.optionInternal(e, 7);
  }
  OPTION8(e) {
    return this.optionInternal(e, 8);
  }
  OPTION9(e) {
    return this.optionInternal(e, 9);
  }
  OR(e) {
    return this.orInternal(e, 0);
  }
  OR1(e) {
    return this.orInternal(e, 1);
  }
  OR2(e) {
    return this.orInternal(e, 2);
  }
  OR3(e) {
    return this.orInternal(e, 3);
  }
  OR4(e) {
    return this.orInternal(e, 4);
  }
  OR5(e) {
    return this.orInternal(e, 5);
  }
  OR6(e) {
    return this.orInternal(e, 6);
  }
  OR7(e) {
    return this.orInternal(e, 7);
  }
  OR8(e) {
    return this.orInternal(e, 8);
  }
  OR9(e) {
    return this.orInternal(e, 9);
  }
  MANY(e) {
    this.manyInternal(0, e);
  }
  MANY1(e) {
    this.manyInternal(1, e);
  }
  MANY2(e) {
    this.manyInternal(2, e);
  }
  MANY3(e) {
    this.manyInternal(3, e);
  }
  MANY4(e) {
    this.manyInternal(4, e);
  }
  MANY5(e) {
    this.manyInternal(5, e);
  }
  MANY6(e) {
    this.manyInternal(6, e);
  }
  MANY7(e) {
    this.manyInternal(7, e);
  }
  MANY8(e) {
    this.manyInternal(8, e);
  }
  MANY9(e) {
    this.manyInternal(9, e);
  }
  MANY_SEP(e) {
    this.manySepFirstInternal(0, e);
  }
  MANY_SEP1(e) {
    this.manySepFirstInternal(1, e);
  }
  MANY_SEP2(e) {
    this.manySepFirstInternal(2, e);
  }
  MANY_SEP3(e) {
    this.manySepFirstInternal(3, e);
  }
  MANY_SEP4(e) {
    this.manySepFirstInternal(4, e);
  }
  MANY_SEP5(e) {
    this.manySepFirstInternal(5, e);
  }
  MANY_SEP6(e) {
    this.manySepFirstInternal(6, e);
  }
  MANY_SEP7(e) {
    this.manySepFirstInternal(7, e);
  }
  MANY_SEP8(e) {
    this.manySepFirstInternal(8, e);
  }
  MANY_SEP9(e) {
    this.manySepFirstInternal(9, e);
  }
  AT_LEAST_ONE(e) {
    this.atLeastOneInternal(0, e);
  }
  AT_LEAST_ONE1(e) {
    return this.atLeastOneInternal(1, e);
  }
  AT_LEAST_ONE2(e) {
    this.atLeastOneInternal(2, e);
  }
  AT_LEAST_ONE3(e) {
    this.atLeastOneInternal(3, e);
  }
  AT_LEAST_ONE4(e) {
    this.atLeastOneInternal(4, e);
  }
  AT_LEAST_ONE5(e) {
    this.atLeastOneInternal(5, e);
  }
  AT_LEAST_ONE6(e) {
    this.atLeastOneInternal(6, e);
  }
  AT_LEAST_ONE7(e) {
    this.atLeastOneInternal(7, e);
  }
  AT_LEAST_ONE8(e) {
    this.atLeastOneInternal(8, e);
  }
  AT_LEAST_ONE9(e) {
    this.atLeastOneInternal(9, e);
  }
  AT_LEAST_ONE_SEP(e) {
    this.atLeastOneSepFirstInternal(0, e);
  }
  AT_LEAST_ONE_SEP1(e) {
    this.atLeastOneSepFirstInternal(1, e);
  }
  AT_LEAST_ONE_SEP2(e) {
    this.atLeastOneSepFirstInternal(2, e);
  }
  AT_LEAST_ONE_SEP3(e) {
    this.atLeastOneSepFirstInternal(3, e);
  }
  AT_LEAST_ONE_SEP4(e) {
    this.atLeastOneSepFirstInternal(4, e);
  }
  AT_LEAST_ONE_SEP5(e) {
    this.atLeastOneSepFirstInternal(5, e);
  }
  AT_LEAST_ONE_SEP6(e) {
    this.atLeastOneSepFirstInternal(6, e);
  }
  AT_LEAST_ONE_SEP7(e) {
    this.atLeastOneSepFirstInternal(7, e);
  }
  AT_LEAST_ONE_SEP8(e) {
    this.atLeastOneSepFirstInternal(8, e);
  }
  AT_LEAST_ONE_SEP9(e) {
    this.atLeastOneSepFirstInternal(9, e);
  }
  RULE(e, r, n = ja) {
    if (this.definedRulesNames.includes(e)) {
      const s = {
        message: Cr.buildDuplicateRuleNameError({
          topLevelRule: e,
          grammarName: this.className
        }),
        type: Be.DUPLICATE_RULE_NAME,
        ruleName: e
      };
      this.definitionErrors.push(s);
    }
    this.definedRulesNames.push(e);
    const i = this.defineRule(e, r, n);
    return this[e] = i, i;
  }
  OVERRIDE_RULE(e, r, n = ja) {
    const i = um(e, this.definedRulesNames, this.className);
    this.definitionErrors = this.definitionErrors.concat(i);
    const a = this.defineRule(e, r, n);
    return this[e] = a, a;
  }
  BACKTRACK(e, r) {
    var n;
    const i = (n = e.coreRule) !== null && n !== void 0 ? n : e;
    return function() {
      this.isBackTrackingStack.push(1);
      const a = this.saveRecogState();
      try {
        return i.apply(this, r), !0;
      } catch (s) {
        if (Fa(s))
          return !1;
        throw s;
      } finally {
        this.reloadRecogState(a), this.isBackTrackingStack.pop();
      }
    };
  }
  // GAST export APIs
  getGAstProductions() {
    return this.gastProductionsCache;
  }
  getSerializedGastProductions() {
    return Hh(Object.values(this.gastProductionsCache));
  }
}
class Um {
  initRecognizerEngine(e, r) {
    if (this.className = this.constructor.name, this.shortRuleNameToFull = {}, this.fullRuleNameToShort = {}, this.ruleShortNameIdx = 256, this.tokenMatcher = Ma, this.subruleIdx = 0, this.currRuleShortName = 0, this.definedRulesNames = [], this.tokensMap = {}, this.isBackTrackingStack = [], this.RULE_STACK = [], this.RULE_STACK_IDX = -1, this.RULE_OCCURRENCE_STACK = [], this.RULE_OCCURRENCE_STACK_IDX = -1, this.gastProductionsCache = {}, Object.hasOwn(r, "serializedGrammar"))
      throw Error(`The Parser's configuration can no longer contain a <serializedGrammar> property.
	See: https://chevrotain.io/docs/changes/BREAKING_CHANGES.html#_6-0-0
	For Further details.`);
    if (Array.isArray(e)) {
      if (e.length === 0)
        throw Error(`A Token Vocabulary cannot be empty.
	Note that the first argument for the parser constructor
	is no longer a Token vector (since v4.0).`);
      if (typeof e[0].startOffset == "number")
        throw Error(`The Parser constructor no longer accepts a token vector as the first argument.
	See: https://chevrotain.io/docs/changes/BREAKING_CHANGES.html#_4-0-0
	For Further details.`);
    }
    if (Array.isArray(e))
      this.tokensMap = e.reduce((a, s) => (a[s.name] = s, a), {});
    else if (Object.hasOwn(e, "modes") && Object.values(e.modes).flat().every(Gp)) {
      const a = Object.values(e.modes).flat(), s = [...new Set(a)];
      this.tokensMap = s.reduce((o, l) => (o[l.name] = l, o), {});
    } else if (typeof e == "object" && e !== null)
      this.tokensMap = Object.assign({}, e);
    else
      throw new Error("<tokensDictionary> argument must be An Array of Token constructors, A dictionary of Token constructors or an IMultiModeLexerDefinition");
    this.tokensMap.EOF = Qt;
    const i = (Object.hasOwn(e, "modes") ? Object.values(e.modes).flat() : Object.values(e)).every(
      // intentional "==" to also cover "undefined"
      (a) => {
        var s;
        return ((s = a.categoryMatches) === null || s === void 0 ? void 0 : s.length) == 0;
      }
    );
    this.tokenMatcher = i ? Ma : Si, ki(Object.values(this.tokensMap));
  }
  defineRule(e, r, n) {
    if (this.selfAnalysisDone)
      throw Error(`Grammar rule <${e}> may not be defined after the 'performSelfAnalysis' method has been called'
Make sure that all grammar rule definitions are done before 'performSelfAnalysis' is called.`);
    const i = Object.hasOwn(n, "resyncEnabled") ? n.resyncEnabled : ja.resyncEnabled, a = Object.hasOwn(n, "recoveryValueFunc") ? n.recoveryValueFunc : ja.recoveryValueFunc, s = this.ruleShortNameIdx << wm + tr;
    this.ruleShortNameIdx++, this.shortRuleNameToFull[s] = e, this.fullRuleNameToShort[e] = s;
    let o;
    return this.outputCst === !0 ? o = function(...d) {
      try {
        this.ruleInvocationStateUpdate(s, e, this.subruleIdx), r.apply(this, d);
        const p = this.CST_STACK[this.CST_STACK.length - 1];
        return this.cstPostRule(p), p;
      } catch (p) {
        return this.invokeRuleCatch(p, i, a);
      } finally {
        this.ruleFinallyStateUpdate();
      }
    } : o = function(...d) {
      try {
        return this.ruleInvocationStateUpdate(s, e, this.subruleIdx), r.apply(this, d);
      } catch (p) {
        return this.invokeRuleCatch(p, i, a);
      } finally {
        this.ruleFinallyStateUpdate();
      }
    }, Object.assign(function(...d) {
      this.onBeforeParse(e);
      try {
        return o.apply(this, d);
      } finally {
        this.onAfterParse(e);
      }
    }, { ruleName: e, originalGrammarAction: r, coreRule: o });
  }
  invokeRuleCatch(e, r, n) {
    const i = this.RULE_STACK_IDX === 0, a = r && !this.isBackTracking() && this.recoveryEnabled;
    if (Fa(e)) {
      const s = e;
      if (a) {
        const o = this.findReSyncTokenType();
        if (this.isInCurrentRuleReSyncSet(o))
          if (s.resyncedTokens = this.reSyncTo(o), this.outputCst) {
            const l = this.CST_STACK[this.CST_STACK.length - 1];
            return l.recoveredNode = !0, l;
          } else
            return n(e);
        else {
          if (this.outputCst) {
            const l = this.CST_STACK[this.CST_STACK.length - 1];
            l.recoveredNode = !0, s.partialCstResult = l;
          }
          throw s;
        }
      } else {
        if (i)
          return this.moveToTerminatedState(), n(e);
        throw s;
      }
    } else
      throw e;
  }
  // Implementation of parsing DSL
  optionInternal(e, r) {
    const n = this.getKeyForAutomaticLookahead(Vf, r);
    return this.optionInternalLogic(e, r, n);
  }
  optionInternalLogic(e, r, n) {
    let i = this.getLaFuncFromCache(n), a;
    if (typeof e != "function") {
      a = e.DEF;
      const s = e.GATE;
      if (s !== void 0) {
        const o = i;
        i = () => s.call(this) && o.call(this);
      }
    } else
      a = e;
    if (i.call(this) === !0)
      return a.call(this);
  }
  atLeastOneInternal(e, r) {
    const n = this.getKeyForAutomaticLookahead(so, e);
    return this.atLeastOneInternalLogic(e, r, n);
  }
  atLeastOneInternalLogic(e, r, n) {
    let i = this.getLaFuncFromCache(n), a;
    if (typeof r != "function") {
      a = r.DEF;
      const s = r.GATE;
      if (s !== void 0) {
        const o = i;
        i = () => s.call(this) && o.call(this);
      }
    } else
      a = r;
    if (i.call(this) === !0) {
      let s = this.doSingleRepetition(a);
      for (; i.call(this) === !0 && s === !0; )
        s = this.doSingleRepetition(a);
    } else
      throw this.raiseEarlyExitException(e, de.REPETITION_MANDATORY, r.ERR_MSG);
    this.attemptInRepetitionRecovery(this.atLeastOneInternal, [e, r], i, so, e, Hp);
  }
  atLeastOneSepFirstInternal(e, r) {
    const n = this.getKeyForAutomaticLookahead(Sa, e);
    this.atLeastOneSepFirstInternalLogic(e, r, n);
  }
  atLeastOneSepFirstInternalLogic(e, r, n) {
    const i = r.DEF, a = r.SEP;
    if (this.getLaFuncFromCache(n).call(this) === !0) {
      i.call(this);
      const o = () => this.tokenMatcher(this.LA_FAST(1), a);
      for (; this.tokenMatcher(this.LA_FAST(1), a) === !0; )
        this.CONSUME(a), i.call(this);
      this.attemptInRepetitionRecovery(this.repetitionSepSecondInternal, [
        e,
        a,
        o,
        i,
        Sc
      ], o, Sa, e, Sc);
    } else
      throw this.raiseEarlyExitException(e, de.REPETITION_MANDATORY_WITH_SEPARATOR, r.ERR_MSG);
  }
  manyInternal(e, r) {
    const n = this.getKeyForAutomaticLookahead(ao, e);
    return this.manyInternalLogic(e, r, n);
  }
  manyInternalLogic(e, r, n) {
    let i = this.getLaFuncFromCache(n), a;
    if (typeof r != "function") {
      a = r.DEF;
      const o = r.GATE;
      if (o !== void 0) {
        const l = i;
        i = () => o.call(this) && l.call(this);
      }
    } else
      a = r;
    let s = !0;
    for (; i.call(this) === !0 && s === !0; )
      s = this.doSingleRepetition(a);
    this.attemptInRepetitionRecovery(
      this.manyInternal,
      [e, r],
      i,
      ao,
      e,
      Vp,
      // The notStuck parameter is only relevant when "attemptInRepetitionRecovery"
      // is invoked from manyInternal, in the MANY_SEP case and AT_LEAST_ONE[_SEP]
      // An infinite loop cannot occur as:
      // - Either the lookahead is guaranteed to consume something (Single Token Separator)
      // - AT_LEAST_ONE by definition is guaranteed to consume something (or error out).
      s
    );
  }
  manySepFirstInternal(e, r) {
    const n = this.getKeyForAutomaticLookahead(oo, e);
    this.manySepFirstInternalLogic(e, r, n);
  }
  manySepFirstInternalLogic(e, r, n) {
    const i = r.DEF, a = r.SEP;
    if (this.getLaFuncFromCache(n).call(this) === !0) {
      i.call(this);
      const o = () => this.tokenMatcher(this.LA_FAST(1), a);
      for (; this.tokenMatcher(this.LA_FAST(1), a) === !0; )
        this.CONSUME(a), i.call(this);
      this.attemptInRepetitionRecovery(this.repetitionSepSecondInternal, [
        e,
        a,
        o,
        i,
        Cc
      ], o, oo, e, Cc);
    }
  }
  repetitionSepSecondInternal(e, r, n, i, a) {
    for (; n(); )
      this.CONSUME(r), i.call(this);
    this.attemptInRepetitionRecovery(this.repetitionSepSecondInternal, [
      e,
      r,
      n,
      i,
      a
    ], n, Sa, e, a);
  }
  doSingleRepetition(e) {
    const r = this.getLexerPosition();
    return e.call(this), this.getLexerPosition() > r;
  }
  orInternal(e, r) {
    const n = this.getKeyForAutomaticLookahead(Kf, r), i = Array.isArray(e) ? e : e.DEF, s = this.getLaFuncFromCache(n).call(this, i);
    if (s !== void 0)
      return i[s].ALT.call(this);
    this.raiseNoAltException(r, e.ERR_MSG);
  }
  ruleFinallyStateUpdate() {
    this.RULE_STACK_IDX--, this.RULE_OCCURRENCE_STACK_IDX--, this.RULE_STACK_IDX >= 0 && (this.currRuleShortName = this.RULE_STACK[this.RULE_STACK_IDX]), this.cstFinallyStateUpdate();
  }
  subruleInternal(e, r, n) {
    let i;
    try {
      const a = n !== void 0 ? n.ARGS : void 0;
      return this.subruleIdx = r, i = e.coreRule.apply(this, a), this.cstPostNonTerminal(i, n !== void 0 && n.LABEL !== void 0 ? n.LABEL : e.ruleName), i;
    } catch (a) {
      throw this.subruleInternalError(a, n, e.ruleName);
    }
  }
  subruleInternalError(e, r, n) {
    throw Fa(e) && e.partialCstResult !== void 0 && (this.cstPostNonTerminal(e.partialCstResult, r !== void 0 && r.LABEL !== void 0 ? r.LABEL : n), delete e.partialCstResult), e;
  }
  consumeInternal(e, r, n) {
    let i;
    try {
      const a = this.LA_FAST(1);
      this.tokenMatcher(a, e) === !0 ? (this.consumeToken(), i = a) : this.consumeInternalError(e, a, n);
    } catch (a) {
      i = this.consumeInternalRecovery(e, r, a);
    }
    return this.cstPostTerminal(n !== void 0 && n.LABEL !== void 0 ? n.LABEL : e.name, i), i;
  }
  consumeInternalError(e, r, n) {
    let i;
    const a = this.LA(0);
    throw n !== void 0 && n.ERR_MSG ? i = n.ERR_MSG : i = this.errorMessageProvider.buildMismatchTokenMessage({
      expected: e,
      actual: r,
      previous: a,
      ruleName: this.getCurrRuleFullName()
    }), this.SAVE_ERROR(new Bf(i, r, a));
  }
  consumeInternalRecovery(e, r, n) {
    if (this.recoveryEnabled && // TODO: more robust checking of the exception type. Perhaps Typescript extending expressions?
    n.name === "MismatchedTokenException" && !this.isBackTracking()) {
      const i = this.getFollowsForInRuleRecovery(e, r);
      try {
        return this.tryInRuleRecovery(e, i);
      } catch (a) {
        throw a.name === Wf ? n : a;
      }
    } else
      throw n;
  }
  saveRecogState() {
    const e = this.errors, r = this.RULE_STACK.slice(0, this.RULE_STACK_IDX + 1);
    return {
      errors: e,
      lexerState: this.exportLexerState(),
      RULE_STACK: r,
      CST_STACK: this.CST_STACK
    };
  }
  reloadRecogState(e) {
    this.errors = e.errors, this.importLexerState(e.lexerState);
    const r = e.RULE_STACK;
    for (let n = 0; n < r.length; n++)
      this.RULE_STACK[n] = r[n];
    this.RULE_STACK_IDX = r.length - 1, this.RULE_STACK_IDX >= 0 && (this.currRuleShortName = this.RULE_STACK[this.RULE_STACK_IDX]);
  }
  ruleInvocationStateUpdate(e, r, n) {
    this.RULE_OCCURRENCE_STACK[++this.RULE_OCCURRENCE_STACK_IDX] = n, this.RULE_STACK[++this.RULE_STACK_IDX] = e, this.currRuleShortName = e, this.cstInvocationStateUpdate(r);
  }
  isBackTracking() {
    return this.isBackTrackingStack.length !== 0;
  }
  getCurrRuleFullName() {
    const e = this.currRuleShortName;
    return this.shortRuleNameToFull[e];
  }
  shortRuleNameToFullName(e) {
    return this.shortRuleNameToFull[e];
  }
  isAtEndOfInput() {
    return this.tokenMatcher(this.LA(1), Qt);
  }
  reset() {
    this.resetLexerState(), this.subruleIdx = 0, this.currRuleShortName = 0, this.isBackTrackingStack = [], this.errors = [], this.RULE_STACK_IDX = -1, this.RULE_OCCURRENCE_STACK_IDX = -1, this.CST_STACK = [];
  }
  /**
   * Hook called before the root-level parsing rule is invoked.
   * This is only called when a rule is invoked directly by the consumer
   * (e.g., `parser.json()`), not when invoked as a sub-rule via SUBRULE.
   *
   * Override this method to perform actions before parsing begins.
   * The default implementation is a no-op.
   *
   * @param ruleName - The name of the root rule being invoked.
   */
  onBeforeParse(e) {
    for (let r = 0; r < this.maxLookahead + 1; r++)
      this.tokVector.push(an);
  }
  /**
   * Hook called after the root-level parsing rule has completed (or thrown).
   * This is only called when a rule is invoked directly by the consumer
   * (e.g., `parser.json()`), not when invoked as a sub-rule via SUBRULE.
   *
   * This hook is called in a `finally` block, so it executes regardless of
   * whether parsing succeeded or threw an error.
   *
   * Override this method to perform actions after parsing completes.
   * The default implementation is a no-op.
   *
   * @param ruleName - The name of the root rule that was invoked.
   */
  onAfterParse(e) {
    if (this.isAtEndOfInput() === !1) {
      const r = this.LA(1), n = this.errorMessageProvider.buildNotAllInputParsedMessage({
        firstRedundant: r,
        ruleName: this.getCurrRuleFullName()
      });
      this.SAVE_ERROR(new Am(n, r));
    }
    for (; this.tokVector.at(-1) === an; )
      this.tokVector.pop();
  }
}
class qm {
  initErrorHandler(e) {
    this._errors = [], this.errorMessageProvider = Object.hasOwn(e, "errorMessageProvider") ? e.errorMessageProvider : Ut.errorMessageProvider;
  }
  SAVE_ERROR(e) {
    if (Fa(e))
      return e.context = {
        ruleStack: this.getHumanReadableRuleStack(),
        ruleOccurrenceStack: this.RULE_OCCURRENCE_STACK.slice(0, this.RULE_OCCURRENCE_STACK_IDX + 1)
      }, this._errors.push(e), e;
    throw Error("Trying to save an Error which is not a RecognitionException");
  }
  get errors() {
    return [...this._errors];
  }
  set errors(e) {
    this._errors = e;
  }
  // TODO: consider caching the error message computed information
  raiseEarlyExitException(e, r, n) {
    const i = this.getCurrRuleFullName(), a = this.getGAstProductions()[i], o = ss(e, a, r, this.maxLookahead)[0], l = [];
    for (let u = 1; u <= this.maxLookahead; u++)
      l.push(this.LA(u));
    const c = this.errorMessageProvider.buildEarlyExitMessage({
      expectedIterationPaths: o,
      actual: l,
      previous: this.LA(0),
      customUserDescription: n,
      ruleName: i
    });
    throw this.SAVE_ERROR(new $m(c, this.LA(1), this.LA(0)));
  }
  // TODO: consider caching the error message computed information
  raiseNoAltException(e, r) {
    const n = this.getCurrRuleFullName(), i = this.getGAstProductions()[n], a = as(e, i, this.maxLookahead), s = [];
    for (let c = 1; c <= this.maxLookahead; c++)
      s.push(this.LA(c));
    const o = this.LA(0), l = this.errorMessageProvider.buildNoViableAltMessage({
      expectedPathsPerAlt: a,
      actual: s,
      previous: o,
      customUserDescription: r,
      ruleName: this.getCurrRuleFullName()
    });
    throw this.SAVE_ERROR(new Em(l, this.LA(1), o));
  }
}
const ls = {
  description: "This Object indicates the Parser is during Recording Phase"
};
Object.freeze(ls);
const _c = !0, Ic = Math.pow(2, tr) - 1, Xf = Pf({ name: "RECORDING_PHASE_TOKEN", pattern: We.NA });
ki([Xf]);
const Yf = Dl(
  Xf,
  `This IToken indicates the Parser is in Recording Phase
	See: https://chevrotain.io/docs/guide/internals.html#grammar-recording for details`,
  // Using "-1" instead of NaN (as in EOF) because an actual number is less likely to
  // cause errors if the output of LA or CONSUME would be (incorrectly) used during the recording phase.
  -1,
  -1,
  -1,
  -1,
  -1,
  -1
);
Object.freeze(Yf);
const Bm = {
  name: `This CSTNode indicates the Parser is in Recording Phase
	See: https://chevrotain.io/docs/guide/internals.html#grammar-recording for details`,
  children: {}
};
class Wm {
  initGastRecorder(e) {
    this.recordingProdStack = [], this.RECORDING_PHASE = !1;
  }
  enableRecording() {
    this.RECORDING_PHASE = !0, this.TRACE_INIT("Enable Recording", () => {
      for (let e = 0; e < 10; e++) {
        const r = e > 0 ? e : "";
        this[`CONSUME${r}`] = function(n, i) {
          return this.consumeInternalRecord(n, e, i);
        }, this[`SUBRULE${r}`] = function(n, i) {
          return this.subruleInternalRecord(n, e, i);
        }, this[`OPTION${r}`] = function(n) {
          return this.optionInternalRecord(n, e);
        }, this[`OR${r}`] = function(n) {
          return this.orInternalRecord(n, e);
        }, this[`MANY${r}`] = function(n) {
          this.manyInternalRecord(e, n);
        }, this[`MANY_SEP${r}`] = function(n) {
          this.manySepFirstInternalRecord(e, n);
        }, this[`AT_LEAST_ONE${r}`] = function(n) {
          this.atLeastOneInternalRecord(e, n);
        }, this[`AT_LEAST_ONE_SEP${r}`] = function(n) {
          this.atLeastOneSepFirstInternalRecord(e, n);
        };
      }
      this.consume = function(e, r, n) {
        return this.consumeInternalRecord(r, e, n);
      }, this.subrule = function(e, r, n) {
        return this.subruleInternalRecord(r, e, n);
      }, this.option = function(e, r) {
        return this.optionInternalRecord(r, e);
      }, this.or = function(e, r) {
        return this.orInternalRecord(r, e);
      }, this.many = function(e, r) {
        this.manyInternalRecord(e, r);
      }, this.atLeastOne = function(e, r) {
        this.atLeastOneInternalRecord(e, r);
      }, this.ACTION = this.ACTION_RECORD, this.BACKTRACK = this.BACKTRACK_RECORD, this.LA = this.LA_RECORD;
    });
  }
  disableRecording() {
    this.RECORDING_PHASE = !1, this.TRACE_INIT("Deleting Recording methods", () => {
      const e = this;
      for (let r = 0; r < 10; r++) {
        const n = r > 0 ? r : "";
        delete e[`CONSUME${n}`], delete e[`SUBRULE${n}`], delete e[`OPTION${n}`], delete e[`OR${n}`], delete e[`MANY${n}`], delete e[`MANY_SEP${n}`], delete e[`AT_LEAST_ONE${n}`], delete e[`AT_LEAST_ONE_SEP${n}`];
      }
      delete e.consume, delete e.subrule, delete e.option, delete e.or, delete e.many, delete e.atLeastOne, delete e.ACTION, delete e.BACKTRACK, delete e.LA;
    });
  }
  //   Parser methods are called inside an ACTION?
  //   Maybe try/catch/finally on ACTIONS while disabling the recorders state changes?
  // @ts-expect-error -- noop place holder
  ACTION_RECORD(e) {
  }
  // Executing backtracking logic will break our recording logic assumptions
  BACKTRACK_RECORD(e, r) {
    return () => !0;
  }
  // LA is part of the official API and may be used for custom lookahead logic
  // by end users who may forget to wrap it in ACTION or inside a GATE
  LA_RECORD(e) {
    return an;
  }
  topLevelRuleRecord(e, r) {
    try {
      const n = new dn({ definition: [], name: e });
      return n.name = e, this.recordingProdStack.push(n), r.call(this), this.recordingProdStack.pop(), n;
    } catch (n) {
      if (n.KNOWN_RECORDER_ERROR !== !0)
        try {
          n.message = n.message + `
	 This error was thrown during the "grammar recording phase" For more info see:
	https://chevrotain.io/docs/guide/internals.html#grammar-recording`;
        } catch {
          throw n;
        }
      throw n;
    }
  }
  // Implementation of parsing DSL
  optionInternalRecord(e, r) {
    return Ln.call(this, Me, e, r);
  }
  atLeastOneInternalRecord(e, r) {
    Ln.call(this, et, r, e);
  }
  atLeastOneSepFirstInternalRecord(e, r) {
    Ln.call(this, tt, r, e, _c);
  }
  manyInternalRecord(e, r) {
    Ln.call(this, Te, r, e);
  }
  manySepFirstInternalRecord(e, r) {
    Ln.call(this, Ve, r, e, _c);
  }
  orInternalRecord(e, r) {
    return Km.call(this, e, r);
  }
  subruleInternalRecord(e, r, n) {
    if (Ga(r), !e || !Object.hasOwn(e, "ruleName")) {
      const o = new Error(`<SUBRULE${Pc(r)}> argument is invalid expecting a Parser method reference but got: <${JSON.stringify(e)}>
 inside top level rule: <${this.recordingProdStack[0].name}>`);
      throw o.KNOWN_RECORDER_ERROR = !0, o;
    }
    const i = this.recordingProdStack.at(-1), a = e.ruleName, s = new qe({
      idx: r,
      nonTerminalName: a,
      label: n?.LABEL,
      // The resolving of the `referencedRule` property will be done once all the Rule's GASTs have been created
      referencedRule: void 0
    });
    return i.definition.push(s), this.outputCst ? Bm : ls;
  }
  consumeInternalRecord(e, r, n) {
    if (Ga(r), !_f(e)) {
      const s = new Error(`<CONSUME${Pc(r)}> argument is invalid expecting a TokenType reference but got: <${JSON.stringify(e)}>
 inside top level rule: <${this.recordingProdStack[0].name}>`);
      throw s.KNOWN_RECORDER_ERROR = !0, s;
    }
    const i = this.recordingProdStack.at(-1), a = new ae({
      idx: r,
      terminalType: e,
      label: n?.LABEL
    });
    return i.definition.push(a), Yf;
  }
}
function Ln(t, e, r, n = !1) {
  Ga(r);
  const i = this.recordingProdStack.at(-1), a = typeof e == "function" ? e : e.DEF, s = new t({ definition: [], idx: r });
  return n && (s.separator = e.SEP), Object.hasOwn(e, "MAX_LOOKAHEAD") && (s.maxLookahead = e.MAX_LOOKAHEAD), this.recordingProdStack.push(s), a.call(this), i.definition.push(s), this.recordingProdStack.pop(), ls;
}
function Km(t, e) {
  Ga(e);
  const r = this.recordingProdStack.at(-1), n = Array.isArray(t) === !1, i = n === !1 ? t : t.DEF, a = new He({
    definition: [],
    idx: e,
    ignoreAmbiguities: n && t.IGNORE_AMBIGUITIES === !0
  });
  Object.hasOwn(t, "MAX_LOOKAHEAD") && (a.maxLookahead = t.MAX_LOOKAHEAD);
  const s = i.some((o) => typeof o.GATE == "function");
  return a.hasPredicates = s, r.definition.push(a), i.forEach((o) => {
    const l = new Ke({ definition: [] });
    a.definition.push(l), Object.hasOwn(o, "IGNORE_AMBIGUITIES") ? l.ignoreAmbiguities = o.IGNORE_AMBIGUITIES : Object.hasOwn(o, "GATE") && (l.ignoreAmbiguities = !0), this.recordingProdStack.push(l), o.ALT.call(this), this.recordingProdStack.pop();
  }), ls;
}
function Pc(t) {
  return t === 0 ? "" : `${t}`;
}
function Ga(t) {
  if (t < 0 || t > Ic) {
    const e = new Error(
      // The stack trace will contain all the needed details
      `Invalid DSL Method idx value: <${t}>
	Idx value must be a none negative value smaller than ${Ic + 1}`
    );
    throw e.KNOWN_RECORDER_ERROR = !0, e;
  }
}
class Vm {
  initPerformanceTracer(e) {
    if (Object.hasOwn(e, "traceInitPerf")) {
      const r = e.traceInitPerf, n = typeof r == "number";
      this.traceInitMaxIdent = n ? r : 1 / 0, this.traceInitPerf = n ? r > 0 : r;
    } else
      this.traceInitMaxIdent = 0, this.traceInitPerf = Ut.traceInitPerf;
    this.traceInitIndent = -1;
  }
  TRACE_INIT(e, r) {
    if (this.traceInitPerf === !0) {
      this.traceInitIndent++;
      const n = new Array(this.traceInitIndent + 1).join("	");
      this.traceInitIndent < this.traceInitMaxIdent && console.log(`${n}--> <${e}>`);
      const { time: i, value: a } = Ef(r), s = i > 10 ? console.warn : console.log;
      return this.traceInitIndent < this.traceInitMaxIdent && s(`${n}<-- <${e}> time: ${i}ms`), this.traceInitIndent--, a;
    } else
      return r();
  }
}
function Hm(t, e) {
  e.forEach((r) => {
    const n = r.prototype;
    Object.getOwnPropertyNames(n).forEach((i) => {
      if (i === "constructor")
        return;
      const a = Object.getOwnPropertyDescriptor(n, i);
      a && (a.get || a.set) ? Object.defineProperty(t.prototype, i, a) : t.prototype[i] = r.prototype[i];
    });
  });
}
const an = Dl(Qt, "", NaN, NaN, NaN, NaN, NaN, NaN);
Object.freeze(an);
const Ut = Object.freeze({
  recoveryEnabled: !1,
  maxLookahead: 3,
  dynamicTokensEnabled: !1,
  outputCst: !0,
  errorMessageProvider: tn,
  nodeLocationTracking: "none",
  traceInitPerf: !1,
  skipValidations: !1
}), ja = Object.freeze({
  recoveryValueFunc: () => {
  },
  resyncEnabled: !0
});
var Be;
(function(t) {
  t[t.INVALID_RULE_NAME = 0] = "INVALID_RULE_NAME", t[t.DUPLICATE_RULE_NAME = 1] = "DUPLICATE_RULE_NAME", t[t.INVALID_RULE_OVERRIDE = 2] = "INVALID_RULE_OVERRIDE", t[t.DUPLICATE_PRODUCTIONS = 3] = "DUPLICATE_PRODUCTIONS", t[t.UNRESOLVED_SUBRULE_REF = 4] = "UNRESOLVED_SUBRULE_REF", t[t.LEFT_RECURSION = 5] = "LEFT_RECURSION", t[t.NONE_LAST_EMPTY_ALT = 6] = "NONE_LAST_EMPTY_ALT", t[t.AMBIGUOUS_ALTS = 7] = "AMBIGUOUS_ALTS", t[t.CONFLICT_TOKENS_RULES_NAMESPACE = 8] = "CONFLICT_TOKENS_RULES_NAMESPACE", t[t.INVALID_TOKEN_NAME = 9] = "INVALID_TOKEN_NAME", t[t.NO_NON_EMPTY_LOOKAHEAD = 10] = "NO_NON_EMPTY_LOOKAHEAD", t[t.AMBIGUOUS_PREFIX_ALTS = 11] = "AMBIGUOUS_PREFIX_ALTS", t[t.TOO_MANY_ALTS = 12] = "TOO_MANY_ALTS", t[t.CUSTOM_LOOKAHEAD_VALIDATION = 13] = "CUSTOM_LOOKAHEAD_VALIDATION";
})(Be || (Be = {}));
function Oc(t = void 0) {
  return function() {
    return t;
  };
}
class wi {
  /**
   *  @deprecated use the **instance** method with the same name instead
   */
  static performSelfAnalysis(e) {
    throw Error("The **static** `performSelfAnalysis` method has been deprecated.	\nUse the **instance** method with the same name instead.");
  }
  performSelfAnalysis() {
    this.TRACE_INIT("performSelfAnalysis", () => {
      let e;
      this.selfAnalysisDone = !0;
      const r = this.className;
      this.TRACE_INIT("toFastProps", () => {
        Af(this);
      }), this.TRACE_INIT("Grammar Recording", () => {
        try {
          this.enableRecording(), this.definedRulesNames.forEach((i) => {
            const s = this[i].originalGrammarAction;
            let o;
            this.TRACE_INIT(`${i} Rule`, () => {
              o = this.topLevelRuleRecord(i, s);
            }), this.gastProductionsCache[i] = o;
          });
        } finally {
          this.disableRecording();
        }
      });
      let n = [];
      if (this.TRACE_INIT("Grammar Resolving", () => {
        n = Rm({
          rules: Object.values(this.gastProductionsCache)
        }), this.definitionErrors = this.definitionErrors.concat(n);
      }), this.TRACE_INIT("Grammar Validations", () => {
        if (n.length === 0 && this.skipValidations === !1) {
          const i = vm({
            rules: Object.values(this.gastProductionsCache),
            tokenTypes: Object.values(this.tokensMap),
            errMsgProvider: Cr,
            grammarName: r
          }), a = im({
            lookaheadStrategy: this.lookaheadStrategy,
            rules: Object.values(this.gastProductionsCache),
            tokenTypes: Object.values(this.tokensMap),
            grammarName: r
          });
          this.definitionErrors = this.definitionErrors.concat(i, a);
        }
      }), this.definitionErrors.length === 0 && (this.recoveryEnabled && this.TRACE_INIT("computeAllProdsFollows", () => {
        const i = tp(Object.values(this.gastProductionsCache));
        this.resyncFollows = i;
      }), this.TRACE_INIT("ComputeLookaheadFunctions", () => {
        var i, a;
        (a = (i = this.lookaheadStrategy).initialize) === null || a === void 0 || a.call(i, {
          rules: Object.values(this.gastProductionsCache)
        }), this.preComputeLookaheadFunctions(Object.values(this.gastProductionsCache));
      })), !wi.DEFER_DEFINITION_ERRORS_HANDLING && this.definitionErrors.length !== 0)
        throw e = this.definitionErrors.map((i) => i.message), new Error(`Parser Definition Errors detected:
 ${e.join(`
-------------------------------
`)}`);
    });
  }
  constructor(e, r) {
    this.definitionErrors = [], this.selfAnalysisDone = !1;
    const n = this;
    if (n.initErrorHandler(r), n.initLexerAdapter(), n.initLooksAhead(r), n.initRecognizerEngine(e, r), n.initRecoverable(r), n.initTreeBuilder(r), n.initGastRecorder(r), n.initPerformanceTracer(r), Object.hasOwn(r, "ignoredIssues"))
      throw new Error(`The <ignoredIssues> IParserConfig property has been deprecated.
	Please use the <IGNORE_AMBIGUITIES> flag on the relevant DSL method instead.
	See: https://chevrotain.io/docs/guide/resolving_grammar_errors.html#IGNORING_AMBIGUITIES
	For further details.`);
    this.skipValidations = Object.hasOwn(r, "skipValidations") ? r.skipValidations : Ut.skipValidations;
  }
}
wi.DEFER_DEFINITION_ERRORS_HANDLING = !1;
Hm(wi, [
  Sm,
  bm,
  Gm,
  jm,
  Um,
  zm,
  qm,
  Wm,
  Vm
]);
class Xm extends wi {
  constructor(e, r = Ut) {
    const n = Object.assign({}, r);
    n.outputCst = !1, super(e, n);
  }
}
function sn(t, e, r) {
  return `${t.name}_${e}_${r}`;
}
const er = 1, Ym = 2, Jf = 4, Zf = 5, cs = 7, Jm = 8, Zm = 9, Qm = 10, eg = 11, Qf = 12;
class jl {
  constructor(e) {
    this.target = e;
  }
  isEpsilon() {
    return !1;
  }
}
class zl extends jl {
  constructor(e, r) {
    super(e), this.tokenType = r;
  }
}
class ed extends jl {
  constructor(e) {
    super(e);
  }
  isEpsilon() {
    return !0;
  }
}
class Ul extends jl {
  constructor(e, r, n) {
    super(e), this.rule = r, this.followState = n;
  }
  isEpsilon() {
    return !0;
  }
}
function tg(t) {
  const e = {
    decisionMap: {},
    decisionStates: [],
    ruleToStartState: /* @__PURE__ */ new Map(),
    ruleToStopState: /* @__PURE__ */ new Map(),
    states: []
  };
  rg(e, t);
  const r = t.length;
  for (let n = 0; n < r; n++) {
    const i = t[n], a = Pr(e, i, i);
    a !== void 0 && hg(e, i, a);
  }
  return e;
}
function rg(t, e) {
  const r = e.length;
  for (let n = 0; n < r; n++) {
    const i = e[n], a = Ne(t, i, void 0, {
      type: Ym
    }), s = Ne(t, i, void 0, {
      type: cs
    });
    a.stop = s, t.ruleToStartState.set(i, a), t.ruleToStopState.set(i, s);
  }
}
function td(t, e, r) {
  return r instanceof ae ? ql(t, e, r.terminalType, r) : r instanceof qe ? dg(t, e, r) : r instanceof He ? og(t, e, r) : r instanceof Me ? lg(t, e, r) : r instanceof Te ? ng(t, e, r) : r instanceof Ve ? ig(t, e, r) : r instanceof et ? ag(t, e, r) : r instanceof tt ? sg(t, e, r) : Pr(t, e, r);
}
function ng(t, e, r) {
  const n = Ne(t, e, r, {
    type: Zf
  });
  rr(t, n);
  const i = pn(t, e, n, r, Pr(t, e, r));
  return nd(t, e, r, i);
}
function ig(t, e, r) {
  const n = Ne(t, e, r, {
    type: Zf
  });
  rr(t, n);
  const i = pn(t, e, n, r, Pr(t, e, r)), a = ql(t, e, r.separator, r);
  return nd(t, e, r, i, a);
}
function ag(t, e, r) {
  const n = Ne(t, e, r, {
    type: Jf
  });
  rr(t, n);
  const i = pn(t, e, n, r, Pr(t, e, r));
  return rd(t, e, r, i);
}
function sg(t, e, r) {
  const n = Ne(t, e, r, {
    type: Jf
  });
  rr(t, n);
  const i = pn(t, e, n, r, Pr(t, e, r)), a = ql(t, e, r.separator, r);
  return rd(t, e, r, i, a);
}
function og(t, e, r) {
  const n = Ne(t, e, r, {
    type: er
  });
  rr(t, n);
  const i = Ft(r.definition, (s) => td(t, e, s));
  return pn(t, e, n, r, ...i);
}
function lg(t, e, r) {
  const n = Ne(t, e, r, {
    type: er
  });
  rr(t, n);
  const i = pn(t, e, n, r, Pr(t, e, r));
  return cg(t, e, r, i);
}
function Pr(t, e, r) {
  const n = zd(Ft(r.definition, (i) => td(t, e, i)), (i) => i !== void 0);
  return n.length === 1 ? n[0] : n.length === 0 ? void 0 : fg(t, n);
}
function rd(t, e, r, n, i) {
  const a = n.left, s = n.right, o = Ne(t, e, r, {
    type: eg
  });
  rr(t, o);
  const l = Ne(t, e, r, {
    type: Qf
  });
  return a.loopback = o, l.loopback = o, t.decisionMap[sn(e, i ? "RepetitionMandatoryWithSeparator" : "RepetitionMandatory", r.idx)] = o, Se(s, o), i === void 0 ? (Se(o, a), Se(o, l)) : (Se(o, l), Se(o, i.left), Se(i.right, a)), {
    left: a,
    right: l
  };
}
function nd(t, e, r, n, i) {
  const a = n.left, s = n.right, o = Ne(t, e, r, {
    type: Qm
  });
  rr(t, o);
  const l = Ne(t, e, r, {
    type: Qf
  }), c = Ne(t, e, r, {
    type: Zm
  });
  return o.loopback = c, l.loopback = c, Se(o, a), Se(o, l), Se(s, c), i !== void 0 ? (Se(c, l), Se(c, i.left), Se(i.right, a)) : Se(c, o), t.decisionMap[sn(e, i ? "RepetitionWithSeparator" : "Repetition", r.idx)] = o, {
    left: o,
    right: l
  };
}
function cg(t, e, r, n) {
  const i = n.left, a = n.right;
  return Se(i, a), t.decisionMap[sn(e, "Option", r.idx)] = i, n;
}
function rr(t, e) {
  return t.decisionStates.push(e), e.decision = t.decisionStates.length - 1, e.decision;
}
function pn(t, e, r, n, ...i) {
  const a = Ne(t, e, n, {
    type: Jm,
    start: r
  });
  r.end = a;
  for (const o of i)
    o !== void 0 ? (Se(r, o.left), Se(o.right, a)) : Se(r, a);
  const s = {
    left: r,
    right: a
  };
  return t.decisionMap[sn(e, ug(n), n.idx)] = r, s;
}
function ug(t) {
  if (t instanceof He)
    return "Alternation";
  if (t instanceof Me)
    return "Option";
  if (t instanceof Te)
    return "Repetition";
  if (t instanceof Ve)
    return "RepetitionWithSeparator";
  if (t instanceof et)
    return "RepetitionMandatory";
  if (t instanceof tt)
    return "RepetitionMandatoryWithSeparator";
  throw new Error("Invalid production type encountered");
}
function fg(t, e) {
  const r = e.length;
  for (let a = 0; a < r - 1; a++) {
    const s = e[a];
    let o;
    s.left.transitions.length === 1 && (o = s.left.transitions[0]);
    const l = o instanceof Ul, c = o, u = e[a + 1].left;
    s.left.type === er && s.right.type === er && o !== void 0 && (l && c.followState === s.right || o.target === s.right) ? (l ? c.followState = u : o.target = u, pg(t, s.right)) : Se(s.right, u);
  }
  const n = e[0], i = e[r - 1];
  return {
    left: n.left,
    right: i.right
  };
}
function ql(t, e, r, n) {
  const i = Ne(t, e, n, {
    type: er
  }), a = Ne(t, e, n, {
    type: er
  });
  return Bl(i, new zl(a, r)), {
    left: i,
    right: a
  };
}
function dg(t, e, r) {
  const n = r.referencedRule, i = t.ruleToStartState.get(n), a = Ne(t, e, r, {
    type: er
  }), s = Ne(t, e, r, {
    type: er
  }), o = new Ul(i, n, s);
  return Bl(a, o), {
    left: a,
    right: s
  };
}
function hg(t, e, r) {
  const n = t.ruleToStartState.get(e);
  Se(n, r.left);
  const i = t.ruleToStopState.get(e);
  return Se(r.right, i), {
    left: n,
    right: i
  };
}
function Se(t, e) {
  const r = new ed(e);
  Bl(t, r);
}
function Ne(t, e, r, n) {
  const i = Object.assign({
    atn: t,
    production: r,
    epsilonOnlyTransitions: !1,
    rule: e,
    transitions: [],
    nextTokenWithinRule: [],
    stateNumber: t.states.length
  }, n);
  return t.states.push(i), i;
}
function Bl(t, e) {
  t.transitions.length === 0 && (t.epsilonOnlyTransitions = e.isEpsilon()), t.transitions.push(e);
}
function pg(t, e) {
  t.states.splice(t.states.indexOf(e), 1);
}
const za = {};
class co {
  constructor() {
    this.map = {}, this.configs = [];
  }
  get size() {
    return this.configs.length;
  }
  finalize() {
    this.map = {};
  }
  add(e) {
    const r = id(e);
    r in this.map || (this.map[r] = this.configs.length, this.configs.push(e));
  }
  get elements() {
    return this.configs;
  }
  get alts() {
    return Ft(this.configs, (e) => e.alt);
  }
  get key() {
    let e = "";
    for (const r in this.map)
      e += r + ":";
    return e;
  }
}
function id(t, e = !0) {
  return `${e ? `a${t.alt}` : ""}s${t.state.stateNumber}:${t.stack.map((r) => r.stateNumber.toString()).join("_")}`;
}
function mg(t, e) {
  const r = {};
  return (n) => {
    const i = n.toString();
    let a = r[i];
    return a !== void 0 || (a = {
      atnStartState: t,
      decision: e,
      states: {}
    }, r[i] = a), a;
  };
}
class ad {
  constructor() {
    this.predicates = [];
  }
  is(e) {
    return e >= this.predicates.length || this.predicates[e];
  }
  set(e, r) {
    this.predicates[e] = r;
  }
  toString() {
    let e = "";
    const r = this.predicates.length;
    for (let n = 0; n < r; n++)
      e += this.predicates[n] === !0 ? "1" : "0";
    return e;
  }
}
const Lc = new ad();
class gg extends Gl {
  constructor(e) {
    var r;
    super(), this.logging = (r = e?.logging) !== null && r !== void 0 ? r : ((n) => console.log(n));
  }
  initialize(e) {
    this.atn = tg(e.rules), this.dfas = yg(this.atn);
  }
  validateAmbiguousAlternationAlternatives() {
    return [];
  }
  validateEmptyOrAlternatives() {
    return [];
  }
  buildLookaheadForAlternation(e) {
    const { prodOccurrence: r, rule: n, hasPredicates: i, dynamicTokensEnabled: a } = e, s = this.dfas, o = this.logging, l = sn(n, "Alternation", r), u = this.atn.decisionMap[l].decision, d = Ft(kc({
      maxLookahead: 1,
      occurrence: r,
      prodType: "Alternation",
      rule: n
    }), (p) => Ft(p, (m) => m[0]));
    if (xc(d, !1) && !a) {
      const p = Zl(d, (m, A, b) => (hs(A, (I) => {
        I && (m[I.tokenTypeIdx] = b, hs(I.categoryMatches, (k) => {
          m[k] = b;
        }));
      }), m), {});
      return i ? function(m) {
        var A;
        const b = this.LA_FAST(1), I = p[b.tokenTypeIdx];
        if (m !== void 0 && I !== void 0) {
          const k = (A = m[I]) === null || A === void 0 ? void 0 : A.GATE;
          if (k !== void 0 && k.call(this) === !1)
            return;
        }
        return I;
      } : function() {
        const m = this.LA_FAST(1);
        return p[m.tokenTypeIdx];
      };
    } else return i ? function(p) {
      const m = new ad(), A = p === void 0 ? 0 : p.length;
      for (let I = 0; I < A; I++) {
        const k = p?.[I].GATE;
        m.set(I, k === void 0 || k.call(this));
      }
      const b = $s.call(this, s, u, m, o);
      return typeof b == "number" ? b : void 0;
    } : function() {
      const p = $s.call(this, s, u, Lc, o);
      return typeof p == "number" ? p : void 0;
    };
  }
  buildLookaheadForOptional(e) {
    const { prodOccurrence: r, rule: n, prodType: i, dynamicTokensEnabled: a } = e, s = this.dfas, o = this.logging, l = sn(n, i, r), u = this.atn.decisionMap[l].decision, d = Ft(kc({
      maxLookahead: 1,
      occurrence: r,
      prodType: i,
      rule: n
    }), (p) => Ft(p, (m) => m[0]));
    if (xc(d) && d[0][0] && !a) {
      const p = d[0], m = Dd(p);
      if (m.length === 1 && Ud(m[0].categoryMatches)) {
        const b = m[0].tokenTypeIdx;
        return function() {
          return this.LA_FAST(1).tokenTypeIdx === b;
        };
      } else {
        const A = Zl(m, (b, I) => (I !== void 0 && (b[I.tokenTypeIdx] = !0, hs(I.categoryMatches, (k) => {
          b[k] = !0;
        })), b), {});
        return function() {
          const b = this.LA_FAST(1);
          return A[b.tokenTypeIdx] === !0;
        };
      }
    }
    return function() {
      const p = $s.call(this, s, u, Lc, o);
      return typeof p == "object" ? !1 : p === 0;
    };
  }
}
function xc(t, e = !0) {
  const r = /* @__PURE__ */ new Set();
  for (const n of t) {
    const i = /* @__PURE__ */ new Set();
    for (const a of n) {
      if (a === void 0) {
        if (e)
          break;
        return !1;
      }
      const s = [a.tokenTypeIdx].concat(a.categoryMatches);
      for (const o of s)
        if (r.has(o)) {
          if (!i.has(o))
            return !1;
        } else
          r.add(o), i.add(o);
    }
  }
  return !0;
}
function yg(t) {
  const e = t.decisionStates.length, r = Array(e);
  for (let n = 0; n < e; n++)
    r[n] = mg(t.decisionStates[n], n);
  return r;
}
function $s(t, e, r, n) {
  const i = t[e](r);
  let a = i.start;
  if (a === void 0) {
    const o = bg(i.atnStartState);
    a = od(i, sd(o)), i.start = a;
  }
  return Tg.apply(this, [i, a, r, n]);
}
function Tg(t, e, r, n) {
  let i = e, a = 1;
  const s = [];
  let o = this.LA_FAST(a++);
  for (; ; ) {
    let l = Cg(i, o);
    if (l === void 0 && (l = Rg.apply(this, [t, i, o, a, r, n])), l === za)
      return $g(s, i, o);
    if (l.isAcceptState === !0)
      return l.prediction;
    i = l, s.push(o), o = this.LA(a++);
  }
}
function Rg(t, e, r, n, i, a) {
  const s = Sg(e.configs, r, i);
  if (s.size === 0)
    return Dc(t, e, r, za), za;
  let o = sd(s);
  const l = wg(s, i);
  if (l !== void 0)
    o.isAcceptState = !0, o.prediction = l, o.configs.uniqueAlt = l;
  else if (Ig(s)) {
    const c = Md(s.alts);
    o.isAcceptState = !0, o.prediction = c, o.configs.uniqueAlt = c, vg.apply(this, [t, n, s.alts, a]);
  }
  return o = Dc(t, e, r, o), o;
}
function vg(t, e, r, n) {
  const i = [];
  for (let c = 1; c <= e; c++)
    i.push(this.LA(c).tokenType);
  const a = t.atnStartState, s = a.rule, o = a.production, l = Eg({
    topLevelRule: s,
    ambiguityIndices: r,
    production: o,
    prefixPath: i
  });
  n(l);
}
function Eg(t) {
  const e = Ft(t.prefixPath, (i) => nn(i)).join(", "), r = t.production.idx === 0 ? "" : t.production.idx;
  let n = `Ambiguous Alternatives Detected: <${t.ambiguityIndices.join(", ")}> in <${Ag(t.production)}${r}> inside <${t.topLevelRule.name}> Rule,
<${e}> may appears as a prefix path in all these alternatives.
`;
  return n = n + `See: https://chevrotain.io/docs/guide/resolving_grammar_errors.html#AMBIGUOUS_ALTERNATIVES
For Further details.`, n;
}
function Ag(t) {
  if (t instanceof qe)
    return "SUBRULE";
  if (t instanceof Me)
    return "OPTION";
  if (t instanceof He)
    return "OR";
  if (t instanceof et)
    return "AT_LEAST_ONE";
  if (t instanceof tt)
    return "AT_LEAST_ONE_SEP";
  if (t instanceof Ve)
    return "MANY_SEP";
  if (t instanceof Te)
    return "MANY";
  if (t instanceof ae)
    return "CONSUME";
  throw Error("non exhaustive match");
}
function $g(t, e, r) {
  const n = Bd(e.configs.elements, (a) => a.state.transitions), i = Wd(n.filter((a) => a instanceof zl).map((a) => a.tokenType), (a) => a.tokenTypeIdx);
  return {
    actualToken: r,
    possibleTokenTypes: i,
    tokenPath: t
  };
}
function Cg(t, e) {
  return t.edges[e.tokenTypeIdx];
}
function Sg(t, e, r) {
  const n = new co(), i = [];
  for (const s of t.elements) {
    if (r.is(s.alt) === !1)
      continue;
    if (s.state.type === cs) {
      i.push(s);
      continue;
    }
    const o = s.state.transitions.length;
    for (let l = 0; l < o; l++) {
      const c = s.state.transitions[l], u = kg(c, e);
      u !== void 0 && n.add({
        state: u,
        alt: s.alt,
        stack: s.stack
      });
    }
  }
  let a;
  if (i.length === 0 && n.size === 1 && (a = n), a === void 0) {
    a = new co();
    for (const s of n.elements)
      Ua(s, a);
  }
  if (i.length > 0 && a.size === 0)
    for (const s of i)
      a.add(s);
  return a;
}
function kg(t, e) {
  if (t instanceof zl && Of(e, t.tokenType))
    return t.target;
}
function wg(t, e) {
  let r;
  for (const n of t.elements)
    if (e.is(n.alt) === !0) {
      if (r === void 0)
        r = n.alt;
      else if (r !== n.alt)
        return;
    }
  return r;
}
function sd(t) {
  return {
    configs: t,
    edges: {},
    isAcceptState: !1,
    prediction: -1
  };
}
function Dc(t, e, r, n) {
  return n = od(t, n), e.edges[r.tokenTypeIdx] = n, n;
}
function od(t, e) {
  if (e === za)
    return e;
  const r = e.configs.key, n = t.states[r];
  return n !== void 0 ? n : (e.configs.finalize(), t.states[r] = e, e);
}
function bg(t) {
  const e = new co(), r = t.transitions.length;
  for (let n = 0; n < r; n++) {
    const a = {
      state: t.transitions[n].target,
      alt: n,
      stack: []
    };
    Ua(a, e);
  }
  return e;
}
function Ua(t, e) {
  const r = t.state;
  if (r.type === cs) {
    if (t.stack.length > 0) {
      const i = [...t.stack], s = {
        state: i.pop(),
        alt: t.alt,
        stack: i
      };
      Ua(s, e);
    } else
      e.add(t);
    return;
  }
  r.epsilonOnlyTransitions || e.add(t);
  const n = r.transitions.length;
  for (let i = 0; i < n; i++) {
    const a = r.transitions[i], s = Ng(t, a);
    s !== void 0 && Ua(s, e);
  }
}
function Ng(t, e) {
  if (e instanceof ed)
    return {
      state: e.target,
      alt: t.alt,
      stack: t.stack
    };
  if (e instanceof Ul) {
    const r = [...t.stack, e.followState];
    return {
      state: e.target,
      alt: t.alt,
      stack: r
    };
  }
}
function _g(t) {
  for (const e of t.elements)
    if (e.state.type !== cs)
      return !1;
  return !0;
}
function Ig(t) {
  if (_g(t))
    return !0;
  const e = Pg(t.elements);
  return Og(e) && !Lg(e);
}
function Pg(t) {
  const e = /* @__PURE__ */ new Map();
  for (const r of t) {
    const n = id(r, !1);
    let i = e.get(n);
    i === void 0 && (i = {}, e.set(n, i)), i[r.alt] = !0;
  }
  return e;
}
function Og(t) {
  for (const e of Array.from(t.values()))
    if (Object.keys(e).length > 1)
      return !0;
  return !1;
}
function Lg(t) {
  for (const e of Array.from(t.values()))
    if (Object.keys(e).length === 1)
      return !0;
  return !1;
}
var uo;
(function(t) {
  function e(r) {
    return typeof r == "string";
  }
  t.is = e;
})(uo || (uo = {}));
var qa;
(function(t) {
  function e(r) {
    return typeof r == "string";
  }
  t.is = e;
})(qa || (qa = {}));
var fo;
(function(t) {
  t.MIN_VALUE = -2147483648, t.MAX_VALUE = 2147483647;
  function e(r) {
    return typeof r == "number" && t.MIN_VALUE <= r && r <= t.MAX_VALUE;
  }
  t.is = e;
})(fo || (fo = {}));
var fi;
(function(t) {
  t.MIN_VALUE = 0, t.MAX_VALUE = 2147483647;
  function e(r) {
    return typeof r == "number" && t.MIN_VALUE <= r && r <= t.MAX_VALUE;
  }
  t.is = e;
})(fi || (fi = {}));
var Z;
(function(t) {
  function e(n, i) {
    return n === Number.MAX_VALUE && (n = fi.MAX_VALUE), i === Number.MAX_VALUE && (i = fi.MAX_VALUE), { line: n, character: i };
  }
  t.create = e;
  function r(n) {
    let i = n;
    return v.objectLiteral(i) && v.uinteger(i.line) && v.uinteger(i.character);
  }
  t.is = r;
})(Z || (Z = {}));
var V;
(function(t) {
  function e(n, i, a, s) {
    if (v.uinteger(n) && v.uinteger(i) && v.uinteger(a) && v.uinteger(s))
      return { start: Z.create(n, i), end: Z.create(a, s) };
    if (Z.is(n) && Z.is(i))
      return { start: n, end: i };
    throw new Error(`Range#create called with invalid arguments[${n}, ${i}, ${a}, ${s}]`);
  }
  t.create = e;
  function r(n) {
    let i = n;
    return v.objectLiteral(i) && Z.is(i.start) && Z.is(i.end);
  }
  t.is = r;
})(V || (V = {}));
var di;
(function(t) {
  function e(n, i) {
    return { uri: n, range: i };
  }
  t.create = e;
  function r(n) {
    let i = n;
    return v.objectLiteral(i) && V.is(i.range) && (v.string(i.uri) || v.undefined(i.uri));
  }
  t.is = r;
})(di || (di = {}));
var ho;
(function(t) {
  function e(n, i, a, s) {
    return { targetUri: n, targetRange: i, targetSelectionRange: a, originSelectionRange: s };
  }
  t.create = e;
  function r(n) {
    let i = n;
    return v.objectLiteral(i) && V.is(i.targetRange) && v.string(i.targetUri) && V.is(i.targetSelectionRange) && (V.is(i.originSelectionRange) || v.undefined(i.originSelectionRange));
  }
  t.is = r;
})(ho || (ho = {}));
var Ba;
(function(t) {
  function e(n, i, a, s) {
    return {
      red: n,
      green: i,
      blue: a,
      alpha: s
    };
  }
  t.create = e;
  function r(n) {
    const i = n;
    return v.objectLiteral(i) && v.numberRange(i.red, 0, 1) && v.numberRange(i.green, 0, 1) && v.numberRange(i.blue, 0, 1) && v.numberRange(i.alpha, 0, 1);
  }
  t.is = r;
})(Ba || (Ba = {}));
var po;
(function(t) {
  function e(n, i) {
    return {
      range: n,
      color: i
    };
  }
  t.create = e;
  function r(n) {
    const i = n;
    return v.objectLiteral(i) && V.is(i.range) && Ba.is(i.color);
  }
  t.is = r;
})(po || (po = {}));
var mo;
(function(t) {
  function e(n, i, a) {
    return {
      label: n,
      textEdit: i,
      additionalTextEdits: a
    };
  }
  t.create = e;
  function r(n) {
    const i = n;
    return v.objectLiteral(i) && v.string(i.label) && (v.undefined(i.textEdit) || yt.is(i)) && (v.undefined(i.additionalTextEdits) || v.typedArray(i.additionalTextEdits, yt.is));
  }
  t.is = r;
})(mo || (mo = {}));
var go;
(function(t) {
  t.Comment = "comment", t.Imports = "imports", t.Region = "region";
})(go || (go = {}));
var yo;
(function(t) {
  function e(n, i, a, s, o, l) {
    const c = {
      startLine: n,
      endLine: i
    };
    return v.defined(a) && (c.startCharacter = a), v.defined(s) && (c.endCharacter = s), v.defined(o) && (c.kind = o), v.defined(l) && (c.collapsedText = l), c;
  }
  t.create = e;
  function r(n) {
    const i = n;
    return v.objectLiteral(i) && v.uinteger(i.startLine) && v.uinteger(i.startLine) && (v.undefined(i.startCharacter) || v.uinteger(i.startCharacter)) && (v.undefined(i.endCharacter) || v.uinteger(i.endCharacter)) && (v.undefined(i.kind) || v.string(i.kind));
  }
  t.is = r;
})(yo || (yo = {}));
var Wa;
(function(t) {
  function e(n, i) {
    return {
      location: n,
      message: i
    };
  }
  t.create = e;
  function r(n) {
    let i = n;
    return v.defined(i) && di.is(i.location) && v.string(i.message);
  }
  t.is = r;
})(Wa || (Wa = {}));
var To;
(function(t) {
  t.Error = 1, t.Warning = 2, t.Information = 3, t.Hint = 4;
})(To || (To = {}));
var Ro;
(function(t) {
  t.Unnecessary = 1, t.Deprecated = 2;
})(Ro || (Ro = {}));
var vo;
(function(t) {
  function e(r) {
    const n = r;
    return v.objectLiteral(n) && v.string(n.href);
  }
  t.is = e;
})(vo || (vo = {}));
var hi;
(function(t) {
  function e(n, i, a, s, o, l) {
    let c = { range: n, message: i };
    return v.defined(a) && (c.severity = a), v.defined(s) && (c.code = s), v.defined(o) && (c.source = o), v.defined(l) && (c.relatedInformation = l), c;
  }
  t.create = e;
  function r(n) {
    var i;
    let a = n;
    return v.defined(a) && V.is(a.range) && v.string(a.message) && (v.number(a.severity) || v.undefined(a.severity)) && (v.integer(a.code) || v.string(a.code) || v.undefined(a.code)) && (v.undefined(a.codeDescription) || v.string((i = a.codeDescription) === null || i === void 0 ? void 0 : i.href)) && (v.string(a.source) || v.undefined(a.source)) && (v.undefined(a.relatedInformation) || v.typedArray(a.relatedInformation, Wa.is));
  }
  t.is = r;
})(hi || (hi = {}));
var _r;
(function(t) {
  function e(n, i, ...a) {
    let s = { title: n, command: i };
    return v.defined(a) && a.length > 0 && (s.arguments = a), s;
  }
  t.create = e;
  function r(n) {
    let i = n;
    return v.defined(i) && v.string(i.title) && v.string(i.command);
  }
  t.is = r;
})(_r || (_r = {}));
var yt;
(function(t) {
  function e(a, s) {
    return { range: a, newText: s };
  }
  t.replace = e;
  function r(a, s) {
    return { range: { start: a, end: a }, newText: s };
  }
  t.insert = r;
  function n(a) {
    return { range: a, newText: "" };
  }
  t.del = n;
  function i(a) {
    const s = a;
    return v.objectLiteral(s) && v.string(s.newText) && V.is(s.range);
  }
  t.is = i;
})(yt || (yt = {}));
var Sr;
(function(t) {
  function e(n, i, a) {
    const s = { label: n };
    return i !== void 0 && (s.needsConfirmation = i), a !== void 0 && (s.description = a), s;
  }
  t.create = e;
  function r(n) {
    const i = n;
    return v.objectLiteral(i) && v.string(i.label) && (v.boolean(i.needsConfirmation) || i.needsConfirmation === void 0) && (v.string(i.description) || i.description === void 0);
  }
  t.is = r;
})(Sr || (Sr = {}));
var De;
(function(t) {
  function e(r) {
    const n = r;
    return v.string(n);
  }
  t.is = e;
})(De || (De = {}));
var Mt;
(function(t) {
  function e(a, s, o) {
    return { range: a, newText: s, annotationId: o };
  }
  t.replace = e;
  function r(a, s, o) {
    return { range: { start: a, end: a }, newText: s, annotationId: o };
  }
  t.insert = r;
  function n(a, s) {
    return { range: a, newText: "", annotationId: s };
  }
  t.del = n;
  function i(a) {
    const s = a;
    return yt.is(s) && (Sr.is(s.annotationId) || De.is(s.annotationId));
  }
  t.is = i;
})(Mt || (Mt = {}));
var pi;
(function(t) {
  function e(n, i) {
    return { textDocument: n, edits: i };
  }
  t.create = e;
  function r(n) {
    let i = n;
    return v.defined(i) && mi.is(i.textDocument) && Array.isArray(i.edits);
  }
  t.is = r;
})(pi || (pi = {}));
var on;
(function(t) {
  function e(n, i, a) {
    let s = {
      kind: "create",
      uri: n
    };
    return i !== void 0 && (i.overwrite !== void 0 || i.ignoreIfExists !== void 0) && (s.options = i), a !== void 0 && (s.annotationId = a), s;
  }
  t.create = e;
  function r(n) {
    let i = n;
    return i && i.kind === "create" && v.string(i.uri) && (i.options === void 0 || (i.options.overwrite === void 0 || v.boolean(i.options.overwrite)) && (i.options.ignoreIfExists === void 0 || v.boolean(i.options.ignoreIfExists))) && (i.annotationId === void 0 || De.is(i.annotationId));
  }
  t.is = r;
})(on || (on = {}));
var ln;
(function(t) {
  function e(n, i, a, s) {
    let o = {
      kind: "rename",
      oldUri: n,
      newUri: i
    };
    return a !== void 0 && (a.overwrite !== void 0 || a.ignoreIfExists !== void 0) && (o.options = a), s !== void 0 && (o.annotationId = s), o;
  }
  t.create = e;
  function r(n) {
    let i = n;
    return i && i.kind === "rename" && v.string(i.oldUri) && v.string(i.newUri) && (i.options === void 0 || (i.options.overwrite === void 0 || v.boolean(i.options.overwrite)) && (i.options.ignoreIfExists === void 0 || v.boolean(i.options.ignoreIfExists))) && (i.annotationId === void 0 || De.is(i.annotationId));
  }
  t.is = r;
})(ln || (ln = {}));
var cn;
(function(t) {
  function e(n, i, a) {
    let s = {
      kind: "delete",
      uri: n
    };
    return i !== void 0 && (i.recursive !== void 0 || i.ignoreIfNotExists !== void 0) && (s.options = i), a !== void 0 && (s.annotationId = a), s;
  }
  t.create = e;
  function r(n) {
    let i = n;
    return i && i.kind === "delete" && v.string(i.uri) && (i.options === void 0 || (i.options.recursive === void 0 || v.boolean(i.options.recursive)) && (i.options.ignoreIfNotExists === void 0 || v.boolean(i.options.ignoreIfNotExists))) && (i.annotationId === void 0 || De.is(i.annotationId));
  }
  t.is = r;
})(cn || (cn = {}));
var Ka;
(function(t) {
  function e(r) {
    let n = r;
    return n && (n.changes !== void 0 || n.documentChanges !== void 0) && (n.documentChanges === void 0 || n.documentChanges.every((i) => v.string(i.kind) ? on.is(i) || ln.is(i) || cn.is(i) : pi.is(i)));
  }
  t.is = e;
})(Ka || (Ka = {}));
class ea {
  constructor(e, r) {
    this.edits = e, this.changeAnnotations = r;
  }
  insert(e, r, n) {
    let i, a;
    if (n === void 0 ? i = yt.insert(e, r) : De.is(n) ? (a = n, i = Mt.insert(e, r, n)) : (this.assertChangeAnnotations(this.changeAnnotations), a = this.changeAnnotations.manage(n), i = Mt.insert(e, r, a)), this.edits.push(i), a !== void 0)
      return a;
  }
  replace(e, r, n) {
    let i, a;
    if (n === void 0 ? i = yt.replace(e, r) : De.is(n) ? (a = n, i = Mt.replace(e, r, n)) : (this.assertChangeAnnotations(this.changeAnnotations), a = this.changeAnnotations.manage(n), i = Mt.replace(e, r, a)), this.edits.push(i), a !== void 0)
      return a;
  }
  delete(e, r) {
    let n, i;
    if (r === void 0 ? n = yt.del(e) : De.is(r) ? (i = r, n = Mt.del(e, r)) : (this.assertChangeAnnotations(this.changeAnnotations), i = this.changeAnnotations.manage(r), n = Mt.del(e, i)), this.edits.push(n), i !== void 0)
      return i;
  }
  add(e) {
    this.edits.push(e);
  }
  all() {
    return this.edits;
  }
  clear() {
    this.edits.splice(0, this.edits.length);
  }
  assertChangeAnnotations(e) {
    if (e === void 0)
      throw new Error("Text edit change is not configured to manage change annotations.");
  }
}
class Mc {
  constructor(e) {
    this._annotations = e === void 0 ? /* @__PURE__ */ Object.create(null) : e, this._counter = 0, this._size = 0;
  }
  all() {
    return this._annotations;
  }
  get size() {
    return this._size;
  }
  manage(e, r) {
    let n;
    if (De.is(e) ? n = e : (n = this.nextId(), r = e), this._annotations[n] !== void 0)
      throw new Error(`Id ${n} is already in use.`);
    if (r === void 0)
      throw new Error(`No annotation provided for id ${n}`);
    return this._annotations[n] = r, this._size++, n;
  }
  nextId() {
    return this._counter++, this._counter.toString();
  }
}
class xg {
  constructor(e) {
    this._textEditChanges = /* @__PURE__ */ Object.create(null), e !== void 0 ? (this._workspaceEdit = e, e.documentChanges ? (this._changeAnnotations = new Mc(e.changeAnnotations), e.changeAnnotations = this._changeAnnotations.all(), e.documentChanges.forEach((r) => {
      if (pi.is(r)) {
        const n = new ea(r.edits, this._changeAnnotations);
        this._textEditChanges[r.textDocument.uri] = n;
      }
    })) : e.changes && Object.keys(e.changes).forEach((r) => {
      const n = new ea(e.changes[r]);
      this._textEditChanges[r] = n;
    })) : this._workspaceEdit = {};
  }
  /**
   * Returns the underlying {@link WorkspaceEdit} literal
   * use to be returned from a workspace edit operation like rename.
   */
  get edit() {
    return this.initDocumentChanges(), this._changeAnnotations !== void 0 && (this._changeAnnotations.size === 0 ? this._workspaceEdit.changeAnnotations = void 0 : this._workspaceEdit.changeAnnotations = this._changeAnnotations.all()), this._workspaceEdit;
  }
  getTextEditChange(e) {
    if (mi.is(e)) {
      if (this.initDocumentChanges(), this._workspaceEdit.documentChanges === void 0)
        throw new Error("Workspace edit is not configured for document changes.");
      const r = { uri: e.uri, version: e.version };
      let n = this._textEditChanges[r.uri];
      if (!n) {
        const i = [], a = {
          textDocument: r,
          edits: i
        };
        this._workspaceEdit.documentChanges.push(a), n = new ea(i, this._changeAnnotations), this._textEditChanges[r.uri] = n;
      }
      return n;
    } else {
      if (this.initChanges(), this._workspaceEdit.changes === void 0)
        throw new Error("Workspace edit is not configured for normal text edit changes.");
      let r = this._textEditChanges[e];
      if (!r) {
        let n = [];
        this._workspaceEdit.changes[e] = n, r = new ea(n), this._textEditChanges[e] = r;
      }
      return r;
    }
  }
  initDocumentChanges() {
    this._workspaceEdit.documentChanges === void 0 && this._workspaceEdit.changes === void 0 && (this._changeAnnotations = new Mc(), this._workspaceEdit.documentChanges = [], this._workspaceEdit.changeAnnotations = this._changeAnnotations.all());
  }
  initChanges() {
    this._workspaceEdit.documentChanges === void 0 && this._workspaceEdit.changes === void 0 && (this._workspaceEdit.changes = /* @__PURE__ */ Object.create(null));
  }
  createFile(e, r, n) {
    if (this.initDocumentChanges(), this._workspaceEdit.documentChanges === void 0)
      throw new Error("Workspace edit is not configured for document changes.");
    let i;
    Sr.is(r) || De.is(r) ? i = r : n = r;
    let a, s;
    if (i === void 0 ? a = on.create(e, n) : (s = De.is(i) ? i : this._changeAnnotations.manage(i), a = on.create(e, n, s)), this._workspaceEdit.documentChanges.push(a), s !== void 0)
      return s;
  }
  renameFile(e, r, n, i) {
    if (this.initDocumentChanges(), this._workspaceEdit.documentChanges === void 0)
      throw new Error("Workspace edit is not configured for document changes.");
    let a;
    Sr.is(n) || De.is(n) ? a = n : i = n;
    let s, o;
    if (a === void 0 ? s = ln.create(e, r, i) : (o = De.is(a) ? a : this._changeAnnotations.manage(a), s = ln.create(e, r, i, o)), this._workspaceEdit.documentChanges.push(s), o !== void 0)
      return o;
  }
  deleteFile(e, r, n) {
    if (this.initDocumentChanges(), this._workspaceEdit.documentChanges === void 0)
      throw new Error("Workspace edit is not configured for document changes.");
    let i;
    Sr.is(r) || De.is(r) ? i = r : n = r;
    let a, s;
    if (i === void 0 ? a = cn.create(e, n) : (s = De.is(i) ? i : this._changeAnnotations.manage(i), a = cn.create(e, n, s)), this._workspaceEdit.documentChanges.push(a), s !== void 0)
      return s;
  }
}
var Eo;
(function(t) {
  function e(n) {
    return { uri: n };
  }
  t.create = e;
  function r(n) {
    let i = n;
    return v.defined(i) && v.string(i.uri);
  }
  t.is = r;
})(Eo || (Eo = {}));
var Ao;
(function(t) {
  function e(n, i) {
    return { uri: n, version: i };
  }
  t.create = e;
  function r(n) {
    let i = n;
    return v.defined(i) && v.string(i.uri) && v.integer(i.version);
  }
  t.is = r;
})(Ao || (Ao = {}));
var mi;
(function(t) {
  function e(n, i) {
    return { uri: n, version: i };
  }
  t.create = e;
  function r(n) {
    let i = n;
    return v.defined(i) && v.string(i.uri) && (i.version === null || v.integer(i.version));
  }
  t.is = r;
})(mi || (mi = {}));
var $o;
(function(t) {
  function e(n, i, a, s) {
    return { uri: n, languageId: i, version: a, text: s };
  }
  t.create = e;
  function r(n) {
    let i = n;
    return v.defined(i) && v.string(i.uri) && v.string(i.languageId) && v.integer(i.version) && v.string(i.text);
  }
  t.is = r;
})($o || ($o = {}));
var Va;
(function(t) {
  t.PlainText = "plaintext", t.Markdown = "markdown";
  function e(r) {
    const n = r;
    return n === t.PlainText || n === t.Markdown;
  }
  t.is = e;
})(Va || (Va = {}));
var un;
(function(t) {
  function e(r) {
    const n = r;
    return v.objectLiteral(r) && Va.is(n.kind) && v.string(n.value);
  }
  t.is = e;
})(un || (un = {}));
var Co;
(function(t) {
  t.Text = 1, t.Method = 2, t.Function = 3, t.Constructor = 4, t.Field = 5, t.Variable = 6, t.Class = 7, t.Interface = 8, t.Module = 9, t.Property = 10, t.Unit = 11, t.Value = 12, t.Enum = 13, t.Keyword = 14, t.Snippet = 15, t.Color = 16, t.File = 17, t.Reference = 18, t.Folder = 19, t.EnumMember = 20, t.Constant = 21, t.Struct = 22, t.Event = 23, t.Operator = 24, t.TypeParameter = 25;
})(Co || (Co = {}));
var So;
(function(t) {
  t.PlainText = 1, t.Snippet = 2;
})(So || (So = {}));
var ko;
(function(t) {
  t.Deprecated = 1;
})(ko || (ko = {}));
var wo;
(function(t) {
  function e(n, i, a) {
    return { newText: n, insert: i, replace: a };
  }
  t.create = e;
  function r(n) {
    const i = n;
    return i && v.string(i.newText) && V.is(i.insert) && V.is(i.replace);
  }
  t.is = r;
})(wo || (wo = {}));
var bo;
(function(t) {
  t.asIs = 1, t.adjustIndentation = 2;
})(bo || (bo = {}));
var No;
(function(t) {
  function e(r) {
    const n = r;
    return n && (v.string(n.detail) || n.detail === void 0) && (v.string(n.description) || n.description === void 0);
  }
  t.is = e;
})(No || (No = {}));
var _o;
(function(t) {
  function e(r) {
    return { label: r };
  }
  t.create = e;
})(_o || (_o = {}));
var Io;
(function(t) {
  function e(r, n) {
    return { items: r || [], isIncomplete: !!n };
  }
  t.create = e;
})(Io || (Io = {}));
var gi;
(function(t) {
  function e(n) {
    return n.replace(/[\\`*_{}[\]()#+\-.!]/g, "\\$&");
  }
  t.fromPlainText = e;
  function r(n) {
    const i = n;
    return v.string(i) || v.objectLiteral(i) && v.string(i.language) && v.string(i.value);
  }
  t.is = r;
})(gi || (gi = {}));
var Po;
(function(t) {
  function e(r) {
    let n = r;
    return !!n && v.objectLiteral(n) && (un.is(n.contents) || gi.is(n.contents) || v.typedArray(n.contents, gi.is)) && (r.range === void 0 || V.is(r.range));
  }
  t.is = e;
})(Po || (Po = {}));
var Oo;
(function(t) {
  function e(r, n) {
    return n ? { label: r, documentation: n } : { label: r };
  }
  t.create = e;
})(Oo || (Oo = {}));
var Lo;
(function(t) {
  function e(r, n, ...i) {
    let a = { label: r };
    return v.defined(n) && (a.documentation = n), v.defined(i) ? a.parameters = i : a.parameters = [], a;
  }
  t.create = e;
})(Lo || (Lo = {}));
var xo;
(function(t) {
  t.Text = 1, t.Read = 2, t.Write = 3;
})(xo || (xo = {}));
var Do;
(function(t) {
  function e(r, n) {
    let i = { range: r };
    return v.number(n) && (i.kind = n), i;
  }
  t.create = e;
})(Do || (Do = {}));
var Mo;
(function(t) {
  t.File = 1, t.Module = 2, t.Namespace = 3, t.Package = 4, t.Class = 5, t.Method = 6, t.Property = 7, t.Field = 8, t.Constructor = 9, t.Enum = 10, t.Interface = 11, t.Function = 12, t.Variable = 13, t.Constant = 14, t.String = 15, t.Number = 16, t.Boolean = 17, t.Array = 18, t.Object = 19, t.Key = 20, t.Null = 21, t.EnumMember = 22, t.Struct = 23, t.Event = 24, t.Operator = 25, t.TypeParameter = 26;
})(Mo || (Mo = {}));
var Fo;
(function(t) {
  t.Deprecated = 1;
})(Fo || (Fo = {}));
var Go;
(function(t) {
  function e(r, n, i, a, s) {
    let o = {
      name: r,
      kind: n,
      location: { uri: a, range: i }
    };
    return s && (o.containerName = s), o;
  }
  t.create = e;
})(Go || (Go = {}));
var jo;
(function(t) {
  function e(r, n, i, a) {
    return a !== void 0 ? { name: r, kind: n, location: { uri: i, range: a } } : { name: r, kind: n, location: { uri: i } };
  }
  t.create = e;
})(jo || (jo = {}));
var zo;
(function(t) {
  function e(n, i, a, s, o, l) {
    let c = {
      name: n,
      detail: i,
      kind: a,
      range: s,
      selectionRange: o
    };
    return l !== void 0 && (c.children = l), c;
  }
  t.create = e;
  function r(n) {
    let i = n;
    return i && v.string(i.name) && v.number(i.kind) && V.is(i.range) && V.is(i.selectionRange) && (i.detail === void 0 || v.string(i.detail)) && (i.deprecated === void 0 || v.boolean(i.deprecated)) && (i.children === void 0 || Array.isArray(i.children)) && (i.tags === void 0 || Array.isArray(i.tags));
  }
  t.is = r;
})(zo || (zo = {}));
var Uo;
(function(t) {
  t.Empty = "", t.QuickFix = "quickfix", t.Refactor = "refactor", t.RefactorExtract = "refactor.extract", t.RefactorInline = "refactor.inline", t.RefactorRewrite = "refactor.rewrite", t.Source = "source", t.SourceOrganizeImports = "source.organizeImports", t.SourceFixAll = "source.fixAll";
})(Uo || (Uo = {}));
var yi;
(function(t) {
  t.Invoked = 1, t.Automatic = 2;
})(yi || (yi = {}));
var qo;
(function(t) {
  function e(n, i, a) {
    let s = { diagnostics: n };
    return i != null && (s.only = i), a != null && (s.triggerKind = a), s;
  }
  t.create = e;
  function r(n) {
    let i = n;
    return v.defined(i) && v.typedArray(i.diagnostics, hi.is) && (i.only === void 0 || v.typedArray(i.only, v.string)) && (i.triggerKind === void 0 || i.triggerKind === yi.Invoked || i.triggerKind === yi.Automatic);
  }
  t.is = r;
})(qo || (qo = {}));
var Bo;
(function(t) {
  function e(n, i, a) {
    let s = { title: n }, o = !0;
    return typeof i == "string" ? (o = !1, s.kind = i) : _r.is(i) ? s.command = i : s.edit = i, o && a !== void 0 && (s.kind = a), s;
  }
  t.create = e;
  function r(n) {
    let i = n;
    return i && v.string(i.title) && (i.diagnostics === void 0 || v.typedArray(i.diagnostics, hi.is)) && (i.kind === void 0 || v.string(i.kind)) && (i.edit !== void 0 || i.command !== void 0) && (i.command === void 0 || _r.is(i.command)) && (i.isPreferred === void 0 || v.boolean(i.isPreferred)) && (i.edit === void 0 || Ka.is(i.edit));
  }
  t.is = r;
})(Bo || (Bo = {}));
var Wo;
(function(t) {
  function e(n, i) {
    let a = { range: n };
    return v.defined(i) && (a.data = i), a;
  }
  t.create = e;
  function r(n) {
    let i = n;
    return v.defined(i) && V.is(i.range) && (v.undefined(i.command) || _r.is(i.command));
  }
  t.is = r;
})(Wo || (Wo = {}));
var Ko;
(function(t) {
  function e(n, i) {
    return { tabSize: n, insertSpaces: i };
  }
  t.create = e;
  function r(n) {
    let i = n;
    return v.defined(i) && v.uinteger(i.tabSize) && v.boolean(i.insertSpaces);
  }
  t.is = r;
})(Ko || (Ko = {}));
var Vo;
(function(t) {
  function e(n, i, a) {
    return { range: n, target: i, data: a };
  }
  t.create = e;
  function r(n) {
    let i = n;
    return v.defined(i) && V.is(i.range) && (v.undefined(i.target) || v.string(i.target));
  }
  t.is = r;
})(Vo || (Vo = {}));
var Ho;
(function(t) {
  function e(n, i) {
    return { range: n, parent: i };
  }
  t.create = e;
  function r(n) {
    let i = n;
    return v.objectLiteral(i) && V.is(i.range) && (i.parent === void 0 || t.is(i.parent));
  }
  t.is = r;
})(Ho || (Ho = {}));
var Xo;
(function(t) {
  t.namespace = "namespace", t.type = "type", t.class = "class", t.enum = "enum", t.interface = "interface", t.struct = "struct", t.typeParameter = "typeParameter", t.parameter = "parameter", t.variable = "variable", t.property = "property", t.enumMember = "enumMember", t.event = "event", t.function = "function", t.method = "method", t.macro = "macro", t.keyword = "keyword", t.modifier = "modifier", t.comment = "comment", t.string = "string", t.number = "number", t.regexp = "regexp", t.operator = "operator", t.decorator = "decorator";
})(Xo || (Xo = {}));
var Yo;
(function(t) {
  t.declaration = "declaration", t.definition = "definition", t.readonly = "readonly", t.static = "static", t.deprecated = "deprecated", t.abstract = "abstract", t.async = "async", t.modification = "modification", t.documentation = "documentation", t.defaultLibrary = "defaultLibrary";
})(Yo || (Yo = {}));
var Jo;
(function(t) {
  function e(r) {
    const n = r;
    return v.objectLiteral(n) && (n.resultId === void 0 || typeof n.resultId == "string") && Array.isArray(n.data) && (n.data.length === 0 || typeof n.data[0] == "number");
  }
  t.is = e;
})(Jo || (Jo = {}));
var Zo;
(function(t) {
  function e(n, i) {
    return { range: n, text: i };
  }
  t.create = e;
  function r(n) {
    const i = n;
    return i != null && V.is(i.range) && v.string(i.text);
  }
  t.is = r;
})(Zo || (Zo = {}));
var Qo;
(function(t) {
  function e(n, i, a) {
    return { range: n, variableName: i, caseSensitiveLookup: a };
  }
  t.create = e;
  function r(n) {
    const i = n;
    return i != null && V.is(i.range) && v.boolean(i.caseSensitiveLookup) && (v.string(i.variableName) || i.variableName === void 0);
  }
  t.is = r;
})(Qo || (Qo = {}));
var el;
(function(t) {
  function e(n, i) {
    return { range: n, expression: i };
  }
  t.create = e;
  function r(n) {
    const i = n;
    return i != null && V.is(i.range) && (v.string(i.expression) || i.expression === void 0);
  }
  t.is = r;
})(el || (el = {}));
var tl;
(function(t) {
  function e(n, i) {
    return { frameId: n, stoppedLocation: i };
  }
  t.create = e;
  function r(n) {
    const i = n;
    return v.defined(i) && V.is(n.stoppedLocation);
  }
  t.is = r;
})(tl || (tl = {}));
var Ha;
(function(t) {
  t.Type = 1, t.Parameter = 2;
  function e(r) {
    return r === 1 || r === 2;
  }
  t.is = e;
})(Ha || (Ha = {}));
var Xa;
(function(t) {
  function e(n) {
    return { value: n };
  }
  t.create = e;
  function r(n) {
    const i = n;
    return v.objectLiteral(i) && (i.tooltip === void 0 || v.string(i.tooltip) || un.is(i.tooltip)) && (i.location === void 0 || di.is(i.location)) && (i.command === void 0 || _r.is(i.command));
  }
  t.is = r;
})(Xa || (Xa = {}));
var rl;
(function(t) {
  function e(n, i, a) {
    const s = { position: n, label: i };
    return a !== void 0 && (s.kind = a), s;
  }
  t.create = e;
  function r(n) {
    const i = n;
    return v.objectLiteral(i) && Z.is(i.position) && (v.string(i.label) || v.typedArray(i.label, Xa.is)) && (i.kind === void 0 || Ha.is(i.kind)) && i.textEdits === void 0 || v.typedArray(i.textEdits, yt.is) && (i.tooltip === void 0 || v.string(i.tooltip) || un.is(i.tooltip)) && (i.paddingLeft === void 0 || v.boolean(i.paddingLeft)) && (i.paddingRight === void 0 || v.boolean(i.paddingRight));
  }
  t.is = r;
})(rl || (rl = {}));
var nl;
(function(t) {
  function e(r) {
    return { kind: "snippet", value: r };
  }
  t.createSnippet = e;
})(nl || (nl = {}));
var il;
(function(t) {
  function e(r, n, i, a) {
    return { insertText: r, filterText: n, range: i, command: a };
  }
  t.create = e;
})(il || (il = {}));
var al;
(function(t) {
  function e(r) {
    return { items: r };
  }
  t.create = e;
})(al || (al = {}));
var sl;
(function(t) {
  t.Invoked = 0, t.Automatic = 1;
})(sl || (sl = {}));
var ol;
(function(t) {
  function e(r, n) {
    return { range: r, text: n };
  }
  t.create = e;
})(ol || (ol = {}));
var ll;
(function(t) {
  function e(r, n) {
    return { triggerKind: r, selectedCompletionInfo: n };
  }
  t.create = e;
})(ll || (ll = {}));
var cl;
(function(t) {
  function e(r) {
    const n = r;
    return v.objectLiteral(n) && qa.is(n.uri) && v.string(n.name);
  }
  t.is = e;
})(cl || (cl = {}));
const Dg = [`
`, `\r
`, "\r"];
var ul;
(function(t) {
  function e(a, s, o, l) {
    return new Mg(a, s, o, l);
  }
  t.create = e;
  function r(a) {
    let s = a;
    return !!(v.defined(s) && v.string(s.uri) && (v.undefined(s.languageId) || v.string(s.languageId)) && v.uinteger(s.lineCount) && v.func(s.getText) && v.func(s.positionAt) && v.func(s.offsetAt));
  }
  t.is = r;
  function n(a, s) {
    let o = a.getText(), l = i(s, (u, d) => {
      let p = u.range.start.line - d.range.start.line;
      return p === 0 ? u.range.start.character - d.range.start.character : p;
    }), c = o.length;
    for (let u = l.length - 1; u >= 0; u--) {
      let d = l[u], p = a.offsetAt(d.range.start), m = a.offsetAt(d.range.end);
      if (m <= c)
        o = o.substring(0, p) + d.newText + o.substring(m, o.length);
      else
        throw new Error("Overlapping edit");
      c = p;
    }
    return o;
  }
  t.applyEdits = n;
  function i(a, s) {
    if (a.length <= 1)
      return a;
    const o = a.length / 2 | 0, l = a.slice(0, o), c = a.slice(o);
    i(l, s), i(c, s);
    let u = 0, d = 0, p = 0;
    for (; u < l.length && d < c.length; )
      s(l[u], c[d]) <= 0 ? a[p++] = l[u++] : a[p++] = c[d++];
    for (; u < l.length; )
      a[p++] = l[u++];
    for (; d < c.length; )
      a[p++] = c[d++];
    return a;
  }
})(ul || (ul = {}));
let Mg = class {
  constructor(e, r, n, i) {
    this._uri = e, this._languageId = r, this._version = n, this._content = i, this._lineOffsets = void 0;
  }
  get uri() {
    return this._uri;
  }
  get languageId() {
    return this._languageId;
  }
  get version() {
    return this._version;
  }
  getText(e) {
    if (e) {
      let r = this.offsetAt(e.start), n = this.offsetAt(e.end);
      return this._content.substring(r, n);
    }
    return this._content;
  }
  update(e, r) {
    this._content = e.text, this._version = r, this._lineOffsets = void 0;
  }
  getLineOffsets() {
    if (this._lineOffsets === void 0) {
      let e = [], r = this._content, n = !0;
      for (let i = 0; i < r.length; i++) {
        n && (e.push(i), n = !1);
        let a = r.charAt(i);
        n = a === "\r" || a === `
`, a === "\r" && i + 1 < r.length && r.charAt(i + 1) === `
` && i++;
      }
      n && r.length > 0 && e.push(r.length), this._lineOffsets = e;
    }
    return this._lineOffsets;
  }
  positionAt(e) {
    e = Math.max(Math.min(e, this._content.length), 0);
    let r = this.getLineOffsets(), n = 0, i = r.length;
    if (i === 0)
      return Z.create(0, e);
    for (; n < i; ) {
      let s = Math.floor((n + i) / 2);
      r[s] > e ? i = s : n = s + 1;
    }
    let a = n - 1;
    return Z.create(a, e - r[a]);
  }
  offsetAt(e) {
    let r = this.getLineOffsets();
    if (e.line >= r.length)
      return this._content.length;
    if (e.line < 0)
      return 0;
    let n = r[e.line], i = e.line + 1 < r.length ? r[e.line + 1] : this._content.length;
    return Math.max(Math.min(n + e.character, i), n);
  }
  get lineCount() {
    return this.getLineOffsets().length;
  }
};
var v;
(function(t) {
  const e = Object.prototype.toString;
  function r(m) {
    return typeof m < "u";
  }
  t.defined = r;
  function n(m) {
    return typeof m > "u";
  }
  t.undefined = n;
  function i(m) {
    return m === !0 || m === !1;
  }
  t.boolean = i;
  function a(m) {
    return e.call(m) === "[object String]";
  }
  t.string = a;
  function s(m) {
    return e.call(m) === "[object Number]";
  }
  t.number = s;
  function o(m, A, b) {
    return e.call(m) === "[object Number]" && A <= m && m <= b;
  }
  t.numberRange = o;
  function l(m) {
    return e.call(m) === "[object Number]" && -2147483648 <= m && m <= 2147483647;
  }
  t.integer = l;
  function c(m) {
    return e.call(m) === "[object Number]" && 0 <= m && m <= 2147483647;
  }
  t.uinteger = c;
  function u(m) {
    return e.call(m) === "[object Function]";
  }
  t.func = u;
  function d(m) {
    return m !== null && typeof m == "object";
  }
  t.objectLiteral = d;
  function p(m, A) {
    return Array.isArray(m) && m.every(A);
  }
  t.typedArray = p;
})(v || (v = {}));
const Fg = /* @__PURE__ */ Object.freeze(/* @__PURE__ */ Object.defineProperty({
  __proto__: null,
  get AnnotatedTextEdit() {
    return Mt;
  },
  get ChangeAnnotation() {
    return Sr;
  },
  get ChangeAnnotationIdentifier() {
    return De;
  },
  get CodeAction() {
    return Bo;
  },
  get CodeActionContext() {
    return qo;
  },
  get CodeActionKind() {
    return Uo;
  },
  get CodeActionTriggerKind() {
    return yi;
  },
  get CodeDescription() {
    return vo;
  },
  get CodeLens() {
    return Wo;
  },
  get Color() {
    return Ba;
  },
  get ColorInformation() {
    return po;
  },
  get ColorPresentation() {
    return mo;
  },
  get Command() {
    return _r;
  },
  get CompletionItem() {
    return _o;
  },
  get CompletionItemKind() {
    return Co;
  },
  get CompletionItemLabelDetails() {
    return No;
  },
  get CompletionItemTag() {
    return ko;
  },
  get CompletionList() {
    return Io;
  },
  get CreateFile() {
    return on;
  },
  get DeleteFile() {
    return cn;
  },
  get Diagnostic() {
    return hi;
  },
  get DiagnosticRelatedInformation() {
    return Wa;
  },
  get DiagnosticSeverity() {
    return To;
  },
  get DiagnosticTag() {
    return Ro;
  },
  get DocumentHighlight() {
    return Do;
  },
  get DocumentHighlightKind() {
    return xo;
  },
  get DocumentLink() {
    return Vo;
  },
  get DocumentSymbol() {
    return zo;
  },
  get DocumentUri() {
    return uo;
  },
  EOL: Dg,
  get FoldingRange() {
    return yo;
  },
  get FoldingRangeKind() {
    return go;
  },
  get FormattingOptions() {
    return Ko;
  },
  get Hover() {
    return Po;
  },
  get InlayHint() {
    return rl;
  },
  get InlayHintKind() {
    return Ha;
  },
  get InlayHintLabelPart() {
    return Xa;
  },
  get InlineCompletionContext() {
    return ll;
  },
  get InlineCompletionItem() {
    return il;
  },
  get InlineCompletionList() {
    return al;
  },
  get InlineCompletionTriggerKind() {
    return sl;
  },
  get InlineValueContext() {
    return tl;
  },
  get InlineValueEvaluatableExpression() {
    return el;
  },
  get InlineValueText() {
    return Zo;
  },
  get InlineValueVariableLookup() {
    return Qo;
  },
  get InsertReplaceEdit() {
    return wo;
  },
  get InsertTextFormat() {
    return So;
  },
  get InsertTextMode() {
    return bo;
  },
  get Location() {
    return di;
  },
  get LocationLink() {
    return ho;
  },
  get MarkedString() {
    return gi;
  },
  get MarkupContent() {
    return un;
  },
  get MarkupKind() {
    return Va;
  },
  get OptionalVersionedTextDocumentIdentifier() {
    return mi;
  },
  get ParameterInformation() {
    return Oo;
  },
  get Position() {
    return Z;
  },
  get Range() {
    return V;
  },
  get RenameFile() {
    return ln;
  },
  get SelectedCompletionInfo() {
    return ol;
  },
  get SelectionRange() {
    return Ho;
  },
  get SemanticTokenModifiers() {
    return Yo;
  },
  get SemanticTokenTypes() {
    return Xo;
  },
  get SemanticTokens() {
    return Jo;
  },
  get SignatureInformation() {
    return Lo;
  },
  get StringValue() {
    return nl;
  },
  get SymbolInformation() {
    return Go;
  },
  get SymbolKind() {
    return Mo;
  },
  get SymbolTag() {
    return Fo;
  },
  get TextDocument() {
    return ul;
  },
  get TextDocumentEdit() {
    return pi;
  },
  get TextDocumentIdentifier() {
    return Eo;
  },
  get TextDocumentItem() {
    return $o;
  },
  get TextEdit() {
    return yt;
  },
  get URI() {
    return qa;
  },
  get VersionedTextDocumentIdentifier() {
    return Ao;
  },
  WorkspaceChange: xg,
  get WorkspaceEdit() {
    return Ka;
  },
  get WorkspaceFolder() {
    return cl;
  },
  get WorkspaceSymbol() {
    return jo;
  },
  get integer() {
    return fo;
  },
  get uinteger() {
    return fi;
  }
}, Symbol.toStringTag, { value: "Module" }));
class Gg {
  constructor() {
    this.nodeStack = [];
  }
  get current() {
    return this.nodeStack[this.nodeStack.length - 1] ?? this.rootNode;
  }
  buildRootNode(e) {
    return this.rootNode = new cd(e), this.rootNode.root = this.rootNode, this.nodeStack = [this.rootNode], this.rootNode;
  }
  buildCompositeNode(e) {
    const r = new Wl();
    return r.grammarSource = e, r.root = this.rootNode, this.current.content.push(r), this.nodeStack.push(r), r;
  }
  buildLeafNode(e, r) {
    const n = new fl(e.startOffset, e.image.length, Zs(e), e.tokenType, !r);
    return n.grammarSource = r, n.root = this.rootNode, this.current.content.push(n), n;
  }
  removeNode(e) {
    const r = e.container;
    if (r) {
      const n = r.content.indexOf(e);
      n >= 0 && r.content.splice(n, 1);
    }
  }
  addHiddenNodes(e) {
    const r = [];
    for (const a of e) {
      const s = new fl(a.startOffset, a.image.length, Zs(a), a.tokenType, !0);
      s.root = this.rootNode, r.push(s);
    }
    let n = this.current, i = !1;
    if (n.content.length > 0) {
      n.content.push(...r);
      return;
    }
    for (; n.container; ) {
      const a = n.container.content.indexOf(n);
      if (a > 0) {
        n.container.content.splice(a, 0, ...r), i = !0;
        break;
      }
      n = n.container;
    }
    i || this.rootNode.content.unshift(...r);
  }
  construct(e) {
    const r = this.current;
    typeof e.$type == "string" && !e.$infixName && (this.current.astNode = e), e.$cstNode = r;
    const n = this.nodeStack.pop();
    n?.content.length === 0 && this.removeNode(n);
  }
}
class ld {
  get hidden() {
    return !1;
  }
  get astNode() {
    const e = typeof this._astNode?.$type == "string" ? this._astNode : this.container?.astNode;
    if (!e)
      throw new Error("This node has no associated AST element");
    return e;
  }
  set astNode(e) {
    this._astNode = e;
  }
  get text() {
    return this.root.fullText.substring(this.offset, this.end);
  }
}
class fl extends ld {
  get offset() {
    return this._offset;
  }
  get length() {
    return this._length;
  }
  get end() {
    return this._offset + this._length;
  }
  get hidden() {
    return this._hidden;
  }
  get tokenType() {
    return this._tokenType;
  }
  get range() {
    return this._range;
  }
  constructor(e, r, n, i, a = !1) {
    super(), this._hidden = a, this._offset = e, this._tokenType = i, this._length = r, this._range = n;
  }
}
class Wl extends ld {
  constructor() {
    super(...arguments), this.content = new Kl(this);
  }
  get offset() {
    return this.firstNonHiddenNode?.offset ?? 0;
  }
  get length() {
    return this.end - this.offset;
  }
  get end() {
    return this.lastNonHiddenNode?.end ?? 0;
  }
  get range() {
    const e = this.firstNonHiddenNode, r = this.lastNonHiddenNode;
    if (e && r) {
      if (this._rangeCache === void 0) {
        const { range: n } = e, { range: i } = r;
        this._rangeCache = { start: n.start, end: i.end.line < n.start.line ? n.start : i.end };
      }
      return this._rangeCache;
    } else
      return { start: Z.create(0, 0), end: Z.create(0, 0) };
  }
  get firstNonHiddenNode() {
    for (const e of this.content)
      if (!e.hidden)
        return e;
    return this.content[0];
  }
  get lastNonHiddenNode() {
    for (let e = this.content.length - 1; e >= 0; e--) {
      const r = this.content[e];
      if (!r.hidden)
        return r;
    }
    return this.content[this.content.length - 1];
  }
}
class Kl extends Array {
  constructor(e) {
    super(), this.parent = e, Object.setPrototypeOf(this, Kl.prototype);
  }
  push(...e) {
    return this.addParents(e), super.push(...e);
  }
  unshift(...e) {
    return this.addParents(e), super.unshift(...e);
  }
  splice(e, r, ...n) {
    return this.addParents(n), super.splice(e, r, ...n);
  }
  addParents(e) {
    for (const r of e)
      r.container = this.parent;
  }
}
class cd extends Wl {
  get text() {
    return this._text.substring(this.offset, this.end);
  }
  get fullText() {
    return this._text;
  }
  constructor(e) {
    super(), this._text = "", this._text = e ?? "";
  }
}
const dl = Symbol("Datatype");
function Cs(t) {
  return t.$type === dl;
}
const Fc = "​", ud = (t) => t.endsWith(Fc) ? t : t + Fc;
class fd {
  constructor(e) {
    this._unorderedGroups = /* @__PURE__ */ new Map(), this.allRules = /* @__PURE__ */ new Map(), this.lexer = e.parser.Lexer;
    const r = this.lexer.definition, n = e.LanguageMetaData.mode === "production";
    e.shared.profilers.LangiumProfiler?.isActive("parsing") ? this.wrapper = new Bg(r, {
      ...e.parser.ParserConfig,
      skipValidations: n,
      errorMessageProvider: e.parser.ParserErrorMessageProvider
    }, e.shared.profilers.LangiumProfiler.createTask("parsing", e.LanguageMetaData.languageId)) : this.wrapper = new hd(r, {
      ...e.parser.ParserConfig,
      skipValidations: n,
      errorMessageProvider: e.parser.ParserErrorMessageProvider
    });
  }
  alternatives(e, r) {
    this.wrapper.wrapOr(e, r);
  }
  optional(e, r) {
    this.wrapper.wrapOption(e, r);
  }
  many(e, r) {
    this.wrapper.wrapMany(e, r);
  }
  atLeastOne(e, r) {
    this.wrapper.wrapAtLeastOne(e, r);
  }
  getRule(e) {
    return this.allRules.get(e);
  }
  isRecording() {
    return this.wrapper.IS_RECORDING;
  }
  get unorderedGroups() {
    return this._unorderedGroups;
  }
  getRuleStack() {
    return this.wrapper.RULE_STACK;
  }
  finalize() {
    this.wrapper.wrapSelfAnalysis();
  }
}
class jg extends fd {
  get current() {
    return this.stack[this.stack.length - 1];
  }
  constructor(e) {
    super(e), this.nodeBuilder = new Gg(), this.stack = [], this.assignmentMap = /* @__PURE__ */ new Map(), this.operatorPrecedence = /* @__PURE__ */ new Map(), this.linker = e.references.Linker, this.converter = e.parser.ValueConverter, this.astReflection = e.shared.AstReflection;
  }
  rule(e, r) {
    const n = this.computeRuleType(e);
    let i;
    Ia(e) && (i = e.name, this.registerPrecedenceMap(e));
    const a = this.wrapper.DEFINE_RULE(ud(e.name), this.startImplementation(n, i, r).bind(this));
    return this.allRules.set(e.name, a), qt(e) && e.entry && (this.mainRule = a), a;
  }
  registerPrecedenceMap(e) {
    const r = e.name, n = /* @__PURE__ */ new Map();
    for (let i = 0; i < e.operators.precedences.length; i++) {
      const a = e.operators.precedences[i];
      for (const s of a.operators)
        n.set(s.value, {
          precedence: i,
          rightAssoc: a.associativity === "right"
        });
    }
    this.operatorPrecedence.set(r, n);
  }
  computeRuleType(e) {
    return Ia(e) ? ui(e) : e.fragment ? void 0 : yf(e) ? dl : ui(e);
  }
  parse(e, r = {}) {
    this.nodeBuilder.buildRootNode(e);
    const n = this.lexerResult = this.lexer.tokenize(e);
    this.wrapper.input = n.tokens;
    const i = r.rule ? this.allRules.get(r.rule) : this.mainRule;
    if (!i)
      throw new Error(r.rule ? `No rule found with name '${r.rule}'` : "No main rule available.");
    const a = this.doParse(i);
    return this.nodeBuilder.addHiddenNodes(n.hidden), this.unorderedGroups.clear(), this.lexerResult = void 0, Bs(a, { deep: !0 }), {
      value: a,
      lexerErrors: n.errors,
      lexerReport: n.report,
      parserErrors: this.wrapper.errors
    };
  }
  doParse(e) {
    let r = this.wrapper.rule(e);
    if (this.stack.length > 0 && (r = this.construct()), r === void 0)
      throw new Error("No result from parser");
    if (this.stack.length > 0)
      throw new Error("Parser stack is not empty after parsing");
    return r;
  }
  startImplementation(e, r, n) {
    return (i) => {
      const a = !this.isRecording() && e !== void 0;
      if (a) {
        const s = { $type: e };
        this.stack.push(s), e === dl ? s.value = "" : r !== void 0 && (s.$infixName = r);
      }
      return n(i), a ? this.construct() : void 0;
    };
  }
  extractHiddenTokens(e) {
    const r = this.lexerResult.hidden;
    if (!r.length)
      return [];
    const n = e.startOffset;
    for (let i = 0; i < r.length; i++)
      if (r[i].startOffset > n)
        return r.splice(0, i);
    return r.splice(0, r.length);
  }
  consume(e, r, n) {
    const i = this.wrapper.wrapConsume(e, r);
    if (!this.isRecording() && this.isValidToken(i)) {
      const a = this.extractHiddenTokens(i);
      this.nodeBuilder.addHiddenNodes(a);
      const s = this.nodeBuilder.buildLeafNode(i, n), { assignment: o, crossRef: l } = this.getAssignment(n), c = this.current;
      if (o) {
        const u = wr(n) ? i.image : this.converter.convert(i.image, s);
        this.assign(o.operator, o.feature, u, s, l);
      } else if (Cs(c)) {
        let u = i.image;
        wr(n) || (u = this.converter.convert(u, s).toString()), c.value += u;
      }
    }
  }
  /**
   * Most consumed parser tokens are valid. However there are two cases in which they are not valid:
   *
   * 1. They were inserted during error recovery by the parser. These tokens don't really exist and should not be further processed
   * 2. They contain invalid token ranges. This might include the special EOF token, or other tokens produced by invalid token builders.
   */
  isValidToken(e) {
    return !e.isInsertedInRecovery && !isNaN(e.startOffset) && typeof e.endOffset == "number" && !isNaN(e.endOffset);
  }
  subrule(e, r, n, i, a) {
    let s;
    !this.isRecording() && !n && (s = this.nodeBuilder.buildCompositeNode(i));
    let o;
    try {
      o = this.wrapper.wrapSubrule(e, r, a);
    } finally {
      this.isRecording() || (o === void 0 && !n && (o = this.construct()), o !== void 0 && s && s.length > 0 && this.performSubruleAssignment(o, i, s));
    }
  }
  performSubruleAssignment(e, r, n) {
    const { assignment: i, crossRef: a } = this.getAssignment(r);
    if (i)
      this.assign(i.operator, i.feature, e, n, a);
    else if (!i) {
      const s = this.current;
      if (Cs(s))
        s.value += e.toString();
      else if (typeof e == "object" && e) {
        const l = this.assignWithoutOverride(e, s);
        this.stack.pop(), this.stack.push(l);
      }
    }
  }
  action(e, r) {
    if (!this.isRecording()) {
      let n = this.current;
      if (r.feature && r.operator) {
        n = this.construct(), this.nodeBuilder.removeNode(n.$cstNode), this.nodeBuilder.buildCompositeNode(r).content.push(n.$cstNode);
        const a = { $type: e };
        this.stack.push(a), this.assign(r.operator, r.feature, n, n.$cstNode);
      } else
        n.$type = e;
    }
  }
  construct() {
    if (this.isRecording())
      return;
    const e = this.stack.pop();
    return this.nodeBuilder.construct(e), "$infixName" in e ? this.constructInfix(e, this.operatorPrecedence.get(e.$infixName)) : Cs(e) ? this.converter.convert(e.value, e.$cstNode) : (Hd(this.astReflection, e), e);
  }
  constructInfix(e, r) {
    const n = e.parts;
    if (!Array.isArray(n) || n.length === 0)
      return;
    const i = e.operators;
    if (!Array.isArray(i) || n.length < 2)
      return n[0];
    let a = 0, s = -1;
    for (let b = 0; b < i.length; b++) {
      const I = i[b], k = r.get(I) ?? {
        precedence: 1 / 0,
        rightAssoc: !1
      };
      k.precedence > s ? (s = k.precedence, a = b) : k.precedence === s && (k.rightAssoc || (a = b));
    }
    const o = i.slice(0, a), l = i.slice(a + 1), c = n.slice(0, a + 1), u = n.slice(a + 1), d = {
      $infixName: e.$infixName,
      $type: e.$type,
      $cstNode: e.$cstNode,
      parts: c,
      operators: o
    }, p = {
      $infixName: e.$infixName,
      $type: e.$type,
      $cstNode: e.$cstNode,
      parts: u,
      operators: l
    }, m = this.constructInfix(d, r), A = this.constructInfix(p, r);
    return {
      $type: e.$type,
      $cstNode: e.$cstNode,
      left: m,
      operator: i[a],
      right: A
    };
  }
  getAssignment(e) {
    if (!this.assignmentMap.has(e)) {
      const r = Ja(e, kr);
      this.assignmentMap.set(e, {
        assignment: r,
        crossRef: r && Qa(r.terminal) ? r.terminal.isMulti ? "multi" : "single" : void 0
      });
    }
    return this.assignmentMap.get(e);
  }
  assign(e, r, n, i, a) {
    const s = this.current;
    let o;
    switch (a === "single" && typeof n == "string" ? o = this.linker.buildReference(s, r, i, n) : a === "multi" && typeof n == "string" ? o = this.linker.buildMultiReference(s, r, i, n) : o = n, e) {
      case "=": {
        s[r] = o;
        break;
      }
      case "?=": {
        s[r] = !0;
        break;
      }
      case "+=":
        Array.isArray(s[r]) || (s[r] = []), s[r].push(o);
    }
  }
  assignWithoutOverride(e, r) {
    for (const [i, a] of Object.entries(r)) {
      const s = e[i];
      s === void 0 ? e[i] = a : Array.isArray(s) && Array.isArray(a) && (a.push(...s), e[i] = a);
    }
    const n = e.$cstNode;
    return n && (n.astNode = void 0, e.$cstNode = void 0), e;
  }
  get definitionErrors() {
    return this.wrapper.definitionErrors;
  }
}
class zg {
  buildMismatchTokenMessage(e) {
    return tn.buildMismatchTokenMessage(e);
  }
  buildNotAllInputParsedMessage(e) {
    return tn.buildNotAllInputParsedMessage(e);
  }
  buildNoViableAltMessage(e) {
    return tn.buildNoViableAltMessage(e);
  }
  buildEarlyExitMessage(e) {
    return tn.buildEarlyExitMessage(e);
  }
}
class dd extends zg {
  buildMismatchTokenMessage({ expected: e, actual: r }) {
    return `Expecting ${e.LABEL ? "`" + e.LABEL + "`" : e.name.endsWith(":KW") ? `keyword '${e.name.substring(0, e.name.length - 3)}'` : `token of type '${e.name}'`} but found \`${r.image}\`.`;
  }
  buildNotAllInputParsedMessage({ firstRedundant: e }) {
    return `Expecting end of file but found \`${e.image}\`.`;
  }
}
class Ug extends fd {
  constructor() {
    super(...arguments), this.tokens = [], this.elementStack = [], this.lastElementStack = [], this.nextTokenIndex = 0, this.stackSize = 0;
  }
  action() {
  }
  construct() {
  }
  parse(e) {
    this.resetState();
    const r = this.lexer.tokenize(e, { mode: "partial" });
    return this.tokens = r.tokens, this.wrapper.input = [...this.tokens], this.mainRule.call(this.wrapper, {}), this.unorderedGroups.clear(), {
      tokens: this.tokens,
      elementStack: [...this.lastElementStack],
      tokenIndex: this.nextTokenIndex
    };
  }
  rule(e, r) {
    const n = this.wrapper.DEFINE_RULE(ud(e.name), this.startImplementation(r).bind(this));
    return this.allRules.set(e.name, n), e.entry && (this.mainRule = n), n;
  }
  resetState() {
    this.elementStack = [], this.lastElementStack = [], this.nextTokenIndex = 0, this.stackSize = 0;
  }
  startImplementation(e) {
    return (r) => {
      const n = this.keepStackSize();
      try {
        e(r);
      } finally {
        this.resetStackSize(n);
      }
    };
  }
  removeUnexpectedElements() {
    this.elementStack.splice(this.stackSize);
  }
  keepStackSize() {
    const e = this.elementStack.length;
    return this.stackSize = e, e;
  }
  resetStackSize(e) {
    this.removeUnexpectedElements(), this.stackSize = e;
  }
  consume(e, r, n) {
    this.wrapper.wrapConsume(e, r), this.isRecording() || (this.lastElementStack = [...this.elementStack, n], this.nextTokenIndex = this.currIdx + 1);
  }
  subrule(e, r, n, i, a) {
    this.before(i), this.wrapper.wrapSubrule(e, r, a), this.after(i);
  }
  before(e) {
    this.isRecording() || this.elementStack.push(e);
  }
  after(e) {
    if (!this.isRecording()) {
      const r = this.elementStack.lastIndexOf(e);
      r >= 0 && this.elementStack.splice(r);
    }
  }
  get currIdx() {
    return this.wrapper.currIdx;
  }
}
const qg = {
  recoveryEnabled: !0,
  nodeLocationTracking: "full",
  skipValidations: !0,
  errorMessageProvider: new dd()
};
class hd extends Xm {
  constructor(e, r) {
    const n = r && "maxLookahead" in r;
    super(e, {
      ...qg,
      lookaheadStrategy: n ? new Gl({ maxLookahead: r.maxLookahead }) : new gg({
        // If validations are skipped, don't log the lookahead warnings
        logging: r.skipValidations ? () => {
        } : void 0
      }),
      ...r
    });
  }
  get IS_RECORDING() {
    return this.RECORDING_PHASE;
  }
  DEFINE_RULE(e, r, n) {
    return this.RULE(e, r, n);
  }
  wrapSelfAnalysis() {
    this.performSelfAnalysis();
  }
  wrapConsume(e, r) {
    return this.consume(e, r, void 0);
  }
  wrapSubrule(e, r, n) {
    return this.subrule(e, r, {
      ARGS: [n]
    });
  }
  wrapOr(e, r) {
    this.or(e, r);
  }
  wrapOption(e, r) {
    this.option(e, r);
  }
  wrapMany(e, r) {
    this.many(e, r);
  }
  wrapAtLeastOne(e, r) {
    this.atLeastOne(e, r);
  }
  rule(e) {
    return e.call(this, {});
  }
}
class Bg extends hd {
  constructor(e, r, n) {
    super(e, r), this.task = n;
  }
  rule(e) {
    this.task.start(), this.task.startSubTask(this.ruleName(e));
    try {
      return super.rule(e);
    } finally {
      this.task.stopSubTask(this.ruleName(e)), this.task.stop();
    }
  }
  ruleName(e) {
    return e.ruleName;
  }
  subrule(e, r, n) {
    this.task.startSubTask(this.ruleName(r));
    try {
      return super.subrule(e, r, n);
    } finally {
      this.task.stopSubTask(this.ruleName(r));
    }
  }
}
function pd(t, e, r) {
  return Wg({
    parser: e,
    tokens: r,
    ruleNames: /* @__PURE__ */ new Map()
  }, t), e;
}
function Wg(t, e) {
  const r = df(e, !1), n = fe(e.rules).filter(qt).filter((a) => r.has(a));
  for (const a of n) {
    const s = {
      ...t,
      consume: 1,
      optional: 1,
      subrule: 1,
      many: 1,
      or: 1
    };
    t.parser.rule(a, Ir(s, a.definition));
  }
  const i = fe(e.rules).filter(Ia).filter((a) => r.has(a));
  for (const a of i)
    t.parser.rule(a, Kg(t, a));
}
function Kg(t, e) {
  const r = e.call.rule.ref;
  if (!r)
    throw new Error("Could not resolve reference to infix operator rule: " + e.call.rule.$refText);
  if (Bt(r))
    throw new Error("Cannot use terminal rule in infix expression");
  const n = e.operators.precedences.flatMap((m) => m.operators), i = {
    $type: "Group",
    elements: []
  }, a = {
    $container: i,
    $type: "Assignment",
    feature: "parts",
    operator: "+=",
    terminal: e.call
  }, s = {
    $container: i,
    $type: "Group",
    elements: [],
    cardinality: "*"
  };
  i.elements.push(a, s);
  const l = {
    $container: s,
    $type: "Assignment",
    feature: "operators",
    operator: "+=",
    terminal: {
      $type: "Alternatives",
      elements: n
    }
  }, c = {
    ...a,
    $container: s
  };
  s.elements.push(l, c);
  const d = n.map((m) => t.tokens[m.value]).map((m, A) => ({
    ALT: () => t.parser.consume(A, m, l)
  }));
  let p;
  return (m) => {
    p ?? (p = Vl(t, r)), t.parser.subrule(0, p, !1, a, m), t.parser.many(0, {
      DEF: () => {
        t.parser.alternatives(0, d), t.parser.subrule(1, p, !1, c, m);
      }
    });
  };
}
function Ir(t, e, r = !1) {
  let n;
  if (wr(e))
    n = Qg(t, e);
  else if (Za(e))
    n = Vg(t, e);
  else if (kr(e))
    n = Ir(t, e.terminal);
  else if (Qa(e))
    n = md(t, e);
  else if (br(e))
    n = Hg(t, e);
  else if (af(e))
    n = Yg(t, e);
  else if (of(e))
    n = Jg(t, e);
  else if (Il(e))
    n = Zg(t, e);
  else if (eh(e)) {
    const i = t.consume++;
    n = () => t.parser.consume(i, Qt, e);
  } else
    throw new cf(e.$cstNode, `Unexpected element type: ${e.$type}`);
  return gd(t, r ? void 0 : Ya(e), n, e.cardinality);
}
function Vg(t, e) {
  const r = ui(e);
  return () => t.parser.action(r, e);
}
function Hg(t, e) {
  const r = e.rule.ref;
  if (Ai(r)) {
    const n = t.subrule++, i = qt(r) && r.fragment, a = e.arguments.length > 0 ? Xg(r, e.arguments) : () => ({});
    let s;
    return (o) => {
      s ?? (s = Vl(t, r)), t.parser.subrule(n, s, i, e, a(o));
    };
  } else if (Bt(r)) {
    const n = t.consume++, i = hl(t, r.name);
    return () => t.parser.consume(n, i, e);
  } else if (r)
    $i();
  else
    throw new cf(e.$cstNode, `Undefined rule: ${e.rule.$refText}`);
}
function Xg(t, e) {
  if (e.some((n) => n.calledByName)) {
    const n = e.map((i) => ({
      parameterName: i.parameter?.ref?.name,
      predicate: gt(i.value)
    }));
    return (i) => {
      const a = {};
      for (const { parameterName: s, predicate: o } of n)
        s && (a[s] = o(i));
      return a;
    };
  } else {
    const n = e.map((i) => gt(i.value));
    return (i) => {
      const a = {};
      for (let s = 0; s < n.length; s++)
        if (s < t.parameters.length) {
          const o = t.parameters[s].name, l = n[s];
          a[o] = l(i);
        }
      return a;
    };
  }
}
function gt(t) {
  if (Qd(t)) {
    const e = gt(t.left), r = gt(t.right);
    return (n) => e(n) || r(n);
  } else if (Zd(t)) {
    const e = gt(t.left), r = gt(t.right);
    return (n) => e(n) && r(n);
  } else if (nh(t)) {
    const e = gt(t.value);
    return (r) => !e(r);
  } else if (ih(t)) {
    const e = t.parameter.ref.name;
    return (r) => r !== void 0 && r[e] === !0;
  } else if (Yd(t)) {
    const e = !!t.true;
    return () => e;
  }
  $i();
}
function Yg(t, e) {
  if (e.elements.length === 1)
    return Ir(t, e.elements[0]);
  {
    const r = [];
    for (const i of e.elements) {
      const a = {
        // Since we handle the guard condition in the alternative already
        // We can ignore the group guard condition inside
        ALT: Ir(t, i, !0)
      }, s = Ya(i);
      s && (a.GATE = gt(s)), r.push(a);
    }
    const n = t.or++;
    return (i) => t.parser.alternatives(n, r.map((a) => {
      const s = {
        ALT: () => a.ALT(i)
      }, o = a.GATE;
      return o && (s.GATE = () => o(i)), s;
    }));
  }
}
function Jg(t, e) {
  if (e.elements.length === 1)
    return Ir(t, e.elements[0]);
  const r = [];
  for (const o of e.elements) {
    const l = {
      // Since we handle the guard condition in the alternative already
      // We can ignore the group guard condition inside
      ALT: Ir(t, o, !0)
    }, c = Ya(o);
    c && (l.GATE = gt(c)), r.push(l);
  }
  const n = t.or++, i = (o, l) => {
    const c = l.getRuleStack().join("-");
    return `uGroup_${o}_${c}`;
  }, a = (o) => t.parser.alternatives(n, r.map((l, c) => {
    const u = { ALT: () => !0 }, d = t.parser;
    u.ALT = () => {
      if (l.ALT(o), !d.isRecording()) {
        const m = i(n, d);
        d.unorderedGroups.get(m) || d.unorderedGroups.set(m, []);
        const A = d.unorderedGroups.get(m);
        typeof A?.[c] > "u" && (A[c] = !0);
      }
    };
    const p = l.GATE;
    return p ? u.GATE = () => p(o) : u.GATE = () => !d.unorderedGroups.get(i(n, d))?.[c], u;
  })), s = gd(t, Ya(e), a, "*");
  return (o) => {
    s(o), t.parser.isRecording() || t.parser.unorderedGroups.delete(i(n, t.parser));
  };
}
function Zg(t, e) {
  const r = e.elements.map((n) => Ir(t, n));
  return (n) => r.forEach((i) => i(n));
}
function Ya(t) {
  if (Il(t))
    return t.guardCondition;
}
function md(t, e, r = e.terminal) {
  if (r)
    if (br(r) && qt(r.rule.ref)) {
      const n = r.rule.ref, i = t.subrule++;
      let a;
      return (s) => {
        a ?? (a = Vl(t, n)), t.parser.subrule(i, a, !1, e, s);
      };
    } else if (br(r) && Bt(r.rule.ref)) {
      const n = t.consume++, i = hl(t, r.rule.ref.name);
      return () => t.parser.consume(n, i, e);
    } else if (wr(r)) {
      const n = t.consume++, i = hl(t, r.value);
      return () => t.parser.consume(n, i, e);
    } else
      throw new Error("Could not build cross reference parser");
  else {
    if (!e.type.ref)
      throw new Error("Could not resolve reference to type: " + e.type.$refText);
    const i = mf(e.type.ref)?.terminal;
    if (!i)
      throw new Error("Could not find name assignment for type: " + ui(e.type.ref));
    return md(t, e, i);
  }
}
function Qg(t, e) {
  const r = t.consume++, n = t.tokens[e.value];
  if (!n)
    throw new Error("Could not find token for keyword: " + e.value);
  return () => t.parser.consume(r, n, e);
}
function gd(t, e, r, n) {
  const i = e && gt(e);
  if (!n)
    if (i) {
      const a = t.or++;
      return (s) => t.parser.alternatives(a, [
        {
          ALT: () => r(s),
          GATE: () => i(s)
        },
        {
          ALT: Oc(),
          GATE: () => !i(s)
        }
      ]);
    } else
      return r;
  if (n === "*") {
    const a = t.many++;
    return (s) => t.parser.many(a, {
      DEF: () => r(s),
      GATE: i ? () => i(s) : void 0
    });
  } else if (n === "+") {
    const a = t.many++;
    if (i) {
      const s = t.or++;
      return (o) => t.parser.alternatives(s, [
        {
          ALT: () => t.parser.atLeastOne(a, {
            DEF: () => r(o)
          }),
          GATE: () => i(o)
        },
        {
          ALT: Oc(),
          GATE: () => !i(o)
        }
      ]);
    } else
      return (s) => t.parser.atLeastOne(a, {
        DEF: () => r(s)
      });
  } else if (n === "?") {
    const a = t.optional++;
    return (s) => t.parser.optional(a, {
      DEF: () => r(s),
      GATE: i ? () => i(s) : void 0
    });
  } else
    $i();
}
function Vl(t, e) {
  const r = ey(t, e), n = t.parser.getRule(r);
  if (!n)
    throw new Error(`Rule "${r}" not found."`);
  return n;
}
function ey(t, e) {
  if (Ai(e))
    return e.name;
  if (t.ruleNames.has(e))
    return t.ruleNames.get(e);
  {
    let r = e, n = r.$container, i = e.$type;
    for (; !qt(n); )
      (Il(n) || af(n) || of(n)) && (i = n.elements.indexOf(r).toString() + ":" + i), r = n, n = n.$container;
    return i = n.name + ":" + i, t.ruleNames.set(e, i), i;
  }
}
function hl(t, e) {
  const r = t.tokens[e];
  if (!r)
    throw new Error(`Token "${e}" not found."`);
  return r;
}
function ty(t) {
  const e = t.Grammar, r = t.parser.Lexer, n = new Ug(t);
  return pd(e, n, r.definition), n.finalize(), n;
}
function ry(t) {
  const e = ny(t);
  return e.finalize(), e;
}
function ny(t) {
  const e = t.Grammar, r = t.parser.Lexer, n = new jg(t);
  return pd(e, n, r.definition);
}
class yd {
  constructor() {
    this.diagnostics = [];
  }
  buildTokens(e, r) {
    const n = fe(df(e, !1)), i = this.buildTerminalTokens(n), a = this.buildKeywordTokens(n, i, r);
    return a.push(...i), a;
  }
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  flushLexingReport(e) {
    return { diagnostics: this.popDiagnostics() };
  }
  popDiagnostics() {
    const e = [...this.diagnostics];
    return this.diagnostics = [], e;
  }
  buildTerminalTokens(e) {
    return e.filter(Bt).filter((r) => !r.fragment).map((r) => this.buildTerminalToken(r)).toArray();
  }
  buildTerminalToken(e) {
    const r = Ol(e), n = this.requiresCustomPattern(r) ? this.regexPatternFunction(r) : r, i = {
      name: e.name,
      PATTERN: n
    };
    return typeof n == "function" && (i.LINE_BREAKS = !0), e.hidden && (i.GROUP = ff(r) ? We.SKIPPED : "hidden"), i;
  }
  requiresCustomPattern(e) {
    return !!(e.flags.includes("u") || e.flags.includes("s"));
  }
  regexPatternFunction(e) {
    const r = new RegExp(e, e.flags + "y");
    return (n, i) => (r.lastIndex = i, r.exec(n));
  }
  buildKeywordTokens(e, r, n) {
    return e.filter(Ai).flatMap((i) => Ei(i).filter(wr)).distinct((i) => i.value).toArray().sort((i, a) => a.value.length - i.value.length).map((i) => this.buildKeywordToken(i, r, !!n?.caseInsensitive));
  }
  buildKeywordToken(e, r, n) {
    const i = this.buildKeywordPattern(e, n), a = {
      name: e.value,
      PATTERN: i,
      LONGER_ALT: this.findLongerAlt(e, r)
    };
    return typeof i == "function" && (a.LINE_BREAKS = !0), a;
  }
  buildKeywordPattern(e, r) {
    return r ? new RegExp(ts(e.value), "i") : e.value;
  }
  findLongerAlt(e, r) {
    return r.reduce((n, i) => {
      const a = i?.PATTERN;
      return a?.source && bh("^" + a.source + "$", e.value) && n.push(i), n;
    }, []);
  }
}
class Td {
  convert(e, r) {
    let n = r.grammarSource;
    if (Qa(n) && (n = Ph(n)), br(n)) {
      const i = n.rule.ref;
      if (!i)
        throw new Error("This cst node was not parsed by a rule.");
      return this.runConverter(i, e, r);
    }
    return e;
  }
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  runConverter(e, r, n) {
    switch (e.name.toUpperCase()) {
      case "INT":
        return xt.convertInt(r);
      case "STRING":
        return xt.convertString(r);
      case "ID":
        return xt.convertID(r);
    }
    switch (Gh(e)?.toLowerCase()) {
      case "number":
        return xt.convertNumber(r);
      case "boolean":
        return xt.convertBoolean(r);
      case "bigint":
        return xt.convertBigint(r);
      case "date":
        return xt.convertDate(r);
      default:
        return r;
    }
  }
}
var xt;
(function(t) {
  function e(c) {
    let u = "";
    for (let d = 1; d < c.length - 1; d++) {
      const p = c.charAt(d);
      if (p === "\\") {
        const m = c.charAt(++d);
        u += r(m);
      } else
        u += p;
    }
    return u;
  }
  t.convertString = e;
  function r(c) {
    switch (c) {
      case "b":
        return "\b";
      case "f":
        return "\f";
      case "n":
        return `
`;
      case "r":
        return "\r";
      case "t":
        return "	";
      case "v":
        return "\v";
      case "0":
        return "\0";
      default:
        return c;
    }
  }
  function n(c) {
    return c.charAt(0) === "^" ? c.substring(1) : c;
  }
  t.convertID = n;
  function i(c) {
    return parseInt(c);
  }
  t.convertInt = i;
  function a(c) {
    return BigInt(c);
  }
  t.convertBigint = a;
  function s(c) {
    return new Date(c);
  }
  t.convertDate = s;
  function o(c) {
    return Number(c);
  }
  t.convertNumber = o;
  function l(c) {
    return c.toLowerCase() === "true";
  }
  t.convertBoolean = l;
})(xt || (xt = {}));
var ar = {}, ta = {}, Gc;
function Or() {
  if (Gc) return ta;
  Gc = 1, Object.defineProperty(ta, "__esModule", { value: !0 });
  let t;
  function e() {
    if (t === void 0)
      throw new Error("No runtime abstraction layer installed");
    return t;
  }
  return (function(r) {
    function n(i) {
      if (i === void 0)
        throw new Error("No runtime abstraction layer provided");
      t = i;
    }
    r.install = n;
  })(e || (e = {})), ta.default = e, ta;
}
var Pe = {}, jc;
function bi() {
  if (jc) return Pe;
  jc = 1, Object.defineProperty(Pe, "__esModule", { value: !0 }), Pe.stringArray = Pe.array = Pe.func = Pe.error = Pe.number = Pe.string = Pe.boolean = void 0;
  function t(o) {
    return o === !0 || o === !1;
  }
  Pe.boolean = t;
  function e(o) {
    return typeof o == "string" || o instanceof String;
  }
  Pe.string = e;
  function r(o) {
    return typeof o == "number" || o instanceof Number;
  }
  Pe.number = r;
  function n(o) {
    return o instanceof Error;
  }
  Pe.error = n;
  function i(o) {
    return typeof o == "function";
  }
  Pe.func = i;
  function a(o) {
    return Array.isArray(o);
  }
  Pe.array = a;
  function s(o) {
    return a(o) && o.every((l) => e(l));
  }
  return Pe.stringArray = s, Pe;
}
var sr = {}, zc;
function mn() {
  if (zc) return sr;
  zc = 1, Object.defineProperty(sr, "__esModule", { value: !0 }), sr.Emitter = sr.Event = void 0;
  const t = Or();
  var e;
  (function(i) {
    const a = { dispose() {
    } };
    i.None = function() {
      return a;
    };
  })(e || (sr.Event = e = {}));
  class r {
    add(a, s = null, o) {
      this._callbacks || (this._callbacks = [], this._contexts = []), this._callbacks.push(a), this._contexts.push(s), Array.isArray(o) && o.push({ dispose: () => this.remove(a, s) });
    }
    remove(a, s = null) {
      if (!this._callbacks)
        return;
      let o = !1;
      for (let l = 0, c = this._callbacks.length; l < c; l++)
        if (this._callbacks[l] === a)
          if (this._contexts[l] === s) {
            this._callbacks.splice(l, 1), this._contexts.splice(l, 1);
            return;
          } else
            o = !0;
      if (o)
        throw new Error("When adding a listener with a context, you should remove it with the same context");
    }
    invoke(...a) {
      if (!this._callbacks)
        return [];
      const s = [], o = this._callbacks.slice(0), l = this._contexts.slice(0);
      for (let c = 0, u = o.length; c < u; c++)
        try {
          s.push(o[c].apply(l[c], a));
        } catch (d) {
          (0, t.default)().console.error(d);
        }
      return s;
    }
    isEmpty() {
      return !this._callbacks || this._callbacks.length === 0;
    }
    dispose() {
      this._callbacks = void 0, this._contexts = void 0;
    }
  }
  class n {
    constructor(a) {
      this._options = a;
    }
    /**
     * For the public to allow to subscribe
     * to events from this Emitter
     */
    get event() {
      return this._event || (this._event = (a, s, o) => {
        this._callbacks || (this._callbacks = new r()), this._options && this._options.onFirstListenerAdd && this._callbacks.isEmpty() && this._options.onFirstListenerAdd(this), this._callbacks.add(a, s);
        const l = {
          dispose: () => {
            this._callbacks && (this._callbacks.remove(a, s), l.dispose = n._noop, this._options && this._options.onLastListenerRemove && this._callbacks.isEmpty() && this._options.onLastListenerRemove(this));
          }
        };
        return Array.isArray(o) && o.push(l), l;
      }), this._event;
    }
    /**
     * To be kept private to fire an event to
     * subscribers
     */
    fire(a) {
      this._callbacks && this._callbacks.invoke.call(this._callbacks, a);
    }
    dispose() {
      this._callbacks && (this._callbacks.dispose(), this._callbacks = void 0);
    }
  }
  return sr.Emitter = n, n._noop = function() {
  }, sr;
}
var Uc;
function us() {
  if (Uc) return ar;
  Uc = 1, Object.defineProperty(ar, "__esModule", { value: !0 }), ar.CancellationTokenSource = ar.CancellationToken = void 0;
  const t = Or(), e = bi(), r = mn();
  var n;
  (function(o) {
    o.None = Object.freeze({
      isCancellationRequested: !1,
      onCancellationRequested: r.Event.None
    }), o.Cancelled = Object.freeze({
      isCancellationRequested: !0,
      onCancellationRequested: r.Event.None
    });
    function l(c) {
      const u = c;
      return u && (u === o.None || u === o.Cancelled || e.boolean(u.isCancellationRequested) && !!u.onCancellationRequested);
    }
    o.is = l;
  })(n || (ar.CancellationToken = n = {}));
  const i = Object.freeze(function(o, l) {
    const c = (0, t.default)().timer.setTimeout(o.bind(l), 0);
    return { dispose() {
      c.dispose();
    } };
  });
  class a {
    constructor() {
      this._isCancelled = !1;
    }
    cancel() {
      this._isCancelled || (this._isCancelled = !0, this._emitter && (this._emitter.fire(void 0), this.dispose()));
    }
    get isCancellationRequested() {
      return this._isCancelled;
    }
    get onCancellationRequested() {
      return this._isCancelled ? i : (this._emitter || (this._emitter = new r.Emitter()), this._emitter.event);
    }
    dispose() {
      this._emitter && (this._emitter.dispose(), this._emitter = void 0);
    }
  }
  class s {
    get token() {
      return this._token || (this._token = new a()), this._token;
    }
    cancel() {
      this._token ? this._token.cancel() : this._token = n.Cancelled;
    }
    dispose() {
      this._token ? this._token instanceof a && this._token.dispose() : this._token = n.None;
    }
  }
  return ar.CancellationTokenSource = s, ar;
}
var he = us();
function iy() {
  return new Promise((t) => {
    typeof setImmediate > "u" ? setTimeout(t, 0) : setImmediate(t);
  });
}
let ka = 0, ay = 10;
function sy() {
  return ka = performance.now(), new he.CancellationTokenSource();
}
const rn = Symbol("OperationCancelled");
function fs(t) {
  return t === rn;
}
async function Ue(t) {
  if (t === he.CancellationToken.None)
    return;
  const e = performance.now();
  if (e - ka >= ay && (ka = e, await iy(), ka = performance.now()), t.isCancellationRequested)
    throw rn;
}
class Hl {
  constructor() {
    this.promise = new Promise((e, r) => {
      this.resolve = (n) => (e(n), this), this.reject = (n) => (r(n), this);
    });
  }
}
class Ti {
  constructor(e, r, n, i) {
    this._uri = e, this._languageId = r, this._version = n, this._content = i, this._lineOffsets = void 0;
  }
  get uri() {
    return this._uri;
  }
  get languageId() {
    return this._languageId;
  }
  get version() {
    return this._version;
  }
  getText(e) {
    if (e) {
      const r = this.offsetAt(e.start), n = this.offsetAt(e.end);
      return this._content.substring(r, n);
    }
    return this._content;
  }
  update(e, r) {
    for (const n of e)
      if (Ti.isIncremental(n)) {
        const i = vd(n.range), a = this.offsetAt(i.start), s = this.offsetAt(i.end);
        this._content = this._content.substring(0, a) + n.text + this._content.substring(s, this._content.length);
        const o = Math.max(i.start.line, 0), l = Math.max(i.end.line, 0);
        let c = this._lineOffsets;
        const u = qc(n.text, !1, a);
        if (l - o === u.length)
          for (let p = 0, m = u.length; p < m; p++)
            c[p + o + 1] = u[p];
        else
          u.length < 1e4 ? c.splice(o + 1, l - o, ...u) : this._lineOffsets = c = c.slice(0, o + 1).concat(u, c.slice(l + 1));
        const d = n.text.length - (s - a);
        if (d !== 0)
          for (let p = o + 1 + u.length, m = c.length; p < m; p++)
            c[p] = c[p] + d;
      } else if (Ti.isFull(n))
        this._content = n.text, this._lineOffsets = void 0;
      else
        throw new Error("Unknown change event received");
    this._version = r;
  }
  getLineOffsets() {
    return this._lineOffsets === void 0 && (this._lineOffsets = qc(this._content, !0)), this._lineOffsets;
  }
  positionAt(e) {
    e = Math.max(Math.min(e, this._content.length), 0);
    const r = this.getLineOffsets();
    let n = 0, i = r.length;
    if (i === 0)
      return { line: 0, character: e };
    for (; n < i; ) {
      const s = Math.floor((n + i) / 2);
      r[s] > e ? i = s : n = s + 1;
    }
    const a = n - 1;
    return e = this.ensureBeforeEOL(e, r[a]), { line: a, character: e - r[a] };
  }
  offsetAt(e) {
    const r = this.getLineOffsets();
    if (e.line >= r.length)
      return this._content.length;
    if (e.line < 0)
      return 0;
    const n = r[e.line];
    if (e.character <= 0)
      return n;
    const i = e.line + 1 < r.length ? r[e.line + 1] : this._content.length, a = Math.min(n + e.character, i);
    return this.ensureBeforeEOL(a, n);
  }
  ensureBeforeEOL(e, r) {
    for (; e > r && Rd(this._content.charCodeAt(e - 1)); )
      e--;
    return e;
  }
  get lineCount() {
    return this.getLineOffsets().length;
  }
  static isIncremental(e) {
    const r = e;
    return r != null && typeof r.text == "string" && r.range !== void 0 && (r.rangeLength === void 0 || typeof r.rangeLength == "number");
  }
  static isFull(e) {
    const r = e;
    return r != null && typeof r.text == "string" && r.range === void 0 && r.rangeLength === void 0;
  }
}
var pl;
(function(t) {
  function e(i, a, s, o) {
    return new Ti(i, a, s, o);
  }
  t.create = e;
  function r(i, a, s) {
    if (i instanceof Ti)
      return i.update(a, s), i;
    throw new Error("TextDocument.update: document must be created by TextDocument.create");
  }
  t.update = r;
  function n(i, a) {
    const s = i.getText(), o = ml(a.map(oy), (u, d) => {
      const p = u.range.start.line - d.range.start.line;
      return p === 0 ? u.range.start.character - d.range.start.character : p;
    });
    let l = 0;
    const c = [];
    for (const u of o) {
      const d = i.offsetAt(u.range.start);
      if (d < l)
        throw new Error("Overlapping edit");
      d > l && c.push(s.substring(l, d)), u.newText.length && c.push(u.newText), l = i.offsetAt(u.range.end);
    }
    return c.push(s.substr(l)), c.join("");
  }
  t.applyEdits = n;
})(pl || (pl = {}));
function ml(t, e) {
  if (t.length <= 1)
    return t;
  const r = t.length / 2 | 0, n = t.slice(0, r), i = t.slice(r);
  ml(n, e), ml(i, e);
  let a = 0, s = 0, o = 0;
  for (; a < n.length && s < i.length; )
    e(n[a], i[s]) <= 0 ? t[o++] = n[a++] : t[o++] = i[s++];
  for (; a < n.length; )
    t[o++] = n[a++];
  for (; s < i.length; )
    t[o++] = i[s++];
  return t;
}
function qc(t, e, r = 0) {
  const n = e ? [r] : [];
  for (let i = 0; i < t.length; i++) {
    const a = t.charCodeAt(i);
    Rd(a) && (a === 13 && i + 1 < t.length && t.charCodeAt(i + 1) === 10 && i++, n.push(r + i + 1));
  }
  return n;
}
function Rd(t) {
  return t === 13 || t === 10;
}
function vd(t) {
  const e = t.start, r = t.end;
  return e.line > r.line || e.line === r.line && e.character > r.character ? { start: r, end: e } : t;
}
function oy(t) {
  const e = vd(t.range);
  return e !== t.range ? { newText: t.newText, range: e } : t;
}
var Ed;
(() => {
  var t = { 975: (N) => {
    function T(y) {
      if (typeof y != "string") throw new TypeError("Path must be a string. Received " + JSON.stringify(y));
    }
    function g(y, R) {
      for (var E, L = "", D = 0, x = -1, j = 0, F = 0; F <= y.length; ++F) {
        if (F < y.length) E = y.charCodeAt(F);
        else {
          if (E === 47) break;
          E = 47;
        }
        if (E === 47) {
          if (!(x === F - 1 || j === 1)) if (x !== F - 1 && j === 2) {
            if (L.length < 2 || D !== 2 || L.charCodeAt(L.length - 1) !== 46 || L.charCodeAt(L.length - 2) !== 46) {
              if (L.length > 2) {
                var te = L.lastIndexOf("/");
                if (te !== L.length - 1) {
                  te === -1 ? (L = "", D = 0) : D = (L = L.slice(0, te)).length - 1 - L.lastIndexOf("/"), x = F, j = 0;
                  continue;
                }
              } else if (L.length === 2 || L.length === 1) {
                L = "", D = 0, x = F, j = 0;
                continue;
              }
            }
            R && (L.length > 0 ? L += "/.." : L = "..", D = 2);
          } else L.length > 0 ? L += "/" + y.slice(x + 1, F) : L = y.slice(x + 1, F), D = F - x - 1;
          x = F, j = 0;
        } else E === 46 && j !== -1 ? ++j : j = -1;
      }
      return L;
    }
    var $ = { resolve: function() {
      for (var y, R = "", E = !1, L = arguments.length - 1; L >= -1 && !E; L--) {
        var D;
        L >= 0 ? D = arguments[L] : (y === void 0 && (y = process.cwd()), D = y), T(D), D.length !== 0 && (R = D + "/" + R, E = D.charCodeAt(0) === 47);
      }
      return R = g(R, !E), E ? R.length > 0 ? "/" + R : "/" : R.length > 0 ? R : ".";
    }, normalize: function(y) {
      if (T(y), y.length === 0) return ".";
      var R = y.charCodeAt(0) === 47, E = y.charCodeAt(y.length - 1) === 47;
      return (y = g(y, !R)).length !== 0 || R || (y = "."), y.length > 0 && E && (y += "/"), R ? "/" + y : y;
    }, isAbsolute: function(y) {
      return T(y), y.length > 0 && y.charCodeAt(0) === 47;
    }, join: function() {
      if (arguments.length === 0) return ".";
      for (var y, R = 0; R < arguments.length; ++R) {
        var E = arguments[R];
        T(E), E.length > 0 && (y === void 0 ? y = E : y += "/" + E);
      }
      return y === void 0 ? "." : $.normalize(y);
    }, relative: function(y, R) {
      if (T(y), T(R), y === R || (y = $.resolve(y)) === (R = $.resolve(R))) return "";
      for (var E = 1; E < y.length && y.charCodeAt(E) === 47; ++E) ;
      for (var L = y.length, D = L - E, x = 1; x < R.length && R.charCodeAt(x) === 47; ++x) ;
      for (var j = R.length - x, F = D < j ? D : j, te = -1, z = 0; z <= F; ++z) {
        if (z === F) {
          if (j > F) {
            if (R.charCodeAt(x + z) === 47) return R.slice(x + z + 1);
            if (z === 0) return R.slice(x + z);
          } else D > F && (y.charCodeAt(E + z) === 47 ? te = z : z === 0 && (te = 0));
          break;
        }
        var Q = y.charCodeAt(E + z);
        if (Q !== R.charCodeAt(x + z)) break;
        Q === 47 && (te = z);
      }
      var _e = "";
      for (z = E + te + 1; z <= L; ++z) z !== L && y.charCodeAt(z) !== 47 || (_e.length === 0 ? _e += ".." : _e += "/..");
      return _e.length > 0 ? _e + R.slice(x + te) : (x += te, R.charCodeAt(x) === 47 && ++x, R.slice(x));
    }, _makeLong: function(y) {
      return y;
    }, dirname: function(y) {
      if (T(y), y.length === 0) return ".";
      for (var R = y.charCodeAt(0), E = R === 47, L = -1, D = !0, x = y.length - 1; x >= 1; --x) if ((R = y.charCodeAt(x)) === 47) {
        if (!D) {
          L = x;
          break;
        }
      } else D = !1;
      return L === -1 ? E ? "/" : "." : E && L === 1 ? "//" : y.slice(0, L);
    }, basename: function(y, R) {
      if (R !== void 0 && typeof R != "string") throw new TypeError('"ext" argument must be a string');
      T(y);
      var E, L = 0, D = -1, x = !0;
      if (R !== void 0 && R.length > 0 && R.length <= y.length) {
        if (R.length === y.length && R === y) return "";
        var j = R.length - 1, F = -1;
        for (E = y.length - 1; E >= 0; --E) {
          var te = y.charCodeAt(E);
          if (te === 47) {
            if (!x) {
              L = E + 1;
              break;
            }
          } else F === -1 && (x = !1, F = E + 1), j >= 0 && (te === R.charCodeAt(j) ? --j == -1 && (D = E) : (j = -1, D = F));
        }
        return L === D ? D = F : D === -1 && (D = y.length), y.slice(L, D);
      }
      for (E = y.length - 1; E >= 0; --E) if (y.charCodeAt(E) === 47) {
        if (!x) {
          L = E + 1;
          break;
        }
      } else D === -1 && (x = !1, D = E + 1);
      return D === -1 ? "" : y.slice(L, D);
    }, extname: function(y) {
      T(y);
      for (var R = -1, E = 0, L = -1, D = !0, x = 0, j = y.length - 1; j >= 0; --j) {
        var F = y.charCodeAt(j);
        if (F !== 47) L === -1 && (D = !1, L = j + 1), F === 46 ? R === -1 ? R = j : x !== 1 && (x = 1) : R !== -1 && (x = -1);
        else if (!D) {
          E = j + 1;
          break;
        }
      }
      return R === -1 || L === -1 || x === 0 || x === 1 && R === L - 1 && R === E + 1 ? "" : y.slice(R, L);
    }, format: function(y) {
      if (y === null || typeof y != "object") throw new TypeError('The "pathObject" argument must be of type Object. Received type ' + typeof y);
      return (function(R, E) {
        var L = E.dir || E.root, D = E.base || (E.name || "") + (E.ext || "");
        return L ? L === E.root ? L + D : L + "/" + D : D;
      })(0, y);
    }, parse: function(y) {
      T(y);
      var R = { root: "", dir: "", base: "", ext: "", name: "" };
      if (y.length === 0) return R;
      var E, L = y.charCodeAt(0), D = L === 47;
      D ? (R.root = "/", E = 1) : E = 0;
      for (var x = -1, j = 0, F = -1, te = !0, z = y.length - 1, Q = 0; z >= E; --z) if ((L = y.charCodeAt(z)) !== 47) F === -1 && (te = !1, F = z + 1), L === 46 ? x === -1 ? x = z : Q !== 1 && (Q = 1) : x !== -1 && (Q = -1);
      else if (!te) {
        j = z + 1;
        break;
      }
      return x === -1 || F === -1 || Q === 0 || Q === 1 && x === F - 1 && x === j + 1 ? F !== -1 && (R.base = R.name = j === 0 && D ? y.slice(1, F) : y.slice(j, F)) : (j === 0 && D ? (R.name = y.slice(1, x), R.base = y.slice(1, F)) : (R.name = y.slice(j, x), R.base = y.slice(j, F)), R.ext = y.slice(x, F)), j > 0 ? R.dir = y.slice(0, j - 1) : D && (R.dir = "/"), R;
    }, sep: "/", delimiter: ":", win32: null, posix: null };
    $.posix = $, N.exports = $;
  } }, e = {};
  function r(N) {
    var T = e[N];
    if (T !== void 0) return T.exports;
    var g = e[N] = { exports: {} };
    return t[N](g, g.exports, r), g.exports;
  }
  r.d = (N, T) => {
    for (var g in T) r.o(T, g) && !r.o(N, g) && Object.defineProperty(N, g, { enumerable: !0, get: T[g] });
  }, r.o = (N, T) => Object.prototype.hasOwnProperty.call(N, T), r.r = (N) => {
    typeof Symbol < "u" && Symbol.toStringTag && Object.defineProperty(N, Symbol.toStringTag, { value: "Module" }), Object.defineProperty(N, "__esModule", { value: !0 });
  };
  var n = {};
  let i;
  r.r(n), r.d(n, { URI: () => p, Utils: () => oe }), typeof process == "object" ? i = process.platform === "win32" : typeof navigator == "object" && (i = navigator.userAgent.indexOf("Windows") >= 0);
  const a = /^\w[\w\d+.-]*$/, s = /^\//, o = /^\/\//;
  function l(N, T) {
    if (!N.scheme && T) throw new Error(`[UriError]: Scheme is missing: {scheme: "", authority: "${N.authority}", path: "${N.path}", query: "${N.query}", fragment: "${N.fragment}"}`);
    if (N.scheme && !a.test(N.scheme)) throw new Error("[UriError]: Scheme contains illegal characters.");
    if (N.path) {
      if (N.authority) {
        if (!s.test(N.path)) throw new Error('[UriError]: If a URI contains an authority component, then the path component must either be empty or begin with a slash ("/") character');
      } else if (o.test(N.path)) throw new Error('[UriError]: If a URI does not contain an authority component, then the path cannot begin with two slash characters ("//")');
    }
  }
  const c = "", u = "/", d = /^(([^:/?#]+?):)?(\/\/([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?/;
  class p {
    static isUri(T) {
      return T instanceof p || !!T && typeof T.authority == "string" && typeof T.fragment == "string" && typeof T.path == "string" && typeof T.query == "string" && typeof T.scheme == "string" && typeof T.fsPath == "string" && typeof T.with == "function" && typeof T.toString == "function";
    }
    scheme;
    authority;
    path;
    query;
    fragment;
    constructor(T, g, $, y, R, E = !1) {
      typeof T == "object" ? (this.scheme = T.scheme || c, this.authority = T.authority || c, this.path = T.path || c, this.query = T.query || c, this.fragment = T.fragment || c) : (this.scheme = /* @__PURE__ */ (function(L, D) {
        return L || D ? L : "file";
      })(T, E), this.authority = g || c, this.path = (function(L, D) {
        switch (L) {
          case "https":
          case "http":
          case "file":
            D ? D[0] !== u && (D = u + D) : D = u;
        }
        return D;
      })(this.scheme, $ || c), this.query = y || c, this.fragment = R || c, l(this, E));
    }
    get fsPath() {
      return S(this);
    }
    with(T) {
      if (!T) return this;
      let { scheme: g, authority: $, path: y, query: R, fragment: E } = T;
      return g === void 0 ? g = this.scheme : g === null && (g = c), $ === void 0 ? $ = this.authority : $ === null && ($ = c), y === void 0 ? y = this.path : y === null && (y = c), R === void 0 ? R = this.query : R === null && (R = c), E === void 0 ? E = this.fragment : E === null && (E = c), g === this.scheme && $ === this.authority && y === this.path && R === this.query && E === this.fragment ? this : new A(g, $, y, R, E);
    }
    static parse(T, g = !1) {
      const $ = d.exec(T);
      return $ ? new A($[2] || c, B($[4] || c), B($[5] || c), B($[7] || c), B($[9] || c), g) : new A(c, c, c, c, c);
    }
    static file(T) {
      let g = c;
      if (i && (T = T.replace(/\\/g, u)), T[0] === u && T[1] === u) {
        const $ = T.indexOf(u, 2);
        $ === -1 ? (g = T.substring(2), T = u) : (g = T.substring(2, $), T = T.substring($) || u);
      }
      return new A("file", g, T, c, c);
    }
    static from(T) {
      const g = new A(T.scheme, T.authority, T.path, T.query, T.fragment);
      return l(g, !0), g;
    }
    toString(T = !1) {
      return C(this, T);
    }
    toJSON() {
      return this;
    }
    static revive(T) {
      if (T) {
        if (T instanceof p) return T;
        {
          const g = new A(T);
          return g._formatted = T.external, g._fsPath = T._sep === m ? T.fsPath : null, g;
        }
      }
      return T;
    }
  }
  const m = i ? 1 : void 0;
  class A extends p {
    _formatted = null;
    _fsPath = null;
    get fsPath() {
      return this._fsPath || (this._fsPath = S(this)), this._fsPath;
    }
    toString(T = !1) {
      return T ? C(this, !0) : (this._formatted || (this._formatted = C(this, !1)), this._formatted);
    }
    toJSON() {
      const T = { $mid: 1 };
      return this._fsPath && (T.fsPath = this._fsPath, T._sep = m), this._formatted && (T.external = this._formatted), this.path && (T.path = this.path), this.scheme && (T.scheme = this.scheme), this.authority && (T.authority = this.authority), this.query && (T.query = this.query), this.fragment && (T.fragment = this.fragment), T;
    }
  }
  const b = { 58: "%3A", 47: "%2F", 63: "%3F", 35: "%23", 91: "%5B", 93: "%5D", 64: "%40", 33: "%21", 36: "%24", 38: "%26", 39: "%27", 40: "%28", 41: "%29", 42: "%2A", 43: "%2B", 44: "%2C", 59: "%3B", 61: "%3D", 32: "%20" };
  function I(N, T, g) {
    let $, y = -1;
    for (let R = 0; R < N.length; R++) {
      const E = N.charCodeAt(R);
      if (E >= 97 && E <= 122 || E >= 65 && E <= 90 || E >= 48 && E <= 57 || E === 45 || E === 46 || E === 95 || E === 126 || T && E === 47 || g && E === 91 || g && E === 93 || g && E === 58) y !== -1 && ($ += encodeURIComponent(N.substring(y, R)), y = -1), $ !== void 0 && ($ += N.charAt(R));
      else {
        $ === void 0 && ($ = N.substr(0, R));
        const L = b[E];
        L !== void 0 ? (y !== -1 && ($ += encodeURIComponent(N.substring(y, R)), y = -1), $ += L) : y === -1 && (y = R);
      }
    }
    return y !== -1 && ($ += encodeURIComponent(N.substring(y))), $ !== void 0 ? $ : N;
  }
  function k(N) {
    let T;
    for (let g = 0; g < N.length; g++) {
      const $ = N.charCodeAt(g);
      $ === 35 || $ === 63 ? (T === void 0 && (T = N.substr(0, g)), T += b[$]) : T !== void 0 && (T += N[g]);
    }
    return T !== void 0 ? T : N;
  }
  function S(N, T) {
    let g;
    return g = N.authority && N.path.length > 1 && N.scheme === "file" ? `//${N.authority}${N.path}` : N.path.charCodeAt(0) === 47 && (N.path.charCodeAt(1) >= 65 && N.path.charCodeAt(1) <= 90 || N.path.charCodeAt(1) >= 97 && N.path.charCodeAt(1) <= 122) && N.path.charCodeAt(2) === 58 ? N.path[1].toLowerCase() + N.path.substr(2) : N.path, i && (g = g.replace(/\//g, "\\")), g;
  }
  function C(N, T) {
    const g = T ? k : I;
    let $ = "", { scheme: y, authority: R, path: E, query: L, fragment: D } = N;
    if (y && ($ += y, $ += ":"), (R || y === "file") && ($ += u, $ += u), R) {
      let x = R.indexOf("@");
      if (x !== -1) {
        const j = R.substr(0, x);
        R = R.substr(x + 1), x = j.lastIndexOf(":"), x === -1 ? $ += g(j, !1, !1) : ($ += g(j.substr(0, x), !1, !1), $ += ":", $ += g(j.substr(x + 1), !1, !0)), $ += "@";
      }
      R = R.toLowerCase(), x = R.lastIndexOf(":"), x === -1 ? $ += g(R, !1, !0) : ($ += g(R.substr(0, x), !1, !0), $ += R.substr(x));
    }
    if (E) {
      if (E.length >= 3 && E.charCodeAt(0) === 47 && E.charCodeAt(2) === 58) {
        const x = E.charCodeAt(1);
        x >= 65 && x <= 90 && (E = `/${String.fromCharCode(x + 32)}:${E.substr(3)}`);
      } else if (E.length >= 2 && E.charCodeAt(1) === 58) {
        const x = E.charCodeAt(0);
        x >= 65 && x <= 90 && (E = `${String.fromCharCode(x + 32)}:${E.substr(2)}`);
      }
      $ += g(E, !0, !1);
    }
    return L && ($ += "?", $ += g(L, !1, !1)), D && ($ += "#", $ += T ? D : I(D, !1, !1)), $;
  }
  function P(N) {
    try {
      return decodeURIComponent(N);
    } catch {
      return N.length > 3 ? N.substr(0, 3) + P(N.substr(3)) : N;
    }
  }
  const W = /(%[0-9A-Za-z][0-9A-Za-z])+/g;
  function B(N) {
    return N.match(W) ? N.replace(W, ((T) => P(T))) : N;
  }
  var H = r(975);
  const ne = H.posix || H, se = "/";
  var oe;
  (function(N) {
    N.joinPath = function(T, ...g) {
      return T.with({ path: ne.join(T.path, ...g) });
    }, N.resolvePath = function(T, ...g) {
      let $ = T.path, y = !1;
      $[0] !== se && ($ = se + $, y = !0);
      let R = ne.resolve($, ...g);
      return y && R[0] === se && !T.authority && (R = R.substring(1)), T.with({ path: R });
    }, N.dirname = function(T) {
      if (T.path.length === 0 || T.path === se) return T;
      let g = ne.dirname(T.path);
      return g.length === 1 && g.charCodeAt(0) === 46 && (g = ""), T.with({ path: g });
    }, N.basename = function(T) {
      return ne.basename(T.path);
    }, N.extname = function(T) {
      return ne.extname(T.path);
    };
  })(oe || (oe = {})), Ed = n;
})();
const { URI: ft, Utils: xn } = Ed;
var Qe;
(function(t) {
  t.basename = xn.basename, t.dirname = xn.dirname, t.extname = xn.extname, t.joinPath = xn.joinPath, t.resolvePath = xn.resolvePath;
  const e = typeof process == "object" && process?.platform === "win32";
  function r(s, o) {
    return s?.toString() === o?.toString();
  }
  t.equals = r;
  function n(s, o) {
    const l = typeof s == "string" ? ft.parse(s).path : s.path, c = typeof o == "string" ? ft.parse(o).path : o.path, u = l.split("/").filter((b) => b.length > 0), d = c.split("/").filter((b) => b.length > 0);
    if (e) {
      const b = /^[A-Z]:$/;
      if (u[0] && b.test(u[0]) && (u[0] = u[0].toLowerCase()), d[0] && b.test(d[0]) && (d[0] = d[0].toLowerCase()), u[0] !== d[0])
        return c.substring(1);
    }
    let p = 0;
    for (; p < u.length && u[p] === d[p]; p++)
      ;
    const m = "../".repeat(u.length - p), A = d.slice(p).join("/");
    return m + A;
  }
  t.relative = n;
  function i(s) {
    return ft.parse(s.toString()).toString();
  }
  t.normalize = i;
  function a(s, o) {
    let l = typeof s == "string" ? s : s.path, c = typeof o == "string" ? o : o.path;
    return c.charAt(c.length - 1) === "/" && (c = c.slice(0, -1)), l.charAt(l.length - 1) === "/" && (l = l.slice(0, -1)), c === l ? !0 : c.length < l.length || c.charAt(l.length) !== "/" ? !1 : c.startsWith(l);
  }
  t.contains = a;
})(Qe || (Qe = {}));
class ly {
  constructor() {
    this.root = { name: "", children: /* @__PURE__ */ new Map() };
  }
  normalizeUri(e) {
    return Qe.normalize(e);
  }
  clear() {
    this.root.children.clear();
  }
  insert(e, r) {
    const n = this.getNode(this.normalizeUri(e), !0);
    n.element = r;
  }
  delete(e) {
    const r = this.getNode(this.normalizeUri(e), !1);
    r?.parent && r.parent.children.delete(r.name);
  }
  has(e) {
    return this.getNode(this.normalizeUri(e), !1)?.element !== void 0;
  }
  hasNode(e) {
    return this.getNode(this.normalizeUri(e), !1) !== void 0;
  }
  find(e) {
    return this.getNode(this.normalizeUri(e), !1)?.element;
  }
  findNode(e) {
    const r = this.normalizeUri(e), n = this.getNode(r, !1);
    if (n)
      return {
        name: n.name,
        uri: Qe.joinPath(ft.parse(r), n.name).toString(),
        element: n.element
      };
  }
  findChildren(e) {
    const r = this.normalizeUri(e), n = this.getNode(r, !1);
    return n ? Array.from(n.children.values()).map((i) => ({
      name: i.name,
      uri: Qe.joinPath(ft.parse(r), i.name).toString(),
      element: i.element
    })) : [];
  }
  all() {
    return this.collectValues(this.root);
  }
  findAll(e) {
    const r = this.getNode(Qe.normalize(e), !1);
    return r ? this.collectValues(r) : [];
  }
  getNode(e, r) {
    const n = e.split("/");
    e.charAt(e.length - 1) === "/" && n.pop();
    let i = this.root;
    for (const a of n) {
      let s = i.children.get(a);
      if (!s)
        if (r)
          s = {
            name: a,
            children: /* @__PURE__ */ new Map(),
            parent: i
          }, i.children.set(a, s);
        else
          return;
      i = s;
    }
    return i;
  }
  collectValues(e) {
    const r = [];
    e.element && r.push(e.element);
    for (const n of e.children.values())
      r.push(...this.collectValues(n));
    return r;
  }
}
var K;
(function(t) {
  t[t.Changed = 0] = "Changed", t[t.Parsed = 1] = "Parsed", t[t.IndexedContent = 2] = "IndexedContent", t[t.ComputedScopes = 3] = "ComputedScopes", t[t.Linked = 4] = "Linked", t[t.IndexedReferences = 5] = "IndexedReferences", t[t.Validated = 6] = "Validated";
})(K || (K = {}));
class cy {
  constructor(e) {
    this.serviceRegistry = e.ServiceRegistry, this.textDocuments = e.workspace.TextDocuments, this.fileSystemProvider = e.workspace.FileSystemProvider;
  }
  async fromUri(e, r = he.CancellationToken.None) {
    const n = await this.fileSystemProvider.readFile(e);
    return this.createAsync(e, n, r);
  }
  fromTextDocument(e, r, n) {
    return r = r ?? ft.parse(e.uri), he.CancellationToken.is(n) ? this.createAsync(r, e, n) : this.create(r, e, n);
  }
  fromString(e, r, n) {
    return he.CancellationToken.is(n) ? this.createAsync(r, e, n) : this.create(r, e, n);
  }
  fromModel(e, r) {
    return this.create(r, { $model: e });
  }
  create(e, r, n) {
    if (typeof r == "string") {
      const i = this.parse(e, r, n);
      return this.createLangiumDocument(i, e, void 0, r);
    } else if ("$model" in r) {
      const i = { value: r.$model, parserErrors: [], lexerErrors: [] };
      return this.createLangiumDocument(i, e);
    } else {
      const i = this.parse(e, r.getText(), n);
      return this.createLangiumDocument(i, e, r);
    }
  }
  async createAsync(e, r, n) {
    if (typeof r == "string") {
      const i = await this.parseAsync(e, r, n);
      return this.createLangiumDocument(i, e, void 0, r);
    } else {
      const i = await this.parseAsync(e, r.getText(), n);
      return this.createLangiumDocument(i, e, r);
    }
  }
  /**
   * Create a LangiumDocument from a given parse result.
   *
   * A TextDocument is created on demand if it is not provided as argument here. Usually this
   * should not be necessary because the main purpose of the TextDocument is to convert between
   * text ranges and offsets, which is done solely in LSP request handling.
   *
   * With the introduction of {@link update} below this method is supposed to be mainly called
   * during workspace initialization and on addition/recognition of new files, while changes in
   * existing documents are processed via {@link update}.
   */
  createLangiumDocument(e, r, n, i) {
    let a;
    if (n)
      a = {
        parseResult: e,
        uri: r,
        state: K.Parsed,
        references: [],
        textDocument: n
      };
    else {
      const s = this.createTextDocumentGetter(r, i);
      a = {
        parseResult: e,
        uri: r,
        state: K.Parsed,
        references: [],
        get textDocument() {
          return s();
        }
      };
    }
    return e.value.$document = a, a;
  }
  async update(e, r) {
    const n = e.parseResult.value.$cstNode?.root.fullText, i = this.textDocuments?.get(e.uri.toString()), a = i ? i.getText() : await this.fileSystemProvider.readFile(e.uri);
    if (i)
      Object.defineProperty(e, "textDocument", {
        value: i
      });
    else {
      const s = this.createTextDocumentGetter(e.uri, a);
      Object.defineProperty(e, "textDocument", {
        get: s
      });
    }
    return n !== a && (e.parseResult = await this.parseAsync(e.uri, a, r), e.parseResult.value.$document = e), e.state = K.Parsed, e;
  }
  parse(e, r, n) {
    return this.serviceRegistry.getServices(e).parser.LangiumParser.parse(r, n);
  }
  parseAsync(e, r, n) {
    return this.serviceRegistry.getServices(e).parser.AsyncParser.parse(r, n);
  }
  createTextDocumentGetter(e, r) {
    const n = this.serviceRegistry;
    let i;
    return () => i ?? (i = pl.create(e.toString(), n.getServices(e).LanguageMetaData.languageId, 0, r ?? ""));
  }
}
class uy {
  constructor(e) {
    this.documentTrie = new ly(), this.services = e, this.langiumDocumentFactory = e.workspace.LangiumDocumentFactory, this.documentBuilder = () => e.workspace.DocumentBuilder;
  }
  get all() {
    return fe(this.documentTrie.all());
  }
  addDocument(e) {
    const r = e.uri.toString();
    if (this.documentTrie.has(r))
      throw new Error(`A document with the URI '${r}' is already present.`);
    this.documentTrie.insert(r, e);
  }
  getDocument(e) {
    const r = e.toString();
    return this.documentTrie.find(r);
  }
  getDocuments(e) {
    const r = e.toString();
    return this.documentTrie.findAll(r);
  }
  async getOrCreateDocument(e, r) {
    let n = this.getDocument(e);
    return n || (n = await this.langiumDocumentFactory.fromUri(e, r), this.addDocument(n), n);
  }
  createDocument(e, r, n) {
    if (n)
      return this.langiumDocumentFactory.fromString(r, e, n).then((i) => (this.addDocument(i), i));
    {
      const i = this.langiumDocumentFactory.fromString(r, e);
      return this.addDocument(i), i;
    }
  }
  hasDocument(e) {
    return this.documentTrie.has(e.toString());
  }
  /**
   * @deprecated Since 4.2 use `DocumentBuilder.resetToState(DocumentState.Changed)` instead
   * TODO remove this for the next major release
   */
  invalidateDocument(e) {
    const r = e.toString(), n = this.documentTrie.find(r);
    return n && this.documentBuilder().resetToState(n, K.Changed), n;
  }
  deleteDocument(e) {
    const r = e.toString(), n = this.documentTrie.find(r);
    return n && (n.state = K.Changed, this.documentTrie.delete(r)), n;
  }
  deleteDocuments(e) {
    const r = e.toString(), n = this.documentTrie.findAll(r);
    for (const i of n)
      i.state = K.Changed;
    return this.documentTrie.delete(r), n;
  }
}
const Fr = Symbol("RefResolving");
class fy {
  constructor(e) {
    this.reflection = e.shared.AstReflection, this.langiumDocuments = () => e.shared.workspace.LangiumDocuments, this.scopeProvider = e.references.ScopeProvider, this.astNodeLocator = e.workspace.AstNodeLocator, this.profiler = e.shared.profilers.LangiumProfiler, this.languageId = e.LanguageMetaData.languageId;
  }
  async link(e, r = he.CancellationToken.None) {
    if (this.profiler?.isActive("linking")) {
      const n = this.profiler.createTask("linking", this.languageId);
      n.start();
      try {
        for (const i of jt(e.parseResult.value))
          await Ue(r), _a(i).forEach((a) => {
            const s = `${i.$type}:${a.property}`;
            n.startSubTask(s);
            try {
              this.doLink(a, e);
            } finally {
              n.stopSubTask(s);
            }
          });
      } finally {
        n.stop();
      }
    } else
      for (const n of jt(e.parseResult.value))
        await Ue(r), _a(n).forEach((i) => this.doLink(i, e));
  }
  doLink(e, r) {
    const n = e.reference;
    if ("_ref" in n && n._ref === void 0) {
      n._ref = Fr;
      try {
        const i = this.getCandidate(e);
        if (Nn(i))
          n._ref = i;
        else {
          n._nodeDescription = i;
          const a = this.loadAstNode(i);
          n._ref = a ?? this.createLinkingError(e, i);
        }
      } catch (i) {
        console.error(`An error occurred while resolving reference to '${n.$refText}':`, i);
        const a = i.message ?? String(i);
        n._ref = {
          info: e,
          message: `An error occurred while resolving reference to '${n.$refText}': ${a}`
        };
      }
      r.references.push(n);
    } else if ("_items" in n && n._items === void 0) {
      n._items = Fr;
      try {
        const i = this.getCandidates(e), a = [];
        if (Nn(i))
          n._linkingError = i;
        else
          for (const s of i) {
            const o = this.loadAstNode(s);
            o && a.push({ ref: o, $nodeDescription: s });
          }
        n._items = a;
      } catch (i) {
        n._linkingError = {
          info: e,
          message: `An error occurred while resolving reference to '${n.$refText}': ${i}`
        }, n._items = [];
      }
      r.references.push(n);
    }
  }
  unlink(e) {
    for (const r of e.references)
      "_ref" in r ? (r._ref = void 0, delete r._nodeDescription) : "_items" in r && (r._items = void 0, delete r._linkingError);
    e.references = [];
  }
  getCandidate(e) {
    return this.scopeProvider.getScope(e).getElement(e.reference.$refText) ?? this.createLinkingError(e);
  }
  getCandidates(e) {
    const n = this.scopeProvider.getScope(e).getElements(e.reference.$refText).distinct((i) => `${i.documentUri}#${i.path}`).toArray();
    return n.length > 0 ? n : this.createLinkingError(e);
  }
  buildReference(e, r, n, i) {
    const a = this, s = {
      $refNode: n,
      $refText: i,
      _ref: void 0,
      get ref() {
        if (Fe(this._ref))
          return this._ref;
        if (Kd(this._nodeDescription)) {
          const o = a.loadAstNode(this._nodeDescription);
          this._ref = o ?? a.createLinkingError({ reference: s, container: e, property: r }, this._nodeDescription);
        } else if (this._ref === void 0) {
          this._ref = Fr;
          const o = pa(e).$document, l = a.getLinkedNode({ reference: s, container: e, property: r });
          if (l.error && o && o.state < K.ComputedScopes)
            return this._ref = void 0;
          this._ref = l.node ?? l.error, this._nodeDescription = l.descr, o?.references.push(this);
        } else this._ref === Fr && a.throwCyclicReferenceError(e, r, i);
        return Fe(this._ref) ? this._ref : void 0;
      },
      get $nodeDescription() {
        return this._nodeDescription;
      },
      get error() {
        return Nn(this._ref) ? this._ref : void 0;
      }
    };
    return s;
  }
  buildMultiReference(e, r, n, i) {
    const a = this, s = {
      $refNode: n,
      $refText: i,
      _items: void 0,
      get items() {
        if (Array.isArray(this._items))
          return this._items;
        if (this._items === void 0) {
          this._items = Fr;
          const o = pa(e).$document, l = a.getCandidates({
            reference: s,
            container: e,
            property: r
          }), c = [];
          if (Nn(l))
            this._linkingError = l;
          else
            for (const u of l) {
              const d = a.loadAstNode(u);
              d && c.push({ ref: d, $nodeDescription: u });
            }
          this._items = c, o?.references.push(this);
        } else this._items === Fr && a.throwCyclicReferenceError(e, r, i);
        return Array.isArray(this._items) ? this._items : [];
      },
      get error() {
        if (this._linkingError)
          return this._linkingError;
        if (!(this.items.length > 0))
          return this._linkingError = a.createLinkingError({ reference: s, container: e, property: r });
      }
    };
    return s;
  }
  throwCyclicReferenceError(e, r, n) {
    throw new Error(`Cyclic reference resolution detected: ${this.astNodeLocator.getAstNodePath(e)}/${r} (symbol '${n}')`);
  }
  getLinkedNode(e) {
    try {
      const r = this.getCandidate(e);
      if (Nn(r))
        return { error: r };
      const n = this.loadAstNode(r);
      return n ? { node: n, descr: r } : {
        descr: r,
        error: this.createLinkingError(e, r)
      };
    } catch (r) {
      console.error(`An error occurred while resolving reference to '${e.reference.$refText}':`, r);
      const n = r.message ?? String(r);
      return {
        error: {
          info: e,
          message: `An error occurred while resolving reference to '${e.reference.$refText}': ${n}`
        }
      };
    }
  }
  loadAstNode(e) {
    if (e.node)
      return e.node;
    const r = this.langiumDocuments().getDocument(e.documentUri);
    if (r)
      return this.astNodeLocator.getAstNode(r.parseResult.value, e.path);
  }
  createLinkingError(e, r) {
    const n = pa(e.container).$document;
    n && n.state < K.ComputedScopes && console.warn(`Attempted reference resolution before document reached ComputedScopes state (${n.uri}).`);
    const i = this.reflection.getReferenceType(e);
    return {
      info: e,
      message: `Could not resolve reference to ${i} named '${e.reference.$refText}'.`,
      targetDescription: r
    };
  }
}
function dy(t) {
  return typeof t.name == "string";
}
class hy {
  getName(e) {
    if (dy(e))
      return e.name;
  }
  getNameNode(e) {
    return pf(e.$cstNode, "name");
  }
}
class py {
  constructor(e) {
    this.nameProvider = e.references.NameProvider, this.index = e.shared.workspace.IndexManager, this.nodeLocator = e.workspace.AstNodeLocator, this.documents = e.shared.workspace.LangiumDocuments, this.hasMultiReference = jt(e.Grammar).some((r) => Qa(r) && r.isMulti);
  }
  findDeclarations(e) {
    if (e) {
      const r = Mh(e), n = e.astNode;
      if (r && n) {
        const i = n[r.feature];
        if (ut(i) || Jt(i))
          return Ql(i);
        if (Array.isArray(i)) {
          for (const a of i)
            if ((ut(a) || Jt(a)) && a.$refNode && a.$refNode.offset <= e.offset && a.$refNode.end >= e.end)
              return Ql(a);
        }
      }
      if (n) {
        const i = this.nameProvider.getNameNode(n);
        if (i && (i === e || ph(e, i)))
          return this.getSelfNodes(n);
      }
    }
    return [];
  }
  /**
   * Returns all self-references for the specified node.
   * Since the node can be part of a multi-reference, this method returns all nodes that are part of the same multi-reference.
   */
  getSelfNodes(e) {
    if (this.hasMultiReference) {
      const r = this.index.findAllReferences(e, this.nodeLocator.getAstNodePath(e)), n = this.getNodeFromReferenceDescription(r.head());
      if (n) {
        for (const i of _a(n))
          if (Jt(i.reference) && i.reference.items.some((a) => a.ref === e))
            return i.reference.items.map((a) => a.ref);
      }
      return [e];
    } else
      return [e];
  }
  getNodeFromReferenceDescription(e) {
    if (!e)
      return;
    const r = this.documents.getDocument(e.sourceUri);
    if (r)
      return this.nodeLocator.getAstNode(r.parseResult.value, e.sourcePath);
  }
  findDeclarationNodes(e) {
    const r = this.findDeclarations(e), n = [];
    for (const i of r) {
      const a = this.nameProvider.getNameNode(i) ?? i.$cstNode;
      a && n.push(a);
    }
    return n;
  }
  findReferences(e, r) {
    const n = [];
    r.includeDeclaration && n.push(...this.getSelfReferences(e));
    let i = this.index.findAllReferences(e, this.nodeLocator.getAstNodePath(e));
    return r.documentUri && (i = i.filter((a) => Qe.equals(a.sourceUri, r.documentUri))), n.push(...i), fe(n);
  }
  getSelfReferences(e) {
    const r = this.getSelfNodes(e), n = [];
    for (const i of r) {
      const a = this.nameProvider.getNameNode(i);
      if (a) {
        const s = Gt(i), o = this.nodeLocator.getAstNodePath(i);
        n.push({
          sourceUri: s.uri,
          sourcePath: o,
          targetUri: s.uri,
          targetPath: o,
          segment: Pa(a),
          local: !0
        });
      }
    }
    return n;
  }
}
class Ri {
  constructor(e) {
    if (this.map = /* @__PURE__ */ new Map(), e)
      for (const [r, n] of e)
        this.add(r, n);
  }
  /**
   * The total number of values in the multimap.
   */
  get size() {
    return qs.sum(fe(this.map.values()).map((e) => e.length));
  }
  /**
   * Clear all entries in the multimap.
   */
  clear() {
    this.map.clear();
  }
  /**
   * Operates differently depending on whether a `value` is given:
   *  * With a value, this method deletes the specific key / value pair from the multimap.
   *  * Without a value, all values associated with the given key are deleted.
   *
   * @returns `true` if a value existed and has been removed, or `false` if the specified
   *     key / value does not exist.
   */
  delete(e, r) {
    if (r === void 0)
      return this.map.delete(e);
    {
      const n = this.map.get(e);
      if (n) {
        const i = n.indexOf(r);
        if (i >= 0)
          return n.length === 1 ? this.map.delete(e) : n.splice(i, 1), !0;
      }
      return !1;
    }
  }
  /**
   * Returns an array of all values associated with the given key. If no value exists,
   * an empty array is returned.
   *
   * _Note:_ The returned array is assumed not to be modified. Use the `set` method to add a
   * value and `delete` to remove a value from the multimap.
   */
  get(e) {
    return this.map.get(e) ?? [];
  }
  /**
   * Returns a stream of all values associated with the given key. If no value exists,
   * {@link EMPTY_STREAM} is returned.
   */
  getStream(e) {
    const r = this.map.get(e);
    return r ? fe(r) : rf;
  }
  /**
   * Operates differently depending on whether a `value` is given:
   *  * With a value, this method returns `true` if the specific key / value pair is present in the multimap.
   *  * Without a value, this method returns `true` if the given key is present in the multimap.
   */
  has(e, r) {
    if (r === void 0)
      return this.map.has(e);
    {
      const n = this.map.get(e);
      return n ? n.indexOf(r) >= 0 : !1;
    }
  }
  /**
   * Add the given key / value pair to the multimap.
   */
  add(e, r) {
    return this.map.has(e) ? this.map.get(e).push(r) : this.map.set(e, [r]), this;
  }
  /**
   * Add the given set of key / value pairs to the multimap.
   */
  addAll(e, r) {
    return this.map.has(e) ? this.map.get(e).push(...r) : this.map.set(e, Array.from(r)), this;
  }
  /**
   * Invokes the given callback function for every key / value pair in the multimap.
   */
  forEach(e) {
    this.map.forEach((r, n) => r.forEach((i) => e(i, n, this)));
  }
  /**
   * Returns an iterator of key, value pairs for every entry in the map.
   */
  [Symbol.iterator]() {
    return this.entries().iterator();
  }
  /**
   * Returns a stream of key, value pairs for every entry in the map.
   */
  entries() {
    return fe(this.map.entries()).flatMap(([e, r]) => r.map((n) => [e, n]));
  }
  /**
   * Returns a stream of keys in the map.
   */
  keys() {
    return fe(this.map.keys());
  }
  /**
   * Returns a stream of values in the map.
   */
  values() {
    return fe(this.map.values()).flat();
  }
  /**
   * Returns a stream of key, value set pairs for every key in the map.
   */
  entriesGroupedByKey() {
    return fe(this.map.entries());
  }
}
class Bc {
  get size() {
    return this.map.size;
  }
  constructor(e) {
    if (this.map = /* @__PURE__ */ new Map(), this.inverse = /* @__PURE__ */ new Map(), e)
      for (const [r, n] of e)
        this.set(r, n);
  }
  clear() {
    this.map.clear(), this.inverse.clear();
  }
  set(e, r) {
    return this.map.set(e, r), this.inverse.set(r, e), this;
  }
  get(e) {
    return this.map.get(e);
  }
  getKey(e) {
    return this.inverse.get(e);
  }
  delete(e) {
    const r = this.map.get(e);
    return r !== void 0 ? (this.map.delete(e), this.inverse.delete(r), !0) : !1;
  }
}
class my {
  constructor(e) {
    this.nameProvider = e.references.NameProvider, this.descriptions = e.workspace.AstNodeDescriptionProvider;
  }
  async collectExportedSymbols(e, r = he.CancellationToken.None) {
    return this.collectExportedSymbolsForNode(e.parseResult.value, e, void 0, r);
  }
  /**
   * Creates {@link AstNodeDescription AstNodeDescriptions} for the given {@link AstNode parentNode} and its children.
   * The list of children to be considered is determined by the function parameter {@link children}.
   * By default only the direct children of {@link parentNode} are visited, nested nodes are not exported.
   *
   * @param parentNode AST node to be exported, i.e., of which an {@link AstNodeDescription} shall be added to the returned list.
   * @param document The document containing the AST node to be exported.
   * @param children A function called with {@link parentNode} as single argument and returning an {@link Iterable} supplying the children to be visited, which must be directly or transitively contained in {@link parentNode}.
   * @param cancelToken Indicates when to cancel the current operation.
   * @throws `OperationCancelled` if a user action occurs during execution.
   * @returns A list of {@link AstNodeDescription AstNodeDescriptions} to be published to index.
   */
  async collectExportedSymbolsForNode(e, r, n = _l, i = he.CancellationToken.None) {
    const a = [];
    this.addExportedSymbol(e, a, r);
    for (const s of n(e))
      await Ue(i), this.addExportedSymbol(s, a, r);
    return a;
  }
  /**
   * Adds a single node to the list of exports if it has a name. Override this method to change how
   * symbols are exported, e.g. by modifying their exported name.
   */
  addExportedSymbol(e, r, n) {
    const i = this.nameProvider.getName(e);
    i && r.push(this.descriptions.createDescription(e, i, n));
  }
  // --- local symbols gathering ---
  async collectLocalSymbols(e, r = he.CancellationToken.None) {
    const n = e.parseResult.value, i = new Ri();
    for (const a of Ei(n))
      await Ue(r), this.addLocalSymbol(a, e, i);
    return i;
  }
  /**
   * Adds a single node to the local symbols of its containing document if it has a name.
   * The default implementation makes the node visible in the subtree of its container if it does have a container.
   * Override this method to change this, e.g. by increasing the visibility to a higher level in the AST.
   */
  addLocalSymbol(e, r, n) {
    const i = e.$container;
    if (i) {
      const a = this.nameProvider.getName(e);
      a && n.add(i, this.descriptions.createDescription(e, a, r));
    }
  }
}
class Wc {
  constructor(e, r, n) {
    this.elements = e, this.outerScope = r, this.caseInsensitive = n?.caseInsensitive ?? !1, this.concatOuterScope = n?.concatOuterScope ?? !0;
  }
  getAllElements() {
    return this.outerScope ? this.elements.concat(this.outerScope.getAllElements()) : this.elements;
  }
  getElement(e) {
    const r = this.caseInsensitive ? e.toLowerCase() : e, n = this.caseInsensitive ? this.elements.find((i) => i.name.toLowerCase() === r) : this.elements.find((i) => i.name === e);
    if (n)
      return n;
    if (this.outerScope)
      return this.outerScope.getElement(e);
  }
  getElements(e) {
    const r = this.caseInsensitive ? e.toLowerCase() : e, n = this.caseInsensitive ? this.elements.filter((i) => i.name.toLowerCase() === r) : this.elements.filter((i) => i.name === e);
    return (this.concatOuterScope || n.isEmpty()) && this.outerScope ? n.concat(this.outerScope.getElements(e)) : n;
  }
}
class gy {
  constructor(e, r, n) {
    this.elements = new Ri(), this.caseInsensitive = n?.caseInsensitive ?? !1, this.concatOuterScope = n?.concatOuterScope ?? !0;
    for (const i of e) {
      const a = this.caseInsensitive ? i.name.toLowerCase() : i.name;
      this.elements.add(a, i);
    }
    this.outerScope = r;
  }
  getElement(e) {
    const r = this.caseInsensitive ? e.toLowerCase() : e, n = this.elements.get(r)[0];
    if (n)
      return n;
    if (this.outerScope)
      return this.outerScope.getElement(e);
  }
  getElements(e) {
    const r = this.caseInsensitive ? e.toLowerCase() : e, n = this.elements.get(r);
    return (this.concatOuterScope || n.length === 0) && this.outerScope ? fe(n).concat(this.outerScope.getElements(e)) : fe(n);
  }
  getAllElements() {
    let e = fe(this.elements.values());
    return this.outerScope && (e = e.concat(this.outerScope.getAllElements())), e;
  }
}
class Ad {
  constructor() {
    this.toDispose = [], this.isDisposed = !1;
  }
  onDispose(e) {
    this.toDispose.push(e);
  }
  dispose() {
    this.throwIfDisposed(), this.clear(), this.isDisposed = !0, this.toDispose.forEach((e) => e.dispose());
  }
  throwIfDisposed() {
    if (this.isDisposed)
      throw new Error("This cache has already been disposed");
  }
}
class yy extends Ad {
  constructor() {
    super(...arguments), this.cache = /* @__PURE__ */ new Map();
  }
  has(e) {
    return this.throwIfDisposed(), this.cache.has(e);
  }
  set(e, r) {
    this.throwIfDisposed(), this.cache.set(e, r);
  }
  get(e, r) {
    if (this.throwIfDisposed(), this.cache.has(e))
      return this.cache.get(e);
    if (r) {
      const n = r();
      return this.cache.set(e, n), n;
    } else
      return;
  }
  delete(e) {
    return this.throwIfDisposed(), this.cache.delete(e);
  }
  clear() {
    this.throwIfDisposed(), this.cache.clear();
  }
}
class Ty extends Ad {
  constructor(e) {
    super(), this.cache = /* @__PURE__ */ new Map(), this.converter = e ?? ((r) => r);
  }
  has(e, r) {
    return this.throwIfDisposed(), this.cacheForContext(e).has(r);
  }
  set(e, r, n) {
    this.throwIfDisposed(), this.cacheForContext(e).set(r, n);
  }
  get(e, r, n) {
    this.throwIfDisposed();
    const i = this.cacheForContext(e);
    if (i.has(r))
      return i.get(r);
    if (n) {
      const a = n();
      return i.set(r, a), a;
    } else
      return;
  }
  delete(e, r) {
    return this.throwIfDisposed(), this.cacheForContext(e).delete(r);
  }
  clear(e) {
    if (this.throwIfDisposed(), e) {
      const r = this.converter(e);
      this.cache.delete(r);
    } else
      this.cache.clear();
  }
  cacheForContext(e) {
    const r = this.converter(e);
    let n = this.cache.get(r);
    return n || (n = /* @__PURE__ */ new Map(), this.cache.set(r, n)), n;
  }
}
class Ry extends yy {
  /**
   * Creates a new workspace cache.
   *
   * @param sharedServices Service container instance to hook into document lifecycle events.
   * @param state Optional document state on which the cache should evict.
   * If not provided, the cache will evict on `DocumentBuilder#onUpdate`.
   * *Deleted* documents are considered in both cases.
   */
  constructor(e, r) {
    super(), r ? (this.toDispose.push(e.workspace.DocumentBuilder.onBuildPhase(r, () => {
      this.clear();
    })), this.toDispose.push(e.workspace.DocumentBuilder.onUpdate((n, i) => {
      i.length > 0 && this.clear();
    }))) : this.toDispose.push(e.workspace.DocumentBuilder.onUpdate(() => {
      this.clear();
    }));
  }
}
class vy {
  constructor(e) {
    this.reflection = e.shared.AstReflection, this.nameProvider = e.references.NameProvider, this.descriptions = e.workspace.AstNodeDescriptionProvider, this.indexManager = e.shared.workspace.IndexManager, this.globalScopeCache = new Ry(e.shared);
  }
  getScope(e) {
    const r = [], n = this.reflection.getReferenceType(e), i = Gt(e.container).localSymbols;
    if (i) {
      let s = e.container;
      do
        i.has(s) && r.push(i.getStream(s).filter((o) => this.reflection.isSubtype(o.type, n))), s = s.$container;
      while (s);
    }
    let a = this.getGlobalScope(n, e);
    for (let s = r.length - 1; s >= 0; s--)
      a = this.createScope(r[s], a);
    return a;
  }
  /**
   * Create a scope for the given collection of AST node descriptions.
   */
  createScope(e, r, n) {
    return new Wc(fe(e), r, n);
  }
  /**
   * Create a scope for the given collection of AST nodes, which need to be transformed into respective
   * descriptions first. This is done using the `NameProvider` and `AstNodeDescriptionProvider` services.
   */
  createScopeForNodes(e, r, n) {
    const i = fe(e).map((a) => {
      const s = this.nameProvider.getName(a);
      if (s)
        return this.descriptions.createDescription(a, s);
    }).nonNullable();
    return new Wc(i, r, n);
  }
  /**
   * Create a global scope filtered for the given reference type.
   */
  getGlobalScope(e, r) {
    return this.globalScopeCache.get(e, () => new gy(this.indexManager.allElements(e)));
  }
}
function Ey(t) {
  return typeof t.$comment == "string";
}
function Kc(t) {
  return typeof t == "object" && !!t && ("$ref" in t || "$error" in t);
}
class Ay {
  constructor(e) {
    this.ignoreProperties = /* @__PURE__ */ new Set(["$container", "$containerProperty", "$containerIndex", "$document", "$cstNode"]), this.langiumDocuments = e.shared.workspace.LangiumDocuments, this.astNodeLocator = e.workspace.AstNodeLocator, this.nameProvider = e.references.NameProvider, this.commentProvider = e.documentation.CommentProvider;
  }
  serialize(e, r) {
    const n = r ?? {}, i = r?.replacer, a = (o, l) => this.replacer(o, l, n), s = i ? (o, l) => i(o, l, a) : a;
    try {
      return this.currentDocument = Gt(e), JSON.stringify(e, s, r?.space);
    } finally {
      this.currentDocument = void 0;
    }
  }
  deserialize(e, r) {
    const n = r ?? {}, i = JSON.parse(e);
    return this.linkNode(i, i, n), i;
  }
  replacer(e, r, { refText: n, sourceText: i, textRegions: a, comments: s, uriConverter: o }) {
    if (!this.ignoreProperties.has(e))
      if (ut(r)) {
        const l = r.ref, c = n ? r.$refText : void 0;
        if (l) {
          const u = Gt(l);
          let d = "";
          this.currentDocument && this.currentDocument !== u && (o ? d = o(u.uri, l) : d = u.uri.toString());
          const p = this.astNodeLocator.getAstNodePath(l);
          return {
            $ref: `${d}#${p}`,
            $refText: c
          };
        } else
          return {
            $error: r.error?.message ?? "Could not resolve reference",
            $refText: c
          };
      } else if (Jt(r)) {
        const l = n ? r.$refText : void 0, c = [];
        for (const u of r.items) {
          const d = u.ref, p = Gt(u.ref);
          let m = "";
          this.currentDocument && this.currentDocument !== p && (o ? m = o(p.uri, d) : m = p.uri.toString());
          const A = this.astNodeLocator.getAstNodePath(d);
          c.push(`${m}#${A}`);
        }
        return {
          $refs: c,
          $refText: l
        };
      } else if (Fe(r)) {
        let l;
        if (a && (l = this.addAstNodeRegionWithAssignmentsTo({ ...r }), (!e || r.$document) && l?.$textRegion && (l.$textRegion.documentURI = this.currentDocument?.uri.toString())), i && !e && (l ?? (l = { ...r }), l.$sourceText = r.$cstNode?.text), s) {
          l ?? (l = { ...r });
          const c = this.commentProvider.getComment(r);
          c && (l.$comment = c.replace(/\r/g, ""));
        }
        return l ?? r;
      } else
        return r;
  }
  addAstNodeRegionWithAssignmentsTo(e) {
    const r = (n) => ({
      offset: n.offset,
      end: n.end,
      length: n.length,
      range: n.range
    });
    if (e.$cstNode) {
      const n = e.$textRegion = r(e.$cstNode), i = n.assignments = {};
      return Object.keys(e).filter((a) => !a.startsWith("$")).forEach((a) => {
        const s = Lh(e.$cstNode, a).map(r);
        s.length !== 0 && (i[a] = s);
      }), e;
    }
  }
  linkNode(e, r, n, i, a, s) {
    for (const [l, c] of Object.entries(e))
      if (Array.isArray(c))
        for (let u = 0; u < c.length; u++) {
          const d = c[u];
          Kc(d) ? c[u] = this.reviveReference(e, l, r, d, n) : Fe(d) && this.linkNode(d, r, n, e, l, u);
        }
      else Kc(c) ? e[l] = this.reviveReference(e, l, r, c, n) : Fe(c) && this.linkNode(c, r, n, e, l);
    const o = e;
    o.$container = i, o.$containerProperty = a, o.$containerIndex = s;
  }
  reviveReference(e, r, n, i, a) {
    let s = i.$refText, o = i.$error, l;
    if (i.$ref) {
      const c = this.getRefNode(n, i.$ref, a.uriConverter);
      if (Fe(c))
        return s || (s = this.nameProvider.getName(c)), {
          $refText: s ?? "",
          ref: c
        };
      o = c;
    } else if (i.$refs) {
      const c = [];
      for (const u of i.$refs) {
        const d = this.getRefNode(n, u, a.uriConverter);
        Fe(d) && c.push({ ref: d });
      }
      if (c.length === 0)
        l = {
          $refText: s ?? "",
          items: c
        }, o ?? (o = "Could not resolve multi-reference");
      else
        return {
          $refText: s ?? "",
          items: c
        };
    }
    if (o)
      return l ?? (l = {
        $refText: s ?? "",
        ref: void 0
      }), l.error = {
        info: {
          container: e,
          property: r,
          reference: l
        },
        message: o
      }, l;
  }
  getRefNode(e, r, n) {
    try {
      const i = r.indexOf("#");
      if (i === 0) {
        const l = this.astNodeLocator.getAstNode(e, r.substring(1));
        return l || "Could not resolve path: " + r;
      }
      if (i < 0) {
        const l = n ? n(r) : ft.parse(r), c = this.langiumDocuments.getDocument(l);
        return c ? c.parseResult.value : "Could not find document for URI: " + r;
      }
      const a = n ? n(r.substring(0, i)) : ft.parse(r.substring(0, i)), s = this.langiumDocuments.getDocument(a);
      if (!s)
        return "Could not find document for URI: " + r;
      if (i === r.length - 1)
        return s.parseResult.value;
      const o = this.astNodeLocator.getAstNode(s.parseResult.value, r.substring(i + 1));
      return o || "Could not resolve URI: " + r;
    } catch (i) {
      return String(i);
    }
  }
}
class $y {
  /**
   * @deprecated Since 3.1.0. Use the new `fileExtensionMap` (or `languageIdMap`) property instead.
   */
  get map() {
    return this.fileExtensionMap;
  }
  constructor(e) {
    this.languageIdMap = /* @__PURE__ */ new Map(), this.fileExtensionMap = /* @__PURE__ */ new Map(), this.fileNameMap = /* @__PURE__ */ new Map(), this.textDocuments = e?.workspace.TextDocuments;
  }
  register(e) {
    const r = e.LanguageMetaData;
    for (const n of r.fileExtensions)
      this.fileExtensionMap.has(n) && console.warn(`The file extension ${n} is used by multiple languages. It is now assigned to '${r.languageId}'.`), this.fileExtensionMap.set(n, e);
    if (r.fileNames)
      for (const n of r.fileNames)
        this.fileNameMap.has(n) && console.warn(`The file name ${n} is used by multiple languages. It is now assigned to '${r.languageId}'.`), this.fileNameMap.set(n, e);
    this.languageIdMap.set(r.languageId, e);
  }
  getServices(e) {
    if (this.languageIdMap.size === 0)
      throw new Error("The service registry is empty. Use `register` to register the services of a language.");
    const r = this.textDocuments?.get(e)?.languageId;
    if (r !== void 0) {
      const s = this.languageIdMap.get(r);
      if (s)
        return s;
    }
    const n = Qe.extname(e), i = Qe.basename(e), a = this.fileNameMap.get(i) ?? this.fileExtensionMap.get(n);
    if (!a)
      throw r ? new Error(`The service registry contains no services for the extension '${n}' for language '${r}'.`) : new Error(`The service registry contains no services for the extension '${n}'.`);
    return a;
  }
  hasServices(e) {
    try {
      return this.getServices(e), !0;
    } catch {
      return !1;
    }
  }
  get all() {
    return Array.from(this.languageIdMap.values());
  }
}
function si(t) {
  return { code: t };
}
var gl;
(function(t) {
  t.defaults = ["fast", "slow", "built-in"], t.all = t.defaults;
})(gl || (gl = {}));
class Cy {
  constructor(e) {
    this.entries = new Ri(), this.knownCategories = new Set(gl.defaults), this.entriesBefore = [], this.entriesAfter = [], this.reflection = e.shared.AstReflection;
  }
  /**
   * Register a set of validation checks. Each value in the record can be either a single validation check (i.e. a function)
   * or an array of validation checks.
   *
   * @param checksRecord Set of validation checks to register.
   * @param thisObj Optional object to be used as `this` when calling the validation check functions.
   * @param category Optional category for the validation checks (defaults to `'fast'`).
   */
  register(e, r = this, n = "fast") {
    if (n === "built-in")
      throw new Error("The 'built-in' category is reserved for lexer, parser, and linker errors.");
    this.knownCategories.add(n);
    for (const [i, a] of Object.entries(e)) {
      const s = a;
      if (Array.isArray(s))
        for (const o of s) {
          const l = {
            check: this.wrapValidationException(o, r),
            category: n
          };
          this.addEntry(i, l);
        }
      else if (typeof s == "function") {
        const o = {
          check: this.wrapValidationException(s, r),
          category: n
        };
        this.addEntry(i, o);
      } else
        $i();
    }
  }
  wrapValidationException(e, r) {
    return async (n, i, a) => {
      await this.handleException(() => e.call(r, n, i, a), "An error occurred during validation", i, n);
    };
  }
  async handleException(e, r, n, i) {
    try {
      await e();
    } catch (a) {
      if (fs(a))
        throw a;
      console.error(`${r}:`, a), a instanceof Error && a.stack && console.error(a.stack);
      const s = a instanceof Error ? a.message : String(a);
      n("error", `${r}: ${s}`, { node: i });
    }
  }
  addEntry(e, r) {
    if (e === "AstNode") {
      this.entries.add("AstNode", r);
      return;
    }
    for (const n of this.reflection.getAllSubTypes(e))
      this.entries.add(n, r);
  }
  getChecks(e, r) {
    let n = fe(this.entries.get(e)).concat(this.entries.get("AstNode"));
    return r && (n = n.filter((i) => r.includes(i.category))), n.map((i) => i.check);
  }
  /**
   * Register logic which will be executed once before validating all the nodes of an AST/Langium document.
   * This helps to prepare or initialize some information which are required or reusable for the following checks on the AstNodes.
   *
   * As an example, for validating unique fully-qualified names of nodes in the AST,
   * here the map for mapping names to nodes could be established.
   * During the usual checks on the nodes, they are put into this map with their name.
   *
   * Note that this approach makes validations stateful, which is relevant e.g. when cancelling the validation.
   * Therefore it is recommended to clear stored information
   * _before_ validating an AST to validate each AST unaffected from other ASTs
   * AND _after_ validating the AST to free memory by information which are no longer used.
   *
   * @param checkBefore a set-up function which will be called once before actually validating an AST
   * @param thisObj Optional object to be used as `this` when calling the validation check functions.
   */
  registerBeforeDocument(e, r = this) {
    this.entriesBefore.push(this.wrapPreparationException(e, "An error occurred during set-up of the validation", r));
  }
  /**
   * Register logic which will be executed once after validating all the nodes of an AST/Langium document.
   * This helps to finally evaluate information which are collected during the checks on the AstNodes.
   *
   * As an example, for validating unique fully-qualified names of nodes in the AST,
   * here the map with all the collected nodes and their names is checked
   * and validation hints are created for all nodes with the same name.
   *
   * Note that this approach makes validations stateful, which is relevant e.g. when cancelling the validation.
   * Therefore it is recommended to clear stored information
   * _before_ validating an AST to validate each AST unaffected from other ASTs
   * AND _after_ validating the AST to free memory by information which are no longer used.
   *
   * @param checkBefore a set-up function which will be called once before actually validating an AST
   * @param thisObj Optional object to be used as `this` when calling the validation check functions.
   */
  registerAfterDocument(e, r = this) {
    this.entriesAfter.push(this.wrapPreparationException(e, "An error occurred during tear-down of the validation", r));
  }
  wrapPreparationException(e, r, n) {
    return async (i, a, s, o) => {
      await this.handleException(() => e.call(n, i, a, s, o), r, a, i);
    };
  }
  get checksBefore() {
    return this.entriesBefore;
  }
  get checksAfter() {
    return this.entriesAfter;
  }
  getAllValidationCategories(e) {
    return this.knownCategories;
  }
}
const Sy = Object.freeze({
  validateNode: !0,
  validateChildren: !0
});
class ky {
  constructor(e) {
    this.validationRegistry = e.validation.ValidationRegistry, this.metadata = e.LanguageMetaData, this.profiler = e.shared.profilers.LangiumProfiler, this.languageId = e.LanguageMetaData.languageId;
  }
  async validateDocument(e, r = {}, n = he.CancellationToken.None) {
    const i = e.parseResult, a = [];
    if (await Ue(n), (!r.categories || r.categories.includes("built-in")) && (this.processLexingErrors(i, a, r), r.stopAfterLexingErrors && a.some((s) => s.data?.code === ct.LexingError) || (this.processParsingErrors(i, a, r), r.stopAfterParsingErrors && a.some((s) => s.data?.code === ct.ParsingError)) || (this.processLinkingErrors(e, a, r), r.stopAfterLinkingErrors && a.some((s) => s.data?.code === ct.LinkingError))))
      return a;
    try {
      a.push(...await this.validateAst(i.value, r, n));
    } catch (s) {
      if (fs(s))
        throw s;
      console.error("An error occurred during validation:", s);
    }
    return await Ue(n), a;
  }
  processLexingErrors(e, r, n) {
    const i = [...e.lexerErrors, ...e.lexerReport?.diagnostics ?? []];
    for (const a of i) {
      const s = a.severity ?? "error", o = {
        severity: Ss(s),
        range: {
          start: {
            line: a.line - 1,
            character: a.column - 1
          },
          end: {
            line: a.line - 1,
            character: a.column + a.length - 1
          }
        },
        message: a.message,
        data: by(s),
        source: this.getSource()
      };
      r.push(o);
    }
  }
  processParsingErrors(e, r, n) {
    for (const i of e.parserErrors) {
      let a;
      if (isNaN(i.token.startOffset)) {
        if ("previousToken" in i) {
          const s = i.previousToken;
          if (isNaN(s.startOffset)) {
            const o = { line: 0, character: 0 };
            a = { start: o, end: o };
          } else {
            const o = { line: s.endLine - 1, character: s.endColumn };
            a = { start: o, end: o };
          }
        }
      } else
        a = Zs(i.token);
      if (a) {
        const s = {
          severity: Ss("error"),
          range: a,
          message: i.message,
          data: si(ct.ParsingError),
          source: this.getSource()
        };
        r.push(s);
      }
    }
  }
  processLinkingErrors(e, r, n) {
    for (const i of e.references) {
      const a = i.error;
      if (a) {
        const s = {
          node: a.info.container,
          range: i.$refNode?.range,
          property: a.info.property,
          index: a.info.index,
          data: {
            code: ct.LinkingError,
            containerType: a.info.container.$type,
            property: a.info.property,
            refText: a.info.reference.$refText
          }
        };
        r.push(this.toDiagnostic("error", a.message, s));
      }
    }
  }
  async validateAst(e, r, n = he.CancellationToken.None) {
    const i = [], a = (s, o, l) => {
      i.push(this.toDiagnostic(s, o, l));
    };
    return await this.validateAstBefore(e, r, a, n), await this.validateAstNodes(e, r, a, n), await this.validateAstAfter(e, r, a, n), i;
  }
  async validateAstBefore(e, r, n, i = he.CancellationToken.None) {
    const a = this.validationRegistry.checksBefore;
    for (const s of a)
      await Ue(i), await s(e, n, r.categories ?? [], i);
  }
  async validateAstNodes(e, r, n, i = he.CancellationToken.None) {
    if (this.profiler?.isActive("validating")) {
      const a = this.profiler.createTask("validating", this.languageId);
      a.start();
      try {
        const s = jt(e).iterator();
        for (const o of s) {
          a.startSubTask(o.$type);
          const l = this.validateSingleNodeOptions(o, r);
          if (l.validateNode)
            try {
              const c = this.validationRegistry.getChecks(o.$type, r.categories);
              for (const u of c)
                await u(o, n, i);
            } finally {
              a.stopSubTask(o.$type);
            }
          l.validateChildren || s.prune();
        }
      } finally {
        a.stop();
      }
    } else {
      const a = jt(e).iterator();
      for (const s of a) {
        await Ue(i);
        const o = this.validateSingleNodeOptions(s, r);
        if (o.validateNode) {
          const l = this.validationRegistry.getChecks(s.$type, r.categories);
          for (const c of l)
            await c(s, n, i);
        }
        o.validateChildren || a.prune();
      }
    }
  }
  validateSingleNodeOptions(e, r) {
    return Sy;
  }
  async validateAstAfter(e, r, n, i = he.CancellationToken.None) {
    const a = this.validationRegistry.checksAfter;
    for (const s of a)
      await Ue(i), await s(e, n, r.categories ?? [], i);
  }
  toDiagnostic(e, r, n) {
    return {
      message: r,
      range: wy(n),
      severity: Ss(e),
      code: n.code,
      codeDescription: n.codeDescription,
      tags: n.tags,
      relatedInformation: n.relatedInformation,
      data: n.data,
      source: this.getSource()
    };
  }
  getSource() {
    return this.metadata.languageId;
  }
}
function wy(t) {
  if (t.range)
    return t.range;
  let e;
  return typeof t.property == "string" ? e = pf(t.node.$cstNode, t.property, t.index) : typeof t.keyword == "string" && (e = xh(t.node.$cstNode, t.keyword, t.index)), e ?? (e = t.node.$cstNode), e ? e.range : {
    start: { line: 0, character: 0 },
    end: { line: 0, character: 0 }
  };
}
function Ss(t) {
  switch (t) {
    case "error":
      return 1;
    case "warning":
      return 2;
    case "info":
      return 3;
    case "hint":
      return 4;
    default:
      throw new Error("Invalid diagnostic severity: " + t);
  }
}
function by(t) {
  switch (t) {
    case "error":
      return si(ct.LexingError);
    case "warning":
      return si(ct.LexingWarning);
    case "info":
      return si(ct.LexingInfo);
    case "hint":
      return si(ct.LexingHint);
    default:
      throw new Error("Invalid diagnostic severity: " + t);
  }
}
var ct;
(function(t) {
  t.LexingError = "lexing-error", t.LexingWarning = "lexing-warning", t.LexingInfo = "lexing-info", t.LexingHint = "lexing-hint", t.ParsingError = "parsing-error", t.LinkingError = "linking-error";
})(ct || (ct = {}));
class Ny {
  constructor(e) {
    this.astNodeLocator = e.workspace.AstNodeLocator, this.nameProvider = e.references.NameProvider;
  }
  createDescription(e, r, n) {
    const i = n ?? Gt(e);
    r ?? (r = this.nameProvider.getName(e));
    const a = this.astNodeLocator.getAstNodePath(e);
    if (!r)
      throw new Error(`Node at path ${a} has no name.`);
    let s;
    const o = () => s ?? (s = Pa(this.nameProvider.getNameNode(e) ?? e.$cstNode));
    return {
      node: e,
      name: r,
      get nameSegment() {
        return o();
      },
      selectionSegment: Pa(e.$cstNode),
      type: e.$type,
      documentUri: i.uri,
      path: a
    };
  }
}
class _y {
  constructor(e) {
    this.nodeLocator = e.workspace.AstNodeLocator;
  }
  async createDescriptions(e, r = he.CancellationToken.None) {
    const n = [], i = e.parseResult.value;
    for (const a of jt(i))
      await Ue(r), _a(a).forEach((s) => {
        s.reference.error || n.push(...this.createInfoDescriptions(s));
      });
    return n;
  }
  createInfoDescriptions(e) {
    const r = e.reference;
    if (r.error || !r.$refNode)
      return [];
    let n = [];
    ut(r) && r.$nodeDescription ? n = [r.$nodeDescription] : Jt(r) && (n = r.items.map((l) => l.$nodeDescription).filter((l) => l !== void 0));
    const i = Gt(e.container).uri, a = this.nodeLocator.getAstNodePath(e.container), s = [], o = Pa(r.$refNode);
    for (const l of n)
      s.push({
        sourceUri: i,
        sourcePath: a,
        targetUri: l.documentUri,
        targetPath: l.path,
        segment: o,
        local: Qe.equals(l.documentUri, i)
      });
    return s;
  }
}
class Iy {
  constructor() {
    this.segmentSeparator = "/", this.indexSeparator = "@";
  }
  getAstNodePath(e) {
    if (e.$container) {
      const r = this.getAstNodePath(e.$container), n = this.getPathSegment(e);
      return r + this.segmentSeparator + n;
    }
    return "";
  }
  getPathSegment({ $containerProperty: e, $containerIndex: r }) {
    if (!e)
      throw new Error("Missing '$containerProperty' in AST node.");
    return r !== void 0 ? e + this.indexSeparator + r : e;
  }
  getAstNode(e, r) {
    return r.split(this.segmentSeparator).reduce((i, a) => {
      if (!i || a.length === 0)
        return i;
      const s = a.indexOf(this.indexSeparator);
      if (s > 0) {
        const o = a.substring(0, s), l = parseInt(a.substring(s + 1));
        return i[o]?.[l];
      }
      return i[a];
    }, e);
  }
}
var Py = mn();
class Oy {
  constructor(e) {
    this._ready = new Hl(), this.onConfigurationSectionUpdateEmitter = new Py.Emitter(), this.settings = {}, this.workspaceConfig = !1, this.serviceRegistry = e.ServiceRegistry;
  }
  get ready() {
    return this._ready.promise;
  }
  initialize(e) {
    this.workspaceConfig = e.capabilities.workspace?.configuration ?? !1;
  }
  async initialized(e) {
    if (this.workspaceConfig) {
      if (e.register) {
        const r = this.serviceRegistry.all;
        e.register({
          // Listen to configuration changes for all languages
          section: r.map((n) => this.toSectionName(n.LanguageMetaData.languageId))
        });
      }
      if (e.fetchConfiguration) {
        const r = this.serviceRegistry.all.map((i) => ({
          // Fetch the configuration changes for all languages
          section: this.toSectionName(i.LanguageMetaData.languageId)
        })), n = await e.fetchConfiguration(r);
        r.forEach((i, a) => {
          this.updateSectionConfiguration(i.section, n[a]);
        });
      }
    }
    this._ready.resolve();
  }
  /**
   *  Updates the cached configurations using the `change` notification parameters.
   *
   * @param change The parameters of a change configuration notification.
   * `settings` property of the change object could be expressed as `Record<string, Record<string, any>>`
   */
  updateConfiguration(e) {
    typeof e.settings != "object" || e.settings === null || Object.entries(e.settings).forEach(([r, n]) => {
      this.updateSectionConfiguration(r, n), this.onConfigurationSectionUpdateEmitter.fire({ section: r, configuration: n });
    });
  }
  updateSectionConfiguration(e, r) {
    this.settings[e] = r;
  }
  /**
  * Returns a configuration value stored for the given language.
  *
  * @param language The language id
  * @param configuration Configuration name
  */
  async getConfiguration(e, r) {
    await this.ready;
    const n = this.toSectionName(e);
    if (this.settings[n])
      return this.settings[n][r];
  }
  toSectionName(e) {
    return `${e}`;
  }
  get onConfigurationSectionUpdate() {
    return this.onConfigurationSectionUpdateEmitter.event;
  }
}
var or = {}, lr = {}, ra = {}, ks = {}, G = {}, Vc;
function $d() {
  if (Vc) return G;
  Vc = 1, Object.defineProperty(G, "__esModule", { value: !0 }), G.Message = G.NotificationType9 = G.NotificationType8 = G.NotificationType7 = G.NotificationType6 = G.NotificationType5 = G.NotificationType4 = G.NotificationType3 = G.NotificationType2 = G.NotificationType1 = G.NotificationType0 = G.NotificationType = G.RequestType9 = G.RequestType8 = G.RequestType7 = G.RequestType6 = G.RequestType5 = G.RequestType4 = G.RequestType3 = G.RequestType2 = G.RequestType1 = G.RequestType = G.RequestType0 = G.AbstractMessageSignature = G.ParameterStructures = G.ResponseError = G.ErrorCodes = void 0;
  const t = bi();
  var e;
  (function(T) {
    T.ParseError = -32700, T.InvalidRequest = -32600, T.MethodNotFound = -32601, T.InvalidParams = -32602, T.InternalError = -32603, T.jsonrpcReservedErrorRangeStart = -32099, T.serverErrorStart = -32099, T.MessageWriteError = -32099, T.MessageReadError = -32098, T.PendingResponseRejected = -32097, T.ConnectionInactive = -32096, T.ServerNotInitialized = -32002, T.UnknownErrorCode = -32001, T.jsonrpcReservedErrorRangeEnd = -32e3, T.serverErrorEnd = -32e3;
  })(e || (G.ErrorCodes = e = {}));
  class r extends Error {
    constructor(g, $, y) {
      super($), this.code = t.number(g) ? g : e.UnknownErrorCode, this.data = y, Object.setPrototypeOf(this, r.prototype);
    }
    toJson() {
      const g = {
        code: this.code,
        message: this.message
      };
      return this.data !== void 0 && (g.data = this.data), g;
    }
  }
  G.ResponseError = r;
  class n {
    constructor(g) {
      this.kind = g;
    }
    static is(g) {
      return g === n.auto || g === n.byName || g === n.byPosition;
    }
    toString() {
      return this.kind;
    }
  }
  G.ParameterStructures = n, n.auto = new n("auto"), n.byPosition = new n("byPosition"), n.byName = new n("byName");
  class i {
    constructor(g, $) {
      this.method = g, this.numberOfParams = $;
    }
    get parameterStructures() {
      return n.auto;
    }
  }
  G.AbstractMessageSignature = i;
  class a extends i {
    constructor(g) {
      super(g, 0);
    }
  }
  G.RequestType0 = a;
  class s extends i {
    constructor(g, $ = n.auto) {
      super(g, 1), this._parameterStructures = $;
    }
    get parameterStructures() {
      return this._parameterStructures;
    }
  }
  G.RequestType = s;
  class o extends i {
    constructor(g, $ = n.auto) {
      super(g, 1), this._parameterStructures = $;
    }
    get parameterStructures() {
      return this._parameterStructures;
    }
  }
  G.RequestType1 = o;
  class l extends i {
    constructor(g) {
      super(g, 2);
    }
  }
  G.RequestType2 = l;
  class c extends i {
    constructor(g) {
      super(g, 3);
    }
  }
  G.RequestType3 = c;
  class u extends i {
    constructor(g) {
      super(g, 4);
    }
  }
  G.RequestType4 = u;
  class d extends i {
    constructor(g) {
      super(g, 5);
    }
  }
  G.RequestType5 = d;
  class p extends i {
    constructor(g) {
      super(g, 6);
    }
  }
  G.RequestType6 = p;
  class m extends i {
    constructor(g) {
      super(g, 7);
    }
  }
  G.RequestType7 = m;
  class A extends i {
    constructor(g) {
      super(g, 8);
    }
  }
  G.RequestType8 = A;
  class b extends i {
    constructor(g) {
      super(g, 9);
    }
  }
  G.RequestType9 = b;
  class I extends i {
    constructor(g, $ = n.auto) {
      super(g, 1), this._parameterStructures = $;
    }
    get parameterStructures() {
      return this._parameterStructures;
    }
  }
  G.NotificationType = I;
  class k extends i {
    constructor(g) {
      super(g, 0);
    }
  }
  G.NotificationType0 = k;
  class S extends i {
    constructor(g, $ = n.auto) {
      super(g, 1), this._parameterStructures = $;
    }
    get parameterStructures() {
      return this._parameterStructures;
    }
  }
  G.NotificationType1 = S;
  class C extends i {
    constructor(g) {
      super(g, 2);
    }
  }
  G.NotificationType2 = C;
  class P extends i {
    constructor(g) {
      super(g, 3);
    }
  }
  G.NotificationType3 = P;
  class W extends i {
    constructor(g) {
      super(g, 4);
    }
  }
  G.NotificationType4 = W;
  class B extends i {
    constructor(g) {
      super(g, 5);
    }
  }
  G.NotificationType5 = B;
  class H extends i {
    constructor(g) {
      super(g, 6);
    }
  }
  G.NotificationType6 = H;
  class ne extends i {
    constructor(g) {
      super(g, 7);
    }
  }
  G.NotificationType7 = ne;
  class se extends i {
    constructor(g) {
      super(g, 8);
    }
  }
  G.NotificationType8 = se;
  class oe extends i {
    constructor(g) {
      super(g, 9);
    }
  }
  G.NotificationType9 = oe;
  var N;
  return (function(T) {
    function g(R) {
      const E = R;
      return E && t.string(E.method) && (t.string(E.id) || t.number(E.id));
    }
    T.isRequest = g;
    function $(R) {
      const E = R;
      return E && t.string(E.method) && R.id === void 0;
    }
    T.isNotification = $;
    function y(R) {
      const E = R;
      return E && (E.result !== void 0 || !!E.error) && (t.string(E.id) || t.number(E.id) || E.id === null);
    }
    T.isResponse = y;
  })(N || (G.Message = N = {})), G;
}
var St = {}, Hc;
function Cd() {
  if (Hc) return St;
  Hc = 1;
  var t;
  Object.defineProperty(St, "__esModule", { value: !0 }), St.LRUCache = St.LinkedMap = St.Touch = void 0;
  var e;
  (function(i) {
    i.None = 0, i.First = 1, i.AsOld = i.First, i.Last = 2, i.AsNew = i.Last;
  })(e || (St.Touch = e = {}));
  class r {
    constructor() {
      this[t] = "LinkedMap", this._map = /* @__PURE__ */ new Map(), this._head = void 0, this._tail = void 0, this._size = 0, this._state = 0;
    }
    clear() {
      this._map.clear(), this._head = void 0, this._tail = void 0, this._size = 0, this._state++;
    }
    isEmpty() {
      return !this._head && !this._tail;
    }
    get size() {
      return this._size;
    }
    get first() {
      return this._head?.value;
    }
    get last() {
      return this._tail?.value;
    }
    has(a) {
      return this._map.has(a);
    }
    get(a, s = e.None) {
      const o = this._map.get(a);
      if (o)
        return s !== e.None && this.touch(o, s), o.value;
    }
    set(a, s, o = e.None) {
      let l = this._map.get(a);
      if (l)
        l.value = s, o !== e.None && this.touch(l, o);
      else {
        switch (l = { key: a, value: s, next: void 0, previous: void 0 }, o) {
          case e.None:
            this.addItemLast(l);
            break;
          case e.First:
            this.addItemFirst(l);
            break;
          case e.Last:
            this.addItemLast(l);
            break;
          default:
            this.addItemLast(l);
            break;
        }
        this._map.set(a, l), this._size++;
      }
      return this;
    }
    delete(a) {
      return !!this.remove(a);
    }
    remove(a) {
      const s = this._map.get(a);
      if (s)
        return this._map.delete(a), this.removeItem(s), this._size--, s.value;
    }
    shift() {
      if (!this._head && !this._tail)
        return;
      if (!this._head || !this._tail)
        throw new Error("Invalid list");
      const a = this._head;
      return this._map.delete(a.key), this.removeItem(a), this._size--, a.value;
    }
    forEach(a, s) {
      const o = this._state;
      let l = this._head;
      for (; l; ) {
        if (s ? a.bind(s)(l.value, l.key, this) : a(l.value, l.key, this), this._state !== o)
          throw new Error("LinkedMap got modified during iteration.");
        l = l.next;
      }
    }
    keys() {
      const a = this._state;
      let s = this._head;
      const o = {
        [Symbol.iterator]: () => o,
        next: () => {
          if (this._state !== a)
            throw new Error("LinkedMap got modified during iteration.");
          if (s) {
            const l = { value: s.key, done: !1 };
            return s = s.next, l;
          } else
            return { value: void 0, done: !0 };
        }
      };
      return o;
    }
    values() {
      const a = this._state;
      let s = this._head;
      const o = {
        [Symbol.iterator]: () => o,
        next: () => {
          if (this._state !== a)
            throw new Error("LinkedMap got modified during iteration.");
          if (s) {
            const l = { value: s.value, done: !1 };
            return s = s.next, l;
          } else
            return { value: void 0, done: !0 };
        }
      };
      return o;
    }
    entries() {
      const a = this._state;
      let s = this._head;
      const o = {
        [Symbol.iterator]: () => o,
        next: () => {
          if (this._state !== a)
            throw new Error("LinkedMap got modified during iteration.");
          if (s) {
            const l = { value: [s.key, s.value], done: !1 };
            return s = s.next, l;
          } else
            return { value: void 0, done: !0 };
        }
      };
      return o;
    }
    [(t = Symbol.toStringTag, Symbol.iterator)]() {
      return this.entries();
    }
    trimOld(a) {
      if (a >= this.size)
        return;
      if (a === 0) {
        this.clear();
        return;
      }
      let s = this._head, o = this.size;
      for (; s && o > a; )
        this._map.delete(s.key), s = s.next, o--;
      this._head = s, this._size = o, s && (s.previous = void 0), this._state++;
    }
    addItemFirst(a) {
      if (!this._head && !this._tail)
        this._tail = a;
      else if (this._head)
        a.next = this._head, this._head.previous = a;
      else
        throw new Error("Invalid list");
      this._head = a, this._state++;
    }
    addItemLast(a) {
      if (!this._head && !this._tail)
        this._head = a;
      else if (this._tail)
        a.previous = this._tail, this._tail.next = a;
      else
        throw new Error("Invalid list");
      this._tail = a, this._state++;
    }
    removeItem(a) {
      if (a === this._head && a === this._tail)
        this._head = void 0, this._tail = void 0;
      else if (a === this._head) {
        if (!a.next)
          throw new Error("Invalid list");
        a.next.previous = void 0, this._head = a.next;
      } else if (a === this._tail) {
        if (!a.previous)
          throw new Error("Invalid list");
        a.previous.next = void 0, this._tail = a.previous;
      } else {
        const s = a.next, o = a.previous;
        if (!s || !o)
          throw new Error("Invalid list");
        s.previous = o, o.next = s;
      }
      a.next = void 0, a.previous = void 0, this._state++;
    }
    touch(a, s) {
      if (!this._head || !this._tail)
        throw new Error("Invalid list");
      if (!(s !== e.First && s !== e.Last)) {
        if (s === e.First) {
          if (a === this._head)
            return;
          const o = a.next, l = a.previous;
          a === this._tail ? (l.next = void 0, this._tail = l) : (o.previous = l, l.next = o), a.previous = void 0, a.next = this._head, this._head.previous = a, this._head = a, this._state++;
        } else if (s === e.Last) {
          if (a === this._tail)
            return;
          const o = a.next, l = a.previous;
          a === this._head ? (o.previous = void 0, this._head = o) : (o.previous = l, l.next = o), a.next = void 0, a.previous = this._tail, this._tail.next = a, this._tail = a, this._state++;
        }
      }
    }
    toJSON() {
      const a = [];
      return this.forEach((s, o) => {
        a.push([o, s]);
      }), a;
    }
    fromJSON(a) {
      this.clear();
      for (const [s, o] of a)
        this.set(s, o);
    }
  }
  St.LinkedMap = r;
  class n extends r {
    constructor(a, s = 1) {
      super(), this._limit = a, this._ratio = Math.min(Math.max(0, s), 1);
    }
    get limit() {
      return this._limit;
    }
    set limit(a) {
      this._limit = a, this.checkTrim();
    }
    get ratio() {
      return this._ratio;
    }
    set ratio(a) {
      this._ratio = Math.min(Math.max(0, a), 1), this.checkTrim();
    }
    get(a, s = e.AsNew) {
      return super.get(a, s);
    }
    peek(a) {
      return super.get(a, e.None);
    }
    set(a, s) {
      return super.set(a, s, e.Last), this.checkTrim(), this;
    }
    checkTrim() {
      this.size > this._limit && this.trimOld(Math.round(this._limit * this._ratio));
    }
  }
  return St.LRUCache = n, St;
}
var Dn = {}, Xc;
function Ly() {
  if (Xc) return Dn;
  Xc = 1, Object.defineProperty(Dn, "__esModule", { value: !0 }), Dn.Disposable = void 0;
  var t;
  return (function(e) {
    function r(n) {
      return {
        dispose: n
      };
    }
    e.create = r;
  })(t || (Dn.Disposable = t = {})), Dn;
}
var cr = {}, Yc;
function xy() {
  if (Yc) return cr;
  Yc = 1, Object.defineProperty(cr, "__esModule", { value: !0 }), cr.SharedArrayReceiverStrategy = cr.SharedArraySenderStrategy = void 0;
  const t = us();
  var e;
  (function(s) {
    s.Continue = 0, s.Cancelled = 1;
  })(e || (e = {}));
  class r {
    constructor() {
      this.buffers = /* @__PURE__ */ new Map();
    }
    enableCancellation(o) {
      if (o.id === null)
        return;
      const l = new SharedArrayBuffer(4), c = new Int32Array(l, 0, 1);
      c[0] = e.Continue, this.buffers.set(o.id, l), o.$cancellationData = l;
    }
    async sendCancellation(o, l) {
      const c = this.buffers.get(l);
      if (c === void 0)
        return;
      const u = new Int32Array(c, 0, 1);
      Atomics.store(u, 0, e.Cancelled);
    }
    cleanup(o) {
      this.buffers.delete(o);
    }
    dispose() {
      this.buffers.clear();
    }
  }
  cr.SharedArraySenderStrategy = r;
  class n {
    constructor(o) {
      this.data = new Int32Array(o, 0, 1);
    }
    get isCancellationRequested() {
      return Atomics.load(this.data, 0) === e.Cancelled;
    }
    get onCancellationRequested() {
      throw new Error("Cancellation over SharedArrayBuffer doesn't support cancellation events");
    }
  }
  class i {
    constructor(o) {
      this.token = new n(o);
    }
    cancel() {
    }
    dispose() {
    }
  }
  class a {
    constructor() {
      this.kind = "request";
    }
    createCancellationTokenSource(o) {
      const l = o.$cancellationData;
      return l === void 0 ? new t.CancellationTokenSource() : new i(l);
    }
  }
  return cr.SharedArrayReceiverStrategy = a, cr;
}
var kt = {}, Mn = {}, Jc;
function Sd() {
  if (Jc) return Mn;
  Jc = 1, Object.defineProperty(Mn, "__esModule", { value: !0 }), Mn.Semaphore = void 0;
  const t = Or();
  class e {
    constructor(n = 1) {
      if (n <= 0)
        throw new Error("Capacity must be greater than 0");
      this._capacity = n, this._active = 0, this._waiting = [];
    }
    lock(n) {
      return new Promise((i, a) => {
        this._waiting.push({ thunk: n, resolve: i, reject: a }), this.runNext();
      });
    }
    get active() {
      return this._active;
    }
    runNext() {
      this._waiting.length === 0 || this._active === this._capacity || (0, t.default)().timer.setImmediate(() => this.doRunNext());
    }
    doRunNext() {
      if (this._waiting.length === 0 || this._active === this._capacity)
        return;
      const n = this._waiting.shift();
      if (this._active++, this._active > this._capacity)
        throw new Error("To many thunks active");
      try {
        const i = n.thunk();
        i instanceof Promise ? i.then((a) => {
          this._active--, n.resolve(a), this.runNext();
        }, (a) => {
          this._active--, n.reject(a), this.runNext();
        }) : (this._active--, n.resolve(i), this.runNext());
      } catch (i) {
        this._active--, n.reject(i), this.runNext();
      }
    }
  }
  return Mn.Semaphore = e, Mn;
}
var Zc;
function Dy() {
  if (Zc) return kt;
  Zc = 1, Object.defineProperty(kt, "__esModule", { value: !0 }), kt.ReadableStreamMessageReader = kt.AbstractMessageReader = kt.MessageReader = void 0;
  const t = Or(), e = bi(), r = mn(), n = Sd();
  var i;
  (function(l) {
    function c(u) {
      let d = u;
      return d && e.func(d.listen) && e.func(d.dispose) && e.func(d.onError) && e.func(d.onClose) && e.func(d.onPartialMessage);
    }
    l.is = c;
  })(i || (kt.MessageReader = i = {}));
  class a {
    constructor() {
      this.errorEmitter = new r.Emitter(), this.closeEmitter = new r.Emitter(), this.partialMessageEmitter = new r.Emitter();
    }
    dispose() {
      this.errorEmitter.dispose(), this.closeEmitter.dispose();
    }
    get onError() {
      return this.errorEmitter.event;
    }
    fireError(c) {
      this.errorEmitter.fire(this.asError(c));
    }
    get onClose() {
      return this.closeEmitter.event;
    }
    fireClose() {
      this.closeEmitter.fire(void 0);
    }
    get onPartialMessage() {
      return this.partialMessageEmitter.event;
    }
    firePartialMessage(c) {
      this.partialMessageEmitter.fire(c);
    }
    asError(c) {
      return c instanceof Error ? c : new Error(`Reader received error. Reason: ${e.string(c.message) ? c.message : "unknown"}`);
    }
  }
  kt.AbstractMessageReader = a;
  var s;
  (function(l) {
    function c(u) {
      let d, p;
      const m = /* @__PURE__ */ new Map();
      let A;
      const b = /* @__PURE__ */ new Map();
      if (u === void 0 || typeof u == "string")
        d = u ?? "utf-8";
      else {
        if (d = u.charset ?? "utf-8", u.contentDecoder !== void 0 && (p = u.contentDecoder, m.set(p.name, p)), u.contentDecoders !== void 0)
          for (const I of u.contentDecoders)
            m.set(I.name, I);
        if (u.contentTypeDecoder !== void 0 && (A = u.contentTypeDecoder, b.set(A.name, A)), u.contentTypeDecoders !== void 0)
          for (const I of u.contentTypeDecoders)
            b.set(I.name, I);
      }
      return A === void 0 && (A = (0, t.default)().applicationJson.decoder, b.set(A.name, A)), { charset: d, contentDecoder: p, contentDecoders: m, contentTypeDecoder: A, contentTypeDecoders: b };
    }
    l.fromOptions = c;
  })(s || (s = {}));
  class o extends a {
    constructor(c, u) {
      super(), this.readable = c, this.options = s.fromOptions(u), this.buffer = (0, t.default)().messageBuffer.create(this.options.charset), this._partialMessageTimeout = 1e4, this.nextMessageLength = -1, this.messageToken = 0, this.readSemaphore = new n.Semaphore(1);
    }
    set partialMessageTimeout(c) {
      this._partialMessageTimeout = c;
    }
    get partialMessageTimeout() {
      return this._partialMessageTimeout;
    }
    listen(c) {
      this.nextMessageLength = -1, this.messageToken = 0, this.partialMessageTimer = void 0, this.callback = c;
      const u = this.readable.onData((d) => {
        this.onData(d);
      });
      return this.readable.onError((d) => this.fireError(d)), this.readable.onClose(() => this.fireClose()), u;
    }
    onData(c) {
      try {
        for (this.buffer.append(c); ; ) {
          if (this.nextMessageLength === -1) {
            const d = this.buffer.tryReadHeaders(!0);
            if (!d)
              return;
            const p = d.get("content-length");
            if (!p) {
              this.fireError(new Error(`Header must provide a Content-Length property.
${JSON.stringify(Object.fromEntries(d))}`));
              return;
            }
            const m = parseInt(p);
            if (isNaN(m)) {
              this.fireError(new Error(`Content-Length value must be a number. Got ${p}`));
              return;
            }
            this.nextMessageLength = m;
          }
          const u = this.buffer.tryReadBody(this.nextMessageLength);
          if (u === void 0) {
            this.setPartialMessageTimer();
            return;
          }
          this.clearPartialMessageTimer(), this.nextMessageLength = -1, this.readSemaphore.lock(async () => {
            const d = this.options.contentDecoder !== void 0 ? await this.options.contentDecoder.decode(u) : u, p = await this.options.contentTypeDecoder.decode(d, this.options);
            this.callback(p);
          }).catch((d) => {
            this.fireError(d);
          });
        }
      } catch (u) {
        this.fireError(u);
      }
    }
    clearPartialMessageTimer() {
      this.partialMessageTimer && (this.partialMessageTimer.dispose(), this.partialMessageTimer = void 0);
    }
    setPartialMessageTimer() {
      this.clearPartialMessageTimer(), !(this._partialMessageTimeout <= 0) && (this.partialMessageTimer = (0, t.default)().timer.setTimeout((c, u) => {
        this.partialMessageTimer = void 0, c === this.messageToken && (this.firePartialMessage({ messageToken: c, waitingTime: u }), this.setPartialMessageTimer());
      }, this._partialMessageTimeout, this.messageToken, this._partialMessageTimeout));
    }
  }
  return kt.ReadableStreamMessageReader = o, kt;
}
var wt = {}, Qc;
function My() {
  if (Qc) return wt;
  Qc = 1, Object.defineProperty(wt, "__esModule", { value: !0 }), wt.WriteableStreamMessageWriter = wt.AbstractMessageWriter = wt.MessageWriter = void 0;
  const t = Or(), e = bi(), r = Sd(), n = mn(), i = "Content-Length: ", a = `\r
`;
  var s;
  (function(u) {
    function d(p) {
      let m = p;
      return m && e.func(m.dispose) && e.func(m.onClose) && e.func(m.onError) && e.func(m.write);
    }
    u.is = d;
  })(s || (wt.MessageWriter = s = {}));
  class o {
    constructor() {
      this.errorEmitter = new n.Emitter(), this.closeEmitter = new n.Emitter();
    }
    dispose() {
      this.errorEmitter.dispose(), this.closeEmitter.dispose();
    }
    get onError() {
      return this.errorEmitter.event;
    }
    fireError(d, p, m) {
      this.errorEmitter.fire([this.asError(d), p, m]);
    }
    get onClose() {
      return this.closeEmitter.event;
    }
    fireClose() {
      this.closeEmitter.fire(void 0);
    }
    asError(d) {
      return d instanceof Error ? d : new Error(`Writer received error. Reason: ${e.string(d.message) ? d.message : "unknown"}`);
    }
  }
  wt.AbstractMessageWriter = o;
  var l;
  (function(u) {
    function d(p) {
      return p === void 0 || typeof p == "string" ? { charset: p ?? "utf-8", contentTypeEncoder: (0, t.default)().applicationJson.encoder } : { charset: p.charset ?? "utf-8", contentEncoder: p.contentEncoder, contentTypeEncoder: p.contentTypeEncoder ?? (0, t.default)().applicationJson.encoder };
    }
    u.fromOptions = d;
  })(l || (l = {}));
  class c extends o {
    constructor(d, p) {
      super(), this.writable = d, this.options = l.fromOptions(p), this.errorCount = 0, this.writeSemaphore = new r.Semaphore(1), this.writable.onError((m) => this.fireError(m)), this.writable.onClose(() => this.fireClose());
    }
    async write(d) {
      return this.writeSemaphore.lock(async () => this.options.contentTypeEncoder.encode(d, this.options).then((m) => this.options.contentEncoder !== void 0 ? this.options.contentEncoder.encode(m) : m).then((m) => {
        const A = [];
        return A.push(i, m.byteLength.toString(), a), A.push(a), this.doWrite(d, A, m);
      }, (m) => {
        throw this.fireError(m), m;
      }));
    }
    async doWrite(d, p, m) {
      try {
        return await this.writable.write(p.join(""), "ascii"), this.writable.write(m);
      } catch (A) {
        return this.handleError(A, d), Promise.reject(A);
      }
    }
    handleError(d, p) {
      this.errorCount++, this.fireError(d, p, this.errorCount);
    }
    end() {
      this.writable.end();
    }
  }
  return wt.WriteableStreamMessageWriter = c, wt;
}
var Fn = {}, eu;
function Fy() {
  if (eu) return Fn;
  eu = 1, Object.defineProperty(Fn, "__esModule", { value: !0 }), Fn.AbstractMessageBuffer = void 0;
  const t = 13, e = 10, r = `\r
`;
  class n {
    constructor(a = "utf-8") {
      this._encoding = a, this._chunks = [], this._totalLength = 0;
    }
    get encoding() {
      return this._encoding;
    }
    append(a) {
      const s = typeof a == "string" ? this.fromString(a, this._encoding) : a;
      this._chunks.push(s), this._totalLength += s.byteLength;
    }
    tryReadHeaders(a = !1) {
      if (this._chunks.length === 0)
        return;
      let s = 0, o = 0, l = 0, c = 0;
      e: for (; o < this._chunks.length; ) {
        const m = this._chunks[o];
        for (l = 0; l < m.length; ) {
          switch (m[l]) {
            case t:
              switch (s) {
                case 0:
                  s = 1;
                  break;
                case 2:
                  s = 3;
                  break;
                default:
                  s = 0;
              }
              break;
            case e:
              switch (s) {
                case 1:
                  s = 2;
                  break;
                case 3:
                  s = 4, l++;
                  break e;
                default:
                  s = 0;
              }
              break;
            default:
              s = 0;
          }
          l++;
        }
        c += m.byteLength, o++;
      }
      if (s !== 4)
        return;
      const u = this._read(c + l), d = /* @__PURE__ */ new Map(), p = this.toString(u, "ascii").split(r);
      if (p.length < 2)
        return d;
      for (let m = 0; m < p.length - 2; m++) {
        const A = p[m], b = A.indexOf(":");
        if (b === -1)
          throw new Error(`Message header must separate key and value using ':'
${A}`);
        const I = A.substr(0, b), k = A.substr(b + 1).trim();
        d.set(a ? I.toLowerCase() : I, k);
      }
      return d;
    }
    tryReadBody(a) {
      if (!(this._totalLength < a))
        return this._read(a);
    }
    get numberOfBytes() {
      return this._totalLength;
    }
    _read(a) {
      if (a === 0)
        return this.emptyBuffer();
      if (a > this._totalLength)
        throw new Error("Cannot read so many bytes!");
      if (this._chunks[0].byteLength === a) {
        const c = this._chunks[0];
        return this._chunks.shift(), this._totalLength -= a, this.asNative(c);
      }
      if (this._chunks[0].byteLength > a) {
        const c = this._chunks[0], u = this.asNative(c, a);
        return this._chunks[0] = c.slice(a), this._totalLength -= a, u;
      }
      const s = this.allocNative(a);
      let o = 0, l = 0;
      for (; a > 0; ) {
        const c = this._chunks[l];
        if (c.byteLength > a) {
          const u = c.slice(0, a);
          s.set(u, o), o += a, this._chunks[l] = c.slice(a), this._totalLength -= a, a -= a;
        } else
          s.set(c, o), o += c.byteLength, this._chunks.shift(), this._totalLength -= c.byteLength, a -= c.byteLength;
      }
      return s;
    }
  }
  return Fn.AbstractMessageBuffer = n, Fn;
}
var ws = {}, tu;
function Gy() {
  return tu || (tu = 1, (function(t) {
    Object.defineProperty(t, "__esModule", { value: !0 }), t.createMessageConnection = t.ConnectionOptions = t.MessageStrategy = t.CancellationStrategy = t.CancellationSenderStrategy = t.CancellationReceiverStrategy = t.RequestCancellationReceiverStrategy = t.IdCancellationReceiverStrategy = t.ConnectionStrategy = t.ConnectionError = t.ConnectionErrors = t.LogTraceNotification = t.SetTraceNotification = t.TraceFormat = t.TraceValues = t.Trace = t.NullLogger = t.ProgressType = t.ProgressToken = void 0;
    const e = Or(), r = bi(), n = $d(), i = Cd(), a = mn(), s = us();
    var o;
    (function(g) {
      g.type = new n.NotificationType("$/cancelRequest");
    })(o || (o = {}));
    var l;
    (function(g) {
      function $(y) {
        return typeof y == "string" || typeof y == "number";
      }
      g.is = $;
    })(l || (t.ProgressToken = l = {}));
    var c;
    (function(g) {
      g.type = new n.NotificationType("$/progress");
    })(c || (c = {}));
    class u {
      constructor() {
      }
    }
    t.ProgressType = u;
    var d;
    (function(g) {
      function $(y) {
        return r.func(y);
      }
      g.is = $;
    })(d || (d = {})), t.NullLogger = Object.freeze({
      error: () => {
      },
      warn: () => {
      },
      info: () => {
      },
      log: () => {
      }
    });
    var p;
    (function(g) {
      g[g.Off = 0] = "Off", g[g.Messages = 1] = "Messages", g[g.Compact = 2] = "Compact", g[g.Verbose = 3] = "Verbose";
    })(p || (t.Trace = p = {}));
    var m;
    (function(g) {
      g.Off = "off", g.Messages = "messages", g.Compact = "compact", g.Verbose = "verbose";
    })(m || (t.TraceValues = m = {})), (function(g) {
      function $(R) {
        if (!r.string(R))
          return g.Off;
        switch (R = R.toLowerCase(), R) {
          case "off":
            return g.Off;
          case "messages":
            return g.Messages;
          case "compact":
            return g.Compact;
          case "verbose":
            return g.Verbose;
          default:
            return g.Off;
        }
      }
      g.fromString = $;
      function y(R) {
        switch (R) {
          case g.Off:
            return "off";
          case g.Messages:
            return "messages";
          case g.Compact:
            return "compact";
          case g.Verbose:
            return "verbose";
          default:
            return "off";
        }
      }
      g.toString = y;
    })(p || (t.Trace = p = {}));
    var A;
    (function(g) {
      g.Text = "text", g.JSON = "json";
    })(A || (t.TraceFormat = A = {})), (function(g) {
      function $(y) {
        return r.string(y) ? (y = y.toLowerCase(), y === "json" ? g.JSON : g.Text) : g.Text;
      }
      g.fromString = $;
    })(A || (t.TraceFormat = A = {}));
    var b;
    (function(g) {
      g.type = new n.NotificationType("$/setTrace");
    })(b || (t.SetTraceNotification = b = {}));
    var I;
    (function(g) {
      g.type = new n.NotificationType("$/logTrace");
    })(I || (t.LogTraceNotification = I = {}));
    var k;
    (function(g) {
      g[g.Closed = 1] = "Closed", g[g.Disposed = 2] = "Disposed", g[g.AlreadyListening = 3] = "AlreadyListening";
    })(k || (t.ConnectionErrors = k = {}));
    class S extends Error {
      constructor($, y) {
        super(y), this.code = $, Object.setPrototypeOf(this, S.prototype);
      }
    }
    t.ConnectionError = S;
    var C;
    (function(g) {
      function $(y) {
        const R = y;
        return R && r.func(R.cancelUndispatched);
      }
      g.is = $;
    })(C || (t.ConnectionStrategy = C = {}));
    var P;
    (function(g) {
      function $(y) {
        const R = y;
        return R && (R.kind === void 0 || R.kind === "id") && r.func(R.createCancellationTokenSource) && (R.dispose === void 0 || r.func(R.dispose));
      }
      g.is = $;
    })(P || (t.IdCancellationReceiverStrategy = P = {}));
    var W;
    (function(g) {
      function $(y) {
        const R = y;
        return R && R.kind === "request" && r.func(R.createCancellationTokenSource) && (R.dispose === void 0 || r.func(R.dispose));
      }
      g.is = $;
    })(W || (t.RequestCancellationReceiverStrategy = W = {}));
    var B;
    (function(g) {
      g.Message = Object.freeze({
        createCancellationTokenSource(y) {
          return new s.CancellationTokenSource();
        }
      });
      function $(y) {
        return P.is(y) || W.is(y);
      }
      g.is = $;
    })(B || (t.CancellationReceiverStrategy = B = {}));
    var H;
    (function(g) {
      g.Message = Object.freeze({
        sendCancellation(y, R) {
          return y.sendNotification(o.type, { id: R });
        },
        cleanup(y) {
        }
      });
      function $(y) {
        const R = y;
        return R && r.func(R.sendCancellation) && r.func(R.cleanup);
      }
      g.is = $;
    })(H || (t.CancellationSenderStrategy = H = {}));
    var ne;
    (function(g) {
      g.Message = Object.freeze({
        receiver: B.Message,
        sender: H.Message
      });
      function $(y) {
        const R = y;
        return R && B.is(R.receiver) && H.is(R.sender);
      }
      g.is = $;
    })(ne || (t.CancellationStrategy = ne = {}));
    var se;
    (function(g) {
      function $(y) {
        const R = y;
        return R && r.func(R.handleMessage);
      }
      g.is = $;
    })(se || (t.MessageStrategy = se = {}));
    var oe;
    (function(g) {
      function $(y) {
        const R = y;
        return R && (ne.is(R.cancellationStrategy) || C.is(R.connectionStrategy) || se.is(R.messageStrategy));
      }
      g.is = $;
    })(oe || (t.ConnectionOptions = oe = {}));
    var N;
    (function(g) {
      g[g.New = 1] = "New", g[g.Listening = 2] = "Listening", g[g.Closed = 3] = "Closed", g[g.Disposed = 4] = "Disposed";
    })(N || (N = {}));
    function T(g, $, y, R) {
      const E = y !== void 0 ? y : t.NullLogger;
      let L = 0, D = 0, x = 0;
      const j = "2.0";
      let F;
      const te = /* @__PURE__ */ new Map();
      let z;
      const Q = /* @__PURE__ */ new Map(), _e = /* @__PURE__ */ new Map();
      let me, le = new i.LinkedMap(), we = /* @__PURE__ */ new Map(), Ie = /* @__PURE__ */ new Set(), Ce = /* @__PURE__ */ new Map(), Y = p.Off, Xe = A.Text, ge, it = N.New;
      const Lr = new a.Emitter(), Tn = new a.Emitter(), Rn = new a.Emitter(), vn = new a.Emitter(), En = new a.Emitter(), at = R && R.cancellationStrategy ? R.cancellationStrategy : ne.Message;
      function An(h) {
        if (h === null)
          throw new Error("Can't send requests with id null since the response can't be correlated.");
        return "req-" + h.toString();
      }
      function Ni(h) {
        return h === null ? "res-unknown-" + (++x).toString() : "res-" + h.toString();
      }
      function _i() {
        return "not-" + (++D).toString();
      }
      function Ii(h, w) {
        n.Message.isRequest(w) ? h.set(An(w.id), w) : n.Message.isResponse(w) ? h.set(Ni(w.id), w) : h.set(_i(), w);
      }
      function Pi(h) {
      }
      function $n() {
        return it === N.Listening;
      }
      function Cn() {
        return it === N.Closed;
      }
      function $t() {
        return it === N.Disposed;
      }
      function Sn() {
        (it === N.New || it === N.Listening) && (it = N.Closed, Tn.fire(void 0));
      }
      function Oi(h) {
        Lr.fire([h, void 0, void 0]);
      }
      function Li(h) {
        Lr.fire(h);
      }
      g.onClose(Sn), g.onError(Oi), $.onClose(Sn), $.onError(Li);
      function kn() {
        me || le.size === 0 || (me = (0, e.default)().timer.setImmediate(() => {
          me = void 0, xi();
        }));
      }
      function wn(h) {
        n.Message.isRequest(h) ? Mi(h) : n.Message.isNotification(h) ? Gi(h) : n.Message.isResponse(h) ? Fi(h) : ji(h);
      }
      function xi() {
        if (le.size === 0)
          return;
        const h = le.shift();
        try {
          const w = R?.messageStrategy;
          se.is(w) ? w.handleMessage(h, wn) : wn(h);
        } finally {
          kn();
        }
      }
      const Di = (h) => {
        try {
          if (n.Message.isNotification(h) && h.method === o.type.method) {
            const w = h.params.id, O = An(w), M = le.get(O);
            if (n.Message.isRequest(M)) {
              const re = R?.connectionStrategy, ye = re && re.cancelUndispatched ? re.cancelUndispatched(M, Pi) : void 0;
              if (ye && (ye.error !== void 0 || ye.result !== void 0)) {
                le.delete(O), Ce.delete(w), ye.id = M.id, nr(ye, h.method, Date.now()), $.write(ye).catch(() => E.error("Sending response for canceled message failed."));
                return;
              }
            }
            const ie = Ce.get(w);
            if (ie !== void 0) {
              ie.cancel(), xr(h);
              return;
            } else
              Ie.add(w);
          }
          Ii(le, h);
        } finally {
          kn();
        }
      };
      function Mi(h) {
        if ($t())
          return;
        function w(X, ce, ee) {
          const be = {
            jsonrpc: j,
            id: h.id
          };
          X instanceof n.ResponseError ? be.error = X.toJson() : be.result = X === void 0 ? null : X, nr(be, ce, ee), $.write(be).catch(() => E.error("Sending response failed."));
        }
        function O(X, ce, ee) {
          const be = {
            jsonrpc: j,
            id: h.id,
            error: X.toJson()
          };
          nr(be, ce, ee), $.write(be).catch(() => E.error("Sending response failed."));
        }
        function M(X, ce, ee) {
          X === void 0 && (X = null);
          const be = {
            jsonrpc: j,
            id: h.id,
            result: X
          };
          nr(be, ce, ee), $.write(be).catch(() => E.error("Sending response failed."));
        }
        qi(h);
        const ie = te.get(h.method);
        let re, ye;
        ie && (re = ie.type, ye = ie.handler);
        const Ae = Date.now();
        if (ye || F) {
          const X = h.id ?? String(Date.now()), ce = P.is(at.receiver) ? at.receiver.createCancellationTokenSource(X) : at.receiver.createCancellationTokenSource(h);
          h.id !== null && Ie.has(h.id) && ce.cancel(), h.id !== null && Ce.set(X, ce);
          try {
            let ee;
            if (ye)
              if (h.params === void 0) {
                if (re !== void 0 && re.numberOfParams !== 0) {
                  O(new n.ResponseError(n.ErrorCodes.InvalidParams, `Request ${h.method} defines ${re.numberOfParams} params but received none.`), h.method, Ae);
                  return;
                }
                ee = ye(ce.token);
              } else if (Array.isArray(h.params)) {
                if (re !== void 0 && re.parameterStructures === n.ParameterStructures.byName) {
                  O(new n.ResponseError(n.ErrorCodes.InvalidParams, `Request ${h.method} defines parameters by name but received parameters by position`), h.method, Ae);
                  return;
                }
                ee = ye(...h.params, ce.token);
              } else {
                if (re !== void 0 && re.parameterStructures === n.ParameterStructures.byPosition) {
                  O(new n.ResponseError(n.ErrorCodes.InvalidParams, `Request ${h.method} defines parameters by position but received parameters by name`), h.method, Ae);
                  return;
                }
                ee = ye(h.params, ce.token);
              }
            else F && (ee = F(h.method, h.params, ce.token));
            const be = ee;
            ee ? be.then ? be.then((Ge) => {
              Ce.delete(X), w(Ge, h.method, Ae);
            }, (Ge) => {
              Ce.delete(X), Ge instanceof n.ResponseError ? O(Ge, h.method, Ae) : Ge && r.string(Ge.message) ? O(new n.ResponseError(n.ErrorCodes.InternalError, `Request ${h.method} failed with message: ${Ge.message}`), h.method, Ae) : O(new n.ResponseError(n.ErrorCodes.InternalError, `Request ${h.method} failed unexpectedly without providing any details.`), h.method, Ae);
            }) : (Ce.delete(X), w(ee, h.method, Ae)) : (Ce.delete(X), M(ee, h.method, Ae));
          } catch (ee) {
            Ce.delete(X), ee instanceof n.ResponseError ? w(ee, h.method, Ae) : ee && r.string(ee.message) ? O(new n.ResponseError(n.ErrorCodes.InternalError, `Request ${h.method} failed with message: ${ee.message}`), h.method, Ae) : O(new n.ResponseError(n.ErrorCodes.InternalError, `Request ${h.method} failed unexpectedly without providing any details.`), h.method, Ae);
          }
        } else
          O(new n.ResponseError(n.ErrorCodes.MethodNotFound, `Unhandled method ${h.method}`), h.method, Ae);
      }
      function Fi(h) {
        if (!$t())
          if (h.id === null)
            h.error ? E.error(`Received response message without id: Error is: 
${JSON.stringify(h.error, void 0, 4)}`) : E.error("Received response message without id. No further error information provided.");
          else {
            const w = h.id, O = we.get(w);
            if (Bi(h, O), O !== void 0) {
              we.delete(w);
              try {
                if (h.error) {
                  const M = h.error;
                  O.reject(new n.ResponseError(M.code, M.message, M.data));
                } else if (h.result !== void 0)
                  O.resolve(h.result);
                else
                  throw new Error("Should never happen.");
              } catch (M) {
                M.message ? E.error(`Response handler '${O.method}' failed with message: ${M.message}`) : E.error(`Response handler '${O.method}' failed unexpectedly.`);
              }
            }
          }
      }
      function Gi(h) {
        if ($t())
          return;
        let w, O;
        if (h.method === o.type.method) {
          const M = h.params.id;
          Ie.delete(M), xr(h);
          return;
        } else {
          const M = Q.get(h.method);
          M && (O = M.handler, w = M.type);
        }
        if (O || z)
          try {
            if (xr(h), O)
              if (h.params === void 0)
                w !== void 0 && w.numberOfParams !== 0 && w.parameterStructures !== n.ParameterStructures.byName && E.error(`Notification ${h.method} defines ${w.numberOfParams} params but received none.`), O();
              else if (Array.isArray(h.params)) {
                const M = h.params;
                h.method === c.type.method && M.length === 2 && l.is(M[0]) ? O({ token: M[0], value: M[1] }) : (w !== void 0 && (w.parameterStructures === n.ParameterStructures.byName && E.error(`Notification ${h.method} defines parameters by name but received parameters by position`), w.numberOfParams !== h.params.length && E.error(`Notification ${h.method} defines ${w.numberOfParams} params but received ${M.length} arguments`)), O(...M));
              } else
                w !== void 0 && w.parameterStructures === n.ParameterStructures.byPosition && E.error(`Notification ${h.method} defines parameters by position but received parameters by name`), O(h.params);
            else z && z(h.method, h.params);
          } catch (M) {
            M.message ? E.error(`Notification handler '${h.method}' failed with message: ${M.message}`) : E.error(`Notification handler '${h.method}' failed unexpectedly.`);
          }
        else
          Rn.fire(h);
      }
      function ji(h) {
        if (!h) {
          E.error("Received empty message.");
          return;
        }
        E.error(`Received message which is neither a response nor a notification message:
${JSON.stringify(h, null, 4)}`);
        const w = h;
        if (r.string(w.id) || r.number(w.id)) {
          const O = w.id, M = we.get(O);
          M && M.reject(new Error("The received response has neither a result nor an error property."));
        }
      }
      function st(h) {
        if (h != null)
          switch (Y) {
            case p.Verbose:
              return JSON.stringify(h, null, 4);
            case p.Compact:
              return JSON.stringify(h);
            default:
              return;
          }
      }
      function zi(h) {
        if (!(Y === p.Off || !ge))
          if (Xe === A.Text) {
            let w;
            (Y === p.Verbose || Y === p.Compact) && h.params && (w = `Params: ${st(h.params)}

`), ge.log(`Sending request '${h.method} - (${h.id})'.`, w);
          } else
            Ct("send-request", h);
      }
      function Ui(h) {
        if (!(Y === p.Off || !ge))
          if (Xe === A.Text) {
            let w;
            (Y === p.Verbose || Y === p.Compact) && (h.params ? w = `Params: ${st(h.params)}

` : w = `No parameters provided.

`), ge.log(`Sending notification '${h.method}'.`, w);
          } else
            Ct("send-notification", h);
      }
      function nr(h, w, O) {
        if (!(Y === p.Off || !ge))
          if (Xe === A.Text) {
            let M;
            (Y === p.Verbose || Y === p.Compact) && (h.error && h.error.data ? M = `Error data: ${st(h.error.data)}

` : h.result ? M = `Result: ${st(h.result)}

` : h.error === void 0 && (M = `No result returned.

`)), ge.log(`Sending response '${w} - (${h.id})'. Processing request took ${Date.now() - O}ms`, M);
          } else
            Ct("send-response", h);
      }
      function qi(h) {
        if (!(Y === p.Off || !ge))
          if (Xe === A.Text) {
            let w;
            (Y === p.Verbose || Y === p.Compact) && h.params && (w = `Params: ${st(h.params)}

`), ge.log(`Received request '${h.method} - (${h.id})'.`, w);
          } else
            Ct("receive-request", h);
      }
      function xr(h) {
        if (!(Y === p.Off || !ge || h.method === I.type.method))
          if (Xe === A.Text) {
            let w;
            (Y === p.Verbose || Y === p.Compact) && (h.params ? w = `Params: ${st(h.params)}

` : w = `No parameters provided.

`), ge.log(`Received notification '${h.method}'.`, w);
          } else
            Ct("receive-notification", h);
      }
      function Bi(h, w) {
        if (!(Y === p.Off || !ge))
          if (Xe === A.Text) {
            let O;
            if ((Y === p.Verbose || Y === p.Compact) && (h.error && h.error.data ? O = `Error data: ${st(h.error.data)}

` : h.result ? O = `Result: ${st(h.result)}

` : h.error === void 0 && (O = `No result returned.

`)), w) {
              const M = h.error ? ` Request failed: ${h.error.message} (${h.error.code}).` : "";
              ge.log(`Received response '${w.method} - (${h.id})' in ${Date.now() - w.timerStart}ms.${M}`, O);
            } else
              ge.log(`Received response ${h.id} without active response promise.`, O);
          } else
            Ct("receive-response", h);
      }
      function Ct(h, w) {
        if (!ge || Y === p.Off)
          return;
        const O = {
          isLSPMessage: !0,
          type: h,
          message: w,
          timestamp: Date.now()
        };
        ge.log(O);
      }
      function Ht() {
        if (Cn())
          throw new S(k.Closed, "Connection is closed.");
        if ($t())
          throw new S(k.Disposed, "Connection is disposed.");
      }
      function Wi() {
        if ($n())
          throw new S(k.AlreadyListening, "Connection is already listening");
      }
      function Ki() {
        if (!$n())
          throw new Error("Call listen() first.");
      }
      function Xt(h) {
        return h === void 0 ? null : h;
      }
      function bn(h) {
        if (h !== null)
          return h;
      }
      function f(h) {
        return h != null && !Array.isArray(h) && typeof h == "object";
      }
      function ve(h, w) {
        switch (h) {
          case n.ParameterStructures.auto:
            return f(w) ? bn(w) : [Xt(w)];
          case n.ParameterStructures.byName:
            if (!f(w))
              throw new Error("Received parameters by name but param is not an object literal.");
            return bn(w);
          case n.ParameterStructures.byPosition:
            return [Xt(w)];
          default:
            throw new Error(`Unknown parameter structure ${h.toString()}`);
        }
      }
      function Ee(h, w) {
        let O;
        const M = h.numberOfParams;
        switch (M) {
          case 0:
            O = void 0;
            break;
          case 1:
            O = ve(h.parameterStructures, w[0]);
            break;
          default:
            O = [];
            for (let ie = 0; ie < w.length && ie < M; ie++)
              O.push(Xt(w[ie]));
            if (w.length < M)
              for (let ie = w.length; ie < M; ie++)
                O.push(null);
            break;
        }
        return O;
      }
      const q = {
        sendNotification: (h, ...w) => {
          Ht();
          let O, M;
          if (r.string(h)) {
            O = h;
            const re = w[0];
            let ye = 0, Ae = n.ParameterStructures.auto;
            n.ParameterStructures.is(re) && (ye = 1, Ae = re);
            let X = w.length;
            const ce = X - ye;
            switch (ce) {
              case 0:
                M = void 0;
                break;
              case 1:
                M = ve(Ae, w[ye]);
                break;
              default:
                if (Ae === n.ParameterStructures.byName)
                  throw new Error(`Received ${ce} parameters for 'by Name' notification parameter structure.`);
                M = w.slice(ye, X).map((ee) => Xt(ee));
                break;
            }
          } else {
            const re = w;
            O = h.method, M = Ee(h, re);
          }
          const ie = {
            jsonrpc: j,
            method: O,
            params: M
          };
          return Ui(ie), $.write(ie).catch((re) => {
            throw E.error("Sending notification failed."), re;
          });
        },
        onNotification: (h, w) => {
          Ht();
          let O;
          return r.func(h) ? z = h : w && (r.string(h) ? (O = h, Q.set(h, { type: void 0, handler: w })) : (O = h.method, Q.set(h.method, { type: h, handler: w }))), {
            dispose: () => {
              O !== void 0 ? Q.delete(O) : z = void 0;
            }
          };
        },
        onProgress: (h, w, O) => {
          if (_e.has(w))
            throw new Error(`Progress handler for token ${w} already registered`);
          return _e.set(w, O), {
            dispose: () => {
              _e.delete(w);
            }
          };
        },
        sendProgress: (h, w, O) => q.sendNotification(c.type, { token: w, value: O }),
        onUnhandledProgress: vn.event,
        sendRequest: (h, ...w) => {
          Ht(), Ki();
          let O, M, ie;
          if (r.string(h)) {
            O = h;
            const X = w[0], ce = w[w.length - 1];
            let ee = 0, be = n.ParameterStructures.auto;
            n.ParameterStructures.is(X) && (ee = 1, be = X);
            let Ge = w.length;
            s.CancellationToken.is(ce) && (Ge = Ge - 1, ie = ce);
            const dt = Ge - ee;
            switch (dt) {
              case 0:
                M = void 0;
                break;
              case 1:
                M = ve(be, w[ee]);
                break;
              default:
                if (be === n.ParameterStructures.byName)
                  throw new Error(`Received ${dt} parameters for 'by Name' request parameter structure.`);
                M = w.slice(ee, Ge).map((xd) => Xt(xd));
                break;
            }
          } else {
            const X = w;
            O = h.method, M = Ee(h, X);
            const ce = h.numberOfParams;
            ie = s.CancellationToken.is(X[ce]) ? X[ce] : void 0;
          }
          const re = L++;
          let ye;
          ie && (ye = ie.onCancellationRequested(() => {
            const X = at.sender.sendCancellation(q, re);
            return X === void 0 ? (E.log(`Received no promise from cancellation strategy when cancelling id ${re}`), Promise.resolve()) : X.catch(() => {
              E.log(`Sending cancellation messages for id ${re} failed`);
            });
          }));
          const Ae = {
            jsonrpc: j,
            id: re,
            method: O,
            params: M
          };
          return zi(Ae), typeof at.sender.enableCancellation == "function" && at.sender.enableCancellation(Ae), new Promise(async (X, ce) => {
            const ee = (dt) => {
              X(dt), at.sender.cleanup(re), ye?.dispose();
            }, be = (dt) => {
              ce(dt), at.sender.cleanup(re), ye?.dispose();
            }, Ge = { method: O, timerStart: Date.now(), resolve: ee, reject: be };
            try {
              await $.write(Ae), we.set(re, Ge);
            } catch (dt) {
              throw E.error("Sending request failed."), Ge.reject(new n.ResponseError(n.ErrorCodes.MessageWriteError, dt.message ? dt.message : "Unknown reason")), dt;
            }
          });
        },
        onRequest: (h, w) => {
          Ht();
          let O = null;
          return d.is(h) ? (O = void 0, F = h) : r.string(h) ? (O = null, w !== void 0 && (O = h, te.set(h, { handler: w, type: void 0 }))) : w !== void 0 && (O = h.method, te.set(h.method, { type: h, handler: w })), {
            dispose: () => {
              O !== null && (O !== void 0 ? te.delete(O) : F = void 0);
            }
          };
        },
        hasPendingResponse: () => we.size > 0,
        trace: async (h, w, O) => {
          let M = !1, ie = A.Text;
          O !== void 0 && (r.boolean(O) ? M = O : (M = O.sendNotification || !1, ie = O.traceFormat || A.Text)), Y = h, Xe = ie, Y === p.Off ? ge = void 0 : ge = w, M && !Cn() && !$t() && await q.sendNotification(b.type, { value: p.toString(h) });
        },
        onError: Lr.event,
        onClose: Tn.event,
        onUnhandledNotification: Rn.event,
        onDispose: En.event,
        end: () => {
          $.end();
        },
        dispose: () => {
          if ($t())
            return;
          it = N.Disposed, En.fire(void 0);
          const h = new n.ResponseError(n.ErrorCodes.PendingResponseRejected, "Pending response rejected since connection got disposed");
          for (const w of we.values())
            w.reject(h);
          we = /* @__PURE__ */ new Map(), Ce = /* @__PURE__ */ new Map(), Ie = /* @__PURE__ */ new Set(), le = new i.LinkedMap(), r.func($.dispose) && $.dispose(), r.func(g.dispose) && g.dispose();
        },
        listen: () => {
          Ht(), Wi(), it = N.Listening, g.listen(Di);
        },
        inspect: () => {
          (0, e.default)().console.log("inspect");
        }
      };
      return q.onNotification(I.type, (h) => {
        if (Y === p.Off || !ge)
          return;
        const w = Y === p.Verbose || Y === p.Compact;
        ge.log(h.message, w ? h.verbose : void 0);
      }), q.onNotification(c.type, (h) => {
        const w = _e.get(h.token);
        w ? w(h.value) : vn.fire(h);
      }), q;
    }
    t.createMessageConnection = T;
  })(ws)), ws;
}
var ru;
function yl() {
  return ru || (ru = 1, (function(t) {
    Object.defineProperty(t, "__esModule", { value: !0 }), t.ProgressType = t.ProgressToken = t.createMessageConnection = t.NullLogger = t.ConnectionOptions = t.ConnectionStrategy = t.AbstractMessageBuffer = t.WriteableStreamMessageWriter = t.AbstractMessageWriter = t.MessageWriter = t.ReadableStreamMessageReader = t.AbstractMessageReader = t.MessageReader = t.SharedArrayReceiverStrategy = t.SharedArraySenderStrategy = t.CancellationToken = t.CancellationTokenSource = t.Emitter = t.Event = t.Disposable = t.LRUCache = t.Touch = t.LinkedMap = t.ParameterStructures = t.NotificationType9 = t.NotificationType8 = t.NotificationType7 = t.NotificationType6 = t.NotificationType5 = t.NotificationType4 = t.NotificationType3 = t.NotificationType2 = t.NotificationType1 = t.NotificationType0 = t.NotificationType = t.ErrorCodes = t.ResponseError = t.RequestType9 = t.RequestType8 = t.RequestType7 = t.RequestType6 = t.RequestType5 = t.RequestType4 = t.RequestType3 = t.RequestType2 = t.RequestType1 = t.RequestType0 = t.RequestType = t.Message = t.RAL = void 0, t.MessageStrategy = t.CancellationStrategy = t.CancellationSenderStrategy = t.CancellationReceiverStrategy = t.ConnectionError = t.ConnectionErrors = t.LogTraceNotification = t.SetTraceNotification = t.TraceFormat = t.TraceValues = t.Trace = void 0;
    const e = $d();
    Object.defineProperty(t, "Message", { enumerable: !0, get: function() {
      return e.Message;
    } }), Object.defineProperty(t, "RequestType", { enumerable: !0, get: function() {
      return e.RequestType;
    } }), Object.defineProperty(t, "RequestType0", { enumerable: !0, get: function() {
      return e.RequestType0;
    } }), Object.defineProperty(t, "RequestType1", { enumerable: !0, get: function() {
      return e.RequestType1;
    } }), Object.defineProperty(t, "RequestType2", { enumerable: !0, get: function() {
      return e.RequestType2;
    } }), Object.defineProperty(t, "RequestType3", { enumerable: !0, get: function() {
      return e.RequestType3;
    } }), Object.defineProperty(t, "RequestType4", { enumerable: !0, get: function() {
      return e.RequestType4;
    } }), Object.defineProperty(t, "RequestType5", { enumerable: !0, get: function() {
      return e.RequestType5;
    } }), Object.defineProperty(t, "RequestType6", { enumerable: !0, get: function() {
      return e.RequestType6;
    } }), Object.defineProperty(t, "RequestType7", { enumerable: !0, get: function() {
      return e.RequestType7;
    } }), Object.defineProperty(t, "RequestType8", { enumerable: !0, get: function() {
      return e.RequestType8;
    } }), Object.defineProperty(t, "RequestType9", { enumerable: !0, get: function() {
      return e.RequestType9;
    } }), Object.defineProperty(t, "ResponseError", { enumerable: !0, get: function() {
      return e.ResponseError;
    } }), Object.defineProperty(t, "ErrorCodes", { enumerable: !0, get: function() {
      return e.ErrorCodes;
    } }), Object.defineProperty(t, "NotificationType", { enumerable: !0, get: function() {
      return e.NotificationType;
    } }), Object.defineProperty(t, "NotificationType0", { enumerable: !0, get: function() {
      return e.NotificationType0;
    } }), Object.defineProperty(t, "NotificationType1", { enumerable: !0, get: function() {
      return e.NotificationType1;
    } }), Object.defineProperty(t, "NotificationType2", { enumerable: !0, get: function() {
      return e.NotificationType2;
    } }), Object.defineProperty(t, "NotificationType3", { enumerable: !0, get: function() {
      return e.NotificationType3;
    } }), Object.defineProperty(t, "NotificationType4", { enumerable: !0, get: function() {
      return e.NotificationType4;
    } }), Object.defineProperty(t, "NotificationType5", { enumerable: !0, get: function() {
      return e.NotificationType5;
    } }), Object.defineProperty(t, "NotificationType6", { enumerable: !0, get: function() {
      return e.NotificationType6;
    } }), Object.defineProperty(t, "NotificationType7", { enumerable: !0, get: function() {
      return e.NotificationType7;
    } }), Object.defineProperty(t, "NotificationType8", { enumerable: !0, get: function() {
      return e.NotificationType8;
    } }), Object.defineProperty(t, "NotificationType9", { enumerable: !0, get: function() {
      return e.NotificationType9;
    } }), Object.defineProperty(t, "ParameterStructures", { enumerable: !0, get: function() {
      return e.ParameterStructures;
    } });
    const r = Cd();
    Object.defineProperty(t, "LinkedMap", { enumerable: !0, get: function() {
      return r.LinkedMap;
    } }), Object.defineProperty(t, "LRUCache", { enumerable: !0, get: function() {
      return r.LRUCache;
    } }), Object.defineProperty(t, "Touch", { enumerable: !0, get: function() {
      return r.Touch;
    } });
    const n = Ly();
    Object.defineProperty(t, "Disposable", { enumerable: !0, get: function() {
      return n.Disposable;
    } });
    const i = mn();
    Object.defineProperty(t, "Event", { enumerable: !0, get: function() {
      return i.Event;
    } }), Object.defineProperty(t, "Emitter", { enumerable: !0, get: function() {
      return i.Emitter;
    } });
    const a = us();
    Object.defineProperty(t, "CancellationTokenSource", { enumerable: !0, get: function() {
      return a.CancellationTokenSource;
    } }), Object.defineProperty(t, "CancellationToken", { enumerable: !0, get: function() {
      return a.CancellationToken;
    } });
    const s = xy();
    Object.defineProperty(t, "SharedArraySenderStrategy", { enumerable: !0, get: function() {
      return s.SharedArraySenderStrategy;
    } }), Object.defineProperty(t, "SharedArrayReceiverStrategy", { enumerable: !0, get: function() {
      return s.SharedArrayReceiverStrategy;
    } });
    const o = Dy();
    Object.defineProperty(t, "MessageReader", { enumerable: !0, get: function() {
      return o.MessageReader;
    } }), Object.defineProperty(t, "AbstractMessageReader", { enumerable: !0, get: function() {
      return o.AbstractMessageReader;
    } }), Object.defineProperty(t, "ReadableStreamMessageReader", { enumerable: !0, get: function() {
      return o.ReadableStreamMessageReader;
    } });
    const l = My();
    Object.defineProperty(t, "MessageWriter", { enumerable: !0, get: function() {
      return l.MessageWriter;
    } }), Object.defineProperty(t, "AbstractMessageWriter", { enumerable: !0, get: function() {
      return l.AbstractMessageWriter;
    } }), Object.defineProperty(t, "WriteableStreamMessageWriter", { enumerable: !0, get: function() {
      return l.WriteableStreamMessageWriter;
    } });
    const c = Fy();
    Object.defineProperty(t, "AbstractMessageBuffer", { enumerable: !0, get: function() {
      return c.AbstractMessageBuffer;
    } });
    const u = Gy();
    Object.defineProperty(t, "ConnectionStrategy", { enumerable: !0, get: function() {
      return u.ConnectionStrategy;
    } }), Object.defineProperty(t, "ConnectionOptions", { enumerable: !0, get: function() {
      return u.ConnectionOptions;
    } }), Object.defineProperty(t, "NullLogger", { enumerable: !0, get: function() {
      return u.NullLogger;
    } }), Object.defineProperty(t, "createMessageConnection", { enumerable: !0, get: function() {
      return u.createMessageConnection;
    } }), Object.defineProperty(t, "ProgressToken", { enumerable: !0, get: function() {
      return u.ProgressToken;
    } }), Object.defineProperty(t, "ProgressType", { enumerable: !0, get: function() {
      return u.ProgressType;
    } }), Object.defineProperty(t, "Trace", { enumerable: !0, get: function() {
      return u.Trace;
    } }), Object.defineProperty(t, "TraceValues", { enumerable: !0, get: function() {
      return u.TraceValues;
    } }), Object.defineProperty(t, "TraceFormat", { enumerable: !0, get: function() {
      return u.TraceFormat;
    } }), Object.defineProperty(t, "SetTraceNotification", { enumerable: !0, get: function() {
      return u.SetTraceNotification;
    } }), Object.defineProperty(t, "LogTraceNotification", { enumerable: !0, get: function() {
      return u.LogTraceNotification;
    } }), Object.defineProperty(t, "ConnectionErrors", { enumerable: !0, get: function() {
      return u.ConnectionErrors;
    } }), Object.defineProperty(t, "ConnectionError", { enumerable: !0, get: function() {
      return u.ConnectionError;
    } }), Object.defineProperty(t, "CancellationReceiverStrategy", { enumerable: !0, get: function() {
      return u.CancellationReceiverStrategy;
    } }), Object.defineProperty(t, "CancellationSenderStrategy", { enumerable: !0, get: function() {
      return u.CancellationSenderStrategy;
    } }), Object.defineProperty(t, "CancellationStrategy", { enumerable: !0, get: function() {
      return u.CancellationStrategy;
    } }), Object.defineProperty(t, "MessageStrategy", { enumerable: !0, get: function() {
      return u.MessageStrategy;
    } });
    const d = Or();
    t.RAL = d.default;
  })(ks)), ks;
}
var nu;
function jy() {
  if (nu) return ra;
  nu = 1, Object.defineProperty(ra, "__esModule", { value: !0 });
  const t = yl();
  class e extends t.AbstractMessageBuffer {
    constructor(l = "utf-8") {
      super(l), this.asciiDecoder = new TextDecoder("ascii");
    }
    emptyBuffer() {
      return e.emptyBuffer;
    }
    fromString(l, c) {
      return new TextEncoder().encode(l);
    }
    toString(l, c) {
      return c === "ascii" ? this.asciiDecoder.decode(l) : new TextDecoder(c).decode(l);
    }
    asNative(l, c) {
      return c === void 0 ? l : l.slice(0, c);
    }
    allocNative(l) {
      return new Uint8Array(l);
    }
  }
  e.emptyBuffer = new Uint8Array(0);
  class r {
    constructor(l) {
      this.socket = l, this._onData = new t.Emitter(), this._messageListener = (c) => {
        c.data.arrayBuffer().then((d) => {
          this._onData.fire(new Uint8Array(d));
        }, () => {
          (0, t.RAL)().console.error("Converting blob to array buffer failed.");
        });
      }, this.socket.addEventListener("message", this._messageListener);
    }
    onClose(l) {
      return this.socket.addEventListener("close", l), t.Disposable.create(() => this.socket.removeEventListener("close", l));
    }
    onError(l) {
      return this.socket.addEventListener("error", l), t.Disposable.create(() => this.socket.removeEventListener("error", l));
    }
    onEnd(l) {
      return this.socket.addEventListener("end", l), t.Disposable.create(() => this.socket.removeEventListener("end", l));
    }
    onData(l) {
      return this._onData.event(l);
    }
  }
  class n {
    constructor(l) {
      this.socket = l;
    }
    onClose(l) {
      return this.socket.addEventListener("close", l), t.Disposable.create(() => this.socket.removeEventListener("close", l));
    }
    onError(l) {
      return this.socket.addEventListener("error", l), t.Disposable.create(() => this.socket.removeEventListener("error", l));
    }
    onEnd(l) {
      return this.socket.addEventListener("end", l), t.Disposable.create(() => this.socket.removeEventListener("end", l));
    }
    write(l, c) {
      if (typeof l == "string") {
        if (c !== void 0 && c !== "utf-8")
          throw new Error(`In a Browser environments only utf-8 text encoding is supported. But got encoding: ${c}`);
        this.socket.send(l);
      } else
        this.socket.send(l);
      return Promise.resolve();
    }
    end() {
      this.socket.close();
    }
  }
  const i = new TextEncoder(), a = Object.freeze({
    messageBuffer: Object.freeze({
      create: (o) => new e(o)
    }),
    applicationJson: Object.freeze({
      encoder: Object.freeze({
        name: "application/json",
        encode: (o, l) => {
          if (l.charset !== "utf-8")
            throw new Error(`In a Browser environments only utf-8 text encoding is supported. But got encoding: ${l.charset}`);
          return Promise.resolve(i.encode(JSON.stringify(o, void 0, 0)));
        }
      }),
      decoder: Object.freeze({
        name: "application/json",
        decode: (o, l) => {
          if (!(o instanceof Uint8Array))
            throw new Error("In a Browser environments only Uint8Arrays are supported.");
          return Promise.resolve(JSON.parse(new TextDecoder(l.charset).decode(o)));
        }
      })
    }),
    stream: Object.freeze({
      asReadableStream: (o) => new r(o),
      asWritableStream: (o) => new n(o)
    }),
    console,
    timer: Object.freeze({
      setTimeout(o, l, ...c) {
        const u = setTimeout(o, l, ...c);
        return { dispose: () => clearTimeout(u) };
      },
      setImmediate(o, ...l) {
        const c = setTimeout(o, 0, ...l);
        return { dispose: () => clearTimeout(c) };
      },
      setInterval(o, l, ...c) {
        const u = setInterval(o, l, ...c);
        return { dispose: () => clearInterval(u) };
      }
    })
  });
  function s() {
    return a;
  }
  return (function(o) {
    function l() {
      t.RAL.install(a);
    }
    o.install = l;
  })(s || (s = {})), ra.default = s, ra;
}
var iu;
function gn() {
  return iu || (iu = 1, (function(t) {
    var e = lr && lr.__createBinding || (Object.create ? (function(l, c, u, d) {
      d === void 0 && (d = u);
      var p = Object.getOwnPropertyDescriptor(c, u);
      (!p || ("get" in p ? !c.__esModule : p.writable || p.configurable)) && (p = { enumerable: !0, get: function() {
        return c[u];
      } }), Object.defineProperty(l, d, p);
    }) : (function(l, c, u, d) {
      d === void 0 && (d = u), l[d] = c[u];
    })), r = lr && lr.__exportStar || function(l, c) {
      for (var u in l) u !== "default" && !Object.prototype.hasOwnProperty.call(c, u) && e(c, l, u);
    };
    Object.defineProperty(t, "__esModule", { value: !0 }), t.createMessageConnection = t.BrowserMessageWriter = t.BrowserMessageReader = void 0, jy().default.install();
    const i = yl();
    r(yl(), t);
    class a extends i.AbstractMessageReader {
      constructor(c) {
        super(), this._onData = new i.Emitter(), this._messageListener = (u) => {
          this._onData.fire(u.data);
        }, c.addEventListener("error", (u) => this.fireError(u)), c.onmessage = this._messageListener;
      }
      listen(c) {
        return this._onData.event(c);
      }
    }
    t.BrowserMessageReader = a;
    class s extends i.AbstractMessageWriter {
      constructor(c) {
        super(), this.port = c, this.errorCount = 0, c.addEventListener("error", (u) => this.fireError(u));
      }
      write(c) {
        try {
          return this.port.postMessage(c), Promise.resolve();
        } catch (u) {
          return this.handleError(u, c), Promise.reject(u);
        }
      }
      handleError(c, u) {
        this.errorCount++, this.fireError(c, u, this.errorCount);
      }
      end() {
      }
    }
    t.BrowserMessageWriter = s;
    function o(l, c, u, d) {
      return u === void 0 && (u = i.NullLogger), i.ConnectionStrategy.is(d) && (d = { connectionStrategy: d }), (0, i.createMessageConnection)(l, c, u, d);
    }
    t.createMessageConnection = o;
  })(lr)), lr;
}
var bs, au;
function su() {
  return au || (au = 1, bs = gn()), bs;
}
var ur = {};
const Xl = /* @__PURE__ */ qd(Fg);
var je = {}, ou;
function pe() {
  if (ou) return je;
  ou = 1, Object.defineProperty(je, "__esModule", { value: !0 }), je.ProtocolNotificationType = je.ProtocolNotificationType0 = je.ProtocolRequestType = je.ProtocolRequestType0 = je.RegistrationType = je.MessageDirection = void 0;
  const t = gn();
  var e;
  (function(o) {
    o.clientToServer = "clientToServer", o.serverToClient = "serverToClient", o.both = "both";
  })(e || (je.MessageDirection = e = {}));
  class r {
    constructor(l) {
      this.method = l;
    }
  }
  je.RegistrationType = r;
  class n extends t.RequestType0 {
    constructor(l) {
      super(l);
    }
  }
  je.ProtocolRequestType0 = n;
  class i extends t.RequestType {
    constructor(l) {
      super(l, t.ParameterStructures.byName);
    }
  }
  je.ProtocolRequestType = i;
  class a extends t.NotificationType0 {
    constructor(l) {
      super(l);
    }
  }
  je.ProtocolNotificationType0 = a;
  class s extends t.NotificationType {
    constructor(l) {
      super(l, t.ParameterStructures.byName);
    }
  }
  return je.ProtocolNotificationType = s, je;
}
var Ns = {}, $e = {}, lu;
function Yl() {
  if (lu) return $e;
  lu = 1, Object.defineProperty($e, "__esModule", { value: !0 }), $e.objectLiteral = $e.typedArray = $e.stringArray = $e.array = $e.func = $e.error = $e.number = $e.string = $e.boolean = void 0;
  function t(c) {
    return c === !0 || c === !1;
  }
  $e.boolean = t;
  function e(c) {
    return typeof c == "string" || c instanceof String;
  }
  $e.string = e;
  function r(c) {
    return typeof c == "number" || c instanceof Number;
  }
  $e.number = r;
  function n(c) {
    return c instanceof Error;
  }
  $e.error = n;
  function i(c) {
    return typeof c == "function";
  }
  $e.func = i;
  function a(c) {
    return Array.isArray(c);
  }
  $e.array = a;
  function s(c) {
    return a(c) && c.every((u) => e(u));
  }
  $e.stringArray = s;
  function o(c, u) {
    return Array.isArray(c) && c.every(u);
  }
  $e.typedArray = o;
  function l(c) {
    return c !== null && typeof c == "object";
  }
  return $e.objectLiteral = l, $e;
}
var Gn = {}, cu;
function zy() {
  if (cu) return Gn;
  cu = 1, Object.defineProperty(Gn, "__esModule", { value: !0 }), Gn.ImplementationRequest = void 0;
  const t = pe();
  var e;
  return (function(r) {
    r.method = "textDocument/implementation", r.messageDirection = t.MessageDirection.clientToServer, r.type = new t.ProtocolRequestType(r.method);
  })(e || (Gn.ImplementationRequest = e = {})), Gn;
}
var jn = {}, uu;
function Uy() {
  if (uu) return jn;
  uu = 1, Object.defineProperty(jn, "__esModule", { value: !0 }), jn.TypeDefinitionRequest = void 0;
  const t = pe();
  var e;
  return (function(r) {
    r.method = "textDocument/typeDefinition", r.messageDirection = t.MessageDirection.clientToServer, r.type = new t.ProtocolRequestType(r.method);
  })(e || (jn.TypeDefinitionRequest = e = {})), jn;
}
var fr = {}, fu;
function qy() {
  if (fu) return fr;
  fu = 1, Object.defineProperty(fr, "__esModule", { value: !0 }), fr.DidChangeWorkspaceFoldersNotification = fr.WorkspaceFoldersRequest = void 0;
  const t = pe();
  var e;
  (function(n) {
    n.method = "workspace/workspaceFolders", n.messageDirection = t.MessageDirection.serverToClient, n.type = new t.ProtocolRequestType0(n.method);
  })(e || (fr.WorkspaceFoldersRequest = e = {}));
  var r;
  return (function(n) {
    n.method = "workspace/didChangeWorkspaceFolders", n.messageDirection = t.MessageDirection.clientToServer, n.type = new t.ProtocolNotificationType(n.method);
  })(r || (fr.DidChangeWorkspaceFoldersNotification = r = {})), fr;
}
var zn = {}, du;
function By() {
  if (du) return zn;
  du = 1, Object.defineProperty(zn, "__esModule", { value: !0 }), zn.ConfigurationRequest = void 0;
  const t = pe();
  var e;
  return (function(r) {
    r.method = "workspace/configuration", r.messageDirection = t.MessageDirection.serverToClient, r.type = new t.ProtocolRequestType(r.method);
  })(e || (zn.ConfigurationRequest = e = {})), zn;
}
var dr = {}, hu;
function Wy() {
  if (hu) return dr;
  hu = 1, Object.defineProperty(dr, "__esModule", { value: !0 }), dr.ColorPresentationRequest = dr.DocumentColorRequest = void 0;
  const t = pe();
  var e;
  (function(n) {
    n.method = "textDocument/documentColor", n.messageDirection = t.MessageDirection.clientToServer, n.type = new t.ProtocolRequestType(n.method);
  })(e || (dr.DocumentColorRequest = e = {}));
  var r;
  return (function(n) {
    n.method = "textDocument/colorPresentation", n.messageDirection = t.MessageDirection.clientToServer, n.type = new t.ProtocolRequestType(n.method);
  })(r || (dr.ColorPresentationRequest = r = {})), dr;
}
var hr = {}, pu;
function Ky() {
  if (pu) return hr;
  pu = 1, Object.defineProperty(hr, "__esModule", { value: !0 }), hr.FoldingRangeRefreshRequest = hr.FoldingRangeRequest = void 0;
  const t = pe();
  var e;
  (function(n) {
    n.method = "textDocument/foldingRange", n.messageDirection = t.MessageDirection.clientToServer, n.type = new t.ProtocolRequestType(n.method);
  })(e || (hr.FoldingRangeRequest = e = {}));
  var r;
  return (function(n) {
    n.method = "workspace/foldingRange/refresh", n.messageDirection = t.MessageDirection.serverToClient, n.type = new t.ProtocolRequestType0(n.method);
  })(r || (hr.FoldingRangeRefreshRequest = r = {})), hr;
}
var Un = {}, mu;
function Vy() {
  if (mu) return Un;
  mu = 1, Object.defineProperty(Un, "__esModule", { value: !0 }), Un.DeclarationRequest = void 0;
  const t = pe();
  var e;
  return (function(r) {
    r.method = "textDocument/declaration", r.messageDirection = t.MessageDirection.clientToServer, r.type = new t.ProtocolRequestType(r.method);
  })(e || (Un.DeclarationRequest = e = {})), Un;
}
var qn = {}, gu;
function Hy() {
  if (gu) return qn;
  gu = 1, Object.defineProperty(qn, "__esModule", { value: !0 }), qn.SelectionRangeRequest = void 0;
  const t = pe();
  var e;
  return (function(r) {
    r.method = "textDocument/selectionRange", r.messageDirection = t.MessageDirection.clientToServer, r.type = new t.ProtocolRequestType(r.method);
  })(e || (qn.SelectionRangeRequest = e = {})), qn;
}
var bt = {}, yu;
function Xy() {
  if (yu) return bt;
  yu = 1, Object.defineProperty(bt, "__esModule", { value: !0 }), bt.WorkDoneProgressCancelNotification = bt.WorkDoneProgressCreateRequest = bt.WorkDoneProgress = void 0;
  const t = gn(), e = pe();
  var r;
  (function(a) {
    a.type = new t.ProgressType();
    function s(o) {
      return o === a.type;
    }
    a.is = s;
  })(r || (bt.WorkDoneProgress = r = {}));
  var n;
  (function(a) {
    a.method = "window/workDoneProgress/create", a.messageDirection = e.MessageDirection.serverToClient, a.type = new e.ProtocolRequestType(a.method);
  })(n || (bt.WorkDoneProgressCreateRequest = n = {}));
  var i;
  return (function(a) {
    a.method = "window/workDoneProgress/cancel", a.messageDirection = e.MessageDirection.clientToServer, a.type = new e.ProtocolNotificationType(a.method);
  })(i || (bt.WorkDoneProgressCancelNotification = i = {})), bt;
}
var Nt = {}, Tu;
function Yy() {
  if (Tu) return Nt;
  Tu = 1, Object.defineProperty(Nt, "__esModule", { value: !0 }), Nt.CallHierarchyOutgoingCallsRequest = Nt.CallHierarchyIncomingCallsRequest = Nt.CallHierarchyPrepareRequest = void 0;
  const t = pe();
  var e;
  (function(i) {
    i.method = "textDocument/prepareCallHierarchy", i.messageDirection = t.MessageDirection.clientToServer, i.type = new t.ProtocolRequestType(i.method);
  })(e || (Nt.CallHierarchyPrepareRequest = e = {}));
  var r;
  (function(i) {
    i.method = "callHierarchy/incomingCalls", i.messageDirection = t.MessageDirection.clientToServer, i.type = new t.ProtocolRequestType(i.method);
  })(r || (Nt.CallHierarchyIncomingCallsRequest = r = {}));
  var n;
  return (function(i) {
    i.method = "callHierarchy/outgoingCalls", i.messageDirection = t.MessageDirection.clientToServer, i.type = new t.ProtocolRequestType(i.method);
  })(n || (Nt.CallHierarchyOutgoingCallsRequest = n = {})), Nt;
}
var ze = {}, Ru;
function Jy() {
  if (Ru) return ze;
  Ru = 1, Object.defineProperty(ze, "__esModule", { value: !0 }), ze.SemanticTokensRefreshRequest = ze.SemanticTokensRangeRequest = ze.SemanticTokensDeltaRequest = ze.SemanticTokensRequest = ze.SemanticTokensRegistrationType = ze.TokenFormat = void 0;
  const t = pe();
  var e;
  (function(o) {
    o.Relative = "relative";
  })(e || (ze.TokenFormat = e = {}));
  var r;
  (function(o) {
    o.method = "textDocument/semanticTokens", o.type = new t.RegistrationType(o.method);
  })(r || (ze.SemanticTokensRegistrationType = r = {}));
  var n;
  (function(o) {
    o.method = "textDocument/semanticTokens/full", o.messageDirection = t.MessageDirection.clientToServer, o.type = new t.ProtocolRequestType(o.method), o.registrationMethod = r.method;
  })(n || (ze.SemanticTokensRequest = n = {}));
  var i;
  (function(o) {
    o.method = "textDocument/semanticTokens/full/delta", o.messageDirection = t.MessageDirection.clientToServer, o.type = new t.ProtocolRequestType(o.method), o.registrationMethod = r.method;
  })(i || (ze.SemanticTokensDeltaRequest = i = {}));
  var a;
  (function(o) {
    o.method = "textDocument/semanticTokens/range", o.messageDirection = t.MessageDirection.clientToServer, o.type = new t.ProtocolRequestType(o.method), o.registrationMethod = r.method;
  })(a || (ze.SemanticTokensRangeRequest = a = {}));
  var s;
  return (function(o) {
    o.method = "workspace/semanticTokens/refresh", o.messageDirection = t.MessageDirection.serverToClient, o.type = new t.ProtocolRequestType0(o.method);
  })(s || (ze.SemanticTokensRefreshRequest = s = {})), ze;
}
var Bn = {}, vu;
function Zy() {
  if (vu) return Bn;
  vu = 1, Object.defineProperty(Bn, "__esModule", { value: !0 }), Bn.ShowDocumentRequest = void 0;
  const t = pe();
  var e;
  return (function(r) {
    r.method = "window/showDocument", r.messageDirection = t.MessageDirection.serverToClient, r.type = new t.ProtocolRequestType(r.method);
  })(e || (Bn.ShowDocumentRequest = e = {})), Bn;
}
var Wn = {}, Eu;
function Qy() {
  if (Eu) return Wn;
  Eu = 1, Object.defineProperty(Wn, "__esModule", { value: !0 }), Wn.LinkedEditingRangeRequest = void 0;
  const t = pe();
  var e;
  return (function(r) {
    r.method = "textDocument/linkedEditingRange", r.messageDirection = t.MessageDirection.clientToServer, r.type = new t.ProtocolRequestType(r.method);
  })(e || (Wn.LinkedEditingRangeRequest = e = {})), Wn;
}
var Oe = {}, Au;
function eT() {
  if (Au) return Oe;
  Au = 1, Object.defineProperty(Oe, "__esModule", { value: !0 }), Oe.WillDeleteFilesRequest = Oe.DidDeleteFilesNotification = Oe.DidRenameFilesNotification = Oe.WillRenameFilesRequest = Oe.DidCreateFilesNotification = Oe.WillCreateFilesRequest = Oe.FileOperationPatternKind = void 0;
  const t = pe();
  var e;
  (function(l) {
    l.file = "file", l.folder = "folder";
  })(e || (Oe.FileOperationPatternKind = e = {}));
  var r;
  (function(l) {
    l.method = "workspace/willCreateFiles", l.messageDirection = t.MessageDirection.clientToServer, l.type = new t.ProtocolRequestType(l.method);
  })(r || (Oe.WillCreateFilesRequest = r = {}));
  var n;
  (function(l) {
    l.method = "workspace/didCreateFiles", l.messageDirection = t.MessageDirection.clientToServer, l.type = new t.ProtocolNotificationType(l.method);
  })(n || (Oe.DidCreateFilesNotification = n = {}));
  var i;
  (function(l) {
    l.method = "workspace/willRenameFiles", l.messageDirection = t.MessageDirection.clientToServer, l.type = new t.ProtocolRequestType(l.method);
  })(i || (Oe.WillRenameFilesRequest = i = {}));
  var a;
  (function(l) {
    l.method = "workspace/didRenameFiles", l.messageDirection = t.MessageDirection.clientToServer, l.type = new t.ProtocolNotificationType(l.method);
  })(a || (Oe.DidRenameFilesNotification = a = {}));
  var s;
  (function(l) {
    l.method = "workspace/didDeleteFiles", l.messageDirection = t.MessageDirection.clientToServer, l.type = new t.ProtocolNotificationType(l.method);
  })(s || (Oe.DidDeleteFilesNotification = s = {}));
  var o;
  return (function(l) {
    l.method = "workspace/willDeleteFiles", l.messageDirection = t.MessageDirection.clientToServer, l.type = new t.ProtocolRequestType(l.method);
  })(o || (Oe.WillDeleteFilesRequest = o = {})), Oe;
}
var _t = {}, $u;
function tT() {
  if ($u) return _t;
  $u = 1, Object.defineProperty(_t, "__esModule", { value: !0 }), _t.MonikerRequest = _t.MonikerKind = _t.UniquenessLevel = void 0;
  const t = pe();
  var e;
  (function(i) {
    i.document = "document", i.project = "project", i.group = "group", i.scheme = "scheme", i.global = "global";
  })(e || (_t.UniquenessLevel = e = {}));
  var r;
  (function(i) {
    i.$import = "import", i.$export = "export", i.local = "local";
  })(r || (_t.MonikerKind = r = {}));
  var n;
  return (function(i) {
    i.method = "textDocument/moniker", i.messageDirection = t.MessageDirection.clientToServer, i.type = new t.ProtocolRequestType(i.method);
  })(n || (_t.MonikerRequest = n = {})), _t;
}
var It = {}, Cu;
function rT() {
  if (Cu) return It;
  Cu = 1, Object.defineProperty(It, "__esModule", { value: !0 }), It.TypeHierarchySubtypesRequest = It.TypeHierarchySupertypesRequest = It.TypeHierarchyPrepareRequest = void 0;
  const t = pe();
  var e;
  (function(i) {
    i.method = "textDocument/prepareTypeHierarchy", i.messageDirection = t.MessageDirection.clientToServer, i.type = new t.ProtocolRequestType(i.method);
  })(e || (It.TypeHierarchyPrepareRequest = e = {}));
  var r;
  (function(i) {
    i.method = "typeHierarchy/supertypes", i.messageDirection = t.MessageDirection.clientToServer, i.type = new t.ProtocolRequestType(i.method);
  })(r || (It.TypeHierarchySupertypesRequest = r = {}));
  var n;
  return (function(i) {
    i.method = "typeHierarchy/subtypes", i.messageDirection = t.MessageDirection.clientToServer, i.type = new t.ProtocolRequestType(i.method);
  })(n || (It.TypeHierarchySubtypesRequest = n = {})), It;
}
var pr = {}, Su;
function nT() {
  if (Su) return pr;
  Su = 1, Object.defineProperty(pr, "__esModule", { value: !0 }), pr.InlineValueRefreshRequest = pr.InlineValueRequest = void 0;
  const t = pe();
  var e;
  (function(n) {
    n.method = "textDocument/inlineValue", n.messageDirection = t.MessageDirection.clientToServer, n.type = new t.ProtocolRequestType(n.method);
  })(e || (pr.InlineValueRequest = e = {}));
  var r;
  return (function(n) {
    n.method = "workspace/inlineValue/refresh", n.messageDirection = t.MessageDirection.serverToClient, n.type = new t.ProtocolRequestType0(n.method);
  })(r || (pr.InlineValueRefreshRequest = r = {})), pr;
}
var Pt = {}, ku;
function iT() {
  if (ku) return Pt;
  ku = 1, Object.defineProperty(Pt, "__esModule", { value: !0 }), Pt.InlayHintRefreshRequest = Pt.InlayHintResolveRequest = Pt.InlayHintRequest = void 0;
  const t = pe();
  var e;
  (function(i) {
    i.method = "textDocument/inlayHint", i.messageDirection = t.MessageDirection.clientToServer, i.type = new t.ProtocolRequestType(i.method);
  })(e || (Pt.InlayHintRequest = e = {}));
  var r;
  (function(i) {
    i.method = "inlayHint/resolve", i.messageDirection = t.MessageDirection.clientToServer, i.type = new t.ProtocolRequestType(i.method);
  })(r || (Pt.InlayHintResolveRequest = r = {}));
  var n;
  return (function(i) {
    i.method = "workspace/inlayHint/refresh", i.messageDirection = t.MessageDirection.serverToClient, i.type = new t.ProtocolRequestType0(i.method);
  })(n || (Pt.InlayHintRefreshRequest = n = {})), Pt;
}
var Ye = {}, wu;
function aT() {
  if (wu) return Ye;
  wu = 1, Object.defineProperty(Ye, "__esModule", { value: !0 }), Ye.DiagnosticRefreshRequest = Ye.WorkspaceDiagnosticRequest = Ye.DocumentDiagnosticRequest = Ye.DocumentDiagnosticReportKind = Ye.DiagnosticServerCancellationData = void 0;
  const t = gn(), e = Yl(), r = pe();
  var n;
  (function(l) {
    function c(u) {
      const d = u;
      return d && e.boolean(d.retriggerRequest);
    }
    l.is = c;
  })(n || (Ye.DiagnosticServerCancellationData = n = {}));
  var i;
  (function(l) {
    l.Full = "full", l.Unchanged = "unchanged";
  })(i || (Ye.DocumentDiagnosticReportKind = i = {}));
  var a;
  (function(l) {
    l.method = "textDocument/diagnostic", l.messageDirection = r.MessageDirection.clientToServer, l.type = new r.ProtocolRequestType(l.method), l.partialResult = new t.ProgressType();
  })(a || (Ye.DocumentDiagnosticRequest = a = {}));
  var s;
  (function(l) {
    l.method = "workspace/diagnostic", l.messageDirection = r.MessageDirection.clientToServer, l.type = new r.ProtocolRequestType(l.method), l.partialResult = new t.ProgressType();
  })(s || (Ye.WorkspaceDiagnosticRequest = s = {}));
  var o;
  return (function(l) {
    l.method = "workspace/diagnostic/refresh", l.messageDirection = r.MessageDirection.serverToClient, l.type = new r.ProtocolRequestType0(l.method);
  })(o || (Ye.DiagnosticRefreshRequest = o = {})), Ye;
}
var ue = {}, bu;
function sT() {
  if (bu) return ue;
  bu = 1, Object.defineProperty(ue, "__esModule", { value: !0 }), ue.DidCloseNotebookDocumentNotification = ue.DidSaveNotebookDocumentNotification = ue.DidChangeNotebookDocumentNotification = ue.NotebookCellArrayChange = ue.DidOpenNotebookDocumentNotification = ue.NotebookDocumentSyncRegistrationType = ue.NotebookDocument = ue.NotebookCell = ue.ExecutionSummary = ue.NotebookCellKind = void 0;
  const t = Xl, e = Yl(), r = pe();
  var n;
  (function(m) {
    m.Markup = 1, m.Code = 2;
    function A(b) {
      return b === 1 || b === 2;
    }
    m.is = A;
  })(n || (ue.NotebookCellKind = n = {}));
  var i;
  (function(m) {
    function A(k, S) {
      const C = { executionOrder: k };
      return (S === !0 || S === !1) && (C.success = S), C;
    }
    m.create = A;
    function b(k) {
      const S = k;
      return e.objectLiteral(S) && t.uinteger.is(S.executionOrder) && (S.success === void 0 || e.boolean(S.success));
    }
    m.is = b;
    function I(k, S) {
      return k === S ? !0 : k == null || S === null || S === void 0 ? !1 : k.executionOrder === S.executionOrder && k.success === S.success;
    }
    m.equals = I;
  })(i || (ue.ExecutionSummary = i = {}));
  var a;
  (function(m) {
    function A(S, C) {
      return { kind: S, document: C };
    }
    m.create = A;
    function b(S) {
      const C = S;
      return e.objectLiteral(C) && n.is(C.kind) && t.DocumentUri.is(C.document) && (C.metadata === void 0 || e.objectLiteral(C.metadata));
    }
    m.is = b;
    function I(S, C) {
      const P = /* @__PURE__ */ new Set();
      return S.document !== C.document && P.add("document"), S.kind !== C.kind && P.add("kind"), S.executionSummary !== C.executionSummary && P.add("executionSummary"), (S.metadata !== void 0 || C.metadata !== void 0) && !k(S.metadata, C.metadata) && P.add("metadata"), (S.executionSummary !== void 0 || C.executionSummary !== void 0) && !i.equals(S.executionSummary, C.executionSummary) && P.add("executionSummary"), P;
    }
    m.diff = I;
    function k(S, C) {
      if (S === C)
        return !0;
      if (S == null || C === null || C === void 0 || typeof S != typeof C || typeof S != "object")
        return !1;
      const P = Array.isArray(S), W = Array.isArray(C);
      if (P !== W)
        return !1;
      if (P && W) {
        if (S.length !== C.length)
          return !1;
        for (let B = 0; B < S.length; B++)
          if (!k(S[B], C[B]))
            return !1;
      }
      if (e.objectLiteral(S) && e.objectLiteral(C)) {
        const B = Object.keys(S), H = Object.keys(C);
        if (B.length !== H.length || (B.sort(), H.sort(), !k(B, H)))
          return !1;
        for (let ne = 0; ne < B.length; ne++) {
          const se = B[ne];
          if (!k(S[se], C[se]))
            return !1;
        }
      }
      return !0;
    }
  })(a || (ue.NotebookCell = a = {}));
  var s;
  (function(m) {
    function A(I, k, S, C) {
      return { uri: I, notebookType: k, version: S, cells: C };
    }
    m.create = A;
    function b(I) {
      const k = I;
      return e.objectLiteral(k) && e.string(k.uri) && t.integer.is(k.version) && e.typedArray(k.cells, a.is);
    }
    m.is = b;
  })(s || (ue.NotebookDocument = s = {}));
  var o;
  (function(m) {
    m.method = "notebookDocument/sync", m.messageDirection = r.MessageDirection.clientToServer, m.type = new r.RegistrationType(m.method);
  })(o || (ue.NotebookDocumentSyncRegistrationType = o = {}));
  var l;
  (function(m) {
    m.method = "notebookDocument/didOpen", m.messageDirection = r.MessageDirection.clientToServer, m.type = new r.ProtocolNotificationType(m.method), m.registrationMethod = o.method;
  })(l || (ue.DidOpenNotebookDocumentNotification = l = {}));
  var c;
  (function(m) {
    function A(I) {
      const k = I;
      return e.objectLiteral(k) && t.uinteger.is(k.start) && t.uinteger.is(k.deleteCount) && (k.cells === void 0 || e.typedArray(k.cells, a.is));
    }
    m.is = A;
    function b(I, k, S) {
      const C = { start: I, deleteCount: k };
      return S !== void 0 && (C.cells = S), C;
    }
    m.create = b;
  })(c || (ue.NotebookCellArrayChange = c = {}));
  var u;
  (function(m) {
    m.method = "notebookDocument/didChange", m.messageDirection = r.MessageDirection.clientToServer, m.type = new r.ProtocolNotificationType(m.method), m.registrationMethod = o.method;
  })(u || (ue.DidChangeNotebookDocumentNotification = u = {}));
  var d;
  (function(m) {
    m.method = "notebookDocument/didSave", m.messageDirection = r.MessageDirection.clientToServer, m.type = new r.ProtocolNotificationType(m.method), m.registrationMethod = o.method;
  })(d || (ue.DidSaveNotebookDocumentNotification = d = {}));
  var p;
  return (function(m) {
    m.method = "notebookDocument/didClose", m.messageDirection = r.MessageDirection.clientToServer, m.type = new r.ProtocolNotificationType(m.method), m.registrationMethod = o.method;
  })(p || (ue.DidCloseNotebookDocumentNotification = p = {})), ue;
}
var Kn = {}, Nu;
function oT() {
  if (Nu) return Kn;
  Nu = 1, Object.defineProperty(Kn, "__esModule", { value: !0 }), Kn.InlineCompletionRequest = void 0;
  const t = pe();
  var e;
  return (function(r) {
    r.method = "textDocument/inlineCompletion", r.messageDirection = t.MessageDirection.clientToServer, r.type = new t.ProtocolRequestType(r.method);
  })(e || (Kn.InlineCompletionRequest = e = {})), Kn;
}
var _u;
function lT() {
  return _u || (_u = 1, (function(t) {
    Object.defineProperty(t, "__esModule", { value: !0 }), t.WorkspaceSymbolRequest = t.CodeActionResolveRequest = t.CodeActionRequest = t.DocumentSymbolRequest = t.DocumentHighlightRequest = t.ReferencesRequest = t.DefinitionRequest = t.SignatureHelpRequest = t.SignatureHelpTriggerKind = t.HoverRequest = t.CompletionResolveRequest = t.CompletionRequest = t.CompletionTriggerKind = t.PublishDiagnosticsNotification = t.WatchKind = t.RelativePattern = t.FileChangeType = t.DidChangeWatchedFilesNotification = t.WillSaveTextDocumentWaitUntilRequest = t.WillSaveTextDocumentNotification = t.TextDocumentSaveReason = t.DidSaveTextDocumentNotification = t.DidCloseTextDocumentNotification = t.DidChangeTextDocumentNotification = t.TextDocumentContentChangeEvent = t.DidOpenTextDocumentNotification = t.TextDocumentSyncKind = t.TelemetryEventNotification = t.LogMessageNotification = t.ShowMessageRequest = t.ShowMessageNotification = t.MessageType = t.DidChangeConfigurationNotification = t.ExitNotification = t.ShutdownRequest = t.InitializedNotification = t.InitializeErrorCodes = t.InitializeRequest = t.WorkDoneProgressOptions = t.TextDocumentRegistrationOptions = t.StaticRegistrationOptions = t.PositionEncodingKind = t.FailureHandlingKind = t.ResourceOperationKind = t.UnregistrationRequest = t.RegistrationRequest = t.DocumentSelector = t.NotebookCellTextDocumentFilter = t.NotebookDocumentFilter = t.TextDocumentFilter = void 0, t.MonikerRequest = t.MonikerKind = t.UniquenessLevel = t.WillDeleteFilesRequest = t.DidDeleteFilesNotification = t.WillRenameFilesRequest = t.DidRenameFilesNotification = t.WillCreateFilesRequest = t.DidCreateFilesNotification = t.FileOperationPatternKind = t.LinkedEditingRangeRequest = t.ShowDocumentRequest = t.SemanticTokensRegistrationType = t.SemanticTokensRefreshRequest = t.SemanticTokensRangeRequest = t.SemanticTokensDeltaRequest = t.SemanticTokensRequest = t.TokenFormat = t.CallHierarchyPrepareRequest = t.CallHierarchyOutgoingCallsRequest = t.CallHierarchyIncomingCallsRequest = t.WorkDoneProgressCancelNotification = t.WorkDoneProgressCreateRequest = t.WorkDoneProgress = t.SelectionRangeRequest = t.DeclarationRequest = t.FoldingRangeRefreshRequest = t.FoldingRangeRequest = t.ColorPresentationRequest = t.DocumentColorRequest = t.ConfigurationRequest = t.DidChangeWorkspaceFoldersNotification = t.WorkspaceFoldersRequest = t.TypeDefinitionRequest = t.ImplementationRequest = t.ApplyWorkspaceEditRequest = t.ExecuteCommandRequest = t.PrepareRenameRequest = t.RenameRequest = t.PrepareSupportDefaultBehavior = t.DocumentOnTypeFormattingRequest = t.DocumentRangesFormattingRequest = t.DocumentRangeFormattingRequest = t.DocumentFormattingRequest = t.DocumentLinkResolveRequest = t.DocumentLinkRequest = t.CodeLensRefreshRequest = t.CodeLensResolveRequest = t.CodeLensRequest = t.WorkspaceSymbolResolveRequest = void 0, t.InlineCompletionRequest = t.DidCloseNotebookDocumentNotification = t.DidSaveNotebookDocumentNotification = t.DidChangeNotebookDocumentNotification = t.NotebookCellArrayChange = t.DidOpenNotebookDocumentNotification = t.NotebookDocumentSyncRegistrationType = t.NotebookDocument = t.NotebookCell = t.ExecutionSummary = t.NotebookCellKind = t.DiagnosticRefreshRequest = t.WorkspaceDiagnosticRequest = t.DocumentDiagnosticRequest = t.DocumentDiagnosticReportKind = t.DiagnosticServerCancellationData = t.InlayHintRefreshRequest = t.InlayHintResolveRequest = t.InlayHintRequest = t.InlineValueRefreshRequest = t.InlineValueRequest = t.TypeHierarchySupertypesRequest = t.TypeHierarchySubtypesRequest = t.TypeHierarchyPrepareRequest = void 0;
    const e = pe(), r = Xl, n = Yl(), i = zy();
    Object.defineProperty(t, "ImplementationRequest", { enumerable: !0, get: function() {
      return i.ImplementationRequest;
    } });
    const a = Uy();
    Object.defineProperty(t, "TypeDefinitionRequest", { enumerable: !0, get: function() {
      return a.TypeDefinitionRequest;
    } });
    const s = qy();
    Object.defineProperty(t, "WorkspaceFoldersRequest", { enumerable: !0, get: function() {
      return s.WorkspaceFoldersRequest;
    } }), Object.defineProperty(t, "DidChangeWorkspaceFoldersNotification", { enumerable: !0, get: function() {
      return s.DidChangeWorkspaceFoldersNotification;
    } });
    const o = By();
    Object.defineProperty(t, "ConfigurationRequest", { enumerable: !0, get: function() {
      return o.ConfigurationRequest;
    } });
    const l = Wy();
    Object.defineProperty(t, "DocumentColorRequest", { enumerable: !0, get: function() {
      return l.DocumentColorRequest;
    } }), Object.defineProperty(t, "ColorPresentationRequest", { enumerable: !0, get: function() {
      return l.ColorPresentationRequest;
    } });
    const c = Ky();
    Object.defineProperty(t, "FoldingRangeRequest", { enumerable: !0, get: function() {
      return c.FoldingRangeRequest;
    } }), Object.defineProperty(t, "FoldingRangeRefreshRequest", { enumerable: !0, get: function() {
      return c.FoldingRangeRefreshRequest;
    } });
    const u = Vy();
    Object.defineProperty(t, "DeclarationRequest", { enumerable: !0, get: function() {
      return u.DeclarationRequest;
    } });
    const d = Hy();
    Object.defineProperty(t, "SelectionRangeRequest", { enumerable: !0, get: function() {
      return d.SelectionRangeRequest;
    } });
    const p = Xy();
    Object.defineProperty(t, "WorkDoneProgress", { enumerable: !0, get: function() {
      return p.WorkDoneProgress;
    } }), Object.defineProperty(t, "WorkDoneProgressCreateRequest", { enumerable: !0, get: function() {
      return p.WorkDoneProgressCreateRequest;
    } }), Object.defineProperty(t, "WorkDoneProgressCancelNotification", { enumerable: !0, get: function() {
      return p.WorkDoneProgressCancelNotification;
    } });
    const m = Yy();
    Object.defineProperty(t, "CallHierarchyIncomingCallsRequest", { enumerable: !0, get: function() {
      return m.CallHierarchyIncomingCallsRequest;
    } }), Object.defineProperty(t, "CallHierarchyOutgoingCallsRequest", { enumerable: !0, get: function() {
      return m.CallHierarchyOutgoingCallsRequest;
    } }), Object.defineProperty(t, "CallHierarchyPrepareRequest", { enumerable: !0, get: function() {
      return m.CallHierarchyPrepareRequest;
    } });
    const A = Jy();
    Object.defineProperty(t, "TokenFormat", { enumerable: !0, get: function() {
      return A.TokenFormat;
    } }), Object.defineProperty(t, "SemanticTokensRequest", { enumerable: !0, get: function() {
      return A.SemanticTokensRequest;
    } }), Object.defineProperty(t, "SemanticTokensDeltaRequest", { enumerable: !0, get: function() {
      return A.SemanticTokensDeltaRequest;
    } }), Object.defineProperty(t, "SemanticTokensRangeRequest", { enumerable: !0, get: function() {
      return A.SemanticTokensRangeRequest;
    } }), Object.defineProperty(t, "SemanticTokensRefreshRequest", { enumerable: !0, get: function() {
      return A.SemanticTokensRefreshRequest;
    } }), Object.defineProperty(t, "SemanticTokensRegistrationType", { enumerable: !0, get: function() {
      return A.SemanticTokensRegistrationType;
    } });
    const b = Zy();
    Object.defineProperty(t, "ShowDocumentRequest", { enumerable: !0, get: function() {
      return b.ShowDocumentRequest;
    } });
    const I = Qy();
    Object.defineProperty(t, "LinkedEditingRangeRequest", { enumerable: !0, get: function() {
      return I.LinkedEditingRangeRequest;
    } });
    const k = eT();
    Object.defineProperty(t, "FileOperationPatternKind", { enumerable: !0, get: function() {
      return k.FileOperationPatternKind;
    } }), Object.defineProperty(t, "DidCreateFilesNotification", { enumerable: !0, get: function() {
      return k.DidCreateFilesNotification;
    } }), Object.defineProperty(t, "WillCreateFilesRequest", { enumerable: !0, get: function() {
      return k.WillCreateFilesRequest;
    } }), Object.defineProperty(t, "DidRenameFilesNotification", { enumerable: !0, get: function() {
      return k.DidRenameFilesNotification;
    } }), Object.defineProperty(t, "WillRenameFilesRequest", { enumerable: !0, get: function() {
      return k.WillRenameFilesRequest;
    } }), Object.defineProperty(t, "DidDeleteFilesNotification", { enumerable: !0, get: function() {
      return k.DidDeleteFilesNotification;
    } }), Object.defineProperty(t, "WillDeleteFilesRequest", { enumerable: !0, get: function() {
      return k.WillDeleteFilesRequest;
    } });
    const S = tT();
    Object.defineProperty(t, "UniquenessLevel", { enumerable: !0, get: function() {
      return S.UniquenessLevel;
    } }), Object.defineProperty(t, "MonikerKind", { enumerable: !0, get: function() {
      return S.MonikerKind;
    } }), Object.defineProperty(t, "MonikerRequest", { enumerable: !0, get: function() {
      return S.MonikerRequest;
    } });
    const C = rT();
    Object.defineProperty(t, "TypeHierarchyPrepareRequest", { enumerable: !0, get: function() {
      return C.TypeHierarchyPrepareRequest;
    } }), Object.defineProperty(t, "TypeHierarchySubtypesRequest", { enumerable: !0, get: function() {
      return C.TypeHierarchySubtypesRequest;
    } }), Object.defineProperty(t, "TypeHierarchySupertypesRequest", { enumerable: !0, get: function() {
      return C.TypeHierarchySupertypesRequest;
    } });
    const P = nT();
    Object.defineProperty(t, "InlineValueRequest", { enumerable: !0, get: function() {
      return P.InlineValueRequest;
    } }), Object.defineProperty(t, "InlineValueRefreshRequest", { enumerable: !0, get: function() {
      return P.InlineValueRefreshRequest;
    } });
    const W = iT();
    Object.defineProperty(t, "InlayHintRequest", { enumerable: !0, get: function() {
      return W.InlayHintRequest;
    } }), Object.defineProperty(t, "InlayHintResolveRequest", { enumerable: !0, get: function() {
      return W.InlayHintResolveRequest;
    } }), Object.defineProperty(t, "InlayHintRefreshRequest", { enumerable: !0, get: function() {
      return W.InlayHintRefreshRequest;
    } });
    const B = aT();
    Object.defineProperty(t, "DiagnosticServerCancellationData", { enumerable: !0, get: function() {
      return B.DiagnosticServerCancellationData;
    } }), Object.defineProperty(t, "DocumentDiagnosticReportKind", { enumerable: !0, get: function() {
      return B.DocumentDiagnosticReportKind;
    } }), Object.defineProperty(t, "DocumentDiagnosticRequest", { enumerable: !0, get: function() {
      return B.DocumentDiagnosticRequest;
    } }), Object.defineProperty(t, "WorkspaceDiagnosticRequest", { enumerable: !0, get: function() {
      return B.WorkspaceDiagnosticRequest;
    } }), Object.defineProperty(t, "DiagnosticRefreshRequest", { enumerable: !0, get: function() {
      return B.DiagnosticRefreshRequest;
    } });
    const H = sT();
    Object.defineProperty(t, "NotebookCellKind", { enumerable: !0, get: function() {
      return H.NotebookCellKind;
    } }), Object.defineProperty(t, "ExecutionSummary", { enumerable: !0, get: function() {
      return H.ExecutionSummary;
    } }), Object.defineProperty(t, "NotebookCell", { enumerable: !0, get: function() {
      return H.NotebookCell;
    } }), Object.defineProperty(t, "NotebookDocument", { enumerable: !0, get: function() {
      return H.NotebookDocument;
    } }), Object.defineProperty(t, "NotebookDocumentSyncRegistrationType", { enumerable: !0, get: function() {
      return H.NotebookDocumentSyncRegistrationType;
    } }), Object.defineProperty(t, "DidOpenNotebookDocumentNotification", { enumerable: !0, get: function() {
      return H.DidOpenNotebookDocumentNotification;
    } }), Object.defineProperty(t, "NotebookCellArrayChange", { enumerable: !0, get: function() {
      return H.NotebookCellArrayChange;
    } }), Object.defineProperty(t, "DidChangeNotebookDocumentNotification", { enumerable: !0, get: function() {
      return H.DidChangeNotebookDocumentNotification;
    } }), Object.defineProperty(t, "DidSaveNotebookDocumentNotification", { enumerable: !0, get: function() {
      return H.DidSaveNotebookDocumentNotification;
    } }), Object.defineProperty(t, "DidCloseNotebookDocumentNotification", { enumerable: !0, get: function() {
      return H.DidCloseNotebookDocumentNotification;
    } });
    const ne = oT();
    Object.defineProperty(t, "InlineCompletionRequest", { enumerable: !0, get: function() {
      return ne.InlineCompletionRequest;
    } });
    var se;
    (function(f) {
      function ve(Ee) {
        const q = Ee;
        return n.string(q) || n.string(q.language) || n.string(q.scheme) || n.string(q.pattern);
      }
      f.is = ve;
    })(se || (t.TextDocumentFilter = se = {}));
    var oe;
    (function(f) {
      function ve(Ee) {
        const q = Ee;
        return n.objectLiteral(q) && (n.string(q.notebookType) || n.string(q.scheme) || n.string(q.pattern));
      }
      f.is = ve;
    })(oe || (t.NotebookDocumentFilter = oe = {}));
    var N;
    (function(f) {
      function ve(Ee) {
        const q = Ee;
        return n.objectLiteral(q) && (n.string(q.notebook) || oe.is(q.notebook)) && (q.language === void 0 || n.string(q.language));
      }
      f.is = ve;
    })(N || (t.NotebookCellTextDocumentFilter = N = {}));
    var T;
    (function(f) {
      function ve(Ee) {
        if (!Array.isArray(Ee))
          return !1;
        for (let q of Ee)
          if (!n.string(q) && !se.is(q) && !N.is(q))
            return !1;
        return !0;
      }
      f.is = ve;
    })(T || (t.DocumentSelector = T = {}));
    var g;
    (function(f) {
      f.method = "client/registerCapability", f.messageDirection = e.MessageDirection.serverToClient, f.type = new e.ProtocolRequestType(f.method);
    })(g || (t.RegistrationRequest = g = {}));
    var $;
    (function(f) {
      f.method = "client/unregisterCapability", f.messageDirection = e.MessageDirection.serverToClient, f.type = new e.ProtocolRequestType(f.method);
    })($ || (t.UnregistrationRequest = $ = {}));
    var y;
    (function(f) {
      f.Create = "create", f.Rename = "rename", f.Delete = "delete";
    })(y || (t.ResourceOperationKind = y = {}));
    var R;
    (function(f) {
      f.Abort = "abort", f.Transactional = "transactional", f.TextOnlyTransactional = "textOnlyTransactional", f.Undo = "undo";
    })(R || (t.FailureHandlingKind = R = {}));
    var E;
    (function(f) {
      f.UTF8 = "utf-8", f.UTF16 = "utf-16", f.UTF32 = "utf-32";
    })(E || (t.PositionEncodingKind = E = {}));
    var L;
    (function(f) {
      function ve(Ee) {
        const q = Ee;
        return q && n.string(q.id) && q.id.length > 0;
      }
      f.hasId = ve;
    })(L || (t.StaticRegistrationOptions = L = {}));
    var D;
    (function(f) {
      function ve(Ee) {
        const q = Ee;
        return q && (q.documentSelector === null || T.is(q.documentSelector));
      }
      f.is = ve;
    })(D || (t.TextDocumentRegistrationOptions = D = {}));
    var x;
    (function(f) {
      function ve(q) {
        const h = q;
        return n.objectLiteral(h) && (h.workDoneProgress === void 0 || n.boolean(h.workDoneProgress));
      }
      f.is = ve;
      function Ee(q) {
        const h = q;
        return h && n.boolean(h.workDoneProgress);
      }
      f.hasWorkDoneProgress = Ee;
    })(x || (t.WorkDoneProgressOptions = x = {}));
    var j;
    (function(f) {
      f.method = "initialize", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolRequestType(f.method);
    })(j || (t.InitializeRequest = j = {}));
    var F;
    (function(f) {
      f.unknownProtocolVersion = 1;
    })(F || (t.InitializeErrorCodes = F = {}));
    var te;
    (function(f) {
      f.method = "initialized", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolNotificationType(f.method);
    })(te || (t.InitializedNotification = te = {}));
    var z;
    (function(f) {
      f.method = "shutdown", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolRequestType0(f.method);
    })(z || (t.ShutdownRequest = z = {}));
    var Q;
    (function(f) {
      f.method = "exit", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolNotificationType0(f.method);
    })(Q || (t.ExitNotification = Q = {}));
    var _e;
    (function(f) {
      f.method = "workspace/didChangeConfiguration", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolNotificationType(f.method);
    })(_e || (t.DidChangeConfigurationNotification = _e = {}));
    var me;
    (function(f) {
      f.Error = 1, f.Warning = 2, f.Info = 3, f.Log = 4, f.Debug = 5;
    })(me || (t.MessageType = me = {}));
    var le;
    (function(f) {
      f.method = "window/showMessage", f.messageDirection = e.MessageDirection.serverToClient, f.type = new e.ProtocolNotificationType(f.method);
    })(le || (t.ShowMessageNotification = le = {}));
    var we;
    (function(f) {
      f.method = "window/showMessageRequest", f.messageDirection = e.MessageDirection.serverToClient, f.type = new e.ProtocolRequestType(f.method);
    })(we || (t.ShowMessageRequest = we = {}));
    var Ie;
    (function(f) {
      f.method = "window/logMessage", f.messageDirection = e.MessageDirection.serverToClient, f.type = new e.ProtocolNotificationType(f.method);
    })(Ie || (t.LogMessageNotification = Ie = {}));
    var Ce;
    (function(f) {
      f.method = "telemetry/event", f.messageDirection = e.MessageDirection.serverToClient, f.type = new e.ProtocolNotificationType(f.method);
    })(Ce || (t.TelemetryEventNotification = Ce = {}));
    var Y;
    (function(f) {
      f.None = 0, f.Full = 1, f.Incremental = 2;
    })(Y || (t.TextDocumentSyncKind = Y = {}));
    var Xe;
    (function(f) {
      f.method = "textDocument/didOpen", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolNotificationType(f.method);
    })(Xe || (t.DidOpenTextDocumentNotification = Xe = {}));
    var ge;
    (function(f) {
      function ve(q) {
        let h = q;
        return h != null && typeof h.text == "string" && h.range !== void 0 && (h.rangeLength === void 0 || typeof h.rangeLength == "number");
      }
      f.isIncremental = ve;
      function Ee(q) {
        let h = q;
        return h != null && typeof h.text == "string" && h.range === void 0 && h.rangeLength === void 0;
      }
      f.isFull = Ee;
    })(ge || (t.TextDocumentContentChangeEvent = ge = {}));
    var it;
    (function(f) {
      f.method = "textDocument/didChange", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolNotificationType(f.method);
    })(it || (t.DidChangeTextDocumentNotification = it = {}));
    var Lr;
    (function(f) {
      f.method = "textDocument/didClose", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolNotificationType(f.method);
    })(Lr || (t.DidCloseTextDocumentNotification = Lr = {}));
    var Tn;
    (function(f) {
      f.method = "textDocument/didSave", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolNotificationType(f.method);
    })(Tn || (t.DidSaveTextDocumentNotification = Tn = {}));
    var Rn;
    (function(f) {
      f.Manual = 1, f.AfterDelay = 2, f.FocusOut = 3;
    })(Rn || (t.TextDocumentSaveReason = Rn = {}));
    var vn;
    (function(f) {
      f.method = "textDocument/willSave", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolNotificationType(f.method);
    })(vn || (t.WillSaveTextDocumentNotification = vn = {}));
    var En;
    (function(f) {
      f.method = "textDocument/willSaveWaitUntil", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolRequestType(f.method);
    })(En || (t.WillSaveTextDocumentWaitUntilRequest = En = {}));
    var at;
    (function(f) {
      f.method = "workspace/didChangeWatchedFiles", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolNotificationType(f.method);
    })(at || (t.DidChangeWatchedFilesNotification = at = {}));
    var An;
    (function(f) {
      f.Created = 1, f.Changed = 2, f.Deleted = 3;
    })(An || (t.FileChangeType = An = {}));
    var Ni;
    (function(f) {
      function ve(Ee) {
        const q = Ee;
        return n.objectLiteral(q) && (r.URI.is(q.baseUri) || r.WorkspaceFolder.is(q.baseUri)) && n.string(q.pattern);
      }
      f.is = ve;
    })(Ni || (t.RelativePattern = Ni = {}));
    var _i;
    (function(f) {
      f.Create = 1, f.Change = 2, f.Delete = 4;
    })(_i || (t.WatchKind = _i = {}));
    var Ii;
    (function(f) {
      f.method = "textDocument/publishDiagnostics", f.messageDirection = e.MessageDirection.serverToClient, f.type = new e.ProtocolNotificationType(f.method);
    })(Ii || (t.PublishDiagnosticsNotification = Ii = {}));
    var Pi;
    (function(f) {
      f.Invoked = 1, f.TriggerCharacter = 2, f.TriggerForIncompleteCompletions = 3;
    })(Pi || (t.CompletionTriggerKind = Pi = {}));
    var $n;
    (function(f) {
      f.method = "textDocument/completion", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolRequestType(f.method);
    })($n || (t.CompletionRequest = $n = {}));
    var Cn;
    (function(f) {
      f.method = "completionItem/resolve", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolRequestType(f.method);
    })(Cn || (t.CompletionResolveRequest = Cn = {}));
    var $t;
    (function(f) {
      f.method = "textDocument/hover", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolRequestType(f.method);
    })($t || (t.HoverRequest = $t = {}));
    var Sn;
    (function(f) {
      f.Invoked = 1, f.TriggerCharacter = 2, f.ContentChange = 3;
    })(Sn || (t.SignatureHelpTriggerKind = Sn = {}));
    var Oi;
    (function(f) {
      f.method = "textDocument/signatureHelp", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolRequestType(f.method);
    })(Oi || (t.SignatureHelpRequest = Oi = {}));
    var Li;
    (function(f) {
      f.method = "textDocument/definition", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolRequestType(f.method);
    })(Li || (t.DefinitionRequest = Li = {}));
    var kn;
    (function(f) {
      f.method = "textDocument/references", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolRequestType(f.method);
    })(kn || (t.ReferencesRequest = kn = {}));
    var wn;
    (function(f) {
      f.method = "textDocument/documentHighlight", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolRequestType(f.method);
    })(wn || (t.DocumentHighlightRequest = wn = {}));
    var xi;
    (function(f) {
      f.method = "textDocument/documentSymbol", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolRequestType(f.method);
    })(xi || (t.DocumentSymbolRequest = xi = {}));
    var Di;
    (function(f) {
      f.method = "textDocument/codeAction", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolRequestType(f.method);
    })(Di || (t.CodeActionRequest = Di = {}));
    var Mi;
    (function(f) {
      f.method = "codeAction/resolve", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolRequestType(f.method);
    })(Mi || (t.CodeActionResolveRequest = Mi = {}));
    var Fi;
    (function(f) {
      f.method = "workspace/symbol", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolRequestType(f.method);
    })(Fi || (t.WorkspaceSymbolRequest = Fi = {}));
    var Gi;
    (function(f) {
      f.method = "workspaceSymbol/resolve", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolRequestType(f.method);
    })(Gi || (t.WorkspaceSymbolResolveRequest = Gi = {}));
    var ji;
    (function(f) {
      f.method = "textDocument/codeLens", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolRequestType(f.method);
    })(ji || (t.CodeLensRequest = ji = {}));
    var st;
    (function(f) {
      f.method = "codeLens/resolve", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolRequestType(f.method);
    })(st || (t.CodeLensResolveRequest = st = {}));
    var zi;
    (function(f) {
      f.method = "workspace/codeLens/refresh", f.messageDirection = e.MessageDirection.serverToClient, f.type = new e.ProtocolRequestType0(f.method);
    })(zi || (t.CodeLensRefreshRequest = zi = {}));
    var Ui;
    (function(f) {
      f.method = "textDocument/documentLink", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolRequestType(f.method);
    })(Ui || (t.DocumentLinkRequest = Ui = {}));
    var nr;
    (function(f) {
      f.method = "documentLink/resolve", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolRequestType(f.method);
    })(nr || (t.DocumentLinkResolveRequest = nr = {}));
    var qi;
    (function(f) {
      f.method = "textDocument/formatting", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolRequestType(f.method);
    })(qi || (t.DocumentFormattingRequest = qi = {}));
    var xr;
    (function(f) {
      f.method = "textDocument/rangeFormatting", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolRequestType(f.method);
    })(xr || (t.DocumentRangeFormattingRequest = xr = {}));
    var Bi;
    (function(f) {
      f.method = "textDocument/rangesFormatting", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolRequestType(f.method);
    })(Bi || (t.DocumentRangesFormattingRequest = Bi = {}));
    var Ct;
    (function(f) {
      f.method = "textDocument/onTypeFormatting", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolRequestType(f.method);
    })(Ct || (t.DocumentOnTypeFormattingRequest = Ct = {}));
    var Ht;
    (function(f) {
      f.Identifier = 1;
    })(Ht || (t.PrepareSupportDefaultBehavior = Ht = {}));
    var Wi;
    (function(f) {
      f.method = "textDocument/rename", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolRequestType(f.method);
    })(Wi || (t.RenameRequest = Wi = {}));
    var Ki;
    (function(f) {
      f.method = "textDocument/prepareRename", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolRequestType(f.method);
    })(Ki || (t.PrepareRenameRequest = Ki = {}));
    var Xt;
    (function(f) {
      f.method = "workspace/executeCommand", f.messageDirection = e.MessageDirection.clientToServer, f.type = new e.ProtocolRequestType(f.method);
    })(Xt || (t.ExecuteCommandRequest = Xt = {}));
    var bn;
    (function(f) {
      f.method = "workspace/applyEdit", f.messageDirection = e.MessageDirection.serverToClient, f.type = new e.ProtocolRequestType("workspace/applyEdit");
    })(bn || (t.ApplyWorkspaceEditRequest = bn = {}));
  })(Ns)), Ns;
}
var Vn = {}, Iu;
function cT() {
  if (Iu) return Vn;
  Iu = 1, Object.defineProperty(Vn, "__esModule", { value: !0 }), Vn.createProtocolConnection = void 0;
  const t = gn();
  function e(r, n, i, a) {
    return t.ConnectionStrategy.is(a) && (a = { connectionStrategy: a }), (0, t.createMessageConnection)(r, n, i, a);
  }
  return Vn.createProtocolConnection = e, Vn;
}
var Pu;
function uT() {
  return Pu || (Pu = 1, (function(t) {
    var e = ur && ur.__createBinding || (Object.create ? (function(a, s, o, l) {
      l === void 0 && (l = o);
      var c = Object.getOwnPropertyDescriptor(s, o);
      (!c || ("get" in c ? !s.__esModule : c.writable || c.configurable)) && (c = { enumerable: !0, get: function() {
        return s[o];
      } }), Object.defineProperty(a, l, c);
    }) : (function(a, s, o, l) {
      l === void 0 && (l = o), a[l] = s[o];
    })), r = ur && ur.__exportStar || function(a, s) {
      for (var o in a) o !== "default" && !Object.prototype.hasOwnProperty.call(s, o) && e(s, a, o);
    };
    Object.defineProperty(t, "__esModule", { value: !0 }), t.LSPErrorCodes = t.createProtocolConnection = void 0, r(gn(), t), r(Xl, t), r(pe(), t), r(lT(), t);
    var n = cT();
    Object.defineProperty(t, "createProtocolConnection", { enumerable: !0, get: function() {
      return n.createProtocolConnection;
    } });
    var i;
    (function(a) {
      a.lspReservedErrorRangeStart = -32899, a.RequestFailed = -32803, a.ServerCancelled = -32802, a.ContentModified = -32801, a.RequestCancelled = -32800, a.lspReservedErrorRangeEnd = -32800;
    })(i || (t.LSPErrorCodes = i = {}));
  })(ur)), ur;
}
var Ou;
function fT() {
  return Ou || (Ou = 1, (function(t) {
    var e = or && or.__createBinding || (Object.create ? (function(a, s, o, l) {
      l === void 0 && (l = o);
      var c = Object.getOwnPropertyDescriptor(s, o);
      (!c || ("get" in c ? !s.__esModule : c.writable || c.configurable)) && (c = { enumerable: !0, get: function() {
        return s[o];
      } }), Object.defineProperty(a, l, c);
    }) : (function(a, s, o, l) {
      l === void 0 && (l = o), a[l] = s[o];
    })), r = or && or.__exportStar || function(a, s) {
      for (var o in a) o !== "default" && !Object.prototype.hasOwnProperty.call(s, o) && e(s, a, o);
    };
    Object.defineProperty(t, "__esModule", { value: !0 }), t.createProtocolConnection = void 0;
    const n = su();
    r(su(), t), r(uT(), t);
    function i(a, s, o, l) {
      return (0, n.createMessageConnection)(a, s, o, l);
    }
    t.createProtocolConnection = i;
  })(or)), or;
}
var na = fT(), li;
(function(t) {
  function e(r) {
    return {
      dispose: async () => await r()
    };
  }
  t.create = e;
})(li || (li = {}));
class dT {
  constructor(e) {
    this.updateBuildOptions = {
      // Default: run only the built-in validation checks and those in the _fast_ category (includes those without category)
      validation: {
        categories: ["built-in", "fast"]
      }
    }, this.updateListeners = [], this.buildPhaseListeners = new Ri(), this.documentPhaseListeners = new Ri(), this.buildState = /* @__PURE__ */ new Map(), this.documentBuildWaiters = /* @__PURE__ */ new Map(), this.currentState = K.Changed, this.langiumDocuments = e.workspace.LangiumDocuments, this.langiumDocumentFactory = e.workspace.LangiumDocumentFactory, this.textDocuments = e.workspace.TextDocuments, this.indexManager = e.workspace.IndexManager, this.fileSystemProvider = e.workspace.FileSystemProvider, this.workspaceManager = () => e.workspace.WorkspaceManager, this.serviceRegistry = e.ServiceRegistry;
  }
  async build(e, r = {}, n = he.CancellationToken.None) {
    for (const i of e) {
      const a = i.uri.toString();
      if (i.state === K.Validated) {
        if (typeof r.validation == "boolean" && r.validation)
          this.resetToState(i, K.IndexedReferences);
        else if (typeof r.validation == "object") {
          const s = this.findMissingValidationCategories(i, r);
          s.length > 0 && (this.buildState.set(a, {
            completed: !1,
            options: {
              validation: {
                categories: s
              }
            },
            result: this.buildState.get(a)?.result
          }), i.state = K.IndexedReferences);
        }
      } else
        this.buildState.delete(a);
    }
    this.currentState = K.Changed, await this.emitUpdate(e.map((i) => i.uri), []), await this.buildDocuments(e, r, n);
  }
  async update(e, r, n = he.CancellationToken.None) {
    this.currentState = K.Changed;
    const i = [];
    for (const l of r) {
      const c = this.langiumDocuments.deleteDocuments(l);
      for (const u of c)
        i.push(u.uri), this.cleanUpDeleted(u);
    }
    const a = (await Promise.all(e.map((l) => this.findChangedUris(l)))).flat();
    for (const l of a) {
      let c = this.langiumDocuments.getDocument(l);
      c === void 0 && (c = this.langiumDocumentFactory.fromModel({ $type: "INVALID" }, l), c.state = K.Changed, this.langiumDocuments.addDocument(c)), this.resetToState(c, K.Changed);
    }
    const s = fe(a).concat(i).map((l) => l.toString()).toSet();
    this.langiumDocuments.all.filter((l) => !s.has(l.uri.toString()) && this.shouldRelink(l, s)).forEach((l) => this.resetToState(l, K.ComputedScopes)), await this.emitUpdate(a, i), await Ue(n);
    const o = this.sortDocuments(this.langiumDocuments.all.filter((l) => (
      // This includes those that were reported as changed and those that we selected for relinking
      l.state < K.Validated || !this.buildState.get(l.uri.toString())?.completed || this.resultsAreIncomplete(l, this.updateBuildOptions)
    )).toArray());
    await this.buildDocuments(o, this.updateBuildOptions, n);
  }
  resultsAreIncomplete(e, r) {
    return this.findMissingValidationCategories(e, r).length >= 1;
  }
  findMissingValidationCategories(e, r) {
    const n = this.buildState.get(e.uri.toString()), i = this.serviceRegistry.getServices(e.uri).validation.ValidationRegistry.getAllValidationCategories(e), a = n?.result?.validationChecks ? new Set(n?.result?.validationChecks) : n?.completed ? i : /* @__PURE__ */ new Set(), s = r === void 0 || r.validation === !0 ? i : typeof r.validation == "object" ? r.validation.categories ?? i : [];
    return fe(s).filter((o) => !a.has(o)).toArray();
  }
  async findChangedUris(e) {
    if (this.langiumDocuments.getDocument(e) ?? this.textDocuments?.get(e))
      return [e];
    try {
      const n = await this.fileSystemProvider.stat(e);
      if (n.isDirectory)
        return await this.workspaceManager().searchFolder(e);
      if (this.workspaceManager().shouldIncludeEntry(n))
        return [e];
    } catch {
    }
    return [];
  }
  async emitUpdate(e, r) {
    await Promise.all(this.updateListeners.map((n) => n(e, r)));
  }
  /**
   * Sort the given documents by priority. By default, documents with an open text document are prioritized.
   * This is useful to ensure that visible documents show their diagnostics before all other documents.
   *
   * This improves the responsiveness in large workspaces as users usually don't care about diagnostics
   * in files that are currently not opened in the editor.
   */
  sortDocuments(e) {
    let r = 0, n = e.length - 1;
    for (; r < n; ) {
      for (; r < e.length && this.hasTextDocument(e[r]); )
        r++;
      for (; n >= 0 && !this.hasTextDocument(e[n]); )
        n--;
      r < n && ([e[r], e[n]] = [e[n], e[r]]);
    }
    return e;
  }
  hasTextDocument(e) {
    return !!this.textDocuments?.get(e.uri);
  }
  /**
   * Check whether the given document should be relinked after changes were found in the given URIs.
   */
  shouldRelink(e, r) {
    return e.references.some((n) => n.error !== void 0) ? !0 : this.indexManager.isAffected(e, r);
  }
  onUpdate(e) {
    return this.updateListeners.push(e), li.create(() => {
      const r = this.updateListeners.indexOf(e);
      r >= 0 && this.updateListeners.splice(r, 1);
    });
  }
  resetToState(e, r) {
    switch (r) {
      case K.Changed:
      case K.Parsed:
        this.indexManager.removeContent(e.uri);
      // Fall through
      case K.IndexedContent:
        e.localSymbols = void 0;
      // Fall through
      case K.ComputedScopes:
        this.serviceRegistry.getServices(e.uri).references.Linker.unlink(e);
      case K.Linked:
        this.indexManager.removeReferences(e.uri);
      // Fall through
      case K.IndexedReferences:
        e.diagnostics = void 0, this.buildState.delete(e.uri.toString());
      // Fall through
      case K.Validated:
    }
    e.state > r && (e.state = r);
  }
  cleanUpDeleted(e) {
    this.buildState.delete(e.uri.toString()), this.indexManager.remove(e.uri), e.state = K.Changed;
  }
  /**
   * Build the given documents by stepping through all build phases. If a document's state indicates
   * that a certain build phase is already done, the phase is skipped for that document.
   *
   * @param documents The documents to build.
   * @param options the {@link BuildOptions} to use.
   * @param cancelToken A cancellation token that can be used to cancel the build.
   * @returns A promise that resolves when the build is done.
   */
  async buildDocuments(e, r, n) {
    this.prepareBuild(e, r), await this.runCancelable(e, K.Parsed, n, (s) => this.langiumDocumentFactory.update(s, n)), await this.runCancelable(e, K.IndexedContent, n, (s) => this.indexManager.updateContent(s, n)), await this.runCancelable(e, K.ComputedScopes, n, async (s) => {
      const o = this.serviceRegistry.getServices(s.uri).references.ScopeComputation;
      s.localSymbols = await o.collectLocalSymbols(s, n);
    });
    const i = e.filter((s) => this.shouldLink(s));
    await this.runCancelable(i, K.Linked, n, (s) => this.serviceRegistry.getServices(s.uri).references.Linker.link(s, n)), await this.runCancelable(i, K.IndexedReferences, n, (s) => this.indexManager.updateReferences(s, n));
    const a = e.filter((s) => this.shouldValidate(s) ? !0 : (this.markAsCompleted(s), !1));
    await this.runCancelable(a, K.Validated, n, async (s) => {
      await this.validate(s, n), this.markAsCompleted(s);
    });
  }
  markAsCompleted(e) {
    const r = this.buildState.get(e.uri.toString());
    r && (r.completed = !0);
  }
  /**
   * Runs prior to beginning the build process to update the {@link DocumentBuildState} for each document
   *
   * @param documents collection of documents to be built
   * @param options the {@link BuildOptions} to use
   */
  prepareBuild(e, r) {
    for (const n of e) {
      const i = n.uri.toString(), a = this.buildState.get(i);
      (!a || a.completed) && this.buildState.set(i, {
        completed: !1,
        options: r,
        result: a?.result
      });
    }
  }
  /**
   * Runs a cancelable operation on a set of documents to bring them to a specified {@link DocumentState}.
   *
   * @param documents The array of documents to process.
   * @param targetState The target {@link DocumentState} to bring the documents to.
   * @param cancelToken A token that can be used to cancel the operation.
   * @param callback A function to be called for each document.
   * @returns A promise that resolves when all documents have been processed or the operation is canceled.
   * @throws Will throw `OperationCancelled` if the operation is canceled via a `CancellationToken`.
   */
  async runCancelable(e, r, n, i) {
    for (const s of e)
      s.state < r && (await Ue(n), await i(s), s.state = r, await this.notifyDocumentPhase(s, r, n));
    const a = e.filter((s) => s.state === r);
    await this.notifyBuildPhase(a, r, n), this.currentState = r;
  }
  onBuildPhase(e, r) {
    return this.buildPhaseListeners.add(e, r), li.create(() => {
      this.buildPhaseListeners.delete(e, r);
    });
  }
  onDocumentPhase(e, r) {
    return this.documentPhaseListeners.add(e, r), li.create(() => {
      this.documentPhaseListeners.delete(e, r);
    });
  }
  waitUntil(e, r, n) {
    let i;
    return r && "path" in r ? i = r : n = r, n ?? (n = he.CancellationToken.None), i ? this.awaitDocumentState(e, i, n) : this.awaitBuilderState(e, n);
  }
  awaitDocumentState(e, r, n) {
    const i = this.langiumDocuments.getDocument(r);
    if (i) {
      if (i.state >= e)
        return Promise.resolve(r);
      if (n.isCancellationRequested)
        return Promise.reject(rn);
      if (this.currentState >= e && e > i.state)
        return Promise.reject(new na.ResponseError(na.LSPErrorCodes.RequestFailed, `Document state of ${r.toString()} is ${K[i.state]}, requiring ${K[e]}, but workspace state is already ${K[this.currentState]}. Returning undefined.`));
    } else return Promise.reject(new na.ResponseError(na.LSPErrorCodes.ServerCancelled, `No document found for URI: ${r.toString()}`));
    return new Promise((a, s) => {
      const o = this.onDocumentPhase(e, (c) => {
        Qe.equals(c.uri, r) && (o.dispose(), l.dispose(), a(c.uri));
      }), l = n.onCancellationRequested(() => {
        o.dispose(), l.dispose(), s(rn);
      });
    });
  }
  awaitBuilderState(e, r) {
    return this.currentState >= e ? Promise.resolve() : r.isCancellationRequested ? Promise.reject(rn) : new Promise((n, i) => {
      const a = this.onBuildPhase(e, () => {
        a.dispose(), s.dispose(), n();
      }), s = r.onCancellationRequested(() => {
        a.dispose(), s.dispose(), i(rn);
      });
    });
  }
  async notifyDocumentPhase(e, r, n) {
    const a = this.documentPhaseListeners.get(r).slice();
    for (const s of a)
      try {
        await Ue(n), await s(e, n);
      } catch (o) {
        if (!fs(o))
          throw o;
      }
  }
  async notifyBuildPhase(e, r, n) {
    if (e.length === 0)
      return;
    const a = this.buildPhaseListeners.get(r).slice();
    for (const s of a)
      await Ue(n), await s(e, n);
  }
  /**
   * Determine whether the given document should be linked during a build. The default
   * implementation checks the `eagerLinking` property of the build options. If it's set to `true`
   * or `undefined`, the document is included in the linking phase. This also affects the
   * references indexing phase, which depends on eager linking.
   */
  shouldLink(e) {
    return this.getBuildOptions(e).eagerLinking ?? !0;
  }
  /**
   * Determine whether the given document should be validated during a build. The default
   * implementation checks the `validation` property of the build options. If it's set to `true`
   * or a `ValidationOptions` object, the document is included in the validation phase.
   */
  shouldValidate(e) {
    return !!this.getBuildOptions(e).validation;
  }
  /**
   * Run validation checks on the given document and store the resulting diagnostics in the document.
   * If the document already contains diagnostics, the new ones are added to the list.
   */
  async validate(e, r) {
    const n = this.serviceRegistry.getServices(e.uri).validation.DocumentValidator, i = this.getBuildOptions(e), a = typeof i.validation == "object" ? { ...i.validation } : {};
    a.categories = this.findMissingValidationCategories(e, i);
    const s = await n.validateDocument(e, a, r);
    e.diagnostics ? e.diagnostics.push(...s) : e.diagnostics = s;
    const o = this.buildState.get(e.uri.toString());
    o && (o.result ?? (o.result = {}), o.result.validationChecks ? o.result.validationChecks = fe(o.result.validationChecks).concat(a.categories).distinct().toArray() : o.result.validationChecks = [...a.categories]);
  }
  getBuildOptions(e) {
    return this.buildState.get(e.uri.toString())?.options ?? {};
  }
}
class hT {
  constructor(e) {
    this.symbolIndex = /* @__PURE__ */ new Map(), this.symbolByTypeIndex = new Ty(), this.referenceIndex = /* @__PURE__ */ new Map(), this.documents = e.workspace.LangiumDocuments, this.serviceRegistry = e.ServiceRegistry, this.astReflection = e.AstReflection;
  }
  findAllReferences(e, r) {
    const n = Gt(e).uri, i = [];
    return this.referenceIndex.forEach((a) => {
      a.forEach((s) => {
        Qe.equals(s.targetUri, n) && s.targetPath === r && i.push(s);
      });
    }), fe(i);
  }
  allElements(e, r) {
    let n = fe(this.symbolIndex.keys());
    return r && (n = n.filter((i) => !r || r.has(i))), n.map((i) => this.getFileDescriptions(i, e)).flat();
  }
  getFileDescriptions(e, r) {
    return r ? this.symbolByTypeIndex.get(e, r, () => (this.symbolIndex.get(e) ?? []).filter((a) => this.astReflection.isSubtype(a.type, r))) : this.symbolIndex.get(e) ?? [];
  }
  remove(e) {
    this.removeContent(e), this.removeReferences(e);
  }
  removeContent(e) {
    const r = e.toString();
    this.symbolIndex.delete(r), this.symbolByTypeIndex.clear(r);
  }
  removeReferences(e) {
    const r = e.toString();
    this.referenceIndex.delete(r);
  }
  async updateContent(e, r = he.CancellationToken.None) {
    const i = await this.serviceRegistry.getServices(e.uri).references.ScopeComputation.collectExportedSymbols(e, r), a = e.uri.toString();
    this.symbolIndex.set(a, i), this.symbolByTypeIndex.clear(a);
  }
  async updateReferences(e, r = he.CancellationToken.None) {
    const i = await this.serviceRegistry.getServices(e.uri).workspace.ReferenceDescriptionProvider.createDescriptions(e, r);
    this.referenceIndex.set(e.uri.toString(), i);
  }
  isAffected(e, r) {
    const n = this.referenceIndex.get(e.uri.toString());
    return n ? n.some((i) => !i.local && r.has(i.targetUri.toString())) : !1;
  }
}
class pT {
  constructor(e) {
    this.initialBuildOptions = {}, this._ready = new Hl(), this.serviceRegistry = e.ServiceRegistry, this.langiumDocuments = e.workspace.LangiumDocuments, this.documentBuilder = e.workspace.DocumentBuilder, this.fileSystemProvider = e.workspace.FileSystemProvider, this.mutex = e.workspace.WorkspaceLock;
  }
  get ready() {
    return this._ready.promise;
  }
  get workspaceFolders() {
    return this.folders;
  }
  initialize(e) {
    this.folders = e.workspaceFolders ?? void 0;
  }
  initialized(e) {
    return this.mutex.write((r) => this.initializeWorkspace(this.folders ?? [], r));
  }
  async initializeWorkspace(e, r = he.CancellationToken.None) {
    const n = await this.performStartup(e);
    await Ue(r), await this.documentBuilder.build(n, this.initialBuildOptions, r);
  }
  /**
   * Performs the uninterruptable startup sequence of the workspace manager.
   * This methods loads all documents in the workspace and other documents and returns them.
   */
  async performStartup(e) {
    const r = [], n = (s) => {
      r.push(s), this.langiumDocuments.hasDocument(s.uri) || this.langiumDocuments.addDocument(s);
    };
    await this.loadAdditionalDocuments(e, n);
    const i = [];
    await Promise.all(e.map((s) => this.getRootFolder(s)).map(async (s) => this.traverseFolder(s, i)));
    const a = fe(i).distinct((s) => s.toString()).filter((s) => !this.langiumDocuments.hasDocument(s));
    return await this.loadWorkspaceDocuments(a, n), this._ready.resolve(), r;
  }
  async loadWorkspaceDocuments(e, r) {
    await Promise.all(e.map(async (n) => {
      const i = await this.langiumDocuments.getOrCreateDocument(n);
      r(i);
    }));
  }
  /**
   * Load all additional documents that shall be visible in the context of the given workspace
   * folders and add them to the collector. This can be used to include built-in libraries of
   * your language, which can be either loaded from provided files or constructed in memory.
   */
  loadAdditionalDocuments(e, r) {
    return Promise.resolve();
  }
  /**
   * Determine the root folder of the source documents in the given workspace folder.
   * The default implementation returns the URI of the workspace folder, but you can override
   * this to return a subfolder like `src` instead.
   */
  getRootFolder(e) {
    return ft.parse(e.uri);
  }
  /**
   * Traverse the file system folder identified by the given URI and its subfolders. All
   * contained files that match the file extensions are added to the `uris` array.
   */
  async traverseFolder(e, r) {
    try {
      const n = await this.fileSystemProvider.readDirectory(e);
      await Promise.all(n.map(async (i) => {
        this.shouldIncludeEntry(i) && (i.isDirectory ? await this.traverseFolder(i.uri, r) : i.isFile && r.push(i.uri));
      }));
    } catch (n) {
      console.error("Failure to read directory content of " + e.toString(!0), n);
    }
  }
  async searchFolder(e) {
    const r = [];
    return await this.traverseFolder(e, r), r;
  }
  /**
   * Determine whether the given folder entry shall be included while indexing the workspace.
   */
  shouldIncludeEntry(e) {
    const r = Qe.basename(e.uri);
    return r.startsWith(".") ? !1 : e.isDirectory ? r !== "node_modules" && r !== "out" : e.isFile ? this.serviceRegistry.hasServices(e.uri) : !1;
  }
}
class mT {
  buildUnexpectedCharactersMessage(e, r, n, i, a) {
    return ro.buildUnexpectedCharactersMessage(e, r, n, i, a);
  }
  buildUnableToPopLexerModeMessage(e) {
    return ro.buildUnableToPopLexerModeMessage(e);
  }
}
const gT = { mode: "full" };
class yT {
  constructor(e) {
    this.errorMessageProvider = e.parser.LexerErrorMessageProvider, this.tokenBuilder = e.parser.TokenBuilder;
    const r = this.tokenBuilder.buildTokens(e.Grammar, {
      caseInsensitive: e.LanguageMetaData.caseInsensitive
    });
    this.tokenTypes = this.toTokenTypeDictionary(r);
    const n = Lu(r) ? Object.values(r) : r, i = e.LanguageMetaData.mode === "production";
    this.chevrotainLexer = new We(n, {
      positionTracking: "full",
      skipValidations: i,
      errorMessageProvider: this.errorMessageProvider
    });
  }
  get definition() {
    return this.tokenTypes;
  }
  tokenize(e, r = gT) {
    const n = this.chevrotainLexer.tokenize(e);
    return {
      tokens: n.tokens,
      errors: n.errors,
      hidden: n.groups.hidden ?? [],
      report: this.tokenBuilder.flushLexingReport?.(e)
    };
  }
  toTokenTypeDictionary(e) {
    if (Lu(e))
      return e;
    const r = kd(e) ? Object.values(e.modes).flat() : e, n = {};
    return r.forEach((i) => n[i.name] = i), n;
  }
}
function TT(t) {
  return Array.isArray(t) && (t.length === 0 || "name" in t[0]);
}
function kd(t) {
  return t && "modes" in t && "defaultMode" in t;
}
function Lu(t) {
  return !TT(t) && !kd(t);
}
function RT(t, e, r) {
  let n, i;
  typeof t == "string" ? (i = e, n = r) : (i = t.range.start, n = e), i || (i = Z.create(0, 0));
  const a = wd(t), s = Jl(n), o = AT({
    lines: a,
    position: i,
    options: s
  });
  return wT({
    index: 0,
    tokens: o,
    position: i
  });
}
function vT(t, e) {
  const r = Jl(e), n = wd(t);
  if (n.length === 0)
    return !1;
  const i = n[0], a = n[n.length - 1], s = r.start, o = r.end;
  return !!s?.exec(i) && !!o?.exec(a);
}
function wd(t) {
  let e = "";
  return typeof t == "string" ? e = t : e = t.text, e.split($h);
}
const xu = /\s*(@([\p{L}][\p{L}\p{N}]*)?)/uy, ET = /\{(@[\p{L}][\p{L}\p{N}]*)(\s*)([^\r\n}]+)?\}/gu;
function AT(t) {
  const e = [];
  let r = t.position.line, n = t.position.character;
  for (let i = 0; i < t.lines.length; i++) {
    const a = i === 0, s = i === t.lines.length - 1;
    let o = t.lines[i], l = 0;
    if (a && t.options.start) {
      const u = t.options.start?.exec(o);
      u && (l = u.index + u[0].length);
    } else {
      const u = t.options.line?.exec(o);
      u && (l = u.index + u[0].length);
    }
    if (s) {
      const u = t.options.end?.exec(o);
      u && (o = o.substring(0, u.index));
    }
    if (o = o.substring(0, kT(o)), Tl(o, l) >= o.length) {
      if (e.length > 0) {
        const u = Z.create(r, n);
        e.push({
          type: "break",
          content: "",
          range: V.create(u, u)
        });
      }
    } else {
      xu.lastIndex = l;
      const u = xu.exec(o);
      if (u) {
        const d = u[0], p = u[1], m = Z.create(r, n + l), A = Z.create(r, n + l + d.length);
        e.push({
          type: "tag",
          content: p,
          range: V.create(m, A)
        }), l += d.length, l = Tl(o, l);
      }
      if (l < o.length) {
        const d = o.substring(l), p = Array.from(d.matchAll(ET));
        e.push(...$T(p, d, r, n + l));
      }
    }
    r++, n = 0;
  }
  return e.length > 0 && e[e.length - 1].type === "break" ? e.slice(0, -1) : e;
}
function $T(t, e, r, n) {
  const i = [];
  if (t.length === 0) {
    const a = Z.create(r, n), s = Z.create(r, n + e.length);
    i.push({
      type: "text",
      content: e,
      range: V.create(a, s)
    });
  } else {
    let a = 0;
    for (const o of t) {
      const l = o.index, c = e.substring(a, l);
      c.length > 0 && i.push({
        type: "text",
        content: e.substring(a, l),
        range: V.create(Z.create(r, a + n), Z.create(r, l + n))
      });
      let u = c.length + 1;
      const d = o[1];
      if (i.push({
        type: "inline-tag",
        content: d,
        range: V.create(Z.create(r, a + u + n), Z.create(r, a + u + d.length + n))
      }), u += d.length, o.length === 4) {
        u += o[2].length;
        const p = o[3];
        i.push({
          type: "text",
          content: p,
          range: V.create(Z.create(r, a + u + n), Z.create(r, a + u + p.length + n))
        });
      } else
        i.push({
          type: "text",
          content: "",
          range: V.create(Z.create(r, a + u + n), Z.create(r, a + u + n))
        });
      a = l + o[0].length;
    }
    const s = e.substring(a);
    s.length > 0 && i.push({
      type: "text",
      content: s,
      range: V.create(Z.create(r, a + n), Z.create(r, a + n + s.length))
    });
  }
  return i;
}
const CT = /\S/, ST = /\s*$/;
function Tl(t, e) {
  const r = t.substring(e).match(CT);
  return r ? e + r.index : t.length;
}
function kT(t) {
  const e = t.match(ST);
  if (e && typeof e.index == "number")
    return e.index;
}
function wT(t) {
  const e = Z.create(t.position.line, t.position.character);
  if (t.tokens.length === 0)
    return new Du([], V.create(e, e));
  const r = [];
  for (; t.index < t.tokens.length; ) {
    const a = bT(t, r[r.length - 1]);
    a && r.push(a);
  }
  const n = r[0]?.range.start ?? e, i = r[r.length - 1]?.range.end ?? e;
  return new Du(r, V.create(n, i));
}
function bT(t, e) {
  const r = t.tokens[t.index];
  if (r.type === "tag")
    return Nd(t, !1);
  if (r.type === "text" || r.type === "inline-tag")
    return bd(t);
  NT(r, e), t.index++;
}
function NT(t, e) {
  if (e) {
    const r = new Id("", t.range);
    "inlines" in e ? e.inlines.push(r) : e.content.inlines.push(r);
  }
}
function bd(t) {
  let e = t.tokens[t.index];
  const r = e;
  let n = e;
  const i = [];
  for (; e && e.type !== "break" && e.type !== "tag"; )
    i.push(_T(t)), n = e, e = t.tokens[t.index];
  return new Rl(i, V.create(r.range.start, n.range.end));
}
function _T(t) {
  return t.tokens[t.index].type === "inline-tag" ? Nd(t, !0) : _d(t);
}
function Nd(t, e) {
  const r = t.tokens[t.index++], n = r.content.substring(1);
  if (t.tokens[t.index]?.type === "text")
    if (e) {
      const a = _d(t);
      return new Is(n, new Rl([a], a.range), e, V.create(r.range.start, a.range.end));
    } else {
      const a = bd(t);
      return new Is(n, a, e, V.create(r.range.start, a.range.end));
    }
  else {
    const a = r.range;
    return new Is(n, new Rl([], a), e, a);
  }
}
function _d(t) {
  const e = t.tokens[t.index++];
  return new Id(e.content, e.range);
}
function Jl(t) {
  if (!t)
    return Jl({
      start: "/**",
      end: "*/",
      line: "*"
    });
  const { start: e, end: r, line: n } = t;
  return {
    start: _s(e, !0),
    end: _s(r, !1),
    line: _s(n, !0)
  };
}
function _s(t, e) {
  if (typeof t == "string" || typeof t == "object") {
    const r = typeof t == "string" ? ts(t) : t.source;
    return e ? new RegExp(`^\\s*${r}`) : new RegExp(`\\s*${r}\\s*$`);
  } else
    return t;
}
class Du {
  constructor(e, r) {
    this.elements = e, this.range = r;
  }
  getTag(e) {
    return this.getAllTags().find((r) => r.name === e);
  }
  getTags(e) {
    return this.getAllTags().filter((r) => r.name === e);
  }
  getAllTags() {
    return this.elements.filter((e) => "name" in e);
  }
  toString() {
    let e = "";
    for (const r of this.elements)
      if (e.length === 0)
        e = r.toString();
      else {
        const n = r.toString();
        e += Mu(e) + n;
      }
    return e.trim();
  }
  toMarkdown(e) {
    let r = "";
    for (const n of this.elements)
      if (r.length === 0)
        r = n.toMarkdown(e);
      else {
        const i = n.toMarkdown(e);
        r += Mu(r) + i;
      }
    return r.trim();
  }
}
class Is {
  constructor(e, r, n, i) {
    this.name = e, this.content = r, this.inline = n, this.range = i;
  }
  toString() {
    let e = `@${this.name}`;
    const r = this.content.toString();
    return this.content.inlines.length === 1 ? e = `${e} ${r}` : this.content.inlines.length > 1 && (e = `${e}
${r}`), this.inline ? `{${e}}` : e;
  }
  toMarkdown(e) {
    return e?.renderTag?.(this) ?? this.toMarkdownDefault(e);
  }
  toMarkdownDefault(e) {
    const r = this.content.toMarkdown(e);
    if (this.inline) {
      const a = IT(this.name, r, e ?? {});
      if (typeof a == "string")
        return a;
    }
    let n = "";
    e?.tag === "italic" || e?.tag === void 0 ? n = "*" : e?.tag === "bold" ? n = "**" : e?.tag === "bold-italic" && (n = "***");
    let i = `${n}@${this.name}${n}`;
    return this.content.inlines.length === 1 ? i = `${i} — ${r}` : this.content.inlines.length > 1 && (i = `${i}
${r}`), this.inline ? `{${i}}` : i;
  }
}
function IT(t, e, r) {
  if (t === "linkplain" || t === "linkcode" || t === "link") {
    const n = e.indexOf(" ");
    let i = e;
    if (n > 0) {
      const s = Tl(e, n);
      i = e.substring(s), e = e.substring(0, n);
    }
    return (t === "linkcode" || t === "link" && r.link === "code") && (i = `\`${i}\``), r.renderLink?.(e, i) ?? PT(e, i);
  }
}
function PT(t, e) {
  try {
    return ft.parse(t, !0), `[${e}](${t})`;
  } catch {
    return t;
  }
}
class Rl {
  constructor(e, r) {
    this.inlines = e, this.range = r;
  }
  toString() {
    let e = "";
    for (let r = 0; r < this.inlines.length; r++) {
      const n = this.inlines[r], i = this.inlines[r + 1];
      e += n.toString(), i && i.range.start.line > n.range.start.line && (e += `
`);
    }
    return e;
  }
  toMarkdown(e) {
    let r = "";
    for (let n = 0; n < this.inlines.length; n++) {
      const i = this.inlines[n], a = this.inlines[n + 1];
      r += i.toMarkdown(e), a && a.range.start.line > i.range.start.line && (r += `
`);
    }
    return r;
  }
}
class Id {
  constructor(e, r) {
    this.text = e, this.range = r;
  }
  toString() {
    return this.text;
  }
  toMarkdown() {
    return this.text;
  }
}
function Mu(t) {
  return t.endsWith(`
`) ? `
` : `

`;
}
class OT {
  constructor(e) {
    this.indexManager = e.shared.workspace.IndexManager, this.commentProvider = e.documentation.CommentProvider;
  }
  getDocumentation(e) {
    const r = this.commentProvider.getComment(e);
    if (r && vT(r))
      return RT(r).toMarkdown({
        renderLink: (i, a) => this.documentationLinkRenderer(e, i, a),
        renderTag: (i) => this.documentationTagRenderer(e, i)
      });
  }
  documentationLinkRenderer(e, r, n) {
    const i = this.findNameInLocalSymbols(e, r) ?? this.findNameInGlobalScope(e, r);
    if (i && i.nameSegment) {
      const a = i.nameSegment.range.start.line + 1, s = i.nameSegment.range.start.character + 1, o = i.documentUri.with({ fragment: `L${a},${s}` });
      return `[${n}](${o.toString()})`;
    } else
      return;
  }
  documentationTagRenderer(e, r) {
  }
  findNameInLocalSymbols(e, r) {
    const i = Gt(e).localSymbols;
    if (!i)
      return;
    let a = e;
    do {
      const o = i.getStream(a).find((l) => l.name === r);
      if (o)
        return o;
      a = a.$container;
    } while (a);
  }
  findNameInGlobalScope(e, r) {
    return this.indexManager.allElements().find((i) => i.name === r);
  }
}
class LT {
  constructor(e) {
    this.grammarConfig = () => e.parser.GrammarConfig;
  }
  getComment(e) {
    return Ey(e) ? e.$comment : Th(e.$cstNode, this.grammarConfig().multilineCommentRules)?.text;
  }
}
class xT {
  constructor(e) {
    this.syncParser = e.parser.LangiumParser;
  }
  parse(e, r) {
    return Promise.resolve(this.syncParser.parse(e));
  }
}
class DT {
  constructor() {
    this.previousTokenSource = new he.CancellationTokenSource(), this.writeQueue = [], this.readQueue = [], this.done = !0;
  }
  write(e) {
    this.cancelWrite();
    const r = sy();
    return this.previousTokenSource = r, this.enqueue(this.writeQueue, e, r.token);
  }
  read(e) {
    return this.enqueue(this.readQueue, e);
  }
  enqueue(e, r, n = he.CancellationToken.None) {
    const i = new Hl(), a = {
      action: r,
      deferred: i,
      cancellationToken: n
    };
    return e.push(a), this.performNextOperation(), i.promise;
  }
  async performNextOperation() {
    if (!this.done)
      return;
    const e = [];
    if (this.writeQueue.length > 0)
      e.push(this.writeQueue.shift());
    else if (this.readQueue.length > 0)
      e.push(...this.readQueue.splice(0, this.readQueue.length));
    else
      return;
    this.done = !1, await Promise.all(e.map(async ({ action: r, deferred: n, cancellationToken: i }) => {
      try {
        const a = await Promise.resolve().then(() => r(i));
        n.resolve(a);
      } catch (a) {
        fs(a) ? n.resolve(void 0) : n.reject(a);
      }
    })), this.done = !0, this.performNextOperation();
  }
  cancelWrite() {
    this.previousTokenSource.cancel();
  }
}
class MT {
  constructor(e) {
    this.grammarElementIdMap = new Bc(), this.tokenTypeIdMap = new Bc(), this.grammar = e.Grammar, this.lexer = e.parser.Lexer, this.linker = e.references.Linker;
  }
  dehydrate(e) {
    return {
      lexerErrors: e.lexerErrors,
      lexerReport: e.lexerReport ? this.dehydrateLexerReport(e.lexerReport) : void 0,
      // We need to create shallow copies of the errors
      // The original errors inherit from the `Error` class, which is not transferable across worker threads
      parserErrors: e.parserErrors.map((r) => ({ ...r, message: r.message })),
      value: this.dehydrateAstNode(e.value, this.createDehyrationContext(e.value))
    };
  }
  dehydrateLexerReport(e) {
    return e;
  }
  createDehyrationContext(e) {
    const r = /* @__PURE__ */ new Map(), n = /* @__PURE__ */ new Map();
    for (const i of jt(e))
      r.set(i, {});
    if (e.$cstNode)
      for (const i of Js(e.$cstNode))
        n.set(i, {});
    return {
      astNodes: r,
      cstNodes: n
    };
  }
  dehydrateAstNode(e, r) {
    const n = r.astNodes.get(e);
    n.$type = e.$type, n.$containerIndex = e.$containerIndex, n.$containerProperty = e.$containerProperty, e.$cstNode !== void 0 && (n.$cstNode = this.dehydrateCstNode(e.$cstNode, r));
    for (const [i, a] of Object.entries(e))
      if (!i.startsWith("$"))
        if (Array.isArray(a)) {
          const s = [];
          n[i] = s;
          for (const o of a)
            Fe(o) ? s.push(this.dehydrateAstNode(o, r)) : ut(o) ? s.push(this.dehydrateReference(o, r)) : s.push(o);
        } else Fe(a) ? n[i] = this.dehydrateAstNode(a, r) : ut(a) ? n[i] = this.dehydrateReference(a, r) : a !== void 0 && (n[i] = a);
    return n;
  }
  dehydrateReference(e, r) {
    const n = {};
    return n.$refText = e.$refText, e.$refNode && (n.$refNode = r.cstNodes.get(e.$refNode)), n;
  }
  dehydrateCstNode(e, r) {
    const n = r.cstNodes.get(e);
    return tf(e) ? n.fullText = e.fullText : n.grammarSource = this.getGrammarElementId(e.grammarSource), n.hidden = e.hidden, n.astNode = r.astNodes.get(e.astNode), ci(e) ? n.content = e.content.map((i) => this.dehydrateCstNode(i, r)) : ef(e) && (n.tokenType = e.tokenType.name, n.offset = e.offset, n.length = e.length, n.startLine = e.range.start.line, n.startColumn = e.range.start.character, n.endLine = e.range.end.line, n.endColumn = e.range.end.character), n;
  }
  hydrate(e) {
    const r = e.value, n = this.createHydrationContext(r);
    return "$cstNode" in r && this.hydrateCstNode(r.$cstNode, n), {
      lexerErrors: e.lexerErrors,
      lexerReport: e.lexerReport,
      parserErrors: e.parserErrors,
      value: this.hydrateAstNode(r, n)
    };
  }
  createHydrationContext(e) {
    const r = /* @__PURE__ */ new Map(), n = /* @__PURE__ */ new Map();
    for (const a of jt(e))
      r.set(a, {});
    let i;
    if (e.$cstNode)
      for (const a of Js(e.$cstNode)) {
        let s;
        "fullText" in a ? (s = new cd(a.fullText), i = s) : "content" in a ? s = new Wl() : "tokenType" in a && (s = this.hydrateCstLeafNode(a)), s && (n.set(a, s), s.root = i);
      }
    return {
      astNodes: r,
      cstNodes: n
    };
  }
  hydrateAstNode(e, r) {
    const n = r.astNodes.get(e);
    n.$type = e.$type, n.$containerIndex = e.$containerIndex, n.$containerProperty = e.$containerProperty, e.$cstNode && (n.$cstNode = r.cstNodes.get(e.$cstNode));
    for (const [i, a] of Object.entries(e))
      if (!i.startsWith("$"))
        if (Array.isArray(a)) {
          const s = [];
          n[i] = s;
          for (const o of a)
            Fe(o) ? s.push(this.setParent(this.hydrateAstNode(o, r), n)) : ut(o) ? s.push(this.hydrateReference(o, n, i, r)) : s.push(o);
        } else Fe(a) ? n[i] = this.setParent(this.hydrateAstNode(a, r), n) : ut(a) ? n[i] = this.hydrateReference(a, n, i, r) : a !== void 0 && (n[i] = a);
    return n;
  }
  setParent(e, r) {
    return e.$container = r, e;
  }
  hydrateReference(e, r, n, i) {
    return this.linker.buildReference(r, n, i.cstNodes.get(e.$refNode), e.$refText);
  }
  hydrateCstNode(e, r, n = 0) {
    const i = r.cstNodes.get(e);
    if (typeof e.grammarSource == "number" && (i.grammarSource = this.getGrammarElement(e.grammarSource)), i.astNode = r.astNodes.get(e.astNode), ci(i))
      for (const a of e.content) {
        const s = this.hydrateCstNode(a, r, n++);
        i.content.push(s);
      }
    return i;
  }
  hydrateCstLeafNode(e) {
    const r = this.getTokenType(e.tokenType), n = e.offset, i = e.length, a = e.startLine, s = e.startColumn, o = e.endLine, l = e.endColumn, c = e.hidden;
    return new fl(n, i, {
      start: {
        line: a,
        character: s
      },
      end: {
        line: o,
        character: l
      }
    }, r, c);
  }
  getTokenType(e) {
    return this.lexer.definition[e];
  }
  getGrammarElementId(e) {
    if (e)
      return this.grammarElementIdMap.size === 0 && this.createGrammarElementIdMap(), this.grammarElementIdMap.get(e);
  }
  getGrammarElement(e) {
    return this.grammarElementIdMap.size === 0 && this.createGrammarElementIdMap(), this.grammarElementIdMap.getKey(e);
  }
  createGrammarElementIdMap() {
    let e = 0;
    for (const r of jt(this.grammar))
      Xd(r) && this.grammarElementIdMap.set(r, e++);
  }
}
function vt(t) {
  return {
    documentation: {
      CommentProvider: (e) => new LT(e),
      DocumentationProvider: (e) => new OT(e)
    },
    parser: {
      AsyncParser: (e) => new xT(e),
      GrammarConfig: (e) => Wh(e),
      LangiumParser: (e) => ry(e),
      CompletionParser: (e) => ty(e),
      ValueConverter: () => new Td(),
      TokenBuilder: () => new yd(),
      Lexer: (e) => new yT(e),
      ParserErrorMessageProvider: () => new dd(),
      LexerErrorMessageProvider: () => new mT()
    },
    workspace: {
      AstNodeLocator: () => new Iy(),
      AstNodeDescriptionProvider: (e) => new Ny(e),
      ReferenceDescriptionProvider: (e) => new _y(e)
    },
    references: {
      Linker: (e) => new fy(e),
      NameProvider: () => new hy(),
      ScopeProvider: (e) => new vy(e),
      ScopeComputation: (e) => new my(e),
      References: (e) => new py(e)
    },
    serializer: {
      Hydrator: (e) => new MT(e),
      JsonSerializer: (e) => new Ay(e)
    },
    validation: {
      DocumentValidator: (e) => new ky(e),
      ValidationRegistry: (e) => new Cy(e)
    },
    shared: () => t.shared
  };
}
function Et(t) {
  return {
    ServiceRegistry: (e) => new $y(e),
    workspace: {
      LangiumDocuments: (e) => new uy(e),
      LangiumDocumentFactory: (e) => new cy(e),
      DocumentBuilder: (e) => new dT(e),
      IndexManager: (e) => new hT(e),
      WorkspaceManager: (e) => new pT(e),
      FileSystemProvider: (e) => t.fileSystemProvider(e),
      WorkspaceLock: () => new DT(),
      ConfigurationProvider: (e) => new Oy(e)
    },
    profilers: {}
  };
}
var Fu;
(function(t) {
  t.merge = (e, r) => vi(vi({}, e), r);
})(Fu || (Fu = {}));
function ke(t, e, r, n, i, a, s, o, l) {
  const c = [t, e, r, n, i, a, s, o, l].reduce(vi, {});
  return Pd(c);
}
const FT = Symbol("isProxy");
function Pd(t, e) {
  const r = new Proxy({}, {
    deleteProperty: () => !1,
    set: () => {
      throw new Error("Cannot set property on injected service container");
    },
    get: (n, i) => i === FT ? !0 : ju(n, i, t, e || r),
    getOwnPropertyDescriptor: (n, i) => (ju(n, i, t, e || r), Object.getOwnPropertyDescriptor(n, i)),
    // used by for..in
    has: (n, i) => i in t,
    // used by ..in..
    ownKeys: () => [...Object.getOwnPropertyNames(t)]
    // used by for..in
  });
  return r;
}
const Gu = Symbol();
function ju(t, e, r, n) {
  if (e in t) {
    if (t[e] instanceof Error)
      throw new Error("Construction failure. Please make sure that your dependencies are constructable. Cause: " + t[e]);
    if (t[e] === Gu)
      throw new Error('Cycle detected. Please make "' + String(e) + '" lazy. Visit https://langium.org/docs/reference/configuration-services/#resolving-cyclic-dependencies');
    return t[e];
  } else if (e in r) {
    const i = r[e];
    t[e] = Gu;
    try {
      t[e] = typeof i == "function" ? i(n) : Pd(i, n);
    } catch (a) {
      throw t[e] = a instanceof Error ? a : void 0, a;
    }
    return t[e];
  } else
    return;
}
function vi(t, e) {
  if (e) {
    for (const [r, n] of Object.entries(e))
      if (n != null)
        if (typeof n == "object") {
          const i = t[r];
          typeof i == "object" && i !== null ? t[r] = vi(i, n) : t[r] = vi({}, n);
        } else
          t[r] = n;
  }
  return t;
}
class GT {
  stat(e) {
    throw new Error("No file system is available.");
  }
  statSync(e) {
    throw new Error("No file system is available.");
  }
  async exists() {
    return !1;
  }
  existsSync() {
    return !1;
  }
  readBinary() {
    throw new Error("No file system is available.");
  }
  readBinarySync() {
    throw new Error("No file system is available.");
  }
  readFile() {
    throw new Error("No file system is available.");
  }
  readFileSync() {
    throw new Error("No file system is available.");
  }
  async readDirectory() {
    return [];
  }
  readDirectorySync() {
    return [];
  }
}
const At = {
  fileSystemProvider: () => new GT()
}, jT = {
  Grammar: () => {
  },
  LanguageMetaData: () => ({
    caseInsensitive: !1,
    fileExtensions: [".langium"],
    languageId: "langium"
  })
}, zT = {
  AstReflection: () => new lf()
};
function UT() {
  const t = ke(Et(At), zT), e = ke(vt({ shared: t }), jT);
  return t.ServiceRegistry.register(e), e;
}
function Wt(t) {
  const e = UT(), r = e.serializer.JsonSerializer.deserialize(t);
  return e.shared.workspace.LangiumDocumentFactory.fromModel(r, ft.parse(`memory:/${r.name ?? "grammar"}.langium`)), r;
}
var qT = Object.defineProperty, _ = (t, e) => qT(t, "name", { value: e, configurable: !0 }), vl;
((t) => {
  t.Terminals = {
    ARROW_DIRECTION: /L|R|T|B/,
    ARROW_GROUP: /\{group\}/,
    ARROW_INTO: /<|>/,
    ACC_DESCR: /[\t ]*accDescr(?:[\t ]*:([^\n\r]*?(?=%%)|[^\n\r]*)|\s*{([^}]*)})/,
    ACC_TITLE: /[\t ]*accTitle[\t ]*:(?:[^\n\r]*?(?=%%)|[^\n\r]*)/,
    TITLE: /[\t ]*title(?:[\t ][^\n\r]*?(?=%%)|[\t ][^\n\r]*|)/,
    STRING: /"([^"\\]|\\.)*"|'([^'\\]|\\.)*'/,
    ID: /[\w]([-\w]*\w)?/,
    NEWLINE: /\r?\n/,
    WHITESPACE: /[\t ]+/,
    YAML: /---[\t ]*\r?\n(?:[\S\s]*?\r?\n)?---(?:\r?\n|(?!\S))/,
    DIRECTIVE: /[\t ]*%%{[\S\s]*?}%%(?:\r?\n|(?!\S))/,
    SINGLE_LINE_COMMENT: /[\t ]*%%[^\n\r]*/,
    ARCH_ICON: /\([\w-:]+\)/,
    ARCH_TITLE: /\[(?:"([^"\\]|\\.)*"|'([^'\\]|\\.)*'|[\w ]+)\]/
  };
})(vl || (vl = {}));
var El;
((t) => {
  t.Terminals = {
    ACC_DESCR: /[\t ]*accDescr(?:[\t ]*:([^\n\r]*?(?=%%)|[^\n\r]*)|\s*{([^}]*)})/,
    ACC_TITLE: /[\t ]*accTitle[\t ]*:(?:[^\n\r]*?(?=%%)|[^\n\r]*)/,
    TITLE: /[\t ]*title(?:[\t ][^\n\r]*?(?=%%)|[\t ][^\n\r]*|)/,
    INT: /0|[1-9][0-9]*(?!\.)/,
    STRING: /"([^"\\]|\\.)*"|'([^'\\]|\\.)*'/,
    NEWLINE: /\r?\n/,
    WHITESPACE: /[\t ]+/,
    YAML: /---[\t ]*\r?\n(?:[\S\s]*?\r?\n)?---(?:\r?\n|(?!\S))/,
    DIRECTIVE: /[\t ]*%%{[\S\s]*?}%%(?:\r?\n|(?!\S))/,
    SINGLE_LINE_COMMENT: /[\t ]*%%[^\n\r]*/,
    REFERENCE: /\w([-\./\w]*[-\w])?/
  };
})(El || (El = {}));
var Al;
((t) => {
  t.Terminals = {
    ACC_DESCR: /[\t ]*accDescr(?:[\t ]*:([^\n\r]*?(?=%%)|[^\n\r]*)|\s*{([^}]*)})/,
    ACC_TITLE: /[\t ]*accTitle[\t ]*:(?:[^\n\r]*?(?=%%)|[^\n\r]*)/,
    TITLE: /[\t ]*title(?:[\t ][^\n\r]*?(?=%%)|[\t ][^\n\r]*|)/,
    NEWLINE: /\r?\n/,
    WHITESPACE: /[\t ]+/,
    YAML: /---[\t ]*\r?\n(?:[\S\s]*?\r?\n)?---(?:\r?\n|(?!\S))/,
    DIRECTIVE: /[\t ]*%%{[\S\s]*?}%%(?:\r?\n|(?!\S))/,
    SINGLE_LINE_COMMENT: /[\t ]*%%[^\n\r]*/
  };
})(Al || (Al = {}));
var $l;
((t) => {
  t.Terminals = {
    ACC_DESCR: /[\t ]*accDescr(?:[\t ]*:([^\n\r]*?(?=%%)|[^\n\r]*)|\s*{([^}]*)})/,
    ACC_TITLE: /[\t ]*accTitle[\t ]*:(?:[^\n\r]*?(?=%%)|[^\n\r]*)/,
    TITLE: /[\t ]*title(?:[\t ][^\n\r]*?(?=%%)|[\t ][^\n\r]*|)/,
    INT: /0|[1-9][0-9]*(?!\.)/,
    STRING: /"([^"\\]|\\.)*"|'([^'\\]|\\.)*'/,
    NEWLINE: /\r?\n/,
    WHITESPACE: /[\t ]+/,
    YAML: /---[\t ]*\r?\n(?:[\S\s]*?\r?\n)?---(?:\r?\n|(?!\S))/,
    DIRECTIVE: /[\t ]*%%{[\S\s]*?}%%(?:\r?\n|(?!\S))/,
    SINGLE_LINE_COMMENT: /[\t ]*%%[^\n\r]*/
  };
})($l || ($l = {}));
var Cl;
((t) => {
  t.Terminals = {
    NUMBER_PIE: /(?:-?[0-9]+\.[0-9]+(?!\.))|(?:-?(0|[1-9][0-9]*)(?!\.))/,
    ACC_DESCR: /[\t ]*accDescr(?:[\t ]*:([^\n\r]*?(?=%%)|[^\n\r]*)|\s*{([^}]*)})/,
    ACC_TITLE: /[\t ]*accTitle[\t ]*:(?:[^\n\r]*?(?=%%)|[^\n\r]*)/,
    TITLE: /[\t ]*title(?:[\t ][^\n\r]*?(?=%%)|[\t ][^\n\r]*|)/,
    STRING: /"([^"\\]|\\.)*"|'([^'\\]|\\.)*'/,
    NEWLINE: /\r?\n/,
    WHITESPACE: /[\t ]+/,
    YAML: /---[\t ]*\r?\n(?:[\S\s]*?\r?\n)?---(?:\r?\n|(?!\S))/,
    DIRECTIVE: /[\t ]*%%{[\S\s]*?}%%(?:\r?\n|(?!\S))/,
    SINGLE_LINE_COMMENT: /[\t ]*%%[^\n\r]*/
  };
})(Cl || (Cl = {}));
var Sl;
((t) => {
  t.Terminals = {
    GRATICULE: /circle|polygon/,
    BOOLEAN: /true|false/,
    ACC_DESCR: /[\t ]*accDescr(?:[\t ]*:([^\n\r]*?(?=%%)|[^\n\r]*)|\s*{([^}]*)})/,
    ACC_TITLE: /[\t ]*accTitle[\t ]*:(?:[^\n\r]*?(?=%%)|[^\n\r]*)/,
    TITLE: /[\t ]*title(?:[\t ][^\n\r]*?(?=%%)|[\t ][^\n\r]*|)/,
    NUMBER: /(?:[0-9]+\.[0-9]+(?!\.))|(?:0|[1-9][0-9]*(?!\.))/,
    STRING: /"([^"\\]|\\.)*"|'([^'\\]|\\.)*'/,
    ID: /[\w]([-\w]*\w)?/,
    NEWLINE: /\r?\n/,
    WHITESPACE: /[\t ]+/,
    YAML: /---[\t ]*\r?\n(?:[\S\s]*?\r?\n)?---(?:\r?\n|(?!\S))/,
    DIRECTIVE: /[\t ]*%%{[\S\s]*?}%%(?:\r?\n|(?!\S))/,
    SINGLE_LINE_COMMENT: /[\t ]*%%[^\n\r]*/
  };
})(Sl || (Sl = {}));
var kl;
((t) => {
  t.Terminals = {
    ACC_DESCR: /[\t ]*accDescr(?:[\t ]*:([^\n\r]*?(?=%%)|[^\n\r]*)|\s*{([^}]*)})/,
    ACC_TITLE: /[\t ]*accTitle[\t ]*:(?:[^\n\r]*?(?=%%)|[^\n\r]*)/,
    TITLE: /[\t ]*title(?:[\t ][^\n\r]*?(?=%%)|[\t ][^\n\r]*|)/,
    TREEMAP_KEYWORD: /treemap-beta|treemap/,
    CLASS_DEF: /classDef\s+([a-zA-Z_][a-zA-Z0-9_]+)(?:\s+([^;\r\n]*))?(?:;)?/,
    STYLE_SEPARATOR: /:::/,
    SEPARATOR: /:/,
    COMMA: /,/,
    INDENTATION: /[ \t]{1,}/,
    WS: /[ \t]+/,
    ML_COMMENT: /\%\%[^\n]*/,
    NL: /\r?\n/,
    ID2: /[a-zA-Z_][a-zA-Z0-9_]*/,
    NUMBER2: /[0-9_\.\,]+/,
    STRING2: /"[^"]*"|'[^']*'/
  };
})(kl || (kl = {}));
var wl;
((t) => {
  t.Terminals = {
    ACC_DESCR: /[\t ]*accDescr(?:[\t ]*:([^\n\r]*?(?=%%)|[^\n\r]*)|\s*{([^}]*)})/,
    ACC_TITLE: /[\t ]*accTitle[\t ]*:(?:[^\n\r]*?(?=%%)|[^\n\r]*)/,
    TITLE: /[\t ]*title(?:[\t ][^\n\r]*?(?=%%)|[\t ][^\n\r]*|)/,
    INDENTATION: /[ \t]{1,}/,
    WS: /[ \t]+/,
    ML_COMMENT: /\%\%[^\n]*/,
    NL: /\r?\n/,
    STRING2: /"[^"]*"|'[^']*'/
  };
})(wl || (wl = {}));
var bl;
((t) => {
  t.Terminals = {
    WARDLEY_NUMBER: /[0-9]+\.[0-9]+/,
    ARROW: /->/,
    LINK_PORT: /\+<>|\+>|\+</,
    LINK_ARROW: /-->|-\.->|>|\+'[^']*'<>|\+'[^']*'<|\+'[^']*'>/,
    LINK_LABEL: /;[^\n\r]+/,
    STRATEGY: /build|buy|outsource|market/,
    KW_WARDLEY: /wardley-beta/,
    KW_SIZE: /size/,
    KW_EVOLUTION: /evolution/,
    KW_ANCHOR: /anchor/,
    KW_COMPONENT: /component/,
    KW_LABEL: /label/,
    KW_INERTIA: /inertia/,
    KW_EVOLVE: /evolve/,
    KW_PIPELINE: /pipeline/,
    KW_NOTE: /note/,
    KW_ANNOTATIONS: /annotations/,
    KW_ANNOTATION: /annotation/,
    KW_ACCELERATOR: /accelerator/,
    KW_DEACCELERATOR: /deaccelerator/,
    NAME_WITH_SPACES: /(?!title\s|accTitle|accDescr)[A-Za-z][A-Za-z0-9_()&]*(?:[ \t]+[A-Za-z(][A-Za-z0-9_()&]*)*/,
    WS: /[ \t]+/,
    ACC_DESCR: /[\t ]*accDescr(?:[\t ]*:([^\n\r]*?(?=%%)|[^\n\r]*)|\s*{([^}]*)})/,
    ACC_TITLE: /[\t ]*accTitle[\t ]*:(?:[^\n\r]*?(?=%%)|[^\n\r]*)/,
    TITLE: /[\t ]*title(?:[\t ][^\n\r]*?(?=%%)|[\t ][^\n\r]*|)/,
    INT: /0|[1-9][0-9]*(?!\.)/,
    STRING: /"([^"\\]|\\.)*"|'([^'\\]|\\.)*'/,
    ID: /[\w]([-\w]*\w)?/,
    NEWLINE: /\r?\n/,
    WHITESPACE: /[\t ]+/,
    YAML: /---[\t ]*\r?\n(?:[\S\s]*?\r?\n)?---(?:\r?\n|(?!\S))/,
    DIRECTIVE: /[\t ]*%%{[\S\s]*?}%%(?:\r?\n|(?!\S))/,
    SINGLE_LINE_COMMENT: /[\t ]*%%[^\n\r]*/
  };
})(bl || (bl = {}));
({
  ...vl.Terminals,
  ...El.Terminals,
  ...Al.Terminals,
  ...$l.Terminals,
  ...Cl.Terminals,
  ...Sl.Terminals,
  ...wl.Terminals,
  ...kl.Terminals,
  ...bl.Terminals
});
var ia = {
  $type: "Accelerator",
  name: "name",
  x: "x",
  y: "y"
}, aa = {
  $type: "Anchor",
  evolution: "evolution",
  name: "name",
  visibility: "visibility"
}, Hn = {
  $type: "Annotation",
  number: "number",
  text: "text",
  x: "x",
  y: "y"
}, Ps = {
  $type: "Annotations",
  x: "x",
  y: "y"
}, Lt = {
  $type: "Architecture",
  accDescr: "accDescr",
  accTitle: "accTitle",
  edges: "edges",
  groups: "groups",
  junctions: "junctions",
  services: "services",
  title: "title"
};
function BT(t) {
  return nt.isInstance(t, Lt.$type);
}
_(BT, "isArchitecture");
var sa = {
  $type: "Axis",
  label: "label",
  name: "name"
}, wa = {
  $type: "Branch",
  name: "name",
  order: "order"
};
function WT(t) {
  return nt.isInstance(t, wa.$type);
}
_(WT, "isBranch");
var zu = {
  $type: "Checkout",
  branch: "branch"
}, oa = {
  $type: "CherryPicking",
  id: "id",
  parent: "parent",
  tags: "tags"
}, Os = {
  $type: "ClassDefStatement",
  className: "className",
  styleText: "styleText"
}, Yr = {
  $type: "Commit",
  id: "id",
  message: "message",
  tags: "tags",
  type: "type"
};
function KT(t) {
  return nt.isInstance(t, Yr.$type);
}
_(KT, "isCommit");
var mr = {
  $type: "Component",
  decorator: "decorator",
  evolution: "evolution",
  inertia: "inertia",
  label: "label",
  name: "name",
  visibility: "visibility"
}, la = {
  $type: "Curve",
  entries: "entries",
  label: "label",
  name: "name"
}, ca = {
  $type: "Deaccelerator",
  name: "name",
  x: "x",
  y: "y"
}, Uu = {
  $type: "Decorator",
  strategy: "strategy"
}, Gr = {
  $type: "Direction",
  accDescr: "accDescr",
  accTitle: "accTitle",
  dir: "dir",
  statements: "statements",
  title: "title"
}, ht = {
  $type: "Edge",
  lhsDir: "lhsDir",
  lhsGroup: "lhsGroup",
  lhsId: "lhsId",
  lhsInto: "lhsInto",
  rhsDir: "rhsDir",
  rhsGroup: "rhsGroup",
  rhsId: "rhsId",
  rhsInto: "rhsInto",
  title: "title"
}, Ls = {
  $type: "Entry",
  axis: "axis",
  value: "value"
}, qu = {
  $type: "Evolution",
  stages: "stages"
}, ua = {
  $type: "EvolutionStage",
  boundary: "boundary",
  name: "name",
  secondName: "secondName"
}, xs = {
  $type: "Evolve",
  component: "component",
  target: "target"
}, Ar = {
  $type: "GitGraph",
  accDescr: "accDescr",
  accTitle: "accTitle",
  statements: "statements",
  title: "title"
};
function VT(t) {
  return nt.isInstance(t, Ar.$type);
}
_(VT, "isGitGraph");
var Xn = {
  $type: "Group",
  icon: "icon",
  id: "id",
  in: "in",
  title: "title"
}, oi = {
  $type: "Info",
  accDescr: "accDescr",
  accTitle: "accTitle",
  title: "title"
};
function HT(t) {
  return nt.isInstance(t, oi.$type);
}
_(HT, "isInfo");
var Yn = {
  $type: "Item",
  classSelector: "classSelector",
  name: "name"
}, Ds = {
  $type: "Junction",
  id: "id",
  in: "in"
}, Jn = {
  $type: "Label",
  negX: "negX",
  negY: "negY",
  offsetX: "offsetX",
  offsetY: "offsetY"
}, fa = {
  $type: "Leaf",
  classSelector: "classSelector",
  name: "name",
  value: "value"
}, gr = {
  $type: "Link",
  arrow: "arrow",
  from: "from",
  fromPort: "fromPort",
  linkLabel: "linkLabel",
  to: "to",
  toPort: "toPort"
}, Jr = {
  $type: "Merge",
  branch: "branch",
  id: "id",
  tags: "tags",
  type: "type"
};
function XT(t) {
  return nt.isInstance(t, Jr.$type);
}
_(XT, "isMerge");
var da = {
  $type: "Note",
  evolution: "evolution",
  text: "text",
  visibility: "visibility"
}, Ms = {
  $type: "Option",
  name: "name",
  value: "value"
}, Zr = {
  $type: "Packet",
  accDescr: "accDescr",
  accTitle: "accTitle",
  blocks: "blocks",
  title: "title"
};
function YT(t) {
  return nt.isInstance(t, Zr.$type);
}
_(YT, "isPacket");
var Qr = {
  $type: "PacketBlock",
  bits: "bits",
  end: "end",
  label: "label",
  start: "start"
};
function JT(t) {
  return nt.isInstance(t, Qr.$type);
}
_(JT, "isPacketBlock");
var $r = {
  $type: "Pie",
  accDescr: "accDescr",
  accTitle: "accTitle",
  sections: "sections",
  showData: "showData",
  title: "title"
};
function ZT(t) {
  return nt.isInstance(t, $r.$type);
}
_(ZT, "isPie");
var ba = {
  $type: "PieSection",
  label: "label",
  value: "value"
};
function QT(t) {
  return nt.isInstance(t, ba.$type);
}
_(QT, "isPieSection");
var Fs = {
  $type: "Pipeline",
  components: "components",
  parent: "parent"
}, ha = {
  $type: "PipelineComponent",
  evolution: "evolution",
  label: "label",
  name: "name"
}, yr = {
  $type: "Radar",
  accDescr: "accDescr",
  accTitle: "accTitle",
  axes: "axes",
  curves: "curves",
  options: "options",
  title: "title"
}, Gs = {
  $type: "Section",
  classSelector: "classSelector",
  name: "name"
}, jr = {
  $type: "Service",
  icon: "icon",
  iconText: "iconText",
  id: "id",
  in: "in",
  title: "title"
}, js = {
  $type: "Size",
  height: "height",
  width: "width"
}, zr = {
  $type: "Statement"
}, en = {
  $type: "Treemap",
  accDescr: "accDescr",
  accTitle: "accTitle",
  title: "title",
  TreemapRows: "TreemapRows"
};
function eR(t) {
  return nt.isInstance(t, en.$type);
}
_(eR, "isTreemap");
var zs = {
  $type: "TreemapRow",
  indent: "indent",
  item: "item"
}, Us = {
  $type: "TreeNode",
  indent: "indent",
  name: "name"
}, Zn = {
  $type: "TreeView",
  accDescr: "accDescr",
  accTitle: "accTitle",
  nodes: "nodes",
  title: "title"
}, Le = {
  $type: "Wardley",
  accDescr: "accDescr",
  accelerators: "accelerators",
  accTitle: "accTitle",
  anchors: "anchors",
  annotation: "annotation",
  annotations: "annotations",
  components: "components",
  deaccelerators: "deaccelerators",
  evolution: "evolution",
  evolves: "evolves",
  links: "links",
  notes: "notes",
  pipelines: "pipelines",
  size: "size",
  title: "title"
};
function tR(t) {
  return nt.isInstance(t, Le.$type);
}
_(tR, "isWardley");
var Od = class extends Qu {
  constructor() {
    super(...arguments), this.types = {
      Accelerator: {
        name: ia.$type,
        properties: {
          name: {
            name: ia.name
          },
          x: {
            name: ia.x
          },
          y: {
            name: ia.y
          }
        },
        superTypes: []
      },
      Anchor: {
        name: aa.$type,
        properties: {
          evolution: {
            name: aa.evolution
          },
          name: {
            name: aa.name
          },
          visibility: {
            name: aa.visibility
          }
        },
        superTypes: []
      },
      Annotation: {
        name: Hn.$type,
        properties: {
          number: {
            name: Hn.number
          },
          text: {
            name: Hn.text
          },
          x: {
            name: Hn.x
          },
          y: {
            name: Hn.y
          }
        },
        superTypes: []
      },
      Annotations: {
        name: Ps.$type,
        properties: {
          x: {
            name: Ps.x
          },
          y: {
            name: Ps.y
          }
        },
        superTypes: []
      },
      Architecture: {
        name: Lt.$type,
        properties: {
          accDescr: {
            name: Lt.accDescr
          },
          accTitle: {
            name: Lt.accTitle
          },
          edges: {
            name: Lt.edges,
            defaultValue: []
          },
          groups: {
            name: Lt.groups,
            defaultValue: []
          },
          junctions: {
            name: Lt.junctions,
            defaultValue: []
          },
          services: {
            name: Lt.services,
            defaultValue: []
          },
          title: {
            name: Lt.title
          }
        },
        superTypes: []
      },
      Axis: {
        name: sa.$type,
        properties: {
          label: {
            name: sa.label
          },
          name: {
            name: sa.name
          }
        },
        superTypes: []
      },
      Branch: {
        name: wa.$type,
        properties: {
          name: {
            name: wa.name
          },
          order: {
            name: wa.order
          }
        },
        superTypes: [zr.$type]
      },
      Checkout: {
        name: zu.$type,
        properties: {
          branch: {
            name: zu.branch
          }
        },
        superTypes: [zr.$type]
      },
      CherryPicking: {
        name: oa.$type,
        properties: {
          id: {
            name: oa.id
          },
          parent: {
            name: oa.parent
          },
          tags: {
            name: oa.tags,
            defaultValue: []
          }
        },
        superTypes: [zr.$type]
      },
      ClassDefStatement: {
        name: Os.$type,
        properties: {
          className: {
            name: Os.className
          },
          styleText: {
            name: Os.styleText
          }
        },
        superTypes: []
      },
      Commit: {
        name: Yr.$type,
        properties: {
          id: {
            name: Yr.id
          },
          message: {
            name: Yr.message
          },
          tags: {
            name: Yr.tags,
            defaultValue: []
          },
          type: {
            name: Yr.type
          }
        },
        superTypes: [zr.$type]
      },
      Component: {
        name: mr.$type,
        properties: {
          decorator: {
            name: mr.decorator
          },
          evolution: {
            name: mr.evolution
          },
          inertia: {
            name: mr.inertia,
            defaultValue: !1
          },
          label: {
            name: mr.label
          },
          name: {
            name: mr.name
          },
          visibility: {
            name: mr.visibility
          }
        },
        superTypes: []
      },
      Curve: {
        name: la.$type,
        properties: {
          entries: {
            name: la.entries,
            defaultValue: []
          },
          label: {
            name: la.label
          },
          name: {
            name: la.name
          }
        },
        superTypes: []
      },
      Deaccelerator: {
        name: ca.$type,
        properties: {
          name: {
            name: ca.name
          },
          x: {
            name: ca.x
          },
          y: {
            name: ca.y
          }
        },
        superTypes: []
      },
      Decorator: {
        name: Uu.$type,
        properties: {
          strategy: {
            name: Uu.strategy
          }
        },
        superTypes: []
      },
      Direction: {
        name: Gr.$type,
        properties: {
          accDescr: {
            name: Gr.accDescr
          },
          accTitle: {
            name: Gr.accTitle
          },
          dir: {
            name: Gr.dir
          },
          statements: {
            name: Gr.statements,
            defaultValue: []
          },
          title: {
            name: Gr.title
          }
        },
        superTypes: [Ar.$type]
      },
      Edge: {
        name: ht.$type,
        properties: {
          lhsDir: {
            name: ht.lhsDir
          },
          lhsGroup: {
            name: ht.lhsGroup,
            defaultValue: !1
          },
          lhsId: {
            name: ht.lhsId
          },
          lhsInto: {
            name: ht.lhsInto,
            defaultValue: !1
          },
          rhsDir: {
            name: ht.rhsDir
          },
          rhsGroup: {
            name: ht.rhsGroup,
            defaultValue: !1
          },
          rhsId: {
            name: ht.rhsId
          },
          rhsInto: {
            name: ht.rhsInto,
            defaultValue: !1
          },
          title: {
            name: ht.title
          }
        },
        superTypes: []
      },
      Entry: {
        name: Ls.$type,
        properties: {
          axis: {
            name: Ls.axis,
            referenceType: sa.$type
          },
          value: {
            name: Ls.value
          }
        },
        superTypes: []
      },
      Evolution: {
        name: qu.$type,
        properties: {
          stages: {
            name: qu.stages,
            defaultValue: []
          }
        },
        superTypes: []
      },
      EvolutionStage: {
        name: ua.$type,
        properties: {
          boundary: {
            name: ua.boundary
          },
          name: {
            name: ua.name
          },
          secondName: {
            name: ua.secondName
          }
        },
        superTypes: []
      },
      Evolve: {
        name: xs.$type,
        properties: {
          component: {
            name: xs.component
          },
          target: {
            name: xs.target
          }
        },
        superTypes: []
      },
      GitGraph: {
        name: Ar.$type,
        properties: {
          accDescr: {
            name: Ar.accDescr
          },
          accTitle: {
            name: Ar.accTitle
          },
          statements: {
            name: Ar.statements,
            defaultValue: []
          },
          title: {
            name: Ar.title
          }
        },
        superTypes: []
      },
      Group: {
        name: Xn.$type,
        properties: {
          icon: {
            name: Xn.icon
          },
          id: {
            name: Xn.id
          },
          in: {
            name: Xn.in
          },
          title: {
            name: Xn.title
          }
        },
        superTypes: []
      },
      Info: {
        name: oi.$type,
        properties: {
          accDescr: {
            name: oi.accDescr
          },
          accTitle: {
            name: oi.accTitle
          },
          title: {
            name: oi.title
          }
        },
        superTypes: []
      },
      Item: {
        name: Yn.$type,
        properties: {
          classSelector: {
            name: Yn.classSelector
          },
          name: {
            name: Yn.name
          }
        },
        superTypes: []
      },
      Junction: {
        name: Ds.$type,
        properties: {
          id: {
            name: Ds.id
          },
          in: {
            name: Ds.in
          }
        },
        superTypes: []
      },
      Label: {
        name: Jn.$type,
        properties: {
          negX: {
            name: Jn.negX,
            defaultValue: !1
          },
          negY: {
            name: Jn.negY,
            defaultValue: !1
          },
          offsetX: {
            name: Jn.offsetX
          },
          offsetY: {
            name: Jn.offsetY
          }
        },
        superTypes: []
      },
      Leaf: {
        name: fa.$type,
        properties: {
          classSelector: {
            name: fa.classSelector
          },
          name: {
            name: fa.name
          },
          value: {
            name: fa.value
          }
        },
        superTypes: [Yn.$type]
      },
      Link: {
        name: gr.$type,
        properties: {
          arrow: {
            name: gr.arrow
          },
          from: {
            name: gr.from
          },
          fromPort: {
            name: gr.fromPort
          },
          linkLabel: {
            name: gr.linkLabel
          },
          to: {
            name: gr.to
          },
          toPort: {
            name: gr.toPort
          }
        },
        superTypes: []
      },
      Merge: {
        name: Jr.$type,
        properties: {
          branch: {
            name: Jr.branch
          },
          id: {
            name: Jr.id
          },
          tags: {
            name: Jr.tags,
            defaultValue: []
          },
          type: {
            name: Jr.type
          }
        },
        superTypes: [zr.$type]
      },
      Note: {
        name: da.$type,
        properties: {
          evolution: {
            name: da.evolution
          },
          text: {
            name: da.text
          },
          visibility: {
            name: da.visibility
          }
        },
        superTypes: []
      },
      Option: {
        name: Ms.$type,
        properties: {
          name: {
            name: Ms.name
          },
          value: {
            name: Ms.value,
            defaultValue: !1
          }
        },
        superTypes: []
      },
      Packet: {
        name: Zr.$type,
        properties: {
          accDescr: {
            name: Zr.accDescr
          },
          accTitle: {
            name: Zr.accTitle
          },
          blocks: {
            name: Zr.blocks,
            defaultValue: []
          },
          title: {
            name: Zr.title
          }
        },
        superTypes: []
      },
      PacketBlock: {
        name: Qr.$type,
        properties: {
          bits: {
            name: Qr.bits
          },
          end: {
            name: Qr.end
          },
          label: {
            name: Qr.label
          },
          start: {
            name: Qr.start
          }
        },
        superTypes: []
      },
      Pie: {
        name: $r.$type,
        properties: {
          accDescr: {
            name: $r.accDescr
          },
          accTitle: {
            name: $r.accTitle
          },
          sections: {
            name: $r.sections,
            defaultValue: []
          },
          showData: {
            name: $r.showData,
            defaultValue: !1
          },
          title: {
            name: $r.title
          }
        },
        superTypes: []
      },
      PieSection: {
        name: ba.$type,
        properties: {
          label: {
            name: ba.label
          },
          value: {
            name: ba.value
          }
        },
        superTypes: []
      },
      Pipeline: {
        name: Fs.$type,
        properties: {
          components: {
            name: Fs.components,
            defaultValue: []
          },
          parent: {
            name: Fs.parent
          }
        },
        superTypes: []
      },
      PipelineComponent: {
        name: ha.$type,
        properties: {
          evolution: {
            name: ha.evolution
          },
          label: {
            name: ha.label
          },
          name: {
            name: ha.name
          }
        },
        superTypes: []
      },
      Radar: {
        name: yr.$type,
        properties: {
          accDescr: {
            name: yr.accDescr
          },
          accTitle: {
            name: yr.accTitle
          },
          axes: {
            name: yr.axes,
            defaultValue: []
          },
          curves: {
            name: yr.curves,
            defaultValue: []
          },
          options: {
            name: yr.options,
            defaultValue: []
          },
          title: {
            name: yr.title
          }
        },
        superTypes: []
      },
      Section: {
        name: Gs.$type,
        properties: {
          classSelector: {
            name: Gs.classSelector
          },
          name: {
            name: Gs.name
          }
        },
        superTypes: [Yn.$type]
      },
      Service: {
        name: jr.$type,
        properties: {
          icon: {
            name: jr.icon
          },
          iconText: {
            name: jr.iconText
          },
          id: {
            name: jr.id
          },
          in: {
            name: jr.in
          },
          title: {
            name: jr.title
          }
        },
        superTypes: []
      },
      Size: {
        name: js.$type,
        properties: {
          height: {
            name: js.height
          },
          width: {
            name: js.width
          }
        },
        superTypes: []
      },
      Statement: {
        name: zr.$type,
        properties: {},
        superTypes: []
      },
      TreeNode: {
        name: Us.$type,
        properties: {
          indent: {
            name: Us.indent
          },
          name: {
            name: Us.name
          }
        },
        superTypes: []
      },
      TreeView: {
        name: Zn.$type,
        properties: {
          accDescr: {
            name: Zn.accDescr
          },
          accTitle: {
            name: Zn.accTitle
          },
          nodes: {
            name: Zn.nodes,
            defaultValue: []
          },
          title: {
            name: Zn.title
          }
        },
        superTypes: []
      },
      Treemap: {
        name: en.$type,
        properties: {
          accDescr: {
            name: en.accDescr
          },
          accTitle: {
            name: en.accTitle
          },
          title: {
            name: en.title
          },
          TreemapRows: {
            name: en.TreemapRows,
            defaultValue: []
          }
        },
        superTypes: []
      },
      TreemapRow: {
        name: zs.$type,
        properties: {
          indent: {
            name: zs.indent
          },
          item: {
            name: zs.item
          }
        },
        superTypes: []
      },
      Wardley: {
        name: Le.$type,
        properties: {
          accDescr: {
            name: Le.accDescr
          },
          accelerators: {
            name: Le.accelerators,
            defaultValue: []
          },
          accTitle: {
            name: Le.accTitle
          },
          anchors: {
            name: Le.anchors,
            defaultValue: []
          },
          annotation: {
            name: Le.annotation,
            defaultValue: []
          },
          annotations: {
            name: Le.annotations,
            defaultValue: []
          },
          components: {
            name: Le.components,
            defaultValue: []
          },
          deaccelerators: {
            name: Le.deaccelerators,
            defaultValue: []
          },
          evolution: {
            name: Le.evolution
          },
          evolves: {
            name: Le.evolves,
            defaultValue: []
          },
          links: {
            name: Le.links,
            defaultValue: []
          },
          notes: {
            name: Le.notes,
            defaultValue: []
          },
          pipelines: {
            name: Le.pipelines,
            defaultValue: []
          },
          size: {
            name: Le.size
          },
          title: {
            name: Le.title
          }
        },
        superTypes: []
      }
    };
  }
  static {
    _(this, "MermaidAstReflection");
  }
}, nt = new Od(), Bu, rR = /* @__PURE__ */ _(() => Bu ?? (Bu = Wt(`{"$type":"Grammar","isDeclared":true,"name":"ArchitectureGrammar","imports":[],"rules":[{"$type":"ParserRule","entry":true,"name":"Architecture","definition":{"$type":"Group","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@23"},"arguments":[],"cardinality":"*"},{"$type":"Keyword","value":"architecture-beta"},{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@23"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@13"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@1"},"arguments":[]}],"cardinality":"*"}]},"fragment":false,"parameters":[]},{"$type":"ParserRule","fragment":true,"name":"Statement","definition":{"$type":"Alternatives","elements":[{"$type":"Assignment","feature":"groups","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@5"},"arguments":[]}},{"$type":"Assignment","feature":"services","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@6"},"arguments":[]}},{"$type":"Assignment","feature":"junctions","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@7"},"arguments":[]}},{"$type":"Assignment","feature":"edges","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@8"},"arguments":[]}}]},"entry":false,"parameters":[]},{"$type":"ParserRule","fragment":true,"name":"LeftPort","definition":{"$type":"Group","elements":[{"$type":"Keyword","value":":"},{"$type":"Assignment","feature":"lhsDir","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@9"},"arguments":[]}}]},"entry":false,"parameters":[]},{"$type":"ParserRule","fragment":true,"name":"RightPort","definition":{"$type":"Group","elements":[{"$type":"Assignment","feature":"rhsDir","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@9"},"arguments":[]}},{"$type":"Keyword","value":":"}]},"entry":false,"parameters":[]},{"$type":"ParserRule","fragment":true,"name":"Arrow","definition":{"$type":"Group","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@2"},"arguments":[]},{"$type":"Assignment","feature":"lhsInto","operator":"?=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@11"},"arguments":[]},"cardinality":"?"},{"$type":"Alternatives","elements":[{"$type":"Keyword","value":"--"},{"$type":"Group","elements":[{"$type":"Keyword","value":"-"},{"$type":"Assignment","feature":"title","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@29"},"arguments":[]}},{"$type":"Keyword","value":"-"}]}]},{"$type":"Assignment","feature":"rhsInto","operator":"?=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@11"},"arguments":[]},"cardinality":"?"},{"$type":"RuleCall","rule":{"$ref":"#/rules@3"},"arguments":[]}]},"entry":false,"parameters":[]},{"$type":"ParserRule","name":"Group","definition":{"$type":"Group","elements":[{"$type":"Keyword","value":"group"},{"$type":"Assignment","feature":"id","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@22"},"arguments":[]}},{"$type":"Assignment","feature":"icon","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@28"},"arguments":[]},"cardinality":"?"},{"$type":"Assignment","feature":"title","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@29"},"arguments":[]},"cardinality":"?"},{"$type":"Group","elements":[{"$type":"Keyword","value":"in"},{"$type":"Assignment","feature":"in","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@22"},"arguments":[]}}],"cardinality":"?"},{"$type":"RuleCall","rule":{"$ref":"#/rules@12"},"arguments":[]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"Service","definition":{"$type":"Group","elements":[{"$type":"Keyword","value":"service"},{"$type":"Assignment","feature":"id","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@22"},"arguments":[]}},{"$type":"Alternatives","elements":[{"$type":"Assignment","feature":"iconText","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@21"},"arguments":[]}},{"$type":"Assignment","feature":"icon","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@28"},"arguments":[]}}],"cardinality":"?"},{"$type":"Assignment","feature":"title","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@29"},"arguments":[]},"cardinality":"?"},{"$type":"Group","elements":[{"$type":"Keyword","value":"in"},{"$type":"Assignment","feature":"in","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@22"},"arguments":[]}}],"cardinality":"?"},{"$type":"RuleCall","rule":{"$ref":"#/rules@12"},"arguments":[]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"Junction","definition":{"$type":"Group","elements":[{"$type":"Keyword","value":"junction"},{"$type":"Assignment","feature":"id","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@22"},"arguments":[]}},{"$type":"Group","elements":[{"$type":"Keyword","value":"in"},{"$type":"Assignment","feature":"in","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@22"},"arguments":[]}}],"cardinality":"?"},{"$type":"RuleCall","rule":{"$ref":"#/rules@12"},"arguments":[]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"Edge","definition":{"$type":"Group","elements":[{"$type":"Assignment","feature":"lhsId","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@22"},"arguments":[]}},{"$type":"Assignment","feature":"lhsGroup","operator":"?=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@10"},"arguments":[]},"cardinality":"?"},{"$type":"RuleCall","rule":{"$ref":"#/rules@4"},"arguments":[]},{"$type":"Assignment","feature":"rhsId","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@22"},"arguments":[]}},{"$type":"Assignment","feature":"rhsGroup","operator":"?=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@10"},"arguments":[]},"cardinality":"?"},{"$type":"RuleCall","rule":{"$ref":"#/rules@12"},"arguments":[]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"TerminalRule","name":"ARROW_DIRECTION","definition":{"$type":"TerminalAlternatives","elements":[{"$type":"TerminalAlternatives","elements":[{"$type":"TerminalAlternatives","elements":[{"$type":"CharacterRange","left":{"$type":"Keyword","value":"L"},"parenthesized":false},{"$type":"CharacterRange","left":{"$type":"Keyword","value":"R"},"parenthesized":false}],"parenthesized":false},{"$type":"CharacterRange","left":{"$type":"Keyword","value":"T"},"parenthesized":false}],"parenthesized":false},{"$type":"CharacterRange","left":{"$type":"Keyword","value":"B"},"parenthesized":false}],"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ARROW_GROUP","definition":{"$type":"RegexToken","regex":"/\\\\{group\\\\}/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ARROW_INTO","definition":{"$type":"RegexToken","regex":"/<|>/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"ParserRule","name":"EOL","dataType":"string","definition":{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@23"},"arguments":[],"cardinality":"+"},{"$type":"EndOfFile"}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","fragment":true,"name":"TitleAndAccessibilities","definition":{"$type":"Group","elements":[{"$type":"Alternatives","elements":[{"$type":"Assignment","feature":"accDescr","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@15"},"arguments":[]}},{"$type":"Assignment","feature":"accTitle","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@16"},"arguments":[]}},{"$type":"Assignment","feature":"title","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@17"},"arguments":[]}}]},{"$type":"RuleCall","rule":{"$ref":"#/rules@12"},"arguments":[]}],"cardinality":"+"},"entry":false,"parameters":[]},{"$type":"TerminalRule","name":"BOOLEAN","type":{"$type":"ReturnType","name":"boolean"},"definition":{"$type":"TerminalAlternatives","elements":[{"$type":"CharacterRange","left":{"$type":"Keyword","value":"true"},"parenthesized":false},{"$type":"CharacterRange","left":{"$type":"Keyword","value":"false"},"parenthesized":false}],"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ACC_DESCR","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*accDescr(?:[\\\\t ]*:([^\\\\n\\\\r]*?(?=%%)|[^\\\\n\\\\r]*)|\\\\s*{([^}]*)})/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ACC_TITLE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*accTitle[\\\\t ]*:(?:[^\\\\n\\\\r]*?(?=%%)|[^\\\\n\\\\r]*)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"TITLE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*title(?:[\\\\t ][^\\\\n\\\\r]*?(?=%%)|[\\\\t ][^\\\\n\\\\r]*|)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"FLOAT","type":{"$type":"ReturnType","name":"number"},"definition":{"$type":"RegexToken","regex":"/[0-9]+\\\\.[0-9]+(?!\\\\.)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"INT","type":{"$type":"ReturnType","name":"number"},"definition":{"$type":"RegexToken","regex":"/0|[1-9][0-9]*(?!\\\\.)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"NUMBER","type":{"$type":"ReturnType","name":"number"},"definition":{"$type":"TerminalAlternatives","elements":[{"$type":"TerminalRuleCall","rule":{"$ref":"#/rules@18"},"parenthesized":false},{"$type":"TerminalRuleCall","rule":{"$ref":"#/rules@19"},"parenthesized":false}],"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"STRING","type":{"$type":"ReturnType","name":"string"},"definition":{"$type":"RegexToken","regex":"/\\"([^\\"\\\\\\\\]|\\\\\\\\.)*\\"|'([^'\\\\\\\\]|\\\\\\\\.)*'/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ID","type":{"$type":"ReturnType","name":"string"},"definition":{"$type":"RegexToken","regex":"/[\\\\w]([-\\\\w]*\\\\w)?/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"NEWLINE","definition":{"$type":"RegexToken","regex":"/\\\\r?\\\\n/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","hidden":true,"name":"WHITESPACE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]+/","parenthesized":false},"fragment":false},{"$type":"TerminalRule","hidden":true,"name":"YAML","definition":{"$type":"RegexToken","regex":"/---[\\\\t ]*\\\\r?\\\\n(?:[\\\\S\\\\s]*?\\\\r?\\\\n)?---(?:\\\\r?\\\\n|(?!\\\\S))/","parenthesized":false},"fragment":false},{"$type":"TerminalRule","hidden":true,"name":"DIRECTIVE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*%%{[\\\\S\\\\s]*?}%%(?:\\\\r?\\\\n|(?!\\\\S))/","parenthesized":false},"fragment":false},{"$type":"TerminalRule","hidden":true,"name":"SINGLE_LINE_COMMENT","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*%%[^\\\\n\\\\r]*/","parenthesized":false},"fragment":false},{"$type":"TerminalRule","name":"ARCH_ICON","definition":{"$type":"RegexToken","regex":"/\\\\([\\\\w-:]+\\\\)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ARCH_TITLE","definition":{"$type":"RegexToken","regex":"/\\\\[(?:\\"([^\\"\\\\\\\\]|\\\\\\\\.)*\\"|'([^'\\\\\\\\]|\\\\\\\\.)*'|[\\\\w ]+)\\\\]/","parenthesized":false},"fragment":false,"hidden":false}],"interfaces":[],"types":[]}`)), "ArchitectureGrammarGrammar"), Wu, nR = /* @__PURE__ */ _(() => Wu ?? (Wu = Wt(`{"$type":"Grammar","isDeclared":true,"name":"GitGraphGrammar","imports":[],"rules":[{"$type":"ParserRule","entry":true,"name":"GitGraph","definition":{"$type":"Group","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@19"},"arguments":[],"cardinality":"*"},{"$type":"Alternatives","elements":[{"$type":"Keyword","value":"gitGraph"},{"$type":"Group","elements":[{"$type":"Keyword","value":"gitGraph"},{"$type":"Keyword","value":":"}]},{"$type":"Keyword","value":"gitGraph:"},{"$type":"Group","elements":[{"$type":"Keyword","value":"gitGraph"},{"$type":"RuleCall","rule":{"$ref":"#/rules@2"},"arguments":[]},{"$type":"Keyword","value":":"}]}]},{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@19"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@9"},"arguments":[]},{"$type":"Assignment","feature":"statements","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@1"},"arguments":[]}}],"cardinality":"*"}]},"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"Statement","definition":{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@3"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@4"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@5"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@6"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@7"},"arguments":[]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"Direction","definition":{"$type":"Assignment","feature":"dir","operator":"=","terminal":{"$type":"Alternatives","elements":[{"$type":"Keyword","value":"LR"},{"$type":"Keyword","value":"TB"},{"$type":"Keyword","value":"BT"}]}},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"Commit","definition":{"$type":"Group","elements":[{"$type":"Keyword","value":"commit"},{"$type":"Alternatives","elements":[{"$type":"Group","elements":[{"$type":"Keyword","value":"id:"},{"$type":"Assignment","feature":"id","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@17"},"arguments":[]}}]},{"$type":"Group","elements":[{"$type":"Keyword","value":"msg:","cardinality":"?"},{"$type":"Assignment","feature":"message","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@17"},"arguments":[]}}]},{"$type":"Group","elements":[{"$type":"Keyword","value":"tag:"},{"$type":"Assignment","feature":"tags","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@17"},"arguments":[]}}]},{"$type":"Group","elements":[{"$type":"Keyword","value":"type:"},{"$type":"Assignment","feature":"type","operator":"=","terminal":{"$type":"Alternatives","elements":[{"$type":"Keyword","value":"NORMAL"},{"$type":"Keyword","value":"REVERSE"},{"$type":"Keyword","value":"HIGHLIGHT"}]}}]}],"cardinality":"*"},{"$type":"RuleCall","rule":{"$ref":"#/rules@8"},"arguments":[]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"Branch","definition":{"$type":"Group","elements":[{"$type":"Keyword","value":"branch"},{"$type":"Assignment","feature":"name","operator":"=","terminal":{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@24"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@17"},"arguments":[]}]}},{"$type":"Group","elements":[{"$type":"Keyword","value":"order:"},{"$type":"Assignment","feature":"order","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@15"},"arguments":[]}}],"cardinality":"?"},{"$type":"RuleCall","rule":{"$ref":"#/rules@8"},"arguments":[]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"Merge","definition":{"$type":"Group","elements":[{"$type":"Keyword","value":"merge"},{"$type":"Assignment","feature":"branch","operator":"=","terminal":{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@24"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@17"},"arguments":[]}]}},{"$type":"Alternatives","elements":[{"$type":"Group","elements":[{"$type":"Keyword","value":"id:"},{"$type":"Assignment","feature":"id","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@17"},"arguments":[]}}]},{"$type":"Group","elements":[{"$type":"Keyword","value":"tag:"},{"$type":"Assignment","feature":"tags","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@17"},"arguments":[]}}]},{"$type":"Group","elements":[{"$type":"Keyword","value":"type:"},{"$type":"Assignment","feature":"type","operator":"=","terminal":{"$type":"Alternatives","elements":[{"$type":"Keyword","value":"NORMAL"},{"$type":"Keyword","value":"REVERSE"},{"$type":"Keyword","value":"HIGHLIGHT"}]}}]}],"cardinality":"*"},{"$type":"RuleCall","rule":{"$ref":"#/rules@8"},"arguments":[]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"Checkout","definition":{"$type":"Group","elements":[{"$type":"Alternatives","elements":[{"$type":"Keyword","value":"checkout"},{"$type":"Keyword","value":"switch"}]},{"$type":"Assignment","feature":"branch","operator":"=","terminal":{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@24"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@17"},"arguments":[]}]}},{"$type":"RuleCall","rule":{"$ref":"#/rules@8"},"arguments":[]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"CherryPicking","definition":{"$type":"Group","elements":[{"$type":"Keyword","value":"cherry-pick"},{"$type":"Alternatives","elements":[{"$type":"Group","elements":[{"$type":"Keyword","value":"id:"},{"$type":"Assignment","feature":"id","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@17"},"arguments":[]}}]},{"$type":"Group","elements":[{"$type":"Keyword","value":"tag:"},{"$type":"Assignment","feature":"tags","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@17"},"arguments":[]}}]},{"$type":"Group","elements":[{"$type":"Keyword","value":"parent:"},{"$type":"Assignment","feature":"parent","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@17"},"arguments":[]}}]}],"cardinality":"*"},{"$type":"RuleCall","rule":{"$ref":"#/rules@8"},"arguments":[]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"EOL","dataType":"string","definition":{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@19"},"arguments":[],"cardinality":"+"},{"$type":"EndOfFile"}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","fragment":true,"name":"TitleAndAccessibilities","definition":{"$type":"Group","elements":[{"$type":"Alternatives","elements":[{"$type":"Assignment","feature":"accDescr","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@11"},"arguments":[]}},{"$type":"Assignment","feature":"accTitle","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@12"},"arguments":[]}},{"$type":"Assignment","feature":"title","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@13"},"arguments":[]}}]},{"$type":"RuleCall","rule":{"$ref":"#/rules@8"},"arguments":[]}],"cardinality":"+"},"entry":false,"parameters":[]},{"$type":"TerminalRule","name":"BOOLEAN","type":{"$type":"ReturnType","name":"boolean"},"definition":{"$type":"TerminalAlternatives","elements":[{"$type":"CharacterRange","left":{"$type":"Keyword","value":"true"},"parenthesized":false},{"$type":"CharacterRange","left":{"$type":"Keyword","value":"false"},"parenthesized":false}],"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ACC_DESCR","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*accDescr(?:[\\\\t ]*:([^\\\\n\\\\r]*?(?=%%)|[^\\\\n\\\\r]*)|\\\\s*{([^}]*)})/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ACC_TITLE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*accTitle[\\\\t ]*:(?:[^\\\\n\\\\r]*?(?=%%)|[^\\\\n\\\\r]*)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"TITLE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*title(?:[\\\\t ][^\\\\n\\\\r]*?(?=%%)|[\\\\t ][^\\\\n\\\\r]*|)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"FLOAT","type":{"$type":"ReturnType","name":"number"},"definition":{"$type":"RegexToken","regex":"/[0-9]+\\\\.[0-9]+(?!\\\\.)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"INT","type":{"$type":"ReturnType","name":"number"},"definition":{"$type":"RegexToken","regex":"/0|[1-9][0-9]*(?!\\\\.)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"NUMBER","type":{"$type":"ReturnType","name":"number"},"definition":{"$type":"TerminalAlternatives","elements":[{"$type":"TerminalRuleCall","rule":{"$ref":"#/rules@14"},"parenthesized":false},{"$type":"TerminalRuleCall","rule":{"$ref":"#/rules@15"},"parenthesized":false}],"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"STRING","type":{"$type":"ReturnType","name":"string"},"definition":{"$type":"RegexToken","regex":"/\\"([^\\"\\\\\\\\]|\\\\\\\\.)*\\"|'([^'\\\\\\\\]|\\\\\\\\.)*'/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ID","type":{"$type":"ReturnType","name":"string"},"definition":{"$type":"RegexToken","regex":"/[\\\\w]([-\\\\w]*\\\\w)?/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"NEWLINE","definition":{"$type":"RegexToken","regex":"/\\\\r?\\\\n/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","hidden":true,"name":"WHITESPACE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]+/","parenthesized":false},"fragment":false},{"$type":"TerminalRule","hidden":true,"name":"YAML","definition":{"$type":"RegexToken","regex":"/---[\\\\t ]*\\\\r?\\\\n(?:[\\\\S\\\\s]*?\\\\r?\\\\n)?---(?:\\\\r?\\\\n|(?!\\\\S))/","parenthesized":false},"fragment":false},{"$type":"TerminalRule","hidden":true,"name":"DIRECTIVE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*%%{[\\\\S\\\\s]*?}%%(?:\\\\r?\\\\n|(?!\\\\S))/","parenthesized":false},"fragment":false},{"$type":"TerminalRule","hidden":true,"name":"SINGLE_LINE_COMMENT","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*%%[^\\\\n\\\\r]*/","parenthesized":false},"fragment":false},{"$type":"TerminalRule","name":"REFERENCE","type":{"$type":"ReturnType","name":"string"},"definition":{"$type":"RegexToken","regex":"/\\\\w([-\\\\./\\\\w]*[-\\\\w])?/","parenthesized":false},"fragment":false,"hidden":false}],"interfaces":[],"types":[]}`)), "GitGraphGrammarGrammar"), Ku, iR = /* @__PURE__ */ _(() => Ku ?? (Ku = Wt(`{"$type":"Grammar","isDeclared":true,"name":"InfoGrammar","imports":[],"rules":[{"$type":"ParserRule","entry":true,"name":"Info","definition":{"$type":"Group","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@12"},"arguments":[],"cardinality":"*"},{"$type":"Keyword","value":"info"},{"$type":"RuleCall","rule":{"$ref":"#/rules@12"},"arguments":[],"cardinality":"*"},{"$type":"Group","elements":[{"$type":"Keyword","value":"showInfo"},{"$type":"RuleCall","rule":{"$ref":"#/rules@12"},"arguments":[],"cardinality":"*"}],"cardinality":"?"},{"$type":"RuleCall","rule":{"$ref":"#/rules@2"},"arguments":[],"cardinality":"?"}]},"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"EOL","dataType":"string","definition":{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@12"},"arguments":[],"cardinality":"+"},{"$type":"EndOfFile"}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","fragment":true,"name":"TitleAndAccessibilities","definition":{"$type":"Group","elements":[{"$type":"Alternatives","elements":[{"$type":"Assignment","feature":"accDescr","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@4"},"arguments":[]}},{"$type":"Assignment","feature":"accTitle","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@5"},"arguments":[]}},{"$type":"Assignment","feature":"title","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@6"},"arguments":[]}}]},{"$type":"RuleCall","rule":{"$ref":"#/rules@1"},"arguments":[]}],"cardinality":"+"},"entry":false,"parameters":[]},{"$type":"TerminalRule","name":"BOOLEAN","type":{"$type":"ReturnType","name":"boolean"},"definition":{"$type":"TerminalAlternatives","elements":[{"$type":"CharacterRange","left":{"$type":"Keyword","value":"true"},"parenthesized":false},{"$type":"CharacterRange","left":{"$type":"Keyword","value":"false"},"parenthesized":false}],"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ACC_DESCR","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*accDescr(?:[\\\\t ]*:([^\\\\n\\\\r]*?(?=%%)|[^\\\\n\\\\r]*)|\\\\s*{([^}]*)})/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ACC_TITLE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*accTitle[\\\\t ]*:(?:[^\\\\n\\\\r]*?(?=%%)|[^\\\\n\\\\r]*)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"TITLE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*title(?:[\\\\t ][^\\\\n\\\\r]*?(?=%%)|[\\\\t ][^\\\\n\\\\r]*|)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"FLOAT","type":{"$type":"ReturnType","name":"number"},"definition":{"$type":"RegexToken","regex":"/[0-9]+\\\\.[0-9]+(?!\\\\.)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"INT","type":{"$type":"ReturnType","name":"number"},"definition":{"$type":"RegexToken","regex":"/0|[1-9][0-9]*(?!\\\\.)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"NUMBER","type":{"$type":"ReturnType","name":"number"},"definition":{"$type":"TerminalAlternatives","elements":[{"$type":"TerminalRuleCall","rule":{"$ref":"#/rules@7"},"parenthesized":false},{"$type":"TerminalRuleCall","rule":{"$ref":"#/rules@8"},"parenthesized":false}],"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"STRING","type":{"$type":"ReturnType","name":"string"},"definition":{"$type":"RegexToken","regex":"/\\"([^\\"\\\\\\\\]|\\\\\\\\.)*\\"|'([^'\\\\\\\\]|\\\\\\\\.)*'/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ID","type":{"$type":"ReturnType","name":"string"},"definition":{"$type":"RegexToken","regex":"/[\\\\w]([-\\\\w]*\\\\w)?/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"NEWLINE","definition":{"$type":"RegexToken","regex":"/\\\\r?\\\\n/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","hidden":true,"name":"WHITESPACE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]+/","parenthesized":false},"fragment":false},{"$type":"TerminalRule","hidden":true,"name":"YAML","definition":{"$type":"RegexToken","regex":"/---[\\\\t ]*\\\\r?\\\\n(?:[\\\\S\\\\s]*?\\\\r?\\\\n)?---(?:\\\\r?\\\\n|(?!\\\\S))/","parenthesized":false},"fragment":false},{"$type":"TerminalRule","hidden":true,"name":"DIRECTIVE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*%%{[\\\\S\\\\s]*?}%%(?:\\\\r?\\\\n|(?!\\\\S))/","parenthesized":false},"fragment":false},{"$type":"TerminalRule","hidden":true,"name":"SINGLE_LINE_COMMENT","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*%%[^\\\\n\\\\r]*/","parenthesized":false},"fragment":false}],"interfaces":[],"types":[]}`)), "InfoGrammarGrammar"), Vu, aR = /* @__PURE__ */ _(() => Vu ?? (Vu = Wt(`{"$type":"Grammar","isDeclared":true,"name":"PacketGrammar","imports":[],"rules":[{"$type":"ParserRule","entry":true,"name":"Packet","definition":{"$type":"Group","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@13"},"arguments":[],"cardinality":"*"},{"$type":"Alternatives","elements":[{"$type":"Keyword","value":"packet"},{"$type":"Keyword","value":"packet-beta"}]},{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@3"},"arguments":[]},{"$type":"Assignment","feature":"blocks","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@1"},"arguments":[]}},{"$type":"RuleCall","rule":{"$ref":"#/rules@13"},"arguments":[]}],"cardinality":"*"}]},"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"PacketBlock","definition":{"$type":"Group","elements":[{"$type":"Alternatives","elements":[{"$type":"Group","elements":[{"$type":"Assignment","feature":"start","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@9"},"arguments":[]}},{"$type":"Group","elements":[{"$type":"Keyword","value":"-"},{"$type":"Assignment","feature":"end","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@9"},"arguments":[]}}],"cardinality":"?"}]},{"$type":"Group","elements":[{"$type":"Keyword","value":"+"},{"$type":"Assignment","feature":"bits","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@9"},"arguments":[]}}]}]},{"$type":"Keyword","value":":"},{"$type":"Assignment","feature":"label","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@11"},"arguments":[]}},{"$type":"RuleCall","rule":{"$ref":"#/rules@2"},"arguments":[]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"EOL","dataType":"string","definition":{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@13"},"arguments":[],"cardinality":"+"},{"$type":"EndOfFile"}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","fragment":true,"name":"TitleAndAccessibilities","definition":{"$type":"Group","elements":[{"$type":"Alternatives","elements":[{"$type":"Assignment","feature":"accDescr","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@5"},"arguments":[]}},{"$type":"Assignment","feature":"accTitle","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@6"},"arguments":[]}},{"$type":"Assignment","feature":"title","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@7"},"arguments":[]}}]},{"$type":"RuleCall","rule":{"$ref":"#/rules@2"},"arguments":[]}],"cardinality":"+"},"entry":false,"parameters":[]},{"$type":"TerminalRule","name":"BOOLEAN","type":{"$type":"ReturnType","name":"boolean"},"definition":{"$type":"TerminalAlternatives","elements":[{"$type":"CharacterRange","left":{"$type":"Keyword","value":"true"},"parenthesized":false},{"$type":"CharacterRange","left":{"$type":"Keyword","value":"false"},"parenthesized":false}],"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ACC_DESCR","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*accDescr(?:[\\\\t ]*:([^\\\\n\\\\r]*?(?=%%)|[^\\\\n\\\\r]*)|\\\\s*{([^}]*)})/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ACC_TITLE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*accTitle[\\\\t ]*:(?:[^\\\\n\\\\r]*?(?=%%)|[^\\\\n\\\\r]*)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"TITLE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*title(?:[\\\\t ][^\\\\n\\\\r]*?(?=%%)|[\\\\t ][^\\\\n\\\\r]*|)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"FLOAT","type":{"$type":"ReturnType","name":"number"},"definition":{"$type":"RegexToken","regex":"/[0-9]+\\\\.[0-9]+(?!\\\\.)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"INT","type":{"$type":"ReturnType","name":"number"},"definition":{"$type":"RegexToken","regex":"/0|[1-9][0-9]*(?!\\\\.)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"NUMBER","type":{"$type":"ReturnType","name":"number"},"definition":{"$type":"TerminalAlternatives","elements":[{"$type":"TerminalRuleCall","rule":{"$ref":"#/rules@8"},"parenthesized":false},{"$type":"TerminalRuleCall","rule":{"$ref":"#/rules@9"},"parenthesized":false}],"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"STRING","type":{"$type":"ReturnType","name":"string"},"definition":{"$type":"RegexToken","regex":"/\\"([^\\"\\\\\\\\]|\\\\\\\\.)*\\"|'([^'\\\\\\\\]|\\\\\\\\.)*'/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ID","type":{"$type":"ReturnType","name":"string"},"definition":{"$type":"RegexToken","regex":"/[\\\\w]([-\\\\w]*\\\\w)?/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"NEWLINE","definition":{"$type":"RegexToken","regex":"/\\\\r?\\\\n/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","hidden":true,"name":"WHITESPACE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]+/","parenthesized":false},"fragment":false},{"$type":"TerminalRule","hidden":true,"name":"YAML","definition":{"$type":"RegexToken","regex":"/---[\\\\t ]*\\\\r?\\\\n(?:[\\\\S\\\\s]*?\\\\r?\\\\n)?---(?:\\\\r?\\\\n|(?!\\\\S))/","parenthesized":false},"fragment":false},{"$type":"TerminalRule","hidden":true,"name":"DIRECTIVE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*%%{[\\\\S\\\\s]*?}%%(?:\\\\r?\\\\n|(?!\\\\S))/","parenthesized":false},"fragment":false},{"$type":"TerminalRule","hidden":true,"name":"SINGLE_LINE_COMMENT","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*%%[^\\\\n\\\\r]*/","parenthesized":false},"fragment":false}],"interfaces":[],"types":[]}`)), "PacketGrammarGrammar"), Hu, sR = /* @__PURE__ */ _(() => Hu ?? (Hu = Wt(`{"$type":"Grammar","isDeclared":true,"name":"PieGrammar","imports":[],"rules":[{"$type":"ParserRule","entry":true,"name":"Pie","definition":{"$type":"Group","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@16"},"arguments":[],"cardinality":"*"},{"$type":"Keyword","value":"pie"},{"$type":"Assignment","feature":"showData","operator":"?=","terminal":{"$type":"Keyword","value":"showData"},"cardinality":"?"},{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@6"},"arguments":[]},{"$type":"Assignment","feature":"sections","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@1"},"arguments":[]}},{"$type":"RuleCall","rule":{"$ref":"#/rules@16"},"arguments":[]}],"cardinality":"*"}]},"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"PieSection","definition":{"$type":"Group","elements":[{"$type":"Assignment","feature":"label","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@14"},"arguments":[]}},{"$type":"Keyword","value":":"},{"$type":"Assignment","feature":"value","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@4"},"arguments":[]}},{"$type":"RuleCall","rule":{"$ref":"#/rules@5"},"arguments":[]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"TerminalRule","name":"FLOAT_PIE","type":{"$type":"ReturnType","name":"number"},"definition":{"$type":"RegexToken","regex":"/-?[0-9]+\\\\.[0-9]+(?!\\\\.)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"INT_PIE","type":{"$type":"ReturnType","name":"number"},"definition":{"$type":"RegexToken","regex":"/-?(0|[1-9][0-9]*)(?!\\\\.)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"NUMBER_PIE","type":{"$type":"ReturnType","name":"number"},"definition":{"$type":"TerminalAlternatives","elements":[{"$type":"TerminalRuleCall","rule":{"$ref":"#/rules@2"},"parenthesized":false},{"$type":"TerminalRuleCall","rule":{"$ref":"#/rules@3"},"parenthesized":false}],"parenthesized":false},"fragment":false,"hidden":false},{"$type":"ParserRule","name":"EOL","dataType":"string","definition":{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@16"},"arguments":[],"cardinality":"+"},{"$type":"EndOfFile"}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","fragment":true,"name":"TitleAndAccessibilities","definition":{"$type":"Group","elements":[{"$type":"Alternatives","elements":[{"$type":"Assignment","feature":"accDescr","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@8"},"arguments":[]}},{"$type":"Assignment","feature":"accTitle","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@9"},"arguments":[]}},{"$type":"Assignment","feature":"title","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@10"},"arguments":[]}}]},{"$type":"RuleCall","rule":{"$ref":"#/rules@5"},"arguments":[]}],"cardinality":"+"},"entry":false,"parameters":[]},{"$type":"TerminalRule","name":"BOOLEAN","type":{"$type":"ReturnType","name":"boolean"},"definition":{"$type":"TerminalAlternatives","elements":[{"$type":"CharacterRange","left":{"$type":"Keyword","value":"true"},"parenthesized":false},{"$type":"CharacterRange","left":{"$type":"Keyword","value":"false"},"parenthesized":false}],"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ACC_DESCR","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*accDescr(?:[\\\\t ]*:([^\\\\n\\\\r]*?(?=%%)|[^\\\\n\\\\r]*)|\\\\s*{([^}]*)})/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ACC_TITLE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*accTitle[\\\\t ]*:(?:[^\\\\n\\\\r]*?(?=%%)|[^\\\\n\\\\r]*)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"TITLE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*title(?:[\\\\t ][^\\\\n\\\\r]*?(?=%%)|[\\\\t ][^\\\\n\\\\r]*|)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"FLOAT","type":{"$type":"ReturnType","name":"number"},"definition":{"$type":"RegexToken","regex":"/[0-9]+\\\\.[0-9]+(?!\\\\.)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"INT","type":{"$type":"ReturnType","name":"number"},"definition":{"$type":"RegexToken","regex":"/0|[1-9][0-9]*(?!\\\\.)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"NUMBER","type":{"$type":"ReturnType","name":"number"},"definition":{"$type":"TerminalAlternatives","elements":[{"$type":"TerminalRuleCall","rule":{"$ref":"#/rules@11"},"parenthesized":false},{"$type":"TerminalRuleCall","rule":{"$ref":"#/rules@12"},"parenthesized":false}],"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"STRING","type":{"$type":"ReturnType","name":"string"},"definition":{"$type":"RegexToken","regex":"/\\"([^\\"\\\\\\\\]|\\\\\\\\.)*\\"|'([^'\\\\\\\\]|\\\\\\\\.)*'/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ID","type":{"$type":"ReturnType","name":"string"},"definition":{"$type":"RegexToken","regex":"/[\\\\w]([-\\\\w]*\\\\w)?/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"NEWLINE","definition":{"$type":"RegexToken","regex":"/\\\\r?\\\\n/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","hidden":true,"name":"WHITESPACE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]+/","parenthesized":false},"fragment":false},{"$type":"TerminalRule","hidden":true,"name":"YAML","definition":{"$type":"RegexToken","regex":"/---[\\\\t ]*\\\\r?\\\\n(?:[\\\\S\\\\s]*?\\\\r?\\\\n)?---(?:\\\\r?\\\\n|(?!\\\\S))/","parenthesized":false},"fragment":false},{"$type":"TerminalRule","hidden":true,"name":"DIRECTIVE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*%%{[\\\\S\\\\s]*?}%%(?:\\\\r?\\\\n|(?!\\\\S))/","parenthesized":false},"fragment":false},{"$type":"TerminalRule","hidden":true,"name":"SINGLE_LINE_COMMENT","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*%%[^\\\\n\\\\r]*/","parenthesized":false},"fragment":false}],"interfaces":[],"types":[]}`)), "PieGrammarGrammar"), Xu, oR = /* @__PURE__ */ _(() => Xu ?? (Xu = Wt(`{"$type":"Grammar","isDeclared":true,"name":"RadarGrammar","imports":[],"rules":[{"$type":"ParserRule","entry":true,"name":"Radar","definition":{"$type":"Group","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@20"},"arguments":[],"cardinality":"*"},{"$type":"Alternatives","elements":[{"$type":"Keyword","value":"radar-beta"},{"$type":"Keyword","value":"radar-beta:"},{"$type":"Group","elements":[{"$type":"Keyword","value":"radar-beta"},{"$type":"Keyword","value":":"}]}]},{"$type":"RuleCall","rule":{"$ref":"#/rules@20"},"arguments":[],"cardinality":"*"},{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@10"},"arguments":[]},{"$type":"Group","elements":[{"$type":"Keyword","value":"axis"},{"$type":"Assignment","feature":"axes","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@2"},"arguments":[]}},{"$type":"Group","elements":[{"$type":"Keyword","value":","},{"$type":"Assignment","feature":"axes","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@2"},"arguments":[]}}],"cardinality":"*"}]},{"$type":"Group","elements":[{"$type":"Keyword","value":"curve"},{"$type":"Assignment","feature":"curves","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@3"},"arguments":[]}},{"$type":"Group","elements":[{"$type":"Keyword","value":","},{"$type":"Assignment","feature":"curves","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@3"},"arguments":[]}}],"cardinality":"*"}]},{"$type":"Group","elements":[{"$type":"Assignment","feature":"options","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@7"},"arguments":[]}},{"$type":"Group","elements":[{"$type":"Keyword","value":","},{"$type":"Assignment","feature":"options","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@7"},"arguments":[]}}],"cardinality":"*"}]},{"$type":"RuleCall","rule":{"$ref":"#/rules@20"},"arguments":[]}],"cardinality":"*"}]},"fragment":false,"parameters":[]},{"$type":"ParserRule","fragment":true,"name":"Label","definition":{"$type":"Group","elements":[{"$type":"Keyword","value":"["},{"$type":"Assignment","feature":"label","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@18"},"arguments":[]}},{"$type":"Keyword","value":"]"}]},"entry":false,"parameters":[]},{"$type":"ParserRule","name":"Axis","definition":{"$type":"Group","elements":[{"$type":"Assignment","feature":"name","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@19"},"arguments":[]}},{"$type":"RuleCall","rule":{"$ref":"#/rules@1"},"arguments":[],"cardinality":"?"}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"Curve","definition":{"$type":"Group","elements":[{"$type":"Assignment","feature":"name","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@19"},"arguments":[]}},{"$type":"RuleCall","rule":{"$ref":"#/rules@1"},"arguments":[],"cardinality":"?"},{"$type":"Keyword","value":"{"},{"$type":"RuleCall","rule":{"$ref":"#/rules@4"},"arguments":[]},{"$type":"Keyword","value":"}"}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","fragment":true,"name":"Entries","definition":{"$type":"Alternatives","elements":[{"$type":"Group","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@20"},"arguments":[],"cardinality":"*"},{"$type":"Assignment","feature":"entries","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@6"},"arguments":[]}},{"$type":"Group","elements":[{"$type":"Keyword","value":","},{"$type":"RuleCall","rule":{"$ref":"#/rules@20"},"arguments":[],"cardinality":"*"},{"$type":"Assignment","feature":"entries","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@6"},"arguments":[]}}],"cardinality":"*"},{"$type":"RuleCall","rule":{"$ref":"#/rules@20"},"arguments":[],"cardinality":"*"}]},{"$type":"Group","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@20"},"arguments":[],"cardinality":"*"},{"$type":"Assignment","feature":"entries","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@5"},"arguments":[]}},{"$type":"Group","elements":[{"$type":"Keyword","value":","},{"$type":"RuleCall","rule":{"$ref":"#/rules@20"},"arguments":[],"cardinality":"*"},{"$type":"Assignment","feature":"entries","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@5"},"arguments":[]}}],"cardinality":"*"},{"$type":"RuleCall","rule":{"$ref":"#/rules@20"},"arguments":[],"cardinality":"*"}]}]},"entry":false,"parameters":[]},{"$type":"ParserRule","name":"DetailedEntry","returnType":{"$ref":"#/interfaces@0"},"definition":{"$type":"Group","elements":[{"$type":"Assignment","feature":"axis","operator":"=","terminal":{"$type":"CrossReference","type":{"$ref":"#/rules@2"},"terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@19"},"arguments":[]},"deprecatedSyntax":false,"isMulti":false}},{"$type":"Keyword","value":":","cardinality":"?"},{"$type":"Assignment","feature":"value","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@17"},"arguments":[]}}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"NumberEntry","returnType":{"$ref":"#/interfaces@0"},"definition":{"$type":"Assignment","feature":"value","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@17"},"arguments":[]}},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"Option","definition":{"$type":"Alternatives","elements":[{"$type":"Group","elements":[{"$type":"Assignment","feature":"name","operator":"=","terminal":{"$type":"Keyword","value":"showLegend"}},{"$type":"Assignment","feature":"value","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@11"},"arguments":[]}}]},{"$type":"Group","elements":[{"$type":"Assignment","feature":"name","operator":"=","terminal":{"$type":"Keyword","value":"ticks"}},{"$type":"Assignment","feature":"value","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@17"},"arguments":[]}}]},{"$type":"Group","elements":[{"$type":"Assignment","feature":"name","operator":"=","terminal":{"$type":"Keyword","value":"max"}},{"$type":"Assignment","feature":"value","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@17"},"arguments":[]}}]},{"$type":"Group","elements":[{"$type":"Assignment","feature":"name","operator":"=","terminal":{"$type":"Keyword","value":"min"}},{"$type":"Assignment","feature":"value","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@17"},"arguments":[]}}]},{"$type":"Group","elements":[{"$type":"Assignment","feature":"name","operator":"=","terminal":{"$type":"Keyword","value":"graticule"}},{"$type":"Assignment","feature":"value","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@8"},"arguments":[]}}]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"TerminalRule","name":"GRATICULE","type":{"$type":"ReturnType","name":"string"},"definition":{"$type":"TerminalAlternatives","elements":[{"$type":"CharacterRange","left":{"$type":"Keyword","value":"circle"},"parenthesized":false},{"$type":"CharacterRange","left":{"$type":"Keyword","value":"polygon"},"parenthesized":false}],"parenthesized":false},"fragment":false,"hidden":false},{"$type":"ParserRule","name":"EOL","dataType":"string","definition":{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@20"},"arguments":[],"cardinality":"+"},{"$type":"EndOfFile"}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","fragment":true,"name":"TitleAndAccessibilities","definition":{"$type":"Group","elements":[{"$type":"Alternatives","elements":[{"$type":"Assignment","feature":"accDescr","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@12"},"arguments":[]}},{"$type":"Assignment","feature":"accTitle","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@13"},"arguments":[]}},{"$type":"Assignment","feature":"title","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@14"},"arguments":[]}}]},{"$type":"RuleCall","rule":{"$ref":"#/rules@9"},"arguments":[]}],"cardinality":"+"},"entry":false,"parameters":[]},{"$type":"TerminalRule","name":"BOOLEAN","type":{"$type":"ReturnType","name":"boolean"},"definition":{"$type":"TerminalAlternatives","elements":[{"$type":"CharacterRange","left":{"$type":"Keyword","value":"true"},"parenthesized":false},{"$type":"CharacterRange","left":{"$type":"Keyword","value":"false"},"parenthesized":false}],"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ACC_DESCR","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*accDescr(?:[\\\\t ]*:([^\\\\n\\\\r]*?(?=%%)|[^\\\\n\\\\r]*)|\\\\s*{([^}]*)})/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ACC_TITLE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*accTitle[\\\\t ]*:(?:[^\\\\n\\\\r]*?(?=%%)|[^\\\\n\\\\r]*)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"TITLE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*title(?:[\\\\t ][^\\\\n\\\\r]*?(?=%%)|[\\\\t ][^\\\\n\\\\r]*|)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"FLOAT","type":{"$type":"ReturnType","name":"number"},"definition":{"$type":"RegexToken","regex":"/[0-9]+\\\\.[0-9]+(?!\\\\.)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"INT","type":{"$type":"ReturnType","name":"number"},"definition":{"$type":"RegexToken","regex":"/0|[1-9][0-9]*(?!\\\\.)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"NUMBER","type":{"$type":"ReturnType","name":"number"},"definition":{"$type":"TerminalAlternatives","elements":[{"$type":"TerminalRuleCall","rule":{"$ref":"#/rules@15"},"parenthesized":false},{"$type":"TerminalRuleCall","rule":{"$ref":"#/rules@16"},"parenthesized":false}],"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"STRING","type":{"$type":"ReturnType","name":"string"},"definition":{"$type":"RegexToken","regex":"/\\"([^\\"\\\\\\\\]|\\\\\\\\.)*\\"|'([^'\\\\\\\\]|\\\\\\\\.)*'/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ID","type":{"$type":"ReturnType","name":"string"},"definition":{"$type":"RegexToken","regex":"/[\\\\w]([-\\\\w]*\\\\w)?/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"NEWLINE","definition":{"$type":"RegexToken","regex":"/\\\\r?\\\\n/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","hidden":true,"name":"WHITESPACE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]+/","parenthesized":false},"fragment":false},{"$type":"TerminalRule","hidden":true,"name":"YAML","definition":{"$type":"RegexToken","regex":"/---[\\\\t ]*\\\\r?\\\\n(?:[\\\\S\\\\s]*?\\\\r?\\\\n)?---(?:\\\\r?\\\\n|(?!\\\\S))/","parenthesized":false},"fragment":false},{"$type":"TerminalRule","hidden":true,"name":"DIRECTIVE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*%%{[\\\\S\\\\s]*?}%%(?:\\\\r?\\\\n|(?!\\\\S))/","parenthesized":false},"fragment":false},{"$type":"TerminalRule","hidden":true,"name":"SINGLE_LINE_COMMENT","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*%%[^\\\\n\\\\r]*/","parenthesized":false},"fragment":false}],"interfaces":[{"$type":"Interface","name":"Entry","attributes":[{"$type":"TypeAttribute","name":"axis","isOptional":true,"type":{"$type":"ReferenceType","referenceType":{"$type":"SimpleType","typeRef":{"$ref":"#/rules@2"}},"isMulti":false}},{"$type":"TypeAttribute","name":"value","type":{"$type":"SimpleType","primitiveType":"number"},"isOptional":false}],"superTypes":[]}],"types":[]}`)), "RadarGrammarGrammar"), Yu, lR = /* @__PURE__ */ _(() => Yu ?? (Yu = Wt(`{"$type":"Grammar","isDeclared":true,"name":"TreemapGrammar","rules":[{"$type":"ParserRule","fragment":true,"name":"TitleAndAccessibilities","definition":{"$type":"Alternatives","elements":[{"$type":"Assignment","feature":"accDescr","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@2"},"arguments":[]}},{"$type":"Assignment","feature":"accTitle","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@3"},"arguments":[]}},{"$type":"Assignment","feature":"title","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@4"},"arguments":[]}}],"cardinality":"+"},"entry":false,"parameters":[]},{"$type":"TerminalRule","name":"BOOLEAN","type":{"$type":"ReturnType","name":"boolean"},"definition":{"$type":"TerminalAlternatives","elements":[{"$type":"CharacterRange","left":{"$type":"Keyword","value":"true"},"parenthesized":false},{"$type":"CharacterRange","left":{"$type":"Keyword","value":"false"},"parenthesized":false}],"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ACC_DESCR","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*accDescr(?:[\\\\t ]*:([^\\\\n\\\\r]*?(?=%%)|[^\\\\n\\\\r]*)|\\\\s*{([^}]*)})/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ACC_TITLE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*accTitle[\\\\t ]*:(?:[^\\\\n\\\\r]*?(?=%%)|[^\\\\n\\\\r]*)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"TITLE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*title(?:[\\\\t ][^\\\\n\\\\r]*?(?=%%)|[\\\\t ][^\\\\n\\\\r]*|)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"ParserRule","entry":true,"name":"Treemap","returnType":{"$ref":"#/interfaces@4"},"definition":{"$type":"Group","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@6"},"arguments":[]},{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@0"},"arguments":[]},{"$type":"Assignment","feature":"TreemapRows","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@15"},"arguments":[]}}],"cardinality":"*"}]},"fragment":false,"parameters":[]},{"$type":"TerminalRule","name":"TREEMAP_KEYWORD","definition":{"$type":"TerminalAlternatives","elements":[{"$type":"CharacterRange","left":{"$type":"Keyword","value":"treemap-beta"},"parenthesized":false},{"$type":"CharacterRange","left":{"$type":"Keyword","value":"treemap"},"parenthesized":false}],"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"CLASS_DEF","definition":{"$type":"RegexToken","regex":"/classDef\\\\s+([a-zA-Z_][a-zA-Z0-9_]+)(?:\\\\s+([^;\\\\r\\\\n]*))?(?:;)?/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"STYLE_SEPARATOR","definition":{"$type":"CharacterRange","left":{"$type":"Keyword","value":":::"},"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"SEPARATOR","definition":{"$type":"CharacterRange","left":{"$type":"Keyword","value":":"},"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"COMMA","definition":{"$type":"CharacterRange","left":{"$type":"Keyword","value":","},"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"INDENTATION","definition":{"$type":"RegexToken","regex":"/[ \\\\t]{1,}/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","hidden":true,"name":"WS","definition":{"$type":"RegexToken","regex":"/[ \\\\t]+/","parenthesized":false},"fragment":false},{"$type":"TerminalRule","hidden":true,"name":"ML_COMMENT","definition":{"$type":"RegexToken","regex":"/\\\\%\\\\%[^\\\\n]*/","parenthesized":false},"fragment":false},{"$type":"TerminalRule","hidden":true,"name":"NL","definition":{"$type":"RegexToken","regex":"/\\\\r?\\\\n/","parenthesized":false},"fragment":false},{"$type":"ParserRule","name":"TreemapRow","definition":{"$type":"Group","elements":[{"$type":"Assignment","feature":"indent","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@11"},"arguments":[]},"cardinality":"?"},{"$type":"Alternatives","elements":[{"$type":"Assignment","feature":"item","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@17"},"arguments":[]}},{"$type":"RuleCall","rule":{"$ref":"#/rules@16"},"arguments":[]}]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"ClassDef","dataType":"string","definition":{"$type":"RuleCall","rule":{"$ref":"#/rules@7"},"arguments":[]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"Item","returnType":{"$ref":"#/interfaces@0"},"definition":{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@19"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@18"},"arguments":[]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"Section","returnType":{"$ref":"#/interfaces@1"},"definition":{"$type":"Group","elements":[{"$type":"Assignment","feature":"name","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@23"},"arguments":[]}},{"$type":"Group","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@8"},"arguments":[]},{"$type":"Assignment","feature":"classSelector","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@20"},"arguments":[]}}],"cardinality":"?"}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"Leaf","returnType":{"$ref":"#/interfaces@2"},"definition":{"$type":"Group","elements":[{"$type":"Assignment","feature":"name","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@23"},"arguments":[]}},{"$type":"RuleCall","rule":{"$ref":"#/rules@11"},"arguments":[],"cardinality":"?"},{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@9"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@10"},"arguments":[]}]},{"$type":"RuleCall","rule":{"$ref":"#/rules@11"},"arguments":[],"cardinality":"?"},{"$type":"Assignment","feature":"value","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@22"},"arguments":[]}},{"$type":"Group","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@8"},"arguments":[]},{"$type":"Assignment","feature":"classSelector","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@20"},"arguments":[]}}],"cardinality":"?"}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"TerminalRule","name":"ID2","definition":{"$type":"RegexToken","regex":"/[a-zA-Z_][a-zA-Z0-9_]*/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"NUMBER2","definition":{"$type":"RegexToken","regex":"/[0-9_\\\\.\\\\,]+/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"ParserRule","name":"MyNumber","dataType":"number","definition":{"$type":"RuleCall","rule":{"$ref":"#/rules@21"},"arguments":[]},"entry":false,"fragment":false,"parameters":[]},{"$type":"TerminalRule","name":"STRING2","definition":{"$type":"RegexToken","regex":"/\\"[^\\"]*\\"|'[^']*'/","parenthesized":false},"fragment":false,"hidden":false}],"interfaces":[{"$type":"Interface","name":"Item","attributes":[{"$type":"TypeAttribute","name":"name","type":{"$type":"SimpleType","primitiveType":"string"},"isOptional":false},{"$type":"TypeAttribute","name":"classSelector","isOptional":true,"type":{"$type":"SimpleType","primitiveType":"string"}}],"superTypes":[]},{"$type":"Interface","name":"Section","superTypes":[{"$ref":"#/interfaces@0"}],"attributes":[]},{"$type":"Interface","name":"Leaf","superTypes":[{"$ref":"#/interfaces@0"}],"attributes":[{"$type":"TypeAttribute","name":"value","type":{"$type":"SimpleType","primitiveType":"number"},"isOptional":false}]},{"$type":"Interface","name":"ClassDefStatement","attributes":[{"$type":"TypeAttribute","name":"className","type":{"$type":"SimpleType","primitiveType":"string"},"isOptional":false},{"$type":"TypeAttribute","name":"styleText","type":{"$type":"SimpleType","primitiveType":"string"},"isOptional":false}],"superTypes":[]},{"$type":"Interface","name":"Treemap","attributes":[{"$type":"TypeAttribute","name":"TreemapRows","type":{"$type":"ArrayType","elementType":{"$type":"SimpleType","typeRef":{"$ref":"#/rules@15"}}},"isOptional":false},{"$type":"TypeAttribute","name":"title","isOptional":true,"type":{"$type":"SimpleType","primitiveType":"string"}},{"$type":"TypeAttribute","name":"accTitle","isOptional":true,"type":{"$type":"SimpleType","primitiveType":"string"}},{"$type":"TypeAttribute","name":"accDescr","isOptional":true,"type":{"$type":"SimpleType","primitiveType":"string"}}],"superTypes":[]}],"imports":[],"types":[],"$comment":"/**\\n * Treemap grammar for Langium\\n * Converted from mindmap grammar\\n *\\n * The ML_COMMENT and NL hidden terminals handle whitespace, comments, and newlines\\n * before the treemap keyword, allowing for empty lines and comments before the\\n * treemap declaration.\\n */"}`)), "TreemapGrammarGrammar"), Ju, cR = /* @__PURE__ */ _(() => Ju ?? (Ju = Wt(`{"$type":"Grammar","isDeclared":true,"name":"TreeViewGrammar","rules":[{"$type":"TerminalRule","name":"ACC_DESCR","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*accDescr(?:[\\\\t ]*:([^\\\\n\\\\r]*?(?=%%)|[^\\\\n\\\\r]*)|\\\\s*{([^}]*)})/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ACC_TITLE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*accTitle[\\\\t ]*:(?:[^\\\\n\\\\r]*?(?=%%)|[^\\\\n\\\\r]*)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"TITLE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*title(?:[\\\\t ][^\\\\n\\\\r]*?(?=%%)|[\\\\t ][^\\\\n\\\\r]*|)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"ParserRule","entry":true,"name":"TreeView","returnType":{"$ref":"#/interfaces@0"},"definition":{"$type":"Group","elements":[{"$type":"Keyword","value":"treeView-beta"},{"$type":"RuleCall","rule":{"$ref":"#/rules@4"},"arguments":[],"cardinality":"?"},{"$type":"Assignment","feature":"nodes","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@9"},"arguments":[]},"cardinality":"*"}]},"fragment":false,"parameters":[]},{"$type":"ParserRule","fragment":true,"name":"TitleAndAccessibilities","definition":{"$type":"Alternatives","elements":[{"$type":"Assignment","feature":"accDescr","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@0"},"arguments":[]}},{"$type":"Assignment","feature":"accTitle","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@1"},"arguments":[]}},{"$type":"Assignment","feature":"title","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@2"},"arguments":[]}}],"cardinality":"+"},"entry":false,"parameters":[]},{"$type":"TerminalRule","name":"INDENTATION","definition":{"$type":"RegexToken","regex":"/[ \\\\t]{1,}/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","hidden":true,"name":"WS","definition":{"$type":"RegexToken","regex":"/[ \\\\t]+/","parenthesized":false},"fragment":false},{"$type":"TerminalRule","hidden":true,"name":"ML_COMMENT","definition":{"$type":"RegexToken","regex":"/\\\\%\\\\%[^\\\\n]*/","parenthesized":false},"fragment":false},{"$type":"TerminalRule","hidden":true,"name":"NL","definition":{"$type":"RegexToken","regex":"/\\\\r?\\\\n/","parenthesized":false},"fragment":false},{"$type":"ParserRule","name":"TreeNode","definition":{"$type":"Group","elements":[{"$type":"Assignment","feature":"indent","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@5"},"arguments":[]},"cardinality":"?"},{"$type":"Assignment","feature":"name","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@10"},"arguments":[]}}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"TerminalRule","name":"STRING2","definition":{"$type":"RegexToken","regex":"/\\"[^\\"]*\\"|'[^']*'/","parenthesized":false},"fragment":false,"hidden":false}],"interfaces":[{"$type":"Interface","name":"TreeView","attributes":[{"$type":"TypeAttribute","name":"nodes","type":{"$type":"ArrayType","elementType":{"$type":"SimpleType","typeRef":{"$ref":"#/rules@9"}}},"isOptional":false},{"$type":"TypeAttribute","name":"title","isOptional":true,"type":{"$type":"SimpleType","primitiveType":"string"}},{"$type":"TypeAttribute","name":"accTitle","isOptional":true,"type":{"$type":"SimpleType","primitiveType":"string"}},{"$type":"TypeAttribute","name":"accDescr","isOptional":true,"type":{"$type":"SimpleType","primitiveType":"string"}}],"superTypes":[]}],"imports":[],"types":[],"$comment":"/**\\n * TreeView grammar for Langium\\n * Converted from treemap grammar\\n *\\n * The ML_COMMENT and NL hidden terminals handle whitespace, comments, and newlines\\n * before the treemap keyword, allowing for empty lines and comments before the\\n * treeView declaration.\\n */"}`)), "TreeViewGrammarGrammar"), Zu, uR = /* @__PURE__ */ _(() => Zu ?? (Zu = Wt(`{"$type":"Grammar","isDeclared":true,"name":"WardleyGrammar","imports":[],"rules":[{"$type":"ParserRule","entry":true,"name":"Wardley","definition":{"$type":"Group","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@52"},"arguments":[],"cardinality":"*"},{"$type":"RuleCall","rule":{"$ref":"#/rules@25"},"arguments":[]},{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@52"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@42"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@1"},"arguments":[]}],"cardinality":"*"}]},"fragment":false,"parameters":[]},{"$type":"ParserRule","fragment":true,"name":"Statement","definition":{"$type":"Alternatives","elements":[{"$type":"Assignment","feature":"size","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@2"},"arguments":[]}},{"$type":"Assignment","feature":"evolution","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@3"},"arguments":[]}},{"$type":"Assignment","feature":"anchors","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@5"},"arguments":[]}},{"$type":"Assignment","feature":"components","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@6"},"arguments":[]}},{"$type":"Assignment","feature":"links","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@9"},"arguments":[]}},{"$type":"Assignment","feature":"evolves","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@10"},"arguments":[]}},{"$type":"Assignment","feature":"pipelines","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@11"},"arguments":[]}},{"$type":"Assignment","feature":"notes","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@13"},"arguments":[]}},{"$type":"Assignment","feature":"annotations","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@14"},"arguments":[]}},{"$type":"Assignment","feature":"annotation","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@15"},"arguments":[]}},{"$type":"Assignment","feature":"accelerators","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@17"},"arguments":[]}},{"$type":"Assignment","feature":"deaccelerators","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@18"},"arguments":[]}}]},"entry":false,"parameters":[]},{"$type":"ParserRule","name":"Size","definition":{"$type":"Group","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@26"},"arguments":[]},{"$type":"Keyword","value":"["},{"$type":"Assignment","feature":"width","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@48"},"arguments":[]}},{"$type":"Keyword","value":","},{"$type":"Assignment","feature":"height","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@48"},"arguments":[]}},{"$type":"Keyword","value":"]"},{"$type":"RuleCall","rule":{"$ref":"#/rules@41"},"arguments":[]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"Evolution","definition":{"$type":"Group","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@27"},"arguments":[]},{"$type":"Assignment","feature":"stages","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@4"},"arguments":[]}},{"$type":"Group","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@20"},"arguments":[]},{"$type":"Assignment","feature":"stages","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@4"},"arguments":[]}}],"cardinality":"+"},{"$type":"RuleCall","rule":{"$ref":"#/rules@41"},"arguments":[]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"EvolutionStage","definition":{"$type":"Group","elements":[{"$type":"Assignment","feature":"name","operator":"=","terminal":{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@51"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@50"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@39"},"arguments":[]}]}},{"$type":"Group","elements":[{"$type":"Keyword","value":"@"},{"$type":"Assignment","feature":"boundary","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@19"},"arguments":[]}}],"cardinality":"?"},{"$type":"Group","elements":[{"$type":"Keyword","value":"/"},{"$type":"Assignment","feature":"secondName","operator":"=","terminal":{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@51"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@50"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@39"},"arguments":[]}]}}],"cardinality":"?"}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"Anchor","definition":{"$type":"Group","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@28"},"arguments":[]},{"$type":"Assignment","feature":"name","operator":"=","terminal":{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@50"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@51"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@39"},"arguments":[]}]}},{"$type":"Keyword","value":"["},{"$type":"Assignment","feature":"visibility","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@19"},"arguments":[]}},{"$type":"Keyword","value":","},{"$type":"Assignment","feature":"evolution","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@19"},"arguments":[]}},{"$type":"Keyword","value":"]"},{"$type":"RuleCall","rule":{"$ref":"#/rules@41"},"arguments":[]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"Component","definition":{"$type":"Group","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@29"},"arguments":[]},{"$type":"Assignment","feature":"name","operator":"=","terminal":{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@50"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@51"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@39"},"arguments":[]}]}},{"$type":"Keyword","value":"["},{"$type":"Assignment","feature":"visibility","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@19"},"arguments":[]}},{"$type":"Keyword","value":","},{"$type":"Assignment","feature":"evolution","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@19"},"arguments":[]}},{"$type":"Keyword","value":"]"},{"$type":"Assignment","feature":"label","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@7"},"arguments":[]},"cardinality":"?"},{"$type":"Assignment","feature":"decorator","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@8"},"arguments":[]},"cardinality":"?"},{"$type":"Alternatives","elements":[{"$type":"Assignment","feature":"inertia","operator":"?=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@31"},"arguments":[]}},{"$type":"Group","elements":[{"$type":"Keyword","value":"("},{"$type":"Assignment","feature":"inertia","operator":"?=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@31"},"arguments":[]}},{"$type":"Keyword","value":")"}]}],"cardinality":"?"},{"$type":"RuleCall","rule":{"$ref":"#/rules@41"},"arguments":[]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"Label","definition":{"$type":"Group","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@30"},"arguments":[]},{"$type":"Keyword","value":"["},{"$type":"Assignment","feature":"negX","operator":"?=","terminal":{"$type":"Keyword","value":"-"},"cardinality":"?"},{"$type":"Assignment","feature":"offsetX","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@48"},"arguments":[]}},{"$type":"Keyword","value":","},{"$type":"Assignment","feature":"negY","operator":"?=","terminal":{"$type":"Keyword","value":"-"},"cardinality":"?"},{"$type":"Assignment","feature":"offsetY","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@48"},"arguments":[]}},{"$type":"Keyword","value":"]"}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"Decorator","definition":{"$type":"Group","elements":[{"$type":"Keyword","value":"("},{"$type":"Assignment","feature":"strategy","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@24"},"arguments":[]}},{"$type":"Keyword","value":")"}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"Link","definition":{"$type":"Group","elements":[{"$type":"Assignment","feature":"from","operator":"=","terminal":{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@50"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@51"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@39"},"arguments":[]}]}},{"$type":"Assignment","feature":"fromPort","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@21"},"arguments":[]},"cardinality":"?"},{"$type":"Assignment","feature":"arrow","operator":"=","terminal":{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@22"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@20"},"arguments":[]}]},"cardinality":"?"},{"$type":"Assignment","feature":"to","operator":"=","terminal":{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@50"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@51"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@39"},"arguments":[]}]}},{"$type":"Assignment","feature":"toPort","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@21"},"arguments":[]},"cardinality":"?"},{"$type":"Assignment","feature":"linkLabel","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@23"},"arguments":[]},"cardinality":"?"},{"$type":"RuleCall","rule":{"$ref":"#/rules@41"},"arguments":[]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"Evolve","definition":{"$type":"Group","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@32"},"arguments":[]},{"$type":"Assignment","feature":"component","operator":"=","terminal":{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@50"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@51"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@39"},"arguments":[]}]}},{"$type":"Assignment","feature":"target","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@19"},"arguments":[]}},{"$type":"RuleCall","rule":{"$ref":"#/rules@41"},"arguments":[]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"Pipeline","definition":{"$type":"Group","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@33"},"arguments":[]},{"$type":"Assignment","feature":"parent","operator":"=","terminal":{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@50"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@51"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@39"},"arguments":[]}]}},{"$type":"Keyword","value":"{"},{"$type":"RuleCall","rule":{"$ref":"#/rules@52"},"arguments":[],"cardinality":"+"},{"$type":"Assignment","feature":"components","operator":"+=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@12"},"arguments":[]},"cardinality":"+"},{"$type":"Keyword","value":"}"},{"$type":"RuleCall","rule":{"$ref":"#/rules@41"},"arguments":[]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"PipelineComponent","definition":{"$type":"Group","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@29"},"arguments":[]},{"$type":"Assignment","feature":"name","operator":"=","terminal":{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@50"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@51"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@39"},"arguments":[]}]}},{"$type":"Keyword","value":"["},{"$type":"Assignment","feature":"evolution","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@19"},"arguments":[]}},{"$type":"Keyword","value":"]"},{"$type":"Assignment","feature":"label","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@7"},"arguments":[]},"cardinality":"?"},{"$type":"RuleCall","rule":{"$ref":"#/rules@41"},"arguments":[]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"Note","definition":{"$type":"Group","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@34"},"arguments":[]},{"$type":"Assignment","feature":"text","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@50"},"arguments":[]}},{"$type":"Keyword","value":"["},{"$type":"Assignment","feature":"visibility","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@19"},"arguments":[]}},{"$type":"Keyword","value":","},{"$type":"Assignment","feature":"evolution","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@19"},"arguments":[]}},{"$type":"Keyword","value":"]"},{"$type":"RuleCall","rule":{"$ref":"#/rules@41"},"arguments":[]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"Annotations","definition":{"$type":"Group","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@35"},"arguments":[]},{"$type":"Keyword","value":"["},{"$type":"Assignment","feature":"x","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@16"},"arguments":[]}},{"$type":"Keyword","value":","},{"$type":"Assignment","feature":"y","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@16"},"arguments":[]}},{"$type":"Keyword","value":"]"},{"$type":"RuleCall","rule":{"$ref":"#/rules@41"},"arguments":[]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"Annotation","definition":{"$type":"Group","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@36"},"arguments":[]},{"$type":"Assignment","feature":"number","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@48"},"arguments":[]}},{"$type":"Keyword","value":","},{"$type":"Keyword","value":"["},{"$type":"Assignment","feature":"x","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@16"},"arguments":[]}},{"$type":"Keyword","value":","},{"$type":"Assignment","feature":"y","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@16"},"arguments":[]}},{"$type":"Keyword","value":"]"},{"$type":"Assignment","feature":"text","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@50"},"arguments":[]}},{"$type":"RuleCall","rule":{"$ref":"#/rules@41"},"arguments":[]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"CoordinateValue","dataType":"number","definition":{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@19"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@48"},"arguments":[]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"Accelerator","definition":{"$type":"Group","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@37"},"arguments":[]},{"$type":"Assignment","feature":"name","operator":"=","terminal":{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@50"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@51"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@39"},"arguments":[]}]}},{"$type":"Keyword","value":"["},{"$type":"Assignment","feature":"x","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@19"},"arguments":[]}},{"$type":"Keyword","value":","},{"$type":"Assignment","feature":"y","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@19"},"arguments":[]}},{"$type":"Keyword","value":"]"},{"$type":"RuleCall","rule":{"$ref":"#/rules@41"},"arguments":[]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","name":"Deaccelerator","definition":{"$type":"Group","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@38"},"arguments":[]},{"$type":"Assignment","feature":"name","operator":"=","terminal":{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@50"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@51"},"arguments":[]},{"$type":"RuleCall","rule":{"$ref":"#/rules@39"},"arguments":[]}]}},{"$type":"Keyword","value":"["},{"$type":"Assignment","feature":"x","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@19"},"arguments":[]}},{"$type":"Keyword","value":","},{"$type":"Assignment","feature":"y","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@19"},"arguments":[]}},{"$type":"Keyword","value":"]"},{"$type":"RuleCall","rule":{"$ref":"#/rules@41"},"arguments":[]}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"TerminalRule","name":"WARDLEY_NUMBER","type":{"$type":"ReturnType","name":"number"},"definition":{"$type":"RegexToken","regex":"/[0-9]+\\\\.[0-9]+/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ARROW","definition":{"$type":"CharacterRange","left":{"$type":"Keyword","value":"->"},"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"LINK_PORT","definition":{"$type":"TerminalAlternatives","elements":[{"$type":"TerminalAlternatives","elements":[{"$type":"CharacterRange","left":{"$type":"Keyword","value":"+<>"},"parenthesized":false},{"$type":"CharacterRange","left":{"$type":"Keyword","value":"+>"},"parenthesized":false}],"parenthesized":false},{"$type":"CharacterRange","left":{"$type":"Keyword","value":"+<"},"parenthesized":false}],"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"LINK_ARROW","definition":{"$type":"TerminalAlternatives","elements":[{"$type":"TerminalAlternatives","elements":[{"$type":"TerminalAlternatives","elements":[{"$type":"TerminalAlternatives","elements":[{"$type":"TerminalAlternatives","elements":[{"$type":"CharacterRange","left":{"$type":"Keyword","value":"-->"},"parenthesized":false},{"$type":"CharacterRange","left":{"$type":"Keyword","value":"-.->"},"parenthesized":false}],"parenthesized":false},{"$type":"CharacterRange","left":{"$type":"Keyword","value":">"},"parenthesized":false}],"parenthesized":false},{"$type":"RegexToken","regex":"/\\\\+'[^']*'<>/","parenthesized":false}],"parenthesized":false},{"$type":"RegexToken","regex":"/\\\\+'[^']*'</","parenthesized":false}],"parenthesized":false},{"$type":"RegexToken","regex":"/\\\\+'[^']*'>/","parenthesized":false}],"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"LINK_LABEL","definition":{"$type":"RegexToken","regex":"/;[^\\\\n\\\\r]+/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"STRATEGY","definition":{"$type":"TerminalAlternatives","elements":[{"$type":"TerminalAlternatives","elements":[{"$type":"TerminalAlternatives","elements":[{"$type":"CharacterRange","left":{"$type":"Keyword","value":"build"},"parenthesized":false},{"$type":"CharacterRange","left":{"$type":"Keyword","value":"buy"},"parenthesized":false}],"parenthesized":false},{"$type":"CharacterRange","left":{"$type":"Keyword","value":"outsource"},"parenthesized":false}],"parenthesized":false},{"$type":"CharacterRange","left":{"$type":"Keyword","value":"market"},"parenthesized":false}],"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"KW_WARDLEY","definition":{"$type":"CharacterRange","left":{"$type":"Keyword","value":"wardley-beta"},"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"KW_SIZE","definition":{"$type":"CharacterRange","left":{"$type":"Keyword","value":"size"},"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"KW_EVOLUTION","definition":{"$type":"CharacterRange","left":{"$type":"Keyword","value":"evolution"},"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"KW_ANCHOR","definition":{"$type":"CharacterRange","left":{"$type":"Keyword","value":"anchor"},"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"KW_COMPONENT","definition":{"$type":"CharacterRange","left":{"$type":"Keyword","value":"component"},"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"KW_LABEL","definition":{"$type":"CharacterRange","left":{"$type":"Keyword","value":"label"},"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"KW_INERTIA","definition":{"$type":"CharacterRange","left":{"$type":"Keyword","value":"inertia"},"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"KW_EVOLVE","definition":{"$type":"CharacterRange","left":{"$type":"Keyword","value":"evolve"},"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"KW_PIPELINE","definition":{"$type":"CharacterRange","left":{"$type":"Keyword","value":"pipeline"},"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"KW_NOTE","definition":{"$type":"CharacterRange","left":{"$type":"Keyword","value":"note"},"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"KW_ANNOTATIONS","definition":{"$type":"CharacterRange","left":{"$type":"Keyword","value":"annotations"},"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"KW_ANNOTATION","definition":{"$type":"CharacterRange","left":{"$type":"Keyword","value":"annotation"},"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"KW_ACCELERATOR","definition":{"$type":"CharacterRange","left":{"$type":"Keyword","value":"accelerator"},"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"KW_DEACCELERATOR","definition":{"$type":"CharacterRange","left":{"$type":"Keyword","value":"deaccelerator"},"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"NAME_WITH_SPACES","definition":{"$type":"RegexToken","regex":"/(?!title\\\\s|accTitle|accDescr)[A-Za-z][A-Za-z0-9_()&]*(?:[ \\\\t]+[A-Za-z(][A-Za-z0-9_()&]*)*/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","hidden":true,"name":"WS","definition":{"$type":"RegexToken","regex":"/[ \\\\t]+/","parenthesized":false},"fragment":false},{"$type":"ParserRule","name":"EOL","dataType":"string","definition":{"$type":"Alternatives","elements":[{"$type":"RuleCall","rule":{"$ref":"#/rules@52"},"arguments":[],"cardinality":"+"},{"$type":"EndOfFile"}]},"entry":false,"fragment":false,"parameters":[]},{"$type":"ParserRule","fragment":true,"name":"TitleAndAccessibilities","definition":{"$type":"Group","elements":[{"$type":"Alternatives","elements":[{"$type":"Assignment","feature":"accDescr","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@44"},"arguments":[]}},{"$type":"Assignment","feature":"accTitle","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@45"},"arguments":[]}},{"$type":"Assignment","feature":"title","operator":"=","terminal":{"$type":"RuleCall","rule":{"$ref":"#/rules@46"},"arguments":[]}}]},{"$type":"RuleCall","rule":{"$ref":"#/rules@41"},"arguments":[]}],"cardinality":"+"},"entry":false,"parameters":[]},{"$type":"TerminalRule","name":"BOOLEAN","type":{"$type":"ReturnType","name":"boolean"},"definition":{"$type":"TerminalAlternatives","elements":[{"$type":"CharacterRange","left":{"$type":"Keyword","value":"true"},"parenthesized":false},{"$type":"CharacterRange","left":{"$type":"Keyword","value":"false"},"parenthesized":false}],"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ACC_DESCR","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*accDescr(?:[\\\\t ]*:([^\\\\n\\\\r]*?(?=%%)|[^\\\\n\\\\r]*)|\\\\s*{([^}]*)})/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ACC_TITLE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*accTitle[\\\\t ]*:(?:[^\\\\n\\\\r]*?(?=%%)|[^\\\\n\\\\r]*)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"TITLE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*title(?:[\\\\t ][^\\\\n\\\\r]*?(?=%%)|[\\\\t ][^\\\\n\\\\r]*|)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"FLOAT","type":{"$type":"ReturnType","name":"number"},"definition":{"$type":"RegexToken","regex":"/[0-9]+\\\\.[0-9]+(?!\\\\.)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"INT","type":{"$type":"ReturnType","name":"number"},"definition":{"$type":"RegexToken","regex":"/0|[1-9][0-9]*(?!\\\\.)/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"NUMBER","type":{"$type":"ReturnType","name":"number"},"definition":{"$type":"TerminalAlternatives","elements":[{"$type":"TerminalRuleCall","rule":{"$ref":"#/rules@47"},"parenthesized":false},{"$type":"TerminalRuleCall","rule":{"$ref":"#/rules@48"},"parenthesized":false}],"parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"STRING","type":{"$type":"ReturnType","name":"string"},"definition":{"$type":"RegexToken","regex":"/\\"([^\\"\\\\\\\\]|\\\\\\\\.)*\\"|'([^'\\\\\\\\]|\\\\\\\\.)*'/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"ID","type":{"$type":"ReturnType","name":"string"},"definition":{"$type":"RegexToken","regex":"/[\\\\w]([-\\\\w]*\\\\w)?/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","name":"NEWLINE","definition":{"$type":"RegexToken","regex":"/\\\\r?\\\\n/","parenthesized":false},"fragment":false,"hidden":false},{"$type":"TerminalRule","hidden":true,"name":"WHITESPACE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]+/","parenthesized":false},"fragment":false},{"$type":"TerminalRule","hidden":true,"name":"YAML","definition":{"$type":"RegexToken","regex":"/---[\\\\t ]*\\\\r?\\\\n(?:[\\\\S\\\\s]*?\\\\r?\\\\n)?---(?:\\\\r?\\\\n|(?!\\\\S))/","parenthesized":false},"fragment":false},{"$type":"TerminalRule","hidden":true,"name":"DIRECTIVE","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*%%{[\\\\S\\\\s]*?}%%(?:\\\\r?\\\\n|(?!\\\\S))/","parenthesized":false},"fragment":false},{"$type":"TerminalRule","hidden":true,"name":"SINGLE_LINE_COMMENT","definition":{"$type":"RegexToken","regex":"/[\\\\t ]*%%[^\\\\n\\\\r]*/","parenthesized":false},"fragment":false}],"interfaces":[],"types":[]}`)), "WardleyGrammarGrammar"), fR = {
  languageId: "architecture",
  fileExtensions: [".mmd", ".mermaid"],
  caseInsensitive: !1,
  mode: "production"
}, dR = {
  languageId: "gitGraph",
  fileExtensions: [".mmd", ".mermaid"],
  caseInsensitive: !1,
  mode: "production"
}, hR = {
  languageId: "info",
  fileExtensions: [".mmd", ".mermaid"],
  caseInsensitive: !1,
  mode: "production"
}, pR = {
  languageId: "packet",
  fileExtensions: [".mmd", ".mermaid"],
  caseInsensitive: !1,
  mode: "production"
}, mR = {
  languageId: "pie",
  fileExtensions: [".mmd", ".mermaid"],
  caseInsensitive: !1,
  mode: "production"
}, gR = {
  languageId: "radar",
  fileExtensions: [".mmd", ".mermaid"],
  caseInsensitive: !1,
  mode: "production"
}, yR = {
  languageId: "treemap",
  fileExtensions: [".mmd", ".mermaid"],
  caseInsensitive: !1,
  mode: "production"
}, TR = {
  languageId: "treeView",
  fileExtensions: [".mmd", ".mermaid"],
  caseInsensitive: !1,
  mode: "production"
}, RR = {
  languageId: "wardley",
  fileExtensions: [".mmd", ".mermaid"],
  caseInsensitive: !1,
  mode: "production"
}, Kt = {
  AstReflection: /* @__PURE__ */ _(() => new Od(), "AstReflection")
}, vR = {
  Grammar: /* @__PURE__ */ _(() => rR(), "Grammar"),
  LanguageMetaData: /* @__PURE__ */ _(() => fR, "LanguageMetaData"),
  parser: {}
}, ER = {
  Grammar: /* @__PURE__ */ _(() => nR(), "Grammar"),
  LanguageMetaData: /* @__PURE__ */ _(() => dR, "LanguageMetaData"),
  parser: {}
}, AR = {
  Grammar: /* @__PURE__ */ _(() => iR(), "Grammar"),
  LanguageMetaData: /* @__PURE__ */ _(() => hR, "LanguageMetaData"),
  parser: {}
}, $R = {
  Grammar: /* @__PURE__ */ _(() => aR(), "Grammar"),
  LanguageMetaData: /* @__PURE__ */ _(() => pR, "LanguageMetaData"),
  parser: {}
}, CR = {
  Grammar: /* @__PURE__ */ _(() => sR(), "Grammar"),
  LanguageMetaData: /* @__PURE__ */ _(() => mR, "LanguageMetaData"),
  parser: {}
}, SR = {
  Grammar: /* @__PURE__ */ _(() => oR(), "Grammar"),
  LanguageMetaData: /* @__PURE__ */ _(() => gR, "LanguageMetaData"),
  parser: {}
}, kR = {
  Grammar: /* @__PURE__ */ _(() => lR(), "Grammar"),
  LanguageMetaData: /* @__PURE__ */ _(() => yR, "LanguageMetaData"),
  parser: {}
}, wR = {
  Grammar: /* @__PURE__ */ _(() => cR(), "Grammar"),
  LanguageMetaData: /* @__PURE__ */ _(() => TR, "LanguageMetaData"),
  parser: {}
}, bR = {
  Grammar: /* @__PURE__ */ _(() => uR(), "Grammar"),
  LanguageMetaData: /* @__PURE__ */ _(() => RR, "LanguageMetaData"),
  parser: {}
}, NR = /accDescr(?:[\t ]*:([^\n\r]*)|\s*{([^}]*)})/, _R = /accTitle[\t ]*:([^\n\r]*)/, IR = /title([\t ][^\n\r]*|)/, PR = {
  ACC_DESCR: NR,
  ACC_TITLE: _R,
  TITLE: IR
}, yn = class extends Td {
  static {
    _(this, "AbstractMermaidValueConverter");
  }
  runConverter(t, e, r) {
    let n = this.runCommonConverter(t, e, r);
    return n === void 0 && (n = this.runCustomConverter(t, e, r)), n === void 0 ? super.runConverter(t, e, r) : n;
  }
  runCommonConverter(t, e, r) {
    const n = PR[t.name];
    if (n === void 0)
      return;
    const i = n.exec(e);
    if (i !== null) {
      if (i[1] !== void 0)
        return i[1].trim().replace(/[\t ]{2,}/gm, " ");
      if (i[2] !== void 0)
        return i[2].replace(/^\s*/gm, "").replace(/\s+$/gm, "").replace(/[\t ]{2,}/gm, " ").replace(/[\n\r]{2,}/gm, `
`);
    }
  }
}, ds = class extends yn {
  static {
    _(this, "CommonValueConverter");
  }
  runCustomConverter(t, e, r) {
  }
}, Vt = class extends yd {
  static {
    _(this, "AbstractMermaidTokenBuilder");
  }
  constructor(t) {
    super(), this.keywords = new Set(t);
  }
  buildKeywordTokens(t, e, r) {
    const n = super.buildKeywordTokens(t, e, r);
    return n.forEach((i) => {
      this.keywords.has(i.name) && i.PATTERN !== void 0 && (i.PATTERN = new RegExp(i.PATTERN.toString() + "(?:(?=%%)|(?!\\S))"));
    }), n;
  }
};
(class extends Vt {
  static {
    _(this, "CommonTokenBuilder");
  }
});
var OR = class extends Vt {
  static {
    _(this, "TreemapTokenBuilder");
  }
  constructor() {
    super(["treemap"]);
  }
}, LR = /classDef\s+([A-Z_a-z]\w+)(?:\s+([^\n\r;]*))?;?/, xR = class extends yn {
  static {
    _(this, "TreemapValueConverter");
  }
  runCustomConverter(t, e, r) {
    if (t.name === "NUMBER2")
      return parseFloat(e.replace(/,/g, ""));
    if (t.name === "SEPARATOR")
      return e.substring(1, e.length - 1);
    if (t.name === "STRING2")
      return e.substring(1, e.length - 1);
    if (t.name === "INDENTATION")
      return e.length;
    if (t.name === "ClassDef") {
      if (typeof e != "string")
        return e;
      const n = LR.exec(e);
      if (n)
        return {
          $type: "ClassDefStatement",
          className: n[1],
          styleText: n[2] || void 0
        };
    }
  }
};
function Ld(t) {
  const e = t.validation.TreemapValidator, r = t.validation.ValidationRegistry;
  if (r) {
    const n = {
      Treemap: e.checkSingleRoot.bind(e)
      // Remove unused validation for TreemapRow
    };
    r.register(n, e);
  }
}
_(Ld, "registerValidationChecks");
var DR = class {
  static {
    _(this, "TreemapValidator");
  }
  /**
   * Validates that a treemap has only one root node.
   * A root node is defined as a node that has no indentation.
   */
  checkSingleRoot(t, e) {
    let r;
    for (const n of t.TreemapRows)
      n.item && (r === void 0 && // Check if this is a root node (no indentation)
      n.indent === void 0 ? r = 0 : n.indent === void 0 ? e("error", "Multiple root nodes are not allowed in a treemap.", {
        node: n,
        property: "item"
      }) : r !== void 0 && r >= parseInt(n.indent, 10) && e("error", "Multiple root nodes are not allowed in a treemap.", {
        node: n,
        property: "item"
      }));
  }
}, MR = {
  parser: {
    TokenBuilder: /* @__PURE__ */ _(() => new OR(), "TokenBuilder"),
    ValueConverter: /* @__PURE__ */ _(() => new xR(), "ValueConverter")
  },
  validation: {
    TreemapValidator: /* @__PURE__ */ _(() => new DR(), "TreemapValidator")
  }
};
function FR(t = At) {
  const e = ke(
    Et(t),
    Kt
  ), r = ke(
    vt({ shared: e }),
    kR,
    MR
  );
  return e.ServiceRegistry.register(r), Ld(r), { shared: e, Treemap: r };
}
_(FR, "createTreemapServices");
var GR = class extends yn {
  static {
    _(this, "WardleyValueConverter");
  }
  runCustomConverter(t, e, r) {
    switch (t.name.toUpperCase()) {
      case "LINK_LABEL":
        return e.substring(1).trim();
      default:
        return;
    }
  }
}, jR = {
  parser: {
    ValueConverter: /* @__PURE__ */ _(() => new GR(), "ValueConverter")
  }
};
function zR(t = At) {
  const e = ke(
    Et(t),
    Kt
  ), r = ke(
    vt({ shared: e }),
    bR,
    jR
  );
  return e.ServiceRegistry.register(r), { shared: e, Wardley: r };
}
_(zR, "createWardleyServices");
var UR = class extends Vt {
  static {
    _(this, "GitGraphTokenBuilder");
  }
  constructor() {
    super(["gitGraph"]);
  }
}, qR = {
  parser: {
    TokenBuilder: /* @__PURE__ */ _(() => new UR(), "TokenBuilder"),
    ValueConverter: /* @__PURE__ */ _(() => new ds(), "ValueConverter")
  }
};
function BR(t = At) {
  const e = ke(
    Et(t),
    Kt
  ), r = ke(
    vt({ shared: e }),
    ER,
    qR
  );
  return e.ServiceRegistry.register(r), { shared: e, GitGraph: r };
}
_(BR, "createGitGraphServices");
var WR = class extends Vt {
  static {
    _(this, "InfoTokenBuilder");
  }
  constructor() {
    super(["info", "showInfo"]);
  }
}, KR = {
  parser: {
    TokenBuilder: /* @__PURE__ */ _(() => new WR(), "TokenBuilder"),
    ValueConverter: /* @__PURE__ */ _(() => new ds(), "ValueConverter")
  }
};
function VR(t = At) {
  const e = ke(
    Et(t),
    Kt
  ), r = ke(
    vt({ shared: e }),
    AR,
    KR
  );
  return e.ServiceRegistry.register(r), { shared: e, Info: r };
}
_(VR, "createInfoServices");
var HR = class extends Vt {
  static {
    _(this, "PacketTokenBuilder");
  }
  constructor() {
    super(["packet"]);
  }
}, XR = {
  parser: {
    TokenBuilder: /* @__PURE__ */ _(() => new HR(), "TokenBuilder"),
    ValueConverter: /* @__PURE__ */ _(() => new ds(), "ValueConverter")
  }
};
function YR(t = At) {
  const e = ke(
    Et(t),
    Kt
  ), r = ke(
    vt({ shared: e }),
    $R,
    XR
  );
  return e.ServiceRegistry.register(r), { shared: e, Packet: r };
}
_(YR, "createPacketServices");
var JR = class extends Vt {
  static {
    _(this, "PieTokenBuilder");
  }
  constructor() {
    super(["pie", "showData"]);
  }
}, ZR = class extends yn {
  static {
    _(this, "PieValueConverter");
  }
  runCustomConverter(t, e, r) {
    if (t.name === "PIE_SECTION_LABEL")
      return e.replace(/"/g, "").trim();
  }
}, QR = {
  parser: {
    TokenBuilder: /* @__PURE__ */ _(() => new JR(), "TokenBuilder"),
    ValueConverter: /* @__PURE__ */ _(() => new ZR(), "ValueConverter")
  }
};
function ev(t = At) {
  const e = ke(
    Et(t),
    Kt
  ), r = ke(
    vt({ shared: e }),
    CR,
    QR
  );
  return e.ServiceRegistry.register(r), { shared: e, Pie: r };
}
_(ev, "createPieServices");
var tv = class extends yn {
  static {
    _(this, "TreeViewValueConverter");
  }
  runCustomConverter(t, e, r) {
    if (t.name === "INDENTATION")
      return e?.length || 0;
    if (t.name === "STRING2")
      return e.substring(1, e.length - 1);
  }
}, rv = class extends Vt {
  static {
    _(this, "TreeViewTokenBuilder");
  }
  constructor() {
    super(["treeView-beta"]);
  }
}, nv = {
  parser: {
    TokenBuilder: /* @__PURE__ */ _(() => new rv(), "TokenBuilder"),
    ValueConverter: /* @__PURE__ */ _(() => new tv(), "ValueConverter")
  }
};
function iv(t = At) {
  const e = ke(
    Et(t),
    Kt
  ), r = ke(
    vt({ shared: e }),
    wR,
    nv
  );
  return e.ServiceRegistry.register(r), { shared: e, TreeView: r };
}
_(iv, "createTreeViewServices");
var av = class extends Vt {
  static {
    _(this, "ArchitectureTokenBuilder");
  }
  constructor() {
    super(["architecture"]);
  }
}, sv = class extends yn {
  static {
    _(this, "ArchitectureValueConverter");
  }
  runCustomConverter(t, e, r) {
    if (t.name === "ARCH_ICON")
      return e.replace(/[()]/g, "").trim();
    if (t.name === "ARCH_TEXT_ICON")
      return e.replace(/["()]/g, "");
    if (t.name === "ARCH_TITLE") {
      let n = e.replace(/^\[|]$/g, "").trim();
      return (n.startsWith('"') && n.endsWith('"') || n.startsWith("'") && n.endsWith("'")) && (n = n.slice(1, -1), n = n.replace(/\\"/g, '"').replace(/\\'/g, "'")), n.trim();
    }
  }
}, ov = {
  parser: {
    TokenBuilder: /* @__PURE__ */ _(() => new av(), "TokenBuilder"),
    ValueConverter: /* @__PURE__ */ _(() => new sv(), "ValueConverter")
  }
};
function lv(t = At) {
  const e = ke(
    Et(t),
    Kt
  ), r = ke(
    vt({ shared: e }),
    vR,
    ov
  );
  return e.ServiceRegistry.register(r), { shared: e, Architecture: r };
}
_(lv, "createArchitectureServices");
var cv = class extends Vt {
  static {
    _(this, "RadarTokenBuilder");
  }
  constructor() {
    super(["radar-beta"]);
  }
}, uv = {
  parser: {
    TokenBuilder: /* @__PURE__ */ _(() => new cv(), "TokenBuilder"),
    ValueConverter: /* @__PURE__ */ _(() => new ds(), "ValueConverter")
  }
};
function fv(t = At) {
  const e = ke(
    Et(t),
    Kt
  ), r = ke(
    vt({ shared: e }),
    SR,
    uv
  );
  return e.ServiceRegistry.register(r), { shared: e, Radar: r };
}
_(fv, "createRadarServices");
var lt = {}, dv = {
  info: /* @__PURE__ */ _(async () => {
    const { createInfoServices: t } = await import("./info-OMHHGYJF-Urp_Ase5.js"), e = t().Info.parser.LangiumParser;
    lt.info = e;
  }, "info"),
  packet: /* @__PURE__ */ _(async () => {
    const { createPacketServices: t } = await import("./packet-4T2RLAQJ-CT04dID4.js"), e = t().Packet.parser.LangiumParser;
    lt.packet = e;
  }, "packet"),
  pie: /* @__PURE__ */ _(async () => {
    const { createPieServices: t } = await import("./pie-ZZUOXDRM-D01fyR4D.js"), e = t().Pie.parser.LangiumParser;
    lt.pie = e;
  }, "pie"),
  treeView: /* @__PURE__ */ _(async () => {
    const { createTreeViewServices: t } = await import("./treeView-SZITEDCU-BnPSNsii.js"), e = t().TreeView.parser.LangiumParser;
    lt.treeView = e;
  }, "treeView"),
  architecture: /* @__PURE__ */ _(async () => {
    const { createArchitectureServices: t } = await import("./architecture-YZFGNWBL-BifDOE8a.js"), e = t().Architecture.parser.LangiumParser;
    lt.architecture = e;
  }, "architecture"),
  gitGraph: /* @__PURE__ */ _(async () => {
    const { createGitGraphServices: t } = await import("./gitGraph-7Q5UKJZL-B_zctUCy.js"), e = t().GitGraph.parser.LangiumParser;
    lt.gitGraph = e;
  }, "gitGraph"),
  radar: /* @__PURE__ */ _(async () => {
    const { createRadarServices: t } = await import("./radar-PYXPWWZC-cZtFSkue.js"), e = t().Radar.parser.LangiumParser;
    lt.radar = e;
  }, "radar"),
  treemap: /* @__PURE__ */ _(async () => {
    const { createTreemapServices: t } = await import("./treemap-W4RFUUIX-DQbHtRSM.js"), e = t().Treemap.parser.LangiumParser;
    lt.treemap = e;
  }, "treemap"),
  wardley: /* @__PURE__ */ _(async () => {
    const { createWardleyServices: t } = await import("./wardley-RL74JXVD-DAdv8G0H.js"), e = t().Wardley.parser.LangiumParser;
    lt.wardley = e;
  }, "wardley")
};
async function hv(t, e) {
  const r = dv[t];
  if (!r)
    throw new Error(`Unknown diagram type: ${t}`);
  lt[t] || await r();
  const i = lt[t].parse(e);
  if (i.lexerErrors.length > 0 || i.parserErrors.length > 0)
    throw new pv(i);
  return i.value;
}
_(hv, "parse");
var pv = class extends Error {
  constructor(t) {
    const e = t.lexerErrors.map((n) => {
      const i = n.line !== void 0 && !isNaN(n.line) ? n.line : "?", a = n.column !== void 0 && !isNaN(n.column) ? n.column : "?";
      return `Lexer error on line ${i}, column ${a}: ${n.message}`;
    }).join(`
`), r = t.parserErrors.map((n) => {
      const i = n.token.startLine !== void 0 && !isNaN(n.token.startLine) ? n.token.startLine : "?", a = n.token.startColumn !== void 0 && !isNaN(n.token.startColumn) ? n.token.startColumn : "?";
      return `Parse error on line ${i}, column ${a}: ${n.message}`;
    }).join(`
`);
    super(`Parsing failed: ${e} ${r}`), this.result = t;
  }
  static {
    _(this, "MermaidParseError");
  }
};
export {
  ov as A,
  qR as G,
  KR as I,
  XR as P,
  uv as R,
  nv as T,
  jR as W,
  YR as a,
  ev as b,
  VR as c,
  QR as d,
  iv as e,
  lv as f,
  BR as g,
  fv as h,
  FR as i,
  MR as j,
  zR as k,
  hv as p
};
