'use strict';
const test=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const dir=__dirname+'/../backend/xano/approval-publication/';
const lambda=name=>new Function('$var',fs.readFileSync(dir+name+'.xs','utf8').match(/code = """\n([\s\S]*?)\n"""/)[1]);
test('supplier public projection exposes hotel content and no internal review or provider data',()=>{
 const d={id:18,source:'provider_sync',status:'active',is_active:true,hotel_name:'nhow Amsterdam RAI',city:'Amsterdam',price:317.39,external_image_urls:['https://example.test/hotel.jpg','javascript:bad'],review_notes:'private',supplier_mapping:{secret:'private'},pricing_config:{cost:1},external_id:'internal',inventory:0};
 const list=lambda('list')({result:[{id:4,source:'hotel'}],supplier_public_rows:[d],production_status:{can_sell:false}});
 assert.equal(list[0].id,4);const item=list[1];assert.equal(item.hotel.name,d.hotel_name);assert.equal(item.inventory,null);assert.equal(item.booking_enabled,false);assert.deepEqual(item.images,['https://example.test/hotel.jpg']);
 for(const key of ['review_notes','supplier_mapping','pricing_config','external_id']) assert.equal(key in item,false);
 for(const name of ['detail64','detail71'])assert.deepEqual(lambda(name)({deal:d,result:d,production_status:{can_sell:false}}),item);
});
test('partner detail projection preserves the existing contract',()=>{
 const d={id:4,source:'hotel',hotel:{name:'Partner'},inventory:5};
 for(const name of ['detail64','detail71'])assert.deepEqual(lambda(name)({deal:d,result:d,production_status:{can_sell:false}}),d);
});
test('only submitted deals can be reviewed in either environment',()=>{
 const src=fs.readFileSync(__dirname+'/../admin/js/deal-detail-v5.js','utf8');
 const expression=src.match(/const reviewAllowed = (.*);/)[1];
 const allowed=(environment,status,role='superadmin',supplierError=null)=>vm.runInNewContext(expression,{core:{canReview:a=>a.role==='superadmin'},admin:{role},deal:{status},supplierDeal:{environment},supplierError});
 assert.equal(allowed('production','draft'),false);assert.equal(allowed('production','pending_approval'),true);assert.equal(allowed('sandbox','draft'),false);assert.equal(allowed('sandbox','pending_approval'),true);assert.equal(allowed('production','draft','viewer'),false);assert.equal(allowed('production','draft','superadmin','unavailable'),false);assert.equal(allowed('production','active'),false);
});
