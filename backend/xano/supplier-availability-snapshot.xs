// Private snapshot lookup rechecks approval, exact pricing/mapping signature and 60-second expiry.
query "supplier-deals/{deal_id}/availability-snapshot" verb=GET {
  api_group = "Admin"
  auth = "admin_users"
  input {
    int deal_id
  }
  stack {
    util.set_header {
      value = "Cache-Control: private, no-store"
      duplicates = "replace"
    }
    function.run "admin/guard" {
      input = {permission: null}
    } as $admin
    precondition ($admin.role == "superadmin" || $admin.role == "platform_admin") {
      error_type = "accessdenied"
      error = "Geen toegang tot leverancierscontrole."
    }
    db.query deals {
      where = $db.deals.id == $input.deal_id
      return = {type: "single"}
    } as $deal
    db.query supplier_deals {
      where = $db.supplier_deals.deal_id == $input.deal_id
      return = {type: "single"}
    } as $supplier
    db.query supplier_availability_snapshots {
      where = $db.supplier_availability_snapshots.deal_id == $input.deal_id && $db.supplier_availability_snapshots.environment == "sandbox"
      sort = {supplier_availability_snapshots.started_at: "desc", supplier_availability_snapshots.id: "desc"}
      return = {type: "single"}
    } as $snapshot
    api.lambda {
      code = """
function approvalSignature(deal,supplier){
  const canonical=value=>JSON.stringify(value,(_key,v)=>v&&typeof v==='object'&&!Array.isArray(v)?Object.fromEntries(Object.keys(v).sort().map(k=>[k,v[k]])):v);
  return canonical({deal_id:deal?.id,status:deal?.status,approved_at:deal?.approved_at,deleted_at:deal?.deleted_at,price:deal?.price,travel_period_start:deal?.travel_period_start,travel_period_end:deal?.travel_period_end,minimum_nights:deal?.minimum_nights,supplier_id:supplier?.id,provider:supplier?.provider,environment:supplier?.environment,hotel_id:supplier?.supplier_hotel_id,pricing:supplier?.pricing_config,mapping:supplier?.supplier_mapping||supplier?.supplier_content});
}
function readSnapshot(deal,supplier,row,now=Date.now()){
  const fail=message=>({deal_id:deal?.id,environment:'sandbox',status:'unknown',available:false,can_pay:false,quantity:null,quantity_known:false,customer_price:Number(deal?.price),currency:'EUR',message});
  if(!deal||!supplier||deal.status!=='active'||!deal.approved_at||deal.deleted_at||supplier.provider!=='nuitee'||supplier.environment!=='sandbox')return fail('Geen goedgekeurde sandboxdeal.');
  const value=row?.snapshot;
  if(!row||row.environment!=='sandbox'||row.deal_id!==deal.id||row.approval_signature!==approvalSignature(deal,supplier)||row.status!==value?.status||!Number.isFinite(row.checked_at)||row.checked_at>now||!Number.isFinite(row.valid_until)||row.valid_until<=now||row.valid_until-row.checked_at>60000||value?.deal_id!==deal.id||value.environment!=='sandbox'||value.checked_at!==row.checked_at||value.valid_until!==row.valid_until||value.customer_price!==Number(deal.price)||value.currency!=='EUR'||value.can_pay!==false)return fail('Geen verse voorraadcontrole voor deze goedgekeurde deal.');
  return value;
}
return readSnapshot($var.deal,$var.supplier,$var.snapshot);
      """
      timeout = 5
    } as $result
  }
  response = $result
}
