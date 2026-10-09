// Fair sandbox rotation: oldest checks first, sequential provider requests and bounded runtime.
task nuitee_sandbox_availability_refresh {
  active = false
  datasource = "live"
  stack {
    api.lambda {
      code = "return {started:Date.now(),cutoff:Date.now()-600000};"
      timeout = 5
    } as $clock
    db.query supplier_deals {
      where = $db.supplier_deals.provider == "nuitee" && $db.supplier_deals.environment == "sandbox"
      return = {type: "list"}
    } as $suppliers
    db.query deals {
      where = $db.deals.status == "active" && $db.deals.source == "provider_sync"
      return = {type: "list"}
    } as $deals
    db.query supplier_availability_snapshots {
      where = $db.supplier_availability_snapshots.environment == "sandbox" && $db.supplier_availability_snapshots.started_at >= $clock.cutoff
      return = {type: "list"}
    } as $recent
    api.lambda {
      code = """
const approved=new Set(($var.deals||[]).filter(d=>d.approved_at&&!d.deleted_at).map(d=>d.id));
const last=new Map();for(const r of ($var.recent||[])){if(!last.has(r.deal_id)||r.started_at>last.get(r.deal_id).started_at)last.set(r.deal_id,r);}
return ($var.suppliers||[]).filter(s=>approved.has(s.deal_id)&&!(last.get(s.deal_id)?.status==='checking'&&Date.now()-last.get(s.deal_id).started_at<20000)).sort((a,b)=>(last.get(a.deal_id)?.started_at||0)-(last.get(b.deal_id)?.started_at||0)||a.deal_id-b.deal_id).slice(0,20);
      """
      timeout = 5
    } as $batch
    foreach ($batch) {
      each as $item {
        api.lambda {
          code = "return Date.now()-$var.clock.started<45000;"
          timeout = 5
        } as $within_budget
        conditional {
          if ($within_budget) {
            try_catch {
              try {
                function.run "supplier/availability/refresh" {
                  input = {deal_id: $item.deal_id}
                } as $result
              }
              catch {
                debug.log {
                  value = {deal_id: $item.deal_id, status: "refresh_failed"}
                }
              }
            }
          }
        }
      }
    }
  }
  schedule = [{starts_on: 2026-10-09 12:00:00+0000, freq: 60}]
}

