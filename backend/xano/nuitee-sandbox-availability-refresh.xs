// Sandbox-only automatic availability; bounded first 10 mappings, one request at a time.
task nuitee_sandbox_availability_refresh {
  active = false
  datasource = "live"
  stack {
    db.query supplier_deals {
      where = $db.supplier_deals.provider == "nuitee" && $db.supplier_deals.environment == "sandbox"
      return = {type: "list"}
    } as $suppliers
    api.lambda {
      code = """
return ($var.suppliers||[]).slice(0,10);
      """
      timeout = 5
    } as $batch
    foreach ($batch) {
      each as $item {
        try_catch {
          try {
            function.run "supplier/availability/refresh" {
              input = {deal_id: $item.deal_id}
            } as $result
          }
          catch {
            debug.log { value = {deal_id: $item.deal_id, status: "refresh_failed"} }
          }
        }
      }
    }
  }
  schedule = [{starts_on: 2026-10-08 12:00:00+0000, freq: 45}]
}
