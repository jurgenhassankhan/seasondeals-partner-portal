(() => {
  "use strict";
  const routes = { "/partner/bookings": "bookings.html", "/partner/vouchers": "vouchers.html", "/partner/settings": "settings.html" };
  document.querySelectorAll("a[href]").forEach((link) => {
    const route = routes[link.getAttribute("href")];
    if (route) link.setAttribute("href", route);
  });
  document.querySelectorAll('.sd-icon-button[aria-label="Notifications"]').forEach((button) => {
    button.addEventListener("click", () => {
      const target = document.getElementById("sd-notifications-panel");
      if (target) target.scrollIntoView({ behavior: "smooth", block: "start" });
      else location.href = "index.html#sd-notifications-panel";
    });
  });
  if (location.hash === "#sd-notifications-panel") {
    setTimeout(() => document.getElementById("sd-notifications-panel")?.scrollIntoView({ behavior: "smooth", block: "start" }), 350);
  }
})();
