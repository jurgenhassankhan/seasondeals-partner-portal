const {test}=require('node:test');
const assert=require('node:assert/strict');
const {createHash}=require('node:crypto');
const {Jimp}=require(process.env.PHOTO_TEST_JIMP || '../backend/nuitee/node_modules/jimp');
const {selectRoomPhotos}=require('../backend/nuitee/photo-selector.js');
const digest=b=>createHash('sha256').update(b).digest('hex');
function picture(seed) {
 const im=new Jimp({width:240,height:160,color:0xffffffff});
 for(let y=0;y<160;y++)for(let x=0;x<240;x++) {
  const v=Math.floor(128+60*Math.sin(x/(13+seed)+y/(7+seed))+50*Math.cos(y/(11+seed)-x/(19+seed)));
  const i=(y*240+x)*4;im.bitmap.data[i]=v;im.bitmap.data[i+1]=v;im.bitmap.data[i+2]=v;
 }
 return im;
}
test('real pixels reject same image at another URL, size and encoding; keep distinct images',async()=>{
 const original=picture(1);
 const files=[await original.getBuffer('image/jpeg'),await original.getBuffer('image/jpeg'),await original.clone().resize({w:480,h:320}).getBuffer('image/png'),await picture(15).getBuffer('image/jpeg')];
 const photos=files.map((_,i)=>({url:`https://static.cupid.travel/${i}.jpg`}));
 const result=await selectRoomPhotos(photos,{Jimp,Buffer,digest,fetchImpl:async u=>new Response(files[Number(new URL(u).pathname.slice(1).split('.')[0])])});
 assert.equal(result.photos.length,2);assert.equal(result.rejected_count,2);
 assert.equal(result.algorithm,'sha256+dhash64-area-v2');
});
test('untrusted hosts never fetched; invalid images cannot produce verified gallery',async()=>{
 let calls=0;
 await assert.rejects(selectRoomPhotos([{url:'https://evil.test/a.jpg'}],{Jimp,Buffer,digest,fetchImpl:async()=>{calls++;}}),/import blocked/);
 assert.equal(calls,0);
 await assert.rejects(selectRoomPhotos([{url:'https://static.cupid.travel/bad.jpg'}],{Jimp,Buffer,digest,fetchImpl:async()=>new Response('not image')}),/import blocked/);
});
test('stop at five unique photographs',async()=>{
 let calls=0;
 const photos=Array.from({length:10},(_,i)=>({url:`https://static.cupid.travel/${i}.jpg`}));
 const result=await selectRoomPhotos(photos,{Jimp,Buffer,digest,fetchImpl:async()=>new Response(await picture(++calls*8).getBuffer('image/jpeg'))});
 assert.equal(result.photos.length,5);assert.ok(calls<=10);
});
