// Separate production implementation; closed by config_status. No release in this change.
query "supplier/production/guest-checkout" verb=POST {
  api_group = "Public API"

  input {
    int deal_id
    text checkin filters=trim
    text checkout filters=trim
    int guest_count
    text request_key filters=trim
    json holder
    json guests
  }

  stack {
    util.set_header {
      value = "Cache-Control: no-store, private"
      duplicates = "replace"
    }
  
    util.set_header {
      value = "Referrer-Policy: no-referrer"
      duplicates = "replace"
    }
  
    function.run "supplier/production/config_status" as $release_gate
    precondition ($release_gate.can_pay && $release_gate.can_sell && $release_gate.can_book) {
      error_type = "accessdenied"
      error = "PRODUCTION_NOT_RELEASED"
    }
  
    var $key_hash {
      value = $input.request_key
        |hmac_sha256:"seasondeals-guest-reference-v1":false
    }
  
    api.lambda {
      code = """
        const i=$input;
        if(!/^[a-f0-9]{64}$/.test(i.request_key))throw new Error('A 256-bit guest request key is required');
        if(!Number.isSafeInteger(i.deal_id)||i.deal_id<=0||!Number.isInteger(i.guest_count)||i.guest_count<1||i.guest_count>6)throw new Error('Invalid stay');
        if(!i.holder||!i.holder.firstName||!i.holder.lastName||!/^.+@.+\..+$/.test(i.holder.email||''))throw new Error('Holder name and email are required');
        if(!Array.isArray(i.guests)||i.guests.length!==i.guest_count||i.guests.some(g=>!g.firstName||!g.lastName||g.occupancyNumber!==1||!/^.+@.+\..+$/.test(g.email||'')))throw new Error('Name and email are required for every guest in room 1');
        return {reference:'SD-GUEST-'+i.deal_id+'-'+$var.key_hash,request:{deal_id:i.deal_id,checkin:i.checkin,checkout:i.checkout,guest_count:i.guest_count,customer_id:0,holder:i.holder,guests:i.guests}};
        """
      timeout = 5
    } as $validated
  
    precondition ($validated.reference != null && $validated.request.customer_id == 0) {
      error_type = "inputerror"
      error = "Invalid checkout input"
    }
  
    db.query supplier_checkout_intents {
      where = $db.supplier_checkout_intents.client_reference == $validated.reference
      return = {type: "single"}
    } as $existing
  
    var $quote {
      value = null
    }
  
    conditional {
      if ($existing == null) {
        function.run "supplier/production/prepare" {
          input = {
            deal_id : $input.deal_id
            checkin : $input.checkin
            checkout: $input.checkout
            guests  : $input.guest_count
          }
        } as $prepared
      
        precondition ($prepared.ready && $prepared.environment == "production") {
          error_type = "inputerror"
          error = "Approved production quote required"
        }
      
        var.update $quote {
          value = $prepared
        }
      }
    }
  
    var $intent {
      value = null
    }
  
    db.transaction {
      stack {
        // Serialize admission for this deal; no customer lookup or account creation.
        db.get deals {
          field_name = "id"
          field_value = $input.deal_id
          lock = true
        } as $admission_deal
      
        precondition ($admission_deal != null) {
          error_type = "notfound"
          error = "Deal not found"
        }
      
        db.query supplier_checkout_intents {
          where = $db.supplier_checkout_intents.client_reference == $validated.reference
          return = {type: "single"}
        } as $prior
      
        conditional {
          if ($prior != null) {
            api.lambda {
              code = """
                const canonical=v=>JSON.stringify(v,(_k,x)=>x&&typeof x==='object'&&!Array.isArray(x)?Object.fromEntries(Object.keys(x).sort().map(k=>[k,x[k]])):x);
                const p=$var.prior;
                return {valid:p.environment==='production'&&p.provider_slug==='nuitee'&&canonical(p.checkout_context?.request)===canonical($var.validated.request)};
                """
              timeout = 5
            } as $same_request
          
            precondition ($same_request.valid) {
              error_type = "inputerror"
              error = "Request key already used with different checkout details"
            }
          
            var.update $intent {
              value = $prior
            }
          }
        
          else {
            db.get deals {
              field_name = "id"
              field_value = $input.deal_id
              lock = true
            } as $locked_deal
          
            db.get supplier_deals {
              field_name = "id"
              field_value = $quote.supplier_deal_id
              lock = true
            } as $locked_supplier
          
            api.lambda {
              code = """
                const q=$var.quote,d=$var.locked_deal,s=$var.locked_supplier;
                const canonical=v=>JSON.stringify(v,(_k,x)=>x&&typeof x==='object'&&!Array.isArray(x)?Object.fromEntries(Object.keys(x).sort().map(k=>[k,x[k]])):x);
                if(!q||!q.ready||q.environment!=='production'||Date.now()-q.checked_at>60000||q.approval_fingerprint!==canonical({deal:d,supplier:s}))throw new Error('Quote expired or approved deal changed');
                return {schema_version:1,flow:'nuitee-production-v1',request:$var.validated.request,quote:q,product_name:'SeasonDeals - '+d.title};
                """
              timeout = 5
            } as $context
          
            precondition ($context.flow == "nuitee-production-v1") {
              error_type = "inputerror"
              error = "Quote expired or approved deal changed"
            }
          
            db.add orders {
              data = {
                deal_id     : $input.deal_id
                customer_id : 0
                total_amount: $quote.selling_price
                status      : "pending_payment"
                currency    : "EUR"
                guests      : $input.guest_count
                updated_at  : now
              }
            } as $new_order
          
            db.add supplier_checkout_intents {
              data = {
                created_at                 : now
                updated_at                 : now
                order_id                   : $new_order.id
                provider_slug              : "nuitee"
                environment                : "production"
                prebook_id                 : $quote.prebook_id
                client_reference           : $validated.reference
                holder                     : $input.holder
                guests                     : $input.guests
                currency                   : "EUR"
                supplier_amount            : $quote.supplier_amount
                selling_price              : $quote.selling_price
                processing_fee             : $quote.processing_reserve
                stripe_fee_estimated       : $quote.stripe_reserve
                margin_estimate_pre_payment: $quote.margin_after_reserve
                payment_method_type        : "unknown"
                status                     : "creating_checkout"
                booking_attempts           : 0
                checkout_context           : $context
              }
            } as $new_intent
          
            var.update $intent {
              value = $new_intent
            }
          }
        }
      }
    }
  
    precondition ($intent.status == "creating_checkout" || $intent.status == "pending_payment") {
      error_type = "accessdenied"
      error = "This checkout is no longer available"
    }
  
    api.lambda {
      code = "return {valid:Number.isFinite($var.intent.created_at)&&Date.now()-$var.intent.created_at>=0&&Date.now()-$var.intent.created_at<82800000};"
      timeout = 5
    } as $guest_window
  
    precondition ($guest_window.valid) {
      error_type = "accessdenied"
      error = "Checkout link expired; contact support before retrying"
    }
  
    conditional {
      if ($intent.stripe_checkout_session_id == null || $intent.stripe_checkout_session_id == "") {
        precondition ($intent.status == "creating_checkout") {
          error_type = "inputerror"
          error = "Checkout state does not permit payment creation"
        }
      
        api.lambda {
          code = "return {valid:Number.isFinite($var.intent.created_at)&&Date.now()-$var.intent.created_at<82800000};"
          timeout = 5
        } as $retry_window
      
        precondition ($retry_window.valid) {
          error = "Checkout retry window expired; reconcile before recreating"
        }
      
        api.request {
          url = "https://api.stripe.com/v1/checkout/sessions"
          method = "POST"
          params = {
            success_url         : "https://www.seasondeals.nl/boeking-bevestiging#session_id={CHECKOUT_SESSION_ID}"
            cancel_url          : "https://www.seasondeals.nl/boeking-bevestiging#cancelled=1"
            mode                : "payment"
            adaptive_pricing    : {enabled:"false"}
            customer_email      : $intent.holder.email
            payment_method_types: ["card","ideal"]
            line_items          : [{price_data:{currency:"eur",product_data:{name:$intent.checkout_context.product_name},unit_amount:(($intent.selling_price * 100)|round:0|to_int)},quantity:1}]
            metadata            : {supplier_order_id:$intent.order_id,supplier_checkout_intent_id:$intent.id,supplier_fulfillment:"nuitee",supplier_flow:"nuitee_production_v1"}
          }
        
          headers = [
            "Authorization: Bearer " ~ ($env.STRIPE_SECRET_KEY_live|to_text)
            "Stripe-Version: 2023-10-16"
            "Content-Type: application/x-www-form-urlencoded"
            "Idempotency-Key: sd-production-checkout-" ~ ($intent.id|to_text)
          ]
        } as $stripe
      
        precondition ($stripe.response.status == 200 && $stripe.response.result.object == "checkout.session" && $stripe.response.result.livemode && $stripe.response.result.currency == "eur" && $stripe.response.result.amount_total == ((($intent.selling_price * 100))|round:0|to_int)) {
          error_type = "inputerror"
          error = "Stripe live session not confirmed; retry only with the same request key"
        }
      
        api.lambda {
          code = "return {...$var.intent.checkout_context,checkout_url:$var.stripe.response.result.url};"
          timeout = 5
        } as $stored_context
      
        db.transaction {
          stack {
            db.get supplier_checkout_intents {
              field_name = "id"
              field_value = $intent.id
              lock = true
            } as $locked_intent
          
            precondition ($locked_intent.stripe_checkout_session_id == null || $locked_intent.stripe_checkout_session_id == "" || $locked_intent.stripe_checkout_session_id == $stripe.response.result.id) {
              error = "Checkout session binding changed"
            }
          
            db.edit orders {
              field_name = "id"
              field_value = $intent.order_id
              data = {
                stripe_checkout_session_id: $stripe.response.result.id
                updated_at                : now
              }
            } as $session_order
          
            conditional {
              if ($locked_intent.status == "creating_checkout") {
                db.edit supplier_checkout_intents {
                  field_name = "id"
                  field_value = $intent.id
                  data = {
                    stripe_checkout_session_id: $stripe.response.result.id
                    checkout_context          : $stored_context
                    status                    : "pending_payment"
                    updated_at                : now
                  }
                } as $session_intent
              
                var.update $intent {
                  value = $session_intent
                }
              }
            
              else {
                var.update $intent {
                  value = $locked_intent
                }
              }
            }
          }
        }
      }
    }
  }

  response = {
    environment    : "production"
    status         : $intent.status
    checkout_url   : $intent.checkout_context.checkout_url
    selling_price  : $intent.selling_price
    currency       : "EUR"
    voucher_allowed: false
  }
}