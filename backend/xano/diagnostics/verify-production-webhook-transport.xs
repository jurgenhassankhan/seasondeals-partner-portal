// Internal synthetic HTTP proof only. No order IDs, bookings, payments or mail. Not used by production flow.
function "supplier/diagnostics/verify_production_webhook_transport" {
  input {
  }

  stack {
    function.run "supplier/production/config_status" as $gate
    precondition ($gate.configured_closed && $gate.can_book == false && $gate.can_pay == false && $gate.can_sell == false) {
      error_type = "accessdenied"
      error = "Diagnostic requires closed production"
    }
  
    api.lambda {
      code = """
        const body='{ "id": "evt_SeasonDealsTransportProbe20261015", "object": "event", "livemode": true, "type": "seasondeals.transport_probe", "data": { "object": { "id": "fixture_only" } } }';
        const timestamp=Math.floor(Date.now()/1000);
        return {body,timestamp,payload:timestamp+'.'+body,stale_payload:(timestamp-600)+'.'+body,stale_timestamp:timestamp-600};
        """
      timeout = 5
    } as $fixture
  
    var $signature {
      value = $fixture.payload
        |hmac_sha256:$env.NUITEE_STRIPE_WEBHOOK_SECRET:false
    }
  
    var $stale_signature {
      value = $fixture.stale_payload
        |hmac_sha256:$env.NUITEE_STRIPE_WEBHOOK_SECRET:false
    }
  
    api.request {
      url = "https://xgrq-dkge-tace.n7e.xano.io/api:seasondeals-public/webhooks/nuitee-production"
      method = "POST"
      params = $fixture.body
      headers = [
        "Content-Type: application/json"
        "Stripe-Signature: t=" ~ $fixture.timestamp ~ ",v1=" ~ $signature
      ]
    
      timeout = 15
    } as $valid
  
    api.request {
      url = "https://xgrq-dkge-tace.n7e.xano.io/api:seasondeals-public/webhooks/nuitee-production"
      method = "POST"
      params = $fixture.body ~ " "
      headers = [
        "Content-Type: application/json"
        "Stripe-Signature: t=" ~ $fixture.timestamp ~ ",v1=" ~ $signature
      ]
    
      timeout = 15
    } as $tampered
  
    api.request {
      url = "https://xgrq-dkge-tace.n7e.xano.io/api:seasondeals-public/webhooks/nuitee-production"
      method = "POST"
      params = $fixture.body
      headers = ["Content-Type: application/json"]
      timeout = 15
    } as $missing
  
    api.request {
      url = "https://xgrq-dkge-tace.n7e.xano.io/api:seasondeals-public/webhooks/nuitee-production"
      method = "POST"
      params = $fixture.body
      headers = [
        "Content-Type: application/json"
        "Stripe-Signature: t=" ~ $fixture.stale_timestamp ~ ",v1=" ~ $stale_signature
      ]
    
      timeout = 15
    } as $stale
  
    api.lambda {
      code = """
        const sanitize=r=>({status:r?.response?.status,code:r?.response?.result?.code,message:r?.response?.result?.message});
        const valid=sanitize($var.valid),tampered=sanitize($var.tampered),missing=sanitize($var.missing),stale=sanitize($var.stale);
        return {passed:valid.status===403&&valid.message==='PRODUCTION_NOT_RELEASED'&&[tampered,missing,stale].every(x=>x.status===403&&x.message==='Invalid webhook signature'),valid,tampered,missing,stale,synthetic:true,transactions_enabled:false};
        """
      timeout = 5
    } as $result
  }

  response = $result
}