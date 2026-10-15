// Internal room-photo refresh for production drafts; no approval, bookings or payments.
function "supplier/production/refresh_deal_photos" {
  input {
    int deal_id
    json verified_photos?
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
const photos=(room?.photos||[]).map(p=>({url:p.hd_url||p.url,caption:p.imageDescription||room.roomName||'Kamerfoto',scope:'matched_room'}));
const unique=[...new Map(photos.filter(p=>typeof p.url==='string'&&p.url.startsWith('https://')).map(p=>[p.url,p])).values()];
const candidates=unique;
const verified=$input.verified_photos;
if(verified==null)return {valid:true,reason:room?null:'Confirmed mapping missing from this offer; refresh offer before selecting room photos',preview:true,photos:candidates,room_matched:!!room,mapped_room_id:mapped??null,rate_name:old?.name,mapping:binding,reference_room_name:room?.roomName};
if(!room||!candidates.length)return {valid:false,reason:'Confirmed room mapping and room photos required'};
const hamming=(a,b)=>{let n=BigInt('0x'+a)^BigInt('0x'+b),bits=0;while(n){bits+=Number(n&1n);n>>=1n;}return bits;};
const valid=Array.isArray(verified)&&verified.length>0&&verified.length<=5&&verified.every(p=>candidates.some(c=>c.url===p.url)&&/^[a-f0-9]{64}$/.test(p.sha256)&&/^[a-f0-9]{16}$/.test(p.dhash));
if(!valid)return {valid:false,reason:'Verified photo selection required'};
for(let i=0;i<verified.length;i++)for(let j=0;j<i;j++)if(verified[i].url===verified[j].url||verified[i].sha256===verified[j].sha256||hamming(verified[i].dhash,verified[j].dhash)<=5)return {valid:false,reason:'Duplicate or visually similar image rejected'};
const selected=verified.map(p=>({...candidates.find(c=>c.url===p.url),sha256:p.sha256,dhash:p.dhash}));
return {valid:true,preview:false,images:selected.map(p=>p.url),photos:selected,room_matched:!!room,mapped_room_id:mapped,rate_name:old.name,binding,checked_at:Date.now()};
"""
      timeout = 5
    } as $prepared
    precondition ($prepared.valid) { error = $prepared.reason }
    var $result { value = $prepared }
    conditional {
      if ($prepared.preview == false) {
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
return {...content,hotel:{...hotel,images:$var.prepared.images,photo_gallery:$var.prepared.photos,photos_checked_at:$var.prepared.checked_at,room_photos_matched:$var.prepared.room_matched,photo_hotel_id:$var.locked_supplier.supplier_hotel_id,mapped_room_id:$var.prepared.mapped_room_id,photo_rate_name:$var.prepared.rate_name,room_photo_binding:$var.prepared.binding,photo_verification:{status:'verified',algorithm:'sha256+dhash64-v1',max_photos:5,checked_at:$var.prepared.checked_at},previous_images:hotel.previous_images||hotel.images||[]}};
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
}
