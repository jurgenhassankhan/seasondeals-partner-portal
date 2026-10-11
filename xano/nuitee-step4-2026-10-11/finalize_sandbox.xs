// Sandbox only. Sends the saved confirmation only when its recipient has explicit recorded approval.
function "supplier/checkout/finalize_sandbox" {
 input { int supplier_checkout_intent_id }
 stack {
 function.run "connector/stripe/verify_supplier_payment" {input={supplier_checkout_intent_id:$input.supplier_checkout_intent_id}} as $verified
 db.get supplier_checkout_intents {field_name="id"
field_value=$input.supplier_checkout_intent_id} as $intent
 precondition ($intent.status == "booked" && $intent.environment == "sandbox") {error="Confirmed sandbox booking required"}
 db.get orders {field_name="id"
field_value=$intent.order_id} as $order
 precondition ($order.provider_sync_status == "confirmed" && $order.external_booking_id != null) {error="Supplier confirmation missing"}
 function.run "connector/adapters/nuitee/get_booking" {input={booking_id:$order.external_booking_id}} as $supplier
 api.request {
 url="https://api.stripe.com/v1/payment_intents/" ~ ($verified.stripe_payment_intent_id|url_encode) ~ "?expand[]=latest_charge.balance_transaction"
 method="GET"
 headers=["Authorization: Bearer " ~ $env.STRIPE_SECRET_KEY_test]
 } as $stripe
 api.lambda {
 code="""
const d=$var.supplier.data,p=$var.stripe.response.result,c=p?.latest_charge,b=c?.balance_transaction,i=$var.intent,o=$var.order;
const valid=$var.supplier.success===true&&d?.status==='CONFIRMED'&&Number(d.sandbox)===1&&d.bookingId===o.external_booking_id&&d.clientReference===i.client_reference&&d.currency==='EUR'&&Number.isFinite(d.price)&&d.price>=0&&Number.isFinite(d.processingFee)&&d.processingFee>=0&&$var.stripe.response.status===200&&p.id===$var.verified.stripe_payment_intent_id&&p.livemode===false&&p.status==='succeeded'&&b?.object==='balance_transaction'&&b.currency==='eur'&&Number.isInteger(b.fee)&&b.fee>=0&&b.amount===Math.round(i.selling_price*100);
if(!valid) throw new Error('Actual supplier or Stripe fees not yet verifiable');
return {supplier_amount:d.price,processing_fee:d.processingFee,stripe_fee:b.fee/100,seasondeals_margin:Math.round((i.selling_price-d.price-d.processingFee-b.fee/100)*100)/100,balance_transaction_id:b.id,stripe_charge_id:c.id,verified_at:Date.now(),status:'reconciled'};
"""
 timeout=5
 } as $financials
 var $mail {value=null}
 db.transaction {
 stack {
 db.get supplier_checkout_intents {field_name="id"
field_value=$intent.id
lock=true} as $locked
 precondition ($locked.status == "booked") {error="Booking state changed"}
 db.query supplier_bookings {where=$db.supplier_bookings.order_id == $intent.order_id && $db.supplier_bookings.external_booking_id == $order.external_booking_id && $db.supplier_bookings.environment == "sandbox"
return={type:"single"}} as $booking
 precondition ($booking != null && $booking.booking_status == "confirmed") {error="Local supplier booking missing"}
 db.edit supplier_bookings {field_name="id"
field_value=$booking.id
data={supplier_amount:$financials.supplier_amount,processing_fee:$financials.processing_fee,stripe_fee:$financials.stripe_fee,seasondeals_margin:$financials.seasondeals_margin,updated_at:now}} as $reconciled
 db.get payments {field_name="stripe_payment_intent_id"
field_value=$verified.stripe_payment_intent_id} as $payment
 conditional {if ($payment == null) {
 db.add payments {data={order_id:$order.id,stripe_payment_intent_id:$verified.stripe_payment_intent_id,stripe_charge_id:$financials.stripe_charge_id,amount:$intent.selling_price,currency:"EUR",status:"succeeded"}} as $created_payment
 }}
 db.get vouchers {field_name="order_id"
field_value=$order.id} as $existing_voucher
 var $voucher {value=$existing_voucher}
 conditional {if ($existing_voucher == null) {
 security.create_password {character_count=8
require_lowercase=false
require_uppercase=true
require_digit=true
require_symbol=false
symbol_whitelist=""} as $suffix
 var $code {value="SD-SBX-" ~ ($order.id|to_text) ~ "-" ~ $suffix}
 db.add vouchers {data={order_id:$order.id,deal_id:$order.deal_id,hotel_id:null,customer_id:$order.customer_id,customer_email:$intent.holder.email,code:$code,qr_payload:$code,redemption_status:"active",status:"active",created_at:now,checkin:$order.checkin,checkout:$order.checkout,guests:$intent.checkout_context.request.guest_count}} as $created_voucher
 var.update $voucher {value=$created_voucher}
 }}
 function.run "supplier/checkout/render_confirmation" {input={confirmation:{booking:$supplier.data,request:$intent.checkout_context.request,holder:$intent.holder,voucher:$voucher,selling_price:$intent.selling_price}}} as $confirmation_html
 api.lambda {
 code="""
const i=$var.locked,d=$var.supplier.data,v=$var.voucher;
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const old=i.checkout_context?.confirmation_mail;
const mail=old||{status:'pending',idempotency_key:'nuitee-sandbox-voucher-'+i.id,to:'delivered@resend.dev',subject:'SANDBOX — SeasonDeals boekingsbevestiging',html:$var.confirmation_html,template_version:'supplier-confirmation-v2',created_at:Date.now()};
return {mail,context:{...i.checkout_context,financial_reconciliation:$var.financials,voucher_id:v.id,confirmation_mail:mail}};
"""
 timeout=5
 } as $context
 db.edit supplier_checkout_intents {field_name="id"
field_value=$intent.id
data={checkout_context:$context.context,updated_at:now}} as $saved
 var.update $mail {value=$context.mail}
 }
 }
 conditional {if ($mail.status != "sent" && ($mail.authorized ?? false) == true) {
 precondition ($mail.to != null && $mail.to != "") {error="Approved recipient required"}
 api.lambda {
 code="""
return {valid:Number.isFinite($var.mail.created_at)&&Date.now()-$var.mail.created_at<82800000};
"""
 timeout=5
 } as $mail_window
 precondition ($mail_window.valid == true) {error="Mail retry outside idempotency window; reconcile before resend"}
 var $html {value=$mail.html}
 conditional {if (($mail.template_version ?? "") != "supplier-confirmation-v2") {
 function.run "emails/render_template" {input={content:$mail.html}} as $legacy_html
 var.update $html {value=$legacy_html}
 }}
 api.request {
 url="https://api.resend.com/emails"
 method="POST"
 params={from:"SeasonDeals <klantenservice@mail.seasondeals.nl>",to:$mail.to,subject:$mail.subject,html:$html}
 headers=["Authorization: Bearer " ~ $env.RESEND_API_KEY,"Content-Type: application/json","Idempotency-Key: " ~ $mail.idempotency_key]
 } as $sent
 precondition ($sent.response.status >= 200 && $sent.response.status < 300 && $sent.response.result.id != null) {error="Confirmation mail pending; retry with same idempotency key"}
 db.transaction {stack {
 db.get supplier_checkout_intents {field_name="id"
field_value=$intent.id
lock=true} as $latest
 api.lambda {code="""
return {...$var.latest.checkout_context,confirmation_mail:{...$var.latest.checkout_context.confirmation_mail,status:'sent',resend_id:$var.sent.response.result.id,sent_at:Date.now()}};
"""
 timeout=5
 } as $sent_context
 db.edit supplier_checkout_intents {field_name="id"
field_value=$intent.id
data={checkout_context:$sent_context,updated_at:now}} as $completed
 }}
 }}
 }
 response={status:"reconciled",environment:"sandbox",order_id:$order.id,external_booking_id:$order.external_booking_id,financials:$financials,voucher_id:$voucher.id,mail_status:($completed.checkout_context.confirmation_mail.status ?? $mail.status),mail_recipient:$mail.to,resend_id:($completed.checkout_context.confirmation_mail.resend_id ?? $mail.resend_id ?? null)}
}