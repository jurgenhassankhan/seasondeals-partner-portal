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
  if (lower(i.status) === 'manual_attention') reasons.push('MANUAL_REVIEW');
  if (!confirmed && (lower(o.provider_sync_status) === 'error' || candidates.some(x => /failed|error/.test(lower(x.booking_status))))) reasons.push('BOOKING_ERROR');
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
if (typeof module !== 'undefined') module.exports = classifyCheckoutIncident;
