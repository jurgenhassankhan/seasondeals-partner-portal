query "supplier-deals/{deal_id}/workflow" verb=PATCH {
  api_group = "Admin"
  auth = "admin_users"

  input {
    int deal_id
    enum action {
      values = ["save_content", "submit", "active", "rejected", "draft"]
    }
  
    text title? filters=trim
    text short_description? filters=trim
    text long_description? filters=trim
    text cancellation_policy? filters=trim
    text rejection_reason? filters=trim
    text review_notes? filters=trim
  }

  stack {
    function.run "admin/guard" {
      input = {permission: null}
    } as $admin
  
    precondition ($admin.role == "superadmin" || $admin.role == "platform_admin") {
      error_type = "accessdenied"
      error = "Alleen bevoegde beheerders mogen Nuitée-deals wijzigen."
    }
  
    var $result { value = null }
    db.transaction {
      stack {
    db.get deals {
      field_name = "id"
      field_value = $input.deal_id
      lock = true
    } as $deal
  
    precondition ($deal != null && ($deal.deleted_at == null || $deal.deleted_at == 0)) {
      error_type = "notfound"
      error = "Deal niet gevonden."
    }
  
    db.query supplier_deals {
      where = $db.supplier_deals.deal_id == $deal.id && $db.supplier_deals.provider == "nuitee"
      return = {type: "single"}
    } as $supplier
  
    precondition ($supplier != null) {
      error_type = "inputerror"
      error = "Dit is geen Nuitée-deal."
    }
  
    precondition ($supplier.environment == "sandbox" || $supplier.environment == "production") {
      error_type = "inputerror"
      error = "Onbekende leveranciersomgeving."
    }
  
    var.update $result {
      value = $deal
    }
  
    conditional {
      if ($input.action == "save_content") {
        precondition ($deal.status == "draft") {
          error_type = "inputerror"
          error = "Inhoud kan alleen in concept worden gewijzigd."
        }
      
        precondition ($input.title != null && $input.title != "") {
          error_type = "inputerror"
          error = "Titel is verplicht."
        }
      
        db.edit deals {
          field_name = "id"
          field_value = $deal.id
          data = {
            title              : $input.title
            short_description  : $input.short_description
            long_description   : $input.long_description
            cancellation_policy: $input.cancellation_policy
            updated_at         : now
          }
        } as $saved
      
        var.update $result {
          value = $saved
        }
      }
    
      elseif ($input.action == "submit" || $input.action == "active") {
        precondition (($input.action == "submit" && $deal.status == "draft") || ($input.action == "active" && $deal.status == "pending_approval")) {
          error_type = "inputerror"
          error = "Ongeldige statusovergang."
        }
      
        api.lambda {
          code = """
const supplier=$var.supplier,hotel=supplier.supplier_content?.hotel||{};
const photos=hotel.photo_gallery,urls=$var.deal.external_image_urls,rateName=supplier.supplier_mapping?.offer?.rates?.[0]?.name;
if(hotel.photo_verification?.status!=='verified'||!['sha256+dhash64-v1','sha256+dhash64-area-v2'].includes(hotel.photo_verification?.algorithm)||hotel.room_photos_matched!==true||!hotel.mapped_room_id||hotel.photo_rate_name!==rateName||hotel.photo_hotel_id!==supplier.supplier_hotel_id)return false;
const rate=supplier.supplier_mapping?.offer?.rates?.[0],binding=hotel.room_photo_binding;
const direct=rate?.mappedRoomId&&String(hotel.mapped_room_id)===String(rate.mappedRoomId);
const confirmed=binding?.source==='provider_exact_room_name'&&binding.hotel_id===supplier.supplier_hotel_id&&binding.rate_name===rate?.name&&binding.adult_count===rate.adultCount&&binding.child_count===rate.childCount&&String(binding.mapped_room_id)===String(hotel.mapped_room_id);
if(rate?.mappedRoomId ? !direct : !confirmed)return false;
if(!Array.isArray(photos)||!Array.isArray(urls)||photos.length<1||photos.length>5||urls.length!==photos.length)return false;
const distance=(a,b)=>{let n=BigInt('0x'+a)^BigInt('0x'+b),bits=0;while(n){bits+=Number(n&1n);n>>=1n;}return bits;};
for(let i=0;i<photos.length;i++){
 const p=photos[i];
 if(p.scope!=='matched_room'||p.url!==urls[i]||!/^https:\/\//.test(p.url)||!(/^[a-f0-9]{64}$/.test(p.sha256))||!(/^[a-f0-9]{16}$/.test(p.dhash)))return false;
 for(let j=0;j<i;j++)if(p.url===photos[j].url||p.sha256===photos[j].sha256||distance(p.dhash,photos[j].dhash)<=5)return false;
}
return true;
"""
          timeout = 5
        } as $photos_verified
        precondition ($photos_verified) {
          error_type = "inputerror"
          error = "De foto's moeten eerst bij het juiste kamertype worden opgehaald en op dubbele beelden worden gecontroleerd."
        }

        precondition ($deal.title != "" && $deal.short_description != null && $deal.short_description != "" && $deal.long_description != null && $deal.long_description != "" && $deal.cancellation_policy != null && $deal.cancellation_policy != "") {
          error_type = "inputerror"
          error = "Vul eerst titel, korte en uitgebreide omschrijving en annuleringsvoorwaarden in."
        }
      
        precondition ($supplier.supplier_hotel_id != "" && $supplier.supplier_base_amount > 0 && $supplier.pricing_config.min_margin_amount != null) {
          error_type = "inputerror"
          error = "Leveranciersmapping en prijsregels zijn verplicht."
        }
      
        precondition ($supplier.pricing_config.processing_fee != null && $supplier.pricing_config.stripe_fee_percentage != null && $supplier.pricing_config.stripe_fee_fixed != null && $supplier.pricing_config.processing_fee >= 0 && $supplier.pricing_config.stripe_fee_percentage >= 0 && $supplier.pricing_config.stripe_fee_percentage < 100 && $supplier.pricing_config.stripe_fee_fixed >= 0) {
          error_type = "inputerror"
          error = "Controleer en sla eerst de kosten en prijsregels op."
        }
      
        var $margin {
          value = $deal.price - $supplier.supplier_base_amount - $supplier.pricing_config.processing_fee - ($deal.price * $supplier.pricing_config.stripe_fee_percentage / 100) - $supplier.pricing_config.stripe_fee_fixed
        }
      
        precondition ($deal.price > 0 && $margin >= $supplier.pricing_config.min_margin_amount) {
          error_type = "inputerror"
          error = "Minimummarge na kostenreserve niet gehaald."
        }
      
        conditional {
          if ($input.action == "submit") {
            db.edit deals {
              field_name = "id"
              field_value = $deal.id
              data = {
                status      : "pending_approval"
                is_active   : false
                submitted_at: now
                updated_at  : now
              }
            } as $submitted
          
            var.update $result {
              value = $submitted
            }
          }
        
          else {
            db.edit deals {
              field_name = "id"
              field_value = $deal.id
              data = {
                status      : "active"
                is_active   : ($supplier.environment == "production")
                approved_at : now
                review_notes: $input.review_notes
                updated_at  : now
              }
            } as $approved
          
            var.update $result {
              value = $approved
            }
          }
        }
      }
    
      elseif ($input.action == "rejected") {
        precondition ($deal.status == "pending_approval" && $input.rejection_reason != null && $input.rejection_reason != "") {
          error_type = "inputerror"
          error = "Afwijzen vereist een ingediende deal en een reden."
        }
      
        db.edit deals {
          field_name = "id"
          field_value = $deal.id
          data = {
            status          : "rejected"
            is_active       : false
            rejected_at     : now
            rejection_reason: $input.rejection_reason
            review_notes    : $input.review_notes
            updated_at      : now
          }
        } as $rejected
      
        var.update $result {
          value = $rejected
        }
      }
    
      else {
        precondition ($deal.status == "pending_approval" || $deal.status == "rejected" || $deal.status == "active") {
          error_type = "inputerror"
          error = "Deze deal staat al in concept."
        }
      
        db.edit deals {
          field_name = "id"
          field_value = $deal.id
          data = {
            status          : "draft"
            is_active       : false
            submitted_at    : null
            approved_at     : null
            rejected_at     : null
            rejection_reason: null
            updated_at      : now
          }
        } as $draft
      
        var.update $result {
          value = $draft
        }
      }
    }
  
    conditional {
      if ($supplier.environment == "production") {
    db.edit supplier_deals {
      field_name = "id"
      field_value = $supplier.id
      data = {is_enabled: ($supplier.environment == "production" && $result.status == "active")}
    } as $visibility_supplier

      }
    }

    function.run "audit/log" {
      input = {
        user_id       : $auth.id
        user_type     : "admin"
        resource_table: "deals"
        resource_id   : $deal.id
        action        : "supplier_" ~ $input.action
        prev_values   : {status: $deal.status}
        new_values    : {status: $result.status, is_active: $result.is_active}
      }
    } as $audit
      }
    }
  }

  response = {deal: $result}
}
