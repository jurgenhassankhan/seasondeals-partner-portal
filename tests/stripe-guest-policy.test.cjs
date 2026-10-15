'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { readGuest } = require('../backend/xano/production/stripe-guest-policy.cjs');
function fixture() {
  const verified = {verified:true,environment:'production',stripe_checkout_session_id:'cs_live_fixture',stripe_payment_intent_id:'pi_fixture',order_id:101,supplier_checkout_intent_id:11,amount_minor:12345,currency:'EUR'};
  const session = {object:'checkout.session',id:'cs_live_fixture',livemode:true,status:'complete',payment_status:'paid',currency:'eur',amount_total:12345,payment_intent:'pi_fixture',metadata:{supplier_order_id:'101',supplier_checkout_intent_id:'11',supplier_fulfillment:'nuitee',supplier_flow:'nuitee_production_v1'},customer_details:{name:'Different Payer',email:'fixture@example.invalid'},custom_fields:[{key:'guestfirstname',type:'text',text:{value:'Anne Marie'}},{key:'guestlastname',type:'text',text:{value:'van der Meer'}}]};
  return {session,verified};
}
test('one room gets exactly one named contact, independent of payer name',()=>{
  const {session,verified}=fixture(); const result=readGuest(session,verified,1);
  assert.equal(result.guests.length,1); assert.equal(result.guests[0].occupancyNumber,1);
  assert.equal(result.holder.firstName,'Anne Marie');assert.equal(result.holder.lastName,'van der Meer');
});
test('missing/ambiguous names never fall back to payer identity',()=>{
  for(const alter of [s=>s.custom_fields=[],s=>s.custom_fields.push(s.custom_fields[0]),s=>s.custom_fields[0].text.value=' ']){
    const {session,verified}=fixture();alter(session);assert.throws(()=>readGuest(session,verified,1));
  }
});
test('unpaid, wrong session, wrong order, amount and sandbox are rejected',()=>{
  for(const alter of [s=>s.payment_status='unpaid',s=>s.id='cs_live_other',s=>s.metadata.supplier_order_id='999',s=>s.amount_total=1,s=>s.livemode=false]){
    const {session,verified}=fixture();alter(session);assert.throws(()=>readGuest(session,verified,1));
  }
});
test('absent contact email, unverified payment and multiple rooms are rejected',()=>{
  const {session,verified}=fixture();assert.throws(()=>readGuest(session,{...verified,verified:false},1));assert.throws(()=>readGuest(session,verified,2));delete session.customer_details.email;assert.throws(()=>readGuest(session,verified,1));
});
