var WippyLoading=(function(i){"use strict";const s={circle:'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 36 36"><circle cx="18" cy="26.06" r="1.33" fill="currentColor"/><path fill="currentColor" d="M18 22.61a1 1 0 0 1-1-1v-12a1 1 0 1 1 2 0v12a1 1 0 0 1-1 1"/><path fill="currentColor" d="M18 34a16 16 0 1 1 16-16a16 16 0 0 1-16 16m0-30a14 14 0 1 0 14 14A14 14 0 0 0 18 4"/></svg>',triangle:'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 36 36"><circle cx="18" cy="26.06" r="1.33" fill="currentColor"/><path fill="currentColor" d="M18 22.61a1 1 0 0 1-1-1v-12a1 1 0 1 1 2 0v12a1 1 0 0 1-1 1"/><path fill="currentColor" d="M15.062 1.681a3.221 3.221 0 0 1 5.647.002l13.89 25.56A3.22 3.22 0 0 1 31.77 32H4.022a3.22 3.22 0 0 1-2.9-4.759zM2.88 28.198A1.22 1.22 0 0 0 4 30h27.77a1.22 1.22 0 0 0 1.071-1.803L18.954 2.642a1.22 1.22 0 0 0-2.137-.001z"/></svg>',sad:'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 36 36"><path fill="currentColor" d="M18 2a16 16 0 1 0 16 16A16 16 0 0 0 18 2m0 30a14 14 0 1 1 14-14a14 14 0 0 1-14 14"/><circle cx="25.16" cy="14.28" r="1.8" fill="currentColor"/><circle cx="11.41" cy="14.28" r="1.8" fill="currentColor"/><path fill="currentColor" d="M18.16 20a9 9 0 0 0-7.33 3.78a1 1 0 1 0 1.63 1.16a7 7 0 0 1 11.31-.13a1 1 0 0 0 1.6-1.2A9 9 0 0 0 18.16 20"/></svg>'},g=`
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
`;class a extends HTMLElement{static observedAttributes=["title","message","icon","severity"];_iconEl=null;_titleEl=null;_messageEl=null;connectedCallback(){const t=this.shadowRoot??this.attachShadow({mode:"open"});t.textContent="";const n=document.createElement("style");n.textContent=g,t.appendChild(n);const e=document.createElement("div");e.className="container",this._iconEl=document.createElement("div"),this._iconEl.className="icon",this._iconEl.setAttribute("part","icon"),this._titleEl=document.createElement("div"),this._titleEl.className="title",this._titleEl.setAttribute("part","title"),this._messageEl=document.createElement("div"),this._messageEl.className="message",this._messageEl.setAttribute("part","message"),this._update(),e.append(this._iconEl,this._titleEl,this._messageEl),t.appendChild(e)}disconnectedCallback(){this._iconEl=null,this._titleEl=null,this._messageEl=null}attributeChangedCallback(){this._update()}_update(){if(this._iconEl){const t=this.getAttribute("icon")??"circle";this._iconEl.innerHTML=s[t]??s.circle}this._titleEl&&(this._titleEl.textContent=this.getAttribute("title")??"Something went wrong"),this._messageEl&&(this._messageEl.textContent=this.getAttribute("message")??"")}}const c=3e3,d=2e3,u=`
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
    animation: spin-outer ${c}ms linear infinite;
  }

  .ring.inner {
    width: 56px;
    height: 56px;
    top: 50%;
    left: 50%;
    border: 3px solid transparent;
    border-top-color: var(--p-primary, rgb(0, 95, 178));
    border-bottom-color: var(--p-primary, rgb(0, 95, 178));
    animation: spin-inner ${d}ms linear infinite;
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
`;class h extends HTMLElement{static observedAttributes=["title","subtitle"];_titleEl=null;_subtitleEl=null;connectedCallback(){const t=this.shadowRoot??this.attachShadow({mode:"open"});t.textContent="";const n=document.createElement("style");n.textContent=u,t.appendChild(n);const e=document.createElement("div");e.className="container";const o=document.createElement("div");o.className="spinner";const r=document.createElement("div");r.className="ring outer";const l=document.createElement("div");l.className="ring inner",o.append(r,l),this._titleEl=document.createElement("div"),this._titleEl.className="title",this._titleEl.setAttribute("part","title"),this._subtitleEl=document.createElement("div"),this._subtitleEl.className="subtitle",this._subtitleEl.setAttribute("part","subtitle"),this._updateText(),e.append(o,this._titleEl,this._subtitleEl),t.appendChild(e);const m=Date.now();r.style.animationDelay=`-${m%c}ms`,l.style.animationDelay=`-${m%d}ms`}disconnectedCallback(){this._titleEl=null,this._subtitleEl=null}attributeChangedCallback(){this._updateText()}_updateText(){this._titleEl&&(this._titleEl.textContent=this.getAttribute("title")??""),this._subtitleEl&&(this._subtitleEl.textContent=this.getAttribute("subtitle")??"")}}function p(){customElements.get("wippy-loading")||customElements.define("wippy-loading",h),customElements.get("wippy-error")||customElements.define("wippy-error",a)}return p(),i.WippyErrorElement=a,i.WippyLoadingElement=h,i.register=p,Object.defineProperty(i,Symbol.toStringTag,{value:"Module"}),i})({});
//# sourceMappingURL=loading.js.map
