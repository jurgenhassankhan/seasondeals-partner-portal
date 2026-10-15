// Public customer-safe preview. No booking, payment, customer lookup or write.
query "supplier/production/booking-preview" verb=POST {
  api_group = "Public API"

  input {
    int deal_id
    text checkin filters=trim
    text checkout filters=trim
    int guests
  }

  stack {
    util.set_header {
      value = "Cache-Control: no-store, private"
      duplicates = "replace"
    }
  
    util.set_header {
      value = "Referrer-Policy: no-referrer"
      duplicates = "replace"
    }
  
    function.run "supplier/production/config_status" as $gate
    conditional {
      if ($gate.can_read != true || $gate.can_sell != true || $gate.can_pay != true || $gate.can_book != true) {
        return {
          value = {
            environment: "production"
            status     : "closed"
            available  : false
            can_pay    : false
            message    : "Online boeken is binnenkort beschikbaar."
          }
        }
      }
    }
  
    function.run "supplier/production/availability" {
      input = {
        deal_id : $input.deal_id
        checkin : $input.checkin
        checkout: $input.checkout
        guests  : $input.guests
      }
    } as $quote
  
    conditional {
      if ($quote.available != true) {
        return {
          value = {
            environment: "production"
            status     : $quote.status
            available  : false
            can_pay    : false
            message    : $quote.message
          }
        }
      }
    }
  
    db.get deals {
      field_name = "id"
      field_value = $input.deal_id
    } as $deal
  
    api.lambda {
      code = """
          const q=$var.quote;
          if(!q || q.environment!=='production') return {environment:'production',status:'unavailable',available:false,can_pay:false};
          const ok=q.status==='available'&&q.available===true&&q.currency==='EUR'&&Number.isFinite(q.customer_price)&&q.customer_price>0&&q.valid_until>Date.now();
          return {environment:'production',status:ok?'available':q.status,available:ok,can_pay:ok,title:$var.deal.title,deal_id:$input.deal_id,checkin:$input.checkin,checkout:$input.checkout,guest_count:$input.guests,customer_price:ok?q.customer_price:null,currency:'EUR',checked_at:q.checked_at,valid_until:q.valid_until,room_name:ok?q.room_name:null,board_name:ok?q.board_name:null,local_fees:ok?q.local_fees:[],cancellation_policies:ok?q.cancellation_policies:null,message:ok?'Je verblijf is beschikbaar.':q.message};
        """
      timeout = 5
    } as $preview
  }

  response = $preview
}