(() => {
  "use strict";
  const core = window.AdminCore;
  const dealId = new URLSearchParams(location.search).get("id");
  let admin;
  let deal;
  let supplierDeal;
  let supplierError;

  init();
  async function init() {
    try {
      admin = await core.requireAuth();
      if (!admin) return;
      core.mountShell({ active: "deals", title: "Deal beoordelen", subtitle: "Controleer de aanbieding en leg je besluit zorgvuldig vast." }, admin);
      if (!dealId || !/^\d+$/.test(dealId)) throw new Error("Geen geldige deal geselecteerd.");
      await load();
    } catch (error) { showError(error.message); }
  }

  async function load() {
    const data = await core.request(`/deals/${encodeURIComponent(dealId)}`);
    deal = data?.deal || data;
    supplierDeal = null;
    supplierError = null;
    if (window.SeasonDealsAdminConfig.supplierDealsEnabled) {
      try {
        const supplier = await core.request(`/supplier-deals/${encodeURIComponent(dealId)}`);
        supplierDeal = supplier?.supplier_deal || null;
      } catch (error) { supplierError = error.message; }
    }
    render();
  }

  function render() {
    const target = document.getElementById("deal-detail");
    const hotel = deal.hotel || {};
    const image = core.imageUrl(deal.images);
    const inclusions = [["includes_breakfast", "Ontbijt"], ["includes_wifi", "Wifi"], ["includes_parking", "Parkeren"], ["includes_late_checkout", "Late check-out"], ["includes_welcome_drink", "Welkomstdrankje"]].filter(([field]) => deal[field]).map(([, text]) => `<span class="inclusion">✓ ${text}</span>`).join("");
    const environment = String(deal.integration_environment || "").toLowerCase();
    const isTestDeal = environment === "test";
    const reviewAllowed = core.canReview(admin) && deal.status === "pending_approval" && !supplierDeal && !supplierError;
    target.className = "detail-layout";
    target.innerHTML = `<article class="panel">${image ? `<img class="deal-hero" src="${core.escapeHtml(image)}" alt="${core.escapeHtml(deal.title || "Deal")}">` : '<div class="deal-hero deal-hero-placeholder">Geen afbeelding beschikbaar</div>'}<div class="deal-body"><div class="deal-title-row"><div><h2>${core.escapeHtml(deal.title || "Naamloze deal")}</h2><p class="hotel-line">${core.escapeHtml(hotel.name || deal.hotel_name || "Onbekend hotel")} · ${core.escapeHtml(hotel.city || deal.city || "")}</p></div>${core.statusBadge(deal.status)}</div><div class="fact-grid"><div class="fact"><span>Dealprijs</span><strong>${core.money(deal.price)}</strong></div><div class="fact"><span>Oorspronkelijke prijs</span><strong>${core.money(deal.original_price)}</strong></div><div class="fact"><span>Voorraad</span><strong>${core.escapeHtml(deal.inventory ?? 0)} beschikbaar</strong></div><div class="fact"><span>Verblijf</span><strong>${core.escapeHtml(deal.minimum_nights || 1)} nacht(en) · max. ${core.escapeHtml(deal.max_guests || 0)} gasten</strong></div><div class="fact"><span>Reisperiode</span><strong>${core.date(deal.travel_period_start)} – ${core.date(deal.travel_period_end)}</strong></div><div class="fact"><span>Ingediend</span><strong>${core.date(deal.submitted_at, true)}</strong></div></div>${inclusions ? `<div class="inclusion-list">${inclusions}</div>` : ""}<section class="deal-copy"><h3>Korte omschrijving</h3><p>${core.escapeHtml(deal.short_description || "Geen korte omschrijving.")}</p></section><section class="deal-copy"><h3>Uitgebreide omschrijving</h3><p>${core.escapeHtml(deal.long_description || "Geen uitgebreide omschrijving.")}</p></section><section class="deal-copy"><h3>Annuleringsvoorwaarden</h3><p>${core.escapeHtml(deal.cancellation_policy || "Niet opgegeven.")}</p></section></div></article><aside class="detail-sidebar"><section class="panel review-card"><span class="eyebrow">Beveiligde weergave</span><h3>Testpreview</h3><p class="notice">Bekijk deze deal in de nieuwe SeasonDeals-stijl. Boeken, betalen en voorraadwijzigingen zijn uitgeschakeld.</p><a class="secondary-button" href="../deal-preview.html?portal=admin&id=${encodeURIComponent(deal.id)}">Testpreview openen</a></section><section class="panel review-card"><span class="eyebrow">Beoordeling</span><h3>${reviewAllowed ? "Neem een besluit" : "Beoordelingsstatus"}</h3>${reviewAllowed ? `<label for="review-notes">Interne notitie (optioneel)</label><textarea id="review-notes" class="review-input" placeholder="Notitie voor het auditdossier"></textarea><label for="rejection-reason">Reden bij afwijzing</label><textarea id="rejection-reason" class="review-input" placeholder="Verplicht wanneer je de deal afwijst"></textarea><div class="review-actions"><button id="approve-deal" class="primary-button" type="button">Goedkeuren</button><button id="reject-deal" class="danger-button" type="button">Afwijzen</button></div>` : reviewSummary()}${!core.canReview(admin) && deal.status === "pending_approval" ? '<p class="notice">Je account mag deals bekijken, maar alleen superadmins en platformadmins kunnen besluiten nemen.</p>' : ""}</section><section class="panel review-card"><span class="eyebrow">Hotelpartner</span><h3>${core.escapeHtml(hotel.name || "Onbekend hotel")}</h3><div class="meta-list"><div class="meta-row"><span>Plaats</span><strong>${core.escapeHtml(hotel.city || "—")}</strong></div><div class="meta-row"><span>Land</span><strong>${core.escapeHtml(hotel.country || "—")}</strong></div><div class="meta-row"><span>E-mail</span><strong>${core.escapeHtml(hotel.email || "—")}</strong></div><div class="meta-row"><span>Telefoon</span><strong>${core.escapeHtml(hotel.phone || "—")}</strong></div><div class="meta-row"><span>Deal-ID</span><strong>#${core.escapeHtml(deal.id)}</strong></div></div></section></aside>`;
    const titleRow = target.querySelector(".deal-title-row");
    titleRow?.insertAdjacentHTML("beforeend", environmentBadge(environment));
    if (isTestDeal) {
      const reviewCard = target.querySelector(".review-card");
      reviewCard?.insertAdjacentHTML("afterbegin", '<p class="notice environment-warning"><strong>TESTDEAL</strong><br>Goedkeuren zet deze deal op Actief + Test. De deal blijft buiten de publieke website totdat je hem via Koppeling live zetten publiceert.</p>');
    }
    if (supplierDeal || supplierError) {
      const sidebar = target.querySelector(".detail-sidebar");
      sidebar?.insertAdjacentHTML("afterbegin", supplierPanel());
      target.querySelector(".deal-title-row .environment-badge")?.remove();
      titleRow?.insertAdjacentHTML("beforeend", '<span class="environment-badge environment-test">NUITÉE · ' + core.escapeHtml(supplierDeal?.environment || "ONBEKEND") + '</span>');
      document.getElementById("supplier-pricing")?.addEventListener("submit", saveSupplierPricing);
      document.getElementById("supplier-pricing")?.addEventListener("input", previewSupplierPrice);
      previewSupplierPrice();
    }
    document.getElementById("approve-deal")?.addEventListener("click", approve);
    document.getElementById("reject-deal")?.addEventListener("click", reject);
  }

  function reviewSummary() {
    if (supplierDeal || supplierError) return '<p class="notice">Nuitée-beoordeling wordt na de leverancierscontrole aangesloten. De conceptdeal blijft niet-publiek.</p>';
    if (deal.status === "rejected") return `<p class="notice"><strong>Afgewezen op ${core.date(deal.rejected_at, true)}</strong><br>${core.escapeHtml(deal.rejection_reason || "Geen reden opgeslagen.")}</p>${deal.review_notes ? `<div class="deal-copy"><h3>Interne notitie</h3><p>${core.escapeHtml(deal.review_notes)}</p></div>` : ""}`;
    if (deal.status === "active") {
      const visibility = String(deal.integration_environment || "").toLowerCase() === "test"
        ? "Deze deal is Actief + Test en blijft buiten de publieke website totdat je hem live zet."
        : "Deze deal is actief en zichtbaar voor bezoekers.";
      return `<p class="notice"><strong>Goedgekeurd op ${core.date(deal.approved_at, true)}</strong><br>${visibility}</p>${deal.review_notes ? `<div class="deal-copy"><h3>Interne notitie</h3><p>${core.escapeHtml(deal.review_notes)}</p></div>` : ""}`;
    }
    return `<p class="notice">Deze deal heeft status ${core.escapeHtml(core.statusLabel(deal.status))} en kan vanuit deze status niet worden goedgekeurd of afgewezen.</p>`;
  }
  function environmentBadge(environment) {
    if (!environment) return '<span class="environment-badge environment-manual">HANDMATIG</span>';
    return `<span class="environment-badge environment-${core.escapeHtml(environment)}">${environment === "production" ? "PRODUCTIE" : "TEST"}</span>`;
  }

  async function approve() {
    const isTestDeal = String(deal.integration_environment || "").toLowerCase() === "test";
    const question = isTestDeal
      ? `Weet je zeker dat je “${deal.title}” wilt goedkeuren als Actief + Test? De deal wordt nog niet publiek.`
      : `Weet je zeker dat je “${deal.title}” wilt goedkeuren en live wilt zetten?`;
    if (!confirm(question)) return;
    await updateStatus("active", isTestDeal ? "Testdeal goedgekeurd als Actief + Test." : "Deal goedgekeurd en geactiveerd.");
  }
  async function reject() {
    const reason = document.getElementById("rejection-reason").value.trim();
    if (!reason) { core.toast("Vul eerst een duidelijke reden voor afwijzing in.", "error"); document.getElementById("rejection-reason").focus(); return; }
    if (!confirm(`Weet je zeker dat je “${deal.title}” wilt afwijzen?`)) return;
    await updateStatus("rejected", "Deal afgewezen.", reason);
  }
  async function updateStatus(status, success, reason = null) {
    const buttons = [document.getElementById("approve-deal"), document.getElementById("reject-deal")];
    buttons.forEach((button) => { if (button) button.disabled = true; });
    const body = { status };
    const notes = document.getElementById("review-notes")?.value.trim();
    if (notes) body.review_notes = notes;
    if (reason) body.rejection_reason = reason;
    try {
      const response = await core.request(`/deals/${encodeURIComponent(dealId)}/status`, { method: "PATCH", body: JSON.stringify(body) });
      core.toast(response?.message || success);
      await load();
    } catch (error) { core.toast(error.message, "error"); buttons.forEach((button) => { if (button) button.disabled = false; }); }
  }

  function supplierPanel() {
    if (supplierError) return '<section class="panel review-card"><h3>Nuitée-gegevens niet beschikbaar</h3><p class="notice">' + core.escapeHtml(supplierError) + '</p><p>Beoordeling wacht totdat de leveranciersgegevens zijn opgehaald.</p></section>';
    const config = supplierDeal.pricing_config || {};
    const writable = core.canReview(admin) && deal.status === "draft";
    const numberInput = (key, label, fallback = 0) => `<label for="supplier-${key}">${label}</label><input id="supplier-${key}" name="${key}" class="review-input" type="number" min="0" step="0.01" value="${core.escapeHtml(config[key] ?? fallback)}" ${writable ? "" : "disabled"}>`;
    return `<section class="panel review-card"><span class="eyebrow">Nuitée-conceptdeal</span><h3>Prijs en marge</h3><p class="notice">De inkoopprijs is alleen-lezen. Dit is een prijsvoorbeeld; actuele kosten en beschikbaarheid worden bij het boeken opnieuw gecontroleerd.</p><div class="meta-list"><div class="meta-row"><span>Inkoopprijs</span><strong>${core.money(supplierDeal.supplier_base_amount)}</strong></div><div class="meta-row"><span>Leveranciershotel</span><strong>${core.escapeHtml(supplierDeal.supplier_hotel_id)}</strong></div><div class="meta-row"><span>Omgeving</span><strong>${core.escapeHtml(supplierDeal.environment)}</strong></div></div><form id="supplier-pricing"><label for="supplier-mode">Prijsregel</label><select id="supplier-mode" name="mode" class="review-input" ${writable ? "" : "disabled"}>${[["percentage","Opslag in procenten"],["fixed","Vaste opslag"],["override","Vaste verkoopprijs"]].map(([value,label])=>`<option value="${value}" ${(config.mode || "percentage")===value?"selected":""}>${label}</option>`).join("")}</select>${numberInput("markup_percentage","Opslag (%)")}${numberInput("markup_amount","Vaste opslag (€)")}${numberInput("override_amount","Vaste verkoopprijs (€)")}${numberInput("discount_percentage","Korting op berekende prijs (%)")}${numberInput("min_margin_amount","Minimummarge na kostenreserve (€)")}${numberInput("processing_fee","Nuitée-processingkosten (€)")}${numberInput("stripe_fee_percentage","Stripe-kostenreserve (%)",3)}${numberInput("stripe_fee_fixed","Stripe-kostenreserve vast (€)",0.25)}<label for="supplier-rounding">Afronding omhoog</label><select id="supplier-rounding" name="rounding" class="review-input" ${writable ? "" : "disabled"}>${[["none","Op centen"],["whole","Op hele euro"],["99","Op € …,99"]].map(([value,label])=>`<option value="${value}" ${(config.rounding || "none")===value?"selected":""}>${label}</option>`).join("")}</select><p id="supplier-price-preview" class="notice" aria-live="polite"></p>${writable ? '<button type="submit" class="primary-button">Prijsregels opslaan</button>' : '<p class="notice">Prijsregels kunnen alleen bij een conceptdeal door een bevoegde beheerder worden gewijzigd.</p>'}</form><p class="notice">Indienen en goedkeuren worden aangesloten nadat de leverancierscontrole is getest. Een sandboxdeal wordt niet gepubliceerd.</p></section>`;
  }
  function readSupplierPricing() {
    const form = document.getElementById("supplier-pricing");
    const config = {mode: form.elements.mode.value, rounding: form.elements.rounding.value};
    for (const key of ["markup_percentage","markup_amount","override_amount","discount_percentage","min_margin_amount","processing_fee","stripe_fee_percentage","stripe_fee_fixed"]) {
      config[key] = Number(form.elements[key].value);
      if (!Number.isFinite(config[key]) || config[key] < 0) throw new Error("Vul geldige positieve prijswaarden in.");
    }
    if (config.discount_percentage >= 100 || config.stripe_fee_percentage >= 100) throw new Error("Korting en kostenpercentage moeten lager zijn dan 100%.");
    return config;
  }
  function calculatePreview(config) {
    const base = Number(supplierDeal.supplier_base_amount);
    let amount = config.mode === "percentage" ? base * (1 + config.markup_percentage / 100) : config.mode === "fixed" ? base + config.markup_amount : config.override_amount;
    amount *= 1 - config.discount_percentage / 100;
    amount = config.rounding === "whole" ? Math.ceil(amount) : config.rounding === "99" ? Math.ceil(amount - .99) + .99 : Math.ceil(amount * 100) / 100;
    const estimatedMargin = amount - base - config.processing_fee - amount * config.stripe_fee_percentage / 100 - config.stripe_fee_fixed;
    if (amount <= 0 || estimatedMargin < config.min_margin_amount) throw new Error("De prijs haalt de ingestelde minimummarge na de kostenreserve niet.");
    return {amount, estimatedMargin};
  }
  function previewSupplierPrice() {
    const target = document.getElementById("supplier-price-preview");
    if (!target) return;
    try {
      const result = calculatePreview(readSupplierPricing());
      target.textContent = "Voorbeeld verkoopprijs: " + core.money(result.amount) + " · Geschatte marge na kostenreserve: " + core.money(result.estimatedMargin);
    } catch (error) { target.textContent = error.message; }
  }
  async function saveSupplierPricing(event) {
    event.preventDefault();
    const button = event.currentTarget.querySelector('button[type="submit"]');
    try {
      const pricing_config = readSupplierPricing();
      calculatePreview(pricing_config);
      button.disabled = true;
      await core.request(`/supplier-deals/${encodeURIComponent(dealId)}/pricing`, {method:"PATCH", body:JSON.stringify({pricing_config})});
      await load();
      core.toast("Prijsregels opgeslagen; deal blijft concept.");
    } catch (error) { core.toast(error.message, "error"); }
    finally { if (button?.isConnected) button.disabled = false; }
  }

  function showError(message) { const target = document.getElementById("deal-detail"); if (target) { target.className = "error-panel"; target.textContent = message; } }
})();
