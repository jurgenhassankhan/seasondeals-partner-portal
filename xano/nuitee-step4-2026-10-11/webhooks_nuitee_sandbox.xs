// Isolated sandbox callback. Fetches the authoritative event from Stripe; ignores untrusted payment payload fields.
query "webhooks/nuitee-sandbox" verb=POST {
 input { text id filters=trim }
 stack {
 api.lambda {code="""
return {valid:/^evt_[A-Za-z0-9]{8,100}$/.test($input.id||'')};
"""
 timeout=5} as $input_check
 precondition ($input_check.valid == true) {error_type="inputerror"
 error="Valid Stripe event ID required"}
 api.request {
 url="https://api.stripe.com/v1/events/" ~ ($input.id|url_encode)
 method="GET"
 headers=["Authorization: Bearer " ~ ($env.STRIPE_SECRET_KEY_test|to_text)]
 } as $event_response
 precondition ($event_response.response.status == 200 && $event_response.response.result.id == $input.id && $event_response.response.result.object == "event" && $event_response.response.result.livemode == false) {error_type="accessdenied"
 error="Stripe did not verify this sandbox event"}
 var $event {value=$event_response.response.result}
 api.lambda {code="""
const e=$var.event,s=e.data?.object;
const accepted=['checkout.session.completed','checkout.session.async_payment_succeeded'].includes(e.type)&&s?.object==='checkout.session'&&s.livemode===false&&s.payment_status==='paid'&&s.metadata?.supplier_fulfillment==='nuitee'&&s.metadata?.supplier_flow==='step4_sandbox_v1';
return {accepted,intent_id:accepted?Number(s.metadata.supplier_checkout_intent_id):0,order_id:accepted?Number(s.metadata.supplier_order_id):0,session_id:s?.id};
"""
 timeout=5} as $route
 conditional {if ($route.accepted != true) {return {value={received:true,ignored:true}}}}
 db.get supplier_checkout_intents {field_name="id"
 field_value=$route.intent_id} as $intent
 precondition ($intent != null && $intent.environment == "sandbox" && $intent.provider_slug == "nuitee" && $intent.order_id == $route.order_id && $intent.stripe_checkout_session_id == $route.session_id) {error="Verified event does not match supplier checkout"}
 function.run "supplier/checkout/fulfill_sandbox_payment" {input={supplier_checkout_intent_id:$intent.id}} as $result
 var $finalization {value=null}
 conditional {if ($result.status == "booked") {
 function.run "supplier/checkout/finalize_sandbox" {input={supplier_checkout_intent_id:$intent.id}} as $finished
 var.update $finalization {value=$finished}
 }}
 db.transaction {
 stack {
 db.get supplier_checkout_intents {field_name="id"
 field_value=$intent.id
 lock=true} as $latest
 api.lambda {code="""
const c=$var.latest.checkout_context||{},e=$var.event;
return {...c,webhook:{event_id:e.id,event_type:e.type,verified_via:'Stripe Events API',received_at:Date.now(),deliveries:Number(c.webhook?.deliveries||0)+1,result_status:$var.result.status}};
"""
 timeout=5} as $context
 db.edit supplier_checkout_intents {field_name="id"
 field_value=$intent.id
 data={checkout_context:$context,updated_at:now}} as $recorded
 }
 }
 }
 response={received:true,status:$result.status,idempotent_replay:($result.idempotent_replay ?? false),finalization:$finalization}
 history="disabled"
}