// Internal room-photo refresh for production drafts; no approval, bookings or payments.
function "supplier/production/refresh_deal_photos" {
  input {
    int deal_id
    bool save?
  }
  stack {
    db.get deals {
      field_name = "id"
      field_value = $input.deal_id
    } as $original
    precondition ($original != null && $original.status == "draft" && $original.is_active == false) {
      error = "Existing inactive draft required"
    }
    db.query supplier_deals {
      where = $db.supplier_deals.deal_id == $input.deal_id && $db.supplier_deals.provider == "nuitee" && $db.supplier_deals.environment == "production"
      return = {type: "single"}
    } as $supplier
    precondition ($supplier != null) { error = "Expected hotel mapping required" }
    api.request {
      url = "https://api.liteapi.travel/v3.0/data/hotel?hotelId=" ~ $supplier.supplier_hotel_id
      method = "GET"
      headers = ["Accept: application/json", "X-API-Key: " ~ $env.NUITEE_PRODUCTION_API_KEY]
      timeout = 30
    } as $details
    api.lambda {
      code = "return !$var.supplier.supplier_mapping?.offer?.rates?.[0]?.mappedRoomId;"
      timeout = 5
    } as $needs_mapping
    var $mapping_rates { value = null }
    conditional {
      if ($needs_mapping) {
        api.request {
          url = "https://api.liteapi.travel/v3.0/hotels/rates"
          method = "POST"
          params = {
            hotelIds: [$supplier.supplier_hotel_id]
            occupancies: $supplier.supplier_mapping.request.occupancies
            checkin: $supplier.supplier_mapping.request.checkin
            checkout: $supplier.supplier_mapping.request.checkout
            currency: "EUR"
            guestNationality: "NL"
            roomMapping: true
            maxRatesPerHotel: 100
          }
          headers = ["Accept: application/json", "Content-Type: application/json", "X-API-Key: " ~ $env.NUITEE_PRODUCTION_API_KEY]
          timeout = 30
        } as $rates_response
        var.update $mapping_rates { value = $rates_response }
      }
    }
    api.lambda {
      code = """
const r=$var.details.response,h=r.result?.data;
if(r.status!==200||!h||h.id!==$var.supplier.supplier_hotel_id)return {valid:false,reason:'Hotel details mismatch'};
const rooms=Array.isArray(h.rooms)?h.rooms:[];
const old=$var.supplier.supplier_mapping?.offer?.rates?.[0];
let mapped=old?.mappedRoomId, mappingSource='offer_mapped_room_id';
if(!mapped){
 const response=$var.mapping_rates?.response;
 if(response?.status!==200||!Array.isArray(response.result?.data))return {valid:false,reason:'Provider room mapping unavailable'};
 // Photo identity follows the supplier room name, not the meal or cancellation rate.
 // Require every exact-name match for this occupancy to agree on one room ID.
 const matching=response.result.data.filter(h=>h.hotelId===$var.supplier.supplier_hotel_id).flatMap(h=>h.roomTypes||[]).flatMap(o=>o.rates||[]).filter(r=>r.name===old.name&&r.adultCount===old.adultCount&&r.childCount===old.childCount);
 const ids=[...new Set(matching.map(r=>r.mappedRoomId).filter(Boolean).map(String))];
 mapped=matching.length&&matching.every(r=>r.mappedRoomId)&&ids.length===1?ids[0]:null;
 mappingSource='provider_exact_room_name';
}
const binding={source:mappingSource,hotel_id:$var.supplier.supplier_hotel_id,rate_name:old.name,mapped_room_id:mapped,adult_count:old.adultCount,child_count:old.childCount,checked_at:Date.now()};
const room=mapped?rooms.find(x=>String(x.id)===String(mapped)):null;
const photos=(room?.photos||[]).map(p=>({url:p.hd_url||p.url,caption:old.name||'Kamerfoto',scope:'matched_room'}));
const unique=[...new Map(photos.filter(p=>typeof p.url==='string'&&p.url.startsWith('https://')).map(p=>[p.url,p])).values()];
const candidates=unique;
if(!room||!candidates.length)return {valid:false,reason:'Confirmed room mapping and room photos required'};
return {valid:true,supplier_details:{id:h.id,hotelFacilities:Array.isArray(h.hotelFacilities)?h.hotelFacilities:[],facilities:Array.isArray(h.facilities)?h.facilities.map(f=>({facilityId:f.facilityId,name:f.name})):[],parking:typeof h.parking==='string'?h.parking:'',checked_at:Date.now()},preview:$input.save!==true,photos:candidates,room_matched:true,mapped_room_id:mapped,rate_name:old.name,binding,checked_at:Date.now()};
"""
      timeout = 5
    } as $prepared
    precondition ($prepared.valid) { error = $prepared.reason }
    var $result { value = $prepared }
    conditional {
      if ($prepared.preview == false) {
    function.run "supplier/production/select_room_photos" {
      input = {photos: $prepared.photos}
    } as $photo_selection
    api.lambda {
      code = "return {...$var.prepared,photos:$var.photo_selection.photos,images:$var.photo_selection.photos.map(p=>p.url),algorithm:$var.photo_selection.algorithm};"
      timeout = 5
    } as $verified_selection
    var.update $prepared { value = $verified_selection }
    db.transaction {
      stack {
        db.get deals {
          field_name = "id"
          field_value = $input.deal_id
          lock = true
        } as $locked_deal
        precondition ($locked_deal.status == "draft" && $locked_deal.is_active == false) { error = "Deal must remain a draft" }
        db.get supplier_deals {
          field_name = "id"
          field_value = $supplier.id
          lock = true
        } as $locked_supplier
        api.lambda {
          code = """
const content=$var.locked_supplier.supplier_content||{},hotel=content.hotel||{};
if(JSON.stringify($var.locked_supplier.supplier_mapping)!==JSON.stringify($var.supplier.supplier_mapping)||$var.locked_supplier.supplier_hotel_id!==$var.supplier.supplier_hotel_id)throw new Error('Room mapping changed; fetch photos again');
return {...content,hotel:{...hotel,supplier_details:$var.prepared.supplier_details,previous_supplier_details:hotel.supplier_details||null,images:$var.prepared.images,photo_gallery:$var.prepared.photos,photos_checked_at:$var.prepared.checked_at,room_photos_matched:$var.prepared.room_matched,photo_hotel_id:$var.locked_supplier.supplier_hotel_id,mapped_room_id:$var.prepared.mapped_room_id,photo_rate_name:$var.prepared.rate_name,room_photo_binding:$var.prepared.binding,photo_verification:{status:'verified',algorithm:$var.prepared.algorithm,max_photos:5,checked_at:$var.prepared.checked_at},previous_images:hotel.previous_images||hotel.images||[]}};
"""
          timeout = 5
        } as $content
        db.edit supplier_deals {
          field_name = "id"
          field_value = $supplier.id
          data = {supplier_content: $content}
        } as $updated_supplier
        db.edit deals {
          field_name = "id"
          field_value = $input.deal_id
          data = {external_image_urls: $prepared.images, updated_at: now}
        } as $updated_deal
        var.update $result {
          value = {deal_id: $input.deal_id, status: $updated_deal.status, photo_count: ($prepared.images|count), room_photos_matched: $prepared.room_matched, gallery: $prepared.photos}
        }
      }
    }
      }
    }
  }
  response = $result
  history = false
}
