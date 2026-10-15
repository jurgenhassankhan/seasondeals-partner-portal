// Separate production implementation; closed by config_status. No release in this change.
function "supplier/production/verify_payment" {
  input {
    int supplier_checkout_intent_id
  }

  stack {
    function.run "supplier/production/config_status" as $release_gate
    precondition ($release_gate.can_read) {
      error_type = "accessdenied"
      error = "PRODUCTION_NOT_RELEASED"
    }
  
    precondition ($input.supplier_checkout_intent_id > 0) {
      error_type = "inputerror"
      error = "A supplier checkout intent is required"
    }
  
    db.get supplier_checkout_intents {
      field_name = "id"
      field_value = $input.supplier_checkout_intent_id
    } as $intent
  
    precondition ($intent != null) {
      error_type = "notfound"
      error = "Supplier checkout intent not found"
    }
  
    precondition ($intent.provider_slug == "nuitee" && $intent.environment == "production" && $intent.currency == "EUR" && $intent.selling_price > 0) {
      error_type = "inputerror"
      error = "Only EUR Nuitée production checkout intents are allowed"
    }
  
    db.get orders {
      field_name = "id"
      field_value = $intent.order_id
    } as $order
  
    precondition ($order != null) {
      error_type = "notfound"
      error = "Order not found"
    }
  
    precondition ($intent.stripe_checkout_session_id != null && $intent.stripe_checkout_session_id != "" && $order.stripe_checkout_session_id == $intent.stripe_checkout_session_id && $order.currency == "EUR" && $order.total_amount == $intent.selling_price && $order.customer_id == $intent.checkout_context.request.customer_id && $order.deal_id == $intent.checkout_context.request.deal_id && $intent.checkout_context.flow == "nuitee-production-v1") {
      error_type = "inputerror"
      error = "Order and supplier checkout do not match"
    }
  
    var $expected_amount {
      value = (($intent.selling_price * 100)|round:0|to_int)
    }
  
    api.request {
      url = "https://api.stripe.com/v1/checkout/sessions/" ~ ($intent.stripe_checkout_session_id|url_encode)
      method = "GET"
      headers = [
        "Authorization: Bearer " ~ ($env.STRIPE_SECRET_KEY_live|to_text)
        "Stripe-Version: 2023-10-16"
      ]
    
      timeout = 15
    } as $session_response
  
    precondition ($session_response.response.status == 200) {
      error_type = "inputerror"
      error = "Unable to verify Stripe checkout session"
    }
  
    var $session {
      value = $session_response.response.result
    }
  
    precondition ($session.object == "checkout.session" && $session.id == $intent.stripe_checkout_session_id && $session.livemode && $session.mode == "payment" && $session.status == "complete" && $session.payment_status == "paid" && $session.currency == "eur" && $session.amount_total == $expected_amount) {
      error_type = "inputerror"
      error = "Stripe has not confirmed an exact live payment"
    }
  
    precondition (($session.metadata.supplier_order_id|to_text) == ($order.id|to_text) && ($session.metadata.supplier_checkout_intent_id|to_text) == ($intent.id|to_text) && $session.metadata.supplier_fulfillment == "nuitee" && $session.metadata.supplier_flow == "nuitee_production_v1" && $session.payment_intent != null && $session.payment_intent != "") {
      error_type = "inputerror"
      error = "Stripe checkout metadata does not match this supplier order"
    }
  
    precondition ($intent.stripe_payment_intent_id == null || $intent.stripe_payment_intent_id == "" || $intent.stripe_payment_intent_id == $session.payment_intent) {
      error_type = "inputerror"
      error = "Payment intent has changed"
    }
  
    api.request {
      url = "https://api.stripe.com/v1/payment_intents/" ~ ($session.payment_intent|url_encode) ~ "?expand[]=latest_charge.balance_transaction"
      method = "GET"
      headers = [
        "Authorization: Bearer " ~ ($env.STRIPE_SECRET_KEY_live|to_text)
        "Stripe-Version: 2023-10-16"
      ]
    
      timeout = 15
    } as $payment_response
  
    precondition ($payment_response.response.status == 200) {
      error_type = "inputerror"
      error = "Unable to verify Stripe payment intent"
    }
  
    var $payment {
      value = $payment_response.response.result
    }
  
    precondition ($payment.object == "payment_intent" && $payment.id == $session.payment_intent && $payment.livemode && $payment.status == "succeeded" && $payment.currency == "eur" && $payment.amount == $expected_amount && $payment.amount_received == $expected_amount) {
      error_type = "inputerror"
      error = "Payment is incomplete or does not match the order amount"
    }
  
    precondition ($payment.latest_charge.object == "charge" && $payment.latest_charge.paid && $payment.latest_charge.livemode && $payment.latest_charge.payment_intent == $payment.id && $payment.latest_charge.amount == $expected_amount && $payment.latest_charge.currency == "eur" && $payment.latest_charge.refunded == false && $payment.latest_charge.amount_refunded == 0 && $payment.latest_charge.disputed == false) {
      error_type = "inputerror"
      error = "Payment charge is missing, refunded or disputed"
    }
  
    api.lambda {
      code = """
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
        
        const i=$var.intent;
        if(i.checkout_context?.guest_capture!=='stripe-custom-fields-v1')return {required:false,valid:true};
        try {
         const guest=readGuest($var.session,{verified:true,environment:'production',stripe_checkout_session_id:$var.session.id,stripe_payment_intent_id:$var.payment.id,order_id:$var.order.id,supplier_checkout_intent_id:i.id,amount_minor:$var.expected_amount,currency:'EUR'},i.checkout_context.room_count);
         return {required:true,valid:true,...guest};
        } catch (_) { return {required:true,valid:false,error:'STRIPE_GUEST_DETAILS_INVALID'}; }
        """
      timeout = 5
    } as $guest_details
  }

  response = {
    guest_details              : $guest_details
    verified                   : true
    environment                : "production"
    order_id                   : $order.id
    supplier_checkout_intent_id: $intent.id
    stripe_checkout_session_id : $session.id
    stripe_payment_intent_id   : $payment.id
    amount_minor               : $expected_amount
    currency                   : "EUR"
    voucher_allowed            : false
  }
}