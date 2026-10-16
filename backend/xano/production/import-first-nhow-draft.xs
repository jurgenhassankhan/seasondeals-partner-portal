// Bounded internal preparation: fresh provider offer -> unpublished admin draft. No transactions at provider.
function "supplier/production/import_first_nhow_draft" {
  input {
    text import_id?
  }

  stack {
    function.run "supplier/production/config_status" as $gate
    precondition ($gate.config_valid && $gate.configured_closed) {
      error = "Closed preparation config required"
    }
  
    api.lambda {
      code = "const id=$input.import_id||'SD-PROD-NHOW-20261127-29-2A-RO-V1';if(!/^SD-PROD-NHOW-[A-Z0-9-]{1,80}$/.test(id))throw Error('Invalid bounded import ID');return id;"
      timeout = 5
    } as $import_id
    function.run "supplier/production/preview_amsterdam_hotels" as $metadata
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
        roomMapping     : true
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
        const response=$var.rates_http.response, hotel=$var.metadata.hotels?.find(h=>h.id==='lp225fcf');
        if(response.status!==200||(response.result?.sandbox!=null&&response.result.sandbox!==false)||!hotel||!Array.isArray(response.result.data)) return {valid:false,reason:'Verified production response and hotel metadata required'};
        const offers=response.result.data.filter(h=>h.hotelId==='lp225fcf').flatMap(h=>h.roomTypes||[]);
        const candidates=offers.filter(o=>o.rateType==='standard'&&o.offerId&&o.offerRetailRate?.currency==='EUR'&&Number.isFinite(o.offerRetailRate.amount)&&o.offerRetailRate.amount>0&&o.rates?.length===1&&o.rates.every(r=>r.mappedRoomId&&r.adultCount===2&&r.childCount===0&&r.boardType==='RO'&&r.cancellationPolicies?.refundableTag==='NRFN'&&Array.isArray(r.retailRate?.taxesAndFees)&&r.retailRate.taxesAndFees.every(t=>t.included===true&&t.currency==='EUR'&&Number.isFinite(t.amount)&&t.amount>=0)));
        candidates.sort((a,b)=>a.offerRetailRate.amount-b.offerRetailRate.amount);
        const offer=candidates[0];if(!offer)return {valid:false,reason:'No standard NRFN room-only offer without excluded fees'};
        const base=offer.offerRetailRate.amount;const suggested=offer.rates[0].retailRate.suggestedSellingPrice?.find(p=>p.currency==='EUR')?.amount;
        if(!Number.isFinite(suggested)||suggested<=0)return {valid:false,reason:'Public price reference missing'};
        const price=Math.ceil(Math.max(suggested,base*1.20)*100)/100;
        const hotelContent={...hotel,images:[]};
        const request={hotel_ids:['lp225fcf'],occupancies:[{adults:2}],checkin:'2026-11-27',checkout:'2026-11-29',currency:'EUR',guest_nationality:'NL'};
        return {valid:true,hotel:hotelContent,offer,base,price,checked_at:Date.now(),mapping:{provider:'nuitee',environment:'production',import_id:$var.import_id,hotel:hotelContent,request,offer,checked_at:Date.now(),credential_source:'NUITEE_PRODUCTION_API_KEY',provider_sandbox:response.result.sandbox??null,environment_evidence:'dedicated_production_credential; response_has_no_environment_marker',import_version:2},pricing:{mode:'override',override_amount:price,markup_percentage:20,markup_amount:0,discount_percentage:0,rounding:'none',min_margin_amount:20,processing_fee:null,stripe_fee_percentage:null,stripe_fee_fixed:null,payment_method:'ACC_CREDIT_CARD',production_costs_verified:false,cost_evidence:null,price_status:'proposal_requires_review'},start:Date.parse('2026-11-27T00:00:00Z'),end:Date.parse('2026-11-29T00:00:00Z')};
        """
      timeout = 5
    } as $prepared
  
    precondition ($prepared.valid) {
      error = $prepared.reason
    }
  
    api.request {
      url = "https://api.liteapi.travel/v3.0/data/hotel?hotelId=lp225fcf"
      method = "GET"
      headers = ["Accept: application/json", "X-API-Key: " ~ $env.NUITEE_PRODUCTION_API_KEY]
      timeout = 30
    } as $room_details
    api.lambda {
      code = """
const response=$var.room_details.response,h=response.result?.data,rate=$var.prepared.offer.rates[0];
if(response.status!==200||h?.id!=='lp225fcf')throw Error('Hotel details mismatch');
const room=h.rooms?.find(r=>String(r.id)===String(rate.mappedRoomId));
if(!room?.photos?.length)throw Error('Confirmed room photos required');
return room.photos.map(p=>({url:p.hd_url||p.url,caption:rate.name,scope:'matched_room'}));
"""
      timeout = 5
    } as $room_candidates
    function.run "supplier/production/select_room_photos" {
      input = {photos: $room_candidates}
    } as $photo_selection
    api.lambda {
      code = """
const p=$var.prepared,r=p.offer.rates[0],selection=$var.photo_selection,at=Date.now();
const hotel={...p.hotel,images:selection.photos.map(p=>p.url),photo_gallery:selection.photos,photos_checked_at:at,room_photos_matched:true,photo_hotel_id:'lp225fcf',mapped_room_id:r.mappedRoomId,photo_rate_name:r.name,room_photo_binding:{source:'offer_mapped_room_id',hotel_id:'lp225fcf',rate_name:r.name,mapped_room_id:r.mappedRoomId,adult_count:r.adultCount,child_count:r.childCount,checked_at:at},photo_verification:{status:'verified',algorithm:selection.algorithm,max_photos:5,checked_at:at}};
return {...p,hotel,mapping:{...p.mapping,hotel}};
"""
      timeout = 5
    } as $with_photos
    var.update $prepared { value = $with_photos }

    db.query admin_users {
      return = {type: "single"}
    } as $owner
  
    precondition ($owner != null && $owner.role == "superadmin") {
      error = "Workspace owner lock required"
    }
  
    var $result {
      value = null
    }
  
    db.transaction {
      stack {
        db.get admin_users {
          field_name = "id"
          field_value = $owner.id
          lock = true
        } as $import_lock
      
        db.query deals {
          where = $db.deals.external_id == $import_id
          return = {type: "single"}
        } as $existing
      
        conditional {
          if ($existing != null) {
            var.update $result {
              value = {
                deal_id: $existing.id
                status : $existing.status
                created: false
                public : false
              }
            }
          }
        
          else {
            db.add deals {
              data = {
                hotel_id           : 0
                title              : "Twee nachten bij nhow Amsterdam RAI"
                description        : "Verblijf van 27 tot 29 november 2026 voor twee volwassenen, zonder ontbijt."
                short_description  : "Twee nachten in Amsterdam voor twee personen, zonder ontbijt."
                long_description   : "Verblijf van 27 tot 29 november 2026 bij nhow Amsterdam RAI. Eén " ~ $prepared.offer.rates[0].name ~ " voor twee volwassenen. Ontbijt is niet inbegrepen. Belastingen en heffingen zijn volgens het geselecteerde tarief inbegrepen."
                price              : $prepared.price
                deal_price         : $prepared.price
                inventory          : 0
                sold_quantity      : 0
                status             : "draft"
                is_active          : false
                source             : "provider_sync"
                external_id        : $import_id
                hotel_name         : $prepared.hotel.name
                city               : $prepared.hotel.city
                country            : "NL"
                address            : $prepared.hotel.address
                star_rating        : $prepared.hotel.stars
                review_score       : $prepared.hotel.rating
                external_image_urls: $prepared.hotel.images
                room_type          : $prepared.offer.rates[0].name
                includes_breakfast : false
                max_guests         : 2
                minimum_nights     : 2
                travel_period_start: $prepared.start
                travel_period_end  : $prepared.end
                cancellation_policy: "Niet restitueerbaar: bij annulering is het volledige verblijfsbedrag verschuldigd."
                review_notes       : "Productieconcept. Verkoopprijs is een voorstel; ACC-/Stripekosten en marge nog te bevestigen. Niet goedgekeurd of publiek."
                updated_at         : now
              }
            } as $new_deal
          
            db.add supplier_deals {
              data = {
                deal_id             : $new_deal.id
                provider            : "nuitee"
                environment         : "production"
                supplier_hotel_id   : "lp225fcf"
                supplier_mapping    : $prepared.mapping
                supplier_content    : $prepared.mapping
                supplier_base_amount: $prepared.base
                pricing_config      : $prepared.pricing
                sync_status         : "pending_review"
                is_enabled          : false
                last_synced_at      : now
              }
            } as $new_supplier
          
            var.update $result {
              value = {
                deal_id                  : $new_deal.id
                supplier_deal_id         : $new_supplier.id
                status                   : "draft"
                created                  : true
                public                   : false
                price_proposal           : $prepared.price
                production_costs_verified: false
                photo_count              : ($prepared.hotel.images|count)
              }
            }
          }
        }
      }
    }
  }

  response = $result
  history = false
}