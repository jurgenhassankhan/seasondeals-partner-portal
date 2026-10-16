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
if (typeof module !== 'undefined') module.exports = {supplierPricingDefaults,supplierPricingConfig,calculateSupplierPrice,acceptedSupplierCosts};
