const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const {nuiteeDealContent}=require('../backend/nuitee/deal-content.js');
const source=fs.readFileSync(__dirname+'/../js/shared-deal-preview.js','utf8');
const loader=source.slice(source.indexOf('  async function loadDeal()'),source.indexOf('  function bindPreviewNavigation()'));
const run=new Function('fetch','nuiteeDealContent',`return (async()=>{
 const CONFIG={adminEndpoint:'https://example.test/admin',tokenKey:'fixture'},dealId='18',isAdmin=true,availabilityPreview=false;
 const sessionStorage={getItem:()=> 'test-only-token',removeItem:()=>{}},window={location:{replace:()=>{}}},console={error:()=>{}};
 let deal=null,supplier=null,gallery=[],rendered=false,error=null;
 const showError=(title,message)=>{error=message},getImages=d=>d.external_image_urls||[],renderDeal=()=>{rendered=true},bindDealEvents=()=>{},bindPreviewNavigation=()=>{};
 ${loader}
 await loadDeal();return {deal,rendered,error};
})()`);
const response=(body,status=200)=>({ok:status===200,status,json:async()=>body});
const mapping={hotel:{id:'h1',name:'Provider hotel'},request:{hotel_ids:['h1'],checkin:'2026-11-27',checkout:'2026-11-29',occupancies:[{adults:2}]},offer:{rates:[{name:'Supplier room',adultCount:2,childCount:0,boardType:'RO'}]}};
test('actual legacy admin preview contract without source still loads automatic supplier inclusions',async()=>{
 const result=await run(async url=>url.endsWith('/preview')?response({preview:{enabled:true,public:false,bookable:false},deal:{id:18}}):response({supplier_deal:{deal_id:18,provider:'nuitee',supplier_hotel_id:'h1',supplier_mapping:mapping}}),nuiteeDealContent);
 assert.equal(result.error,null);assert.equal(result.rendered,true);assert.equal(result.deal.source,'provider_sync');
 assert.equal(result.deal.hotel_name,'Provider hotel');assert.equal(result.deal.included_items.length,3);
});
test('supplier lookup failures and wrong deal binding cannot silently become a partner preview',async()=>{
 for(const supplierResult of [response({},500),response({supplier_deal:{deal_id:19,provider:'nuitee'}})]){
  const result=await run(async url=>url.endsWith('/preview')?response({preview:{enabled:true,public:false,bookable:false},deal:{id:18}}):supplierResult,nuiteeDealContent);
  assert.equal(result.rendered,false);assert.ok(result.error);
 }
 const partner=await run(async url=>url.endsWith('/preview')?response({preview:{enabled:true,public:false,bookable:false},deal:{id:18}}):response({},404),nuiteeDealContent);
 assert.equal(partner.rendered,true);assert.equal(partner.deal.source,undefined);
});
