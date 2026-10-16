query "supplier-deals/{deal_id}/pricing" verb=PATCH {
  api_group = "Admin"
  auth = "admin_users"

  input {
    int deal_id
    json pricing_config
  }

  stack {
    function.run "admin/guard" {
      input = {permission: null}
    } as $admin
  
    precondition ($admin.role == "superadmin" || $admin.role == "platform_admin") {
      error_type = "accessdenied"
      error = "Alleen bevoegde beheerders mogen prijsregels aanpassen."
    }
  
    db.transaction {
      stack {
    db.get deals {
      field_name = "id"
      field_value = $input.deal_id
      lock = true
    } as $deal
  
    precondition ($deal != null && ($deal.deleted_at == null || $deal.deleted_at == 0) && $deal.status == "draft") {
      error_type = "inputerror"
      error = "Prijsregels kunnen uitsluitend bij een conceptdeal worden gewijzigd."
    }
  
    db.query supplier_deals {
      where = $db.supplier_deals.deal_id == $input.deal_id && $db.supplier_deals.provider == "nuitee"
      return = {type: "single"}
    } as $supplier
  
    precondition ($supplier != null) {
      error_type = "notfound"
      error = "Nuitee-koppeling niet gevonden."
    }
  
    api.lambda {
      code = """
// BEGIN GENERATED PRICING
// Shared price policy. Account-specific costs require evidence before configuring.
const supplierPricingDefaults = Object.freeze({
  mode: 'percentage', markup_percentage: 20, markup_amount: 0, override_amount: 0,
  discount_percentage: 0, min_margin_amount: 20, rounding: 'none',
  processing_fee: null, stripe_fee_percentage: null, stripe_fee_fixed: null,
  calculation_basis: 'costs_included_v2', defaults_version: '20261016-1',
  production_costs_verified: false, cost_evidence: null, payment_method: 'ACC_CREDIT_CARD'
});

function supplierPricingConfig(saved = {}, proposal = false) {
  const config = {...supplierPricingDefaults, ...saved};
  // Null means unknown, never zero. Fill only with confirmed central defaults.
  for (const key of ['processing_fee','stripe_fee_percentage','stripe_fee_fixed']) {
    config[key] = saved[key] ?? supplierPricingDefaults[key];
  }
  if (proposal) config.mode = 'percentage';
  return config;
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
const incoming=$input.pricing_config || {}, previous=$var.supplier.pricing_config || {};
try {
  const config = supplierPricingConfig(previous);
  for (const key of ['mode','rounding','markup_percentage','markup_amount','override_amount','discount_percentage','min_margin_amount','processing_fee','stripe_fee_percentage','stripe_fee_fixed']) {
    if (Object.hasOwn(incoming,key)) config[key] = incoming[key];
  }
  config.calculation_basis = 'costs_included_v2';
  const result = calculateSupplierPrice(Number($var.supplier.supplier_base_amount),config);
  const costsChanged = ['processing_fee','stripe_fee_percentage','stripe_fee_fixed'].some(key=>config[key] !== previous[key]);
  // Never accept client assertions of verified commercial costs.
  if (costsChanged) { config.production_costs_verified=false; config.cost_evidence=null; }
  config.price_status='saved_requires_review';
  return {valid:true,config,...result};
} catch(error) { return {valid:false,reason:error.message}; }
      """
      timeout = 5
    } as $calculated
    precondition ($calculated.valid) {
      error_type = "inputerror"
      error = $calculated.reason
    }
    var $config { value = $calculated.config }
    var $price { value = $calculated.amount }
    var $margin { value = $calculated.estimatedMargin }

        db.edit supplier_deals {
          field_name = "id"
          field_value = $supplier.id
          data = {pricing_config: $config}
        } as $updated_supplier
      
        db.edit deals {
          field_name = "id"
          field_value = $deal.id
          data = {price: $price, deal_price: $price, updated_at: "now"}
        } as $updated_deal
      }
    }
  }

  response = {
    supplier_deal   : $updated_supplier
    price           : $price
    estimated_margin: $margin
  }
}
