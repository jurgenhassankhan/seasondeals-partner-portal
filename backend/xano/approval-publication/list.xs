//  Haal alle actieve deals op met gekoppelde hotelinformatie.
//  Filtert op status = active en voert een left join uit naar de hotels tabel.
//  Retourneer de geformatteerde lijst met deals.
//  Geen input parameters toegestaan voor hotel_id.
// 
//  BEVROREN: Officieel API Contract (Webflow)
//  Dit endpoint retourneert alle 44 velden uit de deals tabel.
//  Legacy velden 'image' en 'hotel' zijn behouden voor backward compatibility.
query deals verb=GET {
  api_group = "Public API"

  input {
  }

  stack {
    // Haal de deals op en voeg de hotelnaam toe via een join naar de hotels tabel.
    db.query deals {
      join = {
        hotels            : {
          table: "hotels"
          type : "left"
          where: $db.deals.hotel_id == $db.hotels.id
        }
        hotel_integrations: {
          table: "hotel_integrations"
          type : "left"
          where: $db.deals.hotel_integration_id == $db.hotel_integrations.id
        }
      }
    
      where = ($db.deals.source == null || $db.deals.source != "provider_sync") && $db.deals.status == "active" && (($db.deals.hotel_integration_id == null || $db.deals.hotel_integration_id == 0) || ($db.hotel_integrations.environment == "production" && $db.hotel_integrations.status == "active"))
      eval = {hotel_name: $db.hotels.name}
      return = {type: "list"}
    } as $deals
  
    // Structureer de response voor Webflow (Alle contractvelden + Legacy support).
    array.map ($deals) {
      by = $this
        |set:"image":($this.images|first)
        |set:"hotel":```
          {
            name: $this.hotel_name,
            city: $this.city,
            star_rating: $this.star_rating
          }
          ```
    } as $result
    db.query deals {
      join = {
        supplier_deals: {
          table: "supplier_deals"
          type: "inner"
          where: $db.deals.id == $db.supplier_deals.deal_id
        }
      }
      where = $db.deals.source == "provider_sync" && $db.deals.status == "active" && $db.deals.is_active == true && $db.deals.approved_at != null && ($db.deals.deleted_at == null || $db.deals.deleted_at == 0) && $db.supplier_deals.provider == "nuitee" && $db.supplier_deals.environment == "production" && $db.supplier_deals.is_enabled == true
      return = {type: "list"}
    } as $supplier_public_rows
    function.run "supplier/production/config_status" { input = {} } as $production_status
    api.lambda {
      code = """
const fields = ['id','title','description','short_description','long_description','price','deal_price','original_price','source','status','is_active','city','country','address','star_rating','review_score','review_count','room_type','includes_breakfast','includes_wifi','includes_parking','includes_late_checkout','includes_welcome_drink','max_guests','minimum_nights','travel_period_start','travel_period_end','cancellation_policy','category'];
function project(d) {
  const result = Object.fromEntries(fields.filter(k => d[k] !== undefined).map(k => [k,d[k]]));
  const values = [...(Array.isArray(d.external_image_urls) ? d.external_image_urls : []), ...(Array.isArray(d.images) ? d.images : [])];
  result.images = values.map(v => typeof v === 'string' ? v : v?.url).filter(v => typeof v === 'string' && v.startsWith('https://'));
  result.image = result.images[0] || null;
  result.hotel_name = d.hotel_name || '';
  result.hotel = {name: result.hotel_name, city: d.city, star_rating: d.star_rating};
  result.inventory = null;
  result.booking_enabled = $var.production_status.can_sell === true;
  return result;
}
return [...$var.result, ...$var.supplier_public_rows.map(project)];
"""
      timeout = 5
    } as $public_result
  }

  response = $public_result
}
