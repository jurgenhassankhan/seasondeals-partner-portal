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
        target.querySelectorAll("[data-create-key]").forEach(button => button.addEventListener("click", () => createKey(button.dataset.createKey)));
      }
      renderPagination(data, integrations.length);
    } catch (error) { showError(error.message); }
  }

  function row(item) {
    const hotel = normalizeObject(item.hotel) || {}, provider = normalizeObject(item.provider || item.integration_provider) || {};
    const status = item.status || "pending", environment = item.environment || "test";
    const statuses = ["pending", "testing", "active", "paused", "error", "revoked"];
    return `<tr><td><div class="integration-cell"><strong>${core.escapeHtml(hotel.name || item.hotel_name || `Hotel #${item.hotel_id || "—"}`)}</strong><span>ID ${core.escapeHtml(item.hotel_id || hotel.id || "—")}</span></div></td><td><div class="integration-cell"><strong>${core.escapeHtml(provider.name || item.provider_name || `Provider #${item.provider_id || "—"}`)}</strong><span>${core.escapeHtml(provider.slug || "")}</span></div></td><td>${core.escapeHtml(core.label(environment))}</td><td><div class="integration-cell"><strong>${core.escapeHtml(core.label(item.sync_direction || "bidirectional"))}</strong><span>${item.auto_sync_enabled ? "Automatisch" : "Handmatig"}</span></div></td><td><select class="integration-status-select" data-integration-status="${core.escapeHtml(item.id)}" data-current="${core.escapeHtml(status)}">${statuses.map(value => `<option value="${value}"${value === status ? " selected" : ""}>${core.escapeHtml(core.label(value))}</option>`).join("")}</select></td><td><div class="integration-cell"><strong>${core.escapeHtml(core.date(item.last_success_at || item.last_sync_at, true))}</strong>${item.last_error_message ? `<span class="integration-error">${core.escapeHtml(item.last_error_message)}</span>` : "<span>Geen foutmelding</span>"}</div></td><td><div class="integration-actions"><button class="integration-key-button" type="button" data-create-key="${core.escapeHtml(item.id)}">Testsleutel maken</button></div></td></tr>`;
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

  async function createKey(integrationId) {
    if (!core.canReview(admin)) return core.toast("Alleen een superadmin kan API-sleutels aanmaken.", "error");
    const name = prompt("Naam voor deze testsleutel:", "Testkoppeling");
    if (!name?.trim()) return;
    try {
      const result = normalizeObject(await core.request(`/integrations/${integrationId}/api-keys`, { method: "POST", body: JSON.stringify({ name: name.trim(), environment: "test", scopes: { "deals.read": true, "deals.write": true, "inventory.write": true, "bookings.read": true } }) }));
      const secret = result.api_key || result.key || result.secret || result.full_key;
      if (!secret) throw new Error("De sleutel is aangemaakt, maar de eenmalige sleutel ontbreekt in de response.");
      showSecret(secret);
    } catch (error) { core.toast(error.message, "error"); }
  }

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
