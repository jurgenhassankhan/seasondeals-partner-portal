(() => {
  "use strict";
  const core = window.AdminCore;
  let page = 1;
  let admin;
  init();

  async function init() {
    try {
      admin = await core.requireAuth();
      core.mountShell({ active: "integrations", title: "Integratiebeheer", subtitle: "Beheer externe hotelkoppelingen en veilige API-toegang." }, admin);
      document.getElementById("integrations-refresh").addEventListener("click", load);
      document.getElementById("integration-create").addEventListener("click", openCreateIntegration);
      await load();
    } catch (error) { showError(error.message); }
  }

  async function load() {
    const target = document.getElementById("integrations-content");
    target.className = "loading-state";
    target.innerHTML = '<div class="spinner"></div>Integraties ophalen…';
    try {
      const raw = await core.request(`/integrations?page=${page}&per_page=25`);
      const data = normalizeObject(raw);
      const integrations = getItems(data);
      if (!integrations.length) {
        target.innerHTML = '<div class="empty-state"><strong>Nog geen integraties</strong><span>Nieuwe hotelintegraties verschijnen hier zodra ze zijn aangemaakt.</span></div>';
      } else {
        target.className = "table-wrap";
        target.innerHTML = `<table class="data-table"><thead><tr><th>Hotel</th><th>Provider</th><th>Omgeving</th><th>Synchronisatie</th><th>Status</th><th>Laatste resultaat</th><th>Acties</th></tr></thead><tbody>${integrations.map(row).join("")}</tbody></table>`;
        target.querySelectorAll("[data-integration-status]").forEach(select => select.addEventListener("change", () => updateStatus(select)));
        target.querySelectorAll("[data-manage-keys]").forEach(button => button.addEventListener("click", () => openKeyManager(button.dataset.manageKeys, button.dataset.integrationName)));
      }
      renderPagination(data, integrations.length);
    } catch (error) { showError(error.message); }
  }

  function row(item) {
    const hotel = normalizeObject(item.hotel) || {}, provider = normalizeObject(item.provider || item.integration_provider) || {};
    const status = item.status || "pending", environment = item.environment || "test";
    const statuses = ["pending", "testing", "active", "paused", "error", "revoked"];
    const integrationName = `${hotel.name || item.hotel_name || `Hotel #${item.hotel_id || "—"}`} · ${provider.name || item.provider_name || "API"}`;
    return `<tr><td><div class="integration-cell"><strong>${core.escapeHtml(hotel.name || item.hotel_name || `Hotel #${item.hotel_id || "—"}`)}</strong><span>ID ${core.escapeHtml(item.hotel_id || hotel.id || "—")}</span></div></td><td><div class="integration-cell"><strong>${core.escapeHtml(provider.name || item.provider_name || `Provider #${item.provider_id || "—"}`)}</strong><span>${core.escapeHtml(provider.slug || "")}</span></div></td><td>${core.escapeHtml(core.label(environment))}</td><td><div class="integration-cell"><strong>${core.escapeHtml(core.label(item.sync_direction || "bidirectional"))}</strong><span>${item.auto_sync_enabled ? "Automatisch" : "Handmatig"}</span></div></td><td><select class="integration-status-select" data-integration-status="${core.escapeHtml(item.id)}" data-current="${core.escapeHtml(status)}">${statuses.map(value => `<option value="${value}"${value === status ? " selected" : ""}>${core.escapeHtml(core.label(value))}</option>`).join("")}</select></td><td><div class="integration-cell"><strong>${core.escapeHtml(core.date(item.last_success_at || item.last_sync_at, true))}</strong>${item.last_error_message ? `<span class="integration-error">${core.escapeHtml(item.last_error_message)}</span>` : "<span>Geen foutmelding</span>"}</div></td><td><div class="integration-actions"><button class="integration-key-button" type="button" data-manage-keys="${core.escapeHtml(item.id)}" data-integration-name="${core.escapeHtml(integrationName)}">Sleutels beheren</button></div></td></tr>`;
  }

  async function updateStatus(select) {
    const status = select.value;
    if (!confirm(`Integratiestatus wijzigen naar ${core.label(status)}?${status === "revoked" ? " Alle gekoppelde API-sleutels worden direct ingetrokken." : ""}`)) { select.value = select.dataset.current; return; }
    select.disabled = true;
    try {
      await core.request(`/integrations/${select.dataset.integrationStatus}/status`, { method: "PATCH", body: JSON.stringify({ status }) });
      core.toast("Integratiestatus is bijgewerkt.");
      await load();
    } catch (error) { select.value = select.dataset.current; core.toast(error.message, "error"); }
    finally { select.disabled = false; }
  }

  async function createKey(integrationId, activeCount = 0) {
    if (!core.canReview(admin)) return core.toast("Alleen een superadmin kan API-sleutels aanmaken.", "error");
    if (activeCount > 0 && !confirm(`Er ${activeCount === 1 ? "is" : "zijn"} al ${activeCount} actieve testsleutel${activeCount === 1 ? "" : "s"}. Toch nog een sleutel aanmaken?`)) return;
    const name = prompt("Naam voor deze testsleutel:", "Testkoppeling");
    if (!name?.trim()) return;
    try {
      const result = normalizeObject(await core.request(`/integrations/${integrationId}/api-keys`, { method: "POST", body: JSON.stringify({ name: name.trim(), environment: "test", scopes: { "deals.read": true, "deals.write": true, "inventory.write": true, "bookings.read": true } }) }));
      const secret = result.api_key || result.key || result.secret || result.full_key;
      if (!secret) throw new Error("De sleutel is aangemaakt, maar de eenmalige sleutel ontbreekt in de response.");
      showSecret(secret);
      await loadManagedKeys(integrationId);
    } catch (error) { core.toast(error.message, "error"); }
  }

  async function openKeyManager(integrationId, integrationName = "Hotelintegratie") {
    const modal = document.getElementById("integration-keys-modal");
    modal.dataset.integrationId = integrationId; modal.dataset.integrationName = integrationName;
    modal.innerHTML = `<div class="integration-dialog integration-keys-dialog"><button class="integration-dialog-close" type="button" aria-label="Sluiten">×</button><span class="eyebrow">API-toegang</span><h2>${core.escapeHtml(integrationName)}</h2><div id="integration-keys-content" class="loading-state"><div class="spinner"></div>Sleutels ophalen…</div></div>`;
    modal.classList.add("is-open"); modal.setAttribute("aria-hidden", "false");
    modal.querySelector(".integration-dialog-close").addEventListener("click", () => closeKeyManager(modal));
    modal.addEventListener("click", event => { if (event.target === modal) closeKeyManager(modal); });
    await loadManagedKeys(integrationId);
  }

  async function loadManagedKeys(integrationId) {
    const modal = document.getElementById("integration-keys-modal"), target = document.getElementById("integration-keys-content");
    if (!target || String(modal.dataset.integrationId) !== String(integrationId)) return;
    try {
      const data = normalizeObject(await core.request(`/integrations/${integrationId}/api-keys`)), keys = getItems(data);
      const active = keys.filter(item => item.is_active !== false && !item.revoked_at);
      target.className = "integration-key-manager";
      target.innerHTML = `<div class="integration-key-summary"><div><strong>${active.length}</strong><span>Actieve sleutel${active.length === 1 ? "" : "s"}</span></div><button id="integration-new-key" class="primary-button" type="button">Nieuwe testsleutel</button></div>${keys.length ? `<div class="integration-managed-keys">${keys.map(item => managedKeyRow(integrationId, item)).join("")}</div>` : '<div class="integration-key-empty">Er zijn nog geen API-sleutels voor deze koppeling.</div>'}`;
      document.getElementById("integration-new-key").addEventListener("click", () => createKey(integrationId, active.length));
      target.querySelectorAll("[data-revoke-managed-key]").forEach(button => button.addEventListener("click", () => revokeManagedKey(integrationId, button.dataset.revokeManagedKey)));
    } catch (error) { target.className = "error-panel"; target.textContent = error.message; }
  }

  function managedKeyRow(integrationId, item) {
    const active = item.is_active !== false && !item.revoked_at, masked = `${item.key_prefix || "sd_test_"}••••${item.key_last4 || ""}`;
    return `<div class="integration-managed-key"><div class="integration-managed-key-main"><strong>${core.escapeHtml(item.name || "API-sleutel")}</strong><code>${core.escapeHtml(masked)}</code><span>Aangemaakt ${core.date(item.created_at, true)} · laatst gebruikt ${item.last_used_at ? core.date(item.last_used_at, true) : "nog nooit"}</span></div><div class="integration-managed-key-side"><span class="status-badge status-${active ? "active" : "archived"}"><span></span>${active ? "Actief" : "Ingetrokken"}</span>${active ? `<button class="danger-button" type="button" data-revoke-managed-key="${core.escapeHtml(item.id)}">Intrekken</button>` : ""}</div></div>`;
  }

  async function revokeManagedKey(integrationId, keyId) {
    if (!confirm("Deze API-sleutel intrekken? De gekoppelde applicatie verliest direct toegang.")) return;
    try { await core.request(`/integrations/${integrationId}/api-keys/${keyId}/revoke`, { method: "POST" }); core.toast("API-sleutel is ingetrokken."); await loadManagedKeys(integrationId); }
    catch (error) { core.toast(error.message, "error"); }
  }

  function closeKeyManager(modal) { modal.classList.remove("is-open"); modal.setAttribute("aria-hidden", "true"); modal.innerHTML = ""; delete modal.dataset.integrationId; }

  async function openCreateIntegration() {
    if (!core.canReview(admin)) return core.toast("Alleen een superadmin of platformadmin kan koppelingen aanmaken.", "error");
    const modal = document.getElementById("integration-form-modal");
    modal.innerHTML = '<div class="integration-dialog"><button class="integration-dialog-close" type="button" aria-label="Sluiten">×</button><span class="eyebrow">Nieuwe integratie</span><h2>Hotel koppelen</h2><div class="loading-state"><div class="spinner"></div>Hotels en providers ophalen…</div></div>';
    modal.classList.add("is-open"); modal.setAttribute("aria-hidden", "false");
    bindCreateModalClose(modal);
    try {
      const [hotelResponse, providerResponse] = await Promise.all([
        core.request("/hotels?page=1&per_page=100"),
        core.request("/integration-providers")
      ]);
      const hotels = getItems(normalizeObject(hotelResponse));
      const providers = getItems(normalizeObject(providerResponse));
      renderCreateForm(modal, hotels, providers);
    } catch (error) {
      modal.querySelector(".loading-state").className = "error-panel";
      modal.querySelector(".error-panel").textContent = error.message;
    }
  }

  function renderCreateForm(modal, hotels, providers) {
    const body = modal.querySelector(".loading-state");
    if (!hotels.length || !providers.length) {
      body.className = "error-panel";
      body.textContent = !hotels.length ? "Er zijn geen hotels beschikbaar om te koppelen." : "Er zijn geen actieve integratieproviders beschikbaar.";
      return;
    }
    const preferred = providers.find(item => item.slug === "seasondeals_api")?.id;
    body.outerHTML = `<form id="integration-create-form" class="integration-form"><label>Hotel<select name="hotel_id" required><option value="">Kies een hotel…</option>${hotels.map(item => `<option value="${core.escapeHtml(item.id)}">${core.escapeHtml(item.name || `Hotel #${item.id}`)}</option>`).join("")}</select></label><label>Provider<select name="provider_id" required><option value="">Kies een provider…</option>${providers.map(item => `<option value="${core.escapeHtml(item.id)}"${String(item.id) === String(preferred) ? " selected" : ""}>${core.escapeHtml(item.name || item.slug)}</option>`).join("")}</select></label><label>Omgeving<input value="Test" disabled><input name="environment" type="hidden" value="test"></label><label>Synchronisatie<select name="sync_direction"><option value="bidirectional">Tweerichtingsverkeer</option><option value="inbound">Naar SeasonDeals</option><option value="outbound">Vanuit SeasonDeals</option></select></label><label class="full">Extern hotel-ID <span>(optioneel)</span><input name="external_hotel_id" placeholder="Bijvoorbeeld HOTEL-123"></label><div class="integration-form-note">De koppeling wordt veilig in de testomgeving aangemaakt. Productieverkeer blijft uitgeschakeld.</div><div class="integration-form-actions"><button class="secondary-button" data-cancel-integration type="button">Annuleren</button><button id="integration-create-submit" class="primary-button" type="submit">Koppeling aanmaken</button></div></form>`;
    modal.querySelector("[data-cancel-integration]").addEventListener("click", () => closeCreateModal(modal));
    modal.querySelector("#integration-create-form").addEventListener("submit", event => submitIntegration(event, modal));
  }

  async function submitIntegration(event, modal) {
    event.preventDefault();
    const form = new FormData(event.currentTarget), button = document.getElementById("integration-create-submit");
    const body = {
      hotel_id: Number(form.get("hotel_id")), provider_id: Number(form.get("provider_id")), environment: "test",
      external_hotel_id: String(form.get("external_hotel_id") || "").trim(), sync_direction: String(form.get("sync_direction") || "bidirectional"),
      auto_sync_enabled: false, webhook_enabled: false
    };
    button.disabled = true; button.textContent = "Aanmaken…";
    try {
      await core.request("/integrations", { method: "POST", body: JSON.stringify(body) });
      closeCreateModal(modal); core.toast("Testkoppeling is aangemaakt."); page = 1; await load();
    } catch (error) { core.toast(error.message, "error"); button.disabled = false; button.textContent = "Koppeling aanmaken"; }
  }

  function bindCreateModalClose(modal) { modal.querySelector(".integration-dialog-close").addEventListener("click", () => closeCreateModal(modal)); modal.addEventListener("click", event => { if (event.target === modal) closeCreateModal(modal); }); }
  function closeCreateModal(modal) { modal.classList.remove("is-open"); modal.setAttribute("aria-hidden", "true"); modal.innerHTML = ""; }

  function showSecret(secret) {
    const modal = document.getElementById("integration-secret-modal");
    modal.innerHTML = `<div class="integration-dialog"><button class="integration-dialog-close" type="button" aria-label="Sluiten">×</button><span class="eyebrow">Eenmalig zichtbaar</span><h2>Bewaar deze testsleutel nu</h2><p>De volledige sleutel wordt niet opgeslagen en kan na het sluiten niet opnieuw worden bekeken.</p><div class="integration-secret"><code>${core.escapeHtml(secret)}</code><button class="primary-button" type="button">Kopiëren</button></div></div>`;
    modal.classList.add("is-open"); modal.setAttribute("aria-hidden", "false");
    const close = () => { modal.classList.remove("is-open"); modal.setAttribute("aria-hidden", "true"); modal.innerHTML = ""; };
    modal.querySelector(".integration-dialog-close").addEventListener("click", close);
    modal.querySelector(".primary-button").addEventListener("click", async event => { try { await navigator.clipboard.writeText(secret); event.currentTarget.textContent = "Gekopieerd"; } catch { event.currentTarget.textContent = "Selecteer handmatig"; } });
  }

  function renderPagination(data, visibleCount) {
    const paging = normalizeObject(data.paging) || data;
    const current = Number(paging.curPage || paging.page || page) || 1;
    const pages = Math.max(1, Number(paging.pageTotal || paging.total_pages || 1) || 1);
    const total = Number(paging.itemsTotal || paging.total || visibleCount) || visibleCount;
    page = current;
    document.getElementById("integrations-pagination").innerHTML = `<div class="pagination"><span>${total} integraties · pagina ${current} van ${pages}</span><div class="pagination-buttons"><button id="integrations-prev" ${current <= 1 ? "disabled" : ""}>←</button><button id="integrations-next" ${current >= pages ? "disabled" : ""}>→</button></div></div>`;
    document.getElementById("integrations-prev")?.addEventListener("click", () => { page--; load(); });
    document.getElementById("integrations-next")?.addEventListener("click", () => { page++; load(); });
  }

  function normalizeObject(value) { if (typeof value !== "string") return value; try { return JSON.parse(value); } catch { return value; } }
  function getItems(data) { const values = [data, normalizeObject(data?.items), data?.data, normalizeObject(data?.data?.items)]; return values.find(Array.isArray) || []; }
  function showError(message) { const target = document.getElementById("integrations-content"); if (target) { target.className = "error-panel"; target.textContent = message; } }
})();
