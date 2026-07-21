(() => {
  "use strict";
  const API = "https://xgrq-dkge-tace.n7e.xano.io/api:seasondeals-partner";
  const TOKEN_KEY = "sd_partner_token";
  const USER_KEY = "sd_partner_user";
  const page = document.body.dataset.partnerPage;
  const root = document.getElementById("sd-partner-app");
  let user = readUser();
  let currentPage = 1;
  let searchTimer;

  if (!sessionStorage.getItem(TOKEN_KEY)) return redirectToLogin();
  renderShell();
  bindShell();
  // Each page endpoint validates the bearer token itself. Loading directly
  // prevents a separate Xano /auth/me permission check from blocking the page.
  loadPage();

  function renderShell() {
    const labels = { bookings: ["Boekingen", "Bekijk reserveringen en betaalstatussen van jouw hotel."], vouchers: ["Vouchers", "Zoek vouchers en registreer het gebruik bij aankomst."], settings: ["Hotelinstellingen", "Beheer de gegevens die bij jouw hotelpartneraccount horen."] };
    const [title, subtitle] = labels[page] || ["Partnerportaal", "SeasonDeals"];
    root.innerHTML = `<div id="sd-mobile-overlay" class="sd-mobile-overlay"></div><aside id="sd-sidebar" class="sd-sidebar"><div class="sd-sidebar-top"><a href="index.html" class="sd-sidebar-logo" aria-label="SeasonDeals Partner Portal"><img src="https://cdn.prod.website-files.com/68cb0d808ea4f2467bb313af/6a48e006585299f4853fe7ea_Nieuw%20logo%20trans-p-500.png" alt="SeasonDeals"></a><button id="sd-sidebar-close" class="sd-sidebar-close" type="button" aria-label="Navigatie sluiten">×</button></div><div class="sd-hotel-card"><div id="sd-hotel-avatar" class="sd-hotel-avatar">H</div><div class="sd-hotel-copy"><strong id="sd-sidebar-hotel">Hotelpartner</strong><span id="sd-sidebar-role">Partner Portal</span></div></div><nav class="sd-navigation" aria-label="Partnernavigatie"><span class="sd-nav-label">Overzicht</span>${navLink("index.html","dashboard","Dashboard")}${navLink("deals.html","deals","Deals")}${navLink("bookings.html","bookings","Boekingen")}${navLink("vouchers.html","vouchers","Vouchers")}<span class="sd-nav-label sd-nav-label-secondary">Account</span>${navLink("settings.html","settings","Instellingen")}</nav><div class="sd-sidebar-footer"><button id="sd-sidebar-logout" class="sd-logout-button" type="button">Uitloggen</button><span class="sd-version">SeasonDeals Partner Portal</span></div></aside><div class="sd-app-main"><header class="sd-topbar"><div class="sd-topbar-left"><button id="sd-menu-toggle" class="sd-menu-toggle" type="button" aria-label="Menu openen">☰</button><div><span class="sd-topbar-label">Partner Portal</span><strong id="sd-topbar-hotel">Hotelpartner</strong></div></div><div class="sd-topbar-actions"><a class="sd-icon-button" href="index.html#sd-notifications-panel" aria-label="Notificaties">♢</a><div class="sd-user-menu-wrap"><button id="sd-user-menu-button" class="sd-user-button" type="button"><span id="sd-user-avatar" class="sd-user-avatar">P</span><span class="sd-user-button-copy"><strong id="sd-user-name">Partner</strong><small id="sd-user-role">Hotelpartner</small></span><span class="sd-chevron">⌄</span></button><div id="sd-user-dropdown" class="sd-user-dropdown"><div class="sd-dropdown-account"><strong id="sd-dropdown-name">Partner</strong><span id="sd-dropdown-email"></span></div><a href="settings.html" class="sd-dropdown-item">Accountinstellingen</a><button id="sd-dropdown-logout" class="sd-dropdown-item sd-dropdown-logout" type="button">Uitloggen</button></div></div></div></header><main class="sd-content"><section class="sd-page-header"><div><span class="sd-page-eyebrow">SeasonDeals partner</span><h1>${escapeHtml(title)}</h1><p>${escapeHtml(subtitle)}</p></div><div class="sd-page-header-actions"><button id="sd-page-refresh" class="sd-secondary-button" type="button">Vernieuwen</button></div></section><div id="sd-global-message" class="sd-global-message" role="alert"></div><div id="sd-page-content"><div class="sd-page-loading">Gegevens worden geladen…</div></div></main></div>`;
    renderUser();
  }

  function navLink(href, key, label) { return `<a href="${href}" class="sd-nav-item${page===key?" is-active":""}"><span aria-hidden="true">${({dashboard:"⌂",deals:"◇",bookings:"□",vouchers:"▱",settings:"⚙"})[key]}</span><span>${label}</span></a>`; }
  function bindShell() {
    const sidebar = document.getElementById("sd-sidebar"), overlay = document.getElementById("sd-mobile-overlay"), menu = document.getElementById("sd-user-dropdown");
    const close = () => { sidebar.classList.remove("is-open"); overlay.classList.remove("is-visible"); };
    document.getElementById("sd-menu-toggle").addEventListener("click",()=>{sidebar.classList.add("is-open");overlay.classList.add("is-visible");});
    document.getElementById("sd-sidebar-close").addEventListener("click",close);overlay.addEventListener("click",close);
    document.getElementById("sd-user-menu-button").addEventListener("click",e=>{e.stopPropagation();menu.classList.toggle("is-open");});document.addEventListener("click",()=>menu.classList.remove("is-open"));
    ["sd-sidebar-logout","sd-dropdown-logout"].forEach(id=>document.getElementById(id).addEventListener("click",logout));
    document.getElementById("sd-page-refresh").addEventListener("click",()=>loadPage());
  }

  async function verifySession() {
    const data = await request("/auth/me");
    const apiUser = data?.user || data?.hotel_user;
    const hotel = data?.hotel || apiUser?.hotel;
    user = { ...user, ...(apiUser && typeof apiUser === "object" ? apiUser : {}), ...(hotel && typeof hotel === "object" ? {hotel,hotel_name:hotel.name} : {}) };
    sessionStorage.setItem(USER_KEY, JSON.stringify(user));
    renderUser();
  }
  async function loadPage() {
    clearMessage();
    if (page === "bookings") return loadBookings();
    if (page === "vouchers") return loadVouchers();
    if (page === "settings") return loadSettings();
  }

  async function loadBookings() {
    const query = document.getElementById("sd-record-search")?.value.trim() || "";
    setLoading();
    try {
      const params = new URLSearchParams({ page: String(currentPage), per_page: "20" });
      if (query) params.set("search", query);
      const data = await request(`/bookings?${params.toString()}`);
      const items = resolveItems(data);
      content().innerHTML = `<section class="sd-data-panel"><div class="sd-data-toolbar"><label class="sd-search-field"><span>⌕</span><input id="sd-record-search" type="search" value="${escapeAttribute(query)}" placeholder="Zoek op boeking of klant"></label></div><div class="sd-table-wrap">${items.length?`<table class="sd-data-table"><thead><tr><th>Boeking</th><th>Deal</th><th>Verblijf</th><th>Bedrag</th><th>Status</th></tr></thead><tbody>${items.map(bookingRow).join("")}</tbody></table>`:empty("Geen boekingen gevonden","Nieuwe betaalde boekingen verschijnen hier automatisch.")}</div>${pagination(data)}</section>`;
      bindSearch(loadBookings);bindPagination(loadBookings);
    } catch (error) { showPageError(error); }
  }
  function bookingRow(item) {
    const status=item.payment_status||item.status||"pending", dates=[formatDate(item.checkin),formatDate(item.checkout)].filter(v=>v!=="—").join(" – ");
    return `<tr><td><strong>#${escapeHtml(item.id)}</strong><small>${formatDate(item.created_at,true)}</small></td><td><strong>Deal #${escapeHtml(item.deal_id||"—")}</strong><small>${escapeHtml(item.guests||1)} gast(en)</small></td><td>${escapeHtml(dates||"—")}</td><td><strong>${money(item.total_amount)}</strong><small>${escapeHtml((item.currency||"EUR").toUpperCase())}</small></td><td>${badge(status)}</td></tr>`;
  }

  async function loadVouchers() {
    const query=document.getElementById("sd-record-search")?.value.trim()||"", status=document.getElementById("sd-status-filter")?.value||"";
    setLoading();
    try {
      const data=await request(`/vouchers?search=${encodeURIComponent(query)}&redemption_status=${encodeURIComponent(status)}&page=${currentPage}&per_page=20`),items=resolveItems(data);
      content().innerHTML=`<section class="sd-data-panel"><div class="sd-data-toolbar"><label class="sd-search-field"><span>⌕</span><input id="sd-record-search" type="search" value="${escapeAttribute(query)}" placeholder="Zoek op vouchercode of e-mail"></label><select id="sd-status-filter"><option value="">Alle statussen</option>${["active","redeemed","expired","cancelled","refunded"].map(v=>`<option value="${v}"${v===status?" selected":""}>${label(v)}</option>`).join("")}</select></div><div class="sd-table-wrap">${items.length?`<table class="sd-data-table"><thead><tr><th>Voucher</th><th>Klant</th><th>Boeking</th><th>Geldig</th><th>Status</th><th></th></tr></thead><tbody>${items.map(voucherRow).join("")}</tbody></table>`:empty("Geen vouchers gevonden","Nieuwe vouchers verschijnen hier na een succesvolle betaling.")}</div>${pagination(data)}</section>`;
      bindSearch(loadVouchers);document.getElementById("sd-status-filter").addEventListener("change",()=>{currentPage=1;loadVouchers();});bindPagination(loadVouchers);document.querySelectorAll("[data-redeem]").forEach(button=>button.addEventListener("click",()=>redeemVoucher(button)));
    } catch(error){showPageError(error);}
  }
  function voucherRow(item){const status=item.redemption_status||item.status||"active";return `<tr><td><strong class="sd-code">${escapeHtml(item.code||`#${item.id}`)}</strong><small>Voucher #${escapeHtml(item.id)}</small></td><td><strong>${escapeHtml(item.customer_email||"—")}</strong></td><td><strong>Order #${escapeHtml(item.order_id||"—")}</strong><small>Deal #${escapeHtml(item.deal_id||"—")}</small></td><td>${formatDate(item.expires_at)}</td><td>${badge(status)}</td><td><button class="sd-redeem-button" type="button" data-redeem="${escapeAttribute(item.id)}" data-code="${escapeAttribute(item.code||item.id)}"${status!=="active"?" disabled":""}>Inwisselen</button></td></tr>`;}
  async function redeemVoucher(button){if(!confirm(`Voucher ${button.dataset.code} nu als gebruikt registreren?`))return;button.disabled=true;button.textContent="Bezig…";try{await request(`/vouchers/${encodeURIComponent(button.dataset.redeem)}/redeem`,{method:"POST"});showMessage("Voucher is succesvol ingewisseld.","info");await loadVouchers();}catch(error){showMessage(error.message,"error");button.disabled=false;button.textContent="Inwisselen";}}

  async function loadSettings(){setLoading();try{const data=await request("/hotel"),hotel=data?.hotel||data;content().innerHTML=`<div class="sd-settings-grid"><section class="sd-settings-card"><h2>Hotelprofiel</h2><p>Deze gegevens worden door SeasonDeals gebruikt voor jouw partneraccount.</p><form id="sd-settings-form" class="sd-settings-form"><label>Hotelnaam<input name="name" required value="${escapeAttribute(hotel.name)}"></label><label>E-mail<input name="email" type="email" value="${escapeAttribute(hotel.email)}"></label><label>Telefoon<input name="phone" value="${escapeAttribute(hotel.phone)}"></label><label>Website<input name="website" type="url" value="${escapeAttribute(hotel.website)}"></label><label class="full">Adres<input name="address" value="${escapeAttribute(hotel.address)}"></label><label>Check-in<input name="check_in_time" type="time" value="${escapeAttribute(hotel.check_in_time)}"></label><label>Check-out<input name="check_out_time" type="time" value="${escapeAttribute(hotel.check_out_time)}"></label><label class="full">Beschrijving<textarea name="description" rows="5">${escapeHtml(hotel.description||"")}</textarea></label><label class="full">Annuleringsvoorwaarden<textarea name="cancellation_policy" rows="4">${escapeHtml(hotel.cancellation_policy||"")}</textarea></label><div class="sd-settings-actions"><button id="sd-save-settings" class="sd-primary-button" type="submit">Instellingen opslaan</button></div></form></section><aside class="sd-settings-card"><h2>Account</h2><p>Jouw ingelogde partnerprofiel.</p><div class="sd-account-summary"><div class="sd-account-row"><span>Naam</span><strong>${escapeHtml(user.name||user.full_name||"Partner")}</strong></div><div class="sd-account-row"><span>E-mail</span><strong>${escapeHtml(user.email||"—")}</strong></div><div class="sd-account-row"><span>Rol</span><strong>${escapeHtml(label(user.role||"hotel partner"))}</strong></div><div class="sd-account-row"><span>Status hotel</span><strong>${escapeHtml(label(hotel.legal_status||"active"))}</strong></div><div class="sd-account-row"><span>Commissie</span><strong>${escapeHtml(hotel.commission_percentage??"—")}%</strong></div></div></aside></div>`;document.getElementById("sd-settings-form").addEventListener("submit",saveSettings);}catch(error){showPageError(error);}}
  async function saveSettings(event){event.preventDefault();const button=document.getElementById("sd-save-settings"),form=new FormData(event.currentTarget),body={};["name","email","phone","website","address","check_in_time","check_out_time","description","cancellation_policy"].forEach(key=>body[key]=String(form.get(key)||"").trim());button.disabled=true;button.textContent="Opslaan…";try{const saved=await request("/hotel",{method:"PATCH",body});user={...user,hotel:saved,hotel_name:saved.name||user.hotel_name};sessionStorage.setItem(USER_KEY,JSON.stringify(user));renderUser();showMessage("Hotelinstellingen zijn opgeslagen.","info");}catch(error){showMessage(error.message,"error");}finally{button.disabled=false;button.textContent="Instellingen opslaan";}}

  async function request(path,options={}){const token=sessionStorage.getItem(TOKEN_KEY);let response;try{response=await fetch(API+path,{method:options.method||"GET",mode:"cors",credentials:"omit",headers:{Accept:"application/json",Authorization:`Bearer ${token}`,...(options.body?{"Content-Type":"application/json"}:{}),...(options.headers||{})},body:options.body?JSON.stringify(options.body):undefined});}catch{throw new Error("De partnerservice is niet bereikbaar.");}const text=await response.text();let data={};try{data=text?JSON.parse(text):{};}catch{data={message:text};}if(response.status===401){logout();throw new Error("Je sessie is verlopen.");}if(!response.ok)throw new Error(data.message||data.error||data.detail||`Aanroep mislukt (${response.status}).`);return data;}
  function renderUser(){const name=user.name||user.full_name||"Partner",hotel=user.hotel_name||user.hotel?.name||"Hotelpartner",role=label(user.role||"hotel partner");setText("sd-sidebar-hotel",hotel);setText("sd-sidebar-role",role);setText("sd-topbar-hotel",hotel);setText("sd-user-name",name);setText("sd-user-role",role);setText("sd-dropdown-name",name);setText("sd-dropdown-email",user.email||"");setText("sd-user-avatar",initial(name));setText("sd-hotel-avatar",initial(hotel));}
  function bindSearch(loader){const input=document.getElementById("sd-record-search");input.addEventListener("input",()=>{clearTimeout(searchTimer);searchTimer=setTimeout(()=>{currentPage=1;loader();},350);});}
  function bindPagination(loader){document.querySelectorAll("[data-page]").forEach(button=>button.addEventListener("click",()=>{currentPage=Number(button.dataset.page);loader();}));}
  function pagination(data){const pageNo=Number(data.curPage||currentPage),pages=Number(data.pageTotal||1);return `<div class="sd-pagination"><span>Pagina ${pageNo} van ${Math.max(1,pages)} · ${Number(data.itemsTotal||resolveItems(data).length)} resultaten</span><div><button class="sd-secondary-button" type="button" data-page="${pageNo-1}"${pageNo<=1?" disabled":""}>Vorige</button><button class="sd-secondary-button" type="button" data-page="${pageNo+1}"${pageNo>=pages?" disabled":""}>Volgende</button></div></div>`;}
  function resolveItems(data){return [data,data?.items,data?.data,data?.data?.items,data?.result?.items].find(Array.isArray)||[];}
  function badge(value){const normalized=String(value||"").toLowerCase(),success=["paid","active","completed"].includes(normalized),warning=["pending","pending_payment","unpaid"].includes(normalized);return `<span class="sd-status ${success?"sd-status-success":warning?"sd-status-warning":"sd-status-neutral"}">${escapeHtml(label(normalized))}</span>`;}
  function empty(title,text){return `<div class="sd-table-empty"><strong>${escapeHtml(title)}</strong><span>${escapeHtml(text)}</span></div>`;}
  function content(){return document.getElementById("sd-page-content");}function setLoading(){content().innerHTML='<div class="sd-page-loading">Gegevens worden geladen…</div>';}
  function showPageError(error){content().innerHTML=empty("Gegevens konden niet worden geladen",error.message||"Probeer het opnieuw.");showMessage(error.message||"Aanroep mislukt.","error");}
  function showFatal(error){showPageError(error);}function showMessage(text,type){const el=document.getElementById("sd-global-message");el.textContent=text;el.className=`sd-global-message is-${type}`;}function clearMessage(){const el=document.getElementById("sd-global-message");el.textContent="";el.className="sd-global-message";}
  function readUser(){try{return JSON.parse(sessionStorage.getItem(USER_KEY)||"{}");}catch{return {};}}function logout(){sessionStorage.removeItem(TOKEN_KEY);sessionStorage.removeItem(USER_KEY);redirectToLogin();}function redirectToLogin(){location.replace("/seasondeals-partner-portal/login.html");}
  function money(value){return new Intl.NumberFormat("nl-NL",{style:"currency",currency:"EUR"}).format(Number(value)||0);}function formatDate(value,time=false){if(!value)return"—";const n=Number(value),date=Number.isFinite(n)?new Date(n<1e11?n*1000:n):new Date(value);return Number.isNaN(date.getTime())?"—":new Intl.DateTimeFormat("nl-NL",time?{dateStyle:"medium",timeStyle:"short"}:{dateStyle:"medium"}).format(date);}
  function label(value){return String(value||"").replace(/[_-]+/g," ").replace(/\b\w/g,c=>c.toUpperCase());}function initial(value){return String(value||"S").trim().charAt(0).toUpperCase();}function setText(id,value){const el=document.getElementById(id);if(el)el.textContent=value;}function escapeHtml(value){return String(value??"").replace(/[&<>'"]/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;","'":"&#39;",'"':"&quot;"})[c]);}function escapeAttribute(value){return escapeHtml(value??"").replace(/`/g,"&#96;");}
})();
