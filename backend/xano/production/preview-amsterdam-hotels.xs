// Internal bounded hotel metadata preview. No database writes or transactions.
function "supplier/production/preview_amsterdam_hotels" {
  input {
  }

  stack {
    function.run "supplier/production/config_status" as $gate
    precondition ($gate.config_valid && $gate.configured_closed) {
      error = "Closed production preparation config required"
    }
  
    api.request {
      url = "https://api.liteapi.travel/v3.0/data/hotels?countryCode=NL&cityName=Amsterdam&limit=5"
      method = "GET"
      headers = [
        "Accept: application/json"
        "X-API-Key: " ~ $env.NUITEE_PRODUCTION_API_KEY
      ]
    
      timeout = 30
    } as $hotels
  
    api.lambda {
      code = """
        const r=$var.hotels.response;
        const ok=r.status===200&&Array.isArray(r.result?.data);
        const rows=ok?r.result.data.slice(0,5):[];
        return {success:ok,provider:'nuitee',credential_source:'NUITEE_PRODUCTION_API_KEY',scope:'Amsterdam metadata example; not nationwide inventory',checked_at:Date.now(),http_status:r.status,hotels:rows.map(h=>({id:h.id,name:h.name,city:h.city,country:h.country,address:h.address,stars:h.stars,rating:h.rating,main_photo:h.main_photo,thumbnail:h.thumbnail})),count:rows.length,availability_checked:false,can_book:false,can_pay:false,can_sell:false,production_released:false};
        """
      timeout = 5
    } as $result
  }

  response = $result
}