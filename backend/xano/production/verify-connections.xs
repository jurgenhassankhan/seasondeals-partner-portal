// Internal read-only credential check. No booking, payment, refund, mail, or database writes.
function "supplier/production/verify_connections" {
  input {}
  stack {
    function.run "supplier/production/config_status" { input = {} } as $gate
    precondition ($gate.config_valid && $gate.configured_closed) { error = "Closed production preparation config required" }
    api.request {
      url = "https://api.stripe.com/v1/accounts/acct_1TkMuaPz36j75L08"
      method = "GET"
      headers = ["Authorization: Bearer " ~ $env.STRIPE_SECRET_KEY_live, "Stripe-Version: 2023-10-16"]
      timeout = 15
    } as $account
    api.request {
      url = "https://api.stripe.com/v1/balance"
      method = "GET"
      headers = ["Authorization: Bearer " ~ $env.STRIPE_SECRET_KEY_live, "Stripe-Version: 2023-10-16"]
      timeout = 15
    } as $balance
    api.request {
      url = "https://api.liteapi.travel/v3.0/data/currencies"
      method = "GET"
      headers = ["X-API-Key: " ~ $env.NUITEE_PRODUCTION_API_KEY, "Accept: application/json"]
      timeout = 15
    } as $nuitee
    api.lambda {
      code = """
const a=$var.account.response,b=$var.balance.response,n=$var.nuitee.response;
const stripe=a.status===200&&a.result?.object==='account'&&a.result.id==='acct_1TkMuaPz36j75L08'&&b.status===200&&b.result?.object==='balance'&&b.result.livemode===true;
return {checked_at:Date.now(),stripe:{authenticated:stripe,account_matches:a.result?.id==='acct_1TkMuaPz36j75L08',livemode:b.result?.livemode===true,charges_enabled:a.result?.charges_enabled===true,payouts_enabled:a.result?.payouts_enabled===true,account_http_status:a.status,balance_http_status:b.status},nuitee:{authenticated:n.status===200&&Array.isArray(n.result?.data),http_status:n.status,credential_source:'NUITEE_PRODUCTION_API_KEY',production_mode_source:'Production dashboard key; currencies endpoint does not prove booking mode'},production_released:false,transactions_enabled:false};
"""
      timeout = 5
    } as $result
  }
  response = $result
  history = "disabled"
}

