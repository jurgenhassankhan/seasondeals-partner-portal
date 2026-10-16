// Separate production implementation; closed by config_status. No release in this change.
function "supplier/production/prepare" {
  input {
    int deal_id
    text checkin filters=trim
    text checkout filters=trim
    int guests
  }

  stack {
    function.run "supplier/production/config_status" as $release_gate
    precondition ($release_gate.can_read) {
      error_type = "accessdenied"
      error = "PRODUCTION_NOT_RELEASED"
    }
  
    db.get deals {
      field_name = "id"
      field_value = $input.deal_id
    } as $before_deal
  
    db.query supplier_deals {
      where = $db.supplier_deals.deal_id == $input.deal_id
      return = {type: "single"}
    } as $before_supplier
  
    function.run "supplier/production/availability" {
      input = {
        deal_id : $input.deal_id
        checkin : $input.checkin
        checkout: $input.checkout
        guests  : $input.guests
      }
    } as $availability
  
    precondition ($availability.available && $availability.environment == "production") {
      error_type = "inputerror"
      error = "No approved, margin-safe production offer is available"
    }
  
    api.request {
      url = "https://book.liteapi.travel/v3.0/rates/prebook?timeout=30"
      method = "POST"
      params = {offerId: $availability.offer_id, usePaymentSdk: false}
      headers = [
        "X-API-Key: " ~ $env.NUITEE_PRODUCTION_API_KEY
        "Content-Type: application/json"
        "Accept: application/json"
      ]
    
      timeout = 30
    } as $prebook_http
  
    var $prebook {
      value = {
        success: ($prebook_http.response.status == 200)
        data   : $prebook_http.response.result.data
      }
    }
  
    db.get deals {
      field_name = "id"
      field_value = $input.deal_id
    } as $deal
  
    db.query supplier_deals {
      where = $db.supplier_deals.deal_id == $input.deal_id
      return = {type: "single"}
    } as $supplier
  
    api.lambda {
      code = """
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
        const a=$var.availability, p=$var.prebook, d=$var.deal, s=$var.supplier;
        const fail=(code,message)=>({ready:false,can_pay:false,environment:'production',code,message});
        const canonical=v=>JSON.stringify(v,(_k,x)=>x&&typeof x==='object'&&!Array.isArray(x)?Object.fromEntries(Object.keys(x).sort().map(k=>[k,x[k]])):x);
        if(!d||!s||d.status!=='active'||!d.approved_at||d.deleted_at||s.provider!=='nuitee'||s.environment!=='production')return fail('NOT_APPROVED','Deal is niet meer goedgekeurd.');
        if(canonical(d)!==canonical($var.before_deal)||canonical(s)!==canonical($var.before_supplier)||Number(d.price)!==a.customer_price)return fail('DEAL_CHANGED','Deal is gewijzigd tijdens de controle.');
        if(Date.now()>a.valid_until)return fail('EXPIRED','Beschikbaarheidscontrole is verlopen.');
        if(!p?.success||!p.data?.prebookId)return fail('PREBOOK_FAILED','Nuitee heeft de prijs niet bevestigd.');
        const q=p.data;
        if(!Array.isArray(q.paymentTypes)||!q.paymentTypes.includes('ACC_CREDIT_CARD'))return fail('ACC_UNAVAILABLE','ACC is niet beschikbaar voor dit aanbod.');
        if(q.currency!=='EUR'||typeof q.price!=='number'||!Number.isFinite(q.price)||q.price<=0)return fail('INVALID_PRICE','Definitieve leveranciersprijs ontbreekt.');
        const rooms=q.roomTypes;
        if(!Array.isArray(rooms)||rooms.length!==1||!Array.isArray(rooms[0].rates)||rooms[0].rates.length!==1)return fail('INVALID_ROOM','Definitieve kamervoorwaarden zijn onvolledig.');
        const r=rooms[0].rates[0], approved=(s.supplier_mapping||s.supplier_content)?.offer, old=approved?.rates?.[0];
        if(!old||r.name!==old.name||r.boardType!==old.boardType||r.boardName!==old.boardName||r.adultCount!==old.adultCount||r.childCount!==old.childCount||r.remarks!==old.remarks||canonical(r.cancellationPolicies)!==canonical(old.cancellationPolicies))return fail('CONDITIONS_CHANGED','Kamer of annuleringsvoorwaarden zijn gewijzigd.');
        const fees=r.retailRate?.taxesAndFees;
        if(!Array.isArray(fees)||fees.some(t=>typeof t.included!=='boolean'||t.currency!=='EUR'||typeof t.amount!=='number'||!Number.isFinite(t.amount)||t.amount<0))return fail('INVALID_FEES','Definitieve lokale kosten zijn onvolledig.');
        const local=fees.filter(t=>!t.included).map(t=>({description:t.description,amount:t.amount,currency:t.currency,pay_at_property:true}));
        const sorted=v=>canonical(v.slice().sort((x,y)=>canonical(x).localeCompare(canonical(y))));
        if(sorted(local)!==sorted(a.local_fees))return fail('LOCAL_FEES_CHANGED','Lokale kosten zijn gewijzigd sinds goedkeuring.');
        const cfg=s.pricing_config;
        if(!acceptedSupplierCosts(cfg)||['processing_fee','stripe_fee_percentage','stripe_fee_fixed','min_margin_amount'].some(k=>typeof cfg[k]!=='number'||!Number.isFinite(cfg[k])||cfg[k]<0)||cfg.stripe_fee_percentage>=100)return fail('INVALID_CONFIG','Kostenconfiguratie ontbreekt.');
        const sale=Math.round(d.price*100),cost=Math.ceil(q.price*100-1e-8),processing=Math.ceil(cfg.processing_fee*100-1e-8),stripe=Math.ceil(sale*cfg.stripe_fee_percentage/100+cfg.stripe_fee_fixed*100-1e-8),margin=sale-cost-processing-stripe;
        if(margin<Math.ceil(cfg.min_margin_amount*100-1e-8))return fail('MARGIN_BLOCKED','Definitieve inkoopprijs past niet binnen de goedgekeurde verkoopprijs.');
        return {ready:true,can_pay:false,environment:'production',deal_id:d.id,supplier_deal_id:s.id,approval_fingerprint:canonical({deal:d,supplier:s}),prebook_id:q.prebookId,checkin:$input.checkin,checkout:$input.checkout,guests:$input.guests,currency:'EUR',selling_price:sale/100,supplier_amount:cost/100,processing_reserve:processing/100,stripe_reserve:stripe/100,margin_after_reserve:margin/100,local_fees:local,cancellation_policies:r.cancellationPolicies,checked_at:Date.now(),message:'Productieprijs bevestigd.'};
        """
      timeout = 5
    } as $result
  }

  response = $result
}