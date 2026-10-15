// Dedicated production payment-to-booking callback. Entry gate remains closed; no production release.
query "webhooks/nuitee-production" verb=POST {
  api_group = "Public API"

  input {
  }

  stack {
    function.run "supplier/production/config_status" as $entry_gate
    precondition ($entry_gate.can_book && $entry_gate.can_pay && $entry_gate.can_sell) {
      error_type = "accessdenied"
      error = "PRODUCTION_NOT_RELEASED"
    }
  
    util.get_raw_input {
      encoding = "none"
      exclude_middleware = true
    } as $raw_body
  
    var $headers {
      value = $env.$http_headers
    }
  
    api.lambda {
      code = """
        const headers=$var.headers;
        const values=Array.isArray(headers)?headers.map(h=>String(h)):Object.entries(headers||{}).map(([k,v])=>k+': '+v);
        const matches=values.filter(h=>h.slice(0,h.indexOf(':')).toLowerCase()==='stripe-signature');
        return {signature:matches.length===1?matches[0].slice(matches[0].indexOf(':')+1).trim():''};
        """
      timeout = 5
    } as $header
  
    function.run "supplier/production/verify_stripe_signature" {
      input = {
        raw_body       : $raw_body
        signature      : $header.signature
        endpoint_secret: $env.NUITEE_STRIPE_WEBHOOK_SECRET
      }
    } as $signed
  
    precondition ($signed.verified && $signed.event.livemode) {
      error_type = "accessdenied"
      error = "Verified live Stripe event required"
    }
  
    api.request {
      url = "https://api.stripe.com/v1/events/" ~ ($signed.event.id|url_encode)
      method = "GET"
      headers = [
        "Authorization: Bearer " ~ $env.STRIPE_SECRET_KEY_live
        "Stripe-Version: 2023-10-16"
      ]
    
      timeout = 15
    } as $remote
  
    api.lambda {
      code = """
        const r=$var.remote.response,e=r.result,s=e?.data?.object,signed=$var.signed.event;
        const valid=r.status===200&&e?.object==='event'&&e.id===signed.id&&e.type===signed.type&&e.livemode===true&&e.account==null&&e.data?.object?.id===signed.data?.object?.id;
        const accepted=valid&&['checkout.session.completed','checkout.session.async_payment_succeeded'].includes(e.type)&&s?.object==='checkout.session'&&s.livemode===true&&s.payment_status==='paid'&&s.metadata?.supplier_fulfillment==='nuitee'&&s.metadata?.supplier_flow==='nuitee_production_v1';
        const meta=s?.metadata||{};
        const intent_id=Number(meta.supplier_checkout_intent_id),order_id=Number(meta.supplier_order_id);
        return {valid,accepted:accepted&&Number.isSafeInteger(intent_id)&&intent_id>0&&Number.isSafeInteger(order_id)&&order_id>0,intent_id,order_id,session_id:s?.id};
        """
      timeout = 5
    } as $event_check
  
    precondition ($event_check.valid) {
      error_type = "accessdenied"
      error = "Stripe event lookup did not match signed event"
    }
  
    conditional {
      if ($event_check.accepted != true) {
        return {
          value = {received: true, ignored: true}
        }
      }
    }
  
    function.run "supplier/production/config_status" as $gate
    precondition ($gate.can_book && $gate.can_pay && $gate.can_sell) {
      error = "PRODUCTION_NOT_RELEASED"
    }
  
    db.get supplier_checkout_intents {
      field_name = "id"
      field_value = $event_check.intent_id
    } as $callback_intent
  
    precondition ($callback_intent != null && $callback_intent.environment == "production" && $callback_intent.provider_slug == "nuitee" && $callback_intent.order_id == $event_check.order_id && $callback_intent.stripe_checkout_session_id == $event_check.session_id) {
      error_type = "accessdenied"
      error = "Stripe event does not belong to this production checkout"
    }
  
    function.run "supplier/production/fulfill_payment" {
      input = {supplier_checkout_intent_id: $callback_intent.id}
    } as $fulfillment
  
    conditional {
      if ($fulfillment.voucher_allowed) {
        function.run "supplier/production/finalize" {
          input = {supplier_checkout_intent_id: $callback_intent.id}
        } as $finalization
      
        return {
          value = {
            received           : true
            status             : $fulfillment.status
            confirmation_status: $finalization.mail_status
          }
        }
      }
    }
  
    return {
      value = {received: true, status: $fulfillment.status}
    }
  }

  response = {received: false}
}