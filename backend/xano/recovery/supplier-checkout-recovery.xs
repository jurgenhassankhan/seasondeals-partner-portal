// Private sandbox recovery. No booking creation and no live payment credentials.
query "supplier-checkout-recovery" verb=POST {


 api_group="Admin"
 auth="admin_users"
 input {


 int intent_id?=0
 int order_id?=0
 text action?="inspect" filters=trim
 text expected_version? filters=trim
 int amount_minor?=0 filters=min:0
 text note? filters=trim
 

}


 stack {


 function.run "admin/guard" {

input={

permission:null

}



} as $admin
 precondition ($admin.is_active && ($admin.role == "superadmin" || $admin.role == "platform_admin")) {

error_type="accessdenied"
 error="Active operations administrator required"

}


 util.set_header {

value="Cache-Control: no-store, private"

}


 precondition ($input.action == "inspect" || $input.action == "reconcile" || $input.action == "cancel" || $input.action == "refund" || $input.action == "retry_refund") {

error_type="inputerror"
 error="Unknown recovery action"

}


 var $intent_id {

value=$input.intent_id

}


 conditional {

if ($intent_id <= 0) {


 db.query supplier_checkout_intents {

where=$db.supplier_checkout_intents.order_id == $input.order_id && $db.supplier_checkout_intents.provider_slug == "nuitee" && $db.supplier_checkout_intents.environment == "sandbox"
 return={

type:"list"

}



} as $candidates
 precondition (($candidates|count) == 1) {

error="Exactly one Nuitee sandbox checkout required; other order routes are excluded"

}


 var.update $intent_id {

value=$candidates.0.id

}


 

}



}


 function.run "supplier/checkout/recovery_snapshot" {

input={

intent_id:$intent_id

}



} as $before
 precondition ($input.order_id == 0 || ($before.order_id ?? $input.order_id) == $input.order_id) {

error="Order and checkout do not match"

}


 var $result {

value=$before

}


 conditional {

if ($input.action != "inspect") {


 precondition ($before.valid == true && $before.version == $input.expected_version) {

error="Status changed or uncertain; inspect again"

}


 api.lambda {

code="""
const e=$var.before,a=$input.action;
if(!e.allowed.includes(a))throw new Error('Action not permitted by current provider/payment evidence');
if(a!=='reconcile'&&(!$input.note||$input.note.length<5))throw new Error('An operations reason is required');
if(a==='refund'&&(!Number.isSafeInteger($input.amount_minor)||$input.amount_minor<=0||$input.amount_minor>e.remaining_minor))throw new Error('Refund amount must be positive and within the remaining payment');
return true;
"""
 timeout=5

} as $permitted
 precondition ($permitted == true) {

error="Recovery action not permitted"

}


 conditional {

if ($input.action == "reconcile") {


 function.run "supplier/checkout/recovery_apply" {

input={

intent_id:$intent_id,evidence:$before,admin_id:$auth.id

}



} as $applied
 

}

 else {


 db.transaction {

stack {


 db.get supplier_checkout_intents {

field_name="id"
 field_value=$intent_id
 lock=true

} as $locked
 db.get orders {

field_name="id"
 field_value=$locked.order_id
 lock=true

} as $locked_order
 api.lambda {

code="""
const i=$var.locked,o=$var.locked_order,e=$var.before,c=i.checkout_context||{},r=c.recovery||{},old=r.operation;
const version=JSON.stringify([i.updated_at,o.updated_at,e.booking?.status||'UNKNOWN',e.booking_id||null,e.refunded_minor,e.pending_refund_minor,old?.key||null]);
if(version!==e.version||Date.now()-e.checked_at>60000||i.environment!=='sandbox')throw new Error('Concurrent change; inspect again');
let op;
if($input.action==='retry_refund'){
 if(old?.action!=='refund'||Date.now()-old.started_at>=82800000||Date.now()-(old.last_attempt_at||old.started_at)<60000)throw new Error('Refund retry blocked');
 op={...old,last_attempt_at:Date.now(),attempts:(old.attempts||1)+1};
}else{
 if(old)throw new Error('An operation is already pending');
 const seq=(r.sequence||0)+1;
 op={action:$input.action,amount_minor:$input.amount_minor,actor:$auth.id,note:$input.note.slice(0,500),key:'sd-sbx-recovery-'+i.id+'-'+seq,started_at:Date.now(),last_attempt_at:Date.now(),attempts:1,booking_id:e.booking_id};
}
return {operation:op,context:{...c,recovery:{...r,sequence:$input.action==='retry_refund'?r.sequence:(r.sequence||0)+1,operation:op,history:[...(r.history||[]),{...op,event:'reserved'}].slice(-50)}}};
"""
 timeout=5

} as $reserved
 precondition ($reserved.operation.key != null) {

error="Could not reserve recovery operation"

}


 db.edit supplier_checkout_intents {

field_name="id"
 field_value=$locked.id
 data={

status:"manual_attention",checkout_context:$reserved.context,updated_at:now

}



} as $claimed
 

}



}


 // Reservation is committed BEFORE any irreversible external request.
 var $external {

value=null

}


 try_catch {

try {


 conditional {

if ($input.action == "cancel") {


 function.run "connector/adapters/nuitee/cancel_booking" {

input={

booking_id:$reserved.operation.booking_id

}



} as $cancelled
 var.update $external {

value=$cancelled

}


 

}

 else {


 api.request {


 url="https://api.stripe.com/v1/refunds"
 method="POST"
 params={

payment_intent:$before.payment_intent_id,amount:$reserved.operation.amount_minor,reason:"requested_by_customer",metadata:{

seasondeals_recovery_key:$reserved.operation.key,supplier_checkout_intent_id:$intent_id

}



}


 headers=["Authorization: Bearer " ~ $env.STRIPE_SECRET_KEY_test,"Content-Type: application/x-www-form-urlencoded","Idempotency-Key: " ~ $reserved.operation.key]
 timeout=20
 

} as $refund_response
 var.update $external {

value=$refund_response

}


 

}



}


 

}

 catch {

var.update $external {

value=null

}



}



}


 conditional {
if ($input.action == "cancel" && $external.success == true) {

 api.lambda {
code="""
const d=$var.external.data,op=$var.reserved.operation;
if(!d||d.bookingId!==op.booking_id||d.currency!=='EUR'||!['CANCELLED','CANCELLED_WITH_CHARGES'].includes(d.status)||!Number.isFinite(d.cancellation_fee)||d.cancellation_fee<0||!Number.isFinite(d.refund_amount)||d.refund_amount<0)return null;
return {booking_id:d.bookingId,status:d.status,fee:d.cancellation_fee,refund:d.refund_amount,at:Date.now()};
"""
 timeout=5
} as $cancellation_evidence
 conditional {
if ($cancellation_evidence != null) {

 db.transaction {
stack {

 db.get supplier_checkout_intents {
field_name="id"
 field_value=$intent_id
 lock=true
} as $latest
 precondition ($latest.checkout_context.recovery.operation.key == $reserved.operation.key) {
error="Recovery operation changed"
}

 api.lambda {
code="""
return {...$var.latest.checkout_context,recovery:{...$var.latest.checkout_context.recovery,cancellation:$var.cancellation_evidence}};
"""
 timeout=5
} as $cancellation_context
 db.edit supplier_checkout_intents {
field_name="id"
 field_value=$intent_id
 data={
checkout_context:$cancellation_context,updated_at:now
}

} as $saved_cancellation
 
}

}

 
}

}

 
}

}

 // Never mark an external request as completed from HTTP status alone.
 // A timeout retains the immutable reservation. Next inspect checks the provider first.
 

}


 

}


 function.run "supplier/checkout/recovery_snapshot" {

input={

intent_id:$intent_id

}



} as $after
 var.update $result {

value=$after

}


 conditional {

if ($input.action != "reconcile" && $after.valid == true) {


 function.run "supplier/checkout/recovery_apply" {

input={

intent_id:$intent_id,evidence:$after,admin_id:$auth.id

}



} as $after_applied
 function.run "supplier/checkout/recovery_snapshot" {

input={

intent_id:$intent_id

}



} as $final
 var.update $result {

value=$final

}


 

}



}


 

}



}


 api.lambda {

code="""
const e=$var.result;
const keys=['valid','allowed','message','checked_at','version','order_id','intent_id','environment','supplier_status','booking_id','client_reference','paid_minor','refunded_minor','pending_refund_minor','remaining_minor','currency','cancellation_terms','cancellation_fee','supplier_refund','refund_status','operation'];
return Object.fromEntries(keys.filter(k=>e[k]!==undefined).map(k=>[k,e[k]]));
"""
 timeout=5

} as $safe_result
 

}


 response=$safe_result


}


