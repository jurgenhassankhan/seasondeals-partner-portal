const assert=require('node:assert/strict');
const {visible,createCatalog}=require('../public-preview/js/availability-catalog');
(async()=>{
  let now=100000;const deal={id:17,status:'active',approved_at:1,price:241.43};
  const snapshot={deal_id:17,status:'available',available:true,can_pay:false,environment:'sandbox',customer_price:241.43,currency:'EUR',checked_at:now,valid_until:now+60000};
  assert.equal(visible(deal,snapshot,now),true);
  for(const change of [{status:'unavailable'},{status:'unknown'},{valid_until:now},{deal_id:18},{customer_price:242},{environment:'production'},{can_pay:true},{checked_at:now+1}])assert.equal(visible(deal,{...snapshot,...change},now),false);
  assert.equal(visible({...deal,status:'draft'},snapshot,now),false);
  let views=[],answer=snapshot,timer;const c=createCatalog({request:async()=>answer,render:items=>views.push(items),now:()=>now,setTimer:fn=>(timer=fn,1),clearTimer:()=>{timer=null;}});
  await c.refresh([deal]);assert.equal(views.at(-1).length,1);
  now+=60001;c.expire();assert.equal(views.at(-1).length,0);
  answer={...snapshot,status:'unavailable',available:false};await c.refresh();assert.equal(views.at(-1).length,0);
  answer={...snapshot,checked_at:now,valid_until:now+60000};await c.refresh();assert.equal(views.at(-1).length,1);
  answer=null;await c.refresh();assert.equal(views.at(-1).length,0);c.dispose();assert.equal(timer,null);
  console.log('Catalog: fresh approved price, expired/unknown/unavailable hiding and restoration checks passed.');
})().catch(e=>{console.error(e);process.exitCode=1;});
