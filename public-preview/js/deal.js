(() => {
  "use strict";

  const CONFIG = Object.assign({
    dealsEndpoint: "https://xgrq-dkge-tace.n7e.xano.io/api:seasondeals-public/deals",
    checkoutEndpoint: "https://xgrq-dkge-tace.n7e.xano.io/api:seasondeals-public/create-checkout-session",
    homePage: "index.html",
    locale: "nl-NL",
    currency: "EUR"
  }, window.SEASONDEALS_CONFIG || {});
  const container = document.getElementById("deal-detail");
  const dealId = new URLSearchParams(window.location.search).get("id");
  let deal = null;
  let gallery = [];
  let activePhoto = 0;

  if (!dealId) return showError("Geen deal geselecteerd", "Open een deal via de SeasonDeals-homepage om alle informatie te bekijken.");
  loadDeal();

  async function loadDeal() {
    try {
      const response = await fetch(CONFIG.dealsEndpoint, { method: "GET", mode: "cors", credentials: "omit", headers: { Accept: "application/json" } });
      if (!response.ok) throw new Error(`De dealservice gaf status ${response.status}.`);
      const data = await response.json();
      deal = resolveDeals(data).find((item) => String(item?.id) === String(dealId));
      if (!deal || !isPublicDeal(deal)) return showError("Deze deal is niet beschikbaar", "De aanbieding is mogelijk afgelopen, uitverkocht of tijdelijk offline.");
      gallery = getImages(deal);
      renderDeal();
      bindDealEvents();
    } catch (error) {
      console.error("SeasonDeals detail failed:", error);
      showError("De deal kon niet worden geladen", "Controleer je internetverbinding of probeer het over een paar minuten opnieuw.");
    }
  }

  function renderDeal() {
    const title = text(deal.title || deal.name, "SeasonDeals deal");
    const hotel = text(deal.hotel_name || deal.hotel?.name, "SeasonDeals partner");
    const city = text(deal.city || deal.hotel?.city, "");
    const country = text(deal.country || deal.hotel?.country, "");
    const location = [city, country].filter(Boolean).join(", ");
    const price = number(deal.deal_price ?? deal.price) || 0;
    const original = number(deal.original_price) || price;
    const saving = original > price ? original - price : 0;
    const rating = number(deal.review_score ?? deal.hotel?.review_score);
    const reviews = number(deal.review_count ?? deal.hotel?.review_count);
    const amenities = getAmenities(deal);
    const remaining = getRemaining(deal);
    const maxGuests = Math.max(1, Math.min(20, number(deal.max_guests) || 10));
    const travelStart = toDate(deal.travel_period_start);
    const travelEnd = toDate(deal.travel_period_end);
    const mainDescription = text(deal.short_description || deal.description, "Ontdek deze bijzondere SeasonDeals-aanbieding en bekijk hieronder alles wat is inbegrepen.");
    const longDescription = text(deal.long_description, "");
    const policy = text(deal.cancellation_policy, "Controleer vóór het boeken altijd de voorwaarden van deze deal. Neem bij vragen contact op met SeasonDeals.");
    document.title = `${title} · SeasonDeals`;

    container.innerHTML = `<div class="detail-container">
      <nav class="detail-breadcrumbs" aria-label="Broodkruimel"><a href="${escapeAttribute(CONFIG.homePage)}">Home</a><span>›</span><a href="${escapeAttribute(CONFIG.homePage)}#deals">Deals</a><span>›</span><span>${escapeHtml(title)}</span></nav>
      ${renderGallery(title)}
      <header class="detail-heading"><div><span class="detail-kicker">${escapeHtml(formatCategory(getCategory(deal)))}${location ? ` · ${escapeHtml(location)}` : ""}</span><h1>${escapeHtml(title)}</h1><div class="detail-subline"><strong>${escapeHtml(hotel)}</strong>${rating > 0 ? `<span class="detail-rating">★ ${escapeHtml(formatDecimal(rating))}${reviews > 0 ? ` · ${escapeHtml(formatNumber(reviews))} beoordelingen` : ""}</span>` : ""}${deal.star_rating > 0 ? `<span>${"★".repeat(Math.min(5, Math.round(deal.star_rating)))} hotel</span>` : ""}${remaining !== null ? `<span class="detail-stock${remaining <= 5 ? " is-low" : ""}">● ${remaining === 0 ? "Uitverkocht" : `Actuele voorraad: ${formatNumber(remaining)}`}</span>` : ""}</div></div><div class="detail-heading-actions"><button class="detail-icon-button" id="share-deal" type="button" aria-label="Deal delen">↗</button><button class="detail-icon-button" id="save-deal" type="button" aria-label="Deal opslaan">♡</button></div></header>
      <div class="detail-layout"><article class="detail-content">
        <section><span class="detail-section-label">Over deze deal</span><h2>Een bijzonder moment voor een mooie prijs.</h2><p>${escapeHtml(mainDescription)}</p>${longDescription && longDescription !== mainDescription ? `<p class="detail-description-long">${formatText(longDescription)}</p>` : ""}</section>
        <section><span class="detail-section-label">Dit is inbegrepen</span><h2>Alles voor een zorgeloos verblijf.</h2><div class="amenities-grid">${amenities.length ? amenities.map(renderAmenity).join("") : `<div class="amenity"><span class="amenity-icon">◇</span><div><strong>Bekijk de dealvoorwaarden</strong><small>Alle inbegrepen onderdelen staan bij de aanbieding vermeld.</small></div></div>`}</div></section>
        <section><span class="detail-section-label">Geldigheid</span><h2>Plan jouw moment.</h2><div class="period-card"><div><span>Te gebruiken vanaf</span><strong>${travelStart ? formatDate(travelStart) : "Zie dealvoorwaarden"}</strong></div><div><span>Te gebruiken tot en met</span><strong>${travelEnd ? formatDate(travelEnd) : "Zie dealvoorwaarden"}</strong></div></div></section>
        <section><span class="detail-section-label">Annuleren en wijzigen</span><h2>Goed om vooraf te weten.</h2><div class="policy-card">${formatText(policy)}</div></section>
      </article>
      <aside class="booking-card" aria-label="Deal boeken"><div class="booking-price"><span>${original > price ? `<del>${escapeHtml(formatCurrency(original))}</del>` : ""}<strong>${escapeHtml(formatCurrency(price))}</strong><small>${deal.max_guests > 1 ? `voor maximaal ${formatNumber(deal.max_guests)} personen` : "per boeking"}</small></span>${saving > 0 ? `<span class="booking-save">Bespaar ${escapeHtml(formatCurrency(saving))}</span>` : ""}</div>
        <form id="booking-form" class="booking-form" novalidate><div class="booking-dates"><label>Check-in<input id="sd-checkin" name="checkin" type="date" required></label><label>Check-out<input id="sd-checkout" name="checkout" type="date" required></label></div><label>Aantal gasten<select id="sd-guests" name="guests">${Array.from({length:maxGuests},(_,i)=>`<option value="${i+1}">${i+1} ${i ? "gasten" : "gast"}</option>`).join("")}</select></label><div id="booking-message" class="booking-message" role="alert"></div><button id="sd-check-availability" class="button button-primary booking-submit" type="submit">Bekijk beschikbaarheid & boek <span>→</span></button></form>
        <div class="booking-assurances"><div><span>♢</span><p><strong>Veilig betalen via Stripe</strong><br>Je betaling wordt beveiligd verwerkt.</p></div><div><span>▱</span><p><strong>Direct je voucher</strong><br>Na betaling ontvang je de bevestiging per e-mail.</p></div><div><span>◇</span><p><strong>Transparante voorwaarden</strong><br>Geen onverwachte verplichte kosten achteraf.</p></div></div>${remaining !== null ? `<p class="availability${remaining <= 5 ? " is-low" : ""}"><span>●</span> Actuele voorraad: <strong>${formatNumber(remaining)} ${remaining === 1 ? "deal" : "deals"}</strong></p>` : ""}
      </aside></div>
    </div>${renderLightbox(title)}`;
    setDateLimits(travelStart, travelEnd);
  }

  function renderGallery(title) {
    if (!gallery.length) return `<div class="detail-gallery detail-gallery-single"><div class="detail-photo"><div class="detail-placeholder"><strong>SeasonDeals</strong><small>Hot offers, cool prices</small></div></div></div>`;
    const visible = gallery.slice(0, 3);
    return `<div class="detail-gallery${visible.length === 1 ? " detail-gallery-single" : ""}">${visible.map((url,index)=>`<button class="detail-photo" type="button" data-photo="${index}" aria-label="Foto ${index+1} van ${gallery.length} openen"><img src="${escapeAttribute(url)}" alt="${escapeAttribute(title)}${index ? `, foto ${index+1}` : ""}"><span class="detail-photo-overlay"></span>${index === visible.length-1 && gallery.length > 1 ? `<span class="gallery-count">▦ Bekijk alle ${gallery.length} foto’s</span>` : ""}</button>`).join("")}</div>`;
  }

  function renderLightbox(title) { return gallery.length ? `<div id="deal-lightbox" class="lightbox" role="dialog" aria-modal="true" aria-label="Fotogalerij"><button class="lightbox-close" type="button" aria-label="Sluiten">×</button><button class="lightbox-nav lightbox-prev" type="button" aria-label="Vorige foto">‹</button><img id="lightbox-image" src="${escapeAttribute(gallery[0])}" alt="${escapeAttribute(title)}"><button class="lightbox-nav lightbox-next" type="button" aria-label="Volgende foto">›</button><span id="lightbox-counter" class="lightbox-counter">1 / ${gallery.length}</span></div>` : ""; }

  function bindDealEvents() {
    document.querySelectorAll("[data-photo]").forEach((button) => button.addEventListener("click", () => openPhoto(number(button.dataset.photo) || 0)));
    document.querySelector(".lightbox-close")?.addEventListener("click", closePhoto);
    document.querySelector(".lightbox-prev")?.addEventListener("click", () => movePhoto(-1));
    document.querySelector(".lightbox-next")?.addEventListener("click", () => movePhoto(1));
    document.getElementById("deal-lightbox")?.addEventListener("click", (event) => { if (event.target.id === "deal-lightbox") closePhoto(); });
    document.addEventListener("keydown", handleKeyboard);
    document.getElementById("booking-form")?.addEventListener("submit", startCheckout);
    document.getElementById("share-deal")?.addEventListener("click", shareDeal);
    document.getElementById("save-deal")?.addEventListener("click", () => showToast("Deze favorietenfunctie koppelen we later aan je account."));
  }

  async function startCheckout(event) {
    event.preventDefault();
    const checkin = document.getElementById("sd-checkin").value;
    const checkout = document.getElementById("sd-checkout").value;
    const guests = Number(document.getElementById("sd-guests").value || 1);
    if (!checkin || !checkout) return showBookingMessage("Kies eerst een geldige check-in- en check-outdatum.", "error");
    if (new Date(`${checkout}T00:00:00`) <= new Date(`${checkin}T00:00:00`)) return showBookingMessage("De check-outdatum moet na de check-indatum liggen.", "error");
    const button = document.getElementById("sd-check-availability");
    button.disabled = true; button.innerHTML = "Je wordt doorgestuurd…";
    showBookingMessage("Je wordt doorgestuurd naar de beveiligde betaalpagina…", "info");
    try {
      const response = await fetch(CONFIG.checkoutEndpoint, { method: "POST", mode: "cors", credentials: "omit", headers: { Accept: "application/json", "Content-Type": "application/json" }, body: JSON.stringify({ deal_id: deal.id, checkin, checkout, guests }) });
      const responseText = await response.text();
      let data = {}; try { data = responseText ? JSON.parse(responseText) : {}; } catch { data = { message: responseText }; }
      if (!response.ok) throw new Error(data?.message || data?.error || data?.detail || `Boeken is niet gelukt (${response.status}).`);
      const checkoutUrl = data?.checkout_url || data?.url || data?.session_url || data?.session?.url || data?.api1?.response?.url || data?.api1?.response?.result?.url;
      if (!checkoutUrl) throw new Error("De betaalpagina kon niet worden geopend. Probeer het opnieuw.");
      window.location.href = checkoutUrl;
    } catch (error) {
      console.error("SeasonDeals checkout failed:", error);
      showBookingMessage(error.message || "Boeken is nu niet mogelijk. Probeer het opnieuw.", "error");
      button.disabled = false; button.innerHTML = "Bekijk beschikbaarheid & boek <span>→</span>";
    }
  }

  function setDateLimits(start, end) {
    const checkin = document.getElementById("sd-checkin"), checkout = document.getElementById("sd-checkout");
    if (!checkin || !checkout) return;
    const today = new Date(); today.setHours(0,0,0,0);
    const min = start && start > today ? start : today;
    const minValue = inputDate(min); checkin.min = minValue; checkout.min = minValue;
    if (end) { const maxValue = inputDate(end); checkin.max = maxValue; checkout.max = maxValue; }
    checkin.addEventListener("change", () => { checkout.min = checkin.value || minValue; if (checkout.value && checkout.value <= checkin.value) checkout.value = ""; });
  }

  function openPhoto(index) { if (!gallery.length) return; activePhoto = index; updateLightbox(); document.getElementById("deal-lightbox")?.classList.add("is-open"); document.body.style.overflow = "hidden"; }
  function closePhoto() { document.getElementById("deal-lightbox")?.classList.remove("is-open"); document.body.style.overflow = ""; }
  function movePhoto(step) { activePhoto = (activePhoto + step + gallery.length) % gallery.length; updateLightbox(); }
  function updateLightbox() { const image=document.getElementById("lightbox-image"),counter=document.getElementById("lightbox-counter"); if(image) image.src=gallery[activePhoto]; if(counter) counter.textContent=`${activePhoto+1} / ${gallery.length}`; }
  function handleKeyboard(event) { if (!document.getElementById("deal-lightbox")?.classList.contains("is-open")) return; if(event.key==="Escape") closePhoto(); if(event.key==="ArrowRight") movePhoto(1); if(event.key==="ArrowLeft") movePhoto(-1); }
  async function shareDeal() { try { if(navigator.share) await navigator.share({title:deal.title,text:"Bekijk deze deal bij SeasonDeals",url:location.href}); else { await navigator.clipboard.writeText(location.href); showToast("De link naar deze deal is gekopieerd."); } } catch(error) { if(error?.name!=="AbortError") showToast("Kopieer de link uit je adresbalk om deze deal te delen."); } }

  function resolveDeals(data) { return [data,data?.items,data?.deals,data?.records,data?.data,data?.data?.items,data?.result,data?.result?.items].find(Array.isArray)||[]; }
  function isPublicDeal(item) { const status=String(item?.status||"").toLowerCase(); return (status==="active"||item?.is_active===true)&&(item?.deleted_at===0||item?.deleted_at===null||item?.deleted_at===undefined); }
  function getImages(item) { const values=[...(Array.isArray(item.images)?item.images:[]),item.image,item.cover_image,item.image_url]; return [...new Set(values.map((value)=>typeof value==="string"?value:value?.url).filter(Boolean))]; }
  function getAmenities(item) { return [[item.includes_breakfast,"☕","Ontbijt inbegrepen","Begin de dag ontspannen"],[item.includes_wifi,"⌁","Wifi inbegrepen","Blijf zorgeloos verbonden"],[item.includes_parking,"P","Parkeren inbegrepen","Comfortabel aankomen"],[item.includes_late_checkout,"◷","Late check-out","Nog iets langer genieten"],[item.includes_welcome_drink,"◇","Welkomstdrankje","Een warm welkom"]].filter(([active])=>active); }
  function renderAmenity([,icon,title,subtitle]) { return `<div class="amenity"><span class="amenity-icon">${icon}</span><div><strong>${escapeHtml(title)}</strong><small>${escapeHtml(subtitle)}</small></div></div>`; }
  function getRemaining(item) { const direct=number(item.remaining_inventory??item.available_quantity??item.inventory); return direct===null?null:Math.max(0,direct); }
  function getCategory(item) { const raw=[item.category_slug,item.category?.slug,item.category?.name,item.category,item.deal_type,item.package_type,item.type].filter(v=>typeof v==="string").join(" ").toLowerCase(); if(/wellness|spa|sauna/.test(raw))return"wellness";if(/massage|beauty|behandeling/.test(raw))return"massage";if(/ticket|event|concert|festival/.test(raw))return"tickets";if(/attract|uitje|park|museum|activiteit/.test(raw))return"attraction";return"hotel"; }
  function formatCategory(value){return({hotel:"Hotel",wellness:"Wellness",massage:"Massage",tickets:"Tickets",attraction:"Attractie"})[value]||"Deal";}
  function toDate(value){if(!value)return null;const raw=Number(value);const date=Number.isFinite(raw)?new Date(raw<1e11?raw*1000:raw):new Date(value);return Number.isNaN(date.getTime())?null:date;}
  function inputDate(date){return `${date.getFullYear()}-${String(date.getMonth()+1).padStart(2,"0")}-${String(date.getDate()).padStart(2,"0")}`;}
  function formatDate(date){return new Intl.DateTimeFormat(CONFIG.locale,{day:"numeric",month:"long",year:"numeric"}).format(date);}
  function formatCurrency(value){return new Intl.NumberFormat(CONFIG.locale,{style:"currency",currency:CONFIG.currency,maximumFractionDigits:2}).format(value||0);}
  function formatNumber(value){return new Intl.NumberFormat(CONFIG.locale,{maximumFractionDigits:0}).format(value||0);}
  function formatDecimal(value){return new Intl.NumberFormat(CONFIG.locale,{minimumFractionDigits:1,maximumFractionDigits:1}).format(value||0);}
  function number(value){const result=typeof value==="string"?Number(value.replace(",",".")):value;return Number.isFinite(result)?result:null;}
  function text(value,fallback){return value===null||value===undefined||String(value).trim()===""?fallback:String(value);}
  function formatText(value){return escapeHtml(value).replace(/\n/g,"<br>");}
  function escapeHtml(value){return String(value??"").replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;").replace(/'/g,"&#039;");}
  function escapeAttribute(value){return escapeHtml(value).replace(/`/g,"&#096;");}
  function showBookingMessage(value,type){const el=document.getElementById("booking-message");if(!el)return;el.textContent=value;el.className=`booking-message is-visible is-${type}`;}
  function showToast(value){const toast=document.getElementById("preview-toast");if(!toast)return;toast.textContent=value;toast.classList.add("is-visible");clearTimeout(showToast.timer);showToast.timer=setTimeout(()=>toast.classList.remove("is-visible"),3500);}
  function showError(title,message){container.innerHTML=`<section class="detail-error"><span>!</span><h1>${escapeHtml(title)}</h1><p>${escapeHtml(message)}</p><a class="button button-primary" href="${escapeAttribute(CONFIG.homePage)}#deals">Terug naar alle deals <span>→</span></a></section>`;}
})();
