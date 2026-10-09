'use strict';
function approvalSignature(deal,supplier){
  const canonical=value=>JSON.stringify(value,(_key,v)=>v&&typeof v==='object'&&!Array.isArray(v)?Object.fromEntries(Object.keys(v).sort().map(k=>[k,v[k]])):v);
  return canonical({deal_id:deal?.id,status:deal?.status,approved_at:deal?.approved_at,deleted_at:deal?.deleted_at,price:deal?.price,travel_period_start:deal?.travel_period_start,travel_period_end:deal?.travel_period_end,minimum_nights:deal?.minimum_nights,supplier_id:supplier?.id,provider:supplier?.provider,environment:supplier?.environment,hotel_id:supplier?.supplier_hotel_id,pricing:supplier?.pricing_config,mapping:supplier?.supplier_mapping||supplier?.supplier_content});
}
function readSnapshot(deal,supplier,row,now=Date.now()){
  const fail=message=>({deal_id:deal?.id,environment:'sandbox',status:'unknown',available:false,can_pay:false,quantity:null,quantity_known:false,customer_price:Number(deal?.price),currency:'EUR',message});
  if(!deal||!supplier||deal.status!=='active'||!deal.approved_at||deal.deleted_at||supplier.provider!=='nuitee'||supplier.environment!=='sandbox')return fail('Geen goedgekeurde sandboxdeal.');
  const value=row?.snapshot;
  if(!row||row.environment!=='sandbox'||row.deal_id!==deal.id||row.approval_signature!==approvalSignature(deal,supplier)||row.status!==value?.status||!Number.isFinite(row.checked_at)||row.checked_at>now||!Number.isFinite(row.valid_until)||row.valid_until<=now||row.valid_until-row.checked_at>90000||value?.deal_id!==deal.id||value.environment!=='sandbox'||value.checked_at!==row.checked_at||value.valid_until!==row.valid_until||value.customer_price!==Number(deal.price)||value.currency!=='EUR'||value.can_pay!==false)return fail('Geen verse voorraadcontrole voor deze goedgekeurde deal.');
  return value;
}
function readDuringRefresh(deal,supplier,latest,completed,now=Date.now()){
  if(latest?.status!=='checking')return readSnapshot(deal,supplier,latest,now);
  if(latest.environment!=='sandbox'||latest.deal_id!==deal?.id||latest.approval_signature!==approvalSignature(deal,supplier)||!Number.isFinite(latest.started_at)||latest.started_at>now||now-latest.started_at>20000||!completed||completed.started_at>latest.started_at)return readSnapshot(deal,supplier,latest,now);
  const value=readSnapshot(deal,supplier,completed,now);
  return value.available===true?{...value,refreshing:true}:readSnapshot(deal,supplier,latest,now);
}
module.exports={approvalSignature,readSnapshot,readDuringRefresh};

