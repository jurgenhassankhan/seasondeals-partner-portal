// Apply verified recovery evidence under the same intent lock used by fulfillment.
function "supplier/checkout/recovery_apply" {

 input {
int intent_id
 json evidence
 int admin_id
}

 stack {

 precondition ($input.evidence.valid == true && $input.evidence.intent_id == $input.intent_id && $input.evidence.environment == "sandbox") {
error="Verified sandbox evidence required"
}

 db.transaction {
stack {

 db.get supplier_checkout_intents {
field_name="id"
 field_value=$input.intent_id
 lock=true
} as $i
 db.get orders {
field_name="id"
 field_value=$i.order_id
 lock=true
} as $o
 api.lambda {
code="""
const i=$var.i,o=$var.o,e=$input.evidence,old=i.checkout_context?.recovery||{},op=old.operation;
if(i.environment!=='sandbox'||i.provider_slug!=='nuitee'||i.order_id!==e.order_id||Date.now()-e.checked_at>60000)throw new Error('Recovery evidence expired or changed');
const version=JSON.stringify([i.updated_at,o.updated_at,e.booking?.status||'UNKNOWN',e.booking_id||null,e.refunded_minor,e.pending_refund_minor,op?.key||null]);
if(version!==e.version)throw new Error('Order changed; inspect again');
const terminal=e.cancelled||e.no_booking,full=e.refunded_minor===e.paid_minor;
let operation=op;
if(op?.action==='cancel'&&e.cancelled)operation=null;
if(op?.action==='refund'&&e.refund_id&&['succeeded','failed','canceled'].includes(e.refund_status))operation=null;
const safe={checked_at:e.checked_at,supplier_status:e.supplier_status,paid_minor:e.paid_minor,refunded_minor:e.refunded_minor,pending_refund_minor:e.pending_refund_minor,cancellation_fee:e.cancellation_fee,supplier_refund:e.supplier_refund,refund_status:e.refund_status};
const history=[...(old.history||[]),{at:Date.now(),actor:$input.admin_id,action:'reconcile',...safe}].slice(-50);
return {terminal,full,intent_status:full?'refunded':e.cancelled?'cancelled':terminal?'manual_attention':operation?'manual_attention':'booked',order_status:full?'refunded':terminal?'cancelled':'paid',payment_status:full?'refunded':'paid',context:{...i.checkout_context,recovery:{...old,operation,last:safe,history}},booking_status:e.cancelled?'cancelled':'confirmed',provider_status:terminal?'error':'confirmed'};
"""
 timeout=5
} as $state
 db.query supplier_bookings {
where=$db.supplier_bookings.provider_slug == "nuitee" && $db.supplier_bookings.environment == "sandbox" && $db.supplier_bookings.external_booking_id == $input.evidence.booking_id
 return={
type:"single"
}

} as $b
 conditional {
if ($input.evidence.booking_id != null) {

 precondition ($b == null || $b.order_id == null || $b.order_id == $i.order_id) {
error="Supplier booking belongs to another order"
}

 conditional {
if ($b == null) {

 db.add supplier_bookings {
data={
provider_slug:"nuitee",environment:"sandbox",external_booking_id:$input.evidence.booking_id,client_reference:$i.client_reference,order_id:$i.order_id,currency:"EUR",booking_status:$state.booking_status,payment_status:$state.payment_status,selling_price:$i.selling_price,supplier_amount:$input.evidence.supplier_amount,processing_fee:$input.evidence.processing_fee,stripe_fee:$input.evidence.stripe_fee,created_at:now,updated_at:now
}

} as $created_booking
 
}
 else {

 db.edit supplier_bookings {
field_name="id"
 field_value=$b.id
 data={
booking_status:$state.booking_status,payment_status:$state.payment_status,cancellation_status:$input.evidence.supplier_status,cancellation_fee:$input.evidence.cancellation_fee,refund_amount:$input.evidence.supplier_refund,last_synced_at:now,updated_at:now
}

} as $updated_booking
 
}

}

 
}

}

 db.query vouchers {
where=$db.vouchers.order_id == $i.order_id
 return={
type:"list"
}

} as $vouchers
 conditional {
if ($state.terminal == true) {

 foreach ($vouchers) {
each as $v {

 db.edit vouchers {
field_name="id"
 field_value=$v.id
 data={
redemption_status:"cancelled",status:"cancelled",updated_at:now
}

} as $invalidated
 
}

}

 
}

}

 db.get payments {
field_name="stripe_payment_intent_id"
 field_value=$input.evidence.payment_intent_id
} as $payment
 precondition ($payment == null || $payment.order_id == $i.order_id) {
error="Payment belongs to another order"
}

 conditional {
if ($payment == null) {

 db.add payments {
data={
order_id:$i.order_id,stripe_payment_intent_id:$input.evidence.payment_intent_id,stripe_charge_id:$input.evidence.charge_id,amount:$i.selling_price,currency:"EUR",status:"succeeded",refund_amount:($input.evidence.refunded_minor / 100)
}

} as $new_payment
 
}
 else {

 db.edit payments {
field_name="id"
 field_value=$payment.id
 data={
refund_amount:($input.evidence.refunded_minor / 100),updated_at:now
}

} as $updated_payment
 
}

}

 conditional {
if ($state.full == true) {

 db.query payments {
where=$db.payments.order_id == $i.order_id && $db.payments.stripe_payment_intent_id == $input.evidence.payment_intent_id
 return={
type:"single"
}

} as $full_payment
 db.edit payments {
field_name="id"
 field_value=$full_payment.id
 data={
status:"refunded",updated_at:now
}

} as $refunded_payment
 
}

}

 db.edit orders {
field_name="id"
 field_value=$o.id
 data={
status:$state.order_status,payment_status:$state.payment_status,external_booking_id:$input.evidence.booking_id,provider_sync_status:$state.provider_status,provider_sync_error:null,updated_at:now
}

} as $updated_order
 db.edit supplier_checkout_intents {
field_name="id"
 field_value=$i.id
 data={
status:$state.intent_status,stripe_payment_intent_id:$input.evidence.payment_intent_id,checkout_context:$state.context,last_error:null,updated_at:now
}

} as $updated_intent
 function.run "audit/log" {
input={
user_id:$input.admin_id,user_type:"admin",resource_table:"orders",resource_id:$o.id,action:"nuitee_recovery_reconciled",new_values:$state.context.recovery.last
}

} as $audit
 
}

}

 
}

 response={
success:true,order_id:$o.id,status:$state.order_status
}


}

