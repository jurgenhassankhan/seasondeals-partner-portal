const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const {supplierPricingConfig,calculateSupplierPrice} = require('../backend/nuitee/pricing');
const config = extra => ({...supplierPricingConfig(),processing_fee:5,stripe_fee_percentage:0,stripe_fee_fixed:0,...extra});

test('20% above all costs, including Stripe percentage of final selling price', () => {
  assert.equal(calculateSupplierPrice(200,config()).amount,246);
  const c=config({processing_fee:2.3,stripe_fee_percentage:3,stripe_fee_fixed:.25});
  const r=calculateSupplierPrice(200,c);
  assert.ok(r.estimatedMargin >= r.totalCost*.2 - 1e-9);
  assert.ok(r.estimatedMargin - r.totalCost*.2 < .011);
  assert.equal(r.stripeCost,r.amount*.03+.25);
});
test('fixed addition includes costs; override stays exactly chosen price',()=>{
  const c=config({mode:'fixed',markup_amount:40,stripe_fee_percentage:3,stripe_fee_fixed:.25});
  const r=calculateSupplierPrice(200,c);
  assert.ok(r.estimatedMargin>=40 && r.estimatedMargin<40.01);
  assert.equal(calculateSupplierPrice(200,config({mode:'override',override_amount:249})).amount,249);
});
test('unknown costs and invalid inputs cannot become zero or produce a price',()=>{
  assert.throws(()=>calculateSupplierPrice(200,supplierPricingConfig()),/bevestigen/);
  for(const value of [null,'',-1,NaN,Infinity,'3']) assert.throws(()=>calculateSupplierPrice(200,config({processing_fee:value})));
  assert.throws(()=>calculateSupplierPrice(200,config({stripe_fee_percentage:90})),/geldige verkoopprijs/);
  assert.throws(()=>calculateSupplierPrice(200,config({discount_percentage:100})));
  assert.throws(()=>calculateSupplierPrice(200,config({mode:'override',override_amount:201})),/minimum/);
});
test('rounding, discount and saved choices are preserved',()=>{
  assert.equal(calculateSupplierPrice(200,config({rounding:'whole'})).amount,246);
  assert.equal(calculateSupplierPrice(200,config({rounding:'99'})).amount,246.99);
  assert.equal(calculateSupplierPrice(200,config({discount_percentage:5})).amount,233.7);
  assert.equal(supplierPricingConfig({mode:'override',markup_percentage:12}).markup_percentage,12);
  assert.equal(supplierPricingConfig({mode:'override'},true).mode,'percentage');
});
test('save endpoint preserves server evidence, refuses client verification and rejects missing costs',()=>{
  const source=fs.readFileSync('backend/xano/approval-publication/pricing.xs','utf8');
  const code=source.match(/code = """([\s\S]*?)"""/)[1];
  const run=(incoming,previous)=>vm.runInNewContext('(function(){'+code+'})()',{$input:{pricing_config:incoming},$var:{supplier:{supplier_base_amount:200,pricing_config:previous}}});
  const previous={...config(),production_costs_verified:true,cost_evidence:'account tariff',payment_method:'ACC_CREDIT_CARD'};
  const same=run({markup_percentage:25,production_costs_verified:false},previous);
  assert.equal(same.valid,true);assert.equal(same.config.production_costs_verified,true);
  const changed=run({processing_fee:6,production_costs_verified:true,cost_evidence:'forged'},previous);
  assert.equal(changed.config.production_costs_verified,false);assert.equal(changed.config.cost_evidence,null);
  assert.equal(run({},supplierPricingConfig()).valid,false);
});
test('generated policy matches across frontend, import and save',()=>{
  const source=fs.readFileSync('backend/nuitee/pricing.js','utf8').split('if (typeof module')[0].trim();
  for(const path of ['admin/js/deal-detail-v5.js','backend/xano/approval-publication/pricing.xs','backend/xano/production/import-first-nhow-draft.xs']) {
    const code=fs.readFileSync(path,'utf8').match(/\/\/ BEGIN GENERATED PRICING\n([\s\S]*?)\n\/\/ END GENERATED PRICING/)[1];
    assert.equal(code,source);
  }
});
