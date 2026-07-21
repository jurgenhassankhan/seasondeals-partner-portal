(() => {
  "use strict";
  const chips = [...document.querySelectorAll(".filter-chip")];
  const cards = [...document.querySelectorAll(".deal-card")];
  const menu = document.getElementById("main-nav");
  const menuToggle = document.getElementById("menu-toggle");

  chips.forEach((chip) => chip.addEventListener("click", () => applyFilter(chip.dataset.filter)));
  document.querySelectorAll("[data-filter-link]").forEach((link) => link.addEventListener("click", () => applyFilter(link.dataset.filterLink)));

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

  document.getElementById("deal-search")?.addEventListener("submit", (event) => {
    event.preventDefault();
    applyFilter(document.getElementById("search-category").value);
    document.getElementById("deals").scrollIntoView({ behavior: "smooth" });
    showToast("In de uiteindelijke versie worden hier de actuele Xano-deals getoond.");
  });

  document.getElementById("newsletter")?.addEventListener("submit", (event) => {
    event.preventDefault();
    showToast("Bedankt! Dit formulier wordt later aan de e-mailflow gekoppeld.");
    event.currentTarget.reset();
  });

  document.querySelectorAll('.deal-card a[href="#"], .deal-image button, .round-action, .account-action').forEach((control) => control.addEventListener("click", (event) => {
    event.preventDefault();
    showToast("Previewfunctie — deze koppelen we later aan Xano en je account.");
  }));

  function applyFilter(filter) {
    chips.forEach((chip) => chip.classList.toggle("is-active", chip.dataset.filter === filter));
    cards.forEach((card) => {
      const visible = filter === "all" || card.dataset.category === filter;
      card.hidden = !visible;
    });
  }

  function showToast(message) {
    const toast = document.getElementById("preview-toast");
    toast.textContent = message;
    toast.classList.add("is-visible");
    clearTimeout(showToast.timer);
    showToast.timer = setTimeout(() => toast.classList.remove("is-visible"), 3500);
  }
})();
