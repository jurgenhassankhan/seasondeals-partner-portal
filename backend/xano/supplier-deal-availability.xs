// Private, read-only sandbox availability with an unchanged approved selling price.
query "supplier-deals/{deal_id}/availability" verb=GET {
  api_group = "Admin"
  auth = "admin_users"
  input {
    int deal_id
    text checkin filters=trim
    text checkout filters=trim
    int guests
  }
  stack {
    util.set_header {
      value = "Cache-Control: private, no-store"
      duplicates = "replace"
    }
    function.run "admin/guard" {
      input = {permission: null}
    } as $admin
    precondition ($admin.role == "superadmin" || $admin.role == "platform_admin") {
      error_type = "accessdenied"
      error = "Geen toegang tot leverancierscontrole."
    }
    db.query deals {
      where = $db.deals.id == $input.deal_id && ($db.deals.deleted_at == null || $db.deals.deleted_at == 0)
      return = {type: "single"}
    } as $deal
    db.query supplier_deals {
      where = $db.supplier_deals.deal_id == $input.deal_id
      return = {type: "single"}
    } as $supplier
    api.lambda {
      code = """
function validateRequest(deal, supplier, input, now = Date.now()) {
  const fail = (code, message) => ({valid:false,code,message});
  if (!deal || !supplier || supplier.provider !== 'nuitee' || supplier.environment !== 'sandbox') return fail('SANDBOX_ONLY','Deze controle is uitsluitend voor Nuitée-sandboxdeals.');
  if (deal.status !== 'active' || !deal.approved_at || deal.deleted_at) return fail('NOT_APPROVED','Keur de testdeal eerst goed.');
  const dates = [input.checkin,input.checkout].map(v => typeof v === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(v) ? Date.parse(v+'T00:00:00Z') : NaN);
  if (dates.some((v,i) => !Number.isFinite(v) || new Date(v).toISOString().slice(0,10) !== [input.checkin,input.checkout][i]) || dates[1] <= dates[0] || dates[0] < Math.floor(now/86400000)*86400000) return fail('INVALID_DATES','Kies geldige toekomstige verblijfsdata.');
  if (!Number.isFinite(Number(deal.travel_period_start)) || !Number.isFinite(Number(deal.travel_period_end)) || !(Number(deal.travel_period_start)>0) || !(Number(deal.travel_period_end)>Number(deal.travel_period_start)) || dates[0] < Number(deal.travel_period_start) || dates[1] > Number(deal.travel_period_end) || (dates[1]-dates[0])/86400000 < Number(deal.minimum_nights || 1)) return fail('OUTSIDE_DEAL','Dit verblijf valt buiten de goedgekeurde dealperiode of verblijfsduur.');
  const mapping = supplier.supplier_mapping || supplier.supplier_content || {};
  const original = mapping.request;
  if (!original || !Array.isArray(original.occupancies) || original.occupancies.length !== 1 || original.occupancies[0].children?.length || !Number.isInteger(input.guests) || input.guests !== original.occupancies[0].adults) return fail('OCCUPANCY_NOT_APPROVED','Deze deal is goedgekeurd voor de opgeslagen kamerbezetting.');
  const config = supplier.pricing_config;
  if (!config || ['processing_fee','stripe_fee_percentage','stripe_fee_fixed','min_margin_amount'].some(k => typeof config[k] !== 'number' || !Number.isFinite(config[k]) || config[k] < 0) || config.stripe_fee_percentage >= 100 || !(Number(deal.price) > 0) || original.currency !== 'EUR' || !/^[A-Z]{2}$/.test(original.guest_nationality || '') || !supplier.supplier_hotel_id) return fail('INVALID_PRICING_CONFIG','De goedgekeurde prijs- of kostenconfiguratie is onvolledig.');
  return {valid:true,hotel_ids:[supplier.supplier_hotel_id],occupancies:original.occupancies,checkin:input.checkin,checkout:input.checkout,currency:original.currency,guest_nationality:original.guest_nationality};
}
return validateRequest($var.deal, $var.supplier, $input);
      """
      timeout = 5
    } as $request
    conditional {
      if ($request.valid != true) {
        return {
          value = {status: "blocked", available: false, can_pay: false, quantity: null, environment: "sandbox", code: $request.code, message: $request.message}
        }
      }
    }
    function.run "connector/adapters/nuitee/search_rates" {
      input = {hotel_ids: $request.hotel_ids, occupancies: $request.occupancies, checkin: $request.checkin, checkout: $request.checkout, currency: $request.currency, guest_nationality: $request.guest_nationality, max_rates_per_hotel: 50}
    } as $rates
    api.lambda {
      code = """
function evaluateAvailability(deal, supplier, search, now = Date.now()) {
  const base = {deal_id:deal.id,environment:'sandbox',checked_at:now,valid_until:now+60000,quantity:null,quantity_known:false,customer_price:Number(deal.price),currency:'EUR',available:false,can_pay:false};
  const fail = (status,message) => ({...base,status,message});
  if (!search?.success || !Array.isArray(search.data)) return fail('unknown','Beschikbaarheid kon niet worden bevestigd. Probeer opnieuw.');
  const approved = (supplier.supplier_mapping || supplier.supplier_content)?.offer;
  if (!Array.isArray(approved?.rates) || approved.rates.length !== 1) return fail('mapping_required','De goedgekeurde kamermapping is onvolledig.');
  const old = approved.rates[0];
  const canonical = value => JSON.stringify(value, (_key,v) => v && typeof v === 'object' && !Array.isArray(v) ? Object.fromEntries(Object.keys(v).sort().map(k=>[k,v[k]])) : v);
  const offers = search.data.filter(h=>h.hotelId===supplier.supplier_hotel_id).flatMap(h=>Array.isArray(h.roomTypes)?h.roomTypes:[]);
  const compatible = offers.filter(o=>o.offerId && o.supplier===approved.supplier && o.supplierId===approved.supplierId && o.rateType===approved.rateType && o.priceType===approved.priceType && Array.isArray(o.rates) && o.rates.length===1 && o.rates.every(r=>r.name===old.name && r.boardType===old.boardType && r.boardName===old.boardName && r.adultCount===old.adultCount && r.childCount===old.childCount && r.remarks===old.remarks && canonical(r.cancellationPolicies)===canonical(old.cancellationPolicies)));
  if (!compatible.length) return fail('unavailable','Geen actueel aanbod gevonden dat bij deze goedgekeurde deal past.');
  const monetary = (value) => value && value.currency==='EUR' && typeof value.amount==='number' && Number.isFinite(value.amount) && value.amount>0;
  const safe = compatible.filter(o=>monetary(o.offerRetailRate) && o.rates.every(r=>Array.isArray(r.retailRate?.taxesAndFees) && r.retailRate.taxesAndFees.every(t=>typeof t.included==='boolean' && t.currency==='EUR' && typeof t.amount==='number' && Number.isFinite(t.amount) && t.amount>=0)));
  if (!safe.length) return fail('unknown','De actuele prijs of lokale kosten zijn onvolledig. Boeken is geblokkeerd.');
  const oldFees = old.retailRate?.taxesAndFees;
  const feeSignature = values => canonical(values.filter(t=>t.included===false).map(t=>({description:t.description,amount:t.amount,currency:t.currency})).sort((a,b)=>canonical(a).localeCompare(canonical(b))));
  if (!Array.isArray(oldFees)) return fail('mapping_required','De goedgekeurde lokale kosten zijn onvolledig.');
  const unchanged = safe.filter(o=>feeSignature(oldFees)===feeSignature(o.rates[0].retailRate.taxesAndFees));
  if (!unchanged.length) {
    const changed = safe.slice().sort((a,b)=>a.offerRetailRate.amount-b.offerRetailRate.amount)[0];
    const local = changed.rates.flatMap(r=>r.retailRate.taxesAndFees).filter(t=>!t.included).map(t=>({description:t.description,amount:t.amount,currency:t.currency,pay_at_property:true}));
    return {...fail('conditions_changed','De lokale kosten zijn gewijzigd sinds goedkeuring. Controleer de deal opnieuw.'),local_fees:local,local_fees_total:local.reduce((a,t)=>a+Math.round(t.amount*100),0)/100};
  }
  const candidate = unchanged.slice().sort((a,b)=>a.offerRetailRate.amount-b.offerRetailRate.amount)[0];
  const cents = v=>Math.round(v*100);
  const config = supplier.pricing_config;
  const price = cents(deal.price);
  const cost = Math.ceil(candidate.offerRetailRate.amount*100-1e-8);
  // Sandbox reserve floor from the previously verified booking; production must use prebook/payment-method costs.
  const processing = Math.ceil(Math.max(config.processing_fee,1.30)*100-1e-8);
  const stripe = Math.ceil(price*config.stripe_fee_percentage/100 + config.stripe_fee_fixed*100-1e-8);
  const margin = price-cost-processing-stripe;
  if (margin<Math.ceil(config.min_margin_amount*100-1e-8)) return fail('price_blocked','Dit aanbod haalt de ingestelde minimummarge niet tegen de goedgekeurde verkoopprijs.');
  const local = candidate.rates.flatMap(r=>r.retailRate.taxesAndFees).filter(t=>!t.included).map(t=>({description:t.description,amount:t.amount,currency:t.currency,pay_at_property:true}));
  return {...base,status:'available',available:true,message:'Actueel beschikbaar voor dit verblijf. Sandboxcontrole; betaling blijft uitgeschakeld.',supplier_amount:cost/100,processing_reserve:processing/100,stripe_reserve:stripe/100,margin_after_reserve:margin/100,local_fees:local,local_fees_total:local.reduce((a,t)=>a+cents(t.amount),0)/100,cancellation_policies:candidate.rates[0].cancellationPolicies,offer_id:candidate.offerId,room_name:candidate.rates[0].name,board_name:candidate.rates[0].boardName};
}
return evaluateAvailability($var.deal, $var.supplier, $var.rates);
      """
      timeout = 5
    } as $result
  }
  response = $result
}
