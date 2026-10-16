'use strict';
const test=require('node:test'),assert=require('node:assert/strict');
const {projectDeal}=require('../backend/seo/deal-projection.cjs');
const sample=()=>({id:18,source:'provider_sync',status:'active',is_active:true,approved_at:1,content_verified:true,
 title:'2 nachten bij Hôtel Test',hotel_name:'Hôtel Test',short_description:'Twee nachten in de bevestigde kamer.',long_description:'Voor twee personen.',
 cancellation_policy:'Niet restitueerbaar.',price:333.04,external_image_urls:['https://images.example/room.jpg'],
 travel_period_start:Date.UTC(2026,10,10),travel_period_end:Date.UTC(2026,10,12),max_guests:2,
 included_items:[{icon:'☾',label:'2 overnachtingen',detail:'Bevestigde kamer'}],facility_items:[]});
test('HTML contains actual deal content without JS; prelaunch stays noindex',()=>{
 const p=projectDeal(sample()); assert.equal(p.slug,'hotel-test-18');assert.match(p.html,/<h1>2 nachten bij Hôtel Test<\/h1>/);assert.match(p.html,/Niet restitueerbaar/);assert.match(p.html,/333,04/);assert.match(p.head,/noindex,follow/);assert.equal(p.includeInSitemap,false);assert.doesNotMatch(p.head,/InStock|AggregateRating/);assert.match(p.html,/type="submit" disabled/);
});
test('title changes keep persisted identity and URL; another deal cannot claim it',()=>{
 const d=sample();d.hotel_name='Changed hotel';assert.equal(projectDeal(d,{previousSlug:'hotel-test-18'}).slug,'hotel-test-18');assert.throws(()=>projectDeal(d,{previousSlug:'hotel-test-19'}));
});
test('nonpublic states withdraw; unverified content cannot be projected',()=>{
 for(const patch of [{status:'draft'},{status:'pending_approval'},{is_active:false},{approved_at:null},{deleted_at:10}])assert.equal(projectDeal({...sample(),...patch}),null);
 assert.throws(()=>projectDeal({...sample(),content_verified:false}));assert.throws(()=>projectDeal({...sample(),source:'hotel'}));
});
test('secrets and input HTML never become executable output',()=>{
 const d=sample();d.title='</title><script>alert(1)</script>';d.hotel_name='</script><script>bad</script>';d.included_items[0].icon='<img src=x onerror=bad>';d.supplier_mapping={api_key:'PRIVATE_SENTINEL'};
 const p=projectDeal(d);assert.doesNotMatch(JSON.stringify(p),/PRIVATE_SENTINEL/);assert.doesNotMatch(p.html,/<script>|<img src=x/);assert.doesNotMatch(p.head,/<script>alert/);assert.match(p.head,/\\u003c/);
});
test('malformed photos, occupancy, price and dates block rendering',()=>{
 for(const patch of [{external_image_urls:['javascript:alert(1)']},{external_image_urls:['https://x/a','https://x/a']},{price:0},{max_guests:0},{travel_period_end:0}])assert.throws(()=>projectDeal({...sample(),...patch}));
});
test('only explicit launch option enables indexing',()=>{
 const p=projectDeal(sample(),{indexable:true});assert.equal(p.includeInSitemap,true);assert.match(p.head,/content="index,follow"/);assert.match(p.head,/https:\/\/www.seasondeals.nl\/deals\/hotel-test-18/);
});
