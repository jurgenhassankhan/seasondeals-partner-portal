(() => {
  "use strict";

  const CONFIG = {
    dealsEndpoint: "https://xgrq-dkge-tace.n7e.xano.io/api:seasondeals-public/deals",
    dealPage: "deal.html",
    locale: "nl-NL",
    currency: "EUR"
  };

  const grid = document.getElementById("deal-grid");
  const message = document.getElementById("deals-message");
  const chips = [...document.querySelectorAll(".filter-chip")];
  const menu = document.getElementById("main-nav");
  const menuToggle = document.getElementById("menu-toggle");
  let deals = [];
  let activeFilter = "all";
  let locationQuery = "";

  bindNavigation();
  bindPreviewControls();
  if (grid) {
    bindDealControls();
    loadDeals();
  }

  function bindNavigation() {
    menuToggle?.addEventListener("click", () => {
      const open = menu.classList.toggle("is-open");
      menuToggle.classList.toggle("is-open", open);
      menuToggle.setAttribute("aria-expanded", String(open));
    });
    menu?.querySelectorAll("a").forEach((link) => link.addEventListener("click", () => {
      menu.classList.remove("is-open");
      menuToggle.classList.remove("is-open");
      menuToggle.setAttribute("aria-expanded", "false");
    }));
  }

  function bindDealControls() {
    chips.forEach((chip) => chip.addEventListener("click", () => {
      activeFilter = chip.dataset.filter || "all";
      updateActiveChip();
      renderDeals();
    }));

    document.querySelectorAll("[data-filter-link]").forEach((link) => link.addEventListener("click", () => {
      activeFilter = link.dataset.filterLink || "all";
      const select = document.getElementById("search-category");
      if (select) select.value = activeFilter;
      updateActiveChip();
      renderDeals();
    }));

    document.getElementById("deal-search")?.addEventListener("submit", (event) => {
      event.preventDefault();
      activeFilter = document.getElementById("search-category")?.value || "all";
      locationQuery = document.getElementById("search-location")?.value.trim().toLocaleLowerCase("nl") || "";
      updateActiveChip();
      renderDeals();
      document.getElementById("deals")?.scrollIntoView({ behavior: "smooth" });
    });
  }

  function bindPreviewControls() {
    document.getElementById("newsletter")?.addEventListener("submit", (event) => {
      event.preventDefault();
      showToast("Bedankt! Dit formulier wordt later aan de e-mailflow gekoppeld.");
      event.currentTarget.reset();
    });
    document.querySelectorAll('.round-action, button.account-action').forEach((control) => control.addEventListener("click", (event) => {
      event.preventDefault();
      showToast("Previewfunctie — deze koppelen we later aan je account.");
    }));
  }

  async function loadDeals() {
    try {
      const response = await fetch(CONFIG.dealsEndpoint, { method: "GET", mode: "cors", credentials: "omit", headers: { Accept: "application/json" } });
      if (!response.ok) throw new Error(`Xano gaf status ${response.status}.`);
      const data = await response.json();
      deals = resolveDeals(data).filter(isPublicDeal);
      renderDeals();
    } catch (error) {
      console.error("SeasonDeals public deals failed:", error);
      grid.innerHTML = "";
      setMessage("De deals konden nu niet worden geladen. Probeer het over een paar minuten opnieuw.", "error");
    }
  }

  function resolveDeals(data) {
    const candidates = [data, data?.items, data?.deals, data?.records, data?.data, data?.data?.items, data?.result, data?.result?.items];
    return candidates.find(Array.isArray) || [];
  }

  function isPublicDeal(deal) {
    const status = String(deal?.status || "").toLowerCase();
    const deleted = deal?.deleted_at;
    return (status === "active" || deal?.is_active === true) && (deleted === 0 || deleted === null || deleted === undefined);
  }

  function renderDeals() {
    const filtered = deals.filter((deal) => {
      const categoryMatch = activeFilter === "all" || getCategory(deal) === activeFilter;
      const haystack = [deal.title, deal.hotel_name, deal.city, deal.country, deal.hotel?.name, deal.hotel?.city].filter(Boolean).join(" ").toLocaleLowerCase("nl");
      return categoryMatch && (!locationQuery || haystack.includes(locationQuery));
    });

    grid.innerHTML = "";
    if (!filtered.length) {
      setMessage(deals.length ? "Voor deze selectie zijn momenteel geen deals beschikbaar." : "Er staan momenteel geen actieve deals online.", "empty");
      return;
    }

    setMessage("");
    filtered.forEach((deal) => grid.appendChild(createDealCard(deal)));
  }

  function createDealCard(deal) {
    const category = getCategory(deal);
    const title = text(deal.title || deal.name, "SeasonDeals deal");
    const image = getImage(deal);
    const price = getNumber(deal.deal_price ?? deal.price);
    const originalPrice = getNumber(deal.original_price);
    const discount = originalPrice && price < originalPrice ? Math.round((1 - price / originalPrice) * 100) : 0;
    const remaining = getRemaining(deal);
    const features = getFeatures(deal).slice(0, 2);
    const city = text(deal.city || deal.hotel?.city, "");
    const hotel = text(deal.hotel_name || deal.hotel?.name, "SeasonDeals partner");
    const rating = getNumber(deal.review_score ?? deal.hotel?.review_score);
    const reviews = getNumber(deal.review_count ?? deal.hotel?.review_count);
    const detailUrl = `${CONFIG.dealPage}?id=${encodeURIComponent(deal.id)}`;
    const card = document.createElement("article");
    card.className = "deal-card";
    card.dataset.category = category;
    card.innerHTML = `
      <div class="deal-image">
        ${image ? `<img src="${escapeAttribute(image)}" alt="${escapeAttribute(title)}" loading="lazy">` : `<div class="deal-image-placeholder"><span>SeasonDeals</span><small>Hot offers, cool prices</small></div>`}
        ${discount ? `<span class="discount">-${discount}%</span>` : ""}
      </div>
      <div class="deal-card-body">
        <span class="deal-type">${escapeHtml(formatCategory(category))}${city ? ` · ${escapeHtml(city)}` : ""}</span>
        <h3>${escapeHtml(title)}</h3>
        <div class="deal-partner">${escapeHtml(hotel)}</div>
        ${rating > 0 ? `<div class="rating"><span>★</span> ${escapeHtml(formatDecimal(rating))}${reviews > 0 ? ` · ${escapeHtml(formatNumber(reviews))} beoordelingen` : ""}</div>` : ""}
        <ul>${features.length ? features.map((feature) => `<li>✓ ${escapeHtml(feature)}</li>`).join("") : `<li>Bekijk de deal voor alle details</li>`}</ul>
        <div class="price-row"><span>${originalPrice > price ? `<del>${escapeHtml(formatCurrency(originalPrice))}</del>` : ""}<strong>${escapeHtml(formatCurrency(price))}</strong><small>${remaining === null ? "Beschikbaarheid op de dealpagina" : `${formatNumber(remaining)} beschikbaar`}</small></span><a href="${escapeAttribute(detailUrl)}">Bekijk deal →</a></div>
      </div>`;
    return card;
  }

  function getCategory(deal) {
    const raw = [deal.category_slug, deal.category?.slug, deal.category?.name, deal.category, deal.deal_type, deal.package_type, deal.type].filter((value) => typeof value === "string").join(" ").toLowerCase();
    if (/wellness|spa|sauna/.test(raw)) return "wellness";
    if (/massage|beauty|behandeling/.test(raw)) return "massage";
    if (/ticket|event|concert|festival/.test(raw)) return "tickets";
    if (/attract|uitje|park|museum|activiteit/.test(raw)) return "attraction";
    return "hotel";
  }

  function getImage(deal) {
    const first = deal.images?.[0];
    return deal.image_url || deal.image?.url || (typeof first === "string" ? first : first?.url) || deal.cover_image?.url || "";
  }

  function getFeatures(deal) {
    const features = [];
    if (deal.includes_breakfast) features.push("Ontbijt inbegrepen");
    if (deal.includes_wifi) features.push("Wifi inbegrepen");
    if (deal.includes_parking) features.push("Parkeren inbegrepen");
    if (deal.includes_late_checkout) features.push("Late check-out");
    if (deal.includes_welcome_drink) features.push("Welkomstdrankje");
    return features;
  }

  function getRemaining(deal) {
    const direct = getNumber(deal.remaining_inventory ?? deal.available_quantity);
    if (direct !== null) return Math.max(0, direct);
    const inventory = getNumber(deal.inventory);
    if (inventory === null) return null;
    return Math.max(0, inventory - (getNumber(deal.sold_quantity) || 0));
  }

  function updateActiveChip() {
    chips.forEach((chip) => chip.classList.toggle("is-active", chip.dataset.filter === activeFilter));
  }

  function setMessage(value, type = "") {
    if (!message) return;
    message.textContent = value;
    message.className = `deals-message${value ? " is-visible" : ""}${type ? ` is-${type}` : ""}`;
  }

  function getNumber(value) { const number = typeof value === "string" ? Number(value.replace(",", ".")) : value; return Number.isFinite(number) ? number : null; }
  function formatNumber(value) { return new Intl.NumberFormat(CONFIG.locale, { maximumFractionDigits: 0 }).format(value || 0); }
  function formatDecimal(value) { return new Intl.NumberFormat(CONFIG.locale, { minimumFractionDigits: 1, maximumFractionDigits: 1 }).format(value || 0); }
  function formatCurrency(value) { return new Intl.NumberFormat(CONFIG.locale, { style: "currency", currency: CONFIG.currency, maximumFractionDigits: 2 }).format(value || 0); }
  function formatCategory(value) { return ({ hotel: "Hotel", wellness: "Wellness", massage: "Massage", tickets: "Tickets", attraction: "Attractie" })[value] || "Deal"; }
  function text(value, fallback) { return value === null || value === undefined || String(value).trim() === "" ? fallback : String(value); }
  function escapeHtml(value) { return String(value ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#039;"); }
  function escapeAttribute(value) { return escapeHtml(value).replace(/`/g, "&#096;"); }

  function showToast(value) {
    const toast = document.getElementById("preview-toast");
    if (!toast) return;
    toast.textContent = value;
    toast.classList.add("is-visible");
    clearTimeout(showToast.timer);
    showToast.timer = setTimeout(() => toast.classList.remove("is-visible"), 3500);
  }
})();
