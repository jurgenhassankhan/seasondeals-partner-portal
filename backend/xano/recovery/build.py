from pathlib import Path
p=Path(__file__).parent
policy=(p/'evidence.js').read_text().split("if(typeof module")[0]
source='''// Read-only authoritative sandbox recovery evidence. Never submits a booking.
function "supplier/checkout/recovery_snapshot" {
 input { int intent_id }
 stack {
 db.get supplier_checkout_intents {field_name="id"
 field_value=$input.intent_id} as $intent
 precondition ($intent != null && $intent.provider_slug == "nuitee" && $intent.environment == "sandbox") {error_type="inputerror"
 error="Nuitee sandbox checkout required"}
 db.get orders {field_name="id"
 field_value=$intent.order_id} as $order
 precondition ($order != null && $intent.stripe_checkout_session_id != null) {error="Order and checkout required"}
 api.request {
 url="https://api.stripe.com/v1/checkout/sessions/" ~ ($intent.stripe_checkout_session_id|url_encode)
 method="GET"
 headers=["Authorization: Bearer " ~ $env.STRIPE_SECRET_KEY_test]
 timeout=15
 } as $session
 var $pi {value=null}
 var $refunds {value=null}
 conditional {if ($session.response.status == 200 && $session.response.result.payment_intent != null) {
 api.request {
 url="https://api.stripe.com/v1/payment_intents/" ~ ($session.response.result.payment_intent|url_encode) ~ "?expand[]=latest_charge.balance_transaction"
 method="GET"
 headers=["Authorization: Bearer " ~ $env.STRIPE_SECRET_KEY_test]
 timeout=15
 } as $payment_response
 var.update $pi {value=$payment_response}
 api.request {
 url="https://api.stripe.com/v1/refunds?limit=100&payment_intent=" ~ ($session.response.result.payment_intent|url_encode)
 method="GET"
 headers=["Authorization: Bearer " ~ $env.STRIPE_SECRET_KEY_test]
 timeout=15
 } as $refund_response
 var.update $refunds {value=$refund_response}
 }}
 var $booking {value=null}
 var $lookup {value=null}
 var $booking_id {value=$order.external_booking_id}
 conditional {if ($booking_id == null || $booking_id == "") {
 api.request {
 url="https://book.liteapi.travel/v3.0/bookings?clientReference=" ~ ($intent.client_reference|url_encode) ~ "&timeout=15"
 method="GET"
 headers=["Accept: application/json","X-API-Key: " ~ $env.NUITEE_SANDBOX_API_KEY]
 timeout=20
 } as $reference_response
 var.update $lookup {value=$reference_response}
 api.lambda {code="""
const a=$var.lookup.response?.result?.data;
if($var.lookup.response?.status!==200||!Array.isArray(a)||a.length!==1)return null;
const b=a[0];return (b.clientReference||b.client_reference)===$var.intent.client_reference?b.bookingId||null:null;
"""
 timeout=5} as $found_id
 var.update $booking_id {value=$found_id}
 }}
 conditional {if ($booking_id != null && $booking_id != "") {
 function.run "connector/adapters/nuitee/get_booking" {input={booking_id:$booking_id}} as $retrieved
 var.update $booking {value=$retrieved}
 }}
 api.lambda {code="""
'''+policy+'''
return recoveryEvidence($var.intent,$var.order,$var.session,$var.pi,$var.refunds,$var.lookup,$var.booking,Date.now());
"""
 timeout=10} as $evidence
 }
 response=$evidence
}
'''
(p/'recovery-snapshot.xs').write_text(source)
