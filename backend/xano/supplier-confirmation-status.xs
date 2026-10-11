// Read-only sandbox confirmation. The Stripe test session ID is a temporary bearer capability.
// Never accept an order ID or a client-supplied payment/booking status as authorization.
query "supplier/confirmation-status" verb=POST {
  api_group = "Public API"
  input { text session_id filters=trim }
  stack {
    util.set_header {value="Cache-Control: no-store, private"}
    util.set_header {value="Referrer-Policy: no-referrer"}
    api.lambda {
      code = """
return {valid:/^cs_test_[A-Za-z0-9]{32,240}$/.test($input.session_id||'')};
"""
      timeout = 5
    } as $format
    precondition ($format.valid == true) {error_type="notfound"
error="Confirmation unavailable"}
    db.query supplier_checkout_intents {
      where = $db.supplier_checkout_intents.stripe_checkout_session_id == $input.session_id && $db.supplier_checkout_intents.environment == "sandbox" && $db.supplier_checkout_intents.provider_slug == "nuitee"
      return = {type:"single"}
    } as $intent
    precondition ($intent != null) {error_type="notfound"
error="Confirmation unavailable"}
    api.lambda {
      code = """
const age=Date.now()-Number($var.intent.created_at);
return {valid:Number.isFinite(age)&&age>=0&&age<86400000};
"""
      timeout = 5
    } as $access
    precondition ($access.valid == true) {error_type="notfound"
error="Confirmation unavailable"}
    db.get orders {field_name="id"
field_value=$intent.order_id} as $order
    precondition ($order != null && $order.stripe_checkout_session_id == $input.session_id && $order.customer_id == $intent.checkout_context.request.customer_id) {error_type="notfound"
error="Confirmation unavailable"}
    db.query supplier_bookings {
      where = $db.supplier_bookings.order_id == $intent.order_id && $db.supplier_bookings.environment == "sandbox" && $db.supplier_bookings.provider_slug == "nuitee" && $db.supplier_bookings.external_booking_id == $order.external_booking_id
      return = {type:"single"}
    } as $booking
    db.get vouchers {field_name="order_id"
field_value=$intent.order_id} as $voucher
    api.lambda {
      code = """
const i=$var.intent,o=$var.order,b=$var.booking,v=$var.voucher,c=i.checkout_context||{},d=c.booking_response?.data||{},r=c.request||{};
const paid=o.payment_status==='paid'&&!!i.stripe_payment_intent_id;
const cancelled=['cancelled','cancelled_with_charges'].includes(String(b?.booking_status).toLowerCase())||['cancelled','refunded'].includes(String(o.status).toLowerCase());
const confirmed=paid&&i.status==='booked'&&o.provider_sync_status==='confirmed'&&b?.booking_status==='confirmed'&&b.payment_status==='paid'&&b.external_booking_id===o.external_booking_id&&d.bookingId===o.external_booking_id&&String(d.status).toUpperCase()==='CONFIRMED'&&Number(d.sandbox)===1&&d.clientReference===i.client_reference;
const attention=i.status==='manual_attention'||o.provider_sync_status==='error'||['failed','booking_failed_after_payment'].includes(String(b?.booking_status));
let state=cancelled?'cancelled':confirmed?'confirmed':attention?'needs_attention':paid?'processing':'pending_payment';
if(!['creating_checkout','pending_payment','processing','booked','manual_attention'].includes(i.status)&&!cancelled)state='needs_attention';
const validVoucher=confirmed&&v?.status==='active'&&v.redemption_status==='active'&&v.id===c.voucher_id&&v.code;
const result={schema_version:1,environment:'sandbox',state,payment_status:paid?'paid':'unconfirmed',mail_status:c.confirmation_mail?.status==='sent'?'sent':'pending',retry_after_seconds:['pending_payment','processing'].includes(state)?5:null,booking:null,voucher:null};
if(confirmed&&!cancelled){
 result.booking={hotel_name:d.hotel?.name||d.hotelName||null,checkin:d.checkin||r.checkin||null,checkout:d.checkout||r.checkout||null,guest_count:r.guest_count,booking_reference:o.external_booking_id,hotel_confirmation:d.hotelConfirmationCode||null,amount:i.selling_price,currency:i.currency,refundable_tag:d.cancellationPolicies?.refundableTag||d.tag||c.fulfillment_quote?.cancellation_policies?.refundableTag||null};
 result.voucher=validVoucher?{code:v.code}:null;
}
return result;
"""
      timeout = 5
    } as $result
  }
  response = $result
}
