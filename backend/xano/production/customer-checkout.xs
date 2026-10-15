// Production customer checkout: customer identity comes only from existing customer authentication.
query "supplier/production/checkout" verb=POST {
  api_group = "Customer"
  auth = "customers"

  input {
    int deal_id
    text checkin filters=trim
    text checkout filters=trim
    int guest_count
    text request_key filters=trim
    json holder
    json guests
  }

  stack {
    function.run "supplier/production/config_status" as $gate
    precondition ($gate.can_pay && $gate.can_book && $gate.can_sell) {
      error_type = "accessdenied"
      error = "PRODUCTION_NOT_RELEASED"
    }
  
    db.get customers {
      field_name = "id"
      field_value = $auth.id
    } as $customer
  
    precondition ($customer != null) {
      error_type = "accessdenied"
      error = "Authenticated customer required"
    }
  
    function.run "supplier/production/create_session" {
      input = {
        deal_id    : $input.deal_id
        checkin    : $input.checkin
        checkout   : $input.checkout
        guest_count: $input.guest_count
        customer_id: $auth.id
        request_key: $input.request_key
        holder     : $input.holder
        guests     : $input.guests
      }
    } as $checkout
  }

  response = $checkout
}
