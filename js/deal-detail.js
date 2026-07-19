(() => {
  "use strict";

  const CONFIG = {
    dealsEndpoint: "https://x8ki-letl-twmt.n7.xano.io/api:seasondeals-partner/deals",
    loginUrl: "/seasondeals-partner-portal/login.html",
    tokenKey: "sd_partner_token",
    userKey: "sd_partner_user"
  };

  const form = document.getElementById("sd-deal-form");
  const message = document.getElementById("sd-global-message");
  const preview = document.getElementById("sd-image-preview");
  const uploadField = document.getElementById("sd-upload-field");
  const submit = document.getElementById("sd-submit-deal");
  const titleHeading = document.getElementById("sd-detail-title");
  const dealId = Number(new URLSearchParams(location.search).get("id"));

  init();

  async function init() {
    if (!sessionStorage.getItem(CONFIG.tokenKey)) return redirectToLogin();
    renderUser(readStoredUser());
    bindShell();
    setReadOnly(true);

    if (!Number.isInteger(dealId) || dealId < 1) {
      showMessage("Geen geldige deal geselecteerd.", "error");
      return;
    }

    try {
      const data = await request(CONFIG.dealsEndpoint);
      const deal = resolveDeals(data).find((item) => Number(item.id) === dealId);
      if (!deal) throw new Error("Deze deal is niet gevonden binnen je hotelaccount.");
      populate(deal);
      showMessage(`Deal #${dealId} is geladen. Je bekijkt de opgeslagen gegevens zonder ze te wijzigen.`, "info");
    } catch (error) {
      showMessage(error.message || "De deal kon niet worden geladen.", "error");
    }
  }

  function populate(deal) {
    setValue("title", deal.title);
    setValue("short_description", deal.short_description);
    setValue("long_description", deal.long_description);
    setValue("price", deal.price);
    setValue("original_price", deal.original_price);
    setValue("inventory", deal.inventory);
    setValue("minimum_nights", deal.minimum_nights);
    setValue("max_guests", deal.max_guests);
    setValue("valid_from", toDate(deal.travel_period_start));
    setValue("valid_until", toDate(deal.travel_period_end));
    setValue("cancellation_policy", deal.cancellation_policy);
    setChecked("includes_breakfast", deal.includes_breakfast);
    setChecked("includes_wifi", deal.includes_wifi);
    setChecked("includes_parking", deal.includes_parking);
    setChecked("includes_late_checkout", deal.includes_late_checkout);
    setChecked("includes_welcome_drink", deal.includes_welcome_drink);

    const image = deal.images?.[0]?.url || deal.images?.[0]?.path;
    if (image) {
      const url = image.startsWith("http") ? image : `https://x8ki-letl-twmt.n7.xano.io${image}`;
      preview.style.backgroundImage = `url("${url.replace(/"/g, "%22")}")`;
      preview.classList.add("has-image");
    }
    uploadField?.classList.add("is-hidden");
    if (titleHeading) titleHeading.textContent = deal.title || `Deal #${dealId}`;
    if (submit) {
      submit.disabled = true;
      submit.textContent = deal.status === "draft" ? "Conceptdeal" : formatLabel(deal.status);
    }
  }

  function setReadOnly(value) {
    Array.from(form?.elements || []).forEach((field) => {
      if (field.type !== "button") field.disabled = value;
    });
    document.getElementById("sd-remove-image")?.remove();
  }

  async function request(url) {
    const token = sessionStorage.getItem(CONFIG.tokenKey);
    const response = await fetch(url, {
      method: "GET",
      mode: "cors",
      credentials: "omit",
      headers: { Accept: "application/json", Authorization: `Bearer ${token}` }
    });
    const text = await response.text();
    let data = {};
    try { data = text ? JSON.parse(text) : {}; } catch { data = { message: text }; }
    if (response.status === 401 || response.status === 403) {
      sessionStorage.removeItem(CONFIG.tokenKey);
      sessionStorage.removeItem(CONFIG.userKey);
      redirectToLogin();
      throw new Error("Je sessie is verlopen.");
    }
    if (!response.ok) throw new Error(data.message || data.error || `Laden mislukt (${response.status}).`);
    return data;
  }

  function resolveDeals(data) {
    const options = [data, data?.items, data?.deals, data?.data, data?.data?.items, data?.result?.items];
    return options.find(Array.isArray) || [];
  }

  function setValue(name, value) {
    const field = form?.elements?.[name];
    if (field) field.value = value ?? "";
  }
  function setChecked(name, value) {
    const field = form?.elements?.[name];
    if (field) field.checked = Boolean(value);
  }
  function toDate(value) {
    if (!value) return "";
    const number = Number(value);
    const date = Number.isFinite(number) ? new Date(number) : new Date(value);
    return Number.isNaN(date.getTime()) ? "" : date.toISOString().slice(0, 10);
  }

  function bindShell() {
    const sidebar = document.getElementById("sd-sidebar");
    const overlay = document.getElementById("sd-mobile-overlay");
    document.getElementById("sd-menu-toggle")?.addEventListener("click", () => {
      sidebar?.classList.add("is-open"); overlay?.classList.add("is-visible");
    });
    const close = () => { sidebar?.classList.remove("is-open"); overlay?.classList.remove("is-visible"); };
    document.getElementById("sd-sidebar-close")?.addEventListener("click", close);
    overlay?.addEventListener("click", close);
    const menu = document.getElementById("sd-user-dropdown");
    document.getElementById("sd-user-menu-button")?.addEventListener("click", (event) => {
      event.stopPropagation(); menu?.classList.toggle("is-open");
    });
    document.addEventListener("click", () => menu?.classList.remove("is-open"));
    ["sd-sidebar-logout", "sd-dropdown-logout"].forEach((id) =>
      document.getElementById(id)?.addEventListener("click", () => {
        sessionStorage.removeItem(CONFIG.tokenKey); sessionStorage.removeItem(CONFIG.userKey); redirectToLogin();
      })
    );
  }

  function renderUser(user) {
    const name = user?.name || user?.full_name || "Partner";
    const role = formatLabel(user?.role || "hotel partner");
    const hotel = user?.hotel_name || user?.hotel?.name || "SeasonDeals hotel partner";
    setText("sd-user-name", name); setText("sd-user-role", role);
    setText("sd-dropdown-name", name); setText("sd-dropdown-email", user?.email || "");
    setText("sd-user-avatar", initial(name)); setText("sd-hotel-avatar", initial(hotel));
    setText("sd-sidebar-hotel", hotel); setText("sd-sidebar-role", role); setText("sd-topbar-hotel", hotel);
  }

  function showMessage(text, type) { message.textContent = text; message.className = `sd-global-message is-${type}`; }
  function readStoredUser() { try { return JSON.parse(sessionStorage.getItem(CONFIG.userKey) || "{}"); } catch { return {}; } }
  function redirectToLogin() { location.replace(CONFIG.loginUrl); }
  function formatLabel(value) { return String(value || "").replace(/[_-]+/g, " ").replace(/\b\w/g, (c) => c.toUpperCase()); }
  function initial(value) { return String(value || "S").trim().charAt(0).toUpperCase(); }
  function setText(id, value) { const element = document.getElementById(id); if (element) element.textContent = value; }
})();