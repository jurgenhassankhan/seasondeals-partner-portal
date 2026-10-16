// Bounded internal preparation: fresh provider offer -> unpublished admin draft. No transactions at provider.
function "supplier/production/import_first_nhow_draft" {
  input {
    text import_id?
  }

  stack {
    function.run "supplier/production/config_status" as $gate
    precondition ($gate.config_valid && $gate.configured_closed) {
      error = "Closed preparation config required"
    }
  
    api.lambda {
      code = "const id=$input.import_id||'SD-PROD-NHOW-20261127-29-2A-RO-V1';if(!/^SD-PROD-NHOW-[A-Z0-9-]{1,80}$/.test(id))throw Error('Invalid bounded import ID');return id;"
      timeout = 5
    } as $import_id
    function.run "supplier/production/preview_amsterdam_hotels" as $metadata
    api.request {
      url = "https://api.liteapi.travel/v3.0/hotels/rates"
      method = "POST"
      params = {
        hotelIds        : ["lp225fcf"]
        occupancies     : [{adults:2}]
        checkin         : "2026-11-27"
        checkout        : "2026-11-29"
        currency        : "EUR"
        guestNationality: "NL"
        maxRatesPerHotel: 50
        includeHotelData: true
        roomMapping     : true
      }
    
      headers = [
        "X-API-Key: " ~ $env.NUITEE_PRODUCTION_API_KEY
        "Content-Type: application/json"
        "Accept: application/json"
      ]
    
      timeout = 30
    } as $rates_http
  
    api.lambda {
      code = """
// BEGIN GENERATED NUITEE CONTENT
// One projection for import, review, protected preview and public responses.
// Source: https://docs.liteapi.travel/reference/post_hotels-rates
function nuiteeDealContent(mapping, hotelId, contentHotel) {
  const hotel = mapping?.hotel, request = mapping?.request;
  const rates = mapping?.offer?.rates;
  const clean = value => typeof value === 'string' ? value.trim() : '';
  const date = value => {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(value || '')) throw Error('Verblijfsdatums ontbreken.');
    const ms = Date.parse(value + 'T00:00:00Z');
    if (!Number.isFinite(ms) || new Date(ms).toISOString().slice(0,10) !== value) throw Error('Ongeldige verblijfsdatum.');
    return ms;
  };
  if (!hotelId || String(hotel?.id) !== String(hotelId) || !clean(hotel?.name) || !request?.hotel_ids?.some(id => String(id) === String(hotelId))) throw Error('Bevestigde hotelgegevens ontbreken.');
  if (!Array.isArray(rates) || rates.length !== 1) throw Error('Eén bevestigd kameraanbod vereist.');
  const rate = rates[0], room = clean(rate.name);
  const nights = (date(request.checkout) - date(request.checkin)) / 86400000;
  if (!Number.isInteger(nights) || nights < 1 || !room) throw Error('Bevestigde kamer en verblijfsduur ontbreken.');
  const adults = rate.adultCount, children = rate.childCount;
  const occupancy = request.occupancies?.[0];
  if (!Number.isInteger(adults) || adults < 1 || !Number.isInteger(children) || children < 0 || request.occupancies?.length !== 1 || occupancy?.adults !== adults || (occupancy.children?.length || 0) !== children) throw Error('Kamerbezetting komt niet overeen met het aanbod.');
  const boards = {
    RO: ['Alleen verblijf', false], BI: ['Ontbijt inbegrepen', true],
    HB: ['Halfpension inbegrepen', true], FB: ['Volpension inbegrepen', true],
    AI: ['All-inclusive', true], DI: ['Diner inbegrepen', false],
    LI: ['Lunch inbegrepen', false], BDI: ['Ontbijt en diner inbegrepen', true],
    BLI: ['Ontbijt en lunch inbegrepen', true], LDI: ['Lunch en diner inbegrepen', false]
  };
  const board = Object.hasOwn(boards, rate.boardType) ? boards[rate.boardType] : null;
  if (!board) throw Error('Bevestigde maaltijdvoorwaarden ontbreken.');
  const stay = `${nights} ${nights === 1 ? 'overnachting' : 'overnachtingen'}`;
  const guests = `${adults} ${adults === 1 ? 'volwassene' : 'volwassenen'}${children ? ` en ${children} ${children === 1 ? 'kind' : 'kinderen'}` : ''}`;
  const dutchDate = value => { const d = new Date(date(value)); return `${d.getUTCDate()} ${['januari','februari','maart','april','mei','juni','juli','augustus','september','oktober','november','december'][d.getUTCMonth()]} ${d.getUTCFullYear()}`; };
  const details = contentHotel?.supplier_details || hotel.supplier_details;
  if (details && String(details.id) !== String(hotelId)) throw Error('Hotelvoorzieningen horen niet bij dit hotel.');
  const facilityNames = [...(Array.isArray(details?.hotelFacilities) ? details.hotelFacilities : []), ...(Array.isArray(details?.facilities) ? details.facilities.map(f => f?.name) : [])].map(clean).filter(Boolean);
  const definitions = [
    ['wifi','Wifi','⌁',/\b(?:wi[ -]?fi|wireless internet)\b/i],
    ['parking','Parkeren','P',/\b(?:parking|parkeren|parkeergelegenheid)\b/i],
    ['late_checkout','Late check-out','◷',/\b(?:late check[ -]?out|laat uitchecken)\b/i],
    ['welcome_drink','Welkomstdrankje','♧',/\b(?:welcome drink|welkomstdrankje)\b/i]
  ];
  const perks = (Array.isArray(rate.perks) ? rate.perks : []).filter(p => clean(p?.name) && ['HOTEL','RATE','ROOM'].includes(p.level));
  const conditional = /if available|subject to|on request|upon request|availability|op aanvraag|beschikbaarheid|voorwaarden/i;
  const unavailable = /\b(?:no|not available|unavailable|niet beschikbaar|geen)\b/i;
  const paid = /surcharge|additional (?:charge|cost)|paid|fee|tegen betaling|toeslag|kosten|\b(?:EUR|USD|GBP)\s*\d|[€$£]\s*\d/i;
  const extras = definitions.map(([key,label,icon,match]) => {
    const benefits = perks.filter(p => match.test(p.name));
    const names = facilityNames.filter(n => match.test(n));
    if (key === 'parking' && clean(details?.parking)) names.push(clean(details.parking));
    const evidence = [...new Set(benefits.length ? benefits.map(p => clean(p.name)) : names)];
    let status = 'unconfirmed';
    if (evidence.some(n => unavailable.test(n))) status = 'unconfirmed';
    else if (benefits.length) status = evidence.some(n => conditional.test(n) || paid.test(n)) ? 'conditional' : 'included';
    else if (names.length) {
      // Only explicit whole facility labels certify a complimentary service. No inference from hotel prose.
      const free = /^(?:free (?:wi[ -]?fi|wireless internet|parking|self parking)|gratis (?:wifi|wi-fi|parkeren))$/i;
      status = names.some(n => paid.test(n)) ? 'paid' : names.some(n => conditional.test(n)) ? 'conditional' : names.every(n => free.test(n)) ? 'included' : 'available';
    }
    const displayEvidence = evidence.map(n => n.replace(/\b(?:free|gratis|complimentary)\b/gi, '').replace(/\s{2,}/g, ' ').trim());
    const statusText = {included:'Inbegrepen',paid:'Tegen betaling',conditional:'Onder voorwaarden',available:'Beschikbaar; kosten niet bevestigd',unconfirmed:'Niet bevestigd door de leverancier'}[status];
    return {key,icon,label,status,detail:[statusText,...displayEvidence].join(' · ')};
  });
  const breakfastPerks = perks.filter(p => /\b(?:breakfast|ontbijt)\b/i.test(p.name));
  const breakfast = board[1] || breakfastPerks.some(p => !conditional.test(p.name) && !paid.test(p.name));
  const included = [
    {icon:'☾',label:stay,detail:`Van ${dutchDate(request.checkin)} tot ${dutchDate(request.checkout)}`},
    {icon:'▱',label:room,detail:'Het aangeboden kamertype'},
    {icon:'♧',label:`Voor ${guests}`,detail:'Bezetting van de aangeboden kamer'}
  ];
  if (rate.boardType !== 'RO') included.push({icon:'☕',label:board[0],detail:'Volgens het geselecteerde tarief'});
  if (!board[1]) for (const perk of breakfastPerks) included.push({icon:'☕',label:'Ontbijt volgens tariefvoorwaarden',detail:clean(perk.name).replace(/\b(?:free|gratis|complimentary)\b/gi,'').trim()});
  for (const extra of extras.filter(e => e.status === 'included')) included.push({icon:extra.icon,label:extra.label,detail:extra.detail});
  // Preserve original benefit conditions; amount is benefit value, never a customer charge.
  return {
    content_verified:true, hotel_name:clean(hotel.name), room_type:room,
    minimum_nights:nights, max_guests:adults+children,
    includes_breakfast:breakfast, board_type:rate.boardType,
    ...Object.fromEntries(extras.map(e => [`includes_${e.key}`,e.status === 'included'])),
    extra_conditions:extras, facility_items:extras.filter(e => !['included','unconfirmed'].includes(e.status)),
    included_items:included, excluded_items:board[1] || breakfastPerks.length ? [] : ['Ontbijt'],
    travel_period_start:date(request.checkin), travel_period_end:date(request.checkout),
    title:`${stay} bij ${clean(hotel.name)}`,
    short_description:`${stay} in ${room} voor ${guests}.${rate.boardType === 'RO' ? '' : ' ' + board[0] + '.'}`,
    long_description:`Verblijf van ${dutchDate(request.checkin)} tot ${dutchDate(request.checkout)} bij ${clean(hotel.name)}. Eén ${room} voor ${guests}. ${rate.boardType === 'RO' ? '' : board[0] + '.'}${breakfastPerks.length ? ' ' + breakfastPerks.map(p => clean(p.name).replace(/\b(?:free|gratis|complimentary)\b/gi,'').trim()).join('. ') + '.' : ''}`
  };
}
// END GENERATED NUITEE CONTENT
        const response=$var.rates_http.response, hotel=$var.metadata.hotels?.find(h=>h.id==='lp225fcf');
        if(response.status!==200||(response.result?.sandbox!=null&&response.result.sandbox!==false)||!hotel||!Array.isArray(response.result.data)) return {valid:false,reason:'Verified production response and hotel metadata required'};
        const offers=response.result.data.filter(h=>h.hotelId==='lp225fcf').flatMap(h=>h.roomTypes||[]);
        const candidates=offers.filter(o=>o.rateType==='standard'&&o.offerId&&o.offerRetailRate?.currency==='EUR'&&Number.isFinite(o.offerRetailRate.amount)&&o.offerRetailRate.amount>0&&o.rates?.length===1&&o.rates.every(r=>r.mappedRoomId&&r.adultCount===2&&r.childCount===0&&r.boardType==='RO'&&r.cancellationPolicies?.refundableTag==='NRFN'&&Array.isArray(r.retailRate?.taxesAndFees)&&r.retailRate.taxesAndFees.every(t=>t.included===true&&t.currency==='EUR'&&Number.isFinite(t.amount)&&t.amount>=0)));
        candidates.sort((a,b)=>a.offerRetailRate.amount-b.offerRetailRate.amount);
        const offer=candidates[0];if(!offer)return {valid:false,reason:'No standard NRFN room-only offer without excluded fees'};
        const base=offer.offerRetailRate.amount;const suggested=offer.rates[0].retailRate.suggestedSellingPrice?.find(p=>p.currency==='EUR')?.amount;
        if(!Number.isFinite(suggested)||suggested<=0)return {valid:false,reason:'Public price reference missing'};
        // BEGIN GENERATED PRICING
// Owner-approved estimates; never label these as verified account tariffs.
// Stripe EUR reserve: https://stripe.com/nl/pricing/local-payment-methods (2026-10-16).
// Nuitée: last measured sandbox processing fee, not a confirmed production tariff.
const supplierPricingDefaults = Object.freeze({
  mode: 'percentage', markup_percentage: 20, markup_amount: 0, override_amount: 0,
  discount_percentage: 0, min_margin_amount: 20, rounding: 'none',
  processing_fee: 2.30, stripe_fee_percentage: 3.15, stripe_fee_fixed: 0.25,
  calculation_basis: 'costs_included_v2', defaults_version: '20261016-2',
  production_costs_verified: false, cost_status: 'estimated',
  cost_policy: 'owner_approved_estimate_v1',
  cost_evidence: 'Owner-approved estimate 2026-10-16: Nuitée sandbox 2.30 EUR; Stripe EUR card reserve 3.15% + 0.25 EUR; iDEAL reference 0.29 EUR. Account tariffs not verified.',
  payment_method: 'ACC_CREDIT_CARD'
});

function supplierPricingConfig(saved = {}, proposal = false) {
  const config = {...supplierPricingDefaults, ...saved};
  // Missing stored costs inherit approved estimates; explicit zero stays zero.
  for (const key of ['processing_fee','stripe_fee_percentage','stripe_fee_fixed']) {
    config[key] = saved[key] ?? supplierPricingDefaults[key];
  }
  if (['processing_fee','stripe_fee_percentage','stripe_fee_fixed'].some(key=>saved[key] == null) || saved.production_costs_verified !== true) {
    config.production_costs_verified = false;
    config.cost_status = 'estimated';
    config.cost_policy = supplierPricingDefaults.cost_policy;
    config.cost_evidence = saved.cost_evidence || supplierPricingDefaults.cost_evidence;
  }
  if (proposal) config.mode = 'percentage';
  return config;
}

function acceptedSupplierCosts(config) {
  return !!config && config.payment_method === 'ACC_CREDIT_CARD' && !!config.cost_evidence &&
    (config.production_costs_verified === true ||
     (config.cost_status === 'estimated' && config.cost_policy === 'owner_approved_estimate_v1'));
}

function calculateSupplierPrice(base, config) {
  const names = {processing_fee:'Nuitée kosten',stripe_fee_percentage:'Stripe kosten (%)',stripe_fee_fixed:'Stripe kosten (€)',markup_percentage:'Jouw opslag (%)',markup_amount:'Jouw opslag (€)',override_amount:'Verkoopprijs',discount_percentage:'Korting',min_margin_amount:'Minimaal overhouden'};
  const active = config.mode === 'percentage' ? 'markup_percentage' : config.mode === 'fixed' ? 'markup_amount' : 'override_amount';
  if (!['percentage','fixed','override'].includes(config.mode)) throw Error('Kies een geldige prijsregel.');
  for (const key of ['processing_fee','stripe_fee_percentage','stripe_fee_fixed','discount_percentage','min_margin_amount',active]) {
    if (config[key] == null || config[key] === '') throw Error(names[key] + ': standaardtarief nog te bevestigen.');
    if (typeof config[key] !== 'number' || !Number.isFinite(config[key]) || config[key] < 0) throw Error(names[key] + ': vul een geldig bedrag in.');
  }
  if (!Number.isFinite(base) || base <= 0) throw Error('Inkoopprijs (Nuitée) ontbreekt.');
  const rate = config.stripe_fee_percentage / 100;
  const discount = 1 - config.discount_percentage / 100;
  if (rate >= 1 || discount <= 0 || discount > 1) throw Error('Kosten en korting moeten lager zijn dan 100%.');
  const fixedCost = base + config.processing_fee + config.stripe_fee_fixed;
  let raw = config.override_amount;
  if (config.mode === 'percentage') {
    const factor = 1 + config.markup_percentage / 100;
    const denominator = 1 - factor * rate;
    if (denominator <= 0) throw Error('Deze opslag en Stripe kosten leveren geen geldige verkoopprijs op.');
    raw = fixedCost * factor / denominator;
  } else if (config.mode === 'fixed') {
    raw = (fixedCost + config.markup_amount) / (1 - rate);
  }
  raw *= discount;
  // Avoid adding a cent to an exact integer due to floating-point noise.
  const ceil = n => Math.ceil(n - 1e-9);
  if (!['none','whole','99'].includes(config.rounding)) throw Error('Kies een geldige afronding.');
  const amount = config.rounding === 'whole' ? ceil(raw) : config.rounding === '99' ? (ceil(raw - .99) * 100 + 99) / 100 : ceil(raw * 100) / 100;
  const stripeCost = amount * rate + config.stripe_fee_fixed;
  const estimatedMargin = amount - base - config.processing_fee - stripeCost;
  if (!Number.isFinite(amount) || amount <= 0 || estimatedMargin + 1e-9 < config.min_margin_amount) throw Error('Je houdt minder over dan het ingestelde minimum.');
  return {amount, estimatedMargin, stripeCost, totalCost: base + config.processing_fee + stripeCost};
}
// END GENERATED PRICING
        const pricing=supplierPricingConfig();
        let price;
        try { price=calculateSupplierPrice(base,pricing).amount; pricing.price_status='proposal_requires_review'; }
        catch(error) { price=Math.ceil(Math.max(suggested,base*1.20)*100)/100; pricing.price_status='proposal_requires_costs'; }
        pricing.override_amount=price;
        const hotelContent={...hotel,images:[]};
        const request={hotel_ids:['lp225fcf'],occupancies:[{adults:2}],checkin:'2026-11-27',checkout:'2026-11-29',currency:'EUR',guest_nationality:'NL'};
        const content=nuiteeDealContent({hotel:hotelContent,request,offer},hotel.id);
        return {valid:true,content,hotel:hotelContent,offer,base,price,checked_at:Date.now(),mapping:{provider:'nuitee',environment:'production',import_id:$var.import_id,hotel:hotelContent,request,offer,checked_at:Date.now(),credential_source:'NUITEE_PRODUCTION_API_KEY',provider_sandbox:response.result.sandbox??null,environment_evidence:'dedicated_production_credential; response_has_no_environment_marker',import_version:3,deal_content:content},pricing,start:Date.parse('2026-11-27T00:00:00Z'),end:Date.parse('2026-11-29T00:00:00Z')};
        """
      timeout = 5
    } as $prepared
  
    precondition ($prepared.valid) {
      error = $prepared.reason
    }
  
    api.request {
      url = "https://api.liteapi.travel/v3.0/data/hotel?hotelId=lp225fcf"
      method = "GET"
      headers = ["Accept: application/json", "X-API-Key: " ~ $env.NUITEE_PRODUCTION_API_KEY]
      timeout = 30
    } as $room_details
    api.lambda {
      code = """
const response=$var.room_details.response,h=response.result?.data,rate=$var.prepared.offer.rates[0];
if(response.status!==200||h?.id!=='lp225fcf')throw Error('Hotel details mismatch');
const room=h.rooms?.find(r=>String(r.id)===String(rate.mappedRoomId));
if(!room?.photos?.length)throw Error('Confirmed room photos required');
return room.photos.map(p=>({url:p.hd_url||p.url,caption:rate.name,scope:'matched_room'}));
"""
      timeout = 5
    } as $room_candidates
    function.run "supplier/production/select_room_photos" {
      input = {photos: $room_candidates}
    } as $photo_selection
    api.lambda {
      code = """
// BEGIN GENERATED NUITEE CONTENT
// One projection for import, review, protected preview and public responses.
// Source: https://docs.liteapi.travel/reference/post_hotels-rates
function nuiteeDealContent(mapping, hotelId, contentHotel) {
  const hotel = mapping?.hotel, request = mapping?.request;
  const rates = mapping?.offer?.rates;
  const clean = value => typeof value === 'string' ? value.trim() : '';
  const date = value => {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(value || '')) throw Error('Verblijfsdatums ontbreken.');
    const ms = Date.parse(value + 'T00:00:00Z');
    if (!Number.isFinite(ms) || new Date(ms).toISOString().slice(0,10) !== value) throw Error('Ongeldige verblijfsdatum.');
    return ms;
  };
  if (!hotelId || String(hotel?.id) !== String(hotelId) || !clean(hotel?.name) || !request?.hotel_ids?.some(id => String(id) === String(hotelId))) throw Error('Bevestigde hotelgegevens ontbreken.');
  if (!Array.isArray(rates) || rates.length !== 1) throw Error('Eén bevestigd kameraanbod vereist.');
  const rate = rates[0], room = clean(rate.name);
  const nights = (date(request.checkout) - date(request.checkin)) / 86400000;
  if (!Number.isInteger(nights) || nights < 1 || !room) throw Error('Bevestigde kamer en verblijfsduur ontbreken.');
  const adults = rate.adultCount, children = rate.childCount;
  const occupancy = request.occupancies?.[0];
  if (!Number.isInteger(adults) || adults < 1 || !Number.isInteger(children) || children < 0 || request.occupancies?.length !== 1 || occupancy?.adults !== adults || (occupancy.children?.length || 0) !== children) throw Error('Kamerbezetting komt niet overeen met het aanbod.');
  const boards = {
    RO: ['Alleen verblijf', false], BI: ['Ontbijt inbegrepen', true],
    HB: ['Halfpension inbegrepen', true], FB: ['Volpension inbegrepen', true],
    AI: ['All-inclusive', true], DI: ['Diner inbegrepen', false],
    LI: ['Lunch inbegrepen', false], BDI: ['Ontbijt en diner inbegrepen', true],
    BLI: ['Ontbijt en lunch inbegrepen', true], LDI: ['Lunch en diner inbegrepen', false]
  };
  const board = Object.hasOwn(boards, rate.boardType) ? boards[rate.boardType] : null;
  if (!board) throw Error('Bevestigde maaltijdvoorwaarden ontbreken.');
  const stay = `${nights} ${nights === 1 ? 'overnachting' : 'overnachtingen'}`;
  const guests = `${adults} ${adults === 1 ? 'volwassene' : 'volwassenen'}${children ? ` en ${children} ${children === 1 ? 'kind' : 'kinderen'}` : ''}`;
  const dutchDate = value => { const d = new Date(date(value)); return `${d.getUTCDate()} ${['januari','februari','maart','april','mei','juni','juli','augustus','september','oktober','november','december'][d.getUTCMonth()]} ${d.getUTCFullYear()}`; };
  const details = contentHotel?.supplier_details || hotel.supplier_details;
  if (details && String(details.id) !== String(hotelId)) throw Error('Hotelvoorzieningen horen niet bij dit hotel.');
  const facilityNames = [...(Array.isArray(details?.hotelFacilities) ? details.hotelFacilities : []), ...(Array.isArray(details?.facilities) ? details.facilities.map(f => f?.name) : [])].map(clean).filter(Boolean);
  const definitions = [
    ['wifi','Wifi','⌁',/\b(?:wi[ -]?fi|wireless internet)\b/i],
    ['parking','Parkeren','P',/\b(?:parking|parkeren|parkeergelegenheid)\b/i],
    ['late_checkout','Late check-out','◷',/\b(?:late check[ -]?out|laat uitchecken)\b/i],
    ['welcome_drink','Welkomstdrankje','♧',/\b(?:welcome drink|welkomstdrankje)\b/i]
  ];
  const perks = (Array.isArray(rate.perks) ? rate.perks : []).filter(p => clean(p?.name) && ['HOTEL','RATE','ROOM'].includes(p.level));
  const conditional = /if available|subject to|on request|upon request|availability|op aanvraag|beschikbaarheid|voorwaarden/i;
  const unavailable = /\b(?:no|not available|unavailable|niet beschikbaar|geen)\b/i;
  const paid = /surcharge|additional (?:charge|cost)|paid|fee|tegen betaling|toeslag|kosten|\b(?:EUR|USD|GBP)\s*\d|[€$£]\s*\d/i;
  const extras = definitions.map(([key,label,icon,match]) => {
    const benefits = perks.filter(p => match.test(p.name));
    const names = facilityNames.filter(n => match.test(n));
    if (key === 'parking' && clean(details?.parking)) names.push(clean(details.parking));
    const evidence = [...new Set(benefits.length ? benefits.map(p => clean(p.name)) : names)];
    let status = 'unconfirmed';
    if (evidence.some(n => unavailable.test(n))) status = 'unconfirmed';
    else if (benefits.length) status = evidence.some(n => conditional.test(n) || paid.test(n)) ? 'conditional' : 'included';
    else if (names.length) {
      // Only explicit whole facility labels certify a complimentary service. No inference from hotel prose.
      const free = /^(?:free (?:wi[ -]?fi|wireless internet|parking|self parking)|gratis (?:wifi|wi-fi|parkeren))$/i;
      status = names.some(n => paid.test(n)) ? 'paid' : names.some(n => conditional.test(n)) ? 'conditional' : names.every(n => free.test(n)) ? 'included' : 'available';
    }
    const displayEvidence = evidence.map(n => n.replace(/\b(?:free|gratis|complimentary)\b/gi, '').replace(/\s{2,}/g, ' ').trim());
    const statusText = {included:'Inbegrepen',paid:'Tegen betaling',conditional:'Onder voorwaarden',available:'Beschikbaar; kosten niet bevestigd',unconfirmed:'Niet bevestigd door de leverancier'}[status];
    return {key,icon,label,status,detail:[statusText,...displayEvidence].join(' · ')};
  });
  const breakfastPerks = perks.filter(p => /\b(?:breakfast|ontbijt)\b/i.test(p.name));
  const breakfast = board[1] || breakfastPerks.some(p => !conditional.test(p.name) && !paid.test(p.name));
  const included = [
    {icon:'☾',label:stay,detail:`Van ${dutchDate(request.checkin)} tot ${dutchDate(request.checkout)}`},
    {icon:'▱',label:room,detail:'Het aangeboden kamertype'},
    {icon:'♧',label:`Voor ${guests}`,detail:'Bezetting van de aangeboden kamer'}
  ];
  if (rate.boardType !== 'RO') included.push({icon:'☕',label:board[0],detail:'Volgens het geselecteerde tarief'});
  if (!board[1]) for (const perk of breakfastPerks) included.push({icon:'☕',label:'Ontbijt volgens tariefvoorwaarden',detail:clean(perk.name).replace(/\b(?:free|gratis|complimentary)\b/gi,'').trim()});
  for (const extra of extras.filter(e => e.status === 'included')) included.push({icon:extra.icon,label:extra.label,detail:extra.detail});
  // Preserve original benefit conditions; amount is benefit value, never a customer charge.
  return {
    content_verified:true, hotel_name:clean(hotel.name), room_type:room,
    minimum_nights:nights, max_guests:adults+children,
    includes_breakfast:breakfast, board_type:rate.boardType,
    ...Object.fromEntries(extras.map(e => [`includes_${e.key}`,e.status === 'included'])),
    extra_conditions:extras, facility_items:extras.filter(e => !['included','unconfirmed'].includes(e.status)),
    included_items:included, excluded_items:board[1] || breakfastPerks.length ? [] : ['Ontbijt'],
    travel_period_start:date(request.checkin), travel_period_end:date(request.checkout),
    title:`${stay} bij ${clean(hotel.name)}`,
    short_description:`${stay} in ${room} voor ${guests}.${rate.boardType === 'RO' ? '' : ' ' + board[0] + '.'}`,
    long_description:`Verblijf van ${dutchDate(request.checkin)} tot ${dutchDate(request.checkout)} bij ${clean(hotel.name)}. Eén ${room} voor ${guests}. ${rate.boardType === 'RO' ? '' : board[0] + '.'}${breakfastPerks.length ? ' ' + breakfastPerks.map(p => clean(p.name).replace(/\b(?:free|gratis|complimentary)\b/gi,'').trim()).join('. ') + '.' : ''}`
  };
}
// END GENERATED NUITEE CONTENT
const p=$var.prepared,r=p.offer.rates[0],selection=$var.photo_selection,at=Date.now();
const h=$var.room_details.response.result.data;
const hotel={...p.hotel,supplier_details:{id:h.id,hotelFacilities:Array.isArray(h.hotelFacilities)?h.hotelFacilities:[],facilities:Array.isArray(h.facilities)?h.facilities.map(f=>({facilityId:f.facilityId,name:f.name})):[],parking:typeof h.parking==='string'?h.parking:'',checked_at:Date.now()},images:selection.photos.map(p=>p.url),photo_gallery:selection.photos,photos_checked_at:at,room_photos_matched:true,photo_hotel_id:'lp225fcf',mapped_room_id:r.mappedRoomId,photo_rate_name:r.name,room_photo_binding:{source:'offer_mapped_room_id',hotel_id:'lp225fcf',rate_name:r.name,mapped_room_id:r.mappedRoomId,adult_count:r.adultCount,child_count:r.childCount,checked_at:at},photo_verification:{status:'verified',algorithm:selection.algorithm,max_photos:5,checked_at:at}};
const mapping={...p.mapping,hotel};
const content=nuiteeDealContent(mapping,hotel.id);
return {...p,content,hotel,mapping:{...mapping,deal_content:content}};
"""
      timeout = 5
    } as $with_photos
    var.update $prepared { value = $with_photos }

    db.query admin_users {
      return = {type: "single"}
    } as $owner
  
    precondition ($owner != null && $owner.role == "superadmin") {
      error = "Workspace owner lock required"
    }
  
    var $result {
      value = null
    }
  
    db.transaction {
      stack {
        db.get admin_users {
          field_name = "id"
          field_value = $owner.id
          lock = true
        } as $import_lock
      
        db.query deals {
          where = $db.deals.external_id == $import_id
          return = {type: "single"}
        } as $existing
      
        conditional {
          if ($existing != null) {
            var.update $result {
              value = {
                deal_id: $existing.id
                status : $existing.status
                created: false
                public : false
              }
            }
          }
        
          else {
            db.add deals {
              data = {
                hotel_id           : 0
                title              : $prepared.content.title
                description        : $prepared.content.short_description
                short_description  : $prepared.content.short_description
                long_description   : $prepared.content.long_description
                price              : $prepared.price
                deal_price         : $prepared.price
                inventory          : 0
                sold_quantity      : 0
                status             : "draft"
                is_active          : false
                source             : "provider_sync"
                external_id        : $import_id
                hotel_name         : $prepared.hotel.name
                city               : $prepared.hotel.city
                country            : "NL"
                address            : $prepared.hotel.address
                star_rating        : $prepared.hotel.stars
                review_score       : $prepared.hotel.rating
                external_image_urls: $prepared.hotel.images
                room_type          : $prepared.offer.rates[0].name
                includes_breakfast : $prepared.content.includes_breakfast
                max_guests         : $prepared.content.max_guests
                minimum_nights     : $prepared.content.minimum_nights
                travel_period_start: $prepared.start
                travel_period_end  : $prepared.end
                cancellation_policy: "Niet restitueerbaar: bij annulering is het volledige verblijfsbedrag verschuldigd."
                review_notes       : "Productieconcept. Verkoopprijs is een voorstel; ACC-/Stripekosten en marge nog te bevestigen. Niet goedgekeurd of publiek."
                updated_at         : now
              }
            } as $new_deal
          
            db.add supplier_deals {
              data = {
                deal_id             : $new_deal.id
                provider            : "nuitee"
                environment         : "production"
                supplier_hotel_id   : "lp225fcf"
                supplier_mapping    : $prepared.mapping
                supplier_content    : $prepared.mapping
                supplier_base_amount: $prepared.base
                pricing_config      : $prepared.pricing
                sync_status         : "pending_review"
                is_enabled          : false
                last_synced_at      : now
              }
            } as $new_supplier
          
            var.update $result {
              value = {
                deal_id                  : $new_deal.id
                supplier_deal_id         : $new_supplier.id
                status                   : "draft"
                created                  : true
                public                   : false
                price_proposal           : $prepared.price
                production_costs_verified: false
                photo_count              : ($prepared.hotel.images|count)
              }
            }
          }
        }
      }
    }
  }

  response = $result
  history = false
}