const assert=require('node:assert/strict');
const fs=require('node:fs');
const {render}=require('../public-preview/js/confirmation-production-view.js');
const xs=fs.readFileSync(__dirname+'/../backend/xano/production/confirmation-status.xs','utf8');
const blocks=[...xs.matchAll(/code\s*=\s*(?:"""([\s\S]*?)"""|("(?:\\.|[^"\\])*"))/g)].map(m=>new Function('$var','$input',m[1]??JSON.parse(m[2])));
const base=()=>({intent:{order_id:2001,environment:'production',provider_slug:'nuitee',status:'booked',stripe_payment_intent_id:'pi_fixture',stripe_checkout_session_id:'cs_live_fixture',selling_price:150,currency:'EUR',client_reference:'fixture',checkout_context:{flow:'nuitee-production-v1',request:{customer_id:2002,guest_count:2},booking_response:{data:{sandbox:0,status:'CONFIRMED',bookingId:'fixture_booking',clientReference:'fixture',hotelName:'<script>x</script>'}},voucher_id:2003,confirmation_mail:{status:'sent',to:'private@example.invalid'}}},order:{customer_id:2002,stripe_checkout_session_id:'cs_live_fixture',status:'paid',payment_status:'paid',provider_sync_status:'confirmed',external_booking_id:'fixture_booking'},booking:{order_id:2001,environment:'production',provider_slug:'nuitee',booking_status:'confirmed',payment_status:'paid',external_booking_id:'fixture_booking'},voucher:{id:2003,status:'active',redemption_status:'active',code:'FIXTURE-VOUCHER'}});
const good=blocks[2](base(),{}); assert.equal(good.state,'confirmed'); assert.equal(good.voucher.code,'FIXTURE-VOUCHER');
assert(!JSON.stringify(good).includes('private@example.invalid'));assert(!JSON.stringify(good).includes('pi_fixture'));
for(const mutate of [v=>v.intent.environment='sandbox',v=>v.intent.checkout_context.flow='other',v=>v.order.customer_id=9,v=>v.order.stripe_checkout_session_id='other',v=>v.booking.environment='sandbox',v=>v.booking.order_id=9,v=>v.intent.checkout_context.booking_response.data.sandbox=1,v=>v.order.payment_status='unpaid',v=>v.intent.status='processing',v=>v.booking=null]){const v=base();mutate(v);const result=blocks[2](v,{});assert.notEqual(result.state,'confirmed');assert.equal(result.voucher,null);assert.equal(result.booking,null);}
const cancelled=base();cancelled.order.status='refunded';assert.equal(blocks[2](cancelled,{}).state,'cancelled');assert.equal(blocks[2](cancelled,{}).voucher,null);
const revoked=base();revoked.voucher.status='revoked';assert.equal(blocks[2](revoked,{}).voucher,null);
assert.equal(blocks[0]({}, {session_id:'cs_live_'+'x'.repeat(50)}).valid,true);assert.equal(blocks[0]({}, {session_id:'cs_test_'+'x'.repeat(50)}).valid,false);
assert.equal(blocks[1]({intent:{created_at:Date.now()-86400001}},{}).valid,false);
assert.equal(blocks[1]({intent:{created_at:Date.now()+60000}},{}).valid,false);
assert(render(good).includes('&lt;script&gt;'));assert(!render(good).includes('<script>x'));
assert(render({...good,environment:'sandbox'}).includes('Bevestiging niet beschikbaar'));
assert(!render({...good,state:'processing'}).includes('FIXTURE-VOUCHER'));
console.log('PASS: production confirmation binding, sandbox rejection, revoked/cancelled voucher suppression, expiry, privacy, HTML escaping. Synthetic fixtures only.');
