// GET /seasondeals-admin/supplier-bookings
// Private admin endpoint to list and inspect supplier bookings
// 8. Return response matching requested shape
query "supplier-bookings" verb=GET {
  api_group = "Admin"
  auth = "admin_users"

  input {
    // Page number for pagination
    int page?=1 filters=min:1
  
    // Number of items per page
    int per_page?=25 filters=min:1|max:100
  
    // Optional provider slug filter
    text? provider_slug filters=trim
  
    // Optional environment filter (sandbox or production)
    text? environment filters=trim
  
    // Optional booking status filter
    text? booking_status filters=trim
  
    // Optional search query for external_booking_id, client_reference, hotel_name, or hotel_external_id
    text? search filters=trim
  }

  stack {
    // 1. Authenticate admin user
    function.run "admin/guard" {
      input = {permission: null}
    } as $admin
  
    // 2. Authorize role: allow only active admin or superadmin
    precondition ($admin.is_active && ($admin.role == "superadmin" || $admin.role == "platform_admin" || $admin.role == "admin")) {
      error_type = "accessdenied"
      error = "Admin or superadmin access required."
    }
  
    // 3. Normalize and validate inputs
    var $safe_page {
      value = $input.page ?? 1
    }
  
    conditional {
      if ($safe_page < 1) {
        var.update $safe_page {
          value = 1
        }
      }
    }
  
    var $safe_per_page {
      value = $input.per_page ?? 25
    }
  
    conditional {
      if ($safe_per_page < 1) {
        var.update $safe_per_page {
          value = 1
        }
      }
    
      elseif ($safe_per_page > 100) {
        var.update $safe_per_page {
          value = 100
        }
      }
    }
  
    var $provider_slug_raw {
      value = ($input.provider_slug ?? "")|trim
    }
  
    var $provider_slug_val {
      value = $provider_slug_raw|first_notempty:null
    }
  
    var $environment_raw {
      value = ($input.environment ?? "")|trim
    }
  
    var $environment_val {
      value = $environment_raw|first_notempty:null
    }
  
    conditional {
      if ($environment_val != null) {
        precondition ($environment_val == "sandbox" || $environment_val == "production") {
          error_type = "inputerror"
          error = "Environment must be either sandbox or production."
        }
      }
    }
  
    var $booking_status_raw {
      value = ($input.booking_status ?? "")|trim|to_upper
    }
  
    var $booking_status_val {
      value = $booking_status_raw|first_notempty:null
    }
  
    var $search_raw {
      value = ($input.search ?? "")|trim|to_lower
    }
  
    var $search_val {
      value = $search_raw|first_notempty:null
    }
  
    // Read-only enrichment and filtering before pagination.
    db.query supplier_bookings {
      where = ($db.supplier_bookings.provider_slug ==? $provider_slug_val) && ($db.supplier_bookings.environment ==? $environment_val)
      sort = {updated_at: "desc", id: "desc"}
      return = {type: "list"}
    } as $all_records

    // 7. Format normalized items omitting sensitive guest, payment, and raw provider details
    var $items {
      value = []
    }
  
    foreach ($all_records) {
      each as $item {
        // Enrich each supplier booking with the related SeasonDeals order, deal, voucher and checkout intent.
        db.query orders {
          where = $db.orders.id == $item.order_id
          return = {type: "single"}
        } as $related_order
      
        var $related_deal_id {
          value = $related_order|get:"deal_id":0
        }
      
        db.query deals {
          where = $db.deals.id == $related_deal_id
          return = {type: "single"}
        } as $related_deal
      
        db.query supplier_deals {
          where = $db.supplier_deals.deal_id == $related_deal_id
          return = {type: "single"}
        } as $related_supplier_deal
      
        db.query vouchers {
          where = $db.vouchers.order_id == $item.order_id
          sort = {id: "desc"}
          return = {type: "single"}
        } as $related_voucher
      
        db.query supplier_checkout_intents {
          where = $db.supplier_checkout_intents.order_id == $item.order_id
          sort = {id: "desc"}
          return = {type: "single"}
        } as $related_intent
      
        var $supplier_content {
          value = $related_supplier_deal|get:"supplier_content":{}
        }
      
        var $supplier_hotel {
          value = $supplier_content|get:"hotel":{}
        }
      
        var $supplier_request {
          value = $supplier_content|get:"request":{}
        }
      
        var $intent_context {
          value = $related_intent|get:"checkout_context":{}
        }
      
        var $confirmation_mail {
          value = $intent_context|get:"confirmation_mail":{}
        }
      
        var $reconciliation {
          value = $intent_context
            |get:"financial_reconciliation":{}
        }
      
        var $resolved_hotel_external_id {
          value = $item.hotel_external_id
        }
      
        conditional {
          if ($resolved_hotel_external_id == null || $resolved_hotel_external_id == "") {
            var.update $resolved_hotel_external_id {
              value = $related_supplier_deal|get:"supplier_hotel_id":null
            }
          }
        }
      
        var $resolved_hotel_name {
          value = $item.hotel_name
        }
      
        conditional {
          if ($resolved_hotel_name == null || $resolved_hotel_name == "") {
            var.update $resolved_hotel_name {
              value = $supplier_hotel|get:"name":null
            }
          }
        }
      
        conditional {
          if ($resolved_hotel_name == null || $resolved_hotel_name == "") {
            var.update $resolved_hotel_name {
              value = $related_deal|get:"title":null
            }
          }
        }
      
        var $resolved_checkin {
          value = $item.checkin
        }
      
        conditional {
          if ($resolved_checkin == null || $resolved_checkin == "") {
            var.update $resolved_checkin {
              value = ($related_voucher|get:"checkin":null) ?? ($related_order|get:"checkin":null)
            }
          }
        }
      
        conditional {
          if ($resolved_checkin == null || $resolved_checkin == "") {
            var.update $resolved_checkin {
              value = $supplier_request|get:"checkin":null
            }
          }
        }
      
        var $resolved_checkout {
          value = $item.checkout
        }
      
        conditional {
          if ($resolved_checkout == null || $resolved_checkout == "") {
            var.update $resolved_checkout {
              value = ($related_voucher|get:"checkout":null) ?? ($related_order|get:"checkout":null)
            }
          }
        }
      
        conditional {
          if ($resolved_checkout == null || $resolved_checkout == "") {
            var.update $resolved_checkout {
              value = $supplier_request|get:"checkout":null
            }
          }
        }
      
        var $normalized_item {
          value = {
            id                           : $item.id
            created_at                   : $item.created_at
            updated_at                   : $item.updated_at
            order_id                     : $item.order_id
            deal_id                      : $related_deal_id
            deal_title                   : $related_deal|get:"title":null
            order_status                 : $related_order|get:"status":null
            order_total_amount           : (($related_order|get:"total_amount":null) ?? $item.selling_price ?? 0)|to_decimal
            hotel_integration_id         : $item.hotel_integration_id
            provider_id                  : $item.provider_id
            provider_slug                : $item.provider_slug
            environment                  : $item.environment
            external_booking_id          : $item.external_booking_id
            prebook_id                   : $item.prebook_id
            client_reference             : $item.client_reference
            supplier                     : $item.supplier
            supplier_id                  : $item.supplier_id
            hotel_external_id            : $resolved_hotel_external_id
            hotel_name                   : $resolved_hotel_name
            checkin                      : $resolved_checkin
            checkout                     : $resolved_checkout
            booking_status               : $item.booking_status
            payment_status               : $item.payment_status ?? ($related_order|get:"payment_status":null)
            currency                     : $item.currency
            supplier_amount              : ($item.supplier_amount ?? 0)|to_decimal
            selling_price                : ($item.selling_price ?? 0)|to_decimal
            suggested_selling_price      : ($item.suggested_selling_price ?? 0)|to_decimal
            taxes_fees                   : ($item.taxes_fees ?? 0)|to_decimal
            processing_fee               : ($item.processing_fee ?? 0)|to_decimal
            stripe_fee                   : $item.stripe_fee
            stripe_fee_estimated         : (($related_intent|get:"stripe_fee_estimated":0) ?? 0)|to_decimal
            seasondeals_margin           : ($item.seasondeals_margin ?? 0)|to_decimal
            seasondeals_margin_percentage: ($item.seasondeals_margin_percentage ?? 0)|to_decimal
            provider_commission          : ($item.provider_commission ?? 0)|to_decimal
            refund_amount                : ($item.refund_amount ?? 0)|to_decimal
            cancellation_fee             : ($item.cancellation_fee ?? 0)|to_decimal
            cancellation_status          : $item.cancellation_status
            refundable_tag               : $item.refundable_tag
            guest_count                  : $item.guest_count ?? ($related_order|get:"guests":null)
            voucher_code                 : $related_voucher|get:"code":null
            voucher_status               : $related_voucher|get:"status":null
            voucher_redemption_status    : $related_voucher|get:"redemption_status":null
            qr_payload                   : $related_voucher|get:"qr_payload":null
            customer_email               : $related_voucher|get:"customer_email":null
            checkout_intent_status       : $related_intent|get:"status":null
            confirmation_mail_status     : $confirmation_mail|get:"status":null
            confirmation_mail_sent_at    : $confirmation_mail|get:"sent_at":null
            confirmation_mail_resend_id  : $confirmation_mail|get:"resend_email_id":null
            financial_reconciliation     : $reconciliation|get:"status":null
            last_synced_at               : $item.last_synced_at
            error_message                : $item.error_message
          }
        }
      
        var $status_upper {
          value = ($item.booking_status ?? "")|to_upper
        }
        var $status_matches {
          value = $booking_status_val == null || $status_upper == $booking_status_val || ($booking_status_val == "ACTION_REQUIRED" && (($status_upper|contains:"FAILED") || ($status_upper|contains:"ERROR") || ($status_upper|contains:"ATTENTION"))) || ($booking_status_val == "PENDING" && (($status_upper|contains:"PENDING") || ($status_upper|contains:"PROCESSING")))
        }
        var $search_text {
          value = [$resolved_hotel_name, $resolved_hotel_external_id, $item.external_booking_id, $item.client_reference]|join:" "|to_lower
        }
        conditional {
          if ($status_matches && ($search_val == null || ($search_text|contains:$search_val))) {
            var.update $items {
              value = $items|push:$normalized_item
            }
          }
        }
      }
    }
    // 5. Compute summary across all matching filtered records
    var $total_count {
      value = $items|count
    }
  
    var $sandbox_count {
      value = 0
    }
  
    var $production_count {
      value = 0
    }
  
    var $confirmed_count {
      value = 0
    }
  
    var $cancelled_count {
      value = 0
    }
  
    var $total_selling_price {
      value = 0
    }
  
    var $total_supplier_amount {
      value = 0
    }
  
    var $total_seasondeals_margin {
      value = 0
    }
  
    var $total_refund_amount {
      value = 0
    }
  
    var $total_cancellation_fee {
      value = 0
    }
  
    foreach ($items) {
      each as $row {
        conditional {
          if ($row.environment == "sandbox") {
            var.update $sandbox_count {
              value = $sandbox_count + 1
            }
          }
        
          elseif ($row.environment == "production") {
            var.update $production_count {
              value = $production_count + 1
            }
          }
        }
      
        var $upper_status {
          value = ($row.booking_status ?? "")|to_upper
        }
      
        conditional {
          if ($upper_status == "CONFIRMED") {
            var.update $confirmed_count {
              value = $confirmed_count + 1
            }
          }
        }
      
        conditional {
          if ($upper_status|contains:"CANCELLED") {
            var.update $cancelled_count {
              value = $cancelled_count + 1
            }
          }
        }
      
        var $selling_price_val {
          value = ($row.selling_price ?? 0)|to_decimal
        }
      
        var.update $total_selling_price {
          value = $total_selling_price + $selling_price_val
        }
      
        var $supplier_amount_val {
          value = ($row.supplier_amount ?? 0)|to_decimal
        }
      
        var.update $total_supplier_amount {
          value = $total_supplier_amount + $supplier_amount_val
        }
      
        var $seasondeals_margin_val {
          value = ($row.seasondeals_margin ?? 0)|to_decimal
        }
      
        var.update $total_seasondeals_margin {
          value = $total_seasondeals_margin + $seasondeals_margin_val
        }
      
        var $refund_amount_val {
          value = ($row.refund_amount ?? 0)|to_decimal
        }
      
        var.update $total_refund_amount {
          value = $total_refund_amount + $refund_amount_val
        }
      
        var $cancellation_fee_val {
          value = ($row.cancellation_fee ?? 0)|to_decimal
        }
      
        var.update $total_cancellation_fee {
          value = $total_cancellation_fee + $cancellation_fee_val
        }
      }
    }
  
    var $summary {
      value = {
        total_count             : $total_count
        sandbox_count           : $sandbox_count
        production_count        : $production_count
        confirmed_count         : $confirmed_count
        cancelled_count         : $cancelled_count
        total_selling_price     : $total_selling_price
        total_supplier_amount   : $total_supplier_amount
        total_seasondeals_margin: $total_seasondeals_margin
        total_refund_amount     : $total_refund_amount
        total_cancellation_fee  : $total_cancellation_fee
      }
    }
  
    // 6. Compute pagination
    var $total_pages {
      value = 0
    }
  
    conditional {
      if ($total_count > 0) {
        var.update $total_pages {
          value = (($total_count|to_decimal) / $safe_per_page)|ceil
        }
      }
    }
  
    var $offset {
      value = ($safe_page - 1) * $safe_per_page
    }
  
    var $paged_records {
      value = $items|slice:$offset:$safe_per_page
    }
  

  }

  response = {
    items      : $paged_records
    page       : $safe_page
    per_page   : $safe_per_page
    total      : $total_count
    total_pages: $total_pages
    summary    : $summary
  }
}