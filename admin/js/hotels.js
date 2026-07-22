(() => {
  "use strict";
  const core = window.AdminCore;
  let page = 1;
  init();

  async function init() {
    try {
      const admin = await core.requireAuth();
      if (!admin) return;
      core.mountShell({ active: "hotels", title: "Hotels", subtitle: "Bekijk aangesloten hotelpartners en beheer hun status." }, admin);
      document.getElementById("hotels-refresh")?.addEventListener("click", load);
      load();
    } catch (error) { showError(error.message); }
  }

  async function load() {
    const target = document.getElementById("hotels-content");
    target.className = "loading-state";
    target.innerHTML = '<div class="spinner"></div>Hotels ophalen…';
    try {
      const data = await core.request(`/hotels?page=${page}&per_page=20`);
      render(items(data));
      pagination(data);
    } catch (error) { showError(error.message); }
  }

  function render(hotels) {
    const target = document.getElementById("hotels-content");
    if (!hotels.length) { target.className = "empty-state"; target.innerHTML = "<strong>Geen hotels gevonden</strong><span>Er zijn nog geen hotelpartners aangesloten.</span>"; return; }
    target.className = "table-wrap";
    target.innerHTML = `<table class="data-table"><thead><tr><th>Hotel</th><th>Contact</th><th>Adres</th><th>Commissie</th><th>Status</th><th>Actie</th></tr></thead><tbody>${hotels.map(row).join("")}</tbody></table>`;
    target.querySelectorAll("[data-hotel-status]").forEach((select) => select.addEventListener("change", () => updateStatus(select)));
  }

  function row(hotel) {
    const logo = fileUrl(hotel.logo);
    return `<tr><td><div class="deal-cell">${logo ? `<img class="deal-thumb" src="${core.escapeHtml(logo)}" alt="">` : '<span class="deal-thumb deal-thumb-placeholder">H</span>'}<div><strong>${core.escapeHtml(hotel.name || "Naamloos hotel")}</strong><span>Hotel #${core.escapeHtml(hotel.id)} · sinds ${core.date(hotel.created_at)}</span></div></div></td><td><strong>${core.escapeHtml(hotel.email || "—")}</strong><br><span>${core.escapeHtml(hotel.phone || "—")}</span></td><td>${core.escapeHtml(hotel.address || "—")}</td><td>${core.escapeHtml(hotel.commission_percentage ?? 15)}%</td><td><span class="status-badge status-${core.escapeHtml(hotel.legal_status || "pending")}"><span></span>${core.escapeHtml(core.label(hotel.legal_status || "pending"))}</span></td><td><select data-hotel-status="${core.escapeHtml(hotel.id)}" data-current="${core.escapeHtml(hotel.legal_status || "pending")}"><option value="active"${hotel.legal_status === "active" ? " selected" : ""}>Actief</option><option value="pending"${hotel.legal_status === "pending" ? " selected" : ""}>In afwachting</option><option value="suspended"${hotel.legal_status === "suspended" ? " selected" : ""}>Geschorst</option></select></td></tr>`;
  }

  async function updateStatus(select) {
    const status = select.value;
    if (!confirm(`Hotelstatus wijzigen naar ${core.label(status)}?`)) { select.value = select.dataset.current; return; }
    select.disabled = true;
    try { await core.request(`/hotels/${select.dataset.hotelStatus}/status`, { method: "PATCH", body: JSON.stringify({ status }) }); core.toast("Hotelstatus is bijgewerkt."); await load(); }
    catch (error) { select.value = select.dataset.current; core.toast(error.message, "error"); }
    finally { select.disabled = false; }
  }

  function pagination(data) {
    const pages = Math.max(1, Number(data?.pageTotal) || 1), total = Number(data?.itemsTotal) || items(data).length;
    page = Number(data?.curPage) || page;
    document.getElementById("hotels-pagination").innerHTML = `<div class="pagination"><span>${total} hotels · pagina ${page} van ${pages}</span><div class="pagination-buttons"><button id="hotels-prev" ${page <= 1 ? "disabled" : ""}>←</button><button id="hotels-next" ${page >= pages ? "disabled" : ""}>→</button></div></div>`;
    document.getElementById("hotels-prev")?.addEventListener("click", () => { page--; load(); });
    document.getElementById("hotels-next")?.addEventListener("click", () => { page++; load(); });
  }
  function items(data) { return [data, data?.items, data?.data, data?.data?.items].find(Array.isArray) || []; }
  function fileUrl(file) { const path = typeof file === "string" ? file : file?.url || file?.path; return !path ? "" : path.startsWith("http") ? path : core.config.xanoOrigin + path; }
  function showError(message) { const target = document.getElementById("hotels-content"); if (target) { target.className = "error-panel"; target.textContent = message; } }
})();
