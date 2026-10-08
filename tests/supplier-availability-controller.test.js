const assert=require('node:assert/strict');
const {createController}=require('../public-preview/js/supplier-availability');
(async()=>{
  let time=100000,timer=null,states=[],pending=[];
  const make=request=>createController({request,render:s=>states.push(s),now:()=>time,setTimer:fn=>(timer=fn,1),clearTimer:()=>{timer=null;}});
  const valid={status:'available',available:true,environment:'sandbox',can_pay:false,customer_price:241.43,checked_at:time,valid_until:time+60000};
  const c=make(()=>new Promise(resolve=>pending.push(resolve)));
  const first=c.check({checkin:'first'});c.invalidate();const second=c.check({checkin:'second'});
  pending[1](valid);await second;pending[0]({...valid,status:'unavailable',available:false});await first;
  assert.equal(states.at(-1).status,'available','late response must not replace newest selection');
  assert.equal(typeof timer,'function');c.dispose();assert.equal(timer,null);
  states=[];const expired=make(async()=>({...valid,valid_until:time-1}));await expired.check({});assert.equal(states.at(-1).status,'unknown');expired.dispose();
  states=[];const error=make(async()=>{throw Error('Provider offline');});await error.check({});assert.equal(states.at(-1).available,false);error.dispose();
  states=[];const malicious=make(async()=>({...valid,can_pay:true}));await malicious.check({});assert.equal(states.at(-1).status,'unknown');malicious.dispose();
  states=[];const disposed=make(()=>new Promise(resolve=>pending.push(resolve)));const outstanding=disposed.check({});disposed.dispose();pending.at(-1)(valid);await outstanding;assert.equal(states.at(-1).status,'checking');
  console.log('Availability controller: stale response, expiry, provider failure, forbidden payment and disposal checks passed.');
})().catch(e=>{console.error(e);process.exitCode=1;});
