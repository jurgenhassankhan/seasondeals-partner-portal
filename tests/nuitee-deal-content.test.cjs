const {test}=require('node:test');
const assert=require('node:assert/strict');
const {nuiteeDealContent}=require('../backend/nuitee/deal-content.js');
function sample(){return {hotel:{id:'h1',name:'Provider Hotel',facilities:['Free parking'],roomName:'Dinner Package'},request:{hotel_ids:['h1'],checkin:'2026-11-27',checkout:'2026-11-29',occupancies:[{adults:2}]},offer:{rates:[{name:'Original supplier room',adultCount:2,childCount:0,boardType:'RO'}]}};}
test('different supplier stays and meal plans automatically produce their own inclusions',()=>{
 const m=sample();const ro=nuiteeDealContent(m,'h1');
 assert.equal(ro.hotel_name,'Provider Hotel');assert.equal(ro.minimum_nights,2);
 assert.deepEqual(ro.included_items.map(x=>x.label),['2 overnachtingen','Original supplier room','Voor 2 volwassenen']);
 assert.deepEqual(ro.excluded_items,['Ontbijt']);assert.equal('includes_parking' in ro,false);
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
