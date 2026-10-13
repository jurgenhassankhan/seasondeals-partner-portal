// Dedicated Nuitée live callback. Closed preparation only; no writes or fulfillment.
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
      encoding = "text"
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
        return {valid,accepted};
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
  
    precondition (false) {
      error = "PRODUCTION_ORCHESTRATION_NOT_RELEASED"
    }
  }

  response = {received: false}
}