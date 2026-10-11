// Internal one-order mail test. Run recipient must be explicitly authorized by the user. Never creates a booking.
function "supplier/checkout/send_approved_order100_mail" {
 input {text recipient filters=trim}
 stack {
 api.lambda {
 code="""
return {valid:/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test($input.recipient||'')};
"""
 timeout=5
 } as $recipient_check
 precondition ($recipient_check.valid == true) {error="Valid approved email required"}
 db.transaction {stack {
 db.get supplier_checkout_intents {field_name="id"
 field_value=5
 lock=true} as $intent
 precondition ($intent.order_id == 100 && $intent.environment == "sandbox" && $intent.status == "booked" && $intent.checkout_context.voucher_id == 44) {error="Expected confirmed sandbox fixture required"}
 api.lambda {
 code="""
const c=$var.intent.checkout_context,m=c.confirmation_mail;
if(!m?.html)throw new Error('Prepared confirmation missing');
if(m.authorized&&m.to!==$input.recipient)throw new Error('Recipient is immutable after approval');
return {...c,confirmation_mail:{...m,to:$input.recipient,authorized:true,approval_scope:'User explicitly approved this one sandbox confirmation',authorized_at:m.authorized_at||Date.now(),idempotency_key:'nuitee-sandbox-voucher-5-owner-20261011'}};
"""
 timeout=5
 } as $context
 db.edit supplier_checkout_intents {field_name="id"
 field_value=5
 data={checkout_context:$context,updated_at:now}} as $saved
 }}
 function.run "supplier/checkout/finalize_sandbox" {input={supplier_checkout_intent_id:5}} as $result
 api.request {
 url="https://api.resend.com/emails/" ~ ($result.resend_id|url_encode)
 method="GET"
 headers=["Authorization: Bearer " ~ $env.RESEND_API_KEY]
 } as $delivery
 }
 response={finalization:$result,delivery_http_status:$delivery.response.status,delivery_status:($delivery.response.result.last_event ?? null),delivery_email_id:($delivery.response.result.id ?? null)}
}