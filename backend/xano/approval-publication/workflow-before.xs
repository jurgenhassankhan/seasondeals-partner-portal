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
  
    db.query deals {
      where = $db.deals.id == $input.deal_id && ($db.deals.deleted_at == null || $db.deals.deleted_at == 0)
      return = {type: "single"}
    } as $deal
  
    precondition ($deal != null) {
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
  
    precondition ($supplier.environment == "sandbox") {
      error_type = "inputerror"
      error = "Productiepublicatie volgt pas na de volledige boekingstest."
    }
  
    var $result {
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
      
        precondition ($deal.title != "" && $deal.short_description != null && $deal.short_description != "" && $deal.long_description != null && $deal.long_description != "" && $deal.cancellation_policy != null && $deal.cancellation_policy != "") {
          error_type = "inputerror"
          error = "Vul eerst titel, korte en uitgebreide omschrijving en annuleringsvoorwaarden in."
        }
      
        precondition ($supplier.supplier_hotel_id != "" && $supplier.supplier_base_amount > 0 && $supplier.pricing_config.min_margin_amount != null) {
          error_type = "inputerror"
          error = "Leveranciersmapping en prijsregels zijn verplicht."
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
                is_active   : false
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

  response = {deal: $result}
}
