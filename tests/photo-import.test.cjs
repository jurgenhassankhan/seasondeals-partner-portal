const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const source=fs.readFileSync(__dirname+'/../backend/xano/production/import-first-nhow-draft.xs','utf8');
const blocks=[...source.matchAll(/code = """\n([\s\S]*?)\n\s*"""/g)].map(m=>new Function('$var',m[1]));
const prepare=blocks[0],candidates=blocks[1],attach=blocks[2];
function input(){
 return {import_id:'SD-PROD-NHOW-TEST',metadata:{hotels:[{id:'lp225fcf',name:'nhow'}]},rates_http:{response:{status:200,result:{data:[{hotelId:'lp225fcf',roomTypes:[{rateType:'standard',offerId:'fixture',offerRetailRate:{currency:'EUR',amount:200},rates:[{mappedRoomId:123,name:'Actual supplier room',adultCount:2,childCount:0,boardType:'RO',cancellationPolicies:{refundableTag:'NRFN'},retailRate:{taxesAndFees:[{included:true,currency:'EUR',amount:10}],suggestedSellingPrice:[{currency:'EUR',amount:250}]}}]}]}]}}}};
}
test('import derives gallery only from the actual offered room and preserves original offer',()=>{
 const vars=input();vars.prepared=prepare(vars);assert.equal(vars.prepared.valid,true);
 assert.deepEqual(vars.prepared.hotel.images,[]);
 vars.room_details={response:{status:200,result:{data:{id:'lp225fcf',rooms:[{id:123,photos:[{url:'https://static.cupid.travel/room.jpg'}]},{id:124,photos:[{url:'https://static.cupid.travel/wrong.jpg'}]}]}}}};
 const photos=candidates(vars);assert.equal(photos.length,1);assert.equal(photos[0].caption,'Actual supplier room');
 const offer=JSON.stringify(vars.prepared.offer);
 vars.photo_selection={photos:[{...photos[0],sha256:'a'.repeat(64),dhash:'1'.repeat(16)}],algorithm:'sha256+dhash64-area-v2'};
 const result=attach(vars);assert.equal(JSON.stringify(result.offer),offer);
 assert.equal(result.hotel.mapped_room_id,123);assert.equal(result.hotel.photo_verification.status,'verified');
 assert.deepEqual(result.hotel.images,['https://static.cupid.travel/room.jpg']);
 vars.room_details.response.result.data.rooms.shift();assert.throws(()=>candidates(vars),/Confirmed room photos/);
});
test('import still refuses excluded taxes, package rates and missing room mapping',()=>{
 for(const mutate of [o=>o.rateType='package',o=>delete o.rates[0].mappedRoomId,o=>o.rates[0].retailRate.taxesAndFees[0].included=false]){
  const vars=input();mutate(vars.rates_http.response.result.data[0].roomTypes[0]);assert.equal(prepare(vars).valid,false);
 }
});
