query "supplier-deals/{deal_id}/workflow" verb=PATCH {
  api_group = "Admin"
  auth = "admin_users"

  input {
    int deal_id
    enum action {
      values = ["save_content", "submit", "active", "rejected", "draft"]
    }
  
    text title? filters=trim
    text short_description? filters=trim
    text long_description? filters=trim
    text cancellation_policy? filters=trim
    text rejection_reason? filters=trim
    text review_notes? filters=trim
  }

  stack {
    function.run "admin/guard" {
      input = {permission: null}
    } as $admin
  
    precondition ($admin.role == "superadmin" || $admin.role == "platform_admin") {
      error_type = "accessdenied"
      error = "Alleen bevoegde beheerders mogen Nuitée-deals wijzigen."
    }
  
    var $result { value = null }
    db.transaction {
      stack {
    db.get deals {
      field_name = "id"
      field_value = $input.deal_id
      lock = true
    } as $deal
  
    precondition ($deal != null && ($deal.deleted_at == null || $deal.deleted_at == 0)) {
      error_type = "notfound"
      error = "Deal niet gevonden."
    }
  
    db.query supplier_deals {
      where = $db.supplier_deals.deal_id == $deal.id && $db.supplier_deals.provider == "nuitee"
      return = {type: "single"}
    } as $supplier
  
    precondition ($supplier != null) {
      error_type = "inputerror"
      error = "Dit is geen Nuitée-deal."
    }
  
    precondition ($supplier.environment == "sandbox" || $supplier.environment == "production") {
      error_type = "inputerror"
      error = "Onbekende leveranciersomgeving."
    }
  
    var.update $result {
      value = $deal
    }
  
    conditional {
      if ($input.action == "save_content") {
        precondition ($deal.status == "draft") {
          error_type = "inputerror"
          error = "Inhoud kan alleen in concept worden gewijzigd."
        }
      
        precondition ($input.title != null && $input.title != "") {
          error_type = "inputerror"
          error = "Titel is verplicht."
        }
      
        db.edit deals {
          field_name = "id"
          field_value = $deal.id
          data = {
            title              : $input.title
            short_description  : $input.short_description
            long_description   : $input.long_description
            cancellation_policy: $input.cancellation_policy
            updated_at         : now
          }
        } as $saved
      
        var.update $result {
          value = $saved
        }
      }
    
      elseif ($input.action == "submit" || $input.action == "active") {
        precondition (($input.action == "submit" && $deal.status == "draft") || ($input.action == "active" && $deal.status == "pending_approval")) {
          error_type = "inputerror"
          error = "Ongeldige statusovergang."
        }
      
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
const supplier=$var.supplier,hotel=supplier.supplier_content?.hotel||{};
try { nuiteeDealContent(supplier.supplier_mapping,supplier.supplier_hotel_id,supplier.supplier_content?.hotel); } catch (_) { return false; }
const photos=hotel.photo_gallery,urls=$var.deal.external_image_urls,rateName=supplier.supplier_mapping?.offer?.rates?.[0]?.name;
if(hotel.photo_verification?.status!=='verified'||!['sha256+dhash64-v1','sha256+dhash64-area-v2'].includes(hotel.photo_verification?.algorithm)||hotel.room_photos_matched!==true||!hotel.mapped_room_id||hotel.photo_rate_name!==rateName||hotel.photo_hotel_id!==supplier.supplier_hotel_id)return false;
const rate=supplier.supplier_mapping?.offer?.rates?.[0],binding=hotel.room_photo_binding;
const direct=rate?.mappedRoomId&&String(hotel.mapped_room_id)===String(rate.mappedRoomId);
const confirmed=binding?.source==='provider_exact_room_name'&&binding.hotel_id===supplier.supplier_hotel_id&&binding.rate_name===rate?.name&&binding.adult_count===rate.adultCount&&binding.child_count===rate.childCount&&String(binding.mapped_room_id)===String(hotel.mapped_room_id);
if(rate?.mappedRoomId ? !direct : !confirmed)return false;
if(!Array.isArray(photos)||!Array.isArray(urls)||photos.length<1||photos.length>5||urls.length!==photos.length)return false;
const distance=(a,b)=>{let n=BigInt('0x'+a)^BigInt('0x'+b),bits=0;while(n){bits+=Number(n&1n);n>>=1n;}return bits;};
for(let i=0;i<photos.length;i++){
 const p=photos[i];
 if(p.scope!=='matched_room'||p.url!==urls[i]||!/^https:\/\//.test(p.url)||!(/^[a-f0-9]{64}$/.test(p.sha256))||!(/^[a-f0-9]{16}$/.test(p.dhash)))return false;
 for(let j=0;j<i;j++)if(p.url===photos[j].url||p.sha256===photos[j].sha256||distance(p.dhash,photos[j].dhash)<=5)return false;
}
return true;
"""
          timeout = 5
        } as $photos_verified
        precondition ($photos_verified) {
          error_type = "inputerror"
          error = "De leveranciersgegevens en kamerfoto’s moeten compleet zijn: hotel, verblijfsdatums, kamerbezetting, maaltijdvoorwaarden en gecontroleerde losse foto’s."
        }

        precondition ($deal.title != "" && $deal.short_description != null && $deal.short_description != "" && $deal.long_description != null && $deal.long_description != "" && $deal.cancellation_policy != null && $deal.cancellation_policy != "") {
          error_type = "inputerror"
          error = "Vul eerst titel, korte en uitgebreide omschrijving en annuleringsvoorwaarden in."
        }
      
        precondition ($supplier.supplier_hotel_id != "" && $supplier.supplier_base_amount > 0 && $supplier.pricing_config.min_margin_amount != null) {
          error_type = "inputerror"
          error = "Leveranciersmapping en prijsregels zijn verplicht."
        }
      
        precondition ($supplier.pricing_config.processing_fee != null && $supplier.pricing_config.stripe_fee_percentage != null && $supplier.pricing_config.stripe_fee_fixed != null && $supplier.pricing_config.processing_fee >= 0 && $supplier.pricing_config.stripe_fee_percentage >= 0 && $supplier.pricing_config.stripe_fee_percentage < 100 && $supplier.pricing_config.stripe_fee_fixed >= 0) {
          error_type = "inputerror"
          error = "Controleer en sla eerst de kosten en prijsregels op."
        }
      
        var $margin {
          value = $deal.price - $supplier.supplier_base_amount - $supplier.pricing_config.processing_fee - ($deal.price * $supplier.pricing_config.stripe_fee_percentage / 100) - $supplier.pricing_config.stripe_fee_fixed
        }
      
        precondition ($deal.price > 0 && $margin >= $supplier.pricing_config.min_margin_amount) {
          error_type = "inputerror"
          error = "Minimummarge na kostenreserve niet gehaald."
        }
      
        conditional {
          if ($input.action == "submit") {
            db.edit deals {
              field_name = "id"
              field_value = $deal.id
              data = {
                status      : "pending_approval"
                is_active   : false
                submitted_at: now
                updated_at  : now
              }
            } as $submitted
          
            var.update $result {
              value = $submitted
            }
          }
        
          else {
            db.edit deals {
              field_name = "id"
              field_value = $deal.id
              data = {
                status      : "active"
                is_active   : ($supplier.environment == "production")
                approved_at : now
                review_notes: $input.review_notes
                updated_at  : now
              }
            } as $approved
          
            var.update $result {
              value = $approved
            }
          }
        }
      }
    
      elseif ($input.action == "rejected") {
        precondition ($deal.status == "pending_approval" && $input.rejection_reason != null && $input.rejection_reason != "") {
          error_type = "inputerror"
          error = "Afwijzen vereist een ingediende deal en een reden."
        }
      
        db.edit deals {
          field_name = "id"
          field_value = $deal.id
          data = {
            status          : "rejected"
            is_active       : false
            rejected_at     : now
            rejection_reason: $input.rejection_reason
            review_notes    : $input.review_notes
            updated_at      : now
          }
        } as $rejected
      
        var.update $result {
          value = $rejected
        }
      }
    
      else {
        precondition ($deal.status == "pending_approval" || $deal.status == "rejected" || $deal.status == "active") {
          error_type = "inputerror"
          error = "Deze deal staat al in concept."
        }
      
        db.edit deals {
          field_name = "id"
          field_value = $deal.id
          data = {
            status          : "draft"
            is_active       : false
            submitted_at    : null
            approved_at     : null
            rejected_at     : null
            rejection_reason: null
            updated_at      : now
          }
        } as $draft
      
        var.update $result {
          value = $draft
        }
      }
    }
  
    conditional {
      if ($supplier.environment == "production") {
    db.edit supplier_deals {
      field_name = "id"
      field_value = $supplier.id
      data = {is_enabled: ($supplier.environment == "production" && $result.status == "active")}
    } as $visibility_supplier

      }
    }

    function.run "audit/log" {
      input = {
        user_id       : $auth.id
        user_type     : "admin"
        resource_table: "deals"
        resource_id   : $deal.id
        action        : "supplier_" ~ $input.action
        prev_values   : {status: $deal.status}
        new_values    : {status: $result.status, is_active: $result.is_active}
      }
    } as $audit
      }
    }
  }

  response = {deal: $result}
}
