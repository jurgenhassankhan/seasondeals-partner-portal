// Trigger a refund for an order via Stripe
query "orders/{order_id}/refund" verb=POST {
  api_group = "Admin"
  auth = "admin_users"

  input {
    int order_id {
      table = "orders"
    }
  
    decimal? amount
    text reason?
  }

  stack {
    db.get orders {
      field_name = "id"
      field_value = $input.order_id
    } as $order
  
    precondition ($order != null && ($order.status == "paid")) {
      error_type = "inputerror"
      error = "Order must be in paid status to refund"
    }
  
    db.query payments {
      where = $db.payments.order_id == $order.id
      return = {type: "single"}
    } as $payment
  
    precondition ($payment != null && ($payment.stripe_payment_intent_id != null)) {
      error = "Payment record not found"
    }
  
    // Call Stripe to process refund
    api.request {
      url = "https://api.stripe.com/v1/refunds"
      method = "POST"
      params = {
        payment_intent: $payment.stripe_payment_intent_id
        amount        : (($input.amount ?? $payment.amount) * 100)|to_int
        reason        : $input.reason ?? "requested_by_customer"
      }
    
      headers = [
        "Authorization: Bearer " ~ $env.STRIPE_SECRET_KEY
        "Content-Type: application/x-www-form-urlencoded"
      ]
    } as $stripe_refund
  
    precondition ($stripe_refund.response.status == 200) {
      error = "Stripe refund failed: " ~ ($stripe_refund.response.result.error.message ?? "Unknown error")
    }
  
    db.transaction {
      stack {
        db.edit orders {
          field_name = "id"
          field_value = $order.id
          data = {status: "refunded", updated_at: now}
        } as $updated_order
      
        db.edit payments {
          field_name = "id"
          field_value = $payment.id
          data = {
            status       : "refunded"
            refund_amount: ($input.amount ?? $payment.amount)
            updated_at   : now
          }
        } as $updated_payment
      
        // Invalidate vouchers
        db.query vouchers {
          where = $db.vouchers.order_id == $order.id
          return = {type: "list"}
        } as $vouchers
      
        foreach ($vouchers) {
          each as $v {
            db.edit vouchers {
              field_name = "id"
              field_value = $v.id
              data = {redemption_status: "refunded", updated_at: now}
            } as $v_invalidated
          }
        }
      
        function.run "events/emit" {
          input = {
            event_type    : "RefundProcessed"
            resource_id   : $payment.id
            resource_table: "payments"
            payload       : {
            order_id: $order.id
            amount  : ($input.amount ?? $payment.amount)
          }
          }
        } as $event
      
        function.run "audit/log" {
          input = {
            user_id       : $auth.id
            user_type     : "admin"
            resource_table: "orders"
            resource_id   : $order.id
            action        : "refund_processed"
            new_values    : {
            amount: ($input.amount ?? $payment.amount)
            reason: $input.reason
          }
          }
        } as $audit
      }
    }
  }

  response = {
    success  : true
    refund_id: $stripe_refund.response.result.id
  }
}