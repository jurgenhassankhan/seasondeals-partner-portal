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
  }

  response = $result
}
