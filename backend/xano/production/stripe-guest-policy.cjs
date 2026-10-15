'use strict';

// Prepared policy only. Not wired to Xano or Checkout; visible fields await owner approval.
// Call only with a server-retrieved Session AFTER existing payment verification.
const customFields = [
  { key: 'guestfirstname', label: { type: 'custom', custom: 'Voornaam hoofdgast' }, type: 'text', optional: false },
  { key: 'guestlastname', label: { type: 'custom', custom: 'Achternaam hoofdgast' }, type: 'text', optional: false }
];

function readGuest(session, verified, roomCount) {
  if (roomCount !== 1) throw new Error('Only one room is supported');
  if (verified?.verified !== true || verified.environment !== 'production' ||
      !/^cs_live_/.test(verified.stripe_checkout_session_id || '') ||
      session?.id !== verified.stripe_checkout_session_id ||
      session.object !== 'checkout.session' || session.livemode !== true ||
      session.status !== 'complete' || session.payment_status !== 'paid' ||
      session.currency !== 'eur' || verified.currency !== 'EUR' ||
      !Number.isSafeInteger(verified.amount_minor) || verified.amount_minor <= 0 ||
      session.amount_total !== verified.amount_minor ||
      session.payment_intent !== verified.stripe_payment_intent_id ||
      String(session.metadata?.supplier_order_id) !== String(verified.order_id) ||
      String(session.metadata?.supplier_checkout_intent_id) !== String(verified.supplier_checkout_intent_id) ||
      session.metadata?.supplier_fulfillment !== 'nuitee' ||
      session.metadata?.supplier_flow !== 'nuitee_production_v1') {
    throw new Error('Verified production payment binding required');
  }
  const field = key => {
    const found = Array.isArray(session.custom_fields) ? session.custom_fields.filter(f => f.key === key) : [];
    if (found.length !== 1 || found[0].type !== 'text') throw new Error('Guest name missing or ambiguous');
    const value = found[0].text?.value;
    if (typeof value !== 'string' || !value.trim() || value.trim().length > 100 || /[\u0000-\u001f\u007f]/u.test(value)) throw new Error('Invalid guest name');
    return value.trim();
  };
  const email = session.customer_details?.email;
  if (typeof email !== 'string' || email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) throw new Error('Booking contact email missing');
  const holder = { firstName: field('guestfirstname'), lastName: field('guestlastname'), email };
  // Occupancy number identifies the room, not the number of adults.
  // The payer's email is the booking contact; never infer guest identity from billing name.
  return { holder, guests: [{ ...holder, occupancyNumber: 1 }] };
}

module.exports = { customFields, readGuest };
