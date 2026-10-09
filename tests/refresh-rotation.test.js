const {test}=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
test('rotation reaches more than ten deals and excludes unapproved or still checking deals',()=>{
 const source=fs.readFileSync(require('node:path').join(__dirname,'../backend/xano/nuitee-sandbox-availability-refresh.xs'),'utf8');
 const code=source.match(/code = """\n([\s\S]*?)\n\s*"""/)[1];
 const now=100000,suppliers=Array.from({length:41},(_,i)=>({deal_id:i+1}));
 const deals=suppliers.map(s=>({id:s.deal_id,approved_at:1}));
 const select=recent=>vm.runInNewContext('(function(){'+code+'})()',{Date:{now:()=>now},$var:{suppliers,deals,recent}});
 let recent=[];const seen=new Set();for(let round=0;round<3;round++){for(const s of select(recent)){seen.add(s.deal_id);recent.push({deal_id:s.deal_id,started_at:now+round,status:'available'});}}assert.equal(seen.size,41);
 deals[0].approved_at=null;recent=[{deal_id:2,started_at:now-1,status:'checking'}];assert.equal(select(recent).some(s=>[1,2].includes(s.deal_id)),false);
});
