const {test}=require('node:test');
const assert=require('node:assert/strict');
const {nuiteeDealContent}=require('../backend/nuitee/deal-content.js');
function sample(){return {hotel:{id:'h1',name:'Provider Hotel',facilities:['Free parking'],roomName:'Dinner Package'},request:{hotel_ids:['h1'],checkin:'2026-11-27',checkout:'2026-11-29',occupancies:[{adults:2}]},offer:{rates:[{name:'Original supplier room',adultCount:2,childCount:0,boardType:'RO'}]}};}
test('different supplier stays and meal plans automatically produce their own inclusions',()=>{
 const m=sample();const ro=nuiteeDealContent(m,'h1');
 assert.equal(ro.hotel_name,'Provider Hotel');assert.equal(ro.minimum_nights,2);
 assert.deepEqual(ro.included_items.map(x=>x.label),['2 overnachtingen','Original supplier room','Voor 2 volwassenen']);
 assert.deepEqual(ro.excluded_items,['Ontbijt']);assert.equal(ro.includes_parking,false);
 m.request.checkout='2026-11-30';m.request.occupancies=[{adults:1,children:[8]}];
 Object.assign(m.offer.rates[0],{name:'Family room',adultCount:1,childCount:1,boardType:'BI'});
 const bi=nuiteeDealContent(m,'h1');assert.equal(bi.minimum_nights,3);assert.equal(bi.max_guests,2);
 assert.deepEqual(bi.included_items.map(x=>x.label),['3 overnachtingen','Family room','Voor 1 volwassene en 1 kind','Ontbijt inbegrepen']);
 assert.deepEqual(bi.excluded_items,[]);
});
test('missing or conflicting facts cannot become confirmed inclusions',()=>{
 for(const change of [m=>m.hotel.id='wrong',m=>m.hotel.name='',m=>m.request.checkin='2026-02-30',m=>m.request.checkout=m.request.checkin,m=>m.offer.rates[0].boardType='unknown',m=>m.offer.rates[0].adultCount=3,m=>m.offer.rates.push({...m.offer.rates[0]}),m=>delete m.offer.rates[0].name]){
  const m=sample();change(m);assert.throws(()=>nuiteeDealContent(m,'h1'));
 }
});
test('board names and room catalog labels cannot override actual rate conditions',()=>{
 const m=sample();m.offer.rates[0].boardName='Breakfast Included';m.offer.rates[0].name='Dinner Package';
 assert.equal(nuiteeDealContent(m,'h1').includes_breakfast,false);
 m.offer.rates[0].boardType='BDI';assert.equal(nuiteeDealContent(m,'h1').included_items.at(-1).label,'Ontbijt en diner inbegrepen');
 m.offer.rates[0].boardType='DI';assert.deepEqual(nuiteeDealContent(m,'h1').excluded_items,['Ontbijt']);
});
test('hotel facilities retain costs and uncertainty without inventing included extras',()=>{
 const m=sample();const hotel={supplier_details:{id:'h1',hotelFacilities:['Free WiFi','Parking','Late check-out (surcharge)'],parking:'Self parking costs EUR 25 per day'}};
 const c=nuiteeDealContent(m,'h1',hotel);
 assert.equal(c.includes_wifi,true);assert.equal(c.includes_parking,false);assert.equal(c.includes_late_checkout,false);
 assert.equal(c.extra_conditions.find(x=>x.key==='parking').status,'paid');
 assert.match(c.facility_items.find(x=>x.key==='parking').detail,/EUR 25 per day/);
 assert.equal(c.facility_items.some(x=>x.key==='welcome_drink'),false);
 assert.doesNotMatch(JSON.stringify(c),/\b(?:free|gratis|complimentary)\b/i);
 assert.match(c.included_items[0].detail,/27 november 2026/);
 assert.throws(()=>nuiteeDealContent(m,'h1',{supplier_details:{id:'other'}}),/dit hotel/);
});
test('rate perks keep conditional benefits and never interpret monetary value as a surcharge',()=>{
 const m=sample();m.offer.rates[0].perks=[
 {perkId:1,name:'Welcome drink',amount:15,currency:'EUR',level:'RATE'},
 {perkId:2,name:'Late check-out if available',amount:20,currency:'EUR',level:'HOTEL'},
 {perkId:3,name:'Daily breakfast for 2',amount:40,currency:'EUR',level:'ROOM'}];
 const c=nuiteeDealContent(m,'h1');assert.equal(c.includes_welcome_drink,true);assert.equal(c.includes_late_checkout,false);
 assert.equal(c.includes_breakfast,true);assert.deepEqual(c.excluded_items,[]);
 assert.match(c.facility_items.find(x=>x.key==='late_checkout').detail,/if available/);
 assert.doesNotMatch(JSON.stringify(c.extra_conditions),/EUR|15|20|40/);
});
test('conflicting, conditional or negated facility descriptions never certify inclusions',()=>{
 for(const names of [['Free WiFi','WiFi (surcharge)'],['No free parking'],['Free parking on request'],['WiFi']]){
 const c=nuiteeDealContent(sample(),'h1',{supplier_details:{id:'h1',hotelFacilities:names}});
 assert.equal(c.includes_parking,false);assert.equal(c.includes_wifi,false);
 }
});
