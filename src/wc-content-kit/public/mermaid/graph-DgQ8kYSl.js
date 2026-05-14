import { aR as T, aS as C, aT as z, aU as R, aV as S, aW as k, aX as V, aY as L, aZ as K, a_ as j, a$ as ee, b0 as te, b1 as re, b2 as se, b3 as ne, b4 as ie, aH as ae, b5 as oe, b6 as ue, b7 as he, b8 as y, b9 as $, ba as v } from "./mermaid.core-Jw3znkh4.js";
import { k as d, g as Y, s as de, e as ce, f as fe, h as ge, j as le, d as be, l as _e, b as pe, m, n as g, r as ye } from "./_baseUniq-B0FPZyMQ.js";
function me(t, e) {
  return t && T(e, d(e), t);
}
function je(t, e) {
  return t && T(e, C(e), t);
}
function Te(t, e) {
  return T(t, Y(t), e);
}
var Oe = Object.getOwnPropertySymbols, H = Oe ? function(t) {
  for (var e = []; t; )
    ce(e, Y(t)), t = z(t);
  return e;
} : de;
function Ae(t, e) {
  return T(t, H(t), e);
}
function Ee(t) {
  return fe(t, C, H);
}
var Ce = Object.prototype, Le = Ce.hasOwnProperty;
function we(t) {
  var e = t.length, r = new t.constructor(e);
  return e && typeof t[0] == "string" && Le.call(t, "index") && (r.index = t.index, r.input = t.input), r;
}
function Ne(t, e) {
  var r = e ? R(t.buffer) : t.buffer;
  return new t.constructor(r, t.byteOffset, t.byteLength);
}
var Fe = /\w*$/;
function Pe(t) {
  var e = new t.constructor(t.source, Fe.exec(t));
  return e.lastIndex = t.lastIndex, e;
}
var I = S ? S.prototype : void 0, D = I ? I.valueOf : void 0;
function Se(t) {
  return D ? Object(D.call(t)) : {};
}
var $e = "[object Boolean]", ve = "[object Date]", Ie = "[object Map]", De = "[object Number]", Me = "[object RegExp]", Ue = "[object Set]", Ge = "[object String]", xe = "[object Symbol]", Be = "[object ArrayBuffer]", Re = "[object DataView]", Ve = "[object Float32Array]", Ke = "[object Float64Array]", Ye = "[object Int8Array]", He = "[object Int16Array]", We = "[object Int32Array]", qe = "[object Uint8Array]", Xe = "[object Uint8ClampedArray]", Ze = "[object Uint16Array]", Je = "[object Uint32Array]";
function Qe(t, e, r) {
  var s = t.constructor;
  switch (e) {
    case Be:
      return R(t);
    case $e:
    case ve:
      return new s(+t);
    case Re:
      return Ne(t, r);
    case Ve:
    case Ke:
    case Ye:
    case He:
    case We:
    case qe:
    case Xe:
    case Ze:
    case Je:
      return k(t, r);
    case Ie:
      return new s();
    case De:
    case Ge:
      return new s(t);
    case Me:
      return Pe(t);
    case Ue:
      return new s();
    case xe:
      return Se(t);
  }
}
var ze = "[object Map]";
function ke(t) {
  return V(t) && L(t) == ze;
}
var M = j && j.isMap, et = M ? K(M) : ke, tt = "[object Set]";
function rt(t) {
  return V(t) && L(t) == tt;
}
var U = j && j.isSet, st = U ? K(U) : rt, nt = 1, it = 2, at = 4, W = "[object Arguments]", ot = "[object Array]", ut = "[object Boolean]", ht = "[object Date]", dt = "[object Error]", q = "[object Function]", ct = "[object GeneratorFunction]", ft = "[object Map]", gt = "[object Number]", X = "[object Object]", lt = "[object RegExp]", bt = "[object Set]", _t = "[object String]", pt = "[object Symbol]", yt = "[object WeakMap]", mt = "[object ArrayBuffer]", jt = "[object DataView]", Tt = "[object Float32Array]", Ot = "[object Float64Array]", At = "[object Int8Array]", Et = "[object Int16Array]", Ct = "[object Int32Array]", Lt = "[object Uint8Array]", wt = "[object Uint8ClampedArray]", Nt = "[object Uint16Array]", Ft = "[object Uint32Array]", o = {};
o[W] = o[ot] = o[mt] = o[jt] = o[ut] = o[ht] = o[Tt] = o[Ot] = o[At] = o[Et] = o[Ct] = o[ft] = o[gt] = o[X] = o[lt] = o[bt] = o[_t] = o[pt] = o[Lt] = o[wt] = o[Nt] = o[Ft] = !0;
o[dt] = o[q] = o[yt] = !1;
function O(t, e, r, s, n, a) {
  var i, u = e & nt, h = e & it, J = e & at;
  if (i !== void 0)
    return i;
  if (!ee(t))
    return t;
  var w = ae(t);
  if (w) {
    if (i = we(t), !u)
      return te(t, i);
  } else {
    var b = L(t), N = b == q || b == ct;
    if (re(t))
      return se(t, u);
    if (b == X || b == W || N && !n) {
      if (i = h || N ? {} : ne(t), !u)
        return h ? Ae(t, je(i, t)) : Te(t, me(i, t));
    } else {
      if (!o[b])
        return n ? t : {};
      i = Qe(t, b, u);
    }
  }
  a || (a = new ie());
  var F = a.get(t);
  if (F)
    return F;
  a.set(t, i), st(t) ? t.forEach(function(c) {
    i.add(O(c, e, r, c, t, a));
  }) : et(t) && t.forEach(function(c, f) {
    i.set(f, O(c, e, r, f, t, a));
  });
  var Q = J ? h ? Ee : le : h ? C : d, P = w ? void 0 : Q(t);
  return ge(P || t, function(c, f) {
    P && (f = c, c = t[f]), oe(i, f, O(c, e, r, f, t, a));
  }), i;
}
function Pt(t, e) {
  return be(e, function(r) {
    return t[r];
  });
}
function A(t) {
  return t == null ? [] : Pt(t, d(t));
}
function _(t) {
  return t === void 0;
}
var St = ue(function(t) {
  return _e(pe(t, 1, he, !0));
}), $t = "\0", l = "\0", G = "";
class Z {
  /**
   * @param {GraphOptions} [opts] - Graph options.
   */
  constructor(e = {}) {
    this._isDirected = Object.prototype.hasOwnProperty.call(e, "directed") ? e.directed : !0, this._isMultigraph = Object.prototype.hasOwnProperty.call(e, "multigraph") ? e.multigraph : !1, this._isCompound = Object.prototype.hasOwnProperty.call(e, "compound") ? e.compound : !1, this._label = void 0, this._defaultNodeLabelFn = y(void 0), this._defaultEdgeLabelFn = y(void 0), this._nodes = {}, this._isCompound && (this._parent = {}, this._children = {}, this._children[l] = {}), this._in = {}, this._preds = {}, this._out = {}, this._sucs = {}, this._edgeObjs = {}, this._edgeLabels = {};
  }
  /* === Graph functions ========= */
  /**
   *
   * @returns {boolean} `true` if the graph is [directed](https://en.wikipedia.org/wiki/Directed_graph).
   * A directed graph treats the order of nodes in an edge as significant whereas an
   * [undirected](https://en.wikipedia.org/wiki/Graph_(mathematics)#Undirected_graph)
   * graph does not.
   * This example demonstrates the difference:
   *
   * @example
   *
   * ```js
   * var directed = new Graph({ directed: true });
   * directed.setEdge("a", "b", "my-label");
   * directed.edge("a", "b"); // returns "my-label"
   * directed.edge("b", "a"); // returns undefined
   *
   * var undirected = new Graph({ directed: false });
   * undirected.setEdge("a", "b", "my-label");
   * undirected.edge("a", "b"); // returns "my-label"
   * undirected.edge("b", "a"); // returns "my-label"
   * ```
   */
  isDirected() {
    return this._isDirected;
  }
  /**
   * @returns {boolean} `true` if the graph is a multigraph.
   */
  isMultigraph() {
    return this._isMultigraph;
  }
  /**
   * @returns {boolean} `true` if the graph is compound.
   */
  isCompound() {
    return this._isCompound;
  }
  /**
   * Sets the label for the graph to `label`.
   *
   * @param {GraphLabel} label - Label for the graph.
   * @returns {this}
   */
  setGraph(e) {
    return this._label = e, this;
  }
  /**
   * @returns {GraphLabel | undefined} the currently assigned label for the graph.
   * If no label has been assigned, returns `undefined`.
   *
   * @example
   *
   * ```js
   * var g = new Graph();
   * g.graph(); // returns undefined
   * g.setGraph("graph-label");
   *  g.graph(); // returns "graph-label"
   * ```
   */
  graph() {
    return this._label;
  }
  /* === Node functions ========== */
  /**
   * Sets a new default value that is assigned to nodes that are created without
   * a label.
   *
   * @param {typeof this._defaultNodeLabelFn | NodeLabel} newDefault - If a function,
   * it is called with the id of the node being created.
   * Otherwise, it is assigned as the label directly.
   * @returns {this}
   */
  setDefaultNodeLabel(e) {
    return $(e) || (e = y(e)), this._defaultNodeLabelFn = e, this;
  }
  /**
   * @returns {number} the number of nodes in the graph.
   */
  nodeCount() {
    return this._nodeCount;
  }
  /**
   * @returns {NodeID[]} the ids of the nodes in the graph.
   *
   * @remarks
   * Use {@link node()} to get the label for each node.
   * Takes `O(|V|)` time.
   */
  nodes() {
    return d(this._nodes);
  }
  /**
   * @returns {NodeID[]} those nodes in the graph that have no in-edges.
   * @remarks Takes `O(|V|)` time.
   */
  sources() {
    var e = this;
    return m(this.nodes(), function(r) {
      return v(e._in[r]);
    });
  }
  /**
   * @returns {NodeID[]} those nodes in the graph that have no out-edges.
   * @remarks Takes `O(|V|)` time.
   */
  sinks() {
    var e = this;
    return m(this.nodes(), function(r) {
      return v(e._out[r]);
    });
  }
  /**
   * Invokes setNode method for each node in `vs` list.
   *
   * @param {Collection<NodeID | number>} vs - List of node IDs to create/set.
   * @param {NodeLabel} [value] - If set, update all nodes with this value.
   * @returns {this}
   * @remarks Complexity: O(|names|).
   */
  setNodes(e, r) {
    var s = arguments, n = this;
    return g(e, function(a) {
      s.length > 1 ? n.setNode(a, r) : n.setNode(a);
    }), this;
  }
  /**
   * Creates or updates the value for the node `v` in the graph.
   *
   * @param {NodeID | number} v - ID of the node to create/set.
   * @param {NodeLabel} [value] - If supplied, it is set as the value for the node.
   * If not supplied and the node was created by this call then
   * {@link setDefaultNodeLabel} will be used to set the node's value.
   * @returns {this} the graph, allowing this to be chained with other functions.
   * @remarks Takes `O(1)` time.
   */
  setNode(e, r) {
    return Object.prototype.hasOwnProperty.call(this._nodes, e) ? (arguments.length > 1 && (this._nodes[e] = r), this) : (this._nodes[e] = arguments.length > 1 ? r : this._defaultNodeLabelFn(e), this._isCompound && (this._parent[e] = l, this._children[e] = {}, this._children[l][e] = !0), this._in[e] = {}, this._preds[e] = {}, this._out[e] = {}, this._sucs[e] = {}, ++this._nodeCount, this);
  }
  /**
   * Gets the label of node with specified name.
   *
   * @param {NodeID | number} v - Node ID.
   * @returns {NodeLabel | undefined} the label assigned to the node with the id `v`
   * if it is in the graph.
   * Otherwise returns `undefined`.
   * @remarks Takes `O(1)` time.
   */
  node(e) {
    return this._nodes[e];
  }
  /**
   * Detects whether graph has a node with specified name or not.
   *
   * @param {NodeID | number} v - Node ID.
   * @returns {boolean} Returns `true` the graph has a node with the id.
   * @remarks Takes `O(1)` time.
   */
  hasNode(e) {
    return Object.prototype.hasOwnProperty.call(this._nodes, e);
  }
  /**
   * Remove the node with the id `v` in the graph or do nothing if the node is
   * not in the graph.
   *
   * If the node was removed this function also removes any incident edges.
   *
   * @param {NodeID | number} v - Node ID to remove.
   * @returns {this} the graph, allowing this to be chained with other functions.
   * @remarks Takes `O(|E|)` time.
   */
  removeNode(e) {
    if (Object.prototype.hasOwnProperty.call(this._nodes, e)) {
      var r = (s) => this.removeEdge(this._edgeObjs[s]);
      delete this._nodes[e], this._isCompound && (this._removeFromParentsChildList(e), delete this._parent[e], g(this.children(e), (s) => {
        this.setParent(s);
      }), delete this._children[e]), g(d(this._in[e]), r), delete this._in[e], delete this._preds[e], g(d(this._out[e]), r), delete this._out[e], delete this._sucs[e], --this._nodeCount;
    }
    return this;
  }
  /**
   * Sets the parent for `v` to `parent` if it is defined or removes the parent
   * for `v` if `parent` is undefined.
   *
   * @param {NodeID | number} v - Node ID to set the parent for.
   * @param {NodeID | number} [parent] - Parent node ID. If not defined, removes the parent.
   * @returns {this} the graph, allowing this to be chained with other functions.
   * @throws if the graph is not compound.
   * @throws if setting the parent would create a cycle.
   * @remarks Takes `O(1)` time.
   */
  setParent(e, r) {
    if (!this._isCompound)
      throw new Error("Cannot set parent in a non-compound graph");
    if (_(r))
      r = l;
    else {
      r += "";
      for (var s = r; !_(s); s = this.parent(s))
        if (s === e)
          throw new Error("Setting " + r + " as parent of " + e + " would create a cycle");
      this.setNode(r);
    }
    return this.setNode(e), this._removeFromParentsChildList(e), this._parent[e] = r, this._children[r][e] = !0, this;
  }
  /**
   * @private
   * @param {NodeID | number} v - Node ID.
   */
  _removeFromParentsChildList(e) {
    delete this._children[this._parent[e]][e];
  }
  /**
   * Get parent node for node `v`.
   *
   * @param {NodeID | number} v - Node ID.
   * @returns {NodeID | undefined} the node that is a parent of node `v`
   * or `undefined` if node `v` does not have a parent or is not a member of
   * the graph.
   * Always returns `undefined` for graphs that are not compound.
   * @remarks Takes `O(1)` time.
   */
  parent(e) {
    if (this._isCompound) {
      var r = this._parent[e];
      if (r !== l)
        return r;
    }
  }
  /**
   * Gets list of direct children of node v.
   *
   * @param {NodeID | number} [v] - Node ID. If not specified, gets nodes
   * with no parent (top-level nodes).
   * @returns {NodeID[] | undefined} all nodes that are children of node `v` or
   * `undefined` if node `v` is not in the graph.
   * Always returns `[]` for graphs that are not compound.
   * @remarks Takes `O(|V|)` time.
   */
  children(e) {
    if (_(e) && (e = l), this._isCompound) {
      var r = this._children[e];
      if (r)
        return d(r);
    } else {
      if (e === l)
        return this.nodes();
      if (this.hasNode(e))
        return [];
    }
  }
  /**
   * @param {NodeID | number} v - Node ID.
   * @returns {NodeID[] | undefined} all nodes that are predecessors of the
   * specified node or `undefined` if node `v` is not in the graph.
   * @remarks
   * Behavior is undefined for undirected graphs - use {@link neighbors} instead.
   * Takes `O(|V|)` time.
   */
  predecessors(e) {
    var r = this._preds[e];
    if (r)
      return d(r);
  }
  /**
   * @param {NodeID | number} v - Node ID.
   * @returns {NodeID[] | undefined} all nodes that are successors of the
   * specified node or `undefined` if node `v` is not in the graph.
   * @remarks
   * Behavior is undefined for undirected graphs - use {@link neighbors} instead.
   * Takes `O(|V|)` time.
   */
  successors(e) {
    var r = this._sucs[e];
    if (r)
      return d(r);
  }
  /**
   * @param {NodeID | number} v - Node ID.
   * @returns {NodeID[] | undefined} all nodes that are predecessors or
   * successors of the specified node
   * or `undefined` if node `v` is not in the graph.
   * @remarks Takes `O(|V|)` time.
   */
  neighbors(e) {
    var r = this.predecessors(e);
    if (r)
      return St(r, this.successors(e));
  }
  /**
   * @param {NodeID | number} v - Node ID.
   * @returns {boolean} True if the node is a leaf (has no successors), false otherwise.
   */
  isLeaf(e) {
    var r;
    return this.isDirected() ? r = this.successors(e) : r = this.neighbors(e), r.length === 0;
  }
  /**
     * Creates new graph with nodes filtered via `filter`.
     * Edges incident to rejected node
     * are also removed.
     * 
     * In case of compound graph, if parent is rejected by `filter`,
     * than all its children are rejected too.
  
     * @param {(v: NodeID) => boolean} filter - Function that returns `true` for nodes to keep.
     * @returns {Graph<GraphLabel, NodeLabel, EdgeLabel>} A new graph containing only the nodes for which `filter` returns `true`.
     * @remarks Average-case complexity: O(|E|+|V|).
     */
  filterNodes(e) {
    var r = new this.constructor({
      directed: this._isDirected,
      multigraph: this._isMultigraph,
      compound: this._isCompound
    });
    r.setGraph(this.graph());
    var s = this;
    g(this._nodes, function(i, u) {
      e(u) && r.setNode(u, i);
    }), g(this._edgeObjs, function(i) {
      r.hasNode(i.v) && r.hasNode(i.w) && r.setEdge(i, s.edge(i));
    });
    var n = {};
    function a(i) {
      var u = s.parent(i);
      return u === void 0 || r.hasNode(u) ? (n[i] = u, u) : u in n ? n[u] : a(u);
    }
    return this._isCompound && g(r.nodes(), function(i) {
      r.setParent(i, a(i));
    }), r;
  }
  /* === Edge functions ========== */
  /**
   * Sets a new default value that is assigned to edges that are created without
   * a label.
   *
   * @param {typeof this._defaultEdgeLabelFn | EdgeLabel} newDefault - If a function,
   * it is called with the parameters `(v, w, name)`.
   * Otherwise, it is assigned as the label directly.
   * @returns {this}
   */
  setDefaultEdgeLabel(e) {
    return $(e) || (e = y(e)), this._defaultEdgeLabelFn = e, this;
  }
  /**
   * @returns {number} the number of edges in the graph.
   * @remarks Complexity: O(1).
   */
  edgeCount() {
    return this._edgeCount;
  }
  /**
   * Gets edges of the graph.
   *
   * @returns {EdgeObj[]} the {@link EdgeObj} for each edge in the graph.
   *
   * @remarks
   * In case of compound graph subgraphs are not considered.
   * Use {@link edge()} to get the label for each edge.
   * Takes `O(|E|)` time.
   */
  edges() {
    return A(this._edgeObjs);
  }
  /**
   * Establish an edges path over the nodes in nodes list.
   *
   * If some edge is already exists, it will update its label, otherwise it will
   * create an edge between pair of nodes with label provided or default label
   * if no label provided.
   *
   * @param {Collection<NodeID>} vs - List of node IDs to create edges between.
   * @param {EdgeLabel} [value] - If set, update all edges with this value.
   * @returns {this}
   * @remarks Complexity: O(|nodes|).
   */
  setPath(e, r) {
    var s = this, n = arguments;
    return ye(e, function(a, i) {
      return n.length > 1 ? s.setEdge(a, i, r) : s.setEdge(a, i), i;
    }), this;
  }
  /**
   * Creates or updates the label for the edge (`v`, `w`) with the optionally
   * supplied `name`.
   *
   * @overload
   * @param {EdgeObj} arg0 - Edge object.
   * @param {EdgeLabel} [value] - If supplied, it is set as the label for the edge.
   * If not supplied and the edge was created by this call then
   * {@link setDefaultEdgeLabel} will be used to assign the edge's label.
   * @returns {this} the graph, allowing this to be chained with other functions.
   * @remarks Takes `O(1)` time.
   */
  /**
   * Creates or updates the label for the edge (`v`, `w`) with the optionally
   * supplied `name`.
   *
   * @overload
   * @param {NodeID | number} v - Source node ID. Number values will be coerced to strings.
   * @param {NodeID | number} w - Target node ID. Number values will be coerced to strings.
   * @param {EdgeLabel} [value] - If supplied, it is set as the label for the edge.
   * If not supplied and the edge was created by this call then
   * {@link setDefaultEdgeLabel} will be used to assign the edge's label.
   * @param {string | number} [name] - Edge name. Only useful with multigraphs.
   * @returns {this} the graph, allowing this to be chained with other functions.
   * @remarks Takes `O(1)` time.
   */
  setEdge() {
    var e, r, s, n, a = !1, i = arguments[0];
    typeof i == "object" && i !== null && "v" in i ? (e = i.v, r = i.w, s = i.name, arguments.length === 2 && (n = arguments[1], a = !0)) : (e = i, r = arguments[1], s = arguments[3], arguments.length > 2 && (n = arguments[2], a = !0)), e = "" + e, r = "" + r, _(s) || (s = "" + s);
    var u = p(this._isDirected, e, r, s);
    if (Object.prototype.hasOwnProperty.call(this._edgeLabels, u))
      return a && (this._edgeLabels[u] = n), this;
    if (!_(s) && !this._isMultigraph)
      throw new Error("Cannot set a named edge when isMultigraph = false");
    this.setNode(e), this.setNode(r), this._edgeLabels[u] = a ? n : this._defaultEdgeLabelFn(e, r, s);
    var h = vt(this._isDirected, e, r, s);
    return e = h.v, r = h.w, Object.freeze(h), this._edgeObjs[u] = h, x(this._preds[r], e), x(this._sucs[e], r), this._in[r][u] = h, this._out[e][u] = h, this._edgeCount++, this;
  }
  /**
   * Gets the label for the specified edge.
   *
   * @overload
   * @param {EdgeObj} v - Edge object.
   * @returns {EdgeLabel | undefined} the label for the edge (`v`, `w`) if the
   * graph has an edge between `v` and `w` with the optional `name`.
   * Returned `undefined` if there is no such edge in the graph.
   * @remarks
   * `v` and `w` can be interchanged for undirected graphs.
   * Takes `O(1)` time.
   */
  /**
   * Gets the label for the specified edge.
   *
   * @overload
   * @param {NodeID | number} v - Source node ID.
   * @param {NodeID | number} w - Target node ID.
   * @param {string | number} [name] - Edge name. Only useful with multigraphs.
   * @returns {EdgeLabel | undefined} the label for the edge (`v`, `w`) if the
   * graph has an edge between `v` and `w` with the optional `name`.
   * Returned `undefined` if there is no such edge in the graph.
   * @remarks
   * `v` and `w` can be interchanged for undirected graphs.
   * Takes `O(1)` time.
   */
  edge(e, r, s) {
    var n = arguments.length === 1 ? E(this._isDirected, arguments[0]) : p(this._isDirected, e, r, s);
    return this._edgeLabels[n];
  }
  /**
   * Detects whether the graph contains specified edge or not.
   *
   * @overload
   * @param {EdgeObj} v - Edge object.
   * @returns {boolean} `true` if the graph has an edge between `v` and `w`
   * with the optional `name`.
   * @remarks
   * `v` and `w` can be interchanged for undirected graphs.
   * No subgraphs are considered.
   * Takes `O(1)` time.
   */
  /**
   * Detects whether the graph contains specified edge or not.
   *
   * @overload
   * @param {NodeID | number} v - Source node ID.
   * @param {NodeID | number} w - Target node ID.
   * @param {string | number} [name] - Edge name. Only useful with multigraphs.
   * @returns {boolean} `true` if the graph has an edge between `v` and `w`
   * with the optional `name`.
   * @remarks
   * `v` and `w` can be interchanged for undirected graphs.
   * No subgraphs are considered.
   * Takes `O(1)` time.
   */
  hasEdge(e, r, s) {
    var n = arguments.length === 1 ? E(this._isDirected, arguments[0]) : p(this._isDirected, e, r, s);
    return Object.prototype.hasOwnProperty.call(this._edgeLabels, n);
  }
  /**
   * Removes the edge (`v`, `w`) if the graph has an edge between `v` and `w`
   * with the optional `name`. If not this function does nothing.
   *
   * @overload
   * @param {EdgeObj} v - Edge object.
   * @returns {this}
   * @remarks
   * `v` and `w` can be interchanged for undirected graphs.
   * No subgraphs are considered.
   * Takes `O(1)` time.
   */
  /**
   * Removes the edge (`v`, `w`) if the graph has an edge between `v` and `w`
   * with the optional `name`. If not this function does nothing.
   *
   * @overload
   * @param {NodeID | number} v - Source node ID.
   * @param {NodeID | number} w - Target node ID.
   * @param {string | number} [name] - Edge name. Only useful with multigraphs.
   * @returns {this}
   * @remarks
   * `v` and `w` can be interchanged for undirected graphs.
   * Takes `O(1)` time.
   */
  removeEdge(e, r, s) {
    var n = arguments.length === 1 ? E(this._isDirected, arguments[0]) : p(this._isDirected, e, r, s), a = this._edgeObjs[n];
    return a && (e = a.v, r = a.w, delete this._edgeLabels[n], delete this._edgeObjs[n], B(this._preds[r], e), B(this._sucs[e], r), delete this._in[r][n], delete this._out[e][n], this._edgeCount--), this;
  }
  /**
   * @param {NodeID | number} v - Target node ID.
   * @param {NodeID | number} [u] - Optionally filters edges down to just those
   * coming from node `u`.
   * @returns {EdgeObj[] | undefined} all edges that point to the node `v`.
   * Returns `undefined` if node `v` is not in the graph.
   * @remarks
   * Behavior is undefined for undirected graphs - use {@link nodeEdges} instead.
   * Takes `O(|E|)` time.
   */
  inEdges(e, r) {
    var s = this._in[e];
    if (s) {
      var n = A(s);
      return r ? m(n, function(a) {
        return a.v === r;
      }) : n;
    }
  }
  /**
   * @param {NodeID | number} v - Target node ID.
   * @param {NodeID | number} [w] - Optionally filters edges down to just those
   * that point to `w`.
   * @returns {EdgeObj[] | undefined} all edges that point to the node `v`.
   * Returns `undefined` if node `v` is not in the graph.
   * @remarks
   * Behavior is undefined for undirected graphs - use {@link nodeEdges} instead.
   * Takes `O(|E|)` time.
   */
  outEdges(e, r) {
    var s = this._out[e];
    if (s) {
      var n = A(s);
      return r ? m(n, function(a) {
        return a.w === r;
      }) : n;
    }
  }
  /**
   * @param {NodeID | number} v - Target Node ID.
   * @param {NodeID | number} [w] - If set, filters those edges down to just
   * those between nodes `v` and `w` regardless of direction
   * @returns {EdgeObj[] | undefined} all edges to or from node `v` regardless
   * of direction. Returns `undefined` if node `v` is not in the graph.
   * @remarks Takes `O(|E|)` time.
   */
  nodeEdges(e, r) {
    var s = this.inEdges(e, r);
    if (s)
      return s.concat(this.outEdges(e, r));
  }
}
Z.prototype._nodeCount = 0;
Z.prototype._edgeCount = 0;
function x(t, e) {
  t[e] ? t[e]++ : t[e] = 1;
}
function B(t, e) {
  --t[e] || delete t[e];
}
function p(t, e, r, s) {
  var n = "" + e, a = "" + r;
  if (!t && n > a) {
    var i = n;
    n = a, a = i;
  }
  return n + G + a + G + (_(s) ? $t : s);
}
function vt(t, e, r, s) {
  var n = "" + e, a = "" + r;
  if (!t && n > a) {
    var i = n;
    n = a, a = i;
  }
  var u = { v: n, w: a };
  return s && (u.name = s), u;
}
function E(t, e) {
  return p(t, e.v, e.w, e.name);
}
export {
  Z as G,
  O as b,
  _ as i,
  A as v
};
