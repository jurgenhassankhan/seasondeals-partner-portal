table supplier_availability_snapshots {
  auth = false
  schema {
    int id
    timestamp created_at?=now
    int deal_id
    text environment
    timestamp started_at
    timestamp checked_at?
    timestamp valid_until?
    text approval_signature
    text status
    json snapshot?
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "deal_id"}, {name: "environment"}, {name: "started_at", op: "desc"}]}
  ]
}
