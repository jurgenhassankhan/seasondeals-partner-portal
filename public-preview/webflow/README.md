# SeasonDeals in Webflow

Dit is de definitieve hybride inrichting:

- Webflow beheert het domein, de pagina-HTML en SEO.
- GitHub Pages beheert de centrale CSS en JavaScript.
- Xano levert deals, voorraad en checkout.
- Stripe blijft via Xano werken.

## Webflow-pagina's

Maak deze pagina's aan:

1. `new-website` — tijdelijke homepage-preview; later wordt dezelfde inhoud naar Webflows Home gekopieerd.
2. `dea` — bestaande dynamische dealpagina; ontvangt de deal via `?id=...`.
3. `veelgestelde-vragen` — FAQ.

## Homepage

1. Gebruik de HTML binnen `<body>` uit `../index.html` als de pagina-inhoud. Laat de laatste `script`-tag weg.
2. Plaats `home-head.html` in **Page settings > Custom code > Inside head tag**.
3. Plaats `home-before-body.html` in **Before body tag**.
4. Zet tijdens de testfase `noindex` aan.

## Dealpagina

1. Gebruik de HTML binnen `<body>` uit `../deal.html` als pagina-inhoud. Laat de twee laatste `script`-tags weg.
2. Vervang statische `index.html`-links in deze HTML door `/new-website` en `faq.html` door `/veelgestelde-vragen`.
3. Plaats `deal-head.html` in **Inside head tag**.
4. Plaats `deal-before-body.html` in **Before body tag**.

## Livegang

Kopieer de homepage-inhoud en custom code naar Webflows vaste Home-pagina. Wijzig daarna in `deal-head.html` alleen:

```js
homePage: "/"
```

De Xano- en Stripe-endpoints hoeven bij die omzetting niet te veranderen.
