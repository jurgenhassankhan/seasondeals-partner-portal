// Completed owner-approved design test; retained as read-only delivery lookup.
function "supplier/checkout/test_confirmation_v2" {
 input {}
 stack {
 api.request {
 url="https://api.resend.com/emails/01a12ae5-adb0-706a-83a6-ab8ecd4b55a5"
 method="GET"
 headers=["Authorization: Bearer " ~ $env.RESEND_API_KEY]
 } as $delivery
 }
 response={status:$delivery.response.status,resend_id:$delivery.response.result.id,delivery_status:$delivery.response.result.last_event,template_version:"supplier-confirmation-v2"}
}