// Internal one-hotel rate example for preparing an admin draft. No writes, prebook or transactions.
function "supplier/production/preview_amsterdam_rates" {
  input {
  }

  stack {
    function.run "supplier/production/config_status" as $gate
    precondition ($gate.config_valid && $gate.configured_closed) {
      error = "Closed production preparation config required"
    }
  
    api.request {
      url = "https://api.liteapi.travel/v3.0/hotels/rates"
      method = "POST"
      params = {
        hotelIds        : ["lp225fcf"]
        occupancies     : [{adults:2}]
        checkin         : "2026-11-27"
        checkout        : "2026-11-29"
        currency        : "EUR"
        guestNationality: "NL"
        maxRatesPerHotel: 50
        includeHotelData: true
      }
    
      headers = [
        "X-API-Key: " ~ $env.NUITEE_PRODUCTION_API_KEY
        "Content-Type: application/json"
        "Accept: application/json"
      ]
    
      timeout = 30
    } as $rates_http
  
    api.lambda {
      code = """
        const r=$var.rates_http.response;const ok=r.status===200&&Array.isArray(r.result?.data);
        const hotels=ok?r.result.data.filter(h=>h.hotelId==='lp225fcf'):[];
        const offers=hotels.flatMap(h=>Array.isArray(h.roomTypes)?h.roomTypes:[]);
        return {success:ok,http_status:r.status,checked_at:Date.now(),hotel_id:'lp225fcf',checkin:'2026-11-27',checkout:'2026-11-29',adults:2,rooms:1,currency:'EUR',example_only:true,offer_count:offers.length,offers:offers.map(o=>({offer_id:o.offerId,supplier:o.supplier,supplier_id:o.supplierId,rate_type:o.rateType,price_type:o.priceType,total:o.offerRetailRate,rates:(o.rates||[]).map(t=>({name:t.name,board_type:t.boardType,board_name:t.boardName,adults:t.adultCount,children:t.childCount,retail_rate:t.retailRate,cancellation:t.cancellationPolicies,remarks:t.remarks,payment_types:t.paymentTypes}))})),admin_approval_required:true,imported:false,production_costs_verified:false,can_book:false,can_pay:false,can_sell:false};
        """
      timeout = 5
    } as $result
  }

  response = $result
}