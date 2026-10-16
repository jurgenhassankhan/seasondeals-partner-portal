const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const source = fs.readFileSync(__dirname + '/../backend/xano/approval-publication/workflow.xs', 'utf8');
const verify = new Function('$var', source.match(/code = """\n([\s\S]*?)\n"""/)[1]);
function sample() {
  const gallery = [{url:'https://static.cupid.travel/rooms/a.jpg',scope:'matched_room',sha256:'a'.repeat(64),dhash:'0000000000000000'}, {url:'https://static.cupid.travel/rooms/b.jpg',scope:'matched_room',sha256:'b'.repeat(64),dhash:'ffffffffffffffff'}];
  return {deal:{external_image_urls:gallery.map(p=>p.url)}, supplier:{supplier_hotel_id:'hotel1',supplier_mapping:{hotel:{id:'hotel1',name:'Test Hotel'},request:{hotel_ids:['hotel1'],checkin:'2026-11-27',checkout:'2026-11-29',occupancies:[{adults:2}]},offer:{rates:[{name:'Standard Room',mappedRoomId:12,adultCount:2,childCount:0,boardType:'RO'}]}},supplier_content:{hotel:{photo_hotel_id:'hotel1',mapped_room_id:12,photo_rate_name:'Standard Room',room_photos_matched:true,photo_verification:{status:'verified',algorithm:'sha256+dhash64-v1'},photo_gallery:gallery}}}};
}
test('verified room gallery passes without an extra publication action',()=>assert.equal(verify(sample()),true));
test('missing verification, other hotel, other room or stale gallery is rejected',()=>{
  for(const change of [x=>delete x.supplier.supplier_content.hotel.photo_verification, x=>x.supplier.supplier_hotel_id='other', x=>x.supplier.supplier_mapping.offer.rates[0].mappedRoomId=13, x=>x.supplier.supplier_mapping.offer.rates[0].name='Suite', x=>x.deal.external_image_urls.push('https://example.test/extra.jpg')]) {const x=sample();change(x);assert.equal(verify(x),false);}
});
test('duplicates and non-room photos are rejected',()=>{
  for(const change of [p=>p[1].sha256=p[0].sha256,p=>p[1].dhash='0000000000000001',p=>p[1].scope='hotel',p=>p[1].dhash='invalid']) {const x=sample();change(x.supplier.supplier_content.hotel.photo_gallery);assert.equal(verify(x),false);}
});

test('provider-confirmed exact room-name mapping supports old offers without changing rates',()=>{
 const x=sample(),h=x.supplier.supplier_content.hotel,r=x.supplier.supplier_mapping.offer.rates[0];
 delete r.mappedRoomId;r.adultCount=2;r.childCount=0;
 h.room_photo_binding={source:'provider_exact_room_name',hotel_id:'hotel1',rate_name:'Standard Room',mapped_room_id:12,adult_count:2,child_count:0};
 assert.equal(verify(x),true);
 r.mappedRoomId=13;assert.equal(verify(x),false);
 delete r.mappedRoomId;r.name='Suite';assert.equal(verify(x),false);
});
test('photo lookup requires unanimous provider mapping and selects only that room',()=>{
 const src=fs.readFileSync(__dirname+'/../backend/xano/production/refresh-deal-photos.xs','utf8');
 const prepare=new Function('$var','$input',src.match(/code = """\n([\s\S]*?)\n"""/)[1]);
 const rate={name:'Standard Room',adultCount:2,childCount:0};
 const x={supplier:{supplier_hotel_id:'hotel1',supplier_mapping:{offer:{rates:[rate]}}},details:{response:{status:200,result:{data:{id:'hotel1',rooms:[{id:12,roomName:'Standard',photos:[{url:'https://example.test/standard.jpg'}]},{id:13,roomName:'Suite',photos:[{url:'https://example.test/suite.jpg'}]}]}}}},mapping_rates:{response:{status:200,result:{data:[{hotelId:'hotel1',roomTypes:[{rates:[{...rate,mappedRoomId:12,boardType:'BI'},{...rate,mappedRoomId:12,boardType:'RO'}]}]}]}}}};
 const run=()=>prepare(x,{save:false});
 assert.deepEqual(run().photos.map(p=>p.url),['https://example.test/standard.jpg']);
 x.mapping_rates.response.result.data[0].roomTypes[0].rates[1].mappedRoomId=13;
 assert.equal(run().valid,false);
});

test('server photo algorithm v2 passes while unknown algorithms fail',()=>{
 const x=sample();x.supplier.supplier_content.hotel.photo_verification.algorithm='sha256+dhash64-area-v2';assert.equal(verify(x),true);
 x.supplier.supplier_content.hotel.photo_verification.algorithm='untrusted';assert.equal(verify(x),false);
});
