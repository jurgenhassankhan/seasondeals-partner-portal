// Refresh only the approved reference stay. No deal, order or booking writes.
function "supplier/availability/refresh" {
  input {
    int deal_id
  }
  stack {
    db.query deals {
      where = $db.deals.id == $input.deal_id
      return = {type: "single"}
    } as $deal
    db.query supplier_deals {
      where = $db.supplier_deals.deal_id == $input.deal_id
      return = {type: "single"}
    } as $supplier
    precondition ($supplier.provider == "nuitee" && $supplier.environment == "sandbox") {
      error_type = "accessdenied"
      error = "Alleen sandboxvoorraad verversen."
    }
    api.lambda {
      code = """
function approvalSignature(deal,supplier){
  const canonical=value=>JSON.stringify(value,(_key,v)=>v&&typeof v==='object'&&!Array.isArray(v)?Object.fromEntries(Object.keys(v).sort().map(k=>[k,v[k]])):v);
  return canonical({deal_id:deal?.id,status:deal?.status,approved_at:deal?.approved_at,deleted_at:deal?.deleted_at,price:deal?.price,travel_period_start:deal?.travel_period_start,travel_period_end:deal?.travel_period_end,minimum_nights:deal?.minimum_nights,supplier_id:supplier?.id,provider:supplier?.provider,environment:supplier?.environment,hotel_id:supplier?.supplier_hotel_id,pricing:supplier?.pricing_config,mapping:supplier?.supplier_mapping||supplier?.supplier_content});
}
const mapping=$var.supplier.supplier_mapping||$var.supplier.supplier_content||{};
const input=mapping.request||{};
return {signature:approvalSignature($var.deal,$var.supplier),started_at:Date.now(),checkin:input.checkin||'',checkout:input.checkout||'',guests:input.occupancies?.[0]?.adults||0};
      """
      timeout = 5
    } as $context
    db.add supplier_availability_snapshots {
      data = {deal_id: $input.deal_id, environment: "sandbox", started_at: $context.started_at, checked_at: null, valid_until: null, approval_signature: $context.signature, status: "checking", snapshot: null}
    } as $pending
    var $result {
      value = {status: "unknown", available: false, can_pay: false, message: "De leverancier kon de beschikbaarheid niet bevestigen."}
    }
    try_catch {
      try {
        function.run "supplier/availability/check" {
          input = {deal_id: $input.deal_id, checkin: $context.checkin, checkout: $context.checkout, guests: $context.guests}
        } as $result
      }
      catch {
        var.update $result {
          value = {status: "unknown", available: false, can_pay: false, message: "De leverancier kon de beschikbaarheid niet bevestigen."}
        }
      }
    }
    api.lambda {
      code = """
const now=Date.now();
const result=$var.result||{};
return {...result,deal_id:$input.deal_id,environment:'sandbox',checked_at:now,valid_until:now+90000,customer_price:Number($var.deal?.price),currency:'EUR',can_pay:false,quantity:null,quantity_known:false};
      """
      timeout = 5
    } as $snapshot
    // Each refresh owns its row. Readers select the newest started row,
    // so a slower older run cannot overwrite a newer observation.
    db.edit supplier_availability_snapshots {
      field_name = "id"
      field_value = $pending.id
      data = {checked_at: $snapshot.checked_at, valid_until: $snapshot.valid_until, status: $snapshot.status, snapshot: $snapshot}
    } as $saved

  }
  response = $snapshot
}

