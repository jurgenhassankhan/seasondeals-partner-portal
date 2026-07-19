(() => {
  "use strict";

  const CONFIG = {
    dealsEndpoint: "https://x8ki-letl-twmt.n7.xano.io/api:seasondeals-partner/deals",
    loginUrl: "/seasondeals-partner-portal/login.html",
    dealsUrl: "deals.html",
    tokenKey: "sd_partner_token",
    userKey: "sd_partner_user"
  };

  const elements = {
    form: document.getElementById("sd-deal-form"),
    submit: document.getElementById("sd-submit-deal"),
    message: document.getElementById("sd-global-message"),
    title: document.getElementById("sd-title"),
    shortDescription: document.getElementById("sd-short-description"),
    titleCount: document.getElementById("sd-title-count"),
    shortCount: document.getElementById("sd-short-count"),
    imageUrl: document.getElementById("sd-image-url"),
    imagePreview: document.getElementById("sd-image-preview"),
    sidebar: document.getElementById("sd-sidebar"),
    overlay: document.getElementById("sd-mobile-overlay"),
    menuToggle: document.getElementById("sd-menu-toggle"),
    sidebarClose: document.getElementById("sd-sidebar-close"),
    userMenuButton: document.getElementById("sd-user-menu-button"),
    userDropdown: document.getElementById("sd-user-dropdown"),
    sidebarLogout: document.getElementById("sd-sidebar-logout"),
    dropdownLogout: document.getElementById("sd-dropdown-logout"),
    sidebarHotel: document.getElementById("sd-sidebar-hotel"),
    sidebarRole: document.getElementById("sd-sidebar-role"),
    hotelAvatar: document.getElementById("sd-hotel-avatar"),
    topbarHotel: document.getElementById("sd-topbar-hotel"),
    userName: document.getElementById("sd-user-name"),
    userRole: document.getElementById("sd-user-role"),
    userAvatar: document.getElementById("sd-user-avatar"),
    dropdownName: document.getElementById("sd-dropdown-name"),
    dropdownEmail: document.getElementById("sd-dropdown-email")
  };

  init();

  function init() {
    if (!sessionStorage.getItem(CONFIG.tokenKey)) {
      redirectToLogin();
      return;
    }
    renderUser(readStoredUser());
    bindEvents();
    setDateDefaults();
    updateCounters();
  }

  function bindEvents() {
    elements.form?.addEventListener("submit", submitDeal);
    elements.title?.addEventListener("input", updateCounters);
    elements.shortDescription?.addEventListener("input", updateCounters);
    elements.imageUrl?.addEventListener("input", updateImagePreview);
    elements.menuToggle?.addEventListener("click", openSidebar);
    elements.sidebarClose?.addEventListener("click", closeSidebar);
    elements.overlay?.addEventListener("click", closeSidebar);
    elements.userMenuButton?.addEventListener("click", (event) => {
      event.stopPropagation();
      elements.userDropdown?.classList.toggle("is-open");
    });
    document.addEventListener("click", () => elements.userDropdown?.classList.remove("is-open"));
    elements.sidebarLogout?.addEventListener("click", logout);
    elements.dropdownLogout?.addEventListener("click", logout);
  }

  async function submitDeal(event) {
    event.preventDefault();
    clearMessage();

    if (!elements.form.reportValidity()) return;

    const payload = buildPayload();
    const validationError = validatePayload(payload);
    if (validationError) {
      showMessage(validationError, "error");
      return;
    }

    setLoading(true);
    try {
      const result = await apiRequest(CONFIG.dealsEndpoint, payload);
      const createdDeal = result?.deal || result?.data || result;
      const id = createdDeal?.id;
      sessionStorage.setItem("sd_deal_flash", id
        ? `Conceptdeal #${id} is succesvol opgeslagen.`
        : "De conceptdeal is succesvol opgeslagen.");
      window.location.assign(CONFIG.dealsUrl);
    } catch (error) {
      console.error("SeasonDeals create deal failed:", error);
      showMessage(error?.message || "De deal kon niet worden opgeslagen. Probeer het opnieuw.", "error");
      window.scrollTo({ top: 0, behavior: "smooth" });
    } finally {
      setLoading(false);
    }
  }

  function buildPayload() {
    const data = new FormData(elements.form);
    return {
      title: clean(data.get("title")),
      short_description: clean(data.get("short_description")),
      long_description: clean(data.get("long_description")),
      price: toNumber(data.get("price")),
      original_price: toOptionalNumber(data.get("original_price")),
      inventory: toInteger(data.get("inventory")),
      sold_quantity: 0,
      minimum_nights: toInteger(data.get("minimum_nights")),
      max_guests: toInteger(data.get("max_guests")),
      valid_from: clean(data.get("valid_from")),
      valid_until: clean(data.get("valid_until")),
      image_url: clean(data.get("image_url")),
      cancellation_policy: clean(data.get("cancellation_policy")),
      includes_breakfast: data.has("includes_breakfast"),
      includes_wifi: data.has("includes_wifi"),
      includes_parking: data.has("includes_parking"),
      includes_late_checkout: data.has("includes_late_checkout"),
      includes_welcome_drink: data.has("includes_welcome_drink"),
      status: "draft",
      is_active: false
    };
  }

  function validatePayload(payload) {
    if (payload.original_price !== null && payload.original_price <= payload.price) {
      return "De oorspronkelijke prijs moet hoger zijn dan de dealprijs.";
    }
    if (payload.valid_until < payload.valid_from) {
      return "De einddatum moet op of na de begindatum liggen.";
    }
    if (!payload.image_url.startsWith("https://")) {
      return "Gebruik een veilige afbeeldingslink die begint met https://.";
    }
    return "";
  }

  async function apiRequest(url, body) {
    const token = sessionStorage.getItem(CONFIG.tokenKey);
    if (!token) {
      redirectToLogin();
      throw new Error("Je sessie is verlopen.");
    }

    let response;
    try {
      response = await fetch(url, {
        method: "POST",
        mode: "cors",
        credentials: "omit",
        headers: {
          Accept: "application/json",
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify(body)
      });
    } catch {
      throw new Error("De dealservice is niet bereikbaar. Controleer je verbinding en probeer opnieuw.");
    }

    const responseData = await readResponse(response);
    if (response.status === 401 || response.status === 403) {
      clearSession();
      window.setTimeout(redirectToLogin, 600);
      throw new Error("Je sessie is verlopen. Je wordt doorgestuurd naar de loginpagina.");
    }
    if (!response.ok) {
      const apiMessage = responseData?.message || responseData?.error || responseData?.detail;
      throw new Error(typeof apiMessage === "string"
        ? apiMessage
        : `Deal opslaan mislukt met status ${response.status}.`);
    }
    return responseData;
  }

  async function readResponse(response) {
    const text = await response.text();
    if (!text) return {};
    try { return JSON.parse(text); } catch { return { message: text }; }
  }

  function setDateDefaults() {
    const from = document.getElementById("sd-valid-from");
    const until = document.getElementById("sd-valid-until");
    const today = new Date();
    const later = new Date(today);
    later.setMonth(later.getMonth() + 3);
    from.min = toDateInput(today);
    until.min = toDateInput(today);
    if (!from.value) from.value = toDateInput(today);
    if (!until.value) until.value = toDateInput(later);
    from.addEventListener("change", () => {
      until.min = from.value;
      if (until.value < from.value) until.value = from.value;
    });
  }

  function updateCounters() {
    elements.titleCount.textContent = `${elements.title.value.length}/120 tekens`;
    elements.shortCount.textContent = `${elements.shortDescription.value.length}/240 tekens`;
  }

  function updateImagePreview() {
    const url = elements.imageUrl.value.trim();
    elements.imagePreview.style.backgroundImage = url.startsWith("https://") ? `url("${url.replace(/"/g, "%22")}")` : "";
    elements.imagePreview.classList.toggle("has-image", url.startsWith("https://"));
  }

  function setLoading(loading) {
    elements.submit.disabled = loading;
    elements.submit.textContent = loading ? "Conceptdeal opslaan..." : "Conceptdeal opslaan";
  }

  function renderUser(user) {
    const name = fallback(user?.name || user?.full_name, "Partner");
    const role = fallback(user?.role, "hotel partner");
    const email = fallback(user?.email, "");
    const hotelName = fallback(user?.hotel_name || user?.hotel?.name || user?.hotel?.hotel_name, "SeasonDeals hotel partner");
    setText(elements.userName, name); setText(elements.userRole, formatLabel(role));
    setText(elements.dropdownName, name); setText(elements.dropdownEmail, email);
    setText(elements.userAvatar, initial(name)); setText(elements.hotelAvatar, initial(hotelName));
    setText(elements.sidebarHotel, hotelName); setText(elements.sidebarRole, formatLabel(role)); setText(elements.topbarHotel, hotelName);
  }

  function readStoredUser() { try { return JSON.parse(sessionStorage.getItem(CONFIG.userKey) || "{}"); } catch { return {}; } }
  function logout() { clearSession(); redirectToLogin(); }
  function clearSession() { sessionStorage.removeItem(CONFIG.tokenKey); sessionStorage.removeItem(CONFIG.userKey); }
  function redirectToLogin() { window.location.replace(CONFIG.loginUrl); }
  function openSidebar() { elements.sidebar?.classList.add("is-open"); elements.overlay?.classList.add("is-visible"); document.body.style.overflow = "hidden"; }
  function closeSidebar() { elements.sidebar?.classList.remove("is-open"); elements.overlay?.classList.remove("is-visible"); document.body.style.overflow = ""; }
  function showMessage(message, type) { elements.message.textContent = message; elements.message.className = `sd-global-message is-${type}`; }
  function clearMessage() { elements.message.textContent = ""; elements.message.className = "sd-global-message"; }
  function clean(value) { return String(value || "").trim(); }
  function toNumber(value) { const number = Number(value); return Number.isFinite(number) ? number : 0; }
  function toOptionalNumber(value) { return clean(value) === "" ? null : toNumber(value); }
  function toInteger(value) { return Math.trunc(toNumber(value)); }
  function toDateInput(date) { return date.toISOString().slice(0, 10); }
  function fallback(value, backup) { return value == null || String(value).trim() === "" ? backup : String(value); }
  function initial(value) { return String(value || "S").trim().charAt(0).toUpperCase(); }
  function formatLabel(value) { return String(value || "").replace(/[_-]+/g, " ").replace(/\b\w/g, (c) => c.toUpperCase()); }
  function setText(element, value) { if (element) element.textContent = value; }
})();