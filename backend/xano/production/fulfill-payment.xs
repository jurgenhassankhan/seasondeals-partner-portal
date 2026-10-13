// Separate production implementation; closed by config_status. No release in this change.
function "supplier/production/fulfill_payment" {
  input {
    int supplier_checkout_intent_id
  }

  stack {
    function.run "supplier/production/config_status" as $release_gate
    precondition ($release_gate.can_book && $release_gate.can_pay) {
      error_type = "accessdenied"
      error = "PRODUCTION_NOT_RELEASED"
    }
  
    function.run "supplier/production/claim_payment" {
      input = {
        supplier_checkout_intent_id: $input.supplier_checkout_intent_id
      }
    } as $claim
  
    db.get supplier_checkout_intents {
      field_name = "id"
      field_value = $input.supplier_checkout_intent_id
    } as $intent
  
    conditional {
      if ($claim.claimed != true) {
        db.query supplier_bookings {
          where = $db.supplier_bookings.order_id == $claim.order_id && $db.supplier_bookings.environment == "production" && $db.supplier_bookings.booking_status == "confirmed"
          return = {type: "single"}
        } as $existing_booking
      
        return {
          value = {
            claimed            : false
            idempotent_replay  : true
            status             : $intent.status
            order_id           : $claim.order_id
            supplier_booking_id: $existing_booking.id
            voucher_allowed    : ($intent.status == "booked" && $existing_booking != null)
          }
        }
      }
    }
  
    db.edit orders {
      field_name = "id"
      field_value = $claim.order_id
      data = {
        status        : "paid"
        payment_status: "paid"
        paid_at       : now
        updated_at    : now
      }
    } as $paid_order
  
    var $fresh {
      value = null
    }
  
    try_catch {
      try {
        function.run "supplier/production/prepare" {
          input = {
            deal_id : $intent.checkout_context.request.deal_id
            checkin : $intent.checkout_context.request.checkin
            checkout: $intent.checkout_context.request.checkout
            guests  : $intent.checkout_context.request.guest_count
          }
        } as $prepared
      
        var.update $fresh {
          value = $prepared
        }
      }
    
      catch {
        var.update $fresh {
          value = {ready: false}
        }
      }
    }
  
    api.lambda {
      code = """
        const q=$var.fresh,i=$var.intent,old=i.checkout_context?.quote;
        const canonical=v=>JSON.stringify(v,(_k,x)=>x&&typeof x==='object'&&!Array.isArray(x)?Object.fromEntries(Object.keys(x).sort().map(k=>[k,x[k]])):x);
        return {valid:!!q?.ready&&q.environment==='production'&&q.currency==='EUR'&&q.selling_price===i.selling_price&&q.approval_fingerprint===old?.approval_fingerprint&&canonical(q.local_fees)===canonical(old?.local_fees)&&canonical(q.cancellation_policies)===canonical(old?.cancellation_policies)};
        """
      timeout = 5
    } as $safe_quote
  
    conditional {
      if ($safe_quote.valid != true) {
        db.edit supplier_checkout_intents {
          field_name = "id"
          field_value = $intent.id
          data = {
            status      : "manual_attention"
            last_error  : "Paid, but approved offer could not be safely revalidated. No booking submitted."
            processed_at: now
            updated_at  : now
          }
        } as $blocked
      
        db.edit orders {
          field_name = "id"
          field_value = $intent.order_id
          data = {
            provider_sync_status: "error"
            provider_sync_error : "Offer changed after payment; review/refund required. No booking submitted."
            updated_at          : now
          }
        } as $blocked_order
      
        return {
          value = {
            success          : false
            paid             : true
            booking_submitted: false
            status           : "manual_attention"
            voucher_allowed  : false
            order_id         : $intent.order_id
          }
        }
      }
    }
  
    api.lambda {
      code = "return {...$var.intent.checkout_context,fulfillment_quote:$var.fresh,booking_submission_at:Date.now()};"
      timeout = 5
    } as $attempt_context
  
    db.edit supplier_checkout_intents {
      field_name = "id"
      field_value = $intent.id
      data = {
        prebook_id      : $fresh.prebook_id
        checkout_context: $attempt_context
        updated_at      : now
      }
    } as $attempt
  
    api.lambda {
      code = """
        const guests=$var.intent.guests;
        const valid=Array.isArray(guests)&&guests.length>0&&guests.every(g=>g.occupancyNumber===1&&g.firstName&&g.lastName&&/^.+@.+\..+$/.test(g.email||''));
        return {valid,guests:valid?[guests[0]]:[]};
        """
      timeout = 5
    } as $room_contacts
  
    precondition ($room_contacts.valid) {
      error = "Valid primary room contact required"
    }
  
    var $booking_response {
      value = {
        success    : false
        environment: "production"
        data       : null
      }
    }
  
    try_catch {
      try {
        function.run "supplier/production/config_status" as $submission_gate
        precondition ($submission_gate.can_book) {
          error = "PRODUCTION_NOT_RELEASED"
        }
      
        api.request {
          url = "https://book.liteapi.travel/v3.0/rates/book?timeout=30"
          method = "POST"
          params = {
            prebookId      : $fresh.prebook_id
            clientReference: $intent.client_reference
            holder         : $intent.holder
            guests         : $room_contacts.guests
            payment        : {method:"ACC_CREDIT_CARD"}
          }
        
          headers = [
            "X-API-Key: " ~ $env.NUITEE_PRODUCTION_API_KEY
            "Content-Type: application/json"
            "Accept: application/json"
          ]
        
          timeout = 30
        } as $booking_http
      
        var.update $booking_response {
          value = {
            success    : ($booking_http.response.status == 200)
            environment: "production"
            data       : $booking_http.response.result.data
          }
        }
      }
    
      catch {
        var.update $booking_response {
          value = {
            success    : false
            environment: "production"
            data       : null
          }
        }
      }
    }
  
    api.lambda {
      code = """
        const b=$var.booking_response,d=b?.data;
        const confirmed=b?.success===true&&b.environment==='production'&&d?.sandbox===0&&d.clientReference===$var.intent.client_reference&&d.currency==='EUR'&&typeof d?.bookingId==='string'&&d.bookingId.length>0&&String(d.status).toUpperCase()==='CONFIRMED';
        return {confirmed,booking_id:confirmed?d.bookingId:null,context:{...$var.attempt_context,booking_response:b,booking_response_at:Date.now()}};
        """
      timeout = 5
    } as $outcome
  
    db.edit supplier_checkout_intents {
      field_name = "id"
      field_value = $intent.id
      data = {checkout_context: $outcome.context, updated_at: now}
    } as $recorded_response
  
    conditional {
      if ($outcome.confirmed != true) {
        db.edit supplier_checkout_intents {
          field_name = "id"
          field_value = $intent.id
          data = {
            status      : "manual_attention"
            last_error  : "Supplier confirmation is missing or uncertain. Retrieve by client reference before any retry or refund."
            processed_at: now
            updated_at  : now
          }
        } as $uncertain
      
        db.edit orders {
          field_name = "id"
          field_value = $intent.order_id
          data = {
            provider_sync_status: "error"
            provider_sync_error : "Supplier booking not confirmed; reconciliation required."
            updated_at          : now
          }
        } as $uncertain_order
      
        return {
          value = {
            success        : false
            paid           : true
            status         : "manual_attention"
            voucher_allowed: false
            order_id       : $intent.order_id
          }
        }
      }
    }
  
    db.transaction {
      stack {
        db.get supplier_checkout_intents {
          field_name = "id"
          field_value = $intent.id
          lock = true
        } as $locked
      
        precondition ($locked.status == "processing" && $locked.stripe_payment_intent_id == $claim.stripe_payment_intent_id) {
          error = "Fulfillment state changed; reconcile confirmed supplier booking"
        }
      
        db.query supplier_bookings {
          where = $db.supplier_bookings.order_id == $intent.order_id
          return = {type: "single"}
        } as $prior_booking
      
        precondition ($prior_booking == null) {
          error = "Existing supplier booking requires reconciliation"
        }
      
        db.add supplier_bookings {
          data = {
            provider_slug      : "nuitee"
            environment        : "production"
            external_booking_id: $outcome.booking_id
            order_id           : $intent.order_id
            prebook_id         : $fresh.prebook_id
            client_reference   : $intent.client_reference
            booking_status     : "confirmed"
            payment_status     : "paid"
            currency           : "EUR"
            supplier_amount    : $fresh.supplier_amount
            selling_price      : $intent.selling_price
            processing_fee     : $fresh.processing_reserve
            stripe_fee         : $intent.stripe_fee_estimated
            seasondeals_margin : $fresh.margin_after_reserve
            guest_count        : $intent.checkout_context.request.guest_count
            checkin            : $intent.checkout_context.request.checkin
            checkout           : $intent.checkout_context.request.checkout
            sanitized_metadata : {source: "nuitee_production", schema_version: 1}
            created_at         : now
            updated_at         : now
          }
        } as $supplier_booking
      
        db.edit orders {
          field_name = "id"
          field_value = $intent.order_id
          data = {
            status               : "paid"
            payment_status       : "paid"
            external_booking_id  : $outcome.booking_id
            provider_sync_status : "confirmed"
            provider_sync_error  : null
            pushed_to_provider_at: now
            checkin              : $intent.checkout_context.request.checkin
            checkout             : $intent.checkout_context.request.checkout
            updated_at           : now
          }
        } as $confirmed_order
      
        db.edit supplier_checkout_intents {
          field_name = "id"
          field_value = $intent.id
          data = {
            status      : "booked"
            last_error  : null
            processed_at: now
            updated_at  : now
          }
        } as $booked
      }
    }
  }

  response = {
    success                        : true
    paid                           : true
    status                         : "booked"
    environment                    : "production"
    order_id                       : $intent.order_id
    supplier_booking_id            : $supplier_booking.id
    external_booking_id            : $outcome.booking_id
    voucher_allowed                : true
    idempotent_replay              : false
    financial_reconciliation_status: "pending_actual_fees"
  }
}