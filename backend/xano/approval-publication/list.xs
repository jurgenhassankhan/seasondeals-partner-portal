//  Haal alle actieve deals op met gekoppelde hotelinformatie.
//  Filtert op status = active en voert een left join uit naar de hotels tabel.
//  Retourneer de geformatteerde lijst met deals.
//  Geen input parameters toegestaan voor hotel_id.
// 
//  BEVROREN: Officieel API Contract (Webflow)
//  Dit endpoint retourneert alle 44 velden uit de deals tabel.
//  Legacy velden 'image' en 'hotel' zijn behouden voor backward compatibility.
query deals verb=GET {
  api_group = "Public API"

  input {
  }

  stack {
    // Haal de deals op en voeg de hotelnaam toe via een join naar de hotels tabel.
    db.query deals {
      join = {
        hotels            : {
          table: "hotels"
          type : "left"
          where: $db.deals.hotel_id == $db.hotels.id
        }
        hotel_integrations: {
          table: "hotel_integrations"
          type : "left"
          where: $db.deals.hotel_integration_id == $db.hotel_integrations.id
        }
      }
    
      where = ($db.deals.source == null || $db.deals.source != "provider_sync") && $db.deals.status == "active" && (($db.deals.hotel_integration_id == null || $db.deals.hotel_integration_id == 0) || ($db.hotel_integrations.environment == "production" && $db.hotel_integrations.status == "active"))
      eval = {hotel_name: $db.hotels.name}
      return = {type: "list"}
    } as $deals
  
    // Structureer de response voor Webflow (Alle contractvelden + Legacy support).
    array.map ($deals) {
      by = $this
        |set:"image":($this.images|first)
        |set:"hotel":```
          {
            name: $this.hotel_name,
            city: $this.city,
            star_rating: $this.star_rating
          }
          ```
    } as $result
    db.query deals {
      join = {
        supplier_deals: {
          table: "supplier_deals"
          type: "inner"
          where: $db.deals.id == $db.supplier_deals.deal_id
        }
      }
      where = $db.deals.source == "provider_sync" && $db.deals.status == "active" && $db.deals.is_active == true && $db.deals.approved_at != null && ($db.deals.deleted_at == null || $db.deals.deleted_at == 0) && $db.supplier_deals.provider == "nuitee" && $db.supplier_deals.environment == "production" && $db.supplier_deals.is_enabled == true
      eval = {content_hotel: $db.supplier_deals.supplier_content.hotel, content_mapping: $db.supplier_deals.supplier_mapping, content_hotel_id: $db.supplier_deals.supplier_hotel_id}
      return = {type: "list"}
    } as $supplier_public_rows
    function.run "supplier/production/config_status" { input = {} } as $production_status
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
const fields = ['id','title','description','short_description','long_description','price','deal_price','original_price','source','status','is_active','city','country','address','star_rating','review_score','review_count','room_type','includes_breakfast','includes_wifi','includes_parking','includes_late_checkout','includes_welcome_drink','max_guests','minimum_nights','travel_period_start','travel_period_end','cancellation_policy','category'];
function project(d) {
  let content;
  try { content = nuiteeDealContent(d.content_mapping, d.content_hotel_id, d.content_hotel); } catch (_) { return null; }
  const result = Object.fromEntries(fields.filter(k => d[k] !== undefined).map(k => [k,d[k]]));
  const values = [...(Array.isArray(d.external_image_urls) ? d.external_image_urls : []), ...(Array.isArray(d.images) ? d.images : [])];
  result.images = values.map(v => typeof v === 'string' ? v : v?.url).filter(v => typeof v === 'string' && v.startsWith('https://'));
  result.image = result.images[0] || null;
  const {title,short_description,long_description,...facts} = content;
  Object.assign(result, facts);
  result.hotel = {name: result.hotel_name, city: d.city, star_rating: d.star_rating};
  result.inventory = null;
  result.booking_enabled = $var.production_status.can_sell === true;
  return result;
}
return [...$var.result, ...$var.supplier_public_rows.map(project).filter(Boolean)];
"""
      timeout = 5
    } as $public_result
  }

  response = $public_result
}
