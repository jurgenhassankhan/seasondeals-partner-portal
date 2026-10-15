'use strict';
const test=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const read=f=>fs.readFileSync(path.join(__dirname,'../backend/xano/production',f),'utf8');
const lambda=f=>new Function('$var',read(f).match(/code = """\n([\s\S]*?)\n\s*"""/)[1]);
const verify=lambda('verify-payment.xs'),bind=lambda('claim-payment.xs');
function fixture(){return {
 intent:{id:11,checkout_context:{guest_capture:'stripe-custom-fields-v1',room_count:1}},
 order:{id:101},payment:{id:'pi_fixture'},expected_amount:12345,
 session:{object:'checkout.session',id:'cs_live_fixture',livemode:true,status:'complete',payment_status:'paid',currency:'eur',amount_total:12345,payment_intent:'pi_fixture',metadata:{supplier_order_id:'101',supplier_checkout_intent_id:'11',supplier_fulfillment:'nuitee',supplier_flow:'nuitee_production_v1'},customer_details:{email:'fixture@example.invalid'},custom_fields:[{key:'guestfirstname',type:'text',text:{value:'Anne Marie'}},{key:'guestlastname',type:'text',text:{value:'van der Meer'}}]}
};}
test('actual Xano lambdas pass verified names to existing holder and guests',()=>{
 const v=fixture(), details=verify(v),bound=bind({locked_intent:v.intent,payment:{guest_details:details}});
 assert.equal(bound.valid,true);assert.equal(bound.holder.firstName,'Anne Marie');assert.equal(bound.guests.length,1);assert.equal(bound.guests[0].lastName,'van der Meer');
});
test('actual Xano lambdas block missing, duplicate, invalid and wrong-bound identity',()=>{
 for(const alter of [v=>v.session.custom_fields=[],v=>v.session.custom_fields.push(v.session.custom_fields[0]),v=>v.session.custom_fields[0].text.value='\nAnne',v=>v.session.customer_details.email='',v=>v.intent.checkout_context.room_count=2,v=>v.session.metadata.supplier_order_id='999']){
 const v=fixture();alter(v);const details=verify(v);assert.equal(details.valid,false);assert.equal(bind({locked_intent:v.intent,payment:{guest_details:details}}).valid,false);
 }
});
test('legacy guest route retains its existing stored identity',()=>{
 const v=fixture();delete v.intent.checkout_context.guest_capture;
 const details=verify(v);assert.equal(details.required,false);
 v.intent.holder={firstName:'Existing'};v.intent.guests=[{firstName:'Existing'}];
 assert.deepEqual(bind({locked_intent:v.intent,payment:{guest_details:details}}),{valid:true,holder:v.intent.holder,guests:v.intent.guests});
});
test('new direct checkout refuses old pre-payment guest inputs and isolates retry references',()=>{
 const source=read('guest-checkout.xs');assert.ok(source.includes("'SD-DIRECT-'"));assert.ok(source.includes("guest_capture:'stripe-custom-fields-v1'"));assert.ok(!source.includes('json holder'));assert.ok(!source.includes('customer_email'));
 assert.ok(source.includes('guestfirstname'));assert.ok(source.includes('guestlastname'));
});
