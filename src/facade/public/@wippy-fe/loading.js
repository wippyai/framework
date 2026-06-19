var WippyLoading=(function(t){"use strict";var w=Object.defineProperty;var y=(t,i,r)=>i in t?w(t,i,{enumerable:!0,configurable:!0,writable:!0,value:r}):t[i]=r;var n=(t,i,r)=>y(t,typeof i!="symbol"?i+"":i,r);const p={circle:'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 36 36"><circle cx="18" cy="26.06" r="1.33" fill="currentColor"/><path fill="currentColor" d="M18 22.61a1 1 0 0 1-1-1v-12a1 1 0 1 1 2 0v12a1 1 0 0 1-1 1"/><path fill="currentColor" d="M18 34a16 16 0 1 1 16-16a16 16 0 0 1-16 16m0-30a14 14 0 1 0 14 14A14 14 0 0 0 18 4"/></svg>',triangle:'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 36 36"><circle cx="18" cy="26.06" r="1.33" fill="currentColor"/><path fill="currentColor" d="M18 22.61a1 1 0 0 1-1-1v-12a1 1 0 1 1 2 0v12a1 1 0 0 1-1 1"/><path fill="currentColor" d="M15.062 1.681a3.221 3.221 0 0 1 5.647.002l13.89 25.56A3.22 3.22 0 0 1 31.77 32H4.022a3.22 3.22 0 0 1-2.9-4.759zM2.88 28.198A1.22 1.22 0 0 0 4 30h27.77a1.22 1.22 0 0 0 1.071-1.803L18.954 2.642a1.22 1.22 0 0 0-2.137-.001z"/></svg>',sad:'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 36 36"><path fill="currentColor" d="M18 2a16 16 0 1 0 16 16A16 16 0 0 0 18 2m0 30a14 14 0 1 1 14-14a14 14 0 0 1-14 14"/><circle cx="25.16" cy="14.28" r="1.8" fill="currentColor"/><circle cx="11.41" cy="14.28" r="1.8" fill="currentColor"/><path fill="currentColor" d="M18.16 20a9 9 0 0 0-7.33 3.78a1 1 0 1 0 1.63 1.16a7 7 0 0 1 11.31-.13a1 1 0 0 0 1.6-1.2A9 9 0 0 0 18.16 20"/></svg>'},f=`
  *, *::before, *::after { box-sizing: border-box; }

  :host {
    display: block;
    width: 100%;
    height: 100%;
    min-height: 120px;
    overflow: hidden;
  }

  :host(:only-child) {
    height: 100vh;
    height: 100dvh;
  }

  :host([no-bg]) .container { background: transparent; }

  .container {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    width: 100%;
    height: 100%;
    /* content-background flips with both OS and a forced w-theme-* scope
       (inherited token), so the overlay follows a forced theme too. */
    background: var(--p-content-background, #fff);
    font-family: system-ui, -apple-system, sans-serif;
  }

  .icon {
    width: 48px;
    height: 48px;
    margin-bottom: 16px;
  }

  .icon svg {
    width: 100%;
    height: 100%;
  }

  :host([severity="warning"]) .icon,
  :host([severity="warning"]) .title {
    color: var(--p-warn-500, rgb(249, 115, 22));
  }

  :host(:not([severity="warning"])) .icon,
  :host(:not([severity="warning"])) .title {
    color: var(--p-danger-500, rgb(239, 68, 68));
  }

  .title {
    font-size: 16px;
    font-weight: 600;
    text-align: center;
    padding: 0 16px;
  }

  .title:empty { display: none; }

  .message {
    font-size: 13px;
    color: var(--p-text-muted-color, #71717a);
    margin-top: 6px;
    text-align: center;
    padding: 0 16px;
    max-width: 480px;
    line-height: 1.4;
  }

  .message:empty { display: none; }

  @media (prefers-color-scheme: dark) {
    :host([severity="warning"]) .icon,
    :host([severity="warning"]) .title {
      color: var(--p-warn-400, color-mix(in srgb, rgb(249, 115, 22) 40%, white));
    }
    :host(:not([severity="warning"])) .icon,
    :host(:not([severity="warning"])) .title {
      color: var(--p-danger-400, color-mix(in srgb, rgb(239, 68, 68) 40%, white));
    }
    .message {
      color: var(--p-text-muted-color, #a1a1aa);
    }
  }
`;class s extends HTMLElement{constructor(){super(...arguments);n(this,"_iconEl",null);n(this,"_titleEl",null);n(this,"_messageEl",null)}connectedCallback(){const e=this.shadowRoot??this.attachShadow({mode:"open"});e.textContent="";const l=document.createElement("style");l.textContent=f,e.appendChild(l);const o=document.createElement("div");o.className="container",this._iconEl=document.createElement("div"),this._iconEl.className="icon",this._iconEl.setAttribute("part","icon"),this._titleEl=document.createElement("div"),this._titleEl.className="title",this._titleEl.setAttribute("part","title"),this._messageEl=document.createElement("div"),this._messageEl.className="message",this._messageEl.setAttribute("part","message"),this._update(),o.append(this._iconEl,this._titleEl,this._messageEl),e.appendChild(o)}disconnectedCallback(){this._iconEl=null,this._titleEl=null,this._messageEl=null}attributeChangedCallback(){this._update()}_update(){if(this._iconEl){const e=this.getAttribute("icon")??"circle";this._iconEl.innerHTML=p[e]??p.circle}this._titleEl&&(this._titleEl.textContent=this.getAttribute("title")??"Something went wrong"),this._messageEl&&(this._messageEl.textContent=this.getAttribute("message")??"")}}n(s,"observedAttributes",["title","message","icon","severity"]);const m=3e3,g=2e3,E=`
  *, *::before, *::after { box-sizing: border-box; }

  :host {
    display: block;
    width: 100%;
    height: 100%;
    min-height: 120px;
    overflow: hidden;
  }

  :host(:only-child) {
    height: 100vh;
    height: 100dvh;
  }

  :host([no-bg]) .container { background: transparent; }

  .container {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    width: 100%;
    height: 100%;
    /* content-background flips with both OS and a forced w-theme-* scope
       (inherited token), so the overlay follows a forced theme too. */
    background: var(--p-content-background, #fff);
    font-family: system-ui, -apple-system, sans-serif;
  }

  .spinner {
    position: relative;
    width: 48px;
    height: 48px;
    margin-bottom: 16px;
  }

  .ring {
    position: absolute;
    border-radius: 50%;
    box-sizing: border-box;
  }

  .ring.outer {
    width: 48px;
    height: 48px;
    border: 3px solid var(--p-surface-300, #d4d4d8);
    animation: spin-outer ${m}ms linear infinite;
  }

  .ring.inner {
    width: 56px;
    height: 56px;
    top: 50%;
    left: 50%;
    border: 3px solid transparent;
    border-top-color: var(--p-primary, rgb(0, 95, 178));
    border-bottom-color: var(--p-primary, rgb(0, 95, 178));
    animation: spin-inner ${g}ms linear infinite;
  }

  .title {
    font-size: 14px;
    font-weight: 500;
    color: var(--p-text-color, #3f3f46);
    text-align: center;
    padding: 0 16px;
  }

  .title:empty { display: none; }

  .subtitle {
    font-size: 12px;
    color: var(--p-text-muted-color, #71717a);
    margin-top: 4px;
    text-align: center;
    padding: 0 16px;
  }

  .subtitle:empty { display: none; }

  @media (prefers-color-scheme: dark) {
    .ring.outer {
      border-color: var(--p-surface-500, #71717a);
    }
    .ring.inner {
      border-top-color: var(--p-primary, rgb(0, 125, 178));
      border-bottom-color: var(--p-primary, rgb(0, 125, 178));
    }
    .title {
      color: var(--p-text-color, #fff);
    }
    .subtitle {
      color: var(--p-text-muted-color, #a1a1aa);
    }
  }

  @keyframes spin-outer {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
  }

  @keyframes spin-inner {
    from { transform: translate(-50%, -50%) rotate(0deg); }
    to { transform: translate(-50%, -50%) rotate(-360deg); }
  }
`;class a extends HTMLElement{constructor(){super(...arguments);n(this,"_titleEl",null);n(this,"_subtitleEl",null)}connectedCallback(){const e=this.shadowRoot??this.attachShadow({mode:"open"});e.textContent="";const l=document.createElement("style");l.textContent=E,e.appendChild(l);const o=document.createElement("div");o.className="container";const c=document.createElement("div");c.className="spinner";const d=document.createElement("div");d.className="ring outer";const h=document.createElement("div");h.className="ring inner",c.append(d,h),this._titleEl=document.createElement("div"),this._titleEl.className="title",this._titleEl.setAttribute("part","title"),this._subtitleEl=document.createElement("div"),this._subtitleEl.className="subtitle",this._subtitleEl.setAttribute("part","subtitle"),this._updateText(),o.append(c,this._titleEl,this._subtitleEl),e.appendChild(o);const b=Date.now();d.style.animationDelay=`-${b%m}ms`,h.style.animationDelay=`-${b%g}ms`}disconnectedCallback(){this._titleEl=null,this._subtitleEl=null}attributeChangedCallback(){this._updateText()}_updateText(){this._titleEl&&(this._titleEl.textContent=this.getAttribute("title")??""),this._subtitleEl&&(this._subtitleEl.textContent=this.getAttribute("subtitle")??"")}}n(a,"observedAttributes",["title","subtitle"]);function u(){customElements.get("wippy-loading")||customElements.define("wippy-loading",a),customElements.get("wippy-error")||customElements.define("wippy-error",s)}return u(),t.WippyErrorElement=s,t.WippyLoadingElement=a,t.register=u,Object.defineProperty(t,Symbol.toStringTag,{value:"Module"}),t})({});
//# sourceMappingURL=loading.js.map
