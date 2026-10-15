//  Get a specific deal by ID with all hotel information
// 
//  BEVROREN: Officieel API Contract (Webflow)
//  Dit endpoint retourneert alle 44 velden uit de deals tabel.
//  Legacy velden 'image' en 'hotel' zijn behouden voor backward compatibility.
query "deal/{deal_id}" verb=GET {
  api_group = "Public API"

  input {
    int deal_id {
      table = "deals"
    }
  }

  stack {
    // Fetch the deal by ID
    db.get deals {
      field_name = "id"
      field_value = $input.deal_id
    } as $deal
  
    precondition ($deal != null && $deal.source != "provider_sync") {
      error_type = "notfound"
      error = "Deal not found"
    }
  
    // Ensure the deal exists and is public (Requirement Phase Productiescheiding)
    var $is_public {
      value = false
    }
  
    conditional {
      if ($deal != null && $deal.status == "active" && ($deal.hotel_integration_id ?? 0) == 0) {
        var.update $is_public {
          value = true
        }
      }
    }
  
    conditional {
      if ($deal != null && $deal.status == "active" && ($deal.hotel_integration_id ?? 0) > 0) {
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
  
    precondition ($is_public) {
      error_type = "notfound"
      error = "Deal not found"
    }
  
    // Fetch the associated hotel for the legacy 'hotel' object
    db.get hotels {
      field_name = "id"
      field_value = $deal.hotel_id
    } as $hotel
  
    // Structureer de response voor Webflow (Alle contractvelden + Legacy support).
    var $result {
      value = $deal
        |set:"image":($deal.images|first)
        |set:"hotel":```
          {
            name: $hotel.name,
            city: $deal.city,
            star_rating: $deal.star_rating
          }
          ```
    }
  }

  response = $result
}
