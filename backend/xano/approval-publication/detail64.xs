// Get a single deal by ID
query "deals/{deal_id}" verb=GET {
  api_group = "Public API"

  input {
    int deal_id {
      table = "deals"
    }
  }

  stack {
    db.get deals {
      field_name = "id"
      field_value = $input.deal_id
    } as $deal
  
    precondition ($deal != null) {
      error_type = "notfound"
      error = "Deal not found"
    }
  
    // Ensure the deal exists and is public (Requirement Phase Productiescheiding)
    var $is_public {
      value = false
    }
  
    conditional {
      if ($deal.source != "provider_sync" && $deal != null && $deal.status == "active" && ($deal.hotel_integration_id ?? 0) == 0) {
        var.update $is_public {
          value = true
        }
      }
    }
  
    conditional {
      if ($deal.source != "provider_sync" && $deal != null && $deal.status == "active" && ($deal.hotel_integration_id ?? 0) > 0) {
        db.get hotel_integrations {
          field_name = "id"
          field_value = $deal.hotel_integration_id
        } as $hi
      
        conditional {
          if ($hi != null && $hi.environment == "production" && $hi.status == "active") {
            var.update $is_public {
              value = true
            }
          }
        }
      }
    }
  
    conditional {
      if ($deal.source == "provider_sync" && $deal.status == "active" && $deal.is_active == true && $deal.approved_at != null && ($deal.deleted_at == null || $deal.deleted_at == 0)) {
        db.query supplier_deals {
          where = $db.supplier_deals.deal_id == $deal.id && $db.supplier_deals.provider == "nuitee" && $db.supplier_deals.environment == "production" && $db.supplier_deals.is_enabled == true
          return = {type: "single"}
        } as $public_supplier
        var.update $is_public { value = ($public_supplier != null) }
      }
    }

    precondition ($is_public) {
      error_type = "notfound"
      error = "Deal not found"
    }
  
    db.get hotels {
      field_name = "id"
      field_value = $deal.hotel_id
    } as $hotel
  
    var $deal {
      value = $deal
        |set:"hotel":```
          {
            name: $hotel.name,
            city: $deal.city,
            star_rating: $deal.star_rating
          }
          ```
        |set:"image":($deal.images|first)
        |set:"city":$deal.city
        |set:"star_rating":$deal.star_rating
        |set:"inventory":$deal.inventory
    }
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
return $var.deal.source === 'provider_sync' ? project($var.deal) : $var.deal;
"""
      timeout = 5
    } as $public_result
  }

  response = $public_result
}
