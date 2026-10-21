// Runs the fragment realm stub's inline register script (REGISTER_SCRIPT in
// src/views/api/fragment_bootstrap.lua) against the Web Host's import-map
// bootstrap helper, in a vm context with a minimal DOM.
//
// import-map-bootstrap-1.0.66.js is an unmodified copy of
// https://web-host.wippy.ai/webcomponents-1.0.66/@wippy-fe/import-map-bootstrap.js
// (sha256 9ee461687113825ccb3e8278b09227a28b437573ae8a986435f0911b6909dda9).
//
// Run: node --test js/fragment_stub.test.mjs (from src/views/test)
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { test } from 'node:test'
import vm from 'node:vm'

const LUA = readFileSync(new URL('../../api/fragment_bootstrap.lua', import.meta.url), 'utf8')
const START = 'local REGISTER_SCRIPT = [['
const from = LUA.indexOf(START) + START.length
const REGISTER = LUA.slice(from, LUA.indexOf(']]', from))
const HELPER = readFileSync(new URL('./import-map-bootstrap-1.0.66.js', import.meta.url), 'utf8')

const REALM = 'http://app.test/@fragment/probe/'
const PAGE = 'http://app.test/app/demo/'
const HOST_IMPORTS = { 'vue': 'https://cdn.test/vue.js', 'shared': 'https://cdn.test/host-shared.js' }
const PROXY = 'https://cdn.test/@wippy-fe/proxy-fragment.js'

class Element {
  constructor(doc, tag) {
    this.ownerDocument = doc
    this.tagName = tag.toUpperCase()
    this.attributes = new Map()
    this.children = []
    this.textContent = ''
  }

  setAttribute(name, value) { this.attributes.set(name, String(value)) }
  getAttribute(name) { return this.attributes.has(name) ? this.attributes.get(name) : null }
  get type() { return this.getAttribute('type') ?? '' }
  set type(value) { this.setAttribute('type', value) }
  get firstChild() { return this.children[0] ?? null }
  appendChild(child) { return this.insertBefore(child, null) }
  insertBefore(child, ref) {
    const at = ref ? this.children.indexOf(ref) : -1
    if (at < 0)
      this.children.push(child)
    else
      this.children.splice(at, 0, child)
    child.parentNode = this
    // A browser parses an import map when it is inserted, against the document
    // base URL at that moment.
    if (child.tagName === 'SCRIPT' && child.getAttribute('type') === 'importmap')
      child.registeredBase = this.ownerDocument.baseURI
    return child
  }

  removeChild(child) {
    const at = this.children.indexOf(child)
    assert.ok(at >= 0, 'removeChild gets a child of this element')
    this.children.splice(at, 1)
    child.parentNode = null
    return child
  }
}

// Resolve the addresses of a registered map as the browser does: URL-like
// addresses against the base URL at registration, absolute ones as written.
function browserResolved(map, base) {
  const addresses = (input) => {
    const out = Object.create(null)
    for (const [key, value] of Object.entries(input ?? {})) {
      const relative = value.startsWith('/') || value.startsWith('./') || value.startsWith('../')
      Object.defineProperty(out, key, { value: relative ? new URL(value, base).href : value, enumerable: true })
    }
    return out
  }
  const out = { imports: addresses(map.imports) }
  if (map.scopes) {
    out.scopes = Object.create(null)
    for (const [scope, entries] of Object.entries(map.scopes))
      out.scopes[scope] = addresses(entries)
  }
  return out
}

function makeDocument() {
  const doc = {}
  doc.documentElement = new Element(doc, 'html')
  doc.head = doc.documentElement.appendChild(new Element(doc, 'head'))
  doc.body = doc.documentElement.appendChild(new Element(doc, 'body'))
  const all = () => {
    const out = []
    const walk = (el) => { for (const c of el.children) { out.push(c); walk(c) } }
    walk(doc.documentElement)
    return out
  }
  // The first <base href> in tree order sets the document base URL.
  Object.defineProperty(doc, 'baseURI', {
    get() {
      const base = all().find(el => el.tagName === 'BASE' && el.getAttribute('href') !== null)
      return base ? new URL(base.getAttribute('href'), REALM).href : REALM
    },
  })
  doc.bases = () => all().filter(el => el.tagName === 'BASE')
  doc.createElement = tag => new Element(doc, tag)
  doc.getElementById = id => all().find(el => el.getAttribute('id') === id) ?? null
  doc.querySelector = (selector) => {
    assert.equal(selector, 'script[type="importmap"]')
    return all().find(el => el.tagName === 'SCRIPT' && el.getAttribute('type') === 'importmap') ?? null
  }
  doc.importMaps = () => all().filter(el => el.tagName === 'SCRIPT' && el.getAttribute('type') === 'importmap')
  doc.moduleScripts = () => all().filter(el => el.tagName === 'SCRIPT' && el.getAttribute('type') === 'module')
  doc.headOrder = () => doc.head.children.map(el => el.getAttribute('type') || el.tagName)
  doc.alerts = () => all().filter(el => el.getAttribute('role') === 'alert').map(el => el.textContent)
  return doc
}

// A same-origin ancestor window that carries a Host AppConfig.
function hostWindow(config, parent) {
  const win = { __WIPPY_APP_CONFIG__: config }
  win.parent = parent ?? win
  return win
}

function runStub({ pageMapText, pageBase = PAGE, parent, helper = true, hostImports = HOST_IMPORTS, onRegister } = {}) {
  const document = makeDocument()
  // The payload as build_stub writes it: absent fields are left out.
  const payload = document.createElement('script')
  payload.setAttribute('type', 'application/json')
  payload.setAttribute('id', 'wippy-fragment-bootstrap')
  payload.textContent = JSON.stringify({
    hostMap: { imports: hostImports },
    ...(pageMapText === undefined ? {} : { pageMapText }),
    ...(pageBase === null ? {} : { pageBase }),
    proxyUrl: PROXY,
  })
  document.head.appendChild(payload)
  const errors = []
  const window = {
    document,
    location: { href: REALM },
    console: { error: (...args) => errors.push(args.map(String).join(' ')) },
    URL,
  }
  window.window = window
  window.parent = parent ?? window
  const context = vm.createContext(window)
  if (helper) {
    vm.runInContext(HELPER, context)
    if (onRegister) {
      const register = window.WippyImportMapBootstrap.register
      window.WippyImportMapBootstrap.register = function (...args) {
        onRegister(document)
        return register.apply(this, args)
      }
    }
  }
  vm.runInContext(REGISTER, context)
  const maps = document.importMaps()
  const raw = maps.length ? JSON.parse(maps[0].textContent) : null
  return {
    maps,
    raw,
    map: raw ? browserResolved(raw, maps[0].registeredBase) : null,
    registeredBase: maps[0]?.registeredBase,
    proxies: document.moduleScripts().map(el => el.getAttribute('src')),
    headOrder: document.headOrder(),
    bases: document.bases(),
    baseAfter: document.baseURI,
    first: document.head.firstChild,
    alerts: document.alerts(),
    errors,
    ready: window.__WIPPY_IMPORT_MAP_READY__,
  }
}

async function rejection(promise) {
  assert.ok(promise && typeof promise.then === 'function', 'the ready promise is set')
  try {
    await promise
  }
  catch (error) {
    return error
  }
  assert.fail('the ready promise rejects')
}

test('composes page < Host < configured and resolves page addresses against the page URL', () => {
  const r = runStub({
    pageMapText: JSON.stringify({
      imports: { 'shared': './page-shared.js', 'local': './p.js', 'up': '../up.js', 'root': '/root.js', 'abs': 'https://x.test/a.js', './rel-key': './k.js' },
      scopes: { './sub/': { local: './sub-p.js' } },
    }),
    parent: hostWindow({ importMap: { imports: { shared: 'https://cfg.test/shared.js' } } }),
  })
  assert.equal(r.maps.length, 1)
  assert.equal(r.first.getAttribute('type'), 'importmap', 'the import map is the first <head> child')
  assert.deepEqual(r.alerts, [])
  assert.deepEqual(r.errors, [])
  assert.equal(r.ready, undefined)
  assert.equal(r.registeredBase, PAGE, 'the browser parses the map against the page URL')
  assert.deepEqual(r.bases, [], 'the temporary <base> is removed')
  assert.equal(r.baseAfter, REALM, 'the realm keeps its own URL afterwards')
  assert.equal(r.raw.imports.local, './p.js', 'register() gets the address as written')
  assert.deepEqual(r.proxies, [PROXY], 'the proxy loads once')
  assert.ok(r.headOrder.indexOf('importmap') < r.headOrder.indexOf('module'), 'the proxy loads after the map')
  const imports = r.map.imports
  assert.equal(imports.shared, 'https://cfg.test/shared.js')
  assert.equal(imports.vue, 'https://cdn.test/vue.js')
  assert.equal(imports.local, 'http://app.test/app/demo/p.js')
  assert.equal(imports.up, 'http://app.test/app/up.js')
  assert.equal(imports.root, 'http://app.test/root.js')
  assert.equal(imports.abs, 'https://x.test/a.js')
  assert.equal(imports['http://app.test/app/demo/rel-key'], 'http://app.test/app/demo/k.js')
  assert.deepEqual({ ...r.map.scopes['http://app.test/app/demo/sub/'] }, { local: 'http://app.test/app/demo/sub-p.js' })
})

test('resolves relative Host and configured addresses against the page URL, not the realm URL', () => {
  const r = runStub({
    pageBase: 'https://page.test/app/demo/',
    hostImports: { 'host-rel': './host.js' },
    parent: hostWindow({ importMap: { imports: { cfg: '/cfg.js', up: '../shared/x.js' } } }),
  })
  assert.equal(r.map.imports['host-rel'], 'https://page.test/app/demo/host.js')
  assert.equal(r.map.imports.cfg, 'https://page.test/cfg.js')
  assert.equal(r.map.imports.up, 'https://page.test/app/shared/x.js')
})

test('the Host map wins over the page map when the configured map is silent', () => {
  const r = runStub({
    pageMapText: JSON.stringify({ imports: { shared: './page-shared.js' } }),
    parent: hostWindow({ importMap: null }),
  })
  assert.equal(r.map.imports.shared, 'https://cdn.test/host-shared.js')
})

test('reads the nearest ancestor whose config has importMap', () => {
  const top = hostWindow({ importMap: { imports: { cfg: 'https://cfg.test/top.js' } } })
  const middle = hostWindow({ theme: 'dark' }, top)
  const r = runStub({ parent: middle })
  assert.equal(r.map.imports.cfg, 'https://cfg.test/top.js')
  assert.deepEqual(r.errors, [])
})

test('stops at a cross-origin ancestor and still registers the Host and page maps', () => {
  const crossOrigin = {}
  Object.defineProperty(crossOrigin, '__WIPPY_APP_CONFIG__', { get() { throw new Error('SecurityError') } })
  crossOrigin.parent = crossOrigin
  const r = runStub({ pageMapText: JSON.stringify({ imports: { local: './p.js' } }), parent: crossOrigin })
  assert.equal(r.map.imports.local, 'http://app.test/app/demo/p.js')
  assert.equal(r.map.imports.vue, 'https://cdn.test/vue.js')
  assert.equal(r.errors.length, 1)
  assert.match(r.errors[0], /no Wippy Host configuration is readable/)
  assert.equal(r.ready, undefined)
})

test('an unparseable page map registers nothing and rejects the ready promise', async () => {
  const r = runStub({ pageMapText: '{"imports":', parent: hostWindow({ importMap: null }) })
  assert.equal(r.maps.length, 0)
  assert.equal(r.alerts.length, 1)
  assert.match(r.alerts[0], /Failed to parse page import map/)
  assert.deepEqual(r.proxies, [], 'no proxy loads without a map')
  const error = await rejection(r.ready)
  assert.match(String(error.message), /Failed to parse page import map/)
})

test('maps the Host validator rejects reject the ready promise, as in the iframe engine', async () => {
  const cases = [
    [{ pageMapText: JSON.stringify({ imports: { bad: 'javascript:alert(1)' } }) }, /Invalid page import map/],
    [{ pageMapText: JSON.stringify({ imports: { bad: '/x\\y.js' } }) }, /Invalid page import map/],
    [{ pageMapText: JSON.stringify({ imports: { bad: './a\tb.js' } }) }, /Invalid page import map/],
    [{ pageMapText: JSON.stringify({ imports: { 'p/': './q/..' } }) }, /Invalid page import map/],
    [{ parent: hostWindow({ importMap: { imports: { bad: 'data:text/javascript,1' } } }) }, /Invalid AppConfig import map/],
  ]
  for (const [options, message] of cases) {
    const r = runStub({ parent: hostWindow({ importMap: null }), ...options })
    assert.equal(r.maps.length, 0)
    assert.deepEqual(r.proxies, [], 'no proxy loads without a map')
    const error = await rejection(r.ready)
    assert.match(String(error.message), message)
  }
})

test('addresses with surrounding whitespace are rejected as in the iframe engine, not cleaned', async () => {
  // Browsers strip trailing whitespace from a URL, but the Host validator
  // rejects such an address. The stub must not clean it before validation.
  for (const bad of ['./p.js ', ' ./p.js', './p.js\n', '/p.js ']) {
    const r = runStub({ pageMapText: JSON.stringify({ imports: { bad } }), parent: hostWindow({ importMap: null }) })
    assert.equal(r.maps.length, 0, JSON.stringify(bad))
    assert.deepEqual(r.proxies, [], 'no proxy loads without a map')
    const error = await rejection(r.ready)
    assert.match(String(error.message), /Invalid page import map/)
    assert.deepEqual(r.bases, [], 'the temporary <base> is removed after a failure')
  }
})

test('the page <base> exists only while register() runs', () => {
  const during = []
  const r = runStub({
    pageMapText: JSON.stringify({ imports: { local: './p.js' } }),
    parent: hostWindow({ importMap: null }),
    onRegister: document => during.push({ base: document.baseURI, count: document.bases().length }),
  })
  assert.deepEqual(during, [{ base: PAGE, count: 1 }])
  assert.deepEqual(r.bases, [])
  assert.equal(r.baseAfter, REALM)
  assert.equal(r.map.imports.local, 'http://app.test/app/demo/p.js')
})

test('a "__proto__" specifier stays an ordinary entry', () => {
  const r = runStub({
    pageMapText: '{"imports":{"__proto__":"./proto.js","ok":"./ok.js"}}',
    parent: hostWindow({ importMap: null }),
  })
  assert.equal(r.map.imports.ok, 'http://app.test/app/demo/ok.js')
  assert.equal(Object.getOwnPropertyDescriptor(r.map.imports, '__proto__')?.value, 'http://app.test/app/demo/proto.js')
})

test('falls back to the realm URL without a page base', () => {
  const r = runStub({ pageBase: null, pageMapText: JSON.stringify({ imports: { local: './p.js' } }), parent: hostWindow({ importMap: null }) })
  assert.equal(r.map.imports.local, 'http://app.test/@fragment/probe/p.js')
})

test('applies the Host map alone when the helper did not load', () => {
  const r = runStub({ helper: false, pageMapText: JSON.stringify({ imports: { local: './p.js' } }), parent: hostWindow({ importMap: null }) })
  assert.equal(r.maps.length, 1)
  assert.deepEqual(r.raw, { imports: HOST_IMPORTS })
  assert.deepEqual(r.proxies, [PROXY], 'the proxy still loads with the Host map')
  assert.ok(r.headOrder.indexOf('importmap') < r.headOrder.indexOf('module'), 'the proxy loads after the map')
  assert.equal(r.errors.length, 1)
  assert.match(r.errors[0], /bootstrap is unavailable/)
  assert.equal(r.ready, undefined)
})
