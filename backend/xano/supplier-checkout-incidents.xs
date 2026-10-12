// Private read-only Nuitée checkout incident scan; 50 intents per cursor page.
query "supplier-checkout-incidents" verb=GET {
  api_group = "Admin"
  auth = "admin_users"
  input {
    int after_id?=0 filters=min:0
    text environment?="sandbox" filters=trim
  }
  stack {
    function.run "admin/guard" {input={permission:null}} as $admin
    precondition ($admin.is_active && ($admin.role == "superadmin" || $admin.role == "platform_admin" || $admin.role == "admin")) {error_type="accessdenied"
error="Admin access required"}
    precondition ($input.environment == "sandbox" || $input.environment == "production") {error_type="inputerror"
error="Environment must be sandbox or production"}
    util.set_header {value="Cache-Control: no-store, private"}
    db.query supplier_checkout_intents {
      where = $db.supplier_checkout_intents.provider_slug == "nuitee" && $db.supplier_checkout_intents.environment == $input.environment && $db.supplier_checkout_intents.id > $input.after_id
      sort = {id:"asc"}
      return = {type:"list",paging:{page:1,per_page:51,metadata:false}}
    } as $records
    api.lambda {
      code = """
const rows=Array.isArray($var.records)?$var.records:($var.records?.items||[]);
return {rows:rows.slice(0,50),has_more:rows.length>50,next_cursor:rows.length?rows[Math.min(49,rows.length-1)].id:null};
"""
      timeout = 5
    } as $batch
    var $items {value=[]}
    foreach ($batch.rows) {
      each as $intent {
        db.query orders {where=$db.orders.id == $intent.order_id
return={type:"single"}} as $related_order
        db.query supplier_bookings {where=$db.supplier_bookings.order_id == $intent.order_id && $db.supplier_bookings.provider_slug == "nuitee" && $db.supplier_bookings.environment == $input.environment
sort={id:"desc"}
return={type:"list"}} as $bookings
        db.query vouchers {where=$db.vouchers.order_id == $intent.order_id
return={type:"list"}} as $vouchers
        api.lambda {
          code = """
// Pure policy: reads stored evidence only. Never books, refunds or sends mail.
// Pure policy: reads stored evidence only. Never books, refunds or sends mail.
function classifyCheckoutIncident(intent, order, bookings, vouchers, now) {
  const i = intent || {}, o = order || {}, c = i.checkout_context || {};
  const lower = value => String(value || '').toLowerCase();
  const candidates = (bookings || []).filter(b => b.provider_slug === i.provider_slug && b.environment === i.environment);
  const b = candidates.find(b => b.external_booking_id && b.external_booking_id === o.external_booking_id) || candidates[0];
  const vs = vouchers || [];
  const activeVoucher = vs.some(v => lower(v.status) === 'active' && lower(v.redemption_status) === 'active');
  const paid = lower(o.payment_status) === 'paid';
  const refunded = lower(o.payment_status) === 'refunded' || lower(o.status) === 'refunded';
  const cancelled = refunded || lower(o.status) === 'cancelled' || lower(b?.booking_status).includes('cancelled');
  const at = Number(i.updated_at || i.created_at);
  const overdue = !Number.isFinite(at) || at <= 0 || now - at >= 300000;
  const confirmed = paid && lower(i.status) === 'booked' && lower(o.provider_sync_status) === 'confirmed' && lower(b?.booking_status) === 'confirmed' && !!o.external_booking_id && b.external_booking_id === o.external_booking_id;
  const reasons = [];
  if (!order) reasons.push('ORDER_MISSING');
  const recovery=c.recovery||{};
  if (recovery.operation) reasons.push('RECOVERY_PENDING');
  if (Number(recovery.last?.pending_refund_minor)>0) reasons.push('REFUND_PENDING');
  if (lower(i.status) === 'manual_attention') reasons.push('MANUAL_REVIEW');
  if (!confirmed && !cancelled && (lower(o.provider_sync_status) === 'error' || candidates.some(x => /failed|error/.test(lower(x.booking_status))))) reasons.push('BOOKING_ERROR');
  if (cancelled) {
    if (activeVoucher) reasons.push('CANCELLED_VOUCHER_ACTIVE');
    if (refunded && lower(b?.booking_status) === 'confirmed') reasons.push('REFUNDED_BOOKING_CONFIRMED');
  } else {
    if (paid && !confirmed && overdue) reasons.push(b ? 'PAID_UNCONFIRMED' : 'PAID_WITHOUT_BOOKING');
    if (lower(i.status) === 'booked' && (!b || !o.external_booking_id || b.external_booking_id !== o.external_booking_id)) reasons.push('BOOKING_REFERENCE_MISMATCH');
    if (confirmed && overdue && (!activeVoucher || !vs.some(v => v.id === c.voucher_id && lower(v.status) === 'active'))) reasons.push('VOUCHER_MISSING');
    if (confirmed && overdue && c.confirmation_mail?.status !== 'sent') reasons.push('MAIL_NOT_SENT');
    if (lower(i.status) === 'processing' && overdue && !paid) reasons.push('PAYMENT_REVIEW');
  }
  if (!reasons.length) return null;
  return {
    intent_id: i.id, order_id: i.order_id, provider_slug: i.provider_slug,
    environment: i.environment, updated_at: i.updated_at || i.created_at,
    payment_status: o.payment_status || 'unknown', intent_status: i.status,
    booking_status: b?.booking_status || 'missing', reasons,
    client_reference: i.client_reference || null,
    booking_reference: b?.external_booking_id || null,
    hotel_name: c.booking_response?.data?.hotel?.name || c.product_name || null,
    checkin: c.request?.checkin || null, checkout: c.request?.checkout || null,
    amount: i.selling_price, currency: i.currency || 'EUR',
    severity: paid || refunded || activeVoucher ? 'high' : 'review',
    next_action: 'Controleer eerst de bestaande betaling en leveranciersstatus op referentie. Niet opnieuw boeken, afschrijven of terugbetalen zonder vastgestelde uitkomst.'
  };
}

return classifyCheckoutIncident($var.intent,$var.related_order,$var.bookings,$var.vouchers,Date.now());
"""
          timeout = 5
        } as $incident
        conditional {if ($incident != null) {var.update $items {value=$items|push:$incident}}}
      }
    }
  }
  response = {items:$items,scanned_count:($batch.rows|count),has_more:$batch.has_more,next_cursor:$batch.next_cursor,environment:$input.environment}
}
