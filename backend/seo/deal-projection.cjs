'use strict';
const render = require('./deal-renderer.cjs');
const ORIGIN = 'https://www.seasondeals.nl';
const clean = v => typeof v === 'string' ? v.trim().replace(/\s+/g, ' ') : '';
const required = (v, key) => { const s = clean(v); if (!s) throw Error(`Missing ${key}`); return s; };
const esc = s => String(s).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
function imageUrl(value) {
  const u = new URL(value);
  if (u.protocol !== 'https:' || u.username || u.password) throw Error('Invalid photo URL');
  return u.href;
}
function stableSlug(deal, previous) {
  if (!Number.isSafeInteger(deal.id) || deal.id < 1) throw Error('Invalid deal id');
  if (previous) {
    if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(previous) || !previous.endsWith(`-${deal.id}`)) throw Error('Slug identity mismatch');
    return previous;
  }
  const name = required(deal.hotel_name, 'hotel_name').normalize('NFKD').replace(/[\u0300-\u036f]/g, '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0,100).replace(/-$/,'');
  return `${name || 'hotel'}-${deal.id}`;
}
// Input: verified public projection plus approved_at/deleted_at from the server deal row.
// The server adapter must first recheck provider/environment/is_enabled; never pass raw supplier data.
// Publication/withdrawal is deliberately left to the server outbox adapter, not the browser.
function projectDeal(input, {previousSlug, indexable = false} = {}) {
  if (input?.source !== 'provider_sync') throw Error('Unsupported source; partner route unchanged');
  if (input.status !== 'active' || input.is_active !== true || !input.approved_at || input.deleted_at) return null;
  if (input.content_verified !== true) throw Error('Unverified supplier content');
  const slug = stableSlug(input, previousSlug);
  const title = required(input.title, 'title');
  const description = required(input.short_description, 'short_description');
  const urls = input.external_image_urls ?? input.images;
  if (!Array.isArray(urls) || !urls.length || urls.length > 5 || new Set(urls).size !== urls.length) throw Error('Invalid verified photo gallery');
  const photos = urls.map(imageUrl);
  if (new Set(photos).size !== photos.length) throw Error('Duplicate photo URLs');
  const price = Number(input.deal_price ?? input.price);
  if (!Number.isFinite(price) || price <= 0) throw Error('Invalid public price');
  // Explicit allowlist: no supplier prices, credentials, booking ids or private mappings.
  const deal = {id:input.id,source:'provider_sync',status:'active',is_active:true,content_verified:true,
    title,short_description:description,long_description:(required(input.long_description,'long_description'),input.long_description.trim()),
    hotel_name:required(input.hotel_name,'hotel_name'),city:clean(input.city),country:clean(input.country),
    cancellation_policy:(required(input.cancellation_policy,'cancellation_policy'),input.cancellation_policy.trim()),price,external_image_urls:photos,
    booking_enabled:false}; // Hydration must check current availability before enabling checkout.
  for (const key of ['travel_period_start','travel_period_end']) {
    const value = input[key];
    if (typeof value !== 'number' || !Number.isFinite(value) || value < 1e11) throw Error(`Invalid ${key}`);
    deal[key] = value;
  }
  if (deal.travel_period_end <= deal.travel_period_start) throw Error('Invalid stay');
  if (!Number.isInteger(input.max_guests) || input.max_guests < 1 || input.max_guests > 20) throw Error('Invalid occupancy');
  deal.max_guests = input.max_guests;
  for (const key of ['included_items','facility_items']) {
    if (!Array.isArray(input[key])) throw Error(`Missing ${key}`);
    deal[key] = input[key].map(row => ({icon:clean(row.icon),label:required(row.label,'label'),detail:clean(row.detail)}));
  }
  const canonical = `${ORIGIN}/deals/${slug}`;
  const seoTitle = `${title} · SeasonDeals`;
  const metaDescription = description.length <= 160 ? description : `${description.slice(0,157).trimEnd()}…`;
  // No Offer/InStock/reviews: current bookability is not guaranteed by publication.
  const schema = {'@context':'https://schema.org','@type':'WebPage',url:canonical,name:seoTitle,description:metaDescription,
    inLanguage:'nl-NL',about:{'@type':'Hotel',name:deal.hotel_name},image:photos};
  const jsonLd = JSON.stringify(schema).replace(/</g,'\\u003c').replace(/>/g,'\\u003e').replace(/&/g,'\\u0026');
  return {id:input.id,slug,canonical,includeInSitemap:indexable === true,seoTitle,metaDescription,
    html:render(deal),head:`<title>${esc(seoTitle)}</title>\n<meta name="description" content="${esc(metaDescription)}">\n<link rel="canonical" href="${esc(canonical)}">\n<meta name="robots" content="${indexable === true ? 'index,follow' : 'noindex,follow'}">\n<meta property="og:title" content="${esc(seoTitle)}">\n<meta property="og:description" content="${esc(metaDescription)}">\n<meta property="og:url" content="${esc(canonical)}">\n<meta property="og:image" content="${esc(photos[0])}">\n<script type="application/ld+json">${jsonLd}</script>`};
}
module.exports = {projectDeal,stableSlug};
