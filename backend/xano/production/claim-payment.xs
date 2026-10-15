// Separate production implementation; closed by config_status. No release in this change.
function "supplier/production/claim_payment" {
  input {
    int supplier_checkout_intent_id
  }

  stack {
    function.run "supplier/production/config_status" as $release_gate
    precondition ($release_gate.can_book && $release_gate.can_pay) {
      error_type = "accessdenied"
      error = "PRODUCTION_NOT_RELEASED"
    }
  
    function.run "supplier/production/verify_payment" {
      input = {
        supplier_checkout_intent_id: $input.supplier_checkout_intent_id
      }
    } as $payment
  
    precondition ($payment.verified && $payment.environment == "production") {
      error_type = "inputerror"
      error = "Verified live payment required"
    }
  
    var $claimed {
      value = false
    }
  
    var $claim_status {
      value = "blocked"
    }
  
    db.transaction {
      stack {
        db.get supplier_checkout_intents {
          field_name = "id"
          field_value = $input.supplier_checkout_intent_id
          lock = true
        } as $locked_intent
      
        precondition ($locked_intent != null && $locked_intent.environment == "production" && $locked_intent.provider_slug == "nuitee" && $locked_intent.order_id == $payment.order_id && $locked_intent.stripe_checkout_session_id == $payment.stripe_checkout_session_id && $locked_intent.currency == $payment.currency && ((($locked_intent.selling_price * 100))|round:0|to_int) == $payment.amount_minor) {
          error_type = "inputerror"
          error = "Checkout changed during payment verification"
        }
      
        precondition ($locked_intent.stripe_payment_intent_id == null || $locked_intent.stripe_payment_intent_id == "" || $locked_intent.stripe_payment_intent_id == $payment.stripe_payment_intent_id) {
          error_type = "inputerror"
          error = "Payment binding changed"
        }
      
        var.update $claim_status {
          value = $locked_intent.status
        }
      
        conditional {
          if ($locked_intent.status == "pending_payment" && ($locked_intent.booking_attempts ?? 0) == 0) {
            precondition ($locked_intent.prebook_id != null && $locked_intent.prebook_id != "" && $locked_intent.client_reference != null && $locked_intent.client_reference != "") {
              error_type = "inputerror"
              error = "Prebook and stable booking reference required"
            }
          
            api.lambda {
              code = """
                const i=$var.locked_intent,g=$var.payment.guest_details;
                const direct=i.checkout_context?.guest_capture==='stripe-custom-fields-v1';
                if(direct) return {valid:g?.required===true&&g.valid===true,holder:g?.holder||{},guests:g?.guests||[]};
                return {valid:true,holder:i.holder,guests:i.guests};
                """
              timeout = 5
            } as $bound_guest
          
            conditional {
              if ($bound_guest.valid != true) {
                db.edit supplier_checkout_intents {
                  field_name = "id"
                  field_value = $locked_intent.id
                  data = {
                    status                  : "manual_attention"
                    stripe_payment_intent_id: $payment.stripe_payment_intent_id
                    last_error              : "Paid; Stripe guest details invalid. No booking submitted."
                    updated_at              : now
                  }
                } as $invalid_guest
              
                db.edit orders {
                  field_name = "id"
                  field_value = $payment.order_id
                  data = {
                    status              : "paid"
                    payment_status      : "paid"
                    paid_at             : now
                    provider_sync_status: "error"
                    provider_sync_error : "Guest details require review. No booking submitted."
                    updated_at          : now
                  }
                } as $invalid_guest_order
              
                var.update $claim_status {
                  value = "manual_attention"
                }
              }
            
              else {
                db.edit supplier_checkout_intents {
                  field_name = "id"
                  field_value = $locked_intent.id
                  data = {
                    holder                  : $bound_guest.holder
                    guests                  : $bound_guest.guests
                    status                  : "processing"
                    stripe_payment_intent_id: $payment.stripe_payment_intent_id
                    booking_attempts        : 1
                    last_error              : null
                    updated_at              : now
                  }
                } as $processing_intent
              
                var.update $claimed {
                  value = true
                }
              
                var.update $claim_status {
                  value = "processing"
                }
              }
            }
          }
        }
      }
    }
  }

  response = {
    claimed                    : $claimed
    status                     : $claim_status
    environment                : "production"
    order_id                   : $payment.order_id
    supplier_checkout_intent_id: $input.supplier_checkout_intent_id
    stripe_payment_intent_id   : $payment.stripe_payment_intent_id
    voucher_allowed            : false
  }
}