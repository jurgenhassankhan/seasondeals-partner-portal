const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const source = fs.readFileSync(__dirname + '/../backend/xano/approval-publication/workflow.xs', 'utf8');
const verify = new Function('$var', source.match(/code = """\n([\s\S]*?)\n"""/)[1]);
function sample() {
  const gallery = [{url:'https://static.cupid.travel/rooms/a.jpg',scope:'matched_room',sha256:'a'.repeat(64),dhash:'0000000000000000'}, {url:'https://static.cupid.travel/rooms/b.jpg',scope:'matched_room',sha256:'b'.repeat(64),dhash:'ffffffffffffffff'}];
  return {deal:{external_image_urls:gallery.map(p=>p.url)}, supplier:{supplier_hotel_id:'hotel1',supplier_mapping:{offer:{rates:[{name:'Standard Room',mappedRoomId:12}]}},supplier_content:{hotel:{photo_hotel_id:'hotel1',mapped_room_id:12,photo_rate_name:'Standard Room',room_photos_matched:true,photo_verification:{status:'verified',algorithm:'sha256+dhash64-v1'},photo_gallery:gallery}}}};
}
test('verified room gallery passes without an extra publication action',()=>assert.equal(verify(sample()),true));
test('missing verification, other hotel, other room or stale gallery is rejected',()=>{
  for(const change of [x=>delete x.supplier.supplier_content.hotel.photo_verification, x=>x.supplier.supplier_hotel_id='other', x=>x.supplier.supplier_mapping.offer.rates[0].mappedRoomId=13, x=>x.supplier.supplier_mapping.offer.rates[0].name='Suite', x=>x.deal.external_image_urls.push('https://example.test/extra.jpg')]) {const x=sample();change(x);assert.equal(verify(x),false);}
});
test('duplicates and non-room photos are rejected',()=>{
  for(const change of [p=>p[1].sha256=p[0].sha256,p=>p[1].dhash='0000000000000001',p=>p[1].scope='hotel',p=>p[1].dhash='invalid']) {const x=sample();change(x.supplier.supplier_content.hotel.photo_gallery);assert.equal(verify(x),false);}
});
