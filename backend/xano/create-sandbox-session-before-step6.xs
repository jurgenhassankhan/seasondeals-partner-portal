// Internal sandbox only. Creates an immutable checkout snapshot and an idempotent Stripe test session.
function "supplier/checkout/create_sandbox_session" {
  input {
    int deal_id
    text checkin filters=trim
    text checkout filters=trim
    int guest_count
    int customer_id
    text request_key filters=trim
    json holder
    json guests
  }

  stack {
    api.lambda {
      code = """
        const i=$input;
        if(!/^[a-zA-Z0-9_-]{12,64}$/.test(i.request_key))throw new Error('Use a stable 12-64 character request key');
        if(!i.holder||!i.holder.firstName||!i.holder.lastName||!/^.+@.+\..+$/.test(i.holder.email||''))throw new Error('Holder name and email are required');
        if(!Array.isArray(i.guests)||i.guests.length!==i.guest_count||i.guests.some(g=>!g.firstName||!g.lastName||g.occupancyNumber!==1||!/^.+@.+\..+$/.test(g.email||'')))throw new Error('Name and email are required for every guest in room 1');
        return {reference:'SD-SBX-'+i.customer_id+'-'+i.request_key,request:{deal_id:i.deal_id,checkin:i.checkin,checkout:i.checkout,guest_count:i.guest_count,customer_id:i.customer_id,holder:i.holder,guests:i.guests}};
        """
      timeout = 5
    } as $validated
  
    precondition ($validated.reference != null && $validated.request.customer_id == $input.customer_id) {
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
        function.run "supplier/checkout/prepare" {
          input = {
            deal_id : $input.deal_id
            checkin : $input.checkin
            checkout: $input.checkout
            guests  : $input.guest_count
          }
        } as $prepared
      
        precondition ($prepared.ready && $prepared.environment == "sandbox") {
          error_type = "inputerror"
          error = "Approved sandbox quote required"
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
        db.get customers {
          field_name = "id"
          field_value = $input.customer_id
          lock = true
        } as $customer
      
        precondition ($customer != null && $customer.email == $input.holder.email) {
          error_type = "inputerror"
          error = "Existing test customer must match holder email"
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
                return {valid:p.environment==='sandbox'&&p.provider_slug==='nuitee'&&canonical(p.checkout_context?.request)===canonical($var.validated.request)};
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
                if(!q||!q.ready||q.environment!=='sandbox'||Date.now()-q.checked_at>60000||q.approval_fingerprint!==canonical({deal:d,supplier:s}))throw new Error('Quote expired or approved deal changed');
                return {schema_version:1,flow:'nuitee-step4-sandbox',request:$var.validated.request,quote:q,product_name:'SeasonDeals sandbox - '+d.title};
                """
              timeout = 5
            } as $context
          
            precondition ($context.flow == "nuitee-step4-sandbox") {
              error_type = "inputerror"
              error = "Quote expired or approved deal changed"
            }
          
            db.add orders {
              data = {
                deal_id     : $input.deal_id
                customer_id : $input.customer_id
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
                environment                : "sandbox"
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
  
    conditional {
      if ($intent.stripe_checkout_session_id == null || $intent.stripe_checkout_session_id == "") {
        precondition ($intent.status == "creating_checkout") {
          error_type = "inputerror"
          error = "Checkout state does not permit payment creation"
        }
      
        api.request {
          url = "https://api.stripe.com/v1/checkout/sessions"
          method = "POST"
          params = {
            success_url         : "https://seasondeals.nl/"
            cancel_url          : "https://seasondeals.nl/"
            mode                : "payment"
            adaptive_pricing    : {enabled:"false"}
            customer_email      : $intent.holder.email
            payment_method_types: ["card","ideal"]
            line_items          : [{price_data:{currency:"eur",product_data:{name:$intent.checkout_context.product_name},unit_amount:(($intent.selling_price * 100)|round:0|to_int)},quantity:1}]
            metadata            : {supplier_order_id:$intent.order_id,supplier_checkout_intent_id:$intent.id,supplier_fulfillment:"nuitee",supplier_flow:"step4_sandbox_v1"}
          }
        
          headers = [
            "Authorization: Bearer " ~ ($env.STRIPE_SECRET_KEY_test|to_text)
            "Content-Type: application/x-www-form-urlencoded"
            "Idempotency-Key: sd-sandbox-checkout-" ~ ($intent.id|to_text)
          ]
        } as $stripe
      
        precondition ($stripe.response.status == 200 && $stripe.response.result.object == "checkout.session" && $stripe.response.result.livemode == false && $stripe.response.result.currency == "eur" && $stripe.response.result.amount_total == ((($intent.selling_price * 100))|round:0|to_int)) {
          error_type = "inputerror"
          error = "Stripe test session not confirmed; retry only with the same request key"
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
    environment                : "sandbox"
    order_id                   : $intent.order_id
    supplier_checkout_intent_id: $intent.id
    status                     : $intent.status
    checkout_url               : $intent.checkout_context.checkout_url
    selling_price              : $intent.selling_price
    currency                   : "EUR"
    voucher_allowed            : false
  }
}