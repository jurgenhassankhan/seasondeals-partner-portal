'use strict';
const test=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm'),{webcrypto}=require('node:crypto');
const source=fs.readFileSync(__dirname+'/../public-preview/js/deal.js','utf8');
function harness(deal={id:999,source:'provider_sync'},transport){
 const values={'sd-checkin':{value:'2026-11-10'},'sd-checkout':{value:'2026-11-12'},'sd-guests':{value:'2'},'sd-check-availability':{}};
 const memory=new Map(),calls=[],messages=[];
 const c={deal,checkoutBusy:false,CONFIG:{checkoutEndpoint:'partner',supplierCheckoutEndpoint:'supplier'},document:{getElementById:id=>values[id]},window:{crypto:webcrypto,location:{href:''}},sessionStorage:{getItem:k=>memory.get(k)||null,setItem:(k,v)=>memory.set(k,v),removeItem:k=>memory.delete(k)},showBookingMessage:m=>messages.push(m),console:{error(){}},URL,Uint8Array,Date,fetch:async(url,options)=>{calls.push({url,body:JSON.parse(options.body)});return transport?transport():{ok:true,status:200,text:async()=>JSON.stringify({environment:'production',status:'pending_payment',currency:'EUR',checkout_url:'https://checkout.stripe.com/c/pay/cs_live_fixture#test'})};}};
 vm.createContext(c);vm.runInContext(source.slice(source.indexOf('  async function startCheckout'),source.indexOf('  function setDateLimits')),c);
 return {c,calls,messages,values,memory,run:()=>c.startCheckout({preventDefault(){}})};
}
test('supplier button sends only five expected inputs directly to production checkout',async()=>{
 const h=harness();await h.run();assert.equal(h.calls[0].url,'supplier');assert.deepEqual(Object.keys(h.calls[0].body).sort(),['checkin','checkout','deal_id','guest_count','request_key']);assert.match(h.calls[0].body.request_key,/^[a-f0-9]{64}$/);assert.equal(h.c.window.location.href,'https://checkout.stripe.com/c/pay/cs_live_fixture#test');
});
test('ordinary hotel retains original endpoint and request contract',async()=>{
 const h=harness({id:4,source:'hotel'},()=>({ok:true,text:async()=>JSON.stringify({api1:{response:{result:{url:'https://checkout.stripe.com/c/pay/cs_test_fixture'}}}})}));await h.run();assert.equal(h.calls[0].url,'partner');assert.deepEqual(h.calls[0].body,{deal_id:4,checkin:'2026-11-10',checkout:'2026-11-12',guests:2});assert.equal(h.memory.size,0);
});
test('timeout retry reuses key; changed stay blocks without partner fallback',async()=>{
 const h=harness(undefined,()=>{throw Error('timeout')});await h.run();await h.run();assert.equal(h.calls[0].body.request_key,h.calls[1].body.request_key);h.values['sd-checkout'].value='2026-11-13';await h.run();assert.equal(h.calls.length,2);assert.ok(h.calls.every(c=>c.url==='supplier'));
});
test('closed gate produces customer message, clears unused attempt and never redirects',async()=>{
 const h=harness(undefined,()=>({ok:false,status:403,text:async()=>JSON.stringify({message:'PRODUCTION_NOT_RELEASED'})}));await h.run();assert.equal(h.c.window.location.href,'');assert.equal(h.memory.size,0);assert.equal(h.messages.at(-1),'Deze hoteldeal is nog niet beschikbaar om te boeken.');
});
test('untrusted redirects, sandbox and wrong production status are refused',async()=>{
 for(const change of [{checkout_url:'https://checkout.stripe.com.evil.invalid/c/pay/cs_live_fixture'},{checkout_url:'https://checkout.stripe.com/c/pay/cs_test_fixture'},{environment:'sandbox'},{status:'booked'}]){
 const h=harness(undefined,()=>({ok:true,text:async()=>JSON.stringify({environment:'production',status:'pending_payment',currency:'EUR',checkout_url:'https://checkout.stripe.com/c/pay/cs_live_fixture',...change})}));await h.run();assert.equal(h.c.window.location.href,'');assert.equal(h.memory.size,1);
 }
});
test('double submission makes one request; expired attempt never creates new key',async()=>{
 let done;const h=harness(undefined,()=>new Promise(resolve=>done=resolve));const first=h.run();await h.run();assert.equal(h.calls.length,1);done({ok:false,text:async()=>'{"message":"retry"}'});await first;
 const [key,value]=[...h.memory][0],saved=JSON.parse(value);saved.created_at-=86400000;h.memory.set(key,JSON.stringify(saved));await h.run();assert.equal(h.calls.length,1);
});
