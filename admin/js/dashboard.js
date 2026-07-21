(() => {
  "use strict";
  const core = window.AdminCore;

  init();
  async function init() {
    try {
      const admin = await core.requireAuth();
      if (!admin) return;
      core.mountShell({ active: "dashboard", title: "Dashboard", subtitle: "Platformoverzicht en de nieuwste deals die op beoordeling wachten." }, admin);
      const [dashboard, pending] = await Promise.all([
        core.request("/dashboard"),
        core.request("/deals?status=pending_approval&page=1&per_page=6")
      ]);
      renderKpis(dashboard, pending);
      renderPending(pending?.items || []);
    } catch (error) { renderError(error.message); }
  }

  function renderKpis(data, pending) {
    const cards = [
      ["Hotels", core.pick(data, ["stats.hotels.total", "hotels.total", "total_hotels"]), "Aangesloten accommodaties", ""],
      ["Actieve deals", core.pick(data, ["stats.deals.active", "deals.active", "active_deals"]), "Zichtbaar voor bezoekers", "green"],
      ["Te beoordelen", pending?.pagination?.total_items ?? core.pick(data, ["stats.deals.pending_approval", "deals.pending_approval", "pending_deals"]), "Wachten op een besluit", "orange"],
      ["Omzet", core.money(core.pick(data, ["stats.revenue.total", "revenue.total", "total_revenue"])), "Platformbrede gerealiseerde omzet", ""]
    ];
    document.getElementById("dashboard-kpis").innerHTML = cards.map(([label, value, note, tone]) => `<article class="kpi-card"><div class="kpi-top"><span class="kpi-label">${core.escapeHtml(label)}</span><span class="kpi-icon ${tone}">${kpiIcon()}</span></div><strong class="kpi-value">${core.escapeHtml(value)}</strong><span class="kpi-note">${core.escapeHtml(note)}</span></article>`).join("");
  }

  function renderPending(items) {
    const target = document.getElementById("pending-content");
    if (!items.length) { target.className = "empty-state"; target.innerHTML = "<strong>Alles is beoordeeld</strong><span>Er staan momenteel geen deals in de wachtrij.</span>"; return; }
    target.className = "table-wrap";
    target.innerHTML = `<table class="data-table"><thead><tr><th>Deal</th><th>Status</th><th>Ingediend</th><th>Prijs</th><th></th></tr></thead><tbody>${items.map(row).join("")}</tbody></table>`;
  }

  function row(deal) {
    const image = core.imageUrl(deal.images);
    return `<tr><td><div class="deal-cell">${image ? `<img class="deal-thumb" src="${core.escapeHtml(image)}" alt="">` : '<span class="deal-thumb deal-thumb-placeholder">S</span>'}<div><strong>${core.escapeHtml(deal.title || "Naamloze deal")}</strong><span>${core.escapeHtml(deal.hotel?.name || deal.hotel_name || "Onbekend hotel")} · ${core.escapeHtml(deal.hotel?.city || deal.city || "")}</span></div></div></td><td>${core.statusBadge(deal.status)}</td><td>${core.date(deal.submitted_at, true)}</td><td>${core.money(deal.price)}</td><td><a class="row-link" href="deal-detail.html?id=${encodeURIComponent(deal.id)}">Beoordelen →</a></td></tr>`;
  }

  function renderError(message) {
    const target = document.getElementById("pending-content");
    if (target) { target.className = "error-panel"; target.textContent = message; }
    const kpis = document.getElementById("dashboard-kpis");
    if (kpis) kpis.innerHTML = `<div class="error-panel">${core.escapeHtml(message)}</div>`;
  }
  function kpiIcon() { return '<svg viewBox="0 0 24 24"><path d="M5 19V9M12 19V5M19 19v-7"/></svg>'; }
})();
