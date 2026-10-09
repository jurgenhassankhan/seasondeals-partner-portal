const {test}=require('node:test'),assert=require('node:assert/strict');
const {approvalSignature,readDuringRefresh}=require('../backend/nuitee/snapshot-policy');
test('retain only valid matching availability during a short refresh; negatives always win',()=>{
 const now=100000,d={id:17,status:'active',approved_at:1,price:241.43},s={provider:'nuitee',environment:'sandbox',id:2};
 const signature=approvalSignature(d,s),v={deal_id:17,environment:'sandbox',status:'available',available:true,can_pay:false,checked_at:now-65000,valid_until:now+25000,customer_price:241.43,currency:'EUR'};
 const completed={deal_id:17,environment:'sandbox',status:'available',approval_signature:signature,started_at:now-68000,checked_at:v.checked_at,valid_until:v.valid_until,snapshot:v};
 const pending={deal_id:17,environment:'sandbox',status:'checking',approval_signature:signature,started_at:now-1000};
 assert.equal(readDuringRefresh(d,s,pending,completed,now).refreshing,true);
 for(const change of [{started_at:now-20001},{started_at:now+1},{approval_signature:'old'},{environment:'production'},{deal_id:18}]) assert.equal(readDuringRefresh(d,s,{...pending,...change},completed,now).available,false);
 assert.equal(readDuringRefresh(d,s,pending,completed,now+26000).available,false);
 assert.equal(readDuringRefresh({...d,price:242},s,pending,completed,now).available,false);
 assert.equal(readDuringRefresh(d,s,pending,null,now).available,false);
 for(const status of ['unknown','unavailable']){const negative={...completed,status,snapshot:{...v,status,available:false}};assert.equal(readDuringRefresh(d,s,negative,completed,now).available,false);}
});
