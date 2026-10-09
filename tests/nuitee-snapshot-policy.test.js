const {test}=require('node:test'),assert=require('node:assert/strict');
const {approvalSignature,readSnapshot}=require('../backend/nuitee/snapshot-policy');
test('server snapshot freshness, approval/config changes and pending invalidate previous availability',()=>{
 const now=1791458000000,d={id:17,status:'active',approved_at:1791450000000,price:241.43,minimum_nights:2},s={id:2,provider:'nuitee',environment:'sandbox',supplier_hotel_id:'lp225fcf',pricing_config:{min_margin_amount:20},supplier_mapping:{request:{checkin:'2026-11-10'}}};
 const v={deal_id:17,environment:'sandbox',status:'available',available:true,can_pay:false,checked_at:now,valid_until:now+60000,customer_price:241.43,currency:'EUR'};
 const row={deal_id:17,environment:'sandbox',status:'available',checked_at:now,valid_until:now+60000,approval_signature:approvalSignature(d,s),snapshot:v};
 assert.equal(readSnapshot(d,s,row,now).available,true);
 for(const mutate of [r=>r.valid_until=now,r=>r.checked_at=now+1,r=>r.valid_until=now+90001,r=>r.status='checking',r=>r.environment='production',r=>r.snapshot.can_pay=true,r=>r.snapshot.customer_price=242,r=>r.snapshot.deal_id=16,r=>r.approval_signature='old']){const r=structuredClone(row);mutate(r);assert.equal(readSnapshot(d,s,r,now).available,false);}
 for(const change of [{status:'draft'},{approved_at:1791450000001},{price:242},{deleted_at:now},{minimum_nights:3}])assert.equal(readSnapshot({...d,...change},s,row,now).available,false);
 assert.equal(readSnapshot(d,{...s,pricing_config:{min_margin_amount:30}},row,now).available,false);
 assert.equal(readSnapshot(d,{...s,supplier_mapping:{request:{checkin:'2026-11-11'}}},row,now).available,false);
 const pending={...row,status:'checking',checked_at:null,valid_until:null,snapshot:null};assert.equal(readSnapshot(d,s,pending,now).available,false);
 assert.equal(approvalSignature(d,s),approvalSignature({...d},JSON.parse(JSON.stringify(s))));
});

