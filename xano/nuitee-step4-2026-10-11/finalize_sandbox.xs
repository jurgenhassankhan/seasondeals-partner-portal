// Sandbox only: actual fees and one voucher. Mail is a stored preview; no external email request.
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
 api.lambda {
 code="""
const i=$var.locked,d=$var.supplier.data,v=$var.voucher;
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const old=i.checkout_context?.confirmation_mail;
const mail=old||{status:'pending',idempotency_key:'nuitee-sandbox-voucher-'+i.id,to:'delivered@resend.dev',subject:'SANDBOX — SeasonDeals boekingsbevestiging',html:'<h2>SANDBOX — geen geldig verblijf</h2><p>De testboeking is bevestigd.</p><p>Hotel: '+esc(d.hotel?.name||d.hotelName)+'<br>Boekingsnummer: '+esc(d.bookingId)+'<br>Aankomst: '+esc(d.checkin)+'<br>Vertrek: '+esc(d.checkout)+'<br>Gasten: '+esc(i.checkout_context.request.guest_count)+'<br>Voucher: '+esc(v.code)+'</p><p>Betaald: EUR '+esc(i.selling_price)+' — annuleringsvoorwaarden: '+esc(d.cancellationPolicies?.refundableTag||d.tag)+'</p>',created_at:Date.now()};
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
 }
 response={status:"reconciled",environment:"sandbox",order_id:$order.id,external_booking_id:$order.external_booking_id,financials:$financials,voucher_id:$voucher.id,mail_status:"draft_not_sent",mail_recipient:"delivered@resend.dev"}
}