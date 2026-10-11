const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const {render} = require('../public-preview/js/confirmation-view');
const xs = fs.readFileSync(__dirname+'/../backend/xano/supplier-confirmation-status.xs','utf8');
const blocks = [...xs.matchAll(/code = """\n([\s\S]*?)\n"""/g)].map(m=>m[1]);
const run = (code, vars = {}, input = {}) => vm.runInNewContext('(function(){'+code+'})()',{$var:vars,$input:input,Date});
const base = () => ({
 intent:{status:'booked',stripe_payment_intent_id:'test_payment',selling_price:241.43,currency:'EUR',client_reference:'test_reference',checkout_context:{request:{checkin:'2026-11-10',checkout:'2026-11-12',guest_count:2},booking_response:{data:{status:'CONFIRMED',sandbox:1,bookingId:'test_booking',clientReference:'test_reference',hotel:{name:'Testhotel'},tag:'NRFN'}},voucher_id:44,confirmation_mail:{status:'sent',to:'must-not-be-exposed@example.com'}}},
 order:{status:'paid',payment_status:'paid',provider_sync_status:'confirmed',external_booking_id:'test_booking'},
 booking:{booking_status:'confirmed',payment_status:'paid',external_booking_id:'test_booking'},
 voucher:{id:44,status:'active',redemption_status:'active',code:'TEST-VOUCHER'}
});
const confirmed = run(blocks[2],base());
assert.equal(confirmed.state,'confirmed');assert.equal(confirmed.voucher.code,'TEST-VOUCHER');
assert(!JSON.stringify(confirmed).includes('must-not-be-exposed'));
assert(!JSON.stringify(confirmed).includes('test_payment'));
for(const mutate of [v=>v.order.payment_status='unpaid',v=>v.intent.status='processing',v=>v.booking=null,v=>v.intent.checkout_context.booking_response.data.bookingId='other',v=>v.intent.checkout_context.booking_response.data.sandbox=0]){
 const value=base();mutate(value);const result=run(blocks[2],value);assert.notEqual(result.state,'confirmed');assert.equal(result.voucher,null);assert.equal(result.booking,null);
}
const failed=base();failed.intent.status='manual_attention';failed.order.provider_sync_status='error';assert.equal(run(blocks[2],failed).state,'needs_attention');
const cancelled=base();cancelled.booking.booking_status='cancelled_with_charges';assert.equal(run(blocks[2],cancelled).state,'cancelled');assert.equal(run(blocks[2],cancelled).voucher,null);
const invalid=base();invalid.voucher.status='revoked';assert.equal(run(blocks[2],invalid).voucher,null);
assert.equal(run(blocks[0],{},{session_id:'100'}).valid,false);
assert.equal(run(blocks[0],{},{session_id:'cs_live_'+'x'.repeat(50)}).valid,false);
assert.equal(run(blocks[1],{intent:{created_at:Date.now()-86400001}}).valid,false);
assert.equal(run(blocks[1],{intent:{created_at:Date.now()+60000}}).valid,false);
assert.equal(run(blocks[1],{intent:{created_at:Date.now()-10000}}).valid,true);
assert(render({state:'confirmed'}).includes('Bevestiging niet beschikbaar'));
assert(!render({state:'processing',booking:confirmed.booking,voucher:confirmed.voucher}).includes('TEST-VOUCHER'));
confirmed.booking.hotel_name='<img src=x onerror=alert(1)>';
const html=render(confirmed);assert(!html.includes('<img src=x'));assert(html.includes('&lt;img'));assert(html.includes('Niet-restitueerbaar'));
assert(render({state:'pending_payment'}).includes('Betaal niet opnieuw'));
const qr = require('../public-preview/js/vendor/qrcode'); const code=qr(0,'M');code.addData('TEST-VOUCHER');code.make();assert(code.createSvgTag().includes('<svg'));
console.log('PASS: confirmation gating, failed/cancelled states, voucher revocation, access expiry, output minimization, escaping, local QR.');
