query "supplier-deals/{deal_id}/pricing" verb=PATCH {
  api_group = "Admin"
  auth = "admin_users"

  input {
    int deal_id
    json pricing_config
  }

  stack {
    function.run "admin/guard" {
      input = {permission: null}
    } as $admin
  
    precondition ($admin.role == "superadmin" || $admin.role == "platform_admin") {
      error_type = "accessdenied"
      error = "Alleen bevoegde beheerders mogen prijsregels aanpassen."
    }
  
    db.query deals {
      where = $db.deals.id == $input.deal_id && ($db.deals.deleted_at == null || $db.deals.deleted_at == 0)
      return = {type: "single"}
    } as $deal
  
    precondition ($deal != null && $deal.status == "draft") {
      error_type = "inputerror"
      error = "Prijsregels kunnen uitsluitend bij een conceptdeal worden gewijzigd."
    }
  
    db.query supplier_deals {
      where = $db.supplier_deals.deal_id == $input.deal_id && $db.supplier_deals.provider == "nuitee"
      return = {type: "single"}
    } as $supplier
  
    precondition ($supplier != null) {
      error_type = "notfound"
      error = "Nuitee-koppeling niet gevonden."
    }
  
    var $config {
      value = $input.pricing_config
    }
  
    precondition ($config.markup_percentage >= 0 && $config.markup_amount >= 0 && $config.override_amount >= 0 && $config.discount_percentage >= 0 && $config.discount_percentage < 100 && $config.min_margin_amount >= 0 && $config.processing_fee >= 0 && $config.stripe_fee_percentage >= 0 && $config.stripe_fee_percentage < 100 && $config.stripe_fee_fixed >= 0) {
      error_type = "inputerror"
      error = "Ongeldige prijswaarden."
    }
  
    precondition ($config.mode == "percentage" || $config.mode == "fixed" || $config.mode == "override") {
      error_type = "inputerror"
      error = "Ongeldige prijsregel."
    }
  
    var $raw_price {
      value = $config.override_amount
    }
  
    conditional {
      if ($config.mode == "percentage") {
        var.update $raw_price {
          value = $supplier.supplier_base_amount * (1 + $config.markup_percentage / 100)
        }
      }
    
      elseif ($config.mode == "fixed") {
        var.update $raw_price {
          value = $supplier.supplier_base_amount + $config.markup_amount
        }
      }
    }
  
    var $discounted {
      value = $raw_price * (1 - $config.discount_percentage / 100)
    }
  
    var $price {
      value = ($discounted * 100|ceil) / 100
    }
  
    precondition ($config.rounding == "none" || $config.rounding == "whole" || $config.rounding == "99") {
      error_type = "inputerror"
      error = "Ongeldige afronding."
    }
  
    conditional {
      if ($config.rounding == "whole") {
        var.update $price {
          value = $discounted|ceil
        }
      }
    
      elseif ($config.rounding == "99") {
        var.update $price {
          value = (($discounted - 0.99)|ceil) + 0.99
        }
      }
    }
  
    var $margin {
      value = $price - $supplier.supplier_base_amount - $config.processing_fee - ($price * $config.stripe_fee_percentage / 100) - $config.stripe_fee_fixed
    }
  
    precondition ($price > 0 && $margin >= $config.min_margin_amount) {
      error_type = "inputerror"
      error = "Minimummarge na kostenreserve niet gehaald."
    }
  
    db.transaction {
      stack {
        db.edit supplier_deals {
          field_name = "id"
          field_value = $supplier.id
          data = {pricing_config: $config}
        } as $updated_supplier
      
        db.edit deals {
          field_name = "id"
          field_value = $deal.id
          data = {price: $price, deal_price: $price, updated_at: "now"}
        } as $updated_deal
      }
    }
  }

  response = {
    supplier_deal   : $updated_supplier
    price           : $price
    estimated_margin: $margin
  }
}
